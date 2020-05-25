
import os     as os
import pandas as pd

from subprocess import Popen


class VensimFailed(Exception):
    pass


class Vensim:
    
    executable = None
    
    mdl_name = None
    lst_name = None
    cin_name = None
    vdf_name = None
    tsv_name = None
    cmd_name = None
    
    timestep = None
    
    def __init__(self, basename, timestep, mdl_name = None, executable = "vensimdp.exe"):
        self.executable = executable.split()
        self.timestep = timestep
        self.mdl_name = basename + ".mdl" if mdl_name is None else mdl_name
        self.lst_name = basename + ".lst"
        self.set_names(basename)
        
    def set_names(self, name):
        self.cin_name = name + ".cin"
        self.vdf_name = name + ".vdf"
        self.tsv_name = name + ".tsv"
        self.cmd_name = name + ".cmd"
        
    def make_cmd(self):
        with open(self.cmd_name, "w") as cmd_file:
            cmd_file.writelines([
                "SPECIAL>NOINTERACTION\r\n",
                "SPECIAL>LOADMODEL|" + self.mdl_name + "\r\n",
                "SPECIAL>CLEARRUNS\r\n",
                "SIMULATE>RUNNAME|"  + self.vdf_name + "\r\n",
                "SIMULATE>READCIN|"  + self.cin_name + "\r\n",
                "SIMULATE>SAVELIST|" + self.lst_name + "\r\n",
                "SETTING>SHOWWARNING|0\r\n",
                "MENU>RUN|o\r\n",
                "MENU>VDF2TAB|" + self.vdf_name + "|" + self.tsv_name + "|" + self.lst_name + "|*|" + str(self.timestep) + "|||\r\n",
                "MENU>EXIT\r\n",
            ])

    def make_lst(self, variables):
        with open(self.lst_name, "w") as lst_file:
            lst_file.writelines([
                variable + "\r\n"
                for variable in variables
            ])

    def make_cin(self, constants):
        with open(self.cin_name, "w") as cin_file:
            cin_file.writelines([
                variable + "=" + str(value) + "\r\n"
                for variable, value in constants.items()
            ])

    def read_tsv(self):
        return pd.read_csv(self.tsv_name, sep="\t")

    def delete_run(self, delete_lst):
        os.remove(self.cmd_name)
        os.remove(self.cin_name)
        os.remove(self.vdf_name)
        os.remove(self.tsv_name)
        if delete_lst:
          os.remove(self.lst_name)

    def run_vensim(self, timeout = 60, retry = True):
        with Popen(self.executable + [self.cmd_name]) as p:
            p.wait(timeout)
            if p.returncode != 0:
                if retry:
                    self.run_vensim(timeout, False)
                else:
                    raise VensimFailed()
