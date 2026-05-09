<#
.SYNOPSIS
    週次レポートのダウンロード

.DESCRIPTION
    月次レポートを作成することを踏まえて、実行日時から見て前月分のデータを含む週次レポートをダウンロードします。
    既に取得済みの場合であっても再ダウンロードし、レポートファイルを上書きします。
    本スクリプト実行前に、GlobalProtectにてVPN接続が必要です。

.PARAMETER ProxyServer
    プロキシサーバのIPアドレス

.PARAMETER NodeId
    ノードID
    
.PARAMETER PortalCd
    管理ポータルコード

.PARAMETER Lang
    週次レポートの言語(ja=日本語, en=英語)

.PARAMETER SshKey
    SSHキーファイル

.PARAMETER SaveDir
    週次レポートの保存先
    ※SaveDirの示す先に管理ポータルコード名でフォルダを作成し、その配下に週次レポートを保存します。

.EXAMPLE
    .GetWeeklyReports.ps1 210.140.96.143 75000 mp402c8y700 ja mbsd-tis.pem.idcf C:\work\api

#>
param (
    $ProxyServer = $(throw "ProxyServer parameter is required."),
    $NodeId = $(throw "NodeId parameter is required."),
    $PortalCd = $(throw "PortalCd parameter is required."),
    $Lang = $(throw "Lang parameter is required."),
    $SshKey = $(throw "SshKey parameter is required."),
    $SaveDir = $(throw "SaveDir parameter is required.")
)

cd $(Split-Path $MyInvocation.MyCommand.path)

$remote_server = "portal01-$NodeId"
$ssh_option = "-oStrictHostKeyChecking=no"
$proxy_command = "ssh -W %h:%p $ssh_option -i ""$SshKey"" -p 22 root@$ProxyServer"
$ssh_command = "ssh $ssh_option -oProxyCommand='$proxy_command' -i ""$SshKey"" -p 22 root@$remote_server"
$scp_command = "scp $ssh_option -oProxyCommand='$proxy_command' -i ""$SshKey"" -P 22 -r root@$remote_server"

#ダウンロード対象を確認：先月分(月初は除く)
$last_month = (Get-Date -date (Get-Date) -Day 1).AddMonths(-1).ToString("yyyy-MM")
$remote_command = "ls /opt/report/$PortalCd | grep -E '^${Lang}_${last_month}-.*\.xls.*$' | grep -v ${last_month}-01"
$report_list = Invoke-Expression "$ssh_command ""$remote_command"""

#ダウンロード対象を確認：今月分(初週分のみ)
$this_month = (Get-Date -date (Get-Date) -Day 1).ToString("yyyy-MM")
$remote_command = "ls /opt/report/$PortalCd | grep -E '^${Lang}_${this_month}-0[1-7]{1}.*\.xls.*$'"
$report_list += Invoke-Expression "$ssh_command ""$remote_command"""

#ダウンロードフォルダを作成
$local_dir = "$SaveDir\\$last_month"
if (!(Test-Path $SaveDir)) {
    mkdir $SaveDir
}
if (!(Test-Path $local_dir)) {
    mkdir $local_dir
}

Write-Host "サーバ上のファイル:"
foreach ($remote_file in $report_list) {
    Write-Host　(" - " + $remote_file)
}

#おかしなファイルの検知
$last_end = 0
$this_start = 0
$this_end = 0
$not_download = New-Object System.Collections.ArrayList
for ($i=0; $i -lt $report_list.Count; $i++) {
    $remote_file = $report_list[$i]
    $this_start = [int]($remote_file.Substring(29, 2))
    $this_end = [int]($remote_file.Substring(32, 2))

    if ($i -eq 0) {
        $last_end = $this_end
    } else {
        if ($this_start -ne ($last_end + 1)) {
            #日付が連続していないがダウンロードするか
            Write-Host($remote_file + " はその前のファイルと日付が連続していません。")
            do {
                $str = (Read-Host("ダウンロードしますか？ [Y/N]")).Trim().ToUpper()
            } while ($str -notmatch "^[YN]$")
            if ($str -eq "Y") {
                $last_end = $this_end
            } else {
                #ダウンロードしない
                $not_download.Add($remote_file)
            }
        } else {
            $last_end = $this_end
        }
    }
}

#SCPでダウンロード
foreach ($remote_file in $report_list) {
    #すでにダウンロード済みの場合はダウンロードしない
    if (Test-Path "$local_dir\\$remote_file") {
        continue
    }

    #おかしなファイルの検知がされなかったものをダウンロード
    if (-not $not_download.Contains($remote_file)) {
        Invoke-Expression "${scp_command}:'""/opt/report/$PortalCd/$remote_file""' ""$local_dir"""
    }
}

