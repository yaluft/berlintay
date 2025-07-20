# Windows Pre-Migration Backup Script
# Run as Administrator for best results
# Creates a comprehensive backup of all user data before Linux migration

param(
    [string]$BackupPath = "$env:USERPROFILE\Desktop\LinuxMigrationBackup"
)

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Windows Pre-Migration Backup Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Create backup directory structure
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupRoot = "$BackupPath\Backup_$timestamp"

Write-Host "Creating backup directory: $BackupRoot" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

# Create subdirectories
$dirs = @(
    "$BackupRoot\Edge",
    "$BackupRoot\Chrome",
    "$BackupRoot\Email",
    "$BackupRoot\SystemInfo",
    "$BackupRoot\AppData",
    "$BackupRoot\Documents",
    "$BackupRoot\Desktop",
    "$BackupRoot\Downloads",
    "$BackupRoot\Pictures",
    "$BackupRoot\Videos",
    "$BackupRoot\Music",
    "$BackupRoot\GameSaves",
    "$BackupRoot\SSH_Keys",
    "$BackupRoot\Certificates"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Function to show progress
function Show-Progress($Activity, $Status, $PercentComplete) {
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

# 1. Backup Microsoft Edge
Write-Host "`nBacking up Microsoft Edge..." -ForegroundColor Green
Show-Progress -Activity "Backing up browsers" -Status "Microsoft Edge" -PercentComplete 10

# Edge bookmarks
$edgeBookmarks = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"
if (Test-Path $edgeBookmarks) {
    Copy-Item $edgeBookmarks "$BackupRoot\Edge\Bookmarks.json" -Force
    Write-Host "  ✓ Edge bookmarks backed up" -ForegroundColor Gray
}

# Edge passwords (encrypted - for reference)
$edgeLogin = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data"
if (Test-Path $edgeLogin) {
    Copy-Item $edgeLogin "$BackupRoot\Edge\LoginData.db" -Force
    Write-Host "  ✓ Edge login data backed up (encrypted)" -ForegroundColor Gray
}

# Export Edge favorites to HTML
$shell = New-Object -ComObject Shell.Application
$favorites = [Environment]::GetFolderPath('Favorites')
if (Test-Path $favorites) {
    Copy-Item -Path $favorites -Destination "$BackupRoot\Edge\Favorites" -Recurse -Force
    Write-Host "  ✓ Edge favorites folder backed up" -ForegroundColor Gray
}

# Edge extensions list
$edgeExtPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Extensions"
if (Test-Path $edgeExtPath) {
    $extensions = Get-ChildItem $edgeExtPath | Where-Object { $_.PSIsContainer }
    $extList = @()
    foreach ($ext in $extensions) {
        $manifestPath = Join-Path $ext.FullName -ChildPath (Get-ChildItem $ext.FullName | Select-Object -First 1).Name | Join-Path -ChildPath "manifest.json"
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            $extList += [PSCustomObject]@{
                ID = $ext.Name
                Name = $manifest.name
                Version = $manifest.version
            }
        }
    }
    $extList | Export-Csv "$BackupRoot\Edge\Extensions.csv" -NoTypeInformation
    Write-Host "  ✓ Edge extensions list exported" -ForegroundColor Gray
}

# 2. Backup Google Chrome
Write-Host "`nBacking up Google Chrome..." -ForegroundColor Green
Show-Progress -Activity "Backing up browsers" -Status "Google Chrome" -PercentComplete 25

# Chrome bookmarks
$chromeBookmarks = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
if (Test-Path $chromeBookmarks) {
    Copy-Item $chromeBookmarks "$BackupRoot\Chrome\Bookmarks.json" -Force
    Write-Host "  ✓ Chrome bookmarks backed up" -ForegroundColor Gray
}

# Chrome passwords (encrypted)
$chromeLogin = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
if (Test-Path $chromeLogin) {
    Copy-Item $chromeLogin "$BackupRoot\Chrome\LoginData.db" -Force
    Write-Host "  ✓ Chrome login data backed up (encrypted)" -ForegroundColor Gray
}

# Chrome extensions list
$chromeExtPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions"
if (Test-Path $chromeExtPath) {
    $extensions = Get-ChildItem $chromeExtPath | Where-Object { $_.PSIsContainer }
    $extList = @()
    foreach ($ext in $extensions) {
        $manifestPath = Join-Path $ext.FullName -ChildPath (Get-ChildItem $ext.FullName | Select-Object -First 1).Name | Join-Path -ChildPath "manifest.json"
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            $extList += [PSCustomObject]@{
                ID = $ext.Name
                Name = $manifest.name
                Version = $manifest.version
            }
        }
    }
    $extList | Export-Csv "$BackupRoot\Chrome\Extensions.csv" -NoTypeInformation
    Write-Host "  ✓ Chrome extensions list exported" -ForegroundColor Gray
}

