; --------------------------------------------------------------------------------------------------------------------
; text.asm: The text printer: control codes, single and double height, the font
;
; PrintText prints a string of the font's characters 32-127 with control codes: $16 row col (AT), $01 single height,
; $02 double height, $10 n ink, $11 n paper, $12 n flash, $13 n bright, $14 n the whole attribute, $15 the default
; attribute again, $09 skip a column, $0D a new line, $00 the end. Other codes below 32 and above 127 print "?". The
; state is TextVars $E712-$E716.
; --------------------------------------------------------------------------------------------------------------------

  ORG $E667

; Print the string at HL with its control codes
;
; Input: HL the string. Reads up to and including $00; at the end the attribute
; goes back to the default ($E712 to $E713) and HL points after the $00. $11
; (paper) and $12 (flash) never ran. $12 and $13 cannot set their bit: the
; ROTATE through carry ($E6DB, $E6EE-$E6F0) puts the carry left by the CP
; (always clear) into the bit, so FLASH and BRIGHT are always cleared (known
; only from the code; the menu's "$13 1" at $F05A has no effect).
;
; Witness: L1 46858 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
PrintText:
  LD A,(HL)
  INC HL
  CP $16
  JR Z,PrintTextAt
  CP $01
  JR Z,PrintTextSingle
  CP $02
  JR Z,PrintTextDouble
  CP $10
  JR Z,PrintTextInk
  CP $11
  JR Z,PrintTextPaper
  CP $12
  JR Z,PrintTextFlash
  CP $13
  JR Z,PrintTextBright
  CP $14
  JR Z,PrintTextAttr
  CP $15
  JR Z,PrintTextCode15
  AND A
  JR Z,PrintTextEnd
  CALL PrintChar
  JR PrintText
PrintTextEnd:
  LD A,(TextVars)
  LD (TextAttr),A
  RET
PrintTextAt:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (TextRow),BC
  JR PrintText
PrintTextSingle:
  XOR A
  LD (TextDouble),A
  JR PrintText
PrintTextDouble:
  LD A,$01
  LD (TextDouble),A
  JR PrintText
PrintTextInk:
  LD A,(HL)
  INC HL
  AND $07
  LD C,A
  LD A,(TextAttr)
  AND $F8
  OR C
  LD (TextAttr),A
  JR PrintText
PrintTextPaper:
  LD A,(HL)
  INC HL
  SLA A
  SLA A
  SLA A
  AND $38
  LD C,A
  LD A,(TextAttr)
  AND $C7
  OR C
  LD (TextAttr),A
  JR PrintText
PrintTextFlash:
  LD A,(HL)
  INC HL
  RR A
  AND $80
  LD C,A
  LD A,(TextAttr)
  AND $7F
  OR C
  LD (TextAttr),A
  JP PrintText
PrintTextBright:
  LD A,(HL)
  INC HL
  RR A
  RR A
  AND $40
  LD C,A
  LD A,(TextAttr)
  AND $BF
  OR C
  LD (TextAttr),A
  JP PrintText
PrintTextAttr:
  LD A,(HL)
  INC HL
  LD (TextAttr),A
  JP PrintText
PrintTextCode15:
  LD A,(TextVars)
  LD (TextAttr),A
  JP PrintText

; The printer's state: default attribute, attribute, double height, row, column
TextVars:
  DEFB $07
TextAttr:
  DEFB $07                ; the attribute of the next characters
TextDouble:
  DEFB $00                ; 0 single height, 1 double height
TextRow:
  DEFB $00                ; the character row 0-23 (AT's first byte)
TextColumn:
  DEFB $00                ; the column 0-31 (AT's second byte)

; Print character A, or act on $0D and $09
;
; $0D: NewLine; $09: NextColumn; codes below 32 or from 128: "?"; else
; DrawGlyph. HL kept.
;
; Witness: L1 34443 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
PrintChar:
  PUSH HL
  CP $0D
  JR Z,PrintCharSkip
  CP $09
  JR Z,PrintCharSkip2
  CP $20
  JR C,PrintCharSkip3
  CP $80
  JR NC,PrintCharSkip3
  CALL DrawGlyph
  POP HL
  RET
PrintCharSkip:
  CALL NewLine
  POP HL
  RET
PrintCharSkip2:
  CALL NextColumn
  POP HL
  RET
PrintCharSkip3:
  LD A,$3F
  CALL DrawGlyph
  POP HL
  RET

; Draw font character A at TextRow, TextColumn in TextAttr, and move on a
; column
;
; The glyph Font + 8 x (A - 32) goes to the 8 lines of the character row
; (line-table entry 8 x row + 7, $B53B); at double height each row is drawn
; twice, so the character covers the row and the next. Then the attribute
; TextAttr at the cell (and the cell below at double height), and NextColumn.
;
; Witness: L1 34375 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
DrawGlyph:
  LD DE,SfxSpikeDeathParams+$000E
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD BC,$08FF
  LD IX,SpectrumLines+$000E
  LD A,(TextRow)
  SLA A
  SLA A
  SLA A
  LD E,A
  LD D,$00
  ADD IX,DE
  ADD IX,DE
DrawGlyphLoop:
  LD D,(IX+$01)
  LD A,(TextColumn)
  OR (IX+$00)
  LD E,A
  LDI
  INC IX
  INC IX
  LD A,(TextDouble)
  AND A
  JR Z,DrawGlyphSkip
  DEC HL
  LD D,(IX+$01)
  LD A,(TextColumn)
  OR (IX+$00)
  LD E,A
  LDI
  INC IX
  INC IX
DrawGlyphSkip:
  DJNZ DrawGlyphLoop
  LD A,(TextAttr)
  LD C,A
  LD HL,(TextRow)
  LD A,H
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  OR L
  LD L,A
  LD DE,$5800
  ADD HL,DE
  LD (HL),C
  LD A,(TextDouble)
  AND A
  JR Z,NextColumn
  LD DE,$0020
  ADD HL,DE
  LD (HL),C

; TextColumn + 1; at 32 a new line
;
; Witness: L1 34443 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
NextColumn:
  LD A,(TextColumn)
  INC A
  LD (TextColumn),A
  CP $20
  RET C

; TextColumn 0, TextRow + 1 (24 wraps to 0)
;
; Witness: L1 49 (menu, twoname).
NewLine:
  XOR A
  LD (TextColumn),A
  LD A,(TextRow)
  INC A
  LD (TextRow),A
  CP $18
  RET C
  XOR A
  LD (TextRow),A
  RET

; Print the text "Erase Una Vez ..." (never called)
;
; LD HL,$E7CD: CALL PrintText: RET. Nothing in the image calls it and no
; recording ran it (known only from the code). The text starts with the Amstrad
; CPC firmware's LOCATE code $1F row col, which PrintText does not know: it
; would print "?" for $1F and $0A. A leftover of the CPC original or of the
; Spanish conversion (the menu says "VERSIONED BY J250 <SPAIN>").
;
; Witness: L1 0 ().
PrintOnceUponATime:
  LD HL,OnceUponATimeText
  CALL PrintText
  RET

; "Erase Una Vez ..." ("once upon a time", Spanish): CPC LOCATE 2,10, attribute
; $38, single then double height
OnceUponATimeText:
  INCBIN "res/texts/once-upon-a-time.bin",$0000,25

; XOR the logo onto the menu screen (never called)
;
; XorSprite $E3EE with HL = $C066, DE = Logo, B = 60 lines, width 18: draws the
; logo of DrawLogo $E7F7 a second time, removing it. Not called and not run
; (known only from the code).
;
; Witness: L1 0 ().
XorLogo:
  LD HL,WaterB5+$0002
  LD DE,Logo
  LD A,$12
  LD (SpriteWidth),A
  LD B,$3C
  CALL XorSprite
  RET

  ORG $F5C9

; The font: characters 32-127, 8 bytes each; 123-127 the status-line icons of
; lives, water, keys, hammers and level
Font:
  INCBIN "res/fonts/font.bin",$0000,768

; 11 zeros to the end of the code block
FontTail:
  DEFS $0B
