; --------------------------------------------------------------------------------------------------------------------
; playerdata.asm: The two player records and the score scratch
;
; A player record is 48 bytes: the score, the lives, the level order index, the weapons, the extra life count and,
; from +$0D, the 35-byte state of the level script and the scroll, saved at each checkpoint (script op 14, $AED2) and
; taken back by $AD56 when the player starts or restarts. PlayerRecord $7F99 points at the current one.
; --------------------------------------------------------------------------------------------------------------------

; Player 1's record (48 bytes)
;
; +0-+3 the score (4 BCD bytes, high first; AddScore $A489), +4 the lives
; (DrawLives $A4EF), +5 the lives lost in the level (LevelStart clears it,
; PlayerDied $B119 adds 1), +6 the level order index (LevelDone $B174: +1 mod
; 12), +7 the pod selector 0-4, +8 the side weapon (0 none, 2 plasma, 3
; missiles, 4 seeker; script op 5 clears +8/+9), +9 the double plasma flag,
; +$0A the laser level 0-3, +$0B the speed $40-$A0, +$0C the extra-life index
; into ExtraLifeScores, +$0D-+$2F the level state (LevelTable's 8 bytes,
; ScriptStateInit's 5, the rest of ScriptState).
Player1:
  DEFB $00,$00,$00,$00
Player1Lives:
  DEFB $00                ; +4
Player1LivesLost:
  DEFB $00                ; +5
Player1LevelIndex:
  DEFB $00                ; +6 the index into LevelOrder
Player1PodSelector:
  DEFB $00                ; +7
Player1SideWeapon:
  DEFB $00                ; +8
Player1DoublePlasma:
  DEFB $00                ; +9
Player1LaserLevel:
  DEFB $00                ; +$0A
Player1Speed:
  DEFB $00                ; +$0B
Player1ExtraLives:
  DEFB $00                ; +$0C the extra lives given
Player1LevelState:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$0D-+$2F,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 35 bytes:
  DEFB $00,$00,$00                                                     ; the copy
                                                                       ; of
                                                                       ; ScriptState
                                                                       ; $81D7-$81F9

; Player 2's record (48 bytes), the same fields
;
; PlayersSetup $AFB7 zeroes both records (96 bytes from $7F9C), gives player 2
; three lives when two play, else none.
Player2:
  DEFB $00,$00,$00,$00
Player2Lives:
  DEFB $00
Player2LivesLost:
  DEFB $00
Player2LevelIndex:
  DEFB $00
Player2PodSelector:
  DEFB $00
Player2SideWeapon:
  DEFB $00
Player2DoublePlasma:
  DEFB $00
Player2LaserLevel:
  DEFB $00
Player2Speed:
  DEFB $00
Player2ExtraLives:
  DEFB $00
Player2LevelState:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00

; PrintBcd's copy of the number it prints ($A43E)
BcdScratch:
  DEFB $00,$00,$00,$00
