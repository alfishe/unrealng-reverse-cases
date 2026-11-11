; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: one line whose USR enters the machine code after it, and the enciphered chain
;
; The program is one line, 55 bytes long, then machine code the line never shows. The line's USR adds 59 to PROG
; ($5CCB): the number printed is 10, the five-byte form after it says 59, so LIST shows a sum that is not the one the
; ROM computes. Stage1 at PROG+59 = $5D06 copies the 4821 bytes from PROG+95 = $5D2A to $AC38-$BF0C and returns into
; them, the decryption chain (src/loader/chain.asm).
;
; c1: the ROM loads the block at frames 208-1999 and runs line 0; Stage1 is entered at frame 2028, the chain at $AC38
; at frame 2033 (docs/03 3.1, the stages).
; --------------------------------------------------------------------------------------------------------------------

; Line 0: RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+10), the 10 standing for
; 59
;
; USR (PROG+59): PEEK 23635 + 256*PEEK 23636 is PROG, the system variable at
; $5C53. The number's digits say 10, its hidden five-byte form says 59 ($3B),
; the offset of Stage1. Known from the bytes and c1 (Stage1 entered at frame
; 2028).
BasicLine0:
  DEFB $00,$00
  DEFB $37,$00            ; the line's length, 55
  DEFB $10,$00,$11,$00,$F9,$C0,$28,$28 ; RANDOMIZE ($F9) USR ($C0) "((" PEEK
  DEFB $BE,$32,$33,$36,$33,$35,$0E,$00 ; ($BE) "23635" and $0E, 23635 = $5C53
  DEFB $00,$53
  DEFB $5C,$00,$2B,$32,$35,$36,$0E,$00 ; "+256*" and $0E, 256, "*" PEEK ($BE)
  DEFB $00,$00,$01,$00,$2A,$BE,$32,$33 ; "23636" and $0E, 23636 = $5C54
  DEFB $36,$33,$36,$0E,$00,$00
  DEFB $54,$5C,$00,$29,$2B,$31,$30,$0E ; ")+" "10" and $0E with the value 59
  DEFB $00,$00,$3B,$00,$00,$29         ; ($3B), ")"
  DEFB $0D                ; ENTER

; Clear the screen, copy the chain to $AC38-$BF0C and return into it
;
; Interrupts off; the screen and attributes ($4000-$5AFF) zeroed by LDIR, the
; border black. Then the 4821 bytes from PROG+95 (the address read from $5C53,
; so the copy works wherever PROG is) to $AC38, with SP = $8000 and $AC38
; pushed as the return address: the RET enters the chain. c1: L1 1, frame 2028.
Stage1:
  DI
  LD HL,$4000
  LD DE,$4001
  LD BC,$1AFF
  LD (HL),L
  LDIR
  XOR A
  OUT ($FE),A
  LD HL,($5C53)
  LD DE,$005F
  ADD HL,DE
  LD DE,$AC38
  LD BC,$12D5
  LD SP,$8000
  PUSH DE
  LDIR
  RET

; The decryption chain as the tape holds it (4821 bytes, copied to $AC38)
;
; tools/speedlock.py master writes these bytes from the plain view
; src/loader/chain.asm: every layer's rewrite undone, in reverse order. The
; build INCBINs build/chain-tape.bin.
ChainTape:
  INCBIN "chain-tape.bin",$0000,4821

; The program's last byte, $55, past the copy: no code reads it
;
; Stage1 copies 4821 bytes and the program is 4917: this byte after them is
; never copied or read (c1: no L1 read). Kept as it is.
BasicEnd:
  DEFB $55
