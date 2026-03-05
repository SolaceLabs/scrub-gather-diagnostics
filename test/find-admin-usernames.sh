#!/bin/bash

# Very simple script to find some admin usernames from the command log,
# event log, and system log. Run it from the "logs" directory on the broker,
# or extract the GD tarball and goto the usr/sw/jail/logs directory and run
# from there.
# This was just made for my testing/development... hopefully you can pull
# a complete list of your usernames from LDAP or something.


(grep SYSTEM_AUTHENTICATION_SESSION_OPENED event.log* | perl -lane ' s/CLI/ print $F[17] /e; s/SEMP/ print $F[16] /e; ';
 grep SYSTEM_AUTHENTICATION_SHELL_ACCESS_GRANTED system.log* | perl -lane ' s/CLI/ print substr($F[10],1,-1) /e; ';
 cat command.log | grep -v 'msgbus ' | grep -v 'SHELL ' | perl -lane ' print $F[6]; ') | sort -u

