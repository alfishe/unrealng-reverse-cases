; --------------------------------------------------------------------------------------------------------------------
; icons.asm: the five icons of the pod selector
;
; Five 16 x 16 pictures, one for each pod action the selector offers (record +7): 0 speed-up, 1 laser, 2 plasma, 3
; homing missiles, 4 seeker (the pod table $80F0), drawn by PodIconJob into the panel at rows 20-21, columns 6-7 in
; bright yellow over bright cyan. A preview: ../zynaps/work/f4/icons.preview.png.
; --------------------------------------------------------------------------------------------------------------------

; five 16 x 16 icons, 32 bytes each: the left cell's 8 lines, the right's, then
; the lower row's two
;
; Drawn by PodIconJob at rows 20-21 ($5086/$50A6), columns 6-7, icon n = the
; player record's +7 (the selected pod, 0-4). Bytes in the order IconRow reads
; them: TL, TR, BL, BR, each top line first.
PodIcons:
  DEFB $00,$00,$00,$23,$08,$53,$03,$23 ; icon 0: speed-up
  DEFB $00,$00,$00,$60,$18,$64,$7A,$7E
  DEFB $4B,$03,$53,$0B,$23,$00,$00,$00
  DEFB $7E,$7E,$7C,$78,$60,$00,$00,$00
  DEFB $00,$18,$3D,$3B,$3B,$3B,$3B,$2B ; icon 1: laser
  DEFB $00,$18,$BC,$DC,$DC,$DC,$DC,$DC
  DEFB $2B,$2A,$2A,$2A,$02,$28,$02,$00
  DEFB $CC,$CC,$CC,$CC,$C0,$2C,$C0,$00
  DEFB $00,$02,$37,$3B,$1D,$2E,$76,$39 ; icon 2: plasma
  DEFB $00,$00,$00,$80,$80,$80,$00,$C0
  DEFB $1D,$01,$00,$00,$00,$00,$00,$00
  DEFB $10,$70,$44,$DC,$1C,$38,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$7D ; icon 3: homing missiles
  DEFB $00,$06,$6E,$5C,$18,$64,$EC,$C0
  DEFB $7B,$37,$0E,$35,$1B,$0B,$01,$00
  DEFB $80,$00,$80,$80,$80,$80,$80,$00
  DEFB $00,$00,$18,$1D,$0E,$06,$01,$07 ; icon 4: seeker
  DEFB $00,$00,$0C,$1C,$B8,$B0,$C8,$F0
  DEFB $09,$06,$0E,$1C,$18,$00,$00,$00
  DEFB $C0,$B0,$B8,$5C,$0C,$00,$00,$00
