; --------------------------------------------------------------------------------------------------------------------
; paging128.asm: 128 K: the text copy from page 3 and the paging routine (the disk set), run at $A56A
;
; The patches block's `$DA3F-$DA67` (41 bytes). Stage 3 copies it to `$A56A-$A592` when the machine has more than one
; page ($6335), over textload48 that it copied there first.
; --------------------------------------------------------------------------------------------------------------------

; 128 K: copy BC bytes of a text from page 3 at DE to HL, through the screen
;
; In: DE the text in page 3, BC its length, HL the destination in page 0 or 2;
; A is not used (menu128's text entries load it with the text's number for the
; one-page reader). The screen is cleared first (ClearScreen: the attributes 0,
; black on black), the text copied with page 3 in to `$4000` (pixels only: the
; texts are shorter than $1800 bytes, so nothing shows), then with page 0 back
; from `$4000` to HL. Page 0 stays in and interrupts off (SetPage's DI).
;
; The menu's texts: menu128's entries at $C124-$C14F with the operands stage 3
; writes: 1 NEdescri at page 3 `$CF00` ($155D bytes), 2 NEadvice `$E700`
; ($15C4), 3 NEgreets `$E500` ($0139), 4 NEabout `$C000` ($0EB3).
PagedText:
  PUSH HL                 ; keep the destination...
  PUSH DE                 ; ... the source...
  PUSH BC                 ; ... and the length
  CALL ClearScreen              ; a blank screen: its attributes black on black
  LD A,$03                ; page 3 in
  CALL SetPage
  POP BC                  ; the length
  POP HL                  ; HL = the source
  PUSH BC                 ; the length again
  LD DE,$4000             ; to the screen's pixels
  LDIR
  LD A,$00                ; page 0 back
  CALL SetPage
  POP BC                  ; the length
  POP DE                  ; DE = the destination
  LD HL,$4000             ; from the screen
  LDIR                    ; into place
  RET

; Page A (0-7) in at $C000, the 48 ROM in (port $7FFD = A OR $10); interrupts
; off
;
; No copy goes to BANKM ($5B5C): nothing else here reads it. DI first, never
; undone: the callers run with interrupts off.
SetPage:
  DI                      ; no interrupt while the page changes
  OR $10                  ; bit 4: the 48 ROM
  LD BC,$7FFD             ; the paging port
  OUT (C),A
  RET