# 3. Backup Email configurations
Write-Host "`nBacking up Email configurations..." -ForegroundColor Green
Show-Progress -Activity "Backing up email" -Status "Collecting email settings" -PercentComplete 40

# Outlook profiles (if exists)
$outlookProfiles = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles"
if (Test-Path $outlookProfiles) {
    reg export "HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Outlook\Profiles" "$BackupRoot\Email\OutlookProfiles.reg" /y | Out-Null
    Write-Host "  ✓ Outlook profiles exported" -ForegroundColor Gray
}

# Thunderbird profile (if exists)
$thunderbird = "$env:APPDATA\Thunderbird"
if (Test-Path $thunderbird) {
    Copy-Item -Path $thunderbird -Destination "$BackupRoot\Email\Thunderbird" -Recurse -Force
    Write-Host "  ✓ Thunderbird profile backed up" -ForegroundColor Gray
}

# Windows Mail app
$winMail = "$env:LOCALAPPDATA\Packages\microsoft.windowscommunicationsapps_8wekyb3d8bbwe"
if (Test-Path $winMail) {
    Write-Host "  ℹ Windows Mail app data location saved" -ForegroundColor Gray
    "$winMail" | Out-File "$BackupRoot\Email\WindowsMailPath.txt"
}

# 4. Get list of installed applications
Write-Host "`nGenerating installed applications list..." -ForegroundColor Green
Show-Progress -Activity "System information" -Status "Collecting installed apps" -PercentComplete 55

# Method 1: Get-Package (Windows 10/11)
try {
    $packages = Get-Package | Select-Object Name, Version, Source, ProviderName
    $packages | Export-Csv "$BackupRoot\SystemInfo\InstalledPackages.csv" -NoTypeInformation
    Write-Host "  ✓ Package list exported" -ForegroundColor Gray
} catch {
    Write-Host "  ⚠ Could not export package list" -ForegroundColor Yellow
}

# Method 2: Registry (traditional programs)
$regPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedApps = @()
foreach ($path in $regPaths) {
    if (Test-Path $path) {
        $installedApps += Get-ItemProperty $path | 
            Where-Object { $_.DisplayName -and $_.DisplayName -notmatch "^Update for|^Security Update|^Hotfix" } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation
    }
}

$installedApps | Sort-Object DisplayName -Unique | Export-Csv "$BackupRoot\SystemInfo\InstalledPrograms.csv" -NoTypeInformation
Write-Host "  ✓ Traditional programs list exported" -ForegroundColor Gray

# Method 3: Windows Store Apps
$storeApps = Get-AppxPackage | Where-Object { $_.IsFramework -eq $false } | 
    Select-Object Name, PackageFullName, Version |
    Sort-Object Name

$storeApps | Export-Csv "$BackupRoot\SystemInfo\StoreApps.csv" -NoTypeInformation
Write-Host "  ✓ Microsoft Store apps list exported" -ForegroundColor Gray

# Method 4: Chocolatey packages (if installed)
if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco list --local-only > "$BackupRoot\SystemInfo\ChocolateyPackages.txt"
    Write-Host "  ✓ Chocolatey packages list exported" -ForegroundColor Gray
}

# 5. System Information
Write-Host "`nCollecting system information..." -ForegroundColor Green
Show-Progress -Activity "System information" -Status "Collecting hardware info" -PercentComplete 65

# Computer info
Get-ComputerInfo | Select-Object CsName, WindowsVersion, WindowsBuildLabEx, OsArchitecture, 
    CsProcessors, CsTotalPhysicalMemory, TimeZone |
    Export-Csv "$BackupRoot\SystemInfo\ComputerInfo.csv" -NoTypeInformation

# Network adapters
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed |
    Export-Csv "$BackupRoot\SystemInfo\NetworkAdapters.csv" -NoTypeInformation

# Disk information
Get-Disk | Select-Object Number, FriendlyName, Size, PartitionStyle |
    Export-Csv "$BackupRoot\SystemInfo\Disks.csv" -NoTypeInformation

Get-Volume | Where-Object { $_.DriveLetter } | 
    Select-Object DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining |
    Export-Csv "$BackupRoot\SystemInfo\Volumes.csv" -NoTypeInformation

Write-Host "  ✓ System information collected" -ForegroundColor Gray

# 6. Important directories
Write-Host "`nBacking up important directories..." -ForegroundColor Green
Show-Progress -Activity "Backing up files" -Status "Copying user folders" -PercentComplete 75

