#!/usr/bin/env bash
# Merge every letter/number folder in RecordedReferences into its own subdirectory,
# then create golden references in References/.
# Run from repo root: ./Scripts/merge_all_references.sh

set -e
RECORDED="Talking Fingers/Vision/RecordedReferences"
REFERENCES="Talking Fingers/Vision/References"

# Step 1: Merge individual recordings into <sign>/merged.json
for dir in "$RECORDED"/*/; do
  name=$(basename "$dir")
  echo "Merging $name..."
  python3 Scripts/merge_sign_references.py "$RECORDED/$name" -o "$RECORDED/$name/merged.json"
done

echo ""
echo "Creating golden references..."

# Step 2: Create golden references from merged files → References/<name>.json
for dir in "$RECORDED"/*/; do
  name=$(basename "$dir")
  merged="$RECORDED/$name/merged.json"
  if [ -f "$merged" ]; then
    python3 Scripts/create_golden_reference.py "$merged" -o "$REFERENCES/$name.json"
  fi
done

echo "Done."
