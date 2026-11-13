; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the sprite composer, the cell drawers, the scroll and the attributes
;
; Nothing is drawn on the screen but whole cells. The map builder $88D4 fills ViewCells $6B00 (32 x 44 cell numbers;
; row 8 is the screen's row 0, the HUD, so screen rows 1-23 are view rows 9-31), and DirtyMap $6600 (DirtyMap + $500 =
; ViewCells, same index) says what each screen cell needs: 0 nothing, 1 the level cell again, n >= 2 the composed
; spare cell n.
;
; A sprite is masked into copies, never into the screen: ComposeSprite $7329 asks ComposeCell $7755 for each cell
; under the sprite, which copies the cell's 8 bytes (or the spare cell another sprite already made there) into the
; next spare cell (SpareCells + 8 x (n + 1), n = SpareCount $77B0), marks DirtyMap with n and leaves a cell whose
; CellFlags bit 7 is set alone (the sprite passes behind it). The spare cells of one sprite form a strip, column by
; column, 24 or 32 bytes a column, and the composer masks the sprite's rows into the strip ((byte AND mask) OR data, 3
; bytes a row, 4 when the sprite is shifted), popping the rows with SP. DrawChangedCells $76D4 then copies the spare
; cells to the screen and restores the level cells the sprites left (1 -> 0, n -> 1), so a pass redraws only the cells
; sprites touch.
;
; The view scrolls by 8 cell rows (ScrollDown $78A5, ScrollUp $7905) in three steps of 2, 4 and 2 rows, one frame
; each, redrawing only the cells that differ from what the screen shows (RedrawScrolledView $77B1); attributes are set
; per cell from CellAttrs (SetViewAttrs $783F for the whole view, the scroll per redrawn cell).
;
; The cell drawer $7755-$77A2 reads its cell graphics from the base stored at $7730 and $7777 and leaves the cells
; whose flag has bit 7 by the JP M at $775A. In the menus and the endings FontCellsMode points it at the font $7080
; and turns the JP M into NOPs (no flags: the cell numbers are glyph numbers); LevelCellsMode puts the level's cells
; $A900 and the JP M back.
; --------------------------------------------------------------------------------------------------------------------

; Mask the sprite of the object record at IX into spare copies of the cells
; under it
;
; IX = an object record: +1 x in pixels, +2/+3 y in pixels from the top of the
; view buffer (64 = the screen's top), +4/+5 the sprite's address (0: nothing
; drawn), +6 bit 7 mirrored. The sprite (in Sprites $C26D) is: a byte added to
; the strip offset (the sprite's top line), a byte of rows, then 6 bytes a row:
; data 2, data 1, data 0, mask 0, mask 2, mask 1 (popped as HL, BC, DE).
; Returns at once when y >= 299 ($012B: below the buffer) or the sprite address
; is 0.
;
; The view cell under the top left is ViewCells + (y AND $F8) x 4 + x / 8; the
; first spare cell SpareCells + 8 x (SpareCount + 1). x AND 7 = 0 (aligned): 3
; columns, of 4 cells when y AND 4 (else 3), each through ComposeCell $7755,
; then the rows are masked in at IY = the strip + (y AND 7) + the sprite's
; first byte, columns w = 32 (or 24) bytes apart, the displacements patched
; into $7495-$74AC. Otherwise (shifted, ComposeShifted $74B7): 4 columns, each
; row shifted right by x AND 7 through the chain $7637 entered at $7637 + 14 x
; (x AND 7), a fourth byte of data (0) and mask ($FF) shifted in. A mirrored
; sprite swaps its outer bytes and reverses every byte through MirrorTable
; $6500 ($7471, $760B).
;
; Interrupts are off while SP walks the sprite ($7442-$74B5, $75DC-$76D2): an
; interrupt that falls there is lost. SP is put back from the copy stored at
; $74B3 / $76D0.
;
; Callers: the object drawer $85FA ($860A, $8618, $8626, $8639, $8652) and the
; menu's $814B. 250 504 runs in 65 builds; aligned 118 841 (3 rows 113 446, 4
; rows 5395), shifted 108 333 (3 rows 96 247, 4 rows 13 402); mirrored rows 232
; 085 aligned, 551 698 shifted.
;
; Witness: L1 593362 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ComposeSprite:
  LD A,(IX+$03)
  AND A
  JP Z,ComposeSpriteCells
  CP $01
  RET NZ
  LD A,(IX+$02)
  CP $2B
  RET NC

; ComposeSpriteCells
;
; Used by the routine at ComposeSprite.
ComposeSpriteCells:
  LD A,(IX+$04)           ; y on the buffer: is there a sprite?
  OR (IX+$05)
  RET Z
  LD A,(SpareCount)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,SpareCells+8      ; DE = the first spare cell of this sprite
  ADD HL,BC
  EX DE,HL
  LD A,(IX+$02)
  AND $F8
  LD L,A
  LD H,(IX+$03)
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$01)
  RRA
  RRA
  RRA
  AND $1F
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,ViewCells         ; HL = the view cell under the sprite's top left
  ADD HL,BC
  LD A,(IX+$01)
  AND $07
  JP NZ,ComposeShifted
  LD A,(IX+$02)
  AND $07
  EX AF,AF'
  LD A,(IX+$02)
  AND $04
  JP Z,ComposeAligned3Rows
