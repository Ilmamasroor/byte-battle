from pydantic import BaseModel, ConfigDict, Field


class LLMResponse(BaseModel):
    """Base class for validated LLM response models.

    Whitespace-only string values are normalized so they fail
    min_length validation when a response field must contain text.
    """

    model_config = ConfigDict(str_strip_whitespace=True)

    source: str = Field(default="AI", exclude=True)
