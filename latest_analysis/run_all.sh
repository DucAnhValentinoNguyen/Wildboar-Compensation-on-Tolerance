#!/bin/bash
# Re-run the whole analysis pipeline in order; one log per script in logs/rerun/.
cd "$(dirname "$0")"; export WB_ANALYSIS_ROOT="$(pwd)"; mkdir -p logs/rerun output/tables output/figures output/models
echo "$(date +%T) START 00_extract_raw_supplement"
if python3 scripts/00_extract_raw_supplement.py > logs/rerun/00_extract_raw_supplement.log 2>&1; then echo "$(date +%T) OK    00_extract_raw_supplement"; else echo "$(date +%T) FAIL  00_extract_raw_supplement"; fi
for s in scripts/[0-9][0-9]_*.R; do
  n=$(basename "$s" .R); echo "$(date +%T) START $n"
  if Rscript "$s" > "logs/rerun/$n.log" 2>&1; then echo "$(date +%T) OK    $n"; else echo "$(date +%T) FAIL  $n"; fi
done
echo ALLDONE