ComposeAligned4Rows:
  CALL ComposeCell        ; aligned, y AND 4: 3 columns of 4 cells
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-3*32+1            ; up 3 rows, one column right
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-3*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD A,$20                ; w = 32: the next column's byte is 32 bytes on
  LD (MaskAlignedCol1+$0002),A
  LD (MaskAlignedCol1+$0007),A
  ADD A,A
  LD (MaskAlignedCol2+$0002),A
  LD (MaskAlignedCol2Or+$0003),A
  EX DE,HL
  LD BC,-3*32
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC
  JP ComposeAlignedBlit

; ComposeAligned3Rows
;
; Used by the routine at ComposeSpriteCells.
ComposeAligned3Rows:
  CALL ComposeCell        ; aligned, y AND 4 = 0: 3 columns of 3 cells
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC

; ComposeAligned3RowsCell3
ComposeAligned3RowsCell3:
  CALL ComposeCell
  LD BC,-2*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-2*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD A,$18                ; w = 24
  LD (MaskAlignedCol1+$0002),A
  LD (MaskAlignedCol1+$0007),A
  ADD A,A
  LD (MaskAlignedCol2+$0002),A
  LD (MaskAlignedCol2Or+$0003),A
  EX DE,HL
  LD BC,-3*24             ; HL = the strip's start
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC

; ComposeAlignedBlit
;
; Used by the routine at ComposeSpriteCells.
ComposeAlignedBlit:
  PUSH HL                 ; IY = the strip + (y AND 7)
  POP IY
  DI
  LD (ComposeAlignedEnd+$0001),SP ; the caller's SP into ComposeAlignedEnd
  LD HL,MaskAlignedCol0
  LD (ComposeAlignedRowJump+$0001),HL
  BIT 7,(IX+$06)
  JP Z,ComposeAlignedData
  LD HL,MirrorAlignedRow  ; mirrored: the row goes through MirrorAlignedRow
                          ; first
  LD (ComposeAlignedRowJump+$0001),HL
ComposeAlignedData:
  LD L,(IX+$04)           ; IY += the sprite's first byte, B = its rows, SP =
                          ; its first row
  LD H,(IX+$05)
  LD C,(HL)
  LD B,$00
  ADD IY,BC
  INC HL
  LD A,(HL)
  INC HL
  LD SP,HL
  LD B,A

; ComposeAlignedRow
;
; Used by the routine at ComposeAlignedNext.
ComposeAlignedRow:
  EXX                     ; pop a row: L data 2, H data 1, C data 0, B mask 0,
                          ; E mask 2, D mask 1
  POP HL
  POP BC
  POP DE
ComposeAlignedRowJump:
  JP MaskAlignedCol0      ; JP nn: nn = MaskAlignedCol0, or MirrorAlignedRow
                          ; when mirrored ($744A, $7457)
MirrorAlignedRow:
  LD A,L                  ; swap data 0 / 2 and mask 0 / 2, then reverse every
                          ; byte's bits
  LD L,C
  LD C,A
  LD A,B
  LD B,E
  LD E,A
  LD (MirrorAlignedSaved+$0001),HL
  LD H,MirrorTable/256
  LD L,B
  LD B,(HL)
  LD L,C
  LD C,(HL)
  LD L,D
  LD D,(HL)
  LD L,E
  LD E,(HL)
MirrorAlignedSaved:
  LD HL,$0000             ; LD HL,nn: nn = H, L saved at $7477
  LD A,L
  EXX
  LD H,MirrorTable/256
  LD L,A
  LD A,(HL)
  EXX
  LD L,A
  LD A,H
  EXX
  LD L,A
  LD A,(HL)
  EXX
  LD H,A
MaskAlignedCol0:
  LD A,(IY+$00)           ; (byte AND mask 0) OR data 0
  AND B
  OR C
  LD (IY+$00),A
