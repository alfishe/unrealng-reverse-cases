; --------------------------------------------------------------------------------------------------------------------
; rick.asm: Rick: the body box tests, walk, jump, crawl, climb, the ride, the special surfaces, death
;
; Rick is the record RickRecord ($9BAB, 9 bytes: +1 x, +2/+3 y, +4/+5 the sprite, +6 bit 7 mirrored, +7/+8 the box 16
; x 21), moved once a pass by UpdateRick from the main loop's object step ($86A9, IX = RickRecord). x is in pixels
; from the view's left edge (0-232, the 16-pixel body is x+4..x+19); y is a 16-bit pixel count from the view's top
; with an 8-bit fraction in RickYFrac; the vertical speed RickDy is 8.8 fixed point in pixels a pass, down positive.
; Gravity adds 0.5 a pass up to 8 pixels a pass; a jump starts at -6, a bounce or launch pad at -2175/256 (about
; -8.5).
;
; The map test: TestBodyBox (standing) and TestCrawlBox (crawling) read the flag byte ($A800 + the cell number) of
; every cell the body covers in the view's cell buffer $6B00 (32 cells a row) and OR them into CollisionFlags, masked
; by where the cell lies: bit 0 a special surface (feet row only), 1 solid, 2 a floor one can jump up through (feet
; row only, dropped while rising), 3 a ladder, 4 a ladder's top, 5 deadly; then TestBoxObjects adds bit 6 (and bit 1)
; for the platform and block objects of the $7B8F list. A special surface means something else in each level: level 2
; ice, level 3 a bouncing surface, level 4 mud, level 5 a launch pad (level 1's branch never ran).
; --------------------------------------------------------------------------------------------------------------------

; Test a crawling Rick's box at (E, HL) against the map cells, then the
; platforms
;
; Input: HL = the box's top y (whole pixels, from the view's top), E = its left
; x, C = the vertical speed's high byte ($80: cells only, no objects; $FF: a
; sideways probe; negative: rising). Stores HL at BodyBoxY+1 and HL+20 (the
; feet line) at FeetLineY+1, E+4 at BodyBoxX+1 and FeetLineX+1 (the operands of
; the object tests that follow). The top row of the box only feeds
; CeilingOverCrawl (bit 1 of its 2 or 3 cells: something solid over the
; crawling Rick, so he cannot stand up); then 1 or 2 body rows (2 when y AND 7
; >= 4) and the feet row go into A, masked as in TestBodyBox but for the middle
; column of the body rows ($15: bits 0, 2, 4). 3 columns when (E+4) AND 7 is
; not 0, else 2. Ends in TestBoxObjects with A.
;
; Callers: UpdateRick ($9654, $9693) and RickMoveX ($9979), when RickCrawling
; is set. Ran 7666 times in 43 builds (c1 40, the RZX level pieces).
;
; Witness: L1 15400 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-18000-poke, rzx-l5-full, sec-l1-s8, c1).
TestCrawlBox:
  LD A,C
  EXX
  LD C,A
  EXX
  LD (BodyBoxY+$0001),HL
  LD BC,$0014
  ADD HL,BC
  LD (FeetLineY+$0001),HL
  XOR A
  SBC HL,BC
  LD A,L
  AND $07
  LD B,$01
  CP $04
  JP C,CrawlBoxRows
  INC B
CrawlBoxRows:
  LD A,L                  ; B = 1 body row, 2 when the top lies in the cell's
                          ; lower half
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD A,H
  ADD A,$6B               ; H = $6B00 / 256 + row * 32 / 256: the cell under
                          ; the box's top-left in the view buffer
  LD H,A
  LD A,E
  ADD A,$04
  LD (BodyBoxX+$0001),A
  LD (FeetLineX+$0001),A
  LD E,A
  SRL E
  SRL E
  SRL E
  LD D,$00
  ADD HL,DE
  AND $07
  JP Z,CrawlNarrowBox
  LD C,$00
  LD D,$A8
  LD E,(HL)
  INC HL
  LD A,(DE)
  AND $02
  OR C
  LD C,A
  LD E,(HL)
  INC HL
  LD A,(DE)
  AND $02
  OR C
  LD C,A
  LD E,(HL)
  LD A,(DE)
  AND $02
  OR C
  LD (CeilingOverCrawl),A
  LD DE,$001E
  ADD HL,DE
  LD C,$00
CrawlWideRowLoop:
  LD D,$A8                ; a body row of 3 cells: $22, $15, $22
  LD E,(HL)
  LD A,(DE)
  AND $22
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $15
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $22
  OR C
  LD C,A
  LD DE,$001E
  ADD HL,DE
  DJNZ CrawlWideRowLoop
  LD D,$A8                ; the feet row: $27, $3F, $27 (special surface and
                          ; the floor one jumps through count only here)
  LD E,(HL)
  LD A,(DE)
  AND $27
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $3F
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $27
  OR C
  JP TestBoxObjects
CrawlNarrowBox:
  LD C,$00                ; x+4 on a cell edge: 2 columns
  LD D,$A8
  LD E,(HL)
  LD A,(DE)
  AND $02
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $02
  OR C
  LD (CeilingOverCrawl),A
  LD DE,$001F
  ADD HL,DE
  LD C,$00
CrawlNarrowRowLoop:
  LD D,$A8                ; a body row of 2 cells: $3A each
  LD E,(HL)
  LD A,(DE)
  AND $3A
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $3A
  OR C
  LD C,A
  LD DE,$001F
  ADD HL,DE
  DJNZ CrawlNarrowRowLoop
  LD D,$A8                ; the feet row: every bit, then AND $3F
  LD E,(HL)
  LD A,(DE)
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  OR C
  AND $3F
  JP TestBoxObjects

; Non-zero while a solid cell lies over the crawling Rick's head
;
; Written by TestCrawlBox (bit 1 of the cells in the box's top row); read by
; UpdateRick through RickCrouchCheck ($97B4) and RickInAir ($986D): Rick stays
; crawling while it is set.
CeilingOverCrawl:
  DEFB $00

; Test a standing body's box at (E, HL) against the map cells, then the
; platforms
;
; Input and output as TestCrawlBox: HL = the box's top y, E = its left x, C =
; the vertical speed's high byte ($80 no objects, $FF a sideways probe,
; negative rising); out: CollisionFlags (and A) with the cells' flags,
; PlatformTop, PlatformDx, PlatformDy from TestBoxObjects. The box is 2 or 3
; body rows (3 when y AND 7 >= 4) and the feet row below them, 2 or 3 columns
; from x+4. Body rows mask the cells' flags with $22 (solid, deadly) at the
; sides and $2A (and the ladder) in the middle, or $3A each when only 2 columns
; are touched; the feet row with $27, $3F, $27 (adding the special surface and
; the floor one jumps through), or every bit.
;
; Used by Rick (UpdateRick $965E, $9699; RickMoveX $997F; ClimbLadder $9ADF;
; UpdateRide $94CB, $9550) and by the enemies ($A0DE, $A102, $A1FB, $A289): 166
; 811 runs in 65 builds, the routine every recording runs most in this range.
;
; Witness: L1 412134 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestBodyBox:
  LD A,C
  EXX
  LD C,A
  EXX
  LD (BodyBoxY+$0001),HL
  LD BC,$0014
  ADD HL,BC
  LD (FeetLineY+$0001),HL
  XOR A
  SBC HL,BC
  LD A,L
  AND $07
  LD B,$02
  CP $04
  JP C,BodyBoxRows
  INC B
