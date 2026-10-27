from fastapi import APIRouter

from app.models.visualize_models import FlowRequest, VisualizeRequest
from app.services.visualizer.service import visualize, visualize_flow

router = APIRouter()


@router.post("/visualize")
def visualize_code(request: VisualizeRequest):
    return visualize(request.code, request.mode, request.concept, request.useLlm)


@router.post("/visualize/flow")
def visualize_control_flow(request: FlowRequest):
    return visualize_flow(request.code, request.method)
