#!/bin/bash

create_secret_properties()
{
     input="${1}"
     while IFS= read -r line
     do
         awk "/^${line}/" "${2}" >> "${3}"
         #sed -i "/^${line}/d" "${2}"
     done < "$input"

     if [ -f "${3}" ]
     then
         cp -p "${3}" "${3}.temp"
         sort -u "${3}.temp" > "${3}" 
         rm -f "${3}.temp"
     fi
}

create_yaml_from_template()
{

    PROP_FILE=$1
    cp -p $2 $3
    YAML_TEMPLATE=$3
    sed -i '/^\s*\(#[^!].*\|#$\)/d' "$PROP_FILE"
    sed -i '/^\s*$/d' "$PROP_FILE"
    while IFS='=' read -r key value
    do
        val=_VALUE
        SILENT_KEY=$key$val
        value=`sed -e "s/^\"/'/" -e "s/\"$/'/" <<<"$value"`
        search_and_replace " $SILENT_KEY"  " $value" "$YAML_TEMPLATE"
    done < "$PROP_FILE"

}

create_yaml_helm_package()
{

    PROP_FILE=$1
    cp -rp $2 $3/$4
    YAML_TEMPLATE=$3/$4/values.yaml
    while IFS='=' read -r key value
    do
        val=_VALUE
        SILENT_KEY=$key$val
        search_and_replace " $SILENT_KEY"  " $value" "$YAML_TEMPLATE"
    done < "$PROP_FILE"

    tar czf $3/$4.tar.gz -C $3 $4

    rm -rf $3/$4
}
