; --------------------------------------------------------------------------------------------------------------------
; colour.asm: The sprites' colour cells, and the wait for a key or fire
; --------------------------------------------------------------------------------------------------------------------

; ColourCells for a 24x32 sprite: 3 x 4 cells (4 x 5 when not aligned)
;
; Called by $8229 with DrawBigSprite. C = the attribute, DE = x, y.
ColourBigSprite:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,$1D
  LD H,$00
  LD (ColourRowSkip+$0001),HL
  LD A,$03
  LD (ColourWidth+$0001),A
  LD A,$04
  LD (ColourHeight+$0001),A
  JP ColourCells

; ColourCells for one 8x8 cell (2 x 2 when not aligned)
;
; Callers: $9291, $955D, $9835, $9A7F, $9DD6 (shots and small objects).
ColourCell:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,$1F
  LD H,$00
  LD (ColourRowSkip+$0001),HL
  LD A,$01
  LD (ColourWidth+$0001),A
  LD A,$01
  LD (ColourHeight+$0001),A
  JP ColourCells

; ColourCells for a 16x16 sprite: 2 x 2 cells (3 x 3 when not aligned)
;
; Callers: MenuSparkles ($47), $9FBD, $A26B, $A367, $A7D6, $AC7D.
ColourSprite:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,$1E
  LD H,$00
  LD (ColourRowSkip+$0001),HL
  LD A,$02
  LD (ColourWidth+$0001),A
  LD A,$02
  LD (ColourHeight+$0001),A
  JP ColourCells

; Writes attribute C over a sprite's cells where the background attribute copy
; $5E00 is 0 (black)
;
; DE = x (2-pixel steps), y. HL = $5E00 + the cell ($80DA), the screen
; attribute at HL - $600. The width (ColourWidth), the row step (ColourRowSkip)
; and the height (ColourHeight) are patched by the three entries above; one
; more column when x AND 3 is not 0, one more row when y AND 7 is not 0. A cell
; whose $5E00 copy is non-zero keeps its colour: a sprite passing in front of
; coloured scenery takes the scenery's colour. Keeps every register.
ColourCells:
  CALL AttrShadowCell
  LD A,C
  PUSH HL
  LD BC,OpenCells-CellTypes
  ADD HL,BC
  LD C,A
  PUSH HL
  LD A,E
  AND $03
ColourRowSkip:
  LD HL,$001D             ; LD HL,n: 32 - the width (patched)
ColourWidth:
  LD A,$03                ; LD A,n: the width in cells (patched)
  JR Z,ColourAligned
  DEC HL
  INC A
ColourAligned:
  LD (ColourRowCells+$0001),A ; one more column when x is not on a cell
  LD (ColourRowStep+$0001),HL
  LD A,D
  AND $07
ColourHeight:
  LD A,$04                ; LD A,n: the height in cells (patched)
  JR Z,ColourStart
  INC A
ColourStart:
  POP HL                  ; HL = the screen attributes, DE = the copy
  POP DE
ColourRow:
  EX AF,AF'
ColourRowCells:
  LD B,$00                ; LD B,n: the cells of a row (patched)
ColourBlackCell:
  LD A,(DE)               ; a black background cell takes C
  OR A
  JR NZ,ColourNextCell
  LD (HL),C
ColourNextCell:
  INC HL
  INC DE
  DJNZ ColourBlackCell
  LD A,C
ColourRowStep:
  LD BC,$0000             ; LD BC,n: on to the next row (patched)
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD C,A
  EX AF,AF'
  DEC A
  JR NZ,ColourRow
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; The pause: waits for fire or any key (A = its ASCII from the table $ACEF,
; fire gives '0')
;
; Jumped to by $AD21 after the pause key 3 (row $F7 alone reads $1B), a delay
; and a wait for no key. ReadControls each round: fire ends it with A = '0';
; else the keyboard's 40 keys are scanned half-row by half-row against the key
; table $ACEF until one is down. Never ran in the given recordings; exA1: 3
; pressed in play, 4631 rounds, then Kempston fire resumed the game.
WaitKeyOrFire:
  PUSH BC
  PUSH HL
PauseLoop:
  CALL ReadControls       ; the controls first: fire resumes with A = '0'
  LD A,(ControlFire)
  OR A
  LD A,$30
  JR NZ,PauseDone
  LD HL,KeyTable
  LD D,$FE
PauseScanRow:
  LD A,D                  ; one half-row of the keyboard
  IN A,($FE)
  LD E,$01
  LD B,$05
PauseScanBit:
  RRCA
  JR NC,WaitKeyOrFireKey
  INC HL
  SLA E
  DJNZ PauseScanBit
  RLC D
  JR C,PauseScanRow
  JR PauseLoop
WaitKeyOrFireKey:
  LD A,(HL)               ; A = the key's ASCII
PauseDone:
  POP HL
  POP BC
  RET
