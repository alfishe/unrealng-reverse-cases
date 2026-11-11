; --------------------------------------------------------------------------------------------------------------------
; chain-module.asm: The decryption chain: 103 layers, each rewriting the rest and running into it
;
; Stage1 (src/tape/basic.asm) returns into $AC38. Each layer first shifts the 30 bytes behind its own LDDR down by
; one, which garbles the code already run, then rewrites every byte from its own end up to $BF0C and falls into the
; bytes it has just rewritten: the next layer. Three kinds of rewrite take turns: p = key + c with a CPL or a
; subtraction after (69 layers), p = key - c with an XOR after (12), and p = c - 1 (22), where c is the byte before
; and p after. The keys come from the R register, which Layer000 sets to 12, and from constants and the loop counters,
; never from the bytes, so each byte's transform is fixed by its address.
;
; tools/speedlock.py runs the chain in SkoolKit's simulator both ways: from the tape it gives this plain view, from
; this plain view it gives the tape's bytes back (identical, tools/build.sh). The last layer falls into LoaderStart
; $B8F9.
; --------------------------------------------------------------------------------------------------------------------

; Layer 0: rewrite the 4785 bytes $AC5C-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AC5C-$BF0C into p = NOT ((R XOR D) +
; c), D = $F3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer000:
  DI
  LD A,$0C
  LD R,A
  LD HL,Layer000+$0009
  LD BC,$001E
  LD DE,Layer000+$0008
  LDDR
  LD HL,Layer000Loop+$000C
  LD BC,$12B1
  LD D,$F3
Layer000Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer000Loop

; Layer 1: rewrite the 4768 bytes $AC6D-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AC6D-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer001:
  JP l_AC60
l_AC60:
  LD DE,$12A0
  LD HL,Layer001Loop+$0007
Layer001Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer001Loop

; Layer 2: rewrite the 4733 bytes $AC90-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AC90-$BF0C into p = NOT ((R XOR D) +
; c), D = $90 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer002:
  JP l_AC71
l_AC71:
  LD HL,l_AC71+$0004
  LD BC,$001E
  LD DE,l_AC71+$0003
  LDDR
  LD HL,Layer002Loop+$000C
  LD BC,$127D
  LD D,$90
Layer002Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer002Loop

; Layer 3: rewrite the 4702 bytes $ACAF-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $ACAF-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer003:
  JP l_AC94
l_AC94:
  LD HL,l_AC94
  LD BC,$001E
  LD DE,Layer003+$0002
  LDDR
  LD HL,Layer003Loop+$000A
  LD BC,$125E
Layer003Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer003Loop

; Layer 4: rewrite the 4667 bytes $ACD2-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $ACD2-$BF0C into p = NOT ((R XOR D) +
; c), D = $F1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer004:
  JP l_ACB3
l_ACB3:
  LD HL,l_ACB3+$0004
  LD BC,$001E
  LD DE,l_ACB3+$0003
  LDDR
  LD HL,Layer004Loop+$000C
  LD BC,$123B
  LD D,$F1
Layer004Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer004Loop

; Layer 5: rewrite the 4650 bytes $ACE3-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $ACE3-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer005:
  JP l_ACD6
l_ACD6:
  LD DE,$122A
  LD HL,Layer005Loop+$0007
Layer005Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer005Loop

; Layer 6: rewrite the 4598 bytes $AD17-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AD17-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer006:
  JP l_ACE7
l_ACE7:
  LD HL,l_ACE7
  LD DE,Layer006+$0002
  LD BC,$001E
  LDDR
  LD BC,$11F6
  LD HL,l_AD17
  CALL sub_ACFB

; sub_ACFB
;
; Used by the routine at Layer006.
sub_ACFB:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer007.
l_AD02:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer006Loop

; Layer 7: rewrite the 4568 bytes $AD35-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AD35-$BF0C into p = R + c - D, D =
; $B2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer007:
  JP l_AD17
; This entry point is used by the routine at sub_ACFB.
Layer006Loop:
  JP l_AD02               ; one byte a pass
l_AD17:
  LD HL,l_AD17+$0003
  LD BC,$001E
  LD DE,l_AD17+$0002
  LDDR
  LD HL,Layer007Loop+$000B
  LD BC,$11D8
  LD D,$B2
Layer007Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer007Loop

; Layer 8: rewrite the 4537 bytes $AD54-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AD54-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer008:
  JP l_AD39
l_AD39:
  LD HL,l_AD39
  LD BC,$001E
  LD DE,Layer008+$0002
  LDDR
  LD HL,Layer008Loop+$000A
  LD BC,$11B9
Layer008Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer008Loop

; Layer 9: rewrite the 4502 bytes $AD77-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AD77-$BF0C into p = NOT ((R XOR D) +
; c), D = $93 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer009:
  JP l_AD58
l_AD58:
  LD HL,l_AD58+$0004
  LD BC,$001E
  LD DE,l_AD58+$0003
  LDDR
  LD HL,Layer009Loop+$000C
  LD BC,$1196
  LD D,$93
Layer009Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer009Loop

; Layer 10: rewrite the 4485 bytes $AD88-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AD88-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer010:
  JP l_AD7B
l_AD7B:
  LD DE,$1185
  LD HL,Layer010Loop+$0007
