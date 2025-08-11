PROGRAM tafcj
* By V.Kazimirchik

    INCLUDE JBC.h
    $INSERT I_COMMON
    $INSERT I_EQUATE

    $INSERT I_F.OFS.SOURCE

    GOSUB initvars
    GOSUB parseparams
    GOSUB readscript
    GOSUB runscript

    STOP

*----------------------------------------------------------------------------------------------------------------------------------
doexit:

    IF INFO_list THEN
        CHANGE @FM TO CHAR(10) IN INFO_list
        CRT INFO_list
    END

    IF WARN_list THEN
        CHANGE @FM TO CHAR(10) IN WARN_list
        CRT WARN_list
    END

    IF EXIT_code NE 0 THEN
        CRT ERROR_message
        CRT 'Exit code: ' : EXIT_code
        IF SCRIPT_line_no GT 0 THEN CRT 'Script line: ' : SCRIPT_line_no
    END ELSE CRT 'Finished successfully'

    CRT 'Elapsed time: ' : FMT(TIMESTAMP() - START_time, 'R2') : ' s.'
    EXIT(EXIT_code)

*----------------------------------------------------------------------------------------------------------------------------------
dohelp:

    CRT 'tafcj script interpreter by V.Kazimirchik'
    CRT 'Parameters:'
    CRT '------------------------------------'
    CRT '1st one - OFS.SOURCE @ID (or "-" if login to T24 is not necessary)'
    CRT '-s:script_file'
    CRT '...'

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
initvars:

    COMMIT_options = 'INAU' :@FM: 'IHLD' :@FM: 'RAW'
    DIM DICT_list(1)
    MAT DICT_list = ''
    DIM DICT_list_lref(1)
    MAT DICT_list_lref = ''
    ERROR_message = 'Unknown error'
    EXIT_code = 1

    DIM FILE_handle_list(1)
    MAT FILE_handle_list = ''

    FILE_fname_list = 'F.SPF'
    FILE_no_curr = 1
    INFO_list = ''
    is_EOF = @FALSE
    LBL_list = ''  ;  LBL_posn_list = ''
    LREF_posn = 0
    RECORD_curr = ''
    RECORD_curr_init = ''
    RECORD_id_curr = ''
    RECORD_is_new = @FALSE
    REC_STAT_posn = -1
    SCRIPT_file = ''
    SCRIPT_data = ''
    SCRIPT_line = ''
    SCRIPT_line_no = 0
    SCRIPT_size = 0
    START_time = TIMESTAMP()
    WARN_list = ''

    OPEN 'F.MNEMONIC.COMPANY' TO f_mnem_cmp ELSE
        ERROR_message = 'Error opening F.MNEMONIC.COMPANY'
        EXIT_code = 14
        GOSUB doexit
    END

    READ COMPANY_curr FROM f_mnem_cmp, 'BNK' ELSE
        ERROR_message = 'Error reading F.MNEMONIC.COMPANY'
        EXIT_code = 15
        GOSUB doexit
    END

    CLOSE f_mnem_cmp

    CALL LOAD.COMPANY(COMPANY_curr)

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
parseparams:

    OPEN 'F.SPF' TO FILE_handle_list(1) ELSE
        ERROR_message = 'Error opening SPF'
        EXIT_code = 12
        GOSUB doexit
    END

    GOSUB ygetdict

    OFS_source_id = SENTENCE(1)
    IF OFS_source_id EQ '' THEN
        ERROR_message = 'Parameters missing'
        EXIT_code = 2
        GOSUB dohelp
        GOSUB doexit
    END

    IF OFS_source_id NE '-' THEN
        OPEN 'F.OFS.SOURCE' TO f_ofs_src ELSE
            ERROR_message = 'Error opening OFS.SOURCE'
            EXIT_code = 3
            GOSUB doexit
        END

        READ ofs_source_rec FROM f_ofs_src, OFS_source_id ELSE
            ERROR_message = 'OFS.SOURCE ' : DQUOTE(OFS_source_id) : ' not found'
            EXIT_code = 4
            GOSUB doexit
        END

        ofs_source_type = ofs_source_rec<OfsSource_SourceType>
        IF ofs_source_type NE 'TELNET' THEN
            ERROR_message = 'OFS.SOURCE type should be "TELNET"'
            EXIT_code = 5
            GOSUB doexit
        END

        CLOSE f_ofs_src

        IF PUTENV('OFS_SOURCE=' : OFS_source_id) THEN NULL
        CALL JF.INITIALISE.CONNECTION
    END

    param_no = 1
    LOOP
        param_no ++
        a_param = SENTENCE(param_no)
        IF a_param EQ '' THEN BREAK

        BEGIN CASE
        CASE a_param[1,3] EQ '-s:'
            SCRIPT_file = FIELD(a_param, ':', 2, 99)

        CASE OTHERWISE
            ERROR_message = 'Unrecognized parameter ' : DQUOTE(a_param)
            EXIT_code = 6
            GOSUB doexit

        END CASE

    REPEAT

    IF SCRIPT_file EQ '' THEN
        ERROR_message = 'Script file not specified'
        EXIT_code = 7
        GOSUB dohelp
        GOSUB doexit
    END

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
readscript:

    OSOPEN SCRIPT_file TO f_in ELSE
        ERROR_message = 'Script file - open error'
        EXIT_code = 8
        GOSUB doexit
    END

