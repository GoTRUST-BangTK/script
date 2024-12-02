import config
import os
medipay_updater_bin_path = config.MEDIPAY_UPDATER_FOLDER_PATH / "AutoUpgradeApp.exe"


print (medipay_updater_bin_path   if os.path.exists(medipay_updater_bin_path) else "")