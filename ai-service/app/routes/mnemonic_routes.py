from fastapi import APIRouter

from app.models.mnemonic_models import MnemonicRequest
from app.services.mnemonic_service import generate_mnemonic

router = APIRouter()


@router.post("/ai/mnemonic")
def mnemonic(data: MnemonicRequest):
    mnemonic_data = generate_mnemonic(data)

    return {
        "concept": data.concept,
        "mnemonic": mnemonic_data,
    }
