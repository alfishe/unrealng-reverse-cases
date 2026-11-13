; --------------------------------------------------------------------------------------------------------------------
; levels.asm: The level data, the cells and the level builder
;
; The 100 levels are 75-byte records at LevelRecords $8C3C: 36 cells (a wall type in the high nibble, a platform type
; in the low one), the ball's start cell, the prizes to take, the cell the exit appears in, and an object for each
; cell. BuildLevel $CF2E copies the record of Level $AB00 to LevelRecord $AA20 and splits the cells into CellPlatforms
; $AA6B and CellWalls $AA8F. The text form is src/res/levels/levels.txt.
;
; The cell helpers: a level is 36 cells (6 × 6), each with a platform, a wall, an object, a fire flag and a brick
; count in the tables $AA47-$AAFA.
;
; BuildLevel copies the level's 75-byte record from the level data $8C3C to the work area $AA20, splits the 36 cells
; into platforms and walls, and draws every cell, object, wall and the ball.
; --------------------------------------------------------------------------------------------------------------------

; The 100 level records, 75 bytes each (level 0 first)
;
; BuildLevel $CF2E reads record Level $AB00 (as $8BF1 + 75 x (Level + 1)) once
; per life start. Record: +0..+35 the cells, row by row from the top, 6 a row
; (wall << 4 | platform); +36 the start cell; +37 the prizes; +38 the exit's
; cell; +39..+74 the objects (0 none, 1-40).
;
; Witness: 88 levels read by the RZX recordings rzx l00-l99 (the record of each
; level they reach); the other levels are read by stage 2's level recordings
; (work/stage2/rec).
LevelRecords:
  INCBIN "res/levels/levels.bin",$0000,7500

; 117 zero bytes after the last record, never read
LevelsEnd:
  DEFS $75

  ORG $BB05

; The screen address of the ball's cell: $AB2D = CellAddrs $E131[$AA44]
;
; A CPC screen address (the game draws in CPC coordinates, ScreenAddrToLine
; $C71F converts). Called by MainLoop ($ACCC) and the level builder.
;
; Witness: L1 98391 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
CellScreenAddr:
  AND A
  LD A,(BallCell)
  RLA
  LD E,A
  LD D,$00
  LD IX,CellAddresses
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (CellScrAddr),HL
  RET

; The screen address of wall A: $AB2F = WallAddrs $E179[A]
;
; Input A, a cell. Called by the wall handlers and the builder ($C93E, $CB81,
; $D1D3-$D1F7).
;
; Witness: L1 673 (c1, fire, menu, l x9, rzx x59).
WallScreenAddr:
  AND A
  RLA
  LD E,A
  LD D,$00
  LD IX,WallAddresses
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (WallScrAddr),HL
  RET

; The platform and object of the ball's cell: $AB1C, $AB1D
;
; $AB1C = PlatformCells $AA6B[$AA44], $AB1D = ObjectCells $AA47[$AA44]. Called
; by MainLoop ($ACC9) every frame and the handlers.
;
; Witness: L1 97066 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
ReadCell:
  AND A
  LD A,(BallCell)
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  LD (CellPlatform),A
  LD HL,CellObjects
  ADD HL,DE
  LD A,(HL)
  LD (CellObject),A
  RET

; The wall of cell A: $AB1E = WallCells $AA8F[A]; never called
;
; Known only from the code: no caller, and nothing reads $AB1E.
;
; Witness: L1 0 ().
ReadWallCell:
  LD D,$00
  LD E,A
  LD HL,CellWalls
  ADD HL,DE
  LD A,(HL)
  LD (CellWall),A
  RET

  ORG $CF2E

; Build and draw level Level: copy the record, split the cells, draw them and
; the ball
;
; The CPC inks of the level (LevelColours $E119 row Level mod 7 + 1) go to
; $B6DB, a RET on the Spectrum. The work area $AA20-$AAFA (219 bytes) is
; cleared, the record at $8C3C + 75 x Level is copied to $AA20 (byte 36, the
; start cell, also to $AB1A), and each of the 36 cells is split: the high
; nibble to the walls $AA8F, the low nibble to the platforms $AA6B. Then
; BuildLevelCell draws every cell. Last the ball: sprite $67E8, cell $AA44 =
; the start cell, its screen address $AA03 = the cell's + $2F62, drawn by XOR
; (10 lines of 4 bytes). Called by the main loop at $AC7D, $AC86 and $ACBF (75
; builds in the recordings).
;
; Witness: L1 94 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
BuildLevel:
  AND A
  LD B,$07
  LD A,(Level)
LevelMod7:
  CP $07                  ; A = Level mod 7 by subtraction
  JR C,LevelColourRow
  SUB B
  JR LevelMod7
LevelColourRow:
  AND A
  INC A
  LD IX,LevelColours
  LD DE,$0003
  LD B,A
LevelColourSeek:
  ADD IX,DE
  DJNZ LevelColourSeek
  LD A,(IX+$00)
  LD B,A
  LD C,A
  LD A,$01
  CALL NoOp
  LD A,(IX+$01)
  LD B,A
  LD C,A
  LD A,$02
  CALL NoOp
  LD A,(IX+$02)
  LD B,A
  LD C,A
  LD A,$03
  CALL NoOp
  AND A
  LD B,$DB
  LD IX,LevelRecord
ClearWorkArea:
  LD (IX+$00),$00         ; $AA20-$AAFA to 0
  INC IX
  DJNZ ClearWorkArea
  LD A,(Level)
  LD B,A
  INC B
  LD DE,$004B
  LD HL,Unused8385+$086C
