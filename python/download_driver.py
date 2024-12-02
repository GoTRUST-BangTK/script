from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload
import io
import os
import config
import json
import logger as setup_logger

GOOGLE_SERVICE_ACCOUNT_FILE = config.GOOGLE_SERVICE_ACCOUNT_FILE 
GOOGLE_SCOPES = config.GOOGLE_SCOPES
SETUP_FOLDER_PATH = config.SETUP_FOLDER_PATH
# INSTALL_APP_LOG_FILE_PATH = '.log'
INSTALL_APP_LOG_FILE_PATH = config.INSTALL_APP_LOG_FILE_PATH

logger = setup_logger.setup_logger(INSTALL_APP_LOG_FILE_PATH)

with open(GOOGLE_SERVICE_ACCOUNT_FILE, 'r', encoding='utf-8-sig') as json_file:
    json_data = json.load(json_file)
creds = Credentials.from_service_account_info(json_data, scopes=GOOGLE_SCOPES)
# creds = Credentials.from_service_account_file(
#     GOOGLE_SERVICE_ACCOUNT_FILE, scopes=GOOGLE_SCOPES)
# print(creds)
service = build('drive', 'v3', credentials=creds)


def list_files():
    try:
        results = service.files().list(
            pageSize=10, fields="nextPageToken, files(id, name)").execute()
        items = results.get('files', [])

        if not items:
            print('No files found.')
            logger.info('No files found.')
        else:
            print('Files:')
            logger.info('Files:')
            for item in items:
                print(f"ID: ({item['id']}) --- Name: {item['name']}")
                logger.info(f"ID: ({item['id']}) --- Name: {item['name']}")
    except Exception as e:
        print(f"An error occurred: {e}")
        logger.info(f"An error occurred: {e}")


def download_file(file_name, folder_path='d:/'):
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)
    file_path = os.path.join(folder_path, file_name)

    #? find find by name
    results = service.files().list(
        q=f"name='{file_name}'", spaces='drive').execute()
    files = results.get('files', [])

    if not files:
        print(f"File with name '{file_name}' not found.")
        logger.info(f"File with name '{file_name}' not found.")
        return

    file_id = files[0]['id']
    file_name = files[0]['name']

    request = service.files().get_media(fileId=file_id)

    fh = io.FileIO(file_path, 'wb')
    downloader = MediaIoBaseDownload(fh, request)

    done = False
    while done is False:
        status, done = downloader.next_chunk()
        print(f"Download {int(status.progress() * 100)}%.")
        logger.info(f"Download {int(status.progress() * 100)}%.")
    print(f"File '{file_name}' downloaded successfully to {folder_path}")
    logger.info(f"File '{file_name}' downloaded successfully to {folder_path}")


# if __name__ == '__main__':
#     list_files()
# download_file('App_HN212.zip',SETUP_FOLDER_PATH)
