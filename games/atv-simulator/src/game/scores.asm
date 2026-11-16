; --------------------------------------------------------------------------------------------------------------------
; scores.asm: The high score table and the name entry; the clock, the finish, the score, the lap, EXTENDED PLAY, TIME OUT
;
; The score is five ASCII digits a player (Scores $6948 / $694D): one point up for each $1000 of distance forwards
; ($D789 bit 12 changing, ScoreUpP1 / ScoreUpP2), one down backwards, and at the trail's end the time bonus counted in
; by TrailEnd with the EXTENDED PLAY sound. The clock (Clock $D6C9-$D6CB, three ASCII digits) counts a tenth per pass
; (ClockTick); a trail ends when both records' speed is 0 and every riding player has finished (WaitFrames), or at
; TIME OUT when the clock's first digit reaches the maximum's; a finished rider who holds the throttle stays at speed
; 1 and the trail waits for TIME OUT (MaxTimes: 60, 60, 60, 40, 50, 50). After the game CheckHiScore compares each
; score with the table HiScores and runs the name entry for a place.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7A3E

; After a game: each player's score into the table when it beats a row, with
; the name entry
;
; Player 1 against the five rows (HiCompare); in a two-player game player 2
; too. A place: NameEntry with the player's reader (ReadP1 $7BBE or ReadP2
; $7BC2) patched into ReadControlJump. Called through JpCheckHiScore by
; GameEntry's outer loop after each game (c1: 4 runs, 2 places). Player 1, when
; he reaches only the last row, is skipped unless he beat player 2.
;
; Witness: L1 4 (c1, kb, trail1, warp).
CheckHiScore:
  CALL ClearScreen
  LD HL,Scores
  LD DE,HiScores
  CALL HiCompare
  JR Z,l_7A6F
  CP $01
  JR NZ,l_7A5D
  LD HL,Scores
  LD DE,ScoreP2
  CALL HiCompare
  CP $05
  JR NZ,l_7A6F
l_7A5D:
  LD A,$10
  LD (NameColour),A
  LD IY,MenuPlayerOne
  LD BC,ReadP1
  LD HL,Scores
  CALL NameEntry
l_7A6F:
  LD A,$28
  LD (NameColour),A
  LD IY,MenuPlayerTwo
  LD BC,ReadP2
  LD HL,ScoreP2

; Insert the score at its row (moving the rows below down), then enter the name
; on a letter grid
;
; A the row (HiCompare). The scores and names below move down by LDDR, the
; score goes in, the name is blanked; the screen shows the table, the grid of
; letters A-Z, space and the end mark (4 rows of 7), a cursor moved by the
; player's controls (left/right/up/down), fire takes the letter under it into
; the name; the end mark returns.
;
; Witness: L1 5 (c1, kb, trail1, warp).
NameEntry:
  LD (ReadControlJump+$0001),BC
  LD DE,HiScores
  CALL HiCompare
  RET Z
  LD (NameRow),A
  LD (NameScorePtr),DE
  PUSH HL
  PUSH DE
  SUB $01
  JR C,l_7AB1
  JR Z,l_7AB1
  LD E,$06
  CALL JpMultiply
  PUSH HL
  POP BC
  PUSH BC
  LD HL,HiScores+$0017
  LD DE,HiScores+$001D
  LDDR
  POP BC
  LD HL,HiNames+$0017
  LD DE,HiNames+$001D
  LDDR
l_7AB1:
  POP DE
  POP HL
  LD BC,$0005
  LDIR
  LD A,(NameRow)
  XOR $FF
  ADD A,$07
  LD E,$06
  CALL JpMultiply
  LD DE,HiScoreTitle+$0005
  ADD HL,DE
  LD (NameTextPtr),HL
  LD DE,(NameTextPtr)
  INC DE
  LD (HL),$20
  LD BC,$0004
  LDIR
  LD A,(NameColour)
  SRL A
  SRL A
  SRL A
  OUT ($FE),A
  LD A,(NameColour)
  CALL FillAttrsBase
  CALL MenuRedraw
  CALL NameScreen
  LD HL,ListModes
  LD (ModeVector),HL
  CALL JpClearBufferP1
  LD A,$41
  LD (BigChar),A
  LD A,$4D
  LD (SpriteY),A
  LD C,$04
