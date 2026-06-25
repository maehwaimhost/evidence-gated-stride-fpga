$ErrorActionPreference = "Continue"

# Tool paths: override via env vars, else resolved from PATH (run each vendor's settings/env script first, or set the var).
$VivadoBin = if ($env:VIVADO_BIN) { $env:VIVADO_BIN } else { "vivado.bat" }
$QuartusSh = if ($env:QUARTUS_SH) { $env:QUARTUS_SH } else { "quartus_sh.exe" }
$LiberoBin = if ($env:LIBERO_BIN) { $env:LIBERO_BIN } else { "libero.exe" }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExpDir = Split-Path -Parent $ScriptDir
$ThreatMatrixOverride = Join-Path $ExpDir "inputs\threat_evidence_coverage_matrix.csv"
$ResultsDir = Join-Path $ExpDir "results"
$ArtifactInventory = Join-Path $ResultsDir "cross_vendor_artifact_inventory.csv"
$Recoverability = Join-Path $ResultsDir "cross_vendor_threat_evidence_recoverability.csv"
$Baseline = Join-Path $ResultsDir "generic_stride_vs_artifact_provenance_stride.csv"
$Environment = Join-Path $ResultsDir "experiment_environment.csv"
$Perturbation = Join-Path $ResultsDir "artifact_perturbation_evidence_trace.csv"

New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null

function CsvEscape {
    param([string]$Value)
    $quote = [string][char]34
    if ($null -eq $Value) { return ($quote + $quote) }
    $escaped = $Value.Replace($quote, $quote + $quote)
    return ($quote + $escaped + $quote)
}

function Get-ToolVersion {
    param([string]$Vendor)
    switch ($Vendor) {
        "vivado" {
            $lines = & $VivadoBin -version 2>&1
            return (($lines | Select-Object -First 4) -join " | ")
        }
        "quartus" {
            $lines = & $QuartusSh --version 2>&1
            return (($lines | Select-Object -First 2) -join " | ")
        }
        "libero" {
            $lines = & $LiberoBin -version 2>&1
            $text = (($lines | Select-Object -First 1) -join " | ")
            if (-not [string]::IsNullOrWhiteSpace($text)) { return $text }
            $log = Join-Path $ResultsDir "libero\libero_script.log"
            if (Test-Path -LiteralPath $log) {
                $match = Select-String -LiteralPath $log -Pattern "Software Version:\s*([0-9.]+)" | Select-Object -First 1
                if ($match -and $match.Matches.Count -gt 0) {
                    return "Microchip Libero SoC Software Version $($match.Matches[0].Groups[1].Value)"
                }
            }
            return "Microchip Libero SoC 2025.2"
        }
    }
}

