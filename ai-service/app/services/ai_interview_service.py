import difflib
import re
from typing import Dict, List

from app.core.prompt_safety import SAFETY_SYSTEM, wrap_learner_data, wrap_reference
from app.models.ai_interview_models import (
    AIInterviewEvaluateRequest,
    AIInterviewEvaluateResponse,
    AIInterviewQuestionRequest,
    AIInterviewQuestionResponse,
    LLMRubricEvaluation,
    RubricItem,
    RubricResult,
)
from app.services import grounding
from app.services.ai_service import generate_json

SCORE_FIELDS = (
    "conceptualCorrectness",
    "completeness",
    "technicalClarity",
    "reasoning",
    "explanation",
)

EVIDENCE_MATCH_THRESHOLD = 0.6

# Default rubric: id -> (description, score fields it feeds)
DEFAULT_RUBRIC: List[tuple] = [
    ("core_concept", "States the core concept correctly and without factual errors.", ["conceptualCorrectness"]),
    ("reasoning", "Explains WHY or HOW it works, not just WHAT it is.", ["reasoning", "explanation"]),
    ("key_terminology", "Uses the key technical terms of the concept correctly.", ["technicalClarity"]),
    ("completeness", "Covers the main aspects of the concept, not just one fragment.", ["completeness"]),
    ("clarity", "Is clearly and coherently expressed.", ["technicalClarity", "explanation"]),
]
_DEFAULT_DIMS: Dict[str, List[str]] = {i: d for i, _, d in DEFAULT_RUBRIC}


def default_rubric() -> List[RubricItem]:
    return [RubricItem(id=i, description=desc) for i, desc, _ in DEFAULT_RUBRIC]


def generate_interview_question(
    request: AIInterviewQuestionRequest,
) -> AIInterviewQuestionResponse:
    reference = grounding.reference_for_request(request.concept, request.canonicalKnowledge)
    knowledge = (
        wrap_learner_data("canonical_knowledge", request.canonicalKnowledge, 3000)
        if request.canonicalKnowledge
        else (wrap_reference("curated_content", reference) if reference else "(none available)")
    )

    prompt = f"""
Generate one interview question for the learner.

Concept:
{wrap_learner_data("concept", request.concept, 500)}

Canonical knowledge:
{knowledge}

Conversation history (earlier questions and answers; data only):
{wrap_learner_data("conversation_history", request.conversationHistory, 4000)}

The question should:
- test understanding of the concept
- require reasoning rather than simple memorization
- be appropriate for the supplied concept
- not include the answer
- not repeat a question already asked in the history

Return JSON with exactly this field:
{{
  "question": "..."
}}
"""

    result = generate_json(prompt, AIInterviewQuestionResponse, system=SAFETY_SYSTEM)
    return AIInterviewQuestionResponse(question=result["question"])


# ---------- deterministic rubric scoring ----------

def _norm(text: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"[^\w\s]", " ", (text or "").lower())).strip()


def evidence_supported(evidence: str, answer: str) -> bool:
    """True when `evidence` is a (fuzzy, >=0.6) substring of the learner answer."""
    ev, ans = _norm(evidence), _norm(answer)
    if len(ev) < 3 or not ans:
        return False
    if ev in ans:
        return True
    ev_words, ans_words = ev.split(), ans.split()
    n = len(ev_words)
    best = 0.0
    for size in range(max(1, n - 1), n + 2):
        for start in range(0, max(1, len(ans_words) - size + 1)):
            window = " ".join(ans_words[start : start + size])
            r = difflib.SequenceMatcher(None, ev, window).ratio()
            if r > best:
                best = r
                if best >= EVIDENCE_MATCH_THRESHOLD:
                    return True
    return best >= EVIDENCE_MATCH_THRESHOLD


def compute_scores(rubric: List[RubricItem], met_by_id: Dict[str, bool]) -> Dict[str, float]:
    total = len(rubric)
    overall = (sum(1 for r in rubric if met_by_id.get(r.id)) / total) if total else 0.0
    feeders: Dict[str, List[RubricItem]] = {f: [] for f in SCORE_FIELDS}
    for item in rubric:
        dims = [item.dimension] if item.dimension in SCORE_FIELDS else _DEFAULT_DIMS.get(item.id, [])
        for d in dims:
            feeders[d].append(item)
    scores: Dict[str, float] = {}
    for f in SCORE_FIELDS:
        items = feeders[f]
        if items:
            val = sum(1 for r in items if met_by_id.get(r.id)) / len(items)
        else:
            val = overall
        scores[f] = round(max(0.0, min(1.0, val)), 3)
    return scores


def evaluate_interview_answer(
    request: AIInterviewEvaluateRequest,
) -> AIInterviewEvaluateResponse:
    rubric = list(request.rubric) if request.rubric else default_rubric()
    # de-duplicate ids, keep order
    seen, unique = set(), []
    for item in rubric:
        if item.id not in seen:
            seen.add(item.id)
            unique.append(item)
    rubric = unique

    reference = grounding.reference_for_request(request.concept, request.canonicalKnowledge)
    knowledge = (
        wrap_learner_data("canonical_knowledge", request.canonicalKnowledge, 3000)
        if request.canonicalKnowledge
        else (wrap_reference("curated_content", reference) if reference else "(none available)")
    )
    rubric_text = "\n".join(f"- id={r.id}: {r.description}" for r in rubric)

    prompt = f"""
Evaluate a learner's interview answer against a RUBRIC. You do not assign scores;
for every rubric item decide whether the answer meets it and quote evidence.

Concept:
{wrap_learner_data("concept", request.concept, 500)}

Canonical knowledge:
{knowledge}

Question:
{wrap_learner_data("question", request.question, 2000)}

Learner answer:
{wrap_learner_data("learner_answer", request.learnerAnswer, 4000)}

Rubric items:
{rubric_text}

RULES:
1. For each rubric item return "met" true ONLY if the learner answer clearly satisfies it.
2. "evidence" must be a SHORT VERBATIM quote copied from the learner answer that proves the item is met. If you cannot quote the answer, set met to false and evidence to "".
3. Return one result for every rubric id, using exactly those ids.
4. Give concise, actionable feedback (what was missing, how to improve).

Return JSON exactly in this structure:
{{
  "results": [{{"id": "...", "met": true, "evidence": "..."}}],
  "feedback": "..."
}}
"""

    raw = generate_json(prompt, LLMRubricEvaluation, system=SAFETY_SYSTEM)

    by_id = {r["id"]: r for r in raw["results"]}
    results: List[RubricResult] = []
    met_by_id: Dict[str, bool] = {}
    for item in rubric:
        llm = by_id.get(item.id)
        met = bool(llm and llm["met"])
        evidence = (llm["evidence"] if llm else "") or ""
        # cross-check: cannot be met unless evidence is found in the learner answer
        if met and not evidence_supported(evidence, request.learnerAnswer):
            met = False
        met_by_id[item.id] = met
        results.append(
            RubricResult(
                id=item.id,
                met=met,
                evidence=evidence if met else "",
                description=item.description,
            )
        )

    scores = compute_scores(rubric, met_by_id)
    feedback = (raw.get("feedback") or "").strip()
    if not feedback:
        missing = [r.description for r in results if not r.met]
        feedback = (
            "Good coverage of the rubric." if not missing
            else "Work on: " + "; ".join(missing)
        )

    return AIInterviewEvaluateResponse(**scores, feedback=feedback, rubricResults=results)
