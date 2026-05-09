<#
.SYNOPSIS
    Box フォルダの共有リンクを取得します。

.PARAMETER FolderName
    共有リンクを作成するフォルダ名
#>
param (
    $FolderName = $(throw "FolderName parameter is required.")
)
$ErrorActionPreference = "Stop"
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $path

#クライアントシークレットを復号化する
$ss = Get-Content access_token.txt | ConvertTo-SecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
$at = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)

#フォルダを検索する
$url = "https://api.box.com/2.0/search?query=""$FolderName""&type=folder&scope=user_content&content_types=name&limit=1"
$headers = @{
    "authorization" = "Bearer $at"
}
$json = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

if ($json.total_count -ge 1 -and $json.entries.Count -eq 1) {
    if ($json.entries[0].name -eq $FolderName) {
        #共有リンクを作成する
        #期限は月末までとする
        $url = "https://api.box.com/2.0/folders/$($json.entries[0].id)/?fields=shared_link"
        $body = @{
            "shared_link" = @{
                "access" = "open"
                "unshared_at" = [DateTime]::Today.AddMonths(1).ToString("yyyy-MM-01T00:00:00+09:00")
                "permissions" = @{
                    "can_download" = $true
                }
            }
        }
        $json = ConvertTo-Json $body
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $json = Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $bytes -ContentType "application/json"
        $json.shared_link.url
    }
}