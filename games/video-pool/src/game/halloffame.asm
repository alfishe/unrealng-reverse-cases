; --------------------------------------------------------------------------------------------------------------------
; halloffame.asm: The hall of fame: the qualifying test, the flags on their poles, the slide of the flags, the table
;
; The hall of fame is three slots of 71 bytes at HofTable $AC08, fixed on screen: slot 1 (centre, the highest pole,
; yellow), slot 2 (left, magenta), slot 3 (right, green). A slot holds the score (a word, shown x 10), the name (7
; characters), the flag's current position, the pole's position, the flag's attribute, a "moves" flag and the name
; rendered as a 7 x 8-byte bitmap (inverted glyphs: the flag is solid ink, the letters paper). The ranking moves the
; score and name only (9 bytes); the positions and colours stay with the slot.
;
; At GAME OVER ($9857) GameOverHallOfFame $A702 counts the slots a score beats (CountBeaten $A7EB, ties do not
; qualify). If it beats none, nothing happens (game and f1). Otherwise the name page and name entry run ($ACEF, module
; nameentry), then the hall of fame is drawn (ShowHallOfFame $A8FD: poles, flags, scores), the flags that lose their
; place slide down off the screen (ShowAndSlideDown $A86D), the new entry is inserted (InsertEntry $A817) and the
; flags slide back up to their poles with the new names (SlideFlagsUp $A8C7). w1 ran it all at frames 12018-13732 with
; the name "vp" (screens w1 frames 12500, 13300, 14000). The attract sequence also shows the table through
; ShowHallOfFame ($B906, when $BD0B is set).
;
; The two-player path ($A745-$A7E8) enters a name for each qualifying player ("congratulations! player 1 / 2", $9B30 =
; 1 / 2) and inserts both; no recording ran it (p2 ended by BREAK): known only from the code.
; --------------------------------------------------------------------------------------------------------------------

; At GAME OVER: enter the hall of fame if the score qualifies
;
; Called once by $985D (the GAME OVER path $9857). Clears the "moves" flag
; (+$0E) of the three slots. One player (Players $B8BB = 1): copies the score
; $9F45 to NewEntry1 $ACDD, counts the slots it beats (CountBeaten $A7EB) and
; returns if none; else runs the name page and entry (NameEntryPage $ACEF),
; copies NameBuffer $B227 to NewEntryName1 $ACDF, then ShowAndSlideDown $A86D,
; InsertEntry $A817 for NewEntry1 and SlideFlagsUp $A8C7 (a jump: its RET
; returns to $9860).
;
; Witness: game 1 (frame 9061) and f1 1 (frame 4695) returned at $A72A (score
; below every slot); w1 1 (frame 12018) went on to the name entry; $A72E w1 1,
; frames 13368-13553.
GameOverHallOfFame:
  LD IX,HofTable
  LD (IX+$0E),$00
  LD IX,HofSlot2
  LD (IX+$0E),$00
  LD IX,HofSlot3
  LD (IX+$0E),$00
  LD A,(Players)
  DEC A
  JR NZ,TwoPlayers
  LD HL,(ScorePlayer1)
  LD (NewEntry1),HL
  CALL CountBeaten
  OR A
  RET Z
  CALL NameEntryPage
OnePlayerQualified:
  LD HL,NameBuffer        ; store the name typed and show the hall of fame
  LD DE,NewEntryName1
  LD BC,$0007
  LDIR
  CALL ShowAndSlideDown
  LD DE,NewEntry1
  CALL InsertEntry
  JP SlideFlagsUp
TwoPlayers:
  LD HL,(ScorePlayer1)    ; B = the slots player 1 beats, C = player 2's
  CALL CountBeaten
  PUSH AF
  LD HL,(ScorePlayer2)
  CALL CountBeaten
  POP BC
  LD C,A
  LD A,B
  OR C
  RET Z
  LD A,B
  OR A
  JR Z,TwoPlayersFirst
  LD A,C
  OR A
  JR Z,TwoPlayersFirst
  LD A,B
  DEC A
  JR NZ,TwoPlayersOneLast
  LD A,C
  DEC A
  JR Z,TwoPlayersBothLast
