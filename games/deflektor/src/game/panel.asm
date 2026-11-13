; --------------------------------------------------------------------------------------------------------------------
; panel.asm: The panel, the score, the COMPUTER messages
;
; LoseLife $866A: BOOM BOOM BOOM and a red play area (or a falling sweep when the energy drained), one life bar
; hollowed, 36 bursts of the life-lost sound, then the same level again, or GAME OVER (the banner GameOverBanner) and
; the title. Practice takes no life.
;
; The COMPUTER line (row 23, columns 1-15) is driven by the interrupt (InterruptHandler $A32A): the game only writes
; the address of a message to MessageText $A10E, and a message number to MessageNumber $A104 when the message is more
; urgent than the one shown. A message that starts with $FE is static (14 characters, blinking); any other scrolls in
; from the right a pixel a frame, its $FF followed by the address where it goes on (a loop, or BlankMessage $A199,
; which ends it). The same line in the menu (row 21, columns 5-25, MenuScroller $A103 set) scrolls the credits and the
; name-entry prompt, where a byte $FE is a pause counted down in the text itself.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7B80

; The play panel of rows 20-23: 1024 pixel bytes in plain rows, then 128
; attributes
;
; DrawPanel `$A50C` (from LevelPanel `$8432`, at each new game and level start)
; copies 32 bytes a pixel row to the screen, the 8 rows of character row 20,
; then rows 21, 22 and 23 (the screen address advanced by `INC D` and `E +
; 32`), then the 128 attributes to `$5A80-$5AFF`. So the bytes are a linear
; picture of 32 pixel rows of 32 bytes, top to bottom, followed by 4 rows of 32
; attributes (`$02`-`$07`, no BRIGHT, no FLASH).
;
; The panel: "LEVEL ." with the two digit boxes (columns 6-7, filled by
; SetUpLevel `$843C` from LevelDigits `$88B0`); LIVES with three magenta bars
; (row 21, columns 10-15, hollowed by LoseLife `$866A`); OVERLOAD and ENERGY
; with their dotted bars (rows 21 and 23, columns 17-24, filled by `$A683` /
; `$A613`); SCORE and HIGH with their boxes (columns 26-31); COMPUTER with the
; message box (row 23, columns 1-14, the scroll of InterruptHandler `$A32A`).
;
; Read 67 times (`c1g`, `controls`, `energy`, `kempston`, `menu` and 59 RZX
; segments); never written. The editable form is screens/panel.png (256 x 32,
; the attributes in the palette).
PanelPicture:
  INCBIN "res/screens/panel.bin",$0000,1152

  ORG $866A

; A life lost: BOOM and the red screen, a life bar hollowed, the level again or
; GAME OVER
;
; From PassEnd (`$85C6`) when LifeLost `$8ED3` is set (the overload bar full
; `$A6F0`, or the energy drained `$A67C`).
;
; SoundFlags = 0. When the COMPUTER line's MessageNumber `$A104` is below
; `$16`: message `$16` BOOM BOOM BOOM (MessageText = `$A15D`), PlaySound
; LifeLostSound, and the play area's 640 attributes (rows 0-19) = `$10` (black
; ink on red paper); then LoseLifeCount. With a message `$16` or above already
; shown (`$17` ENERGY DRAINED) LoseLifeDrained plays EnergyDrainedSound
; instead.
;
; Run 45 times: `mine`, `overload`, `gameover` (the red screen, `$8675` 41
; times) and `energy` (ENERGY DRAINED, `$869A` 4 times), and 36 lives lost over
; 26 RZX segments.
;
; Witness: L1 53 (energy, energy-out, gameover, hof, mine, overload, L45, L59,
; rzx x26).
LoseLife:
  XOR A
  LD (SoundFlags),A
  LD A,(MessageNumber)
  CP $16
  JR NC,LoseLifeDrained
  LD A,$16                ; BOOM BOOM BOOM
  LD (MessageNumber),A
  LD HL,BoomMessage
  LD (MessageText),HL
  LD HL,LifeLostSound
  CALL PlaySound
  LD HL,Attributes             ; the play area red: attributes $10
  LD DE,Attributes+1
  LD (HL),$10
  LD BC,$027F
  LDIR
  JR LoseLifeCount

