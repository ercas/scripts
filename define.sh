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

grep -ozP "^${1^^}\s*\$(\n|.)*?.*\n(?=[A-Z]{3})" $dic | head -n -1 | while read line; do
    if [ "${line^^}" = "$line" ] && echo $line | grep -qE "[[:alnum:]]"; then
        echo -e "\e[4m$line\e[m\n"
    else
        echo "$line"
    fi
done

#Word, v. t. [imp. & p. p. Worded; p. pr. & vb. n. Wording.] 25 columns
