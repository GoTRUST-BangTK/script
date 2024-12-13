import win32com.client
import os
import sys

def create_task(task_name, exe_path):
    # Tạo đối tượng Task Scheduler
    scheduler = win32com.client.Dispatch("Schedule.Service")
    scheduler.Connect()

    # Lấy thư mục gốc của Task Scheduler
    root_folder = scheduler.GetFolder("\\")

    # Xóa Task cũ (nếu tồn tại)
    try:
        root_folder.DeleteTask(task_name, 0)
    except Exception as e:
        print(f"Task {task_name} không tồn tại, tiếp tục tạo mới.")

    # Tạo một task định nghĩa
    task_def = scheduler.NewTask(0)

    # Cấu hình Task (General Settings)
    task_def.RegistrationInfo.Description = "Task chạy app.exe từ service"
    task_def.Principal.UserId = os.getlogin()  # Sử dụng tài khoản người dùng hiện tại
    task_def.Principal.LogonType = 3  # Interactive Token (yêu cầu UI)

    # Cấu hình Trigger (chạy ngay lập tức)
    trigger = task_def.Triggers.Create(1)  # TASK_TRIGGER_TIME
    trigger.StartBoundary = "2024-12-13T00:00:00"  # Thời gian bất kỳ trong quá khứ (để chạy ngay)

    # Cấu hình Action (chạy app.exe)
    action = task_def.Actions.Create(0)  # TASK_ACTION_EXEC
    action.Path = sys.executable
    action.Arguments = exe_path

    # Đăng ký Task với Task Scheduler
    root_folder.RegisterTaskDefinition(
        task_name,
        task_def,
        6,  # TASK_CREATE_OR_UPDATE
        None,
        None,
        3,  # TASK_LOGON_INTERACTIVE_TOKEN
    )
    print(f"Task {task_name} đã được tạo và sẵn sàng chạy.")

    scheduler = win32com.client.Dispatch("Schedule.Service")
    scheduler.Connect()
    root_folder = scheduler.GetFolder("\\")
    task = root_folder.GetTask(task_name)
    task.Run(None)
    print(f"Task {task_name} đã được khởi chạy.")


