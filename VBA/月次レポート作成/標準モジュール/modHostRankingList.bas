Attribute VB_Name = "modHostRankingList"
Option Explicit

'--------------------------------------------------------------------------------
'
' 端末ブロックランキング集計用リスト
'
'--------------------------------------------------------------------------------

''' <summary>
''' HostRanking格納用コレクション
''' キー：Host
''' 値：HostRanking
''' </summary>
''' <remarks></remarks>
Private HrList As New Dictionary

''' <summary>
''' リストをクリアする
''' </summary>
''' <remarks></remarks>
Public Sub ClearHrList()
    HrList.RemoveAll
End Sub

''' <summary>
''' リストのデータ個数を取得する
''' </summary>
''' <returns>リストのデータ個数</returns>
''' <remarks></remarks>
Public Function GetHrCount() As Integer
    GetHrCount = HrList.Count
End Function

''' <summary>
''' リストから端末ブロックランキングデータを取得する
''' </summary>
''' <param name="itemIndex">インデックス</param>
''' <returns></returns>
''' <remarks></remarks>
Public Function GetHrItem(ByVal itemIndex As Integer) As HostRanking
    Set GetHrItem = HrList(HrList.Keys(itemIndex))
End Function

''' <summary>
''' 端末ブロックランキングデータをリストに追加する
''' </summary>
''' <param name="blockHost">ホスト名を含む文字列（例：”"SAMPLE-PC.SAMPLE-PC;msedge.exe"）</param>
''' <param name="blockCount">ブロック数</param>
''' <remarks></remarks>
Public Sub AddHrItem(ByVal blockHost As String, ByVal blockCount As Long)
    Dim h As String
    Dim key As String
    Dim hr As New HostRanking
    
    h = GetHostName(blockHost)
    
    key = h
    hr.Host = h
    hr.Count = blockCount

    'すでに追加済みのデータであればブロック数を加算
    If HrList.Exists(key) Then
        HrList(key).Count = HrList(key).Count + blockCount
    Else
        HrList.Add key, hr
    End If
End Sub

''' <summary>
''' ホスト名を取得する
''' </summary>
''' <param name="blockHost">ホスト名を含む文字列（例：”"SAMPLE-PC.SAMPLE-PC;msedge.exe"）</param>
''' <returns>ホスト名</returns>
''' <remarks></remarks>
Private Function GetHostName(ByVal blockHost As String) As String
    Dim i As Integer
    Dim h As String
    i = InStr(1, blockHost, ";")
    If i = 0 Then
        h = blockHost
    Else
        h = Left(blockHost, i - 1)
    End If
    GetHostName = h
End Function
