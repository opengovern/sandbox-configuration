#!/bin/bash

# Script Name: replace_integration_types.sh
# Description: 
#   Replaces '- aws' with '- aws_cloud_account' and '- azure' with '- azure_subscription'
#   within the IntegrationType sections of YAML files.
#
# Usage: 
#   ./replace_integration_types.sh [-r] [directory]
#     -r        : Recursively search through subdirectories
#     directory : Directory to start from (default: current directory)

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display usage instructions
usage() {
    echo "Usage: $0 [-r] [directory]"
    echo "  -r           Recursively search through subdirectories"
    echo "  directory    Directory to start from (default: current directory)"
    exit 1
}

# Initialize variables
RECURSIVE=false
START_DIR="."

# Parse options
while getopts "r" opt; do
    case "$opt" in
        r)
            RECURSIVE=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# If a directory is provided, use it
if [ "$#" -ge 1 ]; then
    START_DIR="$1"
fi

# Check if the starting directory exists and is a directory
if [ ! -d "$START_DIR" ]; then
    echo "Error: Directory '$START_DIR' does not exist." >&2
    exit 1
fi

# Determine the find command based on the recursive flag
if [ "$RECURSIVE" = true ]; then
    FIND_CMD=(find "$START_DIR" -type f)
else
    FIND_CMD=(find "$START_DIR" -maxdepth 1 -type f)
fi

# Find and process each file
for FILE in "${FIND_CMD[@]}"; do
    # Check if the file has a .yaml or .yml extension
    if [[ "$FILE" =~ \.(yaml|yml)$ ]]; then
        # Output processing message
        echo "Processing: $FILE"

        # Check if the file contains 'IntegrationType:'
        if grep -q "^IntegrationType:" "$FILE"; then
            # Create a temporary file securely
            TMP_FILE=$(mktemp)

            # Use awk to perform the replacements within the IntegrationType block
            awk '
            BEGIN { in_block = 0 }
            /^IntegrationType:/ {
                print;
                in_block = 1;
                next
            }
            # Exit the block if a new top-level key starts (line starts with non-space and not a list item)
            /^[^[:space:]]/ && !/^[[:space:]]*-/ {
                in_block = 0
            }
            # If within the IntegrationType block and line matches '- aws', replace it
            in_block == 1 && /^[[:space:]]*-[[:space:]]*aws[[:space:]]*$/ {
                sub(/- aws[[:space:]]*$/, "- aws_cloud_account")
            }
            # If within the IntegrationType block and line matches '- azure', replace it
            in_block == 1 && /^[[:space:]]*-[[:space:]]*azure[[:space:]]*$/ {
                sub(/- azure[[:space:]]*$/, "- azure_subscription")
            }
            { print }
            ' "$FILE" > "$TMP_FILE"

            # Compare the original file with the modified file
            if ! cmp -s "$FILE" "$TMP_FILE"; then
                # Replace the original file with the modified file
                mv "$TMP_FILE" "$FILE"
                echo "Modified: $FILE"
            else
                # No changes made; remove the temporary file
                rm "$TMP_FILE"
            fi
        else
            echo "No IntegrationType section found in: $FILE"
        fi
    else
        # Non-YAML files are ignored, but still output processing message
        echo "Processing: $FILE (skipped, not a YAML file)"
    fi
done

echo "Replacement process complete."