; The PlaySound record of a life lost by drained energy: a falling sweep
;
; Type 1 (`$A85E`): B `$FE` (the half-period grows by 2 each note), C 2, D
; `$14`, 60 notes. Played by LoseLifeDrained `$869A`.
EnergyDrainedSound:
  DEFB $01,$FE,$02,$14,$3C

; The energy drained: the falling sweep, then the life taken (LoseLifeCount)
;
; From LoseLife when MessageNumber is `$16` or above. PlaySound
; EnergyDrainedSound, then LoseLifeCount `$86A0`:
;
; Not in practice: Lives `$837D` - 1, and the bar of that life (the new count
; n: columns 10 + 2n and 11 + 2n of row 21, lines 4-6) hollowed to `$40`, `$01`
; (its outline). Then 36 bursts of LifeLostSound, a Delay; lives left:
; SetUpLevel (the same level again); none: GAME OVER.
;
; GAME OVER: GameOverBanner (96 x 16 pixels) at columns 10-21 of rows 9-10, its
; 24 attributes white (7); a buzz (`$A843` with HL = `$C814`: `$C8` x 256 loops
; of two speaker counters a period apart); TitleLoop.
;
; Witness: L1 10 (energy, energy-out, hof, rzx053912, rzx227686).
LoseLifeDrained:
  LD HL,EnergyDrainedSound
  CALL PlaySound
; This entry point is used by the routine at LoseLife.
LoseLifeCount:
  LD A,(PracticeFlag)     ; practice: no life taken
  AND A
  JR NZ,LoseLifeSound
  LD A,(Lives)            ; Lives - 1 (the POKE `$86A9` of the trainers)
  DEC A
  LD (Lives),A
  LD HL,Screen+5290             ; the lost life's bar: column 10 + 2 x lives, row 21
                          ; lines 4-6
  ADD A,A
  ADD A,L
  LD L,A
  LD B,$03
LoseLifeHollow:
  LD (HL),$40
  INC L
  LD (HL),$01
  DEC L
  INC H
  DJNZ LoseLifeHollow
LoseLifeSound:
  LD B,$24                ; 36 bursts of LifeLostSound
LoseLifeSoundLoop:
  PUSH BC
  LD HL,LifeLostSound
  CALL PlaySound
  POP BC
  DJNZ LoseLifeSoundLoop
  CALL Delay
  LD A,(Lives)            ; lives left: the level again
  AND A
  JP NZ,SetUpLevel
  LD DE,Screen+2090             ; GAME OVER: the banner's top half to row 9, columns
                          ; 10-21
  LD HL,GameOverBanner
  LD A,$08
GameOverTop:
  LD BC,$000C
  LDIR
  LD E,$2A
  INC D
  DEC A
  JR NZ,GameOverTop
  LD DE,Screen+2122             ; the bottom half to row 10
  LD A,$08
GameOverBottom:
  LD BC,$000C
  LDIR
  LD E,$4A
  INC D
  DEC A
  JR NZ,GameOverBottom
  LD HL,Attributes+298             ; their attributes white
  LD B,$0C
GameOverAttrTop:
  LD (HL),$07
  INC L
  DJNZ GameOverAttrTop
  LD HL,Attributes+330
  LD B,$0C
GameOverAttrBottom:
  LD (HL),$07
  INC L
  DJNZ GameOverAttrBottom
  LD HL,$C814             ; a buzz, then the title
  CALL TwoTone
  JP TitleLoop

