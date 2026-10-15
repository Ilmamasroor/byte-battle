import requests
import json
import os

# ---------------------------------------------------------
# CONFIG
# ---------------------------------------------------------

GITHUB_API_URL = "https://api.github.com/repos/leticiamazzoportela/concurrent-programming/contents"
OUTPUT_FILE = "content/parsed/concurrent_programming_letícia.json"

HEADERS = {}
if os.environ.get("GITHUB_TOKEN"):
    HEADERS["Authorization"] = f"token {os.environ['GITHUB_TOKEN']}"

TOPIC = "Multithreading & Concurrency"

# Folders to skip entirely (matches your earlier "skip pure syntax" rule)
EXCLUDED_TOP_LEVEL_DIRS = {"basic-thead-operations"}

# Rough difficulty by category — a subjective estimate, not sourced from
# anything in the repo. Adjust freely.
CATEGORY_DIFFICULTY = {
    "atomic-variables": "MEDIUM",
    "classic-concurrent-programming-problems": "HARD",
    "locks": "MEDIUM",
    "monitors": "MEDIUM",
    "semaphores": "MEDIUM",
    "sharing-and-syncing": "EASY",
    "thread-group": "MEDIUM",
}

# Folders where each .java file is its OWN problem (independent variants),
# rather than being merged into a single entry. Key = "category/folder".
SPLIT_BY_FILE = {
    "classic-concurrent-programming-problems/readers-writers",
}

