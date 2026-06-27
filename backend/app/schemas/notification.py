from uuid import UUID
from pydantic import BaseModel


class NotificationRecipientSummary(BaseModel):
    group: str
    attempted: int = 0
    delivered: bool = False


class AccidentNotificationRequest(BaseModel):
    accident_id: UUID | None = None
    latitude: float
    longitude: float
    severity: str = "critical"
    message: str = "Possible Accident Detected"
    radius_km: float = 5.0


class AccidentNotificationResponse(BaseModel):
    message: str
    severity: str
    location: str
    recipients: list[NotificationRecipientSummary]
    total_tokens: int
    volunteer_radius_km: float
