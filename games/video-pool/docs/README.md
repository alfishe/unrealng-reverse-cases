# Video Pool: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | every screen and the flow between them, the play screen part by part, the controls and the hidden infinite-lives keys, the rack, a shot, twelve key moments, the rules and the score with a worked tally, the three variations, two players, the editor, the hall of fame, the difficulty by frame |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map, the three images, the scheduler and the foreground, the call graph split into interrupt and loop, the module heatmap and the frame budget |
| [3. Build and load](03-build-and-load.md) | the tape as a picture, the BASIC, the turbo loader (the ROM's LD-BYTES with three constants changed, and why they fit), the 16-bit sum, the load in `c1` with its animation, the build |
| [4. Game loop](04-game-loop.md) | no main loop; the program state machine; the IM 2 vector; the 25-slot scheduler; an aiming tick and the heaviest pass against the beam; the lost interrupts; the 437 000 T shot set-up (89 % of it the ROM's SQR); the sequences with the tasks stopped; the foreground's sound budget; the delays |
| [5. Controls](05-controls.md) | one input byte and its four readers (keyboard with KeyDown and the bit-ordered KeyTable, Interface 2, Kempston, cursor joystick), BREAK and the hidden toggle, the menu keys and the redefinition, the aiming cursor on a 756-step cushion perimeter, the power bar (+2 a frame, wrapping at `$86`) and the release, the name entry with its repeat, and the input one frame late against the interrupt |
| [6. Rendering](06-rendering.md) | the screen layout and attributes, XorLine (every vector line, its own eraser), the table drawing for large and small pockets, the pre-shifted XOR ball sprites drawn in three parts, the ball redraw against the beam (flicker-free in the recordings), code vs screen of the play screen, the pen signature script `$DA80` |
| [7. Objects](07-objects.md) | the seven 14-byte ball records, the ball state machine, the draw list, the rack scripts and their interpreter (six sets mapped, four known only from the code), the movers, the order of the collision tests, the two players' sets, the R register as the only randomness |
| [8. HUD and text](08-hud-and-text.md) | the print record and its one print routine, the two fonts (36 glyphs of the game, the rest from the ROM) and the wide print, the number printer with the position on the stack, the HUD and its two blinks, the score tally term by term with its falling beep, the messages and banners, the pocket marks, the hall of fame table, and a data sheet of all 75 records |
| [9. Sound](09-sound.md) | the beeper only, two players: the foreground SoundLoop `$8069` (ball, cushion, pocket tones; its timing, why the interrupt stretches it, the sound loop at work as an animation) and the ROM's BEEPER (clicks, the score count-up, the last-shot beep, the foul jingle), each decoded and measured; the request byte and its rules (last write wins, writes under a tone lost, the frozen pocket tone); what each sound costs in lost interrupts; the data sheet; every sound rendered to WAV |
| [10. Gameplay logic](10-gameplay-logic.md) | the physics profile (8.8 numbers, the shot through the ROM calculator, the friction table, cushions and self-patching jaws, the table-driven ball-ball exchange, a Python model equal to 475 frames of the `w1` break), the aiming aid and the absence of a computer player, the three variations, fouls, scoring, lives and frames, the infinite-lives keys (CAPS SHIFT + SPACE + 1 + 0, shown by an experiment), bugs, notable features |
| [11. Data reference](11-data-reference.md) | every data entry of the image (90), with its readers and writers in the recordings (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine (220) with its runs, time and figures (generated) |
| [14. Porting to the UKNC](14-porting-to-uknc.md) | the Spectrum and the UKNC side by side (two K1801VM2, three planes, the line table), the time budget measured and estimated on the two processors, instruction costs Z80 against VM2, the plan per subsystem, the resource converter and the ball sheet in the UKNC's format, the hot routines in PDP-11 sketches (8.8 words, tables and `MUL`, an exact integer AimShot, word-XOR ball drawing, the CPU/PPU mailbox, sound on the PPU timer), the tick-by-tick identity check, the risks ranked, BK and Soyuz-Neon notes |

There is no document 13 (no other version of the game is compared); 14 is the port document asked for by
[TODO.md](../../../TODO.md).

## Terms

Each term once, here; the documents link to it. The words of time are kept apart: a **video frame** (the machine's
1/50 s), an **interrupt** (the handler entered in it), a **tick** (an interrupt that ran the scheduler) and its
**pass** (the work of that tick); a **frame** without "video" is the game's rack.

| Term | Meaning |
| --- | --- |
| 8.8 | a 16-bit fixed-point number, whole pixels in the high byte, 1/256 in the low byte (stored first) (doc 10.1) |
| ball sprite | 48 bytes at BallSprites `$D000`, index 7 x shift + ball, XORed with no mask (doc 6) |
| balls16 | the UKNC port's 112 word-aligned ball copies (7 balls x 16 shifts), made by `tools/uknc_convert.py` (doc 14) |
| BEEPER | the 48K ROM routine `$03B5`: HL the period, DE the cycles, interrupts off; every sound that is not a tone (doc 9) |
| collision record | one of 31 sets of three 0.8 coefficients at `$DE3A` (dx², dy², \|dx dy\| over 225) (doc 10.5) |
| contact ring | the cells of ContactTable `$DBFA` with 218 <= d² <= 250, numbered 1-31; a ball is stepped back onto it before the exchange (doc 10.5) |
| cushion coordinate | the aiming cursor's position on the perimeter of the cushions, 0-755 (doc 5) |
| frame (game) | one rack of six object balls; the rack set and the pocket turn follow it. Not a video frame |
| friction step | the signed byte added to a velocity component every tick, about 5/256 pixel a tick against the motion, from FrictionTable `$DD3A` (doc 10.3) |
| friction turn | FrictionTurn `$8B4C`, the ball (0-6) whose friction steps are recomputed this tick (doc 10.3) |
| hall of fame slot | 71 bytes at HofTable `$AC08`; score and name move between slots, flag and pole stay (doc 8) |
| InputState | the one byte `$827C` every reader fills: right, left, up, down, fire, BREAK (bits 0-5) (doc 5) |
| interrupt | one entry of the IM 2 handler through `$FCFC`, once a video frame unless one is lost (doc 4) |
| jaw | the 45-degree wall of a corner pocket (DiagonalJaw `$8C7E`) or the point at a middle pocket's mouth (PointJaw `$8CF8`) (doc 10.4) |
| line table | the UKNC's chain of per-line records from PPU address 000270: each line's address, palette and scale (doc 14) |
| lost interrupt | a video frame whose INT falls while the interrupts are off (a long tick, AimShot, BEEPER), so it has no interrupt; the tick it would have run happens a frame later (docs 4, 9) |
| MessageStep | `$9F50`, the counter that shows, holds (75 frames) and removes a foul message (doc 8) |
| pass | the work of one tick, from Im2Handler's entry to its `RET` (doc 4); "a pass of" a named loop (SoundLoop, SoundDelay at 37 T) is one round of that loop |
| pen script | the 378-byte command list at `$DA80` that writes the signature on the presents screen (doc 6) |
| plane | one of the UKNC's three 64 KB memories; a pixel is one bit from each, at the same address (doc 14) |
| pocket box | the small rectangle a potted ball's centre is snapped into (PocketSnap `$8B71`) (doc 10.7) |
| pocket mark | "x1"-"x6" at a pocket, its score multiplier (doc 8) |
| pocket turn | `$9F43`, 0-5, the rotation of the pocket marks, one place each game frame (PocketTurn; doc 10.9) |
| PPU | the UKNC's peripheral processor (K1801VM2, 6.25 MHz) that owns the video, the speaker and the keyboard (doc 14) |
| print record | row, column, attribute, length, then the characters; attribute bit 7 means double width (doc 8) |
| rack script | the byte program (0 end, 1 place, 2 move, 3 wait) that rolls one object ball into place (doc 7.4) |
| rack set | one of six groups of six rack scripts at `$A0C4`, chosen by ((frame - 1) / 2) mod 6 (doc 7.4) |
| shot set-up | AimShot `$8A02`, the cue ball's velocity by the ROM's calculator: 437 092 T measured at `w1` frame 1079, the interrupt held 6.9 video frames (doc 4) |
| SoundLoop | the foreground loop at `$8069`: waits for SoundRequest and plays its tone; the interrupt freezes it (doc 9) |
| SoundRequest | the byte `$827D`: 1 ball, 2 cushion, 3 pocket, 0 none; written by the physics, cleared by the tone's end or by a task (doc 9) |
| step back | StepBack `$8E33`, moving a ball back along its velocity by less than a pixel (docs 10.4, 10.5) |
| tally | ScoreTally `$98FF`, the score of a shot printed term by term (frame x ball x multiplier x 10) and counted into the score with a falling beep (doc 8) |
| TallyPitch | `$9B34`, the count-up's tick period, 1200 at the start, 10 less each step (doc 9) |
| task | a routine in one of the 25 slots of TaskSlots `$91DF`, with a period p: it runs every p + 1 ticks (doc 4) |
| task list | (period, routine) triples ending in `$FF` (AimTasks `$84AA`, MovingTasks `$84BA`), installed and removed as a whole (doc 4) |
| tasks stopped | WaitFrameNoTasks `$80DE` writes `RET` at `$FCFD`, so an interrupt is only `EI; RET` and is not a tick; the long sequences between shots run this way, inside the ShotEnd task (doc 4) |
| tick | an interrupt that runs the scheduler RunTasks `$9155`: one step of every task whose countdown ran out. While the balls move PhysicsTask `$86C1` (period 0) runs once a tick, so the physics counts in ticks: the `w1` break has 159 ticks in 168 video frames (docs 4, 10.1) |
| tone | one of SoundLoop's three sounds: C cycles of two half periods of B delay passes (37 T each) (doc 9) |
| video frame | one 50 Hz television frame of the 48K, 69 888 T from one INT to the next; the unit of every recording, numbered from the recording's start |
| wide print | PrintCharWide `$9EDE`, each glyph pixel doubled into two bytes, two cells per character (doc 8) |
| XorLine | `$93B3`, the one horizontal-run XOR primitive behind every line of the table, the boxes and the flags (doc 6) |
