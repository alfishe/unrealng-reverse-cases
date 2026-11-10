; --------------------------------------------------------------------------------------------------------------------
; hens.asm: The hens: moving, eating grain, drawing, and the cell and screen addresses they use
;
; MainLoop $9858 calls MoveHen once every HenDelay slow ticks; each call moves one of the five hen records at Hens. A
; hen walks along its platform, turns at an edge or a wall, takes a ladder at random, and eats the grain in front of
; it. DrawHen draws a hen and is where a hen kills Harry.
; --------------------------------------------------------------------------------------------------------------------

; Move the next hen one step
;
; Returns at once on levels 9-16 (Level 8-15). Otherwise it takes one random
; bit (RandomPtr steps through the ROM's first 256 bytes: C = 1 when bit 0 of
; the byte is 0), advances HenTurn (0-4) and takes that hen's record (x, y,
; state; x = $FF: no hen, return). It erases the hen (DrawHen with A = 0, which
; also tests Harry), then by the state:
;
; 7 or 8 (pecking): back to 1 or 2, the peck is erased and the hen drawn
; standing. 1 or 2 (walking left / right): when x AND 4 is 0 it first tries
; HenEatGrain, then turns (state 3 - state) when the next step x - 8 / x + 8
; leaves the screen or the cell under it (y - 1) is neither a ladder nor a
; brick; then x moves 4 pixels and the hen is drawn; at a column where x AND 4
; is set, and when the random bit allows, it goes onto a ladder: state 3 (down)
; when the cell 8 below is a ladder's left half, 4 (up) when the cell 16 above
; is (bit 1 of the random byte picks which it tests first).
;
; 3 or 4 (climbing down / up): when y AND 4 is 0 and the next cell is no ladder
; it turns (7 - state); y moves 4 pixels; at y AND 4 clear (the new y a
; multiple of 8) and the random bit it steps off onto a brick 8 left (state 1)
; or 16 right (state 2), the row 8 below.
;
; Inputs: the hen records. Outputs: the record moved; the screen. Side effects:
; RandomPtr, HenTurn; DrawHen may end the life (it unwinds the stack to $A656,
; the return of PlayLevel's CALL SetupLevel; SetupLevel enters MainLoop by JP
; $B12D). Witness: 38 158 calls in the eight builds (c1 801); turns $91A1 979,
; onto a ladder $91DB 324 and $91EF 228, off a ladder $924C 213 and $9261 307,
; meals $9281 82.
MoveHen:
  LD A,(Level)
  CP $08
  JR C,MoveHenRandom
  CP $10
  RET C
MoveHenRandom:
  LD HL,(RandomPtr)
  INC HL
  LD H,$00
  LD (RandomPtr),HL
  LD C,$01
  BIT 0,(HL)
  JR Z,MoveHenNext
  DEC C
MoveHenNext:
  LD HL,HenTurn
  LD A,(HL)
  INC A
  CP $05
  JR NZ,MoveHenTurnSet
  XOR A
MoveHenTurnSet:
  LD (HL),A
  SLA A
  SLA A
  ADD A,$57
  LD H,$73
  LD L,A
  LD E,(HL)
  LD A,E
  XOR $FF
  RET Z
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  EX DE,HL
  XOR A
  CALL DrawHen
  EX DE,HL
  LD A,(HL)
  CP $07
  JR C,MoveHenWalk
  LD C,E
  SUB $06
  LD (HL),A
  LD B,A
  CP $02
  JR Z,MoveHenPeckErase
  LD A,E
  SUB $08
  LD E,A
MoveHenPeckErase:
  EX DE,HL
  XOR A
  CALL DrawHen
  LD A,B
  LD L,C
  CALL DrawHen
  RET
MoveHenWalk:
  CP $03                  ; state 1-2: walking (3-8 go on at MoveHenClimb)
  JR NC,MoveHenClimb
  BIT 2,E
  JR NZ,MoveHenStep
  LD B,A
  CALL HenEatGrain
  LD A,E
  ADD A,$08
  JR C,MoveHenTurn
  DJNZ MoveHenFloor
  SUB $10
  JR C,MoveHenTurn
