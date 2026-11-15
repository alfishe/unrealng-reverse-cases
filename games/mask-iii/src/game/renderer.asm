; --------------------------------------------------------------------------------------------------------------------
; renderer.asm: The renderer: zone swapping, the dirty map, the sprites drawn as characters
;
; Everything on the play area is characters. The 32 x 20 character map at $F080 (rows 2-19 shown, from $F0C0) names a
; character of the live zone; the dirty map $F3C0-$F5FF marks each cell to redraw (1 the zone character from ZoneChars
; $E000 / ZoneAttrs $EF00, 2 a sprite character from $E800 / $EE00). A sprite is drawn by allocating fresh characters
; from $E800 up, copying the backgrounds into them and ORing the masked, shifted picture in (DrawObject $A56F);
; FlushDirty $A1F0 then puts the dirty cells on the screen. Characters $EA and up of a zone are foreground and are
; never drawn over.
; --------------------------------------------------------------------------------------------------------------------

; ZoneSlots[0] the live zone, [1-3] the zones parked at $5B00, $6400, $6D00
ZoneSlots:
  DEFB $00,$01,$02,$03

; Make zone A live: swap its parked $900 bytes with ZoneChars/ZoneAttrs, under
; DI
;
; Also writes TurretStems $A1EC[zone] into TurretStem $C26E. Witness: L1 79
; (c1, door, play2, rzx- x9); the per-frame trace of a room change is in
; work/stage2/NOTES.md.
SwapZone:
  LD HL,ZoneSlots
  CP (HL)
  RET Z
  DI
  LD E,(HL)
  INC HL
  LD B,$01
l_A1A2:
  CP (HL)
  JR Z,l_A1A9
  INC HL
  INC B
  JR l_A1A2
l_A1A9:
  LD D,A
  PUSH DE
  PUSH HL
  LD HL,ParkedZone1
  LD DE,$0900
  JR l_A1B5
l_A1B4:
  ADD HL,DE
l_A1B5:
  DJNZ l_A1B4
  LD DE,ZoneChars
  LD BC,$0800
l_A1BD:
  LD A,(HL)
  EX AF,AF'
  LD A,(DE)
  LD (HL),A
  EX AF,AF'
  LD (DE),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JP NZ,l_A1BD
  LD DE,ZoneAttrs
l_A1CE:
  LD C,(HL)
  EX DE,HL
  LD B,(HL)
  LD (HL),C
  EX DE,HL
  LD (HL),B
  INC L
  INC E
  JR NZ,l_A1CE
  POP HL
  POP DE
  LD (HL),E
  LD A,D
  LD (ZoneSlots),A
  LD E,A
  LD D,$00
  LD HL,TurretStems
  ADD HL,DE
  LD A,(HL)
  LD (TurretStem),A
  EI
  RET

; One character a zone: the stem KindTurret draws under a turret (copied to
; TurretStem $C26E)
TurretStems:
  DEFB $A7,$64,$56,$3F

; Draw every dirty cell (from $F5FF down to the sentinel $F3BF) and clear its
; mark
;
; Witness: L1 13273 (c1, door, play2, rzx- x9).
FlushDirty:
  LD A,$FF
  LD (Zone1CharsLow+$03BF),A
  LD HL,PlayPanel
  LD IX,l_A1FC

; l_A1FC
l_A1FC:
  XOR A
  DEC HL
l_A1FE:
  OR (HL)
  DEC HL
  JP Z,l_A1FE
  RET M
  DEC A
  INC HL
  LD (HL),A
  PUSH HL
  DEC H
  DEC H
  DEC H
  LD E,(HL)
  ADD A,$FC
  LD D,A
  LD BC,$FF40
  ADD HL,BC
  LD C,E
  LD B,H
  LD A,H
  AND $03
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$40
  LD H,A
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  LD A,(HL)
  LD (DE),A
  LD A,B
  SUB $98
  LD D,A
  LD B,$EF
  BIT 3,H
  JR Z,l_A24C
  LD B,$EE
l_A24C:
  LD A,(BC)
  AND $47
  LD (DE),A
  POP HL
  JP (IX)

; The backgrounds kept under the pick-up icons
PickupSaves:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
PickupSavePtr:
  DEFB $00,$00            ; the next free save
NextSpriteChar:
  DEFB $00                ; the next free sprite character