* 2 next lines - keep the numbers the same!  TAFJ can't use a variable in OSBREAD
    max_data_len = 100000
    OSBREAD SCRIPT_data FROM f_in AT 0 LENGTH 100000 ON ERROR
        ret_stat = STATUS()
        ERROR_message = 'Script file - read error (status = ' : DQUOTE(ret_stat) : ')'
        EXIT_code = 9
        GOSUB doexit
    END

* this code gives status 9 in TAFJ but the script is read successfully
*    ret_stat = STATUS()
*    IF ret_stat NE 0 THEN
*        ERROR_message = 'Script file - read error (status = ' : DQUOTE(ret_stat) : ')'
*        EXIT_code = 9
*        GOSUB doexit
*    END

    OSCLOSE f_in

    data_len = LEN(SCRIPT_data)

    IF data_len NE BYTELEN(SCRIPT_data) THEN
        ERROR_message = 'Script file - only ASCII characters allowed'
        EXIT_code = 10
        GOSUB doexit
    END

    IF data_len GE max_data_len THEN
        ERROR_message = 'Script file size exceeds maximum allowed (' : (max_data_len - 1) : ')'
        EXIT_code = 11
        GOSUB doexit
    END

    CHANGE CHAR(13) TO '' IN SCRIPT_data
    CHANGE CHAR(10) TO @FM IN SCRIPT_data
    SCRIPT_size = DCOUNT(SCRIPT_data, @FM)

    FOR i = 1 TO SCRIPT_size
        a_line = TRIM(SCRIPT_data<i>, ' ', 'T')
        SCRIPT_data<i> = a_line
        IF a_line[1, 1] EQ ':' THEN
            FIND a_line IN LBL_list SETTING posn ELSE posn = 0

            IF posn GT 0 THEN
                ERROR_message = 'Duplicate label (' : a_line : ')'
                EXIT_code = 19
                GOSUB doexit
            END

            LBL_list<-1> = a_line
            LBL_posn_list<-1> = i
        END
    NEXT i

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
runscript:

    LOOP
        GOSUB ygetnextline
        IF is_EOF THEN

            IF RECORD_curr_init NE RECORD_curr THEN
                ERROR_message = 'Changes not saved - ' : FILE_fname_list<FILE_no_curr>
                EXIT_code = 16
                GOSUB doexit
            END

            EXIT_code = 0
            GOSUB doexit
        END

*        SCRIPT_line = SCRIPT_data<SCRIPT_line_no>
*        IF SCRIPT_line[1,1] EQ '#' THEN CONTINUE   ;*  comment
*        IF SCRIPT_line EQ '' THEN CONTINUE

* TODO registers/@... replacement

        BEGIN CASE

        CASE SCRIPT_line EQ 'alert'       ;     GOSUB xecalert
        CASE SCRIPT_line EQ 'commit'      ;     GOSUB xeccommit
        CASE SCRIPT_line EQ 'debug'       ;     DEBUG
        CASE SCRIPT_line EQ 'exit'        ;     GOSUB xecexit
        CASE SCRIPT_line EQ 'jump'        ;     GOSUB xecjump
        CASE SCRIPT_line EQ 'read'        ;     GOSUB xecread
        CASE SCRIPT_line EQ 'update'      ;     GOSUB xecupdate

        CASE OTHERWISE
            ERROR_message = 'Command not recognized (' : DQUOTE(SCRIPT_line) : ')'
            EXIT_code = 17
            GOSUB doexit


        END CASE

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecalert:

    GOSUB ygetnextline
    IF is_EOF OR SCRIPT_line[1, 1] NE ' ' THEN
        ERROR_message = 'Command not finished properly'
        EXIT_code = 18
        GOSUB doexit
    END
    INFO_list<-1> = '[INFO] ' : TRIM(SCRIPT_line, ' ', 'L')

    LOOP
        GOSUB ygetnextline
        IF SCRIPT_line[1, 1] NE ' ' THEN
            GOSUB yrewind
            BREAK
        END
        INFO_list<-1> = '[INFO] ' : TRIM(SCRIPT_line, ' ', 'L')
    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xeccommit:

