; --------------------------------------------------------------------------------------------------------------------
; screens.asm: The title page, the HUD text, the lifts, the high score table and the cell colours
;
; Data the menu and the level set-up print or copy; the editable forms are under src/res/text and src/res/tables.
; --------------------------------------------------------------------------------------------------------------------

; The title page's left half: 22 rows of 14 codes, the bottom row first
;
; TitlePage $A420 prints row k at character row 2 + k from the bottom, columns
; 0-13; codes $80-$8A are the big CHUCKIE EGG (its only codes from $80 up; the
; small A+F CHUCKIE EGG $8F-$96 is in HiScoreTable). The editable form is
; src/res/text/TitleText.txt (top row first). Witness: TitlePage runs 4 times
; in the eight builds.
TitleText:
  INCBIN "res/text/TitleText.bin",$0000,308

; The HUD: the SCORE label for the top row, 32 codes for the third
;
; SetupLevel $AE9C prints the first three (SCORE, codes $0B-$0D) at character
; row 23 (the top), the 32 at row 21: PLAYER ($0E-$11), LEVEL ($9B-$9D), BONUS
; ($1B-$1D) and TIME ($12-$14), each with its digits. It writes the digits
; first: $976B the player, $9772-$9773 the level, $977A the bonus's thousands,
; $9784 the time's hundreds (codes $9E + digit, HudCharacters); the image holds
; level 1's.
HudText:
  INCBIN "res/text/HudText.bin",$0000,7
HudPlayer:
  INCBIN "res/text/HudText.bin",$0007,7
HudLevel:
  INCBIN "res/text/HudText.bin",$000E,8
HudBonus:
  INCBIN "res/text/HudText.bin",$0016,10
HudTime:
  INCBIN "res/text/HudText.bin",$0020,3

; The lifts: the record in play, then one a level (1-8)
;
; A record is the screen address of the platform's start (two bytes), the
; lift's x ($FF: no lift) and its height count at the start (3). SetupLevel
; $AE9C copies level (Level AND 7) + 1's record over the first one and into
; Lift1; MoveLifts $A014 restarts a platform from the first one when it reaches
; the top. Lifts on levels 3-7 (x $40, $90, $C8, $78, $F0), none on 1, 2 and 8.
; The editable form is src/res/tables/LiftTable.csv. Witness: the restarts
; $A02E (164) and $A05C (167) in levels-1-3, gameover-name and levels-1-9.
LiftTable:
  INCBIN "res/tables/LiftTable.bin",$0000,36

; Leftover bytes
;
; Never read (L1: no access).
Leftover97AB:
  DEFB $6E,$73,$00,$00

; The ten best scores: ten name bytes and six digits each, the best first
;
; DrawHiScores $ABAD prints the table; EnterHiScore $A80C compares a score with
; each entry's digits ($97B9 + 16 k), shifts the lower entries down and writes
; the new one. The digits are ASCII ($30-$39), as GameOver $A7BC makes the
; scores. The editable form is src/res/text/HiScoreTable.txt. Witness:
; gameover-name writes one entry.
HiScoreTable:
  INCBIN "res/text/HiScoreTable.bin",$0000,160

; The attribute of map cell codes 0-8
;
; PaintCells $9538, EraseHen and SetupLevel $AE9C read CellAttributes + code
; (codes 9 and up take 6, yellow): empty 6, the ladder 3 and 3 (magenta), the
; egg 7, the grain 3, the brick 4 (green), then 6, 7, 7. The editable form is
; src/res/tables/CellAttributes.csv.
CellAttributes:
  INCBIN "res/tables/CellAttributes.bin",$0000,9
