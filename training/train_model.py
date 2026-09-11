import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.metrics import mean_absolute_error, r2_score, mean_squared_error
import joblib

df = pd.read_csv("training/data/synthetic_performance_data.csv")

TOLERANCE = 10

param_grid = {
    "estimator__n_estimators": [50, 100, 200],
    "estimator__max_depth": [3, 5, 10],
    "estimator__learning_rate": [0.01, 0.1, 0.2],
}

def train_and_evaluate(name, sub_df, feature_cols, target_cols, bool_cols, save_path):
    sub_df = sub_df.copy()
    for col in bool_cols:
        sub_df[col] = sub_df[col].astype(int)

    X = sub_df[feature_cols]
    y = sub_df[target_cols]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    base_model = MultiOutputRegressor(GradientBoostingRegressor(random_state=42))
    grid_search = GridSearchCV(base_model, param_grid, cv=3, scoring="r2", n_jobs=-1)
    grid_search.fit(X_train, y_train)

    model = grid_search.best_estimator_
    y_pred = model.predict(X_test)
    y_pred_df = pd.DataFrame(y_pred, columns=target_cols, index=y_test.index)

    print(f"\n{name.upper()} MODEL")
    print(f"Best parameters: {grid_search.best_params_}")
    print(f"Overall MAE: {mean_absolute_error(y_test, y_pred):.2f}")
    print(f"Overall RMSE: {np.sqrt(mean_squared_error(y_test, y_pred)):.2f}")
    print(f"Overall R^2: {r2_score(y_test, y_pred):.3f}")
    print(f"Overall Accuracy (within ±{TOLERANCE} pts): "
          f"{(np.abs(y_test.values - y_pred) <= TOLERANCE).mean() * 100:.1f}%")

    print("Per-target breakdown:")
    for col in target_cols:
        mae = mean_absolute_error(y_test[col], y_pred_df[col])
        rmse = np.sqrt(mean_squared_error(y_test[col], y_pred_df[col]))
        r2 = r2_score(y_test[col], y_pred_df[col])
        acc = (np.abs(y_test[col] - y_pred_df[col]) <= TOLERANCE).mean() * 100
        print(f"  {col}: MAE={mae:.2f}, RMSE={rmse:.2f}, R^2={r2:.3f}, Accuracy(±{TOLERANCE})={acc:.1f}%")

    joblib.dump(model, save_path)
    print(f"Saved to {save_path}")

# --- BATTLE MODEL ---
train_and_evaluate(
    "battle",
    df[df["activityType"] == "battle"],
    feature_cols=["accuracy", "score", "attemptCount", "timeSpentSeconds", "hintsUsed"],
    target_cols=["conceptUnderstanding", "decisionMaking", "hintDependency"],
    bool_cols=[],
    save_path="models_store/battle_model.pkl"
)

# --- INTERVIEW MODEL ---
train_and_evaluate(
    "interview",
    df[df["activityType"] == "interview"],
    feature_cols=["accuracy", "score", "hintsUsed"],
    target_cols=["conceptUnderstanding", "hintDependency"],
    bool_cols=[],
    save_path="models_store/interview_model.pkl"
)

# --- CODING MODEL ---
train_and_evaluate(
    "coding",
    df[df["activityType"] == "coding"],
    feature_cols=["testCasesPassed", "testCasesTotal", "success", "hintsUsed"],
    target_cols=["codingImplementation", "boundaryConditions", "hintDependency"],
    bool_cols=["success"],
    save_path="models_store/coding_model.pkl"
)

# --- DEBUGGING MODEL ---
train_and_evaluate(
    "debugging",
    df[df["activityType"] == "debugging"],
    feature_cols=["testCasesPassed", "testCasesTotal", "success", "hintsUsed"],
    target_cols=["codingImplementation", "boundaryConditions", "hintDependency"],
    bool_cols=["success"],
    save_path="models_store/debugging_model.pkl"
)