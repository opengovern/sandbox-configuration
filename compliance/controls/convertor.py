import yaml
import json
import os
import re
import ruamel.yaml
# Load the YAML file
def load_yaml(file_path):
    with open(file_path, "r") as file:
        yaml = ruamel.yaml.YAML()
        yaml.width = 10000
        yaml.preserve_quotes = False
        yaml.line_break = "\n"
        return yaml.load(file)
    
# read the YAML file to dictionary
def read_yaml(file_path):
    data = load_yaml(file_path)
    return data
# get the all yaml files in the directory

def read_files_in_directory(files,directory):
    for file in os.listdir(directory):
        if(file == "new"):
            continue
        if file.endswith(".yaml"):
            # add full path to file list
            files.append(os.path.join(directory,file))
        if os.path.isdir(os.path.join(directory,file)):
            # pass
            read_files_in_directory(files,os.path.join(directory,file))
    return files

# remove \n from the string
def remove_newline(data):
    return data.replace("\n","\n")
            
#write data to yaml file
def write_yaml(file_path,data):
    # create directory if not exist
    if not os.path.exists(os.path.dirname(file_path)):
        os.makedirs(os.path.dirname(file_path))
    with open(file_path, "w") as file:
        # print(data)
        yaml = ruamel.yaml.YAML()
        yaml.width = 10000
        yaml.preserve_quotes = False
        yaml.indent(mapping=4, sequence=4, offset=2)
        yaml.line_break = "\n"
        yaml.dump(data, file)


def convert_data(data):
    new_data = {}
    new_data["id"] = data["ID"]
    new_data["title"] = data["Title"]
    new_data["description"] = data["Description"]
    new_data["integration_type"]= data["IntegrationType"]
    parameters = data["Query"]["Parameters"]
    # check if its empty array
    if not parameters:
        new_data["parameters"] = []
    else:
        params =[]
        for param in parameters:
            temp_param = {}
            if ('Key' in param):
                temp_param["key"] = param["Key"]
            if ('key' in param):
                temp_param["key"] = param["key"]
            if ('DefaultValue' in param):
                temp_param["value"] = param["DefaultValue"]
            params.append(temp_param)

        new_data["parameters"] = params
    new_data["policy"] = {}
    new_data["policy"]["language"] = "sql"
    new_data["policy"]["primary_resource"] = data["Query"]["PrimaryTable"]
    # new_data["policy"]["definition"] = remove_newline(data["Query"]["QueryToExecute"])
    new_data["policy"]["definition"] = data["Query"]["QueryToExecute"]

    new_data["severity"] = data["Severity"]
    new_data["tags"] = data["Tags"]

    return new_data

# main function
def main():
    files= []
    file_list =read_files_in_directory(files,".")
    # print(file_list)
    for file in file_list:
        print(file)
        data = read_yaml(file)
        new_data = convert_data(data)
        write_yaml(os.path.join("./new",file),new_data)


    

if __name__ == "__main__":
    main()



