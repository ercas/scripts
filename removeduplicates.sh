#!/bin/bash
# remove duplicates in the current directory or the specified directory (if any)

######### defaults

cmd=gvfs-trash
verbose=true
recursive=false

######### parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-hrs] [-c command] [directory]
if directory is not specified, the current directory will be scanned.
       -h           display this message
       -s           silent mode
       -c command   specify what command to use to remove files (default $cmd)
EOF
}
while getopts ":hrsc:" opt; do
    case $opt in
        h) usage; exit 0 ;;
        r) recursive=true ;;
        s) verbose=false ;;
        c) cmd="$OPTARG" ;;
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
removed=0
trap quit SIGINT SIGTERM

######### remove duplicates

output "using $cmd"
function removeduplicates() {
    cd "$1"
    output "changed directory to $(pwd)"
    for selected in *; do
        if [ -f "$selected" ]; then
            output "checking for duplicates of $selected"
            selected_fullname="$(readlink -f "$selected")"
            for compare in *; do
                if [ -f "$compare" ]; then
                    if $(cmp -s "$selected" "$compare") && ! [ "$selected_fullname" == "$(readlink -f "$compare")" ]; then
                        output "$compare is a duplicate of $selected, removing"
                        $cmd "$compare"
                        removed=$((removed+1))
                    fi
                fi
            done
        elif [ -d "$selected" ]; then
            if $recursive; then
                removeduplicates "$selected"
                cd ..
                output "changed directory back to $(pwd)"
            else
                output "$selected is a directory, skipping"
            fi
        else
            output "$selected no longer exists, skipping"
        fi
    done
}

removeduplicates "$(test -z "$1" && echo . || echo "$1")"

quit
