#!/bin/bash

set -euo pipefail

BUCKET="${1:?Usage: run_on_vm.sh BUCKET_NAME}"

sudo apt-get update -qq
sudo apt-get install -y -qq python3-venv python3-pip

cd "$(dirname "$0")"

python3 -m venv .venv
source .venv/bin/activate
pip install -q -r requirements.txt

python src/main.py --bucket "$BUCKET"