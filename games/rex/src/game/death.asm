; --------------------------------------------------------------------------------------------------------------------
; death.asm: Rex's death, the life lost, the game over, the restart points, the sparkle
;
; RexDies starts a death (not while Immune $A071): Dying $A055 = 1, a free smart bomb, the shield gone, the sparkle
; out (Dematerialise $9D47). DeathAnimation runs 50 passes ($A056) of shards flying from Rex (DeathShards $9C05), then
; LifeLost: one life less, Rex back at the last restart point (RestartX $A059, RestartY $A05A, RestartRoom $A05B,
; saved by the restart markers, SaveRestart $9C3B) with a materialise sparkle, and the room built again. No life left:
; the game over panel (GAME OVER, HI-SCORE, HUMANS KILLED) and a new game.
;
; The sparkle ($9D0F-$9F0B) is Rex appearing or vanishing as random dots: SparkleUpdate fills a 3 x 3 cell patch of
; the attribute shadow by random masks, SparkleDraw draws the particles (SparkleMasks $9F0C, SparkleDots $9F14).
; --------------------------------------------------------------------------------------------------------------------

; One pass of Rex's death: the shards, the death picture, the sound; at the end
; LifeLost
;
; The shards follow DeathShards $9C05 (DeathShardPtr $A057 moved by ShardNext
; $9BC8 / ShardBack $9BD1); SpriteRexDeath $816A; the attribute fade
; SaveCellAttrs $CF9B / RestoreCellAttrs $CF6E. After DeathTimer $A056 passes:
; JP LifeLost $9C76.
;
; Witness: L1 758 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room24, p1-room30, rzx-p1- x18).
DeathAnimation:
  LD A,(Lives)
  OR A
  JP NZ,DrawRex
  LD IY,DeathShards+$0006
  LD B,$10
ShardLoop:
  PUSH BC                 ; each shard
  LD A,(IY+$00)
  OR A
  JP Z,DeathTimerStep
  LD B,A
  LD DE,$0048
  CALL Multiply
  LD DE,SpriteRexDeath
  ADD HL,DE
  LD (SpritePicture),HL
  LD A,(IY+$01)
  LD (SpriteX),A
  LD A,(IY+$02)
  CP $A8
  JP NC,DeathTimerStep
  CP $18
  JP C,DeathTimerStep
  LD (SpriteY),A
  LD A,$03
  LD (SpriteWidth),A
  LD A,$18
  LD (SpriteHeight),A
  LD A,$FF
  LD (SpriteMirror),A
  XOR A
  CALL DrawSprite
  LD A,(IY+$01)
  LD (SpriteX),A
  LD A,(IY+$02)
  LD (SpriteY),A
  CALL FlashCells
  LD A,(IY+$00)
  INC A
  LD (IY+$00),A
  CP $09
  JP NZ,ShardNextRecord
  LD (IY+$00),$00
  LD HL,(Temp1)
  LD DE,(Temp2)
  CALL CopyCells3
ShardNextRecord:
  LD DE,$0003             ; the next shard
  ADD IY,DE
  POP BC
  DJNZ ShardLoop
  LD A,(DeathTimer)
  DEC A
  LD (DeathTimer),A
  CP $2F
  CALL Z,ShardNext
  CP $22
  CALL Z,ShardNext
  CP $19
  CALL Z,ShardBack
  CP $17
  CALL Z,ShardBack
  OR A
  JP Z,LifeLost
  RET
DeathTimerStep:
  LD A,(DeathTimer)       ; the death's timer
  CP $10
  JP C,ShardNextRecord
  CALL Random
  CP $96
  JP C,ShardNextRecord
  LD HL,(DeathShardPtr)
  LD A,(RexX)
  SUB (HL)
  LD E,A
  CALL Random2
  LD HL,(DeathShardPtr)
  INC HL
  AND (HL)
  SLA A
  SLA A
  SLA A
  ADD A,E
  AND $F8
  CP $F0
  JP NC,ShardNextRecord
  LD (IY+$01),A
  LD A,(RexY)
  LD HL,(DeathShardPtr)
  SUB (HL)
  LD E,A
  CALL Random2
  LD HL,(DeathShardPtr)
  INC HL
  AND (HL)
  SLA A
  SLA A
  SLA A
  ADD A,E
  AND $F8
  LD (IY+$02),A
  LD (IY+$00),$01
DeathFlash:
  CALL Random             ; a random attribute flash
  AND $03
  OR A
  JP Z,DeathFlash
  LD (SfxExplosion),A
  LD DE,SfxExplosion
  CALL StartSfx
  JP ShardNextRecord

