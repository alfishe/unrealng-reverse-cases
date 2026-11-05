; --------------------------------------------------------------------------------------------------------------------
; movers.asm: the frame's object loop, the path interpreter and its movement commands
;
; RunObjects is the object half of a frame: the player's handler, then the 15 slots from $F600 down to $F398 (the
; sight, the two side-weapon slots, the four laser shots, the eight enemy slots), each active one through the handler
; table $80FA by its kind (+$07): 0 PlayerHandler, 1 LaserHandler, 2 and 11 EnemyHandler, 3 $A1C8, 4 $A1FD (the pod),
; 5 $A263, 6 SightHandler, 7 SeekerHandler, 8 LockableHandler, 9 PlasmaHandler, 10 MissileHandler, 12 BigEnemyHandler.
;
; The in-game engine sound is made here: after each slot $7F86 is XORed with $18 and ANDed with the enable mask $7F87,
; then OUT ($FE): the speaker (bit 4) and the MIC (bit 3) flip 15 times a frame, a buzz whose pitch follows the time
; the handlers take; the border stays black (bits 0-2 are 0). When fewer than 8 slots are active the loop pads with (C
; - 7) x 128 DJNZ turns so the frame time, and the buzz, stay even.
;
; The enemies move by a path bytecode (RunPath, kept in each record: +$1D/+$1E the pointer, +$1C the command, +$1B the
; frames left). A byte with bit 7 set gives the repeat count (b & $7F, 0 = forever) of the command byte after it;
; without it a command runs one frame. Bits 0-2 of a command pick the routine from $8114, bits 3-6 are its parameter
; (P): 0 PathOpAccelerate (P = the acceleration flags), 1 PathOpSetLoop, 2 PathOpSetInterval, 3 PathOpBounce, 4
; PathOpHomePlayer, 5 PathOpSetDirection, 6 PathOpHomeTarget, 7 PathOpExtended, whose P picks one of 16 routines from
; $8124 (0 PathOpScroll, 1 PathOpStop, 2 PathOpRandomDirection, 3 PathOpLoop, 4 PathOpDriftMiddle, 5 PathOpAimPlayer,
; 6 PathOpScrollAlways, 7 PathOpMove, 8 PathOpHome, 9 PathOpToCentre, 10 PathOpLand, 11 PathOpRandomSpeed, 12
; PathOpBounceArena, 13 PathOpDive, 14 PathOpMoveFragile, 15 PathOpWait).
;
; A routine that returns carry is an instant command (a setting): the interpreter goes on to the next command in the
; same frame; NC ends the object's commands for this frame. The coordinates are 8.8: X (+3/+4) in columns of the
; playfield (16-47 on the screen), Y (+5/+6) in rows 0-15; the velocities +$0E/+$0F (X) and +$12/+$13 (Y) are added
; each move, the accelerations +$10/+$11 and +$14/+$15 to the velocities; +$16 is the direction 0-63 (SetVelocity),
; +$17 the speed.
; --------------------------------------------------------------------------------------------------------------------

; run every active object's handler, with the engine buzz
;
; Called once a frame from $AA96 (659 entries in c2, 5.7 % of play's time
; without the handlers). The landing flag $974C is freed (bit 7), the player
; ($F36C) runs by its kind, then the 15 slots from $F600 down in steps of -44
; (DE = $FFD4); C counts the slots not active.
;
; After the loop the per-frame hit masks are cleared: $80BB (lasers and
; player), $80E3 (the homing missile), $80E4 (the sight), $80E5 (plasma and
; seeker), the player's +$0D ($F379) and the +$0D of the 7 records from $F4F8
; (lasers, side weapons, sight; $F505 on).
RunObjects:
  LD HL,LandingFlag
  RES 7,(HL)
  LD IY,PlayerObject
  LD A,(IY+$07)
  LD HL,KindHandlers
  CALL JumpTable
  LD IY,SightObject
  LD B,$0F
  LD C,B
RunObjectsLoop:
  BIT 7,(IY+$08)          ; active? run its handler by +$07
  JR Z,RunObjectsNext
  DEC C
  PUSH BC
  LD A,(IY+$07)
  LD HL,KindHandlers
  CALL JumpTable
  POP BC
