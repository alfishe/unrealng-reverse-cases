; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the back buffer, the sprites, the animated cells
; --------------------------------------------------------------------------------------------------------------------

; Clear the back buffer's play lines $EB00-$FFFF with PUSH (the stack from
; $FFFF down)
;
; As REX 1's ClearBuffer $B205 (src/game/render.asm).
;
; Witness: L1 10902 (c2, p2-room20, rzx-p2- x21).
ClearBuffer:
  LD (Temp1),SP
  LD SP,$FFFF
  LD B,$2A
  LD HL,$0000
ClearBufferLoop:
  PUSH HL                 ; PUSH HL x 16 a line
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearBufferLoop
  LD SP,(Temp1)
  RET

; OR a picture into the back buffer: SpriteX/SpriteY, SpriteWidth/Height
; (written into the loop at $B2EE, $B2F2 or $B35E, $B362), the object's own
; picture when bit 7 of $A1CC; A non-zero draws it mirrored through MirrorTable
; $AE52
;
; Changed from REX 1's DrawSprite $B258 (src/game/render.asm).
;
; Witness: L1 57786 (c2, p2-room20, rzx-p2- x21).
DrawSprite:
  PUSH DE
  OR A
  JP NZ,DrawMirrored
  LD A,(SpriteX)
  AND $07
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  LD D,$00
  POP HL
  ADD HL,DE
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD (SpriteX),A
  PUSH HL
  LD A,(SpriteY)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,AttrShadowPlay+$03A0
  ADD HL,DE
  LD A,(SpriteX)
  LD E,A
  LD D,$00
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH DE
  LD A,(SpriteWidth)
  LD (DrawSpriteBytes+$0001),A
  LD A,(SpriteHeight)
  LD (DrawSpriteRows+$0001),A
  EX DE,HL
  LD A,(SpriteMirror)
  BIT 7,A
  JP Z,DrawSpriteStore
  LD DE,(SpritePicture)
DrawSpriteStore:
  LD (SpriteSource),DE    ; the picture kept in $A25E (never read)
DrawSpritePlain:
  POP HL                  ; not mirrored
DrawSpriteRows:
  LD B,$00                ; LD B,rows: the height written by DrawSprite
DrawSpriteRow:
  PUSH BC                 ; each line
  PUSH HL
DrawSpriteBytes:
  LD B,$00                ; LD B,bytes: the width written by DrawSprite
DrawSpriteByte:
  LD A,(DE)               ; each byte: OR into the buffer
  OR (HL)
  LD (HL),A
  INC DE
  INC HL
  DJNZ DrawSpriteByte
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ DrawSpriteRow
  RET
DrawMirrored:
  LD A,(SpriteX)          ; DrawSprite facing left: the picture's bytes right
                          ; to left through MirrorTable $AE52
  LD DE,$0007
  ADD HL,DE
  AND $07
  LD E,A
  LD D,$00
  AND A
  SBC HL,DE
  LD E,(HL)
  LD D,$00
  POP HL
  ADD HL,DE
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD (SpriteX),A
  PUSH HL
  LD A,(SpriteY)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,AttrShadowPlay+$03A0
  ADD HL,DE
  LD A,(SpriteX)
  LD E,A
  LD D,$00
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH DE
  LD A,(SpriteWidth)
  LD (DrawMirroredBytes+$0001),A
  LD A,(SpriteHeight)
  LD (DrawMirroredRows+$0001),A
  EX DE,HL
  LD A,(SpriteMirror)
  BIT 7,A
  JP Z,DrawMirroredStore
  LD DE,(SpritePicture)
DrawMirroredStore:
  LD (SpriteSource),DE    ; the same
DrawMirroredStart:
  POP HL
  INC HL
  INC HL
DrawMirroredRows:
  LD B,$00                ; LD B,rows: written by DrawMirrored
DrawMirroredRow:
  PUSH BC                 ; each line
  PUSH HL
DrawMirroredBytes:
  LD B,$00                ; LD B,bytes: written by DrawMirrored
DrawMirroredByte:
  LD A,(DE)               ; each byte through MirrorTable
  PUSH DE
  PUSH HL
  LD E,A
  LD D,$00
  LD HL,MirrorTable
  ADD HL,DE
  LD A,(HL)
  POP HL
  POP DE
  OR (HL)
  LD (HL),A
  INC DE
  DEC HL
  DJNZ DrawMirroredByte
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ DrawMirroredRow
  RET

; LD SP,(Temp2): RET: DrawAnimCells' exit with the stack it saved
;
; As REX 1's ReturnToStack $B339 (src/game/render.asm).
;
; Witness: L1 10901 (c2, p2-room20, rzx-p2- x21).
ReturnToStack:
  LD SP,(Temp2)
  RET

; Draw every scenery cell of the room (SceneryCellList $D962) into the back
; buffer, the stack as the list pointer
;
; As REX 1's DrawAnimCells $B33E (src/game/render.asm).
;
; Witness: L1 10902 (c2, p2-room20, rzx-p2- x21).
DrawAnimCells:
  LD (Temp2),SP
  LD SP,SceneryCellList
DrawAnimCellLoop:
  POP HL                  ; each listed cell
  POP DE
  LD A,L
  INC A
  JP Z,ReturnToStack
  LD BC,$0020
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  JP DrawAnimCellLoop

; Fire: a shot of the current weapon if a slot is free (once a press, only
; while Rex is present)
;
; Witness: L1 1261 (c2, p2-room20, rzx-p2- x21).
FireWeapon:
  LD A,(FireLatch)
  OR A
  RET NZ
  LD A,(RexPresent)
  OR A
  RET Z
  LD A,$01
  LD (FireLatch),A
  CALL FindShotSlot
  LD A,(Weapon)
  OR A
  JP Z,FireGun
  LD A,$01
FireGun:
  CALL PowerDrain         ; the gun
  LD A,(RapidShotsOn)
  OR A
  JP Z,FireByWeapon
  LD A,(RapidShotsLeft)
  DEC A
  LD (RapidShotsLeft),A
  OR A
  JP NZ,FireByWeapon
  XOR A
  LD (RapidShotsOn),A
FireByWeapon:
  LD A,(Weapon)           ; the shot by weapon
  CP $04
  JP Z,FireSpray
  CP $02
  JP Z,FireLaser
  CALL RexShot
  LD (IY+$05),$00
  LD A,(Weapon)
  CP $01
  JP Z,FireDouble
  CP $03
  RET NZ
  LD A,(SparkleMode)
  OR A
  RET NZ
  LD A,(PowerLevel)
  ADD A,$03
  LD B,A
  LD HL,$5E4E
FireDroneShots:
  PUSH BC                 ; one shot from each drone
  CALL FindShotSlot
  LD A,(HL)
  LD (Temp1),A
  LD A,(RexFacing)
  LD A,$01
  LD (Temp3),A
  LD A,(RexX)
  CP (HL)
  JP NC,FireDroneDir
  XOR A
  LD (Temp3),A
FireDroneDir:
  LD A,(HL)               ; the shot's direction
  INC HL
  CP $F0
  JP NC,FireDroneNext
  LD A,(HL)
  LD (Temp2),A
  LD A,$03
  LD (Temp4),A
  XOR A
  PUSH HL
  CALL SetupShot
  POP HL
FireDroneNext:
  LD DE,$0002             ; the next drone
  ADD HL,DE
  POP BC
  DJNZ FireDroneShots
  RET
