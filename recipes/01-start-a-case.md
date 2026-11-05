# 01. Start a case

**Answers:** what the original is, what is on the medium, and where each block loads.

**Files:** `orig/`, `README.md`, `case.json`, the skeleton ([case-files.md](../docs/case-files.md)).

1. **The folder.** Copy the skeleton and the original:

   ```bash
   cp -R kit/case-template games/<game>          # README, WALKTHROUGH sections, docs stubs, case.json, game.ann,
                                                 # src/res/README.md, tools/build.sh, tools/res_formats.py
   cp ORIGINAL games/<game>/orig/                # unchanged: the tape / disk (a zip stays a zip) and its texts
   cd games/<game> && md5 orig/* && shasum orig/*
   ```

   The README gets the title, the publisher, the year, the authors, the machine the version targets, and the md5
   and SHA-1 of every file. `work/` and `build/` are git-ignored by the repository's `.gitignore`.

2. **Find which release is the game.** A distribution can hold several releases, and the one you expect may not be
   the game. Before anything else, check which file the player actually runs. In advanced-nether-earth the TRD held
   only the win sequence and the SCL was the game: `ne_match.py` found 493 of 563 Nether Earth entries absent on
   the TRD.

3. **List the medium, block by block.**

   | Medium | Command | Notes |
   | --- | --- | --- |
   | TAP | `python3 ../../kit/tapblocks.py list orig/GAME.TAP` | each block's length, header fields, checksum and play time at ROM speed; the total in 48K frames (nether-earth: 264.7 s, 13258 frames) |
   | TZX | the case's `tools/tzxblocks.py list` (zynaps), `tools/tzx_blocks.py` (nether-earth-editor) | the pulse lengths of a non-standard block; the archive-info block may name the loader (zynaps: "Hewson Countdown II", so no turbo) |
   | SCL / TRD | `tools/disk_files.py IMAGE --out work/media/<medium>/files` (nether-earth-gs, zynaps-gs), `tools/disk.py list` (zynaps-128), `tools/scl.py list` (ZS) | the catalogue; each file's start, length and sectors; **the bytes past the stated length** |
   | BASIC | `tools/basic_list.py FILE LINE` (GS, zynaps), `tools/zxbasic.py list` (editor) | the loader program, and any REM with code in it |

   On a disk, compare the catalogue length with the sector count. In nether-earth-gs the catalogue says 39536 bytes
   but the file takes 155 sectors (39680 bytes). A BASIC program can keep its autostart line in the sector tail,
   past its stated length.

4. **Write doc 3.1 at once.** In `docs/03-build-and-load.md`, write the table of blocks or files:
   - sizes as data (+2 on a tape for the flag and the checksum)
   - load addresses
   - play times
   - the tape's total in seconds and frames (pauses not included)

5. **Fill in `case.json`.** Set:
   - `image_cmd`: a command that cuts the game image out of `orig/` into `work/`, for example `tools/image.py`
   - `lo` and `hi`
   - `device`
   - `header`

   The keys are in the [kit README](../kit/README.md#a-case). A 128K game keeps the default `bases`; its other
   banks get a part generator later ([ann-format.md](../docs/ann-format.md#5-extensions-in-the-cases)).

6. **Scan for known pieces** (players, packers, loaders, the modules of earlier cases):

   ```bash
   python3 ../../kit/sig_scan.py work/media/files/GAME.C --base 6590 --all --out work/stage1/sig-game.json
   python3 ../../kit/sig_scan.py IMAGE --base ADDR --ann      # the hits as .ann lines
   ```

   The scan saves time in stage 1. Its hits are a lead to follow up, not evidence.

7. **Add the case to the repository README's table**, with the state "in progress".

**Done when:** the hashes and the block table are written, `case.json` names the image, and the skeleton is
committed.
