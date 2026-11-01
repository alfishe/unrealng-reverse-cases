; Shadow and sprite lists of the visible objects, the strips under them saved
;
; Step 7 of the pass (docs/04-game-loop.md 4.3), after $EFA5 has put the
; visible records in the list at $6500 (4-byte entries: depth, column, record
; address; bit 6 of the first byte ends it). Pads and dishes (types 14-15) are
; not in it; $EA38 draws them first from their own list at $C99E.
;
; The list is walked twice. The first walk (ShadowListLoop) makes the shadow
; list at $FE64, each object placed at the height of the ground under it; the
; second (SpriteListBuild) makes the sprite list at $FF00, each object at its
; own height (+4). For every entry the playfield strips it will cover are first
; copied to the save area at $F800, so that $DD6C can put the course back after
; the blit. The objects are drawn into the playfield buffer $8000-$BFFF, not
; onto the screen: shadows and sprites by $DDE7 (step 8), before the blit $D35E
; copies the buffer to the screen (docs/06-rendering.md 6.3, 6.6).
BuildSpriteLists:
  CALL StampStatics       ; pads and dishes (list $C99E)
  LD HL,SpriteSaveBuffer  ; the save area starts again at $F800
  LD (SaveAreaPtr),HL
  LD HL,SpriteListArea    ; the sprite list $FF00, empty
  LD (SpriteListPtr),HL
  LD (HL),$FF
  LD HL,Im2Table+$0064    ; the shadow list $FE64, empty
  LD (ShadowListPtr),HL
  LD (HL),$FF
  LD HL,SpriteScratch     ; the visible records, from $EFA5
  PUSH HL

; Shadow list: the next visible record
;
; One entry of $6500 a time: IX = the record. The column (+B) decides how many
; strips show: an object 4 columns or more inside the window has all its strips
; (4 for types 0-3, 3 for 4-10, 2 for 11-13); at either edge the strips that
; fall outside are dropped, and on the left the start moves on by whole strips
; (DE + $FC a strip: the next column, 4 lines lower in the buffer) while C
; counts the skipped mask bytes. Phase (+9) 0 or 2 drops one more strip. The
; line in the strip is +A plus the ground height from the profile at $6000
; (bits 0-4). The entry is finished at ShadowListAdd.
ShadowListLoop:
  POP HL
  BIT 6,(HL)              ; bit 6: the end of the list
  JR Z,l_DA00
  LD HL,(ShadowListPtr)
  LD (HL),$FF             ; end the shadow list, go on with the sprites
  JP SpriteListBuild
l_DA00:
  INC L                   ; IX = the record
  INC L
  LD A,(HL)
  LD IXL,A
  INC L
  LD A,(HL)
  LD IXH,A
  INC L
  PUSH HL
  LD A,(IX+$00)           ; type; a dying record (bit 5 set) fails every
                          ; compare and gets no shadow
  CP $04
  JR C,ShadowBig
  CP $0B
  JP C,ShadowMid
  CP $0E
  JP C,ShadowSmall
  JR ShadowListLoop       ; types 14 and up: not here
ShadowBig:
  EX AF,AF'               ; types 0-3: 4 strips of 17 lines
  LD L,(IX+$01)
  LD H,(IX+$02)
  SRL H
  RR L
  LD BC,$5FF6             ; the profile under the record: $5FF6 + position / 2
  ADD HL,BC
  LD DE,(ShadowListPtr)
  EX DE,HL
  INC L
  INC L
  LD (HL),E               ; entry +2, +3: the profile address
  INC L
  LD (HL),D
  EX DE,HL
  LD E,(IX+$0A)           ; +A: the line in the strip, +B: the column
  LD D,(IX+$0B)
  LD A,(HL)
  AND $1F                 ; the ground height
  ADD A,E
  LD E,A
  LD C,$00
  LD B,$04
  LD A,D
  SUB $04                 ; column - 4 = the screen column
  CP $1D                  ; 0-28: every strip shows
  JR C,l_DA92
  JR NZ,l_DA53
  DEC B
  JR l_DA9C
l_DA53:
  CP $1E
  JR NZ,l_DA5B
  LD B,$02
  JR l_DA9C
l_DA5B:
  CP $1F
  JR NZ,l_DA63
  LD B,$01
  JR l_DA9C
