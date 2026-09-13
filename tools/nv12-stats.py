#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Report objective luminance statistics for raw NV12 frame files.

The tool reads only the Y plane. It does not decode, display, upload, or retain
camera imagery. It identifies black/near-uniform frames and exact or near-exact
successive-frame repeats without non-standard Python dependencies.
"""

import argparse
import math
import os
import sys


def y_statistics(path: str, y_bytes: int) -> tuple[bytes, dict[str, float | int | str]]:
    with open(path, "rb") as frame:
        y_plane = frame.read(y_bytes)
    if len(y_plane) != y_bytes:
        raise ValueError(f"expected at least {y_bytes} bytes, found {len(y_plane)}")

    histogram = [0] * 256
    total = 0
    total_squared = 0
    for value in y_plane:
        histogram[value] += 1
        total += value
        total_squared += value * value

    mean = total / y_bytes
    variance = max(0.0, (total_squared / y_bytes) - (mean * mean))
    deviation = math.sqrt(variance)
    distinct = sum(1 for count in histogram if count)
    # Limited-range black is normally near Y=16; allow a small safety margin.
    black = max(y_plane) <= 20 and deviation <= 2.0
    uniform = deviation <= 1.0 or distinct <= 2
    return y_plane, {
        "min": min(y_plane),
        "max": max(y_plane),
        "mean": mean,
        "stddev": deviation,
        "distinct": distinct,
        "distinct_percent": distinct * 100.0 / 256.0,
        "black": "yes" if black else "no",
        "uniform": "yes" if uniform else "no",
    }


def compare(previous: bytes, current: bytes) -> tuple[bool, float, float]:
    differences = 0
    absolute_difference = 0
    for earlier, later in zip(previous, current):
        delta = abs(earlier - later)
        absolute_difference += delta
        if delta:
            differences += 1
    return (
        differences == 0,
        differences * 100.0 / len(current),
        absolute_difference / len(current),
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--width", type=int, required=True)
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("frames", nargs="+", help="raw NV12 frame files")
    args = parser.parse_args()
    if args.width <= 0 or args.height <= 0:
        parser.error("width and height must be positive")

    y_bytes = args.width * args.height
    print("# NV12 Y-plane statistics; no image data is emitted")
    print("frame\tmin\tmax\tmean\tstddev\tdistinct\tdistinct_%\tblack\tuniform\tcanonical_startup_black\texact_previous\tchanged_%\tmean_abs_delta")
    previous = None
    suspicious = 0
    canonical_startup_black = 0
    for path in args.frames:
        try:
            current, stats = y_statistics(path, y_bytes)
        except (OSError, ValueError) as error:
            print(f"error: {path}: {error}", file=sys.stderr)
            return 2
        if stats["black"] == "yes" or stats["uniform"] == "yes":
            suspicious += 1
        startup_black = (
            stats["black"] == "yes"
            and os.path.basename(path).startswith("frame-000001")
        )
        if startup_black:
            canonical_startup_black += 1
        if previous is None:
            exact, changed, mean_delta = False, 100.0, 0.0
            exact_text = "n/a"
        else:
            exact, changed, mean_delta = compare(previous, current)
            exact_text = "yes" if exact else "no"
        print(
            f"{os.path.basename(path)}\t{stats['min']}\t{stats['max']}\t"
            f"{stats['mean']:.3f}\t{stats['stddev']:.3f}\t{stats['distinct']}\t"
            f"{stats['distinct_percent']:.2f}\t{stats['black']}\t{stats['uniform']}\t"
            f"{'yes' if startup_black else 'no'}\t{exact_text}\t{changed:.3f}\t{mean_delta:.3f}"
        )
        previous = current
    if suspicious:
        print(f"SUMMARY suspicious_black_or_uniform_frames={suspicious}/{len(args.frames)}")
    else:
        print(f"SUMMARY suspicious_black_or_uniform_frames=0/{len(args.frames)}")
    print(f"SUMMARY canonical_startup_black_frames={canonical_startup_black}/{len(args.frames)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
