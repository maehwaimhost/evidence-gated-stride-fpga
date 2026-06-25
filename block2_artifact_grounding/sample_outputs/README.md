# Block 2 — Sample Generated Outputs (representative)

Real signoff/report outputs from **both controlled designs** (design A = single-clock
probe; design B = dual-clock CDC/async-FIFO) across the three commercial flows, copied
verbatim from the evaluation run and **sanitized** (absolute build paths replaced with
`<PROJECT_ROOT>`, build host with `<HOST>`). They show the key reports each flow emits.

This is a curated **representative set (26 reports), not the full output tree.** The
complete per-vendor, per-design inventory of all **1114** generated/project files — with
artifact family, role, size, and SHA-256 — is in `../cross_vendor_artifact_inventory.csv`
(every entry was verified against its recorded digest: 1112/1112 match, the remaining two
being the self-referential inventory and run log). Large vendor-proprietary database and
checkpoint binaries (`.qdb`, `.dcp`, `.cdb`, `.qmsgdb`, ...) are documented there by digest
but **not redistributed**: they cannot be text-sanitized and are tool-version-locked with
low standalone reuse value.

Layout: `<vendor>/design_a/` and `<vendor>/design_b/`.

| Vendor | Reports per design |
|---|---|
| `vivado/` — AMD Vivado 2025.2 | utilization, clock-utilization, DRC, timing-summary reports + implementation log |
| `quartus/` — Intel Quartus Prime Pro 26.1 | fit / STA / synthesis summaries + DRC report |
| `libero/` — Microchip Libero SoC 2025.2 | delay-instance + multi-corner timing reports, net report, SDC-error log |

These map to artifact families **F4** (transformation/implementation state) and **F5**
(report/signoff). Bitstream/programming artifacts (F6) for full builds are in
`../../block4_cross_vendor_builds/`.
