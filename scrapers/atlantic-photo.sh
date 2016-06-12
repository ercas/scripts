#!/bin/bash
# usage: bash atlanticphotoscraper.sh [url] or ./atlanticphotoscraper.sh [url]
# downloads all photos from the given atlantic photo url
# final version hopefully, unless the atlantic updates their website

page="$(wget -qO - $1)"
date=$(cut -d "/" -f 5-6 <<< "$1")
title=$(grep -oP "(?<=<h1 class=\"hed\">).*(?=</h1>)" <<< "$page")
d="$(tr "/" "-" <<< "$date - $title")"

mkdir -p "$d"
grep -oP "(?<=data-src=\").*?(?=\?)" <<< "$page" | while read url; do
    wget -O "$d/$(cut -d "/" -f 11 <<< "$url").jpg" ${url/900/1500}
done
