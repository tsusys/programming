Attribute VB_Name = "modTenantInfoList"
Option Explicit

'--------------------------------------------------------------------------------
'
' テナント設定
'
'--------------------------------------------------------------------------------

''' <summary>
''' TenantInfo格納用コレクション
''' </summary>
''' <remarks></remarks>
Private TiList As Collection

''' <summary>
''' テナント数を取得する
''' </summary>
''' <returns>テナント数</returns>
''' <remarks></remarks>
Public Function GetTenantCount() As Integer
    GetTenantCount = TiList.Count
End Function

''' <summary>
''' テナント設定を読み込む
''' </summary>
''' <returns>TenantInfo格納用コレクション</returns>
''' <remarks></remarks>
Public Function GetTenantInfoList() As Collection
    Dim i As Integer
    Dim ti As TenantInfo
    
    Set TiList = New Collection
    With Sheets("月次レポート作成")
        
        For i = 10 To 1000
            If .Cells(i, 2) <> "" Then
                Set ti = New TenantInfo
                ti.CompanyName = Trim(.Cells(i, 2).Text)
                ti.ProxyServer = Trim(.Cells(i, 3).Text)
                ti.NodeId = Trim(.Cells(i, 4).Text)
                ti.PortalCd = Trim(.Cells(i, 5).Text)
                ti.Lang = Trim(.Cells(i, 6).Text)
                ti.SshKey = Trim(.Cells(i, 7).Text)
                ti.BoxUrl = Trim(.Cells(i, 8).Text)
                ti.ZipPassword = Trim(.Cells(i, 9).Text)
                ti.mailTo = Trim(.Cells(i, 10).Text)
                ti.PM = Trim(.Cells(i, 11).Text)
                ti.First = Trim(.Cells(i, 12).Text)
                ti.Sent = Trim(.Cells(i, 13).Text)
                ti.Row = i
                TiList.Add ti
            Else
                Exit For
            End If
        Next
    End With
    
    Set GetTenantInfoList = TiList
End Function

''' <summary>
''' テナント設定に含まれる処理状況をリセットする
''' 具体的には、[Box URL]をクリアし、[Sent]をFalseにする
''' </summary>
''' <remarks></remarks>
Public Sub ResetStatus()
    Dim i As Integer
    
    Set TiList = Nothing
    
    With Sheets("月次レポート作成")
        For i = 10 To 1000
            If .Cells(i, 2) <> "" Then
                .Cells(i, 1).Value = "" 'Topicsあり
                .Cells(i, 8).Value = "" 'Box URL
                .Cells(i, 13).Value = False 'Sent
            Else
                Exit For
            End If
        Next
    End With
End Sub
