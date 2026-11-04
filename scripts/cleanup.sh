#!/bin/bash

set -euo pipefail

PROJECT_ID="tonal-plateau-508118-g0"
REGION="us-central1"
ZONE="us-central1-a"
VM_NAME="hw6-vm"

gcloud config set project "$PROJECT_ID"

log() {
    echo " ====== $* ======= ";
}

# stop the VM
if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" >/dev/null 2>&1; then
    gcloud compute instances delete "$VM_NAME" --zone="$ZONE"
else
    echo "VM $VM_NAME not found, skipping."
fi

gcloud scheduler jobs resume stop-db-hourly --location=us-central1

log "Done."