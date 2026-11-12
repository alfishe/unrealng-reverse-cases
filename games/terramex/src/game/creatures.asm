; --------------------------------------------------------------------------------------------------------------------
; creatures.asm: The creatures of each room and their behaviours
; --------------------------------------------------------------------------------------------------------------------

; The room's three creatures as DecodeRoomCreatures unpacks them: 3 records of
; 10 bytes
;
; Written by DecodeRoomCreatures $BE42 from RoomCreatures $C152 on every room
; entry; run by RunCreatures $BE98 (IY = the record). +0 the type (the handler,
; CreatureHandlers $BECA), +1 the type again (the fliers put it back from here
; when they leave the room), +2 the hit flag (bit 7), +3 the hit frame (0-7),
; +4 the first sprite frame, +5 the start X, +6 the start Y, +7 the animation
; counter with the direction in bit 7, +8 the timer (bit 0 set once placed:
; PlaceCreature $C135), +9 unused. Split from the place values here (the cut
; had one block $BE18-$BE41).
;
; Witness: read and written by every play build.
CreatureRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
CreatureRecord2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
CreatureRecord3:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Unpack the room's three creature records of RoomCreatures into
; CreatureRecords
;
; A = the room (kept). CreatureRecords $BE24 cleared (30 bytes), then for each
; 4-byte record at $C152 + 12 x A: +0 and +1 = byte0 & $0F, +2 = byte0 & $80,
; +3 = byte0 >> 4 & 7, +4 = byte1, +5 = byte2, +6 = byte3 & $7F, +7 = byte3 &
; $80. Called by $9855 (the room set-up) on every room entry.
;
; Witness: L1 105 (c1, explorers, gameover, rzx x28).
DecodeRoomCreatures:
  PUSH AF
  LD HL,CreatureRecords
  LD DE,CreatureRecords+$0001
  LD BC,$001D
  LD (HL),$00
  LDIR
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  POP DE
  ADD HL,DE
  LD DE,RoomCreatures
  ADD HL,DE
  LD DE,CreatureRecords
  LD B,$03
DecodeCreatureLoop:
  PUSH DE
  LD A,(HL)
  PUSH AF
  AND $0F
  LD (DE),A
  INC DE
  LD (DE),A
  INC DE
  POP AF
  AND $80
  LD (DE),A
  INC DE
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $07
  LD (DE),A
  INC DE
  INC HL
  LD A,(HL)
  LD (DE),A
  INC DE
  INC HL
  LD A,(HL)
  LD (DE),A
  INC DE
  INC HL
  LD A,(HL)
  AND $7F
  LD (DE),A
  INC DE
  LD A,(HL)
  AND $80
  LD (DE),A
  INC HL
  POP DE
  PUSH HL
  LD HL,$000A
  ADD HL,DE
  EX DE,HL
  POP HL
  DJNZ DecodeCreatureLoop
  POP AF
  RET

; Run the room's three creatures: the handler of each record's type
;
; IX = the slots $5B08, $5B0C, $5B10 in turn, IY = CreatureRecords $BE24 + 10k;
; the handler is word +0 of CreatureHandlers $BECA, called through JumpHL
; $BEC9. Called by the main loop every pass ($903D); IX kept.
;
; Witness: L1 26514 (c1, explorers, gameover, rzx x31).
RunCreatures:
  LD B,$03
  LD DE,CreatureRecords
  PUSH IX
  LD IX,ObjectSlot1
RunCreaturesLoop:
  PUSH BC
  PUSH DE
  LD A,(DE)
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,CreatureHandlers
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  PUSH DE
  POP IY
  CALL JumpHL
  LD DE,$0004
  ADD IX,DE
  POP DE
  LD HL,$000A
  ADD HL,DE
  EX DE,HL
  POP BC
  DJNZ RunCreaturesLoop
  POP IX
  RET

; JP (HL): the call into a creature handler
;
; Witness: L1 79544 (c1, explorers, gameover, rzx x31).
JumpHL:
  JP (HL)

; The handler of each creature type 0-8
;
; Type 0 NoCreature, 1 WalkerCreature, 2 ClimberCreature, 3 LeftFlier, 4
; RightFlier, 5 DropCreature, 6 StillCreature, 7 RiserCreature, 8 PlaceCreature
; (scenery: put in place every pass). Witness: every play build reads the words
; of the types its rooms hold.
CreatureHandlers:
  DEFW NoCreature
  DEFW WalkerCreature
  DEFW ClimberCreature
  DEFW LeftFlier
  DEFW RightFlier
  DEFW DropCreature
  DEFW StillCreature
  DEFW RiserCreature
  DEFW PlaceCreature