l_7B03:
  LD A,(SpriteY)
  SUB $10
  LD (SpriteY),A
  LD B,$07
l_7B0D:
  PUSH BC
  LD A,$07
  SUB B
  LD E,$18
  CALL JpMultiply
  LD A,L
  ADD A,$04
  LD (SpriteX),A
  LD IX,BigChar
  CALL Print
  LD A,(BigChar)
  INC A
  CP $21
  JR NZ,l_7B2F
  LD A,$70
  JR l_7B35
l_7B2F:
  CP $5B
  JR NZ,l_7B35
  LD A,$20
l_7B35:
  LD (BigChar),A
  POP BC
  DJNZ l_7B0D
  DEC C
  JR NZ,l_7B03
  LD H,$30
  LD L,$4F
  CALL ShowBufferPlace
  LD HL,$3039
  LD (CursorPos),HL
  XOR A
  LD (BigChar),A
; This entry point is used by the routine at ReadControlRaw.
l_7B4F:
  LD A,$38
  CALL NameCursor
  CALL ReadControl
  LD A,(NameColour)
  CALL NameCursor
  LD A,(PassControls)
  LD D,A
  LD A,(CursorPos+$0001)
  LD HL,(BigChar)
  BIT 3,D
  JR Z,l_7B6E
  INC L
  ADD A,$18
l_7B6E:
  BIT 4,D
  JR Z,l_7B75
  SUB $18
  DEC L
l_7B75:
  CP $30
  JR C,l_7B83
  CP $D8
  JR NC,l_7B83
  LD (CursorPos+$0001),A
  LD (BigChar),HL
l_7B83:
  LD A,(CursorPos)
  BIT 2,D
  LD A,(CursorPos)
  JR Z,l_7B8F
  ADD A,$10
l_7B8F:
  BIT 1,D
  JR Z,l_7B95
  SUB $10
l_7B95:
  CP $3A
  JR NC,l_7B4F
  CP $08
  JR C,l_7B4F
  LD (CursorPos),A
  JR l_7B4F

; Wait for the controls to be released, then pressed: A the bits
;
; Witness: L1 260961 (kb, warp).
ReadControl:
  CALL ReadControlRaw
  CP $00
  JR NZ,ReadControl
l_7BA9:
  CALL ReadControlRaw
  LD (PassControls),A
  BIT 0,A
  JR NZ,NameSelect
  CP $00
  JR Z,l_7BA9
  RET

; Scan the keyboard, then the player's reader
;
; Witness: L1 336036 (kb, warp).
ReadControlRaw:
  CALL JpClearKeys
ReadControlJump:
  JP $0000                ; JP ReadP1 or ReadP2 (the operand patched by
                          ; CheckHiScore)
ReadP1:
  LD A,(Controls1)        ; A = Controls1
  RET
ReadP2:
  LD A,(Controls2)        ; A = Controls2
  RET
; This entry point is used by the routine at ReadControl.
NameSelect:
  POP AF                  ; fire: the letter under the cursor into the name, or
                          ; the end
  LD A,(CursorPos)
  LD E,A
  LD A,$39
  SUB E
  SRL A
  CALL CellCount
  LD E,$07
  CALL JpMultiply
  LD A,(BigChar)
  ADD A,L
  ADD A,$3A
  CP $5B
  JR NZ,l_7BE4
  LD A,$20
l_7BE4:
  CP $5C
  JR NZ,l_7BE9
  RET
l_7BE9:
  LD HL,(NameTextPtr)
  INC HL
  LD DE,(NameTextPtr)
  LD BC,$0004
  LDIR
  DEC HL
  LD (HL),A
  CALL NameScreen
  JP l_7B4F

; Colour the cursor's 2 x 2 cells with A
;
; Witness: L1 22 (kb, warp).
NameCursor:
  LD HL,(CursorPos)
  LD BC,$0202
  JP FillAttrs

; Show the buffer at the screen place H = x, L = y
;
; Witness: L1 33 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1,
; trails, turn, wallcrash, warp).
ShowBufferPlace:
  CALL ScreenAddrHL
  EX DE,HL
  LD HL,BufferP1
  JP ShowBufferAt

