from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession
from app.api import deps
from app.db.session import get_db
from app.models.user import User
from app.services.gov import GovService
from app.websocket.connection_manager import manager
from app.core.logging import logger

router = APIRouter(prefix="/gov", tags=["government"])
gov_guard = Depends(deps.require_roles("admin", "gov"))


@router.websocket("/ws")
async def gov_websocket(websocket: WebSocket):
    logger.info("New Gov WebSocket connection request received")
    await manager.connect_gov(websocket)
    try:
        while True:
            # Maintain connection, listen for any messages or heartbeat
            await websocket.receive_text()
    except WebSocketDisconnect:
        await manager.disconnect_gov(websocket)
    except Exception as e:
        logger.error(f"Gov WebSocket exception: {e}")
        await manager.disconnect_gov(websocket)


@router.get("/dashboard")
async def get_gov_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = gov_guard,
):
    service = GovService(db)
    return await service.get_dashboard_stats()


@router.get("/operations")
async def get_operations_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = gov_guard,
):
    service = GovService(db)
    return await service.get_operations_dashboard()


@router.get("/heatmaps")
async def get_heatmap_coordinates(
    db: AsyncSession = Depends(get_db),
    current_user: User = gov_guard,
):
    service = GovService(db)
    return await service.get_heatmap_coordinates()
