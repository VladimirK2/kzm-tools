PROGRAM rec2tcj
*--------------------------------------------------------------
* By V.Kazimirchik, 2024-01-12 18:35
*---------------------------------------------------------------------------------------------------------------------

    $INSERT I_COMMON
    $INSERT I_EQUATE
    $INSERT I_F.LOCAL.TABLE
    $INSERT I_F.LOCAL.REF.TABLE

    INCLUDE JBC.h

    except_list = 'OVERRIDE' :@FM: 'RECORD.STATUS' :@FM: 'CURR.NO' :@FM: 'INPUTTER' :@FM: 'DATE.TIME' :@FM: 'AUTHORISER' :@FM: 'CO.CODE' :@FM: 'DEPT.CODE' :@FM: 'AUDITOR.CODE' :@FM: 'AUDIT.DATE.TIME'

    param_one = SENTENCE(1)

    IF param_one EQ '' THEN
        CRT SYSTEM(40) : ' v. 0.991'
        CRT 'Usage: ' : SYSTEM(40) : ' [-t:]TABLE [-r:]RECORD [options]'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT 'If table and record are defined with "-t:" and "-r:" prefixes respectively,'
        CRT 'they can be placed anywhere in the command line.'
        CRT 'RECORD can be set as * to grab the whole table'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT 'Options are either:'
        CRT '-x:FIELD1:FIELD2:etc   fields to exclude'
        CRT '-n         exclude noinput fields, default is to include all fields'
        CRT '-g         group associated fields (not compatible with "-n")'
        CRT '-r         use registers in MV/SV; "-g" assumed in this case (not compatible with "-n")'
        CRT '-c:        commit mode (INAU / IHLD / RAW)'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT '... or:'
        CRT '-raw       raw mode - can be used for L apps or data files without corresponding application or even DICT'
        CRT '---------------------------------------------------------------------------------------------------------'
        CRT '-l:list    process a saved list in format TABLE>REC'
        CRT '-o:file    output to &SAVEDLISTS&\file (if folder is not specified), output to screen if not specified'
        EXIT(1)
    END

    IF param_one[1, 1] EQ '-' THEN params_are_fixed = @FALSE
    ELSE params_are_fixed = @TRUE

    param_list = @FALSE  ;  excl_noinput = @FALSE  ;  write_to = ''   ;   group_assoc = @FALSE
    use_registers = @FALSE  ;  the_file = ''  ;  rec_id = ''  ;  j24_syntax = @FALSE  ;  t24_new_syntax = @FALSE  ;  commit_mode = ''  ;  raw_mode = @FALSE

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

*            CASE down_case_par EQ '-j'
*                j24_syntax = @TRUE

            CASE a_param EQ '-raw'
                raw_mode = @TRUE

*            CASE a_param EQ '-movE'
*                t24_new_syntax = @TRUE
*
            CASE down_case_par EQ '-l:'
                param_list = @TRUE
                the_list = FIELD(a_param, ':', 2, 99)

            CASE down_case_par EQ '-c:'
                commit_mode = FIELD(a_param, ':', 2, 99)

            CASE down_case_par[1, 2] EQ '-n'
                excl_noinput = @TRUE

            CASE down_case_par[1, 2] EQ '-g'
                group_assoc = @TRUE

            CASE down_case_par[1, 2] EQ '-r' AND a_param[3, 1] NE ':'
                use_registers = @TRUE

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
        EXIT(12)
    END

    IF NOT(param_list) AND rec_id EQ '' THEN
        CRT 'Record is not specified'
        EXIT(13)
    END

* ---------------------- TT-1657
    commit_mode_match = 'INAU' :@VM: 'IHLD' :@VM: 'RAW'

    IF commit_mode NE '' AND NOT(commit_mode MATCHES commit_mode_match) THEN
        CRT '-c: parameter can be ' : CHANGE(commit_mode_match, @VM, ' or ')
        EXIT(78)
    END

    IF group_assoc AND excl_noinput THEN
        CRT '-g and -n parameters are not compatible'
        EXIT(3)
    END

    IF use_registers AND excl_noinput THEN
        CRT '-r and -n parameters are not compatible'
        EXIT(4)
    END

    IF use_registers THEN group_assoc = @TRUE

