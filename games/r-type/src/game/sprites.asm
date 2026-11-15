; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The sprite drawers and the cell map
; --------------------------------------------------------------------------------------------------------------------

; Draw an object (D, E its size, HL its cells) at row B column C into the
; shadows and SolidMap
;
; Each cell is 9 bytes (attribute, 8 pixel lines). A cell off the play field is
; skipped. CellFree decides whether it may be drawn over what is there;
; CellMark writes DrawTag into SolidMap and the attribute into PlayAttrs; the
; pixel bytes go to the pixel shadow. While DrawPrepare has the hits on, what
; was there is gathered into HitList.
;
; Witness: L1 450223 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
DrawSprite:
  PUSH BC
  PUSH DE
  EXX
  POP DE
  POP BC
  LD A,B
  ADD A,D
  LD H,A
  LD A,C
  LD D,A
  ADD A,E
  LD L,A
l_8D09:
  EXX
  LD A,(HL)
  CP $36
  JP Z,l_8D4C
  EXX
  LD A,B
  CP $14
  JP NC,l_8D5A
  LD A,C
  CP $1F
  JP NC,l_8D5A
  AND A
  JP Z,l_8D5A
  CALL CellFree
  JP NC,l_8D5B
  CALL CellMark
  JP Z,l_8D5B
  LD D,A
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  LD A,(HL)
  LD (DE),A
l_8D4C:
  INC HL
  EXX
  INC C
  LD A,C
  CP L
  JR NZ,l_8D09
  INC B
  LD A,B
  CP H
  RET Z
  LD C,D
  JR l_8D09
l_8D5A:
  EXX
l_8D5B:
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  JR l_8D4C

; Draw an object mirrored left to right
;
; Witness: L1 27030 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
DrawSpriteMirrored:
  PUSH BC
  PUSH DE
  LD B,$5D
  EXX
  POP DE
  POP BC
  LD A,B
  ADD A,D
  LD H,A
  LD A,C
  DEC A
  LD L,A
  ADD A,E
  LD D,A
  LD C,A
l_8D75:
  EXX
  LD A,(HL)
  CP $36
  JR Z,l_8DBA
  EXX
  LD A,B
  CP $14
  JR NC,l_8DC8
  LD A,C
  CP $1F
  JR NC,l_8DC8
  AND A
  JR Z,l_8DC8
  CALL CellFree
  JR NC,l_8DC9
  CALL CellMark
  JR Z,l_8DC9
  LD D,A
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC D
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC D
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC D
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC D
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC D
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC D
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC D
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
l_8DBA:
  INC HL
  EXX
  DEC C
  LD A,C
  CP L
  JR NZ,l_8D75
  INC B
  LD A,B
  CP H
  RET Z
  LD C,D
  JR l_8D75
l_8DC8:
  EXX
l_8DC9:
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  JR l_8DBA

; Draw an object upside down
;
; Witness: L1 26350 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
DrawSpriteFlipped:
  PUSH BC
  PUSH DE
  EXX
  POP DE
  POP BC
  LD A,B
  DEC A
  LD H,A
  ADD A,D
  LD B,A
  LD A,C
  LD D,A
  ADD A,E
  LD L,A
l_8DE1:
  EXX
  LD A,(HL)
  CP $36
  JR Z,l_8E10
  EXX
  LD A,B
  CP $14
  JR NC,l_8E1E
  LD A,C
  CP $1F
  JR NC,l_8E1E
  AND A
  JR Z,l_8E1E
  CALL CellFree
  JR NC,l_8E1F
  CALL CellMark
  JR Z,l_8E1F
  ADD A,$07
  LD D,A
  LD IXL,$07
l_8E05:
  LD A,(HL)
  LD (DE),A
  INC HL
  DEC D
  DEC IXL
  JP NZ,l_8E05
  LD A,(HL)
  LD (DE),A
l_8E10:
  INC HL
  EXX
  INC C
  LD A,C
  CP L
  JR NZ,l_8DE1
  DEC B
  LD A,B
  CP H
  RET Z
  LD C,D
  JR l_8DE1
l_8E1E:
  EXX
l_8E1F:
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  JR l_8E10

