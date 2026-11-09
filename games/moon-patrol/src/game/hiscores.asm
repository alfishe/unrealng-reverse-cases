; --------------------------------------------------------------------------------------------------------------------
; hiscores.asm: The hi-score tables, their page, the hi-score entry after GAME OVER
;
; Two tables. The heroes: ten records of three initials and a four-byte BCD score at $8866. The all-time heroes:
; number 1, THE GREATEST, with a 20-letter name, a score, initials and the course point reached ($88AC-$88C8), then 39
; records like the heroes' ($88C9-$89D9): 40 places. $88AC-$89D9 ($12E bytes) is the block the tape code saves, loads
; and verifies (MenuCheckTape); the heroes are not saved.
;
; HiScoreEntry $8B8F, called at GAME OVER by $8F9F, checks the score $B272 against the last all-time and the last hero
; score, asks for the initials (EntryFieldEdit, three letters into $B289) and puts the record into both tables where
; it fits. A score over THE GREATEST's goes to GreatestEntry $8E4E, which asks for a name of up to 20 letters typed
; over the old one, then the initials.
;
; Scores are four BCD bytes, the highest first, compared byte by byte by ScoreCompare. Texts are print strings of
; $FFD0 (codes in the notes).
; --------------------------------------------------------------------------------------------------------------------

; The heroes: ten records of three initials and a four-byte BCD score, best
; first (MIK 1200 ... PJS 120 in the image)
;
; Drawn by HeroesDrawTables; the tenth score $88A8 is HiScoreEntry's threshold,
; and records shift down from the insert place (HeroesInsert). Not part of the
; tape block. h1 put MPA (score 1260) at the top.
HeroesTable:
  DEFB $4D,$49,$4B,$00,$00,$12,$00
  DEFB $50,$41,$48,$00,$00,$10,$80
  DEFB $4A,$43,$47,$00,$00,$09,$60
  DEFB $44,$45,$56,$00,$00,$08,$40
  DEFB $50,$41,$43,$00,$00,$07,$20
  DEFB $48,$4A,$53,$00,$00,$06,$00
  DEFB $4D,$47,$53,$00,$00,$04,$80
  DEFB $52,$56,$53,$00,$00,$03,$60
  DEFB $41,$4D,$53,$00,$00,$02,$40
  DEFB $50,$4A,$53,$00,$00,$01,$20

; THE GREATEST's course point (1-25, A-Z without O): $18 = Y. The first byte of
; the tape block $88AC-$89D9
;
; Written by GreatestEntry from $B27C; the HUD prints it after the hi-score
; ($91DD with $9258). Read in every build that drew the HUD (i1 12 reads).
GreatestPoint:
  DEFB $18

; THE GREATEST's name, 20 letters (SPIKE NOTWELL), ended by $1F for $FFD0
;
; Printed by HeroesDrawTables; GreatestEntry edits it in place (h2 typed STAGE
; ONE over SPIKE NOTWELL: the untyped tail stays, "STAGE ONEWELL").
GreatestName:
  DEFM "SPIKE NOTWELL       ",$1F

; THE GREATEST's score, BCD (00 05 00 00 = 50000): the hi-score of the HUD
;
; Read by the HUD ($91DD), HeroesDrawTables and HiScoreEntry (the GreatestEntry
; test). i1 24 reads.
GreatestScore:
  DEFB $00,$05,$00,$00

; THE GREATEST's initials (JAS)
GreatestInitials:
  DEFM "JAS"

