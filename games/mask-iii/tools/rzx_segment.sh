#!/bin/sh
# One recording of the ZXDB RZX run (mask3.rzx): from its state after FROM frames (kit/rzx_dump.py's
# work/stage1/rzx/snaps/snap-FROM.z80), the RZX's keys of frames FROM .. TO-1 (tools/rzx_script.py) replayed with the
# TTD on, then the match against the RZX's own screens (kit/rzx_match.py, work/stage1/rzx/dump, a screen every 500).
#   sh tools/rzx_segment.sh FROM TO [PORT_BASE] [MODEL]      (run in the case; source work/env.sh first)
# MODEL is 128K by default: the ten committed segments (work/stage1/rec/rzx-*) were made so. The RZX and its states
# are 48K ones (the .z80 header; unreal-ng's POST /rzx/play switches to the 48K): with MODEL 48K eight of the ten
# segments keep to the RZX to their end, against three on the 128K (work/kitfix/rzx/seg-48K-all.txt)
set -e
FROM=$1; TO=$2; PB=${3:-37780}; MODEL=${4:-128K}
NAME=rzx-$(printf %05d $FROM)
SNAP=work/stage1/rzx/snaps/snap-$(printf %06d $FROM).z80
mkdir -p work/stage1/rec
python3 tools/rzx_script.py work/stage1/rzx/snaps/inputs.json $FROM $TO > tests/inputs/$NAME.txt
python3 tools/capture.py --work work/stage1/rec/$NAME --snapshot $SNAP \
  --model $MODEL --inputs tests/inputs/$NAME.txt --ranges 4000-FFFF --port-base $PB --binary $BIN > work/stage1/rec/$NAME.log 2>&1
python3 ../../kit/rzx_match.py work/stage1/rzx/dump $FROM work/stage1/rec/$NAME --bytes 1500 > work/stage1/rec/$NAME/match.txt || true
tail -2 work/stage1/rec/$NAME/match.txt
python3 $RS stop --work work/stage1/rec/$NAME > /dev/null 2>&1 || true
