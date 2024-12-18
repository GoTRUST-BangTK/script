$setup_path = 'script'
$private_key_path = 'secret\private_key.asc'
$python_requirement_path = 'requirements.txt' 

$WindowsUpdatePath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
$AutoUpdatePath    = "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$LogFilePath = "c:\install_tool.log"

Get-ChildItem -Path . -Filter *.gpg | ForEach-Object {
    $script_file_path_gpg = $_.FullName
    $outputFileName = $_.BaseName
    gpg --decrypt $script_file_path_gpg > "$HOME\$setup_path\$outputFileName"
    (Get-Content "$HOME\$setup_path\$outputFileName") | Set-Content -Encoding utf8 "$HOME\$setup_path\$outputFileName"
    Write-Output "Decrypted file: $script_file_path_gpg to $HOME\$setup_path\$outputFileName"
}