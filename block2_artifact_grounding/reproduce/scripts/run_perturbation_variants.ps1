param(
    [switch]$SkipRuns
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectExpDir = Split-Path -Parent $ScriptDir
$RerunRoot = Split-Path -Parent $ProjectExpDir
$BaseRuntime = $ProjectExpDir
$VariantRoot = Join-Path $RerunRoot "cross_vendor_variant_runtime"
$ProjectVariantDir = Join-Path $ProjectExpDir "variants"
$BaseResults = Join-Path $BaseRuntime "results"

if (-not (Test-Path -LiteralPath $BaseRuntime)) {
    throw "Base runtime folder not found: $BaseRuntime"
}
if (-not (Test-Path -LiteralPath $BaseResults)) {
    throw "Base runtime results not found: $BaseResults"
}

New-Item -ItemType Directory -Force -Path $VariantRoot, $ProjectVariantDir | Out-Null

function Assert-UnderRoot {
    param([string]$Path, [string]$Root)
    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
    if (-not ($fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase))) {
        throw "Refusing to modify path outside intended root: $fullPath"
    }
}

function Copy-BaselineRuntime {
    param([string]$Destination)
    Assert-UnderRoot -Path $Destination -Root $VariantRoot
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null

    foreach ($item in Get-ChildItem -LiteralPath $BaseRuntime -Force) {
        if ($item.Name -eq "results") { continue }
        if ($item.Name -eq "variants") { continue }
        Copy-Item -LiteralPath $item.FullName -Destination (Join-Path $Destination $item.Name) -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path (Join-Path $Destination "results") | Out-Null
}

function Set-AsciiFile {
    param([string]$Path, [string]$Content)
    Set-Content -LiteralPath $Path -Value $Content -Encoding ASCII
}

function Get-Sha256 {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "MISSING" }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function CsvEscape {
    param([string]$Value)
    $quote = [string][char]34
    if ($null -eq $Value) { return ($quote + $quote) }
    return $quote + $Value.Replace($quote, $quote + $quote) + $quote
}

function Get-RunStatus {
    param([string]$VariantDir, [string]$VendorKey)
    $statusPath = Join-Path $VariantDir "results\$VendorKey\${VendorKey}_status.csv"
    if (-not (Test-Path -LiteralPath $statusPath)) { return "missing_status" }
    $rows = Import-Csv -LiteralPath $statusPath
    if ($rows.Count -eq 0) { return "missing_status" }
    $bad = @($rows | Where-Object { $_.status -ne "ok" })
    if ($bad.Count -gt 0) { return "has_failures" }
    $requiredStages = switch ($VendorKey) {
        "vivado" { @("bitstream", "bitstream_b") }
        "quartus" { @("compile", "compile_b") }
        "libero" { @("export_bitstream", "export_bitstream_b") }
    }
    foreach ($requiredStage in $requiredStages) {
        if (-not ($rows | Where-Object { $_.stage -eq $requiredStage -and $_.status -eq "ok" })) {
            return "incomplete"
        }
    }
    return "ok"
}

function Get-ChangedRelativePaths {
    param([string]$VariantDir, [string[]]$RelativePaths)
    $changed = New-Object System.Collections.Generic.List[string]
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($rel in $RelativePaths) {
        $basePath = Join-Path $BaseRuntime $rel
        $variantPath = Join-Path $VariantDir $rel
        $baseHash = Get-Sha256 $basePath
        $variantHash = Get-Sha256 $variantPath
        if ($baseHash -eq "MISSING" -or $variantHash -eq "MISSING") {
            $missing.Add($rel)
        } elseif ($baseHash -ne $variantHash) {
            $changed.Add($rel)
        }
    }
    return [pscustomobject]@{
        Changed = @($changed)
        Missing = @($missing)
    }
}

$variants = @(
    [pscustomobject]@{
        Id = "hdl_revision"
        Type = "HDL revision"
        ChangedArtifacts = @("src\top.v", "src\top_b.v")
        AffectedStage = "HDL/IP Input to downstream transformation"
        Threats = "SIP-2;TRN-1;RPT-2"
        Apply = {
            param([string]$Dir)
            $topPath = Join-Path $Dir "src\top.v"
            $text = Get-Content -Raw -LiteralPath $topPath
            $text = $text.Replace("assign led = {alarm, state, digest[0]};", "assign led = {alarm, state[0], state[1], digest[1]};")
            Set-AsciiFile -Path $topPath -Content $text

            $topBPath = Join-Path $Dir "src\top_b.v"
            $textB = Get-Content -Raw -LiteralPath $topBPath
            $textB = $textB.Replace("status <= {1'b1, peak[7:5]};", "status <= {1'b1, peak[6:4]};")
            Set-AsciiFile -Path $topBPath -Content $textB
        }
    },
    [pscustomobject]@{
        Id = "constraint_revision"
        Type = "constraint revision"
        ChangedArtifacts = @("vivado\top.xdc", "quartus\top.sdc", "libero\top.sdc", "vivado\top_b.xdc", "quartus\top_b.sdc", "libero\top_b.sdc")
        AffectedStage = "Constraint and Configuration to implementation/report stages"
        Threats = "CFG-1;CFG-3;TRN-2;RPT-2"
        Apply = {
            param([string]$Dir)
            $vivadoXdc = Join-Path $Dir "vivado\top.xdc"
            $quartusSdc = Join-Path $Dir "quartus\top.sdc"
            $liberoSdc = Join-Path $Dir "libero\top.sdc"
            Set-AsciiFile -Path $vivadoXdc -Content ((Get-Content -Raw -LiteralPath $vivadoXdc).Replace("create_clock -period 10.000", "create_clock -period 8.000"))
            Set-AsciiFile -Path $quartusSdc -Content ((Get-Content -Raw -LiteralPath $quartusSdc).Replace("-period 10.000", "-period 8.000"))
            Set-AsciiFile -Path $liberoSdc -Content ((Get-Content -Raw -LiteralPath $liberoSdc).Replace("-period 10 ", "-period 8 "))

            $vivadoXdcB = Join-Path $Dir "vivado\top_b.xdc"
            $quartusSdcB = Join-Path $Dir "quartus\top_b.sdc"
            $liberoSdcB = Join-Path $Dir "libero\top_b.sdc"
            Set-AsciiFile -Path $vivadoXdcB -Content ((Get-Content -Raw -LiteralPath $vivadoXdcB).Replace("create_clock -period 7.000", "create_clock -period 6.000"))
            Set-AsciiFile -Path $quartusSdcB -Content ((Get-Content -Raw -LiteralPath $quartusSdcB).Replace("-period 7.000", "-period 6.000"))
            Set-AsciiFile -Path $liberoSdcB -Content ((Get-Content -Raw -LiteralPath $liberoSdcB).Replace("-period 7 ", "-period 6 "))
        }
    }
)

$keyArtifactsByVendorDesign = @{
    "vivado|A" = @(
        "src\top.v",
        "vivado\top.xdc",
        "results\vivado\top_synth.dcp",
        "results\vivado\top_routed.dcp",
        "results\vivado\top_synth_utilization.rpt",
        "results\vivado\top_synth_timing_summary.rpt",
        "results\vivado\top_impl_utilization.rpt",
        "results\vivado\top_impl_timing_summary.rpt",
        "results\vivado\top_impl_drc.rpt",
        "results\vivado\top.bit",
        "results\vivado\vivado_status.csv"
    )
    "vivado|B" = @(
        "src\top_b.v",
        "vivado\top_b.xdc",
        "results\vivado\top_b_synth.dcp",
        "results\vivado\top_b_routed.dcp",
        "results\vivado\top_b_synth_utilization.rpt",
        "results\vivado\top_b_synth_timing_summary.rpt",
        "results\vivado\top_b_synth_clock_interaction.rpt",
        "results\vivado\top_b_impl_utilization.rpt",
        "results\vivado\top_b_impl_timing_summary.rpt",
        "results\vivado\top_b_impl_clock_interaction.rpt",
        "results\vivado\top_b_impl_cdc.rpt",
        "results\vivado\top_b_impl_drc.rpt",
        "results\vivado\top_b.bit",
        "results\vivado\vivado_status.csv"
    )
    "quartus|A" = @(
        "src\top.v",
        "quartus\top.sdc",
        "results\quartus\project\top.qsf",
        "results\quartus\project\output_files\top.syn.rpt",
        "results\quartus\project\output_files\top.fit.rpt",
        "results\quartus\project\output_files\top.sta.rpt",
        "results\quartus\project\output_files\top.asm.rpt",
        "results\quartus\project\output_files\top.sof",
        "results\quartus\quartus_status.csv"
    )
    "quartus|B" = @(
        "src\top_b.v",
        "quartus\top_b.sdc",
        "results\quartus\project_b\top_b.qsf",
        "results\quartus\project_b\output_files\top_b.syn.rpt",
        "results\quartus\project_b\output_files\top_b.fit.rpt",
        "results\quartus\project_b\output_files\top_b.sta.rpt",
        "results\quartus\project_b\output_files\top_b.asm.rpt",
        "results\quartus\project_b\output_files\top_b.sof",
        "results\quartus\quartus_status.csv"
    )
    "libero|A" = @(
        "src\top.v",
        "libero\top.sdc",
        "results\libero\project\synthesis\top_vm.sdc",
        "results\libero\project\synthesis\synplify.log",
        "results\libero\project\designer\top\place_route.sdc",
        "results\libero\project\designer\top\timing_analysis.sdc",
        "results\libero\project\designer\top\top_compile_netlist_resources.rpt",
        "results\libero\project\designer\top\top_pinrpt_number.rpt",
        "results\libero\project\designer\top\export\ap_stride_libero.stp",
        "results\libero\project\designer\top\export\ap_stride_libero.dat",
        "results\libero\project\designer\top\export\ap_stride_libero.ppd",
        "results\libero\libero_status.csv"
    )
    "libero|B" = @(
        "src\top_b.v",
        "libero\top_b.sdc",
        "results\libero\project_b\synthesis\top_b_vm.sdc",
        "results\libero\project_b\synthesis\synplify.log",
        "results\libero\project_b\designer\top_b\place_route.sdc",
        "results\libero\project_b\designer\top_b\timing_analysis.sdc",
        "results\libero\project_b\designer\top_b\top_b_compile_netlist_resources.rpt",
        "results\libero\project_b\designer\top_b\top_b_pinrpt_number.rpt",
        "results\libero\project_b\designer\top_b\export\ap_stride_libero_b.stp",
        "results\libero\project_b\designer\top_b\export\ap_stride_libero_b.dat",
        "results\libero\project_b\designer\top_b\export\ap_stride_libero_b.ppd",
        "results\libero\libero_status.csv"
    )
}

$vendorNames = @{
    "vivado" = "AMD Vivado"
    "quartus" = "Intel Quartus Prime Pro"
    "libero" = "Microchip Libero SoC"
}

$manifestPath = Join-Path $VariantRoot "variant_manifest.csv"
"variant_id,perturbation_type,changed_artifacts,affected_stage,mapped_threat_ids,variant_path,run_started_utc,run_finished_utc,exit_code" | Set-Content -LiteralPath $manifestPath -Encoding ASCII

foreach ($variant in $variants) {
    $variantDir = Join-Path $VariantRoot $variant.Id
    if ($SkipRuns) {
        if (-not (Test-Path -LiteralPath $variantDir)) {
            throw "Variant folder not found for -SkipRuns: $variantDir"
        }
        $row = @(
            $variant.Id,
            $variant.Type,
            ($variant.ChangedArtifacts -join ";"),
            $variant.AffectedStage,
            $variant.Threats,
            $variantDir,
            "not_rerun",
            (Get-Date).ToUniversalTime().ToString("o"),
            "not_rerun"
        ) | ForEach-Object { CsvEscape $_ }
        Add-Content -LiteralPath $manifestPath -Value ($row -join ",") -Encoding ASCII
    } else {
        Copy-BaselineRuntime -Destination $variantDir
        & $variant.Apply $variantDir

        $started = (Get-Date).ToUniversalTime().ToString("o")
        Push-Location $variantDir
        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $variantDir "run_all.ps1")
        $exitCode = $LASTEXITCODE
        Pop-Location

        $timeoutAt = (Get-Date).AddMinutes(40)
        do {
            $liberoStatus = Get-RunStatus -VariantDir $variantDir -VendorKey "libero"
            if ($liberoStatus -eq "ok") { break }
            Start-Sleep -Seconds 10
        } while ((Get-Date) -lt $timeoutAt)

        $finished = (Get-Date).ToUniversalTime().ToString("o")

        $row = @(
            $variant.Id,
            $variant.Type,
            ($variant.ChangedArtifacts -join ";"),
            $variant.AffectedStage,
            $variant.Threats,
            $variantDir,
            $started,
            $finished,
            [string]$exitCode
        ) | ForEach-Object { CsvEscape $_ }
        Add-Content -LiteralPath $manifestPath -Value ($row -join ",") -Encoding ASCII
    }
}

