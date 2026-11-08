; --------------------------------------------------------------------------------------------------------------------
; lowdata.asm: The low data: the scanner and dashboard save areas, the font, the ship slots and the ship blueprints
;
; $5B00-$6047 is TZX block 37 (03-build-and-load.md 3.7); $6048 on is the first decrypted chunk. Nothing here runs.
;
; The 3D view is the top two thirds of the screen, drawn into the back buffer at $C000 and copied to $4000
; (CopyBackBuffer $7FBE); the dashboard is the bottom third. ScannerSave and DashAttrSave hold copies of dashboard
; parts the views paint over.
; --------------------------------------------------------------------------------------------------------------------

; The scanner's background: 48 pixel lines of 13 bytes, $5049-$5055 on of the
; screen's bottom third
;
; ScannerCopy $990C copies 13 bytes a line, 8 lines a row, 6 rows between the
; screen ($5049, the scanner ellipse of the dashboard) and here.
; ScannerSaveMode $98A2 patches it to save the screen here (EX DE,HL, PUSH HL /
; POP HL in place of NOP, PUSH DE / POP DE), ScannerClear $98CD back to restore
; it every frame (f1: 554 runs). DashboardSave $817E also copies the
; dashboard's attributes ($5A00-$5AFF) to $5B00, and DashboardRestore $8042
; copies them back.
;
; The image's bytes are what the last copy left: attribute bytes ($07, $17) in
; the first page, then the mastering machine's system variables (03 3.10) to
; $5D6F.
ScannerSave:
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$17,$17,$17,$17
  DEFB $17,$00,$00,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$17,$17,$17,$17,$17,$07,$07,$07,$07
  DEFB $07,$07,$17,$17,$17,$17,$17,$00,$00,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$17,$17,$17
  DEFB $17,$17,$07,$07,$07,$07,$07,$07,$17,$17,$17,$17,$17
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$17,$17,$17,$17,$17,$07,$07,$07,$07,$07
  DEFB $07,$17,$17,$17,$17,$17,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$17,$17,$17,$17
  DEFB $17,$07,$07,$07,$07,$07,$07,$17,$17,$17,$17,$17,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$17,$17,$17,$17,$17,$07,$07,$07,$07,$07,$07
  DEFB $17,$17,$17,$17,$17,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$17,$17,$17,$17,$17
  DEFB $07,$07,$00,$07,$07,$07,$17,$17,$17,$17,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$17,$17,$17,$17,$17,$07,$07,$00
  DEFB $FF,$00,$1F,$20,$0D,$05,$20,$0D,$0D,$23,$05,$00,$00 ; from here the
  DEFB $00,$10,$00,$01,$00,$06,$00,$0B,$00,$01,$00,$01,$00 ; bytes are TZX
  DEFB $06,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; block 37's copy of
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the mastering
  DEFB $00,$00,$00,$3C,$40,$00,$FF,$CC,$01,$00,$00,$8D,$65 ; machine's system
  DEFB $00,$00,$00,$FF,$FE,$FF,$01,$07,$00,$00,$05,$5D,$00 ; variables
  DEFB $00,$F0,$5C,$F0,$5C,$05,$5D,$14,$5D,$04,$5D,$06,$5D ; (03-build-and-load.md
  DEFB $0D,$5D,$13,$5D,$13,$00,$15,$5D,$15,$5D,$15,$5D,$2D ; 3.10)
  DEFB $92,$5C,$10,$02,$00,$00,$FE,$FF,$01,$00,$00,$00,$B6
  DEFB $1A,$00,$00,$C7,$22,$00,$58,$FF,$00,$00,$21,$00,$5B
  DEFB $21,$17,$00,$40,$E0,$50,$21,$18,$21,$17,$01,$07,$00
  DEFB $07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$01,$00,$00,$00,$00,$00,$90,$65,$FF,$FF
  DEFB $00,$F0,$01,$21,$53,$05,$CD,$7B,$00,$22,$BA,$5C,$C9
  DEFB $0C,$00,$01,$00,$00,$00,$12,$16,$07,$5D,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$01,$00,$FF,$4D,$03,$00,$88
  DEFB $5F,$03,$00,$00,$00,$00,$FF,$00,$00,$03,$00,$00,$50
  DEFB $C3,$00,$80,$98,$DE,$01,$F4,$09,$A8,$10,$4B,$F4,$09
  DEFB $C4,$15,$53,$81,$0F,$C4,$15,$52,$F4,$09,$C4,$15,$50
  DEFB $80,$80,$F9,$C0,$35,$30,$30,$30,$30,$0E,$00,$00,$50
  DEFB $C3,$00,$0D,$80,$00,$00,$50,$C3,$00,$00,$0A,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The character set: 91 glyphs of 8 bytes for the codes $20-$7A, read by