FirstSpriteChar:
  DEFB $00                ; the first sprite character of this pass
DissolveCount:
  DEFB $00                ; non-zero: Matt is drawn dissolved (pods,
                          ; penetrator, death)

; The last step of a pass: place pick-ups, draw the 8 objects, flush, restore
; the backgrounds
;
; Witness: L1 13174 (c1, door, play2, rzx- x9).
DrawObjects:
  CALL PlacePickups
  LD A,(FirstSpriteChar)
  LD (NextSpriteChar),A
  LD E,A
  LD D,$00
  LD IY,Zone1Attrs
  ADD IY,DE
  LD IX,Objects
  LD B,$08
l_A2E8:
  LD A,(IX+$00)
  AND $BF
  JR Z,l_A2F7
  PUSH BC
  CALL SelectFrame
  CALL DrawObject
  POP BC
l_A2F7:
  LD DE,$0026
  ADD IX,DE
  DJNZ l_A2E8
  CALL FlushDirty
  LD IX,Enemies+$00BE
  LD A,$08

; l_A307
;
; Used by the routine at l_A33C.
l_A307:
  PUSH AF
  LD A,(IX+$00)
  AND $BF
  JR Z,l_A33C
  LD DE,$0020
  LD C,(IX+$0E)
  LD B,(IX+$0F)
  LD H,(IX+$0A)
  LD L,(IX+$09)
  LD A,(IX+$05)
  INC A
  LD (IX+$07),A
l_A325:
  LD A,(IX+$06)
  INC A
  PUSH HL
l_A32A:
  EX AF,AF'
  LD A,(BC)
  INC BC
  LD (HL),A
  ADD HL,DE
  EX AF,AF'
  DEC A
  JP NZ,l_A32A
  POP HL
  INC HL
  DEC (IX+$07)
  JP NZ,l_A325

; l_A33C
;
; Used by the routine at l_A307.
l_A33C:
  POP AF
  LD DE,$FFDA
  ADD IX,DE
  DEC A
  JP NZ,l_A307
  JP RestorePickups

; The object's frame address from its mode (+$19), animation (+$18) and mask
; (+$1A); Matt's from his state and x
;
; Witness: L1 90196 (c1, door, play2, rzx- x9).
SelectFrame:
  LD A,(IX+$19)
  AND A
  RET Z
  CP $01
  JP NZ,FrameByMode
  LD HL,MattJump
  LD A,(IX+$00)
  CP $08
  JR Z,l_A38F
  CP $0A
  JR Z,l_A38F
  CP $0C
  JR Z,l_A38F
  LD HL,MattCrouch
  CP $04
  JR Z,l_A38F
  LD HL,MattRun+$0080
  CP $07
  JR Z,l_A38F
  LD A,(IX+$03)
  BIT 7,(IX+$02)
  JR Z,l_A37E
  NEG
l_A37E:
  SRL A
  SRL A
  AND $07
  LD H,A
  LD L,$00
  SRL H
  RR L
  LD DE,MattRun
  ADD HL,DE
l_A38F:
  LD (IX+$0C),L
  LD (IX+$0D),H
  LD A,(DissolveCount)
  AND A
  RET Z
l_A39A:
  DEC A
  JP Z,Dissolve
  PUSH AF
  CALL Dissolve
  POP AF
  JR l_A39A

; Copy a frame to $DF80 through a random mask from R (the dissolve)
;
; Witness: L1 2540 (c1, door, play2, rzx- x8).
Dissolve:
  LD L,(IX+$0C)
  LD H,(IX+$0D)
  LD DE,DissolveBuffer
  LD (IX+$0C),E
  LD (IX+$0D),D
  LD B,$20
  CALL Random
  LD R,A
  CALL Random
  LD C,A
l_A3BF:
  LD A,R
  ADD A,C
  LD C,A
  AND (HL)
  INC L
  LD (DE),A
  INC E
  LD A,R
  ADD A,C
  LD C,A
  AND (HL)
  INC L
  LD (DE),A
  INC E
  LD A,R
  ADD A,C
  LD C,A
  AND (HL)
  INC L
  LD (DE),A
  INC DE
  LD A,R
  ADD A,C
  LD C,A
  AND (HL)
  INC HL
  LD (DE),A
  INC DE
  DJNZ l_A3BF
  RET

