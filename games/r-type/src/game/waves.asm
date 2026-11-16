; --------------------------------------------------------------------------------------------------------------------
; waves.asm: The attack waves: the wave script, the enemy slots and their movers
; --------------------------------------------------------------------------------------------------------------------

; The enemy slot's hits left
;
; Witness: L1 65244 (boss, c1, continue, deaths-l7, ending, force, gameover,
; hiscore, hiscore-typed, restart, l1-l8).
SlotFlags:
  AND $7F
  DEC A
  LD L,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,L
  LD H,$85
  LD L,A
  INC L
  LD A,(HL)
  AND $3F
  CP $3F
  RET

; Start the waves the script has reached
;
; Unless WavesHalted: while the entry at WavePtr matches the scroll's position,
; takes its kind (a command when $63: CommandWave) and script and starts it
; (StartWave).
;
; Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
RunWaves:
  LD A,(WavesHalted)
  AND A
  RET NZ

; RunWavesNext
;
; Used by the routine at StartWaveDone.
RunWavesNext:
  LD HL,(WavePtr)         ; the next entry
  LD A,$FF
  CP (HL)
  RET Z
  LD A,(MapColumn)
  CP (HL)
  RET NZ
  INC HL
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $03
  LD B,A
  LD A,(MetaColumn)
  CP B
  RET NZ
  LD A,(HL)
  AND $07
  LD B,A
  LD A,(ScrollStep)
  CP B
  RET NZ
  INC HL
  LD A,(HL)
  CP $63
  JP Z,CommandWave
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (WavePtr),HL

; Put enemy kind A with its movement script into a free slot
;
; The kind's record from LevelKinds; WaveOverride picks the slot; no free slot:
; the wave is dropped.
;
; Witness: L1 3151 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
StartWave:
  LD H,$00
  LD L,A
  DEC L
  ADD HL,HL
  LD BC,(LevelKinds)
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  PUSH HL
  LD HL,EnemySlots
  LD B,$18
  LD A,(WaveOverride)
  AND A
  JR Z,l_9037
  CALL SlotFlags
  XOR A
  LD (WaveOverride),A
  JP l_9044
l_9037:
  LD A,(HL)
  AND A
  JR Z,l_9044
  LD A,L
  ADD A,$09
  LD L,A
  DJNZ l_9037
  POP HL
  JR StartWaveDone
l_9044:
  PUSH HL
  POP IX
  POP HL
  LD (IX+$06),L
  LD (IX+$07),H
  LD (IX+$03),E
  LD (IX+$04),D
  EX DE,HL
  LD A,(DE)
  LD (IX+$05),A
  INC DE
  LD A,(DE)
  LD (IX+$00),A
  INC DE
  INC DE
  EX DE,HL
  LD A,(HL)
  INC HL
  CP (HL)
  JR NZ,l_9083
  CP $80
  JR NC,l_9083
  LD H,$00
  LD L,A
  DEC L
  ADD HL,HL
  LD BC,(LevelKinds)
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (IX+$06),L
  LD (IX+$07),H
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  INC HL
l_9083:
  LD (IX+$01),A
  LD A,(HL)
  LD (IX+$02),A
  LD A,$01
  LD (IX+$08),A

; StartWaveDone
;
; Used by the routines at StartWave and CommandWave.
StartWaveDone:
  NOP                     ; back to RunWavesNext
  JP RunWavesNext

; A wave command: 1 halt the scroll (a boss), 2 resume, 3 next slot, 4 shooter
; limit, 5 the level's end, 6 a sound
;
; Witness: L1 271 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
CommandWave:
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  LD (WavePtr),HL
  DEC HL
  CP $01
  JR Z,l_90B5
  CP $02
  JR Z,l_90D4
  CP $03
  JR Z,l_90D9
  CP $04
  JR Z,l_90DF
  CP $05
  JR Z,l_90E5
  CP $06
  JR Z,l_90EF
  JR StartWaveDone
l_90B5:
  LD A,$01
  LD (ScrollHalted),A
  LD A,$37
  LD (CellFreeEmpty),A
  LD A,$C9
  LD (CellFreeEmpty+$0001),A
  LD HL,PlayAttrs
  LD DE,$5800
  LD BC,$0280
  LDIR
  CALL ClearSides
  JR StartWaveDone
l_90D4:
  CALL ResumeWaves
  JR StartWaveDone
