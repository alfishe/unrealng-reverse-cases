; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop: one pass a frame
;
; MainLoop $E3C9 runs once a pass: the quit test (`$A13C`), UpdateObjects $EC11 (every object, Rick included),
; BonusCountdown $E466, the pause test (`$A144`), the death and zone-change tests, then HALT at MainLoopHalt $E40F and
; the drawing: `$A73F`, `$A144`, `$A22A` with C = 1, `$A25D`, `$A90F`, and the scroll down `$ADB9` (RickY $EAAE >=
; `$CC`) or up `$ADF0` (RickY < `$60`) unless Rick is dying (`$FD68`).
;
; NewLife $E3AF starts every life: Rick alive and back to type 1, 6 bullets and 6 dynamite, Rick put back at the
; zone's restart point (`$AD29`), the HUD redrawn (`$A93D`). FrameTick $E49B is called by the IM 2 handler every frame
; and keeps a 32-bit frame count, which Random $E441 mixes in.
;
; The pass counts (L1, the first instruction of MainLoop): c1 1073, controls 501, gameover 910, level1 2152, level2
; 2845, level3 2927, level4 1887; FrameTick, once an interrupt: c1 14301, level1 5822, level2 5870, so a pass takes
; about 2-3 frames in play.
; --------------------------------------------------------------------------------------------------------------------

; A new life: Rick alive, ammo 6, back to the zone's restart point
;
; Clears the death flags `$FD69` (lose a life) and `$FD68` (Rick is dying),
; sets RickObject's type to 1, bullets `$A976` and dynamite `$A967` to 6, calls
; `$AD29` (Rick to the restart point of the zone) and `$A93D` (HUD), and falls
; into MainLoop $E3C9.
;
; Run 3 times in c1, 12 in level1 (one per life and new game), 29 in level4.
;
; Witness: L1 323 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
NewLife:
  XOR A
  LD (DeathDone),A
  LD (Dying),A
  LD A,$01
  LD (RickObject),A
  LD A,$06
  LD (Dynamite),A
  LD (Bullets),A
  CALL RestartScreen
  CALL DrawHud

