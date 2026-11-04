#!/bin/bash
# HW6 setup: runs the whole pipeline with one command.
#   - starts the Cloud SQL database (and pauses the hourly auto-stop job)
#   - creates a VM and runs src/main.py on it to train both models
#   - prints the model outputs stored in the bucket
#   - cleans up on exit (scripts/cleanup.sh), even if a step fails

set -euo pipefail
# relative to the root dir of the project
cd "$(dirname "$0")/.."

# ===== settings =====
PROJECT_ID="tonal-plateau-508118-g0"
REGION="us-central1"
ZONE="us-central1-a"

DB_INSTANCE="hw5-db"

VM_NAME="hw6-vm"
VM_TYPE="e2-medium"

BUCKET="cs528-ruoxi-pagerank"
DB_SECRET="hw6-db-password"    


export CLOUDSDK_CORE_PROJECT="$PROJECT_ID"

log() { echo; echo "===== $* ====="; }

# ===== Enable APIs =====
log "Enabling APIs"
gcloud services enable \
    compute.googleapis.com sqladmin.googleapis.com storage.googleapis.com \
    secretmanager.googleapis.com

if [ -z "${DB_PASSWORD:-}" ]; then
    DB_PASSWORD=$(gcloud secrets versions access latest --secret="$DB_SECRET")
fi

gcloud scheduler jobs pause stop-db-hourly --location="$REGION"
trap 'bash scripts/cleanup.sh' EXIT



#  ===== activate database =====
log "Starting database"
POLICY=$(gcloud sql instances describe "$DB_INSTANCE" --format="value(settings.activationPolicy)")
if [ "$POLICY" != "ALWAYS" ]; then
    gcloud sql instances patch "$DB_INSTANCE" --activation-policy=ALWAYS --async --quiet
fi

until [ "$(gcloud sql instances describe "$DB_INSTANCE" --format="value(state)")" = "RUNNABLE" ]; do
    echo "Waiting for database to start..."
    sleep 10
done

# ===== create VM =====
if ! gcloud compute instances describe "$VM_NAME" --zone="$ZONE" >/dev/null 2>&1; then
    gcloud compute instances create "$VM_NAME" \
        --zone="$ZONE" \
        --machine-type="$VM_TYPE" \
        --image-family=debian-12 --image-project=debian-cloud \
        --scopes=cloud-platform
fi

gcloud compute instances start "$VM_NAME" --zone="$ZONE"

# ===== authorize the VM =====
SA=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format="value(serviceAccounts[0].email)")

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA" --role="roles/cloudsql.client" --condition=None --format=none

gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" \
    --member="serviceAccount:$SA" --role="roles/storage.objectUser" --format=none

# ===== wait for the VM =====
until gcloud compute ssh "$VM_NAME" --zone="$ZONE" --quiet --command="true" >/dev/null 2>&1; do
    echo "Waiting for VM to accept SSH..."
    sleep 5
done

gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="mkdir -p ~/hw6"
gcloud compute scp --recurse --zone="$ZONE" \
    src requirements.txt scripts/run_on_vm.sh \
    "$VM_NAME":~/hw6/

gcloud compute ssh "$VM_NAME" --zone="$ZONE" \
    --command="cd ~/hw6 && DB_PASSWORD=$(printf %q "$DB_PASSWORD") bash run_on_vm.sh $(printf %q "$BUCKET")"



log "Model outputs in the bucket"
TMP_DIR=$(mktemp -d)
for f in country_predictions.csv income_predictions.csv; do
    gcloud storage cp "gs://$BUCKET/hw6/$f" "$TMP_DIR/$f" --quiet
    echo
    echo "--- gs://$BUCKET/hw6/$f ($(($(wc -l < "$TMP_DIR/$f") - 1)) rows) ---"
    head -20 "$TMP_DIR/$f"
done
rm -rf "$TMP_DIR"

log "Done."

