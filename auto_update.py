import time
import requests
import subprocess 
import winreg

# GITEA_API_URL = "http://gitea.local/api/v1/repos/kimbang/script/tags"
GITEA_API_URL = "https://github.com/GoTRUST-BangTK/script.git"
GITEA_REPO_DIR = "script"   
time_interval=5
registry_path = r"SOFTWARE\AutoUpgrade"
last_checked_tag = None

def get_registry_tag_value(key_name):
    try:
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, registry_path, 0, winreg.KEY_READ) as key:
            tag_value, reg_type = winreg.QueryValueEx(key, key_name)
            # print(f"Tag value found: {tag_value}")
            return tag_value
    except FileNotFoundError:
        print(f"Registry path '{registry_path}' does not exist.")
        return None
    except OSError as e:
        print(f"An error occurred while accessing the registry: {e}")
        return None
    
def create_or_update_registry_key(tag_value,key_name):
    try:
        with winreg.CreateKey(winreg.HKEY_LOCAL_MACHINE, registry_path) as key:
            winreg.SetValueEx(key, key_name, 0, winreg.REG_SZ, tag_value)
            print("Create config success!")
    except PermissionError:
        print("Permission denied. Run the script as Administrator.")
    except Exception as e:
        print(f"Create config ERROR! {e}")

def check_new_tag(): 
    try:
        response = requests.get(GITEA_API_URL)
        response.raise_for_status()  # raise exception
        latest_tag = response.json()[0]['name']
        last_checked_tag=get_registry_tag_value('tag')
        # print(f"last_checked_tag: {last_checked_tag} ; latest_tag: {latest_tag}")

        if latest_tag:
            if latest_tag != last_checked_tag:
                create_or_update_registry_key(latest_tag, "tag")
                print(f"New tag found: {latest_tag}")
                last_checked_tag = latest_tag  
                pull_changes()
                print(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
            elif latest_tag == None :
                print("No new tag found.")
                create_or_update_registry_key(latest_tag) 
                print(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
        else:
            print("No tags found in the repository.")
    except requests.exceptions.RequestException as e:
        print(f"Error checking new tags: {e}")

def pull_changes():
    try:
        print("Pulling latest changes...")
        subprocess.run(["git", "pull"], check=True)
        print("Successfully pulled the latest changes.")
    except subprocess.CalledProcessError as e:
        print(f"Error while pulling changes: {e}")

def main():
    print("Start auto-checking for updates from the repo.")
    print(f"================== Current tag: {last_checked_tag} ================== \nWaiting for new tag to be pushed in repo")
    while True:
        check_new_tag() 
        time.sleep(time_interval)

if __name__ == "__main__":
    main()
