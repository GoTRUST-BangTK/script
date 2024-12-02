 # $($args[0])"
 
$packages = @("python", "gnupg", "git")

$repo_url = "https://github.com/GoTRUST-BangTK/script.git"
$setup_path = 'script'
$private_key_path = 'secret\private_key.asc'
$python_requirement_path = 'requirements.txt'
# $HOME = 'C:\Windows\System32'
# $python = '.\python312\Python312\python.exe'
# $gpg = '.\gpg\gnupg\bin\gpg.exe'
# $git = '\git\Git\bin\git.exe'

$WindowsUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
$AutoUpdatePath    = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$LogFilePath = "c:\install_tools.log"

#> Run-CommandWithLogging -Command "Get-Process" -LogFilePath "process_log.txt"
function Run-CommandWithLogging {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    try {
        #? Tee-Object: Prints stdout to the console and writes it to a file simultaneously.
        Invoke-Expression $Command 2>&1 | Tee-Object -FilePath $LogFilePath -Append
    } catch {
        Write-Output "Error occurred: $_" | Tee-Object -FilePath $LogFilePath -Append
    }
}
Run-CommandWithLogging -Command "w32tm /resync" -LogFilePath "script_log.txt"

Write-Host "Check if the kiosk is already set up."
if (Test-Path "HKLM:\SOFTWARE\MediPay") {
    $kioskId = Get-ItemProperty -Path "HKLM:\SOFTWARE\MediPay" -Name "KioskId" -ErrorAction SilentlyContinue
    $secretKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\MediPay" -Name "SecretKey" -ErrorAction SilentlyContinue

    if ($kioskId.KioskId -and $secretKey.SecretKey) {
        Write-Host "This machine is already configured." -ForegroundColor Green
        $userInput = Read-Host "Do you want to continue? (y/n)" 
        if ($userInput -eq 'n') {
            Write-Host "Exiting script..."
            exit
        } elseif ($userInput -eq 'y') {
            Write-Host "Continuing with the script..."
        } else {
            Write-Host "Invalid input. Please enter 'y' or 'n'."
            exit
        }
    } else {
        Write-Host "Configuration is incomplete.."
    }
} else {
    Write-Host "This machine is not setup yet."
}

# Tạo registry nếu chưa tồn tại
if (-not (Test-Path -Path "HKLM:SOFTWARE\AutoUpgrade")) {
    Write-Host "Create HKLM:SOFTWARE\AutoUpgrade Registry"
    Run-CommandWithLogging -Command "New-Item -Path 'HKLM:SOFTWARE\AutoUpgrade' -Force" -LogFilePath "script_log.txt"
}

# Cài đặt Chocolatey
function Install-Choco { 
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Chocolatey is already installed." -ForegroundColor Green
    } else { 
        Write-Host "Chocolatey is not installed. Installing now..." -ForegroundColor Yellow
        if (Test-Path -Path "C:\ProgramData\chocolatey") {
            Run-CommandWithLogging -Command "Remove-Item -Recurse -Force 'C:\ProgramData\chocolatey'" -LogFilePath "script_log.txt"
        }
        Run-CommandWithLogging -Command "Set-ExecutionPolicy Bypass -Scope Process -Force" -LogFilePath "script_log.txt"
        Run-CommandWithLogging -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072" -LogFilePath "script_log.txt"
        Run-CommandWithLogging -Command "Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -LogFilePath "script_log.txt"
        Run-CommandWithLogging -Command "choco upgrade chocolatey --version=1.4.0 -y --force" -LogFilePath "script_log.txt"
    }
}

# Hàm cài đặt các gói bằng Chocolatey
function Install-ChocoPackages {
    foreach ($package in $packages) {
        Run-CommandWithLogging -Command "choco install $package -y" -LogFilePath "choco_packages_log.txt"
    }

    Write-Output "Refresh environment"
    Run-CommandWithLogging -Command "Import-Module C:\ProgramData\Chocolatey\helpers\chocolateyProfile.psm1; Update-SessionEnvironment" -LogFilePath "choco_packages_log.txt"

    if (Get-Command pip -ErrorAction SilentlyContinue) {
        Write-Host "pip is already installed."
    } else {
        Write-Host "pip is not installed. Installing now..."
        Install-Choco
        Run-CommandWithLogging -Command "Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile get-pip.py" -LogFilePath "choco_packages_log.txt"
        Run-CommandWithLogging -Command "python get-pip.py" -LogFilePath "choco_packages_log.txt"
        Run-CommandWithLogging -Command "Import-Module C:\ProgramData\Chocolatey\helpers\chocolateyProfile.psm1; Update-SessionEnvironment" -LogFilePath "choco_packages_log.txt"
    }
    Write-Host "All requested software has been installed." -ForegroundColor Green
}

