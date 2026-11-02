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
each; the load takes 2 540 frames instead of about 12 000. The game does not depend on it (all three blocks go
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
  differ. The search found 2613 as the first frame after the depacker's last write; at 2614 the game already
  writes its stack and variables.
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
it is still unpacked from the original; replacing it with `src/game` is the rest of the work.

## 5. Tool gaps found and fixed in unreal-ng

The first L1 build over the whole recording showed three faults in the analysis. They were fixed in unreal-ng (with
fixtures and tests, branch `analysis-stages`) before going on:

| Gap | Seen as | Fix |
| --- | --- | --- |
| One build over a program that arrives in stages mixes the stages: the depacker's buffer and the game's code at the same address | the loader's bytes classified with the game's | **code arrivals**: the first run of bytes written during the recording, one per writer routine (where, when, who wrote it); **window builds** from any frame / T-state to any frame, with their own start image (`build --stage N`) |
| Every loaded byte that ran was marked self-modifying code | thousands of SMC marks on the game | SMC now means written after it ran |
| An overlay (code overwritten by a later stage) gave one finding per opcode | 174 near-duplicate findings | one finding per overwritten run (gap 32) |
| A host trap that runs as one instruction lost its writes: L1 kept 64 bus cycles per instruction, the fast tape load writes a whole block at the ROM loader's entry | the second build listed 31 arrivals: the loaded bytes had no load as their writer (the ROM's RAM test was the last one), so every return from the ROM into the banner was a new arrival, each "written `$4000-$FFFF`" | the events past 64 go to a buffer that grows once (up to 128 K); an arrival's run is the bytes its own writer wrote; one arrival per writer and run (`TrapWritesPastTheEventBuffer`, the fixture's stage 2 now calls back into the loader) |
| The L1 JSON held per-byte kinds only, no counts | no memory heatmap could be drawn from a build | `byte_counts`: reads, writes, first and last frame per byte, dense per page; `tools/heatmap.py` renders them |

Later gaps, found while writing the game's source (section 6.13):

