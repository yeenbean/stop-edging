@echo off
:: edge removal scripts are derived from https://privacy.sexy.


:: check for admin privileges and elevate if needed.
fltmc >nul 2>&1 || (
    echo Administrator privileges are required.
    PowerShell Start -Verb RunAs '%0' 2> nul || (
        echo Right-click on the script and select "Run as administrator".
        pause & exit 1
    )
    exit 0
)


:: disclaimer
echo This script is designed to remove the Microsoft Edge browser from your
echo computer. Be aware that this script makes changes to the Windows operating
echo system that may potentially break certain features. Use this script at your own
echo risk.
echo.
echo In addition to removing Edge, this script will optionally install Firefox. If
echo you do not want to use Firefox, you may want to download your browser of choice
echo before running this script. Please note that if you choose not to install
echo Firefox with this script or another web browser before running the script, you
echo will be left without a web browser.

pause


:: Initialize environment
setlocal EnableExtensions DisableDelayedExpansion


:: remove edge using the official installer
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev" /v "AllowUninstall" /t REG_DWORD /d "1" /f
PowerShell -ExecutionPolicy Unrestricted -Command "$installer = (Get-ChildItem "^""$($env:ProgramFiles)*\Microsoft\Edge\Application\*\Installer\setup.exe"^""); if (!$installer) {; Write-Host 'Installer not found. Microsoft Edge may already be uninstalled.'; } else {; $installer | ForEach-Object {; $uninstallerPath = $_.FullName; $installerArguments = @("^""--uninstall"^"", "^""--system-level"^"", "^""--verbose-logging"^"", "^""--force-uninstall"^""); Write-Output "^""Uninstalling through uninstaller: $uninstallerPath"^""; $process = Start-Process -FilePath "^""$uninstallerPath"^"" -ArgumentList $installerArguments -Wait -PassThru; if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 19) {; Write-Host "^""Successfully uninstalled Edge."^""; } else {; Write-Error "^""Failed to uninstall, uninstaller failed with exit code $($process.ExitCode)."^""; }; }; }"


