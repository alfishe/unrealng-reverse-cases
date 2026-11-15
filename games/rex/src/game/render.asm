; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the back buffer, the sprites, the animated cells
;
; The play area is drawn in a back buffer of 32-byte lines ($E800 + 32 x line; the play's 168 lines are $EB00-$FFFF)
; and copied to the screen once a pass (BufferToScreen $A28A). ClearBuffer empties it with PUSH; DrawSprite ORs a pre-
; shifted picture into it (width and height written into its own loop operands), DrawMirrored the same through
; MirrorTable for a picture facing left.
; --------------------------------------------------------------------------------------------------------------------

; Clear the back buffer's play lines $EB00-$FFFF with PUSH (the stack from
; $FFFF down)
;
; Witness: L1 18688 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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

; OR a picture into the back buffer: HL its frame list, DE the picture,
; SpriteX/SpriteY, SpriteWidth/Height (written into the loop at $B2AC, $B2B0);
; A non-zero draws it mirrored
;
; Witness: L1 106778 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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
  LD DE,SpriteBufferOrigin
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
  JP Z,DrawSpritePlain
  LD DE,(SpritePicture)
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

; DrawSprite facing left: the picture's bytes right to left through MirrorTable
; $AD5D
;
; Witness: L1 30331 (c1, p1-code, p1-cursor, p1-gameover, p1-kempston,
; p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x32).
DrawMirrored:
  LD A,(SpriteX)
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
  LD DE,SpriteBufferOrigin
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
  JP Z,DrawMirroredStart
  LD DE,(SpritePicture)
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
; Witness: L1 18691 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
ReturnToStack:
  LD SP,(Temp2)
  RET

; Draw every scenery cell of the room (SceneryCellList $D962) into the back
; buffer, the stack as the list pointer
;
; Witness: L1 18698 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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
