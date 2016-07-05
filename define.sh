#!/bin/sh
# define a word by parsing the gutenberg copy of webster's unabridged dictionary
# https://www.gutenberg.org/ebooks/29765

dic=~/Documents/gutenberg-29765-webster.txt

function define_word() {
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

        else
            echo "$line"

            # provide context if a definition refers to another word
            # ex. "See Foo" "bar of Foo"
            if grep -qE "^Defn: (See|.*of [A-Z])" <<< "$line"; then
                # extract the last word in the line, ex. Foo, and define it
                context=$(grep -oE "[^ ]*$" <<< "$line" | tr -dc "[:alpha:]")
                define_word "$context" | sed "s/^/>> /g"
            fi

        fi

    done
}

[ -z "$1" ] && exit 1

# download a copy of the dictionary if necessary
if ! [ -f $dic ]; then
    echo -n "couldn't find the dictionary at the set path. download? (Y/n) "
    read ans
    if [ "${ans,,}" = "n" ]; then
        exit 1
    else
        wget -O $dic https://www.gutenberg.org/ebooks/29765.txt.utf-8
    fi
fi

# open in less if the definition's height is greater than the terminal's
defn=$(define_word "$1")
if [ $(wc -l <<< "$defn") -gt $(tput lines) ]; then
    less -r <<< "$defn"
else
    echo "$defn"
fi
