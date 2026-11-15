; --------------------------------------------------------------------------------------------------------------------
; util.asm: Text, cells, the score and the boss
; --------------------------------------------------------------------------------------------------------------------

; A = the next ROM byte at RandomPtr
;
; Witness: L1 2364 (boss, ending, l7, l8).
NextRandom:
  LD HL,(RandomPtr)
  INC HL
  LD (RandomPtr),HL
  LD A,(HL)
  AND $1F
  JR Z,NextRandom
  RET

; HitCount and HitCellCount = 0, HitList cleared
;
; Witness: L1 100195 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ClearHits:
  XOR A
  LD (HitCount),A
  LD (HitCellCount),A
  LD HL,HitList+$0001
  LD BC,$000F
  JP ClearBlock

; The drawers' colour override off
;
; Witness: L1 69052 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ClearColourOverride:
  XOR A
  LD (CellMark+$000F),A
  RET

; Print the text HL double height on the text row, column C
;
; Witness: L1 1256 (c1, deaths-l7, ending, hiscore, hiscore-typed, pause,
; l1-l8).
PrintRow22:
  LD B,$16

; Print the text HL double height at row B column C
;
; Witness: L1 41361 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
PrintText:
  XOR A
  JR PrintTextA

; Print the text HL at row B column C
;
; Witness: L1 21566 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
PrintTextNormal:
  LD A,$01

; PrintTextA
;
; Used by the routine at PrintText.
PrintTextA:
  LD (TextHeight),A       ; A into TextHeight
PrintChar:
  LD A,(HL)               ; the next character
  AND $7F
  PUSH HL
  SUB $20
  JR NZ,l_C093
  LD A,$3B
l_C093:
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,MissileLaunch+$0001
  ADD HL,DE
  LD A,B
  AND $F8
  ADD A,$40
  LD D,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD E,A
  PUSH BC
  LD A,(TextHeight)
  AND A
  JR Z,l_C0BC
  LD B,$08
l_C0B4:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ l_C0B4
  JR l_C0D0
l_C0BC:
  LD A,D
  EX AF,AF'
  CALL PrintHalf
  EX AF,AF'
  LD D,A
  LD A,E
  ADD A,$20
  LD E,A
  JR NC,l_C0CD
  LD A,D
  ADD A,$08
  LD D,A
l_C0CD:
  CALL PrintHalf
l_C0D0:
  POP BC
  INC C
  POP HL
  BIT 7,(HL)
  INC HL
  RET NZ
  JR PrintChar

; Pixel lines of a character, each doubled
;
; Witness: L1 631829 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
PrintHalf:
  LD B,$04
l_C0DB:
  LD A,(HL)
  LD (DE),A
  INC D
  LD (DE),A
  INC D
  INC HL
  DJNZ l_C0DB
  RET

; A = the SolidMap cell at row B column C
;
; Witness: L1 267495 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
GetCell:
  LD A,B
  RRCA
  RRCA
  RRCA
  AND $03
  ADD A,$7E
  LD D,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD E,A
  LD A,(DE)
  CP $FA
  RET

; Run the boss explosion twice a pass
;
; Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
BossBlastStep:
  CALL BossBlastOnce

; One step of the boss explosion: random explosions over the boss, then the
; sweep
;
; Witness: L1 66644 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
BossBlastOnce:
  LD A,(BossBlast)
  AND A
  RET Z
  LD A,(BossBlastCount)
  AND A
  JR Z,l_C164
  DEC A
  LD (BossBlastCount),A
  CP $32
  JR NZ,l_C115
  LD HL,ClearCells
  LD (l_C134+$0004),HL
l_C115:
  LD A,$80
l_C117:
  EX AF,AF'
l_C118:
  CALL NextRandom
  CP $1E
  JR NC,l_C118
  LD C,A
l_C120:
  CALL NextRandom
  CP $12
  JR NC,l_C120
  LD B,A
  CALL GetCell
  CP $80
  JR NC,l_C134
  EX AF,AF'
  DEC A
  JR NZ,l_C117
  RET
l_C134:
  LD HL,$0303
  CALL ClearCells
  LD A,(FrameCounter)
  AND $01
  ADD A,$09
  LD H,A
  LD L,$81
  CALL PlaySound
  PUSH BC
  CALL FreeExplosion
  POP BC
  LD A,(FrameCounter)
  AND $03
  INC A
  CP $03
  JR NZ,l_C158
  LD A,$02