MaskAlignedCol1:
  LD A,(IY+$20)           ; +w: (byte AND mask 1) OR data 1
  AND D
  OR H
  LD (IY+$20),A
MaskAlignedCol2:
  LD A,(IY+$00)           ; +2w: (byte AND mask 2) OR data 2
  AND E

; MaskAlignedCol2Or
MaskAlignedCol2Or:
  OR L
  LD (IY+$00),A
  INC IY
  EXX

; ComposeAlignedNext
ComposeAlignedNext:
  DJNZ ComposeAlignedRow  ; the next row
ComposeAlignedEnd:
  LD SP,$0000             ; LD SP,nn: nn = the caller's SP
  EI
  RET

; ComposeShifted
;
; Used by the routine at ComposeSpriteCells.
ComposeShifted:
  ADD A,A                 ; x AND 7 = k > 0: ShiftRowJump's target = ShiftChain
                          ; + 14k
  LD C,A
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  ADD A,C
  LD C,A
  LD B,$00
  PUSH HL
  LD HL,ShiftChain
  ADD HL,BC
  LD (ShiftRowJump+$0001),HL
  POP HL
  LD A,(IX+$02)
  AND $07
  EX AF,AF'
  LD A,(IX+$02)
  AND $04
  JP NZ,ComposeShifted4Rows
  CALL ComposeCell        ; 4 columns of 3 cells
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-2*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-2*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-2*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD A,$18                ; w = 24, 3w = 72
  LD (MaskShiftedCol1+$0002),A
  LD (MaskShiftedCol1Mask+$0004),A
  ADD A,A
  LD (MaskShiftedCol2+$0002),A
  LD (MaskShiftedCol2+$0007),A
  LD A,$48
  LD (MaskShiftedCol3+$0002),A
  LD (MaskShiftedCol3Mask+$0004),A
  EX DE,HL
  LD BC,-4*24
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC
  JP ComposeShiftedBlit
ComposeShifted4Rows:
  CALL ComposeCell        ; y AND 4: 4 columns of 4 cells
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-3*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-3*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,-3*32+1
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  EX DE,HL
  LD BC,-4*32
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,$20                ; w = 32, 3w = 96
  LD (MaskShiftedCol1+$0002),A
  LD (MaskShiftedCol1Mask+$0004),A
  ADD A,A
  LD (MaskShiftedCol2+$0002),A
  LD (MaskShiftedCol2+$0007),A
  LD A,$60
  LD (MaskShiftedCol3+$0002),A
  LD (MaskShiftedCol3Mask+$0004),A
ComposeShiftedBlit:
  PUSH HL                 ; IY = the strip + (y AND 7)
  POP IY
  DI
  LD (ComposeShiftedEnd+$0001),SP ; the caller's SP into ComposeShiftedEnd
  LD HL,ShiftRowStart
  LD (ComposeShiftedRowJump+$0001),HL
  BIT 7,(IX+$06)
  JP Z,ComposeShiftedData
  LD HL,MirrorShiftedRow  ; mirrored: the row goes through MirrorShiftedRow
                          ; first
  LD (ComposeShiftedRowJump+$0001),HL
ComposeShiftedData:
  LD L,(IX+$04)           ; IY += the sprite's first byte, L' = its rows, SP =
                          ; its first row
  LD H,(IX+$05)
  LD C,(HL)
  LD B,$00
  ADD IY,BC
  INC HL
  LD A,(HL)
  INC HL
  LD SP,HL
  LD L,A

; ComposeShiftedRow
;
; Used by the routine at MaskShiftedCol3Mask.
ComposeShiftedRow:
  EXX                     ; pop a row into the second register set
  POP HL
  POP BC
  POP DE
ComposeShiftedRowJump:
  JP ShiftRowStart        ; JP nn: nn = ShiftRowStart, or MirrorShiftedRow when
                          ; mirrored ($75E4, $75F1)
MirrorShiftedRow:
  LD A,L                  ; as MirrorAlignedRow
  LD L,C
  LD C,A
  LD A,B
  LD B,E
  LD E,A
  LD (MirrorShiftedSaved+$0001),HL
  LD H,MirrorTable/256
  LD L,B
  LD B,(HL)
  LD L,C
  LD C,(HL)
  LD L,D
  LD D,(HL)
  LD L,E
  LD E,(HL)
MirrorShiftedSaved:
  LD HL,$0000             ; LD HL,nn: nn = H, L saved at $7611
  LD A,L
  EXX
  LD D,MirrorTable/256
  LD E,A
  LD A,(DE)
  EXX
  LD L,A
  LD A,H
  EXX
  LD E,A
  LD A,(DE)
  EXX
  LD H,A
