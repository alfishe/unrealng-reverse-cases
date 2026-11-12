# Variant zyxboot-01

From `work/candidates/owner-boots_zyx/zyxboot.scl`, file `ZYX-1` (B, start 182, length 176, 47 sectors). Built by `tools/build.sh --variant zyxboot-01`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 1 sector of BASIC, then: `$619B` x 16, `$A600` x 8, `$C000` x 21, `$FF14` x 1.
- The music piece at `$C000`, 21 sectors, init `$C00B`; play `$C00E`.
- Code: reads the Kempston joystick: `IN A,($1F)` at Joystick `$68B9` in place of `LD A,$00` (`kempston`, src/main/main.ann @variant Kempston).
- Code: reads the catalogue through ReadCatalogue, a 13-byte routine just before Start at `$619B`, and only while the byte at `$FF14` (the launcher's flag) is 0 (`catalogue-call`, tools/variants.py CODE_SWITCHES).
- Code of its own, described in `parts/launcher.ann` (built by kit/mkgame.py from `parts/launcher.json`, placed at `$FF14`).
- Residue (bytes the saved file kept from a run, put back after the build):
  - `ClearPhaseIndex+2`: `05` (LD A,(IY+d): the last phase offset index BuildRombPhases wrote)
  - `MarkPhaseWrite+2`: `1C` (LD (IX+d),1: the last phase index marked)
  - `ScaleTestBit+3`: `6E` (BIT n,(IX): the opcode of the last source bit tested (BIT 5))
  - `ScaleWriteBit+3`: `B6` (RES/SET n,(IY): the opcode of the last pixel written (RES 6))
  - `SampleStarBit+1`: `76` (BIT n,(HL): the opcode of the last star sampled (BIT 6))
- `files/past-ffff.bin`: the last piece's bytes past `$FFFF`, kept as its bytes.
- Files that differ from the original: `basic.txt`, `files/past-ffff.bin`, `music/asc1.txt`, `music/player.txt`, `tables/stars.txt`.
- The tune: "Techno Project II" by Heather, 1994 (ASC Sound Master; the module's own title string; the music index matches its notes).
- The menu code starts 13 bytes lower (`$619B`): ReadCatalogue, a subroutine the variant added before Start (code switch `catalogue-call`).
- The residue shows the file was saved from memory after the menu had run: the stars' self-modified operands hold run-time values.
