#!/bin/bash
# remove duplicates in the current directory or the specified directory (if any)

######### defaults

cmd=gvfs-trash
verbose=true

######### parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-hs] [-c command] [directory]
if directory is not specified, the current directory will be scanned.
       -h           display this message
       -s           silent mode
       -c command   specify what command to use to remove files (default $cmd)
EOF
}
while getopts ":hc:s" opt; do
    case $opt in
        h) usage; exit 0 ;;
        c) cmd="$OPTARG" ;;
        s) verbose=false ;;
        ?) usage; exit 1 ;;
    esac
done
shift $((OPTIND-1))

########## functions

# only output if verbose is true
function output() {
    $verbose && echo $@
}

function quit() {
    output "removed $removed file$( [ $removed == 1 ] || echo s)"
    exit 0
}

########## setup

cmd=$(command -v ${cmd%% *} >/dev/null && echo $cmd || echo rm)
output "using $cmd"
cd "$(test -z "$1" && echo . || echo "$1")"
output "checking for duplicates in $(pwd)"

######### remove duplicates

removed=0
trap quit SIGINT SIGTERM
for selected in *; do
    if [ -f "$selected" ]; then
        output "checking for duplicates of $selected"
        for compare in *; do
            if [ -f "$compare" ]; then
                if $(cmp -s "$selected" "$compare") && ! [ "$(readlink -f "$selected")" == "$(readlink -f "$compare")" ]; then
                    output "$compare is a duplicate of $selected, removing"
                    $cmd "$compare"
                    removed=$((removed+1))
                fi
            fi
        done
    elif [ -d "$selected" ]; then
        output "$selected is a directory, skipping"
    else
        output "$selected no longer exists, skipping"
    fi
done

quit
