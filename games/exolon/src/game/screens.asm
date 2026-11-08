; --------------------------------------------------------------------------------------------------------------------
; screens.asm: The screen change, the screen builder and its 62 scenery elements
; --------------------------------------------------------------------------------------------------------------------

; After the move: when the player left the screen, set X 0 and build the next
; screen
;
; ScreenChanged 0: return. Otherwise PlayerX = RestartX = 0 (the player enters
; on the left at the Y he left at), the ZONES number ($8E7B), and on into
; BuildScreen. Called from the main loop each pass and by the round end $A8A5.
ScreenChangeCheck:
  LD A,(ScreenChanged)
  OR A
  RET Z
  XOR A
  LD (PlayerX),A
  LD (RestartX),A
  CALL PrintZone

; Reset the objects and draw screen ScreenNumber from its element list
;
; Entered at the game start ($75BB) and from ScreenChangeCheck. Clears the
; per-screen state ($AC7B, the grenade $925A, $768D, $AC78), FillOpenMap,
; ClearBlockMap, ClearShots, ClearShells, the other object lists ($91FA, $980F,
; ResetTurretList, $98AD, $9AFA, $9C7D, $9E0A, $9F20, $A545, $A01C, $A352) and
; the screen ($B061: the 22 play rows).
;
; Then the screen's list from the table at $C7F4 (TableWord, index
; ScreenNumber): records of 3 bytes, row, column, element number, $FF the end.
; For each the element number goes to $9487 (with IX = $9437: the enemies and
; objects that element brings), then the element's print string (ElementTable
; $852E) is printed at the row and column by $AF2B with the block map value 1
; (solid; $AE1B), the open-cell value 0 ($AE21) and the attribute 0; the
; string's own codes change them.
;
; At the end: IX's list closed, SaveAttributes, $A2D5, IndexObjectCells (the
; object cells the strings marked become the kinds' lists), $9B07, $A645,
; $A23A, and on to $AB97. 97 warp runs (w/NNN) built every screen 0-124 through
; here.
BuildScreen:
  LD HL,$0000
  LD (IdleTime),HL
  XOR A
  LD (GrenadeTimer),A
  LD (ImmunityCount),A
  LD (IdleMissileLive),A
  CALL ClearWorkArea
  CALL FillOpenMap
  CALL ClearBlockMap
  CALL ClearShots
  CALL ClearMissileList
  CALL ArmMines
  CALL ClearDebris
  CALL ResetTurretList
  CALL ClearPuffs
  CALL ClearBalls
  CALL ClearTraps
  CALL ClearGunShots
  CALL ClearSparkles
  CALL ClearAliens
  CALL ClearBlasts
  CALL ClearPickups
  CALL ClearPlayArea
  LD A,(ScreenNumber)
  LD BC,ScreenTable
  CALL TableWord
  LD IX,DestructibleList
BuildScreenNext:
  LD A,(HL)               ; the next element record; $FF ends
  CP $FF
  JR Z,BuildScreenDone
  LD D,A
  INC HL
  LD E,(HL)
  INC HL
  PUSH HL
  LD A,(HL)
  CALL AddDestructible
  LD BC,ElementTable
  CALL TableWord
  LD A,$01
  LD (PrintCharLine+$0018),A
  XOR A
  LD (PrintCharLine+$001E),A
  LD C,A
  CALL PrintString
  POP HL
  INC HL
  JP BuildScreenNext
BuildScreenDone:
  LD (IX+$00),$FF         ; close the object list, index the object cells,
                          ; start the screen's objects
  CALL SaveAttributes
  CALL DrawStars
  CALL IndexObjectCells
  CALL SpawnBalls
  CALL AliensSetUp
  CALL HomingMissileStart
  JP ForceFieldDraw

; The screen 0-124 the player is on (ZONES); $FF during the round end
;
; Set to 0 at the entry ($6D75), + 1 by NextScreen, read by BuildScreen and
; PrintZone. Screen 124 ($7C) left on the right is the round end ($A867).
ScreenNumber:
  DEFB $00

; HL = the word at BC + 2 A (an entry of a table of addresses)
;
; Used for the screen table $C7F4 and ElementTable by BuildScreen, and by $93E2
; and $99F8.
TableWord:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET

