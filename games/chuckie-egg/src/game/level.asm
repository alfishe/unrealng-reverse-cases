; --------------------------------------------------------------------------------------------------------------------
; level.asm: Setting up a level
;
; SetupLevel draws the level from the map in play, sets every variable of the level and jumps into MainLoop.
; --------------------------------------------------------------------------------------------------------------------

; Draw the level, set it up and enter MainLoop
;
; ClearScreen; the 21 rows of the map in play (LiveMap) at rows 0-20; the HUD
; digits into HudText: the level (Level + 1 in BCD), the bonus's thousands
; min(Level + 1, 9), the time's hundreds 9 - min(Level / 16, 5), the player;
; HudText printed; every player's score printed (AddScore B = 0 with
; ScoreScreenAddr per player), then the score in play reloaded;
; LastTenThousands. The hens: Hens set to $FF, then the HenTable row (none on
; Level 8-15, all 20 bytes from 24). HenDelay 1, RandomPtr 0. The life icons
; (six at most) per player.
;
; The colours: the HUD rows, the player's column white on red ($17, others
; $0F); the map's cells (CellAttributes). Harry at ($64, $17), the duck at (8,
; $98), the jump, the duck's speeds, the counters; BonusRunning, BonusDelay,
; TimeDelay, DuckDelay and PassCounter 1. KeyTable from the key set of KeyType;
; ScoreScreenAddr; LiftTable's record for the level into the first and into
; Lift1, Lift2 one third higher, Lift2Row $43. LevelPhrase, a pause, the icon
; of the life in play erased, JP MainLoop.
;
; Witness: 35 calls.
SetupLevel:
  LD HL,Attributes+767
  LD BC,$1B00
SetupLevelClear:
  LD (HL),$00
  DEC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,SetupLevelClear
  LD BC,LiveMap
  LD H,$00
SetupLevelRow:
  LD L,$00
SetupLevelCell:
  LD A,(BC)
  CALL PrintChar
  INC BC
  INC L
  LD A,L
  CP $20
  JR NZ,SetupLevelCell
  INC H
  LD A,H
  CP $15
  JR NZ,SetupLevelRow
  LD A,(Level)
  LD B,A
  INC B
  XOR A
SetupLevelBcd:
  ADD A,$01
  DAA
  DJNZ SetupLevelBcd
  LD D,A
  AND $0F
  ADD A,$9E
  LD (HudLevel+$0001),A
  LD A,D
  LD B,$04
SetupLevelTens:
  SRL A
  DJNZ SetupLevelTens
  ADD A,$9E
  LD (HudLevel),A
  LD A,(Level)
  INC A
  CP $0A
  JR C,SetupLevelBonus
  LD A,$09
SetupLevelBonus:
  LD (BonusDigits),A
  ADD A,$9E
  LD (HudBonus),A
  LD A,(Level)
  SRL A
  SRL A
  SRL A
  SRL A
  CP $05
  JR C,SetupLevelTime
  LD A,$05
SetupLevelTime:
  LD C,A
  LD A,$09
  SUB C
  LD (TimeDigits),A
  ADD A,$9E
  LD (HudTime),A
  LD A,(Player)
  ADD A,$9E
  LD (HudPlayer),A
  LD HL,$1700
  LD DE,HudText
  LD B,$03
SetupLevelHudTop:
  LD A,(DE)
  CALL PrintChar
  INC L
  INC DE
  DJNZ SetupLevelHudTop
  LD HL,$1500
  LD B,$20
SetupLevelHud:
  LD A,(DE)
  CALL PrintChar
  INC L
  INC DE
  DJNZ SetupLevelHud
  LD HL,Screen-$0002
  LD (ScoreScreenAddr),HL
  LD A,(Players)
  LD HL,PlayerScores
SetupLevelScores:
  LD DE,Score
  LD BC,$0006
  LDIR
  PUSH HL
  LD BC,$0007
  LD HL,(ScoreScreenAddr)
  ADD HL,BC
  LD (ScoreScreenAddr),HL
  LD B,$00
  PUSH AF
  CALL AddScore
  POP AF
  POP HL
  DEC A
  JR NZ,SetupLevelScores
  LD BC,$0006
  LD HL,Score
  LD A,(Player)
SetupLevelScore:
  ADD HL,BC
  DEC A
  JR NZ,SetupLevelScore
  LD DE,Score
  LDIR
  LD A,(Score+1)
  LD (LastTenThousands),A
  LD B,$14
  LD HL,Hens
SetupLevelNoHens:
  LD (HL),$FF
  INC HL
  DJNZ SetupLevelNoHens
  LD A,(Level)
  CP $08
  JR C,SetupLevelHens
  CP $10
  JR C,SetupLevelIcons
SetupLevelHens:
  AND $07
  LD HL,HenTable
  LD BC,$0015
  INC A
SetupLevelHenRow:
  ADD HL,BC
  DEC A
  JR NZ,SetupLevelHenRow
  LD B,(HL)
  INC HL
  LD A,(Level)
  CP $18
  JR C,SetupLevelHenCopy
  LD B,$14
SetupLevelHenCopy:
  LD DE,Hens
SetupLevelHenByte:
  LD A,(HL)
  LD (DE),A
  INC DE
  INC HL
  DJNZ SetupLevelHenByte
SetupLevelIcons:
  LD HL,$0001
  LD (HenDelay),HL
  LD H,$16
  LD L,$05
  LD A,(Players)
  LD B,A
  LD DE,PlayerLives
SetupLevelIconsPlayer:
  PUSH HL
  LD A,(DE)
  CP $07
  JR C,SetupLevelIconsCount
  LD A,$06
SetupLevelIconsCount:
  INC DE
  AND A
  JR Z,SetupLevelIconsNext
  LD C,A
  LD A,$B6