; FrameByMode
;
; Used by the routine at SelectFrame.
FrameByMode:
  ADD A,A                 ; the frame offset: animation x the mode's frame size
                          ; (self-modified JR at $A3EC)
  LD (l_A3EC+$0001),A
  LD A,(IX+$18)
  AND (IX+$1A)
l_A3EC:
  JR l_A3EC

; Four unused bytes of the mode jump table
FrameJumpSpare:
  DEFB $00,$00,$00,$00

; l_A3F2
l_A3F2:
  JR l_A3FE

; JR $A3FE (mode 3), never taken
FrameMode3Jump:
  DEFB $18,$08

; l_A3F6
l_A3F6:
  JR l_A407
  JR l_A40C
  JR l_A411
  JR l_A414
; This entry point is used by the routine at l_A3F2.
l_A3FE:
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  JR l_A422
l_A407:
  RRCA
  RRCA
  RRCA
  JR l_A422
l_A40C:
  ADD A,A
  ADD A,A
  ADD A,A
  JR l_A422
l_A411:
  XOR A
  JR l_A422
l_A414:
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  LD E,A
  LD D,H
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  JR l_A431
l_A422:
  ADD A,(IX+$16)
  LD (IX+$0C),A
  LD A,$00
  ADC A,(IX+$17)
  LD (IX+$0D),A
  RET
l_A431:
  LD E,(IX+$16)
  LD D,(IX+$17)
  ADD HL,DE
  LD (IX+$0C),L
  LD (IX+$0D),H
  RET

; The 8 objects of $26 bytes: Matt, Matt's shot $A465, the six others from
; $A48B
;
; Fields: +0 kind (bit 7 placed, bit 6 dying), +2 direction (bit 7 left), +3 x
; (2 pixels a unit, column (x - $40) / 4), +4 y, +5 width and +6 height in
; characters, +9/+A buffer, +B first character, +C/+D frame, +E/+F save
; pointer, +10-+12 timers, +14/+15 the score it gives (BCD), +16/+17 the sprite
; base, +18 animation step, +19 mode (frame size), +1A animation mask, +1B dx,
; +1C dy, +1E damage to the energy, +1F once-a-room flag, +20 colour, +21 hits
; left, +22 hit by Matt's shot. Witness: read and written every pass (c1).
Objects:
  DEFB $01,$00,$C8,$64,$60,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$47,$00,$00,$00,$00,$00
MattShot:
  DEFB $01,$00,$00,$00,$00,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$FF,$00,$00,$00,$00,$00,$46,$00,$00,$00,$00,$00 ; object 1:
                                                                                                                                                               ; Matt's
                                                                                                                                                               ; shot
Enemies:
  DEFB $00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$46,$00,$00,$01,$00,$00 ; objects
  DEFB $00,$00,$00,$3A,$23,$03,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$45,$00,$00,$02,$00,$00 ; 2-7
  DEFB $00,$00,$00,$68,$3F,$03,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$44,$00,$00,$03,$00,$00
  DEFB $00,$00,$00,$50,$2D,$03,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$43,$00,$00,$04,$00,$00
  DEFB $00,$00,$00,$72,$28,$03,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$42,$00,$00,$05,$00,$00
  DEFB $00,$00,$00,$72,$0D,$03,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$41,$00,$00,$06,$00,$00

; Draw object IX as fresh characters from $E800: copy backgrounds, mask,
; mirror, shift, OR in
;
; Witness: L1 90196 (c1, door, play2, rzx- x9).
DrawObject:
  LD A,(IX+$04)
  ADD A,$30
  AND $F8
  LD (IX+$25),A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$03)
  SUB $40
  LD (IX+$13),A
  SRA A
  SRA A
  LD E,A
  LD D,$00
  ADD A,A
  JR NC,l_A592
  LD D,$FF
l_A592:
  ADD HL,DE
  LD DE,Zone1CharsLow
  ADD HL,DE
  LD (IX+$0A),H
  LD (IX+$09),L
  LD A,(NextSpriteChar)
  LD (IX+$0B),A
  LD B,A
  EXX
  LD L,A
  LD H,$FD
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  EX DE,HL
  EXX
  LD DE,(PickupSavePtr)
  LD (IX+$0E),E
  LD (IX+$0F),D
  LD A,(IX+$05)
  INC A
  LD (IX+$07),A
