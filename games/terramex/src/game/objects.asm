; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The items: where they lie, pick up, the bearers, the swap
; --------------------------------------------------------------------------------------------------------------------

  ORG $B932

; Put every item back: clear the taken bit of all 31 ItemPlaces records
;
; Called by InitGame at $8F83 (a new game); InitGame then marks the Energy
; Crystal of room $30 taken ($8F86). Witness: c1 once, explorers 5 times,
; rzx00000 once (the new games).
;
; Witness: L1 7 (c1, explorers, rzx).
ResetItems:
  LD B,$1F
  LD HL,ItemPlaces
ResetItemsLoop:
  RES 7,(HL)
  INC HL
  INC HL
  INC HL
  DJNZ ResetItemsLoop
  RET

; Fill the two item slots with the items of this room
;
; Both item slots $5C0E and $5C13 emptied (item $FF: IX+2 and IX+7), then the
; 31 ItemPlaces $B99D records are scanned for Room ($5C01) and each match goes
; to PlaceItem $B95F, C counting the matches. Taken items carry bit 7 in their
; room byte and never match. Called on every room entry ($9911, the end of the
; room set-up), after a gift to the professor ($B5F8) and after the crystal is
; placed ($BA27).
;
; Witness: L1 113 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
SpawnRoomItems:
  LD IX,ItemSlot1
  LD (IX+$02),$FF
  LD (IX+$07),$FF
  LD HL,ItemPlaces
  LD A,(Room)
  LD C,$00
  LD B,$1F
SpawnRoomItemsLoop:
  CP (HL)
  CALL Z,PlaceItem
  INC HL
  INC HL
  INC HL
  DJNZ SpawnRoomItemsLoop
  RET

; Put the item of an ItemPlaces record into the next free item slot
;
; HL = the record, C = the slots used so far (0, 1; 2 and more: the record is
; ignored). The slot ($5C0E for C = 0, $5C13 for C = 1) gets X, Y and the item
; (byte 1 & $1F) decoded from the record (ItemPlaces $B99D) and the record's
; address in its bytes +3 and +4, for PickUpItem $BB6C to mark it taken. Out: C
; + 1; HL, AF, B kept.
;
; Witness: L1 42 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). The second slot ($B96A) is used 3
; times (gameover, rzx10000, rzx14500).
PlaceItem:
  BIT 1,C
  RET NZ
  LD IX,ItemSlot1
  BIT 0,C
  JR Z,PlaceItemSlot
  LD IX,ItemSlot2
PlaceItemSlot:
  INC C                   ; the record's address into slot +3, +4
  PUSH HL
  PUSH AF
  PUSH BC
  LD (IX+$03),L
  LD (IX+$04),H
  INC HL
  LD A,(HL)
  INC HL
  LD C,(HL)
  PUSH AF
  AND $1F
  LD (IX+$02),A
  POP AF
  AND $E0                 ; X = (byte2 & 3) x 64 + (byte1 & $E0) / 4
  LD L,A
  LD A,C
  AND $03
  RRA
  RR L
  RRA
  RR L
  LD (IX+$00),L
  LD A,C                  ; Y = (byte2 & $FC) x 2
  AND $FC
  ADD A,A
  LD (IX+$01),A
  POP BC
  POP AF
  POP HL
  RET

; Where the items lie: 31 records of 3 bytes, [room + taken bit, item,
; position]
;
; Byte 0: the room ($00-$47) in bits 0-6, bit 7 set when the item has been
; taken (PickUpItem $BB6C sets it through the record address the slot keeps; it
; then matches no room). Byte 1: the item (0-31, an index into the item sprites
; $8400) in bits 0-4 and bits 3-5 of X in bits 5-7. Byte 2: bits 6-7 of X in
; bits 0-1 and Y / 8 in bits 2-7 (byte2 & $FC = Y / 2). So X = (byte2 & 3) * 64
; + (byte1 & $E0) / 4 and Y = (byte2 & $FC) * 2, both multiples of 8 (PlaceItem
; $B95F). Checked live: record 15 (room $21, Barrel Small, byte2 $24) lies at X
; $28, Y $48 (work/stage2/probe_points.py).
;
; ResetItems $B932 clears every taken bit at a new game; InitGame then sets the
; one of record 20 ($B9D9, the Energy Crystal of room $30) at $8F86, so that
; crystal is not there until the explorer puts it in place (ItemsPass $B9FA
; clears the bit again). SpawnRoomItems $B93F scans the records for the room on
; every room entry and puts the first two matches in the item slots $5C0E and
; $5C13; no room has more than two. The Formula (15) lies in each of the four
; portal rooms $2E, $2F, $46, $47; rooms $10 and $1D hold two items each.
;
; The item names are those of the SkoolKit notes (SK, Items-Format.md); in-play
; checks: the pickups the play builds make (PickUpItem $BBE4, 22 runs in 13
; builds).
ItemPlaces:
  INCBIN "res/tables/item-places.bin",$0000,60
