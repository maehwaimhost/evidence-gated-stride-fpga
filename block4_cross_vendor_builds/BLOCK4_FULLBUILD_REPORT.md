# Block-4 Full-Build Extension — Verification Report

Non-programming full vendor-toolchain builds of public FPGA designs --- Block 4 of
the evaluation --- exercising actual synthesis →
place&route → timing → bitstream/programming-data generation across **four toolchains**
in **eight builds over four public designs**. All builds are commit-pinned, run without
modifying third-party repo sources (drivers/projects/logs live outside the clones), use a
repo-provided or vendor-provided top (no authored RTL), and produce hashed artifacts.

Scope note (calibration): these are **artifact-grounding builds** — they confirm
that the catalog's artifact families are emitted by real flows. They are NOT
efficacy/detection/security claims. No physical board was available, so the two
deployment records (DEP-1 readback/status, BSD-4 programming-target) remain gaps
in every build by construction.

## Builds

| # | Vendor / Toolchain | Repo @ commit | Top | Device | Result |
|---|---|---|---|---|---|
| 1 | Microchip **Libero SoC 2025.2** | polarfire-soc/icicle-kit-reference-design @ fd0aebb9 | BASE_DESIGN (Icicle) | MPFS250T_ES | gen+SYNTH+P&R+VERIFYTIMING+GENPROGDATA all rc=0 |
| 2 | Intel **Quartus Prime Pro 26.1** | YosysHQ/picorv32 @ 87c89acc | system | Cyclone 10 GX 10CX220YU484E5G | full compile success; Setup slack +4.800 ns |
| 3 | AMD **Vivado 2025.2** | YosysHQ/picorv32 @ 87c89acc | system | Artix-7 xc7a35ticsg324-1L | write_bitstream OK; .bit 2.19 MB; timing met; DRC 0 err |
| 4 | Lattice — **open Yosys+nextpnr-ecp5+ecppack** | YosysHQ/picorv32 @ 87c89acc | system | ECP5 LFE5U-85F CABGA381 | yosys/nextpnr/ecppack all exit 0; .bit 1.95 MB; Fmax 98.26 MHz (PASS) |
| 5 | Intel **Quartus Prime Pro 26.1** | olofk/serv @ f5ddfaa6 | serv_synth_wrapper | Cyclone 10 GX 10CX220YU484E5G | full compile SUCCESS (syn/fit/sta/asm 0 errors); .sof 9.0 MB |
| 6 | AMD **Vivado 2025.2** | olofk/serv @ f5ddfaa6 | serv_synth_wrapper | Artix-7 xc7a35ticsg324-1L | write_bitstream OK; .bit 2.19 MB; all timing constraints met; DRC 0 err |
| 7 | Lattice — **open Yosys+nextpnr-ecp5+ecppack** | olofk/serv @ f5ddfaa6 | serv_synth_wrapper | ECP5 LFE5U-85F CABGA381 | yosys/nextpnr/ecppack all exit 0; .bit 1.93 MB; Fmax 115.6 MHz (PASS) |
| 8 | Microchip **Libero SoC 2025.2** | polarfire-soc/discovery-kit-reference-design @ f09b6e0d | MPFS_DISCOVERY_KIT (base) | MPFS095T FCSG325 | gen+SYNTH+P&R+VERIFYTIMING+GENPROGDATA all rc=0; timing MET (+3.72 ns); FlashPro .job 5.75 MB exported; 13156 4LUT / 9298 DFF |

Vendor coverage: Microchip + Intel + AMD (the three audited vendors) + **Lattice
via a fully open toolchain** — directly addressing the paper's disclosed limit
("Lattice, Gowin, and open-source toolchains ... were not examined"). Two portable cores
(PicoRV32, SERV) are each built on Vivado/Quartus/ECP5; two Microchip PolarFire SoC reference
designs (Icicle, Discovery) are built on Libero.

## Record gap→match flip (non-programming)

Verified against actual artifacts per build — no forced mappings.

