#!/usr/bin/bash
# scraper for skadicomic.com, mostly based off of octopuspie.sh

first=http://skadicomic.com/comic/ballad-of-skadi-pt-1-2/
outdir=$HOME/Pictures/webcomics/skadi
num=0

function grab() {
    src="$(wget -qO - $1)"
    title="$(echo "$src" | grep -oP "(?<=post-title\">).*(?=</h2>)")"
    img="$(echo "$src" | grep -oP "(?<=<img src=\").*.jpg(?=\")")"
    next="$(echo "$src" | grep -oP "(?<=href=\").*(?=\" class.*>Next)")"
    num=$(($num+1))

    if ! [ -z "$title" ]; then
        wget -O "$outdir/$num $title.${img##*.}" $img
    else # rename untitled strips
        title="Untitled"
        while [ -f $title ]; do # really lazy way of finding an unused filename
            title="Untitled$(($(echo $title | cut -d "d" -f2)+1))"
        done
        wget -O "$outdir/$num $title.${img##*.}" $img
    fi

    sleep 0.2

    if ! [ -z $next ]; then
        grab $next
    else
        echo $1 > $outdir/lastdl.conf
    fi
}

mkdir -p $outdir
num="$(find $outdir -type f -name "*.jpg" | wc -l)"
[ -f $outdir/lastdl.conf ] && grab $(cat $outdir/lastdl.conf) || grab $first
