#  Standard scripts

Scripts that can be used to select tables, list records etc. Can fully replace DDBTools at some point.

## Where to put standard scripts

Under TAFC - created a folder tcjscripts (as in examples; name can be any) in bnk.run.

Under TAFJ - create that folder in T24\UD.

## How to run standard scripts

### List.tcj
tRun.bat tafcj - -s:tcjscripts\list.tcj

(User will be asked for table and record)

tRun.bat tafcj - -s:tcjscripts\list.tcj -var:{tabl}:f.spf -var:{recid}:system

tRun.bat tafcj - -s:tcjscripts\list.tcj -var:{tabl}:fbnk.customer~his -var:{recid}:100100;1
