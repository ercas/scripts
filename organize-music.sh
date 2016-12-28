#!/bin/sh
# automatically extract, convert, and organize music
# depends: mediainfo, unzip, unrar, 7za (may be named 7z on your system)
# optional: picard, gvfs-trash

# USAGE:
# 1. create a new directory
# 2. move or copy all files that need to be organized into that directory
# 3. create a subdirectory called "music" in that directory
# 4. copy this script into that directory
# 5. run this script

formats_to_keep="mp3|ogg|opus"
formats_to_convert="flac|m4a|mp4|wav"
convert_to="opus"

# use gvfs-trash over rm if possible
remove=$(command -v gvfs-trash || echo rm -rfv)

# use gnu parallel if possible
useparallel=false
if parallel --version | grep -q "GNU parallel"; then
    useparallel=true
fi

cd "$(dirname "$0")"

# create destination folder if it doesn't exist
mkdir -p music

# extract archives
if $useparallel; then
    parallel unzip -n "{}" ::: *.zip
    parallel unrar x -o- "{}" ::: *.rar
    parallel 7za x "{}" ::: *.7z
else
    for f in *.zip; do
        unzip -n "$f"
    done
    for f in *.rar; do
        unrar x -o- "$f"
    done
    for f in *.7z; do
        7za x "$f"
    done
fi
$remove *.{zip,rar,7z}

# move everything to the temporary directory
find . -not -path "./music/*" | grep -E "\.(${formats_to_convert}|${formats_to_keep})$" | while read f; do
    mv "$f" music/
done

# convert if necessary
if find music -type f | grep -qE "\.(flac|ogg|wav|m4a)"; then
    if $useparallel; then
        find music/ -type f | grep -E "\.(${formats_to_convert})$" | parallel 'f={}; yes | ffmpeg -i "$f" "${f%.*}.'$convert_to'" && '$remove' "$f"'
    else
        find music/ -type f | grep -E "\.(${formats_to_convert})$" | while read f; do
            yes | ffmpeg -i "$f" "${f%.*}.$convert_to"
            $remove "$f"
        done
    fi
fi

# clean up
find . -not -path './music*' -not -path './*.sh' -not -path . -exec $remove "{}" \;
find . -name ".*" -not -path . -exec $remove "{}" \;

# get tags
echo -e "\n\nnow opening picard so tags can be updated.\nwhen finished, close picard."
picard ./music/

# rename and organize music files
function move() {
    function extract() {
        echo "$info" | grep "$1" | head -n 1 | cut -d ":" -f2 | cut -c2- | tr "/?<>\\:*|\0" _
    }
    info="$(mediainfo "$1")"
    trackname="$(extract "Track\ name")"
    tracknumber="$(extract "Track name/Position")"
    album="$(extract "Album")"
    artist="$(extract "ARTISTS")"
    if [ -z "$artist" ]; then
        artist="$(extract "Album/Performer")"
    fi
    if [ -z "$artist" ]; then
        artist="$(extract "Performer")"
    fi

    if [ -z "$trackname" ] || [ -z "$tracknumber" ] || [ -z "$artist" ] || [ -z "$album" ]; then
        echo "skipping $1 (incomplete tags)"
    else

        # prepend zero to the track number if needed
        if ! [ ${#tracknumber} = "2" ]; then
            tracknumber=0$tracknumber
        fi

        mkdir -p "./music/$artist/$album"
        ext="${1##*.}"
        mv -v "$1" "./music/$artist/$album/$tracknumber - $trackname.$ext"
    fi
}

if $useparallel; then
    script=/tmp/organize.sh-temp
    echo '#!/usr/bin/bash' > $script
    type move | tail -n +4 | head -n -1 >> $script
    chmod +x $script
    trap "rm $script" SIGINT SIGTERM
    find ./music/ -not -path "./music/*/*" | grep -E "\.(${formats_to_keep})$" | parallel $script {}
    rm $script
else
    find ./music/ -not -path "./music/*/*" | grep -E "\.(${formats_to_keep})$" | while read f; do
        move "$f"
    done
fi
