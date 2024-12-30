 # $($args[0])"
 
$LogFilePath = "c:\install_apps.log"
$KIOSK_SERVICE_PATH = "C:\KioskService"
$API_FOLDER_PATH = "C:\KioskService\API"
$MEDIPAY_FOLDER_PATH = "C:\KioskService\Medipay"

New-Item -Path $API_FOLDER_PATH -ItemType Directory -Force
New-Item -Path $MEDIPAY_FOLDER_PATH -ItemType Directory -Force
$ProgressPreference = 'SilentlyContinue'

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
function Write-Output_ {
    if ($args.Count -eq 0) {
        Write-Output "No message provided"
    } else {
        $Message = $args[0]
        Write-Output $Message
        $Message | Out-File -FilePath $LogFilePath -Append
    }
} 

function Download-Drive-Extract{
    $files = @(
        @{
            Uri = 'https://drive.usercontent.google.com/download?id=1nZkm1KEtouJG6LOYvuLAVYp36T4d2nkT`&export=download`&authuser=0`&confirm=t`&uuid=e3ea8482-5631-4237-ad8d-ba45a899ae81`&at=APvzH3qiqMWBi73KE6Ly0QXYzsb6:1735447023391'
            FileName = 'API_HN212.zip'
            ExtractPath = "C:\KIOSKService\API"
        },
        @{
            Uri = 'https://drive.usercontent.google.com/download?id=1vfBK3ZlBdpLpDB2gb1LtL2u_N9BA7Zpm`&export=download`&authuser=0`&confirm=t`&uuid=c5c20cff-0c1e-4063-9fca-fe5933524284`&at=APvzH3rWG57lRpIM9oNHGIky8Luu:1735448696209'
            FileName = 'MediPay_App.zip'
            ExtractPath = "C:\KIOSKService\Medipay"
        },
        @{
            Uri = 'https://drive.usercontent.google.com/download?id=1BvxFA_QOhX07JPHMnqC3UmJy-8rq6XIf`&export=download`&authuser=0`&confirm=t`&uuid=6cdcc5fe-2cb0-420b-b372-3b138fe16672`&at=APvzH3oOVSYIeS3kmowrYwovFh97:1735448764680'
            FileName = 'MediPay_Updater.zip'
            ExtractPath = 'C:\KIOSKService'
        },
        @{
            Uri = 'https://drive.usercontent.google.com/download?id=1pfoMHmxmhXrrlSf6q644gJkiLNR6EY6e`&export=download`&authuser=0`&confirm=t`&uuid=2fa238c3-2580-4138-a10b-1cbe0bf4b398`&at=APvzH3ocBlokJHWpwZUEPm2T0R_d:1735448767165'
            FileName = 'Support_Exe.zip'
            ExtractPath = "C:\KIOSKService"
        }
    )

    foreach ($file in $files) {
        $uri = $file.Uri
        $fileName = $file.FileName
        $extractPath = $file.ExtractPath
        $ProgressPreference = 'SilentlyContinue'

        Run-CommandWithLogging -Command "Invoke-WebRequest -Uri $uri -OutFile $fileName"
        Run-CommandWithLogging -Command "Expand-Archive -Path $fileName -DestinationPath $extractPath -Force"
        Run-CommandWithLogging -Command "Remove-Item -Path $fileName -Force"
        Write-Output_ "File $fileName downloaded and extracted successfully to $extractPath"
    }

    if (Test-Path -Path "$API_FOLDER_PATH\API_HN212") {
        Get-ChildItem -Path "$API_FOLDER_PATH\API_HN212" -Recurse -Force |
            Move-Item -Destination $API_FOLDER_PATH -Force
        Remove-Item -Path "$API_FOLDER_PATH\API_HN212" -Recurse -Force
    } else {
        Write-Host "Path $API_FOLDER_PATH\API_HN212 is not existing, skipping."
    }
    if (Test-Path -Path "$MEDIPAY_FOLDER_PATH\MediPay_App") {
        Get-ChildItem -Path "$MEDIPAY_FOLDER_PATH\MediPay_App" -Recurse -Force |
            Move-Item -Destination $MEDIPAY_FOLDER_PATH -Force
        Remove-Item -Path "$MEDIPAY_FOLDER_PATH\MediPay_App" -Recurse -Force
    } else {
        Write-Host "Path $MEDIPAY_FOLDER_PATH\MediPay_App is not existing, skipping"
    }
}

