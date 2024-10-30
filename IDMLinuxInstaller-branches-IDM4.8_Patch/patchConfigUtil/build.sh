#!/bin/bash

##############################################################################
#                                                                            #
#    Usage: ./build.sh [build option]                                        #
#                                                                            #
#    Where build option can be:                                              #
#                           clean: Clean the project                         #
#                           clean-build: Clean and build the project         #
#                           build: Only build the project                    #      
##############################################################################

export ANT_ZIP_URL="http://blr-builder.labs.blr.novell.com/artifacts/ant/1.6/ant~1.6_5.zip"
if [[ $OSTYPE == *"linux"* ]]; then
	export JDK_ZIP_URL="http://blr-builder.labs.blr.novell.com/artifacts/jdk/1.8.0_update131/jdk_linux64_1.8.0_131.zip"
else
	export JDK_ZIP_URL="http://blr-builder.labs.blr.novell.com/artifacts/jdk/1.8.0_update131/jdk_windows64_1.8.0_131.zip"
fi
export IVY_URL="http://blr-builder.labs.blr.novell.com/artifacts/ivy/ivy-2.3.0.jar"
export CUSTOM_CODE_FOLDER="customcode"

# cd to the folder which contains this script
cd "${0%/*}"

export TOP_DIR="$PWD"
export PASS=0
export FAIL=1

# Validate the commnad line arguments
if [ $# != 1 ]; then
	echo "Usage: ./build.sh [build option]"
	echo "where build option can be:"
	echo "     clean: Clean the project"
	echo "     clean-build: Clean and build the project"
	echo "     build: Only build the project"
	exit $FAIL
fi
if [ $1 != "clean" ] && [ $1 != "clean-build" ] && [ $1 != "build" ]; then
	echo "Enter a proper build option."
	echo "Usage: ./build.sh [build option]"
	echo "where build option can be:"
	echo "     clean: Clean the project"
	echo "     clean-build: Clean and build the project"
	echo "     build: Only build the project"
	exit $FAIL
fi

# If clean-build then cleanup temporary files and directory
if [ $1 == "clean" ] || [ $1 == "clean-build" ]; then

	[ -d ant ] && rm -r ant
	[ -d JDK ] && rm -r JDK
	[ -f ivy/ivy.jar ] && rm -r ivy/ivy.jar
#	[ -d build ] && rm -r build
	[ -d final ] && rm -r final
	[ -d lib ] && rm -r lib
    [ -d bin ] && rm -r bin
	[ -d ivy/downloads ] && rm -r ivy/downloads
	
	if [ $1 == "clean" ]; then
		exit $PASS
	fi
fi


# Setup ant
echo -e "\nANT:"
if [ ! -d ant ]; then
	mkdir ant
	cd ant
	echo "  Downloading $ANT_ZIP_URL"
	wget -q $ANT_ZIP_URL
	unzip -q "${ANT_ZIP_URL##*/}"
	chmod -R 755 INSTALL KEYS LICENSE LICENSE.dom LICENSE.sax LICENSE.xerces NOTICE README TODO WHATSNEW "${ANT_ZIP_URL##*/}" bin docs etc lib welcome.html
	cd ..
fi
export ANT_HOME="$TOP_DIR/ant"
export PATH=$ANT_HOME/bin:$PATH
echo "  ANT_HOME=$ANT_HOME"

# Setup JDK
echo -e "\nJDK:"
if [ ! -d JDK ]; then
	echo "  Downloading $JDK_ZIP_URL"
	wget -q $JDK_ZIP_URL
	JDK_ZIP="${JDK_ZIP_URL##*/}"
	unzip -q $JDK_ZIP
	rm $JDK_ZIP
	mv "${JDK_ZIP%.*}" JDK
fi
export JAVA_HOME="$TOP_DIR/JDK"
export PATH=$JAVA_HOME/bin:$PATH
echo "  JAVA_HOME=$JAVA_HOME"

# Setup ivy
if [ ! -f ivy/ivy.jar ]; then
    echo -e "\nIVY:"
	cd ivy
	echo -e "  Downloading $IVY_URL\n"
	wget -q $IVY_URL
	mv "${IVY_URL##*/}" ivy.jar
	cd ..
fi

echo -e "\nPATH=$PATH"

# Setup final folder
if [ ! -d final ]; then
	mkdir final
else
	rm -rfv final/*
fi

# Build the code, if the dependencies already downloaded in ivy/downloads, skip downloading the dependencies
echo -e "\nBuilding patchConfigUtil.jar:"
echo "-------------------------------------------------------------------------"
if [ ! -d ivy/downloads ]; then
	ant clean build 
else
	ant clean build -Dskip.download.dependencies=true 
fi
exitcode=$?
echo "-------------------------------------------------------------------------"

# If build failed, exit with build failure
if [ $exitcode != 0 ]; then
	echo -e "\nBUILD FAILED"
	exit $FAIL
fi

# If the JAR file succesfully built and copied to final folder, exit with build success otherwise build failure 
if [ -f final/patchConfigUtil.jar ]; then
	echo -e "\nBUILD SUCCESSFUL"
	exit $PASS
else
	echo -e "\nBUILD FAILED"
	exit $FAIL
fi
