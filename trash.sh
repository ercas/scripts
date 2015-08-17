#!/bin/bash
# wrapper for gvfs-trash

########## defaults

shopt -s dotglob
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
usage: $(basename $0) [-v ] [-DhlR] [-d trashedfile] [-r trashedfile] [filestotrash]
       -D              delete all files/empty the trash
       -d trashedfile  delete/remove the specified file from the trash
       -h              display this message and exit
       -l              list files in the trash
       -L              list items in the trash with du in order to see sizes
       -R              restore all files from the trash
       -r trashedfile  restore the specified file from the trash
       -v              verbose mode

-d and -r can be used multiple times to delete or restore multiple files.
ex: $(basename $0) -r file1 -r file2 -d file3

all options except -d, -r, and -v will make the script exit, and the options are
carried out in the order that they are specified. so, if you want verbosity,
make -v your first option. if you want to restore something and then empty the
trash in the same run, put -r before -D.
EOF
}

while getopts ":Dd:hlLRr:v" opt; do
    case $opt in
        D) empty; exit 0 ;;
        d) remove "$OPTARG" ;;
        h) usage; exit 0 ;;
        l) ls -a --ignore="\." --ignore="\.\." $trashdir/files; exit 0 ;;
        L) cd $trashdir/files; du *; exit 0 ;;
        r) restore "$OPTARG" ;;
        R) restoreall; exit 0 ;;
        v) verbose=true ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## trash everything after the arguments

for f in "$@"; do
    if [ -e "$f" ]; then
        gvfs-trash "$f"
        $verbose && echo "trashed $f"
    else
        echo "$f does not exist"
    fi
done
