#!/usr/bin/env python3
"""
Create a single "golden" reference from a merged SignReference JSON.

Static signs  → average ALL frames from ALL recordings into one master frame.
Dynamic signs → linearly resample each recording to a common length, then
                average corresponding frames across recordings.

Usage:
  python3 Scripts/create_golden_reference.py Talking\\ Fingers/Vision/References/a.json -o golden/a.json
  python3 Scripts/create_golden_reference.py Talking\\ Fingers/Vision/References/ -o golden/
"""

import argparse
import json
import math
import statistics
import uuid
from pathlib import Path


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def avg(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


def average_joint_dicts(dicts: list[dict]) -> dict:
    """Average a list of joint dictionaries → {name: {x, y, confidence}}."""
    accum: dict[str, list[tuple[float, float, float]]] = {}
    for d in dicts:
        for name, jt in d.items():
            accum.setdefault(name, []).append((jt["x"], jt["y"], jt["confidence"]))

    result = {}
    for name, vals in accum.items():
        result[name] = {
            "x": avg([v[0] for v in vals]),
            "y": avg([v[1] for v in vals]),
            "confidence": avg([v[2] for v in vals]),
        }
    return result


def lerp_joints(a: dict, b: dict, t: float) -> dict:
    """Linearly interpolate between two joint dicts at parameter t ∈ [0, 1]."""
    keys = set(a.keys()) | set(b.keys())
    result = {}
    for k in keys:
        ja = a.get(k)
        jb = b.get(k)
        if ja and jb:
            result[k] = {
                "x": ja["x"] + (jb["x"] - ja["x"]) * t,
                "y": ja["y"] + (jb["y"] - ja["y"]) * t,
                "confidence": ja["confidence"] + (jb["confidence"] - ja["confidence"]) * t,
            }
        elif ja:
            result[k] = dict(ja)
        elif jb:
            result[k] = dict(jb)
    return result


def resample_frames(frames: list[dict], target_len: int) -> list[dict]:
    """Linearly resample a list of frames to target_len using interpolation."""
    n = len(frames)
    if n == 0:
        return []
    if n == 1:
        return [dict(frames[0]) for _ in range(target_len)]
    if n == target_len:
        return list(frames)

    resampled = []
    for i in range(target_len):
        src = i * (n - 1) / (target_len - 1)
        lo = int(math.floor(src))
        hi = min(lo + 1, n - 1)
        t = src - lo

        joints = lerp_joints(frames[lo]["joints"], frames[hi]["joints"], t)
        norm = lerp_joints(
            frames[lo].get("normalizedJoints", {}),
            frames[hi].get("normalizedJoints", {}),
            t,
        )

        # Interpolate timestamps
        s_lo = frames[lo].get("seconds", 0.0)
        s_hi = frames[hi].get("seconds", 0.0)

        resampled.append({
            "id": str(uuid.uuid4()).upper(),
            "seconds": s_lo + (s_hi - s_lo) * t,
            "timescale": frames[lo].get("timescale", 24),
            "joints": joints,
            "normalizedJoints": norm,
        })
    return resampled


# ---------------------------------------------------------------------------
# Golden reference builders
# ---------------------------------------------------------------------------

def build_static_golden(refs: list[dict]) -> dict:
    """Collapse all frames from all recordings into a single averaged frame."""
    all_joints: list[dict] = []
    all_norm: list[dict] = []

    for ref in refs:
        for frame in ref.get("frames", []):
            all_joints.append(frame["joints"])
            if "normalizedJoints" in frame:
                all_norm.append(frame["normalizedJoints"])

    if not all_joints:
        return make_golden_ref(refs, "static", [])

    avg_joints = average_joint_dicts(all_joints)
    avg_norm = average_joint_dicts(all_norm) if all_norm else {}

    golden_frame = {
        "id": str(uuid.uuid4()).upper(),
        "seconds": 0.0,
        "timescale": 24,
        "joints": avg_joints,
        "normalizedJoints": avg_norm,
    }

    return make_golden_ref(refs, "static", [golden_frame])


def build_dynamic_golden(refs: list[dict]) -> dict:
    """Resample all recordings to a common length, then average per-frame."""
    recordings = [ref.get("frames", []) for ref in refs if ref.get("frames")]
    if not recordings:
        return make_golden_ref(refs, "dynamic", [])

    lengths = [len(r) for r in recordings]
    target_len = int(statistics.median(lengths))
    target_len = max(target_len, 2)

    resampled_all = [resample_frames(r, target_len) for r in recordings]

    golden_frames = []
    for i in range(target_len):
        frame_joints = [r[i]["joints"] for r in resampled_all]
        frame_norms = [r[i].get("normalizedJoints", {}) for r in resampled_all]

        avg_joints = average_joint_dicts(frame_joints)
        avg_norm = average_joint_dicts(frame_norms) if any(frame_norms) else {}

        seconds_vals = [r[i].get("seconds", 0.0) for r in resampled_all]

        golden_frames.append({
            "id": str(uuid.uuid4()).upper(),
            "seconds": avg(seconds_vals),
            "timescale": 24,
            "joints": avg_joints,
            "normalizedJoints": avg_norm,
        })

    return make_golden_ref(refs, "dynamic", golden_frames)


def make_golden_ref(refs: list[dict], sign_type: str, frames: list[dict]) -> dict:
    sign_name = refs[0].get("signName") if refs else None
    return {
        "id": str(uuid.uuid4()).upper(),
        "signName": sign_name,
        "signType": sign_type,
        "frames": frames,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def process_file(input_path: Path, output_path: Path, quiet: bool) -> None:
    data = json.loads(input_path.read_text(encoding="utf-8"))
    refs = data if isinstance(data, list) else [data]

    if not refs:
        print(f"Skipping {input_path}: no SignReferences found")
        return

    sign_type = refs[0].get("signType", "static")
    total_frames = sum(len(r.get("frames", [])) for r in refs)

    if sign_type == "dynamic":
        golden = build_dynamic_golden(refs)
    else:
        golden = build_static_golden(refs)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump([golden], f, indent=2, sort_keys=True)

    out_frames = len(golden["frames"])
    if not quiet:
        print(
            f"{input_path.stem}: {len(refs)} recordings, "
            f"{total_frames} input frames → {out_frames} golden frame(s) "
            f"[{sign_type}] → {output_path}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create golden SignReference from merged recordings."
    )
    parser.add_argument(
        "inputs",
        nargs="+",
        help="Input JSON file(s) or directory of .json files",
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Output JSON file or directory",
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
    )
    args = parser.parse_args()

    input_paths: list[Path] = []
    for p in args.inputs:
        path = Path(p)
        if path.is_dir():
            input_paths.extend(sorted(path.glob("*.json")))
        elif path.exists():
            input_paths.append(path)
        else:
            print(f"Warning: {p} not found, skipping")

    if not input_paths:
        print("No input files found.")
        return

    out = Path(args.output)

    if len(input_paths) == 1 and out.suffix == ".json":
        process_file(input_paths[0], out, args.quiet)
    else:
        out.mkdir(parents=True, exist_ok=True)
        for ip in input_paths:
            process_file(ip, out / ip.name, args.quiet)


if __name__ == "__main__":
    main()