SeekLevelRecord:
  ADD HL,DE               ; HL = $8BF1 + 75 x (Level + 1) = $8C3C + 75 x Level
  DJNZ SeekLevelRecord
  LD BC,$0024
  ADD HL,BC
  LD A,(HL)
  LD (StartCell),A
  SBC HL,BC
  LD DE,LevelRecord
  LD BC,$004B
  LDIR
  LD B,$24
SplitCell:
  AND A                   ; cell 36 - B: the high nibble to $AA8F, the low to
                          ; $AA6B
  LD HL,LevelRecord
  LD A,$24
  SUB B
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  LD (CellByte),A
  AND $F0
  RRA
  RRA
  RRA
  RRA
  LD IX,CellWalls
  ADD IX,DE
  LD (IX+$00),A
  LD A,(CellByte)
  AND $0F
  LD IX,CellPlatforms
  ADD IX,DE
  LD (IX+$00),A
  DJNZ SplitCell
  LD B,$24

; Draw cell 36 - B: its platform through PlatformDrawTable
;
; $AA44 = the cell, $AA07 = the cell as a word, $AB2D its screen address
; ($BB05), then a jump to PlatformDrawTable[platform].
;
; Witness: L1 3363 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
BuildLevelCell:
  AND A
  PUSH BC
  LD HL,CellPlatforms
  LD A,$24
  SUB B
  LD (BallCell),A
  LD E,A
  LD D,$00
  LD (CellIndex),DE
  ADD HL,DE
  LD A,(HL)
  RLA
  LD E,A
  LD D,$00
  LD IX,PlatformDrawTable
  ADD IX,DE
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  CALL CellScreenAddr
  POP IX
  JP (IX)

; Draw the cell's object and its wall
;
; Object kind K = $AA47[cell]; if not 0 the sprite $6CB0 + 56 K is drawn at
; $AB2D - $9E with ink ObjectInks[K] (14 lines of 4 bytes, $E3E5). Then a jump
; to WallDrawTable[$AA8F[cell]].
;
; Witness: L1 3363 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
BuildLevelObject:
  AND A
  LD DE,(CellIndex)
  LD HL,CellObjects
  ADD HL,DE
  LD A,(HL)
  LD HL,BallPictures2+$0248
  CP $00
  JR Z,BuildLevelWall
  LD B,A
  LD DE,$0038
SeekObjectSprite:
  ADD HL,DE
  DJNZ SeekObjectSprite
  EX DE,HL
  LD HL,(CellScrAddr)
  LD BC,$FF62
  ADD HL,BC
  LD (SeekObjectSprite+$0014),A
  LD IX,ObjectInks
  LD C,(IX+$00)           ; LD C,(IX+K): BuildLevelObject writes K into the
                          ; displacement at $D01D
  LD A,$04
  LD (SpriteWidth),A
  LD B,$0E
  CALL XorSpriteColoured
BuildLevelWall:
  AND A
  LD DE,(CellIndex)
  LD HL,CellWalls
  ADD HL,DE
  LD A,(HL)
  RLA
  LD E,A
  LD D,$00
  LD IX,WallDrawTable
  ADD IX,DE
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  POP IX
  JP (IX)

; The next cell, or the ball when all 36 are drawn
;
; Witness: L1 3362 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
BuildLevelNextCell:
  POP BC
  DEC B
  JP NZ,BuildLevelCell
  LD HL,BallPictures
  LD (BallSprite),HL
  LD A,(StartCell)
  LD (BallCell),A
  CALL CellScreenAddr
  LD BC,$2F62
  ADD HL,BC
  LD (BallScrAddr),HL
  PUSH HL
  LD HL,BallPictures
  CALL PlayerBallSprite
  EX DE,HL
  POP HL
  LD A,$04
  LD (SpriteWidth),A
  LD B,$0A
  CALL XorSprite
  RET

  ORG $E0C4

; 85 bytes of small numbers, never read
;
; Known only from the recordings: no read and no reader in the code. Pairs of
; values 0-$16; their meaning is not known.
LevelLeftover:
  INCBIN "res/leftovers/e0c4.bin",$0000,85

; The CPC inks of the three pens, a row for each level mod 7
;
; BuildLevel reads row Level mod 7 + 1 (the first row, $E119-$E11B, is never
; read) and passes the three values (CPC firmware colours 0-26) to $B6DB, which
; on the Spectrum returns at once: a leftover of the Amstrad version.
LevelColours:
  INCBIN "res/tables/level-colours.bin",$0000,24

  ORG $E1C9

; The texts of a level editor's menu, letters coded A = 1, never read
;
; "RETOUR", "EDITEUR", "CHARGER TABLEAUX", "SAUVER TABLEAUX", "EFFACER
; TABLEAU", "QUITTER EDITEUR", each ended by 0: the French menu of a level
; editor the game does not have. Known only from the bytes: nothing reads them.
EditorTexts:
  INCBIN "res/texts/editor.bin",$0000,81

; Four zero bytes before the editor's letters, never read
EditorFontPad:
  DEFS $04

; The letters A-Z of the editor, 5 lines of 8 pixels each, never read
;
; 26 one-colour glyphs for EditorTexts. Two bytes ($E277-$E278) are read in the
; recordings, by no reader of the font: known only from the recordings.
EditorFont:
  INCBIN "res/sprites/editor-font.bin",$0000,130
