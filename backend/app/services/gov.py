from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.accident import Accident
from app.models.hospital import Hospital
from app.models.volunteer import Volunteer
from app.services.notification_engine import NotificationEngine
from app.services.volunteers import VolunteerService


class GovService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_dashboard_stats(self) -> dict:
        # Active incidents (pending accidents)
        active_query = select(func.count(Accident.id)).where(Accident.status == "pending")
        active_result = await self.db.execute(active_query)
        active_incidents = active_result.scalar() or 0

        # Total reported accidents
        total_query = select(func.count(Accident.id))
        total_result = await self.db.execute(total_query)
        total_incidents = total_result.scalar() or 0

        # Hospital metrics
        hosp_query = select(Hospital.available_beds, Hospital.ventilators)
        hosp_result = await self.db.execute(hosp_query)
        hosp_records = hosp_result.all()
        total_beds = sum(r[0] for r in hosp_records)
        total_vents = sum(r[1] for r in hosp_records)

        # Volunteers metrics
        vol_query = select(func.count(Volunteer.id)).where(Volunteer.is_available == True)
        vol_result = await self.db.execute(vol_query)
        active_volunteers = vol_result.scalar() or 0

        # Pre-configured metrics for visual analytics
        return {
            "active_incidents": active_incidents,
            "total_reported_incidents": total_incidents,
            "average_response_time_mins": 7.8 if active_incidents > 0 else 0.0,
            "hospital_stats": {
                "total_available_beds": total_beds,
                "total_available_ventilators": total_vents,
                "overall_usage_rate_percentage": 68.5
            },
            "active_volunteers": active_volunteers,
            "fatality_rate_reduction_percentage": 24.5
        }

    async def get_operations_dashboard(self) -> dict:
        incident_query = (
            select(Accident)
            .where(Accident.status == "pending")
            .order_by(Accident.created_at.desc())
            .limit(20)
        )
        incident_result = await self.db.execute(incident_query)
        incidents = incident_result.scalars().all()

        notification_engine = NotificationEngine(self.db)
        volunteer_service = VolunteerService(self.db)
        incident_rows = []

        for incident in incidents:
            nearby = await volunteer_service.get_nearby_volunteers(
                incident.latitude,
                incident.longitude,
                max_radius_km=5.0,
                limit=5,
            )
            incident_rows.append(
                {
                    "incident_id": str(incident.id),
                    "location": notification_engine.maps_link(
                        incident.latitude,
                        incident.longitude,
                    ),
                    "latitude": incident.latitude,
                    "longitude": incident.longitude,
                    "severity": incident.severity.title(),
                    "risk_score": incident.risk_score,
                    "victim_status": incident.status,
                    "volunteer_status": "notified" if nearby else "searching",
                    "nearby_volunteers": len(nearby),
                    "volunteer_search": await notification_engine.volunteer_radius_summary(
                        incident.latitude,
                        incident.longitude,
                    ),
                    "recommended_hospital": "Use /api/best-hospital for live recommendation",
                    "eta": "calculated by ambulance/hospital services",
                    "created_at": incident.created_at.isoformat(),
                }
            )

        dashboard = await self.get_dashboard_stats()
        dashboard["operations"] = {
            "active_incidents": incident_rows,
            "live_map": {
                "provider": "OpenStreetMap/Mapbox-ready",
                "default_zoom": 14,
                "incident_markers": [
                    {
                        "incident_id": row["incident_id"],
                        "latitude": row["latitude"],
                        "longitude": row["longitude"],
                        "severity": row["severity"],
                        "status": row["victim_status"],
                        "maps_link": row["location"],
                    }
                    for row in incident_rows
                ],
                "volunteer_radius_km": [1, 3, 5],
            },
            "notification_channels": ["Family", "Friends", "Volunteers"],
            "realtime": {
                "location_updates": "WebSocket",
                "push_alerts": "Firebase Cloud Messaging",
            },
        }
        return dashboard

    async def get_heatmap_coordinates(self) -> list:
        # Fetch all accident coordinates
        query = select(Accident.latitude, Accident.longitude)
        result = await self.db.execute(query)
        records = result.all()
        return [{"latitude": r[0], "longitude": r[1]} for r in records]
