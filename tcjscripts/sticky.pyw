#!/usr/bin/env python

import os
import sys

import tkinter as tk

import time
import tkinter.font
import tkinter.messagebox
import traceback
import calendar
import re
import subprocess
import socket

try:
    s_block = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s_block.bind( ('0.0.0.0', 44881) )
except:
    print('Exiting')
    sys.exit(1)

def focus_out(event):
    for nr in range(0,9):
        w.itemconfig(rect_obj[nr], fill="#44637a")
    return

def focus_in(event):

    for nr in range(0,9):
        try:
            with open(r'C:\temenos\kzm\setup\sticky\s_note_{0}.ini'.format(nr), 'r') as f:
                ini_text = f.read()
                lvl_no = int(ini_text.split('=')[1])

        except:
            lvl_no = 2

        w.itemconfig(rect_obj[nr], fill=clr_list[lvl_no])

    return

def run_cmd(cmd_list):
    p = subprocess.Popen(cmd_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    std_out, std_err = p.communicate()
    return p.returncode, std_out

def motion(event):
    global mouse_x
    global mouse_y

    mouse_x, mouse_y = event.x, event.y

def key(event):

    global edit_mode
    global rect_obj
    global rects
    global mouse_x
    global mouse_y

    if len(event.char) == 1:
        v_key = event.keysym

        if v_key == 'Escape':
            if edit_mode:  # cancel
                edit_mode = False
                w.create_window(0,0, width=100, height=100, window=editor, state="hidden")
            else:
                do_exit(event)

        elif event.char in [ '1', '2', '3', '4', '5' ] and not edit_mode:

            x, y = mouse_x, mouse_y   # can't use event.x and event.y - breaks after editing

            # print(x, y)

            for posn, ( x1, y1, x2, y2 ) in enumerate(rects):
                if x > x1 and x < x2 and y > y1 and y < y2:
                    slot_num = posn  # slot_no is global, don't touch it

                    lvl_no = int(event.char) - 1
                    w.itemconfig(rect_obj[slot_num], fill=clr_list[lvl_no])
                    w.itemconfig(slots[slot_num], fill=fgr_list[lvl_no])

                    with open(r'C:\temenos\kzm\setup\sticky\s_note_{0}.ini'.format(slot_num), 'w') as f:
                        f.write('level={0}'.format(lvl_no))

                    break

def altkey(event):
    pass

def callbackM(event):

    global edit_mode
    global rects
    global slot_no
    global contents

    if edit_mode:

        note_text = editor.get(1.0, tk.END).replace('\r', '')

        while '\n\n' in note_text:
            note_text = note_text.replace('\n\n', '\n')

        if note_text.endswith('\n'):
            note_text = note_text[0:-1]

        # print(note_text)
        with open(r'C:\temenos\kzm\setup\sticky\s_note_{0}.txt'.format(slot_no), 'w') as f:
            f.write(note_text)

        contents[slot_no] = note_text

        edit_mode = False
        w.create_window(0,0, width=100, height=100, window=editor, state="hidden")

        displ_text = displtext(note_text)

        w.itemconfig(slots[slot_no], text = displ_text)

        if displ_text == '':
            w.itemconfig(rect_obj[slot_no], fill=clr_list[2])  # yellow
            with open(r'C:\temenos\kzm\setup\sticky\s_note_{0}.ini'.format(slot_no), 'w') as f:
                f.write('level={2}')

        return

    x, y = event.x, event.y

    # print(x, y)

    for posn, ( x1, y1, x2, y2 ) in enumerate(rects):
        if x > x1 and x < x2 and y > y1 and y < y2:
            slot_no = posn

            a_shift = 18

            w.create_window(x1 + (x2 - x1) / 2, y1 + (y2 - y1) / 2, width = x2 - x1 - a_shift, height=y2 - y1 - a_shift, window=editor)

            editor.delete(1.0, tk.END)
            editor.insert(tk.END, contents[slot_no])

            edit_mode = True

            editor.focus_set()

    return

def displtext(text):

    displ_text = text[0:136].split('\n')
    if len(displ_text) > 8:
        displ_text = displ_text[0:7]
        displ_text.append('...')

    return '\n'.join(displ_text)

def do_exit(event):
    # if tkinter.messagebox.askyesno("Exit", "Quit the program?"):
    root.destroy()
    sys.exit()

def init():

    global slots
    global rects
    global contents
    global rect_obj
    slots, rects, contents, rect_obj = [], [], [], []

    align = 25
    size_x = (the_width - align * 4) / 3
    size_y = (the_height - align * 4) / 3

    sl_no = -1

    for y in range(0, 3):
        for x in range(0, 3):

            x1 = align + (size_x + align) * x
            y1 = align + (size_y + align) * y
            x2 = (align + size_x) * (x + 1)
            y2 = (align + size_y) * (y + 1)

            rects.append(( x1, y1, x2, y2 ))

            sl_no += 1
            try:
                with open(r'C:\temenos\kzm\setup\sticky\s_note_{0}.ini'.format(sl_no), 'r') as f:
                    ini_text = f.read()
                    lvl_no = int(ini_text.split('=')[1])

            except:
                lvl_no = 2

            rect_obj.append(w.create_rectangle(x1, y1, x2, y2, fill=clr_list[lvl_no]))

# 17x8 = 136
            try:
                with open(r'C:\temenos\kzm\setup\sticky\s_note_{0}.txt'.format(sl_no), 'r') as f:
                    sl_text = f.read()
            except:
                sl_text = ''

            contents.append(sl_text)

            displ_text = displtext(sl_text)

            slots.append(w.create_text(align + (size_x + align) * x + 14, align + (size_y + align) * y + 14, text=displ_text, fill=fgr_list[lvl_no], anchor="nw", font=def_font, width=size_x - 20))


    return

# -------------------------------------------------------------------
clr_list = [ 'cyan', 'green', 'yellow', 'orange', 'red' ]
fgr_list = [ 'black', 'yellow', 'black', 'black', 'yellow' ]

root = tk.Tk()

def_font = tkinter.font.Font(family="Lucida Console", size=18)

# root.wm_attributes('-alpha', 0.01)
root.wm_attributes('-alpha', 0.7)

# customFont=tkinter.font.Font(family="Helvetica", size=64)
# smallerFont=tkinter.font.Font(family="Helvetica", size=18)
# evensmallerFont=tkinter.font.Font(family="Lucida Console", size=12, weight="bold")
# clipbFont=tkinter.font.Font(family="Lucida Console", size=12, slant="italic")
# calFont=tkinter.font.Font(family="Lucida Console", size=16)

root.overrideredirect(True)   # remove upper bar

#x_posn, y_posn, the_width, the_height = 80, 5, 900, 775   $ from home
x_posn, y_posn, the_width, the_height = 160, 95, 900, 775
root.geometry('%dx%d+%d+%d' % (the_width, the_height, x_posn, y_posn))

w = tk.Canvas(root, width=the_width, height=the_height, bg="#44637a")
w.pack()

editor = tk.Text(root, font=def_font, width=17, height=24, wrap="word")
edit_mode = False

root.bind_all('<Alt_L>', altkey)
root.bind("<Button-3>", callbackM)
root.bind("<Double-Button-1>", do_exit)
root.bind_all('<Key>', key)
root.bind('<Motion>', motion)

root.bind("<FocusOut>", focus_out)
root.bind("<FocusIn>", focus_in)

root.after(10, init)

root.mainloop()
