import os
import sys
import json
import zipfile

outp = []

jarfile = sys.argv[1]
jarfilename = os.path.basename(jarfile)[0:-4]

zf = zipfile.ZipFile(jarfile, 'r')

setupfile = jarfilename + '/' + '_'.join(jarfilename.split('_')[0:4])

setupcont = zf.read(setupfile).split(b'\n')

tablist = setupcont[30].split(b'\xef\xa3\xbd')
reclist = setupcont[31].split(b'\xef\xa3\xbd')

for posn, tabl in enumerate(tablist):
    outp.append('{}>{}'.format(tabl.decode(), reclist[posn].decode()))

## could also read json files:

# lst = zf.infolist()
# for zi in lst:
    # fnspec = zi.filename
    # fname = os.path.basename(fnspec)
    # if fname.startswith('REC'):
        # print(fname)
        # fcont = zf.read(fnspec)
        # jcont = json.loads(fcont)

        # appid = jcont['header']['dsfApiType']
        # recid = jcont['header']['id']

        # outp.append('F.{}>{}'.format(appid, recid))

with open('{}.LIST'.format(jarfile), 'w') as f:
    f.write('\n'.join(outp) + '\n')