l_C158:
  RLCA
  RLCA
  RLCA
  RLCA
  OR $08
  LD (HL),A
  INC L
  LD (HL),C
  INC L
  LD (HL),B
  RET
l_C164:
  LD BC,(BossBlastPos)
  CALL GetCell
  CP $80
  JR NC,l_C178
  LD HL,$0040
  ADD HL,DE
  LD A,(HL)
  CP $80
  JR C,l_C17E
l_C178:
  LD (BossBlastPos),BC
  JR l_C134
l_C17E:
  INC C
  LD A,C
  CP $1F
  JR NZ,l_C196
  LD C,$00
  INC B
  LD A,B
  CP $12
  JR NZ,l_C196
  XOR A
  LD (BossBlast),A
  LD A,$3F
  LD (LevelEndTimer),A
  RET
l_C196:
  LD (BossBlastPos),BC
  JR l_C164

; Start the boss explosion (called by the levels' boss code)
;
; Sets ScrollHalted, BossBlast and WavesHalted; puts a RET into ShipDies + 3
; (immortal) and ShieldControls (the controls off); RandomPtr and BossBlastPos
; = 0; the explosions cleared; the solid cells marked. Run only in the boss
; recording, where a POKE frees the slot the level code waits for (no boss was
; killed by hits).
;
; Witness: L1 1 (boss).
BossDestroyed:
  LD A,$01
  LD (WavesHalted),A
  LD (BossBlast),A
  LD (ScrollHalted),A
  LD A,$80
  LD (BossBlastCount),A
  LD HL,l_C1DF
  LD (l_C134+$0004),HL
  LD A,$C9
  LD (ShipDies+$0003),A
  LD (ShieldControls),A
  LD HL,$0000
  LD (RandomPtr),HL
  LD (BossBlastPos),HL
  LD HL,Explosions
  LD BC,$003C
  CALL ClearBlock
  LD HL,SolidMap
  LD BC,$0280
  LD E,$FF
l_C1D4:
  LD A,(HL)
  AND A
  JR Z,l_C1D9
  LD (HL),E
l_C1D9:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_C1D4

; l_C1DF
l_C1DF:
  RET

; The slot was hit: a sound while it has hits left, else EnemyDies
;
; Witness: L1 201705 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
EnemyHit:
  BIT 7,(IY+$08)
  RET Z
  RES 7,(IY+$08)
  LD A,(IY+$00)
  AND $3F
  JR Z,l_C1FC
  PUSH HL
  LD HL,$0481
  CALL PlaySound
  POP HL
  LD A,$01
  AND A
  RET
l_C1FC:
  PUSH DE
  PUSH HL
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  POP HL
  POP DE
  SCF
  RET

; Clear D rows of E cells of SolidMap from BC
;
; Witness: L1 4341 (boss, l x5).
ClearCells:
  PUSH DE
  PUSH BC
  CALL GetCell
  EX DE,HL
l_C211:
  LD B,E
  LD C,L
l_C213:
  LD (HL),$00
  INC L
  DJNZ l_C213
  DEC D
  JR NZ,l_C21E
  POP BC
  POP DE
  RET
l_C21E:
  LD L,C
  LD BC,$0020
  ADD HL,BC
  JR l_C211

; Start a wave from a record at HL, for the levels' code
;
; Witness: L1 1030 (boss, deaths-l7, ending, force, restart, l1, l3-l5, l7,
; l8).
StartWaveAt:
  EX AF,AF'
  PUSH AF
  PUSH DE
  PUSH BC
  LD A,$C9
  LD (StartWaveDone),A
  LD A,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  CALL StartWave
  XOR A
  LD (StartWaveDone),A
  POP BC
  POP DE
  POP AF
  EX AF,AF'
  RET

; Add D to the score digit E, carrying
;
; Witness: L1 1635 (boss, c1, continue, deaths-l7, ending, force, gameover,
; hiscore, hiscore-typed, restart, l1-l8).
AddScore:
  LD A,E
  AND A
  RET Z
  LD (ScoreChanged),A
  LD HL,ScoreText
  LD A,E
  XOR $07
  DEC A
  LD E,A
  LD A,D
  LD D,$00
  ADD HL,DE
l_C251:
  ADD A,(HL)
  LD (HL),A
  CP $3A
  RET C
  SUB $0A
  LD (HL),A
  DEC HL
  LD A,$01
  JR l_C251

; The level's end: at each step of LevelEndTimer the next part, then the next
; level
;
; Acts when (LevelEndTimer - 1) AND $1F = 0. LevelDigit '8': '9', the waves on,
; ShipDies+3 = RET (immortal), play goes on; '9': '0', then the normal end, so
; LoadLevel loads level 1 (the wrap).
;
; Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
LevelEnd:
  LD A,(LevelEndTimer)
  AND A
  RET Z
  LD HL,ShieldControls
  LD (HL),$C9
  DEC A
  LD (LevelEndTimer),A
  AND $1F
  RET NZ
  LD A,(LevelDigit)
  CP $38
  JR NZ,l_C287
  INC A
  LD (LevelDigit),A
  XOR A
  LD (WavesHalted),A
  LD (LevelEndTimer),A
  LD A,$C9
  LD (ShipDies+$0003),A
  RET
l_C287:
  CP $39
  JR NZ,l_C290
  LD A,$30
  LD (LevelDigit),A
l_C290:
  CALL ScrollRows
  CALL StarsOff
  LD HL,$1583
  CALL PlaySound
  XOR A
  LD (LevelEndTimer),A
  CALL Wait256
  CALL LoadLevel
  POP DE
  CALL RestartPoint
  LD A,(ForceLevel)
  AND A
  JP Z,StartLife
  CALL ForceRecordOf
  LD A,$01
  LD (DE),A
  LD (ForceAttached),A
  INC E
  LD A,$0D
  LD (DE),A
  INC E
  LD A,$09
  LD (DE),A
  JP StartLife

; Clear the text row
;
; Witness: L1 90 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; ending, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ClearTextRow:
  LD A,$20
  LD BC,$1600
l_C2CA:
  PUSH AF
  LD HL,BlankChar
  CALL PrintText
  POP AF
  DEC A
  JR NZ,l_C2CA
  RET

; At a checkpoint column, set the restart column and wave
;
; Witness: L1 33313 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
CheckRestart:
  LD HL,LevelChecks+$0002
  LD DE,LevelWaves+$0004
  LD A,(MapColumn)
  CP (HL)
  JR Z,l_C2ED
  DEC L
  DEC E
  DEC E
  CP (HL)
  JR Z,l_C2ED
  DEC L
  DEC E
  DEC E
  CP (HL)
  RET NZ
l_C2ED:
  SUB $08
  LD (LevelRestartColumn),A
  LD HL,LevelRestartWave
  EX DE,HL
  LDI
  LDI
  RET

; An enemy fires at the ship while Shooters is below ShooterLimit
;
; Witness: L1 43995 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1, l3-l7).
EnemyFire:
  LD A,(ShooterLimit)
  LD L,A
  LD A,(Shooters)
  CP L
  RET Z
  INC A
  LD (Shooters),A
  PUSH BC
  PUSH DE
  LD A,(DrawTag)
  DEC A
  AND $7F
  LD E,A
  ADD A,A
  ADD A,E
  LD D,$00
  LD E,A
  LD HL,EnemyShots
  ADD HL,DE
  INC L
  INC L
  INC B
  INC C
  LD (HL),B
  DEC L
  LD (HL),C
  DEC L
  LD E,$10
  LD A,(ShipRow)
  CP B
  JR Z,l_C332
  JR C,l_C330
  SET 1,E
  JR l_C332
