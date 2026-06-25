# 00 — STRIDE↔FPGA Mapping and the 24-Record Catalog

The method's **output**: the artifact-level STRIDE-to-FPGA mapping and the 24-record
evidence-gated threat catalog. Backs **Sections 4–5** and **Supplement Tables S1–S3, S6**.

| File | What it is | Backs |
|---|---|---|
| `full_threat_taxonomy_supplement.csv` | The **24-record catalog** (id, group, STRIDE, artifact, boundary, scenario, evidence requirement, mitigation, artifact family, …) | Supplement S1/S2; frozen **24** |
| `threat_record_schema_full.csv` | Full per-record schema — the 22-column master superset (adds verification method, assumption, limitation, detection/prevention evidence, …) | Record schema (§4.4) |
| `threat_evidence_coverage_matrix.csv` | Per-record required evidence + the evidence-gating inclusion rule | S3 basis (also copied to `block2/reproduce/inputs/`) |
| `fpga_toolchain_provenance_rubric.csv` | The seven evidence-requirement families × flow-stage provenance rubric (flow stage → record ids) | §4.5 / system model (S6) |
| `known_threat_replay.csv` | Known-threat-surface → record-disposition replay (10 rows) | Body Table (known-threat replay) |
| `reconciled_taxonomy_gap_decisions.csv` | GA-03…GA-13 reconciliation / DFD-coverage gap decisions | §5 subcases / Supplement Part D |

The three 24-row CSVs are **not** duplicates — each surfaces a different projection of the
same 24 records (catalog rows vs. required-evidence gating rule
vs. full master schema).

**Tool-environment records (seven families, not eight).** TENV-1/2/3 are *cross-cutting*
tool-environment evidence (paper §3.1), not a separate artifact family. Their `artifact_family`
is recorded as `constraint_configuration` (F3), the dominant build-configuration/environment class;
per paper §3.1 this evidence is cross-cutting and also draws from F7 (release-automation), so the
single-valued column records F3 as the primary class while the `group` field keeps them as *Tool Environment*. The
`artifact_family` column therefore spans exactly the seven families F1–F7.
