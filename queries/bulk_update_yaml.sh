#!/bin/bash

# Description:
# This script traverses all subdirectories to find YAML files containing the 'Connector' key
# and renames the key to 'IntegrationTypeName' while mapping specific values.

# Define the root directory (current directory)
ROOT_DIR="."

# Create or clear the log files
> processed_files.log
> error_files.log
> error_messages.log

# Function to process each file
process_file() {
  local file="$1"
  echo "Processing: $file"

  # Apply the yq transformation
  if yq eval -i '.IntegrationTypeName = (if (.Connector | type) == "array" then .Connector | map({"aws": "aws_cloud", "azure": "azure_subscription"}[.] // .) else {"aws": "aws_cloud", "azure": "azure_subscription"}[.Connector] // .Connector end) | del(.Connector)' "$file"
  then
    echo "$file processed successfully." >> processed_files.log
  else
    echo "Error processing $file" >> error_files.log
    # Capture detailed error messages
    yq eval '.IntegrationTypeName = (if (.Connector | type) == "array" then .Connector | map({"aws": "aws_cloud", "azure": "azure_subscription"}[.] // .) else {"aws": "aws_cloud", "azure": "azure_subscription"}[.Connector] // .Connector end) | del(.Connector)' "$file" 2>> error_messages.log
  fi
}

export -f process_file

# Find and process all .yaml and .yml files containing the 'Connector' key
find "$ROOT_DIR" -type f \( -iname "*.yaml" -o -iname "*.yml" \) -print0 | while IFS= read -r -d '' file; do
  if grep -q '^Connector:' "$file"; then
    process_file "$file"
  fi
done

echo "Bulk update completed. Check 'processed_files.log' for details."
echo "Any errors are logged in 'error_files.log' and 'error_messages.log'."