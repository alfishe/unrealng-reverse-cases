; --------------------------------------------------------------------------------------------------------------------
; stars.asm: The falling stars and the twinkles
;
; 60 stars fall down the screen, one pixel row at a time: three tables of 20 (StarsA $AC84 and StarsB $ACFC moved
; twice every 2nd pass of MainLoop, StarsC $AD74 once every 4th pass: the third group falls 4 times slower), each star
; one pixel, the tables' stars in pairs side by side (src/res/tables/stars.txt). A star is drawn by setting its pixel;
; before it moves, the screen pixel under it is put back (SET if it was lit, RES if not), so the stars pass over the
; menu without damaging it. From the bottom row a star goes back to the top.
;
; The twinkle is one 16x16 star sprite (TwinkleSprites $6F60, src/res/graphics/twinkle.png) at a random place: it
; grows through 4 frames and shrinks back, one frame every 4 interrupts, a new place every 32 interrupts with a pause
; of 8 (TwinkleStar $6BA5).
; --------------------------------------------------------------------------------------------------------------------

  ORG $645E

; Read the screen pixel under each of the 60 stars into its record
;
; Falls into SampleStar with IX = StarsA $AC84, B = 60 (the three tables follow
; each other).
;
; Witness: L1 12 (c x4).
SampleStars:
  LD IX,StarsA
  LD B,$3C

; For B stars from IX: record +5 = the pixel under the star (BIT n,(HL), the
; opcode at +4)
;
; A star's record (6 bytes): +0/+1 the screen address, +2 RES n,(HL)'s second
; byte, +3 SET n,(HL)'s, +4 BIT n,(HL)'s, +5 the pixel under it (0 or 1).
;
; Witness: L1 1245596 (c x4).
SampleStar:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(IX+$04)
  LD (SampleStarBit+$0001),A
  XOR A
SampleStarBit:
  BIT 0,(HL)              ; BIT n,(HL): the opcode from the record
  JR Z,SampleStarStore
  LD A,$01
SampleStarStore:
  LD (IX+$05),A
  LD DE,$0006
  ADD IX,DE
  DJNZ SampleStar
  RET

; Move the 20 stars of one table down one pixel row
;
; The table's address is the operand of the LD IX at $6482 (MainLoop writes
; it). For each star: puts back the screen pixel under it (RES or SET from
; +2/+3 by +5), moves the address one pixel row down (from the bottom of the
; screen to the top), samples the new pixel (SampleStar with B = 1) and sets
; it.
;
; Witness: L1 62246 (c x4).
MoveStars:
  LD IX,StarsA
  LD B,$14
MoveStarsNext:
  PUSH BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD D,(IX+$02)
  LD E,(IX+$03)
  LD A,(IX+$05)
  CP $01
  LD A,D
  JR NZ,MoveStarsRestore
  LD A,E
MoveStarsRestore:
  LD (MoveStarsPutBack+$0001),A
MoveStarsPutBack:
  RES 0,(HL)              ; RES / SET n,(HL): put back the pixel the star
                          ; covered
  INC H
  LD A,H
  AND $07
  JR NZ,MoveStarsMoved
  LD A,H
  SUB $08
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
  AND $E0
  JR NZ,MoveStarsMoved
  LD A,H
  ADD A,$08
  LD H,A
  AND $18
  CP $18
  JR NZ,MoveStarsMoved
  LD H,$40
MoveStarsMoved:
  LD (IX+$00),L
  LD (IX+$01),H
  LD B,$01
  CALL SampleStar
  LD A,(MoveStarsPutBack+$0001)
  SET 6,A
  LD (MoveStarsDraw+$0001),A
MoveStarsDraw:
  SET 0,(HL)              ; SET n,(HL): draw the star at its new place
  POP BC
  DJNZ MoveStarsNext
  RET

  ORG $6BA5

