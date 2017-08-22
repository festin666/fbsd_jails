#!/bin/sh

usage() {
cat << EOF
Usage: 
		$0 -n <jailname> -i <ip4> -m <md> [-s <size>] [-b <base>] [-r]

creates new jail <jailname> size <size> megabytes with IPv4 address <ip4> 
based on <base> system (built with create_base.sh)
ONLY IF -r SPECIFIED else will simply display all commands on screen.
<md> - md-unit like md0, md1, ...
EOF
}

execute() {
	[ $dry -eq 1 ] && echo $1
	[ $dry -eq 0 ] && echo "Executing '$1'" && eval "$1"
}

[ $# -lt 1 ] && usage && exit;

jail_name=""
jail_size="500"
jail_ip=""
jail_md=""
jail_base_raw="/usr/local/jails/_base4"
dry=1
jail_parent="/usr/local/jails"
while getopts n:s:i:m:rb: var; do
	case $var in
		n) jail_name="${OPTARG}";;
		s) jail_size="${OPTARG}";;
		i) jail_ip4="${OPTARG}";;
		m) jail_md="${OPTARG}";;
		b) jail_base_raw="${OPTARG}";;
		r) dry=0;;
		*) echo unknown argument '$var';;
	esac
done

[ -z ${jail_ip4} ] && usage && exit
[ -z ${jail_md} ] && usage && exit
[ -d "${jail_parent}/${jail_name}" ] && echo "Directory ${jail_parent}/${jail_name} already exists!" && exit
[ $dry -eq 0 ] && set -e errexit
jail_md_file=${jail_parent}/${jail_name}/disk
jail_base=`echo ${jail_base_raw} | sed -e 's@\/@\\\/@g'`

execute "mkdir ${jail_parent}/${jail_name}"
execute "cp -R skel/fstab ${jail_parent}/${jail_name}"
execute "cp -R skel/jail ${jail_parent}/${jail_name}"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_MD/${jail_md}/g\" -e \"s/JAIL_BASE/${jail_base}/g\" -i '' ${jail_parent}/${jail_name}/fstab"
execute "dd if=/dev/zero of=${jail_md_file} count=0 bs=1m seek=${jail_size}"
execute "mdmfs -F ${jail_md_file} ${jail_md} ${jail_parent}/${jail_name}/jail/rw"
execute "cp -R skel/rw/ ${jail_parent}/${jail_name}/jail/rw"
execute "umount ${jail_parent}/${jail_name}/jail/rw"
#execute "mdconfig -du ${jail_md}"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_IP4/${jail_ip4}/g\"  etc/jail.template >> /etc/jail.conf"
# -e \"s/JAIL_PARENT/${jail_parent}/g\" # need to escape slashes in $jail_parent
echo Jail ${jail_name} created. Installing packages...
execute "jail -cv ${jail_name}"
echo "Initialize jail for ansible and continue"
execute "jexec ${jail_name} pw useradd ansible_temp -e+1d -h- -m -g wheel"
execute "jexec ${jail_name} mkdir /home/ansible_temp/.ssh"
execute "cp etc/ansible.key ${jail_parent}/${jail_name}/jail/rw/home/ansible_temp/.ssh/authorized_keys"
exit
