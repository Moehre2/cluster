#!/bin/bash

if [ ! $(which ssh) ]; then
	echo "Please install ssh to use this script."
	exit 1
fi
if [ ! $(which sshpass) ]; then
	echo "Please install sshpass to use this script."
	exit 2
fi

mkdir -p $HOME/.config
if [ ! -f "$HOME/.config/cluster" ]; then
	echo "SERVERS=\"\"" >> "$HOME/.config/cluster"
	echo "#USER=" >> "$HOME/.config/cluster"
	echo "COPYSERVERS=\"\"" >> "$HOME/.config/cluster"
fi
source "$HOME/.config/cluster"

action="login"
verbose=0
source_file=""
target_file=""

while [ "$1" != "" ]; do
    case $1 in
        -v | --verbose)
            verbose=1
            ;;
        *)
            case $1 in
            	login)
            		action="login"
            		;;
            	put)
            		action="put"
            		shift
            		source_file="$1"
            		shift
            		target_file="$1"
            		;;
            	get)
            		action="get"
            		shift
            		source_file="$1"
            		shift
            		target_file="$1"
            		;;
            	refresh)
            		action="refresh"
            		;;
            	*)
            		echo "Error: Unknown action"
            		exit 1
            		;;
            esac
            ;;
    esac
    shift
done

SERV=""

if [ "$action" = "login" ]; then
	if [ "$SERVERS" = "" ]; then
		echo "No servers available..."
		echo "Please modify $HOME/.config/cluster and specify login nodes"
		exit 0
	else
		SERV="$SERVERS"
	fi
elif [[ "$action" = "put" || "$action" = "get" ]]; then
	if [ "$COPYSERVERS" = "" ]; then
		echo "No servers available..."
		echo "Please modify $HOME/.config/cluster and specify copy nodes"
		exit 0
	else
		SERV="$COPYSERVERS"
	fi
elif [ "$action" = "refresh" ]; then
	SERV="$SERVERS $COPYSERVERS"
	for s in $SERV; do
		if [ "$verbose" = "1" ]; then
			echo "Refresh $s"
		fi
		ssh $USER@$s "exit"
	done
	exit 0
fi

MIN=1; until (( (MIN<<=1) < 0 )) ;do :;done
((MAX=MIN-1))
avail=1
opt=
opt_user=$MAX
re_num='^[0-9]+$'

for s in $SERV; do
	cur_user=$(sshpass -p "$password" ssh $USER@$s "users | tr ' ' '\n' | wc -l")
	if [[ $cur_user =~ $re_num ]]; then
		avail=0
		if [ "$verbose" = "1" ]; then
			echo "$s ($cur_user)"
		fi
		if [ $cur_user -lt $opt_user ]; then
			opt_user=$cur_user
			opt=$s
		fi
	fi
done

if [ "$avail" = "1" ]; then
	echo "None of the specified servers is available..."
	exit 3
fi

if [ "$action" = "login" ]; then
	ssh $USER@$opt
elif [ "$action" = "put" ]; then
	scp "$source_file" "${USER}@${opt}:${target_file}"
elif [ "$action" = "get" ]; then
	scp "${USER}@${opt}:${source_file}" "$target_file"
fi

