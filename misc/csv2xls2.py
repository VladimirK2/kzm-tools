import sys
import xlsxwriter

try:
    inFile = sys.argv[1]
except:
    inFile = 'my.csv'

try:
    delim = sys.argv[2]
except:
    delim = ';'

outFile = inFile.replace('.csv', '.xlsx')

# try to get max column size

csvCont = open(inFile, 'rb').read().decode('ascii', 'backslashreplace').replace('\r', '').split('\n')

maxlen = {}
maxline = []
rowNo = 0

for line in csvCont:
    rowNo += 1
    if line[0:4] == 'sep=':
        continue

    spl = line.split(delim)
    colNo = -1
    for fld in spl:
        lenfld = len(fld)
        colNo += 1

        if colNo in maxlen:
            if lenfld > maxlen[colNo]:
                maxlen[colNo] = lenfld
                maxline.append([colNo, lenfld, rowNo])
        else:
            maxlen[colNo] = lenfld
            maxline.append([colNo, lenfld, rowNo])

# for k, v in maxlen.items():
    # print(k, v)

print(maxline)

# Create a new Excel file and add a worksheet
workbook = xlsxwriter.Workbook(outFile)
worksheet = workbook.add_worksheet()

for k, v in maxlen.items():
    worksheet.set_column(k, k, v+1)

# worksheet.set_column(0, 100, 20)
# worksheet.set_column(3, 3, 15)
# worksheet.set_column(19, 19, 74)

worksheet.set_zoom(160)

cell_format = workbook.add_format({'bold': True})
worksheet.set_row(0, 16, cell_format)
worksheet.freeze_panes(2, 2)

just_bold = workbook.add_format( {'bold': True })
light_green = workbook.add_format({'bold': True, "bg_color": "#C6EFCE"})
light_blue = workbook.add_format({'bold': True, "bg_color": "#ADD8E6"})

rowNo = -1
# csvCont = open(inFile, 'rb').read().decode('ascii', 'backslashreplace').replace('\r', '').split('\n')

for line in csvCont:
    if line[0:4] == 'sep=':
        continue

    spl = line.split(delim)
    colNo = -1
    rowNo += 1
    for fld in spl:

        colNo += 1

        if rowNo == 0:
            worksheet.write(rowNo, colNo, '{}'.format(colNo+1), just_bold)
            worksheet.write(rowNo+1, colNo, fld)

        else:
            worksheet.write(rowNo, colNo, fld)
    if rowNo == 0:
        rowNo += 1


workbook.close()