*DEBUG

    IF NOT(RECORD_is_new) AND RECORD_curr = RECORD_curr_init THEN
        WARN_list<-1> = '[WARN] LIVE record not changed (' : FILE_fname_list<FILE_no_curr> : '>' : RECORD_id_curr : ')'

        LOOP
            GOSUB ygetnextline
            IF is_EOF OR SCRIPT_line[1, 1] NE ' ' THEN
                GOSUB yrewind
                BREAK
            END
        REPEAT

        RETURN
    END

    commit_mode = 'LIVE'   ;* default
    commit_version = ''   ;* default

    GOSUB ygetnextline
    IF SCRIPT_line[1, 1] EQ ' ' THEN
        to_check = TRIM(SCRIPT_line, ' ', 'L')

        FIND to_check IN COMMIT_options SETTING posn ELSE posn = 0
        IF posn GT 0 THEN
            commit_mode = COMMIT_options<posn>

            GOSUB ygetnextline
            IF SCRIPT_line[1, 1] EQ ' ' THEN
                to_check = TRIM(SCRIPT_line, ' ', 'L')

                IF to_check[1, 1] EQ ',' THEN
                    commit_version = to_check
                END ELSE
                    ERROR_message = 'VERSION expected'
                    EXIT_code = 32
                    GOSUB doexit
                END

            END ELSE
                GOSUB yrewind
            END

        END ELSE
            IF to_check[1, 1] EQ ',' THEN
                commit_version = to_check

                GOSUB ygetnextline
                IF SCRIPT_line[1, 1] EQ ' ' THEN
                    to_check = TRIM(SCRIPT_line, ' ', 'L')
                    FIND to_check IN COMMIT_options SETTING posn ELSE posn = 0
                    IF posn GT 0 THEN
                        commit_mode = COMMIT_options<posn>
                    END ELSE
                        ERROR_message = 'Commit mode expected'
                        EXIT_code = 33
                        GOSUB doexit
                    END

                END ELSE
                    GOSUB yrewind
                END

            END ELSE
                ERROR_message = 'VERSION or commit mode expected'
                EXIT_code = 31
                GOSUB doexit
            END

        END

    END ELSE
        GOSUB yrewind
    END

    IF commit_mode NE 'RAW' THEN

        curr_file = FILE_fname_list<FILE_no_curr>
        IF RIGHT(curr_file, 4) EQ '$NAU' OR RIGHT(curr_file, 4) EQ '$HIS' THEN curr_file = curr_file[1, LEN(curr_file) - 4]

        nau_file = curr_file : '$NAU'
        OPEN nau_file TO f_nau ELSE
            ERROR_message = 'Unable to open ': nau_file
            EXIT_code = 35
            GOSUB doexit
        END

        READ nau_rec FROM f_nau, RECORD_id_curr THEN
            ERROR_message = '$NAU record exists, unable to continue'
            EXIT_code = 36
            GOSUB doexit
        END

    END

    BEGIN CASE

    CASE commit_mode EQ 'IHLD'
        RECORD_curr<REC_STAT_posn> = 'IHLD'
        RECORD_curr<REC_STAT_posn + 1> += 1
        RECORD_curr<REC_STAT_posn + 2> = '42_TODO'
        RECORD_curr<REC_STAT_posn + 3> = OCONV(DATE(), 'DG')[3,6] : OCONV(OCONV(TIME(), 'MT'), 'MCC;:;')

        WRITE RECORD_curr TO f_nau, RECORD_id_curr ON ERROR
            ERROR_message = 'Unable to write to ': nau_file
            EXIT_code = 37
            GOSUB doexit
        END

        info_msg = '[INFO] Record {1}>{2} was left in IHLD status'
        CHANGE '{1}' TO nau_file IN info_msg
        CHANGE '{2}' TO RECORD_id_curr IN info_msg
        INFO_list<-1> = info_msg

