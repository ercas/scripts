#!/bin/bash
# sort files with the longest lines first

########## defaults

min=
max=
reverse=false
tmpprefix=$(mktemp -u /tmp/sortbylinelength-XXXXX)

########## parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-hr] file
       -h    display this message and exit
       -r    put the longest lines first instead of last
EOF
}

while getopts ":hr" opt; do
    case $opt in
        h) usage; exit 0 ;;
        r) reverse=true ;;
        ?) usage; exit 1 ;;
    esac
done

shift $(($OPTIND-1))

########## functions

function extremes() {
    for num in $@; do
        [ -z $min ] || [ $num -lt $min ] && min=$num
        [ -z $max ] || [ $num -gt $max ] && max=$num
    done
}

function quit() {
    rm -f /tmp/sortbylinelength-*
    exit 0
}

########## sort by line length

trap quit SIGINT SIGTERM

! [ -f "$1" ] && echo "\"$1\" is not a valid file." && exit 1

# i couldn't get the "while read line" block to set the min and max variables,
# so i had to resort to echoing each line length and having a function determine
# the min and max from the resulting string.

extremes $(cat $1 | while read line; do
    length=${#line}
    echo $line >> $tmpprefix-$length.temp
    echo $length
done)

for l in $(seq $(($max-$min+1))); do
    if $reverse; then
        f=$tmpprefix-$(($max+1-$l)).temp
    else
        f=$tmpprefix-$(($l+$min-1)).temp
    fi
    [ -f $f ] && cat $f
done

quit