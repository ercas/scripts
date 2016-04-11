#!/usr/bin/sh
# display man pages from the freebsd 11 manual, available at:
# http://www.unix.com/man-page-freebsd-repository.php
# depends on w3m

freebsd_man_dir=~/Documents/freebsd_man_pages
man_page=$freebsd_man_dir/$1.html

# first time set up: download all man pages
if ! [ -d $freebsd_man_dir ]; then
    echo "could not find local freebsd manual directory; downloading now..."
    mkdir -p $freebsd_man_dir
    wget -qO - http://www.unix.com/man-page-freebsd-repository.php | \
        grep -oP "http://www.unix.com/man-page/freebsd/1/.*?/" | \
        while read url; do
            wget -O $freebsd_man_dir/$(cut -d "/" -f 7 <<< $url).html $url
        done
fi

if [ -f $man_page ]; then
    sed -n "/<pre>/,/<\/pre>/p" $man_page | \
        w3m -dump -T text/html | \
        less
else
    echo "no manual entry for $1"
fi
