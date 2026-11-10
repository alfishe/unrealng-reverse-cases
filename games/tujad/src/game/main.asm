; --------------------------------------------------------------------------------------------------------------------
; main.asm: The start, the main loop, the hazard, the win and the life lost
;
; Setup puts the stack under the game block, selects the keyboard and installs the IM 2 handler. Restart shows the
; menu and starts a game. MainLoop is one pass of the game with two HALTs (WaitFrame $795D): the droid and its exhaust
; between the first and the second, the objects, enemies and patrollers after the second. The interrupt handler $95D0
; draws the sprite list each frame, so a pass takes two frames when its work fits (and a third when it does not).
; --------------------------------------------------------------------------------------------------------------------

; Power-on setup: the stack, the keyboard, the IM 2 handler
;
; DI; SP = $60C0 (the stack grows down under the cell table, in the BASIC
; area); Controls = $80 (the keyboard); SetupIM2 $9584. Runs once (c1 L1 1).
Setup:
  DI
  LD HL,CellTable
  LD SP,HL
  LD A,$80
  LD (Controls),A
  CALL SetupIM2

; The menu, then a new game
;
; ClearScreen $7A9F, Menu $8854 (waits for 1-4 / ENTER), NewGame $7A2F, the
; message TUJAD FROM ORPHEUS, EI, then MainLoop. Entered at the start and after
; a win ($6A2D) or a game over ($6AAA). L1 4 (c1 and the menu builds).
Restart:
  DI
  CALL ClearScreen
  CALL Menu
  CALL NewGame
  LD HL,Messages
  CALL QueueMessage
  EI

; One pass of the game: two frames
;
; WaitFrame (the sprites of the last half pass are drawn), PassTick $7F6D (a
; sound tick), DroidExhaust $8DD2 (erase), MoveDroid $7208, ExhaustStep $8E7E,
; DroidExhaust (draw), HazardFlash $699B, MoveShot $8298; WaitFrame; MoveObject
; $809D for both objects; MoveEnemy $90E7 for the four enemies, each with its
; pair of EnemyBuffers; MovePatrollers $6AAD; MoveShot again; Pause $793A
; (ENTER); EnergyOut $6A30; WinTest $69E3; again.
;
; Witness: L1 18 585 passes. Most passes take exactly two frames (the two
; HALTs); a pass whose work between the HALTs runs past the next interrupt
; misses it and waits for the one after, so it takes three. The rare one-frame
; pass is a WaitFrame whose HALT is entered just before an interrupt that the
; last half pass left pending (Open point 3 in work/stage2/NOTES.md).
MainLoop:
  CALL WaitFrame
  CALL PassTick
  CALL DroidExhaust
  CALL MoveDroid
  CALL ExhaustStep
  CALL DroidExhaust
  CALL HazardFlash
  CALL MoveShot
MainLoopSecondHalf:
  CALL WaitFrame          ; the second WaitFrame: the objects, the enemies and
                          ; the patrollers follow
  LD HL,Objects
  CALL MoveObject
  LD HL,Object2
  CALL MoveObject
  LD HL,EnemyBuffers
  LD (EnemyBufferPtrs+$0002),HL
  LD HL,EnemyBuffer1B
  LD (EnemyBufferPtrs),HL
  LD HL,Enemies
  CALL MoveEnemy
  LD HL,EnemyBuffer2A
  LD (EnemyBufferPtrs+$0002),HL
  LD HL,EnemyBuffer2B
  LD (EnemyBufferPtrs),HL
  LD HL,Enemy2
  CALL MoveEnemy
  LD HL,EnemyBuffer3A
  LD (EnemyBufferPtrs+$0002),HL
  LD HL,EnemyBuffer3B
  LD (EnemyBufferPtrs),HL
  LD HL,Enemy3
  CALL MoveEnemy
  LD HL,EnemyBuffer4A
  LD (EnemyBufferPtrs+$0002),HL
  LD HL,EnemyBuffer4B
  LD (EnemyBufferPtrs),HL
  LD HL,Enemy4
  CALL MoveEnemy
  CALL MovePatrollers
  CALL MoveShot
  CALL Pause
  CALL EnergyOut
  CALL WinTest
  JP MainLoop

; A touched hazard: the life ends unless the droid is turning round
;
; Reached from MoveDroid's touch test ($75E1) when a cell under the droid has a
; mark other than an enemy's (a patroller or an object: bits 2-6). DroidFlags
; bit 1 (turning) protects; otherwise LoseLife. L1 53.
HazardDeath:
  LD A,(DroidFlags)
  BIT 1,A
  RET NZ
  JP LoseLife

; While touching an enemy: flash the droid's attributes and click the beeper
;
; Only while DroidFlags bit 4 (an enemy touched, the energy drains fast) is
; set: fills the droid's 5 attribute rows with DeathColour (2-7, cycling) +
; FLASH, toggling the beeper bit (port $FE) each row. L1 18 574 calls, 104
; flashes.
HazardFlash:
  LD HL,DroidFlags
  BIT 4,(HL)
  RET Z
  LD BC,(DroidVars)
  CALL ScreenAddr
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD DE,$0020
  LD A,(DroidWidth)
  LD C,A
  LD A,(DeathColour)
  INC A
  CP $08
  JR NZ,HazardFlashColour
  LD A,$02
HazardFlashColour:
  LD (DeathColour),A
  OR $40
  LD B,$05
HazardFlashRow:
  PUSH BC
  PUSH HL
  LD B,C
HazardFlashCell:
  LD (HL),A
  INC L
  DJNZ HazardFlashCell
  PUSH AF
  LD A,(BorderSound)
  OUT ($FE),A
  XOR $10
  LD (BorderSound),A
  POP AF
  POP HL
  ADD HL,DE
  POP BC
  DJNZ HazardFlashRow
  RET

