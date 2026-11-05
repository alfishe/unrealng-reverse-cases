; UltraXOR v1.2: the decrypting loops 1-76, $7758-$7FC9, in their plain form (included by a-nether.asm).
; Written once from the file decrypted by tools/ultraxor.py (z80dasm, one block per loop); the source now.
; The loops are machine-made (polymorphic): each decrypts the next one, from
; its own DJNZ displacement byte to the next loop's DJNZ: HL the first byte, B the count; per byte
; LD A,R, then operations on A with registers the loops keep changing, XOR (HL), LD (HL),A. The LD SP,HL /
; LD SP,IX are against a debugger (a breakpoint or an interrupt would push onto the code); the ED xx with no
; instruction are 8-T NOPs (two fetches: R + 2), there to change R.

; Layer 1, $7758: decrypts $7766-$7785 (32 bytes)
Layer1:
    LD HL,$7766
    LD B,$20
    LD A,R
    INC C
    NOP
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-8

; Layer 2, $7767: decrypts $7786-$7793 (14 bytes)
Layer2:
    LD HL,$7786
    LD B,$0E
    LD A,R
    NEG
    XOR $15
    DEC E
    INC C
    IM 2
    NEG
    CPL
    DB $ED,$4E                  ; IM 0/1, undocumented
    XOR IXL                    ; $DD $AD
    DEC IXL                    ; $DD $2D
    DEC E
    ADD A,H
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-25

; Layer 3, $7787: decrypts $7794-$77A1 (14 bytes)
Layer3:
    LD HL,$7794
    LD B,$0E
    LD A,R
    NOP
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-7

; Layer 4, $7795: decrypts $77A2-$77B8 (23 bytes)
Layer4:
    LD HL,$77A2
    LD B,$17
    LD A,R
    NOP
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-7

; Layer 5, $77A3: decrypts $77B9-$77D5 (29 bytes)
Layer5:
    LD HL,$77B9
    LD B,$1D
    LD A,R
    ADD A,H
    XOR $63
    DB $ED,$4E                  ; IM 0/1, undocumented
    INC IXL                    ; $DD $2C
    SUB IXH                    ; $DD $94
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-16

; Layer 6, $77BA: decrypts $77D6-$77FA (37 bytes)
Layer6:
    LD HL,$77D6
    LD B,$25
    LD A,R
    SUB C
    RRCA
    XOR H
    NOP
    INC C
    NEG
    XOR IYH                    ; $FD $AC
    INC C
    IM 2
    NOP
    NOP
    NEG
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-22

; Layer 7, $77D7: decrypts $77FB-$780F (21 bytes)
Layer7:
    LD HL,$77FB
    LD B,$15
    LD A,R
    INC C
    NEG
    RRCA
    NEG
    XOR $3B
    NEG
    DEC D
    XOR $13
    NEG
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    ADD A,IYH                  ; $FD $84
    XOR IYH                    ; $FD $AC
    XOR IYH                    ; $FD $AC
    XOR $F9
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-30

; Layer 8, $77FC: decrypts $7810-$7828 (25 bytes)
Layer8:
    LD HL,$7810
    LD B,$19
    LD A,R
    INC C
    SUB H
    XOR B
    XOR IYL                    ; $FD $AD
    SUB C
    NEG
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-14

; Layer 9, $7811: decrypts $7829-$7850 (40 bytes)
Layer9:
    LD HL,$7829
    LD B,$28
    LD A,R
    NEG
    XOR $64
    XOR IYH                    ; $FD $AC
    IM 2
    INC D
    XOR H
    SUB IXH                    ; $DD $94
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-18

; Layer 10, $782A: decrypts $7851-$7876 (38 bytes)
Layer10:
    LD HL,$7851
    LD B,$26
    LD A,R
    RLCA
    INC IXH                    ; $DD $24
    XOR IYH                    ; $FD $AC
    NEG
    XOR IYH                    ; $FD $AC
    SUB H
    RLCA
    NOP
    XOR IXL                    ; $DD $AD
    NEG
    ADD A,IYH                  ; $FD $84
    XOR IYH                    ; $FD $AC
    XOR $36
    RLCA
    XOR IYH                    ; $FD $AC
    DEC IXL                    ; $DD $2D
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-33

