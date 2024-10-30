#!/bin/bash
##################################################################################
#
# Copyright © 2017 NetIQ Corporation, a Micro Focus company. All Rights Reserved.
#
##################################################################################

#log_file=

set_log_file()
{
	log_file=$1
}

get_log_file()
{
    return log_file

}

# Although the method is named as sameline, it will
# still introduce a newline
# The current behavior is as intended
echo_sameline()
{
    if [ $UNATTENDED_INSTALL -eq 0 ]
    then
        echo "$1"
    fi
}

write_log()
{
        dirn=`dirname $log_file`
        if [ ! -d $dirn ]
        then
                mkdir -p $dirn 2>/dev/null
        fi

        if [ -n "$log_file" ]
        then
                if [ $# -eq 0 ]
                then
                    echo >> $log_file
                else
                    echo_sameline "`date '--rfc-3339=seconds'` : $*" >>$log_file
                    echo $* >> $log_file
                fi
        fi
}

write_and_log()
{
    if [ $UNATTENDED_INSTALL -eq 0 ]
    then
        echo "$*"
    fi
    write_log $*
}

ckyorn()
{
	shift
		ckyornstr="$@"
		ans=""
		while [ -z "$ans" ] || [ "$ans" = "ERRVAL" ]
			do
				write_log "$@"
					if [ $UNATTENDED_INSTALL -eq 0 ]
					then
						read -e -p "$ckyornstr [y/n/q] ? " ans
					else
						read ans
					fi
					ans=`echo $ans | tr "[:upper:]" "[:lower:]"`
					case $ans in
					y|yes) return 1 ;;
			n|no) return 0 ;;
			q|quit) exit 1 ;;
			*) str1=`gettext install "Invalid option : "`
				echo "$INSTR $str1$ans"
				ans="ERRVAL" ;;
			esac
				done
}

abort_and_exit()
{
	write_log "ABORTED"
		exit 1
}

write_final_log()
{
	dirn=`dirname $log_file`
	if [ ! -d $dirn ]
	then
		mkdir -p $dirn 2>/dev/null
	fi
	if [ -n "$log_file" ]
	then
		echo $* > $log_file
	fi
}

echo_text()
{
        # Check the window size for proper line count
        LINES=`stty size | awk '{print $1}'`
        COLUMNS=`stty size | awk '{print $2}'`

        ECHO_DATA="$1"
        LINES_LEFT=`echo "${ECHO_DATA}" | fold -sw $COLUMNS | wc -l`

        BLOCKSIZE=22

        if [ $LINES -gt 0 ]
        then
                BLOCKSIZE=$(( $LINES - 2 ))
        fi

        # Keep going 'til we run out of lines to view
        while [ $LINES_LEFT -gt 0 ]
        do
                echo "${ECHO_DATA}" | fold -sw $COLUMNS | tail -n $LINES_LEFT | head -n $BLOCKSIZE

                LINES_LEFT=$(( $LINES_LEFT - $BLOCKSIZE ))

                if [ $LINES_LEFT -gt 0 ]
                then
                        # Try to keep a full screen. Looks better.
                        if [ $LINES_LEFT -lt $BLOCKSIZE ]
                        then
                                LINES_LEFT=$BLOCKSIZE
                        fi

                        echo
                        if [ "${ACCMAN_INST_AUTO}" -ne 0 ]
                        then
                                read -es -p "PRESS ENTER TO CONTINUE:"
                        fi
                        echo
                fi
        done
}