BodyBoxRows:
  LD A,L                  ; B = 2 body rows, 3 when the top lies in the cell's
                          ; lower half
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD A,H
  ADD A,$6B
  LD H,A
  LD A,E
  ADD A,$04
  LD (BodyBoxX+$0001),A
  LD (FeetLineX+$0001),A
  LD E,A
  SRL E
  SRL E
  SRL E
  LD D,$00
  ADD HL,DE
  AND $07
  JP Z,BodyNarrowBox
  LD C,$00
BodyWideRowLoop:
  LD D,$A8                ; a body row of 3 cells: $22, $2A, $22
  LD E,(HL)
  LD A,(DE)
  AND $22
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $2A
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $22
  OR C
  LD C,A
  LD DE,$001E
  ADD HL,DE
  DJNZ BodyWideRowLoop
  LD D,$A8                ; the feet row: $27, $3F, $27
  LD E,(HL)
  LD A,(DE)
  AND $27
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $3F
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $27
  OR C
  JP TestBoxObjects
BodyNarrowBox:
  LD C,$00                ; x+4 on a cell edge: 2 columns
BodyNarrowRowLoop:
  LD D,$A8                ; a body row of 2 cells: $3A each
  LD E,(HL)
  LD A,(DE)
  AND $3A
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $3A
  OR C
  LD C,A
  LD DE,$001F
  ADD HL,DE
  DJNZ BodyNarrowRowLoop
  LD D,$A8                ; the feet row: every bit, then AND $3F
  LD E,(HL)
  LD A,(DE)
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  OR C
  AND $3F

; Store the cells' flags, then test the box against the platforms and blocks of
; the $7B8F list
;
; A = the cells' flags, C' = the vertical speed's high byte given to the box
; test. Stores A in CollisionFlags and returns when C' = $80. Else sets the
; platforms' tested height (SetPlatformHeight's operand) to C' + 8, so that a
; fast fall cannot pass through a platform, clears bit 2 of the flags while
; rising (C' negative), sets PlatformTop = $FFFF and PlatformDx = PlatformDy =
; 0, and walks the records at $7B8F (24 bytes each, the end a $FF byte) through
; ObjectScanLoop.
;
; Ran 174 475 times in 65 builds (callers $8FB8, $8FF5, $906A, $908E: the four
; ends of the two box tests).
;
; Witness: L1 427528 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestBoxObjects:
  LD (CollisionFlags),A
  EXX
  LD A,C
  CP $80
  RET Z
  ADD A,$08
  LD (SetPlatformHeight+$0003),A
  LD A,C
  EXX
  AND A
  JP P,ObjectScanInit
  LD A,(CollisionFlags)
  AND $FB
  LD (CollisionFlags),A
ObjectScanInit:
  LD HL,$FFFF             ; no object found yet: PlatformTop the lowest
                          ; possible, no motion carried
  LD (PlatformTop),HL
  XOR A
  LD (PlatformDx),A
  LD (PlatformDy),A
  LD HL,Entry
  LD BC,$0018

; Skip the records whose +0 has bit 7 clear (free or a plain trap or pickup)
;
; Part of TestBoxObjects: HL steps through the $7B8F records 24 bytes at a time
; (BC = 24) until one whose kind byte +0 is negative.
;
; Witness: L1 2926642 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ObjectScanLoop:
  LD A,(HL)
  AND A
  JP M,ObjectScanTest

; Step to the next 24-byte record
;
; Part of TestBoxObjects; also the way back from PlatformScanNext and
; SolidScanNext.
;
; Witness: L1 2508552 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ObjectScanNext:
  ADD HL,BC
  JP ObjectScanLoop

; A record with bit 7: the end, a block (bit 6) or a platform to stand on
;
; +0 = $FF ends the scan (RET). Bit 6 set: TestSolidObject. Else a platform:
; skipped while rising (C' negative); else its height +8 is set to C' + 8 and
; the box test $8DDF checks the line of Rick's feet (y+20, x+4, 1 high, 16
; wide) against the record (+1 x, +2/+3 y, +7 width, +8 height). On a hit whose
; top (+2/+3) is higher than PlatformTop: PlatformTop = that y,
; PlatformDx/PlatformDy = the record's +$16/+$17 (its motion, carried to what
; stands on it), CollisionFlags bit 6 set.
;
; Ran 360 933 times in 65 builds.
;
; Witness: L1 855051 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ObjectScanTest:
  CP $FF
  RET Z
  ADD A,A
  JP M,TestSolidObject
  EXX
  LD A,C
  EXX
  AND A
  JP M,ObjectScanNext
  PUSH IX
  PUSH HL
  POP IX
SetPlatformHeight:
  LD (IX+$08),$08         ; LD (IX+8),n: n = the speed's high byte + 8 (written
                          ; at $909A)
FeetLineY:
  LD HL,$0000             ; LD HL,n: n = the box's top y + 20 (written by the
                          ; box tests)
FeetLineX:
  LD E,$00                ; LD E,n: n = the box's left x + 4
  LD BC,$0110
  CALL BoxesOverlap
  JP NC,PlatformScanNext
  LD E,(IX+$02)
  LD D,(IX+$03)
  LD HL,(PlatformTop)
  OR A
  SBC HL,DE
  JP C,PlatformScanNext
  LD (PlatformTop),DE
  LD A,(IX+$16)
  LD (PlatformDx),A
  LD A,(IX+$17)
  LD (PlatformDy),A
  LD A,(CollisionFlags)
  OR $40
  LD (CollisionFlags),A
; This entry point is used by the routine at ProbeObjectsScan.
PlatformScanNext:
  PUSH IX                 ; also entered from $8EA5 with IX on the stack
  POP HL
  POP IX
  LD BC,$0018
  JP ObjectScanNext