ShiftRowStart:
  EXX                     ; mask 3 = $FF, data 3 (A) = 0
  LD C,$FF
  EXX
  XOR A
ShiftRowJump:
  JP ShiftChain           ; JP nn: nn = ShiftChain + 14 x (x AND 7), set at
                          ; $74C6
ShiftChain:
  ADD HL,HL               ; step 0 of 8: ADD HL,HL / RL C / RLA (data) / SLL E
                          ; / RL D / RL B / EXX / RL C / EXX (mask); entered
                          ; only for k = 0, which takes the aligned path: not
                          ; executed (DEFB)
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
ShiftRight1:
  ADD HL,HL               ; entered here: 7 shifts left = 1 right (27 634 runs)
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
ShiftRight2:
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
ShiftRight3:
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
ShiftRight4:
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
ShiftRight5:
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
ShiftRight6:
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C

; ShiftStep6Exx
ShiftStep6Exx:
  EXX

; ShiftRight7
ShiftRight7:
  ADD HL,HL               ; the last step: it ends in the second set (no final
                          ; EXX)

; ShiftStep7Rotate
ShiftStep7Rotate:
  RL C
  RLA
  SLL E
  RL D
  RL B

; ShiftStep7Exx
ShiftStep7Exx:
  EXX
  RL C

; MaskShiftedCol0
MaskShiftedCol0:
  LD B,A                  ; B' = data 0: (byte AND mask 0) OR data 0
  LD A,(IY+$00)
  AND C
  OR B

; MaskShiftedCol0Store
MaskShiftedCol0Store:
  LD (IY+$00),A
  EXX
MaskShiftedCol1:
  LD A,(IY+$20)           ; +w

; MaskShiftedCol1Mask
MaskShiftedCol1Mask:
  AND B
  OR C
  LD (IY+$20),A
MaskShiftedCol2:
  LD A,(IY+$40)           ; +2w
  AND D
  OR H
  LD (IY+$40),A
MaskShiftedCol3:
  LD A,(IY+$60)           ; +3w

; MaskShiftedCol3Mask
MaskShiftedCol3Mask:
  AND E
  OR L
  LD (IY+$60),A
ComposeShiftedNext:
  INC IY                  ; the next row: DEC L'
  EXX
  DEC L
  JP NZ,ComposeShiftedRow
ComposeShiftedEnd:
  LD SP,$0000             ; LD SP,nn: nn = the caller's SP
  EI
  RET

; Draw the cells DirtyMap marks: the spare cells, and the level cells the
; sprites left
;
; Scans DirtyMap from $6720 (screen row 1) to the sentinel $FF it puts at
; $6A00: 0 is skipped; 1 draws the level cell (ViewCells at the same index, its
; 8 bytes from CellGraphics) and sets 0; n >= 2 draws spare cell n (SpareCells
; + 8 x (n + 1)) and sets 1, so the cell is restored on the next pass unless a
; sprite covers it again. Draws only the bitmap: a cell keeps its attribute.
; The screen address is ((H x 8 + 8) AND $FF, L) of the DirtyMap address.
;
; The graphics base at $772F is CellGraphics in play and the font Glyphs $7080
; under the text printer $88B1 (patched by $7EB3, $7FB2, $88B1).
;
; Callers: the main loop $7D8E after the frame wait (50 140), the scrolls $7901
; / $7961, RedrawView $7968, $8153, $82E7, $8319, $8AE0, $8B30, $8B37. 57 658
; runs in 67 builds; spare cells drawn 1 689 139 times, level cells restored
; 196 595.
;
; Witness: L1 154386 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
DrawChangedCells:
  LD A,$FF
  LD (DirtyMap+1024),A
  LD HL,DirtyMap+287             ; one before screen row 1

; DrawChangedNext
;
; Used by the routines at DrawSpareLine6 and DrawLevelCell.
DrawChangedNext:
  XOR A

; DrawChangedScan
;
; Used by the routine at DrawChangedIfClear.
DrawChangedScan:
  INC HL

; DrawChangedRead
DrawChangedRead:
  OR (HL)

; DrawChangedIfClear
DrawChangedIfClear:
  JP Z,DrawChangedScan    ; 0: next; A = value + 1, 0 at the sentinel
  INC A
  RET Z
  EX AF,AF'               ; DE = the screen address of this cell
  LD A,H
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$08
  LD D,A
  LD E,L
  EX AF,AF'
  CP $02
  JP Z,DrawLevelCell
  LD (HL),$01             ; n >= 2: draw spare cell n, then mark 1
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,SpareCells
  ADD HL,BC
  LDI

