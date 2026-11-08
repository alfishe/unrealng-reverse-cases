; --------------------------------------------------------------------------------------------------------------------
; zoneend.asm: The end of a zone: the bonuses, the bonus screen, CONGRATULATIONS
; --------------------------------------------------------------------------------------------------------------------

; The zone's end: the player at the end marker gets the lives and bravery
; bonuses, then the bonus screen
;
; Main loop ($7644). ZoneEndList holds the marker (tile 16) of the screens 24,
; 49, 74, 99 and 124 (the last of each zone of 25). When the player's X reaches
; the marker's (column x 4): ZoneBonusText (the panel BRAVERY BONUS 00000 /
; LIVES BONUS X 1000), the lives digit at row 12 column 13, the lives x 1000
; points; when ExoSuit is 0 (the zone done without the exoskeleton), "1" at row
; 8 column 14 makes the bravery figure 10000 and 80 x 125 points are added with
; a click each (the count runs up on the HUD). Then RoundEnd.
;
; Warp runs: 9 runs (the starts 24, 49, 74, 99, 124 and the runs that walked
; into them) reached BonusScreen.
ZoneEnd:
  LD DE,(ZoneEndList)
  BIT 7,E
  RET NZ
  CALL CellToPixels
  LD A,(PlayerX)
  CP E
  RET C
  LD HL,ZoneBonusText
  CALL PrintString
  LD A,(Lives)
  LD B,A
  ADD A,$30
  LD DE,$0C0D
  LD C,$46
  CALL PrintChar
  LD DE,Points1000+$0005
ZoneEndLives:
  CALL AddScore           ; lives x Points1000
  DJNZ ZoneEndLives
  LD A,(ExoSuit)
  OR A
  JR NZ,RoundEnd
  LD C,$47
  LD A,$31
  LD DE,$080E
  CALL PrintChar
  LD BC,$0050
ZoneEndBravery:
  PUSH BC                 ; 80 x 125 = 10 000
  LD DE,Points125+$0005
  CALL AddScore
  LD B,$3C
  CALL BeeperNoise
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,ZoneEndBravery
RoundEnd:
  LD A,(ScreenNumber)     ; screen 124 ($7C): the CONGRATULATIONS screen and
                          ; the screen number $FF (the next is 0)
  CP $7C
  JR NZ,ZoneEndBonusScreen
  LD BC,$0000
  CALL Delay
  CALL Delay
  CALL ClearScreen
  LD HL,CongratulationsText
  CALL PrintString
  LD A,$FF
  LD (ScreenNumber),A
  LD BC,$0000
  CALL Delay
  CALL Delay
  CALL Delay
  CALL Delay
ZoneEndBonusScreen:
  CALL BonusScreen
  LD HL,StrayReti         ; HL = $768E (not used after)
  LD A,(Lives)
  CP $09                  ; nine lives: no more
  JR NC,ZoneRefill

; One life more at a zone's end, when below nine (never ran)
;
; The fall-through of the JP NC at $A89F: one more life when below nine. No
; recording ran it: the warp runs that reached a zone's end all had the lives
; POKE (nine lives).
ZoneAddLife:
  INC A
  LD (Lives),A            ; the lives