; A block object (bits 7 and 6): test the whole body box against it
;
; The box test $8DDF with the body's box (top y, x+4, 21 high, 16 wide) against
; the record. On a hit whose top is higher than PlatformTop: PlatformTop = that
; y, no motion carried (PlatformDx = PlatformDy = 0), CollisionFlags bits 6 and
; 1 set (stands on it, and it is solid).
;
; Ran 86 440 times in 41 builds (levels 2-5 and level 1's RZX pieces: the
; levels with block objects).
;
; Witness: L1 207681 (long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-06000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s11, sec-l2-s12, sec-l3-s5, sec-l3-s7, sec-l3-s9,
; sec-l4-s1, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s5).
TestSolidObject:
  PUSH IX
  PUSH HL
  POP IX
BodyBoxY:
  LD HL,$0000             ; LD HL,n: n = the box's top y (written by the box
                          ; tests)
BodyBoxX:
  LD E,$00                ; LD E,n: n = the box's left x + 4
  LD BC,$1510
  CALL BoxesOverlap
  JP NC,SolidScanNext
  LD E,(IX+$02)
  LD D,(IX+$03)
  LD HL,(PlatformTop)
  OR A
  SBC HL,DE
  JP C,SolidScanNext
  LD (PlatformTop),DE
  XOR A
  LD (PlatformDx),A
  LD (PlatformDy),A
  LD A,(CollisionFlags)
  OR $42
  LD (CollisionFlags),A
SolidScanNext:
  PUSH IX
  POP HL
  POP IX
  LD BC,$0018
  JP ObjectScanNext

; The flags the last box test found: bit 0 special surface, 1 solid, 2 floor, 3
; ladder, 4 ladder top, 5 deadly, 6 on an object
;
; Written by TestBodyBox, TestCrawlBox and TestBoxObjects, by the detonator's
; test $8E1C and by $8EA5 / $A0A1 (bit 1); read by UpdateRick and its parts,
; UpdateRide, UpdateDetonator and the enemies ($A025, $A06E, $A0A1, $A213).
CollisionFlags:
  DEFB $00

; The top y of the highest platform or block the last box test found ($FFFF:
; none)
;
; Written by TestBoxObjects; read by UpdateRick ($9673: Rick's y = PlatformTop
; - 21) and UpdateDetonator ($9234: y = PlatformTop - 16), and by $A0A1.
PlatformTop:
  DEFW $0000

; The x motion of the platform found, carried to what stands on it (pixels a
; pass)
;
; Written by TestBoxObjects (the record's +$16); read by RickMoveX ($9941:
; added to the walk step), RickActionDone, UpdateDetonator and $A213.
PlatformDx:
  DEFB $00

; The y motion of the platform found (the record's +$17)
;
; Written by TestBoxObjects; read only by $A213 (an enemy on a platform).
PlatformDy:
  DEFB $00

  ORG $93D0

; Rick dies: the cry, a jump up and a fall off the view
;
; Returns at once while RickDying is set. Else RickDying = $FF; when $8A24 is
; not 0 (level 5's own code is running) it becomes 20; effect 10 ($7A97, the
; death sound); RickDy = -5.0 (a jump up); DeathDrift = -2 when Rick's x >= $74
; (right half), else +2 (he drifts to the middle); then the first DeathFall
; pass.
;
; Callers ($93D0 in l1q): $8C67 (an enemy touch) 18, $9668 (a deadly cell) 13,
; $93B4 (the detonator's blast) 8, $A475 (a trap) 6, $9988 (a deadly cell met
; sideways) 3, $FACB (level 5's code) 1: 65 deaths in 14 builds (c1 8, each
; control recording 4, load-l2 12, load-l3 6, the RZX pieces of level 3 and 5).
; The level 5 branch ran once (rzx-l5-20000-poke).
;
; Witness: L1 113 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2-load-l4).
KillRick:
  LD A,(RickDying)
  AND A
  RET NZ
  DEC A
  LD (RickDying),A
  LD A,(LevelHookOn)
  AND A
  JP Z,KillRickCry
  LD A,$14
  LD (LevelHookOn),A
KillRickCry:
  LD A,$0A                ; effect 10
  CALL PlayEffect
  LD HL,-5*256
  LD (RickDy),HL
  LD A,(RickX)
  SUB $74
  JP C,KillRickDriftRight
  LD A,$FE
  JP KillRickStoreDrift
KillRickDriftRight:
  LD A,$02                ; x < $74: drift right
KillRickStoreDrift:
  LD (DeathDrift),A
  JP DeathFall

; One pass of the death fall: gravity, drift, the two death sprites
;
; From KillRick, then from UpdateRick every pass while RickDying is set (863
; times). RickDy += 0.5 (no limit), the 24-bit y moves by it, x moves by
; DeathDrift; when y passes 255 (high byte not 0) DeathFallOver is set (the
; main loop $7D2D ends the life there). The sprite alternates 15 and 16 every
; two passes (RickStep AND 3, bit 1).
;
; Ran 895 times in 14 builds; DeathFallOver set 35 times.
;
; Witness: L1 1662 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2-load-l4).
DeathFall:
  LD HL,(RickDy)
  LD DE,$0080
  ADD HL,DE
  LD B,$00
  BIT 7,H
  JP Z,DeathFallStoreDy
  DEC B
DeathFallStoreDy:
  LD (RickDy),HL
  LD DE,(RickY)
  LD A,(RickYFrac)
  LD C,A
  LD A,D
  LD D,E
  LD E,C
  ADD HL,DE
  ADC A,B
  LD B,A
  LD C,L
  LD L,H
  LD H,B
  LD (RickY),HL
  LD A,C
  LD (RickYFrac),A
  LD A,(RickX)
  LD C,A
  LD A,(DeathDrift)
  ADD A,C
  LD (RickX),A
  LD A,H
  AND A
  JP Z,DeathFallFrame
  XOR A
  DEC A
  LD (DeathFallOver),A
DeathFallFrame:
  LD HL,Sprites+15*128
  LD A,(RickStep)
  INC A
  AND $03
  LD (RickStep),A
  BIT 1,A
  JP Z,DeathFallStoreSprite
  LD HL,Sprites+16*128
DeathFallStoreSprite:
  LD (RickSprite),HL
  RET

; Rick's x step a pass while he falls dead: +2 or -2
;
; Written by KillRick; read by DeathFall.
DeathDrift:
  DEFB $00

; Non-zero while Rick rides the vehicle (sprite 12): UpdateRick hands the pass
; to UpdateRide
;
; Cleared by the section exits' test $8993 and the level start ($7CAD, $7CDB,
; $7CDE); kept in RestartRide ($8A6D, $8A26). Where it is set is not in this
; range (a run: a write watch).
RideMode:
  DEFB $00