; DrawSpareLine1
DrawSpareLine1:
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D

; DrawSpareLine4
DrawSpareLine4:
  LDI
  DEC DE
  INC D
  LDI
  DEC DE

; DrawSpareLine6
DrawSpareLine6:
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP HL
  JP DrawChangedNext

; DrawLevelCell
;
; Used by the routine at DrawChangedIfClear.
DrawLevelCell:
  LD (HL),$00             ; 1: draw the level cell again, then mark 0
  PUSH HL
  LD A,H
  ADD A,$05
  LD H,A
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
DrawLevelCellBase:
  LD BC,CellGraphics      ; LD BC,nn: nn = CellGraphics, or Glyphs under the
                          ; text printer
  ADD HL,BC
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP HL
  JP DrawChangedNext

; Copy the cell at HL in ViewCells into the next spare cell at DE for a sprite
;
; HL = a ViewCells address, DE = the next spare cell. C = the cell number; when
; CellFlags bit 7 is set the cell is in front of sprites: only SpareCount $77B0
; and DE advance ($77A2), the spare cell is masked but never shown. Otherwise
; the DirtyMap byte (HL - $500) becomes SpareCount (then incremented), and the
; spare cell gets the level cell's 8 bytes (CellGraphics + 8C) or, when
; DirtyMap already held a spare cell n >= 2 (another sprite there this pass),
; that cell's bytes: overlapping sprites stack. DE advances by 8.
;
; The front test at $775A is JP M,$77A2 in play; the game's end $7E1E and the
; text printer $88B1 write it to three NOPs (every cell takes sprites), $7EB3
; and $7FB2 put it back; the graphics base at $7776 is patched with $772F's.
;
; Callers: ComposeSprite $7329 (9 to 16 times a sprite) and $8321 ($8340,
; $8352: 2 cells). 2 497 317 runs; front cells 272 993, stacked 551 496.
;
; Witness: L1 6116909 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ComposeCell:
  LD B,CellFlags/256

; ComposeCellRead
ComposeCellRead:
  LD C,(HL)
  LD A,(BC)
  AND A
ComposeCellFrontTest:
  JP M,ComposeCellSkip    ; JP M,$77A2 (bit 7: in front) or NOP, NOP, NOP; DEFB
                          ; because the game writes it
ComposeCellCopy:
  PUSH HL                 ; DirtyMap = SpareCount; a spare cell already there
                          ; (>= 2): ComposeCellStack
  LD A,H
  SUB $05
  LD H,A
  LD A,(HL)
  CP $02
  JP NC,ComposeCellStack
  LD A,(SpareCount)
  LD (HL),A
  INC A
  LD (SpareCount),A
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
ComposeCellBase:
  LD BC,CellGraphics      ; LD BC,nn: nn = CellGraphics, or Glyphs under the
                          ; text printer
  ADD HL,BC

; CopyCellGraphics
;
; Used by the routine at ComposeCellStackShift.
CopyCellGraphics:
  LDI
  LDI
  LDI

; CopyCellLine3
CopyCellLine3:
  LDI

; CopyCellLine4
CopyCellLine4:
  LDI
  LDI
  LDI
  LDI
  POP HL
  RET

; ComposeCellStack
;
; Used by the routine at ComposeCellRead.
ComposeCellStack:
  LD C,A                  ; copy the other sprite's spare cell instead
  LD A,(SpareCount)
  LD (HL),A
  INC A
  LD (SpareCount),A
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,HL

; ComposeCellStackShift
ComposeCellStackShift:
  ADD HL,HL
  LD BC,SpareCells+8
  ADD HL,BC
  JP CopyCellGraphics

; ComposeCellSkip
;
; Used by the routine at ComposeCellRead.
ComposeCellSkip:
  LD A,(SpareCount)       ; a front cell: skip one spare cell
  INC A
  LD (SpareCount),A
  LD BC,$0008
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  RET

; The next spare cell's number (from 2): ComposeCell takes one per cell under a
; sprite
;
; Read by ComposeSprite $7329 and ComposeCell $7755 (which increments it),
; $8321; set by $80B5, $8127, $81E6 and the object drawer $85FA at the start of
; each pass.
SpareCount:
  DEFB $00

