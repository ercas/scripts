#!/bin/bash
# ./removeduplicates.sh [dir]

# attempt to use gvfs-trash if it's available. otherwise, use rm
cmd=$(command -v gvfs-trash || echo rm)
removed=0

cd "$(test -z "$1" && echo . || echo "$1")"
echo using $cmd
for selected in *; do
    if [ -f "$selected" ]; then
        echo "checking for duplicates of $selected"
        for compare in *; do
            if $(cmp -s "$selected" "$compare") && ! [ "$(readlink -f "$selected")" == "$(readlink -f "$compare")" ]; then
                echo "$compare is a duplicate of $selected, removing"
                $cmd "$compare"
                removed=$((removed+1))
            fi
        done
    else
        echo "$selected no longer exists, skipping"
    fi
done

echo "removed $removed files"
