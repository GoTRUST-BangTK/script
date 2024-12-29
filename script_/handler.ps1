$install_app_log_file_path = 'C:/install_apps.log'
$Uri = "https://api.telegram.org/bot7758334928:AAEM-PqCzWFn7M_11dcS5Xlev9PS1lgDJNo/sendDocument"
$ChatId = "-4583989930"

function Send-Log {
    curl.exe -F "chat_id=$ChatId" -F "document=@$install_app_log_file_path" $Uri
}

function Clean {
    Write-Host "Cleaning..."
    Set-Location $HOME
    $self = $MyInvocation.MyCommand.Definition
    Remove-Item *.ps1 -ErrorAction SilentlyContinue
    Remove-Item C:\install_apps.log -ErrorAction SilentlyContinue
}

# Send-Log
Clean
