#!/bin/sh
# an experiment - creating standalone shell scripts with all of the needed
# resources pre-packaged inside them

start=21
img_lines=42
feh=$(mktemp -u feh-XXX)

# create temporary feh executable
cat $0 | tail -n +$(($start+$img_lines+1)) > $feh
chmod +x ./$feh

# pipe image data to the feh executable
cat $0 | tail -n +$start | head -n $(($img_lines+1)) | ./$feh &

# cleanup
rm $feh
exit

# binaries start after this line