Layer010Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer010Loop

; Layer 11: rewrite the 4450 bytes $ADAB-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $ADAB-$BF0C into p = NOT ((R XOR D) +
; c), D = $B0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer011:
  JP l_AD8C
l_AD8C:
  LD HL,l_AD8C+$0004
  LD BC,$001E
  LD DE,l_AD8C+$0003
  LDDR
  LD HL,Layer011Loop+$000C
  LD BC,$1162
  LD D,$B0
Layer011Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer011Loop

; Layer 12: rewrite the 4419 bytes $ADCA-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $ADCA-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer012:
  JP l_ADAF
l_ADAF:
  LD HL,l_ADAF
  LD BC,$001E
  LD DE,Layer012+$0002
  LDDR
  LD HL,Layer012Loop+$000A
  LD BC,$1143
Layer012Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer012Loop

; Layer 13: rewrite the 4384 bytes $ADED-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $ADED-$BF0C into p = NOT ((R XOR D) +
; c), D = $91 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer013:
  JP l_ADCE
l_ADCE:
  LD HL,l_ADCE+$0004
  LD BC,$001E
  LD DE,l_ADCE+$0003
  LDDR
  LD HL,Layer013Loop+$000C
  LD BC,$1120
  LD D,$91
Layer013Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer013Loop

; Layer 14: rewrite the 4367 bytes $ADFE-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $ADFE-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer014:
  JP l_ADF1
l_ADF1:
  LD DE,$110F
  LD HL,Layer014Loop+$0007
Layer014Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer014Loop

; Layer 15: rewrite the 4315 bytes $AE32-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AE32-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer015:
  JP l_AE02
l_AE02:
  LD HL,l_AE02
  LD DE,Layer015+$0002
  LD BC,$001E
  LDDR
  LD BC,$10DB
  LD HL,l_AE32
  CALL sub_AE16

; sub_AE16
;
; Used by the routine at Layer015.
sub_AE16:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer016.
l_AE1D:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer015Loop

; Layer 16: rewrite the 4285 bytes $AE50-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AE50-$BF0C into p = R + c - D, D =
; $D2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer016:
  JP l_AE32
; This entry point is used by the routine at sub_AE16.
Layer015Loop:
  JP l_AE1D               ; one byte a pass
l_AE32:
  LD HL,l_AE32+$0003
  LD BC,$001E
  LD DE,l_AE32+$0002
  LDDR
  LD HL,Layer016Loop+$000B
  LD BC,$10BD
  LD D,$D2
Layer016Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer016Loop

; Layer 17: rewrite the 4254 bytes $AE6F-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AE6F-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer017:
  JP l_AE54
l_AE54:
  LD HL,l_AE54
  LD BC,$001E
  LD DE,Layer017+$0002
  LDDR
  LD HL,Layer017Loop+$000A
  LD BC,$109E
Layer017Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer017Loop

; Layer 18: rewrite the 4219 bytes $AE92-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AE92-$BF0C into p = NOT ((R XOR D) +
; c), D = $B3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer018:
  JP l_AE73
l_AE73:
  LD HL,l_AE73+$0004
  LD BC,$001E
  LD DE,l_AE73+$0003
  LDDR
  LD HL,Layer018Loop+$000C
  LD BC,$107B
  LD D,$B3
Layer018Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer018Loop

; Layer 19: rewrite the 4202 bytes $AEA3-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AEA3-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer019:
  JP l_AE96
l_AE96:
  LD DE,$106A
  LD HL,Layer019Loop+$0007
Layer019Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer019Loop

; Layer 20: rewrite the 4167 bytes $AEC6-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AEC6-$BF0C into p = NOT ((R XOR D) +
; c), D = $D0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer020:
  JP l_AEA7
l_AEA7:
  LD HL,l_AEA7+$0004
  LD BC,$001E
  LD DE,l_AEA7+$0003
  LDDR
  LD HL,Layer020Loop+$000C
  LD BC,$1047
  LD D,$D0
Layer020Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer020Loop

; Layer 21: rewrite the 4136 bytes $AEE5-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AEE5-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer021:
  JP l_AECA
l_AECA:
  LD HL,l_AECA
  LD BC,$001E
  LD DE,Layer021+$0002
  LDDR
  LD HL,Layer021Loop+$000A
  LD BC,$1028
Layer021Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer021Loop

; Layer 22: rewrite the 4101 bytes $AF08-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AF08-$BF0C into p = NOT ((R XOR D) +
; c), D = $B1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer022:
  JP l_AEE9
l_AEE9:
  LD HL,l_AEE9+$0004
  LD BC,$001E
  LD DE,l_AEE9+$0003
  LDDR
  LD HL,Layer022Loop+$000C
  LD BC,$1005
  LD D,$B1
Layer022Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer022Loop

; Layer 23: rewrite the 4084 bytes $AF19-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AF19-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer023:
  JP l_AF0C
l_AF0C:
  LD DE,$0FF4
  LD HL,Layer023Loop+$0007
Layer023Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer023Loop

; Layer 24: rewrite the 4032 bytes $AF4D-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AF4D-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer024:
  JP l_AF1D
l_AF1D:
  LD HL,l_AF1D
  LD DE,Layer024+$0002
  LD BC,$001E
  LDDR
  LD BC,$0FC0
  LD HL,l_AF4D
  CALL sub_AF31

