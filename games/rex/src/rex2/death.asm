; --------------------------------------------------------------------------------------------------------------------
; death.asm: Rex's death, the life lost, the game over, the restart points, the sparkle, the objects' dissolve
; --------------------------------------------------------------------------------------------------------------------

; One pass of Rex's death: the shards, the death picture, the sound; at the end
; LifeLost
;
; As REX 1's DeathAnimation $9AC5 (src/game/death.asm).
;
; Witness: L1 557 (c2, p2-room20, rzx-p2- x14).
DeathAnimation:
  LD A,(Lives)
  OR A
  JP NZ,DrawRex
  LD IY,ExplosionAreas+$0006
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

; DeathShardPtr $A1F0 + 2
;
; As REX 1's ShardNext $9BC8 (src/game/death.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
ShardNext:
  LD HL,(DeathShardPtr)
  INC HL
  INC HL
  LD (DeathShardPtr),HL
  RET

; DeathShardPtr $A1F0 - 2: the shards step back
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
ShardBack:
  LD HL,(DeathShardPtr)
  DEC HL
  DEC HL
  LD (DeathShardPtr),HL
  RET

; BossAreaPtr $A26A - 2: the boss's explosion area the smaller one
; (BossExplodes at timer $82)
;
; Witness: L1 1 (rzx-p2-40000).
ShrinkArea:
  LD HL,(BossAreaPtr)
  DEC HL
  DEC HL
  LD (BossAreaPtr),HL
  RET

; Rex is killed (unless Immune): the sweep reset, Dying, the timer 50, the free
; smart bomb (none while the boss dies), LosePower, ShieldEnergy refilled to
; 99, dematerialise while lives are left (which switches the shield off)
;
; Changed from REX 1's RexDies $9BDA (src/game/death.asm).
;
; Witness: L1 36 (c2, p2-room20, rzx-p2- x14).
RexDies:
  LD A,(Immune)
  OR A
  RET NZ
  CALL ResetSweep
  LD A,$01
  LD (Dying),A
  LD A,$32
  LD (DeathTimer),A
  LD HL,ExplosionAreas
  LD (DeathShardPtr),HL
  LD A,(BossDying)
  OR A
  JP NZ,RexDiesPower
  CALL SmartBombFree
