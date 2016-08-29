#!/bin/sh

info=
lyrics_output=$HOME/.lyrics

function parse_mediainfo() {
    grep "$1" <<< "$info" | head -n 1 | cut -d ":" -f 2- | tail -c +2
}


function grab_azlyrics() {
    if ! [ -f "$1" ]; then
        echo "\"$1\" is not a file"
        exit 1
    fi

    info=$(mediainfo "$1")
    performer=$(parse_mediainfo Performer\ )
    track=$(parse_mediainfo Track\ name\ )

    if [ -z "$performer" ]; then
        echo "Performer field is blank"
        exit 1
    elif [ -z "$track" ]; then
        echo "Track field is blank"
        exit 1
    else
        mkdir -p $lyrics_output

        output="$lyrics_output/$performer - $track.txt"

        if [ -f "$output" ]; then
            echo "$output already exists"
            exit 1
        else

            formatted_performer=$(tr -dc "[:alpha:]" <<< "$performer" | \
                tr "[:upper:]" "[:lower:]" | \
                sed "s/^the//g")
            formatted_track=$(tr -dc "[:alpha:]" <<< "$track" | \
                tr "[:upper:]" "[:lower:]")

            url=http://www.azlyrics.com/lyrics/$formatted_performer/$formatted_track.html

            echo "trying $url"
            azhtml=$(w3m -dump $url)

            # "Welcome to AZLyrics!" only appears when the given lyric doesn't
            # exist on the site
            if grep -q "Welcome to AZLyrics!" <<< "$azhtml"; then
                echo "no lyrics found for $track by $performer;"

                # offer to open the artist's azlyrics page so the user can look
                # for the lyrics themselves
                if [[ $- == *i* ]]; then
                    echo -ne "\nopen artist page in browser? (y/N) "
                    read response
                    if [ "${response,,}" = "y" ]; then
                        xdg-open "http://www.azlyrics.com/${formatted_performer:0:1}/$formatted_performer.html"
                    fi
                fi

                exit 1
            else

                reading=false
                started_reading=false
                consecutive_blank_lines=0

                echo "$azhtml" | while read line; do
                    # begin reading on the line that consists of only the track name
                    # surrounded by quotes
                    if grep -q "^\"$track\"$" <<< "$line"; then
                        reading=true
                        started_reading=true
                    fi

                    # echo lines until reading is false
                    if $reading; then
                        echo "$line"
                    elif $started_reading; then
                        break
                    fi

                    # set reading to false if 3 consecutive blank lines are encountered
                    if [ -z "$line" ]; then
                        consecutive_blank_lines=$[$consecutive_blank_lines + 1]
                        if [ $consecutive_blank_lines -eq 3 ]; then
                            reading=false
                        fi
                    else
                        consecutive_blank_lines=0
                    fi

                done | tail -n +3 | head -n -5 > "$output"

                echo "wrote lyrics to $output"

            fi
        fi
    fi
}

grab_azlyrics "$1"
