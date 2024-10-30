#!/bin/bash

printf "\n************************************Copy original RPMS to be rebuilt*************************************\n"
printf "\n******************************************************************************************************\n"
mkdir -p $WORKSPACE/sha256digest
cp -rpf $WORKSPACE/cd-image/IDM/packages/OpenSSL/i586/netiq-openssl-32bit-*.x86_64.rpm $WORKSPACE/sha256digest 
cp -rpf $WORKSPACE/cd-image/IDM/packages/cefprocessor/i386/novell-IDMCEFProcessor-*.i586.rpm $WORKSPACE/sha256digest 
#Not required from 4.8.7
#cp -rpf $WORKSPACE/cd-image/IDM/packages/cpplibrary/i586/novell-libstdc++6-32bit-*.x86_64.rpm $WORKSPACE/sha256digest 
cp -rpf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-DXMLrdxml-*.i586.rpm $WORKSPACE/sha256digest 
cp -rpf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-NOVLjvml-*.i586.rpm $WORKSPACE/sha256digest
cp -rpf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLjntls-*.i586.rpm $WORKSPACE/sha256digest
cp -rpf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-DXMLbase-*.i586.rpm $WORKSPACE/sha256digest

printf "\n************************************Remove RPM from source location***********************************\n"
printf "\n******************************************************************************************************\n"

rm -rf $WORKSPACE/cd-image/IDM/packages/OpenSSL/i586/netiq-openssl-32bit-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/cefprocessor/i386/novell-IDMCEFProcessor-*.i586.rpm
#Not required from 4.8.7
#rm -rf $WORKSPACE/cd-image/IDM/packages/cpplibrary/i586/novell-libstdc++6-32bit-*.x86_64.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-DXMLrdxml-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-NOVLjvml-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/driver/novell-DXMLjntls-*.i586.rpm
rm -rf $WORKSPACE/cd-image/IDM/packages/rl/i586/novell-DXMLbase-*.i586.rpm

printf "\n************************************Rpmrebuild on opensuse15 machine**********************************\n"
printf "\n******************************************************************************************************\n"

ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "mkdir rpmrebuild"
scp -r $WORKSPACE/sha256digest n4u_cm@iam-cm-opensuse15.labs.blr.novell.com:~/rpmrebuild
ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rpmrebuild -np -d ~/rpmrebuild/sha256digest_final ~/rpmrebuild/sha256digest/netiq-openssl-32bit-*.x86_64.rpm"
ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rpmrebuild -np -d ~/rpmrebuild/sha256digest_final ~/rpmrebuild/sha256digest/novell-IDMCEFProcessor-*.i586.rpm"
#Not required from 4.8.7
#ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rpmrebuild -np -d ~/rpmrebuild/sha256digest_final ~/rpmrebuild/sha256digest/novell-libstdc++6-32bit-*.x86_64.rpm"
ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rpmrebuild -np -d ~/rpmrebuild/sha256digest_final ~/rpmrebuild/sha256digest/novell-DXMLrdxml-*.i586.rpm"
ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rpmrebuild -np -d ~/rpmrebuild/sha256digest_final ~/rpmrebuild/sha256digest/novell-NOVLjvml-*.i586.rpm"
ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rpmrebuild -np -d ~/rpmrebuild/sha256digest_final ~/rpmrebuild/sha256digest/novell-DXMLjntls-*.i586.rpm"
ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rpmrebuild -np -d ~/rpmrebuild/sha256digest_final ~/rpmrebuild/sha256digest/novell-DXMLbase-*.i586.rpm"
scp -r n4u_cm@iam-cm-opensuse15.labs.blr.novell.com:~/rpmrebuild/sha256digest_final $WORKSPACE/
ssh n4u_cm@iam-cm-opensuse15.labs.blr.novell.com "rm -rf rpmrebuild"

printf "\n*******************************Copy sha256digit RPM to the workarea***********************************\n"
printf "\n******************************************************************************************************\n"


cp -vrpf $WORKSPACE/sha256digest_final/i586/novell-IDMCEFProcessor-*.i586.rpm "$WORKSPACE/cd-image/IDM/packages/cefprocessor/i386"
#Not required from 4.8.7
#cp -vrpf $WORKSPACE/sha256digest_final/x86_64/novell-libstdc++6-32bit-*.x86_64.rpm "$WORKSPACE/cd-image/IDM/packages/cpplibrary/i586"
cp -vrpf $WORKSPACE/sha256digest_final/i586/novell-DXMLrdxml-*.i586.rpm "$WORKSPACE/cd-image/IDM/packages/rl/i586"
cp -vrpf $WORKSPACE/sha256digest_final/i586/novell-NOVLjvml-*.i586.rpm  "$WORKSPACE/cd-image/IDM/packages/rl/i586"
cp -vrpf $WORKSPACE/sha256digest_final/x86_64/netiq-openssl-32bit-*.x86_64.rpm "$WORKSPACE/cd-image/IDM/packages/OpenSSL/i586"
cp -vrpf $WORKSPACE/sha256digest_final/i586/novell-DXMLjntls-*.i586.rpm  "$WORKSPACE/cd-image/IDM/packages/driver"
cp -vrpf $WORKSPACE/sha256digest_final/i586/novell-DXMLbase-*.i586.rpm  "$WORKSPACE/cd-image/IDM/packages/rl/i586"