CrystalPlace:
  INCBIN "res/tables/item-places.bin",$003C,33

; The items of a pass: pick up, the crystal of room $30, the bearer keys, the
; swap, the bridges, the rope
;
; Called by the main loop every pass ($9034), IX = the explorer $5B04. In room
; $30 the pickup is skipped (the return address is set to ItemsKeys $BA36) and
; the Energy Crystal is placed instead: holding it (HeldItem $5B98 = $18) with
; the explorer at Y $60, X $40-$4B, the crystal's ItemPlaces record
; (CrystalPlace $B9D9) loses its taken bit so the crystal lies in its place,
; HeldItem = $FF, CrystalPlaced $5C44 = $FF (read by $A910), the room's items
; spawned again ($B93F), +75 score, the hand icon redrawn. In every other room
; PickUpItems $BB5D runs.
;
; Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). The crystal is placed once
; ($BA1A, rzx24750).
ItemsPass:
  LD A,(Room)
  CP $30
  JR NZ,ItemsPickUp
  LD HL,ItemsKeys
  PUSH HL
  LD A,(HeldItem)
  CP $18
  RET NZ
  LD A,(IX+$01)
  CP $60
  RET NZ
  LD A,(IX+$00)
  CP $40
  RET C
  CP $4C
  RET NC
  LD HL,CrystalPlace      ; the crystal back in its place: clear the taken bit
                          ; of its record
  RES 7,(HL)
  LD A,$FF
  LD (HeldItem),A
  LD (CrystalPlaced),A
  CALL SpawnRoomItems
  LD DE,$004B             ; +75
  CALL AddScore
  JP DrawPortrait
ItemsPickUp:
  CALL PickUpItems        ; not room $30: pick up what the explorer touches

; The bearer keys 1 and 2, the swap key S, then the room effects of rooms $19,
; $3A and $10
;
; BearerKeys $BC1F with Z set when no scroll runs (BearerPhase $5C22 = 0). Then
; the S key (port $FDFE bit 1; the Help page: "S=Swap item with another
; nearest"): on a new press (SwapLatch $BA96 = 0), unless the status is $1B,
; $1C or $1D, the held item and the load of the bearer at BearerIndex $5C23
; change places (either may be $FF, nothing), both icon rows are redrawn
; ($9EBD, $9E5D) and SwapLatch is set until S is released. Then BridgeEffect
; $BA97 in rooms $19 and $3A (A = the room) and RopeTrick $BC73 in room $10.
;
; Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). The swap runs 34 times in
; 21 builds ($BA5B).
ItemsKeys:
  LD A,(BearerPhase)
  OR A
  CALL BearerKeys
  LD BC,$FDFE
  IN A,(C)
  AND $02
  JR NZ,SwapRelease
  LD A,(Status)            ; S pressed: not during status $1B, $1C, $1D
  CP $1B
  JR Z,SwapRelease
  CP $1C
  JR Z,SwapRelease
  CP $1D
  JR Z,SwapRelease
  LD A,(SwapLatch)
  OR A
  JR NZ,ItemsRoomEffects
  LD A,(BearerIndex)            ; swap HeldItem with the load of bearer BearerIndex
  LD E,A
  LD D,$00
  LD HL,BearerLoads
  ADD HL,DE
  LD A,(HeldItem)
  LD E,A
  LD A,(HL)
  LD (HeldItem),A
  LD (HL),E
  CALL DrawBearers
  CALL DrawPortrait
  LD A,$01
  LD (SwapLatch),A
  JR ItemsRoomEffects
