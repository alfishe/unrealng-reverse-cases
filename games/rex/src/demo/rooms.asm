; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The rooms: drawing a room, the exits, the objects made, the spawners
; --------------------------------------------------------------------------------------------------------------------

; Draw the room: silence, the map's 7 x 10 blocks into the buffer, the grid and
; the attribute shadow; the animated cells listed
;
; As REX 1's DrawRoom $C745 (src/game/rooms.asm).
;
; Witness: L1 12 (d1, demo-cycle).
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
  LD HL,AnimCellList
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
; Witness: L1 840 (d1, demo-cycle).
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
; As REX 1's DrawRoomCell $C7E2 (src/game/rooms.asm).
;
; Witness: L1 7560 (d1, demo-cycle).
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
  LD (RoomCellPtr+1),HL
  LD A,(Temp2)
  LD E,A
  LD D,$00
  LD HL,CharFlags
  ADD HL,DE
  LD A,(HL)
  POP HL
  LD (HL),A
  POP AF
FontChar:
  LD L,A                  ; DE = the font's character A ($5FE0 + 8A)
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
  JP Z,l_CE4C
  CP $10
  JP Z,l_CE4C
  CP $71
  JP Z,l_CE4C
  CP $81
  JP Z,l_CE4C
  CP $91
  JP Z,l_CE4C
  CP $A4
  JP Z,l_CE4C
  PUSH IY
  LD IY,(RoomColumn)
  LD (IY+$00),L
  LD (IY+$01),H
  LD (IY+$02),E
  LD (IY+$03),D
  LD (IY+$04),$FF
  PUSH HL
  PUSH DE
  LD HL,(RoomCellPtr+1)
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
l_CE4C:
  LD A,(DE)
  LD (HL),A
  INC DE
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ l_CE4C
  LD HL,(RoomCellPtr+1)
  INC HL
  LD (RoomCellPtr+1),HL
  POP HL
  RET

; One character's 8 bytes into the back buffer
;
; As REX 1's DrawRoomChar $C893 (src/game/rooms.asm).
;
; Witness: L1 7560 (d1, demo-cycle).
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
; Witness: L1 60 (d1, demo-cycle).
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
; Witness: L1 1970000 (d1, demo-cycle).
Delay:
  PUSH BC
  LD B,$1C
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
; Witness: L1 864 (d1, demo-cycle).
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
; Witness: L1 12 (d1, demo-cycle).
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
  LD (ObjectListPtr),DE
  RET

; SpawnTop $5EB7 = 1
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

; SpawnRight $5EB6 = 1
;
; As REX 1's SetSpawnRight $C94E (src/game/rooms.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
SetSpawnRight:
  LD HL,SpawnRight
  LD (HL),$FF
  RET

; SpawnLeft $5EB5 = 1
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

; JP MainLoop: a new room (ExitRight, ExitTop)
;
; Witness: L1 4 (d1, demo-cycle).
ToMainLoop:
  JP MainLoop

; The scripted spawn starts: step 1, timer, count 0
;
; As REX 1's StartScriptSpawn $C965 (src/game/rooms.asm).
;
; Witness: L1 3 (demo-cycle).
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
; Witness: L1 6752 (d1, demo-cycle).
SpawnScripted:
  LD A,(ScriptSpawnStep)
  OR A
  RET Z
  LD A,(ScriptSpawnCount)
  DEC A
  LD (ScriptSpawnCount),A
  OR A
  RET NZ
  LD HL,$5F02
  LD A,(ObjectCount)
  LD B,A
ScriptRecord:
  LD A,(HL)
  OR A
  JP Z,ScriptNext
  LD DE,$0017
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

; The random spawn's timer: every SpawnPeriod passes a random number and
; nothing more (the spawn is cut: SpawnLeftover)
;
; Changed from REX 1's SpawnRandom $C9CA (src/game/rooms.asm).
;
; Witness: L1 6752 (d1, demo-cycle).
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
  CALL Random2
  RET

; Leftover: LD HL,$5F02 after SpawnRandom (part 1 went on to make the object);
; nothing reaches it
;
; Witness: L1 0 ().
SpawnLeftover:
  LD HL,$5F02

; Build the room's objects from its list (ObjectListPtr $5EA9): [kind][X][Y]
; each
;
; As REX 1's MakeObjects $CB52 (src/game/rooms.asm).
;
; Witness: L1 12 (d1, demo-cycle).
MakeObjects:
  LD HL,ObjectTable
  LD DE,$5EF7
  LD BC,$016F
  LD (HL),$00
  LDIR
  LD B,$10
  LD IX,ObjectTable
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
  LD DE,$0017
  ADD IX,DE
  POP BC
  DEC B
  JP NZ,MakeObjectsLoop
  RET
