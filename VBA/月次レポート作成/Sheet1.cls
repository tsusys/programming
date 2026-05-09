VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sheet1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit

'--------------------------------------------------------------------------------
'
' 月次レポート作成シート
'
'--------------------------------------------------------------------------------

''' <summary>
''' [1. 週次レポート取得] クリック
''' </summary>
''' <remarks></remarks>
Private Sub GetWeeklyReportsButton_Click()

    Dim ti As TenantInfo
    Dim cmd As String
    
    'ツール共通設定読込み
    Call LoadCommonSettiings
    
    'テナント設定読込み
    For Each ti In GetTenantInfoList
        Sheet1.Cells(ti.Row, 2).Select
        '処理は外部(PowerShell)で実施
        cmd = ThisWorkbook.Path & "\GetWeeklyReports.ps1 " _
            & ti.ProxyServer & " " & ti.NodeId & " " & ti.PortalCd & " " & ti.Lang & " " & ti.SshKey & " " & ti.SaveDir
        Call RunPowerShell(cmd)
    Next
    
    MsgBox "終了しました。", vbInformation, "月次レポート作成"
    
End Sub

''' <summary>
''' [2. 月次レポート作成] クリック
''' </summary>
''' <remarks></remarks>
Private Sub CreateMonthlyReportsButton_Click()
On Error GoTo Err_CreateMonthlyReportsButton_Click

    Dim ti As TenantInfo
    Dim startTimer As Double    '開始時間
    
    'ツール共通設定読込み
    Call LoadCommonSettiings
    
    MsgBox "月次レポート作成を開始します。" & vbCrLf & _
           "しばらくExcelがちらついたり、非表示になります。" & vbCrLf & _
           "処理が終了したら、Excel画面を再表示します。", vbInformation, "月次レポート作成"
    startTimer = Timer
    
    '処理状況表示
    Load Form_Progress
    Form_Progress.Show vbModeless
    
    '作成対象月
    Call SetTargetDate
    
    '休日設定読み込み
    Call LoadHolidays
    
    'テナント設定読込み
    For Each ti In GetTenantInfoList
        Sheet1.Cells(ti.Row, 2).Select
        'テナント毎に月次レポートを作成
        Call CreateMonthlyReport(ti)
        ThisWorkbook.Save
        
        DoEvents
        Application.Wait [Now] + 1000 / 86400000
        DoEvents
    Next
    
    ThisWorkbook.Save
    
    '処理状況非表示
    Unload Form_Progress
    
    MsgBox "終了しました。" & (Timer - startTimer), vbInformation, "月次レポート作成"
    
    Exit Sub
    
Err_CreateMonthlyReportsButton_Click:
    Application.Visible = True
    
    MsgBox "エラーが発生しました。" & vbCrLf & _
           "進捗表示画面は×で閉じてください。" & vbCrLf & _
           Err.Number & ":" & vbCrLf & _
           Err.Description & vbCrLf & _
           Err.Source & vbCrLf & _
           "処理時間(s): " & (Timer - startTimer), vbCritical, "月次レポート作成"
    
    ThisWorkbook.Save
           
End Sub

''' <summary>
''' [3. 月次レポート アップロード] クリック
''' </summary>
''' <remarks></remarks>
Private Sub UploadMonthlyReportsButton_Click()

    Dim ti As TenantInfo
    Dim reportDir As String 'レポートフォルダ
    Dim xlsFile As String   'Excelファイル名
    Dim zipFile As String   'Zipファイル名
    Dim reportFolderName As String
    Dim cmd As String
    Dim fso As New FileSystemObject
    Dim cf As String
    Dim cmf As String
    Dim result As String
    
    'ツール共通設定読込み
    Call LoadCommonSettiings
    
    '作成対象月
    Call SetTargetDate
    
    'BoxAPI アクセストークン取得
    cmd = ThisWorkbook.Path & "\GetAccessToken.ps1"
    Call RunPowerShell(cmd)
    
    'テナント設定読込み
    For Each ti In GetTenantInfoList
        Sheet1.Cells(ti.Row, 2).Select
        If Cells(ti.Row, 8).Text = "" Then
            reportDir = ti.SaveDir & "\" & Format(DateFrom, "yyyy-mm")
            xlsFile = Replace(Replace(Settings.TemplateFile, "{{CompanyName}}", ti.CompanyName), "{{yyyyMM}}", Format(DateFrom, "yyyymm"))
            zipFile = Replace(xlsFile, ".xlsx", ".zip")
            
            'ファイル圧縮
            cmd = """" & Settings.SevenZipPath & """ a -p" & ti.ZipPassword _
                & " """ & reportDir & "\" & zipFile & """" _
                & " """ & reportDir & "\" & xlsFile & """"
            Call RunCommand(cmd)
            
            'Box内にファイルをアップロード
            If Settings.BoxPath <> "" Then
                cf = Settings.BoxPath & "\" & ti.CompanyName & "様"
                If Not fso.FolderExists(cf) Then
                    fso.CreateFolder cf
                End If
                reportFolderName = ti.CompanyName & "様 月次レポート " & Format(DateFrom, "yyyy年m月")
                cmf = cf & "\" & reportFolderName
                If Not fso.FolderExists(cmf) Then
                    fso.CreateFolder cmf
                End If
                fso.CopyFile reportDir & "\" & zipFile, cmf & "\" & zipFile, True
            
                '共有リンクを作成
                cmd = ThisWorkbook.Path & "\GetSharedLink.ps1 """"" & reportFolderName & """"""
                result = ExecPowerShell(cmd)
                result = Trim(Replace(result, vbCrLf, ""))
                If result <> "" Then
                    Cells(ti.Row, 8).Value = result
                End If
            End If
        End If
    Next
End Sub

''' <summary>
''' [4. 月次レポート メール送信] クリック
''' </summary>
''' <remarks></remarks>
Private Sub SendMailMonthlyReportsButton_Click()

    Dim ti As TenantInfo
    
    'ツール共通設定読込み
    Call LoadCommonSettiings
    
    '作成対象月
    Call SetTargetDate
    
    'テナント設定読込み
    For Each ti In GetTenantInfoList
        Sheet1.Cells(ti.Row, 2).Select
        If Not ti.Sent Then 'メールを送っていない場合のみ
            Call CreateReportMail(ti)
            Sheet1.Cells(ti.Row, 12) = False 'FirstをFalseにする
            Sheet1.Cells(ti.Row, 13) = True 'SentをTrueにする
            MsgBox "続けるにはOKを押してください。", vbInformation, "月次レポート作成"
        End If
    Next
    
    MsgBox "終了しました。", vbInformation, "月次レポート作成"
    
    'Call CreateMail("t.wada@mbsd.jp", "tateki.wada.mbsd.jp@gmail.com; t.wada@websec.jp", "test sub", "body" & vbCrLf & "body2")
    
End Sub

''' <summary>
''' [0. 処理状況リセット] クリック
''' </summary>
''' <remarks></remarks>
Private Sub ResetButton_Click()
    
    'ツール共通設定読込み
    Call LoadCommonSettiings
    '処理状況をリセットする
    Call ResetStatus
    
End Sub