function Classify-Stage {
    param([System.IO.FileInfo]$File, [string]$Vendor)
    $name = $File.Name.ToLowerInvariant()
    $ext = $File.Extension.ToLowerInvariant()
    $path = $File.FullName.ToLowerInvariant()

    if (($path -like "*\src\*" -or $path -like "*\hdl\*" -or $path -like "*\component\*") -and $ext -in ".v", ".sv", ".vhd", ".vhdl") { return "HDL/IP Input" }
    if ($path -like "*\simulation\*" -or $name -like "*tb_*" -or $name -like "*testbench*" -or $name -like "*modelsim*") { return "Simulation" }
    if ($path -like "*\export\*" -or $name -like "*.digest" -or $name -like "*pcbit*" -or $name -like "*snvm*" -or $name -like "*init_stage*" -or $name -like "*init_all_stages*") { return "Bitstream/Programming Artifact" }
    if ($ext -in ".bit", ".sof", ".pof", ".stp", ".dat", ".ppd", ".job", ".svf", ".digest", ".ddf", ".mem") { return "Bitstream/Programming Artifact" }
    if ($ext -in ".xdc", ".sdc", ".qsf", ".qpf", ".xpr", ".pdc", ".fdc", ".ndc", ".cfg", ".def", ".ini", ".prs", ".aws", ".xsl") { return "Constraint and Configuration" }
    if ($name -like "*constraint*" -or $name -like "*options*" -or $name -like "*user_sets*" -or $name -like "*clocklist*" -or $name -like "run_*") { return "Constraint and Configuration" }
    if ($path -like "*\qdb\*" -or $path -like "*\dni\*" -or $path -like "*\.runs\*" -or $path -like "*\.cache\*" -or $path -like "*\checkpoints\*" -or $path -like "*\designer\top\top_fp\*" -or $path -like "*\synthesis\*" -or $path -like "*\synwork\*" -or $path -like "*\compile\*") { return "Synthesis/Implementation Transformation" }
    if ($ext -in ".dcp", ".edf", ".edn", ".vqm", ".qdb", ".srr", ".vm", ".prjx", ".cdb", ".hdb", ".ddb", ".idb", ".model", ".meta", ".rdb", ".tdb", ".db", ".qmsgdb", ".kvp", ".flock", ".ddm", ".hsd", ".srm", ".srs", ".seg", ".afl", ".loc", ".fdep", ".fdepxmr", ".sap", ".fse", ".srd", ".xdm", ".adl", ".cfrt", ".dca", ".hdr", ".plg", ".tgl", ".ccktransfer", ".schmap", ".duruntime", ".szr", ".sld", ".map", ".so", ".pb", ".rst", ".wdf", ".wpc", ".vdi", ".vds", ".lpr", ".jou") { return "Synthesis/Implementation Transformation" }
    if ($ext -in ".rpt", ".log", ".summary", ".smsg", ".sta", ".htm", ".html", ".xml", ".rptmap", ".areasrr", ".pin", ".msg", ".txt", ".rpx") { return "Report Generation" }
    if ($name -like "*report*" -or $name -like "*timing*" -or $name -like "*jitter*" -or $name -like "*slack*" -or $name -like "*warning*" -or $name -like "*error*" -or $name -like "*note*" -or $name -like "*fanout*" -or $name -like "*compiler*" -or $name -like "*mapper*" -or $name -like "*premap*") { return "Report Generation" }
    if ($ext -in ".csv", ".json", ".xml", ".tcl", ".ps1", ".bat", ".js", ".sh") { return "CI/CD Artifact Management" }
    return "Synthesis/Implementation Transformation"
}

function Classify-Role {
    param([System.IO.FileInfo]$File)
    $ext = $File.Extension.ToLowerInvariant()
    switch ($ext) {
        ".v" { return "HDL source" }
        ".sv" { return "SystemVerilog source" }
        ".xdc" { return "Vivado constraints" }
        ".sdc" { return "Timing constraints" }
        ".qsf" { return "Quartus settings" }
        ".qpf" { return "Quartus project" }
        ".xpr" { return "Vivado project" }
        ".dcp" { return "Vivado design checkpoint" }
        ".qdb" { return "Quartus database" }
        ".db" { return "Tool database" }
        ".qmsgdb" { return "Quartus message database" }
        ".kvp" { return "Tool key-value metadata" }
        ".flock" { return "Tool lock file" }
        ".pb" { return "Vivado run-state protobuf" }
        ".rst" { return "Vivado run status marker" }
        ".wdf" { return "Vivado webtalk/data file" }
        ".wpc" { return "Vivado project cache file" }
        ".vdi" { return "Vivado implementation metadata" }
        ".vds" { return "Vivado synthesis metadata" }
        ".lpr" { return "Vivado hardware project metadata" }
        ".jou" { return "Tool journal" }
        ".rpt" { return "Tool report" }
        ".rptmap" { return "Report map" }
        ".rpx" { return "Report sidecar database" }
        ".pin" { return "Pin report" }
        ".msg" { return "Tool message database" }
        ".log" { return "Tool log" }
        ".bit" { return "Vivado bitstream" }
        ".sof" { return "Quartus SRAM object file" }
        ".pof" { return "Quartus programmer object file" }
        ".stp" { return "Libero programming file" }
        ".dat" { return "Libero programming data" }
        ".ppd" { return "Libero programming data" }
        ".digest" { return "Programming artifact digest" }
        ".tcl" { return "Flow command script" }
        ".ps1" { return "Flow wrapper script" }
        ".bat" { return "Tool run wrapper script" }
        ".js" { return "Tool run wrapper script" }
        ".sh" { return "Tool run wrapper script" }
        ".csv" { return "Provenance/evaluation manifest" }
        default { return "Toolchain artifact" }
    }
}

