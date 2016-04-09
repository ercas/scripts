#!/usr/bin/bash
# very thin wrapper around grep, sed, and youtube-dl
# some browser interaction is required, may fully automate in the future

# pasting giant strings of text into the terminal  an get buggy so gui
# applications are preferred
editor=$(\
    command -v mousepad || \
    command -v leafpad || \
    command -v gedit || \
    command -v kate || \
    command -v vim || \
    command -v emacs || \
    command -v nano \
)
if [ -z "$editor" ]; then
    echo "error: could not find a suitable text editor"
    exit 1
fi

tempfile=$(mktemp -u /tmp/ytchannelscraper-XXXXX.temp)
cat <<EOF > $tempfile
usage:
1. open the youtube channel of your choice
2. navigate to the videos page
3. scroll down all the way and load all of the videos
4. inspect element and try to find the element containing all of the videos
5. right click the element -> copy inner html
6. paste here
7. save changes and exit your editor
EOF
trap "rm -f $tempfile" SIGINT SIGTERM

$editor $tempfile

grep -oP "/watch\?v=.*(?=\")" $tempfile | \
    sed "s|^|https://youtube.com|g" | \
    xargs youtube-dl -i -o "%(upload_date)s %(id)s - %(title)s.%(ext)s"

rm -f $tempfile
