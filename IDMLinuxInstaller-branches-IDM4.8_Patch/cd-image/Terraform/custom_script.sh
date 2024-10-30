#!/bin/sh
# Debug script location in vm @ /var/lib/waagent/custom-script/download/0/script.sh
systemctl start docker
systemctl enable docker
systemctl status docker
docker login ${imageregistryserver} -u ${imageregistryserverusername} -p ${imageregistryserverpassword}
docker pull "${imageregistryserver}/${engineimagename}"
cat <<FILEENDFORSURE >/root/silent.properties ${kvsecretvalue}
FILEENDFORSURE
echo "${tlscrtvalue}" > /root/tls.crt 
mkdir -p /data
Entereddisksize=${enginedatadisksize}
((Entereddisksize--))
vgcreate vg00 /dev/sdc
lvcreate -n vol_projects -L "$Entereddisksize"G vg00
mkfs.ext4 /dev/vg00/vol_projects
diskid=$(blkid /dev/vg00/vol_projects | cut -d" " -f2 | cut -d "\"" -f2)
echo UUID=$diskid /data ext4 defaults 0 0 >> /etc/fstab
mount -a
mv /root/silent.properties /data
chmod -R 777 /data
source /data/silent.properties
if [ ! -z $KUBE_USE_HOST_ALIAS_FOR_ENGINE ] && [ "$KUBE_USE_HOST_ALIAS_FOR_ENGINE" == "y" ]
then
    echo "10.0.2.4  $ID_VAULT_HOST" >> /etc/hosts
    export ENGINE_HOSTNAME=$ID_VAULT_HOST
else
    echo "10.0.2.4  $AZURE_DOCKER_VM_HOST_NAME.internal.cloudapp.net" >> /etc/hosts
    export ENGINE_HOSTNAME=$AZURE_DOCKER_VM_HOST_NAME.internal.cloudapp.net  
fi
docker run -d --network=host --name=engine-container --hostname=$ENGINE_HOSTNAME --restart=unless-stopped -v /data:/config -e SILENT_INSTALL_FILE=/config/silent.properties "${imageregistryserver}/${engineimagename}"
sleep 20
while true
do
    grep "Completed configuration of : Identity Manager Engine" /data/idm/log/idmconfigure.log
    if [ $? -eq 0 ]
    then
        break
    else
        sleep 10
    fi
done
sleep 60
mv /root/tls.crt /data/idm/
# Restarting so that tls.crt can be imported by startidm.sh of engine container
docker restart engine-container
