; --------------------------------------------------------------------------------------------------------------------
; main.asm: The game flow: the game's start, the cave start, the play loop, the timer, the cave's ends
;
; NewGame $8BE5 runs StartGameEntry $89F4: StartGame $85D6 (the password, 5 lives, the score 0), then CaveStart $89F7
; for each cave: ClearScreen, the flags 0, CaveIntro $92D4 (the level, the lives, the score, the cave name), the
; cave's tune (PlayCaveTune $EE34), PlayCave $8885. NextCave $8A07 then takes the next cave (after cave 32 the win
; screen, then cave 1 again) or a life.
;
; A pass of PlayCave: KeysStep $8759 (the player), PutPlayer $8382, AbortKey $93A5 (G), ClearVacated $81AC,
; WindowOrigin $8DA6 (the window drawn), MapKey $EA96 (F), ColourCycle $81E7 (with the cell update and the pass
; sound), FizzSound $A773, TimerStep $86DE, QuitKey $872D (H). It ends when CaveOver $FD7D is set (out of time or
; quit), PlayerKilled $7FFD (DeathView $903F, DeathSound $862E) or CaveDone $FD84 (the exit entered: TimeBonus $8702).
; The game has no frame sync (no HALT): a pass takes as long as its work and its sounds.
; --------------------------------------------------------------------------------------------------------------------

  ORG $81E7

; Step the cycling colour, flash the open exit, then the pass sound
;
; ColourPhase $FD8E steps; ColourCycleInk $FD8F cycles $43-$46 (DrawPass $8D46
; writes it into the gem graphic). ExitFlash $905B. Ends with JP PassSoundEntry
; $8250.
;
; Witness: L1 44097 (c1, hiscore, lives, timer, rzx x32).
ColourCycle:
  LD A,(ColourCycleInk)
  CP $46
  JR NZ,ColourCycleSkip
  LD HL,ColourPhase
  LD (HL),$FF
ColourCycleSkip:
  CP $43
  JR NZ,ColourCycleSkip2
  LD HL,ColourPhase
  LD (HL),$01
ColourCycleSkip2:
  LD HL,ColourCycleInk
  LD A,(ColourPhase)
  CP $FF
  JR Z,ColourCycleSkip3
  INC (HL)
  CALL ExitFlash
  RET
ColourCycleSkip3:
  DEC (HL)
  CALL ExitFlash
  RET

; Leftover: CALL $8059, CALL $81CC, CALL $81E7, RET (10 bytes), never run
ColourCyclePad:
  DEFB $CD,$59,$80,$CD,$CC,$81,$CD,$E7
  DEFB $81,$C9

; Clear the variables and the cave grid, $FD7A-$FFFF
;
; HL = $FD7A, DE = HL + 1, BC = $028A, (HL) = 0, LDIR: the copy runs on past
; $FFFF into $0000-$0004 (the ROM: no effect).
;
; Witness: L1 9 (c1, lives, menu).
ClearVars:
  LD HL,ClearStart
  LD DE,VarsFD7B
  LD BC,$028A
  LD (HL),$00
  LDIR
  RET

  ORG $82E6

; The first cave, 4 lives, the colour phase
;
; ColourPhase $FD8E = 1, CaveNumber $FD91 = 1, Lives $FD93 = 4, Unused99 $FD90
; = 99. StartGame $85D6 sets 5 lives later.
;
; Witness: L1 9 (c1, lives, menu).
ResetGame:
  LD A,$01
  LD (ColourPhase),A
  LD (CaveNumber),A
  LD A,$04
  LD (Lives),A
  LD A,$63
  LD (Unused99),A
  RET

  ORG $85F1

; Clear the cave's state and print the HUD
;
; CaveDone, ExitOpen and GemDigits 0, GemCount 0; SetEarthFalls $FB81,
; FaceLeft, ShowHudLine, ShowScore, ShowCounters.
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
ResetCave:
  LD HL,$0000
  LD (CaveDone),HL
  LD (GemDigits),HL
  XOR A
  LD (GemCount),A
  CALL SetEarthFalls
  CALL FaceLeft
  CALL ShowHudLine
  CALL ShowScore
  CALL ShowCounters
  RET

  ORG $8687

; Reset the anti-gravity and the cave state, fill the time bar
;
; ResetAntiGrav $A64B, ResetCave $85F1, FillTimeBar $8654.
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
CaveReset:
  CALL ResetAntiGrav
  CALL ResetCave
  CALL FillTimeBar
  RET

