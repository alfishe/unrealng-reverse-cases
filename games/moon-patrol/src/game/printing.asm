; --------------------------------------------------------------------------------------------------------------------
; printing.asm: Printing: the three fonts, the pixel and line tables, and the print code
;
; Text is printed by PrintText $FFD0 (a string at HL ending with $1F) or PrintChar $FDCC (the code in A). Codes
; $20-$7F print a glyph of the current font at the pixel position PrintX, PrintY, ORed onto the screen; with fonts 0
; and 1 the 2x2 attribute cells under the glyph take PrintAttr. Codes $80-$FF print "!". $0D is a new line. $10-$1A
; are control codes with one parameter byte after them (AT $16 takes two): $10 INK n, $11 PAPER n, $12 FLASH n, $13
; BRIGHT n (n masked to 0-7 or 0-1; a larger n sets PrintError bit 0), $14 n and $15 n print "?" in place of n, $16 AT
; x y (pixels; y wraps at 185), $17 TAB x (a new line first when x is left of PrintX), $18 MARGIN n (n AND $3F), $19
; LIMIT n (n OR $80 when below $80, with the error bit), $1A FONT n (n AND 3). Other codes below $20 print "?". $1F
; ends a string and cannot be printed.
; --------------------------------------------------------------------------------------------------------------------

; Colour the glyph's cells unless the font is FontPlain or the ROM font, then
; draw it
;
; Entered from PrintGlyph $FEF7 ($FF92 JP $F0F0) with the first row's address
; on the stack and in PrintLines $F012. Bit 2 of the font base's high byte set:
; straight to the drawing at $FFAD; otherwise the first row's screen address to
; PrintColour $FF95. Run 5268 times in game (as often as PrintGlyph).
PrintAttrCheck:
  BIT 2,(IX+$09)
  JP NZ,PrintRowsOr
  LD E,(HL)
  INC HL
  LD D,(HL)
  JP PrintColour

; 3 zero bytes, never read
PrintPad:
  DEFB $00,$00,$00

; Font 0: glyphs for $20-$7F, 8 bytes each, 5 rows used
;
; Glyph = PrintFont + 8 x code with PrintFont $F000, so the table starts at
; code $20. One byte a row, top row first, bits 7-0 left to right, set = ink;
; only the rows the descriptor names are drawn, the others are zero. The
; character set follows the Spectrum's ($5E up arrow, $60 pound, $7F copyright,
; lowercase present). 175 of 768 bytes are read in the runs (the characters the
; game prints).
FontSmall:
  INCBIN "res/fonts/FontSmall.bin",$0000,768

; Font 1, the thick title font: glyphs $20-$7F, 6 rows used
;
; Same layout with base $F300. 420 of 768 bytes read.
FontBold:
  INCBIN "res/fonts/FontBold.bin",$0000,768

; Font 2: glyphs $20-$7F, 6 rows used, printed without colours
;
; Same layout with base $F600. 246 of 768 bytes read.
FontPlain:
  INCBIN "res/fonts/FontPlain.bin",$0000,768

