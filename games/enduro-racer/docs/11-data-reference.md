# 11. Data reference

Every data entry of the game image `$5B00`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/rec/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: The first BASIC "enduro" and Stage0, The second BASIC "end2" and
Chain1, The loader: Chain2, Chain3 and the SpeedLock 2 loader, The loader's end as blocks 12 and 14 rewrite it)
follow the game, each under its own heading with its modules, its source, its annotations and its recordings.

## entry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B11` | `MoverTail` | 47 | The 47 bytes after Mover in tape block 15: the ROM font's letters F to K, never read. Tape block 15 carries 64 bytes; Mover uses 17. `$5B11-$5B3F` are the Spectrum ROM's glyphs of F, G, H, I, J and K (ROM `$3E31-$3E5F`; the first row of F, a zero, falls on JP Start's last byte). The game writes RowList (`$5B00`) before it reads it; nothing reads these bytes as loaded (c1, m128). A leftover of the tape's cutting. | `DrawRoad`, `GapRows` (`stage1/rec/stages`), `GroundTexture` (`stage1/rec/stages`) | `RoadRowsFlat`, `GapRows` (`stage1/rec/stages`) |
| `$5B40` | `RowListTail` | 64 | `$5B40-$5B7F`: zeros no tape block loads; the rest of RowList (RoadRowsMake writes it). RowList (`$5B00-$5B7F`, over Mover) is the list of the road's rows, each the RoadLines index of a drawn line, `$FE` a gap (GapRows), `$FF` the end; RoadRowsMake (`$9DF1`) writes it, DrawRoad reads it. | `DrawRoad`, `GapRows` (`stage1/rec/stages`), `GroundTexture` (`stage1/rec/stages`), `Mover` (`stage1/rec/m128`) | `RoadRowsFlat`, `GapRows` (`stage1/rec/stages`) |
| `$5B80` | `BendRows` | 128 | The bend row table, 128 bytes: each road row's x centre (the bend's sideways shift), built by ScrollBends / BlendBend. In the image `$5B80-$5BC7` are zeros (no block loads them) and `$5BC8-$5BFF` the start of the LDDR's leftover: an LDDR moving a block up leaves its first `$5E0` bytes where they were, so `$5BC8-$61A3` still hold what is now at `$61A8-$6783` (entry.cpu.bin byte for byte; tools/parts.py rebuilds it so). ClearBendRows and the game overwrite all of `$5B80-$642F` before reading it. | `BlendBend`, `CopyRows`, `DrawObject`, `DrawRiders`, `DrawRoad` +3 | `BlendBend`, `ClearBendRows`, `CopyRows`, `ScrollBends`, `StartRace` +1 |
| `$5C00` | `RoadLines` | 128 | The screen line of each road row, 128 bytes (`$70` + depth / 2): RoadRowsFlat, RoadRowsCrest, RoadRowsJump write it. RoadLines' last entry (`$5C7F`) gives RoadTopRow = (`$5C7F`) - `$71`; all entries `$70` (the road flat under a high jump) make RoadTopRow `$FF` (the stage 3 reset, leftovers section of NOTES). | `BikeControl`, `Crash`, `DrawBike`, `DrawObject`, `DrawRiders` +8 | `RoadRowsCrest`, `RoadRowsFlat`, `RoadJumpRows` (`stage1/rec/truck`), `RoadRowsJump` (`stage1/rec/stages`) |
| `$5C80` | `Riders` | 90 of 128 | The six riders, 15 bytes each: flags, x, distance, speed, pose, jump. +0 flags (bit 7 not in the race, bit 0 the second kind: the wider sprite set and the hard collision), +2 x, +3/+4 distance (the high byte is the road row; 0-`$4F` on screen), +5/+6 speed, +7 acceleration, +8 top speed, +9 pose (0-3, 4 for the second kind), +`$0A` the lowest pose on a hill, +`$0B`/+`$0C` jump height, +`$0D`/+`$0E` jump speed. StartRace fills it from RiderStarts; MoveRiders and DrawRiders use it. | `BikeControl`, `BikeRoadPlace`, `DrawBike`, `DrawHorizonAt`, `DrawRiders` +25 | `BikeControl`, `Crash`, `DrawRoad`, `HorizonScrollStep`, `MoveRidersLoop` +10 |
| `$5CDA` | `DrawStack` (`Riders`+90) | 13 | the track interpreter's stack for the drawing walk (a copy of TrackStack each pass, 13 bytes) | `Mover`, `TrackStep` | `RacePass`, `TrackStep`, `StartRace` (`stage1/rec/m128`) |
| `$5CE7` | `SavedSp2` (`Riders`+103) | 2 | DrawRoad's SP while it walks RowList (and RoadRowsJump's) | `DrawRoad`, `Mover`, `DrawRoadRunOff` (code) | `DrawRoad` |
| `$5CE9` | `JumpHeight` (`Riders`+105) | 6 | the bike's height in the air, 8.8 (`$5CEA` the whole part; 0 on the ground) | `BikeControl`, `BikeRoadPlace`, `DrawBike`, `EngineSound`, `Mover` +9 | `BikeControl`, `Crash`, `RacePass`, `StartRace`, `GetUpSlide` (`stage1/rec/stages`) +1 |
| `$5CEF` | `HorizonAddr` (`Riders`+111) | 2 | the stage's horizon (StageTable) | `HorizonHidden`, `HorizonScrollStep`, `Mover`, `DrawHorizon` (`stage1/rec/names`), `HorizonBytes` (code) +2 | `SetHorizon` |
| `$5CF1` | `HorizonRows` (`Riders`+113) | 1 | its rows | `HorizonHidden`, `HorizonScrollStep`, `Mover`, `DrawHorizon` (`stage1/rec/names`) | `SetHorizon` |
| `$5CF2` | `HorizonTop` (`Riders`+114) | 1 | the picture's top line (StageTable byte 3): DrawHorizonAt clears from TopClip down to it, then copies the picture from it | `DrawHorizonAt`, `Mover`, `RampSpeed`, `StartRace`, `DrawHorizon` (`stage1/rec/names`) +2 | `SetHorizon` |
| `$5CF3` | `HorizonScroll` (`Riders`+115) | 2 | the horizon's scroll position, 8.8 (HorizonScrollStep) | `HorizonScrollStep`, `Mover` | `HorizonScrollStep` |
| `$5CF5` | `JumpRows` (`Riders`+117) | 4 | up to four rows of ramps (type 0 objects) this pass, `$FF` the end: MoveRiders makes riders jump there | `MoveRidersLoop`, `Mover`, `MoveRiders` (`stage1/rec/ctl`) | `RacePass`, `StartRace` |
| `$5CF9` | `JumpRowPtr` (`Riders`+121) | 2 | the next free JumpRows place | `Mover`, `RacePass` | `RacePass`, `StartRace` |
| `$5CFB` | `DrawTrackPtr` (`Riders`+123) | 2 | the drawing walk's track position | `Mover`, `RacePass` | `RacePass` |
| `$5CFD` | `JumpSpeed` (`Riders`+125) | 2 | the bike's vertical speed, 8.8 (`$5CFE` the whole part), minus `$02F0` each pass | `BikeControl`, `Mover`, `GetUpSlide` (`stage1/rec/stages`), `l_AEB0` (code) | `BikeControl`, `Crash`, `RacePass`, `StartRace`, `GetUpSlide` (`stage1/rec/stages`) +2 |
| `$5CFF` | `SplashOn` (`Riders`+127) | 1 | `$87` on stages 2 and 4: the splash under the bike (DrawSplash) | `Mover`, `StartRace`, `l_A6AC` (code) | `StartRace` |
| `$5D00` | `ReverseTable` | 256 | Each byte with its bits reversed: Init builds it, DrawMirrored reads it (H = `$5D`) | `DrawMirrored`, `Mover`, `MirrorCarry` (`stage1/rec/ctl`) | `Init` |
| `$5E00` | `Records` | 13 | The five stage records (seconds, hundredths, BCD) and their total (minutes, seconds, hundredths). Init copies InitialRecords here; RecordStages improves them at game over. They last until the machine is reset. | `FormatTime`, `Mover`, `PrintTime`, `SumTimes`, `PlayTurn` (`stage1/rec/stages`) | `Init`, `SumTimes`, `PlayTurn` (`stage1/rec/stages`) |
| `$5E0D` | `Player` | 1 of 56 | The current player's block, 56 bytes (NewGame clears it; TurnLoop swaps it with OtherPlayer) | `AddScore`, `AdvanceTrack`, `Attract`, `BikeControl`, `BikeRoadPlace` +40 | `AddScore`, `AdvanceTrack`, `BikeControl`, `NewGame`, `RampSpeed` +10 |
| `$5E0E` | `StageTimes` (`Player`+1) | 10 | five stage times: seconds, hundredths (BCD) | `Mover`, `NewGame`, `FormatTime` (`stage1/rec/stages`), `PlayTurn` (`stage1/rec/stages`), `SumTimes` (`stage1/rec/stages`) | `NewGame`, `StageTime` |
| `$5E18` | `Score` (`Player`+11) | 7 | seven characters, leading blanks | `AddScore`, `Mover`, `NewGame`, `PlayTurn`, `PrintString` | `AddScore`, `NewGame` |
| `$5E1F` | `Timer` (`Player`+18) | 1 | seconds left, BCD (game over at 0) | `Mover`, `NewGame`, `PlayTurn`, `PrintTimer`, `RampSpeed` +8 | `NewGame`, `RampSpeed`, `HudPlayer` (`stage1/rec/m128`), `RaceQuit` (`stage1/rec/ctl`), `RiderBounce` (`stage1/rec/names`) +1 |
| `$5E20` | `Tenths` (`Player`+19) | 1 | passes to the next second, 9 down to 0 (TimerTick reads it first: at 0 the timer's step and 10 again, then one off) | `Mover`, `NewGame`, `RampSpeed`, `StageTime`, `StartRace` +3 | `NewGame`, `RampSpeed`, `HudPlayer` (`stage1/rec/m128`), `RaceQuit` (`stage1/rec/ctl`), `RiderBounce` (`stage1/rec/truck`) |
| `$5E21` | `TimerAtStart` (`Player`+20) | 2 | Timer and Tenths at the stage's start (StageTime) | `Mover`, `NewGame`, `StageTime` | `NewGame`, `StartRace` |
| `$5E23` | `Stage` (`Player`+22) | 1 | 0-4 (5 after the finish) | `BikeControl`, `GapRows`, `GroundTexture`, `Mover`, `NewGame` +14 | `NewGame`, `StageEnd` (`stage1/rec/stages`) |
| `$5E24` | `Countdown` (`Player`+23) | 1 | the start's countdown (16 down; bit 7: resume after a fall) | `BikeControl`, `DrawBike`, `Mover`, `NewGame`, `RampSpeed` +6 | `BikeControl`, `NewGame`, `StartRace` |
| `$5E25` | `SegmentLeft` (`Player`+24) | 2 | the segment's progress, 8.8: counts down by ScrollStep | `AdvanceTrack`, `BlendBend`, `DrawRoad`, `Mover`, `NewGame` +6 | `AdvanceTrack`, `NewGame` |
| `$5E27` | `TrackPtr` (`Player`+26) | 2 | the track position (Track's elements) | `AdvanceTrack`, `Mover`, `NewGame`, `RacePass`, `StartRace` (`stage1/rec/m128`) | `AdvanceTrack`, `NewGame` |
| `$5E29` | `TrackDistance` (`Player`+28) | 2 | the distance into the track, 8.8 | `AdvanceTrack`, `Attract`, `Mover`, `NewGame`, `RacePass` +1 | `AdvanceTrack`, `NewGame` |
| `$5E2B` | `StageListPtr` (`Player`+30) | 2 | the segment in StageList | `AdvanceTrack`, `Mover`, `NewGame`, `PlayTurn`, `SegmentDecode` +3 | `AdvanceTrack`, `NewGame`, `NextSegment` (code) |
| `$5E2D` | `BendDir` (`Player`+32) | 1 | the bend's side (segment bit 4): 1 one way, 0 the other | `BikeControl`, `BikeRoadPlace`, `DrawObject`, `DrawRiders`, `Mover` +7 | `NewGame`, `SegmentDecode`, `AdvanceTrack` (`stage1/rec/crash`) |
| `$5E2E` | `BendPrev` (`Player`+33) | 1 | the previous segment's bend (bits 0-1: 0 straight, 1-3 a bend profile) | `BikeControl`, `BlendBend`, `Mover`, `NewGame`, `RiderNoRamp` +6 | `NewGame`, `SegmentDecode`, `AdvanceTrack` (`stage1/rec/crash`) |
| `$5E2F` | `Bend` (`Player`+34) | 1 | the segment's bend (bits 0-1) | `BlendBend`, `Mover`, `NewGame`, `RiderNoRamp`, `ScrollBends` +5 | `NewGame`, `SegmentDecode`, `AdvanceTrack` (`stage1/rec/crash`) |
| `$5E30` | `CrestPrev` (`Player`+35) | 1 | the previous segment's crest (bits 2-3: 0 level, 1-3 a rise or dip) | `Mover`, `NewGame`, `RoadRowsCrest`, `RoadRowsFlat` (`stage1/rec/stages`) | `NewGame`, `SegmentDecode`, `AdvanceTrack` (`stage1/rec/crash`) |
| `$5E31` | `Crest` (`Player`+36) | 1 | the segment's crest (bits 2-3) | `Mover`, `NewGame`, `RoadRowsCrest`, `SegmentDecode`, `AdvanceTrack` (`stage1/rec/crash`) | `NewGame`, `SegmentDecode`, `AdvanceTrack` (`stage1/rec/crash`) |
| `$5E32` | `FallX` (`Player`+37) | 1 | x at a fall (the restart's x) | `Mover`, `NewGame`, `StartRace` | `BikeControl`, `NewGame` |
| `$5E33` | `GapMarks` (`Player`+38) | 2 | the rows of the two `$F0` marks (the gap ends); `$7F` none | `AdvanceTrack`, `Mover`, `NewGame`, `GapRows` (`stage1/rec/stages`), `TrackStep` (`stage1/rec/stages`) | `AdvanceTrack`, `NewGame`, `StartRace`, `RacePass` (`stage1/rec/fall5`), `TrackStep` (`stage1/rec/stages`) |
| `$5E35` | `Segments` (`Player`+40) | 1 | segments driven in the stage (the lap table's %) | `AdvanceTrack`, `Mover`, `NewGame`, `PlayTurn`, `LapPercent` (code) +1 | `AdvanceTrack`, `NewGame`, `StageEnd` (`stage1/rec/stages`), `NextSegment` (code) |
| `$5E36` | `VarObject` (`Player`+41) | 1 | the object type the `$B0` command set (elements of type 10 draw it) | `Mover`, `NewGame`, `RacePass`, `StartRace` | `NewGame`, `RampSpeed`, `TrackStep` |
| `$5E37` | `TrackStack` (`Player`+42) | 14 | the track interpreter's stack: depth, two frames of 6 bytes (return, length, distance) | `Mover`, `NewGame`, `RacePass`, `TrackStep`, `StartRace` (`stage1/rec/m128`) | `NewGame`, `TrackStep` |
| `$5E45` | `OtherPlayer` | 56 | The other player's block, 56 bytes, swapped in by TurnLoop | `Mover`, `NewGame`, `PlayTurn` (`stage1/rec/stages`), `RecordTie` (`stage1/rec/names`), `NameDone` (code) | `NewGame` |
| `$5E7D` | `PlayerPad` | 3 | 3 bytes after the blocks, never used (`$66`, `$64`, `$00` in the image: LDDR leftovers) | `Mover` | - |
| `$5E80` | `StageList` | 140 of 1456 | The stage list, one byte a segment (Init copies it from `$EB00`; the image's own bytes here are leftovers). bits 0-1 the bend (0 straight, BendProfiles 1-3), bits 2-3 the crest (0 level, CrestTable 1-3), bit 4 the direction, bit 5 the stage's last segment, bits 6-7 added to the segment's progress at its start (SegmentLen, `$AF81`). Five stages end at `$5E9F`, `$5EB6`, `$5ED0`, `$5EEB`, `$5F0B`: 32, 23, 26, 27 and 32 segments. src/res/track/stage1.txt ... stage5.txt (tools/course.py). | `AdvanceTrack`, `Mover`, `PlayTurn`, `RacePass`, `SegmentDecode` +2 | `Init` |
| `$5F0C` | `TrackPatterns` (`StageList`+140) | 452 | the patterns the `$E0` commands run | `AdvanceTrack`, `Mover`, `RacePass`, `TrackStep` | `Init` |
| `$60D0` | `Track` (`StageList`+592) | 864 | the track's elements, from the start of stage 1 (TrackPtr) | `AdvanceTrack`, `Mover`, `RacePass`, `TrackStep` | `Init` |
| `$6430` | `AySilence` | 2 of 12 | AY register 7 = `$3F`: every tone and noise off (written when the tune stops). AY data: a register then its value, written by AyWrite (`$6806`). Interrupt writes this one pair when the tune request TuneRequest goes to 0 (pause, the end of a race). | `AyWrite`, `IntVector`, `Mover` | `IntVector` |
| `$6432` | `AyTuneStart` (`AySilence`+2) | 6 | four pairs at a tune's start: 7 = `$38` (tones A, B, C on), 8 = `$0D`, 9 = `$0E`, 10 = `$0F` (volumes) | `AyWrite`, `Mover` | - |
| `$6438` | `AyEngineVolume` (`AySilence`+8) | 2 | register 10 (volume C) = `$0F`: EngineSound's AY tone on channel C | `AyWrite`, `Mover` | - |
| `$643A` | `TuneHeld` (`AySilence`+10) | 1 | nonzero while an effect owns the AY: the tune's mixer is written again when it ends | `Mover`, `IntVector` (`stage1/rec/m128`) | `IntVector` (`stage1/rec/m128`) |
| `$643B` | `TunePlaying` (`AySilence`+11) | 1 | the tune the channels play: 0 none, 1 or 2 (compared with TuneRequest each interrupt) | `IntVector`, `Mover` | `IntVector` |
| `$8003` | `InitialRecords` | 13 | The five stage records (99"59 each) and their total, copied to Records (`$5E00`) by Init. 13 bytes: five times (seconds BCD, hundredths BCD) = `$99`, `$59`, then the total (minutes, seconds, hundredths) `$03`, `$59`, `$96`, which RecordTotals recomputes before it is shown. Afterwards the bytes are the line buffer. | `BlitHead`, `Init`, `Mover`, `ShiftLeftHead`, `ShiftRightHead` +3 | `DrawMirrored`, `ShiftCopyHead`, `ShiftLeftHead`, `ShiftRightHead`, `WaitKey` +3 |
| `$8010` | `LineBufferTail` | 168 | `$8010-$80B7`: zeros, the rest of the sprite line buffer that starts at `$8000` | `BlitHead`, `Mover`, `ShiftLeftHead`, `ShiftRightHead` | `DrawMirrored`, `ShiftCopyHead`, `ShiftLeftHead`, `ShiftRightHead`, `MirrorCarry` (`stage1/rec/ctl`) |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$645F` | `SkidLevel` | 1 of 5 | The AY skid noise: 0 none, else EngineSound's noise period (set by OffRoad, the dust on stage 3) | `AyEffectTick`, `DrawBike`, `IntVector`, `Mover`, `StartRace` +3 | `AyEffectTick`, `BikeRoadPlace`, `Crash`, `IntVector`, `PlayChannel` +12 |
| `$6460` | `TuneMark` (`SkidLevel`+1) | 1 | 1 after a tune's `$CA` mark: the tune may change now (PlayChannel sets it, Interrupt clears it) | `IntVector`, `Mover` | `AyEffectTick`, `IntVector`, `PlayChannel`, `ChannelCommands` (code), `l_661E` (code) |
| `$6461` | `TuneRequest` (`SkidLevel`+2) | 1 | the tune the game wants: 0 silence, 1 (odd stages) or 2 (even), set by SetTune; also gates EngineSound | `IntVector`, `Mover` | `AyEffectTick`, `RaceEnd`, `RampSpeed`, `SetTune`, `HudPlayer` (`stage1/rec/tech-ramp-wheelie`) +2 |
| `$6462` | `EffectTime` (`SkidLevel`+3) | 1 | the AY effect's count of interrupts (0: none); AyEffectTick counts it down | `AyEffectTick`, `Mover`, `EngineSound` (`stage1/rec/m128`), `IntVector` (`stage1/rec/m128`) | `AyEffectTick`, `PlayEffect`, `StartRace` |
| `$6463` | `EffectStep` (`SkidLevel`+4) | 1 | the effect's step, the AY register 10 sweep | `AyEffectTick`, `Mover` | `AyEffectTick`, `StartRace` |
| `$6566` | `IntStack` | 32 of 34 | The handler's stack, `$6566-$6585` (SP = `$6584` at the entry): six pushes and its calls; zeros in the image. WALKTHROUGH 1 (the stack-flagged bytes of c1's L1) gives `$6574-$6583` as the bytes the handler writes. | `IntVector`, `Mover`, `Interrupt` (code) | `IntVector`, `Interrupt` (code) |
| `$6586` | `IntSavedSp` (`IntStack`+32) | 2 | the interrupted SP + 2 (the SP the handler restores); the image holds `$B0ED`, an old value | `IntVector`, `Mover`, `Interrupt` (code) | `IntVector`, `Interrupt` (code) |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$66AA` | `NoteTable` | 24 | The AY tone periods of one octave (`$0EEE` ... `$07E9`), halved per octave by ChannelPeriod. A note n reads word n (`$66AA` + 2n): word 0 (`$0EEE`) is never read, and a note 12 would read TuneTable; the tunes use the notes 2, 4, 6, 7, 9 and 11 (src/res/sound/tunes.txt). | `Mover`, `PlayChannel` | - |
| `$66C2` | `TuneTable` | 8 | The tunes' streams, two words a tune: tune 1 Tune1A, Tune1B; tune 2 Tune2A, Tune2B. Read at IntSound as `$66BE` + 4 * tune (the operand TuneTable-4): tune 0 is silence and has no row. | `IntVector`, `Mover` | - |
| `$66CA` | `Tune2A` | 55 of 305 | Tune 2, channel A: calls of phrases, repeats and `$CA` marks (the stream format: PlayChannel). src/res/sound/tunes.txt lists the four streams as text (sound/tunes.bin, tools/res_formats.py). | `Mover`, `PlayChannel` | - |
| `$6701` | `Tune1A` (`Tune2A`+55) | 36 | tune 1, channel A | `Mover`, `PlayChannel` | - |
| `$6725` | `Tune2B` (`Tune2A`+91) | 107 | tune 2, channel B | `Mover`, `PlayChannel` (`stage1/rec/stages`) | - |
| `$6790` | `Tune1B` (`Tune2A`+198) | 107 | tune 1, channel B | `Mover`, `PlayChannel` | - |
| `$67FB` | `AyMixer` | 2 of 6 | AY register 7 and its value: the channels' mixer (PlayChannel sets and clears the tone bits). Pairs for AyWrite: register, value. AyMixer's value (`$67FC`) is the live mixer: PlayChannel, EngineTone and EngineSkid change its bits and WriteMixer sends it. | `AyWrite`, `Mover`, `PlayChannel`, `EngineSound` (`stage1/rec/m128`), `WriteMixer` (`stage1/rec/tech-ramp-wheelie`) +2 | `IntVector`, `PlayChannel`, `EngineSound` (`stage1/rec/m128`), `l_68AA` (code), `l_68DF` (code) |
| `$67FD` | `AyVolumeC` (`AyMixer`+2) | 2 | register 10 (channel C's volume), set by EngineSkid from SkidLevel | `Mover` | `l_68AA` (code) |
| `$67FF` | `AyNoise` (`AyMixer`+4) | 2 | register 6 (the noise period), set by EngineSkid from the speed | `Mover` | `l_68AA` (code) |
| `$6817` | `ChannelA` | 17 of 34 | Tune channel A: count, stream, transpose, restart, repeat depth and records, tone register 2 (AY channel B), mixer bit 1 (value `$02`). 17 bytes: +0 the note's count, +1/+2 the stream pointer, +3 the transpose, +4/+5 the restart, +6 the repeat depth (`$FF` none), +7 two records of 3 bytes (count, address), +`$0D` the tone register, +`$0E` the mixer bit, +`$0F`/+`$10` the call's return. | `ChannelLoop`, `Mover`, `PlayChannel` | `IntVector`, `PlayChannel` |
| `$6828` | `ChannelB` (`ChannelA`+17) | 17 | tune channel B: tone register 0 (AY channel A), mixer bit 0 (value `$01`) | `ChannelLoop`, `Mover`, `PlayChannel` | `IntVector`, `PlayChannel` |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$690F` | `Leftover690F` | 729 | `$690F-$6BE7`: 729 bytes no instruction reads in any recording (a repeated word pattern, an older table). L1's byte use has no read here in the seven recordings; no instruction's operand points into it. | `Mover` | - |
| `$6BE8` | `ObjectSprites` | 2504 | The roadside objects' sprites (ObjectTypes' lists point into `$6BE8-$75AF`), and the bike's dust and splash elsewhere. src/res/sprites/objects.png and .csv (tools/res_formats.py: every descriptor's sprite on a sheet). | `BlitHead`, `Mover`, `ShiftCopyHead` | - |
| `$75B0` | `RoadRowsOldData` | 39 | 39 bytes RoadRowsOld points IX at: read by no recording | `Mover` | - |
| `$75D7` | `BendBlend` | 49 | BlendBend's steps: 16 rows of slowly rising values (49 bytes to `$7607`) | `BlendBend`, `Mover`, `ScrollBends` (`stage1/rec/stages`) | - |
| `$7608` | `Font` | 504 | The 8x8 font, characters `$20-$5E` (PrintChar's base `$7508` = Font - `$100`: code - `$20` rows of 8). 63 characters; a `$5F` would read Perspective's first bytes. The frame pieces, the arrows, km/h and UP are among them (src/res/font/font.png, the order of the codes). | `Mover`, `PrintGlyph` | - |
| `$7800` | `Perspective` | 128 | Each of the 128 road rows' depth (the far row first: `$9F` ... `$11`), the road's perspective | `Mover`, `RoadRowsCrest`, `RoadRowsFlat`, `RoadJumpRows` (`stage1/rec/truck`), `RoadRowsJump` (`stage1/rec/stages`) | - |
| `$7880` | `EdgePatterns` | 384 | The road edge's 3-byte patterns, 8 pixel shifts for each of 16 widths (DrawRoad, near rows) | `DrawRoad`, `DrawRoadRunLine`, `Mover` | - |
| `$7A00` | `CrestTable` | 128 | The crest's change of each row's screen line (RoadRowsCrest: perspective * crest table / 512) | `Mover`, `RoadRowsCrest` | - |
| `$7A80` | `EdgePatterns2` | 384 | The second set of edge patterns (DrawRoad, chosen by bit 2 of the row) | `DrawRoad`, `DrawRoadRunLine`, `Mover` | - |
| `$7C00` | `CountGlyphs` | 46 | The countdown's glyphs: G, O (8 lines each), then 1, 2, 3 (10 lines each) for CountGlyph | `CountGlyphC`, `Mover` | `CountGlyphC` |
| `$7C2E` | `PassCount` | 1 of 38 | The passes, + 1 each (the wheel animation's and the HUD's beat). The variables `$7C2E-$7C53` are zeros in the image. | `AddScore`, `AdvanceTrack`, `BigDigit`, `BikeControl`, `BlitHead` +41 | `AdvanceTrack`, `Attract`, `BigDigit`, `BikeControl`, `CopyBuffer` +27 |
| `$7C2F` | `Beeper` (`PassCount`+1) | 1 | `$FF` on the 48K (the ROM test), 0 on the 128K | `CrashSoundD`, `EngineSound`, `IntVector`, `Mover`, `CrashSound` (`stage1/rec/twoplayer`) | `Init` |
| `$7C30` | `DemoMode` (`PassCount`+2) | 1 | a demo's segments left (8-15 at the start), 0 in a game | `AddScore`, `AdvanceTrack`, `BikeControl`, `Mover`, `NewGame` +7 | `AdvanceTrack`, `Attract`, `Menu` |
| `$7C31` | `GetUp` (`PassCount`+3) | 1 | the getting-up slide (LateralX toward 0) | `BikeControl`, `DrawBike`, `Mover`, `RacePass`, `RampSpeed` +4 | `BikeControl`, `StartRace`, `l_AD5C` (code) |
| `$7C32` | `Players` (`PassCount`+4) | 1 | 1 or 2 | `Menu`, `Mover`, `NewGame`, `RampSpeed`, `RiderBounce` (`stage1/rec/ctl`) +2 | `Init`, `Menu` |
| `$7C33` | `Speed` (`PassCount`+5) | 2 | SPEED, 8.8 km/h (`$7C34` the whole part, 0-199: the throttle's curve nears `$C800` and never reaches it) | `BikeControl`, `Crash`, `DrawBike`, `EngineSound`, `Mover` +14 | `BikeControl`, `OffRoad`, `PlayTurn`, `RacePass`, `RampSpeed` +4 |
| `$7C35` | `TotalTime` (`PassCount`+7) | 3 | the player's total (minutes, seconds, hundredths) | `Mover`, `FormatTime` (`stage1/rec/stages`), `PlayTurn` (`stage1/rec/stages`), `PrintTime` (`stage1/rec/stages`), `l_89AD` (code) | `SumTimes` (`stage1/rec/stages`) |
| `$7C38` | `SavedSp` (`PassCount`+10) | 2 | SP while a routine uses it as a pointer | `BigDigit`, `BlitHead`, `DrawRoad`, `HorizonHidden`, `Mover` +2 | `BigDigit`, `CopyBuffer`, `DrawHorizonAt`, `DrawRoad`, `ShiftLeftHead` +4 |
| `$7C3A` | `InGap` (`PassCount`+12) | 2 | the bike over stage 3's gap (GapRows) | `Mover`, `OffRoadStage5` (`stage1/rec/stages`), `TrackStep` (`stage1/rec/stages`) | `StartRace`, `GapRows` (`stage1/rec/stages`) |
| `$7C3C` | `ScoreDigits` (`PassCount`+14) | 10 | 7 digits (0-9) AddScore adds, read back from `$7C42`: the speed's each pass, the time bonus at `$7C3D` (with `$7C3F-$7C42` as the last ScoreAdd left them: the bonus carries that pass's speed points) | `AddScore`, `Mover`, `RampSpeed`, `HudPlayer` (`stage1/rec/m128`), `RiderBounce` (`stage1/rec/truck`) | `RampSpeed`, `StartRace`, `HudPlayer` (`stage1/rec/m128`), `RiderBounce` (`stage1/rec/truck`), `StageEnd` (`stage1/rec/stages`) |
| `$7C46` | `RunLines` (`PassCount`+24) | 13 | DrawRoadRun's work: lines, x positions and slopes (`$7C46-$7C52`) | `DrawRoad`, `DrawRoadRunLine`, `Mover`, `DrawRoadRunOff` (code), `l_9BB9` (code) +3 | `DrawRoad`, `DrawRoadRunLine`, `l_9B37` (code), `l_9B7F` (code), `l_9BB9` (code) +2 |
| `$7C53` | `ExtendedTime` (`PassCount`+37) | 1 | EXTENDED PLAY's flashing passes | `Mover`, `RampSpeed`, `HudPlayer` (`stage1/rec/crash`), `RiderBounce` (`stage1/rec/ctl`) | `StartRace`, `RampSpeed` (`stage1/rec/stages`), `RiderBounce` (`stage1/rec/truck`), `StageEnd` (`stage1/rec/stages`), `ExtendedPlay` (code) |
| `$7C54` | `BigDigits` | 300 | The ten big digits, 15 lines of 2 bytes (16 x 15 pixels) each (BigDigit) | `BigDigit`, `Mover`, `PrintTimer` (`stage1/rec/names`) | - |
| `$7D80` | `BendProfiles` | 384 | The three bends' profiles, each row's sideways shift, 128 rows each (ScrollBends: `$7D80` + 128 * (bend - 1)) | `Mover`, `ScrollBends`, `StartRace` | - |
| `$7F00` | `RowScale` | 256 | Two tables of 128 a road row: `$7F00` + row the row's scale (edge pattern, sideways scale), `$7F80` + row its half width | `DrawObject`, `DrawRiders`, `DrawRoad`, `Mover`, `GroundTexture` (`stage1/rec/stages`) | - |
| `$B11D` | `LeftoverCode` | 227 | `$B11D-$B1FF`: 227 bytes of an older build's code (LD (`$B1BA`),A ...), never run or read. They disassemble as code addressing `$B1`xx; no instruction of the game points here and L1 has no run or read (the seven recordings). | `Mover` | - |
| `$B200` | `Im2Table` | 257 | The IM 2 vector table, 257 bytes: Init fills it with `$64` (vector `$6464` = IntVector); the image holds older graphics here | `IntVector`, `Mover` | `Init` |
| `$B301` | `Gap5` | 5 | 5 bytes between the table and the sprites (`$90` `$11` ...), never read | `Mover`, `BlitHead` (`stage1/rec/stages`), `ShiftCopyHead` (`stage1/rec/stages`) | - |
| `$B306` | `Sprites` | 12218 | The bike's, the riders', the trucks' and the splash and dust sprites (`$B306-$E2BF`), drawn through the descriptors. BikePoses, RiderSprites, DrawSplash and DrawDust point into it. reset3's crash ran through `$D253-$D26A` as code (the bytes of a sprite); src/res/sprites/. | `BlitHead`, `DrawBike`, `DrawMirrored`, `Mover`, `ShiftCopyHead` +1 | `DrawBike` |
| `$E2C0` | `Dunes` | 800 | Stage 3's horizon, 25 lines of 32 bytes | `Mover`, `HorizonHidden` (`stage1/rec/stages`), `RotateLeft1` (`stage1/rec/stages`), `RotateLeft4` (`stage1/rec/stages`), `RotateRight1` (`stage1/rec/stages`) | `RotateLeft1` (`stage1/rec/stages`), `RotateLeft4` (`stage1/rec/stages`), `RotateRight1` (`stage1/rec/stages`) |
| `$E5E0` | `Mountains` | 1024 | Stages 1 and 4's horizon, 32 lines | `HorizonHidden`, `Mover`, `RotateLeft1`, `RotateRight1`, `RotateLeft4` (`stage1/rec/stages`) +1 | `RotateLeft1`, `RotateRight1`, `RotateLeft4` (`stage1/rec/stages`), `RotateRight4` (`stage1/rec/stages`) |
| `$E9E0` | `Clouds` | 288 | Stages 2 and 5's horizon, 9 lines | `Mover`, `HorizonHidden` (`stage1/rec/stages`), `RotateLeft1` (`stage1/rec/stages`), `RotateLeft4` (`stage1/rec/stages`), `RotateRight1` (`stage1/rec/stages`) +1 | `RotateLeft1` (`stage1/rec/stages`), `RotateLeft4` (`stage1/rec/stages`), `RotateRight1` (`stage1/rec/stages`), `RotateRight4` (`stage1/rec/stages`) |
| `$EB00` | `TrackTables` | 1456 | StageList, TrackPatterns and Track as loaded (1456 bytes): Init copies them to `$5E80`; then the back buffer's first rows. `$EB00-$EB8B` StageList (140 segments), `$EB8C-$ED4F` the patterns, `$ED50-$F0AF` the track. src/res/track/ (tools/course.py draws each stage). | `BlitHead`, `CopyRows`, `Init`, `IntVector`, `Mover` +1 | `BlitHead`, `DrawRoad`, `HorizonHidden`, `IntVector`, `GroundTexture` (`stage1/rec/stages`) +1 |
| `$F0B0` | `OldGraphics` | 1296 | `$F0B0-$F5BF`: 1296 bytes of older graphics under the back buffer, overwritten before any read | `BlitHead`, `CopyRows`, `IntVector`, `Mover`, `GroundTexture` (`stage1/rec/stages`) | `BlitHead`, `DrawRoad`, `HorizonHidden`, `IntVector`, `GroundTexture` (`stage1/rec/stages`) +1 |
| `$F5C0` | `BackBuffer` | 2112 | `$F5C0-$FDFF`: zeros; the back buffer (lines 40-191) spans `$EB00-$FDFF` in play | `BlitHead`, `CopyRows`, `IntVector`, `Mover`, `GroundTexture` (`stage1/rec/stages`) | `BlitHead`, `DrawRoad`, `DrawRoadRunLine`, `HorizonHidden`, `IntVector` +2 |
| `$FE00` | `RowTable` | 384 | The address of each of the 192 pixel lines: the screen's, or the back buffer's after SetRowTable `$A600` | `ClearScreen`, `HorizonHidden`, `IntVector`, `PrintGlyph`, `ScrollUp` +2 | `BigDigit`, `BlitHead`, `DrawRoad`, `DrawRoadRunLine`, `HorizonHidden` +6 |
| `$FF80` | `StackArea` | 128 | `$FF80-$FFFF`: the loader's leftovers (Stage0's copy, ROM glyphs); the game's stack below SP = 0. Init sets SP = 0: the pushes go to `$FFFF` down (WALKTHROUGH 1: `$FFE4-$FFFF` used). | `IntVector` | `IntVector`, `PrintGlyph` (`stage1/rec/twoplayer`) |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$831B` | `ControlMethod` | 1 | The control method, 0-4 (CHANGE CONTROL MODE) | `KeyOrFire`, `Menu`, `Mover`, `WaitKey`, `WaitKeyTimeout` +1 | `Menu`, `l_82E1` (code) |
| `$831C` | `Keys` | 7 | The keys of method 0: THROTTLE Q, WHEELIE A, LEFT O, RIGHT P, BRAKES SPACE (3), PAUSE H, RESET R. Character codes as KeyMap gives them; 1-4 stand for SYMBOL SHIFT, ENTER, SPACE and CAPS SHIFT (KeyNames). | `Menu`, `Mover` | `Menu` (`stage1/rec/ctl`) |
| `$8323` | `ControlTable` | 50 | Five methods, 10 bytes each: the half-row bytes of THROTTLE, WHEELIE, LEFT, RIGHT, BRAKES, then their masks. Row 0 is KEYBOARD (DEFINE KEYS writes it): `$FB` `$FD` `$DF` `$DF` `$7F`, masks 1 1 2 1 1 (Q A O P SPACE); 1 KEMPSTON: all 0 (the port is `$1F`), masks 8 4 2 1 `$10`; 2 SINCLAIR RIGHT: `$EF`, masks 2 4 `$10` 8 1 (keys 9 8 7 6 0); 3 SINCLAIR LEFT: `$F7`, masks 8 4 1 2 `$10` (4 3 1 2 5); 4 CURSOR: `$EF` `$EF` `$F7` `$EF` `$EF`, masks 8 `$10` `$10` 4 1 (keys 7 6 5 8 0). The last three masks (`$8352-$8354`) are also the three bytes PrintKeyName's base KeyNamesBase (KeyNames - 3) points at; it never reads them (codes 1-4). src/res/tables/controls.csv. | `Mover`, `PatchControls` | `Menu` (`stage1/rec/ctl`) |
| `$8355` | `KeyNames` | 12 | SYM, ENT, SPC, CPS: the names of the keys 1-4, three letters each | `Mover`, `PrintString` | - |
| `$8520` | `KeyMap` | 40 | The key at each half row and bit as ScanKeys finds it: B N M 1 3 H J K L 2 Y U I O P 6-0 5-1 T-Q G-A V-Z 4. 40 characters, the half rows `$7F`, `$BF`, `$DF`, `$EF`, `$F7`, `$FB`, `$FD`, `$FE`, bit 4 to bit 0. Codes 1 SYMBOL SHIFT, 2 ENTER, 3 SPACE, 4 CAPS SHIFT. | `Mover`, `ScanKeys` | - |
| `$8735` | `LapTexts` | 25 of 32 | TOTAL, RECORD, PLAYER (the lap table), LAPTIME (the stage end's line) and the time text that FormatTime fills | `Mover`, `PrintString`, `PlayTurn` (`stage1/rec/stages`) | `FormatTime`, `PrintTime`, `PlayTurn` (`stage1/rec/stages`), `l_89AD` (code) |
| `$874E` | `TimeText` (`LapTexts`+25) | 7 | the time: minutes, ', seconds, ", hundredths | `Mover`, `PrintString`, `PlayTurn` (`stage1/rec/stages`) | `FormatTime`, `PrintTime`, `PlayTurn` (`stage1/rec/stages`), `l_89AD` (code) |

## flow

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8AB3` | `FrameChars` | 8 of 16 | The frame's eight characters: corners and edges ([ % \ + / ] ) ^ in the font's own shapes). Order: top left, top, top right, left, right, bottom left, bottom, bottom right (DrawFrame). The font draws them as frame pieces (src/res/font/font.png). | `DrawFrame`, `Mover`, `DrawCursor` (`stage1/rec/names`) | - |
| `$8ABB` | `FrameChars2` (`FrameChars`+8) | 8 | DrawWindow's frame: the characters `( ) * / + & % $` | `DrawFrame`, `Mover` | - |
| `$8AC3` | `NameGrid` | 45 | The name entry's letters, three rows of 15: QWERTYUIOP=?789 ASDFGHJKL:;'456 ZXCVBNM,.!@0123. = deletes, ? ends; : ; ' ! @ are the font's own glyphs there. | `Mover`, `PlayTurn` (`stage1/rec/stages`), `RecordTie` (`stage1/rec/names`) | - |
| `$8BEB` | `MultiplyJump` | 2 | The operand of MultiplyEnd's JP: `$93B1` once patched (zeros in the image) | `Mover` | `DrawRoad` |
| `$8BED` | `MenuLayout` | 17 of 105 | The menu's texts as PrintList draws them: count 4, then (line, column, attribute, length) each. ENDURO RACER, FROM SEGA, # 1987 ACTIVISION, START GAME (MenuTexts). src/res/texts/menu.txt has the texts. | `MenuSelect`, `Mover`, `PrintList` | - |
| `$8BFE` | `MenuLayout2` (`MenuLayout`+17) | 17 | CHANGE CONTROL MODE, DEFINE KEYS, SPACE OR FIRE TO EXECUTE, ANY OTHER KEY TO ADVANCE | `Mover`, `PrintList` | - |
| `$8C0F` | `MenuItems` (`MenuLayout`+34) | 17 | MenuSelect's list: START GAME, ONE PLAYERS, CHANGE CONTROL MODE, DEFINE KEYS | `MenuSelect`, `Mover` | - |
| `$8C20` | `ControlItems` (`MenuLayout`+51) | 21 | the five methods (PrintList and MenuSelect) | `MenuSelect`, `Mover`, `PrintList` | - |
| `$8C35` | `DefineItems` (`MenuLayout`+72) | 33 | EXIT and the seven keys | `MenuSelect`, `Mover`, `PrintList` | - |
| `$8C56` | `MenuTexts` | 48 of 243 | The menu's texts, one after another as PrintList and PrintString take them | `Mover`, `PrintString`, `DrawCursor` (`stage1/rec/names`), `DrawFrame` (`stage1/rec/stages`) | - |
| `$8C86` | `PlayerCountTexts` (`MenuTexts`+48) | 14 | ONE, TWO, " PLAYERS" (7 characters for one player, the S then blanked) | `Mover`, `PrintString` | - |
| `$8C94` | `MenuTexts2` (`MenuTexts`+62) | 80 | CHANGE CONTROL MODE ... ADVANCE | `Mover`, `PrintString` | - |
| `$8CE4` | `ControlTexts` (`MenuTexts`+142) | 49 | KEYBOARD, KEMPSTON, SINCLAIR RIGHT, SINCLAIR LEFT, CURSOR | `Mover`, `PrintString` | - |
| `$8D15` | `DefineTexts` (`MenuTexts`+191) | 44 | EXIT, THROTTLE, WHEELIE, LEFT, RIGHT, BRAKES, PAUSE, RESET | `Mover`, `PrintString` | - |
| `$8D41` | `Blanks` (`MenuTexts`+235) | 8 | eight spaces: blanking, and a blank frame for DrawCursor | `Mover`, `PrintString`, `DrawCursor` (`stage1/rec/names`), `DrawFrame` (`stage1/rec/stages`) | - |
| `$8D49` | `CreditList` | 13 | The credits: count 4, then (length, attribute, ScrollUp steps) each. 22 characters `$45` then 48 steps, 23 `$46` 48, 24 `$44` 28, 17 `$43` 40. | `Attract`, `Mover`, `Init` (`stage1/rec/m128`) | - |
| `$8D56` | `CreditTexts` | 86 | ENDURO RACER FROM SEGA, PRESENTED BY ACTIVISION, PROGRAMMED BY GIGA GAMES, GRAPHICS BY FOCUS | `Mover`, `PrintString` | - |
| `$8DAC` | `HudLayout` | 25 | The HUD's texts: count 6, (line, column, attribute, length): TOP, STAGE, SPEED, K<> (km/h), SCORE, TIME | `Mover`, `PrintList` | - |
| `$8DC5` | `HudTexts` | 29 | TOP STAGE SPEED K<> SCORE TIME, then NAME (ShowScores takes SCORE, TIME and NAME) | `Mover`, `PrintString` | - |
| `$8DE2` | `HiScores` | 110 | The high score table: five rows of score (7), name (8), total time (7). 1000000 ENDURO 3'00"00, 800000 RACER 2'30"00, 600000 SEGA 2'00"00, 400000 A'VISION 1'30"00, 200000 GIGA1987 1'00"00. src/res/tables/hiscores.csv. A recording's run in the stages recording entered a row (WALKTHROUGH 6.2). | `Mover`, `PlayTurn`, `PrintString` | `PlayTurn` (`stage1/rec/stages`), `RecordTie` (`stage1/rec/names`) |
| `$8E56` | `LeanTable` | 7 | The steering force of each lean (-3 to 3): `$AD` `$50` `$28` `$00` `$28` `$50` `$AD` (BikeControl, sign from the lean) | `BikeControl`, `Mover`, `GetUpSlide` (`stage1/rec/stages`) | - |
| `$8E5D` | `SteerTable` | 21 of 32 | The steering force at each speed: index ScrollStep's high byte * 2 (0-20), 21 bytes. BikeControl reads `$8E5D` + 2 * (ScrollStep >> 8); the speed is at most 199, the step at most `$AE2`, so the index stays at or below 20 and only every second byte is read; except under the cheat: ScrollStep `$1000` gives index 32, `$8E7D`, past SteerTail, the opcode `$06` of render.asm's first LD B,`$80` (full lean 0.5 pixel a pass, a game bug). | `BikeControl`, `Mover`, `GetUpSlide` (`stage1/rec/stages`) | - |
| `$8E72` | `SteerTail` (`SteerTable`+21) | 11 | 11 bytes past the reachable index: the descending series goes on (`$2A` ... `$1B`); reset3's crash ran through them as code | `Mover` | - |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9111` | `RiderStarts` | 22 | The six riders' starts: x, acceleration, top speed, the lowest pose in a bend (the sixth's last two bytes are BikePoses' first). StartRace copies 4 bytes a rider; the sixth reads `$9127-$9128` (6, `$3A`), shared with BikePoses' first entry. | `Mover`, `StartRace` | - |
| `$917E` | `RiderSprites` | 147 | Seven distance bands: the row threshold, then five poses' descriptors (rows \| bit 7: never mirrored, width \| bit 7 aligned, address). src/res/tables/riders.csv; the sprites in src/res/sprites/. | `DrawMirrored`, `DrawRiders`, `Mover` | - |
| `$975B` | `ObjectTypes` | 16 | The eight object types' descriptor lists (type * 2 indexes it). Each list: the farthest row drawn, the row below which the sprite is byte-aligned (DrawSprite), then 6-byte entries: the row threshold, the y offset, rows, width, the address. src/res/tables/objects.csv; src/res/sprites/ draws each. | `Mover`, `RacePass` | - |
| `$976B` | `ObjectList4` | 38 of 388 | Type 4's list. The lists follow each other (`$976B` type 4, `$9791` type 5, `$97C9` type 1, `$97F5` type 6, `$9821` type 2, `$9859` type 0, `$988B` type 3, `$98BD` type 7). | `DrawObject`, `Mover` | - |
| `$9791` | `ObjectList5` (`ObjectList4`+38) | 56 | type 5 | `Mover`, `DrawObject` (`stage1/rec/stages`) | - |
| `$97C9` | `ObjectList1` (`ObjectList4`+94) | 44 | type 1 | `DrawObject`, `Mover` | - |
| `$97F5` | `ObjectList6` (`ObjectList4`+138) | 44 | type 6 | `Mover`, `DrawObject` (`stage1/rec/stages`) | - |
| `$9821` | `ObjectList2` (`ObjectList4`+182) | 56 | type 2 | `DrawObject`, `Mover` | - |
| `$9859` | `ObjectList0` (`ObjectList4`+238) | 50 | type 0, the ramp | `DrawObject`, `Mover` | - |
| `$988B` | `ObjectList3` (`ObjectList4`+288) | 50 | type 3 | `Mover`, `DrawObject` (`stage1/rec/stages`) | - |
| `$98BD` | `ObjectList7` (`ObjectList4`+338) | 50 | type 7 | `DrawObject`, `Mover` | - |
| `$A0F3` | `DustOffsets` | 10 | The splash's and dust's x offset per pose and lean (10 bytes, signed) | `Mover`, `DrawDust` (`stage1/rec/stages`) | - |
| `$A21F` | `MoveRidersIx` | 1 | The `$DD` prefix of LD IX,`$5C80` (run once); the loop re-enters at `$A220`, where the same bytes read LD HL,`$5C80`. L1 has `$A21F` executed in every recording; the kit keeps it as a byte because two instructions share `$A220`. | `Mover` | - |

## bike

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9127` | `BikePoses` | 15 of 87 | The bike's sprites: rows, width (bit 7 aligned), address, then the wheel animation (count, width, offset, source; count bit 7: none). DrawBike reads BikePoses + 9 * n + 1 ... + 9 (the code's base `$9127`). Entries with no animation leave their last four bytes free, and the game keeps variables in them: ScrollStep, `$9138`, LateralX, TopClip, DrawnTop, FallTime, Wheelies, Pose, Lean, RoadTopRow, BikeX. | `AdvanceTrack`, `BikeControl`, `BikeRoadPlace`, `CopyBuffer`, `Crash` +28 | `BikeControl`, `BikeRoadPlace`, `Crash`, `DrawBike`, `DrawObject` +12 |
| `$9136` | `ScrollStep` (`BikePoses`+15) | 2 | SPEED * 14: the track's distance a pass (8.8) | `AdvanceTrack`, `BikeControl`, `DrawBike`, `Mover`, `RacePass` +8 | `StartRace`, `RacePass` (code) |
| `$9138` | `BendPtr` (`BikePoses`+17) | 7 | ScrollBends' profile pointer | `DrawBike`, `Mover`, `ScrollBends` | `ScrollBends` |
| `$913F` | `LateralX` (`BikePoses`+24) | 45 | the bike's sideways place, 8.8 (`$9140` the whole part, `$5C-$A4` on the road's scale) | `BikeControl`, `BikeRoadPlace`, `Crash`, `DrawBike`, `DrawMirrored` +6 | `BikeControl`, `StartRace`, `GetUpSlide` (`stage1/rec/stages`), `l_AEB0` (code) |
| `$916C` | `TopClip` (`BikePoses`+69) | 1 | the highest line drawn this pass (CopyBuffer starts there) | `CopyBuffer`, `DrawBike`, `DrawHorizon`, `DrawObject`, `DrawRiders` +4 | `DrawBike`, `DrawObject`, `DrawRiders`, `RampSpeed`, `StartRace` +2 |
| `$916D` | `DrawnTop` (`BikePoses`+70) | 1 | last pass's TopClip | `CopyBuffer`, `Mover` | `RampSpeed`, `StartRace`, `HudPlayer` (`stage1/rec/m128`), `RiderBounce` (`stage1/rec/truck`) |
| `$916E` | `FallTime` (`BikePoses`+71) | 1 | a fall's count (bit 7: the side), 0 riding | `BikeControl`, `BikeRoadPlace`, `Mover`, `RampSpeed`, `GetUpSlide` (`stage1/rec/stages`) +4 | `BikeControl`, `Crash`, `StartRace` |
| `$916F` | `Wheelies` (`BikePoses`+72) | 6 | passes with WHEELIE held | `BikeControl`, `DrawBike`, `Mover`, `RacePass`, `GetUpSlide` (`stage1/rec/crash`) | `BikeControl`, `StartRace`, `GetUpSlide` (`stage1/rec/stages`), `l_AECC` (code) |
| `$9175` | `Pose` (`BikePoses`+78) | 1 | the bike's pose | `BikeControl`, `DrawBike`, `Mover`, `RampSpeed`, `DrawDust` (`stage1/rec/stages`) +5 | `BikeControl`, `Crash`, `RacePass`, `StartRace`, `GetUpSlide` (`stage1/rec/stages`) +2 |
| `$9176` | `Lean` (`BikePoses`+79) | 1 | the lean, -3 to 3 | `BikeControl`, `DrawBike`, `Mover`, `RampSpeed`, `DrawDust` (`stage1/rec/stages`) +4 | `BikeControl`, `StartRace`, `GetUpSlide` (`stage1/rec/stages`), `l_AECC` (code) |
| `$9177` | `RoadTopRow` (`BikePoses`+80) | 1 | RoadLines[127] - `$71` (RowTable's first road line - `$70`); `$FF` breaks DrawRoad (the stage 3 reset) | `DrawRoad`, `GroundTexture`, `Mover`, `GapRows` (`stage1/rec/stages`), `RoadRowsOld` (code) | `RoadRowsFlat`, `StartRace` |
| `$9178` | `BikeX` (`BikePoses`+81) | 6 | the bike's screen x (`$80` the centre) | `DrawBike`, `Mover`, `DrawDust` (`stage1/rec/stages`), `DustPlace` (code) | `BikeRoadPlace` |
| `$A1C9` | `BounceTime` | 1 of 3 | A bounce's passes left (3, or 6 after a landing) | `BikeControl`, `Mover`, `RacePass`, `RampSpeed`, `GetUpSlide` (`stage1/rec/stages`) +4 | `BikeControl`, `RacePass`, `RampSpeed`, `StartRace`, `GetUpSlide` (`stage1/rec/stages`) +2 |
| `$A1CA` | `BounceDir` (`BounceTime`+1) | 1 | the bounce's push: 8 right, 4 left, 0 random | `BikeControl`, `Mover`, `GetUpSlide` (`stage1/rec/stages`) | `BikeControl`, `RacePass`, `RampSpeed`, `GetUpSlide` (`stage1/rec/stages`), `l_A894` (code) +1 |
| `$A1CB` | `BikeHitX` (`BounceTime`+2) | 1 | the bike's x for the collisions (`$82` + LateralX * `$C0` / 256) | `Mover`, `RacePass`, `RampSpeed` | `StartRace`, `RacePass` (`stage1/rec/fall5`) |

## horizon

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9316` | `MaskTable` | 8 | Eight left-edge masks (`$00`, `$80`, `$C0` ... `$FE`), read by no instruction. Known only from the code: no operand points here and L1 has no read after the load; DotMasks (`$9CAF`) is the table the game uses. | `Mover` | - |
| `$9A7F` | `RotateTable` | 18 | Six entries (offset, routine): right 8, 4, 1 (RotateBytesRight `$1F`, RotateRight4, RotateRight1); left 8, 4, 1 | `HorizonRotate`, `HorizonScrollStep`, `Mover` | - |
| `$9E67` | `StageTable` | 20 | The five stages' horizons: the picture's address (a word), its lines, its top line (5 x 4 bytes). Mountains/32/`$50`, Clouds/9/`$53`, Dunes/25/`$57`, Mountains/32/`$50`, Clouds/9/`$5A`. src/res/tables/stages.csv. | `Mover`, `SetHorizon` | - |

## road

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9CAF` | `DotMasks` | 8 | Eight bytes for GroundTexture's dots (`$FF` `$7F` `$3F` `$1F` `$0F` `$07` `$03` `$01`): the entry for x AND 7, plus 1, is the dot's one pixel (`$80`, `$40`, ...; 0 for x AND 7 = 0, no dot) | `Mover`, `GroundTexture` (`stage1/rec/stages`) | - |
| `$A45B` | `RandomPtr` | 2 | GroundTexture's ROM pointer (`$0000-$1FFF`) | `Mover`, `GroundTexture` (`stage1/rec/stages`) | `GroundTexture` (`stage1/rec/stages`) |
| `$B11C` | `RowsScrolled` | 1 | The road rows the segment moved this pass (AdvanceTrack), for ScrollBends | `Mover`, `ScrollBends` | `AdvanceTrack` |

## race

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A15D` | `AyEffect` | 10 | The AY effect's five pairs: 7 = `$07` (noise on A, B, C), 6 = `$1F`, volumes 8, 9, 10 = 15 | `AyPairs`, `Mover` | - |
| `$A187` | `StageParams` | 50 | The five stages' routines: road, row builder, off-road, the ground's attribute, the copy mode, 2 bytes unused. Stage 1: DrawRoad, RoadRowsCrest, OffRoad, `$20`; 2: the same, `$30`; 3: DrawRoad, RoadRowsJump, OffRoadSand, `$28`; 4: as 1, `$70`; 5: RoadNone, RoadRowsCrest, OffRoadStage5, `$30`. Byte 7 (BlitMode's JR) is 0 on all. src/res/tables/stageparams.csv. | `Mover`, `StartRace` | - |
| `$A1B9` | `CollisionSizes` | 16 | Each object type's half width and height for the bike's collision (8 types): the ramp `$20` x 1 .... Type 0 (ramp) 32 x 1, 1: 5 x 6, 2: 10 x 32, 3: 8 x 32, 4: 14 x 8, 5: 8 x 24, 6: 11 x 12, 7: 11 x 30. A hit within half the width is head-on (a fall at 35 km/h or more), else side-on (a bounce). | `Mover`, `RacePass` | - |
| `$A1CC` | `ExtendedText` | 13 | EXTENDED PLAY (13 characters, flashed after a stage's end) | `Mover`, `PrintString` (`stage1/rec/stages`) | - |
| `$A8D6` | `DemoText` | 4 | DEMO | `Mover`, `PrintString` | - |
| `$A9C2` | `PauseJump` | 1 | The `$28` of JR Z,Pause; its operand `$08` is EX AF,AF' at `$A9C3`, where a demo's key jumps. L1 has `$A9C2` executed in every recording and `$A9C3` in c1, ctl and m128 (the demo ended by a key); the kit keeps `$A9C2` as a byte because two instructions share `$A9C3`. | `Mover` | - |


## The first BASIC "enduro" and Stage0 (`src/tape/basic1.json`)

Enduro Racer, Activision 1987: tape block 2, the BASIC program "enduro" (205 bytes at PROG `$5CCB`, LINE 0). Its
entries are `src/tape/<module>.asm`, written from `src/tape/basic1.ann` by `kit/mkgame.py --part
src/tape/basic1.json`; the readers and writers from `work/stage1/rec/c1`.

### The first BASIC "enduro" and Stage0: basic1

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine0` | 53 of 74 | Line 0: PAPER 0: INK 0: BORDER 0: CLS: PRINT USR "6746931" (23829): LOAD "". The line number high byte first, the length (53) low byte first, the tokens, `$0D`. Read by the ROM's interpreter in c1; no machine code reads it. | - | - |
| `$5D00` | `BasicLine1` (`BasicLine0`+53) | 13 | the bytes after line 0: number 65152, length 65535 (LIST stops at the end of the program) | - | - |
| `$5D0D` | `StubBytes` (`BasicLine0`+66) | 8 | DI / PUSH HL / PUSH AF / EXX / CALL `$5B14` / RET: bytes LIST shows, unused by Stage0 | - | - |
| `$5D74` | `Stage0Data` | 13 of 36 | The copy's tail: at `$FFF8` the return `$1B76`, at `$FFFA` the error return `$1303` | `Stage0Copy` | - |
| `$5D81` | `BasicTail` (`Stage0Data`+13) | 23 | past the copy: the rest of the 205 bytes, never read | - | - |


## The second BASIC "end2" and Chain1 (`src/tape/basic2.json`)

Enduro Racer, Activision 1987: tape block 4, the BASIC program "end2" (1770 bytes at PROG `$5CCB`, LINE 0), its
variables area the first decoder Chain1 and the enciphered loader. Its entries are `src/tape/<module>.asm`, written
from `src/tape/basic2.ann` by `kit/mkgame.py --part src/tape/basic2.json`; the readers and writers from
`work/stage1/rec/c1`.

### The second BASIC "end2" and Chain1: basic2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine0a` | 132 | Line 0: REM "Protected by SPEEDLOCK" in colour codes (length 128). Read by the ROM's interpreter in c1; no machine code reads any line. | - | - |
| `$5D4F` | `BasicLine0b` | 67 | Line 0: BORDER 0: PAPER 0: INK 0: BRIGHT 1: CLS: POKE 23624,0 (BORDCR) | - | - |
| `$5D92` | `BasicLine0c` | 132 | Line 0: POKE (PEEK 23641+256*PEEK 23642),PEEK 23649 and +1,PEEK 23650: E_LINE's word = WORKSP | - | - |
| `$5E16` | `BasicLine0d` | 132 | Line 0: the same POKEs shown as 23633/23634/23647/23648, hidden 23613/23614/23627/23628: (ERR_SP) = VARS. The shown digits are decoys; the five-byte numbers the interpreter uses are ERR_SP (23613) and VARS (23627). ERR_SP is `$FFFA` (Stage0), VARS is `$621A`: the ROM's POKE writes `$1A`,`$62` to `$FFFA-$FFFB` (c1 frames 1557-1562). | - | - |
| `$5E9A` | `BasicLine0e` | 98 | Line 0: POKE 23662,PEEK 23618: POKE 23663,PEEK 23619: POKE 23664,PEEK 23621 (OLDPPC, OSPPC = NEWPPC, NSPPC) | - | - |
| `$5EFC` | `BasicLine6` | 1 | The sixth line's number high byte (`$9C`): 40079 with LoaderTape's first byte | - | - |
| `$5EFD` | `LoaderTape` | 797 | The loader as the tape holds it (797 bytes): Chain1 XORs it with R into `$FCA3-$FFBF`. src/loader/loader.asm is its plain view; tools/speedlock2.py tape turns that view back into these bytes, and tools/build.sh checks the whole tape against the original. Read by Chain1Loop in c1 (frames 1575-1576); the interpreter also reads its first bytes as the sixth line's header and raises the error. | `Chain1` | `Chain1` |
| `$62BE` | `Chain1Tail` | 247 | The bytes after the loop: a few junk bytes and the SPEEDLOCK credit, never run or read. "SPEEDLOCK Protection System (c) DJL Software & D. Aubrey Jones 1984 - Tel:0793 724317 * Government Health Warning - Attempting to crack SPEEDLOCK can damage your sanity! *" then repeated fragments of the same bytes up to the block's end. A leftover the loader never reads (c1: no read after the ROM's load). | - | - |


## The loader: Chain2, Chain3 and the SpeedLock 2 loader (`src/loader/loader.json`)

Enduro Racer, Activision 1987: the loader `$FCA3-$FFBF` as each byte runs (the plain view; tools/speedlock2.py tape
enciphers it into the second BASIC's `$5EFD-$6219`). Its entries are `src/loader/<module>.asm`, written from
`src/loader/loader.ann` by `kit/mkgame.py --part src/loader/loader.json`; the readers and writers from
`work/stage1/rec/c1`.

### The loader: Chain2, Chain3 and the SpeedLock 2 loader: loader

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$FF36` | `LoadFailed` | 1 | Nonzero after a bad end mark (`$7F`) or a bad probe (1); LoaderStart crashes on it | `Chain2`, `Chain3`, `l_FF41` (code) | `Chain2`, `Chain3`, `l_FE6C` (code), `l_FF32` (code) |
| `$FF85` | `SyncCounts` | 4 | The four sync groups: each the negated count of short pulses before a long one | `Chain2`, `Chain3`, `LoadBlock` | `Chain2`, `Chain3`, `LoadBlock` |
| `$FF89` | `BlockTable` | 53 | The blocks after the screen: address, length - 1, page; 10 rows and an end row. Row n is TZX block n + 6 (doc 03): `$70C8` `$11FF`, `$A0C8` `$0FFF`, `$FE04` 1 (the new Store key), `$FE3C` 3 (the new StoreLast key), `$5BC8` `$14FF`, `$FF63` `$16` (the new tail), `$B0C8` `$4957`, `$FF7A` `$0C` (the new end), `$5B00` `$3F` (Mover), `$82C8` `$0FFF`, then the end row (page 0): the last block follows at `$92C8`. The page is `$10` in every real row. | `Chain2`, `Chain3`, `LoadBlock` | `Chain2`, `Chain3` |
| `$FFBE` | `LoaderPad` | 2 | The two bytes after the table, inside the enciphered range (`$FFBF` is Chain3's first C) | `Chain2`, `Chain3`, `LoadBlock` | `Chain2`, `Chain3` |


## The loader's end as blocks 12 and 14 rewrite it (`src/loader/tail.json`)

Enduro Racer, Activision 1987: `$FF63-$FF86` as tape blocks 12 and 14 load it over the loader's own end. Its entries
are `src/loader/<module>.asm`, written from `src/loader/tail.ann` by `kit/mkgame.py --part src/loader/tail.json`;
the readers and writers from `work/stage1/rec/c1`.
