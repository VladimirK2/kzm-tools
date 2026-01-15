#!/usr/bin/env python

import os
kzm_home = os.environ['kzmhome']

# os.environ['PATH'] = kzm_home + os.sep + r'tools\py-port-34\python-3.4.4.amd64;' + os.environ['PATH']
import win32gui, win32con, win32api

import sys
sys.path.append(kzm_home + os.sep + r'runtime\lib')
import kzm_lib

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

    scr_w = 188

    list_area.delete(0, tk.END)

    with open(in_file, 'r') as f:
        cont = f.read().split('\n')

    for line in cont:

        while len(line) > scr_w:
            list_area.insert(tk.END, ' ' + line[0:scr_w])
            line = line[scr_w:]

        list_area.insert(tk.END, ' ' + line)

    posn = 0

    list_area.activate(posn)
    list_area.select_set(posn)

    return


def do_key(event):

    if event.keysym == 'Escape':
        do_exit(event)
    elif event.keysym == 'Delete':

        if r'\spam' in in_msg_file or tkinter.messagebox.askyesno("Delete", 'Delete "' + os.path.basename(in_msg_file) + '"?'):
            try:
                os.remove(in_msg_file)
                # do_exit(event)
            except:
                tkinter.messagebox.showerror('Unable to delete file')


    elif event.keysym == 'F3':
        do_exit(event)

    elif event.keysym == 'c':
        root.clipboard_clear()

    elif event.keysym == 'a':

        sel = list_area.curselection()
        if len(sel) == 0:
            return

        posn = int(sel[0])

        line = list_area.get(posn).strip()
        root.clipboard_append(line + '\n')

    return

# ---------------------------------------------

global hilite_text
hilite_text = ''

root.wm_attributes('-alpha', 0.9)

# clipbFont=tkinter.font.Font(family="Lucida Console", size=14)
clipbFont=tkinter.font.Font(family="Iosevka", size=14)
favFont=tkinter.font.Font(family="Lucida Console", size=16)

list_area = tk.Listbox(root)
list_area.config(font=clipbFont)
list_area.config(selectbackground="darkgray")
list_area.config(height=52)
list_area.config(width=684)
# list_area.config(fg="white")
list_area.config(fg="black")
# list_area.config(bg="darkcyan")
list_area.config(bg="darkgray")
# list_area.config(takefocus="off")
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

root.title('in_file')
show_list(in_file)
list_area.focus_set()


root.mainloop()
