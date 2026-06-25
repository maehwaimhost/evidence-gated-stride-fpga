$ErrorActionPreference = "Continue"

# Tool path: set $env:VIVADO_BIN to your vivado.bat, or put vivado.bat on PATH (e.g. run Vivado's settings64.bat first).
$VivadoBin = if ($env:VIVADO_BIN) { $env:VIVADO_BIN } else { "vivado.bat" }

$ExpDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Results = Join-Path $ExpDir "results"
New-Item -ItemType Directory -Force -Path $Results, (Join-Path $Results "vivado"), (Join-Path $Results "quartus"), (Join-Path $Results "libero") | Out-Null

$RunLog = Join-Path $Results "run_all.log"
"Cross-vendor artifact-provenance evaluation started: $(Get-Date -Format o)" | Set-Content -LiteralPath $RunLog -Encoding ASCII

function Invoke-Step {
    param([string]$Name, [scriptblock]$Block)
    Add-Content -LiteralPath $RunLog -Value "BEGIN $Name $(Get-Date -Format o)" -Encoding ASCII
    & $Block
    $code = $LASTEXITCODE
    Add-Content -LiteralPath $RunLog -Value "END $Name exit=$code $(Get-Date -Format o)" -Encoding ASCII
}

Invoke-Step "vivado" {
    & $VivadoBin -mode batch -nolog -nojournal -source (Join-Path $ExpDir "vivado\build_vivado.tcl") *> (Join-Path $Results "vivado\vivado_console.log")
}

Invoke-Step "quartus" {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ExpDir "quartus\build_quartus.ps1")
}

Invoke-Step "libero" {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ExpDir "libero\build_libero.ps1")
}

Invoke-Step "collect_evidence" {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ExpDir "scripts\collect_evidence.ps1")
}

Add-Content -LiteralPath $RunLog -Value "Cross-vendor artifact-provenance evaluation ended: $(Get-Date -Format o)" -Encoding ASCII