$tracePath = Join-Path $BaseResults "artifact_perturbation_evidence_trace.csv"
$statusSummaryPath = Join-Path $BaseResults "variant_run_status.csv"

"variant_id,vendor,design_id,perturbation_type,changed_artifact,affected_stage,changed_key_artifacts,total_key_artifacts,missing_key_artifacts,observed_evidence,mapped_threat_ids,audit_result" | Set-Content -LiteralPath $tracePath -Encoding ASCII
"variant_id,vendor,run_status,status_file" | Set-Content -LiteralPath $statusSummaryPath -Encoding ASCII

foreach ($variant in $variants) {
    $variantDir = Join-Path $VariantRoot $variant.Id
    foreach ($vendorKey in @("vivado", "quartus", "libero")) {
        $status = Get-RunStatus -VariantDir $variantDir -VendorKey $vendorKey
        $statusFile = Join-Path $variantDir "results\$vendorKey\${vendorKey}_status.csv"
        $statusRow = @($variant.Id, $vendorNames[$vendorKey], $status, $statusFile) | ForEach-Object { CsvEscape $_ }
        Add-Content -LiteralPath $statusSummaryPath -Value ($statusRow -join ",") -Encoding ASCII

        foreach ($designId in @("A", "B")) {
            $keyList = $keyArtifactsByVendorDesign["$vendorKey|$designId"]
            $comparison = Get-ChangedRelativePaths -VariantDir $variantDir -RelativePaths $keyList
            $changed = @($comparison.Changed)
            $missing = @($comparison.Missing)
            $changedCount = $changed.Count
            $totalCount = $keyList.Count
            $result = if ($status -eq "ok" -and $changedCount -gt 0) { "traceable" } elseif ($status -eq "ok") { "no_downstream_change_observed" } else { "run_incomplete" }
            $evidence = "run_status=$status; changed_key_artifacts=$changedCount/$totalCount; examples=" + (($changed | Select-Object -First 5) -join ";")
            if ($missing.Count -gt 0) {
                $evidence += "; missing=" + (($missing | Select-Object -First 3) -join ";")
            }
            $changedArtifact = if ($variant.Id -eq "constraint_revision") {
                if ($designId -eq "A") {
                    if ($vendorKey -eq "vivado") { "vivado\top.xdc" } else { "$vendorKey\top.sdc" }
                } else {
                    if ($vendorKey -eq "vivado") { "vivado\top_b.xdc" } else { "$vendorKey\top_b.sdc" }
                }
            } else {
                if ($designId -eq "A") { "src\top.v" } else { "src\top_b.v" }
            }
            $row = @(
                $variant.Id,
                $vendorNames[$vendorKey],
                $designId,
                $variant.Type,
                $changedArtifact,
                $variant.AffectedStage,
                [string]$changedCount,
                [string]$totalCount,
                ($missing -join ";"),
                $evidence,
                $variant.Threats,
                $result
            ) | ForEach-Object { CsvEscape $_ }
            Add-Content -LiteralPath $tracePath -Value ($row -join ",") -Encoding ASCII
        }
    }
}

Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $BaseResults "variant_manifest.csv") -Force

