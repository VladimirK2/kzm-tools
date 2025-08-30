PROGRAM rec2tcj
*--------------------------------------------------------------
* By V.Kazimirchik, started 2024-01-12 18:35
*---------------------------------------------------------------------------------------------------------------------

    $INSERT I_COMMON
    $INSERT I_EQUATE
    $INSERT I_F.LOCAL.TABLE
    $INSERT I_F.LOCAL.REF.TABLE

    INCLUDE JBC.h

    except_list = 'OVERRIDE' :@FM: 'RECORD.STATUS' :@FM: 'CURR.NO' :@FM: 'INPUTTER' :@FM: 'DATE.TIME' :@FM: 'AUTHORISER' :@FM: 'CO.CODE' :@FM: 'DEPT.CODE' :@FM: 'AUDITOR.CODE' :@FM: 'AUDIT.DATE.TIME'

    param_one = SENTENCE(1)

    CRT SYSTEM(40) : ' v. 0.998'
    IF param_one EQ '' THEN
        CRT 'Usage: ' : SYSTEM(40) : ' [-t:]TABLE [-r:]RECORD [options]'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT 'If table and record are defined with "-t:" and "-r:" prefixes respectively,'
        CRT 'they can be placed anywhere in the command line.'
        CRT 'RECORD can be set as ! to grab the whole table'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT 'Options are either:'
        CRT '-x:FIELD1:FIELD2:etc   fields to exclude'
        CRT '-c:        commit mode (INAU / IHLD / RAW)'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT '... or:'
        CRT '-raw       raw mode - can be used for L apps or data files without corresponding application or even DICT'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT '-l:list    process a saved list in format TABLE>REC'
        CRT '-o:file    output to &SAVEDLISTS&\file (or to other folder if specified), otherwise output to screen'
        EXIT(1)
    END

    IF GETENV('TAFJ_HOME', tafj_home) THEN TAFJ_on = @TRUE    ;* RUNNING.IN.TAFJ might be not yet set
    ELSE TAFJ_on = @FALSE

    IF param_one[1, 1] EQ '-' THEN params_are_fixed = @FALSE
    ELSE params_are_fixed = @TRUE

    param_list = @FALSE  ;  write_to = ''
    the_file = ''  ;  rec_id = ''  ;  commit_mode = ''  ;  raw_mode = @FALSE
    last_file = ''

    IF params_are_fixed THEN
        the_file = param_one
        rec_id = SENTENCE(2)      ;* only these 2 were fixed ;
        i_par = 2   ;* where to continue parsing of parameters  ;
    END ELSE
        i_par = 0
    END

    LOOP
        i_par ++
        a_param = SENTENCE(i_par)
        IF a_param EQ '' THEN BREAK

        down_case_par = DOWNCASE(a_param[1, 3])

        BEGIN CASE

            CASE NOT(params_are_fixed) AND down_case_par EQ '-t:'
                the_file = FIELD(a_param, ':', 2, 99)

            CASE NOT(params_are_fixed) AND down_case_par EQ '-r:'
                rec_id = FIELD(a_param, ':', 2, 99)

            CASE a_param EQ '-raw'
                raw_mode = @TRUE

            CASE down_case_par EQ '-l:'
                param_list = @TRUE
                the_list = FIELD(a_param, ':', 2, 99)

            CASE down_case_par EQ '-c:'
                commit_mode = FIELD(a_param, ':', 2, 99)

            CASE down_case_par EQ '-o:'
                write_to = FIELD(a_param, ':', 2, 99)

            CASE down_case_par EQ '-x:'
                param_except_list = a_param[4, 99999]
                CHANGE ':' TO @FM IN param_except_list
                except_list<-1> = param_except_list

            CASE 1
                CRT 'Unrecognized parameter (' : a_param : ')'
                EXIT(2)

        END CASE

    REPEAT

    IF NOT(param_list) AND the_file EQ '' THEN
        CRT 'Table is not specified'
        EXIT(3)
    END

    IF NOT(param_list) AND rec_id EQ '' THEN
        CRT 'Record is not specified'
        EXIT(4)
    END

* ---------------------- TT-1657
    commit_mode_match = 'INAU' :@VM: 'IHLD' :@VM: 'RAW'

    IF commit_mode NE '' AND NOT(commit_mode MATCHES commit_mode_match) THEN
        CRT '-c: parameter can be ' : CHANGE(commit_mode_match, @VM, ' or ')
        EXIT(5)
    END

    IF raw_mode THEN
        IF commit_mode NE '' THEN
            CRT '-raw parameter can be used only with -l: and -o:'
            EXIT(6)
        END
    END

