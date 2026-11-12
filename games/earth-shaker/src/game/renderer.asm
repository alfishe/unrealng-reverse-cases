; --------------------------------------------------------------------------------------------------------------------
; renderer.asm: The cell table, the cell graphics and the cave window
;
; The screen shows a window of 16 x 11 cells of the 30 x 20 cave; a cell is 16 x 16 pixels (2 x 2 characters) with its
; own 4 attributes. CellGraphicsTable $8000 gives the graphic of each cell code 0-31 (the low 5 bits of the cell). A
; graphic is 36 bytes: 4 attributes (top left, top right, bottom right, bottom left), then 32 pixel bytes in zigzag
; order (even pixel lines left then right, odd lines right then left), drawn by DrawCell $8F60.
;
; The animated cells are animated by rewriting their table words each pass (AnimateCells $900B: the player;
; AnimateTable $90B2: the specials and, in the falling-earth caves, the earth and empty frames) and the gem colour
; bytes (DrawPass $8D46). The cave's earth and wall words are set from its parameters (CaveSetup $9313).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8000

; The graphic of each cell code 0-31: 32 addresses of 36-byte graphics
;
; Read through CellGraphicAddr $8D66 by DrawCell $8F60 (every cell drawn, in
; every build). Words 3 and 4 (the player), 6 and 5 (earth, wall) and the
; animated words 8, 9, 10 and 12-15 are rewritten during play, and word 0 (the
; empty cell) in the falling-earth caves: EarthAnimStep $FB70 points it at a
; frame of EmptyFrames $FAE0 each pass, and SetEarthFalls $FB84 puts
; BlankGraphic $AA72 back at every cave start. Words 16 and 21 ($8020, $802A)
; are never read: the codes $10 and $15 step on (AnimateCellCodes $937E) before
; the window is drawn in the same pass. Words 1 (the exit: it flashes by its
; attributes, ExitFlash $905B), 2 (the boulder), 7 (the gem: DrawPass $8D46
; cycles its attribute bytes) and 11 (the switch) are never written (code and
; the state logs). Words 28-31 are $0000: no such cells.
CellGraphicsTable:
  DEFW BlankGraphic
CellExitGfx:
  DEFW CellGraphics       ; cell 1
CellBoulderGfx:
  DEFW GfxBoulder         ; cell 2
CellPlayerRightGfx:
  DEFW GfxPlayerRight     ; cell 3
CellPlayerLeftGfx:
  DEFW GfxPlayerLeft      ; cell 4
CellWallGfx:
  DEFW GfxWall2           ; cell 5
CellEarthGfx:
  DEFW GfxEarth           ; cell 6
CellGemGfx:
  DEFW GfxGem             ; cell 7
CellJellyBeanGfx:
  DEFW GfxJellyBean       ; cell 8
CellForceFieldGfx:
  DEFW $A378              ; cell 9
CellAntiGravGfx:
  DEFW GfxAntiGrav        ; cell 10
CellSwitchGfx:
  DEFW GfxSwitch          ; cell 11
CellPotionGfx:
  DEFW CellGraphics2      ; cell 12
CellTeleporterGfx:
  DEFW $A0A8              ; cell 13
CellBubbleGfx:
  DEFW GfxBubble          ; cell 14
CellFireGfx:
  DEFW GfxFire            ; cell 15
CellBurstGfx:
  DEFW GfxBurst           ; cell 16 ($10-$14: the bubble burst frames)
  DEFW GfxBurst
  DEFW $A594
  DEFW $A5B8
  DEFW $A5DC
CellDissolveGfx:
  DEFW GfxDissolve        ; cell 21 ($15-$1B: the boulder dissolving in fire)
  DEFW $A1C8
  DEFW $A1EC
  DEFW $A210
  DEFW $A234
  DEFW $A258
  DEFW $A27C
CellUnusedGfx:
  DEFW $0000              ; cell 28 (28-31: no such cells, $0000)
  DEFW $0000
  DEFW $0000
  DEFW $0000

; Print an 8 x 8 glyph at a character cell
;
; B = the character row (0-23), C = the column (0-31), DE = the 8 glyph bytes.
; Out: DE past the glyph, HL the last screen byte. The font, the HUD digits and
; the map glyphs go through it.
;
; Witness: L1 90104 (c1, hiscore, lives, menu, timer, rzx01-rzx32).
PrintGlyph:
  LD A,B
  AND $F8
  ADD A,$40
  LD H,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD L,A
  PUSH BC
  LD B,$08
PrintGlyphLoop:
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  DJNZ PrintGlyphLoop
  POP BC
  RET

  ORG $81B9

; The attribute address of character cell B, C into HL
;
; B = the row, C = the column. HL = $5800 + 32B + C.
;
; Witness: L1 3860 (c1, hiscore, lives, menu, timer, rzx01-rzx32).
AttrAddr:
  LD A,B
  SRA A
  SRA A
  SRA A
  ADD A,$58
  LD H,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD L,A
  RET

  ORG $8265