; Layer 11, $7852: decrypts $7877-$7884 (14 bytes)
Layer11:
    LD HL,$7877
    LD B,$0E
    LD A,R
    XOR IXL                    ; $DD $AD
    DEC E
    DB $ED,$4E                  ; IM 0/1, undocumented
    SUB B
    DEC E
    NOP
    DB $ED,$4E                  ; IM 0/1, undocumented
    ADD A,H
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    NEG
    DB $ED,$4E                  ; IM 0/1, undocumented
    ADD A,B
    INC IXH                    ; $DD $24
    LD A,R
    IM 2
    LD SP,IX
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-31

; Layer 12, $7878: decrypts $7885-$78A9 (37 bytes)
Layer12:
    LD HL,$7885
    LD B,$25
    LD A,R
    NOP
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-7

; Layer 13, $7886: decrypts $78AA-$78BD (20 bytes)
Layer13:
    LD HL,$78AA
    LD B,$14
    LD A,R
    XOR H
    NEG
    XOR IYH                    ; $FD $AC
    DB $ED,$6E                  ; IM 0, undocumented
    DEC D
    IM 2
    NEG
    XOR L
    SUB C
    ADD A,C
    DB $ED,$6E                  ; IM 0, undocumented
    ADD A,IXH                  ; $DD $84
    SUB H
    XOR IYH                    ; $FD $AC
    XOR B
    LD SP,IX
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-30

; Layer 14, $78AB: decrypts $78BE-$78D4 (23 bytes)
Layer14:
    LD HL,$78BE
    LD B,$17
    LD A,R
    DEC IXH                    ; $DD $25
    IM 2
    XOR L
    ADD A,C
    RRCA
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-13

; Layer 15, $78BF: decrypts $78D5-$78F0 (28 bytes)
Layer15:
    LD HL,$78D5
    LD B,$1C
    LD A,R
    SUB C
    INC D
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$4E                  ; IM 0/1, undocumented
    XOR IXL                    ; $DD $AD
    NOP
    XOR H
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-16

; Layer 16, $78D6: decrypts $78F1-$78FE (14 bytes)
Layer16:
    LD HL,$78F1
    LD B,$0E
    LD A,R
    IM 2
    NOP
    XOR L
    DEC D
    IM 2
    ADD A,H
    ADD A,IYH                  ; $FD $84
    CPL
    XOR IYH                    ; $FD $AC
    INC IXH                    ; $DD $24
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-21

; Layer 17, $78F2: decrypts $78FF-$7919 (27 bytes)
Layer17:
    LD HL,$78FF
    LD B,$1B
    LD A,R
    NOP
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-7

; Layer 18, $7900: decrypts $791A-$7937 (30 bytes)
Layer18:
    LD HL,$791A
    LD B,$1E
    LD A,R
    INC C
    IM 2
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    NEG
    NEG
    INC IXH                    ; $DD $24
    NEG
    SUB B
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-20

; Layer 19, $791B: decrypts $7938-$7957 (32 bytes)
Layer19:
    LD HL,$7938
    LD B,$20
    LD A,R
    ADD A,C
    INC IXH                    ; $DD $24
    IM 2
    NEG
    XOR $77
    INC D
    INC IXH                    ; $DD $24
    ADD A,IXH                  ; $DD $84
    NEG
    XOR $F9
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-23

; Layer 20, $7939: decrypts $7958-$7978 (33 bytes)
Layer20:
    LD HL,$7958
    LD B,$21
    LD A,R
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    XOR $49
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    XOR B
    XOR $7C
    XOR $7C
    XOR $49
    XOR $7C
    DB $ED,$6E                  ; IM 0, undocumented
    INC D
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-25

