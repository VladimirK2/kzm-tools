PROGRAM tafcj
* By V.Kazimirchik

    INCLUDE JBC.h
    $INSERT I_COMMON
    $INSERT I_EQUATE
    $INSERT I_GTS.COMMON

    $INSERT I_F.OFS.SOURCE
    $INSERT I_F.OFS.REQUEST.DETAIL

    CRT 'tafcj script interpreter 1.2.1'

    GOSUB initvars
    GOSUB parseparams
    GOSUB readscript
    GOSUB runscript

    STOP

*----------------------------------------------------------------------------------------------------------------------------------
doexit:

    IF OUT_file_names NE '' THEN
        out_qty = INMAT(OUT_file_handles)
        FOR i = 1 TO out_qty
            IF ASSIGNED(OUT_file_handles(i)) AND OUT_file_handles(i) NE '' THEN
                info_msg = '[INFO] Closing {}...'
                CHANGE '{}' TO FILEINFO(OUT_file_handles(i), 1)<20> IN info_msg
                INFO_list<-1> = info_msg
                CLOSESEQ OUT_file_handles(i)
            END
        NEXT i
    END

    IF DUP_file NE '' AND f_DUP_file NE '' THEN
        info_msg = '[INFO] Closing {}...'
        CHANGE '{}' TO FILEINFO(f_DUP_file, 1)<20> IN info_msg
        INFO_list<-1> = info_msg
        CLOSESEQ f_DUP_file
    END

    IF INFO_list THEN
        CHANGE @FM TO CHAR(10) IN INFO_list
        CRT INFO_list
    END

    IF EXIT_code NE 2 THEN
        CRT '[INFO] ' : SCRIPT_folder : DIR_DELIM_CH : SCRIPT_file : ' finished' :

        IF EXIT_code EQ 0 THEN CRT ' successfully'
        ELSE
            CRT ''
            CRT '[ERROR] ' : ERROR_message
            CRT 'Exit code: ' : EXIT_code
            IF SCRIPT_line_no GT 0 THEN CRT 'Script line: ' : SCRIPT_line_no
        END

        CRT 'Elapsed time: ' : FMT(TIMESTAMP() - START_time, 'R2') : ' s.'
    END

* otherwise infinite loop in WORLD.DISPLAY.b on EX invocation
    GTSACTIVE = ''

    EXIT(EXIT_code)

*----------------------------------------------------------------------------------------------------------------------------------
dohelp:

    CRT 'by V.Kazimirchik'
    CRT 'Parameters:'
    CRT '------------------------------------'
    CRT '1st one - OFS.SOURCE @ID (or "-" if login to T24 is not necessary)'
    CRT '-s:script_file'
    CRT 'Ones below are optional'
    CRT '-l:<login>     T24 login'
    CRT '-p:<password>  T24 password'
    CRT '-var:<value>   pass a variable, e.g. -var:dayno:T1'
    CRT '-a:<file>      duplicate all alerts to file'

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
initvars:

    IF GETENV('TAFJ_HOME', tafj_home) THEN TAFJ_on = @TRUE    ;* RUNNING.IN.TAFJ might be not yet set
    ELSE TAFJ_on = @FALSE

    AUDT_trail = ''

    CLEAR_mode = @FALSE
    CMD_line = ''
    CMD_line_no = 0
    COMMIT_options = 'INAU' :@FM: 'IHLD' :@FM: 'RAW'

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

    DIM DICT_list(1)                        ;* will expand dynamically
    MAT DICT_list = ''
    DIM DICT_list_lref(1)                     ;* will expand dynamically
    MAT DICT_list_lref = ''
    DUP_dir = ''  ;  DUP_file = ''   ; f_DUP_file = ''

    ERROR_message = 'Unknown error'
    EXIT_code = 1

    DIM FILE_handle_list(1)                     ;* will expand dynamically
    MAT FILE_handle_list = ''
    FILE_fname_list = 'F.SPF'
    FILE_no_curr = 1
    FIRST_space = @FALSE   ;* if we had leading space(s) in script line before trimming
    FLD_name = ''  ;  FLD_posn = ''  ;  IS_lref = @FALSE  ;   LREF_posn = 0  ;   LOCREF_posn = 0

    INFO_list = ''
    is_EOF = @FALSE

    LBL_list = ''  ;  LBL_posn_list = ''  ;  LBL_togo = ''

    MACRO_name_list = 'TODAY' :@FM: 'LCCY' :@FM: 'ID.COMPANY' :@FM: 'FM' :@FM: 'VM' :@FM: 'SM' :@FM: 'TM' :@FM: 'SPACE' :@FM: 'BLANK' :@FM: 'RECORD'
    MACRO_name_list := @FM: 'EXECSCREEN' :@FM: 'EXECRETCODE' :@FM: 'EXECRETDATA' :@FM: 'EXECRETLIST' :@FM: 'LF' :@FM: 'TAB' :@FM: 'DIR_DELIM_CH'
    MACRO_name_list := @FM: 'COMMA' :@FM: 'LPARENTH' :@FM: 'RPARENTH' :@FM: 'USERNAME' :@FM: 'PASSWORD' :@FM: 'OFSCOMMIT' :@FM: 'OFSOUTPUT'
