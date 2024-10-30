#!/usr/bin/sh
export WORKSPACE=`pwd`
cd $WORKSPACE/artifacts

mkdir IDMFramework
unzip -q IDM_Framework_4.8.zip -d IDMFramework
unzip -q 3rdParty_Jars.zip
tar -zxf Identity_Manager_Linux_LightWeight_Designer.tar.gz

cd $WORKSPACE

cd config
chmod -R 755 *

cd $WORKSPACE

./config/Get_core_binaries.sh
./config/Get_drivers_binaries.sh
./config/Copy_core_binaries.sh
./config/SHA256Digest.sh
./config/jdk_packaging.sh
./config/Build_ISO.sh
#./config/RL_build.sh
#./config/build_helmcharts.sh

cd artifacts

rm -rf *.zip *.tar.gz

cd $WORKSPACE
