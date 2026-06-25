# Block 2 — Artifact Grounding in Real Tool Output

Evaluation Block 2 (**EQ2–EQ4**): the 24 records assessed against cross-vendor tool outputs and
project-level provenance evidence over two controlled designs. Tool-generated artifacts ground
transformation, report, configuration, simulation, and bitstream records; tool-environment (TENV)
and deployment (DEP) records require external provenance or deployment evidence not emitted by the
local baseline runs. Backs **Section 6 (Block 2)** and **Supplement Table S7**.

No-tool data check: from the repo root run `python block2_artifact_grounding/verify_block2.py` (1114 inventory, 207/396/504/7 vendor split, 72 recoverability rows, 12 perturbation traces). Full regeneration needs the FPGA tools (see `reproduce/`).

| File / folder | What it is | Backs |
|---|---|---|
| `cross_vendor_artifact_inventory.csv` | **Authoritative 1114-file inventory** across two designs — 207 Vivado / 396 Quartus / 504 Libero / 7 common | frozen **1114** |
| `cross_vendor_threat_evidence_recoverability.csv` | 72 rows (24 records × 3 vendors): native-vs-manifest evidence recoverability | per-record dispositions |
| `artifact_perturbation_evidence_trace.csv` | 12 executed perturbation traces (HDL/constraint revisions change downstream evidence) | perturbation claim |
| `experiment_environment.csv` | Tool versions and environment capture (Vivado 2025.2 / Quartus Prime Pro 26.1 / Libero SoC 2025.2) | environment |
| `variant_manifest.csv`, `variant_run_status.csv` | Six-variant run accounting (all OK) | run accounting |
| `run_all.log` | Timestamped BEGIN/END provenance of the baseline flow (all stages exit=0) | run provenance |
| `status/{vivado,quartus,libero}_status.csv` | Per-stage human-readable run status | per-vendor status |
| `reproduce/` | Regeneration bundle (see below) | reproducibility |
| `sample_outputs/` | Representative **real, sanitized** signoff reports from both controlled designs per vendor (26 files, `design_a/`+`design_b/`); the full set is the inventory CSV | artifact variety |

**`reproduce/`** holds the inputs to regenerate the 1114-file inventory: `src/` RTL for both
designs (`top.v`, `top_b.v` + testbenches), per-vendor constraints and flow scripts
(`vivado/`, `quartus/`, `libero/`), `run_all.ps1`,
`inputs/`, `scripts/`, and its own `README.md`. Requires local **AMD Vivado 2025.2**,
**Intel Quartus Prime Pro 26.1**, **Microchip Libero SoC 2025.2**.

> The full generated-output tree and large vendor project/database files (`.xpr`/`.qpf`/`.prjx`,
> `.dcp`/`.qdb`/`.cdb`) are **not** shipped in bulk — the inventory CSV is their *metadata*, and
> `sample_outputs/` carries a sanitized representative subset (reports/logs). Run
> `reproduce/run_all.ps1` to regenerate the full set locally.

**Notes.** "Traceable" in `artifact_perturbation_evidence_trace.csv` means a controlled revision
produced observable downstream evidence changes with confirmed lineage --- not that every expected
key artifact was regenerated. For example, Quartus design B withholds `top_b.sof` (it carries no
pin/I-O assignments), yet its source-to-report lineage is still observed (`audit_result=traceable`).
`experiment_environment.csv` records run metadata (tool versions/paths/date) for reproducibility and
is not counted as full tool-environment (TENV) evidence, which additionally needs tool/image digests,
plugin/package manifests, license records, and update-state attestations. The per-record
native-vs-provenance split --- including the TENV-1/2/3 and DEP-1 records absent from baseline tool
output --- is in `cross_vendor_threat_evidence_recoverability.csv`. The `mapped_records` column in `reproduce/inputs/tool_api_evidence.csv` is a semantic API-to-record mapping (which record a tool command is relevant to), not a claim that the command emits that record's required evidence requirement; whether each requirement is actually recoverable is reported only in that recoverability file, so a tool command tagged `TENV-1` or `DEP-1` still corresponds to an `absent` requirement here. Finally, `cross_vendor_threat_evidence_recoverability.csv` is the raw per-vendor heuristic (it flags a record `native` when its flow stage emits any artifact); the reconciled per-record evidence-source coding the paper relies on is Supplement Table S3 (G/D/P). For provenance-bound records such as BSD-2, BSD-3, and BSD-4, the raw `native+manifest` status is refined to documented/provenance (no `G`) in S3, consistent with the Block-4 report treating BSD-4 and DEP-1 as gaps.
