# Threat-Record Selection Protocol

## Bottom Line

The retained set should be described as 24 evidence-gated threat records, not as a complete FPGA attack catalog. The selection basis is the combination of domain asset decomposition, three-tool baseline evidence, official vendor documentation, candidate filtering, and case validation.

## How Other Threat-Modeling Papers Select or Validate Threats

| Comparator | Selection/evaluation basis | What it validates | Lesson for this paper |
|---|---|---|---|
| Stevens et al. 2018 | Enterprise threat-modeling deployment and operational logs. | Adoption, perceived usefulness, mitigations, and operational outcomes. | Make the validation object explicit; do not claim operational risk reduction without field data. |
| Tuma et al. 2019 | Industrial case-study comparison of threat-analysis procedures. | Comparative productivity, prioritization, and scenario quality. | A method paper needs an explicit protocol and outcome unit even when it does not demonstrate attacks. |
| Wuyts et al. 2014 / LINDDUN | Multiple empirical studies over analysis tasks. | Correctness, completeness, productivity, ease of use, and reliability. | Do not claim analyst usefulness or completeness without participant data. |
| Xiong and Lagerstrom 2019 | Structured literature-review corpus and coding. | Threat-modeling method categories and validation practices. | If using literature as a basis, state the coding scope and do not overclaim PRISMA-grade systematic review. |
| Mauri et al. 2022 | Domain asset decomposition and worked AI/ML use case. | Domain-specific STRIDE reinterpretation and mitigation mapping. | A worked use case is valid when the claim is domain reinterpretation rather than effectiveness. |
| Sassnick et al. 2024 | Review and classification of STRIDE-based domain methodologies. | How STRIDE is adapted across domains. | STRIDE adaptation alone is not novel; the FPGA artifact/provenance schema must carry novelty. |
| Li et al. 2026 UsersFirst | With-taxonomy versus without-taxonomy controlled evaluation. | Taxonomy effect on relevant threats found by analysts. | This paper cannot claim taxonomy effectiveness without human evaluation; use artifact-case validation instead. |
| Space-domain MS-TMT 2026 | Tool specialization, incident/schema mapping, and baseline comparison. | Domain schema coverage against real incidents and a baseline tool. | Use an operational schema, explicit baseline, and case evidence; here the baseline is generic STRIDE and the cases are tool/release artifacts. |

## Selection Basis Used Here

| Basis | Evidence | Count/scope | Selection role |
|---|---|---|---|
| Domain asset decomposition | Seven artifact families: source/IP, simulation/verification, constraint/configuration, transformation state, report/signoff, bitstream/programming, CI/CD release provenance. | 7 artifact families in refined vendor inventory summary. | Only candidates tied to one of these artifact families can be retained. |
| Tool baseline | Vivado, Quartus Prime Pro, and Libero SoC generated artifacts plus vendor-documented flow vocabulary cited in the manuscript. | 1114 refined artifact rows across two controlled designs. | Retained records must map to native tool evidence or explicit project-level provenance evidence. |
| Candidate filtering | excluded_generic_IT=8; excluded_no_evidence_requirement=2; excluded_physical_runtime=7; merged_duplicate=11; retained_distinct=18; rewritten_to_retained=16 | 62 total candidates; 24 retained records. | A candidate is retained only if it satisfies artifact, boundary, attacker capability, evidence, and mitigation criteria. |
| Candidate-source diversity | Artifact-provenance derivation=18; Generic STRIDE prompt=14; FPGA flow prompt=11; FPGA security literature theme=10; Supply-chain prompt=4; Observed artifact family=3; Speculative prompt=2 | Generic STRIDE, FPGA literature themes, FPGA flow prompts, observed artifact families, supply-chain prompts, and speculative prompts. | Generic items are rewritten, duplicate low-level scenarios are merged, and physical/runtime or no-evidence candidates are excluded. |
| Case validation | hdl_revision:AMD Vivado=traceable; hdl_revision:Intel Quartus Prime Pro=traceable; hdl_revision:Microchip Libero SoC=traceable; constraint_revision:AMD Vivado=traceable; constraint_revision:Intel Quartus Prime Pro=traceable; constraint_revision:Microchip Libero SoC=traceable | Six vendor-variant runs, expanded into twelve vendor-design perturbation traces. | Controlled revisions check whether source and constraint changes produce traceable downstream evidence (lineage observed), not that every expected key artifact regenerates. |

## Inclusion and Exclusion Rule

A candidate is retained only when all five conditions are satisfied:

1. It names a protected FPGA toolchain artifact.
2. It crosses or abuses a trust boundary in the FPGA development flow.
3. It states an attacker capability at an auditable level.
4. It has recoverable evidence or an explicit project-level provenance requirement.
5. It maps to a mitigation category.

- Audit-retained distinct scenario rows: 18
- Rewritten candidates: 16
- Merged duplicate candidates: 11
- Excluded candidates: 17
- Reconciled final records: 24 (the 18 audit-distinct rows plus the signing/programming-authority split into BSD-3 and BSD-4, the tool-environment promotion, and four DFD-coverage records)

## Retained IDs

SIP-1, SIP-2, SIP-3, SIM-1, SIM-2, CFG-1, CFG-2, CFG-3, TENV-1, TENV-2, TENV-3, TRN-1, TRN-2, TRN-3, RPT-1, RPT-2, RPT-3, BSD-1, BSD-2, BSD-3, BSD-4, DEP-1, REL-1, REL-2

## Claim Boundary

This protocol supports traceability and internal consistency. It does not prove taxonomy completeness, analyst agreement, exploitability, or security effectiveness. Those claims would require independent coding, participant studies, industrial cases, or incident-ground-truth evaluation.

CSV: `block1_construction_audit/threat_record_selection_protocol.csv`
