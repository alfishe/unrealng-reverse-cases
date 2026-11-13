; --------------------------------------------------------------------------------------------------------------------
; control.asm: The script's control codes below 32
;
; ControlCode gets the code in A and ScriptPtr past it. Codes $0C (CLS), $0E (REPEAT n) and $1D (TABFILL n) print
; FillChar one cell a step and repeat themselves (LoadFlags bit 2) until done. The others go through ControlTable
; $BB92: the handler gets A = the next script byte and DE = the address after it, and stores DE in ScriptPtr only when
; it takes that byte as an argument. A table code first waits 20 x 14 T.
;
; The codes (work/ann/04-loader.md has the decoded script): $03 n pause n hooks; $05 c FillChar = c; $08 left; $09
; right; $0A down; $0B up; $0C clear the window; $0D to the window's left on the next row; $0E n print FillChar n
; times; $0F row col rows cols a picture of rows x cols cells; $10 n INK; $11 n PAPER; $12 n FLASH; $13 n BRIGHT; $16
; row col AT inside the window; $18 swap INK and PAPER; $19 c and 8 bytes a new glyph for c; $1A left right top bottom
; the window; $1D n fill to column n; $1E n BORDER. $00-$02, $04 (the end, never dispatched), $06, $07, $14, $15, $17,
; $1B, $1C and $1F do nothing and take no argument. The INK to BRIGHT and AT codes are the ROM's numbers (16-19, 22).
; --------------------------------------------------------------------------------------------------------------------

