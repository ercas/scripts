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
# * possibly reorganize the options so the script is less confusing to use
# * pause/resume grandchild processes
# * allow the user to specify sleeptime and idletime
# * better documentation
# * ability to abort commands by removing the command files from $queuedir
#   (the control loop should detect these removals and kill those commands)
# * finish misc TODO comments littered around

this="$(basename "$0")"

idle=/usr/bin/xprintidle
queuedir=/tmp/workaholic
sleeptime=2
idletime=10000 # milliseconds

runningpid=
currentidle=
currentcommand=
currentstatus=

mkdir -p "$queuedir"

########## parse options

function usage() {
    cat << EOF
ABOUT
$this is a daemon and collection of interfaces to that daemon that
manages the automatic starting up and pausing of commands based on user idle
time. the purpose of this is to allow the computer to remain productive doing
io/cpu intensive tasks while the user is away, but not keep the user from
being productive by pausing and deferring these tasks to when the user isn't
away. this is similar to the concept of folding@home, which uses idle cpu time
to fold proteins for science.

USAGE
this script runs in two different modes. the first mode is to run as the
control loop, which is the main function of the script and is responsible for
automatically starting/resuming commands when the user is idle and pausing
commands when the user is no longer idle. this mode can either be run inside
the current terminal for debugging purposes or can be run as a daemon.

the second mode is to interface with the control loop by adding, removing, and
querying queued commands. this is essentially a frontend for management of the
\$queuedir directory. to use the second mode, an option MUST be specified; if
the script is run without any options, it will run in the first mode.

CONTROL LOOP
usage: $this [-d]
       -d            run the control loop as a daemon
       
INTERFACE TO CONTROL LOOP
usage: $this -h|-q|-a command|-r id
       -a command    add the specified command to the queue. the command can
                     either be an entire command or the path to a script.
       -h            display this message and exit
       -q            query the workaholic queue
       -r id         remove the command with the given id from the queue
remember that one of these options MUST be used and running $this
without any options will have it start the control loop in the current terminal

CAVEATS
* all scripts must be made to run without any user interaction
* don't forget to source your .bashrc if you want to use its functions/alises

EXAMPLE USAGE
$ $this -d                       # start up the control loop daemon
$ # queue an ffmpeg job. note that -y specified to disable user prompting.
$ $this -a "ffmpeg -y -i in.mp4 out.mkv >/dev/null 2>/dev/null"
$ $this -q                       # view the status of the queue
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

[ -z "$@" ] && cat << EOF && sleep 5
no arguments have been specified; $this control loop will be run in the
current terminal session. if you meant to run this as a daemon, specify -d. for
more information, see $this -h.

starting in 5 seconds...
EOF

########## functions

# start up the specified command file in $queuedir
function startcommand() {
    if ! [ -z "$1" ]; then
        bash "$1" &
        runningpid=$!
        if [ -z $runningpid ]; then
            echo "failed to start command $(basename "$1")"
            runningpid=
        else
            echo "started command $(basename "$1") (PID: $runningpid)"
        fi
    else
        echo "nothing to run"
    fi
}

# update the log file with information
function updatelog() {
    # general queue information
    printf "queue:\n%5s\t%8s\t%50s\n" ID STATUS COMMAND > $queuedir/logfile
    for f in $queuedir/*; do
        status=queued
        # running command should be "running" or "paused"
        if [ "$currentcommand" = "$f" ]; then
            status=$currentstatus 
        fi
        if ! [ "$f" = $queuedir/logfile ]; then
            # TODO: pretty formatting with printf
            #echo -e "$(basename "$f")        $status        $(cat "$f" | tr "\n" " ")"
            printf "%5s\t%8s\t%.50s\n" "$(basename "$f")" $status "$(cat "$f" | tr "\n" " ")"
        fi 
    done >> $queuedir/logfile

    # information about the running command
    if ! [ -z $runningpid ]; then
        echo -e "\nparent pid: $runningpid\n\nchild proccesses:"
        pgrep -P $runningpid | xargs ps -o cmd,pid,vsize,rss,%mem,%cpu,size,time -p
    else
        echo -e "\nthere are no commands running."
    fi >> $queuedir/logfile
}

# clean exit
function quit() {
    ! [ -z $runningpid ] && pkill -TERM -P $runningpid
    echo "terminated running commands"
    exit 0
}

########## control loop

echo "starting $this"

trap quit SIGINT SIGTERM
while true :; do
    currentidle=$($idle)
    echo "idle time: $currentidle  ms"
    
    # start up or resume commands if the user is idle
    if [ $currentidle -gt $idletime ]; then
        
        # if nothing is currently running, attempt to start a new command
        if [ -z $runningpid ]; then
            # run the first command from the sorted queued commands list
            currentcommand="$(find $queuedir -type f -not -path $queuedir/logfile | sort -V | head -n 1)"
            startcommand "$currentcommand"
        else
             echo "waiting for command $(basename "$currentcommand")"
             pkill -CONT -P $runningpid
        fi
        currentstatus=running

    # pause running commands if the user returns
    elif ! [ -z $runningpid ]; then
        echo "paused $runningpid"
        pkill -STOP -P $runningpid
        currentstatus=paused
    fi
    echo
    
    # remove completed commands
    if ! [ -z $runningpid ]; then
        if [ -z "$(ps -p $runningpid | sed -n 2p)" ]; then
            echo "current job finished"
            runningpid=
            rm "$currentcommand"
        fi
    fi
    
    updatelog
    
    sleep $sleeptime
done
