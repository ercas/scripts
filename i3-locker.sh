#!/bin/sh
# lock the screen, display a darkened, desaturated, distorted screenshot,
# display a message, and adjust the screen timeout to be shorter while locked
# 
# this uses https://github.com/eBrnd/i3lock-color
# additional options, from the readme:
# --insidevercolor=rrggbbaa   -- Inside of the circle while the password is being verified
# --insidewrongcolor=rrggbbaa -- Inside of the circle when a wrong password was entered
# --insidecolor=rrggbbaa      -- Inside of the circle while typing/idle
# --ringvercolor=rrggbbaa     -- Outer ring while the password is being
# --ringwrongcolor=rrggbbaa   -- Outer ring when a wrong password was entered
# --ringcolor=rrggbbaa        -- Outer ring while typing/idle
# --linecolor=rrggbbaa        -- Line separating outer ring from inside of the circle and delimiting the highlight segments
# --textcolor=rrggbbaa        -- Text ("verifying", "wrong!")
# --keyhlcolor=rrggbbaa       -- Keypress highlight segments
# --bshlcolor=rrggbbaa        -- Backspace highlight segments

# default is pixelize
distort="-scale 10% -scale 1000%"
#distort="-blur 0x12" ;;

# create distorted desktop screenshot
img=$(mktemp -u /tmp/i3lock-XXXXX.png)
import -window root $img
convert $img \
    -modulate 40,30 \
    $distort \
    -font Fira-Sans-UltraLight -fill white -gravity center -pointsize 60 \
    -annotate +0+220 "enter password to unlock" \
    $img

# lock the screen
xset dpms force off
xset s 10 0 # reduce screen saver timeout while locked
i3lock -n                       \
    --color 000000              \
    --insidevercolor=00000000   \
    --insidewrongcolor=00000000 \
    --insidecolor=00000000      \
    --ringvercolor=00000000     \
    --ringwrongcolor=00000000   \
    --ringcolor=00000000        \
    --textcolor=00000000        \
    --linecolor=ffffffff        \
    --keyhlcolor=ffffffff       \
    --bshlcolor=ffffffff        \
    -i $img
rm $img
xset s 600 0 # restore original screen saver timeout
