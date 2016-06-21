#!/usr/bin/sh

output=font-demo.html
quotes="All their equipment and instruments are alive.
A red flair silhouetted the jagged edge of a wing.
I watched the storm, so beautiful yet terrific.
Almost before we knew it, we had left the ground.
A shining crescent far beneath the flying vessel.
It was going to be a lonely trip back.
Mist enveloped the ship three hours out from port.
My two natures had memory in common.
Silver mist suffused the deck of the ship.
The face of the moon was in shadow.
She stared through the window at the stars.
The recorded voice scratched in the speaker.
The sky was cloudless and of a deep dark blue.
The spectacle before us was indeed sublime.
Then came the night of the first falling star.
Waves flung themselves at the blue evening."

cat << EOF > "$output"
<html>
    <head>
        <title>Font demo (generated $(date))</title>
        <meta charset=UTF-8>
        <style>
            body {
                font-size: 24px;
                margin: 72px;
                color: #1a1a1a;
                line-height: 150%;
            }
            hr {
                color: #dadada;
            }
            div {
                margin: 36px;
            }
            span {
                font-size: 24px;
                font-family: sans-serif;
            }
            .header {
                font-size: 36px;
            }
        </style>
    </head>
    <body>
EOF
fc-list | cut -d ":" -f 2 | cut -d "," -f 1 | sed "s/^ //g" | sort | uniq -u | while read font; do
    cat << EOF >> "$output"
        <div style="font-family: $font;">
            <div class=header>$font <span>($font)</span></div>
            ABCDEFGHIJKLMNOP abcdefghijklmnop 0243456789
            <br>$(shuf -n 1 <<< "$quotes")
            <br><b>$(shuf -n 1 <<< "$quotes")</b>
            <br><i>$(shuf -n 1 <<< "$quotes")</i>
        </div>
        <br>
        <hr>
        <br>
EOF
done
echo -e "    </body>\n</html>" >> "$output"

echo "wrote to $output"