* 25th - ...
    MACRO_name_list := @FM: 'DICT' :@FM: 'LREF' :@FM: 'NEWRECORD' :@FM: 'NUMSEL'

    DIM MACRO_list(DCOUNT(MACRO_name_list, @FM))     ;* will expand dynamically
    MAT MACRO_list = ''
    MACRO_name = ''
    MACRO_value = ''

    MACRO_list(4) = @FM
    MACRO_list(5) = @VM
    MACRO_list(6) = @SM
    MACRO_list(7) = @TM
    MACRO_list(8) = ' '
    MACRO_list(15) = CHAR(10)
    MACRO_list(16) = CHAR(9)
    MACRO_list(17) = DIR_DELIM_CH
    MACRO_list(18) = ','
    MACRO_list(19) = '('
    MACRO_list(20) = ')'
    MACRO_list(27) = -1    ;*  avoid accidental usage before read command

    OFS_msg = ''  ;  FAIL_on_err = @FALSE  ;  DEL_on_err = @FALSE
    OFS_commit_ok = @FALSE  ;  OFS_output = ''
    OUT_file_names = ''
    DIM OUT_file_handles(1)
    MAT OUT_file_handles = ''
    OVERRIDE_posn = -1

    PARAM_info = ''
    PORT_no = SYSTEM(18)

    RECORD_curr = ''
    RECORD_curr_init = ''
    RECORD_id_curr = ''
    RECORD_is_new = @FALSE
    REC_STAT_posn = -1

    SCRIPT_folder = ''
    SCRIPT_file = ''
    SCRIPT_data = ''
    SCRIPT_line = ''
    SCRIPT_line_no = 0
    SCRIPT_size = 0
    DIM SELECT_list(1)     ;* will expand dynamically in getlist
    MAT SELECT_list = ''
    SELECT_name_list = 'DUMMY'
    START_time = TIMESTAMP()

    T24_login = ''   ;  T24_passwd = '' ;  T24_userid = ''

    GOSUB yloadcompany

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

        par_name = FIELD(a_param, ':', 1)

        BEGIN CASE
        CASE par_name EQ '-var'
            MACRO_name = FIELD(a_param, ':', 2)
            MACRO_value = FIELD(a_param, ':', 3, 99999)
            CHANGE '#20' TO ' ' IN MACRO_value
            CHANGE '#3e' TO '>' IN MACRO_value
            CHANGE '#3d' TO '=' IN MACRO_value
            CHANGE '#fe' TO @FM IN MACRO_value
            CHANGE '#fd' TO @VM IN MACRO_value
            CHANGE '#fc' TO @SM IN MACRO_value

            FIND MACRO_name IN MACRO_name_list SETTING posn ELSE posn = 0
            IF posn GT 0 THEN
                ERROR_message = 'Forbidden to redefine internal registers'
                EXIT_code = 53
                GOSUB doexit
            END

            val_for_info = MACRO_value
            CHANGE @FM TO ' (@FM) ' IN val_for_info
            CHANGE @VM TO ' (@VM) ' IN val_for_info
            CHANGE @SM TO ' (@SM) ' IN val_for_info
            PARAM_info<-1> = MACRO_name : ' = ' : DQUOTE(val_for_info)

            GOSUB ysetmacro

        CASE par_name EQ '-a'   ;* 2024-01-19 19:40 duplicate all alerts to file

            out_file_spec = FIELD(a_param, ':', 2, 999)
            CHANGE '/' TO @FM IN out_file_spec
            CHANGE '\' TO @FM IN out_file_spec
            slash_qty = COUNT(out_file_spec, @FM)
            IF slash_qty EQ 0 THEN
                DUP_dir = '.'
                DUP_file = out_file_spec
            END ELSE
                DUP_dir = FIELD(out_file_spec, @FM, 1, slash_qty)
                DUP_file = out_file_spec<slash_qty + 1>
                CHANGE @FM TO DIR_DELIM_CH IN DUP_dir
            END

            IF INDEX(DUP_file, '$', 1) THEN        ;*  see https://strftime.org/  .. can't use "%" in Teamcity
                cur_date = OCONV(DATE(), 'DG')
                cur_time = OCONV(TIME(), 'MTS')
                CHANGE '$Y$' TO cur_date[1, 4] IN DUP_file
                CHANGE '$m$' TO cur_date[5, 2] IN DUP_file
                CHANGE '$d$' TO cur_date[7, 2] IN DUP_file
                CHANGE '$H$' TO cur_time[1, 2] IN DUP_file
                CHANGE '$M$' TO cur_time[4, 2] IN DUP_file
                CHANGE '$S$' TO cur_time[7, 2] IN DUP_file

                CHANGE '$A$' TO OCONV(DATE(), 'DWA') IN DUP_file
                CHANGE '$a$' TO OCONV(DATE(), 'DWA')[1,3] IN DUP_file
                CHANGE '$B$' TO OCONV(DATE(), 'DMA') IN DUP_file
                CHANGE '$b$' TO OCONV(DATE(), 'DMA')[1,3] IN DUP_file

                CHANGE '$TODAY$' TO TODAY IN DUP_file
            END

        CASE par_name EQ '-s'
            script_spec = FIELD(a_param, ':', 2, 99)

            CHANGE '/' TO @FM IN script_spec
            CHANGE '\' TO @FM IN script_spec
            slash_qty = COUNT(script_spec, @FM)

            IF slash_qty EQ 0 THEN
                SCRIPT_folder = '.'
                SCRIPT_file = script_spec
            END ELSE
                SCRIPT_folder = FIELD(script_spec, @FM, 1, slash_qty)
                SCRIPT_file = script_spec<slash_qty + 1>
                CHANGE @FM TO DIR_DELIM_CH IN SCRIPT_folder
            END

        CASE par_name EQ '-l'
            T24_login = FIELD(a_param, ':', 2, 99)
            OPEN 'F.USER.SIGN.ON.NAME' TO f_son ELSE
                ERROR_message = 'Error opening F.USER.SIGN.ON.NAME'
                EXIT_code = 49
                GOSUB doexit
            END
            READ T24_userid FROM f_son, T24_login ELSE
                ERROR_message = 'Not valid T24 login name'
                EXIT_code = 50
                GOSUB doexit
            END
            CLOSE f_son

        CASE par_name EQ '-p'
            T24_passwd = FIELD(a_param, ':', 2, 99)

        CASE 1
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

    IF T24_login NE '' AND T24_passwd EQ '' THEN
        ECHO OFF
        CRT 'Enter T24 password (Enter to cancel) ' :
        INPUT T24_passwd
        ECHO ON

        IF T24_passwd EQ '' THEN
            ERROR_message = 'Cancelled by user'
            EXIT_code = 52
            GOSUB doexit
        END
    END

    MACRO_list(21) = T24_login
    MACRO_list(22) = T24_passwd

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
readscript:

    SCRIPT_data = ''

    OPENSEQ SCRIPT_folder, SCRIPT_file TO f_in ELSE
        ERROR_message = 'Script file - open error'
        EXIT_code = 8
        GOSUB doexit
    END

    CRT 'Script to run: ' : SCRIPT_folder : DIR_DELIM_CH : SCRIPT_file
    IF PARAM_info NE '' THEN
        CHANGE @FM TO CHAR(10) IN PARAM_info
        CRT 'Variable(s) passed to script:'
        CRT PARAM_info
    END
    CRT 'Reading script...'

    LOOP  ;* read all file in one go

        is_eof = @FALSE
        cmd_line = ''
        LOOP
            READSEQ a_chunk FROM f_in ELSE
                is_eof = @TRUE
                BREAK
            END
            chunk_len = BYTELEN(a_chunk)
            cmd_line := a_chunk
            IF TAFJ_on OR chunk_len LT 1024 THEN BREAK
        REPEAT
        IF is_eof AND cmd_line EQ '' THEN BREAK

        SCRIPT_data := cmd_line : CHAR(10)

        IF is_eof THEN BREAK
    REPEAT
    CLOSESEQ f_in

    data_len = LEN(SCRIPT_data)

    IF data_len NE BYTELEN(SCRIPT_data) THEN

        IF TAFJ_on THEN CRT 'Non-printable character(s) found, searching position(s)...'
        ELSE CRT 'Non-printable character(s) found, searching position(s)... (Press any key to cancel)'

        buf_size = 10000   ;   line_no = 1

        FOR i = 1 TO data_len
            IF SYSTEM(14) GT 0 THEN BREAK
            IF MOD(i, 100000) EQ '1' THEN CRT '.' :

            a_buff = SCRIPT_data[i, buf_size]
            IF LEN(a_buff) EQ BYTELEN(a_buff) THEN
                i += buf_size - 1
                line_no += COUNT(a_buff, CHAR(10))
                CONTINUE
            END

            CRT ''
            FOR j = 1 TO buf_size
                a_char = a_buff[j, 1]
                char_num = SEQ(a_char)
                IF char_num EQ 0 THEN BREAK  ;* we are beyond the buffer
                IF SYSTEM(14) GT 0 THEN BREAK
                IF char_num EQ 10 THEN line_no ++
                ELSE
                    IF LEN(a_char) NE BYTELEN(a_char) THEN
                        CRT 'Position ' : i+j : ' (line ' : line_no : '): SEQ(char) = ' : char_num : ', FMT(char, "MX") = ' : FMT(a_char, 'MX')
                    END
                END
            NEXT j
            i += buf_size - 1
        NEXT i
        CRT ''

        ERROR_message = 'Script file - only printable characters allowed'
        EXIT_code = 10
        GOSUB doexit
    END

    CHANGE CHAR(9) TO '    ' IN SCRIPT_data
    CHANGE CHAR(13) TO '' IN SCRIPT_data
    CHANGE CHAR(10) TO @FM IN SCRIPT_data
    SCRIPT_size = DCOUNT(SCRIPT_data, @FM)

    CRT 'Parsing script...'

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

    CRT 'Proceeding ...'

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
preexit:

    IF ( RECORD_curr_init NE RECORD_curr ) AND ( TRIM(RECORD_curr, @FM, 'T') NE TRIM(RECORD_curr_init, @FM, 'T') ) THEN
        ERROR_message = 'Changes not saved - {1}>{2}'
        CHANGE '{1}' TO FILE_fname_list<FILE_no_curr> IN ERROR_message
        CHANGE '{2}' TO RECORD_id_curr IN ERROR_message
        EXIT_code = 16
        GOSUB doexit
    END

    EXIT_code = 0
    GOSUB doexit

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
runscript:

    LOOP
        GOSUB ygetnextline
        IF is_EOF THEN GOSUB preexit

        CMD_line = SCRIPT_line         ;* for error messages, checks etc
        CMD_line_no = SCRIPT_line_no

        BEGIN CASE

        CASE CMD_line EQ 'alert'       ;     GOSUB xecalert   ;* TODO gradually phase out
        CASE CMD_line EQ 'print'       ;     GOSUB xecalert
        CASE CMD_line EQ 'info'       ;     GOSUB xecalert
        CASE CMD_line EQ 'warn'       ;     GOSUB xecalert
        CASE CMD_line EQ 'error'       ;     GOSUB xecalert

        CASE CMD_line EQ 'clear'       ;     GOSUB xecclear
        CASE CMD_line EQ 'clone'       ;     GOSUB xecclone
        CASE CMD_line EQ 'commit'      ;     GOSUB xeccommit
        CASE CMD_line EQ 'company'     ;     GOSUB xeccompany
        CASE CMD_line EQ 'debug'       ;     DEBUG
        CASE CMD_line EQ 'default'     ;     GOSUB xecmove    ;* 1 section, 2 commands
        CASE CMD_line EQ 'delete'      ;     GOSUB xecdelete
        CASE CMD_line EQ 'exec'        ;     GOSUB xecexec
        CASE CMD_line EQ 'exit'        ;     GOSUB xecexit
        CASE CMD_line EQ 'formlist'     ;    GOSUB xecformlist
        CASE CMD_line EQ 'getlist'     ;     GOSUB xecgetlist
        CASE CMD_line EQ 'getnext'     ;     GOSUB xecgetnext
        CASE CMD_line EQ 'jump'        ;     GOSUB xecjump
        CASE CMD_line EQ 'move'        ;     GOSUB xecmove
        CASE CMD_line EQ 'out'         ;     GOSUB xecout
        CASE CMD_line EQ 'outfile'     ;     GOSUB xecoutfile
        CASE CMD_line EQ 'precision'   ;     GOSUB xecprecision
        CASE CMD_line EQ 'read'        ;     GOSUB xecread
        CASE CMD_line EQ 'runofs'      ;     GOSUB xecrunofs
        CASE CMD_line EQ 'select'      ;     GOSUB xecselect
        CASE CMD_line EQ 'sleep'       ;     GOSUB xecsleep
        CASE CMD_line EQ 'update'      ;     GOSUB xecupdate

        CASE 1
            ERROR_message = 'Command not recognized (' : DQUOTE(SCRIPT_line) : ')'
            EXIT_code = 17
            GOSUB doexit

        END CASE

        IF is_EOF THEN GOSUB preexit

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecalert:

    alert_no = 0

    LOOP
        GOSUB ygetnextline
        IF alert_no EQ 0 THEN GOSUB ycheckcmdsyntax
        ELSE
            IF is_EOF THEN RETURN
            IF NOT(FIRST_space) THEN
                GOSUB yrewind
                BREAK
            END
        END

        alert_no ++
        ALERT_msg = SCRIPT_line
        GOSUB yprocalertmsg

        IF CMD_line EQ 'alert' OR CMD_line EQ 'print' THEN   ;* TODO gradually phase out alert
            IF RIGHT(ALERT_msg, 1) EQ ':' THEN
                ALERT_msg = ALERT_msg[1, LEN(ALERT_msg) - 1]
                CRT ALERT_msg :
            END ELSE CRT ALERT_msg
            GOSUB yalertdup
        END ELSE
            INFO_list<-1> = '[' : UPCASE(CMD_line) : '] ' : ALERT_msg
        END

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecclear:

    IF RECORD_id_curr EQ '' THEN
        ERROR_message = 'No "read" command was executed yet'
        EXIT_code = 44
        GOSUB doexit
    END

    CLEAR_mode = @TRUE  ;* don't update empty fields at this mode - can accidentally "extend" the record if an empty field is located after audit trail and then "live record not changed" will never be triggered

    GOSUB yaudtsave
    RECORD_curr = ''
    GOSUB yaudtload

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecclone:

    IF RECORD_id_curr EQ '' THEN
        ERROR_message = 'No "read" command was executed yet'
        EXIT_code = 44
        GOSUB doexit
    END

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    table_name = SCRIPT_line

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    rec_id_cloned = SCRIPT_line

