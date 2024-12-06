import win32com.client
from datetime import datetime, timedelta
import sys
import config

def create_task_scheduler(task_name, program_path, arguments):
    scheduler = win32com.client.Dispatch("Schedule.Service")
    scheduler.Connect()
    root_folder = scheduler.GetFolder("\\")

    # delete if it already exists
    try:
        root_folder.DeleteTask(task_name, 0)
        print(f"Deleted existing task '{task_name}'.")
    except Exception:
        pass

    # Create new task
    task_def = scheduler.NewTask(0) 
    task_def.RegistrationInfo.Description = "Task to run script daily at 2:00 PM and 6:00 PM"
    task_def.Principal.LogonType = 3  # Interactive logon

    # Trigger 1: at 2:00 PM 
    trigger1 = task_def.Triggers.Create(2)  #? 2: DailyTrigger
    trigger1.StartBoundary = datetime.combine(
        datetime.now().date(), datetime.min.time()
    ).replace(hour=10, minute=38).isoformat()
    trigger1.DaysInterval = 1

    # Trigger 2: at 6:00 PM
    trigger2 = task_def.Triggers.Create(2)  # DailyTrigger
    trigger2.StartBoundary = datetime.combine(
        datetime.now().date(), datetime.min.time()
    ).replace(hour=10, minute=39).isoformat()
    trigger2.DaysInterval = 1

    # Set Actions
    action = task_def.Actions.Create(0)  # ExecAction
    action.Path = program_path   
    action.Arguments = arguments  

    # Register task
    root_folder.RegisterTaskDefinition(
        task_name,
        task_def,
        6,  #? Replace task if it exists
        None,
        None,
        2, #? Logon as a batch job, this allows the task to run without user login & interaction
        None,
    )

    print(f"Task '{task_name}' created successfully.")


task_name = "SendLogTask"
# program_path = sys.executable
program_path = r"C:\Python312\python.exe"
arguments = config.SEND_LOG_FILE_PATH

create_task_scheduler(task_name, program_path, arguments)

#@ scheduler.NewTask
#? 0 = "Run Program"
#? 1 = "Send an Email"
#? 2 = "Display a Message"

#@ LogonType
#? 1: Requires user login to interact
#? 2: Runs in daemon mode without requiring user login
#? 3: Runs with interaction but can wait for user login