; The 62 scenery elements: the address of each element's print string
;
; BuildScreen prints element n (the third byte of a screen record) from
; ElementTable[n]. The strings are $AF2B print code (see exB.md): the font
; (code $E6 and a word: each element has its own glyph set, $DAB8-$EC48),
; colour codes $CF-$DE, moves ($61-$CE, $DF), runs ($E4 across, $E5 down),
; loops ($E1 / $E2) and calls of a shared string ($E3), the block map value of
; the following glyphs ($E8 n), the open-cell value ($E9 0, $EA $FF), a mark
; without a glyph ($EB n), $FF the end.
;
; Entries 18 and 19 point at the same string ($887E); entries 8, 9, 56, 57 are
; only called by other elements; 18 is in no screen list. Names below are from
; the drawings (render.py) and the block map kinds the strings set (the kinds'
; handlers in exB.md).
ElementTable:
  DEFW ElementHatchDome,ElementDropPod,ElementLandingCraft,ElementPlanetRed4,ElementPlanetMagenta2,ElementGunTurret,ElementRockA,ElementRockB
  DEFW ElementRockC,ElementRockD,ElementRockGroundA,ElementGantry,ElementMine,ElementRockSpire,ElementRockGroundB,ElementRadarDish
  DEFW ElementMissile,ElementTeleportBooth,ElementAmmoPod,ElementAmmoPod,ElementGrenadePod,ElementRingPedestal,ElementTrapMark,ElementGirderGreen
  DEFW ElementRubbleGrey,ElementPylonGreen,ElementTwinLauncher,ElementRubbleMagenta,ElementThruster,ElementExoBooth,ElementPlanetGreen3,ElementSporePod
  DEFW ElementSporePodStand,ElementFloorStripYellow,ElementWallStripYellow,ElementPlanetYellow2,ElementPlanetMagenta3,ElementPlanetCyan4,ElementGirderGrey,ElementKind9Mark
  DEFW ElementPlanter,ElementRockClump,ElementSectorGate,ElementGatePost,ElementTurretSlab,ElementLauncherSlab,ElementMushroom,ElementCanister
  DEFW ElementGirderDiagonal2,ElementGirderDiagonal3,ElementCanisterColumn,ElementBallPillars,ElementCircuitYellow,ElementDoorCyan,ElementCircuitGreen,ElementStripYellow4
  DEFW ElementRockCyanA,ElementRockCyanB,ElementRockCyanC,ElementRockCyanD,ElementRockGroundC,ElementRockGroundD

; 0: a yellow dome on the ground, 3 x 2 (screens 35, 39, 41, 50, 62, 68, 92,
; 110, 114, 116)
;
; Font $DAB8, solid. Always on the same screens as element 1.
ElementHatchDome:
  DEFB $E6,$B8,$DA,$DD,$00,$D5,$01,$02
  DEFB $AC,$DD,$03,$D5,$04,$05,$FF

; 1: the green and yellow pod at the top of the screen, 5 x 3, with a jet cell
; (kind 2) and a kind 17 cell
;
; Font $DAB8. Glyphs $10 and $14 have block value 2 (a jet below each:
; AnimateFlames), glyph $12 value 17 (list $ABCC, the handler $ABCF).
ElementDropPod:
  DEFB $E6,$B8,$DA,$DB,$06,$07,$D3,$08
  DEFB $09,$0A,$AA,$DD,$0B,$0C,$D5,$0D
  DEFB $0E,$0F,$AA,$E8,$02,$DC,$10,$E8
  DEFB $01,$DD,$11,$D5,$E8,$11,$12,$E8
  DEFB $01,$13,$E8,$02,$D4,$14,$FF

; 2: the landing craft with its legs and aerials, 11 x 8 (screen 0 and 4, 28,
; 75, 89, 98, 100, 103)
;
; Fonts $DBE8 and $DAB8; two jet cells (kind 2) under its yellow engines. Drawn
; from 2 rows above its record's row.
ElementLandingCraft:
  DEFB $E6,$E8,$DB,$DE,$24,$25,$25,$00
  DEFB $01,$D9,$02,$D6,$03,$04,$25,$25
  DEFB $24,$A6,$DE,$05,$DC,$06,$07,$D4
  DEFB $08,$09,$0A,$D6,$0B,$A7,$DE,$20
  DEFB $DD,$0C,$DC,$0D,$0E,$D4,$0F,$10
  DEFB $11,$DD,$12,$DE,$22,$A6,$DE,$21
  DEFB $D5,$13,$DC,$14,$15,$D4,$16,$17
  DEFB $18,$D5,$19,$D6,$23,$A6,$E8,$02
  DEFB $DC,$E6,$B8,$DA,$10,$E8,$01,$78
  DEFB $01,$E6,$E8,$DB,$1A,$1B,$D4,$1C
  DEFB $1D,$1E,$78,$01,$E6,$B8,$DA,$E8
  DEFB $02,$14,$AA,$E6,$E8,$DB,$E8,$01
  DEFB $D4,$1F,$71,$FD,$DE,$27,$AE,$26
  DEFB $77,$03,$D6,$29,$AE,$28,$FF

; 3: a red planet in the sky, 4 x 4, not solid
;
; Font $DD38, block value 0, open-cell value $FF ($EA): sprites pass in front.
; 32 screens.
ElementPlanetRed4:
  DEFB $E6,$38,$DD,$E8,$00,$EA,$D9,$00
  DEFB $01,$D1,$02,$03,$AB,$D9,$04,$05
  DEFB $D1,$06,$07,$AB,$D9,$08,$09,$D1
  DEFB $0A,$0B,$AB,$D9,$0C,$0D,$D1,$0E
  DEFB $0F,$FF

