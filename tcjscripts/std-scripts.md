#  Standard scripts

Scripts that can be used to select tables, list records etc. Can fully replace DBTools at some point.

## Where to put standard scripts

Under TAFC - create a folder tcjscripts (as in examples; name can be any) in bnk.run.

Under TAFJ - create that folder in T24\bnk\UD.

## How to run standard scripts

### List.tcj
List a record.

    tRun.bat tafcj - -s:tcjscripts\list.tcj

(User will be asked to input required table and record.)

    tRun.bat tafcj - -s:tcjscripts\list.tcj -var:{tabl}:f.spf -var:{recid}:system

    tRun.bat tafcj - -s:tcjscripts\list.tcj -var:{tabl}:fbnk.customer~his -var:{recid}:100100;1

Output for the last example:

    tafcj script interpreter 1.4.2
    Script to run: tcjscripts\list.tcj
    Variable(s) passed to script:
    {tabl} = "fbnk.customer~his"
    {recid} = "100100;1"
    Reading script...
    Parsing script...
    Proceeding ...
    ## [FBNK.CUSTOMER$HIS>100100;1]
    (  1) [MNEMONIC                           ] CRISP
    (  2) [SHORT.NAME                         ] Harry Crisp
    (  3) [NAME.1                             ] Harry Crisp
    (  4) [NAME.2                             ] Harry Crisp
    (  5) [STREET                             ] 1000 - 2nd Ave
    (  6) [ADDRESS                            ] Suite 2200
    (  7) [TOWN.COUNTRY                       ] Seattle
    (  8) [POST.CODE                          ] 98104-1049
    (  9) [COUNTRY                            ] United States of America
    ( 10) [RELATION.CODE                      ] 
    ( 11) [REL.CUSTOMER                       ] 
    ( 12) [REVERS.REL.CODE                    ] 
    ( 13) [REL.DELIV.OPT                      ] 
    ( 14) [ROLE                               ] 
    ( 15) [ROLE.MORE.INFO                     ] 
    ( 16) [ROLE.NOTES                         ] 
    ( 17) [REL.RESERV6                        ] 
    ( 18) [REL.RESERV5                        ] 
    ( 19) [REL.RESERV4                        ] 
    ( 20) [REL.RESERV3                        ] 
    ( 21) [REL.RESERV2                        ] 
    ( 22) [REL.RESERV1                        ] 
    ( 23) [SECTOR                             ] 1001
    ( 24) [ACCOUNT.OFFICER                    ] 26
    ( 25) [OTHER.OFFICER                      ] 27
    ( 26) [INDUSTRY                           ] 1000
    ( 27) [TARGET                             ] 4
    ( 28) [NATIONALITY                        ] US
    ( 29) [CUSTOMER.STATUS                    ] 4
    ( 30) [RESIDENCE                          ] US
    ( 31) [CONTACT.DATE                       ] 
    ( 32) [INTRODUCER                         ] 
    ( 33) [TEXT                               ] 
    ( 34) [LEGAL.ID                           ] 
    ( 35) [LEGAL.DOC.NAME                     ] 
    ( 36) [LEGAL.HOLDER.NAME                  ] 
    ( 37) [LEGAL.ISS.AUTH                     ] 
    ( 38) [LEGAL.ISS.DATE                     ] 
    ( 39) [LEGAL.EXP.DATE                     ] 
    ( 40) [OFF.PHONE                          ] 
    ( 41) [REVIEW.FREQUENCY                   ] 
    ( 42) [BIRTH.INCORP.DATE                  ] 
    ( 43) [GLOBAL.CUSTOMER                    ] 
    ( 44) [CUSTOMER.LIABILITY                 ] 
    ( 45) [LANGUAGE                           ] 1
    ( 46) [POSTING.RESTRICT                   ] 
    ( 47) [DISPO.OFFICER                      ] 
    ( 48) [COMPANY.BOOK                       ] GB0010001
    ( 49) [CONFID.TXT                         ] 
    ( 50) [DISPO.EXEMPT                       ] 
    ( 51) [ISSUE.CHEQUES                      ] YES
    ( 52) [CLS.CPARTY                         ] NO
    ( 53) [FX.COMM.GROUP.ID                   ] 
    ( 54) [RESIDENCE.REGION                   ] 
    ( 55) [ASSET.CLASS                        ] 10
    ( 56) [CUSTOMER.RATING                    ] 
    ( 57) [CR.PROFILE.TYPE                    ] VALUED.CUSTOMER
    ( 58) [CR.PROFILE                         ] 14
    ( 59) [NO.UPDATE.CRM                      ] 
    ( 60) [TITLE                              ] MR
    ( 61) [GIVEN.NAMES                        ] Harry Crisp
    ( 62) [FAMILY.NAME                        ] 
    ( 63) [GENDER                             ] MALE
    ( 64) [DATE.OF.BIRTH                      ] 19710222
    ( 65) [MARITAL.STATUS                     ] 
    ( 66) [NO.OF.DEPENDENTS                   ] 
    ( 67) [PHONE.1                            ] 206 553-6944
    ( 68) [SMS.1                              ] 206 553-6944
    ( 69) [EMAIL.1                            ] harrycrisp@gmail.com
    ( 70) [ADDR.LOCATION                      ] 
    ( 71) [EMPLOYMENT.STATUS                  ] 
    ( 72) [OCCUPATION                         ] 
    ( 73) [JOB.TITLE                          ] 
    ( 74) [EMPLOYERS.NAME                     ] 
    ( 75) [EMPLOYERS.ADD                      ] 
    ( 76) [EMPLOYERS.BUSS                     ] 
    ( 77) [EMPLOYMENT.START                   ] 
    ( 78) [CUSTOMER.CURRENCY                  ] 
    ( 79) [SALARY                             ] 
    ( 80) [ANNUAL.BONUS                       ] 
    ( 81) [SALARY.DATE.FREQ                   ] 
    ( 82) [NET.MONTHLY.IN                     ] 
    ( 83) [NET.MONTHLY.OUT                    ] 
    ( 84) [RESIDENCE.STATUS                   ] 
    ( 85) [RESIDENCE.TYPE                     ] 
    ( 86) [RESIDENCE.SINCE                    ] 
    ( 87) [RESIDENCE.VALUE                    ] 
    ( 88) [MORTGAGE.AMT                       ] 
    ( 89) [OTHER.FIN.REL                      ] 
    ( 90) [OTHER.FIN.INST                     ] 
    ( 91) [COMM.TYPE                          ] 
    ( 92) [PREF.CHANNEL                       ] 
    ( 93) [ALLOW.BULK.PROCESS                 ] 
    ( 94) [LEGAL.ID.DOC.NAME                  ] 
    ( 95) [INTERESTS                          ] 
    ( 96) [FAX.1                              ] 
    ( 97) [PREVIOUS.NAME                      ] 
    ( 98) [CHANGE.DATE                        ] 
    ( 99) [CHANGE.REASON                      ] 
    (100) [CUSTOMER.SINCE                     ] 
    (101) [CUSTOMER.TYPE                      ] 
    (102) [RESERVED.51                        ] 
    (103) [DATE.LAST.VERIFIED                 ] 
    (104) [SPOKEN.LANGUAGE                    ] 
    (105) [PASTIMES                           ] 
    (106) [FURTHER.DETAILS                    ] 
    (107) [DOMICILE                           ] 
    (108) [OTHER.NATIONALITY                  ] 
    (109) [CALC.RISK.CLASS                    ] 
    (110) [MANUAL.RISK.CLASS                  ] 
    (111) [OVERRIDE.REASON                    ] 
    (112) [TAX.ID                             ] 
    (113) [VIS.TYPE                           ] 
    (114) [VIS.COMMENT                        ] 
    (115) [VIS.INTERNAL.REVIEW                ] 
    (116) [FORMER.VIS.TYPE                    ] 
    (117) [FORMER.VIS.COMMENT                 ] 
    (118) [RISK.ASSET.TYPE                    ] 
    (119) [RISK.LEVEL                         ] 
    (120) [RISK.TOLERANCE                     ] 
    (121) [RISK.FROM.DATE                     ] 
    (122) [LAST.KYC.REVIEW.DATE               ] 
    (123) [AUTO.NEXT.KYC.REVIEW.DATE          ] 
    (124) [MANUAL.NEXT.KYC.REVIEW.DATE        ] 
    (125) [LAST.SUIT.REVIEW.DATE              ] 
    (126) [AUTO.NEXT.SUIT.REVIEW.DATE         ] 
    (127) [MANUAL.NEXT.SUIT.REVIEW.DATE       ] 
    (128) [KYC.RELATIONSHIP                   ] 
    (129) [MANDATE.APPL                       ] 
    (130) [MANDATE.REG                        ] 
    (131) [MANDATE.RECORD                     ] 
    (132) [SECURE.MESSAGE                     ] 
    (133) [AML.CHECK                          ] NULL
    (134) [AML.RESULT                         ] NULL
    (135) [LAST.AML.RESULT.DATE               ] 
    (136) [KYC.COMPLETE                       ] 
    (137) [INTERNET.BANKING.SERVICE           ] NULL
    (138) [MOBILE.BANKING.SERVICE             ] NULL
    (139) [REPORT.TEMPLATE                    ] 
    (140) [HOLDINGS.PIVOT                     ] 
    (141) [MERGED.TO                          ] 
    (142) [MERGED.STATUS                      ] 
    (143) [ALT.CUS.ID                         ] 
    (144) [EXTERN.SYS.ID                      ] 
    (145) [EXTERN.CUS.ID                      ] 
    (146) [SOCIAL.NTW.IDS                     ] 
    (147) [PERSON.ENTITY.ID                   ] 
    (148) [REG.COUNTRY                        ] 
    (149) [CR.USER.PROFILE.TYPE               ] VALUED.CUSTOMER
    (150) [CR.CALC.PROFILE                    ] 14
    (151) [CR.USER.PROFILE                    ] 14
    (152) [CR.CALC.RESET.DATE                 ] 
    (153) [REF.DATA.ITEM                      ] 
    (154) [REF.DATA.VALUE                     ] 
    (155) [PROB.OF.DEFT                       ] 
    (156) [DEATH.DATE                         ] 
    (157) [NOTIFICATION.OF.DEATH              ] 
    (158) [PROBATE.DATE                       ] 
    (159) [VULNERABILITY                      ] 
    (160) [UPDATE.PREV.ADDRESS                ] 
    (161) [NAME.ALIAS                         ] 
    (162) [ADDRESS.COUNTRY                    ] 
    (163) [ADDRESS.ITEM1                      ] 
    (164) [ADDRESS.ITEM2                      ] 
    (165) [ADDRESS.TYPE                       ] 
    (166) [ADDRESS.PURPOSE                    ] 
    (167) [BUILDING.NUMBER                    ] 
    (168) [BUILDING.NAME                      ] 
    (169) [FLAT.NUMBER                        ] 
    (170) [PO.BOX.NUMBER                      ] 
    (171) [COUNTRY.SUBDIVISION                ] 
    (172) [SALUTATION                         ] 
    (173) [CONTACT.TYPE                       ] 
    (174) [IDD.PREFIX.PHONE                   ] 
    (175) [CONTACT.DATA                       ] 
    (176) [AUTO.UPD.DEL.ADD                   ] 
    (177) [ADDRESS.VALIDATED.BY               ] 
    (178) [LOCAL.CONTENT                      ] 
    (179) [LOCAL.REF                          ] 
    [179.1 SEGMENT                            ] 
    [179.2 CU.EFF.DATE                        ] 
    [179.3 US.STATE                           ] 
    [179.4 APPLY.CERTIFIED                    ] 
    [179.5 W8.BEN                             ] 
    [179.6 BACKUP.WITHHOLD                    ] NO
    [179.7 MIDDLE.NAME                        ] 
    [179.8 SUFFIX                             ] 
    [179.9 CI.INDICATOR                       ] 
    [179.10 COMM.DEVICE                       ] 
    [179.11 DEVICE.NO                         ] 
    [179.12 DEVICE.PRIVACY                    ] 
    [179.13 ANNUAL.PRIVACY                    ] 
    [179.14 COMMN.MODE                        ] 
    [179.15 PRIVACY.STATUS                    ] OPT-IN
    [179.16 PRIVACY.DATE                      ] 20240416
    (180) [OVERRIDE                           ] 
    (181) [RECORD.STATUS                      ] 
    (182) [CURR.NO                            ] 1
    (183) [INPUTTER                           ] 50576_OFFICER__OFS_SEAT
    (184) [DATE.TIME                          ] 2406020106
    (185) [AUTHORISER                         ] 50576_OFFICER_OFS_SEAT
    (186) [CO.CODE                            ] GB0010001
    (187) [DEPT.CODE                          ] 1
    [INFO] tcjscripts\list.tcj finished successfully
    Elapsed time: 9.67 s.

