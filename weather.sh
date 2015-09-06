#!/bin/sh

########## defaults

units=standard
utemp=K
uspeed="m/s"

cityid=5128581
daily=false
json=

########## functions

# get the value of the specified key from the current json (one day's data only)
getval() {
    echo "$json" | grep -oP "(?<=$1\":).*?(?=,\")" | tr -d '"}'
}

########## parse options

usage() {
    cat <<EOF
usage: $(basename "$0") [-dhilm] [cityid]
       -d        daily forecast
       -h        display this message and exit
       -i        use imperial
       -l        list all cityids and exit
       -m        use metric
       cityid    get weather information for this city id (use -l to find yours)
the columns for the list are cityid, city name, latitude, longitude, country
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

########## get weather

cityid=$([ -z $1 ] && echo $cityid || echo $1)
if $daily; then
    json=$(wget -qO - "api.openweathermap.org/data/2.5/forecast/daily?id=$cityid&units=$units")
    echo "Weather for $(getval name)"
    # iterate over the individual days and print data from each
    echo $json | grep -oP "\"dt\":.*?(?=,{)" | while read json; do
        cat << EOF
...on $(date --date=@$(getval dt) +%A):
High:        $(getval max)$utemp
Average:     $(getval day)$utemp
Low:         $(getval min)$utemp
Humidity:    $(getval humidity)%
Wind:        $(getval speed)$uspeed @ $(getval deg)°
EOF
    done
else
    json=$(wget -qO - "api.openweathermap.org/data/2.5/weather?id=$cityid&units=$units")
    cat << EOF
Weather for $(getval name)
High:        $(getval temp_max)$utemp
Current:     $(getval temp)$utemp
Low:         $(getval temp_min)$utemp
Humidity:    $(getval humidity)%
Wind:        $(getval speed)$uspeed @ $(getval deg)°
Sunrise:     $(date --date=@$(getval sunrise) +%r)
Sunset:      $(date --date=@$(getval sunset) +%r)
EOF
fi
