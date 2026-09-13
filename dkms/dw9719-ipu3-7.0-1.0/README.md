# DW9719 IPU3 DKMS source

This directory vendors `drivers/media/i2c/dw9719.c` from the Ubuntu
`Ubuntu-hwe-7.0-7.0.0-31.31_24.04.1` source baseline. Ubuntu's exact source
delta does not modify this file. The only functional change is upstream Linux
commit `d7fe0d53b2a8b08f6042cc89315118dee49e072e`, reproduced as
[`../../patches/0001-media-dw9719-add-back-i2c-device-id-table.patch`](../../patches/0001-media-dw9719-add-back-i2c-device-id-table.patch).

It is intentionally scoped to the currently running `7.0.0-31-generic`
headers. It is not installed by a normal build and `AUTOINSTALL` is disabled.
See `../../scripts/build-dw9719-7.0.sh` for the uninstalled artifact build and
`../../docs/changes.md` for the operator-approved live-test procedure.