l_90D9:
  LD A,(HL)
  LD (WaveOverride),A
  JR StartWaveDone
l_90DF:
  LD A,(HL)
  LD (ShooterLimit),A
  JR StartWaveDone
l_90E5:
  LD A,$41
  LD (LevelEndTimer),A
  LD (WavesHalted),A
  JR StartWaveDone
l_90EF:
  LD H,(HL)
  LD L,$83
  CALL PlaySound
  JR StartWaveDone

; Clear ScrollHalted and WavesHalted and restore CellFreeEmpty's code
;
; Witness: L1 64 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; ending, gameover, hiscore, hiscore-typed, restart, l1-l8).
ResumeWaves:
  XOR A
  LD (ScrollHalted),A
  LD (WavesHalted),A
  LD A,$1C
  LD (CellFreeEmpty),A
  LD A,$1A
  LD (CellFreeEmpty+$0001),A
  RET

; Move every live enemy slot by its kind's movers
;
; For each slot: DrawTag = $80 + slot; the script's step; then the kind's first
; mover from LevelMoves and its second from LevelMoves2: the levels' own code,
; which comes back to MoveStore, MoveDraw, MoveDrawA, MoveNext or MoveDone.
;
; Witness: L1 33321 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
MoveEnemies:
  LD A,(WavesHalted)
  AND A
  RET NZ
  LD IY,EnemySlots
  LD B,$01

; MoveEnemiesSlot
;
; Used by the routine at MoveEnemiesNext.
MoveEnemiesSlot:
  BIT 7,(IY+$08)          ; the next slot
  JR NZ,l_912D
  LD A,(IY+$00)
  AND $3F
  JR NZ,l_912D

; MoveEnemiesNext
;
; Used by the routine at MoveSlotEnd.
MoveEnemiesNext:
  LD DE,$0009             ; advance IY
  ADD IY,DE
  INC B
  LD A,B
  CP $1D
  JR NZ,MoveEnemiesSlot
  RET
; This entry point is used by the routine at MoveEnemiesSlot.
l_912D:
  LD A,B
  OR $80
  LD (DrawTag),A
  PUSH BC
  LD E,(IY+$01)
  LD D,(IY+$02)
  LD C,(IY+$03)
  LD B,(IY+$04)
  LD A,(DE)
  EX AF,AF'
  INC DE
  LD A,(DE)
  RRCA
  RRCA
  CALL MoveByBits
  BIT 7,(IY+$00)
  JR NZ,l_9159
  LD A,(DrawTag)
  BIT 6,(IY+$00)
  CALL NZ,EnemyFire
l_9159:
  LD A,(IY+$05)
  AND $0F
  LD HL,(LevelMoves)
  CALL TableEntry
  CALL EnemyHit
  JP (HL)

; MoveStore
MoveStore:
  LD (IY+$03),C           ; a mover's exit: store the new position, draw
  LD (IY+$04),B

; MoveDraw
MoveDraw:
  LD A,(DE)               ; draw with the script's sprite

; MoveDrawA
MoveDrawA:
  PUSH DE                 ; draw object A (its low 2 bits pick the drawer)
  PUSH AF
  EX AF,AF'
  CALL LevelObject
  POP AF
  AND $03
  JR NZ,l_917F
  CALL DrawSprite
  JR l_9194
l_917F:
  CP $01
  JR NZ,l_9188
  CALL DrawSpriteMirrored
  JR l_9194
l_9188:
  CP $02
  JR NZ,l_9191
  CALL DrawSpriteFlipped
  JR l_9194
l_9191:
  CALL DrawSpriteBoth
l_9194:
  POP DE

; MoveNext
MoveNext:
  LD A,(IY+$05)           ; the second mover
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD HL,(LevelMoves2)
  CALL TableEntry
  JP (HL)

; MoveScript
MoveScript:
  LD A,(DE)               ; step the slot's script
  CP $80
  JR NC,l_91B3
  INC DE
  LD (IY+$01),E
  LD (IY+$02),D

; MoveDone
MoveDone:
  JR MoveSlotEnd          ; the slot done
; This entry point is used by the routine at MoveScript.
l_91B3:
  LD E,(IY+$06)
  LD D,(IY+$07)
  LD A,(IY+$08)
  ADD A,A
  ADD A,$03
  LD H,$00
  LD L,A
  ADD HL,DE
  LD B,(HL)
  INC HL
  LD A,(HL)
  AND A
  JR Z,MoveFree
  CP $FF
  JR NZ,l_91D3
  LD (IY+$08),$00
  JR l_91B3
