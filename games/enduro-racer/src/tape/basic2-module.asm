; --------------------------------------------------------------------------------------------------------------------
; basic2-module.asm: The second BASIC: lines that aim the error return at VARS, and Chain1 in the variables area
;
; Five lines numbered 0 and a sixth that is no line. The digits LIST shows differ from the hidden numbers where it
; matters: line 4 shows PEEK 23633 and 23647 but uses 23613 (ERR_SP) and 23627 (VARS), so it pokes VARS ($621A) into
; the word ERR_SP points at ($FFFA, set by the first BASIC's Stage0). The interpreter then reaches the sixth line,
; number 40079 with a length of 42626, whose bytes are LoaderTape: the error it raises returns through $FFFA into
; Chain1 at VARS.
;
; Chain1 is obfuscated (filler instructions between the real ones): it wipes $63E0-$FF42 with LDIR, sets IM 2 with I
; from the first stage, and runs the R loop Chain1Loop over the 797 bytes of LoaderTape, XORing each with R and
; copying it to $FCA3; the last RET PO enters Chain2 at $FCA3 (src/loader/loader.asm). LoaderTape is assembled from
; loader-tape.bin, which tools/build.sh makes from the loader's plain view with tools/speedlock2.py tape.
; --------------------------------------------------------------------------------------------------------------------

; Line 0: REM "Protected by SPEEDLOCK" in colour codes (length 128)
;
; Read by the ROM's interpreter in c1; no machine code reads any line.
BasicLine0a:
  DEFB $00,$00,$80,$00,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $10,$07,$11,$07,$EA,$11,$07,$10
  DEFB $00,$50,$72,$6F,$74,$65,$63,$74
  DEFB $65,$64,$20,$62,$79,$20,$53,$50
  DEFB $45,$45,$44,$4C,$4F,$43,$4B,$10
  DEFB $07,$11,$07,$0D

; Line 0: BORDER 0: PAPER 0: INK 0: BRIGHT 1: CLS: POKE 23624,0 (BORDCR)
BasicLine0b:
  DEFB $00,$00,$3F,$00,$11,$07,$10,$07
  DEFB $E7,$30,$0E,$00,$00,$00,$00,$00
  DEFB $3A,$DA,$30,$0E,$00,$00,$00,$00
  DEFB $00,$3A,$D9,$30,$0E,$00,$00,$00
  DEFB $00,$00,$3A,$DC,$31,$0E,$00,$00
  DEFB $01,$00,$00,$3A,$FB,$3A,$F4,$32
  DEFB $33,$36,$32,$34,$0E,$00,$00,$48
  DEFB $5C,$00,$2C,$30,$0E,$00,$00,$00
  DEFB $00,$00,$0D

; Line 0: POKE (PEEK 23641+256*PEEK 23642),PEEK 23649 and +1,PEEK 23650:
; E_LINE's word = WORKSP
BasicLine0c:
  DEFB $00,$00,$80,$00,$11,$07,$10,$07
  DEFB $F4,$28,$BE,$10,$07,$32,$33,$36
  DEFB $34,$31,$0E,$8F,$38,$B2,$33,$33
  DEFB $2B,$32,$35,$36,$0E,$00,$00,$00
  DEFB $01,$00,$2A,$BE,$10,$07,$32,$33
  DEFB $36,$34,$32,$0E,$8F,$38,$B4,$99
  DEFB $9A,$29,$2C,$BE,$10,$07,$32,$33
  DEFB $36,$34,$39,$0E,$8F,$38,$C2,$66
  DEFB $66,$3A,$F4,$28,$BE,$10,$07,$32
  DEFB $33,$36,$34,$31,$0E,$8F,$38,$B2
  DEFB $33,$33,$2B,$32,$35,$36,$0E,$00
  DEFB $00,$00,$01,$00,$2A,$BE,$10,$07
  DEFB $32,$33,$36,$34,$32,$0E,$8F,$38
  DEFB $B4,$99,$9A,$29,$2B,$31,$0E,$00
  DEFB $00,$01,$00,$00,$2C,$BE,$10,$07
  DEFB $32,$33,$36,$35,$30,$0E,$8F,$38
  DEFB $C4,$66,$66,$0D

; Line 0: the same POKEs shown as 23633/23634/23647/23648, hidden
; 23613/23614/23627/23628: (ERR_SP) = VARS
;
; The shown digits are decoys; the five-byte numbers the interpreter uses are
; ERR_SP (23613) and VARS (23627). ERR_SP is $FFFA (Stage0), VARS is $621A: the
; ROM's POKE writes $1A,$62 to $FFFA-$FFFB (c1 frames 1557-1562).
BasicLine0d:
  DEFB $00,$00,$80,$00,$11,$07,$10,$07
  DEFB $F4,$28,$BE,$10,$07,$32,$33,$36
  DEFB $33,$33,$0E,$8F,$38,$7A,$33,$33
  DEFB $2B,$32,$35,$36,$0E,$00,$00,$00
  DEFB $01,$00,$2A,$BE,$10,$07,$32,$33
  DEFB $36,$33,$34,$0E,$8F,$38,$7C,$66
  DEFB $66,$29,$2C,$BE,$10,$07,$32,$33
  DEFB $36,$34,$37,$0E,$8F,$38,$96,$99
  DEFB $9A,$3A,$F4,$28,$BE,$10,$07,$32
  DEFB $33,$36,$33,$33,$0E,$8F,$38,$7A
  DEFB $33,$33,$2B,$32,$35,$36,$0E,$00
  DEFB $00,$00,$01,$00,$2A,$BE,$10,$07
  DEFB $32,$33,$36,$33,$34,$0E,$8F,$38
  DEFB $7C,$66,$66,$29,$2B,$31,$0E,$00
  DEFB $00,$01,$00,$00,$2C,$BE,$10,$07
  DEFB $32,$33,$36,$34,$38,$0E,$8F,$38
  DEFB $98,$99,$9A,$0D

; Line 0: POKE 23662,PEEK 23618: POKE 23663,PEEK 23619: POKE 23664,PEEK 23621
; (OLDPPC, OSPPC = NEWPPC, NSPPC)
BasicLine0e:
  DEFB $00,$00,$5E,$00,$11,$07,$10,$07
  DEFB $F4,$10,$07,$32,$33,$36,$36,$32
  DEFB $0E,$8F,$38,$DC,$33,$33,$2C,$BE
  DEFB $10,$07,$32,$33,$36,$31,$38,$0E
  DEFB $8F,$38,$84,$33,$33,$3A,$F4,$10
  DEFB $07,$32,$33,$36,$36,$33,$0E,$8F
  DEFB $38,$DE,$66,$66,$2C,$BE,$10,$07
  DEFB $32,$33,$36,$31,$39,$0E,$8F,$38
  DEFB $86,$33,$33,$3A,$F4,$10,$07,$32
  DEFB $33,$36,$36,$34,$0E,$8F,$38,$E0
  DEFB $33,$33,$2C,$BE,$10,$07,$32,$33
  DEFB $36,$32,$31,$0E,$8F,$38,$8A,$33
  DEFB $33,$0D

; The sixth line's number high byte ($9C): 40079 with LoaderTape's first byte
BasicLine6:
  DEFB $9C

; The loader as the tape holds it (797 bytes): Chain1 XORs it with R into
; $FCA3-$FFBF
;
; src/loader/loader.asm is its plain view; tools/speedlock2.py tape turns that
; view back into these bytes, and tools/build.sh checks the whole tape against
; the original. Read by Chain1Loop in c1 (frames 1575-1576); the interpreter
; also reads its first bytes as the sixth line's header and raises the error.
LoaderTape:
  INCBIN "loader-tape.bin",$0000,797

; Wipe $63E0-$FF42, IM 2, then XOR LoaderTape with R into $FCA3 and enter it
;
; Entered from the ROM's error handling through ERR_SP: the word at $FFFA is
; VARS. Real steps between filler: A = I (from Stage0, $3F); LDIR clears
; $63E0-$FF42 (the RAM the game will use, and any stale loader); IM 2; HL =
; $5EFD, DE = $FCA3, BC = 797, $FCA3 pushed under the loop's own return; R set
; so that the first LD A,R reads $CD (the value the data needs; the count of M1
; cycles before it is known only from the code, because the LDIR's length
; depends on registers the ROM left).
;
; Witness: L1 1 (c1).
Chain1:
  LD L,L
  LD B,L
  LD B,B
  LD A,C
  SUB D
  LD A,I
  LD IXH,D
  LD H,H
  LD D,E
  RET PO
  DEC D
  DEC D
  LD D,D
  EXX
  LD IXL,B
  XOR D
  SBC HL,HL
  XOR E
  DI
  LD L,L
  LD (HL),A
  LD (HL),A
  ADD A,IYH
  XOR IYL
  ADD HL,SP
  LD IYH,D
  LD D,IXH
  XOR IYH
  LD (HL),A
  LD L,B
  LD IYL,C
  LD H,D
  LD IYH,E
  EXX
  LD B,D
  LD D,L
  LD B,A
  RR H
  LD C,A
  LD B,(HL)
  LD B,(HL)
  RR L
  LD E,C
  EXX
  XOR C
  LD E,C
  LD C,A
  LD D,L
  XOR B
  LD B,D
  LD C,C
  LD B,A
  AND A
  LD D,A
  LD B,C
  LD C,H
  LD C,H
  LD E,C
  LD D,IXH
  LD C,IYL
  LD R,A
  LD A,IXL
  LD B,IYH
  LD L,B
  LD E,C
  LD L,A
  LD A,A
  LD L,L
  LD C,D
  LD B,B
  LDIR                    ; the LDIR that wipes $63E0-$FF42
  LD IYH,$FC
  LD C,B
  LD C,A
  XOR $05
  DEC SP
  DEC SP
  LD B,E
  LD C,L
  LD L,L
  SBC HL,DE
  LD IYL,$A3
  LD D,L
  IM 2
  EXX
  LD D,D
  LD C,A
  LD E,L
  EX (SP),IY
  LD B,C
  LD C,(HL)
  LD B,H
  ADC HL,HL
  LD D,IYH
  LD E,IYL
  EX DE,HL
  LD B,D
  LD A,(HL)
  LD D,L
  LD D,B
  SBC HL,DE
  LD C,D
  LD A,E
  LD E,C
  LD C,A
  LD D,L
  LD D,D
  LD D,E
  LD E,A
  LD A,(HL)
  LD B,H
  LD A,I
  LD C,L
  POP HL
  LD D,D
  LD A,H
  RET PE
  PUSH HL
  EX DE,HL
  CALL PO,$3008
Chain1Loop:
  LD A,R                  ; A = R XOR byte, stored in place; LDI to $FCA3+; RET
                          ; PO at the end, RET PE back to the loop
  XOR (HL)
  LD (HL),A
  LDI
  RET PO
  DEC SP
  DEC SP
  RET PE

; The bytes after the loop: a few junk bytes and the SPEEDLOCK credit, never
; run or read
;
; "SPEEDLOCK Protection System (c) DJL Software & D. Aubrey Jones 1984 -
; Tel:0793 724317 * Government Health Warning - Attempting to crack SPEEDLOCK
; can damage your sanity! *" then repeated fragments of the same bytes up to
; the block's end. A leftover the loader never reads (c1: no read after the
; ROM's load).
Chain1Tail:
  DEFB $3B,$3B,$EC,$C7,$83,$5F,$40,$AD
  DEFB $4F,$04,$3B,$D1,$E2,$B0,$64,$53
  DEFB $50,$45,$45,$44,$4C,$4F,$43,$4B
  DEFB $20,$50,$72,$6F,$74,$65,$63,$74
  DEFB $69,$6F,$6E,$20,$53,$79,$73,$74
  DEFB $65,$6D,$20,$7F,$20,$44,$4A,$4C
  DEFB $20,$53,$6F,$66,$74,$77,$61,$72
  DEFB $65,$20,$26,$20,$44,$2E,$20,$41
  DEFB $75,$62,$72,$65,$79,$20,$4A,$6F
  DEFB $6E,$65,$73,$20,$31,$39,$38,$34
  DEFB $20,$2D,$20,$54,$65,$6C,$3A,$30
  DEFB $37,$39,$33,$20,$37,$32,$34,$33
  DEFB $31,$37,$20,$2A,$20,$47,$6F,$76
  DEFB $65,$72,$6E,$6D,$65,$6E,$74,$20
  DEFB $48,$65,$61,$6C,$74,$68,$20,$57
  DEFB $61,$72,$6E,$69,$6E,$67,$20,$2D
  DEFB $20,$41,$74,$74,$65,$6D,$70,$74
  DEFB $69,$6E,$67,$20,$74,$6F,$20,$63
  DEFB $72,$61,$63,$6B,$20,$53,$50,$45
  DEFB $45,$44,$4C,$4F,$43,$4B,$20,$63
  DEFB $61,$6E,$20,$64,$61,$6D,$61,$67
  DEFB $65,$20,$79,$6F,$75,$72,$20,$73
  DEFB $61,$6E,$69,$74,$79,$21,$20,$2A
  DEFB $F3,$52,$FD,$AC,$21,$4F,$7B,$0B
  DEFB $62,$E0,$CC,$8F,$31,$E9,$74,$79
  DEFB $21,$20,$2A,$F3,$52,$FD,$AC,$21
  DEFB $4F,$7B,$0B,$62,$E0,$CC,$8F,$31
  DEFB $E9,$E9,$E9,$31,$E9,$F3,$52,$FD
  DEFB $AC,$21,$4F,$7B,$0B,$62,$E0,$CC
  DEFB $8F,$31,$E9,$20,$73,$61,$6E,$69
  DEFB $74,$79,$21,$20,$2A,$F3,$52