RunObjectsNext:
  LD DE,-$002C            ; the next slot down, and the speaker click
  ADD IY,DE
  LD HL,SlotBeep          ; the beeper: $7F86 ^= $18, AND the enable mask
                          ; $7F87, OUT ($FE)
  LD A,(HL)
  XOR $18
  LD (HL),A
  INC HL
  AND (HL)
  OUT ($FE),A
  DJNZ RunObjectsLoop
  LD A,C                  ; 8 or more slots idle: pad the frame
  CP $08
  JR C,RunObjectsClear
  SUB $07
RunObjectsPad:
  LD B,$80                ; (C - 7) x 128 DJNZ turns
RunObjectsPadLoop:
  DJNZ RunObjectsPadLoop  ; the delay loop
  DEC A
  JR NZ,RunObjectsPad
RunObjectsClear:
  XOR A                   ; clear the frame's hit masks
  LD (LaserHitMask),A
  LD (MissileHitMask),A
  LD (SightMask),A
  LD (PlasmaHitMask),A
  LD (PlayerHitMask),A
  LD HL,LaserShots+$000D
  LD DE,$002C
  LD B,$07
RunObjectsClearMasks:
  LD (HL),A               ; +$0D of the 7 records from $F4F8
  ADD HL,DE
  DJNZ RunObjectsClearMasks
  RET

; run the path bytecode of the object IY for one frame
;
; Frames left +$1B - 1: 0 fetches the next command; a count that was already 0
; (forever) stays 0. The command +$1C goes to JumpTable($8114) with C = the
; command: carry from the routine runs RunPath again (the next command in the
; same frame), NC ends it. Called by EnemyHandler, LockableHandler and
; BigEnemyHandler (1405 entries in c2).
RunPath:
  DEC (IY+$1B)
  JR Z,RunPathFetch
  JP P,RunPathCommand
  INC (IY+$1B)
RunPathCommand:
  LD A,(IY+$1C)           ; the current command
RunPathDispatch:
  LD C,A                  ; bits 0-2: the routine from $8114
  AND $07
  LD HL,PathOps
  CALL JumpTable
  RET NC
  JP RunPath
RunPathFetch:
  LD (IY+$1B),$01         ; one frame unless a count byte comes
  LD L,(IY+$1D)
  LD H,(IY+$1E)
RunPathFetchLoop:
  LD A,(HL)               ; bit 7: a repeat count
  INC HL
  AND A
  JP P,RunPathStore
  AND $7F
  LD (IY+$1B),A
  JR RunPathFetchLoop
RunPathStore:
  LD (IY+$1C),A           ; the command and the new pointer
  LD (IY+$1D),L
  LD (IY+$1E),H
  JP RunPathDispatch

; command 7: bits 3-6 pick one of 16 routines from $8124
;
; 1151 executions in c2.
PathOpExtended:
  LD A,C
  AND $78
  RRCA
  RRCA
  RRCA
  LD HL,PathExtOps
  CALL JumpTable
  RET

; DE = the next word of the path
;
; Used by PathOpLoop for its jump target. Not run in c1/c2; r1 (all levels)
; runs it: 180 entries.
PathReadWord:
  PUSH HL
  LD L,(IY+$1D)
  LD H,(IY+$1E)
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (IY+$1D),L
  LD (IY+$1E),H
  POP HL
  RET

; command 0: accelerate by the flags in C, then move
;
; C bit 3: Vx += Ax; bit 4: Vx -= Ax; bit 5: Vy += Ay; bit 6: Vy -= Ay. Then X
; += Vx, Y += Vy; NC. Also the plain move of the player (C from the joystick),
; PathOpBounce, PathOpDriftMiddle, PathOpToCentre and PlasmaHandler (C = $20,
; gravity). 1918 executions in c2.
PathOpAccelerate:
  LD L,(IY+$0E)
  LD H,(IY+$0F)
  BIT 3,C
  JR Z,PathAccelXDown
  LD E,(IY+$10)
  LD D,(IY+$11)
  ADD HL,DE
  JR PathAccelXStore
