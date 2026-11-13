; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop, the state dispatcher and the keys
;
; MainLoop $ACC8 runs once a frame: it reads the ball's cell, runs the animations (flames, walls, conveyors, bricks,
; locks), counts the timer down, the bottle's pause, tests R (quit), D (the gone cheat mode), the pause key (slot
; $F08A), waits for the frame (WaitFrame $B6E4 through $B87E) and jumps to the ball's state routine through StateTable
; $AD29 by BallState $AA00. Every state routine ends with JP MainLoop.
;
; MainLoop ran 81737 times over the recordings (its witness), one pass a frame, so the game moves at 50 steps a second
; (the ball's bounce in place, 16 steps, takes 16 frames).
;
; The frame wait and the small timing helpers the game, the death and the game-over paths share.
; --------------------------------------------------------------------------------------------------------------------

  ORG $ACC8

; One frame of the game: the animations, the timer, the keys, the frame wait,
; then the ball's state routine
;
; Each pass: $BB32 (the platform under the ball to $AB1C), $BB05 (the ball's
; cell address), the animations $BE94 ($AB33), $BFF3 ($AB2B), $C19D ($AA15),
; $C43E ($AA1D), $BBCD and $BC30 (every fourth frame: the flames and the
; walls), $BD21 ($AA12), the timer $B7D1 (the timer $AB04 minus one), the
; bottle's pause $BA60. Then the keys: R ($2B) held jumps to QuitToMenu $B7B2;
; D ($32) calls CheatModeSwitch $ADDF (a RET); in a game (not the demo) the
; pause key (slot $F08A) calls Pause $B440. Last WaitFrame (through $B87E) and
; the dispatch.
;
; Witness: L1 92281 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
MainLoop:
  AND A
  CALL ReadCell
  CALL CellScreenAddr
  CALL BrickStep
  CALL WaterStep
  CALL PlatformChangeStep
  CALL WallStep
  CALL AnimateFires
  CALL AnimateWalls
  CALL AnimateExit
  CALL TickTimer
  CALL BottleFlashOff
  LD A,$2B
  CALL TestKey
  JP NZ,BackToMenu
  LD A,$32
  CALL TestKey
  CALL NZ,CheatModeSwitch
  LD A,(DemoFlag)
  CP $00
  JR Z,MainLoopPause
  JR MainLoopWait
MainLoopPause:
  LD A,(KeySlots+$0006)   ; in a game: the pause key
  CALL TestKey
  CALL NZ,Pause
MainLoopWait:
  CALL WaitOneFrame       ; the frame wait
Dispatch:
  LD A,(BallState)        ; jump to StateTable[BallState AND 15]
  AND $0F
  RLA
  LD E,A
  LD D,$00
  LD IX,StateTable
  ADD IX,DE
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  POP IX
  JP (IX)

; The ball's nine state routines by BallState $AA00: 0 bounce, 1 left, 2 right,
; 3 up, 4 down, 5 stopped, 6 burst, 7 out below, 8 level end
StateTable:
  DEFW BallBounce,BallLeft,BallRight,BallUp,BallDown,BallStopped,BallBurst,BallFallOut,LevelEnd

; The one-player text: AT 11,13, INK 7, double height, "ready?", end (PrintText
; $E667)
ReadyText:
  DEFB $16,$0B,$0D,$14,$07,$02,$72,$65,$61,$64,$79,$3F,$00

; The two-player text for player 1: "PLAYER 1" at 9,12 in ink 5, "ready?" at
; 12,13 in ink 7, "PLAYER" down column 31 in ink 5, then "1" at 17,31 in ink 7
Player1ReadyText:
  DEFB $16,$09,$0C,$14,$05,$02,$50,$4C,$41,$59,$45,$52,$20,$31,$16,$0C
  DEFB $0D,$14,$07,$02,$72,$65,$61,$64,$79,$3F,$16,$04,$1F,$14,$05,$02
  DEFB $50,$16,$06,$1F,$4C,$16,$08,$1F,$41,$16,$0A,$1F,$59,$16,$0C,$1F
  DEFB $45,$16,$0E,$1F,$52,$16,$11,$1F,$14,$07,$31,$00

; The same for player 2: "PLAYER 2", "ready?", "PLAYER" down column 31, "2"
Player2ReadyText:
  DEFB $16,$09,$0C,$14,$05,$02,$50,$4C,$41,$59,$45,$52,$20,$32,$16,$0C
  DEFB $0D,$14,$07,$02,$72,$65,$61,$64,$79,$3F,$16,$04,$1F,$14,$05,$02
  DEFB $50,$16,$06,$1F,$4C,$16,$08,$1F,$41,$16,$0A,$1F,$59,$16,$0C,$1F
  DEFB $45,$16,$0E,$1F,$52,$16,$11,$1F,$14,$07,$32

; Spaces over "PLAYER n" and "ready?" (AT 9,12 and 12,13); nothing prints it
; (leftover)
BlankReadyText:
  DEFB $00,$16,$09,$0C,$14,$07,$02,$20,$20,$20,$20,$20,$20,$20,$20,$16
  DEFB $0C,$0D,$14,$07,$02,$20,$20,$20,$20,$20,$20,$00

; The player playing now: 1 or 2 (selects the ball sprite, PlayerBallSprite
; $ADE6, and the record)
CurrentPlayer:
  DEFB $02

; The number of players, 1 or 2 (GameRestart)
PlayerCount:
  DEFB $00

; The cheat mode: non-zero refills the stores each life ($BB7D) and lets the
; level end pick a level ($B2C9); no code sets it (CheatModeOn $ADE0 is cut
; off)
CheatMode:
  DEFB $00

; LifeStart's copy of CurrentPlayer while it walks the two records
SavedPlayer:
  DEFB $00

; The D key's routine: a RET, put before the code that would switch the cheat
; mode on
;
; MainLoop and LifeStart call it when D ($32) is held. The RET makes the key do
; nothing; the next six bytes (CheatModeOn $ADE0) are the original body.
; Witness: called whenever D is held; no recording held D.
;
; Witness: L1 0 ().
CheatModeSwitch:
  RET

; LD A,1: LD ($ADDD),A: RET: the cut-off body of the D key (never runs)
;
; Would set CheatMode $ADDD = 1. CheatModeSwitch's RET in front of it keeps it
; from running; nothing else jumps here (known only from the code).
;
; Witness: L1 0 ().
CheatModeOn:
  LD A,$01
  LD (CheatMode),A
  RET

  ORG $B6CB

; NZ (A = 1) when the key or stick code A is held, else Z (A = 0): ReadControls
; then TestKeyBit
;
; Witness: L1 423995 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
TestKey:
  PUSH AF
  CALL ReadControls
  POP AF
  CALL TestKeyBit
  JR NZ,TestKeySkip
  LD A,$01
  AND A
  RET
TestKeySkip:
  XOR A                   ; not held
  RET

; A RET the level builder calls three times ($CF50, $CF5A, $CF64)
;
; Witness: L1 282 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
NoOp:
  RET

; A lone RET ($C9); nothing calls it (leftover)
UnusedRetB6DC:
  DEFB $C9

; Waits until a key or the stick is held (no wait for the release): the
; "ready?" prompt
;
; Witness: L1 332911 (c1, fire, gameover, menu, twoname, rzx x23).
WaitPressHeld:
  CALL AnyControl
  JR Z,WaitPressHeld
  RET

; A lone RET ($C9) before WaitFrame; nothing calls it (leftover)
UnusedRetB6E3:
  DEFB $C9

; Refresh the HUD's attributes and wait for the next frame interrupt
;
; Calls $E58B (the per-frame HUD refresh, which repaints the attributes with
; PaintHudAttrs $B6EE), then EI and HALT: the game runs at one pass of MainLoop
; $ACC8 a frame. IX is preserved. Called by MainLoop ($ACC5) and WaitOneFrame
; $B87E.
;
; Witness: L1 95897 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
WaitFrame:
  PUSH IX
  CALL DrawHud
  EI
  HALT
  POP IX
  RET

  ORG $B747

; A RET in place of an Amstrad CPC firmware call
;
; A lone RET. $B744-$B754 is a row of 17 $C9 bytes: the Spectrum port replaced
; the CPC firmware jump block entries the game called with RETs at the same
; kind of place. This one is called with B = C = 26 by TakeBottle $BA1C and
; with B = C = 0 by BottleFlashOff $BA60: on the CPC, B and C are two colours,
; which fits SCR SET BORDER (26 bright white, 0 black): a border flash for the
; extra life that the Spectrum drops (known only from the code).
;
; Witness: L1 40 (menu, l10, l36, l45, l68, rzx x15).
FirmwareStub:
  RET

; Eight more RET stubs ($C9), none called
;
; Never run or read.
FirmwareStubs2:
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9

; A RET stub, called by $B387 at the end of a level
;
; A lone RET in the row of firmware stubs ($B744-$B754); called by the
; level-end code at $B387.
;
; Witness: L1 20 (menu, l51, l59, l96, l98, rzx x15).
FirmwareStub3:
  RET

; Three more RET stubs ($C9), none called
;
; Never run or read.
FirmwareStubs4:
  DEFB $C9,$C9,$C9

; A RET stub, called only by the disabled cheat routes $B2C9 and $BA80
;
; A lone RET; both callers are dead code (the level-select cheat, see
; SelfDestruct $BA71), so it never runs.
;
; Witness: L1 0 ().
FirmwareStub5:
  RET

  ORG $B7B8

; Wait 50 frames or until a key is pressed
;
; Sets the counter $EFED to 50, then a frame at a time (EI, HALT) calls AnyKey
; $B407 and returns as soon as it reports a key (NZ), else counts down to 0.
; Used between lives (LoseLife $BA93), after a level ($B3AB) and before the
; menu (BackToMenu).
;
; Witness: L1 56 (fire, gameover, menu, twoname, l51, l59, l96, l98, rzx x26).
WaitKeyOrSecond:
  LD HL,$0032
  LD (MenuTimer),HL
WaitKeyOrSecondLoop:
  EI
  HALT
  CALL AnyControl
  JR NZ,WaitKeyOrSecondEnd
  LD HL,(MenuTimer)
  DEC HL
  LD (MenuTimer),HL
  LD A,L
  OR H
  JR NZ,WaitKeyOrSecondLoop
WaitKeyOrSecondEnd:
  RET

  ORG $B873

; Busy wait: B times 50 empty loops
;
; Input B. About 650 T-states a unit. Used by the burst death ($B144),
; GameOverDelay $C4D5 and NameEntry ($EC4E). BC preserved.
;
; Witness: L1 37654 (gameover, menu, twoname, l x6, rzx x29).
Delay:
  PUSH BC
  LD B,$32
DelayInner:
  LD A,$00
  DJNZ DelayInner
  POP BC
  DJNZ Delay
  RET

; CALL WaitFrame: wait one frame
;
; Called where a frame passes without the main loop: the state handlers ($AD0C,
; $B029, $B169), the level end ($B328, $B334) and the pause between lives
; (LoseLife, 50 calls).
;
; Witness: L1 95861 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
WaitOneFrame:
  CALL WaitFrame
  RET
