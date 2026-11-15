; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The rooms: drawing a room, the exits, the objects made, the spawners
;
; DrawRoom draws the room Room $A0B8 from RoomMaps $75E0: each block of BlockDefs $6CE0 is 3 x 3 characters; each
; character goes into the back buffer (CharGraphics $63E0), its attribute into the attribute shadow $E55F (CharAttrs
; $6BE0) and its flag into the grid $E1FF (CharFlags $62E0); the animated characters are listed in SceneryCellList
; $D962 with their cell index in $DE9F. ReadExits takes the room's exits and object list from RoomExits $B133;
; MakeObjects builds the records from the list.
;
; Monsters keep coming: the random spawner (SpawnRandom $C9CA) makes one of SpawnKind $A088 from the room's spawn
; sides every SpawnPeriod passes; rooms 2, 3, 4, 6 and 20 also run the scripted spawn (ScriptSpawn $A9F4).
; --------------------------------------------------------------------------------------------------------------------

; Draw the room: silence, the map's 7 x 10 blocks into the grid, the attribute
; shadow and SceneryCellList (its pixel writes into the buffer are wiped by
; BuildRoom's ClearBuffer after it; the cell list redraws them)
;
; Witness: L1 80 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
DrawRoom:
  LD A,(SparkleOn)
  OR A
  CALL Z,SoundSilence
  LD HL,CellIndexMap
  LD DE,CellIndexMap+$0001
  LD BC,$065F
  LD (HL),$00
  LDIR
  LD A,$01
  LD (RoomCellPtr),A
  LD IX,BackBuffer
  LD HL,SceneryCellList
  LD (RoomColumn),HL
  LD A,(Room)
  LD E,A
  LD D,$00
  LD B,$46
  CALL Multiply
  LD DE,RoomMaps
  ADD HL,DE
  PUSH HL
  POP IY
  LD B,$07
DrawRoomRow:
  PUSH BC                 ; each block row
  PUSH IX
  LD B,$0A
DrawRoomBlock:
  PUSH BC                 ; each block
  LD A,(IY+$00)
  LD E,A
  LD D,$00
  LD B,$09
  CALL Multiply
  LD DE,BlockDefs
  ADD HL,DE
  CALL DrawBlockRow
  LD DE,$0003
  ADD IX,DE
  INC IY
  POP BC
  DJNZ DrawRoomBlock
  POP IX
  LD DE,$0300
  ADD IX,DE
  POP BC
  DJNZ DrawRoomRow
  LD HL,$5860
  LD BC,$02A0
DrawRoomAttrs:
  LD A,(HL)
  OR A
  JP NZ,DrawRoomAttrLoop
  LD (HL),$47
DrawRoomAttrLoop:
  DEC BC
  INC HL
  LD A,B
  OR C
  JP NZ,DrawRoomAttrs
  LD A,(SparkleOn)
  OR A
  RET NZ
  CALL SoundReset
  RET

; One row of 10 blocks
;
; Witness: L1 5655 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
DrawBlockRow:
  PUSH IX
  LD B,$03
BlockRowLoop:
  PUSH BC
  LD B,$03
BlockRowChar:
  PUSH BC
  LD A,(HL)
  CALL DrawRoomCell
  INC HL
  INC IX
  POP BC
  DJNZ BlockRowChar
  LD DE,$00FD
  ADD IX,DE
  POP BC
  DJNZ BlockRowLoop
  POP IX
  RET

; One block: its 3 x 3 characters into the buffer, the attribute shadow and the
; grid; an animated character listed
;
; Witness: L1 50898 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
DrawRoomCell:
  PUSH HL
  PUSH AF
  LD (Temp2),A
  LD E,A
  LD D,$00
  LD HL,CharAttrs
  ADD HL,DE
  LD A,(HL)
  PUSH IX
  POP HL
  CALL DrawRoomChar
  LD (HL),A
  LD DE,AttrShadowPlay
  AND A
  SBC HL,DE
  LD DE,RoomGridPlay
  ADD HL,DE
  PUSH HL
  LD (RoomCellPtr+$0001),HL
  LD A,(Temp2)
  LD E,A
  LD D,$00
  LD HL,CharFlags
  ADD HL,DE
  LD A,(HL)
  POP HL
  LD (HL),A
  POP AF
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,CharGraphics
  ADD HL,DE
  EX DE,HL
  LD B,$08
  PUSH IX
  POP HL
  LD A,(Temp2)
  OR A
  JP Z,NextCellPtr
  CP $01
  JP Z,NextCellPtr
  CP $10
  JP Z,NextCellPtr
  CP $71
  JP Z,NextCellPtr
  CP $81
  JP Z,NextCellPtr
  CP $91
  JP Z,NextCellPtr
  PUSH IY
  LD IY,(RoomColumn)
  LD (IY+$00),L
  LD (IY+$01),H
  LD (IY+$02),E
  LD (IY+$03),D
  LD (IY+$04),$FF
  PUSH HL
  PUSH DE
  LD HL,(RoomCellPtr+$0001)
  LD DE,RoomGrid
  AND A
  SBC HL,DE
  LD DE,CellIndexMap
  ADD HL,DE
  LD A,(RoomCellPtr)
  LD (HL),A
  INC A
  LD (RoomCellPtr),A
  POP DE
  POP HL
  INC IY
  INC IY
  INC IY
  INC IY
  LD (RoomColumn),IY
  POP IY

; The grid pointer one character on
;
; Witness: L1 407192 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
NextCellPtr:
  LD A,(DE)
  LD (HL),A
  INC DE
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ NextCellPtr
  LD HL,(RoomCellPtr+$0001)
  INC HL
  LD (RoomCellPtr+$0001),HL
  POP HL
  RET

; One character's 8 bytes into the back buffer
;
; Witness: L1 50898 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
DrawRoomChar:
  PUSH AF
  PUSH DE
  LD DE,BufferPlayOrigin
  AND A
  SBC HL,DE
  LD A,L
  AND $1F
  LD (Temp1),A
  LD A,L
  AND $E0
  LD L,A
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  LD A,(Temp1)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,AttrShadowPlay
  ADD HL,DE
  POP DE
  POP AF
  RET

; The attribute shadow $E55F to the screen's play rows $5860; the side columns
; white
;
; Witness: L1 136 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x32).
CopyAttrs:
  LD DE,$5860
  LD HL,AttrShadowPlay
  LD BC,$02A0
  LDIR
  LD HL,$5860
  LD B,$15