# problem text, written by hand since the repo has no descriptions at all.
# Keyed by "category/folder" for merged entries, or "category/folder/File.java"
# for split entries. NOT verified against the actual code — review before use.
PROBLEM_DESCRIPTIONS = {
    "atomic-variables/queue-atomic-reference":
        "Implement a thread-safe queue using AtomicReference (lock-free, "
        "compare-and-swap based) instead of synchronized blocks or explicit locks.",
    "atomic-variables/sequential-numbers-generator":
        "Implement a generator that hands out sequential numbers to multiple "
        "concurrent threads with no duplicates or gaps, using an atomic "
        "variable instead of a lock.",
    "atomic-variables/stack-atomic-reference":
        "Implement a thread-safe stack using AtomicReference (lock-free, "
        "compare-and-swap based).",

    "classic-concurrent-programming-problems/dining-philosophers":
        "Implement a solution to the Dining Philosophers problem: N "
        "philosophers share N chopsticks and each needs both neighboring "
        "chopsticks to eat, without deadlock or starvation, and without two "
        "neighbors eating at the same time.",
    "classic-concurrent-programming-problems/readers-writers/ReadersWritersPriority.java":
        "Implement the Readers-Writers problem with reader priority: any "
        "number of readers may read concurrently, but a writer requires "
        "exclusive access once it's ready to write.",
    "classic-concurrent-programming-problems/readers-writers/ReadersWritersStarvationFree.java":
        "Implement a starvation-free variant of the Readers-Writers problem, "
        "ensuring neither readers nor writers can be blocked indefinitely by "
        "the other group.",

    "locks/arraylist-thread-safe":
        "Implement a thread-safe wrapper around ArrayList using explicit "
        "Lock objects (java.util.concurrent.locks) instead of the "
        "synchronized keyword.",
    "locks/lock-counter":
        "Implement a shared counter protected by an explicit Lock, safe for "
        "concurrent increments from multiple threads.",
    "locks/shared-fifo-queue":
        "Implement a thread-safe FIFO queue shared between producer and "
        "consumer threads using explicit locks.",

    "monitors/monitor-bounded-counter":
        "Implement a bounded counter (with min/max limits) as a monitor, "
        "blocking any thread whose operation would push the count out of "
        "bounds until it becomes safe to proceed.",
    "monitors/monitor-counter":
        "Implement a simple thread-safe counter using the monitor pattern "
        "(synchronized methods).",

    "semaphores/barrier":
        "Implement a reusable barrier using semaphores, so a group of "
        "threads all wait until every thread has reached the barrier before "
        "any of them is allowed to proceed.",
    "semaphores/multiplex":
        "Implement a multiplex (counting semaphore) that allows up to N "
        "threads into a critical section concurrently, blocking further "
        "threads until a slot frees up.",
    "semaphores/mutex":
        "Implement mutual exclusion for a critical section using a binary "
        "semaphore.",
    "semaphores/rendezvous":
        "Implement a rendezvous point where two threads must each wait for "
        "the other to arrive before either is allowed to continue.",
    "semaphores/signaling-semaphore":
        "Use a semaphore purely for signaling between two threads (not "
        "mutual exclusion): one thread signals an event that another thread "
        "is waiting on.",

    "sharing-and-syncing/search-value":
        "Search for a value across shared data using multiple threads, "
        "coordinating safe concurrent access to that shared state.",
    "sharing-and-syncing/states-manager":
        "Manage a shared state object safely across multiple threads, "
        "ensuring consistent reads and writes without race conditions.",
    "sharing-and-syncing/thread-internal-counter":
        "Compare a counter kept local to each thread against one that's "
        "shared across threads, and apply the synchronization the shared "
        "version needs.",

    "thread-group/parallel-search":
        "Implement a parallel search across a data set, dividing the work "
        "among worker threads organized in a ThreadGroup.",
    "thread-group/prime-numbers":
        "Use multiple threads within a ThreadGroup to find and report prime "
        "numbers concurrently.",
    "thread-group/status-threads":
        "Query and report the status of the threads within a ThreadGroup.",
    "thread-group/thread-group-operations":
        "Demonstrate common ThreadGroup operations (e.g. listing, "
        "interrupting, or otherwise managing its member threads as a group).",
}

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
    print("Fetching repository structure...")
    root_contents = get_json(GITHUB_API_URL)

    all_problems = []
    problem_id = 1

    for top_item in root_contents:
        if top_item["type"] != "dir":
            continue

        category = top_item["name"]
        if category in EXCLUDED_TOP_LEVEL_DIRS:
            print(f"Skipping category '{category}': excluded")
            continue

        difficulty = CATEGORY_DIFFICULTY.get(category)
        subfolders = get_json(top_item["url"])

        for sub_item in subfolders:
            if sub_item["type"] != "dir":
                continue  # skip stray files directly under a category

            folder_slug = sub_item["name"]
            key = f"{category}/{folder_slug}"

            files = get_json(sub_item["url"])
            java_files = [f for f in files if f["type"] == "file" and f["name"].endswith(".java")]
            if not java_files:
                print(f"  Skipping {key}: no .java files found")
                continue

            print(f"\nProcessing: {key}")

            if key in SPLIT_BY_FILE:
                # Each .java file becomes its own problem entry
                for jf in java_files:
                    file_key = f"{key}/{jf['name']}"
                    problem_text = PROBLEM_DESCRIPTIONS.get(file_key)
                    if not problem_text:
                        problem_text = f"Implement: {humanize(jf['name'].replace('.java', ''))}"
                        print(f"  WARNING: no hand-written description for {file_key}, using a generic placeholder")

                    code = get_text(jf["download_url"]).strip()
                    all_problems.append({
                        "id": problem_id,
                        "problem": problem_text,
                        "subCategory": humanize(folder_slug),
                        "topic": TOPIC,
                        "difficulty": difficulty,
                        "code": code,
                    })
                    problem_id += 1
            else:
                # All .java files in the folder are one combined problem
                problem_text = PROBLEM_DESCRIPTIONS.get(key)
                if not problem_text:
                    problem_text = f"Implement: {humanize(folder_slug)}"
                    print(f"  WARNING: no hand-written description for {key}, using a generic placeholder")

                code_parts = [get_text(f["download_url"]).strip() for f in java_files]
                all_problems.append({
                    "id": problem_id,
                    "problem": problem_text,
                    "subCategory": humanize(folder_slug),
                    "topic": TOPIC,
                    "difficulty": difficulty,
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