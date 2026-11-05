; --------------------------------------------------------------------------------------------------------------------
; panel.asm: Panel spinners, saving the panel
;
; Two spinners turn on the panel's sides (row 20, columns 1 and 29; drawn by the panel update PanelFrame each pass):
; 16x16 images symmetric left to right, kept as the left 8 pixels of 5 shapes; the right half is the bit mirror (the
; table $FB00), the odd offsets read the shape bottom up.
;
; SavePanel and RestorePanel keep the screen third $5000-$57FF and the attribute rows 19-23 in $E748 while another
; screen covers them.
; --------------------------------------------------------------------------------------------------------------------

; Draw a 2x2 cell spinner frame
;
; HL: the attribute address of the top left cell; A: its attribute (four
; cells); C: the frame 0-15. The frame's offset from SpinnerFrames picks the
; shape in SpinnerImages: an even offset is the start of a shape read top down,
; an odd one the last byte of a shape read bottom up (the shape flipped upside
; down). Each row is drawn as the byte and its mirror (the bit-reverse table
; $FB00) side by side.
;
; Callers: the panel update PanelFrame ($AB97, $AB9F).
DrawSpinner:
  PUSH HL
  LD (HL),A
  INC L
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC L
  LD (HL),A
  LD B,$00                ; the shape's offset
  LD HL,SpinnerFrames
  ADD HL,BC
  LD C,(HL)
  LD HL,SpinnerImages
  ADD HL,BC
  EX DE,HL
  POP HL
  LD A,H                  ; the screen address of the cell
  XOR $50
  RLCA
  RLCA
  RLCA
  LD H,A
  EXX
  LD H,$FB                ; H' = the bit-reverse table
  EXX
  LD B,$02                ; two cells down
  BIT 0,C                 ; odd offset: upside down
  JR Z,DrawSpinnerCell
  INC L
DrawSpinnerFlippedCell:
  PUSH BC
  LD B,$08
DrawSpinnerFlippedRow:
  LD A,(DE)               ; the byte left, its mirror right
  DEC DE
  LD C,A
  EXX
  LD L,A
  LD A,(HL)
  EXX
  LD (HL),A
  DEC L
  LD (HL),C
  INC L
  INC H
  DJNZ DrawSpinnerFlippedRow
  LD BC,$F820             ; the cell below
  ADD HL,BC
  POP BC
  DJNZ DrawSpinnerFlippedCell
  RET
DrawSpinnerCell:
  PUSH BC
  LD B,$08
DrawSpinnerRow:
  LD A,(DE)
  INC DE
  LD (HL),A
  INC L
  EXX
  LD L,A
  LD A,(HL)
  EXX
  LD (HL),A
  DEC L
  INC H
  DJNZ DrawSpinnerRow
  LD BC,$F820
  ADD HL,BC
  POP BC
  DJNZ DrawSpinnerCell
  RET

; The 16 frames of a spinner: offsets into SpinnerImages
;
; Even: a shape top down; odd: the end of a shape, bottom up.
SpinnerFrames:
  DEFB $00,$10,$20,$30,$40,$3F,$2F,$1F
  DEFB $0F,$1F,$2F,$3F,$40,$30,$20,$10

; The spinner shapes: 5 x 16 rows, the left 8 pixels
;
; From a thin diagonal line ($A929) to a full ring ($A969): the turning disc
; seen from its edge to its face.
SpinnerImages:
  DEFB $80,$80,$40,$40,$40,$40,$20,$20,$20,$10,$10,$08,$08,$04,$06,$03
  DEFB $80,$C0,$C0,$A0,$A0,$60,$50,$50,$50,$28,$28,$24,$14,$12,$09,$07
  DEFB $C0,$E0,$A0,$90,$90,$88,$88,$44,$44,$44,$42,$42,$21,$21,$13,$0E
  DEFB $60,$B0,$90,$88,$88,$84,$84,$82,$82,$81,$81,$41,$41,$42,$24,$38
  DEFB $70,$48,$44,$84,$82,$82,$81,$81,$81,$81,$82,$82,$84,$44,$48,$70

; Restore the bottom third and the panel attributes from $E748
;
; $E748 -> $5000 (2048 bytes) and $EF48 -> $5A60 (160 bytes, attribute rows
; 19-23). Called at $B04F (the player change, RoundPlaySetup).
RestorePanel:
  LD HL,SpriteCacheImages
  LD DE,$5000
  LD BC,$0800
  LDIR
  LD DE,$5A60
  LD BC,$00A0
  LDIR
  RET

; Save the bottom third and the panel attributes into $E748
;
; The reverse of RestorePanel. Called at $B1F9.
SavePanel:
  LD DE,SpriteCacheImages
  LD HL,$5000
  LD BC,$0800
  LDIR
  LD HL,$5A60
  LD BC,$00A0
  LDIR
  RET