CopyAttrsSides:
  LD (HL),$47             ; the side columns white
  LD DE,$001F
  ADD HL,DE
  LD (HL),$47
  INC HL
  DJNZ CopyAttrsSides
  RET

; Wait BC x 10 loops
;
; Witness: L1 3097216 (c1, menu-rollcall, p1-cursor, p1-define, p1-kempston,
; p1-speedup, rzx-p1- x6).
Delay:
  PUSH BC
  LD B,$0A
DelayInner:
  DJNZ DelayInner
  POP BC
  DEC BC
  LD A,B
  OR C
  JP NZ,Delay
  RET

; HL = DE x B
;
; Witness: L1 6865 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x31).
Multiply:
  LD HL,$0000
MultiplyLoop:
  ADD HL,DE
  DJNZ MultiplyLoop
  RET

; The room's exits and object list from RoomExits; the list's header: count,
; spawn sides, timers, spawn kind
;
; Witness: L1 80 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
ReadExits:
  LD A,(Room)
  LD E,A
  LD D,$00
  LD B,$06
  CALL Multiply
  LD DE,RoomExits
  ADD HL,DE
  LD A,(HL)
  LD (RoomUp),A
  INC HL
  LD A,(HL)
  LD (RoomRight),A
  INC HL
  LD A,(HL)
  LD (RoomDown),A
  INC HL
  LD A,(HL)
  LD (RoomLeft),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,(DE)
  AND $1F
  LD (ObjectCount),A
  XOR A
  LD (SpawnTop),A
  LD (SpawnRight),A
  LD (SpawnLeft),A
  LD A,(DE)
  BIT 7,A
  CALL NZ,SetSpawnTop
  BIT 6,A
  CALL NZ,SetSpawnRight
  BIT 5,A
  CALL NZ,SetSpawnLeft
  INC DE
  LD A,(DE)
  LD (SpawnTimer),A
  LD (SpawnPeriod),A
  INC DE
  LD A,(DE)
  LD (SpawnKind),A
  INC DE
  LD (ObjectListPtr),DE
  RET

