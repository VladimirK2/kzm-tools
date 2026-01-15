import os
kzm_home = os.environ['kzmhome']

# os.environ['PATH'] = kzm_home + os.sep + r'tools\py-port-34\python-3.4.4.amd64;' + os.environ['PATH']

import win32gui, win32ui, win32con, win32api
import sys
import time
from ctypes import windll, Structure, c_long, byref

class POINT(Structure):
    _fields_ = [("x", c_long), ("y", c_long)]

def queryMousePosition():
    pt = POINT()
    windll.user32.GetCursorPos(byref(pt))
    return pt.x, pt.y

the_width = 1000
the_height = 250

#mouse_x, mouse_y = queryMousePosition()
#left = int(mouse_x - the_width / 2)
#top = int(mouse_y - the_height / 2)
left, top = queryMousePosition()

hwin = win32gui.GetDesktopWindow()
width = win32api.GetSystemMetrics(win32con.SM_CXVIRTUALSCREEN)
height = win32api.GetSystemMetrics(win32con.SM_CYVIRTUALSCREEN)
hwindc = win32gui.GetWindowDC(hwin)
srcdc = win32ui.CreateDCFromHandle(hwindc)
memdc = srcdc.CreateCompatibleDC()
bmp = win32ui.CreateBitmap()
bmp.CreateCompatibleBitmap(srcdc, the_width, the_height)
memdc.SelectObject(bmp)

memdc.BitBlt((0, 0), (the_width, the_height), srcdc, (left, top), win32con.SRCCOPY)

bmp.SaveBitmapFile(memdc, kzm_home + os.sep + 'temp' + os.sep + 'screenshot.bmp')

# show by a separate script - libraries being combined fail on exit
os.system(os.path.dirname(os.path.realpath(__file__)) + os.sep + 'zoom-show.pyw')
