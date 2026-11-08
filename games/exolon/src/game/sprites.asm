; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The sprite drawers: 24x32 and 16x16, shifted, masked by the open cells
; --------------------------------------------------------------------------------------------------------------------

; Moves a 24x32 sprite (the player): erases its previous image, draws frame A
; at DE with masking and edge clipping
;
; A = the frame (96 bytes at $EF80 + 96 A, 3 bytes a line, 32 lines), DE = the
; new x (2-pixel steps), y; BC = the old x, y; HL = the 128-byte buffer holding
; the previous image as drawn (HL = $B101, 128 zero bytes: nothing to erase,
; and the new image is not kept). Keeps every register.
;
; Each line is shifted right by (2x AND 7) pixels into 4 bytes of ShiftBuffer
; $78DC through BigShiftJumps $78CA (shifts of 4 and 6 are done as 4 and 2 left
; shifts into the byte before). Then BigSpriteMask: the foreground map $5B00
; cells under the new place cut the image where they are 0, and x from $75 on
; clips the columns past the right edge. Then the old image is XORed off at the
; old place and the new XORed on at the new, line by line, and the new image is
; copied into the buffer.
;
; Called by $8229 (the player). c1: 980 draws, the warp runs 35 344.
DrawBigSprite:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH HL
  PUSH BC
  PUSH HL
  PUSH DE
  LD L,A                  ; HL = 96 A + $EF80: the frame's first line
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,E
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,DE
  LD DE,PlayerFrames
  ADD HL,DE
  LD (SpriteSavedSP),SP   ; SP = the frame, read with POP
  LD SP,HL
  ADD A,A                 ; the shift (2x AND 7: 0, 2, 4 or 6 pixels) picks the
                          ; routine
  AND $07
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,BigShiftJumps
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD IX,$0000
  ADD IX,DE
  LD HL,ShiftBuffer       ; 32 lines into ShiftBuffer
  LD A,$20

; One line of a 24-wide frame: C, B, E = its three bytes, D = 0 for the fourth,
; then the shift routine
;
; The loop head of DrawBigSprite's shift: POP BC, POP DE, DEC SP takes three
; bytes, and JP (IX) runs the shift routine picked from BigShiftJumps; each
; ends by storing four bytes at HL and coming back here for 32 lines, then
; BigSpriteMask.
BigSpriteRow:
  POP BC
  POP DE
  DEC SP
  LD D,$00
  JP (IX)

; A 24-wide line shifted 4 pixels left into D C B E (a 4-pixel right shift from
; the byte before)
;
; Four rounds of RL E / RL B / RL C / RL D, then the store (BigShiftLeft2's
; tail). The entry at $7721 (3 left) and $7731 (1 left) are for odd pixel
; shifts, which x in 2-pixel steps never asks for.
BigShiftLeft4:
  RL E
  RL B
  RL C
  RL D
  RL E
  RL B
  RL C
  RL D

; A 24-wide line shifted 2 pixels left into D C B E (6 right from the byte
; before), stored D, C, B, E at HL
BigShiftLeft2:
  RL E
  RL B
  RL C
  RL D
  RL E
  RL B
  RL C
  RL D
  LD (HL),D               ; the four bytes into ShiftBuffer
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),E
  INC HL
  DEC A
  JP NZ,BigSpriteRow
  JP BigSpriteMask

; An extra pixel of right shift (3 in all with BigShiftRight2): never ran, x
; counts 2-pixel steps so the shift is even
;
; RR C / RR B / RR E / RR D, then BigShiftRight2. BigShiftJumps' entry 3 points
; here; DrawBigSprite only picks the even entries 0, 2, 4, 6. Never ran in any
; recording.
BigShiftRight3:
  RR C
  RR B
  RR E
  RR D

