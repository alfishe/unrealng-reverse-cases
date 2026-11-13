; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The HUD (score, dynamite, bullets, lives), the texts, the title's colours, the level's end
;
; The HUD is the screen's row 1: the six score digits at $4021, then three counters drawn as up to six icons each:
; dynamite at $4029 (char $24), bullets at $4031 ($25), lives at $4039 ($26), all from the font at $9E95 (the digits
; 0-9, A-Z, then the icons).
;
; The HUD lies over the playfield: MaskHudCells $A8BF clears the cell flags under the score and the icons before each
; draw, so the map never overwrites them, and DrawCounter $AA0E gives the cells past the icons back to the map (flag
; 1).
;
; The counters are bytes: Lives $A958, Bullets $A967, Dynamite $A976. A new game sets all three to 6 ($E2F7-$E30B), a
; life lost sets dynamite and bullets to 6 again ($E3BB), and so does a level's end. UpdateHud $A90F redraws a counter
; only when it differs from its copy in OldHudCounts $A93A.
;
; The score is six decimal digits, one byte each (Score $A9BE). AddScore $A9E8 adds a five-digit award to its lower
; five digits with carry; the awards behind the score: 50 ($F18D), 500 ($EDF3), the bonus (Lives + 1) x 10000 after
; the last level; one more lies at $E49A.
;
; LevelEnd $ABD8 runs when the exit Rick takes points at $FFFF: it clears the play area, refills dynamite and bullets,
; counts LevelNumber $E4AD up and shows the next level's text (after the fourth: the bonus, then back to the game
; loop's game over).
;
; A bonus count of five decimal digits that runs while `$FD6C` is set. The start marker object (kind 22, `$F4C8`) sets
; `$FD6C` and the digits to 0 2 0 0 0 with effect 10; BonusCountdown $E466 takes 1 off the fourth digit every 30
; passes; the end marker (kind 23, `$F502`) adds what is left to the score (`$A9E8` with DE = the last digit) and
; plays tune 7.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A8BF

; Clear the cell flags under the score and the counters' icons
;
; Clears the six flags $6C21-$6C26 (the score), then as many flags as each
; counter has icons (at most 6): $6C29 dynamite, $6C31 bullets, $6C39 lives.
;
; When Dynamite is 0 the JP Z at $A8CF lands in the clearing loop with HL = 0
; and B as the caller left it: it writes zeros at $0000-$00FF (the ROM:
; ignored) B times. Harmless; with Bullets or Lives 0 the code skips properly.
;
; Callers: DrawDirtyCells and DrawAllDirtyCells. Output: AF, B, HL changed.
;
; Witness: L1 43074 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
MaskHudCells:
  LD HL,$0000
  LD (Kind16Frame+$007D),HL
  LD (Kind19Frame+$0001),HL
  LD (Kind19Frame+$0003),HL
  LD A,(Dynamite)
  AND A
  JP Z,MaskDynamiteLoop
  CP $07
  JP C,MaskDynamite
  LD A,$06
MaskDynamite:
  LD HL,Kind19Frame+$0007
  LD B,A
  XOR A
MaskDynamiteLoop:
  LD (HL),A
  INC L
  DJNZ MaskDynamiteLoop
  LD A,(Bullets)
  AND A
  JP Z,MaskLives
  CP $07
  JP C,MaskBullets
  LD A,$06
MaskBullets:
  LD B,A
  XOR A
  LD HL,Kind19Frame+$000F
MaskBulletsLoop:
  LD (HL),A
  INC L
  DJNZ MaskBulletsLoop
MaskLives:
  LD A,(Lives)
  AND A
  RET Z
  CP $07
  JP C,MaskLivesCount
  LD A,$06
MaskLivesCount:
  LD B,A
  XOR A
  LD HL,Kind19Frame+$0017
MaskLivesLoop:
  LD (HL),A
  INC L
  DJNZ MaskLivesLoop
  RET