* this might be non-current table, like clone from $HIS to LIVE
    FIND table_name IN FILE_fname_list SETTING posn ELSE posn = 0

    read_ok = @TRUE

    IF posn = 0 THEN
        OPEN table_name TO f_cloned ELSE
            ERROR_message = 'Error opening ' : table_name
            EXIT_code = 13
            GOSUB doexit
        END
        READ RECORD_curr FROM f_cloned, rec_id_cloned ELSE read_ok = @FALSE
        CLOSE f_cloned

    END ELSE
        READ RECORD_curr FROM FILE_handle_list(posn), rec_id_cloned ELSE read_ok = @FALSE
    END

    IF NOT(read_ok) THEN
        ERROR_message = 'Unable to clone from non-existing record'
        EXIT_code = 62
        GOSUB doexit
    END

    IF OVERRIDE_posn THEN RECORD_curr<OVERRIDE_posn> = ''

    GOSUB yaudtload

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xeccommit:

    IF RECORD_id_curr EQ '' THEN
        ERROR_message = 'No "read" command was executed yet'
        EXIT_code = 44
        GOSUB doexit
    END

*  RECORD_curr               : Commitments^LD.LOANS.AND.DEPOSITS^LD.SHRT^^40004^^^^^^^^^^^^^^2^24_S.DONEY2]1_DL.RESTORE^9802171914^13_S.DONEY^LU0010001^1
*  RECORD_curr_init          : Commitments^LD.LOANS.AND.DEPOSITS^LD.SHRT^^40004^^^^^^^^^^^^^^2^24_S.DONEY2]1_DL.RESTORE^9802171914^13_S.DONEY^LU0010001^1^^

    IF NOT(RECORD_is_new) AND (RECORD_curr EQ RECORD_curr_init OR TRIM(RECORD_curr, @FM, 'T') EQ TRIM(RECORD_curr_init, @FM, 'T') ) THEN
        INFO_list<-1> = '[WARN] LIVE record not changed (' : FILE_fname_list<FILE_no_curr> : '>' : RECORD_id_curr : ')'

        LOOP
            GOSUB ygetnextline
            IF is_EOF THEN BREAK
            IF NOT(FIRST_space) THEN
                GOSUB yrewind
                BREAK
            END
        REPEAT

        RETURN
    END

    commit_mode = 'LIVE'   ;* default
    commit_version = ','   ;* default

    GOSUB ygetnextline
    IF FIRST_space THEN
        to_check = SCRIPT_line

        FIND to_check IN COMMIT_options SETTING posn ELSE posn = 0
        IF posn GT 0 THEN
            commit_mode = COMMIT_options<posn>

            GOSUB ygetnextline
            IF NOT(is_EOF) THEN
                IF FIRST_space THEN
                    to_check = SCRIPT_line

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
            END

        END ELSE
            IF to_check[1, 1] EQ ',' THEN
                commit_version = to_check

                GOSUB ygetnextline
                IF NOT(is_EOF) THEN
                    IF FIRST_space THEN
                        to_check = SCRIPT_line
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

    CASE commit_mode EQ 'RAW'

        WRITE RECORD_curr TO FILE_handle_list(FILE_no_curr), RECORD_id_curr ON ERROR
            ERROR_message = 'Unable to write to ': FILE_fname_list<FILE_no_curr>
            EXIT_code = 51
            GOSUB doexit
        END

        INFO_list<-1> = '[INFO] ' : FILE_fname_list<FILE_no_curr> : '>' : RECORD_id_curr : ': WRITE applied'

    CASE commit_mode EQ 'IHLD'
        RECORD_curr<REC_STAT_posn> = 'IHLD'
        RECORD_curr<REC_STAT_posn + 1> += 1

        IF T24_login EQ '' THEN RECORD_curr<REC_STAT_posn + 2> = PORT_no : '_TODO'
        ELSE RECORD_curr<REC_STAT_posn + 2>= PORT_no : '_' : T24_userid

        RECORD_curr<REC_STAT_posn + 3> = OCONV(DATE(), 'DG')[3,6] : OCONV(OCONV(TIME(), 'MT'), 'MCC;:;')
        RECORD_curr<REC_STAT_posn + 4> = ''   ;* clear AUTHORISER

        WRITE RECORD_curr TO f_nau, RECORD_id_curr ON ERROR
            ERROR_message = 'Unable to write to ': nau_file
            EXIT_code = 37
            GOSUB doexit
        END

        info_msg = '[INFO] Record {1}>{2} was left in IHLD status'
        CHANGE '{1}' TO nau_file IN info_msg
        CHANGE '{2}' TO RECORD_id_curr IN info_msg
        INFO_list<-1> = info_msg

    CASE commit_mode EQ 'LIVE' OR commit_mode EQ 'INAU'

*'SPF,/S/PROCESS//0,' : T24$LOGIN : '/' : T24$PASSWD : ',SYSTEM'

        RECORD_curr<REC_STAT_posn> = 'IHLD'
        RECORD_curr<REC_STAT_posn + 1> += 1
        RECORD_curr<REC_STAT_posn + 2> = '42_TODO'
        RECORD_curr<REC_STAT_posn + 3> = OCONV(DATE(), 'DG')[3,6] : OCONV(OCONV(TIME(), 'MT'), 'MCC;:;')

        WRITE RECORD_curr TO f_nau, RECORD_id_curr ON ERROR
            ERROR_message = 'Unable to write to ': nau_file
            EXIT_code = 37
            GOSUB doexit
        END

        BEGIN CASE
        CASE commit_version NE ','
            no_of_auth = ''   ;* default from VERSION
        CASE commit_mode EQ 'INAU'
            no_of_auth = 1
        CASE 1
            no_of_auth = 0
        END CASE

        app_name = FIELD(FILE_fname_list<FILE_no_curr>, '.', 2, 999)

        OFS_msg = '{1}{2}/I/PROCESS//{3},{4}/{5}/{6},{7}'
        CHANGE '{1}' TO app_name IN OFS_msg
        CHANGE '{2}' TO commit_version IN OFS_msg
        CHANGE '{3}' TO no_of_auth IN OFS_msg
        CHANGE '{4}' TO T24_login IN OFS_msg
        CHANGE '{5}' TO T24_passwd IN OFS_msg
        CHANGE '{6}' TO COMPANY_curr IN OFS_msg

        ofs_rec_id = RECORD_id_curr
        special_chars = '",/' ; replace_chars = "|?^" ; CONVERT special_chars TO replace_chars IN ofs_rec_id

        IF LEN(ofs_rec_id) EQ 1 AND ISALPHA(ofs_rec_id) THEN                      ;* e.g. F.INTEREST.BASIS
            CHANGE '{7}' TO ofs_rec_id : '.' IN OFS_msg
        END ELSE
            CHANGE '{7}' TO ofs_rec_id IN OFS_msg
        END

        DEL_on_err = @TRUE
        FAIL_on_err = @TRUE

        GOSUB ylaunchofs

        info_msg =  FILE_fname_list<FILE_no_curr> : '>' : RECORD_id_curr : ' committed'
        IF commit_mode EQ 'INAU' THEN info_msg := ' as INAU'
        INFO_list<-1> = '[INFO] ' : info_msg

    END CASE

    RECORD_curr_init = RECORD_curr    ;* at the end - otherwise next read or exit will fail

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xeccompany:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    COMPANY_curr = SCRIPT_line
    GOSUB yloadcompany

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecdelete:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    table_name = SCRIPT_line

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    record_to_del = SCRIPT_line

    OPEN table_name TO f_for_del ELSE
        ERROR_message = 'Error opening ' : table_name
        EXIT_code = 13
        GOSUB doexit
    END

    rec_exists = @TRUE
    READ rec_dummy FROM f_for_del, record_to_del ELSE rec_exists = @FALSE

    IF rec_exists THEN
        DELETE f_for_del, record_to_del ON ERROR
            ERROR_message = 'Unable to delete {1}>{2}'
            CHANGE '{1}' TO table_name IN ERROR_message
            CHANGE '{2}' TO record_to_del IN ERROR_message
            EXIT_code = 38
            GOSUB doexit
        END
        info_msg = '[INFO] Record {1}>{2} deleted'
    END ELSE
        info_msg = '[WARN] Record {1}>{2} does not exist, unable to delete'
    END

    CHANGE '{1}' TO table_name IN info_msg
    CHANGE '{2}' TO record_to_del IN info_msg
    INFO_list<-1> = info_msg

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecexec:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    exec_cmd = SCRIPT_line
    cmd_line_no = SCRIPT_line_no

