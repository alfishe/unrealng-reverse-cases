; --------------------------------------------------------------------------------------------------------------------
; effects.asm: the intro's screen effects and colour cycles
;
; The effects of the intro: the colour cycles that run with the scroller, the picture rolled in from a buffer, the
; screen pushed out to the sides, the dissolve of the old screen, the spiral attribute wipe and its delay. They write
; the screen ($4000-$5AFF) directly, with the ROM's PIXEL-ADD for line addresses.
; --------------------------------------------------------------------------------------------------------------------

; Recolour the bottom text row (row 23): each cell the next ink 1-7
;
; Attributes $5AE0-$5AFF: each cell takes the previous cell's colour + 1 (mod
; 8, 0 skipped), from the first cell's own colour + 1: a rainbow of inks over
; "You wanted new levels? Take its!" that moves each call. Called twice a
; scroll (r99 frames 747-1310, 368 calls). A, B, HL changed.
CycleBottomRow:
  LD HL,Attrs+$02E0
  LD B,$20
  LD A,(HL)
BottomRowCell:
  LD (HL),A
BottomRowInk:
  INC A                   ; the next ink, never 0 (black)
  AND $07
  JR Z,BottomRowInk
  LD (HL),A
  INC HL
  DJNZ BottomRowCell
  RET

; Recolour the logo's box: 15 rows of 14 cells, each row the next ink 1-7
;
; Attributes from $5831 (row 1, column 17): row by row each takes the next
; colour (mod 8, 0 skipped) after the box's first cell's: the stripes of the
; logo move up each call. Called once a scroll (184 calls). A, C, DE, HL
; changed; BC kept.
CycleLogoColours:
  PUSH BC
  LD HL,Attrs+$0031
  LD A,(HL)
  LD B,$0F
LogoRow:
  PUSH HL
LogoInk:
  INC A                   ; the next ink, never 0
  AND $07
  JR Z,LogoInk
  LD C,$0E
LogoCell:
  LD (HL),A
  INC HL
  DEC C
  JR NZ,LogoCell
  POP HL
  LD DE,$0020
  ADD HL,DE
  DJNZ LogoRow
  POP BC
  RET

; Print the line at DE at the scroller's bottom row, up to its CR
;
; Prints ScrollText's first three bytes (AT 32,22: column 32 of 64, row 22)
; through PrintChars, then the bytes at DE through PrintChar until a CR ($0D).
; Output: DE past the CR. 24 calls in the window (r99 frames 746-1287).
PrintLine:
  PUSH DE
  LD DE,ScrollText
  LD BC,$0003
  CALL PrintChars
  POP DE
; This entry point is used by the routine at PrintLineFont.
PrintLineChar:
  LD A,(DE)
  INC DE
  CP $0D
  RET Z
  CALL PrintChar
  JR PrintLineChar

; Not reached: CHARS = $7487 (a ROM-layout font at $7587), then PrintLine's
; character loop
;
; Code no recording reached and no instruction of the block jumps to: sets the
; ROM's CHARS ($5C36) to $7487 (or, from PrintLineRom, to the ROM's font $3C00)
; and continues in PrintLine's character loop. A leftover of a version that
; printed through the ROM (the bytes at $7587 are not in the ROM's font layout,
; see Font64). Known only from the code.
PrintLineFont:
  LD HL,Font64-$0100
; This entry point is used by the routine at PrintLineRom.
PrintLineSetChars:
  LD ($5C36),HL
  JR PrintLineChar