; A control code: $0C, $0E and $1D here, the others through ControlTable
;
; Called by ScriptStep with A = the code and the script pointer HL (the other
; register set) past it, in ScriptPtr as well.
;
; TABFILL `$1D` n (`$B8FF`): the target column is n - 1, at most WindowRight.
; Until PrintColumn is the target, FillChar is printed and the code repeats
; (the pointer goes back to it); at the target, one more and n is taken: the
; print position ends at column n (through the next row when it was past it).
;
; REPEAT `$0E` n (`$B914`): RepeatCount = n the first time (LoadFlags bit 2),
; then one FillChar a step, n in all (0: 256).
;
; CLS `$0C` (`$B938`): the first time, the print position to the window's top
; left; then FillChar a step until the position is back there, then bit 2 off
; and a wait of 20 x 14 T. The window is filled with spaces, a cell a step (the
; script's 4677 `$0C` steps in c1).
;
; A repeating step goes back one byte (ControlAgain `$B96B`), stores ScriptPtr,
; drops ScriptStep's return and prints FillChar through PrintChar.
;
; The table: the handler from ControlTable + 2 x A, A = the byte at ScriptPtr,
; DE = ScriptPtr + 1, `JP (HL)`; it returns to ScriptStep.
;
; Witness: L1 5843 (c1).
ControlCode:
  CP $0C
  JR Z,CodeCls
  CP $0E
  JR Z,CodeRepeat
  CP $1D
  JR Z,CodeTabFill
  LD H,$14                ; a table code: a wait of 20 x 14 T first
ControlDelay:
  DEC H
  JP NZ,ControlDelay
  ADD A,A                 ; the handler, A = the next byte, DE = past it
  LD L,A
  LD DE,ControlTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,(ScriptPtr)
  LD A,(HL)
  INC HL
  EX DE,HL
  JP (HL)
CodeTabFill:
  LD A,(HL)               ; $1D n: fill to column n
  DEC A
  LD DE,(WindowRight)
  INC E
  CP E
  JR C,TabFillTest
  DEC E
  LD A,E
TabFillTest:
  LD DE,(PrintColumn)
  CP E
  JR NZ,ControlAgain
  JR ControlTake
CodeRepeat:
  LD A,(LoadFlags)            ; $0E n: FillChar n times
  BIT 2,A
  JR NZ,RepeatStep
  SET 2,A
  LD (LoadFlags),A
  LD A,(HL)
  LD (RepeatCount),A
RepeatStep:
  LD A,(RepeatCount)
  DEC A
  LD (RepeatCount),A
  JR NZ,ControlAgain
  LD A,(LoadFlags)
  RES 2,A
  LD (LoadFlags),A
ControlTake:
  INC HL                  ; take the argument, print once more
  JR ControlFill
CodeCls:
  LD A,(LoadFlags)            ; $0C: clear the window with FillChar, a cell a step
  BIT 2,A
  JR NZ,ClsStep
  SET 2,A
  LD (LoadFlags),A
  LD A,(WindowLeft)
  LD (PrintColumn),A
  LD DE,(WindowTop)
  LD (PrintRow),DE
  JR ControlAgain
ClsStep:
  LD A,(PrintColumn)
  LD DE,(WindowLeft)
  CP E
  JR NZ,ControlAgain
  EX DE,HL
  LD HL,(PrintRow)
  LD BC,(WindowTop)
  SBC HL,BC
  EX DE,HL
  JR Z,ClsDone
ControlAgain:
  DEC HL                  ; the pointer back to the code: it runs again next
                          ; step
ControlFill:
  LD (ScriptPtr),HL           ; print FillChar instead of returning to ScriptStep
  POP HL
  LD A,(FillChar)
  JP PrintChar
ClsDone:
  LD HL,LoadFlags
  RES 2,(HL)
  LD H,$14
ClsDelay:
  DEC H
  JP NZ,ClsDelay
  RET

; $03 n: wait n hooks before the next item (ScriptWait = n), ending this hook's
; steps
;
; Takes n, drops ScriptStep's return, EXX and HookPad: no more items this hook.
; HookWork steps again in the n-th hook from now. The script waits 23 times
; (c1), 50 to 250 hooks (about 2.5 to 12 s).
;
; Witness: L1 23 (c1).
CodePause:
  LD (ScriptWait),A
  LD (ScriptPtr),DE
  POP HL
  EXX
  JP HookPad

; $08: the print position one column left; before WindowLeft, WindowRight of
; the row above
;
; No argument. Falls into CodeUp for the row.
;
; Witness: L1 0 ().
CodeLeft:
  LD HL,PrintColumn
  DEC (HL)
  LD A,(WindowLeft)
  DEC A
  CP (HL)
  RET M
  LD A,(WindowRight)
  LD (HL),A

; $0B: the print position one row up; above WindowTop, WindowBottom
;
; No argument. Not used by Deflektor's script.
;
; Witness: L1 0 ().
CodeUp:
  LD HL,(PrintRow)
  LD BC,-32
  ADD HL,BC
  LD (PrintRow),HL
  LD BC,(WindowTop)
  AND A
  SBC HL,BC
  RET NC
  LD HL,(WindowBottom)
  LD (PrintRow),HL
  RET

; $09: the print position one column right (CursorRight)
;
; No argument; drops ScriptStep's return and goes on at CursorRight `$B7CA`, so
; the step ends with ScriptPair as after a character.
;
; Witness: L1 0 ().
CodeRight:
  POP HL
  JP CursorRight

; $0D: the print position to WindowLeft on the next row
;
; No argument. PrintColumn = WindowLeft, then CodeDown's NextRow. 86 times in
; c1.
;
; Witness: L1 86 (c1).
CodeReturn:
  LD A,(WindowLeft)
  LD (PrintColumn),A

; $0A: the print position one row down (NextRow), the column kept
;
; No argument.
;
; Witness: L1 86 (c1).
CodeDown:
  POP HL
  JP NextRow

; $19 c b1-b8: the 8 bytes of character c's glyph (32 or more) copied into the
; font
;
; Below 32 it returns at once and takes nothing (the next byte is read as an
; item). Else 8 bytes from the script to FontPtr + 8 x (c - 32); ScriptPtr past
; them. Not used by Deflektor's script (its glyphs are the fourth load).
;
; Witness: L1 0 ().
CodeGlyph:
  SUB $20
  RET C
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,(FontPtr)
  ADD HL,BC
  LD BC,$0008
  EX DE,HL
  LDIR
  LD (ScriptPtr),HL
  RET

; $1E n: the border = n AND 7 (MIC set)
;
; Not used by Deflektor's script.
;
; Witness: L1 0 ().
CodeBorder:
  LD (ScriptPtr),DE
  AND $07
  OR $08
  LD BC,$00FE
  OUT (C),A
  RET

; $11 n: PrintAttr's paper = n (bits 3-5)
;
; Witness: L1 1 (c1).
CodePaper:
  RLCA
  RLCA
  RLCA
  LD C,$38
  JR SetAttrBits

; $10 n: PrintAttr's ink = n (bits 0-2)
;
; Witness: L1 33 (c1).
CodeInk:
  LD C,$07
  JR SetAttrBits

; $12 n: PrintAttr's FLASH bit = bit 0 of n
;
; Not used by Deflektor's script.
;
; Witness: L1 0 ().
CodeFlash:
  LD C,$80
  JR AttrFlag

; $13 n: PrintAttr's BRIGHT bit = bit 0 of n
;
; Not used by Deflektor's script. AttrFlag `$B9FA` (also CodeFlash's): A =
; `$FF` or 0 from bit 0 of n.
;
; Witness: L1 0 ().
CodeBright:
  LD C,$40
; This entry point is used by the routine at CodeFlash.
AttrFlag:
  RRA
  SBC A,A

; PrintAttr = (A AND C) OR (PrintAttr AND NOT C); take the argument
;
; C is the mask: `$07` ink, `$38` paper, `$80` flash, `$40` bright.
; IgnoreCode28 `$BA09` (its `RET`) is the table's handler of `$1C`.
;
; Witness: L1 34 (c1).
SetAttrBits:
  LD HL,(AttrPair)
  XOR H
  AND C
  XOR H
  LD (PrintAttr),A
  LD (ScriptPtr),DE
