# H.A.T.E. — how the reverse was done

A log of the work, in order: what was asked, which unreal-ng capability answered it, and what a snapshot
disassembler (SkoolKit, IDA, Ghidra on a memory dump) would have needed instead. Each step ends with what it
produced in this folder.

## 0. The medium

`orig/HATE.TAP` (md5 `e1c3c9060a7040d0f6ee573b3a6f48d3`), from Vortex's freeware archive:

| Block | Header | Length | Load address |
| --- | --- | --- | --- |
| 0, 1 | BASIC `H_A_T_E`, autostart line 10 | 413 | |
| 2, 3 | CODE `H_A_T_E.1` | 6432 | `$9C40` |
| 4, 5 | CODE `H_A_T_E.2` | 35495 | `$5FB4` |

All six checksums are good. The target of the source build is this file, byte for byte: all three blocks, packed
data included.

The release is not Vortex's own master: line 0 holds the text "Disked by INXS SOFT'89" and a banner routine. INXS
made a disk version and this tape back from it; [3. Build and load](docs/03-build-and-load.md) documents both
layers.

## 1. One recording from power-on

**Asked:** what runs, from the first instruction of the BASIC loader to play, in what order.

`work/` (recordings, analysis builds) is local and not in the repository: the commands of each section rebuild it.
The terms L1, L2, L3 (the analysis levels) and `re_session.py` (unreal-ng's `tools/verification/analysis/`) are
explained in [the docs index](docs/README.md); `$W` in the commands is the unreal-ng checkout, and `data/rom/...`
paths are its ROMs. The gates ("42 240 of 42 240 bytes", `$5B00-$FFFF`) are the rebuild and assemble checks of an
analysis build; "arrivals" are the stages a recording's code arrives in (section 5).

**Used:** TTD recording with the load included (`re_session.py capture --record-load`). The machine starts from a
power-on state with zeroed RAM (saved as `power-on.szx`); the recording starts before `LOAD ""` is typed, so the
loader, the banner, the screen unpacker, the depacker and the game are all in it. The session is saved once
(`time_travel dump`, 26 MB: every frame's checkpoint, the port journal of 12 M reads and 2.4 M writes, the write
journal) and loaded into a new instance for every later question (`re_session.py open --ttd`). A replay is exact,
so every later counter, window build or memory read sees the same run.

**Instead, without it:** a snapshot of the loaded game. The loader, the banner and the depacker would be gone, and
every question about timing would need a new play session that never repeats the last one.

**Produced:** `work/c2/hate.ttd` (45 260 frames), `work/c2/` (the first L1 build: 292 routines, 0 of 1811
checkpoints diverged).

Note: the emulator's fast tape loading (the ROM's LD-BYTES trap, on by default) loaded the blocks in a few frames
each; the load takes 2 540 frames instead of about 13 200 (263 s of tape signal, doc 3.1, plus the pauses between blocks). The game does not depend on it (all three blocks go
through the ROM's LD-BYTES); the real-speed tape is documented from the block lengths and the ROM timing.

## 2. Static pass over the tape

**Asked:** what each block is before running anything.

**Used:** a block splitter (checksums), the BASIC listing, z80dasm over the REM code and the start of each CODE
block, the ROM itself (`data/rom/48.rom`) to check every ROM address the loaders jump to.

Findings, each checked later on the recording (step 3):

- Line 10 is the whole loader: `PAPER 0: BORDER 0: POKE 23624,0: INK 0: CLEAR 24499: RANDOMIZE USR 23788:
  LOAD "H_A_T_E.1" CODE: CLS: RANDOMIZE USR 40000: POKE 23739,111: LOAD "H_A_T_E.2" CODE: RANDOMIZE USR 24500`.
  Line 20 is `REM NO POKE`; line 30, `RANDOMIZE USR 25000`, starts the game: BASIC falls through to it when the
  depacker returns.
- USR 23788 is INXS's banner in line 0's REM: a bold font made from the ROM's (`$3D00`, `b | b >> 1`, at `$C350`),
  "H.A.T.E." (line 1's REM) printed eight times at row 10 with INK 0 to 7, three frames apart (a fade in), then
  "Disked by INXS SOFT'89" sliding in from the right on row 12.
- `POKE 23739,111` points the S channel's output at `$096F`: a lone `RET` in the ROM (checked). The ROM's
  "Bytes: H_A_T_E.2" message is printed nowhere and the loading screen stays clean.
- `H_A_T_E.1` (USR 40000) is position independent: `CALL $007C` (a lone `RET` in the ROM) leaves its own address
  below SP. It unpacks a screen: RLE `00 N V`, the bitmap by pixel lines, then the attributes.
- `H_A_T_E.2` (USR 24500) moves its 55-byte depacker into the printer buffer (`$5B8C`), moves the packed data
  down `$64` bytes with the ROM's `LDIR; RET` at `$33C3` (checked) and unpacks backwards into `$5FB4-$FFFF`: RLE with
  the marker `$97`.

**Produced:** `work/tape/NOTES.md`, `work/tape/*.bin` (the blocks).

## 3. The packers, proved against the recording

**Asked:** do the static readings hold, and can the packed blocks be made again from their contents?

**Used:** TTD `memory_at` (the 64 K view at any frame and T-state of the recording, without running the machine)
and a binary search over frames.

- `tools/depack.py` (the depacker in Python) gives the memory `$5FB4-$FFFF` of frame 2613 exactly: 0 of 41 036 bytes
  differ. The search found 2613 as the first frame after the depacker's last write: the memory equals the image from
  the start of frame 2613 (the depacker's last writes put back bytes already there) until it returns at t 53 257;
  then the game writes its stack and variables.
- `tools/pack.py` packs that image back into the 35 395 bytes of the tape, identical. The rules came from the
  tokens of the tape's stream: runs from three bytes on; zeros 256 at a time while 256 remain, then up to 127;
  other bytes up to 127; a lone `$97` escaped.
- `tools/screen_depack.py` gives the screen of frame 2531 exactly (0 of 6 912 bytes differ); at frame 2530 the
  unpacker is still on attribute row 21. `tools/screen_pack.py` packs it back into the tape's 5 965 bytes, identical
  (runs from four bytes on, zeros always a run).

**Instead, without it:** dumping memory at the right moment means stopping the game there with a breakpoint and
saving a snapshot, once per question; frame 2613 would have been a guess.

**Produced:** the four tools; `docs/img/load-1-inxs-banner.png`, `docs/img/load-2-loading-screen.png` (frames 2380
and 2531 rendered by `tools/zxscreen.py`).

## 4. The tape from source

**Asked:** can the tape be made again from sources, before the game itself is reversed?

**Used:** sjasmplus, the packers of step 3, a tape writer; `cmp` against `orig/HATE.TAP`.

- `src/loader.asm`: the BASIC program as tokens and the banner as code. The first build was two bytes short: the
  original has a space after each `LOAD` token, as it was typed. Identical since.
- `src/screen.asm`: assembling the unpacker found three misreadings of step 2, all in the parameter handling and
  the run state (the `INC HL` after each picture parameter is unconditional; `RES` of the run flag is skipped when no
  run is on; the picture's length counts two bytes past its data). `tools/screen_depack.py` was corrected with it.
  Identical since.
- `src/depacker.asm`: identical at once.
- `tools/tap.py`: the CODE headers hold `$2020` as their second parameter, not the ROM's 32 768: the tape was made
  by a copier.

**Produced:** `tools/build.sh`: `build/HATE.TAP` identical to `orig/HATE.TAP`, all 42 415 bytes. The game image in
it was at first unpacked from the original; `src/game` replaced it in 6.13.

## 5. Tool gaps found and fixed in unreal-ng

The first L1 builds over the whole recording showed five gaps in the analysis. They were fixed in unreal-ng (with
fixtures and tests, branch `analysis-stages`) before going on:

| Gap | Seen as | Fix |
| --- | --- | --- |
| One build over a program that arrives in stages mixes the stages: the depacker's buffer and the game's code at the same address | the loader's bytes classified with the game's | **code arrivals**: the first run of bytes written during the recording, one per writer routine (where, when, who wrote it); **window builds** from any frame / T-state to any frame, with their own start image (`build --stage N`) |
| Every loaded byte that ran was marked self-modifying code | thousands of SMC marks on the game | SMC now means written after it ran |
| An overlay (code overwritten by a later stage) gave one finding per opcode | 174 near-duplicate findings | one finding per overwritten run |
| A host trap that runs as one instruction lost its writes: L1 kept 64 bus cycles per instruction, the fast tape load writes a whole block at the ROM loader's entry | the second build listed 31 arrivals: the loaded bytes had no load as their writer (the ROM's RAM test was the last one), so every return from the ROM into the banner was a new arrival, each "written `$4000-$FFFF`" | the events past 64 go to a buffer that grows once (up to 128 K); an arrival's run is the bytes its own writer wrote; one arrival per writer and run (`TrapWritesPastTheEventBuffer`, the fixture's stage 2 now calls back into the loader) |
| The L1 JSON held per-byte kinds only, no counts | no memory heatmap could be drawn from a build | `byte_counts`: reads, writes, first and last frame per byte, dense per page; `tools/heatmap.py` renders them |

Since then the whole-recording build lists the arrivals, and each stage is built from its own arrival.

Later gaps, found while writing the game's source and working down the review queue (sections 6.13-6.15):

| Gap | Seen as | Fix |
| --- | --- | --- |
| A tool edit in the recording (the fast tape load, a script's poke) writes memory past the bus: the replay applied it, L1 did not see it | the loaded block had no writer, its bytes no uses | the replay reports every byte an edit changes, in each bank it maps, as a write of the instruction pending at the edit (`ToolEditWritesAreUses`) |
| A seek shows its position's picture by replaying the frame, then puts the machine back; the engine's event cursor stayed where that replay left it | an edit right after the first keyframe (in a recording that starts at the tape load, the fast load comes 55 T-states in) was applied inside the seek and skipped by the replay that followed: no writes for the loaded block | two causes, both fixed: (1) the live-state snapshot now keeps the engine's event cursor and frame state too, so the replay sees the edit; (2) the edit's bytes were folded as bus cycles of the pending instruction, a `CALL` into the loader, so they counted as pushes: they are now plain data writes of that `CALL` (the trap runs the whole loader at its entry's fetch and returns, so the entry itself never starts as an instruction) (`FastTapeLoadWritesAreUses`) |
| The skool draft wrote an instruction whole when its entry ended inside it (code later overwritten by a buffer that starts at the instruction's last byte) | the rebuild gate failed at `$8082` (`JP` at `$8081` into the buffer entry at `$8083`, one byte written twice), the assemble gate shifted | the instruction's own bytes as `DEFB`, the instruction in the comment (`SkoolDraftInstructionCutByTheEntryEnd`); the bot's recording rebuilt again with it: both gates pass, 42 240 of 42 240 bytes |
| L1's self-modified mark (`kSmc`, written after it ran) could not tell an operand patch from a buffer laid over code that ran once | doc 2.7 had to sort the bot game's 123 marked bytes by their writers by hand; the code map called the title player under the playfield buffer self-modifying; L3's `code-overwritten` missed the overlay written by plain `LD (HL),r` | a byte written after it ran and never run after any such write is `overlaid` (the last field of a `byte_use` row; a byte that ran once after a write stays a patch); the code map counts only patches, L3 reports overlaid code whatever wrote it (`PatchIsNotOverlay`, `BufferOverCodeIsAnOverlayPatchIsNot`, fixture `patch-overlay.asm`); on p2: 12 patches, 111 overlaid, eight overlay findings |
| The font claim covered every code from the first glyph drawn to the last, including unused slots holding other data | three "font and text cannot both hold" conflicts at the credits (`$63DB-$63FE`), resolved by hand in 6.6 | a slot read by some code whose bytes no drawing code ever put on the screen is no glyph: the claim splits around it; a slot another routine drew stays (the score digits) (`AnalysisDetectorFonts_StringInAnUnusedSlot`, fixture `font-slot-text.asm`); on p2 the font is codes 45-58 and 64-88, conflicts 241 to 238 |
| L3's `index-past-table` counted every reader of a table, so a byte-after-byte walk through a larger structure (a list, a block copy, a mask) "read past" a table L2 found inside it | ten bug findings on the bot's game, six of them walks (`$C99E`, `$CF02`, `$FBC7`, `$FE00`, `$FF00`) | only accesses that read through an index (L1 `indexes`) count (`IndexPastTableNeedsAnIndex`, fixture `index-past-table.asm`: a real index past a table followed by code, and a walk around a second table); on p2 four remain, each a table L2 measured too short (doc 2.7) |
| The screens detector knew back buffers only as block copies; the playfield buffer goes to the screen through `Blit`'s unrolled loads, so no detector saw it whole | `$8000-$BFFF` as 7 626 small "buffer" claims of the records detector, two false sprites, and 23 unknown areas of 17-31 bytes at page starts | a run of 2 K or more read by routines that write the screen's pixels and rewritten again and again (4 writes or more, one for every 64 reads at least: a sprite's or font's source is written never or once) is a back buffer, layout `drawn` (`AnalysisDetectorScreens_DrawnBackBuffer`, fixture `drawn-back-buffer.asm`); on p2: one claim `$8000-$BFFF`, read by `Blit` `$D35E`, unknown areas in the game image 36 to 13 |
| Code and the buffer laid over it later were a conflict ("cannot both hold"), though both held, one after the other, and the overlay was already the `code-overwritten` bug | 10 new conflicts with the back buffer claim, and most of the old 238 between the title player and the records detector's small buffers | no conflict when every byte of the overlap that ran is `overlaid` (`OverlayIsNoConflict`); on p2 conflicts 248 to 65, export gates still pass (42 240 of 42 240 bytes; skool2asm warnings 784 to 573) |
| L1 took an HL walk's step as the most common gap between its bases; `PairScan` (`$E56F`) restarts its walk at +2 of each 16-byte record (`ADD HL` to the box fields), so its bases sit at 16k and 16k + 2, gaps 2 and 14 equally often | "313 records of 2 bytes, used by `$E56F`" over the object table `$C000-$C271`, 18 records/records conflicts with every 16-byte view of the same table | L1's step is the bases' period (the distance most bases repeat at); the records detector folds a plain walk's restarts onto the record starts (at most 4 restart places, each at two records or more, filling at most half of their lattice's slots, records back to back), else the most common gap as before: `SegmentRows` (`$C8EA`, word lists with holes, a period of 8) stays 2-byte records (`AnalysisDetectorRecords_WalkRestartsInsideRecords`, `AnalysisDetectorRecords_WordListsAreNoRestarts`, fixtures `records-hl-restart.asm`, `records-word-lists.asm`); on p2 `$E56F`'s walk is 40 records of 16 bytes |
| "Not accessed in the replay" conflicted with code, and a text claim with the data claim around it | 28 conflicts between the ROM's signatures (reset, RST, BEEP, PRINT...) and the code map's untouched fallback; 18 between the menu and HUD strings and the blocks `$EE17` reads them from (`$F0E4-$F1A8`, `$63DB-$64FE`) | untouched says nothing of the bytes, text is data: neither conflicts with a claim from the bytes' content; code over data or text still does (`UntouchedAndDataHoldContentClaims`) |
| ROM bytes only written were plain data | "Data, 1 bytes, used by `$D35E`" at `$0100`-`$0800`, the one at `$0400` a conflict with the ROM's BEEP | a ROM byte written and never read is a sink, "written only, in ROM (the writes are lost)", in conflict with nothing: the blit's clip writes (doc 6.3) (`AnalysisDetectorCodeMap_RomWriteSink`, fixture `rom-write-sink.asm`); on p2 conflicts 65 to 0, export gates still pass (42 240 of 42 240 bytes; skool2asm warnings 572) |
| A POP took its word's provenance only from the PUSH that wrote the slot; a table SP walks was never pushed, so its words were no pointers, and SP did not count as an index | `BlitAddresses` (`$D5B2-$D9D3`, 528 screen addresses `Blit` pops) an unknown area, "1058 bytes accessed as plain data" | a slot no PUSH, CALL or interrupt wrote holds memory: the POP reads the word there, and a pointer table may be read through SP; a word whose bytes the stack wrote in the replay (popped before the first push: the stack the recording began with) is no pointer at all (`AnalysisDetectorPointerTables_ListPoppedBySp`, fixture `pop-list.asm`, its start pops two words of the stack before any push); on p2 `$D5B2-$D9D1` is a table of 528 pointers, the end mark `$D9D2` data; unknown areas in the game image 13 to 12; gates pass (42 240 of 42 240, skool2asm warnings 580) |
| L1 took a sprite's mask only from an AND with the screen; a sprite masked into a back buffer reached the screen through a copy without it | `DrawSprites` ANDs each mask byte into the playfield buffer, so the sprites came out as unmasked single-byte columns | a buffer byte keeps the mask merged into it (an AND's operand, or the next source when the value merged the byte it overwrites), and the copy to the screen draws with it (`AnalysisDetectorSprites_MaskCarriedThroughBackBuffer`, fixture `sprite-drawn-buffer.asm`) |
| Graphics dropped every frame whose lines go up through memory, as a known limit | the sprites `$6580-$7FFF`: the blit shows the buffer columns bottom line first, line step -2 | such a frame is read from its lowest address and its claim is marked `bottom_up` (gallery and skool pictures flipped) (`AnalysisDetectorSprites_StoredBottomUp`, fixture `sprite-bottom-up.asm`); on p2-spr `$6580-$7FD5` masked sprites, 21, 17, 13 and 14 lines; gates pass (42 240 of 42 240) |
| A picture could be claimed over the bytes of a string | the blit once copied a buffer column filled from the strings in the font's spare slots: a sprite at `$64C8-$64FF`, 3 sprite/text conflicts | bytes the text detector found (read as character codes) are no pixels: a picture mostly over text is none (`AnalysisDetectorGraphics_TextIsNoPicture`, fixture `text-as-pixels.asm`) |
| A sprite block the recording never drew stayed unknown, though the pointer table gives its bounds and a sibling block of the same size shows its layout | `SpriteTable` `$C300` points at 20 blocks of five sizes; the recording drew none of `$6A6C` (630 bytes) and `$70FC` (420 bytes) | a fully untouched block between two targets of a pointer table copies the sprite claims of a drawn block of the same size, shifted, as inferred (`AnalysisDetectorSprites_PointerTableBlockNeverDrawn`, fixture `sprite-pointer-blocks.asm`; the test fails with the rule off); 176 analysis tests pass; on p2-all it did not fire: L2 found no pointer table of four entries at `$C300` (the words reach their use through the draw list in memory, see 6.14) |
| An init table broke at the first byte nothing read, so a table of short entries in wider slots started late or was no table | the shadow shapes `$5B00-$5B5F`: 4 bytes a strip in 8-byte slots, the last 4 of a slot never read; L2 claimed `$5B08`, `$5B28`, `$5B48` and L3 gave three index-past-table bugs | a run goes on over up to 7 bytes the same routine wrote but nothing read when a read byte of that writer follows and the entry before the gap is 4 bytes or more and no shorter than the gap; the first version, without that condition, swallowed single variables read here and there in a copied area (`AnalysisDetectorVariables_GroupsAndStrides` failed) (`AnalysisDetectorInitTables_PaddedEntries`, fixture `init-padded.asm`, fails with the rule off; 177 analysis tests pass); on p2-all one table `$5B00-$5EEF`, the three bugs gone |
| L1 followed a pointer's provenance through registers and the stack, not through memory: a word stored into a list and used from there was credited to the list only | `DrawSprites` copies the word at `$C300 + (+8)` into the draw list `$6500`, the drawing loop uses it from there; L2 saw only `$C31C-$C31F` in `SpriteTable`, so the pointer-block rule had no table | a byte stored from a register remembers the memory byte the register was loaded from (any other write forgets it); a word used as an address whose two bytes came that way from a word elsewhere makes that word a pointer too, the list's word stays one (`AnalysisDataFlow_PointerThroughAList`, fixture `pointer-through-list.asm`, fails with the rule off); on p2-via `$C300-$C32D` is a pointer table of 23 pointers, and the pointer-block rule fills `$6A6C-$6CE1` and `$70FC-$729F` with inferred masked sprites |
| A font claim ended at the last code a text printed | `FontHigh` `$6400-$64D7`: "Y" and "Z" (`$64C8-$64D7`) never printed, left unknown | the font goes on over up to 8 glyph slots on each side that nothing read or drew and no other claim holds, within codes 32-127 (`AnalysisDetectorFonts_StringInAnUnusedSlot` extended, fails with the rule off). On p2-via the font still ended at `$64C7`. The glyph loop at `$EE68` read `$6490-$64CF`, and L1 saw "Y" drawn 8 times, but too seldom to join the font's object; the first version only took slots nothing drew, and the first refinement (a slot read only by the glyph readers) still kept that condition, so p2-fnt changed nothing. Final rule: a slot whose bytes only the glyph readers read and no other claim holds is a glyph, drawn or not. On p2-fnt `FontHigh` is claimed to `$64D7` (codes 64-90, "Z" included), the lower half from `$6328` (code 37), and the unknown `$64C8-$64DA` is gone |
| `index-past-table` flagged the draw list `$6500` once the other walks were gone: `DrawShadows` reads the mask at `$6500` + the shadow entry's mask offset (+5, `$FE69`, `$FE71`, ...), so one index read `$6500-$6543`, around L2's pointer table `$6502-$653F` on both sides | the last index-past-table bug on p2-fnt | a reader whose every index (all accesses through one selector byte) reads on both sides of the table addresses a larger structure the table lies in, no index past it; an index running off one end still counts (`IndexAroundTableIsALargerStructure`, fixture `index-around-table.asm`, fails with the rule off; `IndexPastTableNeedsAnIndex` still passes, 183 analysis tests). On p2-ipt bugs 9 to 8, all eight the overlays of doc 2.7. L2 still calls the record-address words at +2 of the 4-byte draw-list entries a "Table of 31 pointers" with stride 2, though only every second word was used as a pointer: a known L2 limit, left as is |
| The tile set was no graphics claim: `FreshStrip` copies each tile with a chain of 8 `LDI` (`$D564`, the edge tiles `$D536`) from `$C400` + 8 x tile into a column of the playfield buffer, and the screen shows the buffer, not the tiles (the scroll rewrites the buffer's bytes, so the value flow ends there) | `$C400-$C63F` only CodeMap data, the largest RAM unknown after p2-ipt | tiles block-copied into a drawn back buffer: one copier, sources on one lattice base + L x tile (L 4..32), 4 tiles or more, never rewritten, the copied bytes shown one under another (in the buffer or in the tiles): one byte wide, L lines, from the first tile copied to the last; frames inside the set are its tiles, no sprites (`AnalysisDetectorTiles_CopiedToADrawnBuffer`, fixtures `tiles-copied.asm` (the value flow follows the copy) and `tiles-copied-shifted.asm` (a scroll ends it, as here), fails with the rule off; 184 analysis tests pass). On p2-til `$C400-$C63F` is one tile claim, 72 tiles 8 x 8 stored bottom up, as doc 11 has them (58 copied, 14 between them never copied; the edge tiles inside the set); the unknown `$C3FE-$C8E9` shrinks to the tile runs `$C640-$C8E9`; no conflicts, 8 bugs, gates pass, skool2asm warnings 660 |
| The tile runs `$C640-$C8E9` had no claim: `FreshStrip` reads a tile number (`$D55A` `LD A,(HL)`), makes it `$C400` + 8 x tile and copies the tile with `LDI`, but L1 recorded an index only for reads through a pair, not for a block copy's read through HL, so the run bytes were no index of anything | the largest RAM unknown on p2-til | L1 records the index of a block read too (`AnalysisDataFlow_IndexOfABlockRead`, fixture `tiles-copied-map.asm`, fails without it); the level map detector claims the bytes whose values picked tiles of a copied tile set, runs joined over untouched gaps holding tile numbers, as wide as the copying loop's trips when the run is a multiple of them, else one row (a pool of runs read from varying starts, as here); the same test fails with that rule off (185 analysis tests pass). On p2-map `$C641-$C8E9` is a level map of 681 cells, one row (584 cells read, 97 untouched ones between them holding tile numbers): `TileRuns` of doc 11 (`$C640`, 682 bytes) less its first byte, which nothing read. Unknowns 28 to 27, still 8 bugs (the new block-read indexes raise no index-past-table), no conflicts, gates pass, skool2asm warnings 662 |
| The object templates had no claim: `$E1F5` copies 9 bytes from `LaunchTemplates` (`$C2B4` + 9 x kind) into a launched record, `$E891` 16 bytes from `ShotTemplate` `$C360` into a shot record; the records detector claimed the records, not the blocks they were filled from | `$C2BE-$C2E9` and part of `$C333-$C37F` unknown | record templates: one copier filling records of an array from fewer blocks than records it filled, L bytes each at one offset, the blocks on a lattice of L outside the array, are a record array of L-byte templates with the target's fields (`AnalysisDetectorRecords_Templates`, fixture `record-templates.asm`, fails with the rule off; 186 analysis tests pass). On p2-tpl `$C2BD-$C2D7` is 3 templates of 9 bytes (the kinds launched in the replay, on doc 11's lattice from `$C2B4`) and `$C360-$C36F` the shot template; the unknowns shrink to `$C2D8-$C2E9` (the fifth launch template and `EnemyShotTemplate`, copied by the same `$E1F5`: `$E1BD` points DE at `$C2E1`, `EX DE,HL` at `$E1F3`; their copies are missing from L1 because the copy list was full, see the copy cap row below) and `$C333-$C35F`; 8 bugs, no conflicts, gates pass, skool2asm warnings 663 |
| `Directions` `$C340-$C35F` (8 x 4 bytes) had no claim: `$E2B3` reads the step along (a word) and across (a byte) at `$C340` + 4 x the record's direction (+5), the fourth byte never; the records detector's `(HL)` pattern for that routine mixes these bases with the routine's other `HL` walks (the ground profile, the records), so it found no lattice | part of `$C333-$C35F` unknown | records read through an index: bytes read through an index (L1 `indexes`) whose single reader repeats every S bytes, two readers or more a record, untouched bytes between them, 4 records or more (`AnalysisDetectorRecords_ReadThroughAnIndex`, fixture `records-indexed.asm`, where a second `HL` walk in the same routine spoils the pattern; fails with the rule off). p2-idx: `$C340-$C35F` a record array of 8 x 4, fields +0, +1, +2 read, +3 unread (evidence `indexed $E2BD`); unknowns 27 to 26, still 8 bugs, no conflicts, gates pass 42240/42240, skool2asm warnings 664 |
| L1 kept at most 65 536 distinct block-copy runs in all; the back-buffer copiers `$DD52` and `$DDD3` filled the list (31 268 and 31 226 runs), so the template, SCORE and round-table copies first seen after about frame 6 800 were dropped. `HitHandlers` `$C380` was cut into 3 tables at the entries pointing at handlers that never ran, and those handlers were left untouched bytes. `ShotGaugeText` and `RoundText` are strings with control codes and fields the code fills, passed to `PrintString` `$EE17` | `$C2D8-$C2E9`, `$C333-$C33F`, `$C3D0-$C3E1`, `$EC73-$ECAB`, `$ED3B-$EDC9`, `$EF5B-$EF60` unknown or bare data | three generic fixes, each with a test that fails without it: a copy cap per copier (32 768 runs each, 131 072 in all, room for every copier's first 1 024; `AnalysisDetectorRecords_Templates` on `record-templates-busy.asm`, a blitter making 71 680 runs before the template copier); handler tables grow over words inside the hull of the targets jumped to through their dispatch and bridge the gaps between used entries of one dispatch, and an untouched stretch a handler table points at that decodes as code is inferred code with an entry (`AnalysisDetectorPointerTables_UnrunHandlers`, `unrun-handlers.asm`); a printer's argument: an immediate address passed to a routine that prints claimed text is a string up to that printer's terminator, the bytes code writes are fields (`AnalysisDetectorText_PrinterArgument`, `print-argument.asm`). IndexedRecords now skips bytes that reached the screen (a sprite drawn by unrolled code from base + S x frame). p2-rul: `$C2B4-$C2E9` 6 templates of 9 (doc 11's 5 launch templates and `EnemyShotTemplate`), `$C380-$C3EF` one handler table of 56 words, `$EC73`, `$ED3B`, `$ED81` inferred routines, `$C333` and `$C2FA` text with their filled fields, `$EF5B-$EF60` a round-table row; unknowns outside the ROM 8 to 3 (`$7FD6-$7FFF`, `$EF61-$EF9E`, `$FF66-$FFFF`), still 8 bugs, no conflicts, gates pass 42240/42240, skool2asm warnings 655 |
| The last three unknowns outside the ROM: the stack and BASIC's UDGs at the top of RAM, the round table past the rows the replay read, the blank last strip of the last explosion frame | `$FF66-$FFFF`, `$EF61-$EF9E`, `$7FD6-$7FFF` | three generic rules, each with a test that fails without it: bytes only the stack touched are the stack, and an untouched run of 32 bytes or more (4 values or more, no fill) equal to a ROM range is a ROM copy, both Unused; an unknown accessed only by the stack says so (`AnalysisDetectorCodeMap_StackAndRomCopyAreUnused`, `stack-rom-copy.asm`); an array whose step an index gives is completed by one constant fill on its lattice, a whole number of steps long, over rows only the fill and the array's users touched, and one routine's immediate bases walked to the same sentinel compare are one record each (`AnalysisDetectorRecords_FillCompletesIndexedArray`, `records-fill-completes.asm`); a blank object of one shape drawn by the same blit right next to a claimed neighbour of that shape joins it (`AnalysisDetectorSprites_BlankStripJoinsItsNeighbour`, `sprite-blank-strip.asm`). p2-fin: `$FFF5-$FFFE` the stack, `$FF66-$FFF4` a copy of the ROM's letters (`$3E16-$3EA4`), `$EF4F-$EF90` the round table 11 x 6 (inferred, evidence `fill`), `$EF48`, `$EF91`, `$EF98` the SCORE, HIGH and MAX digit fields (7 bytes, the `.` stop); 1 unknown left outside the ROM, `$7FD6-$7FFF`: its neighbour claim `$7F82` is 16 x 21 (two strips), the blank strip one strip of 8 x 21, so the shapes differ and the blank rule does not join it; the cause is the strip runs off the frames' 168-byte lattice (section 6.14). Still 8 bugs, no conflicts, gates pass 42240/42240, skool2asm warnings 662 (the new claims' labels). The save-area claims at `$EF49`, `$EF50`, `$EF56`, `$EF5C` stay under the round table: the save-areas detector runs first |
| The explosion frames were claimed as runs of strips off their 168-byte lattice (clipping at the window drew them in varying column groups), so the blank last strip `$7FD6-$7FFF` of the last frame had no neighbour of its shape | the last unknown outside the ROM after p2-fin | frames from a pointer table's lattice: when a graphics pointer table's targets run on a constant stride F and the drawn column objects of one height tile those blocks (3/4 of the bytes or more, a pass drawing F / C columns side by side), each block is one frame F / C columns wide, the last block F long, the absorbed objects not claimed (`AnalysisDetectorSprites_PointerTableFrameLattice`, `sprite-frame-lattice.asm`, columns clipped differently per frame; fails with the rule off). p2-lat: `$7C10-$7FFF` one sprite 32 x 21, 6 frames, masked, bottom-up (evidence `frame-lattice $C300`), as doc 11 has it; no unknown left outside the ROM (review queue 0 unknown), 8 bugs (the overlays of doc 2.7), no conflicts, gates pass 42240/42240, skool2asm warnings 655. The full core-tests suite passes (20 shards) |
| The save-areas detector claimed both sides of a copy that goes both ways: SCORE `$EF49` as a save area of a round-table row (`$D175` copies SCORE into the row, `$D03E` back), and 30 pieces of the playfield buffer `$8419-$BE1E` as save areas of `SpriteSaveBuffer` `$F800` (`$DD47`/`$DD52` save the strips under the sprites there, `$DDC9`/`$DDD3` put them back) | 35 save-area claims on p2-lat, 31 of them the data saved, not the save | a saved byte is read only to put it back: an area another instruction reads (the score drawn and compared at `$EF23`, the playfield drawn by `$D35E`) is the data saved (`AnalysisDetectorSaveAreas_LiveDataIsNoSave`, `save-live-score.asm`; fails with the rule off). p2-sav: 4 save areas, `$F800` (`SpriteSaveBuffer`, doc 11) and the round-table rows `$EF50`, `$EF56`, `$EF5C` (SCORE kept per round, inside the round-table claim); no unknown outside the ROM, 8 bugs, no conflicts, gates pass 42240/42240, skool2asm warnings 645 |

New fixture `testdata/analysis/fixtures/stages.asm` (a loader, a depacker with two writers, an overlay); tests
`CodeArrivalsOnePerWriter`, `WindowFromAnArrival`, `OverlayIsOneFinding`; the recipe
`.recipe/analysis/reverse-engineering.md` got "Programs that arrive in stages". All 158 analysis tests pass
(`test.sh --gtest_filter='*Analysis*'`) with the fixes, zero warnings.

## 6. The game stage

### 6.1 The game window build

`re_session.py build --from-frame 2613 --from-tinframe 53257 --into work/game` builds L1 over the game alone, from
the moment the depacker returns: 42 647 frames, 357 575 330 instructions, replayed against 1 706 checkpoints with no
divergence. Its start image (`start.bin`) equals `tools/depack.py`'s output byte for byte. The build took 186 s.

**Why unreal-ng:** a window build is a replay of the TTD recording from any T-state. The analysis sees exactly the
game, with the loader's bytes out of the way. A trace-based tool would need the run again, and a static disassembler
has no run at all.

### 6.2 The interrupt handler, found automatically

`re_session.py interrupts --work work/game` lists the routines L1 saw entered by an interrupt, follows the jump
chain and costs it:

```text
interrupt $FDFD -> $8340: 27645 entries in 42647 frames (0.65 a frame), 123 T an entry, 0.1 % of the CPU
```

No address had to be known. The command was added to unreal-ng for this case (the recipe "Interrupt handlers" in
`.recipe/analysis/reverse-engineering.md`). It also shows what the address alone would not: all entries fall in
frames 2616-30260, the title, so the game itself runs with interrupts off.

### 6.3 The architecture

From the call graph (`calls`, `routines.profile`), the executed byte ranges (`instructions`) and the code around the
entry points: [docs/02-architecture.md](docs/02-architecture.md). Findings:

- the title music player is relocatable;
- its IM 2 handler doubles as the key exit and unwinds the stack to SP as saved at entry;
- the game loop has no frame lock;
- 2 319 passes of the pass loop (`$CFAC`) averaged 6.2 frames each.

Every role the document gives a routine is marked with the document that will confirm it.

### 6.4 Pictures from the recording

- `tools/memanim.py`: a GIF of memory over a stretch of the recording. It samples TTD `memory_at` (exact at any
  T-state) every N T-states and flashes the bytes written since the previous sample. First result:
  [the loading screen unpacking](docs/img/anim-loading-screen.gif), 77 pictures (redrawn 2026-11-03 with
  `--screen-geometry`: the screen page as memory at the screen's size, beside the screen, instead of a 768-pixel strip
  of 256-byte rows), and
  [the game depacking backwards from `$FFFF`](docs/img/anim-depacker.gif), 84 pictures.
- `tools/heatmap.py`: per-byte read, write and execute heatmaps from L1's new `byte_counts` (the last row of the first gap table, section 5).
- `tools/check_docs.py`: every mermaid diagram in the docs is rendered with `mmdc`, and every link is checked. A
  diagram that GitHub's mermaid rejects fails here first.
- `tools/code_addresses.py`: on GitHub, a pair of `$` in text is LaTeX math, so `$C2B1-$F2E1` written bare rendered
  as an italic formula. Every address in prose is now a code span, and `check_docs.py` fails on any `$` left outside
  code.

### 6.5 Controls, from the code and the recording

Reading the code around the routines L1 ranked ([docs/05-controls.md](docs/05-controls.md)):

- **The menu** `$F1AA`: keys 1-4 pick the device, 5 starts the demo, 6 the game. After 512 000 idle passes the demo
  starts by itself. Each pass bumps the RNG seed `$EA36`.
- **Four readers** (`$E70E`, `$E756`, `$E773`, `$E789`) fill one control byte `$C290`.
- **The keyboard's Q and A swap** with bit 0 of the round's byte `$C000`.
- **AUTO:** the vehicle flies itself for 70 or 14 passes at the start of a round.
- **Keys in the play loop:** U+G aborts, P pauses, ENTER resumes.

**Why unreal-ng:** `memory_at` reads any byte at any moment of the recording without replaying by hand. It showed
the recording played with device 3, Protek-AGF (`$C28F` = 3 at frames 35 000 and 44 000), which matches the ports
L1 saw. The same call rendered the screens at chosen frames: `docs/img/game-*.png`, the menu, AUTO, play and PAUSE.

The print routine `$EE17` has a simple record format (attribute + `$80`, column, row, characters, `$FF`). A scan for
`LD HL,nn; CALL $EE17` lists every string in the game, the credits among them: written by Costa Panayi, music by
Ben Daglish, ©1989 Vortex.

### 6.6 Text and the panel

[docs/08-hud-and-text.md](docs/08-hud-and-text.md). Two findings:

- **A review conflict resolved by reading.** L1's conflicts "font and text cannot both hold" at `$63DB-$63FE`
  are both true. The credits are stored in the glyph slots of `;<=>?` and `[\]^_`, which no string prints.
- **The GAME OVER box.** It was found by rendering the string `$F0F5` through the game's own font (codes `$22`-`$2C`
  are its big letters).

Which print calls ran comes from L1's executed instructions. ABORT and "PRESS ANY KEY WHEN READY" did not, so they
are described from the code alone.

**Tool gap, fixed.** The conflict should not reach the review queue, and no longer does. The graphics detector's
font claim spanned every code from the first glyph drawn to the last. It now leaves out a slot whose bytes some code
read but no drawing code ever put on the screen, and splits the claim around it (section 5). On the bot's game the
font became codes 45-58 (`$6368-$63D7`) and 64-88 (`$6400-$64C7`; 64-90 after the later font rule, section 5): exactly the five credit slots `;<=>?`
(`$63D8-$63FF`) fell out. The digits, drawn as rows 2-6 by `DrawDigits` (`$EEA4`, [8.2](docs/08-hud-and-text.md)) rather than by the print
loop, stay glyphs because their bytes reached the screen. The three font and text conflicts are gone (241 to 238).

### 6.7 Sound

[docs/09-sound.md](docs/09-sound.md). The title engine was read from the code with the IM 2 handler as the key. The
handler decrements C, H and L of whatever it interrupts. Those three `DEC`s only make sense if the voice loop keeps
its timers in exactly those registers, and it does: C is the note length, H and L are the voice envelopes. The
drum step is the handler's fourth decrement, `($8244)`, an operand inside the player.

For the effects in play, L1's execution counts at each `SET n,($F2BF)` site tell which sound requests happened in
the recording: shots 26, AUTO ticks 560, bit 1 13 times. Bits 0 and 2 never did, so the recording needs input
that reaches those events (the explorer, or a second capture with an input script) before doc 10 can name them (the bot's recording reached both: doc 10.4, 10.8).

### 6.8 The game loop and the recording's story

[docs/04-game-loop.md](docs/04-game-loop.md). The state machine was read from `$CF32-$D0EC`. Then the game's
variables were sampled with `memory_at` every 250 frames: lives `$C2F9`, round `$C2F7`, demo `$F0DB`, SCORE and
HIGH. The samples tell the recording's story without watching it: two games, each losing four lives in round 1, a
HIGH of 280, then the demo. They also confirm the retry path. The round stays 1, the lives fall 4, 3, 2, 1, and
SCORE returns to the round's starting value.

L1's counts tie the code to the run. `$D3F9` was called 1 280 times, ten round starts of 128 pre-roll steps (it
also runs every pass, entered by falling through: 6.10). That told where the course buffer is filled before the routine was read.

The fall-back to an earlier round when the lives run out did not run: the recording never left round 1. It is
described from the code and needed a recording that gets further: the bot's recording (6.12) reached it.

### 6.9 Memory heatmaps of the game window

[docs/02-architecture.md](docs/02-architecture.md#22-the-memory-map). The game window's build (`work/game2/l1.json`, the window of 6.1 built again with `byte_counts`)
carries `byte_counts`, so `tools/heatmap.py` draws the 48 K as 192 rows of 256 bytes, once by count and once by the
frame each byte was last touched, with the module ranges of `tools/regions-game.txt` as labels:

```bash
python3 tools/heatmap.py work/game2/l1.json docs/img/heat-game.png --cell 2 --regions tools/regions-game.txt
python3 tools/heatmap.py work/game2/l1.json docs/img/heat-game-last.png --cell 2 --regions tools/regions-game.txt --frames
```

(2026-11-04: the two pictures are one now, `docs/img/heat-memory.png`, by `tools/fig_l1.py memory`: the composite
and the last-touched panel side by side, the regions named, a colour bar for the frames.)

What only a per-byte counter of a whole replay gives: the screen picture shows, without reading any code, which
columns the game redraws every pass and which are the static panel; the `$8000-$BFFF` block shows a buffer that
replaced the music player; the bright operand spots inside the code range are the self-modified instructions. A
debugger's memory view shows the bytes at one moment, not how often and how late each was used.

### 6.10 Rendering: the blit re-run in Python

[docs/06-rendering.md](docs/06-rendering.md). The blit `$D35E` reads its screen addresses with `POP` from a list
(`$D5B2`). Reading the list as data, rather than the loop as code, gave the whole geometry: 528 cell addresses, 43
of them `$0800` in the ROM (clipped lines), and a column-to-column step of 4 lines, the isometric slope.

The reading was then tested instead of trusted. `tools/playfield.py` re-runs the blit in Python on a memory image
from TTD `memory_at` and compares the result with that moment's screen:

| Frame | Scroll state used | Play-area bytes equal |
| --- | --- | --- |
| 30700 | as in memory | 2 606 of 3 792 |
| 30700 | one step back | 3 504 |
| 35500 | one step back | 3 607 |
| 36000 | one step back | 3 633 |
| 38000 | one step back | 3 744 |

The first try failed: memory is sampled after the scroller `$D3F9` has stepped the state for the next pass.
Undoing that step, as the code does it, gives 92-99 %; the rest is the shadows and sprites, which the pass draws
into the buffer before the blit and takes out after it (doc 6.6, corrected from the annotated source). The model is now
proven on four moments of the recording, and the picture in doc 06 shows the strips as stored next to the screen.

L1's counts per path made the scroll's four-pass cycle visible before the code was read: `$D51D` 903, `$D413` 900,
`$D45B` 899, `$D49C` 897 runs. One fresh strip, two shifted phases and one pass without drawing, in turn.

A correction came out of it. Doc 04 said `$D3F9` did not run during play, because L1 lists 1 280 *calls*. The
instruction count at `$D3F9` is 3 599: the blit falls through into it every pass. Routine entries count calls; the
first instruction's count is the one to read when a routine can be entered by falling into it.

The scroll animation (`docs/img/anim-scroll.gif`) is `tools/playfield_anim.py`: 81 memory images from TTD
`memory_at`, each drawn three ways: the stored strips, the same strips placed by the
Python re-run of the blit, and the real screen. The first version drew only the stored strips beside the screen,
two different projections that could not be compared by eye; the middle panel (`tools/playfield.py`) is the check
that the blit was read right: it agrees with the screen but for the sprites and the panel. The recording is read at any frame without running
the game again; the instance only seeks.

### 6.11 Objects: types named from the screens, handlers counted by L1

[docs/07-objects.md](docs/07-objects.md). The mover `$E15C` and the hit table `$C380` were read from the code; the
names of the types were not guessed from it. `tools/objects_shot.py` reads the object list at a frame with TTD
`memory_at` and labels each live record on that frame's screen, with the isometric projection worked out for the
blit. Domes, jets, launch pads, cubes and dishes were named by looking at what sat under each label in the demo
(rounds 8 and 10) and in game 2; the gallery in doc 07 is cropped from those screens.

Then L1's per-instruction counts decided which branches of the 7 × 8 hit table the recording exercised:

| Handler | Runs | What it proved |
| --- | --- | --- |
| `$EC59` → `$EBCE` | 5 | every point award was a player shot on a jet or missile: 5 × 140 = 280 + 280 + 140 |
| `$EBD1` | 13 | both-hit pairs |
| `$EDCA` | 1, through `$EDDB` | the only dome contact was an enemy shot, not the player |
| `$E271` | 0 | no follower was ever lost; with `$ECE4` sampled at 0 throughout, no pod was collected |

Two first readings did not survive this: "the one dome shot was of type 2" (it was not the player's shot) and the
size table of the hit boxes (the six self-modified operands hold the sum of two sizes, not one size each).

The pods and the convoy came out of the code alone: `$EDFE` writes type 11 into a free slot at a shot dome, `$ECF3`
turns it into a follower, `$D151` / `$D1DE` turn the followers into the next round's lives. None of it ran in the
recording. It is the first thing a second capture has to reach (doc 10; reached in 6.12).

### 6.12 A second recording, played by a bot that reads the game's own records

**Asked:** what the code says about pods, the convoy, a round's end, the next round and the fall back after the last
life (docs 04 and 07). The first recording never left round 1, and random play does not get further.

**Used:** `tools/autopilot.py`, a player that drives the emulator through the WebAPI / MCP and decides the
Kempston stick every 3 frames from memory alone:

- the object list at `$C000` (doc 07's record layout: type, position along, across, height, direction, speed),
  the scroll distance `$D14D`, round `$C2F7`, lives `$C2F9`, followers `$ECE4`;
- the course profile under and ahead of the player (`$5FF7` + position / 2), read with the wall rule of `$E94F`:
  bit 7 limits the position across to `$17`, bit 6 to `$27`, otherwise `$47`; entering a narrower part beyond the
  limit is the crash of `$E979`;
- a planner that moves every threat along its direction table (`$C340`) for 14 passes and picks the position
  across and the height, closest to the goal (a pod, else a dome of type 3, else the middle of the track), whose
  predicted clearance against the hit boxes of `$E555` (7 + both sizes) is largest.

The bot depends only on memory and the emulator is exact, so a run under a TTD recording plays the same game as the
dry run before it.

**Found on the way:**

- The start image of the first recording (`work/c2/start.szx`, frame 30200) is not yet in the menu: a title loop
  runs at `$8000`-`$83FF` until a key is pressed; only then does `$F1AA` read keys 1-4 and 6.
- The stick directions: left increases the position across, right decreases it; on the aircraft "down"
  climbs and "up" descends.
- The course records alternate the vehicle: the first course byte is 0 (aircraft) in rounds 1, 3, 5, 7, 9
  and 1 (ground vehicle) in 2, 4, 6, 8, 10. The per-round object mix (from the blocks at `$F300`): cubes only in rounds 3,
  6 and 10, dishes in 4, 5, 6 and 10, plain domes (type 2) in rounds 5, 7 and 9.
- The first missiles that killed the bot came from the side: launched missiles with behaviour bit 4 turn toward the
  player's position across every 4 passes, so a prediction along a straight line needs a margin.

- In round 3 the bot died again and again near the course's end with nothing near it. The profile under it read
  `$38`: bit 5 set, bits 6-7 clear. `$E4C3`-`$E4F2` make bit 5 a barrier across the whole track: the player is lost
  there when `$ECE4` (followers) is 0; with a follower, `$E68B` = `$FF` hands the vehicle to the AUTO countdown and
  the round ends. So a round is left only with a pod picked up. Code first, then the bot: with one follower it went
  through and round 4 began.
- The planner's first boxes were twice too wide and ignored height. `$E531` sets the window's start at the
  position less half its width: along and across the window is centred (±11 between the player and a dome), in
  height it is ±7 for every pair. (The annotated source later showed two exceptions: against types 11-13 the across
  window starts 2 below centre, and the dishes' box has no height test; doc 07 7.4.) With the real boxes the bot climbs over missiles, and aiming at a dome needs the
  height of the dome + 2 (shots fly 2 below the vehicle); before that, shots passed under the domes and only one
  pod a round was collected. Doc 07 7.4 was corrected ("within 23" was the width, not the distance).
- Launch pads fire their missiles at their own place, beside the player: the planner keeps 19 clear of a pad.

The rounds are saved as they are reached (`--save-rounds`, `work/p1/round-N.szx`), so a change to the bot is tried
on the round that failed; the recording itself is one run from the menu.

**Dry runs:** round 1 cleared with pods collected (`$ECE4` 1, 2) and one hit absorbed by a follower; round
2 (the ground vehicle) cleared with 4 followers; round 3 cleared with 4 lives (2 pods, one lost to a missile, the barrier passed with the other).
The fall back of doc 04 4.4 needs a round
whose start lives minus one is 1-4 before the round where the lives run out, so the recording plays rounds 1-3,
then spends the lives in round 4 (`--give-up 4`: steer into threats) to fall back to round 3, then ends in GAME
OVER.

**The recording** (`work/p2`, 14 020 frames from the menu to the menu):

```bash
python3 tools/autopilot.py --unreal $W --binary $W/cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/unreal-qt \
    --start work/c2/start.szx --work work/p2 --wait 0 --frames 60000 --give-up 4 --save-rounds --record
```

| Frames | What happened |
| --- | --- |
| 210-3 468 | round 1 (aircraft), 4 lives: 4 pods, one hit taken by a follower; cleared with 3 followers |
| 3 480-7 659 | round 2 (ground vehicle), 3 lives: two lives lost to side missiles, cleared on the last with 3 followers |
| 7 671-10 623 | round 3 (aircraft), 3 lives: 1 pod, cleared with 1 follower |
| 10 635-10 919 | round 4, 1 life, the bot gives up: lost at 10 895-10 919 |
| 10 980 | fall back (play from 10 992): round 3 again with 3 − 1 = 2 lives, SCORE back to 8 120 (MAX keeps 11 080) |
| 11 389-11 413 | a life lost |
| 11 462 | round 3 retried with 1 life |
| 11 871-11 895 | the last life lost; round 2's entry holds 1 (it was retried down to 1): GAME OVER from 11 939 |
| 13 971-14 019 | the demo starts; the bot sees round 0 and stops |

The table shows the lives at each round start, and they are the followers brought out of the round before:
`$ECE4` counts the convoy in play and is the lives of the next round (3, 3, 1 above). A hit with followers in
the convoy costs a follower, not a life.

At the end `--record` built L1 over the whole run (83 routines, 903 blocks, 145 loops, 123 million instructions) into
`work/p2/l1.json` and dumped the time-travel session (`work/p2/session.ttd`, 26.6 MB). The instance stays up, so
the round table could be read at any frame by seeking (`time_travel` `seek`, then a memory read;
`tools/roundtable.py`): it showed that a retry overwrites its round's entry, and that the look-back of a game over
leaves an earlier round's SCORE on the panel ([4.4](docs/04-game-loop.md)).

**Pictures from the bot's recording.** Everything below reads the kept instance or `work/p2/l1.json`; nothing
replays the game:

| Picture | Tool | Where |
| --- | --- | --- |
| `game-p2-timeline.png`: round, lives, followers, hits | `tools/gamechart.py work/p2/run.log` (redrawn 2026-11-04: rounds shaded, events named) | doc 10.1 |
| `anim-round-handover.gif`: the convoy lands beside the parked vehicle, round 2 begins | `tools/screen_anim.py --work work/p2 --from 3280 --to 3540 --step 4` | doc 10.2 |
| `heat-coverage.png`: code run in p2 against m1 | `tools/fig_l1.py coverage work/p2/l1.json docs/img/heat-coverage.png --other work/m1/l1.json` (`work/m1`: L1 over the whole first recording from frame 0) | doc 10.1 |
| `heat-records.png`: reads and writes per field of every object record | `tools/fig_l1.py records` | doc 7.2 |
| `heat-screen.png`: screen writes in the screen's geometry, by kind | `tools/fig_l1.py screen` | doc 6.7 |
| `anim-pass.gif`, `heat-pass.png`: one pass as it writes the buffer and the screen | `tools/pass_anim.py --work work/p2 --from 1000 --to 1005 --step 1750 --cache work/passanim/pass-1000-1005.npz`, then `tools/fig_pass.py ... --one` | doc 6.1 |
| `heat-pass4.png`: four passes, by when each byte first changed | `tools/pass_anim.py --from 1000 --to 1018 --step 3500 --cache work/passanim/pass-1000-1018.npz`, then `tools/fig_pass.py` | doc 6.1 |
| `routines-time.png`: own t-states per routine, coloured by job | `tools/fig_l1.py routines` | doc 4.5 |
| `heat-modules.png`: memory per module (the screen insets dropped 2026-11-04: L1's merged ranges overstated them) | `tools/fig_l1.py modules` | doc 2.6 |

The whole-game memory maps first stood in doc 10.1. They showed memory, not gameplay, and doc 2 already has the
same maps for the game window, so they were removed. What doc 10 keeps is the code coverage, which names what the
bot's game reached. The rendering gained what heatmaps can show there: `tools/pass_anim.py` samples one pass every
1 750 t-states and lights each changed byte where it shows, in the whole strip buffer and on the screen. The
pictures show the steps of 6.1 in time: the sprites go into the set the blit will show, the blit runs 1.5 frames
from the left column to the right, `$DD6C` puts the strips back, and this pass took 5.2 frames (6.2 on average, 6.1). The first table gave 4.2 frames and had `$DD6C` start before the blit's end; timed again at a 1 000 t-state step from one scroll step (`$D14D` + 2) to the next, the restore starts 1 000 t-states after the last screen write, as the code says (the call at `$D3F6`), and the pass is 998:17000 to 1003:29560. Over four
passes the scroller's rewritten strips appear, one phase a pass.

`tools/heatmap.py` now draws the screen page (`$4000-$5AFF`) a second time below each panel, in the screen's own
geometry (bitmap bytes where they show, attributes as cells): in the 256-byte rows of the memory grid the screen's
third-interleaved lines cannot be read as a picture. The first heatmaps (doc 2) were redrawn with it.

The routine chart showed hot routines no document named (`$E56F` 656 852 entries, `$EAE3`, `$DD47`, `$DDC9`,
`$EFDC`, `$F089`): they are the insides of passes the docs describe (the hit test's pair scan, the sprite passes
saving and restoring the strips under each sprite). Doc 12 gives each one its entry.

**Doc claims checked against the code while writing doc 10:** the round colour is set at every round setup by
`$D151` falling into `$D338` (`$D320`-`$D337`), not only by the menu; the demo skips the loss check, so it ends
only at the end of its course.

### 6.13 The game's source

The game image now has a source: `src/game/*.asm`, 18 modules, assembled by sjasmplus into the 41 036 bytes the
depacker leaves at frame 2 613, so `tools/build.sh` builds the whole tape from source and it is identical to
`orig/HATE.TAP` (doc 3.7).

The source is not typed by hand. `tools/mkgame.py` writes it from three inputs:

1. the image, unpacked from the original tape's block 5;
2. the instructions the recordings ran (`work/*/l1.json`, 4 568 instruction starts), widened by a walk along the
   branches no recording took (315 more instructions; the walk stops at bytes the game reads as data, counted only
   in the recordings that start after the depacker, since in the load the depacker reads its packed input at addresses that later hold the game's code);
3. `src/game/game.ann`: what the reverse knows, one line an address (module, entry kind and name, the entry's
   description, comments and labels on instructions, data shapes).

It turns them into a SkoolKit control file, runs `sna2skool.py` and `skool2asm.py`, writes address operands that
point inside an entry as `Label+offset` (120; 125 before the five `@isub` constants, 6.15), splits the listing into the modules, and installs it only when
sjasmplus gives the original bytes.

`game.ann` was written in four address ranges at once, each from the docs and from reading the listing, every
fragment checked by the generator alone before the merge. Reading the code for the comments contradicted the docs
in about twenty places, among them the drawing order (the sprites and the shadows go into the playfield buffer before
the blit, not onto the screen after it; the shadows were not described at all), `$D0EF` (the ground profile builder,
not the play loop), the round digits (`$C2FD`, not `$C2FC`), the object block of round r (`$F300` + 128 × (r − 1)),
the hit handlers that never ran (shot against shot removes only the other shot), and `$5B00`-`$5FFF` (tables for the
renderer, put there by the start-up's screen copy, not dead space). Each was checked against the code and the docs
corrected.

Seven hit handlers no recording reached (`$EBFC`, `$EC01`, `$EC04`, `$EC35`, `$EC73`, `$ED3B`, `$ED81`) are code by
`game.ann`, because the table `$C380` is their only way in: the generator takes a code entry of `game.ann` as a seed
for its walk.

From the same entries `tools/refdocs.py` writes [11. Data reference](docs/11-data-reference.md) (218 data entries
with the routines that read and write them) and [12. Routine reference](docs/12-routine-reference.md) (137 routines:
runs, own time, callers, callees, memory read and written, ports). `tools/heatviews.py` takes its routine names
from `game.ann`, so the pictures and the source use the same names (`routines-time.png` redrawn: `$DDE7` is
`DrawShadows`, not an after-blit pass).

**Doc 1 and a module view.** [1. Game design](docs/01-game-design.md) describes the game as a player meets it,
written only from docs 2-12 and the source. Writing it found three more slips: the demo's course is always bright
green (the demo subtracts one less from ink 6 and leaves the round number at 0, so ink 4; the docs said "one less"),
the scoring table missed the 20 awards of `$EC3F` (a missile or jet moving into a shot: the bot's 70 awards are
10 domes + 59 missiles and jets + 1 cube, by L1's calls of `$EBCE` per caller), and the object gallery labelled the
player with a type number it could not know; all fixed. Doc 2.6, the module map, is now drawn from the source's
modules and L1's calls between them, with `heat-modules.png` (`tools/heatviews.py modules`): which module reads and
writes which page, and below it every drawing module's screen writes in the screen's geometry.

**Every label named.** The 303 generated `l_XXXX` jump targets inside the routines are named now (`tools/ann_names.py`
writes them into `game.ann`; the source still assembles to the original image): loops as `...Loop`, branches by
what happens there (`SkipThatRound`, `PodFromDome`, `DrawAsExplosion`), and a self-modified operand reads as the
instruction it patches (`VoiceAPreDelay+$0003` is the OUT byte of the title player's voice A, `ArmObjectLoop+$000D`
the second lap's patch). Reading every branch for its name corrected five comments of `game.ann`: the static
objects' frame is `$70` × ((phase − 1) AND 3), so phase 0 is the last frame, not the first (`$EA95`); a chasing
object goes straight for the player from 3 below to 2 above it, not within 2 (`$E315`); any change of the ground
height, a fall too, picks the shadow shape `$5B40` (`$E01E`); a player being hit skips its steering and the walls
for the pass (`$E82C`); and a window of the pair scan steps 2 bytes, not 4 (`$E541`). Two names had been lost
because a later comment line for the same address replaced them; `mkgame.py` now merges such lines and refuses two
names for one address.

**Every routine described.** The last 29 code entries without a description got one, each read from the code (the
title player's commands and drums with their loop counts, the shadow mask's run entries, `PairScanStep`): doc 12 now
describes all 137 routines (`StartGame` `$9F1C`, entered by the title player's return, is an entry of its own). `PairScanStep` (`$E57F`, entered 640 205 times in the bot's game) is reached mostly by
falling through `PairScanNext` (a gone or dying record, the "nothing" handler of the hit table), not by a jump from
each handler.

**Self-modifying code, sorted.** Doc 2.7 groups the 123 bytes L1 marks as written after they ran in the bot's game
by the routines whose writes cover them: 12 are real patches (the hit box of the moving record, written by
`MoveRecord` into the six compares of the pair scan), 3 are the IM 2 jump at `$FDFD` (start-up, the title player's
hook and its exit), and 108 are the playfield buffer laid over the title player and the end of the start-up, code that
ran once. The mark alone could not tell a patch from an overlay, so L1 gained a generic flag (unreal-ng, analysis
layers): a byte written after it ran and never run after any such write is `overlaid`, the last field of a `byte_use`
row. On p2 it splits the 123 bytes exactly as the writers did: the 12 compare operands are patches, the other 111
(IM 2 jump restored for a play without interrupts, the buffer over the title player and the start-up) are overlaid.
The code map no longer calls overlays self-modified, and L3's `code-overwritten` sees a buffer laid over code even when
plain `LD (HL),r` writes it, not only a block copy.

### 6.14 The review queue, worked down

Each `p2-xxx` below is the bot's recording `work/p2` built again with one more analyzer change (`xxx` names it);
only the latest builds are kept.

**Bug findings, all explained.** L3 raised 18 bug findings over the bot's game. Eight are overlays (doc 2.7: the
playfield buffer over the title player and the start-up's end, and the IM 2 jump restored for a play without
interrupts). The other ten were `index-past-table`; six were walks, not indexes, and went away with the fix in
section 5. The four left read the shadow shapes at `$5B00`-`$5B53` (blocks of 32 bytes; L2's init tables start 8
bytes into them) and the scratch page `$6500` (the draw list, then the mask): tables L2 measured too short, not bugs
of the game (doc 2.7).

**The playfield buffer, one claim.** The analyzer now claims `$8000-$BFFF` as one back buffer read by `Blit` (`$D35E`),
where it had 7 626 small buffer claims and 23 unknown areas (section 5). The conflicts between the title player's code
and what was laid over it are no longer raised: the overlay is the bug finding. Queue after both fixes: 65 conflicts
(from 241), 12 bug findings, 32 unknown areas, 13 of them in the game image.

**The 65 conflicts, all tool gaps.** None was a fact about the game. 18 were `PairScan`'s walk read as 2-byte records
over the object table, 28 the ROM's signatures against "not accessed", 18 strings inside the blocks the menu prints
them from, and one the blit's clip writes into the ROM (doc 6.3) against BEEP. Each got a generic fix with a test in
unreal-ng (section 5). Queue now: 0 conflicts, 12 bug findings (doc 2.7), 32 unknown areas, the same 13 in the game
image; `SegmentRows` stays word lists. Then the blit's address list became a pointer table (section 5): 31 unknown
areas, 12 in the game image.

**The 12 unknown areas left in the game image** are all named in the source (`src/game/game.ann`): the sprite graphics
below the buffer (`$6542-$7FFF`), the launch templates and texts at `$C2BE-$C37F`, rows of `HitHandlers` (`$C3D0`),
the unused block `UnusedC3FE`, the handlers that did not run (`HitBlockOnShot`, `HitBlockOnPlayer`), the SCORE text
(`$EF48-$EF4E`, the stop and the digits), the round object blocks from `$F300` running into `SpriteSaveBuffer` (`$F800`), and the UDG leftover
(`$FF58`). No detector had a kind for them then; the source describes each. All of them were claimed later (section 5,
p2-til to p2-lat).

**How the sprites became a claim.** L1 does see them drawn: 2 869 bytes of `$6542-$7FFF` reach the screen, in 2 177
drawn frames, the commonest 2 × 21 and 2 × 17 with a line step of -2 and strips 42 bytes apart (doc 6.6: a strip is a
buffer column, shown bottom line first). Two tool gaps keep them out of the graphics claims. The frame's lines go up
through memory, which the graphics detector drops as a known limit. And the mask is lost: `DrawSprites` ANDs it into
a buffer byte, not into the screen, so the copy to the screen carried only the pixel byte. The second gap now has a
generic fix in unreal-ng: a buffer byte keeps the mask ANDed into it, and its copy draws with it. The first has one too:
a frame whose lines go up through memory is read from its lowest address and its claim is marked bottom up
(`bottom_up` in the geometry, flipped in the gallery and in the skool pictures). On the recording (`work/p2-spr`)
`$6580-$7FD5` is now masked bottom-up sprites, 21, 17, 13 and 14 lines high, drawn by `DrawSprites` `$EAE3` and
`StampStatics` `$EA38`. Gates still pass: 42 240 of 42 240.

Three limits remain. First, the frame boundaries are approximate. The playfield blit shows the buffer skewed, so
the strips of one frame are not always seen side by side, and a claim may cut a frame or run into the next one. The
true layout is in doc 6.6: four frames a block, the last one a strip narrower. Second, the two blocks the
recording never drew, `$6A6C` and `$70FC`, and the last explosion strip `$7FD6-$7FFF`, stay unknown on p2-spr.
A generic rule now covers the two blocks: the table `$C300` bounds them, and each copies the claims of a drawn block
of the same size (`$6580` for `$6A6C`, `$6F58` for `$70FC`), marked inferred, once L2 sees `$C300` as a pointer
table; on p2-all it does not yet (see the combined run below). Third, one new
false sprite showed up: the blit once copied a buffer column whose bytes came from the strings in the font's spare
slots (`$64C8-$64FF`). That gave 3 sprite/text conflicts. A generic rule removes it: bytes a print loop reads as
character codes are no pixels.

**Why `$F301-$FBC6` and `$FBD4-$FDFC` are no claim.** The bytes are known (doc 11): the ten round object blocks
`$F300-$F7FF`, then `SpriteSaveBuffer`. Four tool gaps kept them unknown; each got a generic fix:

1. The effect table `$F2E2-$F2FF` (6 records of 5) is read by two loops, `$F2D9` from +0 and `$F2A3` from +1. They
   give two record claims one byte apart, and the second one runs a byte into `RoundObjects1`. That is why the
   unknown starts at `$F301`, not `$F300`.
   Generic fix (unreal-ng, records): two read patterns of one stride whose starts lie less than a stride apart are
   one array, the second reader's fields merged in at their offset (`AnalysisDetectorRecords_ShiftedReadersAreOneArray`,
   fixture `records-shifted-readers.asm`, fails with the rule off). On p2-all `$F2E2-$F2FF` is one claim, 6 records of
   5 used by `$F2A3` and `$F2D9`, and nothing runs into `$F300`.
2. `RoundSetup` takes a block apart with 16 LDIRs of 8 bytes at `$D261`: sources back to back, destinations the 16-byte
   slots `$C0B0-$C1A0`, which are already claimed as records. The records detector ignores copies shorter than 16
   bytes, so it never sees the 8-byte records in the source. The recording set up rounds 1-4 and 9 (the pointers at
   `$CF06`, `$CF0A`, `$CF0E`, `$CF12`, `$CF26`). The other five blocks were never read. Their place on the 128-byte
   lattice is known only from `CourseTable`.
   Generic fix (unreal-ng, records): one routine copying blocks of one length into at least four slots of a records
   array makes the sources records with the slots' fields, observed where copied; blocks a pointer table on the same
   lattice names but the run never copied are inferred (`AnalysisDetectorRecords_GatheredByShortCopies`, fixture
   `records-gathered-blocks.asm`, fails with the rule off). On p2-all `$F300-$F7FF` is ten claims of 16 records of 8:
   `$F300-$F3FF` observed (copied by `$D151`), `$F400-$F7FF` inferred from the pointer lattice (rounds 3, 4 and 9 were
   set up after the copy list filled, about frame 6 800, so their copies are missing; section 5, the copy cap row).
3. The save area under the sprites is written by `$DD52` through the moving pointer `$DD6A` and copied back by `$DDD3`
   with the same lengths. In the recording it filled 980 bytes at most, `$F800-$FBD3`. Its last 13 bytes were read as
   a table built by one routine (`$FBC7`), and that table gave the index-past-table bug finding on `$DDD3`.
   Generic fix (unreal-ng, save areas): one instruction copies X to Y, another later copies Y back to X with the same
   length, at least twice; the slots of one saver/restorer pair merge into a Buffer claim, run before the init tables
   (`AnalysisDetectorSaveAreas_SavedAndRestoredStrips`, fixture `save-area.asm`, fails with the rule off). On the
   recording `$F800-$FBD3` becomes "Save area of `$801D-$BFF1`, 980 bytes: copied here by `$DD52` and back by
   `$DDD3`", the false table at `$FBC7` is gone and the unknown shrinks to `$F301-$F7FF`. (The
   index-past-table bug on `$DDD3` was already gone on p2-spr; its 12 bugs are the eight
   `code-overwritten` overlays and four index-past-table findings, three on the tables at `$5B08-$5EEF` read by
   `$E03C` / `$E04B` and one on the pointer table `$6502` read by `$DEFC`.)
4. `$FBD4-$FDFC` was never touched: zeros at the start of the recording, then bytes that disassemble as Z80 code that
   never ran (from `$FC55`). Nothing marked an untouched area as unused unless it was a BASIC line.
   Generic fix (unreal-ng, code map, `FinishUnused`, last of all detectors): untouched bytes no claim explains are
   Unused when they are a fill of one value or code that never ran, whose calls and jumps land on its own
   instructions or in the ROM (fixture `unused-areas.asm`, fails with the rule off). The rule was later split:
   leftover code that never ran is inferred Code now, only a fill is Unused
   (`AnalysisDetectorCodeMap_FillIsUnusedLeftoverIsCode`). On p2-all `$FBD4-$FC54` is "Fill, 129 bytes of `$00`" and `$FC55-$FDFC` "Code that
   never ran, 424 bytes".

**The combined run (p2-all, 2026-11-02).** All the fixes above in one build, the same recording: gates pass (42 240 of
42 240 bytes), conflicts 3 to 0, bugs 12 to 9, unknowns 34 to 32 (skool2asm warnings 632 to 653, all "No label for
address"). `$F301-$FBC6`, `$FBD4-$FDFC` and `$6542-$657F` are no longer unknown; `$EF48-$EF9E` shrinks to
`$EF5B-$EF9E`. The shadow tables are one table `$5B00-$5EEF` and their three index-past-table bugs are gone. One
unknown is new, `$64C8-$64DA`: the false sprite there is gone, and nothing else claims the bytes. They are two
things (doc 11): `$64C8-$64D7` are the glyphs of "Y" and "Z", the last two of `FontHigh`: "Z" is never printed,
and "Y" (in COSTA PANAYI) too seldom to join the font's object (the font claim ends at code `$58`); `$64D8-$64DA` are the attribute, column
and row that open `CreditsText2`, whose text claim starts at the characters (`$64DB`). Two tool gaps: a font claim
stops at the last code printed even when the font's lattice runs on to the next claim, and a print string's header
bytes stay outside its text. The strings show a third. `CreditsText2` is two records,
`$B0,$01,$14,"BEN DAGLISH"` and `$B0,$01,$15,"@1989 VORTEX",$FF`, and the text detector took the second record's attribute `$B0` for a last character with bit 7
("BEN DAGLISH" claimed as 12 characters, `$64DB-$64E6`). The print path is a font read, not a glyph index, so L1 cannot
tell a printed byte from a control byte here; a rule on the record shape alone (a byte with bit 7, two bytes below
`$20`, text) would be tuned to this game, so it stays a known limit until another game shows the same format (still so on p2-rev4, the last run: `$64DB` `"BEN DAGLISH",$B0`). The pointer-block rule did not fire: `$6A6C-$6CE1` and `$70FC-$729F` stay unknown. Its trigger, a
pointer table of four or more entries, is missing: L2 found only `$C31C-$C31F` in `SpriteTable`. `DrawSprites` loads
the word at `$C300 + (+8)` into HL, adds the frame offset and hands it to `SpriteListAdd`, which stores it in the
draw list `$6500`; the drawing loop reads it back from there. L1 follows a pointer's provenance through registers
and the stack, not through memory, so the word's use is credited to the draw list, not to the table. Only the
statics (`$EA38`), which use the word straight away, made `$C31C` a pointer.

**The run after the L1 fix (p2-via, 2026-11-02).** L1 now follows a stored byte back to the memory byte its register
was loaded from. Gates pass (42 240 of 42 240), no conflicts, 9 bugs, unknowns 32 to 29 (skool2asm warnings 653 to
659). `SpriteTable` is one pointer table `$C300-$C32D` of 23 pointers (the unknown `$C2FA-$C31B` is gone), and the
two blocks the recording never drew are inferred sprites with the layout of their siblings: `$6A6C` as 24 x 21
masked frames like `$6580`, `$70FC` as 8 x 14 frames like `$6F58`.

With the font rule on top (p2-fnt, the same day): unknowns 29 to 28, no conflicts, 9 bugs, gates pass (42 240 of
42 240), skool2asm warnings 658. On p2-fnt, 9 of the unknowns lie outside the ROM:
`$7FD6-$7FFF`, `$C2BE-$C2E9`, `$C333-$C37F`, `$C3D0-$C3E1`, `$C3FE-$C8E9`,
`$EC73-$ECAB`, `$ED3B-$EDC9`, `$EF5B-$EF9E` and `$FF66-$FFFF`.

With the index rule (p2-ipt, 2026-11-02): 8 bug findings, every one an overlay (doc 2.7); no conflicts, 28 unknowns,
gates pass (42 240 of 42 240), skool2asm warnings 658.

The 9 unknowns left outside the ROM, against the reverse and the replay's byte use (p2-ipt `l1.json`). Three are
code and data the replay never touched; six were read, and no detector named them: analyzer gaps, not unknowns of
the game.

| Unknown | Touched in the replay | What it is |
| --- | --- | --- |
| `$7FD6-$7FFF` | all 42 bytes | the tail of `ExplosionGfx2C`, the last explosion frame ([11](docs/11-data-reference.md)) |
| `$C2BE-$C2E9` | all 44 | `LaunchTemplates` entries and `EnemyShotTemplate`, copied into records |
| `$C333-$C37F` | 69 of 77 | `ShotGaugeText`, the tail of `Directions`, `ShotTemplate`, `ShellTemplate` |
| `$C3D0-$C3E1` | none | `HitHandlers` rows of type pairs that never met |
| `$C3FE-$C8E9` | 1 160 of 1 260 (`$C400` on) | `UnusedC3FE`, then the course tiles and tile runs that `FreshStrip` draws into the playfield buffer; claimed since p2-map (tiles, level map), `$C3FE-$C3FF` and `$C640` left untouched |
| `$EC73-$ECAB` | none | `HitBlockOnShot`, a mirror hit handler that never ran ([12](docs/12-routine-reference.md)) |
| `$ED3B-$EDC9` | none | `HitBlockOnPlayer` and `HitDomeOnShot`, mirror hit handlers that never ran |
| `$EF5B-$EF9E` | all 68 | `RoundTable` rows, `HighScore`, `MaxScore` and their stops |
| `$FF66-$FFFF` | 10 of 154 (`$FFF5-$FFFE`, the stack's top) | `UdgLeftover`, the 48K BASIC's UDGs left in the image |

The largest gap was the tile set: 576 of those bytes read every strip, drawn into a back buffer and not named. The
copied-tiles rule (section 5) claims it on p2-til; the tile runs `$C640-$C8E9` followed on p2-map (a level map of
tile numbers, section 5). 8 unknowns remain outside the ROM.

(As of p2-ipt; p2-lat closed it, section 5.) `$7FD6-$7FFF` was a known limit of the sprite detector. The explosion frames are 168 bytes each from `$7C10`
(doc 11): 4 strips of 21 lines, a mask and a pixel byte a line, 42 bytes a strip. The detector joins the strips it
saw drawn side by side, and clipping at the window's edges showed them in varying groups. So its claims (`$7DDE-$7E31`
8 x 21 x 2, `$7E32-$7E85` 16 x 21, ...) are runs of whole strips that do not start on the frames' 168-byte lattice.
The last strip of the last frame was never joined to a claim. The frame boundaries come from the sprite table at
`$C300` (doc 6.6); no rule ties drawn strips to a pointer table's blocks yet.

The direct drop is the blank-frame filter of the graphics detector: the strip is `FF 00` on every line (mask `$FF`,
no ink), so as a separate 8 x 21 object (126 bytes past the previous 8 x 21 frame, not joined) it is all blank and
not claimed. The frame's first strip `$7F58-$7F81` is blank too and survived only because it was paired with the
previous frame's last strip. Two generic rules would claim it: a blank frame drawn by the same blit with the same
shape as a claimed neighbour is part of that object, and a pointer table's targets on a constant stride (168 from
`$7C10`) give the last target the same block length.

The 8 unknowns left outside the ROM after p2-idx (seven rows), read against the replay by two parallel agents (2026-11-02),
each with its cause in the analyzer and the generic rule that closes it (the outcomes follow the table):

| Unknown | What it is | Why no detector named it | Generic rule |
| --- | --- | --- | --- |
| `$7FD6-$7FFF` | the blank last strip of `ExplosionGfx2C` | blank-frame filter, see above | blank neighbour frame; pointer-table stride |
| `$C2D8-$C2E9` | the fifth launch template and `EnemyShotTemplate`, both copied by `$E1F5` | L1 keeps 65 536 distinct copy runs; the back-buffer copiers `$DD52` (31 268) and `$DDD3` (31 226) fill the list, and copies first seen after about frame 6 800 are dropped: `$C2D8` read once, `$C2E1` 4 times, none in the list | a copy cap per copier, so one blitter cannot starve the rest; `RecordTemplates` then claims `$C2B4-$C2E9` as 6 x 9 |
| `$C333-$C33F` (13 bytes, below the 16-byte bar, data) | `ShotGaugeText`, printed by `$CFE9` `LD HL,$C333` / `CALL $EE17`; `$C336-$C33A` refilled with spaces and `/` before each print | the text detector drops bytes written by code; control codes `$84 03 06`, `$87 02 06` leave one printable `/` | a printer's argument: an immediate address passed to a routine that prints claimed text is a string up to that printer's terminator, parsed with its control codes; covers `RoundText` `$C2FA` too |
| `$C3D0-$C3E1` | `HitHandlers` row 5 and row 6 entry 0, type pairs that never met | the pointer-table detector grows a handler table only over words pointing at known code; the never-run handlers stop it (also `$C38E-$C39D`, `$C3EC-$C3EF`) | accept neighbour words inside the hull of the jumped-to targets, merge groups of one dispatch (`$EBCD`), mark the targets as inferred entries |
| `$EC73-$ECAB`, `$ED3B-$EDC9` | `HitBlockOnShot`, `HitBlockOnPlayer`, `HitDomeOnShot`: mirror handlers that never ran | `FinishUnused` sees a table entry pointing at the stretch and leaves it ("not leftovers"), and nothing claims it | a table-entry stretch that decodes cleanly is inferred code with a routine entry at the target |
| `$EF5B-$EF9E` | `RoundTable` rows 2-10 (6 bytes: lives, SCORE), `HighScore`, `MaxScore` and their `.` stops | only rows 0-2 were read (the read-through-index rule wants 4); the `$D03E`/`$D175` copies were dropped by the copy cap; `$EF49`, `$EF50`, `$EF56` were claimed as save areas | the copy cap; an indexed array grown by one bounded fill on its lattice (rows 1-10, 60 = 10 x 6 from `$EF55`; row 0 at `$EF4F` was claimed already); one routine's immediate arguments (`$EF4E`, `$EF97`, `$EF9E` to `DrawDigits`) with one walk and one sentinel as instances of one record |
| `$FF66-$FFFF` | `UdgLeftover`; the sprite list runs into `$FF58-$FF60`, the stack uses `$FFF5-$FFFE`, `$FF61-$FFF4` is free | `FinishUnused` claims fills and code only, not the stack's bytes or a ROM copy | stack-only bytes from the lowest SP to the first SP are the stack; an untouched run equal to a ROM range (the UDG letters A-U at sysvar UDG) is a ROM copy |

After p2-rul (the copy cap, handler tables and printer arguments, section 5) 3 of them remain: `$7FD6-$7FFF`, `$EF61-$EF9E` (round-table rows 3-10, never read, and the HIGH / MAX digits) and `$FF66-$FFFF`. After p2-fin (stack, ROM copy, fill-completed arrays, section 5) only `$7FD6-$7FFF` remains. After p2-lat (frames from the sprite table's lattice, section 5) none remains: every byte outside the ROM has a claim.

The same reading corrected doc 11 (`UdgLeftover` is not unread: the unbounded sprite list runs into it;
`EnemyShotTemplate` is copied by `$E1F5`) and the source: `LD SP,$FFFF`, `LD SP,$FFF9` (the operand the title player
patches), `LD HL,-6` and `LD HL,-10` (follower spacings) were written as `UdgLeftover` + offsets; the TAP still
rebuilds identical.

### 6.15 Resources out of the source

The source held the game's data as 3 250 lines of `DEFB`: the bytes were right, but a sprite, a course or the
title tune was not a thing one could pick up. Now an entry of `game.ann` followed by `@res FILE` is a resource:
`tools/mkgame.py` writes its bytes to `src/res/FILE` and its data lines become `INCBIN "res/FILE",offset,length`
under the entry's label and description (entries naming one file share it: the font's two halves, the game
screen's pixels and attributes, the three tile sets). 66 entries, 62 files, 28 067 bytes: the font, 14 sprite
blocks and 6 explosion frames by table slot, the tiles, the game screen as a `.scr`, the tile runs, the ground
anchors, the ten courses and the ten rounds' objects, the title song with its patterns and drums, the renderer's
tables, and the leftovers (the stale copies, the profile buffer's image, the save area, the UDGs). The loading
screen moved to `src/res/screens/loading.scr` and the tail of block 3 to `src/res/leftovers/screen-tail.bin`.
Every file is listed in [src/res/README.md](src/res/README.md) with its address, size, labels and format;
`tools/res_preview.py` draws the graphic ones to `docs/img/res/` (the sprite previews follow doc 6.6: four
frames, strips of mask and pixel pairs, bottom line first, and show the vehicles, the pads and the explosion as
the game draws them). The files are the original bytes, not converted at build time: editable formats were the next
step (PNG and text sources, below); `tools/build.sh` still writes a tape identical to `orig/HATE.TAP` (SHA-1 `bbe36140...`), checked from a
clean copy of the tree.

Regenerating the source from `game.ann` showed that two outputs had been corrected by hand after the generator
ran (6.14): five instructions in `src/game` (`LD SP,$FFFF`, `LD SP,$FFF9`, `LD HL,-6` twice, `LD HL,-10`, which the
generator writes as `UdgLeftover` + offsets) and five rows of doc 11 (`ExplosionGfx2C`, `EnemyShotTemplate`,
`SpriteSaveBuffer`, `SpriteListArea`, `UdgLeftover`). Both now come from `game.ann`: a new line
`@isub $ADDR INSTRUCTION` writes an instruction as the source means it (a constant the image's bytes cannot tell from an address;
skool2asm prints the negative ones in hex, `LD HL,-$0006`), and the five descriptions moved into the entries, so
`tools/refdocs.py` writes doc 11 identical to the corrected one. The rule stays: edit `game.ann`, never the output.

The analyzer review in unreal-ng (records, graphics, code map, L3 bugs) was checked against the same session
(p2-rev3): 19 unknowns (all in the ROM) and 42 240 of 42 240 bytes rebuilt, as before; a ninth bug,
`index-past-table` on the draw list `$6500`, came back with the review's per-reader rule. Reading the code again
corrected doc 2.7: `DrawShadows` ANDs a 17-byte mask row in, the loop `$DEE6`-`$DEFA` (four instructions, four
passes) the first 16 bytes, `$DEFC` the 17th; no instruction alone reads on both sides of L2's pointer table
`$6502-$653F`, the routine's connected reads `$6500-$6543` do. The rule now joins a reader's index reads with its
routine's connected ones (fixture `index-around-table-fields.asm`). Built again with it (p2-rev4), the session
gives 8 bugs again, none on `$6500`, with 19 unknowns and 42 240 of 42 240 bytes rebuilt.
The analyzer changes of this reverse (records, sprites, code map, L3 bugs, the build windows) are in unreal-ng's
master from `9de1d0fdb` (2026-11-03): a build of that revision or later reproduces these sessions.

Every resource now has a picture in `docs/img/res/`, and the gallery at the end of
[src/res/README.md](src/res/README.md) shows them. `tools/res_preview.py` draws them by running the game's own rules on the
files, so each picture also checks a reading of the format:

- **Courses.** A course expands through the row lists `$C8EA`. `FreshStrip` builds each strip from the edge tile
  plus tile i of row s + i at offset i, with tiles drawn first byte at the bottom. The ten strip panoramas come
  out as continuous landscapes: runways, ridges and trenches, with no breaks between strips.
- **Ground profiles.** These come from the anchors of `$C9FE`, the way `$D0EF` reads them. Their peaks fall where
  the panoramas rise.
- **Round objects.** The objects are placed by their position along and across, and named by type.
- **Title tune.** The song and its patterns are run with the command lengths that the handlers of the table `$83FC` consume. They
  give 56 s (2 800 frames) of two voices and drums before the song jumps back, with no command left over.
- **Sprites and the explosion.** Each sprite has a GIF of its four frames, and the explosion has one of its seven
  steps.

The course pictures were then checked against the recording, byte by byte. `tools/verify_buffer.py` rebuilds all
four sets of the playfield buffer from the course data alone: the fresh strips the way `res_preview.py` draws them,
and the 2-, 4- and 6-pixel phases by doc 6.4. It compares them with the bot's game at seven moments in rounds 1 to 4,
including the hand-over from course 1 to course 2. Every strip outside the set the blit shows is explained exactly:
either it equals its rebuilt strip, or it holds a pad stamped over the course. The pad is `SpriteGfx1C` laid on
with mask and pixels, each strip 4 lines below the one before, in the frame that matches the set's phase (docs 6.4
and 6.6). The only strips left unexplained are in the set the blit shows, where the pass's sprites sit. Two things
became exact along the way:

- **The phase strips.** Doc 6.4's "a copy moved down by a line or two" is, as a rule over a strip and its
  neighbour: s[y + 1] and s + 1[y − 3] for 2 pixels, s[y + 2] and s + 1[y − 2] for 4, s[y + 3] and s + 1[y − 1]
  for 6.
- **The pre-shifted frames.** A sprite block's four frames are one picture moved by 2 pixels each.

The ground profiles and the round objects were checked the same way:

- **Ground profiles.** `tools/verify_profile.py` builds the profile in the 8-bit arithmetic of `$D0EF`: the step is
  shifted with `SRA` and subtracted from the whole byte, walls included. The result equals `$6000-$62FF` of the
  recording at six moments in rounds 1 to 4, all 768 bytes. The profile pictures now draw these bytes, not only the
  anchors.
- **Round objects.** In `tools/verify_objects.py`, the 16 records at `$C0B0` hold their round's file byte for byte
  in the frame of each round's setup (doc 7.1).

The sprites and the title tune were checked last:

- **Sprites and explosions.** `tools/verify_sprites.py` takes the buffer at the moment `DrawSprites` starts, after
  the shadows, and draws the list `$FF00` into it from the files of `src/res/gfx` by the rules of doc 6.6. It
  compares the result with the buffer when the list is done, in five passes of the bot's game: 8 to 15 sprites, eight
  explosion frames, the whole buffer equal. Every sprite address is a block plus whole frames and strips, and the 20
  files equal memory at the addresses of the table `$C300`. Finding the moments needed care: the list pointer holds
  `$FF00` for only some 250 T, and `BuildSpriteLists` `$D9D6` sets it as well when it rebuilds the lists (`$D9E2`,
  then `$DD66` = `$FE64` at `$D9EA`, 36 T later).
- **Title tune.** `tools/verify_tune.py` compares the piano roll's model with the player's operands frame by frame
  in the first recording, from frame 2617, over two passes of the song. Both voices' periods agree in all 2 800
  frames. The note starts agree (205 in voice A, 234 in voice B), repeated pitches included. So do the 266 drum steps with their sounds,
  and the song repeats after 2 800 frames. An earlier version of the list above said 58.5 s; the song is 56 s (doc 9.5).
- **Every resource file.** `tools/verify_res.py` finds each `INCBIN` piece in the assembled image and compares it
  with the recordings' memory. During the title (`work/c2`) 65 of 66 pieces are equal; in `udg.bin` the title's
  stack holds 6 bytes. In the bot's game (`work/p2`) the 47 pieces of graphics and course data never change. The
  rest are work areas in play, foremost the playfield buffer `$8000-$BFFF` over the title's code and data
  (src/res/README.md). The first version found each piece by its bytes, so the stale sprite copy at `$8700`
  was taken for the sprites at `$6E00` and counted as unchanged (48); the addresses now come from the
  assembler's listing (`build/game.lst`).

**Editable sources (owner's go, 2026-11-03).** The graphics and the title tune are no longer kept as the original
bytes. `tools/res_formats.py export` wrote the font, the tiles, the 14 sprite blocks and the 6 explosion frames as
22 indexed PNGs. The sprites show the four frames side by side, upright, with mask and pixels as 4 colours plus a
"no strip" colour for frame 3's missing strip. The song, its 5 patterns and 2 drum patterns became one text,
`music/title/tune.txt`, with commands (`play 5 PatternA`, `note AB $A6 $A4`, `long 3`, `steps click rest ...`)
and labels instead of addresses: the sections are laid out from `$843F`, so a pattern can grow. `build.sh` builds
them back into `build/res` and assembles from there. The tape still comes out identical to `orig/HATE.TAP`. One
changed pixel, or one changed `long`, makes it differ. `res_formats.py check` and an install-and-build of all 64
files (the 62 game files, `loading.scr` and `screen-tail.bin`) from git give the same bytes, the previews are unchanged, and `verify_res.py` and `verify_sprites.py` give
the same results through the new loader.

### 6.16 Final review, second round (2026-11-03)

The review's points that needed the code or a recording first, each checked before the docs were changed:

- **The roles of 2.5** are read from the source now: `$D3F9` is the scroll step, not the game state changes the
  first call graph suggested; it calls the round setup after a course's 32nd strip.
- **Byte +8** (doc 7) has three writers, not one: the player's at `$D246`, every record from `$C060` at each round
  setup (`SetField8` `$D2E3`), and the player's again when a follower takes its hit (`$E2A4`).
- **The pass** (4.3) runs `$CFAC`-`$D0EC`; the pause comes after the GAME OVER exit, not before. The panel's dots are
  the round's lives `$C2F9` (`$D1C2`-`$D1DC`); SCORE is 6 bytes, the last a fixed `0`.
- **The fall back** (4.4), read from the bot's recording at every frame: the vehicle hit at 10 895, gone at 10 919,
  round 3 set up again at 10 980; a life lost at 11 389-11 413, round 3 retried at 11 462; the last life lost at
  11 871-11 895, GAME OVER from 11 939 (the round number 1, SCORE 4 220). Doc 4's old rows were sample frames,
  doc 10's and this walkthrough's a few frames off; all now give these frames.
- **The pass timing** (6.1), timed again at a 1 000 t-state step: the blit writes the screen until 1003:9560 and
  `$DD6C` starts at 1003:10560, after it, as its call at `$D3F6` says (the first table had them overlap); one scroll
  step to the next is 5.2 frames, not 4.2.
- **The skew** (6.3) is one formula for all columns: byte k of column j on line 191 − k − 4 (j − 9).
- **`tools/refdocs.py`** named the game's accesses to the playfield buffer after the title player and start-up
  entries the buffer covers (`TitleSetup`, `StartupHead` ...), split at the gaps, and listed `Blit` or `DrawSprites`
  as readers of the title's tune commands. Code outside `$8000-$BFFF` now has one range there, "the playfield
  buffer", and is no user of the entries under it (docs 11 and 12 regenerated).
- **`CreditsText2`** is still taken as 12 characters on p2-rev4 (the known limit of 6.12).
- Smaller fixes: the module map's 17 nodes (`course` has no code), 2.7 shortened to the facts (the analyzer's
  history stays here), the fast tape loading of the first recording (doc 3), the font codes in hex (doc 8), the
  term "pass" at its first use (docs 1, 2), doc 5's wording, `statics` holding `DrawSprites`.

### 6.17 Final review, third round (2026-11-03)

A reviewer who had not seen the case read the documents against `build/game.lst`. Each point was checked in the code
(and the course files) before the documents changed; all 17 held, two with a different reading:

- **The lap outlives the game.** `$C2F8` is set to 0 only by the load (`$9F29`), and round 0's entry of the round
  table, which every game start copies into SCORE (`$CF36`), is never cleared (`$EEC4` clears rounds 1-10); after
  round 10 `$D18C` copies round 10's entry into it. So once a game has passed round 10, every later game starts on
  that lap with round 11's starting SCORE, the lap-2 operand patches in place. The docs had said the menu clears the
  round table.
- **HIGH after an abort** takes the SCORE of that moment: `$EEE3` first updates MAX from SCORE (`$EF17`).
- **Enemy fire** is every 8th pass of `+F` *and* bit 0 of `Random`: about once in 16 passes, not 8.
- **Dishes never fire.** The five dishes (rounds 4, 5, 6, 10) have behaviour `$00` and the lap arming touches only
  types 5-9 and the pads; the code path for a dish launch exists but never runs.
- **The speed reserve** is spent by the AUTO start (speed 0 while it lasts, `$E6DD`; AUTO lasts 14 or 70 passes),
  so the player always takes over with 0. AUTO's length is set by the vehicle (70 for the aircraft), not the course.
- **`$2C` is not the middle.** The track runs 2 to `$46` across (`$EA0C`, `$E96E`); `$2C` is the start position,
  8 left of the middle.
- **The round-start sweep wraps** (the half-period is 8 bits): three rises, a sawtooth; the bit 1 and 2 effects
  wrap once.
- **The static-object list `$C99E`** lives in a 16-byte gap of `SegmentRows`, the slots of course bytes `$5A`-`$61`,
  which no course uses (checked over the ten course files).
- Smaller: at most 4 enemy shots at once (the first-free search reached the fourth slot), the climb step
  (count + 1) / 2, plain domes in rounds 5, 7 and 9 only, round 1 or 2 *of any lap* ends the game, the shield acting
  on the mover's next pass (`$E262`), the wall crash's explosion values (`$1E`, followers `$22`), and 2.5's "one
  pass a frame" (a mistake of the second round: a pass is about 6 frames).

### 6.18 Final review, fourth round (2026-11-03)

**Asked:** do doc 3, this walkthrough and the intros of docs 11 and 12 hold against the tape, the listing and the
recording? The reviewer had not seen the earlier rounds; each finding was checked again before it was fixed.

- The tape (doc 3.1): a header is 17 bytes (+2 for flag and checksum), block 1 plays for 4.2 s; 2 613 is the game's
  entry, not play; the load at ROM speed is about 13 200 frames, not 12 000.
- The banner: `WipeCredit` prints at columns 31 down to 5 (the loop ends on `CP 4`), each time the first 32 - column
  characters; at column 5 the whole 27-character credit shows (`src/loader.asm` comment too). The depacker head is
  `$5FB4-$6017`.
- The depacker has no back-references: plain RLE, a token's value is in the stream. The real reason the builds over
  the load give no data reads is that it reads its packed input where the game's code later lies (doc 3.7,
  `tools/mkgame.py`, 6.13 here).
- Frame 2613, checked again on the first recording: the memory equals `tools/depack.py`'s image from the start of
  the frame to t 53 000 (the last writes put back bytes already there, input and output pointers meet), then the
  game writes 2, 4 and at the next frame 6 bytes.
- Counts and frames in this walkthrough: 120 `Label+offset` operands (125 before the `@isub` lines), the p2 font
  codes 64-88, 8 unknowns outside the ROM after p2-idx (seven rows), the 2 319 passes of the pass loop `$CFAC` (not
  `$CF33`), the bot game's last rounds in 6.12 and doc 10 now with doc 4's frames (lost at 10 895-10 919, retry at
  11 462, game over from 11 939), and the round blocks of rounds 3, 4 and 9 missing from L1 because the copy list
  had filled.
- Stale or unclear text: section 4's "rest of the work" (done in 6.13), section 5's five gaps, the editable formats
  (done in 6.15), the terms (L1-L3, gates, arrivals, `$W`) explained in the intro, a paragraph put back in time
  order, the docs 11 and 12 intros naming `work/` as local and the full `mkgame.py` command, the `tools/build.sh`
  fallback comment.

## 7. Closed (2026-11-03)

The owner closed the case after the fourth review round. What stands:

- `tools/build.sh` rebuilds `orig/HATE.TAP` byte for byte from `src/` (the loader, the screen stage, the 18 game
  modules from `game.ann`, the resources from their PNG and text sources).
- Docs 01-12 describe the whole image `$5FB4-$FFFF`; every byte outside the ROM has a claim in the last analysis
  build (p2-lat), and four independent reviews were checked against the code, the tape and the recordings.
- Known only from the code, not seen in a recording: rounds 5-10 and the laps after round 10, the seven hit
  handlers no recording reached (doc 12 marks them), the dishes' behaviour in the later rounds. A second capture
  that reaches them (doc 10) is the way to confirm them; nothing in the docs depends on a guess about them.
