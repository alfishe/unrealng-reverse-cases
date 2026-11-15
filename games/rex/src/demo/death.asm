; --------------------------------------------------------------------------------------------------------------------
; death.asm: Rex's death, the life lost, the restart points, the sparkle
; --------------------------------------------------------------------------------------------------------------------

; One pass of Rex's death: the shards, the death picture, the sound; at the end
; LifeLost
;
; As REX 1's DeathAnimation $9AC5 (src/game/death.asm).
;
; Witness: L1 102 (d1, demo-cycle).
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
  LD A,(DeathTimer)            ; the death's timer
  CP $10
  JP C,ShardNextRecord
  CALL Random2
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
  CALL Random2            ; a random attribute flash
  AND $03
  OR A
  JP Z,DeathFlash
  LD (SfxExplosion),A
  LD DE,SfxExplosion
  CALL StartSfx
  JP ShardNextRecord

; DeathShardPtr $5EE0 + 2
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

; DeathShardPtr $5EE0 - 2: the shards step back
;
; As REX 1's ShardBack $9BD1 (src/game/death.asm).
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

; Rex is killed (unless Immune): the sweep reset, Dying, the timer 50, the
; shards, the free smart bomb, the shield energy 99, HeatColour 7,
; dematerialise while lives are left
;
; Changed from REX 1's RexDies $9BDA (src/game/death.asm).
;
; Witness: L1 6 (d1, demo-cycle).
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
  LD A,$63
  LD (ShieldEnergy),A
  LD A,$07
  LD (HeatColour),A
  LD HL,$0064
  LD (HeatCount),HL
  LD A,(Lives)
  OR A
  CALL NZ,Dematerialise
  RET

; The shards' spread (DeathShardPtr), then the 16 shard records [frame][X][Y]
; (DeathAnimation)
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

; Rex on the restart marker (7): the save sound, the marker animated; at X & 7
; = 0 the restart point (X, Y, room) kept; then (LifeLost $92AE) a death's end:
; a life less, Rex back at the point or a new demo game
;
; Witness: L1 276 (d1, demo-cycle).
RestartMarker:
  INC HL
  LD A,(HL)
  CP $07
  RET NZ
  LD A,(Channels+$0008)
  CP $FF
  JP NZ,l_9280
  LD DE,SfxRestart
  CALL StartSfx
l_9280:
  CALL AnimateRestart
  LD A,(RexX)
  AND $07
  OR A
  RET NZ
  LD A,(RexFacing)
  OR A
  JP Z,l_9299
  LD A,(RexX)
  ADD A,$10
  JP l_929C
l_9299:
  LD A,(RexX)
l_929C:
  LD (RestartX),A
  LD A,(RexY)
  AND $F8
  LD (RestartY),A
  LD A,(Room)
  LD (RestartRoom),A
  RET

; LifeLost
;
; Used by the routines at DeathAnimation and SparkleDraw.
LifeLost:
  LD A,(Lives)            ; The end of a death: one life less; Rex back at the
                          ; restart point, or the game over
  DEC A
  LD (Lives),A
  CP $FF
  JP Z,GameOver
  CALL ShowLives
  LD A,(RestartX)
  AND $F0
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
  JP Z,l_92F5
  LD (Room),A
  POP BC
  JP MainLoop
l_92F5:
  RET
GameOver:
  JP NewGame              ; no life left: a new demo game (JP NewGame); no
                          ; panel, no high score

; The materialise is over: RexPresent $5EE6 = 1 (Rex can move and fire),
; SparkleCount $5EE7 = 18
;
; As REX 1's RexAppears $9D0F (src/game/death.asm).
;
; Witness: L1 339 (d1, demo-cycle).
RexAppears:
  LD A,(RexPresent)
  OR A
  RET NZ
  LD A,$01
  LD (RexPresent),A
  LD A,$12
  LD (SparkleCount),A
  RET

; Rex appears: RexPresent 0, the sparkle in (SparkleOn $5EE8, SparkleMode
; $5EE9), its dots cleared, the materialise sound $D9B2
;
; As REX 1's Materialise $9D1F (src/game/death.asm).
;
; Witness: L1 5 (d1, demo-cycle).
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

; Rex vanishes: the shield off, the sparkle out (Vanishing $5EEB = 1), the
; sound $D9BE
;
; As REX 1's Dematerialise $9D47 (src/game/death.asm).
;
; Witness: L1 6 (d1, demo-cycle).
Dematerialise:
  LD DE,SfxDematerialise
  CALL StartSfx
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
; Witness: L1 6753 (d1, demo-cycle).
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
  CALL Random2
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

; Leftover: LD A,100: LD (SparkleTimer),A; nothing reaches it
;
; Witness: L1 0 ().
SparkleLeftover:
  LD A,$64
  LD (SparkleTimer),A

; Vanishing: SparkleCount $5EE7 + 1; at 18 Rex is gone (RexPresent 0) and the
; sparkle's timer is 30
;
; As REX 1's SparkleOut $9DCE (src/game/death.asm).
;
; Witness: L1 102 (d1, demo-cycle).
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

; Leftover: if SparkleOn, SparkleDraw; nothing calls it
;
; Witness: L1 0 ().
SparkleIfOn:
  LD A,(SparkleOn)
  OR A
  CALL NZ,SparkleDraw
  RET

; Write C into a 3 x 3 patch at HL (32-byte rows)
;
; As REX 1's FillCells3 $9DF6 (src/game/death.asm).
;
; Witness: L1 192 (d1, demo-cycle).
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

; Draw the sparkle's particles round Rex (SparkleMasks $94F2 by X & 7,
; SparkleDots $94FA); at the end of a dematerialise LifeLost
;
; Changed from REX 1's SparkleDraw $9E02 (src/game/death.asm).
;
; Witness: L1 6753 (d1, demo-cycle).
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
  LD A,(SparkleTimer)            ; the dots' timer
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
  LD A,(Vanishing)            ; in or out
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
  LD A,(SparkleTimer)            ; move the dots
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

; The particle's pixel mask by X & 7 (SparkleDraw), then SparkleDots $94FA:
; [count][X offset][Y] records
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
