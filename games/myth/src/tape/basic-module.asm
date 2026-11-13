; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: one line whose USR enters the machine code after it, and the enciphered chain
;
; The program is one line, number 0 (LIST and EDIT never reach a line 0): INK 0, PAPER 0, RANDOMIZE USR ((PEEK
; 23635+256*PEEK 23636)+10). The 10 is only the shown digits: the hidden five-byte number after them is 59, so the USR
; enters PROG+59, the first byte after the line's end mark: CopyChain at $5D06 (PROG = $5CCB in c1).
;
; CopyChain copies the 4418 bytes from PROG+$5F ($5D2A, ChainTape) to $EDE4-$FF25 and returns into them: the
; decryption chain (src/loader/chain.asm, its plain view). ChainTape is assembled from chain-tape.bin, which
; tools/build.sh makes from the plain view with tools/speedlock.py tape.
; --------------------------------------------------------------------------------------------------------------------

; Line 0: INK 0 PAPER 0 RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+10), the 10
; hiding 59
;
; The ROM's line format: the line number high byte first, the length (55) low
; byte first, the tokens, $0D. Each number in the line is its digits followed
; by $0E and the five bytes the interpreter really uses: the digits 23635, 256
; and 23636 carry their own numbers, the digits 10 carry 59. Read by the ROM's
; interpreter in c1; no machine code reads it.
BasicLine0:
BasicLineNumber:
  DEFB $00,$00            ; the line number, high byte first: 0
BasicLineLength:
  DEFB $37,$00            ; the line's length after these four bytes, low byte
                          ; first: 55
  DEFB $10,$00,$11,$00    ; INK 0, PAPER 0 (control codes $10 and $11 with
                          ; their colour)
  DEFB $F9,$C0,$28,$28    ; RANDOMIZE USR ( (
  DEFB $BE,$32,$33,$36,$33,$35,$0E,$00 ; PEEK "23635" and its number 23635
  DEFB $00,$53,$5C,$00                 ; (PROG's low byte)
  DEFB $2B,$32,$35,$36,$0E,$00,$00,$00 ; + "256" and its number
  DEFB $01,$00
  DEFB $2A,$BE,$32,$33,$36,$33,$36,$0E ; * PEEK "23636" and its number (PROG's
  DEFB $00,$00,$54,$5C,$00             ; high byte)
  DEFB $29,$2B,$31,$30,$0E ; ) + "10" and the hidden number
BasicHiddenNumber:
  DEFB $00,$00,$3B,$00,$00 ; the five-byte number the interpreter adds: 59 (the
                           ; shown digits say 10)
  DEFB $29,$0D            ; ) and the end of line mark $0D

; Clear the screen, copy the chain to $EDE4-$FF25 and return into it
;
; Entered by line 0's USR (PROG+59). Interrupts off; clears $4000-$5BFF (the
; bitmap, the attributes and the printer buffer) to zero, so the screen goes
; black; border black. HL = PROG + $5F (ChainTape, found from the system
; variable PROG at 23635 rather than assumed); DE = $EDE4, BC = 4418; SP =
; $8000 with $EDE4 pushed, then LDIR and RET: the RET enters the chain's first
; layer at $EDE4. Side effects: the screen cleared, SP left at $7FFE.
;
; c1: frame 1963; the LDIR at $5D27 wrote $EDE4-$FF25 (docs/03 3.2).
;
; Witness: L1 1 (c1).
CopyChain:
  DI
  LD HL,$4000
  LD DE,$4001
  LD BC,$1BFF
  LD (HL),L
  LDIR
  XOR A
  OUT ($FE),A
  LD HL,($5C53)           ; HL = PROG + $5F: the chain's first byte in the
                          ; program
  LD DE,$005F
  ADD HL,DE
  LD DE,$EDE4
  LD BC,$1142
  LD SP,$8000             ; the RET below goes to $EDE4
  PUSH DE
  LDIR
  RET

; The decryption chain as the tape holds it (4418 bytes, copied to $EDE4)
;
; The bytes of $EDE4-$FF25 before any layer ran. src/loader/chain.asm is their
; plain view (each byte after the last layer that rewrites it);
; tools/speedlock.py tape turns the plain view back into these bytes, and
; tools/build.sh checks the whole tape against the original. Read by
; CopyChain's LDIR in c1.
ChainTape:
  INCBIN "chain-tape.bin",$0000,4418

; The block's last byte, past the copy: a zero no code reads
;
; CopyChain copies 4418 bytes, $5D2A-$6E6B; the block's 4514 bytes end one byte
; later. Nothing reads the zero after the ROM's load (c1: CopyChain's LDIR
; stops at $6E6B), a byte of the BASIC block left over past the chain.
BasicEnd:
  DEFB $00