MoveHenFloor:
  LD E,A
  DEC D
  EX DE,HL
  CALL MapCellPeek
  EX DE,HL
  AND A
  JR Z,MoveHenTurn
  CP $03
  JR C,MoveHenStep
  CP $05
  JR Z,MoveHenStep
MoveHenTurn:
  LD A,$03                ; state = 3 - state
  SUB (HL)
  LD (HL),A
MoveHenStep:
  LD B,(HL)               ; x - 4 (state 1) or x + 4 (state 2), then draw
  DEC HL
  LD D,(HL)
  DEC HL
  LD A,(HL)
  ADD A,$04
  DJNZ MoveHenStepSet
  SUB $08
MoveHenStepSet:
  LD (HL),A
  INC B
  LD E,A
  EX DE,HL
  LD A,B
  CALL DrawHen
  INC DE
  INC DE
  BIT 2,L
  RET Z
  DEC C
  RET NZ
  PUSH HL
  LD HL,(RandomPtr)
  LD A,(HL)
  POP HL
  LD C,$02
  BIT 1,A
  JR Z,MoveHenUp
MoveHenDown:
  PUSH HL                 ; a ladder below: state 3
  LD A,H
  SUB $08
  LD H,A
  CALL MapCellPeek
  POP HL
  DEC A
  JR Z,MoveHenSetDown
  DEC C
  JR NZ,MoveHenUp
  RET
MoveHenSetDown:
  LD A,$03
  LD (DE),A
  RET
MoveHenUp:
  PUSH HL                 ; a ladder above: state 4
  LD A,H
  ADD A,$10
  LD H,A
  CALL MapCellPeek
  POP HL
  DEC A
  JR Z,MoveHenSetUp
  DEC C
  JR NZ,MoveHenDown
  RET
MoveHenSetUp:
  LD A,$04
  LD (DE),A
  RET
MoveHenClimb:
  BIT 2,D
  JR NZ,MoveHenClimbStep
  SUB $02
  LD B,A
  LD A,D
  ADD A,$10
  DJNZ MoveHenClimbTest
  SUB $18
MoveHenClimbTest:
  LD D,A
  EX DE,HL
  CALL MapCellPeek
  EX DE,HL
  DEC A
  JR Z,MoveHenClimbStep
  LD A,$07
  SUB (HL)
  LD (HL),A
MoveHenClimbStep:
  LD B,(HL)               ; y - 4 (state 3) or y + 4 (state 4), then draw
  DEC HL
  LD A,(HL)
  DEC HL
  LD E,(HL)
  ADD A,$04
  DEC B
  DEC B
  DJNZ MoveHenClimbSet
  SUB $08
MoveHenClimbSet:
  INC HL
  LD (HL),A
  LD D,A
  EX DE,HL
  LD A,B
  ADD A,$03
  CALL DrawHen
  BIT 2,H
  RET NZ
  DEC C
  RET NZ
  INC DE
  LD A,H
  SUB $08
  LD H,A
  PUSH HL
  LD HL,(RandomPtr)
  LD A,(HL)
  POP HL
  LD C,$02
  BIT 1,A
  JR Z,MoveHenOffRight
MoveHenOffLeft:
  PUSH HL                 ; a brick to the left: state 1
  LD A,L
  SUB $08
  LD L,A
  CALL MapCellPeek
  POP HL
  CP $05
  JR Z,MoveHenSetLeft
  DEC C
  RET Z
  JR MoveHenOffRight
MoveHenSetLeft:
  LD A,$01
  LD (DE),A
  RET
MoveHenOffRight:
  PUSH HL                 ; a brick to the right: state 2
  LD A,L
  ADD A,$10
  LD L,A
  CALL MapCellPeek
  POP HL
  CP $05
  JR Z,MoveHenSetRight
  DEC C
  RET Z
  JR MoveHenOffLeft
MoveHenSetRight:
  LD A,$02
  LD (DE),A
  RET

