#!/bin/bash

TOP_DIR=`pwd`
VERSION=1.8.0-372
COMMON_RPMS_ROOT="$TOP_DIR/cd-image/common/packages"

printf "\n***********************************Get JRE 8 package to the workarea**********************************\n"
printf "\n******************************************************************************************************\n"

cd $WORKSPACE
mkdir $WORKSPACE/jdk_packaging
cd $WORKSPACE/jdk_packaging
wget -q http://blr-iam-builder.labs.blr.novell.com/artifacts/jdk/openjdk/azul/jdk8.0.372/netiq-jrex-1.8.0-372.x86_64.rpm
rpm2cpio netiq-jrex-$VERSION.x86_64.rpm | cpio -idmv
mkdir jre8 
cp -rpf opt/netiq/common/jre/* jre8
zip -qr netiq-jrex-$VERSION.zip jre8
rm -rf jre8
cp -rpf netiq-jrex-$VERSION.zip $COMMON_RPMS_ROOT/java
cd $WORKSPACE
