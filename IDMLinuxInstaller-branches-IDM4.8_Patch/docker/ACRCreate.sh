#!/bin/bash
##############size check ##########################
echo "Azure CLI must be installed and Docker should be up and running in the machine from where you run and free up atleast 6GB space before running the script"
IDM_VERSION=4.8.8
SSPR_VERSION=4.7.0.0-ea
currntdir="$PWD"
IDM_VERSION_WITHOUT_DOT=`echo "${IDM_VERSION//.}"`
CONSOLE_VERSION=1.7.0.0000


availspace=$(df -k $currntdir | grep -v Avail | awk '{print $4}')
neededspace=6000000
if [ $availspace -lt $neededspace ]
then	
	echo "Insufficient disk space to load the images,free up the required space and try again."
	exit 1
fi

looplimit=5
while [ $looplimit -gt 0 ]
do
    az login --use-device-code
    valueofexit=$(echo $?)
    #echo "valueofexit is $valueofexit"
    if [ $valueofexit -ne 0 ]
    then
        echo "azure login seems to have failed. Please Re-try"    
    else
        read -p "Enter the appropriate Azure Account "id" printed above as-is without double quotes : " AZURE_ACCOUNT_ID
        az account set --subscription $AZURE_ACCOUNT_ID
        if [ $? -ne 0 ]
        then
             continue
        fi
        break
    fi
    if [ $looplimit -eq 1 ]
    then
        echo  "azure login tried 5 times but is failing for some reason.  Try running az login outside of this script and check.  Exiting..."
        exit 1
    fi
    ((looplimit--))
done
##for f in *.tar.gz; do
##    cat $f | docker load
##done

read -p "Do you want to create azure container registry? (y/n) : " answer
if [[ $answer = y ]] ; then
  read -p "Do you want to create new resource group? (y/n) : " ans	
  if [[ $ans = y ]]
  then 	  
  read -p "Enter the azure resource group name (only alpha numeric characters are allowed) : " rg_name 
  read -p "Enter the azure resource group location (ex: eastus) : " az_location
  az group create --name "$rg_name"  --location "$az_location"
  else
  read -p "Enter the Existing azure resource group name (only alpha numeric characters are allowed) : " rg_name	  
  read -p "Enter the azure resource group location (ex: eastus) : " az_location
  fi
  looplimit=5
  while [ $looplimit -gt 0 ]
  do
    read -p "Enter the azure container registry name (only alpha numeric characters are allowed) : " REGISTRY_URL
    az acr create --resource-group "$rg_name" --name "$REGISTRY_URL" --sku Basic
    if [ $? -ne 0 ]
    then
        az_warning_msg=`gettext install "azure login seems to have failed. Re-try"`
    else
        REGISTRY_URL="${REGISTRY_URL}.azurecr.io"
        break
    fi
  if [ $looplimit -eq 1 ]
  then
      echo "You have exceeded maximum limit of azure registry creation.Exiting..."
      exit 1
  fi
  ((looplimit --))
  done
else  
    read -p "Enter the existing azure container registry URL (ex: azureregname.azurecr.io) : " REGISTRY_URL
fi
az acr login --name "$REGISTRY_URL"
echo "Azure registry credentials can be taken from the azure portal"

for file in docker-images/*; do
  
  filename="$(basename -- ${file})"
  
  comp=$(echo "${filename}" | sed "s/IDM_${IDM_VERSION_WITHOUT_DOT}_//g")
  comp=$(echo "${comp}" | sed "s/.tar.gz//g")
  
  case "$comp" in
  "sspr")     
     docker load --input "${file}"
     docker tag sspr/sspr-webapp:${SSPR_VERSION} ${REGISTRY_URL}/sspr/sspr-webapp:${SSPR_VERSION}
     docker push ${REGISTRY_URL}/sspr/sspr-webapp:${SSPR_VERSION}
     docker image rm ${REGISTRY_URL}/sspr/sspr-webapp:${SSPR_VERSION}
     docker image rm sspr/sspr-webapp:${SSPR_VERSION}
     ;;
  "activemq" | "formrenderer" | "identityutils" | "identityengine" | "remoteloader" | "fanoutagent" | "identityapplication" | "identityreporting" | "osp")
     docker load --input "${file}"
     docker tag ${comp}:idm-${IDM_VERSION} ${REGISTRY_URL}/${comp}:idm-${IDM_VERSION}
     docker push ${REGISTRY_URL}/${comp}:idm-${IDM_VERSION}
     docker image rm ${REGISTRY_URL}/${comp}:idm-${IDM_VERSION}
     docker image rm ${comp}:idm-${IDM_VERSION}
     ;;
  *)
     echo ""
     ;;
  esac
done

for file in docker-images/*; do

	filename="$(basename -- ${file})"
	echo ${filename} | grep -q identityconsole
	if [ $? -eq 0 ]
	then
	    comp=identityconsole
	else	
	    comp=$(echo "${filename}" | sed "s/.tar.gz//g")
    fi
        case "$comp" in
        "identityconsole") 
	  docker load --input "${file}"
      docker tag ${comp}:${CONSOLE_VERSION} ${REGISTRY_URL}/${comp}:${CONSOLE_VERSION}	
	  docker push ${REGISTRY_URL}/${comp}:${CONSOLE_VERSION}
	  docker image rm ${REGISTRY_URL}/${comp}:${CONSOLE_VERSION}
	  docker image rm ${comp}:${CONSOLE_VERSION}
	  ;;
        *) 
	  echo ""
          ;;
        esac	  
done	
	 