; Eat the grain in front of a walking hen
;
; Input: HL the hen's state byte, E its x, D its y. The cell at (x + 8, y) for
; state 2 or (x - 8, y) for state 1 (MapCellAt $9E34): when it is grain (4) the
; cell becomes empty, the state becomes 7 or 8 (pecking) and the peck is drawn
; (8 pixels left for state 7); then it drops its own frame and MoveHen's (three
; POPs) and returns to MainLoop: the hen does not move this turn. Otherwise it
; returns with the registers kept.
;
; Witness: 6 746 calls, 82 meals ($9281); the grain is gone from LiveMap, so
; Harry can no longer take it.
;
; Known only from the code: when the peck's DrawHen finds Harry touching the
; hen, its six POPs are counted for MoveHen's stack, not this one's, so its RET
; takes the BC pushed at $9265 (B the state, C the random bit) as the return
; address. Only a left peck can get here (a right peck is drawn where MoveHen's
; erase has just tested the same box), so B = 1 and the RET goes to ROM $0100
; or $0101. No build reached it. Tried on a clone (work/docs/ceC/heg.py, level
; 8, a hen at (160, 8) walking left, grain at (19, 1), Harry at (152, 23)): the
; PC goes to $0051, the ROM calculator, the RAM fill $11DE-$11ED, and the
; Spectrum resets to the copyright screen at frame 121; with Harry at 153 the
; normal kill and the death tune follow.
HenEatGrain:
  PUSH BC
  PUSH HL
  PUSH DE
  LD A,E
  ADD A,$08
  JR C,HenEatGrainNone
  LD E,A
  LD A,(HL)
  CP $02
  JR Z,HenEatGrainTest
  LD A,E
  SUB $10
  JR C,HenEatGrainNone
  LD E,A
HenEatGrainTest:
  EX DE,HL
  CALL MapCellAt
  CP $04
  JR NZ,HenEatGrainNone
  LD (HL),$00
  LD A,(DE)
  ADD A,$06
  LD (DE),A
  POP HL
  CP $08
  JR Z,HenEatGrainPeck
  LD A,L
  SUB $08
  LD L,A
HenEatGrainPeck:
  LD A,(DE)
  CALL DrawHen
  POP HL
  POP HL
  POP HL
  RET
HenEatGrainNone:
  POP DE
  POP HL
  POP BC
  RET

; Test a hen against Harry, then draw or erase it
;
; Inputs: L the hen's x, H its y, A the frame (0: erase). First the box test
; against Harry: Harry's x within x - 7 .. x + 5 and his y within y + 1 .. y +
; $1C. A touch drops six words from the stack (DrawHen's four, its return and
; MoveHen's) and returns to $A656 in PlayLevel: the life ends ($92BC: c1 1,
; idle-1p 5, gameover-name 5, 11 in all).
;
; A > 0: the frame from HenSprites (see there) is ORed onto the screen, 16
; lines from (x, y) up (ScreenAddr $9404; at x >= $F9 the DEC C at $9309 skips
; both bytes and only the attributes are set, never reached: a hen turns at
; $F8), and a block of attribute 5 (cyan) of 1-2 columns by 2-3 rows is set
; (AttrAddrHen $93DD). A = 0: the 2 x 3 map cells under the hen (1 x 3 at x >=
; $F8) are drawn again from LiveMap with their glyphs and CellAttributes. IX is
; HarryX at the end. Measured in levels-1-3 frames 600-900: a hen read blank by
; the beam in 7 of 44 steps.
;
; Witness: 44 867 calls.
DrawHen:
  PUSH BC
  PUSH DE
  PUSH AF
  PUSH HL
  EX DE,HL
  LD HL,HarryX
  LD A,E
  ADD A,$05
  CP (HL)
  JR C,DrawHenFrame
  SUB $0D
  JR NC,DrawHenTestX
  XOR A
DrawHenTestX:
  CP (HL)
  JR NC,DrawHenFrame
  INC HL
  LD A,D
  CP (HL)
  JR NC,DrawHenFrame
  ADD A,$1C
  CP (HL)
  JR C,DrawHenFrame
  LD B,$06
HenKill:
  POP HL                  ; drop six words: back to $A656 in PlayLevel
  DJNZ HenKill
  RET
