; --------------------------------------------------------------------------------------------------------------------
; hiscore.asm: The hall of fame: the rank of a score, the name entry
; --------------------------------------------------------------------------------------------------------------------

  ORG $9B76

; The variables of the hall-of-fame entry
;
; BlinkPhase `$9B76` (the name cursor's blink: 1 shown), NameColumn `$9B77`
; (1-6), Rank `$9B78` (1-6, 7 not in the table), RecordsToMove `$9B79`,
; NamePointer `$9B7A` (the next letter in the names table), NameScreen `$9B7C`
; (the screen address of the next letter), NameAttr `$9B7E` (its attribute
; address), KeyHeld `$9B80`, LastKey `$9B81`, BlinkTimer `$9B82` (70 polls),
; LetterIndex `$9B83`, ScoreCopy `$9B84`-`$9B89` (the score's six digits,
; spaces made zeros). `$9B8A`-`$9BBF` are never used.
NameEntryVars:
BlinkPhase:
  DEFB $00                ; 1: the diamond shown
NameColumn:
  DEFB $01                ; 1-6
Rank:
  DEFB $07                ; 1-6, 7: not in the table
RecordsToMove:
  DEFB $00
NamePointer:
  DEFB $00,$00            ; the name's next letter in the table
NameScreen:
  DEFB $00,$00            ; its screen address
NameAttr:
  DEFB $00,$00            ; its attribute address
KeyHeld:
  DEFB $00
LastKey:
  DEFB $00
BlinkTimer:
  DEFB $00                ; 70 polls
LetterIndex:
  DEFB $00
ScoreCopy:
  DEFB $00,$00,$00,$00,$00,$00 ; the score, six digits
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; never used
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; After a game: rank the score, take a name for the hall of fame, draw the
; options screen
;
; Called by the title loop `$840C` after each game (11 runs: c1g, controls,
; gameover, kempston, menu, mine, overload, rzx-344752). Interrupts off, the
; sound flags cleared, `$A103` = `$FF` (the interrupt's title mode). After
; practice (`$8407`): only the options screen (`DrawMenuScreen` `$9ED8`) and
; the COMPUTER line `$A199`.
;
; Else the score's six digits (spaces as 0) go to ScoreCopy `$9B84`,
; `RankScore` `$9E1F` gives the place 1-7. 7: just the options screen. Else the
; lower records move down one (scores 9 bytes a record from `$9FEB`, names 8
; bytes from `$A022`, the last dropped), the score is written into its record,
; the name cleared to five spaces, the rows renumbered (`RenumberHallOfFame`
; `$9E00`), the screen drawn and wiped in (`$8C95`), a tone (`$A843`, `$3250`),
; the COMPUTER line "HIGH DEFLEKTOR RATING ... PLEASE ENTER YOUR NAME"
; (`$A28E`, its `$A2A4` patched to `$FE`).
;
; The name: up to five letters at column `$12` of the hall of fame's row 8 +
; rank, a blinking diamond (`$9FE3`, attribute `$3A`) every 70 polls at the
; next place. The letters A-Z (`ReadLetterKey` `$9E5A`), SPACE, DELETE (0) one
; back, ENTER ends: the screen redrawn from the buffer (`$9ED8`, `$8B9B`), a
; tone (`$465A`) and six delays (`$8908`).
;
; Recording: `rzx-344752` (the RZX player's entry after the ending: one letter,
; R, then ENTER; 206 polls). The DELETE (`$9D15`) and SPACE (`$9D5A`) paths and
; the full name (`$9D7E`) ran in no recording: known only from the code.
;
; Witness: L1 14 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu,
; mine, overload, rzx344752).
HallOfFame:
  DI
  XOR A
  LD (SoundFlags),A
  LD A,$FF
  LD (MenuScroller),A
  LD A,(PracticeFlag)     ; practice: no hall of fame
  AND A
  JR NZ,HallOfFameMenu
  LD HL,ScoreDigits       ; the score to ScoreCopy, spaces as 0
  LD DE,ScoreCopy
  LD B,$06
HallOfFameCopy:
  LD A,(HL)
  CP $20
  JR NZ,HallOfFameDigit
  LD A,$30
HallOfFameDigit:
  LD (DE),A
  INC HL
  INC DE
  DJNZ HallOfFameCopy
  LD A,$01
  LD (NameColumn),A
  CALL RankScore          ; the rank: 7 is out of the table
  CP $07
  JR NZ,HallOfFameInsert
HallOfFameMenu:
  CALL DrawMenuScreen     ; the options screen and the COMPUTER line
  LD HL,BlankMessage
  LD (MessageText),HL
  RET
HallOfFameInsert:
  CP $06                  ; rank 6: nothing to move
  JR Z,HallOfFameScore
  LD B,A                  ; move the lower scores down (9 bytes each)
  LD A,$06
  SUB B
  LD (RecordsToMove),A
  LD DE,$0009
  LD HL,$0000
HallOfFameScoreBytes:
  ADD HL,DE
  DEC A
  JR NZ,HallOfFameScoreBytes
  PUSH HL
  POP BC
  LD HL,HallOfFameScores+$002C
  LD DE,HallOfFameScores+$0035
  DEC BC
  LDDR
  LD A,(RecordsToMove)    ; and the lower names (8 bytes each)
  LD DE,$0008
  LD HL,$0000
HallOfFameNameBytes:
  ADD HL,DE
  DEC A
  JR NZ,HallOfFameNameBytes
  PUSH HL
  POP BC
  LD HL,HallOfFameNames+$0027
  LD DE,HallOfFameNames+$002F
  DEC BC
  LDDR
HallOfFameScore:
  LD HL,HallOfFameScores  ; the score into its record ($9FEB + 9 x (rank - 1) +
                          ; 3)
  LD DE,$0009
  LD A,(Rank)
  DEC A
  JR Z,HallOfFameScoreCopy
HallOfFameScoreRecord:
  ADD HL,DE
  DEC A
  JR NZ,HallOfFameScoreRecord
HallOfFameScoreCopy:
  EX DE,HL
  INC DE
  INC DE
  INC DE
  LD HL,ScoreCopy
  LD BC,$0006
  LDIR
  LD HL,HallOfFameNames   ; the name's record: $A022 + 8 x (rank - 1)
  LD DE,$0008
  LD A,(Rank)
  DEC A
  JR Z,HallOfFameNameReady
HallOfFameNameRecord:
  ADD HL,DE
  DEC A
  JR NZ,HallOfFameNameRecord
HallOfFameNameReady:
  LD (NamePointer),HL     ; renumber the rows, clear the name to five spaces
  CALL RenumberHallOfFame
  LD HL,(NamePointer)
  INC HL
  INC HL
  INC HL
  LD (NamePointer),HL
  LD (HL),$20
  LD D,H
  LD E,L
  INC DE
  LD BC,$0004
  LDIR
  CALL DrawMenuScreen     ; draw the screen into the buffer
  LD A,(Rank)             ; the name's screen and attribute addresses: row 8 +
                          ; rank, column $12
  LD HL,Screen+2066
  LD DE,Attributes+274
  AND A
  JR Z,HallOfFameWipe
  LD BC,$0020
HallOfFameRow:
  RRC H
  RRC H
  RRC H
  ADD HL,BC
  RLC H
  RLC H
  RLC H
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,HallOfFameRow
HallOfFameWipe:
  LD (NameScreen),HL      ; wipe the screen in, a tone, ENTER YOUR NAME
  LD (NameAttr),DE
  CALL WipeInScreen
  LD HL,$3250
  CALL TwoTone
  LD A,$FE
  LD (RatingPause),A
  LD HL,HighRatingMessage
  LD (MessageText),HL
  EI                      ; interrupts on (the COMPUTER line scrolls)
HallOfFameRelease:
  XOR A                   ; wait until no key is held
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,HallOfFameRelease
  LD A,$01                ; first column, the blink every 70 polls
  LD (NameColumn),A
  XOR A
  LD (KeyHeld),A
  LD A,$46
  LD (BlinkTimer),A
HallOfFameLoop:
  LD A,(BlinkTimer)       ; the blink timer
  DEC A
  LD (BlinkTimer),A
  AND A
  JR NZ,HallOfFameKeys
  LD A,$46
  LD (BlinkTimer),A
  LD A,(BlinkPhase)
  AND A
  JR Z,HallOfFameBlinkOff
  XOR A                   ; blink on: the diamond
  LD (BlinkPhase),A
  LD HL,(NameAttr)
  LD (HL),$3A
  LD HL,NameCursorGlyph
  CALL PutGlyph
  JR HallOfFameKeys
HallOfFameBlinkOff:
  LD A,$01                ; blink off: a space
  LD (BlinkPhase),A
  LD HL,Font
  CALL PutGlyph
HallOfFameKeys:
  LD A,$21                ; ENTER: done
  CALL TestKey
  JP NC,HallOfFameDone
  LD A,$23                ; DELETE (0)?
  CALL TestKey
  JR C,HallOfFameSpace
  LD A,(LastKey)          ; DELETE, newly pressed, not at the first column: one
                          ; back
  CP $23
  JR Z,HallOfFameKeys
  LD A,$23
  LD (LastKey),A
  LD A,(NameColumn)
  CP $01
  JR Z,HallOfFameKeys
  DEC A
  LD (NameColumn),A
  LD A,$01
  LD (BlinkPhase),A
  CALL EraseNameCursor
  LD HL,(NameScreen)
  DEC L
  LD (NameScreen),HL
  LD HL,(NameAttr)
  DEC L
  LD (NameAttr),HL
  LD HL,Font
  CALL PutGlyph
  LD HL,(NamePointer)
  DEC HL
  LD (HL),$20
  LD (NamePointer),HL
  JR HallOfFameKeys
HallOfFameSpace:
  LD A,$20                ; SPACE?
  CALL TestKey
  JR C,HallOfFameLetter
  LD A,(LastKey)          ; SPACE, newly pressed: a space, one on (not at the
                          ; sixth column)
  CP $20
  JR Z,HallOfFameKeys
  LD A,$20
  LD (LastKey),A
  LD A,(NameColumn)
  CP $06
  JP Z,HallOfFameFull
  CALL EraseNameCursor
  LD HL,(NamePointer)
  LD (HL),$20
  INC HL
  LD (NamePointer),HL
  JP HallOfFameNextColumn
HallOfFameLetter:
  LD A,(NameColumn)       ; the sixth column: no more letters
  CP $06
  JP NZ,HallOfFameLetterKey
HallOfFameFull:
  CALL ReadLetterKey
  JP HallOfFameLoop
HallOfFameLetterKey:
  CALL ReadLetterKey      ; a letter newly pressed?
  JR C,HallOfFameLetterPut
  LD A,(KeyHeld)
  AND A
  JP NZ,HallOfFameKeys
  JP HallOfFameLoop
HallOfFameLetterPut:
  LD B,A                  ; the letter A + n - 1 into the name and on the
                          ; screen
  LD A,(KeyHeld)
  AND A
  JP Z,HallOfFameKeys
  LD A,B
  ADD A,$40
  LD HL,(NamePointer)
  LD (HL),A
  INC HL
  LD (NamePointer),HL
  SUB $20
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Font
  ADD HL,BC
  CALL PutGlyph
  LD HL,(NameAttr)
  LD (HL),$38
HallOfFameNextColumn:
  LD A,(NameColumn)       ; one column on
  INC A
  LD (NameColumn),A
  LD HL,(NameScreen)
  INC L
  LD (NameScreen),HL
  LD HL,(NameAttr)
  INC L
  LD (NameAttr),HL
  JP HallOfFameKeys
HallOfFameDone:
  DI                      ; ENTER: redraw, a tone, a pause
  CALL DrawMenuScreen
  CALL CopyFullScreen
  LD HL,$465A
  CALL TwoTone
  LD A,$06
HallOfFameDelay:
  CALL Delay
  DEC A
  JR NZ,HallOfFameDelay
  RET

; Copy an 8-byte glyph from HL to the screen at NameScreen
;
; Eight rows down from the address in `$9B7C`. Used by the name entry and by
; the title's options code (`$A7A0`, `$A7F9`, `$A82F`).
;
; Witness: L1 71 (c1, c1g, controls, energy, energy-out, hof, kempston, menu,
; rzx344752).
PutGlyph:
  LD DE,(NameScreen)
  LD B,$08
PutGlyphRow:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ PutGlyphRow
  RET

; Clear the name cursor: attribute $38 and a space
;
; Known only from the code (no recording deletes or types a space).
;
; Witness: L1 0 ().
EraseNameCursor:
  LD HL,(NameAttr)
  LD (HL),$38
  LD HL,Font
  JP PutGlyph

; Set the rows of the hall of fame's records to 9-14
;
; The third byte (the row) of the six names' records (`$A024`, 8 bytes apart)
; and of the six scores' (`$9FED`, 9 bytes apart): 9, 10, ... 14, after records
; were moved.
;
; Witness: L1 2 (hof, rzx344752).
RenumberHallOfFame:
  LD HL,HallOfFameNames+$0002
  LD DE,$0008
  LD A,$09
  LD B,$06
RenumberNames:
  LD (HL),A
  ADD HL,DE
  INC A
  DJNZ RenumberNames
  LD HL,HallOfFameScores+$0002
  LD DE,$0009
  LD A,$09
  LD B,$06
RenumberScores:
  LD (HL),A
  ADD HL,DE
  INC A
  DJNZ RenumberScores
  RET

; The place of ScoreCopy in the hall of fame: 1-6, or 7 when it is too low
;
; Compares the six digits of ScoreCopy `$9B84` with the scores from the last
; (`$A01B`) upwards; the place goes down from 7 while the score is greater than
; the record's; equal does not pass. Returns the place in A and Rank `$9B78`.
;
; Witness: L1 14 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu,
; mine, overload, rzx344752).
RankScore:
  LD A,$07
  LD (Rank),A
  LD HL,ScoreCopy
  LD DE,HallOfFameScores+$0030
  LD B,$06
