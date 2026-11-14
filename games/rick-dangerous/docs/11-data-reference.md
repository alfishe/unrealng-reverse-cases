# 11. Data reference

Every data entry of the game image `$5B00`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage2/c1g`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: The BASIC "Rick", Rick1, the first loader stage, The second loader
stage, LoadGroup, the loader of groups 2 and 3, The AY player and tunes (RAM 1)) follow the game, each under its own
heading with its modules, its source, its annotations and its recordings.

## loader

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B00` | `RomPagingRoutines` | 88 | The 128K ROM's paging routines, copied here by its reset (SWAP, YOUNGER, ONERROR, PIN, POUT, POUT2). Known only from the 128K ROM: the load runs on the 128K editor, whose reset copies them. No code of the game calls them. | `ComposeObject` | `Start` |
| `$5B58` | `Rom128Variables` | 168 | The 128K ROM's system variables (TARGET, RETADDR, BANK_M `$5B5C`, ...) and its stack TSTACK up to `$5BFF`. Known only from the 128K ROM. | `ComposeObject` | `Start` |
| `$5C00` | `SystemVariables` | 182 | The 48K system variables as the loader leaves them (DF_SZ 2, NMIADD 0, RAMTOP `$C350`, ...). The game rebuilds `$5C00-$5CFF` as its char property table before it uses it (BuildCharProps `$F6A9`). | `ComposeCell`, `IsSolidAt`, `ProbeBoxAligned`, `ProbeBoxUnaligned`, `ProbeLow` +1 | `BuildCharProps` |
| `$5CB6` | `ChannelInfo` | 21 | The channel information: K, S, R and P, then the `$80` end mark | `ComposeCell`, `ProbeBoxAligned`, `ProbeBoxUnaligned` | `BuildCharProps` |
| `$5CCB` | `BasicLeft` | 53 | The first 53 bytes of the BASIC "Rick" (src/tape/basic.asm): lines 10, 20 and the start of 30; the second stage overwrote the rest | `ComposeCell`, `ProbeBoxAligned`, `ProbeBoxUnaligned`, `ProbeLow`, `IsSolidAt` (`stage1/level1`) +1 | `BuildCharProps` |
| `$5D00` | `LoaderStage2` | 231 | The second loader stage, deciphered (src/loader/stage2.asm): the build's stage2.bin | `ComposeCell`, `ComposeObject`, `DrawAllDirtyCells`, `DrawDirtyCells` | `ComposeCell`, `ComposeObject` |
| `$5DE7` | `LoaderStack` | 25 | The loader's stack at the game's entry: 24 bytes under `$5DFF` (zeros on the tape). What the second stage's calls (LoadGroup, the ROM's KEY-SCAN) left on its stack (SP = `$5DFF` from `$5D51`); nothing reads them. | `ComposeCell`, `ComposeObject`, `DrawAllDirtyCells`, `DrawDirtyCells` | `ComposeCell`, `ComposeObject` |
| `$5E00` | `MusicImage` | 3492 | The AY player and its tunes, `$0DA4` bytes, as the entry copies them to RAM 1 `$C000` (src/music/music.asm) | `ComposeCell`, `ComposeObject`, `DetectPaging`, `DrawAllDirtyCells`, `DrawCounter` +10 | `BuildScreenMap`, `ComposeCell`, `ComposeObject`, `ShiftMapUp`, `Start` +4 |
| `$6BA4` | `Kind16Frame` | 126 | A sprite frame (24 x 21, 126 bytes): kind 16's graphic, which Start `$AB4D` copies to `$6A80`. Start (`$AB62`) LDIRs it to `$6A80`, the frame ObjectKinds gives kind 16, past the map's rows: the music's bytes at `$5E00-$6BA3` and these become work space (the char map from `$6500`, the cell flags from `$6C00`) once RAM 1 has the player. Read once, by that copy (c1). | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `RedrawScreen`, `ShiftMapUp` +4 | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `MaskHudCells`, `RedrawScreen` +4 |
| `$6C22` | `Kind19Frame` | 126 | A sprite frame: kind 19's graphic, which Start `$AB4D` copies to `$7080`. The second LDIR of Start, to GraphicSlot19 `$7080`. | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `RedrawScreen`, `ShiftMapUp` +4 | `ComposeCell`, `DrawAllDirtyCells`, `DrawCounter`, `DrawDirtyCells`, `MaskHudCells` +5 |
| `$6CA0` | `LowZeros` | 352 | Zeros up to the graphics: part of the cell flags (`$6B00-$707F`) as the load leaves them. The game writes the cell flags before it reads them (MarkAllDirty `$A239`). | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `ShiftMapUp`, `ShiftMarksUp` +2 | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `ShiftMapUp`, `ShiftMarksUp` +2 |