MakeObjectsNext:
  POP BC
  RET

; Make the object of the list record at IY: the kind from IY+0; the common
; sizes; the kind's initialiser (0, 1, 2, 8, 9, 10, 11, 12, 6, $7C, $7D); its
; place from IY+1, IY+2, its direction from bit 7
;
; Changed from REX 1's MakeObjectIY $CB88 (src/game/rooms.asm).
;
; Witness: L1 67 (d1, demo-cycle).
MakeObjectIY:
  LD A,(IY+$00)
MakeObject:
  LD (IX+$0E),$03         ; Make an object of kind A at IX: the common sizes,
                          ; then the kind's initialiser
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
  CP $06
  CALL Z,InitKind6
  CP $7C
  CALL Z,InitKind7C
  CP $7D
  CALL Z,InitKind7D
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

; Kind 0, the foot man: frames ShiftFrames, 2 hits
;
; Changed from REX 1's InitKind0 $CC48 (src/game/rooms.asm).
;
; Witness: L1 14 (demo-cycle).
InitKind0:
  LD HL,ShiftFrames
  LD (IX+$11),$00
  LD (IX+$12),$00
  LD (IX+$14),$02
  LD (IX+$15),$FF
  RET

; Kind 6: SpriteKind6, 2 hits, the turn timer 200
;
; Changed from REX 1's InitKind6 $CC5B (src/game/rooms.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
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
  RET

; Kind 1, the stomper: speed 2, 8 hits, frames $AF2E
;
; Changed from REX 1's InitKind1 $CC83 (src/game/rooms.asm).
;
; Witness: L1 16 (d1, demo-cycle).
InitKind1:
  LD (IX+$10),$02
  LD (IX+$14),$08
  LD (IX+$15),$01
  LD HL,FramesKind1
  RET

; Kind 2: speed 0, no hits, frames $AF2E (it turns to face Rex: ObjectMove)
;
; Changed from REX 1's InitKind3 $CC96 (src/game/rooms.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
InitKind2:
  LD (IX+$10),$00
  LD (IX+$14),$00
  LD HL,FramesKind1
  RET

; Scanner: 7 hits, frames $AF4E
;
; Witness: L1 1 (demo-cycle).
InitKind8:
  LD (IX+$14),$07
  LD (IX+$15),$01
  LD (IX+$10),$01
  LD (IX+$0E),$02
  LD (IX+$0F),$0B
  LD (IX+$12),$10
  LD (IX+$11),$00
  LD (IX+$06),$00
  LD HL,FramesKind8
  RET

; Kind $7C: the bonus pod SpriteBonusPod
;
; Witness: L1 2 (demo-cycle).
InitKind7C:
  LD HL,SpriteBonusPod
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  SET 7,(IX+$09)
  RET

; Kind $7D: the bomb pod SpriteBombPod
;
; Witness: L1 3 (d1, demo-cycle).
InitKind7D:
  LD HL,SpriteBombPod
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  SET 7,(IX+$09)
  RET

; Kind 9, the swing gun: SpriteSwingGun, 12 hits
;
; Changed from REX 1's InitBonusPod $CCE6 (src/game/rooms.asm).
;
; Witness: L1 5 (d1, demo-cycle).
InitKind9:
  LD HL,SpriteSwingGun
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$14),$0C
  LD (IX+$11),$00
  LD (IX+$15),$01
  SET 7,(IX+$09)
  RET

; Kind 10, the shooters: SpriteKind10, 10 hits, the shot timer 20 / 12
;
; Changed from REX 1's InitKind9 $CCF8 (src/game/rooms.asm).
;
; Witness: L1 8 (d1, demo-cycle).
InitKind10:
  LD HL,SpriteKind10
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$14),$0A
  LD (IX+$15),$01
  LD (IX+$11),$14
  LD (IX+$12),$0C
  SET 7,(IX+$09)
  RET

; Kind 11, the launcher: SpriteKind11, 8 hits, the shot timer 10 / 6
;
; Changed from REX 1's InitKind11 $CD7C (src/game/rooms.asm).
;
; Witness: L1 6 (d1, demo-cycle).
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

; Kind 12, the ground walker: 3 hits, frames $AF3E
;
; Changed from REX 1's InitKind12 $CDA2 (src/game/rooms.asm).
;
; Witness: L1 12 (demo-cycle).
InitKind12:
  LD (IX+$14),$03
  LD (IX+$06),$00
  LD (IX+$11),$01
  LD (IX+$12),$01
  LD HL,FramesKind12
  RET
