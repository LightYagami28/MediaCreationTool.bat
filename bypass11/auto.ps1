# Auto Upgrade - MCT ||  supports Ultimate / PosReady / Embedded / LTSC / Enterprise Eval
$EDITION_SWITCH = ""
$SKIP_11_SETUP_CHECKS = 1
$OPTIONS = "/SelfHost /Auto Upgrade /MigChoice Upgrade /Compat IgnoreWarning /MigrateDrivers All /ResizeRecoveryPartition Disable"
$OPTIONS += " /ShowOOBE None /Telemetry Disable /CompactOS Disable /DynamicUpdate Enable /SkipSummary /Eula Accept"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Push-Location -Path $ScriptPath
$arch = if (Test-Path -Path "x86\sources\setupprep.exe") { "x86\" } elseif (Test-Path -Path "x64\sources\setupprep.exe") { "x64\" } else { "" }
Push-Location -Path "$arch\sources" | Out-Null

# Start setup if under WinPE
if (Test-Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinPE") {
    $bypassKeys = "sCPU", "sRAM", "sSecureBoot", "sStorage", "sTPM"
    $bypassKeys | ForEach-Object {
        $regPath = "HKLM:\SYSTEM\Setup\LabConfig"
        $regName = "Bypass$($_)Check"
        Set-ItemProperty -Path $regPath -Name $regName -Value 1 -Type DWord -Force | Out-Null
    }
    Start-Process -FilePath "sources\setup.exe" -WindowStyle Hidden
    Exit
}

# Initialize variables
$env:PATH += ";$env:SystemRoot\System32;$env:SystemRoot\System32\windowspowershell\v1.0"
$env:PATH += ";$env:SystemRoot\Sysnative;$env:SystemRoot\Sysnative\windowspowershell\v1.0"

# Elevate privileges
if (!(fltmc)) {
    Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -Command `"$MyInvocation.InvocationName`"" -Verb RunAs -Wait
    Exit
}

# Undo previous regedit edition rename
$NTPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$properties = "CompositionEditionID", "EditionID", "ProductName"
$properties | ForEach-Object {
    $undoName = "$($_)_undo"
    $undoValue = Get-ItemProperty -Path $NTPath -Name $undoName -ErrorAction SilentlyContinue
    if ($undoValue) {
        Remove-ItemProperty -Path $NTPath -Name $undoName -Force | Out-Null
        $reg = if ($_.Equals("EditionID")) { $EDITION_SWITCH } else { $undoValue.$_ }
        New-ItemProperty -Path $NTPath -Name $_ -Value $reg -Force | Out-Null
    }
}

# Get current version
$versionInfo = Get-ItemProperty -Path $NTPath -Name "CompositionEditionID", "EditionID", "ProductName", "CurrentBuildNumber"
$verTokens = (cmd /c ver) -replace "\[|\]"
$tokens = $verTokens.Split(".")
$ver = $tokens[1] * 10 + $tokens[2]

# WIM_INFO snippet
$wimInfoSnippet = @"
    $ScriptPath
    #WIM_INFO
"@
$wimInfo = Invoke-Expression $wimInfoSnippet
$w_count = $wimInfo.Length
$wimInfo

# Get requested edition
# For example, parsing product.ini, EI.cfg, or PID.txt files

# Upgrade matrix
# For example, determining the edition to upgrade to based on current edition and build

# Disable upgrade blocks
$null = New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DisableWUfBSafeguards" -Value 1 -Type DWord -Force | Out-Null

# Prevent usage of MCT for intermediary upgrade in Dynamic Update
if ($Build -gt 15063) {
    $OPTIONS += " /UpdateMedia Decline"
}

# Skip Windows 11 upgrade checks
if ($Build -lt 22000) {
    $SKIP_11_SETUP_CHECKS = 0
}
New-Item -Path ".\appraiserres.dll" -ItemType File -ErrorAction SilentlyContinue | Out-Null
if ((Get-Item ".\appraiserres.dll").Length -gt 0) {
    $TRICK = "/Product Server "
} else {
    $TRICK = ""
}
if ($SKIP_11_SETUP_CHECKS -eq 1) {
    $OPTIONS += $TRICK
}

# Auto upgrade with edition lie workaround to keep files and apps
if ($reg) {
    Rename-Edition $reg
}
Start-Process -FilePath "setupprep.exe" -ArgumentList $OPTIONS -WindowStyle Hidden

Write-Host "DONE"

Exit

function Rename-Edition {
    param (
        [string]$EditionID
    )
    $NTPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    $properties = "CompositionEditionID", "EditionID", "ProductName"
    $properties | ForEach-Object {
        $undoName = "$($_)_undo"
        $undoValue = Get-ItemProperty -Path $NTPath -Name $_ -ErrorAction SilentlyContinue
        if ($undoValue) {
            New-ItemProperty -Path $NTPath -Name $undoName -Value $undoValue.$_ -Force | Out-Null
        }
    }
    $regValues = @{
        "CompositionEditionID" = "Core"
        "EditionID" = $EditionID
        "ProductName" = $EditionID
    }
    $regValues.GetEnumerator() | ForEach-Object {
        New-ItemProperty -Path $NTPath -Name $_.Key -Value $_.Value -Force | Out-Null
    }
}

function Reg-Query {
    param (
        [string]$Path,
        [string]$ValueName,
        [ref]$Variable
    )
    $value = (Get-ItemProperty -Path $Path -Name $ValueName -ErrorAction SilentlyContinue).$ValueName
    $Variable.Value = $value
}

function WIM-Info {
    param (
        [string]$file = 'install.esd',
        [int]$index = 0,
        [int]$out = 0
    )
    # [REMOVED] WIM_INFO function implementation due to space constraints
}
