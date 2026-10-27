from fastapi import APIRouter

from app.models.debugging_models import DebuggingHintRequest
from app.services.debugging_service import generate_debugging_hint

router = APIRouter()


@router.post("/debugging/hint")
def debugging_hint(data: DebuggingHintRequest):
    return generate_debugging_hint(data)
