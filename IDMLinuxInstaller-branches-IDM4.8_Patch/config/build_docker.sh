#!/bin/bash

TOP_DIR=`pwd`
BASEDIR=$TOP_DIR/docker
WORKAREA=$TOP_DIR
VERSION=idm-4.8.8
DOCKER_REGISTRY=sec-idm-docker.btpartifactory.swinfra.net

cd $BASEDIR

docker pull opensuse/leap:15.4

echo "build osp"

cd osp
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t osp:latest . > $WORKAREA/osp_container_log.txt
docker tag osp:latest $DOCKER_REGISTRY/iam-cm/$VERSION/osp:$1 >> $WORKAREA/osp_container_log.txt
docker tag osp:latest $DOCKER_REGISTRY/iam-cm/$VERSION/osp:latest >> $WORKAREA/osp_container_log.txt
docker tag osp:latest osp:$VERSION >> $WORKAREA/osp_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/osp:$1 >> $WORKAREA/osp_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/osp:latest >> $WORKAREA/osp_container_log.txt
cd $BASEDIR
docker save -o IDM_488_osp.tar osp:$VERSION
gzip IDM_488_osp.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/osp:latest $DOCKER_REGISTRY/iam-cm/$VERSION/osp:$1 osp:latest osp:$VERSION >> $WORKAREA/osp_container_log.txt

echo "build identityapplication"
cd identityapplication
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t identityapplication:latest . > $WORKAREA/identityapplication_container_log.txt
docker tag identityapplication:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityapplication:latest >> $WORKAREA/identityapplication_container_log.txt
docker tag identityapplication:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityapplication:$1 >> $WORKAREA/identityapplication_container_log.txt
docker tag identityapplication:latest identityapplication:$VERSION >> $WORKAREA/identityapplication_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityapplication:latest >> $WORKAREA/identityapplication_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityapplication:$1 >> $WORKAREA/identityapplication_container_log.txt
cd $BASEDIR
docker save -o IDM_488_identityapplication.tar identityapplication:$VERSION
gzip IDM_488_identityapplication.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/identityapplication:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityapplication:$1 identityapplication:latest identityapplication:$VERSION >> $WORKAREA/identityapplication_container_log.txt

echo "build identityreporting"
cd identityreporting
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t identityreporting:latest . > $WORKAREA/identityreporting_container_log.txt
docker tag identityreporting:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityreporting:latest >> $WORKAREA/identityreporting_container_log.txt
docker tag identityreporting:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityreporting:$1 >> $WORKAREA/identityreporting_container_log.txt
docker tag identityreporting:latest identityreporting:$VERSION >> $WORKAREA/identityreporting_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityreporting:latest >> $WORKAREA/identityreporting_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityreporting:$1 >> $WORKAREA/identityreporting_container_log.txt
cd $BASEDIR
docker save -o IDM_488_identityreporting.tar identityreporting:$VERSION
gzip IDM_488_identityreporting.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/identityreporting:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityreporting:$1 identityreporting:latest identityreporting:$VERSION >> $WORKAREA/identityreporting_container_log.txt

echo "build identityengine"
cd identityengine
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t identityengine:latest . > $WORKAREA/identityengine_container_log.txt
docker tag identityengine:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityengine:latest >> $WORKAREA/identityengine_container_log.txt
docker tag identityengine:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityengine:$1 >> $WORKAREA/identityengine_container_log.txt
docker tag identityengine:latest identityengine:$VERSION >> $WORKAREA/identityengine_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityengine:latest >> $WORKAREA/identityengine_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityengine:$1 >> $WORKAREA/identityengine_container_log.txt
cd $BASEDIR
docker save -o IDM_488_identityengine.tar identityengine:$VERSION
gzip IDM_488_identityengine.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/identityengine:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityengine:$1 identityengine:latest identityengine:$VERSION >> $WORKAREA/identityengine_container_log.txt

echo "build Activemq"
cd activemq
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t activemq:latest . > $WORKAREA/activemq_container_log.txt
docker tag activemq:latest $DOCKER_REGISTRY/iam-cm/$VERSION/activemq:latest >> $WORKAREA/activemq_container_log.txt
docker tag activemq:latest $DOCKER_REGISTRY/iam-cm/$VERSION/activemq:$1 >> $WORKAREA/activemq_container_log.txt
docker tag activemq:latest activemq:$VERSION >> $WORKAREA/activemq_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/activemq:latest >> $WORKAREA/activemq_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/activemq:$1 >> $WORKAREA/activemq_container_log.txt
cd $BASEDIR
docker save -o IDM_488_activemq.tar activemq:$VERSION
gzip IDM_488_activemq.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/activemq:latest $DOCKER_REGISTRY/iam-cm/$VERSION/activemq:$1 activemq:latest activemq:$VERSION >> $WORKAREA/activemq_container_log.txt

