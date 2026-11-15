; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The rooms: 16 maps of 48 x 5 blocks, the 192 blocks of 4 x 4 characters
;
; A room is a strip of six screens, 48 blocks across and 5 down, 240 bytes at RoomMaps $7600 + 240 x room, stored row
; by row. A screen shows 8 block columns (32 characters); RoomScreen $950D holds 8 x the screen, the map column of its
; left edge. DrawRoom $A89D expands the screen's 8 x 5 blocks through Blocks $8500 (16 character codes a block, 4 rows
; of 4) into the character map $F080. The room table RoomTable $953B gives the exits, the zone and one enemy kind a
; screen.
;
; The maps are also state: TakeBlockItem $B33D turns a taken item (block $1B) into block $47, KindTurret $C457 turns a
; dead turret's block $12 into $2B; NewGame $915B turns them back (every $2B into $12, every $47 into $1B). The
; resources are text grids (src/res/rooms/README.md); tools/roommap.py draws every room and the world map from them.
; --------------------------------------------------------------------------------------------------------------------

; Room 0: the surface (zone 0), the start, the password doors
Room0Map:
  INCBIN "res/rooms/room-00.bin",$0000,240

; Room 1 (zone 0)
Room1Map:
  INCBIN "res/rooms/room-01.bin",$0000,240

; Room 2 (zone 0)
Room2Map:
  INCBIN "res/rooms/room-02.bin",$0000,240

; Room 3 (zone 0): the first code message
Room3Map:
  INCBIN "res/rooms/room-03.bin",$0000,240

; Room 4 (zone 1)
Room4Map:
  INCBIN "res/rooms/room-04.bin",$0000,240

; Room 5 (zone 1)
Room5Map:
  INCBIN "res/rooms/room-05.bin",$0000,240

; Room 6 (zone 1)
Room6Map:
  INCBIN "res/rooms/room-06.bin",$0000,240

; Room 7 (zone 2, the moon)
Room7Map:
  INCBIN "res/rooms/room-07.bin",$0000,240

; Room 8 (zone 2)
Room8Map:
  INCBIN "res/rooms/room-08.bin",$0000,240

; Room 9 (zone 2)
Room9Map:
  INCBIN "res/rooms/room-09.bin",$0000,240

; Room 10 (zone 3)
Room10Map:
  INCBIN "res/rooms/room-10.bin",$0000,240

; Room 11 (zone 3)
Room11Map:
  INCBIN "res/rooms/room-11.bin",$0000,240

; Room 12 (zone 3)
Room12Map:
  INCBIN "res/rooms/room-12.bin",$0000,240

; Room 13 (zone 3)
Room13Map:
  INCBIN "res/rooms/room-13.bin",$0000,240

; Room 14 (zone 3)
Room14Map:
  INCBIN "res/rooms/room-14.bin",$0000,240

; Room 15 (zone 3): the last room, Scott at screen 5
Room15Map:
  INCBIN "res/rooms/room-15.bin",$0000,240

; The 192 blocks: 16 character codes each, 4 rows of 4 (the codes index the
; live zone's set)
;
; Read by DrawRoom $A89D for every block of a screen ($A8E0-$A920). Witness:
; every room drawn in c1 and the RZX segments.
Blocks:
  INCBIN "res/blocks/blocks.bin",$0000,3072

  ORG $950A

; The room, 0-15
RoomNumber:
  DEFB $00
RoomRecord:
  DEFB $00,$00            ; the room's RoomTable record
RoomScreen:
  DEFB $00                ; 8 x the screen (0-5): the map column of the
                          ; screen's left edge

; The 11 masks lying in the rooms, 4 bytes each [room + bit 7 taken, mask kind,
; x, y], $FF at the end
;
; PlacePickupsInScreen $A9BE shows the records of the room's screen that are
; not taken; CheckPickups $B126 sets bit 7 when Matt takes one; NewGame clears
; the bits. Eleven pick-ups; kinds 2, 3, 9 and 10 (ULTRA FLASH, MIRAGE, LAVA
; SHOT, STREAMER) are in no record and cannot be had in play. Also
; src/res/tables/pickups.csv.
PickupTable:
  INCBIN "res/tables/pickups.bin",$0000,45

; 16 records of 12 bytes: left, right, pod, exit 3, zone, arrival, an enemy
; kind a screen
;
; Bytes: 0 the room to the left, 1 to the right ($FF none), 2 the pod's
; destination (Teleport $B6B3), 3 an exit read only by the never-run ExitByte3
; $B6D8, 4 the zone, 5 the arrival place after a pod: x = (b & $1F) x 4 + $40,
; RoomScreen = (b & $E0) / 4, 6-11 one enemy kind (EnemyKind $BFB0) for each of
; the six screens (DrawRoom $A89D). The table is also src/res/tables/rooms.csv
; (tools/res_formats.py writes it from these bytes).
RoomTable:
  INCBIN "res/tables/rooms.bin",$0000,192

; 5-row glyphs: A-Z, then 0-9 at $967D, '.' $96AF, ':' $96B4, space $96B9
Font:
  INCBIN "res/font/font5.bin",$0000,195

; HL = the 5-byte glyph of character A (letters, digits, '.', ':', space)
;
; Witness: L1 40146 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).
CharGlyph:
  AND $7F
  CP $61
  JR C,l_96CA
  CP $7B
  JR NC,l_96CA
  SUB $20
