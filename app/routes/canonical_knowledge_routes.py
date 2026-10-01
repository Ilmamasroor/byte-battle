from fastapi import APIRouter

from app.models.canonical_knowledge_models import CanonicalKnowledgeRequest
from app.services.canonical_knowledge_service import generate_canonical_knowledge

router = APIRouter()


@router.post("/ai/canonical-knowledge")
def canonical_knowledge(data: CanonicalKnowledgeRequest):
    return generate_canonical_knowledge(data)
