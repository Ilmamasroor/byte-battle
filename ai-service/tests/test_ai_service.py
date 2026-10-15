from unittest.mock import Mock

import pytest

from app.core.exceptions import (
    AI_CONFIGURATION_ERROR,
    AI_INVALID_RESPONSE,
    AI_RATE_LIMITED,
    AI_PROVIDER_UNAVAILABLE,
    AIServiceError,
)
from app.services import ai_service


def test_generate_text_success(monkeypatch):
    fake_client = Mock()
    fake_client.generate_text.return_value = "Java is object-oriented."

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    result = ai_service.generate_text("Explain Java")

    assert result == "Java is object-oriented."
    fake_client.generate_text.assert_called_once_with("Explain Java")


def test_generate_text_429(monkeypatch):
    fake_client = Mock()
    fake_client.generate_text.side_effect = AIServiceError(
        AI_RATE_LIMITED,
        "AI service is busy, please try again shortly",
        429,
    )

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    with pytest.raises(AIServiceError) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 429
    assert exc.value.code == AI_RATE_LIMITED


def test_generate_text_auth_error(monkeypatch):
    fake_client = Mock()
    fake_client.generate_text.side_effect = AIServiceError(
        AI_CONFIGURATION_ERROR,
        "AI service is not configured correctly",
        502,
    )

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    with pytest.raises(AIServiceError) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 502
    assert exc.value.code == AI_CONFIGURATION_ERROR


def test_generate_text_server_error(monkeypatch):
    fake_client = Mock()
    fake_client.generate_text.side_effect = AIServiceError(
        AI_PROVIDER_UNAVAILABLE,
        "AI service is temporarily unavailable",
        502,
    )

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    with pytest.raises(AIServiceError) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 502
    assert exc.value.code == AI_PROVIDER_UNAVAILABLE


def test_generate_text_empty_response(monkeypatch):
    fake_client = Mock()
    fake_client.generate_text.side_effect = AIServiceError(
        AI_INVALID_RESPONSE,
        "AI service returned an empty response",
        502,
    )

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    with pytest.raises(AIServiceError) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 502
    assert exc.value.code == AI_INVALID_RESPONSE


def test_generate_json_success(monkeypatch):
    fake_client = Mock()
    fake_client.generate_json.return_value = {
        "hint": "Check the condition first."
    }

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    result = ai_service.generate_json("Return a hint")

    assert result == {"hint": "Check the condition first."}
    fake_client.generate_json.assert_called_once_with("Return a hint")


def test_generate_json_with_codeblock_markdown(monkeypatch):
    fake_client = Mock()
    fake_client.generate_json.return_value = {
        "hint": "Check the condition first."
    }

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    result = ai_service.generate_json("Return a hint")

    assert result == {"hint": "Check the condition first."}


def test_generate_json_invalid_json(monkeypatch):
    fake_client = Mock()
    fake_client.generate_json.side_effect = AIServiceError(
        AI_INVALID_RESPONSE,
        "AI service returned an invalid response",
        502,
    )

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    with pytest.raises(AIServiceError) as exc:
        ai_service.generate_json("Return JSON")

    assert exc.value.status_code == 502
    assert exc.value.code == AI_INVALID_RESPONSE


def test_generate_json_429(monkeypatch):
    fake_client = Mock()
    fake_client.generate_json.side_effect = AIServiceError(
        AI_RATE_LIMITED,
        "AI service is busy, please try again shortly",
        429,
    )

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    with pytest.raises(AIServiceError) as exc:
        ai_service.generate_json("Return JSON")

    assert exc.value.status_code == 429
    assert exc.value.code == AI_RATE_LIMITED


def test_generate_json_response_model_validation(monkeypatch):
    fake_client = Mock()
    fake_client.generate_json.return_value = {
        "hint": "Check the condition first.",
        "nextStep": "Inspect the loop boundary.",
    }

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    from app.models.battle_hint_models import BattleHintResponse

    result = ai_service.generate_json(
        "Return a battle hint",
        BattleHintResponse,
    )

    assert result == {
        "hintLevel": None,
        "hint": "Check the condition first.",
        "nextStep": "Inspect the loop boundary.",
    }
    assert "source" not in result


def test_generate_json_response_model_rejects_empty_text(monkeypatch):
    fake_client = Mock()
    fake_client.generate_json.return_value = {
        "hint": "   ",
        "nextStep": "Inspect the loop boundary.",
    }

    monkeypatch.setattr(ai_service, "llm_client", fake_client)

    from app.models.battle_hint_models import BattleHintResponse

    with pytest.raises(ValueError):
        ai_service.generate_json(
            "Return a battle hint",
            BattleHintResponse,
        )