l_96CA:
  CP $41
  JR C,l_96D9
  CP $5B
  JR NC,l_96D9
  SUB $41
  LD BC,Font
  JR l_9703
l_96D9:
  CP $30
  JR C,l_96E8
  CP $3A
  JR NC,l_96E8
  SUB $30
  LD BC,$967D
  JR l_9703
l_96E8:
  CP $2E
  JR NZ,l_96F2
  LD BC,$96AF
  XOR A
  JR l_9703
l_96F2:
  CP $3A
  JR NZ,l_96FC
  XOR A
  LD BC,$96B4
  JR l_9703
l_96FC:
  CP $20
  RET NZ
  XOR A
  LD BC,$96B9
l_9703:
  LD L,A
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  ADD HL,BC
  XOR A
  RET

; $FF in the menu and the death sequence: no scroller, no BREAK, the menu tune
; loops
NotInPlay:
  DEFB $00
MenuFlag:
  DEFB $00,$01            ; non-zero: Interrupt runs MenuInterrupt instead of
                          ; CheatCheck
HudSaved:
  DEFB $FF                ; $FF as loaded: the first Menu skips SaveHud
                          ; (PlayPanel $F600 still holds the loaded panel);
                          ; Menu then sets 0, so every later Menu copies the
                          ; screen's panel back to $F600 (BuildTables overwrote
                          ; it)
MenuColours:
  DEFB $00,$01,$02,$03,$04,$05,$06,$07 ; 16 colours for the menu's lit icon and
  DEFB $07,$06,$05,$04,$03,$02,$01,$00 ; bars
MenuColourCount:
  DEFB $00,$00            ; the colour cycle's step

  ORG $A89A

; RoomMaps + 240 x room + RoomScreen: the screen's first block
MapPointer:
  DEFB $00,$00,$00

; Draw the screen RoomScreen of room RoomNumber and set up its objects,
; pick-ups and message
;
; Room 15 at screen 5 is the end: Ending $ADF6. Clears objects 2-7 (3-7 while
; the chaser lives), expands the 8 x 5 blocks into the character map, SwapZone,
; marks every cell dirty and flushes, sets EnemyKind $BFB0 from RoomTable byte
; 6 + screen, then MoonMasks $ADD2, AnimatedCharList $AB6B, FindLift $AA75,
; PlaceTurrets $AC42, FindSpawnPoints $ACA0, FindBlockItems $ACEA, FindFloorRow
; $AC80, PlacePickupsInScreen $A9BE, EffectStops+1 = $FF and RoomMessage $AD28.
; Before the blocks: a new room (RoomNumber not MapPointer+2) clears
; ChaserState, ShotOff $BD7F ends Matt's shot, and with ChaserState set only
; objects 3-7 are cleared (the chaser survives a screen change).
;
; Witness: L1 87 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawRoom:
  LD A,(RoomNumber)
  CP $0F
  JR NZ,l_A8AC
  LD A,(RoomScreen)
  CP $28
  JP Z,Ending
l_A8AC:
  XOR A
  LD (FirstSpriteChar),A
  LD A,(RoomNumber)
  LD HL,MapPointer+$0002
  CP (HL)
  LD (HL),A
  JR Z,l_A8BE
  XOR A
  LD (ChaserState),A