; Redraw the counters that changed since the last call
;
; Compares Dynamite, Bullets and Lives with OldHudCounts and calls
; DrawDynamite, DrawBullets or DrawLives for each one that differs (keeping the
; new value).
;
; Callers: the frame loop ($E422), the game over ($E35D) and the level's end
; ($ABF3). Output: everything.
;
; Witness: L1 42378 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
UpdateHud:
  LD A,(OldHudCounts)
  LD C,A
  LD A,(Dynamite)
  LD (OldHudCounts),A
  CP C
  CALL NZ,DrawDynamite
  LD A,(OldBullets)
  LD C,A
  LD A,(Bullets)
  LD (OldBullets),A
  CP C
  CALL NZ,DrawBullets
  LD A,(OldLives)
  LD C,A
  LD A,(Lives)
  CP C
  RET Z
  LD (OldLives),A
  JP DrawLives

; The counters as last drawn: dynamite, bullets, lives
OldHudCounts:
  DEFB $00
OldBullets:
  DEFB $00
OldLives:
  DEFB $00

; Draw the score and the three counters
;
; Calls DrawScore, DrawDynamite, DrawBullets and DrawLives. Callers: the game
; start ($E30E) and a life lost ($E3C6).
;
; Witness: L1 331 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
DrawHud:
  CALL DrawScore
  CALL DrawDynamite
  CALL DrawBullets
  CALL DrawLives
  RET

; Draw the lives as icons at $4039
;
; DE = $4039, the icon $26, attribute $47, A = Lives, then DrawCounter. Output:
; everything.
;
; Witness: L1 370 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
DrawLives:
  LD DE,$4039
  LD L,$26
  LD H,$47
  LD A,(Lives)
  CALL DrawCounter
  RET

; The lives: 6 at a new game, 0 is the game over ($E354)
Lives:
  DEFB $05

; Draw the bullets as icons at $4031
;
; DE = $4031, the icon $25, attribute $47, A = Bullets, then DrawCounter.
;
; Witness: L1 393 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
DrawBullets:
  LD DE,$4031
  LD L,$25
  LD H,$47
  LD A,(Bullets)
  CALL DrawCounter
  RET

; The bullets: 6 at a new game, a life and a level; Rick's fire uses them
; ($FAA1, $FAA7)
Bullets:
  DEFB $02

; Draw the dynamite as icons at $4029
;
; DE = $4029, the icon $24, attribute $47, A = Dynamite, then DrawCounter.
;
; Witness: L1 407 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
DrawDynamite:
  LD DE,$4029
  LD L,$24
  LD H,$47
  LD A,(Dynamite)
  CALL DrawCounter
  RET

; The sticks of dynamite: 6 at a new game, a life and a level; used at $FA3E,
; $FA4C
Dynamite:
  DEFB $04

