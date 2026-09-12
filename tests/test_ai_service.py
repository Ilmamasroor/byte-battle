from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.services import ai_service


class FakeGeminiError(Exception):
    def __init__(self, status_code):
        super().__init__(f"Gemini error {status_code}")
        self.status_code = status_code


def test_generate_text_success(monkeypatch):
    fake_response = SimpleNamespace(text="Java is object-oriented.")

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        lambda **kwargs: fake_response,
    )

    result = ai_service.generate_text("Explain Java")

    assert result == "Java is object-oriented."


def test_generate_text_429(monkeypatch):
    def raise_error(**kwargs):
        raise FakeGeminiError(429)

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        raise_error,
    )

    with pytest.raises(HTTPException) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 429
    assert "quota" in exc.value.detail.lower()


def test_generate_text_auth_error(monkeypatch):
    def raise_error(**kwargs):
        raise FakeGeminiError(401)

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        raise_error,
    )

    with pytest.raises(HTTPException) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 401


def test_generate_text_server_error(monkeypatch):
    def raise_error(**kwargs):
        raise FakeGeminiError(503)

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        raise_error,
    )

    with pytest.raises(HTTPException) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 502


def test_generate_text_empty_response(monkeypatch):
    fake_response = SimpleNamespace(text="")

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        lambda **kwargs: fake_response,
    )

    with pytest.raises(HTTPException) as exc:
        ai_service.generate_text("Explain Java")

    assert exc.value.status_code == 502


def test_generate_json_success(monkeypatch):
    fake_response = SimpleNamespace(
        text='{"hint": "Check the condition first."}'
    )

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        lambda **kwargs: fake_response,
    )

    result = ai_service.generate_json("Return a hint")

    assert result == {"hint": "Check the condition first."}


def test_generate_json_invalid_json(monkeypatch):
    fake_response = SimpleNamespace(
        text="this is not valid json"
    )

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        lambda **kwargs: fake_response,
    )

    with pytest.raises(HTTPException) as exc:
        ai_service.generate_json("Return JSON")

    assert exc.value.status_code == 502
    assert "invalid json" in exc.value.detail.lower()


def test_generate_json_429(monkeypatch):
    def raise_error(**kwargs):
        raise FakeGeminiError(429)

    monkeypatch.setattr(
        ai_service.client.models,
        "generate_content",
        raise_error,
    )

    with pytest.raises(HTTPException) as exc:
        ai_service.generate_json("Return JSON")

    assert exc.value.status_code == 429