l_91D3:
  LD (IY+$01),B
  LD (IY+$02),A
  INC (IY+$08)

; MoveSlotEnd
;
; Used by the routine at MoveDone.
MoveSlotEnd:
  POP BC                  ; back to the loop
  JP MoveEnemiesNext
; This entry point is used by the routine at MoveDone.
MoveFree:
  LD (IY+$00),$00         ; free the slot
  JR MoveSlotEnd

; HL = the word at HL + 2 x A
;
; Witness: L1 388175 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
TableEntry:
  ADD A,A
  ADD A,L
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET

; The ship is hit: a life off, the explosion, DeathTimer 32
;
; Three ways in: JP NC at $956D (scenery ahead of the ship, GetCell), JP NZ at
; $9574 (an enemy's cell), JP at $C3CE (an enemy shot, MoveEnemyShots). Without
; the immortality POKE: gameover, continue and hiscore (level 1) (and c1) take
; $9574 2-6 times and $956D 0-1 times, $C3CE never; deaths-l7 (level 7, the
; stage 1 POKE undone, 8390 frames) takes $956D 4 times, $9574 once and runs
; $C3CE 3 times: 8 lives, 8 runs of ShipDies.
;
; $91F5 is a NOP in play; a RET there makes the ship immortal (BossDestroyed
; and the end of level 8 put it there, ClearPlayState $8707 puts the NOP back
; at every level load and life; the immortality POKE of the stage 1 recordings
; writes $C9 at $91F2).
;
; Witness: L1 7575 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShipDies:
  CALL ClearHits
  NOP
  LD HL,PlayAttrs+$01A0
  INC H
  LD B,$14
  LD C,$01
  DEC (HL)
  LD HL,$0983
  CALL PlaySound
  LD HL,Explosions
  LD BC,(ShipColumn)
  LD (HL),$28
  INC L
  LD (HL),C
  INC L
  DEC B
  LD (HL),B
  LD A,$20
  LD (DeathTimer),A

; Clear the ship's, the shots' and the enemy shots' state
;
; Witness: L1 85 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; gameover, hiscore, hiscore-typed, restart).
ClearShipStuff:
  LD HL,ShipColumn
  LD BC,$0055
  CALL ClearBlock
  LD HL,EnemyShots
  LD BC,$006D
  CALL ClearBlock
  LD HL,ShipShots
  LD BC,$010D
  CALL ClearBlock
  RET

; Print LifeChar A times from column C leftwards, then a blank
;
; Witness: L1 335 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, gameover, hiscore, hiscore-typed, pause, restart, l2-l8).
DrawLives:
  AND A
  JR Z,l_9244
  PUSH AF
  LD HL,LifeChar
  CALL PrintTextNormal
  DEC C
  DEC C
  POP AF
  DEC A
  JR NZ,DrawLives
l_9244:
  LD HL,BlankChar
  CALL PrintTextNormal
  RET

; Count the death down: the explosion, PILOT STAND BY or MISSION OVER,
; CONTINUE, the next life
;
; Witness: L1 33360 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
LoseLife:
  LD A,(DeathTimer)
  AND A
  RET Z
  DEC A
  LD (DeathTimer),A
  JR Z,LoseLifeNow
  CP $18
  RET NZ
  LD HL,$0A83
  CALL PlaySound
  LD HL,Explosions
  LD (HL),$48
  INC L
  DEC (HL)
  INC L
  DEC (HL)
  RET
LoseLifeNow:
  CALL Silence            ; the timer reached 0
  CALL StarsOff
  CALL DrawHud
  CALL ClearTextRow
  CALL ClearShipStuff
  LD HL,PlayAttrs+$01A0
  INC H
  LD A,(HL)
  AND A
  JR NZ,l_92BE
  PUSH HL
  CALL MissionOver
  LD B,$60
  CALL WaitFrames
  POP HL
  CALL CheckHiScore
  POP DE
  LD A,(CreditDigit)
  CP $31
  JR Z,l_92A4
  DEC A
  LD (CreditDigit),A
  CALL Continue
  JR Z,l_92A4
  CALL NewGameState
  JP StartLife
