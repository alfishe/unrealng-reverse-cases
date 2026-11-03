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
  JR Z,ShadowEntryRecord
  LD HL,(ShadowListPtr)
  LD (HL),$FF             ; end the shadow list, go on with the sprites
  JP SpriteListBuild
ShadowEntryRecord:
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
  JR C,BigShadowPhase
  JR NZ,BigShadowCol30
  DEC B
  JR BigShadowLines
BigShadowCol30:
  CP $1E
  JR NZ,BigShadowCol31
  LD B,$02
  JR BigShadowLines
BigShadowCol31:
  CP $1F
  JR NZ,BigShadowLeft3
  LD B,$01
  JR BigShadowLines
BigShadowLeft3:
  CP $FD                  ; columns -3 to -1: the first strips are off the left
                          ; edge
  JR NZ,BigShadowLeft2
  EX DE,HL
  LD BC,$02F4
  ADD HL,BC
  EX DE,HL
  LD C,$33                ; C = the mask bytes skipped (17 a strip)
  LD B,$01
  JR BigShadowPhase
BigShadowLeft2:
  CP $FE
  JR NZ,BigShadowLeft1
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD C,$22
  LD B,$02
  JR BigShadowPhase
BigShadowLeft1:
  CP $FF
  JP NZ,ShadowListLoop
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD C,$11
  LD B,$03
BigShadowPhase:
  LD A,(IX+$09)           ; phase 0: one strip fewer
  AND A
  JR NZ,BigShadowLines
  DEC B
  JP Z,ShadowListLoop
BigShadowLines:
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
  JR C,MidShadowColumn
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
MidShadowColumn:
  LD C,$00
  LD B,$03
  LD A,D
  SUB $04
  CP $1E
  JR C,MidShadowPhase
  JR NZ,MidShadowCol31
  DEC B
  JR MidShadowLines
MidShadowCol31:
  CP $1F
  JR NZ,MidShadowLeft2
  LD B,$01
  JR MidShadowLines
MidShadowLeft2:
  CP $FE
  JR NZ,MidShadowLeft1
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD C,$16
  LD B,$01
  JR MidShadowPhase
MidShadowLeft1:
  CP $FF
  JP NZ,ShadowListLoop
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD C,$0B
  LD B,$02
MidShadowPhase:
  LD A,(IX+$09)           ; phase 2: one strip fewer
  CP $02
  JR NZ,MidShadowLines
  DEC B
  JP Z,ShadowListLoop
MidShadowLines:
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
  JR C,SmallShadowPhase
  JR NZ,SmallShadowLeft1
  DEC B
  JR SmallShadowLines
SmallShadowLeft1:
  CP $FF
  JP NZ,ShadowListLoop
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD C,$04
  LD B,$01
SmallShadowPhase:
  LD A,(IX+$09)           ; phase 0: one strip fewer
  AND A
  JR NZ,SmallShadowLines
  DEC B
  JP Z,ShadowListLoop
SmallShadowLines:
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
; type normally (set at $D246, $D2E3 and $E2A4) and the explosion counter while
; dying. The phase (+9) picks one of 4 pre-shifted frames: $A8 bytes for types
; 0-3 (4 strips of 21 lines, a mask and a pixel byte a line), $66 for 4-10 (3
; strips of 17), $34 for 11-13 (2 strips of 13). Clipping is as in
; ShadowListLoop; a dropped strip on the left moves the graphic on by one
; strip. The 6-byte entry at SpriteListPtr: +0 type, +1 strips, +2/+3 the
; buffer address, +4/+5 the graphic; then SaveSpriteStrips. $EAE3 draws the
; list after the shadows.
SpriteListBuild:
  LD HL,SpriteScratch
  PUSH HL
SpriteListLoop:
  POP HL
  BIT 6,(HL)
  JR Z,SpriteEntryRecord
  LD HL,(SpriteListPtr)
  LD (HL),$FF             ; end the sprite list
  RET
SpriteEntryRecord:
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
  JR Z,SpriteByType
  LD A,(IX+$04)
  CP $19                  ; at 25 a line lower, above that two
  JR C,DrawAsExplosion
  DEC DE
  CP $1A
  JR C,DrawAsExplosion
  DEC DE
DrawAsExplosion:
  LD A,$03                ; dying: drawn as a type 3, the explosion
SpriteByType:
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
  JR Z,BigSpriteColumn
BigFrameLoop:
  ADD HL,BC
  DEC A
  JR NZ,BigFrameLoop
BigSpriteColumn:
  LD B,$04
  LD A,D
  SUB $04
  CP $1D
  JR C,BigSpritePhase
  JR NZ,BigSpriteCol30
  DEC B
  JR BigSpriteLines
BigSpriteCol30:
  CP $1E
  JR NZ,BigSpriteCol31
  LD B,$02
  JR BigSpriteLines
