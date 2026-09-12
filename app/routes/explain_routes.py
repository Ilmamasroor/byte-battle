from fastapi import APIRouter

from app.models.explain_models import ExplainRequest, ExplainResponse
from app.services.explain_service import generate_explanation

router = APIRouter()


@router.post("/ai/explanation", response_model=ExplainResponse)
def explain(data: ExplainRequest):
    explanation = generate_explanation(data.concept)

    return {
        "concept": data.concept,
        "explanation": explanation
    }
