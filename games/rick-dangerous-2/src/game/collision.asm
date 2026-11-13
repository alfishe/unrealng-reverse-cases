; --------------------------------------------------------------------------------------------------------------------
; collision.asm: Hit tests: points and boxes against boxes, the bullet's wall probe, the bomb's ground probe
;
; The tests return C for a hit. A box is given as E (x), HL (y, pixels from the view's top, 16 bits), C (width) and B
; (height); a record at IX gives its own box as +1 (x), +2/+3 (y), +7 (width), +8 (height). Rick's box is x $9BAC + 4,
; y $9BAD (5 lower when he crawls, $9B98), 16 x 21 pixels (16 x 16 crawling).
;
; The far cases (the two y differing by 256 or more) end in XOR A / RET or SCF / RET pairs that no recording ran and
; that the walk keeps as bytes (the read builds mark them read).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8C6C

; C when the punch's point ($9BA5, $9BA6) lies in the box (E, HL, C x B)
;
; Inside when 0 <= x - E < C and 0 <= y - HL < B. Callers: TestEnemyHits
; ($8C51, 386), $A76C (the trigger boxes, 271). Witness: 657 runs in 34 builds.
;
; Witness: L1 1314 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l3-00000-poke,
; rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-full).
PunchHits:
  LD A,(PunchX)
  SUB E
  JP NC,PunchInX
  CCF
  RET
PunchInX:
  JP Z,PunchTestY
  CP C
  RET NC
PunchTestY:
  EX DE,HL
  LD HL,(PunchY)
  OR A
  SBC HL,DE
  CCF
  RET NC
  LD A,H
  AND A
  JP NZ,PunchHitsFar
  LD A,L
  CP B
  RET

; XOR A / RET: the punch 256 or more pixels below
;
; Witness: L1 0 ().
PunchHitsFar:
  XOR A
  RET

; C when the bullet's point ($9BB5, $9BB6) lies in the box (E, HL, C x B)
;
; As PunchHits. Callers: TestEnemyHits ($8C0B, 717), $A5DE (pickups, 123),
; $A729 (trigger boxes, 43). Witness: 883 runs in 33 builds.
;
; Witness: L1 1766 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke,
; rzx-l5-20000-poke, rzx-l5-full).
BulletHits:
  LD A,(BulletX)
  SUB E
  JP NC,BulletInX
  CCF
  RET
BulletInX:
  JP Z,BulletTestY
  CP C
  RET NC
BulletTestY:
  EX DE,HL
  LD HL,(BulletY)
  OR A
  SBC HL,DE
  CCF
  RET NC
  LD A,H
  AND A
  JP NZ,BulletHitsFar
  LD A,L
  CP B
  RET

; XOR A / RET: the bullet 256 or more pixels below
;
; Witness: L1 0 ().
BulletHitsFar:
  XOR A
  RET

; C when the detonator's blast (24 x 29 from $9BBE, $9BBF - 4) overlaps the box
; (E, HL, C x B)
;
; Overlap when -24 < x - E < C and -29 < (y - 4) - HL < B. Callers:
; TestEnemyHits ($8C2B, 173), $A755 (trigger boxes, 194), level 5's $F938 (14).
; Witness: 381 runs in 26 builds.
;
; Witness: L1 762 (rzx-l1-00000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke,
; rzx-l1-16000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full).
BlastHits:
  LD A,(DetonatorX)
  SUB E
  JP NC,BlastRight
  NEG
  CP $18
  JP C,BlastTestY
  RET
BlastRight:
  JP Z,BlastTestY
  CP C
  RET NC
BlastTestY:
  EX DE,HL                ; the blast reaches 4 rows above the bomb's y
  LD HL,(DetonatorY)
  LD A,L
  SUB $04
  LD L,A
  JP NC,BlastCompareY

; DEC H: the bomb's y - 4 borrowing from its high byte
;
; Witness: L1 0 ().
BlastBorrow:
  DEC H

; BlastHits, continued: the y overlap
;
; Evidence: 105 runs in 21 builds.
;
; Witness: L1 210 (rzx-l1-00000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke,
; rzx-l1-16000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke,
; rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-04000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full).
BlastCompareY:
  OR A
  SBC HL,DE
  JP NC,BlastBelow
  INC H
  JP NZ,BlastHitsFar
  LD A,L
  NEG
  CP $1D
  RET
BlastBelow:
  LD A,H                  ; the blast's top at or below the box's top
  AND A
  JP NZ,BlastHitsFar
  LD A,L
  CP B
  RET

; XOR A / RET: 256 or more pixels apart
;
; Witness: L1 0 ().
BlastHitsFar:
  XOR A
  RET

