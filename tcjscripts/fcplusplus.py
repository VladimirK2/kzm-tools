#!/usr/bin/env python
# fc-like tool with better visibility for long lines
# plus-plus: with contents sorting

import sys
import msvcrt
from ctypes import windll, create_string_buffer

def get_width():

    h = windll.kernel32.GetStdHandle(-12)
    csbi = create_string_buffer(22)
    res = windll.kernel32.GetConsoleScreenBufferInfo(h, csbi)

    if res:
        import struct
        (bufx, bufy, curx, cury, wattr,
         left, top, right, bottom, maxx, maxy) = struct.unpack("hhhhHhhhhhh", csbi.raw)
        sizex = right - left + 1
        sizey = bottom - top + 1
    else:
        sizex, sizey = 80, 25 # can't determine actual size - return default values

    return sizex

def pause_proc():
#    var = raw_input("Input Q to exit or anything else to continue\n")
    print('-----> press Q to exit, N for next line, any other key to continue')
    input_char = msvcrt.getch()
    # print(input_char)
    if input_char.upper() == b'Q':
        sys.exit()
    elif input_char.upper() == b'N':
        return True
    return False

def show_diff(line_nr, extr_posn):
    start_posn = extr_posn-9
    if start_posn < 1:
        start_posn = 1
    left_cut = start_posn-1
    right_cut = left_cut + sizex - 3
    print('Line ' + str(line_nr) + ', showing from position ' + str(start_posn) + ':')
    print('|' + line_one[left_cut:right_cut] + '|')
    print('|' + line_two[left_cut:right_cut] + '|')
    ret = pause_proc()

    extr_posn += sizex - 5  # don't show what'a already shown
    if ret:
        extr_posn = 100000000
    return extr_posn

# -------------------------------------------------------------
if len(sys.argv) < 3:
    print('Usage:', sys.argv[0], 'file1 file2 [n]')
    sys.exit()

do_sort = True

if len(sys.argv) > 3:
    start_from = int(sys.argv[3])
else:
    start_from = 1

all_lines_1, all_lines_2 = [], []

v_file_in_1 = open(sys.argv[1], "r")
v_file_in_2 = open(sys.argv[2], "r")

for line in v_file_in_1:
    if do_sort:
        if line.strip() == '':
            continue
    all_lines_1.append(line)
v_file_in_1.close()

for line in v_file_in_2:
    if do_sort:
        if line.strip() == '':
            continue
    all_lines_2.append(line)
v_file_in_2.close()

if do_sort:
    all_lines_1 = sorted(all_lines_1)
    all_lines_2 = sorted(all_lines_2)

sizex = get_width()
line_nr = start_from - 1

len_1 = len(all_lines_1)
len_2 = len(all_lines_2)

while True:

    line_nr += 1
    if line_nr > len_1 and line_nr <= len_2:
        print('File 2 is longer')
        ret = pause_proc()
        sys.exit()

    if line_nr > len_2 and line_nr <= len_1:
        print('File 1 is longer')
        ret = pause_proc()
        sys.exit()

    if line_nr > len_1 and line_nr > len_2:
        print('Finished')
        sys.exit()

    line_one = all_lines_1[line_nr-1].encode('ascii', 'backslashreplace').decode()
    line_two = all_lines_2[line_nr-1].encode('ascii', 'backslashreplace').decode()

    line_one = line_one.replace('\n', '').replace('\r', '')  # [0:-8]      #   !!!!! use only for comparing liquidation data w/different migration date!
    line_two = line_two.replace('\n', '').replace('\r', '')  # [0:-8]

#    if ignore_fld > -1:
#        spl = line_one.split('|')
#        spl[ignore_fld] = ''
#        line_one = '|'.join(spl)
#        spl = line_two.split('|')
#        spl[ignore_fld] = ''
#        line_two = '|'.join(spl)

    if line_one == line_two:
        continue

# could use difflib but I think it's rather simple case...
# show each difference separately; screen width matters
    extr_posn = -1
    for posn in range (0, len(line_one)):

        extr_posn += 1
        char = line_one[extr_posn:extr_posn+1]
        char2 = line_two[extr_posn:extr_posn+1]
        if char2 == '' and char != '':
            print('In file 1 this line is longer:')
            extr_posn = show_diff(line_nr, extr_posn)
            break

        if char2 != char:
            extr_posn = show_diff(line_nr, extr_posn)

    extr_posn += 1
    char2 = line_two[extr_posn:extr_posn+1]
    if char2 != '':
        print('In file 2 this line is longer:')
        extr_posn = show_diff(line_nr, extr_posn)