; Layer 21, $7959: decrypts $7979-$7990 (24 bytes)
Layer21:
    LD HL,$7979
    LD B,$18
    LD A,R
    DB $ED,$6E                  ; IM 0, undocumented
    ADD A,IYH                  ; $FD $84
    ADD A,H
    XOR H
    SUB C
    NOP
    RLCA
    XOR $46
    XOR H
    DB $ED,$4E                  ; IM 0/1, undocumented
    NEG
    NOP
    CPL
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-26

; Layer 22, $797A: decrypts $7991-$79A2 (18 bytes)
Layer22:
    LD HL,$7991
    LD B,$12
    LD A,R
    XOR $3C
    NEG
    XOR IYH                    ; $FD $AC
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    DEC IXH                    ; $DD $25
    DEC C
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-17

; Layer 23, $7992: decrypts $79A3-$79C8 (38 bytes)
Layer23:
    LD HL,$79A3
    LD B,$26
    LD A,R
    DEC D
    XOR H
    SUB B
    ADD A,IYH                  ; $FD $84
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-11

; Layer 24, $79A4: decrypts $79C9-$79ED (37 bytes)
Layer24:
    LD HL,$79C9
    LD B,$25
    LD A,R
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$6E                  ; IM 0, undocumented
    NEG
    XOR IYL                    ; $FD $AD
    ADD A,IYH                  ; $FD $84
    NEG
    DEC E
    RRCA
    XOR $1E
    XOR IXL                    ; $DD $AD
    XOR $1E
    CPL
    CPL
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-31

; Layer 25, $79CA: decrypts $79EE-$7A0C (31 bytes)
Layer25:
    LD HL,$79EE
    LD B,$1F
    LD A,R
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    NEG
    NEG
    SUB H
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    ADD A,H
    NOP
    LD A,R
    INC E
    DEC IXL                    ; $DD $2D
    INC D
    NEG
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-30

; Layer 26, $79EF: decrypts $7A0D-$7A37 (43 bytes)
Layer26:
    LD HL,$7A0D
    LD B,$2B
    LD A,R
    DEC IXH                    ; $DD $25
    DB $ED,$4E                  ; IM 0/1, undocumented
    NEG
    RRCA
    DEC IXL                    ; $DD $2D
    XOR $77
    DB $ED,$6E                  ; IM 0, undocumented
    INC D
    XOR $77
    IM 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-24

; Layer 27, $7A0E: decrypts $7A38-$7A62 (43 bytes)
Layer27:
    LD HL,$7A38
    LD B,$2B
    LD A,R
    SUB B
    DEC IXL                    ; $DD $2D
    RRCA
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    NEG
    XOR B
    CPL
    NEG
    DEC IXL                    ; $DD $2D
    INC E
    XOR IYL                    ; $FD $AD
    DB $ED,$6E                  ; IM 0, undocumented
    IM 2
    NEG
    SUB H
    XOR H
    XOR IYL                    ; $FD $AD
    IM 2
    LD SP,IX
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-36

; Layer 28, $7A39: decrypts $7A63-$7A75 (19 bytes)
Layer28:
    LD HL,$7A63
    LD B,$13
    LD A,R
    INC IXH                    ; $DD $24
    XOR B
    XOR $4B
    SUB IXH                    ; $DD $94
    NEG
    XOR IYH                    ; $FD $AC
    INC IXL                    ; $DD $2C
    ADD A,H
    XOR IXL                    ; $DD $AD
    SUB IXH                    ; $DD $94
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$4E                  ; IM 0/1, undocumented
    ADD A,IXH                  ; $DD $84
    INC C
    NEG
    XOR H
    XOR $4B
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-36

; Layer 29, $7A64: decrypts $7A76-$7A8C (23 bytes)
Layer29:
    LD HL,$7A76
    LD B,$17
    LD A,R
    DEC C
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$4E                  ; IM 0/1, undocumented
    CPL
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-12

