; --------------------------------------------------------------------------------------------------------------------
; controls.asm: The controls: keys, joysticks, pause, quit
; --------------------------------------------------------------------------------------------------------------------

  ORG $81FD

; The control method: 0 keyboard, 1 Sinclair, 2 Kempston, 3 Protek / AGF (1 in
; the image)
;
; Written by OptionsMenu (`$A823`, keys 1-4); read by ReadControls `$9869`
; (`$9869`), CursorFire (`$9A5F`) and OptionsMenu (`$A775`, the highlight). The
; image holds 1 (Sinclair): the value of the last session the file was saved
; from, kept until the player presses 1-4.
ControlMethod:
  DEFB $01

; One byte of 0 between ControlMethod and Level: never read or written
;
; No instruction addresses it and no recording reads or writes it.
Spare81FE:
  DEFB $00

  ORG $973A

; P: INTERMISSION until ENTER, then the game goes on as it was
;
; Jumped to by `ReadKeys` `$97F0` when P is held without ENTER. Not in the demo
; (`$8379` set). With interrupts off: a short tone (`$A843`, HL = `$0F3C`), the
; COMPUTER line's state, the energy tick and the sound flags saved in
; `CursorVars` (`$96C7`), the sound flags and `$A10D` cleared; five pixel rows
; of the screen at `$50E0` saved and " INTERMISSION  " printed there in the
; panel's font (rows 2-6 of each glyph), with a bar `$80` in its first column;
; wait for every key to be let go, then the pause tune `$AD79`, the COMPUTER
; line set to "PRESS ENTER FOR MORE ACTION" (`$A2C3`), interrupts on, wait for
; ENTER; then the tone again and everything put back.
;
; The energy tick is restored from its copy, so the pause costs no energy.
; Recording: `controls` (P at the frame the input script gives, the pause's
; tune, ENTER), one run.
;
; Witness: L1 1 (controls).
PauseGame:
  LD A,(DemoFlag)
  AND A
  RET NZ
  DI                      ; a tone (H = length, L = pitch)
  LD HL,$0F3C
  CALL TwoTone
  LD HL,MessageNumber     ; save the COMPUTER line's state $A104-$A111
  LD DE,PauseSavedMessage
  LD BC,$000E
  LDIR
  LD A,(EnergyTick)       ; then the energy tick and the sound flags
  LD (DE),A
  INC DE
  LD A,(SoundFlags)
  LD (DE),A
  XOR A                   ; silence, stop the COMPUTER line's scroll
  LD (SoundFlags),A
  LD (MessageState),A
  LD HL,Screen+4320             ; save five pixel rows of 16 bytes from $50E0
  LD DE,PauseSavedRows
  LD A,$05
PauseSaveRows:
  LD BC,$0010
  LDIR
  LD L,$E0
  INC H
  DEC A
  JR NZ,PauseSaveRows
  LD B,$0F                ; print " INTERMISSION  " at $50E1
  LD HL,IntermissionText
  LD DE,Screen+4321
PausePrintChar:
  LD A,(HL)               ; the glyph's rows 2-6 ($D202 + 8 x (character - 32))
  SUB $20
  PUSH BC
  PUSH HL
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$D202
  ADD HL,BC
  LD B,$05
PauseGlyphRows:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ PauseGlyphRows
  LD D,$50
  POP HL
  POP BC
  INC E
  INC HL
  DJNZ PausePrintChar
  LD HL,Screen+4320             ; a bar in the first column
  LD A,$80
  LD B,$05
PauseBar:
  LD (HL),A
  INC H
  DJNZ PauseBar
PauseWaitRelease:
  XOR A                   ; wait until no key is held
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,PauseWaitRelease
  CALL TitleTune          ; the pause's tune
  LD HL,IntermissionMessage ; COMPUTER: PRESS ENTER FOR MORE ACTION
  LD (MessageText),HL
  EI
PauseWaitEnter:
  LD A,$BF
  IN A,($FE)
  BIT 0,A
  JR NZ,PauseWaitEnter
PauseResume:
  DI                      ; a tone, then put back the screen, the message, the
                          ; tick and the sound flags
  LD HL,$0F3C
  CALL TwoTone
  LD HL,PauseSavedRows
  LD DE,Screen+4320
  LD A,$05
PauseRestoreRows:
  LD BC,$0010
  LDIR
  LD E,$E0
  INC D
  DEC A
  JR NZ,PauseRestoreRows
  LD HL,PauseSavedMessage
  LD DE,MessageNumber
  LD BC,$000E
  LDIR
  LD A,(HL)
  LD (EnergyTick),A
  INC HL
  LD A,(HL)
  LD (SoundFlags),A
  EI
  RET