* optional expected return code

    GOSUB ygetnextline
    IF is_EOF OR NOT(FIRST_space) THEN
        check_ret_code = @FALSE
        GOSUB yrewind
    END ELSE
        check_ret_code = @TRUE
        exp_ret_code = SCRIPT_line
    END

    EXECUTE exec_cmd CAPTURING exec_screen RETURNING exec_ret_code RTNDATA exec_ret_data RTNLIST exec_ret_list
    CHANGE @FM TO CHAR(10) IN exec_screen
    MACRO_list(11) = exec_screen
    MACRO_list(12) = exec_ret_code
    MACRO_list(13) = exec_ret_data
    MACRO_list(14) = exec_ret_list

    IF check_ret_code AND exec_ret_code NE exp_ret_code THEN
        ERROR_message = 'Command at the line {1}: return code "{2}", expected : "{3}"'
        CHANGE '{1}' TO cmd_line_no IN ERROR_message
        CHANGE '{2}' TO exec_ret_code IN ERROR_message
        CHANGE '{3}' TO exp_ret_code IN ERROR_message
        CHANGE @FM TO ' (@FM) ' IN ERROR_message
        CHANGE @VM TO ' (@VM) ' IN ERROR_message
        CHANGE @SM TO ' (@SM) ' IN ERROR_message
        CHANGE @TM TO ' (@TM) ' IN ERROR_message
        EXIT_code = 56
        GOSUB doexit
    END

    info_msg = '[INFO] Command at the line {1}: return code "{2}"'
    IF check_ret_code THEN info_msg := ' (as expected)'
    CHANGE '{1}' TO cmd_line_no IN info_msg
    CHANGE '{2}' TO exec_ret_code IN info_msg
    CHANGE @FM TO ' (@FM) ' IN info_msg
    CHANGE @VM TO ' (@VM) ' IN info_msg
    CHANGE @SM TO ' (@SM) ' IN info_msg
    CHANGE @TM TO ' (@TM) ' IN info_msg
    INFO_list<-1> = info_msg

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecexit:

    IF ( RECORD_curr_init NE RECORD_curr ) AND ( TRIM(RECORD_curr, @FM, 'T') NE TRIM(RECORD_curr_init, @FM, 'T') ) THEN
        ERROR_message = 'Changes not saved - {1}>{2}'
        CHANGE '{1}' TO FILE_fname_list<FILE_no_curr> IN ERROR_message
        CHANGE '{2}' TO RECORD_id_curr IN ERROR_message
        EXIT_code = 16
        GOSUB doexit
    END

    GOSUB ygetnextline
    IF is_EOF OR NOT(FIRST_space) THEN
        EXIT_code = 0
    END ELSE EXIT_code = SCRIPT_line
    IF EXIT_code EQ 1000 THEN EXIT_code = 0   ;*  TODO gradually phase out 1000

    IF NOT(ISDIGIT(EXIT_code)) THEN
        ERROR_message = 'Non-numeric exit code'
        EXIT_code = 21
        GOSUB doexit
    END

    IF EXIT_code GT 0 AND EXIT_code LT 1000 THEN    ;*  TODO gradually phase out 1000
        ERROR_message = 'Exit codes 1 - 999 are reserved for script interpreter'
        EXIT_code = 22
        GOSUB doexit
    END

    ERROR_message = 'Non-zero user exit code detected'
    GOSUB doexit

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecformlist:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    sel_list_name = SCRIPT_line

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    sel_list_array = SCRIPT_line

    FIND sel_list_name IN SELECT_name_list SETTING posn ELSE posn = 0
    IF posn = 0 THEN
        sel_qty = INMAT(SELECT_list)
        sel_qty ++
        DIM SELECT_list(sel_qty)
        SELECT_name_list<-1> = sel_list_name
        posn = sel_qty
    END

    FORMLIST sel_list_array TO SELECT_list(posn)

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecgetlist:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    sel_list_name = SCRIPT_line

    FIND sel_list_name IN SELECT_name_list SETTING posn ELSE posn = 0
    IF posn = 0 THEN
        sel_qty = INMAT(SELECT_list)
        sel_qty ++
        DIM SELECT_list(sel_qty)
        SELECT_name_list<-1> = sel_list_name
        posn = sel_qty
    END

    GETLIST sel_list_name TO SELECT_list(posn) SETTING num_sel ELSE
        ERROR_message = 'SELECT list does not exist'
        EXIT_code = 42
        GOSUB doexit
    END

    MACRO_list(28) = num_sel

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecgetnext:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    sel_list_name = SCRIPT_line

    FIND sel_list_name IN SELECT_name_list SETTING posn ELSE
        ERROR_message = 'SELECT list does not exist'
        EXIT_code = 42
        GOSUB doexit
    END

    READNEXT MACRO_value FROM SELECT_list(posn) ELSE
        LBL_togo = ':no_more_' : sel_list_name    ;* default one
        GOSUB yjump
        RETURN
    END

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    MACRO_name = SCRIPT_line
    GOSUB ysetmacro

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecjump:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    LBL_togo = SCRIPT_line
    GOSUB yjump

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecmove:

    cmds_qty = 0
    LOOP
        cmds_qty ++
        GOSUB ygetnextline

        IF cmds_qty EQ 1 THEN GOSUB ycheckcmdsyntax
        ELSE
            IF is_EOF THEN BREAK
            IF NOT(FIRST_space) THEN
                GOSUB yrewind
                BREAK
            END
        END

        MACRO_name = SCRIPT_line

        GOSUB ygetnextline
        GOSUB ycheckcmdsyntax
        eval_keyword = SCRIPT_line

        FIND eval_keyword IN 'const' :@FM: 'field' :@FM: 'func' :@FM: 'subr' SETTING a_dummy ELSE
            ERROR_message = 'Command "{1}": keyword "{2}" is not supported'
            CHANGE '{1}' TO CMD_line IN ERROR_message
            CHANGE '{2}' TO eval_keyword IN ERROR_message
            EXIT_code = 43
            GOSUB doexit
        END

        GOSUB ygetnextline
        GOSUB ycheckcmdsyntax

        IF eval_keyword NE 'func' THEN
            macro_qty = INMAT(MACRO_list)
            FOR i = 1 TO macro_qty
                macro_spec = '$' : MACRO_name_list<i> : '$'
                macro_val = MACRO_list(i)
                IF INDEX(SCRIPT_line, macro_spec, 1) THEN CHANGE macro_spec TO macro_val IN SCRIPT_line
            NEXT i
        END
        eval_cmd = SCRIPT_line

        IF CMD_line EQ 'default' THEN   ;* don't do it if it's already assigned
            FIND MACRO_name IN MACRO_name_list SETTING posn ELSE posn = 0
            IF posn GT 0 THEN CONTINUE
        END

        BEGIN CASE
        CASE eval_keyword EQ 'const'

            MACRO_value = eval_cmd
            GOSUB ysetmacro

        CASE eval_keyword EQ 'field'
            FLD_name = eval_cmd
            GOSUB yfindfield

            IF IS_lref THEN
                MACRO_value = RECORD_curr<LOCREF_posn, LREF_posn>
            END ELSE MACRO_value = RECORD_curr<FLD_posn>
            GOSUB ysetmacro

        CASE eval_keyword EQ 'subr'
            subr_name = FIELD(eval_cmd, ' ', 1)
            data_in = FIELD(eval_cmd, ' ', 2, 9999)
            CALL @subr_name(data_out, data_in)     ;* TODO check if exists
            MACRO_value = data_out
            GOSUB ysetmacro

        CASE eval_keyword EQ 'func'

            parn_open = INDEX(eval_cmd, '(', 1)  ;  parn_close = INDEX(eval_cmd, ')', 1)

            IF NOT(parn_open) OR NOT(parn_close) THEN
                ERROR_message = 'One or both parentheses missing in function definition'
                EXIT_code = 45
                GOSUB doexit
            END

            IF INDEX(eval_cmd, '(', 2) OR INDEX(eval_cmd, ')', 2) THEN
                ERROR_message = 'Only one set of parentheses allowed in function definition'
                EXIT_code = 46
                GOSUB doexit
            END

            func_name = TRIM(eval_cmd[1, parn_open - 1], ' ', 'B')
            args_raw_list = eval_cmd[parn_open + 1, (parn_close - 1 - parn_open)]
            BEGIN CASE
            CASE TRIM(args_raw_list, ' ', 'B') EQ ''
                args_qty = 0
            CASE INDEX(args_raw_list, ',', 1)
                args_qty = DCOUNT(args_raw_list, ',')
            CASE 1
                args_qty = 1
            END CASE

* no args
            FUNC_args = '_DATE_TIME_FILEINFO_GETCWD_INPUT_TIMEDATE_TIMESTAMP_UNIQUEKEY_'
* 1 arg
            FUNC_args<2> = '_ABS_ABSS_ALPHA_BYTELEN_CHAR_CHARS_DIR_DOWNCASE_DQUOTE_DROUND_DTX_GETENV_LEN_LENS_RND_INPUT_INT_ISALPHA_ISALNUM_ISCNTRL_ISDIGIT_ISLOWER_'
            FUNC_args<2> := 'ISPRINT_ISSPACE_ISUPPER_LOWER_MAXIMUM_MINIMUM_NEG_NEGS_NOT_NOTS_NUM_NUMS_PUTENV_RAISE_SENTENCE_SEQ_SEQS_SORT_SPACE_SPACES_SQRT_SQUOTE_'
            FUNC_args<2> := 'SUM_SYSTEM_TRIM_UPCASE_XTD_'
* 2 args
            FUNC_args<3> = '_ADDS_ANDS_CATS_CHANGETIMESTAMP_COUNT_COUNTS_DCOUNT_DEL_DIV_DIVS_DROUND_EQ_EQS_EXTRACT_FADD_FDIV_FIND_FINDSTR_FMUL_FMT_FMTS_FOLD_FSUB_'
            FUNC_args<3> := 'GE_GES_GT_ICONV_ICONVS_LE_LEFT_LES_LOCALDATE_LOCALTIME_LT_MATCHES_MOD_MODS_MULS_NE_NES_OCONV_OCONVS_ORS_PWR_REGEXP_RIGHT_SADD_SDIV_SMUL_'
            FUNC_args<3> := 'STR_STRS_SSUB_SUBS_TRIM_'
* 3 args
            FUNC_args<4> =  '_CHANGE_CONVERT_DEL_EREPLACE_EXTRACT_FIELD_FIELDS_FIND_FINDSTR_IFS_INDEX_INS_MAKETIMESTAMP_MATCHFIELD_REPLACE_SPLICE_SUBSTRINGS_'
            FUNC_args<4> := 'TIMEDIFF_TRIM_'
* 4 args
            FUNC_args<5> = '_DEL_EREPLACE_EXTRACT_FIELD_FIELDS_INS_REPLACE_TRANS_'
