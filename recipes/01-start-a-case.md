# 01. Start a case

**Answers:** what the original is, what is on the medium, where each block loads.

1. Make `$C/` with `orig/` (the distribution, unchanged: the tape or disk image, any text that came with it),
   `README.md` (title, publisher, year, authors, machine, the md5 and SHA-1 of every original file), `.gitignore`
   inherited from the repository (`work/`, `build/` are ignored).
2. List the medium block by block. For a tape: `python3 $K/tapblocks.py list orig/GAME.TAP` gives each block's
   length, header fields, checksum and the play time at ROM speed, and the total in 48K frames. A non-standard block (turbo, headerless, a
   custom loader) is noted with its pulse lengths from the TZX; for a disk, the catalogue and each file's start and
   length.
3. Write `docs/03-build-and-load.md` 3.1 at once: the table of blocks, sizes as data (+2 for flag and checksum),
   load addresses, play times, the tape's total in seconds and frames, pauses not included.
4. Copy `$K/case-template/` (`README.md`, `WALKTHROUGH.md` with its sections, `docs/` with the document stubs and
   their figure lists, `case.json`, `src/game/game.ann`, `src/res/README.md`, `tools/build.sh`,
   `tools/res_formats.py`) and fill the names.
5. Add the case to the repository README's table (state: in progress).

**Done when:** the hashes and the block table are written, the skeleton is committed.