; Redraw screen rows 1-23 from a view moved by some rows, only the cells that
; change
;
; HL = ViewCells at the new view's screen row 1, HL' = ViewCells at the old one
; (what the screen shows), DE = DirtyMap at HL - $500. Per cell, DirtyMap 0:
; drawn only when the new cell differs from the old ($77D0); 1: drawn ($77CB);
; n >= 2: spare cell n drawn ($7827). Each cell drawn gets its attribute from
; CellAttrs. 7 rows to the first third's end, then 8 and 8.
;
; Called three times by each scroll (ScrollDown $78C3, $78D5, $78E7, ScrollUp
; $7923, $7935, $7947): 515 runs in 48 builds, all RZX pieces (c1 never
; scrolls).
;
; Witness: L1 1114 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12).
RedrawScrolledView:
  EXX
  LD DE,Screen+32
  EXX
  LD IX,ScreenAttrs+32
  LD A,$07
  LD B,$03

; RedrawThird
;
; Used by the routine at RedrawNext.
RedrawThird:
  PUSH BC

; RedrawRow
;
; Used by the routine at RedrawNext.
RedrawRow:
  EX AF,AF'
  LD B,$20

; RedrawCell
;
; Used by the routine at RedrawNext.
RedrawCell:
  LD A,(DE)               ; DirtyMap: 0 compare, 1 draw, n >= 2 the spare cell
  AND A
  JP Z,RedrawIfChanged
  DEC A
  JP NZ,RedrawSpareCell
  LD A,(HL)
  EXX
  JP RedrawLevelCell
RedrawIfChanged:
  LD A,(HL)
  EXX
  CP (HL)
  JP NZ,RedrawLevelCell

; RedrawSkip
;
; Used by the routine at RedrawCopyCell.
RedrawSkip:
  INC HL
  INC E
  EXX

; RedrawNext
RedrawNext:
  INC DE
  INC HL
  INC IX
  DJNZ RedrawCell
  EX AF,AF'
  DEC A
  JP NZ,RedrawRow
  EXX
  LD BC,$0800
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  EXX
  LD A,$08
  POP BC
  DJNZ RedrawThird
  RET

; RedrawLevelCell
;
; Used by the routine at RedrawCell.
RedrawLevelCell:
  PUSH HL                 ; A = the cell: its attribute, then its graphics
  LD L,A
  LD H,CellAttrs/256
  LD A,(HL)
  LD (IX+$00),A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,H
  ADD A,CellGraphics/256
  LD H,A

; RedrawCopyCell
;
; Used by the routine at RedrawSpareCell.
RedrawCopyCell:
  PUSH DE
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP DE
  POP HL
  JP RedrawSkip

; RedrawSpareCell
;
; Used by the routine at RedrawCell.
RedrawSpareCell:
  PUSH HL                 ; the view cell's attribute, spare cell n's graphics
  LD L,(HL)
  LD H,CellAttrs/256
  LD L,(HL)
  LD (IX+$00),L
  POP HL
  EXX
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,SpareCells+16
  ADD HL,BC
  JP RedrawCopyCell

; Set the attributes of screen rows 1-23 from the view's cells
;
; ScreenAttrs + 32 onwards = CellAttrs[ViewCells from $6C20], 736 cells (224 +
; 256 + 256 in three loops on A'). Called by RedrawView $7965 only: 97 runs in
; 43 builds.
;
; Witness: L1 271 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
SetViewAttrs:
  LD HL,ViewCells+288
  LD D,CellAttrs/256
  LD BC,ScreenAttrs+32
  LD A,$E0
SetAttrsLoop1:
  EX AF,AF'
  LD E,(HL)
  INC HL
  LD A,(DE)
  LD (BC),A
  INC BC
  EX AF,AF'
  DEC A
  JP NZ,SetAttrsLoop1
SetAttrsLoop2:
  EX AF,AF'
  LD E,(HL)
  INC HL
  LD A,(DE)
  LD (BC),A
  INC BC
  EX AF,AF'
  DEC A
  JP NZ,SetAttrsLoop2
SetAttrsLoop3:
  EX AF,AF'
  LD E,(HL)
  INC HL
  LD A,(DE)
  LD (BC),A
  INC BC
  EX AF,AF'
  DEC A
  JP NZ,SetAttrsLoop3
  RET

; Before a scroll: mark for restoring the cells the sprites' copies will lie on
;
; HL = DirtyMap (or DirtyMap + 256), DE = +32 (down) or -32 (up). For each of
; 1024 DirtyMap bytes >= 2 (a spare cell on the screen) it sets to 1 the bytes
; 2, 6 and 8 rows on, when 0: the screen positions of that cell after each step
; of the scroll, so RedrawScrolledView redraws the level cell there.
;
; Called by ScrollDown $78B1 and ScrollUp $7911: 169 runs in 48 builds.
;
; Witness: L1 366 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12).
MarkScrollCells:
  LD HL,DirtyMap
  LD C,$04
  XOR A
  LD B,A

