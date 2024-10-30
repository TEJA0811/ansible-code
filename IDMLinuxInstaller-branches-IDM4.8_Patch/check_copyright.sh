#!/bin/bash

INPUT_FILE=scripts.txt
COPY_SAMPLE=copy.txt

init_script_file()
{
	# truncate the existing file
	>${INPUT_FILE}
	find cd-image/ -name "*.sh" >> ${INPUT_FILE}
	# special care for files without extension
	echo "cd-image/IDM/idm-nonroot-install" >> ${INPUT_FILE}
	echo "cd-image/IDM/idm-install-schema" >> ${INPUT_FILE}
	# add an empty line
	echo "" >> ${INPUT_FILE}
}

check_copyright()
{
    while read file
	do
        if [ "${file}" == "" ]
        then
            continue
        fi
		#echo "Processing file : ${file}"
		grep -E "`tail -1 copy.txt`" ${file} >> /dev/null
        result=$?
        if [ ${result} -ne 0 ]
        then
            echo "ERROR : Missing copyright in file : ${file} ..."
        #else
        #    echo "SUCCESS : Copyright found in file : ${file} ..."
        fi
	done < "${INPUT_FILE}"
}

main()
{
    init_script_file
    check_copyright
}

main $*
