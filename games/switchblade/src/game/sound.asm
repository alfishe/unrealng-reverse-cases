; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The 48K effect player and its effect table
; --------------------------------------------------------------------------------------------------------------------

  ORG $8450

; Sound variables, shared with the 128K glue: the last $7FFD, a tune request,
; an effect request, the mode
;
; The 48K player only reads EffectRequest. The 128K glue (AyGlue $853F in
; src/boot) uses all of them: $8450 the value last sent to $7FFD ($10), $8452
; the tune request ($FE: none; $5CDA writes it at the start of play), $8453 the
; tune state, $8454 the effect request, $8455 the title's toggle (0 music, 1
; effects).
SoundVars:
Last7FFD:
  DEFB $10                ; $10
SoundSpare:
  DEFB $00                ; read by no code found
TuneRequest:
  DEFB $FE                ; $FE none
TuneState:
  DEFB $00
EffectRequest:
  DEFB $FF                ; the effect to start, $FF none: the game writes 0-13
                          ; here, the player takes it once a frame
SoundMode:
  DEFB $00                ; 128K: 0 music, 1 effects. In music mode, after the
                          ; jingle the glue requests $81 (tune 1 looped) and
                          ; never reaches the effect branch: a 128K in music
                          ; mode plays no effects (doc 09, 9.7)

  ORG $853F

; The 48K sound, every frame: step the effect, copy its level to $9BA3
;
; Calls EffectFrame, then $9BA3 (the operand of $9BA2 LD A,n) = the current
; level (the operand at $85CA): $9BA2 lets the footstep effect 7 start only
; while that level is 0: never over an audible effect, but over the zero-level
; sustain of effects 4, 7, 11, 12 and 13 (sustain 0) it does. On a 128K the
; bootstrap overwrites $853F-$85E0 with the 162-byte glue to the AY player in
; bank 4 (AyGlue): the 48K bytes from $85E1 and the table EffectTable stay but
; are not run.
;
; Witness: L1 222542 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19). The 128K
; recordings' runs at $853F-$85E0 are the glue's; the 48K player runs in c48
; and the RZX builds.
EffectPlayer:
  CALL EffectFrame
  LD A,(EnvelopeStep+$0004)
  LD (FootstepSound+$0001),A
  RET

; Start a requested effect (EffectRequest not $FF), else sound the current one
;
; HL = EffectRequest, A = the request, the request back to $FF: $FF goes to
; EffectSound $8634, else StartEffect $855B (no sound that frame).
;
; Witness: L1 222542 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
EffectFrame:
  LD HL,EffectRequest
  LD A,(HL)
  LD (HL),$FF
  INC A
  JP Z,EffectSound
  DEC A
  JP StartEffect

; The effect's counters: duration, sweep delay, sweep count, the mixer bits
; ($3F idle)
EffectState:
EffectTime:
  DEFB $00                ; +0 of the record: frames to the release (counted
                          ; down every frame; 0 and $FF stay)
SweepDelay:
  DEFB $00                ; +1: frames before the sweep starts ($FF never, 0 at
                          ; once)
SweepCount:
  DEFB $00                ; +2: frames of a sweep cycle
EffectMixer:
  DEFB $3F                ; AY-style mixer bits: $3F idle, bit 0 clear = tone,
                          ; bit 3 clear = noise; both set = silent

; Start effect A: copy its 12-byte record's counters, set the mixer, the sweep
; start and the attack
;
; HL = EffectTable + 12 A (kept in the LD IY,n operand at $863C); the first 3
; bytes to EffectTime, SweepDelay, SweepCount; EffectMixer OR 9, with bit 0
; cleared when the record's +3 bit 0 is set (tone) and bit 3 when +3 bit 1
; (noise). The sweep offset ($8648) = 0; DE = the sweep step (+4 high, +5 low);
; HL = DE x (+2) / 2 (shift-and-add over bits 4-0 of the period, the last half
; step by SRA D / RR E), negated into the LD HL,n operand at $862E: the sweep's
; restart value. The envelope state (the JR offset at $85CC) = 9: the attack.
; The level ($85CA) is not cleared: a new effect attacks from the level the old
; one left.
;
; Witness: L1 62138 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs
; here are the glue's.
StartEffect:
  LD C,A
  ADD A,A
  ADD A,C
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,EffectTable
  ADD HL,BC
  LD (EffectSound+$0008),HL
  LD C,$03
  LD DE,EffectState
  LDIR
  LD A,(DE)
  OR $09
  BIT 0,(HL)
  JR Z,StartEffectNoise
  AND $FE
StartEffectNoise:
  BIT 1,(HL)
  JR Z,StartEffectMixer
  AND $F7
