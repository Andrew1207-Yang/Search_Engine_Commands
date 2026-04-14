#!/bin/bash

IP_FILE="ips.txt"
REPO_URL="https://github.com/nmettke/Search-Engines.git"
SSH_USER="ayayang" # TODO: Change to the default GCP user (e.g., ubuntu, or your username)
LOG_DIR="logs"

# Check if IP file exists
if [ ! -f "$IP_FILE" ]; then
    echo "Error: $IP_FILE not found!"
    exit 1
fi

echo "Starting deployment to 44 VMs..."
INDEX=0
mkdir -p "$LOG_DIR"

# ==============================================================================
# DEPLOYMENT LOOP
# ==============================================================================
while IFS= read -r IP; do
    # Skip empty lines
    [ -z "$IP" ] && continue

    echo "Deploying to Machine $INDEX ($IP)..."

    # The '-o StrictHostKeyChecking=no' prevents the script from hanging when 
    # connecting to a new IP for the first time.
    ssh -i ~/.ssh/gcp_key -o StrictHostKeyChecking=no "$SSH_USER@$IP" "
        echo '--- [Machine $INDEX] Connected ---'

        pkill -9 -f '[s]earch_engine_distributed'
        
        echo '--- [Machine $INDEX] Killed Successfully ---'
    "  & # <-- The '&' here is magic. It runs the SSH command in the background!
    INDEX=$((INDEX + 1))
done < "$IP_FILE"

# Wait for all background SSH processes to finish
wait
echo "====================================================="
echo "All machines killed."
echo "====================================================="
