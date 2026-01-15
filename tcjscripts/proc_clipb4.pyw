#!/usr/bin/env python

import os
kzm_home = os.environ['kzmhome']

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

try:
    s_block = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s_block.bind( ('0.0.0.0', 44882) )
except:
    print('Exiting')
    sys.exit(1)

global temp_loc
temp_loc = kzm_lib.get_location('temp')

global mark_prefix
mark_prefix = '\x06 '.encode()

root = tk.Tk()

global STATE
STATE = 1

def callbackW(hwnd, out):

    out = []
    if win32gui.IsWindowVisible(hwnd):
        window_title = win32gui.GetWindowText(hwnd)
        left, top, right, bottom = win32gui.GetWindowRect(hwnd)
        if window_title and right-left and bottom-top:
            title = window_title
            if not(title.startswith('MINGW64:') or title.endswith('- SumatraPDF')  \
            or title.endswith('Notepad++ [Administrator]') or title == 'tk'):
                win32gui.ShowWindow(hwnd, win32con.SW_MINIMIZE)

    return True

def window_set():

    global STATE
    if STATE == 1:
        home_or_office = kzm.home_or_office()

        if home_or_office == 1:
            the_width, the_height, x_posn, y_posn = 1600, 900, 313, 131  # from home
        elif home_or_office == 2:
            the_width, the_height, x_posn, y_posn = 1600, 900, 3075, 101

        hwnd_myself = win32gui.GetForegroundWindow()
        win32gui.SetForegroundWindow(hwnd_myself)

    else:
        the_width, the_height, x_posn, y_posn = 533, 694, 3064, 2885

    root.geometry('%dx%d+%d+%d' % (the_width, the_height, x_posn, y_posn))

def PressAltTab():

    ctypes.windll.user32.keybd_event(0x12, 0, 0, 0) #Alt
    ctypes.windll.user32.keybd_event(0x09, 0, 0, 0) #Tab

    # time.sleep(2) #optional : if you want to see the atl-tab overlay

    ctypes.windll.user32.keybd_event(0x09, 0, 0x0002, 0) #~Tab
    ctypes.windll.user32.keybd_event(0x12, 0, 0x0002, 0) #~Alt


def altkey(event):
    pass

def after(self, ms, func=None, *args):
    """Call function once after given time.

    MS specifies the time in milliseconds. FUNC gives the
    function which shall be called. Additional parameters
    are given as parameters to the function call.  Return
    identifier to cancel scheduling with after_cancel."""


def task():

    global mark_prefix

    try:
        clipb_cont = root.selection_get(selection="CLIPBOARD")

        if clipb_cont.strip() != '' and not('jBASE Telnetd Server Version 4.1.1' in clipb_cont)  \
            and not('START GLOBUS Y/N=' in clipb_cont) and not(r'set CLASSPATH=;C:\Temenos' in clipb_cont)  \
            and not('---R19DEV3--- 20' in clipb_cont)  \
            and not('Setting environment for using Microsoft Visual Studio' in clipb_cont):

            clipb_list = clipb_area.get(0, tk.END)

            if str.encode(clipb_cont) not in clipb_list and clipb_cont not in clipb_list:
                clipb_area.insert(0, clipb_cont.encode())

    except Exception as e:
        clipb_cont = 'Non-text data'

    root.after(5000,task)

def focus_out(event):
    clipb_area.config(selectforeground="white")
    clipb_area.config(selectbackground="gray")
    fav_area.config(selectbackground="gray")
    return

def focus_in(event):
    clipb_area.config(selectforeground="white")
    clipb_area.config(selectbackground="darkblue")
    return

def proc_line(line):
    if len(line) < 38:
        return line
    else:
        return line[0:34] + '...'

def do_min():

    root.iconify()
    PressAltTab()

    return

def callbackM(event):
    return

def do_exit(event):
    # if tkinter.messagebox.askyesno("Exit", "Exit?"):
    save_list()
    root.destroy()
    sys.exit()
    return

def callbackMiddle(event):

    global mark_prefix

    if not(tkinter.messagebox.askyesno("Clear", "Clear all non-marked items?")):
        return

    clipb_list = clipb_area.get(0, tk.END)
    clr_list = []

    cntr = -1
    for posn, item in enumerate(clipb_list):
        item_clr = clipb_area.itemcget(posn, "fg")
        clr_list.append(item_clr)

    clipb_area.delete(0, tk.END)
    for posn, item in enumerate(clipb_list):
        if clr_list[posn] == 'cyan':
            cntr += 1
            clipb_area.insert(tk.END, item)
            clipb_area.itemconfig(cntr, fg="cyan")
            clipb_area.itemconfig(cntr, selectforeground="cyan")

    return

