 # $($args[0])"
 
$packages = @("python", "gnupg", "git")

# $repo_url = 'http://gitea.local/kimbang/script.git'
$repo_url = "https://github.com/GoTRUST-BangTK/script.git"
$private_key_path = 'secret\private_key.asc'
$script_file_path_gpg= 'install_apps_client.py.gpg' 
# $config_file_path_gpg= 'config.py.gpg' 
$python_requirement_path = 'requirements.txt'
$setup_path = 'script'
# $HOME = 'C:\Windows\System32'
# $python = '.\python312\Python312\python.exe'
# $gpg = '.\gpg\gnupg\bin\gpg.exe'
# $git = '\git\Git\bin\git.exe'

$WindowsUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
$AutoUpdatePath    = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"


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

If(-not (Test-Path -Path "HKLM:SOFTWARE\AutoUpgrade")) {
    Write-Host "Create HKLM:SOFTWARE\AutoUpgrade Registry"
    New-Item -Path "HKLM:SOFTWARE\AutoUpgrade" -Force
}

function Install-Choco{ 
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Chocolatey is already installed." -ForegroundColor Green
    }else { 
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        Write-Host "Chocolatey is not installed. Installing now..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force "C:\ProgramData\chocolatey"
        
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
       $env:Path += ";$([System.Environment]::GetEnvironmentVariable('ChocolateyInstall'))\bin" 
        choco upgrade chocolatey --version=1.4.0 -y --force
    }

}

# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1MRUOB2DDOOEQ4KH-TFOIC3pYOP8fjt6Q&export=download&authuser=0&confirm=t&uuid=a5b1d028-aa42-4335-9be7-176e455c1713&at=AENtkXa3GhZUp5WbPzsKSIo0mubH:1732518754998" -OutFile git.zip

# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1s-JPcCjOChKAOf2wdLwyO9DK6-ufbZQ7&export=download&authuser=0&confirm=t&uuid=97f5a6ef-8ffa-464c-a6b4-d211fb02360d&at=AENtkXZTlbG8rByFQbrRAw8bgt-k:1732518816586" -OutFile python312.zip

# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1rwp1kqiZrmi_SJNLoeP5Hh4rYQ-I8Aad&export=download&authuser=0&confirm=t&uuid=2ff9a88e-717e-4649-b139-27b3609890d3&at=AENtkXaX3DtzyiGy7SkVIEBf5fOf:1732518815997"  -OutFile gpg.zip

# Expand-Archive -Path "git.zip" -Force
# Expand-Archive -Path "python312.zip" -Force
# Expand-Archive -Path "gpg.zip" -Force

function Install-ChocoPackages { 
    foreach ($package in $packages) {  
        choco install $package -y 
    }
    
    Write-Output "Refresh environment" 
    Import-Module C:\ProgramData\Chocolatey\helpers\chocolateyProfile.psm1; Update-SessionEnvironment

    if (Get-Command pip -ErrorAction SilentlyContinue) {
        Write-Host "pip is already installed."
    } else {
        Write-Host "pip is not installed. Installing now..."
        Install-Choco
        Invoke-WebRequest -Uri https://bootstrap.pypa.io/get-pip.py -OutFile get-pip.py
        python get-pip.py
        Import-Module C:\ProgramData\Chocolatey\helpers\chocolateyProfile.psm1; Update-SessionEnvironment
    }
    Write-Host "All requested software has been installed." -ForegroundColor Green
}

function Run-Script {
    if (Test-Path $setup_path) {
        Set-Location $setup_path
        Write-Host "Current working directory: $(Get-Location)"
        git pull 
    } else {
        git clone $repo_url
        Set-Location $setup_path
    }

    gpg --import $private_key_path
    Write-Output "Decrypt python script."
 
    Write-Host "Decrypt to $HOME\$setup_path"
    Get-ChildItem -Path . -Filter *.gpg | ForEach-Object {
        $script_file_path_gpg = $_.FullName
        $outputFileName = $_.BaseName
        gpg --decrypt $script_file_path_gpg > "$HOME\$setup_path\$outputFileName"
        (Get-Content "$HOME\$setup_path\$outputFileName") | Set-Content -Encoding utf8 "$HOME\$setup_path\$outputFileName"
        Write-Host "Decrypted file: $script_file_path_gpg to $HOME\$setup_path\$outputFileName"
    }

    Write-Host "Pip installing requirements"
    pip install -r $python_requirement_path

    Write-Output "Run python script."
    $env:PYTHONDONTWRITEBYTECODE=1
    python install_apps_client.py 
    python python_service.py --startup=auto install
    python python_service.py start
}

function Disable-Window-Update {
    If(Test-Path -Path $WindowsUpdatePath) {
        Remove-Item -Path $WindowsUpdatePath -Recurse
    }
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force
    Write-Host "[+] Disable AutoUpdate:"
    Set-ItemProperty -Path $AutoUpdatePath -Name NoAutoUpdate -Value 1
    Write-Host "[+] Disabel Windows update ScheduledTask"
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" | Disable-ScheduledTask
    Write-Host "[+] Take Windows update  Orchestrator ownership"
    takeown /F C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator /A /R
    icacls C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator /grant Administrators:F /T
    Write-Host "[+] List Windows update  Orchestrator ownership"
    Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" | Disable-ScheduledTask
    Write-Host "[+] Disable Windows Update Server AutoStartup"
    Set-Service wuauserv -StartupType Disabled
    sc.exe config wuauserv start=disabled 
    Write-Host "[+] Disable Windows Update Running Service"
    Stop-Service wuauserv 
    sc.exe stop wuauserv 
     Write-Host "[+] Check Windows Update Service state"
    sc.exe query wuauserv | findstr "STATE"
}
function Disable-Windiws-Firewall{
    netsh advfirewall set allprofiles state off
}
function Disable-Windiws-Defender{
    Set-MpPreference -DisableRealtimeMonitoring $true
}

function Clean {
    Write-Host "Cleaning..."
    Set-Location $HOME
    $self = $MyInvocation.MyCommand.Definition
    Write-Host "Remove script file name: $self"
    Remove-Item -Path $setup_path -Recurse -Force
    Remove-Item *.ps1 
    Remove-Item *.py
}

#@ Call the function
Install-Choco
Install-ChocoPackages
Run-Script
Disable-Window-Update
Clean