; The attribute address of character cell B, C into DE
;
; B = the row, C = the column. DE = $5800 + 32B + C.
;
; Witness: L1 7714880 (c1, hiscore, lives, timer, rzx01-rzx32).
AttrAddrDE:
  LD A,B
  SRA A
  SRA A
  SRA A
  ADD A,$58
  LD D,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD E,A
  RET

; Leftover: 62 bytes, never run
AttrAddrPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

  ORG $8964

; The screen address of pixel line C, column 0, into HL
;
; Witness: L1 19296 (c1, lives, menu).
LineAddr:
  LD A,C
  AND $38
  RLCA
  RLCA
  LD L,A
  LD A,C
  AND $C0
  RRCA
  RRCA
  RRCA
  OR $40
  LD H,A
  LD A,C
  AND $07
  OR H
  LD H,A
  RET

  ORG $8D46

; The colours and animations of a pass
;
; ColourCycleInk into the 4 attributes of the gem graphic $9B74-$9B77 (ink, ink
; - 1, ink - 2, ink - 1), AnimateCells $900B, AnimateTable $90B2.
;
; Witness: L1 43775 (c1, hiscore, lives, timer, rzx01-rzx32).
DrawPass:
  LD A,(ColourCycleInk)
  LD HL,GfxGem
  LD (HL),A
  DEC A
  INC HL
  LD (HL),A
  DEC A
  INC HL
  LD (HL),A
  INC A
  INC HL
  LD (HL),A
  CALL AnimateCells
  CALL AnimateTable
  RET

  ORG $8D66

; DE = the table word of cell A: $8000 + 2 x (A AND $1F)
;
; Witness: L1 7714880 (c1, hiscore, lives, timer, rzx01-rzx32).
CellGraphicAddr:
  AND $1F
  RLCA
  LD E,A
  LD D,$80
  RET

; Leftover: 8 bytes, never run
CellGraphicAddrPad:
  DEFB $11,$1F,$00,$19,$77,$23,$77,$C9

; Draw the window at ViewOrigin
;
; Witness: L1 43775 (c1, hiscore, lives, timer, rzx01-rzx32).
DrawWindowAtOrigin:
  CALL DrawPass

; Draw 11 rows of 16 cells from cell index HL
;
; DrawCell $8F60 for each; B = the character row (0, 2, ... 20), C = the column
; (0, 2, ... 30).
;
; Witness: L1 43834 (c1, hiscore, lives, timer, rzx01-rzx32).
DrawWindow:
  LD DE,CaveGrid
  ADD HL,DE
  LD BC,$0000
DrawWindowLoop:
  LD A,(HL)
  PUSH DE
  PUSH AF
  PUSH BC
  PUSH HL
  CALL DrawCell
  POP HL
  POP BC
  POP AF
  POP DE
  NOP
  NOP
  NOP
  NOP
  NOP
  INC HL
  INC C
  INC C
  LD A,C
  CP $20
  JR NZ,DrawWindowLoop
  LD C,$00
  INC B
  INC B
  LD DE,$000E
  ADD HL,DE
  LD A,B
  CP $16
  JR NZ,DrawWindowLoop
  RET

; The window's first cell from the player's place
;
; Row = PlayerIndex / 30, column the rest; the column clamped to 8-22, the row
; to 5-14; ViewOrigin $FD70 = 30 x (row - 5) + column - 8 (computed as 30 x
; (row + 1) + column - 188). The window is drawn later, by MapKey's CALL
; DrawWindowAtOrigin.
;
; Witness: L1 43833 (c1, hiscore, lives, timer, rzx01-rzx32).
WindowOrigin:
  LD BC,$0000
  LD HL,(PlayerIndex)
  LD DE,$001E
WindowOriginLoop:
  INC C
  SBC HL,DE
  JR NC,WindowOriginLoop
  DEC C
  ADD HL,DE
  LD A,L
  CP $08
  JR NC,WindowOriginSkip
  LD L,$08
WindowOriginSkip:
  CP $16
  JR C,WindowOriginSkip2
  LD L,$16
WindowOriginSkip2:
  LD A,C
  CP $05
  JR NC,WindowOriginSkip3
  LD C,$05
WindowOriginSkip3:
  CP $0E
  JR C,WindowOriginSkip4
  LD C,$0E
WindowOriginSkip4:
  LD DE,$001E
  LD B,C
  INC B
  LD H,$00
WindowOriginLoop2:
  ADD HL,DE
  DJNZ WindowOriginLoop2
  LD DE,$00BC
  SBC HL,DE
  LD (ViewOrigin),HL
  RET

  ORG $8F60

