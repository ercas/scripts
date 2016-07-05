#!/bin/sh
# define a word by parsing the gutenberg copy of webster's unabridged dictionary
# https://www.gutenberg.org/ebooks/29765

dic=~/Documents/gutenberg-29765-webster.txt

[ -z "$1" ] && exit 1

if ! [ -f $dic ]; then
    echo -n "couldn't find the dictionary at the set path. download? (Y/n) "
    read ans
    if [ "${ans,,}" = "n" ]; then
        exit 1
    else
        wget -O $dic https://www.gutenberg.org/ebooks/29765.txt.utf-8
    fi
fi

# assuming that definitions are not longer than 100 lines
grep -A 100 "^${1^^}\s*$" $dic | while read line; do

    # if this line is all caps
    if [ "${line^^}" = "$line" ] && grep -qE "[[:alnum:]]" <<< "$line"; then

        # if this line is the queried word, underline it
        if [ "$(tr -dc "[:alnum:]" <<< "$line")" = "${1^^}" ]; then
            echo -e "\e[4m$line\e[m\n"

        # if it's not, then it's the next word in the dictionary
        else
            break
        fi

    # write all other lines normally
    else
        echo "$line"
    fi

done

