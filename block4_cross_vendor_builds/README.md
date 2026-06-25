# Block 4 — Cross-Vendor Full Builds

Evaluation Block 4 (**EQ6**): non-programming full builds of public FPGA designs through the
three audited commercial flows plus an open Yosys/nextpnr ECP5 flow. Backs **Section 6 (Block 4)**
and **Supplement Table S9**. **8 builds across 4 public designs and 4 toolchains.**

No-tool data check: from the repo root run `python block4_cross_vendor_builds/verify_block4.py` (confirms the 8 build-evidence manifests and that every shipped `bitstreams/` artifact's SHA-256 is recorded in them). Full rebuild needs the FPGA tools (see Reproduce below).

**Evidence depth vs Block 2.** Block 2 ships a *complete* per-file inventory (all 1114 generated files mapped to the seven artifact families) because its controlled designs make a full census feasible and that completeness is its claim. Block 4 instead records *representative* hashed artifacts per build, because its claim is cross-vendor *applicability* — that the catalog's build-observable records (TRN-1–TRN-3 and BSD-1 in all builds; CFG-1–CFG-3 and RPT-1 in the commercial flows) re-emerge in real public-design builds — not an exhaustive file census of much larger third-party builds.

Two portable soft cores (PicoRV32 `system`, SERV `serv_synth_wrapper`) are each built through
AMD Vivado, Intel Quartus, and the open Yosys/nextpnr ECP5 flow (holding each design fixed while
varying the toolchain isolates the vendor variable); two Microchip PolarFire SoC reference designs
(Icicle Kit, Discovery Kit) are built through Libero SoC.

| File | What it is |
|---|---|
| `build1_icicle_evidence.csv` | Microchip **Libero SoC 2025.2** — polarfire-soc/icicle (SHA-256 manifest) |
| `build2_picorv32_quartus_evidence.csv` | Intel **Quartus Prime Pro 26.1** — YosysHQ/picorv32 |
| `build3_picorv32_vivado_evidence.csv` | AMD **Vivado 2025.2** — YosysHQ/picorv32 |
| `build4_picorv32_ecp5_evidence.csv` | Lattice — open **Yosys + nextpnr-ecp5 + ecppack** — YosysHQ/picorv32 |
| `build5_serv_quartus_evidence.csv` | Intel **Quartus Prime Pro 26.1** — olofk/serv |
| `build6_serv_vivado_evidence.csv` | AMD **Vivado 2025.2** — olofk/serv |
| `build7_serv_ecp5_evidence.csv` | Lattice — open **Yosys + nextpnr-ecp5 + ecppack** — olofk/serv |
| `build8_discovery_libero_evidence.csv` | Microchip **Libero SoC 2025.2** — polarfire-soc/discovery-kit |
| `bitstreams/` | Programming deliverables: `build1_icicle.job`, `build2_picorv32_quartus.sof`, `build3_picorv32_vivado.bit`, `build4_picorv32_ecp5.bit`, `build5_serv_quartus.sof`, `build6_serv_vivado.bit`, `build7_serv_ecp5.bit`, `build8_discovery.job` (Discovery FlashPro programming job, exported via `export_prog_job`) |
| `scripts/` | Per-toolchain build-flow inputs: PicoRV32/Icicle (`build_vivado.tcl`, `synth.ys`, `drive_icicle_full.tcl`, `drive_icicle_flow2.tcl`, `picorv32_sys.qpf/.qsf`, `clk.xdc`, `firmware.hex`) and SERV/Discovery (`serv_build_vivado.tcl`, `serv_synth_ecp5.ys`, `serv_quartus.qsf`, `serv_clk.xdc`, `drive_discovery.tcl`) |
| `BLOCK4_FULLBUILD_REPORT.md` | Build provenance, scope, and caveats |
| `icicle_build_provenance.txt` | Build-1 commit pin (fd0aebb9…), device, script args |

All builds are commit-pinned and run without modifying third-party repo sources (no authored RTL:
each build uses a repo-provided or vendor-provided top — PicoRV32's `system`, SERV's shipped
`serv_synth_wrapper`, and the Microchip reference designs). The eight build-evidence CSVs are the
SHA-256 hash manifests cited verbatim in **Supplement Table S9**.

## What `scripts/` contains (author-written build inputs, not third-party RTL)

`scripts/` holds the per-design, per-toolchain build *recipes* this paper authored to build the four
public designs board-lessly. It contains **no third-party source** — it only drives the cloned repos at
`REPO_ROOT/block4_builds/<design>/`. The actual RTL comes from the four public repositories listed below.

| File | Design | Toolchain | Role |
|---|---|---|---|
| `build_vivado.tcl` | PicoRV32 | AMD Vivado | non-project flow: synth -> opt -> place -> route -> `write_bitstream` (Artix-7) |
| `synth.ys` | PicoRV32 | open Yosys (ECP5) | `synth_ecp5` to JSON for nextpnr |
| `picorv32_sys.qpf` / `.qsf` | PicoRV32 | Intel Quartus | project + settings (device, file list, virtual pins) for `quartus_sh --flow compile` |
| `clk.xdc` | PicoRV32 | Vivado | 10 ns clock constraint |
| `firmware.hex` | PicoRV32 | build input | 4096-word NOP memory image read by the repo's `system` top via `$readmemh` |
| `serv_build_vivado.tcl` | SERV | AMD Vivado | non-project flow to `write_bitstream` |
| `serv_synth_ecp5.ys` | SERV | open Yosys (ECP5) | `synth_ecp5` to JSON |
| `serv_quartus.qsf` | SERV | Intel Quartus | settings (file list, virtual pins) |
| `serv_clk.xdc` | SERV | Vivado | clock constraint |
| `drive_icicle_full.tcl` | Icicle Kit | Microchip Libero | generate the reference design from the repo Tcl, then SYNTHESIZE / PLACEROUTE / VERIFYTIMING / GENERATEPROGRAMMINGDATA |
| `drive_icicle_flow2.tcl` | Icicle Kit | Microchip Libero | variant: open the already-generated project and re-run the tool stages (no re-generate) |
| `drive_discovery.tcl` | Discovery Kit | Microchip Libero | same as `drive_icicle_full`, for the Discovery reference design |

## Public source designs

The eight builds use four public, commit-pinned designs (no authored RTL). Cite these repositories:

| Design | Repository | Pinned commit | Builds |
|---|---|---|---|
| PicoRV32 (`system`) | https://github.com/YosysHQ/picorv32 | `87c89acc` | 2, 3, 4 |
| SERV (`serv_synth_wrapper`) | https://github.com/olofk/serv | `f5ddfaa6` | 5, 6, 7 |
| PolarFire SoC Icicle Kit Reference Design | https://github.com/polarfire-soc/icicle-kit-reference-design | `fd0aebb9` | 1 |
| PolarFire SoC Discovery Kit Reference Design | https://github.com/polarfire-soc/polarfire-soc-discovery-kit-reference-design | `f09b6e0d` | 8 |

These four repositories correspond to manuscript citations `picorv32Repo`, `servRepo`, `icicleKitRepo`,
and `polarfireDiscoveryRepo`.

## Reproduce (step by step)

**Prerequisites (each on `PATH`):** AMD Vivado 2025.2, Intel Quartus Prime Pro 26.1,
Microchip Libero SoC 2025.2, and an open Yosys + nextpnr-ecp5 + ecppack toolchain.
Devices/parts cited below are from the build table in `BLOCK4_FULLBUILD_REPORT.md`.

The `scripts/` flow inputs reference sources as `REPO_ROOT/block4_builds/<design>/`. Pick a
working directory `<BUILD_ROOT>`, clone the four designs under it at their pinned commits, then
replace the literal `REPO_ROOT` token in `scripts/*` with `<BUILD_ROOT>`.

**0. Lay out commit-pinned sources (once):**
```
mkdir -p <BUILD_ROOT>/block4_builds && cd <BUILD_ROOT>/block4_builds
# Clone into the short directory names the scripts expect (picorv32 / serv / icicle / discovery):
git clone https://github.com/YosysHQ/picorv32 picorv32 && git -C picorv32 checkout 87c89acc
git clone https://github.com/olofk/serv serv && git -C serv checkout f5ddfaa6
git clone https://github.com/polarfire-soc/icicle-kit-reference-design icicle && git -C icicle checkout fd0aebb9
git clone https://github.com/polarfire-soc/polarfire-soc-discovery-kit-reference-design discovery && git -C discovery checkout f09b6e0d
# then replace the REPO_ROOT token in scripts/* with <BUILD_ROOT> (all scripts now use this one convention)
```

**PicoRV32 `system` — builds 2–4 (design fixed, toolchain varied):**
```
# Build 3 — AMD Vivado, Artix-7 xc7a35ticsg324-1L
vivado -mode batch -source scripts/build_vivado.tcl                  # -> picorv32_viv.bit
# Build 2 — Intel Quartus, Cyclone 10 GX 10CX220YU484E5G
quartus_sh --flow compile scripts/picorv32_sys                       # -> .sof
# Build 4 — open ECP5, LFE5U-85F CABGA381
yosys scripts/synth.ys                                               # -> picorv32_ecp5.json
nextpnr-ecp5 --85k --package CABGA381 --json picorv32_ecp5.json --textcfg picorv32_ecp5.cfg --lpf-allow-unconstrained
ecppack picorv32_ecp5.cfg build4_picorv32_ecp5.bit
```

**SERV `serv_synth_wrapper` — builds 5–7:** identical to PicoRV32 but with
`serv_build_vivado.tcl` (Vivado), `serv_quartus.qsf` (`quartus_sh --flow compile`), and
`serv_synth_ecp5.ys` (Yosys, then the same nextpnr-ecp5/ecppack steps).

**Microchip PolarFire SoC reference designs — builds 1, 8 (Libero SoC):**
```
libero SCRIPT:scripts/drive_icicle_full.tcl     # Build 1 — Icicle,    MPFS250T_ES  -> .job
libero SCRIPT:scripts/drive_discovery.tcl       # Build 8 — Discovery, MPFS095T     -> .job
```

Each build emits the artifacts hashed in the matching `build*_evidence.csv`; compare SHA-256
against those manifests to confirm. The board-less builds leave top-level I/O unconstrained
(Vivado UCIO/NSTD downgraded, Quartus virtual pins, nextpnr `--lpf-allow-unconstrained`); no
device is programmed, so BSD-4/DEP-1 stay gaps by construction. Third-party source is neither
modified nor redistributed.
