#!/bin/sh
# download all comics and alt text from asofterworld.com

mkdir -p asofterworld

for i in $(seq 1 $(curl http://asofterworld.com/ | grep -oE "http.*asofterworld.*id=[0-9]*" | tail -n 1 | cut -d "=" -f2)); do
    src=$(curl http://www.asofterworld.com/index.php?id=$i)
    img="$(echo "$src" | grep "/clean/" | head -n 1 | grep -oP '(?<=src=").*(?=" )')"
    text="$(echo "$src" | grep makeAlert | grep -oP '(?<=, ).*(?=\))')"
    echo $i: $text >> asofterworld/alttexts.txt
    curl -o asofterworld/$i.jpg $img
    sleep 2
done

