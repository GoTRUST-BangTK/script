#>     python python_service.py --startup=auto install

# import time
# import random
# from pathlib import Path
# import subprocess
from SMWinservice import SMWinservice
import win32service
import win32serviceutil
import sys
import auto_upgrade
import config

AUTO_UPDATE_SERVICE_NAME = config.AUTO_UPDATE_SERVICE_NAME

class PythonService(SMWinservice):
    _svc_name_ = AUTO_UPDATE_SERVICE_NAME
    _svc_display_name_ = "Auto Upgrade APP"
    _svc_description_ = "Auto Upgrade APP"

    def start(self):
        self.isrunning = True

    def stop(self):
        self.isrunning = False 
        auto_upgrade.kill_process("pythonservice") 

    def main(self):
        if self.isrunning:
            auto_upgrade.execute() 


if __name__ == '__main__':
    action = sys.argv[1] if len(sys.argv) > 1 else None
    PythonService.parse_command_line()