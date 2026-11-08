; --------------------------------------------------------------------------------------------------------------------
; gameover.asm: GAME OVER and the Hall of Fame name entry
; --------------------------------------------------------------------------------------------------------------------

; GAME OVER: the text and tune, a pause, the Hall of Fame test, then a key or a
; timeout restarts
;
; Reached by the JP Z at $9D38 when the last life is lost. Prints GameOverText
; (a bright red-on-cyan band, rows 10-12 from column 10), plays the tune $7D68
; through $7D17, waits two DelayBC of 65 536 rounds (the delay copies BC bytes
; from $0000 to $0000: 65 536 x 21 T = 1 376 256 T, about 20 frames or 0.4 s
; each), then HallOfFameInsert: a score that enters the table asks for the
; name, and that path never comes back (it jumps to the entry). Else WaitNoKey,
; and up to 20 000 rounds of ReadKey: any key, or the count's end, jumps to the
; entry $6D60 (the menu). c1: 3 game overs, c128: 1, x1, m1, h1: 1 each.
GameOver:
  LD HL,GameOverText
  CALL PrintString
  LD HL,JingleTune
  CALL PlayTune
  LD BC,$0000
  CALL Delay
  CALL Delay
  CALL HallOfFameInsert
  CALL WaitNoKey
  LD BC,$4E20
GameOverWait:
  CALL ReadKey            ; any key: the menu at once
  OR A
  JP NZ,Start
  DEC BC
  LD A,B
  OR C
  JR NZ,GameOverWait
  JP Start

; GAME OVER: at 9,10, font $D7E0, attribute $56, a row of 11 spaces, " GAME
; OVER ", 11 spaces
;
; The print codes of PrintString $AF2B: $DF row col, $E6 the font, $E0 the
; attribute, $E4 n c (n times c), $90-$CE a new line at the column + (code -
; $AF), $FF the end. Rows 9-11, columns 10-20.
GameOverText:
  DEFM $DF,$09,$0A,$E6,$E0,$D7,$E0,"V",$E4,$0B," ",$A4," GAME OVER ",$A4,$E4,$0B," ",$FF

; Finds the place of the score in the 50-entry Hall of Fame; when it enters,
; makes room and asks for the name
;
; The table $71F1: 50 entries of 16 bytes (the name in 10, of which the entry
; writes 8; the score in 6 ASCII digits at +10), $FF at $7511. From the top
; entry: the score $AD8A is compared digit by digit with the entry's
; (HofDigitLoop); a smaller entry digit means the score is higher: HofMakeRoom;
; a larger one, the next entry (HofNextEntry); six equal digits also go on (an
; equal score goes under). The end of the table: RET (the score does not
; enter).
;
; c1 (3 game overs, scores below 1000): 153 entries of HofEntryLoop = 3 x 51
; (50 entries and the end). h1 (the score set to 9000): the first entry
; (RAFFAELE 001000) is lower: the name entry ran.
HallOfFameInsert:
  LD HL,TuneSetMaxVolumes
  LD IX,HallOfFame

; One Hall of Fame entry: IX = the entry, kept on the stack; bit 7 of its first
; byte: the end
;
; Used by the routine at HofNextEntry.
HofEntryLoop:
  BIT 7,(IX+$00)
  RET NZ
  PUSH IX
  LD DE,$000A             ; IX = the entry's score digits
  ADD IX,DE
  LD HL,Score
  LD B,$06

; Compares one score digit with the entry's: equal goes on, the entry's higher
; goes to the next entry
;
; Used by the routine at HofNextDigit.
HofDigitLoop:
  LD A,(IX+$00)
  CP (HL)                 ; A = the entry's digit
  JP Z,HofNextDigit
  JP NC,HofNextEntry      ; the entry is higher: the next one

