; --------------------------------------------------------------------------------------------------------------------
; music.asm: The AY music player: one tune (the title music), three channels, commands, instruments, ornaments
;
; The interrupt calls MusicTick $C0D2 every frame through Bank4Tick ($72D2, bank 5), with bank 4 paged; StartTune
; $C000 (from Bank4Start $72C6, A = 0) starts the tune and StopMusic $C1A2 (Bank4Call $72E9) silences it. Each channel
; has a 39-byte record (ChannelRecords $C05A): it reads its order list (NextPattern $C554), then the pattern's notes
; and commands (ChannelStep $C295, Command $C320) and, every frame, makes its frequency and volume from the note, the
; instrument's volume envelope, the ornament, the vibrato and the slide (ChannelSound $C36A). The 12 AY registers are
; kept in AYShadow $C47B and written out at the end of each tick (ports `$FFFD` / `$BFFD`).
;
; The tune's data (ornaments, instruments, the tune record, the patterns) is one resource, src/res/music/tune.bin. A
; sound effect engine (StartEffect $C5E1, one effect) is built in but never started in any recording.
; --------------------------------------------------------------------------------------------------------------------

; Start tune A: the tune's speed and three order lists from TuneTable, the
; channel records reset, the music on
;
; Input: A = the tune (7-byte records at TuneTable `$C869`; only tune 0
; exists). Clears MusicOn and EffectOn, the speed into the operand `$C0FE`,
; then for each channel: transpose (+`$20`), repeat (+`$21`), duration count 1
; (+`$10`), flags, vibrato and drum off, the order list into +`$03` and +`$05`
; (the restart point), +`$25` = 1 (take a pattern first); the global transpose
; `$C39D` = 0, SpeedCount and MusicOn = 1.
;
; Witness frames (first-last frame of the recording, runs): c1 24005-24633 (2),
; controls 125-294 (2), m2erbe 7553-7554 (1), menu 125-1904 (4), missions
; 8062-34099 (8), play 10724 (1), play2 9718-23564 (3).
;
; Witness: L1 19 (c1, m2erbe, menu, missions, play, play2).
StartTune:
  LD HL,MusicOn
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD C,A
  ADD A,A
  ADD A,C
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,TuneTable
  ADD HL,BC
  LD A,(HL)
  LD (SpeedOp+$0001),A
  INC HL
  LD IX,ChannelRecords
  LD C,$27
  LD A,$03
l_C021:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (IX+$20),$00
  LD (IX+$21),$00
  LD (IX+$10),$01
  LD (IX+$00),B
  LD (IX+$1D),B
  LD (IX+$1F),B
  LD (IX+$03),E
  LD (IX+$04),D
  LD (IX+$05),E
  LD (IX+$06),D
  LD (IX+$25),$01
  ADD IX,BC
  DEC A
  JR NZ,l_C021
  LD (TransposeOp+$0001),A
  INC A
  LD (SpeedCount),A
  LD (MusicOn),A
  RET

; The three channels' records, 39 bytes each: A at $C05A, B at $C081, C at
; $C0A8
;
; Fields: +0 flags (bit 0 the vibrato's half phase, bit 1 set by command `$8D`,
; bit 2 slide, bit 3 bend, bit 5 the volume envelope runs, bit 7 bend up), +1
; the pattern pointer, +3 the order list pointer, +5 the order list's start, +7
; the slide's sum, +9 the ornament (start), +`$0B` the ornament (now), +`$0D`
; the slide step, +`$0E` the slide delay, +`$0F` the instrument's speed, +`$10`
; the frames left of the note, +`$11` the fixed duration, +`$12` the note,
; +`$13` the volume, +`$14` the instrument, +`$16` its envelope pointer, +`$18`
; its volume now, +`$19` its speed count, +`$1A` the vibrato depth, +`$1B` its
; step, +`$1C` its position, +`$1D` the vibrato mode (`$40` on, `$C0` every
; other frame, bit 5 the direction), +`$1E` noise follows the note, +`$1F` the
; drum (bit 7 a hit pending), +`$20` the pattern's transpose, +`$21` the repeat
; count, +`$22` the repeat's start, +`$24` durations inline, +`$25` take the
; next pattern, +`$26` the channel's mixer bits (`$09`, `$12`, `$24`). Zero at
; the entry but the mixer bits.
ChannelRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09
ChannelB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$12
ChannelC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$24
SpeedCount:
  DEFB $00                ; frames to the next step of the patterns