; sub_AF31
;
; Used by the routine at Layer024.
sub_AF31:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer025.
l_AF38:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer024Loop

; Layer 25: rewrite the 4002 bytes $AF6B-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AF6B-$BF0C into p = R + c - D, D =
; $F2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer025:
  JP l_AF4D
; This entry point is used by the routine at sub_AF31.
Layer024Loop:
  JP l_AF38               ; one byte a pass
l_AF4D:
  LD HL,l_AF4D+$0003
  LD BC,$001E
  LD DE,l_AF4D+$0002
  LDDR
  LD HL,Layer025Loop+$000B
  LD BC,$0FA2
  LD D,$F2
Layer025Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer025Loop

; Layer 26: rewrite the 3971 bytes $AF8A-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AF8A-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer026:
  JP l_AF6F
l_AF6F:
  LD HL,l_AF6F
  LD BC,$001E
  LD DE,Layer026+$0002
  LDDR
  LD HL,Layer026Loop+$000A
  LD BC,$0F83
Layer026Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer026Loop

; Layer 27: rewrite the 3936 bytes $AFAD-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AFAD-$BF0C into p = NOT ((R XOR D) +
; c), D = $D3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer027:
  JP l_AF8E
l_AF8E:
  LD HL,l_AF8E+$0004
  LD BC,$001E
  LD DE,l_AF8E+$0003
  LDDR
  LD HL,Layer027Loop+$000C
  LD BC,$0F60
  LD D,$D3
Layer027Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer027Loop

; Layer 28: rewrite the 3919 bytes $AFBE-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AFBE-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer028:
  JP l_AFB1
l_AFB1:
  LD DE,$0F4F
  LD HL,Layer028Loop+$0007
Layer028Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer028Loop

; Layer 29: rewrite the 3884 bytes $AFE1-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $AFE1-$BF0C into p = NOT ((R XOR D) +
; c), D = $F0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer029:
  JP l_AFC2
l_AFC2:
  LD HL,l_AFC2+$0004
  LD BC,$001E
  LD DE,l_AFC2+$0003
  LDDR
  LD HL,Layer029Loop+$000C
  LD BC,$0F2C
  LD D,$F0
Layer029Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer029Loop

; Layer 30: rewrite the 3853 bytes $B000-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B000-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer030:
  JP l_AFE5
l_AFE5:
  LD HL,l_AFE5
  LD BC,$001E
  LD DE,Layer030+$0002
  LDDR
  LD HL,Layer030Loop+$000A
  LD BC,$0F0D
Layer030Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer030Loop

; Layer 31: rewrite the 3818 bytes $B023-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B023-$BF0C into p = NOT ((R XOR D) +
; c), D = $D1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer031:
  JP l_B004
l_B004:
  LD HL,l_B004+$0004
  LD BC,$001E
  LD DE,l_B004+$0003
  LDDR
  LD HL,Layer031Loop+$000C
  LD BC,$0EEA
  LD D,$D1
Layer031Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer031Loop

; Layer 32: rewrite the 3801 bytes $B034-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B034-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer032:
  JP l_B027
l_B027:
  LD DE,$0ED9
  LD HL,Layer032Loop+$0007
Layer032Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer032Loop

; Layer 33: rewrite the 3749 bytes $B068-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B068-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer033:
  JP l_B038
l_B038:
  LD HL,l_B038
  LD DE,Layer033+$0002
  LD BC,$001E
  LDDR
  LD BC,$0EA5
  LD HL,l_B068
  CALL sub_B04C

; sub_B04C
;
; Used by the routine at Layer033.
sub_B04C:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer034.
l_B053:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer033Loop

; Layer 34: rewrite the 3719 bytes $B086-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B086-$BF0C into p = R + c - D, D =
; $92 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer034:
  JP l_B068
; This entry point is used by the routine at sub_B04C.
Layer033Loop:
  JP l_B053               ; one byte a pass
l_B068:
  LD HL,l_B068+$0003
  LD BC,$001E
  LD DE,l_B068+$0002
  LDDR
  LD HL,Layer034Loop+$000B
  LD BC,$0E87
  LD D,$92
Layer034Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer034Loop

; Layer 35: rewrite the 3688 bytes $B0A5-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B0A5-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer035:
  JP l_B08A
l_B08A:
  LD HL,l_B08A
  LD BC,$001E
  LD DE,Layer035+$0002
  LDDR
  LD HL,Layer035Loop+$000A
  LD BC,$0E68
Layer035Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer035Loop

; Layer 36: rewrite the 3653 bytes $B0C8-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B0C8-$BF0C into p = NOT ((R XOR D) +
; c), D = $F3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer036:
  JP l_B0A9
l_B0A9:
  LD HL,l_B0A9+$0004
  LD BC,$001E
  LD DE,l_B0A9+$0003
  LDDR
  LD HL,Layer036Loop+$000C
  LD BC,$0E45
  LD D,$F3
Layer036Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer036Loop

; Layer 37: rewrite the 3636 bytes $B0D9-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B0D9-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer037:
  JP l_B0CC
l_B0CC:
  LD DE,$0E34
  LD HL,Layer037Loop+$0007
Layer037Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer037Loop

