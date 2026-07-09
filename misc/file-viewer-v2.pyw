#!/usr/bin/env python

import os
import sys

import tkinter as tk

import time
import tkinter.font
import tkinter.messagebox
import traceback
import ctypes
from shutil import copyfile
import socket
from pathlib import Path

in_file = sys.argv[1]
try:
    in_msg_file = sys.argv[2]
except:
    in_msg_file = ''

root = tk.Tk()

def window_set():

    the_width, the_height, x_posn, y_posn = 1676, 920, 234, 130
    root.geometry('%dx%d+%d+%d' % (the_width, the_height, x_posn, y_posn))

def altkey(event):
    pass

def after(self, ms, func=None, *args):
    """Call function once after given time.

    MS specifies the time in milliseconds. FUNC gives the
    function which shall be called. Additional parameters
    are given as parameters to the function call.  Return
    identifier to cancel scheduling with after_cancel."""


def focus_out(event):
    list_area.config(selectforeground="white")
    list_area.config(selectbackground="brown")
    return

def focus_in(event):
    list_area.config(selectforeground="blue")
    list_area.config(selectbackground="darkgray")
    return

def do_exit(event):

    root.destroy()
    sys.exit()

    return

def show_list(in_file):

    list_area.delete(0, tk.END)

    with open(in_file, 'r') as f:
        cont = f.read().split('\n')

    for line in cont:
        list_area.insert(tk.END, line)

    try:
        with open(r'clipb_list_posn', 'r') as f:
            last_posn = int(f.read())
    except:
        last_posn = 0

    # list_area.bind("<<ListboxSelect>>", showSelected)

    list_area.activate(last_posn)
    list_area.select_set(last_posn)

    return


def do_key(event):

    global clipbQ

    if event.keysym == 'Escape':
        allCont = list_area.get(0, tk.END)
        with open(in_file, 'w') as f:
            f.write('\n'.join(allCont))

        sel = list_area.curselection()
        if len(sel) != 0:
            posn = int(sel[0])
            with open(r'clipb_list_posn', 'w') as f:
                f.write(str(posn))

        do_exit(event)

    # elif event.keysym == 'Space':
        # root.clipboard_clear()
        # root.clipboard_append('')

    elif event.keysym == 'Delete':
        sel = list_area.curselection()
        if len(sel) == 0:
            return
        posn = int(sel[0])
        list_area.delete(posn)

        list_area.event_generate("<Up>")

    elif event.keysym == 'Return':

        sel = list_area.curselection()
        if len(sel) == 0:
            return

        posn = int(sel[0])

        line = list_area.get(posn).strip()

        clipbQ += 1
        if clipbQ == 1:
            root.clipboard_append(line)
        else:
            root.clipboard_append('\n' + line)

    return

def arrow(event):
    list_area.event_generate("<Space>")
    # root.after(200, arrow)
# ---------------------------------------------

global clipbQ
clipbQ = 0

root.wm_attributes('-alpha', 0.9)

clipbFont=tkinter.font.Font(family="Lucida Console", size=16)
# clipbFont=tkinter.font.Font(family="Iosevka", size=14)
# clipbFont=tkinter.font.Font(family="Courier", size=18)

list_area = tk.Listbox(root)
list_area.config(font=clipbFont)
list_area.config(selectbackground="darkgray")
list_area.config(height=52)
list_area.config(width=684)
# list_area.config(fg="white")
list_area.config(fg="black")
# list_area.config(bg="darkcyan")
list_area.config(bg="darkgray")
# list_area.config(selectmode="tk.SINGLE")
# list_area.extra = 'list'
list_area.pack()

# root.overrideredirect(True)   # remove upper bar

window_set()

# https://www.python-course.eu/tkinter_events_binds.php

# root.bind_all('<Alt_L>', altkey)
root.bind("<Double-Button-1>", do_exit)
root.bind("<Key>", do_key)
root.bind("<FocusOut>", focus_out)
root.bind("<FocusIn>", focus_in)

root.title(in_file)
show_list(in_file)
list_area.focus_set()


# root.after(300, arrow)
root.mainloop()