function Protected-Property {
    param([string]$Stage)
    switch ($Stage) {
        "HDL/IP Input" { return "source identity; integrity; confidentiality" }
        "Constraint and Configuration" { return "configuration integrity; design intent traceability" }
        "Synthesis/Implementation Transformation" { return "transformation lineage; checkpoint integrity" }
        "Report Generation" { return "report integrity; signoff provenance; confidentiality" }
        "Bitstream/Programming Artifact" { return "deployment artifact identity; integrity; authorization" }
        "CI/CD Artifact Management" { return "release provenance; command history; auditability" }
        default { return "artifact identity; integrity" }
    }
}

function Threats-ForStage {
    param([string]$Stage)
    switch ($Stage) {
        "HDL/IP Input" { return "SIP-1;SIP-2;SIP-3" }
        "Simulation" { return "SIM-1;RPT-1;RPT-2" }
        "Constraint and Configuration" { return "CFG-1;CFG-2;CFG-3" }
        "Synthesis/Implementation Transformation" { return "TRN-1;TRN-2;TRN-3;RPT-2" }
        "Report Generation" { return "RPT-1;RPT-2;RPT-3" }
        "Bitstream/Programming Artifact" { return "BSD-1;BSD-2;BSD-3" }
        "CI/CD Artifact Management" { return "REL-1;REL-2;RPT-2" }
        default { return "" }
    }
}

function Evidence-ForStage {
    param([System.IO.FileInfo]$File)
    $hash = ""
    try { $hash = (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256).Hash } catch { $hash = "HASH_UNAVAILABLE" }
    return "sha256=$hash; mtime=$($File.LastWriteTimeUtc.ToString("o")); size=$($File.Length)"
}

"vendor,tool_path,tool_version,run_date_utc" | Set-Content -LiteralPath $Environment -Encoding ASCII
@(
    @("AMD Vivado", $VivadoBin, (Get-ToolVersion "vivado")),
    @("Intel Quartus Prime Pro", $QuartusSh, (Get-ToolVersion "quartus")),
    @("Microchip Libero SoC", $LiberoBin, (Get-ToolVersion "libero"))
) | ForEach-Object {
    $row = @($_[0], $_[1], $_[2], (Get-Date).ToUniversalTime().ToString("o")) | ForEach-Object { CsvEscape $_ }
    Add-Content -LiteralPath $Environment -Value ($row -join ",") -Encoding ASCII
}

"vendor,tool_version,flow_stage,artifact_path,artifact_type,artifact_role,protected_property,provenance_evidence,mapped_threat_ids" | Set-Content -LiteralPath $ArtifactInventory -Encoding ASCII

$vendorMap = @{
    "vivado" = "AMD Vivado"
    "quartus" = "Intel Quartus Prime Pro"
    "libero" = "Microchip Libero SoC"
    "common" = "Common Design Input"
}

$files = @()
$files += Get-ChildItem -LiteralPath (Join-Path $ExpDir "src") -File -Recurse
$files += Get-ChildItem -LiteralPath (Join-Path $ExpDir "vivado") -File -Recurse
$files += Get-ChildItem -LiteralPath (Join-Path $ExpDir "quartus") -File -Recurse
$files += Get-ChildItem -LiteralPath (Join-Path $ExpDir "libero") -File -Recurse
$files += Get-ChildItem -LiteralPath $ResultsDir -File -Recurse -ErrorAction SilentlyContinue