DrawHenFrame:
  POP HL
  POP AF
  PUSH AF
  PUSH HL
  AND A
  JP Z,EraseHen
  LD IXH,A
  CP $04
  JR NZ,DrawHenWalkFrame
  DEC A
DrawHenWalkFrame:
  EX DE,HL
  CP $07
  JR NC,DrawHenSprite
  CP $03
  JR NZ,DrawHenStepFrame
  BIT 2,D
  JR Z,DrawHenSprite
  INC A
  JR DrawHenSprite
DrawHenStepFrame:
  BIT 2,E
  JR Z,DrawHenSprite
  ADD A,$04
DrawHenSprite:
  LD B,$00
  LD C,A
  SLA C
  SLA C
  SLA C
  SLA C
  SLA C
  RL B
  LD HL,HenSprites-$0002
  ADD HL,BC
  EX DE,HL
  LD C,$02
  LD A,L
  CP $F9
  JR C,DrawHenScreen
  DEC C
DrawHenScreen:
  CALL ScreenAddr
  LD B,$10
DrawHenLine:
  LD A,(DE)
  DEC C
  JR Z,DrawHenUp
  INC DE
  OR (HL)
  LD (HL),A
  INC HL
  LD A,(DE)
  OR (HL)
  DEC DE
  DEC DE
  DEC DE
  LD (HL),A
  DEC HL
DrawHenUp:
  INC C                   ; one screen line up
  DEC H
  LD A,H
  AND $07
  CP $07
  JR NZ,DrawHenNext
  LD A,H
  ADD A,$08
  LD H,A
  LD A,L
  SUB $20
  LD L,A
  JR NC,DrawHenNext
  LD A,H
  SUB $08
  LD H,A
DrawHenNext:
  DJNZ DrawHenLine
  POP HL
  PUSH HL
  LD D,$02
  LD A,IXH
  CP $07
  JR NC,DrawHenAttrs
  BIT 2,L
  JR NZ,DrawHenAttrs
  DEC D
DrawHenAttrs:
  LD E,$03
  BIT 2,H
  JR NZ,DrawHenAttrAt
  DEC E
DrawHenAttrAt:
  CALL AttrAddrHen
DrawHenAttrRow:
  LD B,D
  PUSH HL
DrawHenAttrCell:
  LD (HL),$05
  INC HL
  DJNZ DrawHenAttrCell
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  DEC E
  JR NZ,DrawHenAttrRow
  POP HL
  POP AF
  POP DE
  POP BC
  RET
EraseHen:
  LD IXL,$02
  LD A,L
  CP $F8
  JR C,EraseHenAt
  DEC IXL
EraseHenAt:
  LD A,H
  AND $F8
  LD H,A
  CALL ScreenAddr
  EX DE,HL
  POP HL
  PUSH HL
  CALL MapCellAddrKeepA
  PUSH HL
  POP BC
  POP HL
  PUSH HL
  CALL AttrAddrHen
  LD IXH,$03
EraseHenRow:
  PUSH IX
  PUSH HL
  PUSH BC
  PUSH DE
EraseHenCell:
  PUSH HL
  LD A,(BC)
  ADD A,$4F
  LD H,$98
  LD L,A
  LD A,(HL)
  POP HL
  LD (HL),A
  PUSH HL
  PUSH BC
  LD A,(BC)
  SLA A
  SLA A
  SLA A
  LD HL,CharacterSet+$0007
  LD B,$00
  LD C,A
  ADD HL,BC
  PUSH DE
  LD B,$08
EraseHenGlyph:
  LD A,(HL)
  LD (DE),A
  DEC D
  DEC HL
  DJNZ EraseHenGlyph
  POP DE
  INC DE
  POP BC
  INC BC
  POP HL
  INC HL
  DEC IXL
  JR NZ,EraseHenCell
  POP DE
  POP BC
  POP HL
  LD A,E
  SUB $20
  LD E,A
  JR NC,EraseHenNextRow
  LD A,D
  SUB $08
  LD D,A
