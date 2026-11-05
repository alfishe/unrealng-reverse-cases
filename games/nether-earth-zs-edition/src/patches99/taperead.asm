; --------------------------------------------------------------------------------------------------------------------
; taperead.asm: The tape block reader (the tape set), run at $A598
;
; The patches block's `$D974-$D9AB` (56 bytes). Stage 3 copies it to `$A598-$A5CF` when the program was loaded from
; tape (PROG below `$5D3B`: no TR-DOS system variables, $638F). LOAD MAP (TapeLoadMap) and the text reader (LoadText)
; call it. Never run in a recording: the code is read from its bytes.
; --------------------------------------------------------------------------------------------------------------------

; Load a tape block of BC bytes with flag A to HL; on an error print "ERROR!
; LOAD AGAIN..." and wait for it again
;
; In: HL the destination, BC the length, A the flag byte. It sets up what
; LD-BYTES ($0556) would (IX the address, DE the length, the carry set for a
; load, A and the flags into AF') with the border black instead of the ROM's,
; and enters the ROM past its set-up at $0562, so the ROM's SA/LD-RET (the
; BREAK test and its error report) is not pushed: the ROM returns here with the
; carry set for a good block, clear for an error, the BREAK key (SPACE)
; included. Interrupts stay off.
;
; On an error: "ERROR! LOAD AGAIN... " at (11,5), attribute $42 (bright red on
; black), double height, then the next try from the set-up with IX, DE and AF'
; as the ROM left them; a break before the block's data (no block, a wrong
; flag, SPACE) tries again in full, a break inside the data goes on from where
; it stopped with the flag the ROM had swapped back.
TapeRead:
  PUSH HL                 ; IX = the destination
  POP IX
  LD D,B                  ; DE = the length
  LD E,C
; This entry point is used by the routine at TapeRetry.
TapeLoadSetUp:
  SCF                     ; a load, not a verify
  INC D                   ; NZ (the flag byte comes first)...
  EX AF,AF'               ; ... into AF' with the flag
  DEC D                   ; (D back)
  DI                      ; no interrupts
  XOR A                   ; the border black
  OUT ($FE),A
  CALL LdBytesIn              ; ROM LD-BYTES past its set-up
  RET C                   ; loaded
  CALL PrintInline              ; the error line

; PrintInline text: "ERROR! LOAD AGAIN... " at (11,5), attribute $42, setting
; $21
;
; The bytes 1 11 5 (position (11,5)), 2 $42 (bright red on black), 4 $21
; (double height), the 21 characters, 0.
TapeErrorText:
  DEFM $01,$0B,$05,$02,"B",$04,"!ERROR! LOAD AGAIN... ",$00 ; AT (11,5),
                                                            ; attribute $42,
                                                            ; size $21

; Try the load again: AF' back, then the set-up
TapeRetry:
  EX AF,AF'               ; the flag as the ROM left it in AF'
  JR TapeLoadSetUp        ; again

; Zero: 4 bytes of the piece never used
TapeReadSpare:
  DEFS $04