RankScoreRecord:
  PUSH BC
  PUSH HL
  PUSH DE
  LD C,$06
RankScoreDigit:
  LD A,(DE)
  CP (HL)
  JR C,RankScoreUp
  JR NZ,RankScoreDone
  INC DE
  INC HL
  DEC C
  JR NZ,RankScoreDigit
RankScoreDone:
  POP DE                  ; lower or equal: here
  POP HL
  POP BC
  LD A,(Rank)
  RET
RankScoreUp:
  LD A,(Rank)             ; greater: one place up
  DEC A
  LD (Rank),A
  LD DE,$0009
  POP HL
  AND A
  SBC HL,DE
  EX DE,HL
  POP HL
  POP BC
  DJNZ RankScoreRecord
  LD A,(Rank)
  RET

; Which letter key is newly pressed: carry and A = 1-26, or no carry
;
; Tests the 26 key codes of `LetterKeys` `$9EBD` with `TestKey` `$9EA2`. A held
; key: carry only when it differs from LastKey `$9B81`; KeyHeld `$9B80` = 1
; while any letter is held, 0 when none.
;
; Witness: L1 2179 (hof, rzx344752).
ReadLetterKey:
  LD HL,LetterKeys
  LD A,$01
  LD (LetterIndex),A
ReadLetterLoop:
  LD A,(HL)
  CP $FF
  JR Z,ReadLetterNone
  PUSH HL
  CALL TestKey
  POP HL
  JR NC,ReadLetterFound
  INC HL
  LD A,(LetterIndex)
  INC A
  LD (LetterIndex),A
  JR ReadLetterLoop
