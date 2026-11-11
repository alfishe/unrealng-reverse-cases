; --------------------------------------------------------------------------------------------------------------------
; unpack.asm: The cave unpacker and the cave's set-up
;
; Each cave is 314 bytes at CaveData + 314 x (N - 1) (N = 1-32; the code computes $BEC6 + 314N): 300 bytes of two
; cells each (the low nibble first) for the 30 x 20 grid, then 14 parameter bytes copied to CaveParams $FD9A.
; CaveSetup $9313 unpacks the cave, writes the earth and wall graphics into the cell table and colours the exit door,
; the boulder and two more graphics.
; --------------------------------------------------------------------------------------------------------------------

  ORG $82B6

; Unpack cave CaveNumber into the grid and copy its 14 parameters
;
; HL = $BEC6 + 314 x CaveNumber $FD91; 300 bytes give 600 cells (low nibble
; first) into CaveGrid $FDA8, then 14 bytes to CaveParams $FD9A.
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
UnpackCave:
  LD A,(CaveNumber)
  LD B,A
  LD HL,CaveData-314
  LD DE,$013A
UnpackCaveLoop:
  ADD HL,DE
  DJNZ UnpackCaveLoop
  LD BC,$012C
  LD DE,CaveGrid
UnpackCaveLoop2:
  LD A,(HL)
  AND $0F
  LD (DE),A
  INC DE
  LD A,(HL)
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  LD (DE),A
  INC DE
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,UnpackCaveLoop2
  LD DE,CaveParams
  LD BC,$000E
  LDIR
  RET

  ORG $9305

; Write A into the 4 attributes of the graphic at HL: bright, plain, plain,
; bright
;
; Witness: L1 528 (c1, hiscore, lives, timer, rzx x32).
SetGraphicColour:
  OR $40
  LD (HL),A
  AND $3F
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  OR $40
  INC HL
  LD (HL),A
  RET

; Unpack the cave; its earth and wall graphics and its four colours
;
; UnpackCave $82B6; EarthGraphic $FDA0 into the table word $800C (cell 6),
; WallGraphic $FDA2 into $800A (cell 5); DoorColour into the exit graphic
; $9B08, BoulderColour into $9B2C, Wall1Colour into $9CB8, EarthColour into
; $9B50 (SetGraphicColour).
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
CaveSetup:
  CALL UnpackCave
  LD HL,(EarthGraphic)
  LD (CellEarthGfx),HL
  LD HL,(WallGraphic)
  LD (CellWallGfx),HL
  LD DE,DoorColour
  LD A,(DE)
  INC DE
  LD HL,CellGraphics
  CALL SetGraphicColour
  LD A,(DE)
  INC DE
  LD HL,GfxBoulder
  CALL SetGraphicColour
  LD A,(DE)
  INC DE
  LD HL,GfxWall1
  CALL SetGraphicColour
  LD A,(DE)
  INC DE
  LD HL,GfxEarth
  CALL SetGraphicColour
  RET

; ClearScreen, ColourCycleInk = $45
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
ClearScreenCave:
  CALL ClearScreen
  LD A,$45
  LD (ColourCycleInk),A
  RET

  ORG $A600

; CaveSetup, then the boulder colour into the 7 dissolve frames
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
CaveSetupAll:
  CALL CaveSetup
  LD A,(GfxBoulder)
  LD HL,GfxDissolve
  LD DE,$0021
  LD B,$07
CaveSetupAllLoop:
  CALL SetGraphicColour
  ADD HL,DE
  DJNZ CaveSetupAllLoop
  RET