; SpawnTop $A02E = $FF
;
; Witness: L1 44 (c1, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26,
; p1-room30, rzx-p1- x21).
SetSpawnTop:
  LD HL,SpawnTop
  LD (HL),$FF
  RET

; SpawnRight $A02D = $FF
;
; Witness: L1 49 (c1, p1-cursor, p1-kempston, p1-rooms238, p1-speedup,
; p1-room14, p1-room26, p1-room27, p1-room30, rzx-p1- x21).
SetSpawnRight:
  LD HL,SpawnRight
  LD (HL),$FF
  RET

; SpawnLeft $A02C = $FF
;
; Witness: L1 36 (p1-rooms238, p1-speedup, p1-room24, p1-room26, p1-room27,
; p1-room30, rzx-p1- x19).
SetSpawnLeft:
  LD HL,SpawnLeft
  LD (HL),$FF
  RET

; Rex goes through an exit to room A: Room $A0B8 = A, MainLoop; room 99 is the
; end of part 1 (CodePanel $A7CE)
;
; Witness: L1 54 (c1, p1-code, p1-cursor, p1-kempston, p1-rooms238, p1-speedup,
; p1-room x5, rzx-p1- x27).
ChangeRoom:
  LD A,(Room)
  CP $63
  JP Z,CodePanel
  JP MainLoop

; The scripted spawn starts: step 1, timer, count 0
;
; Witness: L1 6 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).
StartScriptSpawn:
  LD A,(ScriptSpawnStep)
  OR A
  RET NZ
  LD A,(HL)
  LD (ScriptSpawnCount),A
  INC HL
  LD (ScriptSpawnTimer),HL
  LD A,$01
  LD (ScriptSpawnStep),A
  RET

; The scripted spawn's step: every few passes the next record of ScriptSpawn
; into a free object
;
; Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
SpawnScripted:
  LD A,(ScriptSpawnStep)
  OR A
  RET Z
  LD A,(ScriptSpawnCount)
  DEC A
  LD (ScriptSpawnCount),A
  OR A
  RET NZ
  LD HL,$5E72
  LD A,(ObjectCount)
  LD B,A
ScriptRecord:
  LD A,(HL)
  OR A
  JP Z,ScriptNext
  LD DE,$0018
  ADD HL,DE
  DJNZ ScriptRecord
  XOR A
  LD (ScriptSpawnStep),A
  RET
ScriptNext:
  LD DE,$000C
  AND A
  SBC HL,DE
  PUSH HL
  POP IX
  LD IY,(ScriptSpawnTimer)
  LD A,(IY+$00)
  CP $FF
  JP Z,ScriptEnd
  CALL MakeObjectIY
  LD A,(IY+$03)
  LD (ScriptSpawnCount),A
  LD DE,$0004
  ADD IY,DE
  LD (ScriptSpawnTimer),IY
  RET
ScriptEnd:
  XOR A
  LD (ScriptSpawnStep),A
  RET

; The random spawn: every SpawnPeriod passes, from a spawn side chosen at
; random
;
; Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
SpawnRandom:
  LD A,(ScriptSpawnStep)
  OR A
  RET NZ
  LD A,(SpawnTimer)
  DEC A
  LD (SpawnTimer),A
  OR A
  RET NZ
  LD A,(SpawnPeriod)
  LD (SpawnTimer),A
  LD HL,$5E72
  LD A,(ObjectCount)
  LD B,A
SpawnFindFree:
  LD A,(HL)
  OR A
  JP Z,SpawnNextRecord
  LD DE,$0018
  ADD HL,DE
  DJNZ SpawnFindFree
  RET
