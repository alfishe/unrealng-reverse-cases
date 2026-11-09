; --------------------------------------------------------------------------------------------------------------------
; gamestart.asm: The game start, the lives and the players, GAME OVER, the life start and the HUD
;
; GameStart $8F10 (from the options page, S) sets up both player records, then plays lives: the "PLAYER n" banner, the
; life start LifeStart $90D3 and the main loop $9696, until the lives of every player are gone; GAME OVER (or GAME
; OVER PLAYER n in a two-player game), the hi-score entries $8B8F and back to the heroes table $81D0.
;
; The current player is the 27-byte record at $B271; the other player's is at $B28C, swapped through $B2A7 by
; PlayerSwap $9022. Fields the code here uses: $B271 the player number, $B272-$B275 the score (8 BCD digits),
; $B276-$B279 the score of the next extra life, $B27A the course script pointer, $B27C the point reached (bits 0-4 the
; point number, bit 5 the Champion course), $B27D the scenery (0 or $FF), $B27E the warning lamps (0-3), $B27F the
; restart pointer, $B281 the start of the segment last read, $B283 the player still in the game, $B284 the lives in
; reserve, $B285-$B286 the time (BCD seconds), $B287 the clock's frame count, $B288 flags (bit 3 a mine entered, bit 4
; the hold, bit 7 the tune off).
;
; The HUD (rows 0-2): the player labels 1P / 2P and the scores with the point letter reached, the hi-score, four buggy
; icons for the lives, the course name and the progress bar, TIME and POINT, and the three warning lamps with DANGER!
; and CAUTION. The scenery colours and the mountains or city backdrop are set here too.
; --------------------------------------------------------------------------------------------------------------------

; The game start: both player records set, then the first life of player 1
;
; Entered by a JP from the options page ($8244) when S is pressed. Makes sure
; the record at $B271 is player 1's (PlayerSwap if $B271 holds 2), then fills
; both records, player 2 first (D = 2, 1): the player number, the score and the
; extra-life score 00010000 ($B277 = 1), the course script $B7E8 (Beginner,
; $B27C = 0) or $BB24 (Champion, $B27C = $20, from the course choice $B258),
; the scenery, lamps and pointers zeroed, $B283 = 1 (in the game), four lives,
; the time zeroed, and $B288 cleared but for bit 7 (the tune off survives). A
; one-player game then zeroes player 2's $B283 and lives, so the swaps after
; each life always come back to player 1.
;
; GameStartLife $8F71 is the start of every life: one life taken from the
; reserve ($B284), the screen cleared in white on black (ClearScreen $9044),
; "PLAYER n" printed (TextPlayer $9073 and the digit) and held for 100 frames
; (Wait100Frames $903D, 300 frames in a two-player game), the screen cleared
; again, then LifePlay $90CC: the life start and the main loop until the buggy
; dies. It goes on at GameAfterLife $8F9F.
;
; Witness: game 5 runs (1448-16318), a1 1 (1314), g1 1 (153), p2 1 (334), h1 1
; (153), i1 1 (153), i2 1 (334). GameStartLife: g1 4 lives, p2 8 (four each of
; two players), i1 / i2 1 (immune).
GameStart:
  LD A,(Player)
  CP $02
  JR Z,GameStartInit
  CALL PlayerSwap
GameStartInit:
  LD DE,$0200             ; D = 2 records to fill (player 2, then player 1), E
                          ; = 0
GameStartRecord:
  LD HL,Player            ; the player number
  LD (HL),D
  INC HL
  LD B,$05
GameStartScore:
  LD (HL),E               ; the score $B272-$B275 and the top byte of the
                          ; extra-life score zeroed
  INC HL
  DJNZ GameStartScore
  LD (HL),$01             ; the extra-life score 00010000: the first extra life
                          ; at 10000 points
  INC HL
  LD (HL),E
  INC HL
  LD (HL),E
  INC HL
  LD BC,BeginnerCourse    ; the course script: Beginner $B7E8, point base 0
  LD A,(Course)
  DEC A
  LD A,$00
  JR Z,GameStartCourse
  LD BC,ChampionCourse    ; Champion: $BB24, point base $20 (bit 5 of $B27C)
  LD A,$20
GameStartCourse:
  LD (HL),C               ; $B27A-$B27B the course pointer, $B27C the point
                          ; base
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD B,$06
GameStartClear:
  LD (HL),E               ; $B27D-$B282 zeroed: the scenery, the lamps, the
                          ; restart and segment pointers
  INC HL
  DJNZ GameStartClear
  LD (HL),$01             ; $B283 = 1: in the game; $B284 = 4 lives
  INC HL
  LD (HL),$04
  INC HL
  LD B,$03
GameStartTime:
  LD (HL),E               ; the time $B285-$B287 zeroed, the flags $B288 kept
                          ; only for bit 7 (the tune off)
  INC HL
  DJNZ GameStartTime
  LD A,(HL)
  AND $80
  LD (HL),A
  CALL PlayerSwap         ; into the other record: the second pass fills the
                          ; other player
  DEC D
  JR NZ,GameStartRecord
  LD A,(Players)
  CP $02
  JR Z,GameStartNextPlayer
  LD HL,$0000             ; one player: player 2 is out of the game, no lives
  LD (PlayerActive),HL
; This entry point is used by the routine at GameAfterLife.
GameStartNextPlayer:
  CALL PlayerSwap         ; the other player's record in
; This entry point is used by the routine at GameAfterLife.
GameStartLife:
  LD HL,PlayerLives       ; a life: one life from the reserve, the PLAYER n
                          ; banner
  DEC (HL)
  LD A,$07
  CALL ClearScreen
  LD HL,TextPlayer
  CALL PrintText
  LD A,(Player)
  ADD A,$30
  CALL PrintChar
  CALL Wait100Frames
  LD A,(Players)
  DEC A
  JR Z,GameStartPlay      ; a two-player game holds the banner 300 frames
  CALL Wait100Frames
  CALL Wait100Frames