l_92A4:
  LD HL,CreditDigit
  LD (HL),$35
  XOR A
  LD (FirstPlay),A
  LD HL,LevelDigit
  LD A,(HL)
  CP $31
  JP Z,NewGame
  LD (HL),$30
  CALL LoadLevel
  JP NewGame
l_92BE:
  CALL PilotStandBy
  POP DE
  JP StartLife

; Print `PILOT STAND BY $` and wait
;
; Witness: L1 38 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; gameover, hiscore, hiscore-typed, restart).
PilotStandBy:
  LD HL,PilotStandByText
  LD BC,$1608
  JR PrintAndWait

; Sounds, `MISSION OVER $` and a wait
;
; Witness: L1 4 (continue, gameover, hiscore, hiscore-typed).
MissionOver:
  LD HL,$1B81
  CALL PlaySound
  LD HL,$1A81
  CALL PlaySound
  LD BC,$1609
  LD HL,MissionOverText

; PrintAndWait
;
; Used by the routine at PilotStandBy.
PrintAndWait:
  CALL PrintText          ; print HL double height at BC, wait
  LD B,$50
  CALL WaitFrames
  RET

; Enter the score into the table when high enough, then show the table
;
; Witness: L1 4 (continue, gameover, hiscore, hiscore-typed).
CheckHiScore:
  LD DE,ScoreText
  CALL InsertHiScore
  RET Z
  CALL ShowHiScores
  CALL Wait256
  XOR A
  LD (TaskTable+$0016),A
  RET

; Find the score's place, shift the lower entries, take the name typed with up,
; down and fire
;
; Witness: L1 4 (continue, gameover, hiscore, hiscore-typed).
InsertHiScore:
  LD HL,HiScoreTable+$000A
  LD C,$09
l_92FF:
  PUSH DE
  PUSH HL
  LD B,$06
l_9303:
  EX DE,HL
  LD A,(DE)
  SUB (HL)
  EX DE,HL
  JR C,l_9319
  JR NZ,l_930F
  INC HL
  INC DE
  DJNZ l_9303
l_930F:
  LD DE,$0011
  POP HL
  ADD HL,DE
  POP DE
  DEC C
  JR NZ,l_92FF
  RET
l_9319:
  LD B,$00
  LD H,B
  LD L,C
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,BC
  LD B,H
  LD C,L
  LD HL,HiScoreTable+$0098
  LD DE,HiScoreSpare+$0010
  LDDR
  INC HL
  LD A,$41
  LD (HL),A
  LD (NameLetter),A
  PUSH HL
  LD BC,$000F
  LD A,$20
  CALL FillBlock
  POP BC
  POP DE
  POP HL
  PUSH BC
  LD BC,$0006
  LDIR
  XOR A
  LD (NamePos),A
  CALL ShowHiScores
  LD HL,EnterNameText
  LD C,$04
  CALL PrintRow22
l_9354:
  POP HL
  LD A,(NameLetter)
  LD (HL),A
  PUSH HL
  CALL PrintHiScores
  CALL ReadControls
  BIT 0,A
  JR NZ,l_936E
  BIT 1,A
  JR NZ,l_937A
  BIT 4,A
  JR NZ,l_9394
  JR l_9354
l_936E:
  LD A,(NameLetter)
  DEC A
  CP $40
  JR NZ,l_9384
  LD A,$5D
  JR l_9384
l_937A:
  LD A,(NameLetter)
  INC A
  CP $5E
  JR NZ,l_9384
  LD A,$41
l_9384:
  LD (NameLetter),A
l_9387:
  LD HL,$0C81
  CALL PlaySound
  LD B,$0C
  CALL WaitFrames
  JR l_9354
l_9394:
  LD A,(NameLetter)
  CP $5C
  JR Z,l_93AF
  CP $5D
  JR Z,l_93C0
  LD A,(NamePos)
  CP $08
  JR Z,l_93CD
  INC A
  LD (NamePos),A
  POP HL
  INC HL
  PUSH HL
  JR l_9387
l_93AF:
  LD A,(NamePos)
  AND A
  JR Z,l_9387
  DEC A
  LD (NamePos),A
  POP HL
  LD (HL),$20
  DEC HL
  PUSH HL
  JR l_9387
l_93C0:
  POP HL
  LD (HL),$20
l_93C3:
  LD HL,$1621
  CALL PlaySound
  LD A,$01
  AND A
  RET
l_93CD:
  POP HL
  JR l_93C3
