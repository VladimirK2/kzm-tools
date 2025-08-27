# TAFCJ script

By V.Kazimirchik.

## Preface

Data management tools used in T24 (e.g. Data Library, BCON) have a certain drawback: they replace a record fully - and this puts a severe limitation to team work with data. Example: 2 developers at the same time amend a HELPTEXT.MENU record....

TAFCJ script allows conditional update of data records. It's called "TAFCJ" because it works both in TAFC and TAFJ. Script interpreter is a jBC program.

## Is it safe assuming T24 transactions, concat files update etc?

Yes, it uses OFS to update a record (to be exact - OFS.BULK.MANAGER). Firstly the full record image is written to $NAU file with IHLD status; then OFS with "I" function and zero authorisation is performed (can be other update options - leave in INAU or IHLD, for example). (Note: if record in \$NAU file exists already, fatal error will be raised.)
In case of OFS error IHLD record is deleted.

## How to run

Minimum set of parameters:

- OFS.SOURCE ID. Should be the first.
- -s:script_name

E.g.:

    tafcj PW.MODEL -s:qwerty.tcj

This command will run a script qwerty.tcj in bnk.run. If a script from other folder is required, both forward and backward slashes can be used:

    tafcj PW.MODEL -s:..\qwerty.tcj
    tafcj PW.MODEL -s:../qwerty.tcj

"Minus" (-) can be used instead of OFS.SOURCE ID if there's no need to amend data (e.g.for reports).

