; --------------------------------------------------------------------------------------------------------------------
; text.asm: Print routines, the font, the strings
; --------------------------------------------------------------------------------------------------------------------

  ORG $80EB

; A string: three rows of three spaces, no attributes: erases the name cursor
; (its Y, X copied from NameCursorText)
;
; String format (PrintString $837B): Y (pixel line), X (in half characters),
; the attribute of the lower cell, the attribute of the cell ($FF: leave), then
; codes: $20 and up a glyph, $FF a new line 8 pixels down, 1-$1F skip that many
; columns, 0 the end. $A8F6-$A8FC copy NameCursorText's Y, X here and print it.
CursorEraseText:
  INCBIN "res/texts/hiscore-texts.bin",$0000,16

; "RANK  SCORE  NAME" at Y 4, X 2
;
; Printed by $A700. Witness: $80FB-$8213 read by PrintString $837B (c48,
; gameover, menu).
HiScoreHeading:
  INCBIN "res/texts/hiscore-texts.bin",$0010,20

; "NO." and two digits: the rank, Y and X and the digits written by $A70D /
; $A711 for each of the 10 lines
HiScoreRankText:
  INCBIN "res/texts/hiscore-texts.bin",$0024,10

; The high-score table's string header: Y $14, X $14, attributes 7, $47
;
; PrintStringTall $836E prints it (twice at $A734 / $A737).
HiScoreTableHead:
  INCBIN "res/texts/hiscores.bin",$0000,4

; Ten entries of 21 bytes: 8 score digits, 4 (skip 4 columns), 10 name letters,
; $FF $FF (two lines down)
;
; TitleFired $5C55 (HL = $8126, the names) and MatchCheatName $5C68 (DE from
; $8213) read the names for the cheat SLOPPY; InsertHighScore $A806 moves the
; entries down on a new high score (the LDDR at $A834) and writes the score and
; the name; ShowHighScores $A6EC prints them. The default table: JEFF C
; 00100400, LINDA, SIMES, DANGERSTU, GREGGS, JAMIE, RAY, MONTY, FUNGUS, KEV
; 00005010.
HiScoreEntries:
  INCBIN "res/texts/hiscores.bin",$0004,211

; "COPYRIGHT GREMLIN GRAPHICS 1990" at Y $B5, X 2
CopyrightText:
  INCBIN "res/texts/copyright.bin",$0000,36

; "SLOPPY" and four spaces: the 11th name, the one moved out when a score
; enters the table
;
; Witness: $8214-$8215 read by $5C68 (every play recording).
SpareName:
  INCBIN "res/texts/sloppy.bin",$0000,10

; The note icon (glyphs $65, $66) at Y $B8, X $1E: printed by the 128K glue
; when the title's toggle picks music
MusicIconText:
  INCBIN "res/texts/strings.bin",$0000,7

; The effects icon (glyphs $2A, $26) at Y $B8, X $1E: printed when the toggle
; picks the effects
;
; Both are printed by the 128K glue ($85B3-$85BF of the glue, AyGlue in
; src/boot); on a 48K the game never prints them. Witness: $821E-$8224 read by
; $837B (c1, deaths, opt2-4).
EffectsIconText:
  INCBIN "res/texts/strings.bin",$0007,7

; "WELL DONE! YOU HAVE A HIGH SCORE" / "PLEASE ENTER YOUR NAME" at Y $14, X 0
HighScoreMessage:
  INCBIN "res/texts/strings.bin",$000E,62

; The letters to pick from: A-F, G-L, M-R, S-X, Y Z ! and the two keys "<"
; (delete) and "+" (end)
NameGridText:
  INCBIN "res/texts/strings.bin",$004C,68

; The name cursor: a 3 x 3 frame of glyphs $22-$29; Y and X moved by $A90E
NameCursorText:
  INCBIN "res/texts/strings.bin",$0090,16

; The name being typed: header (Y $96, X $14), 10 letters, end
NameEntryText:
  INCBIN "res/texts/strings.bin",$00A0,4
NameEntryLetters:
  INCBIN "res/texts/strings.bin",$00A4,11

