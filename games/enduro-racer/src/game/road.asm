; --------------------------------------------------------------------------------------------------------------------
; road.asm: The road: its rows from the hills and curves, the drawing of the edges, the ground's dots, the hill table
;
; A segment of StageList gives a hill (0-3) and a curve (0-3, with a direction). Each pass a row builder (StageParams'
; second word, called at $A68B) makes RoadLines, the screen line of each of the 128 road rows: RoadRowsCurve (stages
; 1, 2, 4, 5) bends the perspective table ($7800) by the curve tables ($7A00) as the segment goes by; RoadRowsJump
; (stage 3) lifts every row by the bike's height in the air; RoadRowsFlat is the straight. RoadRowsMake turns
; RoadLines into RowList (the rows to draw, top down) and RoadTopRow. HillRows (ScrollHills, BlendHill) shift each row
; sideways with the hill profiles ($7D80, $7E00, $7E80).
;
; DrawRoad (StageParams' first word, called at $A68E) draws each row of RowList into the back buffer: the left and the
; right edge as 3-byte patterns (EdgePatterns: $7880 or $7A80 by the row's depth, 8 shifts each) at x = the row's
; centre (HillRows, the lateral position) minus and plus its half width (the RowScale tables at $7F00/$7F80), the road
; between left blank. It walks RowList with SP = RowTable + 2 * line, and Multiply's last byte is patched to a JP
; (MultiplyEnd) so that the multiply in each row returns without a RET, which would pop a line address. Stage 5 has no
; edges (RoadNone): its ground is GroundTexture's dots.
;
; The bug of the stage 3 reset is here: RoadTopRow = RoadLines' last entry - $71, and with every row at line $70 (a
; jump so high that RoadRowsJump scales every row to 0) it is $FF; DrawRoad then sets SP = $FEE0 + 2 * $FF = $00DE,
; inside the ROM (NOTES, leftovers).
; --------------------------------------------------------------------------------------------------------------------

  ORG $931E

; Draw the rows of RowList: both edges of each row into the back buffer, SP
; walking RowTable
;
; GapRowsJump first (GapRows: stage 3's gap rows become $FE in RowList);
; Multiply's RET patched to JP DrawRoadRow; SP = $FEE0 + 2 * RoadTopRow
; (RowTable from line $70 + RoadTopRow). Per entry: $FF ends, $FE skips a line
; (the gap), else the row's depth picks the edge pattern set and the width
; (RowScale), Multiply gives the hill's and the curve's shift, the left edge's
; 3 bytes are written (LDI, or LDDR clipped at the left), then the right
; edge's. Runs of equal entries (a row stretched over several lines) go to
; DrawRoadRun. At the end MultiplyEnd is RET again and SP restored.
;
; Recorded: c1: every pass; the heaviest passes' largest cost.
;
; Witness: L1 3968 (c1, crash, ctl, m128, stages, twoplayer).
DrawRoad:
  CALL GapRowsJump
  LD IX,RowList
  LD A,$C3
  LD (MultiplyEnd),A
  LD HL,DrawRoadRow
  LD (MultiplyJump),HL
  LD (SavedSp),SP         ; SP = RowTable + 2 * ($70 + RoadTopRow)
  LD A,(SegmentLeft+$0001)
  CPL
  LD (l_9366+$000B),A
  LD A,(RoadTopRow)
  LD E,A
  LD D,$00
  LD HL,RowTable+$00E0
  ADD HL,DE
  ADD HL,DE
  LD SP,HL
DrawRoadLoop:
  LD (DrawRoadNext+$0001),A ; the next RowList entry
  LD A,(IX+$00)
  CP $FF
  JP Z,DrawRoadEnd
  CP $FE
  JR NZ,l_935A
  POP HL
  JP DrawRoadNext
l_935A:
  LD C,A
  LD B,$7F
  LD A,(BC)
  SRL A
  CP $70
  JR C,l_9366
  LD A,$70
l_9366:
  AND $F8
  LD E,A
  LD D,$00
  LD L,E
  LD H,D
  ADD HL,HL
  ADD HL,DE
  LD A,C
  ADD A,$00
  BIT 2,A
  LD DE,EdgePatterns
  JR NZ,l_937C
  LD DE,EdgePatterns2
l_937C:
  ADD HL,DE
  LD (l_93BB+$0013),HL
  LD A,C
  OR $80
  LD L,A
  LD H,$7F
  LD A,(HL)
  LD (l_93BB+$0006),A
  LD (DrawRoadRight+$0003),A
  LD A,C
  CP (IX+$01)
  JP Z,DrawRoadRun
  LD H,$5B
  LD A,(HL)
  LD L,C
  LD H,$7F
  LD L,(HL)
  CP $FF
  JP Z,DrawRoadOff
  ADD A,$00
  LD C,$00
  JR NC,l_93AE
  BIT 7,A
  JP Z,DrawRoadOff
  NEG
  INC C
l_93AE:
  JP Multiply             ; JP Multiply: it comes back at DrawRoadRow by
                          ; MultiplyEnd's JP
DrawRoadRow:
  EX DE,HL                ; the row's centre and left edge
  POP DE
  ADD HL,HL
  ADD HL,HL
  LD A,H
  DEC C
  JR NZ,l_93BB
  NEG
l_93BB:
  ADD A,$80
  LD (DrawRoadRight+$0001),A
  SUB $00
  LD B,A
  EX AF,AF'
  LD A,B
  AND $07
  LD L,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  LD BC,EdgePatterns2
  ADD HL,BC
  EX AF,AF'
  JR NC,l_93EC
  RRA
  RRA
  RRA
  OR $E0
  ADD A,$03
  JR NC,DrawRoadRight
  JR Z,DrawRoadRight
  LD C,A
  LD B,$00
  DEC A
  OR E
  LD E,A
  INC HL
  INC HL
  LDDR
  INC DE
  JR DrawRoadRight
l_93EC:
  AND $F8
  RRA
  RRA
  RRA
  OR E
  LD E,A
  LDI
  LDI
  LDI
DrawRoadRight:
  LD A,$00                ; the right edge
  ADD A,$00
  JR C,DrawRoadNext
  LD B,A
  AND $F8
  RRA
  RRA
  RRA
  LD C,A
  EX AF,AF'
  LD A,E
  AND $E0
  OR C
  LD E,A
  LD A,B
  AND $07
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,(l_93BB+$0013)
  ADD HL,BC
  EX AF,AF'
  SUB $1E
  JR C,l_9429
  SUB $02
  NEG
  LD C,A
  LD B,$00
  LDIR
  JR DrawRoadNext
l_9429:
  LDI
  LDI
  LDI
; This entry point is used by the routines at DrawRoadRunLine and
; DrawRoadRunOff.
DrawRoadNext:
  LD A,$00                ; next line
  INC IX
  INC A
  CP $50
  JP C,DrawRoadLoop
DrawRoadEnd:
  LD A,$C9                ; MultiplyEnd = RET; SP back
  LD (MultiplyEnd),A
  LD SP,(SavedSp)
  RET
DrawRoadOff:
  POP DE                  ; the row is off the road's table: skip its line
  JR DrawRoadNext
DrawRoadRun:
  LD L,$00                ; a run of lines of one row: the edges interpolated
                          ; line by line (slopes by Divide)
l_9448:
  INC L
  INC IX
  CP (IX+$00)
  JR Z,l_9448
  DEC IX
  LD A,(DrawRoadNext+$0001)
  ADD A,L
  DEC A
  LD (DrawRoadNext+$0001),A
  LD A,L
  LD (RunLines),A
  LD (SavedSp2),SP
  LD SP,(SavedSp)
  LD A,$C9
  LD (MultiplyEnd),A
  XOR A
  LD (RunLines+$0005),A
  LD (RunLines+$0007),A
  LD (RunLines+$0001),A
  LD (RunLines+$0003),A
  LD L,C
  SET 7,L
  LD H,$5B
  LD A,(HL)
  LD L,C
  LD H,$7F
  LD L,(HL)
  CP $FF
  JP Z,DrawRoadRunOff
  ADD A,$00
  LD C,$00
  JR NC,l_9495
  BIT 7,A
  JP Z,DrawRoadRunOff
  NEG
  INC C
l_9495:
  CALL Multiply
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(l_93BB+$0006)
  LD B,A
  LD A,H
  DEC C
  JR NZ,l_94A5
  NEG
l_94A5:
  ADD A,$80
  SUB B
  LD (RunLines+$0002),A
  LD C,A
  LD A,$BF
  JR NC,l_94B2
  LD A,$23
l_94B2:
  LD (RoadRunOp),A
  LD A,C
  ADD A,B
  ADD A,B
  JR NC,l_94BC
  LD A,$00
l_94BC:
  LD (RunLines+$0006),A
  LD A,(IX+$01)
  CP $FF
  JR NZ,l_94C7
  XOR A
l_94C7:
  LD C,A
  OR $80
  LD (l_94E8+$0004),A
  LD L,A
  LD H,$5B
  LD A,(HL)
  LD L,C
  LD H,$7F
  LD L,(HL)
  CP $FF
  JP Z,DrawRoadRunOff
  ADD A,$00
  LD C,$00
  JR NC,l_94E8
  BIT 7,A
  JP Z,DrawRoadRunOff
  NEG
  INC C
l_94E8:
  CALL Multiply
  LD L,$00
  LD H,$7F
  LD B,(HL)
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  LD A,H
  DEC C
  JR NZ,l_94F9
  NEG
l_94F9:
  ADD A,$80
  SUB B
  LD (RunLines+$0004),A
  ADD A,B
  ADD A,B
  LD (RunLines+$0008),A
  LD B,A
  LD A,(RunLines)
  LD E,A
  LD A,(RunLines+$0006)
  LD C,A
  LD A,B
  SUB C
  JR NC,l_9514
  NEG
  SCF
l_9514:
  BIT 7,A
  JR Z,l_951B
  NEG
  AND A
l_951B:
  LD D,A
  EX AF,AF'
  CALL Divide
  EX AF,AF'
  JR NC,l_9529
  EX DE,HL
  LD HL,$0000
  SBC HL,DE
l_9529:
  LD (RunLines+$000B),HL
  LD A,(RunLines)
  LD E,A
  LD A,(RunLines+$0002)
  LD B,A
  LD A,(RunLines+$0004)
  SUB B
  JR NC,l_953D
  NEG
  SCF
l_953D:
  BIT 7,A
  JR Z,l_9544
  NEG
  SCF
l_9544:
  LD D,A
  EX AF,AF'
  CALL Divide
  EX AF,AF'
  JR NC,l_9552
  EX DE,HL
  LD HL,$0000
  SBC HL,DE
l_9552:
  LD (RunLines+$0009),HL
  LD A,$C3
  LD (MultiplyEnd),A
  LD SP,(SavedSp2)
; This entry point is used by the routine at DrawRoadRunLine.
l_955E:
  LD A,(RunLines+$0002)
  POP DE

; One opcode the run writes per line: $BF (CP A) or $23 (INC HL), executed
; after POP DE
;
; DrawRoadRun writes it at $94B2 and $95F1. L1 has the byte executed in every
; recording; the kit keeps it as a byte because its instruction changes.
RoadRunOp:
  DEFB $00

; One line of a run: the left edge, the right edge at the interpolated x, then
; the slopes added
;
; Witness: L1 119870 (c1, crash, ctl, m128, stages, twoplayer).
DrawRoadRunLine:
  LD B,A
  EX AF,AF'
  LD A,B
  AND $07
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,(l_93BB+$0013)
  ADD HL,BC
  EX AF,AF'
  JR Z,l_958D
  RRA
  RRA
  RRA
  OR $E0
  ADD A,$03
  JR NC,l_959A
  JR Z,l_959A
  LD C,A
  LD B,$00
  DEC A
  OR E
  LD E,A
  INC HL
  INC HL
  LDDR
  INC DE
  JR l_959A
l_958D:
  AND $F8
  RRA
  RRA
  RRA
  OR E
  LD E,A
  LDI
  LDI
  LDI
l_959A:
  LD A,(RunLines+$0006)
  BIT 7,A
  JR Z,l_95D1
  LD B,A
  AND $F8
  RRA
  RRA
  RRA
  LD C,A
  EX AF,AF'
  LD A,E
  AND $E0
  OR C
  LD E,A
  LD A,B
  AND $07
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,(l_93BB+$0013)
  ADD HL,BC
  EX AF,AF'
  SUB $1E
  JR C,l_95CB
  SUB $02
  NEG
  LD C,A
  LD B,$00
  LDIR
  JR l_95D1
l_95CB:
  LDI
  LDI
  LDI
l_95D1:
  LD HL,(RunLines+$0005)
  LD A,H
  AND A
  JR Z,l_95E0
  LD DE,(RunLines+$000B)
  ADD HL,DE
  LD (RunLines+$0005),HL
l_95E0:
  LD HL,(RunLines+$0001)
  LD DE,(RunLines+$0009)
  ADD HL,DE
  LD (RunLines+$0001),HL
  BIT 7,H
  JR Z,l_95F4
  LD A,$23
  LD (RoadRunOp),A
l_95F4:
  LD A,(RunLines)
  DEC A
  LD (RunLines),A
  JP NZ,l_955E
  JP DrawRoadNext

; A run whose row is off the table: SP past its lines, MultiplyEnd = JP again,
; on to DrawRoadNext
;
; Known only from the code.
DrawRoadRunOff:
  LD HL,(SavedSp2)
  LD A,(RunLines)
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD SP,HL
  LD A,$C3
  LD (MultiplyEnd),A
  JP DrawRoadNext

  ORG $999A

; Stage 3's row builder: in the air every row's line is $70 + depth * ($80 -
; JumpHeight) / 256; on the ground RoadRowsFlat
;
; In a fall (FallTime) nothing changes. Out: RoadLines, then RoadRowsMake. With
; JumpHeight near $80 every row is $70 (RoadTopRow $FF: the reset).
;
; Recorded: stages, reset3: stage 3's jumps; reset3 frame 6758: JumpHeight $76,
; RoadLines all $70, RoadTopRow $FF.
;
; Witness: L1 305 (stages).
RoadRowsJump:
  LD A,(JumpHeight+$0001)
  AND A
  JP Z,RoadRowsFlat
  LD E,A
  NEG
  ADD A,$80
  LD (RoadJumpRows+$0001),A
  LD D,A
  LD A,(FallTime)
  AND A
  RET NZ
  LD A,$70
  LD (RoadJumpRows+$000A),A
  LD IX,Perspective+$007F
  LD IY,RoadLines+$007F
  LD C,$80
  LD A,E
  AND A
  JR NZ,RoadJumpRows

; JumpHeight 0 inside the jump path: lines from $79 down
;
; Known only from the code: the path is entered only with JumpHeight nonzero,
; so it is unreachable.
RoadJumpGround:
  LD A,D
  LD L,(IX+$00)
  CALL Multiply
  LD E,$79
  LD A,E
  SUB D
  LD (IY+$00),E
  LD (RoadJumpRows+$000A),A
  DEC IYL
  DEC IXL
  DEC C

; Each row: perspective * n >> 8, + $70 (n the LD A operand, $80 - JumpHeight)
;
; Witness: L1 10112 (stages).
RoadJumpRows:
  LD A,$00
  LD L,(IX+$00)
  CALL Multiply
  LD A,D
  ADD A,$70
  LD (IY+$00),A
  DEC IYL
  DEC IXL
  DEC C
  JR NZ,RoadJumpRows
  JP RoadRowsMake

  ORG $9A91

; Stage 5's road routine: IX = RowList, no drawing
;
; Recorded: stages: stage 5.
;
; Witness: L1 408 (stages).
RoadNone:
  LD IX,RowList
  RET

; A row builder no stage uses: rows into the line buffer at $8000, edges from
; $75B0
;
; 537 bytes. It sets MultiplyEnd = RET, fills the buffer with per-line x
; positions (Divide's slopes, like DrawRoadRun) and draws from it with IX =
; $75B0. No StageParams entry and no instruction points at it. Known only from
; the code.
RoadRowsOld:
  LD HL,LineBuffer
  LD A,$C9
  LD (MultiplyEnd),A
  LD A,(RoadTopRow)
  LD C,A
  AND A
  NOP
  JR Z,l_9AAC
l_9AA6:
  LD (HL),$00
  INC HL
  DEC A
  JR NZ,l_9AA6
l_9AAC:
  EX DE,HL
  LD A,C
  LD IYH,D
  LD IYL,E
l_9AB2:
  LD (l_9B07+$0001),A
  LD A,(IX+$00)
  CP $FF
  JP Z,l_9B24
  LD C,A
  OR $80
  LD L,A
  LD H,$7F
  LD A,(HL)
  LD (l_9AF9+$0003),A
  LD A,C
  CP (IX+$01)
  JP Z,l_9B35
  LD H,$5B
  LD A,(HL)
  LD L,C
  LD H,$7F
  LD L,(HL)
  CP $FF
  JP Z,l_9B16
  ADD A,$00
  LD C,$00
  JR NC,l_9AE8
  BIT 7,A
  JP Z,l_9B16
  NEG
  INC C
l_9AE8:
  CALL Multiply
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  BIT 7,H
  JP NZ,l_9B16
  LD A,H
  DEC C
  JR NZ,l_9AF9
  NEG
l_9AF9:
  ADD A,$80
  LD B,$00
  LD (IY+$00),$00
  SUB B
  JR C,l_9B07
  LD (IY+$00),A
l_9B07:
  LD A,$00
  INC IX
  INC IY
l_9B0D:
  INC A
l_9B0E:
  CP $50
  JP C,l_9AB2
l_9B13:
  JP l_9C2C
l_9B16:
  LD A,(CurveDir)
  AND A
  LD A,$FF
  JR Z,l_9B1F
  INC A
l_9B1F:
  LD (IY+$00),A
  JR l_9B07
l_9B24:
  LD A,(l_9B07+$0001)
  LD C,$00
l_9B29:
  LD (IY+$00),C
  INC IY
  INC A
  CP $50
  JR C,l_9B29
  JR l_9B13
l_9B35:
  LD L,$00
l_9B37:
  INC L
  INC IX
  CP (IX+$00)
  JR Z,l_9B37
  LD A,L
  LD (RunLines),A
  XOR A
  LD (RunLines+$0001),A
  LD (RunLines+$0003),A
  LD L,C
  SET 7,L
  LD H,$5B
  LD A,(HL)
  LD L,C
  LD H,$7F
  LD L,(HL)
  CP $FF
  JP Z,l_9C14
  ADD A,$00
  LD C,$00
  JR NC,l_9B67
  BIT 7,A
  JP Z,l_9C14
  NEG
  INC C
l_9B67:
  CALL Multiply
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(l_9AF9+$0003)
  LD B,A
  LD A,H
  DEC C
  JR NZ,l_9B77
  NEG
l_9B77:
  ADD A,$80
  SUB B
  LD C,A
  JR NC,l_9B7F
  LD A,$FF
l_9B7F:
  LD (RunLines+$0002),A
  LD A,(IX+$00)
  INC A
  JR Z,l_9B89
  DEC A
l_9B89:
  LD C,A
  OR $80
  LD L,A
  LD H,$7F
  LD A,(HL)
  EX AF,AF'
  LD H,$5B
  LD A,(HL)
  LD L,C
  LD H,$7F
  LD L,(HL)
  CP $FF
  JP Z,l_9C14
  ADD A,$00
  LD C,$00
  JR NC,l_9BAB
  BIT 7,A
  JP Z,l_9C14
  NEG
  INC C
l_9BAB:
  CALL Multiply
  EX AF,AF'
  LD B,A
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  LD A,H
  DEC C
  JR NZ,l_9BB9
  NEG
l_9BB9:
  ADD A,$80
  SUB B
  LD (RunLines+$0004),A
  LD A,(RunLines)
  LD E,A
  LD A,(RunLines+$0002)
  LD B,A
  LD A,(RunLines+$0004)
  SUB B
  JR NC,l_9BD0
  NEG
  SCF
l_9BD0:
  BIT 7,A
  JR Z,l_9BD7
  NEG
  SCF
l_9BD7:
  LD D,A
  EX AF,AF'
  CALL Divide
  EX AF,AF'
  JR NC,l_9BE5
  EX DE,HL
  LD HL,$0000
  SBC HL,DE
l_9BE5:
  LD (RunLines+$0009),HL
  LD C,$00
  LD A,(RunLines)
  LD B,A
  LD A,(l_9B07+$0001)
  ADD A,B
  LD (l_9B07+$0001),A
l_9BF5:
  LD (IY+$00),C
  LD HL,(RunLines+$0001)
  BIT 7,H
  JR NZ,l_9C0A
  LD (IY+$00),H
  LD DE,(RunLines+$0009)
  ADD HL,DE
  LD (RunLines+$0001),HL
l_9C0A:
  INC IY
  DJNZ l_9BF5
  LD A,(l_9B07+$0001)
  JP l_9B0E
l_9C14:
  LD A,(RunLines)
  LD E,A
  LD A,(l_9B07+$0001)
  ADD A,E
  LD (l_9B07+$0001),A
  LD C,$00
l_9C21:
  LD (IY+$00),C
  INC IY
  DEC E
  JR NZ,l_9C21
  JP l_9B0D
l_9C2C:
  LD (SavedSp),SP
  LD SP,RowTable+$00E0
  LD IY,LineBuffer
  LD IX,RoadRowsOldData
  LD A,$0A
l_9C3D:
  LD (l_9C8D+$0013),A
  LD E,IYL
  LD D,IYH
  EX DE,HL
  LD DE,$00FF
  LD B,$08
l_9C4A:
  LD A,(HL)
  CP D
  JR C,l_9C4F
  LD D,A
l_9C4F:
  CP E
  JR NC,l_9C53
  LD E,A
l_9C53:
  INC HL
  DJNZ l_9C4A
  LD A,D
  AND $F8
  RRA
  RRA
  RRA
  LD (IX+$01),A
  LD A,E
  INC D
  DEC D
  JR NZ,l_9C6D
  AND A
  JR NZ,l_9C6D
  LD (IX+$00),$FF
  JR l_9C76
l_9C6D:
  AND $F8
  LD E,A
  RRA
  RRA
  RRA
  LD (IX+$00),A
l_9C76:
  LD D,A
  LD A,$08
l_9C79:
  EX AF,AF'
  POP HL
  LD A,L
  OR D
  LD L,A
  LD A,(IY+$00)
  SUB E
  SUB $08
  JR C,l_9C8D
l_9C86:
  LD (HL),$FF
  INC L
  SUB $08
  JR NC,l_9C86
l_9C8D:
  ADD A,$08
  EXX
  ADD A,$16
  LD C,A
  LD B,$93
  LD A,(BC)
  EXX
  LD (HL),A
  INC IY
  EX AF,AF'
  DEC A
  JP NZ,l_9C79
  LD A,$00
  LD DE,$0002
  ADD IX,DE
  DEC A
  JP NZ,l_9C3D
  LD SP,(SavedSp)
  RET

; Eight pixel masks for GroundTexture's dots ($FF $7F $3F $1F $0F $07 $03 $01:
; a dot of width 8 - n)
DotMasks:
  DEFB $FF,$7F,$3F,$1F,$0F,$07,$03,$01

; Stages 1, 2, 4 and 5's row builder: RoadLines from the perspective and the
; curve, as the segment goes by
;
; Curve 0 with CurvePrev 0: RoadRowsMake on the last lines; otherwise, for
; curves 1-3, entering (CurvePrev 0) or leaving, the rows over the segment's
; progress (SegmentLeft) get $70 + (perspective * curve table) / 512, the rest
; the plain perspective.
;
; Recorded: c1: every pass.
;
; Witness: L1 4072 (c1, crash, ctl, m128, stages, twoplayer).
RoadRowsCurve:
  LD A,(CurvePrev)
  AND A
  JR NZ,l_9CE1
  LD IY,CurveTable
  LD A,(SegmentLeft+$0001)
  LD IXH,$78
  LD IXL,A
  LD A,$80
  SUB IXL
  JP Z,RoadRowsMake
  LD E,A
  LD A,(Curve)
  AND A
  JP Z,RoadRowsMake
  CP $02
  JR Z,l_9D58
  JR NC,l_9D0B
  JP l_9DA0
l_9CE1:
  CP $02
  JR Z,l_9D45
  JR NC,l_9CEA
  JP l_9D91
l_9CEA:
  LD A,(Curve)
  INC A
  LD D,A
  LD A,(SegmentLeft+$0001)
  LD C,A
  DEC A
  SRL A
  XOR $3F
  DEC D
  JR NZ,l_9D00
  ADD A,$40
  LD E,C
  JR l_9D02
l_9D00:
  LD E,$80
l_9D02:
  LD IYL,A
  LD IYH,$7A
  LD IX,Perspective
l_9D0B:
  LD A,E
l_9D0C:
  EX AF,AF'
  LD A,(IX+$00)
  LD L,(IY+$00)
  CALL Multiply
  LD A,D
  SRL A
  ADD A,$70
  LD E,IXL
  LD D,$5C
  LD (DE),A
  INC IXL
  EX AF,AF'
  DEC A
  JR Z,l_9D42
  EX AF,AF'
  LD A,(IX+$00)
  LD L,(IY+$00)
  CALL Multiply
  LD A,D
  SRL A
  ADD A,$70
  LD E,IXL
  LD D,$5C
  LD (DE),A
  INC IXL
  INC IYL
  EX AF,AF'
  DEC A
  JR NZ,l_9D0C
l_9D42:
  JP l_9DCE
l_9D45:
  LD A,(SegmentLeft+$0001)
  LD E,A
  DEC A
  AND $3F
  ADD A,A
  XOR $7F
  LD IYL,A
  LD IYH,$7A
  LD IX,Perspective
l_9D58:
  LD A,E
l_9D59:
  EX AF,AF'
  LD A,(IX+$00)
  LD L,(IY+$00)
  CALL Multiply
  LD A,D
  SRL A
  ADD A,$70
  LD E,IXL
  LD D,$5C
  LD (DE),A
  LD A,IYL
  ADD A,$02
  AND $7F
  LD IYL,A
  INC IXL
  EX AF,AF'
  DEC A
  JR NZ,l_9D59
  LD A,IXL
  AND $80
  JP NZ,RoadRowsMake
  LD A,(Curve)
  AND A
  JR Z,l_9DCE
  LD A,(SegmentLeft+$0001)
  SUB $80
  NEG
  JR l_9D59
l_9D91:
  LD A,(SegmentLeft+$0001)
  CPL
  LD IX,Perspective
  ADD A,$81
  LD IYL,A
  LD IYH,$7A
l_9DA0:
  LD A,(IX+$00)
  LD L,(IY+$00)
  CALL Multiply
  LD E,IXL
  LD A,D
  SRL A
  ADD A,$70
  LD D,$5C
  LD (DE),A
  LD A,IYL
  INC A
  AND $7F
  LD IYL,A
  JR Z,l_9DC6
l_9DBC:
  INC IXL
  LD A,IXL
  CP $80
  JR NZ,l_9DA0
  JR RoadRowsMake
l_9DC6:
  LD A,(Curve)
  AND A
  JR NZ,l_9DBC
l_9DCC:
  INC IXL
l_9DCE:
  LD A,IXL
  CP $80
  JR NC,RoadRowsMake
  LD A,(IX+$00)
  SRL A
  ADD A,$70
  INC DE
  LD (DE),A
  JR l_9DCC

; RoadLines = $70 + perspective / 2 for all 128 rows
;
; Witness: L1 396 (c1, crash, ctl, m128, stages, twoplayer).
RoadRowsFlat:
  LD HL,RoadLines+$007F
  LD DE,Perspective+$007F
  LD B,$80
l_9DE7:
  LD A,(DE)
  SRL A
  ADD A,$70
  LD (HL),A
  DEC E
  DEC L
  DJNZ l_9DE7
; This entry point is used by the routines at RoadJumpRows and RoadRowsCurve.
RoadRowsMake:
  LD IX,RowList           ; RowList from RoadLines (each line once, rows that
                          ; share a line skipped), $FF end; RoadTopRow =
                          ; RoadLines[127] - $71
  LD HL,RoadLines+$007F
  LD A,(HL)
  LD C,A
  SUB $71
  LD (RoadTopRow),A       ; RoadTopRow: $FF when the last row is at line $70
l_9DFF:
  LD A,(HL)
  CP C
  JR Z,l_9E05
  JR NC,l_9E09
l_9E05:
  DEC L
  JR NZ,l_9DFF
  RET
l_9E09:
  SUB C
l_9E0A:
  LD (IX+$00),L
  INC IXL
  DEC A
  JR NZ,l_9E0A
  LD C,(HL)
  DEC L
  JR NZ,l_9DFF
  LD (IX+$00),$FF
  LD A,(Stage)
  CP $04
  RET NZ
  LD A,(CurvePrev)
  AND A
  RET NZ
  INC L
  LD (IX+$00),L
  LD (IX+$01),L
  LD (IX+$02),L
  LD (IX+$03),L
  LD (IX+$04),L
  LD (IX+$05),$FF
  RET

  ORG $A301

; Stages 3 and 5: the ground's dots, a ROM byte XOR the column as the random x,
; masks from DotMasks
;
; RandomPtr ($A45B) walks the ROM $0000-$1FFF by 4 * ScrollStep's high byte
; each pass; for each line of RowList, a dot left of the left edge or right of
; the right edge (stage 3), or between them (stage 5).
;
; Recorded: stages: stages 3 and 5.
;
; Witness: L1 4375 (c1, crash, ctl, m128, stages, twoplayer).
GroundTexture:
  LD A,(RoadTopRow)
  LD E,A
  LD A,(Stage)
  CP $02
  JR Z,l_A30F
  CP $04
  RET C
l_A30F:
  LD D,$00
  LD IY,RowTable+$00E0
  LD IX,RowList
  LD B,$00
l_A31B:
  LD A,(IX+$01)
  INC A
  JR Z,l_A327
  INC B
  INC E
  INC IX
  JR l_A31B
l_A327:
  LD A,E
  ADD A,A
  LD E,A
  ADD IY,DE
  LD A,(l_937C+$0025)
  LD (l_A353+$0047),A
  LD A,(l_937C+$0024)
  LD (l_A353+$0046),A
  LD A,(DrawRoadRow+$0006)
  LD (l_A3A7+$000D),A
  LD HL,(RandomPtr)
  LD A,(ScrollStep+$0001)
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  RES 5,H
  LD (RandomPtr),HL
  LD (l_A3CF+$0001),HL
  LD A,B
l_A353:
  EX AF,AF'
  LD A,(IX+$00)
  LD L,A
  SUB (IX-$01)
  NEG
  AND A
  LD H,$7F
  LD E,(HL)
  LD D,A
  JP Z,l_A43D
  CALL Divide
  LD A,L
  INC A
  SRL A
  INC A
  LD B,A
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD (l_A424+$0007),HL
  PUSH BC
  XOR A
  LD (l_A3CF+$000E),A
  DEC A
  LD (l_A418+$0001),A
  LD A,(IX+$00)
  LD C,A
  OR $80
  LD L,A
  LD H,$7F
  LD A,(HL)
  LD (l_A3B8+$0006),A
  LD H,$5B
  LD A,(HL)
  LD L,C
  LD H,$7F
  LD L,(HL)
  CP $FF
  JP Z,l_A449
  ADD A,$00
  LD C,$00
  JR NC,l_A3A7
  BIT 7,A
  JP Z,l_A449
  NEG
  INC C
l_A3A7:
  CALL Multiply
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  BIT 7,H
  JP NZ,l_A449
  LD A,H
  DEC C
  JR NZ,l_A3B8
  NEG
l_A3B8:
  ADD A,$80
  LD (l_A3CF+$0009),A
  LD B,$00
  SRL B
  SUB B
  JR C,l_A3C7
  LD (l_A3CF+$000E),A
l_A3C7:
  ADD A,B
  ADD A,B
  JR C,l_A3CE
  LD (l_A418+$0001),A
l_A3CE:
  POP BC
l_A3CF:
  LD HL,$0000
  INC HL
  RES 5,H
  LD A,(HL)
  XOR L
  ADD A,$00
  LD (l_A3CF+$0001),HL
  CP $00
  JR NC,l_A418
  LD C,A
  LD A,(Stage)
  CP $04
  JR C,l_A43B
  LD HL,l_A3CF+$000E
  LD A,(l_A418+$0001)
  SUB (HL)
  SRL A
  NEG
  ADD A,(HL)
  CP C
  JR C,l_A424
  LD A,C
  AND $F8
  RRA
  RRA
  RRA
  LD HL,(l_A424+$0007)
  OR L
  LD L,A
  LD A,C
  AND $07
  LD E,B
  LD B,A
  LD A,$FF
  LD C,$00
  JR Z,l_A412
l_A40D:
  RRA
  RR C
  DJNZ l_A40D
l_A412:
  LD B,E
  LD (HL),A
  INC L
  LD (HL),C
  JR l_A43B
l_A418:
  CP $00
  JR NC,l_A43B
  LD C,A
  LD A,(Stage)
  CP $02
  JR NZ,l_A43B
l_A424:
  LD A,C
  AND $F8
  RRA
  RRA
  RRA
  LD HL,$0000
  OR L
  LD L,A
  LD A,C
  AND $07
  ADD A,$AF
  LD E,A
  LD D,$9C
  LD A,(DE)
  INC A
  OR (HL)
  LD (HL),A
l_A43B:
  DJNZ l_A3CF
l_A43D:
  DEC IY
  DEC IY
  DEC IX
  EX AF,AF'
  DEC A
  JP NZ,l_A353
  RET
l_A449:
  LD A,(CurveDir)
  AND A
  LD A,$FF
  JR Z,l_A452
  INC A
l_A452:
  LD (l_A3CF+$000E),A
  LD (l_A418+$0001),A
  JP l_A3CE

; GroundTexture's ROM pointer ($0000-$1FFF)
RandomPtr:
  DEFB $00,$02

  ORG $B07D

; As the segment moves (RowsScrolled), shift HillRows down and fill from the
; hill's profile (HillProfiles)
;
; Witness: L1 4377 (c1, crash, ctl, m128, stages, twoplayer).
ScrollHills:
  LD A,(RowsScrolled)
  AND A
  RET Z
  LD A,(HillPrev)
  AND A
  JR NZ,BlendHill
  LD A,(SegmentLeft+$0001)
  ADD A,$80
  RET C
  LD L,A
  LD H,$5B
  LD A,(Hill)
  AND A
  RET Z
  ADD A,$FA
  LD B,A
  LD A,(RowsScrolled)
  ADD A,L
  JR Z,l_B0A1
  JR NC,l_B0B3
l_B0A1:
  EX DE,HL
  LD C,$00
  SRL B
  RR C
l_B0A8:
  LD A,(BC)
  LD (DE),A
  INC C
  INC E
  JR NZ,l_B0A8
  LD (HillPtr),BC
  RET
l_B0B3:
  LD E,A
  LD D,H
  NEG
  LD C,A
  LD A,(l_AF80+$0001)
  CP C
  LD B,$00
  EX DE,HL
  JR C,ScrollHillsTail
  LDIR
  LD BC,(HillPtr)
  JR l_B0A8

; The profile's end reached inside the copy: the rest from BlendHill's start
;
; Known only from the code.
ScrollHillsTail:
  LD C,A
  LDIR
  EX DE,HL
  DEC HL
  RET Z
  JR l_B0DE

; Hill 0 after a hill: HillRows blended back to flat, the profile's step from
; HillBlend ($75D7)
;
; Witness: L1 1541 (c1, crash, m128, stages, twoplayer).
BlendHill:
  LD A,(Hill)
  AND A
  RET NZ
  LD A,(SegmentLeft+$0001)
  OR $80
  LD L,A
  LD H,$5B
; This entry point is used by the routine at ScrollHillsTail.
l_B0DE:
  LD A,L
  CP $80
  RET Z
  LD D,H
  LD B,$04
  SUB $10
  BIT 7,A
  JR NZ,l_B101
  LD A,L
  LD E,A
  AND $0F
  LD L,A
  LD A,(HillPrev)
  ADD A,$D7
  ADD A,L
  LD L,A
  LD H,$75
  JR NC,l_B0FC

; INC H: HillBlend's index crossing a page (not met)
;
; Known only from the code.
BlendCarry:
  INC H
; This entry point is used by the routine at BlendHill.
l_B0FC:
  LD A,(DE)               ; the blend
  LD C,A
  LD A,(HL)
  JR l_B106
; This entry point is used by the routine at BlendHill.
l_B101:
  LD E,A
  EX DE,HL
  LD A,(DE)
  LD C,A
  SUB (HL)
l_B106:
  LD H,C
  LD L,$00
  LD C,L
l_B10A:
  RRA
  RR C
  DJNZ l_B10A
  LD B,A
l_B110:
  LD A,H
  ADD HL,BC
  JR NC,l_B117
  LD HL,StackArea+$007F
l_B117:
  LD (DE),A
  INC E
  JR NZ,l_B110
  RET

; The road rows the segment moved this pass (AdvanceTrack), for ScrollHills
RowsScrolled:
  DEFB $00