if (Test-Path -LiteralPath $ProjectVariantDir) {
    Assert-UnderRoot -Path $ProjectVariantDir -Root $ProjectExpDir
    Remove-Item -LiteralPath $ProjectVariantDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $ProjectVariantDir | Out-Null
Copy-Item -Path (Join-Path $VariantRoot "*") -Destination $ProjectVariantDir -Recurse -Force

function Copy-IfDifferentPath {
    param([string]$Source, [string]$Destination)
    $sourceFull = [System.IO.Path]::GetFullPath($Source)
    $destFull = [System.IO.Path]::GetFullPath($Destination)
    if (-not $sourceFull.Equals($destFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

Copy-IfDifferentPath -Source $tracePath -Destination (Join-Path $ProjectExpDir "results\artifact_perturbation_evidence_trace.csv")
Copy-IfDifferentPath -Source $statusSummaryPath -Destination (Join-Path $ProjectExpDir "results\variant_run_status.csv")
Copy-IfDifferentPath -Source (Join-Path $BaseResults "variant_manifest.csv") -Destination (Join-Path $ProjectExpDir "results\variant_manifest.csv")

Write-Host "Perturbation variants completed."
Write-Host "Runtime variants: $VariantRoot"
Write-Host "Project copy: $ProjectVariantDir"
Write-Host "Trace: $tracePath"
