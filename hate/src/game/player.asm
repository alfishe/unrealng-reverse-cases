; Input: the AUTO countdown, or the chosen device into the control byte
;
; Called once a pass by the play loop outside the demo (docs/04-game-loop.md
; 4.3, step 4). While the countdown $E68B runs it does not read the device: it
; prints " AUTO " ($64F6), or six spaces ($F136) on the pass that ends the
; count, requests sound bit 3, moves the convoy, steers the player 2 across
; toward $2C, sets the new height $C2F6 to the height - 1 (not below 2) plus (6
; - count) / 2 over the last 6 passes, and sets the speed $C006 to 0 while the
; reserve $E7B8 lasts, else 1; the followers ($C066 + 16 * k) get the same
; speed. docs/05-controls.md 5.4, docs/10-gameplay-logic.md 10.4.
;
; With the countdown at 0 it reads the device chosen in the menu ($C28F: 0
; keyboard, 1 Sinclair, 2 Kempston, 3 Protek-AGF) into the control byte $C290
; (bit 0 left, 1 right, 2 down, 3 up, 4 fire, active high) and jumps to the
; player routine $E7E9. docs/05-controls.md 5.2-5.3.
ReadControls:
  LD A,(AutoCountdown)    ; AUTO countdown, set by the round setup ($D251) and
                          ; at the barrier
  AND A
  JR Z,ReadDevice
  DEC A
  LD (AutoCountdown),A
  LD HL,BlankMessage      ; the count reached 0: clear the message window
  JR Z,PrintAutoText
  LD HL,AutoText          ; still counting: " AUTO " (the string stored in the
                          ; font's spare slots)
PrintAutoText:
  CALL PrintString
  LD A,(AutoCountdown)    ; the count, kept in A' for the height ease below
  EX AF,AF'
  LD HL,SoundRequests     ; sound request bit 3: the AUTO beep
  SET 3,(HL)
  CALL ConvoyFollow       ; the followers copy the leader
  LD A,($C003)            ; position across: 2 a pass toward the middle of the
                          ; track, $2C
  CP $2C
  JR Z,AutoStoreAcross
  JR C,AutoAcrossUp
  DEC A
  DEC A
  JR AutoStoreAcross
AutoAcrossUp:
  INC A
  INC A
AutoStoreAcross:
  LD (PlayerRecord+$0003),A
  LD A,($C004)            ; height - 1, but not below 2
  CP $03
  JR C,AutoStoreHeight
  DEC A
AutoStoreHeight:
  LD (MoverHeight),A
  EX AF,AF'
  CP $06                  ; last 6 passes: + (6 - count) / 2
  JR NC,AutoSpeed
  LD B,A
  LD A,$06
  SUB B
  SRL A
  LD B,A
  EX AF,AF'
  ADD A,B
  LD (MoverHeight),A
AutoSpeed:
  LD B,$01
  LD A,(SpeedReserve)     ; speed 0 while the reserve lasts, then 1
  AND A
  JR Z,AutoStoreSpeed
  DEC A
  LD (SpeedReserve),A
  DEC B
AutoStoreSpeed:
  LD A,B
  LD (PlayerRecord+$0006),A
  LD A,(Followers)        ; no followers: done
  AND A
  RET Z
  LD A,B
  LD HL,PodRecords+$0006  ; +6 (speed) of the four pod slots $C060-$C090
  LD DE,$0010
  LD B,$04
AutoPodSpeedLoop:
  LD (HL),A
  ADD HL,DE
  DJNZ AutoPodSpeedLoop
  RET
ReadDevice:
  LD A,(InputDevice)      ; $C28F: the device chosen in the menu
  CP $01
  JR Z,ReadSinclair
  CP $02
  JR Z,ReadKempston
  CP $03
  JR Z,ReadProtek
ReadKeyboard:
  LD B,$00                ; device 0: Q, A, K, L, fire on the bottom two rows
  LD HL,PlayerRecord
  LD A,$FB                ; Q
  IN A,($FE)
  RRA
  JR C,ReadKeyA
  BIT 0,(HL)              ; bit 0 of $C000 (the vehicle type) decides whether Q
                          ; is up or down
  JR Z,QIsDown
  SET 3,B
  JR ReadKeyA
QIsDown:
  SET 2,B
ReadKeyA:
  LD A,$FD                ; A, the opposite of Q
  IN A,($FE)
  RRA
  JR C,ReadKeysKL
  BIT 0,(HL)
  JR Z,AIsUp
  SET 2,B
  JR ReadKeysKL
AIsUp:
  SET 3,B
ReadKeysKL:
  LD A,$BF                ; L (bit 1) right, K (bit 2) left
  IN A,($FE)
  RRA
  RRA
  JR C,ReadKeyK
  SET 1,B
ReadKeyK:
  RRA
  JR C,ReadFireRows
  SET 0,B
ReadFireRows:
  LD A,$7E                ; $7EFE selects the rows $7FFE and $FEFE together:
                          ; any key there fires
  IN A,($FE)
  CPL
  AND $1F
  JR Z,StoreKeyboard
  SET 4,B
StoreKeyboard:
  LD A,B
  LD (ControlByte),A      ; the control byte
  JP MovePlayer
ReadSinclair:
  LD A,$F7                ; device 1, both Interface 2 rows: 1-5 left, right,
                          ; down, up, fire as they are
  IN A,($FE)
  CPL
  AND $1F
  LD E,A
  LD A,$EF                ; 0, 9, 8, 7, 6 from bit 0: reversed below to line up
                          ; with 1-5
  IN A,($FE)
  CPL
  LD C,A
  XOR A
  LD B,$05
ReverseBitsLoop:
  RR C                    ; five bits of C reversed into A
  RLA
  DJNZ ReverseBitsLoop
  OR E                    ; the two sticks ORed together
  LD (ControlByte),A
  JP MovePlayer
ReadKempston:
  IN A,($1F)              ; device 2: port $1F
  LD B,A
  AND $1C                 ; down, up, fire as they are
  BIT 0,B                 ; Kempston right (bit 0) is the game's bit 1
  JR Z,KempstonLeft
  SET 1,A
KempstonLeft:
  BIT 1,B                 ; Kempston left (bit 1) is the game's bit 0
  JR Z,StoreKempston
  SET 0,A
StoreKempston:
  LD (ControlByte),A
  JR MovePlayer
ReadProtek:
  LD E,$00                ; device 3: the cursor keys 5, 6, 7, 8 and 0
  LD A,$F7
  IN A,($FE)
  BIT 4,A                 ; 5: left
  JR NZ,ProtekDown
  SET 0,E
ProtekDown:
  LD A,$EF
  IN A,($FE)
  BIT 4,A                 ; 6: down
  JR NZ,ProtekUp
  SET 2,E
ProtekUp:
  BIT 3,A                 ; 7: up
  JR NZ,ProtekRight
  SET 3,E
ProtekRight:
  BIT 2,A                 ; 8: right
  JR NZ,ProtekFire
  SET 1,E
ProtekFire:
  BIT 0,A                 ; 0: fire
  JR NZ,StoreProtek
  SET 4,E
StoreProtek:
  LD A,E
  LD (ControlByte),A
  JR MovePlayer

; Passes with fire held
;
; Counts the passes fire is held, 0 when released ($E7E9). A shot leaves on odd
; counts (every other pass), a shell of the ground vehicle only when bit 1 is
; clear as well (every fourth pass). docs/07-objects.md 7.7.
FireCount:
  DEFB $00

; The ground vehicle's speed reserve
;
; Spent by slowing down (down held, or the AUTO start), earned back by speeding
; up (up held), at most 32; 10 at each round start. docs/10-gameplay-logic.md
; 10.3.
SpeedReserve:
  DEFB $00

; The followers copy the one in front
;
; With followers ($ECE4 not 0) it walks the convoy links $ECE7-$ECF0 from the
; last to the first: each follower's position across (+3) takes the value of
; the record in front of it (the first follower takes the player's $C003), and
; while the player moves ($C006 not 0) the height (+4) too. Going from the back
; to the front makes each follower take its leader's value of the pass before:
; the convoy trails the player's moves. Called by $E68C (AUTO) and $E7E9.
; docs/07-objects.md 7.5, docs/10-gameplay-logic.md 10.4.
ConvoyFollow:
  LD A,(Followers)        ; followers
  AND A
  RET Z
  LD HL,ConvoyLinks+$0009 ; the last link: DE = its follower's +3
  LD B,$04
ConvoyLinkLoop:
  PUSH BC
  PUSH HL
  LD A,(HL)
  CP $FF
  JR Z,NextConvoyLink
  LD D,A
  DEC HL
  LD E,(HL)
  DEC HL
  LD A,(HL)               ; BC = the link in front ($FF high byte: none)
  CP $FF
  JR Z,NextConvoyLink
  LD B,A
  DEC HL
  LD C,(HL)
  LD A,(BC)               ; across from the one in front
  LD (DE),A
  LD A,($C006)            ; standing: the height is not copied
  AND A
  JR Z,NextConvoyLink
  INC E
  INC C
  LD A,(BC)
  LD (DE),A
NextConvoyLink:
  POP HL
  DEC HL
  DEC HL
  POP BC
  DJNZ ConvoyLinkLoop
  RET

; The player: shot life, firing
;
; Entered by a jump from the device readers. It moves the convoy, ages the
; player's five shots ($C010-$C050, +F counts passes; at 12 a shot not
; exploding is removed) and fires while bit 4 of $C290 is held: a shot every
; other pass into a free slot from template $C360, at the player's position + 4
; along, its position across and 2 below its height; the ground vehicle (bit 0
; of $C000) holding up as well lobs a shell instead, from template $C370 every
; fourth pass, its arc step +E set from the player's height against the arc
; table $C282. Sound request bit 4 per shot. Falls into $E8AF.
; docs/07-objects.md 7.7, docs/10-gameplay-logic.md 10.3.
MovePlayer:
  CALL ConvoyFollow
  LD HL,PlayerShotRecords ; the five shot slots, +F (16 - 1 bytes on)
  LD DE,$000F
  LD B,$05
AgeShotLoop:
  LD A,(HL)
  ADD HL,DE
  BIT 7,A
  JR NZ,NextShotAge
  LD A,(HL)               ; the shot's age, one more a pass
  INC A
  LD (HL),A
  CP $0C                  ; 12 passes: its life is over
  JR C,NextShotAge
  AND A
  SBC HL,DE
  BIT 5,(HL)              ; exploding shots run their explosion out
  JR NZ,ShotExploding
  SET 7,(HL)              ; gone
ShotExploding:
  ADD HL,DE
NextShotAge:
  INC HL
  DJNZ AgeShotLoop
  LD A,(ControlByte)      ; fire held?
  BIT 4,A
  JR NZ,FireHeld
  XOR A                   ; released: the count starts again
  LD (FireCount),A
  JP PlayerSteer
FireHeld:
  LD A,(FireCount)
  INC A
  LD (FireCount),A
  LD C,A
  BIT 0,A                 ; every other pass
  JP Z,PlayerSteer
  LD A,(PlayerRecord)
  BIT 5,A                 ; a player being hit does not fire, and RET skips its
                          ; steering and walls this pass
  RET NZ
  LD B,$05
  LD DE,$0010
  LD HL,PlayerShotRecords
FreeShotLoop:
  BIT 7,(HL)              ; the first free shot slot (bit 7)
  JR NZ,ShotSlotFound
  ADD HL,DE
  DJNZ FreeShotLoop
  JP PlayerSteer
ShotSlotFound:
  LD A,(PlayerRecord)
  BIT 0,A                 ; the ground vehicle ...
  JR Z,FireShot
  LD A,(ControlByte)
  BIT 3,A                 ; ... with up held ...
  JR Z,FireShot
  BIT 1,C                 ; ... lobs a shell every fourth pass
  JP NZ,PlayerSteer
  PUSH HL
  LD DE,ShellTemplate     ; the shell template
  EX DE,HL
  LD BC,$0010
  LDIR
  POP DE
  LD HL,(PlayerRecord+$0001) ; along: the player's position + 4
  LD BC,$0004
  ADD HL,BC
  EX DE,HL
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  LD DE,(PlayerRecord+$0003) ; across and (D) height
  INC L
  LD (HL),E
  PUSH HL
  LD A,D
  LD HL,MissileArc        ; the step of the arc table $C282 at the player's
                          ; height
  LD E,$00
ArcStepLoop:
  CP (HL)
  JR C,StoreArcStep
  INC E
  INC HL
  JR ArcStepLoop
StoreArcStep:
  POP HL
  INC L
  LD (HL),A
  LD BC,$000A
  ADD HL,BC
  LD (HL),E               ; +E: the arc step
  JR ShotSound
FireShot:
  PUSH HL
  LD DE,ShotTemplate      ; the shot template
  LD BC,$0010
  EX DE,HL
  LDIR
  POP DE
  LD HL,(PlayerRecord+$0001)
  LD BC,$0004
  ADD HL,BC
  EX DE,HL
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  LD DE,(PlayerRecord+$0003)
  INC L
  LD (HL),E
  INC L
  DEC D                   ; 2 below the player's height
  DEC D
  LD (HL),D
ShotSound:
  LD HL,SoundRequests     ; sound request bit 4: a shot
  SET 4,(HL)

; The player: height or speed, walls, across
;
; The aircraft (type 0) changes height: down held adds (counter + 1) / 2 with
; the counter $E687 growing to 6, up held subtracts with $E688; the new height
; $C2F6 stays within 2-26. The ground vehicle (type 1) changes speed instead: 0
; with down held while the reserve $E7B8 lasts, 2 with up held while the
; reserve is below 32, 1 otherwise, and the followers get the same speed.
; docs/10-gameplay-logic.md 10.3.
;
; Walls: six bytes of the course profile under the player ($5FF7 + position /
; 2) are ORed; a bit 7 wall limits the position across to below $17, a bit 6
; wall to below $27, else $47. A player already past the limit when a wall
; begins is crashed ($E979): it is hit, stops, moves back 2, and every follower
; is hit too, sound bit 1. Then left and right move it across, accelerating
; with the counters $E689 and $E68A up to a step of 6, within 2 and the limit.
; docs/07-objects.md 7.4, 7.7.
PlayerSteer:
  LD A,(ControlByte)
  LD B,A
  LD A,(PlayerRecord)     ; type 0 the aircraft, type 1 the ground vehicle
  BIT 0,A
  JR NZ,GroundVehicle
  LD A,($C004)            ; the aircraft: height into $C2F6
  LD (MoverHeight),A
  LD L,A
  XOR A
  BIT 2,B                 ; down held: the down counter grows to 6
  JR Z,StoreDownCount
  LD A,(DownHeldCount)
  CP $06
  JR NC,StoreDownCount
  INC A
StoreDownCount:
  LD (DownHeldCount),A
  INC A                   ; + (counter + 1) / 2
  SRL A
  ADD A,L
  CP $1B                  ; at most 26
  JR C,HeightAfterDown
  LD A,$1A
HeightAfterDown:
  LD (MoverHeight),A
  LD L,A
  XOR A
  BIT 3,B                 ; up held: the up counter grows to 6
  JR Z,StoreUpCount
  LD A,(UpHeldCount)
  CP $06
  JR NC,StoreUpCount
  INC A
StoreUpCount:
  LD (UpHeldCount),A
  INC A
  SRL A
  LD C,A
  LD A,L                  ; - (counter + 1) / 2
  SUB C
  CP $03
  JR C,HeightFloor
  CP $1B
  JR C,HeightAfterUp
HeightFloor:
  LD A,$02                ; below 3 or wrapped: 2
HeightAfterUp:
  LD (MoverHeight),A
  JR WallCheck
GroundVehicle:
  LD A,(PlayerRecord)     ; the ground vehicle: speed, not height
  BIT 5,A                 ; being hit: no steering
  JR NZ,WallCheck
  LD C,$01
  BIT 4,B                 ; fire and up together: speed 1 (the shell is lobbed)
  JR Z,CheckSlowDown
  BIT 3,B
  JR NZ,StoreVehicleSpeed
CheckSlowDown:
  BIT 2,B                 ; down: slower, spending the reserve
  JR Z,CheckSpeedUp
  LD A,(SpeedReserve)
  AND A
  JR Z,StoreVehicleSpeed
  DEC A
  LD (SpeedReserve),A
  DEC C
  JR StoreVehicleSpeed
CheckSpeedUp:
  BIT 3,B                 ; up: faster, earning the reserve back to 32
  JR Z,StoreVehicleSpeed
  LD A,(SpeedReserve)
  CP $20
  JR NC,StoreVehicleSpeed
  INC A
  LD (SpeedReserve),A
  INC C
StoreVehicleSpeed:
  LD A,C
  LD (PlayerRecord+$0006),A ; the speed
  LD HL,ConvoyLinks+$0009 ; the followers' +6 get the same speed
  LD B,$04
FollowerSpeedLoop:
  LD A,(HL)
  DEC HL
  CP $FF
  JR Z,NextFollowerSpeed
  LD D,A
  LD E,(HL)
  INC E
  INC E
  INC E
  LD A,C
  LD (DE),A
NextFollowerSpeed:
  DEC HL
  DJNZ FollowerSpeedLoop
WallCheck:
  LD DE,ProfileMargin+$0043 ; the profile under the player: $6000 - 9 +
                            ; position / 2
  LD HL,(PlayerRecord+$0001)
  SRL H
  RR L
  ADD HL,DE
  LD B,$05
  LD C,$00
  LD A,(HL)               ; C = 0 if the first byte is a bit 7 wall, 1 if bit
                          ; 6, 2 if neither
  BIT 7,A
  JR NZ,OrProfileBytes
  INC C
  BIT 6,A
  JR NZ,OrProfileBytes
  INC C
OrProfileBytes:
  LD A,(HL)               ; six bytes ORed
OrProfileLoop:
  INC HL
  OR (HL)
  DJNZ OrProfileLoop
  LD E,$47                ; no wall: the track's full width
  RLA
  JR NC,CheckWall27
  LD E,$17                ; bit 7 wall: limit $17
  LD A,C
  AND A                   ; already beside that wall: only limited
  JR Z,SteerAcross
WallCrash:
  LD A,($C003)            ; past the limit: the player crashes into the wall
  CP E
  JR C,SteerAcross
  LD HL,PlayerRecord
  SET 5,(HL)              ; hit
  XOR A
  LD (PlayerRecord+$0006),A
  LD A,$1E                ; the explosion counter
  LD (PlayerRecord+$0008),A
  LD HL,(PlayerRecord+$0001) ; back 2 along
  LD BC,$FFFE
  ADD HL,BC
  LD (PlayerRecord+$0001),HL
  LD HL,SoundRequests     ; sound request bit 1
  SET 1,(HL)
  XOR A                   ; the convoy is lost
  LD (Followers),A
  LD DE,ConvoyLinks+$0009 ; every follower in the links is hit
  LD B,$04
FollowerCrashLoop:
  LD A,(DE)
  DEC DE
  CP $FF
  JR Z,NextFollowerCrash
  LD H,A
  LD A,(DE)
  LD L,A
  DEC L
  DEC L
  DEC L
  SET 5,(HL)
  LD A,$06
  ADD A,L
  LD L,A
  LD (HL),$00
  INC L
  INC L
  LD (HL),$22
NextFollowerCrash:
  DEC DE
  DJNZ FollowerCrashLoop
  LD E,$47
  JR SteerAcross
CheckWall27:
  RLA                     ; bit 6 wall: limit $27
  JR NC,SteerAcross
  LD E,$27
  LD A,C
  CP $02
  JR Z,WallCrash
SteerAcross:
  LD A,(ControlByte)      ; left and right
  LD B,A
  XOR A
  BIT 0,B                 ; left: the counter $E689 grows to 6
  JR Z,StoreLeftCount
  LD A,(LeftHeldCount)
  CP $06
  JR NC,StoreLeftCount
  INC A
StoreLeftCount:
  LD (LeftHeldCount),A
  INC A                   ; step 2 * ((counter + 1) / 2)
  SRL A
  ADD A,A
  LD C,A
  LD A,($C003)            ; left raises the position across, below the limit E
  ADD A,C
  CP E
  JR C,StoreLeftAcross
  LD A,E
  DEC A
StoreLeftAcross:
  LD (PlayerRecord+$0003),A
  XOR A
  BIT 1,B                 ; right: the counter $E68A
  JR Z,StoreRightCount
  LD A,(RightHeldCount)
  CP $06
  JR NC,StoreRightCount
  INC A
StoreRightCount:
  LD (RightHeldCount),A
  INC A
  SRL A
  ADD A,A
  LD C,A
  LD A,($C003)            ; right lowers it, not below 2
  SUB C
  CP $02
  JR C,AcrossFloor
  CP E
  JR C,StoreRightAcross
AcrossFloor:
  LD A,$02
StoreRightAcross:
  LD (PlayerRecord+$0003),A
  RET

; The random number generator
;
; Returns a new 16-bit value in HL and keeps it in the seed $EA36: about 254 *
; (seed + 1) mod 65537, done with three subtractions instead of a multiply
; (checked by simulating the code over all seeds: 126 of 65 536 differ). The
; menu bumps the seed every pass of its loop ($F20B), so the player's time in
; the menu picks the sequence. Called by the game start (the demo's course,
; $CF56) and the mover ($E16E). docs/05-controls.md 5.1.
Random:
  LD DE,(RandomSeed)
  LD H,E
  LD L,$FD
  LD A,D
  OR A
  SBC HL,DE
  SBC A,$00
  SBC HL,DE
  SBC A,$00
  LD E,A
  LD D,$00
  SBC HL,DE
  JR NC,StoreSeed
  INC HL
StoreSeed:
  LD (RandomSeed),HL
  RET

; The random seed
;
; The state of $EA19, incremented by every pass of the menu loop.
RandomSeed:
  DEFW $0D05
