VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "RowManagerPerSheet"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'--------------------------------------------------------------------------------
'
' 月次レポート各シートの参照行管理
'
'--------------------------------------------------------------------------------

''' <summary>
''' 現在の参照行
''' </summary>
''' <remarks></remarks>
Public Row As Long

''' <summary>
''' 最初のデータ行
''' </summary>
''' <remarks></remarks>
Public First As Long

''' <summary>
''' Initialize
''' </summary>
''' <param name="FirstRow">最初のデータ行</param>
''' <remarks></remarks>
Public Sub Initialize(Optional ByVal FirstRow As Long = 11)
    First = FirstRow
    Row = First
End Sub

''' <summary>
''' ヘッダー行を取得する
''' </summary>
''' <returns>ヘッダー行</returns>
''' <remarks></remarks>
Public Property Get Header() As Long
    Header = First - 1
End Property

''' <summary>
''' 最後のデータ行を取得する
''' </summary>
''' <returns>最後のデータ行</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Property Get Last() As Long
    Last = Row - 1
End Property

''' <summary>
''' 合計行を取得する
''' </summary>
''' <returns>合計行</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Private Property Get SumRow() As Long
    SumRow = Row
End Property

''' <summary>
''' フッター行を取得する
''' </summary>
''' <returns>フッター行</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Private Property Get FooterRow() As Long
    If Row <= 48 Then
        FooterRow = 49
    Else
        FooterRow = Row + 1
    End If
End Property

''' <summary>
''' データがあるか
''' </summary>
''' <returns>データがある場合はTrue</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Property Get HasData() As Boolean
    HasData = (Row > First)
End Property

''' <summary>
''' 次の行へと参照行を移動する
''' </summary>
''' <remarks></remarks>
Public Sub NextRow()
    Row = Row + 1
End Sub

''' <summary>
''' 現在の参照行のセル番地を取得する
''' </summary>
''' <param name="Column">カラム（例："B"）</param>
''' <returns>セル番地（例："B11"）</returns>
''' <remarks></remarks>
Public Function CurrentCell(ByVal Column As String) As String
    CurrentCell = Column & Row
End Function

''' <summary>
''' 合計行のセル番地を取得する
''' </summary>
''' <param name="Column">カラム（例："B"）</param>
''' <returns>セル番地（例："B11"）</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Function SumCell(ByVal Column As String) As String
    SumCell = Column & SumRow
End Function

''' <summary>
''' 最初の行のセル番地(範囲)を取得する
''' </summary>
''' <param name="ColumnFrom">範囲の最初のカラム（例："A"）</param>
''' <param name="ColumnTo">範囲の最後のカラム（例："D"）</param>
''' <returns>セル番地(範囲)（例："A11:D11"）</returns>
''' <remarks></remarks>
Public Function FirstRange(ByVal ColumnFrom As String, ByVal ColumnTo As String) As String
    FirstRange = ColumnFrom & First & ":" & ColumnTo & First
End Function

''' <summary>
''' 現在の参照行のセル番地(範囲)を取得する
''' </summary>
''' <param name="ColumnFrom">範囲の最初のカラム（例："A"）</param>
''' <param name="ColumnTo">範囲の最後のカラム（例："D"）</param>
''' <returns>セル番地(範囲)（例："A11:D11"）</returns>
''' <remarks></remarks>
Public Function CurrentRange(ByVal ColumnFrom As String, ByVal ColumnTo As String) As String
    CurrentRange = ColumnFrom & Row & ":" & ColumnTo & Row
End Function

''' <summary>
''' 現在の参照行全体のセル番地(範囲)を取得する
''' </summary>
''' <returns>セル番地(範囲)（例："11:11"）</returns>
''' <remarks></remarks>
Public Function CurrentRowRange() As String
    CurrentRowRange = Row & ":" & Row
End Function

''' <summary>
''' 特定列のデータ全体のセル番地(範囲)を取得する
''' </summary>
''' <param name="Column">カラム（例："B"）</param>
''' <returns>セル番地(範囲)（例："B11:B40"）</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Function ColumnRange(ByVal Column As String) As String
    ColumnRange = Column & First & ":" & Column & Last
End Function

''' <summary>
''' データ全体のセル番地(範囲)を取得する
''' </summary>
''' <param name="ColumnFrom">範囲の最初のカラム（例："A"）</param>
''' <param name="ColumnTo">範囲の最後のカラム（例："D"）</param>
''' <returns>セル番地(範囲)（例："A11:D40"）</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Function AllRange(ByVal ColumnFrom As String, ByVal ColumnTo As String) As String
    AllRange = ColumnFrom & First & ":" & ColumnTo & Last
End Function

''' <summary>
''' ヘッダ＋データ上位３件のセル番地(範囲)を取得する
''' </summary>
''' <param name="ColumnFrom">範囲の最初のカラム（例："A"）</param>
''' <param name="ColumnTo">範囲の最後のカラム（例："D"）</param>
''' <returns>セル番地(範囲)（例："A10:D13"）</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Function AllRangeWithHeaderLimit3(ByVal ColumnFrom As String, ByVal ColumnTo As String) As String
    If Last > First + 2 Then
        '上位3行だけコピー
        AllRangeWithHeaderLimit3 = ColumnFrom & Header & ":" & ColumnTo & (First + 2)
    Else
        AllRangeWithHeaderLimit3 = ColumnFrom & Header & ":" & ColumnTo & Last
    End If
End Function

''' <summary>
''' '合計行のセル番地(範囲)を取得する
''' </summary>
''' <param name="ColumnFrom">範囲の最初のカラム（例："B"）</param>
''' <param name="ColumnTo">範囲の最後のカラム（例："D"）</param>
''' <returns>セル番地(範囲)（例："B41:D41"）</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Function SumRange(ByVal ColumnFrom As String, ByVal ColumnTo As String) As String
    SumRange = ColumnFrom & SumRow & ":" & ColumnTo & SumRow
End Function

''' <summary>
''' 印刷範囲のセル番地(範囲)を取得する
''' </summary>
''' <param name="ColumnFrom">範囲の最初のカラム（例："A"）</param>
''' <param name="ColumnTo">範囲の最後のカラム（例："D"）</param>
''' <returns>セル番地(範囲)（例："A10:D49"）</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Function PrintRange(ByVal ColumnFrom As String, ByVal ColumnTo As String) As String
    PrintRange = "$" & ColumnFrom & "$1:$" & ColumnTo & "$" & FooterRow
End Function

''' <summary>
''' フッターのセル番地(範囲)を取得する
''' </summary>
''' <param name="ColumnFrom">範囲の最初のカラム（例："A"）</param>
''' <param name="ColumnTo">範囲の最後のカラム（例："D"）</param>
''' <returns>セル番地(範囲)（例："A49:D49"）</returns>
''' <remarks>データを最後(空白行)まで読み取って、初めて正しいデータとなる</remarks>
Public Function FooterRange(ByVal ColumnFrom As String, ByVal ColumnTo As String) As String
    FooterRange = ColumnFrom & FooterRow & ":" & ColumnTo & FooterRow
End Function
