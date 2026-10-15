from fastapi import APIRouter

from app.models.ai_process_models import AiRequest, AiResponse
from app.services.ai_process_service import process

router = APIRouter()


@router.post("/ai/process", response_model=AiResponse)
def ai_process(request: AiRequest):
    return process(request)
