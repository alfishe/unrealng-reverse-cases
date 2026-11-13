; --------------------------------------------------------------------------------------------------------------------
; print.asm: Waits, attribute boxes and PrintText: the strip of seven pixel lines revealed by a dissolve
;
; PrintText $9D72 reads its parameters after the CALL: the font (0: FontSmall $9ED2, 37 glyphs A-Z, space, 0-9; else
; FontLarge $9FFA, 27 glyphs A-Z, space), the start byte in a 32-byte line, a pixel shift 0-7, the screen line (an
; index of ScreenLineTable: 68, 84, 100, 116 for the box's four text lines), then the text up to a zero byte; the code
; goes on after the zero. It draws the text into TextBuffer $5B00 (cleared, 32 bytes a line) with proportional glyphs
; (each glyph: a width mask byte and 7 rows), then RevealStrip $9E4D copies the buffer's columns 7-24 of lines 0-6 to
; the screen in 8 dissolve steps of two frames each (16 frames a line), each step merging more of the new bytes under
; masks picked by ROM bytes, so the old line dissolves into the new one. ClearTextLine $9D65 prints a single space on
; a line: the empty buffer dissolves the line away.
;
; FillAttrBox $9D31 reads five bytes after its CALL: column, row, width, height, attribute. WaitOrSpace $9BA5 waits BC
; x 2 frames with the shimmer and the box colours; SPACE held at the end of a pass drops its caller's return.
; --------------------------------------------------------------------------------------------------------------------

  ORG $9BA5

; Wait BC passes of two frames with the effects; SPACE returns to the caller's
; caller
;
; In: BC = passes. A pass: HALT, ShimmerFrame, PaintBoxColours, HALT, ReadSpace
; $9D29. SPACE held: POP BC, POP HL (the caller's return dropped), RET: the
; caller's caller goes on (CreditsLoop returns to FrontMain). Else BC - 1 until
; 0, RET.
;
; c1 (the front's bytes): 32 passes, frames 7969-8063, the abort once (SPACE,
; frame 8063). menu: 100 passes, no abort (frames 172-1290).
;
; Witness: L1 289 (c1, menu, rzx-r0).
WaitOrSpace:
  PUSH BC
  HALT
  CALL ShimmerFrame
  CALL PaintBoxColours
  HALT
  CALL ReadSpace
  JP Z,WaitAbort
WaitCount:
  POP BC                  ; no SPACE: count down
  DEC BC
  LD A,B
  OR C
  JP NZ,WaitOrSpace
  RET
WaitAbort:
  POP BC                  ; SPACE: drop the caller's return
  POP HL
  RET

; Wait BC frames (HALT each)
;
; In: BC = frames. c1: 20 frames for ShowLogo (frames 7828-7848; $9BBF 20
; runs).
;
; Witness: L1 40 (c1, rzx-r0).
WaitFrames:
  HALT
  DEC BC
  LD A,B
  OR C
  JP NZ,WaitFrames
  RET

  ORG $9D29

; Z if SPACE is held (port $7FFE bit 0)
;
; c1 (the front's bytes): 32 runs; menu: 100 (each from WaitOrSpace).
;
; Witness: L1 289 (c1, menu, rzx-r0).
ReadSpace:
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  RET

; Fill a box of attributes; its five parameters follow the CALL: column, row,
; width, height, attribute
;
; Pops the return address into IY, fills height rows of width bytes from
; Attributes + 32 x row + column with the attribute, then returns past the five
; bytes (IY + 5 pushed, RET). Callers: PaintBoxColours $7971 (every two
; frames), MenuHighlight, JoystickHighlight, ClearScreen.
;
; c1 (the front's bytes): 443 runs; menu: 814.
;
; Witness: L1 3853 (c1, joystick, menu, rzx-r0).
FillAttrBox:
  POP IY
  LD L,(IY+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,L
  ADD A,(IY+$00)
  LD L,A
  LD BC,Attributes
  ADD HL,BC
  LD B,(IY+$03)
FillAttrRow:
  PUSH BC                 ; one row of width bytes
  PUSH HL
  LD B,(IY+$02)
  LD A,(IY+$04)
FillAttrByte:
  LD (HL),A               ; one byte
  INC L
  DJNZ FillAttrByte
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ FillAttrRow
  LD BC,$0005
  ADD IY,BC
  PUSH IY
  RET

; Wipe one text line of the box: print one space on line A
;
; In: A = the screen line (68, 84, 100 or 116). Patches BlankLineLine and calls
; PrintText: the buffer is cleared and holds no glyph, so RevealStrip dissolves
; the 7 lines (columns 7-24) to paper. 16 frames.
;
; c1 (the front's bytes): 8 runs; menu: 12.
;
; Witness: L1 72 (c1, joystick, menu, rzx-r0).
ClearTextLine:
  LD (BlankLineLine),A
  CALL PrintText

; PrintText: small font, byte 0, line patched by ClearTextLine: one space
BlankLineText:
  INCBIN "res/front-texts/blank-line.bin",$0000,3
BlankLineLine:
  INCBIN "res/front-texts/blank-line.bin",$0003,3

; ClearTextLine's RET after its string
;
; PrintText returns here. c1 and menu run it with every ClearTextLine.
;
; Witness: L1 72 (c1, joystick, menu, rzx-r0).
ClearTextLineDone:
  RET

; Print the text after the CALL into TextBuffer and reveal it on its screen
; line; return after its zero byte
;
; In: (SP) = the parameters: font, start byte, pixel shift, screen line, text,
; 0. FontBase $A0D7 := FontSmall $9ED2 for font 0, else FontLarge $9FFA;
; TextBuffer $5B00-$5BFF := 0; D, E = $5B, the start byte; PixelShift $A0D2 :=
; the shift; TextLine $A0D3 := the line. Each character: 0 ends; "A"-"Z" give
; glyph 0-25; a space glyph 26; any other byte under "A": byte - $30 + $5C -
; $41 (the digits 0-9: glyphs 27-36). The glyph's 8 bytes at FontBase + 8 x
; glyph: GlyphMask $A0D4 := its width mask, its 7 rows into GlyphRows $7600
; (each followed by a zero byte), shifted right PixelShift times through the
; pair, ORed into the buffer at DE, DE + 32 a row. AdvanceColumn $9E24 moves
; the pen by the glyph's width + 1 pixels. At the end: RevealStrip $9E4D with A
; = TextLine, then RET past the zero byte (IY pushed).
;
; c1 (the front's bytes): 14 calls, frames 8007-8539; menu: 27 (DEFINE KEYS's
; prompts and names, the menu's lines, the wipes).
;
; Witness: L1 146 (c1, joystick, menu, rzx-r0).
PrintText:
  POP IY
  LD A,(IY+$00)
  LD HL,FontSmall
  CP $00
  JP Z,PrintFontChosen
  LD HL,FontLarge
PrintFontChosen:
  LD (FontBase),HL        ; FontBase chosen
  LD HL,TextBuffer
  LD DE,TextBuffer+1
  LD BC,$0100
  LD (HL),$00
  LDIR
  LD A,$00
  LD (PixelShift),A
  LD D,$5B
  LD E,(IY+$01)
  LD A,(IY+$02)
  LD (PixelShift),A
  LD A,(IY+$03)
  LD (TextLine),A
  LD BC,$0004
  ADD IY,BC
PrintChar:
  LD A,(IY+$00)           ; the next character; 0 ends
  INC IY
  CP $00
  JP Z,PrintTextDone
  CP $41
  JP NC,PrintGlyphNumber
  CP $20
  JP NZ,PrintOtherChar
  LD A,$5B
  JP PrintGlyphNumber
PrintOtherChar:
  SUB $30                 ; a byte under "A" (not a space): byte - $30 + $5C
  ADD A,$5C
PrintGlyphNumber:
  SUB $41                 ; A = the glyph number
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,(FontBase)
  ADD HL,BC
  ADD HL,BC
  LD A,(HL)
  LD (GlyphMask),A
  INC HL
  PUSH DE
  LD DE,GlyphRows
  LD B,$07
PrintCopyRow:
  LD A,(HL)               ; one glyph row into GlyphRows
  LD (DE),A
  INC HL
  INC E
  LD A,$00
  LD (DE),A
  INC E
  DJNZ PrintCopyRow
  POP DE
  PUSH DE
PrintShiftGlyph:
  LD A,(PixelShift)       ; shift the glyph PixelShift pixels right
  CP $00
  JP Z,PrintOrGlyph
  LD C,A
PrintShiftPixel:
  LD HL,GlyphRows         ; one pixel right over the 7 row pairs
  LD B,$07
PrintShiftRow:
  SRL (HL)                ; one row pair
  INC L
  RR (HL)
  INC L
  DJNZ PrintShiftRow
  DEC C
  JP NZ,PrintShiftPixel
PrintOrGlyph:
  LD HL,GlyphRows         ; OR the glyph into the buffer
  LD B,$07
PrintOrRow:
  LD A,(DE)               ; one row pair into the buffer
  OR (HL)
  LD (DE),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC L
  LD A,E
  ADD A,$1F
  LD E,A
  DJNZ PrintOrRow
  POP DE
  CALL AdvanceColumn
  JP PrintChar

; Move the pen right by the glyph's width + 1: PixelShift, and E on a byte
; boundary
;
; C = 9 less the trailing zero bits of GlyphMask (a mask $F8, 5 pixels: C = 6);
; PixelShift + C, and when it reaches 8: E + 1 and PixelShift - 8.
;
; Witness: L1 920 (c1, joystick, menu, rzx-r0).
;
; menu: 156 runs (one a character).
AdvanceColumn:
  LD A,(GlyphMask)
  LD C,$09
AdvanceCountZeros:
  BIT 0,A                 ; one trailing zero bit less
  JP NZ,AdvancePen
  SRL A
  DEC C
  JP AdvanceCountZeros
AdvancePen:
  LD A,(PixelShift)       ; PixelShift + C
  ADD A,C
  CP $08
  JP C,AdvanceStore
  INC DE
  SUB $08
AdvanceStore:
  LD (PixelShift),A       ; store PixelShift
  RET
; This entry point is used by the routine at PrintText.
PrintTextDone:
  PUSH IY                 ; the reveal, then return past the zero
  LD A,(TextLine)
  CALL RevealStrip
  RET

; Copy TextBuffer's 7 lines (columns 7-24) to the screen at line A in 8
; dissolve steps of two frames
;
; In: A = the screen line. RevealLines $A0D5 := ScreenLineTable + 2A. For step
; 0-7: the ADD A,n at $9E98 := $CB + step; HALT, ShimmerFrame, PaintBoxColours,
; HALT; then for the 7 lines and their 18 bytes from column 7: the next ROM
; byte (PixelShift's word as a pointer, from 0 + 1 up) AND $18 picks one of the
; four mask sets of the resident's dissolve masks $F9CB, mask = that set's byte
; for the step; screen := (screen AND NOT mask) OR (buffer AND mask). The masks
; grow to $FF by step 7, so after 16 frames the strip is the buffer's.
;
; c1 (the front's bytes): 14 runs (one a printed line); menu: 27.
;
; Witness: L1 146 (c1, joystick, menu, rzx-r0).
RevealStrip:
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,ScreenLineTable
  ADD HL,BC
  LD (RevealLines),HL
  LD B,$08
RevealStep:
  PUSH BC                 ; one step: the mask offset, two frames with the
                          ; effects
  LD A,$08
  SUB B
  ADD A,$CB
  LD (RevealMaskOffset+$0001),A
  HALT
  CALL ShimmerFrame
  CALL PaintBoxColours
  HALT
  LD IY,(RevealLines)
  LD DE,TextBuffer+7
  LD BC,$0000
  LD (PixelShift),BC
  LD B,$07
RevealLine:
  PUSH BC                 ; one pixel line: 18 bytes from column 7
  LD A,(IY+$00)
  ADD A,$07
  LD L,A
  LD H,(IY+$01)
  INC IY
  INC IY
  LD B,$12
RevealByte:
  PUSH BC                 ; one byte under its mask
  LD BC,(PixelShift)
  INC BC
  LD (PixelShift),BC
  LD A,(BC)
  AND $18
RevealMaskOffset:
  ADD A,$00               ; ADD A,n: n patched to $CB + step at $9E60
  LD C,A
  LD B,$F9
  LD A,(BC)
  LD B,A
  LD A,(DE)
  AND B
  LD C,A
  LD A,B
  XOR $FF
  LD B,A
  LD A,(HL)
  AND B
  OR C
  LD (HL),A
  INC DE
  INC HL
  POP BC
  DJNZ RevealByte
  EX DE,HL
  LD BC,$000E
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ RevealLine
  POP BC
  DJNZ RevealStep
  RET

; Black attributes and a blank bitmap: the whole screen cleared (START GAME)
;
; FillAttrBox (column 0, row 0, 32 x 25, 0): the 25th row's 32 bytes go to
; $5B00-$5B1F (TextBuffer), then the bitmap $4000-$57FF := 0. Called by
; StartGame $99DD before the resident's stage loader prints PRESS PLAY ON TAPE.
;
; c1: once, frame 8555; menu: once, frame 1552.
;
; Witness: L1 4 (c1, joystick, menu, rzx-r0).
ClearScreen:
  CALL FillAttrBox
  DEFB $00,$00,$20,$19,$00
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  RET