; PrintChar $D499
;
; Codes $20-$7A, 8 bytes a glyph top line first. Most are ASCII letters, digits
; and signs; the codes $21-$26, $2B and $3B-$3E (! " # and so on) are the
; dashboard's frame pieces (slants, corners, bars), drawn by the same printer.
Font:
  INCBIN "res/fonts/font.bin",$0000,728

; The 8 ship slots, 39 bytes each: the objects in space
;
; Eight records of $27 bytes from $6048 (slot n at $6048 + 39 n), read and
; written by every ship routine (UpdateShips $9CBB walks them). The record:
; +$00-$08 the position x, y, z (3 bytes each, sign in bit 7 of the top byte),
; +$09-$1A the orientation vectors, +$1B the speed, +$20 / +$21 the flags, +$22
; the energy, +$23 / +$24 the blueprint address, +$25 / +$26 the AI state
; (07-objects.md). The image's bytes are leftovers of a BASIC program in the
; developer's memory (" ***---", "3000"), overwritten when a game starts.
ShipSlots:
  DEFB $20,$2A,$2A,$2A,$2D,$2D,$2D,$22,$0D,$80,$EC,$33,$30,$30,$30,$0E,$00,$00,$B8,$0B,$00,$0D,$80,$00,$00,$22,$5B,$00,$00,$00,$70,$00,$00,$00,$F0,$9D,$6A,$7F,$0C
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Slot 7, the last of the eight: the player's missile in flight, the turning
; ship on the title. The code names it directly (TurnTitleShip,
; ActionTitleShip, the hostility test of UpdateSlot); it is no work copy: the
; ship routines work on each slot in place
Slot7:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The blueprint table: 19 entries of $C3, the blueprint address and its class
;
; CreateShip $B898 reads entry A AND $3F (HL = $6180 + 4 A + 1): the word is
; the blueprint. The first byte of each is $C3 (a JP opcode; nothing jumps
; here). The last byte is the class the spawn code picks ships by: 0 the
; station and the missile, 1 debris (pod, plate, canister, splinter, asteroid),
; 2 traders (rock hermit, Viper, the trader Cobra and Python), 3 pirates and
; Thargoids, 4 the Sidewinder, Krait and Thargon (07-objects.md).
Blueprints:
  DEFB $C3,$9D,$6A,$00
  DEFB $C3,$A6,$67,$00
  DEFB $C3,$32,$66,$01
  DEFB $C3,$A7,$68,$01
  DEFB $C3,$E5,$63,$01
  DEFB $C3,$BC,$6B,$01
  DEFB $C3,$0C,$63,$01
  DEFB $C3,$F5,$62,$02
  DEFB $C3,$1B,$6E,$02
  DEFB $C3,$90,$64,$02
  DEFB $C3,$E6,$68,$02
  DEFB $C3,$FD,$68,$03
  DEFB $C3,$A7,$64,$03
  DEFB $C3,$CC,$61,$03
  DEFB $C3,$89,$66,$03
  DEFB $C3,$13,$6C,$03
  DEFB $C3,$F2,$69,$04
  DEFB $C3,$32,$6D,$04
  DEFB $C3,$F8,$6E,$04

; blueprint 13: the header (19 vertices, 28 edges, 12 faces)
ShipAsp:
  INCBIN "res/ships/ships.bin",$0000,23

; the 19 vertices of blueprint 13
ShipAspVertices:
  INCBIN "res/ships/ships.bin",$0017,114

; the 28 edges of blueprint 13
ShipAspEdges:
  INCBIN "res/ships/ships.bin",$0089,112

; the 12 faces of blueprint 13
ShipAspFaces:
  INCBIN "res/ships/ships.bin",$00F9,48

; blueprint 7: the header (9 vertices, 21 edges, 14 faces)
ShipRockHermit:
  INCBIN "res/ships/ships.bin",$0129,23

; blueprint 6: the header (9 vertices, 21 edges, 14 faces)
ShipAsteroid:
  INCBIN "res/ships/ships.bin",$0140,23

; the 9 vertices of blueprint 6
ShipAsteroidVertices:
  INCBIN "res/ships/ships.bin",$0157,54

; the 21 edges of blueprint 6
ShipAsteroidEdges:
  INCBIN "res/ships/ships.bin",$018D,84

; the 14 faces of blueprint 6
ShipAsteroidFaces:
  INCBIN "res/ships/ships.bin",$01E1,56

; blueprint 4: the header (10 vertices, 15 edges, 7 faces)
ShipCanister:
  INCBIN "res/ships/ships.bin",$0219,23

; the 10 vertices of blueprint 4
ShipCanisterVertices:
  INCBIN "res/ships/ships.bin",$0230,60

; the 15 edges of blueprint 4
ShipCanisterEdges:
  INCBIN "res/ships/ships.bin",$026C,60

; the 7 faces of blueprint 4
ShipCanisterFaces:
  INCBIN "res/ships/ships.bin",$02A8,28

; blueprint 9: the header (28 vertices, 38 edges, 13 faces)
ShipCobraTrader:
  INCBIN "res/ships/ships.bin",$02C4,23

; blueprint 12: the header (28 vertices, 38 edges, 13 faces)
ShipCobraPirate:
  INCBIN "res/ships/ships.bin",$02DB,23

; the 28 vertices of both Cobra blueprints
ShipCobraVertices:
  INCBIN "res/ships/ships.bin",$02F2,168

; the 38 edges of both Cobra blueprints
ShipCobraEdges:
  INCBIN "res/ships/ships.bin",$039A,152

; the 13 faces of both Cobra blueprints
ShipCobraFaces:
  INCBIN "res/ships/ships.bin",$0432,52

; blueprint 2: the header (4 vertices, 6 edges, 4 faces)
ShipEscapePod:
  INCBIN "res/ships/ships.bin",$0466,23

; the 4 vertices of blueprint 2
ShipEscapePodVertices:
  INCBIN "res/ships/ships.bin",$047D,24

; the 6 edges of blueprint 2
ShipEscapePodEdges:
  INCBIN "res/ships/ships.bin",$0495,24

; the 4 faces of blueprint 2
ShipEscapePodFaces:
  INCBIN "res/ships/ships.bin",$04AD,16

; blueprint 14: the header (19 vertices, 27 edges, 10 faces)
ShipFerDeLance:
  INCBIN "res/ships/ships.bin",$04BD,23

; the 19 vertices of blueprint 14
ShipFerDeLanceVertices:
  INCBIN "res/ships/ships.bin",$04D4,114

; the 27 edges of blueprint 14
ShipFerDeLanceEdges:
  INCBIN "res/ships/ships.bin",$0546,108

; the 10 faces of blueprint 14
ShipFerDeLanceFaces:
  INCBIN "res/ships/ships.bin",$05B2,40

; blueprint 1: the header (17 vertices, 24 edges, 9 faces)
ShipMissile:
  INCBIN "res/ships/ships.bin",$05DA,23

; the 17 vertices of blueprint 1
ShipMissileVertices:
  INCBIN "res/ships/ships.bin",$05F1,102

; the 24 edges of blueprint 1
ShipMissileEdges:
  INCBIN "res/ships/ships.bin",$0657,96

; the 9 faces of blueprint 1
ShipMissileFaces:
  INCBIN "res/ships/ships.bin",$06B7,36

; blueprint 3: the header (4 vertices, 4 edges, 0 faces)
ShipPlate:
  INCBIN "res/ships/ships.bin",$06DB,23

; the 4 vertices of blueprint 3
ShipPlateVertices:
  INCBIN "res/ships/ships.bin",$06F2,24

; the 4 edges of blueprint 3
ShipPlateEdges:
  INCBIN "res/ships/ships.bin",$070A,16

; blueprint 10: the header (11 vertices, 26 edges, 13 faces)
ShipPythonTrader:
  INCBIN "res/ships/ships.bin",$071A,23

; blueprint 11: the header (11 vertices, 26 edges, 13 faces)
ShipPythonPirate:
  INCBIN "res/ships/ships.bin",$0731,23

; the 11 vertices of both Python blueprints
ShipPythonVertices:
  INCBIN "res/ships/ships.bin",$0748,66

; the 26 edges of both Python blueprints
ShipPythonEdges:
  INCBIN "res/ships/ships.bin",$078A,104

; the 13 faces of both Python blueprints
ShipPythonFaces:
  INCBIN "res/ships/ships.bin",$07F2,52

; blueprint 16: the header (10 vertices, 15 edges, 7 faces)
ShipSidewinder:
  INCBIN "res/ships/ships.bin",$0826,23

; the 10 vertices of blueprint 16
ShipSidewinderVertices:
  INCBIN "res/ships/ships.bin",$083D,60

; the 15 edges of blueprint 16
ShipSidewinderEdges:
  INCBIN "res/ships/ships.bin",$0879,60

; the 7 faces of blueprint 16
ShipSidewinderFaces:
  INCBIN "res/ships/ships.bin",$08B5,28

; blueprint 0: the header (16 vertices, 28 edges, 14 faces)
ShipCoriolis:
  INCBIN "res/ships/ships.bin",$08D1,23

; the 16 vertices of blueprint 0
ShipCoriolisVertices:
  INCBIN "res/ships/ships.bin",$08E8,96

; the 28 edges of blueprint 0
ShipCoriolisEdges:
  INCBIN "res/ships/ships.bin",$0948,112

; the 14 faces of blueprint 0
ShipCoriolisFaces:
  INCBIN "res/ships/ships.bin",$09B8,56

; blueprint 5: the header (4 vertices, 6 edges, 4 faces)
ShipSplinter:
  INCBIN "res/ships/ships.bin",$09F0,23

; the 4 vertices of blueprint 5
ShipSplinterVertices:
  INCBIN "res/ships/ships.bin",$0A07,24

; the 6 edges of blueprint 5
ShipSplinterEdges:
  INCBIN "res/ships/ships.bin",$0A1F,24

; the 4 faces of blueprint 5
ShipSplinterFaces:
  INCBIN "res/ships/ships.bin",$0A37,16

; blueprint 15: the header (20 vertices, 26 edges, 10 faces)
ShipThargoid:
  INCBIN "res/ships/ships.bin",$0A47,23

; the 20 vertices of blueprint 15
ShipThargoidVertices:
  INCBIN "res/ships/ships.bin",$0A5E,120

; the 26 edges of blueprint 15
ShipThargoidEdges:
  INCBIN "res/ships/ships.bin",$0AD6,104

; the 10 faces of blueprint 15
ShipThargoidFaces:
  INCBIN "res/ships/ships.bin",$0B3E,40

; blueprint 17: the header (17 vertices, 21 edges, 6 faces)
ShipKrait:
  INCBIN "res/ships/ships.bin",$0B66,23

; the 17 vertices of blueprint 17
ShipKraitVertices:
  INCBIN "res/ships/ships.bin",$0B7D,102

; the 21 edges of blueprint 17
ShipKraitEdges:
  INCBIN "res/ships/ships.bin",$0BE3,84

; the 6 faces of blueprint 17
ShipKraitFaces:
  INCBIN "res/ships/ships.bin",$0C37,24

; blueprint 8: the header (15 vertices, 20 edges, 7 faces)
ShipViper:
  INCBIN "res/ships/ships.bin",$0C4F,23

; the 15 vertices of blueprint 8
ShipViperVertices:
  INCBIN "res/ships/ships.bin",$0C66,90

; the 20 edges of blueprint 8
ShipViperEdges:
  INCBIN "res/ships/ships.bin",$0CC0,80

; the 7 faces of blueprint 8
ShipViperFaces:
  INCBIN "res/ships/ships.bin",$0D10,28

; blueprint 18: the header (10 vertices, 15 edges, 7 faces)
ShipThargon:
  INCBIN "res/ships/ships.bin",$0D2C,23

; the 10 vertices of blueprint 18
ShipThargonVertices:
  INCBIN "res/ships/ships.bin",$0D43,60

; the 15 edges of blueprint 18
ShipThargonEdges:
  INCBIN "res/ships/ships.bin",$0D7F,60

; the 7 faces of blueprint 18
ShipThargonFaces:
  INCBIN "res/ships/ships.bin",$0DBB,28

; 79 zeros after the last blueprint
BlueprintsSpare:
  DEFS $4F