TwoPlayersOneLast:
  LD A,B                  ; one of them beats only slot 3 and the other more:
                          ; the one with 1 is dropped
  DEC A
  JR Z,TwoPlayersDropOne
  LD A,C
  DEC A
  JR Z,TwoPlayersDropOne
  JR TwoPlayersFirst
TwoPlayersBothLast:
  LD HL,(ScorePlayer1)    ; both beat only slot 3: the lower score is dropped
                          ; (a tie keeps player 1)
  LD DE,(ScorePlayer2)
  XOR A
  SBC HL,DE
  JR C,TwoPlayersDropFirst
  DEC C
  JR TwoPlayersRanked
TwoPlayersDropFirst:
  DEC B                   ; player 1's score is lower: B = 0
TwoPlayersRanked:
  JR TwoPlayersFirst
TwoPlayersDropOne:
  LD A,B                  ; drop the one whose count is 1
  DEC A
  JR NZ,TwoPlayersDropSecond
  LD B,$00
  JR TwoPlayersFirst
TwoPlayersDropSecond:
  LD C,$00
TwoPlayersFirst:
  LD A,B                  ; player 1 does not qualify: NewEntry1's score word =
                          ; 0
  OR A
  JR NZ,TwoPlayersNameFirst
  LD HL,$0000
  LD (NewEntry1),HL
  JR TwoPlayersSecond
TwoPlayersNameFirst:
  PUSH BC                 ; name entry with $9B30 = 1, the record at NewEntry1
  LD A,$01
  LD (CurrentPlayer),A
  CALL NameEntryPage
  LD HL,NameBuffer
  LD DE,NewEntryName1
  LD BC,$0007
  LDIR
  POP BC
  LD HL,(ScorePlayer1)
  LD (NewEntry1),HL
TwoPlayersSecond:
  LD A,C                  ; player 2 does not qualify: NewEntry2's score word =
                          ; 0
  OR A
  JR NZ,TwoPlayersNameSecond
  LD HL,$0000
  LD (NewEntry2),HL
  JR TwoPlayersShow
TwoPlayersNameSecond:
  LD A,$02                ; name entry with $9B30 = 2, the record at NewEntry2
  LD (CurrentPlayer),A
  CALL NameEntryPage
  LD HL,NameBuffer
  LD DE,NewEntryName2
  LD BC,$0007
  LDIR
  LD HL,(ScorePlayer2)
  LD (NewEntry2),HL
TwoPlayersShow:
  CALL ShowAndSlideDown   ; show, slide down, insert both records, slide up
  LD DE,NewEntry1
  CALL InsertEntry
  LD DE,NewEntry2
  CALL InsertEntry
  JP SlideFlagsUp

