VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BlockRanking"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'--------------------------------------------------------------------------------
'
' URLブロックランキング集計用
'
'--------------------------------------------------------------------------------

''' <summary>
''' ブロック種別
''' </summary>
''' <remarks></remarks>
Public BType As String

''' <summary>
''' ブロック数
''' </summary>
''' <remarks></remarks>
Public Count As Long

''' <summary>
''' URL
''' </summary>
''' <remarks></remarks>
Public Url As String

''' <summary>
'''CATEGORY
''' </summary>
''' <remarks></remarks>
Public Category As String