; 4: a small magenta planet, 2 x 2, not solid
ElementPlanetMagenta2:
  DEFB $E6,$38,$DD,$E8,$00,$EA,$DA,$10
  DEFB $D9,$11,$AD,$D2,$12,$D1,$13,$FF

; 5: a gun turret on a white pedestal, 6 x 5; the barrel's first cell is kind 3
; (AnimateTurrets)
;
; Font $DDD8. The barrel glyphs $12/$13 (the first with block value 3, the
; turret's cell) are the turret's frame of state 2 (TurretFrames).
ElementGunTurret:
  DEFB $E6,$D8,$DD,$E8,$03,$DD,$12,$E8
  DEFB $01,$13,$D6,$00,$77,$00,$DB,$01
  DEFB $02,$DC,$03,$AC,$D3,$04,$05,$D4
  DEFB $06,$AC,$D3,$07,$08,$D4,$09,$AB
  DEFB $DE,$0A,$0B,$D6,$0C,$AC,$DE,$0D
  DEFB $0E,$D6,$0F,$FF

; 6: a 4 x 3 block of the red and magenta rock (font $DED8), called by the
; ground rows
ElementRockA:
  DEFB $E6,$D8,$DE,$D9,$0C,$D2,$0D,$D9
  DEFB $0E,$D2,$0F,$AB,$D2,$00,$D9,$01
  DEFB $D2,$02,$D9,$03,$AB,$D9,$10,$D2
  DEFB $11,$D9,$12,$D2,$13,$AB,$FF

; 7: rock block, 4 x 3
ElementRockB:
  DEFB $E6,$D8,$DE,$D9,$D9,$0E,$D2,$0F
  DEFB $D9,$0D,$D2,$0C,$AB,$D2,$08,$D9
  DEFB $09,$D2,$0A,$D9,$0B,$AB,$D9,$11
  DEFB $D2,$10,$D9,$13,$D2,$12,$AB,$FF

; 8: rock block, 4 x 3 (only called by elements 10 and 14)
ElementRockC:
  DEFB $E6,$D8,$DE,$D9,$D9,$0E,$D2,$0F
  DEFB $D9,$0D,$D2,$0C,$AB,$D2,$03,$D9
  DEFB $02,$D2,$01,$D9,$00,$AB,$D9,$12
  DEFB $D2,$10,$D9,$13,$D2,$11,$AB,$FF

; 9: rock block, 4 x 3 (only called by elements 10 and 14)
ElementRockD:
  DEFB $E6,$D8,$DE,$DA,$D9,$0C,$D2,$0E
  DEFB $D9,$0D,$D2,$0F,$AB,$D2,$0B,$D9
  DEFB $0A,$D2,$09,$D9,$08,$AB,$D9,$13
  DEFB $D2,$12,$D9,$11,$D2,$10,$AB,$FF

; 10: the red rock ground, 32 x 3: blocks 6, 7, 8, 9 twice ($E1 2 ... $E2)
ElementRockGroundA:
  DEFB $E1,$02,$E3,$AD,$86,$78,$04,$E3
  DEFB $CC,$86,$78,$04,$E3,$EC,$86,$78
  DEFB $04,$E3,$0C,$87,$78,$04,$E2,$FF

; 11: the green gantry on two legs with blinking red lights (kind 4), 11 x 10
; (screen 0, 12, 44, 51, 100, 119)
;
; Font $DF78. Printed after $E9 with block value 0: the whole gantry is scenery
; the player walks through. The 6 light cells (block value 4) blink through
; $9118; the legs are drawn by ElementGantryLeg ($E3 $8777) twice.
ElementGantry:
  DEFB $E6,$78,$DF,$E9,$E8,$04,$D9,$0D
  DEFB $78,$04,$0D,$78,$04,$0D,$A4,$E8
  DEFB $00,$DB,$0A,$E4,$05,$0B,$D3,$E4
  DEFB $04,$0B,$0C,$A5,$E3,$77,$87,$78
  DEFB $02,$DB,$0E,$0F,$D3,$10,$11,$12
  DEFB $E3,$77,$87,$AB,$E8,$04,$D9,$13
  DEFB $13,$13,$FF

; The gantry's leg (called twice by element 11): a yellow cap, 5 green rows,
; the foot
ElementGantryLeg:
  DEFB $DD,$08,$D5,$09,$AD,$E1,$05,$DB
  DEFB $00,$D3,$01,$AD,$E2,$DB,$02,$D3
  DEFB $03,$AC,$DB,$04,$05,$D3,$06,$07
  DEFB $FF

; 12: a small yellow mine on the ground, 2 x 1, kind 5 (list $91B0, $9152):
; many per screen
;
; Font $DAB8; block value 5 on its first glyph. $9152 makes it flicker in
; random colours and sets it off when the player comes along its row.
ElementMine:
  DEFB $E6,$B8,$DA,$DD,$E8,$05,$1B,$E8
  DEFB $01,$D5,$1C,$FF

; 13: the yellow rock spire, 3 x 8 (screen 0, 16, 24, 25, 74, 75, 99, 100),
; font $E018
ElementRockSpire:
  DEFB $E6,$18,$E0,$DD,$00,$D5,$01,$AC
  DEFB $DD,$02,$03,$D5,$04,$05,$AB,$DD
  DEFB $06,$07,$D5,$08,$09,$AB,$DD,$0A
  DEFB $0B,$D5,$0C,$0D,$AB,$DD,$0E,$0F
  DEFB $D5,$10,$11,$AB,$DD,$12,$13,$D5
  DEFB $14,$15,$AB,$DD,$16,$17,$D5,$18
  DEFB $19,$AA,$DD,$1E,$1A,$1B,$1C,$1D
  DEFB $FF

; 14: the red rock ground, 32 x 3: blocks 9, 8, 7, 6 twice
ElementRockGroundB:
  DEFB $E1,$02,$E3,$0C,$87,$78,$04,$E3
  DEFB $EC,$86,$78,$04,$E3,$CC,$86,$78
  DEFB $04,$E3,$AD,$86,$78,$04,$E2,$FF

; 15: a radar dish on a white mast, 5 x 8, font $E110
ElementRadarDish:
  DEFB $E6,$10,$E1,$DE,$00,$D6,$01,$02
  DEFB $03,$04,$AA,$DE,$05,$D6,$06,$07
  DEFB $08,$09,$AA,$DE,$0A,$D6,$0B,$0C
  DEFB $0D,$0E,$AB,$DE,$0F,$D6,$10,$11
  DEFB $AD,$12,$AD,$DE,$13,$D6,$14,$15
  DEFB $AC,$DE,$16,$D6,$17,$18,$AC,$DE
  DEFB $16,$D6,$19,$18,$FF

; 16: a white missile on its launch stand, 3 x 6, font $E110 (often 3 in a row)
ElementMissile:
  DEFB $E6,$10,$E1,$DE,$1A,$D6,$1B,$AD
  DEFB $DE,$1C,$D6,$1D,$AD,$DE,$1E,$D6
  DEFB $1F,$AC,$DE,$20,$21,$D6,$22,$23
  DEFB $AC,$DE,$24,$D6,$25,$26,$AC,$DE
  DEFB $27,$D6,$28,$29,$FF

; 17: the cyan teleport booth, 4 x 6: kind 6 cells (list $9930, the teleport
; $98BA) and blinking kind 4 cells
;
; Font $E260. The teleport $98BA reads up ($7B94) when the player stands in a
; booth.
ElementTeleportBooth:
  DEFB $E6,$60,$E2,$DC,$00,$01,$D4,$02
  DEFB $03,$AB,$04,$DC,$E8,$06,$05,$E8
  DEFB $01,$D4,$06,$04,$AB,$E8,$04,$07
  DEFB $AE,$E8,$00,$DC,$04,$AE,$E8,$04
  DEFB $07,$76,$02,$07,$AE,$D4,$E8,$00
  DEFB $04,$AE,$E8,$04,$07,$AB,$E8,$00
  DEFB $DC,$08,$09,$D4,$0A,$0B,$FF

; 18, 19: the white ammunition pod, 2 x 2, kind 7 (list $99F2): ammunition back
; to 99 ($9942)
;
; Font $E2C0. Entry 18 is the same string and no screen uses it.
ElementAmmoPod:
  DEFB $E6,$C0,$E2,$E8,$07,$DE,$00,$E8
  DEFB $00,$D6,$01,$AD,$DE,$02,$D6,$03
  DEFB $FF

; 20: the yellow grenade pod, 2 x 2, kind 8 (list $99F5): grenades back to 10
; ($9942)
ElementGrenadePod:
  DEFB $E6,$C0,$E2,$E8,$08,$DD,$00,$E8
  DEFB $00,$D5,$01,$AD,$DD,$02,$D5,$03
  DEFB $FF

; 21: a cyan ring on a yellow pedestal, 4 x 6, kind 9 cell inside the ring
; (list $9B4B, $9B07)
;
; Font $E2E0. The ring's inside is printed with code $E7 (a space in the main
; font).
ElementRingPedestal:
  DEFB $E6,$E0,$E2,$DC,$00,$01,$D4,$02
  DEFB $03,$AB,$DC,$04,$E8,$09,$D9,$E7
  DEFB $E8,$00,$E7,$E8,$01,$D4,$05,$AB
  DEFB $DC,$06,$E8,$00,$D9,$E7,$E7,$E8
  DEFB $01,$D4,$07,$AB,$DC,$08,$09,$D4
  DEFB $0A,$0B,$AB,$DD,$0C,$0D,$D5,$0E
  DEFB $0F,$AB,$DD,$10,$11,$D5,$12,$13
  DEFB $FF

