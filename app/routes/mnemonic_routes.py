from fastapi import APIRouter

from app.models.mnemonic_models import MnemonicRequest
from app.services.mnemonic_service import generate_mnemonic

router = APIRouter()


@router.post("/ai/mnemonic")
def mnemonic(data: MnemonicRequest):
    try:
        mnemonic_data = generate_mnemonic(data)
        return {
            "concept": data.concept,
            "mnemonic": mnemonic_data
        }

    except Exception as e:
        print("MNEMONIC ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
