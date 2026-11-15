; --------------------------------------------------------------------------------------------------------------------
; main.asm: The entry, the main loop and the start of a life
; --------------------------------------------------------------------------------------------------------------------

; The game's entry from the loader's tail: build the tables, show the title
; picture, load level 1, run the title
;
; Interrupts off; SP = $FFFE; builds BitReverse; copies EntryCopySource to
; EntryCopy; IM 2 through Im2Table; ProbeKempston; ShowLoadingScreen; LoadLevel
; loads level 1. Then NewGame, StartLife, MainLoop.
;
; Witness: L1 1 (c1).
Entry:
  DI
  LD HL,$FFFE
  POP DE
  LD SP,HL
  LD HL,BitReverse
  LD B,$00
l_8608:
  LD C,$08
  LD E,$00
  LD A,B
l_860D:
  SRL A
  RL E
  DEC C
  JR NZ,l_860D
  LD (HL),E
  INC HL
  INC B
  JR NZ,l_8608
  LD HL,EntryCopySource
  LD DE,EntryCopy
  LD BC,$019E
  LDIR
  LD A,$84
  LD I,A
  IM 2
  EI
  CALL ProbeKempston
  CALL ShowLoadingScreen
  CALL LoadLevel

; NewGame
;
; Used by the routine at LoseLife.
NewGame:
  CALL RestartPoint       ; a new game: the restart point, the score and lives
                          ; reset, the title loop
  CALL NewGameState
  CALL TitleLoop

; StartLife
;
; Used by the routines at LoseLife and LevelEnd.
StartLife:
  CALL TitleStarsOn       ; a life starts: stars on, the play state cleared,
                          ; the level drawn from its restart column, the ship
                          ; placed
  CALL ClearPlayState
  CALL StartPlayField
  CALL StartPlay

; MainLoop
;
; Used by the routine at MainLoopPatch.
MainLoop:
  XOR A                   ; one pass of the game (the calls in order below),
                          ; then wait for the third interrupt
  LD (IntTicks),A
  CALL LoseLife
  CALL CheckPause
  CALL Scroll

; MainLoopPatch
MainLoopPatch:
  NOP                     ; three NOPs
  NOP
  NOP
  CALL MoveEnemies
  CALL RunWaves
  CALL ReadControls
  CALL MoveShip
  CALL ShipFlyIn
  CALL MoveForce
  CALL DrawExplosions
  CALL MoveBeam
  CALL MoveMissileSet
  CALL MoveForceShots
  CALL MoveMissiles
  CALL MoveShipShots
  CALL MoveEnemyShots
  CALL BossBlastStep
  CALL CheckExtraLife
  CALL LevelEnd
  CALL CheckRestart
MainWait:
  LD A,(IntTicks)         ; wait until IntTicks reaches 3
  CP $03
  JR C,MainWait
  JP MainLoop

; Copy the level's first restart column and wave entry into the live ones
;
; Witness: L1 10 (c1, gameover, hiscore, l2-l8).
RestartPoint:
  LD HL,(LevelWaves)
  LD (LevelRestartWave),HL
  LD (WavePtr),HL
  LD A,(LevelChecks)
  LD (LevelRestartColumn),A
  LD (MapColumn),A
  RET

; Lives = 5, ExtraLives = 0, the sound silenced, the score set to "000000"
;
; Witness: L1 4 (c1, continue, gameover, hiscore).
NewGameState:
  LD A,$05
  LD HL,PlayAttrs+$01A0
  INC H
  LD (HL),A
  XOR A
  LD (ExtraLives),A
  CALL Silence
  LD HL,ScoreText
  LD BC,$0006
  LD A,$30
  CALL FillBlock
  RET

; Zero the ClearList blocks, set the colours and the control reader
;
; Zeroes every ClearList block; attributes and PlayAttrs $47; border black;
; clears ShieldTimer, the title colour task, the controls patch at
; ShieldControls, Shooters, MissileTimer and the death patch at ShipDies + 3;
; ControlVector from ControlVectors by ControlMethod; ResumeWaves.
;
; Witness: L1 55 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
ClearPlayState:
  LD IX,ClearList
l_86C7:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD C,(IX+$02)
  LD B,(IX+$03)
  CALL ClearBlock
  LD BC,$0004
  ADD IX,BC
  LD A,(IX+$01)
  AND A
  JR NZ,l_86C7
  LD HL,$5800
  LD BC,$0300
  LD A,$47
  CALL FillBlock
  LD HL,PlayAttrs
  LD BC,$0280
  CALL FillBlock
  XOR A
  OUT ($FE),A
  LD (ShieldTimer),A
  LD (TaskTable+$0016),A
  LD (ShieldControls),A
  LD (Shooters),A
  LD (MissileTimer),A
  LD (ShipDies+$0003),A
  LD A,(ControlMethod)
  DEC A
  ADD A,A
  LD H,$00
  LD L,A
  LD DE,ControlVectors
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (ControlVector),HL
  CALL ResumeWaves
  RET

; Start the play field at the level's restart column
;
; Clears ScrollHalted and the BEAM meter, takes MapColumn and WavePtr from the
; restart point, DrawFirstScreen, stars on, DrawHud, the black sides.
;
; Witness: L1 38 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, gameover,
; hiscore, hiscore-typed, l2-l8).
StartPlayField:
  XOR A
  LD (ScrollHalted),A
  LD (BeamMeter),A
  LD HL,(LevelRestartWave)
  LD (WavePtr),HL
  LD A,(LevelRestartColumn)
  LD (MapColumn),A
  CALL DrawFirstScreen
  CALL StarsOn
  CALL DrawHud
  CALL ClearSides
  RET
