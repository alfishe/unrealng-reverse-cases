; --------------------------------------------------------------------------------------------------------------------
; effects.asm: the sound effects: requests by priority, a beeper player inside the scheduler
;
; On a 128K none of this module runs: the glue puts a RET at RequestEffect and EffectPlay, the hook stubs overwrite
; $B30D-$B3A8, and the game's events reach the page-4 engine through the stubs (docs/09-sound.md). On a 48K the 2 in 1
; plays these effects as the 48K did.
;
; An effect is asked for with RequestEffect (A = the effect, 0 = stop): it is taken only when not lower than the one
; playing (CurrentEffect $7F97), which gives the effects their priority by number. The request posts event bit 0, and
; EffectJob runs EffectPlay in the play loop's time, not the interrupt's: the beeper loop then fills the frame and
; returns to the scheduler at every interrupt (EffectTick $7F96 = $FF, set by the play interrupt at $AA18), so the
; jobs go on under the sound.
;
; The effect table is F5's at $7E5A, 8 bytes an effect from effect 1: +0 pitch A, +1 its step, +2 pitch B, +3 its
; step, +4 the change of both steps at each segment's end, +5 the segments, +6 the flags, +7 the segment lengths (low
; nibble A, high nibble B, in frames). The flags: bit 7 two-tone (each period's high half on pitch A, its low half on
; pitch B), bit 6 the pitches back to their start at each segment, bit 5 segment A one frame shorter each time (down
; to 1), bit 4 / bit 3 step B / step A reversed at each segment, bits 0-2 (one tone) which pitch a segment plays: bit
; 0 on even segment counts, bit 1 on odd, bit 2 the last.
;
; The tone: a square wave on the beeper ($FE bit 4: OUT $18, then $00, the border black), each half a count of NOP
; rounds (three NOPs and DJNZ at $B360-$B363, 25 T a round): a pitch value p gives about 3500000 / (2 x 25 p) Hz, a
; little lower for the loop's overhead. 48K c2: 479160 entries at $B360 against 9788 periods at $B358.
; --------------------------------------------------------------------------------------------------------------------

; ask for effect A (0 = stop), taken when not below the one playing
;
; In: A the effect, 0 is stored as $80 (above every effect: a stop always
; wins). Taken when A >= CurrentEffect ($7F97): CurrentEffect = A, EffectTick =
; $80 (new effect), event bit 0 posted. HL kept. Callers (48K c2): FireLaser
; $9C1D x61, $A2D6 x2, $A0EB x1, StopAndSettle x2; in the listing also A = 1
; ($A1C2), 2 ($9C75, the laser: FireLaser), 4 ($A31B), 5 ($A224, a pod) and 6
; ($A21D).
;
; On a 128K: the glue makes its first byte a RET: the beeper effects are off
; (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).
RequestEffect:
  PUSH HL
  LD HL,CurrentEffect
  AND A
  JR NZ,RequestEffectCheck
  LD A,$80                ; 0: the stop, above all
RequestEffectCheck:
  CP (HL)                 ; lower than the one playing: dropped
  JR C,RequestEffectDone
  LD (HL),A
  LD A,$80                ; EffectTick = $80: a new effect
  LD (EffectTick),A
  LD HL,EventRequests     ; event bit 0: EffectJob
  SET 0,(HL)
  LD (EffectTick),A
RequestEffectDone:
  POP HL
  RET