; A = how many hall-of-fame slots the score HL beats, flagging them
;
; Input HL: the score. Tests slot 3, slot 2, slot 1 in that order with TestSlot
; $A802; each slot whose score is below HL (strictly) gets +$0E = 1 (its flag
; will move) and adds 1 to A; the first slot not beaten ends the count
; (TestSlot drops CountBeaten's frame and returns to the caller). Output A =
; 0-3, Z when 0.
;
; Witness: game 1, f1 1 (both A = 0), w1 2 (frames 12018 and 13553, from $A702
; and InsertEntry).
CountBeaten:
  XOR A
  LD IX,HofSlot3
  CALL TestSlot
  LD IX,HofSlot2
  CALL TestSlot
  LD IX,HofTable
  CALL TestSlot
  RET

; Beaten-slot test for CountBeaten: score HL against slot IX
;
; IX: the slot. If HL > the slot's score (+0/+1): A + 1, +$0E = 1, return to
; CountBeaten. Else POP the return address and RET to CountBeaten's caller with
; the count so far. Witness: game 1, w1 6, f1 1; $A811 (beaten) w1 4.
TestSlot:
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH HL
  SCF
  SBC HL,DE
  POP HL
  JR NC,SlotBeaten
  POP DE
  RET
SlotBeaten:
  INC A
  LD (IX+$0E),$01
  RET

; Insert the 9-byte record at DE (score, name) into the table and render the
; three names again
;
; DE: a new-entry record (NewEntry1 $ACDD or NewEntry2 $ACE6). A zero score
; returns at once (a player who did not qualify). Ranks the score with
; CountBeaten (which flags the slots that will change), moves slot 2 to slot 3
; (rank 2 or 3) and slot 1 to slot 2 (rank 3), 9 bytes each, copies the record
; into the freed slot, then RenderName $AADF for all three slots.
;
; Witness: w1 1 at frame 13553 ("vp", 270, into slot 2: james stays first,
; francis moves to slot 3, bill drops out; screen w1 frame 14000).
InsertEntry:
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  DEC DE
  LD A,H
  OR L
  RET Z
  PUSH DE
  CALL CountBeaten
  PUSH AF
  DEC A
  JR Z,InsertCopy
  LD HL,HofSlot2
  LD DE,HofSlot3
  LD BC,$0009
  LDIR
  DEC A
  JR Z,InsertCopy
  LD HL,HofTable
  LD DE,HofSlot2
  LD BC,$0009
  LDIR
InsertCopy:
  POP AF                  ; DE = the slot the rank frees
  LD DE,HofSlot3
  DEC A
  JR Z,InsertStore
  LD DE,HofSlot2
  DEC A
  JR Z,InsertStore
  LD DE,HofTable
InsertStore:
  POP HL
  LD BC,$0009
  LDIR
  LD IX,HofTable
  CALL RenderName
  LD IX,HofSlot2
  CALL RenderName
  LD IX,HofSlot3
  CALL RenderName
  RET

; Show the hall of fame, then slide the flags that lose their place down off
; the screen
;
; ShowHallOfFame $A8FD, 50 frames' pause (HALTs), BlankScore $AA4B over each
; flagged slot's score, then one pixel a frame SlideFlagDown $A95A on each slot
; until no slot has +$0E bit 0 set (each clears it when its flag has left the
; screen at y $C0).
;
; Witness: w1 1, frames 13368-13553 ($A896 129 frames).
ShowAndSlideDown:
  CALL ShowHallOfFame
  LD B,$32
PauseDown:
  HALT
  DJNZ PauseDown
  LD IX,HofTable
  BIT 0,(IX+$0E)
  CALL NZ,BlankScore
  LD IX,HofSlot2
  BIT 0,(IX+$0E)
  CALL NZ,BlankScore
  LD IX,HofSlot3
  BIT 0,(IX+$0E)
  CALL NZ,BlankScore
SlideDownLoop:
  HALT
  LD IX,HofTable
  CALL SlideFlagDown
  LD IX,HofSlot2
  CALL SlideFlagDown
  LD IX,HofSlot3
  CALL SlideFlagDown
  XOR A
  LD IX,HofTable
  OR (IX+$0E)
  LD IX,HofSlot2
  OR (IX+$0E)
  LD IX,HofSlot3
  OR (IX+$0E)
  BIT 0,A
  JR NZ,SlideDownLoop
  RET

; After the insert: slide the flagged flags up to their poles, then print their
; scores
;
; 50 frames' pause, then one pixel a frame SlideFlagUp $A990 on each slot until
; no flag moves. Returns to GameOverHallOfFame's caller. Witness: w1 1, frames
; 13553-13732 ($A8CC 129 frames).
SlideFlagsUp:
  LD B,$32
PauseUp:
  HALT
  DJNZ PauseUp
SlideUpLoop:
  HALT
  LD IX,HofTable
  CALL SlideFlagUp
  LD IX,HofSlot2
  CALL SlideFlagUp
  LD IX,HofSlot3
  CALL SlideFlagUp
  XOR A
  LD IX,HofTable
  OR (IX+$0E)
  LD IX,HofSlot2
  OR (IX+$0E)
  LD IX,HofSlot3
  OR (IX+$0E)
  BIT 0,A
  JR NZ,SlideUpLoop
  RET

; Draw the hall of fame: blue screen, three poles, the flags with their names,
; the scores
;
; Clears the pixels, attributes $0F (white on blue), border 1 (blue). Then a
; frame each: DrawPole $ABC3, DrawFlag $AB7B and PrintScore $AA23 for slots 1,
; 2, 3. Called by ShowAndSlideDown and by the attract sequence ($B906).
;
; Witness: w1 1, frames 13368-13374. The attract call: no recording ran $B906
; (l1sum.py B906) (known only from the code).
ShowHallOfFame:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  INC HL
  INC DE
  LD BC,$02FF
  LD (HL),$0F
  LDIR
  LD A,$01
  OUT ($FE),A
  HALT
  LD IX,HofTable
  CALL DrawPole
  LD IX,HofSlot2
  CALL DrawPole
  LD IX,HofSlot3
  CALL DrawPole
  HALT
  LD IX,HofTable
  CALL DrawFlag
  LD IX,HofSlot2
  CALL DrawFlag
  LD IX,HofSlot3
  CALL DrawFlag
  HALT
  LD IX,HofTable
  CALL PrintScore
  LD IX,HofSlot2
  CALL PrintScore
  LD IX,HofSlot3
  CALL PrintScore
  RET

; Move slot IX's flag one pixel down (if it is flagged and still on the screen)
;
; Returns at once unless +$0E bit 0. At y (+$0A) >= $C0 clears the flag. Else
; XORs the flag's top line off and a line under it on (XorLine $93B3, 48
; pixels), fills the line the name leaves (RestoreFlagLine $AABD, A = 8), moves
; the tail (DrawFlagTail $A9CC at y and y + 1) and draws the name one line
; lower (DrawNameBitmap $AA74).
;
; Witness: w1 387 calls, 216 moves, frames 13425-13553.
SlideFlagDown:
  BIT 0,(IX+$0E)
  RET Z
  LD A,(IX+$0A)
  CP $C0
  JR C,SlideFlagDownMove
  RES 0,(IX+$0E)
  RET