; A 24-wide line shifted 2 pixels right (C B E D), stored by BigShiftNone
;
; The entry at $7758 (1 right) is for odd shifts, never asked.
BigShiftRight2:
  RR C
  RR B
  RR E
  RR D
  RR C
  RR B
  RR E
  RR D

; Stores the line's four bytes C, B, E, D at HL; 32 lines, then BigSpriteMask
BigShiftNone:
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DEC A
  JP NZ,BigSpriteRow

; DrawBigSprite's second half: the foreground mask, the right-edge clip, then
; the XOR erase and draw
;
; HL = the new place's screen address ($B088), patched into BigNewScreen. The
; foreground map $5B00 (the cell = the screen address's third and low byte) is
; ANDed over the 4 x 4 cells (5 rows when y is not a multiple of 8): $FF means
; no foreground cell, else BigMaskRows cuts the image by the map, the first
; cell row for 8 - (y AND 7) lines, then full cell rows, the last for the rest
; (BigMaskTail).
;
; x from $75 on (the sprite reaching the right edge) masks the bytes that would
; wrap to the next line: $75-$77 keeps three bytes, $78-$7B two, $7C and over
; only the first (w runs: 1444 times as the player walks off the right).
;
; Then BigXorLoop: 32 lines, the new image (POP from ShiftBuffer) XORed at the
; new address in the alternate registers, the old one (the buffer at DE) XORed
; at the old address; then the 128 bytes copied into the buffer unless it is
; $B101.
BigSpriteMask:
  LD SP,(SpriteSavedSP)
  POP DE
  CALL PixelAddress
  LD (BigNewScreen+$0001),HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  PUSH DE
  LD BC,OpenCells
  ADD HL,BC
  PUSH HL
  LD A,D
  LD DE,$001D
  LD B,$04
  AND $07
  JR Z,BigMapAnd
  INC B
BigMapAnd:
  LD A,$FF                ; A = $FF AND the map cells: $FF = no foreground over
                          ; the sprite
BigMapRow:
  AND (HL)                ; four cells a row
  INC HL
  AND (HL)
  INC HL
  AND (HL)
  INC HL
  AND (HL)
  ADD HL,DE
  DJNZ BigMapRow
  POP HL
  POP DE
  EX AF,AF'
  LD A,E                  ; x < $75: no clipping
  CP $75
  JP C,BigMaskTest
  EXX                     ; clip at the right edge: D, E, C the masks of bytes
                          ; 1-3
  LD HL,ShiftBuffer+$0001
  CP $7C
  LD DE,$0000
  LD C,D
  JR NC,BigClipMasks
  CP $78
  LD DE,$FF00
  LD C,E
  JR NC,BigClipMasks
  LD DE,$FFFF
  LD C,$00
BigClipMasks:
  LD B,$20                ; 32 lines
BigClipLine:
  LD A,D                  ; bytes 1, 2, 3 of the line masked (byte 0 always
                          ; stays)
  AND (HL)
  LD (HL),A
  INC HL
  LD A,E
  AND (HL)
  LD (HL),A
  INC HL
  LD A,C
  AND (HL)
  LD (HL),A
  INC HL
  INC HL
  DJNZ BigClipLine
  EXX
BigMaskTest:
  EX AF,AF'               ; Z: a foreground cell is under the sprite
  JR NZ,BigEraseDraw
  LD A,$08
  LD (BigMaskTail+$0001),A
  LD A,D
  AND $07
  LD DE,ShiftBuffer
  JR Z,BigMaskFull
  LD (BigMaskTail+$0001),A
  LD B,A
  LD A,$08
  SUB B
  LD B,A
  LD DE,ShiftBuffer
  CALL BigMaskRows
BigMaskFull:
  CALL BigMaskRows8       ; three full cell rows
  CALL BigMaskRows8
  CALL BigMaskRows8
BigMaskTail:
  LD B,$00                ; LD B,n: the last cell row's line count (patched)
  CALL BigMaskRows
BigEraseDraw:
  POP HL                  ; HL = the old place's address; the buffer into DE
  POP DE
  LD B,H
  LD C,L
  CALL PixelAddress
  LD D,B
  LD E,C
  LD C,$07
  EXX
BigNewScreen:
  LD HL,$0000             ; LD HL,n: the new place's screen address (patched)
  LD (SpriteSavedSP),SP
  LD SP,ShiftBuffer
  LD BC,$2007
BigXorLoop:
  POP DE                  ; the new line from ShiftBuffer XORed on
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  POP DE
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  DEC L
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,BigOldLine
  LD A,L
  ADD A,$20
  LD L,A
  JR C,BigOldLine
  LD A,H
  SUB $08
  LD H,A
BigOldLine:
  EXX                     ; the old line from the buffer XORed off
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,BigXorNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,BigXorNext
  LD A,H
  SUB $08
  LD H,A
BigXorNext:
  EXX                     ; 32 lines
  DJNZ BigXorLoop
  LD SP,(SpriteSavedSP)
  POP DE
  PUSH DE
  AND A
  LD HL,NoSaveBuffer      ; buffer $B101: the image is not kept
  SBC HL,DE
  JR Z,BigSpriteDone
  LD HL,ShiftBuffer
  LD BC,$0080
BigKeepImage:
  LDI                     ; 128 bytes into the buffer
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  JP PE,BigKeepImage
BigSpriteDone:
  POP HL
  POP IX
  POP DE
  POP BC
  POP AF
  RET

; BigMaskRows for a full cell row (B = 8)
;
; Used by the routine at BigSpriteMask.
BigMaskRows8:
  LD B,$08

; Cuts B lines of ShiftBuffer by one row of four foreground map cells
;
; HL = the map row: its 4 bytes are patched into the AND n of BigMaskLine (3)
; and C (the fourth); B lines of 4 bytes at DE ANDed with them (0 hides that
; column of the sprite behind the foreground). HL moves on to the next map row
; ($1D + 3).
BigMaskRows:
  LD A,(HL)
  LD (BigMask0+$0001),A
  INC HL
  LD A,(HL)
  LD (BigMask1+$0001),A
  INC HL
  LD A,(HL)
  LD (BigMask2+$0001),A
  INC HL
  LD C,(HL)
BigMaskLine:
  LD A,(DE)
BigMask0:
  AND $00                 ; AND n: the first cell (patched)
  LD (DE),A
  INC DE
  LD A,(DE)
BigMask1:
  AND $00                 ; AND n: the second cell (patched)
  LD (DE),A
  INC DE
  LD A,(DE)
BigMask2:
  AND $00                 ; AND n: the third cell (patched)
  LD (DE),A
  INC DE
  LD A,(DE)
  AND C
  LD (DE),A
  INC DE
  DJNZ BigMaskLine
  LD BC,$001D
  ADD HL,BC
  RET

; DrawBigSprite's shift routines by (2x AND 7): 0, right 1-3, left 4-1
;
; Entry n for a right shift of n pixels: $7760 (0), $7758, $7750 (2), $7748,
; $7719 (4: four left), $7721, $7729 (6: two left), $7731. Only the even
; entries are used.
BigShiftJumps:
  DEFW BigShiftNone,$7758,BigShiftRight2,BigShiftRight3,BigShiftLeft4,$7721,BigShiftLeft2,$7731

; The caller's SP while a sprite routine reads with POP (DrawBigSprite,
; DrawSprite, ScrollHallOfFame, $931C, $9355)
SpriteSavedSP:
  DEFW $0000

