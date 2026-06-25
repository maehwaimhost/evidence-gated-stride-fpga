# Evidence-Gated STRIDE Threat Modeling for FPGA Development Toolchains — Artifact Package

This repository is the reproducibility artifact package for the manuscript:

> **Evidence-Gated STRIDE Threat Modeling for FPGA Development Toolchains**

It is organized to mirror the paper: one folder for the STRIDE-to-FPGA mapping and the
24-record catalog (the method's *output*), and one folder per evaluation block
(the *checks* on that output). Most files are CSV/JSON/Markdown and can be inspected with no tools.

## Repository layout

| Folder | Contents | Paper location |
|---|---|---|
| `00_stride_fpga_catalog/` | The artifact-level STRIDE mapping and the **24-record evidence-gated catalog**: full per-record fields, the threat-record schema, the seven-family provenance rubric, catalog reconciliation (GA decisions), and the known-threat replay. | Sections 4–5; Supplement Tables S1–S3, S6 |
| `block1_construction_audit/` | **How the 24 were derived.** The 62-candidate audit ledger (18 retained / 16 rewritten / 11 merged / 17 excluded), the 54-question generic STRIDE baseline (28 direct / 11 rewrite / 15 generic), the generic-vs-artifact comparison, and the selection protocol. | Section 6 (Block 1, EQ1); Supplement Tables S4–S5 |
| `block2_artifact_grounding/` | **Artifact grounding in real tool output.** The authoritative cross-vendor inventory of **1114 generated/project files across two controlled designs** (Vivado 2025.2, Quartus Prime Pro 26.1, Libero SoC 2025.2), per-record native-vs-provenance recoverability, the HDL and constraint controlled-revision traces, tool-environment capture, and per-vendor run status. `reproduce/` holds the RTL probe, constraints, and flow scripts to regenerate it. | Section 6 (Block 2, EQ2–EQ4); Supplement Table S7 |
| `block3_fixtures_regression/` | **Schema behavior on synthetic fixtures.** Four self-authored release-package fixtures (`fixtures/self_authored_case_tests/`) and eight evidence-fault schema-regression fixtures (`fixtures/self_authored_injection_benchmark/`), with their case matrix and oracle. | Section 6 (Block 3, EQ5); Supplement Table S8 |
| `block4_cross_vendor_builds/` | **Cross-vendor full builds (public-design applicability).** Eight non-programming full builds of four public designs — two portable cores (PicoRV32, SERV) each through Vivado/Quartus/open-ECP5, and two Microchip PolarFire SoC reference designs (Icicle, Discovery) through Libero — with hashed artifacts and per-build provenance. | Section 6 (Block 4, EQ6); Supplement Table S9 |
| `run_all_checks.py` | **One-command runner** at the package root: runs `validate_counts.py` plus all four `block*_*/verify_block*.py` and prints an overall PASS/FAIL. | — |
| `validate_counts.py` | Top-level standard-library Python that re-checks the frozen counts (`python validate_counts.py`). | — |

Each block folder also contains its own `README.md` describing every file and the paper element it backs.

## Public source designs used (Block 4)

The cross-vendor full builds use four public, commit-pinned designs (no authored RTL). These are
third-party repositories, used unmodified and not redistributed here; clone them at the pinned commit:

| Design | Repository | Pinned commit | License |
|---|---|---|---|
| PicoRV32 (`system`) | https://github.com/YosysHQ/picorv32 | `87c89acc` | ISC |
| SERV (`serv_synth_wrapper`) | https://github.com/olofk/serv | `f5ddfaa6` | ISC |
| PolarFire SoC Icicle Kit Reference Design | https://github.com/polarfire-soc/icicle-kit-reference-design | `fd0aebb9` | MIT |
| PolarFire SoC Discovery Kit Reference Design | https://github.com/polarfire-soc/polarfire-soc-discovery-kit-reference-design | `f09b6e0d` | MIT |

Clone commands and the per-toolchain build recipes are in `block4_cross_vendor_builds/README.md`.

## Expected counts (check against the files)

- **24** core threat records — `00_stride_fpga_catalog/full_threat_taxonomy_supplement.csv`
- **62** candidate-pool rows (18/16/11/17) — `block1_construction_audit/candidate_filtering_study.csv`
- **54** generic STRIDE prompts (28/11/15) — `block1_construction_audit/generic_stride_baseline.csv`
- **1114** classified files across two controlled designs (207 Vivado / 396 Quartus / 504 Libero / 7 common) — `block2_artifact_grounding/cross_vendor_artifact_inventory.csv`
- **71** package-fixture files + **96** package-record checks; **77** schema-regression fixture files + **8** oracle cases — `block3_fixtures_regression/`
- **8** cross-vendor full builds (4 public designs across 4 toolchains) with SHA-256 manifests — `block4_cross_vendor_builds/`

## What this package supports

Traceability of the 24 records to catalog/schema/provenance/replay/selection rows; inspection of every
candidate disposition; comparison of the generic STRIDE baseline against the artifact-boundary-evidence
schema; schema behavior on complete/partial/gap fixtures; and grounding of the catalog's artifact families
in the real generated outputs of cross-vendor full builds of public designs.
It does **not** measure catalog completeness, exploitability, project security, threat-detection
effectiveness, key custody, approval intent, or analyst agreement — those need study designs outside this package.

## Reproduction

**Quickest (one command, no tools):** from this folder run `python run_all_checks.py` — it runs the global
count check and all four per-block verifiers (`block*_*/verify_block*.py`) and prints an overall PASS/FAIL.

- **Level 0 (Python 3, standard library only):** run `python validate_counts.py` to automatically
  check the frozen counts above (24 records, 62 candidates, 54 baseline prompts, 1114 inventory files) and
  that the 24 record identifiers are present; it prints PASS/FAIL per check and exits non-zero on any mismatch.
  Each block folder also has a same-style standard-library checker: `block1_construction_audit/verify_block1.py`
  (disposition/baseline splits + ID match), `block2_artifact_grounding/verify_block2.py` (1114 inventory + vendor
  split + recoverability), `block3_fixtures_regression/verify_block3.py` (matrix split, oracle, fixture counts),
  and `block4_cross_vendor_builds/verify_block4.py` (shipped artifact hashes vs evidence CSVs). Run each from the repo root.
- **Level 1 (no tools):** open the CSV/JSON/Markdown files and confirm the counts above and that the 24
  identifiers are consistent across the catalog folder and the per-record evidence tables.
- **Level 2 (Python 3):** the construction-audit ledger was produced by generator scripts that are *not
  redistributed* (they were tied to an internal flat data layout); the published CSVs, the SHA-256 digests
  in `ARTIFACT_MANIFEST.csv`, and `validate_counts.py` let you verify the reported results directly.
- **Level 3 (commercial and open FPGA tools):** `block2_artifact_grounding/reproduce/` provides the
  tool-layer input bundle (RTL probe, testbench, vendor constraints/settings, Tcl/PowerShell flow scripts,
  and the `run_all.ps1` entry point) that regenerates the 1114-file inventory, and
  `block4_cross_vendor_builds/scripts/` provides the per-toolchain build-flow inputs for the eight public
  builds. AMD Vivado 2025.2, Intel Quartus Prime Pro 26.1, Microchip Libero SoC 2025.2, and an open
  Yosys/nextpnr-ecp5 toolchain are required. Proprietary tool outputs and third-party source are not redistributed.

### Per-block reproduction (step by step)

| Block | How to reproduce | Step-by-step in |
|---|---|---|
| **1 — Construction audit** | No tools: `python block1_construction_audit/verify_block1.py` (disposition/baseline splits, ID match), then verify SHA-256 | `block1_construction_audit/README.md` |
| **2 — Artifact grounding** | No-tool data check: `python block2_artifact_grounding/verify_block2.py` (1114 inventory + vendor split + recoverability). Full rebuild (FPGA tools): set tool paths, run `reproduce/run_all.ps1`, then `scripts/run_perturbation_variants.ps1` | `block2_artifact_grounding/reproduce/README.md` |
| **3 — Fixtures / regression** | No tools: `python block3_fixtures_regression/verify_block3.py` (96-row matrix split 67/12/5/6/6, 8 oracle cases, 71/77 fixture counts), verify fixture SHA-256 | `block3_fixtures_regression/README.md` |
| **4 — Cross-vendor builds** | No-tool data check: `python block4_cross_vendor_builds/verify_block4.py` (shipped artifact hashes vs evidence CSVs). Full rebuild (FPGA tools): clone the 4 public designs at their pinned commits, then run the per-toolchain build scripts | `block4_cross_vendor_builds/README.md` |

The four public source-design repositories and their pinned commits for Block 4 (PicoRV32 `87c89acc`, SERV `f5ddfaa6`, PolarFire SoC Icicle `fd0aebb9`, Discovery `f09b6e0d`) are listed with full GitHub URLs and clone commands in `block4_cross_vendor_builds/README.md`.

## Redistribution boundary

**Included:** paper-authored CSV/Markdown/JSON and Python/PowerShell/Tcl scripts; paper-owned fixtures
(including synthetic placeholder `.bit` files used only for evidence-gap tests); generated metadata,
manifests, labels, hashes, per-build artifact digests. **Excluded:** downloaded
research-paper PDFs, extracted paper text, vendor documentation bodies, third-party source trees/HDL, and
proprietary tool output trees. The cross-vendor full builds are reproducible through recorded commit ids,
build scripts, and SHA-256 digests rather than by redistributing third-party source.

`ARTIFACT_MANIFEST.csv` lists every package file (except the manifest itself) with its size and SHA-256 digest.
