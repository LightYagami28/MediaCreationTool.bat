# Quick 11 iso esd wim TPM toggle by AveYo - with SendTo menu entry
# what's new in v1.2: add uninstall when run again without parameters (issue #96) 

# Start timer
$timer = Get-Date

# Install to SendTo menu when run from another location
$SendTo = [Environment]::GetFolderPath('ApplicationData') + '\Microsoft\Windows\SendTo'
$Script = "$SendTo\Quick_11_iso_esd_wim_TPM_toggle.bat"
if (-not $env:1 -and $env:0 -and -not (Test-Path $Script)) { 
    Write-Host "`n No input iso / esd / wim file to patch! use 'Send to' context menu ...`n" -ForegroundColor Yellow
    Copy-Item $env:0 $Script -Force
}
elseif (-not $env:1 -and $env:0 -and (Test-Path $Script)) {
    Write-Host "`n Removed 'Send to' entry - run again to install ...`n" -ForegroundColor Magenta
    Remove-Item $Script -Force
}
if (-not $env:1) { return }

# Can force either patch or undo via second commandline parameter: 1 to patch, 0 to undo
if ($env:2 -eq 1) { $toggle = 1 } elseif ($env:2 -eq 0) { $toggle = 0 } else { $toggle = 2 }

# Verify extension is .iso, .esd, or .wim
$input = Get-Item -LiteralPath $env:1
$invalid = '.iso','.esd','.wim' -notcontains $input.Extension
if ($invalid) {
    Write-Host "`n Input is not a iso / esd / wim file ...`n" -ForegroundColor Yellow
    return
} 
try {
    [IO.File]::OpenWrite($input).Close()
} catch {
    Write-Host "`n ERROR! $input read-only or in use ...`n" -ForegroundColor Red
    return
}

# TPM patch via InstallationType Server
$typeC = '<INSTALLATIONTYPE>Client'
$typeS = '<INSTALLATIONTYPE>Server'
$block = 1048576
$chunk = 2097152
$count = [uint64]([IO.FileInfo]$input).Length / $chunk - 1
$bytes = New-Object "Byte[]" ($chunk)
$begin = [uint64]0
$final = [uint64]0
$limit = [uint64]0

function ToChars {
    return [Text.Encoding]::GetEncoding(28591).GetString([Text.Encoding]::Unicode.GetBytes($args[0]))
}

$find1 = ToChars "</INSTALLATIONTYPE>"
$find2 = ToChars "</WIM>"
$cli = ToChars $typeC
$srv = ToChars $typeS

$f = New-Object IO.FileStream ($input, 3, 3, 1)
$p = 0
$p = $f.Seek(0, 2)
Write-Host "$input`nsearching $p bytes, please wait ...`n"

for ($o = 1; $o -le $count; $o++) { 
    $p = $f.Seek(-$chunk, 1)
    $r = $f.Read($bytes, 0, $chunk)
    if ($r -ne $chunk) {
        Write-Host "invalid block $r"
        break
    }
    $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
    $t = $u.LastIndexOf($find1, [StringComparison]::Ordinal)
    if ($t -ge 0) {
        $f.Seek(($t -$chunk), 1) >''
        for ($o = 1; $o -le $chunk; $o++) {
            $f.Seek(-2, 1) >''
            if ($f.ReadByte() -eq 0xfe) {
                $begin = $f.Position
                break
            }
        }
        $limit = $f.Length - $begin
        if ($limit -lt $chunk) {
            $x = $limit
        } else {
            $x = $chunk
        }
        $bytes = New-Object "Byte[]" ($x)
        $r = $f.Read($bytes, 0, $x)
        if ($r -ne $x) { break }
        $u = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
        $t = $u.IndexOf($find2, [StringComparison]::Ordinal)
        if ($t -ge 0) {
            $f.Seek(($t + 12 -$x), 1) >''
            $final = $f.Position
            break
        }
    } else { $p = $f.Seek(-$chunk, 1) }
}

if ($begin -gt 0 -and $final -gt $begin) {
    $x = $final - $begin
    $f.Seek(-$x, 1) >''
    $bytes = New-Object "Byte[]" ($x)
    $r = $f.Read($bytes, 0, $x)
    if ($r -ne $x) { break }
    $t = [Text.Encoding]::GetEncoding(28591).GetString($bytes)
    if ($t.IndexOf($cli, [StringComparison]::Ordinal) -ge 0) {
        $src = 0
    } else {
        $src = 1
    } 
    if ($src -eq 0 -and $toggle -ne 0) {
        $old = $cli
        $new = $srv
    } elseif ($src -eq 1 -and $toggle -ne 1) {
        $old = $srv
        $new = $cli
    } else {
        Write-Host "`n:) $input already has TPM patch $toggle"
        $f.Dispose()
        return
    }
    $t = $t.Replace($old, $new)
    $t
    $b = [Text.Encoding]::GetEncoding(28591).GetBytes($t)
    $f.Seek(-$x, 1) >''
    $f.Write($b, 0, $x)
    if ($src -eq 1) {
        Write-Host "`n :D TPM patch removed" -ForegroundColor Green
    } else {
        Write-Host "`n :D TPM patch added" -ForegroundColor Green
    } 
    $f.Dispose()
    [GC]::Collect()
} else {
    Write-Host "`n;( TPM patch failed" -ForegroundColor Red
    $f.Dispose()
}

# Display elapsed time
$(Get-Date) - $timer
# Done
