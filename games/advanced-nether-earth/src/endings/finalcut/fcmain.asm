; --------------------------------------------------------------------------------------------------------------------
; fcmain.asm: Final Cut: the sequence, its scroll text and font
;
; The game wins (aneG's GameWon): it copies the packed Final Cut block from bank 6 to $6060, and the HRUM depacker in
; front of it unpacks this image over $6060-$F76C and jumps to FinalCut. FinalCut copies Bank7Block (the green alien
; screen, the PT3 player and X-Man's tune REM) to bank 7 at $C000, starts the tune from an interrupt of its own (mode
; 2: the table at $5B00 filled with $60, the handler FcInterrupt at $6060), shows the caption screen for $500 frames,
; then the magenta alien screen and the scroll.
;
; The scroll: two screens take turns, the normal one (bank 5, the magenta alien) and the shadow one (bank 7, the green
; alien), both reached through the $C000 window. Each frame one of them is paged in, its left 16 bytes scrolled up a
; pixel line (FcScroll, through the line table built over Bank7Block) and given the next pixel row of the text at the
; bottom (FcDrawRow), while the other is shown; so the screen flips between green and magenta every frame. The text
; (ScrollText) is 8 characters a row in a 16 x 16 font (ScrollFont); at its 0 the bottom row is cleared and FcTextEnd
; flickers the two screens for 460 x 2 frames, then FcVictory fades to white and shows the Victory screen, and the
; program stops in FcEnd (the music plays on).
; --------------------------------------------------------------------------------------------------------------------

; the interrupt: one frame of the tune
;
; Mode 2 vector $6060 (the table at $5B00 holds $60). Saves every register,
; pages bank 7 ($17), calls the player's frame (Pt3PlayEntry) and pages $10
; (bank 0, the normal screen) back; the main loop pages again after its HALT.
FcInterrupt:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  EXX
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,$17
  CALL FcPage
  CALL Pt3PlayEntry
  LD A,$10
  CALL FcPage
  POP HL
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  EXX
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RET

; free space, zero
FcSpare:
  DEFS $011C

; Final Cut: the caption, the alien and the scroll
;
; Entered from the HRUM depacker (the game's GameWon) with interrupts off.
; Never returns.
FinalCut:
  DI
  CALL FcBlack            ; black: border and attributes
  LD A,$17                ; bank 7 at $C000
  CALL FcPage
  LD HL,Bank7Block        ; the alien screen, the PT3 player and the tune to
                          ; bank 7 ($3578 bytes)
  LD DE,AlienGreenScreen
  LD BC,$3578
  LDIR
  CALL Pt3Init              ; start the tune
  LD A,$10                ; bank 0 back, the normal screen shown
  CALL FcPage
  LD HL,$5B00             ; the vector table at $5B00: 257 bytes of $60, so the
                          ; vector is $6060 (FcInterrupt)
  LD DE,$5B01
  LD (HL),$60
  LD BC,$0100
  LDIR
  LD A,$5B                ; I = $5B, interrupt mode 2
  LD I,A
  IM 2
  EI
  HALT
  LD HL,CaptionScreen             ; the caption screen
  LD DE,$4000
  LD BC,$1B00
  LDIR
  LD BC,$0500             ; for $500 frames (26.2 s at the Pentagon's 48.83 Hz)
FcCaptionWait:
  HALT
  DEC BC
  LD A,B
  OR C
  JR NZ,FcCaptionWait
  CALL FcBlack            ; black again
  LD A,$10
  CALL FcPage
  LD HL,AlienMagentaScreen             ; the magenta alien screen (the green one is in bank
                          ; 7 at $C000)
  LD DE,$4000
  LD BC,$1B00
  LDIR
  LD HL,Bank7Block        ; the line table over Bank7Block (copied already):
                          ; for each of the 192 pixel lines of the $C000
                          ; window, its address and the next line's
  LD DE,$C000
  LD B,$C0
FcLineTableLoop:
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  CALL FcNextLine
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DJNZ FcLineTableLoop
FcScrollFrame:
  EI                      ; a frame of the scroll
  HALT
FcDrawPage:
  LD A,$17                ; the page to draw on: $17 (bank 7, the shadow
                          ; screen) and $1D (bank 5, the normal screen) in turn
                          ; (the operand)
  CALL FcPage
  XOR $0A
  LD (FcDrawPage+$0001),A
  CALL FcScroll           ; scroll it and draw the next pixel row of the text
FcShowPage:
  LD A,$10                ; the screen to show: $10 (normal) and $18 (shadow)
                          ; in turn (the operand), with bank 0
  CALL FcPage
  PUSH AF
  XOR $08
  LD (FcShowPage+$0001),A
  POP AF
  OR $07                  ; and bank 7 paged with it
  CALL FcPage
  JP FcScrollFrame

; the end: loop forever (the tune plays on from the interrupt)
;
; Used by the routine at FcTextEnd.
FcEnd:
  JR FcEnd

; scroll the left half (16 bytes) of the screen at $C000 up a pixel line, and
; the text's next pixel row
;
; SP walks the line table (POP DE the line, POP HL the line below it; 16 LDI a
; line, 3 lines a pass, until BC = 192 x 16 runs out), then SP comes back. A
; counts the glyph's pixel rows (0-15) in the operand of FcRow; at row 0 the
; text pointer (FcTextPtr+1) moves on 8 characters. A 0 there is the text's
; end: the bottom attribute row of both screens' left half is cleared and
; FcTextEnd takes over (the return address is dropped there); else FcDrawRow
; draws the row.
FcScroll:
  LD (FcScrollSp+$0001),SP ; SP into FcScrollSp's operand
  LD BC,$0C00
  LD SP,Bank7Block        ; SP = the line table
FcScrollLoop:
  POP DE
  POP HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  POP DE
  POP HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  POP DE
  POP HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  JP PE,FcScrollLoop
FcScrollSp:
  LD SP,$0000             ; the operand: SP as it was
FcRow:
  LD A,$0F                ; the glyph's pixel row, 0-15 (the operand)
  INC A
  AND $0F
  LD (FcRow+$0001),A
  JP NZ,FcTextPtr
  LD HL,(FcTextPtr+$0001) ; a new row of text: the next 8 characters
  LD DE,$0008
  ADD HL,DE
  LD (FcTextPtr+$0001),HL
FcTextPtr:
  LD HL,ScrollText-8      ; the text row (the operand; it starts 8 before
                          ; ScrollText, so the first row is ScrollText's)
  PUSH AF
  LD A,(HL)               ; 0: the end of the text
  OR A
  JP NZ,FcDrawRow
  LD HL,$5AE0             ; clear the bottom attribute row's 16 cells of the
                          ; normal screen
  LD D,H
  LD E,L
  INC E
  LD (HL),A
  LD BC,$000F
  PUSH BC
  LDIR
  LD A,$17                ; and of the shadow one (bank 7)
  CALL FcPage
  POP BC
  LD HL,$DAE0
  LD D,H
  LD E,L
  INC E
  LD (HL),B
  LDIR
  LD A,$10
  CALL FcPage
  JP FcTextEnd

; 6 bytes no path reaches: LD HL,ScrollText : LD (FcTextPtr+1),HL, which would
; start the text again
FcRewind:
  DEFB $21,$5C,$64,$22,$C6,$62

; draw pixel row A of the 8 characters at HL into the bottom line of the $C000
; window
;
; The row's 2 bytes of each glyph (ScrollFont + (code - $20) x 32 + row x 2) go
; to the 16 bytes of pixel line 191 ($D7E0 through the window), one LDI pair a
; character.
FcDrawRow:
  LD DE,$D7E0             ; pixel line 191 of the window
  POP AF
  ADD A,A                 ; IXL = the row's offset in a glyph (2 bytes a row)
  LD IXL,A
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  POP HL
  INC HL
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  POP HL
  INC HL
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  POP HL
  INC HL
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  POP HL
  INC HL
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  POP HL
  INC HL
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  POP HL
  INC HL
  PUSH HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  POP HL
  INC HL
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,ScrollFont-$20*32
  ADD HL,BC
  LD A,L
  ADD A,IXL
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LDI
  LDI
  RET

; DE = the screen address of the pixel line below DE
;
; Used by the routine at FinalCut.
FcNextLine:
  INC D
  LD A,D
  AND $07
  RET NZ
  LD A,E
  ADD A,$20
  LD E,A
  RET C
  LD A,D
  SUB $08
  LD D,A
  RET

; A to the paging port $7FFD (BC kept)
;
; Used by the routines at FcInterrupt, FinalCut, FcScroll and FcTextEnd.
FcPage:
  PUSH BC
  LD BC,$7FFD
  OUT (C),A
  POP BC
  RET

; the text is done: flicker the two screens, then the Victory screen
;
; Drops FcScroll's return address (the POP AF of the row count), shows the
; shadow and the normal screen in turn for $1CC x 2 frames (18.4 s; the alien
; flickers between green and magenta), then FcVictory and FcEnd.
FcTextEnd:
  POP AF
  LD BC,$01CC
FcFlickerLoop:
  HALT
  LD A,$18
  CALL FcPage
  HALT
  LD A,$10
  CALL FcPage
  DEC BC
  LD A,B
  OR C
  JR NZ,FcFlickerLoop
  CALL FcVictory
  JP FcEnd

; black: the border and every attribute
;
; Waits for a frame first (EI, HALT).
FcBlack:
  EI
  HALT
  XOR A
  OUT ($FE),A
  LD HL,$5800
  LD D,H
  LD E,L
  INC E
  LD (HL),A
  LD BC,$02FF
  LDIR
  RET

; clear the screen, fade it to white, then the Victory screen
;
; Clears pixels and attributes from $5AFF down to the ROM (as Dead End's
; ClearScreen), then FcFadeStep with the eight FcFadeColours (black to white, 2
; frames each), then copies VictoryScreen to $4000.
FcVictory:
  EI
  XOR A
  OUT ($FE),A
  LD HL,$5B00
FcClearLoop:
  DEC HL
  LD (HL),A
  OR (HL)
  JR Z,FcClearLoop
  LD HL,FcFadeColours
  LD B,$08
FcFadeLoop:
  PUSH BC
  PUSH HL
  CALL FcFadeStep
  POP HL
  POP BC
  INC HL
  DJNZ FcFadeLoop
  LD HL,VictoryScreen
  LD DE,$4000
  LD BC,$1B00
  LDIR
  RET

; every attribute and the border to the colour at HL, then 2 frames
;
; Used by the routine at FcVictory.
FcFadeStep:
  LD A,(HL)
  LD HL,$5800
  LD (HL),A
  AND $07
  OUT ($FE),A
  LD D,H
  LD E,L
  INC E
  LD BC,$02FF
  LDIR
  HALT
  HALT
  RET

; the fade's attributes: paper = ink = 0-7 (black .. white)
FcFadeColours:
  DEFB $00,$09,$12,$1B,$24,$2D,$36,$3F

; the scroll text: 167 rows of 8 characters, then 0
ScrollText:
  INCBIN "res/text/scroll.bin",$0000,1337

; the scroll font: 59 glyphs ($20-$5A), 16 x 16 pixels, 2 bytes a row
ScrollFont:
  INCBIN "res/fonts/scroll.bin",$0000,1888
