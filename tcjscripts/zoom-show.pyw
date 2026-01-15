#!/usr/bin/env python

import os
from PIL import Image, ImageTk, ImageGrab

import tkinter as tk
import tkinter.font
import sys
import time

kzm_home = os.environ['kzmhome']

def key(event):
    global lposn

#    if len(event.char) == 1:
    v_key = event.keysym

    if v_key == 'Escape' or v_key == 'q':
        do_exit()
    elif v_key == 'Left':
        lposn -= 100
        root.geometry('%dx%d+%d+%d' % (width, height, lposn, 0))
    elif v_key == 'Right':
        lposn += 100
        root.geometry('%dx%d+%d+%d' % (width, height, lposn, 0))

def callbackM(event):
    pass

def do_exit():
    root.destroy()
    sys.exit()

# ---------------------------

root = tk.Tk()
root.title('Zoom')

root.bind("<Button-1>", callbackM)
root.bind_all('<Key>', key)

width = 3000
#height = 865
height = 750
image = Image.open(kzm_home + os.sep + 'temp' + os.sep + 'screenshot.bmp')
image = image.resize((width, height), Image.ANTIALIAS)

global lposn
lposn = 64
root.geometry('%dx%d+%d+%d' % (width, height, lposn, 0))

photo = ImageTk.PhotoImage(image)

w = tk.Canvas(root, width=width, height=height)
w.create_image(int(width / 2), int(height / 2), image=photo)
# w.scale = 2
w.pack()

root.overrideredirect(True)   # remove upper bar
root.mainloop()
