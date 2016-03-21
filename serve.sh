#!/bin/sh
# quick wrapper script for a docker lighttpd container to serve a given
# directory, will eventually clean up in the future
#
# usage: ./serve.sh DIRECTORY [CONFIGFILE]
#
# if no CONFIGFILE is specified, the script will attempt to use serve.sh.conf in
# the same directory as the script

[ -z "$1" ] && echo "error: no directory supplied" && exit
[ -z "$2" ] && config="$(dirname $(readlink -f $0))/serve.sh.conf" || config="$2"
! [ -f "$config" ] && echo "error: could not find $(dirname $(readlink -f $0))/serve.sh.conf" && exit

docker run -d \
    -p 80:80 \
    -v "$(readlink -f "$1")":/var/www/localhost/htdocs/:ro \
    -v "$config":/etc/lighttpd/lighttpd.conf:ro \
    ercas/lighttpd-fastcgi-bash
