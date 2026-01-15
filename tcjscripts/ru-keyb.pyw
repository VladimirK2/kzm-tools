#!/usr/bin/env python

# from __future__ import division
import os

# from tkinter import *
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


# A B V G D E Y(o) W Z I J K L M N O P R S T U F H C
# not used: Q X
#   AltGr/numpad 1-9:
# ch
# sh
# chsh
# _
#  b
# bl
# b
# E (mirrored)
# I-O
# R (mirrored)


# def translate(txt_en):

# Q W Y X

    # tbl_en = [ 'A', 'B', 'V', 'G', 'D', 'E', '~', 'X', 'Z', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'F',
               # 'H', 'C', '+', '{', '}', ':', '"', '|', 'W', 'Q', 'Y',
               # '(ch)', 'a', 'b', 'v', 'g', 'd', 'e', '`', 'x', 'z', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'f',
               # 'h', 'c', '[', ']', ';', "'", '\\', 'w', 'q', 'y' ]

    # tbl_ru = [ '\u0410', '\u0411', '\u0412', '\u0413', '\u0414', '\u0415', '\u0401', '\u0416', '\u0417', '\u0418', '\u0419',  \
               # '\u041a', '\u041b', '\u041c', '\u041d', '\u041e', '\u041f', '\u0420', '\u0421', '\u0422', '\u0423', '\u0424',  \
               # '\u0425', '\u0426', '\u0427', '\u0428', '\u0429', '\u042a', '\u042b', '\u042c', '\u042d', '\u042e', '\u042f',   \
               # '\u0447', '\u0430', '\u0431', '\u0432', '\u0433', '\u0434', '\u0435', '\u0451', '\u0436', '\u0437', '\u0438', '\u0439',   \
               # '\u043a', '\u043b', '\u043c', '\u043d', '\u043e', '\u043f', '\u0440', '\u0441', '\u0442', '\u0443', '\u0444',   \
               # '\u0445', '\u0446', '\u0448', '\u0449', '\u044a', '\u044b', '\u044c', '\u044d', '\u044e', '\u044f' ]

    # txt_ru = txt_en

    # for posn, char in enumerate(tbl_en):
        # txt_ru = txt_ru.replace(char, tbl_ru[posn])

    # return txt_ru


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

    # print(event.x, event.y)
    # print('keysim=' + event.keysym)

    global ctrl_pressed
    global shift_pressed
    global copy_done

    chr = ''

    if len(event.char) == 0:
        v_key = event.keysym

        if v_key == 'Control_L':
            ctrl_pressed = True

        if v_key == 'Shift_L':
            shift_pressed = True

    elif event.char == event.keysym:
        chr = event.keysym

    if len(event.char) == 1:
        v_key = event.keysym

        if v_key == 'Escape':
            txt = en_text.get(1.0, tk.END).rstrip()  # remove \n
            # print('[' + txt + ']')
            if copy_done or txt == '':
                do_exit()

    # print(ctrl_pressed)
    # print(shift_pressed)

    if chr != '':

        copy_done = False

        if ctrl_pressed:

            if shift_pressed:
                if chr == 'q':
                    chr = '(CH)'
                elif chr == 'w':
                    chr = '(SH)'
                elif chr == 'e':
                    chr = '(SHCH)'
                elif chr == 'a':
                    chr = '(HARD)'
                elif chr == 's':
                    chr = '(BI)'
                elif chr == 'd':
                    chr = '(SOFT)'
                elif chr == 'z':
                    chr = '(EE)'
                elif chr == 'x':
                    chr = '(YU)'
                elif chr == 'c':
                    chr = '(YA)'
            else:
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

            shift_pressed = False
            ctrl_pressed = False

        # else:
            # if len(chr) == 1:
        en_text.delete('%s-1c' % tk.INSERT, tk.INSERT)

        ru_chr = transchar(chr)
        en_text.insert(tk.INSERT, ru_chr)

    # txt = en_text.get(1.0, tk.END)
    # ru_txt = translate(txt)

    # ru_text.delete(1.0, tk.END)

    # ru_text.insert(tk.END, ru_txt)

    # if event.char == event.keysym:
        # v = status_var.get()
        # v += event.char
        # status_var.set(v)

    # elif len(event.char) == 1:
        # v_key = event.keysym

        # if v_key == 'Escape':
            # root.destroy()
            # sys.exit()
            # pass

        # elif v_key == 'Return':
           # calc()
    # else:
        # pass

def callbackM(event):
    pass

def do_exit():
    root.destroy()
    sys.exit()

###################################################

root = tk.Tk()
root.title('RU keyboard')

the_help = tk.StringVar()
# the_help.set('\n\u0401  1  2  3  4  5  6  7  8  9  0  -  \u0427\n\n    \u042e  \u042d  \u0415  \u0420  \u0422  \u042f  \u0423  \u0418  \u041e  \u041f  \u0428  \u0429\n\n     \u0410  \u0421  \u0414  \u0424  \u0413  \u0425  \u0419  \u041a  \u041b  \u042a  \u042b  \u042c\n\n  \u0417  \u0416  \u0426  \u0412  \u0411  \u041d  \u041c  ,  .  / ')

the_font = tkinter.font.Font(family="Lucida Console", size=12, weight="bold")
bigger_font = tkinter.font.Font(family="Lucida Console", size=16)  #, weight="bold")

command_button = tk.Button(root, text='Exit', fg="blue", font=the_font, command=do_exit)
command_button.grid(row=0, column=0, sticky=tk.W)
command_button = tk.Button(root, text='Copy', fg="blue", font=the_font, command=copy_res)
command_button.grid(row=1, column=0, sticky=tk.W)

en_text = tk.Text(root, font=the_font, width=80, height=24)
en_text.grid(row=0, column = 1, rowspan=2, sticky=tk.E)

# ru_text = tk.Text(root, fg="blue", font=the_font, width=80, height=12)
# ru_text.grid(row=1, column = 1, sticky=tk.SW)

# help_text = tk.Label(root, textvariable=the_help, fg="darkblue", width=45, height=8, font=bigger_font)
# help_text.grid(row=2, column = 1, sticky=tk.W)

root.bind("<Button-1>", callbackM)
root.bind_all('<Key>', key)

root.geometry('1000x400+420+420')

global ctrl_pressed
global shift_pressed
global copy_done
ctrl_pressed = False
shift_pressed = False
copy_done = True

en_text.focus_set()
root.call('wm', 'attributes', '.', '-topmost', '1')
root.mainloop()
