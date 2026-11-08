; --------------------------------------------------------------------------------------------------------------------
; text.asm: The character printers, the string interpreter, the screen helpers
; --------------------------------------------------------------------------------------------------------------------

; Print one 8x8 glyph at a character cell, set its attribute and its three cell
; maps
;
; A the glyph code, D the row (0-23), E the column, C the attribute. Returns at
; once when bit 5 of E is set (a column 32-63 or a negative one from $E0 up:
; the screen layouts place objects from off the left edge, ScreenLayouts). The
; glyph is 8 bytes at GlyphBase + 8A, where GlyphBase is the operand of the LD
; BC at $ADEE (PrintString code $E6 and the callers write it: FontBase $D7E0,
; the tile sets from $DAB8 on). The 8 bytes go down the cell's pixel lines (INC
; D), then C to the cell's attribute.
;
; Then the cell's entries of two maps parallel to the attributes: attribute +
; $0900 = the cell type map at $6100 gets the operand at $AE1B (PrintString
; code $E8 n; the screen builder sets 1 at $84FA, the score and text printers
; leave what was set), attribute + $0900 + $FA00 = the empty-cell map at $5B00
; gets the operand at $AE21 (0 = a glyph is here, PrintString $E9; $FF = empty,
; $EA). The sprite drawers read $5B00 ($777F, $79DD), the collision code $6100
; ($80D3).
;
; Plot mode 0 of PlotModes $9A0F (set by SetPlotMode $99F8 into the four CALLs
; of PrintString). Called also directly: the define keys ($6FE1), the HUD
; ($917C, $9181), the name entry ($A0E2, $A125), the round end ($A837, $A84F),
; the bonus screen ($A91A, $A92C), $ABB5. c1: 158 963 calls from PrintString's
; $AF32 alone.
PrintChar:
  BIT 5,E
  RET NZ
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,$0000             ; BC = GlyphBase: the operand ($ADEF) is written by
                          ; PrintString $E6, $E7 and the callers ($715D, $8E1F,
                          ; $8F95, $9152, $A2D5, $A8DB, $AB9F, $AC2B, $B0C8)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
PrintCharLine:
  LD A,(HL)               ; 8 pixel lines down the cell
  LD (DE),A
  INC D
  INC HL
  DJNZ PrintCharLine
  DEC D                   ; back to the cell's last line: its attribute address
                          ; from H
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  POP BC
  LD (HL),C
  LD DE,$0900
  ADD HL,DE
  LD (HL),$00             ; the cell type map ($6100 + cell): the operand at
                          ; $AE1B, PrintString $E8 n
  LD DE,OpenCells-CellTypes ; DE = $FA00 (-$0600): from the $6100 map to the
                            ; $5B00 map
  ADD HL,DE
  LD (HL),$00             ; the empty-cell map ($5B00 + cell): the operand at
                          ; $AE21, 0 ($E9) or $FF ($EA)
  POP HL
  POP DE
  POP AF
  RET

