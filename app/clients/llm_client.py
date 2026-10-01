from abc import ABC, abstractmethod


class LLMClient(ABC):
    """What any LLM provider must offer. Business logic depends on this,
    never on a specific provider such as Groq."""

    @abstractmethod
    def generate_text(self, prompt: str) -> str:
        ...

    @abstractmethod
    def generate_json(self, prompt: str) -> dict:
        ...