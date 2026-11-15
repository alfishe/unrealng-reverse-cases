; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The rooms: drawing a room, the exits, the objects made, the spawners
; --------------------------------------------------------------------------------------------------------------------

; Draw the room: silence, the map's 7 x 10 blocks into the grid, the attribute
; shadow and SceneryCellList (its pixel writes into the buffer are wiped by
; BuildRoom's ClearBuffer after it; the cell list redraws them)
;
; As REX 1's DrawRoom $C745 (src/game/rooms.asm).
;
; Witness: L1 32 (c2, p2-room20, rzx-p2- x17).
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
  LD IX,BufferPlayOrigin+$0001
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
; As REX 1's DrawBlockRow $C7C5 (src/game/rooms.asm).
;
; Witness: L1 2240 (c2, p2-room20, rzx-p2- x17).
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

; One character A at IX into the buffer: its attribute (CharAttrs) in the
; shadow, its type (CharFlags) in the grid, its 8 bytes; all but characters 0,
; 1, $10, $81, $95, $96, $C6, $D6 listed at $A252 with their number in
; CellIndexMap $DE9F
;
; Changed from REX 1's DrawRoomCell $C7E2 (src/game/rooms.asm).
;
; Witness: L1 20160 (c2, p2-room20, rzx-p2- x17).
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
CellPicture:
  LD L,A                  ; DE = the character's picture, CharGraphics + 8 x A
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
  JP Z,CellCopy
  CP $01
  JP Z,CellCopy
  CP $95
  JP Z,CellCopy
  CP $96
  JP Z,CellCopy
  CP $C6
  JP Z,CellCopy
  CP $D6
  JP Z,CellCopy
  CP $10
  JP Z,CellCopy
  CP $81
  JP Z,CellCopy
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
CellCopy:
  LD A,(DE)               ; the 8 bytes into the buffer
  LD (HL),A
  INC DE
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ CellCopy
  LD HL,(RoomCellPtr+$0001)
  INC HL
  LD (RoomCellPtr+$0001),HL
  POP HL
  RET

; One character's 8 bytes into the back buffer
;
; As REX 1's DrawRoomChar $C893 (src/game/rooms.asm).
;
; Witness: L1 20160 (c2, p2-room20, rzx-p2- x17).
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
; As REX 1's CopyAttrs $C8BF (src/game/rooms.asm).
;
; Witness: L1 65 (c2, p2-room20, rzx-p2- x19).
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
; As REX 1's Delay $C8DB (src/game/rooms.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
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
; As REX 1's Multiply $C8E8 (src/game/rooms.asm).
;
; Witness: L1 3403 (c2, p2-room20, rzx-p2- x18).
Multiply:
  LD HL,$0000
MultiplyLoop:
  ADD HL,DE
  DJNZ MultiplyLoop
  RET

; The room's exits and object list from RoomExits; the list's header: count,
; spawn sides, timers, spawn kind
;
; As REX 1's ReadExits $C8EF (src/game/rooms.asm).
;
; Witness: L1 32 (c2, p2-room20, rzx-p2- x17).
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

; SpawnTop $A1C7 = $FF
;
; As REX 1's SetSpawnTop $C948 (src/game/rooms.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
SetSpawnTop:
  LD HL,SpawnTop
  LD (HL),$FF
  RET

; SpawnRight $A1C6 = $FF
;
; As REX 1's SetSpawnRight $C94E (src/game/rooms.asm).
;
; Witness: L1 8 (c2, rzx-p2-00000, rzx-p2-06000, rzx-p2-08000).
SetSpawnRight:
  LD HL,SpawnRight
  LD (HL),$FF
  RET

; SpawnLeft $A1C5 = $FF
;
; As REX 1's SetSpawnLeft $C954 (src/game/rooms.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
SetSpawnLeft:
  LD HL,SpawnLeft
  LD (HL),$FF
  RET

; JP MainLoop: the exits' way into the new room (part 2 has no end room)
;
; Witness: L1 13 (p2-room20, rzx-p2- x11).
ChangeRoom:
  JP MainLoop

; The scripted spawn starts: step 1, timer, count 0 (as REX 1; nothing calls it
; in part 2)
;
; Witness: L1 0 ().
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
; As REX 1's SpawnScripted $C978 (src/game/rooms.asm).
;
; Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).
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
  LD DE,$001B
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

