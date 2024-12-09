import os
from datetime import datetime
import config
import requests

API_LOG_FOLDER_PATH = r"d:\log"  # config.API_LOG_FOLDER_PATH
TELEGRAM_API = config.TELEGRAM_API


def get_files_created_today(directory):
    today = datetime.now().date()
    file_list = []

    for root, _, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                created_time = datetime.fromtimestamp(
                    os.path.getctime(file_path)
                ).date()
                if created_time == today:
                    file_list.append(file_path)
            except OSError as e:
                print(f"can't get file info {file_path}: {e}")
    return file_list


def send_log(file_path):
    files = {
        "chat_id": (None, "-4583989930"),
        "document": open(file_path, "rb"),
    }
    response = requests.post(
        TELEGRAM_API,
        files=files,
    )
    print("Send log to telegram: ", response.status_code, response.text)


# ? Loop through each file and print out the path
for file_path in get_files_created_today(API_LOG_FOLDER_PATH):
    print(file_path)
    send_log(file_path)