* ----------------------

    the_output_HDR = '# start of script'
    ext_chars = ''
    the_output = ''

    IF rec_id EQ '!' OR param_list THEN

        IF param_list THEN
            GETLIST the_list TO proc_list SETTING num_sel ELSE
                CRT 'List not found (' : the_list : ')'
                EXIT(7)
            END
        END ELSE

            proc_list = ''     ;   num_sel = 0
            OPEN the_file TO f_data ELSE CRT 'Data file open error (' : the_file : '), please supply prefix ("F." etc)'  ;  EXIT(9)

            SELECT f_data TO sel_data
            LOOP
                WHILE READNEXT file_id FROM sel_data DO
                proc_list<-1> = the_file : '>' : file_id
                num_sel ++
            REPEAT

            CLOSE f_data
        END

*        rec_qty = DCOUNT(proc_list, @FM)
        CRT 'Records to proceed: ' : num_sel

        LOOP
            REMOVE rec_spec FROM proc_list SETTING the_stat_main
            the_file = FIELD(rec_spec, '>', 1)
            rec_id = FIELD(rec_spec, '>', 2, 999)
            GOSUB ProcRec

            IF the_stat_main EQ 0 THEN BREAK
        REPEAT

    END ELSE
        GOSUB ProcRec
    END

    the_output<-1> = '# end of script'
    the_output_HDR<-1> = '# ---------------------'
    the_output_HDR<-1> = the_output
    the_output = the_output_HDR

    GOSUB PrintResults

    EXIT(0)

ProcRec:
* in: the_file, rec_id

    same_file = @TRUE
    IF the_file NE last_file THEN
        same_file = @FALSE
        last_file = the_file
    END

    the_output<-1> = '# ' : the_file : '>' : rec_id

    IF NOT(same_file) THEN
        OPEN the_file TO f_data ELSE CRT 'Data file open error (' : the_file : '), please supply prefix ("F." etc)'  ;  EXIT(9)
    END

    READ the_rec FROM f_data, rec_id ELSE CRT 'Read error (' : the_file : '>' : rec_id  : ')'  ;  EXIT(10)

    IF raw_mode THEN
        the_rec_out = the_rec
        CHANGE @FM TO '$FM$' IN the_rec_out
        CHANGE @VM TO '$VM$' IN the_rec_out
        CHANGE @SM TO '$SM$' IN the_rec_out
        CHANGE @TM TO '$TM$' IN the_rec_out
        CHANGE CHAR(9) TO '$TAB$' IN the_rec_out

        FOR i_ch = 127 TO 250
            IF INDEX(the_rec_out, CHAR(i_ch), 1) THEN
                CHANGE CHAR(i_ch) TO '$CHAR_' : i_ch : '$' IN the_rec_out

                FIND i_ch IN ext_chars SETTING dummy ELSE
                    the_output_HDR<-1> = 'move'
                    the_output_HDR<-1> = '    CHAR_' : i_ch
                    the_output_HDR<-1> = '    func'
                    the_output_HDR<-1> = '        CHAR(' : i_ch : ')'
                    ext_chars<-1> = i_ch
                END
            END
        NEXT i_ch

        the_output<-1> = 'read'
        the_output<-1> = '    ' : the_file
        the_output<-1> = '    ' : rec_id
        the_output<-1> = 'update'
        the_output<-1> = '    @RECORD::=' : the_rec_out
        the_output<-1> = 'commit'
        the_output<-1> = '    RAW'

    END ELSE

        app_name = FIELD(FIELD(the_file, '.', 2, 99), '$', 1)

        rezt = CALLC JBASESubroutineExist(app_name, sub_info)
        IF TAFJ_on THEN
            IF sub_info NE 'Subroutine' THEN
                CRT 'Application ' : app_name : ' does not exist'
                EXIT(11)
            END
        END ELSE
            IF rezt NE 1 THEN
                CRT 'Application ' : app_name : ' does not exist'
                EXIT(12)
            END
        END

        IF NOT(same_file) THEN
            OPEN 'DICT', the_file TO f_dict ELSE
                CRT 'Application ' : app_name : ' does not have a DICT'
                EXIT(13)
            END
        END

        dict_list = ''
        SELECT f_dict TO sel_dict
        LOOP
            WHILE READNEXT dict_id FROM sel_dict DO
            READ r_dict FROM f_dict, dict_id ELSE CONTINUE

            IF r_dict<1> EQ 'D' THEN
                dict_num = r_dict<2>
                IF dict_num EQ '0' OR NOT(ISDIGIT(dict_num)) THEN CONTINUE
                dict_list<-1> = dict_num : '*' : dict_id : '*'
            END
        REPEAT

