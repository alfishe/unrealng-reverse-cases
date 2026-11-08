; Elite, Firebird / Torus 1985, Side B ("With Adder ship"): Side A's game image (game.bin, built from
; src/game) with the three parts that differ laid over it (tools/sideb.py, docs/03-build-and-load.md
; 3.12). Assembled by tools/build.sh into build/sideb/game.bin.
  DEVICE ZXSPECTRUM48
  ORG $5B00
  INCBIN "game.bin"

; 1. The mastering machine's system variables and stack (Side B's run: RAMTOP $6047, another FRAMES)
  ORG $5C02
  DEFB $00,$00,$0D,$05,$22
  ORG $5C3F
  DEFB $00,$00
  ORG $5C5F
  DEFB $00
  ORG $5C6E
  DEFB $00,$00,$00
  ORG $5C78
  DEFB $8C,$11
  ORG $5CA1
  DEFB $00
  ORG $5CAB
  DEFB $00,$00
  ORG $5CB2
  DEFB $47,$60
  ORG $5CBA
  DEFB $F0,$5C,$CD,$E8,$19
  ORG $5D1E
  DEFB $05,$00,$DB,$02,$DB,$02,$4D,$00,$D0,$50,$30,$00,$CF,$50,$0C,$02
  DEFB $5C,$0E,$C0,$57,$71,$0E,$F3,$0D,$21,$17,$C6,$1E,$47,$60,$76,$5C
  DEFB $05,$00,$DB,$02,$DB,$02,$4D,$00,$D0,$50,$30,$00,$CF,$50,$0C,$02
  DEFB $5C,$0E,$C0,$57,$71,$0E,$F3,$0D,$21,$17,$C6,$1E,$47,$60,$76,$1B
  DEFB $03,$13,$00,$3E

; 2. Slot 0's blueprint word: the Coriolis, where Side B keeps it
  ORG $606B
  DEFW ShipCoriolis

; 3. The blueprint table (19 entries: $C3, the blueprint, the class) and the blueprints
  ORG $6180
Blueprints:
  DEFB $C3 : DEFW ShipCoriolis : DEFB 0  ; 0 Coriolis
  DEFB $C3 : DEFW ShipMissile : DEFB 0  ; 1 Missile
  DEFB $C3 : DEFW ShipEscapePod : DEFB 1  ; 2 EscapePod
  DEFB $C3 : DEFW ShipPlate : DEFB 1  ; 3 Plate
  DEFB $C3 : DEFW ShipCanister : DEFB 1  ; 4 Canister
  DEFB $C3 : DEFW ShipSplinter : DEFB 1  ; 5 Splinter
  DEFB $C3 : DEFW ShipAsteroid : DEFB 1  ; 6 Asteroid
  DEFB $C3 : DEFW ShipRockHermit : DEFB 2  ; 7 RockHermit
  DEFB $C3 : DEFW ShipViper : DEFB 2  ; 8 Viper
  DEFB $C3 : DEFW ShipCobraTrader : DEFB 2  ; 9 CobraTrader
  DEFB $C3 : DEFW ShipPythonTrader : DEFB 2  ; 10 PythonTrader
  DEFB $C3 : DEFW ShipPythonPirate : DEFB 3  ; 11 PythonPirate
  DEFB $C3 : DEFW ShipCobraPirate : DEFB 3  ; 12 CobraPirate
  DEFB $C3 : DEFW ShipAsp : DEFB 3  ; 13 Asp
  DEFB $C3 : DEFW ShipFerDeLance : DEFB 3  ; 14 FerDeLance
  DEFB $C3 : DEFW ShipThargoid : DEFB 3  ; 15 Thargoid
  DEFB $C3 : DEFW ShipSidewinder : DEFB 4  ; 16 Sidewinder
  DEFB $C3 : DEFW ShipAdder : DEFB 4  ; 17 Adder
  DEFB $C3 : DEFW ShipThargon : DEFB 4  ; 18 Thargon
ShipAdder:
  INCBIN "res/ships-b.bin",$0000,23
ShipAdderVertices:
  INCBIN "res/ships-b.bin",$0017,108
ShipAdderEdges:
  INCBIN "res/ships-b.bin",$0083,116
ShipAdderFaces:
  INCBIN "res/ships-b.bin",$00F7,60
ShipAsp:
  INCBIN "res/ships-b.bin",$0133,23
ShipAspVertices:
  INCBIN "res/ships-b.bin",$014A,114
ShipAspEdges:
  INCBIN "res/ships-b.bin",$01BC,112
ShipAspFaces:
  INCBIN "res/ships-b.bin",$022C,48
ShipRockHermit:
  INCBIN "res/ships-b.bin",$025C,23
ShipAsteroid:
  INCBIN "res/ships-b.bin",$0273,23
ShipAsteroidVertices:
  INCBIN "res/ships-b.bin",$028A,54
ShipAsteroidEdges:
  INCBIN "res/ships-b.bin",$02C0,84
