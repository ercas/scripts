#!/bin/bash
# note: this script is extremely disk i/o intensive. it was designed to be run
# on an external drive, and will be quicker and less taxing on the system i/o if
# it is run on one.

cd "$(dirname "$0")"

########## setup

rm -rf cache/*

archivedir=pool
cachedir=cache
resultdir=searchresults

verbose=false
very_verbose="" # this is passed as an argument; set as "-v" for verbosity

# wrapper for echo that only runs if $verbose is true
function log() {
    $verbose && echo -ne "\n> $@"
}

# exit if the given directory does not exist
function chkdir() {
    if ! [ -d "$1" ]; then
        echo "error: \"$1\" is not a valid directory."
        echo "note: paths are relative to $(pwd)."
        exit 1
    fi
}

########## parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-vV] [-a archivedir] [-c cachedir] [-r resultdir] regex..
       -a archivedir    directory containing tarballs of text files to search
       -c cachedir      directory to temporarily unpack tarballs to
       -r resultdir     directory to copy results to
       -v               verbose mode (summary of what's being done)
       -V               very verbose mode (-v option passed to all commands);
                          also triggers -v
       regex            a regular expression that will be used by GNU grep -rliE
archivedir, cachedir, and resultdir are relative to the directory that this
script is in.

default behavior is $(basename $0) -a pool -c cache -r searchresults

WARNING: $(basename $0) is very i/o intensive. for every tarball found in
archivedir:
1. each tarball is unpacked into cachedir
2. each regular expression is passed to grep -rliE one by one to find matches
    in cachedir
3. all matches are copied to resultdir
for this reason, it is suggested that either this script is run on an external
disk so that it can set up those directories on that disk, or that you manually
create those directories on an external disk and then specify them with -a, -c,
and -r. additionally, cachedir and resultdir should be on a disk that will not
be heavily damaged by repeated overwriting.

suggested setup:
/run/media/external_disk/tarball-searcher/
/run/media/external_disk/tarball-searcher/pool/
/run/media/external_disk/tarball-searcher/cache/
/run/media/external_disk/tarball-searcher/searchresults/
/run/media/external_disk/tarball-searcher/tarball-searcher.sh
EOF
}

while getopts ":a:c:hr:vV" opt; do
    case $opt in
        a) chkdir "$OPTARG" && archivedir="$OPTARG" ;;
        c) chkdir "$OPTARG" && cachedir="$OPTARG" ;;
        h) usage; exit 0 ;;
        r) chkdir "$OPTARG" && resultdir="$OPTARG" ;;
        v) verbose=true ;;
        V) verbose=true; very_verbose="-v" ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## first time setup with default directories

if ([ "$cache" = "cache" ] && ! [ -d "$cache" ]) || \
   ([ "$resultdir" = "searchresults" ] && ! [ -d "$resultdir" ]); then
    echo -n "set up default environment in \"$(pwd)\"? (Y/n) "
    read ans
    if ! [ ${ans,,} = "n" ]; then
        mkdir "$cachedir" "$resultdir"
    else
        echo "please move this script into the directory you want it to set up in."
        echo "alternatively, specify -c and -r."
        echo "see $(basename $0) -h for more info."
        exit 1
    fi
fi

########## search

# this should only fail if
if ! [ -d "$archivedir" ]; then
    echo "error: default tarball directory ./$archivedir/ does not exist."
    echo "please create it or specify one with -a."
    echo "see $(basename $0) -h for more info."
    exit 1
fi

tosearch=$(find "$archivedir" -type f -name '*tar*' | wc -l)
searched=0
strings=0

if [ $tosearch = "0" ]; then
    echo "error: no tarballs found in \"$archivedir\"."
    exit 1
fi

trap "echo -e \"\ncleaning up...\"; rm -rf $cachedir/*; exit" SIGINT SIGTERM

# create subdirectores in $resultdir/ to store individual queries in
for query in "$@"; do
    mkdir $very_verbose -p "$resultdir/$(echo $query | tr -c "[:alnum:] \n" _)"
    strings=$((strings+1))
done

find $archivedir -type f -name '*.tar*' | while read archive; do

    # status
    plural_s=$([ $strings -eq 1 ] || echo s)
    search_percentage=$(echo "scale=2; $searched*100/$tosearch" | bc)
    echo -en "\rsearching for $strings string$plural_s in $tosearch archives... $searched/$tosearch ($search_percentage%)"

    log "unpacking $archive ($(du -sh $archive | awk '{printf $1}')) to $cachedir/..."
    tar $very_verbose -xf $archive -C $cachedir/

    for query in "$@"; do
        log "searching for \"$query\"..."

        querydir="$(echo $query | tr -c "[:alnum:] \n" _)"

        grep -rliE "$query" $cachedir | while read result; do
            #archivename=${archive%.tar*}
            #archivename="$(basename "$archivename")"
            archivename=$(sed \
                -e "s|./pool/||g" \
                -e "s|\.tar.*||g" \
                -e "s|/|_|g" \
                <<< $archive)
            cp $very_verbose $result "$resultdir/$querydir/$archivename-${result##*/}"
        done

    done

    log "clearing cache..."
    rm $very_verbose -rf $cachedir/*
    searched=$((searched+1))

done

echo