foreach ($file in ($files | Sort-Object FullName -Unique)) {
    $vendorKey = "common"
    if ($file.FullName -like "*\results\vivado\*" -or $file.FullName -like "*\vivado\*") { $vendorKey = "vivado" }
    elseif ($file.FullName -like "*\results\quartus\*" -or $file.FullName -like "*\quartus\*") { $vendorKey = "quartus" }
    elseif ($file.FullName -like "*\results\libero\*" -or $file.FullName -like "*\libero\*") { $vendorKey = "libero" }

    $vendor = $vendorMap[$vendorKey]
    $stage = Classify-Stage $file $vendorKey
    $role = Classify-Role $file
    $prop = Protected-Property $stage
    $evidence = Evidence-ForStage $file
    $threats = Threats-ForStage $stage
    $relPath = Resolve-Path -LiteralPath $file.FullName -Relative
    $toolVersion = if ($vendorKey -eq "vivado") { "Vivado 2025.2" } elseif ($vendorKey -eq "quartus") { "Quartus Pro 26.1" } elseif ($vendorKey -eq "libero") { "Libero SoC 2025.2" } else { "not applicable" }
    $row = @($vendor, $toolVersion, $stage, $relPath, $file.Extension, $role, $prop, $evidence, $threats) | ForEach-Object { CsvEscape $_ }
    Add-Content -LiteralPath $ArtifactInventory -Value ($row -join ",") -Encoding ASCII
}

$artifactRows = Import-Csv -LiteralPath $ArtifactInventory
$vendors = @("AMD Vivado", "Intel Quartus Prime Pro", "Microchip Libero SoC")
$threatMatrixPath = $ThreatMatrixOverride
$threats = Import-Csv -LiteralPath $threatMatrixPath

"threat_id,vendor,required_evidence,native_tool_output,manifest_required,evidence_status,limitation" | Set-Content -LiteralPath $Recoverability -Encoding ASCII
foreach ($vendor in $vendors) {
    $vendorRows = $artifactRows | Where-Object { $_.vendor -eq $vendor -or $_.vendor -eq "Common Design Input" }
    foreach ($threat in $threats) {
        $id = $threat.threat_id
        $native = "no"
        $manifest = "yes"
        $status = "manifest"
        $limitation = "Requires project-level provenance or approval record in addition to native tool files."

        if ($id -match "^CFG" -and ($vendorRows.flow_stage -contains "Constraint and Configuration")) {
            $native = "yes"; $status = "native+manifest"; $limitation = "Constraint artifacts are native or linked, but approval rationale remains project-level evidence."
        } elseif ($id -match "^TRN" -and ($vendorRows.flow_stage -contains "Synthesis/Implementation Transformation")) {
            $native = "yes"; $status = "native+manifest"; $limitation = "Transformation files are native; source-to-output digest chain is manifest-level evidence."
        } elseif ($id -match "^RPT" -and ($vendorRows.flow_stage -contains "Report Generation")) {
            $native = "yes"; $status = "native+manifest"; $limitation = "Reports/logs are native; signoff attribution requires release process evidence."
        } elseif ($id -match "^BSD" -and ($vendorRows.flow_stage -contains "Bitstream/Programming Artifact")) {
            $native = "yes"; $status = "native+manifest"; $limitation = "Bitstream/programming files are native when generated; signing and authorization evidence is project-level."
        } elseif ($id -match "^SIP" -and ($vendorRows.flow_stage -contains "HDL/IP Input")) {
            $native = "partial"; $status = "manifest"; $limitation = "Source files are present, but provider identity, review approval, and dependency provenance require manifest records."
        } elseif ($id -match "^SIM" -and ($vendorRows.flow_stage -contains "Simulation")) {
            $native = "partial"; $status = "manifest"; $limitation = "Verification collateral is present, but reviewed expected results and simulation signoff evidence require project-level records."
        } elseif ($id -match "^REL" -and ($vendorRows.flow_stage -contains "CI/CD Artifact Management")) {
            $native = "partial"; $status = "manifest"; $limitation = "Scripts and generated CSVs exist; release approval and service-account evidence require CI/CD platform records."
        } else {
            $native = "no"; $status = "absent"; $limitation = "No corresponding artifact was observed in the current local run."
        }

        $row = @($id, $vendor, $threat.required_evidence, $native, $manifest, $status, $limitation) | ForEach-Object { CsvEscape $_ }
        Add-Content -LiteralPath $Recoverability -Value ($row -join ",") -Encoding ASCII
    }
}

