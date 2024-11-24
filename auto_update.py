import time
import requests
import subprocess
import winreg
import config
import task_05.script.logger as setup_logger

GIT_KIOSK_TAG_API = config.GIT_KIOSK_TAG_API
GIT_REPO_DIR = config.GIT_REPO_DIR
REGISTRY_PATH = config.REGISTRY_PATH
TIME_INTERVAL = config.TIME_INTERVAL
LAST_CHECKED_TAG = None
AUTO_UPDATE_LOG_FILE_PATH = config.AUTO_UPDATE_LOG_FILE_PATH
TELEGRAM_API = config.TELEGRAM_API

logger = setup_logger.setup_logger(AUTO_UPDATE_LOG_FILE_PATH)


def get_registry_tag_value(key_name):
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, REGISTRY_PATH, 0, winreg.KEY_READ) as key:
            tag_value, reg_type = winreg.QueryValueEx(key, key_name)
            # print(f"Tag value found: {tag_value}")
            # logger.info(f"Tag value found: {tag_value}")
            return tag_value
    except FileNotFoundError:
        print(f"Registry path '{REGISTRY_PATH}' does not exist.")
        logger.error(f"Registry path '{REGISTRY_PATH}' does not exist.")
        return None
    except OSError as e:
        print(f"An error occurred while accessing the registry: {e}")
        logger.error(f"An error occurred while accessing the registry: {e}")
        return None


def create_or_update_registry_key(tag_value, key_name):
    try:
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, REGISTRY_PATH) as key:
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
        subprocess.run(["git", "pull"], check=True)
        print("Successfully pulled the latest changes.")
        logger.info("Successfully pulled the latest changes.")
    except subprocess.CalledProcessError as e:
        print(f"Error while pulling changes: {e}")
        logger.error(f"Error while pulling changes: {e}")


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
        response = requests.get(GIT_KIOSK_TAG_API)
        response.raise_for_status()  # raise exception
        latest_tag = response.json()[0]['name'] if len(
            response.json()) > 1 else None
        LAST_CHECKED_TAG = get_registry_tag_value('tag')
        # print(f"LAST_CHECKED_TAG: {LAST_CHECKED_TAG} ; latest_tag: {latest_tag}")
        # logger.info(f"LAST_CHECKED_TAG: {LAST_CHECKED_TAG} ; latest_tag: {latest_tag}")

        if latest_tag:
            if latest_tag != LAST_CHECKED_TAG:
                create_or_update_registry_key(latest_tag, "tag")
                print(f"New tag found: {latest_tag}")
                logger.info(f"New tag found: {latest_tag}")
                LAST_CHECKED_TAG = latest_tag
                pull_changes()
                print(f"================== Current tag: {
                      LAST_CHECKED_TAG} ================== \nWaiting for new tag to be pushed in repo")
                logger.info(f"================== Current tag: {
                    LAST_CHECKED_TAG} ================== \nWaiting for new tag to be pushed in repo")
            
                # send_log()

            elif latest_tag == None:
                print("No new tag found.")
                logger.info("No new tag found.")
                create_or_update_registry_key(latest_tag,"tag")
                print(f"================== Current tag: {
                      LAST_CHECKED_TAG} ================== \nWaiting for new tag to be pushed in repo")
                logger.info(f"================== Current tag: {
                    LAST_CHECKED_TAG} ================== \nWaiting for new tag to be pushed in repo")
        else:
            print("No tags found in the repository.")
            logger.warning("No tags found in the repository.")
    except requests.exceptions.RequestException as e:
        print(f"Error checking new tags: {e}")
        logger.error(f"Error checking new tags: {e}")


def execute():
    print("Start auto-checking for updates from the repo.")
    logger.info("Start auto-checking for updates from the repo.")
    print(f"================== Current tag: {
          LAST_CHECKED_TAG} ================== \nWaiting for new tag to be pushed in repo")
    logger.info(f"================== Current tag: {
        LAST_CHECKED_TAG} ================== \nWaiting for new tag to be pushed in repo")
    while True:
        check_new_tag()
        time.sleep(TIME_INTERVAL)


# execute()
