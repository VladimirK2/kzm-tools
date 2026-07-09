PROGRAM tex

* e.g. trun tex TSA.SERVICE, I TSM 6 STA

    DATA 'user'
    DATA 'passwd'

    cmd_line = SYSTEM(1000)
    CHANGE ' ' TO @FM IN cmd_line
    DEL cmd_line<1>

    IF cmd_line NE '' THEN 
        CHANGE @FM TO ' ' IN cmd_line
        DATA cmd_line
    END

    EXECUTE 'EX'

STOP
END
