#!/usr/bin/bash
# run queued commands when the user is away, thereby preventing cpu/io
# bottlenecks while the user is attending to more important matters
# 
# depends on https://github.com/pmaia/xprintidle-plus
# alternatively, a lighter version exists at http://stackoverflow.com/a/11891468/5063602
# 
# may rewrite in c in the future to avoid this dependency

this="$(basename "$0")"

idle=/usr/bin/xprintidle
queuedir=$HOME/
sleeptime=10
idletime=600

# passing "nocheckduplicate" as the first argument to this script will prevent
# it from exiting if it sees a copy of itself already running. this is only
# used internally to allow the script to start itself up as a backgroud
# process and should not be used during normal use.

if ! [ "$1" = "nocheckduplicate" ]; then
    processes="$(pgrep "$this")"
    if [ $(echo "$processes" | wc -l ) -gt 1 ]; then
        pid=$(echo "$processes" | grep -v $$)
        echo "a running instance of $this already exists (PID: $pid)" && \
        exit 1
    fi
fi

# pid=$(pgrep "$this") 
# ! [ "$1" = "nocheckduplicate" ] && ! [ -z $pid ] && \
#     echo "a running instance of $this already exists (PID: $pid)" && \
#     exit 1

########## parse options

function usage() {
    cat << EOF
usage: $this [-dhq] [-a command] [-r id]
       -a command    add the specified command to the queue
       -d            run the control loop as a daemon
       -h            display this message and exit
       -r id         remove the command with the given id from the queue
       -q            view the current queue
running this script with no arguments will have the control loop run in the
current terminal session, useful for debugging purposes.
EOF
}

while getopts ":h" opt; do
    case $opt in
        d) setsid "$0" nocheckduplicate; exit 0 ;;
        h) usage; exit 0 ;;
        ?) usage; exit 1 ;;
    esac
done

shift $(($OPTIND-1))

########## main loop

[ -z "$@" ] && cat << EOF
no arguments have been specified; $this control loop will be run in the
current terminal session. if you meant to run this as a daemon, specify -d. for
more information, see $this -h.

EOF

echo "starting $this"

while true :; do
    echo "idle time: $($idle) ms"
    sleep $sleeptime
done
