# 11. Data reference

Every data entry of the game image `$6D42`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## hiscore

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6D42` | `ScrollerText` | 434 | The menu scroller's text: 433 ASCII characters and a 0 end mark. RunScroller `$8AEB` prints one character a step at the right end of the bottom line and scrolls the line left 8 pixels (ScrollBottomLine `$8AAC`) between characters. The text names the 1990 features (anti-gravity, 4D teleport, forcefields, bubbles, elixirs, "jumping jelly beans"), the keys G (abort), H (quit screen) and F (map), and "(C) 1990 MICHAEL BATTY". Witness: the menu recording reads the whole text: 3472 ScrollBottomLine calls = 434 x 8, frames 3284-5478, the last character the 0 end mark. | - | - |
| `$8D5D` | `HiScoresTitle` | 9 | "HI-SCORES" | `PrintText` (`stage1/hiscore`) | - |
| `$AA00` | `GameOverTune` | 78 | The game-over tune | `PlayTune` (`stage1/hiscore`) | - |
| `$AA4E` | `GameOverTexts` | 9 of 36 | "GAME OVER", "YOU SCORED", "AND REACHED LEVEL" | `PrintText` (`stage1/hiscore`) | - |
| `$AA57` | `YouScoredText` (`GameOverTexts`+9) | 10 | - | `PrintText` (`stage1/hiscore`) | - |
| `$AA61` | `ReachedLevelText` (`GameOverTexts`+19) | 17 | - | `PrintText` (`stage1/hiscore`) | - |
| `$AA72` | `BlankGraphic` | 36 | The empty cell's graphic (36 zeros): table word 0, set by SetEarthFalls; also clears the high-score area | `DrawCell` | - |
| `$AA96` | `GameOverPad` | 106 | Zeros (106 bytes) | - | - |
| `$B2F9` | `ShowHiScoresPad` | 7 | Zeros (7 bytes) | - | - |

## music

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6EF4` | `WinTune` | 1034 | The tune after cave 32: 258 notes, the last record `$FF`,`$FF` at `$72FC`. Played by WinGame `$A8BF` through PlayWinTune `$A615`. Witness: the rzx32 build reads `$6EF4-$6F5F` (its first 27 notes) before the recording ends; the rest is known only from the code. | `PlayTune` (`stage1/rzx32`) | - |
| `$72FE` | `WinTunePad` | 2 | Leftover: two `$FF` bytes after the win tune. No code reads them (known only from the code). | - | - |
| `$8960` | `PlayCaveTunePad` | 4 | Leftover: CALL `$88CE`, RET (the 1988 version's tail after LD HL,`$BB80`) | - | - |
| `$AC5F` | `LifeTune` | 158 | The extra-life tune | `PlayTune` (`stage1/rzx09`) | - |
| `$ACFD` | `LifeTunePad` | 3 | Leftover: 3 bytes `$FF` | - | - |
| `$AD00` | `TitleTune` | 1386 | The title tune | `PlayTune` | - |
| `$B26A` | `TitleTunePad` | 2 | Leftover: 2 zero bytes | - | - |
| `$BB80` | `CaveTune1` | 122 | The tune of caves 1-4 | `PlayTune` | - |
| `$BBFA` | `CaveTune1Pad` | 6 | Zeros (6 bytes) | - | - |
| `$BC00` | `NotePeriods` | 146 | The note periods: 73 big-endian words, note n at `$BC00` + 2n | `PlayTune` | - |
| `$EE24` | `CaveTunes` | 16 | The tune of each group of four caves | `PlayCaveTune` | - |
| `$EE49` | `PlayCaveTunePad2` | 183 | Leftover: 183 bytes | - | - |
| `$F100` | `CaveTune2` | 82 | The tune of caves 5-8 | `PlayTune` (`stage2/rzx04/cap`) | - |
| `$F152` | `CaveTune8` | 126 | The tune of caves 29-32 | `PlayTune` (`stage1/rzx28`) | - |
| `$F1D0` | `CaveTune3` | 66 | The tune of caves 9-12 | `PlayTune` (`stage1/hiscore`) | - |
| `$F212` | `CaveTune4` | 134 | The tune of caves 13-16 | `PlayTune` (`stage1/rzx12`) | - |
| `$F298` | `CaveTune7` | 106 | The tune of caves 25-28 | `PlayTune` (`stage1/rzx24`) | - |
| `$F302` | `CaveTune5` | 150 | The tune of caves 17-20 | `PlayTune` (`stage1/rzx16`) | - |
| `$F398` | `CaveTune6` | 262 | The tune of caves 21-24 | `PlayTune` (`stage1/rzx20`) | - |
| `$F49E` | `CaveTunesPad` | 1602 | Leftover: 1602 bytes, from `$F9A6` an unused test cave record (src/res/leftovers/README.md) | - | - |

## effects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7300` | `TeleportFrames` | 3072 | Four attribute screens of 768 bytes the teleport effect copies to `$5800` in turn. TeleportFlashOut `$9230` and TeleportFlashIn `$924F` step AnimPhase `$FD72` up or down (0-3) and copy frame AnimPhase (`$7300` + 768 x phase) to the attributes. Witness: the rzx builds read all four frames. | `TeleportFlashIn` (`stage2/rzx04/cap`), `TeleportFlashOut` (`stage2/rzx04/cap`) | - |
| `$8234` | `ThudSoundPad` | 28 | Leftover: 28 bytes, never run | - | - |
| `$8264` | `FallSoundPad` | 1 | Leftover: one byte, never run | - | - |
| `$8548` | `DigNoise` | 2 | The dig noise's entry: LD HL,`$00FF`, whose `$00` is the loop's NOP at `$854A`. CALL `$8548` from DigNoiseIfDug `$E860`: HL = `$00FF`, then DigNoiseLoop `$854A` sends the ROM bytes `$00FF-$0001` AND `$18` to port `$FE`. mkgame keeps the two bytes as data because `$854A` starts an instruction too. | - | - |
| `$861F` | `DeathSoundPad` | 15 | Leftover: 15 bytes before DeathSound, never run | - | - |
| `$862E` | `DeathSound` | 2 | The death sound's entry: LD HL,`$0000`, whose second `$00` is the loop's NOP at `$8630`. CALL `$862E` from PlayCave `$8885` after a kill: HL = 0, then DeathLoop `$8630`. Witness: the c1 build's crush (frame 13218), death-crush (frame 30), death-fire (frame 288). mkgame keeps the two bytes as data because `$8630` starts an instruction too. | - | - |
| `$8643` | `DeathLoopPad` | 17 | Leftover: 17 bytes, never run | - | - |
| `$E7E8` | `PassSoundOld` | 13 | Leftover: an older pass sound choice (13 bytes) | - | - |

## cells

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7FFA` | `FlagsPad` | 1 | Leftover: a byte before the flags, never read | - | - |
| `$7FFB` | `FizzCount` | 1 | The fizz countdown: 7 when a boulder stands over fire (the scan's dissolve); FizzSound `$A773` beeps while it runs down | `FizzSound` | `ResetAntiGrav`, `AntiGravScan` (`stage1/rzx11`), `FizzSound` (`stage1/rzx01`), `ScanCellsBody` (`stage1/rzx01`) |
| `$7FFC` | `SwitchHit` | 1 | `$FF` when a falling object landed on a switch box; SwitchClear `$817A` then clears the force fields | `SwitchClear` | `ResetAntiGrav`, `MoveObject` (`stage1/rzx02`), `SwitchClear` (`stage1/rzx02`), `LandOnSwitch` (code) |
| `$7FFD` | `PlayerKilled` | 1 | `$FF` when the player is killed: crushed by a falling object or walked into fire | `PlayCave` | `ClearMapFlag`, `Crush`, `StartGameEntry`, `CaveStart` (`stage1/hiscore`), `UpSpecialCell` (`stage2/death-fire`) |
| `$7FFE` | `ObjectFell` | 1 | `$FF` when an object other than a boulder fell this pass (the fall noise) | `FallSoundChoice` | `MoveObject`, `ScanCellsBody`, `AntiGravMove` (`stage1/rzx03`), `AntiGravScan` (`stage1/rzx03`) |
| `$7FFF` | `BoulderFell` | 1 | `$FF` when a boulder fell this pass (the fall noise) | `PassSound` | `BoulderLandCheck`, `ClearFallFlags`, `AntiGravMove` (`stage1/rzx03`), `SetBoulderFlags` (`stage1/rzx03`) |
| `$8101` | `MoveObjectPad` | 3 | Leftover: 3 bytes between two jumps, never run | - | - |
| `$810B` | `MoveObjectPad2` | 3 | Leftover: 3 bytes, never run | - | - |
| `$81A7` | `SwitchClearPad` | 5 | Leftover: 5 bytes, never run | - | - |
| `$9AA5` | `EarthFell` | 1 | `$FF` when the falling object is earth: it then does not crush (EarthFallGuard) | `Crush` | `EarthFallGuard` |
| `$E7A8` | `BoulderLanded` | 1 | `$FF` when a falling boulder landed this pass (the thud) | `PassSound` | `BoulderLandCheck`, `ClearFallFlags`, `SetBoulderFlags` (`stage1/rzx03`) |

## renderer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8000` | `CellGraphicsTable` | 2 of 64 | The graphic of each cell code 0-31: 32 addresses of 36-byte graphics. Read through CellGraphicAddr `$8D66` by DrawCell `$8F60` (every cell drawn, in every build). Words 3 and 4 (the player), 6 and 5 (earth, wall) and the animated words 8, 9, 10 and 12-15 are rewritten during play, and word 0 (the empty cell) in the falling-earth caves: EarthAnimStep `$FB70` points it at a frame of EmptyFrames `$FAE0` each pass, and SetEarthFalls `$FB84` puts BlankGraphic `$AA72` back at every cave start. Words 16 and 21 (`$8020`, `$802A`) are never read: the codes `$10` and `$15` step on (AnimateCellCodes `$937E`) before the window is drawn in the same pass. Words 1 (the exit: it flashes by its attributes, ExitFlash `$905B`), 2 (the boulder), 7 (the gem: DrawPass `$8D46` cycles its attribute bytes) and 11 (the switch) are never written (code and the state logs). Words 28-31 are `$0000`: no such cells. | `AnimateCells`, `DrawCell`, `EarthAnim`, `SetEarthFalls` | `AnimateCells`, `AnimateTable`, `CaveSetup`, `DeathView`, `SetEarthFalls` +3 |
| `$8002` | `CellExitGfx` (`CellGraphicsTable`+2) | 2 | cell 1 | `DrawCell` (`stage1/rzx01`) | - |
| `$8004` | `CellBoulderGfx` (`CellGraphicsTable`+4) | 2 | cell 2 | `DrawCell` | - |
| `$8006` | `CellPlayerRightGfx` (`CellGraphicsTable`+6) | 2 | cell 3 | `AnimateCells`, `DrawCell` | `AnimateCells`, `DeathView`, `WinScreen` (`stage1/rzx32`) |
| `$8008` | `CellPlayerLeftGfx` (`CellGraphicsTable`+8) | 2 | cell 4 | `AnimateCells`, `DrawCell` | `AnimateCells`, `DeathView` |
| `$800A` | `CellWallGfx` (`CellGraphicsTable`+10) | 2 | cell 5 | `DrawCell` | `CaveSetup` |
| `$800C` | `CellEarthGfx` (`CellGraphicsTable`+12) | 2 | cell 6 | `DrawCell`, `EarthAnim`, `SetEarthFalls` | `CaveSetup`, `EarthAnim` (`stage1/rzx13`) |
| `$800E` | `CellGemGfx` (`CellGraphicsTable`+14) | 2 | cell 7 | `DrawCell` | - |
| `$8010` | `CellJellyBeanGfx` (`CellGraphicsTable`+16) | 2 | cell 8 | `DrawCell` | `AnimateTable` |
| `$8012` | `CellForceFieldGfx` (`CellGraphicsTable`+18) | 2 | cell 9 | `DrawCell` (`stage1/rzx02`) | `AnimateTable` |
| `$8014` | `CellAntiGravGfx` (`CellGraphicsTable`+20) | 2 | cell 10 | `DrawCell` (`stage1/hiscore`) | `AnimateTable` |
| `$8016` | `CellSwitchGfx` (`CellGraphicsTable`+22) | 2 | cell 11 | `DrawCell` (`stage1/rzx02`) | - |
| `$8018` | `CellPotionGfx` (`CellGraphicsTable`+24) | 2 | cell 12 | `DrawCell` (`stage1/rzx09`) | `AnimateTable` |
| `$801A` | `CellTeleporterGfx` (`CellGraphicsTable`+26) | 2 | cell 13 | `DrawCell` (`stage2/rzx04/cap`) | `AnimateTable` |
| `$801C` | `CellBubbleGfx` (`CellGraphicsTable`+28) | 2 | cell 14 | `DrawCell` | `AnimateTable` |
| `$801E` | `CellFireGfx` (`CellGraphicsTable`+30) | 2 | cell 15 | `DrawCell` | `AnimateTable` |
| `$8020` | `CellBurstGfx` (`CellGraphicsTable`+32) | 10 | cell 16 (`$10-$14`: the bubble burst frames) | `DrawCell` (`stage1/rzx02`) | - |
| `$802A` | `CellDissolveGfx` (`CellGraphicsTable`+42) | 14 | cell 21 (`$15-$1B`: the boulder dissolving in fire) | `DrawCell` (`stage1/rzx01`) | - |
| `$8038` | `CellUnusedGfx` (`CellGraphicsTable`+56) | 8 | cell 28 (28-31: no such cells, `$0000`) | - | - |
| `$8278` | `AttrAddrPad` | 62 | Leftover: 62 bytes, never run | - | - |
| `$8D6D` | `CellGraphicAddrPad` | 8 | Leftover: 8 bytes, never run | - | - |
| `$9B08` | `CellGraphics` | 36 of 756 | The cell graphics, slots 0-20 (36 bytes each) | `CaveSetupAll`, `DrawCell` | `DrawPass`, `SetGraphicColour`, `ExitFlash` (`stage1/rzx01`) |
| `$9B2C` | `GfxBoulder` (`CellGraphics`+36) | 36 | slot 1, cell 2: BoulderColour | `CaveSetupAll`, `DrawCell` | `SetGraphicColour` |
| `$9B50` | `GfxEarth` (`CellGraphics`+72) | 36 | slot 2: the earth of 24 caves, EarthColour | `DrawCell` | `SetGraphicColour` |
| `$9B74` | `GfxGem` (`CellGraphics`+108) | 36 | slot 3, cell 7: the ink cycles (DrawPass) | `DrawCell` | `DrawPass` |
| `$9B98` | `GfxPlayerRight` (`CellGraphics`+144) | 144 | slots 4-7, cell 3: four frames | `DrawCell` | - |
| `$9C28` | `GfxPlayerLeft` (`CellGraphics`+288) | 144 | slots 8-11, cell 4: four frames | `DrawCell` | - |
| `$9CB8` | `GfxWall1` (`CellGraphics`+432) | 36 | slot 12: Wall1Colour | `DrawCell` | `SetGraphicColour` |
| `$9CDC` | `GfxWall2` (`CellGraphics`+468) | 36 | slot 13 | `DrawCell` (`stage1/rzx05`) | - |
| `$9D00` | `GfxWall3` (`CellGraphics`+504) | 36 | slot 14 | `DrawCell` (`stage1/rzx12`) | - |
| `$9D24` | `GfxWall4` (`CellGraphics`+540) | 36 | slot 15 | `DrawCell` (`stage1/rzx09`) | - |
| `$9D48` | `GfxWall5` (`CellGraphics`+576) | 36 | slot 16 | `DrawCell` (`stage1/rzx03`) | - |
| `$9D6C` | `GfxWall6` (`CellGraphics`+612) | 36 | slot 17 | `DrawCell` (`stage1/rzx15`) | - |
| `$9D90` | `GfxSpare` (`CellGraphics`+648) | 36 | slot 18: never read | - | - |
| `$9DB4` | `GfxDeathRight` (`CellGraphics`+684) | 36 | slot 19: the killed player (DeathView) | `DrawCell` | - |
| `$9DD8` | `GfxDeathLeft` (`CellGraphics`+720) | 36 | slot 20: the killed player facing left (the stage 2 recordings death-crush and death-fire; the c1 crush faced right) | `DrawCell` (`stage2/death-crush`) | - |
| `$9E1A` | `EarthAnimPad` | 6 | Leftover: 6 bytes after EarthAnim | - | - |
| `$9E20` | `CellGraphics2` | 144 of 2016 | The cell graphics, slots 22-77 (36 bytes each) | `DrawCell` | `SetGraphicColour` |
| `$9EB0` | `GfxSwitch` (`CellGraphics2`+144) | 36 | slot 26, cell 11 | `DrawCell` (`stage1/rzx02`) | - |
| `$9ED4` | `GfxFire` (`CellGraphics2`+180) | 144 | slots 27-30, cell 15 | `DrawCell` | - |
| `$9F64` | `GfxTeleporter` (`CellGraphics2`+324) | 432 | slots 31-42, cell 13: twelve frames (TeleporterPhase) | `DrawCell` (`stage2/rzx04/cap`) | - |
| `$A114` | `GfxBubble` (`CellGraphics2`+756) | 144 | slots 43-46, cell 14 | `DrawCell` | - |
| `$A1A4` | `GfxDissolve` (`CellGraphics2`+900) | 252 | slots 47-53, cells `$15-$1B`: BoulderColour (CaveSetupAll) | `DrawCell` (`stage1/rzx01`) | `SetGraphicColour` |
| `$A2A0` | `GfxForceField` (`CellGraphics2`+1152) | 288 | slots 54-61, cell 9: eight frames (ForceFieldPhase) | `DrawCell` (`stage1/rzx02`) | - |
| `$A3C0` | `GfxAntiGrav` (`CellGraphics2`+1440) | 144 | slots 62-65, cell `$0A` | `DrawCell` (`stage1/hiscore`) | - |
| `$A450` | `GfxFallingEarth` (`CellGraphics2`+1584) | 144 | slots 66-69: red sparks on black, the earth of caves 13, 17, 22, 24, 26 (it falls; EarthAnim `$9DFC` steps the frames) | `DrawCell` (`stage1/rzx13`) | - |
| `$A4E0` | `GfxJellyBean` (`CellGraphics2`+1728) | 144 | slots 70-73, cell 8 | `DrawCell` | - |
| `$A570` | `GfxBurst` (`CellGraphics2`+1872) | 144 | slots 74-77, cells `$10-$14` | `DrawCell` (`stage1/rzx02`) | - |
| `$ED28` | `ExtraGraphics` | 36 of 180 | Five more cell graphics (36 bytes each) | `DrawCell` (`stage1/hiscore`) | - |
| `$ED4C` | `GfxExtraWall2` (`ExtraGraphics`+36) | 36 | - | `DrawCell` (`stage2/rzx04/cap`) | - |
| `$ED70` | `GfxExtraWall3` (`ExtraGraphics`+72) | 36 | - | `DrawCell` (`stage1/rzx18`) | - |
| `$ED94` | `GfxExtraWall4` (`ExtraGraphics`+108) | 36 | - | `DrawCell` (`stage1/rzx07`) | - |
| `$EDB8` | `GfxExtraWall5` (`ExtraGraphics`+144) | 36 | - | `DrawCell` (`stage1/hiscore`) | - |
| `$EDDC` | `ExtraGraphicsPad` | 36 | Zeros (36 bytes) | - | - |
| `$EE00` | `ExtraGraphic2` | 36 | One more cell graphic | `DrawCell` (`stage1/rzx24`) | - |
| `$EF00` | `ExtraGraphic3` | 36 | One more cell graphic | `DrawCell` (`stage1/rzx02`) | - |
| `$EF24` | `ExtraGraphic3Pad` | 476 | Leftover: 476 bytes | - | - |
| `$FAE0` | `EmptyFrames` | 144 | Four frames of the empty cell in the falling-earth caves: all zeros. EarthAnimStep `$FB70` points table word 0 (the empty cell) at frame AnimPhase each pass when the earth is GfxFallingEarth; every byte is 0, so the empty cell looks as BlankGraphic `$AA72` does (an animation hook with no picture). Witness: L1 6610 entries of EarthAnimStep (the rzx builds of caves 13, 17, 22, 24, 26). | `DrawCell` (`stage1/rzx13`) | - |
| `$FBA0` | `ExtraGraphic4` | 36 of 72 | Two more cell graphics | `DrawCell` (`stage1/rzx15`) | - |
| `$FBC4` | `GfxExtraWall9` (`ExtraGraphic4`+36) | 36 | - | `DrawCell` (`stage1/rzx16`) | - |
| `$FBE8` | `ExtraGraphic4Pad` | 24 | Zeros (24 bytes) | - | - |

## mapscreen

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$805E` | `DrawMapCellsOverlap` | 3 | LD C,`$1E` and the first byte of LD D,`$9A`: bytes that are two instruction streams. From `$8059` the code runs LD C,`$1E` (`$805E`) and LD D,`$9A` (`$8060`). The column loop's JR NZ,`$805F` enters at `$805F`, which runs LD E,`$16` and SBC A,`$D` (`$8061`): both results are overwritten at once (LD A,(HL), LD E,A), so the side entry is harmless. mkgame keeps the overlapped bytes as data (the code at `$8061` is the side entry's). | - | - |
| `$9A00` | `MapGlyphs` | 128 | The map's 8 x 8 glyph of each cell code 0-15 | `FindPassword`, `PrintGlyph` (`stage1/timer`) | - |
| `$9A80` | `MapAttrs` | 16 | The map's attribute of each cell code 0-15 | `FindPassword`, `MapCellAttr` (`stage1/timer`) | - |
| `$9A90` | `MapPatchLeftover` | 21 | Leftover: code never run (CALL `$8059`, CALL `$81CC`, RET; copy 7 bytes to `$8D78`, JP `$8B20`) | `FindPassword` | - |
| `$E8E8` | `MapTune` | 198 | The map screen's tune | `PlayTune` (`stage1/timer`) | - |
| `$E9B4` | `MapCellAttrOld` | 12 | Leftover: the old map attribute write (12 bytes) | - | - |
| `$E9C0` | `MapFrameGlyphs` | 64 | The map frame's 8 glyphs | `PrintGlyph` (`stage1/timer`) | - |
| `$EA8D` | `MapShown` | 1 | `$FF` once the map was shown in this cave | `MapKey` (`stage1/timer`) | `ClearMapFlag`, `MapKey` (`stage1/timer`) |

## main

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8210` | `ColourCyclePad` | 10 | Leftover: CALL `$8059`, CALL `$81CC`, CALL `$81E7`, RET (10 bytes), never run | - | - |
| `$86D3` | `TimeOutPad` | 11 | Leftover: 11 bytes, never run | - | - |
| `$872B` | `TimeBonusPad` | 2 | Leftover: 2 bytes, never run | - | - |
| `$AB6A` | `WinTexts` | 26 of 196 | The win screen's texts | `PrintText` (`stage1/rzx32`) | - |
| `$AB84` | `WinText2` (`WinTexts`+26) | 31 | - | `PrintText` (`stage1/rzx32`) | - |
| `$ABA3` | `WinText3` (`WinTexts`+57) | 8 | - | `PrintText` (`stage1/rzx32`) | - |
| `$ABAB` | `WinText4` (`WinTexts`+65) | 32 | - | `PrintText` (`stage1/rzx32`) | - |
| `$ABCB` | `WinText5` (`WinTexts`+97) | 28 | - | `PrintText` (`stage1/rzx32`) | - |
| `$ABE7` | `WinText6` (`WinTexts`+125) | 32 | - | `PrintText` (`stage1/rzx32`) | - |
| `$AC07` | `WinText7` (`WinTexts`+157) | 30 | - | `PrintText` (`stage1/rzx32`) | - |
| `$AC25` | `WinText8` (`WinTexts`+187) | 9 | - | `PrintText` (`stage1/rzx32`) | - |
| `$FD00` | `PasswordBuffer` | 20 | The typed password (20 characters) | `EnterPassword`, `FindPassword` | `EnterPassword` |
| `$FD14` | `HiScoreTable` | 75 | The high-score table: 5 records of 6 digits and a 9-character name | `HiScoreCompare` (`stage1/hiscore`), `HiScoreInsert` (`stage1/hiscore`), `PrintDigits` (`stage1/hiscore`), `PrintText` (`stage1/hiscore`) | `EnterName` (`stage1/hiscore`), `HiScoreInsert` (`stage1/hiscore`) |
| `$FD5F` | `NameBuffer` | 9 | The name buffer (9 characters) | `PrintText` (`stage1/hiscore`) | - |
| `$FD68` | `VarsPad` | 8 | Zeros (8 bytes) | - | - |
| `$FD70` | `ViewOrigin` | 2 | The window's first cell index | `AnimateCells`, `DeathView`, `TeleportDown` (`stage1/rzx05`), `TeleportLeft` (`stage1/rzx07`), `TeleportRight` (`stage2/rzx04/cap`) +1 | `WindowOrigin` |
| `$FD72` | `AnimPhase` | 1 | The animation phase 0-3 | `AnimateCells`, `AnimateTable`, `EarthAnim` (`stage1/rzx13`), `EarthAnimStep` (`stage1/rzx13`), `TeleportFlashIn` (`stage2/rzx04/cap`) +1 | `AnimateCells`, `CaveStartState`, `TeleportFlashIn` (`stage2/rzx04/cap`), `TeleportFlashOut` (`stage2/rzx04/cap`) |
| `$FD73` | `ForceFieldPhase` | 1 | The force field's animation phase 0-7 | `AnimateTable` | `AnimateTable` |
| `$FD74` | `TeleporterPhase` | 1 | The teleporter's animation phase 0-11 | `AnimateTable` | `AnimateTable` |
| `$FD75` | `VarsPad2` | 5 | Zeros (5 bytes) | - | - |
| `$FD7A` | `ClearStart` | 1 | The first byte ClearVars clears | `ClearVars` | `ClearVars` |
| `$FD7B` | `VarsFD7B` | 1 | Unused | `ClearVars` | `ClearVars` |
| `$FD7C` | `TimerSub` | 1 | The timer's sub-counter (+`$40` a pass) | `ClearVars`, `TimerStep` | `ClearVars`, `TimerStep` |
| `$FD7D` | `CaveOver` | 1 | `$FF`: out of time or quit | `ClearVars`, `PlayCave`, `ForceField` (`stage1/rzx22`) | `ClearVars`, `PlayCave`, `QuitKey`, `StartGameEntry`, `CaveStart` (`stage1/hiscore`) +1 |
| `$FD7E` | `CaveDigits` | 2 | The cave number as 2 digits | `ClearVars`, `PrintDigits`, `IncDigits` (`stage1/rzx01`) | `ClearVars`, `Password`, `StartGame`, `IncDigits` (`stage1/rzx01`), `WinGame` (code) |
| `$FD80` | `KeyMoved` | 1 | `$FF` when a key moved the player this pass | `ClearVars`, `PlayerStep` | `ClearMoveFlags`, `ClearVars`, `PlayCave`, `TryDown`, `TryLeft` +2 |
| `$FD81` | `VarsFD81` | 1 | Unused | `ClearVars` | `ClearVars` |
| `$FD82` | `GemDigits` | 2 | The gems taken as 2 digits | `ClearVars`, `IncDigits`, `PrintDigits` | `ClearVars`, `IncDigits`, `ResetCave` |
| `$FD84` | `CaveDone` | 1 | `$FF` when the player entered the open exit | `ClearVars`, `PlayCave`, `StartGameEntry`, `CaveStart` (`stage1/hiscore`), `NextCave` (`stage1/rzx02`) | `ClearVars`, `ResetCave`, `StartGameEntry`, `CaveStart` (`stage1/hiscore`), `TryDown` (`stage1/rzx05`) +3 |
| `$FD85` | `ExitOpen` | 1 | `$FF` when enough gems are taken | `ClearVars`, `CollectGem`, `ExitFlash`, `TryDown` (`stage1/rzx05`), `TryLeft` (`stage2/rzx04/cap`) +2 | `ClearVars`, `ResetCave`, `CountGem` (`stage1/rzx01`) |
| `$FD86` | `PlayerFacing` | 1 | The player's cell code: 3 right, 4 left | `ClearVars`, `PutPlayer` | `ClearVars`, `FaceLeft`, `TryLeft`, `TryRight` |
| `$FD87` | `Continuation` | 2 | The continuation address of a special cell | `ClearVars`, `Continue` | `ClearVars`, `DownSpecial`, `RightSpecial`, `CollectAntiGrav` (`stage1/rzx05`), `CollectDown` (`stage1/rzx22`) +5 |
| `$FD89` | `SavedCell` | 2 | The saved cell address | `ClearVars`, `CollectDownClear` (`stage1/rzx22`), `CollectLeftClear` (`stage1/rzx24`), `CollectRightClear` (`stage1/rzx24`), `CollectUpClear` (`stage1/rzx24`) | `ClearVars`, `CollectDown` (`stage1/rzx22`), `CollectLeft` (`stage1/rzx24`), `CollectRight` (`stage1/rzx24`), `CollectUp` (`stage1/rzx24`) |
| `$FD8B` | `AntiGravDigits` | 2 | The anti-gravity steps as 2 digits | `ClearVars`, `AntiGravPass` (`stage1/rzx03`), `PrintDigits` (`stage1/rzx03`) | `ClearVars`, `ResetAntiGravState`, `AntiGravPass` (`stage1/rzx03`), `AntiGravStartScan` (`stage1/rzx03`) |
| `$FD8D` | `AntiGravSteps` | 1 | The anti-gravity steps left | `AntiGravPass`, `ClearVars` | `ClearVars`, `ResetAntiGravState`, `AntiGravPass` (`stage1/rzx03`), `AntiGravStartScan` (`stage1/rzx03`) |
| `$FD8E` | `ColourPhase` | 1 | The colour cycle's phase | `ClearVars`, `ColourCycle` | `ClearVars`, `ColourCycle`, `ResetGame` |
| `$FD8F` | `ColourCycleInk` | 1 | The cycling ink `$43-$46` | `ClearVars`, `ColourCycle`, `DrawPass`, `ExitFlash` (`stage1/rzx01`) | `ClearScreenCave`, `ClearVars`, `ColourCycle` |
| `$FD90` | `Unused99` | 1 | Set to 99, never read | `ClearVars` | `ClearVars`, `ResetGame` |
| `$FD91` | `CaveNumber` | 1 | The cave 1-32 | `CaveIntro`, `ClearVars`, `PlayCaveTune`, `UnpackCave`, `NextCave` (`stage1/rzx02`) +1 | `ClearVars`, `Password`, `ResetGame`, `NextCave` (`stage1/rzx02`), `StartGameEntry` (`stage1/rzx01`) |
| `$FD92` | `GemCount` | 1 | The gems taken | `ClearVars`, `CountGem` | `ClearVars`, `CountGem`, `ResetCave` |
| `$FD93` | `Lives` | 1 | The lives | `ClearVars`, `PrintDigits`, `StartGameEntry`, `CaveStart` (`stage1/hiscore`), `NextCave` (`stage1/timer`) +1 | `ClearVars`, `ResetGame`, `StartGame`, `StartGameEntry`, `CaveStart` (`stage1/hiscore`) +2 |
| `$FD94` | `ScoreDigits` | 6 | The score as 6 digits | `ClearVars`, `IncDigits`, `PrintDigits`, `StartGame`, `HiScoreCompare` (`stage1/hiscore`) +1 | `ClearVars`, `IncDigits`, `StartGame` |
| `$FD9A` | `CaveParams` | 1 | The cave's 14 parameter bytes, field 1: GemsNeeded | `ClearVars`, `CountGem` | `ClearVars`, `UnpackCave` |
| `$FD9B` | `GemValue` | 1 | The points a gem | `AddGemValue`, `ClearVars` | `ClearVars`, `UnpackCave` |
| `$FD9C` | `PlayerIndex` | 2 | The player's cell index (the start from the cave) | `ClearVars`, `MoveDown`, `MoveRight`, `PlayerStep`, `PutPlayer` +14 | `ClearVars`, `MoveDown`, `MoveRight`, `TryLeft`, `UnpackCave` +9 |
| `$FD9E` | `GemsNeededDigits` | 2 | The gems needed as 2 digits | `ClearVars`, `PrintDigits` | `ClearVars`, `UnpackCave` |
| `$FDA0` | `EarthGraphic` | 2 | The earth graphic's address | `CaveSetup`, `ClearVars` | `ClearVars`, `UnpackCave` |
| `$FDA2` | `WallGraphic` | 2 | The wall graphic's address | `CaveSetup`, `ClearVars` | `ClearVars`, `UnpackCave` |
| `$FDA4` | `DoorColour` | 1 | The exit door's colour | `CaveSetup`, `ClearVars` | `ClearVars`, `UnpackCave` |
| `$FDA5` | `BoulderColour` | 1 | The boulder's colour | `CaveSetup`, `ClearVars` | `ClearVars`, `UnpackCave` |
| `$FDA6` | `Wall1Colour` | 1 | The colour of GfxWall1 `$9CB8` | `CaveSetup`, `ClearVars` | `ClearVars`, `UnpackCave` |
| `$FDA7` | `EarthColour` | 1 | The colour of GfxEarth `$9B50` | `CaveSetup`, `ClearVars` | `ClearVars`, `UnpackCave` |
| `$FDA8` | `CaveGrid` | 600 | The cave: 20 rows of 30 cells | `AnimateCellCodes`, `BlockWall`, `BoulderLandCheck`, `BubbleDown`, `ClearVacated` +38 | `BubbleDown`, `ClearVacated`, `ClearVars`, `MoveDown`, `MoveObject` +36 |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8671` | `FillTimeBarPad` | 22 | Leftover: 22 bytes, never run | - | - |
| `$A8F2` | `AddPointsPad` | 14 | Zeros (14 bytes) | - | - |
| `$A9FB` | `AntiGravStartPad` | 5 | Leftover: 5 bytes, never run | - | - |
| `$BB00` | `HudLabels` | 5 of 22 | "LEVEL", "LIVES LEFT:", "SCORE:" | `PrintText` | - |
| `$BB05` | `LivesLeftText` (`HudLabels`+5) | 11 | - | `PrintText` | - |
| `$BB10` | `ScoreText` (`HudLabels`+16) | 6 | - | `PrintText` | - |
| `$BB16` | `HudLabelsPad` | 106 | Zeros (106 bytes) | - | - |
| `$BC92` | `BarAttrs` | 64 | The time bar's attributes (2 lines of 32) | `BarColours` | - |
| `$BCD2` | `BarAttrsPad` | 14 | Zeros (14 bytes) | - | - |
| `$BCE0` | `HudLine` | 32 | The bottom line's text | `PrintText` | - |
| `$BD00` | `Font` | 128 of 768 | The font: characters `$20-$7F`, 8 bytes each (`$68-$7F` unused but `$73`, the SYMBOL SHIFT name) | `PrintGlyph` | - |
| `$BD80` | `DigitGlyphs` (`Font`+128) | 392 | the digits 0-9 (codes `$30-$39`), PrintDigits `$832A` | `PrintGlyph` | - |
| `$BF08` | `IconGlyphs` (`Font`+520) | 16 | the HUD icons a-e (codes `$61-$65`) | `PrintGlyph` | - |
| `$BF18` | `AntiGravIcon` (`Font`+536) | 8 | c: the anti-gravity arrow | `PrintGlyph` (`stage1/hiscore`) | - |
| `$BF20` | `AntiGravIconOff` (`Font`+544) | 32 | d: drawn when anti-gravity runs out | `PrintGlyph` | - |
| `$BF40` | `FontUnused` (`Font`+576) | 192 | codes `$68-$7F`: printed only as `$73`, the SYMBOL SHIFT key name (s) of the redefine screen and the key prompt; the rest never printed | - | - |

## player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$879D` | `FireLeftPad` | 2 | Leftover: 2 bytes, never run | - | - |
| `$91B6` | `ForceFieldPad` | 3 | Leftover: JP `$84E6`, never run | - | - |
| `$92B4` | `TeleportUpPad` | 32 | Leftover: two BEEPER calls (32 bytes), never run | - | - |
| `$93C2` | `BubbleScorePad` | 5 | Leftover: 5 bytes, never run | - | - |
| `$96D5` | `CollectPad` | 43 | Leftover: 43 bytes, never run | - | - |
| `$E82E` | `BoulderPushed` | 1 | `$FF` when a boulder was pushed this pass (the thud) | `PassSound` | `ClearMoveFlags`, `PlayerStep`, `PushBoulder` (`stage1/rzx01`) |
| `$E857` | `DugEarth` | 1 | `$FF` when the player dug earth this pass | `DigNoiseIfDug` | `BlockWall`, `ClearStepFlags` |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8B58` | `MenuKeysPad` | 13 | Leftover: 13 bytes, never run | - | - |
| `$8B75` | `ResetMachinePad` | 3 | Leftover: 3 bytes, never run | - | - |
| `$AB00` | `MenuTexts` | 18 of 106 | The menu's lines | `PrintText` | - |
| `$AB12` | `MenuRedefineText` (`MenuTexts`+18) | 21 | "2 ..... REDEFINE KEYS" | `PrintText` | - |
| `$AB27` | `MenuDemoText` (`MenuTexts`+39) | 17 | "3 ..... DEMO MODE": the 1988 line, no longer printed (the 1990 version prints ControlTexts `$EC95` instead; the call is NOPs at `$8A55`) | `PrintText` | - |
| `$AB38` | `MenuQuitText` (`MenuTexts`+56) | 17 | "5 ..... QUIT GAME" | `PrintText` | - |
| `$AB49` | `MenuCopyrightText` (`MenuTexts`+73) | 33 | "(C) 1990 MICHAEL BATTY", 33 characters; `$AB69` is a spare space | `PrintText` | - |
| `$AC2E` | `Credits` | 49 | Leftover: the 1988 credit line, never printed | - | - |
| `$B300` | `LogoPixels` | 2048 | The title logo's pixels: 2048 bytes laid out as the screen's top third | `WipeInLogo` | - |
| `$FC00` | `LogoAttrs` | 256 | The logo's attributes (8 rows of 32) | `ShowLogo` | - |

## password

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8F09` | `PasswordRejectedOld` | 32 | Leftover: the old failure flash (32 bytes), never run | - | - |
| `$9700` | `CaveNames` | 640 | The 32 cave names of 20 characters: the passwords. Read by CaveIntro `$92D4` (the name of the cave) and FindPassword `$8E91`. | `CaveIntro`, `FindPassword`, `PrintText` | - |
| `$99C0` | `CaveNamesPad` | 64 | Zeros after the names (64 bytes): FindPassword's 50 records run on over them | `FindPassword` | - |
| `$9ACC` | `CaveNamesPad2` | 28 | Zeros (28 bytes), the end of FindPassword's 50 records | `FindPassword` | - |
| `$9AE8` | `EnterPasswordText` | 32 | "ENTER PASSWORD (ENTER=LEVEL ONE)" | `PrintText` | - |

## keys

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A900` | `KeyTable` | 120 | 40 keys: half row, bit mask, character | `EnterPassword`, `PrintText`, `RedefineKeys`, `WaitKey`, `EnterName` (`stage1/hiscore`) | - |
| `$A978` | `KeyPrompts` | 19 of 95 | The five prompts of RedefineKeys, 19 characters each | `PrintText` | - |
| `$A98B` | `PromptRight` (`KeyPrompts`+19) | 19 | - | `PrintText` | - |
| `$A99E` | `PromptUp` (`KeyPrompts`+38) | 19 | - | `PrintText` | - |
| `$A9B1` | `PromptDown` (`KeyPrompts`+57) | 19 | - | `PrintText` | - |
| `$A9C4` | `PromptFire` (`KeyPrompts`+76) | 19 | - | `PrintText` | - |
| `$EAC3` | `MapCellAttrPad` | 1 | Leftover: one byte (RET) | - | - |
| `$EAC4` | `KempstonCode` | 81 | The joystick code fragments, 9 bytes for each key site | `JoystickControl` | - |
| `$EB15` | `KeyboardCode` | 81 | The saved keyboard code of each key site | `KeyboardControl` | `SaveKeyboardCode` |
| `$EC95` | `ControlTexts` | 24 of 48 | "3 ..... KEYBOARD CONTROL", "4 ..... JOYSTICK CONTROL" | `PrintText` | - |
| `$ECAD` | `JoystickText` (`ControlTexts`+24) | 24 | - | `PrintText` | - |
| `$ED0C` | `ChooseControlPad` | 28 | Leftover: 28 bytes | - | - |

## cavedata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C000` | `CaveData` | 10048 | The 32 caves, 314 bytes each | `UnpackCave` | - |
