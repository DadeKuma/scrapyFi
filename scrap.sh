#!/bin/bash

# Check if a project name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <PROJECT_NAME>"
    exit 1
fi

env_path="./venv/bin/activate"

# Creates virtualenv if it wasn't set up already
if [ ! -e "$env_path" ]; then
    virtualenv venv && source $env_path && pip3 install -r requirements.txt
fi

# Run the command and capture the output
PROJECT_NAME=$1
source $env_path
output=$(python3 scrapyfi.py search -q "$PROJECT_NAME")

# Extract GITHUB and CONTRACT links
github_links=$(echo "$output" | awk '/GITHUB:/,/CONTRACT:/ {if (NF>1) print $0}' | grep -o 'https://github\.com[^ ]*')
contract_links=$(echo "$output" | sed -n '/CONTRACT:/,/OTHER:/p' | grep -o 'https://[a-zA-Z0-9./?=_-]*')

# Concatenate GITHUB and CONTRACT links with spaces
github_and_contract_links_concatenated=$(echo "$github_links $contract_links" | tr '\n' ' ')

# Run the download command in the background
python3 scrapyfi.py download -fn "$PROJECT_NAME" $github_and_contract_links_concatenated &
download_pid=$!

# Print the extracted information
echo "Downloading contracts..."
while [ -n "$(ps -p $download_pid -o pid=)" ]; do
    if read -t 1 -r line; then
        echo "$line"
    fi
done

# Wait for the background process to finish
wait $download_pid

echo "Finished"
# Kill virtualenv
deactivate