#!/usr/bin/python3
# trim.py - interactive "cut"
# 
# mainly designed to make selecting text to be copied easier for people without
# access to mice, but can also be used in any situation where something like cut
# is needed but user interaction is desired.
# 
# to use, pipe text to this script, then pipe this script to something else.
# ex. ps | trim.py | cat

# TODO:
# * make it possible for trim.py to interact with things other than cat. as it
#   is right now, it can't interact with anything else like xclip because they
#   prevent ncurses from showing.
#   possible solutions:
#   * something similar to the time command where the rest of the command is
#     supplied as an argument vector
#   * something similar to vipe from moreutils where the interactive thing is
#     opened in a subprocess and then output is passed via a file back to the
#     main program, which then reads it and outputs it to stdout

import curses, os, signal, sys

if len(sys.argv) > 1:
    print("this script does not accept arguments; it only reads from stdin.")
    sys.exit(1)

def quit(signal, frame):
    curses.endwin()
    sys.exit(0)
signal.signal(signal.SIGINT, quit)

# many thanks to this answer i found on google: http://stackoverflow.com/a/4000997
# also many thanks to http://github.com/lizardthunder for helping hunt down the bug

# read from stdin
msg = sys.stdin.read()
os.close(sys.stdin.fileno())
start = 0
end = len(msg)

# reopen the tty after reading stdin
fd = open("/dev/tty")
os.dup2(fd.fileno(), 0)

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
    if key == curses.KEY_RIGHT and (start + 1 < end):
        start += 1
    elif key == curses.KEY_LEFT and (end - 1 > start):
        end -= 1
    elif key == 10: # enter
        break
    elif key == 393 and (start - 1 >= 0): # shift + left
        start -= 1
    elif key == 402 and (end - 1 <= len(msg)-2): # shift + right
        end += 1
    #stdscr.addstr(3, 0, "keycode: " + str(key) + "\tstart: " + str(start) + "\tend: " + str(end) + " ")
    
    before = msg[:start]
    during = msg[start:end]
    after = msg[end:]
    stdscr.addstr(4, 0, before)
    stdscr.attron(curses.A_REVERSE)
    stdscr.addstr(during)
    stdscr.attroff(curses.A_REVERSE)
    stdscr.addstr(after)

print(during)
quit(0, 0)
