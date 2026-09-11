import requests
import json
import os

# ---------------------------------------------------------
# CONFIG
# ---------------------------------------------------------

REPO_RAW = "https://raw.githubusercontent.com/exercism/java/main"
REPO_API = "https://api.github.com/repos/exercism/java/contents"
OUTPUT_FILE = "content/parsed/exercism_java_concepts.json"

HEADERS = {}
if os.environ.get("GITHUB_TOKEN"):
    HEADERS["Authorization"] = f"token {os.environ['GITHUB_TOKEN']}"

# Map Exercism "concepts" tags -> your topic categories.
# NOT exhaustive — only covers concepts confirmed to exist in this track.
# Anything not listed here causes the exercise to be skipped (and printed),
# so extend this as you see more tags show up in the run.
CONCEPT_TOPIC_MAP = {
    # Core Java
    "basics": "core_java",
    "if-statements": "core_java",
    "numbers": "core_java",
    "chars": "core_java",
    "strings": "core_java",
    "booleans": "core_java",
    "for-loops": "core_java",
    "foreach-loops": "core_java",
    "while-loops": "core_java",
    "do-while-loops": "core_java",
    "arrays": "core_java",
    "increment-decrement": "core_java",
    "integral-numbers": "core_java",
    "floating-point-numbers": "core_java",
    "arithmetic-operators": "core_java",
    "conditionals": "core_java",
    "if-then-else-expressions": "core_java",

    # OOP
    "classes": "oop",
    "constructors": "oop",
    "interfaces": "oop",
    "inheritance": "oop",
    "method-overloading": "oop",
    "named-arguments": "oop",
    "optional-parameters": "oop",
    "object-initializers": "oop",
    "operator-overloading": "oop",
    "attributes": "oop",
    "flag-enums": "oop",

    # Collections
    "lists": "collections",
    "generics": "collections",
    "generic-types": "collections",
    "vectors": "collections",
    "sets": "collections",
    "maps": "collections",

    # Exception Handling
    "exceptions": "exception_handling",
}

DIFFICULTY_BY_PREREQ_COUNT = lambda n: "EASY" if n == 0 else ("MEDIUM" if n <= 2 else "HARD")

# ---------------------------------------------------------
# FETCH HELPERS
# ---------------------------------------------------------

def get_json(url):
    r = requests.get(url, headers=HEADERS, timeout=15)
    r.raise_for_status()
    return r.json()

def get_text(url):
    r = requests.get(url, headers=HEADERS, timeout=15)
    r.raise_for_status()
    return r.text

def try_get_text(url):
    """Returns None instead of raising, for optional files."""
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        if r.status_code == 404:
            return None
        r.raise_for_status()
        return r.text
    except requests.RequestException:
        return None

# ---------------------------------------------------------
# TOPIC RESOLUTION
# ---------------------------------------------------------

def resolve_topic(concepts):
    """
    Returns the first matching topic among this exercise's concepts,
    or None if nothing maps (exercise gets skipped).
    """
    for c in concepts:
        if c in CONCEPT_TOPIC_MAP:
            return CONCEPT_TOPIC_MAP[c]
    return None

# ---------------------------------------------------------
# PER-EXERCISE FETCH
# ---------------------------------------------------------

def fetch_exercise_meta(slug):
    """.meta/config.json — has exact solution/test/exemplar file paths."""
    url = f"{REPO_RAW}/exercises/concept/{slug}/.meta/config.json"
    text = try_get_text(url)
    if text is None:
        return None
    return json.loads(text)

def fetch_instructions(slug):
    """The actual problem statement for the exercise."""
    url = f"{REPO_RAW}/exercises/concept/{slug}/.docs/instructions.md"
    return try_get_text(url)

def fetch_reference_code(slug, meta):
    """
    Reference solution. Different tracks/exercises use 'exemplar' or
    'example' as the key — try both. Falls back to the stub 'solution'
    file (with a flag) if neither exists, so nothing silently vanishes.
    """
    files = meta.get("files", {})
    for key in ("exemplar", "example"):
        paths = files.get(key)
        if paths:
            parts = []
            for p in paths:
                text = try_get_text(f"{REPO_RAW}/exercises/concept/{slug}/{p}")
                if text:
                    parts.append(text.strip())
            if parts:
                return "\n\n".join(parts), False  # False = not a stub

    # Fall back to the stub file the student edits (marked as such)
    paths = files.get("solution", [])
    parts = []
    for p in paths:
        text = try_get_text(f"{REPO_RAW}/exercises/concept/{slug}/{p}")
        if text:
            parts.append(text.strip())
    if parts:
        return "\n\n".join(parts), True  # True = this is only the stub, not a real solution

    return None, True

# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():
    print("Fetching track config.json...")
    config = get_json(f"{REPO_API}/config.json")
    # config.json is small enough to fetch via raw instead of the API blob format:
    config_text = get_text(f"{REPO_RAW}/config.json")
    config = json.loads(config_text)

    concept_exercises = config.get("exercises", {}).get("concept", [])
    print(f"Found {len(concept_exercises)} concept exercises in track config.\n")

    all_problems = []
    problem_id = 1

    for ex in concept_exercises:
        slug = ex["slug"]
        name = ex.get("name", slug)
        concepts = ex.get("concepts", [])
        prerequisites = ex.get("prerequisites", [])

        topic = resolve_topic(concepts)
        if topic is None:
            print(f"Skipping {slug}: concepts {concepts} don't map to a tracked topic")
            continue

        print(f"Processing: {slug}  ({name})  concepts={concepts}")

        instructions = fetch_instructions(slug)
        if not instructions:
            print(f"  Skipping {slug}: no instructions.md found")
            continue

        meta = fetch_exercise_meta(slug)
        if not meta:
            print(f"  Skipping {slug}: no .meta/config.json found")
            continue

        code, is_stub_only = fetch_reference_code(slug, meta)
        if not code:
            print(f"  Skipping {slug}: no solution/exemplar code found")
            continue

        if is_stub_only:
            print(f"  NOTE: {slug} — only found the student stub, not a reference solution")

        all_problems.append({
            "id": problem_id,
            "problem": instructions.strip(),
            "subCategory": name,
            "topic": topic,
            "difficulty": DIFFICULTY_BY_PREREQ_COUNT(len(prerequisites)),
            "code": code,
            "isStubOnly": is_stub_only,  # so you can filter/flag these downstream
        })
        problem_id += 1

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_problems, f, indent=2, ensure_ascii=False)

    print(f"\nTotal problems parsed: {len(all_problems)}")
    print(f"Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()