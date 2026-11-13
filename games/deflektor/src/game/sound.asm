; --------------------------------------------------------------------------------------------------------------------
; sound.asm: Sound: the beeper effects, the title tune
;
; Two players. The effects are 5-byte records (kind, four parameters) played by PlaySound $A8C0: kind 0 TwoTone (two
; square waves of nearly the same period), kind 1 a sweep, any other a burst of random noise. The interrupt plays one
; effect a frame, the lowest set bit of SoundFlags $A8A6 (records $81D4 + 5 x bit); the main code plays others
; directly (a level complete, a life lost, the end of the charge). The title tune (TitleTune $AD79) is a three-voice
; pulse player run with the interrupt off: 176 notes of three periods, about 10 frames a note.
; --------------------------------------------------------------------------------------------------------------------

  ORG $81D4

; PlaySound record: a sweep when a cell starts to burn (also SoundFlags bit 0)
;
; Kind 1 (PlaySweep `$A85E`): H 2, L 4, D `$2E`, E 9. PassEnd plays it directly
; (`$8657`) on a pass with a new explosion (BurnSoundFlag `$837B`);
; PlaySoundFlags `$A8A7` would also play it for SoundFlags bit 0, which nothing
; sets.
;
; The eight records `$81D4-$81FB` are one resource, tables/sounds.csv (5 bytes
; each: the kind, then four parameters).
BurnSound:
  INCBIN "res/tables/sounds.bin",$0000,5

; PlaySound record: SoundFlags bit 1, the beam on a mine (a falling sweep)
;
; Kind 1: H `$FE` (-2: the delay grows, the pitch falls), L 4, D `$46`, E 2.
; Played by the interrupt (PlaySoundFlags) every frame while BeamOnMine sets
; bit 1 (`$8F75`).
MineSound:
  INCBIN "res/tables/sounds.bin",$0005,5

; PlaySound record: SoundFlags bit 2, the beam back in the laser
;
; Kind 1: H `$0A`, L 3, D `$14`, E 1. Played by the interrupt while
; UpdateOverload `$A683` keeps bit 2 set (`$A6A9`).
LaserBackSound:
  INCBIN "res/tables/sounds.bin",$000A,5

; PlaySound record: SoundFlags bit 3, a cell burning (noise)
;
; Kind 2 (PlayNoise `$A87A`): D 2 (the period mask), E 4 (bursts), C `$0A` (the
; length mask), and the opcode `$A2` (`AND D`) that PlayNoise stores at NoiseOp
; `$A89F`. Bit 3 is set by PassEnd while an explosion is at `$58-$59`
; (`$860F`).
BurningNoise:
  INCBIN "res/tables/sounds.bin",$000F,5

; PlaySound record: SoundFlags bit 4, the laser charging (a warble)
;
; Kind 0 (PlayTone `$A83F`): L `$8C`, H 2 (TwoTone `$A843`: 2 x 256 loops). The
; last two bytes (`$81EB-$81EC`, zeros) are not read: a tone takes two
; parameters. Bit 4 is set by ChargeLaser (`$A5DA`).
ChargeWarble:
  INCBIN "res/tables/sounds.bin",$0014,5

; PlaySound record: a gremlin killed, and each life counted in the
; level-complete bonus
;
; Kind 1: H 2, L 4, D `$50`, E `$1E`. PassEnd (`$85B1`, GremlinSoundFlag
; `$837C` set by CursorFire) and LevelCompletePause (`$884D`, one per life
; left).
GremlinSound:
  INCBIN "res/tables/sounds.bin",$0019,5

; PlaySound record: the laser charged, and twice at the ending
;
; Kind 1: H 8, L 4, D 3, E `$64`. ChargeLaser (`$A60C`) when the bar is full,
; TheEnd (`$8896`, `$889C`), EndingScreen (`$A949`).
ChargedSound:
  INCBIN "res/tables/sounds.bin",$001E,5

; PlaySound record: CONTACT!, the beam in the receiver
;
; Kind 1: H 2, L 4, D 5, E `$DC`. LevelComplete `$87D4` (at `$87E3`).
ContactSound:
  INCBIN "res/tables/sounds.bin",$0023,5