l_DA63:
  CP $FD                  ; columns -3 to -1: the first strips are off the left
                          ; edge
  JR NZ,l_DA73
  EX DE,HL
  LD BC,$02F4
  ADD HL,BC
  EX DE,HL
  LD C,$33                ; C = the mask bytes skipped (17 a strip)
  LD B,$01
  JR l_DA92
l_DA73:
  CP $FE
  JR NZ,l_DA83
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD C,$22
  LD B,$02
  JR l_DA92
l_DA83:
  CP $FF
  JP NZ,ShadowListLoop
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD C,$11
  LD B,$03
l_DA92:
  LD A,(IX+$09)           ; phase 0: one strip fewer
  AND A
  JR NZ,l_DA9C
  DEC B
  JP Z,ShadowListLoop
l_DA9C:
  LD A,$11                ; 17 lines a strip
  JP ShadowListAdd
ShadowMid:
  EX AF,AF'               ; types 4-10: 3 strips of 11 lines
  LD L,(IX+$01)
  LD H,(IX+$02)
  SRL H
  RR L
  LD BC,$5FF7             ; the profile one byte further on
  ADD HL,BC
  LD DE,(ShadowListPtr)
  EX DE,HL
  INC L
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  EX DE,HL
  LD E,(IX+$0A)
  LD D,(IX+$0B)
  LD A,(HL)
  AND $1F
  ADD A,E
  LD E,A
  INC E
  INC E
  LD A,(IX+$09)           ; phase 2 and 3: one column on, 4 lines lower
  CP $02
  JR C,l_DAD4
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
l_DAD4:
  LD C,$00
  LD B,$03
  LD A,D
  SUB $04
  CP $1E
  JR C,l_DB0B
  JR NZ,l_DAE4
  DEC B
  JR l_DB16
l_DAE4:
  CP $1F
  JR NZ,l_DAEC
  LD B,$01
  JR l_DB16
l_DAEC:
  CP $FE
  JR NZ,l_DAFC
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD C,$16
  LD B,$01
  JR l_DB0B
l_DAFC:
  CP $FF
  JP NZ,ShadowListLoop
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD C,$0B
  LD B,$02
l_DB0B:
  LD A,(IX+$09)           ; phase 2: one strip fewer
  CP $02
  JR NZ,l_DB16
  DEC B
  JP Z,ShadowListLoop
l_DB16:
  LD A,$0B                ; 11 lines a strip
  JP ShadowListAdd
ShadowSmall:
  EX AF,AF'               ; types 11-13: 2 strips of 4 lines
  LD L,(IX+$01)
  LD H,(IX+$02)
  SRL H
  RR L
  LD BC,$5FF8             ; the profile two bytes further on
  ADD HL,BC
  LD DE,(ShadowListPtr)
  EX DE,HL
  INC L
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  EX DE,HL
  LD E,(IX+$0A)
  LD D,(IX+$0B)
  LD A,(HL)
  AND $1F
  ADD A,E
  LD E,A
  INC D                   ; one column on
  LD C,$00
  LD B,$02
  LD A,D
  SUB $04
  CP $1F
  JR C,l_DB60
  JR NZ,l_DB51
  DEC B
  JR l_DB6A
l_DB51:
  CP $FF
  JP NZ,ShadowListLoop
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD C,$04
  LD B,$01
l_DB60:
  LD A,(IX+$09)           ; phase 0: one strip fewer
  AND A
  JR NZ,l_DB6A
  DEC B
  JP Z,ShadowListLoop
l_DB6A:
  LD A,$04                ; 4 lines a strip

