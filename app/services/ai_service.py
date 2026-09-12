import json
import os

from google import genai
from google.genai import types


api_key = os.environ.get("GEMINI_API_KEY")

client = genai.Client(api_key=api_key)

MODEL_NAME = "gemini-3.6-flash"


def generate_text(prompt: str) -> str:
    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt
    )

    if not response.text:
        raise ValueError("Gemini returned an empty response")

    return response.text


def generate_json(prompt: str) -> dict:
    response = client.models.generate_content(
        model=MODEL_NAME,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json"
        )
    )

    if not response.text:
        raise ValueError("Gemini returned an empty response")

    return json.loads(response.text)


def generate_explanation(concept: str) -> str:
    prompt = f"""
Explain the concept '{concept}' in simple, beginner-friendly language,
in 2-3 sentences.
"""

    return generate_text(prompt)
