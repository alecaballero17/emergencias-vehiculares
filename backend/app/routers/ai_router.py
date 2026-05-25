"""Router de endpoints de IA: clasificación en español y estimación de costos."""
from fastapi import APIRouter, Depends
from app.schemas.incident import CostEstimateRequest, CostEstimateResponse
from app.ai.cost_estimator import estimate_repair_cost
from app.utils.security import get_current_user

router = APIRouter(prefix="/api/ai", tags=["Inteligencia Artificial"])


@router.post("/estimate-cost", response_model=CostEstimateResponse)
async def estimate_cost(data: CostEstimateRequest, current_user=Depends(get_current_user)):
    """
    Estima un rango de costos de reparación en bolivianos usando IA.
    Recibe la descripción del daño y opcionalmente el tipo de incidente.
    """
    return await estimate_repair_cost(data.description, data.incident_type)