; Finish a shadow entry, save the strips under it
;
; In: A = lines a strip, A' = type, B = strips, C = the mask bytes skipped, D =
; column, E = line. The column becomes the playfield page through the scroll
; state $C32E, as the blit maps columns (docs/06-rendering.md 6.2): page $80 +
; ($C32E + 2 x (column - 4)) mod 64. The 8-byte entry at ShadowListPtr: +0
; type, +1 phase, +2/+3 the profile address, +4 strips, +5 mask offset, +6/+7
; the buffer address. Then SaveStrips copies what the shadow will cover.
ShadowListAdd:
  PUSH AF
  LD A,(ScrollPage)       ; the scroll state: page of column 0
  ADD A,D
  ADD A,D
  ADD A,$78
  LD D,A
  RES 6,D                 ; wrap into $80-$BF
  SET 7,D
  POP AF
  LD HL,(ShadowListPtr)
  EX AF,AF'
  LD (HL),A               ; +0 type
  INC L
  LD A,(IX+$09)           ; +1 phase
  LD (HL),A
  INC L
  INC L
  INC L
  LD (HL),B               ; +4 strips
  INC L
  LD (HL),C               ; +5 mask offset
  INC L
  LD (HL),E               ; +6, +7 the address in the playfield buffer
  INC L
  LD (HL),D
  INC L
  LD (ShadowListPtr),HL   ; the next free entry
  EX AF,AF'
  EX DE,HL
  CALL SaveStrips         ; save the strips under the shadow
  JP ShadowListLoop

; Sprite list: the visible records at their own heights
;
; The second walk of $6500. The line is +A plus the height +4. A dying record
; (bit 5) is drawn as a type 3 explosion, a line lower at height 25 and two
; lines lower above. The graphic is the word at $C300 + (+8): +8 is twice the
; type normally (set at $E2A4) and the explosion counter while dying. The phase
; (+9) picks one of 4 pre-shifted frames: $A8 bytes for types 0-3 (4 strips of
; 21 lines, a mask and a pixel byte a line), $66 for 4-10 (3 strips of 17), $34
; for 11-13 (2 strips of 13). Clipping is as in ShadowListLoop; a dropped strip
; on the left moves the graphic on by one strip. The 6-byte entry at
; SpriteListPtr: +0 type, +1 strips, +2/+3 the buffer address, +4/+5 the
; graphic; then SaveSpriteStrips. $EAE3 draws the list after the shadows.
SpriteListBuild:
  LD HL,SpriteScratch
  PUSH HL
SpriteListLoop:
  POP HL
  BIT 6,(HL)
  JR Z,l_DBA9
  LD HL,(SpriteListPtr)
  LD (HL),$FF             ; end the sprite list
  RET
l_DBA9:
  INC L
  INC L
  LD A,(HL)
  LD IXL,A
  INC L
  LD A,(HL)
  LD IXH,A
  INC L
  PUSH HL
  LD L,(IX+$0A)           ; +A: the line in the strip, +B: the column
  LD H,(IX+$0B)
  LD A,(IX+$04)           ; + the height
  ADD A,L
  LD L,A
  EX DE,HL
  LD A,(IX+$00)
  BIT 5,A                 ; dying?
  JR Z,l_DBD6
  LD A,(IX+$04)
  CP $19                  ; at 25 a line lower, above that two
  JR C,l_DBD4
  DEC DE
  CP $1A
  JR C,l_DBD4
  DEC DE
l_DBD4:
  LD A,$03                ; dying: drawn as a type 3, the explosion
l_DBD6:
  AND $0F
  CP $04
  JR C,SpriteBig
  CP $0B
  JP C,SpriteMid
  CP $0E
  JP C,SpriteSmall
  JR SpriteListLoop       ; types 14 and up: not here
SpriteBig:
  EX AF,AF'               ; types 0-3: 4 strips of 21 lines
  LD L,(IX+$08)           ; the graphic: the word at $C300 + (+8)
  LD H,$C3
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  LD BC,$00A8             ; one frame: 4 strips x 21 lines x 2 bytes
  LD A,(IX+$09)           ; frame (phase - 1) AND 3
  DEC A
  AND $03
  JR Z,l_DC01
l_DBFD:
  ADD HL,BC
  DEC A
  JR NZ,l_DBFD
l_DC01:
  LD B,$04
  LD A,D
  SUB $04
  CP $1D
  JR C,l_DC54
  JR NZ,l_DC0F
  DEC B
  JR l_DC5E
l_DC0F:
  CP $1E
  JR NZ,l_DC17
  LD B,$02
  JR l_DC5E
l_DC17:
  CP $1F
  JR NZ,l_DC1F
  LD B,$01
  JR l_DC5E
l_DC1F:
  CP $FD
  JR NZ,l_DC31
  LD BC,$007E             ; 3 strips off the left: the graphic 3 strips on
  ADD HL,BC
  EX DE,HL
  LD BC,$02F4
  ADD HL,BC
  EX DE,HL
  LD B,$01
  JR l_DC54