; The random spawn: every SpawnPeriod passes, into the first free object record
; (SpawnAnywhere)
;
; Changed from REX 1's SpawnRandom $C9CA (src/game/rooms.asm).
;
; Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).
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
  LD DE,$001B
  ADD HL,DE
  DJNZ SpawnFindFree
  RET
SpawnNextRecord:
  LD DE,$000C
  AND A
  SBC HL,DE
  PUSH HL
  POP IX
  CALL SpawnAnywhere
  RET

; A spawn at a random place (X 24-$DF, Y 32-$A7) away from Rex with ground
; under it: SpawnKind (bit 7: half the time kind 0), random facing, it fades
; in; a kind 0 becomes a jumper
;
; Witness: L1 6278 (c2, p2-room20, rzx-p2- x20).
SpawnAnywhere:
  CALL Random2
  CP $18
  JP C,SpawnAnywhere
  CP $E0
  JP NC,SpawnAnywhere
  AND $F8
  LD (SpriteX),A
SpawnY:
  CALL Random2            ; a random Y
  CP $20
  JP C,SpawnY
  CP $A8
  JP NC,SpawnY
  AND $F8
  LD (SpriteY),A
  LD A,(RexX)
  SUB $10
  LD HL,SpriteX
  CP (HL)
  JP NC,SpawnPlace
  ADD A,$30
  CP (HL)
  JP C,SpawnPlace
  LD A,(RexY)
  SUB $10
  LD HL,SpriteY
  CP (HL)
  JP NC,SpawnPlace
  ADD A,$30
  CP (HL)
  JP C,SpawnPlace
  RET
SpawnPlace:
  CALL FindGround         ; far from Rex: a place with ground
  OR A
  RET Z
SpawnObject:
  LD A,(SpawnKind)        ; Make an object of SpawnKind at SpriteX/Y
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
  CALL Random
  AND $01
  LD (IX+$02),A
  CALL ObjectFadeIn
  LD A,(IX+$09)
  OR A
  RET NZ
  CALL MakeJumper
  LD (IX+$11),$18
  RET

; Find a place with ground under it for a spawn
;
; As REX 1's FindGround $CB03 (src/game/rooms.asm).
;
; Witness: L1 4632 (c2, p2-room20, rzx-p2- x20).
FindGround:
  CALL CellPointer
  LD DE,$0060
  ADD HL,DE
  LD (Temp1),HL
  LD A,(HL)
  CALL IsPassable
  JP Z,FindGroundNone
  LD DE,$0020
  AND A
  SBC HL,DE
  LD A,(HL)
  OR A
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
  OR A
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

; Build the room's objects from its list (ObjectListPtr $A1B9): [kind][X][Y]
; each
;
; As REX 1's MakeObjects $CB52 (src/game/rooms.asm).
;
; Witness: L1 32 (c2, p2-room20, rzx-p2- x17).
MakeObjects:
  LD HL,$5E66
  LD DE,$5E67
  LD BC,$0179
  LD (HL),$00
  LDIR
  LD B,$0E
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
  LD DE,$001B
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
; As REX 1's MakeObjectIY $CB88 (src/game/rooms.asm).
;
; Witness: L1 164 (c2, p2-room20, rzx-p2- x17).
MakeObjectIY:
  LD A,(IY+$00)

