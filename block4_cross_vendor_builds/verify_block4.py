#!/usr/bin/env python3
"""Verify Block 4 (cross-vendor full builds) frozen artifacts for the
Evidence-Gated STRIDE for FPGA Development Toolchains evidence package.

Standard library only. Run from anywhere:

    python block4_cross_vendor_builds/verify_block4.py

Checks that the 8 build-evidence manifests exist and that every shipped
programming artifact in bitstreams/ has a SHA-256 recorded (case-insensitively)
in the matching build-evidence CSV. This verifies the shipped Block-4 artifacts
against their hash manifests; it does NOT rebuild (that needs the FPGA tools).
Exits 0 if every check passes, 1 otherwise.
"""
import hashlib
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B4 = os.path.join(ROOT, "block4_cross_vendor_builds")


def sha256(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()


def main():
    failures = 0
    try:
        manifests = sorted(x for x in os.listdir(B4) if x.endswith("_evidence.csv"))
        ok = (len(manifests) == 8)
        failures += 0 if ok else 1
        print("%s  build-evidence manifests: %d (expected 8)" % ("PASS" if ok else "FAIL", len(manifests)))

        evidence_text = "".join(
            open(os.path.join(B4, x), encoding="utf-8").read() for x in manifests
        ).lower()

        bits_dir = os.path.join(B4, "bitstreams")
        artifacts = sorted(os.listdir(bits_dir))
        unmatched = [a for a in artifacts
                     if sha256(os.path.join(bits_dir, a)).lower() not in evidence_text]
        ok = (bool(artifacts) and not unmatched)
        failures += 0 if ok else 1
        print("%s  shipped artifacts hash-matched: %d/%d in evidence CSVs"
              % ("PASS" if ok else "FAIL", len(artifacts) - len(unmatched), len(artifacts)))
        if unmatched:
            print("   unmatched: %s" % unmatched)
    except FileNotFoundError as exc:
        failures += 1
        print("FAIL  file not found: %s" % exc)

    print()
    if failures:
        print("%d check(s) FAILED" % failures)
        return 1
    print("All Block 4 checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