SpawnNextRecord:
  LD DE,$000C
  AND A
  SBC HL,DE
  PUSH HL
  POP IX
  CALL Random
  CP $55
  JP C,SpawnPickLeft
  CP $AA
  JP C,SpawnPickRight
  CALL SpawnFromTop
  RET
SpawnPickRight:
  CALL SpawnFromRight     ; the right side chosen
  RET
SpawnPickLeft:
  CALL SpawnFromLeft      ; the left side chosen
  RET

; A spawn at the left edge, at a free height
;
; Witness: L1 181 (c1, p1-cursor, p1-kempston, p1-poke41241, p1-rooms238,
; p1-speedup, p1-room14, p1-room24, p1-room27, p1-room30, rzx-p1- x31).
SpawnFromLeft:
  LD A,(SpawnLeft)
  OR A
  RET Z
  LD A,(RexX)
  CP $30
  RET C
  LD A,$00
  LD (SpriteX),A
SpawnLeftY:
  CALL Random
  CP $20
  JP C,SpawnLeftY
  CP $A8
  JP NC,SpawnLeftY
  AND $F8
  LD (SpriteY),A
  CALL FindGround
  OR A
  JP Z,SpawnLeftY
  LD A,$0F
  LD (SpriteX),A
  CALL SpawnObject
  LD (IX+$02),$00
  RET

; Make an object of SpawnKind at SpriteX/Y
;
; Witness: L1 253 (c1, p1-gameover, p1-rooms238, p1-shots, p1-speedup, p1-room
; x5, rzx-p1- x30).
SpawnObject:
  LD A,(SpawnKind)
  LD L,A
  BIT 7,A
  JP Z,SpawnObjectSet
  AND $7F
  LD L,A
  CALL Random2
  AND $01
  OR A
  JP Z,SpawnObjectSet
  LD L,$00
SpawnObjectSet:
  LD A,L
  CALL MakeObject
  LD A,(SpriteX)
  LD (IX+$00),A
  LD A,(SpriteY)
  LD (IX+$01),A
  RET

; A spawn at the right edge
;
; Witness: L1 193 (c1, p1-cursor, p1-define, p1-kempston, p1-poke41241,
; p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x28).
SpawnFromRight:
  LD A,(SpawnRight)
  OR A
  RET Z
  LD A,(RexX)
  CP $C8
  RET NC
  LD A,$E0
  LD (SpriteX),A
SpawnRightY:
  CALL Random
  CP $20
  JP C,SpawnRightY
  CP $A8
  JP NC,SpawnRightY
  AND $F8
  LD (SpriteY),A
  CALL FindGround
  OR A
  JP Z,SpawnRightY
  LD A,$E8
  LD (SpriteX),A
  CALL SpawnObject
  LD (IX+$02),$01
  RET

; A spawn at the top, above Rex's column
;
; Witness: L1 196 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-rooms238, p1-shots, p1-speedup, p1-room24, p1-room26, p1-room27,
; p1-room30, rzx-p1- x31).
SpawnFromTop:
  LD A,(SpawnTop)
  OR A
  RET Z
  LD A,(RexY)
  CP $38
  RET C
  LD A,$18
  LD (SpriteY),A
SpawnTopX:
  CALL Random
  CP $20
  JP C,SpawnTopX
  CP $E0
  JP NC,SpawnTopX
  AND $F8
  LD (SpriteX),A
  CALL CellPointer
  LD A,(HL)
  OR A
  JP NZ,SpawnTopX
  INC HL
  LD A,(HL)
  OR A
  JP NZ,SpawnTopX
  INC HL
  LD A,(HL)
  OR A
  JP NZ,SpawnTopX
  LD DE,$001E
  ADD HL,DE
  LD A,(HL)
  OR A
  JP NZ,SpawnTopX
  INC HL
  LD A,(HL)
  OR A
  JP NZ,SpawnTopX
  LD A,(SpriteX)
  ADD A,$10
  LD (SpriteX),A
  XOR A
  LD (SpriteY),A
  CALL SpawnObject
  LD A,R
  AND $FF
  LD (IX+$02),A
  RET