; Layer 38: rewrite the 3601 bytes $B0FC-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B0FC-$BF0C into p = NOT ((R XOR D) +
; c), D = $90 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer038:
  JP l_B0DD
l_B0DD:
  LD HL,l_B0DD+$0004
  LD BC,$001E
  LD DE,l_B0DD+$0003
  LDDR
  LD HL,Layer038Loop+$000C
  LD BC,$0E11
  LD D,$90
Layer038Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer038Loop

; Layer 39: rewrite the 3570 bytes $B11B-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B11B-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer039:
  JP l_B100
l_B100:
  LD HL,l_B100
  LD BC,$001E
  LD DE,Layer039+$0002
  LDDR
  LD HL,Layer039Loop+$000A
  LD BC,$0DF2
Layer039Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer039Loop

; Layer 40: rewrite the 3535 bytes $B13E-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B13E-$BF0C into p = NOT ((R XOR D) +
; c), D = $F1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer040:
  JP l_B11F
l_B11F:
  LD HL,l_B11F+$0004
  LD BC,$001E
  LD DE,l_B11F+$0003
  LDDR
  LD HL,Layer040Loop+$000C
  LD BC,$0DCF
  LD D,$F1
Layer040Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer040Loop

; Layer 41: rewrite the 3518 bytes $B14F-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B14F-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer041:
  JP l_B142
l_B142:
  LD DE,$0DBE
  LD HL,Layer041Loop+$0007
Layer041Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer041Loop

; Layer 42: rewrite the 3466 bytes $B183-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B183-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer042:
  JP l_B153
l_B153:
  LD HL,l_B153
  LD DE,Layer042+$0002
  LD BC,$001E
  LDDR
  LD BC,$0D8A
  LD HL,l_B183
  CALL sub_B167

; sub_B167
;
; Used by the routine at Layer042.
sub_B167:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer043.
l_B16E:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer042Loop

; Layer 43: rewrite the 3436 bytes $B1A1-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B1A1-$BF0C into p = R + c - D, D =
; $B2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer043:
  JP l_B183
; This entry point is used by the routine at sub_B167.
Layer042Loop:
  JP l_B16E               ; one byte a pass
l_B183:
  LD HL,l_B183+$0003
  LD BC,$001E
  LD DE,l_B183+$0002
  LDDR
  LD HL,Layer043Loop+$000B
  LD BC,$0D6C
  LD D,$B2
Layer043Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer043Loop

; Layer 44: rewrite the 3405 bytes $B1C0-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B1C0-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer044:
  JP l_B1A5
l_B1A5:
  LD HL,l_B1A5
  LD BC,$001E
  LD DE,Layer044+$0002
  LDDR
  LD HL,Layer044Loop+$000A
  LD BC,$0D4D
Layer044Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer044Loop

; Layer 45: rewrite the 3370 bytes $B1E3-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B1E3-$BF0C into p = NOT ((R XOR D) +
; c), D = $93 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer045:
  JP l_B1C4
l_B1C4:
  LD HL,l_B1C4+$0004
  LD BC,$001E
  LD DE,l_B1C4+$0003
  LDDR
  LD HL,Layer045Loop+$000C
  LD BC,$0D2A
  LD D,$93
Layer045Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer045Loop

; Layer 46: rewrite the 3353 bytes $B1F4-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B1F4-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer046:
  JP l_B1E7
l_B1E7:
  LD DE,$0D19
  LD HL,Layer046Loop+$0007
Layer046Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer046Loop

; Layer 47: rewrite the 3318 bytes $B217-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B217-$BF0C into p = NOT ((R XOR D) +
; c), D = $B0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer047:
  JP l_B1F8
l_B1F8:
  LD HL,l_B1F8+$0004
  LD BC,$001E
  LD DE,l_B1F8+$0003
  LDDR
  LD HL,Layer047Loop+$000C
  LD BC,$0CF6
  LD D,$B0
Layer047Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer047Loop

; Layer 48: rewrite the 3287 bytes $B236-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B236-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer048:
  JP l_B21B
l_B21B:
  LD HL,l_B21B
  LD BC,$001E
  LD DE,Layer048+$0002
  LDDR
  LD HL,Layer048Loop+$000A
  LD BC,$0CD7
Layer048Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer048Loop

; Layer 49: rewrite the 3252 bytes $B259-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B259-$BF0C into p = NOT ((R XOR D) +
; c), D = $91 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer049:
  JP l_B23A
l_B23A:
  LD HL,l_B23A+$0004
  LD BC,$001E
  LD DE,l_B23A+$0003
  LDDR
  LD HL,Layer049Loop+$000C
  LD BC,$0CB4
  LD D,$91
Layer049Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer049Loop

; Layer 50: rewrite the 3235 bytes $B26A-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B26A-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer050:
  JP l_B25D
l_B25D:
  LD DE,$0CA3
  LD HL,Layer050Loop+$0007
Layer050Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer050Loop

; Layer 51: rewrite the 3183 bytes $B29E-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B29E-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer051:
  JP l_B26E
l_B26E:
  LD HL,l_B26E
  LD DE,Layer051+$0002
  LD BC,$001E
  LDDR
  LD BC,$0C6F
  LD HL,l_B29E
  CALL sub_B282

; sub_B282
;
; Used by the routine at Layer051.
sub_B282:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer052.
l_B289:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer051Loop

