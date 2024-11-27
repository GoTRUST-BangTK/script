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

#? sync time NTP
w32tm /resync

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
        Write-Host "Chocolatey is not installed. Installing now..." -ForegroundColor Yellow
        If( Test-Path -Path "C:\ProgramData\chocolatey" ) {
            Remove-Item -Recurse -Force "C:\ProgramData\chocolatey"
        }
       
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
       $env:Path += ";$([System.Environment]::GetEnvironmentVariable('ChocolateyInstall'))\bin" 
        choco upgrade chocolatey --version=1.4.0 -y --force
    }
}

# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1MRUOB2DDOOEQ4KH-TFOIC3pYOP8fjt6Q&export=download&authuser=0&confirm=t&uuid=a5b1d028-aa42-4335-9be7-176e455c1713&at=AENtkXa3GhZUp5WbPzsKSIo0mubH:1732518754998" -OutFile git.zip

# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1s-JPcCjOChKAOf2wdLwyO9DK6-ufbZQ7&export=download&authuser=0&confirm=t&uuid=97f5a6ef-8ffa-464c-a6b4-d211fb02360d&at=AENtkXZTlbG8rByFQbrRAw8bgt-k:1732518816586" -OutFile python312.zip

# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1rwp1kqiZrmi_SJNLoeP5Hh4rYQ-I8Aad&export=download&authuser=0&confirm=t&uuid=2ff9a88e-717e-4649-b139-27b3609890d3&at=AENtkXaX3DtzyiGy7SkVIEBf5fOf:1732518815997"  -OutFile gpg.zip

# New-Item -Path "C:\ProgramData\chocolatey\lib" -ItemType Directory -Force
# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1bTQvjah-QPxnYUqjcaY0ny10D31d7hLo&export=download&authuser=0&confirm=t&uuid=3348b0d5-c8d4-4043-8d79-db4c4971b741&at=AENtkXahT0Y2cBVF6lUegpgVRot9:1732546749167"  -OutFile "C:\ProgramData\chocolatey\lib\vcredist2015.zip"
# Expand-Archive -Path "C:\ProgramData\chocolatey\lib\vcredist2015.zip" -DestinationPath "C:\ProgramData\chocolatey\lib\vcredist2015" -Force
# Remove-Item "C:\ProgramData\chocolatey\lib\vcredist2015.zip" -Force
 
# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1zq4XkRxIgYZ4tCNpm0d9KvWuCmw7UQro&export=download&authuser=0&confirm=t&uuid=917e5d0d-df63-4668-9144-17194d37c4bf&at=AENtkXamcpWGqVQWUEdKNSPeTCDB:1732548318959"  -OutFile "C:\ProgramData\chocolatey\lib\vcredist140.zip"
# Expand-Archive -Path "C:\ProgramData\chocolatey\lib\vcredist140.zip" -DestinationPath "C:\ProgramData\chocolatey\lib\vcredist140" -Force
# Remove-Item "C:\ProgramData\chocolatey\lib\vcredist140.zip" -Force

# Invoke-WebRequest -Uri "https://drive.usercontent.google.com/download?id=1IpvigarhlnfHpzMRXghLYrlA6Xao3Y4g&export=download&authuser=0&confirm=t&uuid=5d5cf5b6-38ca-48a2-a690-d97850dc62dd&at=AENtkXbhACtr0AGvEReSexyvcY_W:1732547852560"  -OutFile "chocolatey.zip"
# Expand-Archive -Path "$HOME\chocolatey.zip" -DestinationPath "C:\ProgramData"
# $env:Path += ";C:\ProgramData\chocolatey\bin"
# RefreshEnv

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

function Disable-Window-Installer {
    Write-Host " Disable Window Installer ." -ForegroundColor Green
    Stop-Service -Name msiserver
    Set-Service -Name msiserver -StartupType Disabled
}

function Set-Firewall-Rule{
    New-NetFirewallRule -DisplayName "Allow DNS for gotrust.vn" -Direction Outbound -Protocol UDP -LocalPort 53 -RemoteAddress any -Action Allow

    New-NetFirewallRule -DisplayName "Block All Other Outbound Traffic" -Direction Outbound -Protocol TCP -Action Block
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