l_DC31:
  CP $FE
  JR NZ,l_DC43
  LD BC,$0054
  ADD HL,BC
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD B,$02
  JR l_DC54
l_DC43:
  CP $FF
  JP NZ,SpriteListLoop
  LD BC,$002A
  ADD HL,BC
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD B,$03
l_DC54:
  LD A,(IX+$09)
  AND A
  JR NZ,l_DC5E
  DEC B
  JP Z,SpriteListLoop
l_DC5E:
  LD A,$15                ; 21 lines a strip
  JP SpriteListAdd
SpriteMid:
  EX AF,AF'               ; types 4-10: 3 strips of 17 lines
  LD L,(IX+$08)
  LD H,$C3
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  LD BC,$0066             ; one frame: 3 strips x 17 lines x 2 bytes
  INC E
  INC E
  LD A,(IX+$09)           ; phase 2 and 3: one column on, 4 lines lower
  CP $02
  JR C,l_DC7E
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
l_DC7E:
  INC A                   ; frame (phase + 1) AND 3
  AND $03
  JR Z,l_DC89
l_DC83:
  ADD HL,BC
  DEC A
  JR NZ,l_DC83
  JR l_DC89
l_DC89:
  LD B,$03
  LD A,D
  SUB $04
  CP $1E
  JR C,l_DCC2
  JR NZ,l_DC97
  DEC B
  JR l_DCCD
l_DC97:
  CP $1F
  JR NZ,l_DC9F
  LD B,$01
  JR l_DCCD
l_DC9F:
  CP $FE
  JR NZ,l_DCB1
  LD BC,$0044
  ADD HL,BC
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD B,$01
  JR l_DCC2
l_DCB1:
  CP $FF
  JP NZ,SpriteListLoop
  LD BC,$0022
  ADD HL,BC
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD B,$02
l_DCC2:
  LD A,(IX+$09)
  CP $02
  JR NZ,l_DCCD
  DEC B
  JP Z,SpriteListLoop
l_DCCD:
  LD A,$11                ; 17 lines a strip
  JR SpriteListAdd
SpriteSmall:
  EX AF,AF'               ; types 11-13: 2 strips of 13 lines
  INC D
  LD L,(IX+$08)
  LD H,$C3
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  LD BC,$0034             ; one frame: 2 strips x 13 lines x 2 bytes
  LD A,(IX+$09)
  DEC A
  AND $03
  JR Z,l_DCEB
l_DCE7:
  ADD HL,BC
  DEC A
  JR NZ,l_DCE7
l_DCEB:
  LD B,$02
  LD A,D
  SUB $04
  CP $1F
  JR C,l_DD0A
  JR NZ,l_DCF9
  DEC B
  JR l_DD14
l_DCF9:
  CP $FF
  JP NZ,SpriteListLoop
  LD BC,$001A
  ADD HL,BC
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD B,$01
l_DD0A:
  LD A,(IX+$09)
  AND A
  JR NZ,l_DD14
  DEC B
  JP Z,SpriteListLoop
l_DD14:
  LD A,$0D                ; 13 lines a strip
SpriteListAdd:
  PUSH AF                 ; the page from the column, as at ShadowListAdd
  LD A,(ScrollPage)
  ADD A,D
  ADD A,D
  ADD A,$78
  LD D,A
  RES 6,D
  SET 7,D
  POP AF
  PUSH HL
  LD HL,(SpriteListPtr)
  EX AF,AF'
  LD (HL),A               ; +0 type
  INC L
  LD (HL),B               ; +1 strips
  INC L
  LD (HL),E               ; +2, +3 the address in the playfield buffer
  INC L
  LD (HL),D
  LD (BlitListEnd+$0002),DE
  INC L
  POP DE
  LD (HL),E               ; +4, +5 the graphic
  INC L
  LD (HL),D
  INC L
  LD (SpriteListPtr),HL
  EX AF,AF'
  CALL SaveSpriteStrips   ; save the strips under the sprite
  JP SpriteListLoop

; Save the strips under the sprite just listed
;
; HL = the buffer address kept at $D9D4 (HL held the graphic), then SaveStrips.
SaveSpriteStrips:
  LD HL,(BlitListEnd+$0002)

