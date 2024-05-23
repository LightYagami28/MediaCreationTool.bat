# Get 11 on 'unsupported' PC via Windows Update or mounted ISO (no patching needed)
# if WU is stuck use windows_update_refresh.bat; Beta/Dev/Canary needs OfflineInsiderEnroll
# V13: skip 2nd tpm check on Canary iso; no Server label; future proofing; tested with 26010 iso, wu and wu repair version

$code = @'
$CLI = $args
$SOURCES = "$env:SystemDrive\$WINDOWS.~BT\Sources"
$MEDIA = "."
$MOD = "CLI"
$PRE = "WUA"
$VER = 11

if ($MyInvocation.InvocationName -ne "$env:SystemDrive\Scripts\get11.cmd") {
    goto setup
}

powershell -win 1 -nop -c ";"
$CLI = $args
if ($CLI -eq "") {
    exit
}
elseif (!(Test-Path "$SOURCES\SetupHost.exe")) {
    exit
}
elseif (!(Test-Path "$SOURCES\WindowsUpdateBox.exe")) {
    New-Item -Path "$SOURCES\WindowsUpdateBox.exe" -ItemType "SymbolicLink" -Target "$SOURCES\SetupHost.exe"
}

reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f /v DisableWUfBSafeguards /d 1 /t reg_dword | Out-Null
reg add HKLM\SYSTEM\Setup\MoSetup /f /v AllowUpgradesWithUnsupportedTPMorCPU /d 1 /t reg_dword | Out-Null

$OPT = "/Compat IgnoreWarning /MigrateDrivers All /Telemetry Disable"
$restart_application = 0x800705BB
$incorrect_parameter = 0x80070057
$launch_option_error = 0xc190010a

$SRV = $CLI.Replace("/Product Client ", "")
$SRV = $SRV.Replace("/Product Server ", "")

foreach ($arg in $CLI) {
    if ($arg -eq "/PreDownload") {
        $MOD = "SRV"
    }
    if ($arg -eq "/InstallFile") {
        $PRE = "ISO"
        $MEDIA = ""
    }
    elseif ($MEDIA -eq ".") {
        $MEDIA = Split-Path -Path $arg -Parent
    }
}

if ($VER -eq 11 -and (Test-Path "$MEDIA\appraiserres.dll") -and (Get-Item "$MEDIA\appraiserres.dll").Length -eq 0) {
    $AlreadyPatched = $true
    $VER = 10
}

if ($VER -eq 11) {
    $check = Select-String -Path "$SOURCES\SetupHost.exe" -Pattern "P.r.o.d.u.c.t.V.e.r.s.i.o.n...1.0.\..0.\..2.[2-9]" -Quiet
    if (-not $check) {
        $VER = 10
    }
}

if ($VER -eq 11 -and -not (Test-Path "$MEDIA\EI.cfg")) {
    "[Channel]" | Out-File -FilePath "$SOURCES\EI.cfg"
    "_Default" | Out-File -FilePath "$SOURCES\EI.cfg" -Append
}

if ("$VER$PRE" -eq "11_ISO") {
    Start-Process "$SOURCES\WindowsUpdateBox.exe" -ArgumentList "/Product Server /PreDownload /Quiet $OPT" -NoNewWindow
}

if ("$VER$PRE" -eq "11_ISO") {
    Remove-Item -Path "$SOURCES\appraiserres.dll" -Force -ErrorAction SilentlyContinue
    $null = New-Item "$SOURCES\appraiserres.dll" -ItemType "file"
    & canary
}

if ("$VER$MOD" -eq "11_SRV") {
    $ARG = "$OPT $SRV /Product Server"
}
if ("$VER$MOD" -eq "11_CLI") {
    $ARG = "$OPT $CLI"
}

Start-Process "$SOURCES\WindowsUpdateBox.exe" -ArgumentList $ARG -NoNewWindow
if ($LASTEXITCODE -eq $restart_application) {
    & canary
    Start-Process "$SOURCES\WindowsUpdateBox.exe" -ArgumentList $ARG -NoNewWindow
}
exit

:canary
# canary iso skip 2nd tpm check by AveYo
$X = "$SOURCES\hwreqchk.dll"
$Y = "SQ_TpmVersion GTE 1"
$Z = "SQ_TpmVersion GTE 0"

if (Test-Path $X) {
    try {
        takeown.exe /f $X /a
        icacls.exe $X /grant *S-1-5-32-544:f
        attrib.exe -R -S $X
        [System.IO.File]::OpenWrite($X).close()
    }
    catch {
        return
    }
    $R = [Text.Encoding]::UTF8.GetBytes($Z)
    $l = $R.Length
    $i = 2
    $w = $false
    $B = [System.IO.File]::ReadAllBytes($X)
    $H = [BitConverter]::ToString($B) -replace '-'
    $S = [BitConverter]::ToString([Text.Encoding]::UTF8.GetBytes($Y)) -replace '-'
    do {
        $i = $H.IndexOf($S, $i + 2)
        if ($i -gt 0) {
            $w = $true
            for ($k = 0; $k -lt $l; $k++) {
                $B[$k + $i / 2] = $R[$k]
            }
        }
    }
    until ($i -lt 1)
    if ($w) {
        [System.IO.File]::WriteAllBytes($X, $B)
        [System.GC]::Collect()
    }
}
if ("$VER$PRE" -eq "11_ISO") {
    Start-Process powershell.exe -NoProfile -Command iex($env:C) > $null
}
exit

:setup
# elevate with native shell by AveYo
if (!(Test-Path "fltmc")) {
    if ($MyInvocation.ScriptName -ne "$env:temp\runas.Admin") {
        Set-Content -Path "$env:temp\runas.Admin" -Value $MyInvocation.MyCommand.Path
        Start-Process -FilePath "$env:temp\runas.Admin" -ArgumentList $MyInvocation.MyCommand.Path,$args -Verb RunAs -WindowStyle Hidden
        exit
    }
}

# lean xp+ color macros by AveYo:  %<%:af " hello "%>>%  &  %<%:cf " w\"or\"ld "%>%   for single \ / " use .%|%\  .%|%/  \"%|%\"
$_.s = "|"
$_.s = "%<%:af "
$_.s = " Skip TPM Check on Dynamic Update V13 "
$_.s = " INSTALLED "
$_.s = " run again to remove "
$_.s = "%<%:af "
$_.s = " Skip TPM Check on Dynamic Update V13 "
$_.s = " REMOVED "
$_.s = " run again to install "
$_.s = "%<%:af "

goto :EOF
'@

$scriptPath = "$env:temp\Skip_TPM_Check_on_Dynamic_Update.ps1"
$code -split "\r?\n" | Out-File -FilePath $scriptPath -Encoding default -Force
Start-Process powershell.exe -ArgumentList "-NoProfile", "-File", $scriptPath
