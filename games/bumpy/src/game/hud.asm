; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The timer, lives, score, HUD, game over and hall of fame
;
; The HUD's attribute repaint, the level timer and the loss of a life.
;
; The status line is screen lines 1-7 (line-table entry 8): six fields printed with the font's digits and the icons
; 123-127 by PrintDigit and HudBlit, at the column in $AB18, which each character advances.
; --------------------------------------------------------------------------------------------------------------------

  ORG $B6EE

; Repaint the attributes of the HUD row and of column 30
;
; Copies the 20 bytes of HudRowAttrs $B730 to the top attribute row from $5803,
; in groups of 5, 3, 3, 3, 3 and 3 with one or two cells skipped between them
; (the cells between the HUD's fields keep their colour), then writes 6 (yellow
; on black) down column 30 ($581E, 24 rows). Called by $E58B every frame, so
; whatever the CPC-style drawing leaves in those cells is put right once a
; frame.
;
; Witness: L1 95989 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PaintHudAttrs:
  LD HL,HudRowAttrs
  LD DE,$5803
  LDI
  LDI
  LDI
  LDI
  LDI
  INC DE
  LDI
  LDI
  LDI
  INC DE
  INC DE
  LDI
  LDI
  LDI
  INC DE
  LDI
  LDI
  LDI
  INC DE
  LDI
  LDI
  LDI
  INC DE
  LDI
  LDI
  LDI
  INC DE
  EX DE,HL                ; HL = the attribute cell after the last group: row
                          ; 0, column 30
  LD DE,$0020
  LD B,$18
  LD A,$06
PaintColumn30:
  LD (HL),A               ; 24 rows, 32 bytes apart
  ADD HL,DE
  DJNZ PaintColumn30
  RET

; The attributes of the HUD row (top line), read by PaintHudAttrs
;
; 20 attributes: 5 of $07 (white on black) for $5803-$5807, then five groups of
; three, each one coloured icon cell ($46 bright yellow, $45 bright cyan, $45,
; $46, $42 bright red) and two white digits. Each group is the icon and number
; of one HUD field (known only from the code which field is which: $E5A1-$E5F9
; print them).
;
; Three $C9 (RET) bytes no code reads or runs: part of the row of RET stubs
; that ends at $B754 (see FirmwareStub $B747).
HudRowAttrs:
  DEFB $07,$07,$07,$07,$07,$46,$07,$07,$45,$07,$07,$45,$07,$07,$46,$07
  DEFB $07,$42,$07,$07
HudRowAttrsEnd:
  DEFB $C9,$C9,$C9        ; three unread $C9 bytes before FirmwareStub

  ORG $B7D1

; Count the level timer down by one frame, stopping at 0
;
; The level timer $AB04 (a word, 1000 = $03E8 at each level start, $AC06) goes
; down by one each frame MainLoop runs ($ACE4) and stops at 0. Nothing here
; acts on 0: the timer only sets the bonus the level end ($B35F) adds to the
; score. 1000 frames are 20 seconds.
;
; Witness: L1 92279 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
TickTimer:
  LD HL,(Timer)
  LD A,H
  CP $00
  JR Z,TickTimerLowByte
TickTimerDec:
  DEC HL
  LD (Timer),HL
  RET
TickTimerLowByte:
  LD A,L                  ; high byte 0: stop at 0
  CP $00
  RET Z
  JR TickTimerDec

  ORG $BA71

; The S key: burst the ball (in the demo, back to the main loop)
;
; Jumped to from the state handlers ($AE7F, $AEF6, $AF70, $AFF0, $B085, $B133)
; when the key $31 (S) is down. In the demo ($ABA6 not 0) it jumps back to
; MainLoop $ACC8 and nothing happens. With $ADDD not 0 (never: $ADDF is a RET
; before the store that would set it) a disabled level select runs:
; FirmwareStub5 $B754, then Level = L reduced below 100 by steps of 97. Then
; the death sound $F4CB and LoseLife.
;
; Witness: L1 12 (gameover, twoname).
SelfDestruct:
  LD A,(DemoFlag)
  CP $00
  JP NZ,MainLoop
  LD A,(CheatMode)
  CP $00
  JR Z,SelfDestructSound
