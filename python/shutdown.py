import os

def shutdown():
    print("Shut down instantly.")
    os.system("shutdown /s /t 1")
    
shutdown()