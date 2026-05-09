Attribute VB_Name = "modHoliday"
Option Explicit

'--------------------------------------------------------------------------------
'
' ‹x“úŠÇ—
'
'--------------------------------------------------------------------------------

''' <summary>
''' ‹xj“úƒŠƒXƒg
''' </summary>
''' <remarks></remarks>
Private holidays As Dictionary

''' <summary>
''' ‹xj“ú‚ğ”»’è‚·‚é
''' </summary>
''' <param name="r">“ú•t•¶š—ñ‚ğŠÜ‚ŞƒZƒ‹i“ú•t•¶š—ñ‚Ì—áF"2024-10-07@Œ"j</param>
''' <returns>“y“új‚Ìê‡A"‹x"</returns>
''' <remarks></remarks>
Public Function GetHoliday(ByRef r As Range) As String
    Dim d As String 'r‚Ì“ú•t•”•ª
    Dim wd As String 'r‚Ì—j“ú•”•ª
    Dim h As String
    Dim tmp As String
    
    If r.Text = "" Then
        GetHoliday = ""
        Exit Function
    Else
        d = Left(r.Text, 10)
        wd = Right(r.Text, 1)
    End If
    
    Select Case wd
        Case "Œ", "‰Î", "…", "–Ø", "‹à"
            tmp = ""
        Case "“y", "“ú"
            tmp = "‹x"
        Case Else
            tmp = ""
    End Select
    
    h = holidays(d)
    If h <> "" Then
        tmp = "‹x"
    End If
    
    GetHoliday = tmp
    
End Function

''' <summary>
''' ‹xj“úİ’è‚ğ“Ç‚İ‚Ş
''' </summary>
''' <remarks></remarks>
Public Sub LoadHolidays()
    Dim i As Integer
    Dim d As String
    Dim s As String
    
    Set holidays = New Dictionary
    With Sheets("‹xj“úİ’è")
        For i = 3 To 1000
            d = .Range("A" & i).Text
            If d = "" Then
                Exit For
            Else
                d = Format(CDate(.Range("A" & i).Text), "yyyy-mm-dd")
                s = .Range("B" & i).Text
                holidays.Add d, s
            End If
        Next
    End With
End Sub