SelfDestructLevelSelect:
  CALL FirmwareStub5      ; dead code
  LD A,L
SelfDestructReduce:
  CP $64
  JR C,SelfDestructSetLevel
  SUB $61
  JR SelfDestructReduce
SelfDestructSetLevel:
  AND A
  LD (Level),A
SelfDestructSound:
  CALL SfxLifeLost

; The ball is lost: one life less, the level restarts (or game over, or the
; other player)
;
; Lives $AB01 = 0: GameOver $B755. Else lives - 1; Water, Keys and Hammers go
; back to their values at the level start ($AB06-$AB08); the 7 bytes score,
; water, keys, hammers, level and lives ($AAFB-$AB01) are saved in the player's
; record ($AB09 player 1, $AB10 player 2, by $ADDB). With two players ($ADDC =
; 2) the turn passes to the other player unless his record's lives byte is $FA
; (out): $ADDB = 1 or 2. Then 50 frames (WaitOneFrame), WaitKeyOrSecond, and JP
; $ABD8, which starts the level of the player whose turn it is. Entered from
; the burst death ($B1D1), the fall below the screen ($B2B5) and SelfDestruct.
; Witness: 27 runs (gameover, rzx x11): 25 lives lost, 2 game overs; the turn
; change is known only from the code.
;
; Witness: L1 34 (fire, gameover, twoname, rzx x11).
LoseLife:
  LD A,(Lives)
  CP $00
  JP Z,GameOver
  DEC A
  LD (Lives),A
  LD A,(WaterAtStart)
  LD (Water),A
  LD A,(KeysAtStart)
  LD (Keys),A
  LD A,(HammersAtStart)
  LD (Hammers),A
  LD DE,Player1Record
  LD A,(CurrentPlayer)
  CP $01
  JR Z,LoseLifeSave
  LD DE,Player2Record
LoseLifeSave:
  LD HL,Score
  LD BC,$0007
  LDIR
  LD A,(PlayerCount)
  CP $01
  JR Z,LoseLifeWait
  LD A,(CurrentPlayer)
  CP $01
  JR Z,LoseLifePlayer1
  LD IX,Player1Record
  LD A,(IX+$06)
  CP $FA
  JR Z,LoseLifeWait
; This entry point is used by the routine at GameOver.
SwitchToPlayer1:
  LD A,$01
  LD (CurrentPlayer),A
  JR LoseLifeWait
LoseLifePlayer1:
  LD IX,Player2Record     ; player 1 was in play: is player 2 out?
  LD A,(IX+$06)
  CP $FA
  JR Z,LoseLifeWait

; SwitchToPlayer2
;
; Used by the routine at GameOver.
SwitchToPlayer2:
  LD A,$02
  LD (CurrentPlayer),A

; LoseLifeWait
;
; Used by the routine at LoseLife.
LoseLifeWait:
  LD B,$32
LoseLifeWaitLoop:
  PUSH BC
  CALL WaitOneFrame
  POP BC
  DJNZ LoseLifeWaitLoop
  CALL WaitKeyOrSecond
  JP LifeStart

  ORG $E58B

; Redraw the whole status line
;
; Calls $B6EE, then ScoreToHud, LivesToHud, HammersToHud, WaterToHud, KeysToHud
; and LevelToHud. Called from the main loop ($ACB0, $ACC2) and the frame wait
; ($B6E6).
;
; Witness: L1 95989 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
DrawHud:
  CALL PaintHudAttrs
  CALL ScoreToHud
  CALL LivesToHud
  CALL HammersToHud
  CALL WaterToHud
  CALL KeysToHud
  CALL LevelToHud
  RET

; Print the score: five digits at column 3
;
; The score word $AAFB as five digits (PrintNumber5), columns 3-7.
;
; Witness: L1 96679 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
ScoreToHud:
  LD A,$03
  LD (HudColumn),A
  LD HL,(Score)
  CALL PrintNumber5
  RET

; Print the lives: icon 123 and two digits at column 9
;
; Icon character $7B at column 9, then the low byte of $AB01 as two digits
; (PrintNumber2).
;
; Witness: L1 96009 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
LivesToHud:
  LD A,$09
  LD (HudColumn),A
  LD HL,(Lives)
  LD H,$00
  LD A,$7B
  CALL PrintHudIcon
  CALL PrintNumber2
  RET

