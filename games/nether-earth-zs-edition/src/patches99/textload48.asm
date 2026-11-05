; --------------------------------------------------------------------------------------------------------------------
; textload48.asm: One page / tape: a text or the menu read from disk or tape (the tape set), run at $A56A
;
; The patches block's `$DAE7-$DB14` (46 bytes). Stage 3 copies it to `$A56A-$A597` on every path ($631E); on 128 K
; paging128 then replaces it. Never run in a recording: the code is read from its bytes.
; --------------------------------------------------------------------------------------------------------------------

; "WAITING FILE n", then ReadBlock with the caller's HL, DE, BC and the flag n
;
; In: A the file's number (its low 4 bits: menu48's text entries 1-4; the menu
; file takes what A holds at Start), HL the destination, DE the disk position
; (track, sector), BC the length (B the sectors on disk, BC the bytes on tape).
; The screen is cleared (QuietScreen), "WAITING FILE n" printed at (11,8),
; attribute $06, double height, then ReadBlock: on disk DiskRead (DE, B; A not
; used), on tape TapeRead (BC, the flag byte n: the tape blocks carry their
; file number as the flag).
LoadText:
  AND $0F                 ; the number, 0-15
  PUSH AF                 ; keep the registers
  PUSH BC
  PUSH DE
  PUSH HL
  ADD A,$30               ; the digit...
  LD (WaitFileDigit),A    ; ... into the text
  CALL QuietScreen              ; a blank screen, interrupts off
  CALL PrintInline              ; the prompt

; PrintInline text: "WAITING FILE n" at (11,8), attribute $06, setting $21
;
; The bytes 1 11 8 (position (11,8)), 2 $06 (yellow on black), 4 $21 (double
; height), "WAITING FILE " and the digit LoadText writes at $A58F, 0.
WaitFileText:
  DEFM $01,$0B,$08,$02,$06,$04,"!WAITING FILE " ; AT (11,8), attribute $06,
                                                ; size $21
WaitFileDigit:
  DEFM " ",$00            ; the file's digit (LoadText writes it)

; The registers back, then ReadBlock
LoadTextRead:
  POP HL                  ; the destination
  POP DE                  ; the position
  POP BC                  ; the length
  POP AF                  ; the number (the tape flag)
  JP ReadBlock                ; read the file
