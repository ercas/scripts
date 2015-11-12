these scripts have not been tested with ash/dash. if something doesn't work, change the interpreter directive to use /usr/bin/bash.

directories
-----------
* standaloneshellscript/ - a little experiment with making shell scripts that have all of the resources they need embedded into the shell script itself. just a proof of concept for now

* scrapers/ - a collection of small website scrapers

scripts
-------
* define.sh - define a word by parsing the gutenberg copy of webster's unabridged dictionary

* mpdalbumart.sh - automatically fetch and display album art of mpd's currently playing song with [meh](http://www.johnhawthorn.com/meh/)

* qemuboot.sh - small script to manage qemu virtual machines

* removeduplicates.sh - remove duplicate files in the current directory or the specified directory (if any)

* sortbylinelength.sh - sort the specified file so that the longest lines are first (or last, if -r is specified)

* trash.sh - wrapper for gvfs-trash that allows for easy trash operations like listing and restoring trashed items from the command line

* trim.c - an interactive "cut". not exactly a "script" but didn't warrant a new repository. precursor to trim.py; will probably be removed in the future.

* trim.py - an interactive "cut". reads text from stdin and allows the user select what will be copied or printed to stdout via an ncurses interface. you should probably use vipe from [moreutils](https://joeyh.name/code/moreutils/) instead.

* wplatestgoes.sh - a script to fetch the two latest images from the noaa environmental visualization laboratory's daily repository (ftp://ftp.nnvl.noaa.gov/View/GOES/), create transition images between them, and set the wallpaper to one of the images every hour, progressing from the second latest image to the latest image.
![demo image](wplatestgoes-demo.gif)

* weather.sh - get the current weather from http://openweathermap.org

        $ ./weather.sh -m 2174003
        Weather for Brisbane: scattered clouds
        High:         14°C
        Current:      12.86°C
        Low:          11.8°C
        Humidity:     93%
        Wind:         2.6mph @ 200°
        Sunrise:      03:55:53 PM
        Sunset:       03:36:56 AM
