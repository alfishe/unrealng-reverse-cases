; --------------------------------------------------------------------------------------------------------------------
; signature.asm: The pen that writes "written by" and the signature
;
; SignatureWrite $BD0C runs the pen script SignatureScript $DA80: one command a byte, a pen step a frame. The pen is a
; sprite of three parts drawn relative to its point (x E, y D): a nib of ten spans (PenNib $BFCC), a 45-degree shaft
; 44 lines long copied from PenShaftImage $BFFE, and an end cap of six spans (PenCap $BFEB). Each step erases the pen
; (PenErase $BE40), plots the ink pixel at (x, y - 1) when the pen is down, moves one pixel and draws the pen again
; (PenDraw $BE2F).
;
; The span drawer PenSpan $BF66 and the shaft routine PenShaftBlock $BEDC are self-modifying: PenDraw writes OR (HL)
; into the three NOPs of PenSpan and a JR 0 into PenShaftBlock (copy the shaft bytes); PenErase writes XOR (HL) and a
; JR to PenShaftClear $BF41 (zero the shaft bytes). The shaft copy jumps into one of four 16-byte-aligned copy loops
; (1-4 bytes a line, PenShaftCopy1 $BF03 .. PenShaftCopy4 $BF33) by the bytes left to the screen's right edge.
; --------------------------------------------------------------------------------------------------------------------

; Run the pen script SignatureScript: "written by" and James Hutchby's
; signature, one pen step a frame
;
; Pen up (PenIsDown $C03F = 0), PenBand $C03E = 0, IX = SignatureScript $DA80,
; the pen at x 16, y 128 (DE = $8010), PenDraw $BE2F, then SignatureCommand
; $BD23 until the end command, which drops this loop's return address and
; leaves through PenErase $BE40 back to PresentsPage $B8C5.
;
; Witness (l1sum.py BD0C BD23 BE05): m1 only, 3 runs (655-4498), 828 commands
; and 1484 steps: two whole scripts (312 commands, 557 steps each, by the
; decoder in 05-editor-notes.md) and a third cut by the SPACE at 4500.
; WALKTHROUGH 6.1: m1 frame 900 (the pen after "written by"), 1500 (the
; signature done).
SignatureWrite:
  EI
  XOR A
  LD (PenIsDown),A
  LD (PenBand),A
  LD IX,SignatureScript
  LD DE,$8010
  CALL PenDraw
SignatureLoop:
  CALL SignatureCommand
  JR SignatureLoop

; One command of the pen script at IX: end, pen up, pen down, dot, or a move of
; n steps
;
; Byte b at IX. High nibble zero, a command (IX + 1): 0 end (pops the caller's
; return, JP PenErase $BE40), 1 pen up (PenIsDown $C03F = 0), 2 pen down (= 1),
; 3 dot: the next two bytes dx, dy (signed) are added to the pen point for one
; PenPlot $BF59 (the dot of an i, a full stop), the point does not move; 4-15
; do nothing (SigCmdOther, never run). High nibble not zero, a move (IX + 1):
; bits 7-6 dy, bits 5-4 dx (each 0, +1, -2, -1 by sign extension; the script
; uses 0, +1, -1), bits 3-0 n steps. Each step: one frame (PresentsFrame $B91B,
; a key aborts), PenErase, PenStep $BE05 (plot at (x, y - 1) if the pen is
; down, then x + dx, y + dy), PenDraw.
;
; The band test: with the pen's y at 96 or more (the whole script keeps the pen
; at y 121-147) the step is plain. For y below 96 other paths slow the pen
; down: y 40-95 ($28-$5F) through PenDraw, PenDelay $BE24 and PenErase, y below
; 40 through SigBandSlow (PenDelay) and PenBand $C03E records the pen leaving
; the band (1 above, 2 below) for a pause (SigBandExitAbove, a 300-loop wait)
; on the next move: no build ran any of them (SigBandBelow .. SigBandSlow,
; l1sum.py: not executed); known only from the code.
;
; Witness: m1 828 calls (655-4499) = two whole scripts of 312 commands (218
; moves, 30 pen up, 30 pen down, 33 dots, the end) and 204 of the third, cut by
; a key; 582 moves (SigMove), 1485 step frames.
SignatureCommand:
  LD A,(IX+$00)
  AND $F0
  JR NZ,SigMove
  LD A,(IX+$00)
  AND $0F
  INC IX
  CP $00
  JR NZ,SigCmdPenUp
  POP HL
  JP PenErase
