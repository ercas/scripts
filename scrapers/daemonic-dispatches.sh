#!/bin/sh

outdir=$(dirname $0)
mkdir -p $outdir

function dlarticle() {
    text="$(wget -qO - "$1" | grep -ozP "(?<=<div class=\"content\">)(.|\n)*(?=<div class=\"margin\">)" | w3m -dump -T text/html)"
    date="$(date --date="$(echo "$text" | grep -oP "(?<=Posted at ).*?(?= \|.*)")" -I)"
    title="$(echo "$text" | head -n 1 | tr "/" "_")"

    echo "$text" > "$outdir/$date - $title.txt"
    echo "downloaded $date - $title"
}

if [ -z "$1" ]; then
    echo "pulling entire blog in 5 seconds"
    sleep 5
    for year in $(seq 2005 $(date +%Y)); do
        wget -qO - http://www.daemonology.net/blog/$year.html | \
            grep -ozP "(?<=<div class=\"content\">)(.|\n)*(?=</div>)" | \
            grep -oE "[0-9]+-[0-9]+-[0-9]+-.*.html" | \
            while read article; do
                dlarticle http://www.daemonology.net/blog/$article
                sleep 0.5
            done
    done
else
    dlarticle "$1"
fi
