#!/bin/sh

########## defaults

units=standard
utemp=K
uspeed="m/s"

cityid=5128581
daily=false

########## functions

# get the value of the specified key from the current json (one day's data only)
getval() {
    #echo "$json" | grep -oP "(?<=$1\":).*?(?=,\")" | tr -d '"}'
    echo "$json" | perl -ne "print \$1 if m{$1\":(.*?),\"}" | tr -d '"}'
}

# extract the individual days from the json that the openweathermap daily api
# returns and print each day's json on an individual line. each line can then be
# treated like a json from the openweathermap current weather api.
getdays() {
    #echo "$1" | grep -oP "\"dt\":.*?(?=,{)"
    perl -e 'while ($ARGV[0] =~ m/(\"dt\":.*?),\{/g) { print "$1\n"; }' "$1"
}

# drop-in replacement for gnu date because of differences with bsd date
perldate() {
    perl -e 'use POSIX qw(strftime); print strftime "$ARGV[1]", localtime $ARGV[0]' $1 $2
}

########## parse options

usage() {
    cat <<EOF
usage: $(basename "$0") [-dhgilmp] [cityid]
       -d        daily forecast
       -h        display this message and exit
       -i        use imperial
       -l        list all cityids and exit
       -m        use metric
       cityid    get weather information for this city id (use -l to find yours)

the columns for -l are cityid, city name, latitude, longitude, and country.

by default, grep will be used to get information from the jsons unless it isn't
    gnu grep, in which case, perl will be used instead; the script depends on
    grep -P to work, which bsd grep doesn't have. this decision can be overriden
    by specifying -g or -p.
EOF
}

while getopts ":dhilm" opt; do
    case $opt in
        d) daily=true ;;
        h) usage; exit 0 ;;
        i) units=imperial; utemp=°F; uspeed=mph ;;
        l) wget -qO - http://openweathermap.org/help/city_list.txt; exit 0 ;;
        m) units=metric; utemp=°C ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## setup

cityid=$([ -z $1 ] && echo $cityid || echo $1)
########## get weather

if $daily; then
    json=$(wget -qO - "api.openweathermap.org/data/2.5/forecast/daily?id=$cityid&units=$units")
    echo "Weather for $(getval name)"
    getdays "$json" | while read json; do
#...on $(date --date=@$(getval dt) +%A): $(getval description)
        cat << EOF
...on $(perldate $(getval dt) %A): $(getval description)
High:         $(getval max)$utempcurl 
Average:      $(getval day)$utemp
Low:          $(getval min)$utemp
Humidity:     $(getval humidity)%
Wind:         $(getval speed)$uspeed @ $(getval deg)°
EOF
    done
else
    json=$(wget -qO - "api.openweathermap.org/data/2.5/weather?id=$cityid&units=$units")
#Sunrise:      $(date --date=@$(getval sunrise) +%
#Sunset:       $(date --date=@$(getval sunset) +%r)
    cat << EOF
Weather for $(getval name): $(getval description)
High:         $(getval temp_max)$utemp
Current:      $(getval temp)$utemp
Low:          $(getval temp_min)$utemp
Humidity:     $(getval humidity)%
Wind:         $(getval speed)$uspeed @ $(getval deg)°
Sunrise:      $(perldate $(getval sunrise) %r)
Sunset:       $(perldate $(getval sunset) %r)
EOF
fi