; The GAME OVER banner: 16 lines of 12 bytes (96 x 16 pixels), a frame round
; the words
;
; Drawn by LoseLifeDrained's game-over path (`$86D4`): lines 0-7 to row 9,
; lines 8-15 to row 10, columns 10-21, attributes 7. Read 3 times (`gameover`,
; `mine`, `overload`).
GameOverBanner:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; the frame's top line,
  DEFB $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01 ; then two blank lines
  DEFB $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
  DEFB $80,$07,$E7,$C7,$39,$FC,$03,$E6,$37,$F7,$E0,$01 ; GAME OVER, ten lines
  DEFB $80,$0F,$EF,$EF,$FD,$FC,$07,$F6,$37,$F7,$F0,$01
  DEFB $80,$0C,$0C,$6C,$CD,$80,$06,$36,$36,$06,$30,$01
  DEFB $80,$0C,$0C,$6C,$CD,$80,$06,$36,$36,$06,$30,$01
  DEFB $80,$0C,$0C,$6C,$CD,$FC,$06,$36,$37,$F7,$F0,$01
  DEFB $80,$0C,$EF,$EC,$CD,$FC,$06,$36,$37,$F7,$E0,$01
  DEFB $80,$0C,$EF,$EC,$CD,$80,$06,$37,$76,$07,$C0,$01
  DEFB $80,$0C,$6C,$6C,$CD,$80,$06,$33,$E6,$06,$E0,$01
  DEFB $80,$0F,$EC,$6C,$CD,$FC,$07,$F1,$C7,$F6,$70,$01
  DEFB $80,$07,$EC,$6C,$CD,$FC,$03,$E0,$87,$F6,$30,$01
  DEFB $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01 ; two blank lines and
  DEFB $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01 ; the frame's bottom
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; line

  ORG $88B0

; The panel's LEVEL digits: 11 glyphs of 8 x 8 pixels, 0-9 and P
;
; SetUpLevel `$843C` draws two of them (tens, units) at columns 6 and 7, from
; line 4 of row 20 to line 3 of row 21. P is the tens glyph of the practice
; levels (P1-P3).
LevelDigits:
  DEFB $7C,$FE,$C6,$C6,$C6,$C6,$FE,$7C ; 0
  DEFB $18,$38,$38,$18,$18,$18,$3C,$3C ; 1
  DEFB $FC,$FE,$06,$7E,$FC,$C0,$FE,$FE ; 2
  DEFB $FC,$FE,$06,$FC,$FE,$06,$FE,$FC ; 3
  DEFB $C0,$C0,$CC,$CC,$FE,$FE,$0C,$0C ; 4
  DEFB $FE,$FE,$C0,$FC,$FE,$06,$FE,$FC ; 5
  DEFB $7E,$FE,$C0,$FC,$FE,$C6,$FE,$7C ; 6
  DEFB $FC,$FE,$06,$0E,$0C,$1C,$18,$38 ; 7
  DEFB $7C,$FE,$C6,$7C,$FE,$C6,$FE,$7C ; 8
  DEFB $7C,$FE,$C6,$FE,$7E,$06,$FE,$FC ; 9
  DEFB $FC,$FE,$C6,$FE,$FC,$C0,$C0,$C0 ; P

  ORG $9AF1

; Two bytes ($06, $04) no code reads
;
; No recording reads or writes them (`work/ann/02-beam/rw.py`).
Unused9AF1:
  DEFB $06,$04

; Add B tens to the score, then print it
;
; The score is ASCII digits in ScoreText (`$9B3E`-`$9B43`, the last a fixed
; "0": points come in tens). B times, the tens digit `$9B42` goes up by one
; with the carry to the left (a space counts as 0). Callers: the cells burnt
; (`$8F64`, B = `$18` or the value patched at `$8F63`), gremlins (`CursorFire`
; `$9A57`, 16 a gremlin), the receiver opening when the last cell is gone
; (`$85EC`, 25), the level's end bonuses (`$8808` one ten a step, `$884A` 50 a
; step: fragment 01). 21 897 runs over the 60 RZX segments. Falls into
; `PrintScore`.
;
; Witness: L1 31617 (ending, hof, L x20, rzx x60).
AddScore:
  LD HL,ScoreDigits+$0004
AddScoreDigit:
  LD A,(HL)               ; a space counts as 0
  CP $20
  JR NZ,AddScoreCarry
  LD A,$30
