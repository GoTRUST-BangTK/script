$private_key_path = 'secret\private_key.asc'
$folderPath = '.'
gpg --import $private_key_path
Write-Output "Decrypt python script."
 
Get-ChildItem -Path $folderPath -Filter *.gpg | ForEach-Object {
    $script_file_path_gpg = $_.FullName
    $outputFileName = $_.BaseName
    gpg --decrypt $script_file_path_gpg > "$folderPath\$outputFileName.py"
    (Get-Content "$folderPath\$outputFileName.py") | Set-Content -Encoding utf8 "$folderPath\$outputFileName.py"
    Write-Host "Decrypted file: $script_file_path_gpg to $outputFileName.py"
}


Write-Output "Run python script." 