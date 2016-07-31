#!/usr/bin/bash
# download all available pdfs from an oxford journal volume, given the volume's
# table of contents url

html=$(wget -qO - "$1")
base_url=$(cut -d "/" -f 1-3 <<< "$1")

full_title=$(sed -n "/toc-citation-volume/,/div/p" <<< "$html" | \
    tr -d "\n" | \
    sed -e "s/<[^>]*>//g" -e "s/  */ /g" -e "s/^ *//g")
release_date=$(date --date="$(cut -d " " -f 5-7 <<< "$full_title")" -I)
output_dir="$release_date - $(cut -d " " -f 1-2 <<< "$full_title")"

mkdir -p "$output_dir"

grep -o "/content/.*.full.pdf" <<< "$html" | while read url; do
    name=$(grep -B 10 $url <<< "$html" | \
        grep -oP "(?<=cit-title-group\"\>).*" | \
        sed -e "s|</h4.*>||g" -e "s/<[^>]*>//g" -e "s/\s*$//g" -e "s|/|_|g")
    doi=$(grep -B 10 $url <<< "$html" | \
        grep -oP "(?<=doi:).*" | \
        sed -e "s/<[^>]*>//g" -e "s/\s*$//g" -e "s|/|_|g")
    wget -O "$output_dir/$doi - $name.pdf" "$base_url$url"
done
