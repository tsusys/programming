Attribute VB_Name = "modCreateReports"
Option Explicit

'--------------------------------------------------------------------------------
'
' 月次レポート作成
'
'--------------------------------------------------------------------------------

''' <summary>
''' テナント毎に月次レポートを作成
''' </summary>
''' <param name="ti">テナント情報</param>
''' <remarks></remarks>
Public Sub CreateMonthlyReport(ByVal ti As TenantInfo)

    Dim fso As New FileSystemObject
    
    Dim reportName As String
    Dim reportDir As String
    
    Dim monReport As Workbook       '月次レポート
    Dim monCover As Worksheet       '表紙
    Dim monTopics As Worksheet      '今月のトピックス
    Dim monAccess As Worksheet      'アクセスサマリ
    Dim monAccessG As Worksheet     'アクセス数&ブロック数推移グラフ
    Dim monBlock As Worksheet       'ブロックランキング
    Dim monBlockTime As Worksheet   'ブロック時間分布
    Dim monBlockTimeG As Worksheet  'ブロック時間分布グラフ
    Dim monBlockAddr As Worksheet   'ブロックアドレス一覧
    Dim monHost As Worksheet        'ホストランキング
    
    Dim weekReport As Workbook      '週次レポート
    Dim weekAccess As Worksheet     'アクセスサマリ
    Dim weekBlockTime As Worksheet  'ブロック時間分布
    Dim weekBlockAddr As Worksheet  'ブロックアドレス一覧
    
    Dim i, j, k As Long
    Dim s, t As String
    Dim d As Date
    Dim ll As LongLong
    
    Dim f As File
    Dim br As BlockRanking
    Dim hr As HostRanking
    Dim gs As GraphScale
    Dim rm As New RowManager
    Dim reportFolderName As String
    Dim cf As String
    Dim cmf As String
    Dim fileExists As Boolean
    Dim fileCount As Integer
    
    Dim onlyCurrentMonth As Boolean
    
    Call ClearBrList
    Call ClearHrList

    Form_Progress.SetTenant ti.CompanyName
    Form_Progress.SetMessage "START " & ti.CompanyName
    
    Form_Progress.SetMessage "　OPEN " & Settings.TemplateFile
    Set monReport = Workbooks.Open(ThisWorkbook.Path & "\" & Settings.TemplateFile, readonly:=True)
    Set monCover = monReport.Sheets("表紙")
    Set monTopics = monReport.Sheets("今月のトピックス")
    Set monAccess = monReport.Sheets("アクセスサマリ")
    Set monAccessG = monReport.Sheets("アクセス数&ブロック数推移グラフ")
    Set monBlock = monReport.Sheets("ブロックランキング")
    Set monBlockTime = monReport.Sheets("ブロック時間分布")
    Set monBlockTimeG = monReport.Sheets("ブロック時間分布グラフ")
    Set monBlockAddr = monReport.Sheets("ブロックアドレス一覧")
    Set monHost = monReport.Sheets("ホストランキング")
    
    Application.Visible = False
    
    reportDir = ti.SaveDir & "\" & Format(DateFrom, "yyyy-mm")
    fileExists = False
    fileCount = 0
    
    '
    ' ここから週次レポートを開いて値をコピー
    '
    
    For Each f In fso.GetFolder(reportDir).Files
        If (Right(f.Name, 4) = ".xls" Or Right(f.Name, 5) = ".xlsx") And f.Name Like "*_Weekly_Detail *.xls*" Then
            fileExists = True
            fileCount = fileCount + 1
            onlyCurrentMonth = IsOnlyCurrentMonth(f.Name)
            
            Form_Progress.SetMessage "　OPEN " & f.Name
            Set weekReport = Workbooks.Open(f.Path, readonly:=True)
            Set weekAccess = weekReport.Sheets("アクセスサマリ")
            Set weekBlockTime = weekReport.Sheets("ブロック時間分布")
            Set weekBlockAddr = weekReport.Sheets("ブロックアドレス一覧")
            
            weekReport.Application.Visible = False
            
            '開いている週次レポートが月またぎでなければ、さきに値全体をコピー
            '少しでも高速化するため、全体コピーと部分コピーとで分割する
            If onlyCurrentMonth Then
                '--------------------
                ' アクセスサマリ(全体コピー)
                '--------------------
                With weekAccess
                    Form_Progress.SetMessage "　　COPY アクセスサマリ(全体コピー)"
                    '月またぎデータがないなら全体コピー
                    k = 0
                    For i = 7 To 13
                        s = .Cells(i, 1).Text
                        If s <> "" And s <> "合計" Then
                            k = i
                        Else
                            Exit For
                        End If
                    Next
                    .Range("A" & 7 & ":" & "E" & k).Copy
                    monAccess.Range(rm.Access.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                End With
            
                '--------------------
                ' ブロック時間分布(全体コピー)
                '--------------------
                Form_Progress.SetMessage "　　COPY ブロック時間分布(全体コピー)"
                With weekBlockTime
                    k = 0
                    For i = 6 To 12
                        s = .Cells(i, 1).Text
                        If s <> "" And s <> "合計" Then
                            k = i
                        Else
                            Exit For
                        End If
                    Next
                    .Range("A" & 6 & ":" & "Y" & k).Copy
                    monBlockTime.Range(rm.BlockTime.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                End With
                
                '--------------------
                ' ブロックアドレス一覧(全体コピー)
                '--------------------
                Form_Progress.SetMessage "　　COPY ブロックアドレス一覧(全体コピー)"
                With weekBlockAddr
                    k = 0
                    For i = 6 To 1000000
                        If i Mod 100 = 0 Then
                            Form_Progress.SetMessage "　　　i = " & i
                        End If
                        s = .Cells(i, 1).Text
                        If s <> "" Then
                            k = i
                        Else
                            Exit For
                        End If
                    Next
                    If k <> 0 Then
                        .Range("A" & 6 & ":" & "F" & k).Copy
                        monBlockAddr.Range(rm.BlockAddr.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                    End If
                End With
            Else
                'そうでなければ日付を評価しながらその月のデータだけをコピー
                
                '--------------------
                ' アクセスサマリ(部分コピー)
                '--------------------
                With weekAccess
                    Form_Progress.SetMessage "　　COPY アクセスサマリ(部分コピー)"
                    '月またぎデータがないなら全体コピー
                    j = 0
                    k = 0
                    For i = 7 To 13
                        s = .Cells(i, 1).Text
                        If s <> "" And s <> "合計" Then
                            d = CDate(Left(s, 10))
                            If DateFrom <= d And d <= DateTo Then
                                If j = 0 Then
                                    j = i
                                End If
                                k = i
                            End If
                        Else
                            Exit For
                        End If
                    Next
                    .Range("A" & j & ":" & "E" & k).Copy
                    monAccess.Range(rm.Access.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                End With
            
                '--------------------
                ' ブロック時間分布(部分コピー)
                '--------------------
                Form_Progress.SetMessage "　　COPY ブロック時間分布(部分コピー)"
                With weekBlockTime
                    j = 0
                    k = 0
                    For i = 6 To 12
                        s = .Cells(i, 1).Text
                        If s <> "" And s <> "合計" Then
                            d = CDate(Left(s, 10))
                            If DateFrom <= d And d <= DateTo Then
                                If j = 0 Then
                                    j = i
                                End If
                                k = i
                            End If
                        Else
                            Exit For
                        End If
                    Next
                    .Range("A" & j & ":" & "Y" & k).Copy
                    monBlockTime.Range(rm.BlockTime.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                End With
                
                '--------------------
                ' ブロックアドレス一覧(部分コピー)
                '--------------------
                Form_Progress.SetMessage "　　COPY ブロックアドレス一覧(部分コピー)"
                With weekBlockAddr
                    j = 0
                    k = 0
                    For i = 6 To 1000000
                        If i Mod 100 = 0 Then
                            Form_Progress.SetMessage "　　　i = " & i
                        End If
                        s = .Cells(i, 1).Text
                        If s <> "" Then
                            d = CDate(Left(s, 10))
                            If DateFrom <= d And d <= DateTo Then
                                If j = 0 Then
                                    j = i
                                End If
                                k = i
                            End If
                        Else
                            Exit For
                        End If
                    Next
                    If k <> 0 Then
                        .Range("A" & j & ":" & "F" & k).Copy
                        monBlockAddr.Range(rm.BlockAddr.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                    End If
                End With
            End If
            
            '--------------------
            ' アクセスサマリ(共通処理)
            '--------------------
            Form_Progress.SetMessage "　　COPY アクセスサマリ(共通処理)"
            With weekAccess
                For i = 7 To 13
                    s = .Cells(i, 1).Text
                    If s <> "" And s <> "合計" Then
                        d = CDate(Left(s, 10))
                        If DateFrom <= d And d <= DateTo Then
                            'If Not onlyCurrentMonth Then
                            '    .Range(.Cells(i, 1), .Cells(i, 5)).Copy
                            'End If
                            With monAccess
                                'If Not onlyCurrentMonth Then
                                '    .Range(rm.Access.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                                'End If
                                
                                '土日祝チェック
                                .Range(rm.Access.CurrentCell("F")).Value = GetHoliday(.Range(rm.Access.CurrentCell("A")))
                                '一日の合計ブロック数
                                .Range(rm.Access.CurrentCell("G")).Value = WorksheetFunction.Sum(.Range(rm.Access.CurrentRange("C", "E")))
                            End With
                            rm.Access.NextRow
                        End If
                    Else
                        Exit For
                    End If
                Next
            End With
            Set weekAccess = Nothing
            
            '--------------------
            ' ブロック時間分布(共通処理)
            '--------------------
            Form_Progress.SetMessage "　　COPY ブロック時間分布(共通処理)"
            With weekBlockTime
                For i = 6 To 12
                    s = .Cells(i, 1).Text
                    If s <> "" And s <> "合計" Then
                        d = CDate(Left(s, 10))
                        If DateFrom <= d And d <= DateTo Then
                            'If Not onlyCurrentMonth Then
                            '    .Range(.Cells(i, 1), .Cells(i, 25)).Copy
                            'End If
                            With monBlockTime
                                'If Not onlyCurrentMonth Then
                                '    .Range(rm.BlockTime.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                                'End If
                                
                                'ブロック時間帯の列挙
                                .Range(rm.BlockTime.CurrentCell("Z")).Formula = "=TEXTJOIN("","",TRUE,FILTER(B$10:H$10, " & rm.BlockTime.CurrentRange("B", "H") & ">0, """")) & TEXTJOIN("","",TRUE,FILTER(X$10:Y$10, " & rm.BlockTime.CurrentRange("X", "Y") & ">0, """"))"
                            End With
                            rm.BlockTime.NextRow
                        End If
                    Else
                        Exit For
                    End If
                Next
            End With
            Set weekBlockTime = Nothing
            
            '--------------------
            ' ブロックアドレス一覧(共通処理)
            '--------------------
            Form_Progress.SetMessage "　　COPY ブロックアドレス一覧(共通処理)"
            With weekBlockAddr
                For i = 6 To 1000000
                    If i Mod 100 = 0 Then
                        Form_Progress.SetMessage "　　　i = " & i
                    End If
                    s = .Cells(i, 1).Text
                    If s <> "" Then
                        d = CDate(Left(s, 10))
                        If DateFrom <= d And d <= DateTo Then
                            'If Not onlyCurrentMonth Then
                            '    .Range(.Cells(i, 1), .Cells(i, 6)).Copy
                            'End If
                            With monBlockAddr
                                'If Not onlyCurrentMonth Then
                                '    .Range(rm.BlockAddr.CurrentCell("A")).PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                                'End If
                            End With
                            
                            '端末ごとのブロック件数
                            AddHrItem .Cells(i, 5).Text, 1
                            
                            'URLごとのブロック件数：
                            AddBrItem .Cells(i, 3).Text, 1, .Cells(i, 2).Text, .Cells(i, 4).Text
                            rm.BlockAddr.NextRow
                        End If
                    Else
                        Exit For
                    End If
                Next
            End With
            Set weekBlockAddr = Nothing
            
            Application.DisplayAlerts = False
            weekReport.Close
            Application.DisplayAlerts = True
            Set weekReport = Nothing
        End If
    Next
    
    If Not fileExists Then
        MsgBox """" & reportDir & """ がありませんが、処理を続行します。", vbExclamation, "月次レポート作成"
    End If
       
    '
    ' ここから月次レポートの各シートを編集
    '
    
    '--------------------
    ' 表紙
    '--------------------
    Form_Progress.SetMessage "　EDIT 月次レポート"
    Form_Progress.SetMessage "　　EDIT 表紙"
    With monCover
        .Range("A15").Value = Replace(.Range("A15").Text, "{{CompanyName}}", ti.CompanyName)
        .Range("A24").Value = Replace(.Range("A24").Text, "{{M}}", Format(DateFrom, "m"))
        .Range("A26").Value = Replace(.Range("A26").Text, "{{yyyy年M月d日}}", Format(DateFrom, "yyyy年m月d日"))
        .Range("A26").Value = Replace(.Range("A26").Text, "{{M月d日}}", Format(DateTo, "m月d日"))
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    '--------------------
    ' アクセスサマリ
    '--------------------
    Form_Progress.SetMessage "　　EDIT アクセスサマリ"
    With monAccess
        .Range("A5").Value = Replace(.Range("A5").Text, "{{yyyy/MM/dd_f}}", Format(DateFrom, "yyyy/mm/dd"))
        .Range("A5").Value = Replace(.Range("A5").Text, "{{yyyy/MM/dd_t}}", Format(DateTo, "yyyy/mm/dd"))
        
        'ひと月が31日ではない場合における空行削除
        Do While .Range(rm.Access.CurrentCell("A")).Text = ""
            .Rows(rm.Access.CurrentRowRange).Delete Shift:=xlUp
        Loop
        
        '合計印字
        .Range(rm.Access.SumCell("B")).Formula = "=SUM(" & rm.Access.ColumnRange("B") & ")"
        .Range(rm.Access.SumCell("C")).Formula = "=SUM(" & rm.Access.ColumnRange("C") & ")"
        .Range(rm.Access.SumCell("D")).Formula = "=SUM(" & rm.Access.ColumnRange("D") & ")"
        .Range(rm.Access.SumCell("E")).Formula = "=SUM(" & rm.Access.ColumnRange("E") & ")"
        '数式を値で上書き
        With .Range(rm.Access.SumRange("B", "E"))
            .Copy
            .PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
        End With
        
        '印刷範囲設定
        .PageSetup.PrintArea = "$A$1:$E$49"
        'フッター印字
        Call PrintFooter(.Range("A49:E49"))
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    '--------------------
    ' アクセス数&ブロック数推移グラフ
    '--------------------
    Form_Progress.SetMessage "　　EDIT アクセス数&ブロック数推移グラフ"
    With monAccessG
        .Range("A5").Value = Replace(.Range("A5").Text, "{{yyyy/MM/dd_f}}", Format(DateFrom, "yyyy/mm/dd"))
        .Range("A5").Value = Replace(.Range("A5").Text, "{{yyyy/MM/dd_t}}", Format(DateTo, "yyyy/mm/dd"))
        
        With .ChartObjects("グラフ 4").Chart
            .ChartTitle.Text = Replace(.ChartTitle.Text, "{{M}}", Format(DateFrom, "m"))
            
            'スケールを変更(左)
            gs = CalcGraphScale(CLngLng(WorksheetFunction.Max(monAccess.Range("B" & rm.Access.First & ":B" & rm.Access.Last))))
            .Axes(xlValue).MaximumScale = gs.MaxumumScale
            .Axes(xlValue).MinimumScale = 0
            .Axes(xlValue).MajorUnit = gs.MajorUnit
            
            'スケールを変更(右)
            gs = CalcGraphScale(WorksheetFunction.Max(monAccess.Range(rm.Access.ColumnRange("G"))))
            .Axes(xlValue, xlSecondary).MaximumScale = gs.MaxumumScale
            .Axes(xlValue, xlSecondary).MinimumScale = 0
            .Axes(xlValue, xlSecondary).MajorUnit = gs.MajorUnit
        End With
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    '--------------------
    ' ブロックアドレス一覧
    '--------------------
    Form_Progress.SetMessage "　　EDIT ブロックアドレス一覧"
    With monBlockAddr
        '書式の適用
        If rm.BlockAddr.HasData Then
            .Range(rm.BlockAddr.FirstRange("A", "F")).Copy
            .Range(rm.BlockAddr.AllRange("A", "F")).PasteSpecial Paste:=xlPasteFormats, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
        End If
        
        '印刷範囲設定
        .PageSetup.PrintArea = rm.BlockAddr.PrintRange("A", "F")
        'フッター印字
        Call PrintFooter(.Range(rm.BlockAddr.FooterRange("A", "F")))
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    '--------------------
    ' ブロックランキング
    '--------------------
    Form_Progress.SetMessage "　　EDIT ブロックランキング"
    With monBlock
        '元データが１週当たりのブロック数なので
        For i = 0 To GetBrCount - 1
            Set br = GetBrItem(i)
            .Range(rm.Block.CurrentCell("A")).Value = br.BType
            .Range(rm.Block.CurrentCell("B")).Value = br.Count
            .Range(rm.Block.CurrentCell("C")).Value = br.Url
            .Range(rm.Block.CurrentCell("D")).Value = br.Category
            rm.Block.NextRow
        Next
        
        '書式の適用
        If rm.Block.HasData Then
            .Range(rm.Block.FirstRange("A", "D")).Copy
            .Range(rm.Block.AllRange("A", "D")).PasteSpecial Paste:=xlPasteFormats, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
        End If
        
        '並び替え
        .Sort.SortFields.Clear
        .Sort.SortFields.Add2 key:=.Range(rm.Block.ColumnRange("B")), SortOn:=xlSortOnValues, Order:=xlDescending, DataOption:=xlSortNormal
        .Sort.SetRange .Range(rm.Block.AllRange("A", "D"))
        .Sort.Header = xlGuess
        .Sort.MatchCase = False
        .Sort.Orientation = xlTopToBottom
        .Sort.SortMethod = xlPinYin
        .Sort.Apply
        
        '上位100件のみとする
        If GetBrCount > 100 Then
            '110まで
            .Range("111:" & (rm.Block.Last)).Delete
            rm.Block.Row = 111
        End If
        
        '印刷範囲設定＆フッター印字
        .PageSetup.PrintArea = rm.Block.PrintRange("A", "D")
        Call PrintFooter(.Range(rm.Block.FooterRange("A", "D")))
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    
    '--------------------
    ' ホストランキング
    '--------------------
    Form_Progress.SetMessage "　　EDIT ホストランキング"
    With monHost
        '元データが１週当たりのブロック数なので
        For i = 0 To GetHrCount - 1
            Set hr = GetHrItem(i)
            .Range(rm.Host.CurrentCell("A")).Value = hr.Count
            .Range(rm.Host.CurrentCell("B")).Value = hr.Host
            rm.Host.NextRow
        Next
        
        '書式の適用
        If rm.Host.HasData Then
            .Range(rm.Host.FirstRange("A", "B")).Copy
            .Range(rm.Host.AllRange("A", "B")).PasteSpecial Paste:=xlPasteFormats, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
        End If
        
        '並び替え
        .Sort.SortFields.Clear
        .Sort.SortFields.Add2 key:=.Range(rm.Host.ColumnRange("A")), SortOn:=xlSortOnValues, Order:=xlDescending, DataOption:=xlSortNormal
        .Sort.SetRange .Range(rm.Host.AllRange("A", "B"))
        .Sort.Header = xlGuess
        .Sort.MatchCase = False
        .Sort.Orientation = xlTopToBottom
        .Sort.SortMethod = xlPinYin
        .Sort.Apply
        
        '印刷範囲設定＆フッター印字
        .PageSetup.PrintArea = rm.Block.PrintRange("A", "D")
        Call PrintFooter(.Range(rm.Block.FooterRange("A", "D")))
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    '--------------------
    ' ブロック時間分布
    '--------------------
    Form_Progress.SetMessage "　　EDIT ブロック時間分布"
    With monBlockTime
        '.Select
        '空行削除
        Do While .Range(rm.BlockTime.CurrentCell("A")).Text = ""
            .Rows(rm.BlockTime.CurrentRowRange).Delete Shift:=xlUp
        Loop
        
        '合計印字
        .Range(rm.BlockTime.SumCell("B")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("B") & ")"
        .Range(rm.BlockTime.SumCell("C")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("C") & ")"
        .Range(rm.BlockTime.SumCell("D")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("D") & ")"
        .Range(rm.BlockTime.SumCell("E")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("E") & ")"
        .Range(rm.BlockTime.SumCell("F")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("F") & ")"
        .Range(rm.BlockTime.SumCell("G")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("G") & ")"
        .Range(rm.BlockTime.SumCell("H")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("H") & ")"
        .Range(rm.BlockTime.SumCell("I")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("I") & ")"
        .Range(rm.BlockTime.SumCell("J")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("J") & ")"
        .Range(rm.BlockTime.SumCell("K")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("K") & ")"
        .Range(rm.BlockTime.SumCell("L")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("L") & ")"
        .Range(rm.BlockTime.SumCell("M")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("M") & ")"
        .Range(rm.BlockTime.SumCell("N")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("N") & ")"
        .Range(rm.BlockTime.SumCell("O")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("O") & ")"
        .Range(rm.BlockTime.SumCell("P")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("P") & ")"
        .Range(rm.BlockTime.SumCell("Q")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("Q") & ")"
        .Range(rm.BlockTime.SumCell("R")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("R") & ")"
        .Range(rm.BlockTime.SumCell("S")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("S") & ")"
        .Range(rm.BlockTime.SumCell("T")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("T") & ")"
        .Range(rm.BlockTime.SumCell("U")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("U") & ")"
        .Range(rm.BlockTime.SumCell("V")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("V") & ")"
        .Range(rm.BlockTime.SumCell("W")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("W") & ")"
        .Range(rm.BlockTime.SumCell("X")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("X") & ")"
        .Range(rm.BlockTime.SumCell("Y")).Formula = "=SUM(" & rm.BlockTime.ColumnRange("Y") & ")"
        '数式を値で上書き
        With .Range(rm.BlockTime.SumRange("B", "Y"))
            .Copy
            .PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
        End With
        
        '印刷範囲設定
        .PageSetup.PrintArea = rm.BlockTime.PrintRange("A", "Y")
        'フッター印字
        Call PrintFooter(.Range(rm.BlockTime.FooterRange("A", "Y")))
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    '--------------------
    ' ブロック時間分布グラフ
    '--------------------
    Form_Progress.SetMessage "　　EDIT ブロック時間分布グラフ"
    With monBlockTimeG
        'スケールを変更：合計行の最大値から算出
        With .ChartObjects("グラフ 1").Chart
            gs = CalcGraphScale(CLngLng(WorksheetFunction.Max(monBlockTime.Range(rm.BlockTime.SumRange("B", "Y")))))
            .Axes(xlValue).MaximumScale = gs.MaxumumScale
            .Axes(xlValue).MinimumScale = 0
            .Axes(xlValue).MajorUnit = gs.MajorUnit
            For i = 31 To 1 Step -1
                If .FullSeriesCollection(i).Name = "" Or .FullSeriesCollection(i).Name = "合計" Then
                    .FullSeriesCollection(i).Delete
                Else
                    Exit For
                End If
            Next
        End With
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
    
    '--------------------
    ' 今月のトピックス
    '--------------------
    Form_Progress.SetMessage "　　EDIT 今月のトピックス"
    With monTopics
        
        If rm.Block.Last < rm.Block.First Then 'ブロックデータなし
            Sheet1.Cells(ti.Row, 1).Value = fileCount
            .Range(rm.Topics.CurrentCell("A")).Value = "今月のトピックスは特にございません。"
            rm.Topics.NextRow
            rm.Topics.NextRow
            
        Else 'ブロックデータあり
            Sheet1.Cells(ti.Row, 1).Value = "◎"
            .Range(rm.Topics.CurrentCell("A")).Value = "今月のブロックの傾向は以下のとおりとなります。"
            rm.Topics.NextRow
            rm.Topics.NextRow
            
            '
            ' １．ブロックランキング
            '
            Form_Progress.SetMessage "　　EDIT 今月のトピックス - １．ブロックランキング"
            .Range(rm.Topics.CurrentCell("A")).Value = "１．ブロックランキング"
            rm.Topics.NextRow
            
            
            '
            ' (1) 通信先URL 上位3件
            '
            .Range(rm.Topics.CurrentCell("A")).Value = "(1) 通信先URL 上位3件"
            rm.Topics.NextRow
            
            s = ""
            For i = (rm.Block.First - 1) To (rm.Block.First + 10)
                monBlock.Range(monBlock.Cells(i, 2), monBlock.Cells(i, 4)).Copy
                
                .Range(rm.Topics.CurrentCell("B")).PasteSpecial Paste:=xlPasteAll, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                .Range(rm.Topics.CurrentCell("C")).WrapText = False
                .Range(rm.Topics.CurrentCell("D")).WrapText = False
                rm.Topics.NextRow
                
                s = monBlock.Cells(i, 2).Text
                t = monBlock.Cells(i + 1, 2).Text
                If t = "" Then
                    Exit For
                ElseIf i >= rm.Block.First + 2 Then '上位3件まで処理をしたい
                    If s <> t Then
                        'カウント数が変わったとみなして、ループをとめる
                        Exit For
                    End If
                End If
                
            Next
            rm.Topics.NextRow
            
            
            '
            ' (2) 通信元端末 上位3件
            '
            .Range(rm.Topics.CurrentCell("A")).Value = "(2) 通信元端末 上位3件"
            rm.Topics.NextRow
            
            s = ""
            For i = (rm.Host.First - 1) To (rm.Host.First + 10)
                monHost.Range(monHost.Cells(i, 1), monHost.Cells(i, 2)).Copy
                
                .Range(rm.Topics.CurrentCell("B")).PasteSpecial Paste:=xlPasteAll, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
                rm.Topics.NextRow
                
                s = monHost.Cells(i, 1).Text
                t = monHost.Cells(i + 1, 1).Text
                If t = "" Then
                    Exit For
                ElseIf i >= rm.Host.First + 2 Then '上位3件まで処理をしたい
                    If s <> t Then
                        'カウント数が変わったとみなして、ループをとめる
                        Exit For
                    End If
                End If
            Next
            .Range(rm.Topics.CurrentCell("B")).Value = "※Agentモジュール未導入の環境では、ホスト名が『-』になります。"
            rm.Topics.NextRow
            rm.Topics.NextRow
            
            '
            ' ２．日別のブロック状況
            '
            Form_Progress.SetMessage "　　EDIT 今月のトピックス - ２．日別のブロック状況"
            .Range(rm.Topics.CurrentCell("A")).Value = "２．日別のブロック状況"
            rm.Topics.NextRow
            
            ''monAccessG.ChartObjects("グラフ 4").Chart.ChartArea.Copy
            'monAccessG.ChartObjects("グラフ 4").CopyPicture xlScreen, xlBitmap
            'DoEvents '次のPasteでエラーが発生することがあるため
            '.Pictures.Paste
            Call CopyChart(monAccessG.ChartObjects("グラフ 4"), monTopics)
            .Shapes(1).ScaleHeight 0.5, msoFalse, msoScaleFromTopLeft
            .Shapes(1).Top = .Range(rm.Topics.CurrentCell("B")).Top
            .Shapes(1).Left = .Range(rm.Topics.CurrentCell("B")).Left
            'Call MoveShape(monTopics, 1, rm)
            For i = 1 To 13
                rm.Topics.NextRow
            Next
            rm.Topics.NextRow '文字が見切れることがあり、さらに1行追加
            
            .Range(rm.Topics.CurrentCell("B")).Value = "・今月、ファイルのブロックは " & monAccess.Range(rm.Access.SumCell("D")) & " 件でした。"
            rm.Topics.NextRow
            
            ll = WorksheetFunction.SumIf(monAccess.Range(rm.Access.ColumnRange("F")), "休", monAccess.Range(rm.Access.ColumnRange("G"))) 'F列が"休"の部分だけ、G列を合計
            .Range(rm.Topics.CurrentCell("B")).Value = "・土日祝日のブロックは " & ll & " 件でした。"
            rm.Topics.NextRow
            If ll > 0 Then
                'ブロック日
                .Range(rm.Topics.CurrentCell("B")).Value = "　対象日："
                s = ""
                For i = rm.Access.First To rm.Access.Last
                    If monAccess.Cells(i, 6).Text = "休" And monAccess.Cells(i, 7).Value > 0 Then
                        If s = "" Then
                            s = Mid(monAccess.Cells(i, 1).Text, 6, 5)
                        Else
                            s = s & ", " & Mid(monAccess.Cells(i, 1).Text, 6, 5)
                        End If
                    End If
                Next
                .Range(rm.Topics.CurrentCell("C")).Value = "'" & Replace(s, "-", "/")
                rm.Topics.NextRow
            End If
            rm.Topics.NextRow
            
            
            '
            ' ３．時間帯別のブロック状況
            '
            Form_Progress.SetMessage "　　EDIT 今月のトピックス - ３．時間帯別のブロック状況"
            .Range(rm.Topics.CurrentCell("A")).Value = "３．時間帯別のブロック状況"
            rm.Topics.NextRow
            
            ''monBlockTimeG.ChartObjects("グラフ 1").Chart.ChartArea.Copy
            'monBlockTimeG.ChartObjects("グラフ 1").CopyPicture xlScreen, xlBitmap
            'DoEvents '次のPasteでエラーが発生することがあるため
            '.Pictures.Paste
            Call CopyChart(monAccessG.ChartObjects("グラフ 4"), monTopics)
            .Shapes(2).ScaleHeight 0.5, msoFalse, msoScaleFromTopLeft
            .Shapes(2).Top = .Range(rm.Topics.CurrentCell("B")).Top
            .Shapes(2).Left = .Range(rm.Topics.CurrentCell("B")).Left
            'Call MoveShape(monTopics, 2, rm)
            For i = 1 To 13
                rm.Topics.NextRow
            Next
            rm.Topics.NextRow '文字が見切れることがあり、さらに1行追加
            
            ll = WorksheetFunction.Sum(monBlockTime.Range(rm.BlockTime.SumRange("B", "H"))) + WorksheetFunction.Sum(monBlockTime.Range(rm.BlockTime.SumRange("X", "Y")))
            .Range(rm.Topics.CurrentCell("B")).Value = "・22時から7時までのブロックは " & ll & " 件でした。"
            rm.Topics.NextRow
            
            If ll > 0 Then
                'ブロック日
                .Range(rm.Topics.CurrentCell("B")).Value = "　対象日："
                s = ""
                For i = rm.BlockTime.First To rm.BlockTime.Last
                    t = monBlockTime.Cells(i, 26).Text
                    If t <> "" Then
                        If s = "" Then
                            s = Mid(monBlockTime.Cells(i, 1).Text, 6, 5)
                        Else
                            s = s & ", " & Mid(monBlockTime.Cells(i, 1).Text, 6, 5)
                        End If
                        If Len(s) >= 75 Then
                            .Range(rm.Topics.CurrentCell("C")).Value = "'" & Replace(s, "-", "/")
                            s = ""
                            rm.Topics.NextRow
                        End If
                    End If
                Next
                If s <> "" Then
                    .Range(rm.Topics.CurrentCell("C")).Value = "'" & Replace(s, "-", "/")
                    rm.Topics.NextRow
                End If
            End If
        End If
        
        '印刷範囲設定
        .PageSetup.PrintArea = rm.Topics.PrintRange("A", "D")
        'フッター印字
        Call PrintFooter(.Range(rm.Topics.FooterRange("A", "D")))
        'セル位置
        Call SelectA1(.Range("A1"))
    End With
            
    Form_Progress.SetMessage "　DELETE TEMPORARY DATA"
    
    '集計用列(アクセスサマリF列/G列、ブロック時間分布Z列)を消す
    monAccess.Range(rm.Access.ColumnRange("F")).ClearContents
    monAccess.Range(rm.Access.ColumnRange("G")).ClearContents
    monBlockTime.Range(rm.BlockTime.ColumnRange("Z")).ClearContents
    
    'ホストランキングを消す
    Application.DisplayAlerts = False
    monHost.Delete
    Application.DisplayAlerts = True

    '表紙を選択
    monCover.Activate '.Selectを使うとエラーになる
    
    Form_Progress.SetMessage "　SAVE REPORT"
    
    'ファイルを保存
    reportName = Replace(Replace(Settings.TemplateFile, "{{CompanyName}}", ti.CompanyName), "{{yyyyMM}}", Format(DateFrom, "yyyymm"))
    monReport.SaveCopyAs reportDir & "\" & reportName
    monReport.Close saveChanges:=False
        
    'Teams内にコピーを保存
    If Settings.TeamsPath <> "" Then
        If Not fso.FolderExists(Settings.TeamsPath & "\" & ti.CompanyName) Then
            fso.CreateFolder Settings.TeamsPath & "\" & ti.CompanyName
        End If
        fso.CopyFile reportDir & "\" & reportName, Settings.TeamsPath & "\" & ti.CompanyName & "\" & reportName, True
    End If
    
    'Boxに空のフォルダを作成
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
    End If
    
    Application.Visible = True
    
End Sub

''' <summary>
''' A1セルを選択する
''' </summary>
''' <param name="r">A1セル</param>
''' <remarks></remarks>
Private Sub SelectA1(ByRef r As Range)
    r.Copy 'Excel非表示の場合は.Selectを使うとエラーになるので、やむを得ず.Copy ⇒ .PasteSpecialとしている
    r.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks:=False, Transpose:=False