; Shift the time bar one pixel left
;
; 8 pixel lines from $50DF: RL through the 32 bytes of a line, the rightmost
; first. The bar's first byte $52C0 empties last.
;
; Witness: L1 15905 (c1, hiscore, lives, timer, rzx x32).
ShiftTimeBar:
  LD HL,Screen+4319
  LD B,$08
ShiftTimeBarLoop:
  PUSH BC
  PUSH HL
  LD B,$1F
  RL (HL)
  LD A,(HL)
  DEC HL
ShiftTimeBarLoop2:
  RL (HL)
  DEC HL
  DJNZ ShiftTimeBarLoop2
  DEC HL
  POP HL
  LD BC,$0100
  ADD HL,BC
  POP BC
  DJNZ ShiftTimeBarLoop
  RET

; The time-out sound: a falling sweep
;
; LD C,(HL) then AND $7F: the AND acts on A, so C keeps the full ROM byte (a 0
; byte gives a 256-turn low half).
;
; Witness: L1 14 (c1, hiscore, lives, timer, rzx x1).
TimeOutSound:
  DI
  LD HL,$0180
TimeOutSoundLoop:
  LD C,(HL)
  AND $7F
  LD B,$08
TimeOutSoundLoop2:
  XOR A
  OUT ($FE),A
  LD E,C
TimeOutSoundLoop3:
  DEC E
  JR NZ,TimeOutSoundLoop3
  LD A,$18
  OUT ($FE),A
  LD A,L
  AND $7F
  LD E,A
  XOR A
  SUB E
  SUB C
  LD E,A
TimeOutSoundLoop4:
  DEC E
  JR NZ,TimeOutSoundLoop4
  DJNZ TimeOutSoundLoop2
  DEC L
  JR NZ,TimeOutSoundLoop
  EI
  RET

; Leftover: 11 bytes, never run
TimeOutPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00

; The timer: every fourth pass the bar loses a pixel; an empty bar ends the
; cave
;
; TimerSub $FD7C + $40; on the wrap: ShiftTimeBar $8691 and a ROM BEEPER click
; (HL = 0, DE = 0). The bar's first byte $52C0 at 0: TimeOutSound $86AD,
; CaveOver $FD7D = $FF.
;
; Witness: L1 44229 (c1, hiscore, lives, timer, rzx x32).
TimerStep:
  LD A,(TimerSub)
  ADD A,$40
  LD (TimerSub),A
  OR A
  RET NZ
  CALL ShiftTimeBar
  LD HL,$0000
  LD DE,$0000
  CALL RomBeeper
  LD A,(Screen+4800)
  OR A
  RET NZ
  CALL TimeOutSound
  LD A,$FF
  LD (CaveOver),A
  RET

; The cave done: every remaining bar pixel is a point
;
; DI at its start, but the first BEEPER's EI turns them on again: 41 of the 45
; interrupts in the bonus are taken (rzx-earth01 3668-3713). While $52C0 is not
; 0: BonusTick $871C (a beep, D its period, rising), ShiftTimeBar, AddPoint,
; ShowScore.
;
; Witness: L1 31 (rzx x31).
TimeBonus:
  DI
  LD D,$00
TimeBonusLoop:
  PUSH DE
  CALL BonusTick
  CALL ShiftTimeBar
  CALL AddPoint
  CALL ShowScore
  POP DE
  DEC D
  LD A,(Screen+4800)
  OR A
  JR NZ,TimeBonusLoop
  EI
  RET

; One bonus beep: ROM BEEPER HL = D, DE = 1; its three DEC D are lost to
; TimeBonus's POP DE, so D falls by 1 a pixel (TimeBonus's own DEC D)
;
; Witness: L1 1983 (rzx x31).
BonusTick:
  LD H,$00
  LD L,D
  PUSH DE
  LD DE,$0001
  CALL RomBeeper
  POP DE
  DEC D
  DEC D
  DEC D
  RET

; Leftover: 2 bytes, never run
TimeBonusPad:
  DEFB $00,$00

; Key H (half row $BF, bit 4): drain the time bar, end the cave
;
; Shifts the bar with a click until it is empty, then CaveOver $FD7D = $FF and
; TimeOutSound: NextCave takes a life.
;
; Witness: L1 44097 (c1, hiscore, lives, timer, rzx x32).
QuitKey:
  LD A,$BF
  OUT ($FF),A
  IN A,($FE)
  AND $10
  RET NZ
  DI
