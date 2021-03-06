#!/bin/bash
# 
# depends: curl, ffmpeg, mediainfo, meh, mpc
# 
# automatically fetch and display album art of mpd's currently playing song
# 
# process:
# if -a and -c are specified, cache the art and exit
# for every new album that plays, attempt to load the cover art from:
# * embedded art in the music files
# * art cached my mpdalbumart.sh
# * musicbrainz/archive.org cover art archive
# * slothradio/amazon
# if nothing is found, display mpdalbumart-noart.png
# if something is found and -a is specified, cache the art
# 
# be polite to the people at musicbrainz and the internet archive! specify a
# directory to cache cover art in with -a if you don't like storing images in
# your music files (i personally don't). this will limit the load on the
# coverartarchive.org servers and make art load faster.
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

# accepts either a url or a path to an image file
# returns 1 if the given url or path is invalid
function cacheart() {
    if ! [ -d "$artdir" ]; then
        if [ -z "$artdir" ]; then
            log "no art cache directory specified. not caching art."
        else
            log "\"$artdir\" is not a valid directory. not caching art."
        fi
        return 1
    fi
    
    tempart=$(mktemp -u /tmp/albumart-XXXXX)
    
    if echo "$1" | grep -q ^http; then
        curl -o $tempart "$1"
    else
        if [ -f "$1" ]; then
            cp "$1" $tempart
        else
            log "\"$1\" does not exist."
            return 1
        fi
    fi
    
    if file $tempart | grep -q "image data"; then
        getinfo
        cp $tempart "$artdir/$albumhash"
        log "cached \"$1\" to \"$artdir/$albumhash\""
    else
        log "\"$1\" is not a valid image."
        return 1
    fi

    rm $tempart
}

# add art to an mp3 file
# currently broken
function ffmpeg-addart() {
    ffmpeg -i "$1" -i "$2" -map 0:0 -map 1:0 -c copy \
    -metadata:s:v title="Cover art" -loglevel quiet "$3"
}

# main function to try to get art to display
# handlers are separated by empty lines and return if successful
function getart() {
    rm -f $tempfile
    tempfile=$(mktemp -u /tmp/albumart-XXXXX)
    
    log "attempting to use embedded cover art"
    ffmpeg -i "$currentsong" -loglevel quiet $tempfile.jpg
    mv $tempfile.jpg $tempfile 2>/dev/null
    if [ -f $tempfile ]; then
        log "using embedded cover art"
        echo $tempfile
        return
    fi
    
    log "attempting to search in cover art directory"
    if [ -f "$artdir/$albumhash" ]; then
        log "using album art from cover art directory"
        cp "$artdir/$albumhash" $tempfile
        echo $tempfile
        return
    fi
    
    log "** switching to internet sources **"
    
    log "attempting to fetch musicbrainz copy"
    if ! [ -z $rgmbid ]; then
        log "-> musicbrainz release group tag found"
        arturl="$(curl -Ls coverartarchive.org/release-group/$rgmbid | grep -oP "(?<=small\":\").*250.jpg" | cut -d \" -f1)"
        if ! [ -z $arturl ]; then
            log "-> cover art url found, downloading image"
            tempfile=$(mktemp -u /tmp/albumart-XXXXX)
            curl -Lso $tempfile $arturl
            if [ -f $tempfile ]; then
                echo $tempfile
                cacheart "$tempfile"
                return
            else
                log "-> could not download image"
            fi
        else
            log "-> no art to fetch"
        fi
    else
        log "-> no musicbrainz release group tag found"
    fi
    
    log "attempting to fetch slothradio/amazon copy"
    tempfile=$(mktemp -u /tmp/albumart-XXXXX)
    curl -so $tempfile "$(curl -s "http://www.slothradio.com/covers/index.php?adv=&artist=$(echo "$currentperformer" | tr " " "+")&album=$(echo "$currentalbum" | tr " " "+")" | \
        grep -o http://ecx.images-amazon.com.*jpg | head -n 1)"
    if [ -f $tempfile ]; then
        echo $tempfile
        cacheart "$tempfile"
        return
    fi
    
    # add more cover art fetch attempts here
    
    log "could not fetch art"
    echo "$noart"
}

# update global variables for song information
function getinfo() {
    currentsong="$musicdir/$(mpc -f %file% | head -n 1)"
    info="$(mediainfo "$currentsong")"

    currentalbum="$(echo "$info" | grep Album\ \ | cut -d ":" -f2 | tail -c +2)"
    currentperformer="$(echo "$info" | grep Performer\ \ | head -n 1 | cut -d ":" -f2 | tail -c +2)"
    rgmbid="$(echo "$info" | grep MusicBrainz\ Release\ Group\ Id | awk '{printf $6}')"
    
    albumhash="$(echo "$currentperformer - $currentalbum" | md5sum | awk '{printf $1}')"
}

function log() {
    $verbose && echo "$@" >&2
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
                      cached art. albumart can either be a path to an image
                      file or the url of one.
       -d musicdir    specify what directory mpd looks in for music
       -h             display this message and exit
       -v             verbose mode; log activity to stderr
EOF
}

while getopts ":a:c:d:hv" opt; do
    case $opt in
        a) artdir="$OPTARG" ;;
        c) verbose=true; cacheart "$OPTARG"; exit 0 ;;
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
    
    log
    log "new album: $currentalbum"
    
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