; Layer 30, $7A77: decrypts $7A8D-$7AB1 (37 bytes)
Layer30:
    LD HL,$7A8D
    LD B,$25
    LD A,R
    SUB H
    RLCA
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    XOR $5F
    XOR L
    SUB H
    XOR $5F
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-16

; Layer 31, $7A8E: decrypts $7AB2-$7AC4 (19 bytes)
Layer31:
    LD HL,$7AB2
    LD B,$13
    LD A,R
    ADD A,H
    LD A,R
    XOR IXL                    ; $DD $AD
    DB $ED,$4E                  ; IM 0/1, undocumented
    DEC IXH                    ; $DD $25
    XOR $62
    XOR IYH                    ; $FD $AC
    DEC IXH                    ; $DD $25
    LD A,R
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    INC D
    XOR IYH                    ; $FD $AC
    IM 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-30

; Layer 32, $7AB3: decrypts $7AC5-$7AD3 (15 bytes)
Layer32:
    LD HL,$7AC5
    LD B,$0F
    LD A,R
    NEG
    DEC IXL                    ; $DD $2D
    XOR IYH                    ; $FD $AC
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-12

; Layer 33, $7AC6: decrypts $7AD4-$7AFE (43 bytes)
Layer33:
    LD HL,$7AD4
    LD B,$2B
    LD A,R
    SUB IXH                    ; $DD $94
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-8

; Layer 34, $7AD5: decrypts $7AFF-$7B1D (31 bytes)
Layer34:
    LD HL,$7AFF
    LD B,$1F
    LD A,R
    XOR $14
    DEC D
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    DEC E
    NEG
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    IM 2
    XOR B
    SUB H
    NOP
    DB $ED,$6E                  ; IM 0, undocumented
    ADD A,IXH                  ; $DD $84
    XOR $17
    RLCA
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-36

; Layer 35, $7B00: decrypts $7B1E-$7B2B (14 bytes)
Layer35:
    LD HL,$7B1E
    LD B,$0E
    LD A,R
    DEC IXH                    ; $DD $25
    LD A,R
    DEC E
    XOR IXL                    ; $DD $AD
    XOR $17
    ADD A,C
    DEC D
    ADD A,IXH                  ; $DD $84
    INC E
    XOR $37
    NEG
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-24

; Layer 36, $7B1F: decrypts $7B2C-$7B40 (21 bytes)
Layer36:
    LD HL,$7B2C
    LD B,$15
    LD A,R
    NOP
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-7

; Layer 37, $7B2D: decrypts $7B41-$7B58 (24 bytes)
Layer37:
    LD HL,$7B41
    LD B,$18
    LD A,R
    DEC D
    DB $ED,$4E                  ; IM 0/1, undocumented
    SUB IXH                    ; $DD $94
    XOR IYH                    ; $FD $AC
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-14

; Layer 38, $7B42: decrypts $7B59-$7B7C (36 bytes)
Layer38:
    LD HL,$7B59
    LD B,$24
    LD A,R
    NEG
    ADD A,IYH                  ; $FD $84
    XOR IXL                    ; $DD $AD
    SUB H
    ADD A,C
    SUB C
    DB $ED,$4E                  ; IM 0/1, undocumented
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-17

; Layer 39, $7B5A: decrypts $7B7D-$7B97 (27 bytes)
Layer39:
    LD HL,$7B7D
    LD B,$1B
    LD A,R
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    DEC D
    DEC D
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    DEC IXL                    ; $DD $2D
    XOR IXL                    ; $DD $AD
    NOP
    XOR $21
    NEG
    XOR $21
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-29

; Layer 40, $7B7E: decrypts $7B98-$7BB3 (28 bytes)
Layer40:
    LD HL,$7B98
    LD B,$1C
    LD A,R
    IM 2
    NEG
    DB $ED,$4E                  ; IM 0/1, undocumented
    XOR IYH                    ; $FD $AC
    NEG
    XOR L
    XOR IYL                    ; $FD $AD
    INC C
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-20

