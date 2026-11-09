#!/bin/sh
# Stage-1 recordings, one at a time on port base 32200 (the agent's own), each instance stopped when its capture is
# done (reopen one with re_session.py open for reads). Each argument is NAME:SNAPSHOT:SCRIPT, e.g.
#
#   tools/runs.sh g1:entry:g1-game-over i1:immune:i1-immune-beginner
#
# makes work/runs/NAME from work/snaps/SNAPSHOT.z80 and tests/inputs/SCRIPT.txt.
set -e
cd "$(dirname "$0")/.."
. work/env.sh
mkdir -p work/runs
for spec in "$@"; do
    name=${spec%%:*}; rest=${spec#*:}; snap=${rest%%:*}; script=${rest#*:}
    rm -rf "work/runs/$name"
    python3 "$RS" capture --work "work/runs/$name" --snapshot "work/snaps/$snap.z80" --model 48K \
        --inputs "tests/inputs/$script.txt" --ranges 5B00-FFFF --port-base 32200 --binary "$BIN" \
        > "work/runs/$name.log" 2>&1 || echo "$name: capture failed" >> "work/runs/$name.log"
    python3 "$RS" stop --work "work/runs/$name" >> "work/runs/$name.log" 2>&1 || true
    echo "$name: $(grep -m1 captured "work/runs/$name.log")"
done
