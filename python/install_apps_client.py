import os
import shutil
import subprocess
import re
import glob
import threading
import win32com.client
import zipfile
import sys
import requests
import logger as setup_logger
import psutil
import config
import download_driver
from pathlib import Path
import winreg

KIOSK_REPO_URL = config.KIOSK_REPO_URL
SETUP_FOLDER_PATH = config.SETUP_FOLDER_PATH
INSTALL_APP_LOG_FILE_PATH = config.INSTALL_APP_LOG_FILE_PATH 

KIOSK_FOLDER_PATH = config.KIOSK_FOLDER_PATH
API_FOLDER_PATH = config.API_FOLDER_PATH
MEDIPAY_FOLDER_PATH = config.MEDIPAY_FOLDER_PATH
MEDIPAY_REGISTRY_PATH = config.MEDIPAY_REGISTRY_PATH

API_LOCAL_FOLDER_PATH = config.API_LOCAL_FOLDER_PATH
MEDIPAYAPP_FOLDER_PATH = config.MEDIPAYAPP_FOLDER_PATH
CCCD_SETUP_FOLDER_PATH = config.CCCD_SETUP_FOLDER_PATH
CCCD_SETUP_FOLDER_NAME = config.CCCD_SETUP_FOLDER_NAME
# CCCD_FOLDER_PATH = config.CCCD_FOLDER_PATH
REDIST_SETUP_PATH = config.REDIST_SETUP_PATH
PRINTER_FOLDER_PATH = config.PRINTER_FOLDER_PATH
REGEDIT_FILE_PATH = config.REGEDIT_FILE_PATH
MEDIPAY_UPDATER_FOLDER_PATH = config.MEDIPAY_UPDATER_FOLDER_PATH
HN212_PLUGIN_FOLDER_PATH = config.HN212_PLUGIN_FOLDER_PATH
HN212_PLUGIN_CONFIG_PATH = config.HN212_PLUGIN_CONFIG_PATH

paths = [API_LOCAL_FOLDER_PATH, MEDIPAYAPP_FOLDER_PATH, CCCD_SETUP_FOLDER_PATH,
         REDIST_SETUP_PATH, PRINTER_FOLDER_PATH, REGEDIT_FILE_PATH]
file_exe_pattern = r".*\.exe$"

logger = setup_logger.setup_logger(INSTALL_APP_LOG_FILE_PATH)


