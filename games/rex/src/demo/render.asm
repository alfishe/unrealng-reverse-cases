; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the back buffer, the sprites, the animated cells
; --------------------------------------------------------------------------------------------------------------------

; Clear the back buffer's play lines $EB00-$FFFF with PUSH (the stack from
; $FFFF down)
;
; As REX 1's ClearBuffer $B205 (src/game/render.asm).
;
; Witness: L1 6764 (d1, demo-cycle).
ClearBuffer:
  LD (Temp1),SP
  LD SP,$FFFF
  LD B,$2A
  LD HL,$0000
l_BACF:
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
  PUSH HL
  DJNZ l_BACF
  LD SP,(Temp1)
  RET

; OR a picture into the back buffer: SpriteX/Y, SpriteWidth/Height (written
; into the loop at $BB6A, $BB6E; mirrored $BBD7, $BBDB); the picture is the
; word of the frame list HL for X & 7, or SpritePicture when bit 7 of
; SpriteMirror; A non-zero draws it mirrored (DrawMirrored)
;
; Changed from REX 1's DrawSprite $B258 (src/game/render.asm).
;
; Witness: L1 30606 (d1, demo-cycle).
DrawSprite:
  OR A
  JP NZ,DrawMirrored
  LD A,(SpriteX)
  AND $0F
  SLA A
  AND $0F
  LD E,A
  LD D,$00
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
  LD E,(HL)
  INC HL
  LD D,(HL)
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
DrawMirrored:
  LD A,(SpriteX)            ; DrawSprite facing left: the picture's bytes right
                          ; to left through MirrorTable $AE0E
  LD DE,$000E
  ADD HL,DE
  AND $0F
  SLA A
  AND $0F
  LD E,A
  LD D,$00
  AND A
  SBC HL,DE
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
  LD E,(HL)
  INC HL
  LD D,(HL)
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
; This entry point is used by the routine at DrawAnimCells.
ReturnToStack:
  LD SP,(Temp2)           ; LD SP,(Temp2): RET: DrawAnimCells' exit with the
                          ; stack it saved
  RET

; Draw every scenery cell of the room (SceneryCellList $DBF6) into the back
; buffer, the stack as the list pointer
;
; As REX 1's DrawAnimCells $B33E (src/game/render.asm).
;
; Witness: L1 6764 (d1, demo-cycle).
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
