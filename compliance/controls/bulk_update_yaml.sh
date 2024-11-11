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

# Find all .yaml and .yml files
find "$ROOT_DIR" -type f \( -iname "*.yaml" -o -iname "*.yml" \) -print0 | while IFS= read -r -d '' file; do
  # Check if the file contains the 'Connector:' key
  if grep -q '^Connector:' "$file"; then
    echo "Processing: $file"
    
    # Apply the yq transformation with enhanced handling
    if yq eval -i '
      .IntegrationTypeName = (
        if type == "array" then
          .Connector | map(
            {
              "aws": "aws_cloud_account",
              "azure": "azure_subscription"
            }[.] // .
          )
        else
          {
            "aws": "aws_cloud_account",
            "azure": "azure_subscription"
          }[.] // .
        end
      ) |
      del(.Connector)
    ' "$file"; then
      echo "$file processed successfully." >> processed_files.log
    else
      echo "Error processing $file" >> error_files.log
      # Capture detailed error messages
      yq eval -i '
        .IntegrationTypeName = (
          if type == "array" then
            .Connector | map(
              {
                "aws": "aws_cloud_account",
                "azure": "azure_subscription"
              }[.] // .
            )
          else
            {
              "aws": "aws_cloud_account",
              "azure": "azure_subscription"
            }[.] // .
          end
        ) |
        del(.Connector)
      ' "$file" 2>> error_messages.log
    fi
  fi
done

echo "Bulk update completed. Check 'processed_files.log' for details."
echo "Any errors are logged in 'error_files.log' and 'error_messages.log'."
