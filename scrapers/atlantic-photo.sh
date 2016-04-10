#!/bin/bash
# usage: bash atlanticphotoscraper.sh [url] or ./atlanticphotoscraper.sh [url]
# downloads all photos from the given atlantic photo url
# final version hopefully, unless the atlantic updates their website

# broken
#curl $(for f in $(curl $1 | grep -o -P '(?<=url\().*(?=\);)'); do
#    echo "-o $(echo $f | cut -d / -f $(echo $f | grep -o / | wc -l)- | tr / -) $f"
#done | head -n -4) # exclude the last 4 pictures because they're from other posts' previews

# new as of 8 aug 2015
#curl $(for f in $(curl $1 | grep -oP "(?<=src\=\").*(?=\?.*\=\=\=\=)"); do
#    echo "-o $(echo ${f/900/1500} | cut -d / -f $(echo $f | grep -o / | wc -l)- | tr / -) ${f/900/1500}"
#done)

# new as of 23 oct 2015
#page="$(curl $1)"
#date=$(date --date="$(echo "$page" | grep -oP "(?<=<li class=\"date\">).*(?=</li>)" -m 1)" -I)
#title=$(echo "$page" | grep -oP "(?<=<h1 class=\"hed\">).*(?=</h1>)")
#d="$date - $title"
#mkdir -p "$d"
#cd "$d"
#curl $(for f in $(echo "$page" | grep -oP "(?<=src\=\").*(?=\?.*\=\=\=\=)"); do
#    echo "-o '$(echo ${f/900/1500} | cut -d / -f $(echo $f | grep -o / | wc -l)- | tr / -) ${f/900/1500}"
#done)

# new as of 10 april 2016
page="$(wget -qO - $1)"
date=$(cut -d "/" -f 5-6 <<< "$1")
title=$(grep -oP "(?<=<h1 class=\"hed\">).*(?=</h1>)" <<< "$page")
d="$(tr "/" "-" <<< "$date - $title")"

mkdir -p "$d"
grep -oP "(?<=data-src=\").*?(?=\?)" <<< "$page" | while read url; do
    wget -O "$d/$(cut -d "/" -f 11 <<< "$url").jpg" ${url/900/1500}
done