SigCmdPenUp:
  CP $01
  JR NZ,SigCmdPenDown
  XOR A
  LD (PenIsDown),A
  RET
SigCmdPenDown:
  CP $02
  JR NZ,SigCmdDot
  LD A,$01
  LD (PenIsDown),A
  RET
SigCmdDot:
  CP $03                  ; dx, dy: one pixel, the point stays
  JR NZ,SigCmdOther
  PUSH DE
  LD A,(IX+$00)
  ADD A,E
  LD E,A
  INC IX
  LD A,(IX+$00)
  ADD A,D
  LD D,A
  INC IX
  CALL PenPlot
  POP DE
  RET
SigCmdOther:
  RET                     ; commands 4-15: nothing (never run)
SigMove:
  LD L,A                  ; H = dy, L = dx from bits 7-6 / 5-4, C = n from bits
                          ; 3-0
  AND $C0
  SRA A
  SRA A
  SRA A
  SRA A
  SRA A
  SRA A
  LD H,A
  LD A,L
  SLA A
  SLA A
  AND $C0
  SRA A
  SRA A
  SRA A
  SRA A
  SRA A
  SRA A
  LD L,A
  LD A,(IX+$00)
  INC IX
  AND $0F
  LD C,A
  LD A,(PenBand)
  DEC A
  JR Z,SigBandExitAbove
  DEC A
  JR Z,SigBandExitBelow
SigMoveStep:
  CALL PresentsFrame      ; one frame a step
  LD A,D
  CP $60
  JR NC,SigStepDraw
  CP $28
  JR C,SigBandSlow
  CALL PenDraw
  CALL PenDelay
  CALL PenErase
  CALL PenStep
  LD A,C
  OR A
  JR NZ,SigBandCheck
  LD A,D
  CP $28
  JR NC,SigBandBelow
  LD A,$01
  LD (PenBand),A
  RET
SigBandBelow:
  CP $60                  ; never run: y left the band downwards
  RET C
  LD A,$02
  LD (PenBand),A
  RET
SigBandCheck:
  LD A,D                  ; never run
  CP $60
  JR NC,SigBandExitBelow
  CP $28
  JR C,SigBandExitAbove
  JR SigMoveStep
SigBandExitBelow:
  CALL PresentsFrame      ; never run
  XOR A
  LD (PenBand),A
  JR SigStepNext
SigBandExitAbove:
  CALL PresentsFrame      ; never run: a pause of 300 loops
  XOR A
  LD (PenBand),A
  CALL PenDraw
  PUSH BC
  LD BC,$012C
SigBandPause:
  DEC BC
  LD A,B
  OR C
  JR NZ,SigBandPause
  POP BC
  JR SigStepDraw
SigBandSlow:
  CALL PenDelay           ; never run: the step delayed by PenDelay
SigStepDraw:
  CALL PenErase           ; erase the pen, step, draw it
  CALL PenStep
SigStepNext:
  CALL PenDraw
  LD A,C
  OR A
  RET Z
  JR SigMoveStep

; One step of the pen: plot (E, D - 1) if the pen is down, then D + H, E + L; C
; - 1
;
; C = the steps left, H / L = dy / dx. With PenIsDown $C03F set, PenPlot $BF59
; at (x, y - 1), the pixel just above the nib's tip. B = 1: one step per call.
; m1 1484 calls.
PenStep:
  LD A,C
  OR A
  RET Z
  LD B,$01
PenStepLoop:
  PUSH BC
  LD A,(PenIsDown)
  OR A
  JR Z,PenStepMove
  PUSH HL
  DEC D
  CALL PenPlot
  INC D
  POP HL
PenStepMove:
  LD A,D
  ADD A,H
  LD D,A
  LD A,E
  ADD A,L
  LD E,A
  POP BC
  DEC C
  RET Z
  DJNZ PenStepLoop
  RET