; This entry point is used by the routine at l_A62D.
l_A5BF:
  PUSH HL
  LD A,(IX+$25)
  LD (IX+$24),A
  LD A,(IX+$06)
  INC A
; This entry point is used by the routine at l_A62D.
l_A5CA:
  PUSH AF
  PUSH DE
  LD D,$EF
  LD E,(HL)
  LD A,H
  INC H
  INC H
  INC H
  BIT 1,(HL)
  JR Z,l_A5D9
  LD D,$EE
l_A5D9:
  LD H,A
  LD A,(DE)
  AND A
  JR NZ,l_A5E1
  LD A,(IX+$20)
l_A5E1:
  LD (IY+$00),A
  INC IY
  POP DE
  LD A,(HL)
  LD (DE),A
  CP $EA
  JP NC,l_A655
  BIT 7,(IX+$13)
  JR NZ,l_A655
  EX AF,AF'
  LD A,(IX+$24)
  CP $C0
  JR NC,l_A655
  EX AF,AF'
  LD (HL),B
  INC DE
  INC B
  INC H
  INC H
  INC H
  LD C,(HL)
  LD (HL),$02
  BIT 1,C
  EXX
  LD L,A
  LD H,$FC
  JR Z,l_A610
  LD H,$FD
l_A610:
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  EXX
  DEC H
  DEC H
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_A62D
  DEC H

; l_A62D
;
; Used by the routines at DrawObject and l_A655.
l_A62D:
  LD A,(IX+$24)
  ADD A,$08
  LD (IX+$24),A
  POP AF
  DEC A
  JP NZ,l_A5CA
  POP HL
  INC HL
  LD A,(IX+$13)
  ADD A,$04
  LD (IX+$13),A
  DEC (IX+$07)
  JP NZ,l_A5BF
  LD A,B
  LD (NextSpriteChar),A
  LD (PickupSavePtr),DE
  JP l_A66C

; l_A655
;
; Used by the routine at DrawObject.
l_A655:
  EXX
  LD A,E
  ADD A,$08
  LD E,A
  JP NC,l_A65E
  INC D
l_A65E:
  EXX
  INC DE
  INC B
  LD A,L
  ADD A,$20
  LD L,A
  JP NC,l_A62D
  INC H
  JP l_A62D

; l_A66C
;
; Used by the routine at l_A62D.
l_A66C:
  BIT 7,(IX+$02)
  CALL NZ,MirrorFrame
  CALL MakeMask
  POP HL
  LD A,(IX+$04)
  AND $07
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(IX+$03)
  AND $03
  JP NZ,DrawShifted
DrawAligned:
  LD BC,Zone1CharsLow     ; the picture on a character boundary
  LD E,(IX+$0C)
  LD D,(IX+$0D)
  LD A,(IX+$05)
  LD (IX+$07),A
l_A697:
  LD A,(IX+$06)
l_A69A:
  EX AF,AF'
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC L
  EX DE,HL
  LD (HL),A
  INC HL
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC L
  EX DE,HL
  LD (HL),A
  INC HL
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC L
  EX DE,HL
  LD (HL),A
  INC HL
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC L
  EX DE,HL
  LD (HL),A
  INC HL
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC L
  EX DE,HL
  LD (HL),A
  INC HL
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC L
  EX DE,HL
  LD (HL),A
  INC HL
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC L
  EX DE,HL
  LD (HL),A
  INC HL
  LD A,(BC)
  INC C
  CPL
  AND (HL)
  EX DE,HL
  OR (HL)
  INC HL
  EX DE,HL
  LD (HL),A
  INC HL
  EX AF,AF'
  DEC A
  JR NZ,l_A69A
  LD A,L
  ADD A,$08
  LD L,A
  JP NC,l_A6F7
  INC H
l_A6F7:
  DEC (IX+$07)
  JP NZ,l_A697
  RET
DrawShifted:
  ADD A,A                 ; the picture shifted 2, 4 or 6 pixels through the
                          ; tables $F800-$FDFF
  ADD A,$F6
  LD D,A
  LD A,(IX+$06)
  INC A
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  LD A,D
  EXX
  LD H,A
  LD DE,Zone1CharsLow
  LD C,(IX+$0C)
  LD B,(IX+$0D)
  LD A,(IX+$05)
  LD (IX+$07),A
