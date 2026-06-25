# Candidate Filtering Reconciliation

## Reconciled count: why 24

The candidate audit reduces a 62-row candidate pool to 24 retained core threat records:
18 retained distinct scenarios, 16 rewritten-to-retained candidates, and 11 merged
duplicates, with 17 exclusions (8 generic IT, 7 physical/runtime, 2 no-evidence-requirement);
DFD-coverage reconciliation then adds four records covering simulation-result evidence,
license-state evidence, tool/IP version-update provenance, and programming/readback-status
evidence (18 + 1 split + 1 promotion + 4 = 24). One of the four, the license-state
record TENV-2, is also the mapped destination of the rewritten first-pass candidate
RW-05; it is counted as a reconciliation addition because its license-state evidence
requirement is new.

The count is not an arbitrary target. It follows from evidence decisions that split or
promote records by required evidence requirement:

- `BSD-3` (signing/release authority) vs `BSD-4` (programming-target/deployment authority)
  are separate records because they need different requirements --- signer identity, approval
  record, release manifest vs. target identity, programmer identity, programming log,
  rollback record.
- `TENV-1` (tool-environment identity at the transformation-run boundary): an EDA
  executable, plugin, Tcl package, IP generator, or build container is not generic CI/CD
  background --- it performs the FPGA representation transformation and therefore needs
  tool/image identity evidence.

## Source of truth

Use these files for the 24-record taxonomy:

- `block1_construction_audit/candidate_filtering_study.csv`
- `block1_construction_audit/catalog_24records_audit_snapshot.csv`
- `00_stride_fpga_catalog/full_threat_taxonomy_supplement.csv`
- `00_stride_fpga_catalog/threat_record_schema_full.csv`
- `00_stride_fpga_catalog/threat_evidence_coverage_matrix.csv`
- `00_stride_fpga_catalog/reconciled_taxonomy_gap_decisions.csv`  (creates TENV-1 via GA-05)
- `block1_construction_audit/generic_stride_baseline.csv`  (STRIDE-per-element grid: SIM-2, TENV-3, DEP-1)

## Claim boundary

The 24 records are retained core threat records within the audited candidate pool plus
DFD-coverage reconciliation and evidence-gated artifact-provenance scope. They are not a
complete catalog of all FPGA security threats.