AddScoreCarry:
  INC A                   ; past 9: 0 and carry to the left
  CP $3A
  JR C,AddScoreNext
  LD (HL),$30
  DEC HL
  JR AddScoreDigit
AddScoreNext:
  LD (HL),A
  DJNZ AddScore

; Print the score right-aligned on the panel
;
; From the last digit `$9B43` leftwards to the first space, right to left from
; `$53BF` (`PrintDigitsBack` `$9B10`). Called by `AddScore` and the level
; set-up (`$850C`).
;
; Witness: L1 4957 (c1, c1g, cheat, controls, ending, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x60).
PrintScore:
  LD DE,Screen+5055
  LD BC,$9B43

; Print the characters at BC leftwards from screen address DE until a space
;
; Each character: rows 2-6 of its glyph (`$D202` + 8 x (character - 32)), five
; pixel rows down from DE; then DE one column left, BC one character back. Used
; for the score and the high score (`PrintHighScore` `$9B53`).
;
; Witness: L1 33219 (c1, c1g, cheat, controls, ending, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x60).
PrintDigitsBack:
  LD A,(BC)
  CP $20
  RET Z
  PUSH BC
  SUB $20
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$D202
  ADD HL,BC
  LD C,D
  LD B,$05
PrintDigitRows:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ PrintDigitRows
  LD D,C
  DEC E
  POP BC
  DEC BC
  JR PrintDigitsBack

; Clear the score kept at the level's start
;
; Five spaces at `$9B44`-`$9B48`: the level set-up (`$84EB`) copies them to the
; score digits `$9B3E`, so a new game or practice starts at 0. Called at a new
; game (`$842F`) and for practice (`$84DE`).
;
; Witness: L1 11 (c1, c1g, controls, energy, energy-out, kempston, menu, L01).
ClearSavedScore:
  LD HL,SavedScore
  LD B,$05
ClearSavedScoreLoop:
  LD (HL),$20
  INC HL
  DJNZ ClearSavedScoreLoop
  RET

; The score, the score at the level's start and the high score, as ASCII digits
;
; `$9B3B`-`$9B3D` three spaces stop `PrintScore`; ScoreDigits `$9B3E`-`$9B43`
; the score (the last "0" never changes). SavedScore `$9B44`-`$9B48`: the score
; when the level was entered, copied back to the score by the level set-up
; (`$84EB`): a life lost takes away the points of the unfinished level; written
; at a level's end by `$8865`. `$9B49` ("0") is never read. HighScoreText
; `$9B4A`-`$9B52`: three spaces, then the hall of fame's top score with its
; leading zeros made spaces (`PrintHighScore` `$9B53`), the last "0" fixed.
ScoreText:
  DEFB $20,$20,$20        ; spaces: the end of the printed score
ScoreDigits:
  DEFB $20,$20,$20,$20,$20,$30 ; the score, six digits, the last always 0
SavedScore:
  DEFB $20,$20,$20,$20,$20 ; the score at the level's start, five digits
  DEFB $30                ; "0", never read
HighScoreText:
  DEFB $20,$20,$20,$20,$20,$20,$20,$20,$30 ; spaces, then the high score's
                                           ; digits

; Print the hall of fame's top score on the panel as HIGH
;
; Copies the first score of the hall of fame (`$9FEE`, five digits, leading
; zeros turned to spaces) to `$9B4D`-`$9B51` and prints `$9B52` leftwards from
; `$53FF`. Called by the level set-up (`$850F`); 164 runs over all recordings.
;
; Witness: L1 196 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston,
; menu, mine, overload, L x20, rzx x59).
PrintHighScore:
  LD DE,HallOfFameScores+$0003
  LD HL,HighScoreText+$0003
  LD BC,$0005
PrintHighScoreZero:
  LD A,(DE)               ; a leading 0: a space
  CP $30
  JR NZ,PrintHighScoreRest
  LD (HL),$20
  INC DE
  INC HL
  DEC C
  JR NZ,PrintHighScoreZero
  JR PrintHighScorePrint
PrintHighScoreRest:
  EX DE,HL                ; the rest as it is
  LDIR