; The twinkle at each frame: new randoms at TwinkleClock 0, erase at the end of
; a twinkle, a frame every 4th frame
;
; TwinkleClock $DEAC (+2 a frame, 128 frames a round): 0: NewRandoms $6BAB.
; Bits 0-5 = $3E (the twinkle's last frame): EraseTwinkle without a new frame,
; and for 7 of 8 times TwinkleClock - 2 (TwinklePause $DEB0 counts): an 8-frame
; pause. Else every 4th frame (clock bits 0-2 = 2): DrawTwinkle $6BFD.
;
; Witness: L1 13931 (c x4).
TwinkleStar:
  LD A,(TwinkleClock)
  AND A
  JR NZ,TwinkleEnd

; Fill Randoms $ADEC with 8 new bytes from R, the ROM's bytes and MainTick
;
; Witness: L1 244 (c x4).
NewRandoms:
  LD HL,(RomPointer)
  INC HL
  LD A,H
  AND $07
  LD H,A
  LD (RomPointer),HL
  LD B,$08
  LD C,(HL)
  LD HL,Randoms
NewRandomNext:
  LD A,R
  XOR (HL)
  XOR C
  ADD A,C
  LD C,A
  LD A,(MainTick)
  XOR C
  LD (HL),A
  INC HL
  DJNZ NewRandomNext
  RET
; This entry point is used by the routine at TwinkleStar.
TwinkleEnd:
  LD A,(TwinkleClock)            ; the end of a twinkle: the pause
  AND $3F
  CP $3E
  JR NZ,TwinkleEvery4
  LD A,(TwinklePause)
  INC A
  AND $07
  LD (TwinklePause),A
  JR Z,TwinkleErase
  LD A,(TwinkleClock)
  SUB $02
  LD (TwinkleClock),A
TwinkleErase:
  LD A,$C9
  LD (DrawTwinkleSprite),A
  CALL DrawTwinkle
  LD A,$3A
  LD (DrawTwinkleSprite),A
  RET
TwinkleEvery4:
  LD A,(TwinkleClock)            ; every 4th frame
  AND $07
  CP $02
  RET NZ

; Erase the twinkle and draw its next frame at the place from Randoms
;
; The place: the pair Randoms[2n], [2n+1], n = TwinkleClock bits 6-7;
; CheckTwinkleSpot $6C56 refuses a place on the menu's text or off the screen
; (new randoms and again). EraseTwinkle $6C71 sets TwinkleAddr. The frame:
; TwinkleClock bits 3-4, counted down when bit 5 is set: frames 0, 1, 2, 3, 3,
; 2, 1, 0; ORed onto the screen, 16 rows of 2 bytes.
;
; Witness: L1 5864 (c x4).
DrawTwinkle:
  LD A,(TwinkleClock)
  RLCA
  RLCA
  RLCA
  AND $06
  LD C,A
  LD B,$00
  LD HL,Randoms
  ADD HL,BC
  CALL CheckTwinkleSpot
  PUSH AF
  CALL NC,NewRandoms
  POP AF
  JR NC,DrawTwinkle
  CALL EraseTwinkle
DrawTwinkleSprite:
  LD A,(TwinkleClock)            ; LD A,(TwinkleClock): a RET while TwinkleStar only
                          ; erases
  AND $20
  LD C,$60
  JR NZ,DrawTwinkleFrame
  LD C,$00
DrawTwinkleFrame:
  LD A,(TwinkleClock)
  RLCA
  RLCA
  XOR C
  AND $60
  LD C,A
  LD B,$00
  LD HL,TwinkleSprites
  ADD HL,BC
  EX DE,HL
  LD B,$10
  LD HL,(TwinkleAddr)
DrawTwinkleRow:
  LD C,(HL)               ; OR the sprite onto the screen
  LD A,(DE)
  OR C
  LD (HL),A
  INC L
  INC DE
  LD C,(HL)
  LD A,(DE)
  OR C
  LD (HL),A
  INC DE
  DEC L
  INC H
  LD A,H
  AND $07
  JR NZ,DrawTwinkleNext
  LD A,H
  SUB $08
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
DrawTwinkleNext:
  DJNZ DrawTwinkleRow
  RET

; Carry set if the place (HL) is allowed: the low byte below $E0 and its column
; clear of the menu
;
; Witness: L1 5864 (c x4).
CheckTwinkleSpot:
  LD B,$1A
  INC HL
  LD A,(HL)
  AND $18
  JR Z,CheckSpotColumn
  CP $10
  JR Z,CheckSpotColumn
  LD B,$1F
CheckSpotColumn:
  DEC HL
  LD A,(HL)
  CP $E0
  RET NC
  AND $1F
  CP B
  RET NC
  XOR $1F
  CP B
  RET

; TwinkleAddr = the place; copy its 16 rows of 2 bytes from ScreenCopy (the
; twinkle is erased)
;
; Witness: L1 5705 (c x4).
EraseTwinkle:
  INC HL
  LD A,(HL)
  AND $18
  CP $18
  JR NZ,EraseTwinkleAddr
  LD A,$08
EraseTwinkleAddr:
  DEC HL
  LD L,(HL)
  OR $40
  LD H,A
  LD (TwinkleAddr),HL
  LD B,$10
EraseTwinkleRow:
  LD A,H
  OR ScreenCopyHigh
  LD D,A
  LD E,L
  LD A,(DE)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  LD (HL),A
  DEC L
  INC H
  LD A,H
  AND $07
  JR NZ,EraseTwinkleNext
  LD A,H
  SUB $08
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
EraseTwinkleNext:
  DJNZ EraseTwinkleRow
  RET

  ORG $6F60

; The 4 twinkle frames: 16x16, 2 bytes a row
;
; Read by DrawTwinkle.
TwinkleSprites:
  INCBIN "res/graphics/twinkle.bin",$0000,128

; Zeros to the 15th sector's end: loaded, not read
;
; No instruction in c1-c4 reads them. In many variants they hold other bytes
; (leftovers of the memory the piece was saved from).
TwinkleSpare:
  INCBIN "res/spare/code-tail.bin",$0000,200