; Draw cell code A at character row B, column C (2 x 2 characters)
;
; The graphic from CellGraphicsTable; its 4 attributes through AttrAddrDE
; $8265, then 32 pixel bytes in zigzag order. Valid on even character rows: SET
; 5,E for the lower half needs bit 5 of E clear. The graphic pointer steps with
; INC L inside each 4-byte group, so no group may cross a 256-byte page.
;
; Witness: L1 7714880 (c1, hiscore, lives, timer, rzx01-rzx32).
DrawCell:
  CALL CellGraphicAddr
  NOP
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  CALL AttrAddrDE
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  SET 5,E
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  RES 5,E
  LD A,D
  AND $03
  RLCA
  RLCA
  RLCA
  OR $40
  LD D,A
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  LD A,D
  SUB $07
  LD D,A
  SET 5,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  DEC E
  LD A,(HL)
  LD (DE),A
  RET

; Step the player's frames (4 frames, 36 bytes apart)
;
; AnimPhase $FD72 0-3: the player's table words $8006 / $8008 from $9B98 /
; $9C28 + 36 x phase. Out: HL = ViewOrigin.
;
; Witness: L1 43775 (c1, hiscore, lives, timer, rzx01-rzx32).
AnimateCells:
  LD A,(AnimPhase)
  INC A
  CP $04
  JR NZ,AnimateCellsSkip
  XOR A
  LD (AnimPhase),A
  LD HL,GfxPlayerRight
  LD (CellPlayerRightGfx),HL
  LD HL,GfxPlayerLeft
  LD (CellPlayerLeftGfx),HL
  LD HL,(ViewOrigin)
  RET
AnimateCellsSkip:
  LD (AnimPhase),A
  LD HL,(CellPlayerRightGfx)
  LD DE,$0024
  ADD HL,DE
  LD (CellPlayerRightGfx),HL
  LD HL,(CellPlayerLeftGfx)
  ADD HL,DE
  LD (CellPlayerLeftGfx),HL
  LD HL,(ViewOrigin)
  RET

  ORG $90B2

; Step the animated table words of the specials
;
; EarthAnim $9DFC, then the words of cells 8, 9, $0A, $0C, $0D, $0E, $0F from
; frame AnimPhase.
;
; Witness: L1 43775 (c1, hiscore, lives, timer, rzx01-rzx32).
AnimateTable:
  PUSH HL
  PUSH DE
  PUSH BC
  CALL EarthAnim
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD DE,$0024
  LD HL,GfxFire
  LD A,(AnimPhase)
  OR A
  JR Z,AnimateTableSkip
  LD B,A
AnimateTableLoop:
  ADD HL,DE
  DJNZ AnimateTableLoop
AnimateTableSkip:
  LD (CellFireGfx),HL
  LD HL,CellGraphics2
  LD A,(AnimPhase)
  OR A
  JR Z,AnimateTableSkip2
  LD B,A
AnimateTableLoop2:
  ADD HL,DE
  DJNZ AnimateTableLoop2
AnimateTableSkip2:
  LD (CellPotionGfx),HL
  LD HL,GfxBubble
  LD A,(AnimPhase)
  OR A
  JR Z,AnimateTableSkip3
  LD B,A
AnimateTableLoop3:
  ADD HL,DE
  DJNZ AnimateTableLoop3
AnimateTableSkip3:
  LD (CellBubbleGfx),HL
  LD A,(ForceFieldPhase)
  INC A
  AND $07
  LD (ForceFieldPhase),A
  LD HL,GfxForceField
  LD A,(ForceFieldPhase)
  OR A
  JR Z,AnimateTableSkip4
  LD B,A
AnimateTableLoop4:
  ADD HL,DE
  DJNZ AnimateTableLoop4
AnimateTableSkip4:
  LD (CellForceFieldGfx),HL
  LD HL,GfxAntiGrav
  LD A,(AnimPhase)
  OR A
  JR Z,AnimateTableSkip5
  LD B,A
AnimateTableLoop5:
  ADD HL,DE
  DJNZ AnimateTableLoop5
AnimateTableSkip5:
  LD (CellAntiGravGfx),HL
  LD A,(TeleporterPhase)
  INC A
  CP $0C
  JR NZ,AnimateTableSkip6
  XOR A
AnimateTableSkip6:
  LD (TeleporterPhase),A
  LD HL,GfxTeleporter
  LD A,(TeleporterPhase)
  OR A
  JR Z,AnimateTableSkip7
  LD B,A
AnimateTableLoop6:
  ADD HL,DE
  DJNZ AnimateTableLoop6
AnimateTableSkip7:
  LD (CellTeleporterGfx),HL
  LD HL,GfxJellyBean
  LD A,(AnimPhase)
  OR A
  JR Z,AnimateTableSkip8
  LD B,A
