#!/usr/bin/env python

from tkinter import *
import sys
global clipb_cont

def mouse_wheel(event):
    global count
    # respond to Linux or Windows wheel event
    if event.num == 5 or event.delta == -120:
        count += 100
    if event.num == 4 or event.delta == 120:
        count -= 100

    root.geometry('+200+{}'.format(count))

# def move1():
    # root.geometry('+200+200')
    # root.after(2000, move2)

# def move2():
    # root.geometry('+200+300')
    # root.after(2000, exii)

def exii():
    root.destroy()
    sys.exit()

def key(event):
    global count
    global clipb_cont

    if event.char == event.keysym:
        pass

    elif event.keysym == 'plus':

        try:

            rezt = 0
            spl = clipb_cont.replace('\r', '').split('\n')
            for numb in spl:
                if numb == '':
                    continue
                rezt += float(numb)

            outp = str(rezt)


        except Exception as e:
            outp = '{}'.format(e)

        s_clipboard.delete("1.0", END)
        s_clipboard.insert("1.0", outp)


    elif event.keysym == 'Left':
        if clipb_cont[0:3] == '   ':
            clipb_cont = clipb_cont[3:]
            s_clipboard.delete("1.0", END)
            s_clipboard.insert("1.0", clipb_cont)

    elif event.keysym == 'Right':
        clipb_cont = '   ' + clipb_cont
        s_clipboard.delete("1.0", END)
        s_clipboard.insert("1.0", clipb_cont)

    elif event.keysym == 'Down':
        count += 100
        root.geometry('+200+{}'.format(count))
    elif event.keysym == 'Up':
        count -= 100
        root.geometry('+200+{}'.format(count))


    elif len(event.char) == 1:
        v_key = event.keysym

        if v_key == 'Escape':
            root.destroy()
            sys.exit()
            pass
    else:
        pass

root = Tk()
root.title('Clipboard contents')

command_var = StringVar()
s_clipboard = Text(root, width=132, height=24, wrap="word", font='Courier 18 bold', fg="navy blue", bg="gray")
# s_clipboard = Text(root, width=132, height=24, wrap="word", font='Lucida 18 Bold', fg="navy blue", bg="gray")
s_clipboard.grid(row=0, column = 1, sticky=E)

try:
    clipb_cont = root.selection_get(selection="CLIPBOARD")

except Exception as e:
    clipb_cont = 'Non-text data'

lines_qty = clipb_cont.count('\n') + 1
if lines_qty > 24:
    lines_qty = 24

# s_clipboard.insert("1.0", str(lines_qty) + '   ' + clipb_cont)
s_clipboard.insert("1.0", clipb_cont)

global count
count = 100

root.bind_all('<Key>', key)
root.bind('<Button-3>', exii)
root.bind("<MouseWheel>", mouse_wheel)

# root.geometry('1800x656+200+127')
root.geometry('1800x{}+200+100'.format(lines_qty*30))

# root.after(2000, move1)
root.attributes('-topmost', True)
root.overrideredirect(True)
root.wm_attributes('-alpha', 0.7)
root.mainloop()
