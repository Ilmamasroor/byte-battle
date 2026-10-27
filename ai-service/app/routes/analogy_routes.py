from fastapi import APIRouter

from app.models.analogy_models import AnalogyRequest
from app.services.analogy_service import generate_analogy

router = APIRouter()


@router.post("/ai/analogy")
def analogy(data: AnalogyRequest):
    analogy_data = generate_analogy(data)

    return {
        "concept": data.concept,
        **analogy_data,
    }
