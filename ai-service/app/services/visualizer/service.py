"""Orchestration for the /visualize endpoints."""
import re
from typing import Any, Dict, Optional

from app.services.visualizer.extractor import extract_model
from app.services.visualizer.flow import build_flow
from app.services.visualizer.renderer import render_schedule
from app.services.visualizer.simulator import simulate


# Notes the extractor writes when it had to guess a value or skip code. Guessing a value would show the learner an
# event that does not match their program, so it makes the program unsupported; skipping a branch or repeating a
# loop once is a stated simplification, so it only makes the match partial.
_GUESSED = ("could not evaluate", "could not resolve")
_SIMPLIFIED = ("only the 'if' branch", "loop body modelled")


def _plain_simplifications(notes) -> list:
    """One sentence per kind of simplification, with the line numbers it applies to, instead of one note per line."""
    loops, branches = [], []
    for n in notes:
        m = re.match(r"line (\d+): (.*)", n)
        if not m:
            continue
        if "loop body modelled" in m.group(2):
            loops.append(int(m.group(1)))
        elif "only the 'if' branch" in m.group(2):
            branches.append(int(m.group(1)))
    out = []
    if loops:
        out.append(f"Loops are shown as a single pass (line{'s' if len(loops) > 1 else ''} {', '.join(map(str, sorted(set(loops))))}), so each thread does its step once here.")
    if branches:
        out.append(f"Only the 'if' branch is shown, not the 'else' (line{'s' if len(branches) > 1 else ''} {', '.join(map(str, sorted(set(branches))))}).")
    return out


def support_verdict(model, sim: Dict[str, Any]) -> Dict[str, Any]:
    """Says how faithfully the simulation represents the learner's program: `supported`, `partial` (modelled with
    stated simplifications) or `unsupported` (nothing should be presented as this program's execution)."""
    guessed = [n for n in model.notes if any(g in n for g in _GUESSED)]
    if model.confidence == "low" or not sim["schedules"]:
        return {
            "status": "unsupported",
            "reasons": [
                "This program does not match a pattern the teaching simulator can model accurately "
                "(threads updating a shared counter, locks, wait/notify). Nothing is drawn rather than inventing events."
            ],
        }
    if guessed:
        return {"status": "unsupported", "reasons": guessed + ["The simulator would have to guess these values, so it does not draw them."]}
    reasons = _plain_simplifications(model.notes)
    if model.source == "llm":
        reasons.append("The thread model was inferred by an AI model, not parsed, so check it against your code.")
    return {"status": "partial" if reasons else "supported", "reasons": reasons}


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
                if k in ("kind", "label", "steps", "finalValues", "expected", "actual", "deadlocked", "threads", "locks", "var")
            }
            for s in sim["schedules"]
        ],
        "hazards": sim["hazards"],
        "svg": svg,
        "notes": notes,
        "confidence": model.confidence,
        "provenance": "teaching-simulation",  # never a JVM trace: a deterministic model of the code's threads
        "support": support_verdict(model, sim),
        "fixSuggestion": sim["fixSuggestion"],
    }


def visualize_flow(code: str, method: Optional[str] = None) -> Dict[str, Any]:
    return build_flow(code, method)