SwapRelease:
  XOR A                   ; S released: SwapLatch = 0
  LD (SwapLatch),A
ItemsRoomEffects:
  LD A,(Room)            ; rooms $19 and $3A: the bridge; room $10: the rope
  CP $19
  PUSH AF
  CALL Z,BridgeEffect
  POP AF
  PUSH AF
  CP $3A
  CALL Z,BridgeEffect
  POP AF
  CP $10
  CALL Z,RopeTrick
  RET

; 1 while the S key is held after a swap, so one press swaps once
;
; Witness: written every pass in all 34 builds.
SwapLatch:
  DEFB $00

  ORG $BB59

; PUSH HL, CP A, POP HL, RET: returns with Z set, nothing else
;
; Called by BridgeEffect $BA97 ($BA9F) before its start test, which returns
; when Z is clear: never. A test left empty (known only from the code).
;
; Witness: L1 489 (rzx, rzx, rzx, rzx).
AlwaysZero:
  PUSH HL
  CP A
  POP HL
  RET

; Pick up the items the explorer touches: both item slots
;
; IX = the explorer $5B04; PickUpItem $BB6C for slot $5C0E, then for slot $5C13
; (fallen into). Called by ItemsPass $B9FA every pass except in room $30.
;
; Witness: L1 26330 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PickUpItems:
  LD IX,Hero
  LD IY,ItemSlot1
  CALL PickUpItem
  LD IY,ItemSlot2

; Pick up the item of slot IY if the explorer touches it
;
; IY = the item slot. When the explorer is near ($9140) an item there (below
; $FE): the first free bearer is found (BearerLoads $5B7C, 27 bytes, $FF free:
; the "invisible bearers" of the Help page; with none free nothing happens, not
; executed in any recording). Item $16 (the Anti Radiation Pills) also sets
; PillsTaken $5C3F. The Cannon (8) is never picked up. The Spring ($0E) and the
; Trampoline ($14) are not picked up either: when the explorer touches one in
; status 2 with $5C07 at least 10 and X within 5 pixels of it he is set on top
; of it (X = its X, Y = its Y - $17, frame $0F, status 5: the bounce, BounceUp
; $AD17).
;
; Any other item is taken: the held item, if any, goes to the free bearer (and
; BearerIndex $5C23 is moved to show it: C - 2, not below 0), +50 score, sound
; 2, HeldItem = the item, the slot emptied (item $FE) and its ItemPlaces record
; marked taken (bit 7 of the room byte through slot +3, +4). The icon rows are
; redrawn ($9E5D, $9EBD).
;
; Witness: L1 52660 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). 30 pickups in 15 builds
; ($BBDA), 22 of them with an item in hand ($BBE4); the bounce 3 times ($BBC1:
; gameover, rzx10000, rzx22000).
PickUpItem:
  XOR A
  LD C,A
  LD E,A
  LD D,A
  CALL Near
  JP NC,PickUpRedraw
  LD A,(IY+$02)
  CP $FE
  JP NC,PickUpRedraw
  LD HL,BearerLoads
  PUSH BC
  LD B,$1B
FindFreeBearer:
  LD A,(HL)               ; the first bearer with no load
  CP $FF
  JR Z,PickUpKind
  INC HL
  INC C
  DJNZ FindFreeBearer
  JR PickUpDone
PickUpKind:
  LD A,(IY+$02)           ; the Pills set PillsTaken; the Cannon stays
  CP $16
  JR NZ,PickUpCannon
  LD (PillsTaken),A
PickUpCannon:
  CP $08
  JR Z,PickUpDone
  CP $0E
  JR Z,PickUpBounce
  CP $14
  JR NZ,PickUpTake
PickUpBounce:
  LD A,(Status)            ; Spring or Trampoline: the explorer lands on it
  CP $02
  JR NZ,PickUpDone
  LD A,(StatusTimer)
  CP $0A
  JR C,PickUpDone
  LD A,(Hero)
  SUB (IY+$00)
  JR NC,BounceNear
  NEG