*      RECORD_curr<REC_STAT_posn> = ''      ;*  TODO update on commit
*      RECORD_curr<REC_STAT_posn + 1> = 0   ;* CURR.NO; to be incremented on commit
*      RECORD_curr<REC_STAT_posn + 2> = '42_TODO'   ;* INPUTTER  TODO update on LIVE/INAU commit
*      RECORD_curr<REC_STAT_posn + 3> = OCONV(DATE(), 'DG')[3,6] : OCONV(OCONV(TIME(), 'MT'), 'MCC;:;')  ;* DATE.TIME TODO update on commit
*      RECORD_curr<REC_STAT_posn + 4> = ''  ;* AUTHORISER
*      RECORD_curr<REC_STAT_posn + 5> = COMPANY_curr  ;*  CO.CODE TODO update on LIVE/INAU commit
*      RECORD_curr<REC_STAT_posn + 6> = 1  ;* DEPT.CODE - TODO update on LIVE/INAU commit
*

*DEBUG

    CASE commit_mode EQ 'RAW'
        ERROR_message = 'Not yet supported'
        EXIT_code = 999
        GOSUB doexit

        INFO_list<-1> = '[INFO] ' : FILE_fname_list<FILE_no_curr> : '>' : RECORD_id_curr : ': WRITE applied'

    CASE commit_mode EQ 'INAU'
        ERROR_message = 'Not yet supported'
        EXIT_code = 999
        GOSUB doexit

        INFO_list<-1> = '[INFO] ' : FILE_fname_list<FILE_no_curr> : '>' : RECORD_id_curr : ' committed as INAU'

    CASE commit_mode EQ 'LIVE'
        ERROR_message = 'Not yet supported'
        EXIT_code = 999
        GOSUB doexit

        INFO_list<-1> = '[INFO] ' : FILE_fname_list<FILE_no_curr> : '>' : RECORD_id_curr : ' committed'

    END CASE

    RECORD_curr_init = RECORD_curr    ;* at the end - otherwise next read or exit will fail

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecexit:

    GOSUB ygetnextline
    IF is_EOF OR SCRIPT_line[1, 1] NE ' ' THEN
        EXIT_code = 0
    END ELSE EXIT_code = TRIM(SCRIPT_line, ' ', 'L')

    IF NOT(ISDIGIT(EXIT_code)) THEN
        ERROR_message = 'Non-numeric exit code'
        EXIT_code = 21
        GOSUB doexit
    END

    IF EXIT_code GT 0 AND EXIT_code LT 1000 THEN
        ERROR_message = 'Non-zero exit codes less than 1000 are reserved for script interpreter'
        EXIT_code = 22
        GOSUB doexit
    END

    ERROR_message = 'Non-zero exit code detected'
    GOSUB doexit

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecjump:

    GOSUB ygetnextline
    IF is_EOF OR SCRIPT_line[1, 1] NE ' ' THEN
        ERROR_message = 'Command not finished properly'
        EXIT_code = 18
        GOSUB doexit
    END
    lbl_name = TRIM(SCRIPT_line, ' ', 'L')

    FIND lbl_name IN LBL_list SETTING posn ELSE posn = 0
    IF posn EQ 0 THEN
        ERROR_message = 'Label not found (' : lbl_name : ')'
        EXIT_code = 20
        GOSUB doexit
    END

    SCRIPT_line_no = LBL_posn_list<posn>

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecread:

    IF RECORD_curr_init NE RECORD_curr THEN
        ERROR_message = 'Changes not saved - ' : FILE_fname_list<FILE_no_curr>
        EXIT_code = 16
        GOSUB doexit
    END

    GOSUB ygetnextline
    IF is_EOF OR SCRIPT_line[1, 1] NE ' ' THEN
        ERROR_message = 'Command not finished properly'
        EXIT_code = 18
        GOSUB doexit
    END
    table_name = TRIM(SCRIPT_line, ' ', 'L')

    GOSUB ygetnextline
    IF is_EOF OR SCRIPT_line[1, 1] NE ' ' THEN
        ERROR_message = 'Command not finished properly'
        EXIT_code = 18
        GOSUB doexit
    END
    RECORD_id_curr = TRIM(SCRIPT_line, ' ', 'L')

    FIND table_name IN FILE_fname_list SETTING posn ELSE posn = 0
    IF posn = 0 THEN
        hnd_qty = INMAT(FILE_handle_list)
        hnd_qty ++
        DIM FILE_handle_list(hnd_qty)
        OPEN table_name TO FILE_handle_list(hnd_qty) ELSE
            ERROR_message = 'Error opening ' : table_name
            EXIT_code = 13
            GOSUB doexit
        END

        FILE_no_curr = hnd_qty
        FILE_fname_list<-1> = table_name

        DIM DICT_list(FILE_no_curr)
        DIM DICT_list_lref(FILE_no_curr)
        GOSUB ygetdict

    END ELSE
        FILE_no_curr = posn
    END

    RECORD_is_new = @FALSE
    READ RECORD_curr FROM FILE_handle_list(FILE_no_curr), RECORD_id_curr ELSE
        RECORD_is_new = @TRUE
        RECORD_curr = ''
        IF REC_STAT_posn THEN
            RECORD_curr<REC_STAT_posn> = ''      ;*  TODO update on commit
            RECORD_curr<REC_STAT_posn + 1> = 0   ;* CURR.NO; to be incremented on commit
            RECORD_curr<REC_STAT_posn + 2> = '42_TODO'   ;* INPUTTER  TODO update on LIVE/INAU commit
            RECORD_curr<REC_STAT_posn + 3> = OCONV(DATE(), 'DG')[3,6] : OCONV(OCONV(TIME(), 'MT'), 'MCC;:;')  ;* DATE.TIME TODO update on commit
            RECORD_curr<REC_STAT_posn + 4> = ''  ;* AUTHORISER
            RECORD_curr<REC_STAT_posn + 5> = COMPANY_curr  ;*  CO.CODE
            RECORD_curr<REC_STAT_posn + 6> = 1  ;* DEPT.CODE - TODO update on LIVE/INAU commit
        END

    END

    RECORD_curr_init = RECORD_curr   ;* for comparison before commit

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecupdate:

    updt_qty = 0

    LOOP
        GOSUB ygetnextline

        IF is_EOF THEN
            ERROR_message = 'Command not finished properly'
            EXIT_code = 18
            GOSUB doexit
        END

        IF SCRIPT_line[1, 1] NE ' ' THEN
            IF updt_qty EQ 0 THEN
                ERROR_message = 'No updates specified'
                EXIT_code = 34
                GOSUB doexit
            END ELSE
                GOSUB yrewind
                BREAK
            END
        END

        updt_line = TRIM(SCRIPT_line, ' ', 'L')
        fld_name = FIELD(updt_line, ':', 1)
        vm_no = FIELD(updt_line, ':', 2)
        the_rest = FIELD(updt_line, ':', 3, 999999)
        sm_no = FIELD(the_rest, '=', 1)
        new_data = FIELD(the_rest, '=', 2, 999999)

        IF vm_no NE '' AND vm_no NE -1 AND NOT(ISDIGIT(vm_no)) THEN
            ERROR_message = '@VM number is not numeric'
            EXIT_code = 26
            GOSUB doexit
        END

        IF sm_no NE '' AND sm_no NE -1 AND NOT(ISDIGIT(sm_no)) THEN
            ERROR_message = '@SM number is not numeric'
            EXIT_code = 27
            GOSUB doexit
        END

        IF fld_name EQ 'LOCAL.REF' THEN
            ERROR_message = 'Forbidden to update LOCAL.REF, use local field name'
            EXIT_code = 24
            GOSUB doexit
        END

        FIND fld_name IN DICT_list(FILE_no_curr) SETTING fld_posn ELSE fld_posn = 0

        IF fld_posn GT 0 THEN
            is_locref = @FALSE
        END ELSE
            FIND fld_name IN DICT_list_lref(FILE_no_curr) SETTING lr_posn ELSE lr_posn = 0
            IF lr_posn GT 0 THEN
                is_locref = @TRUE
                IF LREF_posn EQ 0 THEN
                    ERROR_message = 'LOCAL.REF not found in DICT of ' : FILE_fname_list<FILE_no_curr>
                    EXIT_code = 25
                    GOSUB doexit
                END

            END ELSE
                ERROR_message = 'Field {1} not found in {2}'
                CHANGE '{1}' TO fld_name IN ERROR_message
                CHANGE '{2}' TO FILE_fname_list<FILE_no_curr> IN ERROR_message
                EXIT_code = 23
                GOSUB doexit
            END
        END

        BEGIN CASE

        CASE vm_no EQ '' AND sm_no EQ ''
            IF is_locref THEN
                RECORD_curr<LREF_posn, lr_posn> = new_data
            END ELSE RECORD_curr<fld_posn> = new_data

        CASE (vm_no EQ '' OR vm_no EQ -1) AND sm_no NE ''
            ERROR_message = '@SM number requires @VM number to be set explicitly, for LOCAL.REF @SM set up in @VM place, e.g. MY.FIELD:2:=DATA'
            EXIT_code = 28
            GOSUB doexit

        CASE vm_no NE '' AND sm_no EQ ''
            IF is_locref THEN RECORD_curr<LREF_posn, lr_posn, vm_no> = new_data
            ELSE RECORD_curr<fld_posn, vm_no> = new_data

        CASE vm_no NE '' AND sm_no NE ''
            IF is_locref THEN
                ERROR_message = 'Subvalue for LOCAL.REF is set up in @VM place, e.g. MY.FIELD:2:=DATA'
                EXIT_code = 29
                GOSUB doexit
            END

            RECORD_curr<fld_posn, vm_no, sm_no> = new_data

        CASE OTHERWISE
            ERROR_message = 'Error parsing update command'
            EXIT_code = 30
            GOSUB doexit

        END CASE

        updt_qty ++

    REPEAT


    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