l_C330:
  SET 0,E
l_C332:
  LD A,(ShipColumn)
  CP C
  JR Z,l_C340
  JR C,l_C33E
  SET 3,E
  JR l_C340
l_C33E:
  SET 2,E
l_C340:
  LD (HL),E
  SET 7,(IY+$00)
  POP DE
  POP BC
  RET

; Move the enemy shots; one that reaches the ship kills it
;
; Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
MoveEnemyShots:
  LD HL,EnemyShots
  XOR A
l_C34C:
  PUSH AF
  LD A,(HL)
  AND A
  JR NZ,l_C35B
l_C351:
  INC L
l_C352:
  INC L
  INC L
  POP AF
  INC A
  CP $1C
  JR NZ,l_C34C
  RET
l_C35B:
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  CALL MoveByBits
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  EX AF,AF'
  LD A,$80
  LD (DrawTag),A
  LD A,B
  CP $14
  JR NC,l_C3AF
  LD A,C
  CP $1F
  JR NC,l_C3AF
  CALL GetCell
  AND A
  JR Z,l_C391
  CP $06
  JR C,l_C3CD
  CP $FA
  JR NC,l_C3AF
  CP $26
  JR C,l_C3AF
  PUSH HL
  CALL SlotFlags
  POP HL
  JR Z,l_C3AF
