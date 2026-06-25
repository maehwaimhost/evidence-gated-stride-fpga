# Generic STRIDE Baseline and Self-Authored Schema-Regression Suite

## Scope

The generic STRIDE baseline is a mechanical 9-stage by 6-category prompt grid. It is not a human analyst study. The schema-regression suite uses only self-authored fixture files and intentionally injected evidence faults.

## Generic STRIDE Baseline Counts

| Status | Count |
|---|---:|
| direct_retained | 28 |
| generic_or_no_distinct_record | 15 |
| requires_artifact_rewrite | 11 |
| total | 54 |

## Schema-Regression Suite Counts

- Schema-regression cases: 8
- Generated fixture files: 77
- Oracle status counts: {'expected_detected': 8}

| Injection | Expected records | Failed or missing checks | Oracle status |
|---|---|---|---|
| IB-1 hdl_digest_mismatch | SIP-2; RPT-2 | source_digest_match | expected_detected |
| IB-2 constraint_digest_mismatch | CFG-1; RPT-2 | constraint_digest_match | expected_detected |
| IB-3 tool_option_drift | CFG-2; TENV-3 | tool_options_digest_match | expected_detected |
| IB-4 report_digest_mismatch | RPT-1; RPT-2 | report_digest_match | expected_detected |
| IB-5 stale_bitstream_rollback | BSD-1; RPT-2 | bitstream_digest_match | expected_detected |
| IB-6 unauthorized_release | BSD-3; REL-2 | release_approval_present; release_attestation_present | expected_detected |
| IB-7 wrong_target_programming | BSD-4; DEP-1 | target_match | expected_detected |
| IB-8 missing_readback_status | DEP-1 | readback_status_present | expected_detected |