ReadLetterFound:
  LD A,(LetterIndex)      ; a new key: carry
  LD B,A
  LD A,(LastKey)
  CP B
  JR Z,ReadLetterSame
  LD A,$01
  LD (KeyHeld),A
  LD A,(LetterIndex)
  LD (LastKey),A
  SCF
  RET
ReadLetterSame:
  LD A,$01                ; the same key as before: no carry
  LD (KeyHeld),A
  LD A,(LetterIndex)
  AND A
  RET
ReadLetterNone:
  XOR A
  LD (KeyHeld),A
  LD (LastKey),A
  AND A
  RET

; Test one key: A = 8 x (4 - bit) + half-row, NC when it is held
;
; The half-row 0-7 is `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`,
; `$FDFE`, `$FEFE`; the high three bits count the key from the outer end of the
; half-row (bit 4 first). So `$21` is ENTER, `$20` SPACE, `$23` 0 (DELETE).
;
; Witness: L1 49147 (hof, rzx344752).
TestKey:
  LD C,A
  AND $07
  INC A
  LD B,A
  SRL C
  SRL C
  SRL C
  LD A,$05
  SUB C
  LD C,A
  LD A,$FE
TestKeyRow:
  RRCA
  DJNZ TestKeyRow
  IN A,($FE)
