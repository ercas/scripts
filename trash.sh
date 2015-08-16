#!/bin/bash
# wrapper for gvfs-trash

########## defaults

verbose=false
trashdir="$([ -z "$XDG_DATA_HOME" ] && echo ~/.local/share || \
            echo "$XDG_DATA_HOME")/Trash"

########## helper functions

# from https://askubuntu.com/questions/53770/how-can-i-encode-and-decode-percent-encoded-strings-on-the-command-line/295312#295312
function urldecode() {
    echo "$1" | sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b"
}

########## functions

function empty() {
    $verbose && for f in $trashdir/files/*; do
        echo "removed $f"
    done
    gvfs-trash --empty
}

function restore() {
    if [ -e "$trashdir/files/$1" ]; then
        info="$trashdir/info/$1.trashinfo"
        mv $($verbose && echo "-v") "$trashdir/files/$1"\
        "$(urldecode "$(grep -oP "(?<=Path=).*" "$info")")"
        rm -f "$info"
    else
        echo "$1 not found in the trash. use $(basename $0) -l to see all of the files in the trash."
    fi
}

function restoreall() {
    for f in $trashdir/files/*; do
        restore "$(basename "$f")"
    done
}

function remove() {
    if [ -e "$trashdir/files/$1" ]; then
        rm -rf $($verbose && echo "-v") "$trashdir/files/$1"
        rm -f "$trashdir/info/$1.trashinfo"
    else
        echo "$1 not found in the trash. use $(basename $0) -l to see all of the files in the trash."
    fi
}

########## parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-DhlRv] [-d trashedfile] [-r trashedfile] [filestotrash]
       -D              delete all files/empty the trash
       -d trashedfile  delete/remove the specified file from the trash
       -h              display this message and exit
       -l              list items in the trash
       -R              restore all files from the trash
       -r trashedfile  restore the specified file from the trash
       -v              verbose mode
all options except -v will make the script exit. only do one thing at a time!
if nothing is specified, the script will simply trash all of the given files.
EOF
}

while getopts ":Dd:hlRr:v" opt; do
    case $opt in
        D) empty; exit 0 ;;
        d) remove "$OPTARG"; exit 0 ;;
        h) usage; exit 0 ;;
        l) ls $trashdir/files; exit 0 ;;
        r) restore "$OPTARG"; exit 0 ;;
        R) restoreall; exit 0 ;;
        v) verbose=true ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## if no options are selected, trash the given files

for f in "$@"; do
    gvfs-trash "$f"
    $verbose && echo "trashed $f"
done
