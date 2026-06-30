from sqlalchemy import select

from app.core import security
from app.core.logging import logger
from app.models.ambulance import Ambulance
from app.models.hospital import Hospital
from app.models.user import User


async def seed_default_data(session) -> None:
    try:
        users_result = await session.execute(select(User))
        if not users_result.scalars().first():
            session.add_all(
                [
                    User(
                        name="System Admin",
                        email="admin@jeevansetu.local",
                        phone="9000000000",
                        password_hash=security.get_password_hash("ChangeMe123!"),
                        role="admin",
                    ),
                    User(
                        name="Gov Operator",
                        email="gov@jeevansetu.local",
                        phone="9000000001",
                        password_hash=security.get_password_hash("ChangeMe123!"),
                        role="gov",
                    ),
                ]
            )

        hospital_result = await session.execute(select(Hospital))
        if not hospital_result.scalars().first():
            session.add_all(
                [
                    Hospital(
                        name="Apex Trauma Center (Level 1)",
                        latitude=12.971598,
                        longitude=77.594566,
                        trauma_level=1,
                        available_beds=10,
                        ventilators=6,
                    ),
                    Hospital(
                        name="City General Hospital (Level 2)",
                        latitude=12.982598,
                        longitude=77.601566,
                        trauma_level=2,
                        available_beds=15,
                        ventilators=2,
                    ),
                    Hospital(
                        name="Metro SuperSpecialty Hospital",
                        latitude=12.991598,
                        longitude=77.624566,
                        trauma_level=1,
                        available_beds=3,
                        ventilators=10,
                    ),
                ]
            )

        ambulance_result = await session.execute(select(Ambulance))
        if not ambulance_result.scalars().first():
            session.add_all(
                [
                    Ambulance(
                        name="Ambulance-01",
                        license_plate="DL01AB1234",
                        latitude=28.5672,
                        longitude=77.2100,
                        status="available",
                    ),
                    Ambulance(
                        name="Ambulance-02",
                        license_plate="DL01AB5678",
                        latitude=28.6139,
                        longitude=77.2090,
                        status="available",
                    ),
                ]
            )

        await session.commit()
        logger.info("Default production seed data applied successfully.")
    except Exception as exc:
        logger.error("Failed to seed default data: %s", exc)
        await session.rollback()