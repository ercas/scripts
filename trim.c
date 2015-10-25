#include <ncurses.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>

/*
    trim.c - interactive cut
    
    mainly designed to make selecting text to be copied easier for people
        without access to mice. to use, pipe text to this program, then pipe
        this program to something like xclip.
*/

/*
    TODO:
    * read stdin to msg array
    * output the trimmed string when enter is pressed
*/

void quit(int signal) {
    endwin();
    exit(0);
}

int main(void) {
    char msg[] = "Elementary dear watson";
    int start = 0;
    int end = strlen(msg);
    
    signal(SIGINT, quit);
    
    initscr();
    cbreak();
    keypad(stdscr, TRUE);
    noecho();
    
    mvprintw(0, 0, "use the arrow keys to narrow the selection.");
    mvprintw(1, 0, "use shift + arrow keys to widen the selection.");
    while (1) {
        int key = wgetch(stdscr);
        char before[sizeof(msg)];
        char during[sizeof(msg)];
        char after[sizeof(msg)];
        /*
            right arrow: move left bound to the right
            shift + left arrow:  move left bound to the left
            left arrow: move right bound to the left
            shift + right arrow move right bound to the right
            
            might change this to handle only one bound at a time for ease of use
        */
        switch (key) {
            case KEY_RIGHT:
                if (start+1 < end)
                    start++;
                break;
            case KEY_LEFT:
                if (end-1 > start)
                    end--;
                break;
            case 393: /* shift + left */
                if (start-1 >= 0)
                    start--;
                break;
            case 402: /* shift + right */
                if (end-1 <= strlen(msg)-2)
                    end++;
                break;
            case 10:
                /* process enter key here */
                key = 'e';
                break;
            default:
                break;
        }
        
        mvprintw(2, 0, "keycode: %d\tstr: %s\tstart: %d\tend: %d\n", key, msg, start, end);
        
        /* create arrays before, during, and after to visualize the trim */
        strncpy(before, msg, start);
        before[start] = '\0';
        strncpy(during, &msg[start], end);
        during[end-start] = '\0';
        strncpy(after, &msg[end], sizeof(msg)-end);
        after[sizeof(msg)-end] = '\0';
        
        mvprintw(3, 0, "%s", before);
        wattron(stdscr, A_REVERSE);
        printw("%s", during);
        wattroff(stdscr, A_REVERSE);
        printw("%s                         ", after);
        mvprintw(4, 0, "");
        refresh();
    }
    
    quit(0);
}