; play CurrentEffect until it ends or a new request
;
; Entered from EffectJob (event bit 0; 48K c2: 106 entries in 73 frames, 45
; from EffectJob and 61 restarts by a new request at $B388). n = CurrentEffect
; & $1F, 0 ends at once; the entry $7E5A + 8 (n - 1) is copied to the effect
; state $7F8A-$7F90 (+0-+6) and its byte 7 split into SegLenA $7F91 and SegLenB
; $7F92; the pitches PitchA $7F93 and PitchB $7F94 start from +0 and +2, the
; frame counter $7F95 from SegLenA. The tone loop runs until an interrupt sets
; EffectTick, then calls EventDispatch (the jobs run) and steps the pitches; at
; a segment's end the segment's changes apply. Ends (CurrentEffect = 0) when
; the segments run out or a job ran (the carry from EventDispatch: an effect
; stops for the redraw jobs and the next effect request starts it again).
; EffectTick = $80 restarts with the new effect.
;
; On a 128K: the glue makes its first byte a RET, and the set-up copies the
; hook stubs over $B30D-$B3A8 (src/game/stubs.asm) (src/game/setup.asm,
; glue.asm; docs/09-sound.md 9.2).
EffectPlay:
  LD A,(CurrentEffect)
  AND $1F
  JP Z,EffectEnd          ; effect 0: nothing to play
  DEC A                   ; (n - 1) * 8
  RLCA
  RLCA
  RLCA
  LD E,A
  LD D,$00
  LD HL,EffectTable       ; the effect table, F5's
  ADD HL,DE
  LD DE,EffectState
  LD BC,$0007             ; +0-+6 into the state
  LDIR
  LD A,(HL)               ; +7: SegLenA the low nibble, SegLenB the high
  AND $0F
  LD (DE),A
  INC DE
  XOR (HL)
  RRCA
  RRCA

; l_B32F
l_B32F:
  RRCA
  RRCA
  LD (DE),A
  LD HL,EffectState+$0006 ; C = the flags for the whole effect
  LD C,(HL)
  LD HL,PitchA            ; PitchA = +0, PitchB = +2
  LD A,(EffectState)

; l_B33C
l_B33C:
  LD (HL),A
  INC HL
  LD A,($7F8C)
  LD (HL),A
  LD A,(SegLenA)          ; the first segment's frames
EffectFirstLen:
  LD (EffectFrames),A
  BIT 7,C                 ; two-tone: the low half on PitchB (DE = $7F94), else
                          ; both halves on PitchA
  EXX
  LD HL,PitchA
  LD E,L
  LD D,H
  JR Z,EffectFirst
  LD DE,PitchB
EffectFirst:
  EXX                     ; B bit 0 = 1: the first segment plays pitch A
  LD B,$01
; This entry point is used by the routines at EffectTickRead and l_B39C.
EffectPeriod:
  EXX                     ; the alternate set: HL the high half's pitch, DE the
                          ; low half's
EffectHalves:
  LD C,$02                ; two halves
EffectSpeakerOn:
  LD A,$18                ; the speaker bit on
EffectHalf:
  LD B,(HL)               ; B = the half's count
EffectOut:
  OUT ($FE),A
EffectWait:
  NOP                     ; three NOPs and DJNZ: 25 T a round
EffectWait1:
  NOP
EffectWait2:
  NOP
EffectWait3:
  DJNZ EffectWait
EffectSwap:
  EX DE,HL                ; the other half's pitch
EffectLow:
  LD A,$00                ; the speaker bit off
EffectHalfNext:
  DEC C
EffectHalfLoop:
  JR NZ,EffectHalf
EffectTickCheck:
  EXX

; EffectTickRead
EffectTickRead:
  LD A,(EffectTick)       ; EffectTick: 0 until the interrupt
EffectTickTest:
  AND A
EffectTickBranch:
  JR Z,EffectPeriod
  PUSH BC                 ; the registers of the loop kept over the scheduler
  EXX

; l_B374
l_B374:
  PUSH HL
  PUSH DE
  CALL EventDispatch      ; the jobs run in the effect's time

; EffectAfterJobs
EffectAfterJobs:
  POP DE
EffectRestore:
  POP HL
  EXX
  POP BC
  JP C,EffectEnd          ; a job ran: the effect ends
  LD HL,EffectTick        ; EffectTick back to 0
  LD A,(HL)
  LD (HL),$00

