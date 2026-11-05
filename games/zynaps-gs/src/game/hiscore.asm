; --------------------------------------------------------------------------------------------------------------------
; hiscore.asm: The high-score table: rank and initials
;
; The table ROLE OF HONOUR at $8261 holds 5 entries of 14 bytes: a 10-byte print string (row, column, three initials,
; $1B 8 for the dots, $FF) and the score in 4 BCD bytes. A new entry moves the lower ones down by copying 10 bytes of
; each (the initials, the dots and the score: the row and column stay) and takes the player's score; the initials are
; picked with left and right, A-Z, and fire.
; --------------------------------------------------------------------------------------------------------------------

; Rank the current player's score, take the initials
;
; MenuScreenSetup, message 25 (ROLE OF HONOUR, PLAYER n). The score (the record
; ($7F99) + 0) is compared with the five entries from the top: below all of
; them message 26 (UNRANKED) for 150 frames or until fire.
;
; Ranked: message 27 (ENTER YOUR INITIALS), the lower entries move down, the
; score is copied in, then three letters at row 13 column 13 (attribute $59AD,
; 2 cells apart): each starts at A, right/left (ReadControls) step it through
; A-Z with wrap-around every 5 frames, fire (or 100 steps without movement, 10
; seconds) takes it and prints a dot after it; 20 frames between the letters,
; 50 after the last. Ends with WaitMenuRasterEnd, ClearScreen.
;
; Used by the game over (PlayerDied).
;
; GS: the waits are HALT loops (the installer turns WaitFrames $A6AE into the
; driver's round wait, so the GS waits here with HALTs of its own). At $A8B2 LD
; B,50, EI, HALT, DJNZ, then CALL WaitMenuRasterEnd and a tail JP ClearScreen.
; The jumps that end the entry early ($A824 JP C, $A829 JP: 3 seconds without a
; new entry) still go to $A8B7, the 48K's CALL: in the GS that is the DJNZ's
; offset byte $FD, an IY prefix the CALL after it ignores, so they land on the
; CALL with the wait skipped (as in the 48K).
HighScoreEntry:
  CALL MenuScreenSetup
  LD A,$19                ; ROLE OF HONOUR
  CALL PrintMessage
  LD HL,(PlayerRecord)    ; the score at +0 of the player's record
  LD DE,$0000
  ADD HL,DE
  EX DE,HL
  LD HL,HiScoreTable+$000A ; the first entry's score
  LD B,$05
HighScoreRank:
  CALL CompareScore
  JR C,HighScoreInsert
  PUSH BC
  LD BC,$000E             ; the next entry
  ADD HL,BC
  POP BC
  DJNZ HighScoreRank
  LD A,$1A                ; UNRANKED
  CALL PrintMessage
  LD B,$96                ; 3 seconds or fire
HighScoreUnranked:
  HALT
  CALL TitleFireCheck
  JP C,HighScoreDone
  DJNZ HighScoreUnranked
  JP HighScoreDone
HighScoreInsert:
  PUSH HL                 ; ENTER YOUR INITIALS
  PUSH DE
  LD A,$1B
  CALL PrintMessage
  LD DE,$0000             ; the first copy (the last entry) goes to the ROM:
                          ; dropped
  LD HL,HiScoreTable+$003C ; the initials of the last entry
HighScoreMoveDown:
  PUSH HL                 ; an entry's initials, dots and score one entry down
  PUSH BC
  LD BC,$000A
  LDIR
  POP BC
  POP DE
  LD HL,-$000E            ; the entry above
  ADD HL,DE
  DJNZ HighScoreMoveDown
  POP HL                  ; the player's score into the free entry
  POP DE
  LD BC,$0004
  LDIR
  LD HL,-$000A            ; HL = the free entry's initials
  ADD HL,DE
  LD IX,$59AD             ; row 13, column 13
  LD B,$03
HighScoreLetter:
  PUSH BC
  LD C,$41                ; 'A'
  EX AF,AF'               ; 100 steps without input take the letter
  LD A,$64
  EX AF,AF'
HighScoreLetterShow:
  LD (PrintPos),IX
  LD A,C
  CALL PrintChar
  CALL ReadControls
  EI                      ; GS: EI and 4 HALTs for the 48K's 5 frames: the
                          ; initial letters turn a little faster
  HALT
  HALT
  HALT
  HALT
  LD A,(FireHeld)         ; fire: take it
  AND A
  JR NZ,HighScoreLetterTaken
  EX AF,AF'               ; time out: take it
  DEC A
  JR Z,HighScoreLetterTaken
  EX AF,AF'
  LD A,(ControlBits)      ; left or right: the time out again
  AND $03
  JR Z,HighScoreLetterMove
  EX AF,AF'
  LD A,$64
  EX AF,AF'
HighScoreLetterMove:
  LD E,A                  ; right +1, left -1
  LD A,C
  RR E
  ADC A,$00
  RR E
  SBC A,$00
  CP $5B                  ; past Z: A
  LD C,$41
  JR Z,HighScoreLetterLoop
  CP $40                  ; before A: Z
  LD C,$5A
  JR Z,HighScoreLetterLoop
  LD C,A
HighScoreLetterLoop:
  JR HighScoreLetterShow
HighScoreLetterTaken:
  LD (HL),C               ; the initial and a dot
  INC HL
  LD A,$2E
  CALL PrintChar
  LD B,$14                ; GS: LD B,20 and a HALT loop for WaitFrames 20
l_A8A8:
  HALT
  DJNZ l_A8A8
  INC IX
  INC IX
  POP BC
  DJNZ HighScoreLetter
  LD B,$32                ; GS: 50 frames: LD B,50, EI, a HALT loop
  EI
  HALT

; GS: the HALT loop's DJNZ $A8B5 as bytes ($10 $FD): the early exits land on
; its $FD
;
; The walk of the code cannot hold both: the DJNZ at $A8B6 and the jump target
; $A8B7 inside it. The two bytes assemble the same.
HighScoreHaltLoop:
  DEFB $10

; GS: $FD (the DJNZ's offset, an IY prefix the CALL ignores), the menu raster's
; end, the screen cleared
;
; The jumps at $A824 and $A829 (no new entry) come here as in the 48K, where
; $A8B7 is the CALL itself. The fall-through from the wait reaches the CALL at
; $A8B8.
HighScoreDone:
  DEFB $FD
  CALL WaitMenuRasterEnd
  JP ClearScreen