; 22: no picture: $EB 10 marks one cell of kind 10, a trap (list $9C70, $9C15 /
; $9C8B)
;
; The ZXDB "traps" POKE is at $9C15.
ElementTrapMark:
  DEFB $EB,$0A,$FF

; 23: a green girder platform, 32 x 2 (font $E380)
ElementGirderGreen:
  DEFB $E6,$80,$E3,$DB,$00,$01,$02,$06
  DEFB $07,$00,$02,$06,$07,$00,$01,$01
  DEFB $02,$06,$07,$00,$01,$02,$06,$07
  DEFB $00,$02,$00,$01,$02,$06,$07,$06
  DEFB $07,$00,$01,$02,$79,$E0,$D3,$03
  DEFB $04,$05,$08,$09,$03,$05,$08,$09
  DEFB $03,$04,$04,$05,$08,$09,$03,$04
  DEFB $05,$08,$09,$03,$05,$03,$04,$05
  DEFB $08,$09,$08,$09,$03,$04,$05,$FF

; 24: a grey rubble column, 3 x 5, not solid
ElementRubbleGrey:
  DEFB $E6,$80,$E3,$E8,$00,$DE,$0A,$D6
  DEFB $0B,$0C,$AC,$DE,$0D,$D6,$0E,$0F
  DEFB $AC,$DE,$10,$D6,$11,$12,$AC,$DE
  DEFB $13,$D6,$14,$15,$AC,$DE,$16,$D6
  DEFB $17,$18,$AC,$FF

