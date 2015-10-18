#!/bin/sh
# small script to help keep track of qemu virtual machines
# sorry for the messiness. i don't plan on adding anything to this in the future
# and wrote it up really quickly.

configs=$HOME/Documents/qemuboot
qemuboot=$(basename "$0")

mkdir -p $configs

# assumes that $name, $arch, $path, and $opts are set
function genconfig() {
    cat << EOF > "$configs/$name"
ARCH $arch
PATH $path
OPTS $opts
EOF
    echo "saved config to \"$configs/$name\""
}

function invalidvm() {
    echo "\"$name\" is not a valid vm. available vms:"
    ls $configs
    echo -e "\nfor more info, use \"$qemuboot usage\""
    exit 1
}

function usage() {
    cat << EOF
usage: $qemuboot add|edit|list|new|usage|/path/to/vm
       add            add an existing virtual machine
       edit           edit an existing virtual machine
       list           list existing virtual machines
       new            create a new virtual machine
       usage          view this message and exit
       /path/to/vm    boot the specified virtual machine
       -h             displays usage (in case someone tries it)
EOF
}

case $1 in
    add)
        echo -n "name: "
        read name
        if [ -z "$name" ]; then
            echo "no name given. aborting."
            exit 1
        fi
        
        echo -n "architecture (i386/x84_64, default x86_64): "
        read arch
        if [ "${arch,,}" = "i386" ]; then
            arch=i386
        else
            arch=x86_64
        fi
        
        echo -n "path to vm: "
        read -e path
        if ! [ -f "$path" ]; then
            echo "\"$path\" does not exist. aborting."
            exit 1
        fi
        
        echo -n "options: "
        read opts
        
        genconfig
    ;;
    edit)
        shift 1
        name="$@"
        if [ -z "$name" ] || ! [ -f "$configs/$name" ]; then
            invalidvm
        else
            $EDITOR "$configs/$name"
        fi
    ;;
    list) ls $configs ;;
    new)
            
        clear
        
        ########## prompt parameters and create virtual machine
        
        echo -n "name: "
        read name
        if [ -z "$name" ]; then
            echo "no name given. aborting."
            exit 1
        fi
        
        echo -n "architecture (i386/x84_64, default x86_64): "
        read arch
        if [ "${arch,,}" = "i386" ]; then
            arch=i386
        else
            arch=x86_64
        fi
        
        echo -n "path to save vm at: "
        read -e path
        if ! [ -d "$(dirname "$path")" ]; then
            echo "\"$path\" does not exist. aborting."
            exit 1
        fi
        path="$(readlink -f "$path")"
        
        echo -n "qemu boot options: "
        read opts
        
        echo -n "format (raw/qcow, default raw): "
        read format
        if [ "${format,,}" = "qcow" ] || [ "${format,,}" = "q" ]; then
            format=qcow
        else
            format=raw
        fi
        
        echo -n "size (default 4G): "
        read size
        if [ -z "$size" ]; then
            size=4G
        fi
        
        cmd="qemu-img create -f $format $path $size"
        cat << EOF

the following settings will be used:
name         = $name
architecture = $arch
path         = $path
boot opts    = $opts

the following line will be run:
$ $cmd
press enter to continue.
EOF
        read
        $cmd
        
        ########## create config
        
        genconfig
        
        ########## first boot
        
        echo -ne "\nboot iso now? (Y/n): "
        read response
        if ! [ "${response,,}" = "n" ]; then
            echo -n "path to iso: "
            read -e isopath
            if [ -f "$isopath" ]; then
                qemu-system-$arch -cdrom "$isopath" -boot order=d $opts "$path"
            else
                echo "invalid path. exiting."
            fi
        fi
        
        echo -e "\ndone"
    ;;
    usage) usage ;;
    -h) usage ;;
    *)
        name="$@"
        if [ -z "$name" ] || ! [ -f "$configs/$name" ]; then
            invalidvm
        else
            function opt() {
                sed -n -e "s/^$1 //p" "$configs/$name"
            }
            cmd="qemu-system-$(opt ARCH) $(opt OPTS) $(opt PATH)"
            echo "running: $cmd"
            $cmd
        fi
    ;;
esac