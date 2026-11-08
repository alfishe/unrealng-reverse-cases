; --------------------------------------------------------------------------------------------------------------------
; check.asm: The Lenslok check: the size screen, the scrambled code, the answer
;
; Entered from the kickoff with CALL $C213 after the two ROM blocks; it returns only when the code is typed right,
; after at most two rounds of three attempts, and resets the machine otherwise. The kickoff then copies the game's
; $C800-$CFFF over this page.
;
; The picture is drawn with the ROM's PLOT ($22DF), the text with RST $10 on channel 2. All numbers are integers: the
; width the player sets on the size screen is divided by 11 into the scale at LensTable, and each slice of the picture
; is a range of tenths of the scale (docs/lenslok.md 3, 4).
; --------------------------------------------------------------------------------------------------------------------

; Zeros up to the code (the page the kickoff later fills with the game)
LensUnused:
  DEFS $0213

; The Lenslok check: rounds of a size screen and three attempts; returns on
; success, resets after two failed rounds
;
; IX = LensTable for the whole check, IY = ERR_NR for the ROM. Opens channel 2
; and clears the screen, runs LensRound, and tests LensPassed bit 0 with RR A /
; JR C. The JR C at $C22E is the byte ELITE48.TAP makes a JR (docs/lenslok.md
; 7).
;
; On failure it prints "WRONG - TRY AGAIN", waits 65536 loops, counts
; LensRounds down and starts again; LensRounds is never set again, so the
; second failure reaches RST 0. c1 passes in the first round: LensPassed = 1 at
; frame 16075.
Lenslok:
  LD IX,LensTable
  LD IY,$5C3A
  LD A,$02
  CALL $1601
  CALL $0D6B
  CALL LensRound
  CALL AtRow20
  LD A,(LensPassed)
  RR A
LensPassedTest:
  JR C,LensDone           ; JR C: the only test of the result (ELITE48.TAP
                          ; writes $18 here)
  CALL PrintInline

; "  WRONG - TRY AGAIN   ", for PrintInline
WrongText:
  DEFM "  WRONG - TRY AGAIN   ",$5E

; After a failed round: wait 65536 loops, count LensRounds down, start again or
; reset
LensFailedRound:
  LD HL,$0000
LensDelay:
  DEC HL
  LD A,H
  OR L
  JR NZ,LensDelay
  LD A,(LensRounds)
  DEC A
  LD (LensRounds),A
  JR NZ,Lenslok
LensReset:
  RST $00                 ; RST 0: two failed rounds
; This entry point is used by the routine at Lenslok.
LensDone:
  RET