; The all-time heroes 2-40: 39 records of initials and BCD score, best first;
; the last score $89D6 is HiScoreEntry's first threshold
;
; h1 put MPA at 40 (the last record, $89D3). GreatestEntry shifts the whole
; table down and makes the old greatest number 2.
AllTimeTable:
  DEFB $42,$49,$4C,$00,$04,$87,$50
  DEFB $4D,$54,$57,$00,$04,$75,$00
  DEFB $4D,$43,$46,$00,$04,$62,$50
  DEFB $4D,$42,$52,$00,$04,$50,$00
  DEFB $52,$4D,$50,$00,$04,$37,$50
  DEFB $49,$4D,$43,$00,$04,$25,$00
  DEFB $4E,$43,$53,$00,$04,$12,$50
  DEFB $52,$4C,$50,$00,$04,$00,$00
  DEFB $48,$44,$50,$00,$03,$87,$50
  DEFB $4A,$47,$50,$00,$03,$75,$00
  DEFB $53,$4D,$4C,$00,$03,$62,$50
  DEFB $53,$4B,$47,$00,$03,$50,$00
  DEFB $48,$4B,$57,$00,$03,$37,$50
  DEFB $53,$49,$44,$00,$03,$25,$00
  DEFB $4C,$49,$5A,$00,$03,$12,$50
  DEFB $44,$43,$4A,$00,$03,$00,$00
  DEFB $43,$45,$4A,$00,$02,$87,$50
  DEFB $4D,$4C,$4A,$00,$02,$75,$00
  DEFB $52,$4F,$57,$00,$02,$62,$50
  DEFB $4A,$52,$53,$00,$02,$50,$00
  DEFB $44,$47,$4C,$00,$02,$37,$50
  DEFB $41,$4D,$50,$00,$02,$25,$00
  DEFB $59,$41,$4B,$00,$02,$12,$50
  DEFB $44,$57,$50,$00,$02,$00,$00
  DEFB $44,$52,$44,$00,$01,$87,$50
  DEFB $46,$47,$54,$00,$01,$75,$00
  DEFB $53,$49,$53,$00,$01,$62,$50
  DEFB $45,$4E,$45,$00,$01,$50,$00
  DEFB $47,$44,$59,$00,$01,$37,$50
  DEFB $4F,$4C,$46,$00,$01,$25,$00
  DEFB $4C,$4C,$45,$00,$01,$12,$50
  DEFB $57,$4B,$43,$00,$01,$00,$00
  DEFB $4F,$54,$53,$00,$00,$87,$50
  DEFB $4A,$4A,$45,$00,$00,$75,$00
  DEFB $4B,$49,$4D,$00,$00,$62,$50
  DEFB $59,$42,$4E,$00,$00,$50,$00
  DEFB $45,$54,$54,$00,$00,$37,$50
  DEFB $49,$52,$57,$00,$00,$25,$00
  DEFB $48,$4F,$4B,$00,$00,$12,$50

; "MOON PATROL HEROES"
;
; Printed by HeroesDrawTables $8AE0 (a1 2, h1 1, game 4).
HeroesTitleText:
  INCBIN "res/text/HeroesTitleText.bin",$0000,36

; "ALL TIME HEROES" and "1) " for THE GREATEST
AllTimeTitleText:
  INCBIN "res/text/AllTimeTitleText.bin",$0000,33

; "L=LOAD, J=SAVE, G=VERIFY HI-SCORES." at the foot of the page
HeroesTapeKeysText:
  INCBIN "res/text/HeroesTapeKeysText.bin",$0000,45

; One heroes line: rank ($B256), ")", the initials and the six-digit score at x
; D, row E; HL to the next record, E + 8
;
; The rank through $9369 (B = 1, C = 6), the score through $9367 (C = 6).
; Witness: a1 20 calls, h1 10.
HeroesPrintRow:
  LD B,$01
  LD C,$06
  PUSH HL
  PUSH DE
  LD HL,TableRow
  CALL PrintBcd
  POP DE
  POP HL
  LD A,$16
  CALL PrintChar
  LD A,D
  ADD A,$0C
  CALL PrintChar
  LD A,E
  CALL PrintChar
  LD A,$29
  CALL PrintChar
  LD A,$16
  CALL PrintChar
  LD A,D
  ADD A,$13
  CALL PrintChar
  LD A,E
  CALL PrintChar
  LD B,$03