IgnoreCode28:
  RET                     ; RET: the handler of $1C (does nothing)

; $18: swap PrintAttr's ink and paper (FLASH and BRIGHT kept)
;
; No argument. Not used by Deflektor's script.
;
; Witness: L1 0 ().
CodeSwap:
  LD A,(PrintAttr)
  LD L,A
  RRCA
  RRCA
  RRCA
  LD H,A
  RRCA
  RRCA
  XOR H
  AND $38
  XOR H
  XOR L
  AND $3F
  XOR L
  LD (PrintAttr),A
  RET

; $16 row col: the print position inside the window (WindowLeft + col,
; WindowTop + 32 x row), clamped to it
;
; The column: WindowLeft + col, at most WindowRight (also on a carry). The row:
; WindowTop + 32 x row, at most WindowBottom. 24 times in c1.
;
; Witness: L1 24 (c1).
CodeAt:
  LD L,A
  LD A,(DE)
  INC DE
  LD (ScriptPtr),DE
  LD DE,(WindowLeft)
  ADD A,E
  JR C,AtRight
  INC D
  CP D
  JR C,AtColumn
  DEC D
AtRight:
  LD A,D
AtColumn:
  LD (PrintColumn),A
  CALL Times32
  LD DE,(WindowTop)
  ADD HL,DE
  JR C,AtBottom
  EX DE,HL
  LD HL,(WindowBottom)
  SBC HL,DE
  EX DE,HL
  JR NC,AtRow
AtBottom:
  LD HL,(WindowBottom)
AtRow:
  LD (PrintRow),HL
  RET

; HL = 32 x L (H = 0): a row's offset in the attributes
;
; Called by CodeAt, CodeWindow and CodePicture.
;
; Witness: L1 45 (c1).
Times32:
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  RET

; $05 c: FillChar = c (the character CLS, REPEAT and TABFILL print)
;
; Not used by Deflektor's script: FillChar stays a space.
;
; Witness: L1 0 ().
CodeFill:
  LD (ScriptPtr),DE
  LD (FillChar),A
  RET

; $1A left right top bottom: the script's window; the print position to its top
; left
;
; The columns sorted; a right column of 32 or more makes the window 0-31. The
; rows sorted; a bottom row of 24 or more makes it 0-23. WindowLeft,
; WindowRight; WindowTop and WindowBottom as attribute addresses of column 0
; (`$5800` + 32 x row); PrintRow = WindowTop, PrintColumn = WindowLeft.
;
; Deflektor's script: `$1A` 1 30 10 20 (the text panel under the picture), and
; 0 31 0 21 before the last picture.
;
; Witness: L1 2 (c1).
CodeWindow:
  LD L,A
  LD A,(DE)
  INC DE
  CP L
  JR NC,WindowCols
  LD H,A
  LD A,L
  LD L,H
WindowCols:
  LD H,A                  ; the columns in order (H the right, L the left)
  CP $20
  JR C,WindowSetCols
  LD HL,$1F00
WindowSetCols:
  LD (WindowLeft),HL           ; WindowLeft, WindowRight
  LD A,L
  LD (PrintColumn),A
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  INC DE
  LD (ScriptPtr),DE
  LD E,A
  CP L
  JR NC,WindowRows
  EX DE,HL
  LD A,E
WindowRows:
  CP $18                  ; the rows: past 23, the full height
  JR C,WindowSetRows
  LD E,$17
  LD L,$00
WindowSetRows:
  CALL Times32            ; WindowTop
  LD A,H
  ADD A,$58
  LD H,A
  LD (WindowTop),HL
  LD (PrintRow),HL
  EX DE,HL
  CALL Times32
  LD A,H
  ADD A,$58
  LD H,A
  LD (WindowBottom),HL
  RET

; $0F row col rows cols: draw a picture of rows x cols cells from the script,
; one cell a step
;
; The cells' screen place is absolute (not the window's): PictureAt = `$5800` +
; 32 x row + col, PictureRows = rows, PictureWidth = cols, RepeatCount = 0 (the
; column), LoadFlags bit 3: ScriptStep then calls PictureCell for every item
; until the picture is done. 17 pictures in Deflektor's script (the frame of 9
; x 32 cells first).
;
; Witness: L1 17 (c1).
CodePicture:
  LD L,A
  CALL Times32
  LD A,(DE)
  INC DE
  LD C,A
  LD B,$58
  ADD HL,BC
  LD (PictureAt),HL
  EX DE,HL
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD (ScriptPtr),HL
  LD (PictureWidth),DE
  XOR A
  LD (RepeatCount),A
  LD HL,LoadFlags
  SET 3,(HL)
  RET
