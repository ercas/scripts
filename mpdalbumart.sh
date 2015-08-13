#!/bin/bash
# 
# depends: curl, meh
# 
# automatically fetch and display album art of mpd's currently playing song
# 
# temporary files will be stored as /tmp/albumart-*
# 

######### settings

noart="$(dirname "$(readlink -f "$0")")/mpdalbumart-noart.png"
musicdir=/mnt/Shared/music/
delay=2

######### setup

rgmbid="empty1"
lastrgmbid="empty2"
tempfile=

# hacky way of echoing info without polluting the main loop's pipe
logfile=/tmp/albumart-log
>$logfile
tail -F $logfile 2>/dev/null &

function log() {
    echo $@ >> $logfile
}

function quit() {
    rm -f /tmp/albumart*
    ps a | grep $logfile | while read p; do
        kill $(echo $p | awk '{printf $1}') 2>/dev/null
    done
    exit 0
}

########## main loop

trap quit SIGINT SIGTERM
while sleep $delay; do
    rgmbid="$(mediainfo "$musicdir$(mpc -f %file% | head -n 1)" | \
              grep MusicBrainz\ Release\ Group\ Id | awk '{printf $6}')"
    if ! [ "$rgmbid" = "$lastrgmbid" ]; then
        if ! [ -z $rgmbid ]; then
                arturl="$(curl -Ls coverartarchive.org/release-group/$rgmbid | \
                          grep -oP "(?<=small\":\").*250.jpg" | cut -d \" -f1)"
                if ! [ -z $arturl ]; then
                    log "cover art url found, changing image"
                    rm -f $tempfile
                    tempfile=$(mktemp -u /tmp/albumart-XXXXX)
                    curl -Lso $tempfile $arturl
                    if [ -f $tempfile ]; then
                        echo $tempfile
                    else
                        log "could not download image"
                        echo $noart
                    fi
                else
                    log "musicbrainz group release tag found but no art to fetch"
                    echo "$noart"
                fi
        else
            log "no musicbrainz group release tag found"
            echo "$noart"
        fi
    fi
    lastrgmbid=$rgmbid
done | meh -ctl