EraseHenNextRow:
  PUSH DE
  LD DE,$0020
  AND A
  SBC HL,DE
  PUSH HL
  PUSH BC
  POP HL
  ADD HL,DE
  PUSH HL
  POP BC
  POP HL
  POP DE
  POP IX
  DEC IXH
  JR NZ,EraseHenRow
  POP HL
  POP AF
  POP DE
  POP BC
  LD IX,HarryX
  RET

; HL = the attribute address of pixel (L, H)
;
; Input: L = x, H = y. Output: HL = $5800 + x / 8 + 32 x ((191 - y) / 8). AF
; and DE kept. Witness: 44 856 calls (DrawHen). The same code is CellAttrAddr
; $9584 (into DE) and SpriteAttrAddr $9BDE.
AttrAddrHen:
  PUSH AF
  PUSH DE
  LD A,$BF
  SUB H
  LD H,$00
  EX DE,HL
  LD HL,Attributes
  SRL E
  SRL E
  SRL E
  ADD HL,DE
  AND $F8
  SLA A
  RL D
  SLA A
  RL D
  LD E,A
  ADD HL,DE
  POP DE
  POP AF
  RET

; HL = the map cell address of (L, H), A kept
;
; MapCellAt $9E34 with AF saved: HL = the cell's address in LiveMap. Witness:
; 22 474 calls (EraseHen).
MapCellAddrKeepA:
  PUSH AF
  CALL MapCellAt
  POP AF
  RET

; HL = the screen address of pixel (L, H)
;
; Input: L = x, H = y (0 at the bottom). Output: HL = the display file byte of
; that pixel row (the third from y / 64, the character row from y AND $38, the
; line from (y AND 7) XOR 7). AF, BC and DE kept. Witness: 44 856 calls
; (DrawHen).
ScreenAddr:
  PUSH AF
  PUSH DE
  PUSH BC
  EX DE,HL
  LD HL,Screen
  LD BC,$0800
  LD A,D
  CP $80
  JR NC,ScreenAddrRow
  CP $40
  JR NC,ScreenAddrMiddle
  ADD HL,BC
ScreenAddrMiddle:
  ADD HL,BC
ScreenAddrRow:
  AND $38
  LD C,A
  LD A,$38
  SUB C
  SLA A
  SLA A
  LD B,$00
  LD C,A
  ADD HL,BC
  LD A,D
  AND $07
  XOR $07
  LD D,A
  SRL E
  SRL E
  SRL E
  ADD HL,DE
  POP BC
  POP DE
  POP AF
  RET

; A = the map cell at (L, H), HL kept
;
; MapCellAt $9E34 with HL saved. Witness: 19 822 calls (MoveHen's floor and
; ladder tests).
MapCellPeek:
  PUSH HL
  CALL MapCellAt
  POP HL
  RET

; Leftover: copies of code bytes from an earlier assembly
;
; Never read (L1: no access). F1 C9 E5 CD 34 9E E1 C9 is the end of ScreenAddr
; and MapCellPeek ($9436-$943D), the rest the middle of ScreenAddr
; ($940C-$9421), shifted by an earlier layout.
LeftoverCode943E:
  DEFB $F1,$C9,$E5,$CD,$34,$9E,$E1,$C9,$00,$08,$7A,$FE,$80,$30,$06,$FE
  DEFB $40,$30,$01,$09,$09,$E6,$38,$4F,$3E,$38,$91,$CB,$27

; The hens of levels 1-8: a count, then up to five hen records
;
; SetupLevel $AE9C reads the row at $945B + 21 x ((Level AND 7) + 1), so row 0
; here ($945B) is never read: level 1's row is $9470. The first byte is the
; number of bytes to copy into Hens (8 on level 1, 12 on 2-3, 16 on 4-6, 12 on
; 7-8: two to four hens), then the records (x, y, state, spare). Levels 9-16
; copy none, 17-24 the table again, 25 and up all 20 bytes (five hens). The
; editable form is src/res/tables/HenTable.csv.
;
; Witness: SetupLevel's copy at $AFA4: 35 levels in the eight builds.
HenTable:
  INCBIN "res/tables/HenTable.bin",$0000,189

; 32 zeros
;
; Never read (L1: no access).
Zeros9518:
  DEFS $20