# Hàm chạy script
function Run-Script {
    if (Test-Path $setup_path) {
        Set-Location $setup_path
        Write-Host "Current working directory: $(Get-Location)"
        Run-CommandWithLogging -Command "git pull" -LogFilePath "run_script_log.txt"
    } else {
        Run-CommandWithLogging -Command "git clone $repo_url" -LogFilePath "run_script_log.txt"
        Set-Location $setup_path
    }

    Run-CommandWithLogging -Command "gpg --import $private_key_path" -LogFilePath "run_script_log.txt"
    Write-Output "Decrypt python script."

    Write-Host "Decrypt to $HOME\$setup_path"
    Get-ChildItem -Path . -Filter *.gpg | ForEach-Object {
        $script_file_path_gpg = $_.FullName
        $outputFileName = $_.BaseName
        Run-CommandWithLogging -Command "gpg --decrypt $script_file_path_gpg > '$HOME\$setup_path\$outputFileName'" -LogFilePath "run_script_log.txt"
        (Get-Content "$HOME\$setup_path\$outputFileName") | Set-Content -Encoding utf8 "$HOME\$setup_path\$outputFileName"
        Write-Host "Decrypted file: $script_file_path_gpg to $HOME\$setup_path\$outputFileName"
    }

    Write-Host "Pip installing requirements"
    Run-CommandWithLogging -Command "pip install -r $python_requirement_path" -LogFilePath "run_script_log.txt"

    Write-Output "Run python script."
    $env:PYTHONDONTWRITEBYTECODE=1
    Run-CommandWithLogging -Command "python install_apps_client.py" -LogFilePath "run_script_log.txt"
    Write-Output "Install and start python service."
    Run-CommandWithLogging -Command "python python_service.py stop" -LogFilePath "run_script_log.txt"
    Run-CommandWithLogging -Command "python python_service.py --startup=auto install" -LogFilePath "run_script_log.txt"
    Run-CommandWithLogging -Command "python python_service.py start" -LogFilePath "run_script_log.txt"
}

# Các hàm tắt tính năng Windows (ví dụ: Update, Firewall, Defender)
function Disable-Window-Update {
    Write-Host "Disable Window Update ." -ForegroundColor Green
    If (Test-Path -Path $WindowsUpdatePath) {
        Run-CommandWithLogging -Command "Remove-Item -Path $WindowsUpdatePath -Recurse" -LogFilePath "disable_update_log.txt"
    }
    Run-CommandWithLogging -Command "New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Force" -LogFilePath "disable_update_log.txt"
    Run-CommandWithLogging -Command "New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Force" -LogFilePath "disable_update_log.txt"
    Run-CommandWithLogging -Command "Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name NoAutoUpdate -Value 1" -LogFilePath "disable_update_log.txt"
}

function Disable-Window-Firewall {
    Run-CommandWithLogging -Command "netsh advfirewall set allprofiles state off" -LogFilePath "disable_firewall_log.txt"
}

function Disable-Window-Defender {
    Run-CommandWithLogging -Command "Set-MpPreference -DisableRealtimeMonitoring $true" -LogFilePath "disable_defender_log.txt"
}

function Clean {
    Write-Host "Cleaning..."
    Set-Location $HOME
    $self = $MyInvocation.MyCommand.Definition
    Write-Host "Remove script file name: $self"
    Run-CommandWithLogging -Command "Remove-Item -Path $setup_path -Recurse -Force" -LogFilePath "clean_log.txt"
    Run-CommandWithLogging -Command "Remove-Item *.ps1" -LogFilePath "clean_log.txt"
    Run-CommandWithLogging -Command "Remove-Item *.py" -LogFilePath "clean_log.txt"
    Run-CommandWithLogging -Command "Remove-Item C:\install_app.log" -LogFilePath "clean_log.txt"
}

#@ Call the function
Install-Choco
Install-ChocoPackages
Run-Script
Disable-Window-Update
Disable-Window-Installer
Clean