l_A71E:
  LD A,(IX+$06)
  LD (IX+$08),A
l_A724:
  LD A,$04
l_A726:
  EX AF,AF'
  LD A,(BC)
  INC C
  LD L,A
  LD A,(DE)
  INC E
  EXX
  LD E,A
  LD A,(DE)
  CPL
  AND (HL)
  EXX
  OR (HL)
  EXX
  LD (HL),A
  ADD HL,BC
  INC D
  LD A,(DE)
  CPL
  AND (HL)
  EXX
  INC H
  OR (HL)
  EXX
  LD (HL),A
  INC HL
  EXX
  LD A,(BC)
  INC BC
  LD L,A
  LD A,(DE)
  INC E
  EXX
  LD E,A
  LD A,(DE)
  CPL
  AND (HL)
  EXX
  OR (HL)
  EXX
  LD (HL),A
  SBC HL,BC
  DEC D
  LD A,(DE)
  CPL
  AND (HL)
  EXX
  DEC H
  OR (HL)
  EXX
  LD (HL),A
  INC HL
  EXX
  EX AF,AF'
  DEC A
  JP NZ,l_A726
  DEC (IX+$08)
  JP NZ,l_A724
  EXX
  LD A,L
  ADD A,$08
  LD L,A
  JR NC,l_A76F
  INC H
l_A76F:
  EXX
  DEC (IX+$07)
  JP NZ,l_A71E
  RET

; The frame's mask, each byte dilated through the table $F700, into $F000
;
; Witness: L1 90197 (c1, door, play2, rzx- x9).
MakeMask:
  LD B,$F7
  LD DE,Zone1CharsLow
  LD L,(IX+$0C)
  LD H,(IX+$0D)
  EXX
  LD C,(IX+$05)
l_A786:
  EXX
  XOR A
  EX AF,AF'
  LD A,(IX+$06)
