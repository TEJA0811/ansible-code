#!/bin/bash -x

# This is the startup script for volumizing specified locations in volumes.yml
# file.

# include required scripts
# source volumize.sh

# Application script should be passed as first parameter
APP_SCRIPT="$1";

# include the functions
source "$APP_SCRIPT";

# set volume configured to false
VOLUME_CONFIGURED=false;

# set perllib5 for finding perl packages
PERL5LIB=$(pwd);

# perl command
PERL_CMD="perl -e ";

# set volumes.yml file location
VOL_YAML="volumes.yml";

# This function checks if backup is already done
function check_backup {
    print_vars;
    local stmt="use Container::Volume::Actions; Container::Volume::Actions->check_backup('$1');";
    echo "checking backup";
    PERL5LIB=$PERL5LIB $PERL_CMD "$stmt";
    local result=$?;
    if [ $result == 0 ] 
    then
        VOLUME_CONFIGURED=true;
    fi
}

# this function will verify if all files are intact that needs to be
function verify_backup {
    print_vars;
    echo "verifying backup";
    local stmt="use Container::Volume::Actions; Container::Volume::Actions->verify_backup('$1');";
    PERL5LIB=$PERL5LIB $PERL_CMD "$stmt";
}

# this function will create a backup as per yaml file
function do_backlink {
    print_vars;
    echo "backlinking is done";
    local stmt="use Container::Volume::Actions; Container::Volume::Actions->do_backlink('$1');";
    PERL5LIB=$PERL5LIB $PERL_CMD "$stmt";
}

# this function will create a backup as per yaml file
function do_backup {
    print_vars;
    echo "backup is done";
    local stmt="use Container::Volume::Actions; Container::Volume::Actions->do_backlink('$1');";
    PERL5LIB=$PERL5LIB $PERL_CMD "$stmt";
}

function print_vars {
    echo "volume configured variable: $VOLUME_CONFIGURED";
}



# check if backup is existing
check_backup "$VOL_YAML";

# verify existing backup if volume is configured
if [ "$VOLUME_CONFIGURED" = true ]
then
    verify_backup "$VOL_YAML";
    do_backlink "$VOL_YAML";
else 
    configure_app;
    stop_app;
    do_backup "$VOL_YAML";
fi

# start the application
start_app;

# block process from exiting
echo "Press ctrl+p ctrl+q to continue. This would detach you from the container.";
#tail -f /dev/null