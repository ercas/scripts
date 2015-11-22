#!/bin/bash
# tool for managing the trashbin
# 
# originally a wrapper for gvfs-trash but can now function independent of it
# thanks to lizardthunder (https://github.com/lizardthunder). to use without
# gvfs-trash, specify -n.

# FIXME: trashing files on other volumes without gvfs-trash moves them to the
# local trash directory. they should be moved to the .Trash-1000 directory on
# the volume that they reside on.

########## defaults

shopt -s dotglob
verbose=false
usegvfs=true
trashdir="$([ -z "$XDG_DATA_HOME" ] && echo $HOME/.local/share || \
            echo "$XDG_DATA_HOME")/Trash"

mkdir -p $trashdir/{files,info,expunged}

########## helper functions

# from https://askubuntu.com/questions/53770/how-can-i-encode-and-decode-percent-encoded-strings-on-the-command-line/295312#295312
function urldecode() {
    echo "$1" | sed "s@+@ @g;s@%@\\\\x@g" | xargs -0 printf "%b"
}

########## functions

function trash() {
    file="$1"
    path="$(readlink -f $1)"
    num=1
    while true; do
        if [ -f "$trashdir/files/$file" ]; then
            file="$1.$num"
            num=$((num + 1))
        else
            break
        fi
    done
    mv "$1" "$trashdir/files/$file"
    cat <<EOF > "$trashdir/info/$file.trashinfo"
[Trash Info]
Path=$path
DeletionDate="$(date +%FT%T)"
EOF
}

function empty() {
    if $usegvfs; then
        gvfs-trash --empty
        $verbose && echo "emptied the trash for all mounted volumes"
    else
        # empty local trash
        cd $trashdir/files/ && remove *
        cd $trashdir/info/ && rm * 2>/dev/null
        $verbose && echo "emptied local trash"

        # empty trash for mounted volumes
        media=$([ -d /media/ ] && echo /media/$USER || \
            [ -d /run/media/ ] && echo /run/media/$USER)
        if ! [ -z $media ]; then
            for volume in $media/*; do
                cd "$volume/.Trash-1000/files" && remove *
                cd "$volume/.Trash-1000/info" && rm * 2>/dev/null
                $verbose && echo "emptied the trash for $volume"
            done
        else
            $verbose && echo "could not find media/ directory"
        fi
    fi
}

function remove() {
    [ "$@" = "*" ] && return
    for f in "$@"; do
        if [ -e "$f" ]; then
            rm -rf $($verbose && echo "-v") "$f"
            rm -f "$f.trashinfo"
        else
            echo "$f not found in the trash. use $(basename $0) -l to see all of the files in the trash."
        fi
    done
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

function usevolume() {
    ! [ -d "$1" ] && echo "\"$1\" is not a valid mountpoint." && exit 1
    if [ -d "$1/.Trash-1000" ]; then
        trashdir="$1/.Trash-1000"
    else
        echo "no trash directory found in \"$1\""
        exit 1
    fi
}

########## parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-v] [-DghlLR] [-d trashedfile] [-m mountpoint]
       [-r trashedfile] [filestotrash]
       -D                delete all files/empty the trash on all volumes
       -d trashedfile    delete/remove the specified file from the trash
       -h                display this message and exit
       -l                list files in the trash
       -L                list files in the trash with du in order to see sizes
       -m mountpoint     manipulate the trash on the specified volume
       -n                don't use gvfs-trash as the backend
       -R                restore all files from the trash
       -r trashedfile    restore the specified file from the trash
       -v                verbose mode

-d and -r can be used multiple times to delete or restore multiple files.
ex: $(basename $0) -r file1 -r file2 -d file3

all options except -d, -m, -r, and -v will make the script exit, and the options
are carried out in the order that they are specified. so, if you want verbosity,
make -v your first option. if you want to restore something and then empty the
trash in the same run, put -r before -D. if you want to list the contents of
the trash on an external drive, put -m before -l/-L.
EOF
}

while getopts ":Dd:hlLm:nRr:v" opt; do
    case $opt in
        D) empty; exit 0 ;;
        d) remove "$OPTARG" ;;
        h) usage; exit 0 ;;
        l) ls -a --ignore="\." --ignore="\.\." $trashdir/files; exit 0 ;;
        L) cd $trashdir/files; du -s *; exit 0 ;;
        m) usevolume "$OPTARG" ;;
        n) usegvfs=false ;;
        r) restore "$OPTARG" ;;
        R) restoreall; exit 0 ;;
        v) verbose=true ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## trash all other arguments

for f in "$@"; do
    if [ -e "$f" ]; then
        $usegvfs && gvfs-trash "$f" || trash "$f"
        $verbose && echo "trashed $f"
    else
        echo "$f does not exist"
    fi
done
