#!/usr/bin/env python3
"""Run every standard-library check in this evidence package, in ONE command:

    python run_all_checks.py

It runs the global count check (validate_counts.py) and each block's own
verifier (blockN_*/verify_blockN.py), prints PASS/FAIL per script, and exits
non-zero if any check fails.

No FPGA tools are required: these verify the *shipped* data (counts, splits,
record-ID consistency, fixture oracles, build-artifact hashes). Full Block-2 and
Block-4 *rebuilds* need the vendor tools and are described in the per-block
READMEs.
"""
import glob
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))


def main():
    checks = [os.path.join(ROOT, "validate_counts.py")]
    checks += sorted(glob.glob(os.path.join(ROOT, "block*_*", "verify_block*.py")))

    failures = 0
    for path in checks:
        rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
        print("=" * 72)
        print("RUN  " + rel)
        print("=" * 72)
        if subprocess.run([sys.executable, path]).returncode != 0:
            failures += 1
        print()

    print("#" * 72)
    if failures:
        print("RESULT: %d of %d check script(s) FAILED" % (failures, len(checks)))
        return 1
    print("RESULT: ALL %d check scripts PASSED" % len(checks))
    return 0


if __name__ == "__main__":
    sys.exit(main())
