from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import logger
from app.models.volunteer import Volunteer
from app.repositories.emergency_contact import EmergencyContactRepository
from app.repositories.user import UserRepository
from app.services.fcm import FCMNotificationService
from app.services.volunteers import VolunteerService


FAMILY_LABELS = {"family", "mother", "father", "parent", "wife", "husband", "brother", "sister"}
FRIEND_LABELS = {"friend", "friends"}


@dataclass
class RecipientGroup:
    group: str
    tokens: list[str]


class NotificationEngine:
    """Coordinates FCM emergency alerts for contacts and volunteer responders."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.contact_repo = EmergencyContactRepository(db)
        self.volunteer_service = VolunteerService(db)

    @staticmethod
    def maps_link(latitude: float, longitude: float) -> str:
        return f"https://www.google.com/maps/search/?api=1&query={latitude},{longitude}"

    async def _contact_groups(self, user_id: str) -> list[RecipientGroup]:
        contacts = await self.contact_repo.get_by_user(user_id)
        grouped = {"Family": [], "Friends": []}

        for contact in contacts:
            contact_user = await self.user_repo.get_by_phone(contact.phone)
            if not contact_user or not contact_user.fcm_token:
                continue

            relationship = contact.relationship.strip().lower()
            if relationship in FRIEND_LABELS:
                grouped["Friends"].append(contact_user.fcm_token)
            elif relationship in FAMILY_LABELS or relationship:
                grouped["Family"].append(contact_user.fcm_token)

        return [RecipientGroup(group=name, tokens=tokens) for name, tokens in grouped.items()]

    async def _nearby_volunteer_tokens(
        self,
        latitude: float,
        longitude: float,
        radius_km: float,
    ) -> list[str]:
        nearby = await self.volunteer_service.get_nearby_volunteers(
            latitude,
            longitude,
            max_radius_km=radius_km,
            limit=5,
        )

        tokens = []
        for item in nearby:
            volunteer_user = await self.user_repo.get_by_phone(item.volunteer.phone)
            if volunteer_user and volunteer_user.fcm_token:
                tokens.append(volunteer_user.fcm_token)
        return tokens

    async def notify_accident(
        self,
        *,
        user_id: str,
        victim_name: str,
        latitude: float,
        longitude: float,
        severity: str,
        accident_id: str | None = None,
        message: str = "Possible Accident Detected",
        radius_km: float = 5.0,
    ) -> dict:
        location = self.maps_link(latitude, longitude)
        contact_groups = await self._contact_groups(user_id)
        volunteer_tokens = await self._nearby_volunteer_tokens(latitude, longitude, radius_km)
        groups = [
            *contact_groups,
            RecipientGroup(group="Volunteers", tokens=volunteer_tokens),
        ]

        payload = {
            "type": "accident_alert",
            "accident_id": str(accident_id or ""),
            "message": message,
            "location": location,
            "maps_link": location,
            "severity": severity.title(),
            "victim_name": victim_name,
        }
        body = f"{message}\nLocation: {location}\nSeverity: {severity.title()}"

        recipients = []
        total_tokens = 0
        for group in groups:
            unique_tokens = list(dict.fromkeys(group.tokens))
            total_tokens += len(unique_tokens)
            delivered = FCMNotificationService.send_multicast_notification(
                tokens=unique_tokens,
                title=f"Emergency Alert - {severity.title()}",
                body=body,
                data={**payload, "recipient_group": group.group},
            )
            recipients.append(
                {
                    "group": group.group,
                    "attempted": len(unique_tokens),
                    "delivered": delivered,
                }
            )

        logger.info(
            "Notification engine dispatched accident alert for user=%s accident=%s recipients=%s",
            user_id,
            accident_id,
            recipients,
        )

        return {
            "message": message,
            "severity": severity.title(),
            "location": location,
            "recipients": recipients,
            "total_tokens": total_tokens,
            "volunteer_radius_km": radius_km,
        }

    async def volunteer_radius_summary(
        self,
        latitude: float,
        longitude: float,
        radii_km: tuple[float, ...] = (1.0, 3.0, 5.0),
    ) -> list[dict]:
        result = await self.db.execute(select(Volunteer).where(Volunteer.is_available == True))
        volunteers = result.scalars().all()
        summary = []

        for radius in radii_km:
            count = 0
            for volunteer in volunteers:
                distance = self.volunteer_service.haversine_distance(
                    latitude,
                    longitude,
                    volunteer.latitude,
                    volunteer.longitude,
                )
                if distance <= radius:
                    count += 1
            summary.append({"radius_km": radius, "available_volunteers": count})

        return summary
