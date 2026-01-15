#!/usr/bin/env python

import os
kzm_home = os.environ['kzmhome']

# os.environ['PATH'] = kzm_home + os.sep + r'tools\py-port-34\python-3.4.4.amd64;' + os.environ['PATH']
import win32gui, win32con, win32api

import sys
sys.path.append(kzm_home + os.sep + r'runtime\lib')
import kzm_lib
import kzm

import tkinter as tk

import time
import tkinter.font
import tkinter.messagebox
import traceback
import ctypes
from shutil import copyfile
import socket
from pathlib import Path
import sqlite3

try:
    s_block = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s_block.bind( ('0.0.0.0', 44887) )
except:  # 2nd copy...
    print('Exiting')
    sys.exit(1)

temp_loc = os.environ['kzmhome'] + os.sep + 'temp'
root = tk.Tk()

def window_set():

    home_or_office = kzm.home_or_office()

    if home_or_office == 1:
        the_width, the_height, x_posn, y_posn = 1860, 1045, 55, 0  # from home
    elif home_or_office == 2:
        the_width, the_height, x_posn, y_posn = 1860, 1045, 2995, 0
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
#    list_area.config(selectforeground="white")
    list_area.config(selectbackground="brown")
    return

def focus_in(event):
#    list_area.config(selectforeground="white")
    list_area.config(selectbackground="darkblue")
    return

def callbackDM(event):

    return

def do_exit(event):

    root.destroy()
    sys.exit()

    return

def callbackM(event):

    return

def callbackMiddle(event):

    return

def show_list(item_list, hilite_text):

    global seen_files_list
    list_area.delete(0, tk.END)

    cnt = 0

    for line in item_list:

        if hilite_text == '':
            list_area.insert(tk.END, line)
            cnt += 1
            if line in seen_files_list:
                list_area.itemconfig(tk.END, fg="cyan")
                list_area.itemconfig(tk.END, selectforeground="cyan")
        else:
            if hilite_text.lower() in line.lower():
                list_area.insert(tk.END, line)
                cnt += 1
                if line in seen_files_list:
                    list_area.itemconfig(tk.END, fg="cyan")
                    list_area.itemconfig(tk.END, selectforeground="cyan")


    root.title(hilite_text + ' ::: ' + str(cnt) + ' files')

    posn = 0

    list_area.activate(posn)
    list_area.select_set(posn)

    return

def load_files():

    global hilite_text
    global seen_files_list
    item_list = []

    conn = sqlite3.connect(temp_loc + os.sep + 'seenfiles.sqlite')
    conn.execute('''CREATE TABLE IF NOT EXISTS FILES_SEEN
             (ID VARCHAR(240) PRIMARY KEY NOT NULL);''')

    seen_files_list = []
    try:
        cursor = conn.execute("SELECT id from FILES_SEEN;")
        for row in cursor:
            seen_files_list.append(row[0])
    except:
        pass
    conn.close()
#    print('{}'.format(seen_files_list))

#    fldrs_list = [r'\\servdevtem\temenos\logs\email', r'c:\temenos\kzm\arc\not-to-backup', r'c:\temenos\kzm\dev', r'c:\temenos\kzm\info', r'c:\temenos\kzm\runtime', r'c:\temenos\kzm\setup', r'c:\temenos\kzm\t24.dev'  ]
    fldrs_list = [r'\\servutils2\temenos\log\email', r'c:\temenos\kzm\arc\not-to-backup', r'c:\temenos\kzm\dev', r'c:\temenos\kzm\info', r'c:\temenos\kzm\runtime', r'c:\temenos\kzm\setup', r'c:\temenos\kzm\t24.dev'  ]

    for f_posn, fldr in enumerate(fldrs_list):

        for root_dir, dirnames, filenames in os.walk(fldr):

            for filename in filenames:
                if not os.sep + '.git' in root_dir:
                    if f_posn == 0:   # freshest emails - to the top
                        item_list.insert(0, root_dir + os.sep + filename)
                    else:
                        item_list.append(root_dir + os.sep + filename)


    show_list(item_list, hilite_text)

def get_item():

    sel = list_area.curselection()
    if len(sel) == 0:
        return 0, ''

    posn = int(sel[0])
    line = list_area.get(posn).strip()
    return posn, line


def do_key(event):

    global hilite_text

    if event.keysym == 'Return':

        posn, file_spec = get_item()
        if file_spec == '':
            return

        try:
            conn = sqlite3.connect(temp_loc + os.sep + 'seenfiles.sqlite')
            conn.execute('INSERT INTO FILES_SEEN (ID) VALUES ( "{0}" );'.format(file_spec))
            conn.commit()
            conn.close()
        except:
            pass

        os.system(r'start C:\temenos\kzm\tools\cudatext\cudatext.exe {0}'.format(file_spec))
        do_exit(event)

    if event.keysym == 'F3':

        posn, line = get_item()
        os.system(r'pythonw {0} {1}'.format(sys.path[0] + os.sep + 'file-viewer.pyw', line))


    elif event.char == event.keysym and event.char in r'0123456789qwertyuiopasdfghjklzxcvbnm'   or event.keysym in [ 'period', 'minus', 'backslash', 'underscore' ]:

        hilite_text += event.char

        item_list = list_area.get(0, tk.END)
        show_list(item_list, hilite_text)

    elif event.keysym == 'space':
        # print('"{0}"'.format(event.keysym))
        hilite_text = ''
        load_files()

    elif event.keysym == 'Delete':
        posn, file_spec = get_item()
        if file_spec == '':
            return

        if tkinter.messagebox.askyesno("Delete", 'Delete "' + os.path.basename(file_spec) + '"?'):
            try:
                os.remove(file_spec)
                # do_exit(event)
            except:
                tkinter.messagebox.showerror('Unable to delete file')

        load_files()

    elif event.keysym == 'Escape':

        do_exit(event)

    return

def do_bs(event):

    global hilite_text
    if len(hilite_text) == 0:
        return

    hilite_text = hilite_text[0:-1]
    load_files()

    return

# ---------------------------------------------

global hilite_text
hilite_text = ''

root.wm_attributes('-alpha', 0.9)

clipbFont=tkinter.font.Font(family="iosevka", size=14)  #, slant="italic")
favFont=tkinter.font.Font(family="Lucida Console", size=16)

list_area = tk.Listbox(root)
list_area.config(font=clipbFont)
list_area.config(selectbackground="darkblue")
list_area.config(height=52)
list_area.config(width=384)
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

root.bind_all('<Alt_L>', altkey)
root.bind("<Double-Button-1>", callbackDM)
root.bind("<Button-1>", callbackM)
root.bind("<Button-2>", callbackMiddle)
root.bind("<Button-3>", do_exit)
root.bind("<Key>", do_key)
# root.bind("<Space>", do_space)
root.bind("<FocusOut>", focus_out)
root.bind("<FocusIn>", focus_in)
# root.bind("<Control_L>", tab_op)
# root.bind("<Return>", ret_op)
# root.bind("<Control_R>", ret_op)
root.bind("<BackSpace>", do_bs)
#root.wm_attributes('-alpha', 0.5)

# root.option_add('*Dialog.msg.font', 'Helvetica 18')

load_files()
# window_set()
# win32api.keybd_event(0x20, 0, 0, 0)
list_area.focus_set()
list_area.config(fg="white")
list_area.config(bg="dark slate gray")
#list_area.config(selectforeground="white")
#list_area.config(selectbackground="darkblue")
# root.after(3000, task)
root.title('')
root.mainloop()
