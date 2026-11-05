# Zynaps 2 in 1: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

`tools/disk.py list` / `compare` on the SCL and the TRD: one BASIC file `ZYNAPS.B` (137 sectors, a loader in a REM)
in both, plus a generic `boot.B` on the TRD. `tools/hrust1.py` unpacks the two `HR` blocks inside it. Details:
[docs/03-build-and-load.md](docs/03-build-and-load.md) 3.1-3.3; the commands: `work/stage1/NOTES.md`.

## 1. One recording from power-on

`c1`: `re_session.py capture --record-load` on Pentagon 128 + TR-DOS with the TRD, keys from
`work/stage1/inputs/c1-trd-pentagon.txt` (the 128 menu, `RUN`, the boot list, the intro, the menu, random play);
recording frame = script frame + 1602, no fast load (a disk). The same keys on every 128K-or-larger model with
TR-DOS: `tools/model_run.py` (docs/03 3.9).

## 2. Static pass over the medium

## 3. The stages and the packers

`re_session.py stages` and `tools/first_change.py` (a binary search over `time_travel memory_at`) give the frames of
each stage; `tools/ttd_dump.py` the six images in `work/images/`; Hrust 1 proved at 0 bytes different for both
blocks (docs/03 3.3, 3.7). The sound hooks: `time_travel coverage_scan` on each stub, screenshots at those frames
(docs/09 9.2).

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

## 7. Review
