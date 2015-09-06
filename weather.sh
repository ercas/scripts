#!/bin/sh

########## defaults

units=standard
utemp=K
uspeed="m/s"
cityid=5128581
json=

########## functions

# get the value of the specified json key
getval() {
    echo "$json" | grep -oP "(?<=$1\":).*?(?=,\")" | tr -d '"}'
}

########## parse options

usage() {
    cat <<EOF
usage: $(basename "$0") [-hilm] [cityid]
       -h        display this message and exit
       -i        use imperial
       -l        list all cityids and exit
       -m        use metric
       cityid    get weather information for this city id (use -l to find yours)
the columns for the list are cityid, city name, latitude, longitude, country
EOF
}

while getopts ":hilm" opt; do
    case $opt in
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
