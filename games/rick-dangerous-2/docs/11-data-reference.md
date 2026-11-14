# 11. Data reference

Every data entry of the game image `$7080`-`$A7FF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, `work/stage1/load-l2`, `work/stage1/load-l3`, `work/stage1/load-l4`, `work/stage1/load-l5`, `work/stage1/controls-kempston`, `work/stage1/rec/rzx-l5-full`, `work/stage1/rec/rzx-l5-22000-poke`, `work/stage1/rec/rzx-l5-23000`, `work/docs/rec/fatguy-hits`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7080` | `Glyphs` | 80 of 320 | The 40 glyphs of the HUD and the texts, 8 bytes each: 0-9, bolt, detonator, life, A-Z, blank. Glyph n at `$7080` + 8n: 0-9 the digits (`$7080-$70CF`), 10 the ray gun's bolt (`$70D0`, DrawAmmo `$79D1`), 11 a detonator (`$70D8`, DrawDetonators `$79DF`), 12 Rick's head (`$70E0`, DrawLives `$79C3`), 13-38 the letters A-Z (`$70E8-$71B7`), 39 a blank (`$71B8`). Read by DrawGlyph `$7A2C` (the HUD and the texts: `$7080-$70EF`, `$7100-$719F` in the recordings) and, as cell graphics, by DrawChangedCells `$76D4` and ComposeCell `$7755` when the text printer `$88B1` has switched them to the font (`$7080-$71BF` read by both). | `ComposeCell`, `ComposeLetter`, `DrawChangedCells`, `DrawGlyph`, `DrawChangedNext` (`stage2/rec/end-congrats`) | - |
| `$70D0` | `GlyphBolt` (`Glyphs`+80) | 8 | 10: a ray-gun bolt (ammunition) | `ComposeCell`, `DrawChangedCells`, `DrawGlyph` | - |
| `$70D8` | `GlyphDetonator` (`Glyphs`+88) | 8 | 11: a detonator | `ComposeCell`, `DrawChangedCells`, `DrawGlyph` | - |
| `$70E0` | `GlyphLife` (`Glyphs`+96) | 8 | 12: Rick's head (a life) | `ComposeCell`, `DrawChangedCells`, `DrawGlyph` | - |
| `$70E8` | `GlyphLetters` (`Glyphs`+104) | 208 | 13-38: A-Z | `ComposeCell`, `ComposeLetter`, `DrawChangedCells`, `DrawGlyph`, `DrawChangedNext` (`stage2/rec/end-congrats`) | - |
| `$71B8` | `GlyphBlank` (`Glyphs`+312) | 8 | 39: blank | `ComposeCell`, `DrawChangedCells`, `DrawChangedNext` (`stage2/rec/end-congrats`) | - |
| `$7A4B` | `BlankGlyph` | 8 | An empty glyph: the HUD's unused icon places | `DrawGlyph` | - |

