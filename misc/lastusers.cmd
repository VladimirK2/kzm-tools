set year=%date:~6,4%
set month=%date:~3,2%
rem echo %year%
rem echo %month%
rem echo %date%

trun tafcj - -s:..\..\..\kzm\tafcj\tabl.tcj -var:{tabl}:F.USER -var:{addfield}:DATE.LAST.SIGN.ON -var:{sel_crit}:WITH#20DATE.LAST.SIGN.ON#20LIKE#20%year%%month%...#20BY.DSND#20DATE.LAST.SIGN.ON -var:{idlen}:20