; DeathShardPtr $A057 + 2
;
; Witness: L1 4 (c1, p1-gameover).
ShardNext:
  LD HL,(DeathShardPtr)
  INC HL
  INC HL
  LD (DeathShardPtr),HL
  RET

; DeathShardPtr $A057 - 2: the shards step back
;
; Witness: L1 4 (c1, p1-gameover).
ShardBack:
  LD HL,(DeathShardPtr)
  DEC HL
  DEC HL
  LD (DeathShardPtr),HL
  RET

; Rex is killed (unless Immune $A071 or already dying): Dying, the timer 50,
; the free smart bomb, the shield off, dematerialise
;
; Called by the collisions (EnemyBulletsHitRex $D1B9, ObjectHitsRex $D215), the
; fall (RexFall $D14D) and the HUD sweep's end (HudSweep $A0C4). Resets the
; sweep (ResetSweep $A133).
;
; Witness: L1 42 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room24, p1-room30, rzx-p1- x18).
RexDies:
  LD A,(Immune)
  OR A
  RET NZ
  CALL ResetSweep
  LD A,$01
  LD (Dying),A
  LD A,$32
  LD (DeathTimer),A
  LD HL,DeathShards
  LD (DeathShardPtr),HL
  CALL SmartBombFree
  CALL LosePower
  LD A,$63
  LD (ShieldEnergy),A
  LD A,(Lives)
  OR A
  CALL NZ,Dematerialise
  RET

; The shards' 9 paths: X, Y step pairs, read by DeathAnimation
DeathShards:
  DEFB $10,$03,$20,$07,$40,$0F
  DEFB $00,$00,$00,$01,$00,$00
  DEFB $02,$00,$00,$03,$00,$00
  DEFB $04,$00,$00,$05,$00,$00
  DEFB $06,$00,$00,$07,$00,$00
  DEFB $00,$00,$00,$08,$00,$00
  DEFB $02,$00,$00,$03,$00,$00
  DEFB $04,$00,$00,$05,$00,$00
  DEFB $06,$00,$00,$07,$00,$00

; A restart marker (cell $07) under Rex: save Rex's place, room and facing as
; the restart point, a chime
;
; Only when RexX & 7 = 2 (Rex centred on the marker) and the point differs from
; the saved one. The marker character is animated by AnimateRestart $A5B7.
;
; Witness: L1 1199 (c1, p1-cursor, p1-define, p1-kempston, p1-room24,
; p1-room30, rzx-p1- x26).
SaveRestart:
  INC HL
  LD A,(RexFacing)
  OR A
  JP Z,RestartCompare
  DEC HL
  DEC HL
RestartCompare:
  LD A,(HL)               ; the saved point differs?
  CP $07
  RET NZ
  LD DE,SfxRestart
  LD A,(Channels+$0008)
  CP $FF
  CALL Z,StartSfx
  CALL AnimateRestart
  LD A,(RexX)
  AND $07
  CP $02
  RET NZ
  LD A,(RexX)
  AND $F8
  LD (RestartX),A
  LD A,(RexY)
  AND $F8
  LD (RestartY),A
  LD A,(Room)
  LD (RestartRoom),A
  RET

; The end of a death: one life less; Rex back at the restart point, or the game
; over
;
; Lives $A063 - 1; ShowLives; Rex at RestartX/Y $A059/$A05A in RestartRoom
; $A05B, the shield off, the motion cleared; Materialise $9D1F and JP MainLoop
; $9583 (the room is built again). Lives at -1: GameOver $9CBF.
;
; Witness: L1 36 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room24, p1-room30, rzx-p1- x18).
LifeLost:
  LD A,(Lives)
  DEC A
  LD (Lives),A
  CP $FF
  JP Z,GameOver
  CALL ShowLives
  LD A,(RestartX)
  LD (RexX),A
  LD A,(RestartY)
  LD (RexY),A
  XOR A
  LD (RexFrame),A
  LD (ShieldOn),A
  LD (RexFacing),A
  LD (Jumping),A
  LD (RexSpeed),A
  LD (FallSpeed),A
  LD (Dying),A
  CALL Materialise
  LD A,(RestartRoom)
  LD HL,Room
  CP (HL)
  JP Z,LifeLostRestart
  LD (Room),A
  POP BC
  JP MainLoop
LifeLostRestart:
  CALL ShowShield         ; Rex back at the restart point
  RET
