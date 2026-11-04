import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

FEATURES = ["gender", "age", "country", "is_banned", "hour"]
CATEGORICAL = ["gender", "age", "country"]

def model(df:pd.DataFrame, seed=42):
    data = df[["gender", "age", "country", "is_banned", "time_of_day", "income"]].dropna().copy()
    data["hour"] = pd.to_datetime(data["time_of_day"]).dt.hour

    # one-hot code
    X = pd.get_dummies(data[FEATURES], columns=CATEGORICAL)
    y = data["income"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=seed, stratify=y
    )

    model = RandomForestClassifier(n_estimators=200, random_state=seed)
    model.fit(X_train, y_train)
    pred = model.predict(X_test)
    acc = accuracy_score(y_test, pred)

    results = data.loc[X_test.index, FEATURES].copy()
    results["income"] = y_test
    results["predicted_income"] = pred
    return acc, results


if __name__ == "__main__":
    from src.db import load_requests
    df = load_requests()

    baseline = df["income"].value_counts(normalize=True).max()
    print(f"Baseline (always guess the most common class): {baseline:.4f}")

    for seed in [0, 1, 42, 123, 2026]:
        acc, _ = model(df, seed=seed)
        print(f"seed={seed:5d}  accuracy={acc:.4f}")