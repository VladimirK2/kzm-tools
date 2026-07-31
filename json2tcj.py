import os
import sys

import json

json_file = sys.argv[1]

with open(json_file, 'r', encoding='utf-8') as file:
    data = json.load(file)

deal_app = data['header']['dsfApiType']
deal_id = data['header']['id']

output = []
output.append('read')
output.append('    F.{}'.format(deal_app))
output.append('    {}'.format(deal_id))
output.append('clear')
output.append('update')

for group in data['body']:

    fld_data = data['body'][group]

    if type(fld_data) is str:
        output.append('    {}::={}'.format(group, fld_data))

    elif type(fld_data) is list:

        cntr = 0
        for item in fld_data:
            output.append('')
            cntr += 1
            for sub_item in item:
                if type(item[sub_item]) is str:
                    output.append('    {}:{}:={}'.format(sub_item, cntr, item[sub_item]))

                elif type(item[sub_item]) is list:

                    smno = 0
                    for sub_sub_item in item[sub_item]:
                        lst = list(sub_sub_item.items())
                        smno += 1
                        output.append('    {}:{}:{}={}'.format(lst[0][0], cntr, smno, lst[0][1]))


output.append('commit')

with open(json_file.replace('.json', '.tcj'), 'w', encoding='utf-8') as file:
    file.write('\n'.join(output) + '\n')
