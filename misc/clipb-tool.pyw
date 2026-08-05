#!/usr/bin/env python

# 1 parameter - file with accumulated clipboard contents. How to get it?
# in AutoHotKey:

# OnClipboardChange MyClipb

# MyClipb(dataType)
    # {
    # if dataType = 1
        # {

        # Text := FileRead("\home\kzm\clipb.txt")
        # clipb := a_clipboard
        # FoundPos := InStr("`r`n" Text "`r`n", "`r`n" Clipb "`r`n")
        # if FoundPos = 0
            # {
            # FileAppend A_Clipboard "`r`n", "\home\kzm\clipb.txt"
            # }
        # }
    # return
    # }

# Del     - remove current line
# *       - remove empty lines
# -       - remove all below current line
# Enter   - put current line to clipboard
# Enter again - add current line to clipboard
# Esc - exit and save changes
# if a line is what's in clipboard, it's highlighted

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

def slash():
    list_area.event_generate("<slash>")

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
        with open(r'D:\Users\x594822\dev\kzm\runtime\clipb_list_posn', 'r') as f:
            last_posn = int(f.read())
    except:
        last_posn = 0

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
            with open(r'D:\Users\x594822\dev\kzm\runtime\clipb_list_posn', 'w') as f:
                f.write(str(posn))

        do_exit(event)

    elif event.keysym == 'Delete':
        sel = list_area.curselection()
        if len(sel) == 0:
            return
        posn = int(sel[0])
        list_area.delete(posn)

        list_area.event_generate("<Up>")

    elif event.keysym == 'minus':   # remove all down

        sel = list_area.curselection()
        if len(sel) == 0:
            return

        reply = tkinter.messagebox.askyesnocancel(title='!!!', message='Delete all data below?')
        if reply != True:
            return

        posn = int(sel[0])
        all = list_area.get(0, tk.END)

        list_area.delete(0, tk.END)

        for iline, line in enumerate(all):
            if iline <= posn :
                list_area.insert(tk.END, line)

    elif event.keysym == 'slash':   # show what's in clipboard (automated)

        try:
            clipb_cont = root.clipboard_get()
            all = list_area.get(0, tk.END)
            for posn, line in enumerate(all):
                if line == clipb_cont:
                    list_area.itemconfig(posn, {'fg': 'yellow', 'bg': 'blue'})
                else:
                    list_area.itemconfig(posn, {'fg': 'black', 'bg': 'darkgray'})

        except:
            null

    elif event.keysym == 'asterisk':   # remove all empty ones

        all = list_area.get(0, tk.END)

        list_area.delete(0, tk.END)

        for line in all:
            if line != '':
                list_area.insert(tk.END, line)

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

        list_area.event_generate("<slash>")
    return

# ---------------------------------------------

global clipbQ
clipbQ = 0

root.wm_attributes('-alpha', 0.9)

clipbFont=tkinter.font.Font(family="Lucida Console", size=16)

list_area = tk.Listbox(root)
list_area.config(font=clipbFont)
list_area.config(selectbackground="darkgray")
list_area.config(height=52)
list_area.config(width=684)
list_area.config(fg="black")
list_area.config(bg="darkgray")
list_area.pack()

window_set()

# https://www.python-course.eu/tkinter_events_binds.php

root.bind("<Double-Button-1>", do_exit)
root.bind("<Key>", do_key)
root.bind("<FocusOut>", focus_out)
root.bind("<FocusIn>", focus_in)

root.title(in_file)
show_list(in_file)
list_area.focus_set()

root.after(100, slash)

root.mainloop()