GameStartPlay:
  LD A,$07                ; the screen cleared, the life played (LifePlay)
  CALL ClearScreen
  CALL LifePlay

; After a life: the next player's turn, or GAME OVER, the hi-score entries and
; the heroes table
;
; Reached when LifePlay $90CC returns (the buggy has died: the main loop $9696
; returns after the death). With lives left the turn passes to the other player
; when that player is still in the game ($B283), else back to this one ($8F6E
; swaps the record back), and GameStartLife $8F71 plays the next life.
;
; No lives left: $B283 = 0 (out of the game). One player: 8 cells cleared on
; rows 9 and 10 ($484C, $486C) and "GAME OVER" printed (TextGameOver $9086).
; Two players: 14 cells cleared and "GAME OVER PLAYER n" (TextGameOverPlayer
; $909B and the digit). 200 frames held. When the other player is still in the
; game, that player's next life is played. Else the game is over: one player,
; the record is put back to player 1 when needed and its hi-score entry run
; ($8B8F); two players, the entry of each player in turn. Then JP $81D0, the
; heroes table.
;
; Witness: game 19 runs, a1 2, g1 4, p2 8, h1 4, h2 1 (the immune runs never
; die). GAME OVER: g1 1 (~3950), h1 1, h2 1, game 4; GAME OVER PLAYER: p2 2
; (both players, the second at 7700). The two-player end GameOverBoth $9006 ran
; in p2 once; the second player's entry $9009-$900F is not executed in any
; recording (game, a1, g1, t1, p2, h1, i1, i2, h2): p2 stopped in the first
; entry. Known only from the code.
GameAfterLife:
  LD A,(PlayerLives)
  AND A
  JR Z,GameOverPlayer
  CALL PlayerSwap         ; lives left: the other player's turn when that
                          ; player is still in the game, else this player again
  LD A,(PlayerActive)
  AND A
  JR NZ,GameStartLife
  JR GameStartNextPlayer
GameOverPlayer:
  LD (PlayerActive),A     ; no lives: out of the game
  LD A,(Players)
  CP $02
  JR Z,GameOverPlayerN
  LD C,$08                ; one player: 8 cells cleared on two rows, GAME OVER
  LD HL,Screen+2124
  CALL ClearCells
  LD C,$08
  LD HL,Screen+2156
  CALL ClearCells
  LD HL,TextGameOver
  CALL PrintText
  JR GameOverHold
GameOverPlayerN:
  LD C,$0E                ; two players: 14 cells cleared, GAME OVER PLAYER n
  LD HL,Screen+2121
  CALL ClearCells
  LD C,$0E
  LD HL,Screen+2153
  CALL ClearCells
  LD HL,TextGameOverPlayer
  CALL PrintText
  LD A,(Player)
  ADD A,$30
  CALL PrintChar
GameOverHold:
  CALL Wait100Frames      ; 200 frames, then the other player's next life if
                          ; still in the game
  CALL Wait100Frames
  CALL PlayerSwap
  LD A,(PlayerActive)
  AND A
  JP NZ,GameStartLife
  LD A,(Players)
  DEC A
  JR Z,GameOverOne
GameOverBoth:
  CALL HiScoreEntry       ; two players: the hi-score entry of each player,
                          ; then the heroes table
  CALL PlayerSwap
  CALL HiScoreEntry
  JP HeroesPage
GameOverOne:
  LD A,(Player)           ; one player: back to player 1's record, its hi-score
                          ; entry, the heroes table
  CP $01
  JR Z,GameOverEntry
  CALL PlayerSwap
GameOverEntry:
  CALL HiScoreEntry
  JP HeroesPage

