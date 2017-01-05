#!/bin/sh

screen_dimensions=$(xrandr | grep -oE "current [0-9]+ x [0-9]+")
screen_w=$(cut -d " " -f 2 <<< "$screen_dimensions")
screen_h=$(cut -d " " -f 4 <<< "$screen_dimensions")

win_id=$(xprop -root _NET_ACTIVE_WINDOW | cut -d " " -f 5)
win_info=$(xwininfo -id $win_id)
win_w=$(grep Width <<< "$win_info" | awk '{printf $2}')
win_h=$(grep Height <<< "$win_info" | awk '{printf $2}')
win_x=$(grep "Absolute upper-left X" <<< "$win_info" | awk '{printf $4}')
win_y=$(grep "Absolute upper-left Y" <<< "$win_info" | awk '{printf $4}')

target_x=$[ $[screen_w/2] - $[win_w/2] ]
target_y=$[ $[screen_h/2] - $[win_h/2] ]

d_x=$[$target_x - $win_x]
d_y=$[$target_y - $win_y]

if [ $d_x -lt 0 ]; then
    i3-msg move left $[$d_x * -1] px
else
    i3-msg move right $d_x px
fi

if [ $d_y -lt 0 ]; then
    i3-msg move up $[$d_y * -1] px
else
    i3-msg move down $d_y px
fi