; SpriteX = H, SpriteY = L, HL = the screen address (ScreenAddr)
;
; Witness: L1 137 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1,
; trails, turn, wallcrash, warp).
ScreenAddrHL:
  LD A,H
  LD (SpriteX),A
  LD A,L
  LD (SpriteY),A
  JP GfxTable

; The name entry's screen: the score, the name, "HI SCORE", the colours
;
; Witness: L1 4 (kb, warp).
NameScreen:
  CALL JpClearBufferP1
  LD HL,DrawModes+$0010
  LD (ModeVector),HL
  LD A,$02
  LD (BigScaleX),A
  LD HL,$0304
  LD (BigScaleY),HL
  LD IX,(NameScorePtr)
  LD HL,$302E
  CALL PrintAt
  LD IX,(NameTextPtr)
  LD HL,$002C
  CALL PrintAt
  LD IX,HiScoreTitle
  LD HL,$0F4F
  CALL PrintAt
  LD A,(NameColour)
  ADD A,$04
  LD HL,$0087
  LD BC,$2003
  CALL FillAttrs
  LD A,(NameColour)
  LD E,A
  ADD A,$06
  LD HL,$0077
  LD BC,$2006
  CALL FillAttrs
  LD HL,$2894
  JP ShowBufferPlace

; Compare a score (HL) with the five rows (DE): Z when it beats none, else A =
; 5 - the row
;
; Witness: L1 10 (c1, kb, trail1, warp).
HiCompare:
  LD C,$05
l_7C73:
  PUSH HL
  PUSH DE
  LD B,$04
l_7C77:
  LD A,(DE)
  CP (HL)
  JR C,l_7C8D
  JR NZ,l_7C81
  INC HL
  INC DE
  DJNZ l_7C77
l_7C81:
  POP HL
  LD DE,$0006
  ADD HL,DE
  EX DE,HL
  POP HL
  DEC C
  JR NZ,l_7C73
  XOR A
  RET
l_7C8D:
  POP DE
  POP HL
  LD A,C
  RET

; 11 bytes before the trails' records, read by no one ($E1 $79 $C9 ...:
; code-like leftovers)
TrailsLeftover:
  DEFB $E1,$79,$C9,$E1,$79,$C9,$C9,$79
  DEFB $C9,$F6,$E1

  ORG $DBB0

; HL = the number of the three ASCII digits at IX
;
; Witness: L1 22 (kb, trails, wallcrash, warp).
DigitsValue:
  LD A,(IX+$00)
  SUB $30
  LD E,$64
  CALL JpMultiply
  PUSH HL
  LD A,(IX+$01)
  SUB $30
  LD E,$0A
  CALL JpMultiply
  LD A,(IX+$02)
  SUB $30
  LD E,A
  LD D,$00
  ADD HL,DE
  POP DE
  ADD HL,DE
  RET

  ORG $EABF

; Draw a clock digit (sprite A - $97)
;
; Witness: L1 5889 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ClockDigit:
  PUSH AF
  SUB $97
  JR l_EAC7

; Draw a HUD digit (sprite A - $A3)
;
; Witness: L1 548 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
BigDigit:
  PUSH AF
  SUB $A3
; This entry point is used by the routine at ClockDigit.
l_EAC7:
  LD (SpriteNum),A
  CALL JpGameSpriteAt
  POP AF
  RET

; MaxTime from MaxTimes (or "30" in the second round) and its digits
;
; Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ShowMaxTime:
  LD A,(SecondRound)
  CP $00
  JR Z,l_EADF
  LD HL,$3033
  LD (MaxTime),HL
  JP l_EAF4
l_EADF:
  LD DE,(Trail)
  SLA E
  LD D,$00
  LD HL,MaxTimes
  ADD HL,DE
  LD A,(HL)
  LD (MaxTime),A
  INC HL
  LD A,(HL)
  LD (MaxTime+$0001),A
l_EAF4:
  CALL ClockPlace
  LD HL,DrawModes+$0006
  LD (ModeVector),HL
  LD A,(SpriteX)
  ADD A,$2A
  LD (SpriteX),A
  LD A,(MaxTime+$0001)
  CALL BigDigit
  LD A,(SpriteX)
  SUB $0E
  LD (SpriteX),A
  LD A,(MaxTime)
  JR BigDigit