; Find a place with ground under it for a spawn
;
; Witness: L1 2529 (c1, p1-speedup, p1-room x5, rzx-p1- x27).
FindGround:
  CALL CellPointer
  LD DE,$0061
  ADD HL,DE
  LD (Temp1),HL
  LD A,(HL)
  CALL IsPassable
  JP Z,FindGroundNone
  LD DE,$0020
  AND A
  SBC HL,DE
  LD A,(HL)
  CALL IsPassable
  JP NZ,FindGroundNone
  AND A
  SBC HL,DE
  LD A,(HL)
  CALL IsPassable
  JP NZ,FindGroundNone
  LD HL,(Temp1)
  INC HL
  LD A,(HL)
  CALL IsPassable
  JP Z,FindGroundNone
  LD DE,$0020
  AND A
  SBC HL,DE
  LD A,(HL)
  CALL IsPassable
  JP NZ,FindGroundNone
  AND A
  SBC HL,DE
  LD A,(HL)
  CALL IsPassable
  JP NZ,FindGroundNone
  LD A,$FF
  RET
FindGroundNone:
  XOR A
  RET

; Build the room's objects from its list (ObjectListPtr $A020): [kind][X][Y]
; each
;
; Witness: L1 81 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
MakeObjects:
  LD HL,$5E66
  LD DE,$5E67
  LD BC,$017F
  LD (HL),$00
  LDIR
  LD B,$10
  LD IX,$5E66
  LD IY,(ObjectListPtr)
MakeObjectsLoop:
  PUSH BC                 ; each record of the list
  LD A,(IY+$00)
  CP $FF
  JP Z,MakeObjectsNext
  CALL MakeObjectIY
  INC IY
  INC IY
  INC IY
  LD DE,$0018
  ADD IX,DE
  POP BC
  DEC B
  JP NZ,MakeObjectsLoop
  RET
MakeObjectsNext:
  POP BC
  RET

; Make the object of the list record at IY (kind from IY+0)
;
; Witness: L1 385 (c1, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
MakeObjectIY:
  LD A,(IY+$00)

; Make an object of kind A at IX: the common sizes, then the kind's initialiser
;
; Witness: L1 638 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x31).
MakeObject:
  LD (IX+$0E),$03
  LD (IX+$0F),$10
  LD (IX+$10),$02
  LD (IX+$15),$00
  AND $7F
  LD (IX+$09),A
  OR A
  CALL Z,InitKind0
  CP $01
  CALL Z,InitKind1
  CP $03
  CALL Z,InitKind3
  CP $04
  CALL Z,InitKind4
  CP $05
  CALL Z,InitKind5
  CP $08
  CALL Z,InitKind8
  CP $09
  CALL Z,InitKind9
  CP $0A
  CALL Z,InitKind10
  CP $0B
  CALL Z,InitKind11
  CP $0C
  CALL Z,InitKind12
  CP $0D
  CALL Z,InitKind13
  CP $0E
  CALL Z,InitKind14
  CP $0F
  CALL Z,InitKind15
  CP $10
  CALL Z,InitKind16
  CP $11
  CALL Z,InitKind17
  CP $12
  CALL Z,InitKind18
  CP $13
  CALL Z,InitKind19
  CP $14
  CALL Z,InitKind20
  CP $06
  CALL Z,InitKind6
  CP $7D
  CALL Z,InitBonusPod
  LD (IX+$16),E
  LD (IX+$17),D
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD A,(IY+$01)
  LD (IX+$00),A
  LD A,(IY+$02)
  SLA A
  SLA A
  SLA A
  LD (IX+$01),A
  LD A,(IY+$00)
  AND $80
  SRL A
  SRL A
  SRL A
  SRL A
  SRL A
  SRL A
  SRL A
  LD (IX+$02),A
  LD (IX+$03),$00
  LD (IX+$06),$00
  LD (IX+$0C),$01
  LD (IX+$0D),$00
  RET

; Foot man: SpriteFootMan $7F72, ShiftFrames
;
; Witness: L1 212 (c1, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x28).
InitKind0:
  LD HL,ShiftFrames
  LD (IX+$11),$00
  LD (IX+$12),$00
  LD (IX+$14),$02
  LD DE,Sprites
  RET

