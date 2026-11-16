; --------------------------------------------------------------------------------------------------------------------
; render.asm: The back buffer, RowTable, the sprite blitters, the copy to the screen
;
; RowTable ($FE00-$FF7F) holds the address of each of the 192 pixel lines. SetRowTable (DE) adds DE to lines 64-191
; and rebuilds lines 40-63, so the same table points at the screen (DE = $5A00, back from the buffer) or at the back
; buffer (DE = $A600): lines 40-63 are $EB00 + 32 (n - 40), lines 64-191 the screen address + $A600 ($EE00-$FDFF in
; the screen's own order). Lines 0-39 (the HUD) always point at the screen. Every drawing routine goes through
; RowTable: the printer, the road, the sprites; StartRace switches it to the back buffer and RaceEnd back.
;
; The blitters (BlitRows, the core of DrawSprite and DrawShifted) take SP = RowTable + 2 * line and POP each line's
; address, OR a sprite row into it, clipped at line 40 (TopClip) and at the screen's sides. An interrupt pushes its
; return address into RowTable then; Interrupt puts the entry back (RowEntry). DrawShifted first copies the sprite's
; rows into the line buffer at $8000 shifted by x AND 7 (an unrolled RR / RL chain entered at the width's place);
; DrawMirrored ($970C) copies them mirrored through ReverseTable.
;
; CopyBuffer copies the back buffer to the screen each pass: from the highest line anything was drawn on (TopClip,
; DrawnTop) to line 63 line by line, then lines 64-191 in one block ($EE00 to $4800, 4096 bytes). BlitCopyPop, the POP
; copy the stage table's byte 7 could select, never runs (byte 7 is 0 on all five stages).
; --------------------------------------------------------------------------------------------------------------------

; RowTable's lines 64-191 += DE; lines 40-63: the screen's (DE = $5A00) or the
; back buffer's rows
;
; In: DE = $A600 (to the back buffer) or $5A00 (back to the screen: $A600 +
; $5A00 = $10000). Lines 40-63 get lines 168-191's addresses minus $1000 (the
; screen's rows 40-63), and with DE not $5A00 then $EB00 + 32 n.
;
; Recorded: c1: StartRace $A466 and RaceEnd $AAA8 each stage.
;
; Witness: L1 48 (c1, crash, ctl, fall5, m128, names, stages, truck,
; twoplayer).
SetRowTable:
  LD B,$80
  LD IX,RowTable+$0080
l_8E83:
  LD L,(IX+$00)
  LD H,(IX+$01)
  ADD HL,DE
  LD (IX+$00),L
  LD (IX+$01),H
  INC IX
  INC IX
  DJNZ l_8E83
  LD A,D
  LD IX,RowTable+$0050
  LD IY,RowTable+$0150
  LD B,$18
  LD DE,-$1000
l_8EA4:
  LD L,(IY+$00)
  LD H,(IY+$01)
  ADD HL,DE
  LD (IX+$00),L
  LD (IX+$01),H
  INC IX
  INC IX
  INC IY
  INC IY
  DJNZ l_8EA4
  CP $5A
  RET Z
  LD B,$18
  LD IX,RowTable+$0050
  LD HL,TrackTables
  LD DE,$0020
l_8ECA:
  LD (IX+$00),L
  LD (IX+$01),H
  ADD HL,DE
  INC IX
  INC IX
  DJNZ l_8ECA
  RET

; BendRows = 0 ($5B80-$5C00, 129 bytes through CopyRows)
;
; Witness: L1 175 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
ClearBendRows:
  LD HL,BendRows
  LD DE,BendRows+$0001
  LD (HL),$00
  LD A,$04
  JR CopyRows31

; Copy A x 32 bytes HL -> DE (32 unrolled LDI a turn)
;
; Witness: L1 1004349 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
CopyRows:
  LDI
; This entry point is used by the routine at ClearBendRows.
CopyRows31:
  LDI                     ; the first turn one LDI shorter (ClearBendRows'
                          ; fill)
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DEC A
  JP NZ,CopyRows
  RET

; A byte-aligned sprite: C bytes wide, B rows from DE, at x H (carry: x < 0),
; bottom line L
;
; Sets the core's skip (BlitSkip, $9104) and first column ($906A, $90FE) from
; x, clipping at the left edge (RET when wholly off), then BlitRows.
;
; Witness: L1 13978 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawSprite:
  LD C,A
  LD A,$00
  LD (BlitNext+$0007),A
  LD (BlitRows+$0001),A
  LD A,H
  JR NC,l_8F47
  RRA
  RRA
  RRA
  OR $E0
  LD (BlitRows+$0001),A
  NEG
  CP C
  RET NC
  LD (BlitNext+$0007),A
  XOR A
  JR l_8F4C
l_8F47:
  AND $F8
  RRA
  RRA
  RRA
l_8F4C:
  LD (BlitNext+$0001),A
  LD A,C
  JP BlitRows

; A sprite at any x: its rows shifted by x AND 7 into the line buffer at $8000,
; then BlitRows
;
; In as DrawSprite. Row by row: the bytes copied (the unrolled LDI chain
; entered by the patched DJNZ at $8FE7), then RR (HL) or RL (HL) chains shift
; the row (x AND 7 below 4: right; else left by 8 - n). Byte-aligned x goes
; straight to BlitRows.
;
; Recorded: c1: the bike, the riders and the objects every pass.
;
; Witness: L1 50169 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawShifted:
  LD C,A
  LD A,$00
  LD (BlitNext+$0007),A
  LD (BlitRows+$0001),A
  LD A,H
  PUSH DE
  PUSH BC
  EXX
  POP BC
  LD H,A
  JR NC,l_8F79
  RRA
  RRA
  RRA
  OR $E0
  LD (BlitRows+$0001),A
  NEG
  CP C
  JR C,l_8F73
  POP DE
  RET
l_8F73:
  LD (BlitNext+$0007),A
  XOR A
  JR l_8F7E
l_8F79:
  AND $F8
  RRA
  RRA
  RRA
l_8F7E:
  LD (BlitNext+$0001),A
  LD A,H
  AND $07
  JR NZ,l_8F92
  POP DE
  LD A,D
  CP $80
  EXX
  LD A,C
  JP NZ,BlitRows
  EXX
  PUSH DE
  XOR A
l_8F92:
  INC B
  LD HL,LineBuffer+1
  BIT 2,A
  JR Z,l_8F9E
  CPL
  ADD A,$09
  DEC HL
l_8F9E:
  EX AF,AF'
  LD (l_9064+$0003),HL
  POP HL
  LD DE,LineBuffer
  LD A,$FC
  SUB C
  SUB C
  LD (l_8FE5+$0003),A
  INC C
  SUB C
  LD (l_901F+$0001),A
  LD (l_905A+$0001),A
  LD A,B
  LD (l_9021+$0001),A
  LD (l_905C+$0001),A
  PUSH BC
  LD A,H
  CP D
  JR NZ,l_8FC6
  LD HL,$0000
  JR l_8FEB
l_8FC6:
  XOR A
  LD C,$FF
  JR l_8FE5

; The first three LDI of the row copy: entered only for rows of 12 bytes or
; more
;
; Known only from the code: no sprite drawn shifted is that wide.
ShiftCopyHead:
  LDI
  LDI
  LDI
ShiftCopy:
  LDI                     ; the row copy (entered at its width)
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
; This entry point is used by the routine at DrawShifted.
l_8FE5:
  LD (DE),A
  INC E
  DJNZ l_8FE9
l_8FE9:
  EX DE,HL
  DEC L
; This entry point is used by the routine at DrawShifted.
l_8FEB:
  POP BC
  LD A,(l_9064+$0003)
  AND A
  JR Z,l_902C
  EX AF,AF'
  AND A
  JR Z,l_9064
  JR l_901F

; The first two RR (HL) of the right shift: rows of 12 bytes or more
;
; Known only from the code.
ShiftRightHead:
  RR (HL)
  INC L
  RR (HL)
  INC L
ShiftRight:
  RR (HL)                 ; the right shift chain
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
; This entry point is used by the routine at ShiftCopyHead.
l_901F:
  DJNZ l_9021
l_9021:
  LD B,$00
  LD HL,LineBuffer+1
  SUB $01
  JR NZ,l_901F
  JR l_9064
; This entry point is used by the routine at ShiftCopyHead.
l_902C:
  EX AF,AF'
  AND A
  LD (l_905C+$0003),HL
  JR l_905A

; The first two RL (HL) of the left shift: rows of 12 bytes or more
;
; Known only from the code.
ShiftLeftHead:
  RL (HL)
  DEC L
  RL (HL)
  DEC L
ShiftLeft:
  RL (HL)                 ; the left shift chain
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
; This entry point is used by the routine at ShiftRightHead.
l_905A:
  DJNZ l_905C
l_905C:
  LD B,$00
  LD HL,$0000
  DEC A
  JR NZ,l_905A
; This entry point is used by the routines at ShiftCopyHead and ShiftRightHead.
l_9064:
  LD A,C
  EXX
  LD DE,$0000
; This entry point is used by the routines at DrawSprite and DrawShifted.
BlitRows:
  ADD A,$00               ; the core: SP = RowTable + 2 * line, POP each line,
                          ; OR the row, clipped at 32 columns
  LD C,A
  LD H,$00
  LD A,(BlitNext+$0001)
  ADD A,C
  SUB $20
  JR C,l_9080
  JR Z,l_9080
  LD (BlitNext+$0007),A
  NEG
  ADD A,C
  LD C,A
  INC H
l_9080:
  LD A,$04
  BIT 0,C
  SRL C
  JR NC,l_9089
  XOR A
l_9089:
  LD (l_90F7+$0001),A
  LD A,C
  ADD A,A
  ADD A,A
  ADD A,C
  CPL
  SUB $02
  LD (BlitRow+$003E),A
  SUB $15
  LD (l_910A+$0001),A
  LD A,H
  INC B
  LD C,$02
  LD H,$7F
  ADD HL,HL
  LD (SavedSp),SP
  LD SP,HL
  EX DE,HL
  DEC A
  JR NZ,BlitNext
  LD A,(BlitNext+$0001)
  POP DE
  OR E
  LD E,A
  JR l_910A

; The first OR of the unrolled row: rows of 13 bytes
;
; Known only from the code.
BlitHead:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
BlitRow:
  LD A,(DE)               ; the unrolled OR of one row (entered at its width)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  DEC C
  JR NZ,l_90F7
l_90F7:
  JR l_90F9
l_90F9:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
; This entry point is used by the routine at ShiftLeftHead.
BlitNext:
  LD A,$00                ; next line: SP pops it
  POP DE
  OR E
  LD E,A
  LD A,B
  LD BC,$0000
  ADD HL,BC
  LD B,A
  LD C,$02
; This entry point is used by the routine at ShiftLeftHead.
l_910A:
  DJNZ l_910C
l_910C:
  LD SP,(SavedSp)         ; SP back (SavedSp)
  RET

  ORG $970C

; Copy sprite DE's rows into the line buffer at $8000 mirrored (bytes reversed,
; bits through ReverseTable)
;
; In: IX = a descriptor (rows, width; width bit 7: byte-aligned, 3 more bytes
; room). Out: DE = $8000, the sprite in the buffer. Used for the bike leaning
; the other way and for riders and objects on the bend's other side.
;
; Recorded: c1.
;
; Witness: L1 2275 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
DrawMirrored:
  XOR A
  BIT 7,(IX+$02)
  JR Z,l_9715
  LD A,$03
l_9715:
  LD (l_9732+$0001),A
  LD A,(IX+$02)
  AND $7F
  LD B,A
  ADD A,E
  LD E,A
  JR NC,l_9723

; INC D: a sprite crossing a page boundary at its end (not met)
;
; Known only from the code.
MirrorCarry:
  INC D
; This entry point is used by the routine at DrawMirrored.
l_9723:
  LD A,B                  ; the copy
  EXX
  LD L,A
  LD B,A
  LD C,(IX+$01)
  EXX
  ADD A,A
  LD (l_973A+$0010),A
  LD BC,LineBuffer
l_9732:
  JR l_9737
  XOR A
  LD (BC),A
  INC BC
l_9737:
  LD H,$5D
  EXX
l_973A:
  EXX
  DEC DE
  LD A,(DE)
  LD L,A
  LD A,(HL)
  LD (BC),A
  INC BC
  EXX
  DJNZ l_973A
  DEC C
  JR Z,l_9750
  LD B,L
  EXX
  LD HL,$0000
  ADD HL,DE
  EX DE,HL
  JR l_9732
l_9750:
  EXX
  LD (l_8F9E+$0024),BC
  XOR A
  LD (BC),A
  LD DE,LineBuffer
  RET

  ORG $98EF

; JP StartRace (GameEntry's target)
;
; Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).
GameEntryJump:
  JP StartRace

; JP GapRows
;
; Witness: L1 4740 (c1, crash, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
GapRowsJump:
  JP GapRows

; The back buffer to the screen: lines DrawnTop (the highest of TopClip and the
; last pass's) to 63 one by one, then $EE00 to $4800
;
; TopClip ($916C) is the highest line drawn this pass; DrawnTop ($916D) last
; pass's. Lines below 64 are copied through CopyRows a line at a time (screen
; order); then BlitMode's JR (byte 7 of the stage's StageParams, at $9944) is 0
; on every stage: CopyLower copies lines 64-191 ($EE00-$FDFF to $4800-$57FF) in
; one CopyRows of 128.
;
; Recorded: c1: every pass; the heaviest pass's largest single cost with the
; road.
;
; Witness: L1 5138 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
CopyBuffer:
  LD A,(TopClip)
  LD (SavedSp),SP
  LD B,A
  LD A,(DrawnTop)
  CP B
  JR C,l_9904
  LD A,B
l_9904:
  CP $40
  JR NC,BlitMode
  LD C,A
  AND $07
  ADD A,$40
  LD D,A
  LD A,C
  AND $F8
  ADD A,A
  ADD A,A
  LD E,A
  LD A,C
  SUB $40
  NEG
  ADD A,A
  ADD A,A
  ADD A,A
  LD B,$00
  ADD A,A
  RL B
  ADD A,A
  RL B
  LD C,A
  LD HL,BackLine64
  SBC HL,BC
l_992A:
  LD A,$01
  PUSH DE
  CALL CopyRows
  POP DE
  LD A,B
  OR C
  JR Z,BlitMode
  INC D
  LD A,D
  AND $07
  JR NZ,l_992A
  LD D,$40
  LD A,E
  ADD A,$20
  LD E,A
  JR l_992A
BlitMode:
  JR BlitCopyPop          ; JR d: d = byte 7 of StageParams (0 on all stages:
                          ; CopyLower)
CopyLower:
  LD A,$80                ; lines 64-191 in one block
  LD DE,$4800
  LD HL,BackLine64
  JP CopyRows

; A POP copy of B lines through RowTable (each line from back buffer - $A600),
; then JP (IY)
;
; Known only from the code: no stage's byte 7 selects it.
BlitCopyPop:
  POP HL
  LD E,L
  LD A,H
  SUB $A6
  LD D,A
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DJNZ BlitCopyPop
  JP (IY)