; One round: the size screen, the scale, then up to three attempts; LensPassed
; = 1 or 0
;
; Runs SizeScreen with BORDCR = $23 (lower screen white on magenta), divides
; the width it returns by 11 into the scale (IX+0), widens the outer slices
; (LensEdgesWiden) and turns caps lock on (FLAGS2 bit 3) so letters arrive in
; upper case.
;
; Each attempt: LensClear, Bracket, the seed from R read twice into LensSeed
; ($C297-$C29D; bit 7 of R is 1 since the decryptor's LD R,$FF), SetMarks,
; PickCode, DrawCode, AskCode. LensAttempts starts at 4 and is counted down
; before each attempt: three attempts.
LensRound:
  CALL LensClear
  LD A,$23
  LD ($5C09),A
  CALL SizeScreen
  LD C,A
  LD B,$00
  LD DE,$000B
  CALL LensDiv
  LD (IX+$00),C
  CALL SetMarks
  CALL LensEdgesWiden
  XOR A
  LD ($5C09),A
  LD HL,$5C6A
  SET 3,(HL)
  LD A,$04
  LD (LensAttempts),A
LensAttempt:
  LD A,(LensAttempts)
  DEC A
  LD (LensAttempts),A
  JR Z,LensFailed
  CALL LensClear
  CALL Bracket
LensSeedRead:
  LD A,R                  ; LD A,R twice: the seed of the generator
  LD H,A
  LD A,R
  LD L,A
  LD (LensSeed),HL
LensChallenge:
  CALL SetMarks           ; SetMarks, PickCode, DrawCode: the challenge from
                          ; the seed (tools/lenslok_sim.py runs $C2A0-$C2A8)
  CALL PickCode
  CALL DrawCode
LensAsk:
  CALL AskCode
  JR C,LensAttempt
  LD A,$01
  LD (LensPassed),A
  JR LensRoundEnd
LensFailed:
  XOR A
  LD (LensPassed),A
LensRoundEnd:
  RET

; Clear the screen's pixels ($4000-$57FF), leaving the attributes
;
; Byte by byte, 6144 bytes with a 16-bit count: 18 432 instructions a call in
; c1.
LensClear:
  LD HL,$4000
  LD DE,$1800
LensClearLoop:
  XOR A
  LD (HL),A
  DEC DE
  INC HL
  LD A,D
  OR E
  RET Z
  JR LensClearLoop

; Draw the centre line and the 8 rows of the scrambled code in LensCode
;
; The centre line: PlotColumn from (128, 88) and (127, 88), 2 x 2 points. Then
; for each of the 8 rows (B = 8 down to 1, C = 8): GlyphRow (the row of both
; characters into RowBits), Scramble (the 14 slots), DrawRow (the slices). c1
; draws "si" at frames 15866-15891.
DrawCode:
  LD BC,$5880
  LD A,B
  PUSH AF
  PUSH BC
  CALL PlotColumn
  POP BC
  POP AF
  DEC C
  CALL PlotColumn
  LD BC,$0808
DrawCodeRow:
  PUSH BC
  CALL GlyphRow
  CALL Scramble
  POP DE
  PUSH DE
  CALL DrawRow
  POP BC
  DJNZ DrawCodeRow
  RET

; Plot A points to the right from (x C, y B) with the ROM's PLOT
;
; A horizontal run: C is incremented after each point. Used for the bracket's
; bar and, through FillBlock, the slices.
PlotRow:
  PUSH AF
  PUSH BC
  CALL $22DF
  POP BC
  INC C
  POP AF
  DEC A
  JR NZ,PlotRow
  RET

; Plot A points upwards from (x C, y B) with the ROM's PLOT
;
; A vertical run: B is incremented after each point. The bracket's posts and
; the centre line.
PlotColumn:
  PUSH AF
  PUSH BC
  CALL $22DF
  POP BC
  INC B
  POP AF
  DEC A
  JR NZ,PlotColumn
  RET

; Draw one row of the scrambled code: 14 slices from SlotBits, each a block of
; lines
;
; D, E = the row's band (from DrawCode's B, C): the band's height in pixels is
; 20 x scale / 100 (LensRowHeight), its bottom row 120 minus its offset. Copies
; SlotBits to RowBits and walks the 14 slots: for each, PermIndex reads the
; slice's two edges from LensEdges (signed tenths), SliceSpan scales them, and
; when the slot's bit (shifted out of RowBits) is 1, FillBlock fills the slice
; for the band.
;
; The edges are scaled one by one with the remainder dropped, which leaves the
; dark gaps between some slices (docs/lenslok.md 4.4).
DrawRow:
  LD A,E
  SUB D
  LD E,A
  INC E
  PUSH DE
  LD C,$14
  LD E,(IX+$00)
  XOR A
  LD B,A
  LD D,A
  CALL LensMul
  LD E,$64
  CALL LensDiv
  LD A,C
  LD (LensRowHeight),A
  POP DE
  LD D,$00
  CALL LensMul
  LD A,$78
  SUB C
  LD D,A
  PUSH DE
  LD HL,SlotBits
  LD DE,RowBits
  LD BC,$0003
  LDIR
  LD B,$0E
  LD A,$01
  LD (PermIndex+$0002),A
  POP DE
DrawRowSlice:
  PUSH BC
  PUSH DE
  CALL PermIndex
  LD D,A
  CALL PermIndex
  LD E,A
  BIT 7,D
  JR Z,DrawRowRight
  LD A,E
  NEG
  LD E,A
  LD A,D
  NEG
  LD D,A
  SUB E
  CALL SliceSpan
  POP DE
  SUB C
  LD E,A
  JR DrawRowBit