BounceNear:
  CP $06
  JR NC,PickUpDone
  LD A,(IY+$00)
  LD (IX+$00),A
  LD A,(IY+$01)
  SUB $17
  LD (IX+$01),A
  LD (IX+$02),$0F
  LD A,$05
  LD (Status),A
  JR PickUpDone
PickUpTake:
  LD D,$01                ; taken: the held item to the free bearer
  EX AF,AF'
  LD A,(HeldItem)
  CP $FF
  JR Z,PickUpScore
  LD (HL),A
  LD E,$01
PickUpScore:
  EX AF,AF'               ; +50, sound 2
  PUSH DE
  LD DE,$0032
  CALL AddScore
  PUSH AF
  LD A,$02
  CALL PlaySound
  POP AF
  POP DE
  LD (HeldItem),A
  LD (IY+$02),$FE         ; the slot emptied, the record marked taken
  LD L,(IY+$03)
  LD H,(IY+$04)
  SET 7,(HL)
PickUpDone:
  POP HL

; Redraw the hand icon (D not 0) and the bearers (E not 0) after PickUpItem
;
; D, E as PickUpItem $BB6C leaves them; C = the bearer the held item went to:
; BearerIndex $5C23 = C - 2 (0 for C 0 and 1), then the bearer row is drawn
; ($9EBD).
;
; Witness: L1 52660 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PickUpRedraw:
  PUSH DE
  LD A,D
  OR A
  CALL NZ,DrawPortrait
  POP DE
  LD A,E
  OR A
  RET Z
  LD A,C
  OR A
  JR Z,PickUpShowBearer
  DEC A
  JR Z,PickUpShowBearer
  DEC A
PickUpShowBearer:
  LD (BearerIndex),A
  JP DrawBearers

; The bearer keys: 1 moves the bearers right, 2 moves them left, with a 4-step
; scroll
;
; Z set on entry when no scroll runs (BearerPhase $5C22 = 0). Then key 1 (port
; $F7FE bit 0) sets BearerScrollDir $5C21 = 1, BearerPhase = 4 and BearerIndex
; $5C23 - 1 (from 0 to $1A: the 27 bearers wrap); key 2 (bit 1) clears
; BearerScrollDir and BearerPhase. No key: nothing (both at once count as key
; 1). While a scroll runs (and after key 2): with BearerScrollDir 0 the phase
; counts up 1 a call and at 4 BearerIndex + 1 (from $1A to 0) and the phase is
; 0; with BearerScrollDir 1 it counts down from 4. Every step redraws the
; bearer row ($9EBD: four bearers from BearerIndex, shifted by BearerPhase).
; The Help page: "1=Move bearers and objects right 2=Move bearers and objects
; left".
;
; Witness: c1 presses 1 and 2 (tests/inputs/c1.txt); key 1 runs 128 times in 21
; builds ($BC2F), key 2 113 times in 21 ($BC43).
;
; Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
BearerKeys:
  JR NZ,BearerScrollStep
  LD BC,$F7FE
  IN A,(C)
  AND $03
  CP $03
  RET Z
  AND $01                 ; key 1: BearerIndex - 1, scroll from phase 4 down
  JR NZ,BearerKey2
  LD A,$01
  LD (BearerScrollDir),A
  LD A,$04
  LD (BearerPhase),A
  LD HL,BearerIndex
  DEC (HL)
  BIT 7,(HL)
  RET Z
  LD (HL),$1A
  RET
BearerKey2:
  XOR A                   ; key 2: scroll from phase 0 up
  LD (BearerScrollDir),A
  LD (BearerPhase),A
BearerScrollStep:
  LD A,(BearerScrollDir)            ; the scroll's next step
  OR A
  JR NZ,BearerScrollBack
  CALL DrawBearers
  LD HL,BearerPhase
  INC (HL)
  LD A,(HL)
  CP $04
  RET NZ
  LD (HL),$00             ; phase 4: the next bearer, BearerIndex + 1
  LD HL,BearerIndex
  INC (HL)
  LD A,(HL)
  CP $1B
  JP NZ,DrawBearers
  LD (HL),$00
  JP DrawBearers
BearerScrollBack:
  LD HL,BearerPhase             ; BearerScrollDir 1: the phase down
  DEC (HL)
  JP DrawBearers
