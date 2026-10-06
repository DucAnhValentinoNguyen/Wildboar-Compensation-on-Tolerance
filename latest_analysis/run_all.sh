#!/bin/bash
# Re-run the whole analysis pipeline in order; one log per script in logs/rerun/.
cd "$(dirname "$0")"; mkdir -p logs/rerun
for s in scripts/[0-9][0-9]_*.R; do
  n=$(basename "$s" .R); echo "$(date +%T) START $n"
  if Rscript "$s" > "logs/rerun/$n.log" 2>&1; then echo "$(date +%T) OK    $n"; else echo "$(date +%T) FAIL  $n"; fi
done
echo ALLDONE
