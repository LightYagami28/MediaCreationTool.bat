# WINDOWS UPDATE REFRESH
# elevate with native shell by AveYo
if (-not (Test-Path "fltmc")) {
    if ($MyInvocation.ScriptName -ne "$env:temp\runas.Admin") {
        Set-Content -Path "$env:temp\runas.Admin" -Value $MyInvocation.MyCommand.Path
        Start-Process -FilePath "$env:temp\runas.Admin" -ArgumentList $MyInvocation.MyCommand.Path,$args -Verb RunAs -WindowStyle Hidden
        exit
    }
}

# stop pending updates
$BUILD = (Get-WmiObject -Class Win32_OperatingSystem).BuildNumber
$KILL = @()
$UPDATE = "windowsupdatebox", "updateassistant", "updateassistantcheck", "windows10upgrade", "windows10upgraderapp"
foreach ($w in $UPDATE) {
    $KILL += "/im $w.exe"
}
$KILL += "/im dism.exe"
$KILL += "/im setuphost.exe"
$KILL += "/im tiworker.exe"
$KILL += "/im usoclient.exe"
$KILL += "/im sihclient.exe"
$KILL += "/im wuauclt.exe"
$KILL += "/im culauncher.exe"
$KILL += "/im sedlauncher.exe"
$KILL += "/im osrrb.exe"
$KILL += "/im ruximics.exe"
$KILL += "/im ruximih.exe"
$KILL += "/im disktoast.exe"
$KILL += "/im eosnotify.exe"
$KILL += "/im musnotification.exe"
$KILL += "/im musnotificationux.exe"
$KILL += "/im musnotifyicon.exe"
$KILL += "/im monotificationux.exe"
$KILL += "/im mousocoreworker.exe"
$KILL += "/im usoclient.exe"
$KILL = $KILL -join " "
Stop-Process -Name $KILL -Force -ErrorAction SilentlyContinue
dism.exe /cleanup-wim
bitsadmin.exe /reset /allusers
$SERVICES = "msiserver", "wuauserv", "bits", "usosvc", "dosvc", "cryptsvc"
foreach ($service in $SERVICES) {
    net stop $service /y
}
Start-Sleep -Seconds 7
foreach ($service in $SERVICES) {
    $status = (Get-Service -Name $service).Status
    if ($status -eq "Stopped") {
        net start $service /y
    }
}

# clear update logs
$DATA = "$env:ProgramData"
$LOG = "$env:SystemRoot\Logs\WindowsUpdate"
$SRC = "$env:SystemDrive\$WINDOWS.~BT\Sources"
Remove-Item -Path "$DATA\USOShared\Logs\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$DATA\USOPrivate\UpdateStore\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$DATA\Microsoft\Network\Downloader\*" -Force -Recurse -ErrorAction SilentlyContinue
try {
    Get-WindowsUpdateLog -LogPath "$env:temp\WU.log" -ForceFlush -Confirm:$false -ErrorAction SilentlyContinue
}
catch {
}
Remove-Item -Path $LOG -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:ProgramFiles\UNP" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\SoftwareDistribution" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemDrive\Windows.old\Cleanup" -Force -Recurse -ErrorAction SilentlyContinue
if ((Test-Path "$SRC\setuphost.exe") -and (Test-Path "$SRC\setupprep.exe")) {
    Start-Process -FilePath "$SRC\setupprep.exe" -ArgumentList "/cleanup /quiet" -Wait -NoNewWindow
}

# remove forced upgraders and update remediators
Start-Process -FilePath "$env:SystemRoot\UpdateAssistant\Windows10Upgrade.exe" -ArgumentList "/ForceUninstall" -Wait -NoNewWindow
Start-Process -FilePath "$env:SystemDrive\Windows10Upgrade\Windows10UpgraderApp.exe" -ArgumentList "/ForceUninstall" -Wait -NoNewWindow
$GUIDs = "{1BA1133B-1C7A-41A0-8CBF-9B993E63D296}", "{8F2D6CEB-BC98-4B69-A5C1-78BED238FE77}", "{0746492E-47B6-4251-940C-44462DFD74BB}", "{76A22428-2400-4521-96AF-7AC4A6174CA5}"
foreach ($GUID in $GUIDs) {
    $null = msiexec.exe /X $GUID /qn 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "Removed: $GUID"
    }
}
Write-Output ""

# start update services
net start bits /y
net start wuauserv /y
net start usosvc /y
Start-Process -FilePath "UsoClient.exe" -ArgumentList "RefreshSettings" -NoNewWindow -Wait
Write-Output "AveYo: run again / reboot if there are still pending files or services"
Pause
exit