SetupLevelIcon:
  CALL PrintChar
  INC L
  DEC C
  JR NZ,SetupLevelIcon
SetupLevelIconsNext:
  POP HL
  LD A,L
  ADD A,$07
  LD L,A
  DJNZ SetupLevelIconsPlayer
  LD HL,$0000
  LD B,$03
  LD A,$17
  CALL FillAttrRow
  INC H
  LD B,$20
  LD A,$06
  CALL FillAttrRow
  INC H
  LD B,$05
  LD A,$17
  CALL FillAttrRow
  LD L,$07
  INC B
  CALL FillAttrRow
  LD B,$08
  LD L,$0F
  CALL FillAttrRow
  DEC B
  LD L,$19
  CALL FillAttrRow
  LD HL,$0005
  LD BC,$0601
SetupLevelPlayerColour:
  LD D,$0F
  LD A,(Player)
  CP C
  JR NZ,SetupLevelPlayerFill
  LD D,$17
SetupLevelPlayerFill:
  LD A,D
  CALL FillAttrRow
  LD A,L
  ADD A,$07
  LD L,A
  INC C
  LD A,(Players)
  CP C
  JR NC,SetupLevelPlayerColour
  LD HL,LiveMap
  LD DE,Attributes+736
  LD C,$15
SetupLevelAttrRow:
  LD B,$20
  PUSH DE
SetupLevelAttrCell:
  PUSH BC
  LD A,(HL)
  CP $09
  JR C,SetupLevelAttrTable
  LD A,$06
  JR SetupLevelAttrSet
SetupLevelAttrTable:
  ADD A,$4F
  LD B,$98
  LD C,A
  LD A,(BC)
SetupLevelAttrSet:
  LD (DE),A
  INC DE
  INC HL
  POP BC
  DJNZ SetupLevelAttrCell
  POP DE
  EX DE,HL
  PUSH DE
  LD DE,$0020
  AND A
  SBC HL,DE
  POP DE
  EX DE,HL
  DEC C
  JR NZ,SetupLevelAttrRow
  LD IX,HarryX
  LD (IX+$00),$64
  LD (IX+$01),$17
  LD (IX+$70),$08
  LD (IX+$71),$98
  LD (IX+$64),$05
  XOR A
  LD (IX+$68),A
  LD (IX+$69),A
  LD (IX+$6B),A
  LD (IX+$6C),A
  LD (IX+$72),A
  LD (IX+$73),A
  LD (IX+$75),A
  LD (IX+$7D),A
  LD (IX+$02),A
  LD (IX+$03),A
  LD (IX+$4D),A
  LD (HenTurn),A
  LD (SoundSweep),A
  INC A
  LD (IX+$6F),A
  LD (IX+$6D),A
  LD (IX+$6E),A
  LD (IX+$74),A
  LD (IX+$04),A
  LD A,(KeyType)
  CP $05
  LD HL,KeySet2
  JR Z,SetupLevelKeys
  LD HL,KeySet3
  JR C,SetupLevelKeys
  LD HL,KeySets
SetupLevelKeys:
  LD BC,$000C
  LD DE,KeyTable
  LDIR
  LD BC,$0007
  LD HL,Screen-$0002
  LD A,(Player)
SetupLevelScoreAddr:
  ADD HL,BC
  DEC A
  JR NZ,SetupLevelScoreAddr
  LD (ScoreScreenAddr),HL
  LD BC,$0004
  LD HL,LiftTable
  PUSH HL
  POP DE
  LD A,(Level)
  AND $07
  INC A
SetupLevelLift:
  ADD HL,BC
  DEC A
  JR NZ,SetupLevelLift
  LDIR
  LD BC,$0004
  AND A
  SBC HL,BC
  LD DE,Lift1
  LDIR
  LD (IX+$7C),$43
  LD HL,(Lift1)
  LD BC,$0800
  AND A
  SBC HL,BC
  LD (Lift2),HL
  CALL LevelPhrase
  LD D,$1E
SetupLevelPause:
  LD BC,$2710
SetupLevelPauseLoop:
  DEC BC
  LD A,B
  OR C
  JR NZ,SetupLevelPauseLoop
  DEC D
  JR NZ,SetupLevelPause
  LD A,(Player)
  LD L,A
  LD H,$00
  LD DE,PlayerLives-$0001
  ADD HL,DE
  LD C,A
  LD A,(HL)
  CP $07
  JR NC,SetupLevelPlay
  SUB $03
SetupLevelIconColumn:
  ADD A,$07
  DEC C
  JR NZ,SetupLevelIconColumn
  LD H,$16
  LD L,A
  XOR A
  CALL PrintChar
SetupLevelPlay:
  JP MainLoop

; B attributes A on row H (0-2 from the top), from column L
;
; Witness: 252 calls.
FillAttrRow:
  PUSH HL
  PUSH BC
  PUSH AF
  LD E,L
  LD A,H
  LD HL,Attributes
  AND A
  JR Z,FillAttrRowAt
  LD HL,Attributes+32
  DEC A
  JR Z,FillAttrRowAt
  LD HL,Attributes+64
FillAttrRowAt:
  LD D,$00
  ADD HL,DE
  POP AF
FillAttrRowCell:
  LD (HL),A
  INC HL
  DJNZ FillAttrRowCell
  POP BC
  POP HL
  RET

; Speak one of the eight LevelPhrases (R AND 7)
;
; Witness: 35 calls.
LevelPhrase:
  LD HL,LevelPhrases-$0001
  LD A,R
  AND $07
  INC A
  LD B,A
LevelPhraseFind:
  INC HL
  DJNZ LevelPhraseFind
  LD A,(HL)
  JP StartPhrase