QuitKeyLoop:
  CALL ShiftTimeBar
  LD HL,$0001
  LD DE,$0000
  PUSH HL
  CALL RomBeeper
  POP HL
  NOP
  NOP
  NOP
  NOP
  LD A,(Screen+4800)
  OR A
  JR NZ,QuitKeyLoop
  LD A,$FF
  LD (CaveOver),A
  CALL TimeOutSound
  EI
  RET

  ORG $8885

; Play a cave: passes until out of time, killed or done
;
; CaveOver $FD7D = 0, CaveInit $91B9; each pass KeyMoved $FD80 = 0, then the
; steps of the module header. CaveOver ends it; PlayerKilled: DeathView $903F,
; DeathSound $862E; CaveDone: TimeBonus $8702.
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
PlayCave:
  LD HL,CaveOver
  LD (HL),$00
  CALL CaveInit
PassLoop:
  LD HL,KeyMoved
  LD (HL),$00
  CALL KeysStep
  CALL PutPlayer
  CALL AbortKey
  CALL ClearVacated
  CALL WindowOrigin
  CALL MapKey
  CALL ColourCycle
  CALL FizzSound
  CALL TimerStep
  CALL QuitKey
  LD A,(CaveOver)
  OR A
  RET NZ
  LD A,(PlayerKilled)
  OR A
  JR Z,CheckCaveDone
  CALL DeathView
  CALL DeathSound
  RET
CheckCaveDone:
  LD A,(CaveDone)
  OR A
  JR Z,NextPass
  CALL TimeBonus
  RET
NextPass:
  JR PassLoop

  ORG $89EA

; The cave's intro, its tune and its play
;
; CaveIntro $92D4, PlayCaveTuneJump $895D, PlayCave $8885 ($89F0).
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).
CavePlay:
  CALL CaveIntro
  CALL PlayCaveTuneJump
  CALL PlayCave
  RET

; A game: StartGame, then the caves
;
; Witness: L1 3 (c1, lives, rzx x1).
StartGameEntry:
  CALL StartGame

; Start a cave: clear the screen and the flags, play it
;
; ClearScreen $860E, PlayerKilled, CaveOver and CaveDone 0, CavePlay $89EA;
; then NextCave.
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).
CaveStart:
  CALL ClearScreen
  XOR A
  LD (PlayerKilled),A
  LD (CaveOver),A
  LD (CaveDone),A
  CALL CavePlay

; After a cave: the next one, or a life lost
;
; CaveDone: the cave digits + 1, CaveNumber + 1; after 32 (CaveNumber $21)
; WinGame $A8BF and cave 1. Not done: Lives - 1; at 0 the game ends (RET), else
; the same cave again.
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx x32).
NextCave:
  LD A,(CaveDone)
  OR A
  JR NZ,NextCaveSkip
  LD A,(Lives)
  DEC A
  LD (Lives),A
  OR A
  RET Z
  JR CaveStart
NextCaveSkip:
  LD B,$02
  LD HL,CaveDigits+$0001
  CALL IncDigits
  LD A,(CaveNumber)
  INC A
  LD (CaveNumber),A
  CP $21
  JR NZ,NextCaveSkip2
  CALL WinGame
  LD A,$01
  LD (CaveNumber),A
NextCaveSkip2:
  JR CaveStart

  ORG $8BE5

; Key 1: a game, then the high-score check
;
; StartGameEntry $89F4, then GameOver $7FF3 ($8BE8).
;
; Witness: L1 3 (c1, lives, rzx x1).
NewGame:
  CALL StartGameEntry
  CALL GameOver
  RET

  ORG $903F

; The killed player: the death graphics in the player's table words, the window
; redrawn
;
; $8006 = $9DB4, $8008 = $9DD8, DrawWindow at ViewOrigin.
;
; Witness: L1 1 (c1).
DeathView:
  LD HL,GfxDeathRight
  LD (CellPlayerRightGfx),HL
  LD HL,GfxDeathLeft
  LD (CellPlayerLeftGfx),HL
  LD HL,(ViewOrigin)
  CALL DrawWindow
  RET

; AnimPhase = 3, CaveReset
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
CaveStartState:
  LD A,$03
  LD (AnimPhase),A
  CALL CaveReset
  RET

; Flash the exit door's colour while the exit is open
;
; Witness: L1 44097 (c1, hiscore, lives, timer, rzx x32).
ExitFlash:
  LD A,(ExitOpen)
  OR A
  RET Z
  LD A,(ColourCycleInk)
  LD (CellGraphics),A
  LD (CellGraphics+$0003),A
  AND $3F
  LD (CellGraphics+$0001),A
  LD (CellGraphics+$0002),A
  RET

  ORG $91B9