; C when the point (E, HL) lies in the record at IX: (IX+1) < E <= (IX+1) +
; (IX+7), 0 <= HL - y < (IX+8)
;
; Called by ProbePoint for the solid objects. Witness: 336 runs in 18 builds; a
; hit twice.
;
; Witness: L1 672 (rzx-l1-00000-poke, rzx-l1-12000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-16000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-06000-poke, rzx-l4-02000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l5-02000-poke, rzx-l5-08000-poke, rzx-l5-full).
PointInObject:
  LD A,(IX+$01)
  CP E
  RET NC
  ADD A,(IX+$07)
  CP E
  JP NC,PointInObjectY
PointNotInObject:
  CCF
  RET
PointInObjectY:
  LD C,(IX+$02)
  LD B,(IX+$03)
  OR A
  SBC HL,BC
  JP C,PointNotInObject
  LD A,H
  AND A
  JP NZ,PointNotInObject
  LD A,L
  CP (IX+$08)
  RET

; What lies at the point (E, HL): 2 for a solid object, else the flags of the
; view cell there
;
; The 24-byte records at $7B8F up to the $FF end: one whose +0 has bits 7 and 6
; set and holds the point (PointInObject) gives A = 2. Else A =
; CellFlags[ViewCells[(HL / 8) x 32 + E / 8]] (bit 1: a wall).
;
; Callers: the bullet's flight $91BD (755) and level 5's $FAD0 (335). Witness:
; 1090 runs in 44 builds; a solid object twice (rzx-l2-12000-poke,
; rzx-l4-10000-poke).
;
; Witness: L1 2149 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48).
ProbePoint:
  PUSH IX
  LD IX,Entry
  LD BC,$0018
ProbeObjectLoop:
  LD A,(IX+$00)
  CP $FF
  JP Z,ProbeCell
  AND $C0
  CP $C0
  JP NZ,ProbeObjectNext
  PUSH HL
  CALL PointInObject
  POP HL
  JP NC,ProbeObjectMiss
  POP IX
  LD A,$02
  RET
ProbeObjectMiss:
  LD BC,$0018
ProbeObjectNext:
  ADD IX,BC
  JP ProbeObjectLoop
ProbeCell:
  POP IX                  ; the cell under the point in ViewCells
  ADD HL,HL
  ADD HL,HL
  LD A,L
  AND $E0
  LD L,A
  SRL E
  SRL E
  SRL E
  LD D,$00
  ADD HL,DE
  LD DE,ViewCells
  ADD HL,DE
  LD E,(HL)
  LD D,CellFlags/256
  LD A,(DE)
  RET

; C when the box (E, HL, C x B) overlaps Rick's box
;
; Overlap when -16 < ($9BAC + 4) - E < C and -B < HL - Rick's y <= 20 (15
; crawling; his y 5 lower then). Callers: TestEnemyHits ($8C63, 37 713), $93B1
; (the blast, 324), the traps $A470 (83 559), the trigger boxes $A6FE (99 544),
; level 5's $F943 and $FAC8. Witness: 222 000 runs in 64 builds.
;
; Witness: L1 533257 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TouchesRick:
  LD A,(RickX)
  ADD A,$04
  SUB E
  JP Z,TouchRickY
  JP C,TouchRickLeft
  CP C
  JP C,TouchRickY
  RET
TouchRickLeft:
  NEG
  CP $10
  RET NC
TouchRickY:
  LD DE,(RickY)           ; crawling: his top 5 lower, 16 rows tall
  LD A,(RickCrawling)
  AND A
  JP Z,TouchRickCompare
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  OR A
TouchRickCompare:
  SBC HL,DE
  JP Z,TouchRickSameY
  JP C,TouchRickAbove
  LD A,H
  AND A
  JP NZ,TouchRickFar
  LD A,(RickCrawling)
  AND A
  LD A,$14
  JP Z,TouchRickBelow
  LD A,$0F
TouchRickBelow:
  CP L
  CCF
  RET

; XOR A / RET: 256 or more pixels apart
;
; Witness: L1 0 ().
TouchRickFar:
  XOR A
  RET

; TouchesRick, continued: the box's top above Rick's
;
; Evidence: 18 534 runs in 57 builds.
;
; Witness: L1 42000 (cheats, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l3-load-l5,
; sec-l2-s11, sec-l4-s x5, sec-l5-s5).
TouchRickAbove:
  LD A,H
  INC A
  JP NZ,TouchRickFar
  LD A,L
  NEG
  CP B
  RET
; This entry point is used by the routine at TouchesRick.
TouchRickSameY:
  SCF
  RET

