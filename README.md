# fbsd_jails
Scripts to automate process of setting up FreeBSD jails

1. Make /etc/jail from etc/jail.conf.example.

2. Create base with etc/create_base.sh.

3. To create new jail run etc/newjail.sh (without arguments it will 
show usage info).

4. Add configuration for mdconfig into rc.conf. For example: 
mdconfig_md8="-t vnode -f /usr/local/jails/dns2/disk"