; l_B386
l_B386:
  CP $80                  ; $80: a new effect was asked for
  JR Z,EffectPlay
  BIT 7,C                 ; two-tone: both pitches step
  JR Z,EffectStepOne
  LD HL,PitchA
  LD A,($7F8B)
  ADD A,(HL)
  LD (HL),A
  INC HL
  LD A,($7F8D)
  ADD A,(HL)
  LD (HL),A

; l_B39C
l_B39C:
  JR EffectFrame
; This entry point is used by the routine at l_B386.
EffectStepOne:
  LD HL,PitchA            ; one tone: the pitch this segment plays steps
  LD A,($7F8B)
  BIT 0,B
  JR NZ,EffectStepAdd
  LD HL,PitchB
  LD A,($7F8D)
EffectStepAdd:
  ADD A,(HL)
  LD (HL),A
EffectFrame:
  LD HL,EffectFrames      ; the segment's frames
  DEC (HL)
  JR NZ,EffectPeriod
  LD HL,EffectState+$0005 ; a segment over: one fewer
  DEC (HL)
  JP Z,EffectEnd
  LD HL,EffectState+$0004 ; both steps + the change (+4)
  LD E,(HL)
  LD HL,EffectState+$0001
  LD A,(HL)
  ADD A,E
  LD (HL),A
  LD HL,EffectState+$0003
  LD A,(HL)
  ADD A,E
  LD (HL),A
  BIT 5,C                 ; bit 5: SegLenA one shorter, not below 1
  JR Z,EffectReverseA
  LD HL,SegLenA
  DEC (HL)
  JR NZ,EffectReverseA
  LD (HL),$01
EffectReverseA:
  BIT 3,C                 ; bit 3: step A reversed (two-tone, or a pitch-A
                          ; segment)
  JR Z,EffectReverseB
  BIT 7,C
  JR NZ,EffectNegateA
  BIT 0,B
  JR Z,EffectReverseB
EffectNegateA:
  LD HL,EffectState+$0001
  LD A,(HL)
  NEG
  LD (HL),A
EffectReverseB:
  BIT 4,C                 ; bit 4: step B reversed (two-tone, or a pitch-B
                          ; segment)
  JR Z,EffectRestart
  BIT 7,C
  JR NZ,EffectNegateB
  BIT 0,B
  JR NZ,EffectRestart
EffectNegateB:
  LD HL,EffectState+$0003
  LD A,(HL)
  NEG
  LD (HL),A
EffectRestart:
  BIT 6,C                 ; bit 6: the pitches back to their start
  JR Z,EffectNextSeg
  LD HL,PitchA
  LD A,(EffectState)
  LD (HL),A
  INC HL
  LD A,($7F8C)
  LD (HL),A
EffectNextSeg:
  EXX                     ; the next segment's halves and length
  LD HL,PitchA
  LD DE,PitchB
  LD A,(SegLenA)
  EXX
  BIT 7,C                 ; two-tone: both halves, SegLenA
  JR NZ,EffectSegLen
  LD A,($7F8F)            ; one tone: the segment count's parity picks a flag
                          ; bit
  LD B,C
  SRL A
  JR NC,EffectPick
  JR NZ,EffectPickBit
  RR B
EffectPickBit:
  RR B
EffectPick:
  BIT 0,B                 ; bit 0 of B: pitch A (SegLenA) or pitch B (SegLenB)
                          ; on both halves
  EXX
  LD A,(SegLenA)
  JR NZ,EffectPitchB
  EX DE,HL
  LD A,(SegLenB)
EffectPitchB:
  LD E,L
  LD D,H
  EXX
EffectSegLen:
  LD (EffectFrames),A     ; the segment's frames
  JP EffectPeriod
; This entry point is used by the routines at EffectPlay and EffectAfterJobs.
EffectEnd:
  XOR A                   ; CurrentEffect = 0
  LD (CurrentEffect),A
  RET