* 5 args
            FUNC_args<6> = '_EREPLACE_INS_REPLACE_'

            macro_qty = INMAT(MACRO_list)
            FOR i = 1 TO macro_qty
                macro_spec = '$' : MACRO_name_list<i> : '$'
                macro_val = MACRO_list(i)
                IF INDEX(func_name, macro_spec, 1) THEN CHANGE macro_spec TO macro_val IN func_name
            NEXT i

            IF NOT(INDEX(FUNC_args<args_qty+1>, '_' : func_name : '_', 1)) THEN
                ERROR_message = 'Function "{1}" not found in the list of functions with {2} parameter(s)'
                CHANGE '{1}' TO func_name IN ERROR_message
                CHANGE '{2}' TO args_qty IN ERROR_message
                EXIT_code = 47
                GOSUB doexit
            END

            DIM args_list(args_qty)
            MAT args_list = ''

            FOR i_arg = 1 TO args_qty
                the_arg = TRIM(FIELD(args_raw_list, ',' , i_arg), ' ', 'B')   ;* keep spaces inside

                macro_qty = INMAT(MACRO_list)
                FOR i = 1 TO macro_qty
                    macro_spec = '$' : MACRO_name_list<i> : '$'
                    macro_val = MACRO_list(i)
                    IF INDEX(the_arg, macro_spec, 1) THEN CHANGE macro_spec TO macro_val IN the_arg
                NEXT i

                args_list(i_arg) = the_arg

            NEXT i_arg

            BEGIN CASE
            CASE func_name EQ 'ABS'
                MACRO_value = ABS(args_list(1))

            CASE func_name EQ 'ABSS'
                MACRO_value = ABSS(args_list(1))

            CASE func_name EQ 'ADDS'
                MACRO_value = ADDS(args_list(1), args_list(2))

            CASE func_name EQ 'ALPHA'
                MACRO_value = ALPHA(args_list(1))

            CASE func_name EQ 'ANDS'
                MACRO_value = ANDS(args_list(1), args_list(2))

            CASE func_name EQ 'BYTELEN'
                MACRO_value = BYTELEN(args_list(1))

            CASE func_name EQ 'CATS'
                MACRO_value = CATS(args_list(1), args_list(2))

            CASE func_name EQ 'CHANGE'
                MACRO_value = CHANGE(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'CHANGETIMESTAMP'
                MACRO_value = CHANGETIMESTAMP(args_list(1), args_list(2))

            CASE func_name EQ 'CHAR'
                MACRO_value = CHAR(args_list(1))

            CASE func_name EQ 'CHARS'
                MACRO_value = CHARS(args_list(1))

            CASE func_name EQ 'CONVERT'
                MACRO_value = CONVERT(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'COUNT'
                MACRO_value = COUNT(args_list(1), args_list(2))

            CASE func_name EQ 'COUNTS'
                MACRO_value = COUNTS(args_list(1), args_list(2))

            CASE func_name EQ 'DATE'
                MACRO_value = DATE()

            CASE func_name EQ 'DCOUNT'
                MACRO_value = DCOUNT(args_list(1), args_list(2))

            CASE func_name EQ 'DEL'
                BEGIN CASE
                CASE args_qty EQ 2
                    DEL args_list(1)<args_list(2)>
                CASE args_qty EQ 3
                    DEL args_list(1)<args_list(2), args_list(3)>
                CASE args_qty EQ 4
                    DEL args_list(1)<args_list(2), args_list(3), args_list(4)>
                END CASE
                MACRO_value = args_list(1)

            CASE func_name EQ 'DIR'
                MACRO_value = DIR(args_list(1))

            CASE func_name EQ 'DIV'
                MACRO_value = DIV(args_list(1), args_list(2))

            CASE func_name EQ 'DIVS'
                MACRO_value = DIVS(args_list(1), args_list(2))

            CASE func_name EQ 'DOWNCASE'
                MACRO_value = DOWNCASE(args_list(1))

            CASE func_name EQ 'DQUOTE'
                MACRO_value = DQUOTE(args_list(1))

            CASE func_name EQ 'DROUND'
                IF args_qty EQ 2 THEN MACRO_value = DROUND(args_list(1), args_list(2))
                ELSE MACRO_value = DROUND(args_list(1))

            CASE func_name EQ 'DTX'
                MACRO_value = DTX(args_list(1))

            CASE func_name EQ 'EQ'
                MACRO_value = (args_list(1) EQ args_list(2))

            CASE func_name EQ 'EQS'
                MACRO_value = EQS(args_list(1), args_list(2))

            CASE func_name EQ 'EREPLACE'
                BEGIN CASE
                CASE args_qty EQ 3
                    MACRO_value = EREPLACE(args_list(1), args_list(2), args_list(3))
                CASE args_qty EQ 4
                    MACRO_value = EREPLACE(args_list(1), args_list(2), args_list(3), args_list(4))
                CASE args_qty EQ 5
                    MACRO_value = EREPLACE(args_list(1), args_list(2), args_list(3), args_list(4), args_list(5))
                END CASE

            CASE func_name EQ 'EXTRACT'
                BEGIN CASE
                CASE args_qty EQ 2
                    MACRO_value = EXTRACT(args_list(1), args_list(2))
                CASE args_qty EQ 3
                    MACRO_value = EXTRACT(args_list(1), args_list(2), args_list(3))
                CASE args_qty EQ 4
                    MACRO_value = EXTRACT(args_list(1), args_list(2), args_list(3), args_list(4))
                END CASE

            CASE func_name EQ 'FADD'
                MACRO_value = FADD(args_list(1), args_list(2))

            CASE func_name EQ 'FDIV'
                MACRO_value = FDIV(args_list(1), args_list(2))

            CASE func_name EQ 'FIELD'
                IF args_qty EQ 3 THEN MACRO_value = FIELD(args_list(1), args_list(2), args_list(3))
                ELSE MACRO_value = FIELD(args_list(1), args_list(2), args_list(3), args_list(4))

            CASE func_name EQ 'FIELDS'
                IF args_qty EQ 3 THEN MACRO_value = FIELDS(args_list(1), args_list(2), args_list(3))
                ELSE MACRO_value = FIELDS(args_list(1), args_list(2), args_list(3), args_list(4))

            CASE func_name EQ 'FILEINFO'
                MACRO_value = FILEINFO(FILE_handle_list(FILE_no_curr), 1)

            CASE func_name EQ 'FIND'
                IF args_qty EQ 2 THEN
                    FIND args_list(1) IN args_list(2) SETTING fm_posn, vm_posn, sm_posn ELSE
                        fm_posn = -1
                    END
                END ELSE
                    FIND args_list(1) IN args_list(2), args_list(3) SETTING fm_posn, vm_posn, sm_posn ELSE
                        fm_posn = -1
                    END
                END

                IF fm_posn EQ -1 THEN MACRO_value = -1
                ELSE MACRO_value = fm_posn :@FM: vm_posn :@FM: sm_posn

            CASE func_name EQ 'FINDSTR'
                IF args_qty EQ 2 THEN
                    FINDSTR args_list(1) IN args_list(2) SETTING fm_posn, vm_posn, sm_posn ELSE
                        fm_posn = -1
                    END
                END ELSE
                    FINDSTR args_list(1) IN args_list(2), args_list(3) SETTING fm_posn, vm_posn, sm_posn ELSE
                        fm_posn = -1
                    END
                END

                IF fm_posn EQ -1 THEN MACRO_value = -1
                ELSE MACRO_value = fm_posn :@FM: vm_posn :@FM: sm_posn

            CASE func_name EQ 'FMT'
                MACRO_value = FMT(args_list(1), args_list(2))

            CASE func_name EQ 'FMTS'
                MACRO_value = FMTS(args_list(1), args_list(2))

            CASE func_name EQ 'FMUL'
                MACRO_value = FMUL(args_list(1), args_list(2))

            CASE func_name EQ 'FOLD'
                MACRO_value = FOLD(args_list(1), args_list(2))

            CASE func_name EQ 'FSUB'
                MACRO_value = FSUB(args_list(1), args_list(2))

            CASE func_name EQ 'GE'
                MACRO_value = (args_list(1) GE args_list(2))

            CASE func_name EQ 'GES'
                MACRO_value = GES(args_list(1), args_list(2))

            CASE func_name EQ 'GETCWD'
                IF GETCWD(MACRO_value) THEN NULL

            CASE func_name EQ 'GETENV'
                IF GETENV(args_list(1), MACRO_value) THEN NULL
                ELSE MACRO_value = ''

            CASE func_name EQ 'GT'
                MACRO_value = (args_list(1) GT args_list(2))

            CASE func_name EQ 'ICONV'
                MACRO_value = ICONV(args_list(1), args_list(2))

            CASE func_name EQ 'ICONVS'
                MACRO_value = ICONVS(args_list(1), args_list(2))

            CASE func_name EQ 'IFS'
                MACRO_value = IFS(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'INDEX'
                MACRO_value = INDEX(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'INPUT'
                IF args_qty EQ 0 THEN
                    INPUT MACRO_value
                END ELSE
                    INPUT MACRO_value FOR args_list(1) ELSE MACRO_value = ''
                END

            CASE func_name EQ 'INS'
                BEGIN CASE
                CASE args_qty EQ 3
                    INS args_list(1) BEFORE args_list(2)<args_list(3)>
                CASE args_qty EQ 4
                    INS args_list(1) BEFORE args_list(2)<args_list(3), args_list(4)>
                CASE args_qty EQ 5
                    INS args_list(1) BEFORE args_list(2)<args_list(3), args_list(4), args_list(5)>
                END CASE
                MACRO_value = args_list(2)

            CASE func_name EQ 'INT'
                MACRO_value = INT(args_list(1))

            CASE func_name EQ 'ISALPHA'
                MACRO_value = ISALPHA(args_list(1))

            CASE func_name EQ 'ISALNUM'
                MACRO_value = ISALNUM(args_list(1))

            CASE func_name EQ 'ISCNTRL'
                MACRO_value = ISCNTRL(args_list(1))

            CASE func_name EQ 'ISDIGIT'
                MACRO_value = ISDIGIT(args_list(1))

            CASE func_name EQ 'ISLOWER'
                MACRO_value = ISLOWER(args_list(1))

            CASE func_name EQ 'ISPRINT'
                MACRO_value = ISPRINT(args_list(1))

            CASE func_name EQ 'ISSPACE'
                MACRO_value = ISSPACE(args_list(1))

            CASE func_name EQ 'ISUPPER'
                MACRO_value = ISUPPER(args_list(1))

            CASE func_name EQ 'LE'
                MACRO_value = (args_list(1) LE args_list(2))

            CASE func_name EQ 'LEFT'
                MACRO_value = LEFT(args_list(1), args_list(2))

            CASE func_name EQ 'LEN'
                MACRO_value = LEN(args_list(1))

            CASE func_name EQ 'LENS'
                MACRO_value = LENS(args_list(1))

            CASE func_name EQ 'LES'
                MACRO_value = LES(args_list(1), args_list(2))

            CASE func_name EQ 'LOCALDATE'
                MACRO_value = LOCALDATE(args_list(1), args_list(2))

            CASE func_name EQ 'LOCALTIME'
                MACRO_value = LOCALTIME(args_list(1), args_list(2))

            CASE func_name EQ 'LOWER'
                MACRO_value = LOWER(args_list(1))

            CASE func_name EQ 'LT'
                MACRO_value = (args_list(1) LT args_list(2))

            CASE func_name EQ 'MAKETIMESTAMP'
                MACRO_value = MAKETIMESTAMP(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'MATCHES'
                MACRO_value = (args_list(1) MATCHES args_list(2))

            CASE func_name EQ 'MATCHFIELD'
                MACRO_value = MATCHFIELD(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'MAXIMUM'
                MACRO_value = MAXIMUM(args_list(1))

            CASE func_name EQ 'MINIMUM'
                MACRO_value = MINIMUM(args_list(1))

            CASE func_name EQ 'MOD'
                MACRO_value = MOD(args_list(1), args_list(2))

            CASE func_name EQ 'MODS'
                MACRO_value = MODS(args_list(1), args_list(2))

            CASE func_name EQ 'MULS'
                MACRO_value = MULS(args_list(1), args_list(2))

            CASE func_name EQ 'NE'
                MACRO_value = (args_list(1) NE args_list(2))

            CASE func_name EQ 'NEG'
                MACRO_value = NEG(args_list(1))

            CASE func_name EQ 'NEGS'
                MACRO_value = NEGS(args_list(1))

            CASE func_name EQ 'NES'
                MACRO_value = NES(args_list(1), args_list(2))

            CASE func_name EQ 'NOT'
                MACRO_value = NOT(args_list(1))

            CASE func_name EQ 'NOTS'
                MACRO_value = NOTS(args_list(1))

            CASE func_name EQ 'NUM'
                MACRO_value = NUM(args_list(1))

            CASE func_name EQ 'NUMS'
                MACRO_value = NUMS(args_list(1))

            CASE func_name EQ 'OCONV'
                MACRO_value = OCONV(args_list(1), args_list(2))

            CASE func_name EQ 'OCONVS'
                MACRO_value = OCONVS(args_list(1), args_list(2))

            CASE func_name EQ 'ORS'
                MACRO_value = ORS(args_list(1), args_list(2))

            CASE func_name EQ 'PUTENV'
                MACRO_value = PUTENV(args_list(1))

            CASE func_name EQ 'PWR'
                MACRO_value = PWR(args_list(1), args_list(2))

            CASE func_name EQ 'RAISE'
                MACRO_value = RAISE(args_list(1))

            CASE func_name EQ 'REGEXP'
                MACRO_value = REGEXP(args_list(1), args_list(2))

            CASE func_name EQ 'REPLACE'
                BEGIN CASE
                CASE args_qty EQ 3
                    MACRO_value = REPLACE(args_list(1), args_list(2); args_list(3))
                CASE args_qty EQ 4
                    MACRO_value = REPLACE(args_list(1), args_list(2), args_list(3); args_list(4))
                CASE args_qty EQ 5
                    MACRO_value = REPLACE(args_list(1), args_list(2), args_list(3), args_list(4); args_list(5))
                END CASE

            CASE func_name EQ 'RIGHT'
                MACRO_value = RIGHT(args_list(1), args_list(2))

            CASE func_name EQ 'RND'
                MACRO_value = RND(args_list(1))

            CASE func_name EQ 'SADD'
                MACRO_value = SADD(args_list(1), args_list(2))

            CASE func_name EQ 'SDIV'
                MACRO_value = SDIV(args_list(1), args_list(2))

            CASE func_name EQ 'SENTENCE'
                MACRO_value = SENTENCE(args_list(1))

            CASE func_name EQ 'SEQ'
                MACRO_value = SEQ(args_list(1))

            CASE func_name EQ 'SEQS'
                seqs_in = args_list(1)
                GOSUB yseqsemu
                MACRO_value = seqs_out

            CASE func_name EQ 'SMUL'
                MACRO_value = SMUL(args_list(1), args_list(2))

            CASE func_name EQ 'SORT'
                MACRO_value = SORT(args_list(1))

            CASE func_name EQ 'SPACE'
                MACRO_value = SPACE(args_list(1))

            CASE func_name EQ 'SPACES'
                MACRO_value = SPACES(args_list(1))

            CASE func_name EQ 'SPLICE'
                MACRO_value = SPLICE(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'SQRT'
                MACRO_value = SQRT(args_list(1))

            CASE func_name EQ 'SSUB'
                MACRO_value = SSUB(args_list(1), args_list(2))

            CASE func_name EQ 'STR'
                MACRO_value = STR(args_list(1), args_list(2))

            CASE func_name EQ 'STRS'
                MACRO_value = STRS(args_list(1), args_list(2))

            CASE func_name EQ 'SUBS'
                MACRO_value = SUBS(args_list(1), args_list(2))

            CASE func_name EQ 'SQUOTE'
                MACRO_value = SQUOTE(args_list(1))

            CASE func_name EQ 'SUBSTRINGS'
                MACRO_value = SUBSTRINGS(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'SUM'
                MACRO_value = SUM(args_list(1))

            CASE func_name EQ 'SYSTEM'
                MACRO_value = SYSTEM(args_list(1))

            CASE func_name EQ 'TIME'
                MACRO_value = TIME()

            CASE func_name EQ 'TIMEDATE'
                MACRO_value = TIMEDATE()

            CASE func_name EQ 'TIMEDIFF'
                MACRO_value = TIMEDIFF(args_list(1), args_list(2), args_list(3))

            CASE func_name EQ 'TIMESTAMP'
                MACRO_value = TIMESTAMP()

            CASE func_name EQ 'TRANS'
                MACRO_value = TRANS(args_list(1), args_list(2), args_list(3), args_list(4))

            CASE func_name EQ 'TRIM'
                BEGIN CASE
                CASE args_qty EQ 1
                    MACRO_value = TRIM(args_list(1))
                CASE args_qty EQ 2
                    MACRO_value = TRIM(args_list(1), args_list(2))
                CASE args_qty EQ 3
                    MACRO_value = TRIM(args_list(1), args_list(2), args_list(3))
                END CASE

            CASE func_name EQ 'UNIQUEKEY'
                MACRO_value = UNIQUEKEY()

            CASE func_name EQ 'UPCASE'
                MACRO_value = UPCASE(args_list(1))

            CASE func_name EQ 'XTD'
                MACRO_value = XTD(args_list(1))

            END CASE

            GOSUB ysetmacro

        END CASE
    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecout:
* this command should be repeated when file number changes

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    out_file_no = SCRIPT_line
    IF OUT_file_names<out_file_no> EQ '' THEN
        ERROR_message = 'No file for area number {} opened for output'
        CHANGE '{}' TO out_file_no IN ERROR_message
        EXIT_code = 60
        GOSUB doexit
    END

    iter_no = 0
    LOOP
        iter_no +=1

        GOSUB ygetnextline
        IF iter_no EQ 1 THEN
            GOSUB ycheckcmdsyntax
        END ELSE
            IF is_EOF THEN BREAK
            IF NOT(FIRST_space) THEN
                GOSUB yrewind
                BREAK
            END
        END
        output = SCRIPT_line
        WRITESEQ output TO OUT_file_handles(out_file_no) ELSE
            ERROR_message = 'Error writing to output file for area number {}'
            CHANGE '{}' TO out_file_no IN ERROR_message
            EXIT_code = 61
            GOSUB doexit
        END
    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecoutfile:

    iter_no = 0
    LOOP
        iter_no +=1

        GOSUB ygetnextline
        IF iter_no EQ 1 THEN
            GOSUB ycheckcmdsyntax
        END ELSE
            IF is_EOF THEN BREAK
            IF NOT(FIRST_space) THEN
                GOSUB yrewind
                BREAK
            END
        END
        out_file_no = SCRIPT_line

        IF OUT_file_names<out_file_no> NE '' THEN
            ERROR_message = 'Area number {} already used for output'
            CHANGE '{}' TO out_file_no IN ERROR_message
            EXIT_code = 59
            GOSUB doexit
        END

        GOSUB ygetnextline
        GOSUB ycheckcmdsyntax
        out_file_fldr = SCRIPT_line

        GOSUB ygetnextline
        GOSUB ycheckcmdsyntax
        out_file_name = SCRIPT_line

        out_file_spec = out_file_fldr : DIR_DELIM_CH : out_file_name
        CHANGE '/' TO DIR_DELIM_CH IN out_file_spec
        CHANGE '\' TO DIR_DELIM_CH IN out_file_spec
        FIND out_file_spec IN OUT_file_names SETTING posn ELSE posn = 0
        IF posn GT 0 THEN
            ERROR_message = 'File {} already used for output'
            CHANGE '{}' TO out_file_spec IN ERROR_message
            EXIT_code = 57
            GOSUB doexit
        END
        OUT_file_names<out_file_no> = out_file_spec
        IF INMAT(OUT_file_handles) LT out_file_no THEN
            DIM OUT_file_handles(out_file_no)
        END

        OPENSEQ out_file_fldr, out_file_name TO OUT_file_handles(out_file_no) ELSE CREATE OUT_file_handles(out_file_no) ELSE
            ERROR_message = 'Unable to create file {} for output'
            CHANGE '{}' TO out_file_spec IN ERROR_message
            EXIT_code = 58
            GOSUB doexit
        END
        WEOFSEQ OUT_file_handles(out_file_no)

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecprecision:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    IF NOT(ISDIGIT(SCRIPT_line)) THEN
        ERROR_message = 'Non-numeric PRECISION detected'
        EXIT_code = 55
        GOSUB doexit
    END

    PRECISION SCRIPT_line

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecread:

    IF ( RECORD_curr_init NE RECORD_curr ) AND ( TRIM(RECORD_curr, @FM, 'T') NE TRIM(RECORD_curr_init, @FM, 'T') ) THEN
        ERROR_message = 'Changes not saved - {1}>{2}'
        CHANGE '{1}' TO FILE_fname_list<FILE_no_curr> IN ERROR_message
        CHANGE '{2}' TO RECORD_id_curr IN ERROR_message
        EXIT_code = 16
        GOSUB doexit
    END

    CLEAR_mode = @FALSE

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    table_name = SCRIPT_line

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    RECORD_id_curr = SCRIPT_line

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
        GOSUB ygetdict   ;*  $DICT$, $LREF$ (25, 26) are set there

    END ELSE
        FILE_no_curr = posn
        MACRO_list(25) = DICT_list(FILE_no_curr)
        MACRO_list(26) = DICT_list_lref(FILE_no_curr)
        FIND 'RECORD.STATUS' IN DICT_list(FILE_no_curr) SETTING REC_STAT_posn ELSE REC_STAT_posn = 0
        FIND 'OVERRIDE' IN DICT_list(FILE_no_curr) SETTING OVERRIDE_posn ELSE OVERRIDE_posn = 0
        FIND 'LOCAL.REF' IN DICT_list(FILE_no_curr) SETTING LOCREF_posn ELSE LOCREF_posn = 0
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
            RECORD_curr<REC_STAT_posn + 6> = 1  ;* DEPT.CODE
        END
    END

    IF OVERRIDE_posn THEN RECORD_curr<OVERRIDE_posn> = ''  ;* we won't have OVERRIDEs on amended record in case of "clear" so comparison would fail to see non-changed record

    RECORD_curr_init = RECORD_curr   ;* for comparison before commit
    MACRO_list(10) = RECORD_curr   ;* can be addressed as $RECORD$

    IF RECORD_is_new THEN MACRO_list(27) = 1
    ELSE MACRO_list(27) = 0

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecrunofs:

    DEL_on_err = @FALSE
    FAIL_on_err = @FALSE

    LOOP
        cmds_qty ++
        GOSUB ygetnextline

        IF cmds_qty EQ 1 THEN GOSUB ycheckcmdsyntax
        ELSE
            IF is_EOF THEN BREAK
            IF NOT(FIRST_space) THEN
                GOSUB yrewind
                BREAK
            END
        END

        OFS_msg = SCRIPT_line

        GOSUB ylaunchofs
*        OFS_commit_ok, OFS_output:  '$OFSCOMMIT$' , '$OFSOUT$'

        ofs_func = FIELD(OFS_msg, '/', 2)
        IF INDEX('IADR', ofs_func, 1) AND NOT(OFS_commit_ok) THEN
            INFO_list<-1> = '[WARN] OFS error: ' : OFS_output
        END

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecselect:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax
    sel_list = SCRIPT_line

    sel_cmd = 'SELECT'

    LOOP
        GOSUB ygetnextline
        IF is_EOF THEN
            IF sel_cmd EQ 'SELECT' THEN
                ERROR_message = 'Command "{1}" at line {2} not finished properly'
                CHANGE '{1}' TO CMD_line IN ERROR_message
                CHANGE '{2}' TO CMD_line_no IN ERROR_message
                EXIT_code = 18
                GOSUB doexit
            END
            BREAK   ;* the very last command in the script - still we need to execute it to create saved list
        END
        IF NOT(FIRST_space) THEN
            GOSUB yrewind
            BREAK
        END

        sel_cmd := ' ' : SCRIPT_line
    REPEAT

    IF sel_cmd EQ 'SELECT' THEN
        ERROR_message = 'Command "{1}" at line {2} not finished properly'
        CHANGE '{1}' TO CMD_line IN ERROR_message
        CHANGE '{2}' TO CMD_line_no IN ERROR_message
        EXIT_code = 18
        GOSUB doexit
    END

    IF TAFJ_on THEN
        EXECUTE sel_cmd :@FM: 'SAVE-LIST ' : sel_list CAPTURING output RETURNING ret_code          ;* supporting the empty result
    END ELSE  ;*  241]1]sel_list]Savelist_msg after SPF., on empty/wrong file:  NODEFLIST]NODEFLIST (under tAFC but in TAFJ ret.code from 1st command)
        EXECUTE sel_cmd CAPTURING output RTNLIST ret_list RETURNING ret_code          ;* RTNLIST doesn't work in TAFJ
    END

    IF ret_code<1,1> EQ 404 OR (ret_code<1,1> EQ 401 AND ret_code<1,2> EQ 'QLNONSEL') THEN
        IF NOT(TAFJ_on) THEN WRITELIST ret_list TO sel_list
    END ELSE

        LBL_togo = ':sel_error_' : sel_list
        FIND LBL_togo IN LBL_list SETTING posn ELSE posn = 0
        IF posn GT 0 THEN
            INFO_list<-1> = '[WARN] SELECT error [' : sel_cmd : ']'
            GOSUB yjump
            RETURN
        END

        ERROR_message = 'SELECT error [' : sel_cmd : ']'
        EXIT_code = 41
        GOSUB doexit
    END

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecsleep:

    GOSUB ygetnextline
    GOSUB ycheckcmdsyntax

    SLEEP SCRIPT_line

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
xecupdate:

    IF RECORD_id_curr EQ '' THEN
        ERROR_message = 'No "read" command was executed yet'
        EXIT_code = 44
        GOSUB doexit
    END

    updt_qty = 0

    LOOP
        GOSUB ygetnextline

        IF is_EOF THEN
            ERROR_message = 'Command "{1}" at line {2} not finished properly'
            CHANGE '{1}' TO CMD_line IN ERROR_message
            CHANGE '{2}' TO CMD_line_no IN ERROR_message
            EXIT_code = 18
            GOSUB doexit
        END

        IF NOT(FIRST_space) THEN
            IF updt_qty EQ 0 THEN
                ERROR_message = 'No updates specified'
                EXIT_code = 34
                GOSUB doexit
            END ELSE
                GOSUB yrewind
                BREAK
            END
        END

        updt_line = SCRIPT_line
        FLD_name = FIELD(updt_line, ':', 1)
        vm_no = FIELD(updt_line, ':', 2)
        the_rest = FIELD(updt_line, ':', 3, 999999)
        sm_no = FIELD(the_rest, '=', 1)
        new_data = FIELD(the_rest, '=', 2, 999999)

        IF CLEAR_mode AND vm_no EQ 1 AND sm_no EQ 1 AND new_data EQ '' THEN
            updt_qty ++
            CONTINUE
        END

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

        IF FLD_name EQ '@RECORD' THEN
            RECORD_curr = new_data
            updt_qty ++
            CONTINUE
        END

        GOSUB yfindfield

        IF FLD_name EQ 'LOCAL.REF' AND NOT(ISDIGIT(vm_no) AND ISDIGIT(sm_no)) THEN
            ERROR_message = 'LOCAL.REF should have both @VM and @SM specified'
            EXIT_code = 24
            GOSUB doexit
        END

        BEGIN CASE

        CASE vm_no EQ '' AND sm_no EQ ''
            IF IS_lref THEN
                RECORD_curr<LOCREF_posn, LREF_posn> = new_data
            END ELSE RECORD_curr<FLD_posn> = new_data

        CASE (vm_no EQ '' OR vm_no EQ -1) AND sm_no NE ''
            ERROR_message = '@SM number requires @VM number to be set explicitly, for LOCAL.REF @SM set up in @VM place, e.g. MY.FIELD:2:=DATA'
            EXIT_code = 28
            GOSUB doexit

        CASE vm_no NE '' AND sm_no EQ ''
            IF IS_lref THEN RECORD_curr<LOCREF_posn, LREF_posn, vm_no> = new_data
            ELSE RECORD_curr<FLD_posn, vm_no> = new_data

        CASE vm_no NE '' AND sm_no NE ''
            IF IS_lref THEN
                ERROR_message = 'Subvalue for LOCAL.REF is set up in @VM place, e.g. MY.FIELD:2:=DATA'
                EXIT_code = 29
                GOSUB doexit
            END

            RECORD_curr<FLD_posn, vm_no, sm_no> = new_data

        CASE 1
            ERROR_message = 'Error parsing update command'
            EXIT_code = 30
            GOSUB doexit

        END CASE

        updt_qty ++

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------
*----------------------------------------------------------------------------------------------------------------------------------
yalertdup:

    IF DUP_file NE '' THEN
        IF f_DUP_file EQ '' THEN
            OPENSEQ DUP_dir, DUP_file TO f_DUP_file THEN
                WEOFSEQ f_DUP_file
            END ELSE
                CREATE f_DUP_file ELSE
                    f_DUP_file = ''  ;* otherwise "Invalid or uninitialised variable -- NULL USED , Var f_DUP_file , Line    50 , Source tafcj.b"
                    EXIT_code = 58
                    ERROR_message = 'Unable to create output file ' : DUP_dir : DIR_DELIM_CH : DUP_file  ;  GOSUB doexit
                END
            END
        END
        WRITESEQ ALERT_msg TO f_DUP_file ELSE
            EXIT_code = 61
            ERROR_message = 'Unable to write to output file'  ;  GOSUB doexit
        END
    END

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yaudtload:

    IF REC_STAT_posn THEN
        RECORD_curr<REC_STAT_posn> = AUDT_trail<1>
        RECORD_curr<REC_STAT_posn + 1> = AUDT_trail<2>
        RECORD_curr<REC_STAT_posn + 2> = AUDT_trail<3>
        RECORD_curr<REC_STAT_posn + 3> = AUDT_trail<4>
        RECORD_curr<REC_STAT_posn + 4> = AUDT_trail<5>
        RECORD_curr<REC_STAT_posn + 5> = AUDT_trail<6>
        RECORD_curr<REC_STAT_posn + 6> = AUDT_trail<7>
    END

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yaudtsave:

    IF REC_STAT_posn THEN AUDT_trail = FIELD(RECORD_curr, @FM, REC_STAT_posn, 7)
    ELSE AUDT_trail = ''

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
ygetdict:
* in: FILE_no_curr
* out: DICT_list(FILE_no_curr)
* out: DICT_list_lref(FILE_no_curr)
* out: REC_STAT_posn, OVERRIDE_posn, LOCREF_posn, $DICT$, $LREF$

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
    FIND 'OVERRIDE' IN dict_sel_list SETTING OVERRIDE_posn ELSE OVERRIDE_posn = 0

    DICT_list(FILE_no_curr) = dict_sel_list
    DICT_list_lref(FILE_no_curr) = dict_sel_list_lref

    MACRO_list(25) = dict_sel_list   ;* can be addressed as $DICT$
    MACRO_list(26) = dict_sel_list_lref   ;* can be addressed as $LREF$

    FIND 'LOCAL.REF' IN DICT_list(FILE_no_curr) SETTING LOCREF_posn ELSE LOCREF_posn = 0

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
ycheckcmdsyntax:
* check if command contains all mandatory data

    IF is_EOF OR NOT(FIRST_space) THEN
        ERROR_message = 'Command "{1}" at line {2} not finished properly'
        CHANGE '{1}' TO CMD_line IN ERROR_message
        CHANGE '{2}' TO CMD_line_no IN ERROR_message
        EXIT_code = 18
        GOSUB doexit
    END


    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yfindfield:
* in: FLD_name (name or number)
* out FLD_posn, IS_lref, LREF_posn

    IF RECORD_id_curr EQ '' THEN
        ERROR_message = 'No "read" command was executed yet'
        EXIT_code = 44
        GOSUB doexit
    END

    IF ISDIGIT(FLD_name) THEN
        FLD_posn = FLD_name
        FLD_name = DICT_list(FILE_no_curr)<FLD_name>
        IS_lref = @FALSE
        RETURN
    END

    FIND FLD_name IN DICT_list(FILE_no_curr) SETTING FLD_posn ELSE FLD_posn = 0

    IF FLD_posn GT 0 THEN
        IS_lref = @FALSE
    END ELSE
        FIND FLD_name IN DICT_list_lref(FILE_no_curr) SETTING LREF_posn ELSE LREF_posn = 0
        IF LREF_posn GT 0 THEN
            IF LOCREF_posn EQ 0 THEN
                ERROR_message = 'LOCAL.REF not found in DICT of ' : FILE_fname_list<FILE_no_curr>
                EXIT_code = 25
                GOSUB doexit
            END
            IS_lref = @TRUE

        END ELSE
            ERROR_message = 'Field {1} not found in {2}'
            CHANGE '{1}' TO FLD_name IN ERROR_message
            CHANGE '{2}' TO FILE_fname_list<FILE_no_curr> IN ERROR_message
            EXIT_code = 23
            GOSUB doexit
        END
    END

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yfostokdel:

    IF T24_userid NE '' THEN
        EXECUTE 'SELECT F.OS.TOKEN WITH USER.ID EQ ' : T24_userid CAPTURING dummy RTNLIST T24_user_tok
        IF T24_user_tok NE '' THEN
            EXECUTE 'DELETE F.OS.TOKEN ' : T24_user_tok CAPTURING dummy
        END
    END

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
ygetnextline:
* in: SCRIPT_data, SCRIPT_line_no
* out: next SCRIPT_line (all empty ones and comments excluded); is_EOF

    LOOP
        SCRIPT_line_no ++
        IF MOD(SCRIPT_line_no, 100000) EQ 0 THEN CRT '.'
        IF SCRIPT_line_no GT SCRIPT_size THEN
            is_EOF = @TRUE
            SCRIPT_line = ''
            RETURN
        END

        SCRIPT_line = SCRIPT_data<SCRIPT_line_no>
        first_char = SCRIPT_line[1, 1]

* comments can be everywhere
        IF first_char EQ '#' OR first_char EQ ':' THEN CONTINUE

        IF TRIM(SCRIPT_line, ' ', 'L') EQ '' THEN CONTINUE

        IF first_char EQ '=' THEN   ;* conditional TAFC/TAFJ processing
            BEGIN CASE
            CASE LEFT(SCRIPT_line, 6) EQ '=TAFC '
                IF TAFJ_on THEN CONTINUE
                ELSE SCRIPT_line = SCRIPT_line[6, 999999]

            CASE LEFT(SCRIPT_line, 6) EQ '=TAFJ '
                IF NOT(TAFJ_on) THEN CONTINUE
                ELSE SCRIPT_line = SCRIPT_line[6, 999999]

            CASE 1
                ERROR_message = 'Wrong syntax'
                EXIT_code = 54
                GOSUB doexit

            END CASE
            first_char = SCRIPT_line[1, 1]
        END

        BREAK

    REPEAT

    IF first_char EQ ' ' THEN FIRST_space = @TRUE
    ELSE FIRST_space = @FALSE
    SCRIPT_line = TRIM(SCRIPT_line, ' ', 'L')   ;* it's vital to do it before macros substitution - thus we'll keep leading $SPACE$'s

    IF CMD_line NE 'move' THEN
        macro_qty = INMAT(MACRO_list)
        FOR i = 1 TO macro_qty
            macro_spec = '$' : MACRO_name_list<i> : '$'
            macro_val = MACRO_list(i)
            IF INDEX(SCRIPT_line, macro_spec, 1) THEN CHANGE macro_spec TO macro_val IN SCRIPT_line
        NEXT i
    END

    RETURN

*-------------------------------------------------------------------------------------
yjump:
* in: LBL_togo
* out: SCRIPT_line_no

    FIND LBL_togo IN LBL_list SETTING posn ELSE posn = 0
    IF posn EQ 0 THEN
        ERROR_message = 'Label not found (' : LBL_togo : ')'
        EXIT_code = 20
        GOSUB doexit
    END

    SCRIPT_line_no = LBL_posn_list<posn>

    RETURN

*-------------------------------------------------------------------------------------
ylaunchofs:
* in: OFS_msg, FAIL_on_err, DEL_on_err
* out: OFS_commit_ok, OFS_output

    IF OFS_source_id EQ '-' THEN
        IF DEL_on_err THEN
            DELETE f_nau, RECORD_id_curr ON ERROR NULL
        END

        ERROR_message = 'OFS.SOURCE is mandatory for this operation'
        EXIT_code = 40
        GOSUB doexit
    END

    IF T24_login EQ '' THEN
        IF DEL_on_err THEN
            DELETE f_nau, RECORD_id_curr ON ERROR NULL
        END

        ERROR_message = 'T24 credentials are mandatory for this operation'
        EXIT_code = 9
        GOSUB doexit
    END

    IF TAFJ_on THEN GOSUB yfostokdel

    commit_successful = 0

    HUSH ON
    CALL OFS.BULK.MANAGER(OFS_msg, OFS_output, commit_successful)
    HUSH OFF

    OFS_commit_ok = commit_successful
    MACRO_list(23) = OFS_commit_ok
    MACRO_list(24) = OFS_output

    IF NOT(OFS_commit_ok) AND DEL_on_err THEN
        DELETE f_nau, RECORD_id_curr ON ERROR NULL
    END

    IF FAIL_on_err THEN
        IF NOT(OFS_commit_ok) THEN
            ERROR_message = 'OFS error'
            ERROR_message := ': ' : OFS_output

            EXIT_code = 39
            GOSUB doexit
        END
    END

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yloadcompany:
* in: COMPANY_curr

    CALL LOAD.COMPANY(COMPANY_curr)
    MACRO_list(1) = TODAY
    MACRO_list(2) = LCCY
    MACRO_list(3) = ID.COMPANY

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yprocalertmsg:

    CHANGE @FM TO ' (@FM) ' IN ALERT_msg
    CHANGE @VM TO ' (@VM) ' IN ALERT_msg
    CHANGE @SM TO ' (@SM) ' IN ALERT_msg
    CHANGE @TM TO ' (@TM) ' IN ALERT_msg

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
ysetmacro:
* in: MACRO_name, MACRO_value
* out: updated MACRO_list, [MACRO_name_list - if it's new]

    FIND MACRO_name IN MACRO_name_list SETTING posn ELSE posn = 0
    IF posn EQ 0 THEN
        posn = INMAT(MACRO_list)
        posn ++
        DIM MACRO_list(posn)
        MACRO_name_list<-1> = MACRO_name
    END ELSE
        IF NOT(ISDIGIT(MACRO_name)) AND UPCASE(MACRO_name) EQ MACRO_name THEN
            ERROR_message = 'System-level macro ({1}) can not be reassigned'
            CHANGE '{1}' TO MACRO_name IN ERROR_message
            EXIT_code = 48
            GOSUB doexit
        END
    END

    MACRO_list(posn) = MACRO_value

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yrewind:
* rewind script back in case when optional command component is missing
* one line only; we don't need to skip empty lines/comments/labels that might have been skipped on the way forward - not to parse them again

    SCRIPT_line_no --

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
yseqsemu:
* in: seqs_in
* out: seqs_out

    seqs_out = ''
    seqs_repl = CHAR(255) : '|' :@FM: '|' :@VM: '|' :@SM: '|' :@TM: '|' : CHAR(250)

    LOOP
        REMOVE seqs_char FROM seqs_in SETTING stat
        seqs_out := SEQ(seqs_char)

        IF stat EQ 0 THEN BREAK
        seqs_out := FIELD(seqs_repl, '|', stat)

    REPEAT

    RETURN

*----------------------------------------------------------------------------------------------------------------------------------
END