; For each x 0-255: the byte column (x / 8) and the pixel's bit mask
;
; Indexed by $FA00 + 2x: by the pixel routines ($FD80 B = $7D, C = x, doubled),
; and by the copier $AFAB (its byte column). Not a font.
PixelTable:
  DEFB $00,$80
  DEFB $00,$40
  DEFB $00,$20
  DEFB $00,$10
  DEFB $00,$08
  DEFB $00,$04
  DEFB $00,$02
  DEFB $00,$01
  DEFB $01,$80
  DEFB $01,$40
  DEFB $01,$20
  DEFB $01,$10
  DEFB $01,$08
  DEFB $01,$04
  DEFB $01,$02
  DEFB $01,$01
  DEFB $02,$80
  DEFB $02,$40
  DEFB $02,$20
  DEFB $02,$10
  DEFB $02,$08
  DEFB $02,$04
  DEFB $02,$02
  DEFB $02,$01
  DEFB $03,$80
  DEFB $03,$40
  DEFB $03,$20
  DEFB $03,$10
  DEFB $03,$08
  DEFB $03,$04
  DEFB $03,$02
  DEFB $03,$01
  DEFB $04,$80
  DEFB $04,$40
  DEFB $04,$20
  DEFB $04,$10
  DEFB $04,$08
  DEFB $04,$04
  DEFB $04,$02
  DEFB $04,$01
  DEFB $05,$80
  DEFB $05,$40
  DEFB $05,$20
  DEFB $05,$10
  DEFB $05,$08
  DEFB $05,$04
  DEFB $05,$02
  DEFB $05,$01
  DEFB $06,$80
  DEFB $06,$40
  DEFB $06,$20
  DEFB $06,$10
  DEFB $06,$08
  DEFB $06,$04
  DEFB $06,$02
  DEFB $06,$01
  DEFB $07,$80
  DEFB $07,$40
  DEFB $07,$20
  DEFB $07,$10
  DEFB $07,$08
  DEFB $07,$04
  DEFB $07,$02
  DEFB $07,$01
  DEFB $08,$80
  DEFB $08,$40
  DEFB $08,$20
  DEFB $08,$10
  DEFB $08,$08
  DEFB $08,$04
  DEFB $08,$02
  DEFB $08,$01
  DEFB $09,$80
  DEFB $09,$40
  DEFB $09,$20
  DEFB $09,$10
  DEFB $09,$08
  DEFB $09,$04
  DEFB $09,$02
  DEFB $09,$01
  DEFB $0A,$80
  DEFB $0A,$40
  DEFB $0A,$20
  DEFB $0A,$10
  DEFB $0A,$08
  DEFB $0A,$04
  DEFB $0A,$02
  DEFB $0A,$01
  DEFB $0B,$80
  DEFB $0B,$40
  DEFB $0B,$20
  DEFB $0B,$10
  DEFB $0B,$08
  DEFB $0B,$04
  DEFB $0B,$02
  DEFB $0B,$01
  DEFB $0C,$80
  DEFB $0C,$40
  DEFB $0C,$20
  DEFB $0C,$10
  DEFB $0C,$08
  DEFB $0C,$04
  DEFB $0C,$02
  DEFB $0C,$01
  DEFB $0D,$80
  DEFB $0D,$40
  DEFB $0D,$20
  DEFB $0D,$10
  DEFB $0D,$08
  DEFB $0D,$04
  DEFB $0D,$02
  DEFB $0D,$01
  DEFB $0E,$80
  DEFB $0E,$40
  DEFB $0E,$20
  DEFB $0E,$10
  DEFB $0E,$08
  DEFB $0E,$04
  DEFB $0E,$02
  DEFB $0E,$01
  DEFB $0F,$80
  DEFB $0F,$40
  DEFB $0F,$20
  DEFB $0F,$10
  DEFB $0F,$08
  DEFB $0F,$04
  DEFB $0F,$02
  DEFB $0F,$01
  DEFB $10,$80
  DEFB $10,$40
  DEFB $10,$20
  DEFB $10,$10
  DEFB $10,$08
  DEFB $10,$04
  DEFB $10,$02
  DEFB $10,$01
  DEFB $11,$80
  DEFB $11,$40
  DEFB $11,$20
  DEFB $11,$10
  DEFB $11,$08
  DEFB $11,$04
  DEFB $11,$02
  DEFB $11,$01
  DEFB $12,$80
  DEFB $12,$40
  DEFB $12,$20
  DEFB $12,$10
  DEFB $12,$08
  DEFB $12,$04
  DEFB $12,$02
  DEFB $12,$01
  DEFB $13,$80
  DEFB $13,$40
  DEFB $13,$20
  DEFB $13,$10
  DEFB $13,$08
  DEFB $13,$04
  DEFB $13,$02
  DEFB $13,$01
  DEFB $14,$80
  DEFB $14,$40
  DEFB $14,$20
  DEFB $14,$10
  DEFB $14,$08
  DEFB $14,$04
  DEFB $14,$02
  DEFB $14,$01
  DEFB $15,$80
  DEFB $15,$40
  DEFB $15,$20
  DEFB $15,$10
  DEFB $15,$08
  DEFB $15,$04
  DEFB $15,$02
  DEFB $15,$01
  DEFB $16,$80
  DEFB $16,$40
  DEFB $16,$20
  DEFB $16,$10
  DEFB $16,$08
  DEFB $16,$04
  DEFB $16,$02
  DEFB $16,$01
  DEFB $17,$80
  DEFB $17,$40
  DEFB $17,$20
  DEFB $17,$10
  DEFB $17,$08
  DEFB $17,$04
  DEFB $17,$02
  DEFB $17,$01
  DEFB $18,$80
  DEFB $18,$40
  DEFB $18,$20
  DEFB $18,$10
  DEFB $18,$08
  DEFB $18,$04
  DEFB $18,$02
  DEFB $18,$01
  DEFB $19,$80
  DEFB $19,$40
  DEFB $19,$20
  DEFB $19,$10
  DEFB $19,$08
  DEFB $19,$04
  DEFB $19,$02
  DEFB $19,$01
  DEFB $1A,$80
  DEFB $1A,$40
  DEFB $1A,$20
  DEFB $1A,$10
  DEFB $1A,$08
  DEFB $1A,$04
  DEFB $1A,$02
  DEFB $1A,$01
  DEFB $1B,$80
  DEFB $1B,$40
  DEFB $1B,$20
  DEFB $1B,$10
  DEFB $1B,$08
  DEFB $1B,$04
  DEFB $1B,$02
  DEFB $1B,$01
  DEFB $1C,$80
  DEFB $1C,$40
  DEFB $1C,$20
  DEFB $1C,$10
  DEFB $1C,$08
  DEFB $1C,$04
  DEFB $1C,$02
  DEFB $1C,$01
  DEFB $1D,$80
  DEFB $1D,$40
  DEFB $1D,$20
  DEFB $1D,$10
  DEFB $1D,$08
  DEFB $1D,$04
  DEFB $1D,$02
  DEFB $1D,$01
  DEFB $1E,$80
  DEFB $1E,$40
  DEFB $1E,$20
  DEFB $1E,$10
  DEFB $1E,$08
  DEFB $1E,$04
  DEFB $1E,$02
  DEFB $1E,$01
  DEFB $1F,$80
  DEFB $1F,$40
  DEFB $1F,$20
  DEFB $1F,$10
  DEFB $1F,$08
  DEFB $1F,$04
  DEFB $1F,$02
  DEFB $1F,$01

