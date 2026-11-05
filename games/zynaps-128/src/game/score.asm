; --------------------------------------------------------------------------------------------------------------------
; score.asm: Score and lives on the panel
;
; The two players' scores are 4 BCD bytes at the start of their records ($7F9C player 1, $7FCC player 2; $7F99 points
; at the current one, $7F98 is its number). AddScore adds an award from the points table $8231 and marks the panel for
; a redraw; PrintPlayerScore and DrawLives draw the panel; CompareScore ranks a score in the high-score table.
; --------------------------------------------------------------------------------------------------------------------

; Add award A to the current player's score
;
; A: the award number 0-11 of the points table $8231 (4 BCD bytes each: 0, 25,
; 50, 75, 100, 150, 200, 250, 500, 1000, 2000, 5000). The award is added from
; the low byte up to the score of player $7F98 (the low byte at $7F9F or
; $7FCF); bit 1 of $81C5 asks for the panel score redraw.
;
; Callers: the enemy kill (EnemyGone), the enemy movers (EnemyHandler),
; PodStep.
AddScore:
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,PointsTable+$0003 ; HL = the award's low byte
  ADD HL,DE
  LD DE,Player1+$0003     ; player 1's score, low byte
  LD A,(CurrentPlayer)
  DEC A
  JR Z,AddScoreBytes
  LD DE,Player2+$0003     ; player 2's
AddScoreBytes:
  LD B,$04
AddScoreByte:
  LD A,(DE)
  ADC A,(HL)
  DAA
  LD (DE),A
  DEC HL
  DEC DE
  DJNZ AddScoreByte
  LD HL,EventRequests     ; the score on the panel is out of date
  SET 1,(HL)
  RET

; Print player A's score on the panel
;
; A: the player, 1 or 2. Player 1's score at column 2, player 2's at column 22
; of the top row; bright white ($47) for the player in play, dark cyan ($05)
; for the other, leading zeros as spaces. Callers: the panel drawing (ScoreJob)
; and the player change (RoundPlaySetup).
PrintPlayerScore:
  PUSH AF
  LD C,A
  LD HL,Player1
  LD DE,$5802
  DEC A
  JR Z,PrintPlayerScoreColour
  LD HL,Player2
  LD DE,$5816
PrintPlayerScoreColour:
  LD A,(CurrentPlayer)
  CP C
  LD A,$47
  JR Z,PrintPlayerScoreAt
  LD A,$05
PrintPlayerScoreAt:
  EX AF,AF'               ; the leading spaces in blue ink
  LD A,$01
  LD (PrintAttr),A
  LD C,$20
  LD (PrintPos),DE
  CALL PrintBcd

; PrintPlayerScoreDone
PrintPlayerScoreDone:
  POP AF
  RET

; Is the score at DE above the score at HL?
;
; DE, HL: 4 BCD bytes each. Carry set when DE's score is greater (equal scores:
; no carry). Registers kept. Used by HighScoreEntry.
CompareScore:
  PUSH HL
  PUSH DE
  PUSH BC
  LD B,$04
CompareScoreByte:
  LD A,(DE)
  CP (HL)
  JR Z,CompareScoreNext
  JR CompareScoreDone
CompareScoreNext:
  INC DE
  INC HL
  DJNZ CompareScoreByte
  SCF
CompareScoreDone:
  CCF                     ; equal to the end: SCF then CCF, no carry
  POP BC
  POP DE
  POP HL
  RET

; Draw the current player's lives on the panel
;
; Six life marks from the attribute $5AD8 (row 22, column 24), the steps
; between them in $81C0: the first record+4 marks red on black ($42), the rest
; black. Callers: ScoreJob, RoundPlaySetup.
DrawLives:
  PUSH AF
  LD HL,$5AD8
  LD DE,LifeSteps
  LD IX,(PlayerRecord)
  LD A,(IX+$04)
  LD B,$06                ; six marks
  LD C,$42
DrawLivesMark:
  DEC A
  JP P,DrawLivesNext
  LD C,$00                ; past the lives: black
DrawLivesNext:
  LD (HL),C
  EX AF,AF'
  LD A,(DE)
  INC DE
  ADD A,L
  LD L,A
  EX AF,AF'
  DJNZ DrawLivesMark
  POP AF
  RET
