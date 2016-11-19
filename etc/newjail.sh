#!/bin/sh

usage() {
cat << EOF
Usage: 
		$0 -n <jailname> -i <ip4> -m <md> [-s <size>] [-r]

creates new jail <jailname> size <size> megabytes with IPv4 address <ip4> 
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
dry=1
jail_parent="/usr/local/jails"
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
[ -d "${jail_parent}/${jail_name}" ] && echo "Directory ${jail_parent}/${jail_name} already exists!" && exit
[ $dry -eq 0 ] && set -e errexit

execute "cp -R skel/ ${jail_parent}/${jail_name}"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_MD/${jail_md}/g\" -i '' ${jail_parent}/${jail_name}/fstab"
execute "dd if=/dev/zero of=${jail_parent}/${jail_name}/disk count=0 bs=1m seek=${jail_size}"
execute "mdmfs -F ${jail_parent}/${jail_name}/disk ${jail_md} ${jail_parent}/${jail_name}/md"
execute "umount ${jail_parent}/${jail_name}/md"
#execute "mdconfig -du ${jail_md}"
execute "sed -e \"s/JAIL_NAME/${jail_name}/g\" -e \"s/JAIL_IP4/${jail_ip4}/g\"  etc/jail.template >> /etc/jail.conf"
# -e \"s/JAIL_PARENT/${jail_parent}/g\" # need to escape slashes in $jail_parent
echo Jail ${jail_name} created. Installing packages...
execute "jail -cv ${jail_name}"
echo "Do install packages via Chef or something like?"

#if [ ${jail_name} == "jenkins" ]; then
#	execute "pkg -c ${jail_name}/jail install --yes php56 jenkins php-composer git php56-filter php56-mbstring php56-mcrypt php56-curl php56-simplexml php56-dom php56-tokenizer php-xdebug php56-xmlwriter php56-iconv php56-session wget mysql56-client php56-pdo_mysql"
#	#execute "jexec -U jenkins -j ${jail_name} composer global require \"codeception/codeception=2.0.*\""
#fi
#if [ ${jail_name} == "mysql" ]; then
#	execute "pkg -c ${jail_name}/jail install --yes mysql56-server"
#fi
#if [ ${jail_name} == "httppre" ]; then
#	execute "pkg -j ${jail_name} install --yes mysql56-server"
#	execute "pkg -j ${jail_name} install --yes lighttpd"
#	execute "pkg -j ${jail_name} install --yes php56 php56-mbstring php56-mcrypt php56-curl php56-iconv php56-session php56-hash php56-ctype php56-pdo_mysql"
#fi
#[ ${jail_name} == "pbx2" ] && execute "pkg -c ${jail_name}/jail install --yes asterisk11"
#execute "pkg -c ${jail_name}/jail info"
#echo "Checking '~festin/conf/${jail_name}'"
#if [ -f "/home/festin/conf/${jail_name}/onetime.sql" ]; then
#	execute "jexec ${jail_name} mysql -u root < '/home/festin/conf/${jail_name}/onetime.sql'"
#fi
#if [ -d "/home/festin/conf/${jail_name}" ]; then
#	execute "mkdir -p ${jail_name}/md/usr/local/etc/"
#	execute "cp -R ~festin/conf/${jail_name}/ ${jail_name}/md/"
#fi
exit