def save_list():

    global temp_loc
    global mark_prefix

    save_file = temp_loc + os.sep + 'clipboards-4.save'

    clipb_list = clipb_area.get(0, tk.END)
    out_string = b''
    for posn, item in enumerate(clipb_list):

        item_clr = clipb_area.itemcget(posn, "fg")
        if item_clr == 'cyan':
            item = mark_prefix + item

        try:
            out_string += item.encode()
        except:
            out_string += item
        out_string += b'\x08'

    out_string = out_string[0:-1]

    with open(save_file, 'wb') as f:
        try:
            f.write(out_string)
        except Exception as e:
            print(e)
            ex_type, ex, tb = sys.exc_info()
            traceback.print_tb(tb)
            del tb
            tkinter.messagebox.showinfo('Info', 'Error saving clipboard list')

    return

def load_list():

    global temp_loc
    global mark_prefix

    try:
        with open(temp_loc + os.sep + 'clipboards-4.save', 'rb') as f:
            cont = f.read()
        if b'\x08' in cont:
            clipb_list = cont.split(b'\x08')
        else:
            clipb_list = [ cont ]

        for posn, clipb_cont in enumerate(clipb_list):
            if clipb_cont[0:2] == mark_prefix:
                clipb_area.insert(tk.END, clipb_cont[2:])
                clipb_area.itemconfig(posn, fg="cyan")
                clipb_area.itemconfig(posn, selectforeground="cyan")
            else:
                clipb_area.insert(tk.END, clipb_cont)

    except Exception as e:
        pass

    fav_file = temp_loc + os.sep + 'clipboard-fav'
    try:
        with open(fav_file, 'r') as f:
            fav_text = f.read()
            fav_area.delete(0, tk.END)
            fav_area.insert(tk.END, fav_text)

    except Exception as e:
        pass

    return

def do_key(event):

    global temp_loc
    global mark_prefix
    global STATE

    low_char = event.char.lower()
    sel = clipb_area.curselection()

    if len(sel) > 0:
        curr_posn = int(sel[0])
        a_text = clipb_area.get(curr_posn)
    else:
        curr_posn = -1
        a_text = ''

    if event.keysym == 'Escape':
        do_min()
        # do_exit(event)

    elif event.keysym == 'Delete':

#        try:
#            curr_posn = int(sel[0])
        if curr_posn > -1:
#            a_text = clipb_area.get(curr_posn)
            if tkinter.messagebox.askyesno("Delete", 'Delete "{0}"?'.format(a_text.decode('ascii', 'ignore')[0:10] + '...')):
                clipb_area.delete(curr_posn)
#        except:
#            pass

    elif event.char != '' and event.char in '1234567890':
        if a_text != '':
#            a_text = clipb_area.get(curr_posn)
            to_file = temp_loc + os.sep + 'clipboards-4-{0}.save'.format(event.char)
            with open(to_file, 'wb') as f:
                f.write(a_text)

    elif low_char == 'x':
         do_exit(event)

    elif low_char == '-':
         callbackMiddle(event)

    elif low_char == 'q':
         do_min()

    elif low_char == 's':
         save_list()

    elif low_char == 'u' and curr_posn > 0:   # up
        a_text = clipb_area.get(curr_posn)
        clipb_area.delete(curr_posn)
        clipb_area.insert(curr_posn-1, a_text)
        clipb_area.itemconfig(curr_posn-1, fg="cyan")
        clipb_area.itemconfig(curr_posn-1, selectforeground="cyan")
        clipb_area.selection_set(curr_posn-1)

    elif low_char == 'd' and curr_posn > -1:   # down
        a_text = clipb_area.get(curr_posn)
        clipb_area.delete(curr_posn)
        clipb_area.insert(curr_posn+1, a_text)
        clipb_area.itemconfig(curr_posn+1, fg="cyan")
        clipb_area.itemconfig(curr_posn+1, selectforeground="cyan")
        clipb_area.selection_set(curr_posn+1)

    elif low_char == 'm':

