from fastapi import APIRouter
from app.models.byte_dna_models import OnboardingRequest, ByteDNA
from app.services.byte_dna_service import create_byte_dna

router = APIRouter()

@router.post("/onboarding", response_model=ByteDNA)
def onboarding(request: OnboardingRequest):
    return create_byte_dna(request)