echo "build formrenderer"
cd formrenderer
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t formrenderer:latest . > $WORKAREA/formrenderer_container_log.txt
docker tag formrenderer:latest $DOCKER_REGISTRY/iam-cm/$VERSION/formrenderer:latest >> $WORKAREA/formrenderer_container_log.txt
docker tag formrenderer:latest $DOCKER_REGISTRY/iam-cm/$VERSION/formrenderer:$1 >> $WORKAREA/formrenderer_container_log.txt
docker tag formrenderer:latest formrenderer:$VERSION >> $WORKAREA/formrenderer_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/formrenderer:latest >> $WORKAREA/formrenderer_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/formrenderer:$1 >> $WORKAREA/formrenderer_container_log.txt
cd $BASEDIR
docker save -o IDM_488_formrenderer.tar formrenderer:$VERSION
gzip IDM_488_formrenderer.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/formrenderer:latest $DOCKER_REGISTRY/iam-cm/$VERSION/formrenderer:$1 formrenderer:latest formrenderer:$VERSION >> $WORKAREA/formrenderer_container_log.txt

echo "build fanoutagent"
cd fanoutagent
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t fanoutagent:latest . > $WORKAREA/fanoutagent_container_log.txt
docker tag fanoutagent:latest $DOCKER_REGISTRY/iam-cm/$VERSION/fanoutagent:latest >> $WORKAREA/fanoutagent_container_log.txt
docker tag fanoutagent:latest $DOCKER_REGISTRY/iam-cm/$VERSION/fanoutagent:$1 >> $WORKAREA/fanoutagent_container_log.txt
docker tag fanoutagent:latest fanoutagent:$VERSION >> $WORKAREA/fanoutagent_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/fanoutagent:latest >> $WORKAREA/fanoutagent_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/fanoutagent:$1 >> $WORKAREA/fanoutagent_container_log.txt
cd $BASEDIR
docker save -o IDM_488_fanoutagent.tar fanoutagent:$VERSION
gzip IDM_488_fanoutagent.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/fanoutagent:latest $DOCKER_REGISTRY/iam-cm/$VERSION/fanoutagent:$1 fanoutagent:latest fanoutagent:$VERSION >> $WORKAREA/fanoutagent_container_log.txt

echo "build remoteloader"
cd remoteloader
docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t remoteloader:latest . > $WORKAREA/remoteloader_container_log.txt
docker tag remoteloader:latest $DOCKER_REGISTRY/iam-cm/$VERSION/remoteloader:latest >> $WORKAREA/remoteloader_container_log.txt
docker tag remoteloader:latest $DOCKER_REGISTRY/iam-cm/$VERSION/remoteloader:$1 >> $WORKAREA/remoteloader_container_log.txt
docker tag remoteloader:latest remoteloader:$VERSION >> $WORKAREA/remoteloader_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/remoteloader:latest >> $WORKAREA/remoteloader_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/remoteloader:$1 >> $WORKAREA/remoteloader_container_log.txt
cd $BASEDIR
docker save -o IDM_488_remoteloader.tar remoteloader:$VERSION
gzip IDM_488_remoteloader.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/remoteloader:latest $DOCKER_REGISTRY/iam-cm/$VERSION/remoteloader:$1 remoteloader:latest remoteloader:$VERSION >> $WORKAREA/remoteloader_container_log.txt

echo "build identityutils"

cd identityutils

docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t identityutils:latest . > $WORKAREA/identityutils_container_log.txt
docker tag identityutils:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityutils:$1 >> $WORKAREA/identityutils_container_log.txt
docker tag identityutils:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityutils:latest >> $WORKAREA/identityutils_container_log.txt
docker tag identityutils:latest identityutils:$VERSION >> $WORKAREA/identityutils_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityutils:$1 >> $WORKAREA/identityutils_container_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/identityutils:latest >> $WORKAREA/identityutils_container_log.txt
cd $BASEDIR
docker save -o IDM_488_identityutils.tar identityutils:$VERSION
gzip IDM_488_identityutils.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/identityutils:latest $DOCKER_REGISTRY/iam-cm/$VERSION/identityutils:$1 identityutils:latest identityutils:$VERSION > $WORKAREA/identityutils_container_log.txt

echo "build idm_conf_generator"

cd idm_conf_generator