PrintHighScorePrint:
  LD DE,Screen+5119
  LD BC,$9B52
  JP PrintDigitsBack

  ORG $A103

; $FF: the interrupt runs the menu's scroller (row 21) and counts nothing; 0:
; the game's COMPUTER line
;
; Set by the menu set-up `$9BC0` (at `$9BC7`), cleared by OptionsMenu `$A757`
; when a game starts (`$A804`). While set, InterruptHandler `$A32A` jumps to
; MenuScrollerTick `$A459` and neither EnergyTick `$A506` nor FrameCounter
; `$837F` is counted. Evidence: read by every interrupt (381 862 in all
; recordings), written 19 times.
MenuScroller:
  DEFB $00

; The number of the message shown: 0 none ... $18 CONTACT!; a message replaces
; a lower one only
;
; Each writer compares first (`CP n` / `JR NC`) and writes only when the
; current number is lower, so a more urgent message is never replaced by a less
; urgent one: 1 CHARGING LASER / DEMO (ResetBars `$A55E`), 4 BEWARE OF THE
; GREMLINS (`$AC21`), `$0A` ENERGY LOW (`$A665`), `$0C` ENERGY LEVEL CRITICAL
; (`$A62F`), `$12` OVERLOAD (`$A6BD`), `$13` MINE ALERT (`$A68B`), `$14` GAME /
; DEMO ABORTED (`$9816`), `$16` BOOM BOOM BOOM (`$8677`), `$17` ENERGY DRAINED
; (`$A671`), `$18` CONTACT! (`$87DA`, the beam has reached the receiver). 0
; again when a scrolling message runs back into BlankMessage (`$A3F0`) or the
; overload stops (`$A708`).
;
; The pause `$973F` saves the 14 bytes MessageNumber to MessagePointer
; (`$A104-$A111`) to `$96C7` and puts them back (`$97DD`). Evidence: `energy`
; (`tools/ttd_watch.py`): 1 at frame 500, `$0A` at 5000, `$0C` at 5750, `$17`
; at 6450.
MessageNumber:
  DEFB $00

; The character being scrolled in: its 8 font bytes; rows 2-6 ($A107-$A10B) are
; shifted out a bit a frame
;
; Filled by `LDIR` from the font (`$D200 + 8 x (c - 32)`) at `$A405` / `$A4E2`;
; each scroll step rotates rows 2-6 left (`RLA`) and the carry goes into the
; line's rightmost byte. Rows 0, 1 and 7 are copied but never shifted (the line
; shows 5 pixel rows).
MessageGlyph:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The scroller's state: 0-7 the pixel within a scrolling character; $E6-$FF a
; static message's blink phase
;
; Scrolling: counts 0 to 8; at 8 the next character is loaded (`$A3D3`,
; `$A490`). Static: `$E6-$EF` the line blank, `$F0` the text drawn, `$F1-$FE`
; shown, `$FF` the line cleared and back to `$E6` (`$A36E`): 15 frames on, 10
; off.
MessageState:
  DEFB $00

; The next message: the game writes its address here; the interrupt takes it
; and clears the high byte
;
; A message is pending while the high byte (`$A10F`) is not 0 (every message
; lies at `$A1xx-$A2xx`). The interrupt copies the word to MessagePointer and
; writes 0 to `$A10F` (`$A35B`, `$A45F`). Writers: SetupInterrupts
; (BlankMessage), `$8435`, ResetBars, `$A5F7`, DrainEnergy, UpdateOverload,
; GremlinAppear, `$867D`, `$87E0`, `$97B4`, `$9822`, `$9BF6`, `$9CB4`,
; OptionsMenu.
MessageText:
  DEFW $0000

; The text being shown: the next character of a scrolling message, or the $FE
; of a static one
MessagePointer:
  DEFW BlankMessage

; Static: ",,,, DEMO ,,,," (MessageNumber 1, ResetBars on demo level 0)
;
; 14 characters after the `$FE` static mark; `,` is a small ring in the font
; (`$D260`), `.` a small diamond. Evidence: read in `menu` (the demo).
DemoMessage:
  DEFM $FE,",,,, DEMO ,,,,"