BigSpriteCol31:
  CP $1F
  JR NZ,BigSpriteLeft3
  LD B,$01
  JR BigSpriteLines
BigSpriteLeft3:
  CP $FD
  JR NZ,BigSpriteLeft2
  LD BC,$007E             ; 3 strips off the left: the graphic 3 strips on
  ADD HL,BC
  EX DE,HL
  LD BC,$02F4
  ADD HL,BC
  EX DE,HL
  LD B,$01
  JR BigSpritePhase
BigSpriteLeft2:
  CP $FE
  JR NZ,BigSpriteLeft1
  LD BC,$0054
  ADD HL,BC
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD B,$02
  JR BigSpritePhase
BigSpriteLeft1:
  CP $FF
  JP NZ,SpriteListLoop
  LD BC,$002A
  ADD HL,BC
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD B,$03
BigSpritePhase:
  LD A,(IX+$09)
  AND A
  JR NZ,BigSpriteLines
  DEC B
  JP Z,SpriteListLoop
BigSpriteLines:
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
  JR C,MidFrameIndex
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
MidFrameIndex:
  INC A                   ; frame (phase + 1) AND 3
  AND $03
  JR Z,MidSpriteColumn
MidFrameLoop:
  ADD HL,BC
  DEC A
  JR NZ,MidFrameLoop
  JR MidSpriteColumn
MidSpriteColumn:
  LD B,$03
  LD A,D
  SUB $04
  CP $1E
  JR C,MidSpritePhase
  JR NZ,MidSpriteCol31
  DEC B
  JR MidSpriteLines
MidSpriteCol31:
  CP $1F
  JR NZ,MidSpriteLeft2
  LD B,$01
  JR MidSpriteLines
MidSpriteLeft2:
  CP $FE
  JR NZ,MidSpriteLeft1
  LD BC,$0044
  ADD HL,BC
  EX DE,HL
  LD BC,$01F8
  ADD HL,BC
  EX DE,HL
  LD B,$01
  JR MidSpritePhase
MidSpriteLeft1:
  CP $FF
  JP NZ,SpriteListLoop
  LD BC,$0022
  ADD HL,BC
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD B,$02
MidSpritePhase:
  LD A,(IX+$09)
  CP $02
  JR NZ,MidSpriteLines
  DEC B
  JP Z,SpriteListLoop
MidSpriteLines:
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
  JR Z,SmallSpriteColumn
SmallFrameLoop:
  ADD HL,BC
  DEC A
  JR NZ,SmallFrameLoop
SmallSpriteColumn:
  LD B,$02
  LD A,D
  SUB $04
  CP $1F
  JR C,SmallSpritePhase
  JR NZ,SmallSpriteLeft1
  DEC B
  JR SmallSpriteLines
SmallSpriteLeft1:
  CP $FF
  JP NZ,SpriteListLoop
  LD BC,$001A
  ADD HL,BC
  EX DE,HL
  LD BC,$00FC
  ADD HL,BC
  EX DE,HL
  LD B,$01
SmallSpritePhase:
  LD A,(IX+$09)
  AND A
  JR NZ,SmallSpriteLines
  DEC B
  JP Z,SpriteListLoop
SmallSpriteLines:
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
SaveStripLoop:
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
  JR NZ,SaveStripLoop
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
RestoreShadowLoop:
  POP HL
  LD A,(HL)
  CP $FF
  JR Z,RestoreSprites
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
  JR C,RestoreBigShadow
  CP $0B
  JR C,RestoreMidShadow
  LD A,$04
  JR RestoreShadowStrips
RestoreMidShadow:
  LD A,$0B
  JR RestoreShadowStrips
RestoreBigShadow:
  LD A,$11                ; types 0-3: 17 lines
RestoreShadowStrips:
  CALL RestoreStrips
  JR RestoreShadowLoop
RestoreSprites:
  LD HL,SpriteListArea    ; the sprite list
  PUSH HL
RestoreSpriteLoop:
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
  JR C,RestoreBigSprite
  CP $0B
  JR C,RestoreMidSprite
  LD A,$0D
  JR RestoreSpriteStrips
RestoreMidSprite:
  LD A,$11
  JR RestoreSpriteStrips
RestoreBigSprite:
  LD A,$15                ; types 0-3: 21 lines
RestoreSpriteStrips:
  CALL RestoreStrips
  JR RestoreSpriteLoop

; Copy saved strips back into the playfield buffer
;
; In: DE = the playfield address of the first strip's lowest line, B = strips,
; A = lines a strip; the bytes come from SaveAreaPtr on. The reverse of
; SaveStrips.
RestoreStrips:
  LD HL,(SaveAreaPtr)     ; HL = the next saved bytes
  EX AF,AF'
  LD A,B
RestoreStripLoop:
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
  JR NZ,RestoreStripLoop
  LD (SaveAreaPtr),HL
  RET
