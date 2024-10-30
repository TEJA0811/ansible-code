#!/bin/bash

TOP_DIR=`pwd`
BASEDIR=$TOP_DIR/docker
WORKAREA=$TOP_DIR

echo "Build Helm Charts"

cd $BASEDIR/orchestration/kubernetes/helm_packages
helm package remote-loader
helm package fanout-agent
helm package identity-manager
cp -rpf *.tgz $WORKAREA

cd $WORKAREA