; Static: "CHARGING LASER" (MessageNumber 1, ResetBars)
;
; Shown at each level start while the energy bar fills. Evidence: `energy`
; frame 500; every recording that started a level.
ChargingMessage:
  DEFM $FE,"CHARGING LASER"

; Static: " . OVERLOAD . " (MessageNumber $12, the beam back in the laser)
;
; Evidence: `overload`; read in `mine` and 54 RZX segments.
OverloadMessage:
  DEFM $FE," . OVERLOAD . "

; Static: ". MINE ALERT ." (MessageNumber $13, the beam on a mine)
;
; Evidence: `mine`; 46 RZX segments.
MineAlertMessage:
  DEFM $FE,". MINE ALERT ."

; Static: "ENERGY DRAINED" (MessageNumber $17, EnergyDrained $A66F)
;
; Evidence: `energy` (twice), `rzx-053912`, `rzx-227686`.
DrainedMessage:
  DEFM $FE,"ENERGY DRAINED"

; Static: "BOOM BOOM BOOM" (MessageNumber $16, a life lost: $867A)
;
; Evidence: `mine`, `overload`, `gameover` and the RZX segments that lost a
; life.
BoomMessage:
  DEFM $FE,"BOOM BOOM BOOM"

; Static: "   CONTACT!   " (MessageNumber $18, the beam reached the receiver:
; $87DD)
;
; Shown by `$87D4` when LevelDone `$8ED2` is set, the level complete. Evidence:
; read in all 60 RZX segments (each reaches the end of a level in the RZX's own
; run).
ContactMessage:
  DEFM $FE,"   CONTACT!   "

; Static: " GAME ABORTED " (MessageNumber $14, U + G: $9811)
;
; Evidence: `controls`, `kempston`, `menu`.
GameAbortedMessage:
  DEFM $FE," GAME ABORTED "

; Static: " DEMO ABORTED " (the same key in the demo: $981F)
;
; The 14 characters end at `$A198`; BlankMessage follows.
DemoAbortedMessage:
  DEFM $FE," DEMO ABORTED "

; Scrolling: two spaces, then back to itself: the line runs empty; reaching it
; ends a message (MessageNumber 0)
;
; The "no message" message: SetupInterrupts, `$8435`, the end of charging
; (`$A602`), the overload stopping (`$A70B`), `$9BF3`. The scroller compares
; every `$FF` jump with this address (`$A3E7`) and clears MessageNumber when it
; is taken.
BlankMessage:
  DEFM "  "
  DEFM $FF                ; $FF, then the address where the text goes on

; BlankMessage again
BlankMessageLoop:
  DEFW BlankMessage

; Scrolling: ",,,BEWARE OF THE GREMLINS!,,," (MessageNumber 4, GremlinAppear),
; once
;
; Evidence: read in 51 RZX segments (the levels with gremlins).
GremlinsMessage:
  DEFM ",,,BEWARE OF THE GREMLINS!,,,"
  DEFM $FF                ; $FF

; then BlankMessage: shown once
GremlinsMessageLoop:
  DEFW BlankMessage

; Scrolling: "---WARNING-----ENERGY LOW---" (MessageNumber $0A, two bar bytes
; left), once
;
; Evidence: `energy` frame 5000; 17 RZX segments.
EnergyLowMessage:
  DEFM "---WARNING-----ENERGY LOW---"
  DEFM $FF                ; $FF

; then BlankMessage
EnergyLowMessageLoop:
  DEFW BlankMessage

; Scrolling: "---WARNING---ENERGY LEVEL CRITICAL-", repeated (MessageNumber
; $0C, one bar byte left)
;
; Evidence: `energy` frame 5750; 11 RZX segments.
EnergyCriticalMessage:
  DEFM "---WARNING---ENERGY LEVEL CRITICAL-"
  DEFM $FF                ; $FF

; back to its own start: it repeats until another message
EnergyCriticalLoop:
  DEFW EnergyCriticalMessage