## controls

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7252` | `ControlMethod` | 1 | The control method: 0 keyboard, 1 Kempston, 2 cursor, 3 Sinclair. Written by the control menu (`$80B5`, `$8127`), read by ReadControls `$7254` / `$725A`. controls-keyboard, -kempston, -cursor and -sinclair each play with one value. | `ControlMenu`, `ControlMenuLoop`, `ReadControls` | `ControlMenu`, `ControlMenuLoop` |
| `$7253` | `Controls` | 1 | The controls read in the last interrupt, active low: bit 0 right, 1 left, 2 down, 3 up, 4 fire. Written by ReadControls `$7254` (set to `$FF`, then a bit cleared per control held); read by TestFireKeys `$7229` and Rick's movement and weapons (`$945E`, `$95ED`, `$9663`, `$96B4`, `$985F`, `$988F`, `$9AB7`, `$9B27`). | `DropDetonator`, `ReadControls`, `ReadKempston`, `RickCellCollision`, `RickWalk` +8 | `ReadControls`, `ReadKempston` |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$77B0` | `SpareCount` | 1 | The next spare cell's number (from 2): ComposeCell takes one per cell under a sprite. Read by ComposeSprite `$7329` and ComposeCell `$7755` (which increments it), `$8321`; set by `$80B5`, `$8127`, `$81E6` and the object drawer `$85FA` at the start of each pass. | `ComposeCell`, `ComposeLetter`, `ComposeSprite`, `ComposeCellSkip` (`stage1/rec/rzx-l1-14000-poke`), `ComposeCellStack` (`stage1/rec/rzx-l1-14000-poke`) | `ComposeCell`, `ControlMenu`, `ControlMenuLoop`, `DrawSprites`, `MoveLetters` +2 |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7A60` | `FrameCounter` | 1 | Interrupts since the last WaitFrames: incremented by the IM 2 handler `$FEFE`, cleared by WaitFrames | `WaitFrames` | `WaitFrames` |
| `$7A76` | `Machine48K` | 1 | `$FF` on a 48K (no RAM 1: no music, beeper effects), 0 on a 128K. Set by the entry code `$7B8F`; read by CallRam1 `$7A77`, PlayEffect `$7A97`, the level start (`$7CAD`, `$7CDB`, `$7CDE`) and the main loop `$7D80` (CALL NZ the beeper step). 0 in every recording (all 128K). | `CallRam1`, `LevelTune`, `MainLoop`, `PlayEffect`, `ResetGame` +3 | `Entry48K` (code) |
| `$7C39` | `Im2HandlerSource` | 35 | The IM 2 handler as stored here; it runs at `$FEFE` (35 bytes). SetupIm2 copies these 35 bytes to `$FEFE-$FF20` (LD HL,`$7C39` / LD DE,`$FEFE` / LD BC,35 / LDIR); the code runs only there (in c1 4706 times, the IM 2 vector of every interrupt). DI; AF, BC, DE, HL, IX, IY pushed; the frame counter `$7A60` + 1; CALL `$81D4` (CountTicks); CALL `$7254` (the controls into `$7253`, the method in `$7252`); three NOPs, which CopyMusic turns into CALL `$7AB6` on a 128K (the music player, through the RAM 1 call `$7A77`); the registers popped; EI; RET. The handler lasts until its EI, so an interrupt that comes while code runs with interrupts off (the blitters, the map builder, the RAM 1 calls, the tape) is lost (WALKTHROUGH 1). After the copy the bytes here are part of the object table A (from `$7B8F`) and of the falling letters' records. | `ClearObjectTables`, `ComposeLetter`, `ComposeSprite`, `DrawSprites`, `DropText` +26 | `BuildLetters`, `ClearObjectTables`, `EnemyFalling`, `EnemyHitsAndSprite`, `EnemyPatrol` +11 |
| `$7C5C` | `EntryDebris` | 32 of 33 | Bytes of an earlier build after the handler (not executed in any recording). Not read as code by anything: they look like the tail of the handler of an earlier build, eight bytes higher (CALL `$81DC`, CALL `$725C`, the NOPs, the pops, EI, RET) and the start of an earlier NewGame (CALL `$80B1` where this build has CALL `$80B5` at `$7C7D`). The space belongs to the object table B (`$7C20`, four 23-byte records); ClearObjectTables writes its end mark `$FF` at `$7C7C`. | `ClearObjectTables`, `DrawSprites`, `EnemyHitsAndSprite`, `EnemyVertical`, `EnemyWalk` +22 | `ClearObjectTables`, `EnemyVertical`, `SpawnFromMap`, `BuildLetters` (`stage2/rec/end-congrats`), `EnemyChaser` (`stage1/rec/rzx-l4-02000-poke`) +11 |
| `$7C7C` | `ObjectTableBEnd` (`EntryDebris`+32) | 1 | the end mark of the object table B (`$FF` after ClearObjectTables) | `DrawSprites`, `FreeAllObjects`, `ShiftObjects`, `UpdateObjects`, `UpdateTrap` +3 | `ClearObjectTables` |
| `$81CE` | `RandomValue` | 2 | The last random word (Random) | `Random` | `Random` |
| `$81D0` | `Ticks` | 4 | The interrupts counted, 32 bits: the low word, then the high word. Counted by CountTicks every interrupt, read by Random. | `CountTicks`, `Random` | `CountTicks` |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7AF2` | `BeeperEffectTable` | 22 | The eleven beeper effects' addresses, by effect number (SelectBeeperEffect) | - | - |
| `$7B08` | `BeeperEffects` | 2 of 94 | The beeper effects: one note a pass, each byte the half period in loop turns, `$FF` ends. Played by PlayBeeperStep `$7B66` on a 48K. A lower byte is a higher note; every note lasts `$600` loop turns (about 0.7 frame). | - | - |
| `$7B0A` | `BeeperEffect1` (`BeeperEffects`+2) | 3 | 1: two notes | - | - |
| `$7B0D` | `BeeperEffect2` (`BeeperEffects`+5) | 2 | 2: one note | - | - |
| `$7B0F` | `BeeperEffect3` (`BeeperEffects`+7) | 6 | 3 | - | - |
| `$7B15` | `BeeperEffect4` (`BeeperEffects`+13) | 7 | 4: falling period, a rising sweep | - | - |
| `$7B1C` | `BeeperEffect5` (`BeeperEffects`+20) | 13 | 5: an alternating trill | - | - |
| `$7B29` | `BeeperEffect6` (`BeeperEffects`+33) | 17 | 6: a warble | - | - |
| `$7B3A` | `BeeperEffect7` (`BeeperEffects`+50) | 6 | 7 | - | - |
| `$7B40` | `BeeperEffect8` (`BeeperEffects`+56) | 6 | 8: a rising period, 1-5 | - | - |
| `$7B46` | `BeeperEffect9` (`BeeperEffects`+62) | 13 | 9 | - | - |
| `$7B53` | `BeeperEffect10` (`BeeperEffects`+75) | 19 | 10: a long falling sweep | - | - |
| `$7B8E` | `BeeperStepRet` | 1 | A RET after PlayBeeperStep's loop, which ends only by its RET Z: never reached. One byte `$C9` between PlayBeeperStep's JP BeeperHigh and the entry code at `$7B8F`: no instruction jumps to it, no recording reads or runs it (an older routine's end). | - | - |

## mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7C8F` | `LevelStarts` | 30 | Rick's start in each level: section, row, x, y, a flag (6 bytes a level). LevelSetup takes the record of Level (`$7EF1`): IX = `$7C8F` + 6 x (level - 1). +0 the start section (A to the section setup `$8A6D`), +1 the view's top row in it (`$88CF`), +2 Rick's x (E: `$9BAC`, `$9B8C`), +3/+4 Rick's y, a word (HL: `$9BAD`, `$9B8D`), +5 a byte for `$9BB1` (Rick's record +6: bit 7 the mirror; 0 in every level). Level 3 starts in section 1 with the view at row `$90`, level 5 at row `$60`, the others in section 0 at row 0; y is `$CB` in levels 1, 2, 4 and `$AB` in 3 and 5. Evidence: read by LevelSetup in every level start (reads `$7C8F-$7CAC` over the builds). | `LevelTune`, `ResetGame`, `DecryptLevel` (`stage1/rec/rzx-l2-00000-poke`) | - |
| `$7EF1` | `Level` | 1 | The level to play, 1-5. Set by LevelMenu (the key pressed) and by MainLoopPause at a level's end (Level + 1, or 5). LevelStart compares it with LevelNumber (`$C20C`); LevelSetup indexes LevelStarts with it, ResetSectionObjects SectionCounts, Congratulations writes it into the text; read by `$95ED`, `$96B4`, `$988F`, `$9B07` too. 1 in the image. | `LevelTune`, `LoadLevel`, `ResetGame`, `ResetSectionObjects`, `Congratulations` (`stage2/rec/end-congrats`) +13 | `LevelMenu`, `LevelMenuWait` (`stage1/rec/rzx-l1-00000-poke`), `MainLoop` (`stage1/rec/rzx-l3-10000-poke`), `NextLevel` (code) |
| `$7EF2` | `LevelsDone` | 1 | The levels completed in this game. 0 at ResetGame; + 1 at each level's end (MainLoopPause `$7DAD`). Done with 3 (the fourth level of the game) it opens level 5 (Level5Open); 5 (all five in one game, so starting from level 1) is the Fat Guy's end, BonusTally. | `MainLoop` (`stage1/rec/rzx-l3-10000-poke`), `PassWork` (code) | `ResetGame`, `MainLoop` (`stage1/rec/rzx-l3-10000-poke`), `CountLevelDone` (code) |

## ending

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7EC8` | `GameOverText` | 11 | "GAME  OVER", `$FF` the end. Read by DropText (from `$7E8B`) and PrintText (from `$7E94`). The font holds the digits first: a character is drawn as glyph (code - `$34`), so letters are plain ASCII and a digit is stored 4 higher. | `BuildLetters`, `PrintText`, `PutTextCells` | - |
| `$87A0` | `CongratulationsText` | 45 of 157 | The other end's text: records of column, row, text. Records: +0 the column, +1 the row in pixels, the text, `$FF`; a `$FF` record ends the list. The digit at `$87CD` is written by Congratulations (Level + `$34`). Shown by ShowEndText. | `BuildLetters` (`stage2/rec/end-congrats`), `Congratulations` (`stage2/rec/end-congrats`), `PutTextCells` (`stage2/rec/end-congrats`) | `Congratulations` (`stage2/rec/end-congrats`) |
| `$87CD` | `CompletedLevelDigit` (`CongratulationsText`+45) | 112 | the level, + `$34` | `BuildLetters` (`stage2/rec/end-congrats`), `Congratulations` (`stage2/rec/end-congrats`), `PutTextCells` (`stage2/rec/end-congrats`) | `Congratulations` (`stage2/rec/end-congrats`) |
| `$883D` | `FatGuyEndText` | 116 | The Fat Guy's end text: records of column, row, text. "AND SO RICK SAVES THE DAY / BY DEFEATING THE FAT GUY AND / HIS FLEET OF ROBOT STARSHIPS / WHAT WILL RICK DO NEXT", in the same records as CongratulationsText. Shown by TallyLives through ShowEndText (rzx-l5-23000). | `BuildLetters`, `PutTextCells`, `TallyLives`, `ShowEndTextLoop` (`stage1/rec/rzx-l5-24000-poke`) | - |

## score

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7EF3` | `Points50` | 6 | 50 points (000050). Added by `$8C36` and `$9F6D`. | `AddScore` | - |
| `$7EF9` | `Points100` | 6 | 100 points (000100). No instruction in the image or the levels loads `$7EF9` (no byte pair F9 7E in the 64 K image), and no recording reads it: unused. | - | - |
| `$7EFF` | `Points500` | 6 | 500 points (000500). Added by `$A595`. | `AddScore` | - |
| `$7F05` | `Points5000` | 6 | 5000 points (005000): each bullet left at the Fat Guy's end. Added by BonusTally (`$86F1`) for each bullet left (not executed in any recording). | `AddScore` | - |
| `$7F0B` | `Points10000` | 6 | 10 000 points (010000): each detonator left at the Fat Guy's end. Added by BonusTally (`$8712`) for each detonator left (not executed in any recording). | - | - |
| `$7F11` | `Points100000` | 6 | 100 000 points (100000): the Fat Guy defeated, and each life left. Added once by BonusTally (`$86E0`) and once a life by TallyLives (rzx-l5-23000: 5 additions). | `AddScore` | - |
| `$7F17` | `TimeBonus` | 6 | A bonus that counts down: 002000 when set, collected by `$9CD6`. `$9C97` sets its digits +2..+4 to 2, 0, 0 (2000) when Rick takes a certain object (the code at `$9CAC`), `$9163` takes 1 off its digits +1..+4 every 25 passes while `$9BA9` is set, and `$9CCA` adds what is left to the score (AddScore, HL = `$7F17`). | `CountBonus`, `AddScore` (`stage1/rec/rzx-l2-08000-poke`) | `CountBonus`, `SpawnFromMap` |
| `$7F1D` | `Score` | 6 | The score: six decimal digits, the most significant first. Cleared by ResetGame, added to by AddScore, drawn by `$7A0C`. | `AddScore`, `DrawScore` | `AddScore`, `ResetGame` |
| `$8B3B` | `Lives` | 1 | Rick's lives. Set to 6 at a new game (`$7CC2`); a level start with fewer than 6 adds one (`$7CE6`; the bytes at `$7CEE`, INC A / LD (`$8B3B`),A: not executed in any recording); one off in LoseLife (`$8A30`, the POKE file's infinite lives); the main loop ends the game when Rick dies with 1 left (`$7E10`). Read by the HUD `$79C3` and the end tally `$8728`. | `DrawLives`, `LevelTune`, `LoseLife`, `MainLoop`, `ResetGame` +3 | `LoseLife`, `ResetGame`, `TallyLives`, `DecryptLevel` (`docs/rec/life-up`), `AddLife` (code) |
| `$8B3C` | `Ammunition` | 1 | The ray gun's bullets. 6 at every level start (`$7CF4`) and after a death (`$8A41`), 6 again from an ammunition pickup (`$A528`), also written by `$A2F7`; one off per shot (`$9593`, unless `$8066`). The HUD: `$79D1`. | `DrawAmmo`, `FireBullet`, `TallyBullets` (code) | `FireBullet`, `LevelTune`, `LoseLife`, `ResetGame`, `DecryptLevel` (`stage1/rec/rzx-l2-00000-poke`) +4 |
| `$8B3D` | `Detonators` | 1 | The detonators (bombs). 6 at every level start (`$7CF7`) and after a death (`$8A44`), 6 from a pickup (`$A528`), also written by `$A2F7`; one off per bomb (`$95ED`, `$96B4`, `$9B27`, unless `$8066`). The HUD: `$79DF`. | `DrawDetonators`, `DropDetonator`, `RickCellCollision`, `UpdateRick`, `TallyDetonators` (code) | `DropDetonator`, `LevelTune`, `LoseLife`, `ResetGame`, `RickCellCollision` +6 |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7FC7` | `LevelMenuText` | 13 of 158 | The level menu's texts (the digits stored 4 higher: "5" shows as 1). Each text ends with `$FF`. Read by DropText from LevelMenu; the level names are Rick Dangerous 2's five levels. | `BuildLetters`, `PutTextCells` | - |
| `$7FD4` | `StartLevelText` (`LevelMenuText`+13) | 13 | "START  LEVEL" | `BuildLetters`, `PutTextCells` | - |
| `$7FE1` | `Level1Name` (`LevelMenuText`+26) | 20 | "5  HYDE PARK LONDON": 1 | `BuildLetters`, `PutTextCells` | - |
| `$7FF5` | `Level2Name` (`LevelMenuText`+46) | 30 | "6  THE ICE CAVERNS OF FREEZIA": 2 | `PutTextCells` | - |
| `$8013` | `Level3Name` (`LevelMenuText`+76) | 29 | "7  THE FORESTS OF VEGETABLIA": 3 | `PutTextCells` | - |
| `$8030` | `Level4Name` (`LevelMenuText`+105) | 24 | "8  THE ATOMIC MUD MINES": 4 | `PutTextCells` | - |
| `$8048` | `Level5Name` (`LevelMenuText`+129) | 29 | "9  THE FAT GUYS HEADQUARTERS": 5, shown only when Level5Open | `PutTextCells` | - |
| `$8065` | `Level5Open` | 1 | `$FF`: level 5 is open in the level menu. Set to `$FF` by MainLoopPause (`$7DA6`) when the fourth level of a game is done; never cleared, so it stays open for the next games until a reset. Read by LevelMenu (the fifth line), ScanNumberKeys (the key 5), MainLoopPause (level 4 done: level 5 or the CONGRATULATIONS end) and CheatExitsKeys. 0 in the image. Evidence: rzx-l4-20000-poke runs `$7DA6` once; load-l5 sets it by POKE. | `LevelMenu`, `ScanNumberKeys`, `MainLoop` (`stage1/rec/rzx-l4-20000-poke`), `CheatExitsKeys` (code), `CountLevelDone` (code) | `MainLoop` (`stage1/rec/rzx-l4-20000-poke`), `PassWork` (code) |
| `$8066` | `CheatInfinite` | 1 | Not 0: lives, ammunition and detonators are not used up. Toggled by the chord C+S+3 in MainLoop (CheatInfiniteKeys); read by `$8A26` (a life lost), `$9593` (a bullet), `$9B27` (a detonator), `$95ED` and `$96B4`. 0 in the image; cheats sets it with the chord (frames 54, 56, 60: on, off, on). | `DropDetonator`, `FireBullet`, `LoseLife`, `RickCellCollision`, `UpdateRick` +2 | `MainLoop` (`stage2/rec/cheats`), `CheatInfiniteKeys` (code) |
| `$8067` | `CheatExits` | 1 | `$FF`: a section exit test passes (set by the chord SPACE+N+ENTER+J+Y with level 5 open). Set by CheatExitsKeys, read by `$8993` (bit 7, at `$89D9`); never cleared. 0 in the image; cheats sets it with the chord (frame 204), long-l4 by POKE. | `CheckSectionExit` (`stage1/rec/rzx-l2-20000-poke`) | `MainLoop` (`stage2/rec/cheats`), `CheatExitsKeys` (code) |
| `$8159` | `ControlMenuText` | 15 of 85 | The control menu's texts (the digits stored 4 higher) and the title. Each text ends with `$FF`. Read by DropText from ControlMenu. | `BuildLetters`, `PutTextCells` | - |
| `$8168` | `KeyboardText` (`ControlMenuText`+15) | 13 | "5   KEYBOARD": 1 | `BuildLetters`, `PutTextCells` | - |
| `$8175` | `KempstonText` (`ControlMenuText`+28) | 13 | "6   KEMPSTON": 2 | `BuildLetters`, `PutTextCells` | - |
| `$8182` | `CursorText` (`ControlMenuText`+41) | 11 | "7   CURSOR": 3 | `BuildLetters`, `PutTextCells` | - |
| `$818D` | `SinclairText` (`ControlMenuText`+52) | 15 | "8   SINCLAIR": 4 | `BuildLetters`, `PutTextCells` | - |
| `$819C` | `TitleText` (`ControlMenuText`+67) | 18 | "RICK DANGEROUS II", at row `$68` column 7 | `BuildLetters`, `PutTextCells` | - |
| `$81AE` | `MenuKeyHeld` | 1 | `$FF` while a menu key is held: ReadMenuKey takes a key once per press. Written by ReadMenuKey (0 when no key, `$FF` on a new key) and ControlMenu (`$FF` at the start). | `ReadMenuKey` | `ControlMenu`, `ReadMenuKey` |

## level

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8374` | `SectionCounts` | 5 | The number of sections of each level: 9, 13, 10, 13, 8. Read by ResetSectionObjects at SectionCounts - 1 + Level. | `ResetSectionObjects` | - |
| `$88CF` | `ViewTopRow` | 1 | The view's top row in the section (cells). Set by the section setup `$8A6D` (from LevelStarts +1 or the section entered) and by `$8A26`; moved by the scrolls `$7905` (up) and `$78A5` (down); read by the map builder `$88D4`, MainLoopPause's scroll tests, `$8993` and others. | `BuildView`, `CheckSectionExit`, `FindFirstMapEntry`, `LevelTune`, `ResetGame` +14 | `LoseLife`, `ScrollUp`, `SetupSection`, `ScrollDown` (`stage1/rec/rzx-l1-04000-poke`) |
| `$88D0` | `ViewMap` | 2 | The section's map: the maps' base + the section's offset. Set by `$8A6D` and `$8A26`, read by the map builder `$88D4`. | `BuildView` | `LoseLife`, `SetupSection` |
| `$88D2` | `ViewLastRow` | 1 | The last top row the view may scroll down to in the section. The section record's +3, set by `$8A6D` and `$8A26`; MainLoopPause scrolls down only while ViewTopRow is below it. | `ResetGame`, `DecryptLevel` (`stage1/rec/rzx-l4-00000-poke`), `LevelTune` (`stage2/rec/sec-l4-s11`), `MainLoop` (`stage1/rec/rzx-l1-04000-poke`), `ScrollDownTest` (code) | `LoseLife`, `SetupSection` |
| `$88D3` | `ExitDirection` | 1 | The exit Rick asks for in this pass: 0 none. Cleared at each pass (MainLoopPause), set by Rick's movement (`$945E`, `$95ED`, `$96B4`, `$988F`, `$9941`) and by `$8A26`; when set, MainLoopPause runs the exit test `$8993`, which compares it with the exits' kinds (AND `$0B`). | `CheckSectionExit`, `LevelTune`, `LoseLife`, `MainLoop`, `ResetGame` +3 | `LevelTune`, `LoseLife`, `MainLoop`, `ResetGame`, `RickCellCollision` +7 |
| `$8A24` | `LevelHookOn` | 2 | Nonzero: the level's own code (LevelHookA, LevelHookB) runs in place of the map entries. Set to 20 by an exit with bit 6 (`$89FC`; level 5 into the Fat Guy's section) and by a death while it is set (`$93E2`); cleared at a new game (`$7CBD`). While it is nonzero, SetupSection calls LevelHookA (`$C206`) in place of ScanMapObjects, ScanMapObjects returns at once, and `$865D` calls LevelHookB (`$C209`) in place of the object updates; `$91EB` and level 5's own code (`$F954`) read it too. The second byte `$8A25` is read by no code. | `KillRick`, `LoseLife`, `ScanMapObjects`, `SetupSection`, `UpdateDetonator` +1 | `KillRick`, `ResetGame`, `CheckSectionExit` (`stage1/rec/rzx-l5-20000-poke`), `CheckExitBit6` (code) |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$86DF` | `SectionBusy` | 1 | `$FF` while a section is set up: UpdateObjects leaves Rick alone. `$FF` and 0 written by the section setup (`$8AF1` area, `$8B01`); read by UpdateObjects. | `UpdateObjects` | `LoseLife`, `SetupSection` |
| `$8B3E` | `SectionEntries` | 2 | The section's map entry list (0: none). Set by SetupSection (`$8AD5`) from the section table's +6/+7; read by FindFirstMapEntry. | `FindFirstMapEntry` | `LoseLife`, `SetupSection` |
| `$8B40` | `ScanStart` | 2 | The first map entry at or below the view's top row (0: none). Set by FindFirstMapEntry after every BuildView; read by ScanMapObjects each pass. | `ScanMapObjects` | `FindFirstMapEntry` |
| `$8BC0` | `SpawnWholeView` | 1 | `$FF` while SetupSection spawns: every entry in the 40 rows, not only the edge rows. Set to `$FF` at `$8AEB` and 0 at `$8B02`; read by ScanMapObjects (`$8B78`). | `ScanMapObjects`, `ScanDeadEntry` (`stage1/rec/rzx-l3-04000-poke`), `ScanSpawnRule` (`stage1/rec/rzx-l2-22000-poke`) | `LoseLife`, `SetupSection` |
| `$9191` | `KindHandlers` | 30 | DispatchByKind's handlers: `$0000`, `$A2F7`, then NoHandler 13 times (kind 15 would read `$3AC9` past the end). Read only by DispatchByKind, which no recording ran. | - | - |
| `$9D59` | `EnemyAnimScripts` | 9 of 19 | Three animation scripts the enemy spawn stores and nothing reads. Frame numbers for SpriteFrameMap, each script closed by `$FF` and the address to loop to (the form AnimateTrap reads): frames `$2A`, `$2A`, `$2B`, `$2B`, `$2C`, `$2C`; `$2D`, `$2E`; `$2F`, `$30`. SpawnEnemy writes `$9D59` into every enemy's +`$0A`/+`$0B`, but the enemies' sprites come from EnemyWalkSprites (`$9ECE`): no recording reads these bytes (l1q: the loader's writes only). | - | - |
| `$9D62` | `EnemyAnimScript2` (`EnemyAnimScripts`+9) | 5 | frames `$2D`, `$2E`, loop | - | - |
| `$9D67` | `EnemyAnimScript3` (`EnemyAnimScripts`+14) | 5 | frames `$2F`, `$30`, loop | - | - |
| `$A7F0` | `BulletSpent` | 1 | `$FF`: the bullet hit a trigger box this pass. Written `$FF` by TestTriggerBoxes (`$A734`) and by the unexecuted pickup shot (`$A5E6`); `$865D` reads it after the bullet's move, clears it and switches the bullet off (`$9BB4` = 0). | `UpdateObjects` | `TestTriggerBoxes` (`stage1/rec/rzx-l2-18000-poke`), `UpdateObjects` (`stage1/rec/rzx-l2-18000-poke`), `UpdatePickup` (`docs/rec/box-shot`) |
| `$A7F1` | `ImageEndPad` | 15 | Zeros to the end of the game image (`$A7FF`); the level starts at `$A800`. No recording reads them (l1q: the loader's writes only). | - | - |

## levelload

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$843A` | `TapeTexts` | 23 of 48 | "START TAPE ON SIDE TWO", "STOP TAPE AND PRESS FIRE". Printed by LoadLevel with PrintText; `$FF` ends each. | `PrintText` | - |
| `$8451` | `StopTapeText` (`TapeTexts`+23) | 25 | "STOP TAPE AND PRESS FIRE" | `PrintText` | - |
| `$852E` | `LoaderFill` | 204 | 204 bytes of `$C9` (RET) up to `$85F9`. Not read or run by any recording. | - | - |

## enemies

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9F4C` | `EnemyMoveFlags` | 1 of 4 | The enemy movement flags of the current pass. +0 EnemyOnStep: `$FF` when EnemyVertical found a step (probe bit 6) under the enemy; +1 EnemyOnGround: `$FF` when the enemy stands (landed, or EnemyOnStep copied by EnemyWalk). Both cleared by UpdateEnemy, written by EnemyVertical, read by EnemyWalk. +2 EnemyAnimFast and +3 EnemyAnimSlow are read by EnemyHitsAndSprite and never written (always 0). | `EnemyHitsAndSprite`, `EnemyWalk` | `EnemyVertical`, `EnemyWalk`, `UpdateEnemy` |
| `$9F4D` | `EnemyOnGround` (`EnemyMoveFlags`+1) | 1 | - | `EnemyWalk` | `EnemyVertical`, `EnemyWalk`, `UpdateEnemy` |
| `$9F4E` | `EnemyAnimFast` (`EnemyMoveFlags`+2) | 1 | never written: the walk frames' step 4 stays off | `EnemyHitsAndSprite` | - |
| `$9F4F` | `EnemyAnimSlow` (`EnemyMoveFlags`+3) | 1 | never written: the walk frames' step 1 stays off | `EnemyHitsAndSprite` | - |
| `$9F50` | `EnemyWalkSprites` | 6 | The three walking sprites: Sprites 28, 29, 30 (`$D06D`, `$D0ED`, `$D16D`). Read by EnemyHitsAndSprite (`$9F10`); +6 x 128 for the second set (Sprites 34-36). | `EnemyHitsAndSprite` | - |

## rick

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8FF8` | `CeilingOverCrawl` | 1 | Non-zero while a solid cell lies over the crawling Rick's head. Written by TestCrawlBox (bit 1 of the cells in the box's top row); read by UpdateRick through RickCrouchCheck (`$97B4`) and RickInAir (`$986D`): Rick stays crawling while it is set. | `RickCellCollision`, `UpdateRick`, `RickInAir` (`stage1/rec/rzx-l4-14000-poke`), `RickLandOrFall` (`stage1/rec/rzx-l4-14000-poke`), `RickCrouchCheck` (code) | `TestCrawlBox` |
| `$915E` | `CollisionFlags` | 1 | The flags the last box test found: bit 0 special surface, 1 solid, 2 floor, 3 ladder, 4 ladder top, 5 deadly, 6 on an object. Written by TestBodyBox, TestCrawlBox and TestBoxObjects, by the detonator's test `$8E1C` and by `$8EA5` / `$A0A1` (bit 1); read by UpdateRick and its parts, UpdateRide, UpdateDetonator and the enemies (`$A025`, `$A06E`, `$A0A1`, `$A213`). | `EnemyChaser`, `EnemyPatrol`, `EnemyVertical`, `EnemyWalk`, `ProbeGround` +23 | `EnemyVertical`, `ProbeGround`, `TestBodyBox`, `TestBoxObjects`, `TestSolidObject` +4 |
| `$915F` | `PlatformTop` | 2 | The top y of the highest platform or block the last box test found (`$FFFF`: none). Written by TestBoxObjects; read by UpdateRick (`$9673`: Rick's y = PlatformTop - 21) and UpdateDetonator (`$9234`: y = PlatformTop - 16), and by `$A0A1`. | `EnemyVertical`, `TestBodyBox`, `TestBoxObjects`, `TestSolidObject`, `UpdateRick` +5 | `TestBodyBox`, `TestBoxObjects`, `TestSolidObject`, `ProbeGround` (`stage1/rec/rzx-l2-02000-poke`), `FeetLineX` (code) +1 |
| `$9161` | `PlatformDx` | 1 | The x motion of the platform found, carried to what stands on it (pixels a pass). Written by TestBoxObjects (the record's +`$16`); read by RickMoveX (`$9941`: added to the walk step), RickActionDone, UpdateDetonator and `$A213`. | `EnemyWalk`, `RickActionDone`, `RickCellCollision`, `RickShootUp`, `RickWalk` +8 | `TestBodyBox`, `TestBoxObjects`, `TestSolidObject`, `UpdateRick`, `ProbeGround` (`stage1/rec/rzx-l2-02000-poke`) +4 |
| `$9162` | `PlatformDy` | 1 | The y motion of the platform found (the record's +`$17`). Written by TestBoxObjects; read only by `$A213` (an enemy on a platform). | `EnemyWalk` | `TestBodyBox`, `TestBoxObjects`, `TestSolidObject`, `FeetLineX` (code) |
| `$945C` | `DeathDrift` | 1 | Rick's x step a pass while he falls dead: +2 or -2. Written by KillRick; read by DeathFall. | `DeathFall` | `KillRick`, `UpdateDetonator` |
| `$945D` | `RideMode` | 1 | Non-zero while Rick rides the vehicle (sprite 12): UpdateRick hands the pass to UpdateRide. Cleared by the section exits' test `$8993` and the level start (`$7CAD`, `$7CDB`, `$7CDE`); kept in RestartRide (`$8A6D`, `$8A26`). Set to `$FF` by the section exit test at `$89F2` (CheckExitRide) when the exit's flags have bit 5; cleared there at `$89CD` and `$89E9`. The exits with bit 5 lead into level 2 section 6, level 4 sections 4-5 and level 5 section 2 (and level 1 section 2's unreachable exit into section 0); UpdateRide ran in rzx-l2-20000/22000, rzx-l4-10000/12000 and rzx-l5-06000/08000-poke. | `LoseLife`, `SetupSection`, `UpdateRick` | `LevelTune`, `LoseLife`, `ResetGame`, `CheckSectionExit` (`stage1/rec/rzx-l1-00000-poke`), `DecryptLevel` (`stage1/rec/rzx-l2-00000-poke`) +2 |
| `$9AA9` | `WalkFrames` | 10 of 14 | The walk's sprites by RickStep / 4: 5, 4, 3, 2, 1; then the crawl's two: 6, 7. Read by PickRickSprite (RickWalkCycle): HL = WalkFrames (20 steps) or CrawlFrames (8 steps), the word (RickStep / 2) AND `$0E`. | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) | - |
| `$9AB3` | `CrawlFrames` (`WalkFrames`+10) | 4 | sprites 6 and 7 | `UpdateRick`, `PickRickSprite` (`stage1/rec/rzx-l1-06000-poke`), `RickCellCollision` (`stage1/rec/rzx-l2-18000-poke`), `RickWalk` (`stage1/rec/rzx-l2-24000-poke`) | - |
| `$9B8C` | `RestartPoint` | 1 of 9 | Rick's state at the section's entry, where a life restarts; +7 the section Rick is in. Written by the section setup `$8A6D` (Rick's x and y, his crawl, climb, ride and facing, the view's top row, the section); read back by the restart after a death (`$8A26`). | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B8D` | `RestartY` (`RestartPoint`+1) | 2 | 2 bytes | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B8F` | `RestartCrawl` (`RestartPoint`+3) | 1 | - | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B90` | `RestartClimb` (`RestartPoint`+4) | 1 | - | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B91` | `RestartRide` (`RestartPoint`+5) | 1 | - | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B92` | `RestartTopRow` (`RestartPoint`+6) | 1 | the view's top row in the section (`$88CF`) | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B93` | `RickSection` (`RestartPoint`+7) | 1 | the section Rick is in (0 to the level's count - 1) | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B94` | `RestartFacing` (`RestartPoint`+8) | 1 | - | `LoseLife` | `LoseLife`, `SetupSection` |
| `$9B95` | `RickDy` | 2 | Rick's vertical speed, 8.8 pixels a pass, down positive. Gravity +0.5 a pass up to 8.0 (UpdateRick), -6.0 a jump, -5.0 the death's jump, 1.0 standing, -2175/256 a launch. Written by UpdateRick and its parts, KillRick, DeathFall, UpdateRide, ClimbLadder (the climb step), `$80B5`, `$83CE`, `$8A26`; read by the same and `$83CE`. | `DeathFall`, `MoveMenuRick`, `RickCellCollision`, `UpdateRick`, `RickLandOrFall` (`stage1/rec/rzx-l4-14000-poke`) +2 | `ControlMenu`, `DeathFall`, `KillRick`, `LoseLife`, `MoveMenuRick` +9 |
| `$9B97` | `RickYFrac` | 1 | The fraction of RickY (the 24-bit y is RickY:RickYFrac) | `DeathFall`, `MoveMenuRick`, `UpdateRick`, `UpdateRide` (`stage1/rec/rzx-l2-20000-poke`) | `ControlMenu`, `DeathFall`, `MoveMenuRick`, `RickCellCollision`, `UpdateRick` +3 |
| `$9B98` | `RickCrawling` | 1 | `$FF` while Rick crawls (down held, or a ceiling over him). Read by the box test `$8D53` too (a lower box for the enemies' touch). | `LoseLife`, `PickRickSprite`, `RickCellCollision`, `RickWalk`, `SetupSection` +6 | `LevelTune`, `LoseLife`, `ResetGame`, `RickCellCollision`, `UpdateRick` +6 |
| `$9B99` | `RickClimbing` | 1 | `$FF` while Rick is on a ladder: UpdateRick hands the pass to ClimbLadder | `LoseLife`, `PickRickSprite`, `RickCellCollision`, `RickWalk`, `SetupSection` +3 | `LevelTune`, `LoseLife`, `ResetGame`, `RickCellCollision`, `UpdateRick` +7 |
| `$9B9A` | `RickStep` | 1 | The walk animation's step (0-19 walking, 0-7 crawling, `$FF` standing); DeathFall's frame counter | `DeathFall`, `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick` +1 | `DeathFall`, `PickRickSprite`, `RickCellCollision`, `RickShootUp`, `RickWalk` +2 |
| `$9B9B` | `DeathFallOver` | 1 | `$FF` when the dead Rick has fallen below the view. Written by DeathFall; read by the main loop (`$7D2D`) and the level start (`$7CAD`, `$7CDB`, `$7CDE`); cleared by `$8A26`, `$8A6D`. | `LevelTune`, `MainLoop`, `ResetGame`, `DecryptLevel` (`stage1/rec/rzx-l2-00000-poke`), `DeathTest` (code) | `DeathFall`, `LoseLife`, `SetupSection` |
| `$9B9C` | `RickDying` | 1 | `$FF` from KillRick until the restart. Read by UpdateRick, KillRick, the main loop and the enemies and traps (`$A2F7`, `$A43B`, `$A528`, `$A69F`, `$A6E7`: they leave a dying Rick alone). | `KillRick`, `LevelTune`, `MainLoop`, `ResetGame`, `TestTriggerBoxes` +7 | `KillRick`, `LoseLife`, `SetupSection`, `UpdateDetonator` |
| `$9B9D` | `RickOnGround` | 1 | `$FF` when the pass ended on a floor or a platform (cleared every pass) | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) | `RickCellCollision`, `UpdateRick`, `RickLandOrFall` (`stage1/rec/rzx-l4-14000-poke`) |
| `$9B9E` | `RickIceSlide` | 1 | `$FF` while Rick slides on level 2's ice with no key (sprite 0) | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) | `UpdateRick`, `RickWalk` (`stage1/rec/rzx-l2-04000-poke`) |
| `$9B9F` | `MudStep` | 1 | 1 on level 4's mud: the walk step and the animation step are 1 | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) | `UpdateRick`, `RickCellCollision` (`stage1/rec/rzx-l4-06000-poke`), `RickWalk` (`stage2/rec/long-l4`) |
| `$9BA0` | `IceStep` | 1 | 2 on level 2's ice: the animation steps 4 instead of 2 | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) | `UpdateRick`, `RickWalk` (`stage1/rec/rzx-l2-04000-poke`) |
| `$9BA1` | `ShootPose` | 1 | `$FF` on a pass with fire and up held (sprite 9) | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) | `RickCellCollision`, `RickShootUp`, `UpdateRick` |
| `$9BA2` | `DetonatorPose` | 1 | `$FF` on a pass with fire and down held (sprite 0 or 11) | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) | `DropDetonator`, `RickCellCollision`, `UpdateRick` |
| `$9BA3` | `PunchTimer` | 1 | Counts 10 passes down from a punch's start: the stick shows (sprite 10) while not 0. Read by `$8BF3`, `$A69F`, `$A6E7` (the punch against enemies and trigger boxes). | `PickRickSprite`, `RickCellCollision`, `TestEnemyHits`, `TestTriggerBoxes`, `UpdateRick` | `RickCellCollision`, `UpdateRick`, `RickLandOrFall` (`stage1/rec/rzx-l4-14000-poke`), `PunchStart` (code), `RickFireActions` (code) +1 |
| `$9BA4` | `PunchKeys` | 1 | The sideways keys of the punch in progress (1 left, 2 right, `$7253` AND 3); 0 none | `PickRickSprite`, `RickCellCollision`, `RickWalk`, `UpdateRick`, `RickMoveX` (`stage1/rec/rzx-l4-20000-poke`) +1 | `RickCellCollision`, `UpdateRick`, `RickLandOrFall` (`stage1/rec/rzx-l4-14000-poke`), `PunchStart` (code), `RickFireActions` (code) +1 |
| `$9BA5` | `PunchX` | 1 | The punch's x: Rick's x, or x + 24 facing right. Written by RickFireActions; read by `$8C6C`. | `PunchHits` | `RickCellCollision`, `UpdateRick`, `PunchRight` (code), `PunchStart` (code) |
| `$9BA6` | `PunchY` | 2 | The punch's y: Rick's y + 8. Written by RickFireActions; read by `$8C6C`. | `PunchHits` | `RickCellCollision`, `UpdateRick`, `PunchStoreY` (code) |
| `$9BA8` | `FireLatch` | 1 | `$FF` after a shot until fire is released (or held with no up) | `RickCellCollision`, `RickShootUp`, `UpdateRick`, `UpdateRide` (`stage1/rec/rzx-l2-20000-poke`) | `FireBullet`, `RickCellCollision`, `UpdateRick`, `UpdateRide` (`stage1/rec/rzx-l2-20000-poke`), `RickFireActions` (code) |
| `$9BA9` | `BonusRunning` | 1 | `$FF` while the countdown bonus runs (map kind `$78` starts it, `$7C` ends it, `$9C97`) | `SpawnFromMap`, `UpdateObjects` | `LoseLife`, `SetupSection`, `SpawnFromMap` |
| `$9BAA` | `BonusPrescaler` | 1 | CountBonus's count of 25 passes | `CountBonus` | `CountBonus`, `LoseLife`, `SetupSection`, `SpawnFromMap` |
| `$9BAB` | `RickRecord` | 1 of 9 | Rick: +0 state, +1 x, +2/+3 y, +4/+5 sprite, +6 bit 7 mirrored, +7 width 16, +8 height 21. +0 is 1 in the image and 0 after every section setup (`$8A6D`); read by `$85FA`. The sprite composer `$7329` reads the whole record. IX = RickRecord in UpdateRick. | `CheckSectionExit`, `ComposeSprite`, `DeathFall`, `DrawSprites`, `DropDetonator` +34 | `ControlMenu`, `DeathFall`, `FireBullet`, `LevelTune`, `LoseLife` +17 |
| `$9BAC` | `RickX` (`RickRecord`+1) | 1 | pixels from the view's left, 0-`$E8` | `ComposeSprite`, `DeathFall`, `DropDetonator`, `FireBullet`, `KillRick` +16 | `ControlMenu`, `DeathFall`, `LoseLife`, `MoveMenuRick`, `RickCellCollision` +6 |
| `$9BAD` | `RickY` (`RickRecord`+2) | 2 | 2 bytes, pixels from the view's top | `CheckSectionExit`, `ComposeSprite`, `DeathFall`, `DropDetonator`, `EnemyVertical` +23 | `ControlMenu`, `DeathFall`, `LoseLife`, `MoveMenuRick`, `RickCellCollision` +6 |
| `$9BAF` | `RickSprite` (`RickRecord`+4) | 2 | 2 bytes, the sprite's address | `ComposeSprite`, `ComposeAligned3Rows` (`stage1/rec/rzx-l4-20000-poke`), `ComposeAlignedBlit` (`stage1/rec/rzx-l1-22000-poke`), `ComposeShifted` (`stage1/rec/rzx-l1-22000-poke`) | `ControlMenu`, `DeathFall`, `PickRickSprite`, `RickCellCollision`, `RickShootUp` +4 |
| `$9BB1` | `RickFacing` (`RickRecord`+6) | 1 | bit 7: facing left (the sprite mirrored) | `ComposeSprite`, `FireBullet`, `LoseLife`, `SetupSection`, `ComposeAligned3Rows` (`stage1/rec/rzx-l4-20000-poke`) +5 | `ControlMenu`, `FireBullet`, `LevelTune`, `LoseLife`, `ResetGame` +8 |
| `$9BB2` | `RickWidth` (`RickRecord`+7) | 1 | - | `ComposeSprite`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | - |
| `$9BB3` | `RickHeight` (`RickRecord`+8) | 1 | - | `ComposeSprite`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | - |
| `$9BB4` | `BulletRecord` | 1 of 9 | The bullet: +0 active, +1 x, +2/+3 y, +4/+5 sprite 17, +6 the step (+8 or -8, bit 7 mirrors). Written by FireBullet, MoveBullet, the object step `$865D`, the scroll's shift `$9E31`, FreeAllObjects and the enemies' test `$8BF3` (a hit ends it); read by the composer `$7329` and the traps and pickups (`$A2F7`, `$A528`, `$A69F`). | `BulletHits`, `ComposeSprite`, `DrawSprites`, `MoveBullet`, `RickCellCollision` +10 | `FireBullet`, `FreeAllObjects`, `MoveBullet`, `ShiftObjects`, `TestEnemyHits` (`stage1/rec/rzx-l1-00000-poke`) +1 |
| `$9BB5` | `BulletX` (`BulletRecord`+1) | 1 | - | `BulletHits`, `ComposeSprite`, `MoveBullet`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | `FireBullet`, `MoveBullet` |
| `$9BB6` | `BulletY` (`BulletRecord`+2) | 2 | 2 bytes | `BulletHits`, `ComposeSprite`, `MoveBullet`, `ShiftObjects`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | `FireBullet`, `ShiftObjects` |
| `$9BB8` | `BulletSprite` (`BulletRecord`+4) | 2 | 2 bytes | `ComposeSprite`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | - |
| `$9BBA` | `BulletDx` (`BulletRecord`+6) | 1 | - | `ComposeSprite`, `MoveBullet`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | `FireBullet` |
| `$9BBB` | `BulletWidth` (`BulletRecord`+7) | 1 | - | `ComposeSprite`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | - |
| `$9BBC` | `BulletHeight` (`BulletRecord`+8) | 1 | - | `ComposeSprite`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | - |
| `$9BBD` | `DetonatorRecord` | 1 of 10 | The detonator: +0 active, +1 x, +2/+3 y, +4/+5 sprite, +6 flags, +7, +8, then the fuse. Written by DropDetonator, UpdateDetonator, BurnFuse, `$9E31` and FreeAllObjects; read by the composer `$7329`, `$85FA` and the traps and enemies (`$A2F7`, `$A528`, `$A69F`: the blast). | `BlastHits`, `ComposeSprite`, `DrawSprites`, `DropDetonator`, `RickCellCollision` +14 | `DropDetonator`, `FreeAllObjects`, `RickCellCollision`, `ShiftObjects`, `UpdateDetonator` +7 |
| `$9BBE` | `DetonatorX` (`DetonatorRecord`+1) | 1 | - | `BlastHits`, `ComposeSprite`, `UpdateDetonator`, `UpdateTrap`, `BurnFuse` (`stage1/rec/rzx-l2-02000-poke`) +5 | `DropDetonator`, `RickCellCollision`, `UpdateDetonator`, `UpdateRick`, `DetonatorSlide` (`stage1/rec/rzx-l5-16000-poke`) +2 |
| `$9BBF` | `DetonatorY` (`DetonatorRecord`+2) | 2 | 2 bytes | `BlastHits`, `ComposeSprite`, `ShiftObjects`, `UpdateDetonator`, `UpdateTrap` +6 | `DropDetonator`, `RickCellCollision`, `ShiftObjects`, `UpdateDetonator`, `UpdateRick` +1 |
| `$9BC1` | `DetonatorSprite` (`DetonatorRecord`+4) | 2 | 2 bytes | `ComposeSprite`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | `UpdateDetonator`, `BurnFuse` (`stage1/rec/rzx-l2-02000-poke`) |
| `$9BC3` | `DetonatorFlags` (`DetonatorRecord`+6) | 1 | - | `ComposeSprite`, `ComposeShifted` (`stage1/rec/rzx-l2-12000-poke`) | - |
| `$9BC4` | `DetonatorWidth` (`DetonatorRecord`+7) | 1 | - | - | - |
| `$9BC5` | `DetonatorHeight` (`DetonatorRecord`+8) | 1 | - | - | - |
| `$9BC6` | `DetonatorFuse` (`DetonatorRecord`+9) | 1 | 64 at the drop; the blast at 1-10 | `TestEnemyHits`, `TestTriggerBoxes`, `UpdateDetonator`, `UpdateTrap`, `BurnFuse` (`stage1/rec/rzx-l2-02000-poke`) +1 | `DropDetonator`, `RickCellCollision`, `UpdateDetonator`, `UpdateRick`, `BurnFuse` (`stage1/rec/rzx-l2-02000-poke`) +1 |

## weapons

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$93C0` | `ExplosionFrames` | 10 | The blast's sprites by fuse AND `$FE`: sprites 20-24 (`$CC6D-$CE6D`). Read by BurnFuse. | `UpdateDetonator`, `BurnFuse` (`stage1/rec/rzx-l2-02000-poke`), `UpdatePickup` (`docs/rec/box-shot`) | - |
| `$93CA` | `DetonatorDx` | 2 | The detonator's sideways speed, 8.8 pixels a pass (-2.0, 0 or +2.0 when thrown). Written by DropDetonator and the friction (DetonatorSlide ...); read by UpdateDetonator and PickRickSprite (`$9A25`: Rick shows the throw sprite while it is not 0). | `RickCellCollision`, `UpdateDetonator`, `UpdateRick`, `DetonatorSlide` (`stage1/rec/rzx-l5-16000-poke`), `DetonatorStopFall` (`stage1/rec/rzx-l2-02000-poke`) +3 | `DropDetonator`, `RickCellCollision`, `UpdateDetonator`, `UpdateRick`, `DetonatorSlide` (`stage1/rec/rzx-l5-16000-poke`) +2 |
| `$93CC` | `DetonatorDy` | 2 | The detonator's vertical speed, 8.8 pixels a pass, down positive (+1.0 when dropped, gravity 0.5). Written by DropDetonator, UpdateDetonator and DetonatorStopFall. | `ProbeGround`, `UpdateDetonator`, `DetonatorBounce` (code), `ProbeScanRecord` (code) | `DropDetonator`, `RickCellCollision`, `UpdateDetonator`, `UpdateRick`, `DetonatorStopFall` (`stage1/rec/rzx-l2-02000-poke`) +1 |
| `$93CE` | `DetonatorXFrac` | 1 | The fraction of DetonatorX | `UpdateDetonator`, `DetonatorSlide` (`stage1/rec/rzx-l5-16000-poke`), `DetonatorStopFall` (`stage1/rec/rzx-l2-02000-poke`), `DetonatorKeepDx` (code) | `UpdateDetonator`, `DetonatorSlide` (`stage1/rec/rzx-l5-16000-poke`), `DetonatorStopFall` (`stage1/rec/rzx-l2-02000-poke`), `DetonatorStoreX` (code) |
| `$93CF` | `DetonatorYFrac` | 1 | The fraction of DetonatorY | `UpdateDetonator` | `UpdateDetonator` |

## traps

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A391` | `TrapUnreachableJump` | 3 | TrapUnreachableJump | - | - |
