; --------------------------------------------------------------------------------------------------------------------
; screen.asm: the loading screen and its fade-in
;
; The screen at $8000 is the loading picture (src/res/screen/loading.scr, 6912 bytes as a .scr). ShowLoadingScreen
; shows the bitmap under black attributes, makes seven copies of the attributes from dark to full and shows them in
; that order, 6 frames apart.
; --------------------------------------------------------------------------------------------------------------------

; attributes black, the bitmap shown, then the attribute copies from dark to
; full every 6 frames
;
; MakeFades writes the seven copies to $9B00, $9E00 ... $AE00, the darkest
; first and the last one equal to the picture's own attributes. The loop copies
; 768 bytes a step from $9B00 on and stops when HL reaches FadeEnd.
ShowLoadingScreen:
  DI
  CALL MakeFades
  EI
  LD HL,$9B00
  JR l_7F68
l_7F62:
  LD A,$06                ; 6 frames between the steps
l_7F64:
  HALT
  DEC A
  JR NZ,l_7F64
l_7F68:
  LD DE,Attrs             ; one attribute copy to the screen
  LD BC,$0300
  LDIR
  LD A,H
  CP $B0
  RET Z
  JR l_7F62

; attributes black, the bitmap to the screen, the darker attribute copies built
; at $9B00
;
; Each copy takes B from the ink and C from the paper of every cell (not below
; 0) and keeps BRIGHT and FLASH: B runs 6 down to 0 and C 48 down to 0 in steps
; of 8, so the first copy is the darkest and the seventh takes nothing. The two
; OR $00 instructions get the new ink and paper written into their operands.
MakeFades:
  LD HL,Attrs
  LD DE,Attrs+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  LD HL,LoadingScreen
  LD DE,Screen
  LD BC,$1800
  LDIR
  LD BC,$0630
  LD DE,$9B00
l_7F94:
  LD HL,LoadingScreen+$1800 ; one copy of the 768 attributes at $9800
l_7F97:
  LD A,(HL)
  AND $07
  CP B
  CALL C,ClampInk
  SUB B
  LD (SetInk+1),A
  LD A,(HL)
  AND $38
  CP C
  CALL C,ClampPaper
  SUB C
  LD (SetPaper+1),A
  LD A,(HL)
  AND $C0
SetInk:
  OR $00                  ; the cell's BRIGHT and FLASH with the darkened ink
                          ; (the operand written above) ...
SetPaper:
  OR $00                  ; ... and paper
  LD (DE),A
  INC HL
  INC DE
  LD A,H
  CP $9B
  JR NZ,l_7F97
  DEC B
  LD A,C
  SUB $08
  LD C,A
  JR NC,l_7F94
  RET

; A = B (the ink not taken below 0)
;
; Used by the routine at MakeFades.
ClampInk:
  LD A,B
  RET

; A = C
;
; Used by the routine at MakeFades.
ClampPaper:
  LD A,C
  RET

; " PROGRAM BY MIKE BLUM ": never printed
Credit:
  DEFM " PROGRAM BY MIKE BLUM "

; zeros to the screen
Spare:
  DEFS $22

; the loading screen: bitmap and attributes
LoadingScreen:
  INCBIN "build/res/screen/loading.scr",$0000,6912