; The menu scroller's text: "DEFLEKTOR , WRITTEN BY COSTA PANAYI ... SELECT
; OPTION ,,, ", a pause, again
;
; Set by OptionsMenu `$A757` (`$A76E`). `@` is the copyright sign in the font
; (`$D300`). Text: DEFLEKTOR , WRITTEN BY COSTA PANAYI , WITH HELP FROM THE
; ALIEN , MUSIC BY BEN AND JOBBEE , @1987 VORTEX SOFTWARE ,,, SELECT OPTION ,,,
;
; Evidence: read in `c1g`, `controls`, `kempston`, `menu`, `energy`; the whole
; text and the pause only in `controls` (the longest wait on the panel).
CreditsMessage:
  DEFM "DEFLEKTOR , WRITTEN BY COSTA PANAYI , WITH HELP FROM THE ALIEN , "
  DEFM "MUSIC BY BEN AND JOBBEE , @1987 VORTEX SOFTWARE ,,, SELECT OPTION"
  DEFM " ,,, "
CreditsPause:
  DEFM "~"+$80            ; $FE: a pause of 124 frames, counted down in place
                          ; ($A4B5); OptionsMenu writes $FE back ($A769)
  DEFM $FF                ; $FF

; back to the start
CreditsLoop:
  DEFW CreditsMessage

; The name-entry prompt: "HIGH DEFLEKTOR RATING ", a pause, ", PLEASE ENTER
; YOUR NAME , ", again
;
; Set by `$9CB4` for a hall-of-fame entry, which writes `$FE` to the pause
; first (`$9CAE`). Evidence: `rzx-344752` (the RZX player's entry).
HighRatingMessage:
  DEFM "HIGH DEFLEKTOR RATING "
RatingPause:
  DEFM $FE,", PLEASE ENTER YOUR NAME , " ; $FE: the pause, as CreditsPause
  DEFM $FF                ; $FF

; back to the start
HighRatingLoop:
  DEFW HighRatingMessage

; The pause (P): ",,, PRESS ENTER FOR MORE ACTION ,,,,,, INTERMISSION ",
; repeated
;
; Set by `$97B1`; the pause `$973F` first prints "INTERMISSION" itself
; (`$972B`) on the line. Evidence: `controls`.
IntermissionMessage:
  DEFM ",,, PRESS ENTER FOR MORE ACTION ,,,,,, INTERMISSION "
  DEFM $FF                ; $FF

; back to the start
IntermissionLoop:
  DEFW IntermissionMessage

  ORG $A50C

; The HUD panel: 1024 pixel bytes from $7B80 to rows 20-23 and 128 attributes
; from $7F80
;
; DE = `$5080`, HL = `$7B80`: 32 bytes a pixel row, 8 rows a character row (D +
; 1 until bit 3 is set), then E + 32 for the next of the four character rows
; 20-23 (E = `$80`, `$A0`, `$C0`, `$E0`; done when it wraps to 0). Then 128
; bytes to the attributes `$5A80-$5AFF`. So the picture at `$7B80` (the brief's
; OptionsPanel) is the play panel (LEVEL, LIVES, OVERLOAD, ENERGY, SCORE, HIGH,
; COMPUTER), 1024 + 128 bytes ending at `$7FFF`.
;
; Called by `$8432` at each new game and level start. Evidence: 67 runs (`c1g`,
; `controls`, `energy`, `kempston`, `menu`, 59 RZX segments).
;
; Witness: L1 90 (c1, c1g, controls, energy, energy-out, hof, kempston, menu, L
; x20, rzx x59).
DrawPanel:
  LD DE,Screen+4224
  LD HL,PanelPicture
DrawPanelRowLoop:
  LD BC,$0020
  PUSH DE
  LDIR
  POP DE
  INC D
  BIT 3,D
  JR Z,DrawPanelRowLoop
  LD D,$50                ; the next character row: E + 32
  LD A,$20
  ADD A,E
  LD E,A
  JR NZ,DrawPanelRowLoop
  LD DE,Attributes+640             ; the attributes, rows 20-23
  LD BC,$0080
  LDIR
  RET
