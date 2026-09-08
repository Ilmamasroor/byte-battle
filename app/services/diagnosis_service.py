import joblib
import pandas as pd
from app.models.diagnosis_models import DiagnosisRequest, DiagnosisResponse

battle_model = joblib.load("models_store/battle_model.pkl")
interview_model = joblib.load("models_store/interview_model.pkl")
coding_model = joblib.load("models_store/coding_model.pkl")
debugging_model = joblib.load("models_store/debugging_model.pkl")

def predict_diagnosis(request: DiagnosisRequest) -> DiagnosisResponse:
    response = DiagnosisResponse(userId=request.userId, activityType=request.activityType)

    if request.activityType == "battle":
        X = pd.DataFrame([{
            "accuracy": request.accuracy,
            "score": request.score,
            "attemptCount": request.attemptCount,
            "timeSpentSeconds": request.timeSpentSeconds,
            "hintsUsed": request.hintsUsed,
        }])
        pred = battle_model.predict(X)[0]
        response.conceptUnderstanding = round(float(pred[0]), 2)
        response.decisionMaking = round(float(pred[1]), 2)
        response.hintDependency = round(float(pred[2]), 2)

    elif request.activityType == "interview":
        X = pd.DataFrame([{
            "accuracy": request.accuracy,
            "score": request.score,
            "hintsUsed": request.hintsUsed,
        }])
        pred = interview_model.predict(X)[0]
        response.conceptUnderstanding = round(float(pred[0]), 2)
        response.hintDependency = round(float(pred[1]), 2)

    elif request.activityType == "coding":
        X = pd.DataFrame([{
            "testCasesPassed": request.testCasesPassed,
            "testCasesTotal": request.testCasesTotal,
            "success": int(request.success),
            "hintsUsed": request.hintsUsed,
        }])
        pred = coding_model.predict(X)[0]
        response.codingImplementation = round(float(pred[0]), 2)
        response.boundaryConditions = round(float(pred[1]), 2)
        response.hintDependency = round(float(pred[2]), 2)

    elif request.activityType == "debugging":
        X = pd.DataFrame([{
            "testCasesPassed": request.testCasesPassed,
            "testCasesTotal": request.testCasesTotal,
            "success": int(request.success),
            "hintsUsed": request.hintsUsed,
        }])
        pred = debugging_model.predict(X)[0]
        response.codingImplementation = round(float(pred[0]), 2)
        response.boundaryConditions = round(float(pred[1]), 2)
        response.hintDependency = round(float(pred[2]), 2)

    return response

from app.models.diagnosis_models import AggregatedDiagnosisRequest, AggregatedDiagnosisResponse

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