; Draw the six score digits at $4021 and colour them $47
;
; For each digit of Score: its 8 bytes from the font at $9E95 + 8 digit, one
; pixel line per screen line. Then the attributes $5821-$5826 = $47.
;
; Callers: DrawHud and AddScore (a tail jump). Output: everything.
;
; Witness: L1 369 (beeper48, c1, controls, ending2, gameover, spotL3Z7-51,
; L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
DrawScore:
  LD DE,$4021
  LD HL,Score
  LD B,$06
DrawScoreDigit:
  PUSH BC
  PUSH HL
  PUSH DE
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Font
  ADD HL,BC
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP DE
  INC DE
  POP HL
  INC HL
  POP BC
  DJNZ DrawScoreDigit
  LD HL,$4747
  LD ($5821),HL
  LD ($5823),HL
  LD ($5825),HL
  RET

; The score: six decimal digits, one byte each, the highest first
;
; Cleared by a new game ($E2FC-$E305), added to by AddScore. The image holds
; the digits 0 9 3 0 0 0.
Score:
  DEFB $00,$09,$03,$00,$00,$00

; $FF, not read: the byte after the units
ScorePad:
  DEFB $FF

; Five digits, 00001: no reader found
Award1:
  DEFB $00,$00,$00,$00,$01

; 00010: no reader found
Award10:
  DEFB $00,$00,$00,$01,$00

; 00050: AddScore from $F18D
Award50:
  DEFB $00,$00,$00,$05,$00

; 00100: no reader found
Award100:
  DEFB $00,$00,$01,$00,$00

; 00500: AddScore from $EDF3
Award500:
  DEFB $00,$00,$05,$00,$00

; 01000: no reader found
Award1000:
  DEFB $00,$01,$00,$00,$00

; (Lives + 1) 0 0 0 0: written by the end of the last level ($AC2F)
LevelBonus:
  DEFB $00,$00,$00,$00,$00

; Add a five-digit award to the score and redraw it
;
; Input: DE the last (units) digit of the award. Adds the five digits to
; Score's last five ($A9BF-$A9C3) from the units up, carrying past 9, then the
; carry into the first digit (9 wraps to 0). Tail jump to DrawScore.
;
; Callers: $EDF6 (500), $F190 (50), $F52C (the award at $E49A) and the end of
; the last level ($AC35). Output: everything.
;
; Witness: L1 38 (c1, ending2, L1Z3, L2Z6, L3Z2, L3Z6, L3Z11, L3Z12, L4Z2,
; level1, level2, level4).
AddScore:
  LD HL,Score+$0005
  OR A
  LD B,$05
AddScoreDigit:
  LD A,(DE)
  ADC A,(HL)
  CP $0A
  JP NC,AddScoreCarry
  OR A
AddScoreStore:
  LD (HL),A
  DEC HL
  DEC DE
  DJNZ AddScoreDigit
  LD A,(HL)
  ADC A,$00
  CP $0A
  JP C,AddScoreTop
  XOR A
AddScoreTop:
  LD (HL),A
  JP DrawScore
AddScoreCarry:
  SUB $0A                 ; digit - 10, carry 1
  SCF
  JP AddScoreStore

; Draw a counter as up to six icons and give the rest of its six cells back to
; the map
;
; Input: A the count (above 6 shown as 6), DE the screen address, L the icon
; char, H its attribute. Draws the icon A times with its attribute
; (CounterAttr).
;
; For the remaining 6 - A cells it sets the cell flag to 1 ($6C00 + cell) and
; the attribute from the map's char ($6600 + cell, the table $7900 or $8200:
; CounterAttrTableHigh), so the next draw puts the map back there.
;
; The LD A,($6B00) / AND A at $AA76 has no effect (A is reloaded, the flags are
; not tested). Callers: DrawLives, DrawBullets, DrawDynamite.
;
; Witness: L1 1170 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
DrawCounter:
  PUSH AF
  LD A,H
  LD (CounterAttr+$0001),A
  LD A,D
  RRA
  RRA
  RRA
  AND $03
  OR $58
  LD B,A
  LD C,E
  POP AF
  CP $07
  JP C,DrawCounterIcons
  LD A,$06
DrawCounterIcons:
  PUSH AF
  AND A
  JP Z,DrawCounterRest
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  PUSH BC
  LD BC,Font
  ADD HL,BC
  POP BC
DrawCounterIcon:
  PUSH AF
  PUSH HL
CounterAttr:
  LD A,$00                ; its operand: the icon's attribute (H at entry)
  LD (BC),A
  PUSH DE
  PUSH BC
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP BC
  INC BC
  POP DE
  INC DE
  POP HL
  POP AF
  DEC A
  JP NZ,DrawCounterIcon
DrawCounterRest:
  POP HL
  LD A,$06
  SUB H
  RET Z
  PUSH AF
  LD A,B
  ADD A,$0E
  LD H,A
  LD L,C
  LD A,B
  ADD A,$14
  LD D,A
  LD E,C
  POP AF
DrawCounterRestLoop:
  PUSH AF
  LD A,(MusicImage+$0D00)
  AND A
  LD A,$01
  LD (DE),A
  PUSH DE
  LD E,(HL)
CounterAttrTableHigh:
  LD D,$79                ; its operand: $79 or $82 (LoadScreen $AC90, $ACA4)
  LD A,(DE)
  LD (BC),A
  POP DE
  INC DE
  INC HL
  INC BC
  POP AF
  DEC A
  JP NZ,DrawCounterRestLoop
  RET

; Print a text from HL at the screen address DE in attribute C
;
; One char a cell, $FF ends. A space ($20) prints SpaceGlyph; any other byte b
; prints the font char b - $37 from $9E95: 'A'-'Z' are the letters 10-35, and
; the digits 0-9 would be the bytes $37-$40 ('7'-'@').
;
; Output: HL on the $FF, DE past the text, AF changed. Callers: PrintLines and
; the game over text ($E36B-$E381).
;
; Witness: L1 4235 (beeper48, c1, controls, ending2, gameover, level1).
PrintText:
  LD A,(HL)
  CP $FF
  RET Z
  CP $20
  JP NZ,PrintChar
