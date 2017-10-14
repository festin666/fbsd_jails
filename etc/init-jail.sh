#!/bin/sh


usage() {
cat << EOF
Usage: 
		$0 <jailname>

init jail <jailname> to work as ansible node:
# enables login and sudo via LDAP
EOF
} 
execute() {
	[ $dry -eq 1 ] && echo $1
	[ $dry -eq 0 ] && echo "Executing '$1'" && eval "$1"
}
[ $# -lt 1 ] && usage && exit;
jail_name=$1
[ -z ${jail_name} ] && usage && exit
dry=1
execute "jexec $jail_name pkg add -f /tmp/sudo-1.8.20.txz /tmp/nss_ldap-1.265_12.txz"
execute "jexec $jail_name pkg install -y pam_ldap pam_mkhomedir"

execute "cp skel/etc/ldap.conf /usr/local/jails/${jail_name}/jail/usr/local/etc/openldap/"
execute "jexec ${jail_name} rm /usr/local/etc/openldap/ldap.conf.sample"

execute "cp skel/etc/nsswitch.conf /usr/local/jails/${jail_name}/jail/etc/"

execute "cp skel/etc/sshd /usr/local/jails/${jail_name}/jail/usr/local/etc/pam.d/"
execute "jexec ${jail_name} rm /etc/pam.d/sshd"

execute "cp skel/etc/ldap_pam.conf /usr/local/jails/${jail_name}/jail/usr/local/etc/ldap.conf"
execute "jexec ${jail_name} rm /usr/local/etc/ldap.conf.dist"

execute "cp skel/etc/nss_ldap.conf /usr/local/jails/${jail_name}/jail/usr/local/etc/"
execute "jexec ${jail_name} rm /usr/local/etc/nss_ldap.conf.sample"

execute "cp skel/etc/publicKeyFromLdap.sh /usr/local/jails/${jail_name}/jail/usr/local/bin/publicKeyFromLdap.sh"

execute "cp skel/etc/sshd_config /usr/local/jails/${jail_name}/jail/etc/ssh/"

execute "cp skel/etc/sudo.conf /usr/local/jails/${jail_name}/jail/usr/local/etc/"
