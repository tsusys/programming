Attribute VB_Name = "modCreateMail"
Option Explicit

'--------------------------------------------------------------------------------
'
' メール作成
'
'--------------------------------------------------------------------------------

''' <summary>
''' Thunderbirdでメールを作成
''' </summary>
''' <param name="mailTo">To</param>
''' <param name="mailCc">Cc</param>
''' <param name="mailBcc">Bcc</param>
''' <param name="subject">件名</param>
''' <param name="body">本文</param>
''' <remarks></remarks>
Public Sub CreateMail(ByVal mailTo As String, ByVal mailCc As String, ByVal mailBcc As String, ByVal subject As String, ByVal body As String)
    Shell """" & Settings.ThunderbirdPath & """ -compose " _
        & "to=" & mailTo & "," _
        & "cc=" & mailCc & "," _
        & "bcc=" & mailBcc & "," _
        & "subject=" & subject & "," _
        & "body=" & body
End Sub

''' <summary>
''' テナント毎に月次レポートメールを作成
''' </summary>
''' <param name="ti">テナント情報</param>
''' <remarks></remarks>
Public Sub CreateReportMail(ByVal ti As TenantInfo)

    Dim mailTemplate As Worksheet
    Dim mailTo As String
    Dim mailCc As String
    Dim mailBcc As String
    Dim subject As String
    Dim body As String
    'MailFromにはThunderbirdにて設定しているものを使用する
    
    If ti.First Then
        '初回の月次レポート送信の場合
        Set mailTemplate = Sheet5
    Else
        '２回目以降の月次レポート送信の場合
        Set mailTemplate = Sheet4
    End If
    
    mailTo = mailTemplate.Range("B4").Text
    mailTo = Replace(mailTo, "{{to}}", ti.mailTo)
    
    mailCc = mailTemplate.Range("B5").Text
    mailCc = Replace(mailCc, "{{pm}}", ti.PM)
    
    mailBcc = mailTemplate.Range("B6").Text
    
    subject = mailTemplate.Range("B2").Text
    subject = Replace(subject, "{{CompanyName}}", ti.CompanyName)
    subject = Replace(subject, "{{yyyy年m月}}", Format(DateFrom, "yyyy年m月"))
    
    body = mailTemplate.Range("B7").Text
    body = Replace(body, "{{CompanyName}}", ti.CompanyName)
    body = Replace(body, "{{yyyy年m月}}", Format(DateFrom, "yyyy年m月"))
    body = Replace(body, "{{yyyy年m月d日}}", Format(DateFrom, "yyyy年m月d日"))
    body = Replace(body, "{{m月d日}}", Format(DateTo, "m月d日"))
    body = Replace(body, "{{box_url}}", ti.BoxUrl)
    body = Replace(body, "{{yyyy/m/d(aaa)}}", Format(DateSerial(Year(Now), Month(Now) + 1, 0), "yyyy/m/d(aaa)")) '公開期間には今月末を設定
    
    Call CreateMail(mailTo, mailCc, mailBcc, subject, body)
    
    '初回の場合はパスワード通知メールも作成する
    If ti.First Then
        Set mailTemplate = Sheet8
    
        mailTo = mailTemplate.Range("B4").Text
        mailTo = Replace(mailTo, "{{to}}", ti.mailTo)
        
        mailCc = mailTemplate.Range("B5").Text
        mailCc = Replace(mailCc, "{{pm}}", ti.PM)
    
        mailBcc = mailTemplate.Range("B6").Text
        
        subject = mailTemplate.Range("B2").Text
        subject = Replace(subject, "{{CompanyName}}", ti.CompanyName)
        subject = Replace(subject, "{{yyyy年m月}}", Format(DateFrom, "yyyy年m月"))
        
        body = mailTemplate.Range("B7").Text
        body = Replace(body, "{{CompanyName}}", ti.CompanyName)
        body = Replace(body, "{{pw}}", ti.ZipPassword)
        
        Call CreateMail(mailTo, mailCc, mailBcc, subject, body)
    End If

End Sub
