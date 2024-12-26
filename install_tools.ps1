 # $($args[0])"

$packages = @("python", "gnupg", "git")

$repo_url = "https://github.com/GoTRUST-BangTK/script.git"
$setup_path = 'script'
$private_key_path = 'secret\private_key.asc'
$python_requirement_path = 'requirements.txt' 

$WindowsUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
$AutoUpdatePath    = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$LogFilePath = "c:\install_tool.log"

Remove-Item $LogFilePath -ErrorAction SilentlyContinue

#> Run-CommandWithLogging -Command "Get-Process" 
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
function    Write-Output_ {
    if ($args.Count -eq 0) {
        Write-Output "No message provided"
    } else {
        $Message = $args[0]
        Write-Output $Message
        $Message | Out-File -FilePath $LogFilePath -Append
    }
} 

Run-CommandWithLogging -Command "w32tm /resync" 

Write-Output_ "Check if the kiosk is already set up."
if (Test-Path "HKLM:\SOFTWARE\MediPay") {
    $kioskId = Get-ItemProperty -Path "HKLM:\SOFTWARE\MediPay" -Name "KioskId" -ErrorAction SilentlyContinue
    $secretKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\MediPay" -Name "SecretKey" -ErrorAction SilentlyContinue

    if ($kioskId.KioskId -and $secretKey.SecretKey) {
        Write-Output_ "This machine is already configured."
        $userInput = Read-Host "Do you want to continue? (y/n)" 
        if ($userInput -eq 'n') {
            Write-Output_ "Exiting script..."
            exit
        } elseif ($userInput -eq 'y') {
            Write-Output_ "Continuing with the script..."
        } else {
            Write-Output_ "Invalid input. Please enter 'y' or 'n'."
            exit
        }
    } else {
        Write-Output_ "Configuration is incomplete.."
    }
} else {
    Write-Output_ "This machine is not setup yet."
}

# Tạo registry nếu chưa tồn tại
if (-not (Test-Path -Path "HKLM:SOFTWARE\AutoUpgrade")) {
    Write-Output_ "Create HKLM:SOFTWARE\AutoUpgrade Registry"
    Run-CommandWithLogging -Command "New-Item -Path 'HKLM:SOFTWARE\AutoUpgrade' -Force" 
}

function Install-Choco { 
    if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Output_ "Chocolatey is already installed."
    } else { 
    Write-Output_ "Chocolatey is not installed. Installing now..."
        if (Test-Path -Path "C:\ProgramData\chocolatey") {
            Run-CommandWithLogging -Command "Remove-Item -Recurse -Force 'C:\ProgramData\chocolatey'" 
        }
        Run-CommandWithLogging -Command "Set-ExecutionPolicy Bypass -Scope Process -Force" 
        Run-CommandWithLogging -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072" 
        Run-CommandWithLogging -Command "Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" 
        Run-CommandWithLogging -Command "choco upgrade chocolatey --version=1.4.0 -y --force" 
    }
}

function Install-ChocoPackages {
    foreach ($package in $packages) {
        Run-CommandWithLogging -Command "choco install $package -y" 
    }

    Write-Output_ "Refresh environment"
    Run-CommandWithLogging -Command "Import-Module C:\ProgramData\Chocolatey\helpers\chocolateyProfile.psm1; Update-SessionEnvironment" 

    if (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Output_ "pip is already installed."
    } else {
    Write-Output_ "pip is not installed. Installing now..."
        Install-Choco
        Run-CommandWithLogging -Command "Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile get-pip.py" 
        Run-CommandWithLogging -Command "python get-pip.py" 
        Run-CommandWithLogging -Command "Import-Module C:\ProgramData\Chocolatey\helpers\chocolateyProfile.psm1; Update-SessionEnvironment" 
    }
    Write-Output_ "All requested software has been installed."
}

