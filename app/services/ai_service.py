import json
import os

from fastapi import HTTPException
from google import genai
from google.genai import types


api_key = os.environ.get("GEMINI_API_KEY")

if not api_key:
    raise RuntimeError("GEMINI_API_KEY environment variable is not set")

client = genai.Client(api_key=api_key)

MODEL_NAME = "gemini-3.6-flash"


def _gemini_error(exc: Exception) -> HTTPException:
    """
    Convert Gemini/Google API failures into proper HTTP responses.

    This prevents FastAPI from returning HTTP 200 with an error JSON body,
    which could otherwise be interpreted by Spring as a successful DTO.
    """
    status_code = getattr(exc, "status_code", None)

    if status_code is None:
        response = getattr(exc, "response", None)
        status_code = getattr(response, "status_code", None)

    if status_code == 429:
        return HTTPException(
            status_code=429,
            detail="Gemini API quota/rate limit exceeded"
        )

    if status_code in (400, 401, 403):
        return HTTPException(
            status_code=status_code,
            detail="Gemini API request/authentication failed"
        )

    if status_code in (500, 502, 503, 504):
        return HTTPException(
            status_code=502,
            detail="Gemini API is temporarily unavailable"
        )

    return HTTPException(
        status_code=502,
        detail=f"Gemini API request failed: {exc}"
    )


def generate_text(prompt: str) -> str:
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt
        )
    except Exception as exc:
        raise _gemini_error(exc) from exc

    if not response.text:
        raise HTTPException(
            status_code=502,
            detail="Gemini returned an empty response"
        )

    return response.text


def generate_json(prompt: str) -> dict:
    try:
        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json"
            )
        )
    except Exception as exc:
        raise _gemini_error(exc) from exc

    if not response.text:
        raise HTTPException(
            status_code=502,
            detail="Gemini returned an empty response"
        )

    try:
        return json.loads(response.text)
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=502,
            detail="Gemini returned invalid JSON"
        ) from exc


def generate_explanation(concept: str) -> str:
    prompt = f"""
Explain the concept '{concept}' in simple, beginner-friendly language,
in 2-3 sentences.
"""

    return generate_text(prompt)
