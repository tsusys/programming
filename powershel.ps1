# ティッカーをカンマ区切りで入力してもらう
$inputTickers = Read-Host "ティッカーをカンマ区切りで入力してください (例: AAPL, MSFT)"

# 入力された文字列をカンマで分割し、前後の空白を取り除く
$tickers = $inputTickers -split ',' | ForEach-Object { $_.Trim() }

foreach ($ticker in $tickers) {
    if (![string]::IsNullOrWhiteSpace($ticker)) {
        # Google Financeの検索に対して「window=1Y(1年表示)」を指定
        $url = "https://www.google.com/finance?q=$ticker&window=1Y"
        Start-Process $url
    }
}