; The clock's three digits
;
; Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ShowClock:
  CALL ClockPlace
  LD A,(ClockUnits)
  CALL ClockDigit
  LD A,(SpriteX)
  SUB $0E
  LD (SpriteX),A
  LD A,(ClockTens)
  CALL BigDigit
  LD A,(SpriteX)
  SUB $0E
  LD (SpriteX),A
  LD A,(Clock)
  JR BigDigit

; The clock's place (x $60, y $66) and its draw mode
;
; Witness: L1 5910 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ClockPlace:
  LD A,$60
  LD (SpriteX),A
  LD A,$66
  LD (SpriteY),A
  LD HL,DrawModes+$0002
  LD (ModeVector),HL
  LD HL,Screen
  LD (ScreenBase),HL
  RET

; Clock + 1 (the last digit each pass, carried into the others) and its digits
;
; Witness: L1 5868 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ClockTick:
  CALL ClockPlace
  LD A,(ClockUnits)
ClockAdd:
  ADD A,$01               ; ADD A,1: the pass's step (ZXDB POKE 60250,0,
                          ; "infinite lives", makes it ADD A,0: the clock never
                          ; moves, recording pokes)
  LD (ClockUnits),A
  CP $3A
  JP C,ClockDigit
  LD A,$30
  LD (ClockUnits),A
  CALL ClockDigit
  LD A,(SpriteX)
  SUB $0E
  LD (SpriteX),A
  LD A,(ClockTens)
  ADD A,$01
  LD (ClockTens),A
  CP $3A
  JP C,BigDigit
  LD A,$30
  LD (ClockTens),A
  CALL BigDigit
  LD A,(SpriteX)
  SUB $0E
  LD (SpriteX),A
  LD A,(Clock)
  ADD A,$01
  LD (Clock),A
  CP $3A
  JP C,BigDigit
  LD A,$30
  LD (Clock),A
  JP BigDigit

; Fuel = $2000, the FUEL bar drawn full (two 3-pixel cells a byte, 4 lines);
; not scale ticks
;
; Witness: L1 23 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ShowBars:
  LD HL,$2000
  LD (Fuel),HL
  LD A,$90
  LD (SpriteX),A
  ADD A,$20
  LD (FuelBar),A
  LD A,(HudY)
  SUB $01
  LD (SpriteY),A
  CALL GfxTable
  LD C,$04
l_EBC2:
  CALL ScaleLeft
  CALL ScaleRight
  INC HL
  DEC C
  JR NZ,l_EBC2
  RET

; A scale mark's left half
;
; Witness: L1 92 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ScaleLeft:
  PUSH HL
  LD B,$04
  LD E,$E0
  JR l_EBD9

; A scale mark's right half
;
; Witness: L1 92 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ScaleRight:
  PUSH HL
  LD B,$04
  LD E,$0E
; This entry point is used by the routine at ScaleLeft.
l_EBD9:
  LD A,E
  OR (HL)
  LD (HL),A
  CALL JpNextLineHL
  DJNZ l_EBD9
  POP HL
  RET

; "TIME OUT" in each riding half that has not finished
;
; Witness: L1 5 (c1, kb, trail1, trails, warp).
TimeOut:
  LD A,(Finished)
  AND $01
  JR NZ,l_EBFD
  LD A,(Riding)
  AND $01
  JR Z,l_EBFD
  LD HL,BufferP1
  LD (BufferBase),HL
  CALL TimeOutText
  CALL JpCopyBufferP1
l_EBFD:
  LD A,(Riding)
  AND $02
  RET Z
  LD A,(Finished)
  AND $02
  RET NZ
  LD HL,BufferP2
  LD (BufferBase),HL
  CALL TimeOutText
  JP JpCopyBufferP2

; "TIME OUT" at x $40, y $44
;
; Witness: L1 5 (c1, kb, trail1, warp).
TimeOutText:
  LD A,$40
  LD (SpriteX),A
  LD A,$44
  LD (SpriteY),A
  LD IX,GameTexts
  JP PrintShadow

