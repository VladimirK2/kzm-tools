#!/usr/bin/env python

"""
Eternal screen grabbing utility
"""

from PIL import ImageGrab
import time

n = 0

# while True:
for i in range(0, 3):
    time.sleep(5)
    n += 1
    ImageGrab.grab().save('screen' + str(n).zfill(4) + '.png', "PNG")
