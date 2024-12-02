$uri = "https://api.telegram.org/bot7758334928:AAEM-PqCzWFn7M_11dcS5Xlev9PS1lgDJNo/sendDocument"
$chatId = "-4583989930"
$filePath = "C:\install_tools.log"

$body = @{
    chat_id = $chatId
    document = [System.IO.File]::ReadAllBytes($filePath)
}

Invoke-RestMethod -Uri $uri -Method Post -ContentType "multipart/form-data" -Body $body
