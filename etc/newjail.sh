#!/bin/sh

usage() {
cat << EOF
Usage: 
		$0 -n <jailname> -i <ip4> [-s <size>] [-b <base>] [-r]

creates new jail <jailname> size <size> megabytes with IPv4 address <ip4> 
based on <base> system (built with create_base.sh)
ONLY IF -r SPECIFIED else will simply display all commands on screen.
EOF
}

execute() {
	[ $dry -eq 1 ] && echo $1
	[ $dry -eq 0 ] && echo "Executing '$1'" && eval "$1"
}

[ $# -lt 1 ] && usage && exit;

jail_name=""
jail_size="500"
jail_ip="" #TODO
jail_base_raw="/usr/local/jails/_base4" #TODO last created?
dry=1
jail_parent="/usr/local/jails"
while getopts n:s:i:rb: var; do
	case $var in
		n) jail_name="${OPTARG}";;
		s) jail_size="${OPTARG}";;
		i) jail_ip4="${OPTARG}";;
		b) jail_base_raw="${OPTARG}";;
		r) dry=0;;
		*) echo unknown argument '$var';;
	esac
done

[ -z ${jail_ip4} ] && usage && exit
[ -d "${jail_parent}/${jail_name}" ] && echo "Directory ${jail_parent}/${jail_name} already exists!" && exit
[ $dry -eq 0 ] && set -e errexit
jail_base=`echo ${jail_base_raw} | sed -e 's@\/@\\\/@g'`

execute "mkdir ${jail_parent}/${jail_name}"
execute "cp -R skel/fstab ${jail_parent}/${jail_name}"
execute "cp -R skel/jail ${jail_parent}/${jail_name}"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_BASE/${jail_base}/g\" -i '' ${jail_parent}/${jail_name}/fstab"
execute "cp -R skel/rw/ ${jail_parent}/${jail_name}/rw"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_IP4/${jail_ip4}/g\"  etc/jail.template >> /etc/jail.conf"
# -e \"s/JAIL_PARENT/${jail_parent}/g\" # need to escape slashes in $jail_parent
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" etc/rctl.template >> /etc/rctl.conf"
echo Consider to restart rctl
echo Jail ${jail_name} created. Installing packages...
execute "jail -cv ${jail_name}"
echo "Initialize jail for ansible and continue"
execute "jexec ${jail_name} pw useradd ansible_temp -e+1d -h- -m -g wheel"
execute "jexec ${jail_name} mkdir /home/ansible_temp/.ssh"
execute "cp etc/ansible.key ${jail_parent}/${jail_name}/rw/home/ansible_temp/.ssh/authorized_keys"
exit