l_A8BE:
  CALL ShotOff
  LD IX,Enemies
  LD DE,$0026
  LD B,$06
  LD A,(ChaserState)
  AND A
  JR Z,l_A8D3
  ADD IX,DE
  DEC B
l_A8D3:
  LD (IX+$00),$00
  LD (IX+$1F),$00
  ADD IX,DE
  DJNZ l_A8D3
  LD DE,CharMap
  EXX
  LD A,(RoomNumber)
  LD L,A
  LD H,$00
  LD E,L
  LD D,H
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,HL
  LD DE,RoomTable
  ADD HL,DE
  LD (RoomRecord),HL
  LD L,A
  LD H,$00
  LD E,L
  LD D,H
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,Room0Map
  ADD HL,DE
  LD A,(RoomScreen)
  ADD A,L
  LD L,A
  JR NC,l_A911
  INC H
l_A911:
  LD (MapPointer),HL
  LD DE,$0028
  LD C,$05
l_A919:
  LD B,$08
l_A91B:
  LD A,(HL)
  EXX
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Blocks
  ADD HL,BC
  LDI
  LDI
  LDI
  LDI
  PUSH DE
  LD A,$1C
  ADD A,E
  LD E,A
  JR NC,l_A938
  INC D
l_A938:
  LDI
  LDI
  LDI
  LDI
  LD A,$1C
  ADD A,E
  LD E,A
  JR NC,l_A947
  INC D
l_A947:
  LDI
  LDI
  LDI
  LDI
  LD A,$1C
  ADD A,E
  LD E,A
  JR NC,l_A956
  INC D
l_A956:
  LDI
  LDI
  LDI
  LDI
  POP DE
  EXX
  INC HL
  DJNZ l_A91B
  EXX
  LD A,$60
  ADD A,E
  LD E,A
  JR NC,l_A96B
  INC D
l_A96B:
  EXX
  ADD HL,DE
  DEC C
  JP NZ,l_A919
  LD IX,(RoomRecord)
  LD A,(IX+$04)
  CALL SwapZone
  LD HL,DirtyMap
  LD DE,DirtyMap+$0001
  LD BC,$023F
  LD (HL),$01
  LDIR
  CALL FlushDirty
  LD HL,(RoomRecord)
  LD DE,$0006
  ADD HL,DE
  LD A,(RoomScreen)
  RRCA
  RRCA
  RRCA
  LD E,A
  ADD HL,DE
  LD A,(HL)
  LD (EnemyKind),A
  CALL MoonMasks
  CALL AnimatedCharList
  CALL FindLift
  CALL PlaceTurrets
  CALL FindSpawnPoints
  CALL FindBlockItems
  CALL FindFloorRow
  CALL PlacePickupsInScreen
  LD A,$FF
  LD (EffectStops+$0001),A
  JP RoomMessage

; Make the icons of this screen's untaken masks (PickupTable) as characters
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
PlacePickupsInScreen:
  LD HL,PickupTable
  LD DE,$0004
  LD A,(RoomNumber)
  LD C,A
  LD A,(RoomScreen)
  ADD A,A
  ADD A,A
  LD B,A
  EXX
  LD IX,PickupRecords
  CALL PlacePickup
  LD IX,PickupRecords+$0008

; One pick-up: its icon from MaskIcons $D580 + 32 x kind, coloured
; MaskColours[kind]
;
; Witness: L1 172 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
PlacePickup:
  LD (IX+$01),$FF
  CALL FindPickup
  CP $FF
  RET Z
  EXX
  LD (IX+$05),L
  LD (IX+$06),H
  INC HL
  LD A,(HL)
  LD (IX+$02),A
  INC HL
  LD A,(HL)
  LD (IX+$01),A
  INC HL
  LD A,(HL)
  LD (IX+$00),A
  INC HL
  LD A,(IX+$01)
  SUB B
  EXX
  LD E,A
  LD D,$00
  LD A,(IX+$00)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD DE,CharMap+$0040
  ADD HL,DE
  LD (IX+$03),L
  LD (IX+$04),H
  LD A,(FirstSpriteChar)
  LD L,A
  LD (IX+$07),A
  ADD A,$04
  LD (FirstSpriteChar),A
  LD H,$1D
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  LD L,(IX+$02)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,MaskIcons
  ADD HL,DE
  POP DE
  LD BC,$0020
  LDIR
  SUB $04
  LD C,A
  LD B,$EE
  LD A,(IX+$02)
  LD L,A
  LD H,$00
  LD DE,MaskColours
  ADD HL,DE
  LD A,(HL)
  OR $40
  LD (BC),A
  INC C
  LD (BC),A
  INC C
  LD (BC),A
  INC C
  LD (BC),A
  RET

