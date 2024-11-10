#!/usr/bin/env python3

import os
import sys
import argparse
import yaml

def process_file(filepath):
    with open(filepath, 'r') as file:
        try:
            data = yaml.safe_load(file)
        except yaml.YAMLError as exc:
            print(f"Error parsing {filepath}: {exc}")
            return False

    if data is None:
        print(f"File is empty or contains invalid YAML: {filepath}")
        return False

    original_data = yaml.dump(data)
    modified = False

    def replace_integration_type(data):
        nonlocal modified
        if isinstance(data, dict):
            for key, value in data.items():
                if key == 'IntegrationTypeName' and isinstance(value, list):
                    new_list = []
                    for item in value:
                        if item == 'aws':
                            new_list.append('aws_cloud')
                            modified = True
                        elif item == 'azure':
                            new_list.append('azure_subscription')
                            modified = True
                        else:
                            new_list.append(item)
                    data[key] = new_list
                else:
                    replace_integration_type(value)
        elif isinstance(data, list):
            for item in data:
                replace_integration_type(item)

    replace_integration_type(data)

    if modified:
        with open(filepath, 'w') as file:
            yaml.dump(data, file, default_flow_style=False)
        print(f"Modified: {filepath}")
    else:
        print(f"No changes in: {filepath}")

    return True

def main():
    parser = argparse.ArgumentParser(description='Replace IntegrationTypeName values in YAML files.')
    parser.add_argument('directory', nargs='?', default='.', help='Directory to start from (default: current directory)')
    parser.add_argument('-r', '--recursive', action='store_true', help='Recursively search through subdirectories')
    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"Error: Directory '{args.directory}' does not exist.")
        sys.exit(1)

    yaml_files = []
    if args.recursive:
        for root, dirs, files in os.walk(args.directory):
            for file in files:
                if file.endswith(('.yaml', '.yml')):
                    yaml_files.append(os.path.join(root, file))
    else:
        for file in os.listdir(args.directory):
            if file.endswith(('.yaml', '.yml')):
                yaml_files.append(os.path.join(args.directory, file))

    for filepath in yaml_files:
        print(f"Processing: {filepath}")
        process_file(filepath)

    print("Replacement process complete.")

if __name__ == "__main__":
    main()
