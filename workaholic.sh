#!/usr/bin/bash
# run queued commands when the user is away, thereby preventing cpu/io
# bottlenecks while the user is attending to more important matters. this is
# meant to be a more suitable replacement for cron for these kinds of
# activities in the respect that jobs start immediately after the user is
# detected to be idle and pause when the user returns.
# 
# depends on https://github.com/pmaia/xprintidle-plus
# alternatively, a lighter version exists at http://stackoverflow.com/a/11891468/5063602

# NOTES
# -a and -r should add or remove command instructions from $queuedir. it is the
#    control loop's responsibility to watch for removals and kill the
#    respective processes.
# when -a adds a command to the queue, it should create a file in $queuedir
#    containing only that command. the name of the file should be an integer,
#    and all queued commands should have an integer corresponding to the order
#    that they were queued in. ex: the first queued command would reside in a
#    file named "1", the second in a file named "2", etc.
# -q should read from a log file in $queuedir. this logfile should be
#    maintained by the control loop and include information for all queued
#    commands, status (running, queued, etc), and command ids.
# -a, -r, and -q are essentially frontends for the managing of the $queuedir
#    directory. if the user wishes to manage this directory on their own, they
#    may.
# for information about running background commands and keeping track of their
#    pids: https://unix.stackexchange.com/questions/90244/bash-run-command-in-background-and-capture-pid

# TODO
# * have the control loop automatically start/stop commands based on user idle
#   status

this="$(basename "$0")"

idle=/usr/bin/xprintidle
queuedir=/tmp/workaholic
sleeptime=5
idletime=600

mkdir -p "$queuedir"

########## parse options

function usage() {
    cat << EOF
usage: $this [-dhq] [-a command] [-r id]
       -a command    add the specified command to the queue
       -d            run the control loop as a daemon
       -h            display this message and exit
       -q            view the current queue
       -r id         remove the command with the given id from the queue
running this script with no arguments will have the control loop run in the
current terminal session, useful for debugging purposes. running this script
with any arguments will pass information to or start the control loop and exit.
EOF
}

while getopts ":a:dhqr:" opt; do
    case $opt in
        a)
            id=$(ls $queuedir | grep -E "^[0-9]+$" | sort -V | tail -n 1)
            id=$([ -z $id ] && echo 1 || echo $(($id+1)))
            echo $OPTARG > $queuedir/$id
            echo "queued new command with id $id"
            exit 0
        ;;
        d)
            setsid "$0" nocheckduplicate >/dev/null 2>/dev/null &
            echo "starting $this" as a daemon process
            exit 0
        ;;
        h) usage; exit 0 ;;
        q) cat $queuedir/logfile; exit 0 ;;
        r)
            if [ -f "$queuedir/$OPTARG" ]; then
                rm "$queuedir/$OPTARG"
                echo "removed command $OPTARG"
                exit 0
            else
                echo "$OPTARG is not a valid command id. use $this -q for a list."
                exit 1
            fi
        ;; 
        ?) usage; exit 1 ;;
    esac
done

shift $(($OPTIND-1))

# passing "nocheckduplicate" as the first argument to this script will prevent
# it from exiting if it sees a copy of itself already running. this is only
# used internally to allow the script to start itself up as a backgroud
# process and should not be used during normal usage.

if ! [ "$1" = "nocheckduplicate" ]; then
    processes="$(pgrep "$this")"
    if [ $(echo "$processes" | wc -l ) -gt 1 ]; then
        pid=$(echo "$processes" | grep -v $$)
        echo "a running instance of $this already exists (PID: $pid)" && \
        exit 1
    fi
fi

[ -z "$@" ] && cat << EOF
no arguments have been specified; $this control loop will be run in the
current terminal session. if you meant to run this as a daemon, specify -d. for
more information, see $this -h.

EOF

########## control loop

echo "starting $this"

while true :; do
    echo "idle time: $($idle) ms"
    
    # TODO: code to start new commands
    
    # log file maintenance, read all of the queued commands
    echo "ID        STATUS        COMMAND" > $queuedir/logfile
    for f in $queuedir/*; do
        # TODO: set status to "running" for running jobs
        status=queued
        if ! [ "$f" = $queuedir/logfile ]; then
            echo -e "$(basename "$f")        $status        $(cat "$f" | tr "\n" " ")"
        fi 
    done >> $queuedir/logfile
    # TODO: echo statistics for the running command (time, cpu/mem usage, etc)
    
    sleep $sleeptime
done