PrintSpace:
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,SpaceGlyph
  JP PrintGlyph
PrintChar:
  PUSH HL
  PUSH DE
  PUSH BC
  SUB $37
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Font
  ADD HL,BC
PrintGlyph:
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP BC
  POP DE
  PUSH DE
  LD A,D
  RRA
  RRA
  RRA
  AND $07
  OR $58
  LD D,A
  LD A,C
  LD (DE),A
  POP DE
  POP HL
  INC E
  INC HL
  JP PrintText

; The blank char PrintText prints for a space
SpaceGlyph:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Print texts on successive screen rows until $FE
;
; Input: HL the texts, each ending in $FF, the list ending in $FE; DE the first
; row's screen address. Each text in attribute $47; DE goes 32 on (8 more on D
; when E wraps: the next third).
;
; Callers: the title ($E22F-$E241), the level texts ($E31A, $AC1A). Output:
; everything.
;
; Witness: L1 275 (beeper48, c1, controls, ending2, gameover, level1).
PrintLines:
  LD A,(HL)
  CP $FE
  RET Z
  PUSH DE
  LD C,$47
  CALL PrintText
  INC HL
  POP DE
  LD A,E
  ADD A,$20
  LD E,A
  JP NC,PrintLinesNext
  LD A,D
  ADD A,$08
  LD D,A
PrintLinesNext:
  JP PrintLines

; Clear the bitmap and set every attribute to $47
;
; Callers: the title ($E223) and the game start ($E2DC). Output: BC, DE, HL.
;
; Witness: L1 17 (beeper48, c1, controls, ending2, gameover, level1).
ClearScreen:
  LD HL,$4000
  LD DE,$4001
  LD (HL),$00
  LD BC,$1800
  LDIR
  LD (HL),$47
  LD BC,$02FF
  LDIR
  RET

; Colour A attribute cells from DE with a table of 8, the phase moving on one
; each call
;
; Input: A the number of cells, HL the table (written into CycleTablePtr), DE
; the first attribute. CyclePhase counts up modulo 8; cell i gets table[(phase
; + i) AND 7]. The title highlights the chosen method's line with CycleColours
; and repaints the old one with PlainColours ($E269-$E2CE), once every two
; frames (two HALTs).
;
; Output: AF, BC, DE, HL changed, AF' used.
;
; Witness: L1 6603 (beeper48, c1, controls, ending2, gameover, level1).
CycleAttributes:
  EX AF,AF'
  LD (CycleTablePtr+$0001),HL
  LD A,(CyclePhase)
  INC A
  AND $07
  LD (CyclePhase),A
  LD C,A
  LD B,$00
  EX AF,AF'
CycleAttributesLoop:
  EX AF,AF'
CycleTablePtr:
  LD HL,CycleColours      ; its operand: the caller's table
  ADD HL,BC
  LD A,(HL)
  LD (DE),A
  INC E
  LD A,C
  INC A
  AND $07
  LD C,A
  EX AF,AF'
  DEC A
  JP NZ,CycleAttributesLoop
  RET

; CycleAttributes' phase, 0-7
CyclePhase:
  DEFB $00

; The highlight: bright white ink on paper 1, 2, 3, 4 ($4F $4F $57 $57 $5F $5F
; $67 $67)
CycleColours:
  DEFB $4F,$4F,$57,$57,$5F,$5F,$67,$67

; Plain bright white on black ($47)
PlainColours:
  DEFB $47,$47,$47,$47,$47,$47,$47,$47

  ORG $ABD8

