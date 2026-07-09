PROGRAM TEXR11

* e.g. tex TSA.SERVICE, I TSM 6 STA

    EXECUTE 'EBS.TERMINAL.SELECT EBS-JBASE'

    DATA '123'
    DATA '456'
    DATA 'Y'
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
