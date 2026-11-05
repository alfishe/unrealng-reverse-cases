; --------------------------------------------------------------------------------------------------------------------
; player.asm: the player's ship: movement, fuel, fire, hit and death
;
; The ship is the record at $F36C, kind 0. Its weapon state lives in the player record $7F9C (pointer $7F99, the
; second player's at its own place): +$07 the pod selector 0-4 (the highlighted panel item), +$08 the side weapon (0
; none, 2 plasma, 3 homing missiles, 4 seeker), +$09 the double plasma flag, +$0A the laser level 0-3, +$0B the speed
; $40-$A0 in steps of $20.
;
; The fuel: $80E6 counts down in the passes whose PassBit $7F63 (rotated left each pass) has bit 0 set, one in 8
; passes, so one step every 16 TV frames in play (measured: $54, $4A, $40 at 160-frame intervals); at 0 FuelOut sets
; it back to $5A and takes a laser level and a speed step away. A collected pod refills it ($BB with a speed-up, $B4
; when the selector wraps), a missed pod halves it ($A25C). So the ship must keep scooping pods to keep its power: $5A
; steps, about 29 s, a level with nothing collected. Measured: $80E6 = 2 with laser 3 and speed $A0 gave $80E6 = $5A,
; laser 2 and speed $80 forty frames later (../zynaps/work/f2, play-imm.szx).
;
; The death: a scenery hit or an enemy overlap (the enemies of $80BD/$80BE excepted) calls KillPlayer unless the byte
; at $FFD7 is not 0. That byte is 0 in the image and nothing writes it: a switch left for testing. Measured
; (../zynaps/work/f2, play-imm.szx, the ship put in the floor with Y = 14): $FFD7 = 0 starts the death timer ($7F7B =
; $12 ten frames later), $FFD7 = 1 keeps $7F7B = $FF, the ship immune. The death timer $7F7B ($FF while alive) counts
; $16 frames of explosion, then $7F7C = 1 tells the game loop.
; --------------------------------------------------------------------------------------------------------------------

