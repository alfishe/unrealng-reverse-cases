# Variant zyxremix

From `work/candidates/owner-boots_zyx/zyxremix.scl`, file `ZYXremix` (B, start 221, length 221, 56 sectors). Built by `tools/build.sh --variant zyxremix`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 1 sector of BASIC, then: `$61A8` x 55.
- The music piece at `$C000`, 11 sectors, init `$C000`; play `$CB26`.
- Residue (bytes the saved file kept from a run, put back after the build):
  - `ClearPhaseIndex+2`: `06` (self-modified operand: the last phase offset index BuildRombPhases wrote)
  - `MarkPhaseWrite+2`: `17` (self-modified operand: the last phase index marked)
  - `ScaleWriteBit+3`: `AE` (self-modified opcode: the last RES/SET n,(IY) the phase builder used)
  - `SampleStarBit+1`: `76` (self-modified opcode: the last BIT n,(HL) SampleStars used)
  - `SavedIY`: `3A5C58272CFF3F` (the saved IY and the work bytes after it as the menu left them)
  - `FileCount`: `120606020000090900080401009D000000000000C600440000160F1213011005523E202010064020202020202020FF` (the menu's variables (file count, cursor, page) as the saved memory held them)
  - `TwinkleAddr`: `2C402E` (the twinkle position as the saved memory held it)
  - `$FC8E`: `9B6DAB6D00580F011001209DFFF768FFA968376842010000C076BF7614170602327A327703765C760E63061E1862` (the menu's stack (below MenuStack) as the saved memory held it)
  - `$FF00`: `DB02DB02F30DCE0BE450CE0BE5501C17DC0ACE0BDB027C38D4034D00B133DB027C38D4034D0096576A0095578C085C0E0047C057710EF30D2117C61EA761761B03135C3E0047C057710EF30D2117C61E43FF761B0313003E` (BASIC's machine stack under RAMTOP as the saved memory held it)
- Files that differ from the original: `basic.txt`, `files/state-catalogue.bin`, `files/state-im2.bin`, `files/state-rhombus-phases.bin`, `files/state-screen-copy.bin`, `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `music/player.txt`, `music/stc/player.txt`, `music/stc/stc.txt`, `music/whittaker.txt`, `tables/logo-attrs.txt`, `tables/stars.txt`.
- The tune: "KSA" by Ksa (compiled Sound Tracker at `$CB20`, play `$CB26`: `music/stc/`, variant.json music_extra); the music index matches its AY stream exactly. The menu's init call still goes to `$C000`, zyxboot-11's Whittaker player (`music/`, kind whittaker-storm), whose tune never plays.
- Packed: the loader reads 55 sectors to `$61A8`; USR 25000 runs the depacker head (`parts/depack.ann`, the same depacker as zyxtvmbt's music) that unpacks the whole memory `$61A8-$FFFE`. The build makes that memory from the source (the original menu, layout A, with its own font, logo, logo attributes, stars and rhombus, the two music pieces, residue and state) and packs it with tools/lzpack.py (byte-exact, no hints); zeros follow the hook's RET to the end of the 55th sector.
- The packed memory is a snapshot of the running menu: the residue entries and the files/state-*.bin (rhombus phases, the catalogue of the author's disk, the screen copy, the IM 2 table) hold what the menu had built when the memory was saved.