ygetdict:
* in: FILE_fname_list<FILE_no_curr>
* out: DICT_list(FILE_no_curr)
* out: DICT_list_lref(FILE_no_curr)
* out: REC_STAT_posn

    dict_sel_list = ''    ;   dict_sel_list_lref = ''

    OPEN 'DICT', FILE_fname_list<FILE_no_curr> TO f_dict THEN

        SELECT f_dict TO sel_dict
        LOOP
            WHILE READNEXT dict_id FROM sel_dict DO
            READ r_dict FROM f_dict, dict_id ELSE CONTINUE

            dict_type = r_dict<1>
            BEGIN CASE
                CASE dict_type EQ 'D'
                    dict_num = r_dict<2>
                    IF dict_num EQ '0' OR NOT(ISDIGIT(dict_num)) THEN CONTINUE

                    IF dict_sel_list<dict_num> EQ '' THEN dict_sel_list<dict_num> = dict_id
                    ELSE dict_sel_list<dict_num> := @VM: dict_id   ;* all FINDs will work

                CASE dict_type EQ 'I'   ;* take local.ref only
                    dict_descr = r_dict<2>
                    IF dict_descr[1, 9] EQ 'LOCAL.REF' THEN
                        dict_num = FIELD(dict_descr, ',', 2)
                        CHANGE '>' TO '' IN dict_num
                        CHANGE ' ' TO '' IN dict_num

                        IF ISDIGIT(dict_num) THEN
                            IF dict_sel_list_lref<dict_num> EQ '' THEN dict_sel_list_lref<dict_num> = dict_id
                            ELSE dict_sel_list_lref<dict_num> := @VM: dict_id   ;* all FINDs will work
                        END
                    END

            END CASE

        REPEAT

    END

    FIND 'RECORD.STATUS' IN dict_sel_list SETTING REC_STAT_posn ELSE REC_STAT_posn = 0

    DICT_list(FILE_no_curr) = dict_sel_list
    DICT_list_lref(FILE_no_curr) = dict_sel_list_lref

    FIND 'LOCAL.REF' IN DICT_list(FILE_no_curr) SETTING LREF_posn ELSE LREF_posn = 0

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
ygetnextline:
* in: SCRIPT_data, SCRIPT_line_no
* out: next SCRIPT_line (all empty ones and comments excluded); is_EOF

    LOOP
        SCRIPT_line_no ++
        IF SCRIPT_line_no GT SCRIPT_size THEN
            is_EOF = @TRUE
            RETURN
        END

        SCRIPT_line = SCRIPT_data<SCRIPT_line_no>
        first_char = SCRIPT_line[1, 1]

* comments can be everywhere
        IF first_char EQ '#' OR first_char EQ ':' THEN CONTINUE

        IF TRIM(SCRIPT_line, ' ', 'L') EQ '' THEN CONTINUE

        BREAK

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yrewind:
* rewind script back in case when optional command component is missing

    SCRIPT_line_no --

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
END