; Print the water drops: icon 124 and two digits at column 14
;
; Icon $7C at column 14, then the byte $AAFD as two digits.
;
; Witness: L1 96110 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
WaterToHud:
  LD A,$0E
  LD (HudColumn),A
  LD HL,(Water)
  LD H,$00
  LD A,$7C
  CALL PrintHudIcon
  CALL PrintNumber2
  RET

; Print the keys: icon 125 and two digits at column 18
;
; Icon $7D at column 18, then the byte $AAFE as two digits.
;
; Witness: L1 96372 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
KeysToHud:
  LD A,$12
  LD (HudColumn),A
  LD HL,(Keys)
  LD H,$00
  LD A,$7D
  CALL PrintHudIcon
  CALL PrintNumber2
  RET

; Print the hammers: icon 126 and two digits at column 22
;
; Icon $7E at column 22, then the byte $AAFF as two digits.
;
; Witness: L1 96104 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
HammersToHud:
  LD A,$16
  LD (HudColumn),A
  LD HL,(Hammers)
  LD H,$00
  LD A,$7E
  CALL PrintHudIcon
  CALL PrintNumber2
  RET

; Print the level: icon 127 and two digits at column 26
;
; Icon $7F at column 26, then Level $AB00 as two digits: the number shown is
; the level's index 0-99 as stored.
;
; Witness: L1 95991 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
LevelToHud:
  LD A,$1A
  LD (HudColumn),A
  LD HL,(Level)
  LD H,$00
  LD A,$7F
  CALL PrintHudIcon
  CALL PrintNumber2
  RET

; Print HL as five decimal digits
;
; PrintDigit for 10000, 1000 and 100, then falls into PrintNumber2. Also called
; by $B37A (the score while the timer is counted in).
;
; Witness: L1 102196 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PrintNumber5:
  LD DE,$2710
  CALL PrintDigit
  LD DE,$03E8
  CALL PrintDigit
  LD DE,$0064
  CALL PrintDigit

; Print HL's tens and units
;
; PrintDigit for 10 and 1. A value of 100 or more gives a tens "digit" past 9
; (the glyph after "9"); the callers pass bytes below 100 (known only from the
; code).
;
; Witness: L1 582784 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PrintNumber2:
  LD DE,$000A
  CALL PrintDigit
  LD DE,$0001
  CALL PrintDigit
  RET

; Print HL div DE as one digit and keep HL mod DE
;
; Input: HL the value, DE the power of ten. C counts the subtractions; HL is
; left with the remainder; the glyph is Font + 8 x (C + 16) ($F649, "0"), drawn
; by PrintHudGlyph.
;
; Witness: L1 1472156 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PrintDigit:
  LD C,$00
PrintDigitLoop:
  AND A
  SBC HL,DE
  JR C,PrintDigitSkip
  INC C
  JR PrintDigitLoop
PrintDigitSkip:
  ADD HL,DE
  LD DE,Font+$0080

; Draw glyph C of the table at DE on the status line
;
; HL = DE + 8 x C, then HudBlit. HL is kept.
;
; Witness: L1 1952742 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PrintHudGlyph:
  PUSH HL
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD BC,$07FF

; Copy glyph rows 0-6 at HL to the status line at column ($AB18), then advance
; the column
;
; Rows go to screen lines 1-7 (line-table entry 8, $B53D, then INC D for each
; line); glyph row 7 is not drawn. No attribute is written. $AB18 + 1.
;
; Witness: L1 1952744 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
HudBlit:
  LD IX,SpectrumLines+$0010
  LD D,(IX+$01)
  LD A,(HudColumn)
  OR (IX+$00)
  LD E,A
HudBlitLoop:
  LDI
  DEC DE
  INC D
  DJNZ HudBlitLoop
  LD A,(HudColumn)
  INC A
  LD (HudColumn),A
  POP HL
  RET

; Draw character A of the font on the status line
;
; DE = $F4C9 (Font - 256, so that 8 x A lands on the character), C = A, then
; PrintHudGlyph.
;
; Witness: L1 480586 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PrintHudIcon:
  LD DE,SfxSpikeDeathParams+$000E
  LD C,A
  JR PrintHudGlyph