; The shifted and masked sprite image: 32 lines of 4 bytes (DrawBigSprite) or
; 16 lines of 3 (DrawSprite)
ShiftBuffer:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Moves a 16x16 sprite: erases its previous image, draws frame A at DE masked
; by the foreground map
;
; A = the frame (32 bytes at $F8E0 + 32 A, 2 bytes a line, 16 lines), DE = the
; new x (2-pixel steps), y; BC = the old x, y; HL = the 48-byte buffer of the
; previous image ($B101: nothing to erase, not kept). Keeps every register.
;
; Each line is shifted into 3 bytes of ShiftBuffer through SpriteShiftJumps
; $7AD9, the foreground map $5B00 cuts it (SpriteMask, MaskRows), then the old
; image is XORed off at the old place and the new on at the new one, and the 48
; bytes are kept in the buffer. No right-edge clip.
;
; Callers: DrawSparkle (the menu stars), $9E99, $9FBD, $A26B, $A367, $A62D,
; $A7D6, $AC7D. c1: 42 144 draws from the menu alone.
DrawSprite:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH HL
  PUSH BC
  PUSH HL
  PUSH DE
  LD L,A                  ; HL = 32 A + $F8E0: the frame
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,E
  LD DE,Sprites16
  ADD HL,DE
  LD (SpriteSavedSP),SP   ; SP = the frame, read with POP
  LD SP,HL
  ADD A,A                 ; the shift (2x AND 7) picks the routine
  AND $07
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,SpriteShiftJumps
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD IX,$0000
  ADD IX,DE
  LD HL,ShiftBuffer       ; 16 lines into ShiftBuffer
  LD B,$10