def run_command(command, daemon=False, return_output=False):
    """Run a shell command and log the output."""
    try:
        if daemon:
            logger.info("Run in daemon mode")
            print("Run in daemon mode")
            result = subprocess.Popen(
                command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) 
        else:
            result = subprocess.run(
                command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
            if return_output:
                return result.stdout.strip()
            else:
                logger.info(result.stdout.strip())
                print(result.stdout.strip())

            if result.returncode != 0:
                logger.error(f"Error: {result.stderr.strip()}")
                print(f"Error: {result.stderr.strip()}")
            return result.returncode
    except Exception as e:
        logger.info(f"Failed to run command '{command}': {e}")
        print(f"Failed to run command '{command}': {e}")
        return 1


def check_files_in_folder(folder_path, filenames):
    result = {}
    for filename in filenames:
        file_path = os.path.join(folder_path, filename)
        result[filename] = os.path.isfile(file_path)  # Check if it's a file
    return result


def kill_process(process_name):
    for proc in psutil.process_iter(attrs=['pid', 'name']):
        if process_name in proc.info['name']:
            proc.kill()
            print(f"Process {process_name} is killed.")
            return
    print(f"Process {process_name} not found.")


logger.info("=============== Kill Auto Update App =================")
print("=============== Kill Auto Update App =================")
kill_process("AutoUpgradeApp")


def fetch_repo(KIOSK_REPO_URL, SETUP_FOLDER_PATH):
    logger.info(f"Cloning repository from {
                KIOSK_REPO_URL} into {SETUP_FOLDER_PATH}...")
    print(f"Cloning repository from {
          KIOSK_REPO_URL} into {SETUP_FOLDER_PATH}...")
    if os.path.exists(SETUP_FOLDER_PATH):
        os.chdir(SETUP_FOLDER_PATH)
        logger.info(f"Current working directory: {os.getcwd()}")
        print(f"Current working directory: {os.getcwd()}")
        output = run_command("git pull", return_output=True)
        if "Already up to date." == output:
            logger.info("Repository is already up to date. Exiting script.")
            print("Repository is already up to date. Exiting script.")
    else:
        run_command(f"git clone {KIOSK_REPO_URL} {SETUP_FOLDER_PATH}")

def extract_zip():
    logger.info("Extracting ZIP files in the directory...")
    print("Extracting ZIP files in the directory...")
    for root, _, files in os.walk(SETUP_FOLDER_PATH):
        for file in files:
            if file.endswith(".zip"):
                zip_path = os.path.join(root, file)
                extract_to = os.path.join(root, os.path.splitext(file)[0])
                os.makedirs(extract_to, exist_ok=True)
                try:
                    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                        zip_ref.extractall(extract_to)
                        logger.info(f"Extracted: {zip_path} -> {extract_to}")
                        print(f"Extracted: {zip_path} -> {extract_to}")
                except zipfile.BadZipFile:
                    logger.info(f"Error: {zip_path} is not a valid ZIP file.")
                    print(f"Error: {zip_path} is not a valid ZIP file.")
    logger.info("Done.")
    print("Done.")


fetch_repo(KIOSK_REPO_URL, SETUP_FOLDER_PATH)
logger.info(f"Downloading API_HN212 from Google Driver...")
print(f"Downloading API_HN212 from Google Driver...")
download_driver.download_file('API_HN212.zip',SETUP_FOLDER_PATH)
extract_zip()
# threading.Thread(target=download_driver.download_file, args=(
#     CCCD_SETUP_FOLDER_NAME, SETUP_FOLDER_PATH)).start()

def find_file(parent_path="C:/Setup/Support Exe", pattern="*"):
    for file in glob.glob(os.path.join(parent_path, '*')):
        if re.search(pattern, os.path.basename(file)):
            file = os.path.normpath(file)
            return file

medipay_bin_path = find_file(MEDIPAY_FOLDER_PATH, file_exe_pattern)
api_bin_path = find_file(API_FOLDER_PATH, file_exe_pattern)
# cccd_bin_path = find_file(CCCD_FOLDER_PATH, file_exe_pattern) #? skip
medipay_updater_bin_path = find_file(MEDIPAY_UPDATER_FOLDER_PATH, file_exe_pattern)

logger.info("=============== Check path is existing =================")
print("=============== Check path is existing =================")
for path in paths:
    logger.info(f"Path '{path}' {
                '--- EXISTS' if os.path.exists(path) else '--- DOES NOT EXIST'}.")
    print(f"Path '{path}' {'--- EXISTS' if os.path.exists(path)
          else '--- DOES NOT EXIST'}.")

logger.info(
    "=============== Create folders 'KIOSKService', 'API', and 'MediPay' =================")
print("=============== Create folders 'KIOSKService', 'API', and 'MediPay' =================")
KIOSK_FOLDER_PATH.mkdir(parents=True, exist_ok=True)
API_FOLDER_PATH.mkdir(exist_ok=True)
MEDIPAY_FOLDER_PATH.mkdir(exist_ok=True)

logger.info(
    "=============== copy API files to the 'API' folder. =================")
print("=============== copy API files to the 'API' folder. =================")
api_source_folder = SETUP_FOLDER_PATH / API_LOCAL_FOLDER_PATH
shutil.copytree(api_source_folder, API_FOLDER_PATH, dirs_exist_ok=True)

logger.info(
    "=============== copy MediPay App files to the 'MediPay' folder. =================")
print("=============== copy MediPay App files to the 'MediPay' folder. =================")
medipay_source_folder = SETUP_FOLDER_PATH / MEDIPAYAPP_FOLDER_PATH
shutil.copytree(medipay_source_folder, MEDIPAY_FOLDER_PATH, dirs_exist_ok=True)


# cccd_setup_bin_path = find_file(CCCD_SETUP_FOLDER_PATH, file_exe_pattern)
# logger.info(f"\n=============== Install CCCD Reader App: {
#             cccd_setup_bin_path} =================")
# print(f"\n=============== Install CCCD Reader App: {
#       cccd_setup_bin_path} =================")
# # threading.Thread(target=run_command  , args=(str(cccd_setup_bin_path),)).start() #>
# run_command(str(cccd_setup_bin_path))


logger.info(
    f"=============== copy HN212 log config to the {HN212_PLUGIN_FOLDER_PATH} folder. =================")
print(
    f"=============== copy HN212 log config to the {HN212_PLUGIN_FOLDER_PATH} folder. =================")
if not os.path.exists(HN212_PLUGIN_FOLDER_PATH):
    print(f"File '{HN212_PLUGIN_FOLDER_PATH}' is not existing.")
    os.makedirs(HN212_PLUGIN_FOLDER_PATH)
else:
    shutil.copy(HN212_PLUGIN_CONFIG_PATH, HN212_PLUGIN_FOLDER_PATH)


redist_setup_bin_path = find_file(REDIST_SETUP_PATH, file_exe_pattern)
logger.info(f"\n=============== Install VC_redist: {redist_setup_bin_path} =================")
print(f"\n=============== Install VC_redist: {redist_setup_bin_path} =================")
# threading.Thread(target=run_command  , args=(str(redist_setup_bin_path),)).start() #>
run_command(str(redist_setup_bin_path))

logger.info(f"\n=============== Install medipay updater: {MEDIPAY_UPDATER_FOLDER_PATH} =================")
print(f"\n=============== Install medipay updater: {MEDIPAY_UPDATER_FOLDER_PATH} =================")
threading.Thread(target=run_command, args=(str(medipay_updater_bin_path), True,)).start()  #>
# run_command(str(medipay_updater_bin_path))

# logger.info(
#     "=============== Check if printer w80 is already installed or not =================")
# print("=============== Check if printer w80 is already installed or not =================")
# printer_name = "w80"
# printers = subprocess.run(
#     ["wmic", "printer", "get", "name"], capture_output=True, text=True)
# if printer_name not in printers.stdout:
#     logger.info(" Printer w80 is not installed yet. Installing...")
#     print(" Printer w80 is not installed yet. Installing...")
#     run_command([str(PRINTER_FOLDER_PATH / "Uninstaller.exe")])  # >
#     run_command([str(PRINTER_FOLDER_PATH / "PrinterInstall.exe")])  # >
# else:
#     logger.info("Printer w80 is already installed. ")
#     print("Printer w80 is already installed. ")


def check_registry_key_exists(path):
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, path) as key:
            return True
    except FileNotFoundError:
        return False

