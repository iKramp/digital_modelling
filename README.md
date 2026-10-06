# Anvil + F4PGA + VPR Nix flake

This is a Nix packaging layout for LogiSmith/Anvil targeting the Nexys A7-100T.

The board support in Anvil is metadata: it selects `nexys4ddr`, the VPR device
`xc7a100t_test`, the part `xc7a100tcsg324-1`, the openFPGALoader board
`nexys_a7_100`, and the bundled XDC. It does not install F4PGA or VPR.

The F4PGA side is pinned to the toolchain revisions used by LogiSmith's
2022 installer, and only the `xc7a100t_test` device archive is included because
that is the device Anvil selects for the 100T board.

The flake deliberately does not create `~/miniconda3` or `~/opt/f4pga`. Anvil is
patched to use the Nix-store F4PGA prefix directly. Its `conda.sh` dependency is
replaced by a tiny compatibility shim which only exports the store prefix and
PATH.

## Caveat

LogiSmith's installer also applies a small `fix_xc7_carry.py` patch to the
pinned F4PGA Python tree. This layout keeps the upstream Python source intact.
If a Nexys A7 bitstream build reaches the carry-fix stage and fails there, that
installer patch needs to be carried over as a Nix `substituteInPlace` or patch
against `f4pga/utils/xc7/fix_xc7_carry.py`.

## Build

Use:

    nix develop

or inspect individual packages with:

    nix build .#vpr
    nix build .#f4pga
    nix build .#anvil
