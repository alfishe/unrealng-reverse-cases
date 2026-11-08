; --------------------------------------------------------------------------------------------------------------------
; forcefield.asm: The force field and the idle missile
; --------------------------------------------------------------------------------------------------------------------

; Draws the screen's force field (tile 17): character $25 down from under its
; cell to the first solid cell
;
; Jumped to at the end of the screen set-up ($8520). Font $DAB8; PrintChar's
; $5B00 mark 0 and its $6100 kind 1 (the cells become solid for the player);
; the column from row + 1 down while the map $6100 is 0; ForceFieldHeight = the
; cells drawn; ForceFieldHits = 0.
ForceFieldDraw:
  LD DE,(ForceFieldList)
  BIT 7,E
  RET NZ
  INC D
  LD HL,TileGlyphs
  LD (PrintChar+$000E),HL
  XOR A
  LD (ForceFieldHits),A
  LD (PrintCharLine+$001E),A
  INC A
  LD (PrintCharLine+$0018),A
  LD BC,$0001
ForceFieldDrawLoop:
  LD A,$25
  CALL PrintChar
  INC D
  INC B
  CALL CellOffset
  PUSH DE
  LD DE,CellTypes
  ADD HL,DE
  POP DE
  LD A,(HL)
  OR A
  JR Z,ForceFieldDrawLoop
  LD A,B
  LD (ForceFieldHeight),A
  RET

; The force field's cell (column, row) from the builder (tile 17), $FF at
; $ABCE; $FF in the first: none or destroyed
ForceFieldList:
  DEFB $00,$00,$FF

; The force field: a buzz, its column's colour cycling, and death for a player
; who walks into it
;
; Main loop ($7647). Sounds $C1A9 (AY effects 1 and $0B), ink = $768C AND 7
; bright on every cell of the column. The player at X + $0C = the field's X
; (column x 4): KillPlayer.
ForceFieldStep:
  LD DE,(ForceFieldList)
  BIT 7,E
  RET NZ
  CALL PlaySfxHum
  INC D
  LD A,(ForceFieldHeight)
  LD B,A
  CALL CellOffset
  LD DE,$5800
  ADD HL,DE
  LD DE,$0020
ForceFieldColour:
  LD A,(PassCount)
  AND $07
  OR $40
  LD (HL),A
  ADD HL,DE
  DJNZ ForceFieldColour
  LD DE,(ForceFieldList)
  CALL CellToPixels
  LD A,(PlayerX)
  ADD A,$0C
  CP E
  JP Z,KillPlayer
  RET

; Counts the player's shots that reach the force field; the 25th destroys it
;
; Called by the shot step $83DD. A live shot of $845F whose X equals the
; field's (column - 1) x 4 counts once a pass in ForceFieldHits; from 25 on:
; ForceFieldDestroy. No recording got that far (the counter is reset with each
; screen).
ForceFieldVsShots:
  LD DE,(ForceFieldList)
  BIT 7,E
  RET NZ
  DEC E
  CALL CellToPixels
  LD HL,ShotList
ForceFieldVsShotsLoop:
  LD C,(HL)
  BIT 7,C
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,ForceFieldVsShotsLoop
  LD A,E
  CP C
  JR NZ,ForceFieldVsShotsLoop
  LD A,(ForceFieldHits)
  INC A
  LD (ForceFieldHits),A
  CP $19
  RET C

; The force field's 25th hit: erased cell by cell, removed, AY effect 6, 1000
; points
;
; Font $DAB8; for the ForceFieldHeight cells from under the field's cell,
; XorChar $AE95 draws character $25 again in a random bright ink $42-$47 (XOR:
; the field disappears, its cells' marks cleared and their kinds 0);
; ForceFieldList = $FF; AY effect 6 ($C148); JP AddBonusTicks with A = $28 (40
; ticks, 1000 points). Never ran in any recording: no run put 25 shots into one
; force field (ForceFieldHits is reset with each screen).
ForceFieldDestroy:
  LD HL,TileGlyphs
  LD (PrintChar+$000E),HL ; font $DAB8
  LD DE,(ForceFieldList)
  LD A,(ForceFieldHeight) ; B = ForceFieldHeight
  LD B,A
  INC D
ForceFieldErase:
  CALL Random             ; the next cell: a random ink
  AND $07
  OR $42
  LD C,A
  LD A,$25
  CALL EraseBlockDebris   ; XorChar: character $25 erased
  INC D
  DJNZ ForceFieldErase
  LD A,$FF                ; the field gone
  LD (ForceFieldList),A
  LD A,$28                ; 40 ticks, 1000 points
  CALL PlaySfxBlast
  JP AddBonusTicks

; The force field's cells, counted by ForceFieldDraw
ForceFieldHeight:
  DEFB $00

; The shots that reached the force field on this screen
ForceFieldHits:
  DEFB $00

; A player who stays 700 passes on one screen gets a missile from the right at
; his height
;
; Main loop ($764A). IdleTime (+1 each pass at $7682, 0 at a new screen $8497,
; a death $9CAF and $9CBE) reaching $2BC (700 passes, about 28 s at 2 frames a
; pass): the missile at X = $78 and the player's Y. The time is not reset by
; the missile: one follows the other while he stays.
IdleMissileStart:
  LD A,(IdleMissileLive)
  OR A
  RET NZ
  LD HL,(IdleTime)
  AND A
  LD DE,$02BC
  SBC HL,DE
  RET C
  LD DE,(PlayerX)
  LD E,$78
  LD (IdleMissilePosition),DE
  LD A,$01
  LD (IdleMissileLive),A
  RET

; 1 while the idle missile flies
IdleMissileLive:
  DEFB $00

; Its X, Y
IdleMissilePosition:
  DEFB $00,$00

; The passes spent on the current screen (cleared by a new screen and a death)
IdleTime:
  DEFW $0000

; Moves the idle missile 2 left a pass, with smoke now and then, and kills the
; player it touches
;
; Main loop ($764D). At X = 0: the end. X < $6F: half the passes ($AD36 >= $80)
; a small explosion behind it (X + 6, Y + 4). X - 2; frame $24 in the slot
; $B6A1, white. A touch ($9BD6, B = $10, C = 8): KillPlayer. The end: the slot
; cleared, IdleMissileLive 0, a blast.
IdleMissileStep:
  LD A,(IdleMissileLive)
  OR A
  RET Z
  LD DE,(IdleMissilePosition)
  LD B,D
  LD C,E
  LD A,E
  OR A
  JR Z,IdleMissileEnd
  CP $6F
  JR NC,IdleMissileMove
  CALL Random
  CP $80
  JR C,IdleMissileMove
  PUSH DE
  LD A,E
  ADD A,$06
  LD E,A
  LD A,D
  ADD A,$04
  LD D,A
  CALL AddPuff
  POP DE
IdleMissileMove:
  DEC E
  DEC E
  LD (IdleMissilePosition),DE
  LD A,$24
  LD HL,WorkArea+$0520
  CALL DrawSprite
  LD C,$47
  CALL ColourSprite
  LD BC,$1008
  CALL PlayerContact
  OR A
  RET Z
  PUSH DE
  CALL KillPlayer
  POP BC
IdleMissileEnd:
  LD HL,WorkArea+$0520
  XOR A
  LD (IdleMissileLive),A
  CALL DrawSprite
  JP StartBlast
