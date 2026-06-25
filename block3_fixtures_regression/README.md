# Block 3 — Fixtures and Schema-Regression Checks

Evaluation Block 3 (**EQ5**): schema behavior on synthetic, self-authored fixtures.
Backs **Section 6 (Block 3)** and **Supplement Table S8**.

## Top-level index / summary files
| File | What it is |
|---|---|
| `self_authored_case_test_matrix.csv` | 96 rows = 4 cases × 24 records — per-record support status (the SA-1…SA-4 controls) |
| `self_authored_case_test_cases.csv` | Per-case presence / digest-match flags |
| `self_authored_case_test_files.csv` | Per-file SHA-256 inventory of the case-test fixtures (71 files) |
| `self_authored_case_test_summary.md` | Human-readable control narrative + aggregate support-status totals |
| `self_authored_injection_benchmark_oracle.csv` | 8 oracle cases (expected vs. detected record ids) |
| `self_authored_injection_benchmark_files.csv` | Per-file SHA-256 inventory of the injection fixtures (77 files) |
| `baseline_and_schema_regression_summary.md` | Combines the 54-baseline split (28/11/15) with the 8 injections |

## `fixtures/` — the EQ5 test corpus
- `self_authored_case_tests/` — **4** mock FPGA release trees: `complete_self_authored_release`,
  `constraint_digest_mismatch`, `source_only_package`, `unattributed_bitstream_release` (71 files)
- `self_authored_injection_benchmark/` — **8** evidence-fault fixtures: `constraint_digest_mismatch`,
  `hdl_digest_mismatch`, `report_digest_mismatch`, `stale_bitstream_rollback`, `tool_option_drift`,
  `wrong_target_programming`, `missing_readback_status`, `unauthorized_release` (77 files)

Each fixture is a mock release tree (`source/ sim/ impl/ reports/ bitstream/ release/ deploy/
tool_env/ …`). Key numbers: **4 + 8** fixtures; matrix **96 = 4 × 24**; **8** oracle cases.

## Reproduce / verify (no tools)

No FPGA tools are needed: the fixtures are synthetic release trees and the oracle is the deterministic expected-vs-detected mapping. From the repo root, `python block3_fixtures_regression/verify_block3.py` automates steps 1–3 below (PASS/FAIL, exit non-zero on mismatch).

1. `self_authored_case_test_matrix.csv` (96 rows = 4 cases × 24 records) grouped by `support_status`: 67 `full`, 12 `integrity_gap`, 5 `authority_gap`, 6 `partial`, 6 `unsupported`.
2. `self_authored_injection_benchmark_oracle.csv` (8 rows): every row has `oracle_status = expected_detected`, with `detected_threat_ids` equal to `expected_threat_ids` (e.g., IB-7 `wrong_target_programming` → `BSD-4; DEP-1`).
3. Fixture file counts: `self_authored_case_test_files.csv` = **71**, `self_authored_injection_benchmark_files.csv` = **77**.
4. Verify each fixture file's SHA-256 against its inventory CSV and `../ARTIFACT_MANIFEST.csv`.
