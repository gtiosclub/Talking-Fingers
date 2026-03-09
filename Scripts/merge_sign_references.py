#!/usr/bin/env python3
"""
Merge multiple SignReference JSON files for the same sign into a single file.

Usage:
  python merge_sign_references.py a_member1.json a_member2.json a_member3.json -o a.json
  python merge_sign_references.py ./recordings/ -o a.json   # merges all .json in directory
  python merge_sign_references.py *.json -o a.json         # shell glob

Output: One JSON file with all SignReferences concatenated in a single array.
"""

import argparse
import json
import sys
from pathlib import Path


def load_refs(path: Path) -> list[dict]:
    """Load a JSON file; expect [SignReference, ...] or single SignReference."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, list):
        return data
    return [data]


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Merge SignReference JSON files into one."
    )
    parser.add_argument(
        "inputs",
        nargs="+",
        help="Input JSON files or a directory containing .json files",
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Output JSON file path",
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Suppress summary output",
    )
    args = parser.parse_args()

    paths: list[Path] = []
    for p in args.inputs:
        path = Path(p)
        if path.is_dir():
            paths.extend(sorted(path.glob("*.json")))
        elif path.exists():
            paths.append(path)
        else:
            print(f"Warning: {p} not found, skipping", file=sys.stderr)

    if not paths:
        print("No input files found.", file=sys.stderr)
        sys.exit(1)

    merged: list[dict] = []
    sign_names: set[str] = set()

    for path in paths:
        try:
            refs = load_refs(path)
            for ref in refs:
                merged.append(ref)
                if ref.get("signName"):
                    sign_names.add(ref["signName"])
        except (json.JSONDecodeError, OSError) as e:
            print(f"Error reading {path}: {e}", file=sys.stderr)
            sys.exit(1)

    if len(sign_names) > 1 and not args.quiet:
        print(f"Warning: Mixed sign names {sign_names} — verify output.", file=sys.stderr)

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(merged, f, indent=2, sort_keys=True)

    if not args.quiet:
        print(f"Merged {len(paths)} file(s) → {len(merged)} SignReference(s) → {out_path}")


if __name__ == "__main__":
    main()
