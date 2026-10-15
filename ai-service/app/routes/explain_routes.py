from fastapi import APIRouter

from app.models.explain_models import ExplainRequest
from app.services import grounding
from app.services.ai_service import generate_explanation

router = APIRouter()


@router.post("/explain")
def explain_concept(request: ExplainRequest):
    reference = None
    if request.canonicalKnowledge:
        import json

        reference = json.dumps(request.canonicalKnowledge, ensure_ascii=False)
    else:
        ref = grounding.grounded_reference(request.concept)
        reference = ref["text"] if ref else None
    explanation = generate_explanation(request.concept, byte_dna=request.byteDNA, reference=reference)
    return {"concept": request.concept, "explanation": explanation, "grounded": reference is not None}