PathAccelXDown:
  BIT 4,C                 ; bit 4: Vx - Ax
  JR Z,PathMoveX
  LD E,(IY+$10)
  LD D,(IY+$11)
  AND A
  SBC HL,DE
PathAccelXStore:
  LD (IY+$0E),L           ; the new Vx
  LD (IY+$0F),H
PathMoveX:
  LD E,(IY+$03)           ; X + Vx
  LD D,(IY+$04)
  ADD HL,DE
  LD (IY+$03),L
  LD (IY+$04),H
  LD L,(IY+$12)
  LD H,(IY+$13)
  BIT 5,C
  JR Z,PathAccelYDown
  LD E,(IY+$14)
  LD D,(IY+$15)
  ADD HL,DE
  JR PathAccelYStore
PathAccelYDown:
  BIT 6,C                 ; bit 6: Vy - Ay
  JR Z,PathMoveY
  LD E,(IY+$14)
  LD D,(IY+$15)
  AND A
  SBC HL,DE
PathAccelYStore:
  LD (IY+$12),L           ; the new Vy
  LD (IY+$13),H
PathMoveY:
  LD E,(IY+$05)           ; Y + Vy; NC
  LD D,(IY+$06)
  ADD HL,DE
  LD (IY+$05),L
  LD (IY+$06),H
  AND A
  RET

; command 1: the loop counter +$1F = P
;
; Carry: an instant command. Not run in c1/c2; r1 (all levels) runs it.
PathOpSetLoop:
  LD A,C
  AND $78
  RRCA
  RRCA
  RRCA
  LD (IY+$1F),A
  SCF
  RET

; command 2: the homing interval +$27 = +$28 = P
;
; Carry. Not run in c1/c2; r1 (all levels) runs it.
PathOpSetInterval:
  LD A,C
  AND $78
  RRCA
  RRCA
  RRCA
  LD (IY+$27),A
  LD (IY+$28),A
  SCF
  RET

; command 3: move, bouncing off the scenery
;
; With scenery under the object (SceneryAt6): only X moves. Else Y moves with
; the Y acceleration added (C = $20, a fall); if that lands it on the scenery
; or below row 15 the move is undone and Vy reversed (a bounce). NC. Not run in
; c1/c2; r1 (all levels) runs it.
PathOpBounce:
  CALL SceneryAt6
  JR NC,PathBounceY
  LD L,(IY+$03)
  LD H,(IY+$04)
  LD E,(IY+$0E)
  LD D,(IY+$0F)
  ADD HL,DE
  LD (IY+$03),L
  LD (IY+$04),H
  AND A
  RET
PathBounceY:
  LD L,(IY+$05)           ; free: fall by Vy + Ay
  LD H,(IY+$06)
  LD E,(IY+$12)
  LD D,(IY+$13)
  PUSH HL
  PUSH DE
  LD C,$20
  CALL PathOpAccelerate
  LD A,(IY+$06)
  CP $10
  CCF
  JR C,PathBounceTest
  CALL SceneryAt6
PathBounceTest:
  POP DE                  ; hit: Y back, Vy = -Vy
  POP BC
  LD A,$00
  RET NC
  LD HL,$0000
  AND A
  SBC HL,DE
  LD (IY+$12),L
  LD (IY+$13),H
  ADD HL,BC
  LD (IY+$05),L
  LD (IY+$06),H
  AND A
  RET

; command 4: home on the player, turn rate P
;
; The target +$29/+$2A = the player $F36C, the turn rate +$2B = P, then
; PathOpHome. NC. Not run in c1/c2; r1 (all levels) runs it: 1 entries.
PathOpHomePlayer:
  LD HL,PlayerObject
  LD (IY+$29),L
  LD (IY+$2A),H

; PathHomeSetRate
;
; Used by the routine at PathOpHomeTarget.
PathHomeSetRate:
  LD A,C                  ; +$2B = P, one homing step
  AND $78
  RRCA
  RRCA
  RRCA
  LD (IY+$2B),A
  CALL PathOpHome
  AND A
  RET

