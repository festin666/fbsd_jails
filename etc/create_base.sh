#!/bin/sh

JAIL_BASE=$1 # TODO Make validation
SRCCONF=`readlink -f etc/src.conf`
echo Create base in ${JAIL_BASE}
if [ -d "${JAIL_BASE}" ]; then
	echo "${JAIL_BASE} already exists. Exiting"
    curdir=`pwd`
    cd ${JAIL_BASE}
    if [ $? -eq 0 ]; then
        [ -e rw ] || mkdir rw
        [ -e usr/ports ] || mkdir usr/ports
        [ -e usr/ports/distfiles ] || ln -s ../../rw/distfiles usr/ports/distfiles
        [ -d etc -o -L etc ] || ln -s rw/etc etc
        [ -d home -o -L home ] || ln -s rw/home home
        [ -e usr/home ] || ln -s ../rw/home usr/home
        [ -d root -o -L root ] || ln -s rw/root root
        [ -d usr/local -o -L usr/local ] || ln -s ../rw/usr-local usr/local
        [ -d tmp -o -L tmp ] || ln -s rw/tmp tmp
        [ -d var -o -L var ] || ln -s rw/var var
        cd $curdir
    fi
	exit 1
fi
mkdir -p $JAIL_BASE
if [ ! -f logs/createbase.log ]; then
	touch logs/createbase.log
fi
LOGFILE=`readlink -f logs/createbase.log`
cd /usr/src
cat <<E
	Making world for base. It may take up to three hours!
	You can look to ${LOGFILE} for progress.
	[wait...]
E
make world DESTDIR=$JAIL_BASE SRCCONF=${SRCCONF} > ${LOGFILE} 2>&1
echo status=$?
if [ $? -ne 0 ]; then
    echo "Couldn't compile world. See log for details."
    exit 1
fi
cat <<-E
	*********************************************
	The World has been built in ${JAIL_BASE}
	Making distribution
	*********************************************
E	
make distribution DESTDIR=$JAIL_BASE SRCCONF=${SRCCONF} >> ${LOGFILE} 2>>&1
echo status=$?
cat <<-E
	*********************************************
	Base is ready!

	Place cloned_interfaces="lo1" to /etc/rc.conf
	*********************************************
E
curdir=`pwd`
cd ${JAIL_BASE}
if [ $? -eq 0 ]; then
    mkdir rw
    ln -s rw/etc etc
    ln -s rw/home home
    ln -s rw/root root
    ln -s ../rw/usr-local usr/local
    ln -s rw/tmp tmp
    ln -s rw/var var
    cd $curdir
fi
echo "END"
