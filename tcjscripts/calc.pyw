#!/usr/bin/env python

from __future__ import division
import os

from tkinter import *
import sys
import time

def copy_res():
   v_result = status_var.get()
   root.clipboard_clear()
   root.clipboard_append(v_result)

def calc():
   v_expr = command_var.get()
   try:
       v_result = eval(v_expr)
   except Exception as e:
       v_result = 'Error in expression'
   status_var.set(v_result)

def key(event):
    if event.char == event.keysym:
        pass

    elif len(event.char) == 1:
        v_key = event.keysym
        
        if v_key == 'Escape':
            root.destroy()
            sys.exit()
            pass
        
        elif v_key == 'Return':
           calc()
    else:
        pass

def callbackM(event):
    pass
#    if root.winfo_x() < 0:
#        root.geometry('656x65+30+0')  # click to put it into view

def do_hide():
    root.geometry('696x65-%d+%d' % (root.winfo_screenwidth()-2000, 30))

def do_exit():
    root.destroy()
    sys.exit()


###################################################

root = Tk()
root.title('Calculator')

command_button = Button(root, text='Calc', fg="blue", font='Helvetica 10 bold', command=calc)
command_button.grid(row=0, column=2, sticky=E)

command_button = Button(root, text='Copy', fg="blue", font='Helvetica 10', command=copy_res)
command_button.grid(row=1, column=0, sticky=W)

command_button = Button(root, text='Exit', fg="blue", font='Helvetica 10', command=do_exit)
command_button.grid(row=1, column=1, sticky=E)

command_button = Button(root, text='Hide', fg="blue", font='Helvetica 10', command=do_hide)
command_button.grid(row=1, column=2)

command_var = StringVar()
s_command = Entry(root, font='Courier 9 bold', width=80, textvariable=command_var)
s_command.grid(row=0, column = 1, sticky=E)

s_label = Label(root, text='', fg="blue", font=("Helvetica Bold", 12))
status_var = StringVar()
s_label['textvariable'] = status_var
status_var.set('')
s_label.grid(row=1, column = 1, sticky=SW)

root.bind("<Button-1>", callbackM)
root.bind_all('<Key>', key)

root.overrideredirect(True)   # remove upper bar

#do_hide()

s_command.focus_set()

root.mainloop()