; command 5: direction (C & $78) / 2, then move
;
; +$16 = P x 4 (0-60), velocities from the speed +$17 (SetVelocity), one move;
; NC. 20 executions in c2.
PathOpSetDirection:
  LD A,C
  AND $78
  RRCA
  LD (IY+$16),A
  LD B,(IY+$17)
  CALL SetVelocity
  CALL PathOpMove
  AND A
  RET

; command 6: home on the target, the player once it is gone
;
; The target record +$29: no longer active, or of kind 3, makes it
; PathOpHomePlayer; else turn rate P and PathOpHome. Not run in c1/c2; r1 (all
; levels) runs it.
PathOpHomeTarget:
  LD L,(IY+$29)
  LD H,(IY+$2A)
  PUSH HL
  POP IX
  BIT 7,(IX+$08)
  JP Z,PathOpHomePlayer
  LD A,(IX+$07)
  CP $03
  JP Z,PathOpHomePlayer
  JP PathHomeSetRate

; extended 0: move with the landscape when it scrolls
;
; Bit 0 of $7F6C set (a frame the playfield scrolls one step): X - $40 (a
; quarter column); NC. 251 executions in c2: the ground objects.
PathOpScroll:
  LD HL,ScrollThisPass
  BIT 0,(HL)
  RET Z
  LD L,(IY+$03)
  LD H,(IY+$04)
  LD DE,-$0040
  ADD HL,DE
  LD (IY+$03),L
  LD (IY+$04),H
  AND A
  RET

; extended 1: stop
;
; Vx = Vy = 0; the flags of XOR A: NC. Not run in c1/c2.
PathOpStop:
  XOR A
  LD (IY+$0E),A
  LD (IY+$0F),A
  LD (IY+$12),A
  LD (IY+$13),A
  RET

; extended 2: a random direction, then move
;
; +$16 = random & $3F, the velocities for the speed +$17, one move; NC. Not run
; in c1/c2; r1 (all levels) runs it.
PathOpRandomDirection:
  CALL Random
  AND $3F
  LD (IY+$16),A
  LD B,(IY+$17)
  CALL SetVelocity
  CALL PathOpMove
  AND A
  RET

; extended 3: loop back to the word target while +$1F counts down
;
; Reads the target word; +$1F - 1: not 0 = the path pointer goes to the target;
; carry either way (the next command runs at once). Not run in c1/c2; r1 (all
; levels) runs it.
PathOpLoop:
  CALL PathReadWord
  DEC (IY+$1F)
  SCF
  RET Z
  LD (IY+$1D),E
  LD (IY+$1E),D
  SCF
  RET

; extended 4: accelerate towards row 8
;
; Above row 8: C = $20 (Vy + Ay), else $40 (Vy - Ay); PathOpAccelerate; NC.
; 1071 executions in c2.
PathOpDriftMiddle:
  LD A,(IY+$06)
  CP $08
  LD C,$20
  JR C,PathDriftMove
  LD C,$40
PathDriftMove:
  CALL PathOpAccelerate   ; accelerate and move
  AND A
  RET

; extended 5: the direction to the player
;
; +$16 = DirectionTo the player, velocities for the speed; carry. Not run in
; c1/c2; r1 (all levels) runs it.
PathOpAimPlayer:
  LD IX,PlayerObject
  CALL DirectionTo
  LD B,(IY+$17)
  CALL SetVelocity
  SCF
  RET

; extended 7: X += Vx, Y += Vy
;
; NC. Also the move of SetDirection, RandomDirection, PathOpHome and
; MoveFragile. 38 executions in c2.
PathOpMove:
  LD L,(IY+$03)
  LD H,(IY+$04)
  LD E,(IY+$0E)
  LD D,(IY+$0F)
  ADD HL,DE
  LD (IY+$03),L
  LD (IY+$04),H
  LD L,(IY+$05)
  LD H,(IY+$06)
  LD E,(IY+$12)
  LD D,(IY+$13)
  ADD HL,DE
  LD (IY+$05),L
  LD (IY+$06),H
  AND A
  RET