HeroesInitialsLoop:
  LD A,(HL)
  INC HL
  CALL PrintChar
  DJNZ HeroesInitialsLoop
  PUSH DE
  LD A,$2D
  ADD A,D
  LD D,A
  LD C,$06
  CALL PrintBcd4
  POP DE
  LD A,$08
  ADD A,E
  LD E,A
  RET

; One all-time line in the small font: rank, ")", initials, score at x D, row
; E; E + 6
;
; As HeroesPrintRow with narrower spacing and C = 4 for the print calls.
; Witness: a1 78 calls, h1 39.
AllTimePrintRow:
  LD B,$01
  LD C,$04
  PUSH HL
  PUSH DE
  LD HL,TableRow
  CALL PrintBcd
  POP DE
  POP HL
  LD A,$16
  CALL PrintChar
  LD A,D
  ADD A,$08
  CALL PrintChar
  LD A,E
  CALL PrintChar
  LD A,$29
  CALL PrintChar
  LD A,$16
  CALL PrintChar
  LD A,D
  ADD A,$0D
  CALL PrintChar
  LD A,E
  CALL PrintChar
  LD B,$03
AllTimeInitialsLoop:
  LD A,(HL)
  INC HL
  CALL PrintChar
  DJNZ AllTimeInitialsLoop
  PUSH DE
  LD A,$1F
  ADD A,D
  LD D,A
  LD C,$04
  CALL PrintBcd4
  POP DE
  LD A,$06
  ADD A,E
  LD E,A
  RET

; The hi-score page's tables: heroes 1-5 and 6-10 in two columns, THE GREATEST,
; all-time 2-40 in three columns
;
; HeroesTitleText; ranks 1-5 at x $1A and 6-10 at x $89 from row $1C (rank 10
; as BCD $10); AllTimeTitleText, then THE GREATEST: GreatestName, its score six
; columns after the cursor, "(" its initials ")"; font 0, then the all-time
; ranks 2-$14 at x $14, $15-$27 at x $5E, $28-$40 at x $AA from row $59 (BCD
; counters); HeroesTapeKeysText; CycleFrameColours.
;
; Called by HeroesPage only. Witness: game 4, a1 2 (174, 21 208), h1 1 (4545).
HeroesDrawTables:
  LD HL,HeroesTitleText
  CALL PrintText
  LD A,$01
  LD D,$1A
  LD E,$1C
  LD HL,HeroesTable
HeroesLeftColumn:
  LD (TableRow),A         ; ranks 1-5
  PUSH AF
  CALL HeroesPrintRow
  POP AF
  INC A
  CP $06
  JR NZ,HeroesLeftColumn
  LD D,$89                ; ranks 6-10 at x $89
  LD E,$1C
HeroesRightColumn:
  PUSH AF
  CP $0A
  JR NZ,HeroesRankSet
  LD A,$10
HeroesRankSet:
  LD (TableRow),A         ; rank 10 printed as BCD $10
  CALL HeroesPrintRow
  POP AF
  INC A
  CP $0B
  JR NZ,HeroesRightColumn
  LD HL,AllTimeTitleText  ; THE GREATEST
  CALL PrintText
  LD HL,GreatestName
  CALL PrintText
  INC HL
  LD DE,(PrintY)
  LD A,D
  ADD A,$06
  LD D,A
  LD C,$06
  CALL PrintBcd4
  LD A,$28
  CALL PrintChar
  LD B,$03
GreatestInitialsLoop:
  LD A,(HL)
  INC HL
  CALL PrintChar
  DJNZ GreatestInitialsLoop
  LD A,$29
  CALL PrintChar
  LD A,$1A                ; font 0 for the all-time ranks
  CALL PrintChar
  LD A,$00
  CALL PrintChar
  LD A,$02
  LD D,$14
  LD E,$59
AllTimeColumn1:
  LD (TableRow),A         ; ranks 2-14
  PUSH AF
  CALL AllTimePrintRow
  POP AF
  ADD A,$01
  DAA
  CP $15
  JR NZ,AllTimeColumn1
  LD D,$5E
  LD E,$59
