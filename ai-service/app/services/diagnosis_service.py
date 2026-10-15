import logging
from typing import Any, Dict, Optional

from app.core.exceptions import MODEL_LOAD_ERROR, AIServiceError
from app.core.paths import MODELS_DIR
from app.models.diagnosis_models import (
    AggregatedDiagnosisRequest,
    AggregatedDiagnosisResponse,
    DiagnosisRequest,
    DiagnosisResponse,
)

logger = logging.getLogger(__name__)

MODEL_FILES = {
    "battle": "battle_model.pkl",
    "interview": "interview_model.pkl",
    "coding": "coding_model.pkl",
    "debugging": "debugging_model.pkl",
}

_models: Dict[str, Any] = {}
_load_errors: Dict[str, str] = {}
_loaded_attempted = False


def _load_one(name: str):
    """Load a .pkl, only from the repo's models_store dir, with a clear error."""
    import joblib  # imported lazily so a broken ML stack cannot break app import

    path = (MODELS_DIR / MODEL_FILES[name]).resolve()
    if MODELS_DIR.resolve() not in path.parents:
        raise AIServiceError(MODEL_LOAD_ERROR, f"Refusing to load model outside models_store: {name}", 500)
    if not path.is_file():
        raise AIServiceError(MODEL_LOAD_ERROR, f"Model file missing: {MODEL_FILES[name]}", 500)
    try:
        return joblib.load(path)
    except Exception as exc:  # noqa: BLE001 - any unpickle/version failure
        raise AIServiceError(
            MODEL_LOAD_ERROR,
            f"Could not load model {MODEL_FILES[name]}: {type(exc).__name__}",
            500,
        ) from exc


def load_models(force: bool = False) -> Dict[str, Any]:
    global _loaded_attempted
    if _loaded_attempted and not force:
        return _models
    _models.clear()
    _load_errors.clear()
    for name in MODEL_FILES:
        try:
            _models[name] = _load_one(name)
        except AIServiceError as exc:
            _load_errors[name] = exc.message
            logger.warning("diagnosis model '%s' unavailable: %s", name, exc.message)
    _loaded_attempted = True
    return _models


def loaded_model_count() -> int:
    return len(load_models())


def model_load_errors() -> Dict[str, str]:
    load_models()
    return dict(_load_errors)


# ---------------------------------------------------------------- fallbacks

def _pct(value: float) -> float:
    return max(0.0, min(100.0, value))


def _ratio01(value: Optional[float]) -> Optional[float]:
    if value is None:
        return None
    v = float(value)
    if v > 1.0:
        v = v / 100.0
    return max(0.0, min(1.0, v))


def _hint_dependency(hints: Optional[int]) -> float:
    return round(_pct((hints or 0) * 15), 2)


def _blend(parts):
    """parts: [(value or None, weight)] -> weighted mean of available parts."""
    avail = [(v, w) for v, w in parts if v is not None]
    if not avail:
        return None
    return sum(v * w for v, w in avail) / sum(w for _, w in avail)


def _fallback(request: DiagnosisRequest, response: DiagnosisResponse) -> DiagnosisResponse:
    """Deterministic non-ML estimate mirroring how the training data was built."""
    kind = request.activityType
    response.hintDependency = _hint_dependency(request.hintsUsed)

    if kind in ("battle", "interview"):
        acc = _ratio01(request.accuracy)
        score = request.score
        if score is None and acc is not None:
            score = acc * 100
        acc100 = acc * 100 if acc is not None else None
        if kind == "interview":
            cu = _blend([(score, 0.6), (acc100, 0.4)])
        else:
            cu = _blend([(score, 0.5), (acc100, 0.5)])
        response.conceptUnderstanding = round(_pct(cu), 2) if cu is not None else None
        if kind == "battle":
            attempts = (
                max(0.0, 100 - request.attemptCount * 12) if request.attemptCount is not None else None
            )
            speed = (
                max(0.0, 100 - request.timeSpentSeconds / 3)
                if request.timeSpentSeconds is not None
                else None
            )
            dm = _blend([(acc100, 0.5), (attempts, 0.3), (speed, 0.2)])
            response.decisionMaking = round(_pct(dm), 2) if dm is not None else None

    elif kind in ("coding", "debugging"):
        total = request.testCasesTotal
        ratio = None
        if total and total > 0 and request.testCasesPassed is not None:
            ratio = max(0.0, min(1.0, request.testCasesPassed / total))
        elif request.success is not None:
            ratio = 1.0 if request.success else 0.0
        if ratio is not None:
            success = request.success if request.success is not None else ratio > 0.7
            response.boundaryConditions = round(_pct(ratio * 100 * 0.9), 2)
            response.codingImplementation = round(
                _pct(ratio * 100 * 0.7 + (30 if success else 0)), 2
            )
    return response