; One line of a 16-wide frame: E, D = its two bytes, A = 0 for the third, then
; the shift routine
;
; Used by the routines at ShiftLeft2 and ShiftNone.
SpriteRow:
  POP DE
  XOR A
  JP (IX)

; A 16-wide line shifted 4 pixels left into A E D (4 right from the byte
; before)
;
; The entry at $7999 (3 left) is for odd shifts, never asked.
ShiftLeft4:
  SLA D
  RL E
  RLA
  SLA D
  RL E
  RLA

; A 16-wide line shifted 2 pixels left into A E D, stored A, E, D at HL; 16
; lines, then SpriteMask
;
; The entry at $79A3 (1 left) is for odd shifts.
ShiftLeft2:
  SLA D
  RL E
  RLA
  SLA D
  RL E
  RLA
  LD (HL),A
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DJNZ SpriteRow
  JP SpriteMask

; An extra pixel of right shift (3 in all with ShiftRight2): never ran, x
; counts 2-pixel steps
;
; SRL E / RR D / RRA, then ShiftRight2. SpriteShiftJumps' entry 3; DrawSprite
; only picks the even entries. Never ran in any recording.
ShiftRight3:
  SRL E
  RR D
  RRA

; A 16-wide line shifted 2 pixels right (E D A), stored by ShiftNone
;
; The entry at $79BD (1 right) is for odd shifts.
ShiftRight2:
  SRL E
  RR D
  RRA
  SRL E
  RR D
  RRA

; Stores the line's three bytes E, D, A at HL; 16 lines, then SpriteMask
ShiftNone:
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),A
  INC HL
  DJNZ SpriteRow

; DrawSprite's second half: the foreground mask, then the XOR erase and draw
;
; As BigSpriteMask for 3 x 2 cells (3 rows when y is not a multiple of 8),
; without the edge clip: MaskRows cuts the image where a foreground cell is;
; then 16 lines XORed (the new from ShiftBuffer at SmallNewScreen, the old from
; the buffer) and the 48 bytes kept unless the buffer is $B101.
SpriteMask:
  LD SP,(SpriteSavedSP)
  POP DE
  CALL PixelAddress
  LD (SmallNewScreen+$0001),HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  PUSH DE
  LD BC,OpenCells
  ADD HL,BC
  PUSH HL
  LD A,D
  LD DE,$001E
  LD B,$02
  AND $07
  JR Z,SpriteMapAnd
  INC B
SpriteMapAnd:
  LD A,$FF                ; A = $FF AND the map cells