GameOver:
  LD DE,(Score)           ; no life left: a new high score kept, GAME OVER,
                          ; HI-SCORE and HUMANS KILLED $A089, wait for fire,
                          ; NewGame
  LD HL,(HiScore)
  AND A
  SBC HL,DE
  JP NC,GameOverTexts
  LD (HiScore),DE
GameOverTexts:
  LD IX,GameOverText      ; the game over panel's texts
  LD B,$01
  CALL PrintBoxed
  LD IX,HiScoreText
  LD B,$01
  CALL PrintBoxed
  LD IX,HumansKilledText
  LD B,$01
  CALL PrintBoxed
  LD HL,(HumansKilled)
  CALL ToDigits
  LD E,$1B
  LD L,$80
  LD B,$05
  CALL PrintDigits
  LD HL,(HiScore)
  CALL ToDigits
  LD E,$14
  LD L,$60
  LD B,$05
  CALL PrintDigits
  CALL WaitFire
  JP NewGame

; The materialise is over: RexPresent $A05D = 1 (Rex can move and fire),
; SparkleCount $A05E = 18
;
; Witness: L1 2042 (c1, p1-cursor, p1-define, p1-kempston, p1-room24,
; p1-room30, rzx-p1- x20).
RexAppears:
  LD A,(RexPresent)
  OR A
  RET NZ
  LD A,$01
  LD (RexPresent),A
  LD A,$12
  LD (SparkleCount),A
  RET

; Rex appears: RexPresent 0, the sparkle in (SparkleOn $A05F, SparkleMode
; $A060), its dots cleared, the materialise sound $D7AE
;
; Witness: L1 40 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30,
; rzx-p1- x19).
Materialise:
  LD A,$01
  LD (SparkleOn),A
  LD (SparkleMode),A
  XOR A
  LD (Vanishing),A
  LD (RexPresent),A
  LD A,$64
  LD (SparkleTimer),A
; This entry point is used by the routine at Dematerialise.
SparkleClear:
  LD HL,SparkleDots       ; clear the dots, the sound
  LD DE,SparkleDots+$0001
  LD BC,$003B
  LD (HL),$00
  LDIR
  LD DE,SfxMaterialise
  CALL StartSfx
  RET

; Rex vanishes: the shield off, the sparkle out (Vanishing $A062 = 1), the
; sound $D7BA
;
; Witness: L1 40 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30,
; rzx-p1- x18).
Dematerialise:
  LD DE,SfxDematerialise
  CALL StartSfx
  XOR A
  LD (ShieldOn),A
  LD A,$01
  LD (SparkleOn),A
  LD (SparkleMode),A
  LD (Vanishing),A
  LD A,(RexPresent)
  LD L,A
  LD (RexPresent),A
  LD (SparkleCount),A
  LD A,$64
  LD (SparkleTimer),A
  LD A,L
  OR A
  RET NZ
  JP SparkleClear

; One step of the sparkle: random masks over Rex's 3 x 3 cells in the attribute
; shadow; at the end the sparkle stops
;
; Witness: L1 16839 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
SparkleUpdate:
  LD A,(SparkleMode)
  OR A
  RET Z
  LD A,(RexPresent)
  OR A
  RET Z
  LD A,(RexY)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(RexX)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,SparkleBufferOrigin
  ADD HL,DE
  LD C,$00
  LD A,(SparkleCount)
  LD B,A
  CALL FillCells3
  LD DE,$001D
  LD B,$03
SparkleRow:
  PUSH BC                 ; each row of the 3 x 3 patch
  LD B,$03
SparkleCell:
  PUSH BC                 ; each cell: a random mask
  CALL Random
  AND (HL)
  LD (HL),A
  INC HL
  POP BC
  DJNZ SparkleCell
  ADD HL,DE
  POP BC
  DJNZ SparkleRow
  LD A,(Vanishing)
  OR A
  JP NZ,SparkleOut
  LD A,(SparkleCount)
  DEC A
  LD (SparkleCount),A
  OR A
  RET NZ
  JP SparkleEnd

; LD A,100: LD ($A061),A after a JP: no instruction reaches it (leftover)
;
; Known only from the code.
;
; Witness: L1 0 ().
SparkleDeadCode:
  LD A,$64
  LD (SparkleTimer),A

; Vanishing: SparkleCount $A05E + 1; at 18 Rex is gone (RexPresent 0) and the
; sparkle's timer is 30
;
; Witness: L1 658 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30,
; rzx-p1- x18).
SparkleOut:
  LD A,(SparkleCount)
  INC A
  LD (SparkleCount),A
  CP $12
  RET NZ
  XOR A
  LD (RexPresent),A
  JP SparkleTimer30