If the script interpreter is run without parameters - the full list of them is being output. See chapter [parameters](#parameters).

## Script elements

### Comments

A line starting with '#' is a comment.

### Registers (or macros)

Enclosed into dollar symbols. Similar to variables but can be used anywhere (except commands and labels):

    move
        abc
        const
            Hello
    alert
        $abc$ World!
        $abc$$abc$$abc$
    # output:
    # Hello World!
    # HelloHelloHello

Uppercase macros can't be reassigned (useful for constants to avoid accidental change). There are also "system" (standard) macros that are assigned automatically: [Standard macros](#stdmacros).

Example:

    alert
        $TODAY$

See also: [move](#move), [alert](#alert)

### Labels

Labels start with a colon.

    # next line is a label
    :START

Labels are case-sensitive. They can be addressed via a macro (but can't contain a macro themselves):

    read
        F.SPF
        SYSTEM
    move
        t24rel
        field
            CURRENT.RELEASE
    jump
        :proc$t24rel$
    :procR19
    alert
        Older release
    jump
        :fini
    :procR23
    alert
        Newer release
    :fini

See also: [read](#read), [move](#move), [jump](#jump)

### Other notes

Empty lines are ignored.

Non-ASCII (or extended-ASCII) characters result in fatal error (ASCII 32 to 126 are allowed only). If non-allowed characters are necessary in the data or screen output, function CHAR(nnn) has to be applied.

### Commands

Commands are case-sensitive. Each command should occupy one line; command options follow on next line(s) with left offset at least 1 space or tab.

All examples contain the data from Temenos Model Bank R23 running on Windows Server 2019.

### Commands (alphabetical index)

[alert](#alert) | [clear](#clear) | [clone](#clone) | [commit](#commit) | [company](#company) | [debug](#debug)  | [default](#default) | [delete](#delete) | [exec](#exec)  | [exit](#exit) | [getlist](#getlist) | [getnext](#getnext) | [jump](#jump) | [move](#move) | [out](#out) / [outfile](#outfile) | [precision](#precision) | [read](#read) | [runofs](#runofs) | [select](#select) | [sleep](#sleep) | [update](#update)

### Commands (in the order that allows better learning process)

#### alert

Output a message to the screen. Message will appear immediately and also in the final report.

    alert
        All is done

*All alerts are repeated in "final report" (together with [INFO] prefix) in order not to be missed during execution - especially if there was output of T24 transaction processing that often resets the screen.*

Several alerts can be issued at once, e.g.:

    alert
        Working...
        All is done

jBASE delimiters are masked in alert output, e.g.: (@FM) etc.

#### exit

Finish the work. Return 0 by default or - if specified - a numeric error code. Error codes 1 - 999 are reserved for the script interpreter. Code 1000 can be used to suppress the output of the final report.

    # exit with the error.
    exit
        1001

The return code presents in the screen output:

    [ERROR] Non-zero exit code detected
    Exit code: 1001
    Script line: 3
    Elapsed time: 0.01 s.

Return codes provided by the interpreter: [Return codes](#retcodes).

#### exec

Proceed with jBC statement EXECUTE.

Create a table:

    exec
        CREATE-FILE F.TEST TYPE=MSSQL

Output:

    [INFO] Command at the line 2: return code ""
    [INFO] Finished successfully

Second run:

    [INFO] Command at the line 2: return code "413]There is already an object named 'D_F_TEST' in the database."
    [INFO] Finished successfully

*Successful finish happened because the option to check the return code wasn't activated (see below)*.

Copy a record:

    exec
        COPY FROM F.SPF TO F.TEST ALL

Output:

    [INFO] Command at the line 2: return code "805]1]COPY_DONE"
    [INFO] Finished successfully

Check return code, script will fail if it doesn't match:

    exec
        COPY FROM F.SPF TO F.TEST ALL
        805$VM$1$VM$COPY_DONE

Output:

    [ERROR] Command at the line 2: return code "805]0]COPY_DONE", expected : "805]1]COPY_DONE"
    Exit code: 56
    Script line: 3

Correct the copy command:

    exec
        COPY FROM F.SPF TO F.TEST ALL OVERWRITING
        805$VM$1$VM$COPY_DONE

Output:

    [INFO] Command at the line 2: return code "805]1]COPY_DONE" (as expected)
    [INFO] Finished successfully

System macros \$EXECSCREEN\$, \$EXECRETCODE\$, \$EXECRETDATA\$ and \$EXECRETLIST\$ are available after exec command:

    exec
        COPY FROM F.SPF TO F.TEST ALL OVERWRITING
    alert
        $EXECSCREEN$
        $EXECRETCODE$

Output:

    [INFO] Command at the line 2: return code "805]1]COPY_DONE"
    [INFO] 1 records copied
    [INFO] 805 (@VM) 1 (@VM) COPY_DONE

#### read

Read a record into record buffer. Examples:

    read
        F.SPF
        SYSTEM

    read
        F.COMPANY
        GB0010001

A non-existing record can be specified for further population and saving.

After read command system macros \$RECORD\$, \$DICT\$ and \$LREF\$ are available:

    read
        F.ABBREVIATION
        FT
    alert
        $RECORD$
        $DICT$
    read
        FBNK.AA.ARRANGEMENT.ACTIVITY
        DUMMY
    alert
        $LREF$

Output:

    [INFO] FUNDS.TRANSFER (@FM)  (@FM) 1 (@FM) 1_R14m (@FM) 2305230233 (@FM) 7_TRAIN511_OFS_MB.OFS (@FM) GB0010001 (@FM) 1
    [INFO] ORIGINAL.TEXT (@FM) RECORD.STATUS (@FM) CURR.NO (@FM) INPUTTER (@FM) DATE.TIME (@FM) AUTHORISER (@FM) CO.CODE (@FM) DEPT.CODE (@FM) AUDITOR.CODE ...
    [INFO] USRETL.ITEM.TYP (@FM) USRETL.ITEM.VAL (@FM) IS.CONTRACT.REF (@FM) IS.PRODUCT (@FM) IS.COM.SALE.REF (@FM) IS.DISBURSE.REF (@FM) REQUEST.CUST (@FM) HUWRNT.TXN.CODE

To see if a record is a new or existing one the system macro \$NEWRECORD\$ can be used:

    read
        F.HELPTEXT.MENU
        NEW
    jump
        :newrec$NEWRECORD$
    :newrec0
    alert
        Record exists
    exit
    :newrec1
    alert
        Record is new

#### update

Update a field in the record being read into buffer. Syntax is OFS-like.

    read
        F.ABBREVIATION
        QWERTY
    update
        ORIGINAL.TEXT::=TEST TWO

    # make field empty
    read
        F.USER
        VKAZIMIRCHIK
    update
        INIT.APPLICATION::=

    # assign MV field
    read
        FBNK.CUSTOMER
        100500
    update
        OTHER.OFFICER:1:=1
        OTHER.OFFICER:2:=100

    # add a new value to MV field
    read
        FBNK.CUSTOMER
        100100
    update
        OTHER.OFFICER:-1:=104

    # SV field
    read
        F.PRINTER.ID
        TEST
    update
        COMMAND:1:1=TEST1
        COMMAND:1:2=TEST2

    # add associated fields
    read
        F.HELPTEXT.MENU
        MY.MENU
    update
        APPLICATION:-1:1=SC.SETTLEMENT,ACT.SETT I E
        DESCRIPT:-1:1=Unauth Actual Settlement

    # address field by number
    read
        F.LOCKING
        FBNK.FOREX
    update
        2::=FX2000100002

    # update whole record
    read
        F.LOCKING
        FBNK.FOREX
    update
        @RECORD::=FX2332400001$FM$FX2000100001

##### Note

*Be careful in adding associations - all associated fields must be mentioned, even no-input and empty ones.*

#### commit

Commit changes to a record - data from buffer is posted to the database. As it was noted before, OFS is used to process the written IHLD record.

    # commit
    commit

    # use a specific VERSION
    commit
        ,AMEND

    # leave record in INAU
    commit
        INAU

    # leave record in IHLD status
    commit
        IHLD

    # raw commit, not recommended unless there's no other way
    commit
        RAW

##### Notes

*It's not possible to commit (all modes except "RAW") if a NAU record already exists - in order not to lose the last changes*.

*If the record wasn't changed, it will not be processed and a warning message will appear: "LIVE RECORD NOT CHANGED".*

*If the record was changed and no commit was done at the script end or before another "read", fatal error is triggered: "Changes not saved"*.

*If "committing" OFS fails, temporary IHLD record is deleted. Unfortunately, under TAFJ it doesn't happen because the whole session aborts.*

#### clear

Clear the whole record (keeping audit trail).

    read
        F.VERSION
        FUNDS.TRANSFER,TCIB
    clear
    update
        RECORDS.PER.PAGE::=1
        FIELDS.PER.LINE::=1
        NO.OF.AUTH::=2
    commit

#### clone

Clone another record into existing one (except audit trail).

    read
        F.OFS.SOURCE
        TEST
    clone
        F.OFS.SOURCE
        PW.MODEL
    update
        GENERIC.USER::=AUTHORISER
    commit

#### delete

Delete a record. Sometimes deleting of a record via OFS is impossible (usually due to core errors when it applies some checks not intended for D function). Use with care!

    delete
        FBNK.CUSTOMER$NAU
        100100

Output:

    [INFO] Record FBNK.CUSTOMER$NAU>100100 deleted

Or:

    [WARN] Record FBNK.CUSTOMER$NAU>100100 does not exist, unable to delete

##### Note

*Of course "exec" command could be used for it but there were certain problems with that approach under TAFJ.*

#### jump

Pass execution to a line after specified label.

    # do something 5 times
    move
        cntr
        const
            0
    :strt
    move
        cntr
        func
            ADDS($cntr$, 1)
        01
        func
            LE($cntr$, 5)
    jump
        :proc$01$
    :proc1
    alert
        $cntr$
    jump
        :strt
    :proc0
    # finish

See also: [move](#move).

#### select

Proceed with jQL SELECT.

    select
    # name of the resulting SELECT list
        LOCKING_SEL
    # SELECT statement
        F.LOCKING WITH @ID LIKE FBNK...
        SAMPLE 5
    getlist
        LOCKING_SEL
    :strt
    getnext
        LOCKING_SEL
        next_id
    alert
        $next_id$
    jump
        :strt
    # special label where we go when SELECT list is exhausted
    :no_more_LOCKING_SEL
    exit
        1000

Output:

    FBNK.ORDER.BY.CUST
    FBNK.FT.BULK.CREDIT.AC
    FBNK.DX.PRICE.INPUT
    FBNK.DX.REVALUE
    FBNK.DIARY

#### getlist

Get saved list. See [select](#select).

#### getnext

Get the next item in saved list. See [select](#select).

#### move

Assign a macro.

Keywords:

##### const

A constant:

    move
        zero
        const
            0
    # create a dynamic array
        array
        const
            A$FM$BB$VM$CCC$SM$$zero$
    alert
        $array$

Output:

    A (@FM) BB (@VM) CCC (@SM) 0

*Note: spaces in "const" instructions are preserved, e.g.:*

    move
        var
        const
            (A   B     C)
    alert
        var

Output:

   (A&nbsp;&nbsp;&nbsp;B&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C)

See also: [Standard macros](#stdmacros).

##### field

    read
        FBNK.CUSTOMER
        100100
    move
        tc
        field
            TOWN.COUNTRY
        mname
        field
            PRIVACY.STATUS
    alert
        $tc$, $mname$

Output:
    Seattle, OPT-IN

Core field can be addressed by its number:

    read
        FBNK.CUSTOMER
        100100
    move
        tc
        field
            7

##### func

A function. Supported functions list: ABS, ABSS, ADDS, ALPHA, ANDS, BYTELEN, CATS, CHANGE, CHANGETIMESTAMP, CHAR, CHARS, CONVERT, COUNT, COUNTS, DATE, DCOUNT, DIR, DIV, DIVS, DOWNCASE, DQUOTE, DROUND, DTX, EQS, EREPLACE, EXTRACT, FADD, FDIV, FIELD, FIELDS, FILEINFO (key = 1 only), FMT, FMTS, FMUL, FOLD, FSUB, GES, GETCWD, GETENV, ICONV, ICONVS, IFS, INDEX, INPUT, INT, ISALNUM, ISALPHA, ISCNTRL, ISDIGIT, ISLOWER, ISPRINT, ISSPACE, ISUPPER, LEFT, LEN, LENS, LES, LOCALDATE, LOCALTIME, LOWER, MAKETIMESTAMP, MATCHFIELD, MAXIMUM, MINIMUM, MOD, MODS, MULS, NEG, NEGS, NES, NOT, NOTS, NUM, NUMS, OCONV, OCONVS, ORS, PUTENV, PWR, RAISE, REGEXP, REPLACE, RIGHT, RND, SADD, SDIV, SENTENCE, SEQ, SEQS (emulation), SMUL, SORT, SPACE, SPACES, SPLICE, SQRT, SQUOTE, SSUB, STR, STRS, SUBS, SUBSTRINGS, SUM, SYSTEM, TIME, TIMEDATE, TIMEDIFF, TIMESTAMP, TRANS, TRIM, UNIQUEKEY, UPCASE, XTD.

Pseudo-functions EQ(), NE(), LT(), LE(), GT(), GE(), DEL(), INS(), FIND(), FINDSTR() and MATCHES() use corresponding operators and statements to proceed their "parameters".

Examples:

    read
        F.SPF
        SYSTEM
    move
        prods
        field
            PRODUCTS
        qty
        func
            DCOUNT($prods$, $VM$)
    alert
        $qty$

Output: 627.

Notes:

*Function parameters are to be specified without quotes, comma-delimited*.

*Only one set of parentheses can be used in function definition. If those are necessary in function parameters, system macros \$LPARENTH\$ amd \$RPARENTH\$ are to be used*.

*Commas in function parameters shall be represented as \$COMMA\$*.

*If space is a part of function parameter - system macro \$SPACE\$ is to be used to specify leading or trailing spaces. Spaces inside a parameter are preserved*.

    move
        output
        func
            MATCHES( FT220172HQJ4, 'F'1A5N5X )
    alert
        Result: $output$

Output:

    Result: 1

More examples:

    read
        FBNK.ACCOUNT
        DUMMY
    move
        finfo
        func
            FILEINFO()
        ftype
        func
            EXTRACT( $finfo$, 21 )
    alert
        $ftype$
    # output: XMLMSSQL

    move
        outp
        func
            CONVERT(CEYZ, +-*$COMMA$, ABCCCDEFCDYZ)
    alert
        $outp$
    # output: AB+++D-F+D*,

    move
        var
        func
            DQUOTE( A   B     C)
    alert
        $var$
    # output: "A   B     C"

    move
        var
        func
            DQUOTE( $SPACE$A B     C)
    alert
        $var$
    # output: " A B     C"

In this example conditional TAFC/TAFJ script lines are shown:

    move
        func_name
        const
        GETENV
    alert
        Testing $func_name$() ...
    move
        rezt
        func
    =TAFC    $func_name$( TAFC_HOME )
    =TAFJ    $func_name$( TAFJ_HOME )
    alert
        $rezt$

Output (TAFC):

    C:\temenos\TAFC\R23

Output (TAFJ):

    C:\temenos\TAFJ

*Pseudo-functions FIND() and FINDSTR() - if successful - return @FM-delimited dynamic array with @FM/@VM/@SM positions of found text or -1 if search was insuccessful:*

    read
        F.HELPTEXT.MENU
    =TAFC    AC.MENU
    =TAFJ    ACCOUNT.ENTRY
    move
        appl
        field
            APPLICATION
        tofind
        const
    =TAFC        ACCOUNT.STATEMENT
    =TAFJ        ENQ ACCT.STMT.HIST
        found
        func
            FIND( $tofind$, $appl$ )
    alert
        $found$
    move
        random
        func
            RND(100000)
        tofind
        const
            ACCOUNT, I F3 $random$
        found
        func
            FIND( $tofind$, $appl$ )
    alert
        $found$

Output:

    1 (@FM) 5 (@FM) 1
    -1

##### subr

Call a "EVAL" subroutine - one that can be used in jQL EVAL(). Example:

jBC subroutine:

    SUBROUTINE tafCJlocref(out_lref_list, in_app_name)
    *
        CALL EB.LOCREF.SETUP(in_app_name, out_lref_list)
    *
        RETURN
    END

Script:

    move
        lrefs
        subr
            tafCJlocref ACCOUNT
        fld1
        func
            EXTRACT($lrefs$, 1, 1)
        fld2
        func
            EXTRACT($lrefs$, 2, 1)
        fld3
        func
            EXTRACT($lrefs$, 3, 1)
        qty
        func
            DCOUNT($lrefs$, $FM$)
    alert
        $fld1$
        $fld2$
        $fld3$
        Local fields found: $qty$
    # output:
    # PLEDGE.PURPOSE
    # PLEDGE.FLAG
    # SOLD.DATE
    # Local fields found: 138

#### default

Default a macro passed via "-var:" parameter.

Script test.tcj:

    exec
        DOS /c C:\temenos\TAFJ\bin\trun.bat tafcj - -s:\temenos\TAFJ\UD\test2.tcj -var:folder:ETC.BP
    move
        out1
        func
            CHANGE( $EXECSCREEN$, $FM$, $LF$ )
    exec
        DOS /c C:\temenos\TAFJ\bin\trun.bat tafcj - -s:\temenos\TAFJ\UD\test2.tcj
    move
        out2
        func
            CHANGE( $EXECSCREEN$, $FM$, $LF$ )
    alert
        $out1$
        $out2$
    exit
        1000

Script test2.tcj:

    default
        folder
        const
            MISC.BP
    alert
        Will proceed $folder$
    exit
        1000

Output:

    Will proceed ETC.BP
    Will proceed MISC.BP

See chapter [parameters](#parameters).

#### runofs

Execute OFS message.

    move
        abbr_id
        const
            TEST.FTNAU
    runofs
        ABBREVIATION,/I/PROCESS//0,$USERNAME$/$PASSWORD$,$abbr_id$,ORIGINAL.TEXT::=FUNDS.TRANSFER? E
    alert
        $OFSCOMMIT$
        $OFSOUTPUT$

Result:

    1
    TEST.FTNAU/PWOFS233406951652333.01/1,ORIGINAL.TEXT:1:1=FUNDS.TRANSFER, E,CURR.NO:1:1=1,INPUTTER:1:1=69516_AUTHORISER__OFS_PW.MODEL,DATE.TIME:1:1=2312061432,
    AUTHORISER:1:1=69516_AUTHORISER_OFS_PW.MODEL,CO.CODE:1:1=GB0010001,DEPT.CODE:1:1=1

#### sleep

    move
        tdate
        func
            TIMEDATE()
    alert
        $tdate$
        Going to sleep 5 seconds
    sleep
        5
    move
        tdate
        func
            TIMEDATE()
    alert
        $tdate$

Output:

    20:06:51 06 DEC 2023
    Going to sleep 5 seconds
    20:06:56 06 DEC 2023

#### out

#### outfile

Output information to a text file.

    outfile
    # number of file
        1
    #folder
        TAFJAY.OUT
    # file
        tcjtest-1.txt
    # next file
        2
        TAFJAY.OUT
        tcjtest-2.txt
    move
        tdate_ini
        func
            TIMEDATE()
    sleep
        5
    move
        tdate
        func
            TIMEDATE()
    out
        1
        $tdate_ini$
    out
        2
        $tdate_ini$
        $tdate$

#### precision

Invoke PRECISION statement.

    precision
        13
    move
        rezt
        func
            DIVS(1, 3)
    alert
        $rezt$
    precision
        3
    move
        rezt
        func
            DIVS(1, 3)
    alert
        $rezt$

Output:

    0.3333333333333
    0.333

#### company

Change a current COMPANY. Necessary if a commit will be used. If not, data can be read without this command.

    company
        AU0010001
    read
        FAU1.INDUSTRY
        123
    move
        descr
        field
            DESCRIPTION
    move
        descr
        const
            $descr$!
    update
        DESCRIPTION::=$descr$
    commit

#### debug

Enter the TAFC/TAFJ debugger.

## parameters

    -------------------------------------------------------------
    <OFS.SOURCE ID>   | @ID of OFS.SOURCE to use
                      |   - this parameter is mandatory
                      |   - its type should be "TELNET"
                      |   - has to be the first one
                      | Can be replaced by - (if no commits used)
    -------------------------------------------------------------
    All following parameters can be specified in any order:
    -------------------------------------------------------------
    -s:<script>       | script to process (with path)
                      |   - this parameter is mandatory
                      |   - can be specified as:
                      |     path/file
                      |     path\file
    -------------------------------------------------------------
    The following parameters are not mandatory:
    -------------------------------------------------------------
    -l:<login>        | T24 login
    -------------------------------------------------------------
    -p:<password>     | T24 password
    -------------------------------------------------------------
    -var              | free-format parameter to supply a
                      | register value, e.g.:
                      | -var:date:20170630 (mask spaces with #20)
                      | -var:equ:A#3dB (mask "=" with #3d)
                      | -var:rec:SPF#3eSYSTEM (mask ">" with #3e)
    -------------------------------------------------------------
    -a:<file>         | duplicate all alerts to file
    -------------------------------------------------------------

## retcodes

Return codes supported by the interpreter:

- 0  success
- 1  unknown error
- 2  Parameters missing
- 3  Error opening OFS.SOURCE
- 4  OFS.SOURCE @ID not found
- 5  non-TELNET OFS.SOURCE
- 6  Unrecognized parameter
- 7  Script file not specified
- 8  Script file - open error
- 9  **RESERVE**
- 10 Script file - non-ASCII characters found
- 11 **RESERVE**
- 12 Error opening SPF
- 13 Error opening table on read/delete command
- 14 Error opening F.MNEMONIC.COMPANY
- 15 Error reading F.MNEMONIC.COMPANY
- 16 Changes not saved
- 17 Command not recognized
- 18 Command not finished properly
- 19 Duplicate label
- 20 Label not found
- 21 Non-numeric exit code
- 22 Non-zero exit codes less than 1000 are reserved for script interpreter
- 23 Field not found
- 24 LOCAL.REF should have both @VM and @SM specified
- 25 LOCAL.REF not found in DICT
- 26 @VM number is not numeric
- 27 @SM number is not numeric
- 28 @SM number requires @VM number to be set explicitly
- 29 Subvalue for LOCAL.REF is set up in @VM place
- 30 Error parsing update command
- 31 VERSION or commit mode expected
- 32 VERSION expected
- 33 Commit mode expected
- 34 No updates specified
- 35 Unable to open $NAU file
- 36 $NAU record exists, unable to continue
- 37 Unable to write to $NAU file
- 38 Unable to delete a record
- 39 OFS error
- 40 OFS.SOURCE is mandatory for this operation
- 41 SELECT error
- 42 SELECT list does not exist
- 43 Command "move": keyword is not supported
- 44 No "read" command was executed yet
- 45 One or both parentheses missing in function definition
- 46 Only one set of parentheses allowed function definition
- 47 Function not found in the list of functions with N parameter(s)
- 48 Uppercase macro can not be reassigned
- 49 Error opening F.USER.SIGN.ON.NAME
- 50 Not valid T24 login name
- 51 Unable to write to LIVE file
- 52 Cancelled by user
- 53 Forbidden to redefine internal registers
- 54 Wrong syntax
- 55 Non-numeric PRECISION detected
- 56 exec - return code not as expected
- 57 File already used for output
- 58 Unable to create file for output
- 59 Area number N already used for output
- 60 No file for area number N opened for output
- 61 Error writing to output file for area number N
- 62 Unable to clone from non-existing record

## stdmacros

- \$TODAY\$
- \$LCCY\$
- \$ID.COMPANY\$
- \$FM\$
- \$VM\$
- \$SM\$
- \$TM\$
- \$SPACE\$
- \$BLANK\$
- \$RECORD\$
- \$EXECSCREEN\$
- \$EXECRETCODE\$
- \$EXECRETDATA\$
- \$EXECRETLIST\$
- \$LF\$
- \$TAB\$
- \$DIR\_DELIM\_CH\$
- \$COMMA\$
- \$LPARENTH\$
- \$RPARENTH\$
- \$USERNAME\$
- \$PASSWORD\$
- \$OFSCOMMIT\$
- \$OFSOUTPUT\$
- \$DICT\$
- \$LREF\$
- \$NEWRECORD\$
