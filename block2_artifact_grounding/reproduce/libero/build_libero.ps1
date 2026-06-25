$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpDir = Split-Path -Parent $ScriptDir
$ResultDir = Join-Path $ExpDir "results\libero"
$Libero = if ($env:LIBERO_BIN) { $env:LIBERO_BIN } else { "libero.exe" }  # set $env:LIBERO_BIN or put libero on PATH
$Tcl = Join-Path $ScriptDir "build_libero.tcl"
$Log = Join-Path $ResultDir "libero_script.log"
$StatusFile = Join-Path $ResultDir "libero_status.csv"

New-Item -ItemType Directory -Force -Path $ResultDir | Out-Null

& $Libero "SCRIPT:$Tcl" "LOGFILE:$Log"
$exitCode = $LASTEXITCODE

$deadline = (Get-Date).AddMinutes(40)
$complete = $false
do {
    if (Test-Path -LiteralPath $StatusFile) {
        $statusText = Get-Content -Raw -LiteralPath $StatusFile -ErrorAction SilentlyContinue
        if ($statusText -match ",fail,") {
            $exitCode = 1
            break
        }
        if ($statusText -match "export_bitstream_b,ok") {
            $complete = $true
            break
        }
    }
    Start-Sleep -Seconds 10
} while ((Get-Date) -lt $deadline)

if (-not $complete) {
    exit 1
}

exit $exitCode
