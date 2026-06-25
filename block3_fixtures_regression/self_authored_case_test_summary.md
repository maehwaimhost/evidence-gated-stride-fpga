# Self-Authored Artifact-Package Case Tests

## Scope

These tests are self-authored fixtures. They do not use third-party source repositories, downloaded bitstreams, vendor manuals, or copied paper figures. The files are intentionally small placeholders whose purpose is to test whether the 24-record evidence schema exposes complete evidence, missing generated artifacts, digest mismatch, authority gaps, and deployment-record gaps.

## Case Summary

| Case | Description | Files | Families | Status counts |
|---|---|---:|---|---|
| SA-1 complete_self_authored_release | Self-authored package containing source, constraints, tool metadata, transformation state, reports, bitstream placeholder, deployment logs, manifest, approval, and attestation. | 22 | Bitstream/Programming Artifact; CI/CD and Release Provenance; Constraint/Configuration Artifact; Deployment Evidence; Report/Signoff Evidence; Simulation/Verification Artifact; Source/IP Artifact; Tool-Environment Evidence; Transformation/Implementation State | full=24 |
| SA-2 source_only_package | Self-authored source package with HDL, constraints, verification collateral, build scripts, tool metadata, and CI metadata, but no generated reports, bitstream, deployment logs, or release attestation. | 10 | CI/CD and Release Provenance; Constraint/Configuration Artifact; Simulation/Verification Artifact; Source/IP Artifact; Tool-Environment Evidence; Transformation/Implementation State | authority_gap=2, full=10, integrity_gap=2, partial=5, unsupported=5 |
| SA-3 constraint_digest_mismatch | Self-authored release package whose manifest records an incorrect constraint digest, creating a controlled evidence-integrity failure. | 22 | Bitstream/Programming Artifact; CI/CD and Release Provenance; Constraint/Configuration Artifact; Deployment Evidence; Report/Signoff Evidence; Simulation/Verification Artifact; Source/IP Artifact; Tool-Environment Evidence; Transformation/Implementation State | full=19, integrity_gap=5 |
| SA-4 unattributed_bitstream_release | Self-authored package with generated-looking report and bitstream placeholders but no release approval, attestation, or deployment logs. | 17 | Bitstream/Programming Artifact; CI/CD and Release Provenance; Constraint/Configuration Artifact; Report/Signoff Evidence; Simulation/Verification Artifact; Source/IP Artifact; Tool-Environment Evidence; Transformation/Implementation State | authority_gap=3, full=14, integrity_gap=5, partial=1, unsupported=1 |

## Overall Threat-Record Support

| Support status | Count |
|---|---:|
| authority_gap | 5 |
| full | 67 |
| integrity_gap | 12 |
| partial | 6 |
| unsupported | 6 |

## Interpretation

SA-1 is the positive control: all major evidence families are present and linked.
SA-2 is the source-package control: source, constraints, verification, build, tool, and CI metadata exist, but generated reports, bitstreams, deployment logs, and release attestations are absent.
SA-3 is the integrity negative control: required files exist, but the release manifest intentionally records a wrong constraint digest.
SA-4 is the authority/deployment negative control: report and bitstream placeholders exist, but release approval, attestation, programming log, and readback evidence are absent.
