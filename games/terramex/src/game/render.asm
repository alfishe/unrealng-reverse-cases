; --------------------------------------------------------------------------------------------------------------------
; render.asm: The back buffer, the sprite plotter and the floor items
; --------------------------------------------------------------------------------------------------------------------

  ORG $9B22

; Draw the five actors and the items of one main-loop pass and update the
; screen
;
; Called once a pass by the main loop at $9040 (26 517 calls over the 34
; builds). The actor slots ActorSlots $5B04 hold 5 records of 4 bytes (X, Y,
; frame, flags; slot 0 the hero).
;
; 1. For each slot BufferAddress $9CEE gives the back-buffer address of (X, Y)
; and the row plotter for X mod 8; both go to the slot's record in ActorRects
; $5B44 (slot + $40: the address, slot + $42: the plotter).
;
; 2. Each slot's sprite, frame F at $6000 + 72 * F, is drawn into the back
; buffer in three columns of 24 rows (DrawSpriteColumn $9C6A). Flags bit 7 set
; (facing left) patches the two MirrorPatch points $9C82/$9C87 to LD L,A / LD
; A,(HL), so each byte is bit-reversed through the table at $FE00, and draws
; the columns right to left; bit 7 clear patches them to two NOPs. The L1
; arrivals record these writes in 21 builds ($9B82/$9B85 or $9B9C/$9B9F). After
; slot 0 WellFront $9A09 may paint the well over the hero.
;
; 3. DrawItems $9DE3 draws the floor items into the buffer and the screen at
; once. 4. CopyRects $9BEB copies the 4-byte by 24-row rectangles of last
; pass's positions (PrevActorRects $5B24, through IX = $5AE4) and of this
; pass's ($5B44) from the buffer to the screen: the old places get their
; background back and the new ones the sprites, with no flicker. 5. $5B44 is
; saved to $5B24, the alternate set's effects run ($92BD) and
; RestoreActorBackgrounds $9D3C repaints the buffer under the five actors from
; the tile map, ready for the next pass.
;
; Witness: L1 26515 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
RenderPass:
  LD IX,Hero
  LD B,$05
RenderPassAddresses:
  PUSH BC                 ; step 1: 5 slots
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL BufferAddress
  PUSH IY
  POP HL
  LD (IX+$42),L           ; the plotter
  LD (IX+$43),H
  LD (IX+$40),C           ; the back-buffer address
  LD (IX+$41),B
  INC IX
  INC IX
  INC IX
  INC IX
  POP BC
  DJNZ RenderPassAddresses
  LD IX,Hero
  LD B,$05
RenderPassSprites:
  PUSH BC                 ; step 2: 5 slots
  LD A,(IX+$02)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  POP DE
  ADD HL,DE
  LD DE,ExplorerSet             ; DE' = the sprite, $6000 + 72 * frame
  ADD HL,DE
  EX DE,HL
  LD H,$FE                ; H' = the bit-reverse table's page $FE
  EXX
  LD C,(IX+$40)
  LD B,(IX+$41)
  LD L,(IX+$42)
  LD H,(IX+$43)
  PUSH HL
  POP IY
  BIT 7,(IX+$03)          ; facing left?
  JR NZ,RenderPassMirror
  LD HL,$0000             ; right-facing: no byte reversal, columns left to
                          ; right
  LD (MirrorPatch1),HL
  LD (MirrorPatch2),HL
  PUSH BC
  CALL DrawSpriteColumn
  POP BC
  INC C
  PUSH BC
  CALL DrawSpriteColumn
  POP BC
  INC C
  CALL DrawSpriteColumn
  JR RenderPassNext
RenderPassMirror:
  LD HL,$7E6F             ; left-facing: LD L,A / LD A,(HL) (bytes $6F, $7E),
                          ; columns right to left
  LD (MirrorPatch1),HL
  LD (MirrorPatch2),HL
  INC C
  INC C
  PUSH BC
  CALL DrawSpriteColumn
  POP BC
  DEC C
  PUSH BC
  CALL DrawSpriteColumn
  POP BC
  DEC C
  CALL DrawSpriteColumn
