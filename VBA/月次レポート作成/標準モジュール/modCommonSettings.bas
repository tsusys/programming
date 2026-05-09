Attribute VB_Name = "modCommonSettings"
Option Explicit

'--------------------------------------------------------------------------------
'
' ツール共通設定
'
'--------------------------------------------------------------------------------

''' <summary>
''' ツール共通設定
''' </summary>
''' <remarks></remarks>
Public Type CommonSettings
    'レポートの保存場所
    SaveDir As String
    
    '月次レポートのテンプレート
    TemplateFile As String
    
    'SMTPサーバのFQDN
    SmtpServer As String
    
    'SMTPサーバのポート番号（TCP）
    SmtpPort As Long
    
    '月次レポートをZIPで圧縮する際のパスワード
    'ZipPassword As String
    
    '7-Zipのパス
    SevenZipPath As String
    
    'Thunderbirdのパス
    ThunderbirdPath As String
    
    'Teams内の月次レポート保管場所
    TeamsPath As String
    
    'Box内の月次レポート保管場所
    BoxPath As String
End Type

''' <summary>
''' ツール共通設定(変数)
''' </summary>
''' <remarks></remarks>
Public Settings As CommonSettings

''' <summary>
''' ツール共通設定を読み込む
''' </summary>
''' <remarks></remarks>
Public Sub LoadCommonSettiings()
    With Sheets("ツール共通設定")
        Settings.SaveDir = Trim(.Cells(2, 2).Text)
        Settings.TemplateFile = Trim(.Cells(3, 2).Text)
        Settings.SmtpServer = Trim(.Cells(4, 2).Text)
        Settings.SmtpPort = CLng(Trim(.Cells(5, 2).Text))
        'Settings.ZipPassword = Trim(.Cells(6, 2).Text)
        Settings.SevenZipPath = Trim(.Cells(7, 2).Text)
        Settings.ThunderbirdPath = Trim(.Cells(8, 2).Text)
        Settings.TeamsPath = Trim(.Cells(9, 2).Text)
        Settings.BoxPath = Trim(.Cells(10, 2).Text)
    End With
End Sub

