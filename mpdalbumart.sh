#!/bin/bash
# 
# depends: curl, ffmpeg, mediainfo, meh, mpc
# 
# automatically fetch and display album art of mpd's currently playing song
# 
# process:
# if new album, look for embedded album art
# ├─success: display embedded album art
# └─fail: attempt to find album art in cover art directory (if specified)
#   ├─success: display album art from cover art directory
#   └─fail: look for musicbrainz release group tag
#     ├─success: attempt to get the url for the "small" image
#     │ ├─success: attempt to download the "small" image
#     │ │ ├─success: display the "small" image
#     │ │ │ └─if cover art directory is specified, copy the image to it
#     │ │ └─fail: display the "noart" image
#     │ └─fail: display the "noart" image
#     └─fail: display the "noart" image
# if new song and if the -A option is used, write the cover art, if any, to the 
# music file
# 
# be polite to the people at musicbrainz and the internet archive! write cover
# art to your music files with -A or specify a directory to cache cover art in
# with -a if you don't like storing images in your music files (i personally
# don't). this will limit the load on the coverartarchive.org servers. you can
# also specify both, of course.
# 
# temporary files will be stored as /tmp/albumart-*
# 

######### defaults

noart="$(dirname "$(readlink -f "$0")")/mpdalbumart-noart.png"
artdir=
addart=false
musicdir=/mnt/Shared/music/
verbose=false

######### setup

currentsong=
currentalbum=
currentperformer=
rgmbid="empty"
lastalbum="empty"
lastsong="empty"
tempfile=

# my text editor's syntax highlighting freaks out if i put this near optargs
musicdir="$(readlink -f "$musicdir")"

! [ -z "$artdir" ] && mkdir -p "$artdir"

########## functions

function addart() {
    ! [ -f "$1" ] && echo "\"$1\" does not exist." && exit 1
    albumhash="$(echo "$currentperformer - $currentalbum" | md5sum | awk '{printf $1}')"
    cp -v "$1" "$artdir/$albumhash"
}

function ffmpeg-addart() {
    ffmpeg -i "$1" -i "$2" -map 0:0 -map 1:0 -c copy \
    -metadata:s:v title="Cover art" -loglevel quiet "$3"
}

function getart() {
    rm -f $tempfile
    tempfile=$(mktemp -u /tmp/albumart-XXXXX)
    
    ffmpeg -i "$currentsong" -loglevel quiet $tempfile.jpg
    mv $tempfile.jpg $tempfile 2>/dev/null
    if [ -f $tempfile ]; then
        log "using embedded cover art"
        echo $tempfile
        return
    fi
    
    log "no embedded cover art, attempting to search in cover art directory"
    if [ -f "$artdir/$albumhash" ]; then
        log "using album art from cover art directory"
        cp "$artdir/$albumhash" $tempfile
        echo $tempfile
        return
    fi
    
    log "album $albumhash not found in cover art directory, attempting to fetch musicbrainz copy"
    if ! [ -z $rgmbid ]; then
        log "musicbrainz release group found"
        arturl="$(curl -Ls coverartarchive.org/release-group/$rgmbid | grep -oP "(?<=small\":\").*250.jpg" | cut -d \" -f1)"
        if ! [ -z $arturl ]; then
            log "cover art url found, downloading image"
            tempfile=$(mktemp -u /tmp/albumart-XXXXX)
            curl -Lso $tempfile $arturl
            if [ -f $tempfile ]; then
                echo $tempfile
                if [ -d "$artdir" ]; then
                    log "copying album art to cover art directory"
                    cp $tempfile "$artdir/$albumhash"
                fi
                return
            else
                log "could not download image"
            fi
        else
            log "musicbrainz release group found but no art to fetch"
        fi
    fi

    echo "$noart"
}

function getinfo() {
    currentsong="$musicdir/$(mpc -f %file% | head -n 1)"
    info="$(mediainfo "$currentsong")"

    currentalbum="$(echo "$info" | grep Album\ \ | cut -d ":" -f2 | tail -c +2)"
    currentperformer="$(echo "$info" | grep Performer\ \ | head -n 1 | cut -d ":" -f2 | tail -c +2)"
    rgmbid="$(echo "$info" | grep MusicBrainz\ Release\ Group\ Id | awk '{printf $6}')"
    
    albumhash="$(echo "$currentperformer - $currentalbum" | md5sum | awk '{printf $1}')"
}

function log() {
    $verbose && echo $@ >&2
}

function quit() {
    rm -f /tmp/albumart*
    exit 0
}

######### parse options

function usage() {
    cat <<EOF
usage: $(basename "$0") [-hv] [-a artdir] [-d musicdir] [-u albumart]
       -a artdir      specify what directory to cache album art in
       -c albumart    cache the specified albumart. -a must be specified before
                      using this. embedded art will still have priority over
                      cached art.
       -d musicdir    specify what directory mpd looks in for music
       -h             display this message and exit
       -v             verbose mode; log activity to stderr
EOF
}

while getopts ":a:c:d:hv" opt; do
    case $opt in
        a) artdir="$OPTARG" ;;
        c) addart "$OPTARG"; exit 0 ;;
        d) musicdir="$OPTARG" ;;
        h) usage; exit 0 ;;
        v) verbose=true ;;
        ?) usage; exit 1 ;;
    esac
done

shift $(($OPTIND-1))

########## main loop

trap quit SIGINT SIGTERM
while true :; do
    
    # refresh song information variables
    getinfo

    if ! [ "$currentalbum" = "$lastalbum" ]; then
        getart
    fi

    # disabled for now
    if ! [ "$currentsong" = "$lastsong" ] && $addart && [ -f $tempfile ]\
        && [ -z "$(mediainfo "$currentsong" | grep Cover\ \ .*\ Yes)" ]; then
        log "writing album art to music file"
        tempmusicfile="${currentsong%.mp3}-withart.mp3"
        ffmpeg-addart "$currentsong" $tempfile "$tempmusicfile"
        mv "$tempmusicfile" "$currentsong"
    fi

    lastalbum="$currentalbum"
    lastsong="$currentsong"

    mpc idle player >/dev/null

done | meh -ctl