; Layer 41, $7B99: decrypts $7BB4-$7BD2 (31 bytes)
Layer41:
    LD HL,$7BB4
    LD B,$1F
    LD A,R
    DB $ED,$6E                  ; IM 0, undocumented
    INC IXL                    ; $DD $2C
    SUB IXH                    ; $DD $94
    NEG
    XOR IYL                    ; $FD $AD
    IM 2
    XOR $00
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-21

; Layer 42, $7BB5: decrypts $7BD3-$7BFA (40 bytes)
Layer42:
    LD HL,$7BD3
    LD B,$28
    LD A,R
    NEG
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    SUB H
    DEC IXL                    ; $DD $2D
    DEC D
    IM 2
    XOR IXL                    ; $DD $AD
    NEG
    DEC IXL                    ; $DD $2D
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-24

; Layer 43, $7BD4: decrypts $7BFB-$7C08 (14 bytes)
Layer43:
    LD HL,$7BFB
    LD B,$0E
    LD A,R
    NOP
    NOP
    SUB C
    DEC IXL                    ; $DD $2D
    RLCA
    INC E
    SUB C
    XOR IYL                    ; $FD $AD
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$6E                  ; IM 0, undocumented
    DEC IXH                    ; $DD $25
    NOP
    INC IXH                    ; $DD $24
    DEC C
    NEG
    IM 2
    DEC D
    CPL
    XOR H
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-33

; Layer 44, $7BFC: decrypts $7C09-$7C29 (33 bytes)
Layer44:
    LD HL,$7C09
    LD B,$21
    LD A,R
    NOP
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-7

; Layer 45, $7C0A: decrypts $7C2A-$7C3A (17 bytes)
Layer45:
    LD HL,$7C2A
    LD B,$11
    LD A,R
    IM 2
    INC D
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    XOR IYH                    ; $FD $AC
    XOR IYH                    ; $FD $AC
    DB $ED,$4E                  ; IM 0/1, undocumented
    XOR IYH                    ; $FD $AC
    RLCA
    NOP
    INC E
    INC IXL                    ; $DD $2C
    INC IXL                    ; $DD $2C
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-26

; Layer 46, $7C2B: decrypts $7C3B-$7C5C (34 bytes)
Layer46:
    LD HL,$7C3B
    LD B,$22
    LD A,R
    XOR H
    INC C
    ADD A,IXH                  ; $DD $84
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-10

; Layer 47, $7C3C: decrypts $7C5D-$7C75 (25 bytes)
Layer47:
    LD HL,$7C5D
    LD B,$19
    LD A,R
    NEG
    NEG
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    NEG
    IM 2
    RLCA
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    XOR IYL                    ; $FD $AD
    LD A,R
    ADD A,C
    DEC IXL                    ; $DD $2D
    INC E
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-27

; Layer 48, $7C5E: decrypts $7C76-$7C8D (24 bytes)
Layer48:
    LD HL,$7C76
    LD B,$18
    LD A,R
    ADD A,IYH                  ; $FD $84
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    DB $ED,$4E                  ; IM 0/1, undocumented
    DEC D
    SUB B
    NEG
    XOR IXL                    ; $DD $AD
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-18

; Layer 49, $7C77: decrypts $7C8E-$7CA9 (28 bytes)
Layer49:
    LD HL,$7C8E
    LD B,$1C
    LD A,R
    NEG
    ADD A,H
    XOR IYH                    ; $FD $AC
    DEC IXH                    ; $DD $25
    INC C
    XOR $79
    INC C
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-17

; Layer 50, $7C8F: decrypts $7CAA-$7CC2 (25 bytes)
Layer50:
    LD HL,$7CAA
    LD B,$19
    LD A,R
    INC IXH                    ; $DD $24
    SUB H
    XOR $7D
    NEG
    RLCA
    ADD A,H
    LD A,R
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$6E                  ; IM 0, undocumented
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-21

