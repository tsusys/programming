
#アメリカ株のティッカーを入れる
$ticker = Read-Host "ティッカーを入力してください"

#変数にURL入れる
$url = "https://www.google.com/search?q=$ticker+chart"

#ブラウザで変数url実行
Start-Process $url