; Layer 52: rewrite the 3153 bytes $B2BC-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B2BC-$BF0C into p = R + c - D, D =
; $D2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer052:
  JP l_B29E
; This entry point is used by the routine at sub_B282.
Layer051Loop:
  JP l_B289               ; one byte a pass
l_B29E:
  LD HL,l_B29E+$0003
  LD BC,$001E
  LD DE,l_B29E+$0002
  LDDR
  LD HL,Layer052Loop+$000B
  LD BC,$0C51
  LD D,$D2
Layer052Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer052Loop

; Layer 53: rewrite the 3122 bytes $B2DB-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B2DB-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer053:
  JP l_B2C0
l_B2C0:
  LD HL,l_B2C0
  LD BC,$001E
  LD DE,Layer053+$0002
  LDDR
  LD HL,Layer053Loop+$000A
  LD BC,$0C32
Layer053Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer053Loop

; Layer 54: rewrite the 3087 bytes $B2FE-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B2FE-$BF0C into p = NOT ((R XOR D) +
; c), D = $B3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer054:
  JP l_B2DF
l_B2DF:
  LD HL,l_B2DF+$0004
  LD BC,$001E
  LD DE,l_B2DF+$0003
  LDDR
  LD HL,Layer054Loop+$000C
  LD BC,$0C0F
  LD D,$B3
Layer054Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer054Loop

; Layer 55: rewrite the 3070 bytes $B30F-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B30F-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer055:
  JP l_B302
l_B302:
  LD DE,$0BFE
  LD HL,Layer055Loop+$0007
Layer055Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer055Loop

; Layer 56: rewrite the 3035 bytes $B332-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B332-$BF0C into p = NOT ((R XOR D) +
; c), D = $D0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer056:
  JP l_B313
l_B313:
  LD HL,l_B313+$0004
  LD BC,$001E
  LD DE,l_B313+$0003
  LDDR
  LD HL,Layer056Loop+$000C
  LD BC,$0BDB
  LD D,$D0
Layer056Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer056Loop

; Layer 57: rewrite the 3004 bytes $B351-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B351-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer057:
  JP l_B336
l_B336:
  LD HL,l_B336
  LD BC,$001E
  LD DE,Layer057+$0002
  LDDR
  LD HL,Layer057Loop+$000A
  LD BC,$0BBC
Layer057Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer057Loop

; Layer 58: rewrite the 2969 bytes $B374-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B374-$BF0C into p = NOT ((R XOR D) +
; c), D = $B1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer058:
  JP l_B355
l_B355:
  LD HL,l_B355+$0004
  LD BC,$001E
  LD DE,l_B355+$0003
  LDDR
  LD HL,Layer058Loop+$000C
  LD BC,$0B99
  LD D,$B1
Layer058Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer058Loop

; Layer 59: rewrite the 2952 bytes $B385-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B385-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer059:
  JP l_B378
l_B378:
  LD DE,$0B88
  LD HL,Layer059Loop+$0007
Layer059Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer059Loop

; Layer 60: rewrite the 2900 bytes $B3B9-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B3B9-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer060:
  JP l_B389
l_B389:
  LD HL,l_B389
  LD DE,Layer060+$0002
  LD BC,$001E
  LDDR
  LD BC,$0B54
  LD HL,l_B3B9
  CALL sub_B39D

; sub_B39D
;
; Used by the routine at Layer060.
sub_B39D:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer061.
l_B3A4:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer060Loop

; Layer 61: rewrite the 2870 bytes $B3D7-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B3D7-$BF0C into p = R + c - D, D =
; $F2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer061:
  JP l_B3B9
; This entry point is used by the routine at sub_B39D.
Layer060Loop:
  JP l_B3A4               ; one byte a pass
l_B3B9:
  LD HL,l_B3B9+$0003
  LD BC,$001E
  LD DE,l_B3B9+$0002
  LDDR
  LD HL,Layer061Loop+$000B
  LD BC,$0B36
  LD D,$F2
Layer061Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer061Loop

; Layer 62: rewrite the 2839 bytes $B3F6-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B3F6-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer062:
  JP l_B3DB
l_B3DB:
  LD HL,l_B3DB
  LD BC,$001E
  LD DE,Layer062+$0002
  LDDR
  LD HL,Layer062Loop+$000A
  LD BC,$0B17
Layer062Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer062Loop

; Layer 63: rewrite the 2804 bytes $B419-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B419-$BF0C into p = NOT ((R XOR D) +
; c), D = $D3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer063:
  JP l_B3FA
l_B3FA:
  LD HL,l_B3FA+$0004
  LD BC,$001E
  LD DE,l_B3FA+$0003
  LDDR
  LD HL,Layer063Loop+$000C
  LD BC,$0AF4
  LD D,$D3
Layer063Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer063Loop

; Layer 64: rewrite the 2787 bytes $B42A-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B42A-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer064:
  JP l_B41D
l_B41D:
  LD DE,$0AE3
  LD HL,Layer064Loop+$0007
Layer064Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer064Loop

; Layer 65: rewrite the 2752 bytes $B44D-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B44D-$BF0C into p = NOT ((R XOR D) +
; c), D = $F0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer065:
  JP l_B42E