MusicOn:
  DEFB $00
EffectOn:
  DEFB $00

; One frame of music: the effect, the patterns every SpeedCount frames, each
; channel's sound, the AY registers out
;
; Calls EffectTick; when MusicOn, counts SpeedCount down and at 0 steps the
; three channels (ChannelStep) and reloads it from the speed (`$C0FE`); then
; ChannelSound per channel into the tone words `$C47B`, `$C47D`, `$C47F` and
; the volumes `$C483`-`$C485`, and the noise period from `$C12A` into `$C481`.
; When EffectOn, the effect's tone A, tone C, noise, mixer and volumes replace
; the music's. If either is on, registers 11 down to 0 go out from `$C486` down
; (`OUT` on `$FFFD`, `OUTD` on `$BFFD`).
;
; Witness frames (first-last frame of the recording, runs): c1 24005-33298
; (4415), controls 0-330 (259), death 0-20038 (15291), m10 0-9028 (6442),
; m2erbe 0-7808 (3258), m2ocean 0-4799 (2252), menu 0-10996 (7704), missions
; 0-35997 (14024), play 0-10930 (6216), play2 0-23665 (14418), search 0-5043
; (2273).
;
; Witness: L1 76293 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
MusicTick:
  CALL EffectTick
  LD A,(MusicOn)
  AND A
  JP Z,EffectMix
NoiseOp:
  LD A,$00                ; LD A,n: n ($C0DD) the noise period the last noise
                          ; note set
  LD (NoiseOutOp+$0001),A
  LD HL,SpeedCount
  DEC (HL)
  JR NZ,l_C102
  LD B,(HL)
  LD IX,ChannelRecords
  CALL ChannelStep
  LD IX,ChannelB
  CALL ChannelStep
  LD IX,ChannelC
  CALL ChannelStep
SpeedOp:
  LD A,$01                ; LD A,n: n ($C0FE) the tune's speed
  LD (SpeedCount),A
l_C102:
  LD IX,ChannelRecords
  CALL ChannelSound
  LD (AYShadow),HL
  LD (AYVolumes),A
  LD IX,ChannelB
  CALL ChannelSound
  LD (AYShadow+$0002),HL
  LD (AYVolumes+$0001),A
  LD IX,ChannelC
  CALL ChannelSound
  LD (AYShadow+$0004),HL
  LD (AYVolumes+$0002),A
NoiseOutOp:
  LD A,$00                ; LD A,n: n ($C12A) the noise period for register 6
                          ; this frame
  LD (AYNoise),A
EffectMix:
  LD A,(EffectOn)
  AND A
  JR Z,WriteRegisters
  LD HL,(EffectRegs)
  LD (AYShadow),HL
  LD HL,(EffectRegs+$0004)
  LD (AYShadow+$0004),HL
  LD A,(EffectRegs+$0006)
  LD (AYNoise),A
  LD A,(AYMixer)
  OR $2D
  LD HL,EffectRegs+$0007
  AND (HL)
  LD (AYMixer),A
  LD A,(EffectRegs+$0008)
  LD (AYVolumes),A
  LD A,(EffectRegs+$000A)
  LD (AYVolumes+$0002),A
WriteRegisters:
  LD A,(MusicOn)
  LD HL,EffectOn
  OR (HL)
  RET Z
  LD HL,AYVolumes+$0003
  LD A,$0B
  LD C,$FD
l_C16D:
  LD B,$FF
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  JP P,l_C16D
  RET

; Write E to AY register D
;
; Known only from the code as a routine of its own: called by StartEffect,
; which no recording runs.
WriteAY:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; Registers 13 down to 0 to zero, then the mixer (register 7) to $3F: all quiet
;
; Witness frames (first-last frame of the recording, runs): c1 24571-24716 (2),
; controls 61-224 (2), death 98 (1), m10 98 (1), m2erbe 98-7732 (2), m2ocean 98
; (1), menu 61-2095 (5), missions 98-34256 (9), play 98-10891 (2), play2
; 98-17546 (3), search 98 (1).
;
; Witness: L1 27 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
MusicSilence:
  LD C,$FD
  LD DE,$0D00
  SUB A
