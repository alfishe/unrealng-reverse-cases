; Objects to screen places and depth lists
;
; Once a pass (docs/04-game-loop.md 4.3, step 6). Starts three lists: $C99E
; (record addresses of visible types 14-15, $FF ends it), $FF00 (4-byte entries
; sorted by height, a $40 entry ends it) and $6500 (the same, ended by $40).
; Calls $EFDC for every live record of $C000 and at the end of the list jumps
; to $F089. docs/06-rendering.md 6.6.
PlaceObjects:
  LD IX,PlayerRecord
  LD HL,SegmentRows+$00B4 ; the static-object list, empty
  LD (StaticListEnd),HL
  INC HL
  LD (HL),$FF
  LD HL,SpriteListArea+$0001 ; the depth list, only the $40 end entry
  LD (DepthListEnd),HL
  LD (HL),$00
  DEC L
  LD (HL),$40
  LD HL,SpriteScratch+$0001 ; the draw list, only the $40 end entry
  LD (DrawListEnd),HL
  LD (HL),$00
  DEC L
  LD (HL),$40
PlaceRecordsLoop:
  LD A,(IX+$00)
  BIT 6,A                 ; bit 6: the end of the records
  JP NZ,SortDrawList
  BIT 7,A                 ; bit 7: gone, not shown
  CALL Z,PlaceObject
  LD DE,$0010
  ADD IX,DE
  JR PlaceRecordsLoop

; One record: its screen place, into a list
;
; The distance ahead of the scroll (+1,+2 less $D14D) less the position across
; must be 1-$11F, else the record is not shown. It sets +B = (distance - across
; + 1) / 8, the column of strips; +9 = ((distance - across) / 2) AND 3, the
; phase within the strip, 1 while exploding; +A = $C32F + across + $10 + phase.
; Types 14 and 15 go to the list at $C99E (stamped into the buffer by $EA38);
; the others are inserted into the $FF00 list by height (+4), as height,
; (distance + across) / 2 + 1, record address. 41 391 calls in the first
; recording. docs/06-rendering.md 6.6, docs/07-objects.md 7.1.
PlaceObject:
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD BC,(ScrollDistance)  ; less the distance scrolled
  AND A
  SBC HL,BC
  LD D,H
  LD E,L
  LD C,(IX+$03)
  LD B,$00
  AND A
  SBC HL,BC               ; less the position across
  DEC HL
  LD A,H
  BIT 7,A                 ; behind the view: not shown
  RET NZ
  AND A
  JR Z,InViewAhead
  CP $01
  RET NZ
  LD A,L                  ; $120 or more ahead: not shown
  CP $1F
  RET NC
InViewAhead:
  INC HL
  INC HL
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  LD (IX+$0B),L           ; +B: the strip column
  EX DE,HL
  LD A,L                  ; +9: the phase, 0-3
  SUB C
  SRL A
  AND $03
  BIT 5,(IX+$00)          ; exploding: phase 1
  JR Z,StorePhase
  LD A,$01
StorePhase:
  LD (IX+$09),A
  LD E,A
  LD A,(ScrollHalf)       ; +A: the line in the strip
  ADD A,C
  ADD A,$10
  ADD A,E
  LD (IX+$0A),A
  LD A,(IX+$00)
  AND $0F
  CP $0E                  ; types 14-15: the static list
  JR C,DepthListInsert
  LD HL,(StaticListEnd)
  LD E,IXL
  LD D,IXH
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  LD (StaticListEnd),HL
  INC L
  LD (HL),$FF
  RET
DepthListInsert:
  ADD HL,BC               ; (distance + across) / 2 + 1
  SRL H
  RR L
  LD A,L
  INC A
  LD C,A
  LD A,(IX+$04)
  LD B,A
  LD HL,SpriteListArea    ; the first entry higher than this record
FindHeightSlot:
  CP (HL)
  JR C,OpenDepthGap
  INC L
  INC L
  INC L
  INC L
  JP FindHeightSlot
OpenDepthGap:
  LD DE,(DepthListEnd)    ; open a 4-byte gap: the tail moves up
  PUSH HL
  PUSH BC
  LD A,E
  SUB L
  LD C,A
  LD B,$00
  INC C
  LD L,E
  INC E
  INC E
  INC E
  INC E
  LD (DepthListEnd),DE
  LDDR
  POP BC
  POP HL
  LD (HL),B               ; height, depth, record address
  INC L
  LD (HL),C
  INC L
  LD E,IXL
  LD D,IXH
  LD (HL),E
  INC L
  LD (HL),D
  RET

; The depth list into the draw list at $6500
;
; Each entry of $FF00 (height, depth, record) is inserted into the list at
; $6500 before the first entry more than 9 above it, or within 9 in height and
; with a smaller depth byte. So among objects that overlap in height, the
; farther one comes first. The draw list is read by the sprite pass $D9D6.
; docs/06-rendering.md 6.6.
SortDrawList:
  LD DE,SpriteListArea
SortEntryLoop:
  LD A,(DE)               ; bit 6: the $40 end entry
  BIT 6,A
  RET NZ
  LD B,A
  INC E
  LD A,(DE)
  DEC A
  LD C,A
  DEC E
  LD HL,SpriteScratch
FindDrawSlot:
  LD A,B                  ; heights within 9 of each other?
  ADD A,$09
  SUB (HL)
  CP $13
  JP C,CompareDepth
  BIT 7,A                 ; more than 9 higher: insert here
  JR NZ,InsertDrawEntry
  INC L
  INC L
  INC L
  INC L
  JP FindDrawSlot
CompareDepth:
  LD A,C                  ; overlapping: by the depth byte
  INC L
  CP (HL)
  JR NC,BackToEntryStart
  INC L
  INC L
  INC L
  JP FindDrawSlot
BackToEntryStart:
  DEC L
InsertDrawEntry:
  PUSH DE                 ; open a 4-byte gap and copy the entry in
  PUSH HL
  LD DE,(DrawListEnd)
  LD A,E
  SUB L
  LD C,A
  LD B,$00
  INC C
  LD L,E
  INC E
  INC E
  INC E
  INC E
  LD (DrawListEnd),DE
  LDDR
  POP DE
  POP HL
  LD BC,$0004
  LDIR
  EX DE,HL
  JP SortEntryLoop
