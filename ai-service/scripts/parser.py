import requests
import re
import json
import os

# ---------------------------------------------------------
# CONFIG
# ---------------------------------------------------------

GITHUB_API_URL = "https://api.github.com/repos/thanhit95/multi-threading/contents/java/src"
NOTES_RAW_URL = "https://raw.githubusercontent.com/thanhit95/multi-threading/main/notes-demos-exercises.md"
OUTPUT_FILE = "content/parsed/multithreading_practice_problems.json"

HEADERS = {}
if os.environ.get("GITHUB_TOKEN"):
    HEADERS["Authorization"] = f"token {os.environ['GITHUB_TOKEN']}"

TOPIC = "Multithreading & Concurrency"

# Pure syntax/API demos — nothing to "solve", just how a method works.
# Not useful as coding practice problems.
EXCLUDED_DIRS = {
    "demo00_intro",
    "demo01_hello",
    "demo02_join",
    "demo03_pass_arg",
    "demo04_sleep",
    "demo05_id",
    "demo06_list_threads",
    "demo07_terminate",
    "demo08_return_value",
    "demo09_detach",
    "demo10_yield",
}
# Everything NOT in this set — i.e. demo11 onward (exec_service, race
# conditions, mutex, deadlock, monitors, locks, semaphores, condition
# variables, blocking queue, thread-local, volatile/atomic) plus all
# exer01-08 — is kept, since those describe an actual scenario/problem
# worth implementing or fixing, not just a one-line API call.

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

def get_java_files(directory_url):
    java_files = []
    for item in get_json(directory_url):
        if item["type"] == "file" and item["name"].endswith(".java"):
            java_files.append(item)
        elif item["type"] == "dir":
            java_files.extend(get_java_files(item["url"]))
    return java_files

# ---------------------------------------------------------
# NOTES PARSER
# ---------------------------------------------------------

HEADER_RE = re.compile(
    r'^#{2,4}\s*(DEMO|EX)\s*0*(\d+)[A-Z]?(?:\s*&\s*0*(\d+))?\s*-?\s*(.*)$',
    re.IGNORECASE
)

def clean_markdown(text):
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return text.strip()

def parse_notes(notes_text):
    sections = {}
    current_keys = None
    current_title = None
    buffer = []

    def flush():
        if current_keys:
            text = clean_markdown(" ".join(buffer).strip())
            if text:
                for key in current_keys:
                    entry = sections.setdefault(key, {"title": current_title, "description": ""})
                    entry["description"] = (entry["description"] + " " + text).strip()

    for line in notes_text.splitlines():
        stripped = line.strip()
        m = HEADER_RE.match(stripped)
        if m:
            flush()
            kind = "demo" if m.group(1).lower() == "demo" else "ex"
            nums = [m.group(2)] + ([m.group(3)] if m.group(3) else [])
            current_keys = [f"{kind}{n.zfill(2)}" for n in nums]
            current_title = m.group(4).strip() or None
            buffer = []
            continue
        if current_keys and stripped and not stripped.startswith(("#", "[#", "```")):
            buffer.append(stripped)
    flush()
    return sections

def match_directory(directory_name, notes):
    m = re.match(r'^(demo|exer)(\d+)_', directory_name)
    if not m:
        return None
    kind = "demo" if m.group(1) == "demo" else "ex"
    key = f"{kind}{m.group(2).zfill(2)}"
    return notes.get(key)

# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():
    print("Downloading notes-demos-exercises.md...")
    notes_text = get_text(NOTES_RAW_URL)

    print("Parsing notes...")
    notes = parse_notes(notes_text)
    print(f"  -> {len(notes)} sections parsed")

    print("\nFetching repository structure...")
    root_contents = get_json(GITHUB_API_URL)

    all_problems = []
    problem_id = 1

    for item in root_contents:
        if item["type"] != "dir":
            continue

        directory_name = item["name"]

        if directory_name in EXCLUDED_DIRS:
            print(f"  Skipping {directory_name}: pure syntax demo, not a practice problem")
            continue

        entry = match_directory(directory_name, notes)
        if not entry or not entry["description"]:
            print(f"  Skipping {directory_name}: no matching notes entry")
            continue

        print(f"\nProcessing: {directory_name}  ({entry['title']})")

        java_files = get_java_files(item["url"])
        if not java_files:
            print("  No Java files found.")
            continue

        code_parts = [get_text(f["download_url"]).strip() for f in java_files]

        all_problems.append({
            "id": problem_id,
            "problem": entry["description"],
            "subCategory": entry["title"],
            "topic": TOPIC,
            "difficulty": None,
            "code": "\n\n".join(code_parts),
        })
        problem_id += 1

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_problems, f, indent=2, ensure_ascii=False)

    print(f"\nTotal problems parsed: {len(all_problems)}")
    print(f"Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()