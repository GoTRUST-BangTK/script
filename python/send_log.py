import os
from datetime import datetime
import config
# import requests
import pysftp
import logger as setup_logger

# TELEGRAM_API_SEND_FILE = config.TELEGRAM_API_SEND_FILE
# TELEGRAM_CHAT_ID=config.TELEGRAM_CHAT_ID

API_LOG_FOLDER_PATH = r"d:\log"  # config.API_LOG_FOLDER_PATH
SFTP_HOST = config.SFTP_HOST
SFTP_PORT = config.SFTP_PORT
SFTP_USERNAME = config.SFTP_USERNAME
SFTP_PASSWORD = config.SFTP_PASSWORD
logger = setup_logger.setup_logger(r"c:\Task_send_log.log")

# def get_files_created_today(directory):
#     today = datetime.now().date()
#     file_list = []

#     for root, _, files in os.walk(directory):
#         for file in files:
#             file_path = os.path.join(root, file)
#             try:
#                 created_time = datetime.fromtimestamp(
#                     os.path.getctime(file_path)
#                 ).date()
#                 if created_time == today:
#                     file_list.append(file_path)
#             except OSError as e:
#                 print(f"can't get file info {file_path}: {e}")
#                 logger.info(f"can't get file info {file_path}: {e}")
#     return file_list


# def send_log(file_path):
#     files = {
#         "chat_id": (None, "-4583989930"),
#         "document": open(file_path, "rb"),
#     }
#     response = requests.post(
#         TELEGRAM_API_SEND_FILE,
#         files=files,
#     )
#     print("Send log to telegram: ", response.status_code, response.text)
#     logger.info("Send log to telegram: ", response.status_code, response.text)

# # # ? Loop through each file and print out the path
# # # ? Loop through each file and logger.info out the path
# # for file_path in get_files_created_today(API_LOG_FOLDER_PATH):
# #     print(file_path)
# #     logger.info(file_path)
# #     send_log(file_path)
 
def send_log_sftp():
    # check existence
    if not os.path.exists(API_LOG_FOLDER_PATH):
        print(f"Log folder {API_LOG_FOLDER_PATH} does not exist.")
        logger.info(f"Log folder {API_LOG_FOLDER_PATH} does not exist.")
        return

    # Create connection 
    cnopts = pysftp.CnOpts()
    cnopts.hostkeys = None

    try:
        with pysftp.Connection(host=SFTP_HOST, port=SFTP_PORT, username=SFTP_USERNAME, password=SFTP_PASSWORD, cnopts=cnopts) as sftp:
            print("Connected to SFTP server.")
            logger.info("Connected to SFTP server.")

            # create folder in SFTP server
            remote_log_folder = f"/Log/kioskId"
            if not sftp.exists(remote_log_folder):
                sftp.makedirs(remote_log_folder)
                print(f"Created remote directory: {remote_log_folder}")
                logger.info(f"Created remote directory: {remote_log_folder}")

            # Loop through each file in the local folder and send it to SFTP
            for filename in os.listdir(API_LOG_FOLDER_PATH):
                file_path = os.path.join(API_LOG_FOLDER_PATH, filename)
                remote_file_path = f"{remote_log_folder}/{filename}"

                if os.path.isfile(file_path):
                    try:
                        # check existence in server, if not, upload
                        if sftp.exists(remote_file_path):
                            print(f"File {filename} already exists on SFTP server, skipping upload.")
                            logger.info(f"File {filename} already exists on SFTP server, skipping upload.")
                        else:
                            # Upload file to SFTP server
                            sftp.put(file_path, remote_file_path)
                            print(f"Uploaded: {filename} to {remote_file_path}")
                            logger.info(f"Uploaded: {filename} to {remote_file_path}")
                    except Exception as e:
                        print(f"Failed to upload {filename}: {e}")
                        logger.error(f"Failed to upload {filename}: {e}")
    except Exception as e:
        print(f"Failed to connect to SFTP server: {e}")
        logger.error(f"Failed to connect to SFTP server: {e}")

send_log_sftp()