; One byte of 0 after the sound records: never read or written
;
; No instruction addresses it and no recording reads or writes it.
Spare81FC:
  DEFB $00

  ORG $A83F

; Kind 0: L, H from the record, then TwoTone
;
; From PlaySound. The record `$81E8` (SoundFlags bit 4, the charge) is the only
; kind-0 record found: L = `$8C`, H = 2.
;
; Evidence: 16 418 runs.
;
; Witness: L1 22256 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
PlayTone:
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A

; A warble: two square waves of periods 256-L and 257-L loops toggle the
; speaker, for H x 256 loops
;
; D counts up from L, E from L-1; each that wraps to 0 toggles the speaker and
; MIC bits (`XOR $18`) and starts again from L (E from L-1). The two nearly
; equal periods beat against each other. B x C = H x 256 loops.
;
; Also called directly with HL as the tone: the menu (`$465A` 14.4 frames,
; `$28A0` 8.2, `$1478` 4.1), the pause (`$0F3C` 3.1), the abort (`$C814` 41.1),
; the name entry (`$3250` 10.3), the level complete (`$0A3C` 2.1 each step of
; the bonus count, and `$0204` (0.41 frame) after each life of the bonus, at
; `$8853`: HL is what PlaySweep left, GremlinSound's step and half-cycles);
; T-states by SkoolKit's simulator (work/ann/03-irq/simtime.py, no contention).
;
; Evidence: 17 972 runs.
;
; Witness: L1 24908 (c1, c1g, cheat, controls, ending, energy, energy-out,
; gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx
; x60).
TwoTone:
  LD C,H
  XOR A
  LD B,A
  LD D,L
  LD E,D
  DEC E
TwoToneLoop:
  OUT ($FE),A
  INC D
  JR NZ,TwoToneSecond
  LD D,L
  XOR $18
TwoToneSecond:
  INC E
  JR NZ,TwoToneNext
  LD E,L
  DEC E
  XOR $18
TwoToneNext:
  DJNZ TwoToneLoop
  DEC C
  JR NZ,TwoToneLoop
  RET

; Kind 1: E steps of L half-cycles, each of a delay D, D - H after each step (a
; falling or rising sweep)
;
; Record: H (the step), L (half-cycles a step), D (the first delay, `DJNZ`
; loops), E (steps). H > 0 shortens the delay (the pitch rises), `$FE` (-2, the
; mine's `$81D9`) lengthens it.
;
; Records: `$81D4` (BurnSound: played directly by PassEnd `$865A` on a pass
; with a new explosion; its flag bit 0 is never set), `$81D9` (bit 1, the beam
; on a mine, 0.20 frame), `$81DE` (bit 2, the beam in the laser, 0.02), `$81ED`
; (`$85B5`, 2.2 frames), `$81F2` (the charge done, the ending, 17.9), `$81F7`
; (CONTACT!, 43.3), `$8660` (5.99), `$8665` (a life lost, 2.6).
;
; Evidence: 43 809 runs.
;
; Witness: L1 50108 (c1, c1g, cheat, controls, corner, ending, energy,
; energy-out, gameover, hof, kempston, menu, mine, nameedit, overload,
; practice, L x20, rzx x60).
PlaySweep:
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD E,(HL)
  LD H,B
  LD L,C
SweepStepLoop:
  XOR A
  LD C,L
SweepHalfCycle:
  XOR $18
  LD B,D
SweepDelay:
  OUT ($FE),A
  DJNZ SweepDelay
  DEC C
  JR NZ,SweepHalfCycle
  LD A,D
  SUB H
  LD D,A
  DEC E
  JR NZ,SweepStepLoop
  RET

; Kind 2: E bursts of random length and period; the record's 4th byte is an
; opcode written into the code
;
; Record: D (the period mask), E (bursts), C (the length mask), and an opcode
; byte stored at NoiseOp `$A89F` (self-modifying: `$A2` = `AND D`, the image's
; own). Each burst: L half-cycles of a delay B, then a random pair from
; `$8E15`: L = (L AND C) + 1, B = (H op D) + 1.
;
; The record `$81E3` (SoundFlags bit 3: a burning cell, `$860F`): D = 2, E = 4,
; C = `$0A`, `AND D`; 0.04 frame.
;
; Evidence: 11 171 runs (53 RZX segments).
;
; Witness: L1 16546 (corner, L x20, rzx x53).
PlayNoise:
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  LD HL,NoiseOp           ; the opcode byte into the code
  LD (HL),A
  LD B,$02
  LD L,$02
NoiseBurstLoop:
  XOR A
NoiseHalfCycle:
  XOR $18
  PUSH BC
NoiseDelay:
  OUT ($FE),A
  DJNZ NoiseDelay
  POP BC
  DEC L
  JR NZ,NoiseHalfCycle
  PUSH DE                 ; a new random length and period
  CALL Random
  POP DE
  LD A,L
  AND C
  INC A
  LD L,A
  LD A,H
NoiseOp:
  AND D                   ; AND D, or the opcode the record gives
  INC A
  LD B,A
  DEC E
  JR NZ,NoiseBurstLoop
  RET

; The effects asked for: bit 0 (dormant), 1 mine, 2 laser overload, 3 a cell
; burning, 4 the charge
;
; Set by the main code, played by PlaySoundFlags from the interrupt (the lowest
; set bit, one effect a frame, as long as the bit stays set). Bit 1: the beam
; on a mine (`$8F75`); bit 2: the beam back in the laser (`$A6A9`, which clears
; bit 1); bits 1 and 2 cleared by CoolOverload; bit 3: a cell burning (`$860F`,
; cleared each pass at `$85D6`); bit 4: ChargeLaser (`$A5DA`, all cleared when
; charged). No instruction sets bit 0 (its record `$81D4` is dormant). Cleared
; at a level start (`$84AD`), a life lost (`$866B`), a level complete
; (`$87D5`), the menu (`$9BC2`); the pause saves it.
SoundFlags:
  DEFB $00

; From the interrupt: the effect of the lowest set bit 0-4 of SoundFlags,
; record $81D4 + 5 x bit
;
; B counts 5 down while the flags are rotated right; the first carry gives the
; bit (5 - B), HL = `$81D4` + 5 x bit, then PlaySound. No bit: return.
;
; Evidence: 381 862 runs (every interrupt).
;
; Witness: L1 487506 (c1, c1g, cheat, controls, corner, ending, energy,
; energy-out, gameover, hof, kempston, menu, mine, nameedit, overload,
; practice, L x20, rzx x60).
PlaySoundFlags:
  LD A,(SoundFlags)
  LD B,$05
SoundFlagsLoop:
  RRA
  JR C,SoundFlagsFound
  DJNZ SoundFlagsLoop
  RET
SoundFlagsFound:
  LD A,$05
  SUB B
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,BurnSound
  ADD HL,BC

; Play the 5-byte effect record at HL: kind 0 PlayTone, 1 PlaySweep, else
; PlayNoise
;
; Called directly by the main code (`$85B5`, `$85E7`, `$865A`, `$8683`,
; `$869D`, `$86C4`, `$87E6`, `$8850`, `$8899`, `$889F`, ChargeLaser `$A60F`,
; EndingScreen `$A94C`) and from PlaySoundFlags.
;
; Evidence: 71 398 runs.
;
; Witness: L1 88910 (c1, c1g, cheat, controls, corner, ending, energy,
; energy-out, gameover, hof, kempston, menu, mine, nameedit, overload,
; practice, L x20, rzx x60).
PlaySound:
  LD A,(HL)
  INC HL
  AND A
  JP Z,PlayTone
  CP $01
  JP Z,PlaySweep
  JP PlayNoise

  ORG $AD79

; The title tune with the interrupt off: 176 notes from TitleTuneData, again
; and again until a key
;
; `DI`; IX = TitleTuneData, B = `$B0` notes; each note: H, L, D the three
; voices' periods, BC = `$1770` (6000) loops of PlayNote. After each note the
; keyboard (all half rows): a key ends it with `EI`. After the last note it
; starts again.
;
; Called by TitleScreen `$A754`, the pause `$97AE` (the "pause's tune"), the
; ending `$88AA`. One note takes 677 051-733 334 T (9.7-10.5 frames), the tune
; 35.4 s (SkoolKit's simulator, work/ann/03-irq/simtime.py).
;
; Evidence: 12 runs (`c1g`, `controls`, `gameover`, `kempston`, `menu`, `mine`,
; `overload`, `rzx-344752`).
;
; Witness: L1 17 (c1, c1g, controls, ending, energy-out, gameover, hof,
; kempston, menu, mine, nameedit, overload, rzx344752).
TitleTune:
  DI
; This entry point is used by the routine at TitleTuneNoteLoop.
TitleTuneRestart:
  LD B,$B0
  LD IX,TitleTuneData

; TitleTuneNoteLoop
TitleTuneNoteLoop:
  PUSH BC
  LD H,(IX+$00)
  LD L,(IX+$01)
  LD D,(IX+$02)
  LD BC,$1770
  CALL PlayNote
  POP BC
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JP NZ,TitleTuneEnd
  INC IX
  INC IX
  INC IX
  DJNZ TitleTuneNoteLoop
  JP TitleTuneRestart
TitleTuneEnd:
  EI
  RET

; The inner loop of a note: three counters; each that reaches 0 sends a short
; pulse and reloads
;
; H, L, D count down once a loop; at 0 the speaker goes off (`OUT` 0) for C =
; 15 `DJNZ` loops and back on (`$10`) for 16 - C = 1, then the counter is
; reloaded from the note (IX+0, +1, +2). So each voice is a train of short
; pulses at 3.5 MHz / (about 108 T x period): `$42` about 490 Hz, `$84` about
; 245 Hz. BC on the stack counts the note's loops (`ADE8`); `NOP NOP` pad the
; loop.
;
; Evidence: 6 919 984 runs.
;
; Witness: L1 10535890 (c1, c1g, controls, ending, energy, energy-out,
; gameover, hof, kempston, menu, mine, nameedit, overload, practice,
; rzx344752).
PlayNote:
  PUSH BC
  NOP
  NOP
  LD C,$0F
  DEC H
  JR NZ,NoteVoice2
  XOR A
  OUT ($FE),A
  LD B,C
NoteVoice1Off:
  DJNZ NoteVoice1Off
  LD A,$10
  OUT ($FE),A
  SUB C
  LD B,A
NoteVoice1On:
  DJNZ NoteVoice1On
  LD H,(IX+$00)
NoteVoice2:
  DEC L
  JR NZ,NoteVoice3
  XOR A
  OUT ($FE),A
  LD B,C
NoteVoice2Off:
  DJNZ NoteVoice2Off
  LD A,$10
  OUT ($FE),A
  SUB C
  LD B,A
NoteVoice2On:
  DJNZ NoteVoice2On
  LD L,(IX+$01)
NoteVoice3:
  DEC D
  JR NZ,NoteLoopEnd
  XOR A
  OUT ($FE),A
  LD B,C
NoteVoice3Off:
  DJNZ NoteVoice3Off
  LD A,$10
  OUT ($FE),A
  SUB C
  LD B,A
NoteVoice3On:
  DJNZ NoteVoice3On
  LD D,(IX+$02)

; NoteLoopEnd
;
; Used by the routine at PlayNote.
NoteLoopEnd:
  POP BC                  ; the note's loop count (BC on the stack)
  DEC BC
  LD A,B
  OR C
  JP NZ,PlayNote
  RET

; The title tune: 176 notes of three periods (voice 1, 2, 3), up to $AFFF
;
; 528 bytes, `$ADF0-$AFFF`; 54 different periods from `$2B` to `$E2`. Read by
; TitleTune. Evidence: read in `c1g`, `controls`, `gameover`, `kempston`,
; `menu`, `mine`, `overload`, `rzx-344752`.
TitleTuneData:
  INCBIN "res/tables/title-tune.bin",$0000,528