; Layer 51, $7CAB: decrypts $7CC3-$7CEF (45 bytes)
Layer51:
    LD HL,$7CC3
    LD B,$2D
    LD A,R
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$6E                  ; IM 0, undocumented
    SUB B
    XOR IYH                    ; $FD $AC
    DEC E
    IM 2
    IM 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-18

; Layer 52, $7CC4: decrypts $7CF0-$7D12 (35 bytes)
Layer52:
    LD HL,$7CF0
    LD B,$23
    LD A,R
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    SUB IXH                    ; $DD $94
    NEG
    SUB IXH                    ; $DD $94
    ADD A,IXH                  ; $DD $84
    INC C
    NEG
    ADD A,IYH                  ; $FD $84
    DB $ED,$6E                  ; IM 0, undocumented
    NEG
    ADD A,C
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    XOR IYL                    ; $FD $AD
    XOR $79
    XOR B
    NOP
    XOR $4C
    XOR IYH                    ; $FD $AC
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-38

; Layer 53, $7CF1: decrypts $7D13-$7D3A (40 bytes)
Layer53:
    LD HL,$7D13
    LD B,$28
    LD A,R
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$4E                  ; IM 0/1, undocumented
    ADD A,IYH                  ; $FD $84
    NEG
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$4E                  ; IM 0/1, undocumented
    NOP
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    DEC E
    XOR $7D
    ADD A,H
    DEC IXL                    ; $DD $2D
    SUB H
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-28

; Layer 54, $7D14: decrypts $7D3B-$7D4A (16 bytes)
Layer54:
    LD HL,$7D3B
    LD B,$10
    LD A,R
    LD A,R
    SUB IXH                    ; $DD $94
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    DB $ED,$4E                  ; IM 0/1, undocumented
    ADD A,IYH                  ; $FD $84
    SUB C
    RLCA
    INC IXL                    ; $DD $2C
    DB $ED,$4E                  ; IM 0/1, undocumented
    INC IXH                    ; $DD $24
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    XOR $11
    LD A,R
    XOR L
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-33

; Layer 55, $7D3C: decrypts $7D4B-$7D65 (27 bytes)
Layer55:
    LD HL,$7D4B
    LD B,$1B
    LD A,R
    XOR IYL                    ; $FD $AD
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-9

; Layer 56, $7D4C: decrypts $7D66-$7D85 (32 bytes)
Layer56:
    LD HL,$7D66
    LD B,$20
    LD A,R
    DEC IXL                    ; $DD $2D
    INC IXL                    ; $DD $2C
    XOR B
    DB $ED,$4E                  ; IM 0/1, undocumented
    IM 2
    XOR IYH                    ; $FD $AC
    DEC C
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-20

; Layer 57, $7D67: decrypts $7D86-$7DAD (40 bytes)
Layer57:
    LD HL,$7D86
    LD B,$28
    LD A,R
    XOR B
    XOR L
    DEC E
    DB $ED,$6E                  ; IM 0, undocumented
    INC IXH                    ; $DD $24
    DB $ED,$4E                  ; IM 0/1, undocumented
    XOR $3A
    LD A,R
    ADD A,H
    XOR $3A
    INC C
    NEG
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-25

; Layer 58, $7D87: decrypts $7DAE-$7DC1 (20 bytes)
Layer58:
    LD HL,$7DAE
    LD B,$14
    LD A,R
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$6E                  ; IM 0, undocumented
    RLCA
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    NEG
    XOR L
    INC C
    SUB C
    DEC C
    INC IXL                    ; $DD $2C
    ADD A,H
    ADD A,IXH                  ; $DD $84
    LD A,R
    RRCA
    ADD A,B
    XOR $7D
    CPL
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-33

; Layer 59, $7DAF: decrypts $7DC2-$7DDB (26 bytes)
Layer59:
    LD HL,$7DC2
    LD B,$1A
    LD A,R
    RLCA
    XOR H
    XOR $04
    RLCA
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-13

