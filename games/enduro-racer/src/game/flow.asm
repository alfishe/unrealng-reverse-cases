; --------------------------------------------------------------------------------------------------------------------
; flow.asm: A game: the players' blocks and turns, a turn's screen, game over, the records, the lap table, the high scores and the name entry
;
; NewGame clears both player blocks (Player, the current one at $5E0D, and OtherPlayer at $5E45, 56 bytes each), and
; the turn loop swaps them before each turn, skipping a player whose Timer is 0. With one player the second block's
; timer stays 0, so every turn is player 1's. PlayTurn draws the HUD and runs the race (JP StartRace); it returns at a
; fall's end (the timer still running: the next turn; a stage's end goes on to StageStart in the same turn) or at game
; over (Timer 0: the records, the lap table, the high score entry). With two players a key is waited for between turns
; (twoplayer). The game ends, back to Attract, when both timers are 0.
;
; Times are BCD pairs: seconds (a value of $60 or more is one minute more) and hundredths. Records ($5E00) holds the
; five stage records and their total; a stage time shorter than its record replaces it at game over (RecordStages).
; The lap table shows the records beside the player's times, and for the stage the player did not finish the share of
; it driven, in %. The high score table (HiScores) has five rows of 22 characters: score, name and total time; a score
; above a row takes its place, the rows below move down, and the name is entered on a grid with the controls.
; --------------------------------------------------------------------------------------------------------------------

; Clear both player blocks, set the timers, the tracks and the countdowns, then
; the turn loop
;
; ClearScreen; $5E0D-$5E7C zero; both scores "      0"; outside a demo both
; countdowns 16; player characters '2' here and '1' in the other block (swapped
; at once by the loop); OtherPlayer's Timer = $60 and, with two players,
; Player's too; the track pointers TrackPtr = Track, the stage lists
; StageListPtr = StageList, the segment progress $80.
;
; Recorded: c1, m128: one player; twoplayer: both.
;
; Witness: L1 13 (c1, ctl, m128, stages, twoplayer).
NewGame:
  CALL ClearScreen
  LD HL,Player
  LD (HL),$00
  LD DE,StageTimes
  LD BC,$006F
  LDIR
  LD IX,Score
  LD BC,$0620
l_876C:
  LD (IX+$00),C
  LD (IX+$38),C
  INC IX
  DJNZ l_876C
  LD (IX+$00),$30
  LD (IX+$38),$30
  LD A,(DemoMode)
  AND A
  JR NZ,l_878C
  LD A,$10
  LD (Countdown),A
  LD (OtherPlayer+$0017),A
l_878C:
  LD A,$32
  LD (PlayerChar),A
  DEC A
  LD (OtherPlayer),A
  LD A,(Players)
  DEC A
  LD A,$60
  LD (OtherPlayer+$0012),A
  JR Z,l_87A3
  LD (Timer),A
l_87A3:
  LD HL,Track
  LD (TrackPtr),HL
  LD (OtherPlayer+$001A),HL
  LD HL,StageList
  LD (StageListPtr),HL
  LD (OtherPlayer+$001E),HL
  LD A,$80
  LD (SegmentLeft+$0001),A
  LD (OtherPlayer+$0019),A
; This entry point is used by the routine at TurnSkip.
TurnLoop:
  LD B,$38                ; swap the blocks (56 bytes); a player with Timer 0
                          ; is skipped
  LD IX,Player
l_87C3:
  LD A,(IX+$00)
  LD C,(IX+$38)
  LD (IX+$38),A
  LD (IX+$00),C
  INC IX
  DJNZ l_87C3
  LD A,(Timer)
  AND A
  JR Z,TurnLoop
  CALL PlayTurn           ; the turn
  LD A,(Timer)
  AND A
  LD A,(OtherPlayer+$0012)
  JR NZ,TurnNext
  AND A
  JP Z,Attract

; The player's game is over but the other's is not: next turn
;
; Known only from the code: in twoplayer both games ended in the same round of
; turns.
TurnSkip:
  JR TurnLoop
