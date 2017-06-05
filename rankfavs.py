#!/usr/bin/env python3

import collections
import csv
import os
import random

def bounded_input(msg, min_, max_):
    """ Restrict input to an integer between min_ and max_

    Args:
        msg: The string to be passed to input().
        min_: The lower bound of the input.
        max_: The upper bound of the input.

    Returns:
        A number within the bounds.

    Raises:
        Any exceptions raised by interruptions to the input() function.
    """

    try:
        response = int(input(msg))
        if (response >= min_) and (response <= max_):
            return response
        else:
            print("ERROR: input was not within range [%d, %d]" % (min_, max_))
            return bounded_input(msg, min_, max_)
    except ValueError as e:
        print("ERROR: did not input a number")
        return bounded_input(msg, min_, max_)

def main(csv_path, names, descriptions, number, comparisons):
    """ Main routine

    Args:
        csv_path: A string containing the full path to the CSV file.
        names: The name of the field containing item names.
        descriptions: The name of the field containing item descriptions.
        number: The number of favorites to isolate.
        comparisons: The number of comparisons to make during the isolation
            stage.
    """

    items = []
    nround = 0

    with open(csv_path, "r") as f:
        items = [
            {
                "name": row[names],
                "description": row[descriptions],
                "score": 0
            }
            for row in csv.DictReader(f)
        ]

    print("==== ISOLATING TOP %d" % comparisons)
    current_round = random.sample(items, comparisons)
    while (len(items) > number):

        print("== round %d (%d left):" % (nround, len(items) - number))
        for n in range(comparisons):
            item = current_round[n]
            print("%d. %s - %s" % (n, item["name"], item["description"]))
        print("%d. pass" % comparisons)
        print("")

        response = bounded_input("enter a number: ", 0, comparisons)
        if (response < comparisons):
            to_remove = current_round.pop(int(not bool(0)))
            items = [
                x for x in items
                if x is not to_remove
            ]

        current_round = random.sample(items, comparisons)
        nround += 1

        print("")

    print("==== RANKING TOP %d" % comparisons)
    rounds_left = (len(items)**2 - len(items)) / 2
    compared = []
    for x in items:
        for y in items:
            if (
                (x is not y)
                and (not x["name"] + y["name"] in compared)
                and (not y["name"] + x["name"] in compared)
            ):

                print("== round %d (%d left):" % (nround, rounds_left))
                print("0. %s - %s" % (x["name"], x["description"]))
                print("1. %s - %s" % (y["name"], y["description"]))
                print("2. pass")
                print("")

                response = bounded_input("enter a number: ", 0, 2)
                if (response == 0):
                    x["score"] += 1
                elif (response == 1):
                    y["score"] += 1

                nround += 1
                rounds_left -= 1
                compared.append(x["name"] + y["name"])

                print("")

    ranking = collections.OrderedDict(sorted(
        {
            item["name"]: item["score"]
            for item in items
        }.items(),
        key = lambda x: x[1],
        reverse = True
    ))

    print("==== RESULTS")
    for item in ranking:
        print("%s (score: %d)" % (item, ranking[item]))

def parse_err(parser, msg):
    """ optparse.OptionParser.print_help wrapper

    Args:
        parser: An optparse.OptionParser object.
        msg: The error message to display.
    """

    print("ERROR: %s\n" % msg)
    parser.print_help()

if (__name__ == "__main__"):
    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-f", "--file", dest = "csv_path",
                      help = "path to csv file",
                      metavar = "FILE")
    parser.add_option("-n", "--names", dest = "names",
                      help = "name of the column with the item names",
                      metavar = "NAME_COLUMN")
    parser.add_option("-d", "--descriptions", dest = "descriptions",
                      help = "name of the column with the item descriptions",
                      metavar = "DESCRIPTION_COLUMN")
    parser.add_option("-N", "--number", dest = "number",
                      help = "number of items to isolate as favorites",
                      metavar = "INTEGER", default = 2, type = "int")
    parser.add_option("-c", "--comparisons", dest = "comparisons",
                      help = "number of items to compare in one round during "
                             "the isolation stage",
                      metavar = "INTEGER", default = 2, type = "int")
    (options, args) = parser.parse_args()

    if (options.csv_path is None):
        parse_err(parser, "no csv file supplied")
    elif (not os.path.isfile(options.csv_path)):
        parse_err(parser, "invalid path \"%s\"" % options.csv_path)
    elif (options.names is None):
        parse_err(parser, "no name field supplied")
    elif (options.descriptions is None):
        parse_err(parser, "no description field supplied")
    elif (options.comparisons > options.number):
        parse_err(
            parser, "number of items per round (%d) exceeds target number of "
                    "favorites to isolate (%d)" % (
                        options.comparisons, options.number
                    )
        )
    else:
        main(**vars(options))