*    excl_noinput = @FALSE  ;  group_assoc = @FALSE
*    use_registers = @FALSE    ;  j24_syntax = @FALSE  ;  t24_new_syntax = @FALSE  ;  commit_mode = ''

    IF raw_mode THEN
        IF excl_noinput OR group_assoc OR use_registers OR j24_syntax OR t24_new_syntax OR commit_mode NE '' THEN
            CRT '-raw parameter can be used only with -t:, -r:, -l: and -o:'
            EXIT(76)
        END
    END

* ----------------------

    the_output = '# start of script'

    IF rec_id EQ '*' OR param_list THEN

        IF param_list THEN
            GETLIST the_list TO proc_list ELSE
                CRT 'List not found (' : the_list : ')'
                EXIT(5)
            END
        END ELSE
            IF RUNNING.IN.TAFJ THEN
                CRT '"*" not yet supported under TAFJ'
                EXIT(16)
            END
            sel_cmd = 'SELECT {} SAVING EVAL "\{}>\:@ID"'
            CHANGE '{}' TO the_file IN sel_cmd
            EXECUTE sel_cmd CAPTURING out_put RTNLIST proc_list

        END

        rec_qty = DCOUNT(proc_list, @FM)
        IF NOT(raw_mode) AND rec_qty GT 100 THEN
            the_output<-1> = 'options records=' : rec_qty
            IF rec_id NE '*' THEN the_output<-1> = 'options tables=' : rec_qty
        END

        LOOP
            REMOVE rec_spec FROM proc_list SETTING the_stat_main
            the_file = FIELD(rec_spec, '>', 1)
            rec_id = FIELD(rec_spec, '>', 2)
            GOSUB ProcRec

            IF the_stat_main EQ 0 THEN BREAK
        REPEAT

    END ELSE
        GOSUB ProcRec
    END

    the_output<-1> = '# end of script'
    GOSUB PrintResults

    EXIT(0)

ProcRec:
* in: the_file, rec_id

    the_output<-1> = '# ' : the_file : '>' : rec_id

    OPEN the_file TO f_data ELSE CRT 'Data file open error (' : the_file : '), please supply prefix ("F." etc)'  ;  EXIT(6)

    READ the_rec FROM f_data, rec_id ELSE CRT 'Read error (' : the_file : '>' : rec_id  : ')'  ;  EXIT(7)
    CLOSE f_data

    IF raw_mode THEN
        the_rec_out = the_rec
        CHANGE @FM TO '$FM$' IN the_rec_out
        CHANGE @VM TO '$VM$' IN the_rec_out
        CHANGE @SM TO '$SM$' IN the_rec_out
        CHANGE @TM TO '$TM$' IN the_rec_out
        the_output<-1> = 'read'
        the_output<-1> = '    ' : the_file
        the_output<-1> = '    ' : rec_id
        the_output<-1> = 'update'
        the_output<-1> = '    @RECORD::=' : the_rec_out
        the_output<-1> = 'commit'
        the_output<-1> = '    RAW'

    END ELSE

        app_name = FIELD(FIELD(the_file, '.', 2, 99), '$', 1)

        V$FUNCTION = 'TEST'
* CALL @app_name    ;* 17:25:34 22 Nov 2016, Tue.: this won't work with new template ;

        rezt = CALLC JBASESubroutineExist(app_name, sub_info)
        IF RUNNING.IN.TAFJ THEN
            IF sub_info NE 'Subroutine' THEN
                CRT 'Application ' : app_name : ' does not exist'
                EXIT(75)
            END
        END ELSE
            IF rezt NE 1 THEN
                CRT 'Application ' : app_name : ' does not exist'
                EXIT(75)
            END
        END

        CALL EB.EXECUTE.APPLICATION(app_name)         ;* get arrays ;

* get associations

        MATBUILD f_array FROM F

*    CRT f_array
*    INPUT dummy
* TAFJ R22, COMPANY:
* Launching ['trun.bat', 'EW.REC.TO.SCRIPT', '-j', '-r', '-o:C:\\Temenos\\TAFJ\\UD\\TAFJAY.OUT\\script.j24', '-t:F.COUNTRY', '-r:LU'] ...
* \uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8fe\uf8feAUDIT.DATE.TIME