; Print in ModeCopyBuffer (DrawModes + 8: each glyph's box replaces the buffer,
; a cleared band, the letters cut), then Print in OR (ListModes + 0) at the
; same x, y
;
; Witness: L1 1184 (c1, empty, kb, trail1, trails, wallcrash, warp).
PrintShadow:
  PUSH IX
  LD A,(SpriteX)
  LD E,A
  LD A,(SpriteY)
  LD D,A
  PUSH DE
  LD HL,DrawModes+$0008
  LD (ModeVector),HL
  CALL JpPrint
  POP DE
  LD A,D
  LD (SpriteY),A
  LD A,E
  LD (SpriteX),A
  LD HL,ListModes
  LD (ModeVector),HL
  POP IX
  JP JpPrint

; "TIME OUT|", "OUT OF FUEL|", "EXTENDED PLAY|", "LAP TIME     |" (the lap time
; written into its blanks)
GameTexts:
  INCBIN "res/texts/game.bin",$0000,9
OutOfFuelText:
  INCBIN "res/texts/game.bin",$0009,12
ExtendedText:
  INCBIN "res/texts/game.bin",$0015,14
LapText:
  INCBIN "res/texts/game.bin",$0023,14

  ORG $EDBB

; Player 1's score + 1 (ASCII, carried): +1 point, shown as +10 (the units
; digit is never changed)
;
; Witness: L1 4269 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ScoreUpP1:
  LD IX,Scores+$0003
  LD A,$9B
  JR l_EDDB

; Player 2's score + 1: +1 point, shown as +10
;
; Witness: L1 327 (kb).
ScoreUpP2:
  LD IX,ScoreP2+$0003
  LD A,$3B
  JR l_EDDB

; Player 1's score - 1
;
; Witness: L1 25 (fuel, kb, speedcrash, turn, wallcrash, warp).
ScoreDownP1:
  LD IX,Scores+$0003
  LD A,$9B
  JR l_EDFC

; Player 2's score - 1
;
; Witness: L1 1 (kb).
ScoreDownP2:
  LD IX,ScoreP2+$0003
  LD A,$3B
  JR l_EDFC
; This entry point is used by the routines at ScoreUpP1 and ScoreUpP2.
l_EDDB:
  CALL ShowScore
  LD B,$04
l_EDE0:
  CALL ScoreDigit
  LD A,(IX+$00)
  INC A
  LD (IX+$00),A
  CP $3A
  JR C,ScoreDigit
  LD A,$30
  LD (IX+$00),A
  CALL ScoreDigit
  CALL ScoreDigitLeft
  DJNZ l_EDE0
  RET
; This entry point is used by the routine at ScoreDownP1.
l_EDFC:
  CALL ShowScore
  LD B,$04
l_EE01:
  CALL ScoreDigit
  LD A,(IX+$00)
  SUB $01
  LD (IX+$00),A
  CP $30
  JR NC,ScoreDigit
  LD A,$39
  LD (IX+$00),A
  CALL ScoreDigit
  CALL ScoreDigitLeft
  DJNZ l_EE01
  RET

; Draw the score digit at IX (XOR); not per player
;
; Witness: L1 10250 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ScoreDigit:
  LD A,(IX+$00)
  ADD A,$69
  LD (SpriteNum),A
  PUSH BC
  CALL JpGameSpriteAt
  POP BC
  RET

; IX - 1, x - 7: the next digit to the left, then ScoreDigit; not per player
;
; Witness: L1 503 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash,
; warp).
ScoreDigitLeft:
  DEC IX
  LD A,(SpriteX)
  SUB $07
  LD (SpriteX),A
  RET

; The five digits at IX
;
; Witness: L1 4622 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ShowScore:
  LD (SpriteY),A
  LD A,$E8
  LD (SpriteX),A
  LD HL,DrawModes+$0006
  LD (ModeVector),HL
  LD HL,Screen
  LD (ScreenBase),HL
  RET

; 56 bytes no code reaches: an older copy of ShowScore and the code after it,
; assembled one byte lower
ScoreLeftover:
  DEFB $32,$DA,$80,$21,$FD,$69,$22,$F7
  DEFB $82,$21,$00,$40,$22,$DE,$80,$C9
  DEFB $DE,$80,$C9,$80,$C9,$32,$DC,$80
  DEFB $3E,$E8,$32,$DA,$80,$21,$FD,$69
  DEFB $22,$F7,$82,$21,$00,$40,$22,$DE
  DEFB $80,$C9,$CD,$0C,$83,$CD,$0F,$83
  DEFB $3A,$AD,$80,$FE,$00,$20,$F3,$CD