| Gap | Seen as | Fix |
| --- | --- | --- |
| A tool edit in the recording (the fast tape load, a script's poke) writes memory past the bus: the replay applied it, L1 did not see it | the loaded block had no writer, its bytes no uses | the replay reports every byte an edit changes, in each bank it maps, as a write of the instruction pending at the edit (`ToolEditWritesAreUses`) |
| A seek shows its position's picture by replaying the frame, then puts the machine back; the engine's event cursor stayed where that replay left it | an edit right after the first keyframe (the fast tape load 55 T-states into a recording) was applied inside the seek and skipped by the replay that followed: no writes for the loaded block | two causes, both fixed: (1) the live-state snapshot now keeps the engine's event cursor and frame state too, so the replay sees the edit; (2) the edit's bytes were folded as bus cycles of the pending instruction, a `CALL` into the loader, so they counted as pushes: they are now plain data writes of that `CALL` (the trap runs the whole loader at its entry's fetch and returns, so the entry itself never starts as an instruction) (`FastTapeLoadWritesAreUses`) |
| The skool draft wrote an instruction whole when its entry ended inside it (code later overwritten by a buffer that starts at the instruction's last byte) | the rebuild gate failed at `$8082` (`JP` at `$8081` into the buffer entry at `$8083`, one byte written twice), the assemble gate shifted | the instruction's own bytes as `DEFB`, the instruction in the comment (`SkoolDraftInstructionCutByTheEntryEnd`); the bot's recording rebuilt again with it: both gates pass, 42 240 of 42 240 bytes |
| L1's self-modified mark (`kSmc`, written after it ran) could not tell an operand patch from a buffer laid over code that ran once | doc 2.7 had to sort the bot game's 123 marked bytes by their writers by hand; the code map called the title player under the playfield buffer self-modifying; L3's `code-overwritten` missed the overlay written by plain `LD (HL),r` | a byte written after it ran and never run after any such write is `overlaid` (the last field of a `byte_use` row; a byte that ran once after a write stays a patch); the code map counts only patches, L3 reports overlaid code whatever wrote it (`PatchIsNotOverlay`, `BufferOverCodeIsAnOverlayPatchIsNot`, fixture `patch-overlay.asm`); on p2: 12 patches, 111 overlaid, eight overlay findings |
| The font claim covered every code from the first glyph drawn to the last, including unused slots holding other data | three "font and text cannot both hold" conflicts at the credits (`$63DB-$63FE`), resolved by hand in 6.6 | a slot read by some code whose bytes no drawing code ever put on the screen is no glyph: the claim splits around it; a slot another routine drew stays (the score digits) (`AnalysisDetectorFonts_StringInAnUnusedSlot`, fixture `font-slot-text.asm`); on p2 the font is codes 45-58 and 64-89, conflicts 241 to 238 |
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
| An init table broke at the first byte nothing read, so a table of short entries in wider slots started late or was no table | the shadow shapes `$5B00-$5B5F`: 4 bytes a strip in 8-byte slots, the last 4 of a slot never read; L2 claimed `$5B08`, `$5B28`, `$5B48` and L3 gave three index-past-table bugs | a run goes on over up to 7 bytes the same routine wrote but nothing read when a read byte of that writer follows and the entry before the gap is 4 bytes or more and no shorter than the gap; the first version, without that condition, swallowed single variables read here and there in a copied area (`AnalysisDetectorVariables_GroupsAndStrides` failed) (`AnalysisDetectorInitTables_PaddedEntries`, fixture `init-padded.asm`, fails with the rule off; 177 analysis tests pass); on p2-all one table `$5B00-$5EEF`, the three bugs gone |
| A sprite block the recording never drew stayed unknown, though the pointer table gives its bounds and a sibling block of the same size shows its layout | `SpriteTable` `$C300` points at 20 blocks of five sizes; the recording drew none of `$6A6C` (630 bytes) and `$70FC` (420 bytes) | a fully untouched block between two targets of a pointer table copies the sprite claims of a drawn block of the same size, shifted, as inferred (`AnalysisDetectorSprites_PointerTableBlockNeverDrawn`, fixture `sprite-pointer-blocks.asm`; the test fails with the rule off); 176 analysis tests pass; on p2-all it did not fire: L2 found no pointer table of four entries at `$C300` (the words reach their use through the draw list in memory, see 6.14) |
| L1 followed a pointer's provenance through registers and the stack, not through memory: a word stored into a list and used from there was credited to the list only | `DrawSprites` copies the word at `$C300 + (+8)` into the draw list `$6500`, the drawing loop uses it from there; L2 saw only `$C31C-$C31F` in `SpriteTable`, so the pointer-block rule had no table | a byte stored from a register remembers the memory byte the register was loaded from (any other write forgets it); a word used as an address whose two bytes came that way from a word elsewhere makes that word a pointer too, the list's word stays one (`AnalysisDataFlow_PointerThroughAList`, fixture `pointer-through-list.asm`, fails with the rule off); on p2-via `$C300-$C32D` is a pointer table of 23 pointers, and the pointer-block rule fills `$6A6C-$6CE1` and `$70FC-$729F` with inferred masked sprites |
| A font claim ended at the last code a text printed | `FontHigh` `$6400-$64D7`: "Y" and "Z" (`$64C8-$64D7`) never printed, left unknown | the font goes on over up to 8 glyph slots on each side that nothing read or drew and no other claim holds, within codes 32-127 (`AnalysisDetectorFonts_StringInAnUnusedSlot` extended, fails with the rule off). On p2-via the font still ended at `$64C7`. The glyph loop at `$EE68` read `$6490-$64CF`, and L1 saw "Y" drawn 8 times, but too seldom to join the font's object; the first version only took slots nothing drew, and the first refinement (a slot read only by the glyph readers) still kept that condition, so p2-fnt changed nothing. Final rule: a slot whose bytes only the glyph readers read and no other claim holds is a glyph, drawn or not. On p2-fnt `FontHigh` is claimed to `$64D7` (codes 64-90, "Z" included), the lower half from `$6328` (code 37), and the unknown `$64C8-$64DA` is gone |
| `index-past-table` flagged the draw list `$6500` once the other walks were gone: `DrawShadows` reads the mask at `$6500` + the shadow entry's mask offset (+5, `$FE69`, `$FE71`, ...), so one index read `$6500-$6543`, around L2's pointer table `$6502-$653F` on both sides | the last index-past-table bug on p2-fnt | a reader whose every index (all accesses through one selector byte) reads on both sides of the table addresses a larger structure the table lies in, no index past it; an index running off one end still counts (`IndexAroundTableIsALargerStructure`, fixture `index-around-table.asm`, fails with the rule off; `IndexPastTableNeedsAnIndex` still passes, 183 analysis tests). On p2-ipt bugs 9 to 8, all eight the overlays of doc 2.7. L2 still calls the record-address words at +2 of the 4-byte draw-list entries a "Table of 31 pointers" with stride 2, though only every second word was used as a pointer: a known L2 limit, left as is |
| The tile set was no graphics claim: `FreshStrip` copies each tile with a chain of 8 `LDI` (`$D564`, the edge tiles `$D536`) from `$C400` + 8 x tile into a column of the playfield buffer, and the screen shows the buffer, not the tiles (the scroll rewrites the buffer's bytes, so the value flow ends there) | `$C400-$C63F` only CodeMap data, the largest RAM unknown after p2-ipt | tiles block-copied into a drawn back buffer: one copier, sources on one lattice base + L x tile (L 4..32), 4 tiles or more, never rewritten, the copied bytes shown one under another (in the buffer or in the tiles): one byte wide, L lines, from the first tile copied to the last; frames inside the set are its tiles, no sprites (`AnalysisDetectorTiles_CopiedToADrawnBuffer`, fixtures `tiles-copied.asm` (the value flow follows the copy) and `tiles-copied-shifted.asm` (a scroll ends it, as here), fails with the rule off; 184 analysis tests pass). On p2-til `$C400-$C63F` is one tile claim, 72 tiles 8 x 8 stored bottom up, as doc 11 has them (58 copied, 14 between them never copied; the edge tiles inside the set); the unknown `$C3FE-$C8E9` shrinks to the tile runs `$C640-$C8E9`; no conflicts, 8 bugs, gates pass, skool2asm warnings 660 |
| The tile runs `$C640-$C8E9` had no claim: `FreshStrip` reads a tile number (`$D55A` `LD A,(HL)`), makes it `$C400` + 8 x tile and copies the tile with `LDI`, but L1 recorded an index only for reads through a pair, not for a block copy's read through HL, so the run bytes were no index of anything | the largest RAM unknown on p2-til | L1 records the index of a block read too (`AnalysisDataFlow_IndexOfABlockRead`, fixture `tiles-copied-map.asm`, fails without it); the level map detector claims the bytes whose values picked tiles of a copied tile set, runs joined over untouched gaps holding tile numbers, as wide as the copying loop's trips when the run is a multiple of them, else one row (a pool of runs read from varying starts, as here); the same test fails with that rule off; 185 analysis tests pass). On p2-map `$C641-$C8E9` is a level map of 681 cells, one row (584 cells read, 97 untouched ones between them holding tile numbers): `TileRuns` of doc 11 (`$C640`, 682 bytes) less its first byte, which nothing read. Unknowns 28 to 27, still 8 bugs (the new block-read indexes raise no index-past-table), no conflicts, gates pass, skool2asm warnings 662 |
| The object templates had no claim: `$E1F5` copies 9 bytes from `LaunchTemplates` (`$C2B4` + 9 x kind) into a launched record, `$E891` 16 bytes from `ShotTemplate` `$C360` into a shot record; the records detector claimed the records, not the blocks they were filled from | `$C2BE-$C2E9` and part of `$C333-$C37F` unknown | record templates: one copier filling records of an array from fewer blocks than records it filled, L bytes each at one offset, the blocks on a lattice of L outside the array, are a record array of L-byte templates with the target's fields (`AnalysisDetectorRecords_Templates`, fixture `record-templates.asm`, fails with the rule off; 186 analysis tests pass). On p2-tpl `$C2BD-$C2D7` is 3 templates of 9 bytes (the kinds launched in the replay, on doc 11's lattice from `$C2B4`) and `$C360-$C36F` the shot template; the unknowns shrink to `$C2D8-$C2E9` (the fifth launch template and `EnemyShotTemplate`, copied by other code) and `$C333-$C35F`; 8 bugs, no conflicts, gates pass, skool2asm warnings 663 |
| `Directions` `$C340-$C35F` (8 x 4 bytes) had no claim: `$E2B3` reads the step along (a word) and across (a byte) at `$C340` + 4 x the record's direction (+5), the fourth byte never; the records detector's `(HL)` pattern for that routine mixes these bases with the routine's other `HL` walks (the ground profile, the records), so it found no lattice | part of `$C333-$C35F` unknown | records read through an index: bytes read through an index (L1 `indexes`) whose single reader repeats every S bytes, two readers or more a record, untouched bytes between them, 4 records or more (`AnalysisDetectorRecords_ReadThroughAnIndex`, fixture `records-indexed.asm`, where a second `HL` walk in the same routine spoils the pattern; fails with the rule off). p2-idx: `$C340-$C35F` a record array of 8 x 4, fields +0, +1, +2 read, +3 unread (evidence `indexed $E2BD`); unknowns 27 to 26, still 8 bugs, no conflicts, gates pass 42240/42240, skool2asm warnings 664 |

New fixture `testdata/analysis/fixtures/stages.asm` (a loader, a depacker with two writers, an overlay); tests
`CodeArrivalsOnePerWriter`, `WindowFromAnArrival`, `OverlayIsOneFinding`; the recipe
`.recipe/analysis/reverse-engineering.md` got "Programs that arrive in stages". All 158 analysis tests pass
(`test.sh --gtest_filter='*Analysis*'`) with the fixes, zero warnings.

## 6. The game stage (in progress)

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
- 2 319 passes of `$CF33` averaged 6.2 frames each.
- Every role the document gives a routine is marked with the document that will confirm it.

### 6.4 Pictures from the recording

- `tools/memanim.py`: a GIF of memory over a stretch of the recording. It samples TTD `memory_at` (exact at any
  T-state) every N T-states and flashes the bytes written since the previous sample. First result:
  [the loading screen unpacking](docs/img/anim-loading-screen.gif), 77 pictures, and
  [the game depacking backwards from `$FFFF`](docs/img/anim-depacker.gif), 84 pictures.
- `tools/heatmap.py`: per-byte read, write and execute heatmaps from L1's new `byte_counts` (5 in the gap table).
  Waiting for the build with the fix.
- `tools/check_docs.py`: every mermaid diagram in the docs is rendered with `mmdc`, and every link is checked. A
  diagram that GitHub's mermaid rejects fails here first.
- `tools/code_addresses.py`: on GitHub, a pair of `$` in text is LaTeX math, so `$C2B1-$F2E1` written bare rendered
  as an italic formula. Every address in prose is now a code span, and `check_docs.py` fails on any `$` left outside
  code.

The recording is open in an instance built from that branch; the whole-recording build lists the arrivals, then
each stage is built from its own arrival.

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
font became codes 45-58 (`$6368-$63D7`) and 64-89 (`$6400-$64CF`): exactly the five credit slots `;<=>?`
(`$63D8-$63FF`) fell out. The digits, drawn as rows 2-6 by `DrawDigits` (`$EEA4`, [8.2](docs/08-hud-and-text.md)) rather than by the print
loop, stay glyphs because their bytes reached the screen. The three font and text conflicts are gone (241 to 238).

### 6.7 Sound

[docs/09-sound.md](docs/09-sound.md). The title engine was read from the code with the IM 2 handler as the key. The
handler decrements C, H and L of whatever it interrupts. Those three `DEC`s only make sense if the voice loop keeps
its timers in exactly those registers, and it does: C is the note length, H and L are the voice envelopes. The
drum step is the handler's fourth decrement, `($8244)`, an operand inside the player.

For the effects in play, L1's execution counts at each `SET n,($F2BF)` site tell which sound requests happened in
the recording: shots 26, AUTO ticks 560, bit 1 13 times. Bits 0 and 2 never did, so the recording needs input
that reaches those events (the explorer, or a second capture with an input script) before doc 10 can name them.

### 6.8 The game loop and the recording's story

[docs/04-game-loop.md](docs/04-game-loop.md). The state machine was read from `$CF32-$D0EC`. Then the game's
variables were sampled with `memory_at` every 250 frames: lives `$C2F9`, round `$C2F7`, demo `$F0DB`, SCORE and
HIGH. The samples tell the recording's story without watching it: two games, each losing four lives in round 1, a
HIGH of 280, then the demo. They also confirm the retry path. The round stays 1, the lives fall 4, 3, 2, 1, and
SCORE returns to the round's starting value.

L1's counts tie the code to the run. `$D3F9` ran 1 280 times, ten round starts of 128 pre-roll steps, and never
during play. That told where the course buffer is filled before the routine was read.

The fall-back to an earlier round when the lives run out did not run: the recording never left round 1. It is
described from the code and needs a recording that gets further (planned for doc 10).


### 6.9 Memory heatmaps of the game window

[docs/02-architecture.md](docs/02-architecture.md#22-the-memory-map). The game window's build (`work/game2/l1.json`)
carries `byte_counts`, so `tools/heatmap.py` draws the 48 K as 192 rows of 256 bytes, once by count and once by the
frame each byte was last touched, with the module ranges of `tools/regions-game.txt` as labels:

```bash
python3 tools/heatmap.py work/game2/l1.json docs/img/heat-game.png --cell 2 --regions tools/regions-game.txt
python3 tools/heatmap.py work/game2/l1.json docs/img/heat-game-last.png --cell 2 --regions tools/regions-game.txt --frames
```

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
into the buffer before the blit and takes out after it (doc 06 6.6, corrected from the annotated source). The model is now
proven on four moments of the recording, and the picture in doc 06 shows the strips as stored next to the screen.

L1's counts per path made the scroll's four-pass cycle visible before the code was read: `$D51D` 903, `$D413` 900,
`$D45B` 899, `$D49C` 897 runs. One fresh strip, two shifted phases and one pass without drawing, in turn.

A correction came out of it. Doc 04 said `$D3F9` did not run during play, because L1 lists 1 280 *calls*. The
instruction count at `$D3F9` is 3 599: the blit falls through into it every pass. Routine entries count calls; the
first instruction's count is the one to read when a routine can be entered by falling into it.

The scroll animation (`docs/img/anim-scroll.gif`) is `tools/playfield_anim.py`: 81 memory images from TTD
`memory_at`, each drawn three ways: the stored strips, the same strips placed by the
Python re-run of the blit, and the real screen. The first version drew only the stored strips beside the screen,
two different projections that could not be compared by eye; the middle panel is the check that the blit was read
right. The recording is read at any frame without running
the game again; the instance only seeks.

### 6.11 Objects: types named from the screens, handlers counted by L1

[docs/07-objects.md](docs/07-objects.md). The mover `$E15C` and the hit table `$C380` were read from the code; the
names of the types were not guessed from it. `tools/objects_shot.py` reads the object list at a frame with TTD
`memory_at` and labels each live record on that frame's screen, with the isometric projection worked out for the
blit. Domes, jets, launch pads, cubes and dishes were named by looking at what sat under each label in the demo
(rounds 8 and 10) and in game 2; the gallery in doc 07 is cropped from those screens.

Then L1's per-instruction counts decided which branches of the 8 × 8 hit table the recording exercised:

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
recording. It is the first thing a second capture has to reach (doc 10).

### 6.12 A second recording, played by a bot that reads the game's own records

**Asked:** what the code says about pods, the convoy, a round's end, the next round and the fall back after the last
life (docs 04 and 07). The first recording never left round 1, and random play does not get further.

**Used:** `tools/autopilot.py`, a player that drives the emulator through the WebAPI / MCP and decides the
Kempston stick once a pass (3 frames) from memory alone:

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
  6 and 10, dishes in 4, 5, 6 and 10, plain domes (type 2) only from round 5.
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

**Dry runs so far:** round 1 cleared with pods collected (`$ECE4` 1, 2) and one hit absorbed by a follower; round
2 (the ground vehicle) cleared with 4 followers; round 3 entered with 4 lives; round 3 cleared (2 pods, one lost to a missile, the barrier passed with the other).
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
| 10 635-10 896 | round 4, 1 life, the bot gives up |
| 10 983 | fall back: round 3 again with 3 − 1 = 2 lives, SCORE back to 8 120 (MAX keeps 11 080) |
| 11 388, 11 871 | both lives lost; round 2's entry holds 1 (it was retried down to 1): GAME OVER |
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
| `game-p2-timeline.png`: round, lives, followers, hits | `tools/gamechart.py work/p2/run.log` | doc 10.1 |
| `anim-round-handover.gif`: the convoy lands beside the parked vehicle, round 2 begins | `tools/screen_anim.py --work work/p2 --from 3280 --to 3540 --step 4` | doc 10.2 |
| `heat-p2.png`, `heat-p2-last.png`: the whole game's memory | `tools/heatmap.py` | doc 10.1 |
| `heat-coverage.png`: code run in p2 against m1 | `tools/heatviews.py coverage --other work/m1/l1.json --from C000` | doc 10.1 |
| `heat-records.png`: reads and writes per field of every object record | `tools/heatviews.py records` | doc 7.2 |
| `heat-screen.png`: screen writes in the screen's geometry | `tools/heatviews.py screen` | doc 6.7 |
| `routines-time.png`: own t-states per routine | `tools/heatviews.py routines` | doc 4.5 |
| `heat-modules.png`: memory per module, screen writes per module | `tools/heatviews.py modules` | doc 2.6 |

`tools/heatmap.py` now draws the screen page (`$4000-$5AFF`) a second time below each panel, in the screen's own
geometry (bitmap bytes where they show, attributes as cells): in the 256-byte rows of the memory grid the screen's
third-interleaved lines cannot be read as a picture. The first heatmaps (doc 2) were redrawn with it.

The routine chart showed hot routines no document named (`$E56F` 656 852 entries, `$EAE3`, `$DD47`, `$DDC9`,
`$EFDC`, `$F089`): they are the insides of passes the docs describe (the hit test's pair scan, the sprite passes
saving and restoring the strips under each sprite). Doc 12 gives each one its entry.

**The scroll animation, redone.** The first `anim-scroll.gif` put the stored strips beside the screen: two different
projections, so nothing could be compared. It now has three panels: the stored strips, the same bytes placed by
the Python re-run of the blit (`tools/playfield.py`), and the screen; the middle one and the screen agree but for
the sprites and the panel.

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
   in the recordings that start after the depacker, whose back-references read its own output);
3. `src/game/game.ann`: what the reverse knows, one line an address (module, entry kind and name, the entry's
   description, comments and labels on instructions, data shapes).

It turns them into a SkoolKit control file, runs `sna2skool.py` and `skool2asm.py`, writes address operands that
point inside an entry as `Label+offset` (125), splits the listing into the modules, and installs it only when
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
(`$EF48`), the round object blocks from `$F300` running into `SpriteSaveBuffer` (`$F800`), and the UDG leftover
(`$FF58`). No detector has a kind for them; the source describes each.

**Why the sprites are no claim yet.** L1 does see them drawn: 2 869 bytes of `$6542-$7FFF` reach the screen, in 2 177
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
true layout is in doc 06 6.6: four frames a block, the last one a strip narrower. Second, the two blocks the
recording never drew, `$6A6C` and `$70FC`, and the last explosion strip `$7FD6-$7FFF`, stay unknown on p2-spr.
A generic rule now covers the two blocks: the table `$C300` bounds them, and each copies the claims of a drawn block
of the same size (`$6580` for `$6A6C`, `$6F58` for `$70FC`), marked inferred, once L2 sees `$C300` as a pointer
table; on p2-all it does not yet (see the combined run below). Third, one new
false sprite showed up: the blit once copied a buffer column whose bytes came from the strings in the font's spare
slots (`$64C8-$64FF`). That gave 3 sprite/text conflicts. A generic rule removes it: bytes a print loop reads as
character codes are no pixels.

**Why `$F301-$FBC6` and `$FBD4-$FDFC` are no claim.** The bytes are known (doc 11): the ten round object blocks
`$F300-$F7FF`, then `SpriteSaveBuffer`. Four tool gaps keep them unknown, each to be fixed generically:

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
   `$F300-$F3FF` observed (copied by `$D151`), `$F400-$F7FF` inferred from the pointer lattice.
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
   instructions or in the ROM (`AnalysisDetectorCodeMap_FillAndLeftoverCodeAreUnused`, fixture `unused-areas.asm`,
   fails with the rule off). On p2-all `$FBD4-$FC54` is "Fill, 129 bytes of `$00`" and `$FC55-$FDFC` "Code that
   never ran, 424 bytes".

**The combined run (p2-all, 2026-11-02).** All the fixes above in one build, the same recording: gates pass (42 240 of
42 240 bytes), conflicts 3 to 0, bugs 12 to 9, unknowns 34 to 32 (skool2asm warnings 632 to 653, all "No label for
address"). `$F301-$FBC6`, `$FBD4-$FDFC` and `$6542-$657F` are no longer unknown; `$EF48-$EF9E` shrinks to
`$EF5B-$EF9E`. The shadow tables are one table `$5B00-$5EEF` and their three index-past-table bugs are gone. One
unknown is new, `$64C8-$64DA`: the false sprite there is gone, and nothing else claims the bytes. They are two
things (doc 11): `$64C8-$64D7` are the glyphs of "Y" and "Z", the last two of `FontHigh`, which no string the
recording printed uses (the font claim ends at code `$58`, the last printed); `$64D8-$64DA` are the attribute, column
and row that open `CreditsText2`, whose text claim starts at the characters (`$64DB`). Two tool gaps: a font claim
stops at the last code printed even when the font's lattice runs on to the next claim, and a print string's header
bytes stay outside its text. The strings show a third. `CreditsText2` is two records,
`$B0,$01,$14,"BEN DAGLISH"` and `$B0,$01,$15,"@1989 VORTEX",$FF`, and the text detector took the second record's attribute `$B0` for a last character with bit 7
("BEN DAGLISH" claimed as 12 characters, `$64DB-$64E6`). The print path is a font read, not a glyph index, so L1 cannot
tell a printed byte from a control byte here; a rule on the record shape alone (a byte with bit 7, two bytes below
`$20`, text) would be tuned to this game, so it stays a known limit until another game shows the same format. The pointer-block rule did not fire: `$6A6C-$6CE1` and `$70FC-$729F` stay unknown. Its trigger, a
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
42 240), skool2asm warnings 658. Of the 34 unknowns of p2-spr, the 9 left outside the ROM are
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

`$7FD6-$7FFF` is a known limit of the sprite detector. The explosion frames are 168 bytes each from `$7C10`
(doc 11): 4 strips of 21 lines, a mask and a pixel byte a line, 42 bytes a strip. The detector joins the strips it
saw drawn side by side, and clipping at the window's edges showed them in varying groups. So its claims (`$7DDE-$7E31`
8 x 21 x 2, `$7E32-$7E85` 16 x 21, ...) are runs of whole strips that do not start on the frames' 168-byte lattice.
The last strip of the last frame was never joined to a claim. The frame boundaries come from the sprite table at
`$C300` (doc 6.6); no rule ties drawn strips to a pointer table's blocks yet.