; List kind 6: the standing gunman, kind $80 (bit 7 kept: +$11 = $C8, which
; JumperTimer never counts), the fixed picture SpriteKind6, hits 2; a front hit
; makes it kind 6
;
; Witness: L1 45 (p1-speedup, p1-room14, p1-room26, p1-room27, p1-room30,
; rzx-p1- x14).
InitKind6:
  LD HL,SpriteKind6
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$11),$C8
  LD (IX+$12),$01
  LD (IX+$10),$00
  LD (IX+$0E),$02
  LD (IX+$09),$80
  LD (IX+$14),$02
  LD HL,ShiftFrames
  LD DE,Sprites
  RET

; Stomper
;
; Witness: L1 43 (p1-rooms238, p1-room24, p1-room30, rzx-p1- x14).
InitKind1:
  LD (IX+$10),$02
  LD (IX+$14),$08
  LD (IX+$15),$01
  LD HL,ShiftFrames
  LD DE,SpriteStomper
  RET

; Kind 3
;
; Witness: L1 27 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).
InitKind3:
  LD (IX+$14),$0F
  LD HL,ShiftFrames
  LD DE,SpriteKind3
  RET

; Kind 4
;
; Witness: L1 6 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).
InitKind4:
  LD (IX+$14),$05
  LD (IX+$15),$01
  LD HL,ShiftFrames
  LD DE,SpriteKind4
  RET

; Kind 5
;
; Witness: L1 6 (c1, p1-rooms238, rzx-p1-04000, rzx-p1-08000, rzx-p1-12000).
InitKind5:
  LD (IX+$14),$0F
  LD (IX+$15),$01
  LD HL,ShiftFrames
  LD DE,SpriteKind5
  RET

; Scanner
;
; Witness: L1 8 (p1-room30, rzx-p1-04000, rzx-p1-18000, rzx-p1-20000,
; rzx-p1-54000).
InitKind8:
  LD (IX+$14),$10
  LD (IX+$15),$01
  LD (IX+$10),$01
  LD (IX+$0E),$02
  LD (IX+$0F),$0B
  LD (IX+$12),$10
  LD (IX+$11),$00
  LD (IX+$06),$00
  LD HL,ShiftFrames5
  LD DE,SpriteScanner2
  RET

; Kind $7D, the bonus pod
;
; Witness: L1 6 (p1-speedup, p1-room30, rzx-p1-52000, rzx-p1-54000,
; rzx-p1-56000, rzx-p1-60000).
InitBonusPod:
  LD HL,SpriteBonusPod
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  SET 7,(IX+$09)
  RET

; Swing gun; also kinds 17-20 (the swing gun at four start angles)
;
; Witness: L1 98 (c1, p1-cursor, p1-kempston, p1-rooms238, p1-speedup,
; p1-room26, p1-room27, p1-room30, rzx-p1- x19).
InitKind9:
  LD HL,SpriteSwingGun
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$14),$0A
  LD (IX+$11),$00
  LD (IX+$15),$01
  LD (IX+$12),$00
  SET 7,(IX+$09)
  RET

; Kind 17: a swing gun at angle 1
;
; Witness: L1 21 (p1-rooms238, p1-speedup, p1-room26, p1-room27, p1-room30,
; rzx-p1- x13).
InitKind17:
  LD (IX+$09),$09
  CALL InitKind9
  LD (IX+$11),$00
  LD (IX+$12),$01
  RET

; Kind 18: angle 2
;
; Witness: L1 23 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, p1-room30,
; rzx-p1- x11).
InitKind18:
  LD (IX+$09),$09
  CALL InitKind9
  LD (IX+$11),$01
  LD (IX+$12),$01
  RET

; Kind 19: angle 3
;
; Witness: L1 13 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, p1-room30,
; rzx-p1-00000, rzx-p1-02000, rzx-p1-12000, rzx-p1-58000).
InitKind19:
  LD (IX+$09),$09
  CALL InitKind9
  LD (IX+$11),$04
  LD (IX+$12),$01
  RET