; The PickupTable record of this room at Matt's place
;
; Witness: L1 172 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FindPickup:
  EXX
l_AA5A:
  LD A,(HL)
  CP $FF
  EXX
  RET Z
  EXX
  CP C
  JR Z,l_AA66
l_AA63:
  ADD HL,DE
  JR l_AA5A
l_AA66:
  INC HL
  INC HL
  LD A,(HL)
  DEC HL
  DEC HL
  SUB B
  CP $20
  JR NC,l_AA63
  EXX
  RET

; The zone-0 lift's map address and direction (AnimateLift $CA3D)
LiftPlace:
  DEFB $00,$00,$00

; Zone 0: find character $34 in the screen (the lift), else none
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FindLift:
  LD HL,$0000
  LD (LiftPlace),HL
  LD A,(ZoneSlots)
  AND A
  RET NZ
  LD A,(ZoneSlots)
  AND A
  RET NZ
  LD HL,CharMap+$0040
  LD BC,$0240
  LD E,$34
l_AA8D:
  LD A,(HL)
  CP E
  JR Z,l_AA98
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_AA8D
  RET
l_AA98:
  INC HL
  LD (LiftPlace),HL
  XOR A
  LD (LiftPlace+$0002),A
  RET

; The dirty-map addresses of the screen's animated characters, $FFxx at the end
AnimatedCells:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; List the cells of the zone's animated characters (AnimatedChars) into
; AnimatedCells
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
AnimatedCharList:
  LD HL,AnimatedChars+$003F
  LD A,(ZoneSlots)
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (l_AB89+$0001),HL
  LD HL,AnimatedCells
  LD (AnimatedCells+$00C8),HL
  LD HL,CharMap+$0040
  LD BC,$0240
l_AB89:
  LD DE,$0000
l_AB8C:
  LD A,(DE)
  AND A
  JR Z,l_ABA8
  CP (HL)
  JR Z,l_AB98
  JR NC,l_ABA8
  INC DE
  JR l_AB8C
l_AB98:
  LD DE,(AnimatedCells+$00C8)
  LD A,L
  LD (DE),A
  INC DE
  LD A,H
  ADD A,$03
  LD (DE),A
  INC DE
  LD (AnimatedCells+$00C8),DE
l_ABA8:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_AB89
  LD HL,(AnimatedCells+$00C8)
  INC HL
  LD (HL),$00
  RET

; The animated character codes of each zone, 0-terminated, and the four list
; pointers at $ABF5
AnimatedChars:
  DEFB $60,$61,$62,$63,$9C,$9D,$BC,$BD
  DEFB $E2,$E3,$E4,$E5,$E6,$E7,$E8,$E9
  DEFB $EB,$EC,$ED,$EE,$00,$51,$52,$71
  DEFB $72,$A1,$A2,$C0,$C1,$E0,$E1,$E2
  DEFB $E3,$E4,$E5,$E6,$E7,$E8,$E9,$00
  DEFB $6C,$E2,$E3,$E4,$E5,$E6,$E7,$E8
  DEFB $E9,$00,$E0,$E1,$E2,$E3,$E5,$E6
  DEFB $E7,$E8,$E9,$EA,$EB,$EC,$00,$B5
  DEFB $AB,$CA,$AB,$DD,$AB,$E7,$AB,$00

; B, C = the place of the first block A in the screen's map
;
; Witness: L1 258 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FindBlock:
  LD (AnimatedChars+$0047),A
  LD HL,(MapPointer)
  LD DE,$0028
  LD BC,$0805
l_AC09:
  CP (HL)
  JR Z,l_AC16
  INC HL
  DJNZ l_AC09
  ADD HL,DE
  LD B,$08
  DEC C
  JR NZ,l_AC09
  RET

