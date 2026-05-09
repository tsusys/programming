VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "TenantInfo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'--------------------------------------------------------------------------------
'
' テナント情報
'
'--------------------------------------------------------------------------------

''' <summary>
''' 会社名
''' </summary>
''' <remarks></remarks>
Public CompanyName As String

''' <summary>
''' プロキシサーバのIPアドレス
''' </summary>
''' <remarks>SSHにてテナントに接続する際に必要</remarks>
Public ProxyServer As String

''' <summary>
''' ノードID
''' </summary>
''' <remarks></remarks>
Public NodeId As String

''' <summary>
''' 管理ポータルコード
''' </summary>
''' <remarks></remarks>
Public PortalCd As String

''' <summary>
''' 言語("ja" または "en")
''' </summary>
''' <remarks>週次レポートの言語を識別するのに必要</remarks>
Public Lang As String

''' <summary>
''' SSHキー
''' </summary>
''' <remarks>SSHにてテナントに接続する際に使用</remarks>
Public SshKey As String

''' <summary>
''' ファイルダウンロード用URL
''' </summary>
''' <remarks></remarks>
Public BoxUrl As String

''' <summary>
''' Zipパスワード
''' </summary>
''' <remarks></remarks>
Public ZipPassword As String

''' <summary>
''' 月次ファイルの送付先
''' </summary>
''' <remarks></remarks>
Public mailTo As String

''' <summary>
''' 月次ファイルの送付先(PM)
''' </summary>
''' <remarks></remarks>
Public PM As String

''' <summary>
''' 初回処理フラグ
''' 初回送信の場合True
''' </summary>
''' <remarks>初回送信と２回目以降では、送信メールの内容が異なる</remarks>
Public First As Boolean

''' <summary>
''' 送信済みフラグ
''' 送信済みの場合True
''' </summary>
''' <remarks></remarks>
Public Sent As Boolean

''' <summary>
''' 行番号
''' </summary>
''' <remarks></remarks>
Public Row As Long

''' <summary>
''' レポートの保存場所を取得する
''' </summary>
''' <returns>レポートの保存場所</returns>
''' <remarks></remarks>
Public Property Get SaveDir()
    SaveDir = Settings.SaveDir & "\" & Me.PortalCd
End Property
