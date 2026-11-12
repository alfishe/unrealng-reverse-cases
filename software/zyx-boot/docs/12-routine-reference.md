# 12. Routine reference

Every code entry of the main program, in address order by module (`src/main/<module>.asm`). The name, the title and
the description are the source's (`src/main/main.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/main/main.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: The BASIC loader (sector 0 of boot), The music: ASC Sound Master
player and tune (src/music)) follow the main program, each under its own heading with its modules, its source, its
annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`setup`](#setup) | `$61A8`-`$62F0` | 2 of 2 |
| [`rhombi`](#rhombi) | `$62F1`-`$645D`, `$64DA`-`$650F`, `$6ADD`-`$6AFC`, `$6B74`-`$6BA4`, `$6E98`-`$6F5F` | 9 of 13 |
| [`stars`](#stars) | `$645E`-`$64D9`, `$6BA5`-`$6CA1`, `$6F60`-`$70A7` | 8 of 10 |
| [`screen`](#screen) | `$6510`-`$671F`, `$6848`-`$6863`, `$6930`-`$6A3E` | 13 of 13 |
| [`font`](#font) | `$6720`-`$6736`, `$6AFD`-`$6B52` | 1 of 3 |
| [`catalogue`](#catalogue) | `$6737`-`$6756`, `$6B6B`-`$6B73` | 2 of 3 |
| [`interrupt`](#interrupt) | `$6757`-`$6847`, `$6CA2`-`$6CBE` | 5 of 5 |
| [`keys`](#keys) | `$6864`-`$692F`, `$6B53`-`$6B6A` | 1 of 2 |
| [`launcher`](#launcher) | `$6A3F`-`$6ADC` | 2 of 2 |
| [`fade`](#fade) | `$6CBF`-`$6D03`, `$6E72`-`$6E97` | 4 of 4 |
| [`logo`](#logo) | `$6D04`-`$6E40` | 7 of 7 |
| [`sound`](#sound) | `$6E41`-`$6E71` | 3 of 4 |
| [`buffers`](11-data-reference.md#buffers) | `$70A8`-`$A5FF` | 0 of 19 |
| [`graphics`](11-data-reference.md#graphics) | `$A600`-`$ADFF` | 0 of 7 |

## setup

`src/main/setup.asm`

### `Start` (`$61A8`)

**Save the caller's registers, read the catalogue, set up IM 2 and the music, draw the screen and build the rhombus phases**

Saves IY (SavedIY `$AFC8`), HL' (SavedHLAlt), SP (SavedSP) and I (SavedI). Reads 8 sectors from track 0, sector 0 (the catalogue) to Catalogue `$9D00` through TrdosEntry `$3D13`, still in IM 1. Then SP = MenuStack `$FCBC`, DI, Im2Table `$FD00` filled with `$FC`, JP Interrupt at Im2Jump `$FCFC`, IM 2 with I = `$FD`. CALL `$C00B` (the music's init, src/music), DrawScreen `$6510` (which also lists the catalogue), EI.

The rhombi: copies RombSource `$6E98` to RombWork `$7700`, RombColumnOrder to RombColumns `$7600` and RombPhaseOffsets to RombOffsets `$765C`; BuildRombPhases `$62F1` with threshold `$40` writes set A, phases 0-8 at PhasesA `$7800-$80FF`, and MirrorSprite `$63D6` the mirror images of phases 0-7 as phases 9-16 at MirrorsA `$8100-$88FF`. RotateSprite `$6422` three times turns RombWork by 270 degrees; BuildRombPhases (threshold `$80`) writes set B at PhasesB `$8A00`, MirrorSprite the mirrors at MirrorsB `$9300`, and RotateSprite turns each of the 17 sprites `$8A00-$9AFF` by 90 degrees: set A turns about the vertical axis, set B about the horizontal one.

DrawReflection `$6DC6` draws the logo's mirror image at the bottom; the four rhombus steps start at 0, 5, 8 and 14 (PhaseTopLeft `$B3B1`-PhaseBottomRight `$B3B4`), MainTick at `$FF`; SampleStars `$645E` reads the 60 stars' pixels; then falls into MainLoop.

Witness: L1 4 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 3,824,403 t-states own (0.69 %) |
| Runs (the other recordings) | 3 calls (`stage1/c2` 1, `stage1/c4` 1, `stage1/c3` 1) |
| Calls | `BuildRombPhases`, `MirrorSprite`, `RotateSprite`, `SampleStars`, `DrawScreen`, `DrawReflection` |
| Reads | `$6B74`-`$6BA4` (`RombColumnOrder`, `RombPhaseOffsets`); `$6E98`-`$6F5F` (`RombSource`); `$B3B0` (`work space $B3B0+`); `$FD00`-`$FDFE` (`work space $FD00+`) |
| Writes | `$6484`-`$6485` (`MoveStars+2`); `$7600`-`$7627` (`RombColumns`); `$765C`-`$7664` (`RombOffsets`); `$768E` (`RombThreshold`); `$7700`-`$77C7` (`RombWork`); `$AFC8`-`$AFCE` (`work space $AFC8+`); 2 more ranges |

### `MainLoop` (`$627C`)

**The main loop: the falling stars and the turning rhombi, as fast as the CPU runs**

MainTick `$B3B0` + 1 each pass. Every 2nd pass: MoveStars `$6482` twice on StarsA `$AC84` and twice on StarsB `$ACFC` (the operand MoveStars+2 set first). Every 4th: the top left rhombus (set A, at `$4000`, PhaseTopLeft) and the top right one (set B, at `$401B`, PhaseTopRight) one step (PrintRombPhase `$64DA`), and StarsC `$AD74` once. Every 8th: the bottom left rhombus (set B, at `$5060`) and the bottom right (set A, at `$507B`). No HALT: the loop never ends; Interrupt `$6757` does the rest (keys, music, twinkles, cursor) and the launcher leaves through the stack.

Witness: L1 27670 (c x4).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `MoveStars`, `PrintRombPhase` |

## rhombi

`src/main/rhombi.asm`

### `BuildRombPhases` (`$62F1`)

**Build phases 0-7 and the edge-on phase 8 of the rhombus in RombWork, at DE (256 bytes a phase)**

In: DE = the set's base (PhasesA `$7800` or PhasesB `$8A00`), RombThreshold `$768E`. For each phase (C = 8 down to 1) and each of the 40 rows: ClearPhaseMask `$633B` sets PhaseOffset `$76C0` = RombOffsets[C] and clears PhaseMask `$7698`; the first 5 x C entries of RombColumns mark their columns in PhaseMask (MarkPhaseColumn `$6354`); ScaleRombLine `$6364` writes the row. Each phase starts at the next 256 bytes (D + 1, E = 0).

Then phase 8 at DE: for each row k, `$18` at byte 2 when RombColumns[k] >= the threshold (never: see the module's header).

Witness: L1 8 (c x4).

[Animation: `BuildRombPhases` at work](img/routines/BuildRombPhases.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2 calls, 1,029,542 t-states own (0.18 %) |
| Runs (the other recordings) | 6 calls (`stage1/c4` 2, `stage1/c2` 2, `stage1/c3` 2) |
| Called from | `Start` |
| Calls | `ClearPhaseMask`, `MarkPhaseColumn`, `ScaleRombLine` |
| Reads | `$7600`-`$7627` (`RombColumns`); `$768E` (`RombThreshold`) |

### `ClearPhaseMask` (`$633B`)

**Clear PhaseMask and set PhaseOffset to RombOffsets[C]**

The offset's index is written into the LD A,(IY+d) at `$634D` (IY = RombOffsets `$765C`).

Witness: L1 2560 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 640 calls, 587,710 t-states own (0.11 %) |
| Runs (the other recordings) | 1,920 calls (`stage1/c4` 640, `stage1/c2` 640, `stage1/c3` 640) |
| Called from | `BuildRombPhases` |
| Reads | `$765D`-`$7664` (`RombOffsets+1`); `$7698`-`$76BE` (`PhaseMask`) |
| Writes | `$634F` (`ClearPhaseIndex+2`); `$7698`-`$76C0` (`PhaseMask`, `PhaseOffset`) |

### `MarkPhaseColumn` (`$6354`)

**PhaseMask[A] = 1: column A is kept in this phase**

The index is written into the LD (IX+d),1 at `$635D`.

Witness: L1 57600 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 14,400 calls, 1,224,323 t-states own (0.22 %) |
| Runs (the other recordings) | 43,200 calls (`stage1/c4` 14,400, `stage1/c2` 14,400, `stage1/c3` 14,400) |
| Called from | `BuildRombPhases` |
| Writes | `$635F` (`MarkPhaseWrite+2`); `$7698`-`$76BF` (`PhaseMask`) |

### `ScaleRombLine` (`$6364`)

**Copy one 40-pixel row of the rhombus to the phase: only the marked columns, packed, from PhaseOffset on**

In: HL = the source row, DE = the phase row, PhaseMask `$7698`, PhaseOffset `$76C0` (bits 7-3 the byte, 2-0 the pixel). For each of the 40 source pixels whose PhaseMask byte is 1, writes the pixel (SET or RES, the opcode built into the instruction at `$63AD`) at the next destination pixel. Returns HL and DE 5 bytes on (the next row).

Witness: L1 2560 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 640 calls, 4,807,672 t-states own (0.86 %) |
| Runs (the other recordings) | 1,920 calls (`stage1/c2` 640, `stage1/c3` 640, `stage1/c4` 640) |
| Called from | `BuildRombPhases` |
| Reads | `$7698`-`$76C0` (`PhaseMask`, `PhaseOffset`); `$7700`-`$77C7` (`RombWork`); `$7800`-`$7BC6` (`PhasesA`); `$7C01`-`$7CC6` (`PhasesA+1025`); `$7D01`-`$7DC6` (`PhasesA+1281`); `$7E01`-`$7EC6` (`PhasesA+1537`); 3 more ranges |
| Writes | `$6395` (`ScaleTestBit+3`); `$63B0` (`ScaleWriteBit+3`); `$7800`-`$7BC6` (`PhasesA`); `$7C01`-`$7CC6` (`PhasesA+1025`); `$7D01`-`$7DC6` (`PhasesA+1281`); `$7E01`-`$7EC6` (`PhasesA+1537`); 3 more ranges |

### `MirrorSprite` (`$63D6`)

**Write the mirror image (left to right) of the 40x40 sprite at HL to DE**

Reverses the 5 bytes of each row and the bits of each byte (MirrorByte `$6419`). HL = DE is allowed (FlipSprite `$6E35` uses it so).

Witness: L1 80 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 20 calls, 286,973 t-states own (0.05 %) |
| Runs (the other recordings) | 60 calls (`stage1/c4` 20, `stage1/c2` 20, `stage1/c3` 20) |
| Called from | `Start`, `FlipSprite` |
| Calls | `MirrorByte` |
| Reads | `$7800`-`$7BC7` (`PhasesA`); `$7C00`-`$7CC7` (`PhasesA+1024`); `$7D00`-`$7DC7` (`PhasesA+1280`); `$7E00`-`$7EC7` (`PhasesA+1536`); `$7F00`-`$7FC7` (`PhasesA+1792`); `$8A00`-`$91C7` (`PhasesB`); 1 more ranges |
| Writes | `$8100`-`$88C7` (`MirrorsA`); `$9300`-`$96C7` (`MirrorsB`); `$9700`-`$97C7` (`MirrorsB+1024`); `$9800`-`$98C7` (`MirrorsB+1280`); `$9900`-`$99C7` (`MirrorsB+1536`); `$9A00`-`$9AC7` (`MirrorsB+1792`); 1 more ranges |

### `MirrorByte` (`$6419`)

**Reverse the bits of C**

Witness: L1 16000 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 4,000 calls, 864,228 t-states own (0.16 %) |
| Runs (the other recordings) | 12,000 calls (`stage1/c2` 4,000, `stage1/c3` 4,000, `stage1/c4` 4,000) |
| Called from | `MirrorSprite` |

### `RotateSprite` (`$6422`)

**Turn the 40x40 sprite at HL by 90 degrees (through RotateBuffer `$9C00`)**

For each of the 40 source columns (left to right), shifts the column's 40 pixels into one 40-pixel row of RotateBuffer `$9C00`, then copies the 200 bytes back to HL. Called 3 times on RombWork, 17 times on set B, twice by FlipSprite for each logo sprite.

Witness: L1 112 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 28 calls, 12,225,110 t-states own (2.19 %) |
| Runs (the other recordings) | 84 calls (`stage1/c2` 28, `stage1/c3` 28, `stage1/c4` 28) |
| Called from | `Start`, `FlipSprite` |
| Reads | `$7700`-`$77C7` (`RombWork`); `$8A00`-`$96C7` (`PhasesB`, `MirrorsB`); `$9700`-`$97C7` (`MirrorsB+1024`); `$9800`-`$98C7` (`MirrorsB+1280`); `$9900`-`$99C7` (`MirrorsB+1536`); `$9A00`-`$9AC7` (`MirrorsB+1792`); 2 more ranges |
| Writes | `$7700`-`$77C7` (`RombWork`); `$8A00`-`$96C7` (`PhasesB`, `MirrorsB`); `$9700`-`$97C7` (`MirrorsB+1024`); `$9800`-`$98C7` (`MirrorsB+1280`); `$9900`-`$99C7` (`MirrorsB+1536`); `$9A00`-`$9AC7` (`MirrorsB+1792`); 2 more ranges |

### `PrintRombPhase` (`$64DA`)

**Print the rhombus at its step (BC) at HL from the phase set at DE, and advance the step**

The phase is PhaseOrder[(BC)], its sprite DE + 256 x phase; PrintSprite `$64F4`. The step (BC) + 1, modulo 32.

Witness: L1 20744 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 11,424 calls, 1,680,069 t-states own (0.30 %) |
| Runs (the other recordings) | 9,320 calls (`stage1/c2` 4,718, `stage1/c4` 2,478, `stage1/c3` 2,124) |
| Called from | `MainLoop` |
| Calls | `PrintSprite` |
| Reads | `$6ADD`-`$6AFC` (`PhaseOrder`); `$B3B1`-`$B3B4` (`work space $B3B1+`) |
| Writes | `$B3B1`-`$B3B4` (`work space $B3B1+`) |

### `PrintSprite` (`$64F4`)

**Print a 40x40 sprite from DE to the screen at HL (5 cells across, 5 down)**

Plain copy (no masking). Used for the rhombi, the logo and, into ScreenCopy, the reflection.

Witness: L1 20792 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 11,436 calls, 82,559,889 t-states own (14.81 %) |
| Runs (the other recordings) | 9,356 calls (`stage1/c2` 4,730, `stage1/c4` 2,490, `stage1/c3` 2,136) |
| Called from | `PrintRombPhase`, `DrawScreen`, `DrawReflection` |
| Reads | `$6E98`-`$6F5F` (`RombSource`); `$7800`-`$7FC7` (`PhasesA`); `$8000`-`$88C7` (`PhasesA+2048`, `MirrorsA`); `$8A00`-`$8AC7` (`PhasesB`); `$8B00`-`$93C7` (`PhasesB+256`, `MirrorsB`); `$9400`-`$9AC7` (`MirrorsB+256`); 1 more ranges |
| Writes | `$4000`-`$479F` (screen); `$5060`-`$57FF` (screen); `$F066`-`$F3F9` (`work space $F066+`); `$F466`-`$F4F9` (`work space $F466+`); `$F566`-`$F5F9` (`work space $F566+`); `$F666`-`$F6F9` (`work space $F666+`); 1 more ranges |

## stars

`src/main/stars.asm`

### `SampleStars` (`$645E`)

**Read the screen pixel under each of the 60 stars into its record**

Falls into SampleStar with IX = StarsA `$AC84`, B = 60 (the three tables follow each other).

Witness: L1 12 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3 calls, 63 t-states own (0.00 %) |
| Runs (the other recordings) | 9 calls (`stage1/c2` 4, `stage1/c3` 3, `stage1/c4` 2) |
| Called from | `Start`, `ShowCatalogue` |
| Calls | `SampleStar` (falls into) |

### `SampleStar` (`$6464`)

**For B stars from IX: record +5 = the pixel under the star (BIT n,(HL), the opcode at +4)**

A star's record (6 bytes): +0/+1 the screen address, +2 RES n,(HL)'s second byte, +3 SET n,(HL)'s, +4 BIT n,(HL)'s, +5 the pixel under it (0 or 1).

Witness: L1 1245596 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 685,450 calls, 110,389,903 t-states own (19.81 %) |
| Runs (the other recordings) | 559,438 calls (`stage1/c2` 283,127, `stage1/c4` 148,769, `stage1/c3` 127,542) |
| Called from | `SampleStars` (falls into), `MoveStars` |
| Reads | `$4000`-`$57FE` (screen); `$AC84`-`$ADEA` (`StarsA`, `StarsB`, `StarsC`) |
| Writes | `$6472` (`SampleStarBit+1`); `$AC89`-`$ADEB` (`StarsA+5`, `StarsB`, `StarsC`) |

### `MoveStars` (`$6482`)

**Move the 20 stars of one table down one pixel row**

The table's address is the operand of the LD IX at `$6482` (MainLoop writes it). For each star: puts back the screen pixel under it (RES or SET from +2/+3 by +5), moves the address one pixel row down (from the bottom of the screen to the top), samples the new pixel (SampleStar with B = 1) and sets it.

Witness: L1 62246 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 34,273 calls, 222,767,059 t-states own (39.97 %) |
| Runs (the other recordings) | 27,973 calls (`stage1/c2` 14,157, `stage1/c4` 7,439, `stage1/c3` 6,377) |
| Called from | `MainLoop` |
| Calls | `SampleStar` |
| Reads | `$4000`-`$57FE` (screen); `$64A2` (`MoveStarsPutBack+1`); `$AC84`-`$ADEB` (`StarsA`, `StarsB`, `StarsC`) |
| Writes | `$4000`-`$57FE` (screen); `$64A2` (`MoveStarsPutBack+1`); `$64D5` (`MoveStarsDraw+1`); `$AC84`-`$ADE7` (`StarsA`, `StarsB`, `StarsC`) |

### `TwinkleStar` (`$6BA5`)

**The twinkle at each frame: new randoms at TwinkleClock 0, erase at the end of a twinkle, a frame every 4th frame**

TwinkleClock `$DEAC` (+2 a frame; 32 frames a twinkle plus the 7 held frames at `$3E`: 39 frames a twinkle, 156 a round of 4): 0: NewRandoms `$6BAB`. Bits 0-5 = `$3E` (the twinkle's last frame): EraseTwinkle without a new frame, and for 7 of 8 times TwinkleClock - 2 (TwinklePause `$DEB0` counts): an 8-frame pause. Else every 4th frame (clock bits 0-2 = 2): DrawTwinkle `$6BFD`.

Witness: L1 13931 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 7,274 calls, 903,394 t-states own (0.16 %) |
| Runs (the other recordings) | 6,657 calls (`stage1/c2` 3,189, `stage1/c4` 1,846, `stage1/c3` 1,622) |
| Called from | `Interrupt` |
| Calls | `NewRandoms` (falls into) |
| Reads | `$DEAC`-`$DEB0` (`work space $DEAC+`) |
| Writes | `$6C19` (`DrawTwinkleSprite`); `$DEAC`-`$DEB0` (`work space $DEAC+`) |

### `NewRandoms` (`$6BAB`)

**Fill Randoms `$ADEC` with 8 new bytes from R, the ROM's bytes and MainTick**

Witness: L1 244 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 126 calls, 81,900 t-states own (0.01 %) |
| Runs (the other recordings) | 118 calls (`stage1/c2` 60, `stage1/c3` 33, `stage1/c4` 25) |
| Called from | `TwinkleStar` (falls into), `DrawTwinkle` |
| Calls | `DrawTwinkle` (falls into) |
| Reads | `$ADEC`-`$ADF3` (`Randoms`); `$B3B0` (`work space $B3B0+`); `$DEA8`-`$DEA9` (`work space $DEA8+`) |
| Writes | `$ADEC`-`$ADF3` (`Randoms`); `$DEA8`-`$DEA9` (`work space $DEA8+`) |

### `DrawTwinkle` (`$6BFD`)

**Erase the twinkle and draw its next frame at the place from Randoms**

The place: the pair Randoms[2n], [2n+1], n = TwinkleClock bits 6-7; CheckTwinkleSpot `$6C56` refuses a place on the menu's text or off the screen (new randoms and again). EraseTwinkle `$6C71` sets TwinkleAddr. The frame: TwinkleClock bits 3-4, counted down when bit 5 is set: frames 0, 1, 2, 3, 3, 2, 1, 0; ORed onto the screen, 16 rows of 2 bytes.

Witness: L1 5864 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2,981 calls, 3,336,157 t-states own (0.60 %) |
| Runs (the other recordings) | 2,724 calls (`stage1/c2` 1,305, `stage1/c4` 756, `stage1/c3` 663) |
| Called from | `NewRandoms` (falls into) |
| Calls | `NewRandoms`, `CheckTwinkleSpot`, `EraseTwinkle` |
| Reads | `$4014`-`$57F8` (screen); `$6F60`-`$6FDF` (`TwinkleSprites`); `$DEAA`-`$DEAC` (`work space $DEAA+`) |
| Writes | `$4014`-`$57F8` (screen) |

### `CheckTwinkleSpot` (`$6C56`)

**Carry set if the place (HL) is allowed: the low byte below `$E0` and its column clear of the menu**

Witness: L1 5864 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3,061 calls, 346,266 t-states own (0.06 %) |
| Runs (the other recordings) | 2,803 calls (`stage1/c2` 1,346, `stage1/c4` 770, `stage1/c3` 687) |
| Called from | `DrawTwinkle` |
| Reads | `$ADEC`-`$ADF3` (`Randoms`) |

### `EraseTwinkle` (`$6C71`)

**TwinkleAddr = the place; copy its 16 rows of 2 bytes from ScreenCopy (the twinkle is erased)**

Witness: L1 5705 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2,981 calls, 5,143,793 t-states own (0.92 %) |
| Runs (the other recordings) | 2,724 calls (`stage1/c2` 1,305, `stage1/c4` 756, `stage1/c3` 663) |
| Called from | `DrawTwinkle` |
| Reads | `$ADEC`-`$ADF3` (`Randoms`); `$E014`-`$F7F8` (`work space $E014+`) |
| Writes | `$4014`-`$57F8` (screen); `$DEAA`-`$DEAB` (`work space $DEAA+`) |

## screen

`src/main/screen.asm`

### `DrawScreen` (`$6510`)

**Draw the static screen, save it to ScreenCopy and fall into ShowCatalogue**

The rhombi at `$4000`, `$401B`, `$5060`, `$507B` (RombSource), the logo's four sprites at `$4006`, `$400B`, `$4010`, `$4015`, its attributes (5 rows of 20 from LogoAttributes `$AC20` to `$5806`), ColourCorners `$6CBF`, Chars `$5C36` = Font - 256, MenuHelp through PrintString `$6720`; copies the screen to ScreenCopy `$E000`.

Witness: L1 4 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 148,038 t-states own (0.03 %) |
| Runs (the other recordings) | 3 calls (`stage1/c4` 1, `stage1/c2` 1, `stage1/c3` 1) |
| Called from | `Start` |
| Calls | `PrintSprite`, `ShowCatalogue` (falls into), `PrintString`, `ColourCorners` |
| Reads | `$4000`-`$5AFF` (screen); `$AC20`-`$AC83` (`LogoAttributes`) |
| Writes | `$5806`-`$5899` (screen); `$5C36`-`$5C37` (system); `$E000`-`$FAFF` (`work space $E000+`) |

### `ShowCatalogue` (`$6586`)

**Show a catalogue page: the clean screen, the file list, the cursor; save the screen**

SoundOff `$6E41`; ScreenCopy back to the screen; ClearFilesArea `$6930`; CursorAttr = 1; ListCatalogue `$65C7` from the entry at the operand of the LD IX at `$659C` (ShowCatalogueAt: Catalogue `$9D00`, or the next page's for SYMBOL SHIFT); CursorSavedAttr = the attribute under the cursor; PagePointer `$B3C1` = the page's first entry; Frames `$5C78` and TwinkleClock `$DEAC` = 0; the screen to ScreenCopy again (now with the list); SampleStars `$645E`.

Called from DrawScreen (falling in), ReadKeyboard for CAPS SHIFT, SYMBOL SHIFT and SPACE.

Witness: L1 8 (c x4).

[Animation: `ShowCatalogue` at work](img/routines/ShowCatalogue.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2 calls, 581,132 t-states own (0.10 %) |
| Runs (the other recordings) | 5 calls (`stage1/c2` 3, `stage1/c3` 2) |
| Called from | `DrawScreen` (falls into), `ReadKeyboard` |
| Calls | `SampleStars`, `ListCatalogue`, `CursorAttrAddr`, `ClearFilesArea`, `SoundOff` |
| Reads | `$4000`-`$5AFF` (screen); `$E000`-`$FAFF` (`work space $E000+`) |
| Writes | `$4000`-`$5AFF` (screen); `$5C78`-`$5C79` (system); `$B3BF`-`$B3CB` (`work space $B3BF+`); `$DEAC` (`work space $DEAC+`); `$E000`-`$FAFF` (`work space $E000+`) |

### `ListCatalogue` (`$65C7`)

**Count the page's files from IX and print them in one or two columns, or NO EXE FILES !**

Counts the entries from IX to the catalogue's end (a first byte 0, or 128 entries: the end of Catalogue at `$A500`) that the menu lists: type B except "boot    B" (IsBootFile `$6737`), and type C of exactly 192 sectors (`$C0` at +13; a 48K snapshot saved as CODE, which TR-DOS runs with GO TO "name" CODE). Deleted entries (first byte 1) are skipped (SkipDeleted `$674D`).

0 files: NoFilesText at row 11, column 9, the cursor 14 cells wide on it. 1-12: one column (PrintColumn `$668E` at row 6, column 10, Columns = 1). 13-24: ListTwoColumns `$6648`. 25 or more: ListTwoColumns with 24, NextPagePointer `$B3C3` = the entry after the 24th, MorePages `$B3B9` = 1.

Witness: L1 8 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2 calls, 884 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/c2` 3, `stage1/c3` 2, `stage1/c4` 1) |
| Called from | `ShowCatalogue` |
| Calls | `PrintColumn`, `PrintString`, `IsBootFile`, `SkipDeleted` |
| Reads | `$9D00`-`$9D10` (`Catalogue`) |
| Writes | `$5C78` (system); `$B3B5`-`$B3BE` (`work space $B3B5+`) |

### `ListTwoColumns` (`$6648`)

**Print A files (13-24) in two columns: half (rounded up) in column 1 at column 2, the rest at column 18**

ColumnOneCount `$B3BB` = A - A / 2, ColumnTwoCount `$B3BC` = A / 2; the cursor on the first file (row 6, column 6).

Witness: L1 3 (c x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/c2` 2, `stage1/c3` 1) |
| Calls | `PrintColumn` |

### `PrintColumn` (`$668E`)

**Print D catalogue lines from HL, the first at row C, column B, the letters from E**

Each listed entry: EntryLine `$B3CE` = AT row,col, BRIGHT 1, INK 5, letter, ">", two spaces, INK 4 (BASIC) or INK 6 (192-sector CODE), the 8 name characters (a byte below 32 or from 128 up shown as "."), `$FF`; PrintString `$6720`. Returns HL after the last entry printed.

Witness: L1 8 (c x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/c2` 5, `stage1/c3` 3) |
| Called from | `ListCatalogue`, `ListTwoColumns` |
| Calls | `PrintString`, `IsBootFile`, `SkipDeleted` |

### `CursorAttrAddr` (`$6848`)

**HL = the attribute address of the row and column at the operand of the LD DE at `$6848` (CursorRow normally)**

Also CursorAttrOffset `$B3C9` = HL - `$5800`. RotateCursorName points the operand at RotateRow for one call.

Witness: L1 3784 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1,966 calls, 1,148,144 t-states own (0.21 %) |
| Runs (the other recordings) | 1,818 calls (`stage1/c2` 882, `stage1/c4` 498, `stage1/c3` 438) |
| Called from | `ShowCatalogue`, `Interrupt`, `RotateCursorName`, `KeyDone`, `CursorMoved`, `MoveCursor` |
| Reads | `$B3B6`-`$B3B7` (`work space $B3B6+`); `$B3CC`-`$B3CD` (`work space $B3CC+`) |
| Writes | `$B3C9`-`$B3CA` (`work space $B3C9+`) |

### `ClearFilesArea` (`$6930`)

**Clear the pixels of rows 6-17 and set their attributes to white on black**

Witness: L1 8 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2 calls, 193,486 t-states own (0.03 %) |
| Runs (the other recordings) | 6 calls (`stage1/c2` 3, `stage1/c3` 2, `stage1/c4` 1) |
| Called from | `ShowCatalogue` |
| Reads | `$58C0`-`$5A3E` (screen) |
| Writes | `$40C0`-`$503F` (screen); `$5100`-`$513F` (screen); `$5200`-`$523F` (screen); `$5300`-`$533F` (screen); `$5400`-`$543F` (screen); `$5500`-`$553F` (screen); 3 more ranges |

### `ColumnKey` (`$6967`)

**1, 2, 6, 7: move the cursor to the other column (two columns only)**

From column 1 to column 2 the cursor keeps its row, but from column 1's last file it goes to column 2's first when the columns differ in length (13-23 files odd); from column 2 to column 1 it keeps the row.

Witness: L1 2 (c x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 2) |
| Called from | `ReadKeyboard` |

### `KeyDone` (`$696E`)

**Pop the caller's AF and return: the key had nothing to do**

Witness: L1 1 (c x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/c4` 1) |
| Called from | `FireKey` (tail) |
| Calls | `CursorAttrAddr`, `CursorMoved` (falls into) |

### `CursorMoved` (`$69B7`)

**CursorSavedAttr = the attribute at the cursor's new place; pop AF, return**

Witness: L1 8 (c x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 8 calls (`stage1/c2` 8) |
| Called from | `KeyDone` (falls into), `MoveCursor` (tail) |
| Calls | `CursorAttrAddr` |

### `DownKey` (`$69C0`)

**3, 8: the cursor down one file (B = 0), wrapping from the column's end to the other column or the top**

Witness: L1 4 (c x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/c2` 4) |
| Called from | `ReadKeyboard` |
| Calls | `MoveCursor` (falls into) |

### `MoveCursor` (`$69C3`)

**Move the cursor down (B = 0) or up (B = 1), from column to column at the ends**

Puts back the old cells' attribute first. The positions run down column 1 (CursorIndex 1 to ColumnOneCount) and on down column 2.

Witness: L1 6 (c x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/c2` 6) |
| Called from | `DownKey` (falls into), `UpKey` (tail) |
| Calls | `CursorAttrAddr`, `CursorMoved` (tail) |

### `UpKey` (`$6A3A`)

**4, 9: the cursor up one file**

Witness: L1 2 (c x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 2) |
| Called from | `ReadKeyboard` |
| Calls | `MoveCursor` (tail) |

## font

`src/main/font.asm`

### `PrintString` (`$6720`)

**Print the string at HL up to `$FF` through RST `$10` on channel 2**

Puts back HL' and IY for the ROM (SavedHLAlt, SavedIY), opens channel 2 (RomChanOpen `$1601`), then RST `$10` for each byte: the control codes AT, INK, BRIGHT are the ROM's.

Witness: L1 93 (c x4).

[Animation: `PrintString` at work](img/routines/PrintString.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3 calls, 5,178 t-states own (0.00 %) |
| Runs (the other recordings) | 90 calls (`stage1/c2` 56, `stage1/c3` 32, `stage1/c4` 2) |
| Called from | `DrawScreen`, `ListCatalogue`, `PrintColumn` |
| Reads | `$6AFD`-`$6B52` (`MenuHelp`, `NoFilesText`); `$AFC8`-`$AFCB` (`work space $AFC8+`) |

## catalogue

`src/main/catalogue.asm`

### `IsBootFile` (`$6737`)

**Compare the 9 bytes at HL (name and type) with "boot    B": C = 0 if equal, `$FF` if not**

Returns HL at the entry's type byte (+8) and E = C: the caller ANDs the type with E, so the boot file's type reads 0 and is never listed.

Witness: L1 219 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2 calls, 1,038 t-states own (0.00 %) |
| Runs (the other recordings) | 217 calls (`stage1/c2` 135, `stage1/c3` 79, `stage1/c4` 3) |
| Called from | `ListCatalogue`, `PrintColumn`, `RunLetter` |
| Reads | `$6B6B`-`$6B73` (`BootName`); `$9D00`-`$9D08` (`Catalogue`) |

### `SkipDeleted` (`$674D`)

**While the entry at HL is deleted (A = 1), go to the next one (HL + 16, A its first byte)**

Witness: L1 234 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 4 calls, 72 t-states own (0.00 %) |
| Runs (the other recordings) | 223 calls (`stage1/c2` 138, `stage1/c3` 81, `stage1/c4` 4) |
| Called from | `ListCatalogue`, `PrintColumn`, `RunLetter` |

## interrupt

`src/main/interrupt.asm`

### `Interrupt` (`$6757`)

**The IM 2 handler**

Witness: L1 13932 (c x4).

[Animation: `Interrupt` at work](img/routines/Interrupt.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 7,275 calls, 3,880,821 t-states own (0.70 %) |
| Runs (the other recordings) | 6,658 calls (`stage1/c2` 3,189, `stage1/c4` 1,847, `stage1/c3` 1,622) |
| Calls | `RotateCursorName` (falls into), `CursorAttrAddr`, `TwinkleStar`, `LogoGlint` |
| Reads | `$5C78`-`$5C79` (system); `$AFC8`-`$AFCB` (`work space $AFC8+`); `$B3B6`-`$B3BF` (`work space $B3B6+`); `$DEAC` (`work space $DEAC+`) |
| Writes | `$5969`-`$5976` (screen); `$5C78`-`$5C79` (system); `$67D8` (`SpinCharacters`); `$B3BF`-`$B3CD` (`work space $B3BF+`); `$B3EC` (`work space $B3EC+`); `$DEAC` (`work space $DEAC+`) |

### `RotateCursorName` (`$67C2`)

**Turn each character of the cursor's name by 90 degrees in ScreenCopy**

RotateAddr `$DEAE` = the name's address in ScreenCopy (from CursorAttrAddr's offset); each character's 8 rows to CharBuffer `$B3ED`, then written back column by column. At Frames 90 the LD A at `$67D8` is made a RET for one call: only the address is worked out.

Witness: L1 276 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 145 calls, 5,559,184 t-states own (1.00 %) |
| Runs (the other recordings) | 131 calls (`stage1/c2` 65, `stage1/c4` 36, `stage1/c3` 30) |
| Called from | `Interrupt` (falls into), `ShowRotatedName` (tail) |
| Calls | `ShowRotatedName` (falls into), `CursorAttrAddr` |
| Reads | `$B3C9`-`$B3CA` (`work space $B3C9+`); `$B3EC`-`$B3F4` (`work space $B3EC+`); `$E869`-`$E876` (`work space $E869+`); `$E969`-`$E976` (`work space $E969+`); `$EA69`-`$EA76` (`work space $EA69+`); `$EB69`-`$EB76` (`work space $EB69+`); 4 more ranges |
| Writes | `$684A`-`$684B` (`CursorAttrAddr+2`); `$B3ED`-`$B3F4` (`work space $B3ED+`); `$DEAE`-`$DEAF` (`work space $DEAE+`); `$E869`-`$E876` (`work space $E869+`); `$E969`-`$E976` (`work space $E969+`); `$EA69`-`$EA76` (`work space $EA69+`); 5 more ranges |

### `ShowRotatedName` (`$6803`)

**Copy the name from ScreenCopy to the screen (CopyNameToScreen) and leave**

Witness: L1 276 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 145 calls, 7,975 t-states own (0.00 %) |
| Runs (the other recordings) | 131 calls (`stage1/c2` 65, `stage1/c4` 36, `stage1/c3` 30) |
| Called from | `RotateCursorName` (falls into) |
| Calls | `RotateCursorName` (tail), `InterruptExit` (tail), `CopyNameToScreen` |
| Writes | `$684A`-`$684B` (`CursorAttrAddr+2`) |

### `InterruptExit` (`$682D`)

**Every 8th frame read the keys; restore the registers, EI, RET**

Witness: L1 13931 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 7,274 calls, 1,250,217 t-states own (0.22 %) |
| Runs (the other recordings) | 6,657 calls (`stage1/c2` 3,189, `stage1/c4` 1,846, `stage1/c3` 1,622) |
| Called from | `ShowRotatedName` (tail) |
| Calls | `ReadKeyboard` |
| Reads | `$5C78` (system) |

### `CopyNameToScreen` (`$6CA2`)

**Copy the 8 rows of the rotated name from ScreenCopy to the screen**

Witness: L1 276 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 145 calls, 467,335 t-states own (0.08 %) |
| Runs (the other recordings) | 131 calls (`stage1/c2` 65, `stage1/c4` 36, `stage1/c3` 30) |
| Called from | `ShowRotatedName` |
| Reads | `$B3EC` (`work space $B3EC+`); `$DEAE`-`$DEAF` (`work space $DEAE+`); `$E869`-`$E876` (`work space $E869+`); `$E969`-`$E976` (`work space $E969+`); `$EA69`-`$EA76` (`work space $EA69+`); `$EB69`-`$EB76` (`work space $EB69+`); 4 more ranges |
| Writes | `$4869`-`$4876` (screen); `$4969`-`$4976` (screen); `$4A69`-`$4A76` (screen); `$4B69`-`$4B76` (screen); `$4C69`-`$4C76` (screen); `$4D69`-`$4D76` (screen); 2 more ranges |

## keys

`src/main/keys.asm`

### `ReadKeyboard` (`$6864`)

**Read the letters, the digits, ENTER, CAPS SHIFT, SYMBOL SHIFT and SPACE**

Witness: L1 1741 (c x4).

[Animation: `ReadKeyboard` at work](img/routines/ReadKeyboard.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 909 calls, 3,334,347 t-states own (0.60 %) |
| Runs (the other recordings) | 832 calls (`stage1/c2` 399, `stage1/c4` 230, `stage1/c3` 203) |
| Called from | `InterruptExit` |
| Calls | `ShowCatalogue`, `ColumnKey`, `DownKey`, `UpKey`, `FireKey`, `RunLetter`, `SoundOff` |
| Reads | `$6B53`-`$6B6A` (`KeyTable`); `$AFC8`-`$AFCB` (`work space $AFC8+`) |
| Writes | `$6876` (`ReadLetterRow+1`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

## launcher

`src/main/launcher.asm`

### `FireKey` (`$6A3F`)

**5, 0, ENTER: run the file under the cursor (none with no files)**

C = "@" + CursorIndex: the letter of the file.

Witness: L1 2 (c x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/c4` 1) |
| Called from | `ReadKeyboard` |
| Calls | `KeyDone` (tail) |

### `RunLetter` (`$6A51`)

**Run the page's file with letter C (A for the first): write the launch line, restore the caller's state, bell, fade, return to the loader**

Returns at once when C is past the page's last file. Walks the catalogue from PagePointer `$B3C1` counting the listed files; each entry passed has its first byte set to 1 (deleted), so the walk's SkipDeleted steps over it, and the chosen one gets its byte back. LaunchToken `$5D4C` = `$F7` (RUN) for a B file, `$EC` (GO TO) for a 192-sector C file; the name's 8 bytes after the quote; after the closing quote a space or `$AF` (CODE). Frames = 0; I, HL', IY and SP from Start; Chars = `$3C00`; PlayBell `$6E48`; ExitFade `$6E72`; IM 1; EI; RET to the loader's `$5DB7` (after its CALL MenuStart at `$5DB4`).

Witness: L1 3 (c x3).

[Animation: `RunLetter` at work](img/routines/RunLetter.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c3` 1, `stage1/c4` 1) |
| Called from | `ReadKeyboard` |
| Calls | `IsBootFile`, `SkipDeleted`, `PlayBell`, `ExitFade` |

## fade

`src/main/fade.asm`

### `ColourCorners` (`$6CBF`)

**Colour the four 5x5 corners with CornerColours**

Witness: L1 4 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 118 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/c2` 1, `stage1/c3` 1, `stage1/c4` 1) |
| Called from | `DrawScreen` |
| Calls | `ColourCornerRows`, `ColourCornerColumns` |

### `ColourCornerRows` (`$6CD8`)

**At HL, 5 rows of 5 cells: row n all CornerColours[n]**

Witness: L1 8 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2 calls, 2,194 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/c2` 2, `stage1/c3` 2, `stage1/c4` 2) |
| Called from | `ColourCorners` |
| Reads | `$ADF4`-`$ADF8` (`CornerColours`) |
| Writes | `$5800`-`$5844` (screen); `$5860`-`$5864` (screen); `$5880`-`$5884` (screen); `$5A7B`-`$5A7F` (screen); `$5A9B`-`$5A9F` (screen); `$5ABB`-`$5ABF` (screen); 2 more ranges |

### `ColourCornerColumns` (`$6CEF`)

**At DE, 5 rows of 5 cells, each row the 5 CornerColours**

Witness: L1 8 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 2 calls, 1,854 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/c2` 2, `stage1/c3` 2, `stage1/c4` 2) |
| Called from | `ColourCorners` |
| Reads | `$ADF4`-`$ADF8` (`CornerColours`) |
| Writes | `$581B`-`$585F` (screen); `$587B`-`$587F` (screen); `$589B`-`$589F` (screen); `$5A60`-`$5A64` (screen); `$5A80`-`$5A84` (screen); `$5AA0`-`$5AA4` (screen); 2 more ranges |

### `ExitFade` (`$6E72`)

**Shift every pixel row out of its bytes in 8 passes: the screen goes black**

Witness: L1 2 (c x2).

[Animation: `ExitFade` at work](img/routines/ExitFade.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/c3` 1) |
| Called from | `RunLetter` |

## logo

`src/main/logo.asm`

### `LogoGlint` (`$6D04`)

**Frames 0-63 of every 256: the glint across the logo or its reflection**

At Frames low byte 0 the corner cells by the logo turn red (2). Then on every even frame up to 53 a glint step: 5 rows, each row's three cells left of the step restored from ScreenCopy's attributes (RestoreGlintCells `$6D6A`) and three cells red, bright red, red drawn (DrawGlintRow `$6D8A`), mirrored about the screen's centre, the row above one cell further on.

Witness: L1 13931 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 7,274 calls, 1,029,770 t-states own (0.18 %) |
| Runs (the other recordings) | 6,657 calls (`stage1/c2` 3,189, `stage1/c4` 1,846, `stage1/c3` 1,622) |
| Called from | `Interrupt` |
| Calls | `RestoreGlintCells`, `DrawGlintRow` |
| Reads | `$5C78`-`$5C79` (system) |
| Writes | `$5806` (screen); `$5819` (screen); `$5A66` (screen); `$5A79` (screen); `$6D3E`-`$6D42` (`GlintCornerLeft+1`, `GlintCornerRight`); `$6D54`-`$6D55` (`GlintRowStart+1`) |

### `RestoreGlintCells` (`$6D6A`)

**Copy 3 attribute cells at the glint's column and their mirror image from ScreenCopy**

Witness: L1 7605 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3,770 calls, 1,059,370 t-states own (0.19 %) |
| Runs (the other recordings) | 3,835 calls (`stage1/c2` 1,805, `stage1/c4` 1,040, `stage1/c3` 990) |
| Called from | `LogoGlint` |
| Reads | `$F800`-`$F89F` (`work space $F800+`); `$FA60`-`$FAFF` (`work space $FA60+`) |
| Writes | `$5800`-`$589F` (screen); `$5A60`-`$5AFF` (screen) |

### `DrawGlintRow` (`$6D8A`)

**Draw the glint's 3 cells (red, bright red, red) at the column and the mirror image**

Witness: L1 7605 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3,770 calls, 852,020 t-states own (0.15 %) |
| Runs (the other recordings) | 3,835 calls (`stage1/c2` 1,805, `stage1/c4` 1,040, `stage1/c3` 990) |
| Called from | `LogoGlint` |
| Calls | `GlintRed`, `GlintBright` |

### `GlintRed` (`$6DAE`)

**(HL) = 2 (red ink) if HL's column is within the logo (6-25)**

Witness: L1 30420 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 15,080 calls, 758,640 t-states own (0.14 %) |
| Runs (the other recordings) | 15,340 calls (`stage1/c2` 7,220, `stage1/c4` 4,160, `stage1/c3` 3,960) |
| Called from | `DrawGlintRow` |
| Writes | `$5806`-`$5899` (screen); `$5A66`-`$5AF9` (screen) |

### `GlintBright` (`$6DBA`)

**(HL) = `$42` (bright red) if HL's column is within the logo**

Witness: L1 15210 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 7,540 calls, 379,900 t-states own (0.07 %) |
| Runs (the other recordings) | 7,670 calls (`stage1/c2` 3,610, `stage1/c4` 2,080, `stage1/c3` 1,980) |
| Called from | `DrawGlintRow` |
| Writes | `$5806`-`$5899` (screen); `$5A66`-`$5AF9` (screen) |

### `DrawReflection` (`$6DC6`)

**Print the logo upside down into ScreenCopy's bottom third and copy it to the screen**

FlipSprite `$6E35` on each of the four logo sprites (they stay flipped), PrintSprite to `$F066`, `$F06B`, `$F070`, `$F075` in ScreenCopy (the screen's `$5066`...), the logo's 5 attribute rows copied in reverse order to `$FAE6` upward, then ScreenCopy's bottom third (`$F000`, 2K) and its attribute rows 19-23 to the screen. DI around it.

Witness: L1 4 (c x4).

[Animation: `DrawReflection` at work](img/routines/DrawReflection.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 49,266 t-states own (0.01 %) |
| Runs (the other recordings) | 3 calls (`stage1/c2` 1, `stage1/c3` 1, `stage1/c4` 1) |
| Called from | `Start` |
| Calls | `PrintSprite`, `FlipSprite` |
| Reads | `$F000`-`$F899` (`work space $F000+`); `$FA60`-`$FAFF` (`work space $FA60+`) |
| Writes | `$5000`-`$57FF` (screen); `$5A60`-`$5AFF` (screen); `$FA66`-`$FAF9` (`work space $FA66+`) |

### `FlipSprite` (`$6E35`)

**Turn the 40x40 sprite at HL upside down (RotateSprite twice: 180 degrees, then MirrorSprite)**

Witness: L1 16 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 4 calls, 276 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/c2` 4, `stage1/c3` 4, `stage1/c4` 4) |
| Called from | `DrawReflection` |
| Calls | `MirrorSprite`, `RotateSprite` |

## sound

`src/main/sound.asm`

### `SoundOff` (`$6E41`)

**Silence the AY: registers 0-13 from 30000, bytes of the work space nothing writes (zeros)**

30000 is `$7530`, inside Unused1 `$70A8` (cleared by the loader, never written), so every register gets 0: no tone, volume 0. Called by ShowCatalogue before every page, cutting the music for a moment.

Witness: L1 9 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3 calls, 111 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/c2` 3, `stage1/c3` 2, `stage1/c4` 1) |
| Called from | `ShowCatalogue`, `ReadKeyboard` |
| Calls | `WriteAY` |

### `PlayBell` (`$6E48`)

**Write ExitSound to the AY registers 0-13: the bell when a file is chosen**

Witness: L1 2 (c x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/c2` 1, `stage1/c3` 1) |
| Called from | `RunLetter` |
| Calls | `WriteAY` |

### `WriteAY` (`$6E4F`)

**Write 14 bytes from HL to the AY registers 0-13**

Witness: L1 11 (c x4).

[Animation: `WriteAY` at work](img/routines/WriteAY.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3 calls, 4,446 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/c2` 4, `stage1/c3` 3, `stage1/c4` 1) |
| Called from | `SoundOff`, `PlayBell` |
| Reads | `$7530`-`$753D` (`Unused1+1160`) |
| Ports out | `$BFFD`, `$FFFD` |


## The BASIC loader (sector 0 of boot) (`src/basic/basic.json`)

ZYX boot: sector 0 of the file boot (B, 180 bytes, 46 sectors), the BASIC program TR-DOS loads at PROG `$5D3B`. Line
4's REM holds the loader, entered at `$5D80` by line 10's RANDOMIZE USR 23936. Its entries are
`src/basic/<module>.asm`, written from `src/basic/basic.ann` by `kit/mkgame.py --part src/basic/basic.json`; the
recordings: `work/stage1/c1` (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE), and
`work/stage1/c2` (`$5D3B`-`$5E3A`), `work/stage1/c3` (`$5D3B`-`$5E3A`), `work/stage1/c4` (`$5D3B`-`$5E3A`).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic`](#the-basic-loader-sector-0-of-boot-basic) | `$5D3B`-`$5E3A` | 1 of 9 |

### The BASIC loader (sector 0 of boot): basic

`src/basic/basic-module.asm`

#### `Loader` (`$5D80`)

**Clear the menu's memory, read the code, the graphics and the music from the disk, run the menu, clear again**

Entered by line 10's RANDOMIZE USR 23936 with TR-DOS's TrdosNextSector `$5CF4` pointing at the sector after sector 0 of boot (TR-DOS just loaded the program). Clears `$61A8-$FEAF` (LDIR of `$9D08` bytes), then three TrdosEntry `$3D13` reads (C = 5), each starting at TrdosNextSector: 15 sectors to MenuStart `$61A8` (`$61A8-$70A7`), 8 sectors to MenuGraphics `$A600` (`$A600-$ADFF`), 22 sectors to MusicPiece `$C000` (`$C000-$D5FF`). Then CALL MenuStart: the menu returns here when a file is chosen, with the launch line already rewritten. Clears `$61A8-$FEAF` again and returns to BASIC, which goes on with line 10's RUN.

The memory is cleared because the menu builds its tables and buffers in the zero bytes between its pieces (`$70A8-$A5FF`, `$AE00-$BFFF`, `$D600-$FEAF`) and the program it starts should find clean memory.

Witness: L1 4 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 844,558 t-states own (0.15 %) |
| Runs (the other recordings) | 3 calls (`stage1/c2` 1, `stage1/c3` 1, `stage1/c4` 1) |
| Reads | `$5CF4`-`$5CF5`; `$61A8`-`$FEAE` |
| Writes | `$61A8`-`$FC81`; `$FCBC`-`$FEAF` |


## The music: ASC Sound Master player and tune (src/music) (`src/music/music.json`)

ZYX boot: the music piece at `$C000`, an ASC Sound Master compilation (player and tune) the menu calls at `$C00B`
(init) and from its interrupt at `$C00E` (play). Its entries are `src/music/<module>.asm`, written from
`src/music/music.ann` by `kit/mkgame.py --part src/music/music.json`; the recordings: `work/stage1/c1` (c1: the
original disk from power-on, the menu idle (NO EXE FILES !), SPACE), and `work/stage1/c2` (`$C000`-`$D5FF`),
`work/stage1/c3` (`$C000`-`$D5FF`), `work/stage1/c4` (`$C000`-`$D5FF`).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`player`](#the-music-asc-sound-master-player-and-tune-srcmusic-player) | `$C000`-`$C477` | 21 of 32 |
| [`tune`](11-data-reference.md#the-music-asc-sound-master-player-and-tune-srcmusic-tune) | `$C478`-`$D5FF` | 0 of 9 |

### The music: ASC Sound Master player and tune (src/music): player

`src/music/player.asm`

#### `MusicInit` (`$C00B`)

**Set the player up for the tune (JP InitPlayer)**

The init entry: the menu's set-up calls it once (c1 frame 532), before its IM 2 handler starts calling MusicPlay `$C00E`.

Witness: L1 4 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/c2` 1, `stage1/c3` 1, `stage1/c4` 1) |
| Calls | `InitPlayer` (tail) |

#### `MusicPlay` (`$C00E`)

**Play one frame of the tune (JP PlayFrame)**

The play entry: the menu's IM 2 handler calls it at `$676D` on every interrupt (c1: 7274 calls, frames 543-7879).

Witness: L1 13931 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 7,274 calls, 72,740 t-states own (0.01 %) |
| Runs (the other recordings) | 6,657 calls (`stage1/c2` 3,189, `stage1/c4` 1,846, `stage1/c3` 1,622) |
| Calls | `PlayFrame` (tail) |

#### `MusicStop` (`$C011`)

**Silence the AY (JP Silence)**

The stop entry of the compilation. Known only from the code: no instruction in c1-c4 jumps or calls here (the menu never stops the music; the launched program loads over it).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `InitPlayer` (`$C053`)

**Clear the channels, read the module's header into the player's operands, silence the AY**

In: nothing. Clears ChannelA `$C0A9` to the end of ChannelC `$C0F3` (75 bytes), sets PositionOp+1 to 0 (the first position), and DelayCounter `$C103` and the three row counters (+`$0A` of each record) to 1, so the first MusicPlay reads a row at once.

Then BC = DE = TuneHeader `$C478`: DelayOp+1 = the delay (byte 0: 6); through ReadOffsetDE `$C189` the three offsets at +1, +3, +5 plus the module's address into PatternTableOp+1 (`$C496`), SampleTableOp+1 (`$D074`) and CommandOrnament+1 (`$D4EF`); PositionCountOp+1 = the number of positions (byte 7: 22); NextPosition+1 = the positions' address (`$C480`). Falls into Silence `$C095`.

c1 runs it once, at frame 532.

Witness: L1 4 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 2,184 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/c2` 1, `stage1/c3` 1, `stage1/c4` 1) |
| Called from | `MusicInit` (tail) |
| Calls | `ReadOffsetDE` |
| Reads | `$C0A9`-`$C100` (`ChannelA`, `ChannelB`, `ChannelC`, `AYRegisters`); `$C478`-`$C47F` (`TuneHeader`) |
| Writes | `$C0A9`-`$C10B` (`ChannelA`, `ChannelB`, `ChannelC`, `AYRegisters` and 3 more); `$C192`-`$C1AA` (`NextPosition+1`, `PositionOp`, `PositionCountOp`, `PatternTableOp`); `$C25F`-`$C26D` (`SampleTableOp+1`, `CommandOrnament`) |

#### `Silence` (`$C095`)

**Clear the AY register image, mixer `$FF`, write all 14 registers**

AYRegisters `$C0F4-$C101` = 0, then AYMixer `$C0FB` = `$FF` (tones and noise off), and JP WriteAY `$C15F`, which writes registers 13 to 0 (AYEnvelopeShape is 0 here, not `$FF`, so register 13 is written too). Reached by falling from InitPlayer `$C053` (once a recording) and from MusicStop `$C011` (known only from the code).

Witness: L1 4 (c x4).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `WriteAY` (tail) |

#### `PlayFrame` (`$C104`)

**Play one frame: on a row frame the next position and the channels' rows, then each channel's sound, the mixer, the AY write**

In: nothing (reached from MusicPlay `$C00E`). DelayCounter `$C103` - 1; at 0 it becomes the delay and, if bit 0 of all three records' flags is 0 (every stream met its `$FF`), NextPosition `$C191` starts the next position; then ChannelRow `$C1CE` for A, B and C (IX = ChannelA `$C0A9`, ChannelB `$C0C2`, ChannelC `$C0DB`).

PlayFrameSound `$C131`, every frame: ChannelSound `$C2A0` with A = 0, 1, 2 and IX = each record; the mixer (register 7) = channel C's +`$01` bits << 2 | channel B's << 1 | channel A's (bits 0-2 tone off, 3-5 noise off) through SetAYRegister `$C17D`; falls into WriteAY `$C15F`.

c1: 7274 frames, 1213 of them row frames (the JR NZ at `$C108`), 21 new positions (the CALL Z at `$C119`).

Witness: L1 13931 (c x4).

[Animation: `PlayFrame` at work](img/routines/PlayFrame.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 7,274 calls, 1,878,160 t-states own (0.34 %) |
| Runs (the other recordings) | 6,657 calls (`stage1/c2` 3,189, `stage1/c4` 1,846, `stage1/c3` 1,622) |
| Called from | `MusicPlay` (tail) |
| Calls | `SetAYRegister`, `NextPosition`, `ChannelRow`, `ChannelSound` |
| Reads | `$C0A9`-`$C0AA` (`ChannelA`); `$C0C2`-`$C0C3` (`ChannelB`); `$C0DB`-`$C0DC` (`ChannelC`); `$C103` (`DelayCounter`) |
| Writes | `$C103` (`DelayCounter`) |

#### `WriteAY` (`$C15F`)

**Write AYRegisters to the AY: registers 13 (when set) or 12 down to 0**

In: AYRegisters `$C0F4`. Register 13 is written only when AYEnvelopeShape `$C101` is not `$FF` (a shape command this frame, or Silence `$C095`), since writing it restarts the envelope; then AYEnvelopeShape = `$FF`. Each register: OUT (`$FFFD`) its number, OUTD its value (B = `$BF` goes to `$BE` first: port `$BEFD`, the AY data port).

Out: A = `$FF`. Reached by falling from PlayFrame `$C104` and by JP from Silence `$C095`.

Witness: L1 13935 (c x4).

[Animation: `WriteAY` at work](img/routines/WriteAY.gif)

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1 call, 5,347,440 t-states own (0.96 %) |
| Runs (the other recordings) | 3 calls (`stage1/c2` 1, `stage1/c4` 1, `stage1/c3` 1) |
| Called from | `Silence` (tail) |
| Reads | `$C0F4`-`$C101` (`AYRegisters`, `AYNoise`, `AYMixer`, `AYEnvelopePeriod` and 1 more) |
| Writes | `$C101` (`AYEnvelopeShape`) |
| Ports out | `$BEFD`, `$FFFD` |

#### `SetAYRegister` (`$C17D`)

**AYRegisters[E] = A**

In: E = the register (0-13), A = the value. Keeps DE and HL.

Witness: L1 137602 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 72,148 calls, 6,276,876 t-states own (1.13 %) |
| Runs (the other recordings) | 65,454 calls (`stage1/c2` 31,518, `stage1/c4` 18,088, `stage1/c3` 15,848) |
| Called from | `PlayFrame`, `ChannelSound` (tail) |
| Writes | `$C0F4`-`$C0FE` (`AYRegisters`, `AYNoise`, `AYMixer`) |

#### `ReadOffsetDE` (`$C189`)

**HL = BC + the word at (DE), DE + 2**

EX DE,HL and falls into ReadOffset `$C18A`. Used by InitPlayer `$C053` (the module's three table offsets) and NextPosition `$C191` (the streams of channels B and C).

Witness: L1 98 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 45 calls, 180 t-states own (0.00 %) |
| Runs (the other recordings) | 53 calls (`stage1/c2` 23, `stage1/c3` 15, `stage1/c4` 15) |
| Called from | `InitPlayer`, `NextPosition` |
| Calls | `ReadOffset` (falls into) |

#### `ReadOffset` (`$C18A`)

**HL = BC + the word at (HL); DE = HL + 2**

In: HL = the word's address, BC = the base the offset is from. Out: HL = the address, DE = the address after the word.

Witness: L1 141 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 66 calls, 3,366 t-states own (0.00 %) |
| Runs (the other recordings) | 75 calls (`stage1/c2` 33, `stage1/c3` 21, `stage1/c4` 21) |
| Called from | `ReadOffsetDE` (falls into), `NextPosition` |
| Reads | `$C479`-`$C47E` (`TuneHeader+1`); `$C496`-`$C4F5` (`PatternTable`) |

#### `NextPosition` (`$C191`)

**Start the next position: the three channels' streams of its pattern**

LD HL,n: n = the positions' address (set by InitPlayer `$C053`), plus the position (PositionOp+1); the next position = this one + 1, or 0 after the last (PositionCountOp+1 = 22): the tune loops to position 0. Then HL = PatternTableOp+1 + 6 x the pattern number (an 8-bit product: at most pattern 42), and ReadOffset `$C18A` / ReadOffsetDE `$C189` put the three stream addresses into +`$0B`/`$0C` of ChannelA `$C0A9`, ChannelB `$C0C2`, ChannelC `$C0DB`, and bit 0 of their flags is set.

c1: 21 positions (0-20, frames 543-7602); position 21 (pattern 14) would start at row 1230, after c1's last row 1213.

Witness: L1 43 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 21 calls, 6,363 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/c2` 10, `stage1/c3` 6, `stage1/c4` 6) |
| Called from | `PlayFrame` |
| Calls | `ReadOffsetDE`, `ReadOffset` |
| Reads | `$C0A9` (`ChannelA`); `$C0C2` (`ChannelB`); `$C0DB` (`ChannelC`); `$C480`-`$C494` (`TunePositions`) |
| Writes | `$C0A9`-`$C0E7` (`ChannelA`, `ChannelB`, `ChannelC`); `$C195` (`PositionOp+1`) |

#### `ChannelRow` (`$C1CE`)

**One row of a channel: when its event ends, read the commands and the next event of its stream**

In: IX = the channel record. +`$0A` - 1; while not 0 the current event goes on. At 0, the bytes at +`$0B`/`$0C`: each byte `$80-$FF` is a command (PatternCommand `$C24C`), then the event: `$00-$55` a note (RowNote `$C1F9`), `$56-$7D` nothing new (the note goes on), `$7E` release (RowRelease `$C1F3`: the sample leaves its loop), `$7F` off (bit 2 cleared: silence).

RowDone `$C238`: +`$0A` = the length (+`$09`), the pointer kept; when the next byte is `$FF` the stream is over (bit 0 cleared). So the three streams of a pattern must end on the same row.

c1: 3639 calls in the 1213 row frames.

Witness: L1 6972 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 3,639 calls, 1,214,809 t-states own (0.22 %) |
| Runs (the other recordings) | 3,333 calls (`stage1/c2` 1,596, `stage1/c4` 924, `stage1/c3` 813) |
| Called from | `PlayFrame` |
| Calls | `PatternCommand` |
| Reads | `$C0A9`-`$C0EF` (`ChannelA`, `ChannelB`, `ChannelC`); `$C4F6`-`$CF9F` (`PatternData`, `Pattern1`, `Pattern2`, `Pattern3` and 10 more); `$D05C`-`$D073` (`Pattern15`) |
| Writes | `$C0A9`-`$C0FF` (`ChannelA`, `ChannelB`, `ChannelC`, `AYRegisters`) |

#### `PatternCommand` (`$C24C`)

**A pattern command byte `$80-$FF`: sample, ornament, volume or envelope mode, noise, length or shape**

In: A = the byte, IX = the record, DE = the stream after it. `$80-$9F`: the sample A - `$80` (+`$0D`/`$0E` = SampleTable + its offset, through TableEntry `$C278`); `$A0-$BF`: the ornament (CommandOrnament `$C26B`, +`$13`/`$14`); `$C0-$CF`: CommandVolume `$C283`; `$D0-$EF`: CommandNoise `$C290`; `$F0-$FF`: CommandLength `$C294`.

Witness: L1 3520 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1,807 calls, 218,678 t-states own (0.04 %) |
| Runs (the other recordings) | 1,713 calls (`stage1/c2` 836, `stage1/c4` 462, `stage1/c3` 415) |
| Called from | `ChannelRow` |
| Calls | `TableEntry` |
| Reads | `$C0A9` (`ChannelA`); `$C0C2` (`ChannelB`); `$C0DB` (`ChannelC`); `$C4FB`-`$CAE7` (`PatternData+5`, `Pattern1`, `Pattern2`, `Pattern3` and 5 more); `$CB0E`-`$CBBA` (`Pattern8+76`, `Pattern9`); `$CBE1`-`$CC8C` (`Pattern9+90`, `Pattern10`); 5 more ranges |
| Writes | `$C0A9`-`$C0EF` (`ChannelA`, `ChannelB`, `ChannelC`); `$C101` (`AYEnvelopeShape`) |

#### `TableEntry` (`$C278`)

**HL = BC + the word at BC + 2A (a sample or ornament address from its table)**

In: A = the number (0-31), BC = SampleTable `$D074` or OrnamentTable `$D4EF`.

Witness: L1 2522 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 1,310 calls, 93,010 t-states own (0.02 %) |
| Runs (the other recordings) | 1,212 calls (`stage1/c2` 600, `stage1/c4` 324, `stage1/c3` 288) |
| Called from | `PatternCommand` |
| Reads | `$D076`-`$D08F` (`SampleTable+2`); `$D4F1`-`$D50A` (`OrnamentTable+2`) |

#### `CommandVolume` (`$C283`)

**`$C0`: envelope mode; `$C1-$CF`: the channel volume 1-15**

In: A = the byte - `$C0` (Z for `$C0`). `$C0` sets bit 4 (envelope mode: each note is followed by the envelope period byte, and a sample row with E plays on the envelope); `$C1-$CF` clears it and +`$08` = 1-15, the scale of the sample's volumes.

Witness: L1 173 (c x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CommandNoise` (`$C290`)

**`$D0-$EF`: the noise base 0-31**

+`$05` = A; a note copies it into the noise period +`$06`.

Witness: L1 119 (c x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CommandLength` (`$C294`)

**`$F0` n: the row length n; `$F1-$FF`: the envelope shape 1-15**

In: A = the byte - `$F0` (Z for `$F0`). `$F0`: +`$09` = the next byte (CommandLengthByte `$C29A`). `$F1-$FF`: AYEnvelopeShape `$C101` = 1-15, written (and the envelope restarted) at this frame's WriteAY `$C15F`.

Witness: L1 706 (c x4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ChannelSound` (`$C2A0`)

**One frame of a channel's sound: its sample and ornament rows, the period, the volume, the noise**

In: A = the channel (0-2, into CurrentChannel `$C102`), IX = its record. When the sample ended (bit 1) or no note sounds (bit 2 clear): only the volume register, 0. Else SampleStep `$C308` and OrnamentStep `$C385`; AYNoise `$C0FA` = +`$06` unless the sample row has noise off; the note +`$02` (above `$55`: `$55`, or 0 when an ornament took it below 0) indexes PeriodTable `$C3CA`, plus the tone offset +`$03`/`$04`: registers 2 x channel and 2 x channel + 1 (its low nibble); the volume +`$07`, with bit 4 (the envelope) when both bit 4 (envelope mode) and bit 5 (the row's E) are set: register 8 + channel.

c1: 21 822 calls (3 a frame); 224 with the sample ended, 72 with no note.

Witness: L1 41793 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 21,822 calls, 10,033,732 t-states own (1.80 %) |
| Runs (the other recordings) | 19,971 calls (`stage1/c2` 9,567, `stage1/c4` 5,538, `stage1/c3` 4,866) |
| Called from | `PlayFrame` |
| Calls | `SetAYRegister` (tail), `SampleStep`, `OrnamentStep` |
| Reads | `$C0A9`-`$C0B0` (`ChannelA`); `$C0C2`-`$C0C9` (`ChannelB`); `$C0DB`-`$C0E2` (`ChannelC`); `$C102` (`CurrentChannel`); `$C3CA`-`$C469` (`PeriodTable`) |
| Writes | `$C0FA`-`$C102` (`AYNoise`, `CurrentChannel`) |

#### `SampleStep` (`$C308`)

**One row of the channel's sample: loop marks, tone offset, mixer, volume, noise offset**

In: IX. The row at +`$0F`/`$10`, three bytes: F (flags and noise delta), T (tone delta), M (mixer and volume). F bit 7: this row is the loop row (+`$11`/`$12`); bit 6: the next row is the loop row, unless released (bit 3); bit 5 (checked only when not looping back): the sample ends here (bit 1: silence from the next frame). The tone offset += T (signed); +`$01` = M AND 9 (bit 0 tone off, bit 3 noise off); bit 5 of the flags = M bit 1 (envelope); the volume +`$07` = (M >> 4) x (the channel volume + 1) / 16. Then AddNoise `$C3BB` with F's low 5 bits.

Witness: L1 40939 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 21,526 calls, 15,334,859 t-states own (2.75 %) |
| Runs (the other recordings) | 19,413 calls (`stage1/c2` 9,381, `stage1/c4` 5,352, `stage1/c3` 4,680) |
| Called from | `ChannelSound` |
| Calls | `AddNoise` (tail) |
| Reads | `$C0A9`-`$C0ED` (`ChannelA`, `ChannelB`, `ChannelC`); `$D0B7`-`$D19D` (`Sample1`, `Sample2`, `Sample3`, `Sample4` and 1 more); `$D1B0`-`$D425` (`Sample7`, `Sample8`, `Sample9`, `Sample10` and 2 more) |
| Writes | `$C0A9`-`$C0ED` (`ChannelA`, `ChannelB`, `ChannelC`) |

#### `OrnamentStep` (`$C385`)

**One row of the channel's ornament: loop marks, note offset, noise offset**

In: IX. The row at +`$15`/`$16`, two bytes: F (flags and noise delta), N (note delta). F bit 7: this row is the loop row (+`$17`/`$18`); bit 6: the next row is the loop row (always, released or not). The note +`$02` += N (signed): the deltas add up from the note's start. Falls into AddNoise `$C3BB` with F.

Witness: L1 40939 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 21,526 calls, 5,904,335 t-states own (1.06 %) |
| Runs (the other recordings) | 19,413 calls (`stage1/c2` 9,381, `stage1/c4` 5,352, `stage1/c3` 4,680) |
| Called from | `ChannelSound` |
| Calls | `AddNoise` (falls into) |
| Reads | `$C0AB` (`ChannelA+2`); `$C0BE`-`$C0C4` (`ChannelA+21`, `ChannelB`); `$C0D7`-`$C0DD` (`ChannelB+21`, `ChannelC`); `$C0F0`-`$C0F3` (`ChannelC+21`); `$D531`-`$D56E` (`Ornament1`, `Ornament2`, `Ornament3`, `Ornament4` and 7 more) |
| Writes | `$C0AB` (`ChannelA+2`); `$C0BE`-`$C0C4` (`ChannelA+21`, `ChannelB`); `$C0D7`-`$C0DD` (`ChannelB+21`, `ChannelC`); `$C0F0`-`$C0F3` (`ChannelC+21`) |

#### `AddNoise` (`$C3BB`)

**The noise period += the row's signed 5-bit noise delta**

In: C = the row's first byte (bits 0-4 a signed delta, -16 to 15), IX. +`$06` = (+`$06` + the delta) AND 31. Reached from SampleStep `$C308` and OrnamentStep `$C385`.

Witness: L1 81878 (c x4).

| | |
| --- | --- |
| Runs (c1: the original disk from power-on, the menu idle (NO EXE FILES !), SPACE) | 43,052 calls, 3,358,056 t-states own (0.60 %) |
| Runs (the other recordings) | 38,826 calls (`stage1/c2` 18,762, `stage1/c4` 10,704, `stage1/c3` 9,360) |
| Called from | `SampleStep` (tail), `OrnamentStep` (falls into) |
| Reads | `$C0AF` (`ChannelA+6`); `$C0C8` (`ChannelB+6`); `$C0E1` (`ChannelC+6`) |
| Writes | `$C0AF` (`ChannelA+6`); `$C0C8` (`ChannelB+6`); `$C0E1` (`ChannelC+6`) |