; l_AC16
;
; Used by the routines at FindBlock and FindNextBlock.
l_AC16:
  PUSH BC
  EXX
  POP BC
  LD A,$08
  SUB B
  RLCA
  RLCA
  RLCA
  RLCA
  ADD A,$40
  LD B,A
  LD A,$05
  SUB C
  RRCA
  RRCA
  RRCA
  SUB $10
  LD C,A
  OR $FF
  RET

; The next one
;
; Witness: L1 19 (door, rzx- x7).
FindNextBlock:
  LD A,(AnimatedChars+$0047)
  EXX
  JR l_AC38
l_AC35:
  CP (HL)
  JR Z,l_AC16
l_AC38:
  INC HL
  DJNZ l_AC35
  ADD HL,DE
  LD B,$08
  DEC C
  JR NZ,l_AC35
  RET

; Every block $12 of the screen becomes a turret object (kind 4, template 2:
; animation 3, so it bobs at once), the next slot reserved ($40); the SUB $02
; at $AC55 is dead (LD A,C follows), so y is the block's row
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
PlaceTurrets:
  LD A,(ChaserState)
  AND A
  RET NZ
  LD A,$12
  CALL FindBlock
  RET Z
  LD IX,Enemies
l_AC51:
  LD (IX+$03),B
  LD A,C
  SUB $02
  LD A,C
  LD (IX+$04),A
  LD (IX+$00),$04
  LD (IX+$1C),$00
  EXX
  LD (IX+$11),L
  LD (IX+$12),H
  EXX
  LD HL,EnemyTemplates+$0018
  CALL SetupObject
  LD (IX+$26),$40
  CALL FindNextBlock
  RET Z
  LD IX,Enemies+$004C
  JR l_AC51

; the first character row with a solid attribute
FloorRow:
  DEFB $00

; FloorRow from the attributes (bit 7)
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FindFloorRow:
  XOR A
  EX AF,AF'
  LD HL,CharMap+$0040
  LD DE,$0020
  LD B,$EF
l_AC8A:
  LD C,(HL)
  LD A,(BC)
  BIT 7,A
  JR NZ,l_AC97
  ADD HL,DE
  EX AF,AF'
  ADD A,$08
  EX AF,AF'
  JR l_AC8A
l_AC97:
  EX AF,AF'
  LD (FloorRow),A
  RET

; Two map places of block $61, where kind-12 enemies rise
SpawnPoints:
  DEFB $00,$00,$00,$00

; Up to two blocks $61 into SpawnPoints
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FindSpawnPoints:
  LD HL,$0000
  LD (SpawnPoints),HL
  LD (SpawnPoints+$0002),HL
  LD A,$61
  CALL FindBlock
  RET Z
  LD (SpawnPoints),BC
  CALL FindNextBlock
  RET Z
  LD (SpawnPoints+$0002),BC
  RET

; Room 0's four door lamps at map $7628 (screen 5, top row): blocks $45/$46
; shut, $1E/$1F lit for each password entered
;
; Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).
PasswordPods:
  LD HL,Room0Map+$0028
  LD DE,PasswordFlags
  LD B,$04
l_ACC4:
  LD A,(DE)
  INC DE
  AND A
  JR NZ,l_ACD1
  LD (HL),$45
  INC HL
  LD (HL),$46
  INC HL
  JR l_ACD7
l_ACD1:
  LD (HL),$1E
  INC HL
  LD (HL),$1F
  INC HL
l_ACD7:
  DJNZ l_ACC4
  RET

; Up to four block-$1B items of the screen (map address, place)
BlockItems:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The block-$1B items into BlockItems
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FindBlockItems:
  LD IX,BlockItems
  LD DE,$0004
  LD B,$04
l_ACF3:
  LD (IX+$00),$00
  ADD IX,DE
  DJNZ l_ACF3
  LD A,$1B
  CALL FindBlock
  RET Z
  LD IX,BlockItems
  LD DE,$0004
  LD H,$03
l_AD0A:
  LD A,B
  ADD A,$04
  LD (IX+$00),A
  LD A,C
  ADD A,$08
  LD (IX+$01),A
  EXX
  LD (IX+$02),L
  LD (IX+$03),H
  EXX
  ADD IX,DE
  CALL FindNextBlock
  RET Z
  DEC H
  JR NZ,l_AD0A
  RET