; The next zone: the suit off, 99 ammunition, 10 grenades, the next screen
; built, the HUD, the player at the zone's start
;
; ExoSuit = 0, $8E5A = 99, $8E66 = 10; $8253 with A = $88 (the player's Y $88
; for now, the screen number + 1: 25, 50, 75, 100, or 0 after RoundEnd's $FF),
; $8485 builds it, $7690 the HUD; $82F7 = 0; ZoneStarts gives the start X, Y of
; the new screen into $82F5 (the player) and $82F3 (the restart point).
ZoneRefill:
  XOR A
  LD (ExoSuit),A
  LD A,$63
  LD (Ammo),A
  LD A,$0A
  LD (Grenades),A
  LD A,$88
  CALL NextScreen
  CALL ScreenChangeCheck
  CALL DrawHud
  XOR A
  LD (JumpStep),A
  LD HL,ZoneStarts
  LD A,(ScreenNumber)
  LD B,A
ZoneRefillFind:
  LD A,(HL)
  CP B
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  JR NZ,ZoneRefillFind
  LD (PlayerX),DE
  LD (RestartX),DE
  RET

; The bonus screen: a "*" steps down eight lines until fire; the odd lines pay
; 1000, 3000, 5000, 7000
;
; Six DelayBC of 65 536 (about 2.4 s; the zone's panel stays up 133 frames in
; w/124, from RoundEnd to BonusScreen), ClearScreen, BonusScreenText,
; WaitNoKey, a delay; then each round BonusPointer + 1, "*" ($2A, white) at row
; 13 + (BonusPointer AND 7), column 22, a space over the line before,
; ReadControls $7B72, DelayBC 6000; fire ($7B96) stops it. BonusPointer AND 7
; odd: that many x 1000 points (the lines read 00000, 01000, 00000, 03000, ...:
; the odd ones are what they say). BonusPointer is never reset: the pointer
; goes on from where it stopped. 9 warp runs.
BonusScreen:
  LD HL,FontBase
  LD (PrintChar+$000E),HL
  LD BC,$0000
  CALL Delay
  CALL Delay
  CALL Delay
  CALL Delay
  CALL Delay
  CALL Delay
  CALL ClearScreen
  LD HL,BonusScreenText
  CALL PrintString
  CALL WaitNoKey
  LD BC,$0000
  CALL Delay
BonusScreenStep:
  LD A,(BonusPointer)
  INC A
  LD (BonusPointer),A
  AND $07
  ADD A,$0D
  LD D,A
  LD E,$16
  LD C,$47
  LD A,$2A
  CALL PrintChar
  LD A,(BonusPointer)
  DEC A
  AND $07
  ADD A,$0D
  LD D,A
  LD E,$16
  LD C,$47
  LD A,$20
  CALL PrintChar
  CALL ReadControls
  LD BC,$1770
  CALL Delay
  LD A,(ControlFire)
  OR A
  JP Z,BonusScreenStep
BonusScreenStopped:
  LD BC,$0000
  CALL Delay
  CALL Delay
  CALL Delay
  LD A,(BonusPointer)
  AND $01
  RET Z
  LD A,(BonusPointer)
  AND $07
  LD B,A
  LD DE,Points1000+$0005  ; Points1000
BonusScreenAdd:
  CALL AddScore           ; 1000 points a time, B times
  DJNZ BonusScreenAdd
  RET

; The bonus screen's pointer, + 1 a step, never reset (its line = AND 7)
BonusPointer:
  DEFB $00

; The bonus screen: the frame and title, EXOLON BONUS SCREEN!, PRESS FIRE TO
; STOP POINTER, the 8 lines
;
; The same frame as HofEntryText (PanelBar, PanelCorner, the side columns, the
; title $70FF); EXOLON BONUS SCREEN! (8,6, bright white), PRESS FIRE TO STOP
; POINTER (10,3, bright green), from 13,9 the lines 00000 POINTS (bright
; yellow) and 01000, 03000, 05000, 07000 POINTS (bright cyan) in turn.
BonusScreenText:
  DEFM $E6,$E0,$EC,$DF,$00,$00,$E3,$10,$A2,$DF,$02,$00,$E1,$0A,$DC,$04,$D4,$05,$AD,$DC,$06,$D4,$07,$AD,$E2,$E3,$10,$A2,$DF,$02,$1E,$E1,$0A,$DC,$04,$D4,$05,$AD,$DC,$06,$D4,$07,$AD,$E2,$DF,$03,$08,$E3,$FF,"p"
  DEFM $E6,$E0,$D7,$DF,$08,$06,$DE,"EXOLON BONUS SCREEN!",$DF,$0A,$03,$DB,"PRESS FIRE TO STOP POINTER",$DF,$0D,$09,$DD,"0000" ; the texts
  DEFM "0 POINTS",$A3,$DC,"01000 POINTS",$A3,$DD,"00000 POINTS",$A3,$DC,"03000 POINTS",$A3,$DD,"00000 POINTS",$A3             ; in font
  DEFM $DC,"05000 POINTS",$A3,$DD,"00000 POINTS",$A3,$DC,"07000 POINTS",$FF                                                   ; $D7E0

; The end of the game's 125 screens: CONGRATULATIONS! YOU HAVE PROVEN YOUR
; COMBAT ABILITIES TO THE FULL
;
; RoundEnd prints it on screen 124's end, then the game goes on from screen 0
; (no ending beyond it). The same frame; then PRESS FIRE TO RESUME PLAY (the
; code waits with 4 DelayBC, not for fire).
CongratulationsText:
  DEFM $E6,$E0,$EC,$DF,$00,$00,$E3,$10,$A2,$DF,$02,$00,$E1,$0A,$DC,$04,$D4,$05,$AD,$DC,$06,$D4,$07,$AD,$E2,$E3,$10,$A2,$DF,$02,$1E,$E1,$0A,$DC,$04,$D4,$05,$AD,$DC,$06,$D4,$07,$AD,$E2,$DF,$03,$08,$E3,$FF,"p"
  DEFM $DF,$08,$08,$E0,"F",$E6,$E0,$D7,"CONGRATULATIONS!z",$EE,$DB,"YOU HAVE PROVEN YOURz",$EE,$DA,"COMBAT ABILITIE" ; the texts
  DEFM "Sz",$F2,$DE,"TO THE FULL{",$F4,$DC,"PRESS FIRE TOz",$F4,$DC,"RESUME PLAY",$FF                                ; in font
                                                                                                                     ; $D7E0

; The start of each zone: the screen, the player's X, Y (screens 0, 25, 50, 75,
; 100)
;
; ZoneRefill looks the new screen up (no end mark: a screen not in the table
; would loop for ever; only these five follow a zone's end). The entry $6D60
; starts a game at $10, $70 itself (the first record's values).
ZoneStarts:
  DEFB $00,$10,$70
  DEFB $19,$00,$78
  DEFB $32,$00,$20
  DEFB $4B,$28,$80
  DEFB $64,$10,$70

; The zone end marker's cell (column, row) from the builder (tile 16), $FF at
; $AAF1
ZoneEndList:
  DEFB $00,$00,$FF

; The zone end panel: a frame of font $EAB0, BRAVERY BONUS 00000, LIVES BONUS X
; 1000, PRESS FIRE TO RESUME PLAY (no code reads fire there: the panel ends
; with its Delays)
;
; At 3,7: a box 17 wide and 15 high of yellow pieces (font $EAB0), cleared
; inside with spaces of font $D7E0, then the texts (bright magenta, white,
; green, yellow, cyan).
ZoneBonusText:
  DEFM $DF,$03,$07,$E0,$00,$E6,$B0,$EA,$DD,$00,$D5,$01,$DD,$E4,$0F,$04,$00,$D5,$01,$9C,$DD,$02,$D5,$03,$E4,$0F,$05,$DD,$02,$D5,$03,$9C,$E1,$0D,$DD,$06,$D5,$07,$AD,$E2,$DD,$00,$D5,$01,$DD,$E4,$0F,$04,$00,$D5,$01,$9C,$DD,$02,$D5,$03,$E4,$0F,$05,$DD,$02,$D5,$03,"j",$FE
  DEFM $E1,$0D,$DD,$06,$D5,$07,$AD,$E2,"k",$F1,$E6,$E0,$D7,$E1,$0D,$E4,$0F," ",$A0,$E2,$DA,"l",$01,"BRAVERY BONUSz",$F7,$DE,"00000z",$F8,$DB,"LIVES BONUSz",$F9,$DD,"X 10"
  DEFM "00z",$F5,$DC,"PRESS FIRE TOz",$F4,"RESUME PLAY",$FF

; CALL NextPixelLine $B099 that no jump or call reaches (never ran)
;
; Never ran in any recording, and cannot: a CALL of NextPixelLine $B099 between
; ZoneBonusText's $FF and ForceFieldDraw; nothing in the image jumps to $AB94.
; A leftover.
DeadNextLineCall:
  CALL NextPixelLine