SlideFlagDownMove:
  LD E,(IX+$09)
  LD D,(IX+$0A)
  LD B,$30
  CALL XorLine
  LD A,D
  ADD A,$18
  LD D,A
  CP $C0
  CALL C,XorLine
  LD A,$08
  CALL RestoreFlagLine
  CALL DrawFlagTail
  INC (IX+$0A)
  CALL DrawFlagTail
  JP DrawNameBitmap

; Move slot IX's flag one pixel up until it is back at its pole
;
; Returns unless +$0E bit 0. When y - 2 < the pole's y (+$0C) clears the flag
; and prints the score (PrintScore $AA23, a jump). Else the mirror of
; SlideFlagDown (RestoreFlagLine with A = $0F). Witness: w1 387 calls, 216
; moves, frames 13604-13732.
SlideFlagUp:
  BIT 0,(IX+$0E)
  RET Z
  LD A,(IX+$0A)
  SUB $02
  CP (IX+$0C)
  JR NC,SlideFlagUpMove
  RES 0,(IX+$0E)
  JP PrintScore
SlideFlagUpMove:
  LD E,(IX+$09)
  LD D,(IX+$0A)
  DEC D
  LD B,$30
  CALL XorLine
  LD A,D
  ADD A,$18
  LD D,A
  CP $C0
  CALL C,XorLine
  LD A,$0F
  CALL RestoreFlagLine
  CALL DrawFlagTail
  DEC (IX+$0A)
  CALL DrawFlagTail
  JP DrawNameBitmap

; XOR the flag's ragged tail (FlagTail $AB41, 29 lines) at x + 48 of slot IX's
; flag
;
; From the flag position (+9 x, +$0A y); nothing when y >= $C0. Draws the lines
; of the first character row, then whole rows of 8 (clipped at the screen's
; bottom), through XorTailLines $AA12. Witness: w1 867 calls, frames
; 13372-13731.
DrawFlagTail:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD A,H
  CP $C0
  RET NC
  LD A,L
  ADD A,$30
  LD L,A
  LD DE,FlagTail
  LD C,$1D
  LD B,H
  PUSH HL
  CALL ScreenCell
  LD A,B
  AND $07
  ADD A,H
  LD H,A
  LD A,B
  CPL
  AND $07
  INC A
  LD B,A
  CALL XorTailLines
