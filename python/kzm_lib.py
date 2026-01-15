#!/usr/bin/env python

import os

def recursive_glob(rootdir='.', suffix=''):
    return [os.path.join(rootdir, filename)
            for rootdir, dirnames, filenames in os.walk(rootdir)
            for filename in filenames if filename.endswith(suffix)]

def get_location(what):

    kzm_home = os.environ['kzmhome']

    if what == 'py3-64':
        ret = r'c:\temenos\tools\py-port-34\python-3.4.4.amd64'
    elif what == 't24help':
        ret = kzm_home + os.sep + r'man\T24Help\R{0}.T24Help'
    elif what == 'email':
        ret = r'C:\temenos\kzm\runtime\email'
    elif what == 'temp':
        ret = kzm_home + os.sep + 'temp'
    else:
        ret = ''

    # print(ret)
    return ret

def get_abbr(abbr):
    if abbr == 'AC':
        return 'ACCOUNT'
    elif abbr == 'FT':
        return 'FUNDS.TRANSFER'
    elif abbr == 'MM':
        return 'MM.MONEY.MARKET'
    elif abbr == 'LD':
        return 'LD.LOANS.AND.DEPOSITS'
    elif abbr == 'SM':
        return 'SECURITY.MASTER'
    elif abbr == 'SAM':
        return 'SEC.ACC.MASTER'
    elif abbr == 'SPA':
        return 'SC.POS.ASSET'
    # elif abbr == '':
        # return ''

    else:
        return abbr  # not an abbreviation


if __name__ == '__main__':
    print('This is a library')
