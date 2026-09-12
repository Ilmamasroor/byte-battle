from fastapi import APIRouter

from app.models.coding_feedback_models import CodingFeedbackRequest
from app.services.coding_feedback_service import generate_coding_feedback

router = APIRouter()


@router.post("/coding/feedback")
def coding_feedback(data: CodingFeedbackRequest):
    try:
        return generate_coding_feedback(data)

    except Exception as e:
        print("CODING FEEDBACK ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