RenderPassNext:
  POP BC
  LD A,B                  ; slot 0 (B = 5): the hero
  CP $05
  CALL Z,WellFront
  INC IX
  INC IX
  INC IX
  INC IX
  DJNZ RenderPassSprites
  CALL DrawItems          ; step 3: the floor items
  LD IX,Attributes+740             ; step 4: last pass's rectangles ($5B24 = $5AE4 +
                          ; $40)
  CALL CopyRects
  LD IX,Hero             ; this pass's rectangles
  CALL CopyRects
  LD HL,ActorRects             ; step 5: this pass's rectangles become last pass's
  LD DE,PrevActorRects
  LD BC,$0020
  LDIR
  LD IX,Hero
  CALL ShowCapsules       ; the alternate set's effects
  CALL RestoreActorBackgrounds ; repaint the buffer under the actors
  RET

; Copy five 4 x 24-byte rectangles from the back buffer to the screen
;
; IX = a 4-byte record array whose +$40/+$41 holds each rectangle's back-buffer
; address ($5B04 for ActorRects $5B44, $5AE4 for PrevActorRects $5B24). The
; screen address is the buffer address AND $5FFF. Each rectangle is 24 pixel
; rows of 4 bytes, copied with LDI and LDD on alternate rows (a serpentine, so
; the pointers never step back); NextCharRow $9DBF follows the character-row
; and third boundaries. B counts the rectangles; the entry CopyRect $9BF3
; copies one (B = 1) from HL.
;
; Called by RenderPass at $9BCB and $9BD2 (53 020 calls).
;
; Witness: L1 53020 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
CopyRects:
  LD B,$05

; CopyRects: the next record's rectangle
;
; The loop head of CopyRects $9BEB (the tail jump at $9C66 comes back here for
; each record).
;
; Witness: L1 265094 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
CopyRectsLoop:
  LD L,(IX+$40)
  LD H,(IX+$41)

; Copy the 4 x 24-byte rectangle at back-buffer address HL to the screen
;
; HL = the buffer address, B = the rectangles to go (1 from EraseItem $9D21 at
; $9D39), IX the record (stepped by 4 at the end).
;
; Witness: L1 265129 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
CopyRect:
  LD A,H
  AND $5F                 ; DE = the screen address: $E0xx -> $40xx, $E8xx ->
                          ; $48xx
  LD D,A
  LD E,L
  PUSH BC
  LD B,$04
CopyRectRows:
  PUSH BC                 ; 4 times 6 rows
  LD BC,$07F0             ; B = 7 for the row test, C large enough that the 18
                          ; LDI/LDD never borrow from B
  LDI
  LDI
  LDI
  LD A,(HL)               ; the 4th byte without stepping
  LD (DE),A
  INC H
  INC D
  LD A,H
  AND B
  CALL Z,NextCharRow      ; a character row crossed
  LDD                     ; the next row right to left
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,H
  AND B
  CALL Z,NextCharRow
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,H
  AND B
  CALL Z,NextCharRow
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,H
  AND B
  CALL Z,NextCharRow
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,H
  AND B
  CALL Z,NextCharRow
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,H
  AND B
  CALL Z,NextCharRow
  POP BC
  DJNZ CopyRectRows
  INC IX
  INC IX
  INC IX
  INC IX
  POP BC
  DEC B
  JP NZ,CopyRectsLoop     ; next rectangle
  RET

; Draw one 24-row sprite column into the back buffer with its outline mask
;
; In: the main set DE = the column's 24 bytes, H = $FE (the bit-reverse page,
; used when MirrorPatch is in); the alternate set BC = the buffer address, IY =
; the row plotter from BufferAddress $9CEE. C (main set) = 0: the byte above
; the first row. The nested calls DrawSprite12Rows $9C72, DrawSprite6Rows
; $9C75, DrawSprite3Rows $9C78 run DrawSpriteRow $9C7E 24 times. Called by
; RenderPass 6 call sites, 397 715 calls (three a slot a pass).
;
; Witness: L1 397715 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawSpriteColumn:
  EXX
  LD BC,$0000             ; no byte above the first row
  EXX
  CALL DrawSprite12Rows

; DrawSpriteColumn: 12 rows (twice 6)
;
; Witness: L1 795428 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawSprite12Rows:
  CALL DrawSprite6Rows

; DrawSpriteColumn: 6 rows (twice 3)
;
; Witness: L1 1590856 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawSprite6Rows:
  CALL DrawSprite3Rows

; DrawSpriteColumn: 3 rows
;
; Witness: L1 3181707 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawSprite3Rows:
  CALL DrawSpriteRow
  CALL DrawSpriteRow

