from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api import deps
from app.db.session import get_db
from app.models.user import User
from app.schemas.notification import AccidentNotificationRequest, AccidentNotificationResponse
from app.services.notification_engine import NotificationEngine

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post(
    "/accident-alert",
    response_model=AccidentNotificationResponse,
    status_code=status.HTTP_202_ACCEPTED,
)
async def send_accident_alert(
    request: AccidentNotificationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(deps.get_current_user),
):
    try:
        return await NotificationEngine(db).notify_accident(
            user_id=str(current_user.id),
            victim_name=current_user.name,
            latitude=request.latitude,
            longitude=request.longitude,
            severity=request.severity,
            accident_id=str(request.accident_id) if request.accident_id else None,
            message=request.message,
            radius_km=request.radius_km,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))
