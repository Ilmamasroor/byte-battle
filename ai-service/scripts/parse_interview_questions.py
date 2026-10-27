import requests
import re
import json

BASE_RAW_URL = "https://raw.githubusercontent.com/VanshSharmaSDE/Java-Interview-Questions/main/"

FILE_CONFIGS = [
    {
        "filename": "01_Java_Basics_Part1.md",
        "topic_resolver": lambda subcat: "core_java"
    },
    {
        "filename": "02_Java_Basics_Part2.md",
        "topic_resolver": lambda subcat: "oop"
    },
    {
        "filename": "03_Collections_Framework.md",
        "topic_resolver": lambda subcat: "collections"
    },
    {
        "filename": "04_Exception_Handling_Multithreading.md",
        "topic_resolver": lambda subcat: "exception_handling" if subcat and "exception" in subcat.lower() else "multithreading"
    },
    {
        "filename": "05_DS_Arrays_Strings.md",
        "topic_resolver": lambda subcat: "arrays"
    },
    {
        "filename": "06_DS_LinkedList_Stacks_Queues.md",
        "topic_resolver": lambda subcat: "linked_lists"
    },
    {
        "filename": "07_DS_Trees_BST.md",
        "topic_resolver": lambda subcat: "trees"
    },
    {
        "filename": "09_Algorithms_Sorting_Searching.md",
        "topic_resolver": lambda subcat: "searching" if subcat and "search" in subcat.lower() else "sorting"
    },
]

DIFFICULTY_MAP = {
    "🟢 Beginner": "EASY",
    "🟡 Medium": "MEDIUM",
    "🔴 Advanced": "HARD",
}

def download_file(filename):
    response = requests.get(BASE_RAW_URL + filename)
    response.raise_for_status()
    return response.text

def parse_questions(markdown_text, topic_resolver):
    lines = markdown_text.split("\n")

    current_difficulty = None
    current_subcategory = None
    questions = []

    for line in lines:
        line = line.strip()

        for emoji_label, level in DIFFICULTY_MAP.items():
            if line.startswith("##") and emoji_label in line:
                current_difficulty = level

        if line.startswith("###"):
            current_subcategory = re.sub(r"^#+\s*", "", line)
            current_subcategory = re.sub(r"\s*\(Questions.*\)", "", current_subcategory)

        match = re.match(r"^(\d+)\.\s+(.+)$", line)
        if match and current_difficulty:
            question_id = match.group(1)
            question_text = match.group(2)
            questions.append({
                "id": question_id,
                "question": question_text,
                "difficulty": current_difficulty,
                "subCategory": current_subcategory,
                "topic": topic_resolver(current_subcategory)
            })

    return questions


def main():
    all_questions = []

    for config in FILE_CONFIGS:
        filename = config["filename"]
        print(f"Downloading {filename}...")
        markdown_text = download_file(filename)

        print(f"Parsing {filename}...")
        questions = parse_questions(markdown_text, config["topic_resolver"])
        print(f"  -> {len(questions)} questions parsed")

        all_questions.extend(questions)

    print(f"\nTotal questions parsed: {len(all_questions)}")

    with open("content/parsed/interview_questions.json", "w") as f:
        json.dump(all_questions, f, indent=2)

    print("Saved to content/parsed/interview_questions.json")

if __name__ == "__main__":
    main()