l_B42E:
  LD HL,l_B42E+$0004
  LD BC,$001E
  LD DE,l_B42E+$0003
  LDDR
  LD HL,Layer065Loop+$000C
  LD BC,$0AC0
  LD D,$F0
Layer065Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer065Loop

; Layer 66: rewrite the 2721 bytes $B46C-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B46C-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer066:
  JP l_B451
l_B451:
  LD HL,l_B451
  LD BC,$001E
  LD DE,Layer066+$0002
  LDDR
  LD HL,Layer066Loop+$000A
  LD BC,$0AA1
Layer066Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer066Loop

; Layer 67: rewrite the 2686 bytes $B48F-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B48F-$BF0C into p = NOT ((R XOR D) +
; c), D = $D1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer067:
  JP l_B470
l_B470:
  LD HL,l_B470+$0004
  LD BC,$001E
  LD DE,l_B470+$0003
  LDDR
  LD HL,Layer067Loop+$000C
  LD BC,$0A7E
  LD D,$D1
Layer067Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer067Loop

; Layer 68: rewrite the 2669 bytes $B4A0-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B4A0-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer068:
  JP l_B493
l_B493:
  LD DE,$0A6D
  LD HL,Layer068Loop+$0007
Layer068Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer068Loop

; Layer 69: rewrite the 2617 bytes $B4D4-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B4D4-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer069:
  JP l_B4A4
l_B4A4:
  LD HL,l_B4A4
  LD DE,Layer069+$0002
  LD BC,$001E
  LDDR
  LD BC,$0A39
  LD HL,l_B4D4
  CALL sub_B4B8

; sub_B4B8
;
; Used by the routine at Layer069.
sub_B4B8:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer070.
l_B4BF:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer069Loop

; Layer 70: rewrite the 2587 bytes $B4F2-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B4F2-$BF0C into p = R + c - D, D =
; $92 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer070:
  JP l_B4D4
; This entry point is used by the routine at sub_B4B8.
Layer069Loop:
  JP l_B4BF               ; one byte a pass
l_B4D4:
  LD HL,l_B4D4+$0003
  LD BC,$001E
  LD DE,l_B4D4+$0002
  LDDR
  LD HL,Layer070Loop+$000B
  LD BC,$0A1B
  LD D,$92
Layer070Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer070Loop

; Layer 71: rewrite the 2556 bytes $B511-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B511-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer071:
  JP l_B4F6
l_B4F6:
  LD HL,l_B4F6
  LD BC,$001E
  LD DE,Layer071+$0002
  LDDR
  LD HL,Layer071Loop+$000A
  LD BC,$09FC
Layer071Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer071Loop

; Layer 72: rewrite the 2521 bytes $B534-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B534-$BF0C into p = NOT ((R XOR D) +
; c), D = $F3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer072:
  JP l_B515
l_B515:
  LD HL,l_B515+$0004
  LD BC,$001E
  LD DE,l_B515+$0003
  LDDR
  LD HL,Layer072Loop+$000C
  LD BC,$09D9
  LD D,$F3
Layer072Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer072Loop

; Layer 73: rewrite the 2504 bytes $B545-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B545-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer073:
  JP l_B538
l_B538:
  LD DE,$09C8
  LD HL,Layer073Loop+$0007
Layer073Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer073Loop

; Layer 74: rewrite the 2469 bytes $B568-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B568-$BF0C into p = NOT ((R XOR D) +
; c), D = $90 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer074:
  JP l_B549
l_B549:
  LD HL,l_B549+$0004
  LD BC,$001E
  LD DE,l_B549+$0003
  LDDR
  LD HL,Layer074Loop+$000C
  LD BC,$09A5
  LD D,$90
Layer074Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer074Loop

; Layer 75: rewrite the 2438 bytes $B587-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B587-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer075:
  JP l_B56C
l_B56C:
  LD HL,l_B56C
  LD BC,$001E
  LD DE,Layer075+$0002
  LDDR
  LD HL,Layer075Loop+$000A
  LD BC,$0986
Layer075Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer075Loop

; Layer 76: rewrite the 2403 bytes $B5AA-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B5AA-$BF0C into p = NOT ((R XOR D) +
; c), D = $F1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer076:
  JP l_B58B
l_B58B:
  LD HL,l_B58B+$0004
  LD BC,$001E
  LD DE,l_B58B+$0003
  LDDR
  LD HL,Layer076Loop+$000C
  LD BC,$0963
  LD D,$F1
Layer076Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer076Loop

; Layer 77: rewrite the 2386 bytes $B5BB-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B5BB-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer077:
  JP l_B5AE
l_B5AE:
  LD DE,$0952
  LD HL,Layer077Loop+$0007
Layer077Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer077Loop

; Layer 78: rewrite the 2334 bytes $B5EF-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B5EF-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer078:
  JP l_B5BF
l_B5BF:
  LD HL,l_B5BF
  LD DE,Layer078+$0002
  LD BC,$001E
  LDDR
  LD BC,$091E
  LD HL,l_B5EF
  CALL sub_B5D3

; sub_B5D3
;
; Used by the routine at Layer078.
sub_B5D3:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer079.
l_B5DA:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer078Loop

; Layer 79: rewrite the 2304 bytes $B60D-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B60D-$BF0C into p = R + c - D, D =
; $B2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer079:
  JP l_B5EF
