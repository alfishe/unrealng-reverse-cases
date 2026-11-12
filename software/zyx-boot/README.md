# ZYX boot (ZYX Software, 1993-1994)

State: complete (2026-11-12): two review rounds, the kit gaps fixed. The source rebuilds `orig/boot.scl` byte for byte; documents 01-13 are
written; all 56 variants build identical from the same source ([doc 13](docs/13-variants.md)).

| | |
| --- | --- |
| Machine | 48K with TR-DOS and an AY (works silent without one); recorded on a Pentagon 128K ([doc 2, 2.1](docs/02-architecture.md#21-the-machine-budget)) |
| Profile (AGENTS.md 4.0) | a system program: a TR-DOS boot menu, the `boot` file a disk starts with ([doc 1](docs/01-overview.md)). It reads the disk's catalogue (track 0, 8 sectors) and lists the BASIC programs and the CODE files of exactly 192 sectors (48K Magic snapshots), never `boot`, as a menu of up to 24 names a page, letters A-X, one column up to 12 names, two from 13 ([doc 7](docs/07-catalogue-and-menu.md)); keys: a letter runs its file at once, the digits are the two Sinclair joysticks (1-5 and 6-0: left, right, down, up, fire), ENTER fires, SYMBOL SHIFT / CAPS SHIFT turn the pages, SPACE reads a new disk; the keyboard read every 8th frame, the Kempston read silenced ([doc 5](docs/05-keys.md)). Around it the ZYX logo with a red diagonal glint and its upside-down reflection, four rhombi turning in 3D in the corners (34 phases built at the start from one sprite), 30 falling stars (10 near of 2 x 2 pixels, 20 far of 1), a twinkling star sprite (39 frames a twinkle), fixed corner colour gradients, the cursor name that spins in a 256-frame (5.12 s) cycle ([doc 6](docs/06-graphics.md), [doc 8](docs/08-font-and-text.md)). ASC Sound Master music, "Disco music" by Ant P: 7704 frames the first tune loop, 7764 every later one ([doc 9](docs/09-music-and-sound.md)). IM 2 and a main loop that never waits for the frame, about 2.2 passes a frame ([doc 4](docs/04-program-cycle.md)). The chosen file runs through TR-DOS from a command the menu writes into its own BASIC line 1; the menu puts the caller's state back, rings a bell, fades the screen out and returns to the loader at `$5DB7` ([doc 10](docs/10-launcher-and-notes.md)) |
| Authors | ZYX Software (zxart: "ZYX boot (1993)(ZYX Software)"); the code's author is not named anywhere in the boot. The music: "ASM COMPILATION OF DISCO MUSIC BY ANT P BY ANDREW SENDETSKI ASC" (the player's text at `$C014`): ASC Sound Master by Andrew Sendetski (ASC), the tune by Ant P |
| Release | ZYX Software's own disks: the boot is sector-for-sector the `boot` file of "Games Compilation - Tank (1994)(Zyx)" and "Games Compilation - War Cars Construction Set (1994)(Zyx)" (TOSEC); zxart dates "ZYX boot" 1993. Countless re-uses with changed graphics and music ([variants](work/stage1/variants.md)) |
| Original | `orig/boot.scl` (11 803 bytes, md5 `754a157f1c027d7037754ad24ce8e434`, SHA-1 `960ac26d252ea4ee1c19dbd1e9caba1d878eccd6`): the `boot.scl` of Vadim's 2010 sources (`work/candidates/sources-2010-vadim/`), one file `boot` (B, 180, 46 sectors, body sha256 `1add29ab65b5e2b4112f30e7fdf23a68f96cf136969ede87dce09ab93b7fbd79`) |

## The release check: why this file is the original

1. **ZYX's own disks carry it.** The body of `boot` is byte for byte the `boot` in slot 0 (track 1, sector 0) of
   `Games Compilation - Tank (1994)(Zyx).trd` (md5 `45e922e3da95dfe5c2eaf89e50f0355b`) and
   `Games Compilation - War Cars Construction Set (1994)(Zyx).trd` (md5 `312bb732d0b0ef1da5ac5ab84b1b19e5`), two of
   the 48 TOSEC "(Zyx)" compilations (`work/stage1/zyxdisks/`, `work/stage1/release_check.py`). The other ZYX
   compilations carry its close relatives: family B (a 3-byte longer set-up for a two-entry music player) on about
   20 of them, family A (only the music's two CALL addresses changed) on Cabal, Eidolon and Rainbow Islands.
2. **It is the base form.** Family A differs from it only in the bytes at `$61E8`/`$676E` (the music's entries) and
   family B only by the inserted CALL and the 3-byte shift; this one has the single-entry player the others were
   adapted from ([variants](work/stage1/variants.md)).
3. **Vadim's 2010 decompilation is this boot.** Its binaries `61a8.bin`, `a600.bin`, `c000.bin` are the three pieces
   of this body byte for byte, and its `ZYXboot.mac` assembles to `$61A8-$705F` exactly (`work/stage2/vadim.asm`).
4. **It is the one in circulation.** The collection index finds the same body on 42 images (`work/stage1/img-vadim.txt`,
   `work/stage1/vadim-images.tsv`): boot collections (`bootcol/66ZYX.TRD`, rindex `ZYXBOOT.TRD`), music and demo
   disks of 1993-1995. Some name it `BOOT27`, and its sector 0 still holds `oot27" LINE 10` after the program: the
   file was saved as `boot27`.
5. **What the zxart entry is.** "ZYX boot (1993)(ZYX Software)" on zxart is the 18-file disk `zyxboot.scl` (byte for
   byte the owner's), ZYX-1 to ZYX-18: none of them is this body; 13 are family A or close, 5 family B. It is a
   collection of ZYX's boots with different music, not one release ([variants](work/stage1/variants.md)).

## Other copies and variants

The owner's 39 images (56 boot files), compared piece by piece with this one: [work/stage1/variants.md](work/stage1/variants.md).
`work/candidates/owner-BOOT.zip/ZYX.SCL` (2005) is a family B boot (179 edit runs in the code piece, the graphics
identical); `boot.$b` is a Hobeta whose header is damaged (bad checksum, no name), its body 180 edit runs from the
original's code: family B by the look, not examined further. [Doc 13](docs/13-variants.md) describes the variants as differences in `src/res`, the music and a few code switches.

## Sources

- Vadim's decompilation (`work/candidates/sources-2010-vadim/`: `ZYXboot.mac` "Decompiled by Vadim (C) July 2010,
  (C) Unkown Autor 1991-1993", the raw listing `61A8.MAC`, the binaries, the M80/L80 build): the starting point for
  the names, the routine boundaries and the data shapes of `src/main`. Every name was checked against the code and the
  recordings; the names kept, changed and why: [work/stage2/NOTES.md](work/stage2/NOTES.md), and
  [doc 2, 2.7](docs/02-architecture.md#27-vadims-decompilation-and-where-this-case-differs). It has no source for the
  BASIC sector or the music, which are this case's own. Credit: "Decompiled by Vadim (C) July 2010".
- The variants' players and tunes, identified by their texts and AY fingerprints ([variants/README.md](variants/README.md),
  [doc 13](docs/13-variants.md)): the players ASC Sound Master by Andrew Sendetski (ASC), Fuxoft's player by Frantisek
  Fuka, the compiled Sound Tracker, and the game rips' drivers of David Whittaker, Ian Sheridan and Ben Daglish; the
  tunes by Ant P, Frantisek Fuka (Fuxoft), David Whittaker, Rob Hubbard, Ian Sheridan, Ben Daglish (Pac-Mania), Paul
  Hiley (Altered Beast), Dave Rogers (Marauder), Ziutek (Ethanol, ESI), Andrew Sendetski (ASC), Oleg Krasnobaev (OKO),
  Jaroslaw Byrczynski (Stracker), Heather, Ironman, Kent, Ksa and ST Compile; the per-variant table with the
  evidence is in doc 13.
- zxart (offline copy): the entries "ZYX ... boot" with groups and years.
- TOSEC "Compilations" (ZX Spectrum, TR-DOS): the ZYX compilations of 1994.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]                  # builds build/boot.scl and compares it with orig/boot.scl byte for byte
tools/build.sh [SJASMPLUS] --variant NAME   # one of the owner's variants: variants/NAME over src/res
tools/build.sh [SJASMPLUS] --all            # all 56 variants, one line each (56 identical)
```

The sources are `src/basic` (the BASIC sector), `src/main` (the menu and its graphics) and `src/music` (the player
and the tune), each written by `kit/mkgame.py` from its `.ann`; the resources are `src/res/`
([src/res/README.md](src/res/README.md)). The variants are built from the same source: each folder in `variants/`
holds only the resource files that differ, its music piece and the constants it moves
([variants/README.md](variants/README.md)).

## Counts

Computed, not counted by hand (from the case folder, 2026-11-12):

| What | Count | Command |
| --- | ---: | --- |
| documents | 13 | `ls docs/[0-9][0-9]-*.md \| wc -l` |
| figures (PNG) | 42 | `find docs/img -name '*.png' \| wc -l` |
| animations (GIF) | 25 | `find docs/img -name '*.gif' \| wc -l` |
| audio: WAV / MP3 | 3 / 43 | `find docs/audio -name '*.wav' \| wc -l`, the same with `*.mp3` |
| variants identical | 56 of 56 | `tools/build.sh --all` (last line) |
