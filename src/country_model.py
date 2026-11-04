import ipaddress
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score

def model(df:pd.DataFrame, seed=42):
    # IP -> int
    data = df[["client_ip", "country"]].copy()
    data["ip_int"] = data["client_ip"].apply(lambda s: int(ipaddress.ip_address(s)))

    # train test split
    train, test = train_test_split(data, test_size=0.2, random_state=seed)

    # train
    model = DecisionTreeClassifier(random_state=seed)
    model.fit(train[["ip_int"]], train["country"])

    # validation
    test = test.copy()
    test["predicted_country"] = model.predict(test[["ip_int"]])
    acc = accuracy_score(test["country"], test["predicted_country"])

    return acc, test[["client_ip", "country", "predicted_country"]]

if __name__ == "__main__":
    from src.db import load_ip_country
    acc, results = model(load_ip_country())
    print(f"Country model accuracy: {acc:.4f}")
    print(results.head())