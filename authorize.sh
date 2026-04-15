# Set your target group and the directory name
IP_FILE="ips_sub.txt"
SSH_USER="ayayang" # TODO: Change to the default GCP user (e.g., ubuntu, or your username)


TARGET_GROUP="google-sudoers"
PROJECT_DIR="Search-Engines"

# Check if IP file exists
if [ ! -f "$IP_FILE" ]; then
    echo "Error: $IP_FILE not found!"
    exit 1
fi

while IFS= read -r IP; do
    [ -z "$IP" ] && continue
    
    echo "Updating permissions on: $IP"
    
    # We use -t to force a pseudo-terminal if needed, 
    # and run the commands in one go.
    ssh -i ~/.ssh/gcp_key -o StrictHostKeyChecking=no "$SSH_USER@$IP" "
        # 1. Open the 'front door' (your home directory) 
        # Others can now enter, but NOT list your private files.
        chmod 755 ~

        # 2. Open the project folder
        # 755 = You can Read/Write/Execute; Others can only Read/Execute.
        # If you want them to be able to EDIT/DELETE files, change 755 to 777.
        if [ -d 'Search-Engines' ]; then
            chmod -R 777 Search-Engines
            echo '   ✅ Search-Engines set to 777'
        else
            echo '   ⚠️ Folder Search-Engines not found'
        fi
    " & # The '&' runs them in parallel so it doesn't take forever
done < "$IP_FILE"

wait
echo "All machines updated."