#!/usr/bin/env bash
# FS-0030 suite helper: export the same bash indirection the other suites use
# (CA_BASH_FOR_TESTS lets a Bash 3.2 binary stand in for the system bash).
export TEST_BASH="${CA_BASH_FOR_TESTS:-bash}"
