from fastapi import APIRouter

from app.models.byte_dna_models import ByteDNARequest
from app.services.byte_dna_service import create_byte_dna

router = APIRouter()


@router.post("/ai/byte-dna")
def byte_dna(data: ByteDNARequest):
    try:
        byte_dna_data = create_byte_dna(data)
        return {"byteDNA": byte_dna_data}

    except Exception as e:
        print("BYTE DNA ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