AllTimeColumn2:
  LD (TableRow),A         ; ranks 15-27
  PUSH AF
  CALL AllTimePrintRow
  POP AF
  ADD A,$01
  DAA
  CP $28
  JR NZ,AllTimeColumn2
  LD D,$AA
  LD E,$59
AllTimeColumn3:
  LD (TableRow),A         ; ranks 28-40
  PUSH AF
  CALL AllTimePrintRow
  POP AF
  ADD A,$01
  DAA
  CP $41
  JR NZ,AllTimeColumn3
  LD HL,HeroesTapeKeysText
  CALL PrintText
  CALL CycleFrameColours
  RET

; GAME OVER: a score for the tables asks for the initials (or THE GREATEST's
; name) and goes into the all-time and heroes tables
;
; Called by the game over $8F9F with the player's score at $B272 and the player
; number at $B271. A score not over the last all-time score $89D6 and not over
; the tenth hero $88A8 returns at once. Otherwise: the screen cleared, the
; frame, $93C5 and $9136, "CONGRATULATIONS PLAYER n"; a score over THE
; GREATEST's goes to GreatestEntry $8E4E. Else "YOU ARE AN ATARI MP HERO,
; PLEASE ENTER YOUR INITIALS", "3 LETTERS MAXIMUM" (the digit printed before
; the tail of "20 LETTERS MAXIMUM"), EntryFieldEdit with InitialsField (three
; letters into $B289).
;
; Then the all-time table: a score over $89D6 is placed by HiScoreFindSlot (39
; records), the records below shift down 7 bytes (LDDR), the initials and score
; go in. Then HeroesInsert does the same for the heroes (ten records). Equal
; scores do not enter: the older record stays above.
;
; Witness: entries game 4, g1 1 (4144), p2 1 (7830), h1 1 (4144-4524), h2 1
; (488). The prompt: game, g1, p2, h1 ($8BE0); g1 and p2 never finished the
; initials (the scripts typed play keys, no ENTER); h1 did: all-time ($8C1D,
; place 40) and heroes ($8C58, place 1). game (c1's random play) entered once
; and only the heroes.
HiScoreEntry:
  LD HL,PlayerScore
  LD DE,AllTimeTable+$010D
  CALL ScoreCompare
  JR C,HiScoreQualifies
  LD HL,PlayerScore       ; not in the all-time table: is it in the heroes?
  LD DE,HeroesTable+$0042
  CALL ScoreCompare
  RET NC
  RET Z
HiScoreQualifies:
  XOR A                   ; the congratulations page
  CALL ClearScreen
  CALL DrawPixelFrame
  CALL CycleFrameColours
  LD C,$60
  LD HL,Screen
  CALL ClearCells
  CALL HudDraw
  LD A,(Attributes+128)            ; the colour of row 3 copied to row 2
  LD (Attributes+96),A
  LD HL,CongratulationsText
  CALL PrintText
  LD A,(Player)
  ADD A,$30
  CALL PrintChar
  LD HL,HiScoreTexts
  CALL PrintText
  LD HL,PlayerScore       ; over THE GREATEST: the name entry
  LD DE,GreatestScore
  CALL ScoreCompare
  JP C,GreatestEntry
  LD HL,YouAreAtText      ; a hero: YOU ARE AN ATARI MP HERO
  CALL PrintText
  LD HL,AnAtariHeroText
  CALL PrintText
  LD HL,InitialsText
  CALL PrintText
  LD HL,LettersAtText
  CALL PrintText
  LD A,$33                ; "3" before " LETTERS MAXIMUM"
  CALL PrintChar
  LD HL,LettersMaximumText
  CALL PrintText
  LD HL,InitialsField     ; the initials field
  LD DE,EntryLength
  LD BC,$0005
  LDIR
  CALL EntryFieldEdit
  LD HL,AllTimeTable+$010D ; not over the last all-time score: only the heroes
  LD DE,PlayerScore
  CALL ScoreCompare
  JP C,HeroesInsert
  JP Z,HeroesInsert
  LD HL,AllTimeTable+$010D ; the all-time place, the rest shifted down
  LD DE,PlayerScore
  LD B,$27
  CALL HiScoreFindSlot
  DEC HL
  DEC HL
  DEC HL
  LD (HeroSlot),HL
  LD DE,AllTimeTable+$010A
  EX DE,HL
  AND A
  SBC HL,DE
  JR Z,AllTimeStoreEntry
  LD B,H
  LD C,L
  LD HL,AllTimeTable+$0109
  LD DE,AllTimeTable+$0110
  LDDR
AllTimeStoreEntry:
  LD DE,(HeroSlot)        ; the initials and the score into the place
  LD HL,PlayerInitials
  LD BC,$0003
  LDIR
  LD HL,PlayerScore
  LD BC,$0004
  LDIR
; This entry point is used by the routine at GreatestEntry.
HeroesInsert:
  LD HL,HeroesTable+$0042 ; the heroes: not over the tenth score returns
  LD DE,PlayerScore
  CALL ScoreCompare
  RET C
  RET Z
  LD HL,HeroesTable+$0042 ; the heroes place, the rest shifted down
  LD DE,PlayerScore
  LD B,$0A
  CALL HiScoreFindSlot
  DEC HL
  DEC HL
  DEC HL
  LD (HeroSlot),HL
  LD DE,HeroesTable+$003F
  EX DE,HL
  AND A
  SBC HL,DE
  JR Z,HeroesStoreEntry
  LD B,H
  LD C,L
  LD HL,HeroesTable+$003E
  LD DE,HeroesTable+$0045
  LDDR
HeroesStoreEntry:
  LD DE,(HeroSlot)        ; the initials and the score into the place
  LD HL,PlayerInitials
  LD BC,$0003
  LDIR
  LD HL,PlayerScore
  LD BC,$0004
  LDIR
  RET

; Clears ten pixel lines of 28 bytes from the field's row ($B24E)
;
; Witness: g1 121 calls, h2 11.
EntryFieldClear:
  LD A,(EntryY)
  LD C,$0A
EntryClearLine:
  PUSH AF
  LD H,$7E
  LD L,A
  SLA L
  RL H
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  XOR A
  INC HL
  INC HL
  LD B,$1C
EntryClearBytes:
  LD (HL),A
  INC HL
  DJNZ EntryClearBytes
  POP AF
  INC A
  DEC C
  JR NZ,EntryClearLine
  RET

; Draws the field: cleared, AT x, y, its characters, a five-pixel line under
; the one at the cursor $B254
;
; The field descriptor is at $B24B: length, the buffer address, y, x
; (EntryFieldDescriptors). $B252 counts the characters left, $B253 the index.
; Witness: g1 121 calls, p2 615, h2 11.
EntryFieldDraw:
  CALL EntryFieldClear
  LD A,$16
  CALL PrintChar
  LD A,(EntryX)
  CALL PrintChar
  LD A,(EntryY)
  CALL PrintChar
  LD A,(EntryLength)
  LD HL,HeroCount
  LD (HL),A
  INC HL
  LD (HL),$00
  LD HL,(EntryBuffer)
EntryFieldCharLoop:
  PUSH HL
  LD A,(HeroIndex)
  LD HL,EntryCursor
  CP (HL)
  JR NZ,EntryFieldPrintChar
  LD HL,(PrintY)          ; the cursor's character: a line 8 rows under the
                          ; print position
  LD A,$08
  ADD A,L
  LD L,A
  LD B,$05
  INC H
EntryCursorLoop:
  PUSH BC
  PUSH HL
  CALL PlotPixel
  POP HL
  POP BC
  INC H
  DJNZ EntryCursorLoop
EntryFieldPrintChar:
  POP HL
  LD A,(HL)
  PUSH HL
  CALL PrintChar
  POP DE
  INC DE
  LD HL,HeroIndex
  INC (HL)
  DEC HL
  DEC (HL)
  EX DE,HL
  JR NZ,EntryFieldCharLoop
  RET

; Edits the field at $B24B with the ROM's LAST_K: characters, cursor left /
; right, DELETE; ENTER ends
;
; Cursor 0, FLAGS bit 3 and FLAGS2 bit 3 (CAPS LOCK: capitals) set, MODE 0.
; Draws the field, clears LAST_K and waits for the IM 1 handler to put a key
; there. ENTER returns. $20-$5E: stored at the cursor, cursor right (stops at
; the last place). 8 (cursor left): EditCursorLeft; 9 (cursor right):
; EditCursorRight; 12 (DELETE): EditDelete. Other codes are ignored. Typing
; over a longer old text leaves its tail (h2).
;
; Witness: entries g1 1 (4172, never left: no ENTER), p2 1 (7859, never left),
; h1 1 (4172-4524), h2 2 (517-1141 the name, then the initials, not finished),
; game 1. Characters typed: g1 120, p2 614, h1 3, h2 9. The keys 8, 9 and 12
; never came ($8D5D, $8D7C and the direct jump to $8D6B never ran in any
; recording: known only from the code).
EntryFieldEdit:
  XOR A
  LD (EntryCursor),A
  LD HL,FLAGS
  SET 3,(HL)
  LD HL,FLAGS2
  SET 3,(HL)
  LD HL,MODE
  LD (HL),$00
; This entry point is used by the routine at EditCursorLeft.
EditRedraw:
  CALL EntryFieldDraw
EditWaitKey:
  LD HL,LAST_K             ; LAST_K = 0, wait for a key
  XOR A
  LD (HL),A
EditWaitLoop:
  CP (HL)
  JR Z,EditWaitLoop
  LD A,(HL)
  CP $0D
  RET Z
  CP $08
  JP Z,EditCursorLeft
  CP $09
  JP Z,EditCursorRight
  CP $0C
  JP Z,EditDelete
  CP $20
  JR C,EditWaitKey
  CP $5F
  JR NC,EditWaitKey
  LD D,A                  ; a character into the buffer, cursor right
  CALL EditCursorAddress
  LD (HL),D
  JP EditCursorRight

; Entry field descriptor (length, buffer, y, x): 3 letters into $B289 at y $7C,
; x $77
;
; Copied to $B24B before EntryFieldEdit by HiScoreEntry $8C03 (read in game,
; g1, p2, h1). The three descriptors InitialsField, GreatestNameField,
; GreatestInitialsField have one layout: length, the buffer address, y, x.
InitialsField:
  DEFB $03,$89,$B2,$7C,$77

; Entry field descriptor: THE GREATEST's 20 letters at $88AD, y $7C, x $44
;
; Used by GreatestEntry $8E96 (h2).
GreatestNameField:
  DEFB $14,$AD,$88,$7C,$44

; Entry field descriptor: the initials after the name, 3 letters into $B289 at
; y $A0, x $77
;
; Used by GreatestEntry $8EB6 (h2).
GreatestInitialsField:
  DEFB $03,$89,$B2,$A0,$77

; Cursor left (key 8, and after a DELETE), not below 0, then EntryFieldEdit's
; redraw
;
; Not executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known
; only from the code. The labels below are EntryFieldEdit's other key paths.
EditCursorLeft:
  LD A,(EntryCursor)
  AND A
  JP Z,EditRedraw
  DEC A
  LD (EntryCursor),A
  JP EditRedraw
; This entry point is used by the routine at EntryFieldEdit.
EditCursorRight:
  LD A,(EntryCursor)      ; cursor right, not past the last place (after every
                          ; character; key 9 never came)
  INC A
  LD HL,EntryLength
  CP (HL)
  JP Z,EditRedraw
  LD (EntryCursor),A
  JP EditRedraw
; This entry point is used by the routine at EntryFieldEdit.
EditDelete:
  LD A,(EntryCursor)      ; DELETE: the characters after the cursor move left
                          ; one, a space at the end, then cursor left (never
                          ; ran)
  LD B,$00
  LD C,A
  LD HL,(EntryBuffer)
  ADD HL,BC
  EX DE,HL
  LD HL,(EntryBuffer)
  LD A,(EntryLength)
  LD B,$00
  LD C,A
  ADD HL,BC
  DEC HL
  PUSH HL
  AND A
  SBC HL,DE
  LD A,H
  OR L
  JR Z,EditDeleteTail
  LD B,H
  LD C,L
  LD H,D
  LD L,E
  INC HL
  LDIR
EditDeleteTail:
  POP HL
  LD (HL),$20
  JR EditCursorLeft

; HL = the field's buffer + the cursor $B254
;
; Witness: g1 120 calls, p2 614, h2 9.
EditCursorAddress:
  LD A,(EntryCursor)
  LD C,A
  LD B,$00
  LD HL,(EntryBuffer)
  ADD HL,BC
  RET

; The texts of the hi-score entry, printed in pieces; first INK 6 BRIGHT 1,
; printed after the player number
;
; All printed by HiScoreEntry and GreatestEntry with $FFD0; the pieces are
; reused ("3" + the tail of "20 LETTERS MAXIMUM", "YOU ARE " without its AT for
; THE GREATEST, "PLEASE ENTER YOUR " again after the name).
;
; CongratulationsText $8DB6: "CONGRATULATIONS PLAYER " (the player digit
; follows)
;
; YouAreText $8DDE: "YOU ARE " without the AT (THE GREATEST)
;
; AnAtariHeroText $8DF4: "AN ATARI MP HERO", AT, "PLEASE ENTER YOUR "
;
; AtariHeroText $8DF6: " ATARI MP HERO" and the rest (after THE GREATEST)
;
; PleaseEnterText $8E07: "PLEASE ENTER YOUR " without the AT (after the name)
;
; LettersAtText $8E27: AT, INK 5 for the letters line
;
; LettersMaximumText $8E2F: " LETTERS MAXIMUM" (after a "3")
;
; GreatestAtText $8E40: AT for "YOU ARE THE GREATEST"
;
; InitialsAtText $8E44: AT for the initials prompt after the name
HiScoreTexts:
  INCBIN "res/text/HiScoreTexts.bin",$0000,5
CongratulationsText:
  INCBIN "res/text/HiScoreTexts.bin",$0005,37
YouAreAtText:
  INCBIN "res/text/HiScoreTexts.bin",$002A,3
YouAreText:
  INCBIN "res/text/HiScoreTexts.bin",$002D,9
TheGreatestText:
  INCBIN "res/text/HiScoreTexts.bin",$0036,13
AnAtariHeroText:
  INCBIN "res/text/HiScoreTexts.bin",$0043,2
AtariHeroText:
  INCBIN "res/text/HiScoreTexts.bin",$0045,17
PleaseEnterText:
  INCBIN "res/text/HiScoreTexts.bin",$0056,19
InitialsText:
  INCBIN "res/text/HiScoreTexts.bin",$0069,9
NameText:
  INCBIN "res/text/HiScoreTexts.bin",$0072,4
LettersAtText:
  INCBIN "res/text/HiScoreTexts.bin",$0076,6
TwentyLettersText:
  INCBIN "res/text/HiScoreTexts.bin",$007C,2
LettersMaximumText:
  INCBIN "res/text/HiScoreTexts.bin",$007E,17
GreatestAtText:
  INCBIN "res/text/HiScoreTexts.bin",$008F,4
InitialsAtText:
  INCBIN "res/text/HiScoreTexts.bin",$0093,10
                          ; here)

