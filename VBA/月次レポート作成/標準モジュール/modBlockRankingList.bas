Attribute VB_Name = "modBlockRankingList"
Option Explicit

'--------------------------------------------------------------------------------
'
' URLブロックランキング集計用リスト
'
'--------------------------------------------------------------------------------

''' <summary>
''' BlockRanking格納用コレクション
''' キー：ブロック種別＋URL＋CATEGORY
''' 値：BlockRanking
''' </summary>
''' <remarks></remarks>
Private BrList As New Dictionary

''' <summary>
''' リストをクリアする
''' </summary>
''' <remarks></remarks>
Public Sub ClearBrList()
    BrList.RemoveAll
End Sub

''' <summary>
''' リストのデータ個数を取得する
''' </summary>
''' <returns>リストのデータ個数</returns>
''' <remarks></remarks>
Public Function GetBrCount() As Integer
    GetBrCount = BrList.Count
End Function

''' <summary>
''' リストからブロックランキングデータを取得する
''' </summary>
''' <param name="itemIndex">インデックス</param>
''' <returns>ブロックランキングデータ</returns>
''' <remarks></remarks>
Public Function GetBrItem(ByVal itemIndex As Integer) As BlockRanking
    Set GetBrItem = BrList(BrList.Keys(itemIndex))
End Function

''' <summary>
''' ブロックランキングデータをリストに追加する
''' </summary>
''' <param name="blockType">ブロック種別</param>
''' <param name="blockCount">ブロック数</param>
''' <param name="blockUrl">URL</param>
''' <param name="blockCategory">CATEGORY</param>
''' <remarks></remarks>
Public Sub AddBrItem(ByVal blockType As String, ByVal blockCount As Long, ByVal blockUrl As String, ByVal blockCategory As String)
    Dim key As String
    Dim br As New BlockRanking
    
    key = blockType & blockUrl & blockCategory
    br.BType = blockType
    br.Count = blockCount
    br.Url = blockUrl
    br.Category = blockCategory

    'すでに追加済みのデータであればブロック数を加算
    If BrList.Exists(key) Then
        BrList(key).Count = BrList(key).Count + blockCount
    Else
        BrList.Add key, br
    End If
End Sub
