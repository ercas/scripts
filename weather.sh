#!/bin/sh

########## defaults

units=standard
suffix=K
cityid=4930956

########## parse options

usage() {
    cat <<EOF
usage: weather [-cf] [cityid]
   -c        use celsius
   -f        use fahrenheit
   cityid    the location id to get weather information for
see http://openweathermap.org/help/city_list.txt for a list of cityids
EOF
}

case $1 in
    -c) units=metric; suffix=℃ ; shift 1 ;;
    -f) units=imperial; suffix=℉; shift 1 ;;
    -h) usage; exit 0 ;;
    -*) usage; exit 1 ;;
esac

########## get weather

cityid=$([ -z $1 ] && echo $cityid || echo $1)
echo $(wget -qO - "api.openweathermap.org/data/2.5/weather?id=$cityid&units=$units" | \
     grep -oP "(?<=temp\":).*(?=,\"pressure)")$suffix
