#!/bin/sh

JAIL_BASE=$1 # TODO Make validation
SRCCONF=`readlink -f etc/src.conf`
echo Create base in ${JAIL_BASE}
if [ -d "${JAIL_BASE}" ]; then
	echo "${JAIL_BASE} already exists. Exiting" 
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
echo "END"
