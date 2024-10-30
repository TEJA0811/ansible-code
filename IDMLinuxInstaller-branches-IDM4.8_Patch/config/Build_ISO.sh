#!/bin/bash

# Set up paths.
ROOT_DIR=`pwd`
BUILD_DIR="$ROOT_DIR/cd-image"

echo "**** Removing .svn file from build ****"
cd $BUILD_DIR
find . -name ".svn" |xargs rm -rf
find . -name ".git" |xargs rm -rf
find . -name ".gitignore" |xargs rm -rf

printf "\n*********************** Remove the empty directories from the dvd structure ***********************************\n"
printf "\n***************************************************************************************************************\n"

cd $BUILD_DIR
find . -type d -empty -print
find . -type d -empty -delete

echo "**** Rename rpm files to accepted nomenclature ****"
cd $BUILD_DIR

find . -name "*.rpm" | while read I; do
   DIRNAME=$(dirname "$I")
   NEWRPMNAME=`rpm -qp --qf "%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm" $I`
   mv $I "$DIRNAME/$NEWRPMNAME"
done

printf "\n******************************** Sign the RPM from the dvd structure ******************************************\n"
printf "\n***************************************************************************************************************\n"

cd $ROOT_DIR
bash +x config/RPM_Signing.sh

#mkisofs -l -J -r -A "Identity Manager 4.7 - Linux_Framework" -V "IDM4.7_Lin_FW" -p "NOVELL Inc." -publisher "Novell Inc." -copyright copy.txt -hide-rr-moved -x $BUILD_DIR/designer -x $BUILD_DIR/analyzer -x $BUILD_DIR/osp -x $BUILD_DIR/reporting -x $BUILD_DIR/sspr -x $BUILD_DIR/user_application -x $BUILD_DIR/SentinelLogManagementforIGA -o $ROOT_DIR/Identity_Manager_4.7_Linux_Framework.iso $ROOT_DIR/cd-image

#mkisofs -l -J -r -A "Identity Manager 4.7 - Linux_Reporting" -V "IDM4.7_Lin_Rep" -p "NOVELL Inc." -publisher "Novell Inc." -copyright copy.txt -hide-rr-moved -x $BUILD_DIR/designer/packages/Identity_Manager_4.7_Linux_Designer.tar.gz -x $BUILD_DIR/analyzer -x $BUILD_DIR/osp -x $BUILD_DIR/IDVault -x $BUILD_DIR/sspr -x $BUILD_DIR/user_application -x $BUILD_DIR/IDM -x $BUILD_DIR/iManager -o $ROOT_DIR/Identity_Manager_4.7_Linux_Reporting.iso $ROOT_DIR/cd-image

#mkisofs -l -J -r -A "Identity Manager 4.7 - Linux_IdentityApplication" -V "IDM4.7_Lin_UA" -p "NOVELL Inc." -publisher "Novell Inc." -copyright copy.txt -hide-rr-moved -x $BUILD_DIR/analyzer -x $BUILD_DIR/IDVault -x $BUILD_DIR/reporting -x $BUILD_DIR/iManager -x $BUILD_DIR/IDM -x $BUILD_DIR/SentinelLogManagementforIGA -x $BUILD_DIR/designer/packages/Identity_Manager_4.7_Linux_Designer.tar.gz -o $ROOT_DIR/Identity_Manager_4.7_Linux_IdentityApplication.iso $ROOT_DIR/cd-image

mkisofs -l -J -r -A "Identity Manager 4.8.8 - Linux" -V "IDM4.8.8_Lin" -p "NOVELL Inc." -publisher "Novell Inc." -copyright copy.txt -hide-rr-moved -x $BUILD_DIR/SentinelLogManagementforIGA -o $ROOT_DIR/Identity_Manager_4.8.8_Linux.iso $ROOT_DIR/cd-image

cd $ROOT_DIR
md5sum Identity_Manager_4.8.8_Linux.iso > Identity_Manager_4.8.8_Linux.iso.md5
sha256sum Identity_Manager_4.8.8_Linux.iso > Identity_Manager_4.8.8_Linux.iso.sha256sum
