import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.ai.model_service import AISeverityService
from app.models.accident import Accident
from app.repositories.accident import AccidentRepository
from app.repositories.user import UserRepository
from app.services.notification_engine import NotificationEngine
from app.services.volunteers import VolunteerService
from app.schemas.accident import AccidentCreate


class AccidentService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.accident_repo = AccidentRepository(db)
        self.user_repo = UserRepository(db)

    async def report_accident(self, user_id: str, accident_in: AccidentCreate) -> Accident:
        # Fetch user
        user = await self.user_repo.get(user_id)
        if not user:
            raise ValueError("User not found")

        # Run AI prediction (severity and score)
        # response_delay is defaulted to 0 for initial report
        ai_res = AISeverityService.predict_severity(
            impact_force=accident_in.impact_force,
            speed=accident_in.speed,
            orientation_change=accident_in.orientation_change,
            response_delay=0.0,
        )

        # Create database object
        accident_dict = {
            "user_id": user_id,
            "latitude": accident_in.latitude,
            "longitude": accident_in.longitude,
            "impact_force": accident_in.impact_force,
            "speed": accident_in.speed,
            "orientation_change": accident_in.orientation_change,
            "severity": ai_res["severity"],
            "risk_score": ai_res["score"],
            "status": "pending",
        }
        accident = await self.accident_repo.create(accident_dict)

        try:
            await VolunteerService(self.db).assign_nearest_volunteer(accident)
        except Exception as exc:
            from app.core.logging import logger

            logger.error(f"Volunteer assignment failed for accident {accident.id}: {exc}")

        # Notify family, friends, and nearby volunteers via FCM.
        try:
            await NotificationEngine(self.db).notify_accident(
                user_id=str(user_id),
                victim_name=user.name,
                latitude=accident.latitude,
                longitude=accident.longitude,
                severity=accident.severity,
                accident_id=str(accident.id),
                message="Possible Accident Detected",
                radius_km=5.0,
            )
        except Exception as exc:
            # Silence exceptions in notifications to ensure report transaction completes successfully
            from app.core.logging import logger

            logger.error(f"Notification engine failed for accident {accident.id}: {exc}")

        # Broadcast to connected government dashboards via WebSocket
        try:
            from app.websocket.connection_manager import manager
            await manager.broadcast_gov({
                "type": "accident_reported",
                "accident": {
                    "incident_id": str(accident.id),
                    "latitude": accident.latitude,
                    "longitude": accident.longitude,
                    "severity": accident.severity.title(),
                    "risk_score": accident.risk_score,
                    "victim_status": accident.status,
                    "volunteer_status": accident.volunteer_status,
                    "assigned_volunteer_id": str(accident.assigned_volunteer_id) if accident.assigned_volunteer_id else None,
                    "created_at": accident.created_at.isoformat() if hasattr(accident.created_at, "isoformat") else str(accident.created_at),
                }
            })
        except Exception as ws_exc:
            from app.core.logging import logger
            logger.error(f"WebSocket broadcast failed for reported accident {accident.id}: {ws_exc}")

        return accident

    async def get_accident(self, accident_id: str) -> Accident | None:
        return await self.accident_repo.get(accident_id)
