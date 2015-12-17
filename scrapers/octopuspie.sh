#!/bin/bash
# download all comics from octopuspie.com

first=http://www.octopuspie.com/2007-05-14/001-pea-wiggle/
outdir=$HOME/Pictures/webcomics/octopuspie

# recursive function to grab all strips from after the given strip
function grabnext() {
    src="$(curl $1)"
    title="$(echo "$src" | grep -o -P '(?<=8211; ).*(?=</title>)')"
    num=$(echo "$src" | grep -o -P '(?<=alt="#).*(?=.)' | cut -d ' ' -f1)
    img=$(echo "$src" | grep strippy | cut -d "\"" -f2)
    next=$(echo "$src" | grep -o -P '(?<=href=").*(?=" rel="next")')
    if ! [ -z "$title" ]; then
        curl -o "$outdir/$num $title.${img##*.}" $img
    else # rename untitled strips
        title="Untitled"
        while [ -f $title ]; do # really lazy way of finding an unused filename
            title="Untitled$(($(echo $title | cut -d "d" -f2)+1))"
        done
        curl -o "$outdir/$title.${img##*.}" $img
    fi
    sleep 0.2 # let's not overwhelm them
    if ! [ -z $next ]; then
        grabnext $next
    else # finished
        echo $1 > $outdir/lastdl.conf
    fi
}

# attempt to start at the last strip from a previous invocation
if [ -f $outdir/lastdl.conf ]; then
    first=$(cat $outdir/lastdl.conf)
fi

mkdir -p $outdir
grabnext $first