; The end of a level: the next level's text and first screen, or after the
; fourth the bonus and the end
;
; Falls in from CheckScreenExit when the exit points at $FFFF. MarkAllDirty,
; clears the map's screen rows $6600-$68FF, RedrawScreen, Dynamite = Bullets =
; 6, UpdateHud, LevelNumber $E4AD + 1 = n.
;
; The level record at $E4AE + 11n (+0/+1 the text list, +2/+3 its screen
; address, +4 the attribute of char 0 at $7900): PrintLines, then StartTune n.
; After the fourth level (n = 4) the bonus: LevelBonus = Lives + 1, AddScore.
; Then waits for the start key's release and press (StartPressed).
;
; n >= 4: ClearPlayArea, MarkAllDirty, $E440 = $FF (the game loop's "over"
; flag: on to the game over at $E35D) and return. Else NextLevel.
;
; Run once, in the ending recording (work/stage2/ending2: level 4's end exit
; from the L4Z9 warp, the door opened by the warp); the ends of levels 1-3 are
; in no recording. Output: everything.
;
; Witness: L1 1 (ending2).
LevelEnd:
  CALL MarkAllDirty
  LD HL,MusicImage+$0800
  LD DE,MusicImage+$0801
  LD (HL),$00
  LD BC,$02FF
  LDIR
  CALL RedrawScreen
  LD A,$06
  LD (Dynamite),A
  LD (Bullets),A
  CALL UpdateHud
  LD A,(Level)
  INC A
  LD (Level),A
  LD B,A
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,LevelTable
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD (CharAttr0),A
  PUSH HL
  PUSH BC
  POP HL
  CALL PrintLines
  LD A,(Level)
  CALL StartTune
  LD A,(Level)
  CP $04
  JP NZ,LevelEndRelease
  LD A,(Lives)
  INC A
  LD (LevelBonus),A
  LD DE,LevelBonus+$0004
  CALL AddScore
LevelEndRelease:
  CALL StartPressed
  JR Z,LevelEndRelease
LevelEndPress:
  CALL StartPressed
  JR NZ,LevelEndPress
  LD A,(Level)
  CP $04
  JR C,NextLevel
  CALL ClearPlayArea
  CALL MarkAllDirty
  POP HL
  LD A,$FF
  LD (GameComplete),A
  RET
NextLevel:
  POP HL                  ; the record's +5 Rick's x ($EAAD), +6/+7 his y
                          ; ($EAAE), +8/+9 the screen record, +10 the top row:
                          ; LoadScreen
  INC HL
  LD A,(HL)
  LD (RickX),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (RickY),DE
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  POP IX
  INC HL
  LD C,(HL)
  LD B,$00
  JP LoadScreen

  ORG $AF56

; Clear the map's screen rows $6600-$68FF (the char 0)
;
; Called once, after the last level ($AC49), before the game over.
;
; Witness: L1 1 (ending2).
ClearPlayArea:
  LD HL,MusicImage+$0800
  LD DE,MusicImage+$0801
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

  ORG $E466

; Count the bonus down while it runs
;
; Returns at once when `$FD6C` is 0. Else BonusDivider $E495 counts passes;
; every `$1E` passes (the reload) it takes 1 from BonusDigits+3 with a decimal
; borrow (a digit going below 0 becomes 9 and borrows from the one before); at
; 0 0 0 0 0 it stops.
;
; Run in c1, controls, gameover, level1 and level2; never in level3 / level4.
; Known only from the code: the digits are not drawn here.
;
; Witness: L1 42787 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
BonusCountdown:
  LD A,(BonusActive)
  AND A
  RET Z
  LD A,(BonusDivider)
  DEC A
  LD (BonusDivider),A
  RET NZ
  LD A,$1E
  LD (BonusDivider),A
  LD HL,(BonusDigits)
  LD A,H
  OR L
  JR NZ,BonusDecrement
  LD HL,(BonusDigits+$0002)
  LD A,H
  OR L
  JR NZ,BonusDecrement
  LD A,(BonusDigits+$0004)
  AND A
  RET Z
BonusDecrement:
  LD HL,BonusDigits+$0003
BonusBorrowLoop:
  DEC (HL)
  RET P
  LD (HL),$09
  DEC HL
  JR BonusBorrowLoop

; passes to the next step ($1E reload; $32 in the image), then the five digits
;
; Written by BonusCountdown $E466 (BonusDivider and the digits) and by the
; start marker `$F4C8` (`$F4EE`-`$F4F9`: the digits); read by the end marker
; `$F502` (`$F529`: DE = BonusDigits+4).
BonusDivider:
  DEFB $32
BonusDigits:
  DEFB $00,$00,$00,$00,$00 ; five decimal digits, most significant first
