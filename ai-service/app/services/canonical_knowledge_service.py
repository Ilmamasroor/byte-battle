from app.core.prompt_safety import SAFETY_SYSTEM, wrap_learner_data, wrap_reference
from app.models.canonical_knowledge_models import (
    CanonicalKnowledgeRequest,
    CanonicalKnowledgeResponse,
)
from app.services import grounding
from app.services.ai_service import generate_json


def _concept_name(concept) -> str:
    if isinstance(concept, dict):
        return str(concept.get("conceptName") or concept.get("name") or concept.get("topic") or "this concept")
    return str(concept or "this concept")


def generate_canonical_knowledge(data: CanonicalKnowledgeRequest) -> dict:
    """Grounded canonical knowledge. The LLM only rephrases/structures curated
    content from content/parsed; it never invents facts from a concept name."""
    ref = grounding.grounded_reference(data.concept)

    if ref is None:
        name = _concept_name(data.concept)
        return CanonicalKnowledgeResponse(
            keyPoints=[
                f"No curated reference material is available yet for '{name}'. "
                "Canonical knowledge must be authored or reviewed manually."
            ],
            rules=[],
            examples=[],
            grounded=False,
            sources=[],
            requiresManualAuthoring=True,
        ).model_dump(exclude={"source"})

    prompt = f"""
You are Byte Battle's technical knowledge structurer.

Turn the REFERENCE MATERIAL into SHORT canonical technical knowledge for the concept.

CONCEPT:
{wrap_learner_data("concept", data.concept, 500)}

REFERENCE MATERIAL (the only allowed factual base):
{wrap_reference("curated_content", ref["text"])}

RULES:

1. Use ONLY facts stated in or directly demonstrated by the reference material.
2. Do NOT add facts from your own memory. If the material does not support a point, omit it.
3. Give up to 2 key points, up to 2 important rules, and up to 1 simple example (taken from or adapted from the material).
4. Keep every point short and clear.
5. Return only valid JSON.

RETURN EXACTLY:

{{
    "keyPoints": ["..."],
    "rules": ["..."],
    "examples": ["..."]
}}
"""
    result = generate_json(prompt, CanonicalKnowledgeResponse, system=SAFETY_SYSTEM)
    result["grounded"] = True
    result["sources"] = ref["sources"]
    result["requiresManualAuthoring"] = None
    return result
