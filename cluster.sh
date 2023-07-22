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
fi
source "$HOME/.config/cluster"
if [ "$SERVERS" = "" ]; then
	echo "No servers available..."
	echo "Please modify $HOME/.config/cluster and specify login nodes"
	exit 0
fi

MIN=1; until (( (MIN<<=1) < 0 )) ;do :;done
((MAX=MIN-1))
avail=1
opt=
opt_user=$MAX
re_num='^[0-9]+$'

echo -n "Password: "
read -s password
echo

for s in $SERVERS; do
	cur_user=$(sshpass -p "$password" ssh $USER@$s "users | tr ' ' '\n' | wc -l")
	if [[ $cur_user =~ $re_num ]]; then
		avail=0
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

sshpass -p "$password" ssh $USER@$opt

