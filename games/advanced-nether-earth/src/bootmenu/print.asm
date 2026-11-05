; --------------------------------------------------------------------------------------------------------------------
; print.asm: the help's text printer, the page keys, the game key
;
; PrintString prints a 0-terminated string at PrintAt (column 0-63 in 4-pixel half cells, row 0-23): code 1 switches
; to FontLatin, 2 to FontCyrillic (UseLatin / UseCyrillic patch the font base in PrintGlyph), every other byte is a
; glyph. PrintGlyph ORs the glyph's 7 lines (its bytes 1-7; byte 0 is the blank line above) into the left or right
; half of the screen byte (masks $F0 / $0F): text over a picture keeps the picture. Past column 62 the line goes on at
; column 30 of the next row; past row 23, row 0.
;
; With TypeAtOnce = 0 (the pages) each glyph is followed by a delay (BC = $02BC: about 18000 T) and a look at SPACE,
; which drops the page for HelpMenu. With 1 (the help menu's names) neither.
; --------------------------------------------------------------------------------------------------------------------

; code 1: the Latin font from here; A = the next byte, HL on it
;
; Used by the routine at PrintString.
UseLatin:
  PUSH HL
  LD HL,FontLatin-$0100   ; glyph = code * 8 + FontLatin - $100
  LD (GlyphFont+$0001),HL
  POP HL
  INC HL
  LD A,(HL)
  RET

; code 2: the Cyrillic font from here; A = the next byte, HL on it
;
; Used by the routine at PrintString.
UseCyrillic:
  PUSH HL
  LD HL,FontCyrillic-$0100
  LD (GlyphFont+$0001),HL
  POP HL
  INC HL
  LD A,(HL)
  RET

; print glyph A at PrintAt, then PrintAt on one column
;
; The glyph's address: A * 8 + the font base (GlyphFont's operand). The column
; wraps at 63 to 30 on the next row, the row at 24 to 0 (never on the help's
; pages). The screen byte from ScreenRows and the column / 2; the column's bit
; 0 picks the right half (mask $0F) or the left ($F0). Seven lines from the
; cell's second.
PrintGlyph:
  LD L,A                  ; HL = the code
  XOR A
  LD H,A
  LD B,A                  ; B = 0 (PrintString's delay sets it again)
GlyphFont:
  LD DE,FontLatin-$0100   ; the font base: UseLatin / UseCyrillic write the
                          ; operand
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE               ; HL = the glyph
  PUSH HL
  LD HL,PrintAt           ; PrintAt: the column
  LD A,(HL)
GlyphColumn:
  LD C,A                  ; C = the column
  CP $3F                  ; past column 62
  JR C,GlyphHere
  LD A,(PrintAt+1)        ; the next row
  INC A
  LD (PrintAt+$0001),A
  LD A,$1E                ; column 30 of it
  JR GlyphColumn
GlyphHere:
  INC A                   ; the column after this one
  LD (HL),A
  LD A,(PrintAt+1)
  CP $18                  ; past row 23
  JR C,l_B0C9
  XOR A                   ; row 0 (the help never gets there)
  LD (PrintAt+$0001),A
l_B0C9:
  LD DE,ScreenRows        ; the row's screen address
  SLA A
  LD H,B
  LD L,A
  ADD HL,DE
  LD A,C
  SRL A                   ; the column's byte, its half in the carry
  LD C,A
  EX AF,AF'
  LD A,C
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  EX DE,HL
  EX AF,AF'
  POP DE
  JR C,RightHalf          ; the right half
  LD C,$F0                ; the left half
  INC DE                  ; the glyph's line 0 is not drawn: lines 1-7 to the
                          ; cell's lines 1-7
  INC H
  LD A,(DE)               ; OR the glyph's half into the screen
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  AND C
  OR (HL)
  LD (HL),A
  RET
RightHalf:
  LD C,$0F                ; the same with the low nibble
  INC DE
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  AND C
  OR (HL)
  LD (HL),A
  INC H
  LD A,(DE)
  AND C
  OR (HL)
  LD (HL),A
  RET

; print the 0-terminated string at HL: codes 1 / 2 the fonts, with TypeAtOnce 0
; a delay a glyph and SPACE to the help menu
;
; Used by the routines at HelpMenu and ShowPage.
PrintString:
  LD A,(HL)
  OR A
  JR Z,PrintEnd           ; 0: the end
  CP $01                  ; 1: Latin from here
  CALL Z,UseLatin
  CP $02                  ; 2: Cyrillic from here
  CALL Z,UseCyrillic
  PUSH HL
  CALL PrintGlyph         ; the glyph
  LD A,(TypeAtOnce)       ; at once?
  OR A
  JR NZ,PrintSkip
  LD A,$7F                ; SPACE: the help menu (it sets the stack again)
  IN A,($FE)
  RRA
  JP NC,HelpMenu
  LD BC,700               ; the typewriter's delay: 700 turns of 26 T
TypeDelay:
  DEC BC
  LD A,B
  OR C
  JR NZ,TypeDelay
PrintSkip:
  POP HL                  ; the next byte
  INC HL
  JR PrintString
PrintEnd:
  RET                     ; the 0

; 1: PrintString prints at once (the help menu), 0: types (the pages)
TypeAtOnce:
  DEFB $00

; boot menu key 1: the tune from its start, the screen cleared, IM 1, StartGame
;
; Calls bank 1's $C000 (the player's init: the tune from its start, its AY
; registers set), bank 0, ClearScreen (one more interrupt: a frame of the
; tune), I = $3F, IM 1, EI, JP StartGame.
LeaveForGame:
  DI
  LD A,$11                ; bank 1
  CALL SetPage
  CALL BANK_WINDOW        ; the tune's init: the tune back at its start
  LD A,$10                ; bank 0
  CALL SetPage
  CALL ClearScreen        ; one more frame under IM 2 (ClearScreen's HALT)
  LD A,$3F                ; I as the ROM keeps it
  LD I,A
  IM 1                    ; IM 1: no more BootInterrupt
  EI
  JP StartGame

; ENTER or 0: return (the next page); SPACE: the help menu
;
; A HALT a turn (the tune plays on).
WaitPageKey:
  LD A,$BF                ; ENTER
  IN A,($FE)
  RRA
  RET NC
  LD A,$EF                ; 0
  IN A,($FE)
  RRA
  RET NC
  LD A,$7F                ; SPACE
  IN A,($FE)
  RRA
  JP NC,HelpMenu
  EI
  HALT                    ; a frame
  JR WaitPageKey

; the printer's column (0-63, 4-pixel cells) and row (0-23)
PrintAt:
  DEFB $1E,$05

; the Latin font: 96 glyphs $20-$7F, 8 bytes each (line 0 blank), 4 pixels in
; both nibbles
FontLatin:
  INCBIN "res/fonts/latin.bin",$0000,768

; the Cyrillic font: the same codes, the authors' KOI-7-like layout (a = а, q =
; я, w = в ...)
FontCyrillic:
  INCBIN "res/fonts/cyrillic.bin",$0000,768

; the screen address of each character row's first line, rows 0-23
ScreenRows:
  DEFW $4000,$4020,$4040,$4060,$4080,$40A0,$40C0,$40E0
  DEFW $4800,$4820,$4840,$4860,$4880,$48A0,$48C0,$48E0
  DEFW $5000,$5020,$5040,$5060,$5080,$50A0,$50C0,$50E0
