#requires -version 5.1

# 1. 高解像度（DPI）対応 ＋ 黒い画面（コンソール）を非表示にする
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDpiAwarenessContext(IntPtr dpiContext);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
[void][WinAPI]::SetProcessDpiAwarenessContext([IntPtr](-4))
[void][WinAPI]::ShowWindow([WinAPI]::GetConsoleWindow(), 0)

# 2. Forms や Drawing の読み込み
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "launcher.json"

if (-not (Test-Path $configPath)) {
  [System.Windows.Forms.MessageBox]::Show("設定ファイルが見つかりません: $configPath")
  exit 1
}

$config = Get-Content -Raw -Encoding UTF8 $configPath | ConvertFrom-Json

# 設定値の取得（デフォルト値付き）
$settings = $config.settings
$formWidth  = if ($settings.width)      { $settings.width }      else { 520 }
$formHeight = if ($settings.height)     { $settings.height }     else { 420 }
$fontName   = if ($settings.fontName)   { $settings.fontName }   else { "Yu Gothic UI" }
$fontSize   = if ($settings.fontSize)   { $settings.fontSize }   else { 10 }
$itemHeight = if ($settings.itemHeight) { $settings.itemHeight } else { 32 }
$position   = if ($settings.position)   { $settings.position }   else { "center" }
$posX       = $settings.x
$posY       = $settings.y

$font = New-Object System.Drawing.Font($fontName, $fontSize)

# フォーム作成
$form = New-Object System.Windows.Forms.Form
$form.Text = "ランチャー"
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.Font = $font


# 表示位置の設定
switch ($position) {
  "manual" {
    if ($null -ne $posX -and $null -ne $posY) {
      $form.StartPosition = "Manual"
      $form.Location = New-Object System.Drawing.Point($posX, $posY)
    } else {
      $form.StartPosition = "CenterScreen"
    }
  }
  "topLeft" {
    $form.StartPosition = "Manual"
    $form.Location = New-Object System.Drawing.Point(0, 0)
  }
  "topRight" {
    $form.StartPosition = "Manual"
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Location = New-Object System.Drawing.Point(($screen.Width - $formWidth), 0)
  }
  "bottomLeft" {
    $form.StartPosition = "Manual"
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Location = New-Object System.Drawing.Point(0, ($screen.Height - $formHeight))
  }
  "bottomRight" {
    $form.StartPosition = "Manual"
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Location = New-Object System.Drawing.Point(($screen.Width - $formWidth), ($screen.Height - $formHeight))
  }
  default {
    $form.StartPosition = "CenterScreen"
  }
}

# タブコントロール
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = "Fill"

# 項目を開く処理（フォルダ or プログラム）
$openAction = {
  param($listBox)
  $sel = $listBox.SelectedItem
  if ($null -eq $sel) { return }

  $p = [Environment]::ExpandEnvironmentVariables([string]$sel.path)
  $selArgs = if ($sel.args) { [Environment]::ExpandEnvironmentVariables([string]$sel.args) } else { $null }

  try {
    # フォルダ or シェル特殊フォルダの場合は explorer.exe で開く
    $isFolder = (Test-Path $p -PathType Container) -or ($p -like "shell:*")
    
    if ($isFolder) {
      Start-Process explorer.exe -ArgumentList $p
    } elseif ($selArgs) {
      Start-Process $p -ArgumentList $selArgs
    } else {
      Start-Process $p
    }
  } catch {
    [System.Windows.Forms.MessageBox]::Show("開けませんでした: $p`n$($_.Exception.Message)")
  }
}

# カテゴリごとにタブを作成（settingsキーはスキップ）
foreach ($category in $config.PSObject.Properties) {
  if ($category.Name -eq "settings") { continue }

  $tabPage = New-Object System.Windows.Forms.TabPage
  $tabPage.Text = $category.Name

  $list = New-Object System.Windows.Forms.ListBox
  $list.Dock = "Fill"
  $list.DisplayMember = "name"
  $list.DrawMode = "OwnerDrawFixed"
  $list.ItemHeight = $itemHeight

  # オーナードロー描画（パネル風）
  $list.Add_DrawItem({
    param($sender, $e)
    if ($e.Index -lt 0) { return }

    # 文字をくっきり綺麗に描く（ClearType描画）
    $e.Graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    # 背景描画
    if (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -ne 0) {
      $e.Graphics.FillRectangle([System.Drawing.SystemBrushes]::Highlight, $e.Bounds)
    } else {
      $e.Graphics.FillRectangle([System.Drawing.SystemBrushes]::Window, $e.Bounds)
    }

    # 下線を描画（境界線）
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::LightGray, 1)
    $y = $e.Bounds.Bottom - 1
    $e.Graphics.DrawLine($pen, $e.Bounds.Left, $y, $e.Bounds.Right, $y)
    $pen.Dispose()

    # テキスト描画
    $item = $sender.Items[$e.Index]
    $text = if ($item.name) { $item.name } else { $item.ToString() }
    
    if (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -ne 0) {
      $brush = [System.Drawing.SystemBrushes]::HighlightText
    } else {
      $brush = [System.Drawing.SystemBrushes]::WindowText
    }
    
    $sf = New-Object System.Drawing.StringFormat
    $sf.LineAlignment = "Center"
    $textRect = [System.Drawing.RectangleF]::new($e.Bounds.X + 8, $e.Bounds.Y, $e.Bounds.Width - 16, $e.Bounds.Height)
    $e.Graphics.DrawString($text, $e.Font, $brush, $textRect, $sf)

    $e.DrawFocusRectangle()
    $sf.Dispose()
  })

  foreach ($it in $category.Value) {
    if ($null -ne $it.name -and $null -ne $it.path) {
      [void]$list.Items.Add($it)
    }
  }

  $list.Add_DoubleClick({ $openAction.Invoke($this) })

  $tabPage.Controls.Add($list)
  $tabControl.TabPages.Add($tabPage)
}

$form.Controls.Add($tabControl)
[void]$form.ShowDialog()
