; The demo: $FF while the demo plays
;
; Set by the menu (key 5, or when idle too long), cleared when the menu is
; entered. docs/05-controls.md 5.1, docs/10-gameplay-logic.md 10.6.
DemoFlag:
  DEFB $00

; The menu's idle count, low byte
MenuIdleLow:
  DEFB $00

; The menu's idle count in 256 passes; 2 000 starts the demo
MenuIdleHigh:
  DEFW $0000

; The attribute address of the device highlight bar
MenuBarAttr:
  DEFW $0000

; " DEMO " at (2,6)
;
; Printed every pass of the demo. Strings are records for $EE17: attribute +
; $80, column, row, characters; $FF ends. docs/08-hud-and-text.md 8.3.
DemoMessage:
  DEFM $87,$02,$06," DEMO ",$FF

; "PAUSE!" at (2,6)
PauseMessage:
  DEFM $87,$02,$06,"PAUSE!",$FF

; The GAME OVER box
;
; A red frame of $2E blocks around the eleven big-letter glyphs $22-$2C, rows
; 9-11, columns 10-22. Printed at GAME OVER and ABORT ($D0A5).
; docs/08-hud-and-text.md 8.2-8.3.
GameOverBox:
  DEFM $82,$0A,$09,".............",$87,$0B,$0A,"\"#$%&'()*+,",$82,$0A,$0A,".",$82,$16,$0A,".",$82,$0A,$0B,".............",$FF

; "ABORT!" at (2,6)
AbortMessage:
  DEFM $87,$02,$06,"ABORT!",$FF

; Six spaces at (2,6): clears the message window
BlankMessage:
  DEFM $87,$02,$06,"      ",$FF

; The menu: SELECT and the six choices
;
; Seven records: SELECT at (2,6); the four devices at (10,8-11) in white; 5
; DEMO and 6 START GAME at (10,13-14) in green. docs/05-controls.md 5.1.
MenuText:
  DEFM $87,$02,$06,"SELECT",$87,$0A,$08,"1 KEYBOARD   ",$87,$0A,$09,"2 SINCLAIR   ",$87,$0A,$0A,"3 KEMPSTON   ",$87,$0A,$0B,"4 PRO"
  DEFM "TEK-AGF ",$84,$0A,$0D,"5 DEMO       ",$84,$0A,$0E,"6 START GAME ",$FF

; The menu: device, demo or start
;
; Paints the cells of the list $D5B2 with attribute 6 ($D338,
; docs/08-hud-and-text.md 8.5). Unless it is entered after the demo, it updates
; HIGH ($EEE3) and clears SCORE, MAX and the round table ($EEC4). Prints the
; menu and the credits, waits for all keys to be released, beeps. Then it
; loops: keys 1-4 choose the device ($C28F) and move the 13-cell highlight bar;
; 5 starts the demo; 6 starts the game; 256 * 2 000 passes with no key start
; the demo. Every pass increments the random seed $EA36. docs/05-controls.md
; 5.1.
Menu:
  LD B,$06
  CALL PaintAttributes    ; attribute 6 over the cells of the list $D5B2
  LD A,(DemoFlag)         ; returning from the demo: the scores are left alone
  AND A
  JR NZ,MenuKeepScores
  CALL UpdateHigh         ; MAX into HIGH
  CALL ClearScores        ; a new game's SCORE, MAX and round table
MenuKeepScores:
  XOR A
  LD (DemoFlag),A
  LD HL,MenuText          ; the menu, then the credits stored in the font
  CALL PrintString
  LD HL,CreditsText1
  CALL PrintString
  LD HL,CreditsText2
  CALL PrintString
MenuReleaseWait:
  XOR A                   ; wait until no key is pressed
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,MenuReleaseWait
  LD HL,$465A             ; the menu beep
  CALL Beep
MenuShowDevice:
  LD HL,$0000             ; the idle count starts again
  LD (MenuIdleHigh),HL
  XOR A
  LD (MenuIdleLow),A
  LD A,(InputDevice)
  LD HL,$590A             ; the bar: attribute row 8 + device, column 10
  AND A
  JR Z,BarRowFound
  LD BC,$0020
BarRowLoop:
  ADD HL,BC
  DEC A
  JR NZ,BarRowLoop
BarRowFound:
  LD (MenuBarAttr),HL
  LD B,$0D
BarHighlightLoop:
  LD (HL),$17             ; 13 cells highlighted
  INC L
  DJNZ BarHighlightLoop
DeviceReleaseWait:
  XOR A                   ; wait until no key is pressed
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,DeviceReleaseWait
MenuLoop:
  LD HL,(RandomSeed)      ; the random seed, once a pass
  INC HL
  LD (RandomSeed),HL
  LD A,(MenuIdleLow)      ; the idle count
  INC A
  LD (MenuIdleLow),A
  JR NZ,MenuReadKeys
  LD HL,(MenuIdleHigh)
  INC HL
  LD (MenuIdleHigh),HL
  LD BC,$07D0             ; 2 000 * 256 passes: the demo
  AND A
  SBC HL,BC
  JR Z,StartDemo
MenuReadKeys:
  LD HL,$59CA             ; key 6: start the game (bar on row 14)
  LD A,$EF
  IN A,($FE)
  BIT 4,A
  JR Z,HighlightChoice
  LD A,$F7                ; key 5: the demo
  IN A,($FE)
  BIT 4,A
  JR NZ,MenuDevice