TestKeyBit:
  RRA
  DEC C
  JR NZ,TestKeyBit
  RET

; The key codes of A to Z for TestKey, $FF ends
;
; `$26` A, `$00` B, `$0F` C, `$16` D, `$15` E, `$0E` F, `$06` G, `$01` H, `$12`
; I, `$09` J, `$11` K, `$19` L, `$10` M, `$08` N, `$1A` O, `$22` P, `$25` Q,
; `$0D` R, `$1E` S, `$05` T, `$0A` U, `$07` V, `$1D` W, `$17` X, `$02` Y, `$1F`
; Z (the code is 8 x (4 - bit) + half-row of `TestKey`).
LetterKeys:
  DEFB $26,$00,$0F,$16,$15,$0E,$06,$01
  DEFB $12,$09,$11,$19,$10,$08,$1A,$22
  DEFB $25,$0D,$1E,$05,$0A,$07,$1D,$17
  DEFB $02,$1F,$FF

  ORG $A022

; The hall of fame's six names: text records (attribute, column, row, 5
; characters), $FF
;
; Six records of 8 bytes for the printer `$8E3A`: an attribute byte with bit 7
; set (the record mark; the printer clears bit 7, so the colour is `$39`, blue
; on white), the column `$12`, the row `$09-$0E`, then five characters. `$FF`
; ends the list. They stand beside the six score records `$9FEB` (9 bytes each:
; attribute, column `$18`, row, six digits) printed by `$9ED8` (at `$9F2E`) on
; the options panel; the default names are the six ranks MEGA, GREAT, GOOD,
; SO-SO, BAD, AWFUL.
;
; A new entry (`$9BC0`): the names below the new place move down one record
; (`LDDR` from `$A049` to `$A051`, 8 bytes a record), the new record's five
; characters are cleared to spaces (`$9C6D`) and typed in by `$9E00` (which
; reads from `$A024`, the row byte). Evidence: written once in `rzx-344752`
; (the RZX player's entry, name R); read in every recording that showed the
; options panel (`c1g`, `menu`, `controls`, `kempston`, `mine`, `overload`,
; `gameover`).
HallOfFameNames:
  DEFM $B9,$12,$09,"MEGA " ; MEGA (row 9)
  DEFM $B9,$12,$0A,"GREAT" ; GREAT (row 10)
  DEFM $B9,$12,$0B,"GOOD " ; GOOD (row 11)
  DEFM $B9,$12,$0C,"SO-SO" ; SO-SO (row 12)
  DEFM $B9,$12,$0D,"BAD  " ; BAD (row 13)
  DEFM $B9,$12,$0E,"AWFUL" ; AWFUL (row 14)
  DEFM $FF                ; the end of the list
