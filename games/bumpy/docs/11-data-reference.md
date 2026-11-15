# 11. Data reference

Every data entry of the game image `$61A8`-`$F8D3`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: The tape's BASIC, The loading screen) follow the game, each under
its own heading with its modules, its source, its annotations and its recordings.

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$61A8` | `UnusedPicture61A8` | 496 | Never read: 496 bytes of CPC mode-1 picture data left from the original (known only from the bytes). No instruction refers to `$61A8-$6397` and no recording reads it (work/stage1/memmap-use.txt). The bytes are mostly `$F0` and `$0F` runs, the shape of a CPC frame or panel. Kept as leftovers/unused-61a8.bin. | - | - |
| `$6398` | `SidePanels` | 384 of 768 | The two side panels, each 2 bytes x 192 lines, drawn by DrawSides `$B488`. DrawSides `$B488` draws SidePanels at the CPC address `$F800` (left edge, B = `$C0` lines, SpriteWidth 2) and SidePanelRight `$6518` at `$F83C` (right edge) once per game start. Witness: read by every recording that starts a game (c1, menu, gameover, rzx). | `DrawSprite` | - |
| `$6518` | `SidePanelRight` (`SidePanels`+384) | 384 | the right panel, 384 bytes | `DrawSprite` | - |
| `$6698` | `ExitSign` | 112 | The EXIT sign: two pictures of 8 bytes x 7 lines, read only by the unrun DrawExitSign `$D08E`. DrawExitSign `$D08E` (never called) would XOR the first picture one character row above the exit's cell. No recording reads these 112 bytes. Known only from the code. | - | - |
| `$6708` | `BlankPicture` | 80 | 80 zero bytes: the blank picture that erases a cell, the ball's last burst frame and the exit's first frame. Read by the burst's last step (`$B1CB`, 4 x 14), FillColumn (`$B4E1`), OpenExit (`$BCE1`, 8 x 10), the fire put-out (`$C126`) and the lock opening's end (`$C4B8`). Its bytes are all zero, so a stored blank clears and an XOR leaves the screen as it is. | `ClearPlayArea`, `DrawSprite` (`stage1/menu`) | - |
| `$6758` | `Unused6758` | 144 | 144 zero bytes no routine reads | - | - |
| `$67E8` | `BallPictures` | 640 of 1280 | The ball: 16 pictures of 4 bytes x 10 lines for player 1, then 16 for player 2 at BallPictures2 `$6A68`. BallPictures (the round ball) and the 15 rolling frames `$6810-$6A40`, 40 bytes apart, chosen by BallFramesRight `$C4E2` / BallFramesLeft `$C502` for each step of a move. Player 2's ball is the same set `$280` bytes on (`$ADE6` adds `$0280` when CurrentPlayer `$ADDB` is 2). Witness: read every frame of play (the ball is drawn by XOR, erased and drawn again); BallPictures2 is read only in two-player turns of player 2 (work/stage2/rec/twoplayer). | `XorSprite`, `DrawSprite` (`stage1/menu`) | - |
| `$6A68` | `BallPictures2` (`BallPictures`+640) | 640 | player 2's ball, 16 pictures | `XorSprite` (`stage2/rec/twoname`) | - |
| `$6CE8` | `ObjectPictures` | 2240 | The objects 1-40: 4 bytes x 14 lines each (56 bytes), kind k at `$6CB0` + 56k. TakeObject `$B958` and BuildLevelObject `$CFF4` find kind k at `$6CB0` + 56 x k (kind 0, no object, is never drawn, so `$6CB0` is only a base inside BallPictures2). Drawn in the ink ObjectInks `$C6F6`[k] by `$E3E5`. Kinds: 1 hammer, 2 key, 3 water, 4 bottle (an extra life), 5-40 prizes (src/res/sprites/README.md). | `XorSprite` | - |
| `$75A8` | `UnusedPicture75A8` | 480 | Never read: 480 bytes of CPC picture data left from the original (known only from the bytes) | - | - |
| `$7788` | `Platform1Pictures` | 32 of 376 | Platform type 1 (and the plain one under a fire, type 8): rest, two take-off and three spring pictures, 8 bytes wide. Rest `$7788` (4 lines), take-off `$77A8` and `$77F8` (10 lines each, also the conveyors 6 and 7, PlatDraw6/7), spring `$7848` (7), `$7880` (9), `$78C8` (7): the pictures SpringPics `$C5D6` and TakeoffPics `$C64E` name for type 1. Drawn by XOR at the cell's screen address CellScrAddr `$AB2D`. | `XorSprite` | - |
| `$77A8` | `Platform1Takeoff` (`Platform1Pictures`+32) | 80 | take-off, 8 x 10; the conveyor left (type 6) | `XorSprite` | - |
| `$77F8` | `Platform1Takeoff2` (`Platform1Pictures`+112) | 80 | take-off, 8 x 10; the conveyor right (type 7) | `XorSprite` | - |
| `$7848` | `Platform1Spring` (`Platform1Pictures`+192) | 184 | spring pictures: 8 x 7, 8 x 9, 8 x 7 | `XorSprite` | - |
| `$7900` | `Platform2Pictures` | 376 | Platform type 2 (crumbling, first stage): rest 8 x 4, take-off 8 x 10 twice, spring 8 x 7, 8 x 9, 8 x 7 | `XorSprite` (`stage1/menu`) | - |
| `$7A78` | `Platform3Pictures` | 234 | Platform type 3 (crumbling, second stage), 6 bytes wide: rest 6 x 4, take-off 6 x 8 twice, spring 6 x 6, 6 x 7, 6 x 6 | `XorSprite` (`stage1/menu`) | - |
| `$7B62` | `Platform4Pictures` | 128 | Platform type 4 (crumbling, last stage), 4 bytes wide: rest 4 x 4, take-off 4 x 6 twice, spring 4 x 5, 4 x 6, 4 x 5 | `XorSprite` (`stage1/menu`) | - |
| `$7BE2` | `Platform5Pictures` | 376 | Platform type 5 (the stopping platform, and the one under a fire, type 9): rest 8 x 4, take-off 8 x 10 twice, spring 8 x 7, 8 x 9, 8 x 7 | `XorSprite` (`stage1/menu`) | - |
| `$7D5A` | `SpikesPicture` | 42 | Platform type 12, the spikes: 6 bytes x 7 lines (PlatDraw12 `$D1B2`) | `XorSprite` (`stage1/menu`) | - |
| `$7D84` | `CrumblePictures` | 32 | The crumbling platforms' falling pictures: 8 x 4, then three of 6 x 4 (CrumbleType3), three of 4 x 4, three of 2 x 4 and four of 2 x 5. Drawn one a step by the crumble steps (`$C258-$C3BF`) at CrumbleAddr `$AB24` as a platform wears from type 2 to 3, 3 to 4 and 4 to nothing. | `XorSprite` (`stage1/menu`) | - |
| `$7DA4` | `CrumbleType3` | 72 | Three falling pictures of 6 x 4 | `XorSprite` (`stage1/menu`) | - |
| `$7DEC` | `CrumbleType4` | 48 | Three falling pictures of 4 x 4 | `XorSprite` (`stage1/menu`) | - |
| `$7E1C` | `CrumbleSmall` | 24 | Three falling pictures of 2 x 4 | `XorSprite` (`stage1/menu`) | - |
| `$7E34` | `CrumbleBits` | 40 | Four falling pictures of 2 x 5, the last pieces | `XorSprite` (`stage1/menu`) | - |
| `$7E5C` | `WallPictures` | 192 of 624 | The walls, 2 bytes x 24 lines each: wall 4's four frames, the locks 3, 2, 1, the flash, the lock's five opening frames. Wall 4 (no key opens it) cycles `$7E5C` + 48n, n 0-3, every fourth frame (AnimateWalls `$BC30`). Locks: type 3 `$7F1C`, type 2 `$7F4C`, type 1 `$7F7C` (WallDraw3/2/1); `$7FAC` the flash of a key used; `$7FDC-$809C` the five frames of a type-1 lock opening (`$C492-$C4B1`). Drawn at WallScrAddr `$AB2F`. | `DrawSprite` (`stage1/menu`), `XorSprite` (`stage1/menu`) | - |
| `$7F1C` | `WallLock3` (`WallPictures`+192) | 48 | lock type 3 | `XorSprite` (`stage1/rzx/l01`) | - |
| `$7F4C` | `WallLock2` (`WallPictures`+240) | 48 | lock type 2 | `XorSprite` (`stage1/rzx/l01`) | - |
| `$7F7C` | `WallLock1` (`WallPictures`+288) | 48 | lock type 1 | `XorSprite` (`stage1/menu`) | - |
| `$7FAC` | `WallFlash` (`WallPictures`+336) | 48 | a lock taking a key | `XorSprite` (`stage1/menu`) | - |
| `$7FDC` | `WallOpening` (`WallPictures`+384) | 240 | a type-1 lock opening, five frames | `DrawSprite` (`stage1/menu`) | - |
| `$80CC` | `ExitMark` | 9 | The exit: a 1-byte x 9-line mark, then four frames of 6 bytes x 5 lines at ExitFrames `$80D5`. OpenExit `$BCB9` draws ExitMark (`$BCF6`, SpriteWidth 1, 9 lines); AnimateExit `$BD21` cycles the frames from the table `$C522`. | `DrawSprite` (`stage1/menu`) | - |
| `$80D5` | `ExitFrames` | 120 | The exit's four frames, 6 x 5 | `DrawSprite` (`stage1/menu`) | - |
| `$814D` | `FirePictures` | 90 | Flames: three frames of 6 bytes x 5 lines over a burning platform (types 8 and 9). AnimateFires `$BBCD` picks frame FireFrame `$AA16` every fourth frame; PlatDraw8/9 draw the first at the build. | `DrawSprite`, `XorSprite` | - |
| `$81A7` | `SteamPictures` | 66 | The water drop's steam over a fire put out: 6 x 6, 6 x 3, 6 x 2, then 4 x 3 at SteamSmall `$81E9`. Drawn by the fire put-out steps (`$C13E-$C185`) at FireOutAddr `$AB29`. | `XorSprite` (`stage1/menu`) | - |
| `$81E9` | `SteamSmall` | 12 | the last steam picture, 4 x 3 | `XorSprite` (`stage1/menu`) | - |
| `$81F5` | `BurstPictures` | 336 | The ball bursting: six pictures of 4 bytes x 14 lines (state 6, `$B195-$B1C2`), then BlankPicture | `DrawSprite` (`stage1/rzx/l35`) | - |
| `$8345` | `BrickPicture` | 64 | One brick layer: 8 bytes x 8 lines, drawn by XorBricks `$E4C4` from the high nibbles. DrawBricks `$D180` draws it once a layer still standing (BrickLayers `$AAD7`, 8 for a whole brick). | `XorBricks` (`stage1/rzx/l40`) | - |
| `$8385` | `Unused8385` | 2231 | Never read: 2231 bytes left from the original (known only from the bytes). No instruction refers to `$8385-$8C3B`; no recording reads it. The bytes look like more CPC mode-1 pictures. Note that LevelRecords is reached as `$8BF1` + 75 x (level + 1) (BuildLevel `$CF7E`), an address inside this block that is never read. | - | - |

## levels

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8C3C` | `LevelRecords` | 7500 | The 100 level records, 75 bytes each (level 0 first). BuildLevel `$CF2E` reads record Level `$AB00` (as `$8BF1` + 75 x (Level + 1)) once per life start. Record: +0..+35 the cells, row by row from the top, 6 a row (wall << 4 \| platform); +36 the start cell; +37 the prizes; +38 the exit's cell; +39..+74 the objects (0 none, 1-40). Witness: 88 levels read by the RZX recordings rzx l00-l99 (the record of each level they reach); the other levels are read by stage 2's level recordings (work/stage2/rec). | `BuildLevel` | - |
| `$A988` | `LevelsEnd` | 117 | 117 zero bytes after the last record, never read | `DrawObjectXor` (code) | - |
| `$E0C4` | `LevelLeftover` | 85 | 85 bytes of small numbers, never read. Known only from the recordings: no read and no reader in the code. Pairs of values 0-`$16`; their meaning is not known. | - | - |
| `$E119` | `LevelColours` | 24 | The CPC inks of the three pens, a row for each level mod 7. BuildLevel reads row Level mod 7 + 1 (the first row, `$E119-$E11B`, is never read) and passes the three values (CPC firmware colours 0-26) to `$B6DB`, which on the Spectrum returns at once: a leftover of the Amstrad version. | `BuildLevel` | - |
| `$E1C9` | `EditorTexts` | 81 | The texts of a level editor's menu, letters coded A = 1, never read. "RETOUR", "EDITEUR", "CHARGER TABLEAUX", "SAUVER TABLEAUX", "EFFACER TABLEAU", "QUITTER EDITEUR", each ended by 0: the French menu of a level editor the game does not have. Known only from the bytes: nothing reads them. | - | - |
| `$E21A` | `EditorFontPad` | 4 | Four zero bytes before the editor's letters, never read | - | - |
| `$E21E` | `EditorFont` | 130 | The letters A-Z of the editor, 5 lines of 8 pixels each, never read. 26 one-colour glyphs for EditorTexts. Two bytes (`$E277-$E278`) are read in the recordings, by no reader of the font: known only from the recordings. | `WallScreenAddr` (`stage1/rzx/l14`) | - |

