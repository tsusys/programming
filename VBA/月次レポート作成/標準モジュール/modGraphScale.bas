Attribute VB_Name = "modGraphScale"
Option Explicit

'--------------------------------------------------------------------------------
'
' グラフのスケール算出
'
'--------------------------------------------------------------------------------

''' <summary>
''' グラフのスケールと目盛り
''' </summary>
''' <remarks></remarks>
Public Type GraphScale
    MaxumumScale As LongLong
    MajorUnit As LongLong
End Type

''' <summary>
''' データの最大値を使ってグラフのスケールを算出する
''' </summary>
''' <param name="maxValue">データの最大値</param>
''' <returns></returns>
''' <remarks></remarks>
Public Function CalcGraphScale(ByVal maxValue As LongLong) As GraphScale
    Dim gs As GraphScale

    Dim valueDigits As Integer
    Dim power As LongLong
    
    '最大値の桁数取得
    valueDigits = Len(CStr(maxValue))
    
    Select Case valueDigits
        Case 1  '1桁のとき
            'MaxumumScaleとMajorUnitを決定
            If maxValue < 5 Then
                gs.MaxumumScale = 5
                gs.MajorUnit = 1
            Else
                gs.MaxumumScale = 10
                gs.MajorUnit = 2
            End If
        Case Else '2桁以上のとき
            '桁数に応じて10の累乗倍して、MaxumumScaleとMajorUnitを決定
            power = 10 ^ (valueDigits - 2)
            If maxValue < 15 * power Then
                gs.MaxumumScale = 15 * power
                gs.MajorUnit = 3 * power
            ElseIf maxValue < 20 * power Then
                gs.MaxumumScale = 20 * power
                gs.MajorUnit = 5 * power
            ElseIf maxValue < 30 * power Then
                gs.MaxumumScale = 30 * power
                gs.MajorUnit = 5 * power
            ElseIf maxValue < 50 * power Then
                gs.MaxumumScale = 50 * power
                gs.MajorUnit = 10 * power
            ElseIf maxValue < 80 * power Then
                gs.MaxumumScale = 80 * power
                gs.MajorUnit = 15 * power
            Else
                gs.MaxumumScale = 100 * power
                gs.MajorUnit = 20 * power
            End If
    End Select
    
    CalcGraphScale = gs
End Function

