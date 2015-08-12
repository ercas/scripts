#!/bin/bash
# 
# depends: imagemagick, curl, feh
# 
# get the two latest infrared cloud imagery images from NOAA GOES, create 22
# transition images between them, and change the wallpaper every hour to each of
# the transition images so that there's one new wallpaper every hour.
# 
# files will be stored in /tmp/noaa-goes. this directory will be about 5mb max.
# 
# ideally, this script should be run in the background (you can do this by
# running "nohup ./wplatestgoes.sh >/dev/null 2>&1 &"), and can be run as a
# daily cron job so that there's a new wallpaper every hour of every day.
# 

# settings
dailydir=ftp://ftp.nnvl.noaa.gov/View/GOES/Images/Grayscale/Daily/;
memlimits="-limit memory 32 -limit map 64"

# setup
wpdir=/tmp/noaa-goes
res=$(xrandr | grep -oP "(?<=   ).*(?=\*)" | cut -d \  -f1)
files="$(curl $dailydir)"
mkdir -p $wpdir
rm $wpdir/*
cd $wpdir

# fetch the nth image and save it to the specified file in wallpaper dimensions
function getwp() {
    curl $dailydir$(echo "$files" | sed -n ${1}p | awk \{printf\ \$9\}) | \
    convert - $memlimits -resize ${res}^ -gravity center -crop $res+0+0 wp$2.jpg
}

# create transition images between the latest image and the previous one
getwp $(echo "$files" | wc -l) 2
getwp $(($(echo "$files" | wc -l)-1)) 1
convert wp1.jpg wp2.jpg $memlimits -morph 22 wp.jpg
rm wp1.jpg wp2.jpg

# cycle through the images and remove them as the script runs
for i in $(seq 24); do
    wp=wp-$(($i-1)).jpg
    feh --bg-fill $wp
    rm $wp
    sleep 3600 # one hour
done