l_C18A:
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),A
  DEC D
  JP P,l_C18A
  LD DE,$073F
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; StopMusicCore with every register saved
;
; Witness frames (first-last frame of the recording, runs): c1 24571-24716 (2),
; controls 61-224 (2), death 98 (1), m10 98 (1), m2erbe 98-7732 (2), m2ocean 98
; (1), menu 61-2095 (5), missions 98-34256 (9), play 98-10891 (2), play2
; 98-17547 (3), search 98 (1).
;
; Witness: L1 27 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
StopMusic:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  CALL StopMusicCore
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; MusicOn and EffectOn off, MusicSilence, the three volumes to zero
;
; Witness: L1 27 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
StopMusicCore:
  XOR A
  LD (MusicOn),A
  LD (EffectOn),A
  CALL MusicSilence
  XOR A
  LD (AYVolumes),A
  LD (AYVolumes+$0001),A
  LD (AYVolumes+$0002),A
  RET

; The commands $80-$93: each byte the distance from itself to the command's
; routine
;
; Read by Command (`$C362`: HL = `$C147` + the command byte, so `$80` reads
; `$C1C7`).
CommandOffsets:
  DEFB $A2,$8A,$8E,$93,$51,$80,$7B,$11,$6A,$62,$26,$10,$38,$8F,$06,$9C,$A1,$A6,$AA,$B0

; Command $8E: drop the return into the channel step and stop the music
;
; Witness: known only from the code (the tune never uses `$8E`).
CmdStop:
  POP HL
  JP StopMusic

; Command $87: the pattern is done, take the next one from the order list
;
; Witness: L1 19 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
CmdNextPattern:
  JP NextPattern

; Command $8B: the channel plays noise only (its tone bit off in the mixer
; template), the noise follows the note
;
; The mixer template is the operand at `$C446`. Witness: L1 2 (menu).
CmdNoise:
  LD A,(IX+$26)
  LD C,A
  AND $07
  LD HL,MixerTemplateOp+$0001
  XOR (HL)
  AND C
  XOR (HL)
  LD (HL),A
  LD A,$01
  LD (IX+$1E),A
  JP ReadStream

; Command $8A: the channel plays tone only, the noise no longer follows the
; note
;
; Witness: L1 66 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
CmdTone:
  LD A,(IX+$26)
  LD C,A
  AND $38
  LD HL,MixerTemplateOp+$0001
  XOR (HL)
  AND C
  XOR (HL)
  LD (HL),A
  XOR A
  LD (IX+$1E),A
  JP ReadStream

; Command $8C: tone and noise both on for the channel, the noise follows the
; note
;
; Witness: L1 41 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
CmdToneNoise:
  LD HL,MixerTemplateOp+$0001
  LD A,(IX+$26)
  CPL
  AND (HL)
  LD (HL),A
  LD A,$01
  LD (IX+$1E),A
  JP ReadStream

; Command $84 step, delay: slide the frequency by step every delay frames
;
; Witness: known only from the code.
CmdSlide:
  LD A,(DE)
  INC DE
  LD (IX+$07),B
  LD (IX+$08),B
  LD (IX+$0D),A
  SET 2,(IX+$00)
  LD A,(DE)
  LD (IX+$0E),A
  INC DE
  JR ReadStream

; Command $89 n: transpose every channel by n semitones (the operand $C39D)
;
; Witness: known only from the code.
CmdTranspose:
  LD A,(DE)
  INC DE
  LD (TransposeOp+$0001),A
  JR ReadStream

; Command $88 step, depth: the vibrato's step and depth (its position starts at
; the depth)
;
; Witness: L1 38 (c1, m2erbe, menu, missions, play, play2).
CmdVibrato:
  LD A,(DE)
  LD (IX+$1B),A
  INC DE
  LD A,(DE)
  LD (IX+$1A),A
  INC DE
  LD (IX+$1C),A
  JR ReadStream