; extended 6: X - $40 every frame
;
; NC. Not run in c1/c2.
PathOpScrollAlways:
  LD L,(IY+$03)
  LD H,(IY+$04)
  LD DE,-$0040
  ADD HL,DE
  LD (IY+$03),L
  LD (IY+$04),H
  AND A
  RET

; extended 8: turn towards the target, then move
;
; Every +$28 frames (+$27 counts down): the direction to the target (+$29/+$2A)
; by DirectionTo; a difference up to the turn rate +$2B is taken at once, else
; the direction turns by +$2B the shorter way round (mod 64), and SetVelocity
; for the speed +$17. Then PathOpMove; NC. 18 executions in c2; the homing
; missile and the seeker use it too.
PathOpHome:
  DEC (IY+$27)
  JR NZ,PathHomeMove
  LD A,(IY+$28)
  LD (IY+$27),A
  LD L,(IY+$29)
  LD H,(IY+$2A)
  PUSH HL
  POP IX
  CALL DirectionTo
  LD E,A
  LD D,(IY+$2B)
  SUB (IY+$16)
  JR Z,PathHomeMove
  LD C,A
  JP P,PathHomeCompare
  NEG
PathHomeCompare:
  CP D                    ; |difference| within the turn rate?
  JR NC,PathHomeTurn
  LD A,E
  JR PathHomeSetDirection
PathHomeTurn:
  LD A,C                  ; the shorter way: left or right
  NEG
  AND $3F
  CP $20
  LD A,(IY+$16)
  JR NC,PathHomeTurnRight
  SUB D
  JR PathHomeWrap
PathHomeTurnRight:
  ADD A,D                 ; + the turn rate
PathHomeWrap:
  AND $3F                 ; mod 64
PathHomeSetDirection:
  LD (IY+$16),A           ; the new direction and velocities
  LD B,(IY+$17)
  CALL SetVelocity
PathHomeMove:
  CALL PathOpMove         ; one move
  AND A
  RET

; extended 9: accelerate towards column 32 and row 8
;
; X below 32: C = 8 (Vx + Ax), else $10; Y below 8: $20, else $40;
; PathOpAccelerate; NC. Not run in c1/c2; r1 (all levels) runs it.
PathOpToCentre:
  LD A,(IY+$04)
  CP $20
  LD C,$08
  JR C,PathToCentreY
  LD C,$10
PathToCentreY:
  LD A,(IY+$06)           ; the Y flag
  CP $08
  LD A,C
  LD C,$20
  JR C,PathToCentreMove
  LD C,$40
PathToCentreMove:
  OR C                    ; accelerate and move
  LD C,A
  CALL PathOpAccelerate
  AND A
  RET

; PathOpLand's per-frame flag and retry count
;
; Bit 7: an object has used PathOpLand in this frame (RunObjects clears it each
; frame); bits 0-6: the failed tries since the last landing.
LandingFlag:
  DEFB $00

; extended 10: put the object on the ground below it
;
; One object a frame (bit 7 of LandingFlag). After 8 failed tries in a row, or
; when another object landed this frame, it is parked at X = 0, Y = 0 (off the
; playfield, it leaves). Else Y fraction = $E0, Y goes down out of any scenery,
; then on down to the first row with all 4 cells under it filled: Y one up
; there, the repeat count 1, the tries reset; a row that is filled only in part
; parks it. NC. 1 execution in c2.
PathOpLand:
  LD HL,LandingFlag
  BIT 7,(HL)
  JR NZ,PathLandPark
  LD A,(HL)
  LD (HL),$80
  INC A
  CP $08
  JR Z,PathLandPark
  OR $80
  LD (HL),A
  LD (IY+$05),$E0
PathLandRise:
  LD A,(IY+$06)           ; out of the scenery first
  CP $0F
  JR Z,PathLandParkY
  CALL SceneryAt6
  JR NC,PathLandFall
  INC (IY+$06)
  JR PathLandRise