l_C391:
  EX AF,AF'
  CP $01
  JR NZ,l_C3A2
  LD A,(FrameCounter)
  AND $01
  LD A,$01
  JR Z,l_C3A2
  DEC L
  JR l_C3A5
l_C3A2:
  LD (HL),B
  DEC L
  LD (HL),C
l_C3A5:
  PUSH HL
  CALL LevelObject
  CALL DrawSprite
  POP HL
  JR l_C352
l_C3AF:
  DEC L
  DEC L
  LD A,(HL)
  LD (HL),$00
  AND $F0
  CP $10
  JR NZ,l_C351
  POP AF
  PUSH AF
  PUSH HL
  INC A
  CALL SlotFlags
  RES 7,(HL)
  LD A,(Shooters)
  DEC A
  LD (Shooters),A
  POP HL
  JR l_C351
l_C3CD:
  POP AF
  JP ShipDies

; Step BC by the direction bits of A: bit 0 up, 1 down, 2 left, 3 right
;
; Witness: L1 306115 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
MoveByBits:
  BIT 0,A
  JR Z,l_C3D6
  DEC B
l_C3D6:
  BIT 1,A
  JR Z,l_C3DB
  INC B
l_C3DB:
  BIT 2,A
  JR Z,l_C3E0
  DEC C
l_C3E0:
  BIT 3,A
  RET Z
  INC C
  RET

; Patch the drawers for the soft cells
;
; Witness: L1 3284 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, gameover, hiscore, hiscore-typed, restart, l1-l8).
SoftCellsOn:
  LD A,$40
  LD (l_8EB7+$0008),A
  LD A,$D8
  JR SoftCellsSet

; Restore them
;
; Witness: L1 12266 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, gameover, hiscore, hiscore-typed, restart, l1-l8).
SoftCellsOff:
  LD A,$60
  LD (l_8EB7+$0008),A
  LD A,$D0

; SoftCellsSet
;
; Used by the routine at SoftCellsOn.
SoftCellsSet:
  LD (CellFreeEmpty+$0005),A ; write A into the drawer
  RET

; ClearCells through the attribute shadow
;
; Witness: L1 2220 (boss, l1, l2, l4).
ClearCellsTag:
  LD (l_C213+$0001),A
  LD A,$78
  LD (GetCell+$0007),A
  CALL ClearCells
  XOR A
  LD (l_C213+$0001),A
  LD A,$7E
  LD (GetCell+$0007),A
  RET

; Step and draw the explosions
;
; Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
DrawExplosions:
  LD B,$14
  LD HL,Explosions
l_C413:
  LD A,(HL)
  AND A
  JR NZ,l_C41D
l_C417:
  INC HL
  INC HL
  INC HL
l_C41A:
  DJNZ l_C413
  RET
l_C41D:
  DEC (HL)
  LD A,(HL)
  AND $0F
  CP $0F
  JR NZ,l_C429
  LD (HL),$00
  JR l_C417
l_C429:
  LD C,A
  LD A,(HL)
  AND $F0
  RRCA
  SUB $08
  LD DE,ExplosionFrames
  ADD A,E
  ADD A,C
  LD E,A
  LD A,(DE)
  AND A
  JR Z,l_C417
  PUSH BC
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  PUSH HL
  CALL GameObject
  CALL DrawSprite
  POP HL
  POP BC
  INC HL
  JR l_C41A

; Paint and print the HUD: BEAM, the meter, HI SCORE, the lives and the score
;
; Witness: L1 96 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; gameover, hiscore, hiscore-typed, pause, restart, l2-l8).
DrawHud:
  LD HL,$5A80
  LD BC,$0020
  LD A,$45
  CALL FillBlock
  LD BC,$0008
  LD A,$44
  CALL FillBlock
  LD HL,$5AE0
  LD BC,$0020
  LD A,$43
  CALL FillBlock
  LD HL,BeamLabel
  LD BC,$1405
  CALL PrintTextNormal
  LD HL,BeamHudText
  CALL PrintTextNormal
  LD HL,Font+$0006
  CALL PrintTextNormal
  LD HL,HiScoreLabel
  LD BC,$1708
  CALL PrintTextNormal
  LD HL,HiScoreTable+$0009
  CALL PrintTextNormal
  LD A,(Lives)
  LD BC,$151E
  CALL DrawLives
  CALL PrintScore
  RET

; "GAME  PAUSED"
PausedText:
  INCBIN "res/texts/paused.bin",$0000,12

; eight zeros before the level space (no recording reads them)
PausedPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
