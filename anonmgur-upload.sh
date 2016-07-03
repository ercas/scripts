#!/bin/sh
# replacement for imgur upload script

# quick and messy prototype to be further developed later
curl --ssl-reqd \
    -F "browse=@$1" \
    -F "url=" \
    -F "submit=" \
    https://anonmgur.com/?upload=upload | \
    grep -oP "(?<=Click \<a href=\").*(?=\"\>here)" | \
    sed "s|?view=|/up/|g"
