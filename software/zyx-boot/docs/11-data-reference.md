# 11. Data reference

Every data entry of the main program's image `$61A8`-`$ADFF`, in address order by module (`src/main/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/main/main.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: The BASIC loader (sector 0 of boot), The music: ASC Sound Master
player and tune (src/music)) follow the main program, each under its own heading with its modules, its source, its
annotations and its recordings.

## rhombi

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6ADD` | `PhaseOrder` | 32 | The rhombus phase shown at each of the 32 steps of a turn. Read by PrintRombPhase `$64DA`. | `PrintRombPhase` | - |
| `$6B74` | `RombColumnOrder` | 40 | The 40 rhombus columns in the order the phases keep them (5 fewer a phase). Copied to RombColumns `$7600` by Start. | `Start` | - |
| `$6B9C` | `RombPhaseOffsets` | 9 | Per phase, where its narrowed rhombus starts (the pixel column). Copied to RombOffsets `$765C` by Start. | `Start` | - |
| `$6E98` | `RombSource` | 200 | The rhombus: 40x40, 5 bytes a row. Printed by DrawScreen and copied to RombWork by Start. | `PrintSprite`, `Start` | - |

## stars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6F60` | `TwinkleSprites` | 128 | The 4 twinkle frames: 16x16, 2 bytes a row. Read by DrawTwinkle. | `DrawTwinkle` | - |
| `$6FE0` | `TwinkleSpare` | 200 | Zeros to the 15th sector's end: loaded, not read. No instruction in c1-c4 reads them. In many variants they hold other bytes (leftovers of the memory the piece was saved from). | - | - |

## font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6AFD` | `MenuHelp` | 68 | The help lines: SPACE  TO NEW DISK, "SS" TO NEXT PAGES, "CS" TO FIRST PAGE (rows 19-21). Printed by DrawScreen `$6510` (c1: the screen from the first menu frame). | `PrintString` | - |
| `$6B41` | `NoFilesText` | 18 | NO EXE FILES ! at row 11, column 9. Printed by ListCatalogue `$65C7` when the page lists no file (c1 on the original disk, c4). | `PrintString` | - |

## catalogue

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6B6B` | `BootName` | 9 | "boot    B": the name and type IsBootFile never lists | `IsBootFile` | - |

## keys

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6B53` | `KeyTable` | 24 | The letters A-X: the half-row (bits 7-5) and the key's bit mask (bits 4-0). Read by ReadKeyboard `$6864`. | `ReadKeyboard` | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6E64` | `ExitSound` | 14 | The bell: AY registers 0-13. Read by PlayBell. | - | - |

