import subprocess
# import logger as setup_logger
# import config
import threading


# AUTO_UPDATE_LOG_FILE_PATH = config.AUTO_UPDATE_LOG_FILE_PATH 
# logger = setup_logger.setup_logger(AUTO_UPDATE_LOG_FILE_PATH)
medipay_updater_bin_path = r"C:\kiosk\MediPay_App\MediPay_App\AutoUpgradeApp.exe"

def run_command(command):
    """Run a shell command and log the output."""
    try:
        # logger.info(f"Run in daemon mode: {medipay_updater_bin_path}")
        print("Run in daemon mode")
        subprocess.Popen(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) 
    except Exception as e:
        # logger.error(f"Failed to run command '{command}': {e}")
        print(f"Failed to run command '{command}': {e}")
        return 1

threading.Thread(target=run_command, args=(str(medipay_updater_bin_path),)).start()
