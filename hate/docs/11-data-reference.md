# 11. Data reference

Every data entry of the game image `$5FB4`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/p2`, `work/game`; the playfield buffer's accesses over the title player and
the start-up are not counted as theirs). The object records are laid out in
[7. Objects](07-objects.md), the course data in [6. Rendering](06-rendering.md).
Written by `tools/refdocs.py`.

## buffers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5FB4` | `ProfileMargin` | 76 | Bytes below the ground profile. 76 bytes just below the ground profile `$6000`. In the image they hold mask/pixel byte pairs left from the build; the screen copy at `$9F1C` overwrites them from `$BFB4-$BFFF` (the image of `$5B00-$5FFF`) before play. The profile readers index from `$5FF6-$5FF8` (`$DA1E`, `$DAA1`, `$DB1B`, `$E3E5`, `$E94F`), so the top of this block is the profile's left margin. | - | `StartGame`, `Startup` |
| `$6000` | `ProfileBuffer` | 424 | Ground profile buffer (768 bytes). The course's profile under the scroll, one byte for every 2 units along the course: the ground height (bits 0-4) and the walls (bits 5-7); docs/07-objects.md 7.4. Cleared at every round start (`$CF68`, `$D0EF`). In the image it holds leftovers of the build, and the entry `$61A8` sits inside it: code that runs once and then becomes buffer space (docs/02-architecture.md 2.2). | `BuildGroundProfile`, `BuildSpriteLists`, `DrawShadows`, `GameEntry`, `MainLoop` +12 | `BuildGroundProfile`, `GameEntry`, `MainLoop` |
| `$61AF` | `GroundProfileTail` | 337 | Ground profile buffer, after the entry. The rest of the profile buffer, to `$62FF`. The first 42 bytes are leftover loader code that never runs, the rest is zero. | `BuildGroundProfile`, `BuildSpriteLists`, `DrawShadows`, `GameEntry`, `MainLoop` +12 | `BuildGroundProfile`, `GameEntry`, `MainLoop` |
| `$6300` | `Font` | 216 | Font, codes `$20-$3A`. 64 glyphs of 8 bytes for codes `$20-$5F` at `$6300-$64FF`, glyph = `$6300` + (code - `$20`) * 8; printed by `$EE17` and, lines 2-6 only, by `$EEA4` (docs/08-hud-and-text.md 8.2). Codes `$22-$2C` are the big GAME OVER, `$2E` a red block, `$2F` a gauge segment. The glyph slots of ";" to "?" and "[" to "_" hold strings instead (next entries). | `DrawDigits`, `PrintString` | - |
| `$63D8` | `CreditsText1` | 40 | Credits, first part (in the font's ";" to "?" slots). A print string for `$EE17` (records: attribute + `$80`, column, row, characters; `$FF` ends): "WRITTEN BY", "COSTA PANAYI", "MUSIC BY" at column 1, rows 17-19, attribute `$30`. Printed by the menu `$F1AA`; docs/08-hud-and-text.md 8.3. | `PrintString` | - |
| `$6400` | `FontHigh` | 216 | Font, codes `$40-$5A`. The second half of the font: the (c) sign at code `$40` ("@" in the strings) and the capitals. | `PrintString` | - |
| `$64D8` | `CreditsText2` | 30 | Credits, second part (in the font's "[" to "_" slots). "BEN DAGLISH", "(c)1989 VORTEX" at column 1, rows 20-21. Printed by the menu `$F1AA`. | `PrintString` | - |
| `$64F6` | `AutoText` | 10 | " AUTO " in the top window. Printed at (2,6) by the AUTO start in `$E68C` (docs/05-controls.md 5.4). | `PrintString` | - |
| `$6500` | `SpriteScratch` | 128 | Visible-record list and sprite scratch page. Work space of the sprite code. `$EFA5` builds the list of visible records here each pass (pointer kept at `$EF9F`, `$40` ends the list) and `$F089` scans it; `$DE08` fills `$6500-$6543` with `$FF` as scratch. Zero in the image. | `BuildSpriteLists`, `DrawShadows`, `MaskAnd3`, `MaskAnd4`, `MaskAnd5` +7 | `DrawShadows`, `MaskAnd3`, `MaskAnd4`, `MaskAnd5`, `MaskAnd6` +5 |
| `$6580` | `SpriteGfx00` | 630 | Sprite graphics, table slot `$00`. The sprite graphics run from here to `$7FFF`. Each block is reached through the pointer table `$C300` by a record's byte +8 (the low byte of the address into `$C300`): 2 x type, for the player at `$D246` (`$C008`) and for every record from `$C060` at each round setup (`$D2E3`); the templates `$C2B4-$C2E1` and `$C360`/`$C370` carry their own. The block boundaries below are the table's pointers. | `DrawSprites` | - |
| `$67F6` | `SpriteGfx02` | 630 | Sprite graphics, table slot `$02` | `DrawSprites` | - |
| `$6A6C` | `SpriteGfx04` | 630 | Sprite graphics, table slot `$04` | - | - |
| `$6CE2` | `SpriteGfx06` | 630 | Sprite graphics, table slot `$06` | `DrawSprites` | - |
| `$6F58` | `SpriteGfx1C` | 420 | Sprite graphics, table slot `$1C` | `StampStatics` | - |
| `$70FC` | `SpriteGfx1E` | 420 | Sprite graphics, table slot `$1E` | `StampStatics` | - |
| `$72A0` | `SpriteGfx14` | 374 | Sprite graphics, table slot `$14` | `DrawSprites` | - |
| `$7416` | `SpriteGfx08` | 374 | Sprite graphics, table slot `$08` (the type 4 missile template) | `DrawSprites` | - |
| `$758C` | `SpriteGfx0A` | 374 | Sprite graphics, table slots `$0A` and `$0C` (the type 6 missile template) | `DrawSprites` | - |
| `$7702` | `SpriteGfx0E` | 374 | Sprite graphics, table slot `$0E` (the type 7 missile template) | `DrawSprites` | - |
| `$7878` | `SpriteGfx10` | 374 | Sprite graphics, table slots `$10` and `$12` (the jet templates) | `DrawSprites` | - |
| `$79EE` | `SpriteGfx16` | 182 | Sprite graphics, table slot `$16` | `DrawSprites` | - |
| `$7AA4` | `SpriteGfx18` | 182 | Sprite graphics, table slot `$18` (shots: templates `$C360`, `$C2E1`) | `DrawSprites` | - |
| `$7B5A` | `SpriteGfx1A` | 182 | Sprite graphics, table slot `$1A` (the shell: template `$C370`) | `DrawSprites` | - |
| `$7C10` | `ExplosionGfx22` | 168 | Explosion frame, table slot `$22`. The explosion: a hit record's byte +8 is set to `$20` (`$EBD1`, `$E262`) and counts up by 2 a pass to `$2C` (`$E235`), so the frames are the slots `$20-$2C`; slot `$20` and `$24` share one picture. | `DrawSprites` | - |
| `$7CB8` | `ExplosionGfx20` | 168 | Explosion frame, table slots `$20` and `$24` | `DrawSprites` | - |
| `$7D60` | `ExplosionGfx26` | 168 | Explosion frame, table slot `$26` | `DrawSprites` | - |
| `$7E08` | `ExplosionGfx28` | 168 | Explosion frame, table slot `$28` | `DrawSprites` | - |
| `$7EB0` | `ExplosionGfx2A` | 168 | Explosion frame, table slot `$2A` | `DrawSprites` | - |
| `$7F58` | `ExplosionGfx2C` | 168 | Explosion frame, table slot `$2C` (the last before the record is gone). Its first and last strips (`$7F58-$7F81`, `$7FD6-$7FFF`) are blank (`FF 00`: mask `$FF`, no ink), the only blank strips of the explosion frames: the burst has thinned to its middle | `DrawSprites` | - |

## titleplayer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$80C2` | `CmdModeA` | 12 | Title commands 5 and 6: envelope mode of voice A (not run). Two handlers that did not run in the recording: POP HL; LD B,1; JP `$8088` (command 5, mode 1: hold) and POP HL; LD B,0; JP `$8088` (command 6, mode 0: decay). B of the pattern's register set is voice A's envelope mode; docs/09-sound.md 9.4. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$80DA` | `CmdSilence` | 27 | Title commands 13-15: silence the voices (not run). Three handlers that did not run in the recording. Each zeroes an OUT value operand: command 13 at `$80DA` both (`$82D0` and `$8332`), command 14 at `$80E5` voice A (`$82D0`), command 15 at `$80ED` voice B (`$8332`); then JP `$8088`. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$811C` | `SongReturn` | 6 | Title song byte `$FF`: return (not run). LD HL,nn; JP `$8118`: back to the position saved by `$FE` (the operand `$811D`). The tune of this game uses no sub-song. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$8125` | `SongCall` | 12 | Title song byte `$FE`: call a sub-song (not run). INC HL; LD E,(HL); INC HL; LD D,(HL); INC HL; LD (`$811D`),HL; EX DE,HL; JP `$8118`: saves the position after the address into SongReturn's operand and continues at the address. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$819F` | `NoteABModeA` | 2 | Title command 10: voice A mode 3 (not run). LD B,3: voice A starts in mode 3 when its mode is not 0. Voice A was in mode 0 through the recording. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$81F2` | `NoteAModeA` | 2 | Title command 11: voice A mode 3 (not run). LD B,3, as in command 10. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$8284` | `VoiceAModes` | 31 | Title player: voice A envelope modes 1-3 (not run). DEC A; JR Z,`$82BD` (mode 1: hold); DEC A; JR Z,`$8296` (mode 2: B = 3, voice on, the period reloaded, then a decay step); mode 3: B = 2, voice off (`$82D0` = 0), H = 1, JP `$82C1`. Modes 2 and 3 alternate: a stutter. Voice B's copy of this code ran (`$82E2`). | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$82B1` | `VoiceAOff` | 16 | Title player: voice A's pulse width ran out (not run). INC (HL) (the width back to 1); XOR A; LD (`$82D0`),A (voice A off); LD A,B; AND A; JP Z,`$82BD`; LD B,1 (a mode other than 0 becomes hold); `$82BD`: EXX; JP `$82C5`. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$8313` | `VoiceBOff` | 16 | Title player: voice B's pulse width ran out (not run). INC (HL); XOR A; LD (`$8332`),A (voice B off); LD A,C; AND A; JP Z,`$831F`; LD C,1; `$831F`: EXX; JP `$8327`. The JR Z,`$831F` at `$82E7` (mode 1) enters at its tail. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$83E2` | `TitleStack` | 21 | Title player's stack. SP points at `$83F7` from `$803E` on: the interrupts and the command dispatch push here. Stale bytes in the image. | `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$83F7` | `TitleVectorAddr` | 2 | The IM 2 vector address. Written at `$8049` (`$FDFD` when I = `$FE`), read by the exit `$8357`. The image holds a stale value. | `TitleInterrupt`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack`, `TitleSetup` |
| `$83F9` | `TitleVectorSave` | 3 | The 3 bytes the title replaced at the vector. Saved at `$8052`, put back at `$8361`. | `TitleInterrupt`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack`, `TitleSetup` |
| `$83FC` | `TitleCommands` | 38 | Pattern command handlers 0-18. Read by `$8088`, 2 bytes a command: 0 `$8175` hold, 1-4 `$8098-$80B9` voice parameters, 5-8 `$80C2-$80D4` envelope modes, 9 `$8109` end of pattern, 10-12 `$819B`, `$81EE`, `$821A` notes, 13-15 `$80DA-$80ED` silence, 16 `$8101` drums, 17 `$80F5` note length, 18 `$817A` long note; docs/09-sound.md 9.3. | `PatternCommand`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$8422` | `TitlePatches` | 27 | Patch list: 9 x (address, byte). Applied by `$803A` at every start: periods `$64` (`$82CA`, `$832C`), both voices silenced (`$82D0`, `$8332`), pulse widths `$17` (`$82D4`, `$8336`), pre-delays 1 (`$82CC`, `$832E`), the long-note counter 0 (`$817B`). | `TitlePlayer`, `TitlePlayerSwapBack`, `TitleSetup` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$843D` | `TuneTable` | 2 | Tune table. One song address a tune, picked by C at `$806F`. Tune 0 is `$843F`. | `TitlePlayer`, `TitlePlayerSwapBack`, `TitleSetup` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$843F` | `TuneSong` | 40 | Tune 0: the song. Song entries (`$8118`): n and a pattern address, `$FB` and a drum pattern address, `$FD` and an address (jump). It plays `$8467` once, then `$8473` x5, `$84A8`, `$84C6` x2, `$853B`, `$84C6` x2, `$853B` with drums `$85A2` and `$85B4`, and jumps back to the start at `$8460`: the tune loops until a key. The last 4 bytes (pattern `$83E8`, `$FC`) are never reached. | `DrumStart`, `SongStep`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$8467` | `PatternInit` | 12 | Tune 0: set-up pattern. Command 8 (voice B mode 0), 17 (note length 5), 1-4 (the voices' parameters), 9 (end). Pattern commands are listed at `$83FC`. | `CmdEnvelopeA`, `CmdEnvelopeB`, `CmdNoteLength`, `CmdWidthA`, `CmdWidthB` +3 | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$8473` | `PatternA` | 53 | Tune 0: pattern A. Notes: command 10 with two periods, 11 or 12 with one; 0 holds, 18 n holds n note lengths, 9 ends the pattern. | `CmdLongNote`, `CmdNoteAB`, `PatternCommand`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$84A8` | `PatternB` | 30 | Tune 0: pattern B | `CmdNoteA`, `CmdNoteAB`, `PatternCommand`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$84C6` | `PatternC` | 117 | Tune 0: pattern C | `CmdLongNote`, `CmdNoteA`, `CmdNoteAB`, `CmdNoteB`, `PatternCommand` +2 | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$853B` | `PatternD` | 103 | Tune 0: pattern D. Uses command 16 at `$8583` to switch to the drums `$85B4`. | `CmdLongNote`, `CmdNoteAB`, `DrumStart`, `PatternCommand`, `TitlePlayer` +1 | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$85A2` | `DrumPatternA` | 18 | Drum pattern: clicks and noise. The speed (5 frames a step), then the steps: 2 click, 3 noise, 0 rest, 1 loop; docs/09-sound.md 9.5. | `DrumStart`, `DrumTick`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$85B4` | `DrumPatternB` | 18 | Drum pattern: the three tones. Speed 5, then the drums 4 (rising), 5 (sweep) and 6 (falling) and 1 loop. | `DrumStart`, `DrumTick`, `TitlePlayer`, `TitlePlayerSwapBack` | `TitlePlayer`, `TitlePlayerSwapBack` |
| `$85C6` | `TitleTail` | 58 | Unused, zero | - | - |

## startup

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8600` | `StartupCopy` | 106 | A stale copy of `$9F00-$9F69`. Never run. The bytes equal the start-up block `$9F00-$9F69` (with its PRESS ANY KEY string at `$862F`): a copy left `$1900` bytes below its place. The whole of `$8700-$9FFF` repeats `$6E00-$86FF` this way (next entries). | - | - |
| `$866A` | `StartupCopyTail` | 150 | Unused, zero | - | - |
| `$8700` | `SpriteGfxCopy` | 4608 | A stale copy of the sprite graphics `$6E00-$7FFF`. Byte for byte the same as `$6E00-$7FFF`. The start-up head at `$9F00` (not run in this version) moves `$7C00-$9FFF` down to `$6300`, which would put this copy in place; here the data is already there. Overwritten by the playfield in play. | - | - |
| `$9900` | `TitlePlayerCopy` | 1536 | A stale copy of the title player `$8000-$85FF`. The same bytes as `$8000-$85FF` except the player's self-modified operands, which are 0 here (`$9985` for `$8085`, `$9C64` for `$8364` and others): the player as assembled, before a run. The copy at `$8000` carries the values of a run. | - | - |
| `$9F00` | `StartupHead` | 18 | Start-up head (not run). DI; LD HL,`$7C00`; LD DE,`$6300`; LD BC,`$2400`; LDIR (move the font and graphics down to their place) then LD HL,`$9F2F`; CALL `$EE17` (print PRESS ANY KEY). The game enters at `$9F12`, after these bytes; docs/08-hud-and-text.md 8.3. | - | - |
| `$9F2F` | `PressKeyText` | 28 | "PRESS ANY KEY WHEN READY". A print string for `$EE17` at (4,23), attribute 7. Only the start-up head `$9F00` and its copy print it; neither ran. | - | - |
| `$9F68` | `DefaultInterrupt` | 2 | Default IM 2 handler: EI; RET. The target of JP `$FDFD` until the title player hooks it. Data in the recording: it never ran. | - | - |
| `$9F6A` | `StartupPad` | 150 | Unused, zero | - | - |
| `$A000` | `GameScreenImage` | 6144 | Game screen image: pixels. The play screen with its panel, copied to `$4000` by `$9F1C` when play starts (`$A000-$B7FF` the pixels). Part of the playfield buffer afterwards. | `StartGame`, `Startup` | - |
| `$B800` | `GameScreenAttrs` | 768 | Game screen image: attributes. Copied to `$5800-$5AFF`. | `StartGame`, `Startup` | - |
| `$BB00` | `RendererTablesImage` | 1280 | Image of `$5B00-$5FFF`: the renderer's tables. The last 1 280 bytes of the copy land at `$5B00-$5FFF`. The renderer reads them there: `$5B00`, `$5B20`, `$5B40` (`$E011-$E01E`), `$5B60`, `$5C60`, `$5BE0` (`$DF23-$DF31`) and `$5DE8`, `$5EF0`, `$5CE0` (`$DE1C-$DE29`). `$BFB4-$BFFF` become ProfileMargin. | `StartGame`, `Startup` | - |

## gamedata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C000` | `PlayerRecord` | 16 | Object record: the player. Every moving or hittable thing is a 16-byte record in the list `$C000-$C26F`, ended by `$FF` at `$C270`; docs/07-objects.md 7.1-7.2. +0 flags and type (bit 7 gone, 6 end, 5 hit, 0-3 type), +1/+2 position along, +3 across, +4 height, +5 direction, +6 speed, +7 behaviour, +8 the sprite slot in `$C300` (also the explosion frame), +9-+B screen place, +C/+E motion steps, +F fire timer. Zero in the image: the round start fills the list. Bit 7 of `$C000` set is a lost life (`$CFEF`). | `BuildSpriteLists`, `ConvoyFollow`, `GameEntry`, `HitBoth`, `HitDispatch` +14 | `GameEntry`, `HitBoth`, `MainLoop`, `MoveRecord`, `PlaceObject` +4 |
| `$C010` | `PlayerShotRecords` | 80 | Object records: the player's shots (5). `$E82F` fires into a free one; `$CFD6` counts the free ones for the gauge. | `BuildSpriteLists`, `GameEntry`, `HitBoth`, `HitDispatch`, `HitPlayerOnShot` +14 | `GameEntry`, `HitBoth`, `HitShotOnBlock`, `MainLoop`, `MovePlayer` +4 |
| `$C060` | `PodRecords` | 64 | Object records: pods (4). Released by shot domes (`$EDFE`); docs/07-objects.md 7.5. | `BuildSpriteLists`, `ConvoyFollow`, `HitDispatch`, `HitPlayerOnPod`, `HitShotOnBlock` +7 | `ConvoyFollow`, `GameEntry`, `HitPlayerOnPod`, `HitShotOnDome`, `MainLoop` +5 |
| `$C0A0` | `ParkedVehicleRecord` | 16 | Object record: the vehicle of the other kind. Parked at position `$600`, from VehicleTemplate (`$D1FB`); the vehicle of the next round. | `BuildSpriteLists`, `MoveRecord`, `NextMover`, `PairScan`, `PlaceObject` +2 | `GameEntry`, `MainLoop`, `PlaceObject`, `RoundSetup` |
| `$C0B0` | `CourseObjectRecords` | 256 | Object records: the course's objects (16). The round's block of the course data, 8 bytes each, the rest zeroed (`$D250`). | `BuildSpriteLists`, `HitBoth`, `HitDispatch`, `HitShotOnBlock`, `HitShotOnDome` +10 | `GameEntry`, `HitBoth`, `HitShotOnBlock`, `MainLoop`, `MoveRecord` +3 |
| `$C1B0` | `LaunchedRecords` | 96 | Object records: launched missiles and jets (6). Filled from the templates `$C2B4` by a firing object (`$E1DD`). | `BuildSpriteLists`, `HitBoth`, `HitDispatch`, `HitShotOnTarget`, `HitTargetOnShot` +10 | `HitBoth`, `HitTurnRound`, `MoveRecord`, `PlaceObject`, `RoundSetup` +1 |
| `$C210` | `EnemyShotRecords` | 80 | Object records: the enemy's shots (5). Filled from EnemyShotTemplate (`$E1E1`). | `BuildSpriteLists`, `HitDispatch`, `HitShotOnDome`, `HitShotOnTarget`, `HitTargetOnShot` +8 | `HitShotOnDome`, `MoveRecord`, `PlaceObject`, `RoundSetup`, `StoreMove` |
| `$C260` | `PreviousVehicleRecord` | 16 | Object record: the vehicle of the round before. At position `$6C` (`$D27A`). | `BuildSpriteLists`, `HitDispatch`, `HitTargetOnShot`, `MoveRecord`, `NextMover` +6 | `MoveRecord`, `PlaceObject`, `RoundSetup`, `StoreMove` |
| `$C270` | `ObjectListEnd` | 1 | End of the object list (`$FF`) | `NextMover`, `PairScan`, `PlaceObjects`, `RoundSetup` | `RoundSetup` |
| `$C271` | `PassCounter` | 1 | Pass counter of the mover. Incremented once a pass by `$E15C`; steering acts when its low 2 bits are 0 (every 4 passes). | `MoveObjects`, `MoveRecord`, `PairScan` | `MoveObjects` |
| `$C272` | `HeightWave` | 16 | Height wave: 16 steps. Followed by records with behaviour bit 1 (`$E3BF`), index +E mod 16. | `MoveRecord`, `PairScan` | - |
| `$C282` | `MissileArc` | 13 | Height arc of a missile or shell. 9 up to 24 and down to 2, then `$FF`: a height of 25 or more ends the flight (`$E38F`). The shell's start is found in it from the player's height (`$E878`). | `MoveRecord`, `PairScan`, `ReadControls` | - |
| `$C28F` | `InputDevice` | 1 | Input device: 0 keyboard, 1 Sinclair, 2 Kempston, 3 Protek-AGF. Set by the menu (`$F26D`), read by the device reader (`$E6FF`); docs/05-controls.md 5.1. | `Menu`, `PairScan`, `ReadControls` | `Menu` |
| `$C290` | `ControlByte` | 2 | Control byte: bit 0 left, 1 right, 2 down, 3 up, 4 fire. Written once a pass by the device reader `$E68C`; docs/05-controls.md 5.2. The byte after it (`$C291`) is not referenced by address. | `MovePlayer`, `PairScan`, `PlayerSteer`, `ReadControls` | `ReadControls` |
| `$C292` | `PlayerTemplate` | 7 | Player start: +1 to +7 of `$C000`. Position along `$0080`, across `$2C`, height 2, direction 0, speed 1, behaviour 0; copied by `$D1FB` at each round start. | `PairScan`, `RoundSetup` | - |
| `$C299` | `UnusedC299` | 8 | Not referenced by address | `PairScan` | - |
| `$C2A1` | `VehicleTemplate` | 16 | The parked and the previous vehicle records. `$C2A1` is set to the type of the round's vehicle (`$D1FB`) and becomes +0 of `$C260` in the next round (`$D27A`). `$C2A2-$C2B0` are copied to `$C0A1` (position along `$0600`, across `$2C`, height 2); `$C2A4-$C2B0` to `$C263`. | `PairScan`, `RoundSetup` | `RoundSetup` |
| `$C2B4` | `LaunchTemplates` | 45 | Templates of launched objects (5 x 9 bytes). +0 to +8 of a record (the position is then copied from the firer, the rest cleared): type 8 jet, type 7 missile (written at `$D1FB`: course vehicle type + 6), type 8 jet, type 4 missile, type 6 missile. A pad picks one by the highest set bit of its behaviour bits 7-4 (`$E1D7`); the dome of type 2 throws out the third (`$E259`); docs/07-objects.md 7.4. | `MoveRecord`, `PairScan` | `RoundSetup` |
| `$C2E1` | `EnemyShotTemplate` | 9 | Template of an enemy shot. Bytes `1C 00 00 00 00 04 04 00 18`: type 12 (the low nibble; bit 4 set), direction 4, speed 4, sprite slot `$18`; used by firing objects below type 14: `$E1BD` points DE at it and the same `LDIR` at `$E1F5` that copies `LaunchTemplates` copies it. | `MoveRecord`, `PairScan` | - |
| `$C2EA` | `MoverAlong` | 2 | New position along of the record being moved. Written by `$E2D7` (position + direction step x speed), read by the hit window set-up `$E531`. | `MoveRecord`, `StoreMove` | `MoveRecord` |
| `$C2EC` | `HitWindowAlong` | 6 | Hit test window starts, along (3 words). The moving record's new position along less half the box, for the three size classes of the other record; set at `$E531`, compared in `$E586-$E62D`; docs/07-objects.md 7.4. | `PairScan` | `MoveRecord` |
| `$C2F2` | `MoverAcross` | 1 | New position across of the record being moved | `MoveRecord`, `StoreMove` | `MoveRecord` |
| `$C2F3` | `HitWindowAcross` | 3 | Hit test window starts, across (3 bytes) | `PairScan` | `MoveRecord` |
| `$C2F6` | `MoverHeight` | 1 | New height of the record being moved. docs/10-gameplay-logic.md; the terrain check `$E400-$E43B` corrects it. | `MoveRecord`, `PairScan`, `StoreMove` | `GameEntry`, `MainLoop`, `MoveRecord`, `PlayerSteer`, `ReadControls` |
| `$C2F7` | `RoundNumber` | 1 | Round number, 1-10. docs/04-game-loop.md 4.2. | `GameEntry`, `MainLoop`, `PairScan`, `RoundSetup` | `GameEntry`, `MainLoop`, `RoundSetup` |
| `$C2F8` | `LapNumber` | 1 | Lap: passes through the 10 rounds. 0 at the start (`$9F29`); from 1 on the course is armed harder (`$D296`, docs/07-objects.md 7.8). | `PairScan`, `RoundSetup` | `StartGame`, `Startup` |
| `$C2F9` | `Lives` | 1 | Lives of the round | `GameEntry`, `MainLoop` | `RoundSetup` |
| `$C2FA` | `RoundText` | 6 | Round number string: two digits at (21,18). Printed by `$D1BF`; the digits are written into `$C2FD-$C2FE` (the record: `$87`, `$15`, `$12`, digit, digit, `$FF`). | `PrintString` | `RoundSetup` |
| `$C300` | `SpriteTable` | 46 | Sprite graphics pointers. 23 addresses into `$6580-$7FFF`, read as `$C300` + record byte +8 (`$DBEC`, `$DC67`, `$DCD6`, `$EA8F`). Slots `$20-$2C` are the explosion frames. | `BuildSpriteLists`, `PairScan`, `SpriteListBuild`, `StampStatics` | - |
| `$C32E` | `ScrollPage` | 1 | Scroll state: page step 0-63. docs/06-rendering.md 6.2-6.4. | `Blit`, `BuildSpriteLists`, `FreshStrip`, `ScrollStep`, `ShadowListAdd` +2 | `GameEntry`, `MainLoop`, `ScrollStep` |
| `$C32F` | `ScrollHalf` | 1 | Scroll state: strip half, 0 or `$80` | `Blit`, `PlaceObject`, `ScrollStep` | `GameEntry`, `MainLoop`, `ScrollStep` |
| `$C330` | `UnusedC330` | 1 | Not referenced by address | - | - |
| `$C331` | `SavedStack` | 2 | SP saved by the blit and the strip builder. `$D35E` and `$D536` use SP to walk address lists. | `Blit`, `FreshStrip` | `Blit`, `FreshStrip` |
| `$C333` | `ShotGaugeText` | 13 | Shot gauge string. Five cells at (3,6), filled with "/" for each free shot slot by `$CFD6`, then a "/" at (2,6); printed at `$CFE9`; docs/08-hud-and-text.md 8.3. | `PrintString` | `GameEntry`, `MainLoop` |
| `$C340` | `Directions` | 32 | Direction steps: along, across (8 x 4 bytes). Read by `$E2B3`: the word +0 is the step along, the byte +2 the step across; docs/07-objects.md 7.1. | `MoveRecord` | - |
| `$C360` | `ShotTemplate` | 16 | Template of the player's shot. Type 12, direction 0, speed 6, sprite slot `$18`; copied by `$E889`. | `MovePlayer`, `ReadControls` | - |
| `$C370` | `ShellTemplate` | 16 | Template of the ground vehicle's shell. Type 12, speed 6, behaviour bit 2 (the arc `$C282`), sprite slot `$1A`; copied by `$E841`. | `ReadControls` | - |
| `$C380` | `HitHandlers` | 112 | Hit handlers: 7 rows of 8. `$EBAA` jumps to the word at `$C380` + 16 x (moving type / 2) + 2 x (other type / 2). Rows for the moving types 0-1 to 12-13; types 14-15 never move first. `$EBD1` both hit, `$EC0B` nothing, `$EC0F` both turn, `$EC27` player meets a shot, `$E57E` nothing (next pair), the rest score or collect; docs/07-objects.md 7.6. | `HitDispatch` | - |
| `$C3F0` | `WeavePattern` | 8 | Weave: direction sequence 4 5 6 5 4 3 2 3. Behaviour bit 6 (`$E327`), index +C mod 8. | `MoveRecord` | - |
| `$C3F8` | `CourseRowPtr` | 2 | Next row of the expanded course. docs/06-rendering.md 6.5; `$D49C`, `$D536`. | `FreshStrip`, `ScrollStep` | `CourseExpand`, `FreshStrip` |
| `$C3FA` | `StripCount` | 2 | Strips drawn in the round. At 32 the round starts (`$D4BF`). | `ScrollStep` | `CourseExpand`, `GameEntry`, `MainLoop`, `ScrollStep` |
| `$C3FC` | `FreshStripPage` | 2 | Page of the last fresh strip. Written by `$D57F`; docs/06-rendering.md 6.4. | `ScrollStep` | `FreshStrip` |
| `$C3FE` | `UnusedC3FE` | 2 | Not referenced by address | - | - |

## course

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C400` | `Tiles` | 184 | Course tiles 0-22, 8 x 8 bytes. The tile set of the course: 72 tiles of 8 bytes at `$C400` + 8 x tile, one byte (8 pixels) a line, the first byte at the bottom of the strip. FreshStrip (`$D51D`) copies 15 of them into each fresh strip (docs/06-rendering.md 6.5). The tiles are split here only to name the two edge tiles 23 and 24. | `FreshStrip` | - |
| `$C4B8` | `EdgeTiles` | 16 | Edge tiles 23 and 24. The first 8 lines of every fresh strip: tile 23 (`$C4B8`) for three strips in four, tile 24 (`$C4C0`) for the fourth (FreshStrip, `$D534`). No tile run uses them. | `FreshStrip` | - |
| `$C4C8` | `TilesHigh` | 376 | Course tiles 25-71. The rest of the tile set (see Tiles). | `FreshStrip` | - |
| `$C640` | `TileRuns` | 682 | Runs of tile numbers, one per tile across the track. A row of the course is the address of a run in here: tile numbers from the bottom of the strip up, read as row i at offset i by FreshStrip. Runs overlap: rows one byte apart are the same run shifted by one tile, which is how bends are drawn (docs/06-rendering.md 6.5). The rows of all ten courses point between `$C640` and `$C8DB`. | `FreshStrip` | - |
| `$C8EA` | `SegmentRows` | 276 | Row lists of the course segments. A course byte b selects the list at `$C8EA` + 2 x b: row addresses (into TileRuns), ended by a word with a zero high byte. Lists overlap, so a byte can start inside another byte's list. CourseExpand (`$D4D9`) copies them into RowList (docs/06-rendering.md 6.5). One line here is the slot of one even course byte. The 16 zero bytes `$C99E-$C9AD`, the slots of course bytes `$5A-$61`, which no course uses, are the static-object list of StampStatics (`$EA38`) in play. | `CourseExpand`, `StampStatics` | `PlaceObject`, `PlaceObjects` |
| `$C9FE` | `GroundAnchors` | 69 | Ground profile anchors of the course segments. A course byte b selects the list at `$C9FE` + b / 2, ended by `$FF`: one ground anchor byte for every 8 bytes of the profile at `$6000` (height in bits 0-4, walls in bits 5-7, docs/07-objects.md 7.4). GroundProfile (`$D0EF`) interpolates between them. | `BuildGroundProfile` | - |
| `$CA43` | `RowList` | 352 | The row list of the current course (filled by CourseExpand). 176 words, zero in the image, where CourseExpand writes the course's rows (178 for every course, so the last two land on the first two words of RowListTail). `$C3F8` points to the next row a fresh strip starts from. | `ScrollStep` | `CourseExpand` |
| `$CBA3` | `RowListTail` | 32 | Run-out rows after a course, and the end mark `$FFFF`. The rows that follow every course: `$C643` and `$C655` alternating, then `$FFFF` at `$CBC1`. With 178 course rows the list holds 191 rows before the mark. The course check (`$D49C`) looks at the high byte of the row 15 ahead and ends the course at `$FF`. | `ScrollStep` | `CourseExpand` |
| `$CBC3` | `Course7` | 84 | Course data of round 7. A course: the player's type (0 aircraft, 1 ground vehicle), then one segment byte per course piece (indexes into SegmentRows and GroundAnchors), ended by `$FF` (docs/04-game-loop.md 4.2, docs/06-rendering.md 6.5). The ten courses are stored in the order of rounds 7, 8, 9, 10, 3, 2, 1, 6, 5, 4. | - | - |
| `$CC17` | `Course8` | 85 | Course data of round 8 | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CC6C` | `Course9` | 84 | Course data of round 9 | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CCC0` | `Course10` | 79 | Course data of round 10 | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CD0F` | `Course3` | 78 | Course data of round 3 | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CD5D` | `Course2` | 89 | Course data of round 2 | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CDB6` | `Course1` | 84 | Course data of round 1 | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CE0A` | `Course6` | 83 | Course data of round 6 | - | - |
| `$CE5D` | `Course5` | 78 | Course data of round 5 | - | - |
| `$CEAB` | `Course4` | 89 | Course data of round 4 | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CF04` | `CourseTable` | 42 | Course records of rounds 1-10, ended by `$FFFF`. Ten records of two words: the course data, and the round's 128-byte object block at `$F300` + 128 x (round - 1) (docs/04-game-loop.md 4.2, docs/07-objects.md 7.2). `$FFFF` ends the table: CourseExpand wraps to `$CF04` there. | `BuildGroundProfile`, `CourseExpand`, `RoundSetup` | - |
| `$CF2E` | `CourseRecord` | 2 | The current course record. The record of the course being played or scrolled into. NextCourse (`$D4CF`) steps it by 4. | `BuildGroundProfile`, `GameEntry`, `MainLoop`, `RoundSetup`, `ScrollStep` | `GameEntry`, `MainLoop`, `ScrollStep` |
| `$CF30` | `RestartRecord` | 2 | The course record a round start uses. RoundStart (`$CF68`) copies it into CourseRecord. Set by the game start, by RoundSetup (`$D1E1`) and by the look-back (`$D027`). | `GameEntry`, `MainLoop` | `GameEntry`, `MainLoop`, `RoundSetup` |

## roundsetup

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D14D` | `ScrollDistance` | 2 | The distance scrolled into the round. + 2 a pass (ScrollStep). The positions of the object records along the course are in the same unit (docs/07-objects.md 7.1). Cleared at a round start and by RoundSetup. | `MoveRecord`, `PlaceObject`, `ScrollStep` | `GameEntry`, `MainLoop`, `RoundSetup`, `ScrollStep` |
| `$D14F` | `ConvoyShift` | 2 | The player's old position less `$6C`. Set by RoundSetup (`$D209`): subtracted from the positions of the records `$C060-$C090` (the followers), so they keep their place behind the player when the positions start again. | `RoundSetup` | `RoundSetup` |

## scroller

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D5B2` | `BlitAddresses` | 34 | Blit addresses, column 0 (17 cells). 528 screen addresses, the bottom line of a character cell each, popped by Blit: 17 for each even column, 16 for each odd one, from the bottom of the screen up. Even columns sit 4 lines off the odd ones; the list carries the 2:1 isometric skew and the clipping, 43 entries `$0800` pointing into the ROM (docs/06-rendering.md 6.3). PaintAttributes uses the same list to colour the playfield's cells. Split here by column. | `PaintAttributes` | - |
| `$D5D4` | `BlitColumn01` | 32 | Blit addresses, column 1 (16 cells) | `PaintAttributes` | - |
| `$D5F4` | `BlitColumn02` | 34 | Blit addresses, column 2 (17 cells) | `PaintAttributes` | - |
| `$D616` | `BlitColumn03` | 32 | Blit addresses, column 3 (16 cells) | `PaintAttributes` | - |
| `$D636` | `BlitColumn04` | 34 | Blit addresses, column 4 (17 cells) | `PaintAttributes` | - |
| `$D658` | `BlitColumn05` | 32 | Blit addresses, column 5 (16 cells) | `PaintAttributes` | - |
| `$D678` | `BlitColumn06` | 34 | Blit addresses, column 6 (17 cells) | `PaintAttributes` | - |
| `$D69A` | `BlitColumn07` | 32 | Blit addresses, column 7 (16 cells) | `PaintAttributes` | - |
| `$D6BA` | `BlitColumn08` | 34 | Blit addresses, column 8 (17 cells) | `PaintAttributes` | - |
| `$D6DC` | `BlitColumn09` | 32 | Blit addresses, column 9 (16 cells) | `PaintAttributes` | - |
| `$D6FC` | `BlitColumn10` | 34 | Blit addresses, column 10 (17 cells) | `PaintAttributes` | - |
| `$D71E` | `BlitColumn11` | 32 | Blit addresses, column 11 (16 cells) | `PaintAttributes` | - |
| `$D73E` | `BlitColumn12` | 34 | Blit addresses, column 12 (17 cells) | `PaintAttributes` | - |
| `$D760` | `BlitColumn13` | 32 | Blit addresses, column 13 (16 cells) | `PaintAttributes` | - |
| `$D780` | `BlitColumn14` | 34 | Blit addresses, column 14 (17 cells) | `PaintAttributes` | - |
| `$D7A2` | `BlitColumn15` | 32 | Blit addresses, column 15 (16 cells) | `PaintAttributes` | - |
| `$D7C2` | `BlitColumn16` | 34 | Blit addresses, column 16 (17 cells) | `PaintAttributes` | - |
| `$D7E4` | `BlitColumn17` | 32 | Blit addresses, column 17 (16 cells) | `PaintAttributes` | - |
| `$D804` | `BlitColumn18` | 34 | Blit addresses, column 18 (17 cells) | `PaintAttributes` | - |
| `$D826` | `BlitColumn19` | 32 | Blit addresses, column 19 (16 cells) | `PaintAttributes` | - |
| `$D846` | `BlitColumn20` | 34 | Blit addresses, column 20 (17 cells) | `PaintAttributes` | - |
| `$D868` | `BlitColumn21` | 32 | Blit addresses, column 21 (16 cells) | `PaintAttributes` | - |
| `$D888` | `BlitColumn22` | 34 | Blit addresses, column 22 (17 cells) | `PaintAttributes` | - |
| `$D8AA` | `BlitColumn23` | 32 | Blit addresses, column 23 (16 cells) | `PaintAttributes` | - |
| `$D8CA` | `BlitColumn24` | 34 | Blit addresses, column 24 (17 cells) | `PaintAttributes` | - |
| `$D8EC` | `BlitColumn25` | 32 | Blit addresses, column 25 (16 cells) | `PaintAttributes` | - |
| `$D90C` | `BlitColumn26` | 34 | Blit addresses, column 26 (17 cells) | `PaintAttributes` | - |
| `$D92E` | `BlitColumn27` | 32 | Blit addresses, column 27 (16 cells) | `PaintAttributes` | - |
| `$D94E` | `BlitColumn28` | 34 | Blit addresses, column 28 (17 cells) | `PaintAttributes` | - |
| `$D970` | `BlitColumn29` | 32 | Blit addresses, column 29 (16 cells) | `PaintAttributes` | - |
| `$D990` | `BlitColumn30` | 34 | Blit addresses, column 30 (17 cells) | `PaintAttributes` | - |
| `$D9B2` | `BlitColumn31` | 32 | Blit addresses, column 31 (16 cells) | `PaintAttributes` | - |
| `$D9D2` | `BlitListEnd` | 4 | The end mark of BlitAddresses (`$FFFF`), and a spare zero word | `PaintAttributes`, `SaveSpriteStrips` | `BuildSpriteLists`, `SpriteListBuild` |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DD66` | `ShadowListPtr` | 2 | The shadow list's next free entry (`$FE64` on); DrawShadows reuses it to walk the list | `BuildSpriteLists`, `DrawShadows`, `ShadowListAdd`, `ShadowListLoop` | `BuildSpriteLists`, `DrawShadows`, `ShadowListAdd` |
| `$DD68` | `SpriteListPtr` | 2 | The next free entry of the sprite list (`$FF00` on) | `BuildSpriteLists`, `DrawSprites`, `SpriteListBuild` | `BuildSpriteLists`, `DrawSprites`, `SpriteListBuild` |
| `$DD6A` | `SaveAreaPtr` | 2 | The free end of the strip save area (`$F800` on) | `RestoreStrips`, `SaveStrips` | `BuildSpriteLists`, `RestoreStrips`, `RestoreUnderSprites`, `SaveStrips` |

## shadows

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DDE6` | `ShadowGround` | 1 | The ground height under the shadow being drawn | `MaskStepRuns1x6x4`, `MaskStepRuns2x6`, `MaskStepRuns3x5`, `MaskStepRuns3x7x3`, `MaskStepRuns4x4` +3 | `DrawShadows` |

## mover

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E687` | `DownHeldCount` | 1 | Passes down has been held, up to 6: the aircraft's climb step. `$E687-$E68A`: one counter for each stick direction, read by the player routine `$E7E9`; the step is (count + 1) / 2 (docs/10-gameplay-logic.md 10.3). | `PlayerSteer`, `ReadControls` | `PlayerSteer`, `ReadControls` |
| `$E688` | `UpHeldCount` | 1 | Passes up has been held, up to 6 | `PlayerSteer`, `ReadControls` | `PlayerSteer`, `ReadControls` |
| `$E689` | `LeftHeldCount` | 1 | Passes left has been held, up to 6 | `PlayerSteer`, `ReadControls` | `PlayerSteer`, `ReadControls` |
| `$E68A` | `RightHeldCount` | 1 | Passes right has been held, up to 6 | `PlayerSteer`, `ReadControls` | `PlayerSteer`, `ReadControls` |
| `$E68B` | `AutoCountdown` | 1 | The AUTO countdown: passes left, 0 when off. Set at the round start (`$D251`) and to `$FF` when the player reaches the barrier (`$E4DE`); counted down by `$E68C` (docs/05-controls.md 5.4). | `GameEntry`, `MainLoop`, `ReadControls` | `MoveRecord`, `ReadControls`, `RoundSetup` |

## player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E7B7` | `FireCount` | 1 | Passes with fire held. Counts the passes fire is held, 0 when released (`$E7E9`). A shot leaves on odd counts (every other pass), a shell of the ground vehicle only when bit 1 is clear as well (every fourth pass). docs/07-objects.md 7.7. | `MovePlayer`, `ReadControls` | `MovePlayer`, `ReadControls` |
| `$E7B8` | `SpeedReserve` | 1 | The ground vehicle's speed reserve. Spent by slowing down (down held, or the AUTO start), earned back by speeding up (up held), at most 32; 10 at each round start, all spent by the AUTO start (speed 0 while it lasts). docs/10-gameplay-logic.md 10.3. | `ReadControls` | `ReadControls`, `RoundSetup` |
| `$EA36` | `RandomSeed` | 2 | The random seed. The state of `$EA19`, incremented by every pass of the menu loop. | `Menu`, `Random` | `Menu`, `Random` |

## hits

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$ECE4` | `Followers` | 1 | The number of followers (the lives carried into the next round). The convoy behind the player, up to 4. A hit on the player costs the last one instead of the vehicle (`$E262`); the next round's lives are these (`$D151` copies them into `$C2F9`); the game start sets 4 (`$CF36-$CF65`); the round setup clears it after taking the lives (`$D1DE`). docs/07-objects.md 7.5, docs/10-gameplay-logic.md 10.4. | `ConvoyFollow`, `HitPlayerOnPod`, `MoveRecord`, `ReadControls`, `RoundSetup` | `GameEntry`, `HitPlayerOnPod`, `MainLoop`, `MoveRecord`, `RoundSetup` |
| `$ECE5` | `FollowerOffset` | 2 | Where the next follower goes, along, from the player. Added to a new follower's position: -10 at each round setup (`$D1DE`), then 6 less for each follower (`$ED25`); a lost follower gives 6 back (`$E262`). | `HitPlayerOnPod`, `MoveRecord` | `HitPlayerOnPod`, `MoveRecord`, `RoundSetup` |
| `$ECE7` | `ConvoyLinks` | 10 | The convoy: the leader's and the followers' +3 addresses. Five words: `$C003` (the player's position across), then the +3 address of each follower in the order they joined; `$FF` in the high byte marks an empty link (the round setup `$D1DE` fills the four with `$FF`, the image holds 0). `$ECF3` appends, `$E7B9` copies along them, `$E979` hits every follower in them. | `ConvoyFollow`, `MoveRecord`, `ReadControls` | `HitPlayerOnPod`, `MoveRecord`, `RoundSetup` |
| `$ECF1` | `ConvoyLinkEnd` | 2 | The next free convoy link | `HitPlayerOnPod`, `MoveRecord` | `HitPlayerOnPod`, `MoveRecord`, `RoundSetup` |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$EE13` | `PrintScreenPos` | 2 | The print routine's screen address. The bitmap address of the next character cell, kept in memory because the glyph copy needs B and DE. docs/08-hud-and-text.md 8.1. | `PrintString` | `PrintString` |
| `$EE15` | `PrintAttrPos` | 2 | The print routine's attribute address | `PrintString` | `PrintString` |
| `$EF48` | `ScoreStop` | 1 | '.': the left end of SCORE for `$EEA4` | `DrawDigits` | - |
| `$EF49` | `Score` | 6 | SCORE: five characters and a fixed '0'. Six ASCII characters; leading spaces stay spaces until a carry reaches them. docs/08-hud-and-text.md 8.4. | `AddPoints`, `DrawDigits`, `RoundSetup`, `UpdateMax` | `AddPoints`, `ClearScores`, `GameEntry`, `MainLoop` |
| `$EF4F` | `RoundTable` | 66 | The round table: 6 bytes a round, rounds 0-10. Each entry: the lives at the round's start, then SCORE's five characters at that moment. `$D151` writes a round's entry at every setup; a lost life or a fall back restores SCORE from it. docs/04-game-loop.md 4.2, 4.4. | `GameEntry`, `MainLoop` | `ClearScores`, `RoundSetup` |
| `$EF91` | `HighStop` | 1 | '.': the left end of HIGH | `DrawDigits` | - |
| `$EF92` | `HighScore` | 6 | HIGH: kept until the machine is reset | `DrawDigits`, `UpdateHigh` | `UpdateHigh` |
| `$EF98` | `MaxStop` | 1 | '.': the left end of MAX | `DrawDigits` | - |
| `$EF99` | `MaxScore` | 6 | MAX: the best SCORE of this game | `DrawDigits`, `UpdateHigh`, `UpdateMax` | `ClearScores`, `UpdateMax` |
| `$EF9F` | `DrawListEnd` | 2 | The end of the draw list at `$6500`. Written by `$EFA5` and `$F089`. | `SortDrawList` | `PlaceObjects`, `SortDrawList` |
| `$EFA1` | `DepthListEnd` | 2 | The end of the depth list at `$FF00` | `PlaceObject` | `PlaceObject`, `PlaceObjects` |
| `$EFA3` | `StaticListEnd` | 2 | The end of the static-object list at `$C99E` | `PlaceObject` | `PlaceObject`, `PlaceObjects` |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F0DB` | `DemoFlag` | 1 | The demo: `$FF` while the demo plays. Set by the menu (key 5, or when idle too long), cleared when the menu is entered. docs/05-controls.md 5.1, docs/10-gameplay-logic.md 10.6. | `GameEntry`, `MainLoop`, `Menu`, `RoundSetup`, `ScrollStep` | `Menu` |
| `$F0DC` | `MenuIdleLow` | 1 | The menu's idle count, low byte | `Menu` | `Menu` |
| `$F0DD` | `MenuIdleHigh` | 2 | The menu's idle count in 256 passes; 2 000 starts the demo | `Menu` | `Menu` |
| `$F0DF` | `MenuBarAttr` | 2 | The attribute address of the device highlight bar | `Menu` | `Menu` |
| `$F0E1` | `DemoMessage` | 10 | " DEMO " at (2,6). Printed every pass of the demo. Strings are records for `$EE17`: attribute + `$80`, column, row, characters; `$FF` ends. docs/08-hud-and-text.md 8.3. | `PrintString` | - |
| `$F0EB` | `PauseMessage` | 10 | "PAUSE!" at (2,6) | `PrintString` | - |
| `$F0F5` | `GameOverBox` | 55 | The GAME OVER box. A red frame of `$2E` blocks around the eleven big-letter glyphs `$22-$2C`, rows 9-11, columns 10-22. Printed at GAME OVER and ABORT (`$D0A5`). docs/08-hud-and-text.md 8.2-8.3. | `PrintString` | - |
| `$F12C` | `AbortMessage` | 10 | "ABORT!" at (2,6) | - | - |
| `$F136` | `BlankMessage` | 10 | Six spaces at (2,6): clears the message window | `PrintString` | - |
| `$F140` | `MenuText` | 106 | The menu: SELECT and the six choices. Seven records: SELECT at (2,6); the four devices at (10,8-11) in white; 5 DEMO and 6 START GAME at (10,13-14) in green. docs/05-controls.md 5.1. | `PrintString` | - |
| `$F2BF` | `SoundRequests` | 1 | The sound requests: one bit an effect. Set by the game (bit 0 a pod joins, 1 an explosion, 2 a hit that does not destroy, 3 AUTO, 4 a shot), played by `$F2C0`, cleared by the play loop (`$D085`). docs/09-sound.md 9.6, docs/10-gameplay-logic.md 10.8. | `HitBoth`, `HitPlayerOnPod`, `HitShotOnBlock`, `MovePlayer`, `MoveRecord` +2 | `GameEntry`, `HitBoth`, `HitPlayerOnPod`, `HitShotOnBlock`, `MainLoop` +3 |
| `$F2E2` | `EffectTable` | 25 | The five request effects. Entry per request bit 0-4: kind (0 beep, 1 sweep), then the beep's pitch and length or the sweep's step, cycles, start half-period and tones. Bit 0 sweep 2,4,`$50`,`$1E`; bit 1 sweep `$0A`,3,`$14`,6; bit 2 sweep `$32`,5,`$1E`,3; bit 3 beep `$0414`; bit 4 sweep 2,4,`$42`,`$0A`. docs/09-sound.md 9.6. | `BeepAt`, `PlaySound`, `Sweep` | - |
| `$F2FB` | `RoundStartSound` | 5 | The sweep of the round setup. Sweep 8, 4, 3, `$64`, played by `$D151` through `$F2D9` when a round is set up. | `PlaySound`, `Sweep` | - |

## coursedata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F300` | `RoundObjects1` | 128 | The objects of round 1. 16 records of 8 bytes, copied into the object slots `$C0B0-$C1A0` at the round setup: +0 type, +1,+2 position along, +3 across, +4 height, +5 direction, +6 speed, +7 behaviour bits (docs/07-objects.md 7.1-7.4). The course record of a round (`$CF04`, 4 bytes) points here: round 1 at `$F300`, then 128 bytes a round. docs/04-game-loop.md 4.2, docs/10-gameplay-logic.md 10.2. | `RoundSetup` | - |
| `$F380` | `RoundObjects2` | 128 | The objects of round 2 | `RoundSetup` | - |
| `$F400` | `RoundObjects3` | 128 | The objects of round 3 | `RoundSetup` | - |
| `$F480` | `RoundObjects4` | 128 | The objects of round 4 | `RoundSetup` | - |
| `$F500` | `RoundObjects5` | 128 | The objects of round 5 | - | - |
| `$F580` | `RoundObjects6` | 128 | The objects of round 6 | - | - |
| `$F600` | `RoundObjects7` | 128 | The objects of round 7 | - | - |
| `$F680` | `RoundObjects8` | 128 | The objects of round 8 | `RoundSetup` | - |
| `$F700` | `RoundObjects9` | 128 | The objects of round 9 | `RoundSetup` | - |
| `$F780` | `RoundObjects10` | 128 | The objects of round 10 | `RoundSetup` | - |
| `$F800` | `SpriteSaveBuffer` | 1533 | The strips under the sprites, saved. `$D9D6` starts the pointer `$DD6A` at `$F800` each pass and `$DD47` copies the buffer strips under each sprite here before the sprites are drawn; `$DDC9` puts them back. Nothing in the image here is read before it is written: a fill pattern (`$FA`,`$FC`) and, toward the end, bytes that look like Z80 code that never ran. In the recording the strips took 980 bytes at most (`$F800-$FBD3`): `$FBD4-$FDFC` was never read or written. docs/06-rendering.md 6.6. | `RestoreStrips` | `SaveStrips` |
| `$FE00` | `Im2Table` | 256 | The IM 2 vector table, then the shadow list. During the title, `$9F4B` fills `$FE00-$FF00` with `$FD` and sets I = `$FE`, so any bus value gives the vector `$FDFD`. In play the table is no longer needed and `$D9D6` builds the shadow list at `$FE64` in it (8 bytes an object), drawn by `$DDE7` before the blit. docs/02-architecture.md 2.3, docs/06-rendering.md 6.6. | `DrawShadows`, `RestoreUnderSprites`, `TitleSetup` | `BuildSpriteLists`, `SetupIM2`, `ShadowListAdd`, `ShadowListLoop` |
| `$FF00` | `SpriteListArea` | 88 | The depth list and the sprite list, then the stack. `$FF00` holds the depth list of `$EFA5` (4 bytes an entry) and then, rebuilt by `$D9D6` each pass, the sprite list drawn by `$EAE3` (6 bytes an entry); its first byte is also the last vector byte of the IM 2 table. The stack grows down from `$FFFF` (SP = `$FFFF` at the entry, `$61A8`). The bytes in the image up to `$FF57` are leftovers. The sprite list has no bound: with 16 entries drawn its end mark lands at `$FF60`, so it runs on into `UdgLeftover` (`$FF58-$FF60` are written and read in the replay). docs/02-architecture.md 2.2. | `DrawSprites`, `PlaceObject`, `RestoreUnderSprites`, `SortDrawList` | `BuildSpriteLists`, `PlaceObject`, `PlaceObjects`, `SetupIM2`, `SpriteListBuild` |
| `$FF58` | `UdgLeftover` | 168 | The 48K BASIC's user-defined graphics, left in the image. `$FF58-$FFFF` is where the Spectrum ROM keeps the UDGs, set up as copies of the letters A-U; the bytes are those copies, left from BASIC. The game never reads them as graphics: the sprite list runs over the first bytes (`$FF58-$FF60` in the replay) and the stack over the last ones (`$FFF5-$FFFE`, SP from `$FFFF`); `$FF61-$FFF4` is the free space between the two. | `DrawSprites`, `RestoreUnderSprites` | `BuildSpriteLists` |