; C when the box (E, HL, C x B) overlaps the 16 x 21 box of the record at IX (x
; (IX+1) + 4)
;
; Callers: the traps $A451 (62 770, the enemies against a trap), $A79A (the
; trigger boxes, 683). Witness: 63 453 runs in 52 builds.
;
; Witness: L1 164313 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke,
; rzx-l1-16000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s11,
; sec-l2-s12, sec-l3-s5, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12,
; sec-l5-s3, sec-l5-s5).
TouchesObject:
  LD A,(IX+$01)
  ADD A,$04
  SUB E
  JP Z,TouchObjY
  JP C,TouchObjLeft
  CP C
  JP C,TouchObjY
  RET
TouchObjLeft:
  NEG
  CP $10
  RET NC
TouchObjY:
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  JP Z,TouchObjSameY
  JP C,TouchObjAbove
  LD A,H
  AND A
  JP NZ,TouchObjMiss
  LD A,L
  CP $15
  RET
TouchObjMiss:
  XOR A
  RET
TouchObjAbove:
  LD A,H
  INC A
  JP NZ,TouchObjMiss
  LD A,L
  NEG
  CP B
  RET

; SCF / RET: the same y, a hit
;
; Witness: L1 0 ().
TouchObjSameY:
  SCF
  RET

; C when the box (E, HL, C x B) overlaps the record at IX's own box (+7 wide,
; +8 tall)
;
; Callers: ProbeGround ($8ED8, $8F18), $90E6 and $912B (109 000 each), $A416,
; $A57D, $A7D7. Witness: 196 030 runs in 59 builds.
;
; Witness: L1 458710 (cheats, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7,
; sec-l3-s9, sec-l4-s x5, sec-l5-s5).
BoxesOverlap:
  LD A,(IX+$01)
  SUB E
  JP Z,OverlapY
  JP C,OverlapLeft
  CP C
  JP C,OverlapY
  RET
OverlapLeft:
  NEG                     ; the box's left within the record's width
  CP (IX+$07)
  RET NC
OverlapY:
  SCF
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  JP Z,OverlapSameY
  JP C,OverlapAbove
  LD A,H
  AND A
  JP NZ,OverlapMiss
  LD A,L
  CP (IX+$08)
  RET
OverlapMiss:
  XOR A
  RET
OverlapAbove:
  LD A,H
  INC A
  JP NZ,OverlapMiss
  LD A,L
  NEG
  CP B
  RET
OverlapSameY:
  SCF
  RET

; What the bomb at (E, HL) touches: the flags of its cells and the one below,
; and the objects; into $915E
;
; The probe is 8 pixels wide from x + 8 and 16 tall from y. The cells it covers
; (1 or 2 rows, 1 or 2 columns, from ViewCells) give CellFlags bits 1 and 5;
; the row under it gives bits 1, 2 and 5. Then the records at $7B8F (the alive
; ones, +0 bit 7): with +0 bit 6 (solid) one overlapping the probe (16 x 8 box)
; sets bit 1; without bit 6, while the fall speed $93CD is not negative, one
; whose top (its +8 set to 8 + $93CD) holds the probe's bottom row sets bit 6
; and gives its y ($915F) and +$16 ($9161): a platform to stand on.
;
; The result $915E: bit 1 solid, bit 2 floor, bit 5 deadly (the bomb's code
; goes to $93B8), bit 6 an object platform. The probe's coordinates are stored
; into the instructions at $8ECC-$8ED3 and $8F10-$8F13.
;
; A platform lower than the one already found jumps to $9113 ($8EEA), the tail
; of another scan ($9090's loop): not taken in any recording (94 tests); a copy
; slip, it seems.
;
; Callers: the bomb's fall $91EB ($9222 5704, $9247 202), $9320 (5610).
; Witness: 5812 runs in 34 builds: 108 for each bomb dropped (c1, controls-*).
;
; Witness: L1 11732 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48).
ProbeGround:
  PUSH HL
  LD (ProbeSolidY+$0001),HL ; the probe's y into $8F11
  LD BC,$000F
  ADD HL,BC
  LD (ProbePlatformY+$0001),HL ; y + 15 into $8ED1
  POP HL
  LD B,$01                ; B = 1 row, 2 when y is not on a cell row
  LD A,L
  AND $07
  JP Z,ProbeRowAddress
  INC B
ProbeRowAddress:
  LD A,L                  ; HL = (y / 8) x 32: the probe's top cell row
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD A,E                  ; x + 8 into $8ED4 and $8F14
  ADD A,$08
  LD (ProbePlatformX+$0001),A
  LD (ProbeSolidX+$0001),A
  SRL E
  SRL E
  SRL E
  INC E
  LD D,$00
  ADD HL,DE
  LD DE,ViewCells             ; the cell under x + 8
  ADD HL,DE
  LD C,$00
  AND $07
  JP NZ,ProbeTwoColumns   ; x + 8 on a cell column: one column