; The screen address of each pixel line 0-191 (192 words)
;
; Indexed by $FC00 + 2y ($7E00 doubled: H = $7E, L = y, then SLA L / RL H) by
; the pixel routines, PrintGlyph ($FF2D) and the sprite drawers. The scrollers
; start at line 64 ($FC80), 96 ($FCC0), 128 ($FD00) and 160 ($FD40). A line
; number past 191 reads past the table into PlotPixel's bytes (the wreck
; pieces, see BuggyWreck1 $638A).
ScreenLineTable:
  DEFW $4000,$4100,$4200,$4300,$4400,$4500,$4600,$4700
  DEFW $4020,$4120,$4220,$4320,$4420,$4520,$4620,$4720
  DEFW $4040,$4140,$4240,$4340,$4440,$4540,$4640,$4740
  DEFW $4060,$4160,$4260,$4360,$4460,$4560,$4660,$4760
  DEFW $4080,$4180,$4280,$4380,$4480,$4580,$4680,$4780
  DEFW $40A0,$41A0,$42A0,$43A0,$44A0,$45A0,$46A0,$47A0
  DEFW $40C0,$41C0,$42C0,$43C0,$44C0,$45C0,$46C0,$47C0
  DEFW $40E0,$41E0,$42E0,$43E0,$44E0,$45E0,$46E0,$47E0
  DEFW $4800,$4900,$4A00,$4B00,$4C00,$4D00,$4E00,$4F00
  DEFW $4820,$4920,$4A20,$4B20,$4C20,$4D20,$4E20,$4F20
  DEFW $4840,$4940,$4A40,$4B40,$4C40,$4D40,$4E40,$4F40
  DEFW $4860,$4960,$4A60,$4B60,$4C60,$4D60,$4E60,$4F60
  DEFW $4880,$4980,$4A80,$4B80,$4C80,$4D80,$4E80,$4F80
  DEFW $48A0,$49A0,$4AA0,$4BA0,$4CA0,$4DA0,$4EA0,$4FA0
  DEFW $48C0,$49C0,$4AC0,$4BC0,$4CC0,$4DC0,$4EC0,$4FC0
  DEFW $48E0,$49E0,$4AE0,$4BE0,$4CE0,$4DE0,$4EE0,$4FE0
  DEFW $5000,$5100,$5200,$5300,$5400,$5500,$5600,$5700
  DEFW $5020,$5120,$5220,$5320,$5420,$5520,$5620,$5720
  DEFW $5040,$5140,$5240,$5340,$5440,$5540,$5640,$5740
  DEFW $5060,$5160,$5260,$5360,$5460,$5560,$5660,$5760
  DEFW $5080,$5180,$5280,$5380,$5480,$5580,$5680,$5780
  DEFW $50A0,$51A0,$52A0,$53A0,$54A0,$55A0,$56A0,$57A0
  DEFW $50C0,$51C0,$52C0,$53C0,$54C0,$55C0,$56C0,$57C0
  DEFW $50E0,$51E0,$52E0,$53E0,$54E0,$55E0,$56E0,$57E0

