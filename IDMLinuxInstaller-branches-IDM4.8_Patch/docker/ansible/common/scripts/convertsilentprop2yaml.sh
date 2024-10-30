#!/bin/bash
playbook_dir=$1
input_prop_file=$2

output_yaml_file="$playbook_dir/roles/variables/files/main.yml"
output_prop_file="$playbook_dir/roles/variables/files/silent.properties"

rm -f $output_yaml_file &> /dev/null
touch $output_yaml_file

rm -f $output_prop_file &> /dev/null
touch $output_prop_file

echo "---" > $output_yaml_file

echo "# Vars file for pre_install_role" >> $output_yaml_file
echo ""
sed -i '/^\s*\(#[^!].*\|#$\)/d' "$input_prop_file"
sed -i '/^\s*$/d' "$input_prop_file"


while IFS='=' read -r key value
do
    echo " "  >> $output_yaml_file
		
    if [ "$key" = "OSP_COMM_TOMCAT_KEYSTORE_FILE" ]; then
		echo "OSP_COMM_TOMCAT_KEYSTORE_BASENAME: \"${value##*/}" >> $output_yaml_file
        echo "OSP_COMM_TOMCAT_KEYSTORE_FILE: \"/config/${value##*/}" >> $output_yaml_file
        echo "OSP_COMM_TOMCAT_KEYSTORE_FILE=\"/config/${value##*/}" >> $output_prop_file		
    elif [ "$key" = "RPT_COMM_TOMCAT_KEYSTORE_FILE" ]; then
		echo "RPT_COMM_TOMCAT_KEYSTORE_BASENAME: \"${value##*/}" >> $output_yaml_file
        echo "RPT_COMM_TOMCAT_KEYSTORE_FILE: \"/config/${value##*/}" >> $output_yaml_file
        echo "RPT_COMM_TOMCAT_KEYSTORE_FILE=\"/config/${value##*/}" >> $output_prop_file		
    elif [ "$key" = "UA_COMM_TOMCAT_KEYSTORE_FILE" ]; then
		echo "UA_COMM_TOMCAT_KEYSTORE_BASENAME: \"${value##*/}" >> $output_yaml_file
        echo "UA_COMM_TOMCAT_KEYSTORE_FILE: \"/config/${value##*/}" >> $output_yaml_file
        echo "UA_COMM_TOMCAT_KEYSTORE_FILE=\"/config/${value##*/}" >> $output_prop_file		
    else
		echo "$key: $value" >> $output_yaml_file
		echo "$key=$value" >> $output_prop_file
	fi
				
done < "$input_prop_file"

echo "..." >> $output_yaml_file