; This entry point is used by the routine at NewGame.
TurnNext:
  AND A                   ; the other's Timer 0 or one player: on; else Delay
                          ; and GetKey first
  JR Z,TurnLoop
  LD A,(Players)
  DEC A
  JR Z,TurnLoop
  CALL Delay
  CALL GetKey
  JR TurnLoop

; A turn: the HUD (frames, TOP, the best score, STAGE, TIME, SPEED, SCORE),
; GameEntry, a jump through GameEntryJump to StartRace; at game over the tables
;
; The pixel lines 0-63 cleared, their attributes $69; HudLayout's texts; two
; frames (FrameChars); DrawScore; the best score (HiScores' first row) at
; column 5; the stage in big digits; PrintTimer; SPEED 0; CALL GameEntry (JP
; GameEntryJump, JP StartRace). Back with Timer nonzero: RET (the next turn).
; Timer 0: the game is over: RecordStages, the totals (TotalTime = the player's
; finished stages, Records' total), the lap table (LapTable), then the high
; scores (ScoreCheck).
;
; Recorded: c1, m128: game over by the timer in stage 1; stages: game over
; after the finish; twoplayer: turns.
;
; Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).
PlayTurn:
  LD HL,$4000
  LD DE,$4001
  LD BC,$07FF
  LD (HL),$00
  LDIR
  LD HL,$5800
  LD B,$C0
l_880E:
  LD (HL),$69
  INC L
  DJNZ l_880E
  LD HL,HudTexts
  LD IX,HudLayout
  CALL PrintList
  LD IX,FrameChars
  LD HL,$0301
  LD BC,$0000
  LD E,$68
  CALL DrawFrame
  LD HL,$0501
  LD BC,$1200
  CALL DrawFrame
  CALL DrawScore
  LD HL,HiScores
  LD B,$05
  LD D,$07
  CALL PrintString
  LD A,(Stage)
  INC A
  LD DE,$0718
  CALL BigDigit
  CALL PrintTimer
  XOR A
  LD H,A
  LD L,A
  LD (Speed),HL
  LD BC,$1B18
  LD E,$68
  CALL PrintNumber
  CALL GameEntry          ; the race
  LD A,(Timer)
  AND A
  RET NZ
RecordStages:
  LD IX,Records           ; for each finished stage: a time below the record
                          ; replaces it
  LD A,(Stage)
  AND A
  JR Z,l_889C
  LD B,A
  LD C,A
; This entry point is used by the routine at RecordTie.
l_8871:
  LD H,(IX+$0F)
  LD L,(IX+$0E)
  LD A,(IX+$00)
  CP L
  JR C,l_888B
  JR NZ,l_8885

; Equal seconds: compare the hundredths
;
; Known only from the code: no recorded stage time had the record's seconds.
RecordTie:
  LD A,H
  CP (IX+$01)
  JR NC,l_888B
; This entry point is used by the routine at PlayTurn.
l_8885:
  LD (IX+$00),L           ; the new record
  LD (IX+$01),H
; This entry point is used by the routine at PlayTurn.
l_888B:
  INC IX
  INC IX
  DJNZ l_8871
  LD IX,StageTimes
  LD HL,TotalTime
  LD B,C
  CALL SumTimes
; This entry point is used by the routine at PlayTurn.
l_889C:
  LD IX,Records
  LD HL,Records+$000A
  LD B,$05
  CALL SumTimes
LapTable:
  LD HL,LapTexts+$0005    ; RECORD and PLAYER, five rows (stage, record, the
                          ; player's time or the % driven), TOTAL
  LD DE,$0650
  LD BC,$0B40
  CALL PrintString
  LD D,$06
  LD B,$14
  CALL PrintString
  LD BC,$0558
  LD HL,Records
l_88C1:
  PUSH BC
  PUSH HL
  PUSH HL
  LD A,B
  CPL
  ADD A,$06
  PUSH AF
  ADD A,$31
  LD B,$07
  CALL PrintGlyph
  LD E,$70
  LD B,$0B
  CALL FormatTime
  LD HL,TimeText
  LD D,$07
  CALL PrintString
  LD B,$14
  POP DE
  POP HL
  LD A,(Stage)
  CP D
  JR NZ,l_8910
LapPercent:
  PUSH BC                 ; the unfinished stage: segments driven * 100 / its
                          ; segments, then "%" (the font's @)
  LD A,(Segments)
  LD D,A
  LD HL,(StageListPtr)
l_88F1:
  INC A
  BIT 5,(HL)
  INC HL
  JR Z,l_88F1
  LD E,A
  CALL Divide
  LD A,$64
  CALL Multiply
  LD A,D
  POP BC
  LD B,$17
  LD E,$78
  CALL PrintNumber
  LD A,$40
  CALL PrintChar
  JR l_8922
l_8910:
  JR C,l_8922
  LD DE,$000E
  ADD HL,DE
  CALL FormatTime
  LD HL,TimeText
  LD DE,$0770
  CALL PrintString
l_8922:
  POP HL
  INC HL
  INC HL
  POP BC
  LD A,C
  ADD A,$10
  LD C,A
  DJNZ l_88C1
  LD BC,$03B0
  LD DE,$0550
  LD HL,LapTexts
  CALL PrintString
  LD B,$0B
  LD E,$68
  LD HL,Records+$000A
  CALL PrintTime
  LD B,$14
  LD HL,TotalTime
  LD A,(Stage)
  AND A
  CALL NZ,PrintTime
  CALL Delay
l_8951:
  CALL KeyOrFire
  JR NZ,l_8951
  LD BC,$03E8
  CALL WaitKey
ScoreCheck:
  XOR A                   ; the first HiScores row the score beats: insert
                          ; there, enter the name
  OUT ($FE),A
  LD HL,HiScores
  LD B,$05
l_8964:
  LD DE,Score
  PUSH HL
  PUSH BC
  LD B,$07
l_896B:
  LD A,(DE)
  CP (HL)
  JR Z,l_897A
  JR NC,l_897E
  POP BC
  POP HL
  LD DE,$0016
  ADD HL,DE
  DJNZ l_8964
  RET
l_897A:
  INC HL
  INC DE
  DJNZ l_896B
l_897E:
  POP BC
  LD A,B
  CPL
  ADD A,$09
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$0C
  LD (NamePlace+$0001),HL
  DEC B
  JR Z,l_899F
  LD HL,HiScores+$0057
  LD DE,HiScores+$006D
l_8996:
  PUSH BC
  LD BC,$0016
  LDDR
  POP BC
  DJNZ l_8996
l_899F:
  POP DE
  LD HL,Score
  LD C,$07
  LDIR
  EX DE,HL
  LD (NamePtr+$0001),HL
  LD B,$08
l_89AD:
  LD (HL),$20
  INC HL
  DJNZ l_89AD
  PUSH HL
  LD HL,TotalTime+$0001
  CALL FormatTime
  LD A,(TotalTime)
  ADD A,$30
  LD HL,TimeText
  LD (HL),A
  POP DE
  LD C,$07
  LDIR
  LD C,$10
  CALL ShowScores
NameEntry:
  LD E,$45                ; the grid (NameGrid, 15 characters a row, three
                          ; rows), the cursor (DrawCursor) moved by the
                          ; controls
  LD C,$90
  LD HL,NameGrid
l_89D3:
  LD B,$01
l_89D5:
  LD A,(HL)
  CALL PrintChar
  INC HL
  INC B
  LD A,B
  CP $1E
  JR C,l_89D5
  LD A,C
  ADD A,$10
  LD C,A
  CP $B1
  JR C,l_89D3
  XOR A
  LD (NameEntrySound+$0001),A
  LD IY,NameGrid
  LD HL,$0190
; This entry point is used by the routine at NameRightWrap.
l_89F3:
  LD (DrawCursor+$0001),HL
; This entry point is used by the routines at NameDelete and NameSpace.
l_89F6:
  LD IX,FrameChars
  CALL DrawCursor
l_89FD:
  CALL NameEntrySound
  CALL ReadControls
  BIT 4,D
  JR NZ,l_89FD
l_8A07:
  CALL NameEntrySound
  CALL ReadControls
  LD A,D
  AND $1F
  JR Z,l_8A07
  BIT 4,D                 ; fire: the character under the cursor; ? ends, =
                          ; deletes, else it is written
  JR Z,NameMove
NamePtr:
  LD HL,$0000             ; LD HL,nn: nn = the name's next place (written by
                          ; ScoreCheck and after each character)
NamePlace:
  LD BC,$0000             ; LD BC,nn: C the pixel line, B the column of the
                          ; name's next character (ScoreCheck; the column after
                          ; each character)
  LD A,$28
  LD (NameEntrySound+$0001),A
  LD A,(IY+$00)
  CP $3F
  JR Z,NameDone
  CP $3D
  JR NZ,l_8A38

; =: one character back, blanked (not before the first)
;
; The recording names (c1's play, the score POKEd to 300 000) types = after its
; first letter (frame 2 526).
;
; Witness: L1 1 (names).
NameDelete:
  LD A,B
  CP $0D
  JR C,l_89F6
  LD A,$20
  DEC B
  DEC HL
  LD (HL),A
  JR l_8A3A
; This entry point is used by the routine at RecordTie.
l_8A38:
  LD (HL),A               ; write the character
  INC HL
l_8A3A:
  LD (NamePtr+$0001),HL
  LD E,$42
  CALL PrintChar
  CP $20
  JR NZ,l_8A47

; After a delete's blank: DEC B, the column steps back
;
; Witness: L1 1 (names).
NameSpace:
  DEC B
; This entry point is used by the routine at NameDelete.
l_8A47:
  LD A,B                  ; eight characters: done
  LD (NamePlace+$0002),A
  CP $14
  JR C,l_89F6
; This entry point is used by the routine at RecordTie.
NameDone:
  LD A,(Timer)            ; Timer + the other's Timer nonzero: ClearScreen and
                          ; back; else RET
  LD HL,OtherPlayer+$0012
  ADD A,(HL)
  JP NZ,ClearScreen
  RET
; This entry point is used by the routine at RecordTie.
NameMove:
  LD HL,(DrawCursor+$0001) ; LEFT, RIGHT: two columns (the grid's step), UP,
                           ; DOWN: 16 lines; IY follows the character
  LD A,H
  BIT 2,D
  JR Z,l_8A70
  SUB $02
  JR NC,l_8A6D

; LEFT at the first column: wrap to column 29
;
; Witness: L1 1 (names).
NameLeftWrap:
  LD A,$1D
  LD BC,$000F
  ADD IY,BC
; This entry point is used by the routine at NameSpace.
l_8A6D:
  LD H,A                  ; the column
  DEC IY
; This entry point is used by the routine at NameSpace.
l_8A70:
  LD A,H
  BIT 3,D
  JR Z,l_8A85
  ADD A,$02
  CP $1E
  JR C,l_8A82

; RIGHT at the last column: wrap to column 1
;
; Witness: L1 1 (names).
NameRightWrap:
  LD A,$01
  LD BC,$FFF1
  ADD IY,BC
; This entry point is used by the routine at NameLeftWrap.
l_8A82:
  LD H,A                  ; the column
  INC IY
; This entry point is used by the routine at NameLeftWrap.
l_8A85:
  LD A,L
  BIT 0,D
  JR Z,l_8A96
  SUB $10
  CP $90
  JR C,l_8A96
  LD L,A
  LD BC,$FFF1
  ADD IY,BC
l_8A96:
  LD A,L
  BIT 1,D
  JR Z,l_8AA7
  ADD A,$10
  CP $B9
  JR NC,l_8AA7
  LD L,A
  LD BC,$000F
  ADD IY,BC
l_8AA7:
  PUSH HL
  LD IX,Blanks
  CALL DrawCursor
  POP HL
  JP l_89F3

; The frame's eight characters: corners and edges ([ % \ + / ] ) ^ in the
; font's own shapes)
;
; Order: top left, top, top right, left, right, bottom left, bottom, bottom
; right (DrawFrame). The font draws them as frame pieces
; (src/res/font/font.png).
FrameChars:
  INCBIN "res/texts/namegrid.bin",$0000,8
FrameChars2:
  INCBIN "res/texts/namegrid.bin",$0008,8

; The name entry's letters, three rows of 15: QWERTYUIOP=?789 ASDFGHJKL:;'456
; ZXCVBNM,.!@0123
;
; = deletes, ? ends; : ; ' ! @ are the font's own glyphs there.
NameGrid:
  INCBIN "res/texts/namegrid.bin",$0010,45

; One step of the name entry: a beeper blip rising in pitch for a few calls
; after a pick (NameSound counts down, the period is NameSound + 8), then a
; pause
;
; NameSound (the LD A operand) is set to $28 by a pick and counts down: 191
; edges of period NameSound + 8, then a quiet wait of 191 x ($31 - NameSound)
; turns, NameSound taken after the count (CPL, ADD A,$32): every call with a
; blip takes the same time. At 0 only the wait of 191 x $31 turns, a shorter
; call.
;
; Recorded: stages: the name entry; the OUT ($FE) at $8AFF.
;
; Witness: L1 1092 (names, stages).
NameEntrySound:
  LD A,$00
  AND A
  JR Z,l_8B0C
  DEC A
  LD (NameEntrySound+$0001),A
  ADD A,$08
  LD C,A
  LD D,$BF
  XOR A
l_8AFF:
  OUT ($FE),A
  XOR $10
  LD B,C
l_8B04:
  DJNZ l_8B04
  DEC D
  JR NZ,l_8AFF
  LD A,(NameEntrySound+$0001)
l_8B0C:
  CPL
  ADD A,$32
  LD C,A
  LD D,$BF
l_8B12:
  LD B,C
l_8B13:
  DJNZ l_8B13
  DEC D
  JR NZ,l_8B12
  RET

; Wipe and draw HiScores from pixel line C: SCORE, NAME, TIME, then five rows
; of score, name, time
;
; Witness: L1 2 (names, stages).
ShowScores:
  PUSH BC
  CALL ClearScreen
  POP BC
  LD HL,HudTexts+$0010
  LD B,$04
  LD DE,$0542
  CALL PrintString
  LD D,$04
  LD B,$17
  CALL PrintString
  LD D,$04
  LD B,$0E
  CALL PrintString
  LD B,$05
  LD A,C
  ADD A,$20
  LD C,A
l_8B3D:
  PUSH BC
  LD DE,$0746
  LD B,$03
  CALL PrintString
  LD DE,$0845
  LD B,$0C
  CALL PrintString
  LD DE,$0744
  LD B,$16
  CALL PrintString
  POP BC
  LD A,C
  ADD A,$10
  LD C,A
  DJNZ l_8B3D
  RET

; Print the time at HL (minutes, then FormatTime's pair) as 0'00"00, 7
; characters
;
; Witness: L1 4 (c1, names, stages).
PrintTime:
  PUSH HL
  INC HL
  CALL FormatTime
  POP HL
  LD A,(HL)
  ADD A,$30
  LD D,$07
  LD HL,TimeText
  LD (HL),A
  JP PrintString

; (HL) = minutes, seconds, hundredths: the sum of B times from IX (BCD, $60
; seconds a minute)
;
; Witness: L1 4 (c1, names, stages).
SumTimes:
  LD DE,$0000
  LD C,D
l_8B74:
  LD A,(IX+$01)
  ADD A,D
  DAA
  LD D,A
  LD A,(IX+$00)
  ADC A,E
  DAA
  JR NC,l_8B85
  INC C
  SUB $60
  DAA
l_8B85:
  LD E,A
  SUB $60
  JR C,l_8B8C
  LD E,A
  INC C
l_8B8C:
  INC IX
  INC IX
  DJNZ l_8B74
  LD (HL),C
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  RET

; HL = D * 256 / E (8.8 fixed point; C the remainder)
;
; The lap table's %, the road's slopes (BuildRoadRows).
;
; Witness: L1 138289 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
Divide:
  LD A,E
  LD BC,$1000
  LD HL,$0000
l_8B9F:
  RL D
  RL C
  LD A,C
  SUB E
  CCF
  JR NC,l_8BA9
  LD C,A
l_8BA9:
  ADC HL,HL
  DJNZ l_8B9F
  RET

; DE = A x L (8 x 8 bits, unrolled)
;
; Its last byte (MultiplyEnd) is a RET that RoadPatch turns into JP $93B1
; (DrawRoad) and RoadRows ($9A96) back into RET.
;
; Recorded: c1: called by the road and the objects every pass.
;
; Witness: L1 582990 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
Multiply:
  LD DE,$0000
  LD H,D
  RRCA
  JR NC,l_8BB8
  EX DE,HL
  ADD HL,DE
  EX DE,HL
l_8BB8:
  ADD HL,HL
  RRCA
  JR NC,l_8BBF
  EX DE,HL
  ADD HL,DE
  EX DE,HL
l_8BBF:
  ADD HL,HL
  RRCA
  JR NC,l_8BC6
  EX DE,HL
  ADD HL,DE
  EX DE,HL
l_8BC6:
  ADD HL,HL
  RRCA
  JR NC,l_8BCD
  EX DE,HL
  ADD HL,DE
  EX DE,HL
l_8BCD:
  ADD HL,HL
  RRCA
  JR NC,l_8BD4
  EX DE,HL
  ADD HL,DE
  EX DE,HL
l_8BD4:
  ADD HL,HL
  RRCA
  JR NC,l_8BDB
  EX DE,HL
  ADD HL,DE
  EX DE,HL
l_8BDB:
  ADD HL,HL
  RRCA
  JR NC,l_8BE2
  EX DE,HL
  ADD HL,DE
  EX DE,HL
l_8BE2:
  ADD HL,HL
  RRCA
  EX DE,HL
  JR NC,l_8BE8
  ADD HL,DE
l_8BE8:
  EX DE,HL
  ADD HL,HL
MultiplyEnd:
  RET                     ; RET, or JP DrawRoadRow while DrawRoad's patch is in

; The operand of MultiplyEnd's JP: $93B1 once patched (zeros in the image)
MultiplyJump:
  DEFB $00,$00

; The menu's texts as PrintList draws them: count 4, then (line, column,
; attribute, length) each
;
; ENDURO RACER, FROM SEGA, # 1987 ACTIVISION, START GAME (MenuTexts).
; src/res/texts/menu.txt has the texts.
MenuLayout:
  DEFB $04,$08,$01,$79,$0C,$08,$16,$7A
  DEFB $09,$10,$07,$7D,$11,$38,$0A,$47
  DEFB $0A
MenuLayout2:
  DEFB $04,$60,$06,$46,$14,$70,$0A,$46 ; CHANGE CONTROL MODE, DEFINE KEYS,
  DEFB $0C,$B0,$04,$04,$18,$B8,$04,$04 ; SPACE OR FIRE TO EXECUTE, ANY OTHER
  DEFB $18                             ; KEY TO ADVANCE
MenuItems:
  DEFB $04,$38,$0A,$47,$0A,$50,$0A,$46 ; MenuSelect's list: START GAME, ONE
  DEFB $0B,$60,$06,$46,$13,$70,$0A,$46 ; PLAYERS, CHANGE CONTROL MODE, DEFINE
  DEFB $0B                             ; KEYS
ControlItems:
  DEFB $05,$08,$02,$4F,$08,$10,$02,$4F ; the five methods (PrintList and
  DEFB $08,$18,$02,$4F,$0E,$20,$02,$4F ; MenuSelect)
  DEFB $0D,$28,$02,$4F,$06
DefineItems:
  DEFB $08,$08,$02,$4F,$04,$10,$02,$4F ; EXIT and the seven keys
  DEFB $08,$18,$03,$4F,$07,$20,$06,$4F
  DEFB $04,$28,$05,$4F,$05,$30,$04,$4F
  DEFB $06,$38,$05,$4F,$05,$40,$05,$4F
  DEFB $05

; The menu's texts, one after another as PrintList and PrintString take them
MenuTexts:
  INCBIN "res/texts/menu.bin",$0000,48
PlayerCountTexts:
  INCBIN "res/texts/menu.bin",$0030,14
MenuTexts2:
  INCBIN "res/texts/menu.bin",$003E,80
ControlTexts:
  INCBIN "res/texts/menu.bin",$008E,49
DefineTexts:
  INCBIN "res/texts/menu.bin",$00BF,44
Blanks:
  INCBIN "res/texts/menu.bin",$00EB,8

; The credits: count 4, then (length, attribute, ScrollUp steps) each
;
; 22 characters $45 then 48 steps, 23 $46 48, 24 $44 28, 17 $43 40.
CreditList:
  DEFB $04,$16,$45,$30,$17,$46,$30,$18
  DEFB $44,$1C,$11,$43,$28

; ENDURO RACER FROM SEGA, PRESENTED BY ACTIVISION, PROGRAMMED BY GIGA GAMES,
; GRAPHICS BY FOCUS
CreditTexts:
  INCBIN "res/texts/credits.bin",$0000,86

; The HUD's texts: count 6, (line, column, attribute, length): TOP, STAGE,
; SPEED, K<> (km/h), SCORE, TIME
HudLayout:
  DEFB $06,$08,$01,$7A,$03,$18,$01,$70
  DEFB $05,$18,$13,$70,$05,$18,$1D,$68
  DEFB $03,$08,$13,$7A,$05,$08,$0D,$60
  DEFB $04

; TOP STAGE SPEED K<> SCORE TIME, then NAME (ShowScores takes SCORE, TIME and
; NAME)
HudTexts:
  INCBIN "res/texts/hud.bin",$0000,29

; The high score table: five rows of score (7), name (8), total time (7)
;
; 1000000 ENDURO 3'00"00, 800000 RACER 2'30"00, 600000 SEGA 2'00"00, 400000
; A'VISION 1'30"00, 200000 GIGA1987 1'00"00. src/res/tables/hiscores.csv. A
; recording's run in the stages recording entered a row (WALKTHROUGH 6.2).
HiScores:
  INCBIN "res/tables/hiscores.bin",$0000,110

; JP StartRace (PlayTurn's CALL)
;
; Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).
GameEntry:
  JP GameEntryJump

; JP CopyRows
;
; Witness: L1 327207 (c1, ctl, m128, names, stages, twoplayer).
Copy32:
  JP CopyRows

; The steering force of each lean (-3 to 3): $AD $50 $28 $00 $28 $50 $AD
; (BikeControl, sign from the lean)
LeanTable:
  INCBIN "res/tables/lean.bin",$0000,7

; The steering force at each speed: index ScrollStep's high byte * 2 (0-20), 21
; bytes
;
; BikeControl reads $8E5D + 2 * (ScrollStep >> 8); the speed is at most 199,
; the step at most $AE2, so the index stays at or below 20 and only every
; second byte is read; except under the cheat: ScrollStep $1000 gives index 32,
; $8E7D, past SteerTail, the opcode $06 of render.asm's first LD B,$80 (full
; lean 0.5 pixel a pass, a game bug).
SteerTable:
  INCBIN "res/tables/steer.bin",$0000,21
SteerTail:
  INCBIN "res/tables/steer.bin",$0015,11