* ------------------------------------

        the_output<-1> = 'read'
        the_output<-1> = '    ' : FIELD(the_file, '$', 1)
        the_output<-1> = '    ' : FIELD(rec_id, ';', 1)
        the_output<-1> = 'clear'

        rec_output = ''

        CHANGE CHAR(9) TO '$TAB$' IN the_rec

        the_qty = DCOUNT(dict_list, @FM)
        FOR i_fld = 1 TO the_qty
            fld_name = FIELD(dict_list<i_fld>, '*', 2)
            FIND fld_name IN except_list SETTING to_skip ELSE to_skip = ''
            IF to_skip THEN CONTINUE

            fld_posn = FIELD(dict_list<i_fld>, '*', 1)

            IF fld_name[1, 2] EQ 'K.' THEN
                to_find = fld_posn : '*' : fld_name[3, 99] : '*'
                FIND to_find IN dict_list SETTING it_is_k_dot ELSE it_is_k_dot = 0
                IF it_is_k_dot THEN CONTINUE
            END

            fld_cont = the_rec<fld_posn>

            FOR i_ch = 127 TO 251
                IF INDEX(fld_cont, CHAR(i_ch), 1) THEN
                    CHANGE CHAR(i_ch) TO '$CHAR_' : i_ch : '$' IN fld_cont

                    FIND i_ch IN ext_chars SETTING dummy ELSE
                        the_output_HDR<-1> = 'move'
                        the_output_HDR<-1> = '    CHAR_' : i_ch
                        the_output_HDR<-1> = '    func'
                        the_output_HDR<-1> = '        CHAR(' : i_ch : ')'
                        ext_chars<-1> = i_ch
                    END
                END
            NEXT i_ch

            mv_posn = 1  ;  sv_posn = 1
            LOOP
                REMOVE a_chunk FROM fld_cont SETTING mv_sv_stat

* Keep trailing spaces - script interpreter would TRIM them
                a_chunk_trimmed = TRIM(a_chunk, ' ', 'T')
                trail_sp_qty = LEN(a_chunk) - LEN(a_chunk_trimmed)
                FOR i_space = 1 TO trail_sp_qty
                    a_chunk_trimmed := '$SPACE$'
                NEXT i_space

                rec_output<-1> = fld_name : ':' : mv_posn : ':' : sv_posn : '=' : a_chunk_trimmed

                BEGIN CASE
                CASE mv_sv_stat EQ 0
                    BREAK
                CASE mv_sv_stat EQ 3
                    mv_posn ++
                    sv_posn = 1
                CASE mv_sv_stat EQ 4
                    sv_posn ++

                END CASE
            REPEAT

        NEXT i_fld

        lines_qty = DCOUNT(rec_output, @FM)

        rec_output_upd = ''
        rec_output_upd<-1> = 'update'
        FOR i_line = 1 TO lines_qty
            rec_output_upd<-1> = '    ' : rec_output<i_line>
        NEXT i_line

        the_output<-1> = rec_output_upd
        the_output<-1> = 'commit'
        the_output<-1> = TRIM('    ' : commit_mode, ' ', 'T')
    END

    RETURN

* -----------------------------------------------------------------------------
PrintResults:

    IF write_to EQ '' THEN
        CHANGE @FM TO CHAR(10) IN the_output
        CRT the_output
    END ELSE

        CHANGE '/' TO DIR_DELIM_CH IN write_to
        CHANGE '\' TO DIR_DELIM_CH IN write_to

        IF INDEX(write_to, DIR_DELIM_CH, 1) THEN  ;* for "file" in current folder use .\file
            CHANGE @FM TO CHAR(10) IN the_output

            slash_qty = DCOUNT(write_to, DIR_DELIM_CH)

            write_to_dir = FIELD(write_to, DIR_DELIM_CH, 1, slash_qty - 1)
            write_to_file = FIELD(write_to, DIR_DELIM_CH, slash_qty)

            OPENSEQ write_to_dir, write_to_file TO f_out THEN
                WEOFSEQ f_out
            END ELSE
                CREATE f_out ELSE CRT 'Output file creation error'  ;  EXIT(14)
            END

            WRITESEQ the_output TO f_out ELSE CRT 'Output file write error'  ;  EXIT(15)
            CLOSESEQ f_out

            CRT write_to : ' written'

        END ELSE
            WRITELIST the_output TO write_to
            CRT '&SAVEDLISTS&>' : write_to : ' written'
        END
    END

    RETURN
*-------------------------------------------------------
END
