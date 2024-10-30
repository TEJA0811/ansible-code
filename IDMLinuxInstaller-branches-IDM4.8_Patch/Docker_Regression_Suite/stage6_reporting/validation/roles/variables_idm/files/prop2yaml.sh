#!/bin/bash

input_prop_file="modifiable_copy_silent_props"
output_yaml_file="../vars/silent.yml"

# Copy the provided file for modification
touch $input_prop_file
cp -f "$1" $input_prop_file

# Remove any existing (i.e., previous) conversion file
rm -f $output_yaml_file &> /dev/null

# Start the YAML file
touch $output_yaml_file
echo -e "---\n# IDM silent properties converted to Ansible format\n\n" > $output_yaml_file

# Remove all comments
sed -i '/^\s*\(#[^!].*\|#$\)/d' "$input_prop_file"
# Remove all empty lines
sed -i '/^\s*$/d' "$input_prop_file"

# Convert every property to an Ansible variable equivalent
# IDM conversion file (create_silent_props.sh) places all values within double-quotes
while IFS='=' read -r key value; do
    echo " "  >> $output_yaml_file
    echo "$key: $value" >> $output_yaml_file
done < "$input_prop_file"

# Finish the YAML file
echo -e "\n..." >> $output_yaml_file

# Remove the temporary modifiable file
rm -f $input_prop_file