## screenwork

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6E00` | `CellFlagsRow16` | 256 | The cell flags of rows 16-23 of the map window (`$6C00` + 32 x row + column), 0 as loaded. Written 1 by the scrolls' compares (`$AE25`, `$AE76`, `$AE9A`) and the fills `$A239` / `$AF18`, read and cleared by the redraw `$A834` / `$A25D` and `$A6D0`. Read and written in every recording. | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `ShiftMapUp`, `ShiftMarksUp` +2 | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `ShiftMapUp`, `ShiftMarksUp` +2 |
| `$6F00` | `CellFlagsRow24` | 256 | The cell flags of rows 24-31 (below the screen); `$6F00` is also the redraw's end mark. The redraws `$A25D` and `$A834` put `$FF` at `$6F00` (CellFlagsRow24's first byte) to stop their scan after row 23; `$A781` saves the byte into its own code (`$A80F`) and puts it back after its copy. `$AF18` fills the 256 bytes with 1 (SP `$7000`, 8 x 16 PUSH). `$AE76` scans the whole map window up to its end mark at CellFlagsEnd. | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `RedrawScreen`, `ShiftMapUp` +1 | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `RedrawScreen`, `ShiftMapUp` +2 |
| `$7000` | `CellFlagsEnd` | 1 | The end mark of the 32-row scan: `$AE76` writes `$FF` here | `ShiftMarksUp` | `ShiftMarksUp` |
| `$7001` | `Unused7001` | 127 | 127 bytes no routine reads in play (0 as loaded). Known only from the code: no instruction names an address in it, and the recordings read and write it only while the tape loads (`c1`). | - | - |
| `$7080` | `GraphicSlot19` | 126 | A 126-byte sprite frame filled at the entry: kind 19's graphic (ObjectKinds `$D3B6`). The entry `$AB4D` copies 126 bytes from `$6C22` here (`$AB62`, after the 126 from `$6BA4` to `$6A80`, kind 16's graphic): the two graphics kept past the music's bytes, which the game reuses as work space. The format is SpriteFrames'. No recording drew kind 19. | - | `Start` |
| `$70FE` | `Unused70FE` | 2 | 2 bytes, not read in play | - | - |

## charsets

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7100` | `CharSet0` | 2048 | Char set 0 (levels 1-2): 256 chars of 8 lines. Read by the redraws `$A834`, `$A25D` and `$A6D0` (the char cells under the sprites). | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells`, `Im2Handler` (`stage1/level2`) | - |
| `$7900` | `CharAttr0` | 256 | The attributes of char set 0; char 0's (`$7900`) is the screen's empty colour, set by the level. `$E320` (LevelIntro) and `$AC14` write `$7900`: the colour of char 0 (empty space) follows the level record's attribute; `$ABD8` and `$E267` write it too. Read by `$AA0E` (the HUD) and the redraw through the page patched into `$A853`. | `DrawAllDirtyCells`, `DrawCounter` | `Menu`, `LevelEnd` (code), `LevelIntro` (code) |
| `$7A00` | `CharSet1` | 2048 | Char set 1 (levels 3-4): 256 chars of 8 lines | `ComposeCell` (`stage1/level3`), `DrawAllDirtyCells` (`stage1/level3`), `DrawDirtyCells` (`stage1/level3`), `Im2Handler` (`stage1/level3`) | - |
| `$8200` | `CharAttr1` | 256 | The attributes of char set 1 | `DrawAllDirtyCells` (`stage1/level3`), `DrawCounter` (`stage1/level3`) | - |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8300` | `Im2Table` | 257 | The IM 2 vector table: 257 bytes `$FE` written at the entry (`$A215`, I = `$83`), 0 as loaded. `$A215` fills `$8300-$8400` with `$FE` and sets I = `$83`, so any data bus value gives the vector `$FEFE`, the handler. With the Spectrum's idle bus (`$FF`) every interrupt reads `$83FF` and `$8400` (every routine of the recordings shows that read: the interrupt's acceptance booked to the interrupted instruction). | `Im2Handler` | `SetUpInterrupts` |
| `$A237` | `FrameTicks` | 2 | The frame count: +1 each interrupt (`$FF07-$FF0B`), cleared by WaitFrames and the frame loop (`$E411`). Only the first byte is used. | `Im2Handler`, `WaitFrames` | `Im2Handler`, `Menu`, `WaitFrames`, `StartLevel` (`stage1/level2`), `MainLoopHalt` (code) |
| `$FF1E` | `BasicStackResidue` | 58 | Residue of a 48K BASIC session the tape carries: never read. Bytes the tape's last group holds, read by no code: the leftovers of the developers' BASIC memory. The ROM's machine stack (return addresses such as `$1B76` and `$1303` at `$FF52`) and, at `$FF57`, RAMTOP's GO SUB stack marker `$3E`. | - | - |
| `$FF58` | `UdgResidue` | 150 | The BASIC UDGs A-U as the ROM sets them up: never read. 21 letters, 8 bytes each, as the ROM copies them to UDG `$FF58`; the game stack takes the last 18 bytes. | - | - |
| `$FFEE` | `GameStack` | 18 | The game's stack: SP = 0 (`$A258`), it grows down from `$FFFF`. The image holds the UDG bytes here; at run time the stack's words. Where the stack really ends is known only from the code: this entry takes 18 bytes, the last two and a half UDG letters. | - | `Im2Handler` |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8401` | `SpriteFrames` | 126 of 6804 | 54 frames x 21 rows x 6 bytes (OR3, OR2, OR1, AND1, AND3, AND2) | - | - |
| `$847F` | `RickWalk1` (`SpriteFrames`+126) | 126 | frame 1: walk steps 1 and 3 | - | - |
| `$84FD` | `RickWalk2` (`SpriteFrames`+252) | 126 | frame 2: walk step 2, and Rick in the air (jumping, falling: `$FD18`) | - | - |
| `$857B` | `RickDying` (`SpriteFrames`+378) | 126 | frame 3: Rick dying, the mirror flipped every 4 frames (`$FC81`) | - | - |
| `$85F9` | `Frame4` (`SpriteFrames`+504) | 126 | frame 4: a small shot, the bullet (the picture); kind 57's animation (mirrored) | - | - |
| `$8677` | `RickCrawl1` (`SpriteFrames`+630) | 126 | frame 5: crawl steps 2-3 (CrawlFrames `$FD75`) | - | - |
| `$86F5` | `RickCrawl0` (`SpriteFrames`+756) | 126 | frame 6: crawl steps 0-1 | - | - |
| `$8773` | `RickFiring` (`SpriteFrames`+882) | 126 | frame 7: firing the pistol (`$FD29`) | - | - |
| `$87F1` | `RickPoking` (`SpriteFrames`+1008) | 126 | frame 8: poking with the stick (`$FC95`) | - | - |
| `$886F` | `RickClimbing` (`SpriteFrames`+1134) | 126 | frame 9: on a ladder, the mirror wiggling (`$FCE0`) | - | - |
| `$88ED` | `DynamiteFuse` (`SpriteFrames`+1260) | 126 | frame 10: the burning stick of dynamite (FuseFrames `$ECF2`) | - | - |
| `$896B` | `BulletsPickup` (`SpriteFrames`+1386) | 126 | frame 11: kind 17's graphic, the bullets to pick up | - | - |
| `$89E9` | `Blast0` (`SpriteFrames`+1512) | 126 | frame 12: the blast, small (BlastFrames `$ECF6`); kinds 29, 30, 54, 55, 67, 68 | - | - |
| `$8A67` | `Blast1` (`SpriteFrames`+1638) | 126 | frame 13: the blast, large; kinds 54, 55, 67, 68 | - | - |
| `$8AE5` | `Blast2` (`SpriteFrames`+1764) | 126 | frame 14: the blast, largest; kinds 54, 55, 67, 68 | - | - |
| `$8B63` | `Frame15` (`SpriteFrames`+1890) | 126 | frame 15: kind 20's graphic | - | - |
| `$8BE1` | `Frame16` (`SpriteFrames`+2016) | 126 | frame 16: kind 18's graphic, kind 47's animation | - | - |
| `$8C5F` | `Frame17` (`SpriteFrames`+2142) | 126 | frame 17: kind 21's graphic, kind 65's animation | - | - |
| `$8CDD` | `Frame18` (`SpriteFrames`+2268) | 126 | frame 18: kinds 7-9's graphic | - | - |
| `$8D5B` | `Frame19` (`SpriteFrames`+2394) | 126 | frame 19: kinds 7-9 falling (graphic + 126) | - | - |
| `$8DD9` | `Frame20` (`SpriteFrames`+2520) | 126 | frame 20 | - | - |
| `$8E57` | `Frame21` (`SpriteFrames`+2646) | 126 | frame 21 | - | - |
| `$8ED5` | `Frame22` (`SpriteFrames`+2772) | 126 | frame 22 | - | - |
| `$8F53` | `Frame23` (`SpriteFrames`+2898) | 126 | frame 23: kinds 4-6's graphic | - | - |
| `$8FD1` | `Frame24` (`SpriteFrames`+3024) | 126 | frame 24: kinds 4-6 falling | - | - |
| `$904F` | `Frame25` (`SpriteFrames`+3150) | 126 | frame 25 | - | - |
| `$90CD` | `Frame26` (`SpriteFrames`+3276) | 126 | frame 26 | - | - |
| `$914B` | `Frame27` (`SpriteFrames`+3402) | 126 | frame 27: kinds 10-15's graphic | - | - |
| `$91C9` | `Frame28` (`SpriteFrames`+3528) | 126 | frame 28: kinds 10-15 falling | - | - |
| `$9247` | `Frame29` (`SpriteFrames`+3654) | 126 | frame 29: kind 56's animation (mirrored) | - | - |
| `$92C5` | `Frame30` (`SpriteFrames`+3780) | 126 | frame 30 | - | - |
| `$9343` | `Frame31` (`SpriteFrames`+3906) | 126 | frame 31 | - | - |
| `$93C1` | `Frame32` (`SpriteFrames`+4032) | 126 | frame 32: a stone block (the picture); kinds 24, 28, 31, 33, 35, 36, 38 | - | - |
| `$943F` | `Frame33` (`SpriteFrames`+4158) | 126 | frame 33: kinds 25-27 | - | - |
| `$94BD` | `Frame34` (`SpriteFrames`+4284) | 126 | frame 34: kind 32 | - | - |
| `$953B` | `Frame35` (`SpriteFrames`+4410) | 126 | frame 35: a jar (the picture); kind 34 | - | - |
| `$95B9` | `Frame36` (`SpriteFrames`+4536) | 126 | frame 36: a row of spikes (the picture); kinds 37, 39 | - | - |
| `$9637` | `Frame37` (`SpriteFrames`+4662) | 126 | frame 37: kinds 40, 41 | - | - |
| `$96B5` | `Frame38` (`SpriteFrames`+4788) | 126 | frame 38: kinds 40, 41 | - | - |
| `$9733` | `Frame39` (`SpriteFrames`+4914) | 126 | frame 39: a boulder (the picture); kind 42 | - | - |
| `$97B1` | `Frame40` (`SpriteFrames`+5040) | 126 | frame 40: a bat (the picture); kind 43's animation with frame 41 | - | - |
| `$982F` | `Frame41` (`SpriteFrames`+5166) | 126 | frame 41: the bat, wings spread; kind 43 | - | - |
| `$98AD` | `Frame42` (`SpriteFrames`+5292) | 126 | frame 42: kinds 44, 48 | - | - |
| `$992B` | `Frame43` (`SpriteFrames`+5418) | 126 | frame 43: kinds 45, 49, 52 | - | - |
| `$99A9` | `Frame44` (`SpriteFrames`+5544) | 126 | frame 44: kind 46 | - | - |
| `$9A27` | `Frame45` (`SpriteFrames`+5670) | 126 | frame 45: kinds 50, 51, 61 | - | - |
| `$9AA5` | `Frame46` (`SpriteFrames`+5796) | 126 | frame 46: kinds 59, 64 | - | - |
| `$9B23` | `Frame47` (`SpriteFrames`+5922) | 126 | frame 47: kinds 53, 62, 66 | - | - |
| `$9BA1` | `Frame48` (`SpriteFrames`+6048) | 126 | frame 48: kinds 53, 62, 66 | - | - |
| `$9C1F` | `Frame49` (`SpriteFrames`+6174) | 126 | frame 49: kinds 54, 55 | - | - |
| `$9C9D` | `Frame50` (`SpriteFrames`+6300) | 126 | frame 50: kinds 58, 70 | - | - |
| `$9D1B` | `Frame51` (`SpriteFrames`+6426) | 126 | frame 51: kinds 59, 63, 64 | - | - |
| `$9D99` | `Frame52` (`SpriteFrames`+6552) | 126 | frame 52: kinds 59, 63, 64 | - | - |
| `$9E17` | `Frame53` (`SpriteFrames`+6678) | 126 | frame 53: kinds 60, 69 | - | - |

## font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9E95` | `Font` | 80 of 344 | 43 glyphs: 0-9, A-Z, three pictures, comma, full stop, question mark, space. Glyph G at `$9E95` + 8G, top line first. The printers: `$A977` (the score and counters, digits 0-9 as numbers), `$A9E8`, `$AA0E` / `$AA25` (codes as glyph numbers) and `$AA8D` / `$AA9F` (ASCII: code - `$37`, so "A" = 10). The editable form is src/res/graphics/font.png. | `DrawCounter`, `DrawScore`, `PrintText` | - |
| `$9EE5` | `FontLetters` (`Font`+80) | 208 | glyphs 10-35: A-Z | `PrintText` | - |
| `$9FB5` | `FontIcons` (`Font`+288) | 24 | glyphs 36-38: pictures (a stick of dynamite, bullets, a face: the HUD's counters) | `DrawCounter` | - |
| `$9FCD` | `FontPunctuation` (`Font`+312) | 32 | glyphs 39-42: comma, full stop, question mark, space | `PrintText` | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A08D` | `Is48K` | 1 | 0 on a 128K, `$FF` on a 48K (DetectPaging `$A05F`). Read by PlayEffect and StartTune. 0 in the image and in the 128K recordings; `$FF` in beeper48 (the 48K). | `PlayEffect`, `StartTune` | `Set48K` (code) |

## controls

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A14C` | `ControlMethod` | 1 | The control method: 0 keyboard, 1 Kempston, 2 cursor keys, 3 Sinclair. Set by the title's keys 1-4 (`$E27F`, `$E297`, `$E2AF`, `$E2C7`), read by ReadInput and by the title to pick the line to highlight (`$E249`). 0 in the image. | `Menu`, `ReadInput` | `Menu` |
| `$A14D` | `InputBits` | 1 | The controls, active low: bit 0 right, 1 left, 2 down, 3 up, 4 fire. Written by ReadInput (`$FF`, then a RES for each thing held), read by StartFireTest and by Rick's code (`$F8DC`, `$F9A4`, `$F9C4`, `$FBC2`). | `ClimbRick`, `LandRick`, `ReadInput`, `StartPressed`, `WalkRick` +4 | `ReadInput`, `InputKempston` (`stage1/level1`) |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A73C` | `ComposeCount` | 1 | The next composed char's number (2 at each pass's start). Set to 2 by ComposeObjects, counted up by ComposeCell. The flags 0 and 1 mean the map, so the numbers start at 2 (`$5D00`). | `ComposeCell` | `ComposeCell`, `ComposeObjects` |
| `$A73D` | `CharsetBase` | 2 | The charset of the screen: `$7100`, or `$7A00` when the screen record's +0 is not 0 (LoadScreen `$ACAD`). Read by DrawDirtyCells, ComposeCell and DrawAllDirtyCells: char c's 8 bytes at CharsetBase + 8c. | `ComposeCell`, `DrawAllDirtyCells`, `DrawDirtyCells` | `LoadScreen` |
| `$A814` | `SavedHudCells` | 32 | The 32 flags of the HUD row `$6C21-$6C40` while RedrawScreen runs | `RedrawScreen` | `RedrawScreen` |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A93A` | `OldHudCounts` | 1 of 3 | The counters as last drawn: bullets, dynamite, lives | `UpdateHud` | `UpdateHud` |
| `$A93B` | `OldDynamite` (`OldHudCounts`+1) | 1 | - | `UpdateHud` | `UpdateHud` |
| `$A93C` | `OldLives` (`OldHudCounts`+2) | 1 | - | `UpdateHud` | `UpdateHud` |
| `$A958` | `Lives` | 1 | The lives: 6 at a new game, 0 is the game over (`$E354`) | `DrawLives`, `MaskHudCells`, `Menu`, `UpdateHud`, `StartLevel` (`stage1/level2`) +2 | `Menu`, `StartLevel` (`stage1/level2`), `CheckDeath` (code), `ClearDoneLoop` (code) |
| `$A967` | `Dynamite` | 1 | The sticks of dynamite: 6 at a new game, a life and a level; the dynamite drop uses them (`$FAA1`, `$FAA7`) | `DrawDynamite`, `MaskHudCells`, `UpdateHud`, `MoveRick` (`stage1/level2`), `DropDynamite` (code) | `Menu`, `MoveRick` (`stage1/level2`), `StartLevel` (`stage1/level2`), `BoxGiveDynamite` (code), `ClearDoneLoop` (code) +3 |
| `$A976` | `Bullets` | 1 | The bullets: 6 at a new game, a life and a level; Rick's fire uses them (`$FA3E`, `$FA4C`) | `DrawBullets`, `FireNoStick`, `MaskHudCells`, `UpdateHud`, `MoveRick` (`stage1/level1`) +1 | `FireNoStick`, `Menu`, `MoveRick` (`stage1/level1`), `StartLevel` (`stage1/level2`), `BoxActive` (code) +4 |
| `$A9BE` | `Score` | 6 | The score: six decimal digits, one byte each, the highest first. Cleared by a new game (`$E2FC-$E305`), added to by AddScore. The image holds the digits 0 9 3 0 0 0. | `AddScore`, `DrawScore` | `AddScore`, `Menu`, `ClearDoneLoop` (code) |
| `$A9C4` | `ScorePad` | 1 | `$FF`, not read: the byte after the units | - | - |
| `$A9C5` | `Award1` | 5 | Five digits, 00001: no reader found | - | - |
| `$A9CA` | `Award10` | 5 | 00010: no reader found | - | - |
| `$A9CF` | `Award50` | 5 | 00050: AddScore from `$F18D` | `AddScore` | - |
| `$A9D4` | `Award100` | 5 | 00100: no reader found | - | - |
| `$A9D9` | `Award500` | 5 | 00500: AddScore from `$EDF3` | `AddScore` | - |
| `$A9DE` | `Award1000` | 5 | 01000: no reader found | - | - |
| `$A9E3` | `LevelBonus` | 5 | (Lives + 1) 0 0 0 0: written by the end of the last level (`$AC2F`) | - | `LevelEnd` (code) |
| `$AAE1` | `SpaceGlyph` | 8 | The blank char PrintText prints for a space | `PrintText` | - |
| `$AB3C` | `CyclePhase` | 1 | CycleAttributes' phase, 0-7 | `CycleAttributes` | `CycleAttributes` |
| `$AB3D` | `CycleColours` | 8 | The highlight: bright white ink on paper 1, 2, 3, 4 (`$4F` `$4F` `$57` `$57` `$5F` `$5F` `$67` `$67`) | `CycleAttributes` | - |
| `$AB45` | `PlainColours` | 8 | Plain bright white on black (`$47`) | `CycleAttributes` | - |
| `$E495` | `BonusDivider` | 1 of 6 | passes to the next step (`$1E` reload; `$32` in the image), then the five digits. Written by BonusCountdown `$E466` (BonusDivider and the digits) and by the start marker `$F4C8` (`$F4EE`-`$F4F9`: the digits); read by the end marker `$F502` (`$F529`: DE = BonusDigits+4). | `AddScore`, `BonusCountdown` | `BonusCountdown`, `BonusTrigger` |
| `$E496` | `BonusDigits` (`BonusDivider`+1) | 5 | five decimal digits, most significant first | `AddScore`, `BonusCountdown` | `BonusCountdown`, `BonusTrigger` |

## levels

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AD20` | `RestartPoint` | 1 of 9 | The state at the current screen's entry: `$FD5A`, x, y (word), +6, the top row (word), the screen record (word) | `RestartScreen` | `LoadScreen`, `SaveRestartPoint` |
| `$AD21` | `RestartX` (`RestartPoint`+1) | 1 | - | `RestartScreen` | `SaveRestartPoint` |
| `$AD22` | `RestartY` (`RestartPoint`+2) | 2 | - | `RestartScreen` | `SaveRestartPoint` |
| `$AD24` | `RestartFlags` (`RestartPoint`+4) | 1 | - | `RestartScreen` | `SaveRestartPoint` |
| `$AD25` | `RestartTopRow` (`RestartPoint`+5) | 2 | - | `RestartScreen` | `SaveRestartPoint` |
| `$AD27` | `RestartScreenRecord` (`RestartPoint`+7) | 2 | - | `RestartScreen` | `LoadScreen` |
| `$ADB5` | `MapBlockTable` | 2 | The current screen's map: the block numbers, 8 a row | `BuildScreenMap` | `LoadScreen` |
| `$ADB7` | `ViewTopRow` | 2 | The map row at the view's top (read as a byte too) | `BuildScreenMap`, `CheckScreenExit`, `ExitScan`, `LoadScreen`, `SaveRestartPoint` +3 | `LoadScreen`, `ScrollViewDown`, `ScrollViewUp` (`stage1/level2`) |
| `$E4AE` | `LevelTable` | 2 of 55 | 11 bytes a level: 0 jungle, 1 Egypt, 2 castle, 3 missile base, 4 the ending. +0-1 the intro text, +2-3 its screen address, +4 the attribute stored in `$7900`, +5 Rick's x (RickX `$EAAD`), +6-7 Rick's y (RickY `$EAAE`), +8-9 the first zone record (to IX), +10 the count passed in C to `$AC83`. Record 0 is read by NewGame `$E2DC` and StartLevel `$E32C`; at a level change `$AC07` reads record Level `$E4AD` (`$AC56`). The ending's record has only the text and the attribute in use. The warp recordings copy record N over record 0 (WALKTHROUGH 6.0). | `Menu`, `StartLevel` (`stage1/level2`), `LevelIntro` (code) | - |
| `$E4B0` | `LevelTextAt` (`LevelTable`+2) | 2 | - | `Menu`, `LevelIntro` (code) | - |
| `$E4B2` | `LevelAttr` (`LevelTable`+4) | 1 | - | `Menu`, `LevelIntro` (code) | - |
| `$E4B3` | `LevelRickX` (`LevelTable`+5) | 1 | - | `Menu`, `StartLevel` (`stage1/level2`) | - |
| `$E4B4` | `LevelRickY` (`LevelTable`+6) | 2 | - | `Menu`, `StartLevel` (`stage1/level2`) | - |
| `$E4B6` | `LevelZone` (`LevelTable`+8) | 2 | - | `Menu`, `StartLevel` (`stage1/level2`) | - |
| `$E4B8` | `LevelZoneCount` (`LevelTable`+10) | 45 | - | `Menu`, `StartLevel` (`stage1/level2`) | - |
| `$FEE8` | `FreeFEE8` | 22 | 22 zero bytes, never used | - | - |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$EA8E` | `ObjectTable` | 30 of 361 | 12 object slots of 30 bytes, all 0 at the load. The record format is in the module header. In play (work/images/play.*.bin) slot 1 is `01 8E A5 00 FD 84 01 18 15`: Rick, x `$8E`, y `$00A5`, frame `$84FD`, width `$18`, height `$15`. | `BonusCollect`, `BonusTrigger`, `BulletObj`, `CheckScreenExit`, `ChooseRickFrame` +48 | `BonusCollect`, `BonusTrigger`, `BulletObj`, `ChooseRickFrame`, `ClimbRick` +33 |
| `$EAAC` | `RickObject` (`ObjectTable`+30) | 1 | slot 1: Rick | `ComposeObjects`, `ObjectsOverlap`, `ResetObjects`, `ShiftObjects`, `UpdateObjectSlot` +2 | `DeathFall`, `Menu`, `ResetObjects`, `ShiftObjects` (`stage1/level2`), `StartLevel` (`stage1/level2`) +1 |
| `$EAAD` | `RickX` (`ObjectTable`+31) | 1 | - | `BonusCollect`, `BonusTrigger`, `ChooseRickFrame`, `ClimbRick`, `ComposeObject` +20 | `ClimbRick`, `DeathFall`, `ExitLeft`, `ExitRight`, `Menu` +8 |
| `$EAAE` | `RickY` (`ObjectTable`+32) | 4 | 16-bit | `BonusCollect`, `BonusTrigger`, `CheckScreenExit`, `ChooseRickFrame`, `ClimbRick` +21 | `ChooseRickFrame`, `ClimbRick`, `DeathFall`, `LandRick`, `Menu` +6 |
| `$EAB2` | `RickMirror` (`ObjectTable`+36) | 1 | +6 | `ChooseRickFrame`, `ComposeObject`, `ComposeObjects`, `ResetObjects`, `SaveRestartPoint` +2 | `ChooseRickFrame`, `ResetObjects`, `RestartScreen`, `ShiftObjects` (`stage1/level2`) |
| `$EAB3` | `RickWidth` (`ObjectTable`+37) | 1 | - | `ComposeObjects`, `ResetObjects`, `ShiftObjects`, `UpdateObjectSlot`, `ComposeObject` (`stage1/level2`) +1 | `Menu`, `ResetObjects`, `ShiftObjects` (`stage1/level2`), `StartLevel` (`stage1/level2`) |
| `$EAB4` | `RickHeight` (`ObjectTable`+38) | 22 | - | `ComposeObjects`, `ResetObjects`, `ShiftObjects`, `UpdateObjectSlot`, `ComposeObject` (`stage1/level2`) | `Menu`, `ResetObjects`, `ShiftObjects`, `StartLevel` (`stage1/level2`) |
| `$EACA` | `BulletObject` (`ObjectTable`+60) | 1 | slot 2: Rick's bullet | `ClimberObj`, `ComposeObjects`, `EnemyCommon`, `FireNoStick`, `ResetObjects` +8 | `EnemyCommon`, `FireNoStick`, `ResetObjects`, `BulletObj` (`stage1/level1`), `MoveRick` (`stage1/level1`) +4 |
| `$EACB` | `BulletX` (`ObjectTable`+61) | 1 | - | `BulletObj`, `ComposeObject`, `ComposeObjects`, `EnemyCommon`, `ResetObjects` +4 | `BulletObj`, `FireNoStick`, `ResetObjects`, `MoveRick` (`stage1/level1`), `FireShoot` (code) |
| `$EACC` | `BulletY` (`ObjectTable`+62) | 28 | - | `BulletObj`, `ComposeObject`, `ComposeObjects`, `EnemyCommon`, `ResetObjects` +4 | `FireNoStick`, `ResetObjects`, `MoveRick` (`stage1/level1`), `FireShoot` (code), `ShootLeft` (code) +1 |
| `$EAE8` | `DynamiteObject` (`ObjectTable`+90) | 1 | slot 3: Rick's dynamite | `ComposeObjects`, `ResetObjects`, `ShiftObjects`, `UpdateObjectSlot`, `MoveRick` (`stage1/level2`) +1 | `ResetObjects`, `DynamiteObj` (`stage1/level2`), `MoveRick` (`stage1/level2`), `DropDynamite` (code) |
| `$EAE9` | `DynamiteX` (`ObjectTable`+91) | 29 | - | `ComposeObjects`, `ResetObjects`, `ShiftObjects`, `UpdateObjectSlot`, `ComposeObject` (`stage1/level2`) +2 | `ResetObjects`, `DynamiteObj` (`stage1/level2`), `MoveRick` (`stage1/level2`), `DropDynamite` (code) |
| `$EB06` | `ZoneObjects` (`ObjectTable`+120) | 240 | slots 4-11: the zone's objects | `ClimberFall`, `ClimberMove`, `ComposeObject`, `ComposeObjects`, `DyingEnemyObj` +19 | `BonusCollect`, `BonusTrigger`, `ClimberFall`, `DyingEnemyObj`, `EnemyFall` +9 |
| `$EBF6` | `ObjectTableEnd` (`ObjectTable`+360) | 1 | `$FF` | `ComposeObjects`, `ResetObjects`, `ShiftObjects`, `UpdateObjectSlot` | - |
| `$EC47` | `ObjectHandlers` | 48 | Handler of each kind 0-23. Indexed by UpdateObjectSlot `$EC15` with type AND `$7F` below `$18`. | `UpdateObjectSlot` | - |
| `$F173` | `TracksRick` | 1 | `$FF`: the enemy turns towards Rick (TrackerObj `$EFD6`); 0: it patrols (PatrolObj `$EFCF`) | `EnemyFall` | `PatrolObj`, `TrackerObj` |
| `$F174` | `EnemyWalkFrames` | 8 | walk frames, offsets from the frame base, by x bits 2-3 | `ClimberFall`, `EnemyFall`, `ClimberMove` (`stage1/level4`) | - |
| `$F689` | `ProbeRecord` | 30 of 32 | The probe's box as an object record (IY) for ObjectsOverlap. ProbeBoxObject0 `$F624` writes +1 (X) and +2/+3 (Y) and hands it to ObjectsOverlap `$F6E9` as IY; the other fields are never read (0 in the image). | `ClimbRick`, `ClimberFall`, `EnemyFall`, `MoveRick`, `WalkRick` +4 | `ProbeBox`, `ProbeBoxAligned`, `ProbeBoxUnaligned`, `ProbeLow`, `ProbeBoxObject0` (`stage1/level2`) |
| `$F6A7` | `ProbeLowResult` (`ProbeRecord`+30) | 1 | ProbeLow's top row (AND `$F0`); MoveRick reads it while crawling | `MoveRick` | `ProbeLow` |
| `$F6A8` | `ProbeResult` (`ProbeRecord`+31) | 1 | the OR of the properties under the box (+ bit 6 for object 0) | `ClimbRick`, `ClimberFall`, `EnemyFall`, `MoveRick`, `WalkRick` +3 | `ProbeBox`, `ProbeBoxAligned`, `ProbeBoxUnaligned`, `ProbeBoxObject0` (`stage1/level2`) |
| `$F6C0` | `CharPropsSet0` | 16 | Char properties of the first tile set: (count, property) x 8. Chars 0-76 nothing, 77-90 ladder, 91-94 deadly, 95-181 bit 3, 182-189 platform, 190-192 spring + wall, 193-251 wall, 252-255 floor. | `BuildCharProps` | - |
| `$F6D0` | `CharPropsSet1` | 16 | Char properties of the second tile set: 0-54 nothing, 55-58 ladder, 59-62 deadly, 63-206 bit 3, 207-215 platform, 216 spring + wall, 217-249 wall, 250-255 floor | `BuildCharProps` (`stage1/level3`) | - |

## leveldata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AF64` | `LevelMaps` | 120 of 5048 | The zones' maps: rows of 8 tile numbers (32 x 4 chars), one map a zone, zone after zone. DrawZone `$AD5A` draws 11 tile rows from map + (map row AND `$FC`) * 2: each byte a tile number, each tile 4 x 4 char codes from Tiles. The zone record +1-2 points at the map. A map row is 4 char rows: the zone's map row variable `$ADB7` counts char rows. | `BuildScreenMap`, `DetectPaging` | `DetectPaging` (code), `Set48K` (code) |
| `$AFDC` | `Level1Map2` (`LevelMaps`+120) | 216 | level 1 zone 2: 27 rows | `BuildScreenMap` | - |
| `$B0B4` | `Level1Map3` (`LevelMaps`+336) | 72 | level 1 zone 3: 9 rows | `BuildScreenMap` | - |
| `$B0FC` | `Level1Map4` (`LevelMaps`+408) | 264 | level 1 zone 4: 33 rows | `BuildScreenMap` | - |
| `$B204` | `Level1Map5` (`LevelMaps`+672) | 168 | level 1 zone 5: 21 rows | - | - |
| `$B2AC` | `Level1Map6` (`LevelMaps`+840) | 120 | level 1 zone 6: 15 rows | - | - |
| `$B324` | `Level2Map` (`LevelMaps`+960) | 256 | level 2 zone 1: 32 rows | `BuildScreenMap` (`stage1/level2`) | - |
| `$B424` | `Level2Map2` (`LevelMaps`+1216) | 200 | level 2 zone 2: 25 rows | `BuildScreenMap` (`stage1/level2`) | - |
| `$B4EC` | `Level2Map3` (`LevelMaps`+1416) | 120 | level 2 zone 3: 15 rows | - | - |
| `$B564` | `Level2Map4` (`LevelMaps`+1536) | 104 | level 2 zone 4: 13 rows | - | - |
| `$B5CC` | `Level2Map5` (`LevelMaps`+1640) | 112 | level 2 zone 5: 14 rows | - | - |
| `$B63C` | `Level2Map6` (`LevelMaps`+1752) | 208 | level 2 zone 6: 26 rows | - | - |
| `$B70C` | `Level2Map7` (`LevelMaps`+1960) | 288 | level 2 zone 7: 36 rows | - | - |
| `$B82C` | `Level3Map` (`LevelMaps`+2248) | 144 | level 3 zone 1: 18 rows | `BuildScreenMap` (`stage1/level3`) | - |
| `$B8BC` | `Level3Map2` (`LevelMaps`+2392) | 80 | level 3 zone 2: 10 rows | `BuildScreenMap` (`stage1/level3`) | - |
| `$B90C` | `Level3Map3` (`LevelMaps`+2472) | 80 | level 3 zone 3: 10 rows | - | - |
| `$B95C` | `Level3Map4` (`LevelMaps`+2552) | 176 | level 3 zone 4: 22 rows | - | - |
| `$BA0C` | `Level3Map5` (`LevelMaps`+2728) | 128 | level 3 zone 5: 16 rows | - | - |
| `$BA8C` | `Level3Map6` (`LevelMaps`+2856) | 80 | level 3 zone 6: 10 rows | - | - |
| `$BADC` | `Level3Map7` (`LevelMaps`+2936) | 176 | level 3 zone 7: 22 rows | - | - |
| `$BB8C` | `Level3Map8` (`LevelMaps`+3112) | 80 | level 3 zone 8: 10 rows | - | - |
| `$BBDC` | `Level3Map9` (`LevelMaps`+3192) | 176 | level 3 zone 9: 22 rows | - | - |
| `$BC8C` | `Level3Map10` (`LevelMaps`+3368) | 80 | level 3 zone 10: 10 rows | - | - |
| `$BCDC` | `Level3Map11` (`LevelMaps`+3448) | 128 | level 3 zone 11: 16 rows | - | - |
| `$BD5C` | `Level3Map12` (`LevelMaps`+3576) | 120 | level 3 zone 12: 15 rows | - | - |
| `$BDD4` | `Level4Map` (`LevelMaps`+3696) | 96 | level 4 zone 1: 12 rows | `BuildScreenMap` (`stage1/level4`) | - |
| `$BE34` | `Level4Map2` (`LevelMaps`+3792) | 224 | level 4 zone 2: 28 rows | `BuildScreenMap` (`stage1/level4`) | - |
| `$BF14` | `Level4Map3` (`LevelMaps`+4016) | 80 | level 4 zone 3: 10 rows | - | - |
| `$BF64` | `Level4Map4` (`LevelMaps`+4096) | 224 | level 4 zone 4: 28 rows | `DetectPaging` | `DetectPaging` (code), `Set48K` (code) |
| `$C044` | `Level4Map5` (`LevelMaps`+4320) | 80 | level 4 zone 5: 10 rows | - | - |
| `$C094` | `Level4Map6` (`LevelMaps`+4400) | 224 | level 4 zone 6: 28 rows | - | - |
| `$C174` | `Level4Map7` (`LevelMaps`+4624) | 80 | level 4 zone 7: 10 rows | - | - |
| `$C1C4` | `Level4Map8` (`LevelMaps`+4704) | 224 | level 4 zone 8: 28 rows | - | - |
| `$C2A4` | `Level4Map9` (`LevelMaps`+4928) | 120 | level 4 zone 9: 15 rows | - | - |
| `$C31C` | `Tiles` | 4096 | 256 tiles of 4 x 4 char codes (16 bytes: 4 rows of 4), read by `$AD76`. Tile T is at `$C31C` + 16T: rows top to bottom, 4 char codes a row. The char codes index the zone's char set (zone +0: set 0 bitmaps `$7100` attributes `$7900`, set 1 bitmaps `$7A00` attributes `$8200`). | `BuildScreenMap` | - |
| `$D31C` | `ObjectKinds` | 576 | 72 object kinds, 8 bytes each, indexed by an object record's kind (+1). SpawnObjects `$FD7D` copies, for kind K at `$D31C` + 8K: +0 to slot +7, +1 to slot +8, +2-3 (the animation list, AnimLists, or a graphic address `$6A80-$914B` for kinds 4-21) to slot +4/+5 and +`$12`/+`$13`, +4-5 (the movement script, ObjectScripts; 0 for kinds 0-23) to slot +`$14`/+`$15`. `$F7C3` reads +6 and +7 (`$D322` + 8K). Kinds 0, 2, 3 and 71 are all zero. The meaning of +0, +1, +6 and +7 (sizes and hit boxes, it seems) is known only from the code. | `PointInTrigger`, `SpawnObjects` | - |
| `$D55C` | `Zones` | 42 of 238 | The 34 zones, 7 bytes: +0 char set, +1-2 map, +3-4 exits, +5-6 object list. EnterZone `$AC83` (IX = the record, C = the map row): +0 = 0 char set 0, else set 1 (attributes `$79` or `$82` patched into `$A853` and `$AA80`); +1-2 the map (`$ADB5`); +3-4 the exit list (the operand of `$AB93`); +5-6 the object list (the operand of `$FD7D`). Levels 1-2 use set 0, levels 3-4 set 1. | `LoadScreen` | - |
| `$D586` | `Level2Zones` (`Zones`+42) | 49 | level 2: zone 1 of 7 | `LoadScreen` (`stage1/level2`) | - |
| `$D5B7` | `Level3Zones` (`Zones`+91) | 84 | level 3: zone 1 of 12 | `LoadScreen` (`stage1/level3`) | - |
| `$D60B` | `Level4Zones` (`Zones`+175) | 63 | level 4: zone 1 of 9 | `LoadScreen` (`stage1/level4`) | - |
| `$D64A` | `Exits` | 66 of 434 | The exit lists, one a zone: 5-byte records, `$FF` ends a list. CheckExit `$AB93` runs when the player leaves the screen sideways (`$FD62` = 0 left, 1 right): a record matches when +0 is that side and the player's char row in the map is +1 to +1 + 2. +2-3 the zone entered (`$FFFF`: the level is complete, `$ABD8`), +4 the map row there that takes +1's place on the screen. | `ExitScan` | - |
| `$D68C` | `Level2Exits` (`Exits`+66) | 77 | level 2 zone 1 | - | - |
| `$D6D9` | `Level3Exits` (`Exits`+143) | 192 | level 3 zone 1 | - | - |
| `$D799` | `Level4Exits` (`Exits`+335) | 99 | level 4 zone 1 | - | - |
| `$D7FC` | `Objects` | 285 of 1825 | The object lists, one a zone: 5-byte records in map row order, then `$FF` and "term". SpawnObjects `$FD7D` (D = the first map row, E = the rows) starts at the first record whose +0 is D or more and spawns while +0 < D + E. +0 the map char row (bits 3-7) ; +1 the kind (ObjectKinds; bit 7 set: taken, never spawned again; NewGame `$E2DC` clears bit 7 of all 365 records from `$D7FD`); +2 flags (bit 1: the one special slot `$EA8E`, bit 2: slot +0 bit 7, the whole byte to slot +`$0B`); +3 the x (bits 3-7) and a row offset (bits 0-2); +4 a second x (bits 3-7) and row offset (bits 0-2), slot +`$0C`/+`$1D`. Each list ends with `$FF` and the 4 bytes "term", a 5-byte record of its own: the RES 7 loop steps over it. | `Menu`, `SpawnObjects`, `TreasureObj` | `Menu`, `TreasureObj` |
| `$D919` | `Level2Objects` (`Objects`+285) | 460 | level 2 zone 1 | `Menu`, `SpawnObjects` (`stage1/level2`), `TreasureObj` (`stage1/level2`) | `Menu`, `TreasureObj` (`stage1/level2`) |
| `$DAE5` | `Level3Objects` (`Objects`+745) | 545 | level 3 zone 1 | `Menu`, `SpawnObjects` (`stage1/level3`) | `Menu` |
| `$DD06` | `Level4Objects` (`Objects`+1290) | 535 | level 4 zone 1 | `Menu`, `SpawnObjects` (`stage1/level4`) | `Menu` |
| `$DF1D` | `AnimLists` | 102 | Animation lists: frame bytes, `$FF` wraps to the first; pointed at by ObjectKinds +2-3. `$EE0B` steps slot +`$18` through the list: a frame byte, `$FF` = back to the start, 0 = no picture; bit 7 goes to slot +6 (known only from the code: a mirror flag, it seems), bits 0-6 pick the graphic. | `TrapMove` | - |
| `$DF83` | `ObjectScripts` | 662 | Movement scripts: 3-byte steps (frames, dx, dy), `$FF` ends; ObjectKinds +4-5. `$EE81` counts slot +`$19` up to the step's frames, adding the signed dx to x (slot +1) and dy to y each pass; at a frames byte `$FF` the object is removed (slot +`$0B` bit 0, when `$FD68` is 0) or restarts at its spawn place. | `TrapMove`, `TrapStepMove` (`stage1/controls`) | - |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E397` | `GameOverBlankText` | 12 | 11 spaces, ended by `$FF`: the band above and below GAME OVER | `PrintText` | - |
| `$E3A3` | `GameOverText` | 12 | " GAME OVER ", ended by `$FF` | `PrintText` | - |

## mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E440` | `GameComplete` | 1 | `$FF` when the last level is done (`$AC52`); cleared by NewGame `$E2DC`. Read by CheckGameComplete `$E406`. The ending recording sets it at the end of the closing text. | `Menu`, `CheckGameComplete` (code) | `Menu`, `ClearDoneLoop` (code), `LevelEndPress` (code) |
| `$E460` | `RandomState` | 2 of 6 | the generator's 16-bit state | `FrameTick`, `Random` | `FrameTick`, `Random` |
| `$E462` | `FrameCount` (`RandomState`+2) | 2 | frames since the load, low word (FrameTick `$E49B`) | `FrameTick`, `Random` | `FrameTick` |
| `$E464` | `FrameCountHigh` (`RandomState`+4) | 2 | its high word | `Random`, `FrameTick` (code) | `FrameTick` (code) |
| `$E4AD` | `Level` | 1 | The level, 0-3; 4 after the last (the ending). Cleared by NewGame `$E2DC`, raised by the level change `$ABF6`; `$AC07` uses it to pick the LevelTable record, `$AC20` as the end-of-level tune. | `LevelEnd` (code), `LevelEndPress` (code) | `Menu`, `ClearDoneLoop` (code), `LevelEnd` (code) |

## text

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E4E5` | `SouthAmericaText` | 279 | Level 1 intro: South America, the Goolu tribe | `PrintLines`, `PrintText` | - |
| `$E5FC` | `EgyptText` | 270 | Level 2 intro: Egypt, the jewel of Ankhel | - | - |
| `$E70A` | `CastleText` | 260 | Level 3 intro: Europe, Schwarzendumpf castle | - | - |
| `$E80E` | `MissileBaseText` | 235 | Level 4 intro: Europe, the secret missile base | - | - |
| `$E8F9` | `LondonText` | 258 | The ending: London, the Barfian empire | - | - |
| `$E9FB` | `TitleText` | 32 | " R I C K    D A N G E R O U S " | `PrintLines`, `PrintText` | - |
| `$EA1B` | `ControlsText` | 54 | 1 KEYBOARD, 2 KEMPSTON, 3 CURSOR, 4 SINCLAIR | `PrintLines`, `PrintText` | - |
| `$EA51` | `CreditsText` | 61 | PRESS FIRE TO START and the two copyright lines | `PrintLines`, `PrintText` | - |

## rick

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$ECED` | `DynFuse` | 1 | the dynamite's fuse count (set by the drop `$FAB1`) | `DynamiteObj` (`stage1/level2`) | `DynamiteObj` (`stage1/level2`), `MoveRick` (`stage1/level2`), `DropDynamite` (code) |
| `$ECEE` | `BlastX` | 1 | the blast's centre x | `TrapMove` (`stage1/level2`), `TrapTestBlast` (code) | `DynamiteObj` (`stage1/level2`) |
| `$ECEF` | `BlastY` | 2 | the blast's centre y | `TrapMove` (`stage1/level2`), `TrapTestBlast` (code) | `DynamiteObj` (`stage1/level2`) |
| `$ECF1` | `BlastOn` | 1 | `$FF` while the blast lasts; cleared by ResetObjects `$EBF7`, `$AD50` and DynamiteObj `$EC77` | `ClimberMove`, `EnemyCommon`, `DynamiteObj` (`stage1/level2`), `PatrolObj` (`stage1/level4`), `TrapMove` (`stage1/level2`) +2 | `ResetObjects`, `RestartScreen`, `DynamiteObj` (`stage1/level2`) |
| `$ECF2` | `FuseFrames` | 4 of 14 | the burning stick (twice), then BlastFrames | `DynamiteObj` (`stage1/level2`) | - |
| `$ECF6` | `BlastFrames` (`FuseFrames`+4) | 10 | the five blast frames: small, large, larger, large, small (also the boxes' explosion) | `DynamiteObj` (`stage1/level2`) | - |
| `$ED3F` | `BulletDx` | 1 | the bullet's step: negative left, positive right (`$FA75`, `$FA83`) | `BulletObj`, `EnemyCommon`, `ClimberObj` (`stage1/level2`), `PatrolObj` (`stage1/level4`) | `FireNoStick`, `MoveRick` (`stage1/level1`), `ShootSetFrame` (code) |
| `$ED40` | `BulletHitX` | 1 | the bullet's front x (BulletObj `$ED00`) | `BoxTestBullet` (code), `TrapTestBullet` (code) | `BulletObj` |
| `$ED41` | `BulletHitY` | 2 | the bullet's y + 5 (BulletObj `$ED00`) | `BoxTestBullet` (code), `TrapTestBullet` (code) | `BulletObj` |

## vars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FD54` | `RickVars` | 1 of 25 | Rick's state, cleared by `$AD29` (25 bytes). Flags are 0 or `$FF` unless said. `$FD54`, `$FD5D` and `$FD6B` are never used. | `BonusCollect`, `BonusCountdown`, `CheckScreenExit`, `ChooseRickFrame`, `ClimberMove` +22 | `BonusCollect`, `BonusTrigger`, `ChooseRickFrame`, `ClimbRick`, `DeathFall` +23 |
| `$FD55` | `YFraction` (`RickVars`+1) | 1 | Rick's Y fraction (8.8 with YVelocity) | `DeathFall`, `MoveRick` | `DeathFall`, `LandRick`, `MoveRick`, `RestartScreen` |
| `$FD56` | `YVelocity` (`RickVars`+2) | 2 | Rick's Y velocity, 8.8 signed (2 bytes): +`$80` per pass, at most `$0800`; `$FA80` a jump | `DeathFall`, `LandRick`, `MoveRick` | `DeathFall`, `KillRick`, `LandRick`, `MoveRick`, `NoFire` +4 |
| `$FD58` | `Facing` (`RickVars`+4) | 1 | 1 left, 0 right (the sprite mirror) | `ChooseRickFrame`, `FireNoStick`, `MoveRick` (`stage1/level1`), `ShootSetFrame` (code) | `RestartScreen`, `WalkRick`, `LandRick` (`stage1/controls`), `MoveRick` (`stage1/level1`) |
| `$FD59` | `Climbing` (`RickVars`+5) | 1 | - | `ChooseRickFrame`, `MoveRick` | `ClimbRick`, `NoFire`, `RestartScreen`, `MoveRick` (`stage1/level1`), `ClimbLeave` (code) +1 |
| `$FD5A` | `Crawling` (`RickVars`+6) | 1 | - | `ChooseRickFrame`, `MoveRick`, `ObjectsOverlap`, `RickHandler`, `SaveRestartPoint` +2 | `MoveRick`, `NoFire`, `RestartScreen` |
| `$FD5B` | `Airborne` (`RickVars`+7) | 1 | - | `ChooseRickFrame` | `LandRick`, `MoveRick`, `RestartScreen` |
| `$FD5C` | `AnimStep` (`RickVars`+8) | 2 | the step counter of ChooseRickFrame; `$FF` standing | `ChooseRickFrame` | `ChooseRickFrame`, `FireNoStick`, `RestartScreen`, `WalkRick`, `ClimbRick` (`stage1/level4`) +2 |
| `$FD5E` | `FireLatch` (`RickVars`+10) | 1 | set while fire with up is held: one shot per press | `FireNoStick`, `MoveRick` (`stage1/level1`), `FireClearPokeLatch` (code) | `FireNoStick`, `RestartScreen`, `MoveRick` (`stage1/level1`), `FireClearPokeLatch` (code), `FireNotUp` (code) |
| `$FD5F` | `PrevCrawl` (`RickVars`+11) | 1 | Crawling of the frame before | `LandRick`, `MoveRick` (`stage1/level1`) | `RestartScreen`, `RickHandler` |
| `$FD60` | `PokeLatch` (`RickVars`+12) | 1 | one stick sound per press | `LandRick` (`stage1/controls`), `MoveRick` (`stage1/level1`) | `FireNoStick`, `RestartScreen`, `LandRick` (`stage1/controls`), `MoveRick` (`stage1/level1`), `FireClearPokeLatch` (code) |
| `$FD61` | `ZoneChange` (`RickVars`+13) | 1 | set by ExitLeft / ExitRight, read at `$E3FD` | `Menu`, `StartLevel` (`stage1/level2`), `CheckZone` (code) | `ExitLeft`, `ExitRight`, `LoadScreen`, `RestartScreen`, `MoveRick` (`stage1/level1`) |
| `$FD62` | `ExitSide` (`RickVars`+14) | 1 | 0 left, 1 right (read at `$ABA6`) | `CheckScreenExit` | `ExitLeft`, `ExitRight`, `RestartScreen`, `MoveRick` (`stage1/level1`) |
| `$FD63` | `Poking` (`RickVars`+15) | 1 | the stick is out; the objects read PokeX / PokeY (`$EF57`, `$F019`, `$F273`) | `ChooseRickFrame`, `ClimberMove`, `EnemyCommon`, `PatrolObj` (`stage1/level4`), `TrapMove` (`stage1/level2`) +2 | `MoveRick`, `ResetObjects`, `RestartScreen`, `LandRick` (`stage1/controls`) |
| `$FD64` | `PokeX` (`RickVars`+16) | 1 | - | `EnemyCommon` (`stage1/level1`), `TrapMove` (`stage1/level2`), `BoxTestStick` (code), `ClimberTestStick` (code), `TrapTestStick` (code) | `RestartScreen`, `LandRick` (`stage1/controls`), `MoveRick` (`stage1/level1`) |
| `$FD65` | `PokeY` (`RickVars`+17) | 2 | 16-bit | `EnemyCommon` (`stage1/level1`), `TrapMove` (`stage1/level2`), `BoxTestStick` (code), `ClimberTestStick` (code), `TrapTestStick` (code) | `RestartScreen`, `LandRick` (`stage1/controls`), `MoveRick` (`stage1/level1`) |
| `$FD67` | `FireHeld` (`RickVars`+19) | 1 | fire with up held: the firing frame | `ChooseRickFrame` | `FireNoStick`, `MoveRick`, `RestartScreen`, `FireClearPokeLatch` (code) |
| `$FD68` | `Dying` (`RickVars`+20) | 1 | - | `ChooseRickFrame`, `KillRick`, `Menu`, `MoveRick`, `RickTouches` +4 | `KillRick`, `Menu`, `RestartScreen`, `StartLevel` (`stage1/level2`), `KillRickNow` (code) +1 |
| `$FD69` | `DeathDone` (`RickVars`+21) | 1 | Rick fell off the bottom: read at `$E3EB` | `Menu`, `StartLevel` (`stage1/level2`), `CheckDeath` (code) | `DeathFall`, `Menu`, `RestartScreen`, `StartLevel` (`stage1/level2`), `NewLife` (code) |
| `$FD6A` | `DeathDrift` (`RickVars`+22) | 2 | X step of the dying Rick: 3 or -3 | `DeathFall` | `KillRick`, `RestartScreen`, `KillRickDriftLeft` (code), `KillRickNow` (code) |
| `$FD6C` | `BonusActive` (`RickVars`+24) | 1 | set by BonusTrigger, the countdown at `$E466` | `BonusCollect`, `BonusCountdown` | `BonusCollect`, `BonusTrigger`, `RestartScreen` |
| `$FD6D` | `WalkFrames` | 8 of 16 | Rick's walk frames by AnimStep / 2. Read by ChooseRickFrame `$FC60` (FrameWalkTable `$FD47`). | `ChooseRickFrame` | - |
| `$FD75` | `CrawlFrames` (`WalkFrames`+8) | 8 | the crawl frames by AnimStep / 2 (FrameNotPoking `$FC9F`) | `ChooseRickFrame` | - |


## The BASIC "Rick" (`src/tape/basic.json`)

Rick Dangerous, Firebird 1989: TZX block 2, the BASIC program "Rick" (181 bytes at PROG `$5CCB`, LINE 10): it clears
to 50000, prints the title and loads and runs Rick1 at `$CD00`. Its entries are `src/tape/<module>.asm`, written
from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic.json`; the readers and writers from
`work/stage2/c1g`.

### The BASIC "Rick": basic

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine10` | 29 | 10 REM RICK DANGEROUS  v.2/89. A version mark ("v.2/89"); nothing reads it. | - | - |
| `$5CE8` | `BasicLine20` | 17 | 20 CLEAR 50000. RAMTOP at 50000 = `$C350`, below the key page `$C900` and Rick1 `$CD00`. | - | - |
| `$5CF9` | `BasicLine30` | 33 | 30 BORDER 0: PAPER 0: INK 0: CLS. A black screen and border: the title of line 40 is the only thing shown while Rick1 loads. | - | - |
| `$5D1A` | `BasicLine40` | 59 | 40 PRINT AT 1,8; PAPER 1; INK 7;" RICK DANGEROUS ". The title in white on blue at row 1, column 8. Rick1 then prints its own messages at rows 7 and 10. | - | - |
| `$5D55` | `BasicLine50` | 25 | 50 LOAD "Rick1" CODE 52480. Loads TZX blocks 3 and 4 (the header "Rick1", CODE, 512 bytes) at 52480 = `$CD00`, Rick1Start. | - | - |
| `$5D6E` | `BasicLine60` | 18 | 60 RANDOMIZE USR 52480. Calls Rick1Start `$CD00` (src/loader/rick1.asm), which never returns. | - | - |


## Rick1, the first loader stage (`src/loader/rick1.json`)

Rick Dangerous, Firebird 1989 (Bleepload): TZX block 4, Rick1: the first loader stage, which the ROM loads at
`$CD00` (512 bytes). Its entries are `src/loader/<module>.asm`, written from `src/loader/rick1.ann` by
`kit/mkgame.py --part src/loader/rick1.json`; the readers and writers from `work/stage2/c1g`.

### Rick1, the first loader stage: rick1

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CD0C` | `ColoursText` | 5 | INK 9, PAPER 8: the print colours (contrasting ink, transparent paper), `$FF` the end | - | - |
| `$CE5C` | `LoadingText` | 29 | AT 10,10, twelve spaces (clear the search line), AT 7,10 "Loading   " | - | - |
| `$CE84` | `BlockText` | 14 | AT 7,10 "Block ?   " | - | - |
| `$CE9F` | `SearchingText` | 14 | AT 10,10 "Searching " | - | - |
| `$CEB5` | `RewindText` | 14 | AT 10,10 "Rewind to " | - | - |
| `$CED4` | `Rick1Spare` | 44 | Rick1's last 44 bytes: zeros, which nothing reads but MakeKey `$5D12` (the key material) | - | - |


## The second loader stage (`src/loader/stage2.json`)

Rick Dangerous, Firebird 1989 (Bleepload): group 1's block 46: the second loader stage at `$5D00` (256 bytes,
deciphered, as the tape holds it). Its entries are `src/loader/<module>.asm`, written from `src/loader/stage2.ann`
by `kit/mkgame.py --part src/loader/stage2.json`; the readers and writers from `work/stage2/c1g`.

### The second loader stage: stage2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5DBE` | `Stage2Spare` | 66 | The page's last 66 bytes: zeros on the tape; the stack under `$5DFF` from ShowScreen on | - | - |


## LoadGroup, the loader of groups 2 and 3 (`src/loader/loadgroup.json`)

Rick Dangerous, Firebird 1989 (Bleepload): group 1's blocks 44-45: LoadGroup at `$FA00`, the loader of groups 2 and
3 (512 bytes, deciphered). Its entries are `src/loader/<module>.asm`, written from `src/loader/loadgroup.ann` by
`kit/mkgame.py --part src/loader/loadgroup.json`; the readers and writers from `work/stage2/c1g`.

### LoadGroup, the loader of groups 2 and 3: loadgroup

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FA1A` | `GroupColoursText` | 5 | INK 9, PAPER 8, `$FF` the end | - | - |
| `$FB6D` | `GroupLoadingText` | 11 | "Loading   " | - | - |
| `$FB85` | `GroupBlockText` | 11 | "Block ?   " | - | - |
| `$FBA0` | `GroupSearchingText` | 11 | "Searching " | - | - |
| `$FBB6` | `GroupRewindText` | 11 | "Rewind to " | - | - |
| `$FBD5` | `SpacesText` | 13 | twelve spaces | - | - |
| `$FBE6` | `StatusAtText` | 1 of 4 | AT row, column: the row and the column LoadGroup sets | - | `LoadGroup` (code) |
| `$FBE7` | `StatusAt` (`StatusAtText`+1) | 3 | the row, then the column: LoadGroup's C and B | - | `LoadGroup` (code) |
| `$FBEE` | `ErrorAtText` | 1 of 4 | AT row, column: the row and the column LoadGroup sets | - | `LoadGroup` (code) |
| `$FBEF` | `ErrorAt` (`ErrorAtText`+1) | 3 | the row, then the column: LoadGroup's E and D | - | `LoadGroup` (code) |
| `$FBF3` | `GroupMarker` | 1 | The marker of the group being loaded (`$34` or `$35`), set by LoadGroup | `GroupNextBlock` (code) | `LoadGroup` (code) |
| `$FBF4` | `LoadGroupSpare` | 12 | LoadGroup's last 12 bytes: zeros | - | - |


## The AY player and tunes (RAM 1) (`src/music/music.json`)

Rick Dangerous, Firebird 1989: the AY music and effects player and its tunes, `$0DA4` bytes, assembled at `$C000` in
RAM 1 where the entry's CopyMusicToRam1 puts them on a 128K; the game image holds the same bytes at `$5E00`. Its
entries are `src/music/<module>.asm`, written from `src/music/music.ann` by `kit/mkgame.py --part
src/music/music.json`; the readers and writers from `work/stage2/c1g`, `work/stage1/controls`,
`work/stage1/gameover`, `work/stage1/level1`, `work/stage1/level2`, `work/stage1/level3`, `work/stage1/level4`.

### The AY player and tunes (RAM 1): player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C000` | `PeriodTable` | 170 | AY tone periods, 85 notes from C-1 (3822) by semitones; index = note + transpose + 12. TrackStep `$C4B4` (at `$C573`) and OrnamentStep `$C5F5` (at `$C672`) read the word at PeriodTable + 2 * index; the index is the pattern's note plus the track's transpose plus 12. The values are 2 000 000 / 16 / f of the equal-tempered scale (3822: 32.7 Hz, C-1, at 2 MHz). Two entries carry a typo in bit 5 of the low byte: index 20 (G#2) is 1236 (`$04D4`), not 1204 (`$04B4`), and index 24 (C-3) is 988 (`$03DC`), not 956 (`$03BC`); those two notes sound about half a semitone flat. The last entry, index 84, is 24, not 30. | `TrackStep` | - |
| `$C0AA` | `MixerShadow` | 1 | AY register 7 as last written: bits 0-2 tone off, bits 3-5 noise off (all set: silent). StartNote clears the channel's tone and/or noise bits (its instrument's flags bits 0 and 1), ReleaseStep `$C2DD` sets them again when the volume reaches 0. UpdateAy returns at once while bits 0-5 are all set (nothing sounding): that is the cost of a silent frame. As loaded: `$3F`. | `AyTick`, `ChannelStep`, `ReleaseStep`, `SilenceAll`, `StartNote` +1 | `ReleaseStep`, `SilenceAll`, `StartNote` |
| `$C0AB` | `ChannelA` | 18 | Channel A: +0 tone-on AND mask, +1 noise-on AND mask, +2 its mixer bits, +3/+4 period, +5 volume (0-255). The channel record (IX), 18 bytes: +0 the AND mask that turns its tone on in register 7, +1 the mask that turns its noise on, +2 both its bits (tone and noise off), +3/+4 the note's period, +5 the volume (0-255; AY volume = it / 8), +6 the duration left (frames; 0: released; `$FF`: held), +7 the vibrato delay left (`$FF`: none), +8 the vibrato steps left, +9/+10 the offset added to the period, +11/+12 the offset's step per frame, +13/+14 the envelope phase routine (AttackStep `$C28D`, DecayStep `$C2AC`, SustainStep `$C2CE`, ReleaseStep `$C2DD`), +15/+16 the instrument, +17 the instrument's flags (bit 7 set while an effect owns the channel, so tunes leave it alone). Masks of channel A as loaded: `$FE`, `$F7`, `$09`. | `AttackStep`, `ChannelStep`, `DecayStep`, `OrnamentStep`, `ReleaseStep` +5 | `AttackStep`, `ChannelStep`, `DecayStep`, `ReleaseStep`, `SilenceAll` +3 |
| `$C0BD` | `ChannelB` | 18 | Channel B (masks `$FD`, `$EF`, `$12`); effect 4 always plays here | `AttackStep`, `ChannelStep`, `DecayStep`, `OrnamentStep`, `ReleaseStep` +5 | `AttackStep`, `ChannelStep`, `DecayStep`, `ReleaseStep`, `SilenceAll` +3 |
| `$C0CF` | `ChannelC` | 18 | Channel C (masks `$FB`, `$DF`, `$24`) | `AttackStep`, `ChannelStep`, `DecayStep`, `OrnamentStep`, `ReleaseStep` +5 | `AttackStep`, `ChannelStep`, `DecayStep`, `ReleaseStep`, `SilenceAll` +3 |
| `$C0E1` | `NoisePeriod` | 1 | The noise period: the low period byte of the last channel with noise (instrument flags bit 1). UpdateAy stores the low byte of a noise channel's period (+ offset) here and writes it rotated right three times to AY register 6. | `UpdateAy` | `UpdateAy` |

### The AY player and tunes (RAM 1): sequencer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C35A` | `MusicOn` | 1 | The music flag: `$FF` after AyPlayTune, 1 while the last notes die away, 0 when the tune is over. AyPlayTune sets `$FF`; AyTick ORs the three tracks' active bytes (+13) into it, and when all three order lists have ended it is 1 until every channel is silent, then 0. AyTick steps the tracks only while it is not 0. | `AyTick` | `AyPlayTune`, `AyTick`, `OldStopMusic` (code) |
| `$C38D` | `Track0` | 21 | Track 0 (channel A): +0 instrument map offset, +1/+2 order list pointer, +3/+4 pattern start, +5/+6 pattern pointer. The track record (IY), 21 bytes: +0 its 8 slots' offset in InstrumentMap (0, 8, 16 as loaded; never written), +1/+2 the next order list byte, +3/+4 the pattern's start (for a repeat), +5/+6 the next pattern byte, +7/+8 the instrument, +9 the repeats left, +10 the transpose (semitones), +11 `$FF` when the pattern has ended, +12 the frames left of the note, +13 active (0 when its order list has ended), +14 the note's period index, +15 the ornament number, +16/+17 the ornament pointer, +18 the ornament step's frames, +19 the steps left, +20 the ornament state (bit 7 on, bit 6 restart, bits 0-5 the number). | `AyTick`, `OrnamentStep`, `PatternCommand`, `TrackStep` | `AyPlayTune`, `OrnamentStep`, `PatternCommand`, `TrackStep` |
| `$C3A2` | `Track1` | 21 | Track 1 (channel B), map offset 8 | `AyTick`, `OrnamentStep`, `PatternCommand`, `TrackStep` | `AyPlayTune`, `OrnamentStep`, `PatternCommand`, `TrackStep` |
| `$C3B7` | `Track2` | 21 | Track 2 (channel C), map offset 16 | `AyTick`, `OrnamentStep`, `PatternCommand`, `TrackStep` | `AyPlayTune`, `OrnamentStep`, `PatternCommand`, `TrackStep` |
| `$C3CC` | `InstrumentMap` | 24 | Each track's 8 instrument slots: an offset into Instruments, 0-70 step 10, set by AyPlayTune. A pattern's `$80`-`$87` takes slot 0-7 here; an order list's `$C0`-`$FD` byte puts the next byte into a slot (no tune does). AyPlayTune fills all three with 0, 10, ... 70, so slot N is instrument N. | `PatternCommand` | `AyPlayTune` |

### The AY player and tunes (RAM 1): effects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C6E4` | `EffectChannel` | 1 | The channel of the last effect: 0, 1, 2 = A, B, C (as loaded 0) | `AyPlayEffect` | `AyPlayEffect` |
| `$CD08` | `EffectTable` | 13 of 156 | The 12 effects, 13 bytes each: an instrument's 10 bytes, the period, the duration. +0-+9 as Instruments, +10/+11 the period, +12 the duration in frames. The comments give the call sites of the game's AyPlayEffect `$9FED` with A = the effect and the most runs of a call site in one recording. | `AttackStep`, `AyPlayEffect`, `ChannelStep`, `DecayStep`, `ReleaseStep` +2 | - |
| `$CD15` | `Effect1` (`EffectTable`+13) | 13 | Effect 1: noise; fire with no bullets left, `$FA47` (emptygun, frames 500 and 580) | - | - |
| `$CD22` | `Effect2` (`EffectTable`+26) | 13 | Effect 2: noise, a slide; the dynamite's bang, `$EC93` (level3 6) | `AttackStep` (`stage1/level2`), `AyPlayEffect` (`stage1/level2`), `ChannelStep` (`stage1/level2`), `DecayStep` (`stage1/level2`), `ReleaseStep` (`stage1/level2`) +2 | - |
| `$CD2F` | `Effect3` (`EffectTable`+39) | 13 | Effect 3: noise, a slide (step -8); a trap set off `$EFCB`, a poke with the stick `$F9EF` (level4 62 at `$EFCB`) | `AttackStep`, `AyPlayEffect`, `ChannelStep`, `DecayStep`, `ReleaseStep` +2 | - |
| `$CD3C` | `Effect4` (`EffectTable`+52) | 13 | Effect 4: tone and noise, always channel B; Rick's steps (crawl `$FCB8`, climb `$FD0D`, walk `$FD44`) (level3 357 at `$FD44`) | `AttackStep`, `AyPlayEffect`, `ChannelStep`, `DecayStep`, `ReleaseStep` +1 | - |
| `$CD49` | `Effect5` (`EffectTable`+65) | 13 | Effect 5: noise; no call site passes 5 | - | - |
| `$CD56` | `Effect6` (`EffectTable`+78) | 13 | Effect 6: tone, a slide up after 4 frames (step `$0FF8`: -8 in the AY's 12 bits); a head against a ceiling `$F97D`, `$FADB` (level2 53 and 67) | `AttackStep`, `AyPlayEffect`, `ChannelStep`, `DecayStep`, `ReleaseStep` +2 | - |
| `$CD63` | `Effect7` (`EffectTable`+91) | 13 | Effect 7: tone, a slide up after 3 frames (step `$0FF7`); no call site passes 7 | - | - |
| `$CD70` | `Effect8` (`EffectTable`+104) | 13 | Effect 8: tone, a vibrato; dynamite or bullets picked up, `$ED76` (once, in the L1Z4 zone recording) | - | - |
| `$CD7D` | `Effect9` (`EffectTable`+117) | 13 | Effect 9: tone, a vibrato; a treasure picked up, `$EDEC` (level1 4) | `AttackStep`, `AyPlayEffect`, `ChannelStep`, `DecayStep`, `ReleaseStep` +2 | - |
| `$CD8A` | `Effect10` (`EffectTable`+130) | 13 | Effect 10: tone, as 9 without the vibrato (delay `$FF`); the bonus count starts (the start marker), `$F4FE` (controls 7) | `AttackStep`, `AyPlayEffect`, `ChannelStep`, `DecayStep`, `StartNote` +1 | - |
| `$CD97` | `Effect11` (`EffectTable`+143) | 13 | Effect 11: tone, a slide that stops; Rick dies `$FBF4`, an enemy is hit `$F17E` (level4 29 at `$FBF4`) | `AttackStep`, `AyPlayEffect`, `ChannelStep`, `DecayStep`, `ReleaseStep` +2 | - |

### The AY player and tunes (RAM 1): tunes

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C6E5` | `Patterns` | 938 | The 55 patterns, one after the other: notes (note, frames), rests, instrument bytes, `$FF` at the end. A pattern: `$80`-`$87` instrument slot, `$7F` FRAMES a rest, `$7E` LO HI FRAMES a period given directly, NOTE FRAMES a note (NOTE 0-`$7D`, played at PeriodTable[NOTE + transpose + 12]), `$FF` the end. The tunes use notes 6-52, durations of 4-96 frames (50 a second) and instruments 0-5. Patterns 34-37 are empty (only `$FF`), and 12 patterns are named by no order list: 21, 28-30, 34-37, 39, 42, 49, 50. | `PatternCommand`, `TrackStep` | - |
| `$CA8F` | `TuneTable` | 48 | 8 tunes x 3 order list pointers (channels A, B, C). Tune 0 `$E324` (a level's intro), 1-4 `$AC20` (a level's end), 5 `$E220` (the menu), 6 `$E386` (GAME OVER), 7 `$F531` (the bonus end marker). In the recordings (reads of this table): tunes 0, 5, 6 in `controls` and `gameover`; 0, 5, 6, 7 in `level1`; 4, 5, 6 in `ending`. | `AyPlayTune` | - |
| `$CABF` | `OrderLists` | 395 | The 24 order lists: pattern numbers, `$80`+N repeats, `$FE` N transpose, `$FF` end. Stored for tunes 0-3, 5-7, then 4. Tunes 2, 3, 4, 6 and 7 leave a channel silent (a list that is only `$FF`). Transposes run from -12 (tune 2) to +28 semitones (tune 0's last pattern). | `TrackStep` | - |
| `$CC4A` | `PatternLo` | 55 | The low bytes of the 55 pattern addresses | `TrackStep` | - |
| `$CC81` | `PatternHi` | 55 | The high bytes of the 55 pattern addresses | `TrackStep` | - |
| `$CCB8` | `Instruments` | 80 | 8 instruments of 10 bytes: attack, decay, sustain, release, peak, vibrato delay, length, step, flags. +0 attack step, +1 decay step (signed), +2 sustain level, +3 release step (signed), +4 peak volume (AY volume = /8), +5 vibrato delay in frames (`$FF`: none), +6 vibrato length (0: a slide that goes on, bit 7: a slide that stops), +7/+8 the step added to the period each frame, +9 flags (bit 0 tone, bit 1 noise, bit 2 fixed volume). Instruments 0-4 are tone with envelopes peaking at `$2D`-`$36`; 5 is noise, used only by pattern 42, which no order list names; 6 (a tone that slides down after 63 frames, step `$0500`) and 7 (noise with a vibrato, step `$6400`: `$0400` in the AY's 12 bits) are used by no pattern. | `AttackStep`, `ChannelStep`, `DecayStep`, `ReleaseStep`, `StartNote` | - |
