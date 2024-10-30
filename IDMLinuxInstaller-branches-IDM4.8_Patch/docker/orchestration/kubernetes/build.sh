#!/bin/bash

cd "$(dirname "$0")"

[ -d final ] && rm -r final
mkdir -p final/helm_charts
mkdir -p final/templates

echo "Building Helm Charts"
cd helm_packages
helm package remote-loader
helm package fanout-agent
helm package identity-manager
cd ..
mv helm_packages/*.tgz final/helm_charts/

cp templates/rl-values.yaml final/templates/
cp templates/fa-values.yaml final/templates/
cp templates/values.yaml final/templates/
cp templates/data_containers.ldif final/
cp templates/values.yaml final/


templates/defaultvalues.sh




 