; Type 0: an empty record, RET
;
; Witness: L1 41598 (c1, explorers, gameover, rzx x31).
NoCreature:
  RET

; Type 1: walk 2 pixels a pass along X, turn at walls and the room edges
;
; Placed at the first call (PlaceCreature $C135). Direction bit 7 of +7 set: X
; + 2 up to $E6, the tiles right of it tested (TestRight $C109); clear: X - 2
; down to 0, the ground under it tested (TestBelow $C0FD). A test flag not 0,
; or the edge, turns it (+7 bit 7 flipped). Then AnimateCreature $C0AC.
;
; Witness: L1 2454 (rzx x11).
WalkerCreature:
  BIT 0,(IY+$08)
  JR NZ,WalkerMove
  CALL PlaceCreature
WalkerMove:
  BIT 7,(IY+$07)
  LD A,(IX+$00)
  JR NZ,WalkerRight
  SUB $02
  JR C,WalkerTurn
  LD (IX+$00),A
  CALL TestBelow
  LD A,(TileScanFlags)
  OR A
  JR NZ,WalkerTurn
  JP AnimateCreature
WalkerRight:
  ADD A,$02
  CP $E7
  JR C,WalkerRightTest
WalkerTurn:
  LD A,(IY+$07)
  XOR $80
  LD (IY+$07),A
  JP AnimateCreature
WalkerRightTest:
  LD (IX+$00),A
  CALL TestRight
  LD A,(TileScanFlags+$0001)
  OR A
  JR NZ,WalkerTurn
  JP AnimateCreature

; Type 2: move 2 pixels a pass along Y, turn at the floor, the ceiling and the
; room's top and bottom
;
; As WalkerCreature $BEDD along Y: bit 7 set: Y + 2 up to $66, tested by
; TestBelowRight $C121; clear: Y - 2 down to 0, tested by TestAhead $C115. Then
; AnimateCreature $C0AC.
;
; Witness: L1 266 (rzx x3).
ClimberCreature:
  BIT 0,(IY+$08)
  JR NZ,ClimberMove
  CALL PlaceCreature
ClimberMove:
  BIT 7,(IY+$07)
  LD A,(IX+$01)
  JR NZ,ClimberDown
  SUB $02
  JR C,ClimberTurn
  LD (IX+$01),A
  CALL TestAhead
  LD A,(TileScanSecond)
  OR A
  JR NZ,ClimberTurn
  JP AnimateCreature
ClimberDown:
  ADD A,$02
  CP $67
  JR C,ClimberDownTest
ClimberTurn:
  LD A,(IY+$07)
  XOR $80
  LD (IY+$07),A
  JP AnimateCreature
ClimberDownTest:
  LD (IX+$01),A
  CALL TestBelowRight
  LD A,(TileScanSecond+$0001)
  OR A
  JR NZ,ClimberTurn
  JP AnimateCreature

; Type 3: wait a random time unseen, then fly left 2 pixels a pass across the
; room
;
; CreatureTimer $BFA0 (C = 1); while it runs the frame is $7F (unseen). Then X
; - 2 a pass (direction bit cleared); X below 0: unseen again, the timer 0 (a
; new random wait, the place again) and the type restored from +1. A TestBelow
; $C0FD flag not 0 adds 1 to the record's type (+0): it becomes a RightFlier
; until it leaves the room (not executed in any recording). Then
; AnimateCreature $C0AC.
;
; Witness: L1 5796 (c1, explorers, rzx x2).
LeftFlier:
  LD C,$01
  CALL CreatureTimer
  LD (IX+$02),$7F
  RET NZ
  RES 7,(IY+$07)
  LD A,(IX+$00)
  SUB $02
  JR NC,LeftFlierStep
  LD (IX+$02),$7F
  XOR A
  LD (IY+$08),A
  LD A,(IY+$01)
  LD (IY+$00),A
  RET
LeftFlierStep:
  LD (IX+$00),A
  CALL TestBelow
  LD A,(TileScanFlags)
  OR A
  JR NZ,LeftFlierBlocked
  JP AnimateCreature
LeftFlierBlocked:
  INC (IY+$00)            ; type + 1: now a right flier
  JP AnimateCreature