; A score over THE GREATEST's: the name (20 letters, over the old one), the
; initials, the all-time table shifted down
;
; Jumped to from HiScoreEntry ($8BDD). Prints "YOU ARE THE GREATEST ATARI MP
; HERO, PLEASE ENTER YOUR NAME, 20 LETTERS MAXIMUM". The all-time records 2-39
; shift down one place (the 40th is lost) and the old greatest's initials and
; score become number 2; its name is not kept: GreatestNameField edits
; GreatestName in place. Then "PLEASE ENTER YOUR INITIALS"
; (GreatestInitialsField into $B289); the score, the initials and the course
; point $B27C go to GreatestScore, GreatestInitials and GreatestPoint, and
; HeroesInsert puts the record into the heroes too.
;
; Witness: h2 once (513-1141); the shift and the name ran ($8E81 266 bytes
; moved), the initials prompt was reached (the second EntryFieldEdit) but not
; finished, so $8EC4-$8EE0 never ran in any recording (game, a1, g1, t1, p2,
; h1, i1, i2, h2): known only from the code.
GreatestEntry:
  LD HL,GreatestAtText
  CALL PrintText
  LD HL,YouAreText
  CALL PrintText
  LD HL,TheGreatestText
  CALL PrintText
  LD HL,AtariHeroText
  CALL PrintText
  LD HL,NameText
  CALL PrintText
  LD HL,LettersAtText
  CALL PrintText
  LD HL,TwentyLettersText
  CALL PrintText
  LD HL,AllTimeTable+$0109 ; all-time 2-39 down one place
  LD DE,AllTimeTable+$0110
  LD BC,$010A
  LDDR
  LD DE,AllTimeTable      ; the old greatest becomes number 2
  LD HL,GreatestInitials
  LD BC,$0003
  LDIR
  LD HL,GreatestScore
  LD BC,$0004
  LDIR
  LD HL,GreatestNameField ; the name, in place
  LD DE,EntryLength
  LD BC,$0005
  LDIR
  CALL EntryFieldEdit
  LD HL,InitialsAtText    ; then the initials
  CALL PrintText
  LD HL,PleaseEnterText
  CALL PrintText
  LD HL,InitialsText
  CALL PrintText
  LD HL,GreatestInitialsField
  LD DE,EntryLength
  LD BC,$0005
  LDIR
  CALL EntryFieldEdit
  LD HL,PlayerScore       ; the new greatest: score, initials, course point
  LD DE,GreatestScore
  LD BC,$0004
  LDIR
  LD HL,PlayerInitials
  LD DE,GreatestInitials
  LD BC,$0003
  LDIR
  LD A,(PlayerPoint)
  LD (GreatestPoint),A
  JP HeroesInsert