; Set the pixel at x H, line L
;
; Address from PixelTable and ScreenLineTable, then OR the mask. Run 61349
; times in game; called from $87AE, $87B9, $8CF3 and $92CE.
PlotPixel:
  LD B,$7D
  LD C,H
  SLA C
  RL B
  LD H,$7E
  SLA L
  RL H
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(BC)
  ADD A,L
  LD L,A
  INC BC
  LD A,(BC)
  OR (HL)
  LD (HL),A
  RET

; Reset the pixel at x H, line L (AND NOT the mask)
;
; Run in a1 (1160), t1 (58), i1 (420) and i2 (942): called from $A7F5.
UnplotPixel:
  LD B,$7D
  LD C,H
  SLA C
  RL B
  LD H,$7E
  SLA L
  RL H
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(BC)
  ADD A,L
  LD L,A
  INC BC
  LD A,(BC)
  CPL
  AND (HL)
  LD (HL),A
  RET

; Invert the pixel at x H, line L (XOR the mask)
;
; Called from $AE12; run in i1 97928 times.
FlipPixel:
  LD B,$7D
  LD C,H
  SLA C
  RL B
  LD H,$7E
  SLA L
  RL H
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(BC)
  ADD A,L
  LD L,A
  INC BC
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  RET

; Print the code in A at the print position (or take it as a control code's
; parameter)
;
; Keeps BC, DE, HL and IX; works in the other register set. Sets IX = $F000 and
; jumps to the handler in PrintState $F00A with a return to $FDDD. Run 13526
; times in game.
PrintChar:
  PUSH BC
  EXX
  PUSH HL
  PUSH IX
  LD IX,PrintY
  LD HL,PrintCharDone
  PUSH HL
  LD HL,(PrintState)
  JP (HL)

; PrintCharDone
PrintCharDone:
  POP IX                  ; restore and return
  POP HL
  EXX
  POP BC
  RET

; The handler of a fresh code: a glyph, a new line, a control code or "?"
;
; $80 and up print "!"; $20-$7F print the glyph; $0D a new line; $10-$1A put
; the code's parameter handler from PrintCodeTable $F080 into PrintState
; ($FE0A); anything else prints "?". Run 8169 times in game.
PrintCharNormal:
  CP $80
  JR C,PrintCharLow
  LD A,$21
  JP PrintGlyph
PrintCharLow:
  CP $20                  ; codes below $80
  JP NC,PrintGlyph
  CP $0D
  JR Z,PrintNewline
  CP $10
  JR C,PrintUnknown
  CP $1B
  JR NC,PrintUnknown
  LD HL,PrintCodeTable
  SUB $10
  LD D,$00
  LD E,A
  ADD HL,DE
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (PrintState),DE
  RET

; New line: PrintX to the left margin, then the next line
;
; Run in game (33) and a1 (231): the menus' multi-line texts.
PrintNewline:
  LD HL,PrintX
  LD A,(PrintMargin)
  LD (HL),A
  DEC HL

; Add the line step to the line at HL; past 184 wrap to the top
;
; Also called by TAB ($FEA6) and by PrintGlyph when a glyph would pass the
; limit ($FF25).
PrintNextLine:
  LD A,(HL)
  ADD A,(IX+$10)
  CP $B9
  JR C,PrintNextLineStore
  SUB $B9
PrintNextLineStore:
  LD (HL),A               ; store the new line
  RET

; The handler for codes $14 and $15: back to PrintCharNormal and print "?" for
; the byte after them
;
; Not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known
; only from the code. The game's texts never use $14 or $15.
PrintSwallow:
  LD HL,PrintCharNormal
  LD (PrintState),HL
; This entry point is used by the routine at PrintCharNormal.
PrintUnknown:
  LD A,$3F                ; print "?": not executed in any recording, known
                          ; only from the code
  JP PrintGlyph

; INK n: PrintAttr's bits 0-2 = n AND 7 (game 82 runs)
PrintInk:
  LD B,$08
  CALL PrintTakeParam
  LD A,(PrintAttr)
  AND $F8
  OR B
  LD (PrintAttr),A
  RET

