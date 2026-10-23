import os
import sys
import json

global ret
ret = []

def list_files_recursive(path='.'):
    global ret
    for entry in os.listdir(path):
        full_path = os.path.join(path, entry)
        if os.path.isdir(full_path):
            list_files_recursive(full_path)
        else:
            if entry.startswith('t24data.') and entry.endswith('.json'):
                ret.append(full_path)

    return ret

gitpath = os.environ['USERPROFILE'] + r'\git\XXXXXXXXXXX\src'

print('Getting file names...', flush=True)
flist = list_files_recursive(gitpath)
print('Got', len(flist), flush=True)

idescL = []
cntr = 0

for jfile in flist:

    cntr += 1
    if cntr % 1000 == 0:
        print(cntr, end = '', flush=True)

    with open(jfile, 'rb') as f:
        fcont = f.read().decode('ascii', 'ignore')
    jcont = json.loads(fcont)

    print('.', end = '', flush=True)

    # print(jcont)

    try:
        apiaction = jcont['header']['dsfApiAction']
    except:
        apiaction = ''

    jfilename = os.path.basename(jfile)
    jfilenameSPL = jfilename.split('!')

    exclcount = jfilename.count('!')

    if exclcount == 1:
        fappid = jfilenameSPL[0].replace('t24data.', '')
        frecid = jfilenameSPL[1].replace('.json', '')

    elif exclcount == 2:
        fappid = jfilenameSPL[0].replace('t24data.', '')

        if fappid == 'MV.MARGIN.RULES':
            frecid = jfilenameSPL[1] + '!' + jfilenameSPL[2].replace('.json', '')
        else:
            frecid = jfilenameSPL[2].replace('.json', '')

    elif exclcount == 3:
        fappid = jfilenameSPL[0].replace('t24data.', '')

        if fappid == 'PP.COMPANY.PROPERTIES':
            frecid = jfilenameSPL[1] + '!' + jfilenameSPL[2] + '!'
        else:
            print(jfile)
            print('Found', exclcount, 'exclamation signs, please check')
            sys.exit()

    elif exclcount == 4:
        fappid = jfilenameSPL[0].replace('t24data.', '')
        frecid = jfilenameSPL[2] + '!' + jfilenameSPL[3] + '!' + jfilenameSPL[4].replace('.json', '')

    else:
        print(jfile)
        print('Found', exclcount, 'exclamation signs')
        sys.exit()

    frecid = frecid.replace('^2', '/').replace('^4', '*').replace(']62', '>')

    if apiaction == 'Reverse':
        frecid = frecid.replace('@R', '')

    if apiaction == 'History restore':
        frecid = frecid.replace('@H', '')

    if fappid == 'STANDARD.SELECTION' and '#' in frecid:
        frecidSPL = frecid.split('#')
        frecid = frecidSPL[0]
        idescid = frecidSPL[1]

        if idescid in idescL:
            print(jfile)
            print(idescid, 'already in IDESC list')
            sys.exit()
        else:
            idescL.append(idescid)

    appid = jcont['header']['dsfApiType']

    recid = jcont['header']['id']

    if fappid != appid or frecid != recid:
        print('')
        print('Non-matching data in:')

        outjfile = jfile
        slashno = 0
        while '\\' in outjfile:
            slashno += 1
            outjfile = outjfile.replace('\\', '\n' + ' ' *slashno, 1)
        print(outjfile)

        print(fappid, appid, 'Match:', fappid == appid)
        print(frecid, recid, 'Match:', frecid == recid)

        sys.exit()

print('\nSuccess')