:: remove file/url associations for edge
PowerShell -ExecutionPolicy Unrestricted -Command "$programIdPattern = 'MSEdge*'; $defaultAssociations = @(; @{ Type = 'File';   Ext = '.htm'; }; @{ Type = 'File';   Ext = '.html'; }; @{ Type = 'File';   Ext = '.pdf'; }; @{ Type = 'File';   Ext = '.mht'; }; @{ Type = 'File';   Ext = '.mhtml'; }; @{ Type = 'File';   Ext = '.svg'; }; @{ Type = 'File';   Ext = '.url'; }; @{ Type = 'File';   Ext = '.website'; }; @{ Type = 'File';   Ext = '.xht'; }; @{ Type = 'File';   Ext = '.xhtml'; }; @{ Type = 'URL';    Ext = 'ftp'; }; @{ Type = 'URL';    Ext = 'http'; }; @{ Type = 'URL';    Ext = 'https'; }; @{ Type = 'URL';    Ext = 'microsoft-edge'; }; @{ Type = 'URL';    Ext = 'microsoft-edge-holographic'; }; @{ Type = 'URL';    Ext = 'ms-xbl-3d8b930f'; }; @{ Type = 'URL';    Ext = 'read'; }; ); foreach ($assoc in $defaultAssociations) {; $path = $null; if ($assoc.Type -eq 'File') {; $path = "^""HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$($assoc.Ext)\UserChoice"^""; } elseif ($assoc.Type -eq 'URL') {; $path = "^""HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$($assoc.Ext)\UserChoice"^""; } else {; throw "^""Error, unknown type: $($assoc.Type)"^""; }; $currentProgramId = Get-ItemProperty -Path $path -Name 'Progid' -ErrorAction Ignore | Select-Object -ExpandProperty Progid; if (!$currentProgramId) {; Write-Host "^""Skipping, no association found for `"^""$($assoc.Ext)`"^"" in `"^""$path`"^"" matching `"^""$programIdPattern`"^""."^""; continue; }; if ($currentProgramId -notlike $programIdPattern) {; Write-Host "^""Skipping, association found `"^""$currentProgramId`"^"" in `"^""$path`"^"" does not match pattern `"^""$programIdPattern`"^""."^""; continue; }; $hkcuHiveId = 2147483649; $pathWithoutHive = ($path -split ':\\')[1]; $wmi = Get-WmiObject -List -Namespace root\default | Where-Object {$_.Name -eq 'StdRegProv'}; $result = $wmi.DeleteKey($hkcuHiveId, $pathWithoutHive); if ($result.ReturnValue -ne 0) {; Write-Error "^""Failed to delete `"^""$path`"^"": Return code $($result.ReturnValue)"^""; continue; }; Write-Host "^""Successfully removed `"^""$($assoc.Ext)`"^"" association in `"^""$path`"^""."^""; }"
PowerShell -ExecutionPolicy Unrestricted -Command "$extensions = @('.htm', '.html', '.pdf', '.svg'); foreach ($extension in $extensions) {; $path = "^""HKCU:\Software\Classes\$extension\OpenWithProgids"^""; Write-Host "^""Removing association for `"^""$extension`"^"": `"^""$path`"^""..."^""; Remove-Item -Path $path -Force -ErrorAction SilentlyContinue; }"
for %%a in (
    MSEdgeHTM_.webp MSEdgeHTM_http MSEdgeHTM_https MSEdgeHTM_.htm MSEdgeHTM_ftp MSEdgeHTM_.xml MSEdgeHTM_.html MSEdgePDF_.pdf MSEdgeHTM_.svg MSEdgeHTM_mailto MSEdgeHTM_read MSEdgeHTM_.mht MSEdgeMHT_.mht MSEdgeHTM_.mhtml MSEdgeMHT_.mhtml MSEdgeHTM_.xhtml MSEdgeHTM_.xht
) do (
    echo Removing association toast for "%%a"...
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "%%a" /f 2>nul
)
for %%A in (
    htm:MSEdgeHTM, html:MSEdgeHTM, shtml:MSEdgeHTM,
    pdf:MSEdgePDF, svg:MSEdgeHTM, xht:MSEdgeHTM,
    xhtml:MSEdgeHTM, webp:MSEdgeHTM, xml:MSEdgeHTM,
    mht:MSEdgeMHT, mhtml:MSEdgeMHT
) do (
    for /f "tokens=1,2 delims=:" %%B in ("%%A") do (
        echo Removing OpenWith association for "%%C" from "%%B"...
        reg delete "HKCR\.%%B\OpenWithProgIds" /v "%%C" /f 2>nul
    )
)


:: remove shortcuts
PowerShell -ExecutionPolicy Unrestricted -Command "$shortcuts = @(; @{ Revert = $True;  Path = "^""$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"^""; }; @{ Revert = $True;  Path = "^""$env:AppData\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk"^""; }; @{ Revert = $True;  Path = "^""$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"^""; }; @{ Revert = $True;  Path = "^""$env:Public\Desktop\Microsoft Edge.lnk"^""; }; @{ Revert = $True;  Path = "^""$env:SystemRoot\System32\config\systemprofile\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk"^""; }; @{ Revert = $False; Path = "^""$env:UserProfile\Desktop\Microsoft Edge.lnk"^""; }; ); foreach ($shortcut in $shortcuts) {; if (-Not (Test-Path $shortcut.Path)) {; Write-Host "^""Skipping, shortcut does not exist: `"^""$($shortcut.Path)`"^""."^""; continue; }; try {; Remove-Item -Path $shortcut.Path -Force -ErrorAction Stop; Write-Output "^""Successfully removed shortcut: `"^""$($shortcut.Path)`"^""."^""; } catch {; Write-Error "^""Encountered an issue while attempting to remove shortcut at: `"^""$($shortcut.Path)`"^""."^""; }; }"


:: firefox installation
PowerShell -ExecutionPolicy Unrestricted -Command "$ProgressPreference = 'SilentlyContinue';$choice = Read-Host "^""Do you want to install Firefox? y/[n]"^"";if ($choice -eq "^""y"^"") {    $os = "^"""^"";    switch ($env:PROCESSOR_ARCHITECTURE) {        "^""ARM64"^"" {$os = "^""win64-aarch64"^"";Write-Output "^""ARM CPU detected."^"";}        "^""AMD64"^"" {$os = "^""win64"^"";Write-Output "^""x64 CPU detected."^"";}        "^""X86"^"" {$os = "^""win"^"";Write-Output "^""x86 CPU detected."^"";}    }    if ( $os -eq "^"""^"" )    {        Write-Output "^""Unsupported CPU architecture. Unable to install Firefox."^"";    } else {        $link = "^""https://download.mozilla.org/?product=firefox-latest-ssl&os=$os&lang=en-US"^"";        Write-Output "^""Downloading Firefox, please wait..."^"";        Invoke-WebRequest -URI $link -OutFile "^""$env:temp\Firefox.exe"^"";        Write-Output "^""Installing..."^"";        Start-Process -FilePath "^""$env:temp\Firefox.exe"^"" -ArgumentList "^""/S"^"" -Wait;    }}else {    Write-Host "^""Skipping Firefox installation."^"";}"


:: Restore previous environment settings
endlocal
pause

:: Exit the script successfully
exit /b 0