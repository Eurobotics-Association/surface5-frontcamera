# Licensing and provenance

## Project policy

The project default is **GPL-2.0-only**. The complete GNU GPL version 2 text
is provided in the top-level [`COPYING`](../COPYING) file. Original project
kernel-related scripts carry `SPDX-License-Identifier: GPL-2.0-only`.

Documentation is also distributed under GPL-2.0-only unless it quotes or
reproduces third-party material, in which case the quoted material retains its
own terms. No camera images, firmware binaries, or built modules are included.

## Imported DW9719 driver

[`dkms/dw9719-ipu3-7.0-1.0/dw9719.c`](../dkms/dw9719-ipu3-7.0-1.0/dw9719.c)
is kernel-derived code. It preserves verbatim:

- `// SPDX-License-Identifier: GPL-2.0`;
- `Copyright (c) 2012 Intel Corporation`;
- the upstream historical-source attribution comment.

It was taken from the v7.0 base source used by Ubuntu HWE source tag
`Ubuntu-hwe-7.0-7.0.0-31.31_24.04.1` (dereferenced source commit
`cc909f9a3d277832d246c6493bbc06e0955cde2e`). The audited Ubuntu source-package
delta for `7.0.0-31.31~24.04.1` does not modify this path.

The only functional divergence is upstream Linux commit
[`d7fe0d53b2a8b08f6042cc89315118dee49e072e`](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=d7fe0d53b2a8b08f6042cc89315118dee49e072e),
preserved separately as
[`patches/0001-media-dw9719-add-back-i2c-device-id-table.patch`](../patches/0001-media-dw9719-add-back-i2c-device-id-table.patch).
That patch is likewise GPL-2.0 kernel derivative material and must not be
relicensed.

## Preservation rules

- Do not change imported SPDX identifiers or copyright notices.
- Keep upstream commit IDs and source baselines with any derived source.
- New kernel-related source must be GPL-2.0-only unless upstream provenance
  requires another compatible license, in which case document the exception.
- Do not copy third-party installers, binaries, or firmware into this project
  merely to simplify setup.

## Check performed

Before this policy was committed, the vendored driver's SPDX and copyright
header were read directly. `COPYING` is the verbatim GPLv2 text supplied by the
local system's standard license collection. The repository contains no other
imported source code besides the identified driver and derivative patch.