l_A78C:
  EX AF,AF'
  OR (HL)
  INC L
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC E
  DEC L
  LD A,(HL)
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC E
  DEC L
  LD A,(HL)
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC E
  DEC L
  LD A,(HL)
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC E
  DEC L
  LD A,(HL)
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC E
  DEC L
  LD A,(HL)
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC E
  DEC L
  LD A,(HL)
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC E
  DEC L
  LD A,(HL)
  INC L
  OR (HL)
  INC HL
  OR (HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  INC DE
  DEC HL
  LD A,(HL)
  INC HL
  EX AF,AF'
  DEC A
  JP NZ,l_A78C
  DEC HL
  DEC HL
  LD A,(HL)
  INC HL
  OR (HL)
  INC HL
  LD C,A
  LD A,(BC)
  DEC DE
  LD (DE),A
  INC DE
  EXX
  DEC C
  JP NZ,l_A786
  RET

; The frame mirrored through the bit-reverse table $F600 into $F300
;
; Witness: L1 9519 (c1, rzx- x9).
MirrorFrame:
  LD A,(IX+$06)
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  LD H,(IX+$0D)
  LD L,(IX+$0C)
  LD A,(IX+$05)
l_A805:
  DEC A
  JR Z,l_A80C
  ADD HL,DE
  JP l_A805
l_A80C:
  LD A,E
  NEG
  LD (l_A825+$002F),A
  LD DE,Zone1CharsLow+$0300
  LD (IX+$0D),D
  LD (IX+$0C),E
  LD B,$F6
  EXX
  LD C,(IX+$05)
l_A821:
  EXX
  LD A,(IX+$06)
l_A825:
  EX AF,AF'
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC L
  INC E
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC L
  INC E
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC L
  INC E
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC L
  INC E
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC L
  INC E
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC L
  INC E
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC L
  INC E
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC DE
  EX AF,AF'
  DEC A
  JP NZ,l_A825
  LD BC,ImTable+256
  ADD HL,BC
  ADD HL,BC
  LD B,$F6
  EXX
  DEC C
  JP NZ,l_A821
  RET

; Build the dilate table $F700, the shift tables $F800-$FDFF and the
; bit-reverse table $F600
;
; Witness: L1 16 (c1, door, play2, rzx- x8).
BuildTables:
  LD HL,PlayPanel+$0100
l_A863:
  LD A,L
  LD D,L
  ADD A,A
  SRL D
  OR D
  OR L
  LD (HL),A
  INC L
  JR NZ,l_A863
  LD HL,PlayPanel+$0200
l_A871:
  LD E,H
  LD B,$00
  LD A,L
  LD D,$03
l_A877:
  SRL A
  RR B
  RRA
  RR B
  LD (HL),A
  INC H
  LD (HL),B
  INC H
  DEC D
  JR NZ,l_A877
  LD H,E
  INC L
  JR NZ,l_A871
  LD HL,PlayPanel
l_A88C:
  LD A,L
  LD B,$08
l_A88F:
  SRL A
  RL E
  DJNZ l_A88F
  LD (HL),E
  INC L
  JR NZ,l_A88C
  RET

  ORG $C9EA

; Eight bits of the characters at $E710 ($E728 in zone 3) switched on and off
; in turn (TwinkleSteps)
;
; Witness: L1 13174 (c1, door, play2, rzx- x9).
Twinkle:
  LD HL,ZoneChars+$0710
  LD A,(ZoneSlots)
  CP $03
  JR NZ,l_C9F7
  LD HL,ZoneChars+$0728
l_C9F7:
  LD DE,TwinkleSteps
  LD B,$00
  LD A,$08
l_C9FE:
  LD (l_CA2A+$0006),A
  PUSH HL
  LD A,(DE)
  BIT 7,A
  JR NZ,l_CA19
  AND $07
  DEC A
  LD C,A
  ADD HL,BC
  LD (HL),$FF
  AND A
  JR Z,l_CA14
  LD (DE),A
  JR l_CA2A
l_CA14:
  LD A,$80
  LD (DE),A
  JR l_CA2A
l_CA19:
  AND $07
  LD C,A
  ADD HL,BC
  LD (HL),$00
  INC A
  CP $07
  JR Z,l_CA29
  OR $80
  LD (DE),A
  JR l_CA2A
l_CA29:
  LD (DE),A
l_CA2A:
  POP HL
  LD C,$08
  ADD HL,BC
  INC DE
  LD A,$00
  DEC A
  JR NZ,l_C9FE
  RET

; The eight steps' states
TwinkleSteps:
  DEFB $80,$81,$82,$83,$84,$85,$86,$07

; Zone 0: move the lift (characters $69 / $6B) up and down its shaft
;
; Witness: L1 13174 (c1, door, play2, rzx- x9).
AnimateLift:
  LD HL,(LiftPlace)
  LD A,H
  OR L
  RET Z
  LD A,(LiftPlace+$0002)
  AND A
  JR NZ,l_CA6E
  LD A,(HL)
  CP $69
  JR Z,l_CA53
  LD A,$69
  JP l_CA9B
l_CA53:
  INC HL
  LD A,(HL)
  AND A
  JR Z,l_CA66
  DEC HL
  LD (LiftPlace),HL
  OR $FF
  LD (LiftPlace+$0002),A
  LD A,$6B
  JP l_CA9B
l_CA66:
  LD (LiftPlace),HL
  LD A,$6B
  JP l_CA9B
l_CA6E:
  LD A,(HL)
  CP $6B
  JR Z,l_CA78
  LD A,$6B
  JP l_CA9B
l_CA78:
  DEC HL
  LD A,(HL)
  CP $69
  JR NZ,l_CA92
  LD (LiftPlace),HL
  INC HL
  XOR A
  LD (HL),A
  LD DE,$0020
  ADD HL,DE
  LD (HL),A
  INC H
  INC H
  INC H
  INC A
  LD (HL),A
  SBC HL,DE
  LD (HL),A
  RET
l_CA92:
  INC HL
  LD (LiftPlace),HL
  XOR A
  LD (LiftPlace+$0002),A
  RET
l_CA9B:
  LD (HL),A
  LD DE,$0020
  ADD HL,DE
  INC A
  LD (HL),A
  INC H
  INC H
  INC H
  LD (HL),$01
  AND A
  SBC HL,DE
  LD (HL),$01
  RET

; Mark every AnimatedCells cell dirty
;
; Witness: L1 13174 (c1, door, play2, rzx- x9).
MarkAnimated:
  LD HL,AnimatedCells
  LD A,$01
l_CAB2:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  BIT 7,D
  RET Z
  LD (DE),A
  JP l_CAB2

; Three counters: 0-7, 5-0, 0-11, and frame tables at $CAC0 and $CAC7
AnimSteps:
  DEFB $00,$00,$00,$00,$01,$02,$03,$02
  DEFB $01,$00,$00,$01,$02,$03,$02,$01

; Each pass: copy the zone's next animation frames into its live characters,
; the lift, the twinkle
;
; Witness: L1 13174 (c1, door, play2, rzx- x9).
AnimateZone:
  CALL MarkAnimated
  CALL AnimateLift
  LD HL,AnimSteps
  LD A,(HL)
  INC A
  AND $07
  LD (HL),A
  INC HL
  LD A,(HL)
  DEC A
  JP P,l_CAE3
  LD A,$05
l_CAE3:
  LD (HL),A
  INC HL
  LD A,(HL)
  INC A
  CP $0C
  JR NZ,l_CAEC
  XOR A
l_CAEC:
  LD (HL),A
  LD A,(ZoneSlots)
  AND A
  JR NZ,AnimateZone1
  LD A,(AnimSteps)
  RRCA
  RRCA
  RRCA
  LD E,A
  LD D,$00
  LD HL,ZoneChars+$0600
  ADD HL,DE
  LD DE,ZoneChars+$0300
  LD BC,$0020
  LDIR
  LD A,(AnimSteps+$0001)
  RRCA
  RRCA
  RRCA
  LD E,A
  LD D,$00
  LD HL,ZoneChars+$0210
  ADD HL,DE
  LD DE,ZoneChars+$0758
  LD BC,$0020
  LDIR
  LD A,(AnimSteps)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,ZoneChars+$0460
  ADD HL,DE
  LD DE,ZoneChars+$04E0
  PUSH HL
  PUSH DE
  LD BC,$0010
  LDIR
  POP DE
  POP HL
  INC H
  INC D
  LD BC,$0010
  LDIR
  JP Twinkle

; the last random frame (zone 1)
AnimLast:
  DEFB $00

; AnimateZone1
;
; Used by the routine at AnimateZone.
AnimateZone1:
  CP $01                  ; zone 1
  JP NZ,l_CBBB
  LD A,(AnimSteps)
  RRCA
  RRCA
  RRCA
  LD L,A
  LD H,$00
  LD DE,ZoneChars+$0400
  ADD HL,DE
  LD DE,ZoneChars+$0288
  LD A,E
  LD BC,$0010
  LDIR
  LD E,A
  INC D
  LD BC,$0010
  LDIR
  LD A,(AnimSteps+$0001)
  RRCA
  RRCA
  RRCA
  LD L,A
  LD H,$00
  LD DE,ZoneChars+$0630
  ADD HL,DE
  LD DE,ZoneChars+$0600
  LD BC,$0010
  LD A,E
  LDIR
  LD E,A
  INC D
  LD BC,$0010
  LDIR
  LD A,(AnimLast)
  AND A
  JR NZ,l_CB97
  LD A,(AnimSteps+$0001)
  CP $05
  JP NZ,Twinkle
  CALL Random
  AND $07
  JP NZ,Twinkle
l_CB97:
  LD A,(AnimSteps+$0001)
  LD (AnimLast),A
  LD L,A
  LD H,$00
  LD DE,AnimSteps+$0003
  ADD HL,DE
  LD A,(HL)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,ZoneChars+$0788
  ADD HL,DE
  LD DE,ZoneChars+$0508
  LD BC,$0010
  LDIR
  JP Twinkle

; l_CBBB
;
; Used by the routine at AnimateZone1.
l_CBBB:
  CP $02
  JR NZ,l_CBDF
  LD A,(AnimSteps+$0001)
  LD L,A
  LD H,$00
  LD DE,AnimSteps+$000A
  ADD HL,DE
  LD A,(HL)
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,ZoneChars+$03A0
  ADD HL,DE
  LD DE,ZoneChars+$0360
  LD BC,$0008
  LDIR
  JP Twinkle
l_CBDF:
  LD A,(AnimSteps+$0002)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,ZoneChars+$0580
  ADD HL,DE
  LD DE,ZoneChars+$0700
  LD BC,$0020
  LDIR
  JP Twinkle
