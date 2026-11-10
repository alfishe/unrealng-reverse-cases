; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The beeper: the sweeps, the pass tick, the teleport
; --------------------------------------------------------------------------------------------------------------------

; A rising sweep: $DC toggles, each shorter
;
; DI; the beeper bit toggled with delays $DC down to 1; EI. L1 209.
RiseSweep:
  LD E,$DC
  XOR A
  DI
RiseSweepLoop:
  OUT ($FE),A
  XOR $10
  LD B,E
RiseSweepDelay:
  DJNZ RiseSweepDelay
  DEC E
  JR NZ,RiseSweepLoop
  EI
  RET

; A falling sweep: 256 toggles, each longer
;
; DI; delays 0, 1, ... 255; EI. DeathEffect (8 a death) and TeleportFlash. L1
; 649.
FallSweep:
  LD E,$00
  XOR A
  DI
FallSweepLoop:
  OUT ($FE),A
  XOR $10
  LD B,E
FallSweepDelay:
  DJNZ FallSweepDelay
  INC E
  JR NZ,FallSweepLoop
  EI
  RET

; The droid's hum: two beeper toggles each pass, a pitch from a running sum
;
; Called by MainLoop once a pass (L1 18 554): two toggles with a delay worked
; out from H; BorderSound starts at 0.
PassTick:
  LD BC,$0002
  XOR A
  LD (BorderSound),A
  LD H,$00
PassTickLoop:
  LD A,(BorderSound)
  OUT ($FE),A
  XOR $10
  LD (BorderSound),A
  LD L,$00
  LD D,L
  LD E,H
  AND A
  SBC HL,DE
  SBC HL,DE
  LD DE,$00FE
  ADD HL,DE
  LD A,L
  SUB H
  JR C,PassTickDelaySet
  DEC A
PassTickDelaySet:
  LD H,A
PassTickDelay:
  DEC A
  JR NZ,PassTickDelay
  DEC BC
  LD A,B
  OR C
  JR NZ,PassTickLoop
  RET

; The teleport beam fills the droid's place top down, with a tone
;
; The 5 x 4 attributes at the teleporter turn $42; 40 lines get $A0 / $05 bytes
; (the beam's edges), each after BeamScreen counts and, while it is not 1, a
; tone of 30 toggles. L1 21.
BeamDown:
  LD BC,(TeleportColumn)
  CALL ScreenAddr
  PUSH DE
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD DE,$001D
  LD B,$05
BeamDownAttrs:
  LD (HL),$42
  INC L
  INC L
  INC L
  LD (HL),$42
  ADD HL,DE
  DJNZ BeamDownAttrs
  POP HL
  LD B,$28
BeamDownLine:
  PUSH BC
  LD DE,(BeamScreen)
  DEC DE
  LD A,D
  OR E
  JR Z,BeamDownDraw
  LD B,$1E
  LD A,(BorderSound)
BeamDownTone:
  PUSH BC
  OUT ($FE),A
  XOR $10
  LD B,$64
BeamDownToneDelay:
  DJNZ BeamDownToneDelay
  POP BC
  DJNZ BeamDownTone
  LD (BorderSound),A
BeamDownDraw:
  LD (HL),$A0
  INC L
  INC L
  INC L
  LD (HL),$05
  DEC L
  DEC L
  DEC L
  INC H
  LD DE,(BeamScreen)
BeamDownDelay:
  DEC DE
  LD A,D
  OR E
  JR NZ,BeamDownDelay
  LD A,H
  AND $07
  JR NZ,BeamDownNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,BeamDownNext
  LD A,H
  SUB $08
  LD H,A
BeamDownNext:
  POP BC
  DJNZ BeamDownLine
  RET

; The beam erased bottom up, with a tone
;
; L1 13.
BeamUp:
  LD BC,(TeleportColumn)
  LD A,B
  ADD A,$27
  LD B,A
  CALL ScreenAddr
  EX DE,HL
  LD B,$28
BeamUpLine:
  PUSH BC
  LD B,$1E
  LD A,(BorderSound)
BeamUpTone:
  PUSH BC
  OUT ($FE),A
  XOR $10
  LD B,$64
BeamUpToneDelay:
  DJNZ BeamUpToneDelay
  POP BC
  DJNZ BeamUpTone
  LD (BorderSound),A
  LD (HL),$00
  INC L
  INC L
  INC L
  LD (HL),$00
  DEC L
  DEC L
  DEC L
  DEC H
  LD DE,(BeamScreen)
BeamUpDelay:
  DEC DE
  LD A,D
  OR E
  JR NZ,BeamUpDelay
  LD A,H
  AND $07
  CP $07
  JR NZ,BeamUpNext
  LD A,L
  SUB $20
  LD L,A
  JR C,BeamUpNext
  LD A,H
  ADD A,$08
  LD H,A
BeamUpNext:
  POP BC
  DJNZ BeamUpLine
  RET

; The play area's attributes $41, the teleporter's cells flashing through the
; colours
;
; The play area's 18 attribute rows become $41 (blue ink on black, bright);
; then the 5 x 2 cells of the teleporter take the attributes 7 down to 2, six
; steps, three times, each step with FallSweep and RiseSweep. L1 11.
TeleportFlash:
  LD HL,Attributes+192
  LD B,$12
TeleportFlashRow:
  PUSH BC
  LD B,$20
TeleportFlashCell:
  LD (HL),$41
  INC HL
  DJNZ TeleportFlashCell
  POP BC
  DJNZ TeleportFlashRow
  LD BC,(TeleportColumn)
  INC C
  CALL ScreenAddr
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD B,$03
TeleportFlashPulse:
  PUSH BC
  LD A,$08
  LD B,$06
TeleportFlashStep:
  PUSH BC
  DEC A
  LD B,$05
  LD DE,$001E
  PUSH HL
TeleportFlashCellRow:
  PUSH BC
  LD B,$02
TeleportFlashCellSet:
  LD (HL),A
  INC L
  DJNZ TeleportFlashCellSet
  ADD HL,DE
  POP BC
  DJNZ TeleportFlashCellRow
  PUSH AF
  CALL FallSweep
  CALL RiseSweep
  POP AF
  POP HL
  POP BC
  DJNZ TeleportFlashStep
  POP BC
  DJNZ TeleportFlashPulse
  RET