; Layer 60, $7DC3: decrypts $7DDC-$7DF4 (25 bytes)
Layer60:
    LD HL,$7DDC
    LD B,$19
    LD A,R
    XOR $21
    DB $ED,$4E                  ; IM 0/1, undocumented
    DB $ED,$6E                  ; IM 0, undocumented
    ADD A,IXH                  ; $DD $84
    NEG
    ADD A,IYH                  ; $FD $84
    RLCA
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-19

; Layer 61, $7DDD: decrypts $7DF5-$7E1B (39 bytes)
Layer61:
    LD HL,$7DF5
    LD B,$27
    LD A,R
    SUB IXH                    ; $DD $94
    DB $ED,$6E                  ; IM 0, undocumented
    DEC IXL                    ; $DD $2D
    INC C
    DEC C
    DEC D
    INC IXH                    ; $DD $24
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-18

; Layer 62, $7DF6: decrypts $7E1C-$7E2A (15 bytes)
Layer62:
    LD HL,$7E1C
    LD B,$0F
    LD A,R
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    INC IXL                    ; $DD $2C
    DB $ED,$6E                  ; IM 0, undocumented
    LD A,R
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    RLCA
    DEC D
    XOR IYL                    ; $FD $AD
    IM 2
    ADD A,C
    XOR $6F
    XOR IXL                    ; $DD $AD
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-32

; Layer 63, $7E1D: decrypts $7E2B-$7E40 (22 bytes)
Layer63:
    LD HL,$7E2B
    LD B,$16
    LD A,R
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-8

; Layer 64, $7E2C: decrypts $7E41-$7E4F (15 bytes)
Layer64:
    LD HL,$7E41
    LD B,$0F
    LD A,R
    DB $ED,$6E                  ; IM 0, undocumented
    NEG
    RLCA
    NEG
    DB $ED,$4E                  ; IM 0/1, undocumented
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-15

; Layer 65, $7E42: decrypts $7E50-$7E6B (28 bytes)
Layer65:
    LD HL,$7E50
    LD B,$1C
    LD A,R
    LD A,R
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-8

; Layer 66, $7E51: decrypts $7E6C-$7E85 (26 bytes)
Layer66:
    LD HL,$7E6C
    LD B,$1A
    LD A,R
    ADD A,C
    LD A,R
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    IM 2
    DEC IXL                    ; $DD $2D
    CPL
    XOR IYH                    ; $FD $AC
    SUB C
    XOR IYH                    ; $FD $AC
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-21

; Layer 67, $7E6D: decrypts $7E86-$7EAC (39 bytes)
Layer67:
    LD HL,$7E86
    LD B,$27
    LD A,R
    XOR IYL                    ; $FD $AD
    NEG
    XOR L
    DEC IXL                    ; $DD $2D
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    XOR IXL                    ; $DD $AD
    ADD A,IYH                  ; $FD $84
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-19

; Layer 68, $7E87: decrypts $7EAD-$7ECD (33 bytes)
Layer68:
    LD HL,$7EAD
    LD B,$21
    LD A,R
    SUB C
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    ADD A,C
    INC E
    INC E
    XOR $6E
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    XOR $6E
    IM 2
    NEG
    XOR IYL                    ; $FD $AD
    IM 2
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$4E                  ; IM 0/1, undocumented
    SUB IXH                    ; $DD $94
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-32

; Layer 69, $7EAE: decrypts $7ECE-$7EE9 (28 bytes)
Layer69:
    LD HL,$7ECE
    LD B,$1C
    LD A,R
    RRCA
    RLCA
    RLCA
    NOP
    XOR H
    INC IXL                    ; $DD $2C
    NEG
    DB $ED,$6E                  ; IM 0, undocumented
    IM 2
    IM 2
    SUB H
    RLCA
    RRCA
    XOR H
    XOR H
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-26