DrawRowRight:
  LD A,E
  SUB D
  CALL SliceSpan
  POP DE
  ADD A,C
  LD E,A
DrawRowBit:
  PUSH DE
  LD A,$01
  LD HL,RowBits+$0002
  CALL ShiftLeft3
  POP DE
  PUSH DE
  CALL C,FillBlock
  POP DE
  POP BC
  DJNZ DrawRowSlice
  RET

; A = (IX + n), n the displacement at $C376, then n + 1
;
; A self-modifying table reader: DrawRow sets the displacement to 1
; (LensEdges), Scramble to $1D (LensPerm), and each call reads the next byte.
PermIndex:
  LD A,(IX+$00)
  LD HL,PermIndex+$0002
  INC (HL)
  RET

; The two mark bytes: Rand(128) with bit 0 cleared, into LensMark1 and
; LensMark2
;
; The marks fill the two outer slots of each row (Scramble shifts one bit of
; each out per row). In c1 with the seed $FE81: $32 and $62.
SetMarks:
  LD A,$80
  CALL Rand
  RES 0,A
  LD (LensMark1),A
  LD A,$80
  CALL Rand
  RES 0,A
  LD (LensMark2),A
  RET

; Widen the outer slices: edges 1 and 2 from edge 3 (minus 5), edges 27 and 28
; from edge 26 (plus 5)
;
; Run once a round after the scale is set.
LensEdgesWiden:
  LD B,$05
  LD A,(IX+$03)
  LD (IX+$02),A
  SUB B
  LD (IX+$01),A
  LD A,(IX+$1A)
  LD (IX+$1B),A
  ADD A,B
  LD (IX+$1C),A
  RET

; Print position: AT 20,2 (the prompt line)
;
; Used by the routines at Lenslok, SizeScreen and AskCode.
AtRow20:
  LD B,$14
  LD C,$02
  JR AtPrint

; Print position: AT B,5
;
; Used by the routines at SizeScreenText and BlankLine.
AtColumn5:
  LD C,$05
; This entry point is used by the routine at AtRow20.
AtPrint:
  LD A,$16
  RST $10
  LD A,B
  RST $10
  LD A,C
  RST $10
  RET

; Scale a slice's edges: LensSliceStart = (A x scale) / 10, BC = (D x scale) /
; 10; A = $80
;
; Used by the routine at DrawRow.
SliceSpan:
  PUSH DE
  LD C,A
  LD E,(IX+$00)
  XOR A
  LD B,A
  LD D,A
  CALL LensMul
  LD E,$0A
  CALL LensDiv
  LD (LensSliceStart),BC
  POP DE
  LD C,D
  LD E,(IX+$00)
  XOR A
  LD D,A
  LD B,A
  CALL LensMul
  LD E,$0A
  CALL LensDiv
  LD A,$80
  RET

; Fill one slice of one row: LensRowHeight horizontal runs of the slice's
; width, one row up each time
;
; Used by the routine at DrawRow.
FillBlock:
  LD A,(LensRowHeight)
  LD B,A
FillBlockLoop:
  PUSH BC
  PUSH DE
  LD A,(LensSliceStart)
  LD B,D
  LD C,E
  CALL PlotRow
  POP DE
  DEC D
  POP BC
  DJNZ FillBlockLoop
  RET

; BC = BC x DE by repeated addition (BC = 0 when DE = 0)
;
; Used by the routines at DrawRow, SliceSpan and AskCodeWait.
LensMul:
  LD A,D
  OR E
  JR NZ,LensMulStart
  LD BC,$0000
  RET
LensMulStart:
  LD H,B
  LD L,C
LensMulLoop:
  DEC DE
  LD A,D
  OR E
  JR Z,LensMulDone
  ADD HL,BC
  JR LensMulLoop
LensMulDone:
  LD B,H
  LD C,L
  RET

; BC = BC / DE by repeated subtraction (the remainder dropped)
;
; Used by the routines at LensRound, DrawRow, SliceSpan and SizeScreenText.
LensDiv:
  LD H,B
  LD L,C
  LD BC,$0000
LensDivLoop:
  INC BC
  SBC HL,DE
  JR NC,LensDivLoop
  DEC BC
  RET

