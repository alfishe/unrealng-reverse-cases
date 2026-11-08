#!/bin/sh
# Exploration recordings on clones (tools/warp_snapshot.py): one per start screen, tests/inputs/w-short.txt, three
# at a time on port bases 20100 / 20700 / 21300. Each work/w/NNN holds a session.ttd and its L1; each instance is
# stopped when its capture is done.
#
#   tools/warp_runs.sh 0 5 120        # start screens 0, 5, ..., 120
#   tools/warp_runs.sh list 6 7 13    # these start screens
set -e
cd "$(dirname "$0")/.."
. work/env.sh
mkdir -p work/w work/snaps
run() {  # $1 screen, $2 port base
    n=$(printf %03d "$1")
    python3 tools/warp_snapshot.py "$1" "work/snaps/warp-$n.z80"
    rm -rf "work/w/$n"
    python3 "$RS" capture --work "work/w/$n" --snapshot "work/snaps/warp-$n.z80" --model 48K \
        --inputs tests/inputs/w-short.txt --ranges 4000-FFFF --port-base "$2" --binary "$BIN" > "work/w/$n.log" 2>&1
    python3 "$RS" stop --work "work/w/$n" >> "work/w/$n.log" 2>&1
    echo "screen $n: $(head -1 "work/w/$n.log")"
}
if [ "$1" = list ]; then
    shift
    screens="$*"
else
    screens=$(seq "$1" "$2" "$3")
fi
set -- $screens
while [ $# -gt 0 ]; do
    run "$1" 20100 &
    [ $# -gt 1 ] && run "$2" 20700 &
    [ $# -gt 2 ] && run "$3" 21300 &
    wait
    shift $(( $# < 3 ? $# : 3 ))
done