; kind 0: the ship for one pass
;
; Not alive ($7F7B not $FF): PlayerDying. Else the fuel count; $A6B6; the input
; $8186 (bits 0/1 right/left, 2/3 down/up): up or down sets Vy = the speed -
; $20 at once, left or right accelerate X up to the speed + $20 (the
; acceleration masked at the limit), no horizontal input brakes Vx to 0.
; PathOpAccelerate moves, ClampRow and ClampColumn keep it on the screen,
; scenery under the ship undoes the row move (to the row's edge). A moving ship
; writes its position into the ring of 8 at $80C0 (index $80BF): the sight
; follows it from there.
;
; The colour +$25: $70, or the flashing $7F79 x 8 + $40 while fire has been
; held 8 passes or more ($8184, the pod-collect signal). The side weapon's
; frame routine from $80EA by +$08 - 2; a fire press ($8185 = $FF) FireLaser;
; then the hit test. 659 executions in 48K c2.
PlayerHandler:
  LD A,(DeathTimer)
  CP $FF
  JP NZ,PlayerDying
  LD IX,(PlayerRecord)
  LD A,(PassBit)
  RRA
  JR NC,PlayerInput
  LD HL,Fuel              ; the fuel, on the passes with PassBit bit 0 set (one
                          ; in 8)
  DEC (HL)
  CALL Z,FuelOut
PlayerInput:
  CALL ReadControls       ; the input bits
  LD A,(ControlBits)
  LD E,A
  AND $03
  JR NZ,PlayerNoDrift
  LD C,$02                ; no horizontal input: brake against the motion
  BIT 7,(IY+$0F)
  JR Z,PlayerDrift
  DEC C
PlayerDrift:
  LD A,(IY+$0E)           ; Vx 0: nothing to brake
  AND A
  JR NZ,PlayerVertical
PlayerNoDrift:
  LD C,$00                ; no brake flags
PlayerVertical:
  LD A,C                  ; up/down: Vy = +-(speed - $20)
  OR E
  LD E,A
  LD H,(IY+$06)
  LD L,(IY+$05)
  AND $0C
  LD D,$00
  JR Z,PlayerHorizontal
  LD A,(IX+$0B)
  SUB $20
  LD L,$E0
  BIT 2,E
  JR NZ,PlayerHorizontal
  LD L,$00
  DEC D
  NEG
PlayerHorizontal:
  LD (IY+$12),A           ; the X speed limit = speed + $20
  LD (IY+$13),D
  LD A,(IX+$0B)
  ADD A,$20
  LD D,A
  LD A,(IY+$0E)
  LD C,$01
  BIT 7,(IY+$0F)
  JR Z,PlayerSpeedLimit
  INC C
  NEG
PlayerSpeedLimit:
  CP D                    ; under the limit: accelerate
  JR NC,PlayerMove
  LD C,$00
PlayerMove:
  LD A,C                  ; the flags into bits 3-6, move, clamp, scenery
  CPL
  AND E
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  PUSH HL
  CALL PathOpAccelerate
  CALL ClampRow
  CALL ClampColumn
  CALL SceneryAt6
  POP HL
  JR NC,PlayerHistory
  LD (IY+$05),L           ; on the scenery: back to the old row
  LD (IY+$06),H
PlayerHistory:
  LD A,(IY+$0E)           ; moving: X, Y into the ring at $80C0
  OR (IY+$12)
  JR Z,PlayerColour
  LD HL,ShipHistoryIndex
  LD A,(HL)
  INC (HL)
  RES 3,(HL)
  LD HL,ShipHistory
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  EX DE,HL
  LD HL,PlayerObject+$0003
  LDI
  LDI
  LDI
  LDI
PlayerColour:
  LD A,(FireHeld)         ; fire held 8 passes: flash
  CP $08
  LD A,$70
  JR C,PlayerWeapon
  LD A,(SpinnerColour)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$40
PlayerWeapon:
  LD (IY+$25),A           ; the side weapon's frame routine
  LD IX,(PlayerRecord)
  LD A,(IX+$08)
  SUB $02
  JR C,PlayerFire
  LD HL,SideWeaponFrames
  CALL JumpTable
PlayerFire:
  LD A,(FireChanged)      ; a fire press: a laser shot
  INC A
  CALL Z,FireLaser
  CALL SceneryAt6         ; the hit test: scenery under the ship
  JR C,PlayerHit
  LD A,(HarmlessMaskA)    ; or an enemy not of $80BD/$80BE in the overlap mask
                          ; +$0D
  LD HL,HarmlessMaskB
  OR (HL)
  CPL
  AND (IY+$0D)
  RET Z
PlayerHit:
  LD A,(Invulnerable)     ; the test switch at $FFD7: not 0 = immune
  AND A
  RET NZ
  JP KillPlayer
PlayerDying:
  DEC A                   ; the death timer; at 0: $7F7C = 1
  LD (DeathTimer),A
  RET NZ
  LD A,$01
  LD (EndPending),A
  RET

; the ship destroyed: the timer and the explosion
;
; $7F7B = $16 (22 frames), all 16 records from $F36C deactivated,
; ScatterDebris. 2 executions in 48K c2.
KillPlayer:
  LD A,$16
  LD (DeathTimer),A
  LD B,$10
  LD HL,PlayerObject+$0008
  LD DE,$002C
KillPlayerLoop:
  RES 7,(HL)              ; +$08 bit 7 off in each record
  ADD HL,DE
  DJNZ KillPlayerLoop
  CALL ScatterDebris
  RET

; the weapon rating $80E7-$80E9 for the enemy fire and the wave colours
;
; L = laser level + side weapon: $80E7 = $FF, $30 from 4; $80E9 = 0, 8 from 7;
; $80E8 = ((speed / 32 + L) x 4) & $F0 + ($81DE). LaunchWave adds $80E9 to a
; kind's colour select (the KindColours set); EnemyFire reads $80E7 (the first
; shot's column) and $80E8 (the fire chance), so a well armed, fast ship draws
; more fire. Called from $AC7A and $B03A (10 entries in 48K c2).
WeaponRating:
  LD C,$FF
  LD B,$00
  LD IX,(PlayerRecord)
  LD A,(IX+$0A)
  ADD A,(IX+$08)
  CP $04
  JR C,WeaponRatingHigh
  LD C,$30
WeaponRatingHigh:
  CP $07                  ; 7 or more
  JR C,WeaponRatingStore
  LD B,$08
WeaponRatingStore:
  LD D,A                  ; the three values
  LD A,(IX+$0B)
  RLCA
  RLCA
  RLCA
  ADD A,D
  ADD A,A
  ADD A,A
  AND $F0
  LD HL,ScriptLevelBias
  ADD A,(HL)
  LD (WeaponRatingValue),A
  LD HL,WeaponRatingMask
  LD (HL),C
  LD HL,WeaponRatingLevel
  LD (HL),B
  RET

; the 5 records from $F398 as debris around IY
;
; Each at a random column X - 1 + 0-3 and a random row near Y, active, +$26 =
; 0, $A293 (the explosion picture), ClampRow, +$27 = random 0-3; $8072 = 0, so
; no wave starts until they are gone. Used by KillPlayer and BigEnemyHandler. 2
; entries in 48K c2.
;
; On a 128K: the LD ($8072),A at $9BFF becomes CALL HookShipLost ($B354): the
; store, then sounds $14 + $15 (src/game/setup.asm, glue.asm; docs/09-sound.md
; 9.2).
ScatterDebris:
  EXX
  LD C,(IY+$04)
  DEC C
  LD E,(IY+$05)
  LD D,(IY+$06)
  DEC D
  EXX
  PUSH IY
  LD B,$05
  LD IY,EnemyObjects
ScatterDebrisLoop:
  PUSH BC                 ; one piece
  CALL Random
  EXX
  LD B,A
  AND $03
  ADD A,C
  LD (IY+$04),A
  LD A,B
  RLCA
  RLCA
  RLCA
  LD L,A
  AND $03
  LD H,A
  XOR L
  LD L,A
  ADD HL,DE
  LD (IY+$05),L
  LD (IY+$06),H
  EXX
  LD (IY+$26),$00
  SET 7,(IY+$08)
  CALL StartExplosion
  CALL ClampRow
  CALL Random
  AND $03
  LD (IY+$27),A
  POP BC
  LD DE,$002C
  ADD IY,DE
  DJNZ ScatterDebrisLoop
  POP IY
  XOR A
  LD (FreeEnemySlots),A
  RET

; the fuel ran out: $80E6 = $5A, laser - 1, speed - $20
;
; The laser level +$0A of IX does not go below 0, the speed +$0B not below $40.
; Also called at $B119. 1 entry in 48K c2; measured, see the module notes.
FuelOut:
  LD HL,Fuel
  LD (HL),$5A
  DEC (IX+$0A)
  JP P,FuelOutSpeed
  INC (IX+$0A)
FuelOutSpeed:
  LD A,(IX+$0B)           ; the speed one step down, not below $40
  SUB $20
  CP $40
  RET C
  LD (IX+$0B),A
  RET

; fire a laser shot from the ship
;
; $80BA counts the shots not in flight (4 at most, set at $B2D1; LaserHandler
; gives one back): a shot is fired only when $80BA + the laser level is 4 or
; more, so level 0 has one shot in the air, level 3 four. The first free of the
; 4 slots at $F4F8: X + 1 column, Y + $1E0/256 for two shots out of three, +
; $20/256 for the third (+$26 counts the guns); sound effect 2 ($B2F0); $7F77 =
; 6 when 0. 564 entries in 48K c2.
;
; On a 128K: its CALL RequestEffect at $9C77 (effect 2) becomes CALL HookShot
; ($B32F): the page-4 engine plays sound $0E (src/game/setup.asm, glue.asm;
; docs/09-sound.md 9.2).
FireLaser:
  LD HL,LaserShotsFree
  LD A,(HL)
  AND A
  RET Z
  LD IX,(PlayerRecord)
  ADD A,(IX+$0A)
  CP $04
  RET C
  DEC (HL)
  LD B,$04
  LD IX,LaserShots
  LD DE,$002C
FireLaserFindSlot:
  BIT 7,(IX+$08)          ; a free shot slot?
  JR Z,FireLaserLaunch
  ADD IX,DE
  DJNZ FireLaserFindSlot
  RET
FireLaserLaunch:
  SET 7,(IX+$08)          ; the gun: two low, one high
  LD L,(IY+$05)
  LD H,(IY+$06)
  LD DE,$01E0
  LD A,(IY+$26)
  INC A
  CP $03
  JR C,FireLaserPlace
  XOR A
  LD D,A
  LD E,$20
FireLaserPlace:
  LD (IY+$26),A           ; the shot's position
  ADD HL,DE
  LD (IX+$05),L
  LD (IX+$06),H
  LD L,(IY+$03)
  LD H,(IY+$04)
  LD DE,$0100
  ADD HL,DE
  LD (IX+$03),L
  LD (IX+$04),H
  LD A,$02
  CALL RequestEffect      ; sound effect 2: the laser
  LD HL,PanelBurst
  LD A,(HL)
  AND A
  RET NZ
  LD (HL),$06
  RET
