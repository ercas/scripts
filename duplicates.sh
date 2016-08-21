#!/usr/bin/sh
# find duplicate files by comparing md5 checksum

keep_first=true
find_args="-maxdepth 1"
remove=false
remove_cmd=gvfs-trash
searchdir=$(pwd)
verbose=false

########## parse options

this=$(basename "$0")

function usage() {
    cat <<EOF
usage: $this [-dhflrv] [-c cmd] [searchdir]
       -c cmd       use this command to remove files in delete mode (default is
                      gvfs-trash; defaults to rm if the command is unavailable)
       -d           delete mode
       -h           view this message and exit
       -f           in delete mode, delete all but the first file (default)
       -l           in delete mode, delete all but the last file
       -r           recursive
       -v           verbose mode
       searchdir    the directory to search in (default is current directory)

by default, $this will only print all repeated checksums and the files that
share them; nothing else is done.
EOF
}

while getopts ":c:dhflrv" opt; do
    case $opt in
        c) remove_cmd="$OPTARG" ;;
        d) remove=true ;;
        h) usage; exit 0 ;;
        f) keep_first=true ;;
        l) keep_first=false ;;
        r) find_args="" ;;
        v) verbose=true ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## main

# stand-in for echo that only runs if $verbose is true and prints to stderr
function log() {
    $verbose && echo "$@" >& 2
}

# check if searchdir exists
if ! [ -z "$1" ]; then
    if [ -d "$1" ]; then
        searchdir="$1"
    else
        echo "error: \"$1\" is not a directory."
        exit 1
    fi
fi

# check if remove_cmd is available if in remove mode
base_cmd=$(echo "$remove_cmd" | cut -d " " -f 1)
if ! command -v $base_cmd > /dev/null && $remove; then
    echo "error: $base_cmd is not available; using rm" >& 2
    remove_cmd=rm
fi

# calculate checksums
$verbose && echo "finding files and calculating md5 checksums..." >& 2
sums=$(find "$searchdir" $find_args -type f | \
    sort | tr "\n" "\0" | xargs -0 md5sum | \
    tee $($verbose && echo /dev/fd/2 || echo /dev/null))

# find duplicates
$verbose && echo "finding duplicates..." >& 2
cut -d " " -f 1 <<< "$sums" | sort | uniq -d | while read repeated_hash; do

    # print hashes if verbose and removing things or if not removing anything
    (! $remove || $verbose) && echo ">> repeated hash: $repeated_hash"

    duplicates=$(grep $repeated_hash <<< "$sums" | cut -d " " -f 3- | sort)
    if $remove; then

        # create a list of stuff to remove
        if $keep_first; then
            to_remove=$(tail -n +2 <<< "$duplicates")
            $verbose && echo "keeping $(head -n 1 <<< "$duplicates")"
        else
            to_remove=$(head -n -2 <<< "$duplicates")
            $verbose && echo "keeping $(tail -n 1 <<< "$duplicates")"
        fi

        # remove the stuff
        echo "$to_remove" | while read file; do
            $verbose && echo "removing $file"
            $remove_cmd "$file"
        done

    else
        echo "$duplicates"
    fi
done
