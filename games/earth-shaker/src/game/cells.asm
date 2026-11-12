; --------------------------------------------------------------------------------------------------------------------
; cells.asm: The cell update: gravity, rolling, crushing, the switch, the animation codes
;
; Once a pass ScanCells $8075 walks CaveGrid from row 18, column 29 back to row 0, column 0 (each row right to left,
; the rows upward), DE the cell below. Earth 6, empty 0, wall 5, force field 9, bubble $0E, teleporter $0D, the exit
; 1, the switch box $0B, the player 3 / 4 and the codes above $10 ($11-$1F) are skipped ($10 itself reaches MoveObject
; $80DB); boulders 2, gems 7, jelly beans 8, anti-gravity arrows $0A, potions $0C and fire $0F fall (MoveObject
; $80DB). Row 19 is never a source: nothing falls out of the cave.
;
; An object falls one cell when the cell below is empty; the cell it left gets $20 (just vacated: nothing falls or
; rolls into it this pass; ClearVacated $81AC clears the marks at the next pass). If the cell under the object's new
; place is the player, the player is killed (Crush $9ABC); if it is a switch box, SwitchHit $7FFC is set. When the
; cell below is not empty the object rolls off anything but the player, earth or a vacated cell: to the left when the
; left cell and the one below it are empty, else to the right the same way; the object goes to the side cell, its old
; cell and the cell under the side cell get $20. A boulder above fire becomes the dissolve animation $15 instead.
;
; In the caves whose earth graphic is the $A4xx one (13, 17, 22, 24, 26) earth falls too: SetEarthFalls $FB81 patches
; the earth test of the scan away. Falling earth never crushes the player (EarthFallGuard $9AA6). With anti-gravity on
; (AntiGravSteps $FD8D not 0) AntiGravPass $A7CD runs the upward scan AntiGravScan $A655 instead: objects rise.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7FFA

; Leftover: a byte before the flags, never read
FlagsPad:
  DEFB $00

