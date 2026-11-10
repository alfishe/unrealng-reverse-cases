; --------------------------------------------------------------------------------------------------------------------
; world.asm: The alien map: the room records, dealing the items, resetting the world
; --------------------------------------------------------------------------------------------------------------------

; HL = the alien record of room C
;
; AlienMap + AlienMap[2 x C] (the authors' lookup). L1 4 746.
RoomRecord:
  LD HL,AlienMap
  LD D,$00
  LD E,C
  SLA E
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,AlienMap
  ADD HL,DE
  RET

; Move the non-weapon items one step round the rooms
;
; B = the item of room $7B; then for rooms 0-$7B in turn, each present item
; whose kind has bit 6 clear (GEN 19, energy, an ED piece; not a weapon) swaps
; with B. Each call moves every such item to the next room that holds one:
; NewGame calls it 1-31 times (Random), so the pieces' rooms change from game
; to game. The authors' scram. L1 34 calls.
ScrambleRooms:
  LD C,$7B
  CALL RoomRecord
  INC HL
  LD B,(HL)
  LD C,$00
ScrambleRoomsLoop:
  CALL RoomRecord
  XOR A
  CP (HL)
  JR Z,ScrambleRoomsItem2
  INC HL
  BIT 6,(HL)
  JR NZ,ScrambleRoomsItem2
  LD A,(HL)
  LD (HL),B
  LD B,A
ScrambleRoomsItem2:
  INC HL
  XOR A
  CP (HL)
  JR Z,ScrambleRoomsNext
  INC HL
  BIT 6,(HL)
  JR NZ,ScrambleRoomsNext
  LD A,(HL)
  LD (HL),B
  LD B,A
ScrambleRoomsNext:
  INC C
  LD A,$7C
  CP C
  JR NZ,ScrambleRoomsLoop
  RET

; Every item present again, every object reset
;
; Rooms 0-$7B: bit 7 set on both item kinds; for each object record: the
; direction kept (AND 3) and bit 6 set, the graphic, width and kill mark from
; ObjectKind, the frame 0. L1 4.
InitRooms:
  LD C,$00
InitRoomsLoop:
  PUSH BC
  CALL RoomRecord
  XOR A
  CP (HL)
  JR Z,InitRoomsItem2
  INC HL
  SET 7,(HL)
InitRoomsItem2:
  INC HL
  CP (HL)
  JR Z,InitRoomsTeleport
  INC HL
  SET 7,(HL)
InitRoomsTeleport:
  INC HL
  CP (HL)
  JR Z,InitRoomsObjects
  INC HL
InitRoomsObjects:
  INC HL
  INC HL
  CP (HL)
  JR Z,InitRoomsNext
  LD B,(HL)
  INC HL
  LD A,(HL)
  AND $03
  OR $40
  LD (HL),A
  INC HL
  INC HL
  INC HL
  CALL ObjectKind
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),C
  INC HL
  LD (HL),A
  INC HL
  INC HL
  XOR A
  CP (HL)
  JR Z,InitRoomsNext
  LD B,(HL)
  INC HL
  LD A,(HL)
  AND $03
  OR $40
  LD (HL),A
  INC HL
  INC HL
  INC HL
  CALL ObjectKind
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),C
  INC HL
  LD (HL),A
InitRoomsNext:
  POP BC
  INC C
  LD A,$7C
  CP C
  JR NZ,InitRoomsLoop
  RET

; An object's graphic, width and the weapon mark it dies to, by its kind bits
;
; In: B the kind (the record's first byte, bits 4-7). Bit 4: $B049, 3 frames,
; $40 (it dies to weapon 1's mark); bit 5: $B16C, 4 frames, $20 (weapon 2); bit
; 6: $B2F0, 3, $10 (weapon 3); bit 7: $B413, 4, $20; none: $B597, 3, $10. Out:
; DE the graphic (frames of 97 bytes: the shift byte, 24 rows of 4), C the
; frames, A the mark. L1 100.
ObjectKind:
  LD DE,ObjectGraphics
  LD C,$03
  LD A,$40
  BIT 4,B
  RET NZ
  LD DE,ObjectKind5
  LD C,$04
  LD A,$20
  BIT 5,B
  RET NZ
  LD DE,ObjectKind6
  LD C,$03
  LD A,$10
  BIT 6,B
  RET NZ
  LD DE,ObjectKind7
  LD C,$04
  LD A,$20
  BIT 7,B
  RET NZ
  LD DE,ObjectKindNone
  LD C,$03
  LD A,$10
  RET