; 25: a green lattice pylon, 3 x 7, not solid (font $DF78)
ElementPylonGreen:
  DEFB $E6,$78,$DF,$E8,$00,$DD,$08,$D5
  DEFB $09,$AD,$E1,$04,$DB,$00,$D3,$01
  DEFB $AD,$E2,$DB,$02,$D3,$03,$AC,$DB
  DEFB $04,$05,$D3,$06,$07,$FF

; 26: the green and white twin launcher, 4 x 3: cells of kinds 11 and 14 (lists
; $9DC1 and $A333)
;
; Font $E448.
ElementTwinLauncher:
  DEFB $E6,$48,$E4,$E8,$0B,$DB,$09,$E8
  DEFB $0E,$DE,$0A,$E8,$00,$D3,$0B,$DD
  DEFB $0C,$AB,$DB,$E8,$0B,$09,$E8,$0E
  DEFB $DE,$0A,$E8,$00,$D3,$0B,$D5,$0D
  DEFB $AB,$DD,$0E,$D5,$0F,$10,$11,$FF

; 27: a magenta rubble column, 3 x 5, not solid (screens 12-21)
ElementRubbleMagenta:
  DEFB $E6,$80,$E3,$E8,$00,$DA,$0A,$D2
  DEFB $0B,$D9,$0C,$AC,$DA,$0D,$D2,$0E
  DEFB $D9,$0F,$AC,$DA,$10,$D2,$11,$D9
  DEFB $12,$AC,$DA,$13,$D2,$14,$D9,$15
  DEFB $AC,$DA,$16,$D2,$17,$D9,$18,$FF

; 28: a yellow thruster cone hanging under a platform with a jet below (kind
; 2), 3 x 3
;
; Font $E4D8.
ElementThruster:
  DEFB $E6,$D8,$E4,$DD,$00,$D5,$01,$02
  DEFB $AC,$DD,$03,$D5,$04,$05,$AD,$E8
  DEFB $02,$D9,$06,$FF

; 29: the magenta exoskeleton booth, 4 x 7, kind 12 cell (list $9F6E): up in
; front of it puts the suit on or off ($9F2D)
;
; Screens 9, 34, 60, 90, 109.
ElementExoBooth:
  DEFB $E6,$D8,$E4,$DA,$E8,$0C,$07,$E8
  DEFB $01,$08,$D2,$09,$AD,$E8,$00,$DA
  DEFB $0A,$AE,$0B,$AE,$0B,$AE,$0C,$AC
  DEFB $E8,$01,$0D,$0E,$0F,$D2,$10,$11
  DEFB $AB,$DA,$12,$D2,$13,$14,$73,$FC
  DEFB $EA,$E8,$00,$DE,$15,$AE,$16,$AE
  DEFB $17,$AE,$18,$75,$03,$19,$AE,$1A
  DEFB $AE,$1B,$AE,$1C,$FF

; 30: a green planet, 3 x 3, not solid
ElementPlanetGreen3:
  DEFB $E6,$48,$E4,$EA,$E8,$00,$DB,$00
  DEFB $D3,$01,$02,$AC,$DB,$03,$D3,$04
  DEFB $05,$AC,$06,$07,$08,$FF

