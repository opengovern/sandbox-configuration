#!/bin/bash

# Description:
# This script traverses all subdirectories to find YAML files containing the 'Integration_Type_Name' key
# and renames the key to 'IntegrationTypeName' while preserving its values.

# Define the root directory (current directory)
ROOT_DIR="."

# Create or clear the log files
> renamed_files.log
> error_files.log
> error_messages.log

# Find all .yaml and .yml files
find "$ROOT_DIR" -type f \( -iname "*.yaml" -o -iname "*.yml" \) -print0 | while IFS= read -r -d '' file; do
  # Check if the file contains the 'Integration_Type_Name:' key
  if grep -q '^Integration_Type_Name:' "$file"; then
    echo "Processing: $file"
    
    # Apply the yq transformation to rename the key
    if yq eval -i '
      .IntegrationTypeName = .Integration_Type_Name |
      del(.Integration_Type_Name)
    ' "$file"; then
      echo "$file renamed successfully." >> renamed_files.log
    else
      echo "Error renaming $file" >> error_files.log
      # Capture detailed error messages
      yq eval -i '
        .IntegrationTypeName = .Integration_Type_Name |
        del(.Integration_Type_Name)
      ' "$file" 2>> error_messages.log
    fi
  fi
done

echo "Bulk renaming completed. Check 'renamed_files.log' for details."
echo "Any errors are logged in 'error_files.log' and 'error_messages.log'."
