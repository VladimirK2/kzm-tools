import sys

import tkinter as tk
from tkinter.constants import *

def do_exit(event):
    sys.exit()

def scroll_start(event=None):
    canvas.scan_mark(event.x, event.y)

def scroll_move(event=None):
    canvas.scan_dragto(event.x, event.y, gain=1)

global img

canvas = tk.Canvas(width=1000, height=400, bg='black')
img = tk.PhotoImage(file=sys.argv[1])

canvas.pack(expand=YES, fill=BOTH)

canvas.configure(width=img.width(), height=img.height(), scrollregion=(0,0,img.width(),img.height()))
canvas.create_image(0, 0, image=img, anchor=NW)

canvas.bind("<ButtonPress-1>", scroll_start)
canvas.bind("<B1-Motion>", scroll_move)

canvas.bind("<Escape>", do_exit)

canvas.focus_set()
tk.mainloop()