; This entry point is used by the routine at sub_B5D3.
Layer078Loop:
  JP l_B5DA               ; one byte a pass
l_B5EF:
  LD HL,l_B5EF+$0003
  LD BC,$001E
  LD DE,l_B5EF+$0002
  LDDR
  LD HL,Layer079Loop+$000B
  LD BC,$0900
  LD D,$B2
Layer079Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer079Loop

; Layer 80: rewrite the 2273 bytes $B62C-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B62C-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer080:
  JP l_B611
l_B611:
  LD HL,l_B611
  LD BC,$001E
  LD DE,Layer080+$0002
  LDDR
  LD HL,Layer080Loop+$000A
  LD BC,$08E1
Layer080Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer080Loop

; Layer 81: rewrite the 2238 bytes $B64F-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B64F-$BF0C into p = NOT ((R XOR D) +
; c), D = $93 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer081:
  JP l_B630
l_B630:
  LD HL,l_B630+$0004
  LD BC,$001E
  LD DE,l_B630+$0003
  LDDR
  LD HL,Layer081Loop+$000C
  LD BC,$08BE
  LD D,$93
Layer081Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer081Loop

; Layer 82: rewrite the 2221 bytes $B660-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B660-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer082:
  JP l_B653
l_B653:
  LD DE,$08AD
  LD HL,Layer082Loop+$0007
Layer082Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer082Loop

; Layer 83: rewrite the 2186 bytes $B683-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B683-$BF0C into p = NOT ((R XOR D) +
; c), D = $B0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer083:
  JP l_B664
l_B664:
  LD HL,l_B664+$0004
  LD BC,$001E
  LD DE,l_B664+$0003
  LDDR
  LD HL,Layer083Loop+$000C
  LD BC,$088A
  LD D,$B0
Layer083Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer083Loop

; Layer 84: rewrite the 2155 bytes $B6A2-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B6A2-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer084:
  JP l_B687
l_B687:
  LD HL,l_B687
  LD BC,$001E
  LD DE,Layer084+$0002
  LDDR
  LD HL,Layer084Loop+$000A
  LD BC,$086B
Layer084Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer084Loop

; Layer 85: rewrite the 2120 bytes $B6C5-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B6C5-$BF0C into p = NOT ((R XOR D) +
; c), D = $91 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer085:
  JP l_B6A6
l_B6A6:
  LD HL,l_B6A6+$0004
  LD BC,$001E
  LD DE,l_B6A6+$0003
  LDDR
  LD HL,Layer085Loop+$000C
  LD BC,$0848
  LD D,$91
Layer085Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer085Loop

; Layer 86: rewrite the 2103 bytes $B6D6-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B6D6-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer086:
  JP l_B6C9
l_B6C9:
  LD DE,$0837
  LD HL,Layer086Loop+$0007
Layer086Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer086Loop

; Layer 87: rewrite the 2051 bytes $B70A-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B70A-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer087:
  JP l_B6DA
l_B6DA:
  LD HL,l_B6DA
  LD DE,Layer087+$0002
  LD BC,$001E
  LDDR
  LD BC,$0803
  LD HL,l_B70A
  CALL sub_B6EE

; sub_B6EE
;
; Used by the routine at Layer087.
sub_B6EE:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer088.
l_B6F5:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer087Loop

; Layer 88: rewrite the 2021 bytes $B728-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B728-$BF0C into p = R + c - D, D =
; $D2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer088:
  JP l_B70A
; This entry point is used by the routine at sub_B6EE.
Layer087Loop:
  JP l_B6F5               ; one byte a pass
l_B70A:
  LD HL,l_B70A+$0003
  LD BC,$001E
  LD DE,l_B70A+$0002
  LDDR
  LD HL,Layer088Loop+$000B
  LD BC,$07E5
  LD D,$D2
Layer088Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer088Loop

; Layer 89: rewrite the 1990 bytes $B747-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B747-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer089:
  JP l_B72C
l_B72C:
  LD HL,l_B72C
  LD BC,$001E
  LD DE,Layer089+$0002
  LDDR
  LD HL,Layer089Loop+$000A
  LD BC,$07C6
Layer089Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer089Loop

; Layer 90: rewrite the 1955 bytes $B76A-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B76A-$BF0C into p = NOT ((R XOR D) +
; c), D = $B3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer090:
  JP l_B74B
l_B74B:
  LD HL,l_B74B+$0004
  LD BC,$001E
  LD DE,l_B74B+$0003
  LDDR
  LD HL,Layer090Loop+$000C
  LD BC,$07A3
  LD D,$B3
Layer090Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer090Loop

; Layer 91: rewrite the 1938 bytes $B77B-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B77B-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer091:
  JP l_B76E
l_B76E:
  LD DE,$0792
  LD HL,Layer091Loop+$0007
Layer091Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer091Loop

; Layer 92: rewrite the 1903 bytes $B79E-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B79E-$BF0C into p = NOT ((R XOR D) +
; c), D = $D0 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer092:
  JP l_B77F
l_B77F:
  LD HL,l_B77F+$0004
  LD BC,$001E
  LD DE,l_B77F+$0003
  LDDR
  LD HL,Layer092Loop+$000C
  LD BC,$076F
  LD D,$D0
Layer092Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer092Loop