; PAPER n: bits 3-5 = n AND 7 (game 54)
PrintPaper:
  LD B,$08
  CALL PrintTakeParam
  LD A,(PrintAttr)
  AND $C7
  SLA B
  SLA B
  SLA B
  OR B
  LD (PrintAttr),A
  RET

; FLASH n: bit 7 = n AND 1 (game 5)
PrintFlash:
  LD B,$02
  CALL PrintTakeParam
  BIT 0,B
  JR Z,PrintFlashOff
  SET 7,(IX+$04)
  RET
PrintFlashOff:
  RES 7,(IX+$04)          ; flash off
  RET

; BRIGHT n: bit 6 = n AND 1 (game 82)
PrintBright:
  LD B,$02
  CALL PrintTakeParam
  BIT 0,B
  JR Z,PrintBrightOff
  SET 6,(IX+$04)
  RET
PrintBrightOff:
  RES 6,(IX+$04)          ; bright off
  RET

; AT x y, first parameter: PrintX = x, the next byte to PrintAtY (game 2489)
PrintAtX:
  LD (PrintX),A
  LD HL,PrintAtY
  LD (PrintState),HL
  RET

; AT, second parameter: PrintY = y, less 185 when 185 or more
PrintAtY:
  LD HL,PrintCharNormal
  LD (PrintState),HL
  CP $B9
  JR C,PrintAtYStore
  SUB $B9
PrintAtYStore:
  LD (PrintY),A           ; store the line
  RET

; TAB x: PrintX = x; a new line when x is left of the old PrintX
;
; Run only in a1 (320) and t1 (16): the score advance table's columns.
PrintTab:
  LD HL,PrintCharNormal
  LD (PrintState),HL
  LD C,A
  LD A,(PrintX)
  LD B,A
  LD A,C
  LD (PrintX),A
  SUB B
  RET NC
  LD HL,PrintY
  CALL PrintNextLine
  RET

; MARGIN n: PrintMargin = n AND $3F (game 25)
PrintMarginSet:
  LD B,$40
  CALL PrintTakeParam
  LD (PrintMargin),A
  RET

; LIMIT n: PrintLimit = n, with bit 7 forced and PrintError set when n is below
; $80 (game 25)
PrintLimitSet:
  LD HL,PrintCharNormal
  LD (PrintState),HL
  CP $80
  JR NC,PrintLimitStore
  SET 0,(IX+$07)
  OR $80
PrintLimitStore:
  LD (PrintLimit),A       ; store the limit
  RET

; FONT n: copy descriptor n AND 3 to the metrics and the base (game 106)
PrintFontSet:
  LD B,$04
  CALL PrintTakeParam
  LD H,$00
  LD L,B
  LD DE,FontDescriptors
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD DE,PrintWidth
  LD BC,$0006
  LDIR
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (PrintFont),DE
  RET

; Put PrintCharNormal back into PrintState and mask the parameter A with B - 1
; (error bit when A >= B)
;
; Called by each control code handler that takes a number (game 354 runs).
PrintTakeParam:
  LD HL,PrintCharNormal
  LD (PrintState),HL
  CP B
  JR C,PrintTakeParamMask
  SET 0,(IX+$07)
PrintTakeParamMask:
  DEC B                   ; mask
  AND B
  LD B,A
  RET

; Draw the glyph of the code in A at the print position and advance PrintX by
; its width
;
; The width: PrintWidthSpace for a space, PrintWidthI for "I", PrintWidthMW for
; "M" and "W", PrintWidth otherwise. A glyph that would pass PrintLimit starts
; a new line first. Then the row addresses into PrintLines (ScreenLineTable
; plus the byte column), the rows shifted right by PrintShift into
; PrintShifted, and PrintAttrCheck $F0F0. Run 5268 times in game.
PrintGlyph:
  LD (PrintCode),A
  CP $20
  JR Z,PrintGlyphSpace
  CP $49
  JR NZ,PrintGlyphNotI
  LD C,(IX+$0D)
  JR PrintGlyphFit
PrintGlyphSpace:
  LD C,(IX+$0F)           ; width of a space
  JR PrintGlyphFit
PrintGlyphNotI:
  CP $4D                  ; not "I"
  JR Z,PrintGlyphWide
  CP $57
  JR NZ,PrintGlyphNormal
PrintGlyphWide:
  LD C,(IX+$0E)           ; "M" or "W"
  JR PrintGlyphFit
