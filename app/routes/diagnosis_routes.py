from fastapi import APIRouter
from app.models.diagnosis_models import DiagnosisRequest, DiagnosisResponse
from app.services.diagnosis_service import predict_diagnosis

router = APIRouter()

@router.post("/diagnose", response_model=DiagnosisResponse)
def diagnose(request: DiagnosisRequest):
    return predict_diagnosis(request)

from app.models.diagnosis_models import AggregatedDiagnosisRequest, AggregatedDiagnosisResponse
from app.services.diagnosis_service import aggregate_diagnosis

@router.post("/diagnose/summary", response_model=AggregatedDiagnosisResponse)
def diagnose_summary(request: AggregatedDiagnosisRequest):
    return aggregate_diagnosis(request)