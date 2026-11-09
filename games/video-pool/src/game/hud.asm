; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The new game's screen, the HUD texts, the 1up / 2up blink, the "last shot" blink
;
; Text records for PrintText $9E65: row, column, attribute (bit 7 = double width), length, then the characters (no end
; marker). Lower case and digits come from the game's font $DEF4, everything else from the ROM's character set
; (printing module).
;
; The HUD, rows 0 and 1, attribute $38 for the words and $3A for the numbers: "1up" col 0 and the player 1 score cols
; 3-8, "hi" col 12 and the hi score cols 14-19, "2up" col 23 and the player 2 score cols 26-31; row 1: the power box
; (cols 0-16), "frame" col 17 and the frame number cols 22-23, "shots" col 26 and the shots left col 31. Scores print
; as five digits plus a fixed "0" (the score x 10).
; --------------------------------------------------------------------------------------------------------------------

; Start a game: clear the screen, colours, HUD, scores, frames, lives, the
; table, the power box; park all balls
;
; Called once by the game start $8013 (game frame 6182, w1 622, v1 twice: 772,
; 2603). Clears the display, border 7 (white; BORDCR $38), attributes: rows 0-4
; $39 (the HUD and message rows), row 5 $38 (the top pocket marks), rows 6-22
; $60 (the table: bright green paper, black ink), row 23 $38 (the bottom pocket
; marks).
;
; Prints the HUD words (HudTexts $969D "1up" ... HudShots), zeroes the scores
; ($9F45, $9F47) and the pocket turns (PlayerVars $9F43 / $9F44), frames $9F4B
; / $9F4C = 1, lives $9F4E / $9F4F = 3, Player2Racked $9B33 = 0; prints the
; three scores (PrintHudNumber 0, 1, 2), the power box, power $86BF / $86C0 =
; 0, the table; ParkBalls $967B for both ball sets ($8A88 and $8AEA).
NewGameScreen:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  LD A,$07
  OUT ($FE),A
  LD A,$38
  LD (BORDCR),A
  INC HL
  INC DE
  LD BC,$009F
  LD (HL),$39
  LDIR
  INC HL
  INC DE
  LD BC,$001F
  LD (HL),$38
  LDIR
  INC HL
  INC DE
  LD BC,$021F
  LD (HL),$60
  LDIR
  INC HL
  INC DE
  LD BC,$001F
  LD (HL),$38
  LDIR
  LD HL,HudTexts
  CALL PrintText
  LD HL,HudTwoUp
  CALL PrintText
  LD HL,HudHi
  CALL PrintText
  LD HL,HudRowOneBlank
  CALL PrintText
  LD HL,HudFrame
  CALL PrintText
  LD HL,HudShots
  CALL PrintText
  LD HL,$0000
  LD (ScorePlayer1),HL
  LD (ScorePlayer2),HL
  LD (PocketTurn),HL
  LD HL,$0101
  LD (FrameNumber),HL
  LD HL,$0303
  LD (LivesLeft),HL
  XOR A
  LD (Player2Racked),A
  XOR A
  CALL PrintHudNumber
  LD A,$01
  CALL PrintHudNumber
  LD A,$02
  CALL PrintHudNumber
  CALL DrawPowerBox
  LD HL,$0000
  LD (Power),HL
  CALL DrawTable
  LD IX,BallRecords
  CALL ParkBalls
  ADD IX,DE
  CALL ParkBalls
  RET

; Take the set at IX off the table: cue ball and balls 1-6 bit 7 of +13 clear,
; balls 1-6 to the potted row (x 0, 24, ... 120; y 20)
;
; Input IX = a set of 7 records (14 bytes each). Only +10/+11 (the sprite's
; place) and bit 7 of +13 are set; nothing is drawn. Called twice by
; NewGameScreen (game 2, frame 6190): $8A88 the current player's set, $8AEA the
; other player's (the set TurnSwap $9C15 exchanges).
ParkBalls:
  RES 7,(IX+$0D)
  LD DE,$000E
  LD A,$01
  LD HL,$1400             ; y 20, x 0: the potted row's first place
  LD BC,$0018