; One sprite row: the outline mask from the bytes above, at and below, then the
; plotter
;
; The mask: OutlineMasks at $FF00 indexed by the OR of the sprite bytes of the
; row above, this row and the row below; the table is NOT (v OR v<<1 OR v>>1)
; ($FF01 = $FC, $FF02 = $F8: the image), so every sprite gets a one-pixel clear
; border round its set pixels (horizontally within the byte). The row below is
; the next byte, so the column's last row reads the first byte of the next
; column. Out to the plotter (alternate set): L = the sprite byte, D = the
; mask, A = $FF and H = 0 for the shift, BC = the buffer address; JP (IY).
;
; Witness: L1 9545126 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawSpriteRow:
  LD H,$FF                ; H' = the mask table's page
  EXX
  LD A,(DE)               ; the sprite byte of this row
MirrorPatch1:
  NOP                     ; NOP NOP, or LD L,A / LD A,(HL): bit-reverse through
                          ; $FE00 (RenderPass $9B82, $9B9C)
  NOP
  INC DE
  LD B,A
  LD A,(DE)               ; the byte of the row below
MirrorPatch2:
  NOP                     ; patched with MirrorPatch1
  NOP
  OR B                    ; OR this row, OR the row above (C)
  OR C
  LD C,B                  ; this row is the next row's "above"
  EXX
  LD L,A
  LD D,(HL)               ; D' = the mask
  EXX
  LD A,B
  EXX
  LD L,A
  LD A,H                  ; A = $FF (mask fill), H = 0 (the byte's spill)
  INC H
  JP (IY)                 ; to the row plotter

; The shift step for X mod 8 = 0 (ADD HL,HL / SLL D / RLA): never reached
;
; BufferAddress $9CEE points IY at $9C97 + 4 * (X mod 8) for X mod 8 = 1-7 and
; at PlotRowAligned $9CE7 for 0, so these four bytes, a shift step like the
; seven after them, are not executed in any of the 34 builds (only the 128K
; set-up's copy of the image reads them in c1).
PlotShiftUnused:
  DEFB $29,$CB,$32,$17

; Plot one masked sprite row shifted right 1 pixel (7 shift steps) into the
; back buffer
;
; The plotters $9C9B-$9CB3 are one chain of seven steps (ADD HL,HL / SLL D /
; RLA); entering at X mod 8 = k runs 8 - k steps, so H:L = the sprite byte
; moved right k pixels over two bytes and A:D the mask moved with 1s filled in.
; Then (BC) = (BC) AND A OR H and (BC + 1) = (BC + 1) AND D OR L, and
; NextBufferRow $9CC2. Entered by JP (IY) from DrawSpriteRow (73 368 times in 7
; builds for k = 1).
;
; Witness: L1 73368 (gameover, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowShift1:
  ADD HL,HL
  SLL D
  RLA

; Plot one sprite row shifted right 2 pixels (6 steps)
;
; Witness: L1 1334322 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowShift2:
  ADD HL,HL
  SLL D
  RLA

; Plot one sprite row shifted right 3 pixels (5 steps)
;
; Witness: L1 1368305 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowShift3:
  ADD HL,HL
  SLL D
  RLA

; Plot one sprite row shifted right 4 pixels (4 steps)
;
; Witness: L1 3338410 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowShift4:
  ADD HL,HL
  SLL D
  RLA

; Plot one sprite row shifted right 5 pixels (3 steps)
;
; Witness: L1 3350866 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowShift5:
  ADD HL,HL
  SLL D
  RLA

; Plot one sprite row shifted right 6 pixels (2 steps)
;
; Witness: L1 4967450 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowShift6:
  ADD HL,HL
  SLL D
  RLA

; Plot one sprite row shifted right 7 pixels (1 step), then the two buffer
; bytes
;
; Witness: L1 5146153 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowShift7:
  ADD HL,HL
  SLL D
  RLA
  LD E,A                  ; E = the mask's left byte
  LD A,(BC)
  AND E
  OR H
  LD (BC),A
  INC C                   ; the right byte
  LD A,(BC)
  AND D
  OR L
  LD (BC),A
  DEC C

; Step the back-buffer address BC one pixel row down, over character rows and
; thirds
;
; B = the high byte ($E0-$EF), C = the low. Within a character cell B + 1; past
; its 8th row C + $20 (the next character row), or past the third's last
; character row C AND $1F and B to the next third; below the second third ($F0)
; B is set to $E0, so a sprite past row 127 would wrap to the top (known only
; from the code). Returns to the DrawSpriteRow call chain.
;
; Witness: L1 9545124 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
NextBufferRow:
  INC B
  LD A,B
  AND $07
  RET NZ
  DEC B
  LD A,C
  CPL
  AND $E0
  JR Z,NextBufferThird
  LD A,C
  ADD A,$20
  LD C,A
  LD A,B
  AND $F8
  LD B,A
  RET
NextBufferThird:
  LD A,C
  AND $1F
  LD C,A
  LD A,B
  AND $F8
  ADD A,$08
  LD B,A
  BIT 4,A
  RET Z
  LD B,$E0
  RET

; Plot one masked sprite row at a byte-aligned X: (BC) = (BC) AND D OR L
;
; Witness: L1 4398977 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PlotRowAligned:
  LD A,(BC)
  AND D
  OR L
  LD (BC),A
  JP NextBufferRow

; Back-buffer address BC of pixel (L = X, H = Y) and the row plotter IY for X
; mod 8
;
; Y 0-127 (bit 7 ignored): B = $E0 + (Y AND 7) + 8 * (Y bit 6), C = 32 * ((Y >>
; 3) AND 7) + X >> 3, the screen layout of the play window at $E000. IY =
; PlotRowAligned $9CE7 when X mod 8 = 0, else $9C97 + 4 * (X mod 8)
; (PlotRowShift1-7). DE changed.
;
; Callers: RenderPass at $9B2F (132 575 calls), DrawItem $9DF8 at $9E0C,
; EraseItem $9D21 at $9D2B.
;
; Witness: L1 136425 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
BufferAddress:
  LD A,L
  PUSH AF
  RRCA
  RRCA
  RRCA
  AND $1F
  LD C,A
  LD A,H
  AND $7F
  RLCA
  RLCA
  AND $E0
  OR C
  LD C,A
  LD A,H
  AND $07
  LD B,A
  LD A,H
  AND $40
  RRCA
  RRCA
  RRCA
  OR B
  OR $E0
  LD B,A
  POP AF
  AND $07
  LD IY,PlotRowAligned
  RET Z
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  LD IY,PlotShiftUnused
  ADD IY,DE
  RET

; Remove a floor item (frame $FE): mark it gone, repaint its cells, copy them
; to the screen
;
; IX = the item record (DrawItem $9DF8 jumps here when +2 = $FE). +2 = $FF;
; BufferAddress gives the address of (X, Y); RestoreRect $9D48 repaints the
; cells under it in the back buffer from the tile map and CopyRect $9BF3 puts
; the rectangle on the screen. IX ends 8 on (both loops step it); DrawItems
; reloads it.
;
; Evidence: 35 runs in 17 builds (an item picked up; the respawn's $FE in $5B9B
; at $90BE).
;
; Witness: L1 35 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx).
EraseItem:
  LD (IX+$02),$FF
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL BufferAddress
  PUSH BC
  POP HL
  PUSH HL
  LD B,$01
  CALL RestoreRect
  POP HL
  LD B,$01
  JP CopyRect

; Repaint the back buffer under the five actors from the tile map (SK)
;
; IX = ActorSlots $5B04, B = 5. For each actor: its rectangle from ActorRects
; ($5B44), the cells under it, 3 columns and 3 rows, one more column when X mod
; 8 is not 0 and one more row when Y mod 8 is not 0; each cell's tile index
; from the tile map ($F800 + 256 * third + the low byte of the address), its 8
; bytes from TileBitmaps $5B72 into the buffer. This removes the sprites drawn
; this pass, after CopyRects has shown them. Called by RenderPass at $9BE7 (26
; 510 calls).
;
; Witness: L1 26510 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
RestoreActorBackgrounds:
  LD IX,Hero
  LD B,$05

; RestoreActorBackgrounds: the next actor's rectangle
;
; Witness: L1 132558 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
RestoreActorsLoop:
  LD L,(IX+$40)
  LD H,(IX+$41)

; Repaint the 3-4 x 3-4 cells under the record IX at back-buffer address HL
;
; Entry of RestoreActorBackgrounds for one record (EraseItem $9D21 calls it
; with B = 1).
;
; Witness: L1 132593 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
RestoreRect:
  PUSH BC
  LD A,H
  AND $F8                 ; the top of the character row
  LD H,A
  LD B,$03
  LD A,(IX+$01)
  AND $07
  JR Z,RestoreRectRow
  INC B
RestoreRectRow:
  PUSH BC
  PUSH HL
  LD A,(IX+$00)
  LD B,$03
  AND $07
  JR Z,RestoreRectCell
  INC B
RestoreRectCell:
  PUSH HL
  LD A,H                  ; the tile map: $F800 + 256 * third + L
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD DE,TileMap
  ADD HL,DE
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,(TilePixelsPtr)
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH HL                 ; the tile's 8 rows
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  POP HL
  INC L
  DJNZ RestoreRectCell
  POP HL                  ; the next character row
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,RestoreRectNextRow
  LD A,H
  ADD A,$08
  LD H,A
RestoreRectNextRow:
  POP BC
  DJNZ RestoreRectRow
  POP BC
  INC IX
  INC IX
  INC IX
  INC IX
  DJNZ RestoreActorsLoop
  RET

; NextCharRow for the address in DE
;
; Called by DrawItem $9DF8 at $9E50 (34 342 calls). Out: DE the fixed address,
; HL the screen counterpart.
;
; Witness: L1 34342 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
NextCharRowDE:
  EX DE,HL
  CALL NextCharRow
  EX DE,HL
  RET

; Fix address HL after INC H crossed a character row: the next character row or
; third
;
; Called when INC H made H AND 7 = 0. DEC H, then L + $20 with H AND $F8 (the
; next character row), or past the third's last row L AND $1F and H AND $F8 + 8
; (the next third). Out: HL, and DE = H AND $5F, L: the screen address of a
; back-buffer address (a screen address stays itself). Callers: CopyRects (6
; sites, 795 385 calls), BlitColumns $9F86 at $9F9A, NextCharRowDE.
;
; Witness: L1 893376 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
NextCharRow:
  DEC H
  LD A,L
  CPL
  AND $E0
  JR Z,NextCharRowThird
  LD A,L
  ADD A,$20
  LD L,A
  LD A,H
  AND $F8
  LD H,A
  LD A,H
  AND $5F
  LD D,A
  LD E,L
  RET
NextCharRowThird:
  LD A,L
  AND $1F
  LD L,A
  LD A,H
  AND $F8
  ADD A,$08
  LD H,A
  AND $5F
  LD D,A
  LD E,L
  RET

; Draw the room's two floor items and the third item record
;
; DrawItem $9DF8 for FloorItem1 $5C0E, FloorItem2 $5C13 (placed by $B93F from
; the table $B99D) and, running on, for the record $5B99 (X, Y, frame; $5B9B =
; $FE set by the respawn at $90BE). Called by RenderPass at $9BC4 (26 510
; calls).
;
; Witness: L1 26510 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawItems:
  LD IX,ItemSlot1
  LD B,$02
DrawItemsLoop:
  PUSH BC
  CALL DrawItem
  POP BC
  LD IX,ItemSlot2
  DJNZ DrawItemsLoop
  LD IX,Thought

; Draw the item record IX (X, Y, item) into the back buffer and the screen
;
; +2 = $FF: none, return; $FE: EraseItem $9D21. Else the item sprite $8400 + 72
; * item at X AND $F8 (byte-aligned, so no plotter) and Y: three columns of 24
; rows, each byte masked like a sprite row (OutlineMasks at $FF00 on the OR of
; the bytes above, at and below) and written to the back buffer and, the same
; byte, to the screen (RES 5 and RES 7 of the high byte: $E0xx -> $40xx). The
; items are drawn after the actors, so they stand in front of them, and are not
; repainted by RestoreActorBackgrounds: they stay in the buffer.
;
; Witness: L1 79532 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawItem:
  LD A,(IX+$02)
  CP $FF
  RET Z
  CP $FE
  JP Z,EraseItem
  LD A,(IX+$00)
  AND $F8
  LD L,A
  LD H,(IX+$01)
  CALL BufferAddress      ; BC = the buffer address (byte-aligned)
  PUSH BC
  LD L,(IX+$02)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  POP DE
  ADD HL,DE
  EX DE,HL
  LD IX,ItemSprites       ; IX = the item sprite
  ADD IX,DE
  POP DE
  LD B,$03
DrawItemColumn:
  PUSH BC                 ; 3 columns
  PUSH DE
  LD B,$18
  LD C,(IX+$00)           ; the byte above the first row: the first byte itself
  LD H,$FF
DrawItemRow:
  LD A,(IX+$00)           ; 24 rows
  OR (IX+$01)
  OR C
  LD C,(IX+$00)
  INC IX
  LD L,A                  ; L = the masks' index
  LD A,(DE)
  AND (HL)
  OR C
  LD (DE),A
  RES 5,D                 ; the screen byte too
  RES 7,D
  LD (DE),A
  LD A,D                  ; D + $A1: from $4x back to the buffer's next row
  ADD A,$A1
  LD D,A
  AND $07
  JP NZ,DrawItemNextRow
  CALL NextCharRowDE
  LD H,$FF
DrawItemNextRow:
  DJNZ DrawItemRow
  POP DE
  POP BC
  INC E
  DJNZ DrawItemColumn
  RET

  ORG $E000

; The back buffer of the play window in play; on the tape and between games the
; saved panel's pixels
;
; In play RenderPass $9B22 composes the actors here, at the screen address +
; $A000 (rows of the play window in the screen's layout, $E000-$EFFF for the
; top two thirds), copies their rectangles to the screen and repaints the
; background from the tile map. Before play the first 2048 bytes are the status
; panel (the screen's bottom third, $5000-$57FF): InitGame copies them to the
; screen at $8F8B, DeviceMenu $93AF cuts the menu's frame from them, and
; EndGame $906D saves the panel back here when a game ends.
;
; Witness: c1 reads all of $E000-$E8FF (byte counts, page 0; InitGame copies
; them before the first game, and EndGame has not run yet); every play build
; reads and writes $DF80-$EFFF.
BackBuffer:
  INCBIN "res/screens/panel-pixels.bin",$0000,2048

; The saved panel's attributes (8 rows of 32), part of the back buffer in play
;
; Copied to $5A00 by InitGame ($8F8B); saved again by EndGame $906D ($907B).
SavedPanelAttrs:
  INCBIN "res/screens/panel-attrs.bin",$0000,256

; The rest of the back buffer: on the tape, leftover bytes play overwrites
;
; No code reads these 1792 bytes before play writes them. They hold, among
; other bytes, twelve 24 x 24 sprites in the sprite layout at $E930-$EC8F that
; no frame number reaches (the sprite space ends at $A7B8; SK names three of
; them "captured by the snake"), drawn in src/res/leftovers/README.md.
BackBufferLeftover:
  INCBIN "res/leftovers/back-buffer-tape.bin",$0000,1792

  ORG $FE00

; Byte n reversed bit for bit: mirrors a sprite byte for the left-facing frames
;
; Checked: all 256 bytes equal n reversed. Read by the mirror patch of the
; plotter ($9C82/$9C87).
BitReverse:
  DEFB $00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
  DEFB $08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
  DEFB $04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
  DEFB $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
  DEFB $02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
  DEFB $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
  DEFB $06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
  DEFB $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
  DEFB $01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
  DEFB $09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
  DEFB $05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
  DEFB $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
  DEFB $03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
  DEFB $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
  DEFB $07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
  DEFB $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF

; The outline mask of byte n: NOT (n OR n << 1 OR n >> 1)
;
; Checked: all 256 bytes follow the formula. RenderPass ANDs the screen with
; the mask of the rows above, at and below a sprite row, so a sprite gets a
; one-pixel black outline.
OutlineMasks:
  DEFB $FF,$FC,$F8,$F8,$F1,$F0,$F0,$F0,$E3,$E0,$E0,$E0,$E1,$E0,$E0,$E0
  DEFB $C7,$C4,$C0,$C0,$C1,$C0,$C0,$C0,$C3,$C0,$C0,$C0,$C1,$C0,$C0,$C0
  DEFB $8F,$8C,$88,$88,$81,$80,$80,$80,$83,$80,$80,$80,$81,$80,$80,$80
  DEFB $87,$84,$80,$80,$81,$80,$80,$80,$83,$80,$80,$80,$81,$80,$80,$80
  DEFB $1F,$1C,$18,$18,$11,$10,$10,$10,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $07,$04,$00,$00,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $0F,$0C,$08,$08,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $07,$04,$00,$00,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $3F,$3C,$38,$38,$31,$30,$30,$30,$23,$20,$20,$20,$21,$20,$20,$20
  DEFB $07,$04,$00,$00,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $0F,$0C,$08,$08,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $07,$04,$00,$00,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $1F,$1C,$18,$18,$11,$10,$10,$10,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $07,$04,$00,$00,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $0F,$0C,$08,$08,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
  DEFB $07,$04,$00,$00,$01,$00,$00,$00,$03,$00,$00,$00,$01,$00,$00,$00
