#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOUNDS="$ROOT/CraveRoll/Resources/Sounds"

python3 "$ROOT/scripts/generate_slot_sounds.py"

for f in spin_pull spin_loop winner reel_tick_1 reel_tick_2 reel_tick_3 reel_tick_4 reel_tick_5 reel_tick_6; do
  afconvert -f caff -d LEI16@44100 -c 1 "$SOUNDS/${f}.wav" "$SOUNDS/${f}.caf"
done

echo "Regenerated CAF files in $SOUNDS"