ProbeOneColumn:
  LD D,CellFlags/256      ; bits 1 and 5 of the body's cells
  LD E,(HL)
  LD A,(DE)
  OR C
  LD C,A
  LD DE,$0020
  ADD HL,DE
  DJNZ ProbeOneColumn
  AND $22                 ; the row below: bits 1, 2 and 5
  LD C,A
  LD D,CellFlags/256
  LD E,(HL)
  LD A,(DE)
  AND $26
  OR C
  LD C,A
  JP ProbeObjects
ProbeTwoColumns:
  LD D,CellFlags/256
  LD E,(HL)
  INC HL
  LD A,(DE)
  OR C
  LD C,A
  LD E,(HL)
  LD A,(DE)
  OR C
  LD C,A
  LD DE,$001F
  ADD HL,DE
  DJNZ ProbeTwoColumns
  AND $22
  LD C,A
  LD D,CellFlags/256
  LD E,(HL)
  LD A,(DE)
  AND $26
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $26
  OR C
  LD C,A
ProbeObjects:
  LD A,C                  ; the cells' flags into $915E
  LD (CollisionFlags),A
  LD A,(DetonatorDy+$0001) ; rising (the speed's high byte negative): the bytes
                           ; at $8E9D
  AND A
  JP P,ProbeObjectsScan

; LD A,($915E) / AND $FB / LD ($915E),A: no floor bit while rising
;
; Reached from $8E9A when $93CD is negative; no recording ran it. The code
; after it ($8EA5) then adds 8 to the flags, not to the speed.
;
; Witness: L1 0 ().
ProbeRising:
  LD A,(CollisionFlags)
  AND $FB
  LD (CollisionFlags),A

; ProbeGround, continued: the objects at $7B8F
;
; A = the fall speed's high byte $93CD: the platform test's height is 8 + it.
;
; Evidence: 5812 runs in 34 builds.
;
; Witness: L1 11732 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48).
ProbeObjectsScan:
  ADD A,$08
  LD (ProbePlatformHeight+$0003),A ; into the LD (IX+8),n below
  LD HL,Entry
  LD DE,$0018
ProbeScanLoop:
  LD A,(HL)               ; alive records only (+0 bit 7)
  AND A
  JP M,ProbeScanRecord
ProbeScanNext:
  ADD HL,DE
  JP ProbeScanLoop
ProbeScanRecord:
  CP $FF                  ; $FF ends the list; bit 6: a solid object
  RET Z
  ADD A,A
  JP M,ProbeSolidObject
  LD A,(DetonatorDy+$0001) ; rising: no platform
  AND A
  JP M,ProbeScanNext
  PUSH IX
  PUSH HL
  POP IX
ProbePlatformHeight:
  LD (IX+$08),$08         ; the record's height = 8 + the fall speed (operand
                          ; set at $8EA7)
ProbePlatformY:
  LD HL,$0000             ; HL = the probe's y + 15: its bottom row (operand
                          ; set at $8E24)
ProbePlatformX:
  LD E,$00                ; E = x + 8 (operand set at $8E3A); B = 1, C = 8
  LD BC,$0108
  CALL BoxesOverlap
  JP NC,ProbeScanStep
  LD E,(IX+$02)
  LD D,(IX+$03)
  LD HL,(PlatformTop)
  OR A
  SBC HL,DE
  JP C,PlatformScanNext   ; a lower platform: into $9090's loop (not taken in
                          ; any recording)
  LD (PlatformTop),DE     ; the platform: its y and +$16, bit 6
  LD A,(IX+$16)
  LD (PlatformDx),A
  LD A,(CollisionFlags)
  OR $40
  LD (CollisionFlags),A
ProbeScanStep:
  PUSH IX                 ; IX back, the next record
  POP HL
  POP IX
  LD DE,$0018
  ADD HL,DE
  JP ProbeScanLoop
ProbeSolidObject:
  PUSH IX                 ; a 16 x 8 box against the solid object
  PUSH HL
  POP IX
ProbeSolidY:
  LD HL,$0000             ; HL = the probe's y (operand set at $8E1D)
ProbeSolidX:
  LD E,$00                ; E = x + 8 (operand set at $8E3D); B = 16, C = 8
  LD BC,$1008
  CALL BoxesOverlap
  JP NC,ProbeScanStep
  LD A,(CollisionFlags)   ; bit 1: solid
  OR $02
  LD (CollisionFlags),A
  JP ProbeScanStep