#        sel = clipb_area.curselection()
        if len(sel) == 0:
            return

        curr_posn = int(sel[0])
        a_text = clipb_area.get(curr_posn)

        item_clr = clipb_area.itemcget(curr_posn, "fg")

        if item_clr == 'cyan':
            to_hilite = False
        else:
            to_hilite = True

        clipb_area.delete(curr_posn)
        clipb_area.insert(curr_posn, a_text)
        clipb_area.activate(curr_posn)
        clipb_area.selection_set(curr_posn)

        if to_hilite:
            clipb_area.itemconfig(curr_posn, fg="cyan")
            clipb_area.itemconfig(curr_posn, selectforeground="cyan")
        else:
            clipb_area.itemconfig(curr_posn, fg="white")
            clipb_area.itemconfig(curr_posn, selectforeground="white")

    elif low_char == 'g':  # go - for http://etc

        if len(sel) == 0:
            return

        curr_posn = int(sel[0])
        url = clipb_area.get(curr_posn).decode()
        if url[0:2] == mark_prefix:
            url = url[2:]
        do_min()
        os.system('"' + kzm_home + r'\tools\Mozilla Firefox\firefox.exe" ' + url)

    elif low_char == 'c' or event.keysym == 'asterisk':  # copy to clipboard - current line or default string

#        sel = clipb_area.curselection()

        if low_char == 'c':
            if len(sel) == 0:
                return

            curr_posn = int(sel[0])
            old_text = clipb_area.get(curr_posn)

            if old_text[0:2] == mark_prefix:
                a_text = old_text[2:]
            else:
                a_text = old_text
        else:
            a_text = b'   '

        f_cl_temp = temp_loc + os.sep + 'clipb.tmp'
        with open(f_cl_temp, 'w') as f:
            f.write(a_text.decode())

        os.system('type {0} | clip'.format(f_cl_temp))

        # PressAltTab()

        root.after(100, do_min, event)
        # do_min()

    return

def set_clipb(data):

    strcpy = ctypes.cdll.msvcrt.strcpy
    ocb = ctypes.windll.user32.OpenClipboard    # Basic clipboard functions
    ecb = ctypes.windll.user32.EmptyClipboard
    gcd = ctypes.windll.user32.GetClipboardData
    scd = ctypes.windll.user32.SetClipboardData
    ccb = ctypes.windll.user32.CloseClipboard
    ga = ctypes.windll.kernel32.GlobalAlloc    # Global memory allocation
    gl = ctypes.windll.kernel32.GlobalLock     # Global memory Locking
    gul = ctypes.windll.kernel32.GlobalUnlock
    GMEM_DDESHARE = 0x2000

    ocb(None) # Open Clip, Default task
    ecb()
    hCd = ga(GMEM_DDESHARE, len(bytes(data,"ascii")) + 1)  # TypeError: encoding or errors without a string argument
    pchData = gl(hCd)
    strcpy(ctypes.c_char_p(pchData), bytes(data, "ascii"))
    gul(hCd)
    scd(1, hCd)
    ccb()

root.wm_attributes('-alpha', 0.8)

clipbFont=tkinter.font.Font(family="Iosevka", size=14, slant="italic")
favFont=tkinter.font.Font(family="Lucida Console", size=16)

clipb_area = tk.Listbox(root)
clipb_area.config(font=clipbFont)
clipb_area.config(selectbackground="darkblue")
clipb_area.config(height=43)
clipb_area.config(width=384)
clipb_area.config(fg="white")
clipb_area.config(bg="black")
clipb_area.pack()

fav_area = tk.Listbox(root)
fav_area.config(font=favFont)
fav_area.config(selectbackground="darkblue")
fav_area.config(height=1)  # to avoid the gray bg at the bottom
fav_area.config(width=384)
fav_area.config(borderwidth=1)
fav_area.config(fg="yellow")
fav_area.config(bg="black")
fav_area.pack(ipady=2)

# root.overrideredirect(True)   # remove upper bar
root.title('Clipboard manager')

window_set()

root.bind_all('<Alt_L>', altkey)
root.bind("<Double-Button-1>", do_exit)
# root.bind("<Button-1>", callbackM)
root.bind("<Button-3>", callbackMiddle)
# root.bind("<Double-Button-1>", callbackMiddle)
root.bind("<Key>", do_key)
root.bind("<FocusOut>", focus_out)
root.bind("<FocusIn>", focus_in)
load_list()

try:
    if sys.argv[1] == '-a':
        task()
        save_list()
        root.destroy()
        sys.exit()
except:
    pass

root.after(10,task)
clipb_area.focus_set()
clipb_area.selection_set(0)
root.mainloop()