; Each pass: P pauses, U and G together abort the game, then the controls
;
; Called first in each pass of the main loop (`$854A`; 90 922 runs over all
; recordings). Clears CursorMode `$96C6`. P (`$DFFE` bit 0) without ENTER:
; PauseGame `$973A`. U (`$DFFE` bit 3) with G (`$FDFE` bit 4): the COMPUTER
; line shows message `$14`, "GAME ABORTED" (`$A17B`, "DEMO ABORTED" `$A18A` in
; the demo), a tone (`$A843`, HL = `$C814`), the return address is dropped and
; the game goes back to the title (`$840C`). Then `ReadControls` `$9869`.
;
; A quirk: with P and ENTER both held the abort test reads bit 3 of the ENTER
; half-row (J) for U.
;
; Recordings: `controls` aborts with U + G ("GAME ABORTED", screen 2000),
; `menu` the demo (SPACE ends it elsewhere) and practice (U + G); `$9811` 5
; runs (controls, kempston, menu).
;
; Witness: L1 111157 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
ReadKeys:
  XOR A
  LD (CursorMode),A
  LD A,$DF                ; P?
  IN A,($FE)
  BIT 0,A
  JR NZ,ReadKeysAbort
  LD A,$BF                ; P with ENTER: no pause
  IN A,($FE)
  BIT 0,A
  JP NZ,PauseGame
ReadKeysAbort:
  BIT 3,A                 ; U?
  JR NZ,ReadKeysControls
  LD A,$FD                ; and G?
  IN A,($FE)
  BIT 4,A
  JR NZ,ReadKeysControls
AbortGame:
  LD HL,GameAbortedMessage ; COMPUTER: message $14, GAME ABORTED
  LD A,$14
  LD (MessageNumber),A
  LD A,(DemoFlag)
  AND A
  JR Z,AbortGameMessage
  LD HL,DemoAbortedMessage ; in the demo: DEMO ABORTED
AbortGameMessage:
  LD (MessageText),HL
  LD HL,$C814             ; a tone, then back to the title (the return address
                          ; dropped)
  CALL TwoTone
  POP HL
  JP TitleLoop
ReadKeysControls:
  JP ReadControls         ; the cheat below is skipped: straight to the
                          ; controls

; The dormant level cheat: W for the next level, S for the one before
;
; Never reached in the game: the `JP $9869` at `$982F` jumps over it and no
; other jump or call leads here. Recorded working on a clone: `cheat`
; (work/stage2/cheat/cheat.szx = level 1 in play with the POKE `$982F-$9831` =
; 0, tests/inputs/cheat.txt): W twice took the level from 0 to 1 and 2
; (`$9847-$984F` 2 runs), S back to 1 (`$985A-$9866` once); the Y + T drop
; `$983E` ran in no recording. A is the half-row `ReadKeys` read last: `$DFFE`
; (Y is its bit 4) unless U is held. W (`$FBFE` bit 1): the level `$81FF` + 1
; (no upper limit); S (`$FDFE` bit 1): the level - 1, not below 0; either drops
; `ReadKeys`' return address and restarts at the level set-up `$843C` (the
; `$843C` loop never returns, so the stack's depth does not matter). Neither:
; on to `ReadControls`.
;
; Y (bit 4 of A) and T (`$FBFE` bit 4) held together drop one more return
; address first. With W or S that is harmless (the restart); without them
; `ReadControls` would return past the main pass, so the Y + T test looks like
; a guard whose jump sense went wrong, or a leftover. A `JR $9832` (or no `JP`)
; at `$982F` would bring the cheat back.
;
; Witness: L1 531 (cheat).
LevelCheat:
  BIT 4,A                 ; Y held?
  JR NZ,LevelCheatUp
  LD A,$FB                ; and T?
  IN A,($FE)
  BIT 4,A
  JR NZ,LevelCheatUp
  POP HL                  ; both: one return address dropped
LevelCheatUp:
  LD A,$FB                ; W: the next level
  IN A,($FE)
  BIT 1,A
  JR NZ,LevelCheatDown
  LD A,(Level)
  INC A
  LD (Level),A
  POP HL
  JP SetUpLevel