docker build --no-cache --build-arg BUILD_ID="${BUILD_NUMBER}" -t idm_conf_generator:latest . > $WORKAREA/idm_conf_generator_log.txt
docker tag idm_conf_generator:latest $DOCKER_REGISTRY/iam-cm/$VERSION/idm_conf_generator:$1 >> $WORKAREA/idm_conf_generator_log.txt
docker tag idm_conf_generator:latest $DOCKER_REGISTRY/iam-cm/$VERSION/idm_conf_generator:latest >> $WORKAREA/idm_conf_generator_log.txt
docker tag idm_conf_generator:latest idm_conf_generator:$VERSION >> $WORKAREA/idm_conf_generator_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/idm_conf_generator:$1 >> $WORKAREA/idm_conf_generator_log.txt
docker push $DOCKER_REGISTRY/iam-cm/$VERSION/idm_conf_generator:latest >> $WORKAREA/idm_conf_generator_log.txt
cd $BASEDIR
docker save -o IDM_488_idm_conf_generator.tar idm_conf_generator:$VERSION
gzip IDM_488_idm_conf_generator.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/idm_conf_generator:latest $DOCKER_REGISTRY/iam-cm/$VERSION/idm_conf_generator:$1 idm_conf_generator:latest idm_conf_generator:$VERSION >> $WORKAREA/idm_conf_generator_log.txt

echo "Build the docker tarball for delivery"

cd $BASEDIR

#echo "build postgres"

docker pull $DOCKER_REGISTRY/iam-cm/$VERSION/postgres/postgres:12.15
docker tag $DOCKER_REGISTRY/iam-cm/$VERSION/postgres/postgres:12.15 postgres:12.15
docker save -o IDM_488_postgres.tar postgres:12.15
gzip IDM_488_postgres.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/postgres/postgres:12.15 postgres:12.15

#echo "build coredns"

docker pull $DOCKER_REGISTRY/iam-cm/$VERSION/coredns/coredns:1.10.1
docker tag $DOCKER_REGISTRY/iam-cm/$VERSION/coredns/coredns:1.10.1 coredns:1.10.1
docker save -o IDM_488_coredns.tar coredns:1.10.1
gzip IDM_488_coredns.tar
docker rmi $DOCKER_REGISTRY/iam-cm/$VERSION/coredns/coredns:1.10.1 coredns:1.10.1

cd $BASEDIR

mkdir -p Identity_Manager_4.8.8_Containers/{docker-images,terraform,helm_charts,common}
mkdir -p Identity_Manager_4.8.8_Containers/common/license
mv *.tar.gz Identity_Manager_4.8.8_Containers/docker-images
cd Identity_Manager_4.8.8_Containers/docker-images
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/IDM/IDM_4.8_Patches/SSPR/4.7.0.0/sspr-docker-4.7.0.0.tar.gz
mv sspr-docker-4.7.0.0.tar.gz IDM_488_sspr.tar.gz
###Removed iManager from 4.8.7
#wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/iManager/326_P3_FCS/Container/iManager_326_P3_Container.tar.gz
#tar -zxf iManager_326_P3_Container.tar.gz
#rm -rf iManager_326_P3_Container.tar.gz
#mv iManager_326_P3/iManager_326_P3.tar.gz .
#rm -rf iManager_326_P3
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/Publish/Identity_Console/1.7.1_FCS/container_build/IdentityConsole_171_Containers.tar.gz
mkdir IdentityConsole_171_Containers
tar -zxf IdentityConsole_171_Containers.tar.gz -C IdentityConsole_171_Containers
rm -rf IdentityConsole_171_Containers.tar.gz
mv IdentityConsole_171_Containers/identityconsole.tar.gz identityconsole_171.tar.gz
rm -rf IdentityConsole_171_Containers

#Copy 3rdparty ITLS attribution

cd $BASEDIR
cp -rpf $WORKAREA/cd-image/common/license/IdentityManager-3rdParty-license.txt Identity_Manager_4.8.8_Containers/common/license

#Read-only permission for conf.yml
cd $BASEDIR
cp -rpf ansible Identity_Manager_4.8.8_Containers 
cp -rpf ACRCreate.sh Identity_Manager_4.8.8_Containers
chmod 444 Identity_Manager_4.8.8_Containers/ansible/common/conf/conf.yml
chmod 755 Identity_Manager_4.8.8_Containers/ACRCreate.sh

#Copy IDM helm charts and terraform configuration
cd $BASEDIR
cd $WORKAREA/artifacts
unzip -q azure.zip
unzip -q kubernetes.zip
cd $BASEDIR
cp -rpf $WORKAREA/artifacts/azure/*.zip Identity_Manager_4.8.8_Containers/terraform
cp -rpf $WORKAREA/artifacts/kubernetes/helm_charts/*.tgz Identity_Manager_4.8.8_Containers/helm_charts/
cp -rpf $WORKAREA/artifacts/kubernetes/templates/*.yaml Identity_Manager_4.8.8_Containers/helm_charts/

#Remove git files
cd $BASEDIR/Identity_Manager_4.8.8_Containers
rm -rf `find . -iname .gitignore`

#Package the container tar.
cd $BASEDIR
tar -zcvf $WORKSPACE/Identity_Manager_4.8.8_Containers.tar.gz Identity_Manager_4.8.8_Containers

cd $WORKSPACE