; " / " at Y $A0, X $12: its Y, X set by $A874
NameEntryMark:
  INCBIN "res/texts/strings.bin",$00AF,8

; The panel's Fireblade picture: Y 0, X $34, six glyph codes from
; FirebladeIcons, end
FirebladePanelText:
  INCBIN "res/texts/strings.bin",$00B7,4
FirebladeGlyphs:
  INCBIN "res/texts/strings.bin",$00BB,7

; "THE DAWN HAS COME AND MY / WORLD IS SAFE, / FOR NOW....." at Y $20, X 4
;
; Printed by HavokFade $872B (at $8761) when the end picture has faded.
; Witness: havok (Havok's hit points POKEd to 1).
EndText:
  INCBIN "res/texts/strings.bin",$00C2,58

  ORG $8365

; Print the score string $6657, then the panel string $6667
;
; Callers: $5C68, $9615 (the energy loss), $97A3, $9801, $9E61.
;
; Witness: L1 262 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x1, opt x3, rzx x63, rzxroom x12).
PrintScore:
  LD HL,ScoreLine
  CALL PrintString

; Print the panel string at $6667 (the globals page)
;
; Caller: $FF01 (each pass, when its value changed).
;
; Witness: L1 455 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x1, opt x3, rzx x64, rzxroom x12).
PrintPanelLine:
  LD HL,StatusLine

; Print the string at HL in the tall mode: one glyph row drawn twice
;
; The string's Y (HL+0) AND 7: 0 puts 0 into the operand at $8411
; (PrintGlyphTop repeats row 4 and row 7 is lost), else into $841D (the upper
; cell's last row is drawn again at the top of the lower cell: 9 rows).
; PrintString's end sets both back to $FF. Callers: the title $6A7B (the
; options), $A6D9 (the high-score table), $A861.
;
; Witness: L1 546 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, rzx x66, rzxroom x12).
PrintStringTall:
  LD BC,PrintGlyphTop+10
  LD A,(HL)
  AND $07
  JR Z,SetTallMode
  LD BC,PrintGlyphTopNext+$0007
  XOR A
SetTallMode:
  LD (BC),A               ; (BC) = 0

; Print the string at HL: Y, X, two attributes, then glyph codes, $FF new line,
; 1-$1F skip, 0 end
;
; Header: B = Y in pixel lines, C = X in half characters (SRL C), the third
; byte to $8436 (the attribute of the lower cell when the glyph straddles two),
; the fourth to $83FB (the attribute of the glyph's cell); $FF leaves the
; attributes. SetPrintPosition puts the screen address in DE and the next
; line's B + 8, C into the operand at $83C6. Codes: $20 and up PrintGlyph from
; Font $7BE5 + (code - $20) x 8; 1-$1F add to DE (skip columns); $FF new line;
; 0: the end, the attribute operands and the tall flags back to $FF. Returns HL
; past the end: the strings can be printed one after the other.
;
; Callers: $5DF1, $5DFB, PrintScore, HavokFade, $A6D9, $A861, $A8E2, $FF01.
;
; Witness: L1 2381 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, rzx x67, rzxroom x12).
PrintString:
  LD BC,Font
  PUSH BC
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  INC HL
  LD (PrintGlyphLowerLoop+$0007),A
  LD A,(HL)
  INC HL
  LD (PrintGlyph+$0002),A
  PUSH HL
  CALL SetPrintPosition
  POP HL
  POP BC
PrintStringLoop:
  LD A,(HL)               ; the next code
  INC HL
  OR A
  JR NZ,PrintStringCode
  DEC A
  LD (PrintGlyphLowerLoop+$0007),A
  LD (PrintGlyph+$0002),A
  LD (PrintGlyphTopNext+$0007),A
  LD (PrintGlyphTop+$000A),A
  RET
PrintStringCode:
  PUSH BC                 ; a glyph, a skip or a new line
  PUSH HL
  LD H,$00
  CP $FF
  JR Z,PrintStringNewline
  CP $20
  JR C,PrintStringSkip
  SUB $20
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,BC
  CALL PrintGlyph