; Draw an object mirrored and upside down
;
; Witness: L1 13308 (ending, l1-l8).
DrawSpriteBoth:
  PUSH BC
  PUSH DE
  LD B,$5D
  EXX
  POP DE
  POP BC
  LD A,B
  DEC A
  LD H,A
  ADD A,D
  LD B,A
  LD A,C
  DEC A
  LD L,A
  ADD A,E
  LD D,A
  LD C,A
l_8E3B:
  EXX
  LD A,(HL)
  CP $36
  JR Z,l_8E6C
  EXX
  LD A,B
  CP $14
  JR NC,l_8E7A
  LD A,C
  CP $1F
  JR NC,l_8E7A
  AND A
  JR Z,l_8E7A
  CALL CellFree
  JR NC,l_8E7B
  CALL CellMark
  JR Z,l_8E7B
  ADD A,$07
  LD D,A
  LD IXL,$07
l_8E5F:
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  DEC D
  DEC IXL
  JP NZ,l_8E5F
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
l_8E6C:
  INC HL
  EXX
  DEC C
  LD A,C
  CP L
  JR NZ,l_8E3B
  DEC B
  LD A,B
  CP H
  RET Z
  LD C,D
  JR l_8E3B
l_8E7A:
  EXX
l_8E7B:
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  JR l_8E6C

; D, E, HL = the size and cells of the level's object A (LevelObjects)
;
; Witness: L1 198340 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
LevelObject:
  LD DE,(LevelObjects)
  JP ObjectEntry

; D, E, HL = the size and cells of the game's object A (GameObjects)
;
; Witness: L1 317051 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
GameObject:
  LD (DrawTag),A
  LD DE,GameObjects

; ObjectEntry
;
; Used by the routine at LevelObject.
ObjectEntry:
  LD H,$00                ; 4 bytes an entry
  LD L,A
  DEC L
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET

; Write DrawTag into the SolidMap cell and the attribute into PlayAttrs
;
; Witness: L1 1541974 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
CellMark:
  LD A,(DrawTag)
  LD (DE),A
  LD A,D
  SUB $06
  LD D,A
  LD A,(CellMark+$000F)
  AND A
  JR Z,l_8EB5
  LD A,$00
  LD (DE),A
  JR l_8EB7
l_8EB5:
  LD A,(HL)
  LD (DE),A
l_8EB7:
  INC HL
  LD A,D
  AND $03
  RLCA
  RLCA
  RLCA
  ADD A,$60
  AND A
  RET

; Carry when the cell at row B column C may be drawn on; a taken cell may be
; gathered as a hit
;
; Reads SolidMap ($7E00 + row x 32 + column). A taken cell returns at the RET
; here unless DrawPrepare made it a NOP: then the tag goes into HitList (14 at
; most) and a soft cell's ($FA) position into HitCells.
;
; Witness: L1 2025510 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
CellFree:
  LD A,B
  RRCA
  RRCA
  RRCA
  AND $03
  ADD A,$7E
  EX AF,AF'
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  EXX
  LD E,A
  EX AF,AF'
  LD D,A
  LD A,(DE)
  AND A
  JR Z,CellFreeEmpty
  RET
CollectHit:
  LD A,(HitCount)         ; the code behind the patched RET
  CP $0E
  RET Z
  INC A
  LD (HitCount),A
  PUSH BC
  LD BC,HitList
  ADD A,C
  LD C,A
  LD A,(DE)
  LD (BC),A
  CP $FA
  JR NZ,l_8F08
  LD A,(HitCellCount)
  INC A
  LD (HitCellCount),A
  DEC A
  ADD A,A
  LD BC,HitCells
  ADD A,C
  LD C,A
  EXX
  LD A,C
  EXX
  LD (BC),A
  INC C
  EXX
  LD A,B
  EXX
  LD (BC),A
l_8F08:
  AND A
  POP BC
  RET
CellFreeEmpty:
  INC E                   ; the empty cell's test
  LD A,(DE)
  DEC E
  CP $DC
  RET NC
  LD A,(ScrollStep)
  CP $07
  RET NZ
  INC E
  INC E
  LD A,(DE)
  DEC E
  DEC E
  CP $DC
  RET
