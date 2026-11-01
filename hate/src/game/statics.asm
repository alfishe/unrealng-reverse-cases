; Static objects into the playfield buffer
;
; Called first by the sprite pass $D9D6. Walks the list at $C99E (record
; addresses, $FF ends it) that $EFDC builds of the visible records of types 14
; and 15, the launch pads and the dishes. A record is drawn only while its
; column +B is $20-$23, the strips at the far edge of the buffer: 4, 3, 2 or 1
; strips of a masked sprite (14 mask and data byte pairs a strip; at column $20
; with phase 0, 3 strips). The target is in the playfield buffer $8000-$BFFF
; (high byte from the scroll offset $C32E + 2 * column + $78), the sprite from
; the pointer table at $C300 + (+8), stepped $70 bytes per phase (+9). So these
; objects are stamped into the course picture as it scrolls in, not drawn per
; pass. docs/06-rendering.md 6.6.
StampStatics:
  LD HL,SegmentRows+$00B4 ; the list of types 14-15, made by $EFDC
  PUSH HL
l_EA3C:
  POP HL
  LD A,(HL)
  LD IXL,A
  INC L
  LD A,(HL)
  INC L
  CP $FF                  ; $FF: the end
  RET Z
  LD IXH,A
  PUSH HL
  LD E,(IX+$0A)           ; +A plus the height: the line in the strip
  LD D,(IX+$0B)
  LD A,(IX+$04)
  ADD A,E
  LD E,A
  LD B,$04
  LD A,D                  ; only columns $20-$23, the edge being drawn
  CP $20
  JR C,l_EA3C
  JR Z,l_EA74
  CP $21
  JR NZ,l_EA64
  DEC B
  JR l_EA7E
l_EA64:
  CP $22
  JR NZ,l_EA6C
  LD B,$02
  JR l_EA7E
l_EA6C:
  CP $23
  JR NZ,l_EA3C
  LD B,$01
  JR l_EA7E
l_EA74:
  LD A,(IX+$09)           ; column $20: 4 strips, 3 with phase 0
  AND A
  JR NZ,l_EA7E
  DEC B
  JP Z,l_EA3C
l_EA7E:
  LD A,(ScrollPage)       ; the buffer row of the column
  ADD A,D
  ADD A,D
  ADD A,$78
  LD D,A
  RES 6,D
  SET 7,D
  LD A,B
  EX AF,AF'
  LD L,(IX+$08)           ; the sprite: pointer table at $C300 + (+8)
  LD H,$C3
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  LD A,(IX+$09)           ; + $70 per phase
  DEC A
  AND $03
  JR Z,l_EAA4
  LD BC,$0070
l_EAA0:
  ADD HL,BC
  DEC A
  JR NZ,l_EAA0
l_EAA4:
  EX AF,AF'
  LD C,A
l_EAA6:
  PUSH DE                 ; one strip: 14 bytes masked in (AND mask, OR data)
  LD B,$03
l_EAA9:
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  DJNZ l_EAA9
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  POP DE
  DEC E
  DEC E
  DEC E
  DEC E
  INC D                   ; the next strip: 2 rows of the buffer on, wrapping
                          ; in $8000-$BFFF
  INC D
  RES 6,D
  DEC C
  JR NZ,l_EAA6
  JP l_EA3C

; The moving objects into the playfield buffer
;
; Reached by a jump from $DDE7 after the strips under the sprites were saved.
; Walks the sprite list at $FF00 that $D9D6 rebuilds each pass: 6-byte entries
; of kind, strip count, buffer address and sprite address, $FF ends it (the
; pointer is kept at $DD68). Each strip is masked in (AND mask, OR data): 21
; bytes for kinds 0-3, 17 for kinds 4-10, 13 for 11 and up, then 2 rows on in
; the buffer, wrapping inside $8000-$BFFF. docs/06-rendering.md 6.6.
DrawSprites:
  LD HL,SpriteListArea    ; the sprite list
  LD (SpriteListPtr),HL
l_EAE9:
  LD HL,(SpriteListPtr)
  LD A,(HL)               ; kind; $FF ends the list
  CP $FF
  RET Z
  EX AF,AF'
  INC L                   ; strip count, buffer address, sprite address
  LD A,(HL)
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD (SpriteListPtr),HL
  LD H,B
  LD L,C
  LD C,A
  EX AF,AF'
  CP $04
  JR C,DrawSpriteTall
  CP $0B
  JP C,DrawSpriteMid
  JP DrawSpriteShort
DrawSpriteTall:
  PUSH DE                 ; kinds 0-3: 21 bytes a strip
  LD B,$05
l_EB12:
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  DJNZ l_EB12
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  POP DE
  DEC E
  DEC E
  DEC E
  DEC E
  INC D
  INC D
  RES 6,D
  DEC C
  JR NZ,DrawSpriteTall
  JP l_EAE9
DrawSpriteMid:
  PUSH DE                 ; kinds 4-10: 17 bytes a strip
  LD B,$04
l_EB48:
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  DJNZ l_EB48
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  POP DE
  DEC E
  DEC E
  DEC E
  DEC E
  INC D
  INC D
  RES 6,D
  DEC C
  JR NZ,DrawSpriteMid
  JP l_EAE9
DrawSpriteShort:
  PUSH DE                 ; kinds 11 and up: 13 bytes a strip
  LD B,$04
l_EB7E:
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  DJNZ l_EB7E
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  POP DE
  DEC E
  DEC E
  DEC E
  DEC E
  INC D
  INC D
  RES 6,D
  DEC C
  JR NZ,DrawSpriteShort
  JP l_EAE9