AnimateTableLoop7:
  ADD HL,DE
  DJNZ AnimateTableLoop7
AnimateTableSkip8:
  LD (CellJellyBeanGfx),HL
  POP BC
  POP DE
  POP HL
  RET

  ORG $9B08

; The cell graphics, slots 0-20 (36 bytes each)
CellGraphics:
  INCBIN "res/graphics/cells-a.bin",$0000,36
GfxBoulder:
  INCBIN "res/graphics/cells-a.bin",$0024,36
GfxEarth:
  INCBIN "res/graphics/cells-a.bin",$0048,36
GfxGem:
  INCBIN "res/graphics/cells-a.bin",$006C,36
GfxPlayerRight:
  INCBIN "res/graphics/cells-a.bin",$0090,144
GfxPlayerLeft:
  INCBIN "res/graphics/cells-a.bin",$0120,144
GfxWall1:
  INCBIN "res/graphics/cells-a.bin",$01B0,36
GfxWall2:
  INCBIN "res/graphics/cells-a.bin",$01D4,36
GfxWall3:
  INCBIN "res/graphics/cells-a.bin",$01F8,36
GfxWall4:
  INCBIN "res/graphics/cells-a.bin",$021C,36
GfxWall5:
  INCBIN "res/graphics/cells-a.bin",$0240,36
GfxWall6:
  INCBIN "res/graphics/cells-a.bin",$0264,36
GfxSpare:
  INCBIN "res/graphics/cells-a.bin",$0288,36
GfxDeathRight:
  INCBIN "res/graphics/cells-a.bin",$02AC,36
GfxDeathLeft:
  INCBIN "res/graphics/cells-a.bin",$02D0,36

  ORG $9E1A

; Leftover: 6 bytes after EarthAnim
EarthAnimPad:
  INCBIN "res/leftovers/earth-anim-pad.bin",$0000,6

; The cell graphics, slots 22-77 (36 bytes each)
CellGraphics2:
  INCBIN "res/graphics/cells-b.bin",$0000,144
GfxSwitch:
  INCBIN "res/graphics/cells-b.bin",$0090,36
GfxFire:
  INCBIN "res/graphics/cells-b.bin",$00B4,144
GfxTeleporter:
  INCBIN "res/graphics/cells-b.bin",$0144,432
GfxBubble:
  INCBIN "res/graphics/cells-b.bin",$02F4,144
GfxDissolve:
  INCBIN "res/graphics/cells-b.bin",$0384,252
GfxForceField:
  INCBIN "res/graphics/cells-b.bin",$0480,288
GfxAntiGrav:
  INCBIN "res/graphics/cells-b.bin",$05A0,144
GfxFallingEarth:
  INCBIN "res/graphics/cells-b.bin",$0630,144
GfxJellyBean:
  INCBIN "res/graphics/cells-b.bin",$06C0,144
GfxBurst:
  INCBIN "res/graphics/cells-b.bin",$0750,144

  ORG $ED28

; Five more cell graphics (36 bytes each)
ExtraGraphics:
  INCBIN "res/graphics/extra-a.bin",$0000,36
GfxExtraWall2:
  INCBIN "res/graphics/extra-a.bin",$0024,36
GfxExtraWall3:
  INCBIN "res/graphics/extra-a.bin",$0048,36
GfxExtraWall4:
  INCBIN "res/graphics/extra-a.bin",$006C,36
GfxExtraWall5:
  INCBIN "res/graphics/extra-a.bin",$0090,36

; Zeros (36 bytes)
ExtraGraphicsPad:
  DEFS $24

; One more cell graphic
ExtraGraphic2:
  INCBIN "res/graphics/extra-b.bin",$0000,36

  ORG $EF00

; One more cell graphic
ExtraGraphic3:
  INCBIN "res/graphics/extra-c.bin",$0000,36

; Leftover: 476 bytes
ExtraGraphic3Pad:
  INCBIN "res/leftovers/graphic-pad.bin",$0000,476

  ORG $FAE0

; Four frames of the empty cell in the falling-earth caves: all zeros
;
; EarthAnimStep $FB70 points table word 0 (the empty cell) at frame AnimPhase
; each pass when the earth is GfxFallingEarth; every byte is 0, so the empty
; cell looks as BlankGraphic $AA72 does (an animation hook with no picture).
; Witness: L1 6610 entries of EarthAnimStep (the rzx builds of caves 13, 17,
; 22, 24, 26).
EmptyFrames:
  INCBIN "res/graphics/empty-frames.bin",$0000,144

  ORG $FBA0

; Two more cell graphics
ExtraGraphic4:
  INCBIN "res/graphics/extra-d.bin",$0000,36
GfxExtraWall9:
  INCBIN "res/graphics/extra-d.bin",$0024,36

; Zeros (24 bytes)
ExtraGraphic4Pad:
  DEFS $18