LevelCheatDown:
  LD A,$FD                ; S: the level before, not below 0
  IN A,($FE)
  BIT 1,A
  JR NZ,ReadControls
  POP HL
  LD A,(Level)
  AND A
  JP Z,SetUpLevel         ; S at level 0: the level restarts
  DEC A
  LD (Level),A
  JP SetUpLevel

; Read the chosen control method into the control bits: 0 left, 1 right, 2
; down, 3 up, 4 fire
;
; By ControlMethod `$81FD`: 0 the keyboard (Q up, A down, K left, L right, fire
; any key of the bottom row: CAPS SHIFT to V and B to SPACE, port `$7EFE`), 1
; Sinclair (`$98AD`: both Interface 2 ports, 1-5 left, right, down, up, fire
; and 6-0 left, right, down, up, fire, ORed), 2 Kempston (`ReadKempston`
; `$98D2`), 3 Protek / AGF cursor keys (`$98E7`: 5 left, 8 right, 6 down, 7 up,
; 0 fire). All four end in `MoveCursor` `$9910`.
;
; Runs: the keyboard `$987B` 1361 (c1g, controls), Sinclair `$98AD` 88 978 (the
; default; every RZX segment), Kempston `$98D2` 301 (kempston), Protek `$98E7`
; 276 (controls).
;
; Witness: L1 111148 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
ReadControls:
  LD A,(ControlMethod)
  CP $01
  JP Z,ReadSinclair
  CP $02
  JP Z,ReadKempston
  CP $03
  JP Z,ReadProtek
ReadKeyboard:
  LD B,$00                ; Q: up
  LD A,$FB
  IN A,($FE)
  RRA
  JR C,ReadKeyboardA
  SET 3,B
ReadKeyboardA:
  LD A,$FD                ; A: down
  IN A,($FE)
  RRA
  JR C,ReadKeyboardL
  SET 2,B
ReadKeyboardL:
  LD A,$BF                ; L: right
  IN A,($FE)
  RRA
  RRA
  JR C,ReadKeyboardK
  SET 1,B
ReadKeyboardK:
  RRA                     ; K: left
  JR C,ReadKeyboardFire
  SET 0,B
ReadKeyboardFire:
  LD A,$7E                ; any key of the two bottom half-rows: fire
  IN A,($FE)
  CPL
  AND $1F
  JR Z,ReadKeyboardDone
  SET 4,B
ReadKeyboardDone:
  LD A,B
  JP MoveCursor
ReadSinclair:
  LD A,$F7                ; 1-5: left, right, down, up, fire
  IN A,($FE)
  OR $E0
  CPL
  LD B,A
  LD A,$EF                ; 6-0: reversed into the same order (0 fire ... 6
                          ; left)
  IN A,($FE)
  OR $E0
  CPL
  LD C,$00
  RRA
  RL C
  RRA
  RL C
  RRA
  RL C
  RRA
  RL C
  RRA
  RL C
  LD A,C
  OR B
  JP MoveCursor

; Kempston (port $1F): the control bits, left and right swapped into place
;
; Port `$1F` gives bit 0 right, 1 left, 2 down, 3 up, 4 fire; down, up and fire
; are kept, right becomes bit 1 and left bit 0. Then `MoveCursor`. The entry
; point `$98E7` reads the Protek / AGF keys (5 left, 6 down, 7 up, 8 right, 0
; fire). Recording `kempston`: 301 runs, the cursor moved and a mirror turned.
;
; Witness: L1 301 (kempston).
ReadKempston:
  IN A,($1F)
  LD B,A
  AND $1C                 ; down, up, fire as they are
  BIT 0,B
  JR Z,ReadKempstonLeft
  SET 1,A
ReadKempstonLeft:
  BIT 1,B
  JP Z,MoveCursor
  SET 0,A
  JP MoveCursor
; This entry point is used by the routine at ReadControls.
ReadProtek:
  LD E,$00                ; 5: left
  LD A,$F7
  IN A,($FE)
  BIT 4,A
  JR NZ,ReadProtek6
  SET 0,E
ReadProtek6:
  LD A,$EF                ; 6: down
  IN A,($FE)
  BIT 4,A
  JR NZ,ReadProtek7
  SET 2,E
ReadProtek7:
  BIT 3,A                 ; 7: up
  JR NZ,ReadProtek8
  SET 3,E
ReadProtek8:
  BIT 2,A                 ; 8: right
  JR NZ,ReadProtek0
  SET 1,E
ReadProtek0:
  BIT 0,A                 ; 0: fire
  JR NZ,ReadProtekDone
  SET 4,E
ReadProtekDone:
  LD A,E
