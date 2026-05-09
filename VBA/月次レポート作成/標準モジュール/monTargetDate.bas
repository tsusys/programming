Attribute VB_Name = "monTargetDate"
Option Explicit

'--------------------------------------------------------------------------------
'
' 作成対象月
'
'--------------------------------------------------------------------------------

''' <summary>
''' 対象日(From)
''' </summary>
''' <remarks></remarks>
Public DateFrom As Date

''' <summary>
''' 対象日(To)
''' </summary>
''' <remarks></remarks>
Public DateTo As Date

''' <summary>
''' 作成対象月(前月)を設定する
''' </summary>
''' <remarks>現時点では対象月は指定せずに、前月を自動設定している</remarks>
Public Sub SetTargetDate()
    DateFrom = DateSerial(Year(Now), Month(Now) - 1, 1)
    DateTo = DateSerial(Year(Now), Month(Now), 1) - 1
End Sub