; 31: a green pod with spikes on top of a stand, 4 x 4, kind 13 cell (list
; $A266) that stays 13 in the block map
;
; Font $E600. Always with element 32.
ElementSporePod:
  DEFB $E6,$00,$E6,$E8,$0D,$DE,$00,$E8
  DEFB $01,$01,$D6,$02,$03,$AC,$DE,$04
  DEFB $D6,$05,$AC,$DE,$06,$DB,$07,$D3
  DEFB $08,$D6,$09,$AB,$DE,$0A,$DB,$0B
  DEFB $D3,$0C,$D6,$0D,$FF

; 32: the magenta stand under element 31, 3 x 5, not solid
ElementSporePodStand:
  DEFB $E6,$00,$E6,$E8,$00,$DE,$0E,$D6
  DEFB $0F,$AD,$DE,$10,$D6,$11,$AD,$DA
  DEFB $12,$D2,$13,$AD,$DA,$12,$D2,$13
  DEFB $AC,$DA,$14,$12,$D2,$13,$15,$FF

; 33: the yellow strip floor, 32 x 1 (font $E840)
ElementFloorStripYellow:
  DEFB $E6,$40,$E8,$E1,$10,$DD,$00,$D5
  DEFB $01,$E2,$FF

; 34: a yellow strip column, 1 x 4
ElementWallStripYellow:
  DEFB $E6,$40,$E8,$DD,$E5,$04,$02,$FF

; 35: a small yellow planet, 2 x 2, not solid (screen 5)
ElementPlanetYellow2:
  DEFB $E6,$38,$DD,$E8,$00,$EA,$DD,$10
  DEFB $D5,$11,$AD,$DD,$12,$D5,$13,$FF

; 36: a magenta and red planet, 3 x 3, not solid
ElementPlanetMagenta3:
  DEFB $E6,$48,$E4,$EA,$E8,$00,$DA,$00
  DEFB $D2,$01,$D9,$02,$AC,$DA,$03,$D2
  DEFB $04,$D9,$05,$AC,$06,$07,$08,$FF

; 37: a cyan planet, 4 x 4, not solid
ElementPlanetCyan4:
  DEFB $E6,$38,$DD,$E8,$00,$EA,$DC,$00
  DEFB $01,$D4,$02,$03,$AB,$DC,$04,$05
  DEFB $D4,$06,$07,$AB,$DC,$08,$09,$D4
  DEFB $0A,$0B,$AB,$DC,$0C,$0D,$D4,$0E
  DEFB $0F,$FF

; 38: a grey girder platform, 32 x 2
ElementGirderGrey:
  DEFB $E6,$80,$E3,$DE,$00,$01,$02,$06
  DEFB $07,$00,$02,$06,$07,$00,$01,$01
  DEFB $02,$06,$07,$00,$01,$02,$06,$07
  DEFB $00,$02,$00,$01,$02,$06,$07,$06
  DEFB $07,$00,$01,$02,$79,$E0,$D6,$03
  DEFB $04,$05,$08,$09,$03,$05,$08,$09
  DEFB $03,$04,$04,$05,$08,$09,$03,$04
  DEFB $05,$08,$09,$03,$05,$03,$04,$05
  DEFB $08,$09,$08,$09,$03,$04,$05,$FF

; 39: no picture: $EB 9 marks a cell of kind 9 (list $9B4B), always in pairs
ElementKind9Mark:
  DEFB $EB,$09,$FF

; 40: a green bowl of red rocks on a grey foot, 4 x 5 (font $E860)
ElementPlanter:
  DEFB $E6,$60,$E8,$D9,$00,$01,$02,$D1
  DEFB $03,$AB,$DB,$04,$05,$05,$D3,$06
  DEFB $AB,$DB,$07,$08,$D3,$09,$0A,$AB
  DEFB $DB,$0B,$0C,$D3,$0D,$0E,$AB,$DE
  DEFB $0F,$D6,$10,$11,$12,$FF

; 41: a clump of the red rock, 5 x 3 (screen 22), fonts $E860 and $DED8
ElementRockClump:
  DEFB $E6,$60,$E8,$D9,$13,$D2,$14,$D9
  DEFB $15,$AB,$D9,$16,$D2,$17,$D9,$18
  DEFB $D2,$19,$D9,$1A,$D2,$1B,$A9,$E6
  DEFB $D8,$DE,$D2,$00,$D9,$01,$D2,$02
  DEFB $D9,$03,$D2,$04,$D9,$05,$FF

