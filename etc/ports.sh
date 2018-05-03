#!/bin/sh

#setenv DESTDIR_MOUNT_LIST "PORTSDIR:/usr/ports:/usr/ports WRKDIRPREFIX:/tmp/ports.build:/tmp/ports.build"
setenv DESTDIR_MOUNT_LIST "PORTSDIR:/usr/ports:/usr/ports"
setenv PREFIX "/usr/global"
setenv LOCALBASE "/usr/global"
setenv DESTDIR_ENV_LIST "PREFIX LOCALBASE"