; Layer 93: rewrite the 1872 bytes $B7BD-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B7BD-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer093:
  JP l_B7A2
l_B7A2:
  LD HL,l_B7A2
  LD BC,$001E
  LD DE,Layer093+$0002
  LDDR
  LD HL,Layer093Loop+$000A
  LD BC,$0750
Layer093Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer093Loop

; Layer 94: rewrite the 1837 bytes $B7E0-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B7E0-$BF0C into p = NOT ((R XOR D) +
; c), D = $B1 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer094:
  JP l_B7C1
l_B7C1:
  LD HL,l_B7C1+$0004
  LD BC,$001E
  LD DE,l_B7C1+$0003
  LDDR
  LD HL,Layer094Loop+$000C
  LD BC,$072D
  LD D,$B1
Layer094Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer094Loop

; Layer 95: rewrite the 1820 bytes $B7F1-$BF0C (DEC (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B7F1-$BF0C into p = c - 1 (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer095:
  JP l_B7E4
l_B7E4:
  LD DE,$071C
  LD HL,Layer095Loop+$0007
Layer095Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer095Loop

; Layer 96: rewrite the 1768 bytes $B825-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B825-$BF0C into p = ((R XOR IXH) - c)
; XOR IXL, IX the address after the CALL plus $1C (R the refresh register as LD
; A,R reads it). Known from the code and the chain run of tools/speedlock.py
; (all 103 layers, the tape masters back identical).
Layer096:
  JP l_B7F5
l_B7F5:
  LD HL,l_B7F5
  LD DE,Layer096+$0002
  LD BC,$001E
  LDDR
  LD BC,$06E8
  LD HL,l_B825
  CALL sub_B809

; sub_B809
;
; Used by the routine at Layer096.
sub_B809:
  POP IX
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer097.
l_B810:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer096Loop

; Layer 97: rewrite the 1738 bytes $B843-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B843-$BF0C into p = R + c - D, D =
; $F2 (R the refresh register as LD A,R reads it). Known from the code and the
; chain run of tools/speedlock.py (all 103 layers, the tape masters back
; identical).
Layer097:
  JP l_B825
; This entry point is used by the routine at sub_B809.
Layer096Loop:
  JP l_B810               ; one byte a pass
l_B825:
  LD HL,l_B825+$0003
  LD BC,$001E
  LD DE,l_B825+$0002
  LDDR
  LD HL,Layer097Loop+$000B
  LD BC,$06CA
  LD D,$F2
Layer097Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer097Loop

; Layer 98: rewrite the 1707 bytes $B862-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B862-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer098:
  JP l_B847
l_B847:
  LD HL,l_B847
  LD BC,$001E
  LD DE,Layer098+$0002
  LDDR
  LD HL,Layer098Loop+$000A
  LD BC,$06AB
Layer098Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer098Loop

; Layer 99: rewrite the 1672 bytes $B885-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B885-$BF0C into p = NOT ((R XOR D) +
; c), D = $D3 (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer099:
  JP l_B866
l_B866:
  LD HL,l_B866+$0004
  LD BC,$001E
  LD DE,l_B866+$0003
  LDDR
  LD HL,Layer099Loop+$000C
  LD BC,$0688
  LD D,$D3
Layer099Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer099Loop

; Layer 100: rewrite the 1641 bytes $B8A4-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B8A4-$BF0C into p = R + c (R the
; refresh register as LD A,R reads it). Known from the code and the chain run
; of tools/speedlock.py (all 103 layers, the tape masters back identical).
Layer100:
  JP l_B889
l_B889:
  LD HL,l_B889
  LD BC,$001E
  LD DE,Layer100+$0002
  LDDR
  LD HL,Layer100Loop+$000A
  LD BC,$0669
Layer100Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer100Loop

; Layer 101: rewrite the 1598 bytes $B8CF-$BF0C (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B8CF-$BF0C into p = (R XOR D) + c -
; $07, D = $CD (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer101:
  JP l_B8A8
l_B8A8:
  LD BC,$3FFD
  LD A,$03
  NOP
  NOP
  LD HL,l_B8A8+$000C
  LD BC,$001E
  LD DE,l_B8A8+$000B
  LDDR
  LD HL,Layer101Loop+$000D
  LD BC,$063E
  LD D,$CD
Layer101Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer101Loop

; Layer 102: rewrite the 1557 bytes $B8F8-$BF0C (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled), then rewrites each byte c of $B8F8-$BF0C into p = (R XOR E, E the
; count) - c (R the refresh register as LD A,R reads it). Known from the code
; and the chain run of tools/speedlock.py (all 103 layers, the tape masters
; back identical).
Layer102:
  JP l_B8D3
l_B8D3:
  LD BC,$001E
  LD HL,l_B8D3+$0002
  LD DE,l_B8D3+$0001
  CALL sub_B8DF

; sub_B8DF
;
; Used by the routine at Layer102.
sub_B8DF:
  LDDR
  LD DE,$0615
  POP BC
  LD HL,$0019
  ADD HL,BC
Layer102Loop:
  LD A,R                  ; one byte a pass
  XOR E
  SUB (HL)
  DEC DE
  LD (HL),A
  LD A,E
  INC HL
  OR D
  DEFB $ED,$CA
  NOP
  NOP
  JP NZ,Layer102Loop
