# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/rec/c1` (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: The first BASIC "enduro" and Stage0, The second BASIC "end2" and
Chain1, The loader: Chain2, Chain3 and the SpeedLock 2 loader, The loader's end as blocks 12 and 14 rewrite it)
follow the game, each under its own heading with its modules, its source, its annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`entry`](#entry) | `$5B00`-`$643B`, `$8000`-`$810B` | 3 of 17 |
| [`interrupt`](#interrupt) | `$643C`-`$6587` | 2 of 4 |
| [`sound`](#sound) | `$6588`-`$690E` | 11 of 16 |
| [`graphics`](11-data-reference.md#graphics) | `$690F`-`$7FFF`, `$B11D`-`$FFFF` | 0 of 26 |
| [`menu`](#menu) | `$810C`-`$8754` | 40 of 46 |
| [`flow`](#flow) | `$8755`-`$8E7C` | 16 of 28 |
| [`render`](#render) | `$8E7D`-`$9110`, `$970C`-`$975A`, `$98EF`-`$9999` | 15 of 15 |
| [`objects`](#objects) | `$9111`-`$9126`, `$917E`-`$9210`, `$9615`-`$970B`, `$975B`-`$98EE`, `$9F18`-`$9FBD`, `$A09A`-`$A142`, `$A21A`-`$A300` | 10 of 16 |
| [`bike`](#bike) | `$9127`-`$917D`, `$9FBE`-`$A099`, `$A1C9`-`$A1CB`, `$A1D9`-`$A219`, `$ACDF`-`$AFFD`, `$AFFE`-`$B07C` | 14 of 16 |
| [`horizon`](#horizon) | `$9211`-`$931D`, `$99F0`-`$9A90`, `$9E3A`-`$9F17` | 13 of 16 |
| [`road`](#road) | `$931E`-`$9614`, `$999A`-`$99EF`, `$9A91`-`$9E39`, `$A301`-`$A45C`, `$B07D`-`$B11C` | 15 of 18 |
| [`race`](#race) | `$A143`-`$A1C8`, `$A1CC`-`$A1D8`, `$A45D`-`$ABA0`, `$ABA1`-`$ACDE` | 25 of 31 |

## entry

`src/game/entry.asm`

### `Mover` (`$5B00`)

**LDDR `$5BC4-$FA1F` up by `$5E0` to `$61A4-$FFFF`, SP = `$61A7`, JP Start**

Loaded by tape block 15 (row 9 of BlockTable, src/loader/loader.asm) and entered by TailEnd's JP `$5B00` at c1 frame 11632 (m128 too). DE = `$FFFF`, HL = `$FA1F`, BC = `$9E5C` (40 540), LDDR; SP = `$61A7`, the top of the gap the move leaves; JP Start. The entry image differs from the loaded one only by that move (doc 02, 2.2).

Witness: L1 1379 (c1, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 936,703 t-states own (0.06 %) |
| Runs (the other recordings) | 1,378 calls (`stage1/rec/m128` 1,378) |
| Called from | `MoverTail` |
| Calls | `Start` (tail) |
| Reads | `$5B5C` (`RowListTail+28`); `$5BC4`-`$FA1F` (`BendRows+68`, `RoadLines`, `Riders`, `ReverseTable` and 240 more) |
| Ports out | `$7FFD` |

### `Start` (`$8000`)

**JP Init: the entry Mover jumps to; its three bytes and the 181 after them are work space later**

After the start `$8000-$8002` hold variables (MenuItem `$8001`, KeyItem `$8000`, WaitCount `$8002-$8003`) and `$8000-$80B7` is the line buffer of the sprite routines (DrawShifted, DrawMirrored, BuildRoadRows: up to 184 bytes).

Recorded: c1 frame 11646: Mover's JP `$8000`.

Witness: L1 2 (c1, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/m128` 1) |
| Called from | `Mover` (tail) |
| Calls | `Init` (tail) |

### `Init` (`$80B8`)

**The IM 2 table, the records, the track tables, the bit-reverse table, the 128K test, IM 2 and on to Attract**

I = `$B2`, `$B200-$B300` = `$64`; InitialRecords to Records (`$5E00`, 13 bytes); `$EB00-$F0AF` to StageList (`$5E80`, 1456 bytes: the stage list and the track); ReverseTable at `$5D00` (each byte with its bits reversed, for DrawMirrored); the byte sum of ROM `$3B00-$3BFF`: `$FE` (the 48K ROM) gives Beeper = `$FF`, else 0; Players = 1; SP = 0 (the stack under `$0000`: `$FF`xx); IM 2; EI; falls into Attract.

Recorded: c1 and m128 frame 11646; c1's sum is `$FE`, m128's is not: Beeper 0 there.

Witness: L1 2 (c1, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 115,450 t-states own (0.01 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/m128` 1) |
| Called from | `Start` (tail) |
| Calls | `Attract` (falls into) |
| Reads | `$8003`-`$800F` (`InitialRecords`); `$8D49` (`CreditList`); `$EB00`-`$F0AF` (`TrackTables`) |
| Writes | `$5D00`-`$5E0C` (`ReverseTable`, `Records`); `$5E80`-`$642F` (`StageList`, `TrackPatterns`, `Track`); `$7C2F`-`$7C32` (`Beeper`, `DemoMode`, `GetUp`, `Players`); `$B200`-`$B300` (`Im2Table`) |

## interrupt

`src/game/interrupt.asm`

### `Interrupt` (`$643C`)

**Save SP, take IntStack, read the return address into IntReturn's JP, push the registers**

Entered through IntVector (`$6464`, JR here) on every interrupt in play and the menus. IntSavedSp = SP; SP = `$6584`; AF, BC, DE, HL, IX, IY pushed on IntStack. HL = the interrupted SP: the return address is read from (HL) into the operand of IntReturn's JP (`$6524`), IntSavedSp += 2 (the SP to restore), HL = the address of the two bytes the push wrote; A = H, and on at IntRepair.

Recorded: c1, m128 and every play recording; 1.00 entries a frame in c1's play.

Witness: L1 79550 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `Interrupt` at work](img/routines/Interrupt.gif)

[Animation: `Interrupt` at work, reset](img/routines/Interrupt-reset.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 9,617 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 69,933 runs of its first instruction, entered by a jump (`stage1/rec/stages` 23,908, `stage1/rec/twoplayer` 21,272, `stage1/rec/m128` 5,226 and 9 more) |

### `IntVector` (`$6464`)

**JR Interrupt (the vector of every IM 2 entry); then the repair and the sound part of the handler**

`$6464` is the address every byte of the IM 2 table `$B200-$B300` points at (`$64`,`$64`). The bytes after the JR are the handler's second half, reached by Interrupt's JP `$6466` (IntRepair).

IntRepair (`$6466`): H = `$FE`, or H = `$FF` and L < `$82`: RowEntry recomputes the address that belongs at that place of RowTable; H elsewhere but `$FF`: the two bytes become 0; the real stack (`$FF82` up): nothing. IntSound (`$6476`): TuneRequest against TunePlaying; a change waits for TuneMark, then TunePlaying = TuneRequest, and 0 writes AySilence, 1 or 2 starts the tune (TuneTable's two streams into ChannelA and ChannelB, as stream and restart, counts 1, repeat depths `$FF`, TuneMark 0, the four pairs of AyTuneStart, AyMixer's value `$38`). A tune playing: on the 128K (Beeper 0) an effect (EffectTime) holds the channels (TuneHeld = EffectTime); its end writes AyTuneStart and AyMixer again; else both channels step (PlayChannel, ChannelA then ChannelB). TuneRequest nonzero: EngineSound. IntExit pops, SP = IntSavedSp, EI, JP to the interrupted code.

n < `$28`: the screen line n's address (LineAddress); n < `$40`: `$EB00` + 32 (n - `$28`), a back buffer row; n >= `$40`: the screen line n's address + `$A600`, a back buffer row. What SetRowTable left there in play.

Witness: L1 79550 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 9,617 calls, 5,796,632 t-states own (0.39 %) |
| Runs (the other recordings) | 69,933 calls (`stage1/rec/stages` 23,908, `stage1/rec/twoplayer` 21,272, `stage1/rec/m128` 5,226 and 9 more) |
| Entered by | the interrupt, 79,550 times in 89 routines |
| Calls | `PlayChannel`, `WriteMixer`, `AyWrite`, `LineAddress`, `EngineSound`, `Attract` (tail), `Menu` (tail), `PrintString` (tail), `PrintChar` (tail), `PrintGlyph` (tail), `PrintNumber` (tail), `DrawWindow` (tail), `DrawFrame` (tail), `SetAttr` (tail), `BigDigit` (tail), `ScrollUp` (tail), `ScanKeys` (tail), `WaitKeyTimeout` (tail), `Delay` (tail), `ReadControls` (tail), `ClearScreen` (tail), `DelayBC` (tail), `PrintList` (tail), `AddScore` (tail), `DrawScore` (tail), `NewGame` (tail), `PlayTurn` (tail), `RecordTie` (tail), `NameEntrySound` (tail), `Divide` (tail), `Multiply` (tail), `Copy32` (tail), `SetRowTable` (tail), `CopyRows` (tail), `DrawSprite` (tail), `DrawShifted` (tail), `ShiftCopyHead` (tail), `ShiftRightHead` (tail), `ShiftLeftHead` (tail), `BlitHead` (tail), `RotateRight1` (tail), `RotateLeft1` (tail), `DrawRoad` (tail), `DrawRoadRunLine` (tail), `DrawRiders` (tail), `MirrorCarry` (tail), `GapRowsJump` (tail), `CopyBuffer` (tail), `RoadJumpRows` (tail), `HorizonScrollStep` (tail), `RoadRowsCrest` (tail), `RoadRowsFlat` (tail), `DrawHorizon` (tail), `HorizonHidden` (tail), `DrawObject` (tail), `DrawBike` (tail), `CountGlyphC` (tail), `MoveRidersLoop` (tail), `RiderNoRamp` (tail), `GroundTexture` (tail), `StartRace` (tail), `RacePass` (tail), `RampSpeed` (tail), `RiderBounce` (tail), `HudPlayer` (tail), `RaceQuit` (tail), `BeepTone` (tail), `TrackStep` (tail), `CrashSoundD` (tail), `BikeControl` (tail), `GetUpSlide` (tail), `AdvanceTrack` (tail), `SegmentDecode` (tail), `BikeRoadPlace` (tail), `ScrollBends` (tail) |
| Reads | `$643A`-`$643B` (`TuneHeld`, `TunePlaying`); `$6460`-`$6462` (`TuneMark`, `TuneRequest`, `EffectTime`); `$6586`-`$6587` (`IntSavedSp`); `$66C2`-`$66C9` (`TuneTable`); `$7C2F` (`Beeper`); `$B2FF`-`$B300` (`Im2Table+255`); 3 more ranges |
| Writes | `$5BCB`-`$5BFE` (`BendRows+75`); `$643A`-`$643B` (`TuneHeld`, `TunePlaying`); `$6460` (`TuneMark`); `$6524`-`$6525` (`IntReturn+1`); `$6586`-`$6587` (`IntSavedSp`); `$67FC` (`AyMixer+1`); 6 more ranges |

## sound

`src/game/sound.asm`

### `PlayChannel` (`$6588`)

**Step one tune channel (IX): count its note down, then read the next note or command**

In: IX = ChannelA or ChannelB. The count (IX+0) minus 1: reaching 0 sets the channel's mixer bit (IX+`$0E`) in AyMixer's value (the note stops for one interrupt) and writes the mixer; going past 0 (`$FF`) toggles the bit back and reads the stream at (IX+1,2): a length byte below `$C8` (the new count, minus 1), then the note byte: low nibble 0 sets the bit (a rest); 1-11 reads NoteTable's word n (`$66AA` + 2n), halved (high nibble + transpose IX+3) times, into the channel's tone registers (IX+`$0D` and +1). Bytes from `$C8`: ChannelCommands.

Recorded: c1, m128: two calls each interrupt in play.

Witness: L1 65445 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `PlayChannel` at work](img/routines/PlayChannel.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 14,760 calls, 2,104,622 t-states own (0.14 %) |
| Runs (the other recordings) | 50,685 calls (`stage1/rec/crash` 8,998, `stage1/rec/m128` 7,836, `stage1/rec/twoplayer` 7,558 and 9 more) |
| Called from | `IntVector` |
| Calls | `WriteMixer` (tail) |
| Reads | `$66AE`-`$66D5` (`NoteTable+4`, `TuneTable`, `Tune2A`); `$66E9`-`$6740` (`Tune2A+31`, `Tune1A`, `Tune2B`); `$6760`-`$67FC` (`Tune2B+59`, `AyMixer`); `$6817`-`$6838` (`ChannelA`, `ChannelB`) |
| Writes | `$6460` (`TuneMark`); `$67FC` (`AyMixer+1`); `$6817`-`$6838` (`ChannelA`, `ChannelB`) |
| Ports out | `$BFFD`, `$FFFD` |

### `NoteCarry` (`$65DC`)

**INC H for a note table that crosses a page: not reached with this table**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChannelPeriod` (`$65DD`)

**The period from (HL), halved (high nibble + transpose) times, out to the channel's tone registers**

In: HL = the word in NoteTable, C = the note byte, IX the channel. Writes the low then the high register (IX+`$0D`, IX+`$0D`+1) through ports `$FFFD` / `$BFFD`.

Witness: L1 6397 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1,513 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,884 runs of its first instruction, entered by a jump (`stage1/rec/crash` 808, `stage1/rec/m128` 783, `stage1/rec/twoplayer` 728 and 9 more) |
| Calls | `ChannelLoop` |

### `ChannelAyPairs` (`$668B`)

**Any other command byte: the next byte E is a count of AY pairs, written by AyWrite, then on**

Known only from the code: no stream of the two tunes holds such a byte (src/res/sound/tunes.txt lists every command they use).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ChannelLoop` (`$6694`)

**IY = the channel's repeat record: IX + 7 + 3 * depth (count, address)**

Witness: L1 2936 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 710 calls, 79,520 t-states own (0.01 %) |
| Runs (the other recordings) | 2,226 calls (`stage1/rec/crash` 367, `stage1/rec/m128` 350, `stage1/rec/twoplayer` 326 and 9 more) |
| Called from | `ChannelPeriod` |
| Reads | `$681D` (`ChannelA+6`); `$682E` (`ChannelB+6`) |

### `WriteMixer` (`$6801`)

**AY register 7 = AyMixer's value**

Witness: L1 16090 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 3,380 calls, 57,460 t-states own (0.00 %) |
| Runs (the other recordings) | 12,710 calls (`stage1/rec/m128` 3,520, `stage1/rec/crash` 1,805, `stage1/rec/twoplayer` 1,618 and 9 more) |
| Called from | `IntVector`, `PlayChannel` (tail), `EngineTone` (tail) |
| Calls | `AyWrite` (falls into) |
| Reads | `$67FB`-`$67FC` (`AyMixer`) |
| Ports out | `$BFFD`, `$FFFD` |

### `AyWrite` (`$6806`)

**Write E pairs (register, value) from HL to the AY: OUT (`$FFFD`) the register, OUT (`$BFFD`) the value**

Out: HL past the pairs. On the 48K the ports reach nothing (the game writes them on both machines).

Witness: L1 18027 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 3,395 calls, 300,752 t-states own (0.02 %) |
| Runs (the other recordings) | 12,397 calls (`stage1/rec/m128` 5,304, `stage1/rec/crash` 1,808, `stage1/rec/twoplayer` 1,623 and 5 more) |
| Called from | `IntVector`, `WriteMixer` (falls into), `EngineTone` |
| Reads | `$6430`-`$6439` (`AySilence`, `AyTuneStart`, `AyEngineVolume`); `$67FB`-`$67FC` (`AyMixer`) |
| Ports out | `$BFFD`, `$FFFD` |

### `LineAddress` (`$6839`)

**DE = the screen address of pixel line A (L = the same line): the ROM's PIXEL-ADD layout, column 0**

In: A = L = the line (0-191). D = `$40` + (line AND 7) + 8 * (line >> 6), E = (line AND `$38`) * 4. RowEntry's helper.

Witness: L1 13451 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 2,358 calls, 219,292 t-states own (0.01 %) |
| Runs (the other recordings) | 11,093 calls (`stage1/rec/stages` 3,470, `stage1/rec/crash` 1,661, `stage1/rec/twoplayer` 1,522 and 9 more) |
| Called from | `IntVector` |

### `EngineSound` (`$6851`)

**Every second interrupt: the engine's note from SPEED, on the beeper (48K) or AY channel C (128K)**

EngineToggle (the LD A operand at `$6852`) flips each call and the call with it 0 returns. A = SPEED (`$7C34`), +9 in the air (JumpHeight), folded (below 60 as is, 60-129 minus 60, then minus 60 more), C = `$63` - A. 48K (Beeper nonzero): 11 edges on port `$FE`, the n-th after `$14` + C + (a ROM byte at `$02`xx AND `$3F`) DJNZ turns: a buzz whose pitch rises with the speed. 128K: an effect playing (EffectTime): nothing; SkidLevel nonzero: EngineSkid; else EngineTone.

Recorded: c1: the OUT (`$FE`) at `$687F` in play; m128: the AY path `$68D1`.

Witness: L1 28577 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 6,006 calls, 65,802,538 t-states own (4.43 %) |
| Runs (the other recordings) | 22,571 calls (`stage1/rec/crash` 4,499, `stage1/rec/m128` 3,781, `stage1/rec/twoplayer` 3,779 and 9 more) |
| Called from | `IntVector` |
| Reads | `$5CEA` (`JumpHeight+1`); `$645F`-`$6462` (`SkidLevel`, `TuneMark`, `TuneRequest`, `EffectTime`); `$67FC` (`AyMixer+1`); `$7C2F`-`$7C34` (`Beeper`, `DemoMode`, `GetUp`, `Players` and 1 more) |
| Writes | `$67FC` (`AyMixer+1`); `$6852` (`EngineSound+1`) |
| Ports out | `$00FE`, `$10FE`, `$BFFD`, `$FFFD` |

### `EngineSkid` (`$689E`)

**128K: channel C's volume from SkidLevel, the noise period from SPEED, noise on C and tone off**

In: A = SkidLevel. Volume = ((A >> 2) AND 3) + `$0B`, 11-14 (the clamp to 15 never fires); noise period = SPEED >> 4 (SPEED 0: EngineTone instead); AyVolumeC and AyNoise written, mixer AND `$1F` OR 4.

Known only from the code: SkidLevel is set by the sand of stage 3 (OffRoadSand), and no recording left the road there on the 128K.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `EngineTone` (`$68D1`)

**128K: AY channel C's period from C and SPEED's low byte, volume 15 (AyEngineVolume), tone C on**

Period = (C + `$1C`) * 32 with the top bits of -SPEED's low byte (`$7C33`) shifted in. Mixer AND `$3B` OR `$20`.

Witness: L1 1768 (m128).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1,768 runs of its first instruction, entered by a jump (`stage1/rec/m128` 1,768) |
| Calls | `WriteMixer` (tail), `AyWrite` |

## menu

`src/game/menu.asm`

### `Attract` (`$810C`)

**Wipe, scroll the credits up, wait for a key; none: a demo race; a key: Menu**

ClearScreen; ScrollPhase = 1; for each of the four CreditList records: the line printed centred at the bottom (pixel line 183), then ScrollUp the record's count of times, KeyOrFire stopping it into Menu. Then WaitKey with 250 units: a key gives Menu; none: DemoMode = 8 + (the distance AND 7) and NewGame plays a demo race.

Recorded: c1: the credits from frame 11646; the demo from the attract in m128 and c1 before the menu key.

Witness: L1 5 (c1, m128, names, stages).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 2 calls, 33,171 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/stages` 1, `stage1/rec/names` 1) |
| Called from | `IntVector` (tail), `Init` (falls into), `NewGame` (tail) |
| Calls | `PrintString`, `ScrollUp`, `KeyOrFire`, `WaitKey`, `ClearScreen`, `NewGame` |
| Reads | `$5E29` (`TrackDistance`); `$8D49`-`$8D55` (`CreditList`) |
| Writes | `$7C30` (`DemoMode`); `$84CE` (`ScrollPhase+1`) |

### `AttractScores` (`$8163`)

**After a demo: wait 200 units, show the high scores (ShowScores), wait 750 units, Attract again**

A key at either wait gives Menu. Known only from the code: no recording let a demo end (each pressed a key during it or before it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Menu` (`$8178`)

**The main menu: draw it, MenuSelect, then the item's action**

ClearScreen; DemoMode 0; MenuItem 0; the top four character rows' attributes `$79`; below them every attribute with a paper colour cleared to 0; the frame (FrameChars), MenuLayout's texts, ONE or TWO PLAYERS, MenuLayout2's texts. MenuSelect over MenuItems: timeout: Attract; 0: NewGame; 1: Players 1 <-> 2; 2: the method window (ControlItems, MenuSelect, ControlMethod, PatchControls); 3: DefineKeys.

Recorded: c1, m128, ctl: every item; twoplayer: item 1.

KeyItem 0; the window; DefineItems' texts; the seven keys (PrintKey) beside them; MenuSelect: EXIT (0) or timeout back to the menu; item n: its old key's three-letter place blanked (Blanks), GetKey; the key's character goes to Keys + n - 1, its half-row byte to ControlTable + n - 1, its mask (XOR `$1F`) to ControlTable + n + 4; the cursor moves to the next item; a key already in use is refused (DefineTaken); keys 6 and 7 (PAUSE, RESET) patch ReadControls' last two tests (DefinePauseKey). Then method 0 and PatchControls.

Recorded: ctl: DEFINE KEYS, keys 1-5 set.

Witness: L1 8 (c1, ctl, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 199,745 t-states own (0.01 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/ctl` 6, `stage1/rec/m128` 1) |
| Called from | `IntVector` (tail), `RaceQuit` (tail) |
| Calls | `PatchControls`, `PrintString`, `PrintKey`, `PrintChar`, `DrawWindow`, `DrawFrame`, `GetKey`, `MenuSelect`, `ClearScreen`, `PrintList`, `NewGame` (tail) |
| Reads | `$5880`-`$5AFF` (screen); `$7C32` (`Players`); `$8000`-`$8001` (`Start`); `$831B`-`$8322` (`ControlMethod`, `Keys`); `$8659`-`$865A` (`RestoreBar+1`) |
| Writes | `$5800`-`$587F` (screen); `$5949`-`$5955` (screen); `$5968`-`$5A3B` (screen); `$5A4C`-`$5A5B` (screen); `$5A6C`-`$5A7B` (screen); `$5A8C`-`$5A9B` (screen); 6 more ranges |

### `DefineTaken` (`$82BE`)

**The key is in use: back to GetKey**

Known only from the code: ctl gave five different keys.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DefinePauseKey` (`$82D4`)

**Items 6 and 7: patch ReadControls' PAUSE (`$85E5`) or RESET (`$85EF`) test directly**

Known only from the code: ctl set only the five driving keys.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `PatchControls`, `RestoreBar` |

### `PatchControls` (`$82F8`)

**Write method IX's five half-row bytes and masks, with D and E, into ReadControls' five tests**

In: IX = a ControlTable row, D = the port's low byte (`$FE` or `$1F`), E = the jump's opcode (`$20` JR NZ for the active-low keyboard, `$28` JR Z for the active-high Kempston). Each test at `$85B2` + 10n gets C (the LD A operand), D (the IN port), B (the AND mask), E (the JR opcode).

Witness: L1 8 (c1, ctl, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 467 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/ctl` 6, `stage1/rec/m128` 1) |
| Called from | `Menu`, `DefinePauseKey` |
| Calls | `PatchTest` |
| Reads | `$8323`-`$8354` (`ControlTable`) |

### `PatchTest` (`$830B`)

**One test: (HL) = C, +2 = D, +4 = B, +5 = E; HL += 10, IX += 1**

Witness: L1 40 (c1, ctl, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 5 calls, 495 t-states own (0.00 %) |
| Runs (the other recordings) | 35 calls (`stage1/rec/ctl` 30, `stage1/rec/m128` 5) |
| Called from | `PatchControls` |
| Writes | `$85B3`-`$85E0` (`ReadControls+3`, `l_85BC`, `l_85C6`, `l_85D0` and 1 more) |

### `PrintKeyName` (`$8361`)

**Print key code A (1-4) as its three-letter name**

Witness: L1 3 (c1, ctl).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 runs of its first instruction, entered by a jump (`stage1/rec/ctl` 2) |
| Calls | `PrintString` (falls into) |

### `PrintString` (`$836C`)

**Print D characters from HL (B column, C line, E attribute); HL and B move on**

Witness: L1 41186 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 773 calls, 257,445 t-states own (0.02 %) |
| Runs (the other recordings) | 7,741 calls (`stage1/rec/stages` 1,979, `stage1/rec/tech-ramp-wheelie` 1,262, `stage1/rec/tech-land-wheelie` 1,255 and 9 more) |
| Called from | `IntVector` (tail), `Attract`, `Menu`, `PrintKeyName` (falls into), `PrintTimer`, `PrintList`, `DrawScore` (tail), `PlayTurn`, `RecordTie`, `ShowScores`, `PrintTime` (tail), `RiderBounce`, `HudPlayer` |
| Calls | `PrintChar` |
| Reads | `$5E18`-`$5E1E` (`Score`); `$835B`-`$835D` (`KeyNames+6`); `$8735`-`$8754` (`LapTexts`, `TimeText`); `$8C56`-`$8D44` (`MenuTexts`, `PlayerCountTexts`, `MenuTexts2`, `ControlTexts` and 2 more); `$8D56`-`$8DAB` (`CreditTexts`); `$8DC5`-`$8E4F` (`HudTexts`, `HiScores`); 2 more ranges |

### `PrintKey` (`$8375`)

**A below 5: PrintKeyName; else PrintChar**

Witness: L1 21 (c1, ctl).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 7 calls, 217 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/rec/ctl` 14) |
| Called from | `Menu` |
| Calls | `PrintChar` (falls into) |

### `PrintChar` (`$8379`)

**Print character A at column B, pixel line C, attribute E (SetAttr), then B + 1**

The glyph is Font + 8 * (A - `$20`) (the code's base `$7508` = Font - `$100`); each of its 8 rows goes to RowTable's line C + n, column B + PrintOrigin's column. Registers kept but B.

Recorded: c1: the menu, the HUD.

Witness: L1 57774 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `PrintChar` at work](img/routines/PrintChar.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 7,838 calls, 133,284 t-states own (0.01 %) |
| Runs (the other recordings) | 49,939 calls (`stage1/rec/stages` 20,805, `stage1/rec/ctl` 5,352, `stage1/rec/crash` 5,235 and 9 more) |
| Called from | `IntVector` (tail), `Menu`, `PrintString`, `PrintKey` (falls into), `PrintNumber` (tail), `DrawWindow`, `DrawFrame` (tail), `RecordTie`, `NameDelete` |
| Calls | `SetAttr` |

### `PrintGlyph` (`$837C`)

**the glyph without the attribute (DrawScore's digits, the lap table's numbers)**

Witness: L1 63405 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 727 calls, 7,760,951 t-states own (0.52 %) |
| Runs (the other recordings) | 4,906 calls (`stage1/rec/stages` 1,766, `stage1/rec/twoplayer` 1,085, `stage1/rec/crash` 562 and 9 more) |
| Called from | `IntVector` (tail), `RecordTie`, `HudPlayer`, `PrintSpeed` |
| Reads | `$7608`-`$77FF` (`Font`); `$FE00`-`$FF7F` (`RowTable`) |
| Writes | `$4000`-`$57FB` (screen); `$EE29`-`$F576` (`TrackTables+809`, `OldGraphics`); `$F6DC`-`$FDDF` (`BackBuffer+284`); `$FFE6`-`$FFE7` (`StackArea+102`) |

### `PrintNumber` (`$83AB`)

**Print A (0-255) in decimal, no leading zeros, ending at column B (it prints the high digits first, recursively)**

Witness: L1 12418 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1,550 calls, 281,189 t-states own (0.02 %) |
| Runs (the other recordings) | 10,868 calls (`stage1/rec/stages` 5,165, `stage1/rec/crash` 1,407, `stage1/rec/m128` 1,209 and 9 more) |
| Called from | `IntVector` (tail), `PlayTurn`, `RecordTie`, `PrintSpeed` (tail) |
| Calls | `PrintChar` (tail) |

### `DrawWindow` (`$83C5`)

**Clear an H x L character area at PrintOrigin = BC, attribute `$4F`, and draw a frame round it (FrameChars2)**

Witness: L1 9 (c1, ctl, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 2 calls, 8,352 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/ctl` 6, `stage1/rec/m128` 1) |
| Called from | `IntVector` (tail), `Menu` |
| Calls | `PrintChar`, `DrawFrame` (tail) |
| Writes | `$8381`-`$8382` (`PrintOrigin+1`) |

### `DrawCursor` (`$83EA`)

**The name entry's 1 x 1 frame (IX's eight characters) round the cell at DrawCursor's BC operand, attribute `$46`**

Witness: L1 105 (names, stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 105 calls (`stage1/rec/names` 63, `stage1/rec/stages` 42) |
| Called from | `RecordTie`, `NameRightWrap` |
| Calls | `DrawFrame` (falls into) |
| Reads | `$8AB3`-`$8ABA` (`FrameChars`); `$8D41`-`$8D48` (`Blanks`) |

### `DrawFrame` (`$83F7`)

**A frame of IX's eight characters (corners, edges) round an H x L area at column B, line C, attribute E**

Witness: L1 183 (c1, crash, ctl, fall5, m128, names, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 23 calls, 26,027 t-states own (0.00 %) |
| Runs (the other recordings) | 97 calls (`stage1/rec/stages` 46, `stage1/rec/ctl` 27, `stage1/rec/m128` 11 and 4 more) |
| Called from | `IntVector` (tail), `Menu`, `DrawWindow` (tail), `DrawCursor` (falls into), `PlayTurn` |
| Calls | `PrintChar` (tail) |
| Reads | `$8AB3`-`$8AC2` (`FrameChars`, `FrameChars2`); `$8D41`-`$8D48` (`Blanks`) |

### `SetAttr` (`$8440`)

**The attribute of column B, pixel line C (plus PrintOrigin) = E**

Witness: L1 59717 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 8,210 calls, 1,377,984 t-states own (0.09 %) |
| Runs (the other recordings) | 51,511 calls (`stage1/rec/stages` 20,805, `stage1/rec/ctl` 6,471, `stage1/rec/m128` 5,539 and 9 more) |
| Called from | `IntVector` (tail), `PrintChar`, `PaintAttrs` |
| Reads | `$8381`-`$8382` (`PrintOrigin+1`) |
| Writes | `$5800`-`$588E` (screen); `$58C3`-`$5AFB` (screen) |

### `PrintTimer` (`$8458`)

**The timer (Timer, BCD) in big digits at column 13, line 24: tens (blank when 0) and units**

Witness: L1 502 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 68 calls, 8,068 t-states own (0.00 %) |
| Runs (the other recordings) | 434 calls (`stage1/rec/stages` 176, `stage1/rec/crash` 58, `stage1/rec/m128` 47 and 9 more) |
| Called from | `PlayTurn`, `RaceQuit`, `StageEnd` |
| Calls | `PrintString`, `BigDigit` (falls into) |
| Reads | `$5E1F` (`Timer`); `$7C38`-`$7C39` (`SavedSp`); `$7C54`-`$7C71` (`BigDigits`) |
| Writes | `$406F`-`$4090` (screen); `$416F`-`$4190` (screen); `$426F`-`$4290` (screen); `$436F`-`$4390` (screen); `$446F`-`$4490` (screen); `$456F`-`$4590` (screen); 3 more ranges |

### `BigDigit` (`$8486`)

**Digit A (0-9) of BigDigits at column D, line E: 15 rows of two bytes through RowTable, SP as the pointer**

SavedSp (`$7C38`) keeps SP; SP = RowTable + 2 * line; each POP gives a line's address. An interrupt during it is repaired by Interrupt (the pops read RowTable).

Witness: L1 1013 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 132 calls, 195,902 t-states own (0.01 %) |
| Runs (the other recordings) | 880 calls (`stage1/rec/stages` 358, `stage1/rec/crash` 110, `stage1/rec/m128` 98 and 8 more) |
| Called from | `IntVector` (tail), `PrintTimer` (falls into), `PlayTurn`, `StageEnd` |
| Reads | `$7C38`-`$7C39` (`SavedSp`); `$7C54`-`$7D7F` (`BigDigits`) |
| Writes | `$4067`-`$4190` (screen); `$4267`-`$4290` (screen); `$4367`-`$4390` (screen); `$4467`-`$4490` (screen); `$4567`-`$4590` (screen); `$4667`-`$4690` (screen); 3 more ranges |

### `ScrollUp` (`$84B2`)

**The credits' scroll: every pixel line one line up (through RowTable); every eighth call the attributes one row up**

Witness: L1 820 (c1, m128, names, stages).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 329 calls, 7,231,446 t-states own (0.49 %) |
| Runs (the other recordings) | 493 calls (`stage1/rec/names` 165, `stage1/rec/stages` 164, `stage1/rec/m128` 164) |
| Called from | `IntVector` (tail), `Attract` |
| Calls | `Copy32` (tail) |
| Reads | `$FE02`-`$FF7F` (`RowTable+2`) |
| Writes | `$84CE` (`ScrollPhase+1`) |

### `KeyOrFire` (`$84E1`)

**NZ when a key is pressed (or, for the Kempston, fire)**

Witness: L1 665534 (c1, ctl, m128, names, stages).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 451 calls, 31,120 t-states own (0.00 %) |
| Runs (the other recordings) | 665,083 calls (`stage1/rec/stages` 664,627, `stage1/rec/m128` 286, `stage1/rec/names` 165 and 1 more) |
| Called from | `Attract`, `RecordTie`, `HudPlayer` |
| Calls | `ScanKeys` |
| Reads | `$831B` (`ControlMethod`) |

### `KempstonFire` (`$84EC`)

**Kempston: A = port `$1F` AND `$1F` (NZ: a direction or fire)**

Known only from the code: the attract and the menus were left by keys in every recording.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScanKeys` (`$84F3`)

**A = the character of the first key down (KeyMap), `$FF` none; B, D: its half row and bit**

The eight half rows from port `$FEFE` up, five bits each; the character is KeyMap's (5 * row + bit), the code's base `$851A` = KeyMap - 6.

Witness: L1 690526 (c1, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 2,568 calls, 7,339,727 t-states own (0.49 %) |
| Runs (the other recordings) | 687,958 calls (`stage1/rec/stages` 665,039, `stage1/rec/twoplayer` 18,733, `stage1/rec/ctl` 1,596 and 6 more) |
| Called from | `IntVector` (tail), `KeyOrFire`, `WaitKey`, `WaitKeyTimeout` |
| Reads | `$8524`-`$8529` (`KeyMap+4`); `$853C`-`$853D` (`KeyMap+28`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `KeyMapCarry` (`$851C`)

**INC H: not reached (KeyMap does not cross a page)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GetKey` (`$8548`)

**WaitKey with no timeout (B = `$FF`)**

Witness: L1 8 (c1, ctl, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 7 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/twoplayer` 2, `stage1/rec/tech-brake-bend` 1, `stage1/rec/tech-cheat` 1 and 3 more) |
| Called from | `Menu`, `TurnSkip`, `RaceQuit` |
| Calls | `WaitKey` (falls into) |
| Reads | `$8002`-`$8003` (`Start+2`, `InitialRecords`); `$831B` (`ControlMethod`) |
| Writes | `$8002`-`$8003` (`Start+2`, `InitialRecords`) |

### `WaitKey` (`$854A`)

**Wait for every key up, then for a key: NC and A = its character (`$40` on the Kempston method: any stick bit, a direction or fire, at port `$001F`), or C after BC units**

In: BC = the timeout (B = `$FF`: none). Each unit is a DelayBC(`$9A13`) and a scan; the count is WaitCount. Used by the menus, the credits, the lap table, between turns.

Witness: L1 307 (c1, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 22 calls, 7,464 t-states own (0.00 %) |
| Runs (the other recordings) | 79 calls (`stage1/rec/ctl` 53, `stage1/rec/m128` 15, `stage1/rec/twoplayer` 7 and 2 more) |
| Called from | `Attract`, `GetKey` (falls into), `MenuSelect`, `RecordTie` |
| Calls | `ScanKeys`, `WaitKeyTimeout` (tail), `DelayBC` |
| Reads | `$8002`-`$8003` (`Start+2`, `InitialRecords`); `$831B` (`ControlMethod`) |
| Writes | `$8002`-`$8003` (`Start+2`, `InitialRecords`) |
| Ports in | `$001F` |

### `WaitKeyTimeout` (`$8573`)

**The keys stayed down for the whole timeout: C**

Known only from the code: every wait in the recordings saw the keys released in time.

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | run into, not called, 345,388 t-states own (0.02 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/ctl`, `stage1/rec/names`) |
| Called from | `IntVector` (tail), `WaitKey` (tail) |
| Calls | `ScanKeys`, `DelayBC` |
| Reads | `$8002`-`$8003` (`Start+2`, `InitialRecords`); `$831B` (`ControlMethod`) |
| Writes | `$8002`-`$8003` (`Start+2`, `InitialRecords`) |
| Ports in | `$001F` |

### `Delay` (`$85A2`)

**About 2 s: 5 x 53 846 turns of DEC BC / LD A,B / OR C / JR NZ**

Witness: L1 5 (c1, names, stages, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 7,002,035 t-states own (0.47 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/twoplayer` 2, `stage1/rec/names` 1, `stage1/rec/stages` 1) |
| Called from | `IntVector` (tail), `TurnSkip`, `RecordTie` |

### `ReadControls` (`$85B0`)

**D = the controls: 0 throttle, 1 wheelie, 2 left, 3 right, 4 brakes, 5 pause (H), 6 reset (R)**

Seven tests: LD A,half row / IN A,(port) / AND mask / JR NZ (JR Z for the Kempston) / SET n,D. The first five are patched by PatchControls (the image holds method 3's SINCLAIR LEFT tests, half row `$F7`).

Recorded: c1, ctl: every method; ctl's Kempston run sets DE = `$1F28`.

Witness: L1 10165 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1,148 calls, 329,880 t-states own (0.02 %) |
| Runs (the other recordings) | 9,017 calls (`stage1/rec/stages` 3,426, `stage1/rec/crash` 1,084, `stage1/rec/names` 925 and 9 more) |
| Called from | `IntVector` (tail), `MenuSelect`, `RecordTie`, `HudPlayer`, `GetUpSlide`, `BikeLateralPush` |
| Ports in | `$001F`, `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### `MenuSelect` (`$85F9`)

**Highlight item A of menu HL, colour E, until SPACE or fire picks it (NC, A) or about 22 s pass (C)**

HL = a list: the count, then four bytes an item (line, column, attribute, length), the PrintList layout of the same texts. The item's bar (column - 1, length + 2) gets attribute (attr AND `$47`) OR E (PaintAttrs; RestoreBar puts it back). WaitKey `$04E2`: SPACE (3) or ReadControls = brakes only picks; THROTTLE moves up (MenuUp), any other key down, wrapping.

Recorded: c1, m128, ctl.

Witness: L1 29 (c1, ctl, m128, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 7 calls, 7,013 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/ctl` 18, `stage1/rec/m128` 3, `stage1/rec/twoplayer` 1) |
| Called from | `Menu` |
| Calls | `WaitKey`, `ReadControls`, `PaintAttrs` |
| Reads | `$8000` (`Start`); `$8C0F`-`$8C55` (`MenuItems`, `ControlItems`, `DefineItems`) |
| Writes | `$8000` (`Start`); `$8625` (`MenuColour+1`); `$8659`-`$865D` (`RestoreBar+1`) |

### `MenuUp` (`$8644`)

**THROTTLE: the item before (wrapping)**

Known only from the code: the recordings moved down only.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `RestoreBar` |

### `RestoreBar` (`$8658`)

**PaintAttrs with the bar's saved BC and DE (the operands at `$8659` and `$865C`, written by MenuSelect)**

Witness: L1 61 (c1, ctl, m128, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 11 calls, 220 t-states own (0.00 %) |
| Runs (the other recordings) | 50 calls (`stage1/rec/ctl` 35, `stage1/rec/m128` 11, `stage1/rec/twoplayer` 4) |
| Called from | `DefinePauseKey`, `MenuUp` |
| Calls | `PaintAttrs` (falls into) |

### `PaintAttrs` (`$865E`)

**D attributes E from column B on pixel line C**

Witness: L1 1943 (c1, ctl, m128, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 29 calls, 13,835 t-states own (0.00 %) |
| Runs (the other recordings) | 121 calls (`stage1/rec/ctl` 87, `stage1/rec/m128` 25, `stage1/rec/twoplayer` 9) |
| Called from | `MenuSelect`, `RestoreBar` (falls into) |
| Calls | `SetAttr` |

### `ClearScreen` (`$8666`)

**Border black; a wipe: 32 times every pixel line and attribute row one byte to the left**

Witness: L1 28 (c1, ctl, m128, names, stages, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 6 calls, 8,890,568 t-states own (0.60 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/ctl` 11, `stage1/rec/m128` 4, `stage1/rec/stages` 4 and 2 more) |
| Called from | `IntVector` (tail), `Attract`, `Menu`, `NewGame`, `ShowScores` |
| Calls | `Copy32` |
| Reads | `$5801`-`$5AFF` (screen); `$FE00`-`$FF7F` (`RowTable`) |
| Writes | `$401F`-`$54FF` (screen); `$551F`-`$55DF` (screen); `$55FF` (screen); `$561F`-`$56DF` (screen); `$56FF` (screen); `$571F`-`$57DF` (screen); 1 more ranges |
| Ports out | `$00FE` |

### `DelayBC` (`$86A5`)

**DJNZ / DEC C: B x C turns**

Witness: L1 119007349 (c1, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 42,122 calls, 131,544,349 t-states own (8.85 %) |
| Runs (the other recordings) | 105,750 calls (`stage1/rec/twoplayer` 35,491, `stage1/rec/ctl` 31,657, `stage1/rec/names` 23,882 and 6 more) |
| Called from | `IntVector` (tail), `WaitKey`, `WaitKeyTimeout` |

### `PrintList` (`$86AB`)

**Print IX's list of texts from HL: the count, then (line, column, attribute, length) each**

Witness: L1 72 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 20 calls, 16,032 t-states own (0.00 %) |
| Runs (the other recordings) | 52 calls (`stage1/rec/ctl` 33, `stage1/rec/m128` 9, `stage1/rec/twoplayer` 5 and 4 more) |
| Called from | `IntVector` (tail), `Menu`, `PlayTurn` |
| Calls | `PrintString` |
| Reads | `$8BED`-`$8C0E` (`MenuLayout`, `MenuLayout2`); `$8C20`-`$8C55` (`ControlItems`, `DefineItems`); `$8DAC`-`$8DC4` (`HudLayout`) |

### `AddScore` (`$86C9`)

**Add the 7 digits ending at HL to Score (ASCII, leading blanks), then DrawScore; not in a demo**

The digits are 0-9 values (ScoreAdd's, `$7C3D-$7C41`, and the time bonus); the score's leading zeros (up to six) become blanks.

Witness: L1 4850 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `AddScore` at work](img/routines/AddScore.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 666 calls, 485,286 t-states own (0.03 %) |
| Runs (the other recordings) | 4,184 calls (`stage1/rec/stages` 1,762, `stage1/rec/crash` 533, `stage1/rec/m128` 524 and 9 more) |
| Called from | `IntVector` (tail), `HudPlayer`, `StageEnd` |
| Calls | `DrawScore` (tail) |
| Reads | `$5E18`-`$5E1E` (`Score`); `$7C30`-`$7C42` (`DemoMode`, `GetUp`, `Players`, `Speed` and 4 more) |
| Writes | `$5E18`-`$5E1E` (`Score`) |

### `DrawScore` (`$86FA`)

**Score's 7 characters at column 25, line 8, attribute `$69`**

Witness: L1 4572 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 552 calls, 22,080 t-states own (0.00 %) |
| Runs (the other recordings) | 3,449 calls (`stage1/rec/stages` 1,710, `stage1/rec/crash` 534, `stage1/rec/m128` 406 and 4 more) |
| Called from | `IntVector` (tail), `AddScore` (tail), `PlayTurn` |
| Calls | `PrintString` (tail) |

### `FormatTime` (`$8706`)

**The time at HL (seconds BCD with `$60` a minute, hundredths BCD) into TimeText's digits**

Witness: L1 31 (c1, names, stages).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 6 calls, 886 t-states own (0.00 %) |
| Runs (the other recordings) | 25 calls (`stage1/rec/stages` 18, `stage1/rec/names` 7) |
| Called from | `RecordTie`, `PrintTime`, `StageEnd` |
| Calls | `BcdToText` |
| Reads | `$5E00`-`$5E17` (`Records`, `Player`); `$7C36`-`$7C37` (`TotalTime+1`) |
| Writes | `$874E`-`$8754` (`TimeText`) |

### `BcdToText` (`$8724`)

**A (BCD) to two digit characters: L the tens, H the units**

Witness: L1 62 (c1, names, stages).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 12 calls, 840 t-states own (0.00 %) |
| Runs (the other recordings) | 50 calls (`stage1/rec/stages` 36, `stage1/rec/names` 14) |
| Called from | `FormatTime` |

## flow

`src/game/flow.asm`

### `NewGame` (`$8755`)

**Clear both player blocks, set the timers, the tracks and the countdowns, then the turn loop**

ClearScreen; `$5E0D-$5E7C` zero; both scores "      0"; outside a demo both countdowns 16; player characters '2' here and '1' in the other block (swapped at once by the loop); OtherPlayer's Timer = `$60` and, with two players, Player's too; the track pointers TrackPtr = Track, the stage lists StageListPtr = StageList, the segment progress `$80`.

Recorded: c1, m128: one player; twoplayer: both.

Witness: L1 13 (c1, ctl, m128, stages, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 3 calls, 93,867 t-states own (0.01 %) |
| Runs (the other recordings) | 10 calls (`stage1/rec/ctl` 5, `stage1/rec/m128` 2, `stage1/rec/stages` 2 and 1 more) |
| Called from | `IntVector` (tail), `Attract`, `Menu` (tail), `TurnSkip` (tail) |
| Calls | `Attract` (tail), `ClearScreen`, `PlayTurn` |
| Reads | `$5E0D`-`$5E7C` (`Player`, `OtherPlayer`); `$7C30`-`$7C32` (`DemoMode`, `GetUp`, `Players`) |
| Writes | `$5E0D`-`$5E7C` (`Player`, `OtherPlayer`) |

### `TurnSkip` (`$87E9`)

**The player's game is over but the other's is not: next turn**

Known only from the code: in twoplayer both games ended in the same round of turns.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `GetKey`, `Delay`, `NewGame` (tail) |

### `PlayTurn` (`$87FC`)

**A turn: the HUD (frames, TOP, the best score, STAGE, TIME, SPEED, SCORE), GameEntry, a jump through GameEntryJump to StartRace; at game over the tables**

The pixel lines 0-63 cleared, their attributes `$69`; HudLayout's texts; two frames (FrameChars); DrawScore; the best score (HiScores' first row) at column 5; the stage in big digits; PrintTimer; SPEED 0; CALL GameEntry (JP GameEntryJump, JP StartRace). Back with Timer nonzero: RET (the next turn). Timer 0: the game is over: RecordStages, the totals (TotalTime = the player's finished stages, Records' total), the lap table (LapTable), then the high scores (ScoreCheck).

Recorded: c1, m128: game over by the timer in stage 1; stages: game over after the finish; twoplayer: turns.

Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 8 calls, 471,050 t-states own (0.03 %) |
| Runs (the other recordings) | 17 calls (`stage1/rec/ctl` 5, `stage1/rec/m128` 4, `stage1/rec/twoplayer` 3 and 4 more) |
| Called from | `IntVector` (tail), `NewGame` |
| Calls | `PrintString`, `PrintNumber`, `DrawFrame`, `PrintTimer`, `BigDigit`, `PrintList`, `DrawScore`, `GameEntry` |
| Reads | `$4000`-`$47FE` (screen); `$5E00`-`$5E35` (`Records`, `Player`); `$5E57` (`OtherPlayer+18`); `$5E80`-`$5E9F` (`StageList`); `$7C35` (`TotalTime`); `$83EB`-`$83EC` (`DrawCursor+1`); 3 more ranges |
| Writes | `$4000`-`$47FF` (screen); `$5800`-`$58BF` (screen); `$5E02`-`$5E07` (`Records+2`); `$7C33`-`$7C34` (`Speed`); `$83EB`-`$83EC` (`DrawCursor+1`); `$874E` (`TimeText`); 3 more ranges |
| Ports out | `$00FE` |

### `RecordTie` (`$887F`)

**Equal seconds: compare the hundredths**

Known only from the code: no recorded stage time had the record's seconds.

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings run into, not called (`stage1/rec/names`) |
| Called from | `IntVector` (tail), `NameSpace` (tail), `NameRightWrap` (tail) |
| Calls | `PrintString`, `PrintChar`, `PrintGlyph`, `PrintNumber`, `DrawCursor`, `KeyOrFire`, `WaitKey`, `Delay`, `ReadControls`, `FormatTime`, `NameEntrySound`, `ShowScores`, `PrintTime`, `SumTimes`, `Divide`, `Multiply` |
| Reads | `$5E1F` (`Timer`); `$5E57` (`OtherPlayer+18`); `$83EB`-`$83EC` (`DrawCursor+1`); `$8AC5`-`$8AD1` (`NameGrid+2`) |
| Writes | `$83EB`-`$83EC` (`DrawCursor+1`); `$8A17`-`$8A1B` (`NamePtr+1`, `NamePlace`); `$8AF1` (`NameEntrySound+1`); `$8E41`-`$8E42` (`HiScores+95`) |

### `NameDelete` (`$8A2C`)

**=: one character back, blanked (not before the first)**

The recording names (c1's play, the score POKEd to 300 000) types = after its first letter (frame 2 526).

Witness: L1 1 (names).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/names` 1) |
| Calls | `PrintChar` |

### `NameSpace` (`$8A46`)

**After a delete's blank: DEC B, the column steps back**

Witness: L1 1 (names).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/names` 1) |
| Calls | `RecordTie` (tail) |

### `NameLeftWrap` (`$8A66`)

**LEFT at the first column: wrap to column 29**

Witness: L1 1 (names).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/names` 1) |

### `NameRightWrap` (`$8A7B`)

**RIGHT at the last column: wrap to column 1**

Witness: L1 1 (names).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/names` 1) |
| Calls | `DrawCursor`, `RecordTie` (tail) |

### `NameEntrySound` (`$8AF0`)

**One step of the name entry: a beeper blip rising in pitch for a few calls after a pick (NameSound counts down, the period is NameSound + 8), then a pause**

NameSound (the LD A operand) is set to `$28` by a pick and counts down: 191 edges of period NameSound + 8, then a quiet wait of 191 x (`$31` - NameSound) turns, NameSound taken after the count (CPL, ADD A,`$32`): every call with a blip takes the same time. At 0 only the wait of 191 x `$31` turns, a shorter call.

Recorded: stages: the name entry; the OUT (`$FE`) at `$8AFF`.

Witness: L1 1092 (names, stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1,092 calls (`stage1/rec/names` 898, `stage1/rec/stages` 194) |
| Called from | `IntVector` (tail), `RecordTie` |
| Reads | `$8AF1` (`NameEntrySound+1`) |
| Writes | `$8AF1` (`NameEntrySound+1`) |
| Ports out | `$00FE`, `$10FE` |

### `ShowScores` (`$8B19`)

**Wipe and draw HiScores from pixel line C: SCORE, NAME, TIME, then five rows of score, name, time**

Witness: L1 2 (names, stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 2 calls (`stage1/rec/names` 1, `stage1/rec/stages` 1) |
| Called from | `RecordTie` |
| Calls | `PrintString`, `ClearScreen` |

### `PrintTime` (`$8B5E`)

**Print the time at HL (minutes, then FormatTime's pair) as 0'00"00, 7 characters**

Witness: L1 4 (c1, names, stages).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 96 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/stages` 2, `stage1/rec/names` 1) |
| Called from | `RecordTie` |
| Calls | `PrintString` (tail), `FormatTime` |
| Reads | `$5E0A` (`Records+10`); `$7C35` (`TotalTime`) |
| Writes | `$874E` (`TimeText`) |

### `SumTimes` (`$8B70`)

**(HL) = minutes, seconds, hundredths: the sum of B times from IX (BCD, `$60` seconds a minute)**

Witness: L1 4 (c1, names, stages).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 724 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/stages` 2, `stage1/rec/names` 1) |
| Called from | `RecordTie` |
| Reads | `$5E00`-`$5E17` (`Records`, `Player`) |
| Writes | `$5E0A`-`$5E0C` (`Records+10`); `$7C35`-`$7C37` (`TotalTime`) |

### `Divide` (`$8B98`)

**HL = D * 256 / E (8.8 fixed point; C the remainder)**

The lap table's %, the road's slopes (BuildRoadRows).

Witness: L1 138289 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 18,001 calls, 20,060,417 t-states own (1.35 %) |
| Runs (the other recordings) | 120,322 calls (`stage1/rec/stages` 53,899, `stage1/rec/crash` 12,990, `stage1/rec/m128` 12,286 and 9 more) |
| Called from | `IntVector` (tail), `RecordTie`, `DrawRoad`, `GroundTexture` |

### `Multiply` (`$8BAE`)

**DE = A x L (8 x 8 bits, unrolled)**

Its last byte (MultiplyEnd) is a RET that RoadPatch turns into JP `$93B1` (DrawRoad) and RoadRows (`$9A96`) back into RET.

Recorded: c1: called by the road and the objects every pass.

Witness: L1 582990 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 74,217 calls, 21,346,204 t-states own (1.44 %) |
| Runs (the other recordings) | 508,938 calls (`stage1/rec/stages` 222,806, `stage1/rec/m128` 60,963, `stage1/rec/crash` 60,438 and 9 more) |
| Called from | `IntVector` (tail), `RecordTie`, `DrawRoad`, `DrawRiders`, `RoadJumpRows`, `RoadRowsCrest`, `SetHorizon`, `DrawObject`, `OffRoad`, `GroundTexture`, `StartRace`, `RaceStep`, `RacePass`, `RampSpeed`, `RaceQuit`, `BikeControl`, `GetUpSlide`, `BikeLateralPush` |
| Calls | `DrawRoad` (tail) |
| Writes | `$93FA` (`DrawRoadRight+1`); `$FEE4`-`$FF3D` (`RowTable+228`) |

### `GameEntry` (`$8E50`)

**JP StartRace (PlayTurn's CALL)**

Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 8 calls, 80 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/rec/ctl` 5, `stage1/rec/m128` 4, `stage1/rec/twoplayer` 3 and 4 more) |
| Called from | `PlayTurn` |
| Calls | `GameEntryJump` (tail) |

### `Copy32` (`$8E53`)

**JP CopyRows**

Witness: L1 327207 (c1, ctl, m128, names, stages, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 99,624 calls, 995,672 t-states own (0.07 %) |
| Runs (the other recordings) | 227,842 calls (`stage1/rec/ctl` 66,142, `stage1/rec/stages` 55,953, `stage1/rec/m128` 55,939 and 2 more) |
| Called from | `IntVector` (tail), `ScrollUp` (tail), `ClearScreen` |
| Calls | `CopyRows` (tail) |

## render

`src/game/render.asm`

### `SetRowTable` (`$8E7D`)

**RowTable's lines 64-191 += DE; lines 40-63: the screen's (DE = `$5A00`) or the back buffer's rows**

In: DE = `$A600` (to the back buffer) or `$5A00` (back to the screen: `$A600` + `$5A00` = `$1000`0). Lines 40-63 get lines 168-191's addresses minus `$1000` (the screen's rows 40-63), and with DE not `$5A00` then `$EB00` + 32 n.

Recorded: c1: StartRace `$A466` and RaceEnd `$AAA8` each stage.

Witness: L1 48 (c1, crash, ctl, fall5, m128, names, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 15 calls, 298,110 t-states own (0.02 %) |
| Runs (the other recordings) | 33 calls (`stage1/rec/ctl` 11, `stage1/rec/m128` 7, `stage1/rec/twoplayer` 5 and 5 more) |
| Called from | `IntVector` (tail), `StartRace`, `RaceEnd` (tail) |
| Reads | `$FE80`-`$FF7F` (`RowTable+128`) |
| Writes | `$FE50`-`$FF7F` (`RowTable+80`) |

### `ClearBendRows` (`$8ED8`)

**BendRows = 0 (`$5B80-$5C00`, 129 bytes through CopyRows)**

Witness: L1 175 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 25 calls, 1,229 t-states own (0.00 %) |
| Runs (the other recordings) | 150 calls (`stage1/rec/stages` 68, `stage1/rec/crash` 16, `stage1/rec/m128` 16 and 8 more) |
| Called from | `StartRace`, `SegmentDecode` |
| Calls | `CopyRows` (tail) |
| Writes | `$5B80` (`BendRows`) |

### `CopyRows` (`$8EE4`)

**Copy A x 32 bytes HL -> DE (32 unrolled LDI a turn)**

Witness: L1 1004349 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 201,303 calls, 126,362,822 t-states own (8.50 %) |
| Runs (the other recordings) | 803,174 calls (`stage1/rec/stages` 293,403, `stage1/rec/m128` 131,152, `stage1/rec/ctl` 89,768 and 9 more) |
| Called from | `IntVector` (tail), `Copy32` (tail), `ClearBendRows` (tail), `CopyBuffer` (tail) |
| Reads | `$4001`-`$5800` (screen); `$5820`-`$5ADF` (screen); `$5B80`-`$5BFE` (`BendRows`); `$EB00`-`$FDFF` (`TrackTables`, `OldGraphics`, `BackBuffer`) |
| Writes | `$4000`-`$5ABF` (screen); `$5B81`-`$5BFF` (`BendRows+1`) |

### `DrawSprite` (`$8F29`)

**A byte-aligned sprite: C bytes wide, B rows from DE, at x H (carry: x < 0), bottom line L**

Sets the core's skip (BlitSkip, `$9104`) and first column (`$906A`, `$90FE`) from x, clipping at the left edge (RET when wholly off), then BlitRows.

Witness: L1 13978 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 151 calls, 261,376 t-states own (0.02 %) |
| Runs (the other recordings) | 1,208 calls (`stage1/rec/stages` 630, `stage1/rec/m128` 151, `stage1/rec/crash` 150 and 8 more) |
| Called from | `IntVector` (tail), `DrawRiders`, `DrawObject`, `DrawBike` (tail) |
| Calls | `ShiftLeftHead` (tail) |
| Writes | `$906A` (`BlitRows+1`); `$90FE`-`$9104` (`BlitNext+1`) |

### `DrawShifted` (`$8F53`)

**A sprite at any x: its rows shifted by x AND 7 into the line buffer at `$8000`, then BlitRows**

In as DrawSprite. Row by row: the bytes copied (the unrolled LDI chain entered by the patched DJNZ at `$8FE7`), then RR (HL) or RL (HL) chains shift the row (x AND 7 below 4: right; else left by 8 - n). Byte-aligned x goes straight to BlitRows.

Recorded: c1: the bike, the riders and the objects every pass.

Witness: L1 50169 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `DrawShifted` at work](img/routines/DrawShifted.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1,723 calls, 2,531,399 t-states own (0.17 %) |
| Runs (the other recordings) | 11,118 calls (`stage1/rec/stages` 4,818, `stage1/rec/crash` 1,188, `stage1/rec/m128` 1,151 and 9 more) |
| Called from | `IntVector` (tail), `DrawRiders`, `DrawObject`, `DrawBike` (tail), `DustCarry` (tail) |
| Calls | `ShiftCopyHead` (tail), `ShiftLeftHead` (tail) |
| Writes | `$8FE8` (`l_8FE5+3`); `$9020`-`$9022` (`l_901F+1`, `l_9021`); `$905B`-`$906A` (`l_905A+1`, `l_905C`, `l_9064`, `BlitRows`); `$90FE`-`$9104` (`BlitNext+1`) |

### `ShiftCopyHead` (`$8FCB`)

**The first three LDI of the row copy: entered only for rows of 12 bytes or more**

Known only from the code: no sprite drawn shifted is that wide.

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | run into, not called, 10,562,541 t-states own (0.71 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/stages`, `stage1/rec/m128`, `stage1/rec/crash` and 9 more) |
| Called from | `IntVector` (tail), `DrawShifted` (tail) |
| Calls | `ShiftRightHead` (tail), `ShiftLeftHead` (tail) |
| Reads | `$6BE8`-`$6D33` (`ObjectSprites`); `$74EB`-`$75AF` (`ObjectSprites+2307`); `$9067` (`l_9064+3`); `$B301`-`$B701` (`Gap5`, `Sprites`); `$BC8F`-`$BDA7` (`Sprites+2441`); `$C0DA`-`$C27A` (`Sprites+3540`); 3 more ranges |
| Writes | `$8000`-`$80F6` (`Start`, `InitialRecords`, `LineBufferTail`, `Init`); `$905F`-`$9060` (`l_905C+3`) |

### `ShiftRightHead` (`$8FF8`)

**The first two RR (HL) of the right shift: rows of 12 bytes or more**

Known only from the code.

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | run into, not called, 10,086,424 t-states own (0.68 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/stages`, `stage1/rec/m128`, `stage1/rec/crash` and 9 more) |
| Called from | `IntVector` (tail), `ShiftCopyHead` (tail) |
| Calls | `ShiftLeftHead` (tail) |
| Reads | `$8000`-`$80FF` (`Start`, `InitialRecords`, `LineBufferTail`, `Init`) |
| Writes | `$8000`-`$80FF` (`Start`, `InitialRecords`, `LineBufferTail`, `Init`) |

### `ShiftLeftHead` (`$9033`)

**The first two RL (HL) of the left shift: rows of 12 bytes or more**

Known only from the code.

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | run into, not called, 26,236,866 t-states own (1.77 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/stages`, `stage1/rec/m128`, `stage1/rec/crash` and 9 more) |
| Called from | `IntVector` (tail), `DrawSprite` (tail), `DrawShifted` (tail), `ShiftCopyHead` (tail), `ShiftRightHead` (tail) |
| Calls | `BlitHead` (tail) |
| Reads | `$8001`-`$80F6` (`Start+1`, `InitialRecords`, `LineBufferTail`, `Init`); `$90FE` (`BlitNext+1`) |
| Writes | `$7C38`-`$7C39` (`SavedSp`); `$8001`-`$80F6` (`Start+1`, `InitialRecords`, `LineBufferTail`, `Init`); `$90F6`-`$910B` (`BlitRow+62`, `l_90F7`, `l_90F9`, `BlitNext` and 1 more); `$FE86`-`$FE87` (`RowTable+134`); `$FE98`-`$FE9F` (`RowTable+152`); `$FEB0`-`$FECF` (`RowTable+176`); 3 more ranges |

### `BlitHead` (`$90B3`)

**The first OR of the unrolled row: rows of 13 bytes**

Known only from the code.

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | run into, not called, 78,155,912 t-states own (5.26 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/stages`, `stage1/rec/m128`, `stage1/rec/crash` and 9 more) |
| Called from | `IntVector` (tail), `ShiftLeftHead` (tail) |
| Reads | `$6BE8`-`$75AF` (`ObjectSprites`); `$7C38`-`$7C39` (`SavedSp`); `$8000`-`$8107` (`Start`, `InitialRecords`, `LineBufferTail`, `Init`); `$B301`-`$E2BE` (`Gap5`, `Sprites`); `$EB00`-`$FDDF` (`TrackTables`, `OldGraphics`, `BackBuffer`) |
| Writes | `$EB00`-`$FDDF` (`TrackTables`, `OldGraphics`, `BackBuffer`); `$FE50`-`$FF7F` (`RowTable+80`) |

### `DrawMirrored` (`$970C`)

**Copy sprite DE's rows into the line buffer at `$8000` mirrored (bytes reversed, bits through ReverseTable)**

In: IX = a descriptor (rows, width; width bit 7: byte-aligned, 3 more bytes room). Out: DE = `$8000`, the sprite in the buffer. Used for the bike leaning the other way and for riders and objects on the bend's other side.

Recorded: c1.

Witness: L1 2275 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 388 calls, 3,290,543 t-states own (0.22 %) |
| Runs (the other recordings) | 1,887 calls (`stage1/rec/stages` 871, `stage1/rec/m128` 227, `stage1/rec/twoplayer` 226 and 8 more) |
| Called from | `DrawRiders`, `DrawBike` |
| Reads | `$5D00`-`$5DFF` (`ReverseTable`); `$9143`-`$9156` (`LateralX+4`); `$9183`-`$9206` (`RiderSprites+5`); `$D49A`-`$DAF3` (`Sprites+8596`) |
| Writes | `$8000`-`$8108` (`Start`, `InitialRecords`, `LineBufferTail`, `Init`); `$8FC2`-`$8FC3` (`l_8F9E+36`); `$9733` (`l_9732+1`); `$974A` (`l_973A+16`) |

### `MirrorCarry` (`$9722`)

**INC D: a sprite crossing a page boundary at its end (not met)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings run into, not called (`stage1/rec/twoplayer`, `stage1/rec/truck`, `stage1/rec/tech-land-wheelie` and 5 more) |
| Called from | `IntVector` (tail) |
| Reads | `$5D00`-`$5DFF` (`ReverseTable`); `$D49A`-`$DAF3` (`Sprites+8596`) |
| Writes | `$8000`-`$8108` (`Start`, `InitialRecords`, `LineBufferTail`, `Init`); `$8FC2`-`$8FC3` (`l_8F9E+36`) |

### `GameEntryJump` (`$98EF`)

**JP StartRace (GameEntry's target)**

Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 8 calls, 80 t-states own (0.00 %) |
| Runs (the other recordings) | 17 calls (`stage1/rec/ctl` 5, `stage1/rec/m128` 4, `stage1/rec/twoplayer` 3 and 4 more) |
| Called from | `GameEntry` (tail) |
| Calls | `StartRace` (tail) |

### `GapRowsJump` (`$98F2`)

**JP GapRows**

Witness: L1 4740 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 786 calls, 7,850 t-states own (0.00 %) |
| Runs (the other recordings) | 3,955 calls (`stage1/rec/stages` 1,382, `stage1/rec/m128` 577, `stage1/rec/crash` 576 and 8 more) |
| Called from | `IntVector` (tail), `DrawRoad` |
| Calls | `GapRows` (tail) |

### `CopyBuffer` (`$98F5`)

**The back buffer to the screen: lines DrawnTop (the highest of TopClip and the last pass's) to 63 one by one, then `$EE00` to `$4800`**

TopClip (`$916C`) is the highest line drawn this pass; DrawnTop (`$916D`) last pass's. Lines below 64 are copied through CopyRows a line at a time (screen order); then BlitMode's JR (byte 7 of the stage's StageParams, at `$9944`) is 0 on every stage: CopyLower copies lines 64-191 (`$EE00-$FDFF` to `$4800-$57FF`) in one CopyRows of 128.

Recorded: c1: every pass; the heaviest pass's largest single cost with the road.

Witness: L1 5138 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `CopyBuffer` at work](img/routines/CopyBuffer.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 776 calls, 251,542 t-states own (0.02 %) |
| Runs (the other recordings) | 4,362 calls (`stage1/rec/stages` 1,786, `stage1/rec/crash` 573, `stage1/rec/m128` 572 and 9 more) |
| Called from | `IntVector` (tail), `HudPlayer` |
| Calls | `CopyRows` (tail) |
| Reads | `$916C`-`$916D` (`TopClip`, `DrawnTop`) |
| Writes | `$7C38`-`$7C39` (`SavedSp`) |

### `BlitCopyPop` (`$9950`)

**A POP copy of B lines through RowTable (each line from back buffer - `$A600`), then JP (IY)**

Known only from the code: no stage's byte 7 selects it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## objects

`src/game/objects.asm`

### `DrawRiders` (`$9615`)

**Draw each rider on a visible row: x from its lateral place, the row's centre (the bend) and the row's scale; sprite by distance and pose**

RiderSprites' row is the first whose threshold is above the rider's row; the pose (4 for the second kind) picks the descriptor (rows, width, address; bit 7 of the width: byte-aligned, of the rows: never mirrored; without it the sprite is mirrored (DrawMirrored) when BendDir is 1). TopClip is raised to the sprite's top. DrawSprite or DrawShifted (DrawMirrored first when needed).

Recorded: c1, stages, twoplayer: riders on screen.

Witness: L1 5195 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 1,800,574 t-states own (0.12 %) |
| Runs (the other recordings) | 4,410 calls (`stage1/rec/stages` 1,789, `stage1/rec/m128` 577, `stage1/rec/crash` 576 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `Multiply`, `DrawSprite`, `DrawShifted`, `DrawMirrored` |
| Reads | `$5B80`-`$5BCF` (`BendRows`); `$5C00`-`$5C4F` (`RoadLines`); `$5C80`-`$5CD7` (`Riders`); `$5E2D` (`BendDir`); `$7F00`-`$7F4F` (`RowScale`); `$916C` (`TopClip`); 1 more ranges |
| Writes | `$916C` (`TopClip`); `$9656` (`l_964E+8`) |

### `DrawObject` (`$9F18`)

**Draw the object on row A with descriptor list IX at lateral B: the list's entry for the row, x from the row's centre (the bend) and the scale**

RET when the row is beyond the list's farthest. Entries scanned until the row's threshold; the screen line is RoadLines[row] (the LD A at `$9F80`); x = the row's centre (BendRows) +/- B scaled (RowScale); the part above line 40 is cut off; TopClip raised. JP (IY): DrawSprite (byte-aligned) for rows below the list's aligned row, the near ones; DrawShifted beyond.

Recorded: c1: every pass.

Witness: L1 78179 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `DrawObject` at work](img/routines/DrawObject.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 10,982 calls, 7,425,444 t-states own (0.50 %) |
| Runs (the other recordings) | 67,207 calls (`stage1/rec/stages` 28,342, `stage1/rec/m128` 9,531, `stage1/rec/crash` 9,134 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `Multiply`, `DrawSprite`, `DrawShifted` |
| Reads | `$5B80`-`$5C7F` (`BendRows`, `RoadLines`); `$5E2D` (`BendDir`); `$7F00`-`$7F7F` (`RowScale`); `$916C` (`TopClip`); `$976B`-`$98EE` (`ObjectList4`, `ObjectList5`, `ObjectList1`, `ObjectList6` and 4 more) |
| Writes | `$916C` (`TopClip`); `$9F62` (`l_9F5A+8`); `$9F81` (`l_9F6B+22`) |

### `DrawSplash` (`$A09A`)

**Stages 2 and 4 (SplashOn): the splash under the bike, two frames alternating (`$DED3` 20 x 5, `$DF37` 15 x 3)**

Recorded: stages and reset3 (stage 2).

Witness: L1 586 (stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 586 calls (`stage1/rec/stages` 586) |
| Called from | `RacePass` |
| Calls | `DrawDust` (tail) |
| Reads | `$7C2E` (`PassCount`) |

### `DrawDust` (`$A0AE`)

**SkidLevel: the dust beside the bike, two frames (`$DF64` 12 x 4, `$DF94` 14 x 4)**

Witness: L1 448 (stages, truck).

[Animation: `DrawDust` at work](img/routines/DrawDust.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 448 calls (`stage1/rec/stages` 352, `stage1/rec/truck` 96) |
| Called from | `DrawSplash` (tail), `RacePass` |
| Reads | `$5C00` (`RoadLines`); `$5CEA` (`JumpHeight+1`); `$7C2E`-`$7C34` (`PassCount`, `Beeper`, `DemoMode`, `GetUp` and 2 more); `$9175`-`$9178` (`Pose`, `Lean`, `RoadTopRow`, `BikeX`); `$A0F5`-`$A0FC` (`DustOffsets+2`) |

### `DustCarry` (`$A0DC`)

**INC H: DustOffsets crossing a page (not met: `$A0F3` + at most 9 stays in the page)**

Known only from the code. DrawDust and DrawSplash run on from `$A0DD` (DustPlace).

Known only from the code.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `DrawShifted` (tail) |

### `GapRows` (`$A0FD`)

**Stage 3: the rows between the two gap marks become `$FE` in RowList (not drawn); the bike over them sets InGap**

GapMarks are the rows of the track's two `$F0` commands seen this pass (`$7F` none). InGap (`$7C3A`) is read by OffRoadSand: the bike slowed hard and the skid noise.

Recorded: stages, reset3: stage 3.

Witness: L1 4740 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 25,302 t-states own (0.00 %) |
| Runs (the other recordings) | 3,955 calls (`stage1/rec/stages` 1,382, `stage1/rec/m128` 577, `stage1/rec/crash` 576 and 8 more) |
| Called from | `GapRowsJump` (tail) |
| Reads | `$5B13`-`$5B48` (`MoverTail+2`, `RowListTail`); `$5C00`-`$5C7F` (`RoadLines`); `$5E23`-`$5E34` (`Stage`, `Countdown`, `SegmentLeft`, `TrackPtr` and 9 more); `$9137` (`ScrollStep+1`); `$9177` (`RoadTopRow`) |
| Writes | `$5B01`-`$5B47` (`Mover+1`, `MoverTail`, `RowListTail`); `$7C3A` (`InGap`) |

### `GapRowsRet` (`$A142`)

**A lone RET after GapRows' loop, which no branch reaches**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MoveRiders` (`$A21A`)

**Each rider in the race: jump (height, speed - `$02F0`), start a jump at a ramp row, speed toward its top, distance - ScrollStep, pose in bends**

Recorded: c1: from the countdown's end; stages: jumps at stage 3's ramps.

Witness: L1 5097 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `MoveRiders` at work](img/routines/MoveRiders.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 777 calls, 24,087 t-states own (0.00 %) |
| Runs (the other recordings) | 4,320 calls (`stage1/rec/stages` 1,781, `stage1/rec/crash` 573, `stage1/rec/m128` 569 and 9 more) |
| Called from | `RacePass` |
| Reads | `$5C80`-`$5CD7` (`Riders`); `$5CF5` (`JumpRows`); `$5E26`-`$5E2F` (`SegmentLeft+1`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 3 more); `$9136`-`$9137` (`ScrollStep`) |
| Writes | `$5C83`-`$5CD1` (`Riders+3`) |

### `MoveRidersLoop` (`$A220`)

**One rider (IX; HL's load is harmless in the other register set)**

Witness: L1 25485 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 3,885 calls, 527,921 t-states own (0.04 %) |
| Runs (the other recordings) | 17,940 calls (`stage1/rec/stages` 8,905, `stage1/rec/m128` 2,845, `stage1/rec/twoplayer` 2,165 and 7 more) |
| Called from | `IntVector` (tail), `MoveRidersIx` (falls into), `RiderNoRamp` (tail) |
| Calls | `RiderNoRamp` (tail) |
| Reads | `$5C80`-`$5CD9` (`Riders`); `$5CF5`-`$5CF7` (`JumpRows`); `$5E26`-`$5E2F` (`SegmentLeft+1`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 3 more); `$9136`-`$9137` (`ScrollStep`) |
| Writes | `$5C83`-`$5CD9` (`Riders+3`) |

### `RiderNoRamp` (`$A271`)

**No ramp row ahead of the rider: on to the speed**

Known only from the code: JumpRows always held an end mark within four.

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | run into, not called, 1,551,529 t-states own (0.10 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/stages`, `stage1/rec/m128`, `stage1/rec/truck` and 7 more) |
| Called from | `IntVector` (tail), `MoveRidersLoop` (tail) |
| Calls | `MoveRidersLoop` (tail) |
| Reads | `$5C83`-`$5CD7` (`Riders+3`); `$5E26`-`$5E2F` (`SegmentLeft+1`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 3 more); `$9136`-`$9137` (`ScrollStep`) |
| Writes | `$5C83`-`$5CD1` (`Riders+3`) |

## bike

`src/game/bike.asm`

### `DrawBike` (`$9FBE`)

**Draw the bike: its pose's sprite (mirrored when leaning the other way), the wheels' animation, at BikeX, on the road or in the air**

Not during the countdown's first part or while getting up. Pose 3: entry Lean + 6 (3-6, mirrored for 7-9); others: entry Pose. The wheel patch is XORed in every pass above 64 km/h, every second above 32, every fourth below, never stopped. y: RoadLines[0] or `$C0` in the air, minus JumpHeight; TopClip raised.

Witness: L1 5151 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `DrawBike` at work](img/routines/DrawBike.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 780 calls, 1,150,788 t-states own (0.08 %) |
| Runs (the other recordings) | 4,371 calls (`stage1/rec/stages` 1,757, `stage1/rec/crash` 575, `stage1/rec/m128` 575 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `DrawSprite` (tail), `DrawShifted` (tail), `DrawMirrored` |
| Reads | `$5C00` (`RoadLines`); `$5CEA` (`JumpHeight+1`); `$5E24` (`Countdown`); `$645F` (`SkidLevel`); `$7C2E`-`$7C34` (`PassCount`, `Beeper`, `DemoMode`, `GetUp` and 2 more); `$9128`-`$917D` (`BikePoses+1`, `ScrollStep`, `BendPtr`, `LateralX` and 8 more); 6 more ranges |
| Writes | `$916C` (`TopClip`); `$A043` (`l_A035+14`); `$D2EC`-`$D310` (`Sprites+8166`); `$D51A`-`$D547` (`Sprites+8724`); `$D774`-`$D7B1` (`Sprites+9326`); `$DAA7`-`$DADE` (`Sprites+10145`); 1 more ranges |

### `OffRoad` (`$A1D9`)

**Stages 1, 2 and 4: beyond `$24` off the road's middle, SPEED capped at SPEED * (256 - ((d - `$24`) / 2 + 1)) / 256 + 1**

POKE: the Keep Speed Off Road POKE turns its LD (`$7C34`),A at `$A1F1` into LD A,(nn) (WALKTHROUGH 6.0).

Witness: L1 3917 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 667 calls, 25,819 t-states own (0.00 %) |
| Runs (the other recordings) | 3,250 calls (`stage1/rec/stages` 1,049, `stage1/rec/crash` 522, `stage1/rec/m128` 520 and 7 more) |
| Called from | `OffRoadStage5` (tail), `BikeRoadPlace` (tail) |
| Calls | `Multiply` |
| Reads | `$7C34` (`Speed+1`) |
| Writes | `$7C34` (`Speed+1`) |

### `OffRoadStage5` (`$A1F5`)

**Stage 5: no test on one side (RET NC), else OffRoadSand**

Witness: L1 376 (fall5, stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 376 calls (`stage1/rec/stages` 352, `stage1/rec/fall5` 24) |
| Called from | `BikeRoadPlace` (tail) |
| Calls | `OffRoad` (tail) |
| Reads | `$7C34`-`$7C3A` (`Speed+1`, `TotalTime`, `SavedSp`, `InGap`) |
| Writes | `$645F` (`SkidLevel`) |

### `BikeControl` (`$ACDF`)

**The bike each pass: a fall's count (and its end: the turn ends), getting up, the demo's steering, the controls, bounce, wheelie, lean, sideways speed**

Falling: SPEED * `$D0` / 256 a pass; pose 8 or 9; on stages 3 and 5 the sand adds skid noise (FallSand). The fall's end: FallX = LateralX, Countdown = `$80` (resume), the race ends (RaceEndFall, back to PlayTurn: the next turn). Getting up: GetUp (`$7C31`) slides LateralX toward 0 by 3 a pass. In the air: only BikeLateral. The demo steers back to the middle. Then HeldKeys (the OR operand at `$AD8A`, ReadControls' D of RaceLoop) gives the controls.

Recorded: crash (the falls, frames 3320-4580), twoplayer (the turn handed over at a fall).

Witness: L1 5163 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `BikeControl` at work](img/routines/BikeControl.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 786 calls, 572,872 t-states own (0.04 %) |
| Runs (the other recordings) | 4,378 calls (`stage1/rec/stages` 1,757, `stage1/rec/m128` 577, `stage1/rec/crash` 576 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `Multiply`, `RaceQuit` (tail), `GetUpSlide` (tail) |
| Reads | `$5C00`-`$5C0C` (`RoadLines`); `$5CE9`-`$5CEA` (`JumpHeight`); `$5CFD`-`$5CFE` (`JumpSpeed`); `$5E23`-`$5E2E` (`Stage`, `Countdown`, `SegmentLeft`, `TrackPtr` and 4 more); `$7C2E`-`$7C34` (`PassCount`, `Beeper`, `DemoMode`, `GetUp` and 2 more); `$8E56`-`$8E71` (`LeanTable`, `SteerTable`); 3 more ranges |
| Writes | `$5CE9`-`$5CEA` (`JumpHeight`); `$5CFD`-`$5CFE` (`JumpSpeed`); `$5E24`-`$5E32` (`Countdown`, `SegmentLeft`, `TrackPtr`, `TrackDistance` and 7 more); `$7C31`-`$7C34` (`GetUp`, `Players`, `Speed`); `$913F`-`$9140` (`LateralX`); `$916E`-`$9176` (`FallTime`, `Wheelies`, `Pose`, `Lean`); 3 more ranges |

### `FallStage5` (`$AD36`)

**Stage 5's fall on the sand: skid noise only off the right side**

The recording fall5 (from the stages state of stage 5, the obstacle and truck bytes put back) falls at frames 235-280.

Witness: L1 8 (fall5).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 8 runs of its first instruction, entered by a jump (`stage1/rec/fall5` 8) |

### `GetUpSlide` (`$AD49`)

**GetUp: LateralX toward 0 by 3 a pass**

Witness: L1 4863 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 672 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,191 runs of its first instruction, entered by a jump (`stage1/rec/stages` 1,757, `stage1/rec/crash` 535, `stage1/rec/m128` 527 and 9 more) |
| Called from | `IntVector` (tail), `BikeControl` (tail) |
| Calls | `ReadControls`, `Multiply` |
| Reads | `$5C00` (`RoadLines`); `$5CE9`-`$5CEA` (`JumpHeight`); `$5CFD`-`$5CFE` (`JumpSpeed`); `$5E24`-`$5E2E` (`Countdown`, `SegmentLeft`, `TrackPtr`, `TrackDistance` and 3 more); `$7C2E` (`PassCount`); `$8E56`-`$8E7D` (`LeanTable`, `SteerTable`, `SetRowTable`); 3 more ranges |
| Writes | `$5CE9`-`$5CEA` (`JumpHeight`); `$5CFD`-`$5CFE` (`JumpSpeed`); `$913F`-`$9140` (`LateralX`); `$916F`-`$9176` (`Wheelies`, `Pose`, `Lean`); `$99F1`-`$99F2` (`HorizonScrollStep+1`); `$A1C9`-`$A1CA` (`BounceTime`, `BounceDir`); 1 more ranges |

### `BikeLateralPush` (`$AE64`)

**The push: (ScrollStep's high byte, doubled on stages 2 and 4) * the bend's factor (`$52`, `$8F`, `$A4`; BendPrev holds the bend), signed by BendDir; HorizonSpeed too**

Then LateralX += the sideways speed (BounceSpeed added during a bounce) + the push, clamped to `$A4-$5C`. In the air: JumpHeight += JumpSpeed, JumpSpeed -= `$02F0`; the landing (below the road's line) ends the jump: pose 3, lean 0, Wheelies 0, and with WHEELIE not held a 6-pass bounce.

Witness: L1 4934 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `BikeLateralPush` at work](img/routines/BikeLateralPush.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 686 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,248 runs of its first instruction, entered by a jump (`stage1/rec/stages` 1,757, `stage1/rec/crash` 554, `stage1/rec/m128` 535 and 9 more) |
| Calls | `ReadControls`, `Multiply` |

### `Crash` (`$AF02`)

**A fall: the bike thrown (JumpHeight from RoadLines[0], JumpSpeed = SPEED / 32 + `$12`), pose 7, FallTime 9 (bit 7 the side), the crash sound**

Recorded: crash, c1, m128, twoplayer (no fall in stages and reset3: their POKEs make the bike immune).

Witness: L1 13 (c1, crash, fall5, m128, truck, twoplayer).

[Animation: `Crash` at work](img/routines/Crash.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 5 calls, 888 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/twoplayer` 2, `stage1/rec/m128` 2, `stage1/rec/crash` 2 and 2 more) |
| Called from | `RacePass`, `TruckCrash` |
| Calls | `CrashSound` (tail) |
| Reads | `$5C00` (`RoadLines`); `$7C34` (`Speed+1`); `$9140` (`LateralX+1`) |
| Writes | `$5CEA` (`JumpHeight+1`); `$5CFE` (`JumpSpeed+1`); `$645F` (`SkidLevel`); `$916E`-`$9175` (`FallTime`, `Wheelies`, `Pose`) |

### `AdvanceTrack` (`$AF2E`)

**Each pass: BikeRoadPlace, then TrackDistance += ScrollStep; the elements passed (TrackStep); the segment's progress, and the next segment when it ends**

SegmentLeft counts down by ScrollStep; its high byte's change is RowsScrolled (ScrollBends). At the segment's end: SegmentLeft = the segment's length (`$AF81`: the segment byte's bits 6-7 + `$80`, in 256 units), and in a demo DemoMode - 1 (at 0 the demo ends: DemoEnd).

Witness: L1 5203 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 253,914 t-states own (0.02 %) |
| Runs (the other recordings) | 4,418 calls (`stage1/rec/stages` 1,795, `stage1/rec/crash` 577, `stage1/rec/m128` 577 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `TrackStep`, `BikeRoadPlace` |
| Reads | `$5E25`-`$5E35` (`SegmentLeft`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 8 more); `$5E80`-`$60D0` (`StageList`, `TrackPatterns`, `Track`); `$6156`-`$6158` (`Track+134`); `$6178`-`$627D` (`Track+168`); `$6298`-`$62F4` (`Track+456`); `$631A`-`$63A4` (`Track+586`); 3 more ranges |
| Writes | `$5E25`-`$5E35` (`SegmentLeft`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 8 more); `$7C30` (`DemoMode`); `$93B7` (`DrawRoadRow+6`); `$94A1` (`l_9495+12`); `$94F5` (`l_94E8+13`); `$9680` (`l_9661+31`); 6 more ranges |

### `DemoEnd` (`$AF91`)

**The demo's segments used up: drop three returns and end the race (RaceEnd), back to the attract loop**

Known only from the code: every recorded demo was ended by a key first.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NextSegment` (`$AF97`)

**Segments + 1, StageListPtr to the next segment; bit 5 of the one passed: the stage's end (StageEnd)**

Witness: L1 257 (c1, crash, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 22 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 235 runs of its first instruction, entered by a jump (`stage1/rec/stages` 141, `stage1/rec/crash` 23, `stage1/rec/m128` 16 and 7 more) |
| Calls | `StageEnd` (tail), `SegmentDecode` (falls into) |

### `SegmentDecode` (`$AFA7`)

**The segment byte: Bend (bits 0-1, the bend), Crest (bits 2-3, the crest), BendDir (bit 4, the bend's side), length (bits 6-7); RoadRowsFlat when the crest was 0, ClearBendRows when the bend was 0**

Witness: L1 270 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 25 calls, 6,816 t-states own (0.00 %) |
| Runs (the other recordings) | 180 calls (`stage1/rec/stages` 142, `stage1/rec/m128` 18, `stage1/rec/twoplayer` 15 and 1 more) |
| Called from | `IntVector` (tail), `StartRace`, `NextSegment` (falls into) |
| Calls | `ClearBendRows`, `RoadRowsFlat`, `SetBendDir` (falls into) |
| Reads | `$5E2B`-`$5E31` (`StageListPtr`, `BendDir`, `BendPrev`, `Bend` and 2 more); `$5E80`-`$5F0B` (`StageList`) |
| Writes | `$5E2D`-`$5E31` (`BendDir`, `BendPrev`, `Bend`, `CrestPrev` and 1 more); `$AF81` (`l_AF80+1`) |

### `SetBendDir` (`$AFE0`)

**The bend's side into eight branch opcodes: JR NZ (`$20`) or JR Z (`$28`) at `$9FAF`, `$93B7`, `$9680`, `$94A1`, `$94F5`, `$9AF5`, `$9B73`, `$9BB5`**

Witness: L1 62 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 11 calls, 1,386 t-states own (0.00 %) |
| Runs (the other recordings) | 47 calls (`stage1/rec/stages` 24, `stage1/rec/m128` 6, `stage1/rec/ctl` 5 and 4 more) |
| Called from | `StartRace`, `SegmentDecode` (falls into) |
| Calls | `BikeRoadPlace` (falls into) |
| Writes | `$93B7` (`DrawRoadRow+6`); `$94A1` (`l_9495+12`); `$94F5` (`l_94E8+13`); `$9680` (`l_9661+31`); `$9AF5` (`l_9AE8+13`); `$9B73` (`l_9B67+12`); 2 more ranges |

### `BikeRoadPlace` (`$AFFE`)

**From LateralX and the bend: patch the road's and the objects' centre into twelve operands, BikeX; OffRoad by stage**

The offset is clamped to +/-`$21` (the rest goes to BikeX's offset); the operands at `$93A0`/`$93A1`, `$9487`/`$9488`, `$94DA`/`$94DB`, `$9ADA`/`$9ADB`, `$9B59`/`$9B5A`, `$9B9D`/`$9B9E` get ADD A,n or SUB n and the offset; `$9F4F` and `$9643` the signed offset. In the air or falling no off-road test.

Witness: L1 5265 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 796 calls, 343,446 t-states own (0.02 %) |
| Runs (the other recordings) | 4,469 calls (`stage1/rec/stages` 1,819, `stage1/rec/m128` 583, `stage1/rec/crash` 580 and 9 more) |
| Called from | `IntVector` (tail), `AdvanceTrack`, `SetBendDir` (falls into) |
| Calls | `OffRoad` (tail), `OffRoadStage5` (tail) |
| Reads | `$5CEA` (`JumpHeight+1`); `$5E2D` (`BendDir`); `$9140` (`LateralX+1`); `$916E` (`FallTime`) |
| Writes | `$645F` (`SkidLevel`); `$9178` (`BikeX`); `$93A0`-`$93A1` (`l_937C+36`); `$9487`-`$9488` (`l_9448+63`); `$94DA`-`$94DB` (`l_94C7+19`); `$9643` (`l_9642+1`); 4 more ranges |

## horizon

`src/game/horizon.asm`

### `RotateRight1` (`$9211`)

**Rotate C lines of the picture at HL right by one pixel (32 bytes a line, the last bit wraps to the first)**

Recorded: c1, stages: in every bend.

Witness: L1 42826 (c1, crash, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 2,880 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,060,235 t-states own (0.14 %) |
| Runs (the other recordings) | 5,466 calls (`stage1/rec/truck` 4,536, `stage1/rec/tech-cheat` 930) |
| Called from | `IntVector` (tail), `HorizonRotate` |
| Reads | `$E2C0`-`$EAFF` (`Dunes`, `Mountains`, `Clouds`) |
| Writes | `$E2C0`-`$EAFF` (`Dunes`, `Mountains`, `Clouds`) |

### `RotateLeft1` (`$923B`)

**Rotate C lines left by one pixel (HL at a line's last byte; the next line 64 bytes on)**

Witness: L1 25206 (c1, crash, fall5, stages, truck).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 2,208 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,622,805 t-states own (0.11 %) |
| Runs (the other recordings) | 216 calls (`stage1/rec/fall5` 216) |
| Called from | `IntVector` (tail), `HorizonRotate` |
| Reads | `$E2C0`-`$EAFF` (`Dunes`, `Mountains`, `Clouds`) |
| Writes | `$E2C0`-`$EAFF` (`Dunes`, `Mountains`, `Clouds`) |

### `RotateRight4` (`$9268`)

**Rotate C lines right by four pixels (RRD along the line, the last nibble wraps)**

Witness: L1 3033 (stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3,033 runs of its first instruction, entered by a jump (`stage1/rec/stages` 3,033) |
| Called from | `HorizonRotate` |
| Reads | `$E5E0`-`$EAFF` (`Mountains`, `Clouds`) |
| Writes | `$E5E0`-`$EAFF` (`Mountains`, `Clouds`) |

### `RotateLeft4` (`$9294`)

**Rotate C lines left by four pixels (RLD)**

Witness: L1 2100 (stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 2,100 runs of its first instruction, entered by a jump (`stage1/rec/stages` 2,100) |
| Called from | `HorizonRotate` |
| Reads | `$E2C0`-`$EAFF` (`Dunes`, `Mountains`, `Clouds`) |
| Writes | `$E2C0`-`$EAFF` (`Dunes`, `Mountains`, `Clouds`) |

### `RotateBytesRight` (`$92C0`)

**Rotate C lines right by whole bytes**

Known only from the code: a step of 8 pixels in one pass never happened (the bend's push stays below it).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RotateBytesLeft` (`$92ED`)

**Rotate C lines left by whole bytes**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HorizonScrollStep` (`$99F0`)

**HorizonScroll += HorizonSpeed / 2; rotate the picture by the whole pixels gained, right or left**

HorizonSpeed is the LD DE operand (`$99F1`) BikeLateral writes (the bend and the speed). The pixels: 8 at a time (RotateBytes, never), then 4 (RotateRight4 / RotateLeft4), then 1, through RotateTable's entries (offset, routine).

Recorded: c1: each pass in a bend.

Witness: L1 5182 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `HorizonScrollStep` at work](img/routines/HorizonScrollStep.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 779 calls, 152,866 t-states own (0.01 %) |
| Runs (the other recordings) | 4,403 calls (`stage1/rec/stages` 1,789, `stage1/rec/crash` 575, `stage1/rec/m128` 575 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Reads | `$5CEF`-`$5CF4` (`HorizonAddr`, `HorizonRows`, `HorizonTop`, `HorizonScroll`); `$9A82`-`$9A8E` (`RotateTable+3`) |
| Writes | `$5CF3`-`$5CF4` (`HorizonScroll`) |

### `HorizonBytes` (`$9A18`)

**Steps of 8 pixels: RotateBytes for C lines (C * 31 bytes)**

Known only from the code.

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `HorizonRotate` |

### `HorizonRotate` (`$9A74`)

**JP to the routine of RotateTable's entry IY (HL = HorizonAddr + the entry's offset)**

Witness: L1 3230 (c1, crash, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 159 calls, 11,289 t-states own (0.00 %) |
| Runs (the other recordings) | 3,071 calls (`stage1/rec/stages` 2,369, `stage1/rec/truck` 228, `stage1/rec/crash` 165 and 7 more) |
| Called from | `HorizonBytes` |
| Calls | `RotateRight1`, `RotateLeft1`, `RotateRight4`, `RotateLeft4` |
| Reads | `$9A83`-`$9A90` (`RotateTable+4`) |

### `SetHorizon` (`$9E3A`)

**HorizonAddr, HorizonRows, HorizonTop from StageTable[Stage]; the clear count `$C0` - rows - top**

Witness: L1 54 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 16 calls, 3,763 t-states own (0.00 %) |
| Runs (the other recordings) | 38 calls (`stage1/rec/ctl` 10, `stage1/rec/stages` 8, `stage1/rec/m128` 8 and 4 more) |
| Called from | `StartRace` |
| Calls | `Multiply` |
| Reads | `$5E23` (`Stage`); `$9E67`-`$9E7A` (`StageTable`) |
| Writes | `$5CEF`-`$5CF2` (`HorizonAddr`, `HorizonRows`, `HorizonTop`); `$9EE5` (`l_9E9F+70`) |

### `DrawHorizon` (`$9E7B`)

**From TopClip: draw the horizon's lines into the back buffer and clear the lines above it**

Witness: L1 5137 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `DrawHorizon` at work](img/routines/DrawHorizon.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 776 calls, 10,088 t-states own (0.00 %) |
| Runs (the other recordings) | 4,362 calls (`stage1/rec/stages` 1,786, `stage1/rec/crash` 573, `stage1/rec/m128` 572 and 9 more) |
| Called from | `IntVector` (tail), `HudPlayer` |
| Calls | `DrawHorizonAt` (falls into) |
| Reads | `$5CEF`-`$5CF2` (`HorizonAddr`, `HorizonRows`, `HorizonTop`); `$916C` (`TopClip`) |
| Writes | `$7C38`-`$7C39` (`SavedSp`); `$FE9E`-`$FE9F` (`RowTable+158`) |

### `DrawHorizonAt` (`$9E7E`)

**from line A (StartRace: 40)**

Witness: L1 5162 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 784 calls, 94,097 t-states own (0.01 %) |
| Runs (the other recordings) | 3,817 calls (`stage1/rec/stages` 1,788, `stage1/rec/m128` 576, `stage1/rec/crash` 574 and 4 more) |
| Called from | `DrawHorizon` (falls into), `StartRace` |
| Reads | `$5CF2` (`HorizonTop`) |
| Writes | `$7C38`-`$7C39` (`SavedSp`); `$FE80`-`$FE81` (`RowTable+128`); `$FE9E`-`$FE9F` (`RowTable+158`) |

### `HorizonHidden` (`$9E86`)

**TopClip below the picture's top line: start at HorizonTop, nothing to clear above the picture (B = 0 path)**

Known only from the code: TopClip never went below the picture's top line.

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | run into, not called, 30,169,457 t-states own (2.03 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/stages`, `stage1/rec/m128`, `stage1/rec/crash` and 9 more) |
| Called from | `IntVector` (tail) |
| Reads | `$5CEF`-`$5CF1` (`HorizonAddr`, `HorizonRows`); `$7C38`-`$7C39` (`SavedSp`); `$E2C0`-`$EAFF` (`Dunes`, `Mountains`, `Clouds`); `$FE50`-`$FF7F` (`RowTable+80`) |
| Writes | `$EB1E`-`$EC5F` (`TrackTables+30`); `$EC7E`-`$EC7F` (`TrackTables+382`); `$ECBE`-`$ECBF` (`TrackTables+446`); `$ECFE`-`$ECFF` (`TrackTables+510`); `$ED1E`-`$ED1F` (`TrackTables+542`); `$ED3E`-`$ED3F` (`TrackTables+574`); 9 more ranges |

## road

`src/game/road.asm`

### `DrawRoad` (`$931E`)

**Draw the rows of RowList: both edges of each row into the back buffer, SP walking RowTable**

GapRowsJump first (GapRows: stage 3's gap rows become `$FE` in RowList); Multiply's RET patched to JP DrawRoadRow; SP = `$FEE0` + 2 * RoadTopRow (RowTable from line `$70` + RoadTopRow). Per entry: `$FF` ends, `$FE` skips a line (the gap), else the row's depth picks the edge pattern set and the width (RowScale), Multiply gives the hill's and the curve's shift, the left edge's 3 bytes are written (LDI, or LDDR clipped at the left), then the right edge's. Runs of equal entries (a row stretched over several lines) go to DrawRoadRun. At the end MultiplyEnd is RET again and SP restored.

Recorded: c1: every pass; the heaviest passes' largest cost.

Witness: L1 4740 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `DrawRoad` at work](img/routines/DrawRoad.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 38,234,201 t-states own (2.57 %) |
| Runs (the other recordings) | 3,955 calls (`stage1/rec/stages` 1,382, `stage1/rec/m128` 577, `stage1/rec/crash` 576 and 8 more) |
| Called from | `IntVector` (tail), `Multiply` (tail), `DrawRoadRunLine` (tail), `RacePass` |
| Calls | `Divide`, `Multiply`, `DrawRoadRunLine` (falls into), `GapRowsJump` |
| Reads | `$5B00`-`$5B49` (`Mover`, `MoverTail`, `RowListTail`); `$5B80`-`$5BFE` (`BendRows`); `$5CE7`-`$5CE8` (`SavedSp2`); `$5E26` (`SegmentLeft+1`); `$7898`-`$79E7` (`EdgePatterns+24`); `$7A98`-`$7BE7` (`EdgePatterns2+24`); 5 more ranges |
| Writes | `$5CE7`-`$5CE8` (`SavedSp2`); `$7C38`-`$7C52` (`SavedSp`, `InGap`, `ScoreDigits`, `RunLines`); `$8BEA`-`$8BEC` (`MultiplyEnd`, `MultiplyJump`); `$9371` (`l_9366+11`); `$93C1`-`$93CF` (`l_93BB+6`); `$93FA`-`$93FC` (`DrawRoadRight+1`); 6 more ranges |

### `DrawRoadRunLine` (`$9563`)

**One line of a run: the left edge, the right edge at the interpolated x, then the slopes added**

Witness: L1 142770 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 25,191 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 11,582,379 t-states own (0.78 %) |
| Runs (the other recordings) | 18,129 calls (`stage1/rec/crash` 18,129) |
| Called from | `IntVector` (tail), `DrawRoad` (falls into) |
| Calls | `DrawRoad` (tail) |
| Reads | `$78F8`-`$79E7` (`EdgePatterns+120`); `$7AF8`-`$7BE7` (`EdgePatterns2+120`); `$7C46`-`$7C52` (`RunLines`); `$93CE`-`$93CF` (`l_93BB+19`) |
| Writes | `$7C46`-`$7C4C` (`RunLines`); `$9562` (`RoadRunOp`); `$F620`-`$FDDF` (`BackBuffer+96`); `$FF06`-`$FF75` (`RowTable+262`) |

### `DrawRoadRunOff` (`$9601`)

**A run whose row is off the table: SP past its lines, MultiplyEnd = JP again, on to DrawRoadNext**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoadRowsJump` (`$999A`)

**Stage 3's row builder: in the air every row's line is `$70` + depth * (`$80` - JumpHeight) / 256; on the ground RoadRowsFlat**

In a fall (FallTime) nothing changes. Out: RoadLines, then RoadRowsMake. With JumpHeight near `$80` every row is `$70` (RoadTopRow `$FF`: the reset).

Recorded: stages, reset3: stage 3's jumps; reset3 frame 6758: JumpHeight `$76`, RoadLines all `$70`, RoadTopRow `$FF`.

Witness: L1 503 (stages, truck).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 503 calls (`stage1/rec/stages` 305, `stage1/rec/truck` 198) |
| Called from | `RacePass` |
| Calls | `RoadJumpRows` (tail), `RoadRowsFlat` (tail) |
| Reads | `$5CEA` (`JumpHeight+1`); `$7800`-`$787F` (`Perspective`); `$916E` (`FallTime`) |
| Writes | `$5C00`-`$5C7F` (`RoadLines`); `$99D9`-`$99E2` (`RoadJumpRows+1`) |

### `RoadJumpGround` (`$99C2`)

**JumpHeight 0 inside the jump path: lines from `$79` down**

Known only from the code: the path is entered only with JumpHeight nonzero, so it is unreachable.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoadJumpRows` (`$99D8`)

**Each row: perspective * n >> 8, + `$70` (n the LD A operand, `$80` - JumpHeight)**

Witness: L1 14080 (stages, truck).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3,969 calls (`stage1/rec/truck` 3,969) |
| Called from | `IntVector` (tail), `RoadRowsJump` (tail) |
| Calls | `Multiply`, `RoadRowsFlat` (tail) |
| Reads | `$7800`-`$787F` (`Perspective`) |
| Writes | `$5C00`-`$5C7F` (`RoadLines`) |

### `RoadNone` (`$9A91`)

**Stage 5's road routine: IX = RowList, no drawing**

Recorded: stages: stage 5.

Witness: L1 456 (fall5, stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 456 calls (`stage1/rec/stages` 408, `stage1/rec/fall5` 48) |
| Called from | `RacePass` |

### `RoadRowsOld` (`$9A96`)

**A row builder no stage uses: rows into the line buffer at `$8000`, edges from `$75B0`**

537 bytes. It sets MultiplyEnd = RET, fills the buffer with per-line x positions (Divide's slopes, like DrawRoadRun) and draws from it with IX = `$75B0`. No StageParams entry and no instruction points at it. Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RoadRowsCrest` (`$9CB7`)

**Stages 1, 2, 4 and 5's row builder: RoadLines from the perspective and the crest, as the segment goes by**

Crest 0 with CrestPrev 0: RoadRowsMake on the last lines; otherwise, for crests 1-3, entering (CrestPrev 0) or leaving, the rows over the segment's progress (SegmentLeft) get `$70` + (perspective * crest table) / 512, the rest the plain perspective.

Recorded: c1: every pass.

Witness: L1 4695 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 2,921,518 t-states own (0.20 %) |
| Runs (the other recordings) | 3,910 calls (`stage1/rec/stages` 1,485, `stage1/rec/m128` 577, `stage1/rec/crash` 577 and 8 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `Multiply`, `RoadRowsFlat` (tail) |
| Reads | `$5E26`-`$5E31` (`SegmentLeft+1`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 5 more); `$7800`-`$787F` (`Perspective`); `$7A00`-`$7A7F` (`CrestTable`) |
| Writes | `$5C00`-`$5C7F` (`RoadLines`) |

### `RoadRowsFlat` (`$9DDF`)

**RoadLines = `$70` + perspective / 2 for all 128 rows**

Witness: L1 568 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 25 calls, 7,181,544 t-states own (0.48 %) |
| Runs (the other recordings) | 543 calls (`stage1/rec/stages` 317, `stage1/rec/truck` 156, `stage1/rec/crash` 16 and 8 more) |
| Called from | `IntVector` (tail), `RoadRowsJump` (tail), `RoadJumpRows` (tail), `RoadRowsCrest` (tail), `StartRace`, `SegmentDecode` |
| Reads | `$5C01`-`$5C7F` (`RoadLines+1`); `$5E23`-`$5E30` (`Stage`, `Countdown`, `SegmentLeft`, `TrackPtr` and 6 more); `$7800`-`$787F` (`Perspective`) |
| Writes | `$5B00`-`$5B4E` (`Mover`, `MoverTail`, `RowListTail`); `$5C00`-`$5C7F` (`RoadLines`); `$9177` (`RoadTopRow`) |

### `GroundTexture` (`$A301`)

**Stages 3 and 5: the ground's dots, a ROM byte XOR the column as the random x, masks from DotMasks; many tries per row; on stage 5 dots and 8-pixel dashes; about 140 000 T (2 frames) a pass**

RandomPtr (`$A45B`) walks the ROM `$0000-$1FFF` by 4 * ScrollStep's high byte each pass; for each line of RowList a band, centre (`$80` + BendRows scaled) -/+ half the byte at `$7F80` + row: stage 3 puts a dot inside the band (between the road's edges), nothing outside; stage 5 draws only left of the band, a dot within half a band-width of its left edge, an 8-pixel dash further out.

Recorded: stages: stages 3 and 5.

Witness: L1 5195 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `GroundTexture` at work](img/routines/GroundTexture.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 49,308 t-states own (0.00 %) |
| Runs (the other recordings) | 4,410 calls (`stage1/rec/stages` 1,789, `stage1/rec/m128` 577, `stage1/rec/crash` 576 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `Divide`, `Multiply` |
| Reads | `$5B00`-`$5B4E` (`Mover`, `MoverTail`, `RowListTail`); `$5B81`-`$5BFE` (`BendRows+1`); `$5E23`-`$5E2D` (`Stage`, `Countdown`, `SegmentLeft`, `TrackPtr` and 3 more); `$7F01`-`$7FFE` (`RowScale+1`); `$9137` (`ScrollStep+1`); `$9177` (`RoadTopRow`); 12 more ranges |
| Writes | `$A399`-`$A39A` (`l_A353+70`); `$A3B4`-`$A3BE` (`l_A3A7+13`, `l_A3B8`); `$A3D0`-`$A3DD` (`l_A3CF+1`); `$A419` (`l_A418+1`); `$A42B`-`$A42C` (`l_A424+7`); `$A45B`-`$A45C` (`RandomPtr`); 2 more ranges |

### `ScrollBends` (`$B07D`)

**As the segment moves (RowsScrolled), shift BendRows down and fill from the bend's profile (BendProfiles)**

Witness: L1 5198 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 261,250 t-states own (0.02 %) |
| Runs (the other recordings) | 4,413 calls (`stage1/rec/stages` 1,790, `stage1/rec/crash` 577, `stage1/rec/m128` 577 and 9 more) |
| Called from | `IntVector` (tail), `RacePass` |
| Calls | `BlendBend` (tail) |
| Reads | `$5B80`-`$5BFF` (`BendRows`); `$5E26`-`$5E2F` (`SegmentLeft+1`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 3 more); `$75D9`-`$75E9` (`BendBlend+2`); `$7D80`-`$7EFD` (`BendProfiles`); `$9138`-`$9139` (`BendPtr`); `$AF81` (`l_AF80+1`); 1 more ranges |
| Writes | `$5B81`-`$5BFF` (`BendRows+1`); `$9138`-`$9139` (`BendPtr`) |

### `ScrollBendsTail` (`$B0C9`)

**The profile's end reached inside the copy: the rest from BlendBend's start**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BlendBend` (`$B0D1`)

**Bend 0 after a bend: BendRows blended back to straight, the profile's step from BendBlend (`$75D7`)**

Witness: L1 1756 (c1, crash, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 218 calls, 365,326 t-states own (0.02 %) |
| Runs (the other recordings) | 522 calls (`stage1/rec/crash` 174, `stage1/rec/m128` 154, `stage1/rec/truck` 119 and 2 more) |
| Called from | `StartRace`, `ScrollBends` (tail) |
| Reads | `$5B80`-`$5BFF` (`BendRows`); `$5E26`-`$5E2F` (`SegmentLeft+1`, `TrackPtr`, `TrackDistance`, `StageListPtr` and 3 more); `$75D9`-`$75E8` (`BendBlend+2`) |
| Writes | `$5B81`-`$5BFF` (`BendRows+1`) |

### `BlendCarry` (`$B0FB`)

**INC H: BendBlend's index crossing a page (not met)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

## race

`src/game/race.asm`

### `CountGlyph` (`$A143`)

**Draw an 8-line glyph at HL as attribute blocks (`$52`) at DE (C lines: CountGlyphC)**

Witness: L1 32 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 2 calls, 14 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/rec/ctl` 10, `stage1/rec/twoplayer` 4, `stage1/rec/crash` 2 and 7 more) |
| Called from | `StartRace` |
| Calls | `CountGlyphC` (falls into) |

### `CountGlyphC` (`$A145`)

**The same with C preset (the digits' 10 lines)**

Witness: L1 616 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 5 calls, 20,612 t-states own (0.00 %) |
| Runs (the other recordings) | 447 calls (`stage1/rec/ctl` 230, `stage1/rec/stages` 46, `stage1/rec/crash` 26 and 7 more) |
| Called from | `IntVector` (tail), `CountGlyph` (falls into), `StartRace` |
| Reads | `$7C00`-`$7C2D` (`CountGlyphs`) |
| Writes | `$590D`-`$5912` (screen); `$5929`-`$59F7` (screen); `$5A09`-`$5A33` (screen); `$7C00`-`$7C2D` (`CountGlyphs`) |

### `AyPairs` (`$A167`)

**Write E AY pairs from HL (as AyWrite, ports loaded each time)**

Witness: L1 1580 (c1, crash, fall5, m128, stages, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 9 calls, 3,915 t-states own (0.00 %) |
| Runs (the other recordings) | 307 calls (`stage1/rec/stages` 229, `stage1/rec/truck` 43, `stage1/rec/crash` 12 and 5 more) |
| Called from | `PlayEffect` |
| Reads | `$A15D`-`$A166` (`AyEffect`) |
| Ports out | `$BFFD`, `$FFFD` |

### `PlayEffect` (`$A179`)

**EffectTime = A (1 a fall, 2 a bounce or a landing), and the AY's noise on through AyEffect**

On the 48K the AY writes reach nothing; the 48K hears CrashSound instead.

Witness: L1 316 (c1, crash, fall5, m128, stages, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 9 calls, 596 t-states own (0.00 %) |
| Runs (the other recordings) | 307 calls (`stage1/rec/stages` 229, `stage1/rec/truck` 43, `stage1/rec/crash` 12 and 5 more) |
| Called from | `RacePass`, `RampSpeed`, `RiderBounce` |
| Calls | `AyPairs` |
| Writes | `$6462` (`EffectTime`) |

### `StartRace` (`$A45D`)

**A stage's start: RowTable to the back buffer, the horizon, the riders (a new turn), StageParams, the ground, the first segment**

EffectTime 0 / EffectStep 15; flags cleared; pose 3; SetHorizon, DrawHorizonAt 40. A demo or a new turn (Countdown nonzero): the riders cleared and set from RiderStarts (rider 4 from stage 2, rider 5 from stage 4, both in the demo); StageStart: TimerAtStart. Then StageParams patch the row builder's and the road's CALLs and the off-road JP, the HUD row's attributes `$68` and the ground's (not stage 5); SplashOn and BendOp on stages 2 and 4; ClearBendRows, RoadRowsFlat, the first segment (SetBendDir, then SegmentDecode or, resuming, LateralX from FallX); the bend rows of a segment begun mid-bend.

Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 8 calls, 771,420 t-states own (0.05 %) |
| Runs (the other recordings) | 17 calls (`stage1/rec/ctl` 5, `stage1/rec/m128` 4, `stage1/rec/twoplayer` 3 and 4 more) |
| Called from | `IntVector` (tail), `GameEntryJump` (tail), `HudPlayer` (tail), `RaceQuit` (tail), `StageEnd` (tail) |
| Calls | `Multiply`, `SetRowTable`, `ClearBendRows`, `RoadRowsFlat`, `SetHorizon`, `DrawHorizonAt`, `CountGlyph`, `CountGlyphC`, `SetTune`, `SegmentDecode`, `SetBendDir`, `BlendBend` |
| Reads | `$58A0`-`$5AFE` (screen); `$5C80`-`$5CD8` (`Riders`); `$5CF2`-`$5CFF` (`HorizonTop`, `HorizonScroll`, `JumpRows`, `JumpRowPtr` and 3 more); `$5E1F`-`$5E43` (`Timer`, `Tenths`, `TimerAtStart`, `Stage` and 15 more); `$5E80`-`$5EA0` (`StageList`); `$5EB7`-`$5ED1` (`StageList+55`); 7 more ranges |
| Writes | `$58A0`-`$5AFF` (screen); `$5B80`-`$5BFF` (`BendRows`); `$5C80`-`$5CFF` (`Riders`, `DrawStack`, `SavedSp2`, `JumpHeight` and 9 more); `$5E21`-`$5E34` (`TimerAtStart`, `Stage`, `Countdown`, `SegmentLeft` and 10 more); `$645F`-`$6463` (`SkidLevel`, `TuneMark`, `TuneRequest`, `EffectTime` and 1 more); `$7C2E`-`$7C3E` (`PassCount`, `Beeper`, `DemoMode`, `GetUp` and 6 more); 12 more ranges |
| Ports in | `$FBFE`, `$FEFE` |

### `CheatKey` (`$A659`)

**CAPS SHIFT and Q: toggle CheatStep on every pass both read down (a fixed ScrollStep of `$1000` on stages 1-3)**

A step of `$1000` is SPEED 293, faster than the throttle gives; it also makes BikeControl read SteerTable at `$8E7D`, past its end, and BikeLateralPush push with `$10`. The recording tech-cheat holds CAPS SHIFT + Q at frame 126.

Witness: L1 1 (tech-cheat).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/tech-cheat` 1) |

### `RaceStep` (`$A667`)

**ScrollStep = SPEED * 14 (CheatStep: `$1000`)**

Witness: L1 5203 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,418 runs of its first instruction, entered by a jump (`stage1/rec/stages` 1,795, `stage1/rec/crash` 577, `stage1/rec/m128` 577 and 9 more) |
| Calls | `Multiply` |

### `CheatFixedStep` (`$A674`)

**Stages 1-3 with CheatStep: DE = `$1000`**

Witness: L1 51 (tech-cheat).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 51 runs of its first instruction, entered by a jump (`stage1/rec/tech-cheat` 51) |

### `RacePass` (`$A67E`)

**ScrollStep stored; AyEffectTick, AdvanceTrack, ScrollBends, the row builder, the road, GroundTexture, MoveRiders, DrawRiders, the bike, dust, splash, horizon, BikeHitX**

Witness: L1 5203 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 4,648,559 t-states own (0.31 %) |
| Runs (the other recordings) | 4,418 runs of its first instruction, entered by a jump (`stage1/rec/stages` 1,795, `stage1/rec/crash` 577, `stage1/rec/m128` 577 and 9 more) |
| Called from | `IntVector` (tail), `RampSpeed` (tail) |
| Calls | `Multiply`, `DrawRoad`, `DrawRiders`, `RoadRowsJump`, `HorizonScrollStep`, `RoadNone`, `RoadRowsCrest`, `DrawObject`, `DrawBike`, `DrawSplash`, `DrawDust`, `PlayEffect`, `MoveRiders`, `GroundTexture`, `RampSpeed` (tail), `TrackStep`, `CrashSound`, `AyEffectTick`, `BikeControl`, `Crash`, `AdvanceTrack`, `ScrollBends` |
| Reads | `$5C00` (`RoadLines`); `$5CEA`-`$5CFC` (`JumpHeight+1`, `HorizonAddr`, `HorizonRows`, `HorizonTop` and 4 more); `$5E27`-`$5E43` (`TrackPtr`, `TrackDistance`, `StageListPtr`, `BendDir` and 9 more); `$5F10`-`$60D1` (`TrackPatterns+4`, `Track`); `$6156`-`$6159` (`Track+134`); `$6178`-`$61EE` (`Track+168`); 9 more ranges |
| Writes | `$5CDA`-`$5CFE` (`DrawStack`, `SavedSp2`, `JumpHeight`, `HorizonAddr` and 7 more); `$5E33`-`$5E34` (`GapMarks`); `$7C34` (`Speed+1`); `$9175` (`Pose`); `$A1C9`-`$A1CB` (`BounceTime`, `BounceDir`, `BikeHitX`) |

### `RampCap` (`$A808`)

**Wheelies capped at 8**

The recording tech-ramp-wheelie holds WHEELIE 13 passes before the ramp at its frame 1 412.

Witness: L1 1 (tech-ramp-wheelie).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/tech-ramp-wheelie` 1) |

### `RampSpeed` (`$A80A`)

**SPEED * (8 * Wheelies - `$40` + 256) / 256 (8 or more: unchanged), JumpSpeed, PrintSpeed, PlayEffect 2, CrashSound**

Witness: L1 19 (c1, crash, m128, stages, tech-land-wheelie, tech-ramp-wheelie, truck).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,257,734 t-states own (0.08 %) |
| Runs (the other recordings) | 18 runs of its first instruction, entered by a jump (`stage1/rec/stages` 12, `stage1/rec/truck` 2, `stage1/rec/crash` 1 and 3 more) |
| Called from | `IntVector` (tail), `RacePass` (tail), `RiderBounce` (tail) |
| Calls | `Multiply`, `PlayEffect`, `RacePass` (tail), `RiderBounce` (tail), `PrintSpeed`, `CrashSoundD`, `AyEffectTick` |
| Reads | `$5C80`-`$5CD7` (`Riders`); `$5CEA`-`$5CF2` (`JumpHeight+1`, `HorizonAddr`, `HorizonRows`, `HorizonTop`); `$5E0D` (`Player`); `$5E1F`-`$5E24` (`Timer`, `Tenths`, `TimerAtStart`, `Stage` and 1 more); `$7C2E`-`$7C41` (`PassCount`, `Beeper`, `DemoMode`, `GetUp` and 6 more); `$7C53` (`ExtendedTime`); 3 more ranges |
| Writes | `$5E1F`-`$5E20` (`Timer`, `Tenths`); `$5E36` (`VarObject`); `$6461` (`TuneRequest`); `$7C33`-`$7C42` (`Speed`, `TotalTime`, `SavedSp`, `InGap` and 1 more); `$7C53` (`ExtendedTime`); `$916C`-`$916D` (`TopClip`, `DrawnTop`); 2 more ranges |

### `TruckCrash` (`$A88F`)

**A truck head-on: Crash**

The trucks met in stages and reset3 were under the Immune To Trucks POKE, which turns this CALL into LD BC,nn (POKE 43151,1); the recording truck puts the byte back and meets a truck head-on at its frame 1 240.

Witness: L1 5 (stages, truck).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 5 runs of its first instruction, entered by a jump (`stage1/rec/stages` 4, `stage1/rec/truck` 1) |
| Calls | `Crash` |

### `RiderBounce` (`$A892`)

**JR to the HUD**

Witness: L1 5 (stages, truck).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 5 runs of its first instruction, entered by a jump (`stage1/rec/stages` 4, `stage1/rec/truck` 1) |
| Called from | `IntVector` (tail), `RampSpeed` (tail) |
| Calls | `PrintString`, `PlayEffect`, `RampSpeed` (tail), `HudPlayer` (tail), `CrashSound` |
| Reads | `$5CEA`-`$5CF2` (`JumpHeight+1`, `HorizonAddr`, `HorizonRows`, `HorizonTop`); `$5E1F`-`$5E24` (`Timer`, `Tenths`, `TimerAtStart`, `Stage` and 1 more); `$7C2E`-`$7C41` (`PassCount`, `Beeper`, `DemoMode`, `GetUp` and 6 more); `$7C53` (`ExtendedTime`); `$916C`-`$9176` (`TopClip`, `DrawnTop`, `FallTime`, `Wheelies` and 2 more); `$A1C9` (`BounceTime`) |
| Writes | `$5E1F`-`$5E20` (`Timer`, `Tenths`); `$6461` (`TuneRequest`); `$7C33`-`$7C42` (`Speed`, `TotalTime`, `SavedSp`, `InGap` and 1 more); `$7C53` (`ExtendedTime`); `$916C`-`$916D` (`TopClip`, `DrawnTop`); `$AD8B` (`HeldKeys+1`) |

### `HudPlayer` (`$A8DA`)

**Two players: PlayerChar, U, P (the font's own glyphs for "UP")**

Witness: L1 2433 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 329 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,104 runs of its first instruction, entered by a jump (`stage1/rec/stages` 867, `stage1/rec/crash` 288, `stage1/rec/m128` 227 and 9 more) |
| Called from | `IntVector` (tail), `RiderBounce` (tail) |
| Calls | `PrintString`, `PrintGlyph`, `KeyOrFire`, `ReadControls`, `AddScore`, `CopyBuffer`, `DrawHorizon`, `StartRace` (tail), `BeepTone` |
| Reads | `$5CEA`-`$5CF2` (`JumpHeight+1`, `HorizonAddr`, `HorizonRows`, `HorizonTop`); `$5E1F`-`$5E24` (`Timer`, `Tenths`, `TimerAtStart`, `Stage` and 1 more); `$7C30`-`$7C41` (`DemoMode`, `GetUp`, `Players`, `Speed` and 4 more); `$7C53` (`ExtendedTime`); `$916C`-`$9176` (`TopClip`, `DrawnTop`, `FallTime`, `Wheelies` and 2 more); `$A1C9` (`BounceTime`) |
| Writes | `$5E1F`-`$5E20` (`Timer`, `Tenths`); `$6461` (`TuneRequest`); `$7C33`-`$7C42` (`Speed`, `TotalTime`, `SavedSp`, `InGap` and 1 more); `$916C`-`$916D` (`TopClip`, `DrawnTop`); `$AD8B` (`HeldKeys+1`) |

### `RaceQuit` (`$A9C3`)

**A key in the demo or RESET: RaceEnd, then Menu**

Witness: L1 3 (c1, ctl, m128).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 102 t-states own (0.00 %) |
| Runs (the other recordings) | 2 runs of its first instruction, entered by a jump (`stage1/rec/ctl` 1, `stage1/rec/m128` 1) |
| Called from | `IntVector` (tail), `BikeControl` (tail) |
| Calls | `Menu` (tail), `PrintTimer`, `GetKey`, `Multiply`, `StartRace` (tail), `RaceEnd`, `PrintSpeed`, `SetTune`, `StageTime` |
| Reads | `$5CEA` (`JumpHeight+1`); `$5E1F`-`$5E20` (`Timer`, `Tenths`); `$7C30` (`DemoMode`); `$9175`-`$9176` (`Pose`, `Lean`); `$A1C9` (`BounceTime`) |
| Writes | `$5E1F`-`$5E20` (`Timer`, `Tenths`); `$6461` (`TuneRequest`); `$7C33`-`$7C34` (`Speed`) |

### `RaceEnd` (`$AAA1`)

**TuneRequest 0, RowTable back to the screen (SetRowTable `$5A00`)**

Witness: L1 23 (c1, crash, ctl, fall5, m128, names, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 1 call, 263 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/rec/ctl` 6, `stage1/rec/m128` 1) |
| Called from | `RaceQuit` |
| Calls | `SetRowTable` (tail) |
| Writes | `$6461` (`TuneRequest`) |

### `PrintSpeed` (`$AAAB`)

**SPEED in decimal at column 27, line 24 (a blank before 2 and 1 digits)**

Witness: L1 4950 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 722 calls, 79,539 t-states own (0.01 %) |
| Runs (the other recordings) | 4,228 calls (`stage1/rec/stages` 1,761, `stage1/rec/crash` 562, `stage1/rec/m128` 544 and 9 more) |
| Called from | `RampSpeed`, `RaceQuit` |
| Calls | `PrintGlyph`, `PrintNumber` (tail) |
| Reads | `$7C34` (`Speed+1`) |

### `SetTune` (`$AAC9`)

**TuneRequest = (Stage AND 1) + 1: tune 1 on stages 1, 3, 5, tune 2 on 2 and 4**

Witness: L1 34 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 9 calls, 431 t-states own (0.00 %) |
| Runs (the other recordings) | 25 calls (`stage1/rec/stages` 6, `stage1/rec/ctl` 5, `stage1/rec/m128` 4 and 8 more) |
| Called from | `StartRace`, `RaceQuit` |
| Reads | `$5E23` (`Stage`) |
| Writes | `$6461` (`TuneRequest`) |

### `StageTime` (`$AAD3`)

**The stage's time into StageTimes: TimerAtStart - Timer seconds, and the tenths with PassCount's last digit as hundredths**

The seconds are the timer's (10 passes each), so a "time" is in timer seconds; the hundredths digit is PassCount's units (BCD), a filler.

Witness: L1 19 (c1, crash, fall5, m128, names, stages, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 6 calls, 1,382 t-states own (0.00 %) |
| Runs (the other recordings) | 13 calls (`stage1/rec/stages` 5, `stage1/rec/twoplayer` 2, `stage1/rec/m128` 2 and 4 more) |
| Called from | `RaceQuit`, `StageEnd` |
| Reads | `$5E1F`-`$5E23` (`Timer`, `Tenths`, `TimerAtStart`, `Stage`); `$7C2E` (`PassCount`) |
| Writes | `$5E0E`-`$5E17` (`StageTimes`) |

### `StageEnd` (`$AB0A`)

**The stage's last segment passed: the time bonus (the timer's tens and units as the 100 000s and 10 000s digits: 10 000 points a second left, plus the last pass's speed points still in ScoreDigits+3..+6), StageTime, Stage + 1; the finish after stage 5**

Reached by NextSegment's JP NZ with its return address on the stack (POP HL). Stages 1-4: the big stage digit, ExtendedTime 32, Timer + 50 (at most 99), StageStart. After stage 5: SPEED 0, the rider of 0-3 with the largest row byte (unsigned: a rider just behind the bike, row `$FF`, beats one ahead) is put on row 0 at the bike's x with speed and top 2 (FinishRider) and the run goes on to FinishCheck.

Recorded: stages (frames 3422, 5340, 7806, 10272, the finish 13012), reset3 (stages 2 and 3).

Witness: L1 5 (stages).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 5 calls (`stage1/rec/stages` 5) |
| Called from | `NextSegment` (tail) |
| Calls | `PrintTimer`, `BigDigit`, `AddScore`, `FormatTime`, `StartRace` (tail), `StageTime` |
| Reads | `$5C84`-`$5CB1` (`Riders+4`); `$5E1F`-`$5E23` (`Timer`, `Tenths`, `TimerAtStart`, `Stage`); `$9140` (`LateralX+1`) |
| Writes | `$5C82`-`$5C8C` (`Riders+2`); `$5E1F`-`$5E23` (`Timer`, `Tenths`, `TimerAtStart`, `Stage`); `$5E35` (`Segments`); `$7C34`-`$7C3E` (`Speed+1`, `TotalTime`, `SavedSp`, `InGap` and 1 more); `$7C53` (`ExtendedTime`); `$A963`-`$A964` (`FinishRider+2`) |

### `BeepTone` (`$AB95`)

**D edges on the beeper, E loop turns apart (the countdown, EXTENDED PLAY)**

Witness: L1 73 (c1, crash, ctl, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 4 calls, 947,437 t-states own (0.06 %) |
| Runs (the other recordings) | 69 calls (`stage1/rec/ctl` 20, `stage1/rec/stages` 16, `stage1/rec/twoplayer` 8 and 8 more) |
| Called from | `IntVector` (tail), `HudPlayer` |
| Ports out | `$00FE`, `$10FE` |

### `TrackStep` (`$ABA1`)

**Step HL to the track's next element and run the commands before it: marks, pattern calls and returns, jumps, the variable object**

HL is a track pointer, IX a track stack (TrackStack for the bike, the drawing walk's own), B the element's row for the marks. An element byte is a command (high nibble) and a gap (low nibble * 2: the distance from the previous element, in ScrollStep's high-byte units). `$F0`: a gap mark, its row into GapMarks (D, then E; 0 over the gap). `$E0` ADDR, LEN: call the pattern at ADDR (a frame of 6 bytes: return, length, distance done) until LEN distance is driven. `$D0`: return from the pattern (the depth in IX+0). `$C0` d: jump by d (signed) in the track. `$B0`+n: VarObject = 2n. Any other high nibble: an element (its type), and the distance is added to every open pattern's count; a pattern whose count reaches its length returns to its caller from that element, which is not placed: a call covers its elements below its length.

Witness: L1 82250 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

[Animation: `TrackStep` at work](img/routines/TrackStep.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 11,333 calls, 5,104,648 t-states own (0.34 %) |
| Runs (the other recordings) | 70,928 calls (`stage1/rec/stages` 30,625, `stage1/rec/m128` 9,792, `stage1/rec/crash` 9,491 and 9 more) |
| Called from | `IntVector` (tail), `RacePass`, `AdvanceTrack` |
| Reads | `$5CDA`-`$5CE6` (`DrawStack`); `$5E33`-`$5E43` (`GapMarks`, `Segments`, `VarObject`, `TrackStack`); `$5F10`-`$642A` (`TrackPatterns+4`, `Track`); `$7C3A` (`InGap`) |
| Writes | `$5CDA`-`$5CE6` (`DrawStack`); `$5E33`-`$5E43` (`GapMarks`, `Segments`, `VarObject`, `TrackStack`) |

### `CrashSound` (`$AC88`)

**48K only: 248 (or D) noise edges, the ROM's bytes at `$03`xx as bit 4 and the spacing; C set on return**

On the 128K (Beeper 0) it returns at once (NC): RampSpeed's CALL NC,AyEffectTick then steps the AY effect.

Witness: L1 220 (c1, crash, fall5, m128, stages, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 8 calls, 56 t-states own (0.00 %) |
| Runs (the other recordings) | 212 calls (`stage1/rec/stages` 160, `stage1/rec/truck` 21, `stage1/rec/crash` 11 and 5 more) |
| Called from | `RacePass`, `RiderBounce`, `Crash` (tail) |
| Calls | `CrashSoundD` (falls into) |
| Reads | `$7C2F` (`Beeper`) |
| Ports out | `$00FE`, `$10FE` |

### `CrashSoundD` (`$AC8A`)

**D edges**

Witness: L1 239 (c1, crash, fall5, m128, stages, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 9 calls, 1,875,853 t-states own (0.13 %) |
| Runs (the other recordings) | 221 calls (`stage1/rec/stages` 172, `stage1/rec/truck` 23, `stage1/rec/crash` 12 and 3 more) |
| Called from | `IntVector` (tail), `RampSpeed`, `CrashSound` (falls into) |
| Reads | `$7C2F` (`Beeper`) |
| Ports out | `$00FE`, `$10FE` |

### `AyEffectTick` (`$ACA5`)

**The AY effect each pass: EffectStep - 1 into the volumes of channels C, B, A (registers 10-8)**

EffectTime 2 (a bounce, a landing): two steps, then EffectTime 0 and EffectStep 15. EffectTime 1 (a fall): down to 0, then TuneRequest 0 and TuneMark 1: the tune stops until SetTune (the next StartRace or a pause's end).

Witness: L1 5204 (c1, crash, ctl, fall5, m128, names, stages, tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu tour, stage 1 to the time out) | 785 calls, 52,103 t-states own (0.00 %) |
| Runs (the other recordings) | 4,419 calls (`stage1/rec/stages` 1,795, `stage1/rec/m128` 578, `stage1/rec/crash` 577 and 9 more) |
| Called from | `RacePass`, `RampSpeed` |
| Reads | `$6462`-`$6463` (`EffectTime`, `EffectStep`) |
| Writes | `$6460`-`$6463` (`TuneMark`, `TuneRequest`, `EffectTime`, `EffectStep`) |
| Ports out | `$BFFD`, `$FFFD` |


## The first BASIC "enduro" and Stage0 (`src/tape/basic1.json`)

Enduro Racer, Activision 1987: tape block 2, the BASIC program "enduro" (205 bytes at PROG `$5CCB`, LINE 0). Its
entries are `src/tape/<module>.asm`, written from `src/tape/basic1.ann` by `kit/mkgame.py --part
src/tape/basic1.json`; the recordings: `work/stage1/rec/c1` (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy
at signal speed, the menu, stage 1 to the time out).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic1`](#the-first-basic-enduro-and-stage0-basic1) | `$5CCB`-`$5D97` | 2 of 4 |

### The first BASIC "enduro" and Stage0: basic1

`src/tape/basic1-module.asm`

#### `Stage0` (`$5D15`)

**CALL Stage0Copy: its return address is the source of the copy**

Entered by PRINT USR 23829. The CALL pushes `$5D18`, which Stage0Copy POPs as the copy's source.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 call, 31 t-states own (0.00 %) |
| Calls | `Stage0Copy` |

#### `Stage0Copy` (`$5D1A`)

**Copy `$5D18-$5D80` to `$FF98-$FFFF`, set ERR_SP to `$FFFA` and I, return to BASIC**

Obfuscated with IXl/IXh moves and both register sets (known from the code; the result is in the c1 dump at frame 1574). Interrupts off; POP BC' takes `$5D18`; SP = `$FFF8`; RES 4,(IY+1) (FLAGS bit 4, the 128K ROM's mode flag); R = `$A6`, I = `$3F`; ERR_SP (`$5C3D`) = `$FFFA`; the 105 bytes `$5D18-$5D80` go to `$FF98-$FFFF`. The copy leaves `$1B76` (the ROM's STMT-RET) at `$FFF8`, which the RET takes back to the interpreter, and `$1303` (MAIN-4, the error return) at `$FFFA` until the second BASIC pokes VARS there. The interpreter then runs LOAD "" for the second BASIC.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 call, 9,039 t-states own (0.00 %) |
| Called from | `Stage0` |
| Reads | `$5C3B`; `$5D18`-`$5D80` (`Stage0+3`, `Stage0Copy`, `Stage0Data`) |
| Writes | `$5C3B`-`$5C3E`; `$FF98`-`$FFFF` |


## The second BASIC "end2" and Chain1 (`src/tape/basic2.json`)

Enduro Racer, Activision 1987: tape block 4, the BASIC program "end2" (1770 bytes at PROG `$5CCB`, LINE 0), its
variables area the first decoder Chain1 and the enciphered loader. Its entries are `src/tape/<module>.asm`, written
from `src/tape/basic2.ann` by `kit/mkgame.py --part src/tape/basic2.json`; the recordings: `work/stage1/rec/c1` (c1:
a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic2`](#the-second-basic-end2-and-chain1-basic2) | `$5CCB`-`$63B4` | 1 of 9 |

### The second BASIC "end2" and Chain1: basic2

`src/tape/basic2-module.asm`

#### `Chain1` (`$621A`)

**Wipe `$63E0-$FF42`, IM 2, then XOR LoaderTape with R into `$FCA3` and enter it**

Entered from the ROM's error handling through ERR_SP: the word at `$FFFA` is VARS. Real steps between filler: A = I (from Stage0, `$3F`); LDIR clears `$63E0-$FF42` (the RAM the game will use, and any stale loader); IM 2; HL = `$5EFD`, DE = `$FCA3`, BC = 797, `$FCA3` pushed under the loop's own return; R set so that the first LD A,R reads `$CD` (the value the data needs; the count of M1 cycles before it is known only from the code, because the LDIR's length depends on registers the ROM left).

Witness: L1 1 (c1).

[Animation: `Chain1` at work](img/routines/Chain1.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 981,307 t-states own (0.07 %) |
| Reads | `$5EFD`-`$621A` (`LoaderTape`, `Chain1`); `$63B8`-`$FF1A` |
| Writes | `$5EFD`-`$6219` (`LoaderTape`); `$63E0`-`$FFBF`; `$FFFC` |


## The loader: Chain2, Chain3 and the SpeedLock 2 loader (`src/loader/loader.json`)

Enduro Racer, Activision 1987: the loader `$FCA3-$FFBF` as each byte runs (the plain view; tools/speedlock2.py tape
enciphers it into the second BASIC's `$5EFD-$6219`). Its entries are `src/loader/<module>.asm`, written from
`src/loader/loader.ann` by `kit/mkgame.py --part src/loader/loader.json`; the recordings: `work/stage1/rec/c1` (c1:
a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`loader`](#the-loader-chain2-chain3-and-the-speedlock-2-loader-loader) | `$FCA3`-`$FFBF` | 13 of 17 |

### The loader: Chain2, Chain3 and the SpeedLock 2 loader: loader

`src/loader/loader-module.asm`

#### `Chain2` (`$FCA3`)

**Find its own address, then XOR `$FCD1-$FFBF` (751 bytes) with R in place and run into Chain3**

Entered by Chain1's RET. The first nine bytes are filler the decoder keys on (Chain3 reads `$FCA3-$FD2B` as its keys). EX (SP),IY with `$FCD1` pushed leaves the return address +`$2E` in DE and HL: `$FCD1`. BC = 751; A = I sets the parity flag from IFF2 (interrupts off: PO), so the CALL PO,`$3008` into the ROM (EXX / INC E / JR NZ / INC D / EXX / RET) only burns M1 cycles that set R. Chain2Loop is Chain1's loop: LD A,R / XOR (HL) / LD (HL),A / LDI, leaving by RET PO when BC reaches 0 into the next code (the DEC SP pair puts the return address back).

R at the first byte is `$8D`: Chain1's last R plus 40 M1 cycles (tools/speedlock2.py r2_start, checked against the c1 dump at frame 1577 T 5842).

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 50,484 t-states own (0.00 %) |
| Calls | `Chain3` |
| Reads | `$621A`; `$FCD1`-`$FFBF` (`Chain3`, `Crash`, `Edge`, `LoadBlock` and 12 more) |
| Writes | `$FCD1`-`$FFBF` (`Chain3`, `Crash`, `Edge`, `LoadBlock` and 12 more) |

#### `Chain3` (`$FCD1`)

**137 rounds of a running XOR over `$FD2C-$FFBF`, check the sum of `$FF37-$FFBF` and wipe itself**

C = the byte at `$FFBF`, B = 137 rounds, DE = `$FCA3` (the keys: the decoders' own bytes). Each round: A = key - C, then for each of the 660 bytes `$FD2C-$FFBF` A = A XOR byte, byte = A; C = the last A. Then HL = the sum of the 137 bytes from `$FF37`; it must be `$36FE`. The 61 bytes `$FCD1-$FD0D` become `$C9` (RET) and JP Z enters LoaderStart; a wrong sum falls into Crash.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,104,805 t-states own (0.21 %) |
| Called from | `Chain2` |
| Calls | `LoaderStart` (tail) |
| Reads | `$FCA3`-`$FFC0` (`Chain2`, `Chain3`, `Crash`, `Edge` and 14 more) |
| Writes | `$FCD1`-`$FD0D` (`Chain3`, `l_FCDA`, `l_FCE4`, `l_FCFF`); `$FD2C`-`$FFBF` (`Edge`, `LoadBlock`, `Store`, `StoreLast` and 10 more) |

#### `Crash` (`$FD20`)

**Wipe the RAM from `$0075` upward with zeros until the machine resets**

IY from 0, LD (IY+`$75`),0 forever: the RAM is cleared, then the stack and this code, and the machine resets. Called by Chain3 on a bad sum, by LoaderStart when LoadFailed is set and by the end when the check byte leaves H nonzero.

[Animation: `Crash` at work](img/routines/Crash.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `Edge` (`$FD2C`)

**Wait A*16 T-states, then count in B until the EAR bit changes; border stripes**

In: A the delay, B the start count, C the last EAR level in bit 5. Out: carry set and B the count at the edge, the border flipped; carry clear (B wrapped to 0) on a timeout or BREAK (bit 0 of port `$7FFE` is SPACE: RRA puts it in carry... the ROM's LD-EDGE shape). The AND at `$FD3F` picks the border colours; LoadBlock and LeaderDone patch it (`$FD40`).

Witness: L1 9845859 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 773,370 calls, 640,102,213 t-states own (43.07 %) |
| Called from | `LoadBlock`, `ReadMarkBits` |
| Ports in | `$7FFE` |
| Ports out | `$08FE`, `$09FE`, `$0AFE` |

#### `LoadBlock` (`$FD47`)

**Read a leader, the sync counts and the 6-bit mark `$3A`, then the bytes of the first block**

In: IX the address, DE the length - 1. Reads leader edges until about 1045 * 256 T-states of tone, then the sync: four groups of short pulses (SyncCounts), each followed by a long one; then a 6-bit mark that must be %111010 (`$3A`) or Crash. IY = BlockTable, H = 0 (the running XOR of the tape bytes) and the bit loop at ByteLoop.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 2 calls, 54,809,671 t-states own (3.69 %) |
| Called from | `ProbeTape`, `LoaderStart` |
| Calls | `Edge` |
| Reads | `$FF85`-`$FFBF` (`SyncCounts`, `BlockTable`, `LoaderPad`) |
| Writes | `$4000`-`$5B3F` (screen); `$5BC8`-`$FA1F`; `$FD40` (`l_FD30+16`); `$FE04`-`$FE3F` (`Store`, `StoreLast`); `$FF63`-`$FF86` (`l_FF41+34`, `LoadEnd`, `SyncCounts`) |
| Ports in | `$0FFE` |
| Ports out | `$0FFE`, `$7FFD` |

#### `Store` (`$FE04`)

**Store a byte ((L XOR `$98`) + `$0B`) and read the next one**

The store of every byte but a block's last. Its operands k = `$98` and a = `$0B` are the keys: block 9 loads `$3E`,`$07` over `$FE04-$FE05`, making k = `$07` for the blocks after it.

Witness: L1 47560 (c1).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `LoadEnd` (tail) |

#### `StoreLast` (`$FE3C`)

**Store a block's last byte, read the 21-bit end mark, take the next row of BlockTable**

The last byte's store has its own keys (`$98`, `$0B`; block 10 loads `$3E`,`$07`,`$AD`,`$C6`). Then three 7-bit groups via ReadMarkBits; the middle one must be `$7F` or LoadFailed = `$7F`. The row: page (IY+4) out to `$7FFD` when nonzero (always `$10` here: ROM 1, bank 0 on a 128K), IX = (IY+0), DE = (IY+2), IY += 5, back to ByteLoop. A row with page 0 (row 11) keeps IX, sets StoreLastJump to `$FF7A` and DE = `$0E00`: the last block, 3585 bytes, whose last byte is the check.

Witness: L1 11 (c1).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ReadMarkBits` |

#### `ReadMarkBits` (`$FEB3`)

**Read one mark bit into L by two edges (threshold `$DB`)**

In: L with its marker, B the count. Loops by JP NC to `$FEB1` for 0 bits; returns when the marker leaves L. Used by StoreLast for the 21-bit end mark.

Witness: L1 231 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 33 calls, 22,506 t-states own (0.00 %) |
| Called from | `StoreLast` |
| Calls | `Edge` |

#### `ProbeTape` (`$FEC9`)

**Load block 5 to `$A000`, sample the EAR 255 times to `$9000` and check the samples**

Called by LoaderStart with IX = `$A000`, DE = `$11`: block 5 (18 tape bytes: the ROM bytes of `$0032-$0042` decoded with k = `$98`, a = `$0B`, then the block's last byte; a decoy later overwritten). Then 255 samples by SampleEar to `$9000-$90FE` and CheckSamples; a bad tape sets LoadFailed. A copy without the tone after block 5 fails here.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 call, 16,376 t-states own (0.00 %) |
| Called from | `LoaderStart` |
| Calls | `LoadBlock`, `SampleEar`, `CheckSamples` |
| Writes | `$9000`-`$90FE` |

#### `SampleEar` (`$FEDE`)

**Count the EAR changes in 255 reads into E**

Witness: L1 255 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 255 calls, 4,687,921 t-states own (0.32 %) |
| Called from | `ProbeTape` |
| Ports in | `$7FFE` |

#### `CheckSamples` (`$FEFA`)

**Sum the samples `$9032-$9063` and `$90CD-$90FE`; LoadFailed = 1 unless both are in range**

Sum 1 of the 50 bytes from `$9032`, sum 2 of the 50 bytes from `$90CD`. LoadFailed (`$FF36`) = 1 when sum 2 >= `$0D00`, or when sum 2 - sum 1 and sum 2 - sum 1 - 50 are both not negative; otherwise it stays 0.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 call, 7,047 t-states own (0.00 %) |
| Called from | `ProbeTape` |
| Reads | `$9032`-`$9063`; `$90CD`-`$90FE` |

#### `LoaderStart` (`$FF37`)

**Clear the attributes, probe the tape, load the screen and every block, then start the game**

Interrupts off, SP = `$FFFF`, `$5800-$5AFF` zero (the screen black). ProbeTape loads block 5; then IX = `$4000`, DE = `$1AFF` and StoreLastJump = StoreLast: LoadBlock loads the screen and the rows of BlockTable after it. The tail `$FF63-$FF79` is block 12's: it checks LoadFailed, sets IY = `$5C3A`, IM 1, HL' = `$2758`, R = 0 and jumps on (src/loader/tail.asm). This view holds the original tail with JP `$6000`.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 1 call, 23,631 t-states own (0.00 %) |
| Called from | `Chain3` (tail) |
| Calls | `LoadBlock`, `ProbeTape` |
| Writes | `$5800`-`$5AFF` (screen); `$FE3A`-`$FE3B` (`StoreLastJump+1`) |

#### `LoadEnd` (`$FF7A`)

**The end: drop `$FF7B`, border black; H (the XOR of the stream) 0: return to LoaderStart's tail, else Crash**

LoadBlock pushes `$FF7B` first, so a timeout anywhere (RET NC) lands at `$FF7B`; the last block's StoreLastJump lands at `$FF7A`, whose POP DE drops that `$FF7B`. Either way H < 1 returns to the tail at `$FF63`, anything else is Crash. This is the plain view's version, known only from the code: block 14 rewrites `$FF7A-$FF86` before the end (src/loader/tail.asm, TailEnd), and the 2 runs the witness counts are TailEnd's bytes (c1 frame 11632).

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 2 calls, 101 t-states own (0.00 %) |
| Called from | `Store` (tail) |
| Ports out | `$00FE` |


## The loader's end as blocks 12 and 14 rewrite it (`src/loader/tail.json`)

Enduro Racer, Activision 1987: `$FF63-$FF86` as tape blocks 12 and 14 load it over the loader's own end. Its entries
are `src/loader/<module>.asm`, written from `src/loader/tail.ann` by `kit/mkgame.py --part src/loader/tail.json`;
the recordings: `work/stage1/rec/c1` (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the
menu, stage 1 to the time out).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`tail`](#the-loaders-end-as-blocks-12-and-14-rewrite-it-tail) | `$FF63`-`$FF86` | 2 of 2 |

### The loader's end as blocks 12 and 14 rewrite it: tail

`src/loader/tail-module.asm`

#### `TailStart` (`$FF63`)

**LoadFailed set: Crash; else IY = `$5C3A`, IM 1, HL' = `$2758`, R = 0, JP `$A000`**

Reached when LoadBlock returns after the last block (the return address LoadBlock left). The JP `$A000` enters the decoy area block 5 filled; in c1 the game never got here: LoadEnd's JP `$5B00` comes first (c1 frame 11632).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `TailEnd` (`$FF7A`)

**Border black; H (the XOR of the stream) 0: JP Mover (`$5B00`), else JP `$0000`**

POP DE drops `$FF7B` (LoadBlock's push); XOR A / OUT (`$FE`) black border; LD A,H / CP 1 / JP C,`$5B00` when H = 0, JP `$0000` (a reset) otherwise.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the TOSEC [SpeedLock 2] copy at signal speed, the menu, stage 1 to the time out) | 2 calls, 101 t-states own (0.00 %) |
| Ports out | `$00FE` |
