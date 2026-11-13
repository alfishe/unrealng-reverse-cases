#!/bin/sh
# The frame windows of c1 and joystick the witness counts read (src/*/*.json witness_builds): one L1 keeps one
# instruction an address, so a program that ran where another ran before (TimeCheck and Unxor at $FE76, the
# SpeedLock chain under the resident, the front under stage 1) is counted apart only in a window of its own.
#
#   sh tools/c1_windows.sh [PORT_BASE]      # default 37480; needs work/stage1/c1 and work/stage2/rec/joystick
#
# work/stage1/c1/load    frames 0-5099      the chain, the second stage, TimeCheck (frame 2227)
# work/stage1/c1/unxor   frames 5100-5165   the last blocks, Sl1End, Unxor (5164), Boot
# work/stage1/c1/run     frames 5166-16658  the resident from its entry on: the front, the stage 1 load, stage 1
# work/stage1/c1/front   frames 5166-15074  the same up to stage 1's first instruction (15075): the front alone
# work/stage2/rec/joystick/front  frames 0-8899  joystick up to the stage 1 load
# Inside the recording's folder a window keeps its name in the witness lines (c1, joystick: kit/mkgame.py).
set -eu
cd "$(dirname "$0")/.."
. work/env.sh
PB=${1:-37480}
RS="python3 ../../kit/rs.py"
BIN=$(python3 -c "import json; print(json.load(open('work/stage1/c1/session.json'))['binary'])")
W=work/c1win
$RS open --work $W --ttd work/stage1/c1/session.ttd --model 48K --ranges 4000-FFFF --port-base "$PB" --binary "$BIN"
$RS build --work $W --to-frame 5100 --into work/stage1/c1/load
$RS build --work $W --from-frame 5100 --to-frame 5166 --into work/stage1/c1/unxor
$RS build --work $W --from-frame 5166 --into work/stage1/c1/run
$RS build --work $W --from-frame 5166 --to-frame 15075 --into work/stage1/c1/front
$RS stop --work $W
W=work/joywin
$RS open --work $W --ttd work/stage2/rec/joystick/session.ttd --model 48K --ranges 4000-FFFF --port-base "$PB" \
    --binary "$BIN"
$RS build --work $W --to-frame 8900 --into work/stage2/rec/joystick/front
$RS stop --work $W