## buffers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$70A8` | `Unused1` | 1368 | Not written: SoundOff reads its zeros at `$7530` | `WriteAY` | - |
| `$7600` | `RombColumns` | 92 | RombColumnOrder's copy (40) | `BuildRombPhases` | `Start` |
| `$765C` | `RombOffsets` | 50 | RombPhaseOffsets's copy (9) | `ClearPhaseMask` | `Start` |
| `$768E` | `RombThreshold` | 10 | Phase 8's threshold: `$40` for set A, `$80` for set B | `BuildRombPhases` | `Start` |
| `$7698` | `PhaseMask` | 40 | 40 bytes: 1 for each column the phase keeps | `ClearPhaseMask`, `ScaleRombLine` | `ClearPhaseMask`, `MarkPhaseColumn` |
| `$76C0` | `PhaseOffset` | 1 | The phase's start column | `ScaleRombLine` | `ClearPhaseMask` |
| `$76C1` | `Unused2` | 63 | Not used | - | - |
| `$7700` | `RombWork` | 200 | The rhombus being turned (200) | `RotateSprite`, `ScaleRombLine` | `RotateSprite`, `Start` |
| `$77C8` | `Unused3` | 56 | Not used | - | - |
| `$7800` | `PhasesA` | 2304 | Set A (turning about the vertical axis): phases 0-8, 256 bytes each | `MirrorSprite`, `PrintSprite`, `ScaleRombLine` | `ScaleRombLine` |
| `$8100` | `MirrorsA` | 2048 | Set A: phases 9-16, the mirror images of 0-7 | `PrintSprite` | `MirrorSprite` |
| `$8900` | `Unused4` | 256 | Not used | - | - |
| `$8A00` | `PhasesB` | 2304 | Set B (turning about the horizontal axis): phases 0-8 | `MirrorSprite`, `PrintSprite`, `RotateSprite`, `ScaleRombLine` | `RotateSprite`, `ScaleRombLine` |
| `$9300` | `MirrorsB` | 2048 | Set B: phases 9-16 | `PrintSprite`, `RotateSprite` | `MirrorSprite`, `RotateSprite` |
| `$9B00` | `Unused5` | 256 | Not used | - | - |
| `$9C00` | `RotateBuffer` | 200 | RotateSprite's work (200) | `RotateSprite` | `RotateSprite` |
| `$9CC8` | `Unused6` | 56 | Not used | - | - |
| `$9D00` | `Catalogue` | 2048 | The disk's catalogue: track 0 sectors 0-7, 128 entries of 16 bytes | `IsBootFile`, `ListCatalogue` | - |
| `$A500` | `FontBase` | 256 | Not used: Chars points here (Font - 256) | - | - |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A600` | `Font` | 768 | The font: 96 characters of 8 bytes, space to the copyright sign. Chars `$5C36` = `$A500` while the menu prints (DrawScreen). | - | - |
| `$A900` | `Logo` | 200 of 800 | The ZYX logo: four 40x40 sprites (the Z takes two). Printed by DrawScreen at `$4006`, `$400B`, `$4010`, `$4015`; flipped by DrawReflection. | `MirrorSprite`, `PrintSprite`, `RotateSprite` | `MirrorSprite`, `RotateSprite` |
| `$A9C8` | `LogoPart2` (`Logo`+200) | 200 | - | `MirrorSprite`, `PrintSprite`, `RotateSprite` | `MirrorSprite`, `RotateSprite` |
| `$AA90` | `LogoPart3` (`Logo`+400) | 200 | - | `MirrorSprite`, `PrintSprite`, `RotateSprite` | `MirrorSprite`, `RotateSprite` |
| `$AB58` | `LogoPart4` (`Logo`+600) | 200 | - | `MirrorSprite`, `PrintSprite`, `RotateSprite` | `MirrorSprite`, `RotateSprite` |
| `$AC20` | `LogoAttributes` | 100 | The logo's attributes: 5 rows of 20 cells. Copied to `$5806` by DrawScreen. | `DrawScreen` | - |
| `$AC84` | `StarsA` | 120 of 360 | The falling stars: three tables of 20 records of 6 bytes. Read by SampleStars and MoveStars. | `MoveStars`, `SampleStar` | `MoveStars`, `SampleStar` |
| `$ACFC` | `StarsB` (`StarsA`+120) | 120 | - | `MoveStars`, `SampleStar` | `MoveStars`, `SampleStar` |
| `$AD74` | `StarsC` (`StarsA`+240) | 120 | - | `MoveStars`, `SampleStar` | `MoveStars`, `SampleStar` |
| `$ADEC` | `Randoms` | 8 | 8 random bytes: the twinkles' places (NewRandoms refills them) | `CheckTwinkleSpot`, `EraseTwinkle`, `NewRandoms` | `NewRandoms` |
| `$ADF4` | `CornerColours` | 5 | The corner gradients' five attributes. Read by ColourCornerRows and ColourCornerColumns. | `ColourCornerColumns`, `ColourCornerRows` | - |
| `$ADF9` | `GraphicsSpare` | 7 | Zeros to the 8th sector's end: loaded, not read | - | - |


## The BASIC loader (sector 0 of boot) (`src/basic/basic.json`)

ZYX boot: sector 0 of the file boot (B, 180 bytes, 46 sectors), the BASIC program TR-DOS loads at PROG `$5D3B`. Line
4's REM holds the loader, entered at `$5D80` by line 10's RANDOMIZE USR 23936. Its entries are
`src/basic/<module>.asm`, written from `src/basic/basic.ann` by `kit/mkgame.py --part src/basic/basic.json`; the
readers and writers from `work/stage1/c1`.

### The BASIC loader (sector 0 of boot): basic

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5D3B` | `LaunchLine` | 17 of 30 | Line 1: RANDOMIZE USR VAL "15619": REM : RUN "        " (26 bytes): the launch line. Rewritten by the menu's launcher RunLetter `$6A51` just before it returns: the token at `$5D4C` (LaunchToken) becomes RUN (`$F7`) for a BASIC file or GO TO (`$EC`) for a 192-sector CODE file, the 8 characters at `$5D4E` (LaunchName) the file's name, and the byte at `$5D57` (LaunchSuffix) a space for RUN or the token CODE (`$AF`) for GO TO. Line 10's RUN then starts the program at this line, and TR-DOS runs the command. Witness: c2 ran TEST 03 and c3 ran TEST 30 after the menu wrote RUN "T03     " and RUN "T30     " here (the screens at the end of the recordings). | - | - |
| `$5D4C` | `LaunchToken` (`LaunchLine`+17) | 2 | the command token: RUN (`$F7`) in the image | - | - |
| `$5D4E` | `LaunchName` (`LaunchLine`+19) | 9 | the file name, 8 characters, spaces in the image | - | - |
| `$5D57` | `LaunchSuffix` (`LaunchLine`+28) | 2 | a space, or the token CODE (`$AF`) for a GO TO | - | - |
| `$5D59` | `LineTwo` | 19 | Line 2: RANDOMIZE USR VAL "15619": REM : RUN (15 bytes; not reached in any recording). A TR-DOS RUN without a name runs "boot" again. The program only gets here if line 1's command returns to BASIC without an error; no recording does. | - | - |
| `$5D6C` | `LineThree` | 15 | Line 3: RANDOMIZE USR VAL "15616" (11 bytes; not reached in any recording). USR 15616 enters TR-DOS's command line (the A> prompt). | - | - |
| `$5D7B` | `LineFour` | 5 | Line 4: the header (line number, length 71) and the REM token before the loader. The loader's code follows the REM token `$EA` at `$5D7F`; the line's `$0D` is at `$5DC5`. | - | - |
| `$5DC5` | `LineFourEnd` | 1 | Line 4's end (`$0D`) | - | - |
| `$5DC6` | `LineTen` | 41 | Line 10: BORDER NOT PI: PAPER NOT PI: INK VAL "7": CLEAR VAL "65347": RANDOMIZE USR VAL "23936": RUN. The autostart line: black border and paper, white ink, RAMTOP `$FF43` (the menu's stack `$FCBC` and IM 2 table `$FD00-$FE00` lie below it), the loader `$5D80`, then RUN, which clears the variables and runs line 1. | - | - |
| `$5DEF` | `AutostartMark` | 4 | The program's end (`$80`) and TR-DOS's autostart mark: `$AA` and the line, 10. TR-DOS writes the line number after `$AA` when a program is saved with LINE; RUN "boot" starts the program there. | - | - |
| `$5DF3` | `SectorTail` | 72 | The sector's leftover bytes after the program: not loaded, not read. 72 bytes that were in memory after the program when it was saved: `oot27" LINE 10` reads like the end of a `SAVE "boot27" LINE 10` statement, followed by number bytes and zeros. TR-DOS does not load them (it loads only the program and the autostart mark, `$5D3B-$5DF2`: at c1 frame 446 `$5E07-$5E3A` are zeros), and the Loader starts at the next sector, so they stay on the disk; the build reproduces them because the file holds them. A resource (spare/basic-tail.bin, bytes): in most variants they name another SAVE (`boot12`, `boot32`). | - | - |


## The music: ASC Sound Master player and tune (src/music) (`src/music/music.json`)

ZYX boot: the music piece at `$C000`, an ASC Sound Master compilation (player and tune) the menu calls at `$C00B`
(init) and from its interrupt at `$C00E` (play). Its entries are `src/music/<module>.asm`, written from
`src/music/music.ann` by `kit/mkgame.py --part src/music/music.json`; the readers and writers from `work/stage1/c1`.

### The music: ASC Sound Master player and tune (src/music): player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C000` | `PlayerVectors` | 8 | The compiled player's header: the init, play, AY-write and AY-register addresses. DEFW MusicInit `$C00B`, MusicPlay `$C00E`, WriteAY `$C15F`, AYRegisters `$C0F4`: the addresses a program using the compilation may take from the header. No instruction in c1-c4 reads them (the menu calls `$C00B` and `$C00E` directly). | - | - |
| `$C008` | `PlayerHeaderBytes` | 3 | Three more bytes of the compilation's header: `$80`, `$54`, `$1E`. No instruction in c1-c4 reads them and the player's code does not refer to them (known only from the code); their meaning is not known. | - | - |
| `$C014` | `PlayerText` | 63 | "ASM COMPILATION OF DISCO MUSIC BY ANT P BY ANDREW SENDETSKI ASC". 63 bytes the compiler puts in the player: "ASM COMPILATION OF " (19), the tune's title "DISCO MUSIC BY ANT P" (20), " BY " (4), the author field "ANDREW SENDETSKI ASC" (20). No instruction in c1-c4 reads it; the menu never prints it. | - | - |
| `$C0A9` | `ChannelA` | 25 | Channel A's record (25 bytes). The record PlayFrame `$C104` hands to ChannelRow `$C1CE` and ChannelSound `$C2A0` in IX. +`$00` the flags: bit 0 the pattern stream goes on (cleared when the next byte is the `$FF` that ends it), bit 1 the sample ended (its X row: silence), bit 2 a note sounds (set by a note, cleared by off `$7F`), bit 3 released (set by `$7E`: the sample's loop no longer loops), bit 4 envelope mode (set by `$C0`, cleared by `$C1-$CF`), bit 5 the sample row's envelope bit. +`$01` the sample row's mixer bits (bit 0 tone off, bit 3 noise off). +`$02` the note (0-`$55`; the ornament adds to it). +`$03`/`$04` the tone offset (the sum of the sample's tone deltas since the note). +`$05` the noise base (`$D0`+n). +`$06` the noise period (the base plus the noise deltas, 0-31). +`$07` the volume of this frame. +`$08` the channel volume (`$C1-$CF`). +`$09` the row length (`$F0` n). +`$0A` the rows left of the current event. +`$0B`/`$0C` the stream pointer. +`$0D`/`$0E` the sample's start, +`$0F`/`$10` its row, +`$11`/`$12` its loop row. +`$13`/`$14` the ornament's start, +`$15`/`$16` its row, +`$17`/`$18` its loop row. Cleared by InitPlayer `$C053`, which sets the row counter +`$0A` (`$C0B3`) to 1. | `AddNoise`, `ChannelRow`, `ChannelSound`, `InitPlayer`, `NextPosition` +4 | `AddNoise`, `ChannelRow`, `InitPlayer`, `NextPosition`, `OrnamentStep` +2 |
| `$C0C2` | `ChannelB` | 25 | Channel B's record (25 bytes, as ChannelA). Its +`$01` (`$C0C3`) gives the mixer bits 1 and 4 (PlayFrame `$C104`). | `AddNoise`, `ChannelRow`, `ChannelSound`, `InitPlayer`, `NextPosition` +4 | `AddNoise`, `ChannelRow`, `InitPlayer`, `NextPosition`, `OrnamentStep` +2 |
| `$C0DB` | `ChannelC` | 25 | Channel C's record (25 bytes, as ChannelA). Its +`$01` (`$C0DC`) gives the mixer bits 2 and 5 (PlayFrame `$C104`). | `AddNoise`, `ChannelRow`, `ChannelSound`, `InitPlayer`, `NextPosition` +4 | `AddNoise`, `ChannelRow`, `InitPlayer`, `NextPosition`, `OrnamentStep` +2 |
| `$C0F4` | `AYRegisters` | 6 of 14 | The image of AY registers 0-13 that WriteAY sends. Written by SetAYRegister `$C17D` (E = the register), ChannelSound `$C2A0` (the noise), CommandLength `$C294` (the shape) and ChannelRow `$C1CE` (the envelope period); cleared by Silence `$C095`. | `InitPlayer`, `WriteAY` | `ChannelRow`, `ChannelSound`, `InitPlayer`, `PatternCommand`, `SetAYRegister` +3 |
| `$C0FA` | `AYNoise` (`AYRegisters`+6) | 1 | register 6: the noise period (the last channel whose sample row has noise on) | `InitPlayer`, `WriteAY` | `ChannelSound`, `InitPlayer` |
| `$C0FB` | `AYMixer` (`AYRegisters`+7) | 4 | register 7: the mixer, from the three channels' +`$01` bits | `InitPlayer`, `WriteAY` | `InitPlayer`, `SetAYRegister`, `Silence` (code) |
| `$C0FF` | `AYEnvelopePeriod` (`AYRegisters`+11) | 2 | register 11: the envelope period's low byte (the byte after a note in envelope mode); register 12 stays 0 | `InitPlayer`, `WriteAY` | `ChannelRow`, `InitPlayer` |
| `$C101` | `AYEnvelopeShape` (`AYRegisters`+13) | 1 | register 13: the envelope shape (`$F1-$FF` sets 1-15); `$FF`: no new shape, not written | `WriteAY` | `InitPlayer`, `PatternCommand`, `WriteAY`, `CommandLength` (code) |
| `$C102` | `CurrentChannel` | 1 | The channel ChannelSound is working on: 0 A, 1 B, 2 C. Set by ChannelSound `$C2A0` from A; it selects the registers (2 x channel, 8 + channel). | `ChannelSound` | `ChannelSound` |
| `$C103` | `DelayCounter` | 1 | Frames left to the next row. PlayFrame `$C104` decrements it each frame and reads a row when it reaches 0, then sets it to the delay (DelayOp `$C10A`: 6). InitPlayer `$C053` sets it to 1. | `PlayFrame` | `InitPlayer`, `PlayFrame` |
| `$C3CA` | `PeriodTable` | 172 | The AY tone period of each note 0-`$55` (86 notes, A#0 to B7). Read by ChannelSound `$C2A0`. At the 128K's AY clock of 1.7734 MHz note n is MIDI n + 22 (note 0 = `$0EDC`, A#0, 29.1 Hz; note 2 = C1), within 1 cent up to the fifth octave and up to 33 cents off at the top, where the periods are small. | `ChannelSound` | - |
| `$C476` | `PeriodPad` | 2 | Two zero bytes after the table: a note `$56` would read them, but the player clamps the note to `$55`. Known only from the code: no instruction reads them. | - | - |

### The music: ASC Sound Master player and tune (src/music): tune

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C478` | `TuneHeader` | 8 | The module's header: delay, the three table offsets, the number of positions. Read by InitPlayer `$C053`: the delay (6), the pattern table (+`$001E`: `$C496`), the sample table (+`$0BFC`: `$D074`), the ornament table (+`$1077`: `$D4EF`), 22 positions. No loop byte: NextPosition `$C191` loops to position 0. | `InitPlayer`, `ReadOffset` | - |
| `$C480` | `TunePositions` | 22 | The 22 positions: the pattern of each. 0 1 2 3 3 4 4 5 5 6 6 7 8 9 9 10 11 12 13 15 1 14. Read by NextPosition `$C191` (c1 reads positions 0-20). | `NextPosition` | - |
| `$C496` | `PatternTable` | 96 | 16 patterns: the offsets of the streams of channels A, B and C from this table. Read by NextPosition `$C191` (6 x the pattern). | `ReadOffset` | - |
| `$C4F6` | `PatternData` | 21 of 2942 | The 48 channel streams (pattern 0 first): commands, events, `$FF` at each stream's end. Read by ChannelRow `$C1CE` and PatternCommand `$C24C`. Pattern 14 (position 21) is read in no recording. | `ChannelRow`, `PatternCommand` | - |
| `$C50B` | `Pattern1` (`PatternData`+21) | 211 | pattern 1 (A `$C50B`, B `$C53A`, C `$C561`); each label is the pattern's stream A | `ChannelRow`, `PatternCommand` | - |
| `$C5DE` | `Pattern2` (`PatternData`+232) | 206 | - | `ChannelRow`, `PatternCommand` | - |
| `$C6AC` | `Pattern3` (`PatternData`+438) | 198 | - | `ChannelRow`, `PatternCommand` | - |
| `$C772` | `Pattern4` (`PatternData`+636) | 206 | - | `ChannelRow`, `PatternCommand` | - |
| `$C840` | `Pattern5` (`PatternData`+842) | 256 | - | `ChannelRow`, `PatternCommand` | - |
| `$C940` | `Pattern6` (`PatternData`+1098) | 193 | - | `ChannelRow`, `PatternCommand` | - |
| `$CA01` | `Pattern7` (`PatternData`+1291) | 193 | - | `ChannelRow`, `PatternCommand` | - |
| `$CAC2` | `Pattern8` (`PatternData`+1484) | 197 | - | `ChannelRow`, `PatternCommand` | - |
| `$CB87` | `Pattern9` (`PatternData`+1681) | 211 | - | `ChannelRow`, `PatternCommand` | - |
| `$CC5A` | `Pattern10` (`PatternData`+1892) | 210 | - | `ChannelRow`, `PatternCommand` | - |
| `$CD2C` | `Pattern11` (`PatternData`+2102) | 208 | - | `ChannelRow`, `PatternCommand` | - |
| `$CDFC` | `Pattern12` (`PatternData`+2310) | 210 | - | `ChannelRow`, `PatternCommand` | - |
| `$CECE` | `Pattern13` (`PatternData`+2520) | 210 | - | `ChannelRow`, `PatternCommand` | - |
| `$CFA0` | `Pattern14` (`PatternData`+2730) | 188 | - | - | - |
| `$D05C` | `Pattern15` (`PatternData`+2918) | 24 | - | `ChannelRow`, `PatternCommand` | - |
| `$D074` | `SampleTable` | 64 | 32 samples: their offsets from this table. Read by TableEntry `$C278` for a `$80-$9F` command. | `TableEntry` | - |
| `$D0B4` | `SampleData` | 3 of 1083 | The samples (sample 0 first): rows of 3 bytes (flags and noise, tone delta, mixer and volume). Read by SampleStep `$C308`. Samples 0, 11, 12 and 14-31 are one row with S, L and X: a steady tone at volume 15 that loops on itself until a release (`$7E`), then ends. The streams use samples 1-10 and 13. | `SampleStep` | - |
| `$D0B7` | `Sample1` (`SampleData`+3) | 75 | - | `SampleStep` | - |
| `$D102` | `Sample2` (`SampleData`+78) | 48 | - | `SampleStep` | - |
| `$D132` | `Sample3` (`SampleData`+126) | 36 | - | `SampleStep` | - |
| `$D156` | `Sample4` (`SampleData`+162) | 18 | - | `SampleStep` | - |
| `$D168` | `Sample5` (`SampleData`+180) | 54 | - | `SampleStep` | - |
| `$D19E` | `Sample6` (`SampleData`+234) | 18 | - | - | - |
| `$D1B0` | `Sample7` (`SampleData`+252) | 258 | - | `SampleStep` | - |
| `$D2B2` | `Sample8` (`SampleData`+510) | 18 | - | `SampleStep` | - |
| `$D2C4` | `Sample9` (`SampleData`+528) | 81 | - | `SampleStep` | - |
| `$D315` | `Sample10` (`SampleData`+609) | 84 | - | `SampleStep` | - |
| `$D369` | `Sample11` (`SampleData`+693) | 6 | samples 11 and 12: one row each | - | - |
| `$D36F` | `Sample13` (`SampleData`+699) | 330 | - | `SampleStep` | - |
| `$D4B9` | `Sample14` (`SampleData`+1029) | 54 | samples 14-31: one row each | - | - |
| `$D4EF` | `OrnamentTable` | 64 | 32 ornaments: their offsets from this table. Read by TableEntry `$C278` for an `$A0-$BF` command (through CommandOrnament `$C26B`). | `TableEntry` | - |
| `$D52F` | `OrnamentData` | 2 of 100 | The ornaments (ornament 0 first): rows of 2 bytes (flags and noise, note delta). Read by OrnamentStep `$C385`. Ornaments 0, 2, 10 and 11-31 are one row of no change; the streams use 1-10 and 13. | `OrnamentStep` | - |
| `$D531` | `Ornament1` (`OrnamentData`+2) | 8 | - | `OrnamentStep` | - |
| `$D539` | `Ornament2` (`OrnamentData`+10) | 2 | - | `OrnamentStep` | - |
| `$D53B` | `Ornament3` (`OrnamentData`+12) | 4 | - | `OrnamentStep` | - |
| `$D53F` | `Ornament4` (`OrnamentData`+16) | 8 | - | `OrnamentStep` | - |
| `$D547` | `Ornament5` (`OrnamentData`+24) | 4 | - | `OrnamentStep` | - |
| `$D54B` | `Ornament6` (`OrnamentData`+28) | 6 | - | - | - |
| `$D551` | `Ornament7` (`OrnamentData`+34) | 8 | - | `OrnamentStep` | - |
| `$D559` | `Ornament8` (`OrnamentData`+42) | 6 | - | `OrnamentStep` | - |
| `$D55F` | `Ornament9` (`OrnamentData`+48) | 8 | - | `OrnamentStep` | - |
| `$D567` | `Ornament10` (`OrnamentData`+56) | 2 | - | `OrnamentStep` | - |
| `$D569` | `Ornament11` (`OrnamentData`+58) | 42 | ornaments 11-31: one row each | `OrnamentStep` | - |
| `$D593` | `SectorTail` | 109 | 109 bytes after the module to the end of the 22nd sector: older stream bytes, not read. Leftovers of the memory the compilation was saved from (they read like a pattern stream: `$F0` `$0C`, notes, `$7E`, `$FF`, `$85` `$A5` `$CF` `$D0` `$F0` `$01` ...). Known only from the code: the player's pointers end at `$D592` and no instruction in c1-c4 reads these bytes. | - | - |
