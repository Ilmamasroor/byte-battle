import os
from google import genai

api_key = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=api_key)

def generate_explanation(concept: str) -> str:
    prompt = f"Explain the concept '{concept}' in simple, beginner-friendly language, in 2-3 sentences."
    
    response = client.models.generate_content(
        model="gemini-3.6-flash",
        contents=prompt
    )
    
    return response.text