; The fizz countdown: 7 when a boulder stands over fire (the scan's dissolve);
; FizzSound $A773 beeps while it runs down
FizzCount:
  DEFB $00

; $FF when a falling object landed on a switch box; SwitchClear $817A then
; clears the force fields
SwitchHit:
  DEFB $00

; $FF when the player is killed: crushed by a falling object or walked into
; fire
PlayerKilled:
  DEFB $00

; $FF when an object other than a boulder fell this pass (the fall noise)
ObjectFell:
  DEFB $00

; $FF when a boulder fell this pass (the fall noise)
BoulderFell:
  DEFB $00

  ORG $8075

; The gravity scan of a pass: clear the fall flags, then ScanCellsBody
;
; A = 0, JP ClearFallFlags $E7F5, which clears BoulderLanded $E7A8 and
; BoulderFell $7FFF and jumps to ScanCellsBody $8079.
;
; Witness: L1 42379 (c1, hiscore, lives, timer, rzx01-rzx32).
ScanCells:
  XOR A
  JP ClearFallFlags

; Walk the grid bottom-up, right to left, and move each falling object
;
; ObjectFell $7FFE = A (0). HL = $FFE1 (row 18, column 29), DE = HL + 30, 19
; rows of 30 cells. A boulder above fire becomes $15 (the dissolve) and
; FizzCount $7FFB = 7. The cells skipped (see the module header) never reach
; EarthFallGuard $9AA6 / MoveObject $80DB. The CP (HL) at $809A is the earth
; test SetEarthFalls $FB81 patches to NOP.
;
; Witness: L1 42379 (c1, hiscore, lives, timer, rzx01-rzx32).
ScanCellsBody:
  LD (ObjectFell),A
  LD HL,CaveGrid+$0239
  LD DE,CaveGrid+$0257
  LD B,$13
ScanRowLoop:
  PUSH BC
  LD B,$1E
ScanCellLoop:
  LD A,$02
  CP (HL)
  JR NZ,ScanSkipTests
  LD A,(DE)
  CP $0F
  JR NZ,ScanSkipTests
  LD (HL),$15
  LD A,$07
  LD (FizzCount),A
ScanSkipTests:
  LD A,$06
ScanEarthTest:
  CP (HL)
  JR Z,ScanNextCell
  XOR A
  CP (HL)
  JR Z,ScanNextCell
  LD A,$05
  CP (HL)
  JR Z,ScanNextCell
  LD A,$09
  CP (HL)
  JR Z,ScanNextCell
  LD A,$0E
  CP (HL)
  JR Z,ScanNextCell
  LD A,$0D
  CP (HL)
  JR Z,ScanNextCell
  LD A,$01
  CP (HL)
  JR Z,ScanNextCell
  LD A,$0B
  CP (HL)
  JR Z,ScanNextCell
  LD A,$03
  CP (HL)
  JR Z,ScanNextCell
  LD A,$04
  CP (HL)
  JR Z,ScanNextCell
  LD A,$10
  CP (HL)
  JR C,ScanNextCell
  PUSH BC
  CALL EarthFallGuard
  POP BC
ScanNextCell:
  DEC HL
  DEC DE
  DJNZ ScanCellLoop
  POP BC
  DJNZ ScanRowLoop
  RET

; Make the object at HL fall into DE, or roll it off
;
; HL = the object, DE = the cell below, B = the column count left (30 for
; column 29, 1 for column 0). The cell below empty: the object moves into it,
; HL gets $20; a boulder calls BoulderLandCheck $E78C, another object sets
; ObjectFell $7FFE. Then the cell under the new place: the player facing right
; (3) jumps to Crush $9ABC, the rest to MoveObjectLanded $8104. The cell below
; not empty: RollObject $8117.
;
; Witness: L1 4511703 (c1, hiscore, lives, timer, rzx01-rzx32).
MoveObject:
  LD A,(DE)
  OR A
  JR NZ,RollObject
  LD A,(HL)
  LD (HL),$20
  LD (DE),A
  CP $02
  JR NZ,MarkObjectFell
  CALL BoulderLandCheck
  NOP
  NOP
  JR CheckUnderFallen
MarkObjectFell:
  LD A,$FF
  LD (ObjectFell),A
CheckUnderFallen:
  PUSH HL
  LD HL,$001E
  ADD HL,DE
  LD A,(HL)
  POP HL
  CP $03
  JR NZ,MoveObjectLanded
  JP Crush

; Leftover: 3 bytes between two jumps, never run
MoveObjectPad:
  DEFB $00,$00,$00

; The cell under the fallen object: the player facing left, or a switch box
;
; A = the cell. 4 jumps to Crush $9ABC; else LandOnSwitch $810E.
;
; Witness: L1 15918 (c1, hiscore, rzx01-rzx32).
MoveObjectLanded:
  CP $04
  JR NZ,LandOnSwitch
  JP Crush

; Leftover: 3 bytes, never run
MoveObjectPad2:
  DEFB $00,$00,$00

; A switch box under a fallen object sets SwitchHit
;
; A = $0B: SwitchHit $7FFC = $FF. The code that follows ($8117, RollObject) is
; reached from MoveObject when the cell below is not empty: an object on the
; player (3, 4), earth (6) or a vacated cell ($20) stays; else it rolls left
; when it is not in column 0 and the left cell and the one below it are both 0,
; else right when it is not in column 29 and those are 0.
;
; Witness: L1 15901 (c1, hiscore, rzx01-rzx32).
LandOnSwitch:
  CP $0B
  RET NZ
  LD A,$FF
  LD (SwitchHit),A
  RET
; This entry point is used by the routine at MoveObject.
RollObject:
  LD A,(DE)
  CP $03
  RET Z
  CP $04
  RET Z
  CP $06
  RET Z
  CP $20
  RET Z
  LD A,B
  CP $01
  JR Z,TryRollRight
  DEC HL
  DEC DE
  LD A,(DE)
  OR (HL)
  JR Z,RollLeft
  INC HL
  INC DE
  JR TryRollRight
RollLeft:
  INC HL
  LD A,(HL)
  DEC HL
  LD (HL),A
  INC HL
  LD A,$20
  LD (DE),A
  LD (HL),A
  INC DE
  RET
TryRollRight:
  LD A,B
  CP $1E
  RET Z
  INC DE
  INC HL
  LD A,(DE)
  OR (HL)
  JR Z,RollRight
  DEC DE
  DEC HL
  RET
RollRight:
  DEC HL
  LD A,(HL)
  INC HL
  LD (HL),A
  DEC HL
  LD A,$20
  LD (DE),A
  LD (HL),A
  DEC DE
  RET

; The anti-gravity sound: falling BEEPER sweeps
;
; C = $A0 down by 8 a sweep: periods from C + $3C down to C, 2 cycles each.
; Called by AntiGravStart $A9EF.
;
; Witness: L1 16 (rzx x6).
AntiGravSound:
  LD C,$A0
AntiGravSoundLoop:
  LD A,C
  ADD A,$3C
  LD L,A
  LD H,$00
  LD DE,$0002
AntiGravSoundLoop2:
  PUSH DE
  PUSH HL
  PUSH BC
  CALL RomBeeper
  POP BC
  POP HL
  POP DE
  DEC L
  LD A,L
  CP C
  JR NZ,AntiGravSoundLoop2
  DEC C
  DEC C
  DEC C
  DEC C
  DEC C
  DEC C
  DEC C
  DEC C
  JR NZ,AntiGravSoundLoop
  RET

; After a switch was hit: every force field and switch box becomes $20
;
; If SwitchHit $7FFC: every cell 9 (force field) and $0B (switch box) becomes
; $20, SwitchScore $A9E3 (250 points and the sound), SwitchHit = 0. Then
; AntiGravPass $A7CD: the gravity scan of the pass.
;
; Witness: L1 43776 (c1, hiscore, lives, timer, rzx01-rzx32).
SwitchClear:
  LD A,(SwitchHit)
  OR A
  JR Z,SwitchClearSkip3
  LD HL,CaveGrid
  LD B,$14
SwitchClearLoop:
  PUSH BC
  LD B,$1E
SwitchClearLoop2:
  LD A,(HL)
  CP $09
  JR NZ,SwitchClearSkip
  LD (HL),$20
SwitchClearSkip:
  LD A,(HL)
  CP $0B
  JR NZ,SwitchClearSkip2
  LD (HL),$20
SwitchClearSkip2:
  INC HL
  DJNZ SwitchClearLoop2
  POP BC
  DJNZ SwitchClearLoop
  CALL SwitchScore
  XOR A
  LD (SwitchHit),A
SwitchClearSkip3:
  CALL AntiGravPass
  RET

; Leftover: 5 bytes, never run
SwitchClearPad:
  DEFB $00,$00,$00,$00,$00

; Clear the vacated mark of every cell
;
; Every grid cell AND $1F: $20 becomes 0, the animation codes $10-$1F stay.
;
; Witness: L1 43775 (c1, hiscore, lives, timer, rzx01-rzx32).
ClearVacated:
  LD HL,CaveGrid
ClearVacatedLoop:
  LD A,(HL)
  AND $1F
  LD (HL),A
  INC HL
  LD A,H
  OR L
  JR NZ,ClearVacatedLoop
  RET

  ORG $937E

; SwitchClear, then every animation code steps on
;
; $10-$14 step to $15, which becomes $20 (the burst); $15-$1B step to $1C,
; which becomes $20 (the dissolve).
;
; Witness: L1 43776 (c1, hiscore, lives, timer, rzx01-rzx32).
AnimateCellCodes:
  CALL SwitchClear
  LD HL,CaveGrid
  LD BC,$0258
AnimateCellCodesLoop:
  LD A,(HL)
  CP $10
  JR C,AnimateCellCodesSkip3
  CP $20
  JR Z,AnimateCellCodesSkip3
  INC A
  CP $15
  JR NZ,AnimateCellCodesSkip
  LD A,$20
AnimateCellCodesSkip:
  CP $1C
  JR NZ,AnimateCellCodesSkip2
  LD A,$20
AnimateCellCodesSkip2:
  LD (HL),A
AnimateCellCodesSkip3:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,AnimateCellCodesLoop
  RET

  ORG $9AA5

; $FF when the falling object is earth: it then does not crush (EarthFallGuard)
EarthFell:
  DEFB $00

; Mark falling earth, then MoveObject
;
; Witness: L1 4511703 (c1, hiscore, lives, timer, rzx01-rzx32).
EarthFallGuard:
  PUSH AF
  XOR A
  LD (EarthFell),A
  NOP
  NOP
  NOP
  LD A,(HL)
  CP $06
  JR NZ,EarthFallGuardSkip
  LD A,$FF
  LD (EarthFell),A
EarthFallGuardSkip:
  POP AF
  JP MoveObject

; A falling object on the player: PlayerKilled unless it is earth
;
; Witness: L1 48 (c1, rzx x5): 47 falling earth in caves 13, 17, 22, 24, 26
; (EarthFell set, no kill) and one boulder kill, c1 frame 13208 (CrushSkip
; once). The stage 2 recording death-crush kills the player at frame 21 (cave
; 1: up twice under a boulder, down once).
Crush:
  PUSH AF
  LD A,(EarthFell)
  OR A
  JR Z,CrushSkip
  POP AF
  RET
CrushSkip:
  LD A,$FF
  LD (PlayerKilled),A
  POP AF
  RET

  ORG $9DFC

; The falling-earth caves: animate earth and the empty cell (frames EmptyFrames
; $FAE0)
;
; Witness: L1 43775 (c1, hiscore, lives, timer, rzx01-rzx32).
EarthAnim:
  LD HL,(CellEarthGfx)
  LD A,H
  CP $A4
  RET NZ
  LD DE,$0024
  LD HL,GfxFallingEarth
  LD A,(AnimPhase)
  OR A
  JR Z,EarthAnimSkip
  LD B,A
EarthAnimLoop:
  ADD HL,DE
  DJNZ EarthAnimLoop
EarthAnimSkip:
  LD (CellEarthGfx),HL
  CALL EarthAnimStep
  RET

  ORG $A655

; The upward scan while anti-gravity runs: objects rise
;
; Witness: L1 1397 (rzx x6).
AntiGravScan:
  XOR A
  CALL SetBoulderFlags
  LD (ObjectFell),A
  LD HL,CaveGrid+$001E
  LD DE,CaveGrid
  LD B,$13
AntiGravScanLoop:
  PUSH BC
  LD B,$1E
AntiGravScanLoop2:
  LD A,$02
  CP (HL)
  JR NZ,AntiGravSkipTests
  LD A,(DE)
  CP $0F
  JR NZ,AntiGravSkipTests
  LD (HL),$15
  LD A,$07
  LD (FizzCount),A
AntiGravSkipTests:
  LD A,$06
AntiGravEarthTest:
  CP (HL)
  JR Z,AntiGravScanSkip
  XOR A
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$05
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$09
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$0E
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$0D
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$01
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$0B
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$03
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$04
  CP (HL)
  JR Z,AntiGravScanSkip
  LD A,$10
  CP (HL)
  JR C,AntiGravScanSkip
  PUSH BC
  CALL AntiGravMove
  POP BC
AntiGravScanSkip:
  INC HL
  INC DE
  DJNZ AntiGravScanLoop2
  POP BC
  DJNZ AntiGravScanLoop
  RET

; Move one object up
;
; Witness: L1 166974 (rzx x6).
AntiGravMove:
  LD A,(DE)
  OR A
  JR NZ,AntiGravMoveSkip2
  LD A,(HL)
  LD (HL),$20
  LD (DE),A
  CP $02
  JR NZ,AntiGravMoveSkip
  LD A,$FF
  LD (BoulderFell),A
  JR AntiGravMoveDone
AntiGravMoveSkip:
  LD A,$FF
  LD (ObjectFell),A
AntiGravMoveDone:
  RET
AntiGravMoveSkip2:
  LD A,(DE)
  CP $03
  RET Z
  CP $04
  RET Z
  CP $06
  RET Z
  CP $20
  RET Z
  LD A,B
  CP $1E
  JR Z,AntiGravMoveSkip4
  DEC HL
  DEC DE
  LD A,(DE)
  OR (HL)
  JR Z,AntiGravMoveSkip3
  INC HL
  INC DE
  JR AntiGravMoveSkip4
AntiGravMoveSkip3:
  INC HL
  LD A,(HL)
  DEC HL
  LD (HL),A
  INC HL
  LD A,$20
  LD (DE),A
  LD (HL),A
  INC DE
  RET
AntiGravMoveSkip4:
  LD A,B
  CP $01
  RET Z
  INC DE
  INC HL
  LD A,(DE)
  OR (HL)
  JR Z,AntiGravMoveSkip5
  DEC DE
  DEC HL
  RET
AntiGravMoveSkip5:
  DEC HL
  LD A,(HL)
  INC HL
  LD (HL),A
  DEC HL
  LD A,$20
  LD (DE),A
  LD (HL),A
  DEC DE
  RET

  ORG $A7A0

; Anti-gravity on: 99 steps, the digits, the icon
;
; Witness: L1 16 (rzx x6).
AntiGravStartScan:
  CALL AntiGravStart
  LD A,$09
  LD (AntiGravDigits),A
  LD A,$09
  LD (AntiGravDigits+$0001),A
  LD A,$63
  LD (AntiGravSteps),A
  LD HL,AntiGravDigits+$0001
  LD D,$02
  LD BC,$1712
  CALL PrintDigits
  LD DE,AntiGravIcon
  LD BC,$170F
  CALL PrintGlyph
  RET

; The player takes the arrow: AntiGravStartScan
;
; Witness: L1 15 (rzx x6).
AntiGravTake:
  CALL AntiGravStartScan
  JP Continue

; The gravity scan of a pass: down, or up while anti-gravity runs
;
; Witness: L1 43776 (c1, hiscore, lives, timer, rzx01-rzx32).
AntiGravPass:
  LD A,(AntiGravSteps)
  OR A
  JR NZ,AntiGravPassSkip
  CALL ScanCells
  RET
AntiGravPassSkip:
  DEC A
  LD (AntiGravSteps),A
  OR A
  JR NZ,AntiGravPassSkip2
  LD DE,AntiGravIconOff
  LD BC,$170F
  CALL PrintGlyph
AntiGravPassSkip2:
  LD HL,AntiGravDigits+$0001
  LD B,$02
AntiGravPassLoop:
  LD A,(HL)
  DEC A
  LD (HL),A
  CP $FF
  JR NZ,AntiGravPassSkip3
  LD (HL),$09
  DEC HL
  DJNZ AntiGravPassLoop
AntiGravPassSkip3:
  LD HL,AntiGravDigits+$0001
  LD BC,$1712
  LD D,$02
  CALL PrintDigits
  CALL AntiGravScan
  LD A,(AntiGravSteps)
  RLCA
  LD DE,$000A
  LD L,A
  LD H,$00
  CALL RomBeeper
  DI
  RET

  ORG $E78C

; A boulder fell: BoulderLanded when the cell under its new place is not empty
; or vacated
;
; Witness: L1 9340 (c1, hiscore, rzx01-rzx19, rzx21-rzx28, rzx30, rzx32).
BoulderLandCheck:
  PUSH HL
  PUSH DE
  LD DE,$003C
  ADD HL,DE
  LD A,$20
  CP (HL)
  JR Z,BoulderLandCheckSkip
  XOR A
  CP (HL)
  JR Z,BoulderLandCheckSkip
  LD A,$FF
  LD (BoulderLanded),A
BoulderLandCheckSkip:
  POP DE
  POP HL
  LD A,$FF
  LD (BoulderFell),A
  RET

; $FF when a falling boulder landed this pass (the thud)
BoulderLanded:
  DEFB $00

  ORG $E7F5

; BoulderLanded and BoulderFell = A, then ScanCellsBody
;
; Witness: L1 42379 (c1, hiscore, lives, timer, rzx01-rzx32).
ClearFallFlags:
  LD (BoulderLanded),A
  LD (BoulderFell),A
  JP ScanCellsBody

  ORG $E83A

; The pass sound: a thud after a landing or a push, else the fall noise
;
; Witness: L1 43775 (c1, hiscore, lives, timer, rzx01-rzx32).
PassSound:
  LD A,(BoulderLanded)
  OR A
  JR NZ,PassSoundSkip
  LD A,(BoulderPushed)
  OR A
  JR Z,PassSoundSkip2
PassSoundSkip:
  CALL ThudSound
  RET
PassSoundSkip2:
  LD A,(BoulderFell)
  JP FallSoundChoice

; BoulderFell and BoulderLanded = A
;
; Witness: L1 1397 (rzx x6).
SetBoulderFlags:
  LD (BoulderFell),A
  LD (BoulderLanded),A
  RET

  ORG $FB70

; The falling-earth caves' animation step
;
; Witness: L1 6610 (rzx x5).
EarthAnimStep:
  LD HL,EmptyFrames
  LD A,(AnimPhase)
  OR A
  JR Z,EarthAnimStepSkip
  LD B,A
EarthAnimStepLoop:
  ADD HL,DE
  DJNZ EarthAnimStepLoop
EarthAnimStepSkip:
  LD (CellGraphicsTable),HL
  RET

; Patch the scan so earth falls in the caves whose earth graphic is $A4xx
;
; The earth graphic's page decides the rule: earth falls when word 6 points
; into page $A4 (GfxFallingEarth).
;
; Witness: L1 47 (c1, hiscore, lives, timer, rzx01-rzx32).
SetEarthFalls:
  CALL CaveSetupAll
  LD HL,BlankGraphic
  LD (CellGraphicsTable),HL
  LD A,$BE
  LD (ScanEarthTest),A
  LD (AntiGravEarthTest),A
  LD A,(CellEarthGfx+$0001)
  CP $A4
  RET NZ
  XOR A
  LD (ScanEarthTest),A
  LD (AntiGravEarthTest),A
  RET
