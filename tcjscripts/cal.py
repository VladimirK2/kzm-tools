#!/c/temenos/tools/py-port-34\python-3.4.4.amd64/python.exe

import os
kzm_home = os.environ['kzmhome']
import sys
sys.path.append(kzm_home + os.sep + r'runtime\lib')
import kzm

import json

import time
import calendar

json_colrs_str = kzm.get_setup('colours|json')
colr = json.loads(json_colrs_str)
br_cyan = colr[ 'br_cyan' ]
reset = colr[ 'reset' ]

def get_cal(yearmon):

    the_result = '\n'

    c = calendar.TextCalendar(calendar.MONDAY)

    if yearmon == '':
        year_no, month_no, day_no = int(time.strftime('%Y')), int(time.strftime('%m')), int(time.strftime('%d'))
    else:
        year_no = int(yearmon[0:4])
        month_no = int(yearmon[4:])
        day_no = 99

    the_result += c.formatmonth(year_no, month_no) + '\n'

    month_no += 1
    if month_no == 13:
        year_no += 1
        month_no = 1

    the_result += c.formatmonth(year_no, month_no) + '\n'

    month_no += 1
    if month_no == 13:
        year_no += 1
        month_no = 1

    the_result += c.formatmonth(year_no, month_no)

    spl = the_result.split('\n')
    find, found = ' ' + str(day_no) + ' ', False

    for posn, line in enumerate(spl):
        line = ' ' + line + ' '
        if not found and find in line:
            line = line.replace(find, br_cyan + find + reset)

            found = True
        spl[posn] = line

    return '\n'.join(spl)

try:
    print(get_cal(sys.argv[1]))
except:
    print(get_cal(''))
