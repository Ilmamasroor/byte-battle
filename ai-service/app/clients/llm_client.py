from abc import ABC, abstractmethod
from typing import Optional


class LLMClient(ABC):
    """What any LLM provider must offer. Business logic depends on this,
    never on a specific provider such as Groq."""

    @abstractmethod
    def generate_text(self, prompt: str, system: Optional[str] = None) -> str:
        ...

    @abstractmethod
    def generate_json(self, prompt: str, system: Optional[str] = None) -> dict:
        ...