*Note: table and record IDs are converted to upper case in the script but it's very easy to suppress it if necessary - e.g. for mixed case IDs.*

*Note 2: to get record contents into a file (without runtime information) use -a or -A parameter.*

*Note 3: Examples are run on quite a weak PC, not a server - so elapsed times here and below are hopefully not what you're going to get.*

### List.tcj
Display the latest changes in a record.

    tRun.bat tafcj - -s:tcjscripts\hist.tcj -var:{tabl}:fbnk.customer -var:{recid}:100100

Again, if variables *tabl* and/or *recid* are not specified - user will be asked to input them.

By default output is quite wide; to limit the output width it's possible to use additional optional variables *datawidth* and *dictwidth*:

    tRun.bat tafcj - -s:tcjscripts\hist.tcj -var:{tabl}:fbnk.customer -var:{recid}:100100 -var:{datawidth}:25 -var:{dictwidth}:30

Output:

    tafcj script interpreter 1.4.2
    Script to run: tcjscripts\hist.tcj
    Variable(s) passed to script:
    {tabl} = "fbnk.customer"
    {recid} = "100100"
    {datawidth} = "32"
    {dictwidth} = "30"
    Reading script...
    Parsing script...
    Proceeding ...
    [FBNK.CUSTOMER>100100]
    ( 78) [CUSTOMER.CURRENCY             ]                                  | USD 
    ( 79) [SALARY                        ]                                  | 500000.00 
    ( 80) [ANNUAL.BONUS                  ]                                  | 1000000.00 
    ( 81) [SALARY.DATE.FREQ              ]                                  | 20240601M0101 
    (182) [  CURR.NO                     ] 1                                | 2 
    (183) [  INPUTTER                    ] 50576_OFFICER__OFS_SEAT          | 13156_OFFICER__OFS_SEAT 
    (184) [  DATE.TIME                   ] 2406020106                       | 2406020947 
    (185) [  AUTHORISER                  ] 50576_OFFICER_OFS_SEAT           | 13156_OFFICER_OFS_SEAT 
    [INFO] tcjscripts\hist.tcj finished successfully
    Elapsed time: 12.44 s.