; The size screen: the bracket, the test code "OK", keys 5 / 8 change the
; width, ENTER returns it in A
;
; LensWidth starts at $90 (144). Each pass clears the screen, prints the two
; hint lines, sets the scale (width / 11), draws "OK" with ShowOK and the
; bracket (OVER 1), and waits for a key: "5" narrows by 2, "8" widens by 2
; (never below $50), ENTER ($0D) returns. c1 presses ENTER at frame 15866 with
; the width 144 unchanged.
SizeScreen:
  LD A,$90
  LD (LensWidth),A
; This entry point is used by the routine at SizeScreenText.
SizeScreenDraw:
  CALL LensClear
  CALL AtRow20
  CALL PrintInline

; "<(5) DECREASE - INCREASE (8)>", for PrintInline
SizeHintText:
  DEFM "<(5) DECREASE - INCREASE (8)>",$5E

; The size screen, continued after its hint line: the bracket, "OK" and the
; keys
SizeScreenText:
  LD B,$15
  CALL AtColumn5
  CALL PressEnterText
  LD A,$78
  LD (LensBarY),A
  SUB $14
  LD (LensPostY),A
  CALL OverOn
  LD A,(LensWidth)
  LD C,A
  LD B,$00
  LD DE,$000B
  CALL LensDiv
  LD (IX+$00),C
  CALL ShowOK
  LD A,(LensWidth)
  LD B,A
  LD A,$FF
  SUB B
  RRA
  LD (LensBracketX),A
  CALL Bracket
SizeScreenKey:
  CALL WaitKey
  PUSH AF
  LD A,(LensWidth)
  LD B,A
  POP AF
  CP $35
  JR NZ,SizeScreenWider
  DEC B
  DEC B
  JR SizeScreenSet
SizeScreenWider:
  CP $38
  JR NZ,SizeScreenEnter
  INC B
  INC B
SizeScreenSet:
  LD A,B
  LD (LensWidthNew),A
  CP $50
  JR NC,SizeScreenStore
  LD A,$50
SizeScreenStore:
  LD (LensWidth),A
  JP SizeScreenDraw
SizeScreenEnter:
  CP $0D
  JR NZ,SizeScreenKey
  CALL OverOff
  LD B,$14
  CALL BlankLine
  INC B
  CALL BlankLine
  LD A,(LensWidth)
  RET

; Print 24 spaces at AT B,5
;
; Used by the routine at SizeScreenText.
BlankLine:
  CALL AtColumn5
  CALL PrintInline

; 24 spaces, for PrintInline
SpacesText:
  DEFM "                        ",$5E

; The return after the spaces
BlankLineEnd:
  RET

; Draw the bracket: two posts of 40 points and the bar between them at row 120
;
; The posts stand at x = LensBracketX - 1 and LensBracketX + LensWidth from y =
; LensPostY (100); the bar runs LensWidth points at y = LensBarY (120). The
; player sets the lens on the posts.
Bracket:
  LD A,(LensPostY)
  LD B,A
  LD A,(LensBracketX)
  LD C,A
  LD A,$28
  DEC C
  CALL PlotColumn
  LD A,(LensBarY)
  LD B,A
  LD A,(LensBracketX)
  LD C,A
  LD A,(LensWidth)
  CALL PlotRow
  LD A,(LensPostY)
  LD B,A
  LD A,(LensBracketX)
  LD C,A
  LD A,(LensWidth)
  ADD A,C
  LD C,A
  LD A,$28
  CALL PlotColumn
  RET