* TT-2192 there are spaces in some fields, e.g.:
*  FILE.CONTROL>FILE TYPE, DE.ADDRESS>COUNTRY CODE
*  -> they have to be changed to dots.
*  VERSION>AUTH.ROUTINE has a space at the end that has to be suppressed.

* 2023-07-25 08:46 TT-4642
        dict_sel_cmd = 'SELECT DICT {} WITH F1 EQ "D" SAVING EVAL "INT(F2):\*\:@ID:\*\"'
        CHANGE '{}' TO the_file IN dict_sel_cmd
        EXECUTE dict_sel_cmd CAPTURING out_put RTNLIST dict_list   ;*   e.g. 2*SHORT.NAME*^3*NAME.1*^5*STREET*^10*RELATION.CODE*^11*REL.CUSTOMER*^ ...

* ------

        assoc_list = ''  ;  assoc_cnt = 0  ;  fld_list = ''
        fld_qty = DCOUNT(f_array, @FM)

        FOR i_fld = 1 TO fld_qty

            fld_name = TRIM(f_array<i_fld>, ' ', 'B')

            IF fld_name EQ '' THEN
                CRT 'F array: field name #' : i_fld : ' is empty'  ;  EXIT(19)
            END

            CHANGE ' ' TO '.' IN fld_name
* TT-4642 DFP
            CHANGE '/' TO '.' IN fld_name
            CHANGE '"' TO '.' IN fld_name
            CHANGE '(' TO '.' IN fld_name
            CHANGE ')' TO '.' IN fld_name

            fld_prefix = fld_name[1,3]

            BEGIN CASE
                CASE fld_prefix EQ 'XX.'
                    assoc_cnt ++
                    assoc_list<assoc_cnt> = i_fld

                CASE fld_prefix EQ 'XX<'
                    assoc_cnt ++
                    assoc_list<assoc_cnt> = i_fld

                CASE fld_prefix EQ 'XX-'
                    assoc_list<assoc_cnt> := @VM : i_fld

                CASE fld_prefix EQ 'XX>'
                    assoc_list<assoc_cnt> := @VM : i_fld

                CASE 1
                    assoc_cnt ++
                    assoc_list<assoc_cnt> = i_fld

            END CASE

            LOOP
                IF fld_name[1,3] MATCHES 'XX.' :@VM: 'LL.' :@VM: 'XX<' :@VM: 'XX-' :@VM: 'XX>' THEN
                    fld_name = fld_name[4,99]
                END ELSE
                    fld_list<-1> = fld_name
                    BREAK
                END
            REPEAT

        NEXT i_fld

*DEBUG
* V dict_list
* V fld_list
* V assoc_list

* ------------------------------------

        OPEN 'F.LOCAL.REF.TABLE' TO f_lrt ELSE
            CRT 'Unable to open LOCAL.REF.TABLE'
            EXIT(14)
        END

        OPEN 'F.LOCAL.TABLE' TO f_lt ELSE
            CRT 'Unable to open LOCAL.TABLE'
            EXIT(15)
        END

        lrt_presents = @TRUE
        READ rec_lrt FROM f_lrt, app_name ELSE lrt_presents = @FALSE

        lref_list = ''
        IF lrt_presents THEN
            lrt_list = rec_lrt<EB.LRT.LOCAL.TABLE.NO>
            LOOP
                REMOVE lt_id FROM lrt_list SETTING status
                READ rec_lt FROM f_lt, lt_id ELSE CRT 'ERROR 1', lt_id  ;  EXIT(8)
                lref_list<-1> = rec_lt<LocalTable_ShortName>
                IF status EQ 0 THEN BREAK
            REPEAT
        END

