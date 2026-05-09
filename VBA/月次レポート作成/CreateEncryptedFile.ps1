<#
.SYNOPSIS
    encrypted.txt を作成する

.DESCRIPTION
    Box APIで使用するClient Secretを暗号化し、encrypted.txt を作成します。
#>
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $path

$cs = Read-Host "クライアントシークレットを入力してください"
$ss = ConvertTo-SecureString -string $cs -AsPlainText -Force
$ss | ConvertFrom-SecureString | Out-File encrypted.txt
