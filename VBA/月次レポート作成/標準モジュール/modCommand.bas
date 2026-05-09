Attribute VB_Name = "modCommand"
Option Explicit

'--------------------------------------------------------------------------------
'
' コマンド実行
'
'--------------------------------------------------------------------------------

''' <summary>
''' コマンドを実行する
''' </summary>
''' <param name="cmd">コマンド</param>
''' <remarks></remarks>
Public Sub RunCommand(ByVal cmd As String)
    Dim wsh As New IWshRuntimeLibrary.WshShell
    
    wsh.Run cmd, 1, True
End Sub

''' <summary>
''' PowerShellを実行する
''' </summary>
''' <param name="cmd">コマンド</param>
''' <remarks></remarks>
Public Sub RunPowerShell(ByVal cmd As String)
    Dim wsh As New IWshRuntimeLibrary.WshShell
    
    wsh.Run "powershell -NoLogo -ExecutionPolicy RemoteSigned -Command """ & cmd & """", 1, True
End Sub

''' <summary>
''' PowerShellを実行して、実行結果を取得する
''' </summary>
''' <param name="cmd">コマンド</param>
''' <returns>実行結果</returns>
''' <remarks></remarks>
Public Function ExecPowerShell(ByVal cmd As String)
    Dim wsh As New IWshRuntimeLibrary.WshShell
    Dim obj As Object
    Dim result As String
    
    Set obj = wsh.Exec("powershell -NoLogo -ExecutionPolicy RemoteSigned -Command """ & cmd & """")
    result = obj.StdOut.ReadAll
    
    ExecPowerShell = result
End Function