; Rick in the vehicle: thrust up and down, move 4 pixels sideways, fire with
; fire alone
;
; Gravity 0.25 a pass, the speed kept within -4.0..+4.0; neither up nor down:
; only gravity; up: -0.75 a pass (net -0.5); down: +0.5. The 24-bit y moves by
; RickDy and TestBodyBox checks the new box: solid or floor stops it (RickDy =
; 0), rising under the cell edge or landing on it ((y + 12) OR 7 - 20). Left or
; right moves x by 4 (and the facing); x below 0 sets the exit $88D3 = 1, x
; above $E8 sets 2; a solid cell snaps x as RickMoveX does. The sprite is 12.
; Fire (released between shots, one bullet at a time) calls FireBullet: no up
; key needed here.
;
; Ran 3045 times in 6 builds: rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke.
;
; Witness: L1 6090 (rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke).
UpdateRide:
  LD HL,(RickDy)
  LD DE,$0040
  ADD HL,DE
  LD A,H
  AND A
  JP M,RideThrust
  CP $04
  JP C,RideThrust
  LD HL,$0400
RideThrust:
  LD A,(Controls)         ; the up and down keys (bits 3 and 2 of $7253, active
                          ; low)
  AND $0C
  CP $0C
  JP Z,RideStoreDy
  CP $04
  JP Z,RideRise
  LD DE,$0080
  ADD HL,DE
  LD A,H
  AND A
  JP M,RideStoreDy
  CP $04
  JP C,RideStoreDy
  LD HL,$0400
  JP RideStoreDy
RideRise:
  LD DE,-192              ; up alone: -0.75 a pass, not below -4.0
  ADD HL,DE
  LD A,H
  AND A
  JP P,RideStoreDy
  CP $FC
  JP NC,RideStoreDy
  LD HL,-4*256
RideStoreDy:
  LD (RickDy),HL
  LD B,$00
  BIT 7,H
  JP Z,RideMoveY
  DEC B
RideMoveY:
  LD DE,(RickY)
  LD A,(RickYFrac)
  LD C,A
  LD A,D
  LD D,E
  LD E,C
  ADD HL,DE
  ADC A,B
  LD B,A
  LD C,L
  LD L,H
  LD H,B
  PUSH HL
  PUSH BC
  LD E,(IX+$01)
  LD A,(RickDy+$0001)
  LD C,A
  CALL TestBodyBox
  POP BC
  POP HL
  LD A,(CollisionFlags)
  AND $06
  JP Z,RideStoreY
  BIT 1,A
  JP Z,RideLand
  LD A,(RickDy+$0001)
  AND A
  JP P,RideLand
  LD A,L
  OR $07
  LD L,A
  INC HL
  LD C,$00
  LD DE,$0000
  LD (RickDy),DE
  JP RideStoreY
RideLand:
  LD BC,$000C             ; a floor under it: the feet onto the cell edge
  ADD HL,BC
  LD A,L
  OR $07
  LD L,A
  LD BC,-20
  ADD HL,BC
  LD C,$00
  LD DE,$0000
  LD (RickDy),DE
RideStoreY:
  LD (RickY),HL
  LD A,C
  LD (RickYFrac),A
  LD A,(Controls)
  AND $03
  CP $03
  JP Z,RideSprite
  CP $01
  LD A,(RickX)
  JP Z,RideLeft
  RES 7,(IX+$06)
  LD D,$04
  ADD A,D
  CP $E8
  JP C,RideTestX
  LD A,$02
  LD (ExitDirection),A
  LD A,$E8
  JP RideTestX
RideLeft:
  SET 7,(IX+$06)          ; facing left, x - 4
  LD D,$FC
  ADD A,D
  JP C,RideTestX
  LD A,$01
  LD (ExitDirection),A
  DEC A
RideTestX:
  LD E,A
  PUSH DE
  LD HL,(RickY)
  LD C,$FF
  CALL TestBodyBox
  POP DE
  LD A,(CollisionFlags)
  AND $02
  JP Z,RideStoreX
  BIT 7,D
  JP Z,RideSnapRight
  LD A,E
  ADD A,$0C
  JP RideAlignX
RideSnapRight:
  LD A,E
  ADD A,$03
RideAlignX:
  AND $F8
  SUB $04
  LD E,A
RideStoreX:
  LD (IX+$01),E
RideSprite:
  LD HL,Sprites+12*128      ; sprite 12; fire released clears FireLatch
  LD (RickSprite),HL
  LD A,(Controls)
  BIT 4,A
  JP Z,RideFire
  XOR A
  LD (FireLatch),A
  RET
RideFire:
  LD A,(FireLatch)
  AND A
  RET NZ
  LD A,(BulletRecord)
  AND A
  RET NZ
  CALL FireBullet
  RET

  ORG $95ED