ShipAsteroidFaces:
  INCBIN "res/ships-b.bin",$0314,56
ShipCanister:
  INCBIN "res/ships-b.bin",$034C,23
ShipCanisterVertices:
  INCBIN "res/ships-b.bin",$0363,60
ShipCanisterEdges:
  INCBIN "res/ships-b.bin",$039F,60
ShipCanisterFaces:
  INCBIN "res/ships-b.bin",$03DB,28
ShipCobraTrader:
  INCBIN "res/ships-b.bin",$03F7,23
ShipCobraPirate:
  INCBIN "res/ships-b.bin",$040E,23
ShipCobraVertices:
  INCBIN "res/ships-b.bin",$0425,168
ShipCobraEdges:
  INCBIN "res/ships-b.bin",$04CD,152
ShipCobraFaces:
  INCBIN "res/ships-b.bin",$0565,52
ShipEscapePod:
  INCBIN "res/ships-b.bin",$0599,23
ShipEscapePodVertices:
  INCBIN "res/ships-b.bin",$05B0,24
ShipEscapePodEdges:
  INCBIN "res/ships-b.bin",$05C8,24
ShipEscapePodFaces:
  INCBIN "res/ships-b.bin",$05E0,16
ShipFerDeLance:
  INCBIN "res/ships-b.bin",$05F0,23
ShipFerDeLanceVertices:
  INCBIN "res/ships-b.bin",$0607,114
ShipFerDeLanceEdges:
  INCBIN "res/ships-b.bin",$0679,108
ShipFerDeLanceFaces:
  INCBIN "res/ships-b.bin",$06E5,40
ShipMissile:
  INCBIN "res/ships-b.bin",$070D,23
ShipMissileVertices:
  INCBIN "res/ships-b.bin",$0724,102
ShipMissileEdges:
  INCBIN "res/ships-b.bin",$078A,96
ShipMissileFaces:
  INCBIN "res/ships-b.bin",$07EA,36
ShipPlate:
  INCBIN "res/ships-b.bin",$080E,23
ShipPlateVertices:
  INCBIN "res/ships-b.bin",$0825,24
ShipPlateEdges:
  INCBIN "res/ships-b.bin",$083D,16
ShipPythonTrader:
  INCBIN "res/ships-b.bin",$084D,23
ShipPythonPirate:
  INCBIN "res/ships-b.bin",$0864,23
ShipPythonVertices:
  INCBIN "res/ships-b.bin",$087B,66
ShipPythonEdges:
  INCBIN "res/ships-b.bin",$08BD,104
ShipPythonFaces:
  INCBIN "res/ships-b.bin",$0925,52
ShipSidewinder:
  INCBIN "res/ships-b.bin",$0959,23
ShipSidewinderVertices:
  INCBIN "res/ships-b.bin",$0970,60
ShipSidewinderEdges:
  INCBIN "res/ships-b.bin",$09AC,60
ShipSidewinderFaces:
  INCBIN "res/ships-b.bin",$09E8,28
ShipCoriolis:
  INCBIN "res/ships-b.bin",$0A04,23
ShipCoriolisVertices:
  INCBIN "res/ships-b.bin",$0A1B,96
ShipCoriolisEdges:
  INCBIN "res/ships-b.bin",$0A7B,112
ShipCoriolisFaces:
  INCBIN "res/ships-b.bin",$0AEB,56
ShipSplinter:
  INCBIN "res/ships-b.bin",$0B23,23
ShipSplinterVertices:
  INCBIN "res/ships-b.bin",$0B3A,24
ShipSplinterEdges:
  INCBIN "res/ships-b.bin",$0B52,24
ShipSplinterFaces:
  INCBIN "res/ships-b.bin",$0B6A,16
ShipThargoid:
  INCBIN "res/ships-b.bin",$0B7A,23
ShipThargoidVertices:
  INCBIN "res/ships-b.bin",$0B91,120
ShipThargoidEdges:
  INCBIN "res/ships-b.bin",$0C09,104
ShipThargoidFaces:
  INCBIN "res/ships-b.bin",$0C71,40
ShipViper:
  INCBIN "res/ships-b.bin",$0C99,23
ShipViperVertices:
  INCBIN "res/ships-b.bin",$0CB0,90
ShipViperEdges:
  INCBIN "res/ships-b.bin",$0D0A,80
ShipViperFaces:
  INCBIN "res/ships-b.bin",$0D5A,28
ShipThargon:
  INCBIN "res/ships-b.bin",$0D76,23
ShipThargonVertices:
  INCBIN "res/ships-b.bin",$0D8D,60
ShipThargonEdges:
  INCBIN "res/ships-b.bin",$0DC9,60
ShipThargonFaces:
  INCBIN "res/ships-b.bin",$0E05,28
BlueprintsSpare:
  DEFS $6FF2-$

  SAVEBIN "game.bin",$5B00,$FFA8-$5B00
