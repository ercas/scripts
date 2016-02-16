#!/usr/bin/bash

fx=
input_dir=
output_dir=
this=$(basename "$0")

########## functions
function error() {
    echo "error: $@"
    echo "see $this -h for more info"
    exit 1
}

function usage() {
    cat <<EOF
$this - sort images by fx values

from the imagemagick documentation:
"[The] Fx special effects image operator [applies] a mathematical expression to
    an image or image channels." (http://www.imagemagick.org/script/fx.php)

$this uses the output from fx expressions to sort images. for example, if
    "hue" is specified, images will be sorted by increasing hue. this is done by
    creating a new directory separate from the input directory, creating links
    to images from the input directory, and storing these links in the new
    directory. the links are named in such a way that when the file manager
    sorts them in order of increasing name, the images will all appear in the
    desired order.

all fx values are averages of the pixels of an entire image.

usage: $this [-h] [-o output_dir] fx input_dir
       -h               display this message and exit
       -o output_dir    the directory to create links in. the path of this
                        directory cannot contain the "@" symbol. by default,
                        output_dir=\${input_dir}-\${fx}_sorted
       fx               the fx symbol to use (see below)
       input_dir        the directory containing images to be sorted

fx can be one of the following: r (red), g (green), b (blue), c (cyan),
    m (magenta), y (yellow), intensity, hue, saturation, lightness, luma. other
    symbols produce non-numeric output such as hex or srgb data which this
    script cannot use.

ex: $this hue ~/Pictures/Wallpapers/
EOF
}

########## parse options
while getopts ":ho:" opt; do
    case $opt in
        h) usage; exit 0 ;;
        o) output_dir="$OPTARG" ;;
        ?) usage; exit 1 ;;
    esac
done

shift $((OPTIND-1))

########## pre-run checks
if ! parallel --version 2> /dev/null | grep -q "GNU parallel"; then
    echo "gnu parallel is not available. exiting."
    exit 1
fi

if ! command -v convert > /dev/null; then
    echo "imagemagick is not available. exiting."
    exit 1
fi

if [ -z "$1" ]; then
    error "no fx symbol provided"
else
    if ! grep -E "^(r|g|b|c|m|y|intensity|hue|saturation|lightness|luma)$" <<< "$1"; then
        error "invalid fx symbol provided"
    else
        fx="$1"
    fi
fi

if [ -z "$2" ]; then
    error "no input_dir provided"
else
    if ! [ -d "$2" ]; then
        error "input_dir is not a directory"
    else
        input_dir="${2%/}"
    fi
fi

# default value of $output_dir if none is supplied
if [ -z "$output_dir" ]; then
    output_dir="$input_dir-${fx}_sorted"
fi

########## start
# hacky way of being able to write the parallel command like a normal script
# instead of a one liner without having a separate script.
tmp_script=$(mktemp -u /tmp/$this-XXXXX.sh)
(echo "#!/usr/bin/bash" && sed -n "/^#parallel_cmd_start/,/*/p" "$0") > $tmp_script
trap "rm $tmp_script" SIGINT SIGTERM

# replace placeholders in the parallel command with actual values
sed -i \
    -e "s@%OUTPUT_DIR%@$output_dir@" \
    -e "s@%FX%@$fx@" \
    $tmp_script

chmod +x $tmp_script
mkdir -p $output_dir
parallel $tmp_script ::: $input_dir/*.{png,jpg,gif}
rm $tmp_script blah 2> /dev/null

exit 0 # exit before the script reaches the parallel command

################################################################################
#parallel_cmd_start

# these values are supplied by the script above
output_dir="%OUTPUT_DIR%"
fx="%FX%"

fx_value=$(convert "$1" -resize 1x1 -format "%[fx:$fx]" info: | sed s/0.//)

# pad the fx_value value by appending zeroes. 5462 -> 5462000
min_fx_value_characters=8
fx_value_padded=$fx_value
padding=$[$min_fx_value_characters-${#fx_value}]
if [ $padding -gt 0 ]; then
    fx_value_padded="$fx_value$(printf "0%.0s" $(seq $padding))"
fi

# the numbers are converted into letters because common file managers wouldn't
# sort them properly otherwise; 0.5 should come after 0.499.
ln -sv "$(readlink -f "$1")" \
    "$output_dir/$(tr 0123456789 abcdefghij <<< $fx_value_padded)-$(basename "$1")"