* ------------------------------------

        the_output<-1> = 'read ' : app_name : '>' : FIELD(rec_id, ';', 1)
        the_output<-1> = 'clear @>@'

        rec_output = ''

        the_qty = DCOUNT(fld_list, @FM)
        FOR i_fld = 1 TO the_qty

            fld_name = fld_list<i_fld>
            FIND fld_name IN except_list SETTING to_skip ELSE to_skip = ''
            IF to_skip THEN CONTINUE

            IF excl_noinput AND fld_name NE 'LOCAL.REF' THEN
                fld_spec = T(i_fld)<3>
                IF fld_spec EQ 'NOINPUT' OR fld_spec[6] EQ 'EXTERN' THEN CONTINUE   ;* could be NV.EXTERN ;
            END

* 2023-07-25 09:03 TT-4642

            FINDSTR '*' : fld_name : '*' IN dict_list SETTING dict_posn ELSE
                CRT 'DICT - field not found: ' : DQUOTE(fld_name)
                EXIT(404)
            END
            phys_loc = FIELD(dict_list<dict_posn>, '*', 1)

            fld_cont = the_rec<phys_loc>

            mv_posn = 1  ;  sv_posn = 1
            LOOP
                REMOVE a_chunk FROM fld_cont SETTING mv_sv_stat

                FIND i_fld IN assoc_list SETTING fm_posn, vm_posn ELSE CRT 'Structure fatal error'  ;  EXIT(9)
                fld_idx = 'I' : FMT(fm_posn, 'R%5') : FMT(mv_posn, 'R%5') : FMT(vm_posn, 'R%5') : FMT(sv_posn, 'R%5')

                rec_output<-1> = fld_idx : fld_name : ':' : mv_posn : ':' : sv_posn : '=' : a_chunk

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

        IF group_assoc THEN GOSUB RecOutputSort
        ELSE
            lines_qty = DCOUNT(rec_output, @FM)

            rec_output_upd = ''
            FOR i_line = 1 TO lines_qty
                rec_output_upd<-1> = 'update @>@>' : rec_output<i_line>[22, 999]
            NEXT i_line
        END

        the_output<-1> = rec_output_upd
        the_output<-1> = TRIM('commit @>@ ' : commit_mode, ' ', 'T')
    END

    RETURN

* -----------------------------------------------------------------------------
RecOutputSort:
* in: rec_output
* out: rec_output_upd
* ---
* index:  'I' :
* # of assoc [nnnnn]
* MV # [nnnnn]
* # of field in assoc [nnnnn]
* SV # [nnnnn]

    rec_output = SORT(rec_output)
    lines_qty = DCOUNT(rec_output, @FM)

    rec_output_upd = ''

    lref_in_progress = @FALSE  ;  assoc_in_progress = @FALSE

    FOR i_line = 1 TO lines_qty
* use registers for MV/SV
        the_line = rec_output<i_line>
        the_idx = the_line[2,20]
        the_line = the_line[22,999]     ;*  VALUE:3:1=CardHolderFile_$proc_month$_$entity_code$.xml  ;

        hard_mv_no = FIELD(the_line, ':', 2)
        hard_sv_no = FIELD(FIELD(the_line, ':', 3), '=', 1)

        IF the_line[1,10] EQ 'LOCAL.REF:' THEN
            IF lrt_presents THEN
                IF NOT(lref_in_progress) THEN
                    rec_output_upd<-1> = '# ========== LOCAL.REF ============='
                    lref_in_progress = @TRUE
                END
                lref_name = lref_list<hard_mv_no>
                IF j24_syntax THEN
                    rec_output_upd<-1> = 'update @>@>LOCAL.REF:' : lref_name : ':' : hard_sv_no : '=' : FIELD(the_line, '=', 2, 9999)
                END ELSE
                    rec_output_upd<-1> = 'update @>@>' : lref_name : ':' : hard_sv_no : ':=' : FIELD(the_line, '=', 2, 9999)
                END
            END ELSE          ;* no LRT ;
                rec_output_upd<-1> = 'update @>@>' : the_line
            END
            CONTINUE
        END

        IF lref_in_progress THEN
            rec_output_upd<-1> = '# ========== end of LOCAL.REF ============='
            lref_in_progress = @FALSE
        END

        assoc_no = TRIM(the_idx[1,5], '0', 'L')
        fld_is_alone = ( COUNT(assoc_list<assoc_no>, @VM) EQ 0 )
        IF fld_is_alone OR NOT(use_registers) THEN

            IF assoc_in_progress THEN
                rec_output_upd<-1> = '# ===== Non-associated fields '
                assoc_in_progress = @FALSE
            END

            rec_output_upd<-1> = 'update @>@>' : the_line
            CONTINUE
        END

        assoc_in_progress = @TRUE

