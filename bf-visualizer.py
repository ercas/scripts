#!/usr/bin/env python3
# TODO: [ ] ,

import os, time

registers = [ 0 ]
pointer_position = 0

def render_registers(cursor):

    global registers

    labels = ""
    registers_string = ""

    print("Registers:")

    for index, value in enumerate(registers):

        if (index == pointer_position):
            registers_string = registers_string + cursor
        else:
            registers_string = registers_string + " "

        registers_string = registers_string + ("%03d " % value)
        labels = labels + (" %3d " % index)

    print(labels)
    print(registers_string)

def main(src):

    global registers
    global pointer_position

    # src is converted into a list so we can jump back in the index for loops
    instructions = list(src)
    index = 0
    step = 1
    cursor = "~"
    output = ""
    padding = str(len(str(len(src))))

    while (index < len(instructions)):

        instruction = instructions[index]

        if (instruction == ">"):
            pointer_position += 1
            cursor = ">"

            # create new register if it doesn't exist yet
            try:
                registers[pointer_position]
            except IndexError:
                registers = registers + [ 0 ]
        elif (instruction == "<"):
            pointer_position -= 1
            cursor = ">"
        elif (instruction == "+"):
            registers[pointer_position] += 1
            cursor = "+"
        elif (instruction == "-"):
            registers[pointer_position] -= 1
            cursor = "-"
        elif (instruction == "."):
            output = output + chr(registers[pointer_position])
            cursor = "v"

        # terminal clearing code from
        # https://stackoverflow.com/questions/2084508/clear-terminal-in-python/2084521#2084521
        print(chr(27) + "[2J")
        print(("Step %0" + padding + "d: {%s} %s")
                % (step, instruction, src[step:]))
        print()
        render_registers(cursor)
        print()
        print("Output: %s" % output)
        print()

        index += 1
        step += 1

        time.sleep(0.05)

main(">+++<++>-.>>+++++++>>>>>>>>>><<<<<<<<<<+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.+.+.+.+.+.+.")
