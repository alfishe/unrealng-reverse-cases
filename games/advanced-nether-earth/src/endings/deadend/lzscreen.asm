; --------------------------------------------------------------------------------------------------------------------
; lzscreen.asm: the Dead End picture and its depacker
;
; LzScreen unpacks a screen packed by the authors' own LZ (tools/endings_lz.py has the format and the packer) into
; $4000. It is position-independent: CALL RomRet leaves its own address (LzHere) under SP, and it writes the address
; of LzPutByte over the operands of its three CALLs; the image holds them as the authors assembled them
; (LzPutByteOrg). The stream follows the routine (LzHere + $BE). The game menu's picture routine (menupicture.asm) is
; a byte-identical copy.
;
; The bytes come in the order of character cells: down the 8 pixel lines of a cell, the next cell down a column of a
; third, the next column, the next third; then the 768 attributes. A back reference counts in that order: the copy
; turns the sequence address (DE) back into a screen address before it reads. Tokens: 0LLLLHHH + a byte, a match
; (length 3-18, distance up to 2047); 11NNNNNN + a byte, a run (3-66); 10NNNNNN + bytes, literals (1-63); $80 the end.
; --------------------------------------------------------------------------------------------------------------------

; unpack the LZ screen that follows this routine into the screen
;
; Uses both register sets: DE the sequence address (from $4000), HL the stream;
; the second set writes: HL' the screen address, B' the lines left in a cell,
; C' the cells left in a column, A' the column count of a third (it carries out
; after 32 columns; Z after the third third: the attributes). Enables
; interrupts (the picture builds while the tune plays). Returns with HL' =
; RomHlAlt.
LzScreen:
  EI
  CALL RomRet             ; a RET in the ROM: the return address, LzHere, stays
                          ; just under SP
LzHere:
  DEC SP                  ; SP back onto it: BC = LzHere
  DEC SP
  POP BC
  LD HL,LzPutByte-LzHere  ; DE = LzPutByte
  ADD HL,BC
  EX DE,HL
  LD HL,LzMatchCall+1-LzHere     ; over the three CALL operands
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,LzLiteralCall+1-LzHere
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,LzRunCall+1-LzHere
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,DeadEndPicture-LzHere ; HL = the stream (LzHere + $BE)
  ADD HL,BC
  LD DE,$4000             ; the sequence address and the screen address both
                          ; start at $4000
  PUSH DE
  EXX
  EX AF,AF'
  LD A,$03                ; A' = 3 with Z clear, B' = C' = 8
  OR A
  LD B,$08
  LD C,B
  POP HL
  EX AF,AF'
  EXX
LzToken:
  LD A,(HL)               ; the next token: bit 7 clear, a match
  BIT 7,A
  JR NZ,LzNotMatch
  AND $07                 ; C = the distance's high bits
  LD C,A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,$03
  LD B,A                  ; B = the length (3-18)
  INC HL
  LD A,E                  ; HL = DE - distance: the source's sequence address
  SUB (HL)
  INC HL
  PUSH HL
  LD L,A
  LD A,D
  SBC A,C
  LD H,A
LzMatchByte:
  PUSH HL                 ; the sequence address to a screen address
                          ; (attributes stay as they are)
  LD A,H
  AND $58
  CP $58
  JR Z,LzMatchRead
  LD C,A
  LD A,L
  AND $07
  OR C
  LD C,A
  ADD HL,HL
  ADD HL,HL
  LD A,H
  AND $1F
  LD H,A
  LD A,L
  AND $E0
  OR H
  LD L,A
  LD H,C
LzMatchRead:
  LD A,(HL)               ; the byte from the screen
LzMatchCall:
  CALL LzPutByteOrg       ; (CALL LzPutByte)
  POP HL
  INC HL
  DJNZ LzMatchByte
  POP HL
  JR LzToken
LzNotMatch:
  AND $7F                 ; bit 7 set: the end, literals or a run
  JR Z,LzEnd
  INC HL
  BIT 6,A
  JR NZ,LzRun
  LD B,A
LzLiteralByte:
  LD A,(HL)
LzLiteralCall:
  CALL LzPutByteOrg       ; (CALL LzPutByte)
  INC HL
  DJNZ LzLiteralByte
  JR LzToken
LzRun:
  AND $3F                 ; a run: the byte 3-66 times
  ADD A,$03
  LD B,A
  LD A,(HL)
LzRunCall:
  CALL LzPutByteOrg       ; (CALL LzPutByte)
  DJNZ LzRunCall
  INC HL
  JR LzToken
LzEnd:
  EXX                     ; $80: HL' as the ROM needs it
  LD HL,RomHlAlt
  EXX
  EI
  RET

; the byte A to the screen in the depacker's order
;
; DE (the sequence address) counts on; in the second set HL' gets the byte and
; moves on: down the cell's lines, down the column of cells, along the columns,
; across the thirds, then the attributes one by one.
LzPutByte:
  INC DE
  EXX
  LD (HL),A
  EX AF,AF'
  JR Z,LzPutAttr          ; Z (A' after the last third): an attribute, the next
                          ; one
  INC H                   ; the next pixel line of the cell
  DJNZ LzPutDone
  LD DE,-$07E0            ; 8 lines done: back 8 lines and down one character
                          ; row
  ADD HL,DE
  DEC C                   ; 8 cells done: back to the third's top, one column
                          ; right
  JR NZ,LzPutLines
  LD DE,-$00FF
  ADD HL,DE
  ADD A,$08               ; a column more: 32 carry out
  JR NC,LzPutCells
  LD DE,$07E0             ; the next third (Z after the third one)
  ADD HL,DE
  DEC A
  JR LzPutCells
LzPutAttr:
  INC HL                  ; an attribute: the next one
LzPutCells:
  LD C,$08                ; a new column: 8 cells
LzPutLines:
  LD B,$08                ; a new cell: 8 lines
LzPutDone:
  EX AF,AF'
  EXX
  RET

; the Dead End picture (screen LZ, 3266 bytes)
DeadEndPicture:
  INCBIN "res/pictures/dead-end.lz",$0000,3266
