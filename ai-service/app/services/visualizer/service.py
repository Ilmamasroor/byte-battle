"""Orchestration for the /visualize endpoints."""
from typing import Any, Dict, Optional

from app.services.visualizer.extractor import extract_model
from app.services.visualizer.flow import build_flow
from app.services.visualizer.renderer import render_schedule
from app.services.visualizer.simulator import simulate


def visualize(code: str, mode: str = "auto", concept: Optional[str] = None, use_llm: bool = True) -> Dict[str, Any]:
    model = extract_model(code, use_llm=use_llm)
    sim = simulate(model, mode)
    svg: Dict[str, str] = {}
    for sched in sim["schedules"]:
        key = sched["kind"].lower()
        if key not in svg:
            svg[key] = render_schedule(model, sched, sim["hazards"])
    notes = list(model.notes) + [n for n in sim["notes"] if n not in model.notes]
    if concept:
        notes.append(f"concept: {concept[:80]}")
    return {
        "model": model.model_dump(),
        "schedules": [
            {
                k: v
                for k, v in s.items()
                if k in ("kind", "steps", "finalValues", "expected", "actual", "deadlocked", "threads", "locks", "var")
            }
            for s in sim["schedules"]
        ],
        "hazards": sim["hazards"],
        "svg": svg,
        "notes": notes,
        "confidence": model.confidence,
        "fixSuggestion": sim["fixSuggestion"],
    }


def visualize_flow(code: str, method: Optional[str] = None) -> Dict[str, Any]:
    return build_flow(code, method)
