from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from app.core.config import settings
from app.core.logging import logger
from app.db.session import SessionLocal
from app.db.seed import seed_default_data
from app.utils.rate_limiter import RateLimitMiddleware
from app.ai.model_service import AISeverityService

# Import routers
from app.api.auth import router as auth_router
from app.api.accident import router as accident_router
from app.api.sos import router as sos_router
from app.api.location import router as location_router
from app.api.ai import router as ai_router
from app.api.hospital import router as hospital_router
from app.api.contacts import router as contacts_router
from app.api.authority import router as authority_router
from app.api.volunteers import router as volunteers_router
from app.api.ambulances import router as ambulances_router
from app.api.first_aid import router as first_aid_router
from app.api.gov import router as gov_router
from app.api.notifications import router as notifications_router


# Async Startup/Shutdown lifespan manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    logger.info("Initializing Golden Minute AI backend...")

    # Load model (and train if missing)
    AISeverityService.get_model()

    # Auto-create tables for SQLite fallback
    from app.db.session import engine
    if "sqlite" in str(engine.url):
        from app.db.base import Base
        logger.info("SQLite database detected. Auto-creating database tables...")
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    # Seed production defaults when enabled.
    if settings.SEED_DEFAULT_DATA:
        async with SessionLocal() as session:
            await seed_default_data(session)

    yield
    # Shutdown logic
    logger.info("Shutting down Golden Minute AI backend...")


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_STR}/openapi.json",
    lifespan=lifespan,
)

# CORS configuration
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Rate Limiter middleware (120 requests/minute default)
app.add_middleware(RateLimitMiddleware, requests_per_minute=120)

# Wire Routes
app.include_router(auth_router, prefix=settings.API_STR)
app.include_router(accident_router, prefix=settings.API_STR)
app.include_router(sos_router, prefix=settings.API_STR)
app.include_router(location_router, prefix=settings.API_STR)
app.include_router(ai_router, prefix=settings.API_STR)
app.include_router(hospital_router, prefix=settings.API_STR)
app.include_router(contacts_router, prefix=settings.API_STR)
app.include_router(authority_router, prefix=settings.API_STR)
app.include_router(volunteers_router, prefix=settings.API_STR)
app.include_router(ambulances_router, prefix=settings.API_STR)
app.include_router(first_aid_router, prefix=settings.API_STR)
app.include_router(gov_router, prefix=settings.API_STR)
app.include_router(notifications_router, prefix=settings.API_STR)


@app.get("/")
def read_root():
    return {
        "status": "online",
        "service": settings.PROJECT_NAME,
        "api_docs": "/docs",
    }