; POP HL: moves the entries down by 16 from this one, writes the score, asks
; for the name
;
; Ran only in h1 and exD's d1 (neither is a case.json build: h1 is left out for
; its NOP patch, WALKTHROUGH 4), so it is code from this c entry's walk; the
; CAPS delete $A102-$A121 ran in no recording but d1 (no case.json run pressed
; CAPS). The score is higher than this entry (HL = the entry, from the stack):
; CPIR for the $FF ($7511) gives the bytes from the entry to the end; LDDR from
; $7510 to $7520 moves them down 16 (the last entry falls to $7511-$7520, past
; the end; the byte before the entry goes to its +15, then overwritten by the
; score), $FF goes back to $7511. The score's 6 digits go to the entry's +10.
; Then the name entry: ClearScreen $B04B, NameBuffer filled with 8 spaces,
; HofEntryText printed, the cursor "?" at row 15 column 12.
;
; The name entry (HofNameKey): WaitNoKey, ReadKey until a key; SYMBOL SHIFT (2)
; is ignored; ENTER (13) ends; CAPS SHIFT (1) deletes (HofDelete); any other
; key's character is stored at the cursor and printed in bright yellow ($46),
; then the cursor moves on (8 places, columns 12-19; at column 19 it stays and
; the next key overwrites). A delete at column 19 over a character blanks it in
; place; elsewhere it prints "-" ($47, the field's dash) at the cursor, steps
; back and blanks the character there; at column 12 it does nothing. ENTER
; copies the 8 bytes of NameBuffer to the entry's name, sets HallOfFameFirst
; $71F0 to 1, WaitNoKey, JP $6D60: the entry sees the flag and shows the Hall
; of Fame ($7145).
;
; Evidence: h1 (E X O L O N, ENTER: the top entry EXOLON 009000). exD's d1
; (work/ann/exD/d1, from entry-score.z80): E X, CAPS, O L O N A B C, CAPS, D,
; ENTER: every branch of the delete ran ($A102-$A121), and the table's top
; entry became EOLONABD 009000 (the X deleted, the C at the last place blanked
; and overwritten by D). The run's last RAM (frame 8500): $71F1 = "EOLONABD
; 009000", NameBuffer = "EOLONABD".
HofMakeRoom:
  POP HL
  PUSH HL
  LD A,$FF
  LD BC,$03E8             ; BC = 1000, more than the table's 801 bytes
  CPIR
  LD HL,$03E8
  AND A
  SBC HL,BC
  PUSH HL
  POP BC
  LD DE,HallOfFame+$032F  ; the end of the table's room: $7511 + 15
  LD HL,HallOfFame+$031F
  LDDR
  LD A,$FF                ; the table's end again
  LD (HallOfFame+$0320),A
  POP HL                  ; the entry
  PUSH HL
  LD DE,$000A
  ADD HL,DE
  EX DE,HL
  LD HL,Score             ; the score digits
  LD BC,$0006
  LDIR
  CALL ClearScreen        ; ClearScreen
  LD HL,NameBuffer        ; NameBuffer: 8 spaces
  LD DE,NameBuffer+$0001
  LD BC,$0007
  LD (HL),$20
  LDIR
  LD HL,HofEntryText      ; HofEntryText
  CALL PrintString
  LD DE,$0F0C             ; row 15, column 12: the first place
  LD HL,NameBuffer
HofNameCursor:
  LD C,$44                ; the cursor "?" in bright green
  LD A,$3F
  CALL PrintChar
HofNameKey:
  LD BC,$03E8             ; a short delay, then wait for the keys up
  CALL Delay
  CALL WaitNoKey
  PUSH DE                 ; the cursor's row and column
HofNameRead:
  CALL ReadKey            ; ReadKey until a key
  OR A
  JR Z,HofNameRead
  CP $02                  ; SYMBOL SHIFT: not a character
  JR Z,HofNameRead
  POP DE
  CP $0D                  ; ENTER: the end
  JR Z,HofNameDone
  CP $01                  ; CAPS SHIFT: delete; only exD's d1 ran it
  JR NZ,HofNameChar
HofDelete:
  LD A,E                  ; at the last place (column 19); ran only in exD's d1
  CP $13
  JR NZ,HofDeleteBack
  LD A,(HL)               ; a character there: blank it, the cursor stays
  CP $20
  JR Z,HofDeleteBack
  LD (HL),$20
  JR HofNameCursor
HofDeleteBack:
  LD A,E                  ; at the first place: nothing to delete
  CP $0C
  JR Z,HofNameCursor
  LD A,$2D                ; "-" in white over the cursor
  LD C,$47
  CALL PrintChar
  DEC HL                  ; one place back, blanked
  LD (HL),$20
  DEC E
  JR HofNameCursor
HofNameChar:
  LD (HL),A               ; the character into the name
  LD C,$46                ; bright yellow
  CALL PrintChar
  LD A,E                  ; the last place: the cursor stays on it
  CP $13
  JR Z,HofNameKey
  INC HL                  ; the next place
  INC E
  JR HofNameCursor
HofNameDone:
  POP DE                  ; DE = the entry (pushed at $A0B4)
  LD HL,NameBuffer
  LD BC,$0008             ; the 8 characters into the entry's name
  LDIR
  LD A,$01                ; HallOfFameFirst: the entry shows the table
  LD (ShowHallOfFame),A
  CALL WaitNoKey
  JP Start

; The next digit of the score and of the entry; after six equal digits, the
; next entry
;
; Used by the routine at HofDigitLoop.
HofNextDigit:
  INC HL
  INC IX
  DEC B
  JP NZ,HofDigitLoop

; The next entry (IX + 16 from the stack)
;
; Used by the routine at HofDigitLoop.
HofNextEntry:
  POP IX
  LD DE,$0010
  ADD IX,DE
  JP HofEntryLoop

; The name entry screen: the frame, the EXOLON title, CONGRATULATIONS!, PLEASE
; ENTER YOUR NAME ...
;
; Font $ECE0 (the frame pieces, characters 0-11), PanelBar at rows 0-1 and
; 22-23, the two side columns (10 x 2 rows of pieces 4-7 at columns 0-1 and
; 30-31), the title $70FF at 3,8, then in font $D7E0: CONGRATULATIONS! (8,8,
; attribute $46), PLEASE ENTER YOUR NAME (bright green), INTO THE EXOLON HALL
; OF FAME (bright magenta), the field "--------" (bright white, row 15 columns
; 12-19), PRESS CAPS TO DELETE (bright cyan), PRESS ENTER TO END (bright
; yellow). The strings proper start at $A188.
;
; The codes: $61-$8F move by (code - $78) rows and the next byte (signed)
; columns; $CF-$DE the ink (code - $CF, 8 and up bright); $E1 n ... $E2 repeats
; n times; $E3 lo hi prints another string.
HofEntryText:
  DEFM $E6,$E0,$EC,$DF,$00,$00,$E3,$10,$A2,$DF,$02,$00,$E1,$0A,$DC,$04,$D4,$05,$AD,$DC,$06,$D4,$07,$AD,$E2,$E3,$10,$A2,$DF,$02,$1E,$E1,$0A,$DC,$04,$D4,$05,$AD,$DC,$06,$D4,$07,$AD,$E2,$DF,$03,$08,$E3,$FF,"p"
  DEFM $DF,$08,$08,$E0,"F",$E6,$E0,$D7,"CONGRATULATIONS!z",$ED,$DB,"PLEASE ENTER YOUR NAMEz",$E7,$DA,"INTO THE EXOL" ; the texts
  DEFM "ON HALL OF FAME{",$EE,$DE,"--------{",$F2,$DC,"PRESS CAPS TO DELETEz",$ED,$DD,"PRESS ENTER T"                ; in font
  DEFM "O END",$FF                                                                                                   ; $D7E0

; A frame bar: a corner, 14 pairs of top pieces (8, 9), the row under (10, 11),
; the other corner
;
; Printed with {call} by HofEntryText, BonusScreenText and CongratulationsText
; at rows 0 and 22 (two rows: the pieces 8-11 of font $ECE0, bright and plain
; cyan).
PanelBar:
  DEFM $E3,"(",$A2,$DC,"x",$02,$E1,$0E,$08,$09,$E2,$93,$D4,$E1,$0E,$0A,$0B,$E2,"w",$00,$E3,"(",$A2,$FF

; A corner of the frame: pieces 0-3 in 2 x 2, bright cyan and cyan
PanelCorner:
  DEFM $DC,$00,$D4,$01,$AD,$DC,$02,$D4,$03,$FF

; The name typed in the Hall of Fame entry: 8 characters (spaces at the start
; of each entry)
NameBuffer:
  DEFM "        "