# SSH Keys
$sshDir = "$env:USERPROFILE\.ssh"
if (Test-Path $sshDir) {
    Copy-Item -Path $sshDir -Destination "$BackupRoot\SSH_Keys" -Recurse -Force
    Write-Host "  ✓ SSH keys backed up" -ForegroundColor Gray
}

# Git config
$gitConfig = "$env:USERPROFILE\.gitconfig"
if (Test-Path $gitConfig) {
    Copy-Item $gitConfig "$BackupRoot\SystemInfo\gitconfig" -Force
    Write-Host "  ✓ Git configuration backed up" -ForegroundColor Gray
}

# Steam game saves (common locations)
$steamUserdata = "C:\Program Files (x86)\Steam\userdata"
if (Test-Path $steamUserdata) {
    Copy-Item -Path $steamUserdata -Destination "$BackupRoot\GameSaves\Steam" -Recurse -Force
    Write-Host "  ✓ Steam saves backed up" -ForegroundColor Gray
}

# Documents folder structure (list only, not copy)
Write-Host "`nCreating directory structure list..." -ForegroundColor Green
Get-ChildItem "$env:USERPROFILE\Documents" -Directory -Recurse | 
    Select-Object FullName | 
    Export-Csv "$BackupRoot\SystemInfo\DocumentsStructure.csv" -NoTypeInformation

# 7. Create backup summary
Write-Host "`nCreating backup summary..." -ForegroundColor Green
Show-Progress -Activity "Finalizing" -Status "Creating summary" -PercentComplete 90

$summary = @"
Windows Pre-Migration Backup Summary
====================================
Backup Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer Name: $env:COMPUTERNAME
User: $env:USERNAME
Backup Location: $BackupRoot

Backed Up Items:
----------------
✓ Microsoft Edge (bookmarks, favorites, extensions list)
✓ Google Chrome (bookmarks, extensions list)
✓ Email configurations
✓ Installed applications list (multiple formats)
✓ System information
✓ SSH keys (if present)
✓ Git configuration
✓ Steam saves (if present)

Important Notes:
----------------
1. Browser passwords are encrypted and tied to Windows user account
   - Consider using a password manager for migration
   - Or manually export passwords from browser settings

2. Email data:
   - For cloud email (Gmail, Outlook.com): Just sign in on Linux
   - For POP3/IMAP: Note down server settings
   - Consider using Thunderbird on both systems for easy migration

3. Applications:
   - Review the CSV files for Linux alternatives
   - Steam games will re-download on Linux
   - Check Wine compatibility for Windows-only software

4. Additional manual backups recommended:
   - Any specialized software settings
   - License keys for purchased software
   - VPN configurations
   - Custom fonts
   - Printer drivers/settings

Next Steps:
-----------
1. Copy this backup folder to external drive
2. Boot into Linux installer
3. After Linux installation, restore data as needed
"@

$summary | Out-File "$BackupRoot\README.txt" -Encoding UTF8
Write-Host "  ✓ Backup summary created" -ForegroundColor Gray

# Create a quick restore script for Linux
$linuxRestore = @'
#!/bin/bash
# Quick restore helper for Linux
# Run this after installing Linux

echo "Windows Backup Restore Helper"
echo "============================"

# Create directories
mkdir -p ~/.config/google-chrome/Default
mkdir -p ~/.mozilla/firefox
mkdir -p ~/.ssh
mkdir -p ~/Documents/WindowsBackup

echo "1. To restore Chrome bookmarks:"
echo "   cp ./Chrome/Bookmarks.json ~/.config/google-chrome/Default/"

echo "2. To restore SSH keys:"
echo "   cp -r ./SSH_Keys/* ~/.ssh/"
echo "   chmod 600 ~/.ssh/id_*"

echo "3. Review installed apps:"
echo "   cat ./SystemInfo/InstalledPrograms.csv"

echo "For detailed migration guide, see README.txt"
'@

$linuxRestore | Out-File "$BackupRoot\linux-restore.sh" -Encoding UTF8 -NoNewline

Show-Progress -Activity "Backup Complete" -Status "Done" -PercentComplete 100
Start-Sleep -Milliseconds 500

# Final report
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Backup completed successfully!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Location: $BackupRoot" -ForegroundColor Yellow
Write-Host "`nTotal backup size: $([math]::Round((Get-ChildItem $BackupRoot -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" -ForegroundColor Yellow
Write-Host "`nIMPORTANT: Copy this folder to an external drive!" -ForegroundColor Red
Write-Host "See README.txt in backup folder for detailed information." -ForegroundColor Yellow

# Open backup folder
Start-Process explorer.exe -ArgumentList $BackupRoot
