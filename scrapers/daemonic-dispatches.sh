#!/bin/sh

outdir=daemonic-dispatches
mkdir -p $outdir

function dlarticle() {
    text="$(wget -qO - "$1" | grep -ozP "(?<=<div class=\"content\">)(.|\n)*(?=<div class=\"margin\">)" | w3m -dump -T text/html)"
    date="$(date --date="$(echo "$text" | grep -oP "(?<=Posted at ).*?(?= \|.*)")" -I)"
    title="$(echo "$text" | head -n 1 | tr "/" "_")"

    echo "$text" > "$outdir/$date - $title.txt"
    echo "downloaded $date - $title"
}

dlarticle http://www.daemonology.net/blog/2012-08-16-portifying-freebsd-ec2-startup-scripts.html
dlarticle http://www.daemonology.net/blog/2014-02-16-FreeBSD-EC2-build.html
dlarticle http://www.daemonology.net/blog/2012-01-16-automatically-populating-ssh-known-hosts.html
dlarticle http://www.daemonology.net/blog/2011-03-22-FreeBSD-EC2-cluster-compute.html
exit
for year in $(seq 2005 $(date +%Y)); do
    wget -qO - http://www.daemonology.net/blog/$year.html | \
        grep -ozP "(?<=<div class=\"content\">)(.|\n)*(?=</div>)" | \
        grep -oE "[0-9]+-[0-9]+-[0-9]+-.*.html" | \
        while read article; do
            dlarticle http://www.daemonology.net/blog/$article
            sleep 0.5
        done
done
