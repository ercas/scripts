#!/bin/bash
# 
# depends: curl, ffmpeg, mediainfo, meh
# 
# automatically fetch and display album art of mpd's currently playing song
# 
# process:
# look for embedded album art
# ├─success: display embedded album art
# └─fail: attempt to find album art in cover art directory (if specified)
#   ├─success: display album art from cover art directory
#   └─fail: look for musicbrainz group release id tag
#     ├─success: attempt to get the url for the "small" image
#     │ ├─success: attempt to download the "small" image
#     │ │ ├─success: display the "small" image
#     │ │ │ └─if cover art directory is specified, copy the image to it
#     │ │ └─fail: display the "noart" image
#     │ └─fail: display the "noart" image
#     └─fail: display the "noart" image
# 
# temporary files will be stored as /tmp/albumart-*
# 

######### defaults

noart="$(dirname "$(readlink -f "$0")")/mpdalbumart-noart.png"
artdir=
musicdir=/mnt/Shared/music/
delay=2
verbose=false

######### parse options

function usage() {
    cat <<EOF
usage: $(basename $0) [-h] [-a artdir] [-d musicdir] [-n interval]
       -a artdir    specify what directory to store album art in
       -d musicdir  specify what directory mpd looks in for music
       -h           display this message and exit
       -n interval  specify how long to wait between each loop
       -v           verbose mode
EOF
}

while getopts ":a:d:hn:v" opt; do
    case $opt in
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
tempfile=

! [ -z "$artdir" ] && mkdir -p "$artdir"

# hacky way of echoing info without polluting the main loop's pipe
logfile=/tmp/albumart-log
$verbose && >$logfile && tail -F $logfile 2>/dev/null &

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
    currentsong="$musicdir$(mpc -f %file% | head -n 1)"
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
                    log "musicbrainz group release found"
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
                        log "musicbrainz group release found but no art to fetch"
                        echo "$noart"
                    fi
                else
                    log "no musicbrainz group release found"
                    echo "$noart"
                fi
            fi
        fi
        
        
    fi
    lastalbum="$currentalbum"
done | meh -ctl