StartDemo:
  LD HL,$59AA             ; the demo (bar on row 13)
  LD A,$FF
  LD (DemoFlag),A
HighlightChoice:
  LD B,$0D
ChoiceBarLoop:
  LD (HL),$17
  INC L
  DJNZ ChoiceBarLoop
  LD HL,$1E9C             ; the start beep
  CALL Beep
  RET
MenuDevice:
  LD A,$F7                ; keys 1-4: the device
  IN A,($FE)
  LD B,$00
  BIT 0,A
  JR Z,DeviceChosen
  INC B
  BIT 1,A
  JR Z,DeviceChosen
  INC B
  BIT 2,A
  JR Z,DeviceChosen
  INC B
  BIT 3,A
  JP NZ,MenuLoop
DeviceChosen:
  LD A,B
  LD (InputDevice),A      ; the chosen device
  LD HL,$04B4             ; the device beep
  CALL Beep
  LD HL,(MenuBarAttr)     ; the old bar back to white
  LD B,$0D
BarWhiteLoop:
  LD (HL),$07
  INC L
  DJNZ BarWhiteLoop
  JP MenuShowDevice

; Beep with the length and pitch at HL
;
; HL points to a word: the length (high byte) and the pitch (low byte) for
; $F288. Used by the effect table ($F2D9).
BeepAt:
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A

; A two-tone beep
;
; H = length in 256-step units, L = pitch. Two square waves with half-periods
; of 256 - L and 257 - L steps (D and E count up to the wrap) toggle the beeper
; and MIC bits; their beating gives the warble. Border black. docs/09-sound.md
; 9.6.
Beep:
  LD C,H
  XOR A
  LD B,A
  LD D,L
  LD E,D
  DEC E
BeepStepLoop:
  OUT ($FE),A             ; the beeper, border 0
  INC D                   ; wave 1: 256 - L steps
  JR NZ,BeepWaveTwo
  LD D,L
  XOR $18
BeepWaveTwo:
  INC E                   ; wave 2: 257 - L steps
  JR NZ,BeepNextStep
  LD E,L
  DEC E
  XOR $18
BeepNextStep:
  DJNZ BeepStepLoop
  DEC C
  JR NZ,BeepStepLoop
  RET

; A rising sweep
;
; HL points to four bytes: the step, the cycles of each tone, the start
; half-period and the number of tones. Each tone is the step shorter than the
; one before, so the pitch rises; the half-period D is 8 bits and wraps (0
; waits 256), so a sweep that passes 0 drops to its lowest pitch and rises
; again (the round start's wraps three times). docs/09-sound.md 9.6.
Sweep:
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD E,(HL)
  LD H,B
  LD L,C
SweepToneLoop:
  XOR A
  LD C,L
SweepHalfPeriod:
  XOR $18                 ; one half-period
  LD B,D
SweepWaitLoop:
  OUT ($FE),A
  DJNZ SweepWaitLoop
  DEC C
  JR NZ,SweepHalfPeriod
  LD A,D                  ; the next tone, shorter by the step
  SUB H
  LD D,A
  DEC E
  JR NZ,SweepToneLoop
  RET

; The sound requests: one bit an effect
;
; Set by the game (bit 0 a pod joins, 1 an explosion, 2 a hit that does not
; destroy, 3 AUTO, 4 a shot), played by $F2C0, cleared by the play loop
; ($D085). docs/09-sound.md 9.6, docs/10-gameplay-logic.md 10.8.
SoundRequests:
  DEFB $00

; Play the requested effect of the highest priority
;
; The lowest set bit of $F2BF (bits 0-4) picks the 5-byte entry $F2E2 + 5 *
; bit; nothing requested, nothing played. docs/09-sound.md 9.6.
PlayEffect:
  LD A,(SoundRequests)
  LD B,$05
LowestBitLoop:
  RRA                     ; the lowest set bit
  JR C,EffectFound
  DJNZ LowestBitLoop
  RET
EffectFound:
  LD A,$05                ; entry = 5 * bit
  SUB B
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,EffectTable
  ADD HL,BC

; Play one effect entry
;
; HL = a 5-byte entry: 0 and a beep word for $F288, or not 0 and four sweep
; bytes for $F2A3. The round setup plays the entry $F2FB through here.
PlaySound:
  LD A,(HL)
  INC HL
  AND A
  JP Z,BeepAt
  JP Sweep

; The five request effects
;
; Entry per request bit 0-4: kind (0 beep, 1 sweep), then the beep's pitch and
; length or the sweep's step, cycles, start half-period and tones. Bit 0 sweep
; 2,4,$50,$1E; bit 1 sweep $0A,3,$14,6; bit 2 sweep $32,5,$1E,3; bit 3 beep
; $0414; bit 4 sweep 2,4,$42,$0A. docs/09-sound.md 9.6.
EffectTable:
  DEFB $01,$02,$04,$50,$1E
  DEFB $01,$0A,$03,$14,$06
  DEFB $01,$32,$05,$1E,$03
  DEFB $00,$14,$04,$00,$00
  DEFB $01,$02,$04,$42,$0A

; The sweep of the round setup
;
; Sweep 8, 4, 3, $64, played by $D151 through $F2D9 when a round is set up.
RoundStartSound:
  DEFB $01,$08,$04,$03,$64
