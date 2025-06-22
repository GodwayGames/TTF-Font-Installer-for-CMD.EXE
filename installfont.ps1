# Requires admin privileges
$fontName = "Envy Code R"
$fontFile = "Envy Code R.ttf"
$fontRegistryName = "EnvyCode"  # Registry-safe alias
$consoleFontIndexBaseKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont"
$powerShellConsoleKey = Join-Path "HKCU:\Console" `
    ((($env:SystemRoot -replace ":", "").Replace("\", "_") + "_System32_WindowsPowerShell_v1.0_powershell.exe"))

# Full path to font file in script's directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$fontPath = Join-Path $scriptDir $fontFile

# Step 1: Copy font to Fonts folder
$fontsDir = "$env:WINDIR\Fonts"
$targetFontPath = Join-Path $fontsDir $fontFile

if (!(Test-Path $targetFontPath)) {
    Copy-Item -Path $fontPath -Destination $targetFontPath
    Write-Host "Font file copied to Fonts directory."
}

# Step 2: Install the font (add registry entry under Fonts key)
$fontsRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
$fontEntryName = "$fontName (TrueType)"
Set-ItemProperty -Path $fontsRegPath -Name $fontEntryName -Value $fontFile
Write-Host "Font registered in Windows Fonts registry."

# Step 3: Add to Console TrueType fonts
$existingKeys = (Get-ItemProperty $consoleFontIndexBaseKey).PSObject.Properties |
    Where-Object { $_.Name -match '^0+$' }
$nextIndex = '0' * ($existingKeys.Count + 1)
New-ItemProperty -Path $consoleFontIndexBaseKey -Name $nextIndex -PropertyType String -Value $fontName -Force
Write-Host "Console font '$fontName' registered under $nextIndex."

# Step 4: Apply to PowerShell console settings (current user)
if (!(Test-Path $powerShellConsoleKey)) {
    New-Item -Path $powerShellConsoleKey -Force | Out-Null
}

New-ItemProperty -Path $powerShellConsoleKey -Name "FaceName" -PropertyType String -Value $fontName -Force
New-ItemProperty -Path $powerShellConsoleKey -Name "FontFamily" -PropertyType DWORD -Value 0x00000036 -Force
New-ItemProperty -Path $powerShellConsoleKey -Name "FontSize" -PropertyType DWORD -Value 0x00100000 -Force  # 16pt
New-ItemProperty -Path $powerShellConsoleKey -Name "FontWeight" -PropertyType DWORD -Value 0x00000190 -Force

Write-Host "`n '$fontName' installed and applied to PowerShell console."
Write-Host "You may need to restart PowerShell or reboot to see the effect."