End Sub

''' <summary>
''' フッターを印字する
''' </summary>
''' <param name="r">フッターを印字するセル</param>
''' <remarks></remarks>
Private Sub PrintFooter(ByRef r As Range)
    r.Merge
    With r.Interior
        .Pattern = xlPatternLinearGradient
        .Gradient.Degree = 0
        .Gradient.ColorStops.Clear
    End With
    With r.Interior.Gradient.ColorStops.Add(0)
        .ThemeColor = xlThemeColorDark1
        .TintAndShade = 0
    End With
    With r.Interior.Gradient.ColorStops.Add(1)
        .ThemeColor = xlThemeColorAccent2
        .TintAndShade = -0.250984221930601
    End With
End Sub

''' <summary>
''' グラフをコピーし、シートに貼り付ける
''' </summary>
''' <param name="copyFrom">チャート</param>
''' <param name="copyTo">シート</param>
''' <remarks></remarks>
Private Sub CopyChart(ByRef copyFrom As ChartObject, ByRef copyTo As Worksheet)
On Error GoTo Err_CopyChart

    Dim tryCount As Integer
    Dim shapeCount As Integer
    tryCount = 0
    shapeCount = copyTo.Shapes.Count

Try_CopyChart:
    tryCount = tryCount + 1

    DoEvents
    copyFrom.CopyPicture xlScreen, xlBitmap
    DoEvents '次のPasteでエラーが発生することがあるため
    copyTo.Paste
    
    'Pasteができていない(Shapeが増えていない)場合は、再実行
    DoEvents
    If copyTo.Shapes.Count = shapeCount Then
        GoTo Try_CopyChart
    End If
    
    Exit Sub
    
Err_CopyChart:
    If tryCount > 0 Then
        Debug.Print "tryCount(copy) :" & tryCount & vbCrLf & "Err.Number: " & Err.Number & vbCrLf & "Err.Description: " & Err.Description
    End If
    If tryCount >= 5 Then
        Err.Raise Err.Number, Err.Source, Err.Description, Err.HelpFile, Err.HelpContext
    Else
        GoTo Try_CopyChart
    End If
End Sub

'''' <summary>
'''' グラフ画像を調整する
'''' </summary>
'''' <param name="ws">シート</param>
'''' <param name="shapeIndex">参照したいShapesのインデックス</param>
'''' <param name="rm">RowManager</param>
'''' <remarks></remarks>
'Private Sub MoveShape(ByRef ws As Worksheet, ByVal shapeIndex As Integer, ByRef rm As RowManager)
'On Error GoTo Try_MoveShape
'
'    Dim tryCount As Integer
'    tryCount = 0
'
'Try_MoveShape:
'    If tryCount > 0 Then
'        Debug.Print "tryCount(move) :" & tryCount & vbCrLf & "Err.Number: " & Err.Number & vbCrLf & "Err.Description: " & Err.Description
'    End If
'    tryCount = tryCount + 1
'    If tryCount >= 5 Then
'        Err.Raise Err.Number, Err.Source, Err.Description, Err.HelpFile, Err.HelpContext
'    End If
'
'    DoEvents
'    With ws
'        .Shapes(shapeIndex).ScaleHeight 0.48, msoFalse, msoScaleFromTopLeft
'        .Shapes(shapeIndex).Top = .Range(rm.Topics.CurrentCell("B")).Top
'        .Shapes(shapeIndex).Left = .Range(rm.Topics.CurrentCell("B")).Left
'    End With
'
'End Sub

''' <summary>
''' 週次レポートのファイル名から月またぎデータでないことを判定する
''' </summary>
''' <param name="fname">週次レポート</param>
''' <returns>月またぎデータでないならTrue</returns>
''' <remarks></remarks>
Private Function IsOnlyCurrentMonth(ByVal fname As String) As Boolean
    '例えば "ja_2025-08-11_Weekly_Detail (04-10).xls" ならば st="04", ed="10"
    Dim st As String
    Dim ed As String
    IsOnlyCurrentMonth = False
    st = Mid(fname, 30, 2)
    ed = Mid(fname, 33, 2)
    If IsNumeric(st) And IsNumeric(ed) Then
        If CInt(st) <= CInt(ed) Then
            IsOnlyCurrentMonth = True
        End If
    End If
End Function
