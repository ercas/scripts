#!/usr/bin/sh
# display man pages from the POSIX 1003.1 2013 edition manual, available at:
# http://pubs.opengroup.org/onlinepubs/9699919799/
# depends on w3m

posix_man_dir=~/Documents/posix_man_pages
man_page=$posix_man_dir/$1.html

# first time set up: download all man pages
if ! [ -d $posix_man_dir ]; then
    echo "could not find local posix manual directory; downloading now..."
    mkdir -p $posix_man_dir
    wget -qO - http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html | \
        grep -o utilities.*html | \
        sed -e "s|^|http://pubs.opengroup.org/onlinepubs/9699919799/|g" \
            -e "/contents/d" | \
        uniq | \
        xargs wget -P $posix_man_dir
fi

if [ -f $man_page ]; then
    w3m -dump -T text/html -cols $(tput cols) $man_page | less
else
    echo "no manual entry for $1"
fi