; Count down the creature's timer +8; a new random wait when it is 0
;
; IY = the record, C = bits that are ORed into a new wait. Timer 0:
; PlaceCreature $C135, then a random 0-$7F ($9390) OR C as the new wait. Then
; the timer - 1: out Z set (and the timer left at 1) when it has run out, else
; the new value stored, Z clear. So after the wait the creature acts every pass
; until its handler clears the timer.
;
; Witness: L1 31152 (c1, explorers, gameover, rzx x23).
CreatureTimer:
  LD A,(IY+$08)
  OR A
  JR NZ,CreatureTimerDown
  CALL PlaceCreature
  CALL Random
  AND $7F
  OR C
  LD (IY+$08),A
CreatureTimerDown:
  LD A,(IY+$08)
  DEC A
  RET Z
  LD (IY+$08),A
  RET

; Type 4: wait a random time unseen, then fly right 2 pixels a pass across the
; room
;
; As LeftFlier $BF67, rightwards: X + 2 to $E6, the direction bit set, tested
; by TestRight $C109 (a flag not 0 subtracts 1 from the type: it becomes a
; LeftFlier; not executed in any recording).
;
; Witness: L1 989 (rzx x4).
RightFlier:
  LD C,$01
  CALL CreatureTimer
  LD (IX+$02),$7F
  RET NZ
  SET 7,(IY+$07)
  LD A,(IX+$00)
  ADD A,$02
  CP $E7
  JR C,RightFlierStep
  LD (IX+$02),$7F
  XOR A
  LD (IY+$08),A
  LD A,(IY+$01)
  LD (IY+$00),A
  RET
RightFlierStep:
  LD (IX+$00),A
  CALL TestRight
  LD A,(TileScanFlags+$0001)
  OR A
  JR NZ,RightFlierBlocked
  JP AnimateCreature
RightFlierBlocked:
  DEC (IY+$00)            ; type - 1: now a left flier
  JP AnimateCreature

; Type 5: a drop that waits, falls 2 pixels a pass, splashes and starts again
;
; CreatureTimer $BFA0 (C = 1): the drop is unseen (frame $7F) while it waits,
; at its start place. Then DropFall $C000.
;
; Witness: L1 12834 (rzx x20).
DropCreature:
  LD C,$01
  CALL CreatureTimer
  LD (IX+$02),$7F
  RET NZ

; The drop's fall: Y + 2 until the ground or Y $66, then the splash
;
; The second half of DropCreature $BFF6, an entry of the cut because $C000 is
; also the address the IM 2 handler calls with RAM 6 paged in (the music
; player, $94A0); here, in RAM 0, it is only the drop. Y + 2 a pass; at Y $67
; the drop is gone (frame $7F, the timer 0: a new wait). Falling, +7 counts the
; passes and the frame is +4, then +4 + 1 from the third pass on ((+7 & 6) / 2
; held at 1). The ground below (TestBelowRight $C121): Y - 1, the splash frames
; (+7 stepped, frame +4 + 1, 2, 3) and at the end the timer 0, frame $7F and
; sound 5 (PlaySound $C4B2). The drop always tests the explorer (HitExplorer
; $C0DA), with no hit flag.
;
; Witness: L1 3288 (rzx x19). 105 splashes with sound 5 in 18 builds ($C04F).
DropFall:
  LD A,(IX+$01)
  ADD A,$02
  CP $67
  JR C,DropStep
  LD (IX+$02),$7F
  LD (IY+$08),$00
  RET
DropStep:
  LD (IX+$01),A
  CALL TestBelowRight
  LD A,(TileScanSecond+$0001)
  OR A
  JR NZ,DropSplash
  LD A,(IY+$07)
  INC A
  LD (IY+$07),A
  AND $06
  RRCA
  CP $02
  JR NZ,DropFrame
  DEC (IY+$07)
  DEC A
DropFrame:
  LD C,A
  ADD A,(IY+$04)
  LD (IX+$02),A
  JP HitExplorer
DropSplash:
  DEC (IX+$01)            ; on the ground: the splash frames
  INC (IY+$07)
  LD A,(IY+$07)
  AND $06
  RRCA
  JR NZ,DropFrame
  LD (IY+$08),A
  LD (IX+$02),$7F
  LD A,$05
  JP PlaySound

; Type 6: placed once, then animated in place until its frame is $55 or $7F
;
; The frames $55 and $7F are the ones the snake scripts set (SnakeStrike $B5C2,
; SnakeBite $B5C8): a still creature they have struck or removed stops. Else
; AnimateCreature $C0AC.
;
; Witness: L1 2107 (gameover, rzx x9).
StillCreature:
  BIT 0,(IY+$08)
  JR NZ,StillCreatureFrame
  CALL PlaceCreature
StillCreatureFrame:
  LD A,(IX+$02)
  CP $55
  RET Z
  CP $7F
  RET Z
  JP AnimateCreature

