; --------------------------------------------------------------------------------------------------------------------
; intromain.asm: the intro: logo, robot, AY bars and the scroller over the tune
;
; ZS's own code, after the compiled tune: IntroMain at $D88F, CALLed by the REM loader (src/basic98/basic.asm,
; RemLoader $5D84) once the block is in; it returns there when a key is pressed and the loader reads the game. r98:
; entered at frame 2048, returned at frame 4331 (the key at 4203).
;
; The screen it builds: the title text left by the REM loader faded out by a diagonal sweep (AttrWipe), the screen
; cleared (ClearScreen), the ZS logo in the top middle (8 x 8 attribute cells at column 12, row 0, LogoMask) whose
; paper colour changes every frame (LogoColour), a one-line scroller on row 11 (ScrollStep, from the interrupt; the
; text ScrollText, the font IntroFont or the ROM's), three AY volume bars in the bottom left corner (AyBars: columns
; 0-2, rows 22-23, red / yellow / green), three coloured cells on row 9 that follow AY registers 2, 4 and 6
; (IntroLoop), and the robot in its yellow box at column 13, row 16 (RobotFrame every 32 frames: a four-frame
; animation). The interrupt (IM 2 through the table IntroMain builds at $8100, IntroInterrupt) plays the tune and
; moves the scroller, then goes on to the ROM's IM 1 handler (FRAMES and the keyboard).
; --------------------------------------------------------------------------------------------------------------------