def _features(request: DiagnosisRequest) -> Optional[Dict[str, Any]]:
    """Model features, or None when any required input is null."""
    kind = request.activityType
    if kind == "battle":
        f = {
            "accuracy": request.accuracy,
            "score": request.score,
            "attemptCount": request.attemptCount,
            "timeSpentSeconds": request.timeSpentSeconds,
            "hintsUsed": request.hintsUsed,
        }
    elif kind == "interview":
        f = {"accuracy": request.accuracy, "score": request.score, "hintsUsed": request.hintsUsed}
    elif kind in ("coding", "debugging"):
        f = {
            "testCasesPassed": request.testCasesPassed,
            "testCasesTotal": request.testCasesTotal,
            "success": None if request.success is None else int(request.success),
            "hintsUsed": request.hintsUsed,
        }
    else:
        return None
    if any(v is None for v in f.values()):
        return None
    return f


def _predict_ml(request: DiagnosisRequest, response: DiagnosisResponse) -> bool:
    kind = request.activityType
    model = load_models().get(kind)
    feats = _features(request)
    if model is None or feats is None:
        return False
    try:
        import pandas as pd

        pred = model.predict(pd.DataFrame([feats]))[0]
        if kind == "battle":
            response.conceptUnderstanding = round(float(pred[0]), 2)
            response.decisionMaking = round(float(pred[1]), 2)
            response.hintDependency = round(float(pred[2]), 2)
        elif kind == "interview":
            response.conceptUnderstanding = round(float(pred[0]), 2)
            response.hintDependency = round(float(pred[1]), 2)
        else:
            response.codingImplementation = round(float(pred[0]), 2)
            response.boundaryConditions = round(float(pred[1]), 2)
            response.hintDependency = round(float(pred[2]), 2)
        return True
    except Exception as exc:  # noqa: BLE001
        logger.warning("diagnosis model '%s' predict failed: %s", kind, type(exc).__name__)
        return False


def predict_diagnosis_with_method(request: DiagnosisRequest):
    """Returns (response, method) where method is 'ml', 'fallback' or 'none'."""
    response = DiagnosisResponse(userId=request.userId, activityType=request.activityType)
    if request.activityType not in MODEL_FILES:
        return response, "none"
    if _predict_ml(request, response):
        return response, "ml"
    return _fallback(request, response), "fallback"


def predict_diagnosis(request: DiagnosisRequest) -> DiagnosisResponse:
    return predict_diagnosis_with_method(request)[0]


def aggregate_diagnosis(request: AggregatedDiagnosisRequest) -> AggregatedDiagnosisResponse:
    dimension_values = {
        "conceptUnderstanding": [],
        "decisionMaking": [],
        "boundaryConditions": [],
        "codingImplementation": [],
        "hintDependency": [],
    }

    for activity in request.activities:
        result = predict_diagnosis(activity)
        for dimension in dimension_values:
            value = getattr(result, dimension)
            if value is not None:
                dimension_values[dimension].append(value)

    final_scores = {
        dimension: round(sum(values) / len(values), 2) if values else None
        for dimension, values in dimension_values.items()
    }

    return AggregatedDiagnosisResponse(userId=request.userId, **final_scores)