PrintGlyphNormal:
  LD C,(IX+$0C)           ; any other character
PrintGlyphFit:
  LD A,(PrintX)           ; new line when the glyph does not fit
  LD B,A
  LD A,(PrintLimit)
  SUB B
  SUB C
  CALL C,PrintNewline
  LD A,C
  EX AF,AF'
  LD A,(PrintY)
  LD H,$7E
  LD L,A
  SLA L
  RL H
  LD A,(PrintX)
  AND A
  LD B,$00
  RRA
  RR B
  RRA
  RR B
  RRA
  RR B
  RLC B
  RLC B
  RLC B
  LD C,A
  LD A,B
  LD (PrintShift),A
  LD DE,PrintLines
  LD B,(IX+$11)
PrintGlyphLines:
  LD A,(HL)               ; one row address a pass
  ADD A,C
  LD (DE),A
  INC DE
  INC HL
  LD A,(HL)
  LD (DE),A
  INC DE
  INC HL
  DJNZ PrintGlyphLines
  LD A,(PrintCode)
  LD H,$00
  LD L,A
  LD DE,(PrintFont)
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  EX DE,HL
  LD HL,PrintShifted
  LD C,(IX+$11)
PrintGlyphShift:
  LD A,(PrintShift)       ; shift one glyph row into two bytes
  LD B,A
  LD A,(DE)
  LD (HL),A
  XOR A
  CP B
  JR Z,PrintGlyphStore
  AND A
PrintGlyphShiftBit:
  RR (HL)                 ; one bit
  RRA
  DJNZ PrintGlyphShiftBit
PrintGlyphStore:
  INC HL                  ; store the right byte
  LD (HL),A
  INC HL
  INC DE
  DEC C
  JR NZ,PrintGlyphShift
  LD BC,PrintShifted
  LD HL,PrintLines
  PUSH HL
  JP PrintAttrCheck

; Set the 2x2 attribute cells under the glyph to PrintAttr, then draw it
;
; HL = the first row's screen address; the cell's attribute address from its
; high byte ($58 + bits 3-4). Run 4055 times in game (fonts 0 and 1 only).
PrintColour:
  DEC HL
  EX DE,HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD A,(PrintAttr)
  LD (HL),A
  INC HL
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),A

; OR the shifted rows onto the screen, two bytes a row, and advance PrintX by
; the width
;
; Run 5268 times in game.
PrintRowsOr:
  POP HL
  EXX
  LD B,(IX+$11)
PrintRowsLoop:
  EXX                     ; one row
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,(BC)
  OR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  OR (HL)
  LD (HL),A
  INC BC
  EX DE,HL
  EXX
  DJNZ PrintRowsLoop
  EXX
  EX AF,AF'
  LD C,A
  LD A,(PrintX)
  ADD A,C
  LD (PrintX),A
  RET

; Print the string at HL up to its $1F
;
; Run 4004 times in game. The build-date strings start with $1F and print
; nothing (BuildDate0335 $7F00).
PrintText:
  LD A,(HL)
  CP $1F
  RET Z
  CALL PrintChar
  INC HL
  JR PrintText

; Reset the print state and print PrintResetText
;
; Not executed in any recording: known only from the code. Nothing calls it;
; the image's print state (font 3, the ROM font) is what this leaves, so it was
; the developer's.
PrintReset:
  LD HL,PrintCharNormal
  LD (PrintState),HL
  LD HL,PrintResetText
  CALL PrintText
  RET

; INK 0, AT 0 0, MARGIN 0, LIMIT $FF, FONT 3, end ($12 00 16 00 00 18 00 19 FF
; 1A 03 1F)
PrintResetText:
  INCBIN "res/text/PrintResetText.bin",$0000,12

; A zero byte, never read
PrintResetPad:
  DEFB $00

; The IM 2 interrupt's target: JP $7F14
;
; The game runs in IM 2 with I = $3A ($A7D5): the ROM's bytes at $3A00-$3AFF
; are $FF, so the vector is $FFFF, and the JR there (its offset is the ROM's
; $F3 at $0000) lands here. Run 25747 times in i1.
Im2Jump:
  JP Im2Handler

; Leftover: "ROYD3313", never read
BuildTag:
  DEFM "ROYD3313"

; $18, the JR the interrupt lands on: with the byte $F3 at $0000 it jumps back
; 13 to Im2Jump $FFF4 (run 25747 times in i1)
Im2Vector:
  DEFB $18