; 42: the two tall pillars with yellow balls, 8 x 15: screens 24, 49, 74, 99,
; 124, the last of each 25
;
; Font $E940. The pillars are ElementGatePillar ($E3 $8B75) twice; $EB 15 marks
; a cell of kind 15 (list $A814, $A7D6) above each, $EB 16 one of kind 16 (list
; $AAEF, $A817) between them, by the cyan bar on the floor.
ElementSectorGate:
  DEFB $E6,$40,$E9,$E3,$75,$8B,$78,$02
  DEFB $EB,$0F,$78,$04,$E3,$75,$8B,$86
  DEFB $FC,$E8,$01,$DC,$10,$11,$D4,$12
  DEFB $13,$73,$FD,$EB,$10,$FF

; A pillar of the sector gate: the ball, the neck, the green collar, the
; magenta column (called twice)
ElementGatePillar:
  DEFB $E8,$00,$DD,$00,$D5,$01,$AD,$DD
  DEFB $02,$D5,$03,$AD,$DE,$04,$D6,$05
  DEFB $AD,$DE,$06,$D4,$07,$AD,$DB,$08
  DEFB $D3,$09,$AD,$DB,$0A,$D3,$0B,$AD
  DEFB $DA,$0C,$D2,$0D,$AD,$E1,$06,$DA
  DEFB $0E,$D2,$0F,$AD,$E2,$DA,$14,$D2
  DEFB $15,$AD,$DA,$16,$D2,$17,$FF

; 43: a small green post with a magenta light (kind 4: it blinks), 2 x 3;
; beside the sector gate and on other screens
ElementGatePost:
  DEFB $E6,$40,$E9,$E8,$04,$E0,$03,$18
  DEFB $AE,$E8,$00,$DB,$19,$AD,$1A,$D3
  DEFB $1B,$1C,$FF

; 44: a gun turret lying on a slab, 6 x 2, barrel kind 3 (AnimateTurrets),
; fonts $DDD8 and $EA28
ElementTurretSlab:
  DEFB $E6,$D8,$DD,$E8,$03,$DD,$12,$E8
  DEFB $01,$13,$E6,$28,$EA,$DE,$00,$01
  DEFB $D6,$02,$03,$AA,$DB,$04,$05,$D3
  DEFB $06,$07,$FF

; 45: a twin launcher on a slab, 6 x 2, kinds 11 and 14 (as element 26)
ElementLauncherSlab:
  DEFB $E6,$28,$EA,$DD,$E8,$0B,$08,$E8
  DEFB $0E,$D5,$09,$DB,$0A,$0B,$D3,$E8
  DEFB $00,$0C,$0D,$AB,$DD,$0E,$0F,$D5
  DEFB $0F,$10,$FF

; 46: a green mushroom tree, 3 x 4 (font $EAF0)
ElementMushroom:
  DEFB $E6,$F0,$EA,$DB,$00,$01,$D3,$02
  DEFB $AC,$DB,$03,$04,$D3,$05,$AC,$DB
  DEFB $06,$D3,$07,$08,$AC,$DB,$09,$D3
  DEFB $0A,$0B,$FF

; 47: a yellow ribbed canister, 3 x 4, not solid (also the unit of element 50)
ElementCanister:
  DEFB $E6,$F0,$EA,$E8,$00,$DD,$0C,$D5
  DEFB $0D,$0E,$AC,$DD,$0F,$D5,$10,$11
  DEFB $AC,$DD,$0F,$D5,$10,$11,$AC,$DD
  DEFB $12,$D5,$13,$14,$FF

; 48: a white diagonal girder, 2 x 2, solid, open-cell value $FF
ElementGirderDiagonal2:
  DEFB $E6,$F0,$EA,$EA,$DE,$15,$D6,$16
  DEFB $AC,$DE,$17,$D6,$18,$AD,$19,$FF

; 49: a white diagonal girder, 3 x 3, solid, open-cell value $FF
ElementGirderDiagonal3:
  DEFB $E6,$F0,$EA,$EA,$DE,$1A,$D6,$1B
  DEFB $AE,$DE,$1C,$D6,$1D,$AE,$DE,$1E
  DEFB $FF

; 50: four canisters (element 47) one above the other, 3 x 16
ElementCanisterColumn:
  DEFB $E1,$04,$E3,$10,$8C,$7C,$00,$E2
  DEFB $FF

; 51: two short pillars with cyan balls below, 8 x 6 (screens 25, 66), each
; with an $EB 15 mark (kind 15)
;
; Font $EBE8; the pillars are ElementBallPillar ($E3 $8C67).
ElementBallPillars:
  DEFB $E6,$E8,$EB,$E3,$67,$8C,$7C,$02
  DEFB $EB,$0F,$74,$04,$E3,$67,$8C,$FF

; A pillar of element 51 (called twice)
ElementBallPillar:
  DEFB $DD,$00,$D5,$01,$AD,$DD,$02,$D5
  DEFB $03,$AD,$DE,$04,$DC,$05,$AD,$DE
  DEFB $06,$DC,$07,$AD,$DC,$08,$D4,$09
  DEFB $AD,$DC,$0A,$D4,$0B,$FF