* mark the start of association

        IF the_idx[11,5] EQ '00001' THEN          ;*  first field in association  ;
            IF the_idx[6,5] EQ '00001' THEN       ;*  first MV  ;
                curr_mv_no = 0     ;    curr_sv_no = 1
                rec_output_upd<-1> = '# ===== Associated fields'
                IF j24_syntax OR t24_new_syntax THEN
                    rec_output_upd<-1> = 'movE vx,const 0'
                    rec_output_upd<-1> = 'movE sx,const 1'
                END ELSE
                    rec_output_upd<-1> = 'mov vx,0'
                    rec_output_upd<-1> = 'mov sx,1'
                END
                rec_output_upd<-1> = '# -----------------------'
            END ELSE
                IF curr_sv_no NE 1 THEN
                    curr_sv_no = 1
                    IF j24_syntax OR t24_new_syntax THEN rec_output_upd<-1> = 'movE sx,const 1'
                    ELSE rec_output_upd<-1> = 'mov sx,1'
                END
                rec_output_upd<-1> = '# -----------------------'
            END
        END

        LOOP
            IF curr_mv_no EQ hard_mv_no THEN BREAK
            curr_mv_no ++
            IF curr_mv_no GT 99999 THEN CRT 'Something went wrong (1)'  ;  EXIT(10)
            IF j24_syntax OR t24_new_syntax THEN rec_output_upd<-1> = 'movE vx,func ADDS($VX$, 1)'
            ELSE rec_output_upd<-1> = 'mov vx,$VX$+1'
        REPEAT

        IF curr_sv_no GT hard_sv_no THEN
            IF j24_syntax OR t24_new_syntax THEN rec_output_upd<-1> = 'movE sx,const 1'
            ELSE rec_output_upd<-1> = 'mov sx,1'
            curr_sv_no = 1
        END

        LOOP
            IF curr_sv_no EQ hard_sv_no THEN BREAK
            curr_sv_no ++
            IF curr_sv_no GT 99999 THEN CRT 'Something went wrong (2)'  ;  EXIT(11)
            IF j24_syntax OR t24_new_syntax THEN rec_output_upd<-1> = 'movE sx,func ADDS($SX$, 1)'
            ELSE rec_output_upd<-1> = 'mov sx,$SX$+1'
        REPEAT

        the_line = FIELD(the_line, ':', 1, 1) : ':$VX$:$SX$=' : FIELD(the_line, '=', 2, 9999)

        rec_output_upd<-1> = 'update @>@>' : the_line
    NEXT i_line

    IF lref_in_progress THEN rec_output_upd<-1> = '# ========== end of LOCAL.REF ============='

    RETURN

* -----------------------------------------------------------------------------
PrintResults:

    IF write_to EQ '' THEN
        CHANGE @FM TO CHAR(10) IN the_output
        CRT the_output
    END ELSE

        IF INDEX(write_to, DIR_DELIM_CH, 1) THEN  ;* for "file" in current folder use .\file
            CHANGE @FM TO CHAR(10) IN the_output
*            OSWRITE the_output TO write_to ON ERROR CRT 'Saving error'  ;  EXIT(1)   ;* not supported in TAFJ

            slash_qty = DCOUNT(write_to, DIR_DELIM_CH)

            write_to_dir = FIELD(write_to, DIR_DELIM_CH, 1, slash_qty - 1)
            write_to_file = FIELD(write_to, DIR_DELIM_CH, slash_qty)

            OPENSEQ write_to_dir, write_to_file TO f_out THEN
                WEOFSEQ f_out
            END ELSE
                CREATE f_out ELSE CRT 'Output file creation error'  ;  EXIT(17)
            END

            WRITESEQ the_output TO f_out ELSE CRT 'Output file write error'  ;  EXIT(18)
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