; Every ED piece taken: EDS COMPLETED; back in room $54: the end
;
; All ten EdFlags bytes $1F (L1 18 581 tests): the eleventh byte (EdFlagsEnd)
; is set to $1F once and the message EDS COMPLETED queued. Then in room $54
; (the control room, where the game starts): the scroller's row is cleared,
; CONGRATULATIONS queued, EnergyTimer and ScrollPriority zeroed, a delay
; (WinDelay, BC = $FDE8), ProgressScreen with A = 0 (the whole picture), 512
; HALTs (WinWait: B = 0, C = 2; about 10 s) and Restart. Witness: the RZX log
; (work/stage1/rzx/frames.bin) queues EDS COMPLETED at RZX frame 71 845 in room
; 28 (ScrollNext $63E8, priority 10), enters room 84 at 79 916 and runs
; WinTestRoom at 79 947 (ScrollNext $64C7, priority 20, EnergyTimer 0); the win
; recording starts inside WinWait ($6A26: 495 HALTs, then Restart, Menu at its
; frame 497). $69FF-$6A25 ran only in the RZX playback, which no L1 build
; holds.
WinTest:
  LD HL,EdFlags
  LD A,$1F
  LD B,$0A
WinTestLoop:
  CP (HL)
  INC HL
  RET NZ
  DJNZ WinTestLoop
  CP (HL)
  JR Z,WinTestRoom
  LD (HL),A
  LD HL,MsgEdsCompleted
  CALL QueueMessage
WinTestRoom:
  LD A,(Room)
  CP $54
  RET NZ
  LD HL,Attributes+133
  LD B,$05
WinClearRow:
  LD (HL),$00
  INC L
  DJNZ WinClearRow
  XOR A
  LD (EnergyTimer),A
  LD (ScrollPriority),A
  LD HL,MsgCongratulations
  CALL QueueMessage
  LD BC,$FDE8
WinDelay:
  DEC BC
  LD A,B
  OR C
  JR NZ,WinDelay
  XOR A
  CALL ProgressScreen
  EI
  LD BC,$0002
WinWait:
  HALT
  DJNZ WinWait
  DEC C
  JR NZ,WinWait
  POP BC
  JP Restart

; Energy 0 and not turning: a life lost
;
; L1 18 582 tests, 2 with energy 0 (energy-out).
EnergyOut:
  LD A,(Energy)
  CP $00
  RET NZ
  LD A,(DroidFlags)
  BIT 1,A
  RET NZ

; A life ends: the death effect, the droid placed again, or the game over
;
; Energy back to 99 and the timers to $FA; Lives - 1 (BCD); GEN 19 DESTROYED;
; DeathEffect $7ADF; SaveRoomObjects; PlaceDroid $7A6D; the touch test off;
; then, with lives left, the HUD's lives and energy printed (PrintBcd) and
; DrawRoom with A = $FF (a clear, no scroll). With Lives = $99 (0 - 1 in BCD):
; the game over at LoseLifeGameOver. L1 55 lives lost (energy-out 2,
; game-over).
LoseLife:
  LD A,$FA
  LD (EnergyReload),A
  LD (EnergyTimer),A
  LD A,$99
  LD (Energy),A
  LD A,(Lives)
  DEC A
  DAA
  LD (Lives),A
  LD HL,MsgGenDestroyed
  CALL QueueMessage
  CALL DeathEffect
  CALL SaveRoomObjects
  CALL PlaceDroid
  LD HL,DroidFlags
  RES 4,(HL)
  LD (FlagPointer),HL
  LD A,(Lives)
  CP $99
  JR Z,LoseLifeGameOver
  LD HL,Screen+133
  CALL PrintBcd
  LD A,$99
  LD HL,Screen+136
  CALL PrintBcd
  LD A,$FF
  CALL DrawRoom
  RET
LoseLifeGameOver:
  LD HL,Attributes+133             ; COMPUTER MALFUNCTION, ProgressScreen with A = $FF,
                          ; a wait, Restart (L1 1: game-over)
  LD B,$05
GameOverClearRow:
  LD (HL),$00
  INC L
  DJNZ GameOverClearRow
  XOR A
  LD (EnergyTimer),A
  LD (ScrollPriority),A
  LD HL,MsgMalfunction
  CALL QueueMessage
  LD A,$FF
  CALL ProgressScreen
  LD BC,$0002
  EI
GameOverWait:
  HALT
  DJNZ GameOverWait
  DEC C
  JR NZ,GameOverWait
  POP BC
  JP Restart

; Move one of the three patrollers a pass
;
; PatrollerTurn cycles 0-2; PatrollerPtr = PatrollerPtrs[turn]; MovePatroller
; $93A6. L1 18 583.
MovePatrollers:
  LD A,(PatrollerTurn)
  INC A
  CP $03
  JR NZ,MovePatrollersSet
  XOR A
MovePatrollersSet:
  LD (PatrollerTurn),A
  LD D,$00
  LD E,A
  SLA E
  LD HL,PatrollerPtrs
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (PatrollerPtr),DE
  CALL MovePatroller
  RET

; Queue the message at HL when its priority is above the one shown
;
; In: HL a message (Messages). When (HL) > ScrollPriority: ScrollPriority =
; (HL), ScrollNext = HL + 1. L1 86 calls, 79 taken.
QueueMessage:
  LD B,(HL)
  LD A,(ScrollPriority)
  CP B
  RET NC
  LD A,B
  LD (ScrollPriority),A
  INC HL
  LD (ScrollNext),HL
  RET