; Type 7: rise and sink through 4 frames, 16 steps, then a random pause
;
; CreatureTimer $BFA0 with C = $11 (a wait of at least $11, odd). One step a
; pass, +7 + 1: the frame index (+7 & $0E) / 2 folded at 4 runs 0 1 1 2 2 3 3 3
; 3 2 2 1 1 0 0, the frame +4 + index; after 16 steps (+7 bit 4) +7 keeps only
; its direction bit and the timer is cleared (a new pause). With the hit flag
; (+2 bit 7) the explorer is tested (HitExplorer $C0DA) at the frame index +3
; (3: the riser fully up), or at every frame when +3 is 4 or more.
;
; Witness: L1 11533 (c1, explorers, gameover, rzx x17).
RiserCreature:
  LD C,$11
  CALL CreatureTimer
  RET NZ
  INC (IY+$07)
  BIT 4,(IY+$07)
  JR Z,RiserFrame
  LD A,(IY+$07)
  AND $80
  LD (IY+$07),A
  XOR A
  LD (IY+$08),A
  RET
RiserFrame:
  LD A,(IY+$07)
  AND $0E
  RRCA
  BIT 2,A
  JR Z,RiserSetFrame
  CPL
  AND $03
RiserSetFrame:
  LD C,A
  ADD A,(IY+$04)
  LD (IX+$02),A
  BIT 7,(IY+$02)
  RET Z
  LD A,(IY+$03)
  CP $04
  JR NC,HitExplorer
  LD A,C
  CP (IY+$03)
  RET NZ
  JR HitExplorer

; Step the creature's animation (frames +4 to +4 + 3) and test the explorer if
; it can hit
;
; +7 + 1, kept to bit 7 and bits 0-2; frame = +4 + (+7 & 6) / 2; the object
; flag byte IX+3 = +7 (the direction bit mirrors the sprite). With the hit flag
; (+2 bit 7): the explorer is tested (HitExplorer $C0DA) at every frame when
; the hit frame +3 is 4 or more, else only at frame index +3 (no room record
; has a hit frame below 4 for these types: not executed in any recording).
;
; Witness: L1 8663 (c1, explorers, gameover, rzx x18).
AnimateCreature:
  LD A,(IY+$07)
  INC A
  AND $87
  LD (IY+$07),A
  AND $7E
  RRCA
  ADD A,(IY+$04)
  LD (IX+$02),A
  LD A,(IY+$07)
  LD (IX+$03),A
  BIT 7,(IY+$02)
  RET Z
  LD A,(IY+$03)
  CP $04
  JR NC,HitExplorer
  LD A,(IY+$07)
  AND $06
  RRCA
  CP (IY+$03)
  RET NZ

; A creature that touches the explorer: status $18 (or $1A)
;
; IX = the creature's object. The explorer ($5B04 as IY) near it ($9140: within
; $10 pixels both ways, 8 for the drop's frames $5C-$5F): when the status is
; below $0F, status $18 (CreatureDeath $A89E); if the status is 0 and the flag
; $A101 is 0, status $1A (FallDeath $A888) instead. During the statuses $0F and
; above (the scripted events) creatures do not hit.
;
; Witness: L1 10981 (c1, explorers, gameover, rzx x26). 23 contacts in 4 builds
; ($C0E6), 4 of them set a status ($C0F9: rzx06000, rzx22000, rzx24000,
; rzx32000), $1A once (rzx24000).
HitExplorer:
  PUSH IY
  LD IY,Hero
  CALL Near
  POP IY
  RET NC
  LD C,$18
  LD A,(Status)
  CP $0F
  RET NC
  OR A
  JR NZ,HitExplorerStatus
  LD A,(HeroProbes+$0003)
  OR A
  JR NZ,HitExplorerStatus
  LD C,$1A
HitExplorerStatus:
  LD A,C
  JP SetStatus

; Test the tiles under the creature with $A2AC (SK: under the feet), the flag
; in TileScanFlags+0
;
; Witness: L1 4553 (c1, explorers, rzx x12).
TestBelow:
  PUSH IY
  LD IY,TileScanFlags
  CALL LeftWallCheck
  POP IY
  RET

; Test the tiles right of the creature with $A2FA (SK: X + 23), the flag in
; TileScanFlags+1
;
; Witness: L1 1724 (rzx x14).
TestRight:
  PUSH IY
  LD IY,TileScanFlags
  CALL RightWallCheck
  POP IY
  RET

; Test a tile with $A31F (SK: X + 12, the special tiles), the flag in
; TileScanFlags+4
;
; Witness: L1 138 (rzx x3).
TestAhead:
  PUSH IY
  LD IY,TileScanSecond
  CALL CreatureSolidAt
  POP IY
  RET

