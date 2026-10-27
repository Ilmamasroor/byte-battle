"""Generic POST /ai/process dispatcher (Java AiRequest -> AiResponse).

Spring Boot stays authoritative for scoring/progress; this only interprets
(diagnosis) and generates (explanation)."""
import json
from typing import Any, Dict, Optional

from app.core.exceptions import AI_UNSUPPORTED_OPERATION, AIServiceError
from app.models.ai_process_models import AiRequest, AiResponse
from app.models.diagnosis_models import DiagnosisRequest
from app.services import grounding
from app.services.ai_service import MODEL_NAME, generate_explanation
from app.services.diagnosis_service import predict_diagnosis_with_method

SUPPORTED = ("explanation", "diagnosis")


def _concept_dict(req: AiRequest) -> Dict[str, Any]:
    return req.concept.model_dump(exclude_none=True) if req.concept else {}


def _canonical(req: AiRequest) -> Dict[str, Any]:
    return req.canonicalKnowledge.model_dump(exclude_none=True) if req.canonicalKnowledge else {}


def _explanation(req: AiRequest) -> AiResponse:
    concept = _concept_dict(req)
    name = concept.get("conceptName") or concept.get("topic")
    if not name:
        raise AIServiceError("VALIDATION_ERROR", "concept.conceptName is required for 'explanation'", 422)
    canonical = _canonical(req)
    reference: Optional[str] = None
    sources = []
    if canonical and any(canonical.values()):
        reference = json.dumps(canonical, ensure_ascii=False)
    else:
        ref = grounding.grounded_reference(concept)
        if ref:
            reference, sources = ref["text"], ref["sources"]
    dna = req.byteDNA.model_dump(exclude_none=True) if req.byteDNA else None
    text = generate_explanation(name, byte_dna=dna, reference=reference)
    return AiResponse(
        success=True,
        operation="explanation",
        content=text,
        metadata={
            "conceptName": name,
            "grounded": reference is not None,
            "groundedIn": "request" if canonical and any(canonical.values()) else ("content" if sources else "none"),
            "sources": sources,
            "personalized": bool(dna),
            "model": MODEL_NAME,
        },
    )


def _diagnosis(req: AiRequest) -> AiResponse:
    d = req.diagnosis
    p = req.performance
    activity = ((d.activityType if d else None) or "").strip().lower()
    if not activity:
        activity = "coding" if d and (d.testCasesTotal or d.sourceCode) else "battle"
    dr = DiagnosisRequest(
        userId=req.userId or "unknown",
        activityType=activity,
        accuracy=p.accuracy if p else None,
        score=p.score if p else None,
        attemptCount=p.attemptCount if p else None,
        timeSpentSeconds=p.timeSpentSeconds if p else None,
        testCasesPassed=d.testCasesPassed if d else None,
        testCasesTotal=d.testCasesTotal if d else None,
        success=p.success if p else None,
        hintsUsed=(p.hintsUsed if p and p.hintsUsed is not None else 0),
    )
    result, method = predict_diagnosis_with_method(dr)
    scores = {
        k: v
        for k, v in result.model_dump().items()
        if k not in ("userId", "activityType") and v is not None
    }
    return AiResponse(
        success=True,
        operation="diagnosis",
        content=json.dumps(scores),
        metadata={
            "activityType": activity,
            "scores": scores,
            "method": method,
            "errorCategory": d.errorCategory if d else None,
        },
    )


def process(req: AiRequest) -> AiResponse:
    op = (req.operation or "").strip().lower()
    if op == "explanation":
        return _explanation(req)
    if op == "diagnosis":
        return _diagnosis(req)
    raise AIServiceError(
        AI_UNSUPPORTED_OPERATION,
        f"Unsupported operation '{(req.operation or '')[:40]}'. Supported: {', '.join(SUPPORTED)}",
        422,
    )
