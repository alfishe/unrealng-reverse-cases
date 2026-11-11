# 11. Data reference

Every data entry of the game image `$6D60`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/game`, local and not in the repository), and, marked
"(code)", the routines whose `LD` through `(nn)` reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6E16` | `SoundIsAy` | 1 | The sound flag: 0 on a 48K (the beeper), non-zero on a 128K (the AY), set by the machine test of Start. Written once by Start (`$6D69`). Read by BeeperNoise `$7C26` and BeeperSweep `$7C3C` (return at once when set), MainMenu `$6DC5` (no beeper title tune), DrawSparkle `$6F23` (the AY music tick) and `$9597`. | `BeeperNoise`, `Delay`, `DrawSparkle`, `MainMenu`, `BeeperSweep` (code) +1 | `Delay`, `Start` |
| `$6E17` | `MenuText` | 146 | The main menu text (a print string of `$AF2B`: control codes inside, `$FF` ends). Printed by MainMenu at `$6DB2` and again at `$6E06` after a control change. `$E8` 01 first: every printed cell is marked 1 in the occupancy map `$6100`, so MenuSparkles keeps the stars off the text. Then the logo (LogoText `$70FF` at row 0 column 8), the font `$D7E0`, BY  RAFFAELE CECCO in attribute `$44` at row 7, the options from row 11 column 9 two rows apart (the digit in bright magenta, the text in bright cyan), the copyright in bright red at row 23 column 2. The print codes (`$AF2B`): below `$61` a character; `$61-$8F` a move (rows + code - `$78`, columns + the next byte); `$90-$CE` the next row, columns + code - `$AF`; `$CF-$DE` the ink (code - `$CF`, 8 and up bright); `$DF` row column; `$E0` the attribute; `$E1` n ... `$E2` a repeat; `$E3` a sub-string at the word; `$E4` / `$E5` n char repeated across / down; `$E6` the font address; `$E7` a space; `$E8` n the occupancy value; `$E9` / `$EA` the foreground value 0 / `$FF`; `$EB`; anything else ends. | `Delay`, `PrintString` | `Delay` |
| `$6F4D` | `AyTickCount` | 1 | Counts the star draws 0-3 on a 128K: the AY title music steps when it wraps (DrawSparkle) | `Delay`, `DrawSparkle` (code) | `Delay`, `DrawSparkle` (code) |
| `$6F4E` | `SparkleFrames` | 16 | The star's 16 frames, indexed by the frames left (16 first, 1 last): 16x16 sprites `$0C-$0F`, then 0. MenuSparkles reads SparkleFrames[n] for n = 16 down to 1 (`$6F4D` + n): `$0C` `$0C` `$0E` `$0D` `$0E` `$0E` `$0F` `$0F` `$0F` `$0E` `$0E` `$0D` `$0D` `$0C` `$0C`, then sprite 0, which is blank (`$F8E0`: 32 zero bytes). The blank last frame matters: the next place's first draw erases the buffer's image at its own position, so the buffer must hold nothing. | `Delay`, `MenuSparkles` | `Delay` |
| `$6F5E` | `SparkleSlots` | 37 | The 12 star slots: x (2-pixel steps), y (pixels), frames left (0 = free); `$FF` ends. Cleared by ClearMenuStars `$6F83` (36 bytes), walked by MenuSparkles. The end mark at `$6F82`. | `ClearMenuStars`, `Delay`, `MenuSparkles` | `ClearMenuStars`, `Delay`, `MenuSparkles` |
| `$705B` | `KeyNames` | 48 | The key names DefineKeys prints: a one-character slot, SPACE, ENTER, CAPS SHIFT, SYMBOL SHIFT. Print strings of `$AF2B`. Each name ends with a move (`$7A` n: two rows down, n columns back) to the next answer's column, then `$FF`. The first slot's character is overwritten with the key's ASCII (`$701E`) before the print ("?" in the image). | `Delay`, `PrintString` | `DefineKeys`, `Delay`, `DefineKeySymbolShift` (code) |
| `$708B` | `TypedKeys` | 5 | The five ASCII codes typed in DefineKeys, compared with CheatWord | `DefineKeys`, `Delay`, `PrintString` | `DefineKeys`, `Delay` |
| `$7090` | `CheatWord` | 5 | ZORBA: the five keys that toggle the infinite lives (ZorbaCheat) | `DefineKeys`, `Delay`, `PrintString` | `Delay` |
| `$7095` | `DefineKeysText` | 102 | The define keys screen: the logo, SELECT KEY FOR...., LEFT RIGHT JUMP DUCK FIRE, the copyright. Printed by DefineKeys. The logo (LogoText) at row 0 column 8, attribute `$46`, SELECT KEY FOR.... at row 6 column 7, the five prompts in bright white from row 9 column 7 two rows apart, nine spaces down column 15 (the answers' column cleared), the copyright in bright red at row 23. | `Delay`, `PrintString` | `Delay` |
| `$70FB` | `FontResetText` | 4 | A sub-string that only sets the font to `$D7E0`: no string or code refers to it | `Delay`, `PrintString` | `Delay` |
| `$70FF` | `LogoText` | 70 | The EXOLON logo: glyphs 0-`$31` of the logo font at `$E6B0`, two blocks of 8x3 characters and two more below. A sub-string (`$E3`) of MenuText, DefineKeysText, HallOfFameScreen and the texts at `$A185`, `$A990`, `$AA6E`. Sets the font to `$E6B0` and the attribute `$47`: glyphs 0-7 bright white, 8-15 bright yellow, `$10-$17` yellow (the left half, three rows), then two rows back up for `$18-$2F` (the right half, same colours), then glyphs `$30-$31` one row down and two columns in from the right half's start. The caller sets the font again after it. | `Delay`, `PrintString` | `Delay` |

## hiscore

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$718D` | `HallOfFameScreen` | 99 | The Hall of Fame screen: the logo, the score columns' attribute, twelve planet pictures round the edges. Printed by HallOfFameRoll. The logo at row 0 column 8; attribute `$43` and the font `$D7E0`; 19 rows of 8 spaces from row 4 column 16 (columns 16-23: the scores' side); then twelve sub-strings drawing the planets of the screen at the edges: `$8A07` at 0,0 / 5,3 / 21,26, `$8671` at 1,5 / 16,4 / 18,30, `$864F` at 10,0 / 0,26, `$8A9D` at 19,1 / 14,26, `$8A75` at 5,26, `$8A85` at 9,28 (the pictures are in the screen graphics strings). h1 screens.png: the roll between the planets. | `Delay` | `Delay` |
| `$71F0` | `ShowHallOfFame` | 1 | 1 after a name entry: Start shows the Hall of Fame before the menu. Set by `$A13A` after the name, read by Start (`$6D9A`), cleared by ShowHallOfFameFirst. | `Delay`, `Start` | `Delay`, `HofMakeRoom` (code), `ShowHallOfFameFirst` (code) |
| `$71F1` | `HallOfFame` | 817 | The Hall of Fame: 50 entries of 16 bytes (a name of 10 characters, the score in 6 ASCII digits), `$FF` ends. Highest first. The image holds RAFFAELE, SURYANI, SCRAGGY, SABATTA!, PADDY, LOFTY, ... HUMPTY, all 001000. `$A073` compares the score `$AD8A` with the +10 digits entry by entry, moves the lower entries down 16 bytes (LDDR from `$7510` to `$7520`: the last entry is pushed into `$7511-$7520`) and writes the end mark at `$7511` again, then the new score; the name entry fills the 10 name bytes. HallOfFameRoll prints the entries 16 characters at a time; its scroll leaves columns 16-17 (the name's 9th and 10th characters) where they were printed, so a name longer than 8 characters keeps those two letters on row 23 only. | `Delay`, `HofDigitLoop`, `HofEntryLoop` | `Delay`, `HofMakeRoom` (code) |
| `$7588` | `HallOfFamePtr` | 2 | The next Hall of Fame entry to print (PrintNextHallEntry; HallOfFameRoll sets it to HallOfFame) | `Delay`, `PrintNextHallEntry` (code) | `Delay`, `HallOfFameRoll` (code), `PrintNextHallEntry` (code) |

## mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$768C` | `PassCount` | 2 | The main loop's pass count (8 bits): its low 3 bits cycle the flashing colours of `$912A` and `$ABE8`. Raised once a MainLoop pass (`$767E`). | `ColourCycle`, `Delay`, `KillPlayer`, `StartGame`, `ForceFieldStep` (code) | `BuildScreen`, `Delay`, `KillPlayer`, `StartGame` |
| `$768D` | `ImmunityCount` (`PassCount`+1) | 1 | passes of immunity left after a restart: set to `$42` by the death at `$9CCF`, zeroed by the screen build `$849E`; while non-zero `$9CB4` returns before the hit test (the ZXDB immunity POKE is the RET at `$9CB8`) | `Delay`, `KillPlayer`, `StartGame` | `BuildScreen`, `Delay`, `KillPlayer`, `StartGame` |
| `$76A2` | `HudText` | 56 | The HUD text: the labels on row 22 in their colours, row 23 cleared, the score sub-string `$AD82`. AT 22,0, the font `$D7E0`, the occupancy value 1 and the foreground value 0 for these cells (`$E8` 01, `$E9`), AMMO bright cyan, GRENADES bright yellow, POINTS bright green, LIVES bright white, ZONES bright magenta; AT 23,0, 32 spaces, then the sub-string `$AD82` (the score digits `$AD8A` at their place). | `Delay`, `PrintString` | `Delay` |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$78CA` | `BigShiftJumps` | 16 | DrawBigSprite's shift routines by (2x AND 7): 0, right 1-3, left 4-1. Entry n for a right shift of n pixels: `$7760` (0), `$7758`, `$7750` (2), `$7748`, `$7719` (4: four left), `$7721`, `$7729` (6: two left), `$7731`. Only the even entries are used. | `Delay`, `DrawBigSprite` | `Delay` |
| `$78DA` | `SpriteSavedSP` | 2 | The caller's SP while a sprite routine reads with POP (DrawBigSprite, DrawSprite, ScrollHallOfFame, `$931C`, `$9355`) | `BigSpriteMask`, `Delay`, `DrawSmallSprite`, `ShiftNone`, `ScrollHallOfFame` (code) +1 | `BigSpriteMask`, `Delay`, `DrawBigSprite`, `DrawSmallSprite`, `DrawSprite` +3 |
| `$78DC` | `ShiftBuffer` | 128 | The shifted and masked sprite image: 32 lines of 4 bytes (DrawBigSprite) or 16 lines of 3 (DrawSprite) | `BigMaskRows`, `BigSpriteMask`, `Delay`, `MaskRows`, `ShiftNone` | `BigMaskRows`, `BigShiftLeft2`, `BigShiftNone`, `Delay`, `MaskRows` +1 |
| `$7AD9` | `SpriteShiftJumps` | 16 | DrawSprite's shift routines by (2x AND 7): 0, right 1-3, left 4-1. `$79C2` (0), `$79BD`, `$79B8` (2), `$79B3`, `$7994` (4: four left), `$7999`, `$799E` (6: two left), `$79A3`. Only the even entries are used. | `Delay`, `DrawSprite` | `Delay` |

## input

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7B92` | `ControlLeft` | 7 | The controls as ReadControls left them: 1 = pressed. Left | `ClearControls`, `Delay`, `ExoSuitBooth`, `Fall`, `FireControl` +8 | `ClearControls`, `DefineKeys`, `Delay`, `MainMenu`, `ReadInterface2` +2 |
| `$7B93` | `ControlRight` (`ControlLeft`+1) | 1 | right | `ClearControls`, `Delay`, `Fall`, `Walk` (code) | `ClearControls`, `Delay`, `ReadInterface2`, `ReadKempston` |
| `$7B94` | `ControlJump` (`ControlLeft`+2) | 1 | jump (up) | `ClearControls`, `Delay`, `ExoSuitBooth`, `MovePlayer`, `Teleports` | `ClearControls`, `Delay`, `ReadInterface2`, `ReadKempston` |
| `$7B95` | `ControlDuck` (`ControlLeft`+3) | 1 | duck (down) | `ClearControls`, `Delay`, `MovePlayer` | `ClearControls`, `Delay`, `ReadInterface2`, `ReadKempston` |
| `$7B96` | `ControlFire` (`ControlLeft`+4) | 1 | fire: read by `$8347` (the fire hold count `$83DC`), WaitKeyOrFire and the bonus screen | `Delay`, `FireControl`, `BonusScreen` (code), `WaitKeyOrFire` (code) | `ClearControls`, `Delay`, `ReadInterface2`, `ReadKempston` |
| `$7B97` | `ControlType` (`ControlLeft`+5) | 1 | the control type: 0 keyboard (ReadKeyboard), 1 Interface 2, 2 Kempston; set by the menu keys 3-5, 0 by DefineKeys | `Delay`, `HighlightControl`, `MainMenu`, `ReadControls` | `DefineKeys`, `Delay`, `MainMenu` |
| `$7B98` | `ControlSpare` (`ControlLeft`+6) | 1 | written 0 by `$8343`, read by nothing | `Delay` | `Delay`, `FireControl` (code) |
| `$7BDA` | `PlayerFlipped` | 1 | 1 while the player's frames are mirrored (facing left), toggled by FlipPlayerFrames | `Delay`, `Fall`, `FlipPlayerFrames`, `PlayerDeath`, `StartGame` +1 | `Delay`, `FlipPlayerFrames` |

## tunes

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7D67` | `TitleTunePending` | 1 | 1 from Start to the first menu: the title tune is still to play (MainMenu clears it) | `Delay`, `MainMenu` | `Delay`, `MainMenu`, `Start` |
| `$7D68` | `JingleTune` | 59 | A short tune of 19 notes (length, note, note) and its end: the cheat's and GAME OVER's jingle. Notes 18 x (15, n, m): falling arpeggios over the notes `$1C-$17`, then (45, `$1C`, `$28`); a length 0 ends. PlayTune from ZorbaCheat and `$A030` (GAME OVER). | `Delay`, `PlayTune` | `Delay` |
| `$7DA3` | `TitleTune` | 587 | The 48K title tune: 195 notes (length, note, note), lengths 18 to 90 in steps of 18, notes up to 50. PlayTune from MainMenu at the first menu after each entry to Start on a 48K, any key cuts it. The note numbers index the period table `$8062` (53 entries). | `Delay`, `PlayTune` | `Delay` |
| `$7FEE` | `TuneNoteLength` | 3 | The current note's length (PlayTune), passed in A to the tone routine | `Delay`, `PlayTune`, `PlayTuneNote` (code), `PlayTuneRest` (code) | `Delay`, `PlayTune` |
| `$7FEF` | `TunePointer` (`TuneNoteLength`+1) | 2 | the next note of the tune (PlayTune), a word | `Delay`, `PlayTune` | `Delay`, `PlayTune` |
| `$8062` | `NoteReloads` | 53 | The counter reload of each note: 53 notes a semitone apart, lowest first. PlayTwoTones counts from the reload value to 256, so the period of note n is 256 - NoteReloads[n] loop steps: 255, 240, 227, 215, 204, ... 13, 12. Successive periods differ by a factor 1.055-1.065 (a semitone is 1.0595): about four and a half octaves. Read by the tune player `$7D4E` (LD DE,`$8062` and LD BC,`$8062`, index the note number). The c1 load ran code at `$8063-$8096` at frame 1808 (the loading screen's depacker that lived here before the game was moved in); in the game these bytes are only read. | `Delay`, `PlayTune` | `Delay` |

## player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$80A8` | `OpenMapCell` | 25 | Code that never runs: HL = the open-cell map (`$5B00`) address of pixel position D, E. The same as BlockMapCell `$80C1` with the base `$5B00`: column = E / 4, row = D / 8, HL = `$5B00` + 32 row + column; AF and DE kept. No instruction in the image calls or jumps to `$80A8` and no recording ran it: a left-over. The sprite drawers `$777F` and `$79DD` compute the same address inline. Bytes F5 D5 7B E6 7C 0F 0F 5F 7A E6 F8 0F 0F 0F 57 CD 97 80 11 00 5B 19 D1 F1 C9: PUSH AF, PUSH DE, LD A,E, AND `$7C`, RRCA, RRCA, LD E,A, LD A,D, AND `$F8`, RRCA x3, LD D,A, CALL CellOffset, LD DE,`$5B00`, ADD HL,DE, POP DE, POP AF, RET. A `c` entry is refused by mkgame ("the recordings say data"): c1's L1 (the read build) also covers the load, whose depacker read these addresses at frame 1808, and those reads stop the static walk. | `Delay`, `TwoTonesNext` | `Delay` |
| `$8269` | `PlayerFrameShown` | 1 | The frame number last drawn; `$FF` forces a redraw (also JumpSteps' unused entry 0). Written by DrawPlayer, set to `$FF` by the game start `$7593`, NextScreen, the turn (`$82E8`) and the pod pick-ups `$9989` / `$99DF`. MovePlayer reads the jump table from `$8269` + JumpStep with JumpStep 1-22, so this byte is never a jump step. | `Delay`, `PlayerFrame`, `TwoTonesNext`, `DrawPlayer` (code), `Pods` (code) | `Delay`, `Fall`, `PlayerFrame`, `StartGame`, `DrawPlayer` (code) +3 |
| `$826A` | `JumpSteps` | 22 | The jump's Y steps, read from step 22 down to 1: up 18 pixels, then down 18. Read backwards (JumpStep 22 first): -4, -4, -2, -2, -2, -1, -1, -1, -1, 0, 0, 0, 0, +1, +1, +1, +1, +2, +2, +2, +4, +4. A value below `$0A` is a fall step (TestBelow), above an up step (TestAbove); 0 moves only sideways. | `Delay`, `MovePlayer`, `PlayerFrame`, `TwoTonesNext`, `DrawPlayer` (code) | `Delay` |
| `$8294` | `FallFlag` | 1 | 9 while the player falls (the fall's frame number), 0 on the ground | `Delay`, `MovePlayer`, `TwoTonesNext` | `Delay`, `Fall` |
| `$82F2` | `ScreenChanged` | 1 | Not 0: the player left the screen on the right this pass (NextScreen stores Y). Cleared by MovePlayer each pass; ScreenChangeCheck `$8485` builds the next screen when it is set. | `Delay`, `ScreenChangeCheck`, `TwoTonesNext` | `Delay`, `MovePlayer`, `NextScreen` (code) |
| `$82F3` | `RestartX` | 1 | The X the player restarts at after a death (`$9D3B`), 0 on each new screen, `$10` at the game start | `Delay`, `PlayerDeath`, `TwoTonesNext` | `Delay`, `StartGame`, `ScreenChangeCheck` (code), `ZoneRefill` (code) |
| `$82F4` | `RestartY` | 1 | The Y the player restarts at (`$70` at the start; the Y he entered the screen at). The respawn `$9D3B` drops the player from (RestartX, RestartY) to the ground (TestBelow, Y + 1). The round end `$A8D6` sets both from its restart table. | `Delay`, `PlayerDeath`, `TwoTonesNext` | `Delay`, `StartGame`, `NextScreen` (code), `ZoneRefill` (code) |
| `$82F5` | `PlayerX` | 1 | The player's X, 2 pixels a unit, 4 a column (`$10` at the start; `$80` = off the right edge) | `Delay`, `FireControl`, `KillPlayer`, `MovePlayer`, `MoveShots` +16 | `Delay`, `PlayerFrame`, `StartGame`, `DrawPlayer` (code), `ScreenChangeCheck` (code) +1 |
| `$82F6` | `PlayerY` | 1 | The player's Y in pixels, the top of the 32-pixel sprite (`$70` at the start: on the ground of screen 0) | `Delay`, `KillPlayer`, `MovePlayer`, `PlayerContact`, `PlayerDeath` +13 | `Delay`, `PlayerFrame`, `StartGame`, `DrawPlayer` (code), `FireControl` (code) +2 |
| `$82F7` | `JumpStep` | 1 | The jump's step 22-1, 0 when not jumping; cleared by the death `$9CC2` | `Delay`, `MovePlayer`, `TwoTonesNext` | `Delay`, `KillPlayer`, `MovePlayer`, `StartGame`, `ZoneRefill` (code) |
| `$82F8` | `MoveDir` | 1 | The horizontal move of this pass: 0, 1 right, `$FF` left; a jump keeps it | `Delay`, `Fall`, `MovePlayer`, `TwoTonesNext`, `Walk` (code) | `Delay`, `Fall`, `Walk` (code) |
| `$82F9` | `WalkPhase` | 1 | The walk frame 0-9, + 1 each step that moves | `Delay`, `Fall`, `TwoTonesNext`, `Walk` (code) | `Delay`, `Fall`, `Walk` (code) |
| `$82FA` | `Facing` | 1 | 1 right, `$FF` left: the shots' direction; 1 after a death (`$9D17`) | `Delay`, `SpawnShot`, `TwoTonesNext`, `GrenadeStart` (code) | `Delay`, `Fall`, `PlayerDeath`, `StartGame`, `Walk` (code) |
| `$82FB` | `CrouchOffset` | 1 | `$FA` (-6) while crouching, else 0: shots leave lower (`$13` below the top, not `$0E`). Read by SpawnShot `$83A7` and the grenade throw `$922D`. | `Delay`, `PlayerContact`, `SpawnShot`, `TwoTonesNext`, `ThrowGrenade` (code) | `Delay`, `MovePlayer` |
| `$83DC` | `FireHeld` | 1 | The passes the fire button has been held, 0 when up, at most `$FF`; 15 throws a grenade (`$9208`) | `Delay`, `FireControl`, `ThrowGrenade`, `TwoTonesNext` | `Delay`, `FireControl`, `KillPlayer` |
| `$845F` | `ShotList` | 25 | The player's shots: 8 slots of X, Y, direction (0 free, 1 right, `$FF` left). Written by SpawnShot, moved by MoveShots, cleared by ClearShots for each screen; read by the hit tests `$9B82`, `$9F71`, `$AC0F`. | `ClearShots`, `Delay`, `MoveShots`, `SpawnShot`, `TwoTonesNext` | `ClearShots`, `Delay`, `MoveShots`, `SpawnShot` |

## screens

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8523` | `ScreenNumber` | 1 | The screen 0-124 the player is on (ZONES); `$FF` during the round end. Set to 0 at the entry (`$6D75`), + 1 by NextScreen, read by BuildScreen and PrintZone. Screen 124 (`$7C`) left on the right is the round end (`$A867`). | `AliensSetUp`, `BuildScreen`, `Delay`, `PrintZone`, `TwoTonesNext` +3 | `Delay`, `Start`, `NextScreen` (code), `ZoneEnd` (code) |
| `$852E` | `ElementTable` | 124 | The 62 scenery elements: the address of each element's print string. BuildScreen prints element n (the third byte of a screen record) from ElementTable[n]. The strings are `$AF2B` print code (see exB.md): the font (code `$E6` and a word: each element has its own glyph set, `$DAB8-$EC48`), colour codes `$CF-$DE`, moves (`$61-$CE`, `$DF`), runs (`$E4` across, `$E5` down), loops (`$E1` / `$E2`) and calls of a shared string (`$E3`), the block map value of the following glyphs (`$E8` n), the open-cell value (`$E9` 0, `$EA` `$FF`), a mark without a glyph (`$EB` n), `$FF` the end. Entries 18 and 19 point at the same string (`$887E`); entries 8, 9, 56, 57 are only called by other elements; 18 is in no screen list. Names below are from the drawings (render.py) and the block map kinds the strings set (the kinds' handlers in exB.md). | `Delay`, `TableWord`, `TwoTonesNext` | `Delay` |
| `$85AA` | `ElementHatchDome` | 15 | 0: a yellow dome on the ground, 3 x 2 (screens 35, 39, 41, 50, 62, 68, 92, 110, 114, 116). Font `$DAB8`, solid. Always on the same screens as element 1. | `Delay`, `TwoTonesNext` | `Delay` |
| `$85B9` | `ElementDropPod` | 39 | 1: the green and yellow pod at the top of the screen, 5 x 3, with a jet cell (kind 2) and a kind 17 cell. Font `$DAB8`. Glyphs `$10` and `$14` have block value 2 (a jet below each: AnimateFlames), glyph `$12` value 17 (list `$ABCC`, the handler `$ABCF`). | `Delay`, `TwoTonesNext` | `Delay` |
| `$85E0` | `ElementLandingCraft` | 111 | 2: the landing craft with its legs and aerials, 11 x 8 (screen 0 and 4, 28, 75, 89, 98, 100, 103). Fonts `$DBE8` and `$DAB8`; two jet cells (kind 2) under its yellow engines. Drawn from 2 rows above its record's row. | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$864F` | `ElementPlanetRed4` | 34 | 3: a red planet in the sky, 4 x 4, not solid. Font `$DD38`, block value 0, open-cell value `$FF` (`$EA`): sprites pass in front. 32 screens. | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8671` | `ElementPlanetMagenta2` | 16 | 4: a small magenta planet, 2 x 2, not solid | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8681` | `ElementGunTurret` | 44 | 5: a gun turret on a white pedestal, 6 x 5; the barrel's first cell is kind 3 (AnimateTurrets). Font `$DDD8`. The barrel glyphs `$12`/`$13` (the first with block value 3, the turret's cell) are the turret's frame of state 2 (TurretFrames). | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$86AD` | `ElementRockA` | 31 | 6: a 4 x 3 block of the red and magenta rock (font `$DED8`), called by the ground rows | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$86CC` | `ElementRockB` | 32 | 7: rock block, 4 x 3 | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$86EC` | `ElementRockC` | 32 | 8: rock block, 4 x 3 (only called by elements 10 and 14) | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$870C` | `ElementRockD` | 32 | 9: rock block, 4 x 3 (only called by elements 10 and 14) | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$872C` | `ElementRockGroundA` | 24 | 10: the red rock ground, 32 x 3: blocks 6, 7, 8, 9 twice (`$E1` 2 ... `$E2`) | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8744` | `ElementGantry` | 51 | 11: the green gantry on two legs with blinking red lights (kind 4), 11 x 10 (screen 0, 12, 44, 51, 100, 119). Font `$DF78`. Printed after `$E9` with block value 0: the whole gantry is scenery the player walks through. The 6 light cells (block value 4) blink through `$9118`; the legs are drawn by ElementGantryLeg (`$E3` `$8777`) twice. | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8777` | `ElementGantryLeg` | 25 | The gantry's leg (called twice by element 11): a yellow cap, 5 green rows, the foot | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8790` | `ElementMine` | 12 | 12: a small yellow mine on the ground, 2 x 1, kind 5 (list `$91B0`, `$9152`): many per screen. Font `$DAB8`; block value 5 on its first glyph. `$9152` makes it flicker in random colours and sets it off when the player comes along its row. | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$879C` | `ElementRockSpire` | 57 | 13: the yellow rock spire, 3 x 8 (screen 0, 16, 24, 25, 74, 75, 99, 100), font `$E018` | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$87D5` | `ElementRockGroundB` | 24 | 14: the red rock ground, 32 x 3: blocks 9, 8, 7, 6 twice | `Delay`, `TwoTonesNext` | `Delay` |
| `$87ED` | `ElementRadarDish` | 53 | 15: a radar dish on a white mast, 5 x 8, font `$E110` | `Delay`, `TwoTonesNext` | `Delay` |
| `$8822` | `ElementMissile` | 37 | 16: a white missile on its launch stand, 3 x 6, font `$E110` (often 3 in a row) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8847` | `ElementTeleportBooth` | 55 | 17: the cyan teleport booth, 4 x 6: kind 6 cells (list `$9930`, the teleport `$98BA`) and blinking kind 4 cells. Font `$E260`. The teleport `$98BA` reads up (`$7B94`) when the player stands in a booth. | `Delay`, `TwoTonesNext` | `Delay` |
| `$887E` | `ElementAmmoPod` | 17 | 18, 19: the white ammunition pod, 2 x 2, kind 7 (list `$99F2`): ammunition back to 99 (`$9942`). Font `$E2C0`. Entry 18 is the same string and no screen uses it. | `Delay`, `TwoTonesNext` | `Delay` |
| `$888F` | `ElementGrenadePod` | 17 | 20: the yellow grenade pod, 2 x 2, kind 8 (list `$99F5`): grenades back to 10 (`$9942`) | `Delay`, `TwoTonesNext` | `Delay` |
| `$88A0` | `ElementRingPedestal` | 57 | 21: a cyan ring on a yellow pedestal, 4 x 6, kind 9 cell inside the ring (list `$9B4B`, `$9B07`). Font `$E2E0`. The ring's inside is printed with code `$E7` (a space in the main font). | `Delay`, `TwoTonesNext` | `Delay` |
| `$88D9` | `ElementTrapMark` | 3 | 22: no picture: `$EB` 10 marks one cell of kind 10, a trap (list `$9C70`, `$9C15` / `$9C8B`). The ZXDB "traps" POKE is at `$9C15`. | `Delay`, `TwoTonesNext` | `Delay` |
| `$88DC` | `ElementGirderGreen` | 72 | 23: a green girder platform, 32 x 2 (font `$E380`) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8924` | `ElementRubbleGrey` | 36 | 24: a grey rubble column, 3 x 5, not solid | `Delay`, `TwoTonesNext` | `Delay` |
| `$8948` | `ElementPylonGreen` | 30 | 25: a green lattice pylon, 3 x 7, not solid (font `$DF78`) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8966` | `ElementTwinLauncher` | 40 | 26: the green and white twin launcher, 4 x 3: cells of kinds 11 and 14 (lists `$9DC1` and `$A333`). Font `$E448`. | `Delay`, `TwoTonesNext` | `Delay` |
| `$898E` | `ElementRubbleMagenta` | 40 | 27: a magenta rubble column, 3 x 5, not solid (screens 12-21) | `Delay`, `TwoTonesNext` | `Delay` |
| `$89B6` | `ElementThruster` | 20 | 28: a yellow thruster cone hanging under a platform with a jet below (kind 2), 3 x 3. Font `$E4D8`. | `Delay`, `TwoTonesNext` | `Delay` |
| `$89CA` | `ElementExoBooth` | 61 | 29: the magenta exoskeleton booth, 4 x 7, kind 12 cell (list `$9F6E`): up in front of it puts the suit on or off (`$9F2D`). Screens 9, 34, 60, 90, 109. | `Delay`, `TwoTonesNext` | `Delay` |
| `$8A07` | `ElementPlanetGreen3` | 22 | 30: a green planet, 3 x 3, not solid | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8A1D` | `ElementSporePod` | 37 | 31: a green pod with spikes on top of a stand, 4 x 4, kind 13 cell (list `$A266`) that stays 13 in the block map. Font `$E600`. Always with element 32. | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8A42` | `ElementSporePodStand` | 32 | 32: the magenta stand under element 31, 3 x 5, not solid | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8A62` | `ElementFloorStripYellow` | 11 | 33: the yellow strip floor, 32 x 1 (font `$E840`) | `Delay`, `PrintString`, `TwoTonesNext` | `Delay` |
| `$8A6D` | `ElementWallStripYellow` | 8 | 34: a yellow strip column, 1 x 4 | `Delay`, `TwoTonesNext` | `Delay` |
| `$8A75` | `ElementPlanetYellow2` | 16 | 35: a small yellow planet, 2 x 2, not solid (screen 5) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8A85` | `ElementPlanetMagenta3` | 24 | 36: a magenta and red planet, 3 x 3, not solid | `Delay`, `TwoTonesNext` | `Delay` |
| `$8A9D` | `ElementPlanetCyan4` | 34 | 37: a cyan planet, 4 x 4, not solid | `Delay`, `TwoTonesNext` | `Delay` |
| `$8ABF` | `ElementGirderGrey` | 72 | 38: a grey girder platform, 32 x 2 | `Delay`, `TwoTonesNext` | `Delay` |
| `$8B07` | `ElementKind9Mark` | 3 | 39: no picture: `$EB` 9 marks a cell of kind 9 (list `$9B4B`), always in pairs | `Delay`, `TwoTonesNext` | `Delay` |
| `$8B0A` | `ElementPlanter` | 38 | 40: a green bowl of red rocks on a grey foot, 4 x 5 (font `$E860`) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8B30` | `ElementRockClump` | 39 | 41: a clump of the red rock, 5 x 3 (screen 22), fonts `$E860` and `$DED8` | `Delay`, `TwoTonesNext` | `Delay` |
| `$8B57` | `ElementSectorGate` | 30 | 42: the two tall pillars with yellow balls, 8 x 15: screens 24, 49, 74, 99, 124, the last of each 25. Font `$E940`. The pillars are ElementGatePillar (`$E3` `$8B75`) twice; `$EB` 15 marks a cell of kind 15 (list `$A814`, `$A7D6`) above each, `$EB` 16 one of kind 16 (list `$AAEF`, `$A817`) between them, by the cyan bar on the floor. | `Delay`, `TwoTonesNext` | `Delay` |
| `$8B75` | `ElementGatePillar` | 55 | A pillar of the sector gate: the ball, the neck, the green collar, the magenta column (called twice) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8BAC` | `ElementGatePost` | 19 | 43: a small green post with a magenta light (kind 4: it blinks), 2 x 3; beside the sector gate and on other screens | `Delay`, `TwoTonesNext` | `Delay` |
| `$8BBF` | `ElementTurretSlab` | 27 | 44: a gun turret lying on a slab, 6 x 2, barrel kind 3 (AnimateTurrets), fonts `$DDD8` and `$EA28` | `Delay`, `TwoTonesNext` | `Delay` |
| `$8BDA` | `ElementLauncherSlab` | 27 | 45: a twin launcher on a slab, 6 x 2, kinds 11 and 14 (as element 26) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8BF5` | `ElementMushroom` | 27 | 46: a green mushroom tree, 3 x 4 (font `$EAF0`) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8C10` | `ElementCanister` | 29 | 47: a yellow ribbed canister, 3 x 4, not solid (also the unit of element 50) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8C2D` | `ElementGirderDiagonal2` | 16 | 48: a white diagonal girder, 2 x 2, solid, open-cell value `$FF` | `Delay`, `TwoTonesNext` | `Delay` |
| `$8C3D` | `ElementGirderDiagonal3` | 17 | 49: a white diagonal girder, 3 x 3, solid, open-cell value `$FF` | `Delay`, `TwoTonesNext` | `Delay` |
| `$8C4E` | `ElementCanisterColumn` | 9 | 50: four canisters (element 47) one above the other, 3 x 16 | `Delay`, `TwoTonesNext` | `Delay` |
| `$8C57` | `ElementBallPillars` | 16 | 51: two short pillars with cyan balls below, 8 x 6 (screens 25, 66), each with an `$EB` 15 mark (kind 15). Font `$EBE8`; the pillars are ElementBallPillar (`$E3` `$8C67`). | `Delay`, `TwoTonesNext` | `Delay` |
| `$8C67` | `ElementBallPillar` | 30 | A pillar of element 51 (called twice) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8C85` | `ElementCircuitYellow` | 72 | 52: a yellow circuit-panel platform, 32 x 2 (font `$EC48`) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8CCD` | `ElementDoorCyan` | 38 | 53: a cyan door column, 3 x 5, not solid | `Delay`, `TwoTonesNext` | `Delay` |
| `$8CF3` | `ElementCircuitGreen` | 72 | 54: a green circuit-panel platform, 32 x 2 | `Delay`, `TwoTonesNext` | `Delay` |
| `$8D3B` | `ElementStripYellow4` | 11 | 55: a yellow strip, 4 x 1 (font `$E840`) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8D46` | `ElementRockCyanA` | 31 | 56: a 4 x 3 block of the green and cyan rock (font `$DED8`), only called by elements 60, 61 | `Delay`, `TwoTonesNext` | `Delay` |
| `$8D65` | `ElementRockCyanB` | 32 | 57: green and cyan rock block, 4 x 3, only called by elements 60, 61 | `Delay`, `TwoTonesNext` | `Delay` |
| `$8D85` | `ElementRockCyanC` | 32 | 58: green and cyan rock block, 4 x 3 (also on screen 76) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8DA5` | `ElementRockCyanD` | 32 | 59: green and cyan rock block, 4 x 3 (also on screen 76) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8DC5` | `ElementRockGroundC` | 24 | 60: the green and cyan rock ground, 32 x 3: blocks 56, 57, 58, 59 twice (screens 75-120) | `Delay`, `TwoTonesNext` | `Delay` |
| `$8DDD` | `ElementRockGroundD` | 24 | 61: the green and cyan rock ground, 32 x 3: blocks 59, 58, 57, 56 twice | `Delay`, `TwoTonesNext` | `Delay` |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8E5A` | `Ammo` | 1 | The ammunition 0-99 (99 at the start, after a death and at an ammunition pod); the ZXDB POKE 33646 is its DEC A (`$836E`) | `Delay`, `FireControl`, `PrintAmmo`, `TwoTonesNext` | `Delay`, `FireControl`, `PlayerDeath`, `StartGame`, `Pods` (code) +1 |
| `$8E66` | `Grenades` | 1 | The grenades 0-10 (10 at the start, after a death and at a grenade pod); POKE 37456 at `$9250` | `Delay`, `PrintGrenades`, `ThrowGrenade`, `TwoTonesNext`, `GrenadeStart` (code) | `Delay`, `PlayerDeath`, `StartGame`, `GrenadeStart` (code), `Pods` (code) +1 |
| `$8E7A` | `Lives` | 1 | The lives 0-9 (9 at the entry `$6D97`; - 1 at `$9D1D`, the ZXDB POKE 40221; + 1 up to 9 at the round end) | `Delay`, `PlayerDeath`, `PrintLives`, `TwoTonesNext`, `ZoneEnd` (code) | `Delay`, `PlayerDeath`, `Start`, `ZoneAddLife` (code) |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8EF4` | `KindTable` | 96 | The 16 object cell kinds 2-17: the list, its write pointer, the record size, the map value after indexing. +0/+1 the list's address, +2/+3 the write pointer (IndexObjectCells sets it to +0/+1), +4 the record length (2: column, row; 3: one more state byte), +5 what the block map byte becomes. The kinds (the handlers are past exB's range; the names from the elements that mark them): 2 `$8F89` (2, 0) the jets, AnimateFlames; 3 `$9022` (3, 3) the gun turrets' barrels, AnimateTurrets; 4 `$9135` (2, 0) blinking light cells, `$9118` (attribute = pass count AND 7 OR `$40`); 5 `$91B0` (3, 1) the mines, `$9152`; 6 `$9930` (2, 1) the teleport booths, `$98BA`; 7 `$99F2` (2, 0) the ammunition pod; 8 `$99F5` (2, 0) the grenade pod, both `$9942`; 9 `$9B4B` (2, 0) the ring, `$9B07` / `$9B52`; 10 `$9C70` (3, 1) the traps, `$9C15` / `$9C8B`; 11 `$9DC1` (2, 0) and 14 `$A333` (3, 0) the twin launchers, `$9D7F` and `$A30B`; 12 `$9F6E` (2, 1) the exoskeleton booth, `$9F2D`; 13 `$A266` (2, 13) the spore pod, `$A23A` / `$A26B`; 15 `$A814` (2, 0) the sector gate's top marks, `$A7D6`; 16 `$AAEF` (2, 0) the gate's floor mark, `$A817`; 17 `$ABCC` (2, 1) the drop pod, `$AB97` / `$ABCF`. | `AddObjectCell`, `Delay`, `IndexObjectCells`, `TwoTonesNext` | `AddObjectCell`, `Delay`, `IndexObjectCells` |
| `$8F89` | `FlameList` | 11 | The jets' cells (kind 2): up to 5 of column, row; `$FF` ends. Filled by IndexObjectCells; read by AnimateFlames. Screen 27 has five jet cells, which fill it exactly (the `$FF` lands on `$8F93`); a sixth would run over FlamePhase. | `AnimateFlames`, `Delay` | `AddObjectCell`, `Delay`, `IndexObjectCells` |
| `$8F94` | `FlamePhase` | 1 | The jets' animation frame 0-2 | `AnimateFlames`, `Delay` | `AnimateFlames`, `Delay`, `IndexObjectCells` |
| `$9019` | `TurretFrames` | 9 | The barrel's first glyph for the states 1-9 (the second is the next glyph) | `AnimateTurrets`, `Delay`, `TurretFrame` | `Delay`, `IndexObjectCells` |
| `$9022` | `TurretList` | 13 | The turrets: up to 4 of column, row, state (2 after a screen is built); `$FF` ends (at most 2 on a screen: 7). ResetTurretList fills the state bytes with 2 before IndexObjectCells writes the columns and rows. | `AnimateTurrets`, `Delay`, `ResetTurretList` | `AddObjectCell`, `AnimateTurrets`, `Delay`, `IndexObjectCells`, `ResetTurretList` |
| `$90CB` | `ShellList` | 31 | The turrets' shells: 10 slots of X, Y, direction (0 free); `$FF` ends | `ClearShellList`, `Delay`, `FireShell`, `MoveShells`, `ShellsHitPlayer` | `ClearShellList`, `Delay`, `FireShell`, `IndexObjectCells`, `MoveShells` +1 |
| `$9135` | `ColourCycleList` | 29 | Up to 14 cells (column, row) of the colour cycle; `$FF` after the last. Filled by `$8E86` / `$8EAD` from the map (map value 4), emptied (`$FF` in the first byte) by `$8E86` at each screen build. The ROM image holds zeros. | `ColourCycle`, `Delay` | `AddObjectCell`, `Delay`, `IndexObjectCells` |

## mines

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$91AF` | `MineFlameToggle` | 1 | 0 or 2: which flame pair the spent mines show this pass | `Delay`, `Mines` | `Delay`, `IndexObjectCells`, `Mines` |
| `$91B0` | `MineList` | 31 | Up to 10 mines (column, row, state); `$FF` after the last. Built by `$8E86` from map value 5 (record size 3: the builder writes column and row, the third byte keeps the 1 ArmMines put there). Mines sets the state to 0 when one fires. | `ArmMines`, `Delay`, `Mines` | `ArmMines`, `Delay`, `IndexObjectCells` |
| `$91ED` | `MineBlastText` | 13 | The print string of MineBlast (control codes of PrintString `$AF2B`). `$E6` `$E0` `$D7`: the font `$D7E0`; `$E0` n: the colour (patched with the floor's attribute at `$91F1`); `$E1` 5 ... `$E2`: repeat five times: two spaces, then `$78` `$FE` (row + 0, column - 2); `$FF`: the end. | `Delay` | `Delay`, `MineBlast` (code) |

## grenade

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$925A` | `GrenadeTimer` | 5 | The grenade in flight: the flight timer `$20` down to 1 (0: none). The timer indexes GrenadeArc. It stops at 1 (the fall goes on until the grenade lands). The main loop runs MoveGrenade once more twice a pass while the timer is below `$13` (`$7609`, `$7620`): three steps a pass for the late flight. | `Delay`, `MoveGrenade`, `StartGame`, `GrenadeRightWall` (code), `ThrowGrenade` (code) | `BuildScreen`, `Delay`, `GrenadeRightWall` (code), `GrenadeStart` (code), `MoveGrenade` (code) +1 |
| `$925B` | `GrenadeX` (`GrenadeTimer`+1) | 1 | X, in 2-pixel units | `Delay`, `MoveGrenade` (code) | `Delay`, `GrenadeRightWall` (code), `GrenadeStart` (code) |
| `$925C` | `GrenadeY` (`GrenadeTimer`+2) | 1 | Y, in pixels | `Delay`, `GrenadeRightWall` (code), `MoveGrenade` (code) | `Delay`, `GrenadeRightWall` (code), `GrenadeStart` (code) |
| `$925D` | `GrenadeDir` (`GrenadeTimer`+3) | 1 | the direction: `$FF` left, 1 right (the player's facing at the throw) | `Delay`, `GrenadeRightWall` (code), `MoveGrenade` (code) | `Delay`, `GrenadeStart` (code) |
| `$925E` | `GrenadeFrame` (`GrenadeTimer`+4) | 1 | the small-sprite frame: 0 facing right, 1 facing left | `Delay`, `GrenadeRightWall` (code), `MoveGrenade` (code) | `Delay`, `GrenadeStart` (code) |
| `$92DB` | `GrenadeArc` | 32 | The grenade's vertical step for the timer 1-32 (index 1 first). MoveGrenade reads byte timer - 1 (HL = `$92DA` + timer; `$92DA` is the last byte of the JP at `$92D8`). From the throw (timer 32) on: -4, -4, -2, -2, -2, -1, -1, -1, -1 (a climb of 18 pixels in 9 steps), 22 steps level, then +1 a step at timer 1 for the rest of the flight (the fall, three steps a pass). | `Delay` | `Delay` |

## effects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9437` | `DestructibleList` | 80 | The grenade-destructible scenery pieces of the screen: 7-byte records, `$FF` after the last. Written by AddDestructible while the screen builder `$8494` prints the elements (IX from `$9437`, `$FF` written after the last by `$850A`). A record: +0 x0, +1 x1 (columns, the box's left and its right + 1), +2 y0, +3 y1 (rows), +4 the element's column, +5 its row, +6 the element number. +0 = `$80`: destroyed. The ROM image holds zeros; 80 bytes: 11 records and 3 spare. | `Delay` | `AddDestructible`, `BuildScreen`, `Delay` |
| `$94C6` | `DestructibleKinds` | 51 | The 10 destructible element kinds: element, dx, width, dy, height; `$FF` ends. The box of an element at (column, row): x0 = column + dx, x1 = x0 + width, y0 = row + dy, y1 = y0 + height (signed offsets). Elements `$05`, `$0D`, `$0F`, `$10`, `$12`, `$15`, `$1F`, `$28`, `$2C`, `$2E`. | `AddDestructible`, `Delay` | `Delay` |
| `$9555` | `DebrisSpeeds` | 8 | The debris speeds: -4, -3, -2, 0, 0, 2, 3, 4 | `Delay` | `Delay` |
| `$95B6` | `DebrisList` | 601 | 100 debris pieces of 6 bytes: state, X, Y, dx, dy, colour; `$FF` ends. Cleared by ClearDebris at each screen build. The ROM image holds zeros. | `ClearDebris`, `Delay`, `MoveDebris` | `ClearDebris`, `Delay` |
| `$9865` | `PuffFrames` | 11 | The puff's frames by timer: index t at `$9865` + t - 1 (t = 1-11). Read as `$9864` + t + 1 and `$9864` + t (LD BC,`$9864` at `$984A`). | `Delay` | `Delay` |
| `$9870` | `PuffList` | 61 | 20 puffs (X, Y, timer); `$FF` ends. Cleared by ClearPuffs at each screen build. | `AnimatePuffs`, `ClearPuffs`, `Delay` | `ClearPuffs`, `Delay` |

## pickups

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9930` | `TeleportPads` | 6 | The teleport pair of the screen: pad 1 (column, row), pad 2 (column, row), `$FF`, the latch. Built by `$8E86` from map value 6 (record 6 of `$8EF4`). `$FF` in the first byte: no teleports. | `Delay`, `Teleports` | `Delay`, `IndexObjectCells`, `Teleports` |
| `$9932` | `TeleportPad2` (`TeleportPads`+2) | 3 | - | `Delay`, `Teleports` (code) | `Delay`, `IndexObjectCells` |
| `$9935` | `TeleportLatch` (`TeleportPads`+5) | 1 | non-zero while up is held after a teleport test | `Delay`, `Teleports` | `Delay`, `IndexObjectCells`, `Teleports` |
| `$99F2` | `AmmoPod` | 6 | The ammunition pod (column, row), `$FF` after it; `$FF` in the first byte: taken or none | `Delay`, `Pods` | `Delay`, `IndexObjectCells`, `Pods` (code) |
| `$99F5` | `GrenadePod` (`AmmoPod`+3) | 3 | the grenade pod (column, row), `$FF` after it | `Delay`, `Pods` | `Delay`, `IndexObjectCells`, `Pods` (code) |
| `$9A0F` | `Printers` | 10 | The five character printers of SetPrinter: `$ADE1`, `$AE26`, `$AE5D`, `$AE95`, `$AEE4` | `Delay` | `Delay` |

## balls

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9A99` | `BallList` | 97 | Up to 24 balls (X, Y, state, dx); `$FF` after the last. Filled by SpawnBalls (8 balls for each of up to 3 spawners) at the screen build; cleared by ClearBalls. | `BallsTouchPlayer`, `ClearBalls`, `Delay`, `MoveBallsLoop`, `ShotsHitBalls` | `ClearBalls`, `Delay` |
| `$9B4B` | `BallSpawners` | 7 | Up to 3 ball spawners (column, row); `$FF` after the last (map value 9) | `Delay`, `SpawnBalls` | `Delay`, `IndexObjectCells` |

## death

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9C70` | `TrapList` | 13 | Up to 4 traps (column, row, counter); `$FF` after the last. Built by `$8E86` from map value 10 (record size 3; the map cell then 1). The counter starts at `$5F` (ClearTraps): the first rise six passes after the screen starts. The ROM image holds zeros. | `ClearTraps`, `Delay`, `TrapContact`, `Traps` | `ClearTraps`, `Delay`, `IndexObjectCells` |
| `$9CE2` | `DeathTimer` | 1 | The passes left of the player's death, 46 down to 0 (0: alive) | `AbortIfDying`, `Delay`, `KillPlayer`, `PlayerDeath`, `HomingMissileStart` (code) | `Delay`, `KillPlayer`, `PlayerDeath`, `Start` |
| `$9D4A` | `DeathLeap` | 46 | The death's vertical steps for DeathTimer 1-45 (index 1 first). PlayerDeath reads `$9D49` + t (`$9D49` is the JR operand before the table). From the start (t = 45) on: -4, -4, -2, -2, -2, -1 x 4, 0 x 4, then down 1 x 4, 2 x 3 and 4 a pass to the end: a leap of 18 lines, then the fall. | `Delay`, `PlayerDeath` | `Delay` |

## guns

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9DC1` | `GunList` | 21 | Up to 10 guns (column, row); `$FF` after the last (map value 11) | `Delay`, `Guns` | `Delay`, `IndexObjectCells` |
| `$9E18` | `GunShots` | 31 | Up to 10 gun shots (X, Y, dx); `$FF` after the last. The shots hit by the player's shots (`$9E37` / `$9E4F`) and the player (`$9E64`) are tested past this range. | `ClearGunShots`, `Delay`, `GunShotsVsPlayer`, `GunShotsVsShots`, `MoveGunShots` | `ClearGunShots`, `Delay` |

## passtime

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9E98` | `XorSpriteCount` | 1 | The XOR sprite draws of this pass: zeroed at `$75BF`, +1 per XorSprite `$92FB` (`$9359`) | `Delay`, `DrawSmallSprite`, `PadXorSprites` | `Delay`, `DrawSmallSprite`, `StartGame` |
| `$9EAE` | `SlotSpriteCount` | 1 | Zeroed each pass (`$75C2`); no code raises it | `Delay`, `PadSlotSprites` | `Delay`, `StartGame` |
| `$9ED6` | `BonusTicks` | 2 | The pending bonus in ticks of 25 points (AddBonusTicks, PayBonusTick); 0 at a new game (`$6D7B`) | `Delay`, `PayBonusTick`, `AddBonusTicks` (code) | `Delay`, `Start`, `AddBonusTicks` (code), `PayBonusTick` (code) |
| `$9ED8` | `ExoSuit` | 1 | `$0C` while the player wears the exoskeleton, 0 without: the frame offset of his sprites. Toggled by ExoSuitBooth (XOR `$0C`), cleared at a new game (`$6D72`) and at a zone's end (ZoneRefill `$A8A5`). `$8224` adds it to every player frame number (the suited frames are `$0C` on). Read by the fire (`$837B`: a second shot 6 lower while suited), by `$9CAA` (the mines and traps of the ZXDB POKEs `$9CAE`: the suit protects) and by ZoneBonus (no bravery bonus while suited). | `Delay`, `FireControl`, `PlayerFrame`, `ExoSuitBooth` (code), `ShieldedKill` (code) +1 | `Delay`, `Start`, `ExoSuitBooth` (code), `ZoneRefill` (code) |
| `$9F13` | `SparkleList` | 13 | The sparkles: 4 records of X, Y, passes left; `$FF` ends | `ClearSparkles`, `Delay`, `RunSparkles` | `ClearSparkles`, `Delay` |
| `$9F6D` | `BoothUpLatch` | 1 | 1 while UP stays pressed after a booth action, 0 when released | `Delay`, `ExoSuitBooth` | `Delay`, `ExoSuitBooth` |
| `$9F6E` | `ExoBoothList` | 3 | The exoskeleton booth's cell (column, row), `$FF` when the screen has none. Written by the screen builder (`$8EAD` through `$8EF4`'s tile-12 record, which points here); one booth a screen at most (the `$FF` after the first record ends the list). | `Delay`, `ExoSuitBooth` | `Delay`, `IndexObjectCells` |

## blasts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A001` | `BlastFrames` | 11 | The blast's frame for passes left 1..11: 0 (cleared), 9 9 8 8 7 7 6 6 5 5 | `Delay` | `Delay` |
| `$A00C` | `BlastList` | 16 | The blasts: 5 records of X, Y, passes left; `$FF` at `$A01B` ends | `ClearBlasts`, `Delay`, `RunBlasts` | `ClearBlasts`, `Delay` |

## gameover

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A057` | `GameOverText` | 28 | GAME OVER: at 9,10, font `$D7E0`, attribute `$56`, a row of 11 spaces, " GAME OVER ", 11 spaces. The print codes of PrintString `$AF2B`: `$DF` row col, `$E6` the font, `$E0` the attribute, `$E4` n c (n times c), `$90-$CE` a new line at the column + (code - `$AF`), `$FF` the end. Rows 9-11, columns 10-20. | `Delay`, `PrintString` | `Delay` |
| `$A156` | `HofEntryText` | 186 | The name entry screen: the frame, the EXOLON title, CONGRATULATIONS!, PLEASE ENTER YOUR NAME .... Font `$ECE0` (the frame pieces, characters 0-11), PanelBar at rows 0-1 and 22-23, the two side columns (10 x 2 rows of pieces 4-7 at columns 0-1 and 30-31), the title `$70FF` at 3,8, then in font `$D7E0`: CONGRATULATIONS! (8,8, attribute `$46`), PLEASE ENTER YOUR NAME (bright green), INTO THE EXOLON HALL OF FAME (bright magenta), the field "--------" (bright white, row 15 columns 12-19), PRESS CAPS TO DELETE (bright cyan), PRESS ENTER TO END (bright yellow). The strings proper start at `$A188`. The codes: `$61-$8F` move by (code - `$78`) rows and the next byte (signed) columns; `$CF-$DE` the ink (code - `$CF`, 8 and up bright); `$E1` n ... `$E2` repeats n times; `$E3` lo hi prints another string. | `Delay` | `Delay` |
| `$A210` | `PanelBar` | 24 | A frame bar: a corner, 14 pairs of top pieces (8, 9), the row under (10, 11), the other corner. Printed with {call} by HofEntryText, BonusScreenText and CongratulationsText at rows 0 and 22 (two rows: the pieces 8-11 of font `$ECE0`, bright and plain cyan). | `Delay` | `Delay` |
| `$A228` | `PanelCorner` | 10 | A corner of the frame: pieces 0-3 in 2 x 2, bright cyan and cyan | `Delay` | `Delay` |
| `$A232` | `NameBuffer` | 8 | The name typed in the Hall of Fame entry: 8 characters (spaces at the start of each entry) | `Delay` | `Delay` |

## aliens

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A266` | `MissileLauncher` | 2 | The missile launcher's cell (column, row) from the screen builder (tile 13); `$FF` in the first byte: none | `Delay`, `HomingMissileStart`, `HomingMissileStep` (code) | `Delay`, `IndexObjectCells` |
| `$A268` | `MissilePosition` | 2 | The missile's X, Y; the builder's `$FF` end mark of MissileLauncher lands here first | `Delay`, `HomingMissileStep` (code) | `Delay`, `IndexObjectCells`, `HomingMissileStart` (code), `HomingMissileStep` (code) |
| `$A26A` | `MissileLive` | 1 | `$0D` while the missile flies, 0 when not | `Delay`, `HomingMissileStep` | `Delay`, `HomingMissileStart`, `IndexObjectCells`, `HomingMissileStep` (code) |
| `$A333` | `PickupList` | 31 | The pick-ups of tile 14: up to 10 records of column, row, live (1); `$FF` at `$A351`. The builder writes the column and row (its record size is 3, so the live byte is left as ClearPickups set it: 1 for the first four records). | `ClearPickups`, `Delay`, `PickupsVsPlayer` | `ClearPickups`, `Delay`, `IndexObjectCells` |
| `$A406` | `AlienPaths` | 258 | The 6 alien paths (`$A406`, `$A445`, `$A490`, `$A4C5`, `$A4CE`, `$A4E3`): dX dY pairs, `$C4` n hold, `$C3` loop. `$A406`: a sine wave left (31 pairs of dX -1, dY 0 to +-3); `$A445`: the same wave, then 15 x (-1, 0), 6 x (-2, 0), 100 x (-4, 0) (it speeds off); `$A490`: 34 x (-2, 0), then a loop up and down over 30 passes, 100 x (-2, 0); `$A4C5`: 40 x (-1, 0), 100 x (-4, 0); `$A4CE`: 18 x (-2, 0), 32 x (0, -1), 24 x (0, +1), 6 still, 100 x (-4, 0); `$A4E3`: zig-zag, a box, 100 x (-4, 0). X is in 2-pixel units (128 across), Y in pixels. Every path ends with `$C3`. | `Delay` | `Delay` |
| `$A445` | `AlienPath2` (`AlienPaths`+63) | 75 | - | `Delay` | `Delay` |
| `$A490` | `AlienPath3` (`AlienPaths`+138) | 53 | - | `Delay` | `Delay` |
| `$A4C5` | `AlienPath4` (`AlienPaths`+191) | 9 | - | `Delay` | `Delay` |
| `$A4CE` | `AlienPath5` (`AlienPaths`+200) | 21 | - | `Delay` | `Delay` |
| `$A4E3` | `AlienPath6` (`AlienPaths`+221) | 37 | - | `Delay` | `Delay` |
| `$A508` | `AlienList` | 61 | The aliens: 6 records of 10 bytes (AliensStep), `$FF` at `$A544` | `AliensStepLoop`, `AliensVsPlayer`, `AliensVsShots`, `ClearAliens`, `Delay` | `ClearAliens`, `Delay` |
| `$A5C9` | `AlienSpawnDelay` | 1 | Passes before the next alien may start | `Delay` | `Delay`, `AlienSpawn` (code) |
| `$A676` | `AliensHere` | 1 | 1 when the current screen has aliens (AliensSetUp) | `AlienSpawn`, `Delay` | `AliensSetUp`, `Delay` |
| `$A677` | `AlienScreens` | 351 | The 70 screens with aliens: the screen, the path (word), the frame base, the delay; `$FF` ends. Screens 3-124 (none on 0-2 or on screen 24 and many others; the zone ends 49, 74, 99 and 124 have aliens). The frame bases are `$01`, `$10`, `$14`, `$18`, `$25` and `$29` (six alien looks); the delays 8-40 passes. A screen's path and look are independent (e.g. screen 3: path `$A406`, frame `$10`, delay 20; screen 54: `$A4E3`, `$29`, 30). The full list is in exD.md. | `AliensSetUp`, `Delay` | `Delay` |
| `$A814` | `FlickerPadList` | 3 | The flickering pad's cell (column, row), `$FF` at `$A816`; `$FF` in the first byte: none | `Delay`, `FlickerPadStep` | `Delay`, `IndexObjectCells` |

## zoneend

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A960` | `BonusPointer` | 1 | The bonus screen's pointer, + 1 a step, never reset (its line = AND 7) | `Delay`, `BonusScreen` (code) | `Delay`, `BonusScreen` (code) |
| `$A961` | `BonusScreenText` | 222 | The bonus screen: the frame and title, EXOLON BONUS SCREEN!, PRESS FIRE TO STOP POINTER, the 8 lines. The same frame as HofEntryText (PanelBar, PanelCorner, the side columns, the title `$70FF`); EXOLON BONUS SCREEN! (8,6, bright white), PRESS FIRE TO STOP POINTER (10,3, bright green), from 13,9 the lines 00000 POINTS (bright yellow) and 01000, 03000, 05000, 07000 POINTS (bright cyan) in turn. | `Delay` | `Delay` |
| `$AA3F` | `CongratulationsText` | 161 | The end of the game's 125 screens: CONGRATULATIONS! YOU HAVE PROVEN YOUR COMBAT ABILITIES TO THE FULL. RoundEnd prints it on screen 124's end, then the game goes on from screen 0 (no ending beyond it). The same frame; then PRESS FIRE TO RESUME PLAY (the code waits with 4 DelayBC, not for fire). | `Delay` | `Delay` |
| `$AAE0` | `ZoneStarts` | 15 | The start of each zone: the screen, the player's X, Y (screens 0, 25, 50, 75, 100). ZoneRefill looks the new screen up (no end mark: a screen not in the table would loop for ever; only these five follow a zone's end). The entry `$6D60` starts a game at `$10`, `$70` itself (the first record's values). | `Delay` | `Delay` |
| `$AAEF` | `ZoneEndList` | 3 | The zone end marker's cell (column, row) from the builder (tile 16), `$FF` at `$AAF1` | `Delay`, `ZoneEnd` | `Delay`, `IndexObjectCells` |
| `$AAF2` | `ZoneBonusText` | 162 | The zone end panel: a frame of font `$EAB0`, BRAVERY BONUS 00000, LIVES BONUS X 1000, PRESS FIRE TO RESUME PLAY (no code reads fire there: the panel ends with its Delays). At 3,7: a box 17 wide and 15 high of yellow pieces (font `$EAB0`), cleared inside with spaces of font `$D7E0`, then the texts (bright magenta, white, green, yellow, cyan). | `Delay` | `Delay`, `IndexObjectCells` |

## forcefield

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$ABCC` | `ForceFieldList` | 3 | The force field's cell (column, row) from the builder (tile 17), `$FF` at `$ABCE`; `$FF` in the first: none or destroyed | `Delay`, `ForceFieldDraw`, `ForceFieldStep`, `ForceFieldVsShots`, `ForceFieldDestroy` (code) | `Delay`, `IndexObjectCells`, `ForceFieldDestroy` (code) |
| `$AC57` | `ForceFieldHeight` | 1 | The force field's cells, counted by ForceFieldDraw | `Delay`, `ForceFieldDestroy` (code), `ForceFieldStep` (code) | `Delay`, `ForceFieldDraw` (code) |
| `$AC58` | `ForceFieldHits` | 1 | The shots that reached the force field on this screen | `Delay`, `ForceFieldVsShots` (code) | `Delay`, `ForceFieldDraw` (code), `ForceFieldVsShots` (code) |
| `$AC78` | `IdleMissileLive` | 1 | 1 while the idle missile flies | `Delay`, `IdleMissileStart`, `IdleMissileStep` | `BuildScreen`, `Delay`, `IdleMissileStart` (code), `IdleMissileStep` (code) |
| `$AC79` | `IdleMissilePosition` | 2 | Its X, Y | `Delay`, `IdleMissileStep` (code) | `Delay`, `IdleMissileStart` (code), `IdleMissileStep` (code) |
| `$AC7B` | `IdleTime` | 2 | The passes spent on the current screen (cleared by a new screen and a death) | `Delay`, `IdleMissileStart`, `StartGame` | `BuildScreen`, `Delay`, `KillPlayer`, `StartGame` |

## utils

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$ACEF` | `KeyTable` | 41 | The 40 keys in the order of the rows `$FE` ... `$7F` and their bits 0-4, then 0 (no key). CAPS SHIFT is 1, SYMBOL SHIFT 2, ENTER 13, SPACE 32, the rest their characters: (CS) Z X C V, A S D F G, Q W E R T, 1 2 3 4 5, 0 9 8 7 6, P O I U Y, (ENTER) L K J H, (SPACE) (SS) M N B. The define-keys screen (`$7CF9`) uses it too. | `Delay`, `ReadKey` | `Delay` |
| `$AD51` | `RandomSeed` | 2 | The random seed (Random) | `Delay`, `Random` | `Delay`, `Random` |
| `$AD82` | `ScoreText` | 15 | The HUD score: attribute `$45`, font `$D7E0`, at 23,14, the six digits, `$FF` | `Delay`, `HofDigitLoop`, `PrintString`, `Start` | `Delay`, `Start` |
| `$AD8A` | `Score` (`ScoreText`+8) | 7 | the score: 6 ASCII digits (000000 at a new game, `$6D88`) | `Delay`, `HofDigitLoop`, `PrintString`, `Start` | `Delay`, `Start` |
| `$AD91` | `PointValues` | 60 | The ten addends of AddScore, 6 ASCII digits each: 25 50 100 125 150 200 250 300 350 1000 | `Delay` | `Delay` |
| `$AD97` | `Points50` (`PointValues`+6) | 6 | - | `Delay` | `Delay` |
| `$AD9D` | `Points100` (`PointValues`+12) | 6 | - | `Delay` | `Delay` |
| `$ADA3` | `Points125` (`PointValues`+18) | 6 | - | `Delay` | `Delay` |
| `$ADA9` | `Points150` (`PointValues`+24) | 6 | - | `Delay` | `Delay` |
| `$ADAF` | `Points200` (`PointValues`+30) | 6 | - | `Delay` | `Delay` |
| `$ADB5` | `Points250` (`PointValues`+36) | 6 | - | `Delay` | `Delay` |
| `$ADBB` | `Points300` (`PointValues`+42) | 6 | - | `Delay` | `Delay` |
| `$ADC1` | `Points350` (`PointValues`+48) | 6 | - | `Delay` | `Delay` |
| `$ADC7` | `Points1000` (`PointValues`+54) | 6 | - | `Delay` | `Delay` |

## workarea

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B101` | `NoSaveBuffer` | 1488 | A 128-byte sprite background buffer for the drawings that keep no background. The sprite drawers save the screen under a sprite into the buffer the caller gives (DE) and skip the copy when it is NoSaveBuffer (`$7867`: SBC HL,DE with HL = `$B101` for the 24-pixel frames, `$7A80` for the 16-pixel frames). `$9EA4` passes it. The draw routine `$79C2` reads `$B101-$B130` (16 rows of 3 bytes) in the warp runs. Zeros in the image. | `BigSpriteMask`, `ClearWorkArea`, `Delay`, `ShiftNone` | `BigSpriteMask`, `ClearWorkArea`, `Delay`, `ShiftNone` |
| `$B181` | `WorkArea` (`NoSaveBuffer`+128) | 1360 | `$B181-$B6D0`: the per-screen work area cleared by ClearWorkArea; from `$B181` the player's background save (128 bytes: `$824D`, `$9C15`) and the menu's (`$6EAF`) | `BigSpriteMask`, `ClearWorkArea`, `Delay`, `ShiftNone` | `BigSpriteMask`, `ClearWorkArea`, `Delay`, `ShiftNone` |

## music

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B6DF` | `TuneState` | 13 | The title tune's player state. +0 (`$B6DF`) and +3/+4 (`$B6E2`, `$B6E3`) have no reader or writer in any recording or in the code. The stream pointers hold stale values in the image (TuneStart writes them). | `Delay`, `TuneInitChannel`, `TuneSetMaxVolumes`, `TuneNextEvent` (code), `TuneTick` (code) | `AySilence`, `Delay`, `TuneStart`, `TuneEnd` (code), `TuneNextEvent` (code) +1 |
| `$B6E0` | `TuneVolume` (`TuneState`+1) | 1 | 12: the start volume and the ceiling (TuneSetMaxVolumes, TuneInitChannel) | `Delay`, `TuneInitChannel`, `TuneSetMaxVolumes` | `Delay` |
| `$B6E1` | `TuneStreamRead` (`TuneState`+2) | 3 | 0 at each TuneTick; `$FF` once a channel has read its stream in this tick (TuneNextEvent) | `Delay`, `TuneNextEvent` (code) | `Delay`, `TuneNextEvent` (code), `TuneTick` (code) |
| `$B6E4` | `TuneStopped` (`TuneState`+5) | 1 | `$FF`: no tune (set in TuneStart and at the tune's end, TuneEnd), 0 playing | `Delay`, `TuneTick` (code) | `Delay`, `TuneStart`, `TuneEnd` (code) |
| `$B6E5` | `TuneMixer` (`TuneState`+6) | 1 | the AY mixer value (register 7) the tune keeps: `$B8` from AySilence, toggled by the stream code `$64` | `Delay` | `AySilence`, `Delay` |
| `$B6E6` | `TunePointerA` (`TuneState`+7) | 2 | channel A's stream pointer (IY between the ticks) | `Delay`, `TuneTick` (code) | `Delay`, `TuneStart`, `TuneTick` (code) |
| `$B6E8` | `TunePointerB` (`TuneState`+9) | 2 | channel B's stream pointer | `Delay`, `TuneTick` (code) | `Delay`, `TuneStart`, `TuneTick` (code) |
| `$B6EA` | `TunePointerC` (`TuneState`+11) | 2 | channel C's stream pointer | `Delay`, `TuneTick` (code) | `Delay`, `TuneStart`, `TuneTick` (code) |
| `$BA01` | `TuneStreamA` | 1148 | The title tune, channel A: the order list, then its patterns. The codes of TuneNextEvent. `$BA01-$BA57`: calls (`$75`) of the patterns and the envelope settings, ending with `$FF`; `$BA58-$BB7D` the patterns, each ending with `$76`. tune.py: 340 notes, 40 calls, 11 volume envelopes. | `Delay` | `Delay` |
| `$BA58` | `TunePatternsA` (`TuneStreamA`+87) | 294 | channel A's patterns (sub-streams, `$76` each) | `Delay` | `Delay` |
| `$BB7E` | `TuneStreamB` (`TuneStreamA`+381) | 101 | channel B: the order list (`$FF` at `$BBE2`), 364 notes, 28 noise settings, 2 mixer toggles | `Delay` | `Delay` |
| `$BBE3` | `TunePatternsB` (`TuneStreamA`+482) | 291 | - | `Delay` | `Delay` |
| `$BD06` | `TuneStreamC` (`TuneStreamA`+773) | 88 | channel C: the order list (`$FF` at `$BD5D`), 90 notes, 29 volume envelopes | `Delay` | `Delay` |
| `$BD5E` | `TunePatternsC` (`TuneStreamA`+861) | 131 | - | `Delay` | `Delay` |
| `$BDE1` | `TuneEnvelopes` (`TuneStreamA`+992) | 156 | envelope sub-streams called by all three channels (`$8A` n ... `$76`) | `Delay` | `Delay` |
| `$BE7D` | `TuneChannels` | 240 | The tune's three channel records, 80 bytes each: A, B, C. TuneTick passes IX = `$BE7D`, `$BECD`, `$BF1D`. +0/+1 the note's period, +2 the note's ticks left, +3 the volume, +4/+5 (5 at the start, +5 = 1 at a note: no reader), +6 the tone register (A 0, B 2, C 4), +7 the volume register (8, 9, 10), +8 the volume ceiling, +9 the transpose, +`$0A` the note length, +`$0B` the mixer bits (A `$09`, B `$12`, C `$24`), +`$0C` the call depth, +`$0D` the deferred read, +`$0E`-+`$18` the call return points (2 bytes each), +`$19` the pitch offset, +`$1A` the pitch envelope index, +`$1B`/+`$1C`/+`$1D`/+`$1E` the pitch counters, the step and the reload, +`$1F` the pitch table's length and +`$20` on its entries, +`$35` the volume envelope index, +`$36`/+`$37`/+`$38`/+`$39` the volume counters, the step and the reload, +`$3A` the volume table's length and +`$3B` on its entries. Only the fixed fields (+6, +7, +`$0B`) matter in the image; the rest is set by TuneStart and the streams (written in c128 only). | `Delay` | `Delay`, `TuneInitChannel`, `TuneSetMaxVolumes`, `TuneStart` |
| `$BECD` | `TuneChannelB` (`TuneChannels`+80) | 80 | - | `Delay` | `Delay`, `TuneInitChannel`, `TuneSetMaxVolumes`, `TuneStart` |
| `$BF1D` | `TuneChannelC` (`TuneChannels`+160) | 80 | - | `Delay` | `Delay`, `TuneInitChannel`, `TuneSetMaxVolumes`, `TuneStart` |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C077` | `SfxChannelWriters` | 32 | The writers of AY channels A, B, C, then 13 times SfxNoChannel. SfxToAyChannel's JP (HL): SfxWriteChannelA `$C097`, SfxWriteChannelB `$C0B1`, SfxWriteChannelC `$C0CC`, then `$C7F3` (a RET). | `Delay`, `SfxToAyChannel` | `Delay` |
| `$C218` | `SoundEffects` | 1437 | The 23 sound effect streams (codes of SfxReadStream). Each starts at the address its trigger passes and ends with `$FF`; sfx.py decodes them. | `Delay`, `SfxReadStream`, `SfxSlotStep`, `SfxToAyChannel`, `SfxWriteChannelA` +3 | `Delay`, `SfxReadStream`, `SfxSlotStep`, `SfxToAyChannel`, `SfxWriteChannelA` +4 |
| `$C23E` | `GrenadeRefillSound` (`SoundEffects`+38) | 38 | slot 2: arpeggios 84-76-68-60 at volume 13 ... 3 | `Delay` | `Delay` |
| `$C264` | `NoiseBurstSound` (`SoundEffects`+76) | 28 | slot 13: tone and noise, note 75, volume 13 down to 3 | `Delay` | `Delay` |
| `$C280` | `TrillSound` (`SoundEffects`+104) | 71 | slot 5: note 60 and silence alternating, 3 ticks each, 34 times | `Delay` | `Delay` |
| `$C2C7` | `NoiseSweepSound` (`SoundEffects`+175) | 62 | slot 7: noise only, the noise period stepping 0, 2, ... 30 | `Delay` | `Delay` |
| `$C305` | `BlastSound` (`SoundEffects`+237) | 57 | slot 6: noise 31 and notes 40 down to 12, volume 15 down to 1 | `Delay`, `SfxReadStream` | `Delay` |
| `$C33E` | `ExplosionSound` (`SoundEffects`+294) | 30 | slot 8: noise and notes 50 down to 36, volume 14 down to 3 | `Delay` | `Delay` |
| `$C35C` | `HumSoundA` (`SoundEffects`+324) | 5 | slot 1: note 1 (period `$0384`) for 10 ticks | `Delay` | `Delay` |
| `$C361` | `HumSoundB` (`SoundEffects`+329) | 5 | slot 11: note 2 (period `$0392`) for 10 ticks | `Delay` | `Delay` |
| `$C366` | `GrenadeSoundA` (`SoundEffects`+334) | 114 | slot 9: notes 79 down to 24, the volume up 1 to 15 then down | `Delay` | `Delay` |
| `$C3D8` | `GrenadeSoundB` (`SoundEffects`+448) | 114 | slot 15: the same from note 59 | `Delay` | `Delay` |
| `$C44A` | `FanfareSound` (`SoundEffects`+562) | 24 | slot 0 (never read): an arpeggio of 18 notes, then 60 held | `Delay` | `Delay` |
| `$C462` | `PulseSound` (`SoundEffects`+586) | 221 | slot 13: note 60 with tremolo volumes 15 ... 1 | `Delay` | `Delay` |
| `$C53F` | `FanfareBassSound` (`SoundEffects`+807) | 14 | slot 15 (never read): decay 1,1, notes 48 down to 43 | `Delay` | `Delay` |
| `$C54D` | `JingleBSound` (`SoundEffects`+821) | 16 | slot 14 (never read): decay 2,1, a phrase from note 67 | `Delay` | `Delay` |
| `$C55D` | `JingleASound` (`SoundEffects`+837) | 16 | slot 4 (never read): decay 1,1, a phrase from note 67 | `Delay` | `Delay` |
| `$C56D` | `JingleBBassSound` (`SoundEffects`+853) | 10 | slot 5 (never read): decay 4,1, notes 60 55 60 | `Delay` | `Delay` |
| `$C577` | `ChordSound1` (`SoundEffects`+863) | 14 | slot 8 (never read): decay 1,1, 72 67 64 60 64 67 72 | `Delay` | `Delay` |
| `$C585` | `ChordSound2` (`SoundEffects`+877) | 14 | slot 9 (never read): 67 64 60 55 60 64 67 | `Delay` | `Delay` |
| `$C593` | `ChordSound3` (`SoundEffects`+891) | 14 | slot 10 (never read): 64 60 55 52 55 60 64 | `Delay` | `Delay` |
| `$C5A1` | `ShotSound` (`SoundEffects`+905) | 25 | slot 15: noise 15 and note 20 at volume 13 down to 2 | `Delay`, `SfxReadStream` | `Delay` |
| `$C5BA` | `WobbleSound` (`SoundEffects`+930) | 14 | slot 13 (never read): decay 2,1, notes 69-72-69 | `Delay` | `Delay` |
| `$C5C8` | `RiseSound` (`SoundEffects`+944) | 31 | slot 12 (never read): decay 3,1, noise and notes 40 up to 56 | `Delay` | `Delay` |
| `$C5E7` | `SfxChannelBits` (`SoundEffects`+975) | 1 | the mixer bits of the channel being handed out (`$F6` rotated) | `Delay`, `SfxWriteChannelA`, `SfxWriteChannelB`, `SoundEffectsTick`, `SfxWriteChannelC` (code) | `Delay`, `SoundEffectsTick` |
| `$C5E8` | `SfxNoise` (`SoundEffects`+976) | 1 | the noise period to register 6 | `Delay`, `SoundEffectsTick` | `Delay`, `SfxReadStream`, `SfxCheckMixer` (code) |
| `$C5E9` | `SfxMixer` (`SoundEffects`+977) | 1 | the mixer value to register 7 | `Delay`, `SfxWriteChannelA`, `SfxWriteChannelB`, `SoundEffectsTick` | `Delay`, `SfxWriteChannelA`, `SfxWriteChannelB`, `SoundEffectsTick` |
| `$C5EA` | `SfxChannelIndex` (`SoundEffects`+978) | 1 | the AY channels handed out in this tick | `Delay`, `SfxToAyChannel`, `SoundEffectsTick` | `Delay`, `SfxToAyChannel`, `SoundEffectsTick` |
| `$C5EB` | `SfxSlots` (`SoundEffects`+979) | 256 | 16 slots of 16 bytes: +0 `$FF` free / 0 active, +1/+2 the stream, +3 the note's ticks, +4 the volume, +5 the start volume, +6/+7 the decay counter and its reload, +8 the decay step, +9/+`$0A` the period, +`$0B` the mixer mask, +`$0C` the note length | `Delay`, `SfxReadStream`, `SfxSlotStep`, `SfxToAyChannel`, `SfxWriteChannelA` +2 | `Delay`, `SfxReadStream`, `SfxSlotStep`, `StartSoundEffect` |
| `$C6EB` | `NotePeriods` (`SoundEffects`+1235) | 48 | 96 AY tone periods: 0 (silence), `$0384`, `$0392`, then from 3 the semitones `$0C8E` down to `$0010`; the tune reads from entry 24 (`$C71B`) | `Delay`, `SfxReadStream` | `Delay` |
| `$C71B` | `NotePeriodsTune` (`SoundEffects`+1283) | 144 | entry 24: the tune's note 0 | `Delay`, `SfxReadStream` | `Delay` |
| `$C7AB` | `CpcKeyMatrix` (`SoundEffects`+1427) | 10 | 10 bytes (`$FF`): the Amstrad CPC keyboard rows CpcReadKeyboard writes (never written in any recording) | `Delay` | `Delay` |

## layouts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C7F4` | `ScreenTable` | 250 | The 125 screens: the address of each screen's layout, by the screen number. The screen builder BuildScreen reads entry ScreenNumber `$8523` (`$84D7`: BC = `$C7F4`, TableWord HL = the word at BC + 2A). The words point at the layouts in ScreenLayouts, in screen order and packed with no gap (`$C8EE-$D8DF`). The round is screens 0-124 (screen 124 walked off ends it, `$A867`). | `Delay`, `TableWord` | `Delay` |
| `$C8EE` | `Screen000Layout` | 4082 | The layouts (from screen 0's) of screens 0-124: the objects of each screen, 3 bytes an object, `$FF` the end. An object: the row, the column (signed: from `$E0` up the object starts off the left edge, its glyphs there clipped by PrintChar's bit 5 test), the object number. The builder (`$84E4-$8507`) takes D = row, E = column, the object's string from ObjectTable `$852E` (62 objects, 0-61), `$AE1B` = 1 (the cells solid), `$AE21` = 0 (drawn), C = 0, and PrintString draws it; the object's string sets its own glyph set (`$E6`) and colours. Objects per screen: 3-21 (1319 in all); every one of the 62 objects but [8, 9, 18, 56, 57] is used. | `BuildScreen`, `Delay` | `Delay` |
| `$C90A` | `Screen001Layout` (`Screen000Layout`+28) | 31 | screen 1: 10 objects | `Delay` | `Delay` |
| `$C929` | `Screen002Layout` (`Screen000Layout`+59) | 34 | screen 2: 11 objects | `Delay` | `Delay` |
| `$C94B` | `Screen003Layout` (`Screen000Layout`+93) | 22 | screen 3: 7 objects | `Delay` | `Delay` |
| `$C961` | `Screen004Layout` (`Screen000Layout`+115) | 22 | screen 4: 7 objects | `Delay` | `Delay` |
| `$C977` | `Screen005Layout` (`Screen000Layout`+137) | 25 | screen 5: 8 objects | `Delay` | `Delay` |
| `$C990` | `Screen006Layout` (`Screen000Layout`+162) | 40 | screen 6: 13 objects | `Delay` | `Delay` |
| `$C9B8` | `Screen007Layout` (`Screen000Layout`+202) | 40 | screen 7: 13 objects | `Delay` | `Delay` |
| `$C9E0` | `Screen008Layout` (`Screen000Layout`+242) | 34 | screen 8: 11 objects | `Delay` | `Delay` |
| `$CA02` | `Screen009Layout` (`Screen000Layout`+276) | 40 | screen 9: 13 objects | `Delay` | `Delay` |
| `$CA2A` | `Screen010Layout` (`Screen000Layout`+316) | 34 | screen 10: 11 objects | `Delay` | `Delay` |
| `$CA4C` | `Screen011Layout` (`Screen000Layout`+350) | 49 | screen 11: 16 objects | `Delay` | `Delay` |
| `$CA7D` | `Screen012Layout` (`Screen000Layout`+399) | 40 | screen 12: 13 objects | `Delay` | `Delay` |
| `$CAA5` | `Screen013Layout` (`Screen000Layout`+439) | 25 | screen 13: 8 objects | `Delay` | `Delay` |
| `$CABE` | `Screen014Layout` (`Screen000Layout`+464) | 40 | screen 14: 13 objects | `Delay` | `Delay` |
| `$CAE6` | `Screen015Layout` (`Screen000Layout`+504) | 25 | screen 15: 8 objects | `Delay` | `Delay` |
| `$CAFF` | `Screen016Layout` (`Screen000Layout`+529) | 25 | screen 16: 8 objects | `Delay` | `Delay` |
| `$CB18` | `Screen017Layout` (`Screen000Layout`+554) | 28 | screen 17: 9 objects | `Delay` | `Delay` |
| `$CB34` | `Screen018Layout` (`Screen000Layout`+582) | 40 | screen 18: 13 objects | `Delay` | `Delay` |
| `$CB5C` | `Screen019Layout` (`Screen000Layout`+622) | 28 | screen 19: 9 objects | `Delay` | `Delay` |
| `$CB78` | `Screen020Layout` (`Screen000Layout`+650) | 37 | screen 20: 12 objects | `Delay` | `Delay` |
| `$CB9D` | `Screen021Layout` (`Screen000Layout`+687) | 37 | screen 21: 12 objects | `Delay` | `Delay` |
| `$CBC2` | `Screen022Layout` (`Screen000Layout`+724) | 25 | screen 22: 8 objects | `Delay` | `Delay` |
| `$CBDB` | `Screen023Layout` (`Screen000Layout`+749) | 31 | screen 23: 10 objects | `Delay` | `Delay` |
| `$CBFA` | `Screen024Layout` (`Screen000Layout`+780) | 22 | screen 24: 7 objects | `Delay` | `Delay` |
| `$CC10` | `Screen025Layout` (`Screen000Layout`+802) | 37 | screen 25: 12 objects | `Delay` | `Delay` |
| `$CC35` | `Screen026Layout` (`Screen000Layout`+839) | 25 | screen 26: 8 objects | `Delay` | `Delay` |
| `$CC4E` | `Screen027Layout` (`Screen000Layout`+864) | 34 | screen 27: 11 objects | `Delay` | `Delay` |
| `$CC70` | `Screen028Layout` (`Screen000Layout`+898) | 19 | screen 28: 6 objects | `Delay` | `Delay` |
| `$CC83` | `Screen029Layout` (`Screen000Layout`+917) | 46 | screen 29: 15 objects | `Delay` | `Delay` |
| `$CCB1` | `Screen030Layout` (`Screen000Layout`+963) | 37 | screen 30: 12 objects | `Delay` | `Delay` |
| `$CCD6` | `Screen031Layout` (`Screen000Layout`+1000) | 34 | screen 31: 11 objects | `Delay` | `Delay` |
| `$CCF8` | `Screen032Layout` (`Screen000Layout`+1034) | 31 | screen 32: 10 objects | `Delay` | `Delay` |
| `$CD17` | `Screen033Layout` (`Screen000Layout`+1065) | 34 | screen 33: 11 objects | `Delay` | `Delay` |
| `$CD39` | `Screen034Layout` (`Screen000Layout`+1099) | 46 | screen 34: 15 objects | `Delay` | `Delay` |
| `$CD67` | `Screen035Layout` (`Screen000Layout`+1145) | 22 | screen 35: 7 objects | `Delay` | `Delay` |
| `$CD7D` | `Screen036Layout` (`Screen000Layout`+1167) | 19 | screen 36: 6 objects | `Delay` | `Delay` |
| `$CD90` | `Screen037Layout` (`Screen000Layout`+1186) | 28 | screen 37: 9 objects | `Delay` | `Delay` |
| `$CDAC` | `Screen038Layout` (`Screen000Layout`+1214) | 31 | screen 38: 10 objects | `Delay` | `Delay` |
| `$CDCB` | `Screen039Layout` (`Screen000Layout`+1245) | 34 | screen 39: 11 objects | `Delay` | `Delay` |
| `$CDED` | `Screen040Layout` (`Screen000Layout`+1279) | 28 | screen 40: 9 objects | `Delay` | `Delay` |
| `$CE09` | `Screen041Layout` (`Screen000Layout`+1307) | 40 | screen 41: 13 objects | `Delay` | `Delay` |
| `$CE31` | `Screen042Layout` (`Screen000Layout`+1347) | 25 | screen 42: 8 objects | `Delay` | `Delay` |
| `$CE4A` | `Screen043Layout` (`Screen000Layout`+1372) | 31 | screen 43: 10 objects | `Delay` | `Delay` |
| `$CE69` | `Screen044Layout` (`Screen000Layout`+1403) | 16 | screen 44: 5 objects | `Delay` | `Delay` |
| `$CE79` | `Screen045Layout` (`Screen000Layout`+1419) | 37 | screen 45: 12 objects | `Delay` | `Delay` |
| `$CE9E` | `Screen046Layout` (`Screen000Layout`+1456) | 43 | screen 46: 14 objects | `Delay` | `Delay` |
| `$CEC9` | `Screen047Layout` (`Screen000Layout`+1499) | 37 | screen 47: 12 objects | `Delay` | `Delay` |
| `$CEEE` | `Screen048Layout` (`Screen000Layout`+1536) | 37 | screen 48: 12 objects | `Delay` | `Delay` |
| `$CF13` | `Screen049Layout` (`Screen000Layout`+1573) | 31 | screen 49: 10 objects | `Delay` | `Delay` |
| `$CF32` | `Screen050Layout` (`Screen000Layout`+1604) | 43 | screen 50: 14 objects | `Delay` | `Delay` |
| `$CF5D` | `Screen051Layout` (`Screen000Layout`+1647) | 22 | screen 51: 7 objects | `Delay` | `Delay` |
| `$CF73` | `Screen052Layout` (`Screen000Layout`+1669) | 31 | screen 52: 10 objects | `Delay` | `Delay` |
| `$CF92` | `Screen053Layout` (`Screen000Layout`+1700) | 43 | screen 53: 14 objects | `Delay` | `Delay` |
| `$CFBD` | `Screen054Layout` (`Screen000Layout`+1743) | 22 | screen 54: 7 objects | `Delay` | `Delay` |
| `$CFD3` | `Screen055Layout` (`Screen000Layout`+1765) | 31 | screen 55: 10 objects | `Delay` | `Delay` |
| `$CFF2` | `Screen056Layout` (`Screen000Layout`+1796) | 31 | screen 56: 10 objects | `Delay` | `Delay` |
| `$D011` | `Screen057Layout` (`Screen000Layout`+1827) | 40 | screen 57: 13 objects | `Delay` | `Delay` |
| `$D039` | `Screen058Layout` (`Screen000Layout`+1867) | 10 | screen 58: 3 objects | `Delay` | `Delay` |
| `$D043` | `Screen059Layout` (`Screen000Layout`+1877) | 52 | screen 59: 17 objects | `Delay` | `Delay` |
| `$D077` | `Screen060Layout` (`Screen000Layout`+1929) | 37 | screen 60: 12 objects | `Delay` | `Delay` |
| `$D09C` | `Screen061Layout` (`Screen000Layout`+1966) | 37 | screen 61: 12 objects | `Delay` | `Delay` |
| `$D0C1` | `Screen062Layout` (`Screen000Layout`+2003) | 28 | screen 62: 9 objects | `Delay` | `Delay` |
| `$D0DD` | `Screen063Layout` (`Screen000Layout`+2031) | 16 | screen 63: 5 objects | `Delay` | `Delay` |
| `$D0ED` | `Screen064Layout` (`Screen000Layout`+2047) | 28 | screen 64: 9 objects | `Delay` | `Delay` |
| `$D109` | `Screen065Layout` (`Screen000Layout`+2075) | 28 | screen 65: 9 objects | `Delay` | `Delay` |
| `$D125` | `Screen066Layout` (`Screen000Layout`+2103) | 40 | screen 66: 13 objects | `Delay` | `Delay` |
| `$D14D` | `Screen067Layout` (`Screen000Layout`+2143) | 49 | screen 67: 16 objects | `Delay` | `Delay` |
| `$D17E` | `Screen068Layout` (`Screen000Layout`+2192) | 46 | screen 68: 15 objects | `Delay` | `Delay` |
| `$D1AC` | `Screen069Layout` (`Screen000Layout`+2238) | 58 | screen 69: 19 objects | `Delay` | `Delay` |
| `$D1E6` | `Screen070Layout` (`Screen000Layout`+2296) | 64 | screen 70: 21 objects | `Delay` | `Delay` |
| `$D226` | `Screen071Layout` (`Screen000Layout`+2360) | 37 | screen 71: 12 objects | `Delay` | `Delay` |
| `$D24B` | `Screen072Layout` (`Screen000Layout`+2397) | 31 | screen 72: 10 objects | `Delay` | `Delay` |
| `$D26A` | `Screen073Layout` (`Screen000Layout`+2428) | 34 | screen 73: 11 objects | `Delay` | `Delay` |
| `$D28C` | `Screen074Layout` (`Screen000Layout`+2462) | 22 | screen 74: 7 objects | `Delay` | `Delay` |
| `$D2A2` | `Screen075Layout` (`Screen000Layout`+2484) | 31 | screen 75: 10 objects | `Delay` | `Delay` |
| `$D2C1` | `Screen076Layout` (`Screen000Layout`+2515) | 49 | screen 76: 16 objects | `Delay` | `Delay` |
| `$D2F2` | `Screen077Layout` (`Screen000Layout`+2564) | 25 | screen 77: 8 objects | `Delay` | `Delay` |
| `$D30B` | `Screen078Layout` (`Screen000Layout`+2589) | 58 | screen 78: 19 objects | `Delay` | `Delay` |
| `$D345` | `Screen079Layout` (`Screen000Layout`+2647) | 28 | screen 79: 9 objects | `Delay` | `Delay` |
| `$D361` | `Screen080Layout` (`Screen000Layout`+2675) | 31 | screen 80: 10 objects | `Delay` | `Delay` |
| `$D380` | `Screen081Layout` (`Screen000Layout`+2706) | 34 | screen 81: 11 objects | `Delay` | `Delay` |
| `$D3A2` | `Screen082Layout` (`Screen000Layout`+2740) | 43 | screen 82: 14 objects | `Delay` | `Delay` |
| `$D3CD` | `Screen083Layout` (`Screen000Layout`+2783) | 22 | screen 83: 7 objects | `Delay` | `Delay` |
| `$D3E3` | `Screen084Layout` (`Screen000Layout`+2805) | 28 | screen 84: 9 objects | `Delay` | `Delay` |
| `$D3FF` | `Screen085Layout` (`Screen000Layout`+2833) | 16 | screen 85: 5 objects | `Delay` | `Delay` |
| `$D40F` | `Screen086Layout` (`Screen000Layout`+2849) | 31 | screen 86: 10 objects | `Delay` | `Delay` |
| `$D42E` | `Screen087Layout` (`Screen000Layout`+2880) | 31 | screen 87: 10 objects | `Delay` | `Delay` |
| `$D44D` | `Screen088Layout` (`Screen000Layout`+2911) | 28 | screen 88: 9 objects | `Delay` | `Delay` |
| `$D469` | `Screen089Layout` (`Screen000Layout`+2939) | 34 | screen 89: 11 objects | `Delay` | `Delay` |
| `$D48B` | `Screen090Layout` (`Screen000Layout`+2973) | 46 | screen 90: 15 objects | `Delay` | `Delay` |
| `$D4B9` | `Screen091Layout` (`Screen000Layout`+3019) | 31 | screen 91: 10 objects | `Delay` | `Delay` |
| `$D4D8` | `Screen092Layout` (`Screen000Layout`+3050) | 25 | screen 92: 8 objects | `Delay` | `Delay` |
| `$D4F1` | `Screen093Layout` (`Screen000Layout`+3075) | 37 | screen 93: 12 objects | `Delay` | `Delay` |
| `$D516` | `Screen094Layout` (`Screen000Layout`+3112) | 28 | screen 94: 9 objects | `Delay` | `Delay` |
| `$D532` | `Screen095Layout` (`Screen000Layout`+3140) | 31 | screen 95: 10 objects | `Delay` | `Delay` |
| `$D551` | `Screen096Layout` (`Screen000Layout`+3171) | 37 | screen 96: 12 objects | `Delay` | `Delay` |
| `$D576` | `Screen097Layout` (`Screen000Layout`+3208) | 34 | screen 97: 11 objects | `Delay` | `Delay` |
| `$D598` | `Screen098Layout` (`Screen000Layout`+3242) | 31 | screen 98: 10 objects | `Delay` | `Delay` |
| `$D5B7` | `Screen099Layout` (`Screen000Layout`+3273) | 25 | screen 99: 8 objects | `Delay` | `Delay` |
| `$D5D0` | `Screen100Layout` (`Screen000Layout`+3298) | 25 | screen 100: 8 objects | `Delay` | `Delay` |
| `$D5E9` | `Screen101Layout` (`Screen000Layout`+3323) | 19 | screen 101: 6 objects | `Delay` | `Delay` |
| `$D5FC` | `Screen102Layout` (`Screen000Layout`+3342) | 34 | screen 102: 11 objects | `Delay` | `Delay` |
| `$D61E` | `Screen103Layout` (`Screen000Layout`+3376) | 19 | screen 103: 6 objects | `Delay` | `Delay` |
| `$D631` | `Screen104Layout` (`Screen000Layout`+3395) | 46 | screen 104: 15 objects | `Delay` | `Delay` |
| `$D65F` | `Screen105Layout` (`Screen000Layout`+3441) | 37 | screen 105: 12 objects | `Delay` | `Delay` |
| `$D684` | `Screen106Layout` (`Screen000Layout`+3478) | 34 | screen 106: 11 objects | `Delay` | `Delay` |
| `$D6A6` | `Screen107Layout` (`Screen000Layout`+3512) | 31 | screen 107: 10 objects | `Delay` | `Delay` |
| `$D6C5` | `Screen108Layout` (`Screen000Layout`+3543) | 34 | screen 108: 11 objects | `Delay` | `Delay` |
| `$D6E7` | `Screen109Layout` (`Screen000Layout`+3577) | 46 | screen 109: 15 objects | `Delay` | `Delay` |
| `$D715` | `Screen110Layout` (`Screen000Layout`+3623) | 22 | screen 110: 7 objects | `Delay` | `Delay` |
| `$D72B` | `Screen111Layout` (`Screen000Layout`+3645) | 19 | screen 111: 6 objects | `Delay` | `Delay` |
| `$D73E` | `Screen112Layout` (`Screen000Layout`+3664) | 28 | screen 112: 9 objects | `Delay` | `Delay` |
| `$D75A` | `Screen113Layout` (`Screen000Layout`+3692) | 31 | screen 113: 10 objects | `Delay` | `Delay` |
| `$D779` | `Screen114Layout` (`Screen000Layout`+3723) | 34 | screen 114: 11 objects | `Delay` | `Delay` |
| `$D79B` | `Screen115Layout` (`Screen000Layout`+3757) | 28 | screen 115: 9 objects | `Delay` | `Delay` |
| `$D7B7` | `Screen116Layout` (`Screen000Layout`+3785) | 40 | screen 116: 13 objects | `Delay` | `Delay` |
| `$D7DF` | `Screen117Layout` (`Screen000Layout`+3825) | 1 | screen 117: 8 objects | `Delay` | `Delay` |
| `$D7E0` | `FontBase` (`Screen000Layout`+3826) | 24 | GlyphBase of the font: glyph n at `$D7E0` + 8n, so codes `$00-$1F` would fall on this layout; the glyphs start at Font `$D8E0` (code `$20`) | `Delay` | `Delay` |
| `$D7F8` | `Screen118Layout` (`Screen000Layout`+3850) | 31 | screen 118: 10 objects | `Delay` | `Delay` |
| `$D817` | `Screen119Layout` (`Screen000Layout`+3881) | 16 | screen 119: 5 objects | `Delay` | `Delay` |
| `$D827` | `Screen120Layout` (`Screen000Layout`+3897) | 37 | screen 120: 12 objects | `Delay` | `Delay` |
| `$D84C` | `Screen121Layout` (`Screen000Layout`+3934) | 43 | screen 121: 14 objects | `Delay` | `Delay` |
| `$D877` | `Screen122Layout` (`Screen000Layout`+3977) | 37 | screen 122: 12 objects | `Delay` | `Delay` |
| `$D89C` | `Screen123Layout` (`Screen000Layout`+4014) | 37 | screen 123: 12 objects | `Delay` | `Delay` |
| `$D8C1` | `Screen124Layout` (`Screen000Layout`+4051) | 31 | screen 124: 10 objects | `Delay` | `Delay` |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D8E0` | `Font` | 472 | The font: 59 glyphs of 8 bytes, codes `$20-$5A` (space to Z), one glyph a row. GlyphBase FontBase `$D7E0` (set at `$715D`, `$8E1F`, `$8E71`, `$A8DB`, PrintNumber3 `$B0C8`, PrintString `$E7` at `$AFF5`): code n at `$D7E0` + 8n. Thick 7-pixel letters and digits (glyphs.py). In the runs PrintChar and PrintCharAttr read the space, !, the digits, : and the letters. | `Delay`, `PrintChar`, `PrintCharAttr` | `Delay` |
| `$DAB8` | `TileGlyphs` | 4744 | The scenery glyphs: 8 bytes each, one glyph a row, in 23 sets (GlyphBase values). The objects of ObjectTable `$852E` select a set with PrintString `$E6` lo hi and then print codes from 0: glyph n of a set at its base + 8n. A base is any address, the sets follow each other. The code sets three bases itself: `$DAB8` (Mines, `$AB9F`, `$AC2B`), `$DDD8` (AnimateTurrets, for the XOR plotter XorCharAttr), `$E840` (`$A2D5`). strings.py lists for each base the objects that use it and the codes they print; the runs read `$DAB8-$ED3F` as glyphs (PrintChar, EraseBlockDebris, EraseBlock, XorCharAttr), with unread holes at `$DBC0-$DBDF` and `$E5C0-$E5FF`. | `Delay`, `PrintChar`, `PrintCharAttr`, `XorCharAttr` | `Delay` |
| `$DBE8` | `TileSetDBE8` (`TileGlyphs`+304) | 336 | the glyph set of objects 2 | `Delay`, `PrintChar` | `Delay` |
| `$DD38` | `TileSetDD38` (`TileGlyphs`+640) | 160 | the glyph set of objects 3, 4, 35, 37 | `Delay`, `PrintChar` | `Delay` |
| `$DDD8` | `TileSetDDD8` (`TileGlyphs`+800) | 256 | the glyph set of objects 5, 44 | `Delay`, `PrintChar`, `XorCharAttr` | `Delay` |
| `$DED8` | `TileSetDED8` (`TileGlyphs`+1056) | 160 | the glyph set of objects 6, 7, 8, 9, 10, 14, 41, 56, 57, 58, 59, 60, 61 | `Delay`, `PrintChar` | `Delay` |
| `$DF78` | `TileSetDF78` (`TileGlyphs`+1216) | 160 | the glyph set of objects 11, 25 | `Delay`, `PrintChar` | `Delay` |
| `$E018` | `TileSetE018` (`TileGlyphs`+1376) | 248 | the glyph set of objects 13 | `Delay`, `PrintChar` | `Delay` |
| `$E110` | `TileSetE110` (`TileGlyphs`+1624) | 336 | the glyph set of objects 15, 16 | `Delay` | `Delay` |
| `$E260` | `TileSetE260` (`TileGlyphs`+1960) | 96 | the glyph set of objects 17 | `Delay` | `Delay` |
| `$E2C0` | `TileSetE2C0` (`TileGlyphs`+2056) | 32 | the glyph set of objects 18, 19, 20 | `Delay` | `Delay` |
| `$E2E0` | `TileSetE2E0` (`TileGlyphs`+2088) | 160 | the glyph set of objects 21 | `Delay` | `Delay` |
| `$E380` | `TileSetE380` (`TileGlyphs`+2248) | 200 | the glyph set of objects 23, 24, 27, 38 | `Delay` | `Delay` |
| `$E448` | `TileSetE448` (`TileGlyphs`+2448) | 144 | the glyph set of objects 26, 30, 36 | `Delay`, `PrintChar` | `Delay` |
| `$E4D8` | `TileSetE4D8` (`TileGlyphs`+2592) | 296 | the glyph set of objects 28, 29 | `Delay` | `Delay` |
| `$E600` | `TileSetE600` (`TileGlyphs`+2888) | 576 | the glyph set of objects 31, 32 | `Delay`, `PrintChar` | `Delay` |
| `$E840` | `TileSetE840` (`TileGlyphs`+3464) | 32 | the glyph set of objects 33, 34, 55 | `Delay`, `PrintChar`, `PrintCharAttr` | `Delay` |
| `$E860` | `TileSetE860` (`TileGlyphs`+3496) | 224 | the glyph set of objects 40, 41 | `Delay` | `Delay` |
| `$E940` | `TileSetE940` (`TileGlyphs`+3720) | 232 | the glyph set of objects 42, 43 | `Delay` | `Delay` |
| `$EA28` | `TileSetEA28` (`TileGlyphs`+3952) | 200 | the glyph set of objects 44, 45 | `Delay` | `Delay` |
| `$EAF0` | `TileSetEAF0` (`TileGlyphs`+4152) | 248 | the glyph set of objects 46, 47, 48, 49, 50 | `Delay` | `Delay` |
| `$EBE8` | `TileSetEBE8` (`TileGlyphs`+4400) | 96 | the glyph set of objects 51 | `Delay` | `Delay` |
| `$EC48` | `TileSetEC48` (`TileGlyphs`+4496) | 248 | the glyph set of objects 52, 53, 54 | `Delay` | `Delay` |
| `$ED40` | `SmallSprites` | 576 | 9 small XOR sprites, 16 x 8 pixels, each in 4 pre-shifted copies: 64 bytes a sprite. DrawSmallSprite: A the sprite, D the pixel line, E the X (2-pixel units); the copy (E AND 3) at `$ED40` + 64A + 16 (E AND 3), 8 rows of 2 bytes XORed onto the screen at PixelAddress (POPs through SP, BC = `$0407`: 4 passes of 2 rows). Drawn twice it is gone. Each copy is shifted 2 pixels right of the one before (bitmap.py). | `Delay` | `Delay` |
| `$ED80` | `SmallSprite1` (`SmallSprites`+64) | 64 | the same pointing left | `Delay` | `Delay` |
| `$EDC0` | `SmallSprite2` (`SmallSprites`+128) | 64 | a spark (the debris particle: `$9537`, A = 2) | `Delay` | `Delay` |
| `$EE00` | `SmallSprite3` (`SmallSprites`+192) | 64 | a cluster of dots | `Delay` | `Delay` |
| `$EE40` | `SmallSprite4` (`SmallSprites`+256) | 64 | a smaller cluster | `Delay` | `Delay` |
| `$EE80` | `SmallSprite5` (`SmallSprites`+320) | 64 | three dots | `Delay` | `Delay` |
| `$EEC0` | `SmallSprite6` (`SmallSprites`+384) | 64 | blank | `Delay` | `Delay` |
| `$EF00` | `SmallSprite7` (`SmallSprites`+448) | 64 | a round blob, 8 x 8 (drawn at `$9DB8` with A = 8 before PlaySfxNoiseSweep) | `Delay` | `Delay` |
| `$EF40` | `SmallSprite8` (`SmallSprites`+512) | 64 | a short bar | `Delay` | `Delay` |
| `$EF80` | `PlayerFrames` | 2400 | The player's 25 frames, 24 x 32 pixels: 32 rows of 3 bytes, 96 bytes a frame. DrawBigSprite: A the frame, the rows from `$EF80` + 96A (POPs through SP), shifted at drawing by (E * 2) AND 7 pixels through the shift table `$78CA`, the screen under it saved in the caller's buffer (the player's at WorkArea `$B181`) unless that is NoSaveBuffer. Frames 0-23: the soldier in his suit, 24 poses. FlipPlayerFrames mirrors exactly those 24 in place (768 rows: the outer bytes swapped, each byte bit-reversed through the table at `$6400`) and toggles `$7BDA`, so the frames face the way the player walks. Frame 24 (`$F880`, not mirrored) is no soldier: a bar on a post over a striped block (bitmap.py). | `Delay`, `FlipPlayerFrames` | `Delay`, `FlipPlayerFrames` |
| `$F8E0` | `Sprites16` | 1440 | 45 sprites of 16 x 16 pixels: 16 rows of 2 bytes, 32 bytes each. DrawSprite: A the sprite, the rows from `$F8E0` + 32A (POPs through SP), shifted at drawing by (E * 2) AND 7 through the table `$7AD9`. The shapes (bitmap.py): 0 blank; 1-4 a round body with a moving dot; 5-10 a ring of dots thinning out; 11 a wedge with a trail; 12-15 a cross growing rays; 16-19 a disc turning edge-on; 20-23 a striped capsule in four phases; 24-27 and 37-44 a horizontal launcher shape in phases; 28-36 thin arcs and lines (fragments). Which enemy uses which is for the routines that pass A. | `Delay` | `Delay` |
| `$FE80` | `SpriteSpare` | 152 | 152 zero bytes after sprite 44 (no reader) | `Delay` | `Delay` |

## leftover

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FF18` | `LeftoverStack` | 96 | Leftover of the development machine: its BASIC machine stack. Words such as `$0DF3`, `$0BCE`, `$171E`, `$0ADC` (48K ROM addresses), `$50E2`, `$6D5F`, and at `$FF54` `$1303` (the address the 48K ROM keeps at the bottom of every BASIC stack, the error return to MAIN-4), then `$3E` at `$FF57`: the marker byte the ROM puts at RAMTOP, here `$FF57`, the 48K default. The image was saved from a 48K whose BASIC stack and user-defined graphics lay at the top of RAM. No reader in any recording. | `Delay` | `Delay` |
| `$FF58` | `LeftoverUdgs` (`LeftoverStack`+64) | 32 | `$FF58-$FF77`: the user-defined graphics A-D as the ROM sets them (copies of the ROM font's A, B, C, D) | `Delay` | `Delay` |
| `$FFDB` | `SerialSum` | 37 | The downloader's checksum | `Delay`, `SerialDownloader` (code), `SerialReadByte` (code) | `Delay`, `SerialDownloader` (code), `SerialReadByte` (code) |
| `$FFDC` | `LeftoverCode` (`SerialSum`+1) | 36 | `$FFDC-$FFFA`: an older copy of SerialReadByte's tail (the bytes of `$FFB3-$FFD1`, then CPL and RET: no checksum); `$FFFB-$FFFF` the end of UDG U | `Delay` | `Delay` |
