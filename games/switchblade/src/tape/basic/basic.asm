; --------------------------------------------------------------------------------------------------------------------
; basic.asm: The BASIC: line 0, whose USR enters the code that ends the line
;
; The program is one line, numbered 0 and auto-run: LET X=PEEK 23635+256*PEEK 23636: LET x=x+60: RANDOMIZE USR x, that
; is USR (PROG + 60) = $5D07. LIST shows the digits "66666", "770", "60877" and "87": the five-byte forms after them
; hold the real numbers 23635 (PROG), 256, 23636 and 60. The ROM's variable names are case-blind, so X and x are one
; variable.
;
; The line has no ENTER: its length field (57) runs to $5D07, whose byte $F3 is both the token NEXT (where the ROM
; would look for the end of the statement) and the DI that starts the machine code. USR is evaluated first, so the
; line never ends.
; --------------------------------------------------------------------------------------------------------------------

; Line 0: LET X=PEEK 66666+770*PEEK 60877: LET x=x+87: RANDOMIZE USR x, the
; hidden numbers 23635, 256, 23636, 60
;
; X = PEEK PROG + 256 x PEEK (PROG + 1) = `$5CCB`, the line's own address; x +
; 60 = `$5D07`, the code after the line. The digits shown are decoys: the
; five-byte forms (each after `$0E`) are what the ROM uses, so LIST shows
; nonsense numbers.
;
; c1 and c48: the ROM runs the line after the load and USR enters `$5D07`.
BasicLine0:
  DEFB $00,$00            ; the line number, 0 (high byte first)
  DEFB $39,$00            ; the line's length, 57: to $5D07, the first byte of
                          ; the code
  DEFB $F1,$58,$3D,$BE    ; LET ($F1) X = PEEK ($BE)
  DEFB $36,$36,$36,$36,$36,$0E,$00,$00 ; "66666", $0E and 23635 = $5C53 (PROG)
  DEFB $53,$5C,$00
  DEFB $2B,$37,$37,$30,$0E,$00,$00,$00 ; "+" "770", $0E and 256
  DEFB $01,$00
  DEFB $2A,$BE,$36,$30,$38,$37,$37,$0E ; "*" PEEK "60877", $0E and 23636 =
  DEFB $00,$00,$54,$5C,$00             ; $5C54
  DEFB $3A,$F1,$78,$3D,$78,$2B ; ":" LET x = x "+"
  DEFB $38,$37,$0E,$00,$00,$3C,$00,$00 ; "87", $0E and 60
  DEFB $3A,$F9,$C0,$78    ; ":" RANDOMIZE ($F9) USR ($C0) x; no ENTER: the line
                          ; goes on into the code

; Line 0's code: 48K ROM, black screen, find its own address, copy the loader
; to $FF00 and run it
;
; Entered by USR with interrupts on; its first byte `$F3` (DI) is also the end
; of the BASIC line (the token NEXT).
;
; 1. `$10` to the 128K paging port `$7FFD`: the 48K BASIC ROM, RAM bank 0 at
; `$C000`, paging not locked (a 48K ignores the write). Border black; Screen
; and Attributes cleared to 0 (the LDIR copies the stored A = 0).
;
; 2. Its own address: SP = 0, CALL RomRet `$0555` (a RET), so the return
; address `$5D24` is left at `$FFFE`; two DEC SP and POP HL read it back, +
; `$13` = `$5D37`, the loader's bytes. SP = `$5D37` (the stack grows down into
; the line, which is no longer needed).
;
; 3. LDIR the `$FD` bytes `$5D37-$5E33` to `$FF00-$FFFC` and `JP $FFEE`
; (LoaderStart).
;
; Witness: L1 11 (c1).
BasicCode:
  DI
  LD A,$10                ; the 48K BASIC ROM, bank 0
  LD BC,$7FFD
  OUT (C),A
  XOR A                   ; border black, the screen and attributes cleared
  OUT ($FE),A
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1AFF
  LD (HL),A
  LDIR
  LD SP,$0000             ; the return address of a CALL to a RET: this code's
                          ; address
  CALL RomRet
  DEC SP
  DEC SP
  POP HL
  LD DE,$0013             ; + $13: the loader's bytes
  ADD HL,DE
  LD SP,HL
  LD DE,$FF00             ; copy the loader to $FF00 and run it
  LD BC,$00FD
  LDIR
  JP $FFEE
