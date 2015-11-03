#!/usr/bin/python3
# trim.py - interactive "cut"
# 
# dependencies: xclip
# 
# mainly designed to make selecting text to be copied easier for people without
# access to mice, but can also be used in any situation where something like cut
# is needed but user interaction is desired.
# 
# to use, pipe text to this script and follow the instructions to select text.
# this text is automatically copied to the clipboard using xclip.

import curses, getopt, os, signal, subprocess, sys

########## config

# keys to move left bound
lboundkeys = {
    261 : 1,   # right
    258 : 10,  # down
    393 : -1,  # shift + left
    # no shift + up
}

# keys to move right bound
rboundkeys = {
    260 : -1,   # left
    259 : -10,  # up
    402 : 1,    # shift + right
    # no shift + down
}

write = False

########## functions


def quit(signal, frame):
    try:
        curses.endwin()
    except:
        pass
    sys.exit(0)

def usage():
    print("usage: [program] | " + os.path.basename(__file__) + " [-hw]\n"
          "       -h, --help     display this message and exit\n"
          "       -w, --write    write the trimmed string to stdout\n"
          "\n"
          "this program reads from stdin, allows the user to select text, and copies\n"
          "the selected text to the clipboard using xclip.")
    quit(0,0)

########## parse options

try:
    opts, args = getopt.getopt(sys.argv[1:], "hw", ["help", "write"])
except:
    usage()

for opt, arg in opts:
    if opt in ("-h", "--help"):
        usage()
        sys.exit()
    elif opt in ("-w", "--write"):
        write = True
    else:
        usage()

########## begin

signal.signal(signal.SIGINT, quit)

# many thanks to this answer i found on google: http://stackoverflow.com/a/4000997
# also many thanks to http://github.com/lizardthunder for helping hunt down the bug
# read from stdin then reopen the tty
msg = sys.stdin.read()
os.close(sys.stdin.fileno())
fd = open("/dev/tty")
os.dup2(fd.fileno(), 0)

# selection variables
during = msg
start = 0
end = len(msg)

# curses settings
stdscr = curses.initscr()
stdscr.keypad(True)
curses.cbreak()
curses.curs_set(0)
curses.noecho()

# instructions
stdscr.addstr(0, 0, "use the arrow keys to narrow the selection.")
stdscr.addstr(1, 0, "use shift + arrow keys to widen the selection.")
stdscr.addstr(2, 0, "press enter to confirm the selection and exit.")
stdscr.attron(curses.A_REVERSE)
stdscr.addstr(4, 0, msg)
stdscr.attroff(curses.A_REVERSE)

# main loop, break when the user presses enter
while True:
    key = stdscr.getch()
    #stdscr.addstr(3, 0, str(key) + "\trkeys: " + str(key in rboundkeys) +  "\tlkeys: " + str(key in lboundkeys) + " ")
    
    # move left bound
    if key in lboundkeys:
        change = lboundkeys[key]
        if ((change < 1) and (start - change >= 0)) or (start + change < end):
                start += change
        
    # move right bound
    elif key in rboundkeys:
        change = rboundkeys[key]
        if ((change > 1) and (end + change <= len(msg-2))) or (end - change > start):
                end += change
        
    # enter
    elif key == 10:
        break
    
    before = msg[:start]
    during = msg[start:end]
    after = msg[end:]
    stdscr.addstr(4, 0, before)
    stdscr.attron(curses.A_REVERSE)
    stdscr.addstr(during)
    stdscr.attroff(curses.A_REVERSE)
    stdscr.addstr(after)

if write:
    sys.stdout.write(during)
else:
    subprocess.Popen(["xclip","-i"], stdin=subprocess.PIPE).stdin.write(during.encode("utf-8"))

quit(0, 0)
