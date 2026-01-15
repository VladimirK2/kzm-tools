#!/usr/bin/env python
# 2020-01-10 12:30 ported to Python 3 (v5)

import sys

from reportlab.pdfgen.canvas import Canvas
from reportlab.lib.units import cm, mm, inch, pica
from reportlab.lib.pagesizes import A4, landscape

def begin(left, bottom):
    rhyme = pdf.beginText(inch * left, inch * bottom)
    return (rhyme)

if len(sys.argv) < 2:
    print("Usage: <script> textfile [outfile.pdf]")
    sys.exit()

v_line_no = 0

file_cont = open(sys.argv[1], 'rb').read()
line_width = 136
ext_width = 150
page_len = 61
font_size = 8
FF = chr(12).encode()

if len(sys.argv) > 2:
    f_out = sys.argv[2]
else:
    f_out = sys.argv[1] + '.pdf'

while FF + FF in file_cont:
    file_cont = file_cont.replace(FF + FF, FF)

file_cont = file_cont.replace(chr(13).encode(), b'').replace(b'\xfe', b'\n')

lines_list = file_cont.split(b'\n')

# Proceed FFs - put them at separate lines
new_lines_list = []

for line in lines_list:
    if FF in line:
       temp = line.rstrip().split(FF)

       if len(temp) == 2 and temp[0] != '':  # text before and after FF
           new_lines_list.append(temp[0])
           new_lines_list.append(FF)
           new_lines_list.append(temp[1])

       elif len(temp) == 2:  # text  after FF
           new_lines_list.append(FF)
           new_lines_list.append(temp[1])

       else:                   # standalone FF
           new_lines_list.append(FF)

    else:
       new_lines_list.append(line)

if new_lines_list[0] == FF:
    new_lines_list = new_lines_list[1:]

# count pages size and add FFs if necessary
latest_lines_list = []
num = 0

max_len = 0
for line in new_lines_list:
    num += 1
    if num > page_len:
        latest_lines_list.append(FF)
        num = 0
    if line == FF:
        num = 0
    latest_lines_list.append(line)
    line_len = len(line)
    if max_len < line_len:
        max_len = line_len

# TODO long lines - create a wrap? we have up to 174 chars...

left, bottom = 1.8, 8.1
if max_len > line_width:
    left = 1
if max_len > ext_width:
    left = 0.1

pdf = Canvas(f_out, pagesize=landscape(A4))
rhyme = begin(left, bottom)
pdf.setFont("Courier", font_size)


for line in latest_lines_list:
    if line == FF:
        pdf.drawText(rhyme)
        pdf.showPage()
        rhyme = begin(left, bottom)
        pdf.setFont("Courier", font_size)
    else:
        rhyme.textLine(line)

pdf.drawText(rhyme)
pdf.showPage()
pdf.save()
