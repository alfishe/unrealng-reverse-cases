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
SaveHeader:
  DEFM "            "     ; the tape header (31 bytes): file name 12, Funds 3,
                          ; a spare, Month, Year 2, a spare, the city name 11
                          ; (SaveCityName $A944-$A94E)
SaveFunds:
  DEFM $00,$00,$00,$00,$00,$00,$00,$00
SaveCityName:
  DEFM "HERESVILLE "

; SaveSpare
SaveSpare:
  DEFB $20

; The 24 x 24 fire coverage, 0-15 (zero in the image: built at run time)
FireCover:
  DEFS $0240
PoliceCover:
  DEFS $0240              ; the police coverage
Pollution:
  DEFS $0900              ; the 48 x 48 pollution
Traffic:
  DEFS $0900              ; the 48 x 48 traffic
PowerMap:
  DEFS $0480              ; the powered bit of each map cell, 12 bytes a row
CityMap:
  DEFS $2400,$02          ; the 96 x 96 map, all land (2) in the image:
                          ; NewLandscape makes it