; Kind 20: angle 4
;
; Witness: L1 16 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, rzx-p1-
; x6).
InitKind20:
  LD (IX+$09),$09
  CALL InitKind9
  LD (IX+$11),$03
  LD (IX+$12),$01
  RET

; Shooters
;
; Witness: L1 54 (c1, p1-rooms238, p1-speedup, p1-room14, p1-room24, p1-room26,
; p1-room30, rzx-p1- x15).
InitKind10:
  LD HL,SpriteKind10
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$14),$0A
  LD (IX+$15),$01
  LD (IX+$11),$14
  LD (IX+$12),$11
  SET 7,(IX+$09)
  RET

; Launcher
;
; Witness: L1 41 (c1, p1-cursor, p1-define, p1-kempston, p1-speedup, p1-room14,
; p1-room24, p1-room26, p1-room30, rzx-p1- x14).
InitKind11:
  LD HL,SpriteKind11
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$14),$08
  LD (IX+$11),$00
  LD (IX+$15),$01
  LD (IX+$11),$0A
  LD (IX+$12),$06
  SET 7,(IX+$09)
  RET

; Ramming pod; also the human's body
;
; Witness: L1 30 (p1-gameover, p1-shots, p1-speedup, rzx-p1- x13).
InitKind12:
  LD (IX+$14),$02
  LD (IX+$06),$00
  LD (IX+$11),$00
  LD (IX+$12),$00
  LD HL,ShiftFrames
  LD DE,SpriteKind12
  RET

; Mine layer
;
; Witness: L1 12 (p1-room30, rzx-p1- x7).
InitKind13:
  LD (IX+$14),$0F
  LD (IX+$06),$00
  LD (IX+$0F),$0C
  LD (IX+$11),$01
  LD (IX+$12),$01
  LD (IX+$15),$01
  LD HL,ShiftFrames3
  LD DE,SpriteKind13
  RET

; Mine
;
; Witness: L1 164 (p1-code, p1-speedup, p1-room30, rzx-p1- x10).
InitKind14:
  LD (IX+$14),$02
  LD (IX+$06),$00
  LD (IX+$0E),$02
  LD (IX+$0F),$08
  LD (IX+$10),$01
  LD (IX+$04),$00
  LD (IX+$05),$00
  LD (IX+$11),$10
  LD (IX+$12),$00
  LD (IX+$15),$FF
  LD HL,ShiftFrames4
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD DE,SpriteKind14
  LD (IX+$16),E
  LD (IX+$17),D
  RET

; Blob
;
; Witness: L1 49 (p1-rooms238, p1-room14, p1-room24, p1-room26, rzx-p1- x6).
InitKind15:
  LD (IX+$14),$04
  LD (IX+$06),$00
  LD (IX+$0E),$02
  LD (IX+$0F),$08
  LD (IX+$10),$01
  LD (IX+$04),$00
  LD (IX+$05),$00
  LD (IX+$11),$02
  LD (IX+$15),$FF
  LD HL,ShiftFrames4
  LD DE,SpriteKind15
  RET

; The big gun: kind $90 (bit 7 set), speed IX+$12 = 2, 6 x 48, hits Weapon x 50
; + 16
;
; Witness: L1 1 (rzx-p1-22000).
InitKind16:
  LD HL,SpriteKind16
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$06
  LD (IX+$0F),$30
  CALL KillHumanPicture
  LD (IX+$15),$FF
  LD (IX+$11),$00
  LD (IX+$13),$00
  SET 7,(IX+$09)
  LD (IX+$12),$02
  RET

; The big gun's hits by the weapon held (Weapon x 50 + 16) into IX+$14 and
; HumanPicture $A022 (written, never read)
;
; Witness: L1 2 (rzx-p1-22000, rzx-p1-24000).
KillHumanPicture:
  LD A,(Weapon)
  LD B,A
  LD DE,$0032
  CALL Multiply
  LD A,L
  ADD A,$10
  LD (IX+$14),A
  LD (HumanPicture),A
  RET