; Walks a table up from its last score HL for B records while the score DE is
; not less: HL = the score field of the new record's place
;
; Each step ScoreCompare; a record with a higher score stops the walk and the
; place is the one below it (HL + 7); $B250 / $B252 keep HL and DE. Witness:
; game 1, h1 2 (4524: all-time, then heroes).
HiScoreFindSlot:
  LD (HeroCount),DE
  LD (HeroSlot),HL
FindSlotLoop:
  PUSH BC
  CALL ScoreCompare
  POP BC
  LD HL,(HeroSlot)
  JR C,FindSlotDone
  LD DE,-$0007            ; one record up
  ADD HL,DE
  LD (HeroSlot),HL
  LD DE,(HeroCount)
  DJNZ FindSlotLoop
FindSlotDone:
  LD DE,$0007             ; the place below the higher record
  ADD HL,DE
  RET

; Compares the four BCD bytes at DE with those at HL, highest first: carry if
; (DE) < (HL), Z if equal
;
; Witness: game 16 calls, g1 2, p2 3, h1 16, h2 2.
ScoreCompare:
  LD B,$04
ScoreCompareLoop:
  LD A,(DE)
  CP (HL)
  RET NZ
  INC HL
  INC DE
  DJNZ ScoreCompareLoop
  RET