; the intro: set up, the frame loop until a key, then IntroEnd
;
; Entered from the REM loader with interrupts on, IM 1, the 48 K BASIC ROM
; paged and page 0 at $C000. Sets up the player (Pt3Init), the IM 2 table and
; vector, pages $7FFD = $10, fades the loader's title out (AttrWipe), clears
; the screen (ClearScreen), colours the bottom third and the bars' cells, then
; loops once a frame (IntroLoop) until LAST_K ($5C08) is not 0 (the ROM's
; handler, run from IntroInterrupt, sets it when a key is pressed). Then
; IntroEnd. Out: interrupts on, IM 0 (behaves as IM 1 here), the AY silent, the
; attributes black. Uses AF BC DE HL; the IM 2 table at $8080-$8200 is left in
; memory (the game load overwrites it).
IntroMain:
  DI
  CALL Pt3Init            ; the player set up: the module's pointers, the AY
                          ; silent (Pt3Init leaves interrupts off)
  LD HL,$8100             ; the IM 2 table: $8100-$8200, 257 bytes of $80 ...
  LD DE,$8101
  LD (HL),$80
  LD BC,$0100
  LDIR
  LD A,$C3                ; ... so every vector is $8080, where a JP
                          ; IntroInterrupt goes
  LD ($8080),A
  LD BC,IntroInterrupt
  LD ($8081),BC
  LD A,$10                ; $7FFD = $10: page 0 at $C000, the 48 K BASIC ROM,
                          ; screen 5 (the loader's own state)
  LD BC,$7FFD
  OUT (C),A
  LD A,$81                ; I = $81: the table above; IM 2 on
  LD I,A
  IM 2
  EI
  CALL AttrWipe           ; the loader's title text faded out (128 frames)
  CALL ClearScreen        ; then the screen cleared, white on black, border
                          ; black
  LD HL,$5A00             ; the bottom third's attributes ($5A00-$5AFF): yellow
                          ; ink on black (the robot's box, RobotHeader's
                          ; colour)
  LD B,$00
BottomAttrLoop:
  LD (HL),$06
  INC HL
  DJNZ BottomAttrLoop
  LD A,$02                ; the bars' cells, rows 23 and 22: column 0 red
                          ; (channel A) ...
  LD ($5AE0),A
  LD ($5AC0),A
  LD A,$06                ; ... column 1 yellow (B) ...
  LD ($5AE1),A
  LD ($5AC1),A
  LD A,$04                ; ... column 2 green (C)
  LD ($5AE2),A
  LD ($5AC2),A
  XOR A                   ; LAST_K = 0: the loop runs until the ROM's keyboard
                          ; scan stores a key
  LD ($5C08),A
IntroLoop:
  LD A,($5C08)            ; a frame of the intro
  OR A
  JR NZ,IntroEnd
  HALT                    ; wait for the frame (the interrupt has played the
                          ; tune and moved the scroller)
  LD BC,$FFFD             ; AY register 2 (channel B's tone, low byte) ...
  LD A,$02
  OUT (C),A
  IN A,(C)
  AND $1F                 ; ... its low 5 bits pick a cell of row 9
                          ; ($5920-$593F): paper red
  OR $20
  LD H,$59
  LD L,A
  LD (HL),$10
  PUSH HL                 ; the cell's address kept to clear it at the end of
                          ; the frame
  LD BC,$FFFD             ; AY register 4 (channel C's tone, low byte): a cell
                          ; of row 9 in yellow
  LD A,$04
  OUT (C),A
  IN A,(C)
  AND $1F
  OR $20
  LD H,$59
  LD L,A
  LD (HL),$30
  PUSH HL
  LD BC,$FFFD             ; AY register 6 (the noise period): a cell of row 9
                          ; in green
  LD A,$06
  OUT (C),A
  IN A,(C)
  AND $1F
  OR $20
  LD H,$59
  LD L,A
  LD (HL),$20
  PUSH HL
  CALL AyBars             ; the bars, three times ...
  CALL AyBars
  CALL AyBars
  LD A,($5C78)            ; every 32 frames (FRAMES' low byte & $1F = 0) the
                          ; robot's next frame
  AND $1F
  CALL Z,RobotFrame
  CALL AyBars             ; the bars again ...
  LD A,($5C78)            ; the logo in the colour FRAMES & 7
  AND $07
  CALL LogoColour
  CALL AyBars             ; ... and once more
  POP HL                  ; the three cells of row 9 back to black: they show
                          ; only while this frame is drawn
  LD (HL),$00
  POP HL
  LD (HL),$00
  POP HL
  LD (HL),$00
  JR IntroLoop
IntroEnd:
  DI                      ; I = $3F (the ROM's value), IM 0: the bus reads $FF,
                          ; so the interrupt is RST $38 as under IM 1
  LD A,$3F
  LD I,A
  IM 0
  CALL Pt3StopEntry       ; the AY silent
  EI
  CALL AttrWipe           ; the screen faded out by the same diagonal sweep
                          ; (128 frames)
  RET

; the ZS logo's cells in paper colour A (0-7)
;
; A = the colour (IntroLoop passes FRAMES & 7, so it changes every frame and
; goes black every eighth). Writes the attribute A * 8 (paper A, ink 0) to
; every cell of the 8 x 8 block at column 12, row 0 ($580C) whose byte in
; LogoMask is not 0; the other cells are left as they are. The colour goes into
; the LD (HL),n below (self-modified). Entered 2008 times (frames 2180-4203).
; Uses AF BC DE HL.
LogoColour:
  LD HL,$580C
  RLA                     ; A * 8: the paper colour ...
  RLA
  RLA
  LD (LogoInk+$0001),A    ; ... into LogoInk's operand
  LD DE,LogoMask          ; the logo's 64 mask bytes, 8 rows of 8 cells
  LD C,$08
LogoRow:
  LD B,$08
LogoCell:
  LD A,(DE)
  OR A
  JR Z,LogoNextCell
LogoInk:
  LD (HL),$00             ; the cell's attribute (operand: the colour * 8)
LogoNextCell:
  INC HL
  INC DE
  DJNZ LogoCell
  LD B,$18                ; to the next row: 24 cells on
LogoRowSkip:
  INC HL
  DJNZ LogoRowSkip
  DEC C
  JR NZ,LogoRow
  RET

; the scroller: one pixel further, a new glyph column at the right
;
; From IntroInterrupt every frame (2155 times, frames 2049-4203). ScrollPtr's
; operand is the text pointer, ScrollColumn's the column counter (0-7, one up a
; frame). On counter 0 the byte at the pointer is taken and the pointer moves
; on: $00 ends the text (the pointer = the word after it: ScrollTextLoop) and
; $01 LO HI switches the font (ScrollFont's operand = HI LO), both giving a
; space; on 1-7 the byte at the pointer is used without moving. The byte's
; glyph is ScrollFont - 256 + code * 8 (codes below $20: ScrollFont itself, a
; space), and one pixel column of it, chosen by the counter (counter 2-7:
; columns 0-5, counter 0: column 6, counter 1: column 7 of the byte after: the
; pointer has moved on; no glyph of either font has a pixel in column 7), is
; ORed into the right-hand byte of row 11 ($487F) on its 8 lines. Then the 8
; lines of row 11 ($4860-$487F) shift left one pixel. Uses AF BC DE HL.
ScrollStep:
  LD HL,ScrollText        ; the text pointer (operand), ScrollText at first
  LD A,($D9CE)            ; the counter + 1, mod 8
  INC A
  AND $07
  LD (ScrollColumn+$0001),A
  LD A,(HL)               ; counter not 0: the byte at the pointer, the pointer
                          ; stays
  JR NZ,ScrollFont
  LD A,(HL)               ; counter 0: the next byte, the pointer moves on
  INC HL
  OR A
  JR NZ,ScrollFontCode
  LD A,(HL)               ; $00: the text ends, the pointer from the word after
                          ; it (ScrollTextLoop)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,$20                ; ... and a space this time
  JR ScrollKeep
ScrollFontCode:
  CP $01                  ; $01 LO HI: the font from here on
  JR NZ,ScrollKeep
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (ScrollFont+$0001),BC
  LD A,$20                ; ... and a space this time
ScrollKeep:
  LD (ScrollStep+$0001),HL ; the pointer kept
ScrollFont:
  LD HL,IntroFont         ; the font (operand): IntroFont, or $3D00 (the ROM's)
                          ; after a switch
  CP $20                  ; below $20: the font's address as it is (the space)
  JR C,ScrollGlyph
  DEC H                   ; font - 256 + code * 8
  LD C,A
  LD B,$00
  RL C
  RL B
  RL C
  RL B
  RL C
  RL B
  ADD HL,BC
ScrollGlyph:
  LD DE,$487F             ; DE = the scroller's right-hand byte on row 11's
                          ; first line
  EX DE,HL
  LD C,$08
ScrollColumn:
  LD A,$00                ; the column counter (operand, 0-7)
  OR $08                  ; B = counter + 8: the byte rotated left counter - 1
                          ; times (mod 8), bit 0 taken
  LD B,A
  LD A,(DE)
ScrollBitRotate:
  RLCA
  DJNZ ScrollBitRotate
  RRCA
  AND $01
  OR (HL)                 ; ORed into the screen byte
  LD (HL),A
  INC H                   ; the next pixel line (INC H)
  INC DE
  DEC C
  JR NZ,ScrollColumn
  LD HL,$487F             ; the 8 lines of row 11 shifted left one pixel, right
                          ; to left
  LD C,$08
ScrollShiftLine:
  PUSH HL
  XOR A                   ; no carry into the right-hand byte
  LD B,$20
ScrollShiftByte:
  RL (HL)
  DEC HL
  DJNZ ScrollShiftByte
  POP HL
  INC H
  DEC C
  JR NZ,ScrollShiftLine
  RET

; the three AY volume bars
;
; AyBar for register 8 (channel A's volume) at column 0, 9 (B) at column 1, 10
; (C) at column 2, each from the bottom line of row 23 up. IntroLoop calls it
; five times a frame (10040 entries in 2008 frames). Uses AF BC DE HL.
AyBars:
  LD A,$08
  LD HL,$57E0
  CALL AyBar
  LD A,$09
  LD HL,$57E1
  CALL AyBar
  LD A,$0A
  LD HL,$57E2
  CALL AyBar
  RET

; the IM 2 handler: a frame of the tune and of the scroller, then the ROM's
;
; Reached through the vector $8080 (a JP here) on every interrupt from
; IntroMain's IM 2 on (2155 times, frames 2048-4202). Saves every register (AF'
; too: the player uses it), CALLs Pt3PlayEntry and ScrollStep, restores them
; and jumps to $0038, the 48 K ROM's IM 1 handler: FRAMES + 1 and the keyboard
; scan into LAST_K, then EI and RET.
IntroInterrupt:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  EX AF,AF'
  PUSH AF
  CALL Pt3PlayEntry
  CALL ScrollStep
  POP AF
  EX AF,AF'
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  JP $0038                ; the ROM's handler does the EI / RET

; one volume bar: AY register A, its column from HL up
;
; A = the AY register (8-10: the channel volumes), HL = the bar's bottom byte
; ($57E0 + column). Reads the register; its low 4 bits v (the envelope bit
; dropped) are the bar's height in pixel lines: v lines of $7E from the bottom
; up, then 15 - v lines of 0 above them; past the top line of row 23 ($50xx) it
; goes on at the bottom line of row 22 ($57C0 + column). Entered 30120 times.
; Uses AF BC E HL.
AyBar:
  LD BC,$FFFD
  OUT (C),A               ; register select, read back
  IN A,(C)
  LD E,L                  ; E = the column
  AND $0F                 ; C = 15 - v: the clear lines ...
  XOR $0F
  LD C,A
  XOR $0F                 ; ... B = v: the bar's lines
  LD B,A
  JR Z,AyBarClear
AyBarUp:
  LD A,H                  ; a line of the bar
  CP $50
  JR NC,AyBarPut
  LD A,E                  ; above row 23: on at the bottom line of row 22
  AND $0F
  OR $C0
  LD L,A
  LD H,$57
AyBarPut:
  LD (HL),$7E             ; the bar's pattern
  DEC H
  DJNZ AyBarUp
AyBarClear:
  LD A,C                  ; the rest up to 15 lines cleared
  OR A
  RET Z
  LD B,C
AyBarClearLine:
  LD A,H
  CP $50
  JR NC,AyBarClearPut
  LD A,E
  AND $0F
  OR $C0
  LD L,A
  LD H,$57
AyBarClearPut:
  LD (HL),$00
  DEC H
  DJNZ AyBarClearLine
  RET

; the screen cleared: white on black, the border black
;
; ATTR_P ($5C8D) = 7, BORDER 0 (ROM $229B with A = 0), CLS (ROM $0D6B), channel
; 2 (the upper screen) opened (ROM $1601). The same steps as the REM loader's
; start. Entered once (frame 2176). Uses all.
ClearScreen:
  LD A,$07
  LD ($5C8D),A
  XOR A
  CALL $229B
  CALL $0D6B
  LD A,$02
  CALL $1601
  RET

; the diagonal fade: 128 frames of AttrDiagonal
;
; E from $F8 to $77: AttrDiagonal(E), then HALT. Each frame the band of eight
; diagonals moves one cell right: whatever the attributes held is overwritten,
; first white ink (the band's front, $47) then darker inks down to black ($40),
; so the screen's contents fade out from left to right; at the end every cell
; is $40 (bright, black on black). Run twice: on IntroMain's start (frames
; 2048-2176, over the REM loader's title) and in IntroEnd (frames 4203-4331,
; over the intro). Uses AF BC DE HL.
AttrWipe:
  LD E,$F8
AttrWipeFrame:
  CALL AttrDiagonal
  HALT
  INC E
  LD A,E
  CP $78
  JR NZ,AttrWipeFrame
  RET

; the band of 8 attribute diagonals at column E of row 0
;
; For each row D = 0-23, eight cells leftwards from column E - D: the
; attributes $47, $46 ... $40 (bright, ink 7 down to 0, black paper), through
; AttrCell (cells off the screen skipped). Keeps DE and AF; uses BC HL.
AttrDiagonal:
  PUSH DE
  PUSH AF
  LD D,$00
AttrDiagonalRow:
  PUSH DE
  LD A,$47
AttrDiagonalCell:
  CALL AttrCell
  DEC E
  DEC A
  CP $3F
  JR NZ,AttrDiagonalCell
  POP DE
  DEC E
  INC D
  LD A,D
  CP $18
  JR NZ,AttrDiagonalRow
  POP AF
  POP DE
  RET

; attribute A at row D, column E (if on the screen)
;
; D = the row, E = the column, A = the attribute; nothing when E >= 32 or D >=
; 24. HL = $5800 + D * 32 + E. Keeps AF DE.
AttrCell:
  EX AF,AF'
  LD A,E
  CP $20
  JR NC,AttrCellOff
  LD A,D
  CP $18
  JR NC,AttrCellOff
  PUSH HL
  LD HL,$5800
  SRL D
  RR L
  SRL D
  RR L
  SRL D
  RR L
  ADD HL,DE
  LD D,A
  EX AF,AF'
  LD (HL),A
  POP HL
  RET
AttrCellOff:
  EX AF,AF'               ; off the screen
  RET
