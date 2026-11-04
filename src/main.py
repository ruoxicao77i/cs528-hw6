import argparse
import pandas as pd
from google.cloud import storage

from db import load_ip_country, load_requests
from country_model import model as train_country_model
from income_model import model as train_income_model

def upload_csv(df:pd.DataFrame, bucket_name:str, blob_name:str):
    """Upload a DataFrame to the bucket as a CSV file."""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.upload_from_string(df.to_csv(index=False), content_type="text/csv")

def parse_args():
    parser = argparse.ArgumentParser(description="Train the country and income models and upload test predictions.")
    parser.add_argument("--bucket", required=True, help="Cloud storage bucket for the prediction files")
    parser.add_argument("--seed", required=False, type=int, default=42, help="random seed for train/test split and models (default: 42)")
    return parser.parse_args()

def main():
    args = parse_args()

    # model 1
    ip_df = load_ip_country()
    country_acc, country_results = train_country_model(ip_df, args.seed)
    print(f"Country model test accuracy: {country_acc:.4f}")
    upload_csv(country_results, args.bucket, "hw6/country_predictions.csv")

    req_df = load_requests()
    income_acc, income_results = train_income_model(req_df, args.seed)
    print(f"Income model test accuracy: {income_acc:.4f}")
    upload_csv(income_results, args.bucket, "hw6/income_predictions.csv")

if __name__ == "__main__":
    main()