; Test a tile with $A30B (SK: X + 12, Y + 24), the flag in TileScanFlags+5
;
; Witness: L1 3402 (rzx x21).
TestBelowRight:
  PUSH IY
  LD IY,TileScanSecond
  CALL CreatureFloorBelow
  POP IY
  RET

; The results of the creatures' tile tests: two records of 4 bytes
;
; $A2AC and $A2FA write +0 and +1 through IY = $C12D, $A31F and $A30B write +4
; and +5 through IY = TileScanSecond $C131 (LeftWallCheck, RightWallCheck,
; CreatureSolidAt, CreatureFloorBelow). +2, +3, +6, +7 are only read by the
; load in c1. SK took $C12E-$C134 for NOPs (code).
TileScanFlags:
  DEFB $00,$00,$00,$00
TileScanSecond:
  DEFB $00,$00,$00,$00

; Put the creature in its start place: X, Y, frame and flags from its record
;
; IX = the object slot, IY = the record: timer bit 0 set (placed), X = +5, Y =
; +6, frame = +4, IX+3 = +7. The type 8 handler (scenery: placed every pass, so
; it never moves or animates), and called by the other handlers at their first
; pass.
;
; Witness: L1 2377 (c1, explorers, gameover, rzx x26).
PlaceCreature:
  SET 0,(IY+$08)
  LD A,(IY+$05)
  LD (IX+$00),A
  LD A,(IY+$06)
  LD (IX+$01),A
  LD A,(IY+$04)
  LD (IX+$02),A
  LD A,(IY+$07)
  LD (IX+$03),A
  RET

; The creatures of each room $00-$47: 3 records of 4 bytes a room, 12 bytes
;
; DecodeRoomCreatures $BE42 reads the 12 bytes at $C152 + 12 x Room on every
; room entry (from $9855) and unpacks each 4-byte record into a 10-byte record
; of CreatureRecords $BE24, which RunCreatures $BE98 runs every pass in the
; object slots $5B08, $5B0C, $5B10 (record k in slot k + 1). An all-zero record
; is an empty slot (type 0, RET).
;
; The record: byte 0 = the hit flag in bit 7, the hit frame in bits 4-6 (0-7; 4
; and more: every frame hits), the type in bits 0-3 (an index into
; CreatureHandlers $BECA); byte 1 = the first sprite frame of its animation
; (the object frame byte, IX+2); byte 2 = the start X; byte 3 = the start Y in
; bits 0-6 and the start direction in bit 7 (types 1 and 2: set = moving right
; / down; the fliers force it, 3 clear and 4 set; AnimateCreature copies it to
; the object flag byte IX+3 with the animation counter). The hit flag and the
; hit frame are used by AnimateCreature $C0AC and RiserCreature $C069 only; the
; drop ($BFF6) always tests contact.
;
; The types: 1 walker (2 pixels a pass along X, turns at a wall or the room
; edge, WalkerCreature $BEDD), 2 climber (the same along Y, ClimberCreature
; $BF22), 3 left flier and 4 right flier (wait a random time, then fly across
; once, $BF67, $BFBB), 5 drop (waits, falls, splashes with sound 5, $BFF6), 6
; still (animated in place until its frame is $55 or $7F, $C054), 7 riser
; (rises and sinks in a cycle with random pauses, $C069), 8 scenery (put in
; place every pass, never animated, never hits: CreatureHandlers points type 8
; straight at PlaceCreature $C135). Counted over the 72 rooms: 33 drops, 20
; risers, 10 walkers, 10 scenery, 8 still, 3 right fliers, 2 left fliers, 2
; climbers. The sprite frames the types use: drops $5C, risers $58, walkers $60
; / $78 / $6B, the snakes of room $17 $51 (SnakesRoom17 $B55A and RunSnakes
; $B57C animate them), still ones $64; SK names (Room-Format.md / Actors.md):
; $05 Water Drop, $07 Tentacles in a concrete block, $01 / $03 Flying Lizard.
;
; 72 rooms (864 bytes, to $C4B1), the 70 of the map and the portal rooms $46,
; $47 (both empty). Witness: every play build reads the records of the rooms it
; enters, 4 bytes at a time a slot (DecodeRoomCreatures, L1 105 runs in 31
; builds); rooms $01, $02, $05, $06, $11, $12, $1E, $21, $24, $25, $2E, $2F,
; $46, $47 are read only by the load in c1.
RoomCreatures:
  INCBIN "res/rooms/table.bin",$0000,864
