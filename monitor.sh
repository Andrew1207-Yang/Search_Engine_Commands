#!/bin/bash

IP_FILE="ips.txt"
SSH_USER="ayayang" # Change if your GCP user is different
INDEX=0

if [ ! -f "$IP_FILE" ]; then
    echo "Error: $IP_FILE not found!"
    exit 1
fi

echo "====================================================="
echo "   Scanning 44 VMs for Crawler Health..."
echo "====================================================="

while IFS= read -r IP; do
    [ -z "$IP" ] && continue

    ssh -n -i ~/.ssh/gcp_key -o StrictHostKeyChecking=no "$SSH_USER@$IP" "
        REPO_DIR='Search-Engines'
        LOG_PATH=''
        PID=''

        if [ -f \"\$REPO_DIR/search_engine.log\" ]; then
            LOG_PATH=\"\$REPO_DIR/search_engine.log\"
        elif [ -f \"\$REPO_DIR/crawler.log\" ]; then
            LOG_PATH=\"\$REPO_DIR/crawler.log\"
        elif [ -f 'crawler.log' ]; then
            LOG_PATH='crawler.log'
        fi

        if [ -f \"\$REPO_DIR/crawler.pid\" ]; then
            PID=\$(cat \"\$REPO_DIR/crawler.pid\")
            if ! kill -0 \"\$PID\" 2>/dev/null; then
                PID=''
            fi
        fi

        if [ -z \"\$PID\" ]; then
            PID=\$(ps -eo pid=,args= | awk '/[s]earch_engine_distributed([[:space:]]|$)/ { print \$1; exit }')
        fi

        if [ -z \"\$PID\" ]; then
            echo \"[Machine $INDEX - $IP] CRASHED or NOT RUNNING\"
            if [ -n \"\$LOG_PATH\" ]; then
                echo '   Last error in log:'
                tail -n 10 \"\$LOG_PATH\" | sed 's/^/      /'
            else
                echo '   Last error in log:'
                echo '      No known crawler log file found.'
            fi
        else
            echo \"[Machine $INDEX - $IP] RUNNING (PID: \$PID)\"
            if [ -n \"\$LOG_PATH\" ]; then
                echo '   Latest activity:'
                tail -n 1 \"\$LOG_PATH\" | sed 's/^/      /'
            else
                echo '   Latest activity:'
                echo '      Process is running, but no known crawler log file was found.'
            fi
        fi
    "

    INDEX=$((INDEX + 1))
done < "$IP_FILE"

echo "====================================================="
echo "   Scan Complete."
echo "====================================================="
