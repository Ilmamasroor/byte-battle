from typing import List, Optional
from pydantic import BaseModel


class ByteDNARequest(BaseModel):
    technicalLevel: Optional[str] = None
    experience: Optional[str] = None
    goals: Optional[List[str]] = None
    subjects: Optional[List[str]] = None
    interests: Optional[List[str]] = None
    learningPreference: Optional[str] = None


class ByteDNAData(BaseModel):
    technicalLevel: Optional[str] = None
    goals: List[str] = []
    interests: List[str] = []
    learningPreference: Optional[str] = None
    strongAreas: List[str] = []
    weakAreas: List[str] = []


class ByteDNAResponse(BaseModel):
    byteDNA: ByteDNAData