; Copy the strips an object will cover into the save area
;
; In: HL = the playfield address of the first strip's lowest line, B = strips,
; A = lines a strip. Each strip's lines are copied with LDIR to SaveAreaPtr
; ($F800 on); the next strip is the next column of the buffer: 4 bytes lower
; (the 4-line skew of docs/06-rendering.md 6.3), two pages on, wrapping from
; $C0 to $80. RestoreStrips undoes it after the blit.
SaveStrips:
  LD DE,(SaveAreaPtr)     ; DE = the free save area
  EX AF,AF'
  LD A,B
l_DD4D:
  EX AF,AF'
  LD B,$00                ; BC = lines
  LD C,A
  PUSH HL
  LDIR
  POP HL
  DEC L                   ; the next strip: 4 lines lower ...
  DEC L
  DEC L
  DEC L
  INC H                   ; ... two pages on, $80-$BF
  INC H
  RES 6,H
  EX AF,AF'
  DEC A
  JR NZ,l_DD4D
  LD (SaveAreaPtr),DE     ; the save area's new end
  RET

; The shadow list's next free entry ($FE64 on); DrawShadows reuses it to walk
; the list
ShadowListPtr:
  DEFW $0000

; The next free entry of the sprite list ($FF00 on)
SpriteListPtr:
  DEFW $0000

; The free end of the strip save area ($F800 on)
SaveAreaPtr:
  DEFW $0000

; After the blit: the strips under every shadow and sprite put back
;
; Called by the blit $D35E once the buffer is on the screen
; (docs/06-rendering.md 6.1). Walks the shadow list $FE64 (17, 11 or 4 lines a
; strip by type) and then the sprite list $FF00 (21, 17 or 13), in the order
; BuildSpriteLists saved them, and copies the saved bytes back from $F800 with
; RestoreStrips. The playfield is clean again for the scroller.
RestoreUnderSprites:
  LD HL,SpriteSaveBuffer  ; the saved strips, in the order they were saved
  LD (SaveAreaPtr),HL
  LD HL,Im2Table+$0064    ; the shadow list
  PUSH HL
l_DD76:
  POP HL
  LD A,(HL)
  CP $FF
  JR Z,l_DD9F
  INC L
  INC L
  INC L
  INC L
  LD B,(HL)               ; +4 strips
  INC L
  INC L
  LD E,(HL)               ; +6, +7 the buffer address
  INC L
  LD D,(HL)
  INC L
  PUSH HL
  CP $04
  JR C,l_DD98
  CP $0B
  JR C,l_DD94
  LD A,$04
  JR l_DD9A
l_DD94:
  LD A,$0B
  JR l_DD9A
l_DD98:
  LD A,$11                ; types 0-3: 17 lines
l_DD9A:
  CALL RestoreStrips
  JR l_DD76
l_DD9F:
  LD HL,SpriteListArea    ; the sprite list
  PUSH HL
l_DDA3:
  POP HL
  LD A,(HL)
  CP $FF
  RET Z
  INC L
  LD B,(HL)               ; +1 strips
  INC L
  LD E,(HL)               ; +2, +3 the buffer address
  INC L
  LD D,(HL)
  INC L
  INC L
  INC L
  PUSH HL
  CP $04
  JR C,l_DDC2
  CP $0B
  JR C,l_DDBE
  LD A,$0D
  JR l_DDC4
l_DDBE:
  LD A,$11
  JR l_DDC4
l_DDC2:
  LD A,$15                ; types 0-3: 21 lines
l_DDC4:
  CALL RestoreStrips
  JR l_DDA3

; Copy saved strips back into the playfield buffer
;
; In: DE = the playfield address of the first strip's lowest line, B = strips,
; A = lines a strip; the bytes come from SaveAreaPtr on. The reverse of
; SaveStrips.
RestoreStrips:
  LD HL,(SaveAreaPtr)     ; HL = the next saved bytes
  EX AF,AF'
  LD A,B
l_DDCE:
  EX AF,AF'
  LD B,$00
  LD C,A
  PUSH DE
  LDIR
  POP DE
  DEC E                   ; the next strip: 4 lines lower, two pages on
  DEC E
  DEC E
  DEC E
  INC D
  INC D
  RES 6,D
  EX AF,AF'
  DEC A
  JR NZ,l_DDCE
  LD (SaveAreaPtr),HL
  RET
