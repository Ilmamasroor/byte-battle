from fastapi import APIRouter

from app.models.canonical_knowledge_models import CanonicalKnowledgeRequest
from app.services.canonical_knowledge_service import generate_canonical_knowledge

router = APIRouter()


@router.post("/ai/canonical-knowledge")
def canonical_knowledge(data: CanonicalKnowledgeRequest):
    try:
        return generate_canonical_knowledge(data)

    except Exception as e:
        print("CANONICAL KNOWLEDGE ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
