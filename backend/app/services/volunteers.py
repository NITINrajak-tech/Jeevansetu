import math
from typing import List
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.accident import Accident
from app.models.volunteer import Volunteer
from app.schemas.volunteer import (
    VolunteerResponse,
    VolunteerNearbyResponse,
    VolunteerCreate,
    VolunteerUpdate,
    VolunteerAssignmentUpdate,
)


class VolunteerService:
    def __init__(self, db: AsyncSession):
        self.db = db

    @staticmethod
    def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        r = 6371.0
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(math.radians(lat1))
            * math.cos(math.radians(lat2))
            * math.sin(dlon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return r * c

    async def register_volunteer(self, vol_in: VolunteerCreate) -> Volunteer:
        existing = await self.db.execute(select(Volunteer).where(Volunteer.phone == vol_in.phone))
        vol = existing.scalar_one_or_none()
        if vol:
            raise ValueError("Volunteer already registered with this phone number")

        vol = Volunteer(
            name=vol_in.name,
            phone=vol_in.phone,
            latitude=vol_in.latitude,
            longitude=vol_in.longitude,
            training_level=vol_in.training_level,
            is_available=vol_in.is_available,
        )
        self.db.add(vol)
        await self.db.flush()
        return vol

    async def update_status(self, phone: str, vol_up: VolunteerUpdate) -> Volunteer | None:
        query = select(Volunteer).where(Volunteer.phone == phone)
        result = await self.db.execute(query)
        vol = result.scalar_one_or_none()
        if not vol:
            return None

        update_data = vol_up.model_dump(exclude_unset=True)
        for field, val in update_data.items():
            setattr(vol, field, val)

        self.db.add(vol)
        await self.db.flush()
        return vol

    async def get_nearby_volunteers(
        self, lat: float, lon: float, max_radius_km: float = 5.0, limit: int = 5
    ) -> List[VolunteerNearbyResponse]:
        query = select(Volunteer).where(Volunteer.is_available == True)
        result = await self.db.execute(query)
        all_vols = result.scalars().all()

        nearby = []
        for v in all_vols:
            dist = self.haversine_distance(lat, lon, v.latitude, v.longitude)
            if dist <= max_radius_km:
                nearby.append(
                    VolunteerNearbyResponse(
                        volunteer=VolunteerResponse.model_validate(v),
                        distance_km=round(dist, 2),
                    )
                )

        nearby.sort(key=lambda x: x.distance_km)
        return nearby[:limit]

    async def assign_nearest_volunteer(
        self,
        accident: Accident,
        max_radius_km: float = 5.0,
    ) -> dict:
        nearby = await self.get_nearby_volunteers(
            accident.latitude,
            accident.longitude,
            max_radius_km=max_radius_km,
            limit=1,
        )

        if not nearby:
            accident.assigned_volunteer_id = None
            accident.volunteer_status = "searching"
            self.db.add(accident)
            await self.db.flush()
            return {"assigned": False, "status": "searching", "volunteer": None}

        selected = nearby[0].volunteer
        accident.assigned_volunteer_id = selected.id
        accident.volunteer_status = "notified"
        self.db.add(accident)
        await self.db.flush()
        return {
            "assigned": True,
            "status": "notified",
            "volunteer": selected,
            "distance_km": nearby[0].distance_km,
        }

    async def update_assignment_status(
        self,
        accident_id: str,
        phone: str,
        assignment_in: VolunteerAssignmentUpdate,
    ) -> Accident | None:
        accident_uuid = uuid.UUID(accident_id) if isinstance(accident_id, str) else accident_id
        accident_result = await self.db.execute(select(Accident).where(Accident.id == accident_uuid))
        accident = accident_result.scalar_one_or_none()
        if not accident:
            return None

        volunteer_result = await self.db.execute(select(Volunteer).where(Volunteer.phone == phone))
        volunteer = volunteer_result.scalar_one_or_none()
        if not volunteer:
            return None

        status = assignment_in.status.strip().lower()
        if status not in {"accepted", "rejected", "en_route", "arrived"}:
            raise ValueError("Invalid volunteer assignment status")

        if accident.assigned_volunteer_id and accident.assigned_volunteer_id != volunteer.id:
            if status != "rejected":
                return None

        if status == "rejected":
            accident.assigned_volunteer_id = None
            accident.volunteer_status = "searching"
            volunteer.is_available = True
        else:
            accident.assigned_volunteer_id = volunteer.id
            accident.volunteer_status = status
            volunteer.is_available = False

        self.db.add(accident)
        self.db.add(volunteer)
        await self.db.flush()

        # Broadcast to connected government dashboards via WebSocket
        try:
            from app.websocket.connection_manager import manager
            await manager.broadcast_gov({
                "type": "volunteer_status_updated",
                "accident_id": str(accident.id),
                "volunteer_status": accident.volunteer_status,
                "assigned_volunteer_id": str(accident.assigned_volunteer_id) if accident.assigned_volunteer_id else None,
                "volunteer_name": volunteer.name,
                "volunteer_phone": volunteer.phone,
                "volunteer_lat": volunteer.latitude,
                "volunteer_lng": volunteer.longitude,
            })
        except Exception as ws_exc:
            from app.core.logging import logger
            logger.error(f"WebSocket broadcast failed for volunteer status update on accident {accident.id}: {ws_exc}")

        return accident
