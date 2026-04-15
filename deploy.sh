#!/bin/bash

IP_FILE="ips.txt"
REPO_URL="https://github.com/nmettke/Search-Engines.git"
SSH_USER="ayayang"
LOG_DIR="logs"
SEARCH_PEERS="10.128.0.14:9000,10.128.0.15:9000"

# Check if IP file exists
if [ ! -f "$IP_FILE" ]; then
    echo "Error: $IP_FILE not found!"
    exit 1
fi

echo "Starting deployment to 8 VMs..."
INDEX=0
mkdir -p "$LOG_DIR"

# ==============================================================================
# DEPLOYMENT LOOP
# ==============================================================================
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
        set -e

        # 1. CRITICAL: Set file descriptors for our 25M token flush
        sudo sysctl -w net.ipv4.ip_local_port_range='1024 65535'
        sudo sysctl -w net.ipv4.tcp_tw_reuse=1
        ulimit -n 100000

        # 2. Clone the repository
        if [ -d 'Search-Engines' ]; then
            rm -rf Search-Engines
        fi
        
        git clone $REPO_URL Search-Engines
        cd Search-Engines
        git checkout crawler-refactor

        # 3. Build the project
        chmod +x setup.sh
        ./setup.sh -d

        # 4. Stop any existing crawler so they don't fight for RAM/Ports
        # pkill -9 -f '[s]earch_engine_distributed'

        # 5. Write the background command to run.sh, make it executable, and launch it
        echo \"#!/bin/bash\" > ./run.sh
        echo \"nohup env SEARCH_PEERS=$SEARCH_PEERS ./build/src/search_engine_distributed $INDEX 5120 > crawler.log 2>&1 &\" >> ./run.sh
        chmod +x ./run.sh
        ./run.sh
        
        echo '--- [Machine $INDEX] Crawler Started Successfully ---'
    " > "$LOG_DIR/machine_${INDEX}.log" 2>&1 & # <-- The '&' here is magic. It runs the SSH command in the background!
    INDEX=$((INDEX + 1))
done < "$IP_FILE"

# Wait for all background SSH processes to finish
wait
echo "====================================================="
echo "Deployment Complete! All machines are crawling."
echo "====================================================="