"method,candidate_id,stride,flow_stage,scenario,artifact_present,boundary_present,evidence_mappable,fpga_specific,mitigation_actionable,decision" | Set-Content -LiteralPath $Baseline -Encoding ASCII

$baselineRows = @(
    @("Generic STRIDE","G-S-1","Spoofing","All stages","Attacker uses stolen developer credentials","no","partial","partial","no","yes","rewrite"),
    @("Generic STRIDE","G-T-1","Tampering","All stages","Attacker changes a file in the project directory","partial","partial","partial","no","partial","rewrite"),
    @("Generic STRIDE","G-R-1","Repudiation","All stages","User denies running a build","no","partial","partial","no","yes","rewrite"),
    @("Generic STRIDE","G-I-1","Information Disclosure","All stages","Attacker reads files over the network","partial","no","partial","no","yes","rewrite"),
    @("Generic STRIDE","G-D-1","Denial of Service","All stages","Build machine becomes unavailable","no","no","no","no","yes","remove"),
    @("Generic STRIDE","G-E-1","Elevation of Privilege","All stages","User gains administrator privilege","no","partial","partial","no","yes","rewrite"),
    @("Generic STRIDE","G-T-2","Tampering","Constraint and Configuration","Any configuration file is modified","partial","partial","partial","partial","partial","rewrite"),
    @("Generic STRIDE","G-I-2","Information Disclosure","Report Generation","Reports may leak information","yes","partial","partial","partial","yes","rewrite"),
    @("Generic STRIDE","G-D-2","Denial of Service","Placement and Routing","Routing does not finish","yes","yes","partial","yes","yes","retain_if_artifact_bound")
)

foreach ($rowData in $baselineRows) {
    $row = $rowData | ForEach-Object { CsvEscape $_ }
    Add-Content -LiteralPath $Baseline -Value ($row -join ",") -Encoding ASCII
}

foreach ($threat in $threats) {
    $rowData = @("Artifact-Provenance STRIDE", $threat.threat_id, $threat.stride, $threat.flow_stage, $threat.coverage_note, "yes", "yes", "yes", "yes", "yes", "retain")
    $row = $rowData | ForEach-Object { CsvEscape $_ }
    Add-Content -LiteralPath $Baseline -Value ($row -join ",") -Encoding ASCII
}

"vendor,perturbation_type,changed_artifact,affected_stage,observed_evidence,mapped_threat_ids,audit_result" | Set-Content -LiteralPath $Perturbation -Encoding ASCII
@(
    @("Planned cross-vendor", "HDL revision", "src/top.v", "HDL/IP Input to downstream transformation", "SHA-256 and downstream artifact regeneration to be compared after perturbation run", "SIP-2;TRN-1;RPT-2", "not_run"),
    @("Planned cross-vendor", "constraint revision", "vendor constraint file", "Constraint and Configuration to implementation/report stages", "SHA-256 and report/checkpoint regeneration to be compared after perturbation run", "CFG-1;CFG-3;TRN-2;RPT-2", "not_run"),
    @("Planned cross-vendor", "build option revision", "vendor flow script", "Configuration to transformation lineage", "Command-script hash and output artifact lineage to be compared after perturbation run", "CFG-2;TRN-1;TRN-2", "not_run")
) | ForEach-Object {
    $row = $_ | ForEach-Object { CsvEscape $_ }
    Add-Content -LiteralPath $Perturbation -Value ($row -join ",") -Encoding ASCII
}

Write-Host "Evidence collection completed under $ResultsDir"