RexDiesPower:
  CALL LosePower          ; LosePower (the boss's death gives no free bomb)
  LD A,$63
  LD (ShieldEnergy),A
  LD A,(Lives)
  OR A
  CALL NZ,Dematerialise
  RET

; The explosion areas: [size][mask] pairs $10/$03, $20/$07, $40/$0F; Rex's
; death starts at $9CF7, the boss's at $9CF9
;
; A piece comes back at X = $68 - size + 8 x (random AND mask), likewise Y
; (BossExplodes); the boss moves from the middle pair to the first at timer $82
; (ShrinkArea).
ExplosionAreas:
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
; As REX 1's SaveRestart $9C3B (src/game/death.asm).
;
; Witness: L1 550 (c2, p2-room20, rzx-p2- x15).
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

; The end of a death: BossDying 0, one life less; Rex back at the restart
; point, or the game over
;
; Witness: L1 29 (c2, p2-room20, rzx-p2- x12).
LifeLost:
  XOR A
  LD (BossDying),A
LifeLostCount:
  LD A,(Lives)            ; one life less
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
                          ; HI-SCORE and BIO GROWTHS KILLED $A222, wait for
                          ; fire, NewGame
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
  LD IX,BioGrowthsText
  LD B,$01
  CALL PrintBoxed
  LD HL,(GrowthsKilled)
  CALL ToDigits
  LD E,$1E
  LD L,$80
  LD B,$05
  CALL PrintDigits
  LD HL,(HiScore)
  CALL ToDigits
  LD E,$12
  LD L,$60
  LD B,$05
  CALL PrintDigits
  CALL WaitFire
  JP NewGame

; The materialise is over: RexPresent $A1F6 = 1 (Rex can move and fire),
; SparkleCount $A1F7 = 18
;
; As REX 1's RexAppears $9D0F (src/game/death.asm).
;
; Witness: L1 1899 (c2, p2-room20, rzx-p2- x12).
RexAppears:
  LD A,(RexPresent)
  OR A
  RET NZ
  LD A,$01
  LD (RexPresent),A
  LD A,$12
  LD (SparkleCount),A
  RET

; Rex appears: RexPresent 0, the sparkle in (SparkleOn $A1F8, SparkleMode
; $A1F9), its dots cleared, the materialise sound $D546
;
; As REX 1's Materialise $9D1F (src/game/death.asm).
;
; Witness: L1 32 (c2, p2-room20, rzx-p2- x12).
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

; Rex vanishes: the shield off, the sparkle out (Vanishing $A1FB = 1), the
; sound $D552
;
; As REX 1's Dematerialise $9D47 (src/game/death.asm).
;
; Witness: L1 36 (c2, p2-room20, rzx-p2- x14).
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

; One step of the sparkle in Rex's 3-byte box of the back buffer
; (SparkleBufferOrigin $E89F): SparkleCount lines cleared, the next 3 ANDed
; with random bytes; at the end the sparkle stops
;
; As REX 1's SparkleUpdate $9D71 (src/game/death.asm).
;
; Witness: L1 10438 (c2, p2-room20, rzx-p2- x21).
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
  LD DE,AttrShadowPlay+$0340
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

; Leftover: LD A,$64: LD ($A1FA),A after SparkleUpdate's JP; no instruction
; reaches it
SparkleLeftover:
  DEFB $3E,$64,$32,$FA,$A1

; Vanishing: SparkleCount $A1F7 + 1; at 18 Rex is gone (RexPresent 0) and the
; sparkle's timer is 30
;
; As REX 1's SparkleOut $9DCE (src/game/death.asm).
;
; Witness: L1 557 (c2, p2-room20, rzx-p2- x14).
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

; The object at IX materialises: dissolve on (IX+$18), step 0 (IX+$19), inwards
; (IX+$1A); ObjectDissolve counts it up to 10
;
; Witness: L1 136 (c2, p2-room20, rzx-p2- x19).
ObjectFadeIn:
  LD (IX+$1A),$01
  LD (IX+$18),$01
  LD (IX+$19),$00
  RET

; Unless it dissolves already, the object at IX dissolves out from step 10; a
; kind 0 also becomes a jumper (MakeJumper)
;
; Witness: L1 8 (c2, rzx-p2-00000, rzx-p2-16000, rzx-p2-28000, rzx-p2-32000).
ObjectFadeOut:
  LD A,(IX+$18)
  OR A
  RET NZ
  LD (IX+$1A),$00
  LD (IX+$18),$01
  LD (IX+$19),$0A
  LD A,(IX+$09)
  OR A
  RET NZ
  CALL MakeJumper
  RET

; The dissolve's masks by step: $10, $22, $89, $65, $AB, $DB, $F7, $FF, $FF,
; $FF
DissolveMasks:
  DEFB $10,$22,$89,$65,$AB,$DB,$F7,$FF,$FF,$FF

; A dissolving object: its bytes in the back buffer ANDed with a random byte
; and the step's mask; in: step + 1 to 10; out: step - 1, at 0 the object is
; gone
;
; Witness: L1 47643 (c2, p2-room20, rzx-p2- x20).
ObjectDissolve:
  LD A,(IX+$18)
  OR A
  RET Z
  LD A,(IX+$01)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,AttrShadowPlay+$03A0
  ADD HL,DE
  LD A,(IX+$02)
  OR A
  JP Z,DissolveRows
  INC HL
DissolveRows:
  LD C,$00                ; the object's lines
  LD B,(IX+$19)
  LD IY,DissolveMasks
  LD A,(IX+$19)
  LD E,A
  LD D,$00
  ADD IY,DE
  LD B,(IX+$0F)
DissolveRow:
  PUSH BC                 ; each line
  LD B,(IX+$0E)
  PUSH HL
DissolveByte:
  PUSH BC                 ; each byte: AND a random byte, AND the mask
  CALL Random2
  AND (HL)
  AND (IY+$00)
  LD (HL),A
  INC HL
  POP BC
  DJNZ DissolveByte
  POP HL
  LD DE,$0020
  ADD HL,DE
  POP BC
  DJNZ DissolveRow
  LD A,(IX+$1A)
  OR A
  JP NZ,DissolveIn
  DEC (IX+$19)
  RET NZ
  LD (IX+$18),$00
  LD (IX+$0C),$00
  RET
DissolveIn:
  LD A,(IX+$19)           ; inwards: step + 1
  INC A
  LD (IX+$19),A
  CP $0A
  RET NZ
  LD (IX+$18),$00
  RET

; Write C into a 3 x 3 patch at HL (32-byte rows)
;
; As REX 1's FillCells3 $9DF6 (src/game/death.asm).
;
; Witness: L1 1097 (c2, p2-room20, rzx-p2- x14).
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

; Draw the sparkle's particles round Rex (SparkleMasks $A0A5, SparkleDots
; $A0AD); at the end of a dematerialise LifeLost
;
; As REX 1's SparkleDraw $9E02 (src/game/death.asm).
;
; Witness: L1 10437 (c2, p2-room20, rzx-p2- x21).
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
