import pandas as pd
import numpy as np

np.random.seed(42)

N_SAMPLES = 2000
ACTIVITY_TYPES = ["battle", "coding", "debugging", "interview"]

def noisy(value, spread=7):
    return round(np.clip(value + np.random.normal(0, spread), 0, 100), 2)

def generate_row():
    activity_type = np.random.choice(ACTIVITY_TYPES)

    hints_used = np.random.randint(0, 6)
    attempt_count = np.random.randint(1, 7)
    time_spent = np.random.randint(30, 300)

    row = {
        "activityType": activity_type,
        "hintsUsed": hints_used,
        "attemptCount": attempt_count,
        "timeSpentSeconds": time_spent,
        # all 5 output columns start as missing; only relevant ones get filled below
        "conceptUnderstanding": np.nan,
        "decisionMaking": np.nan,
        "boundaryConditions": np.nan,
        "codingImplementation": np.nan,
        "hintDependency": np.nan,
    }

    # hintDependency applies to every activity type
    row["hintDependency"] = noisy(hints_used * 15)

    if activity_type == "battle":
        accuracy = np.random.uniform(0.2, 1.0)
        score = np.clip(accuracy * 100 * np.random.uniform(0.85, 1.05), 0, 100)
        row["score"] = round(score, 2)
        row["accuracy"] = round(accuracy, 2)

        row["conceptUnderstanding"] = noisy(score * 0.5 + accuracy * 100 * 0.5)
        row["decisionMaking"] = noisy(
            accuracy * 100 * 0.5
            + max(0, 100 - attempt_count * 12) * 0.3
            + max(0, 100 - time_spent / 3) * 0.2
        )

    elif activity_type == "interview":
        accuracy = np.random.uniform(0.2, 1.0)
        score = np.clip(accuracy * 100 * np.random.uniform(0.85, 1.05), 0, 100)
        row["score"] = round(score, 2)
        row["accuracy"] = round(accuracy, 2)

        row["conceptUnderstanding"] = noisy(score * 0.6 + accuracy * 100 * 0.4)

    elif activity_type in ("coding", "debugging"):
        test_cases_total = np.random.randint(5, 15)
        base_pass_ratio = np.random.uniform(0.2, 1.0)
        test_cases_passed = int(base_pass_ratio * test_cases_total)
        pass_ratio = test_cases_passed / test_cases_total
        success = pass_ratio > 0.7
        execution_status = "pass" if pass_ratio > 0.7 else ("fail" if pass_ratio > 0.3 else "error")

        row["testCasesTotal"] = test_cases_total
        row["testCasesPassed"] = test_cases_passed
        row["executionStatus"] = execution_status
        row["success"] = success

        row["boundaryConditions"] = noisy(pass_ratio * 100 * 0.9)
        row["codingImplementation"] = noisy(pass_ratio * 100 * 0.7 + (30 if success else 0))

    return row

rows = [generate_row() for _ in range(N_SAMPLES)]
df = pd.DataFrame(rows)

df.to_csv("training/data/synthetic_performance_data.csv", index=False)
print(f"Generated {len(df)} rows and saved to training/data/synthetic_performance_data.csv")
print(df["activityType"].value_counts())
print(df.head(10))