PrintStringNext:
  POP HL
  POP BC
  JR PrintStringLoop
PrintStringSkip:
  LD L,A                  ; 1-$1F: DE += A
  ADD HL,DE
  EX DE,HL
  JR PrintStringNext
PrintStringNewline:
  LD BC,$0000             ; LD BC,n: n = the next line's Y, X
                          ; (SetPrintPosition)
  CALL SetPrintPosition
  JR PrintStringNext

; DE = the screen address of pixel line B, column C / 2; the next line's B + 8,
; C kept at $83C6
;
; Caller: PrintString, $61E5, $620D (stage 2).
;
; Witness: L1 4627 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, rzx x67, rzxroom x12).
SetPrintPosition:
  PUSH BC
  LD A,$08
  ADD A,B
  LD B,A
  LD (PrintStringNewline+$0001),BC
  POP BC
  SRL C
  LD A,B
  AND $07
  LD D,A
  LD A,B
  AND $F8
  RRCA
  RRCA
  RRCA
  LD B,A
  JR ScreenAddress

; DE = the screen address of character row B + 1, column C (D = 0: the top
; pixel line)
;
; Callers: CellScreenAddress $8803, SpriteScreenAddress $8828.
;
; Witness: L1 179180 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
CharCellAddress:
  INC B
  LD D,$00
  LD A,B

; DE = the screen address of character row B, pixel line D, column C
;
; Witness: L1 183808 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ScreenAddress:
  AND $F8
  ADD A,$40
  ADD A,D
  LD D,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD E,A
  RET

; Draw the 8-byte glyph at HL at the screen address DE (any pixel line): DE + 1
; on return
;
; The cell's attribute from the operand at $83FB (SetCellAttr). C = D AND 7: 8
; - C rows into this cell, C rows into the cell below (E + 32; in the same
; third, no carry, D = the saved D AND $F8; a third crossed, the carry, D kept,
; already moved into the next third by the row loop); the lower cell's
; attribute from $8436. Tall mode: the operands at $8411 / $841D
; (PrintStringTall). Callers: PrintString, $6200.
;
; Witness: L1 34287 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, rzx x67, rzxroom x12).
PrintGlyph:
  PUSH DE
  LD A,$FF
  CALL SetCellAttr
  LD A,D
  AND $07
  LD C,A
  LD A,$08
  SUB C
  LD B,A
PrintGlyphTop:
  LD A,(HL)               ; the rows in the first cell; LD A,n at $8410: 0 =
                          ; tall (row 4 twice, row 7 lost)
  LD (DE),A
  INC HL
  INC D
  LD A,B
  CP $04
  JR NZ,PrintGlyphTopNext
  LD A,$FF
  OR A
  JR NZ,PrintGlyphTopNext
  DEC HL
PrintGlyphTopNext:
  DJNZ PrintGlyphTop
  LD A,C
  OR A
  JR Z,PrintGlyphDone
  LD A,$FF
  OR A
  JR NZ,PrintGlyphLower
  INC C
  DEC HL
PrintGlyphLower:
  LD A,E                  ; the next character row (E + 32, or the next third)
  ADD A,$20
  LD E,A
  JR C,PrintGlyphLowerRows
  POP AF
  PUSH AF
  AND $F8
  LD D,A
PrintGlyphLowerRows:
  LD B,C
PrintGlyphLowerLoop:
  LD A,(HL)               ; LD A,n at $8435: the lower cell's attribute
  LD (DE),A
  INC HL
  INC D
  DJNZ PrintGlyphLowerLoop
  LD A,$FF
  CALL SetCellAttr
PrintGlyphDone:
  POP DE
  INC DE
  RET

; Write A to the attribute of the screen address DE, unless A = $FF
;
; Witness: L1 44166 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x2, opt x3, rzx x67, rzxroom x12).
SetCellAttr:
  PUSH DE
  PUSH AF
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD D,A
  POP AF
  CP $FF
  JR Z,SetCellAttrDone
  LD (DE),A
SetCellAttrDone:
  POP DE
  RET