; A busy wait of 900 loops (the band's slow step; never run)
;
; Called from SigBandSlow $BDF4 only; no build ran it.
PenDelay:
  PUSH BC
  LD BC,$0384
PenDelayLoop:
  DEC BC
  LD A,B
  OR C
  JR NZ,PenDelayLoop
  POP BC
  RET

; Draw the pen at (E, D): spans OR, shaft copied
;
; Writes JR 0 at PenShaftBlock $BEDC (copy path) and OR (HL) ($B6) into
; PenSpanOp1-3 ($BF93, $BFA1, $BFAE), then PenRender $BE50. m1 1487 calls.
PenDraw:
  XOR A
  LD (PenShaftBlock+$0001),A
  LD A,$B6
  LD (PenSpanOp1),A
  LD (PenSpanOp2),A
  LD (PenSpanOp3),A
  JR PenRender

; Erase the pen at (E, D): spans XOR, shaft cleared
;
; Writes JR $63 at PenShaftBlock $BEDC (to PenShaftClear $BF41) and XOR (HL)
; ($AE) into PenSpanOp1-3, then PenRender: PenShape $BE5A with HL, BC, DE kept.
; m1 1486 calls.
PenErase:
  LD A,$63
  LD (PenShaftBlock+$0001),A
  LD A,$AE
  LD (PenSpanOp1),A
  LD (PenSpanOp2),A
  LD (PenSpanOp3),A
; This entry point is used by the routine at PenDraw.
PenRender:
  PUSH HL                 ; PenShape with HL, BC, DE kept (PenDraw jumps here)
  PUSH BC
  PUSH DE
  CALL PenShape
  POP DE
  POP BC
  POP HL
  RET

; The pen's three parts at (E, D): nib spans, shaft from (E + 5, D + 10), cap
; spans
;
; PenSpans $BE79 with PenNib $BFCC; returns at once if x + 5 passes 255 or y +
; 10 reaches 192; PenShaftPos $C040 = (x + 5, y + 10), PenShaft $BE9F; then
; PenSpans with PenCap $BFEB. m1 2973 calls.
PenShape:
  LD HL,PenNib
  CALL PenSpans
  LD A,E
  ADD A,$05
  LD L,A
  RET C
  LD A,D
  ADD A,$0A
  LD H,A
  CP $C0
  RET NC
  LD (PenShaftPos),HL
  PUSH DE
  CALL PenShaft
  POP DE
  LD HL,PenCap
  JR PenSpans

; Draw the span list at HL relative to (E, D): records dx, dy, length, $FF end;
; clipped right and bottom
;
; Each record: the span at (x + dx, y + dy) of the given length by PenSpan
; $BF66 (OR or XOR as set), the length cut at the right edge; a span past the
; bottom (y 192) or past x 255 ends the list. m1 5946 calls, 40 732 spans.
PenSpans:
  LD A,(HL)
  CP $FF
  RET Z
  PUSH DE
  ADD A,E
  LD E,A
  JR C,PenSpansClip
  INC HL
  LD A,(HL)
  ADD A,D
  LD D,A
  CP $C0
  JR NC,PenSpansClip
  INC HL
  LD B,(HL)
  INC HL
  PUSH HL
  LD A,E
  ADD A,B
  JR NC,PenSpansDraw
  NEG
  ADD A,B
  LD B,A
PenSpansDraw:
  CALL PenSpan
  POP HL
  POP DE
  JR PenSpans
PenSpansClip:
  POP DE
  RET

; The pen's shaft: 44 lines down-right from PenShaftPos, in blocks that end on
; character-cell lines
;
; From PenShaftPos $C040: blocks of up to 8 lines (the first to the end of its
; character row), each by PenShaftBlock $BEDC; x and y both advance by the
; block's lines (45 degrees); stops at the bottom of the screen or when x
; wraps. 44 lines in all ($2C). m1 2973 calls.
PenShaft:
  LD HL,(PenShaftPos)
  LD C,H
  CALL PenPixelAddress
  LD A,C
  AND $07
  ADD A,H
  LD H,A
  LD A,C
  CPL
  AND $07
  INC A
  LD B,A
  NEG
  ADD A,$2C
  LD C,A
PenShaftLoop:
  PUSH BC
  CALL PenShaftBlock
  POP BC
  LD HL,(PenShaftPos)
  LD A,H
  ADD A,B
  LD H,A
  CP $C0
  RET NC
  LD A,L
  ADD A,B
  LD L,A
  RET C
  LD (PenShaftPos),HL
  CALL PenPixelAddress
  LD A,C
  CP $08
  JR C,PenShaftLast
  LD B,$08
  SUB B
  LD C,A
  JR PenShaftLoop
PenShaftLast:
  OR A
  RET Z
  LD B,A

; B lines of the shaft at PenShaftPos: copy from PenShaftImage (draw) or zero
; them (erase), self-modified
;
; The JR at $BEDC is the switch: displacement 0 (PenDraw) runs the copy, $63
; (PenErase) jumps to PenShaftClear $BF41. Copy: HL = PenShaftImage $BFFE + 4
; (x AND 7), DE the screen; the bytes to copy are 1-4 (fewer at columns 29-31:
; the bytes left to the right edge, at most 3, plus one), written as 16 times
; (that count - 1) into the displacement of the JR at PenShaftJump $BF01, which
; lands on PenShaftCopy1-4 ($BF03, $BF13, $BF23, $BF33). Each line takes the
; next 4-byte row of the image (the shaft moves one pixel right a line). m1 18
; 215 calls; only PenShaftCopy4 ran (the pen never came near the right edge).
PenShaftBlock:
  JR PenShaftCopyPath
PenShaftCopyPath:
  LD A,(PenShaftPos)
  AND $07
  ADD A,A
  ADD A,A
  LD DE,PenShaftImage
  ADD A,E
  LD E,A
  JR NC,PenShaftWidth
  INC D
PenShaftWidth:
  LD C,$FF                ; bytes to the right edge, at most 3
  EX DE,HL
  LD A,E
  CPL
  AND $1F
  CP $03
  JR C,PenShaftBytes
  LD A,$03
PenShaftBytes:
  ADD A,A                 ; x 16 into the JR below
  ADD A,A
  ADD A,A
  ADD A,A
  LD (PenShaftJump+$0001),A
PenShaftJump:
  JR PenShaftCopy1        ; JR to PenShaftCopy1 + 16 (bytes - 1)
PenShaftCopy1:
  LD A,(HL)               ; one byte a line (never run)
  LD (DE),A
  INC D
  INC HL
  INC HL
  INC HL
  INC HL
  DJNZ PenShaftCopy1
  RET

; Six zero bytes that align PenShaftCopy2 at PenShaftCopy1 + 16
;
; Never read or executed (l1sum.py --reads BF0D-BF32: no build).
PenShaftPad1:
  DEFB $00,$00,$00,$00,$00,$00

; The shaft copy, two bytes a line (a target of PenShaftJump; never run)
;
; LDI twice, DE back, the next screen line, the next image row; DJNZ. No build
; ran it.
PenShaftCopy2:
  LDI
  LDI
  DEC DE
  DEC DE
  INC D
  INC HL
  INC HL
  DJNZ PenShaftCopy2
  RET

; Four zero bytes of alignment
PenShaftPad2:
  DEFB $00,$00,$00,$00

; The shaft copy, three bytes a line (never run)
;
; As PenShaftCopy2 $BF13 with three LDIs. No build ran it.
PenShaftCopy3:
  LDI
  LDI
  LDI
  DEC DE
  DEC DE
  DEC DE
  INC D
  INC HL
  DJNZ PenShaftCopy3
  RET

; Two zero bytes of alignment
PenShaftPad3:
  DEFB $00,$00

; The shaft copy, four bytes a line
;
; PUSH DE, four LDIs, POP DE, INC D; DJNZ. m1 64 168 lines.
PenShaftCopy4:
  PUSH DE
  LDI
  LDI
  LDI
  LDI
  POP DE
  INC D
  DJNZ PenShaftCopy4
  RET

; Erase B lines of the shaft: zero the bytes up to the right edge (1-4)
;
; The target of PenShaftBlock's JR $63 when PenErase set it. m1 9105 calls, 64
; 128 lines.
PenShaftClear:
  LD A,L
  CPL
  AND $1F
  CP $03
  JR C,PenClearBytes
  LD A,$03
PenClearBytes:
  INC A
PenClearLine:
  PUSH HL
  LD C,A
PenClearByte:
  LD (HL),$00
  INC HL
  DEC C
  JR NZ,PenClearByte
  POP HL
  INC H
  DJNZ PenClearLine
  RET

; Plot one pixel at (E, D) with OR (sets PenSpan's mode to OR, B = 1)
;
; Writes OR (HL) into PenSpanOp1-3 and falls into PenSpan $BF66 with one pixel.
; Called by PenStep $BE05 and the dot command SigCmdDot $BD4C; m1 1105 calls.
PenPlot:
  LD A,$B6
  LD (PenSpanOp1),A
  LD (PenSpanOp2),A
  LD (PenSpanOp3),A
  LD B,$01

; A horizontal span of B pixels at (E, D), ORed or XORed by the self-modified
; PenSpanOp1-3
;
; Builds the left partial byte, the full bytes and the right partial byte; the
; NOPs at PenSpanOp1 $BF93, PenSpanOp2 $BFA1 and PenSpanOp3 $BFAE hold OR (HL)
; or XOR (HL) (PenDraw / PenErase / PenPlot). m1 41 837 calls.
PenSpan:
  LD A,B
  OR A
  RET Z
  PUSH BC
  LD H,D
  LD L,E
  CALL PenPixelAddress
  LD A,D
  AND $07
  ADD A,H
  LD H,A
  LD A,B
  SUB $08
  JR NC,PenSpanLong
  LD C,$00
PenSpanShort:
  SCF                     ; under 8 pixels: the mask
  RR C
  DJNZ PenSpanShort
  JR PenSpanShift
PenSpanLong:
  LD B,A
  LD C,$FF
PenSpanShift:
  LD A,E                  ; shift the mask by x AND 7
  AND $07
  JR Z,PenSpanFirst
PenSpanShiftLoop:
  SRL C
  JR NC,PenSpanShiftNext
  INC B
PenSpanShiftNext:
  DEC A
  JR NZ,PenSpanShiftLoop
PenSpanFirst:
  LD A,C
PenSpanOp1:
  NOP                     ; NOP / OR (HL) / XOR (HL)
  LD (HL),A
  INC HL
PenSpanMiddle:
  LD A,B
  OR A
  JR Z,PenSpanDone
  SUB $08
  JR C,PenSpanTail
  LD B,A
  LD A,$FF
PenSpanOp2:
  NOP                     ; NOP / OR (HL) / XOR (HL)
  LD (HL),A
  INC HL
  JR PenSpanMiddle
PenSpanTail:
  LD C,$00
PenSpanTailLoop:
  SCF
  RR C
  DJNZ PenSpanTailLoop
  LD A,C
PenSpanOp3:
  NOP                     ; NOP / OR (HL) / XOR (HL)
  LD (HL),A
PenSpanDone:
  POP BC
  RET

; HL = the display-file address of line H, x L (the same code as
; PresentsPixelAddress $BA6C)
;
; m1 60 112 calls (PenShaft, PenSpan).
PenPixelAddress:
  LD A,H
  ADD A,A
  ADD A,A
  AND $E0
  SRL L
  SRL L
  SRL L
  ADD A,L
  LD L,A
  LD A,H
  SRL A
  SRL A
  SRL A
  AND $F8
  OR $40
  LD H,A
  RET

; The pen's nib: ten spans (dx, dy, length) from the pen point down-right, $FF
;
; (0,0,2) (0,1,4) (1,2,5) (1,3,7) (2,4,8) (2,5,10) (3,6,10) (3,7,11) (4,8,11)
; (4,9,12): a wedge 10 lines high. Read by PenSpans $BE79 (m1, all 31 bytes).
PenNib:
  INCBIN "res/graphics/PenNib.bin",$0000,31

; The pen's end cap: six spans at (49..54, 54..59), lengths 11 down to 1, $FF
;
; Read by PenSpans $BE79 after the shaft (m1, all 19 bytes).
PenCap:
  INCBIN "res/graphics/PenCap.bin",$0000,19

; The shaft: 16 rows of 4 bytes, a 12-pixel bar moving one pixel right a row
;
; Row r = the bar's 12 pixels starting at pixel r of the 32: PenShaftBlock
; $BEDC starts at row x AND 7 and takes one row a line. Read by PenShaftCopy4
; $BF33 (m1, 60 of 64 bytes: rows 15's last bytes never).
PenShaftImage:
  INCBIN "res/graphics/PenShaftImage.bin",$0000,64

; The pen's state: the band flag (0; 1 / 2 only on the band paths, never run),
; pen down, the shaft position
;
; PenBand $C03E: zeroed by SignatureWrite $BD0C, read by SigMove $BD65 (m1 582
; reads, always 0).
PenBand:
  DEFB $00
PenIsDown:
  DEFB $00                ; 0 pen up, 1 pen down (SignatureCommand commands 1 /
                          ; 2; read by PenStep, m1 1484 reads)
PenShaftPos:
  DEFB $00,$00            ; the shaft's start: x (+0), y (+1) (PenShape,
                          ; PenShaft)