; Print one glyph and its attribute, no clipping and no cell maps
;
; As PrintChar without the column test and the map writes: A the code, D the
; row, E the column, C the attribute, the glyph from GlyphBase ($ADEF). Plot
; mode 1 of PlotModes. Used for the HUD's numbers (PrintNumber3 $B0E0), $7578,
; $8E49, $8E77, the score glyphs $8F7E/$8F83 (163 849 calls each in the runs),
; $A300.
PrintCharAttr:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(PrintChar+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
PrintCharAttrLine:
  LD A,(HL)               ; 8 pixel lines
  LD (DE),A
  INC D
  INC HL
  DJNZ PrintCharAttrLine
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  POP BC
  LD (HL),C
  POP HL
  POP DE
  POP AF
  RET

; XOR one glyph onto a cell and set its attribute
;
; A the code, D the row, E the column, C the attribute, the glyph from
; GlyphBase. The glyph is XORed onto the screen (drawn twice it is gone). Plot
; mode 2 of PlotModes. Called from $8FC0-$9009 (AnimateTurrets, 8 sites, 3580
; and 14 208 calls each in the runs), with GlyphBase $DDD8 set at $8F95.
XorCharAttr:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(PrintChar+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
XorCharAttrLine:
  LD A,(DE)               ; XOR 8 pixel lines
  XOR (HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ XorCharAttrLine
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  POP BC
  LD (HL),C
  POP HL
  POP DE
  POP AF
  RET

; XOR a glyph off a cell, mark the cell empty and throw two debris particles
;
; A the code, D the row, E the column (clipped as in PrintChar: bit 5 of E set
; returns). The glyph is XORed onto the screen, which takes off the same glyph
; drawn there before; the attribute is left. Then the cell's maps: $5B00 = $FF
; (empty), $5E00 (the attribute copy CopyAttributes $8E11 made after the screen
; was built) = 0, $6100 (the cell type) = 0: the cell is no longer solid. At
; the end two calls of $94F9 (one CALL, one JP) with DE = the row and column:
; each starts a debris particle there (a 6-byte record of the list at $95B6, a
; random direction from $AD36, small sprite 2 of SmallSprites drawn by $92FB).
;
; Plot mode 3 of PlotModes, reached only through PrintString's CALLs ($AF32:
; 2681 calls, $AFFD: 304, in the runs): the destructible scenery that a shot or
; a grenade breaks is erased by printing its object again in this mode. The
; caller selects it by SetPlotMode $99F8 with A = 3 ($9418, $AC44 region).
EraseBlockDebris:
  BIT 5,E
  RET NZ
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(PrintChar+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
EraseBlockLine:
  LD A,(DE)               ; XOR 8 pixel lines
  XOR (HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ EraseBlockLine
  DEC D
  LD A,D
  RRCA
  RRCA                    ; the cell's offset (0-$2FF) from the last line's
                          ; address
  RRCA
  AND $03
  LD H,A
  LD L,E
  LD DE,OpenCells             ; the three cell maps: $5B00 empty, $5E00 colourless,
                          ; $6100 not solid
  ADD HL,DE
  POP BC
  LD (HL),$FF
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  POP HL
  POP DE
  POP AF
  CALL AddDebris          ; a debris particle at D, E, then a second (JP)
  JP AddDebris

; XOR a glyph off a cell and mark the cell empty, no clipping and no debris
;
; As EraseBlockDebris without the column test and without the particles: A the
; code, D the row, E the column; $5B00 = $FF, $5E00 = 0, $6100 = 0 for the
; cell. Plot mode 4 of PlotModes, reached through PrintString's CALL at $AF32
; (368 calls in the warp runs).
EraseBlock:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(PrintChar+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
EraseBlockLine2:
  LD A,(DE)               ; XOR 8 pixel lines
  XOR (HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ EraseBlockLine2
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD L,E
  LD DE,OpenCells
  ADD HL,DE
  POP BC
  LD (HL),$FF
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  POP HL
  POP DE
  POP AF
  RET

; Print a string of glyph codes and control codes up to an end code
;
; HL the string, D the row, E the column, C the attribute. Each glyph is
; printed by the routine of the current plot mode (the CALLs at $AF32, $AFBF,
; $AFD1, $AFFD, written by SetPlotMode $99F8 from PlotModes $9A0F: PrintChar,
; PrintCharAttr, XorCharAttr, EraseBlockDebris, EraseBlock); the codes:
;
; $00-$60 a glyph, then the column + 1. $61-$8F: row += code - $78 (-23..+23),
; then column += the next byte (a relative move). $90-$CE: the next row, column
; += code - $AF (-31..+31). $CF-$DE: the ink of C = code - $CF, 8-15 the bright
; inks 0-7 (C = C AND $38 OR ink, BRIGHT for 8-15, FLASH dropped). $DF r c: row
; and column absolute. $E0 a: the attribute. $E1 n: repeat the bytes up to the
; next $E2 n times (HL and BC pushed: the attribute comes back at every pass).
; $E2: the repeat's end. $E3 lo hi: print the string at hi lo here, then go on
; with the row, column and attribute as before (a subroutine; the objects of
; ObjectTable $852E share parts so). $E4 n g: glyph g n times to the right. $E5
; n g: glyph g n times down. $E6 lo hi: GlyphBase = hi lo (the glyph set). $E7:
; a space of FontBase (the glyph set kept), column + 1. $E8 n: the cell type
; the next glyphs write ($AE1B). $E9: the next glyphs mark their cells drawn
; ($AE21 = 0). $EA: ... empty ($AE21 = $FF). $EB n: the current cell's type = n
; (only in plot mode 0). Any other code ($EC-$FF; the strings end with $FF)
; returns, HL past it.
;
; Callers: the menu ($6DB2, $6E06), the define keys ($6FC3), $7023, the Hall of
; Fame ($7151), $7693, the screen builder ($8502: every object of a screen,
; 2547 calls), $91E6, $941D, $996C, $99C2, the Hall of Fame entry ($A02D,
; $A0D5), the round end ($A829, $A87D), the bonus screen ($A8FC), the HUD score
; ($AD7A: 5969 calls).
PrintString:
  LD A,(HL)
  INC HL
  CP $61
  JP NC,PrintStringMove
  CALL PrintChar          ; the plot mode's routine (operand $AF33 set by
                          ; SetPlotMode)
  INC E
  JP PrintString
PrintStringMove:
  CP $90                  ; $61-$8F: a relative move, the row from the code,
                          ; the column from the next byte
  JP NC,PrintStringNewLine
  SUB $78
  ADD A,D
  LD D,A
  LD A,(HL)
  ADD A,E
  LD E,A
  INC HL
  JP PrintString
PrintStringNewLine:
  CP $CF                  ; $90-$CE: the next row, the column moved by code -
                          ; $AF
  JP NC,PrintStringInk
  INC D
  SUB $AF
  ADD A,E
  LD E,A
  JP PrintString
PrintStringInk:
  CP $DF                  ; $CF-$DE: the ink (8-15 bright)
  JP NC,PrintStringAt
  SUB $CF
  CP $08
  JP C,PrintInkSet
  SUB $08
  OR $40
PrintInkSet:
  LD B,A                  ; the ink code as an attribute (bright for 8-15)
  LD A,C
  AND $38
  OR B
  LD C,A
  JP PrintString
PrintStringAt:
  CP $DF                  ; $DF: row and column
  JP NZ,PrintStringAttr
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  JP PrintString
PrintStringAttr:
  CP $E0                  ; $E0: the attribute
  JP NZ,PrintStringRepeat
  LD C,(HL)
  INC HL
  JP PrintString
PrintStringRepeat:
  CP $E1                  ; $E1 n: the count in B, the restart point and the
                          ; attribute pushed
  JP NZ,PrintStringRepeatEnd
  LD B,(HL)
  INC HL
PrintStringRepeatPass:
  PUSH HL
  PUSH BC
  JP PrintString
PrintStringRepeatEnd:
  CP $E2                  ; $E2: once more or drop the restart point
  JP NZ,PrintStringCall
  POP BC
  DJNZ PrintStringRepeatAgain
  POP AF
  JP PrintString
PrintStringRepeatAgain:
  POP HL
  JP PrintStringRepeatPass
PrintStringCall:
  CP $E3                  ; $E3 lo hi: the sub-string, position and attribute
                          ; kept
  JP NZ,PrintStringRowOf
  LD A,(HL)
  INC HL
  PUSH HL
  LD H,(HL)
  LD L,A
  PUSH BC
  PUSH DE
  CALL PrintString
  POP DE
  POP BC
  POP HL
  INC HL
  JP PrintString
PrintStringRowOf:
  CP $E4                  ; $E4 n g: n glyphs to the right
  JP NZ,PrintStringColumnOf
  LD B,(HL)
  INC HL
  LD A,(HL)
PrintStringRowLoop:
  CALL PrintChar          ; the plot mode's routine (operand $AFC0)
  INC E
  DJNZ PrintStringRowLoop
  INC HL
  JP PrintString
PrintStringColumnOf:
  CP $E5                  ; $E5 n g: n glyphs down
  JP NZ,PrintStringGlyphSet
  LD B,(HL)
  INC HL
  LD A,(HL)
PrintStringColumnLoop:
  CALL PrintChar          ; the plot mode's routine (operand $AFD2)
  INC D
  DJNZ PrintStringColumnLoop
  INC HL
  JP PrintString
PrintStringGlyphSet:
  CP $E6                  ; $E6 lo hi: GlyphBase
  JR NZ,PrintStringSpace
  LD A,(HL)
  LD (PrintChar+$000E),A
  INC HL
  LD A,(HL)
  LD (PrintChar+$000F),A
  INC HL
  JP PrintString
PrintStringSpace:
  CP $E7                  ; $E7: a space from FontBase, the glyph set restored
  JR NZ,PrintStringCellType
  PUSH HL
  LD HL,(PrintChar+$000E)
  PUSH HL
  LD HL,FontBase
  LD (PrintChar+$000E),HL
  LD A,$20
  CALL PrintChar          ; the plot mode's routine (operand $AFFE, read back
                          ; at $B033)
  INC E
  POP HL
  LD (PrintChar+$000E),HL
  POP HL
  JP PrintString
PrintStringCellType:
  CP $E8                  ; $E8 n: the cell type for the next glyphs
  JR NZ,PrintStringDrawn
  LD A,(HL)
  LD (PrintCharLine+$0018),A
  INC HL
  JP PrintString
PrintStringDrawn:
  CP $E9                  ; $E9: the next cells marked drawn ($5B00 = 0)
  JR NZ,PrintStringEmpty
  XOR A
  LD (PrintCharLine+$001E),A
  JP PrintString
PrintStringEmpty:
  CP $EA                  ; $EA: the next cells marked empty ($5B00 = $FF)
  JR NZ,PrintStringSetType
  LD A,$FF
  LD (PrintCharLine+$001E),A
  JP PrintString
PrintStringSetType:
  CP $EB                  ; $EB n: the cell type of the current cell; any other
                          ; code ends the string
  RET NZ
  LD A,(HL)
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,(PrintStringSpace+$0012) ; only in plot mode 0 (the CALL at $AFFD is
                                 ; PrintChar's)
  LD BC,PrintChar
  SBC HL,BC
  JR NZ,PrintStringSetTypeDone
  CALL CellToPixels       ; DE to pixels (row * 8, column * 4), HL = the $6100
                          ; cell ($80C1)
  CALL BlockMapCell
  LD (HL),A
PrintStringSetTypeDone:
  POP HL
  POP DE
  POP BC
  INC HL
  JP PrintString

; Clear the pixels and set every attribute to 0
;
; C = 0, falls into ClearScreenAttr. Callers: the menu ($6DA1), the define keys
; ($6FAE), the game start ($758E), the name entry ($A0C2), the round end
; ($A877), the bonus screen ($A8F6).
ClearScreen:
  LD C,$00

; Clear the pixels and set every attribute to C
;
; $5AFF down to $5800 = C, then $57FF down to $4000 = 0 (two LDDRs). Called
; with C = $44 by the Hall of Fame ($714B).
ClearScreenAttr:
  LD HL,$5AFF
  LD DE,$5AFE
  LD (HL),C
  LD BC,$02FF
  LDDR
  LD (HL),$00
  LD BC,$17FF
  LDDR
  RET

; Clear the top 22 character rows (pixels and attributes), the HUD rows 22-23
; kept
;
; The attributes $5800-$5ABF = 0, then 176 pixel lines of 32 bytes from $4000,
; the next line by NextPixelLine $B099. Called by the screen builder ($84D4)
; before a screen is drawn (241 calls in the runs).
ClearPlayArea:
  LD C,$00
  LD HL,$5800
  LD (HL),C
  LD DE,$5801
  LD BC,$02BF
  LDIR
  LD HL,$4000
  LD B,$B0
ClearPlayAreaLine:
  PUSH BC                 ; one pixel line of 32 bytes
  PUSH HL
  LD E,L
  LD D,H
  INC DE
  LD (HL),$00
  LD BC,$001F
  LDIR
  POP HL
  CALL NextPixelLine
  POP BC
  DJNZ ClearPlayAreaLine
  RET

; The screen address of a pixel position from the line tables
;
; D the pixel line (0-191), E the X in 2-pixel units (0-127). HL = the address
; of line D from the tables built by $7BEF at $6500 (high bytes) and $6600 (low
; bytes), plus (E AND $7C) / 4 = the byte column. A and the flags kept.
; Callers: the sprite drawers $7771, $77FF, $79CF, $7A22 (1.5 million calls),
; $830F, $9041, $92FF (SmallSprites).
PixelAddress:
  PUSH AF
  LD L,D
  LD H,$65
  LD A,(HL)
  INC H
  LD L,(HL)
  LD H,A
  LD A,E
  AND $7C
  RRCA
  RRCA
  ADD A,L
  LD L,A
  POP AF
  RET

; HL to the screen address of the next pixel line down
;
; The standard step: H + 1; at a character row's end L + 32, and at a third's
; end H back by 8. Callers: the line table builder $7C06, $7C1E, ClearPlayArea.
NextPixelLine:
  INC H
  LD A,H
  AND $07
  RET NZ
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; HL to the screen address of the pixel line above (never ran)
;
; The step up, the reverse of NextPixelLine: H - 1; at a character row's top L
; - 32, and when that does not borrow H + 8. No caller in the image and no
; recording ran it (in the cut it is data): a routine of the toolkit left
; unused.
PrevPixelLine:
  LD A,H
  DEC H
  AND $07
  RET NZ
  LD A,L
  SUB $20
  LD L,A
  RET C
  LD A,H
  ADD A,$08
  LD H,A
  RET

; Wait BC times 21 T-states
;
; An LDIR of BC bytes from $0000 to $0000: each byte copied onto itself (the
; ROM bytes go nowhere, the RAM bytes are written with their own values), 21 T
; a byte. BC, DE and HL kept. Callers: $7033, $7036, the Hall of Fame ($716E,
; BC = $0400), $756E, $7585, the main loop ($7668), the name entry ($A039,
; $A03C, $A0E8), the round end ($A871-$A891), the bonus screen ($A8E4-$A948).
Delay:
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,$0000
  LD DE,$0000
  LDIR                    ; BC bytes onto themselves
  POP HL
  POP DE
  POP BC
  RET

; Print A as three decimal digits at D, E with FontBase and attribute C
;
; GlyphBase = FontBase $D7E0, then the hundreds, the tens and the units by
; PrintDigit with B = 100, 10, 1; E advances by 3. Entered by the JP at $8E83
; (the HUD's ZONES and other counters, 249 runs). Leaves GlyphBase at FontBase.
PrintNumber3:
  PUSH BC
  PUSH HL
  LD HL,FontBase
  LD (PrintChar+$000E),HL
  LD B,$64
  CALL PrintDigit
  LD B,$0A
  CALL PrintDigit
  LD B,$01
  CALL PrintDigit
  POP HL
  POP BC
  RET

; Print the digit of A in base B, keep the remainder
;
; L = A / B (subtraction), the glyph '0' + L printed by PrintCharAttr at D, E
; with attribute C, E + 1; A = the remainder.
PrintDigit:
  LD L,$00
PrintDigitLoop:
  SUB B
  JR C,PrintDigitShow
  INC L
  JR PrintDigitLoop
PrintDigitShow:
  ADD A,B
  PUSH AF
  LD A,L
  ADD A,$30
  CALL PrintCharAttr
  POP AF
  INC E
  RET

; Zero the work area $B181-$B6D0 (1360 bytes)
;
; Called by the menu ($6DD4), the define keys ($6FC9) and the screen builder
; ($84A4): every screen starts with the object tables of WorkArea cleared.
ClearWorkArea:
  LD HL,WorkArea
  LD DE,WorkArea+$0001
  LD BC,$054F
  LD (HL),$00
  LDIR
  RET