; A cave's start: CaveStartState, MapShown and PlayerKilled 0
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
CaveInit:
  CALL CaveStartState
  XOR A
  CALL ClearMapFlag
  RET

  ORG $92D4

; The cave's intro screen: level, lives, score, the cave name centred on row 20
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).
CaveIntro:
  CALL ColourLevelLivesScore
  LD A,(CaveNumber)
  LD B,A
  INC B
  LD DE,$0014
  LD HL,CaveNames-20
CaveIntroLoop:
  ADD HL,DE
  DJNZ CaveIntroLoop
  PUSH HL
  LD B,$14
CaveIntroLoop2:
  DEC HL
  LD A,$20
  CP (HL)
  JR NZ,CaveIntroSkip
  DJNZ CaveIntroLoop2
CaveIntroSkip:
  LD A,$15
  SUB B
  AND $FE
  RRCA
  ADD A,$05
  LD C,A
  LD B,$08
  POP HL
  SBC HL,DE
  LD DE,$1400
  CALL PrintText
  RET

  ORG $93A5

; Key G (half row $FD, bit 4): back to the menu, the return addresses dropped
;
; The four POPs drop the returns of PlayCave, CavePlay, CaveStart and NewGame
; ($889B, $89F3, $8A07, $8BE8, the CALL GameOver); the RET reaches $8B42 (JP
; GameEntry): no game-over screen, no high-score check. Witness: c1, AbortKey
; last at 15 244, GameOver never runs.
;
; Witness: L1 44099 (c1, hiscore, lives, timer, rzx x32).
AbortKey:
  CALL AnimateCellCodes
  LD A,$FD
  OUT ($FF),A
  IN A,($FE)
  AND $10
  RET NZ
  POP HL
  POP HL
  POP HL
  POP HL
  RET

  ORG $A615

; Play WinTune $6EF4
;
; Witness: L1 1 (rzx x1).
PlayWinTune:
  LD HL,WinTune
  CALL PlayTune

; RET after the win tune
;
; Known only from the code: the rzx32 recording ends during the tune.
PlayWinTuneEnd:
  RET

; Clear the screen, draw three cells (the player and two gems)
;
; Witness: L1 1 (rzx x1).
WinScreen:
  CALL ClearScreen
  LD HL,GfxPlayerRight
  LD (CellPlayerRightGfx),HL
  LD A,$03
  LD BC,$020F
  CALL DrawCell
  LD A,$07
  LD BC,$0212
  CALL DrawCell
  LD BC,$020C
  LD A,$07
  CALL DrawCell
  RET

  ORG $A64B

; ResetAntiGravState, FizzCount and SwitchHit 0
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
ResetAntiGrav:
  CALL ResetAntiGravState
  LD HL,$0000
  LD (FizzCount),HL
  RET

  ORG $A792

; ClearScreenCave, the anti-gravity digits and steps 0
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
ResetAntiGravState:
  CALL ClearScreenCave
  XOR A
  LD (AntiGravDigits),A
  LD (AntiGravDigits+$0001),A
  LD (AntiGravSteps),A
  RET

  ORG $A815

; Print WinTexts $AB6A
;
; Witness: L1 1 (rzx x1).
ShowWinTexts:
  LD HL,WinTexts
  LD D,$1A
  LD BC,$0703
  CALL PrintText
  LD HL,WinText2
  LD D,$1F
  LD BC,$0901
  CALL PrintText
  LD HL,WinText3
  LD D,$08
  LD BC,$0B0A
  CALL PrintText
  LD HL,WinText4
  LD D,$20
  LD BC,$0D00
  CALL PrintText
  LD HL,WinText5
  LD D,$1C
  LD BC,$0F02
  CALL PrintText
  LD HL,WinText6
  LD D,$20
  LD BC,$1100
  CALL PrintText
  LD HL,WinText7
  LD D,$1E
  LD BC,$1501
  CALL PrintText
  LD HL,WinText8
  LD D,$09
  LD BC,$1716
  CALL PrintText
  RET

; Colour the win texts
;
; Witness: L1 1 (rzx x1).
ColourWinTexts:
  LD A,$04
  LD D,$1A
  LD BC,$0703
  CALL FillAttrs
  LD A,$05
  LD D,$1F
  LD BC,$0901
  CALL FillAttrs
  LD A,$05
  LD D,$08
  LD BC,$0B0A
  CALL FillAttrs
  LD A,$03
  LD D,$20
  LD BC,$0D00
  CALL FillAttrs
  LD A,$03
  LD D,$1C
  LD BC,$0F02
  CALL FillAttrs
  LD A,$03
  LD D,$20
  LD BC,$1100
  CALL FillAttrs
  LD A,$06
  LD D,$1E
  LD BC,$1501
  CALL FillAttrs
  LD A,$06
  LD D,$09
  LD BC,$1716
  CALL FillAttrs
  RET