; Command $86: the note rises one step a frame while it lasts
;
; Witness: known only from the code.
CmdBendUp:
  SET 7,(IX+$00)
CmdBendDown:
  SET 3,(IX+$00)          ; command $85: the same with bit 7 clear, the note
                          ; falls
  JR ReadStream

; Command $81: no vibrato
;
; Witness: L1 28 (c1, m2erbe, menu, missions, play, play2).
CmdVibratoOff:
  LD (IX+$1D),B
  JR ReadStream

; Command $82: vibrato every frame
;
; Witness: L1 38 (c1, m2erbe, menu, missions, play, play2).
CmdVibratoOn:
  LD (IX+$1D),$40
  JR ReadStream

; Command $83: vibrato every other frame
;
; Witness: known only from the code.
CmdVibratoHalf:
  LD (IX+$1D),$C0
  JR ReadStream

; Command $8D: set bit 1 of the channel's flags, which no routine reads
;
; Witness: known only from the code.
CmdFlag1:
  SET 1,(IX+$00)
  JR ReadStream

; Command $80: silence (volume 0, the envelope stopped) for a note's duration
;
; Witness: L1 1 (menu).
CmdRest:
  LD (IX+$13),B
  RES 5,(IX+$00)
  JR SetDuration

; Command $8F: the envelope stops, the volume stays, for a note's duration
;
; Witness: L1 12 (c1, menu, play2).
CmdHold:
  RES 5,(IX+$00)
  JR SetDuration

; Command $90: a drum hit (noise period 1 on the channel for a frame) on every
; note
;
; Witness: known only from the code.
CmdDrum:
  LD (IX+$1F),$FF
  JR ReadStream

; Command $91: no drum
;
; Witness: L1 64 (c1, m2erbe, menu, missions, play, play2).
CmdDrumOff:
  LD (IX+$1F),B
  JR ReadStream

; Command $92: each note is followed by its duration
;
; Witness: L1 66 (c1, m2erbe, menu, missions, play, play2).
CmdInlineDurations:
  LD A,$01
  LD (IX+$24),A
  JR ReadStream

; Command $93 n: every note lasts n steps
;
; Witness: L1 2 (menu).
CmdDuration:
  LD A,(DE)
  INC DE
  LD (IX+$11),A
  LD (IX+$24),$00
  JR ReadStream

; Count the note down; at its end read the channel's next note and the commands
; before it
;
; Input: IX the channel record, B = 0. When +`$25` is set, the next pattern
; first (NextPattern). A note byte (below `$80`) plus the pattern's transpose
; is the note (+`$12`); a noise-following channel also sets the noise period
; (`$C0DD`); the ornament and the instrument's envelope restart; the duration
; from +`$11` or the next byte. Between notes a bend changes the note a step a
; frame (`$C30F`).
;
; Witness: L1 15111 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
ChannelStep:
  DEC (IX+$10)
  JR NZ,BendStep
  LD (IX+$00),B
  LD A,(IX+$25)
  OR A
  JP NZ,NextPattern
  LD E,(IX+$01)
  LD D,(IX+$02)

; ReadStream
;
; Used by the routines at CmdNoise, CmdTone, CmdToneNoise, CmdSlide,
; CmdTranspose, CmdVibrato, CmdBendUp, CmdVibratoOff, CmdVibratoOn,
; CmdVibratoHalf, CmdFlag1, CmdDrum, CmdDrumOff, CmdInlineDurations,
; CmdDuration, Command and NextPattern.
ReadStream:
  LD A,(DE)
  INC DE
  AND A
  JP M,Command
  ADD A,(IX+$20)
  LD (IX+$12),A
  BIT 0,(IX+$1E)
  JR Z,l_C2BF
  LD (NoiseOp+$0001),A
l_C2BF:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD (IX+$0B),L
  LD (IX+$0C),H
  LD L,(IX+$14)
  LD (IX+$16),L
  LD H,(IX+$15)
  LD (IX+$17),H
  LD A,(HL)
  LD (IX+$18),A
  LD (IX+$13),A
  LD A,(IX+$0F)
  LD (IX+$19),A
  SET 5,(IX+$00)

