import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

os.environ.setdefault("GROQ_API_KEY", "mock_groq_api_key_for_testing")


class OfflineClient:
    """Default LLM for tests: never touches the network."""

    def generate_text(self, prompt, system=None):
        from app.core.exceptions import AI_PROVIDER_UNAVAILABLE, AIServiceError

        raise AIServiceError(AI_PROVIDER_UNAVAILABLE, "offline test client", 502)

    generate_json = generate_text


@pytest.fixture(autouse=True)
def _offline_llm(monkeypatch):
    from app.services import ai_service

    monkeypatch.setattr(ai_service, "llm_client", OfflineClient())