- **match in all eight builds:** TRN-1 (synthesis netlist), TRN-2 (place&route
  state), TRN-3 (routing/resource), BSD-1 (bitstream/programming data).
  (Tool/version state is recorded in every build log, but TENV-3 is coded as a
  *documented* (D) requirement in Table~S3, not a build-observable (G) record, so it is
  not counted among the records that flip to match here---consistent with the
  paper's Block-4 grounding of only TRN-1--TRN-3 and BSD-1.)
- **match in the six commercial-flow builds (Libero/Quartus/Vivado):**
  CFG-1 (constraints), CFG-2 (tool options/scripts), CFG-3 (timing closure —
  positive slack / Fmax PASS), RPT-1 (timing/utilization/DRC signoff reports).
  The two open ECP5 (Yosys/nextpnr) builds were run **without explicit constraint or
  signoff inputs** (no LPF/SDC; nextpnr used a default target frequency), so
  CFG and RPT-1 are NOT claimed for them — only TRN and BSD-1.
- **gap — requires a physical board:** DEP-1 (readback/status/verify),
  BSD-4 (programming-target identity/log).
- **gap — requires org/release pipeline (not a local build):** SIP-1 (provider
  identity), BSD-3 (signing authority), REL-1 / REL-2 (release automation).
- **not applicable / not exercised:** SIP-3 (proprietary-HDL confidentiality —
  open designs), BSD-2 (bitstream keys — no encryption configured),
  SIM-1 / SIM-2 (simulation not run in these synthesis builds).

This matches the catalog's evidence-source coding: the "G" (build-observable)
records flip to match; the "P"/"D" (provenance/deployment) records stay gap
without organizational provenance or a programmed device.

## Build scope and caveats

1. **Non-programming ceiling:** DEP-1 and BSD-4 cannot reach match without a physical
   PolarFire/Arty/ECP5 board + programmer; documented as future work. Discovery (Build 8)
   completed programming-data generation (rc=0) and exported a FlashPro programming job
   (`build8_discovery.job`, 5.75 MB) via `export_prog_job` --- a real programming file
   (BSD-1), but no device was programmed, so BSD-4/DEP-1 stay gaps.
2. **Design fixed, vendor varied:** each portable core (PicoRV32 `system`; SERV
   `serv_synth_wrapper`, the wrapper **shipped by the SERV repo**) is built on three
   toolchains (Intel/AMD/Lattice). Holding the design fixed isolates the vendor variable and
   shows the same artifact families emerge across all toolchains (vendor-neutrality). The two
   Microchip reference designs (Icicle, Discovery) are built on Libero only, as they target
   PolarFire devices and Microchip IP. No build uses authored RTL.
3. **Device retarget:** Quartus builds use Cyclone 10 GX (not the cores' default older
   families) because the installed Quartus is Prime Pro 26.1, which supports only modern
   families; same family as the paper's controlled Block-2 build.
4. **Unconstrained I/O:** the board-less builds leave top-level I/O unconstrained — UCIO/NSTD
   DRC downgraded (Vivado), virtual pins (Quartus), `--lpf-allow-unconstrained` (nextpnr).
   Synthesis/P&R/bitstream all complete; only pin-location assignment is omitted.
5. **firmware.hex:** a synthetic 4096-word NOP (00000013) memory image supplied
   as a *build input* (PicoRV32 `system` reads it via $readmemh). No repo source
   file was modified.
6. **No repo modification:** `git status` clean on every clone; all generated
   project dirs are build outputs (gitignored), drivers/QSF/XDC/Tcl live outside
   the clones.

## Artifact hashes

Per-build SHA-256 manifests:
build1_icicle_evidence.csv, build2_picorv32_quartus_evidence.csv,
build3_picorv32_vivado_evidence.csv, build4_picorv32_ecp5_evidence.csv,
build5_serv_quartus_evidence.csv, build6_serv_vivado_evidence.csv,
build7_serv_ecp5_evidence.csv, build8_discovery_libero_evidence.csv.