; Not reached: CHARS = $3C00 (the ROM's font), then as PrintLineFont
PrintLineRom:
  LD HL,$3C00
  JR PrintLineSetChars

; Show the picture at HL: line y of it fills screen lines 0-y, y from 191 down
; to 0, then its attributes
;
; Input: HL = the picture (screen layout: 6144 pixel bytes, 768 attributes).
; For y = 191 down to 0 the picture's line y is copied into every screen line
; from 0 to y: the picture rolls down from the top, its lower lines first
; stretched over the screen above them. Then the 768 attributes to $5800. The
; pixel lines through the ROM's PIXEL-ADD. Ran once, r99 frames 472-726. A, BC,
; DE, HL changed.
RollInPicture:
  LD (RollInSource),HL
  LD A,$BF
  LD BC,$00C0*$0100
RollInLine:
  PUSH BC
  PUSH AF
  CALL RomPixelAddr              ; HL = screen line y ...
  LD DE,(RollInSource)    ; ... DE = the same line in the picture
  LD A,D
  SUB $40
  LD D,A
  ADD HL,DE
  POP AF
  PUSH AF
  INC A
  LD B,A
  XOR A
RollInCopy:
  PUSH BC                 ; screen lines 0..y = the picture's line y
  PUSH AF
  PUSH HL
  CALL RomPixelAddr
  EX DE,HL
  POP HL
  PUSH HL
  LD BC,$0020
  LDIR
  POP HL
  POP AF
  INC A
  POP BC
  DJNZ RollInCopy
  POP AF
  DEC A
  POP BC
  DJNZ RollInLine
  LD HL,(RollInSource)    ; the attributes
  LD A,$18
  ADD A,H
  LD H,A
  LD DE,Attrs
  LD BC,$0300
  LDIR
  RET

; RollInPicture's picture address
RollInSource:
  DEFW $0000

; Push the screen out: each half shifted one pixel outwards, more lines each
; step
;
; The left half (bytes 0-15 of a line) is shifted left and the right half
; (16-31) right, one pixel a pass (ShiftLinesApart): lines 0..n-1 for n = 1 to
; 191 (the opening runs down the screen), then lines 64-191 128 times more. Ran
; once after SPACE, r99 frames 1312-1953. A, BC, DE, HL changed.
PushOutScreen:
  LD HL,Screen+$000F
  LD B,$01
PushOutStep:
  PUSH HL
  PUSH BC
  CALL ShiftLinesApart
  POP BC
  POP HL
  INC B
  LD A,B
  CP $C0
  JR NZ,PushOutStep
  LD HL,Screen+$080F
  LD B,$80
PushOutEnd:
  PUSH BC
  LD B,$80
  PUSH HL
  CALL ShiftLinesApart
  POP HL
  POP BC
  DJNZ PushOutEnd
  RET

; Shift B screen lines from the one at HL+1 apart by one pixel
;
; Input: HL = the 16th byte of the first line (its left half's last), B = the
; number of lines. Each line: RL through bytes 15 down to 0 (the left half one
; pixel left), RR through bytes 16 to 31 (the right half one pixel right); the
; next line through NextLineDown.
ShiftLinesApart:
  PUSH BC
  PUSH HL
  PUSH HL
  LD B,$10
  XOR A
ShiftLeftHalf:
  RL (HL)
  DEC HL
  DJNZ ShiftLeftHalf
  POP HL
  INC HL
  XOR A
  LD B,$10
ShiftRightHalf:
  RR (HL)
  INC HL
  DJNZ ShiftRightHalf
  POP HL
  CALL NextLineDown
  POP BC
  DJNZ ShiftLinesApart
  RET

; HL = the screen address one pixel line down
;
; The usual INC H, then across a character row or a third.
NextLineDown:
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

; Clear the screen's pixels bit by bit: 250 passes over every 29th byte
;
; HL steps through $4000-$57FF by 29 (wrapping back by $1800); each byte is
; ANDed with C, a mask whose clear bit moves one place each pass ($FE, $FD,
; ...): 250 passes, so every bit of every byte is reached and the old screen's
; pixels fade to nothing in a scattered order. Ran once, r99 frames 261-303. A,
; BC, DE, HL changed.
DissolveScreen:
  LD B,$FA
  LD C,$FE
  LD HL,Screen
  LD DE,$001D
DissolveByte:
  LD A,(HL)
  AND C
  LD (HL),A
  ADD HL,DE
  LD A,H
  CP $58
  JR C,DissolveByte
  SUB $18
  LD H,A
  RLC C
  DJNZ DissolveByte
  RET

; Fill the attributes with A in a spiral from the outside in, one cell a delay
;
; Input: A = the attribute. 12 rings from the corner (0,0): the top row to the
; right, the right column down, the bottom row to the left, the left column up,
; each next ring one cell further in; a Delay500 after each cell. Ran r99
; frames 303-472 (A = 7) and 1953-2114 (A = $38). A', BC, DE, HL changed.
SpiralAttrs:
  LD HL,Attrs
  LD B,$0C
  EX AF,AF'               ; A' = the attribute
SpiralRing:
  PUSH HL
  LD A,B
  ADD A,A
  ADD A,$08
SpiralTop:
  EX AF,AF'
  LD (HL),A
  EX AF,AF'
  INC HL
  DEC A
  CALL Delay500
  JR NZ,SpiralTop
  LD A,B
  ADD A,A
  DEC HL
  LD DE,$0020
SpiralRight:
  EX AF,AF'
  LD (HL),A
  EX AF,AF'
  ADD HL,DE
  DEC A
  CALL Delay500
  JR NZ,SpiralRight
  SBC HL,DE
  LD A,B
  ADD A,A
  ADD A,$08
SpiralBottom:
  EX AF,AF'
  LD (HL),A
  EX AF,AF'
  DEC HL
  DEC A
  CALL Delay500
  JR NZ,SpiralBottom
  INC HL
  LD A,B
  ADD A,A
SpiralLeft:
  EX AF,AF'
  LD (HL),A
  EX AF,AF'
  SBC HL,DE
  DEC A
  CALL Delay500
  JR NZ,SpiralLeft
  POP HL                  ; the next ring starts one cell down and right
  LD DE,$0021
  ADD HL,DE
  DJNZ SpiralRing
  RET

; A delay loop of 500 counts (BC, AF kept)
;
; Used by the routine at SpiralAttrs.
Delay500:
  PUSH BC
  PUSH AF
  LD BC,$01F4
DelayLoop:
  DEC BC
  LD A,B
  OR C
  JR NZ,DelayLoop
  POP AF
  POP BC
  RET

; Not reached: HL = the attribute address of the window at IX, C = its width, B
; = its height
;
; IX as ScrollWindow (column, row, width, height). No instruction of the block
; calls it and no recording ran it: known only from the code.
WindowAttrAddr:
  LD C,(IX+$02)
  LD B,(IX+$03)
  LD A,(IX+$01)
  LD DE,Attrs
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD A,(IX+$00)
  ADD A,L
  LD L,A
  RET

; Scroll the window at IX up by one pixel line; its last line cleared
;
; IX = the window: +0 column, +1 row, +2 width (bytes), +3 height (character
; rows). For each of its height x 8 - 1 lines the next line's bytes are copied
; up (LDIR, addresses through the ROM's PIXEL-ADD), then the last line is
; cleared. 184 calls (r99 frames 746-1309), always ScrollWindow. A, BC, DE, HL
; changed.
ScrollWindowUp:
  LD C,(IX+$00)
  LD B,(IX+$03)
  LD A,(IX+$01)
  SLA A
  SLA A
  SLA A
  SLA B
  SLA B
  SLA B
  DEC B
  SLA C
  SLA C
  SLA C
  PUSH AF
  PUSH BC
  CALL RomPixelAddr
  POP BC
  POP AF
ScrollWindowLine:
  INC A
  PUSH AF
  PUSH BC
  PUSH HL
  CALL RomPixelAddr
  POP DE
  PUSH HL
  LD C,(IX+$02)
  LD B,$00
  LDIR
  POP HL
  POP BC
  POP AF
  DJNZ ScrollWindowLine
  LD (HL),$00             ; the last line cleared
  LD D,H
  LD E,L
  INC DE
  LD A,(IX+$02)
  DEC A
  RET Z
  LD C,A
  LD B,$00
  LDIR
  RET
