$ProgressPreference = 'SilentlyContinue';
$choice = Read-Host "Do you want to install Firefox? y/[n]";
if ($choice -eq "y") {
    $os = "";
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "ARM64" {$os = "win64-aarch64";Write-Output "ARM CPU detected.";}
        "AMD64" {$os = "win64";Write-Output "x64 CPU detected.";}
        "X86" {$os = "win";Write-Output "x86 CPU detected.";}
    }
    if ( $os -eq "" )
    {
        Write-Output "Unsupported CPU architecture. Unable to install Firefox.";
    } else {
        $link = "https://download.mozilla.org/?product=firefox-latest-ssl&os=$os&lang=en-US";
        Write-Output "Downloading Firefox, please wait...";
        Invoke-WebRequest -URI $link -OutFile "$env:temp\Firefox.exe";
        Write-Output "Installing...";
        Start-Process -FilePath "$env:temp\Firefox.exe" -ArgumentList "/S" -Wait;
    }
}
else {
    Write-Host "Skipping Firefox installation.";
}