; Rick's pass: death fall, ride or climb, else gravity, the vertical move and
; its test
;
; IX = RickRecord (the object step $86A9, every pass, 50 260 times in 65
; builds). RickDying: DeathFall. RideMode: UpdateRide. RickClimbing:
; ClimbLadder. Else clears RickOnGround, RickIceSlide, MudStep, IceStep,
; ShootPose and DetonatorPose, counts PunchTimer down to 0, adds the gravity
; 0.5 to RickDy (at most 8.0), moves the 24-bit y by it and tests the new box
; (TestCrawlBox when crawling, else TestBodyBox, with C = RickDy's high byte);
; then RickLandOrFall.
;
; Witness: L1 119409 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
UpdateRick:
  LD A,(RickDying)
  AND A
  JP NZ,DeathFall
  LD A,(RideMode)
  AND A
  JP NZ,UpdateRide
  LD A,(RickClimbing)
  AND A
  JP NZ,ClimbLadder
  LD HL,$0000
  LD (RickOnGround),HL
  LD (MudStep),HL
  LD (ShootPose),HL
  LD A,(PunchTimer)
  DEC A
  JP P,StorePunchTimer
  XOR A
StorePunchTimer:
  LD (PunchTimer),A
  LD HL,(RickDy)
  LD DE,$0080
  ADD HL,DE
  LD A,H
  AND A
  LD B,$FF
  JP M,RickStoreDy
  INC B
  CP $08
  JP C,RickStoreDy
  LD HL,$0800
RickStoreDy:
  LD (RickDy),HL
  LD A,H
  EX AF,AF'
  LD DE,(RickY)
  LD A,(RickYFrac)
  LD C,A
  LD A,D
  LD D,E
  LD E,C
  ADD HL,DE
  ADC A,B
  LD B,A
  LD C,L
  LD L,H
  LD H,B
  PUSH HL
  PUSH BC
  LD E,(IX+$01)
  EX AF,AF'
  LD C,A
  LD A,(RickCrawling)
  AND A
  JP Z,RickProbeStanding
  CALL TestCrawlBox
  JP RickProbeDone
RickProbeStanding:
  XOR A
  LD (RickCrawling),A
  CALL TestBodyBox
RickProbeDone:
  POP BC
  POP HL

; Deadly: die; on a platform: stand on it; else RickCellCollision
;
; Deadly cell (bit 5): KillRick. On a platform or block (bit 6): y =
; PlatformTop - 21, fraction 0, RickOnGround = $FF, and the cells at that place
; are tested again (C = $80, PlatformDx kept): deadly kills, solid or floor
; goes to RickHeadBump, else RickDy = 1.0 (standing) and on to RickStoreRestDy.
; Also the end of ClimbLadder ($9AE5).
;
; Ran 46 352 times in 62 builds.
;
; Witness: L1 111716 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
RickLandOrFall:
  LD A,(CollisionFlags)
  BIT 5,A
  JP NZ,KillRick
  BIT 6,A
  JP Z,RickCellCollision
  LD BC,-21
  LD HL,(PlatformTop)
  ADD HL,BC
  LD (RickY),HL
  XOR A
  LD (RickYFrac),A
  DEC A
  LD (RickOnGround),A
  LD A,(PlatformDx)
  PUSH AF
  LD E,(IX+$01)
  LD C,$80
  PUSH HL
  LD A,(RickCrawling)
  AND A
  JP Z,PlatformProbeStanding
  CALL TestCrawlBox
  JP PlatformProbeDone
PlatformProbeStanding:
  CALL TestBodyBox
PlatformProbeDone:
  POP HL
  POP AF
  LD (PlatformDx),A
  LD A,(CollisionFlags)
  BIT 5,A
  JP NZ,KillRick
  AND $06
  JP NZ,RickHeadBump
  LD HL,$0100
  JP RickStoreRestDy

; React to the cells: land, bump the head, start a climb down, or keep falling
;
; One-way floor (bit 2): RickLanded. No solid (bit 1 clear): RickInAir. Solid
; while rising: RickHeadBump. Solid while falling: RickLanded.
;
; Ran 43 705 times in 62 builds.
;
; Witness: L1 106422 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
RickCellCollision:
  BIT 2,A
  JP NZ,RickLanded
  BIT 1,A
  JP Z,RickInAir
  LD A,(RickDy+$0001)
  AND A
  JP P,RickLanded
; This entry point is used by the routine at RickLandOrFall.
RickHeadBump:
  LD A,(RickClimbing)     ; climbing: x onto the ladder ((x AND $F0) OR 4) when
                          ; x AND 15 < 12
  AND A
  JP Z,RickBumpSnap
  LD A,(RickX)
  LD C,A
  AND $0F
  CP $0C
  JP NC,RickBumpSnap
  LD A,C
  AND $F0
  OR $04
  LD (RickX),A
RickBumpSnap:
  LD A,L                  ; y = (y OR 7) + 1, fraction 0, RickDy = 1.0 (630
                          ; runs in 42 builds)
  OR $07
  LD L,A
  INC HL
  LD C,$00
  LD DE,$0100
  LD (RickDy),DE
  JP RickInAir
RickLanded:
  BIT 4,A                 ; a ladder's top (bit 4) with down alone, standing, x
                          ; AND 31 < 10: start climbing down
  JP Z,RickOnFloor
  LD A,(RickCrawling)
  AND A
  JP NZ,RickOnFloor
  LD A,(RickClimbing)
  AND A
  JP NZ,RickInAir
  LD A,(Controls)
  AND $10
  JP Z,RickOnFloor
  LD A,(Controls)
  BIT 2,A
  JP NZ,RickOnFloor
  LD A,(RickX)
  LD E,A
  AND $1F
  CP $0A
  JP NC,RickOnFloor
  LD A,E
  AND $F0
  OR $04
  LD (RickX),A
  XOR A
  DEC A
  LD (RickClimbing),A
  JP RickInAir
RickOnFloor:
  XOR A                   ; not climbing, on the ground; the feet onto the cell
                          ; edge ((y + 12) OR 7 - 20), the jump speed -6.0
  LD (RickClimbing),A
  DEC A
  LD (RickOnGround),A
  LD DE,$000C
  ADD HL,DE
  LD A,L
  OR $07
  LD L,A
  LD DE,-20
  ADD HL,DE
  LD (RickY),HL
  XOR A
  LD (RickYFrac),A
  LD HL,$0100
  LD A,(CollisionFlags)
  AND $01
  JP Z,RickStoreRestDy
  LD A,(Level)            ; a special surface in level 3: the bounce
  CP $03
  JP NZ,RickStoreRestDy
  LD HL,(RickDy)
  LD A,H
  CP $02
  JP C,BounceRest
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  LD DE,$0060
  ADD HL,DE
  LD (RickDy),HL
  LD HL,-2175
  JP RickCrouchCheck
BounceRest:
  LD HL,$0100             ; too slow to bounce: rest (rzx-l3-04000-poke, 23
                          ; times; the bounce itself 4 times)
  LD (RickDy),HL
  LD HL,-6*256
  JP RickCrouchCheck
; This entry point is used by the routine at RickLandOrFall.
RickStoreRestDy:
  LD (RickDy),HL          ; RickDy = HL (1.0 when standing); HL = the jump
                          ; speed -6.0; a special surface: level 1 or 5
  LD HL,-6*256
  LD A,(CollisionFlags)
  BIT 0,A
  JP Z,RickCrouchCheck
  LD A,(Level)
  CP $01
  JP NZ,LaunchPadLevel5

; level 1's special surface, the jump speed -2.0
;
; HL = -2.0 (the speed an up key would give), then RickCrouchCheck. Not
; executed in any recording: level 1's cell flags have bit 0 in one cell kind
; only. Kept as bytes for the reason given at BonusRunOut.
;
; Witness: L1 0 ().
WeakJumpLevel1:
  LD HL,$FE00             ; LD HL,-2*256
  JP RickCrouchCheck      ; JP RickCrouchCheck

; Level 5's special surface throws Rick up at -2175/256 a pass
;
; Level 5: RickDy = -2175/256 (about -8.5), without a key, then RickWalk. Other
; levels (2, 4): RickCrouchCheck with the jump speed -6.0. Ran 719 times in 10
; builds (levels 2 and 4 mostly); the launch 5 times (rzx-l5-16000-poke).
;
; Witness: L1 4062 (long-l4, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-08000-poke, rzx-l2-14000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-16000-poke, rzx-l5-16000-poke,
; sec-l4-s1, sec-l4-s6).
LaunchPadLevel5:
  CP $05
  JP NZ,RickCrouchCheck
  LD HL,-2175
  LD (RickDy),HL
  JP RickWalk
; This entry point is used by the routines at RickCellCollision and
; WeakJumpLevel1.
RickCrouchCheck:
  LD A,(RickCrawling)     ; crawling: stay down while CeilingOverCrawl, else
                          ; stand up and look at the down key again
  AND A
  JP Z,RickReadJump
  LD A,(CeilingOverCrawl)
  AND A
  JP NZ,RickWalk
  XOR A
  LD (RickCrawling),A
  LD A,(Controls)
  JP RickCrouchKey
RickReadJump:
  LD A,(Controls)         ; fire held: RickFireActions; up: jump (RickDy = HL),
                          ; or grab a ladder (bit 3, no floor bit 2)
  BIT 4,A
  JP Z,RickFireActions
  LD C,A
  XOR A
  LD (PunchKeys),A
  LD (PunchTimer),A
  LD A,C
  BIT 3,A
  JP NZ,RickCrouchKey
  LD (RickDy),HL
  LD A,(CollisionFlags)
  BIT 2,A
  JP NZ,RickWalk
  BIT 3,A
  JP Z,RickWalk
  LD A,$FF
  LD (RickClimbing),A
  JP RickWalk
RickCrouchKey:
  BIT 2,A                 ; down held: crawl
  JP NZ,RickWalk
  XOR A
  DEC A
  LD (RickCrawling),A
  JP RickWalk
RickFireActions:
  BIT 3,A                 ; fire held: up shoots (RickShootUp), down drops a
                          ; detonator, left or right punches
  JP Z,RickShootUp
  EX AF,AF'
  XOR A
  LD (FireLatch),A
  EX AF,AF'
  BIT 2,A
  JP Z,DropDetonator
  AND $03
  CP $03
  JP NZ,PunchStart
  XOR A
  LD (PunchKeys),A
  LD (PunchTimer),A
  JP RickWalk
PunchStart:
  LD C,A                  ; a new punch: PunchKeys, PunchTimer 10, the facing,
                          ; the punch's x and y
  LD A,(PunchKeys)
  CP C
  JP Z,RickActionDone
  LD A,C
  LD (PunchKeys),A
  LD A,$0A
  LD (PunchTimer),A
  LD A,C
  CP $02
  JP Z,PunchRight
  LD A,$80
  LD (RickFacing),A
  LD A,(RickX)
  LD (PunchX),A
  JP PunchStoreY
PunchRight:
  XOR A                   ; facing right: PunchX = x + 24
  LD (RickFacing),A
  LD A,(RickX)
  ADD A,$18
  LD (PunchX),A
PunchStoreY:
  LD HL,(RickY)           ; PunchY = y + 8
  LD BC,$0008
  ADD HL,BC
  LD (PunchY),HL
  JP RickActionDone

; Store the new y; stand up when the ceiling allows; grab a ladder with up or
; down
;
; Ran 13 698 times in 61 builds.
;
; Witness: L1 27940 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke,
; rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l3-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
RickInAir:
  LD (RickY),HL
  LD A,C
  LD (RickYFrac),A
  LD A,(RickCrawling)
  AND A
  JP Z,RickGrabLadder
  LD A,(CeilingOverCrawl)
  AND A
  JP NZ,RickGrabLadder
  XOR A
  LD (RickCrawling),A
RickGrabLadder:
  LD A,(CollisionFlags)   ; a ladder cell (bit 3) with up or down: RickClimbing
                          ; = $FF
  BIT 3,A
  JP Z,RickWalk
  LD A,(Controls)
  AND $0C
  CP $0C
  JP Z,RickWalk
  XOR A
  DEC A
  LD (RickClimbing),A

; Leave a climb without a ladder; the sideways keys and the special surfaces
;
; Climbing with no ladder cell (bit 3) left: the climb ends, and while rising
; RickDy = -2.0 (a hop off the ladder's top, 33 times). Left: facing left, step
; -2; right: facing right, step +2; level 4's special surface (mud) makes the
; step 1 (MudStep), level 2's (ice) speeds the walk animation (IceStep = 2).
; Neither key: RickNoWalk.
;
; Ran 45 590 times in 62 builds; the mud branch 34 + 253 times (level 4), the
; ice 133 + 104 (level 2).
;
; Witness: L1 110207 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
RickWalk:
  LD A,(RickClimbing)
  AND A
  JP Z,RickWalkKeys
  LD A,(CollisionFlags)
  AND $08
  JP NZ,RickWalkKeys
  XOR A
  LD (RickClimbing),A
  LD A,(RickDy+$0001)
  AND A
  JP P,RickWalkKeys
  LD HL,-2*256
  LD (RickDy),HL
RickWalkKeys:
  LD A,(Controls)         ; bits 0 (right) and 1 (left) of $7253, active low
  AND $03
  CP $01
  JP NZ,WalkRightKey
  LD A,$80
  LD (RickFacing),A
  LD C,$FE
  LD A,(CollisionFlags)
  AND $01
  JP Z,RickMoveX
  LD A,(Level)
  CP $04
  JP NZ,WalkLeftIce
  LD A,$01
  LD (MudStep),A
  LD C,$FF
  JP RickMoveX
WalkLeftIce:
  CP $02
  JP NZ,RickMoveX
  LD A,$02
  LD (IceStep),A
  JP RickMoveX
WalkRightKey:
  CP $02
  JP NZ,RickNoWalk
  LD A,$00
  LD (RickFacing),A
  LD C,$02
  LD A,(CollisionFlags)
  AND $01
  JP Z,RickMoveX
  LD A,(Level)
  CP $04
  JP NZ,WalkRightIce
  LD A,$01
  LD (MudStep),A
  LD C,$01
  JP RickMoveX
WalkRightIce:
  CP $02
  JP NZ,RickMoveX
  LD A,$02
  LD (IceStep),A
  JP RickMoveX
; This entry point is used by the routine at RickActionDone.
RickNoWalk:
  LD A,$FF                ; standing (RickStep = $FF); on level 2's ice Rick
                          ; slides 2 pixels a pass the way he faces
                          ; (RickIceSlide)
  LD (RickStep),A
  LD C,$00
  LD A,(CollisionFlags)
  AND $01
  JP Z,RickMoveX
  LD A,(Level)
  CP $02
  JP NZ,RickMoveX
  LD A,$FF
  LD (RickIceSlide),A
  LD C,$02
  LD A,(RickFacing)
  AND A
  JP P,RickMoveX
  LD C,$FE

; Move x by the step plus PlatformDx; the view's side edges; walls and deadly
; cells
;
; x + step: below 0 sets x = 0 and the exit $88D3 = 1 (to the section on the
; left), above $E8 sets x = $E8 and $88D3 = 2. The box test (C = $FF) at the
; new x: deadly kills (KillRick from $9988); solid snaps x to the cell's edge
; ((x + 12) AND $F8 - 4 going left, (x + 3) AND $F8 - 4 going right); else x is
; stored, and a climb ends where no ladder cell is left.
;
; Ran 45 592 times in 62 builds; the left edge 1230 times, the right edge 33.
;
; Witness: L1 110211 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
RickMoveX:
  LD A,(PlatformDx)
  ADD A,C
  LD C,A
  LD A,(IX+$01)
  BIT 7,C
  JP Z,MoveRightEdge
  ADD A,C
  LD E,A
  JP C,MoveXProbe
  LD A,$01
  LD (ExitDirection),A
  LD E,$00
  JP MoveXProbe
MoveRightEdge:
  ADD A,C
  LD E,A
  CP $E9
  JP C,MoveXProbe
  LD A,$02
  LD (ExitDirection),A
  LD E,$E8
MoveXProbe:
  LD D,C
  PUSH DE
  LD HL,(RickY)
  LD C,$FF
  LD A,(RickCrawling)
  AND A
  JP Z,MoveXProbeStanding
  CALL TestCrawlBox
  JP MoveXProbed
MoveXProbeStanding:
  CALL TestBodyBox
MoveXProbed:
  POP DE
  LD A,(CollisionFlags)
  BIT 5,A
  JP NZ,KillRick
  AND $02
  JP Z,MoveXStore
  LD A,D
  AND A
  JP P,MoveXSnapRight
  LD A,E
  ADD A,$0C
  AND $F8
  SUB $04
  LD (IX+$01),A
  JP PickRickSprite
MoveXSnapRight:
  LD A,E
  ADD A,$03
  AND $F8
  SUB $04
  LD (IX+$01),A
  JP PickRickSprite
MoveXStore:
  LD (IX+$01),E
  LD A,(RickClimbing)
  AND A
  JP Z,PickRickSprite
  LD A,(CollisionFlags)
  BIT 3,A
  JP NZ,PickRickSprite
  XOR A
  LD (RickClimbing),A

; Choose Rick's sprite from his state
;
; Climbing: 13 or 14 by (x XOR y) bit 2. In the air: 8 (crawling: the crawl
; frames). On the ground: punching 1, or 10 while PunchTimer runs (the stick
; out); shooting 9; a detonator dropped: 0, or 11 while DetonatorDx is not 0 (a
; throw); sliding on ice 0; else RickWalkCycle. The address goes to RickSprite.
;
; Ran 46 336 times in 62 builds.
;
; Witness: L1 111682 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
PickRickSprite:
  LD A,(RickClimbing)
  AND A
  JP Z,SpriteOnGround
  LD HL,Sprites+13*128
  LD A,(RickX)
  LD C,A
  LD A,(RickY)
  XOR C
  AND $04
  JP Z,ClimbSpriteStore
  LD HL,Sprites+14*128
ClimbSpriteStore:
  LD (RickSprite),HL
  RET
SpriteOnGround:
  LD A,(RickOnGround)
  AND A
  JP NZ,SpritePunch
  LD A,(RickCrawling)
  AND A
  JP NZ,SpriteStand
  LD HL,Sprites+8*128
  LD (RickSprite),HL
  RET
SpritePunch:
  LD A,(PunchKeys)
  AND A
  JP Z,SpriteShoot
  LD HL,Sprites+1*128
  LD A,(PunchTimer)
  AND A
  JP Z,SpritePunchStore
  LD HL,Sprites+10*128
SpritePunchStore:
  LD (RickSprite),HL
  RET
SpriteShoot:
  LD A,(ShootPose)
  AND A
  JP Z,SpriteDetonator
  LD HL,Sprites+9*128
  LD (RickSprite),HL
  RET
SpriteDetonator:
  LD A,(DetonatorPose)
  AND A
  JP Z,SpriteIceSlide
  LD HL,(DetonatorDx)
  LD A,H
  OR L
  JP NZ,SpriteThrow
  LD HL,Sprites
  LD (RickSprite),HL
  RET
SpriteThrow:
  LD HL,Sprites+11*128      ; 39 runs in 4 builds (levels 4 and 5)
  LD (RickSprite),HL
  RET
SpriteIceSlide:
  LD A,(RickIceSlide)
  AND A
  JP Z,SpriteStand
  LD HL,Sprites
  LD (RickSprite),HL
  RET
SpriteStand:
  LD A,(RickStep)         ; RickStep = $FF (no key): sprite 0, or 6 crawling
  INC A
  JP NZ,SpriteWalkCycle
  LD (RickStep),A
  LD HL,Sprites
  LD A,(RickCrawling)
  AND A
  JP Z,SpriteStandStore
  LD HL,Sprites+6*128
SpriteStandStore:
  LD (RickSprite),HL
  RET
SpriteWalkCycle:
  LD HL,WalkFrames        ; RickStep += 2 (MudStep 1, IceStep + 2 = 4): 20
                          ; steps of 5 walk frames, 8 of 2 crawl frames
  LD B,$14
  LD A,(RickCrawling)
  AND A
  JP Z,WalkStepMud
  LD HL,CrawlFrames
  LD B,$08
WalkStepMud:
  LD A,(MudStep)
  AND A
  JP NZ,WalkStepAdd
  LD A,(IceStep)
  ADD A,$02
WalkStepAdd:
  LD C,A
  LD A,(RickStep)
  ADD A,C
  CP B
  JP C,WalkFrameStore
  XOR A
WalkFrameStore:
  LD (RickStep),A         ; effect 0 (a footstep) every 8 steps
  SRL A
  AND $0E
  LD C,A
  LD B,$00
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (RickSprite),DE
  LD A,(RickStep)
  AND $07
  RET NZ
  LD A,$00
  CALL PlayEffect
  RET

; The walk's sprites by RickStep / 4: 5, 4, 3, 2, 1; then the crawl's two: 6, 7
;
; Read by PickRickSprite (RickWalkCycle): HL = WalkFrames (20 steps) or
; CrawlFrames (8 steps), the word (RickStep / 2) AND $0E.
WalkFrames:
  INCBIN "res/tables/rick-walk-frames.bin",$0000,10
CrawlFrames:
  INCBIN "res/tables/rick-walk-frames.bin",$000A,4

; Climb: up or down 2 pixels a pass on an even y, then the common tests
;
; y's lowest bit cleared; up: -2; down alone: +2; neither: 0; RickDy = that
; step (its sign is all the box test reads). TestBodyBox with C = the step's
; low byte (+2 or -2), then RickLandOrFall (deadly, platforms, landing at the
; foot) and the rest of the pass.
;
; Ran 3737 times in 38 builds.
;
; Witness: L1 7474 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full).
ClimbLadder:
  LD HL,(RickY)
  LD A,L
  AND $FE
  LD L,A
  LD BC,$0000
  LD A,(Controls)
  AND $0C
  CP $0C
  JP Z,ClimbStoreStep
  LD C,$02
  CP $08
  JP Z,ClimbStoreStep
  LD BC,-2
ClimbStoreStep:
  LD (RickDy),BC
  ADD HL,BC
  LD A,(RickX)
  LD E,A
  PUSH HL
  CALL TestBodyBox
  POP HL
  LD C,$00
  JP RickLandOrFall

  ORG $9B07

; After a fire action: carried by a platform, slide on ice, or only the sprite
;
; PlatformDx not 0: RickNoWalk (the platform carries him). On level 2's special
; surface (ice): RickWalk. Else PickRickSprite: no sideways step while an
; action key is held.
;
; Ran 767 times in 52 builds.
;
; Witness: L1 1519 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke,
; rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48).
RickActionDone:
  LD A,(PlatformDx)
  AND A
  JP NZ,RickNoWalk
  LD A,(CollisionFlags)
  AND $01
  JP Z,PickRickSprite
  LD A,(Level)
  CP $02
  JP Z,RickWalk
  JP PickRickSprite

  ORG $9B8C