; Layer 70, $7ECF: decrypts $7EEA-$7F08 (31 bytes)
Layer70:
    LD HL,$7EEA
    LD B,$1F
    LD A,R
    ADD A,C
    LD A,R
    SUB B
    NOP
    RLCA
    XOR H
    XOR $75
    XOR IYL                    ; $FD $AD
    RRCA
    ADD A,IXH                  ; $DD $84
    SUB H
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-21

; Layer 71, $7EEB: decrypts $7F09-$7F31 (41 bytes)
Layer71:
    LD HL,$7F09
    LD B,$29
    LD A,R
    XOR IYH                    ; $FD $AC
    NEG
    NOP
    NOP
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    LD A,R
    XOR H
    NOP
    XOR $3B
    XOR H
    DB $ED,$04                  ; ED NOP (undocumented): R + 2
    XOR $F9
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-24

; Layer 72, $7F0A: decrypts $7F32-$7F5E (45 bytes)
Layer72:
    LD HL,$7F32
    LD B,$2D
    LD A,R
    DEC D
    XOR H
    INC IXL                    ; $DD $2C
    XOR $1A
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    DB $ED,$6E                  ; IM 0, undocumented
    XOR $53
    INC D
    XOR IYL                    ; $FD $AD
    XOR L
    DB $ED,$6E                  ; IM 0, undocumented
    NEG
    INC IXL                    ; $DD $2C
    XOR IXL                    ; $DD $AD
    NOP
    DB $ED,$6E                  ; IM 0, undocumented
    XOR L
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-34

; Layer 73, $7F33: decrypts $7F5F-$7F8A (44 bytes)
Layer73:
    LD HL,$7F5F
    LD B,$2C
    LD A,R
    INC E
    LD A,R
    DB $ED,$4E                  ; IM 0/1, undocumented
    DEC D
    XOR H
    DEC E
    XOR $08
    DEC IXL                    ; $DD $2D
    XOR IYH                    ; $FD $AC
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    DB $ED,$6E                  ; IM 0, undocumented
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    SUB C
    SUB H
    DB $ED,$4E                  ; IM 0/1, undocumented
    XOR L
    XOR IYH                    ; $FD $AC
    ADD A,B
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    ADD A,C
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-38

; Layer 74, $7F60: decrypts $7F8B-$7FA0 (22 bytes)
Layer74:
    LD HL,$7F8B
    LD B,$16
    LD A,R
    IM 2
    INC IXH                    ; $DD $24
    XOR H
    DB $ED,$0D                  ; ED NOP (undocumented): R + 2
    RRCA
    XOR $19
    LD A,R
    SUB IXH                    ; $DD $94
    DB $ED,$4E                  ; IM 0/1, undocumented
    IM 2
    NOP
    IM 2
    XOR IXL                    ; $DD $AD
    IM 2
    DB $ED,$6E                  ; IM 0, undocumented
    ADD A,C
    XOR IYL                    ; $FD $AD
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-37

; Layer 75, $7F8C: decrypts $7FA1-$7FC8 (40 bytes)
Layer75:
    LD HL,$7FA1
    LD B,$28
    LD A,R
    XOR $34
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    IM 2
    INC IXH                    ; $DD $24
    DB $ED,$F9                  ; ED NOP (undocumented): R + 2
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-15

; Layer 76, $7FA2: decrypts $7FC9-$7FE9 (33 bytes)
Layer76:
    LD HL,$7FC9
    LD B,$21
    LD A,R
    NOP
    DB $ED,$4E                  ; IM 0/1, undocumented
    SUB IXH                    ; $DD $94
    NOP
    XOR IYH                    ; $FD $AC
    XOR $13
    INC IXL                    ; $DD $2C
    NEG
    XOR L
    NOP
    INC C
    INC IXL                    ; $DD $2C
    IM 2
    DB $ED,$07                  ; ED NOP (undocumented): R + 2
    ADD A,IXH                  ; $DD $84
    XOR $5E
    LD SP,HL
    XOR (HL)
    LD (HL),A
    INC HL
    DJNZ $-33