## vars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A9FD` | `TakeoffDrawn` | 1 | 1 while the take-off picture of the cell the ball leaves is on the screen | `LeftStep5`, `RightStep5` | `GameStart`, `LeftStep5`, `LeftTakeoff`, `RightStep5`, `RightTakeoff` +8 |
| `$A9FE` | `SpriteWidth` | 1 | The width in bytes of the next picture a blitter draws (the rows go in B) | `DrawSprite`, `PaintAttrs`, `XorSprite`, `XorBricks` (`stage1/rzx/l40`) | `AnimateFires`, `BuildLevelNextCell`, `BuildLevelObject`, `DrawBallLeft`, `DrawBallRight` +65 |
| `$A9FF` | `BallStep` | 1 | The step of the ball's current move: 0-15 (bounce, left, right), 0-7 (up, down) | `BallBounceMove`, `BallDownMove`, `BallLeftMove`, `BallRightMove`, `BallStepMove` +7 | `BallBounceMove`, `BallDownMove`, `BallLeftMove`, `BallRightMove`, `BallUpMove` +13 |
| `$AA00` | `BallState` | 1 | The ball's state: 0 bounce in place, 1 left, 2 right, 3 up, 4 down, 5 stopped, 6 burst, 7 fall out, 8 level end | `ChooseNextState`, `MainLoop`, `UpStep0`, `UpStep1`, `UpStep2` +5 | `BallBumpCeiling`, `ChooseNextState`, `GameStart`, `LandingCheck`, `RightStep5` +16 |
| `$AA01` | `BallSprite` | 2 | The ball's current picture (in BallPictures `$67E8`) | `BallStepMove`, `DrawBallFrame`, `LostStep3` (`stage1/rzx/l10`), `LostStep4` (`stage1/rzx/l10`), `LostStep5` (`stage1/rzx/l10`) +1 | `BallBounceMove`, `BallDownMove`, `BallUpMove`, `BuildLevelNextCell`, `DrawBallLeft` +2 |
| `$AA03` | `BallScrAddr` | 2 | The ball's CPC screen address | `BallBumpCeiling`, `BallStepMove`, `DrawBallFrame`, `DrawBallRound`, `LeftStep5` +8 | `BallBumpCeiling`, `BallStepMove`, `BuildLevelNextCell`, `LevelEnd` (`stage1/menu`), `LostStep1` (`stage1/rzx/l10`) +3 |
| `$AA05` | `BallOldAddr` | 2 | The address the ball was drawn at last, to erase it | `BallStepMove`, `DrawBallRoundOld` | `BallBumpCeiling`, `BallStepMove` |
| `$AA07` | `CellIndex` | 2 | A cell's index as a word: the build's and the brick test's current cell | `BuildLevelObject`, `HitBrick` (`stage1/rzx/l01`) | `BuildLevelCell`, `HitBrick` (`stage1/rzx/l01`) |
| `$AA09` | `Unused1` | 2 | two bytes never used | - | - |
| `$AA0B` | `CellByte` | 1 | Scratch: a cell's byte during the build, a brick's layers in the brick test | `AnimateFires`, `BuildLevel`, `LeftStep8`, `RightStep8`, `AnimateWalls` (`stage1/menu`) +1 | `AnimateFires`, `AnimateWalls`, `BuildLevel`, `LeftStep8`, `RightStep8` +1 |
| `$AA0C` | `FireTick` | 1 | Counts frames to the flames' next frame (every fourth) | `AnimateFires` | `AnimateFires`, `NextFireFrame` |
| `$AA0D` | `WallTick` | 1 | Counts frames to wall 4's next frame (every fourth) | `AnimateWalls` | `AnimateWalls`, `NextWallFrame` |
| `$AA0E` | `ExitTick` | 1 | Counts frames to the exit's next frame | `AnimateExit` (`stage1/menu`) | `AnimateExit` (`stage1/menu`), `NextExitFrame` (`stage1/menu`) |
| `$AA0F` | `ExitFrame` | 1 | The exit's frame, 1-4 | `AnimateExit` (`stage1/menu`), `NextExitFrame` (`stage1/menu`) | `NextExitFrame` (`stage1/menu`) |
| `$AA10` | `ExitAnimAddr` | 2 | The exit's screen address | `AnimateExit` (`stage1/menu`) | `OpenExit` (`stage1/menu`) |
| `$AA12` | `ExitOpen` | 1 | 1 once the exit is open | `AnimateExit` | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`), `OpenExit` (`stage1/menu`) |
| `$AA13` | `SpringArmed` | 1 | 1 when the up key or fire armed the spring: the next landing goes up (state 3) | `BounceStep11`, `BounceStep14`, `BounceStep15`, `BounceStep9`, `ChooseNextState` +15 | `GameStart`, `LoadSpring`, `SpringStep6`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`) +1 |
| `$AA14` | `CrumblePending` | 1 | A crumbling platform waits for the ball to leave | `BounceStep1`, `LeftStep5`, `RightStep5`, `UpStep3` | `GameStart`, `FallAwayStep9` (`stage1/rzx/l02`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) +5 |
| `$AA15` | `CrumbleActive` | 1 | A crumbling platform's animation runs | `DownStep4`, `PlatformChangeStep`, `UpStep4`, `LeftCrumble2` (`stage1/menu`), `LeftCrumble3` (`stage1/rzx/l05`) +4 | `GameStart`, `BounceStep1` (`stage1/rzx/l02`), `FallAwayStep9` (`stage1/rzx/l02`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`) +6 |
| `$AA16` | `FireFrame` | 1 | The flames' frame, 1-3 | `AnimateFires`, `NextFireFrame` | `NextFireFrame` |
| `$AA17` | `WallFrame` | 1 | Wall 4's frame, 1-4 | `NextWallFrame`, `AnimateWalls` (`stage1/menu`) | `NextWallFrame` |
| `$AA18` | `LockAnimAddr` | 2 | The screen address of the lock being opened | `StoreWallFrame` (`stage1/menu`) | `LeftStep5` (`stage1/menu`), `RightStep5` (`stage1/rzx/l01`) |
| `$AA1A` | `LockAnimSteps` | 2 | The lock animation's step table (`$C592`, `$C596` or `$C59A`) | `WallStep` (`stage1/menu`) | `LeftStep5` (`stage1/menu`), `RightStep5` (`stage1/rzx/l01`) |
| `$AA1C` | `LockStep` | 1 | The lock animation's step | `WallStep` (`stage1/menu`) | `LeftStep5` (`stage1/menu`), `RightStep5` (`stage1/rzx/l01`), `WallStep` (`stage1/menu`) |
| `$AA1D` | `LockActive` | 1 | A lock animation runs | `WallStep` | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LeftStep5` (`stage1/menu`), `LifeStart` (`stage1/gameover`) +3 |
| `$AA1E` | `Unused2` | 2 | two bytes never used | - | - |
| `$AA20` | `LevelRecord` | 36 | The current level's record, copied from LevelRecords: 36 cells, then BallCell, PrizesLeft, ExitCell. BuildLevel `$CF2E` clears `$AA20-$AAFA` (219 bytes) and copies the 75-byte record here, so the record's byte 36 becomes BallCell `$AA44`, byte 37 PrizesLeft `$AA45`, byte 38 ExitCell `$AA46` and bytes 39-74 CellObjects `$AA47`. | `BuildLevel` | `BuildLevel` |
| `$AA44` | `BallCell` | 1 | The ball's cell, 0-35 (the record's start cell at a life's start) | `BounceStep0`, `CellScreenAddr`, `DownStep0`, `DownStep3`, `DrawFlames` +23 | `BuildLevel`, `BuildLevelCell`, `BuildLevelNextCell`, `DownStep3`, `LeftStep8` +2 |
| `$AA45` | `PrizesLeft` | 1 | The prizes still to take; at 0 OpenExit `$BCB9` opens the exit | `AddScore` | `AddScore`, `BuildLevel` |
| `$AA46` | `ExitCell` | 1 | The cell the exit opens in | `OpenExit` (`stage1/menu`) | `BuildLevel` |
| `$AA47` | `CellObjects` | 36 | The object of each cell, 0 none, 1-40 (taken ones become 0) | `BuildLevelObject`, `ReadCell` | `BuildLevel`, `TakeObject` |
| `$AA6B` | `CellPlatforms` | 36 | The platform type of each cell (the record's low nibbles; changed as platforms crumble, burn out or break) | `BounceStep0`, `BuildLevelCell`, `DownStep0`, `LandingCheck`, `LeftStep0` +4 | `BuildLevel`, `ExtinguishFire` (`stage1/menu`), `HitBrick` (`stage1/rzx/l01`), `OpenExit` (`stage1/menu`), `SetPlatformCell` (`stage1/menu`) |
| `$AA8F` | `CellWalls` | 36 | The wall type to the right of each cell (the record's high nibbles; lowered as keys open locks) | `AnimateWalls`, `BuildLevelObject`, `RightStep5`, `BounceStep0` (`stage1/rzx/l02`), `LeftStep0` (`stage1/menu`) +2 | `BuildLevel`, `LeftStep5` (`stage1/menu`), `RightStep5` (`stage1/rzx/l01`) |
| `$AAB3` | `CellBurning` | 36 | 1 for a cell whose platform burns (types 8 and 9) | `AnimateFires` | `BuildLevel`, `DrawFlames`, `ExtinguishFire` (`stage1/menu`) |
| `$AAD7` | `BrickLayers` | 36 | The brick layers still standing in each cell (8 for a whole brick, type 10) | `LeftStep8`, `RightStep8`, `HitBrick` (`stage1/rzx/l01`) | `BuildLevel`, `DrawBricks` (`stage1/rzx/l40`), `HitBrick` (`stage1/rzx/l01`) |
| `$AAFB` | `Score` | 2 | The current player's score | `AddScore`, `ScoreToHud`, `EnterHallOfFame` (`stage1/gameover`), `GameOver` (`stage1/gameover`), `LevelEnd` (`stage1/menu`) +2 | `AddScore`, `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LevelEnd` (`stage1/menu`) +3 |
| `$AAFD` | `Water` | 1 | Water drops: one puts out a fire the ball lands on | `GameStart`, `TakeWater`, `WaterToHud`, `DownStep0` (`stage1/menu`), `GameRestart` (`stage1/menu`) +7 | `GameStart`, `TakeWater`, `DownStep0` (`stage1/menu`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`) +5 |
| `$AAFE` | `Keys` | 1 | Keys: one opens a lock one step | `GameStart`, `KeysToHud`, `RightStep5`, `TakeKey`, `WaterToHud` +7 | `GameStart`, `TakeKey`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LeftStep5` (`stage1/menu`) +4 |
| `$AAFF` | `Hammers` | 1 | Hammers: one breaks a whole brick's first layer | `GameStart`, `HammersToHud`, `KeysToHud`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`) +6 | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `HitBrick` (`stage1/rzx/l01`), `LifeStart` (`stage1/gameover`) +3 |
| `$AB00` | `Level` | 1 | The level, 0-99 (shown as is) | `BuildLevel`, `HammersToHud`, `LevelToHud`, `LevelEnd` (`stage1/menu`), `LoseLife` (`stage1/rzx/l10`) +1 | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LevelEnd` (`stage1/menu`), `LifeStart` (`stage1/gameover`) +1 |
| `$AB01` | `Lives` | 1 | Spare lives | `GameStart`, `LevelToHud`, `LivesToHud`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`) +5 | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`), `LoseLife` (`stage1/rzx/l10`) +2 |
| `$AB02` | `AfterLives` | 1 | Read with the record copies, never written: the byte after the player's record | `LivesToHud` | - |
| `$AB03` | `Unused3` | 1 | never used | - | - |
| `$AB04` | `Timer` | 2 | The level's timer: 1000 at a life's start, one off a pass of MainLoop; the rest goes into the score at the level end | `TickTimer`, `LevelEnd` (`stage1/menu`) | `GameStart`, `TickTimer`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LevelEnd` (`stage1/menu`) +1 |
| `$AB06` | `WaterAtStart` | 1 | Water at the level's start (given back when a life is lost) | `LoseLife` (`stage1/rzx/l10`), `SelfDestruct` (`stage1/gameover`) | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) |
| `$AB07` | `KeysAtStart` | 1 | Keys at the level's start | `LoseLife` (`stage1/rzx/l10`), `SelfDestruct` (`stage1/gameover`) | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) |
| `$AB08` | `HammersAtStart` | 1 | Hammers at the level's start | `LoseLife` (`stage1/rzx/l10`), `SelfDestruct` (`stage1/gameover`) | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) |
| `$AB09` | `Player1Record` | 7 | Player 1's record: score (word), water, keys, hammers, level, lives (`$FA` lives: the player is out) | `GameStart`, `GameOver` (`stage2/rec/twoname`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) +1 | `InitPlayers`, `CheatStock` (`stage1/menu`), `GameOver` (`stage1/gameover`), `LevelEnd` (`stage1/menu`), `LoseLife` (`stage1/rzx/l10`) +1 |
| `$AB10` | `Player2Record` | 7 | Player 2's record, the same layout | `GameOver` (`stage2/rec/twoname`), `GameRestart` (`stage1/menu`), `LifeStart` (`stage2/rec/twoname`), `SelfDestruct` (`stage2/rec/twoname`) | `InitPlayers`, `CheatStock` (`stage1/menu`), `GameOver` (`stage2/rec/twoname`), `SelfDestruct` (`stage2/rec/twoname`) |
| `$AB17` | `BorderFlash` | 1 | Set by the bottle (an extra life): the CPC border flash, a RET on the Spectrum | `BottleFlashOff` | `BottleFlashOff` (`stage1/menu`), `TakeBottle` (`stage1/menu`) |
| `$AB18` | `HudColumn` | 1 | The column the next HUD figure prints at | `PrintHudGlyph`, `HudBlit` (`stage1/rzx/l36`) | `HammersToHud`, `KeysToHud`, `LevelToHud`, `LivesToHud`, `PrintHudGlyph` +4 |
| `$AB19` | `Unused4` | 1 | never used | - | - |
| `$AB1A` | `StartCell` | 1 | The level's start cell (the record's byte 36) | `BuildLevelNextCell` | `BuildLevel` |
| `$AB1B` | `CrumbleCell` | 1 | The cell of the crumbling platform | `SetPlatformCell` (`stage1/menu`) | `StartFallAway` (`stage1/rzx/l02`), `StartWearTo3` (`stage1/menu`), `StartWearTo4` (`stage1/menu`) |
| `$AB1C` | `CellPlatform` | 1 | The platform type of the ball's cell (CellPlatforms[BallCell], set by `$BB32`) | `BounceStep0`, `ChooseNextState`, `DownStep7`, `LandingCheck`, `LeftStep0` +21 | `GameStart`, `ReadCell`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) |
| `$AB1D` | `CellObject` | 1 | The object in the ball's cell | `TakeObject` | `ReadCell` |
| `$AB1E` | `CellWall` | 1 | The wall of the ball's cell (written by the unrun ReadWallCell `$BB4A`) | - | `ReadWallCell` (code) |
| `$AB1F` | `Unused5` | 1 | never used | - | - |
| `$AB20` | `CrumbleNewType` | 1 | The type the crumbling platform becomes | `SetPlatformCell` (`stage1/menu`) | `StartFallAway` (`stage1/rzx/l02`), `StartWearTo3` (`stage1/menu`), `StartWearTo4` (`stage1/menu`) |
| `$AB21` | `CrumbleStep` | 1 | The crumble animation's step | `PlatformChangeStep` (`stage1/menu`) | `PlatformChangeStep` (`stage1/menu`), `StartFallAway` (`stage1/rzx/l02`), `StartWearTo3` (`stage1/menu`), `StartWearTo4` (`stage1/menu`) |
| `$AB22` | `CrumbleSteps` | 2 | The crumble animation's step table | `PlatformChangeStep` (`stage1/menu`) | `StartFallAway` (`stage1/rzx/l02`), `StartWearTo3` (`stage1/menu`), `StartWearTo4` (`stage1/menu`) |
| `$AB24` | `CrumbleAddr` | 2 | The crumbling platform's screen address | `XorCrack2a` (`stage1/menu`), `XorCrack2b` (`stage1/menu`), `XorCrack2c` (`stage1/menu`), `XorCrack3a` (`stage1/menu`), `XorCrack3b` (`stage1/menu`) +12 | `StartFallAway` (`stage1/rzx/l02`), `StartWearTo3` (`stage1/menu`), `StartWearTo4` (`stage1/menu`) |
| `$AB26` | `FireOutStep` | 1 | The fire put-out animation's step | `WaterStep` (`stage1/menu`) | `DownStep0` (`stage1/menu`), `LeftStep9` (`stage1/rzx/l00`), `RightStep9` (`stage1/rzx/l08`), `WaterStep` (`stage1/menu`) |
| `$AB27` | `FireOutSteps` | 2 | Its step table (`$C55E`, `$C56E` or `$C57E`) | `WaterStep` (`stage1/menu`) | `DownStep0` (`stage1/menu`), `LeftStep9` (`stage1/rzx/l00`), `RightStep9` (`stage1/rzx/l08`) |
| `$AB29` | `FireOutAddr` | 2 | Its screen address | `ExtinguishFire` (`stage1/menu`), `Steam1` (`stage1/menu`), `Steam2` (`stage1/menu`), `Steam3` (`stage1/menu`), `Steam4` (`stage1/menu`) +1 | `DownStep0` (`stage1/menu`), `LeftStep9` (`stage1/rzx/l00`), `RightStep9` (`stage1/rzx/l08`) |
| `$AB2B` | `FireOutActive` | 1 | A fire put-out animation runs | `WaterStep` | `GameStart`, `DownStep0` (`stage1/menu`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LeftStep9` (`stage1/rzx/l00`) +5 |
| `$AB2C` | `Unused6` | 1 | never used | - | - |
| `$AB2D` | `CellScrAddr` | 2 | The CPC screen address of the current cell (CellAddresses `$E131`) | `BuildLevelObject`, `DrawFlames`, `DrawPlatform1Pic`, `SpringPart0`, `SpringPart1` +25 | `CellScreenAddr`, `OpenExit` (`stage1/menu`) |
| `$AB2F` | `WallScrAddr` | 2 | The CPC screen address of the current wall (WallAddresses `$E179`) | `DrawLock1Pic` (`stage1/rzx/l98`), `DrawLock3Pic` (`stage1/rzx/l38`), `DrawWall4Pic` (`stage1/menu`), `DrawWallPic` (`stage1/menu`), `StoreWallPic` (code) | `WallScreenAddr` |
| `$AB31` | `BrickLayerAddr` | 2 | The screen address of the brick layer being knocked off | `BrickCrumble1` (`stage1/rzx/l01`), `BrickCrumble2` (`stage1/rzx/l01`), `BrickCrumble3` (`stage1/rzx/l01`), `BrickCrumble4` (`stage1/rzx/l01`) | `HitBrick` (`stage1/rzx/l01`) |
| `$AB33` | `BrickActive` | 1 | A brick animation runs | `BrickStep` | `GameStart`, `BrickCrumble4` (`stage1/rzx/l01`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `HitBrick` (`stage1/rzx/l01`) +1 |
| `$AB34` | `BrickAnimStep` | 1 | The brick animation's step | `BrickStep` (`stage1/rzx/l01`) | `BrickStep` (`stage1/rzx/l01`), `HitBrick` (`stage1/rzx/l01`) |
| `$AB35` | `SpringRecord` | 24 | The spring record of the ball's platform (24 bytes from SpringPics `$C5D6`): 4 offsets, 4 pictures, 4 widths, 4 row counts | `SpringPart0`, `SpringPart1`, `SpringPart2`, `SpringPart3` | `LoadSpring` |
| `$AB4D` | `TakeoffRecord` | 18 | The take-off record (18 bytes from TakeoffPics `$C64E`): 3 offsets, 3 pictures, 3 widths, 3 row counts | `TiltPart0`, `TiltPart1`, `TiltPart2` | `LeftTakeoff`, `RightTakeoff`, `LeftCrumble2` (`stage1/rzx/l39`), `LeftCrumble3` (`stage1/rzx/l34`), `LeftCrumble4` (`stage1/rzx/l13`) +2 |
| `$AB5F` | `Unused7` | 29 | 29 zero bytes never used | - | - |

## setup

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$ABA3` | `UnusedByteABA3` | 1 | One byte (`$01`) between the JP and the demo variables; nothing reads it (leftover) | - | - |
| `$ABA4` | `DemoInputPtr` | 2 | The demo's input pointer: the last move state read from `$D25B`+ (BallStopped `$B11A`) | `BallStopped` (`stage1/menu`), `BounceStep9` (`stage1/menu`), `ChooseNextState` (`stage1/menu`), `DownStep4` (`stage1/menu`), `LeftStep9` (`stage1/menu`) +1 | `BallStopped` (`stage1/menu`), `ChooseNextState` (`stage1/menu`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (code) |
| `$ABA6` | `DemoFlag` | 1 | 1 while the demo plays, 0 in a game: no keys are read, the "ready?" text is skipped | `BallBounceMove`, `BallDownMove`, `BallLeftMove`, `BallRightMove`, `BallUpMove` +14 | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`stage2/rec/twoname`) |
| `$ABA7` | `ObjectFlag` | 1 | The quiet flag: 1 before the landing click (SfxLand at `$C79E`, `$C86D`, `$CAB3`), 4 after the bottle (TakeBottle `$BA1C`) or a water drop spent on a fire (`$CA0C`, `$CC4F`, `$CE4E`); at 4 the next bounce, jump or pick-up is silent, and the silent branch sets it back to 0 | `BounceStep0`, `LeftStep0`, `RightStep0`, `TakeKey`, `TakeObject` +3 | `BounceStep0`, `LeftStep0`, `RightStep0`, `DownStep0` (`stage1/menu`), `LeftStep9` (`stage1/rzx/l00`) +7 |

## mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AD29` | `StateTable` | 18 | The ball's nine state routines by BallState `$AA00`: 0 bounce, 1 left, 2 right, 3 up, 4 down, 5 stopped, 6 burst, 7 out below, 8 level end | `MainLoop` | - |
| `$AD3B` | `ReadyText` | 13 | The one-player text: AT 11,13, ATTR 7, double height, "ready?", end (PrintText `$E667`) | `PrintText` | - |
| `$AD48` | `Player1ReadyText` | 60 | The two-player text for player 1: "PLAYER 1" at 9,12 in ink 5, "ready?" at 12,13 in ink 7, "PLAYER" down column 31 in ink 5, then "1" at 17,31 in ink 7 | `PrintText` (`stage1/menu`) | - |
| `$AD84` | `Player2ReadyText` | 59 | The same for player 2: "PLAYER 2", "ready?", "PLAYER" down column 31, "2" | `PrintText` (`stage2/rec/twoname`) | - |
| `$ADBF` | `BlankReadyText` | 28 | Spaces over "PLAYER n" and "ready?" (AT 9,12 and 12,13); nothing prints it (leftover) | `PrintText` (`stage2/rec/twoname`) | - |
| `$ADDB` | `CurrentPlayer` | 1 | The player playing now: 1 or 2 (selects the ball sprite, PlayerBallSprite `$ADE6`, and the record) | `GameStart`, `PlayerBallSprite`, `GameOver` (`stage1/gameover`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`) +4 | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`stage2/rec/twoname`), `LifeStart` (`stage1/gameover`), `SelfDestruct` (`stage2/rec/twoname`) +3 |
| `$ADDC` | `PlayerCount` | 1 | The number of players, 1 or 2 (GameRestart) | `GameStart`, `GameOver` (`stage1/gameover`), `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) +2 | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`stage2/rec/twoname`), `NewGameOnePlayer` (code), `NewGameTwoPlayers` (code) |
| `$ADDD` | `CheatMode` | 1 | The cheat mode: non-zero refills the stores each life (`$BB7D`) and lets the level end pick a level (`$B2C9`); no code sets it (CheatModeOn `$ADE0` is cut off) | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LevelEnd` (`stage1/menu`), `LifeStart` (`stage1/gameover`) +1 | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`stage2/rec/twoname`), `CheatModeOn` (code) |
| `$ADDE` | `SavedPlayer` | 1 | LifeStart's copy of CurrentPlayer while it walks the two records | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`docs/integrate/rec/exitbelow`), `LifeStart` (`stage1/gameover`) |
| `$B6DC` | `UnusedRetB6DC` | 1 | A lone RET (`$C9`); nothing calls it (leftover) | - | - |
| `$B6E3` | `UnusedRetB6E3` | 1 | A lone RET (`$C9`) before WaitFrame; nothing calls it (leftover) | - | - |
| `$B748` | `FirmwareStubs2` | 8 | Eight more RET stubs (`$C9`), none called. Never run or read. | - | - |
| `$B751` | `FirmwareStubs4` | 3 | Three more RET stubs (`$C9`), none called. Never run or read. | - | - |

## ball

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AE9B` | `BounceChecks` | 32 | State 0's 16 per-step checks (routines `$C778-$C822`) | `StepDispatch` | - |
| `$AEBB` | `BounceOffsets` | 32 | State 0's 16 address offsets: the ball's arc, 18 lines up and back | `BallStepMove` | - |
| `$AF15` | `LeftChecks` | 32 | State 1's 16 per-step checks (routines `$C847-$CA57`) | `StepDispatch` | - |
| `$AF35` | `LeftOffsets` | 32 | State 1's 16 offsets: the arc and 10 CPC bytes to the left | `BallStepMove` | - |
| `$AF8F` | `RightChecks` | 32 | State 2's 16 per-step checks (routines `$CA8D-$CC9A`) | `StepDispatch` | - |
| `$AFAF` | `RightOffsets` | 32 | State 2's 16 offsets: the arc and 10 CPC bytes to the right | `BallStepMove` | - |
| `$B044` | `UpChecks` | 16 | State 3's 8 per-step checks (routines `$CCD0-$CE10`) | `StepDispatch` | - |
| `$B054` | `UpOffsets` | 16 | State 3's 8 offsets: 4 lines up each (`$E000` + `$1FB0` = -`$50` and so on, by the line in the character row) | `BallStepMove` | - |
| `$B0FA` | `DownChecks` | 16 | State 4's 8 per-step checks (routines `$CE24-$CECC`) | `StepDispatch` | - |
| `$B10A` | `DownOffsets` | 16 | State 4's 8 offsets: 4 lines down each | `BallStepMove` | - |
| `$B1F6` | `BurstSteps` | 20 | State 6's ten steps: BurstBall1-3, BurstFrame1-6, BurstEnd | `BallBurst` (`stage1/rzx/l35`) | - |
| `$B22F` | `UnusedRetB22F` | 1 | A lone RET (`$C9`) nobody calls (leftover) | - | - |
| `$B2B8` | `LostSteps` | 10 | State 7's five steps | `BallFallOut` (`stage1/rzx/l10`) | - |
| `$C4E2` | `BallFramesRight` | 32 | The ball's picture for each of the 16 steps of the move right. MoveRight's draw (`$B882`) sets the ball sprite `$AA01` = BallFramesRight[BallStep]: the 15 rolling frames `$6810-$6A40` (40 bytes apart), then the round ball `$67E8` at step 15. Read 16 359 times in the recordings. | `DrawBallRight` | - |
| `$C502` | `BallFramesLeft` | 32 | The ball's picture for each of the 16 steps of the move left. The same frames in the reverse order (`$6A40` down to `$6810`, then `$67E8`), read by `$B8A2` for the move left (13 276 times). | `DrawBallLeft` | - |
| `$C522` | `ExitFrameTable` | 8 | The addresses of the four pictures of the open exit (ExitFrames `$80D5`). AnimateExit `$BD21` draws ExitFrameTable[`$AA0F` - 1] (`$80D5`, `$80F3`, `$8111`, `$812F`; 30 bytes apart, 5 lines of 6 bytes) with ink `$5E` at ExitAnimAddr, every second pass (5672 times), only while the exit is open; the flames are animated by AnimateFires `$BBCD`. | `AnimateExit` (`stage1/menu`) | - |
| `$C52A` | `SpringCurves` | 10 | The spring-press records of platform types 1-5 (24 bytes each at SpringPics). LoadSpring `$BD73` copies the record of the ball's platform type (1-5) to `$AB35` when the up key or fire arms the spring. The records are at SpringPics `$C5D6`. | `LoadSpring` | - |
| `$C5CC` | `TakeoffTable` | 10 | The take-off picture record of platform types 1-5 (18 bytes each at TakeoffPics). LeftTakeoff `$C890` and RightTakeoff `$CAD6` copy TakeoffTable[type - 1]'s record to `$AB4D`. | `LeftTakeoff`, `RightTakeoff`, `LeftCrumble2` (`stage1/rzx/l39`), `LeftCrumble3` (`stage1/rzx/l34`), `LeftCrumble4` (`stage1/rzx/l13`) +2 | - |
| `$C5D6` | `SpringPics` | 24 of 120 | The spring-press records of platform types 1-5, 24 bytes each. Each record is four pictures, the frames of the platform pressed by the bouncing ball: four screen offsets from the cell's address (words), four picture addresses (words), four widths in bytes, four heights in lines. Type 1: offsets 0, `$F800`, `$2FB0`, `$2FB0`; pictures `$7788`, `$7848`, `$7880`, `$78C8`. LoadSpring `$BD73` copies one to `$AB35`; `$BDA6-$BDCE` draw its frames. | `LoadSpring` | - |
| `$C5EE` | `SpringPics2` (`SpringPics`+24) | 24 | type 2, crumbling (first stage) | `LoadSpring` (`stage1/menu`) | - |
| `$C606` | `SpringPics3` (`SpringPics`+48) | 24 | type 3, crumbling (second stage) | `LoadSpring` (`stage1/rzx/l03`) | - |
| `$C61E` | `SpringPics4` (`SpringPics`+72) | 24 | type 4, crumbling (last stage) | `LoadSpring` (`stage1/rzx/l02`) | - |
| `$C636` | `SpringPics5` (`SpringPics`+96) | 24 | type 5, the stopping platform | `LoadSpring` (`stage1/menu`) | - |
| `$C64E` | `TakeoffPics` | 18 of 90 | The take-off records of platform types 1-5, 18 bytes each. Each record is three pictures: three screen offsets from the cell's address (words), three picture addresses (words), three widths, three heights. Picture 0 is the platform itself, picture 1 the one drawn when the ball leaves it to the left (the same picture as the conveyor 6, `$77A8` for type 1), picture 2 the one for the right (`$77F8`, as the conveyor 7). `$BE43` draws picture 0, `$BE5E` picture 1, `$BE79` picture 2, all by XOR, so step 5 of the move draws them again to undo them. | `LeftTakeoff`, `RightTakeoff`, `LeftCrumble2` (`stage1/rzx/l39`), `LeftCrumble3` (`stage1/rzx/l34`), `LeftCrumble4` (`stage1/rzx/l13`) +2 | - |
| `$C660` | `TakeoffPics2` (`TakeoffPics`+18) | 18 | type 2 | `LeftCrumble2` (`stage1/rzx/l39`), `LeftTakeoff` (`stage1/menu`), `RightTakeoff` (`stage1/rzx/l08`) | - |
| `$C672` | `TakeoffPics3` (`TakeoffPics`+36) | 18 | type 3 | `LeftCrumble3` (`stage1/rzx/l34`), `LeftTakeoff` (`stage1/rzx/l05`), `RightCrumble3` (`stage1/rzx/l32`), `RightTakeoff` (`stage1/menu`) | - |
| `$C684` | `TakeoffPics4` (`TakeoffPics`+54) | 18 | type 4 | `LeftCrumble4` (`stage1/rzx/l13`), `LeftTakeoff` (`stage1/rzx/l05`), `RightCrumble4` (`stage1/rzx/l09`), `RightTakeoff` (`stage1/rzx/l05`) | - |
| `$C696` | `TakeoffPics5` (`TakeoffPics`+72) | 18 | type 5 | `LeftTakeoff` (`stage1/menu`), `RightTakeoff` (`stage1/rzx/l12`) | - |
| `$C6A8` | `LeftTakeoffTable` | 26 | Step 0 of the move left: the handler for each platform type 0-12 the ball leaves. LeftStep0 `$C847` jumps to LeftTakeoffTable[`$AB1C`]: 1 and 5 LeftTakeoff, 2-4 LeftCrumble2-4, the others the plain step `$AEE2`. | `LeftStep0` | - |
| `$C6C2` | `RightTakeoffTable` | 26 | Step 0 of the move right: the handler for each platform type 0-12. RightStep0 `$CA8D`: 1 and 5 RightTakeoff, 2-4 RightCrumble2-4, the others `$AF5C`. | `RightStep0` | - |
| `$C6DC` | `UpTakeoffTable` | 26 | Step 0 of the jump: the handler for each platform type 0-12. UpStep0 `$CCD0`: 1 and 5 UpSpringRelease, 2-4 UpCrumble2-4, the others `$AFD6`. | `UpStep0` | - |
| `$C82D` | `BounceTypeTable` | 26 | Bounce step 0: the handler for each platform type 0-12. Types 2, 3, 4 BounceCrumble2-4, the others the tail `$AE65`. Only types 0-4 are read: the ball never bounces in place on the others (5 stops it, 6 and 7 push it, 8, 9 and 12 kill it, 10 and 11 end its moves another way). | `BounceStep0` | - |
| `$E1C1` | `BrickSteps` | 8 | The value a brick counter must have at each step 0-7 of a jump for the bricks to break. `$B8D1` compares `$AAD7`[cell] with BrickSteps[BallStep]: 5, 4, 3, 2, 1, 8, 7, 6. | `HitBrick` (`stage1/rzx/l01`) | - |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B3B1` | `MenuChoice` | 1 | The menu's choice: 0 one player, 2 two players, 4 the demo; GameRestart starts the demo on any value but 0 and 2 (written by Menu at `$EF97` with 4, by SetPlayersMode `$F0C7` with 0 or 2) | `GameStart`, `GameRestart` (`stage1/menu`), `GameRestartChoice` (`stage2/rec/twoname`) | `SetPlayersMode`, `MenuWait` (`stage1/menu`) |
| `$B3CE` | `ControlMask` | 2 | ReadControlMask's result; never read (leftover) | - | `ReadControlMaskNext` (code) |
| `$B436` | `KeyRows` | 9 | The last read of the controls: 8 keyboard half-rows (`$7FFE` ... `$FEFE`) and the Kempston stick, 0 = held | `AnyControl`, `TestKeyBit`, `TestKeyBitTest` (`stage1/rzx/l25`) | `ReadControls` |
| `$B43F` | `UnusedByteB43F` | 1 | One byte after KeyRows; nothing reads it (leftover) | - | - |
| `$D25A` | `DemoMoves` | 49 | The demo's move list: one byte a decision. GameStart sets the demo pointer `$ABA4` = `$D25A`; each decision reads the byte after it (from `$D25B` on, 48 bytes read): 0-5 the next ball state at a landing, 9 arm the spring at a step 9 (BounceStep9, LeftStep9 and the others) or at a fall's step 4 (DownStep4). The first byte is never read. | `BallStopped` (`stage1/menu`), `BounceStep9` (`stage1/menu`), `ChooseNextState` (`stage1/menu`), `DownStep4` (`stage1/menu`), `LeftStep9` (`stage1/menu`) +1 | - |
| `$D28B` | `DemoPad` | 41 | 41 zeros after the demo moves, never read | - | - |
| `$E808` | `Logo` | 1080 | The BUMPY logo: 60 lines of 18 CPC mode-1 bytes (72 x 60 pixels) | `DrawSprite` | - |
| `$EFA2` | `MenuDemoToggle` | 1 | Flipped at each menu time-out: 1 the demo, 0 the hall of fame | `MenuWait` (`stage1/menu`) | `MenuWait` (`stage1/menu`) |
| `$EFED` | `MenuTimer` | 2 | The menu's time-out in frames (3000; 750 on the hall of fame) | `Menu`, `MenuShowHallOfFame` (`stage1/menu`), `MenuWait` (`stage1/menu`), `WaitKeyOrSecond` (`stage1/menu`) | `Menu`, `MenuPrint` (`stage1/menu`), `MenuShowHallOfFame` (`stage1/menu`), `MenuWait` (`stage1/menu`), `WaitKeyOrSecond` (`stage1/menu`) |
| `$EFEF` | `MenuText` | 115 | The options: 0 GAME, 1 ONE PLAYER, 2 KEYBOARD, 3 SINCLAIR, 4 KEMPSTON, and VERSIONED BY J250 <SPAIN> (PrintText) | `PrintText` | `Menu`, `MenuWait` (`stage1/menu`) |
| `$F062` | `Players` | 1 | 0 one player, 1 two players (SetPlayersMode: `$B3B1` = 2 x Players) | `Menu`, `SetPlayersMode`, `MenuWait` (`stage1/menu`), `MenuTogglePlayers` (code) | `Menu`, `MenuWait` (`stage1/menu`), `MenuTogglePlayers` (code) |
| `$F063` | `PlayersTexts` | 32 | "ONE PLAYER" and "TWO PLAYERS", 16 bytes each; MenuTogglePlayers copies 11 | `Menu`, `MenuWait` (`stage1/menu`) | - |
| `$F083` | `ControlChoice` | 1 | The controls chosen in the menu: 0 keyboard, 1 Sinclair, 2 Kempston | `LoadControls` | `Menu`, `MenuWait` (`stage1/menu`), `MenuSelectControlsLoop` (code) |
| `$F084` | `KeySlots` | 8 | The controls in play: eight key codes (row x 8 + bit; row 8 the Kempston port). The key codes of the key test `$B6CB` / `$B3D0`: row 0-7 the half-rows `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE`, row 8 the Kempston byte `$B43E` (inverted by `$B418`). The slots: +0 up, +1 down, +2 left, +3 right, +4 fire, +5 a second fire (not read in this range), +6 `$0C` (H), +7 `$2B` (R). The tape holds the keyboard set; LoadControls copies the chosen set here when a game starts. | `MainLoop`, `TestLeft`, `TestRight`, `TestUpOrFire`, `TestDown` (`stage1/rzx/l00`) +1 | `LoadControls` |
| `$F08C` | `ControlSets` | 6 | The three sets of eight codes by ControlChoice: KeyboardKeys, SinclairKeys, KempstonKeys | `LoadControls` | - |
| `$F092` | `KeyboardKeys` | 8 of 24 | The three control sets, eight key codes each (the KeySlots order): keyboard, Kempston, Sinclair. KeyboardKeys: Q A O P SPACE SPACE H R. KempstonKeys: the Kempston bits 3 2 1 0 4 4 (up, down, left, right, fire, fire), H, R. SinclairKeys: 9 8 6 7 0, the Kempston fire, H, R. | `LoadControls` | - |
| `$F09A` | `KempstonKeys` (`KeyboardKeys`+8) | 8 | Kempston up, down, left, right, fire, fire, H, R | `LoadControls` (`stage1/menu`) | - |
| `$F0A2` | `SinclairKeys` (`KeyboardKeys`+16) | 8 | 9 8 6 7 0, Kempston fire, H, R | `LoadControls` (`stage1/menu`) | - |
| `$F0E8` | `MenuBackdropText` | 125 | The menu's backdrop: coloured bars of spaces around the logo (PrintText) | `PrintText` | - |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B52C` | `SpectrumColumn` | 1 | LineAddress's Spectrum byte column (the CPC byte column / 2) | `DrawSprite`, `XorSprite`, `BrickCrumble1` (`stage1/rzx/l01`), `BrickCrumble2` (`stage1/rzx/l01`), `BrickCrumble3` (`stage1/rzx/l01`) +5 | `LineAddress` |
| `$B52D` | `SpectrumLines` | 414 | The Spectrum address of the start of each CPC line 0-206: 7 lines at `$FCE0`, the 192 screen lines from `$4000`, 8 more at `$FCE0` | `ClearPlayArea`, `DrawGlyph`, `DrawSprite`, `LeftStep5`, `PrintHudGlyph` +11 | - |
| `$C0FE` | `WaterDrop` | 14 | The falling water drop: 2 bytes × 7 rows of CPC mode-1 pixels. Read by XorWaterDrop `$C0E8`. | `XorSprite` (`stage1/menu`) | - |
| `$C534` | `BrickBreakSteps` | 8 | The four steps of a brick wall breaking. `$BE94` calls BrickBreakSteps[`$AB34`] once a frame while `$AB33` is set: `$BEBB`, `$BF19`, `$BF60`, `$BFA7` (1476 calls). | `BrickStep` (`stage1/rzx/l01`) | - |
| `$C53C` | `CrumbleSteps2` | 8 | The steps of a type-2 platform turning into type 3. Set by `$C3D5` (`$AB22`); `$C1C3` writes the new type (`$B8C2`: `$AA6B`[`$AB1B`] = `$AB20` = 3), the others redraw. Witness: StartWearTo3 L1 250. | `PlatformChangeStep` (`stage1/menu`) | - |
| `$C544` | `CrumbleSteps3` | 8 | The steps of a type-3 platform turning into type 4. Set by `$C3F8` (StartWearTo4 L1 394); the new type `$AB20` = 4. | `PlatformChangeStep` (`stage1/menu`) | - |
| `$C54C` | `CrumbleSteps4` | 18 | The steps of a type-4 platform vanishing. Set by `$C41B` (StartFallAway L1 783); the new type `$AB20` = 0, no platform; the last step `$C24C` clears `$AA14` and `$AA15`. | `PlatformChangeStep` (`stage1/rzx/l02`) | - |
| `$C55E` | `FireOutLeft` | 16 | The steps of the water putting out a fire, the ball moving left. LeftStep9 `$C9CE` starts it (`$AB27`, `$AB26` = 0, `$AB29` the cell's screen address, `$AB2B` = 1) when the ball reaches a burning platform (type 8 or 9) and holds a water drop. | `WaterStep` (`stage1/rzx/l00`) | - |
| `$C56E` | `FireOutRight` | 16 | The same, the ball moving right. Started by RightStep9 `$CC11`. | `WaterStep` (`stage1/rzx/l08`) | - |
| `$C57E` | `FireOutDown` | 18 | The same, the ball falling onto the burning platform below. Started by DownStep0 `$CE24`. | `WaterStep` (`stage1/menu`) | - |
| `$C590` | `LeftoverWord` | 2 | `$B1CB`, a word nothing reads. Known only from the recordings: no read. It would be a tenth step of FireOutDown (`$B1CB` is inside the burst animation `$B1A7-$B1E6`). | - | - |
| `$C592` | `LockOpenSteps3` | 4 | The two steps of a lock of type 3 opening to type 2. The ball hits the lock with a key: `$AA1A` points here, `$C43E` plays it (`$AA1C` the step, `$AA1D` active). `$C464`: sound `$F43E`, XOR out the type-3 picture, XOR the flash picture; `$C46E`: XOR the flash picture off, draw the type-2 picture, stop. | `WallStep` (`stage1/rzx/l01`) | - |
| `$C596` | `LockOpenSteps2` | 4 | The two steps of a lock of type 2 opening to type 1. `$C476` (sound `$F455`, XOR out the type-2 picture, flash), `$C480` (flash off, draw the type-1 picture, stop). | `WallStep` (`stage1/rzx/l01`) | - |
| `$C59A` | `LockOpenSteps1` | 14 | The seven steps of a lock of type 1 opening for good. `$C488` (sound `$F46C`, XOR out the type-1 picture, flash), `$C492` (flash off, store `$7FDC`), then `$800C`, `$803C`, `$806C`, `$809C` and the blank `$6708` stored over the wall's place (`$AA18`): the lock falls away. 97 openings in the recordings. | `WallStep` (`stage1/menu`) | - |
| `$C5A8` | `PlatformDrawTable` | 26 | The routine that draws each platform type 0-12 when the level is built. BuildLevel's cell loop (`$CFC8`) jumps to PlatformDrawTable[type]; each routine draws at the cell's screen address `$AB2D` and goes on to BuildLevelObject `$CFF4`. Type 0 and type 11 (the exit) draw nothing: the exit appears only when OpenExit `$BCB9` writes it. | `BuildLevelCell` | - |
| `$C5C2` | `WallDrawTable` | 10 | The routine that draws each wall type 0-4 when the level is built. BuildLevelObject jumps to WallDrawTable[`$AA8F`[cell]]; each goes on to BuildLevelNextCell `$D047`. | `BuildLevelObject` | - |
| `$C74E` | `ScanInRow` | 1 of 4 | The line within the character row (0-7) | `DrawSprite`, `LeftStep5`, `LineAddress`, `PaintAttrs`, `RightStep5` +2 | `PaintAttrs`, `ScreenAddrToLine` |
| `$C74F` | `CharRow` (`ScanInRow`+1) | 1 | The character row | `PaintAttrs` | `PaintAttrs`, `ScreenAddrToLine` |
| `$C750` | `ByteColumn` (`ScanInRow`+2) | 1 | The byte column (0-79) | `DrawSprite`, `LeftStep5`, `LineAddress`, `PaintAttrs`, `RightStep5` +2 | `ScreenAddrToLine` |
| `$C751` | `PixelLine` (`ScanInRow`+3) | 1 | The pixel line, row x 8 + line | `LineAddress` | `ScreenAddrToLine` |
| `$C774` | `DivQuotient` | 2 of 4 | The quotient of the last division | - | `DivideHLbyBC` |
| `$C776` | `DivRemainder` (`DivQuotient`+2) | 2 | The remainder | - | `DivideHLbyBC` |
| `$D2B4` | `PanelPicture` | 3600 | A picture of 18 bytes x 200 lines in CPC mode 1, never read. Only DrawPanelA and DrawPanelB (never called) would read it. 3600 bytes, `$D2B4-$E0C3`. | - | - |
| `$E131` | `CellAddresses` | 72 | The CPC screen address of each cell 0-35 (36 words). `$BB05` sets `$AB2D` = the word for the ball's cell `$AA44`; the fire put-out code reads it too. Rows are `$140` bytes (`$C942`, `$CA82`, `$CBC2`, `$CD02`, `$CE42`, `$CF82` for column 0), columns 10 bytes apart. Words that only look like program addresses. | `AnimateFires`, `CellScreenAddr`, `DownStep0` (`stage1/menu`), `LeftStep9` (`stage1/rzx/l00`), `OpenExit` (`stage1/menu`) +1 | - |
| `$E179` | `WallAddresses` | 72 | The CPC screen address of each wall 0-35 (36 words; the sixth of each row is 0). `$BB1D` sets `$AB2F` = the word for wall A. Wall N is between cell N and cell N + 1; the last of each row has no wall. | `WallScreenAddr`, `AnimateWalls` (`stage1/menu`) | - |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B730` | `HudRowAttrs` | 20 of 23 | The attributes of the HUD row (top line), read by PaintHudAttrs. 20 attributes: 5 of `$07` (white on black) for `$5803-$5807`, then five groups of three, each one coloured icon cell (`$46` bright yellow, `$45` bright cyan, `$45`, `$46`, `$42` bright red) and two white digits. Each group is the icon and number of one HUD field (known only from the code which field is which: `$E5A1-$E5F9` print them). Three `$C9` (RET) bytes no code reads or runs: part of the row of RET stubs that ends at `$B754` (see FirmwareStub `$B747`). | `PaintHudAttrs` | - |
| `$B744` | `HudRowAttrsEnd` (`HudRowAttrs`+20) | 3 | three unread `$C9` bytes before FirmwareStub | - | - |

## hiscore

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$ED18` | `NameLetterPtr` | 2 | EnterName: the address of the letter being chosen | `EnterName` (`stage2/rec/twoname`) | `EnterName` (`stage1/gameover`) |
| `$ED93` | `NewRecordPtr` | 2 | The hall-of-fame record the last game entered | `EnterName` (`stage1/gameover`), `ScoreToDigits` (`stage1/gameover`) | `EnterHallOfFame` (`stage1/gameover`) |
| `$EDE1` | `HofLineRows` | 14 | The lines of DrawHofLines: 0, 2, 5, 8, 12, 17, 23, 30, 38, 48, 60, 73, 87, then `$FF` | `DrawHofLines` (`stage1/menu`) | - |
| `$EDEF` | `HofTitleText` | 196 | The hall of fame screen: coloured bars, "B U M P Y" and "H A L L  O F  F A M E" (PrintText) | `PrintText` (`stage1/menu`) | - |
| `$EEB3` | `HallOfFame` | 128 | The hall of fame: four records of 32 bytes, PrintText strings with the score word. Each record: `$16` row col (AT; the row is set by PrintHallOfFame), `$14` `$0F` (attribute), `$02` (double height), three letters, " : ", five digits, `$00`, then the score as a word (+`$12`) and 12 zeros. The tape's table: PAP 16000, PEP 08000, PIP 04000, POP 01700. | `EnterHallOfFame` (`stage1/gameover`), `EnterName` (`stage2/rec/twoname`), `GameOver` (`stage1/gameover`), `PrintText` (`stage1/menu`), `ScoreToDigits` (`stage1/gameover`) | `EnterHallOfFame` (`stage1/gameover`), `EnterName` (`stage1/gameover`), `PrintHallOfFame` (`stage1/menu`), `ScoreToDigits` (`stage1/gameover`) |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BA3D` | `ObjectHandlers` | 10 | The handlers of object kinds 0-4, jumped to by TakeObject. TakeNothing `$B9BE`, TakeHammer `$B9FD`, TakeKey `$B9BF`, TakeWater `$B9DE`, TakeBottle `$BA1C`. | `TakeObject` | - |
| `$C6F6` | `ObjectInks` | 41 | The Spectrum attribute each object kind 0-40 is drawn with. BuildLevelObject `$CFF4` draws object kind K (sprite `$6CB0` + 56 K, 14 lines of 4 bytes) with ink ObjectInks[K] (it patches the displacement of LD C,(IX+d) at `$D01B`). Kind 0 is no object and is never read. The values are attributes: `$45` bright cyan, `$46` bright yellow, `$44` bright green, `$42` bright red, `$43` bright magenta, `$06` yellow and so on. | `BuildLevelObject` | - |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E3E4` | `SpriteHeight` | 1 | The height in lines of the last sprite drawn (PaintAttrs takes it) | `PaintAttrs` | `DrawSprite`, `PaintAttrs`, `XorSprite`, `XorBricks` (`stage1/rzx/l40`) |

## text

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E712` | `TextVars` | 1 of 5 | The printer's state: default attribute, attribute, double height, row, column | `ClearScreen`, `DrawGlyph`, `PrintText`, `NextColumn` (`stage1/menu`), `NewLine` (code) | `DrawGlyph`, `PrintText`, `NextColumn` (`stage1/menu`), `NewLine` (code) |
| `$E713` | `TextAttr` (`TextVars`+1) | 1 | the attribute of the next characters | `DrawGlyph`, `PrintText` | `PrintText` |
| `$E714` | `TextDouble` (`TextVars`+2) | 1 | 0 single height, 1 double height | `DrawGlyph` | `PrintText` |
| `$E715` | `TextRow` (`TextVars`+3) | 1 | the character row 0-23 (AT's first byte) | `DrawGlyph`, `NextColumn` (`stage1/menu`), `NewLine` (code) | `PrintText`, `NextColumn` (`stage1/menu`), `NewLine` (code) |
| `$E716` | `TextColumn` (`TextVars`+4) | 1 | the column 0-31 (AT's second byte) | `DrawGlyph`, `NextColumn` (`stage1/menu`) | `DrawGlyph`, `PrintText`, `NextColumn` (`stage1/menu`), `NewLine` (code) |
| `$E7CD` | `OnceUponATimeText` | 25 | "Erase Una Vez ..." ("once upon a time", Spanish): CPC LOCATE 2,10, attribute `$38`, single then double height | - | - |
| `$F5C9` | `Font` | 768 | The font: characters 32-127, 8 bytes each; 123-127 the status-line icons of lives, water, keys, hammers and level | `DrawGlyph`, `PrintHudGlyph`, `HudBlit` (`stage1/rzx/l36`) | - |
| `$F8C9` | `FontTail` | 11 | 11 zeros to the end of the code block | - | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F1B8` | `UnusedF1B8` | 16 | 16 bytes: seven NOPs, `$FF` and eight NOPs | - | - |
| `$F206` | `LineTableArea` | 35 | 35 bytes where BuildLineTable writes: a shifted copy of the code `$F1E1-$F205` | - | - |
| `$F229` | `UnusedF229` | 282 | 282 zeros | - | - |
| `$F383` | `UnusedF383` | 5 | 5 bytes: LD HL,`$F38A` and two NOPs, never run | - | - |
| `$F3CF` | `SfxLandParams` | 16 | SfxLand's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F3E6` | `SfxHitParams` | 16 | SfxHit's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; on the 48K only the address's low byte `$E6` is used, as RomNoise's start in the ROM | - | - |
| `$F3FD` | `SfxPickupParams` | 16 | SfxPickup's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F417` | `SfxExtraLifeParams` | 16 | SfxExtraLife's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F42E` | `SfxWaterDropParams` | 16 | SfxWaterDrop's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F445` | `SfxWallBounceParams` | 16 | SfxWallBounce's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F45C` | `SfxLockAParams` | 16 | SfxLockA's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F473` | `SfxLockBParams` | 16 | SfxLockB's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F48A` | `SfxFireDeathParams` | 16 | SfxFireDeath's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F4A4` | `SfxLevelEndParams` | 16 | SfxLevelEnd's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F4BB` | `SfxSpikeDeathParams` | 16 | SfxSpikeDeath's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F4D2` | `SfxLifeLostParams` | 16 | SfxLifeLost's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F4E9` | `SfxBrickCrumbleParams` | 16 | SfxBrickCrumble's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |
| `$F500` | `SfxTimerTickParams` | 16 | SfxTimerTick's AY register image: R0-R13 and two zeros, the block WriteAyRegisters `$F190` would write; unread on the 48K | - | - |


## The tape's BASIC (`src/tape/basic.json`)

Bumpy, Loriciels 1989: tape block 2, the BASIC program "BUMPY" (191 bytes at PROG `$5CCB`, LINE 10): hides the tape
messages, CLEAR 24999, `LOAD "" SCREEN$`, LOAD "" CODE 25000 and RANDOMIZE USR 43900. Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic.json`; the
readers and writers from `work/stage1/c1`.

### The tape's BASIC: basic

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine10` | 191 | BASIC line 10: POKE 23624,0: POKE 23693,0: POKE 23607,128: CLEAR 24999: `LOAD "" SCREEN$`: PRINT: BRIGHT 1: OVER 1: PAPER 5: {INK 0} LOAD "" CODE 25000: POKE 23607,60: POKE 23685,0: RANDOMIZE USR 43900. The whole program (the header's program length 191 covers it all): the line number 10 (two bytes, high byte first), the line's length (187, low byte first), then thirteen statements split by ":" (`$3A`) and closed by ENTER (`$0D`). POKE 23624,0 sets BORDCR (a black border and lower screen) and POKE 23693,0 ATTR_P (black on black). POKE 23607,128 moves the high byte of CHARS from `$3C` to `$80`: the ROM's messages ("Bytes: BUMPY.SCR", "Bytes: BUMPY.CDE") then print with the font read from RAM at `$8100-$83FF`, which holds zeros before the code block loads, so they print blank. CLEAR 24999 puts RAMTOP at `$61A7`, one byte below the code block (GameBlock `$61A8`). `LOAD "" SCREEN$` loads the loading screen (tape blocks 3 and 4) at `$4000`; PRINT, BRIGHT 1, OVER 1 and PAPER 5 make the next message (OVER 1, a blank font) leave the picture alone (known only from the code: the message is not seen in c1's shots). The two bytes `$10` `$00` before LOAD are an embedded INK 0 control, which the interpreter skips (the ROM's character fetch passes over colour controls and their parameter); in a LIST it inks the rest of the line black. LOAD "" CODE 25000 loads tape blocks 5 and 6 at `$61A8`. POKE 23607,60 puts CHARS back at `$3C00`, POKE 23685,0 clears the high byte of DF_CC (known only from the code: nothing prints after it), and RANDOMIZE USR 43900 calls GameStart `$AB7C`, which never returns. | - | - |


## The loading screen (`src/screen/screen.json`)

Bumpy, Loriciels 1989: tape block 4, the loading screen BUMPY.SCR, loaded by the BASIC's `LOAD "" SCREEN$` at
`$4000`. Its entries are `src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part
src/screen/screen.json`; the readers and writers from `work/stage1/c1`.

### The loading screen: screen

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$4000` | `LoadingScreen` | 6912 | The loading screen: 6144 bytes of pixels, 768 of attributes. Witness: c1 loads it at `$4000` (work/stage1/c1/screens/001182-loading-2.png); it stays on screen through the load of the code block. | - | - |
