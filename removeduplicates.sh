#!/bin/sh
# ./removeduplicates.sh [dir]

cd "$(test -z "$1" && echo . || echo "$1")"
removed=0
for selected in *; do
    if test -f "$selected"; then
        echo "checking for duplicates of $selected"
        for compare in *; do
            if $(cmp -s "$selected" "$compare") && ! test "$selected" == "$compare"; then
                echo "$compare is a duplicate of $selected, removing"
                rm "$compare"
                removed=$((removed+1))
            fi
        done
    else
        echo "$selected no longer exists, skipping"
    fi
done

echo "removed $removed files"
