; --------------------------------------------------------------------------------------------------------------------
; workspace.asm: The movers' sprites and the work space
;
; The five 16 x 16 sprites, the save header, and the arrays built at run time: the fire and police coverage,
; pollution, traffic, the power bitmap and the 96 x 96 city map.
; --------------------------------------------------------------------------------------------------------------------

; The movers' 16 x 16 sprites, 32 bytes each: the plane, two tornado frames,
; the train across and down
MoverSprites:
  INCBIN "res/graphics/Movers.bin",$0000,160

; The name typed for LOAD and SAVE
SaveName:
  DEFM "            "

; The tape header (31 bytes): file name 12, Funds 3, a spare, Month, Year 2, a
; spare, the city name 11 (SaveCityName $A944-$A94E)
SaveHeader:
  DEFB $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
SaveFunds:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
SaveCityName:
  DEFB $48,$45,$52,$45,$53,$56,$49,$4C,$4C,$45,$20

; The city name's twelfth letter: SaveCity copies 12 letters to $A944, but the
; header block ends at $A94E, so this byte never reaches the tape; LoadCity
; copies it back from RAM
SaveSpare:
  DEFB $20

; The 24 x 24 fire coverage, 0-15 (zero in the image: built at run time)
FireCover:
  DEFS $0240

; The 24 x 24 police coverage, 0-15
PoliceCover:
  DEFS $0240

; The 48 x 48 pollution, 0-255
Pollution:
  DEFS $0900

; The 48 x 48 traffic, 0-$F0
Traffic:
  DEFS $0900

; The powered bit of each map cell, 12 bytes a row
PowerMap:
  DEFS $0480

; The 96 x 96 map, all land (2) in the image: NewLandscape makes it
CityMap:
  DEFS $2400,$02