def set_registry_keys():
    logger.info("================= Config KioskId. =================")
    print("================= Config KioskId. =================")
    with open(REGEDIT_FILE_PATH) as file:
        kioskId_command = file.read()
        # print(kioskId_command)
    try:
        result = subprocess.run(["powershell", "-Command", kioskId_command],
                                capture_output=True, text=True, check=True)  # >
        print(result.stdout)
        logger.info(result.stdout)
    except subprocess.CalledProcessError as e:
        print("Error:", e.stderr)
        logger.error("Error:", e.stderr)

def check_and_set_registry_keys():
    registry_hive = winreg.HKEY_LOCAL_MACHINE
    try:
        with winreg.OpenKey(registry_hive, MEDIPAY_REGISTRY_PATH, 0, winreg.KEY_READ) as key:
            kiosk_id = winreg.QueryValueEx(key, "KioskId")[0]
            secret_key = winreg.QueryValueEx(key, "SecretKey")[0]
            print(f"KioskId: {kiosk_id}")
            print(f"SecretKey: {secret_key}")
            print("Both 'KioskId' and 'SecretKey' already exist. No changes made.")
            if not kiosk_id or not secret_key:
                logger.info("One or both registry keys exist but have no value.")
                print("KioskId or SecretKey exists but has no value. Please reconfigure.")
                set_registry_keys()
            else:
                change_keys = input("Do you want to change the values of KioskId and SecretKey? (y/n): ").strip().lower()
                if change_keys == 'y':
                    set_registry_keys()
                else:
                    print("No changes made.")
    except FileNotFoundError:
        set_registry_keys()

check_and_set_registry_keys()

# ? Enable auto-start for MediPay, HN212 and API
startup_folder = Path(os.getenv("APPDATA")) / \
    "Microsoft/Windows/Start Menu/Programs/Startup"

def create_shortcut(target, shortcut_name):
    shell = win32com.client.Dispatch("WScript.Shell")
    shortcut = shell.CreateShortcut(
        str(startup_folder / f"{shortcut_name}.lnk"))
    shortcut.TargetPath = str(target)
    shortcut.save()


logger.info("================= Config auto-start ================= ")
print("================= Config auto-start ================= ")
# if not  os.path.isfile(medipay_bin_path):
#     print(f"Target path does not exist: {medipay_bin_path}")
# if not os.path.isfile(medipay_bin_path):
#     print(f"Target path does not exist: {api_bin_path}")
create_shortcut(config.MEDIPAY_EXE, "MediPay")
create_shortcut(config.API_EXE, "API")
# create_shortcut(cccd_bin_path, "HN212")
# create_shortcut(medipay_updater_bin_path, "Auto_Updater")

filenames = ["MediPay.lnk", "API.lnk"]
# filenames = ["MediPay.lnk", "API.lnk", "HN212.lnk", "Auto_Updater.lnk"]
check_result = check_files_in_folder(startup_folder, filenames)

for filename, exists in check_result.items():
    if exists:
        logger.info(f"Create {filename} shortcut successfully.")
        print(f"Create {filename} shortcut successfully.")
    else:
        logger.info(f"Creating {filename} shortcut failed.")
        print(f"Create {filename} shortcut failed.")
 