; Swaps the current player record $B271 with the other player's $B28C (27 bytes
; each, through $B2A7)
;
; $B271 -> $B2A7, $B28C -> $B271, $B2A7 -> $B28C, with the alternate registers
; so BC, DE, HL are kept. Called by GameStart (twice per record set-up), after
; each life and at GAME OVER, and twice by HudDraw $9136 (to print the other
; player's score).
;
; Witness: game 100 runs (1448-16320), a1 16, g1 22, p2 30, h1 22, i1 28, i2
; 28, h2 4.
PlayerSwap:
  EXX
  LD HL,Player
  LD DE,SwapBuffer
  LD BC,$001B
  LDIR
  LD DE,Player
  LD BC,$001B
  LDIR
  LD BC,$001B
  LDIR
  EXX
  RET

; Waits 100 frames: EI and 100 HALTs (the PLAYER n banner, GAME OVER, the bonus
; screen)
;
; Called by GameStart, GameAfterLife and the sector bonus screen $A4EE.
; Interrupts are on in IM 1 here (the ROM's handler): stage 1 of the power-on
; recording (WALKTHROUGH 1) is this loop resumed by the interrupt's RET.
;
; Witness: game 28 runs (1452-16316), a1 3, g1 6, p2 28, h1 6, i1 6, i2 6, h2
; 2. The HALT $9040: 100 a call (game 2800, p2 2800, i1 600).
Wait100Frames:
  EI
  LD B,$64
Wait100Loop:
  HALT
  DJNZ Wait100Loop
  RET

; Clears the screen: pixels to 0, the attributes to A; ATTR-P, BORDCR and the
; border follow A
;
; A = the attribute (7 white on black in the game, 0 for the title). ATTR-P
; $5C8D = A; BORDCR $5C48 = A AND $38 (the paper), with ink 7 added when the
; paper is dark (bit 5 clear); the border = the paper colour (OUT $FE); ($5CC6)
; = the paper colour XOR 7.
;
; Called by the entry $8000, the title and menus ($8064, $81D0, $825A), the
; hi-score entry $8B8F, GameStart and the bonus screen $A4EE. Witness: game 49
; runs (from 256), a1 52, g1 10, t1 4, p2 19, h1 13, i1 13, i2 14, h2 1.
ClearScreen:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1800
  LD (HL),$00
  LDIR
  LD BC,$0300
  LD (HL),A
  LDIR
  LD ($5C8D),A
  AND $38
  BIT 5,A
  JP NZ,ClearScreenBorder
  XOR $07
ClearScreenBorder:
  LD (BORDCR),A            ; BORDCR, the border colour
  AND $38
  RRCA
  RRCA
  RRCA
  OUT ($FE),A
  XOR $07
  LD ($5CC6),A
  RET

; Print string (PrintText $FFD0): white on black, AT x $68 y $55, font 1,
; "PLAYER " (the digit follows)
;
; The print codes of $FDCC that these strings use: $10 n ink, $11 n paper, $13
; n bright, $16 x y a position in pixels, $18, $19, $1A n the font; $1F ends
; the string (PrintText $FFD0 stops on it). Printed by GameStartLife $8F7A:
; read game 20, a1 3, g1 4, p2 8, h1 4, i1 1, i2 1 (one read a life).
TextPlayer:
  INCBIN "res/text/TextPlayer.bin",$0000,19

; Print string: AT x $65 y $55, font 1, "GAME OVER" (one player)
;
; Printed by GameAfterLife $8FCD: read game 4, g1 1, h1 1, h2 1.
TextGameOver:
  INCBIN "res/text/TextGameOver.bin",$0000,21

; Print string: AT x $4B y $55, font 1, "GAME OVER PLAYER " (the digit follows)
;
; Printed by GameAfterLife $8FE5: read p2 2.
TextGameOverPlayer:
  INCBIN "res/text/TextGameOverPlayer.bin",$0000,29

; An empty print string ($1F only): LifeStart prints it, and the build stamp
; after it is never printed
;
; LifeStart $9123 prints from here at every life start (read game 20, a1 4, g1
; 4, p2 8, h1 4, i1 6, i2 6). The $1F ends the string at once, so the stamp
; BuildStamp $90B9 that follows is never read (no reads in any recording).
; LifeStart prints three more strings of this shape: $7F00, $A182, $B2C2, each
; a $1F before a stamp.
TextNoDate:
  INCBIN "res/text/TextNoDate.bin",$0000,1

; A build time stamp, never printed: $00 $21, font 2, "20:15 29/10/84", $1F
;
; Not read in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only
; from the bytes. The other stamps: $7F01 "03:35 30/10/84", $A183 "03:40
; 30/10/84", $B2C3 "02:45 29/10/84".
BuildStamp:
  INCBIN "res/text/BuildStamp.bin",$0000,19

; One life: LifeStart, then the main loop until the buggy dies
;
; Witness: game 20 runs (1554-16323), a1 3, g1 4, p2 8, h1 4, i1 1, i2 1.
LifePlay:
  CALL LifeStart
  CALL MainLoop

; The return of LifePlay, reached when the main loop $9696 returns after a
; death
;
; An entry of its own because h2 began in play with this address on the stack
; (h2: entered at 287). Witness: game 19 runs, a1 2, g1 4, p2 8, h1 4, h2 1.
LifePlayDone:
  RET

; The life start: the colours, the HUD, the backdrop, the buggy, the shots, IM
; 2
;
; SceneryColours $95B0, the lamps $B27E to 0, HudDraw $9136, ScenerySetup
; $9541. $B223 = $FF; the buggy alive, not dying ($B216 / $B217 = $FF), its box
; at $B212 = y $92, x $38 (drawn at y $89, sprite $00 through $A826). $B237
; (UFOs leave), $B220, $B234, $B240 = 0. ShotBoxes $9681 (21 bytes) copied to
; $5B60 (the printer buffer). The ground pattern pointer $B232 = $A9AF (the
; plain ground), $B23E = $B4E6 (the tune). Four empty strings printed ($7F00,
; TextNoDate $90B8, $A182, $B2C2: build stamps cut off by a $1F). Then SetIm2
; $A7D4: IM 2 for play.
;
; Called by LifePlay, the title's demo $8064 and the bonus screen $A4EE (after
; each sector). Witness: game 20 runs (1554-16323), a1 4, g1 4, p2 8, h1 4, i1
; 6, i2 6.
LifeStart:
  CALL SceneryColours
  XOR A
  LD (PlayerLights),A
  CALL HudDraw
  CALL ScenerySetup
  LD A,$FF                ; the buggy alive, not dying
  LD (JumpStep),A
  LD (DeathStep),A
  LD (WreckStep),A
  LD HL,$3892             ; the buggy's box: y $92, x $38
  LD (BuggyY),HL
  LD L,$89                ; drawn at y $89: sprite 0 ($A826)
  XOR A
  LD (UfosLeave),A
  LD (DeadFlag),A
  LD (GroundCountdown),A
  LD (TuneDivider),A
  CALL DrawSprite
  LD BC,$0015             ; the shot boxes to $5B60
  LD DE,ShotForward
  LD HL,ShotBoxes
  LDIR
  LD HL,RoadFeed          ; the ground pattern: plain ground
  LD (GroundProfile),HL
  LD HL,Tune              ; the tune from its start
  LD (TunePointer),HL
  LD HL,BuildDate0335     ; four empty print strings (build stamps never
                          ; printed)
  CALL PrintText
  LD HL,TextNoDate
  CALL PrintText
  LD HL,LifeStartDateText
  CALL PrintText
  LD HL,BuildDate0245
  CALL PrintText
  CALL SetIm2             ; IM 2 for play
  RET

; Draws the HUD (rows 0-2): colours, icons, lamps, labels, scores, hi-score,
; TIME, POINT, the course name
;
; Attributes of rows 0-2 from HudAttributes $9621; the player icon
; HudPlayerIcon $9469 at $4000; the HUD panel HudPanel $9481 (64x24 pixels at x
; $50, the four buggy icons, the course marks and the progress bar frame)
; through $AFAB with $B247 = $1800 (lines 0-$17), $B249 = $0850 (x $50, 8 bytes
; a line); the lamp glyph HudLampGlyph $9479 in column 27 of rows 0-2;
; HudTextLamps $93D3 (DANGER! and CAUTION, ink = paper until HudLamps colours
; them); a few attributes of column 0 (rows 1-3).
;
; Then HudLives $9263, HudLamps $927E, HudProgress $92AA; the label 1P (row 1
; when two players, else row 2) and 2P (row 2), the current player's label
; inverted (two cells at $4020 or $4040); the hi-score from the heroes table
; ($88C2, four BCD bytes at x $10 y 1) with "-" and its point letter ($88AC);
; both players' scores (HudPrintScore $92DA, PlayerSwap, again, PlayerSwap);
; TIME and POINT (HudTextTimePoint $93FF) and the point letter (HudPrintPoint
; $9247); BEGINNER or CHAMPION from bit 5 of $B27C after 7 cells cleared at
; $4053; the time (HudPrintTime $922A, its flag $B239 cleared first).
;
; Called by LifeStart, the hi-score entry $8B8F, the bonus screen $A4EE and the
; course switches $BB07 / $BED4. Witness: game 21 runs (1554-16321), a1 4, g1
; 5, p2 9, h1 5, i1 12, i2 12, h2 1. 2P and the inverted label: p2 only ($93F9
; read 9 times in p2).
HudDraw:
  LD HL,HudAttributes
  LD DE,Attributes
  LD BC,$0060
  LDIR
  LD B,$08
  LD DE,HudPlayerIcon
  LD HL,Screen
HudIconLoop:
  LD A,(DE)               ; 8 lines of two bytes
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DEC L
  DJNZ HudIconLoop
  LD HL,$1800             ; the HUD panel: lines 0-$17 at x $50, 8 bytes a line
                          ; ($AFAB)
  LD (BlitTop),HL
  LD HL,$0850
  LD (BlitX),HL
  LD HL,HudPanel
  CALL BlitRows
  LD HL,Screen+27             ; the lamp glyph in column 27 of rows 0, 1, 2
  LD C,$03
HudLampGlyphRow:
  LD DE,HudLampGlyph
  LD B,$08
HudLampGlyphLine:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ HudLampGlyphLine
  LD DE,$F820             ; HL + $F820: back up 8 lines and one row down
  ADD HL,DE
  DEC C
  JR NZ,HudLampGlyphRow
  LD HL,HudTextLamps      ; DANGER! and CAUTION, invisible until the lamps are
                          ; lit
  CALL PrintText
  LD HL,Attributes+96             ; column 0 of rows 3, 2, 1: attributes 7, $16, $16
  LD DE,-$0020
  LD (HL),$07
  ADD HL,DE
  LD (HL),$16
  ADD HL,DE
  LD (HL),$16
  CALL HudLives
  CALL HudLamps
  CALL HudProgress
  LD HL,HudText1P         ; 1P: row 1 (y 9) in a two-player game, else row 2 (y
                          ; $11)
  LD E,$09
  LD A,(Players)
  LD C,A
  CP $02
  JR Z,HudPlayerLabel
  LD E,$11
HudPlayerLabel:
  LD A,$16                ; AT x 2 y E, then the label
  CALL PrintChar
  LD A,$02
  CALL PrintChar
  LD A,E
  CALL PrintChar
  CALL PrintText
  LD A,C
  CP $01
  JR Z,HudHiScore
  LD HL,HudText2P         ; two players: 2P, then the current player's label
                          ; inverted
  CALL PrintText
  LD A,(Player)
  AND A
  RRCA
  RRCA
  RRCA
  LD L,A
  LD H,$40
  LD BC,$08FF
HudLabelInvert:
  LD A,(HL)
  XOR C
  LD (HL),A
  INC L
  LD A,(HL)
  XOR C
  LD (HL),A
  DEC L
  INC H
  DJNZ HudLabelInvert
HudHiScore:
  LD HL,GreatestScore     ; the hi-score from the heroes table at x $10 y 1,
                          ; "-", its point letter
  LD DE,$1001
  LD C,$06
  CALL PrintBcd4
  LD A,$2D
  CALL PrintChar
  LD A,(GreatestPoint)
  CALL HudPrintPointLetter
  CALL HudPrintScore      ; both players' scores: the other one's through two
                          ; swaps
  CALL PlayerSwap
  CALL HudPrintScore
  CALL PlayerSwap
  LD HL,HudTextTimePoint  ; TIME and POINT, the point letter
  CALL PrintText
  CALL HudPrintPoint
  LD HL,HudTextChampion   ; CHAMPION when bit 5 of $B27C is set, else BEGINNER
  LD A,(PlayerPoint)
  AND $20
  JR NZ,HudCourseName
  LD HL,HudTextBeginner
HudCourseName:
  PUSH HL                 ; 7 cells cleared at $4053, then the name
  LD C,$07
  LD HL,Screen+83
  CALL ClearCells
  POP HL
  CALL PrintText
  XOR A                   ; the time printed now: its flag cleared first
  LD (TimeShown),A
  CALL HudPrintTime
  RET

; Prints the time $B285-$B286 (4 digits at x $B3 y 1) once after each clock
; change
;
; Does nothing while the flag $B239 is non-zero; the clock $7F98 clears it.
; Then sets it, clears 3 cells at $4017 and prints the two BCD bytes of the
; time ($9369, 6 pixels a digit).
;
; Called once a main-loop pass ($96FA) and by HudDraw. Witness: game 1597 runs,
; a1 296, g1 498, p2 673, h1 498, i1 3613, i2 3947, h2 41. Printing ($9230): i1
; 523 times, about once a second of play.
HudPrintTime:
  LD HL,TimeShown
  LD A,(HL)
  AND A
  RET NZ
  LD (HL),$FF             ; the time changed: print it
  LD C,$03
  LD HL,Screen+23
  CALL ClearCells
  LD HL,PlayerTime
  LD DE,$B301
  LD BC,$0206
  CALL PrintBcd
  RET

; Prints the letter of the point reached ($B27C) on the HUD after POINT
;
; One cell cleared at $4038, the position from HudTextPointAt $9427 (x $C2 y 9,
; font 2), then falls into HudPrintPointLetter with A = $B27C.
;
; Called by HudDraw and when a point is passed (ObjPoint $9980). Witness: game
; 21 runs, a1 4, g1 5, p2 9, h1 5, i1 37 (12 HUD draws + 25 points), i2 39, h2
; 1.
HudPrintPoint:
  LD C,$01
  LD HL,Screen+56
  CALL ClearCells
  LD HL,HudTextPointAt
  CALL PrintText
  LD A,(PlayerPoint)

; Prints the point letter of A: bits 0-4 the point number, 1 = A, O skipped
;
; A AND $1F, then $40 added, plus 1 from 15 on: 1-14 are A-N, 15-25 are P-Z
; ('O' is no point). 0 prints '@' (no point passed yet). Called by
; HudPrintPoint, HudPrintScore (the score's point letter), HudDraw (the
; hi-score's) and the bonus screen $A4EE. Witness: game 88 runs, i1 382, i2
; 519.
HudPrintPointLetter:
  AND $1F
  CP $0F
  CCF
  ADC A,$40
  CALL PrintChar
  RET

; Shows the lives in reserve ($B284) as buggy icons: up to four, colour pairs
; at $580A-$5811
;
; Four pairs of cells on row 0 (columns 10-17, the icons of HudPanel): a pair
; whose index is below the lives gets attribute $1F (white on magenta, seen),
; the others $1B (ink = paper, hidden). Called by HudDraw and by ScoreAddBcd
; $9311 when an extra life is given. Witness: game 21 runs, i1 14 (12 HUD draws
; + the two extra lives at 10000 and 30000), i2 15.
HudLives:
  LD A,(PlayerLives)
  AND A
  RL A
  ADD A,$08
  LD HL,Attributes+10
  LD B,$04
HudLivesLoop:
  LD C,$1B
  CP L
  JR C,HudLivesSet
  LD C,$1F
HudLivesSet:
  LD (HL),C
  INC HL
  LD (HL),C
  INC HL
  DJNZ HudLivesLoop
  RET

; Colours the warning lamps from $B27E (0-3): 3 rows of 5 attributes at $581B
; from HudLampColours
;
; The pattern is HudLampColours + 15 x ($B27E AND 3): column 27 the lamp,
; columns 28-31 the text. 0 lights the bottom lamp green; 1 the middle lamp
; yellow and CAUTION white; 2 the top lamp red and DANGER! white; 3 both, red
; and yellow. Called by HudDraw and by the lamp object ObjLamps $99A3. Witness:
; game 21 runs, i1 36, i2 41; the patterns read (HudLampColours reads) in i1: 0
; 15 times, 1 13, 2 6, 3 2; in i2: 13, 10, 10, 8.
HudLamps:
  LD A,(PlayerLights)
  LD HL,HudLampColours
  AND $0F
  LD D,A
  RLCA
  RLCA
  RLCA
  RLCA
  SUB D
  LD D,$00
  LD E,A
  ADD HL,DE
  EX DE,HL
  LD HL,Attributes+27
  EXX
  LD C,$03
HudLampsRow:
  EXX
  LD B,$05
HudLampsCell:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC HL
  DJNZ HudLampsCell
  LD BC,$001B
  ADD HL,BC
  EXX
  DEC C
  JR NZ,HudLampsRow
  EXX
  RET

; Plots the course progress bar: a solid bar of 2x2 blocks that touch, one a
; point, from x $57 to 2 x point + $56, y $13-$14
;
; Nothing at point 0. Uses HudPlot $92CD (the OR plot $FD80, H = x, L = y).
; Called by HudDraw and when a point is passed (ObjPoint). Witness: game 21
; runs, i1 37, i2 39; the dots ($92CD) i1 1900.
HudProgress:
  LD A,(PlayerPoint)
  AND $1F
  RET Z
  RL A
  ADD A,$56
  LD HL,Screen+5907
HudProgressLoop:
  CP H
  RET C
  PUSH AF
  CALL HudPlot
  INC L
  CALL HudPlot
  INC H
  CALL HudPlot
  DEC L
  CALL HudPlot
  INC H
  POP AF
  JR HudProgressLoop

; Plots one pixel at H = x, L = y ($FD80), keeping HL
;
; Witness: i1 1900 runs, i2 1912 (only from HudProgress, no dots at point 0).
HudPlot:
  PUSH HL
  CALL PlotPixel
  POP HL
  RET

; Adds DEBC (8 BCD digits) to the score, gives the extra lives, prints the
; score
;
; ScoreAddBcd $9311, then HudPrintScore $92DA. The values the callers pass (BC,
; DE = 0): 100 the rock shot or hit (ObjRock $9A21), 80 the rock jumped
; ($9A3E), 100 the crater jumped ($9AD8), 50 the mine jumped ($9B36), 25 the
; kill $A7DD; the other handlers from $9B6B on (annotator 03) and the bonus
; $A4EE pass their own.
;
; Witness: game 25 runs (2029-16149), a1 4, g1 16, p2 16, h1 16, i1 291, i2
; 424, h2 3.
ScoreAdd:
  CALL ScoreAddBcd
  CALL HudPrintScore
  RET

; Prints the current player's score at x $10 (row 1 for player 1 of two, else
; row 2), "-", the point letter
;
; E = y: $11 (row 2), or 9 (row 1) for player 1 of a two-player game; the
; record of player 2 in a one-player game prints nothing. 8 cells cleared at
; $4022 or $4042, the 8 digits ($9364, 6 pixels apart, leading zeros blank),
; "-", the point letter of $B27C. Witness: game 67 runs, a1 12, g1 26, p2 34,
; h1 26, i1 340, i2 475, h2 5. Player 1 of two ($92EB): p2 34.
HudPrintScore:
  LD A,(Players)
  LD E,$11
  CP $02
  LD A,(Player)
  JR Z,HudScoreTwo
  CP $01
  JR Z,HudScoreAt
  RET
HudScoreTwo:
  CP $02
  JR Z,HudScoreAt
  LD E,$09
HudScoreAt:
  LD A,E                  ; HL = $4022 + $20 when y is $11
  AND $10
  RLCA
  LD HL,Screen+34
  ADD A,L
  LD L,A
  LD C,$08
  CALL ClearCells
  LD D,$10
  LD C,$06
  CALL HudPrintScoreDigits
  LD A,$2D
  CALL PrintChar
  LD A,(PlayerPoint)
  JP HudPrintPointLetter

; Adds DEBC to the score $B272-$B275 (BCD) and gives an extra life each time it
; passes $B276-$B279
;
; C to $B275, B to $B274, E to $B273, D to $B272, each with DAA and the carry.
; Below 60000 points ($B273 < 6) the score is compared with the extra-life
; score $B276-$B279: when reached, a life is added ($B284), HudLives shows it,
; and the extra-life score goes up 20000 ($B277 + 2). The extra lives: 10000,
; 30000, 50000; none from 60000 on.
;
; Witness: game 25 runs, i1 291, i2 424; the extra life ($9344-$935D) i1 2, i2
; 3. The carry into the top byte ($932C) and the carry of the extra-life score
; into $B276 ($935E-$9363) are not executed in any recording (game, a1, g1, t1,
; p2, h1, i1, i2, h2): known only from the code.
ScoreAddBcd:
  LD HL,PlayerScore+$0003
  LD A,C
  ADD A,(HL)
  DAA
  LD (HL),A
  DEC HL
  LD A,B
  JR NC,ScoreAddHundreds
  INC A
ScoreAddHundreds:
  ADD A,(HL)
  DAA
  LD (HL),A
  DEC HL
  LD A,E
  JR NC,ScoreAddTenThousands
  INC A
ScoreAddTenThousands:
  ADD A,(HL)
  DAA
  LD (HL),A
  DEC HL
  LD A,D
  JR NC,ScoreAddMillions
  INC A
ScoreAddMillions:
  ADD A,(HL)
  DAA
  LD (HL),A
  LD A,(PlayerScore+$0001) ; from 60000 points on, no more extra lives
  CP $06
  RET NC
  LD DE,PlayerScore       ; score >= the extra-life score?
  LD HL,PlayerNextLife
  LD A,(DE)
  CP (HL)
  RET C
  INC HL
  INC DE
  LD A,(DE)
  CP (HL)
  RET C
  INC HL
  INC DE
  LD A,(DE)
  CP (HL)
  RET C
  INC HL
  INC DE
  LD A,(DE)
  CP (HL)
  RET C
  LD HL,PlayerLives       ; an extra life
  INC (HL)
  CALL HudLives
  LD HL,PlayerNextLife+$0001 ; the next one 20000 points further
  LD A,$02
  ADD A,(HL)
  DAA
  LD (HL),A
  RET NC
  DEC HL
  LD A,(HL)
  INC A
  DAA
  LD (HL),A
  RET

; HL = the score $B272: falls into PrintBcd4
;
; Witness: game 46 runs, i1 328, i2 463.
HudPrintScoreDigits:
  LD HL,PlayerScore

; Prints 4 BCD bytes (8 digits) from HL: B = 4, then PrintBcd
;
; Also called by the hi-score tables ($8A4C, $8A96, $8AE0) and HudDraw.
; Witness: game 267 runs, a1 112, i1 340, i2 475.
PrintBcd4:
  LD B,$04

; Prints B BCD bytes from HL at x D y E, C pixels a digit, leading zeros left
; blank (the last digit always shown)
;
; Each digit goes out as $16 x y and the character through $FDCC. Called by
; PrintBcd4, HudPrintTime and the hi-score tables. Witness: routine entries
; game 711, a1 255, g1 96, p2 142, h1 195, i1 1017, i2 1248, h2 11 (PrintBcd4
; falls into it, the time print calls it).
PrintBcd:
  LD A,(HL)
  SRL A
  SRL A
  SRL A
  SRL A
  JR NZ,PrintBcdHigh
  LD A,D
  ADD A,C
  LD D,A
  LD A,B
  CP $01
  JR Z,PrintBcdLow
  LD A,(HL)
  AND $0F
  JR NZ,PrintBcdLowDigit
  LD A,D
  ADD A,C
  LD D,A
  INC HL
  DJNZ PrintBcd
PrintBcdNext:
  LD A,(HL)               ; after the first digit shown: every digit
  SRL A
  SRL A
  SRL A
  SRL A
PrintBcdHigh:
  ADD A,$30               ; the high digit of the byte
  PUSH AF
  LD A,$16
  CALL PrintChar
  LD A,D
  CALL PrintChar
  LD A,E
  CALL PrintChar
  POP AF
  CALL PrintChar
  LD A,D
  ADD A,C
  LD D,A
PrintBcdLow:
  LD A,(HL)               ; the low digit of the byte
  AND $0F
PrintBcdLowDigit:
  ADD A,$30
  PUSH AF
  LD A,$16
  CALL PrintChar
  LD A,D
  CALL PrintChar
  LD A,E
  CALL PrintChar
  POP AF
  CALL PrintChar
  LD A,D
  ADD A,C
  LD D,A
  INC HL
  DJNZ PrintBcdNext
  RET

; Clears C cells from the screen address HL (8 pixel lines each)
;
; Witness: game 345 runs, a1 61, g1 104, p2 156, h1 104, i1 1035, i2 1268, h2
; 15.
ClearCells:
  XOR A
ClearCellsLoop:
  PUSH HL
  LD B,$08
ClearCellsLines:
  LD (HL),A
  INC H
  DJNZ ClearCellsLines
  POP HL
  INC HL
  DEC C
  JR NZ,ClearCellsLoop
  RET

; Print string: ink 1 paper 1, AT x $E0 y 2 "DANGER!", AT x $E0 y $0A "CAUTION"
; (the lamp texts)
;
; Printed by HudDraw $9180 in blue on blue: HudLamps colours them. game 21
; reads.
HudTextLamps:
  INCBIN "res/text/HudTextLamps.bin",$0000,33

; Print string: font 2, "1P" (HudDraw puts the position first)
HudText1P:
  INCBIN "res/text/HudText1P.bin",$0000,5

; Print string: AT x 2 y $11, "2P" (two players only: p2 9 reads)
HudText2P:
  INCBIN "res/text/HudText2P.bin",$0000,6

; Print string: AT x $9B y 1 "TIME", AT x $9E y 9 "POINT"
HudTextTimePoint:
  INCBIN "res/text/HudTextTimePoint.bin",$0000,16

; Print string: AT x $9B y $11 "BEGINNER" (game 21 reads)
HudTextBeginner:
  INCBIN "res/text/HudTextBeginner.bin",$0000,12

; Print string: AT x $9B y $11 "CHAMPION" (read i1 1: the Champion course after
; Z; i2 11)
HudTextChampion:
  INCBIN "res/text/HudTextChampion.bin",$0000,12

; Print string: AT x $C2 y 9, font 2 (the point letter follows: HudPrintPoint)
HudTextPointAt:
  INCBIN "res/text/HudTextPointAt.bin",$0000,6

; The warning lamp attributes: 4 patterns ($B27E 0-3) of 3 rows x 5 cells (the
; lamp, then the text)
;
; Read by HudLamps $927E: pattern = $942D + 15 x $B27E. Column 27 the lamp
; glyph, columns 28-31 the text. $08 / $09 unlit (black or blue ink on blue),
; $0C green, $0E yellow, $0A red, $0F white text.
HudLampColours:
  DEFB $08,$09,$09,$09,$09 ; 0: all clear: the bottom lamp green
  DEFB $08,$09,$09,$09,$09
  DEFB $0C,$09,$09,$09,$09
  DEFB $08,$09,$09,$09,$09 ; 1: the middle lamp yellow, CAUTION
  DEFB $0E,$0F,$0F,$0F,$0F
  DEFB $08,$09,$09,$09,$09
  DEFB $0A,$0F,$0F,$0F,$0F ; 2: the top lamp red, DANGER!
  DEFB $08,$09,$09,$09,$09
  DEFB $08,$09,$09,$09,$09
  DEFB $0A,$0F,$0F,$0F,$0F ; 3: red and yellow, DANGER! and CAUTION
  DEFB $0E,$0F,$0F,$0F,$0F
  DEFB $08,$09,$09,$09,$09

; A 16x8 icon drawn at the top left of the HUD ($4000) by HudDraw
HudPlayerIcon:
  DEFB $00,$00
  DEFB $20,$08
  DEFB $31,$18
  DEFB $3B,$B8
  DEFB $3B,$B8
  DEFB $3F,$F8
  DEFB $3F,$F8
  DEFB $00,$00

; The lamp glyph (a round light), drawn in column 27 of rows 0-2 by HudDraw
; (game 63 reads)
HudLampGlyph:
  DEFB $00,$18,$3C,$7E,$7E,$7E,$3C,$18

; The HUD panel: 24 lines of 8 bytes at x $50, rows 0-2: the four buggy icons,
; the course marks, the progress bar frame
;
; Drawn by $AFAB from HudDraw. Lines 0-7: four 16x8 buggies (HudLives shows or
; hides each by its colour); lines 10-14: small marks over the bar; lines
; 16-21: the frame of the progress bar that HudProgress fills. game 21 reads.
HudPanel:
  DEFB $04,$00,$04,$00,$04,$00,$04,$00
  DEFB $04,$F8,$04,$F8,$04,$F8,$04,$F8
  DEFB $05,$08,$05,$08,$05,$08,$05,$08
  DEFB $1F,$FC,$1F,$FC,$1F,$FC,$1F,$FC
  DEFB $3F,$F8,$3F,$F8,$3F,$F8,$3F,$F8
  DEFB $3F,$F8,$3F,$F8,$3F,$F8,$3F,$F8
  DEFB $19,$98,$19,$98,$19,$98,$19,$98
  DEFB $19,$98,$19,$98,$19,$98,$19,$98
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; lines 8-9: empty
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $01,$01,$C0,$38,$1C,$05,$01,$C0 ; lines 10-15: the marks over the bar
  DEFB $01,$81,$00,$10,$14,$05,$00,$40
  DEFB $07,$C1,$C0,$10,$1C,$05,$00,$80
  DEFB $01,$81,$00,$50,$10,$05,$01,$00
  DEFB $01,$01,$C0,$70,$10,$07,$01,$C0
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$80,$20,$08,$02,$00,$80 ; lines 16-23: the progress bar frame
  DEFB $02,$AA,$AA,$AA,$AA,$AA,$AA,$80
  DEFB $03,$FF,$FF,$FF,$FF,$FF,$FF,$80
  DEFB $02,$00,$00,$00,$00,$00,$00,$80
  DEFB $02,$00,$00,$00,$00,$00,$00,$80
  DEFB $03,$FF,$FF,$FF,$FF,$FF,$FF,$80
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The backdrop: the mountains or the city for $B27D, drawn on rows 8-11 and the
; scroll pointers set
;
; Mountains ($B27D = 0): $B22C = $E340, $B22E = $E780, $B22A = $E720; the city:
; $E780, $EBC0, $EB60. $B228 / $B224 = 0, $B226 = $EFA0. Draws 4 rows of 32
; columns from $EBC0 at $4800 (rows 8-11) and 4 rows from ($B22C) at $4880
; (rows 12-15) with SceneryDrawRows $9590, then copies 32 bytes from the ROM at
; $2000 to the pixel line $5080 (row 20). The scrollers that use these pointers
; are the main loop's ($A846, $A89A ...).
;
; Called by LifeStart and the title $8064 (with $B27D = $FF). Witness: game 20
; runs, a1 24, g1 4, t1 1, p2 8, h1 4, i1 6, i2 6. The city: game 0, i1 2 (the
; sectors from F and Q).
ScenerySetup:
  LD BC,MountainsStrip
  LD DE,MoonBaseStrip
  LD HL,MountainsStrip+$03E0
  LD A,(PlayerScenery)
  AND A
  JR Z,SceneryStore
  LD BC,MoonBaseStrip
  LD DE,HillsStrip
  LD HL,MoonBaseStrip+$03E0
SceneryStore:
  LD (MiddleStart),BC
  LD (MiddleEnd),DE
  LD (MiddleColumn),HL
  XOR A
  LD (MiddleCountdown),A
  LD (FarCountdown),A
  LD HL,HillsStrip+$03E0
  LD (FarColumn),HL
  LD DE,HillsStrip
  LD HL,Screen+2048
  CALL SceneryDrawRows
  LD DE,(MiddleStart)
  LD HL,Screen+2176
  CALL SceneryDrawRows
  LD BC,$0020
  LD DE,Screen+4224
  LD HL,$2000
  LDIR
  RET

; Draws 32 columns x 4 rows of 8 lines from DE (column by column) at the screen
; address HL
;
; Witness: game 40 runs, i1 12 (two calls each ScenerySetup).
SceneryDrawRows:
  EXX
  LD B,$20
SceneryColumn:
  EXX
  LD C,$04
SceneryCell:
  LD B,$08
SceneryLine:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ SceneryLine
  PUSH BC
  LD BC,$F820
  ADD HL,BC
  POP BC
  DEC C
  JR NZ,SceneryCell
  LD BC,-$007F
  ADD HL,BC
  EXX
  DJNZ SceneryColumn
  EXX
  RET

; Picks the scenery colour set ($B27D: SceneryColourSets $9617 or $961C) and
; paints rows 3-23
;
; $B230 = the set. Rows 3-7 = set +0, 12-15 = +2, 16-19 = +3, 20-21 = +4, then
; SceneryColoursRepaint: rows 8-11 = +1, rows 22-23 = +4 paper only. Called by
; LifeStart and the title $8064. Witness: game 20 runs, a1 24, t1 1, i1 6, i2
; 6; the city set ($95B9) a1 21, i1 2, i2 2.
SceneryColours:
  LD HL,SceneryColourSets
  LD A,(PlayerScenery)
  AND A
  JR Z,SceneryColoursSet
  LD HL,SceneryColourSets+$0005
SceneryColoursSet:
  LD (ColourScheme),HL
  PUSH HL
  POP IX
  LD HL,Attributes+96
  LD DE,Attributes+97
  LD BC,$00A0
  LD A,(IX+$00)
  LD (HL),A
  LDIR
  LD HL,Attributes+384
  LD DE,Attributes+385
  LD BC,$0080
  LD A,(IX+$02)
  LD (HL),A
  LDIR
  LD BC,$0080
  LD A,(IX+$03)
  LD (HL),A
  LDIR
  LD BC,$0040
  LD A,(IX+$04)
  LD (HL),A
  LDIR

; Paints rows 8-11 with the set's colour +1 and rows 22-23 with the paper of
; +4, every main-loop pass
;
; Called once a pass from MainLoopCalls $96FA (so the colours the sprites leave
; there are wiped) and by SceneryColours. Witness: game 1596 runs, a1 315, g1
; 497, p2 672, h1 497, i1 3606, i2 3940, h2 40.
SceneryColoursRepaint:
  LD IX,(ColourScheme)
  LD HL,Attributes+256
  LD DE,Attributes+257
  LD BC,$007F
  LD A,(IX+$01)
  LD (HL),A
  LDIR
  LD HL,Attributes+704
  LD DE,Attributes+705
  LD BC,$0040
  LD A,(IX+$04)
  AND $F8
  LD (HL),A
  LDIR
  RET

; The two scenery colour sets, 5 attributes each: rows 3-7, 8-11, 12-15, 16-19,
; 20-23
;
; Picked by SceneryColours from $B27D: 0 the mountains, $FF the city ($B27D
; comes from the sector-end record of the bonus screen $A4EE). The byte +1 is
; read every pass (SceneryColoursRepaint); +3 is read by other routines through
; $B230 too (i2: 2094 reads of $961A).
SceneryColourSets:
  DEFB $07,$02,$14,$20,$34 ; the mountains
  DEFB $07,$02,$16,$30,$26 ; the city

; The attributes of the HUD rows 0-2, copied to $5800 by HudDraw
HudAttributes:
  DEFB $16,$16,$2A,$2A,$2A,$2A,$2A,$2A,$28,$28,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$1B,$28,$28,$28,$28,$28,$2A,$2A,$2A,$2A,$08,$09,$09,$09,$09
  DEFB $16,$16,$2A,$2A,$2A,$2A,$2A,$2A,$28,$28,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$28,$28,$28,$28,$28,$28,$2A,$2A,$2A,$08,$09,$09,$09,$09
  DEFB $16,$16,$2A,$2A,$2A,$2A,$2A,$2A,$28,$28,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$29,$29,$29,$29,$29,$29,$29,$29,$29,$08,$09,$09,$09,$09

; The shots' boxes, copied to $5B60 at each life start: y, x, height, width of
; a flat 3x6 shot (+1 byte), then four 4x3 boxes
;
; LifeStart copies these 21 bytes to the printer buffer $5B60. y = $FF means no
; shot. The rock handler ObjRock $99C3 tests its box against the first one (the
; forward shot) with $A7FE and sets its x ($5B62) to $FF on a hit. The names
; forward / up shot are from the shapes and from the rock (a ground object)
; testing only the first box; the writers of these boxes and the users of the
; four 4-byte boxes (height 4, width 3) are outside this range.
ShotBoxes:
  DEFB $FF,$00,$03,$06,$00 ; the forward shot: y $FF (none), x 0, height 3,
                           ; width 6, one more byte
  DEFB $FF,$00,$04,$03,$FF,$00,$04,$03 ; the up shots, 4 bytes each: y $FF, x
  DEFB $FF,$00,$04,$03,$FF,$00,$04,$03 ; 0, height 4, width 3
