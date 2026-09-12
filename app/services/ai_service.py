"""
Shared Gemini client setup and generation helper.

Every feature service in app/services/ should import `generate_json`
from here instead of creating its own `genai.Client`. This keeps the
client, model name, and error/parsing behavior consistent across all
LLM-based features (per the project handoff, General Rule #1).
"""

import os
import json

from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=api_key)

# Single source of truth for the model name used across all features.
MODEL_NAME = "gemini-3.6-flash"


def generate_text(prompt: str) -> str:
    """
    Calls Gemini with the given prompt and returns plain text (no JSON
    parsing). Use this for features whose output is a single free-text
    field (e.g. Explain), where the route itself wraps the text into a
    JSON response — not Gemini.
    """
    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt
    )
    return response.text


def generate_json(prompt: str) -> dict:
    """
    Calls Gemini with the given prompt, forcing JSON output, and returns
    the parsed dict.

    Raises:
        ValueError: if Gemini returns an empty response.
        json.JSONDecodeError: if Gemini's text isn't valid JSON.
    """
    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json"
        )
    )

    print("GEMINI RESPONSE:", repr(response.text))

    if not response.text:
        raise ValueError("Gemini returned an empty response")

    return json.loads(response.text)
