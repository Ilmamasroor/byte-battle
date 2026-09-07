from fastapi import APIRouter
from app.models.explain_models import ExplainRequest
from app.services.ai_service import generate_explanation

router = APIRouter()

@router.post("/explain")
def explain_concept(request: ExplainRequest):
    explanation = generate_explanation(request.concept)
    return {"concept": request.concept, "explanation": explanation}