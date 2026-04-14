#!/bin/bash

IP_FILE="ips.txt"
SSH_USER="ayayang" # Change if your GCP user is different
POLL_INTERVAL_SECONDS=5
INDEX=0

if [ ! -f "$IP_FILE" ]; then
    echo "Error: $IP_FILE not found!"
    exit 1
fi

echo "====================================================="
echo "   Stopping search_engine processes with SIGINT..."
echo "====================================================="

while IFS= read -r IP; do
    [ -z "$IP" ] && continue

    echo "[Machine $INDEX - $IP] Checking for running search_engine processes..."

    ssh -n -i ~/.ssh/gcp_key -o StrictHostKeyChecking=no "$SSH_USER@$IP" "
        PIDS=\$(ps -eo pid=,comm= | awk '\$2 == \"search_engine\" || \$2 == \"search_engine_distributed\" { print \$1 }')

        if [ -z \"\$PIDS\" ]; then
            echo \"❌ [Machine $INDEX - $IP] No search_engine processes found.\"
            exit 0
        fi

        PID_LIST=\$(echo \"\$PIDS\" | xargs)

        echo \"✅ [Machine $INDEX - $IP] Sending SIGINT to PID(s): \$PID_LIST\"
        echo \"\$PIDS\" | xargs kill -INT

        while true; do
            sleep $POLL_INTERVAL_SECONDS

            REMAINING=''
            for PID in \$PID_LIST; do
                if kill -0 \"\$PID\" 2>/dev/null; then
                    REMAINING=\"\$REMAINING \$PID\"
                fi
            done

            REMAINING=\$(echo \"\$REMAINING\" | xargs)
            if [ -z \"\$REMAINING\" ]; then
                echo \"✅ [Machine $INDEX - $IP] Processes exited cleanly.\"
                break
            fi

            echo \"⚠️  [Machine $INDEX - $IP] Still running after SIGINT: \$REMAINING. Waiting $POLL_INTERVAL_SECONDS seconds...\"
        done
    "

    INDEX=$((INDEX + 1))
done < "$IP_FILE"

echo "====================================================="
echo "   Stop Complete."
echo "====================================================="