SpriteMapRow:
  AND (HL)                ; three cells a row
  INC L
  AND (HL)
  INC L
  AND (HL)
  ADD HL,DE
  DJNZ SpriteMapRow
  POP HL
  POP DE
  JR NZ,SpriteEraseDraw
  LD A,$08
  LD (SpriteMaskTail+$0001),A
  LD A,D
  AND $07
  LD DE,ShiftBuffer
  JR Z,SpriteMaskFull
  LD (SpriteMaskTail+$0001),A
  LD B,A
  LD A,$08
  SUB B
  LD B,A
  LD DE,ShiftBuffer
  CALL MaskRows
SpriteMaskFull:
  CALL MaskRows8          ; one full cell row
SpriteMaskTail:
  LD B,$00                ; LD B,n: the last cell row's line count (patched)
  CALL MaskRows
SpriteEraseDraw:
  POP HL                  ; HL = the old place's address; the buffer into DE
  POP DE
  LD B,H
  LD C,L
  CALL PixelAddress
  LD D,B
  LD E,C
  LD C,$07
  EXX
SmallNewScreen:
  LD HL,$0000             ; LD HL,n: the new place's screen address (patched)
  LD (SpriteSavedSP),SP
  LD SP,ShiftBuffer
  LD BC,$1007
SpriteXorLoop:
  POP DE                  ; the new line from ShiftBuffer XORed on
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  POP DE
  LD A,E
  XOR (HL)
  LD (HL),A
  DEC SP
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,SpriteOldLine
  LD A,L
  ADD A,$20
  LD L,A
  JR C,SpriteOldLine
  LD A,H
  SUB $08
  LD H,A
SpriteOldLine:
  EXX                     ; the old line from the buffer XORed off
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,SpriteXorNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,SpriteXorNext
  LD A,H
  SUB $08
  LD H,A
SpriteXorNext:
  EXX                     ; 16 lines
  DJNZ SpriteXorLoop
  LD SP,(SpriteSavedSP)
  POP DE
  PUSH DE
  AND A
  LD HL,NoSaveBuffer
  SBC HL,DE
  JR Z,SpriteDone
  LD HL,ShiftBuffer
  LD BC,$0030
SpriteKeepImage:
  LDI                     ; 48 bytes into the buffer
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  JP PE,SpriteKeepImage
SpriteDone:
  POP HL
  POP IX
  POP DE
  POP BC
  POP AF
  RET

; MaskRows for a full cell row (B = 8)
;
; Used by the routine at SpriteMask.
MaskRows8:
  LD B,$08

; Cuts B lines of ShiftBuffer by one row of three foreground map cells
;
; HL = the map row: 2 bytes into the AND n of MaskLine and C the third; B lines
; of 3 bytes at DE ANDed; HL to the next map row ($1E + 2).
MaskRows:
  LD A,(HL)
  LD (Mask0+$0001),A
  INC HL
  LD A,(HL)
  LD (Mask1+$0001),A
  INC HL
  LD C,(HL)
MaskLine:
  LD A,(DE)
Mask0:
  AND $00                 ; AND n: the first cell (patched)
  LD (DE),A
  INC DE
  LD A,(DE)
Mask1:
  AND $00                 ; AND n: the second cell (patched)
  LD (DE),A
  INC DE
  LD A,(DE)
  AND C
  LD (DE),A
  INC DE
  DJNZ MaskLine
  LD BC,$001E
  ADD HL,BC
  RET

; DrawSprite's shift routines by (2x AND 7): 0, right 1-3, left 4-1
;
; $79C2 (0), $79BD, $79B8 (2), $79B3, $7994 (4: four left), $7999, $799E (6:
; two left), $79A3. Only the even entries are used.
SpriteShiftJumps:
  DEFW ShiftNone,$79BD,ShiftRight2,ShiftRight3,ShiftLeft4,$7999,ShiftLeft2,$79A3
