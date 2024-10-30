#!/bin/bash

TOP_DIR=`pwd`
WORKAREA=$TOP_DIR

cd $WORKAREA/docker/orchestration/kubernetes
./build.sh

cd $WORKAREA/cloud_deployment/azure
./build.sh

cd $WORKAREA/docker/orchestration/kubernetes/
cp -rpf final kubernetes
zip -r $WORKAREA/kubernetes.zip kubernetes

cd $WORKAREA/cloud_deployment/azure
cp -rpf final azure
zip -r $WORKAREA/azure.zip azure

cd $WORKAREA
