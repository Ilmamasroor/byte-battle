from fastapi import APIRouter
from app.models.byte_dna_evolution_models import ByteDNAEvolutionRequest, ByteDNAEvolutionResponse
from app.services.byte_dna_evolution_service import evolve_byte_dna

router = APIRouter()

@router.post("/byte-dna/evolve", response_model=ByteDNAEvolutionResponse)
def evolve(request: ByteDNAEvolutionRequest):
    return evolve_byte_dna(request)