; MarkScrollScan
;
; Used by the routine at MarkScrollNext.
MarkScrollScan:
  OR (HL)
  JP NZ,MarkScrollCell

; MarkScrollNext
;
; Used by the routines at MarkScrollCell and MarkScrollRow6Test.
MarkScrollNext:
  INC HL
  DJNZ MarkScrollScan
  DEC C
  JP NZ,MarkScrollScan
  RET

; MarkScrollCell
;
; Used by the routine at MarkScrollScan.
MarkScrollCell:
  CP $01
  JP Z,MarkScrollNext
  PUSH HL
  ADD HL,DE
  ADD HL,DE
  LD A,(HL)
  AND A
  JP NZ,MarkScrollRow6
  LD (HL),$01
MarkScrollRow6:
  ADD HL,DE
  ADD HL,DE
  ADD HL,DE
  ADD HL,DE
  LD A,(HL)

; MarkScrollRow6Test
MarkScrollRow6Test:
  AND A
  JP NZ,MarkScrollRow8
  LD (HL),$01
MarkScrollRow8:
  ADD HL,DE
  ADD HL,DE
  LD A,(HL)
  AND A
  JP NZ,MarkScrollDone
  LD (HL),$01
MarkScrollDone:
  POP HL
  JP MarkScrollNext

; Move the view 8 cell rows down the section in three steps
;
; The main loop $7E06 calls it when Rick's y ($9BAD) >= 204 and the view's top
; $88CF < its limit $88D2. Clears the marks ($8985), composes the sprites
; ($85FA), marks their cells (MarkScrollCells), then redraws the screen from 2,
; 6 and 8 rows lower (RedrawScrolledView), each after a frame wait (C = 1).
; Then $88CF += 8, the view is rebuilt ($88D4), every object moved 64 pixels up
; ($9E31, BC = -64), and the sprites composed and drawn again. So a scroll
; takes at least three frames.
;
; 81 runs in 30 builds (RZX pieces).
;
; Witness: L1 190 (rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-24000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-18000-poke,
; rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, sec-l4-s2,
; sec-l4-s6, sec-l4-s11, sec-l4-s12).
ScrollDown:
  CALL ClearRedraw
  CALL DrawSprites
  LD DE,$0020
  LD HL,DirtyMap
  CALL MarkScrollCells
  LD HL,ViewCells+288
  EXX
  LD HL,ViewCells+352
  LD DE,DirtyMap+352
  LD C,$01
  CALL WaitFrames
  CALL RedrawScrolledView
  LD HL,ViewCells+352
  EXX
  LD HL,ViewCells+480
  LD DE,DirtyMap+480
  LD C,$01
  CALL WaitFrames
  CALL RedrawScrolledView
  LD HL,ViewCells+480
  EXX
  LD HL,ViewCells+544
  LD DE,DirtyMap+544
  LD C,$01
  CALL WaitFrames
  CALL RedrawScrolledView
  LD A,(ViewTopRow)
  ADD A,$08
  LD (ViewTopRow),A
  CALL BuildView
  LD BC,-64
  CALL ShiftObjects
  CALL ClearRedraw
  CALL DrawSprites
  CALL DrawChangedCells
  RET

; Move the view 8 cell rows up the section in three steps
;
; As ScrollDown, the other way: the main loop $7DEB calls it when Rick's y
; ($9BAD) < 96 and $88CF > 0; redraws from 2, 6 and 8 rows higher, $88CF -= 8,
; the objects moved 64 pixels down ($9E31, BC = 64). 88 runs in 34 builds.
;
; Witness: L1 176 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-22000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full).
ScrollUp:
  CALL ClearRedraw
  CALL DrawSprites
  LD DE,-32
  LD HL,DirtyMap+256
  CALL MarkScrollCells
  LD HL,ViewCells+288
  EXX
  LD HL,ViewCells+224
  LD DE,DirtyMap+224
  LD C,$01
  CALL WaitFrames
  CALL RedrawScrolledView
  LD HL,ViewCells+224
  EXX
  LD HL,ViewCells+96
  LD DE,DirtyMap+96
  LD C,$01
  CALL WaitFrames
  CALL RedrawScrolledView
  LD HL,ViewCells+96
  EXX
  LD HL,ViewCells+32
  LD DE,DirtyMap+32
  LD C,$01
  CALL WaitFrames
  CALL RedrawScrolledView
  LD A,(ViewTopRow)
  SUB $08
  LD (ViewTopRow),A
  CALL BuildView
  LD BC,64
  CALL ShiftObjects
  CALL ClearRedraw
  CALL DrawSprites
  CALL DrawChangedCells
  RET

