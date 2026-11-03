# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/p2` (the bot game), `work/game` (the L1 build of the first recording's game window). Both are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover; in `$8000-$BFFF` the accesses of code outside it are
the playfield buffer's, laid over the title player and the start-up. An entry no recording reached says so.
Written by `tools/refdocs.py`; edit `src/game/game.ann`, then run `tools/mkgame.py --venv SKOOLKIT_VENV --sjasmplus SJASMPLUS --install`
(see [3. Build and load](03-build-and-load.md)) and `tools/refdocs.py`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`buffers`](#buffers) | `$5FB4`-`$7FFF` | 1 of 30 |
| [`titleplayer`](#titleplayer) | `$8000`-`$85FF` | 41 of 65 |
| [`startup`](#startup) | `$8600`-`$BFFF` | 3 of 14 |
| [`gamedata`](#gamedata) | `$C000`-`$C3FF` | 1 of 44 |
| [`course`](#course) | `$C400`-`$CF31` | 0 of 21 |
| [`mainloop`](#mainloop) | `$CF32`-`$D0EE` | 2 of 2 |
| [`roundsetup`](#roundsetup) | `$D0EF`-`$D35D` | 4 of 6 |
| [`scroller`](#scroller) | `$D35E`-`$D9D5` | 6 of 39 |
| [`sprites`](#sprites) | `$D9D6`-`$DDE5` | 8 of 11 |
| [`shadows`](#shadows) | `$DDE6`-`$E15B` | 22 of 23 |
| [`mover`](#mover) | `$E15C`-`$E68B` | 7 of 12 |
| [`player`](#player) | `$E68C`-`$EA37` | 5 of 8 |
| [`statics`](#statics) | `$EA38`-`$EBA9` | 2 of 2 |
| [`hits`](#hits) | `$EBAA`-`$EE12` | 18 of 22 |
| [`hud`](#hud) | `$EE13`-`$EFA4` | 7 of 19 |
| [`objview`](#objview) | `$EFA5`-`$F0DA` | 3 of 3 |
| [`menu`](#menu) | `$F0DB`-`$F2FF` | 6 of 19 |
| [`coursedata`](#coursedata) | `$F300`-`$FFFF` | 1 of 15 |

## buffers

`src/game/buffers.asm`

### `Entry` (`$61A8`)

**Game entry (RANDOMIZE USR 25000)**

The address BASIC line 30 calls. It sets the stack to the top of memory, disables interrupts and jumps to the start-up `$9F12`. Overwritten when the first round clears the profile buffer.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 24 t-states own (0.00 %) |
| Calls | `Startup` (tail) |

## titleplayer

`src/game/titleplayer.asm`

### `TitlePlayer` (`$8000`)

**Title music player: relocating entry**

Entry of the title music player (Ben Daglish's beeper engine); docs/02-architecture.md 2.3, docs/09-sound.md. C = the tune number (the operand `$8002`, set to 0 by the start-up). It reads its own call address from the CALL operand below the return address, swaps `$58C` bytes from that address + `$3A` with `$803A`, calls the set-up `$803A` and swaps them back, so the player can be linked anywhere. Called as CALL `$8000` the swap changes nothing. The same 64 pages are the playfield buffer `$8000-$BFFF` in play (docs/06-rendering.md 6.2).

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 1 call, 210,321 t-states own (0.01 %) |
| Called from | `Startup` |
| Calls | `TitleSetup` |
| Reads | `$803A`-`$85C5` (`TitleSetup`, `NoteTimeCheck`, `PatternStep`, `PatternCommand` and 58 more); `$9F1A`-`$9F1B` (`Startup`) |
| Writes | `$803A`-`$85C5` (`TitleSetup`, `NoteTimeCheck`, `PatternStep`, `PatternCommand` and 58 more) |

### `TitlePlayerSwapBack` (`$8025`)

**Title music player: swap the body back**

Undoes the swap of `$8000` and returns to the start-up.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 105,115 t-states own (0.01 %) |
| Reads | `$803A`-`$85C5` (`TitleSetup`, `NoteTimeCheck`, `PatternStep`, `PatternCommand` and 58 more) |
| Writes | `$803A`-`$85C5` (`TitleSetup`, `NoteTimeCheck`, `PatternStep`, `PatternCommand` and 58 more) |

### `TitleSetup` (`$803A`)

**Title player set-up: hook IM 2, reset the voices, start the tune**

Saves SP into the operand at `$8364` (for the exits at `$8356`), points SP at its own small stack below `$83F7`, reads the IM 2 vector address from I (the vector table byte at I*256, doubled: `$FDFD`) and saves the 3 bytes there to `$83F9`, then writes JP `$8340` in their place. Applies the 9 (address, byte) patches of `$8422` to reset its own operands, enables interrupts, and starts tune C from the table `$843D`; docs/02-architecture.md 2.3.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 1 call, 46,279 t-states own (0.00 %) |
| Called from | `TitlePlayer` |
| Calls | `SongStep` (tail), `Im2Jump` |
| Reads | `$806E` (`TitleSetup`); `$8422`-`$843E` (`TitlePatches`, `TuneTable`); `$FDFD`-`$FE00` (`Im2Jump`, `Im2Table`) |
| Writes | `$817B` (`CmdLongNote`); `$82CA`-`$82D4` (`VoicesPlay`); `$832C`-`$8336` (`VoiceBStep`); `$8364`-`$8365` (`TitleInterrupt`); `$83F7`-`$83FB` (`TitleVectorAddr`, `TitleVectorSave`); `$FDFD`-`$FDFF` (`Im2Jump`) |

### `NoteTimeCheck` (`$807F`)

**Title player: is the current note over?**

Entered from the voice loop after each period of voice B. C counts the note's frames down (the IM 2 handler decrements it); while it is not 0 the voices go on, at 0 the next pattern command is read.

| | |
| --- | --- |
| Runs (the bot game) | 3 calls, 54 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 8,362,124 calls, 150,556,536 t-states own (5.05 %) |
| Called from | `VoiceAEnvelope` (tail), `VoiceBDelayLoop` (tail) |
| Calls | `PatternStep`, `DrumTick` (tail), `Im2Jump` |

### `PatternStep` (`$8084`)

**Title player: next note, reload the note length**

Reloads C with the note length (the operand `$8085`, set by command 17), then reads the next command of the pattern.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 5,657 calls, 84,855 t-states own (0.00 %) |
| Called from | `NoteTimeCheck`, `PatternEnter` (tail) |
| Calls | `PatternCommand` |

### `PatternCommand` (`$8088`)

**Title player: dispatch one pattern command**

Reads the command byte at HL and jumps through the handler table `$83FC` (2 bytes a command) with the position after the byte on the stack; docs/09-sound.md 9.3.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 6,374 calls, 560,912 t-states own (0.02 %) |
| Called from | `PatternStep`, `CmdWidthA` (tail), `CmdWidthB` (tail), `CmdEnvelopeA` (tail), `CmdEnvelopeB` (tail), `CmdModeBHold` (tail), `CmdModeBDecay` (tail), `CmdNoteLength` (tail), `CmdDrums` (tail), `CmdLongNote` (tail) |
| Calls | `CmdWidthA`, `CmdWidthB`, `CmdEnvelopeA`, `CmdEnvelopeB`, `CmdModeBHold`, `CmdModeBDecay`, `CmdNoteLength`, `CmdDrums`, `CmdPatternEnd`, `CmdHold`, `CmdLongNote`, `CmdNoteAB`, `CmdNoteA`, `CmdNoteB` |
| Reads | `$83FC`-`$8421` (`TitleCommands`); `$8467`-`$859F` (`PatternInit`, `PatternA`, `PatternB`, `PatternC` and 1 more) |

### `CmdWidthA` (`$8098`)

**Title command 1: voice A's starting pulse width**

Writes the argument byte into the operands at `$81DE` and `$8205`, the LD B,n of voice A's note set-up in commands 10 and 11: the pulse width a note starts with, its loudness.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 590 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail) |
| Reads | `$846B` (`PatternInit`) |
| Writes | `$81DE` (`CmdNoteABVoiceB`); `$8205` (`CmdNoteAPeriod`) |

### `CmdWidthB` (`$80A4`)

**Title command 2: voice B's starting pulse width**

Writes the argument byte into the operands at `$81BB` and `$8231`, the LD B,n of voice B's note set-up in commands 10 and 12.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 590 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail) |
| Reads | `$846D` (`PatternInit`) |
| Writes | `$81BB` (`CmdNoteABVoiceB`); `$8231` (`CmdNoteB`) |

### `CmdEnvelopeA` (`$80B0`)

**Title command 3: envelope step time of voice A**

Writes the argument into the operand at `$827E`, the reload of H (voice A's envelope frame counter) when a note starts.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 460 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail) |
| Reads | `$846F` (`PatternInit`) |
| Writes | `$827E` (`VoiceAEnvelope`) |

### `CmdEnvelopeB` (`$80B9`)

**Title command 4: envelope step time of voice B**

Writes the argument into the operand at `$82E0`, the reload of L (voice B's envelope frame counter) when a note starts.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 460 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail) |
| Reads | `$8471` (`PatternInit`) |
| Writes | `$82E0` (`VoicesPlay`) |

### `CmdModeBHold` (`$80CE`)

**Title command 7: voice B envelope mode 1 (hold)**

C of the pattern's register set is voice B's envelope mode.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 513 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail) |

### `CmdModeBDecay` (`$80D4`)

**Title command 8: voice B envelope mode 0 (decay)**

Sets voice B's envelope mode C = 0 and goes back to the pattern reader (PatternCommand); docs/09-sound.md 9.3.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 270 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail) |

### `CmdNoteLength` (`$80F5`)

**Title command 17: set the note length**

The argument goes into the operand of LD C,n at `$8085` and into C' at once.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 580 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail) |
| Reads | `$8469` (`PatternInit`) |
| Writes | `$8085` (`PatternStep`) |

### `CmdDrums` (`$8101`)

**Title command 16: change the drum pattern from a pattern**

Starts the drum pattern whose address follows the command byte (`$815E`), then reads the next command.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 817 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail), `DrumStart` |

### `CmdPatternEnd` (`$8109`)

**Title command 9: end of pattern**

Counts the repeats down (the operand `$810E`). While some remain, it restarts the pattern from its start (the operand `$810B`); otherwise it goes back to the song at the position saved in `$8116`; docs/09-sound.md 9.3.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 7,508 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `SongStep`, `PatternEnter` (tail) |
| Writes | `$810E` (`CmdPatternEnd`) |

### `SongStep` (`$8118`)

**Title player: interpret the song**

Reads one song byte at HL: `$FF` return from a sub-song, `$FE` call a sub-song, `$FD` jump, `$FC` end of the tune, `$FB` start a drum pattern, n < `$FB` play the pattern at the following address n times; docs/09-sound.md 9.2.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 109 calls, 16,205 t-states own (0.00 %) |
| Called from | `TitleSetup` (tail), `CmdPatternEnd`, `DrumStart` |
| Calls | `PatternEnter`, `SongDrums` (tail) |
| Reads | `$843F`-`$8462` (`TuneSong`) |
| Writes | `$810B`-`$8117` (`CmdPatternEnd`) |

### `SongCallCheck` (`$8122`)

**Title player: song byte `$FE`?**

Song bytes from `$FE` down: `$FE` calls a sub-song (SongCall, not run), anything else is a jump in the song (SongJump).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SongJump` (`$8131`)

**Title player: song bytes `$FD`, `$FC`, `$FB` and patterns**

`$FD` jumps to the address that follows (tune 0 loops this way); `$FC` leaves through `$8356`, the same exit as a key; `$FB` starts a drum pattern; any other byte n plays the pattern at the following address n times: n goes into `$810E`, the pattern's start into `$810B` and the song position after it into `$8116`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PatternEnter` (`$8156`)

**Title player: enter a pattern**

Back to the pattern register set, where DE holds the pattern position, then `$8084`.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 129 calls, 1,806 t-states own (0.00 %) |
| Called from | `CmdPatternEnd` (tail), `SongStep` |
| Calls | `PatternStep` (tail) |

### `SongDrums` (`$815A`)

**Title song byte `$FB`: start a drum pattern**

Calls DrumStart with the return set to `$8118`, the next song byte.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 40 calls, 840 t-states own (0.00 %) |
| Called from | `SongStep` (tail) |
| Calls | `DrumStart` |

### `DrumStart` (`$815E`)

**Title player: start the drum pattern at the address after HL**

Clears the drum timer (operand `$8244`), stores the pattern's first byte, its speed in frames, into the operand `$824B`, and its step address into `$8250` (the position) and `$8258` (the loop point); docs/09-sound.md 9.5.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 59 calls, 7,375 t-states own (0.00 %) |
| Called from | `CmdDrums`, `SongDrums` |
| Calls | `SongStep` |
| Reads | `$8443`-`$8459` (`TuneSong`); `$8584`-`$8585` (`PatternD`); `$85A2` (`DrumPatternA`); `$85B4` (`DrumPatternB`) |
| Writes | `$8244`-`$8259` (`DrumTick`) |

### `CmdHold` (`$8175`)

**Title command 0: hold the notes one more note length**

Command 0: nothing changes this note length; the player goes on to the drum tick (DrumTick) with the notes as they are.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 23,736 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `DrumTick` (tail) |

### `CmdLongNote` (`$817A`)

**Title command 18: hold the notes n note lengths**

The counter is its own operand at `$817B`: 0 means the command starts, it loads n from the argument; otherwise it counts down, staying on this command until 0, then steps over the argument.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 191,255 t-states own (0.01 %) |
| Called from | `PatternCommand` |
| Calls | `PatternCommand` (tail), `DrumTick` (tail) |
| Reads | `$817B` (`CmdLongNote`); `$847B`-`$849B` (`PatternA`); `$84CD` (`PatternC`); `$84E8` (`PatternC`); `$8507` (`PatternC`); `$8522` (`PatternC`); 3 more ranges |
| Writes | `$817B` (`CmdLongNote`) |

### `CmdNoteAB` (`$819B`)

**Title command 10: a note on both voices**

Two period bytes: voice A's goes into D of the voice loop and the reload operand `$82CA`, voice B's into E and `$832C`. Each voice's pulse width (`$82D4`, `$8336`) starts at the width of command 1 or 2, its pre-delay (`$82CC`, `$832E`) is period / 8 + `$18` less that width, and its OUT value (`$82D0`, `$8332`) is `$18` (beeper on); H and L get the envelope times of commands 3 and 4. When an envelope mode is not 0, the note starts mode 3; docs/09-sound.md 9.3-9.4.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 551,790 t-states own (0.02 %) |
| Called from | `PatternCommand` |
| Calls | `DrumTick` (tail) |
| Reads | `$827E` (`VoiceAEnvelope`); `$82E0` (`VoicesPlay`); `$8474`-`$859B` (`PatternA`, `PatternB`, `PatternC`, `PatternD`) |
| Writes | `$82CA`-`$82D4` (`VoicesPlay`); `$832C`-`$8336` (`VoiceBStep`) |

### `CmdNoteABVoiceB` (`$81A1`)

**Title command 10: voice B mode and the periods**

Command 10: voice B starts in envelope mode 3 when C is not 0; then both periods from the pattern (NoteABPeriods), voice B's written into its period reload VoiceBStep+`$0005`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdNoteA` (`$81EE`)

**Title command 11: a note on voice A only**

One period byte for voice A, set up as in command 10.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 78,690 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `DrumTick` (tail) |
| Reads | `$827E` (`VoiceAEnvelope`); `$84B1`-`$84D2` (`PatternB`, `PatternC`); `$84E6`-`$84EA` (`PatternC`); `$8505`-`$850C` (`PatternC`); `$8520`-`$8524` (`PatternC`) |
| Writes | `$82CA`-`$82D4` (`VoicesPlay`) |

### `CmdNoteAPeriod` (`$81F4`)

**Title command 11: voice A's period**

Command 11: voice A's period from the pattern into its reload VoiceAStep+`$0005`, and its pre-delay VoiceAStep+`$0007` = period / 8 + `$18` - the starting width (an operand command 1 writes); docs/09-sound.md 9.3.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CmdNoteB` (`$821A`)

**Title command 12: a note on voice B only**

One period byte for voice B, set up as in command 10.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | run into, not called, 124,580 t-states own (0.00 %) |
| Called from | `PatternCommand` |
| Calls | `DrumTick` |
| Reads | `$82E0` (`VoicesPlay`); `$84D5`-`$84FC` (`PatternC`); `$850F`-`$8536` (`PatternC`) |
| Writes | `$832C`-`$8336` (`VoiceBStep`) |

### `DrumTick` (`$8243`)

**Title player: drum timer, then the voices**

The operand `$8244` is the drum timer, decremented once a frame by the IM 2 handler. At 0 it is reloaded from the speed (operand `$824B`) and the next drum byte is played: 0 rest, 1 loop to the pattern's start, 2-6 the sounds `$8367`, `$837F`, `$839A`, `$83C6`, `$83B0`; docs/09-sound.md 9.5.

| | |
| --- | --- |
| Runs (the bot game) | 3 calls, 804 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 8,362,125 calls, 176,386,884 t-states own (5.92 %) |
| Called from | `NoteTimeCheck` (tail), `CmdHold` (tail), `CmdLongNote` (tail), `CmdNoteAB` (tail), `CmdNoteA` (tail), `CmdNoteB` |
| Calls | `VoiceAEnvelope`, `VoiceBDelayLoop`, `DrumClick` (tail), `DrumNoise` (tail), `DrumRise` (tail), `DrumFall` (tail), `DrumSweep` (tail), `Im2Jump` |
| Reads | `$85A3`-`$85C4` (`DrumPatternA`, `DrumPatternB`) |
| Writes | `$8244`-`$8251` (`DrumTick`) |

### `VoiceAEnvelope` (`$8279`)

**Title player: voice A's envelope tick**

H counts voice A's envelope frames (the IM 2 handler decrements it). At 0 it is reloaded with 3 and voice A's envelope mode B' is applied: 0 decays the note (`$82A3`), 1-3 are handled by the bytes `$8284` (not run in the recording).

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 8,362,125 calls, 1,548,407,840 t-states own (51.95 %) |
| Called from | `DrumTick`, `DrumClick` (tail), `DrumNoise` (tail), `DrumRise` (tail), `DrumFall` (tail), `DrumSweep` (tail) |
| Calls | `NoteTimeCheck` (tail), `Im2Jump` |
| Reads | `$82CC`-`$82D4` (`VoicesPlay`); `$832C`-`$8336` (`VoiceBStep`) |
| Writes | `$82CC`-`$82D4` (`VoicesPlay`); `$832E`-`$8336` (`VoiceBStep`) |
| Ports out | `$00FE`, `$18FE` |

### `VoiceADecay` (`$82A3`)

**Title player: voice A's decay step**

Narrows voice A's pulse (`$82D4`) and lengthens its pre-delay (`$82CC`) by one: the same pitch, quieter. When the width runs out the bytes at `$82B1` silence the voice.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `VoicesPlay` (`$82C1`)

**Title player: the two voices**

One period step of each voice. D counts voice A's period down; at 0 it is reloaded (the operand `$82CA`) and one pulse is sent: pre-delay (`$82CC`), beeper on (`$82D0`, `$18`), pulse width (`$82D4`), beeper off. Then voice B's envelope tick (L, mode C') and the same for voice B with E at `$8327`; docs/09-sound.md 9.4.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `VoiceBDelay` (`$8323`)

**Title player: balance the envelope branch**

A 4-step delay loop that makes the envelope branch take as long as the other one, so voice B's period step comes at the same time either way.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `VoiceBDelayLoop` (`$8325`)

**Title player: delay loop**

The delay loop of VoiceBDelay (B = 4), then voice B's period step.

| | |
| --- | --- |
| Runs (the bot game) | 2 calls, 170 t-states own (0.00 %) |
| Called from | `DrumTick` |
| Calls | `NoteTimeCheck` (tail) |

### `VoiceBStep` (`$8327`)

**Title player: voice B's period step**

E counts voice B's period down; at 0 one pulse is sent like voice A's. Then back to `$807F`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TitleInterrupt` (`$8340`)

**Title player: the IM 2 handler, once a frame**

Reached through JP `$8340` at `$FDFD`. A key on any row ends the music (`$8356`). Otherwise it ticks the engine's clocks: the drum timer (`$8244`) and the registers of the interrupted voice loop, C (the note length), H and L (the envelopes); 123 T an entry. docs/02-architecture.md 2.3.

| | |
| --- | --- |
| Runs (the bot game) | 1 call, 168 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 27,645 calls, 3,123,940 t-states own (0.10 %) |
| Called from | `Im2Jump` (tail) |
| Reads | `$8244` (`DrumTick`); `$83F7`-`$83FB` (`TitleVectorAddr`, `TitleVectorSave`) |
| Writes | `$8244` (`DrumTick`); `$FDFD`-`$FDFF` (`Im2Jump`) |
| Ports in | `$00FE` |

### `DrumClick` (`$8367`)

**Title drum 2: a click**

The beeper held on for 300 loop steps, then a pause; docs/09-sound.md 9.5.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 1,593 calls, 13,655,196 t-states own (0.46 %) |
| Called from | `DrumTick` (tail) |
| Calls | `VoiceAEnvelope` (tail) |
| Ports out | `$00FE`, `$18FE` |

### `DrumNoise` (`$837F`)

**Title drum 3: noise from the ROM**

150 pulses whose levels and lengths are the bytes of the ROM from `$0064`: code read as random numbers.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 633 calls, 20,294,003 t-states own (0.68 %) |
| Called from | `DrumTick` (tail) |
| Calls | `VoiceAEnvelope` (tail) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE` |

### `DrumRise` (`$839A`)

**Title drum 4: a rising tone, half-period 50 down to 1**

The beeper toggled 50 times with two waits of D each, D from 50 down to 1: a tone rising in pitch. Then back to voice A's envelope.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 145 calls, 5,040,936 t-states own (0.17 %) |
| Called from | `DrumTick` (tail) |
| Calls | `VoiceAEnvelope` (tail) |
| Ports out | `$00FE`, `$18FE` |

### `DrumFall` (`$83B0`)

**Title drum 6: a falling tone, period 180 up in steps of 4**

The beeper toggled with one wait of D, D from 180 up in steps of 4 until it wraps past 255 (19 steps): a tone falling in pitch.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 116 calls, 6,291,472 t-states own (0.21 %) |
| Called from | `DrumTick` (tail) |
| Calls | `VoiceAEnvelope` (tail) |
| Ports out | `$00FE`, `$18FE` |

### `DrumSweep` (`$83C6`)

**Title drum 5: a rising tone, period 200 down to 124**

The beeper toggled with one wait of D, D from 200 down in steps of 4 while it is at least 124 (20 steps): a short rising tone, then back to voice A's envelope.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 145 calls, 6,296,884 t-states own (0.21 %) |
| Called from | `DrumTick` (tail) |
| Calls | `VoiceAEnvelope` (tail) |
| Ports out | `$00FE`, `$18FE` |

## startup

`src/game/startup.asm`

### `Startup` (`$9F12`)

**Start-up: IM 2, the title music, then the game**

Called once from the entry `$61A8`. Sets IM 2 (`$9F4B`), plays tune 0 of the title player until it ends or a key is pressed, then copies the game screen image `$A000-$BFFF` to `$4000-$5FFF`, clears the lap `$C2F8` and enters the game through `$C2B1`; docs/02-architecture.md 2.3.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 1 call, 219,973 t-states own (0.01 %) |
| Called from | `Entry` (tail) |
| Calls | `TitlePlayer`, `SetupIM2`, `GameStart` (tail) |
| Reads | `$A000`-`$BFFF` (`GameScreenImage`, `GameScreenAttrs`, `RendererTablesImage`) |
| Writes | `$4000`-`$5FFF` (`ProfileMargin`); `$8002` (`TitlePlayer`); `$C2F8` (`LapNumber`) |

### `StartGame` (`$9F1C`)

**Start-up, after the title music: the play screen, then the game**

Reached when the title player returns (the tune ended or a key was pressed), not called: DI, the game screen image `$A000-$BFFF` copied to `$4000-$5FFF` (the play screen, its attributes and the renderer's tables at `$5B00-$5FFF`), the lap `$C2F8` = 0, then JP `$C2B1` into the main loop with interrupts off for good; docs/02-architecture.md 2.3.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 219,922 t-states own (0.02 %) |
| Calls | `GameStart` (tail) |
| Reads | `$A000`-`$BFFF` (`GameScreenImage`, `GameScreenAttrs`, `RendererTablesImage`) |
| Writes | `$4000`-`$5FFF` (`ProfileMargin`); `$C2F8` (`LapNumber`) |

### `SetupIM2` (`$9F4B`)

**Set up IM 2 with a safe vector**

Writes JP `$9F68` at `$FDFD`, fills the 257 bytes `$FE00-$FF00` with `$FD` and sets I = `$FE`, IM 2: whatever the bus holds, the vector is `$FDFD`; docs/02-architecture.md 2.3.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 1 call, 6,758 t-states own (0.00 %) |
| Called from | `Startup` |
| Writes | `$FDFD`-`$FF00` (`Im2Jump`, `Im2Table`, `SpriteListArea`) |

## gamedata

`src/game/gamedata.asm`

### `GameStart` (`$C2B1`)

**Game start: JP to the main loop**

Entered once from the start-up `$9F2C`.

| | |
| --- | --- |
| Runs (the bot game) | 1 call, 10 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 1 call, 10 t-states own (0.00 %) |
| Called from | `Startup` (tail), `StartGame` (tail) |
| Calls | `GameEntry` (tail) |

## mainloop

`src/game/mainloop.asm`

### `GameEntry` (`$CF32`)

**The game's entry: interrupts off**

Entered from `$C2B1` after loading. Interrupts stay off from here on: no pass waits for a frame (docs/04-game-loop.md 4.5). Runs on into MainLoop.

| | |
| --- | --- |
| Runs (the bot game) | 1 call, 1,949,876 t-states own (0.20 %) |
| Runs (the L1 build of the first recording's game window) | 1 call, 4 t-states own (0.00 %) |
| Called from | `GameStart` (tail) |
| Calls | `MainLoop`, `ShortPause`, `Blit`, `ScrollStep`, `CourseExpand`, `BuildSpriteLists`, `DrawShadows`, `MoveObjects`, `ReadControls`, `Random`, `PrintString`, `UpdateMax`, `PlaceObjects`, `Menu`, `Beep`, `PlayEffect` |
| Reads | `$6000`-`$62FE` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C000`-`$C050` (`PlayerRecord`, `PlayerShotRecords`); `$C2F7`-`$C2F9` (`RoundNumber`, `LapNumber`, `Lives`); `$CF2E`-`$CF31` (`CourseRecord`, `RestartRecord`); `$E68B` (`AutoCountdown`); `$EF50`-`$EF60` (`RoundTable`); 1 more ranges |
| Writes | `$5A58` (screen); `$6000`-`$62FF` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C000`-`$C0B0` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 1 more); `$C2F6`-`$C2F7` (`MoverHeight`, `RoundNumber`); `$C32E`-`$C33A` (`ScrollPage`, `ScrollHalf`, `UnusedC330`, `SavedStack` and 1 more); `$C3FA`-`$C3FB` (`StripCount`); 5 more ranges |
| Ports in | `$DFFE` |

### `MainLoop` (`$CF33`)

**Menu, game start, round start and the pass loop**

The whole game state machine; it never returns (docs/04-game-loop.md 4.1-4.4). `$CF33` calls the menu, then starts a game or the demo; RoundStart (`$CF68`) starts a round or a retry, pre-rolls 32 strips and enters the pass loop PassLoop (`$CFAC`). A lost vehicle (CheckLost, `$CFEF`) retries the round, falls back to an earlier one (LookBack, `$D017`) or ends in GameOver (`$D0A5`). The pass also reads the abort (U+G) and pause (P) keys (docs/05-controls.md 5.5). GAME OVER and ABORT return to `$CF33`.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 2 calls, 372,248,024 t-states own (12.49 %) |
| Called from | `GameEntry`, `ScrollStep` (tail) |
| Calls | `ShortPause`, `Blit`, `ScrollStep`, `CourseExpand`, `BuildSpriteLists`, `DrawShadows`, `MoveObjects`, `ReadControls`, `Random`, `PrintString`, `UpdateMax`, `PlaceObjects`, `Menu`, `Beep`, `PlayEffect` |
| Reads | `$6000`-`$62FE` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C000`-`$C050` (`PlayerRecord`, `PlayerShotRecords`); `$C2F7`-`$C2F9` (`RoundNumber`, `LapNumber`, `Lives`); `$CF2E`-`$CF31` (`CourseRecord`, `RestartRecord`); `$E68B` (`AutoCountdown`); `$EF50`-`$EF54` (`RoundTable`); 1 more ranges |
| Writes | `$5A58` (screen); `$6000`-`$62FF` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C000`-`$C0B0` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 1 more); `$C2F6`-`$C2F7` (`MoverHeight`, `RoundNumber`); `$C32E`-`$C33A` (`ScrollPage`, `ScrollHalf`, `UnusedC330`, `SavedStack` and 1 more); `$C3FA`-`$C3FB` (`StripCount`); 5 more ranges |
| Ports in | `$BFFE`, `$DFFE` |

## roundsetup

`src/game/roundsetup.asm`

### `BuildGroundProfile` (`$D0EF`)

**Build the ground profile `$6000` from the course**

Clears `$6000-$62FF` and fills it with the ground profile of the course (CourseRecord): one byte for every 2 units along, height in bits 0-4 and walls in bits 5-7 (docs/07-objects.md 7.4). Each course byte b after the type gives the anchors at `$C9FE` + b / 2 (GroundAnchors), ended by `$FF`; an anchor goes every 8 bytes from `$6008`, and the 7 bytes after the previous anchor step from it toward the new one by (old height - new height) / 8 a byte. The previous anchor also takes the new anchor's wall bits. Stops when the buffer is full (`$6300`) or the course ends. Entered by JP from the course check (`$D4C2`) right after RoundSetup, so it returns to the caller of ScrollStep.

| | |
| --- | --- |
| Runs (the bot game) | 9 calls, 635,546 t-states own (0.06 %) |
| Runs (the L1 build of the first recording's game window) | 10 calls, 706,925 t-states own (0.02 %) |
| Called from | `ScrollStep` (tail) |
| Reads | `$6000`-`$62FE` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C9FE`-`$CA42` (`GroundAnchors`); `$CC18`-`$CE09` (`Course8`, `Course9`, `Course10`, `Course3` and 2 more); `$CEAC`-`$CF2F` (`Course4`, `CourseTable`, `CourseRecord`) |
| Writes | `$6000`-`$62FF` (`ProfileBuffer`, `Entry`, `GroundProfileTail`) |

### `RoundSetup` (`$D151`)

**Set up a round: round table, round number, lives, objects, colour**

Called by the course check (`$D4BF`) when the 32nd strip of a course is drawn: at the end of a round start's pre-roll, and when the next course scrolls in without a break (docs/04-game-loop.md 4.2, docs/10-gameplay-logic.md 10.2). Outside the demo: MAX from SCORE, the round table entry of the round just ended (or retried) gets the carried lives and SCORE, the round number counts up (after 10 back to 1, with the lap `$C2F8` counted and round 10's entry copied to round 0's), the round number and the lives are shown. Then, demo or not (`$D1DE`): the round's objects from the course record (docs/07-objects.md 7.2, 7.8), the round sound, and the course colour painted by falling into PaintAttributes with B = ink 6 - ((round - 1) AND 3), bright below 5; in the demo the subtracted value is one less (the round number stays 0 there, so ink 4, bright green).

| | |
| --- | --- |
| Runs (the bot game) | 9 calls, 113,658 t-states own (0.01 %) |
| Runs (the L1 build of the first recording's game window) | 10 calls, 125,728 t-states own (0.00 %) |
| Called from | `ScrollStep` |
| Calls | `PaintAttributes`, `ShortPause`, `PrintString`, `ShowScore`, `UpdateMax`, `PlaySound` |
| Reads | `$C000`-`$C002` (`PlayerRecord`); `$C060`-`$C270` (`PodRecords`, `ParkedVehicleRecord`, `CourseObjectRecords`, `LaunchedRecords` and 3 more); `$C292`-`$C2B0` (`PlayerTemplate`, `UnusedC299`, `VehicleTemplate`); `$C2F7`-`$C2F8` (`RoundNumber`, `LapNumber`); `$CC17` (`Course8`); `$CC6C` (`Course9`); 12 more ranges |
| Writes | `$5A58`-`$5A5B` (screen); `$C000`-`$C008` (`PlayerRecord`); `$C061`-`$C270` (`PodRecords`, `ParkedVehicleRecord`, `CourseObjectRecords`, `LaunchedRecords` and 3 more); `$C2A1` (`VehicleTemplate`); `$C2BD` (`LaunchTemplates`); `$C2F7`-`$C2FE` (`RoundNumber`, `LapNumber`, `Lives`, `RoundText`); 6 more ranges |

### `PaintAttributes` (`$D338`)

**Colour the cells of the blit address list with B**

Walks the address list at `$D5B2` (BlitAddresses), screen addresses of the bottom lines of character cells ended by a high byte `$FF`, and sets the attribute of each cell to B. A high byte below `$47` (the `$0800` clip entries) is skipped; `$47` gives row block `$58`xx, `$48-$4F` `$59`xx, `$50` and up `$5A`xx (docs/08-hud-and-text.md 8.5). Reached by falling through from RoundSetup with the course colour, and called by the menu with B = 6.

| | |
| --- | --- |
| Runs (the bot game) | 11 calls, 608,166 t-states own (0.06 %) |
| Runs (the L1 build of the first recording's game window) | 14 calls, 773,536 t-states own (0.03 %) |
| Called from | `RoundSetup`, `Menu` |
| Reads | `$D5B2`-`$D9D3` (`BlitAddresses`, `BlitColumn01`, `BlitColumn02`, `BlitColumn03` and 29 more) |
| Writes | `$5818`-`$581F` (screen); `$5836`-`$583F` (screen); `$5854`-`$585F` (screen); `$5872`-`$587F` (screen); `$5890`-`$5ACC` (screen); `$5AE0`-`$5AEA` (screen) |

### `ShortPause` (`$D354`)

**A busy wait of 65 536 DJNZ steps**

About 0.85 million T-states, a quarter of a second. Keeps A. Used after hiding the dots (RoundSetup `$D1D2`, and on the last life lost at `$D00A`).

| | |
| --- | --- |
| Runs (the bot game) | 10 calls, 8,565,880 t-states own (0.87 %) |
| Runs (the L1 build of the first recording's game window) | 10 calls, 8,565,880 t-states own (0.29 %) |
| Called from | `GameEntry`, `MainLoop`, `RoundSetup` |

## scroller

`src/game/scroller.asm`

### `Blit` (`$D35E`)

**Copy the 32 strips of the playfield to the screen**

SP walks the address list BlitAddresses (`$D5B2`): every POP is the screen address of a cell's bottom line, and up to 8 lines are written upward from it (LD A,(DE); LD (HL),A; INC E; DEC H). DE starts at page `$80` + `$C32E`, byte `$C32F` (the half), and moves 2 pages a column, wrapping in `$80-$BF`. Even columns take 17 POPs, the first and last writing 4 lines; odd columns 16 POPs of 8 lines. Clip entries point at `$0800` in the ROM. Then the sprite lists (`$DD6C`), and falls into ScrollStep (docs/06-rendering.md 6.3).

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 270,660,483 t-states own (27.62 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 239,372,463 t-states own (8.03 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `RestoreUnderSprites` |
| Reads | `$8000`-`$BFFF` (the playfield buffer); `$C32E`-`$C332` (`ScrollPage`, `ScrollHalf`, `UnusedC330`, `SavedStack`) |
| Writes | `$4019`-`$401F` (screen); `$4037`-`$403F` (screen); `$4055`-`$405F` (screen); `$4073`-`$407F` (screen); `$4091`-`$40FF` (screen); `$4119`-`$411F` (screen); 26 more ranges |

### `ScrollStep` (`$D3F9`)

**One scroll step: toggle the half, make one strip**

Called 128 times by the round start's pre-roll and entered once a pass from Blit. The scroll distance `$D14D` grows by 2, the half `$C32F` toggles and the page offset `$C32E` (0-63) counts up when the half goes back to 0. Each of the four states makes one strip (docs/06-rendering.md 6.4): half 0, offset even: FreshStrip (`$D51D`); half `$80`, even: StripPhase4 (`$D413`); half 0, odd: StripPhase2 (`$D45B`); half `$80`, odd: the course check (`$D49C`).

| | |
| --- | --- |
| Runs (the bot game) | 768 calls, 17,343,711 t-states own (1.77 %) |
| Runs (the L1 build of the first recording's game window) | 1,280 calls, 18,398,842 t-states own (0.62 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `MainLoop` (tail), `BuildGroundProfile` (tail), `RoundSetup`, `CourseExpand`, `FreshStrip` (tail) |
| Reads | `$8000`-`$BFFE` (the playfield buffer); `$C32E`-`$C32F` (`ScrollPage`, `ScrollHalf`); `$C3F8`-`$C3FD` (`CourseRowPtr`, `StripCount`, `FreshStripPage`); `$CA64`-`$CBC2` (`RowList`, `RowListTail`); `$CF2E`-`$CF2F` (`CourseRecord`); `$D14D`-`$D14E` (`ScrollDistance`); 1 more ranges |
| Writes | `$8100`-`$BFFF` (the playfield buffer); `$C32E`-`$C32F` (`ScrollPage`, `ScrollHalf`); `$C3FA`-`$C3FB` (`StripCount`); `$CF2E`-`$CF2F` (`CourseRecord`); `$D14D`-`$D14E` (`ScrollDistance`) |

### `StripPhase4` (`$D413`)

**Make the 4-pixel phase in page H - 1, half 0**

H is the page of the last fresh strip (`$C3FC`). Steps the page offset `$C32E`. Copies H's half 0 two lines up into page H - 1, half 0 (the two lines below cleared), then shifts it 4 pixels right with RRD, taking the nibble entering from H - 2's half 0 at line 2. The last byte is 0 (docs/06-rendering.md 6.4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StripPhase2` (`$D45B`)

**Make the 2-pixel phase in page H - 1, half `$80`**

Copies H's half 0 one line up into page H - 1, half `$80` (line 0 cleared), then shifts it 2 pixels right, the 2 bits entering from H - 2's half 0 at line 3. The last bytes shift with nothing coming in (docs/06-rendering.md 6.4).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CourseExpand` (`$D4D9`)

**Expand a course record into RowList**

HL = a course record (CourseRecords). At `$FFFF` wraps to `$CF04` and sets CourseRecord. Each course byte b after the type selects the row list `$C8EA` + 2 x b (SegmentRows), copied word by word into RowList `$CA43` until a word with a zero high byte. Then the next row `$C3F8` = `$CA43` and the strip count `$C3FA` = 0 (docs/06-rendering.md 6.5).

| | |
| --- | --- |
| Runs (the bot game) | 9 calls, 246,517 t-states own (0.03 %) |
| Runs (the L1 build of the first recording's game window) | 10 calls, 273,018 t-states own (0.01 %) |
| Called from | `GameEntry`, `MainLoop`, `ScrollStep` |
| Reads | `$C8EA`-`$C99B` (`SegmentRows`); `$C9AE`-`$C9FB` (`SegmentRows`); `$CC18`-`$CE09` (`Course8`, `Course9`, `Course10`, `Course3` and 2 more); `$CEAC`-`$CF29` (`Course4`, `CourseTable`) |
| Writes | `$C3F8`-`$C3FB` (`CourseRowPtr`, `StripCount`); `$CA43`-`$CBA6` (`RowList`, `RowListTail`) |

### `FreshStrip` (`$D51D`)

**Make a fresh strip from tiles, and the phase 2 pixels left of it**

Half 0, even offset. The new strip is page `$80` + `$C32E`, half 0: 8 lines of the edge tile (EdgeTiles), then 15 tiles, tile i read from row i at offset i, rows popped from `$C3F8` on; `$C3F8` moves one row on. The page is kept in `$C3FC`. The tail makes page H - 2, half `$80`: H - 2's half 0 at line 1 shifted 2 pixels left, the 2 bits entering from H copied in at line 3 (docs/06-rendering.md 6.4, 6.5).

| | |
| --- | --- |
| Runs (the bot game) | 849 calls, 12,981,628 t-states own (1.32 %) |
| Runs (the L1 build of the first recording's game window) | 903 calls, 13,807,314 t-states own (0.46 %) |
| Called from | `ScrollStep` (tail) |
| Reads | `$8000`-`$BEFE` (the playfield buffer); `$C32E`-`$C332` (`ScrollPage`, `ScrollHalf`, `UnusedC330`, `SavedStack`); `$C3F8`-`$C8E9` (`CourseRowPtr`, `StripCount`, `FreshStripPage`, `UnusedC3FE` and 4 more) |
| Writes | `$8000`-`$BEFF` (the playfield buffer); `$C331`-`$C332` (`SavedStack`); `$C3F8`-`$C3FD` (`CourseRowPtr`, `StripCount`, `FreshStripPage`) |

## sprites

`src/game/sprites.asm`

### `BuildSpriteLists` (`$D9D6`)

**Shadow and sprite lists of the visible objects, the strips under them saved**

Step 7 of the pass (docs/04-game-loop.md 4.3), after `$EFA5` has put the visible records in the list at `$6500` (4-byte entries: depth, column, record address; bit 6 of the first byte ends it). Pads and dishes (types 14-15) are not in it; `$EA38` draws them first from their own list at `$C99E`.

The list is walked twice. The first walk (ShadowListLoop) makes the shadow list at `$FE64`, each object placed at the height of the ground under it; the second (SpriteListBuild) makes the sprite list at `$FF00`, each object at its own height (+4). For every entry the playfield strips it will cover are first copied to the save area at `$F800`, so that `$DD6C` can put the course back after the blit. The objects are drawn into the playfield buffer `$8000-$BFFF`, not onto the screen: shadows and sprites by `$DDE7` (step 8), before the blit `$D35E` copies the buffer to the screen (docs/06-rendering.md 6.3, 6.6).

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 24,205,266 t-states own (2.47 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 315,384 t-states own (0.01 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `ShadowListLoop`, `SaveSpriteStrips`, `SaveStrips`, `StampStatics` |
| Reads | `$6023`-`$62F6` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$6500`-`$6540` (`SpriteScratch`); `$C000`-`$C19B` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 1 more); `$C1B0`-`$C23B` (`LaunchedRecords`, `EnemyShotRecords`); `$C260`-`$C26B` (`PreviousVehicleRecord`); `$C300`-`$C32E` (`SpriteTable`, `ScrollPage`); 1 more ranges |
| Writes | `$D9D4`-`$D9D5` (`BlitListEnd`); `$DD66`-`$DD6B` (`ShadowListPtr`, `SpriteListPtr`, `SaveAreaPtr`); `$FE64`-`$FEBC` (`Im2Table`); `$FF00`-`$FF60` (`SpriteListArea`, `UdgLeftover`) |

### `ShadowListLoop` (`$D9F3`)

**Shadow list: the next visible record**

One entry of `$6500` a time: IX = the record. The column (+B) decides how many strips show: an object 4 columns or more inside the window has all its strips (4 for types 0-3, 3 for 4-10, 2 for 11-13); at either edge the strips that fall outside are dropped, and on the left the start moves on by whole strips (DE + `$FC` a strip: the next column, 4 lines lower in the buffer) while C counts the skipped mask bytes. Phase (+9) 0 or 2 drops one more strip. The line in the strip is +A plus the ground height from the profile at `$6000` (bits 0-4). The entry is finished at ShadowListAdd.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 10,384 calls, 4,232,277 t-states own (0.14 %) |
| Called from | `BuildSpriteLists`, `ShadowListAdd` (tail) |
| Calls | `ShadowListAdd` (tail), `SpriteListBuild` (tail) |
| Reads | `$6036`-`$629C` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$6500`-`$6538` (`SpriteScratch`); `$C000`-`$C050` (`PlayerRecord`, `PlayerShotRecords`); `$C0B0`-`$C17B` (`CourseObjectRecords`); `$C1A0`-`$C260` (`CourseObjectRecords`, `LaunchedRecords`, `EnemyShotRecords`, `PreviousVehicleRecord`); `$DD66`-`$DD67` (`ShadowListPtr`) |
| Writes | `$FE64`-`$FEAC` (`Im2Table`) |

### `ShadowListAdd` (`$DB6C`)

**Finish a shadow entry, save the strips under it**

In: A = lines a strip, A' = type, B = strips, C = the mask bytes skipped, D = column, E = line. The column becomes the playfield page through the scroll state `$C32E`, as the blit maps columns (docs/06-rendering.md 6.2): page `$80` + (`$C32E` + 2 x (column - 4)) mod 64. The 8-byte entry at ShadowListPtr: +0 type, +1 phase, +2/+3 the profile address, +4 strips, +5 mask offset, +6/+7 the buffer address. Then SaveStrips copies what the shadow will cover.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 8,065 calls, 1,879,145 t-states own (0.06 %) |
| Called from | `ShadowListLoop` (tail) |
| Calls | `ShadowListLoop` (tail), `SaveStrips` |
| Reads | `$C009` (`PlayerRecord`); `$C0B9`-`$C179` (`CourseObjectRecords`); `$C1A9`-`$C209` (`CourseObjectRecords`, `LaunchedRecords`); `$C32E` (`ScrollPage`); `$DD66`-`$DD67` (`ShadowListPtr`) |
| Writes | `$DD66`-`$DD67` (`ShadowListPtr`); `$FE64`-`$FEAB` (`Im2Table`) |

### `SpriteListBuild` (`$DB9A`)

**Sprite list: the visible records at their own heights**

The second walk of `$6500`. The line is +A plus the height +4. A dying record (bit 5) is drawn as a type 3 explosion, a line lower at height 25 and two lines lower above. The graphic is the word at `$C300` + (+8): +8 is twice the type normally (set at `$D246`, `$D2E3` and `$E2A4`) and the explosion counter while dying. The phase (+9) picks one of 4 pre-shifted frames: `$A8` bytes for types 0-3 (4 strips of 21 lines, a mask and a pixel byte a line), `$66` for 4-10 (3 strips of 17), `$34` for 11-13 (2 strips of 13). Clipping is as in ShadowListLoop; a dropped strip on the left moves the graphic on by one strip. The 6-byte entry at SpriteListPtr: +0 type, +1 strips, +2/+3 the buffer address, +4/+5 the graphic; then SaveSpriteStrips. `$EAE3` draws the list after the shadows.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 6,851,939 t-states own (0.23 %) |
| Called from | `ShadowListLoop` (tail) |
| Calls | `SaveSpriteStrips` |
| Reads | `$6500`-`$6538` (`SpriteScratch`); `$C000`-`$C05B` (`PlayerRecord`, `PlayerShotRecords`); `$C0B0`-`$C17B` (`CourseObjectRecords`); `$C1A0`-`$C26B` (`CourseObjectRecords`, `LaunchedRecords`, `EnemyShotRecords`, `PreviousVehicleRecord`); `$C300`-`$C32E` (`SpriteTable`, `ScrollPage`); `$DD68`-`$DD69` (`SpriteListPtr`) |
| Writes | `$D9D4`-`$D9D5` (`BlitListEnd`); `$DD68`-`$DD69` (`SpriteListPtr`); `$FF00`-`$FF54` (`SpriteListArea`) |

### `SaveSpriteStrips` (`$DD44`)

**Save the strips under the sprite just listed**

HL = the buffer address kept at `$D9D4` (HL held the graphic), then SaveStrips.

| | |
| --- | --- |
| Runs (the bot game) | 19,915 calls, 318,640 t-states own (0.03 %) |
| Runs (the L1 build of the first recording's game window) | 8,775 calls, 140,400 t-states own (0.00 %) |
| Called from | `BuildSpriteLists`, `SpriteListBuild` |
| Calls | `SaveStrips` |
| Reads | `$D9D4`-`$D9D5` (`BlitListEnd`) |

### `SaveStrips` (`$DD47`)

**Copy the strips an object will cover into the save area**

In: HL = the playfield address of the first strip's lowest line, B = strips, A = lines a strip. Each strip's lines are copied with LDIR to SaveAreaPtr (`$F800` on); the next strip is the next column of the buffer: 4 bytes lower (the 4-line skew of docs/06-rendering.md 6.3), two pages on, wrapping from `$C0` to `$80`. RestoreStrips undoes it after the blit.

| | |
| --- | --- |
| Runs (the bot game) | 30,480 calls, 33,844,684 t-states own (3.45 %) |
| Runs (the L1 build of the first recording's game window) | 16,840 calls, 21,709,568 t-states own (0.73 %) |
| Called from | `BuildSpriteLists`, `ShadowListAdd`, `SaveSpriteStrips` |
| Reads | `$8008`-`$BFF1` (the playfield buffer); `$DD6A`-`$DD6B` (`SaveAreaPtr`) |
| Writes | `$DD6A`-`$DD6B` (`SaveAreaPtr`); `$F800`-`$FBD3` (`SpriteSaveBuffer`) |

### `RestoreUnderSprites` (`$DD6C`)

**After the blit: the strips under every shadow and sprite put back**

Called by the blit `$D35E` once the buffer is on the screen (docs/06-rendering.md 6.1). Walks the shadow list `$FE64` (17, 11 or 4 lines a strip by type) and then the sprite list `$FF00` (21, 17 or 13), in the order BuildSpriteLists saved them, and copies the saved bytes back from `$F800` with RestoreStrips. The playfield is clean again for the scroller.

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 5,202,796 t-states own (0.53 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 3,049,403 t-states own (0.10 %) |
| Called from | `Blit` |
| Calls | `RestoreStrips` |
| Reads | `$FE64`-`$FEBC` (`Im2Table`); `$FF00`-`$FF60` (`SpriteListArea`, `UdgLeftover`) |
| Writes | `$DD6A`-`$DD6B` (`SaveAreaPtr`) |

### `RestoreStrips` (`$DDC9`)

**Copy saved strips back into the playfield buffer**

In: DE = the playfield address of the first strip's lowest line, B = strips, A = lines a strip; the bytes come from SaveAreaPtr on. The reverse of SaveStrips.

| | |
| --- | --- |
| Runs (the bot game) | 30,480 calls, 33,600,844 t-states own (3.43 %) |
| Runs (the L1 build of the first recording's game window) | 16,840 calls, 21,574,848 t-states own (0.72 %) |
| Called from | `RestoreUnderSprites` |
| Reads | `$DD6A`-`$DD6B` (`SaveAreaPtr`); `$F800`-`$FBD3` (`SpriteSaveBuffer`) |
| Writes | `$8008`-`$BFF1` (the playfield buffer); `$DD6A`-`$DD6B` (`SaveAreaPtr`) |

## shadows

`src/game/shadows.asm`

### `DrawShadows` (`$DDE7`)

**Shadows into the playfield buffer, then the sprites**

Step 8 of the pass (docs/04-game-loop.md 4.3), before the blit. For every entry of the shadow list `$FE64` it ANDs a shadow into the strips at the ground under the object, then jumps to `$EAE3`, which draws the sprite list `$FF00` over it.

Types 0-3 and 4-10: the shadow is first built as a mask in `$6500` (68 bytes, 4 strips of 17, or 33 bytes, 3 strips of 11; set to `$FF` = clear), from the shape tables below the image (`$5CE0`, `$5DE8`, `$5EF0` for types 0-3; `$5B60`, `$5BE0`, `$5C60` for 4-10), at an offset by the phase (+1). The Mask* helpers AND runs of shape bytes into it, strip by strip; each MaskStep* helper moves one profile byte (2 units along) further and shifts its run by the change of the ground height from ShadowGround, so the shadow follows the slope. The mask is then ANDed into the buffer from the entry's mask offset (+5), +4 strips, at the address +6/+7.

Types 11-13 (ShadowTiny): 4 bytes a strip from `$5B00`, `$5B20` or `$5B40` (the ground level, rising by 1, or more over the next profile byte), 8 bytes a phase, ANDed straight into the buffer.

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 30,038,040 t-states own (3.07 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 26,307,928 t-states own (0.88 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `MaskStepRuns5x3`, `MaskRuns5x3`, `MaskStepRuns4x4`, `MaskRuns4x4`, `MaskStepRuns3x5`, `MaskRuns3x5`, `MaskStepRuns2x6`, `MaskRuns2x6`, `MaskStepRuns5x5`, `MaskRuns5x5`, `MaskStepRuns4x6`, `MaskRuns4x6`, `MaskStepRuns3x7x3`, `MaskRuns3x7x3`, `MaskStepRuns1x6x4`, `MaskRuns1x6x4`, `DrawSprites` (tail) |
| Reads | `$5B00`-`$5B5F` (system); `$6023`-`$62F6` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$6500`-`$6543` (`SpriteScratch`); `$8008`-`$BFE3` (the playfield buffer); `$DD66`-`$DD67` (`ShadowListPtr`); `$FE64`-`$FEBC` (`Im2Table`) |
| Writes | `$6500`-`$6543` (`SpriteScratch`); `$8008`-`$BFE3` (the playfield buffer); `$DD66`-`$DD67` (`ShadowListPtr`); `$DDE6` (`ShadowGround`) |

### `MaskStepRuns5x3` (`$E05C`)

**Next profile byte, then MaskRuns5x3**

The MaskStep* entries share one head: BC moves to the next profile byte; E = `$6500` + D + (its ground height - ShadowGround), the mask position of the run in this strip, raised by the slope. They fall into the matching MaskRuns* entry.

| | |
| --- | --- |
| Runs (the bot game) | 2,540 calls, 163,026 t-states own (0.02 %) |
| Runs (the L1 build of the first recording's game window) | 3,760 calls, 241,279 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns5x3` |
| Reads | `$605C`-`$629F` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns5x3` (`$E06B`)

**AND 5 shape bytes into the mask at DE, then 3 more 7 on**

In: HL = the shape, DE = the mask in `$6500`. The MaskRuns* entries AND short runs of shape bytes into the mask: a run, a gap, a run (the gap is the step to the next strip of the mask), HL running on. This one: 5, a gap of 7, 3.

| | |
| --- | --- |
| Runs (the bot game) | 3,167 calls, 133,014 t-states own (0.01 %) |
| Runs (the L1 build of the first recording's game window) | 5,336 calls, 224,112 t-states own (0.01 %) |
| Called from | `DrawShadows`, `MaskStepRuns5x3` |
| Calls | `MaskAnd5`, `MaskAnd3` (tail) |

### `MaskStepRuns4x4` (`$E075`)

**Next profile byte, then MaskRuns4x4**

DrawShadows calls it between two runs of a big or mid shadow shape: BC on to the next profile byte (the ground under the next column), DE = SpriteScratch + (that byte AND `$1F`) - ShadowGround + D, so the next runs of the shape are ANDed into the mask where the ground there puts them; then it falls into the runs entry below.

| | |
| --- | --- |
| Runs (the bot game) | 2,012 calls, 129,208 t-states own (0.01 %) |
| Runs (the L1 build of the first recording's game window) | 4,321 calls, 277,511 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns4x4` |
| Reads | `$605D`-`$6298` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns4x4` (`$E084`)

**AND 4 shape bytes, then 4 more 7 on**

The mask shapes are runs of shape bytes ANDed into the mask at `$6500` (SpriteScratch) through the chain MaskAnd7-MaskAnd3: 4 bytes, then E + 7 (the mask is strips of 17 bytes), then 4 more. Used by DrawShadows; docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 3,167 calls, 133,014 t-states own (0.01 %) |
| Runs (the L1 build of the first recording's game window) | 5,336 calls, 224,112 t-states own (0.01 %) |
| Called from | `DrawShadows`, `MaskStepRuns4x4` |
| Calls | `MaskAnd4` (tail) |

### `MaskStepRuns3x5` (`$E08E`)

**Next profile byte, then MaskRuns3x5**

DrawShadows calls it between two runs of a big or mid shadow shape: BC on to the next profile byte (the ground under the next column), DE = SpriteScratch + (that byte AND `$1F`) - ShadowGround + D, so the next runs of the shape are ANDed into the mask where the ground there puts them; then it falls into the runs entry below.

| | |
| --- | --- |
| Runs (the bot game) | 2,526 calls, 161,897 t-states own (0.02 %) |
| Runs (the L1 build of the first recording's game window) | 3,695 calls, 236,848 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns3x5` |
| Reads | `$6060`-`$629D` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns3x5` (`$E09D`)

**AND 3 shape bytes, then 5 more 7 on**

The mask shapes are runs of shape bytes ANDed into the mask at `$6500` (SpriteScratch) through the chain MaskAnd7-MaskAnd3: 3 bytes, then E + 7 (the mask is strips of 17 bytes), then 5 more. Used by DrawShadows; docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 3,167 calls, 133,014 t-states own (0.01 %) |
| Runs (the L1 build of the first recording's game window) | 5,336 calls, 224,112 t-states own (0.01 %) |
| Called from | `DrawShadows`, `MaskStepRuns3x5` |
| Calls | `MaskAnd5` (tail), `MaskAnd3` |

### `MaskStepRuns2x6` (`$E0A7`)

**Next profile byte, then MaskRuns2x6**

DrawShadows calls it between two runs of a big or mid shadow shape: BC on to the next profile byte (the ground under the next column), DE = SpriteScratch + (that byte AND `$1F`) - ShadowGround + D, so the next runs of the shape are ANDed into the mask where the ground there puts them; then it falls into the runs entry below.

| | |
| --- | --- |
| Runs (the bot game) | 2,423 calls, 155,332 t-states own (0.02 %) |
| Runs (the L1 build of the first recording's game window) | 4,232 calls, 271,464 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns2x6` |
| Reads | `$605B`-`$629E` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns2x6` (`$E0B6`)

**AND 2 shape bytes, then 6 more 7 on**

The mask shapes are runs of shape bytes ANDed into the mask at `$6500` (SpriteScratch) through the chain MaskAnd7-MaskAnd3: 2 bytes, then E + 7 (the mask is strips of 17 bytes), then 6 more. Used by DrawShadows; docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 3,167 calls, 269,211 t-states own (0.03 %) |
| Runs (the L1 build of the first recording's game window) | 5,336 calls, 453,316 t-states own (0.02 %) |
| Called from | `DrawShadows`, `MaskStepRuns2x6` |
| Calls | `MaskAnd6` (tail) |
| Reads | `$5B78`-`$5BC1` (system); `$5BF8`-`$5C11` (system); `$5C28`-`$5C29` (system); `$5C40`-`$5C41` (system); `$5C78`-`$5C79` (system); `$5C90`-`$5C91` (system); 3 more ranges |
| Writes | `$6503`-`$650A` (`SpriteScratch`) |

### `MaskStepRuns5x5` (`$E0C6`)

**Next profile byte, then MaskRuns5x5**

DrawShadows calls it between two runs of a big or mid shadow shape: BC on to the next profile byte (the ground under the next column), DE = SpriteScratch + (that byte AND `$1F`) - ShadowGround + D, so the next runs of the shape are ANDed into the mask where the ground there puts them; then it falls into the runs entry below.

| | |
| --- | --- |
| Runs (the bot game) | 4,879 calls, 312,859 t-states own (0.03 %) |
| Runs (the L1 build of the first recording's game window) | 3,167 calls, 203,022 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns5x5` |
| Reads | `$602D`-`$62FB` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns5x5` (`$E0D5`)

**AND 5 shape bytes, then 5 more 11 on**

The mask shapes are runs of shape bytes ANDed into the mask at `$6500` (SpriteScratch) through the chain MaskAnd7-MaskAnd3: 5 bytes, then E + 7 (the mask is strips of 17 bytes), then 5 more. Used by DrawShadows; docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 5,604 calls, 235,368 t-states own (0.02 %) |
| Runs (the L1 build of the first recording's game window) | 3,583 calls, 150,486 t-states own (0.01 %) |
| Called from | `DrawShadows`, `MaskStepRuns5x5` |
| Calls | `MaskAnd5` (tail) |

### `MaskStepRuns4x6` (`$E0DF`)

**Next profile byte, then MaskRuns4x6**

DrawShadows calls it between two runs of a big or mid shadow shape: BC on to the next profile byte (the ground under the next column), DE = SpriteScratch + (that byte AND `$1F`) - ShadowGround + D, so the next runs of the shape are ANDed into the mask where the ground there puts them; then it falls into the runs entry below.

| | |
| --- | --- |
| Runs (the bot game) | 4,883 calls, 313,203 t-states own (0.03 %) |
| Runs (the L1 build of the first recording's game window) | 3,145 calls, 201,599 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns4x6` |
| Reads | `$602D`-`$62FB` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns4x6` (`$E0EE`)

**AND 4 shape bytes, then 6 more 11 on**

The mask shapes are runs of shape bytes ANDed into the mask at `$6500` (SpriteScratch) through the chain MaskAnd7-MaskAnd3: 4 bytes, then E + 7 (the mask is strips of 17 bytes), then 6 more. Used by DrawShadows; docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 6,468 calls, 271,656 t-states own (0.03 %) |
| Runs (the L1 build of the first recording's game window) | 4,359 calls, 183,078 t-states own (0.01 %) |
| Called from | `DrawShadows`, `MaskStepRuns4x6` |
| Calls | `MaskAnd6` (tail), `MaskAnd4` |

### `MaskStepRuns3x7x3` (`$E0F8`)

**Next profile byte, then MaskRuns3x7x3**

DrawShadows calls it between two runs of a big or mid shadow shape: BC on to the next profile byte (the ground under the next column), DE = SpriteScratch + (that byte AND `$1F`) - ShadowGround + D, so the next runs of the shape are ANDed into the mask where the ground there puts them; then it falls into the runs entry below.

| | |
| --- | --- |
| Runs (the bot game) | 5,743 calls, 368,392 t-states own (0.04 %) |
| Runs (the L1 build of the first recording's game window) | 3,943 calls, 252,790 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns3x7x3` |
| Reads | `$602D`-`$62FB` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns3x7x3` (`$E107`)

**AND 3 shape bytes, 7 more 11 on, 3 more 11 on**

The mask shapes are runs of shape bytes ANDed into the mask at `$6500` (SpriteScratch) through the chain MaskAnd7-MaskAnd3: 3 bytes, then E + 7 (the mask is strips of 17 bytes), then 7, then 3. Used by DrawShadows; docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 6,870 calls, 508,380 t-states own (0.05 %) |
| Runs (the L1 build of the first recording's game window) | 4,604 calls, 340,696 t-states own (0.01 %) |
| Called from | `DrawShadows`, `MaskStepRuns3x7x3` |
| Calls | `MaskAnd7`, `MaskAnd3` (tail) |

### `MaskStepRuns1x6x4` (`$E118`)

**Next profile byte, then MaskRuns1x6x4**

DrawShadows calls it between two runs of a big or mid shadow shape: BC on to the next profile byte (the ground under the next column), DE = SpriteScratch + (that byte AND `$1F`) - ShadowGround + D, so the next runs of the shape are ANDed into the mask where the ground there puts them; then it falls into the runs entry below.

| | |
| --- | --- |
| Runs (the bot game) | 5,285 calls, 339,203 t-states own (0.03 %) |
| Runs (the L1 build of the first recording's game window) | 3,390 calls, 217,819 t-states own (0.01 %) |
| Called from | `DrawShadows` |
| Calls | `MaskRuns1x6x4` |
| Reads | `$602D`-`$62FB` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$DDE6` (`ShadowGround`) |

### `MaskRuns1x6x4` (`$E127`)

**AND 1 shape byte, 6 more 12 on, 4 more 11 on**

The mask shapes are runs of shape bytes ANDed into the mask at `$6500` (SpriteScratch) through the chain MaskAnd7-MaskAnd3: 1 bytes, then E + 7 (the mask is strips of 17 bytes), then 6, then 4. Used by DrawShadows; docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 6,006 calls, 547,203 t-states own (0.06 %) |
| Runs (the L1 build of the first recording's game window) | 3,828 calls, 348,733 t-states own (0.01 %) |
| Called from | `DrawShadows`, `MaskStepRuns1x6x4` |
| Calls | `MaskAnd6`, `MaskAnd4` (tail) |
| Reads | `$5D01` (system); `$5D37` (system); `$5D70`-`$5DD3` (system); `$5E09` (system); `$5E3F` (system); `$5E78` (system); 3 more ranges |
| Writes | `$6505`-`$6520` (`SpriteScratch`) |

### `MaskAnd7` (`$E139`)

**AND 7 shape bytes into the mask**

In: HL = the shape, DE = the mask. One chain of entries: MaskAnd7, MaskAnd6, MaskAnd5, MaskAnd4 and MaskAnd3 AND that many bytes (HL and E move on; E stays on the last byte).

| | |
| --- | --- |
| Runs (the bot game) | 6,870 calls, 223,372 t-states own (0.02 %) |
| Runs (the L1 build of the first recording's game window) | 4,604 calls, 149,581 t-states own (0.01 %) |
| Called from | `MaskRuns3x7x3` |
| Calls | `MaskAnd6` |
| Reads | `$5CF7` (system); `$5D2D`-`$5D92` (system); `$5DC9` (system); `$5DFF` (system); `$5E35` (system); `$5E61`-`$5E6E` (system); 3 more ranges |
| Writes | `$6511`-`$652C` (`SpriteScratch`) |

### `MaskAnd6` (`$E13E`)

**AND 6 shape bytes into the mask**

Entry points of one chain: MaskAnd6, MaskAnd5, MaskAnd4, MaskAnd3 AND 6, 5, 4 or 3 shape bytes (HL) into the shadow mask (DE), each falling into the next; see MaskAnd7.

| | |
| --- | --- |
| Runs (the bot game) | 22,511 calls, 720,965 t-states own (0.07 %) |
| Runs (the L1 build of the first recording's game window) | 18,127 calls, 582,147 t-states own (0.02 %) |
| Called from | `MaskRuns2x6` (tail), `MaskRuns4x6` (tail), `MaskRuns1x6x4`, `MaskAnd7` |
| Calls | `MaskAnd5` |
| Reads | `$5B7A`-`$5BC2` (system); `$5BFA`-`$5C42` (system); `$5C7A`-`$5CC2` (system); `$5CEE`-`$5DD4` (system); `$5DF6`-`$5EB0` (system); `$5EC8`-`$5EDC` (system); 1 more ranges |
| Writes | `$650B`-`$652D` (`SpriteScratch`) |

### `MaskAnd5` (`$E143`)

**AND 5 shape bytes into the mask**

An entry into the AND chain (MaskAnd6 above): AND the remaining shape bytes into the shadow mask.

| | |
| --- | --- |
| Runs (the bot game) | 40,053 calls, 1,275,693 t-states own (0.13 %) |
| Runs (the L1 build of the first recording's game window) | 35,965 calls, 1,146,039 t-states own (0.04 %) |
| Called from | `MaskRuns5x3`, `MaskRuns3x5` (tail), `MaskRuns5x5` (tail), `MaskAnd6` |
| Calls | `MaskAnd4` |
| Reads | `$5B60`-`$5BE0` (system); `$5BF3`-`$5C30` (system); `$5C43`-`$5C48` (system); `$5C5B`-`$5C60` (system); `$5C73`-`$5CB0` (system); `$5CC3`-`$5CC8` (system); 2 more ranges |
| Writes | `$6500`-`$653D` (`SpriteScratch`) |

### `MaskAnd4` (`$E148`)

**AND 4 shape bytes into the mask**

An entry into the AND chain (MaskAnd6 above): AND the remaining shape bytes into the shadow mask.

| | |
| --- | --- |
| Runs (the bot game) | 58,861 calls, 1,874,956 t-states own (0.19 %) |
| Runs (the L1 build of the first recording's game window) | 54,824 calls, 1,745,515 t-states own (0.06 %) |
| Called from | `MaskRuns4x4` (tail), `MaskRuns4x6`, `MaskRuns1x6x4` (tail), `MaskAnd5` |
| Calls | `MaskAnd3` |
| Reads | `$5B61`-`$5EEC` (system); `$6501`-`$653E` (`SpriteScratch`) |
| Writes | `$6501`-`$653E` (`SpriteScratch`) |

### `MaskAnd3` (`$E14D`)

**AND 3 shape bytes into the mask**

An entry into the AND chain (MaskAnd6 above): AND the remaining shape bytes into the shadow mask.

| | |
| --- | --- |
| Runs (the bot game) | 78,935 calls, 7,967,490 t-states own (0.81 %) |
| Runs (the L1 build of the first recording's game window) | 74,704 calls, 7,542,450 t-states own (0.25 %) |
| Called from | `MaskRuns5x3` (tail), `MaskRuns3x5`, `MaskRuns3x7x3` (tail), `MaskAnd4` |
| Reads | `$5B62`-`$5EEF` (system); `$6502`-`$6541` (`SpriteScratch`) |
| Writes | `$6502`-`$6541` (`SpriteScratch`) |

## mover

`src/game/mover.asm`

### `MoveObjects` (`$E15C`)

**Objects: move, steer, height, walls and hits, once a pass**

Step 5 of the pass (docs/04-game-loop.md 4.3, docs/07-objects.md 7.4). Counts the passes in `$C271`, then moves every live record of `$C000` with MoveRecord. The new position along goes to `$C2EA`, across to `$C2F2`, the height to `$C2F6` (for the player, `$C2F6` already holds the height `$E7E9` or AUTO chose); StoreMove writes them back unless the record stopped.

| | |
| --- | --- |
| Runs (the bot game) | 2,623 calls, 194,102 t-states own (0.02 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 171,606 t-states own (0.01 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `MoveRecord`, `NextMover` (tail) |
| Reads | `$C000` (`PlayerRecord`); `$C271` (`PassCounter`) |
| Writes | `$C271` (`PassCounter`) |

### `MoveRecord` (`$E16E`)

**Move one record**

IX = the record. In order: the distance ahead of the scroll (`$D14D`): below 0 the record is gone, 352 or more it waits. A dying record (bit 5) counts its explosion. With behaviour bit 3, at 190 or more ahead, every 8th pass (+F) and on a random bit, it fires: pads and dishes (types 14-15) launch the template `$C2B4` + 9k (k from the highest of behaviour bits 7-4) into a free slot of `$C1B0-$C200`; the others fire the template `$C2E1` into the first free of the 6 slots from `$C210` (which takes in `$C260`). A record with no speed and no height behaviour stops here, except the player.

Then the step (direction table `$C340` times the speed +6), steering by behaviour bits 4-7, the height by bits 0-2, the terrain (TerrainHeight), walls and the barrier from the profile, and the hit boxes for PairScan (docs/07-objects.md 7.4, docs/10-gameplay-logic.md 10.3, 10.4).

| | |
| --- | --- |
| Runs (the bot game) | 45,568 calls, 34,930,026 t-states own (3.56 %) |
| Runs (the L1 build of the first recording's game window) | 41,495 calls, 20,352,490 t-states own (0.68 %) |
| Called from | `MoveObjects`, `NextMover` (tail) |
| Calls | `PairScan`, `StoreMove` (tail), `NextMover` (tail), `Random` |
| Reads | `$6036`-`$62F0` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C000`-`$C28E` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 8 more); `$C2B4`-`$C2F6` (`LaunchTemplates`, `EnemyShotTemplate`, `MoverAlong`, `HitWindowAlong` and 3 more); `$C340`-`$C35E` (`Directions`); `$C3F0`-`$C3F7` (`WeavePattern`); `$D14D`-`$D14E` (`ScrollDistance`); 2 more ranges |
| Writes | `$C000`-`$C098` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`); `$C0B0`-`$C26F` (`CourseObjectRecords`, `LaunchedRecords`, `EnemyShotRecords`, `PreviousVehicleRecord`); `$C2EA`-`$C2F6` (`MoverAlong`, `HitWindowAlong`, `MoverAcross`, `HitWindowAcross` and 1 more); `$E5DD`-`$E5E9` (`PairScanStep`); `$E60F`-`$E61B` (`PairScanStep`); `$E641`-`$E64D` (`PairScanStep`); 3 more ranges |

### `PairScan` (`$E56F`)

**Hit test: the moving record against every record**

IX = the moving record, HL = the other. Records that are gone or dying are passed over. The other's class picks the box: its position along less the box start (BC) must be below the width, as must its position across less the start, and its height less IYL below 15. The width operands are self-modified by MoveRecord (`$E555`): the box is centred along for every class, and across for others of types 0-10; against types 11-13 the across box starts at `$C2F4` and runs 2 lower than centred (`$C2F3`, the centred start, is written and not read). Pads (14) are never hit; dishes (15) only by the player, without a height test. A pair goes to the handler table at `$EBAA`, which skips the record itself (docs/07-objects.md 7.4, 7.6). The list's end goes to StoreMove.

| | |
| --- | --- |
| Runs (the bot game) | 656,852 calls, 77,865,101 t-states own (7.95 %) |
| Runs (the L1 build of the first recording's game window) | 311,496 calls, 36,548,402 t-states own (1.23 %) |
| Called from | `MoveRecord`, `PairScanStep` (tail) |
| Calls | `PairScanNext`, `StoreMove` (tail), `HitDispatch` (tail) |
| Reads | `$C000`-`$C306` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 26 more) |

### `PairScanNext` (`$E57E`)

**Drop the other record's address and go on**

Also the "nothing" handler of the hit table (docs/07-objects.md 7.6).

| | |
| --- | --- |
| Runs (the bot game) | 631,970 calls, 6,319,700 t-states own (0.64 %) |
| Runs (the L1 build of the first recording's game window) | 296,601 calls, 2,966,010 t-states own (0.10 %) |
| Called from | `PairScan`, `HitPlayerOnShot` (tail), `HitTargetOnShot` (tail), `HitPlayerOnPod` (tail) |
| Calls | `PairScanStep` |

### `PairScanStep` (`$E57F`)

**The next record of the scan**

The pair scan moves on to the next record (HL + 16) and tests it against the moving record IX again (PairScan). Most pairs come by falling through PairScanNext (the other record gone or dying, or the "nothing" handler of the table); it is jumped to directly when the other record is the moving one itself and from HitShotOnTarget when an enemy shot passes a moving target; entered 640 205 times in the bot game (PairScan 656 852) (docs/04-game-loop.md 4.5, docs/07-objects.md 7.6).

| | |
| --- | --- |
| Runs (the bot game) | 640,205 calls, 19,846,355 t-states own (2.03 %) |
| Runs (the L1 build of the first recording's game window) | 303,507 calls, 9,408,717 t-states own (0.32 %) |
| Called from | `PairScanNext`, `HitDispatch` (tail), `HitShotOnTarget` (tail) |
| Calls | `PairScan` (tail) |

### `StoreMove` (`$E65F`)

**Write the new position and height into the record**

From `$C2F6` (height), `$C2EA` (along) and `$C2F2` (across), into +4, +1/+2 and +3.

| | |
| --- | --- |
| Runs (the bot game) | 17,557 calls, 2,071,726 t-states own (0.21 %) |
| Runs (the L1 build of the first recording's game window) | 7,442 calls, 878,156 t-states own (0.03 %) |
| Called from | `MoveRecord` (tail), `PairScan` (tail), `HitBoth` (tail) |
| Calls | `NextMover` |
| Reads | `$C2EA`-`$C2F6` (`MoverAlong`, `HitWindowAlong`, `MoverAcross`, `HitWindowAcross` and 1 more) |
| Writes | `$C001`-`$C094` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`); `$C0B1`-`$C264` (`CourseObjectRecords`, `LaunchedRecords`, `EnemyShotRecords`, `PreviousVehicleRecord`) |

### `NextMover` (`$E674`)

**The next live record to move**

Gone records (bit 7) are passed over; bit 6 ends the list.

| | |
| --- | --- |
| Runs (the bot game) | 45,568 calls, 7,434,900 t-states own (0.76 %) |
| Runs (the L1 build of the first recording's game window) | 42,376 calls, 6,537,444 t-states own (0.22 %) |
| Called from | `MoveObjects` (tail), `MoveRecord` (tail), `StoreMove`, `HitNone` (tail), `HitTurnRound` (tail), `HitShotOnBlock` (tail), `HitShotOnDome` (tail) |
| Calls | `MoveRecord` (tail) |
| Reads | `$C010`-`$C270` (`PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord`, `CourseObjectRecords` and 4 more) |

## player

`src/game/player.asm`

### `ReadControls` (`$E68C`)

**Input: the AUTO countdown, or the chosen device into the control byte**

Called once a pass by the play loop outside the demo (docs/04-game-loop.md 4.3, step 4). While the countdown `$E68B` runs it does not read the device: it prints " AUTO " (`$64F6`), or six spaces (`$F136`) on the pass that ends the count, requests sound bit 3, moves the convoy, steers the player 2 across toward `$2C`, sets the new height `$C2F6` to the height - 1 (not below 2) plus (6 - count) / 2 over the last 6 passes, and sets the speed `$C006` to 0 while the reserve `$E7B8` lasts, else 1; the followers (`$C066` + 16 * k) get the same speed. docs/05-controls.md 5.4, docs/10-gameplay-logic.md 10.4.

With the countdown at 0 it reads the device chosen in the menu (`$C28F`: 0 keyboard, 1 Sinclair, 2 Kempston, 3 Protek-AGF) into the control byte `$C290` (bit 0 left, 1 right, 2 down, 3 up, 4 fire, active high) and jumps to the player routine `$E7E9`. docs/05-controls.md 5.2-5.3.

| | |
| --- | --- |
| Runs (the bot game) | 2,615 calls, 4,118,005 t-states own (0.42 %) |
| Runs (the L1 build of the first recording's game window) | 1,306 calls, 393,180 t-states own (0.01 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `ConvoyFollow`, `MovePlayer` (tail), `PrintString` |
| Reads | `$603B`-`$62A9` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C000`-`$C05F` (`PlayerRecord`, `PlayerShotRecords`); `$C282`-`$C290` (`MissileArc`, `InputDevice`, `ControlByte`); `$C360`-`$C37F` (`ShotTemplate`, `ShellTemplate`); `$E687`-`$E68B` (`DownHeldCount`, `UpHeldCount`, `LeftHeldCount`, `RightHeldCount` and 1 more); `$E7B7`-`$E7B8` (`FireCount`, `SpeedReserve`); 2 more ranges |
| Writes | `$C003`-`$C096` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`); `$C290` (`ControlByte`); `$C2F6` (`MoverHeight`); `$E687`-`$E68B` (`DownHeldCount`, `UpHeldCount`, `LeftHeldCount`, `RightHeldCount` and 1 more); `$E7B7`-`$E7B8` (`FireCount`, `SpeedReserve`); `$F2BF` (`SoundRequests`) |
| Ports in | `$021F`, `$EFFE`, `$F7FE` |

### `ConvoyFollow` (`$E7B9`)

**The followers copy the one in front**

With followers (`$ECE4` not 0) it walks the convoy links `$ECE7-$ECF0` from the last to the first: each follower's position across (+3) takes the value of the record in front of it (the first follower takes the player's `$C003`), and while the player moves (`$C006` not 0) the height (+4) too. Going from the back to the front makes each follower take its leader's value of the pass before: the convoy trails the player's moves. Called by `$E68C` (AUTO) and `$E7E9`. docs/07-objects.md 7.5, docs/10-gameplay-logic.md 10.4.

| | |
| --- | --- |
| Runs (the bot game) | 2,615 calls, 810,004 t-states own (0.08 %) |
| Runs (the L1 build of the first recording's game window) | 1,306 calls, 36,568 t-states own (0.00 %) |
| Called from | `ReadControls`, `MovePlayer` |
| Reads | `$C003`-`$C006` (`PlayerRecord`); `$C063`-`$C084` (`PodRecords`); `$ECE4`-`$ECF0` (`Followers`, `FollowerOffset`, `ConvoyLinks`) |
| Writes | `$C063`-`$C094` (`PodRecords`) |

### `MovePlayer` (`$E7E9`)

**The player: shot life, firing**

Entered by a jump from the device readers. It moves the convoy, ages the player's five shots (`$C010-$C050`, +F counts passes; at 12 a shot not exploding is removed) and fires while bit 4 of `$C290` is held: a shot every other pass into a free slot from template `$C360`, at the player's position + 4 along, its position across and 2 below its height; the ground vehicle (bit 0 of `$C000`) holding up as well lobs a shell instead, from template `$C370` every fourth pass, its arc step +E set from the player's height against the arc table `$C282`. Sound request bit 4 per shot. Falls into `$E8AF`. docs/07-objects.md 7.7, docs/10-gameplay-logic.md 10.3.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 746 calls, 314,495 t-states own (0.01 %) |
| Called from | `ReadControls` (tail) |
| Calls | `ConvoyFollow`, `PlayerSteer` |
| Reads | `$C000`-`$C05F` (`PlayerRecord`, `PlayerShotRecords`); `$C290` (`ControlByte`); `$C360`-`$C36F` (`ShotTemplate`); `$E7B7` (`FireCount`); `$F2BF` (`SoundRequests`) |
| Writes | `$C010`-`$C05F` (`PlayerShotRecords`); `$E7B7` (`FireCount`); `$F2BF` (`SoundRequests`) |

### `PlayerSteer` (`$E8AF`)

**The player: height or speed, walls, across**

The aircraft (type 0) changes height: down held adds (counter + 1) / 2 with the counter `$E687` growing to 6, up held subtracts with `$E688`; the new height `$C2F6` stays within 2-26. The ground vehicle (type 1) changes speed instead: 0 with down held while the reserve `$E7B8` lasts, 2 with up held while the reserve is below 32, 1 otherwise, and the followers get the same speed. docs/10-gameplay-logic.md 10.3.

Walls: six bytes of the course profile under the player (`$5FF7` + position / 2) are ORed; a bit 7 wall limits the position across to below `$17`, a bit 6 wall to below `$27`, else `$47`. A player already past the limit when a wall begins is crashed (`$E979`): it is hit, stops, moves back 2, and every follower is hit too, sound bit 1. Then left and right move it across, accelerating with the counters `$E689` and `$E68A` up to a step of 6, within 2 and the limit. docs/07-objects.md 7.4, 7.7.

| | |
| --- | --- |
| Runs (the L1 build of the first recording's game window) | 746 calls, 617,717 t-states own (0.02 %) |
| Called from | `MovePlayer` |
| Reads | `$6073`-`$61C4` (`ProfileBuffer`, `Entry`, `GroundProfileTail`); `$C000`-`$C004` (`PlayerRecord`); `$C290` (`ControlByte`); `$E687`-`$E68A` (`DownHeldCount`, `UpHeldCount`, `LeftHeldCount`, `RightHeldCount`) |
| Writes | `$C003` (`PlayerRecord`); `$C2F6` (`MoverHeight`); `$E687`-`$E68A` (`DownHeldCount`, `UpHeldCount`, `LeftHeldCount`, `RightHeldCount`) |

### `Random` (`$EA19`)

**The random number generator**

Returns a new 16-bit value in HL and keeps it in the seed `$EA36`: about 254 * (seed + 1) mod 65537, done with three subtractions instead of a multiply (checked by simulating the code over all seeds: 126 of 65 536 differ). The menu bumps the seed every pass of its loop (`$F20B`), so the player's time in the menu picks the sequence. Called by the game start (the demo's course, `$CF56`) and the mover (`$E16E`). docs/05-controls.md 5.1.

| | |
| --- | --- |
| Runs (the bot game) | 187 calls, 27,489 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 954 calls, 140,239 t-states own (0.00 %) |
| Called from | `GameEntry`, `MainLoop`, `MoveRecord` |
| Reads | `$EA36`-`$EA37` (`RandomSeed`) |
| Writes | `$EA36`-`$EA37` (`RandomSeed`) |

## statics

`src/game/statics.asm`

### `StampStatics` (`$EA38`)

**Static objects into the playfield buffer**

Called first by the sprite pass `$D9D6`. Walks the list at `$C99E` (record addresses, `$FF` ends it; 16 bytes in a gap of SegmentRows, the slots of course bytes `$5A-$61`, which no course uses) that `$EFDC` builds of the visible records of types 14 and 15, the launch pads and the dishes. A record is drawn only while its column +B is `$20-$23`, the strips at the far edge of the buffer: 4, 3, 2 or 1 strips of a masked sprite (14 mask and data byte pairs a strip; at column `$20` with phase 0, 3 strips). The target is in the playfield buffer `$8000-$BFFF` (high byte from the scroll offset `$C32E` + 2 * column + `$78`), the sprite from the pointer table at `$C300` + (+8), stepped `$70` bytes times ((phase +9) - 1) AND 3. So these objects are stamped into the course picture as it scrolls in, not drawn per pass. docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 1,044,573 t-states own (0.11 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 1,081,464 t-states own (0.04 %) |
| Called from | `BuildSpriteLists` |
| Reads | `$6F58`-`$729F` (`SpriteGfx1C`, `SpriteGfx1E`); `$8046`-`$BFD8` (the playfield buffer); `$C0B4`-`$C10B` (`CourseObjectRecords`); `$C124`-`$C1AB` (`CourseObjectRecords`); `$C31C`-`$C32E` (`SpriteTable`, `ScrollPage`); `$C99E`-`$C9AB` (`SegmentRows`) |
| Writes | `$8046`-`$BFD8` (the playfield buffer) |

### `DrawSprites` (`$EAE3`)

**The moving objects into the playfield buffer**

Reached by a jump from `$DDE7` after the strips under the sprites were saved. Walks the sprite list at `$FF00` that `$D9D6` rebuilds each pass: 6-byte entries of kind, strip count, buffer address and sprite address, `$FF` ends it (the pointer is kept at `$DD68`). Each strip is masked in (AND mask, OR data): 21 bytes for kinds 0-3, 17 for kinds 4-10, 13 for 11 and up, then 2 rows on in the buffer, wrapping inside `$8000-$BFFF`. docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 48,293,641 t-states own (4.93 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 26,374,274 t-states own (0.88 %) |
| Called from | `DrawShadows` (tail) |
| Reads | `$6580`-`$6A6B` (`SpriteGfx00`, `SpriteGfx02`); `$6CE2`-`$6F57` (`SpriteGfx06`); `$72A0`-`$7FFF` (`SpriteGfx14`, `SpriteGfx08`, `SpriteGfx0A`, `SpriteGfx0E` and 10 more); `$800E`-`$BFF1` (the playfield buffer); `$DD68`-`$DD69` (`SpriteListPtr`); `$FF00`-`$FF60` (`SpriteListArea`, `UdgLeftover`) |
| Writes | `$800E`-`$BFF1` (the playfield buffer); `$DD68`-`$DD69` (`SpriteListPtr`) |

## hits

`src/game/hits.asm`

### `HitDispatch` (`$EBAA`)

**A pair hit: jump through the handler table `$C380`**

Reached from the pair scan `$E56F` when the other record (HL, on the stack) is within the moving record's box. The same record is skipped (`$E57F`). Otherwise the moving record's type pair (IX+0 AND `$0E`) picks the row and the other's the column of the 7 x 8 word table at `$C380`, and the handler is entered with the other record's address on the stack. Handlers leave by `$E57E` (pop it and test the next record), `$E57F` (next, already popped), `$E674` (the moving record is done: its new position is not stored, `$E65F` is skipped) or `$E65F` via `$EBD1`. docs/07-objects.md 7.6.

| | |
| --- | --- |
| Runs (the bot game) | 9,475 calls, 606,087 t-states own (0.06 %) |
| Runs (the L1 build of the first recording's game window) | 7,671 calls, 468,736 t-states own (0.02 %) |
| Called from | `PairScan` (tail) |
| Calls | `PairScanStep` (tail), `HitBoth`, `HitNone`, `HitTurnRound`, `HitPlayerOnShot`, `HitTargetOnShot`, `HitShotOnTarget`, `HitShotOnBlock`, `HitPlayerOnPod`, `HitShotOnDome` |
| Reads | `$C000`-`$C090` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`); `$C0B0`-`$C260` (`CourseObjectRecords`, `LaunchedRecords`, `EnemyShotRecords`, `PreviousVehicleRecord`); `$C382`-`$C38D` (`HitHandlers`); `$C3A4`-`$C3CD` (`HitHandlers`); `$C3E2`-`$C3EB` (`HitHandlers`) |

### `HitScore` (`$EBCE`)

**Points, then both hit**

B tens of points (`$EE87`), then `$EBD1`. Entered with B = 21 (dome type 2), 32 (dome type 3, after it released a pod), 14 (a missile or a jet) or 18 (a cube on its 4th hit). docs/10-gameplay-logic.md 10.7.

| | |
| --- | --- |
| Runs (the bot game) | 70 calls, 1,190 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 5 calls, 85 t-states own (0.00 %) |
| Called from | `HitTargetOnShot` (tail), `HitShotOnTarget` (tail), `HitShotOnBlock` (tail), `HitShotOnDome` (tail) |
| Calls | `AddPoints` |

### `HitBoth` (`$EBD1`)

**Both records are hit**

Both records get bit 5 (hit) and the explosion counter +8 = `$20`; a moving one is slowed to speed 1. Sound request bit 1. Ends by storing the moving record's new position (`$E65F`). The table's cells for the player against the others (row 0, columns 0-4) and the others against the player (column 0) lead here. docs/07-objects.md 7.6.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 16,047 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | run into, not called, 2,756 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `StoreMove` (tail) |
| Reads | `$C000`-`$C056` (`PlayerRecord`, `PlayerShotRecords`); `$C0B0`-`$C196` (`CourseObjectRecords`); `$C1B0`-`$C206` (`LaunchedRecords`); `$F2BF` (`SoundRequests`) |
| Writes | `$C000`-`$C058` (`PlayerRecord`, `PlayerShotRecords`); `$C0B0`-`$C198` (`CourseObjectRecords`); `$C1B0`-`$C208` (`LaunchedRecords`); `$F2BF` (`SoundRequests`) |

### `HitShotOnShot` (`$EBFC`)

**Handler: a shot against a shot (not run in the recordings)**

Reached through the table only (row 6, column 6). POP HL; SET 7,(HL); JR `$EBE2`. The other shot is removed and the moving one explodes as in `$EBD1`, sound bit 1.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitPlayerOnStatic` (`$EC01`)

**Handler: the player against a pad or a dish (not run)**

Row 0, column 7: POP HL; JR `$EBE2`. Only the player is hit (and explodes, sound bit 1); the pad or dish stays.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitBlockOnOther` (`$EC04`)

**Handler: a cube or pod against types 2-11 (not run)**

Row 5, columns 1-5: BIT 0,(IX+`$00`); JP NZ,`$E57E`; then falls into `$EC0B`. A pod goes on with the scan, a cube ends it. Nothing is hit.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitNone` (`$EC0B`)

**Handler: nothing happens**

POP HL; JP `$E674`: the pair has no effect and the moving record's scan ends for this pass. The most common handler (609 runs in the first recording). docs/07-objects.md 7.6.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 3,760 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | run into, not called, 12,180 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `NextMover` (tail) |

### `HitTurnRound` (`$EC0F`)

**Handler: two missiles of types 4-5 turn round**

Both directions + 4 (mod 8). docs/07-objects.md 7.6.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 23,115 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | run into, not called, 10,695 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `NextMover` (tail) |
| Reads | `$C1B5`-`$C1F5` (`LaunchedRecords`) |
| Writes | `$C1B5`-`$C1F5` (`LaunchedRecords`) |

### `HitPlayerOnShot` (`$EC27`)

**Handler: the player against a shot**

The player's own shots fly in direction 0 and are ignored (`$E57E`); any other shot hits both (`$EBD1`). docs/07-objects.md 7.6.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 41,382 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | run into, not called, 1,482 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `PairScanNext` (tail) |
| Reads | `$C015`-`$C055` (`PlayerShotRecords`) |

### `HitShotOnPlayer` (`$EC35`)

**Handler: a shot against the player (not run)**

Row 6, column 0, the mirror of `$EC27`: LD A,(IX+`$05`); AND A; JP Z,`$E57E`; JP `$EBD1`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitTargetOnShot` (`$EC3F`)

**Handler: a missile or a jet (types 4-9) against a shot**

A shot of the player (direction 0): 140 points and both hit. An enemy shot: ignored while the missile moves, else the shot is removed. docs/10-gameplay-logic.md 10.7.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 1,571 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | run into, not called, 2,231 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `PairScanNext` (tail), `HitScore` (tail) |
| Reads | `$C015`-`$C055` (`PlayerShotRecords`); `$C1B6`-`$C245` (`LaunchedRecords`, `EnemyShotRecords`); `$C265` (`PreviousVehicleRecord`) |

### `HitShotOnTarget` (`$EC59`)

**Handler: a shot against a missile or a jet**

The mirror of `$EC3F` with the shot moving: a shot of the player scores 140 and both are hit; an enemy shot goes on past a moving target and is removed by a standing one. All five point awards of the first recording came this way. docs/07-objects.md 7.6.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 1,560 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | run into, not called, 1,318 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `PairScanStep` (tail), `HitScore` (tail) |
| Reads | `$C015`-`$C055` (`PlayerShotRecords`); `$C1C6`-`$C255` (`LaunchedRecords`, `EnemyShotRecords`) |

### `HitBlockOnShot` (`$EC73`)

**Handler: a cube or a pod against a shot (not run)**

Row 5, column 6, the mirror of `$ECAC` with the cube moving: an enemy shot or a pod ends at `$ECA6` (POP HL; SET 7,(HL): the shot is removed); a shot of the player counts a hit in the cube's +F, at the 4th it scores 180 (`$EBCE`, B = 18), otherwise the shot explodes (+6 = 0, +8 = `$20`) and sound request bit 2 (`$EC9E`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitShotOnBlock` (`$ECAC`)

**Handler: a shot against a cube or a pod**

An enemy shot, or any shot on a pod, is removed (`$ECDC`). A shot of the player counts a hit in the cube's +F: the 4th scores 180 points and both are hit; hits 1-3 only explode the shot, with sound request bit 2. docs/07-objects.md 7.6, docs/10-gameplay-logic.md 10.7.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 5,073 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `NextMover` (tail), `HitScore` (tail) |
| Reads | `$C010`-`$C090` (`PlayerShotRecords`, `PodRecords`); `$C100`-`$C10F` (`CourseObjectRecords`); `$F2BF` (`SoundRequests`) |
| Writes | `$C010`-`$C058` (`PlayerShotRecords`); `$C10F` (`CourseObjectRecords`); `$F2BF` (`SoundRequests`) |

### `HitPlayerOnPod` (`$ECF3`)

**Handler: the player against a cube or a pod**

A cube hits both (`$EBD1`). A pod (type 11) joins the convoy: it takes the player's +1-+7 (position, across, height, direction, speed, behaviour), is put FollowerOffset behind, its +3 address is appended to the links, the offset grows by 6, `$ECE4` counts it, and sound request bit 0 plays. The scan goes on. docs/07-objects.md 7.5.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 4,128 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `PairScanNext` (tail) |
| Reads | `$C001`-`$C007` (`PlayerRecord`); `$C060`-`$C092` (`PodRecords`); `$ECE4`-`$ECF2` (`Followers`, `FollowerOffset`, `ConvoyLinks`, `ConvoyLinkEnd`); `$F2BF` (`SoundRequests`) |
| Writes | `$C061`-`$C097` (`PodRecords`); `$ECE4`-`$ECF2` (`Followers`, `FollowerOffset`, `ConvoyLinks`, `ConvoyLinkEnd`); `$F2BF` (`SoundRequests`) |

### `HitBlockOnPlayer` (`$ED3B`)

**Handler: a cube or a pod against the player (not run)**

Row 5, column 0, the mirror of `$ECF3` with the pod moving: BIT 0,(IX+`$00`); JP Z,`$EBD1`, then the same join with IX and HL swapped, ending in sound request bit 0 (`$ED79`) and JP `$E674`.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitDomeOnShot` (`$ED81`)

**Handler: a dome against a shot (not run)**

Row 1, column 6, the mirror of `$EDCA` with the dome moving: an enemy shot passes a moving dome and is removed by a standing one; a shot of the player on a type 2 dome scores 210, on a type 3 dome it releases a pod into a free slot of `$C060-$C090` (`$EDB3`) and scores 320.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HitShotOnDome` (`$EDCA`)

**Handler: a shot against a dome**

An enemy shot passes a moving dome and is removed by a standing one (`$EDDC`). A shot of the player on a dome of type 2: 210 points and both hit. On type 3: a pod (type 11) is written into the first free slot of `$C060-$C090` at the dome's place (+1-+6), its +8 = `$16`, and 320 points; with no free slot, both are just hit. docs/07-objects.md 7.5.

| | |
| --- | --- |
| Runs (the bot game) | run into, not called, 3,837 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | run into, not called, 130 t-states own (0.00 %) |
| Called from | `HitDispatch` |
| Calls | `NextMover` (tail), `HitScore` (tail) |
| Reads | `$C015`-`$C090` (`PlayerShotRecords`, `PodRecords`); `$C0C0`-`$C0C6` (`CourseObjectRecords`); `$C0E6`-`$C126` (`CourseObjectRecords`); `$C140`-`$C156` (`CourseObjectRecords`); `$C180`-`$C196` (`CourseObjectRecords`); `$C220`-`$C225` (`EnemyShotRecords`) |
| Writes | `$C060`-`$C098` (`PodRecords`); `$C220` (`EnemyShotRecords`) |

## hud

`src/game/hud.asm`

### `PrintString` (`$EE17`)

**Print a string of records**

HL = the string: records of attribute + `$80`, column, row, characters `$20-$5F`; the next byte with bit 7 set starts a new record, `$FF` ends the string. Glyphs from the font at `$6300`, 8 lines each. docs/08-hud-and-text.md 8.1.

| | |
| --- | --- |
| Runs (the bot game) | 2,643 calls, 10,377,792 t-states own (1.06 %) |
| Runs (the L1 build of the first recording's game window) | 2,380 calls, 9,231,718 t-states own (0.31 %) |
| Called from | `GameEntry`, `MainLoop`, `RoundSetup`, `ReadControls`, `Menu` |
| Reads | `$6300`-`$64FF` (`Font`, `CreditsText1`, `FontHigh`, `CreditsText2` and 1 more); `$C2FA`-`$C2FF` (`RoundText`); `$C333`-`$C33F` (`ShotGaugeText`); `$EE13`-`$EE16` (`PrintScreenPos`, `PrintAttrPos`); `$F0E1`-`$F1A9` (`DemoMessage`, `PauseMessage`, `GameOverBox`, `AbortMessage` and 2 more) |
| Writes | `$40C2`-`$50AC` (screen); `$5121`-`$51AC` (screen); `$5221`-`$52AC` (screen); `$5321`-`$53AC` (screen); `$5421`-`$54AC` (screen); `$5521`-`$55AC` (screen); 10 more ranges |

### `AddPoints` (`$EE87`)

**Add B tens of points to SCORE**

SCORE is ASCII (`$EF49-$EF4E`, the last digit a fixed '0'): one ten at a time, a space counting as '0', with carry to the left. Falls into `$EE9E`. docs/08-hud-and-text.md 8.4.

| | |
| --- | --- |
| Runs (the bot game) | 70 calls, 100,830 t-states own (0.01 %) |
| Runs (the L1 build of the first recording's game window) | 5 calls, 5,877 t-states own (0.00 %) |
| Called from | `HitScore` |
| Calls | `ShowScore` |
| Reads | `$EF4A`-`$EF4D` (`Score`) |
| Writes | `$EF4A`-`$EF4D` (`Score`) |

### `ShowScore` (`$EE9E`)

**Draw SCORE in the panel**

SCORE's digits at `$529D` in small digits (`$EEA4`). Called by the round setup `$D151` too.

| | |
| --- | --- |
| Runs (the bot game) | 78 calls, 1,560 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 13 calls, 260 t-states own (0.00 %) |
| Called from | `RoundSetup`, `AddPoints` |
| Calls | `DrawDigits` |

### `DrawDigits` (`$EEA4`)

**Draw a number in small digits, right to left**

DE = the screen address of the units digit, BC = its character. Draws to the left until a '.' byte before the field, each digit from lines 2-6 of its glyph (`$6302` + (code - `$20`) * 8). docs/08-hud-and-text.md 8.4.

| | |
| --- | --- |
| Runs (the bot game) | 95 calls, 193,442 t-states own (0.02 %) |
| Runs (the L1 build of the first recording's game window) | 35 calls, 71,347 t-states own (0.00 %) |
| Called from | `ShowScore`, `UpdateHigh` (tail), `UpdateMax` (tail) |
| Reads | `$6302`-`$6306` (`Font`); `$6382`-`$63CE` (`Font`); `$EF48`-`$EF4E` (`ScoreStop`, `Score`); `$EF91`-`$EF9E` (`HighStop`, `HighScore`, `MaxStop`, `MaxScore`) |
| Writes | `$51B8`-`$51FD` (screen); `$5298`-`$52FD` (screen); `$5398`-`$53FD` (screen); `$5498`-`$54BD` (screen); `$54F8`-`$54FD` (screen); `$5598`-`$55BD` (screen); 2 more ranges |

### `ClearScores` (`$EEC4`)

**Clear SCORE, MAX and the round table**

Spaces into the round table entries of rounds 1-10 (`$EF55`, 60 bytes), SCORE and MAX; HIGH is kept. Called by the menu `$F1AA` when it is entered, not after the demo. docs/08-hud-and-text.md 8.4.

| | |
| --- | --- |
| Runs (the bot game) | 2 calls, 4,152 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 3 calls, 6,228 t-states own (0.00 %) |
| Called from | `Menu` |
| Writes | `$EF49`-`$EF9D` (`Score`, `RoundTable`, `HighStop`, `HighScore` and 2 more) |

### `UpdateHigh` (`$EEE3`)

**MAX into HIGH if higher, and draw HIGH**

First updates MAX from SCORE (`$EF17`). Then compares MAX with HIGH digit by digit as strings (a space sorts below the digits) and copies MAX into HIGH when it is higher. HIGH is drawn at `$51FD`. Called by the menu `$F1AA` when it is entered, not after the demo. docs/08-hud-and-text.md 8.4, docs/10-gameplay-logic.md 10.7.

| | |
| --- | --- |
| Runs (the bot game) | 2 calls, 818 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 3 calls, 1,424 t-states own (0.00 %) |
| Called from | `Menu` |
| Calls | `DrawDigits` (tail), `UpdateMax` |
| Reads | `$EF92`-`$EF9D` (`HighScore`, `MaxStop`, `MaxScore`) |
| Writes | `$EF92`-`$EF96` (`HighScore`) |

### `UpdateMax` (`$EF17`)

**SCORE into MAX if higher, and draw MAX**

The same string compare, SCORE against MAX; MAX is drawn at `$51BD`. Called by the round setup `$D151`, at every loss (`$CF33`) and by `$EEE3`. docs/10-gameplay-logic.md 10.7.

| | |
| --- | --- |
| Runs (the bot game) | 15 calls, 5,290 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 19 calls, 7,649 t-states own (0.00 %) |
| Called from | `GameEntry`, `MainLoop`, `RoundSetup`, `UpdateHigh` |
| Calls | `DrawDigits` (tail) |
| Reads | `$EF49`-`$EF4D` (`Score`); `$EF99`-`$EF9D` (`MaxScore`) |
| Writes | `$EF99`-`$EF9D` (`MaxScore`) |

## objview

`src/game/objview.asm`

### `PlaceObjects` (`$EFA5`)

**Objects to screen places and depth lists**

Once a pass (docs/04-game-loop.md 4.3, step 6). Starts three lists: `$C99E` (record addresses of visible types 14-15, `$FF` ends it), `$FF00` (4-byte entries sorted by height, a `$40` entry ends it) and `$6500` (the same, ended by `$40`). Calls `$EFDC` for every live record of `$C000` and at the end of the list jumps to `$F089`. docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 10,234,973 t-states own (1.04 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 9,061,703 t-states own (0.30 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `PlaceObject`, `SortDrawList` (tail) |
| Reads | `$C000`-`$C270` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 5 more) |
| Writes | `$6500`-`$6501` (`SpriteScratch`); `$C99F` (`SegmentRows`); `$EF9F`-`$EFA4` (`DrawListEnd`, `DepthListEnd`, `StaticListEnd`); `$FF00`-`$FF01` (`SpriteListArea`) |

### `PlaceObject` (`$EFDC`)

**One record: its screen place, into a list**

The distance ahead of the scroll (+1,+2 less `$D14D`) less the position across must be 1-`$11F`, else the record is not shown. It sets +B = (distance - across + 1) / 8, the column of strips; +9 = ((distance - across) / 2) AND 3, the phase within the strip, 1 while exploding; +A = `$C32F` + across + `$10` + phase. Types 14 and 15 go to the list at `$C99E` (stamped into the buffer by `$EA38`); the others are inserted into the `$FF00` list by height (+4), as height, (distance + across) / 2 + 1, record address. 41 391 calls in the first recording. docs/06-rendering.md 6.6, docs/07-objects.md 7.1.

| | |
| --- | --- |
| Runs (the bot game) | 45,256 calls, 24,924,260 t-states own (2.54 %) |
| Runs (the L1 build of the first recording's game window) | 41,391 calls, 14,379,619 t-states own (0.48 %) |
| Called from | `PlaceObjects` |
| Reads | `$C000`-`$C264` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 4 more); `$C32F` (`ScrollHalf`); `$D14D`-`$D14E` (`ScrollDistance`); `$EFA1`-`$EFA4` (`DepthListEnd`, `StaticListEnd`); `$FF00`-`$FF3D` (`SpriteListArea`) |
| Writes | `$C009`-`$C26B` (`PlayerRecord`, `PlayerShotRecords`, `PodRecords`, `ParkedVehicleRecord` and 4 more); `$C99E`-`$C9AB` (`SegmentRows`); `$EFA1`-`$EFA4` (`DepthListEnd`, `StaticListEnd`); `$FF00`-`$FF41` (`SpriteListArea`) |

### `SortDrawList` (`$F089`)

**The depth list into the draw list at `$6500`**

Each entry of `$FF00` (height, depth, record) is inserted into the list at `$6500` before the first entry more than 9 above it, or within 9 in height and with a smaller depth byte. So among objects that overlap in height, the farther one comes first. The draw list is read by the sprite pass `$D9D6`. docs/06-rendering.md 6.6.

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 16,127,746 t-states own (1.65 %) |
| Runs (the L1 build of the first recording's game window) | 2,319 calls, 5,738,184 t-states own (0.19 %) |
| Called from | `PlaceObjects` (tail) |
| Reads | `$6500`-`$653D` (`SpriteScratch`); `$EF9F`-`$EFA0` (`DrawListEnd`); `$FF00`-`$FF40` (`SpriteListArea`) |
| Writes | `$6500`-`$6541` (`SpriteScratch`); `$EF9F`-`$EFA0` (`DrawListEnd`) |

## menu

`src/game/menu.asm`

### `Menu` (`$F1AA`)

**The menu: device, demo or start**

Paints the cells of the list `$D5B2` with attribute 6 (`$D338`, docs/08-hud-and-text.md 8.5). Unless it is entered after the demo, it updates HIGH (`$EEE3`) and clears SCORE, MAX and the round table (`$EEC4`). Prints the menu and the credits, waits for all keys to be released, beeps. Then it loops: keys 1-4 choose the device (`$C28F`) and move the 13-cell highlight bar; 5 starts the demo; 6 starts the game; 256 * 2 000 passes with no key start the demo. Every pass increments the random seed `$EA36`. docs/05-controls.md 5.1.

| | |
| --- | --- |
| Runs (the bot game) | 2 calls, 144,748,638 t-states own (14.77 %) |
| Runs (the L1 build of the first recording's game window) | 4 calls, 60,067,405 t-states own (2.02 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `PaintAttributes`, `PrintString`, `ClearScores`, `UpdateHigh`, `Beep` |
| Reads | `$C28F` (`InputDevice`); `$EA36`-`$EA37` (`RandomSeed`); `$F0DB`-`$F0E0` (`DemoFlag`, `MenuIdleLow`, `MenuIdleHigh`, `MenuBarAttr`) |
| Writes | `$592A`-`$5936` (screen); `$594A`-`$5956` (screen); `$596A`-`$5976` (screen); `$59AA`-`$59B6` (screen); `$59CA`-`$59D6` (screen); `$C28F` (`InputDevice`); 2 more ranges |
| Ports in | `$00FE`, `$EFFE`, `$F7FE` |

### `BeepAt` (`$F284`)

**Beep with the length and pitch at HL**

HL points to a word: the length (high byte) and the pitch (low byte) for `$F288`. Used by the effect table (`$F2D9`).

| | |
| --- | --- |
| Runs (the bot game) | 568 calls, 13,632 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 560 calls, 13,440 t-states own (0.00 %) |
| Called from | `PlaySound` (tail) |
| Calls | `Beep` |
| Reads | `$F2F2`-`$F2F3` (`EffectTable`) |

### `Beep` (`$F288`)

**A two-tone beep**

H = length in 256-step units, L = pitch. Two square waves with half-periods of 256 - L and 257 - L steps (D and E count up to the wrap) toggle the beeper and MIC bits; their beating gives the warble. Border black. docs/09-sound.md 9.6.

| | |
| --- | --- |
| Runs (the bot game) | 580 calls, 51,410,651 t-states own (5.25 %) |
| Runs (the L1 build of the first recording's game window) | 612 calls, 72,299,824 t-states own (2.43 %) |
| Called from | `GameEntry`, `MainLoop`, `Menu`, `BeepAt` |
| Ports out | `$00FE`, `$18FE` |

### `Sweep` (`$F2A3`)

**A rising sweep**

HL points to four bytes: the step, the cycles of each tone, the start half-period and the number of tones. Each tone is the step shorter than the one before, so the pitch rises; the half-period D is 8 bits and wraps (0 waits 256), so a sweep that passes 0 drops to its lowest pitch and rises again (the round start's wraps three times). docs/09-sound.md 9.6.

| | |
| --- | --- |
| Runs (the bot game) | 857 calls, 60,674,104 t-states own (6.19 %) |
| Runs (the L1 build of the first recording's game window) | 48 calls, 14,872,421 t-states own (0.50 %) |
| Called from | `PlaySound` (tail) |
| Reads | `$F2E3`-`$F2FF` (`EffectTable`, `RoundStartSound`) |
| Ports out | `$00FE`, `$18FE` |

### `PlayEffect` (`$F2C0`)

**Play the requested effect of the highest priority**

The lowest set bit of `$F2BF` (bits 0-4) picks the 5-byte entry `$F2E2` + 5 * bit; nothing requested, nothing played. docs/09-sound.md 9.6.

| | |
| --- | --- |
| Runs (the bot game) | 2,622 calls, 422,214 t-states own (0.04 %) |
| Runs (the L1 build of the first recording's game window) | 2,318 calls, 349,242 t-states own (0.01 %) |
| Called from | `GameEntry`, `MainLoop` |
| Calls | `PlaySound` |
| Reads | `$F2BF` (`SoundRequests`) |

### `PlaySound` (`$F2D9`)

**Play one effect entry**

HL = a 5-byte entry: 0 and a beep word for `$F288`, or not 0 and four sweep bytes for `$F2A3`. The round setup plays the entry `$F2FB` through here.

| | |
| --- | --- |
| Runs (the bot game) | 1,425 calls, 47,045 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 608 calls, 16,896 t-states own (0.00 %) |
| Called from | `RoundSetup`, `PlayEffect` |
| Calls | `BeepAt` (tail), `Sweep` (tail) |
| Reads | `$F2E2`-`$F2FB` (`EffectTable`, `RoundStartSound`) |

## coursedata

`src/game/coursedata.asm`

### `Im2Jump` (`$FDFD`)

**The IM 2 jump**

Every interrupt vector of the table `$FE00-$FF00` is `$FDFD`. The start-up `$9F4B` writes JP `$9F68` here (EI; RET) and the title player `$803A` writes JP `$8340`, its handler; the image holds the latter. The game proper runs with interrupts off. docs/02-architecture.md 2.3-2.4.

| | |
| --- | --- |
| Runs (the bot game) | 1 call, 10 t-states own (0.00 %) |
| Runs (the L1 build of the first recording's game window) | 27,645 calls, 276,450 t-states own (0.01 %) |
| Called from | `TitleSetup`, `NoteTimeCheck`, `DrumTick`, `VoiceAEnvelope` |
| Calls | `TitleInterrupt` (tail) |
