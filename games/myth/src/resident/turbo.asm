; --------------------------------------------------------------------------------------------------------------------
; turbo.asm: The turbo loader
;
; TurboLoad reads one block of the game: flag $56, then D x 256 bytes to GameBlock, the ROM's LD-BYTES method with its
; own timing. Its three bytes at $FEFE-$FF00 are also Im2Jump: LoadBlock puts them back before it loads and SetIm2
; writes the JP again after.
; --------------------------------------------------------------------------------------------------------------------

  ORG $FE90

; Load a block of 2 x (9B + H + L) pages (LoadLength) to GameBlock; carry set
; when it loaded
;
; Witness: L1 7 (c1, joystick, menu, stageload, rzx-r0, rzx-r1).
TurboLoad:
  LD A,(LoadLengthB)
  LD C,A
  SLA A
  SLA A
  SLA A
  ADD A,C
  LD C,A
  LD A,(LoadLength)
  ADD A,C
  LD C,A
  LD A,(LoadLengthL)
  ADD A,C
  SLA A
  LD D,A
  LD E,$00
  LD IX,GameBlock
  JP TurboStart
TurboExit:
  PUSH AF                 ; border black; carry set: return; else RST 8 report
                          ; R (Tape loading error)
  XOR A
  OUT ($FE),A
  POP AF
  RET C
  RST $08
  LD A,(DE)
TurboStart:
  LD A,$56                ; flag $56, the pilot, the sync, the bytes
  OR A
  SCF
  EX AF,AF'
  LD A,$02
  LD (TurboBorderMask+$0001),A
  LD A,$00
  OUT ($FE),A
  LD HL,TurboExit
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  LD C,A
TurboPilot:
  LD H,$00
TurboPilotEdge:
  LD B,$90
  CALL TurboEdgePair
  JR NC,TurboPilot
  LD A,$BF
  CP B
  JR NC,TurboPilot
  INC H
  JR NZ,TurboPilotEdge
TurboSync:
  LD B,$C3
  CALL TurboEdge
  JR NC,TurboPilot
  LD A,B
  CP $D4
  JR NC,TurboSync
  CALL TurboEdge
  RET NC
  LD A,$01
  LD (TurboBorderMask+$0001),A
  LD H,$00
  LD B,$C0
  JR TurboBits
TurboByte:
  EX AF,AF'               ; the flag byte first, then the data
Im2Jump:
  JR NZ,TurboFlag         ; JR NZ: also where SetIm2 writes JP Im2Handler
  JR NC,TurboVerify
  LD (IX+$00),L
  JR TurboNext
TurboFlag:
  RL C                    ; the first byte must be $56
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR TurboCount
TurboVerify:
  LD A,(IX+$00)           ; the verify path: never taken (the flag's carry says
                          ; LOAD)
  XOR L
  RET NZ
TurboNext:
  INC IX
TurboCount:
  DEC DE
  EX AF,AF'
  LD B,$C2
TurboBits:
  LD L,$01
TurboBit:
  CALL TurboEdgePair
  RET NC
  LD A,$DB
  CP B
  RL L
  LD B,$C0
  JP NC,TurboBit
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,TurboByte
  LD A,H
  CP $01
  RET

; Two edges
;
; Witness: L1 936052 (c1, joystick, menu, stageload).
TurboEdgePair:
  CALL TurboEdge
  RET NC

; TurboEdge
;
; Used by the routines at TurboLoad and TurboEdgePair.
TurboEdge:
  AND A                   ; one edge: count B up while EAR stays; the border
                          ; from it
TurboEdgeLoop:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC
  XOR C
  AND $20
  JR Z,TurboEdgeLoop
  LD A,C
  CPL
  LD C,A
TurboBorderMask:
  AND $02                 ; AND n: 2 at the pilot, 1 for the data
  OR $08
  OUT ($FE),A
  SCF
  RET