function Run-Script {
    if (Test-Path $setup_path) {
        Set-Location $setup_path
        Write-Output_ "Current working directory: $(Get-Location)"
        Run-CommandWithLogging -Command "git pull" 
    } else {
        Run-CommandWithLogging -Command "git clone $repo_url" 
        Set-Location $setup_path
    }

    Run-CommandWithLogging -Command "gpg --import $private_key_path" 
    Write-Output_ "Decrypt python script."

    Write-Output_ "Decrypt to $HOME\$setup_path"
    Get-ChildItem -Path . -Filter *.gpg | ForEach-Object {
        $script_file_path_gpg = $_.FullName
        $outputFileName = $_.BaseName
        Run-CommandWithLogging -Command "gpg --decrypt $script_file_path_gpg > '$HOME\$setup_path\$outputFileName'" 
        (Get-Content "$HOME\$setup_path\$outputFileName") | Set-Content -Encoding utf8 "$HOME\$setup_path\$outputFileName"
    Write-Output_ "Decrypted file: $script_file_path_gpg to $HOME\$setup_path\$outputFileName"
    }

    Write-Output_ "Pip installing requirements"
    Run-CommandWithLogging -Command "pip install -r $python_requirement_path" 

    Write-Output_ "Run python script."
    $env:PYTHONDONTWRITEBYTECODE=1
    python install_apps_client.py

    if ($env:TEST -eq 'true') {
        Write-Output_ "Install and start python service."
        python auto_upgrade_service.py stop
        python auto_upgrade_service.py --startup=auto install
        python auto_upgrade_service.py start

        Write-Output_ "Install task scheduler for sending log."
        python task_scheduler.py
    } 
}

function Disable-Window-Update {
    If(Test-Path -Path $WindowsUpdatePath) {
        Run-CommandWithLogging -Command "Remove-Item -Path $WindowsUpdatePath -Recurse"
    }
    Run-CommandWithLogging -Command "New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Force"
    Run-CommandWithLogging -Command "New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Force"
    Write-Output_ "[+] Disable AutoUpdate:"
    Run-CommandWithLogging -Command "Set-ItemProperty -Path $AutoUpdatePath -Name NoAutoUpdate -Value 1"
    Write-Output_ "[+] Disabel Windows update ScheduledTask"
    Run-CommandWithLogging -Command "Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate\' | Disable-ScheduledTask"
    Write-Output_ "[+] Take Windows update  Orchestrator ownership"
    Run-CommandWithLogging -Command "takeown /F C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator /A /R"
    Run-CommandWithLogging -Command "icacls C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator /grant Administrators:F /T"
    Write-Output_ "[+] List Windows update  Orchestrator ownership"
    Run-CommandWithLogging -Command "Get-ScheduledTask -TaskPath '\Microsoft\Windows\UpdateOrchestrator\' | Disable-ScheduledTask"
    Write-Output_ "[+] Disable Windows Update Server AutoStartup"
    Run-CommandWithLogging -Command "Set-Service wuauserv -StartupType Disabled"
    Run-CommandWithLogging -Command "sc.exe config wuauserv start=disabled "
    Write-Output_ "[+] Disable Windows Update Running Service"
    Run-CommandWithLogging -Command "Stop-Service wuauserv "
    Run-CommandWithLogging -Command "sc.exe stop wuauserv "
    Write-Output_ "[+] Check Windows Update Service state"
    Run-CommandWithLogging -Command "sc.exe query wuauserv | findstr 'STATE'"
}

function Disable-Window-Firewall {
    Run-CommandWithLogging -Command "netsh advfirewall set allprofiles state off" 
}

function Disable-Window-Defender {
    Run-CommandWithLogging -Command "Set-MpPreference -DisableRealtimeMonitoring $true" 
}

function Disable-Window-Installer {
    Write-Output_ "Disable Window Installer."
    Stop-Service -Name msiserver
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\msiserver" -Name "Start" -Value 4
    Get-Service -Name msiserver
}

function Disable-Screen-Edge-Swipe {
    Write-Output_ "Disable Screen Edge Swipe."
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe /t REG_DWORD /d 0 /f
    taskkill /f /im explorer.exe
    start explorer.exe
}

#@ Call the functions
Install-Choco
Install-ChocoPackages
Run-Script  
Disable-Window-Update
# Disable-Window-Installer 
Disable-Screen-Edge-Swipe 