PathLandFall:
  LD A,(IY+$06)           ; down a row: the 4 cells below
  CP $0F
  JR Z,PathLandParkY
  INC (IY+$06)
  CALL SceneryCell
  INC H
  DEC L
  XOR A
  LD C,A
  CP (HL)
  RL C
  INC L
  CP (HL)
  RL C
  INC L
  CP (HL)
  RL C
  INC L
  CP (HL)
  RL C
  OR C
  JR Z,PathLandFall
  CP $0F
  JR NZ,PathLandParkY
  DEC (IY+$06)
  LD (IY+$1B),$01
  LD HL,LandingFlag
  LD (HL),$80
  AND A
  RET
PathLandPark:
  LD (IY+$04),$00         ; X = 0: off the playfield
PathLandParkY:
  LD (IY+$06),$00         ; Y = 0
  AND A
  RET

; extended 11: the speed +$17 one up or down at random
;
; A random byte below $55 keeps it, below $AA + 1, else - 1; kept in 1-7 (0
; refused). Carry. Not run in c1/c2; r1 (all levels) runs it.
PathOpRandomSpeed:
  CALL Random
  CP $55
  RET C
  CP $AA
  LD A,$01
  JR C,PathRandomSpeedSet
  NEG
PathRandomSpeedSet:
  ADD A,(IY+$17)          ; a new speed of 0 is refused
  AND $07
  JR Z,PathRandomSpeedDone
  LD (IY+$17),A
PathRandomSpeedDone:
  SCF                     ; carry: instant
  RET

; extended 12: move, bouncing off the scenery and the edges
;
; X + Vx: outside columns 16-45 or on scenery: X back, Vx = -Vx. Y + Vy: Y 17
; or more (also a negative Y) or on scenery: Y back, Vy = -Vy. NC. Not run in
; c1/c2; r1 (all levels) runs it.
PathOpBounceArena:
  LD L,(IY+$03)
  LD H,(IY+$04)
  LD E,L
  LD D,H
  LD C,(IY+$0E)
  LD B,(IY+$0F)
  ADD HL,BC
  LD (IY+$03),L
  LD (IY+$04),H
  LD A,H
  SUB $10
  CP $1E
  JR NC,PathArenaFlipX
  EXX
  CALL SceneryAt6
  EXX
  JR NC,PathArenaMoveY
PathArenaFlipX:
  LD HL,$0000             ; X back, Vx reversed
  AND A
  SBC HL,BC
  LD (IY+$0E),L
  LD (IY+$0F),H
  LD (IY+$03),E
  LD (IY+$04),D
PathArenaMoveY:
  LD L,(IY+$05)           ; Y + Vy
  LD H,(IY+$06)
  LD E,L
  LD D,H
  LD C,(IY+$12)
  LD B,(IY+$13)
  ADD HL,BC
  LD (IY+$05),L
  LD (IY+$06),H
  LD A,H
  CP $11
  JR NC,PathArenaFlipY
  EXX
  CALL SceneryAt6
  EXX
  JR NC,PathArenaDone
PathArenaFlipY:
  LD HL,$0000             ; Y back, Vy reversed
  AND A
  SBC HL,BC
  LD (IY+$12),L
  LD (IY+$13),H
  LD (IY+$05),E
  LD (IY+$06),D
PathArenaDone:
  AND A                   ; NC
  RET

; extended 13: scroll along, dive at the player when close
;
; PathOpScroll, then, once its column is no more than the player's plus half
; the row distance between them and a random byte is below 200: one frame of Vy
; = -$80, Vx = -$40 (a dive up and back). Else on scenery: SelfDestruct. Not
; run in c1/c2; r1 (all levels) runs it.
PathOpDive:
  CALL PathOpScroll
  LD IX,PlayerObject
  LD A,(IY+$06)
  SUB (IX+$06)
  SRA A
  ADD A,(IX+$04)
  SUB (IY+$04)
  JP M,PathDiveTest
  CALL Random             ; a random byte below 200 (78 %) dives
  CP $C8
  JR NC,PathDiveTest
  LD (IY+$1B),$01
  LD (IY+$12),$80
  LD (IY+$13),$FF
  LD (IY+$0E),$C0
  LD (IY+$0F),$FF
  RET
