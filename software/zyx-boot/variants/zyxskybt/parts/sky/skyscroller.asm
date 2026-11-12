; --------------------------------------------------------------------------------------------------------------------
; skyscroller.asm: The scroll text and the code SkySetup copies to $A500
;
; Copied by SkySetup from $7519 to $A500 (over the menu font's old place: the font moved to $A984). Every frame
; SkyFrame scrolls the text one pixel through a 10-byte window in the picture (char row 20), moves two blinking
; markers up and down over it, waves the bars and plays the music.
; --------------------------------------------------------------------------------------------------------------------

; The scroll text, enciphered: ScrollInit turns each byte e into CPL(RRCA e)
; XOR $66 in place
;
; The plain text is texts/sky-scroll.txt (tools/res_variants.py writes it and
; enciphers it back): the firm's advertisement in Russian (KOI-7: the codes
; $60-$7F are Cyrillic letters), Skynet in Taganrog, telephone 66-33-1, ending
; with the code $01 (the gap, then the text again). The plain bytes must sum to
; $AA (mod 256), or ScrollInit hangs: a changed text needs a balancing byte.
ScrollText:
  INCBIN "res/texts/sky-scroll.bin",$0000,432

; Set the scroller's variables, decipher ScrollText in place and check its sum
;
; IX = ScrollVars; the gap counter and its start $AA; the text pointer one
; before ScrollText with 16 columns done (a new letter next), the mask $80. A
; sum other than $AA runs LD A,R / PUSH AF for ever: the stack runs down over
; the memory.
ScrollInit:
  LD IX,ScrollVars
  LD H,$AA
  LD (IX+$0C),H
  LD (IX+$0D),H
  LD HL,ScrollText-1
  LD (IX+$01),H
  LD (IX+$00),L
  LD (IX+$02),$10
  LD (IX+$05),$80
  INC HL
  LD E,$00
  LD BC,$01B0
ScrollDecipher:
  LD A,(HL)
  RRCA
  CPL
  XOR $66
  LD (HL),A
  ADD A,E
  LD E,A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,ScrollDecipher
  LD A,E
  CP $AA
  JR Z,ScrollInitBase
ScrollHang:
  LD A,R
  PUSH AF
  JR ScrollHang
ScrollInitBase:
  LD HL,CyrillicGlyphs             ; the glyph base for $60-$7F
  LD (IX+$07),H
  LD (IX+$06),L
  RET

; Scroll the window one pixel left and shift in the next pixel column of the
; current letter
;
; Letters are drawn double size: each glyph row on two pixel rows, each glyph
; column twice (the mask turns every second step), 16 steps a letter. After 16
; it takes the next text byte: a code below $60 is a glyph of the moved menu
; font (FontGlyphs + 8 x code), $60-$7F a Cyrillic one (CyrillicGlyphs + 8 x
; code). The code $01 counts the gap counter down and shows a space while it is
; not 0 (the text stays on the $01): $A9 spaces, then the counter is set again
; and the text starts over.
ScrollStep:
  LD A,(IX+$02)
  CP $10
  JR Z,ScrollNextLetter
  LD D,(IX+$04)
  LD E,(IX+$03)
  JR ScrollColumn
ScrollNextLetter:
  LD (IX+$02),$00
  LD B,(IX+$01)
  LD C,(IX+$00)
  INC BC
  LD (IX+$01),B
  LD (IX+$00),C
ScrollNextByte:
  LD A,(BC)
  CP $01
  JR NZ,ScrollGlyph
  DEC (IX+$0C)
  LD A,(IX+$0C)
  AND A
  JR Z,ScrollRestart
  DEC BC
  LD (IX+$01),B
  LD (IX+$00),C
  LD A,$20
  JR ScrollGlyph
ScrollRestart:
  LD H,(IX+$0D)
  LD (IX+$0C),H
  LD BC,ScrollText
  LD (IX+$01),B
  LD (IX+$00),C
  JR ScrollNextByte
ScrollGlyph:
  LD H,$00
  LD L,A
  LD B,$03
l_A744:
  ADD HL,HL
  DJNZ l_A744
  CP $60
  JR C,ScrollMenuGlyph
  LD D,(IX+$07)
  LD E,(IX+$06)
  JR ScrollGlyphAt
ScrollMenuGlyph:
  LD DE,FontGlyphs
ScrollGlyphAt:
  ADD HL,DE
  EX DE,HL
ScrollColumn:
  LD C,(IX+$05)
  LD B,$01
l_A75D:
  PUSH BC
  LD HL,ScrollRow
  PUSH DE
  LD B,$08
ScrollColumnRow:
  PUSH BC
  LD B,$02
ScrollColumnLine:
  PUSH BC
  PUSH HL
  LD A,(DE)
  AND C                   ; carry = the glyph's bit
  CPL
  CP $FF
  LD B,$0A
ScrollRollRow:
  RL (HL)
  DEC HL
  DJNZ ScrollRollRow
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,ScrollRowNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,ScrollRowNext
  LD A,H
  SUB $08
  LD H,A
ScrollRowNext:
  POP BC
  DJNZ ScrollColumnLine
  INC DE
  POP BC
  DJNZ ScrollColumnRow
  POP DE
  POP BC
  INC (IX+$02)
  LD A,(IX+$02)
  RRA
  JR C,ScrollColumnNext
  RRC C
ScrollColumnNext:
  DJNZ l_A75D
  LD (IX+$04),D
  LD (IX+$03),E
  LD (IX+$05),C
  RET

