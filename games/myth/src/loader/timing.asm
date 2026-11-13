; --------------------------------------------------------------------------------------------------------------------
; timing.asm: The timing check: load the second stage, sample the tape's edges, compare the two ends
;
; TimeCheck is LoaderMain's call: it loads tape block 7 and then measures how often the EAR bit changes in 255
; windows; a tape played too fast or too slow (a copy, a turbo deck) sets FailFlag, which Sl1End
; (src/loader/sl1end.asm) turns into a crash at the end of the load.
; --------------------------------------------------------------------------------------------------------------------

  ORG $FE76

; Load the second stage, then measure the tape's edges into TimeBuffer and
; compare them
;
; CALL LoadStream (IX = Sl1Start, DE = $AA: tape block 7). Then 255 TimeSample
; counts to TimeBuffer. On the +2A/+3 ROM (its byte $006D is $28) no compare;
; else TimeCompare. Tape block 29 loads Unxor over this routine later
; (src/loader/unxor.asm). Witness: L1 1 (c1).
TimeCheck:
  CALL LoadStream
  LD HL,TimeBuffer
  LD B,$FF
TimeCheckLoop:
  PUSH BC                 ; one sample: c1 255 passes
  CALL TimeSample
  LD (HL),E
  INC HL
  POP BC
  DJNZ TimeCheckLoop
  LD A,(RomModelByte)
  CP $28
  RET Z
  CALL TimeCompare
  RET

; Count the changes of EAR (port $7FFE bit 6) in 255 polls into E
;
; Witness: L1 255 (c1).
TimeSample:
  LD E,$00
  LD C,E
  LD B,$FF
TimeSamplePoll:
  LD A,$7F
  IN A,($FE)
  AND $40
  XOR C
  JR Z,TimeSampleSame
  INC E
  LD A,C
  CPL
  AND $40
  LD C,A
TimeSampleNext:
  DJNZ TimeSamplePoll
  RET
TimeSampleSame:
  NOP                     ; no change: the same time as a change
  NOP
  JP TimeSampleNext

; S1 = samples 50-99, S2 = samples 205-254; FailFlag := H of S2 when it is $0D
; or more, 1 when S2 - S1 >= 50
;
; A tape played at the right speed gives about the same counts at both ends of
; the block. Witness: L1 1 (c1).
TimeCompare:
  LD HL,$0000
  LD DE,TimeBuffer+50
  LD B,$32
TimeSumFirst:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ TimeSumFirst
  PUSH HL
  LD HL,$0000
  LD DE,TimeBuffer+205
  LD B,$32
TimeSumLast:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ TimeSumLast
  POP BC
  LD A,H
  CP $0D
  JR NC,TimeFailed
  AND A
  SBC HL,BC
  RET C
  LD BC,$0032
  AND A
  SBC HL,BC
  RET C
  LD A,$01
TimeFailed:
  LD (FailFlag),A         ; FailFlag := A
  RET

; Non-zero when the timing check failed (1 or S2's high byte) or a table mark
; was wrong ($7F)
;
; Read by Sl1End (src/loader/sl1end.asm) and by the second stage's original
; end. c1: 0 at the end of the load.
FailFlag:
  DEFB $00
