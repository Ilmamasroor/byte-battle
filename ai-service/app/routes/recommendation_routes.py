from fastapi import APIRouter
from app.models.recommendation_models import RecommendationRequest, RecommendationResponse
from app.services.recommendation_service import get_recommendation

router = APIRouter()

@router.post("/recommend", response_model=RecommendationResponse)
def recommend(request: RecommendationRequest):
    return get_recommendation(request)