# Tool-Layer Evidence Experiment

Reproducible cross-vendor tool-layer evidence run. Grounds the artifact inventory in two paper-authored designs of different structure per vendor flow.

## Designs

- **Design A** (`src/top.v`, module `top`): single clock, 4 hierarchical modules (timer, LFSR sample source, control FSM with 16x8 history memory, integrity LFSR), 4 outputs. Constraints: one `create_clock` (10 ns) plus pin/IO assignments where applicable.
- **Design B** (`src/top_b.v`, module `top_b`): dual clock domain (clk_a 10 ns, clk_b 7 ns), 16x8 dual-clock FIFO with gray-coded pointers and 2-FF synchronizers (CDC), 8x8 register file, monitor FSM. Constraints: two `create_clock`, `set_clock_groups -asynchronous` (XDC/SDC), no pin assignments (Vivado UCIO-1/NSTD-1 downgraded for bitstream generation, Quartus auto pin placement, Libero auto IO assignment). Design B exercises multi-clock constraint semantics, CDC/clock-interaction report families, and inferred-memory transformation state that design A does not.

## Flows

Official CLI/Tcl flows and tool installs:
- AMD Vivado 2025.2 (`vivado.bat -mode batch -source vivado/build_vivado.tcl`): project mode, synth/impl runs, DCP checkpoints, utilization/timing/DRC reports (+ clock-interaction and CDC reports for design B), `write_bitstream`.
- Intel Quartus Prime Pro 26.1 (`quartus_sh -t`, `quartus_sh --flow compile`): QPF/QSF/SDC projects (`project` for A, `project_b` for B), full compile, output_files reports, `.sof`.
- Microchip Libero SoC 2025.2 (`libero.exe SCRIPT:libero/build_libero.tcl`): PolarFire MPF100T projects (`project` for A, `project_b` for B), SYNTHESIZE/PLACEROUTE/VERIFYTIMING/GENERATEPROGRAMMINGDATA/GENERATEPROGRAMMINGFILE, `export_bitstream_file` (STP/DAT/PPD).

**Tool paths.** The scripts resolve each tool from `PATH` by default (`vivado.bat`, `quartus_sh.exe`, `libero.exe`). Either add the vendor `bin` directories to `PATH` (run each vendor's environment/settings script first) or set `$env:VIVADO_BIN`, `$env:QUARTUS_SH`, and `$env:LIBERO_BIN` to the full executable paths before running.

## Run order

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_all.ps1                       # baseline: A+B through all three flows + collect_evidence
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_perturbation_variants.ps1   # 2 controlled revisions x (A+B) x 3 vendors
```

Variant runtimes are materialized under `..\cross_vendor_variant_runtime\`.

## Controlled revisions (perturbation variants)

- `hdl_revision`: one-line output-assignment change in `top.v` AND in `top_b.v` (`status <= {1'b1, peak[7:5]}` -> `peak[6:4]`).
- `constraint_revision`: clock-period tightening in all six constraint files (A: 10 ns -> 8 ns; B: clk_b 7 ns -> 6 ns).

Each variant re-runs the complete three-vendor flow and the trace compares SHA-256 digests of per-design key artifacts against the baseline, yielding 2 variants x 3 vendors x 2 designs = 12 trace rows in `results/artifact_perturbation_evidence_trace.csv` (with a `design_id` column).

## Outputs

- `results/cross_vendor_artifact_inventory.csv` — full file inventory with vendor, stage, role, SHA-256, mtime, size, mapped record IDs.
- `results/experiment_environment.csv` — tool paths/versions/run date.
- `results/artifact_perturbation_evidence_trace.csv` — 12-row controlled-revision trace.
- `results/variant_run_status.csv`, `results/variant_manifest.csv` — variant run accounting.
- `results/{vivado,quartus,libero}/` — native tool outputs per design.

## Run notes

- Baseline + both perturbation variants completed with exit 0; all 12 trace rows are `traceable` and all 6 variant runs report `ok`.
- **Quartus design B emits no .sof by design-state:** the Assembler completes but withholds the programming file because design B deliberately carries no pin-location or I/O-standard assignments (Critical Warnings 25196/25207 in `results/quartus/quartus_compile_b.log`). `top_b.sof` therefore appears in the trace's `missing_key_artifacts` column on both baseline and variant sides. This is reported in the manuscript as an observed instance of programming-file generation being gated on constraint completeness.
- **Vivado flaky child-process teardown crash:** one run of the impl child crashed at exit (EXCEPTION_ACCESS_VIOLATION) after route_design completed, leaving the run marked ERROR and the parent hung in `wait_on_run`. `build_vivado.tcl` now uses `wait_on_run -timeout` plus an open-checkpoint fallback (see `open_run_or_checkpoint`); the final clean run did not need the fallback (all run STATUS values were Complete).
- **Design-bug bring-up note:** the first version of the design B async FIFO computed `full` combinationally from `wptr_gray_next` (which depended on `~full`), a combinational loop. Vivado's DRC LUTLP-1 blocked bitstream generation; Quartus and Synplify silently cut the loop and completed. The FIFO was fixed to registered full/empty flags before the final clean run. Kept here as a toolchain-behavior observation.