; Make an object of kind A at IX: the common sizes, the kind's initialiser (0,
; 1, 2, 3, 4, 5, 6, 9, 14 and the bonus pod $7C), its place from the list entry
; at IY
;
; Changed from REX 1's MakeObject $CB8B (src/game/rooms.asm).
;
; Witness: L1 300 (c2, p2-room20, rzx-p2- x20).
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
  CP $02
  CALL Z,InitKind2
  CP $03
  CALL Z,InitKind3
  CP $04
  CALL Z,InitKind4
  CP $05
  CALL Z,InitKind5
  CP $09
  CALL Z,InitKind9
  CP $06
  CALL Z,InitKind6
  CP $0E
  CALL Z,InitKind14
  CP $7C
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

; Foot man: SpriteFootMan $8198, ShiftFrames
;
; As REX 1's InitKind0 $CC48 (src/game/rooms.asm).
;
; Witness: L1 59 (c2, rzx-p2- x15).
InitKind0:
  LD HL,ShiftFrames
  LD (IX+$11),$00
  LD (IX+$12),$00
  LD (IX+$14),$02
  LD DE,Sprites
  RET

; Kind 6
;
; As REX 1's InitKind6 $CC5B (src/game/rooms.asm).
;
; Witness: L1 14 (c2, p2-room20, rzx-p2- x6).
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

; Kind 1: picture $8F00, ShiftFrames
;
; Witness: L1 11 (p2-room20, rzx-p2- x6).
InitKind1:
  LD (IX+$10),$02
  LD (IX+$14),$0A
  LD (IX+$15),$01
  LD HL,ShiftFrames
  LD DE,SpriteKind1
  RET

; Kind 3: picture $8BE0, frame timer 5
;
; Witness: L1 10 (rzx-p2- x6).
InitKind3:
  LD (IX+$14),$02
  LD (IX+$15),$01
  LD (IX+$0E),$02
  LD (IX+$11),$00
  LD HL,SpriteKind3
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$12),$05
  SET 7,(IX+$09)
  RET

; Kind 2: picture $8D20, a random wait 100-227, kind $82
;
; Witness: L1 45 (c2, p2-room20, rzx-p2- x11).
InitKind2:
  LD (IX+$14),$02
  LD (IX+$15),$01
  LD (IX+$0E),$02
  LD HL,SpriteKind2
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$11),$00
  CALL Random2
  AND $7F
  ADD A,$64
  LD (IX+$12),A
  LD (IX+$09),$82
  RET

; Kind 4: picture $8FC0
;
; Witness: L1 56 (c2, p2-room20, rzx-p2- x12).
InitKind4:
  LD (IX+$14),$08
  LD (IX+$15),$01
  LD (IX+$0E),$02
  LD HL,SpriteKind4
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$11),$00
  LD (IX+$12),$00
  SET 7,(IX+$09)
  RET

; Kind $7D, the bonus pod
;
; As REX 1's InitBonusPod $CCE6 (src/game/rooms.asm).
;
; Witness: L1 1 (rzx-p2-30000).
InitBonusPod:
  LD HL,SpriteBonusPod2
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  SET 7,(IX+$09)
  RET

; Kind 9, the fan gun: picture $9040, five shots
;
; Changed from REX 1's InitKind9 $CCF8 (src/game/rooms.asm).
;
; Witness: L1 9 (c2, rzx-p2- x5).
InitKind9:
  LD HL,SpriteKind9
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$14),$0E
  LD (IX+$11),$00
  LD (IX+$15),$01
  LD (IX+$12),$05
  SET 7,(IX+$09)
  RET

; Kind 5: picture $8E20, frame timer 5
;
; Witness: L1 19 (c2, rzx-p2- x10).
InitKind5:
  LD HL,SpriteKind5
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$14),$0C
  LD (IX+$11),$00
  LD (IX+$15),$01
  LD (IX+$12),$05
  SET 7,(IX+$09)
  RET

; Kind 14, the mine: picture $9100, frames $AF6A
;
; Changed from REX 1's InitKind14 $CDD8 (src/game/rooms.asm).
;
; Witness: L1 77 (c2, p2-room20, rzx-p2- x11).
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
  LD DE,SpriteKind14
  RET