TailRowLoop:
  POP HL
  LD A,H
  AND $F8
  ADD A,$08
  LD H,A
  CP $C0
  RET NC
  LD A,C
  OR A
  RET Z
  CP $08
  JR C,TailLastRow
  PUSH HL
  CALL ScreenCell
  LD B,$08
  CALL XorTailLines
  JR TailRowLoop
TailLastRow:
  CALL ScreenCell         ; the last part row, then falls into XorTailLines
  LD B,C

; XOR B lines of the tail (2 bytes a line, the right byte first) at HL; C
; counts the lines left
;
; DE: the tail data, HL: the screen. Called by DrawFlagTail and fallen into
; from $AA0E. Witness: w1 3372 entries, 21779 lines.
XorTailLines:
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC HL
  DEC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  DEC HL
  INC H
  INC DE
  INC DE
  DEC C
  DJNZ XorTailLines
  RET

; Print slot IX's score x 10 above its pole: five digits with leading zeros and
; a "0"
;
; At character column x/8 (+$0B) and row y/8 - 1 (+$0C), attribute $0F: $9E13
; with B = $80 (leading zeros printed), then the character "0" through $9E7C.
; The 003000 / 002700 of w1 frame 14000. Witness: w1 5, frames 13374-13732.
PrintScore:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(IX+$0B)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD A,(IX+$0C)
  SRL A
  SRL A
  SRL A
  DEC A
  LD D,A
  LD B,$80
  LD C,$0F
  CALL PrintNumber
  EX DE,HL
  LD A,$30
  JP PrintChar

; Print six spaces over slot IX's score (before its flag slides away)
;
; Patches the row and column of the text record ScoreBlank $AA6A and prints it
; ($9E65). Witness: w1 2 (the two flagged slots), frame 13424.
BlankScore:
  LD A,(IX+$0B)
  SRL A
  SRL A
  SRL A
  LD (ScoreBlank+$0001),A
  LD A,(IX+$0C)
  SRL A
  SRL A
  SRL A
  DEC A
  LD (ScoreBlank),A
  LD HL,ScoreBlank
  JP PrintText

; A text record: row, column (both patched by BlankScore), attribute $0F, 6
; spaces
;
; Read by $9E65 from BlankScore only (w1 20 reads). The text record format: see
; MenuTexts $B464.
ScoreBlank:
  INCBIN "res/text/ScoreBlank.bin",$0000,10

; Copy slot IX's name bitmap (+$0F, 7 bytes x 8 lines) to the flag at (x, y +
; 8)
;
; Clipped at y $C0, split over two character rows when y + 8 is not a multiple
; of 8, through CopyNameLines $AAAF. Reached by a jump from SlideFlagDown,
; SlideFlagUp and DrawFlag. Witness: w1 435, frames 13372-13731.
DrawNameBitmap:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD A,H
  ADD A,$08
  LD H,A
  CP $C0
  RET NC
  PUSH IX
  POP DE
  LD A,E
  ADD A,$0F
  LD E,A
  JR NC,NameBitmapRows
  INC D
NameBitmapRows:
  LD B,H
  PUSH HL
  CALL ScreenCell
  LD A,B
  AND $07
  ADD A,H
  LD H,A
  LD A,B
  CPL
  AND $07
  INC A
  CALL CopyNameLines
  POP HL
  LD B,H
  LD A,H
  AND $F8
  ADD A,$08
  LD H,A
  CP $C0
  RET NC
  CALL ScreenCell
  LD A,B
  AND $07
  RET Z

; Copy A lines of 7 bytes from DE to the screen at HL (down one pixel line
; each)
;
; Witness: w1 1107 entries, 3480 lines (from DrawNameBitmap and
; RestoreFlagLine).
CopyNameLines:
  LD BC,$0007
  PUSH HL
  EX DE,HL
  LDIR
  EX DE,HL
  POP HL
  INC H
  DEC A
  JR NZ,CopyNameLines
  RET

