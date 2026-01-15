import os
import sys
import configparser
import subprocess

IN_SPLIT = '|'
OUT_SPLIT = '|'
KZM_HOME = os.environ['kzmhome']

def run_cmd(cmd_list):
    p = subprocess.Popen(cmd_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    std_out, std_err = p.communicate()
    retc = p.returncode
    return retc, std_out, std_err

def home_or_office():
    retc, std_out, std_err = run_cmd(['wmic', 'desktopmonitor', 'get', 'ScreenWidth'])
    rezt = std_out.count(b'\n1920')
    if rezt == 3:
        to_ret = 2   # office
    elif rezt == 4:
        to_ret = 1   # home
    else:
        sys.exit()
#    to_ret = 1
    return to_ret

def get_setup(key_id):

    config = configparser.ConfigParser()
    config.read(sys.path[-1] + os.sep + 'kzm.ini')
    spl = key_id.split(IN_SPLIT)
    out = config[spl[0]][spl[1]].replace('$KZM_HOME', KZM_HOME)
    if OUT_SPLIT in out:
        to_ret = out.split(OUT_SPLIT)
    else:
        to_ret = out
    return to_ret


if __name__ == '__main__':
    print('This is a library')

