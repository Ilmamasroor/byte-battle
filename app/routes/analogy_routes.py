from fastapi import APIRouter

from app.models.analogy_models import AnalogyRequest
from app.services.analogy_service import generate_analogy

router = APIRouter()


@router.post("/ai/analogy")
def analogy(data: AnalogyRequest):
    try:
        analogy_data = generate_analogy(data)
        return {
            "concept": data.concept,
            **analogy_data
        }

    except Exception as e:
        print("ANALOGY ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