StartEffectMixer:
  LD (DE),A
  DEC HL
  LD A,(HL)
  INC HL
  INC HL
  LD D,(HL)
  INC HL
  LD E,(HL)
  LD HL,$0000
  LD (EffectSound+$0014),HL
  RLCA
  RLCA
  RLCA
  RLCA
  LD B,$03
SweepSpanLoop:
  JR NC,SweepSpanShift
  ADD HL,DE
SweepSpanShift:
  ADD HL,HL
  RLCA
  DJNZ SweepSpanLoop
  JR NC,SweepSpanHalf
  ADD HL,DE

; The last half step of the span (DE / 2), then the negation (an entry only
; because the 128K glue's $859E hook lies here)
;
; Witness: L1 13167 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs here are
; the glue's.
SweepSpanHalf:
  SRA D
  RR E
  RLCA
  JR NC,SweepSpanNegate
  ADD HL,DE
SweepSpanNegate:
  LD A,H
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  INC HL
  LD (SweepRestart+$0001),HL
  LD A,$09

; Store A as the envelope state (the JR offset at $85CC: 0 sustain, 9 attack,
; $16 decay, $2B release)
;
; Witness: L1 8022 (bossgate, havok, play48, c x1, poke-room x15, rzx x71,
; rzxroom x19). 128K runs here are the glue's.
SetEnvelopeState:
  LD (EnvelopeStep+$0006),A
  RET

; One frame of the effect: the duration, the sweep, then the envelope step
; (attack, decay, sustain, release)
;
; A = EffectMixer: both channels off returns at once. EffectTime counted down
; unless 0 or $FF; EffectSweep; A = the level (LD A,n, operand $85CA); JR n
; (operand $85CC) to the state: attack $85D6 adds +7 until +11 (the peak), then
; decay; decay $85E3 adds +8 (negative) down to +9 (the sustain level); sustain
; $85CD holds until EffectTime is 0, then release; release $85F8 adds +10
; (negative) and at a negative level sets EffectMixer OR 9 (idle when the other
; bits are set) with the level 0.
;
; Witness: L1 106023 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
EffectEnvelope:
  AND $09
  CP $09
  RET Z
  LD HL,EffectState
  LD A,(HL)
  AND A
  JR Z,EnvelopeStep
  INC A

; EffectTime $FF: no count-down (an entry only because the 128K glue's code
; starts here)
;
; Witness: L1 74157 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs here are
; the glue's.
EnvelopeTimeFF:
  JR Z,EnvelopeStep

; EffectTime - 1 (an entry because the glue's $85C5 hook lies here)
;
; Witness: L1 65807 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19). 128K runs here are
; the glue's.
EnvelopeTimeCount:
  DEC (HL)
; This entry point is used by the routines at EffectEnvelope and
; EnvelopeTimeFF.
EnvelopeStep:
  CALL EffectSweep        ; the sweep, A = the level, JR to the state (operand
                          ; $85CC)
  LD A,$00
  JR EnvelopeSustain
EnvelopeSustain:
  LD A,(EffectTime)       ; state 0: hold until EffectTime is 0, then the
                          ; release ($2B)
  AND A
  RET NZ
  LD A,$2B
  JR SetEnvelopeState
EnvelopeAttack:
  ADD A,(IY+$07)          ; state 9: level + (+7) up to +11
  LD E,(IY+$0B)
  CP E
  JR C,EnvelopeStoreLevel
  LD A,$16
  JR EnvelopeSetState
EnvelopeDecay:
  ADD A,(IY+$08)          ; state $16: level + (+8) down to +9
  LD E,(IY+$09)
  JP M,EnvelopeToSustain
  CP E
  JR NC,EnvelopeStoreLevel
EnvelopeToSustain:
  XOR A
EnvelopeSetState:
  LD (EnvelopeStep+$0006),A
  LD A,E
EnvelopeStoreLevel:
  LD (EnvelopeStep+$0004),A ; the level into the operand at $85CA
  RET
EnvelopeRelease:
  ADD A,(IY+$0A)          ; state $2B: level + (+10), below 0 the effect ends
  JP P,EnvelopeStoreLevel
  LD A,(EffectMixer)
  OR $09
  LD (EffectMixer),A
  XOR A
  JR EnvelopeStoreLevel

; The pitch sweep: after SweepDelay frames add the step (+4, +5) to the offset
; ($8648) each frame, restart every +2 frames
;
; SweepDelay 0: sweep now; $FF: never; else count down and, at 0, restart
; (SweepRestart) and sweep. The offset += the step; SweepCount - 1, at 0
; reloaded from +2 (0: never) and the offset back to -(step x period / 2): a
; saw-tooth around the record's pitch.
;
; Witness: L1 105058 (bossgate, havok, play48, c x1, poke-room x15, rzx x72,
; rzxroom x19).
EffectSweep:
  INC HL
  LD A,(HL)
  AND A
  JR Z,SweepStep
  INC A
  RET Z
  DEC (HL)
  RET NZ
  CALL SweepRestart
SweepStep:
  LD HL,(EffectSound+$0014)
  LD B,(IY+$04)
  LD C,(IY+$05)
  ADD HL,BC
  LD (EffectSound+$0014),HL
  LD HL,SweepCount
  DEC (HL)
  RET NZ
  LD A,(IY+$02)
  AND A
  RET Z
  LD (HL),A

; The sweep offset = the start value (LD HL,n, operand $862E, set by
; StartEffect)
;
; Witness: L1 11983 (bossgate, havok, play48, poke-room x15, rzx x72, rzxroom
; x16).
SweepRestart:
  LD HL,$0000
  LD (EffectSound+$0014),HL
  RET

; Sound one frame of the effect on the beeper: a burst of C toggles at a
; carrier set by the pitch
;
; Idle ($855A = $3F) returns. IY = the record (LD IY,n, set by StartEffect);
; EffectEnvelope; L = +6 (the pitch) + the sweep offset (LD BC,n at $8647),
; only the low byte kept: PitchToDelay sets the DJNZ count B (bits 5-7, made
; odd: 1, 3, 5, 7); LevelToBurst sets C = ((level / 2) AND $7C) OR 4 (4-60
; toggles). OUT ($FE),$18, then C times: B = n, XOR $10, OUT, DJNZ: 47 + 13 (B
; - 1) T a half cycle (47, 73, 99, 125 T: 37, 24, 18, 14 kHz); OUT ($FE),$08. A
; burst lasts at most 60 x 125 = 7500 T (11 % of a frame). On the speaker that
; is a 50 Hz buzz whose loudness follows the envelope: the pitch only picks one
; of four ultrasonic carriers.
;
; Witness: L1 160413 (bossgate, havok, play48, c x1, poke-room x15, rzx x72,
; rzxroom x19).
EffectSound:
  LD A,(EffectMixer)
  CP $3F
  RET Z
  LD IY,$0000
  CALL EffectEnvelope
  LD L,(IY+$06)
  LD H,$00
  PUSH BC
  LD BC,$0000
  ADD HL,BC
  POP BC
  LD A,L
  CALL PitchToDelay
  LD A,(EnvelopeStep+$0004)
  CALL LevelToBurst
  LD A,$18                ; the speaker on (bit 4), MIC (bit 3), border 0
  OUT ($FE),A
  LD C,$0A
BeeperBurst:
  LD B,$00                ; LD C,n at $865A: the burst length; LD B,n here: the
                          ; half-period
  XOR $10
  OUT ($FE),A
BeeperDelay:
  DJNZ BeeperDelay
  DEC C
  JP NZ,BeeperBurst
  LD A,$08
  OUT ($FE),A
  RET

; The burst length C (the operand at $865B) from the level A: ((A / 2) AND $7C)
; OR 4
;
; Witness: L1 105058 (bossgate, havok, play48, c x1, poke-room x15, rzx x72,
; rzxroom x19).
LevelToBurst:
  RRCA
  OR $04
  AND $7C
  LD (EffectSound+$0027),A
  RET

; The DJNZ count (the operand at $865D) from the pitch byte A: bits 5-7, OR 1
;
; Witness: L1 105058 (bossgate, havok, play48, c x1, poke-room x15, rzx x72,
; rzxroom x19).
PitchToDelay:
  RRCA
  RRCA
  RRCA
  RRCA
  RRCA
  OR $01
  AND $07
  LD (BeeperBurst+$0001),A
  RET

; The 14 effects, 12 bytes each: time, sweep delay, sweep period, mixer, sweep
; step (2, big end), pitch, attack, decay, sustain, release, peak
;
; +0 EffectTime (frames before the release; $FF hold), +1 SweepDelay, +2 the
; sweep period, +3 bit 0 tone, bit 1 noise (AY mixer bits: the 48K player only
; uses them to tell silence), +4/+5 the sweep step (big end, added to the pitch
; offset), +6 the pitch (low byte: the 48K player uses bits 5-7), +7 the attack
; step, +8 the decay step (signed), +9 the sustain level, +10 the release step
; (signed), +11 the peak level. Read only by StartEffect / EffectSound through
; IY; the AY player in bank 4 has its own effects (not this table).
;
; Witness: read in c48 (the title) and the RZX builds; 48K only.
EffectTable:
  INCBIN "res/tables/effects-48k.bin",$0000,168
