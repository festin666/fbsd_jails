#!/bin/sh

usage() {
cat << EOF
Usage: 
		$0 -n <jailname> -i <ip4> -m <md> [-s <size>] [-r]

creates new jail <jailname> size <size> megabytes with IPv4 address <ip4> 
only if -r specified else will simply display all commands on screen.
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
dry=1
while getopts n:s:i:m:r var; do
	case $var in
		n) jail_name="${OPTARG}";;
		s) jail_size="${OPTARG}";;
		i) jail_ip4="${OPTARG}";;
		m) jail_md="${OPTARG}";;
		r) dry=0;;
		*) echo unknown argument '$var';;
	esac
done

[ -z ${jail_ip4} ] && usage && exit
[ -z ${jail_md} ] && usage && exit
[ -d ${jail_name} ] && echo "Directory ${jail_name} already exists!" && exit
[ $dry -eq 0 ] && set -e errexit

execute "cp -R skel/ ${jail_name}"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_MD/${jail_md}/g\" -i '' ${jail_name}/fstab"
execute "dd if=/dev/zero of=${jail_name}/disk count=0 bs=1m seek=${jail_size}"
execute "mdmfs -F ${jail_name}/disk ${jail_md} ${jail_name}/md"
echo "Checking '~festin/conf/${jail_name}'"
if [ -d "/home/festin/conf/${jail_name}" ]; then
	execute "mkdir -p ${jail_name}/md/usr/local/etc/"
	execute "cp -R ~festin/conf/${jail_name}/ ${jail_name}/md/"
fi
execute "umount ${jail_name}/md"
#execute "mdconfig -du ${jail_md}"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_IP4/${jail_ip4}/g\" etc/jail.template >> /etc/jail.conf"
execute "jail -cv ${jail_name}"
if [ ${jail_name} == "jenkins" ]; then
	execute "pkg -c ${jail_name}/jail install --yes php56 jenkinsi php-composer"
fi
[ ${jail_name} == "pbx2" ] && execute "pkg -c ${jail_name}/jail install --yes asterisk11"
execute "pkg -c ${jail_name}/jail info"
execute "jail -rc ${jail_name}"
exit