; After cave 32: the win screen and tune
;
; Witness: L1 1 (rzx x1).
WinGame:
  CALL WinScreen
  CALL ShowWinTexts
  CALL ColourWinTexts
  CALL PlayWinTune
  XOR A
  LD (CaveDigits),A
  LD A,$01
  LD (CaveDigits+$0001),A
  RET

  ORG $AB6A

; The win screen's texts
WinTexts:
  INCBIN "res/texts/win.bin",$0000,26
WinText2:
  INCBIN "res/texts/win.bin",$001A,31
WinText3:
  INCBIN "res/texts/win.bin",$0039,8
WinText4:
  INCBIN "res/texts/win.bin",$0041,32
WinText5:
  INCBIN "res/texts/win.bin",$0061,28
WinText6:
  INCBIN "res/texts/win.bin",$007D,32
WinText7:
  INCBIN "res/texts/win.bin",$009D,30
WinText8:
  INCBIN "res/texts/win.bin",$00BB,9

  ORG $FD00

; The typed password (20 characters)
PasswordBuffer:
  DEFM "OUTER BOUNDS        "

; The high-score table: 5 records of 6 digits and a 9-character name
HiScoreTable:
  INCBIN "res/tables/hiscores.bin",$0000,75

; The name buffer (9 characters)
NameBuffer:
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20

; Zeros (8 bytes)
VarsPad:
  DEFS $08

; The window's first cell index
ViewOrigin:
  DEFW $0000

; The animation phase 0-3
AnimPhase:
  DEFB $00

; The force field's animation phase 0-7
ForceFieldPhase:
  DEFB $06

; The teleporter's animation phase 0-11
TeleporterPhase:
  DEFB $09

; Zeros (5 bytes)
VarsPad2:
  DEFS $05

; The first byte ClearVars clears
ClearStart:
  DEFB $00

; Unused
VarsFD7B:
  DEFB $00

; The timer's sub-counter (+$40 a pass)
TimerSub:
  DEFB $00

; $FF: out of time or quit
CaveOver:
  DEFB $00

; The cave number as 2 digits
CaveDigits:
  DEFB $00,$00

; $FF when a key moved the player this pass
KeyMoved:
  DEFB $00

; Unused
VarsFD81:
  DEFB $00

; The gems taken as 2 digits
GemDigits:
  DEFB $00,$00

; $FF when the player entered the open exit
CaveDone:
  DEFB $00

; $FF when enough gems are taken
ExitOpen:
  DEFB $00

; The player's cell code: 3 right, 4 left
PlayerFacing:
  DEFB $00

; The continuation address of a special cell
Continuation:
  DEFW $0000

; The saved cell address
SavedCell:
  DEFW $0000

; The anti-gravity steps as 2 digits
AntiGravDigits:
  DEFB $00,$00

; The anti-gravity steps left
AntiGravSteps:
  DEFB $00

; The colour cycle's phase
ColourPhase:
  DEFB $01

; The cycling ink $43-$46
ColourCycleInk:
  DEFB $00

; Set to 99, never read
Unused99:
  DEFB $63

; The cave 1-32
CaveNumber:
  DEFB $01

; The gems taken
GemCount:
  DEFB $00

; The lives
Lives:
  DEFB $04

; The score as 6 digits
ScoreDigits:
  DEFB $00,$00,$00,$00,$00,$00

; The cave's 14 parameter bytes, field 1: GemsNeeded
CaveParams:
  DEFB $00

; The points a gem
GemValue:
  DEFB $00

; The player's cell index (the start from the cave)
PlayerIndex:
  DEFW $0000

; The gems needed as 2 digits
GemsNeededDigits:
  DEFB $00,$00

; The earth graphic's address
EarthGraphic:
  DEFW $0000

; The wall graphic's address
WallGraphic:
  DEFW $0000

; The exit door's colour
DoorColour:
  DEFB $00

; The boulder's colour
BoulderColour:
  DEFB $00

; The colour of GfxWall1 $9CB8
Wall1Colour:
  DEFB $00

; The colour of GfxEarth $9B50
EarthColour:
  DEFB $00

; The cave: 20 rows of 30 cells
CaveGrid:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