; Put the two markers at their first places: column 7, line 4 of char row 21,
; going down; column 24, line 3 of row 21, going up ($D3B8: bit 7 set = up)
;
; Used by the routine at SkyScrollSetup.
MarkersInit:
  LD HL,$54A7
  LD (IX+$09),H
  LD (IX+$08),L
  LD HL,$D3B8
  LD (IX+$0B),H
  LD (IX+$0A),L
  RET

; Blink and move both markers one pixel row
;
; Used by the routine at SkyFrame.
MoveMarkers:
  LD H,(IX+$09)
  LD L,(IX+$08)
  CALL MarkerStep
  CALL MarkerTurn
  LD (IX+$09),H
  LD (IX+$08),L
  LD H,(IX+$0B)
  LD L,(IX+$0A)
  CALL MarkerStep
  CALL MarkerTurn
  LD (IX+$0B),H
  LD (IX+$0A),L
  RET

; XOR $18 (two pixels) into the marker's byte (HL without bit 7), then one
; pixel row up (bit 7 set) or down
;
; The XOR draws the dot on one pass and wipes it on the next: each marker draws
; a blinking two-pixel line as it moves.
MarkerStep:
  PUSH HL
  LD A,H
  AND $7F
  LD H,A
  LD A,$18
  XOR (HL)
  LD (HL),A
  POP HL
  BIT 7,H
  JR Z,SkyRowDown

; HL one pixel row up the screen
;
; Used by the routine at MarkerTurn.
SkyRowUp:
  DEC H
  LD A,H
  AND $07
  CP $07
  JR NZ,SkyRowUpDone
  LD A,L
  SUB $20
  LD L,A
  JR C,SkyRowUpDone
  LD A,H
  ADD A,$08
  LD H,A
SkyRowUpDone:
  RET

; HL one pixel row down the screen (also for the menu's StarStep, code switch
; sky-stars)
;
; Used by the routines at MarkerStep and MarkerTurn.
SkyRowDown:
  INC H
  LD A,H
  AND $07
  JR NZ,SkyRowDownDone
  LD A,L
  ADD A,$20
  LD L,A
  JR C,SkyRowDownDone
  LD A,H
  SUB $08
  LD H,A
SkyRowDownDone:
  RET

; Turn a marker round at its ends: going up at line 2 of char row 20, going
; down at line 5 of char row 22 (the row bits only: the third is left as it is)
;
; Used by the routine at MoveMarkers.
MarkerTurn:
  BIT 7,H
  JR Z,MarkerTurnDown
  LD A,L
  AND $E0
  CP $80
  RET NZ
  LD A,H
  AND $07
  CP $02
  RET NZ
  RES 7,H
  CALL SkyRowDown
  RET
MarkerTurnDown:
  LD A,L
  AND $E0
  CP $C0
  RET NZ
  LD A,H
  AND $07
  CP $05
  RET NZ
  SET 7,H
  CALL SkyRowUp
  RET

; Copy CyrillicFont to CyrillicCopy $9C00, clear $6FE0-$9BFF (the picture, the
; font and the copied code: all used up), then ScrollInit and MarkersInit
SkyScrollSetup:
  LD HL,CyrillicFont
  LD DE,CyrillicCopy
  LD BC,$0100
  LDIR
  LD HL,SkyPicture
  LD DE,SkyPicture+1
  LD BC,$2C1F
  LD (HL),$00
  LDIR
  CALL ScrollInit
  CALL MarkersInit
  RET

; unused
ScrollerSpare:
  DEFS $05

; The interrupt's work (code switch sky-screen calls it in place of MusicPlay):
; ScrollStep, MoveMarkers, SkyBars, then MusicPlay
SkyFrame:
  LD IX,ScrollVars
  CALL ScrollStep
  CALL MoveMarkers
  CALL SkyBars
  CALL MusicPlay
  RET

; MoveStars' first step: load the star's address; a star over the logo or the
; picture is moved but not drawn
;
; Reached by JP from MoveStars (code switch sky-stars); it pushes the return to
; MoveStarsLoaded, so RET goes on as before. A star in columns 6-25 of char
; rows 0-4 (the logo) or 20-23 (the picture) drops that return and goes to
; MoveStarsHidden. The five NOPs are an emptied instruction.
SkyStarClip:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD DE,MoveStarsLoaded
  PUSH DE
  LD A,H
  AND $08
  RET NZ
  LD A,H
  AND $18
  JR Z,SkyStarTop
  LD A,L
  AND $E0
  CP $80
  RET C
  JR SkyStarColumn
SkyStarTop:
  LD A,L
  NOP
  NOP
  NOP
  NOP
  NOP
  CP $A0
  RET NC
SkyStarColumn:
  LD A,L
  AND $1F
  CP $06
  RET C
  CP $1A
  RET NC
  POP DE
  JP MoveStarsHidden

; In place of CheckTwinkleSpot (code switch sky-stars): carry set if the
; twinkle may go to the place (HL)
;
; Allowed: not the last pixel line of a char row, not column 31, and char rows
; 5-6, 8-14 or 16-18: off the logo, the picture and their surroundings.
SkyTwinkleSpot:
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD A,C
  CP $E0
  RET NC
  LD A,C
  AND $1F
  CP $1F
  RET NC
  LD A,B
  AND $08
  SCF
  RET NZ
  LD A,B
  AND $18
  JR Z,SkyTwinkleTop
  LD A,C
  AND $E0
  CP $60
  RET C
  AND A
  RET
SkyTwinkleTop:
  LD A,C
  AND $E0
  CP $A0
  CCF
  RET