; Rick's state at the section's entry, where a life restarts; +7 the section
; Rick is in
;
; Written by the section setup $8A6D (Rick's x and y, his crawl, climb, ride
; and facing, the view's top row, the section); read back by the restart after
; a death ($8A26).
RestartPoint:
RestartX:
  DEFB $00
RestartY:
  DEFB $00,$00            ; 2 bytes
RestartCrawl:
  DEFB $00
RestartClimb:
  DEFB $00
RestartRide:
  DEFB $00
RestartTopRow:
  DEFB $00                ; the view's top row in the section ($88CF)
RickSection:
  DEFB $00                ; the section Rick is in (0 to the level's count - 1)
RestartFacing:
  DEFB $00

; Rick's vertical speed, 8.8 pixels a pass, down positive
;
; Gravity +0.5 a pass up to 8.0 (UpdateRick), -6.0 a jump, -5.0 the death's
; jump, 1.0 standing, -2175/256 a launch. Written by UpdateRick and its parts,
; KillRick, DeathFall, UpdateRide, ClimbLadder (the climb step), $80B5, $83CE,
; $8A26; read by the same and $83CE.
RickDy:
  DEFW $0000

; The fraction of RickY (the 24-bit y is RickY:RickYFrac)
RickYFrac:
  DEFB $00

; $FF while Rick crawls (down held, or a ceiling over him)
;
; Read by the box test $8D53 too (a lower box for the enemies' touch).
RickCrawling:
  DEFB $00

; $FF while Rick is on a ladder: UpdateRick hands the pass to ClimbLadder
RickClimbing:
  DEFB $00

; The walk animation's step (0-19 walking, 0-7 crawling, $FF standing);
; DeathFall's frame counter
RickStep:
  DEFB $00

; $FF when the dead Rick has fallen below the view
;
; Written by DeathFall; read by the main loop ($7D2D) and the level start
; ($7CAD, $7CDB, $7CDE); cleared by $8A26, $8A6D.
DeathFallOver:
  DEFB $00

; $FF from KillRick until the restart
;
; Read by UpdateRick, KillRick, the main loop and the enemies and traps ($A2F7,
; $A43B, $A528, $A69F, $A6E7: they leave a dying Rick alone).
RickDying:
  DEFB $00

; $FF when the pass ended on a floor or a platform (cleared every pass)
RickOnGround:
  DEFB $00

; $FF while Rick slides on level 2's ice with no key (sprite 0)
RickIceSlide:
  DEFB $00

; 1 on level 4's mud: the walk step and the animation step are 1
MudStep:
  DEFB $00

; 2 on level 2's ice: the animation steps 4 instead of 2
IceStep:
  DEFB $00

; $FF on a pass with fire and up held (sprite 9)
ShootPose:
  DEFB $00

; $FF on a pass with fire and down held (sprite 0 or 11)
DetonatorPose:
  DEFB $00

; Counts 10 passes down from a punch's start: the stick shows (sprite 10) while
; not 0
;
; Read by $8BF3, $A69F, $A6E7 (the punch against enemies and trigger boxes).
PunchTimer:
  DEFB $00

; The sideways keys of the punch in progress (1 left, 2 right, $7253 AND 3); 0
; none
PunchKeys:
  DEFB $00

; The punch's x: Rick's x, or x + 24 facing right
;
; Written by RickFireActions; read by $8C6C.
PunchX:
  DEFB $00

; The punch's y: Rick's y + 8
;
; Written by RickFireActions; read by $8C6C.
PunchY:
  DEFW $0000

; $FF after a shot until fire is released (or held with no up)
FireLatch:
  DEFB $00

; $FF while the countdown bonus runs (map kind $78 starts it, $7C ends it,
; $9C97)
BonusRunning:
  DEFB $00

; CountBonus's count of 25 passes
BonusPrescaler:
  DEFB $00

; Rick: +0 state, +1 x, +2/+3 y, +4/+5 sprite, +6 bit 7 mirrored, +7 width 16,
; +8 height 21
;
; +0 is 1 in the image and 0 after every section setup ($8A6D); read by $85FA.
; The sprite composer $7329 reads the whole record. IX = RickRecord in
; UpdateRick.
RickRecord:
  DEFB $01
RickX:
  DEFB $80                ; pixels from the view's left, 0-$E8
RickY:
  DEFB $20,$00            ; 2 bytes, pixels from the view's top
RickSprite:
  DEFB $6D,$C2            ; 2 bytes, the sprite's address
RickFacing:
  DEFB $00                ; bit 7: facing left (the sprite mirrored)
RickWidth:
  DEFB $10
RickHeight:
  DEFB $15

; The bullet: +0 active, +1 x, +2/+3 y, +4/+5 sprite 17, +6 the step (+8 or -8,
; bit 7 mirrors)
;
; Written by FireBullet, MoveBullet, the object step $865D, the scroll's shift
; $9E31, FreeAllObjects and the enemies' test $8BF3 (a hit ends it); read by
; the composer $7329 and the traps and pickups ($A2F7, $A528, $A69F).
BulletRecord:
  DEFB $00
BulletX:
  DEFB $80
BulletY:
  DEFB $20,$00            ; 2 bytes
BulletSprite:
  DEFB $ED,$CA            ; 2 bytes
BulletDx:
  DEFB $00
BulletWidth:
  DEFB $10
BulletHeight:
  DEFB $15

; The detonator: +0 active, +1 x, +2/+3 y, +4/+5 sprite, +6 flags, +7, +8, then
; the fuse
;
; Written by DropDetonator, UpdateDetonator, BurnFuse, $9E31 and
; FreeAllObjects; read by the composer $7329, $85FA and the traps and enemies
; ($A2F7, $A528, $A69F: the blast).
DetonatorRecord:
  DEFB $00
DetonatorX:
  DEFB $80
DetonatorY:
  DEFB $20,$00            ; 2 bytes
DetonatorSprite:
  DEFB $6D,$CB            ; 2 bytes
DetonatorFlags:
  DEFB $00
DetonatorWidth:
  DEFB $10
DetonatorHeight:
  DEFB $15
DetonatorFuse:
  DEFB $00                ; 64 at the drop; the blast at 1-10