; Copy one solid line (SolidLine $AAD8) at slot IX's flag x, line y + A
;
; A = 8 (sliding down: the line above the name) or $0F (sliding up: the line
; under it). Nothing at y + A >= $C0. Witness: w1 432, frames 13425-13731.
RestoreFlagLine:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  ADD A,H
  LD H,A
  CP $C0
  RET NC
  LD DE,SolidLine
  LD B,H
  CALL ScreenCell
  LD A,B
  AND $07
  ADD A,H
  LD H,A
  LD A,$01
  JR CopyNameLines

; Seven $FF bytes: a solid 56-pixel line of a flag
;
; Read by RestoreFlagLine through CopyNameLines (w1 2688 reads).
SolidLine:
  INCBIN "res/graphics/SolidLine.bin",$0000,7

; Render slot IX's name (+2, 7 characters) into its bitmap (+$0F), inverted
;
; RenderChar $AB04 for each character, into the bitmap with a stride of 7.
; Called by InsertEntry (the three slots) and DrawFlag. Witness: w1 6, frames
; 13372-13553.
RenderName:
  PUSH IX
  POP HL
  LD A,L
  ADD A,$0F
  LD L,A
  JR NC,RenderNameSource
  INC H
RenderNameSource:
  PUSH IX
  POP DE
  LD A,E
  ADD A,$02
  LD E,A
  JR NC,RenderNameLoop
  INC D
RenderNameLoop:
  LD B,$07
RenderNameNext:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,(DE)
  CALL RenderChar
  POP HL
  POP DE
  POP BC
  INC HL
  INC DE
  DJNZ RenderNameNext
  RET