PathDiveTest:
  CALL SceneryAt6         ; on the scenery?
  RET NC
  CALL SelfDestruct
  AND A
  RET

; extended 14: move; destroyed on scenery or leaving the playfield
;
; PathOpMove; Y 17 or more, X outside 16-46, or scenery under it: SelfDestruct.
; NC. Not run in c1/c2; r1 (all levels) runs it.
PathOpMoveFragile:
  CALL PathOpMove
  LD A,(IY+$06)
  CP $11
  JR NC,PathFragileDestroy
  LD A,(IY+$04)
  SUB $10
  CP $1F
  JR NC,PathFragileDestroy
  CALL SceneryAt6
  RET NC
PathFragileDestroy:
  CALL SelfDestruct       ; out or hit
  AND A
  RET

; extended 15: do nothing this frame
;
; NC. Not run in c1/c2; r1 (all levels) runs it.
PathOpWait:
  AND A
  RET

; mark the object as hit by the player's laser
;
; +$0D = 1 (one hit point) and its bit (+$24) into $80BB: the enemy handler's
; laser test kills it this frame. Not run in c1/c2; r1 (all levels) runs it: 36
; entries.
SelfDestruct:
  LD (IY+$0D),$01
  LD HL,LaserHitMask
  LD A,(HL)
  OR (IY+$24)
  LD (HL),A
  RET

; A = the direction 0-63 from the object IY to IX
;
; The rounded column and row distances; their signs pick the octant, the ratio
; of the smaller to the larger (by subtraction in 8 steps) the direction inside
; it. Used by PathOpAimPlayer, PathOpHome and $A0EB. Not run in c1/c2; r1 (all
; levels) runs it: 1431 entries: the homing interval of the objects there never
; ran out.
DirectionTo:
  LD A,(IX+$03)
  RLA
  LD A,(IX+$04)
  ADC A,$00
  SUB (IY+$04)
  LD C,A
  LD A,(IX+$05)
  RLA
  LD A,(IX+$06)
  ADC A,$00
  SUB (IY+$06)
  LD B,A
  LD D,$00
  LD A,B
  AND A
  JP P,DirectionToX
  NEG
  LD B,A
  LD D,$3F
DirectionToX:
  LD A,C                  ; the column distance's sign
  AND A
  JP P,DirectionToOctant
  NEG
  LD C,A
  LD A,D
  XOR $1F
  LD D,A
  LD A,C
DirectionToOctant:
  CP B                    ; swap so the larger distance divides
  JR NC,DirectionToDivide
  LD C,B
  LD B,A
  LD A,D
  XOR $0F
  LD D,A
DirectionToDivide:
  LD E,$08                ; the ratio in 8 steps
  SLA B
  SLA B
  SLA B
  LD A,C
  ADD A,A
  ADD A,A
  ADD A,A
DirectionToLoop:
  DEC E                   ; one step
  JR Z,DirectionToDone
  SUB C
  CP B
  JR NC,DirectionToLoop
DirectionToDone:
  LD A,E                  ; the step XOR the octant
  XOR D
  RET

; the velocities for direction A and speed B
;
; Vx = B x sine[A] and Vy = B x sine[(A - 16) & $3F] with the 64-entry signed
; sine table $8144 (B additions, so B is 1-7 in practice). 21 entries in c2.
SetVelocity:
  LD C,B
  PUSH AF
  LD HL,SineTable
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  LD E,A
  RLA
  SBC A,A
  LD D,A
  LD HL,$0000
SetVelocityXLoop:
  ADD HL,DE               ; Vx = speed x sine
  DJNZ SetVelocityXLoop
  LD (IY+$0E),L
  LD (IY+$0F),H
  LD B,C
  POP AF
  SUB $10
  AND $3F
  LD HL,SineTable
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  LD E,A
  RLA
  SBC A,A
  LD D,A
  LD HL,$0000
SetVelocityYLoop:
  ADD HL,DE               ; Vy = speed x the sine a quarter turn back
  DJNZ SetVelocityYLoop
  LD (IY+$12),L
  LD (IY+$13),H
  RET