; The main loop, one pass per frame
;
; Q (`$A13C` Z) quits to Quit $E35A. Then UpdateObjects $EC11, BonusCountdown
; $E466 (HL = RickY, unused), and the pause: P (`$A144` Z) waits for P to be
; let go, pressed again and let go (only c1 paused: 9228 / 139455 / 10050
; polls).
;
; CheckDeath: when `$FD69` is set (Rick's death has played out, `$FC47`) one
; life `$A958` goes; none left: Quit $E35A, else NewLife $E3AF. The ZXDB
; infinite-lives POKE 58356,0 turns the `DEC A` at `$E3F4` into NOP (the warp
; recordings use it).
;
; CheckZone: when `$FD61` is set (Rick left the zone, `$FBD1` / `$FBE0`),
; `$AB93` changes the zone or level and CheckGameComplete $E406 follows; else
; MainLoopHalt.
;
; Witness: L1 42793 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
MainLoop:
  CALL QuitPressed
  JR Z,Quit
  CALL UpdateObjects
  LD HL,(RickY)
  CALL BonusCountdown
  CALL PausePressed
  JR NZ,CheckDeath
PauseRelease:
  CALL PausePressed       ; P pressed: wait for its release
  JR Z,PauseRelease
PauseWaitPress:
  CALL PausePressed
  JR NZ,PauseWaitPress
PauseResume:
  CALL PausePressed
  JR Z,PauseResume
CheckDeath:
  LD A,(DeathDone)
  AND A
  JR Z,CheckZone
  LD A,(Lives)
  DEC A                   ; POKE 58356,0 (infinite lives) makes this a NOP
  LD (Lives),A
  JP Z,Quit
  JR NewLife
CheckZone:
  LD A,(ZoneChange)
  AND A
  JR Z,MainLoopHalt
  CALL CheckScreenExit

; After a zone change: the game complete, or the frame's drawing
;
; GameComplete $E440 set (`$AC52`, after the closing text of the ending) goes
; to GameOver $E35D (seen in ending); else back to MainLoop $E3C9.
;
; MainLoopHalt is the frame's HALT, reached from CheckZone when no zone change
; is pending. After it: `$A237` = 0, `$A73F`, `$A144`, `$A22A` (C = 1),
; `$A25D`, `$A90F`, then the vertical scroll unless `$FD68` (Rick dying): RickY
; $EAAE >= `$CC`: `$ADB9` (c1 14, level1 15); RickY < `$60`: `$ADF0` (only
; level2, 11 times).
;
; Witness: L1 105 (c1, ending2, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12,
; L4Z2-L4Z6, L4Z8, level1).
CheckGameComplete:
  LD A,(GameComplete)
  AND A
  JP NZ,GameOver
  JR MainLoop
; This entry point is used by the routine at MainLoop.
MainLoopHalt:
  HALT                    ; the frame's HALT
  XOR A
  LD (FrameTicks),A
  CALL ComposeObjects
  CALL PausePressed
  LD C,$01
  CALL WaitFrames
  CALL DrawDirtyCells
  CALL UpdateHud
  LD A,(Dying)
  AND A
  JR NZ,MainLoopNext
  LD A,(RickY)
  CP $CC
  JR C,CheckScrollUp
  CALL ScrollViewDown
  JR MainLoopNext
CheckScrollUp:
  CP $60
  JR NC,MainLoopNext
  CALL ScrollViewUp
MainLoopNext:
  JR MainLoop

; $FF when the last level is done (`$AC52`); cleared by NewGame $E2DC
;
; Read by CheckGameComplete $E406. The ending recording sets it at the end of
; the closing text.
GameComplete:
  DEFB $00

; A pseudo-random byte from the frame count
;
; HL = RandomState + FrameCount + `$0D` + FrameCountHigh (with carry); L = A
; XOR L XOR D XOR E XOR H (A the caller's), stored back to RandomState; returns
; that byte in A, HL and DE kept.
;
; Called by `$F4AA`; run in c1 (3) and levels 1-4 (19, 32, 13, 137). What the
; caller does with it is known only from the code.
;
; Witness: L1 519 (c1, L1Z3, L1Z4, L2Z2-L2Z5, L3Z2, L3Z5, L3Z11, L4Z1-L4Z3,
; L4Z5, L4Z7, L4Z8, level1-level4).
Random:
  PUSH HL
  PUSH DE
  LD HL,(RandomState)
  LD DE,(FrameCount)
  ADD HL,DE
  LD DE,$000D
  ADD HL,DE
  LD DE,(FrameCountHigh)
  ADC HL,DE
  XOR L
  XOR D
  XOR E
  XOR H
  LD L,A
  LD (RandomState),HL
  POP DE
  POP HL
  RET

; the generator's 16-bit state
RandomState:
  DEFW $0000
FrameCount:
  DEFW $0000              ; frames since the load, low word (FrameTick $E49B)
FrameCountHigh:
  DEFW $0000              ; its high word

  ORG $E49B

; The 32-bit frame count, from the IM 2 handler
;
; FrameCount $E462 + 1, carried into FrameCountHigh $E464. Called by the IM 2
; handler once a frame (its counts equal the handler's: c1 14301, ending 1499).
;
; Witness: L1 108326 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
FrameTick:
  LD HL,(FrameCount)
  INC HL
  LD (FrameCount),HL
  LD A,L
  OR H
  RET NZ
  LD HL,(FrameCountHigh)
  INC HL
  LD (FrameCountHigh),HL
  RET

; The level, 0-3; 4 after the last (the ending)
;
; Cleared by NewGame $E2DC, raised by the level change `$ABF6`; `$AC07` uses it
; to pick the LevelTable record, `$AC20` as the end-of-level tune.
Level:
  DEFB $00
