<#
.SYNOPSIS
    Box APIのアクセストークンを取得し、
    access_token.txt に暗号化したアクセストークンを保存します。
#>
$ErrorActionPreference = "Stop"
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $path

$ss = Get-Content encrypted.txt | ConvertTo-SecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
$cs = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

$url = "https://api.box.com/oauth2/token"
$headers = @{
    "content-type" = "application/x-www-form-urlencoded"
}
$body = @{
    "client_id" = "geqrfqhq4qx4zv8vodrzzavgq2asrxak"
    "client_secret" = $cs
    "grant_type" = "client_credentials"
    "box_subject_type" = "enterprise"
    "box_subject_id" = "206102445"
}

$json = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
$ss = ConvertTo-SecureString -string $json.access_token -AsPlainText -Force
$ss | ConvertFrom-SecureString | Out-File access_token.txt