; This entry point is used by the routine at SparkleUpdate.
SparkleEnd:
  XOR A                   ; the sparkle over
  LD (SparkleMode),A
  LD A,$01
  LD (RexPresent),A
SparkleTimer30:
  LD A,$1E                ; the timer 30
  LD (SparkleTimer),A
  RET

; If SparkleOn $A05F, SparkleDraw: no instruction calls it (leftover)
;
; Known only from the code.
;
; Witness: L1 0 ().
SparkleIfOn:
  LD A,(SparkleOn)
  OR A
  CALL NZ,SparkleDraw
  RET

; Write C into a 3 x 3 patch at HL (32-byte rows)
;
; Witness: L1 1381 (c1, p1-cursor, p1-define, p1-kempston, p1-room24,
; p1-room30, rzx-p1- x21).
FillCells3:
  LD DE,$001E
FillCellsRow:
  LD (HL),C               ; each row
  INC HL
  LD (HL),C
  INC HL
  LD (HL),C
  ADD HL,DE
  DJNZ FillCellsRow
  RET

; Draw the sparkle's particles round Rex (SparkleMasks $9F0C, SparkleDots
; $9F14); at the end of a dematerialise LifeLost
;
; Witness: L1 16839 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
SparkleDraw:
  LD A,(SparkleOn)
  OR A
  RET Z
  LD IY,SparkleDots
  LD B,$14
SparkleDotLoop:
  PUSH BC                 ; each particle
  LD A,(IY+$00)
  OR A
  JP Z,SparkleDir
  LD A,(RexX)
  ADD A,(IY+$01)
  LD (Temp1),A
  AND $07
  LD E,A
  LD D,$00
  LD HL,SparkleMasks
  ADD HL,DE
  LD A,(HL)
  PUSH AF
  LD A,(IY+$02)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(Temp1)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,BufferPlayOrigin
  ADD HL,DE
  POP AF
  OR (HL)
  LD (HL),A
  LD A,(Vanishing)
  OR A
  JP Z,SparkleDotIn
  JP SparkleDotOut
SparkleDotNext:
  LD DE,$0003             ; the next particle
  ADD IY,DE
  POP BC
  DJNZ SparkleDotLoop
  LD A,(Vanishing)
  OR A
  JP Z,SparkleDots2
  LD A,(RexY)
  DEC A
  CP $18
  JP C,SparkleDots2
  LD (RexY),A
SparkleDots2:
  LD A,(SparkleTimer)     ; the dots' timer
  DEC A
  LD (SparkleTimer),A
  OR A
  RET NZ
  LD A,$01
  LD (RexPresent),A
  XOR A
  LD (SparkleOn),A
  LD (SparkleMode),A
  LD A,(Dying)
  OR A
  JP NZ,LifeLost
  RET
SparkleDir:
  LD A,(Vanishing)        ; in or out
  OR A
  JP NZ,SparkleMove
  LD A,(SparkleTimer)
  CP $32
  JP C,SparkleDotNext
  CALL Random2
  AND $0F
  ADD A,$04
  LD (IY+$00),A
  CALL Random2
  AND $0F
  LD (IY+$01),A
  LD (IY+$02),$00
  JP SparkleDotNext
SparkleMove:
  LD A,(SparkleTimer)     ; move the dots
  CP $32
  JP C,SparkleDotNext
  CALL Random2
  AND $0F
  ADD A,$04
  LD (IY+$00),A
  CALL Random2
  AND $0F
  LD (IY+$01),A
  LD A,(RexY)
  SUB $04
  LD (IY+$02),A
  JP SparkleDotNext
SparkleDotIn:
  LD A,(IY+$02)           ; a dot moving in
  ADD A,(IY+$00)
  LD HL,RexY
  CP (HL)
  JP C,SparkleDotStore
  LD (IY+$00),$00
  CALL RexAppears
  JP SparkleDotNext
SparkleDotStore:
  LD (IY+$02),A           ; its new place
  JP SparkleDotNext
SparkleDotOut:
  LD A,(IY+$02)           ; a dot moving out
  SUB (IY+$00)
  CP $DF
  JP C,SparkleDotStore2
  LD (IY+$00),$00
  JP SparkleDotNext
SparkleDotStore2:
  LD (IY+$02),A           ; its new place
  JP SparkleDotNext

; Eight bit masks $80-$01, then the particles' offsets (SparkleDots)
SparkleMasks:
  DEFB $80,$40,$20,$10,$08,$04,$02,$01
SparkleDots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the sparkle's particles: Y, X offset
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; pairs
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00