; SetDuration
;
; Used by the routines at CmdRest and CmdHold.
SetDuration:
  LD A,(IX+$24)
  OR A
  JR Z,l_C2F2
  LD A,(DE)
  INC DE
  JR l_C2F5
l_C2F2:
  LD A,(IX+$11)
l_C2F5:
  LD (IX+$10),A
  LD (IX+$02),D
  LD (IX+$01),E
  LD A,(IX+$1F)
  AND A
  JR Z,l_C30E
  LD A,(EffectOn)
  AND A
  JR NZ,l_C30E
  LD (IX+$1F),$FF
l_C30E:
  RET
; This entry point is used by the routine at ChannelStep.
BendStep:
  LD A,(IX+$00)
  BIT 3,A
  RET Z
  RLA
  JR NC,l_C31C
  INC (IX+$12)
  RET
l_C31C:
  DEC (IX+$12)
  RET

; A pattern byte of $80 and above: $E0-$FF an instrument, $B0-$DF an ornament,
; $80-$AF a command through CommandOffsets
;
; `$E0`+n: the instrument n from Instruments `$C75A`, its speed the byte before
; its data. `$B0`+n: the ornament n from OrnamentOffsets `$C721`. The branch at
; `$C342` (the tune's speed from a byte, `$C0FE`) is never taken: the sum `A +
; $50` always carries for a byte from `$B0` (known only from the code).
;
; Witness: L1 595 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
Command:
  CP $B0
  JR C,CommandJump
  ADD A,$20
  JR C,SetInstrument
  ADD A,$30
  JR NC,CmdSpeedDead
  LD C,A
  LD HL,OrnamentOffsets
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  LD (IX+$0B),L
  LD (IX+$09),L
  LD (IX+$0C),H
  LD (IX+$0A),H
  JP ReadStream
CmdSpeedDead:
  ADD A,$09
  LD (SpeedOp+$0001),A
  JP ReadStream
SetInstrument:
  LD HL,Instruments
  ADD A,A
  LD C,A
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (IX+$14),L
  LD (IX+$15),H
  DEC HL
  LD A,(HL)
  LD (IX+$0F),A
  JP ReadStream
CommandJump:
  LD HL,EffectMix+$0019
  LD C,A
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  JP (HL)

; The channel's frequency (HL) and volume (A) this frame, and its mixer bits in
; AYShadow
;
; Input: IX the channel. The volume envelope steps every +`$0F` frames (the
; instrument's bytes until one with bit 7); the note plus the global transpose
; (`$C39D`) plus the ornament's byte (a byte with bit 7 ends the ornament and
; loops it) indexes NoteTable; the vibrato moves the frequency by its position
; (the depth in both directions); the slide adds its sum. The noise and tone
; bits go into the mixer `$C482` through the template `$C446`; a pending drum
; hit sets the noise period `$41`.
;
; Witness: L1 15111 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
ChannelSound:
  LD C,(IX+$00)
  BIT 5,C
  JR Z,TransposeOp
  LD A,(IX+$19)
  SUB $01
  LD (IX+$19),A
  JR NC,l_C396
  LD A,(IX+$0F)
  LD (IX+$19),A
  LD L,(IX+$16)
  LD H,(IX+$17)
  INC HL
  LD A,(HL)
  AND A
  JP M,l_C396
  LD (IX+$16),L
  LD (IX+$17),H
  LD (IX+$18),A
l_C396:
  LD A,(IX+$18)
  LD (IX+$13),A
TransposeOp:
  LD A,$00                ; LD A,n: n ($C39D) the global transpose
  ADD A,(IX+$12)
  LD B,A
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  LD A,(HL)
  INC HL
  AND A
  JP P,l_C3B6
  LD L,(IX+$09)
  LD H,(IX+$0A)
  AND $7F
l_C3B6:
  LD (IX+$0B),L
  LD (IX+$0C),H
  ADD A,B
  LD HL,NoteTable
  LD D,$00
  ADD A,A
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD L,(IX+$1D)
  BIT 6,L
  JR Z,l_C417
  LD H,A
  LD B,(IX+$1A)
  SLA B
  BIT 7,L
  LD A,(IX+$1C)
  JR Z,l_C3E0
  BIT 0,C
  JR NZ,l_C3FE
l_C3E0:
  BIT 5,L
  JR NZ,l_C3F0
  SUB (IX+$1B)
  JR NC,l_C3FB
  SET 5,(IX+$1D)
  SUB A
  JR l_C3FB
l_C3F0:
  ADD A,(IX+$1B)
  CP B
  JR C,l_C3FB
  RES 5,(IX+$1D)
  LD A,B
l_C3FB:
  LD (IX+$1C),A
l_C3FE:
  EX DE,HL
  SRL B
  SUB B
  LD E,A
  LD A,D
  LD D,$00
  JR NC,l_C409
  DEC D
l_C409:
  ADD A,$A0
  JR C,l_C415
l_C40D:
  SLA E
  RL D
  ADD A,$18
  JR NC,l_C40D
l_C415:
  ADD HL,DE
  EX DE,HL
l_C417:
  LD A,C
  XOR $01
  LD (IX+$00),A
  BIT 2,C
  JR Z,l_C442
  LD B,(IX+$0E)
  DJNZ l_C43F
  LD C,(IX+$0D)
  BIT 7,C
  JR Z,l_C42E
  DEC B
l_C42E:
  LD L,(IX+$07)
  LD H,(IX+$08)
  ADD HL,BC
  LD (IX+$07),L
  LD (IX+$08),H
  ADD HL,DE
  EX DE,HL
  JR l_C442
l_C43F:
  LD (IX+$0E),B
l_C442:
  CPL
  AND $03
MixerTemplateOp:
  LD A,$38                ; LD A,n: n ($C446) the mixer template the noise
                          ; commands change
  JR NZ,l_C453
  LD A,(NoiseOp+$0001)
  XOR $08
  LD (NoiseOutOp+$0001),A
  LD A,$07
l_C453:
  LD HL,AYMixer
  XOR (HL)
  AND (IX+$26)
  XOR (HL)
  LD (HL),A
  LD A,(IX+$1F)
  AND A
  JP P,l_C476
  AND $7F
  LD (IX+$1F),A
  LD A,(IX+$26)
  AND $38
  XOR $FF
  AND (HL)
  LD (HL),A
  LD A,$41
  LD (NoiseOutOp+$0001),A
l_C476:
  EX DE,HL
  LD A,(IX+$13)
  RET

; The AY registers 0-11 as MusicTick writes them, then the effect's values
;
; `$C47B`-`$C480` the three tone periods, `$C481` noise, `$C482` mixer,
; `$C483`-`$C485` the volumes, `$C486` register 11. `$C488`-`$C492` the
; effect's tone A, tone C, noise, mixer mask and volumes (StartEffect,
; EffectTick).
AYShadow:
  DEFB $00,$00,$00,$00,$00,$00
AYNoise:
  DEFB $00
AYMixer:
  DEFB $3F
AYVolumes:
  DEFB $0F,$0F,$0F,$00,$00
EffectRegs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$3F,$10,$00,$10,$00

; The AY tone periods of 96 notes, 8 octaves from $0EF8 down to $000F
;
; Read by ChannelSound (`$C3BD`).
NoteTable:
  DEFW $0EF8,$0E10,$0D60,$0C80,$0BD8,$0B28,$0A88,$09F0,$0960,$08E0,$0858,$07E0
  DEFW $077C,$0708,$06B0,$0640,$05EC,$0594,$0544,$04F8,$04B0,$0470,$042C,$03F0
  DEFW $03BE,$0384,$0358,$0320,$02F6,$02CA,$02A2,$027C,$0258,$0238,$0216,$01F8
  DEFW $01DF,$01C2,$01AC,$0190,$017B,$0165,$0151,$013E,$012C,$011C,$010B,$00FC
  DEFW $00EF,$00E1,$00D6,$00C8,$00BD,$00B2,$00A8,$009F,$0096,$008E,$0085,$007E
  DEFW $0077,$0070,$006B,$0064,$005E,$0059,$0054,$004F,$004B,$0047,$0042,$003F
  DEFW $003B,$0038,$0035,$0032,$002F,$002C,$002A,$0027,$0025,$0023,$0021,$001F
  DEFW $001D,$001C,$001A,$0019,$0017,$0016,$0015,$0013,$0012,$0011,$0010,$000F

; Take the channel's next pattern from its order list
;
; The order list: a byte below `$80` is a pattern (PatternTable `$C870`); `$FF`
; n the pattern's transpose; `$FE` n repeat the following n times; `$FD` back
; to the list's start; `$FC` a word, jump there. Any other byte runs the trap
; at `$C5B1`: random border colours forever (a debugging aid of the music
; editor, known only from the code).
;
; Witness: L1 76 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
NextPattern:
  XOR A
  LD (IX+$25),A
  LD L,(IX+$03)
  LD H,(IX+$04)
l_C55E:
  LD A,(IX+$21)
  OR A
  JP Z,l_C57A
  DEC A
  LD (IX+$21),A
  JP Z,l_C57E
  LD L,(IX+$22)
  LD H,(IX+$23)
  LD (IX+$03),L
  LD (IX+$04),H
  JR l_C57E
l_C57A:
  LD (IX+$20),$00
l_C57E:
  LD A,(HL)
  INC HL
  OR A
  JP M,l_C5A1
  LD (IX+$03),L
  LD (IX+$04),H
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,PatternTable
  ADD HL,DE
  LD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  LD (IX+$01),E
  LD (IX+$02),D
  LD B,$00
  JP ReadStream
l_C5A1:
  CP $FD
  JR Z,l_C5D8
  CP $FF
  JR Z,l_C5D0
  CP $FE
  JR Z,l_C5C2
  CP $FC
  JR Z,l_C5BB
OrderTrap:
  LD A,R
  OUT ($FE),A
  LD B,$64
l_C5B7:
  DJNZ l_C5B7
  JR OrderTrap
l_C5BB:
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP l_C57E
l_C5C2:
  LD A,(HL)
  INC HL
  LD (IX+$21),A
  LD (IX+$22),L
  LD (IX+$23),H
  JP l_C57E
l_C5D0:
  LD A,(HL)
  INC HL
  LD (IX+$20),A
  JP l_C57E
l_C5D8:
  LD L,(IX+$05)
  LD H,(IX+$06)
  JP l_C55E

; Start sound effect A: its 17 bytes from EffectTable to EffectState, the
; envelope registers set
;
; Witness: known only from the code (no routine of the game calls it; the
; effects of play are bank 0's, `$D692`).
StartEffect:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  LD HL,EffectOn
  LD (HL),$00
  LD HL,EffectTable
  ADD A,A
  ADD A,L
  LD L,A
  JR NC,l_C5F5
  INC H
l_C5F5:
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD B,$11
  LD HL,EffectState
l_C5FD:
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  DJNZ l_C5FD
  LD A,(EffectState+$0001)
  LD (EffectState+$0011),A
  LD HL,(EffectState+$0002)
  LD (EffectRegs),HL
  LD DE,(EffectState+$0004)
  LD (EffectRegs+$0004),DE
  LD A,L
  LD (EffectRegs+$0006),A
  LD A,(EffectState+$0007)
  LD (EffectRegs+$0007),A
  LD A,(EffectState+$0006)
  LD E,A
  LD D,$0C
  CALL WriteAY
  LD A,(EffectState+$0010)
  LD E,A
  LD D,$0D
  CALL WriteAY
  LD HL,EffectOn
  INC (HL)
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; Step the random number; while an effect runs, its time, its repeats and its
; tone slides
;
; Witness: L1 76293 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
EffectTick:
  CALL NextRandom
  LD A,(EffectOn)
  AND A
  RET Z
  LD A,(EffectState)
  AND A
  JR NZ,l_C652
  LD (EffectOn),A
  JP MusicSilence
l_C652:
  DEC A
  LD (EffectState),A
  LD A,(EffectState+$0011)
  AND A
  JR NZ,l_C68B
  LD A,(EffectState+$000E)
  AND A
  RET Z
  DEC A
  LD (EffectState+$000E),A
  LD A,(EffectState+$0001)
  LD (EffectState+$0011),A
  LD A,(EffectState+$000F)
  AND A
  JR Z,l_C674
  LD A,(RandomSeed)
l_C674:
  LD B,A
  LD A,(EffectState+$0002)
  ADD A,B
  LD (EffectRegs),A
  LD A,(EffectState+$0003)
  ADD A,B
  AND $0F
  LD (EffectRegs+$0001),A
  LD HL,(EffectState+$0004)
  LD (EffectRegs+$0004),HL
l_C68B:
  LD HL,EffectState+$0011
  DEC (HL)
  LD A,(EffectState+$000C)
  AND A
  JR Z,l_C6B2
  JP P,l_C6A5
  LD HL,(EffectRegs)
  LD DE,(EffectState+$0008)
  ADD HL,DE
  LD (EffectRegs),HL
  JR l_C6B2
l_C6A5:
  LD HL,(EffectRegs)
  LD DE,(EffectState+$0008)
  AND A
  SBC HL,DE
  LD (EffectRegs),HL
l_C6B2:
  LD A,(EffectState+$000D)
  AND A
  JR Z,l_C6D5
  JP P,l_C6C8
  LD HL,(EffectRegs+$0004)
  LD DE,(EffectState+$000A)
  ADD HL,DE
  LD (EffectRegs+$0004),HL
  JR l_C6D5
l_C6C8:
  LD HL,(EffectRegs+$0004)
  LD DE,(EffectState+$000A)
  AND A
  SBC HL,DE
  LD (EffectRegs+$0004),HL
l_C6D5:
  LD A,(EffectRegs)
  LD (EffectRegs+$0006),A
  RET

; The effects' addresses: one effect, at $C6DE
EffectTable:
  DEFB $DE,$C6
Effect0:
  DEFB $07,$00            ; 17 bytes: time, speed, tone A, tone C, envelope,
  DEFB $60,$00            ; mixer mask, slides, repeats
  DEFB $00,$01
  DEFB $07,$D2
  DEFB $F0,$00
  DEFB $F0,$00
  DEFB $FF,$FF
  DEFB $01,$00
  DEFB $00

; The running effect: a copy of its 17 bytes and the speed count $C700
EffectState:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; Shift the 32-bit generator at RandomSeed one step; A = its first byte
;
; Witness: L1 76293 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
NextRandom:
  LD A,(RandomSeed)
  AND $48
  ADC A,$38
  SLA A
  SLA A
  LD HL,RandomSeed+$0003
  RL (HL)
  DEC HL
  RL (HL)
  DEC HL
  RL (HL)
  DEC HL
  RL (HL)
  LD A,(HL)
  RET

; The generator's 32 bits
RandomSeed:
  DEFB $FF,$80,$1B,$34

; The ornaments: each byte the distance from itself to the ornament
;
; Read by Command (`$C32D`).
OrnamentOffsets:
  INCBIN "res/music/tune.bin",$0000,7

; Seven ornaments: semitone offsets, a byte with bit 7 ends one (its low bits
; the last offset)
Ornaments:
  INCBIN "res/music/tune.bin",$0007,50

; Thirteen instruments' envelope addresses (each with its speed in the byte
; before)
Instruments:
  INCBIN "res/music/tune.bin",$0039,26

; The instruments' volume envelopes
InstrumentData:
  INCBIN "res/music/tune.bin",$0053,245

; The only tune: its speed and the order lists of channels A, B, C
TuneTable:
  INCBIN "res/music/tune.bin",$0148,7

; The 17 patterns' addresses
PatternTable:
  INCBIN "res/music/tune.bin",$014F,34
  ASSERT {PatternTable} == Patterns && {PatternTable+32} == CatalogueSpace

; The three channels' order lists
OrderLists:
  INCBIN "res/music/tune.bin",$0171,122

; The 17 patterns: notes, durations, commands
Patterns:
  INCBIN "res/music/tune.bin",$01EB,600

; Where the mission catalogue loads ($CB64, 7124 bytes): $E5 bytes and zeros on
; the tape
;
; LoadDirectory (`$715D`, bank 5) reads the DIRECTORY block here with LdBytes
; (`$8617`; writes `$CB64-$E737` in menu); the tape's bank 4 block carries only
; `$E5` filler, three zeros and 16 zeros at the end.
CatalogueSpace:
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$00,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$00,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$00,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
