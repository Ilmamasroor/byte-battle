import requests
import re
import json
import os

# ---------------------------------------------------------
# CONFIG
# ---------------------------------------------------------

GITHUB_API_URL = "https://api.github.com/repos/thanhit95/multi-threading/contents/java/src"
NOTES_RAW_URL = "https://raw.githubusercontent.com/thanhit95/multi-threading/main/notes-demos-exercises.md"
OUTPUT_FILE = "content/parsed/multithreading_debugging_problems.json"

HEADERS = {}
if os.environ.get("GITHUB_TOKEN"):
    HEADERS["Authorization"] = f"token {os.environ['GITHUB_TOKEN']}"

TOPIC = "Multithreading & Concurrency"
ACTIVITY_TYPE = "debugging"

# Only these top-level directories are candidates for debugging content.
# Everything else in this repo is a "here's how X works" demo, not a bug to find.
TARGET_DIRS = {"demo15_deadlock", "demo20_semaphore", "demo12_race_condition"}

# demo20_semaphore has multiple sub-versions (A01/A02/A03/B) but only
# the one whose notes text matches this substring is an actual bug to
# find — the rest (naive version, improved version) are progression,
# not debugging material, and get skipped.
BUG_MARKER_PHRASES = [
    "deadlock",              # catches demo15 A & B, and demo20's A03
]

# Rough, unverified guess — spotting a live concurrency bug is
# generally harder than implementing from a spec, but this isn't
# based on per-exercise analysis. Revisit by hand.
DEFAULT_DIFFICULTY = "HARD"

# ---------------------------------------------------------
# NOTES PARSER (same logic as the coding-problems script)
# ---------------------------------------------------------

HEADER_RE = re.compile(
    r'^#{2,6}\s*(DEMO|EX|VERSION)\s*0*(\d*)([A-Z]?)(?:\s*&\s*0*(\d+))?\s*-?\s*(.*)$',
    re.IGNORECASE
)

def clean_markdown(text):
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return text.strip()

def parse_notes_with_subsections(notes_text):
    """
    Same as before, but ALSO tracks nested '#### Version X' headers
    under a DEMO section, so we can pull e.g. demo15's Version A text
    separately from Version B.
    Returns: { "demo15": {"title":..., "description":..., "versions": {"a": "...", "b": "..."}}, ... }
    """
    sections = {}
    current_key = None
    current_version = None
    buffer = []

    def flush():
        if current_key:
            text = clean_markdown(" ".join(buffer).strip())
            if text:
                entry = sections.setdefault(current_key, {"description": "", "versions": {}})
                if current_version:
                    entry["versions"][current_version] = (
                        entry["versions"].get(current_version, "") + " " + text
                    ).strip()
                else:
                    entry["description"] = (entry["description"] + " " + text).strip()

    for line in notes_text.splitlines():
        stripped = line.strip()
        m = HEADER_RE.match(stripped)
        if m:
            flush()
            kind = m.group(1).upper()
            if kind == "VERSION":
                current_version = m.group(3).lower() or (m.group(2) or "").lower()
                # keep current_key as-is, just switch subsection
            else:
                current_key = f"demo{m.group(2).zfill(2)}" if kind == "DEMO" else f"ex{m.group(2).zfill(2)}"
                current_version = None
            buffer = []
            continue
        if current_key and stripped and not stripped.startswith(("#", "[#", "```")):
            buffer.append(stripped)
    flush()
    return sections

def match_directory_key(directory_name):
    m = re.match(r'^(demo|exer)(\d+)_', directory_name)
    if not m:
        return None
    kind = "demo" if m.group(1) == "demo" else "ex"
    return f"{kind}{m.group(2).zfill(2)}"

# ---------------------------------------------------------
# GITHUB FETCH HELPERS
# ---------------------------------------------------------

def get_json(url):
    r = requests.get(url, headers=HEADERS, timeout=15)
    r.raise_for_status()
    return r.json()

def get_text(url):
    r = requests.get(url, headers=HEADERS, timeout=15)
    r.raise_for_status()
    return r.text

def humanize(slug):
    return slug.replace("-", " ").replace("_", " ").strip().capitalize()

# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():
    print("Downloading notes-demos-exercises.md...")
    notes = parse_notes_with_subsections(get_text(NOTES_RAW_URL))

    print("Fetching repository structure...")
    root_contents = get_json(GITHUB_API_URL)

    all_problems = []
    problem_id = 1

    for item in root_contents:
        if item["type"] != "dir" or item["name"] not in TARGET_DIRS:
            continue

        directory_name = item["name"]
        notes_key = match_directory_key(directory_name)
        entry = notes.get(notes_key)
        print(f"\nInspecting: {directory_name}")

        children = get_json(item["url"])
        java_files_flat = [c for c in children if c["type"] == "file" and c["name"].endswith(".java")]
        subdirs = [c for c in children if c["type"] == "dir"]

        # Case 1: everything is flat .java files directly in this folder,
        # no version subfolders — treat the whole folder as ONE entry.
        if not subdirs and java_files_flat:
            groups = {None: java_files_flat}
        # Case 2: real subfolders exist — one group per subfolder.
        elif subdirs:
            groups = {}
            for sd in subdirs:
                sub_files = [f for f in get_json(sd["url"]) if f["type"] == "file" and f["name"].endswith(".java")]
                if sub_files:
                    groups[sd["name"]] = sub_files
        else:
            print(f"  Skipping {directory_name}: no .java files found at all")
            continue

        for version_key, files in groups.items():
            # Figure out which notes description applies to this group.
            if version_key and entry:
                # try to match subfolder name (e.g. "VersionA", "versiona") to a notes version key
                norm = re.sub(r'[^a-z]', '', version_key.lower())
                desc = None
                for v_key, v_text in entry.get("versions", {}).items():
                    if v_key and v_key in norm:
                        desc = v_text
                        break
                desc = desc or entry.get("description", "")
            elif entry:
                desc = entry.get("description", "")
                # if there are unlabeled versions in the notes but no subfolders here,
                # just concatenate all version texts as fallback context
                if not desc and entry.get("versions"):
                    desc = " ".join(entry["versions"].values())
            else:
                desc = ""

            if not any(phrase in desc.lower() for phrase in BUG_MARKER_PHRASES):
                print(f"  Skipping {directory_name}/{version_key or '(root)'}: notes don't confirm a bug here — "
                      f"'{desc[:80]}...'")
                continue

            label = f"{directory_name}" + (f" — {version_key}" if version_key else "")
            print(f"  Including as debugging problem: {label}")

            code_parts = [get_text(f["download_url"]).strip() for f in files]
            code = "\n\n".join(code_parts)

            problem_text = (
                "The following code contains a real concurrency bug. Read it carefully, "
                "run it if possible, and identify what's wrong before fixing it.\n\n"
                f"Context from the original notes: {desc}"
            )

            all_problems.append({
                "id": problem_id,
                "problem": problem_text,
                "subCategory": humanize(version_key or directory_name.split("_", 1)[-1]),
                "topic": TOPIC,
                "difficulty": DEFAULT_DIFFICULTY,
                "activityType": ACTIVITY_TYPE,
                "code": code,
            })
            problem_id += 1

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_problems, f, indent=2, ensure_ascii=False)

    print(f"\nTotal debugging problems parsed: {len(all_problems)}")
    print(f"Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()