# Run-CommandWithLogging -Command "w32tm /resync" 

function Execute{
    $executables = @(
        # @{
        #     Path = "C:\KIOSKService\API\API.exe"
        #     NoNewWindow = $false
        #     WindowStyle = "Normal"
        # },
        # @{
        #     Path = "C:\KIOSKService\Medipay\MediPay.exe"
        #     NoNewWindow = $false
        #     WindowStyle = "Normal"
        # },
        @{
            Path = "C:\KIOSKService\Support_Exe\VC_redist.x64.exe"
            NoNewWindow = $false
            WindowStyle = "Normal"
        },
        @{
            Path = "C:\KIOSKService\MediPay_Updater\AutoUpgradeApp.exe"
            NoNewWindow = $false
            WindowStyle = "Hidden"
        }
    )

    foreach ($exe in $executables) {
        if (Test-Path -Path $exe.Path) {
            Start-Process -FilePath $exe.Path -WindowStyle $exe.WindowStyle
            Write-Output_ "Started $($exe.Path)"
        } else {
            Write-Output_ "Executable $($exe.Path) not found, skipping."
        }
    }
}

function Config-Kiosk {
    $registryPath = "HKLM:\SOFTWARE\MediPay"
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force
    }
    Set-ItemProperty -Path $registryPath -Name "KioskId" -Value $kioskIdValue -Type String
    Set-ItemProperty -Path $registryPath -Name "SecretKey" -Value $secretKeyValue -Type String
    if (Test-Path $registryPath) {
        Write-Host "Create config success!"
    } else {
        Write-Host "Create config ERROR!"
    }
}

function Hide-Taskbar {
    # Note: change $v[8]=3 to $v[8]=2 in the commands to undo this change
    $p='HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    $v=(Get-ItemProperty -Path $p).Settings;$v[8]=3
    Set-ItemProperty -Path $p -Name Settings -Value $v
    # Stop-Process -f -ProcessName explorer}
}

function Set-Vietnamese-Language {
    Write-Output_ "Set Vietnamese Language."
    $ProgressPreference = 'SilentlyContinue'
    Run-CommandWithLogging -Command "Install-Language -Language vi-VN"

    Run-CommandWithLogging -Command "Set-WinUILanguageOverride -Language vi-VN"
    Run-CommandWithLogging -Command "Set-WinDefaultInputMethodOverride -InputTip vi-VN"
    Run-CommandWithLogging -Command "Set-WinSystemLocale -SystemLocale vi-VN"
    Run-CommandWithLogging -Command "Set-Culture -CultureInfo vi-VN"

    $LangList = New-WinUserLanguageList -Language "vi-VN"
    Run-CommandWithLogging -Command "Set-WinUserLanguageList -LanguageList $LangList -Force"
    Run-CommandWithLogging -Command "Set-SystemPreferredUILanguage -Language 'vi-VN'"

    Run-CommandWithLogging -Command "Get-SystemPreferredUILanguage"
    Run-CommandWithLogging -Command "Get-WinUserLanguageList"
    Run-CommandWithLogging -Command "Get-WinUILanguageOverride"
    Run-CommandWithLogging -Command "Get-WinSystemLocale"
}

function Disable-Window-Update {
    $WindowsUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
    $AutoUpdatePath    = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"    
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

function Disable-Window-Installer {
    Write-Output_ "Disable Window Installer."
    Stop-Service -Name msiserver
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\msiserver" -Name "Start" -Value 4
    Get-Service -Name msiserver
}

function Disable-Screen-Edge-Swipe {
    Write-Output_ "Disable Screen Edge Swipe."
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\EdgeUI" /v AllowEdgeSwipe /t REG_DWORD /d 0 /f
}

function Restart-Explorer{
    taskkill /f /im explorer.exe
    start explorer.exe
}

#@ Call the functions
Download-Drive-Extract
Config-Kiosk
Execute
Disable-Window-Update
Disable-Window-Installer 
Disable-Screen-Edge-Swipe 
Hide-Taskbar
Set-Vietnamese-Language
Restart-Explorer