ParkBallsLoop:
  ADD IX,DE
  LD (IX+$0A),L
  LD (IX+$0B),H
  RES 7,(IX+$0D)
  ADD HL,BC
  INC A
  CP $07
  JR NZ,ParkBallsLoop
  RET

; The HUD's text records (PrintText format: row, column, attribute, length,
; text)
;
; All read: NewGameScreen prints $969D, $96AB, $96B9, $96BF, $96D4, $96DD;
; UpBlinkTask $96E6 alternates $969D / $96A4 and $96AB / $96B2; ShotsBlinkTask
; $970E reprints $96DD.
HudTexts:
  INCBIN "res/text/HudTexts.bin",$0000,7
HudOneUpBlank:
  INCBIN "res/text/HudTexts.bin",$0007,7
HudTwoUp:
  INCBIN "res/text/HudTexts.bin",$000E,7
HudTwoUpBlank:
  INCBIN "res/text/HudTexts.bin",$0015,7
HudHi:
  INCBIN "res/text/HudTexts.bin",$001C,6
HudRowOneBlank:
  INCBIN "res/text/HudTexts.bin",$0022,21
HudFrame:
  INCBIN "res/text/HudTexts.bin",$0037,9
HudShots:
  INCBIN "res/text/HudTexts.bin",$0040,9

; Blink the current player's "1up" / "2up": print it or its blank by UpBlink
; $9B31, then flip UpBlink
;
; A task added by StartAim $8425 with period 20 (every 21 interrupts) and
; removed by $8483 when the shot starts, which first prints it with UpBlink =
; $FF (shown). CurrentPlayer $9B30 = 1 picks HudTexts ("1up", $969D) /
; HudOneUpBlank, 2 HudTwoUp / HudTwoUpBlank; UpBlink 0 prints the blank. game
; 88 runs, w1 377, p2 130.
UpBlinkTask:
  LD A,(CurrentPlayer)
  DEC A
  LD A,(UpBlink)
  JR NZ,UpBlinkPlayer2
  LD HL,HudTexts
  OR A
  JR NZ,UpBlinkPrint1
  LD HL,HudOneUpBlank
UpBlinkPrint1:
  JR UpBlinkPrint
UpBlinkPlayer2:
  LD HL,HudTwoUp
  OR A
  JR NZ,UpBlinkPrint
  LD HL,HudTwoUpBlank
UpBlinkPrint:
  CALL PrintText
  LD A,(UpBlink)
  CPL
  LD (UpBlink),A
  RET

; With one shot left: alternate "last  " / "  shot" in place of "shots"; at the
; shot's end (StopShotTasks, LastShotBlink = $FF) put "shots" and the count
; back
;
; A task added by StartAim $8425 with period 25, removed by $8483, which calls
; it once with LastShotBlink $9B32 = $FF. Returns at once unless ShotsLeft
; $9F4D = 1. LastShotBlink 0 prints HudLast $9740, 1 HudShot $974A, then flips
; 0 / 1; $FF prints HudShots and the count (PrintHudNumber 3) and sets 0. game
; 72 runs, w1 308; the $FF branch only in f1 (once).
ShotsBlinkTask:
  LD A,(ShotsLeft)
  DEC A
  RET NZ
  LD A,(LastShotBlink)
  CP $FF
  JR Z,ShotsBlinkRestore
  LD HL,HudLastShot
  OR A
  JR Z,ShotsBlinkPrint
  LD HL,HudShot
ShotsBlinkPrint:
  CALL PrintText
  LD A,(LastShotBlink)
  INC A
  AND $01
  LD (LastShotBlink),A
  RET
ShotsBlinkRestore:
  LD HL,HudShots
  CALL PrintText
  LD A,$03
  CALL PrintHudNumber
  XOR A
  LD (LastShotBlink),A
  RET

; The two halves of the "last shot" blink (PrintText records at row 1, col 26,
; attr $38, 6 characters)
;
; Printed by ShotsBlinkTask $970E; both read in game, w1, f1.
HudLastShot:
HudLast:
  INCBIN "res/text/HudLastShot.bin",$0000,10
HudShot:
  INCBIN "res/text/HudLastShot.bin",$000A,10
