import os
import sys

def getXML(xmlCont):

    outDict = {}

    itemInProgress = False
    currItem = ''
    idx = 'N/A'

    for line in xmlCont:
        if itemInProgress:
            if line.startswith('<P014>'):
                idx = line

            elif line == endTag:
                outDict[idx] = currItem
                currItem = ''

            else:
                currItem += line + '\n'

        else:
            if line == strtTag:
                itemInProgress = True
                continue


    return(outDict)

inFile = sys.argv[1]
otherFile = sys.argv[2]

strtTag, endTag = '<Payment>', '</Payment>'

xmlCont = open(inFile, 'rb').read().decode('ascii', 'backslashreplace').replace('\r', '').split('\n')
inDict = getXML(xmlCont)

xmlCont = open(otherFile, 'rb').read().decode('ascii', 'backslashreplace').replace('\r', '').split('\n')
otherDict = getXML(xmlCont)

itemNo = 0
itemQ = len(inDict)
itemQ2 = len(otherDict)

print('File 1, found', itemQ, 'items')
print('File 2, found', itemQ2, 'items')

for k, v in inDict.items():
    itemNo += 1
    if k in otherDict:
        if v != otherDict[k]:
            print('Item #', itemNo, 'of', itemQ)
            print('File 1', k, ':')
            print(v)
            print('File 2', k, ':')
            print(otherDict[k])

            spl1 = v.split('\n')
            spl2 = otherDict[k].split('\n')

            for tag in spl1:
                if tag not in spl2:
                    print(tag)
            print('...')
            for tag in spl2:
                if tag not in spl1:
                    print(tag)


            key = input()
    else:
        print('File 2', k, 'not found')
        key = input()

for k, v in otherDict.items():
    if k not in inDict:
        print('File 1', k, 'not found')
        key = input()

sys.exit()

