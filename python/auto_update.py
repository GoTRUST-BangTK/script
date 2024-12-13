import time
import requests
import subprocess
import winreg
import config
import psutil
import shutil
import logger as setup_logger
import os
import config
import threading
import zipfile
import time
import run_exe

GIT_KIOSK_TAG_API = config.GIT_KIOSK_TAG_API
GIT_REPO_DIR = config.GIT_REPO_DIR
AUTO_UPGRADE_REGISTRY_PATH = config.AUTO_UPGRADE_REGISTRY_PATH
TIME_INTERVAL = config.TIME_INTERVAL
AUTO_UPDATE_LOG_FILE_PATH = config.AUTO_UPDATE_LOG_FILE_PATH 
TELEGRAM_API = config.TELEGRAM_API
GITHUB_TOKEN = config.GITHUB_TOKEN
last_checked_tag = None
SETUP_FOLDER_PATH = config.SETUP_FOLDER_PATH
AUTO_UPDATE_SERVICE_NAME = config.AUTO_UPDATE_SERVICE_NAME
AUTO_UPDATE_FILE = config.AUTO_UPDATE_FILE
medipay_updater_bin_path = config.MEDIPAY_UPDATER_FOLDER_PATH / "AutoUpgradeApp.exe"


logger = setup_logger.setup_logger(AUTO_UPDATE_LOG_FILE_PATH)


def run_command(command):
    """Run a shell command and log the output."""
    try:
        logger.info("Run in daemon mode")
        print("Run in daemon mode")
        subprocess.Popen(
            command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) 
    except Exception as e:
        logger.error(f"Failed to run command '{command}': {e}")
        print(f"Failed to run command '{command}': {e}")
        return 1

    
def get_registry_tag_value(key_name):
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, AUTO_UPGRADE_REGISTRY_PATH, 0, winreg.KEY_READ) as key:
            tag_value, reg_type = winreg.QueryValueEx(key, key_name)
            # print(f"Tag value found: {tag_value}")
            # logger.info(f"Tag value found: {tag_value}")
            return tag_value
    except FileNotFoundError:
        print(f"Registry path '{AUTO_UPGRADE_REGISTRY_PATH}' does not exist.")
        logger.error(f"Registry path '{AUTO_UPGRADE_REGISTRY_PATH}' does not exist.")
        return None
    except OSError as e:
        print(f"An error occurred while accessing the registry: {e}")
        logger.error(f"An error occurred while accessing the registry: {e}")
        return None


def create_or_update_registry_key(tag_value, key_name):
    try:
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, AUTO_UPGRADE_REGISTRY_PATH) as key:
            winreg.SetValueEx(key, key_name, 0, winreg.REG_SZ, tag_value)
            print("Create config success!")
            logger.info("Create config success!")
    except PermissionError:
        print("Permission denied. Run the script as Administrator.")
        logger.error("Permission denied. Run the script as Administrator.")
    except Exception as e:
        print(f"Create config ERROR! {e}")
        logger.error(f"Create config ERROR! {e}")


def pull_changes():
    try:
        print("Pulling latest changes...")
        logger.info("Pulling latest changes...")
        os.chdir(SETUP_FOLDER_PATH)
        subprocess.run(["git", "pull"], check=True)

        print("Successfully pulled the latest changes.")
        logger.info("Successfully pulled the latest changes.")
        
        
    except subprocess.CalledProcessError as e:
        print(f"Error while pulling changes: {e}")
        logger.error(f"Error while pulling changes: {e}")
 
def extract_zip():
    logger.info("Extracting ZIP files in the directory...")
    print("Extracting ZIP files in the directory...")
    file_path='MediPay_Updater.zip'
    extract_to_folder='MediPay_Updater'
    shutil.rmtree(extract_to_folder)
    try:
        with zipfile.ZipFile(file_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to_folder)
    except zipfile.BadZipFile:
        print(f"{file_path} is invalid.")
    except Exception as e:
        print(f"error: {e}")

def handle_changed_files():
    os.chdir(SETUP_FOLDER_PATH)
    result = subprocess.run(
        ['git', 'diff', '--name-only', 'HEAD~1', 'HEAD'],
        capture_output=True, text=True
    )
    changed_files = result.stdout.strip().split('\n')
    for file in changed_files:
        if file == AUTO_UPDATE_FILE:
            print(f"----> File: {AUTO_UPDATE_FILE} was changed")
            logger.info(f"----> File: {AUTO_UPDATE_FILE} was changed")
            kill_process(AUTO_UPDATE_SERVICE_NAME)
            time.sleep(5)
            extract_zip()
            threading.Thread(target=run_command, args=(str(medipay_updater_bin_path),)).start()
            # run_exe.create_task("StartAppTask", str(config.AUTO_UPGRADE_FILE_PATH))

        else:
            print(f"----> File: {file} has changed but no specific handler.")
            logger.info(f"----> File: {file} has changed but no specific handler.")

def send_log():
    files = {
        'chat_id': (None, '-4583989930'),
        'document': open(AUTO_UPDATE_LOG_FILE_PATH, 'rb'),
    }
    response = requests.post(TELEGRAM_API,
                             files=files,
                             )
    print("Send log to telegram: ", response.status_code, response.text)


def check_new_tag():
    try:
        headers = {"Authorization": f"Bearer {GITHUB_TOKEN}"}
        response = requests.get(GIT_KIOSK_TAG_API, headers=headers)
        response.raise_for_status()  # raise exception
        # print(response.json())
        latest_tag = response.json()[0]['name'] if len(response.json()) > 0 else None
        last_checked_tag = get_registry_tag_value('tag')

        # print(f"last_checked_tag: {last_checked_tag} ; latest_tag: {latest_tag}")
        # logger.info(f"last_checked_tag: {last_checked_tag} ; latest_tag: {latest_tag}")

        if latest_tag:
            if latest_tag != last_checked_tag:
                print(f"New tag found: {latest_tag}")
                logger.info(f"New tag found: {latest_tag}")
                # last_checked_tag = latest_tag
                pull_changes()
                handle_changed_files()
                create_or_update_registry_key(latest_tag, "tag")
                last_checked_tag = get_registry_tag_value('tag')
                print(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
                logger.info(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
            
                # send_log()
            elif latest_tag == None:
                print("No new tag found.")
                logger.info("No new tag found.")
                create_or_update_registry_key(latest_tag,"tag")
                print(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
                logger.info(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
        else:
            print("No tags found in the repository.")
            logger.warning("No tags found in the repository.")
    except requests.exceptions.RequestException as e:
        print(f"Error checking new tags: {e}")
        logger.error(f"Error checking new tags: {e}")


def execute():
    print("Start auto-checking for updates from the repo.")
    logger.info("Start auto-checking for updates from the repo.")
    last_checked_tag = get_registry_tag_value('tag')
    print(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
    logger.info(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
    while True:
        check_new_tag()
        time.sleep(TIME_INTERVAL)


def kill_process(process_name):
    for proc in psutil.process_iter(attrs=['pid', 'name']):
        if process_name in proc.info['name']:
            proc.kill()
            print(f"Process {process_name} is killed.")
            logger.info(f"Process {process_name} is killed.")
            return
    print(f"Process {process_name} not found.")
    logger.info(f"Process {process_name} not found.")
 

# execute() 