#!/bin/bash

TOP_DIR=`pwd`
BUILD_DIR="$TOP_DIR/cd-image"
ARTIFACTS="$TOP_DIR/artifacts"
SENTINEL_ROOT="$TOP_DIR/cd-image/SentinelLogManagementforIGA"

printf "\n****************************Get the Sentinel linux Binaries to the workarea***************************\n"
printf "\n******************************************************************************************************\n"

mkdir artifacts
cd $ARTIFACTS

wget -q http://blr-builder.labs.blr.novell.com/artifacts/dorado_sentinel_linux/8.5.1.1/sentinel-collector.zip
wget -q http://blr-builder.labs.blr.novell.com/artifacts/dorado_sentinel_linux/8.5.1.1/sentinel_server-8.5.1.1-6003.x86_64.tar.gz
wget -q http://blr-builder.labs.blr.novell.com/artifacts/dorado_sentinel_linux/8.5.1.1/NetIQ_Identity-Manager_2011.1r6.clz.zip
wget -q http://blr-builder.labs.blr.novell.com/artifacts/dorado_sentinel_linux/8.5.1.1/NetIQ_eDirectory_2011.1r12.clz.zip

tar -zxf sentinel_server-8.5.1.1-6003.x86_64.tar.gz 
rm -rf sentinel_server-8.5.1.1-6003.x86_64.tar.gz

printf "\n****************************Copy Sentinel Build to the workarea***************************************\n"
printf "\n******************************************************************************************************\n"

cp -rpf $ARTIFACTS/sentinel_server-*.x86_64/* $SENTINEL_ROOT/packages
cp -rpf $ARTIFACTS/sentinel-collector.zip $SENTINEL_ROOT/content
cp -rpf $ARTIFACTS/NetIQ_Identity-Manager_2011.1r6.clz.zip $SENTINEL_ROOT/content
cp -rpf $ARTIFACTS/NetIQ_eDirectory_2011.1r12.clz.zip $SENTINEL_ROOT/content

printf "\n****************************Archive Sentinel Build to the workarea************************************\n"
printf "\n******************************************************************************************************\n"

cd $BUILD_DIR
mv SentinelLogManagementforIGA SentinelLogManagementForIGA8.5.1.1
tar -zcvf $TOP_DIR/SentinelLogManagementForIGA8.5.1.1.tar.gz SentinelLogManagementForIGA8.5.1.1

printf "\n****************************Generate the MD5SUM & SHA256SUM of the build******************************\n"
printf "\n******************************************************************************************************\n"

cd $TOP_DIR
md5sum SentinelLogManagementForIGA8.5.1.1.tar.gz > SentinelLogManagementForIGA8.5.1.1.tar.gz.md5
sha256sum SentinelLogManagementForIGA8.5.1.1.tar.gz > SentinelLogManagementForIGA8.5.1.1.tar.gz.sha256sum