; One character A as 8 inverted bytes, every 7th byte from HL
;
; Digits from Font+$D0 ($DFC4), a-z from Font $DEF4, anything else from
; CHAR_SET $3D00 (space). Same lookup as the print routine $9E7C. Witness: w1
; 42 (6 names x 7), $AB23 (the ROM's glyphs, spaces) 12.
RenderChar:
  PUSH HL
  CP $30
  JR C,RenderCharLetter
  CP $3A
  JR NC,RenderCharLetter
  SUB $30
  LD DE,FontDigits
  JR RenderCharCopy
RenderCharLetter:
  CP $61
  JR C,RenderCharRom
  CP $7B
  JR NC,RenderCharRom
  SUB $61
  LD DE,Font
  JR RenderCharCopy
RenderCharRom:
  SUB $20
  LD DE,CHAR_SET
RenderCharCopy:
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  EX DE,HL
  POP HL
  LD B,$08
RenderCharLoop:
  LD A,(DE)
  CPL
  LD (HL),A
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC DE
  DJNZ RenderCharLoop
  RET

; The flag's ragged tail: 29 lines of 2 bytes (right byte, left byte), XORed at
; x + 48
;
; Read by XorTailLines (w1 43558 reads). Lines 0-4: right $00, left $FF (the
; flag goes on 8 pixels); lines 5-23: left $FF, right $7F $7E $7C $78 $78 $7C
; $7E $7F repeating (the ragged edge, two notches and a part); lines 24-28
; ($AB71-$AB7A): the curled bottom corner below the 24-line field.
FlagTail:
  INCBIN "res/graphics/FlagTail.bin",$0000,58

; Draw slot IX's flag at its pole: attributes, the solid field, the tail, the
; name
;
; Sets the flag position to (x + 8, y + 1) of the pole, renders the name
; (RenderName), fills 9 attribute cells a row with +$0D from the flag's row to
; the bottom of the screen, XORs a 48 x 24 solid field (XorLine $93B3), the
; tail (DrawFlagTail) and the name (DrawNameBitmap). Witness: w1 3, frames
; 13372-13373.
DrawFlag:
  LD A,(IX+$0B)
  ADD A,$08
  LD (IX+$09),A
  LD A,(IX+$0C)
  INC A
  LD (IX+$0A),A
  CALL RenderName
  LD L,(IX+$09)
  LD H,(IX+$0A)
FlagAttrRows:
  PUSH HL
  CALL ScreenCell
  CALL AttrOfScreen
  LD B,$09
FlagAttrCells:
  LD A,(IX+$0D)
  LD (HL),A
  INC HL
  DJNZ FlagAttrCells
  POP HL
  LD A,H
  ADD A,$08
  LD H,A
  CP $C0
  JR C,FlagAttrRows
  LD B,$30
  LD C,$18
  LD E,(IX+$09)
  LD D,(IX+$0A)
FlagFieldLines:
  CALL XorLine
  INC D
  DEC C
  JR NZ,FlagFieldLines
  CALL DrawFlagTail
  JP DrawNameBitmap

; Draw slot IX's pole from (x, y) to the bottom of the screen
;
; At the pole's top line + 7: the cap ($FF $E0, 11 pixels) with attribute $0F
; on its two cells; then each character row down to the bottom: attribute $0F
; and 8 lines of $1F (a 5-pixel pole). Witness: w1 3, frame 13371.
DrawPole:
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  PUSH HL
  CALL ScreenCell
  LD A,H
  ADD A,$07
  LD H,A
  LD (HL),$FF
  INC HL
  LD (HL),$E0
  DEC HL
  CALL AttrOfScreen
  LD (HL),$0F
  INC HL
  LD (HL),$0F
  POP HL
  INC H
PoleRows:
  PUSH HL
  CALL ScreenCell
  PUSH HL
  CALL AttrOfScreen
  LD (HL),$0F
  POP HL
  LD B,$08
PoleLines:
  LD (HL),$1F
  INC H
  DJNZ PoleLines
  POP HL
  LD A,H
  ADD A,$08
  LD H,A
  CP $C0
  JR C,PoleRows
  RET

; HL = the attribute address of the screen address HL (H's character row)
;
; Witness: w1 99, frames 13371-13373 (DrawPole, DrawFlag).
AttrOfScreen:
  SRL H
  SRL H
  SRL H
  SET 6,H
  SET 4,H
  RET

; The hall of fame: 3 slots of 71 bytes; slot 1 centre top (james 300), slot 2
; left (francis 200), slot 3 right (bill 100)
;
; Read by CountBeaten (the scores: game and f1 read only slot 3's score),
; InsertEntry, ShowHallOfFame and the slide routines; written by InsertEntry,
; RenderName (the bitmaps) and the slide routines (+9/+$0A, +$0E). In the
; image: +0/+1 score, +2..+8 the name (padded with spaces), +9/+$0A the flag's
; x / y (set by DrawFlag), +$0B/+$0C the pole's x / y in pixels, +$0D the
; flag's attribute, +$0E bit 0 = the flag moves, +$0F..+$46 the name bitmap (56
; bytes, rendered at the first draw).
;
; w1 wrote "vp" with 270 into slot 2 (screen w1 frame 14000: james 003000
; centre, vp 002700 left, francis 002000 right).
HofTable:
  INCBIN "res/text/HofTable.bin",$0000,71
HofSlot2:
  INCBIN "res/text/HofTable.bin",$0047,71
HofSlot3:
  INCBIN "res/text/HofTable.bin",$008E,71

; The new entries: player 1's score and name, then player 2's (9 bytes each,
; the format of a slot's first 9)
;
; Written by GameOverHallOfFame (the score from $9F45 / $9F47, the name from
; NameBuffer $B227), read by InsertEntry. w1 wrote and read NewEntry1 (11
; reads); NewEntry2 is read and written only on the two-player path, which no
; recording ran.
NewEntry1:
  DEFB $00,$00
NewEntryName1:
  DEFB $00,$00,$00,$00,$00,$00,$00 ; player 1's name
NewEntry2:
  DEFB $00,$00            ; player 2's score
NewEntryName2:
  DEFB $00,$00,$00,$00,$00,$00,$00 ; player 2's name