; Put "OK" into LensCode and draw it (the size screen's test code)
;
; Before the first attempt LensCode still holds "OK", which keeps O and K out
; of the first code (PickCode).
ShowOK:
  LD HL,LensCode
  LD (HL),$4F
  INC HL
  LD (HL),$4B
  CALL DrawCode
  RET

; OVER 1 (P_FLAG bit 1), so the bracket can be drawn and wiped by plotting
; twice
;
; Used by the routine at SizeScreenText.
OverOn:
  LD HL,$5C91
  SET 1,(HL)
  RET

; OVER 0 (P_FLAG bits 0 and 1)
;
; Used by the routine at SizeScreenText.
OverOff:
  LD HL,$5C91
  RES 1,(HL)
  RES 0,(HL)
  RET

; Z if A is in LensExcluded (up to "^"); A kept
;
; Used by the routine at PickChar.
IsExcluded:
  PUSH HL
  PUSH BC
  LD HL,LensExcluded
  LD B,A
IsExcludedLoop:
  LD A,(HL)
  INC HL
  CP $5E
  JR Z,IsExcludedNo
  CP B
  JR Z,IsExcludedYes
  JR IsExcludedLoop
IsExcludedNo:
  AND A
IsExcludedYes:
  LD A,B
  POP BC
  POP HL
  RET

; Print "PRESS ENTER WHEN READY"
;
; Used by the routine at SizeScreenText.
PressEnterText:
  CALL PrintInline

; "PRESS ENTER WHEN READY ", for PrintInline
PressEnterString:
  DEFM "PRESS ENTER WHEN READY ",$5E

; The return after the string
PressEnterEnd:
  RET

; One character: a digit, an upper- and a lower-case candidate, then one of
; them by Rand(3)
;
; Each candidate is drawn again while IsExcluded finds it: Rand(9) + "0",
; Rand(25) + "A", Rand(25) + "a" into LensCandidates; then Rand(B) + 1 picks
; the candidate (docs/lenslok.md 4.2, worked for the seed $FE81).
PickChar:
  LD A,$07
  LD B,$00
  LD HL,LensCandidates
  BIT 0,A
  PUSH AF
  JR Z,PickCharUpper
PickDigit:
  LD A,$09
  CALL Rand
  ADD A,$30
  CALL IsExcluded
  JR Z,PickDigit
  LD (HL),A
  INC B
  INC HL
PickCharUpper:
  POP AF
  BIT 1,A
  PUSH AF
  JR Z,PickCharLower
PickUpper:
  LD A,$19
  CALL Rand
  ADD A,$41
  CALL IsExcluded
  JR Z,PickUpper
  LD (HL),A
  INC HL
  INC B
PickCharLower:
  POP AF
  BIT 2,A
  JR Z,PickNth
PickLower:
  LD A,$19
  CALL Rand
  ADD A,$61
  CALL IsExcluded
  JR Z,PickLower
  LD (HL),A
  INC B
PickNth:
  LD A,B
  CALL Rand
  INC A
  LD HL,LensTimeout+$0001
  LD B,A
PickNthLoop:
  INC HL
  DJNZ PickNthLoop
  LD A,(HL)
  RET

; One row's 14 slots: mark 1's bit, the 12 glyph columns in LensPerm order,
; mark 2's bit, into SlotBits
;
; For slot k (1-12) it finds the column c with LensPerm[c] = k and copies
; column c's bit of RowCopy into SlotBits. The marks are shifted right one bit
; a row, so each row gets the next bit of each mark.
Scramble:
  LD A,(LensMark1)
  RR A
  LD (LensMark1),A
  CALL SlotShift1
  LD B,$01
ScrambleSlot:
  PUSH BC
  LD BC,$0003
  LD HL,RowBits
  LD DE,RowCopy
  LDIR
  LD A,$1D
  LD (PermIndex+$0002),A
  POP BC
  PUSH BC
  LD C,$01
ScrambleFind:
  CALL PermIndex
  CP B
  JR Z,ScrambleCopy
  INC C
  JR ScrambleFind
ScrambleCopy:
  LD A,C
  LD HL,RowCopy+$0002
  CALL ShiftLeft3
  CALL SlotShift1
  POP BC
  INC B
  LD A,$0D
  CP B
  JR NZ,ScrambleSlot
  LD A,(LensMark2)
  RR A
  LD (LensMark2),A
  CALL SlotShift1
  LD A,$0A
  LD HL,SlotBits+$0002
  CALL ShiftLeft3
  RET

; Shift SlotBits ($C796-$C798) left by one bit
;
; Used by the routine at Scramble.
SlotShift1:
  LD A,$01
  LD HL,SlotBits+$0002
  CALL ShiftLeft3
  RET

; Shift the 3 bytes ending at HL left by A bits (carry in from the previous
; instruction's flags)
;
; Used by the routines at DrawRow, Scramble and SlotShift1.
ShiftLeft3:
  LD B,A
ShiftLeft3Bit:
  LD C,B
  PUSH BC
  PUSH HL
  LD B,$03
ShiftLeft3Byte:
  RL (HL)
  PUSH AF
  DEC HL
  POP AF
  DJNZ ShiftLeft3Byte
  POP HL
  POP BC
  LD B,C
  DJNZ ShiftLeft3Bit
  RET

; "ENTER CODE:", then up to two keys or a timeout of 600 frames; NC when they
; match LensCode
;
; Waits with HALT, LensTimeout = 12 x 50 frames, for keys from the ROM's
; interrupt scan (FLAGS bit 5, LAST_K), echoes each with RST $10 and stores it
; in LensTyped. A timeout returns C (a wrong answer). CheckCode then compares
; each typed key with the code, and again plus $20, so the case does not
; matter. With the interrupts off (the fast-load trap,
; docs/03-build-and-load.md 3.9) no key arrives and the HALT never returns.
AskCode:
  XOR A
  LD (LensTemp),A
  LD HL,LensTyped
  LD (LensTypedPtr),HL
  CALL AtRow20
  CALL PrintInline

; "ENTER CODE:", for PrintInline
EnterCodeText:
  DEFM "ENTER CODE:",$5E

; AskCode, continued after its prompt: 600 frames for two keys
AskCodeWait:
  LD C,$0C
  LD E,$32
  XOR A
  LD B,A
  LD D,A
  CALL LensMul
  LD (LensTimeout),BC
AskCodeFrame:
  HALT
  LD BC,(LensTimeout)
  DEC BC
  LD (LensTimeout),BC
  LD A,B
  OR C
  JR Z,AskCodeTimeout
  CALL KeyReady
  JR Z,AskCodeFrame
AskCodeKey:
  RES 5,(HL)
  LD A,($5C08)
  PUSH AF
  RST $10
  POP AF
  LD HL,(LensTypedPtr)
  LD (HL),A
  INC HL
  LD (LensTypedPtr),HL
  LD A,(LensTemp)
  INC A
  LD (LensTemp),A
  CP $02
  JR Z,CheckCode
  JR AskCodeFrame
AskCodeTimeout:
  SCF
  RET
CheckCode:
  LD HL,LensCode          ; compare LensTyped with LensCode: NC right, C wrong
  LD DE,LensTyped
  LD B,$02
CheckNext:
  LD A,(DE)
  INC DE
  CP (HL)
  JR Z,CheckOK
  ADD A,$20
  CP (HL)
  JR NZ,CheckBad
CheckOK:
  INC HL
  DJNZ CheckNext
  AND A
  RET
CheckBad:
  SCF
  RET

; Wait for a key from the ROM's scan (FLAGS bit 5), clear the flag and return
; LAST_K in A
;
; The size screen's key loop: 123 342 calls of KeyReady in c1 while the size
; screen waits for ENTER.
WaitKey:
  CALL KeyReady
  JR Z,WaitKey
  RES 5,(HL)
  LD A,($5C08)
  RET

; NZ when FLAGS bit 5 says a new key is in LAST_K
;
; Used by the routines at AskCodeWait and WaitKey.
KeyReady:
  LD HL,$5C3B
  BIT 5,(HL)
  RET

; The generator: low byte of LensSeed + $31, returned mod A
;
; One byte of state: each call adds 49 and returns the new value mod A by
; repeated subtraction. The seed's high byte is set to 0 by the first call.
Rand:
  PUSH HL
  PUSH BC
  LD HL,(LensSeed)
  LD DE,$0031
  ADD HL,DE
  LD H,$00
  LD (LensSeed),HL
  LD B,A
  LD A,L
  CCF
RandMod:
  SUB B
  JR NC,RandMod
  ADD A,B
  POP BC
  POP HL
  RET

; Two new characters into LensCode, none in LensPrevious or already in
; LensCode; then LensPrevious = LensCode
;
; Before the first attempt LensCode holds "OK" (ShowOK), afterwards the code
; shown before.
PickCode:
  LD C,$02
  LD B,C
  LD HL,LensCode
PickCodeChar:
  PUSH HL
  PUSH BC
PickCodeRetry:
  CALL PickChar
  POP BC
  PUSH BC
  LD HL,LensPrevious
  CALL InList
  JR C,PickCodeRetry
  POP BC
  PUSH BC
  LD HL,LensCode
  CALL InList
  JR C,PickCodeRetry
  POP BC
  POP HL
  LD (HL),A
  INC HL
  DJNZ PickCodeChar
  LD HL,LensCode
  LD DE,LensPrevious
  LD BC,$0004
  LDIR
  RET

; C (carry) if A is one of the B bytes at HL; A kept
;
; Used by the routine at PickCode.
InList:
  LD B,C
  LD C,A
InListLoop:
  LD A,(HL)
  INC HL
  CP C
  JR Z,InListYes
  DJNZ InListLoop
  AND A
  JR InListDone
InListYes:
  CCF
InListDone:
  LD A,C
  RET

; Row C - B of both characters of LensCode: GlyphGather, then 6 columns of each
; into RowBits
;
; The two font bytes (shifted right once, so the glyph's columns 1-6 fill the
; six slots of a half) are shifted bit by bit into the 24-bit RowBits.
GlyphRow:
  CALL GlyphGather
  CALL ClearRowBits
  LD DE,$0002
  LD B,E
  LD HL,LensGlyphs
  DEC E
  ADD HL,DE
GlyphRowChar:
  LD A,(HL)
  SRA A
  DEC HL
  PUSH HL
  PUSH BC
  CALL ShiftInRow
  POP BC
  POP HL
  DJNZ GlyphRowChar
  RET

; Shift the 6 low bits of A into RowBits ($C790-$C792), one bit at a time
;
; Used by the routine at GlyphRow.
ShiftInRow:
  LD HL,RowBits
  LD B,$06
ShiftInRowBit:
  RR A
  PUSH AF
  PUSH BC
  LD B,$03
  PUSH HL
ShiftInRowByte:
  RR (HL)
  PUSH AF
  INC HL
  POP AF
  DJNZ ShiftInRowByte
  POP HL
  POP BC
  POP AF
  DJNZ ShiftInRowBit
  RET

; Zero the 4 bytes at RowBits
;
; Used by the routine at GlyphRow.
ClearRowBits:
  LD B,$04
  LD HL,RowBits
ClearRowBitsLoop:
  XOR A
  LD (HL),A
  INC HL
  DJNZ ClearRowBitsLoop
  RET

; Print the string after the CALL up to "^" with RST $10, then continue after
; it
;
; Used by the routines at Lenslok, SizeScreen, BlankLine, PressEnterText and
; AskCode.
PrintInline:
  POP HL
PrintInlineLoop:
  LD A,(HL)
  INC HL
  CP $5E
  JR Z,PrintInlineEnd
  RST $10
  JR PrintInlineLoop
PrintInlineEnd:
  PUSH HL
  RET

; Row r of the characters at LensCode onwards from the ROM font into
; LensGlyphs: B = 8 - r bytes
;
; r = C - B (stored in LensTemp); the font is CHARS + 256. The loop count is
; the row loop's B, so row r copies 8 - r bytes where 4 were meant: past the
; code and the previous code they run over the first four bytes of
; LensExcluded. Their last values are font bytes of the codes drawn last, which
; changes the excluded set from attempt to attempt; on row 7 only one byte is
; copied, so the second character's row 7 repeats its row 6 ("Sg" and "Sq" draw
; the same pixels). docs/lenslok.md 4.4 and 5.
GlyphGather:
  PUSH BC
  LD A,C
  SUB B
  LD HL,($5C36)
  INC H
  LD DE,LensCode
  LD (LensTemp),A
  PUSH HL
  LD HL,LensGlyphs
  LD (LensGatherPtr),HL
  POP HL
  POP BC
GlyphGatherLoop:
  PUSH BC
  LD A,(DE)
  INC DE
  SUB $20
  LD C,A
  LD B,$00
  RL C
  RL B
  RL C
  RL B
  RL C
  RL B
  PUSH HL
  ADD HL,BC
  LD A,(LensTemp)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  LD HL,(LensGatherPtr)
  LD (HL),A
  INC HL
  LD (LensGatherPtr),HL
  POP HL
  POP BC
  DJNZ GlyphGatherLoop
  RET

; The Lenslok's variables and its table
LensVars:
  DEFB $00,$00
LensBarY:
  DEFB $00                ; the bracket's bar: row 120
LensPostY:
  DEFB $00                ; the posts' bottom: row 100
LensSpare:
  DEFB $00
LensTemp:
  DEFB $00                ; AskCode's key count; GlyphGather's row
LensBracketX:
  DEFB $00                ; the left post: (255 - LensWidth) / 2
LensWidthNew:
  DEFB $00                ; the width the keys asked for, before the minimum
                          ; (written only)
LensRowHeight:
  DEFB $00                ; a band's height in pixels: 20 x scale / 100
LensWidth:
  DEFB $00                ; the bracket's width, $90 at the start; 5 / 8 change
                          ; it by 2, never below $50
LensAttempts:
  DEFB $00                ; 4, counted down before each attempt
LensMark1:
  DEFB $00                ; the left mark, shifted out one bit a row
LensMark2:
  DEFB $00                ; the right mark
LensPassed:
  DEFB $00                ; 1 when the code was right: the check's only result
LensSliceStart:
  DEFB $00,$00            ; SliceSpan's scaled start (word)
LensSeed:
  DEFB $E8,$03            ; the generator: R read twice at the start of an
                          ; attempt; only the low byte is stepped
LensTypedPtr:
  DEFB $E8,$03            ; where AskCode stores the next key
LensGatherPtr:
  DEFB $00,$00            ; where GlyphGather stores the next font byte
LensRounds:
  DEFB $02                ; 2 rounds, never reset
LensTimeout:
  DEFB $00,$00            ; AskCode's frame count (word)
LensCandidates:
  DEFB $00,$00            ; PickChar's three candidates
  DEFB $00
RowBits:
  DEFB $00,$00            ; the 12 bits of a glyph row (3 bytes), and the slot
  DEFB $00                ; bits DrawRow shifts out
RowCopy:
  DEFB $00,$00            ; RowBits copied before the scramble
  DEFB $00
SlotBits:
  DEFB $00,$00            ; the 14 scrambled bits
  DEFB $00
LensCode:
  DEFB $00,$00            ; the code: 2 characters and two zeros ("OK" on the
  DEFB $00,$00            ; size screen)
LensPrevious:
  DEFB $00,$00            ; the code shown before
  DEFB $00,$00
LensTyped:
  DEFB $00,$00            ; the 2 keys typed
  DEFB $00,$00
LensGlyphs:
  DEFB $00,$00            ; GlyphGather's 4 font bytes, which run on into
  DEFB $00,$00            ; LensExcluded
LensExcluded:
  DEFB $54,$4C            ; "TLWMIYfmwtzl^": the characters kept out of a code
  DEFB $57,$4D            ; (the first four overwritten from the first drawing
  DEFB $49,$59            ; on)
  DEFB $66,$6D
  DEFB $77,$74
  DEFB $7A,$6C
  DEFB $5E
LensTable:
  DEFB $0D                ; IX: the scale, the 28 slice edges, the permutation
LensEdges:
  DEFB $D3,$D8            ; 14 slices, each two signed edges in tenths of the
  DEFB $D8,$E3            ; scale from the centre line
  DEFB $E3,$EA
  DEFB $EB,$F0
  DEFB $F1,$F5
  DEFB $F6,$F9
  DEFB $F9,$FE
  DEFB $02,$07
  DEFB $08,$0C
  DEFB $0C,$11
  DEFB $11,$16
  DEFB $16,$1E
  DEFB $1E,$26
  DEFB $26,$2B
LensPerm:
  DEFB $03,$02            ; the slot each of the 12 glyph columns goes to
  DEFB $01,$07
  DEFB $04,$05
  DEFB $0A,$06
  DEFB $08,$09
  DEFB $0C,$0B
LensTail:
  DEFB $00,$00            ; zeros to the end of the page
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00
