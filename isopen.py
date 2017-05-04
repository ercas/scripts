#!/usr/bin/env python3

import datetime
import json
import math

WEEKDAYS = [ "mon", "tue", "wed", "thu", "fri", "sat", "sun" ]
FORMATS = [ "%I:%M %p", "%H:%M", "%I %p", "%H" ]
CLOSED = "\x1b[31mClosed\x1b[0m"
OPEN = "\x1b[32mOpen\x1b[0m"

def parse_time(time_string):
    """ Attempt to convert a time string into a datetime, using a format
    specified in FORMATS

    Args:
        time_string: The string to be converted.

    Returns:
        A datetime.datetime object. Returns LookupError if the string could not
        be converted.
    """

    for _format in FORMATS:
        try:
            return datetime.datetime.strptime(time_string, _format)
        except:
            pass
    raise LookupError

def second_of_day(datetime):
    """ Convert a datetime into the number of seconds since 12:00 am

    Args:
        datetime: A datetime.datetime object.

    Returns:
        The number of seconds since 12:00 am.
    """

    return datetime.second + datetime.minute*60 + datetime.hour*3600

def time_diff(start_datetime, end_datetime):
    """ Show the difference between two times

    Args:
        start_datetime, end_datetime: The datetime.datetime objects that the
            difference will be calculated from.

    Returns:
        A string describing the difference in time of day.
    """

    seconds = abs(
        (end_datetime.second - start_datetime.second)
        + (end_datetime.minute - start_datetime.minute) * 60
        + (end_datetime.hour - start_datetime.hour) * 3600
    )
    minutes = math.floor(seconds/60)
    hours = math.floor(seconds/3600)

    if (hours > 1):
        return "%d hours" % hours
    elif (minutes == 60):
        return "1 hour"
    elif (hours == 1):
        return "1 hour and %d minutes" % (minutes - 60)
    elif (minutes > 1):
        return "%d minutes" % minutes
    elif (seconds == 60):
        return "1 minute"
    elif (minutes == 1):
        return "1 minute and %d seconds" % (seconds - 60)
    else:
        return "%d seconds" % seconds

def main(times_json, relative, absolute):
    """ Prints if locations are opened or closed

    Args:
        times: A string containing a path to a JSON of locations and hours.
            Sample JSON:
                [
                    {
                        "name": "Boston Public Library",
                        "hours": {
                            "sun": ["1:00 pm", "5:00 pm"],
                            "mon": ["9:00 am", "9:00 pm"],
                            "tue": ["9:00 am", "9:00 pm"],
                            "wed": ["9:00 am", "9:00 pm"],
                            "thu": ["9:00 am", "9:00 pm"],
                            "fri": ["9:00 am", "5:00 pm"],
                            "sat": ["9:00 am", "5:00 pm"]
                        }
                    },
                    {
                        "name": "Only Thursdays",
                        "hours": {
                            "thu": ["9:00 am", "9:00 pm"],
                        }
                    }
                ]
            Times must be in one of the formats defined in the FORMATS array.
            For example, 1:00 pm, 1 pm, 13:00, and 13 are all valid. If a venue
            is closed for the whole day, that day can be ommitted.
        relative: A bool describing whether or not opening and closing times
            should be given in relation to the current time or not.

    """

    with open(times_json, "r") as f:
        locations = json.load(f)

    now = datetime.datetime.now()
    today = WEEKDAYS[now.weekday()]
    now_sod = second_of_day(now)

    for location in locations:
        description = []
        _open = False
        if (today in location["hours"]):
            hours = location["hours"][today]
            start = parse_time(hours[0])
            end = parse_time(hours[1])
            start_sod = second_of_day(start)
            end_sod = second_of_day(end)

            if (now_sod > start_sod) and (now_sod < end_sod):
                _open = True

                if (relative):
                    description.append("Open until %s" % hours[1])
                if (absolute):
                    description.append("Closes in %s" % time_diff(now, end))

            elif (now_sod >= end_sod):
                if (relative):
                    description.append("Closed for the day")
                if (absolute):
                    description.append("Closed %s ago" % time_diff(now, end))

            else:
                if (relative):
                    description.append("Closed until %s" % hours[0])
                if (absolute):
                    description.append("Opens in %s" % time_diff(now, start))
        elif (absolute):
            description.append("Closed today")

        print("%s: %s" % (location["name"], _open and OPEN or CLOSED))
        if (len(description) > 0):
            print("\n".join(description))
        #print("%d < %d < %d %s" % (start_sod, now_sod, end_sod, _open))
        print("")

if (__name__ == "__main__"):
    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-f", "--file", dest = "file", help = "The JSON to use",
                      metavar = "FILE", default = "isopen.json")
    parser.add_option("-a", "--abs", "--absolute", dest = "relative",
                      help = "Toggle absolute time output", default = False,
                      action = "store_true")
    parser.add_option("-r", "--rel", "--relative", dest = "absolute",
                      help = "Toggle absolute time output", default = False,
                      action = "store_true")
    (options, args) = parser.parse_args()

    main(options.file, options.relative, options.absolute)
