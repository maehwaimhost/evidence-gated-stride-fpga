$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpDir = Split-Path -Parent $ScriptDir
$ResultDir = Join-Path $ExpDir "results\quartus"
$ProjectDir = Join-Path $ResultDir "project"
$ProjectDirB = Join-Path $ResultDir "project_b"
$StatusFile = Join-Path $ResultDir "quartus_status.csv"
$QuartusSh = if ($env:QUARTUS_SH) { $env:QUARTUS_SH } else { "quartus_sh.exe" }  # set $env:QUARTUS_SH or put quartus_sh on PATH

New-Item -ItemType Directory -Force -Path $ResultDir, $ProjectDir, $ProjectDirB | Out-Null
"stage,status,detail" | Set-Content -LiteralPath $StatusFile -Encoding ASCII

function Add-Status {
    param([string]$Stage, [string]$Status, [string]$Detail)
    $clean = ($Detail -replace "[`r`n,]", " ")
    Add-Content -LiteralPath $StatusFile -Value "$Stage,$Status,$clean" -Encoding ASCII
}

$version = & $QuartusSh --version 2>&1
Add-Status "environment" "ok" (($version | Select-Object -First 1) -join " ")

# ---------------- Design A ----------------

& $QuartusSh -t (Join-Path $ScriptDir "create_project.tcl") *> (Join-Path $ResultDir "quartus_create_project.log")
if ($LASTEXITCODE -eq 0) {
    Add-Status "project_create" "ok" "QPF/QSF project generated"
} else {
    Add-Status "project_create" "fail" "quartus_sh create_project failed with exit $LASTEXITCODE"
}

Push-Location $ProjectDir
& $QuartusSh --flow compile top -c top *> (Join-Path $ResultDir "quartus_compile.log")
$compileExit = $LASTEXITCODE
Pop-Location

if ($compileExit -eq 0) {
    Add-Status "compile" "ok" "Quartus compile flow completed"
} else {
    Add-Status "compile" "fail" "Quartus compile flow failed with exit $compileExit"
}

# ---------------- Design B (dual clock domain, async FIFO, CDC) ----------------

& $QuartusSh -t (Join-Path $ScriptDir "create_project_b.tcl") *> (Join-Path $ResultDir "quartus_create_project_b.log")
if ($LASTEXITCODE -eq 0) {
    Add-Status "project_create_b" "ok" "QPF/QSF project generated"
} else {
    Add-Status "project_create_b" "fail" "quartus_sh create_project_b failed with exit $LASTEXITCODE"
}

Push-Location $ProjectDirB
& $QuartusSh --flow compile top_b -c top_b *> (Join-Path $ResultDir "quartus_compile_b.log")
$compileExitB = $LASTEXITCODE
Pop-Location

if ($compileExitB -eq 0) {
    Add-Status "compile_b" "ok" "Quartus compile flow completed"
} else {
    Add-Status "compile_b" "fail" "Quartus compile flow failed with exit $compileExitB"
}

if (($compileExit -ne 0) -or ($compileExitB -ne 0)) {
    exit 1
}
exit 0
