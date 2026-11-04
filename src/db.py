import os
import sys
import pymysql
import pandas as pd
from google.cloud.sql.connector import Connector

# =========== Configuration ===========
INSTANCE_CONNECTION_NAME = os.environ.get(
    "INSTANCE_CONNECTION_NAME", "tonal-plateau-508118-g0:us-central1:hw5-db")
DB_USER = os.environ.get("DB_USER", "root")
DB_NAME = os.environ.get("DB_NAME", "hw5")
DB_PASSWORD = os.environ.get("DB_PASSWORD")


def get_connection(connector:pymysql.connections.Connection):
    """Open a pymysql connection to Cloud SQL through the Python Connector."""
    return connector.connect(
        INSTANCE_CONNECTION_NAME,
        "pymysql",
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
    )

def fetch_requests(conn:Connector, sql:str):
    """Return all requests."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(sql)
        return cur.fetchall()
    
def query_df(sql, params=None):
    """Run any SELECT and return the result as a DataFrame."""
    if not DB_PASSWORD:
        sys.exit("Please set DB_PASSWORD first, e.g. export DB_PASSWORD='...'")

    with Connector() as connector:
        conn = get_connection(connector)
        try:
            with conn.cursor(pymysql.cursors.DictCursor) as cur:
                cur.execute(sql, params)
                rows = cur.fetchall()
        finally:
            conn.close()

    return pd.DataFrame(rows)

REQUESTS_QUERY = """
    SELECT
        r.id,
        r.client_ip,
        c.country_name AS country,
        c.is_banned,
        r.gender,
        r.age,
        r.income,
        r.time_of_day,
        r.requested_file
    FROM requests_3nf AS r
    JOIN ip_addresses   AS i ON r.client_ip  = i.client_ip
    JOIN countries AS c ON i.country_id = c.country_id
    ORDER BY r.id
"""

def load_requests():
    return query_df(REQUESTS_QUERY)


IP_COUNTRY_QUERY = """
SELECT i.client_ip, c.country_name AS country
FROM ip_addresses AS i
JOIN countries    AS c ON i.country_id = c.country_id;
"""

def load_ip_country():
    """Return a DataFrame with columns: client_ip, country (one row per IP)."""
    return query_df(IP_COUNTRY_QUERY)

if __name__ == "__main__":
    """For test."""
    df = load_requests()
    print(f"Retrieved {len(df)} rows\n")
    print(df.head(10).to_string(index=False))