Optional variable *all* can be used to display all fields - not only changed ones; "equal" signs indicate fields that didn't change:

    tRun.bat tafcj - -s:tcjscripts\hist.tcj -var:{tabl}:f.de.form.type -var:{recid}:system -var:{all}:y -var:{datawidth}:32 -var:{dictwidth}:30

Output:

    tafcj script interpreter 1.4.2
    Script to run: tcjscripts\hist.tcj
    Variable(s) passed to script:
    {tabl} = "f.de.form.type"
    {recid} = "system"
    {all} = "y"
    {datawidth} = "32"
    {dictwidth} = "30"
    Reading script...
    Parsing script...
    Proceeding ...
    [F.DE.FORM.TYPE>system]
    (  1) [DESCRIPTION                   ] Standard landscape form          = Standard landscape form 
    (  3) [FORM.WIDTH                    ] 132                              | 162 
    (  4) [FORM.DEPTH                    ] 66                               = 66 
    (  7) [RPT.ATTRIBUTES                ] LANDCOMP                         = LANDCOMP 
    (  8) [OPTIONS                       ] NHEAD                            = NHEAD 
    ( 10) [  CURR.NO                     ] 6                                | 7 
    ( 11) [  INPUTTER                    ] 3_AUTHORISER___OFS_MB.OFS.AUTH   | 1_202102 
    ( 12) [  DATE.TIME                   ] 0804151341                       | 2406010641 
    ( 13) [  AUTHORISER                  ] 3_AUTHORISER_OFS_MB.OFS.AUTH     | 97500_TRAIN511_OFS_MB.OFS 
    ( 14) [  CO.CODE                     ] GB0010001                        = GB0010001 
    ( 15) [  DEPT.CODE                   ] 1                                = 1 
    [INFO] tcjscripts\hist.tcj finished successfully
    Elapsed time: 13.97 s.

**TO BE CONTINUED**
