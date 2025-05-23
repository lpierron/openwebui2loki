#!/bin/bash

# Make the script executable
chmod +x openwebui2loki.py

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install Python 3 and try again."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Please install pip3 and try again."
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
pip3 install -r requirements.txt

# Check if the database file exists
if [ ! -f "datas/webui.db" ]; then
    echo "Error: Database file 'datas/webui.db' not found."
    echo "Please make sure the database file is in the 'datas' directory."
    exit 1
fi

# Run the script
echo "Starting OpenWebUI to Loki connector..."
python3 openwebui2loki.py --db datas/webui.db --audit-log datas/audit.log "$@"