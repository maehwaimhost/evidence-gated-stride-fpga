# Block 1 — Construction Audit (how the 24 were derived)

Evaluation Block 1 (**EQ1**): the auditable trail from the candidate pool to the final
24 records. Backs **Section 6 (Block 1)** and **Supplement Tables S4–S5**.

| File | What it is | Backs |
|---|---|---|
| `candidate_filtering_study.csv` | **62-candidate audit ledger** — 18 retained_distinct / 16 rewritten_to_retained / 11 merged_duplicate / 17 excluded (8 generic_IT + 7 physical_runtime + 2 no_evidence_requirement) | Supplement S4; frozen **62** |
| `generic_stride_baseline.csv` | **54-question generic-STRIDE baseline** — 28 direct / 11 requires-rewrite / 15 generic (9 record-groups × 6 STRIDE) | Supplement S5; frozen **54** |
| `generic_stride_vs_artifact_provenance_stride.csv` | Head-to-head: 9 generic-STRIDE rows (retain/rewrite/remove) vs. 24 artifact-provenance rows under Definition 1 | §4 generic-vs-provenance contrast |
| `catalog_24records_audit_snapshot.csv` | The 24-record catalog (construction-audit snapshot, carries `artifact_family`) | frozen **24** |
| `threat_record_selection_protocol.csv` | Selection-basis + comparator-pattern table (5 paper-basis + 8 comparator rows) | §6.1 selection protocol |
| `threat_record_selection_protocol.md` | Narrative selection protocol (basis, inclusion/exclusion rule, retained ids, claim boundary) | §6.1 |
| `candidate_filtering_reconciliation.md` | Why the reconciled count is 24: the 62-candidate pool yields 18 first-pass scenario rows plus 6 completeness-pass records, all under Definition 1 | §5 reconciliation |

Note: `catalog_24records_audit_snapshot.csv` is the 24-record catalog (with an added
`artifact_family` column); `threat_record_selection_protocol.csv`/`.md` are the
selection-basis and comparator table/narrative. They are distinct files.

## Reproduce / verify (no tools)

The construction generator scripts are not redistributed (root README, Level 2); these CSVs plus the SHA-256 digests in `../ARTIFACT_MANIFEST.csv` are the verifiable record.

1. From the repo root, `python validate_counts.py` confirms the frozen counts, and `python block1_construction_audit/verify_block1.py` automates steps 2–4 below (PASS/FAIL, exit non-zero on mismatch).
2. `candidate_filtering_study.csv` (62 rows) grouped by `disposition`: 18 `retained_distinct`, 16 `rewritten_to_retained`, 11 `merged_duplicate`, 8 `excluded_generic_IT`, 7 `excluded_physical_runtime`, 2 `excluded_no_evidence_requirement` (8+7+2 = 17 excluded).
3. `generic_stride_baseline.csv` (54 rows) grouped by `baseline_status`: 28 direct, 11 requires-rewrite, 15 generic (the 15 generic rows have an empty `mapped_retained_threat_ids`).
4. The 24 IDs in `catalog_24records_audit_snapshot.csv` match `00_stride_fpga_catalog/full_threat_taxonomy_supplement.csv`.
5. Verify any file's integrity: its SHA-256 must match the row in `../ARTIFACT_MANIFEST.csv`.