; 52: a yellow circuit-panel platform, 32 x 2 (font $EC48)
ElementCircuitYellow:
  DEFB $E6,$48,$EC,$DD,$00,$01,$02,$06
  DEFB $07,$00,$02,$06,$07,$00,$01,$01
  DEFB $02,$06,$07,$00,$01,$02,$06,$07
  DEFB $00,$02,$00,$01,$02,$06,$07,$06
  DEFB $07,$00,$01,$02,$79,$E0,$D5,$03
  DEFB $04,$05,$08,$09,$03,$05,$08,$09
  DEFB $03,$04,$04,$05,$08,$09,$03,$04
  DEFB $05,$08,$09,$03,$05,$03,$04,$05
  DEFB $08,$09,$08,$09,$03,$04,$05,$FF

; 53: a cyan door column, 3 x 5, not solid
ElementDoorCyan:
  DEFB $E6,$48,$EC,$E8,$00,$DC,$0A,$0B
  DEFB $D4,$0C,$AC,$DC,$0D,$78,$01,$D4
  DEFB $0E,$AC,$DC,$0D,$D6,$12,$D4,$0E
  DEFB $AC,$DC,$0D,$78,$01,$D4,$0E,$AC
  DEFB $DC,$0F,$D4,$10,$11,$FF

; 54: a green circuit-panel platform, 32 x 2
ElementCircuitGreen:
  DEFB $E6,$48,$EC,$DB,$00,$01,$02,$06
  DEFB $07,$00,$02,$06,$07,$00,$01,$01
  DEFB $02,$06,$07,$00,$01,$02,$06,$07
  DEFB $00,$02,$00,$01,$02,$06,$07,$06
  DEFB $07,$00,$01,$02,$79,$E0,$D3,$03
  DEFB $04,$05,$08,$09,$03,$05,$08,$09
  DEFB $03,$04,$04,$05,$08,$09,$03,$04
  DEFB $05,$08,$09,$03,$05,$03,$04,$05
  DEFB $08,$09,$08,$09,$03,$04,$05,$FF

; 55: a yellow strip, 4 x 1 (font $E840)
ElementStripYellow4:
  DEFB $E6,$40,$E8,$E1,$02,$DD,$00,$D5
  DEFB $01,$E2,$FF

; 56: a 4 x 3 block of the green and cyan rock (font $DED8), only called by
; elements 60, 61
ElementRockCyanA:
  DEFB $E6,$D8,$DE,$DC,$0C,$DB,$0D,$DC
  DEFB $0E,$DB,$0F,$AB,$DB,$00,$DC,$01
  DEFB $DB,$02,$DC,$03,$AB,$DC,$10,$DB
  DEFB $11,$DC,$12,$DB,$13,$AB,$FF

; 57: green and cyan rock block, 4 x 3, only called by elements 60, 61
ElementRockCyanB:
  DEFB $E6,$D8,$DE,$DC,$DC,$0E,$DB,$0F
  DEFB $DC,$0D,$DB,$0C,$AB,$DB,$08,$DC
  DEFB $09,$DB,$0A,$DC,$0B,$AB,$DC,$11
  DEFB $DB,$10,$DC,$13,$DB,$12,$AB,$FF

; 58: green and cyan rock block, 4 x 3 (also on screen 76)
ElementRockCyanC:
  DEFB $E6,$D8,$DE,$DC,$DC,$0E,$DB,$0F
  DEFB $DC,$0D,$DB,$0C,$AB,$DB,$03,$DC
  DEFB $02,$DB,$01,$DC,$00,$AB,$DC,$12
  DEFB $DB,$10,$DC,$13,$DB,$11,$AB,$FF

; 59: green and cyan rock block, 4 x 3 (also on screen 76)
ElementRockCyanD:
  DEFB $E6,$D8,$DE,$DB,$DC,$0C,$DB,$0E
  DEFB $DC,$0D,$DB,$0F,$AB,$DB,$0B,$DC
  DEFB $0A,$DB,$09,$DC,$08,$AB,$DC,$13
  DEFB $DB,$12,$DC,$11,$DB,$10,$AB,$FF

; 60: the green and cyan rock ground, 32 x 3: blocks 56, 57, 58, 59 twice
; (screens 75-120)
ElementRockGroundC:
  DEFB $E1,$02,$E3,$46,$8D,$78,$04,$E3
  DEFB $65,$8D,$78,$04,$E3,$85,$8D,$78
  DEFB $04,$E3,$A5,$8D,$78,$04,$E2,$FF

; 61: the green and cyan rock ground, 32 x 3: blocks 59, 58, 57, 56 twice
ElementRockGroundD:
  DEFB $E1,$02,$E3,$A5,$8D,$78,$04,$E3
  DEFB $85,$8D,$78,$04,$E3,$65,$8D,$78
  DEFB $04,$E3,$46,$8D,$78,$04,$E2,$FF