; Draw the whole view: mark every cell, draw, set the attributes
;
; $8969 (marks the DirtyMap for a full redraw), DrawChangedCells $76D4,
; SetViewAttrs $783F. Called by the section start ($8B2D, $8B34): 97 runs in 43
; builds, a few per recording (c1 6).
;
; Witness: L1 271 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
RedrawView:
  CALL RedrawAll
  CALL DrawChangedCells
  CALL SetViewAttrs
  RET

  ORG $7A61

; Clear the bitmap and set every attribute to $47 (bright white on black)
;
; Callers: the level menu $7F47, the tape loader $840C, $8427, $84FF and the
; text printer $88C4. 47 runs in 13 builds.
;
; Witness: L1 176 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l3-10000-poke, rzx-l4-20000-poke,
; rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
ClearScreen:
  LD HL,Screen
  LD DE,Screen+1
  LD (HL),$00
  LD BC,$1800
  LDIR
  LD (HL),$47
  LD BC,$02FF
  LDIR
  RET

  ORG $7EB3

; The cell drawer back to the level's cells
;
; Writes $A900 (CellGraphics) to the drawer's two bases $7730 and $7777 and JP
; M,$77A2 back at $775A. The same code ends LevelMenu ($7FB2).
;
; Evidence: 3 runs in 2 builds (controls-keyboard 1, rzx-l5-full 2): after GAME
; OVER ($7EAD).
;
; Witness: L1 40 (controls-keyboard, rzx-l5-full, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
LevelCellsMode:
  LD HL,CellGraphics
  LD (DrawLevelCellBase+$0001),HL
  LD (ComposeCellBase+$0001),HL
  LD A,$FA
  LD (ComposeCellFrontTest),A
  LD HL,ComposeCellSkip
  LD (ComposeCellFrontTest+$0001),HL
  RET

  ORG $85FA

; Compose every sprite of the pass into the view
;
; The composed cells from 2 ($77B0). The blitter $7329 for the record $9BB4
; when its +0 is set, for Rick ($9BAB), for $9BBD, then for every used record
; of table B (from $7C20, 23 bytes each) and of table A (from $7B8F, 24 bytes
; each), until their end marks.
;
; Evidence: called by MainLoopPause every pass, by the scrolls $78A5 and $7905
; and the section setup $8A6D.
;
; Witness: L1 120416 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
DrawSprites:
  LD A,$02
  LD (SpareCount),A
  LD A,(BulletRecord)
  AND A
  JP Z,DrawRick
  LD IX,BulletRecord
  CALL ComposeSprite
DrawRick:
  LD A,(RickRecord)       ; Rick's record
  AND A
  JP Z,DrawThird
  LD IX,RickRecord
  CALL ComposeSprite
DrawThird:
  LD A,(DetonatorRecord)  ; the record $9BBD
  AND A
  JP Z,DrawTableB
  LD IX,DetonatorRecord
  CALL ComposeSprite
DrawTableB:
  LD IX,SetupIm2+$0006    ; table B ($7C20, 23-byte records)
DrawTableBLoop:
  LD A,(IX+$00)           ; a record: 0 free, $FF the end
  AND A
  JP Z,DrawTableBNext
  CP $FF
  JP Z,DrawTableA
  CALL ComposeSprite
DrawTableBNext:
  LD DE,$0017             ; + 23
  ADD IX,DE
  JP DrawTableBLoop
DrawTableA:
  LD IX,Entry             ; table A ($7B8F, 24-byte records)
DrawTableALoop:
  LD A,(IX+$00)           ; a record: 0 free, $FF the end
  AND A
  JP Z,DrawTableANext
  CP $FF
  RET Z
  CALL ComposeSprite
DrawTableANext:
  LD DE,$0018             ; + 24
  ADD IX,DE
  JP DrawTableALoop

  ORG $88B1

; The cell drawer on the font; screen and buffers cleared
;
; Writes $7080 (the font) to the drawer's bases $7730 and $7777 and three zeros
; (NOPs) over the JP M at $775A, then $7A61, $8985, $8977. HL kept.
;
; Evidence: 16 runs in 11 builds (callers LevelMenu, ControlMenu, ShowEndText).
;
; Witness: L1 100 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
FontCellsMode:
  PUSH HL
  LD HL,Glyphs
  LD (DrawLevelCellBase+$0001),HL
  LD (ComposeCellBase+$0001),HL
  LD HL,$0000
  LD (ComposeCellFrontTest),HL
  LD (ComposeCellFrontTest+$0001),HL
  CALL ClearScreen
  CALL ClearRedraw
  CALL BlankView
  POP HL
  RET
