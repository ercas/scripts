#!/bin/bash
# 
# depends: curl, ffmpeg, mediainfo, meh
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
delay=2
verbose=false

######### parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-Ahv] [-a artdir] [-d musicdir] [-n interval]
       -a artdir    specify what directory to store album art in
       -A           write cover art to the currently playing file
       -d musicdir  specify what directory mpd looks in for music
       -h           display this message and exit
       -n interval  specify how long to wait between each loop
       -v           verbose mode
EOF
}

while getopts ":Aa:d:hn:v" opt; do
    case $opt in
        A) addart=true ;;
        a) artdir="$OPTARG" ;;
        d) musicdir="$OPTARG" ;;
        h) usage; exit 0 ;;
        n) delay="$OPTARG" ;;
        v) verbose=true ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

######### setup

rgmbid="empty"
lastalbum="empty"
lastsong="empty"
tempfile=

# my text editor's syntax highlighting freaks out if i put this near optargs
musicdir="$(readlink -f "$musicdir")"

! [ -z "$artdir" ] && mkdir -p "$artdir"

# hacky way of echoing info without polluting the main loop's pipe
logfile=/tmp/albumart-log
$verbose && >$logfile && tail -F $logfile 2>/dev/null &

########## functions

function ffmpeg-addart() {
    ffmpeg -i "$1" -i "$2" -map 0:0 -map 1:0 -c copy \
    -metadata:s:v title="Cover art" -loglevel quiet "$3"
}

function log() {
    $verbose && echo $@ >> $logfile
}

function quit() {
    rm -f /tmp/albumart*
    $verbose && ps a | grep $logfile | while read p; do
        kill $(echo $p | awk '{printf $1}') 2>/dev/null
    done
    exit 0
}

########## main loop

trap quit SIGINT SIGTERM
while sleep $delay; do
    currentsong="$musicdir/$(mpc -f %file% | head -n 1)"
    currentalbum="$(mediainfo "$currentsong" | grep Album\ \ | cut -d ":" -f2 | tail -c +2)"
    if ! [ "$currentalbum" = "$lastalbum" ]; then
        rm -f tempfile
        tempfile=$(mktemp -u /tmp/albumart-XXXXX)
        
        ffmpeg -i "$currentsong" -loglevel quiet $tempfile.jpg
        mv $tempfile.jpg $tempfile 2>/dev/null
        if [ -f $tempfile ]; then
            log "using embedded cover art"
            echo $tempfile
        else
            log "no embedded cover art, attempting to search in cover art directory"
            currentperformer="$(mediainfo "$currentsong" | grep Performer\ \ | head -n 1 | cut -d ":" -f2 | tail -c +2)"
            albumhash="$(echo "$currentperformer - $currentalbum" | md5sum | awk '{printf $1}')"
            if [ -f "$artdir/$albumhash" ]; then
                log "using album art from cover art directory"
                cp "$artdir/$albumhash" $tempfile
                echo $tempfile
            else
                log "album not found in cover art directory, attemtping to fetch musicbrainz copy"
                rgmbid="$(mediainfo "$currentsong" | grep MusicBrainz\ Release\ Group\ Id | awk '{printf $6}')"
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
                        else
                            log "could not download image"
                            echo $noart
                        fi
                    else
                        log "musicbrainz release group found but no art to fetch"
                        echo "$noart"
                    fi
                else
                    log "no musicbrainz release group found"
                    echo "$noart"
                fi
            fi
        fi
        
        
    fi
    if ! [ "$currentsong" = "$lastsong" ] && $addart && [ -f $tempfile ]\
        && [ -z "$(mediainfo "$currentsong" | grep Cover\ \ .*\ Yes)" ]; then
        log "writing album art to music file"
        tempmusicfile="${currentsong%.mp3}-withart.mp3"
        ffmpeg-addart "$currentsong" $tempfile "$tempmusicfile"
        mv "$tempmusicfile" "$currentsong"
    fi
    lastalbum="$currentalbum"
    lastsong="$currentsong"
done | meh -ctl