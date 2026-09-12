from fastapi import APIRouter

from app.models.debugging_models import DebuggingHintRequest
from app.services.debugging_service import generate_debugging_hint

router = APIRouter()


@router.post("/debugging/hint")
def debugging_hint(data: DebuggingHintRequest):
    try:
        return generate_debugging_hint(data)

    except Exception as e:
        print("DEBUGGING HINT ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
