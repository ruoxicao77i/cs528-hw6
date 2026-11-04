#!/bin/bash
# HW6 cleanup: deletes the VM, stops the database and resumes the
# hourly auto-stop job. Every step runs even if an earlier one fails.

set -uo pipefail        # no -e: try every cleanup step

PROJECT_ID="tonal-plateau-508118-g0"
REGION="us-central1"
ZONE="us-central1-a"

DB_INSTANCE="hw5-db"
VM_NAME="hw6-vm"
SCHEDULER_JOB="stop-db-hourly"

export CLOUDSDK_CORE_PROJECT="$PROJECT_ID"

log() { echo; echo "===== $* ====="; }

log "Deleting VM"
if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" >/dev/null 2>&1; then
    gcloud compute instances delete "$VM_NAME" --zone="$ZONE" --quiet
else
    echo "VM $VM_NAME not found, skipping."
fi

log "Stopping database"
gcloud sql instances patch "$DB_INSTANCE" --activation-policy=NEVER --async --quiet

log "Resuming the hourly auto-stop job"
gcloud scheduler jobs resume "$SCHEDULER_JOB" --location="$REGION"

log "Cleanup done."