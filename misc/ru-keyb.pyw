#!/usr/bin/env python

import os

import tkinter as tk
import tkinter.font
import sys
import time


def copy_res():
   global copy_done

   txt = en_text.get(1.0, tk.END)
   root.clipboard_clear()
   root.clipboard_append(txt)

   copy_done = True


def transchar(chr):

    tbl_en = [ 'A', 'B', 'V', 'G', 'D', 'E', '~', 'W', 'Z', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'F',
               'H', 'C', '(CH)', '(SH)', '(SHCH)', '(HARD)', '(BI)', '(SOFT)', '(EE)', '(YU)', '(YA)',
               'a', 'b', 'v', 'g', 'd', 'e', '`', 'w', 'z', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'f',
               'h', 'c', '(ch)', '(sh)', '(shch)', '(hard)', '(bI)', '(soft)', '(ee)', '(yu)', '(ya)' ]

    tbl_ru = [ '\u0410', '\u0411', '\u0412', '\u0413', '\u0414', '\u0415', '\u0401', '\u0416', '\u0417', '\u0418', '\u0419',  \
               '\u041a', '\u041b', '\u041c', '\u041d', '\u041e', '\u041f', '\u0420', '\u0421', '\u0422', '\u0423', '\u0424',  \
               '\u0425', '\u0426', '\u0427', '\u0428', '\u0429', '\u042a', '\u042b', '\u042c', '\u042d', '\u042e', '\u042f',   \
               '\u0430', '\u0431', '\u0432', '\u0433', '\u0434', '\u0435', '\u0451', '\u0436', '\u0437', '\u0438', '\u0439',   \
               '\u043a', '\u043b', '\u043c', '\u043d', '\u043e', '\u043f', '\u0440', '\u0441', '\u0442', '\u0443', '\u0444',   \
               '\u0445', '\u0446', '\u0447', '\u0448', '\u0449', '\u044a', '\u044b', '\u044c', '\u044d', '\u044e', '\u044f' ]


    try:
        posn = tbl_en.index(chr)
        ru_chr = tbl_ru[posn]
    except:
        if chr in [ 'q', 'x', 'Q','X' ]:  # unused ones
            ru_chr = ''
        else:
            ru_chr = chr

    return ru_chr

def key(event):

    global ctrl_pressed
    global shift_pressed
    global copy_done

    chr = ''

    if len(event.char) == 0:
        v_key = event.keysym

        if v_key == 'Control_L' or v_key == 'Control_R':
            ctrl_pressed = True

        if v_key == 'Shift_L':
            shift_pressed = True

    elif event.char == event.keysym:
        chr = event.keysym

    if len(event.char) == 1:
        v_key = event.keysym

        if v_key == 'Escape':
            txt = en_text.get(1.0, tk.END).rstrip()  # remove \n
            if copy_done or txt == '':
                do_exit()

    if chr != '':

        copy_done = False

        if rus_lat:   # latinics
            en_text.insert(tk.INSERT, chr)
            return


        if ctrl_pressed:

            if chr == 'q':
                chr = '(ch)'
            elif chr == 'w':
                chr = '(sh)'
            elif chr == 'e':
                chr = '(shch)'
            elif chr == 'a':
                chr = '(hard)'
            elif chr == 's':
                chr = '(bI)'
            elif chr == 'd':
                chr = '(soft)'
            elif chr == 'z':
                chr = '(ee)'
            elif chr == 'x':
                chr = '(yu)'
            elif chr == 'c':
                chr = '(ya)'

# Uppercase
            if chr == 'i':
                chr = '(CH)'
            elif chr == 'o':
                chr = '(SH)'
            elif chr == 'p':
                chr = '(SHCH)'
            elif chr == 'j':
                chr = '(HARD)'
            elif chr == 'k':
                chr = '(BI)'
            elif chr == 'l':
                chr = '(SOFT)'
            elif chr == 'b':
                chr = '(EE)'
            elif chr == 'n':
                chr = '(YU)'
            elif chr == 'm':
                chr = '(YA)'
            shift_pressed = False
            ctrl_pressed = False

        en_text.delete('%s-1c' % tk.INSERT, tk.INSERT)

        ru_chr = transchar(chr)
        en_text.insert(tk.INSERT, ru_chr)
    return

def callbackM(event):
    pass

def do_exit():
    root.destroy()
    sys.exit()

def toggle_rus_lat():
    global rus_lat
    caption = ['RUS', 'LAT']
    rus_lat = not(rus_lat)
    command_button_1.configure(text=caption[rus_lat])

###################################################

root = tk.Tk()
root.title('RU keyboard')

the_help = tk.StringVar()

the_font = tkinter.font.Font(family="Lucida Console", size=20, weight="bold")
bigger_font = tkinter.font.Font(family="Lucida Console", size=24)  #, weight="bold")

command_button_1 = tk.Button(root, text='RUS', fg="blue", font=the_font, command=toggle_rus_lat)
command_button_1.grid(row=0, column=0, sticky=tk.W)

command_button_2 = tk.Button(root, text='Exit', fg="blue", font=the_font, command=do_exit)
command_button_2.grid(row=1, column=0, sticky=tk.W)

command_button_3 = tk.Button(root, text='Copy', fg="blue", font=the_font, command=copy_res)
command_button_3.grid(row=2, column=0, sticky=tk.W)

en_text = tk.Text(root, font=the_font, width=80, height=24)
en_text.grid(row=0, column = 1, rowspan=2, sticky=tk.E)

root.bind("<Button-1>", callbackM)
root.bind_all('<Key>', key)

root.geometry('1500x700+420+420')

global ctrl_pressed
global shift_pressed
global copy_done
global rus_lat
ctrl_pressed = False
shift_pressed = False
copy_done = True
rus_lat = 0

en_text.focus_set()
root.call('wm', 'attributes', '.', '-topmost', '1')
root.mainloop()
