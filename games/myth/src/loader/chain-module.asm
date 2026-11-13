; --------------------------------------------------------------------------------------------------------------------
; chain-module.asm: The decryption chain: 103 layers, each rewriting the rest and running into it
;
; CopyChain (src/tape/basic.asm) returns into $EDE4. Each layer (all but a few) first shifts the 30 bytes behind its
; own LDDR down by one, which garbles the code already run, then rewrites every byte from its own end up to $FF25 and
; runs into the bytes it has just rewritten: the next layer. Four kinds of rewrite: p = key + c then a CPL, a SUB D or
; a SUB n (67 layers), p = key - c then an XOR (13), p = key XOR c (22; in 12 of them D, the key's second half, is the
; byte the layer wrote just before, plus 1) and p = c - 1 (1), where c is the byte before and p after. The keys come
; from the R register, which Layer000 sets to $42, from constants and from the loop counters, never from the bytes
; except in the 12 chained XOR layers.
;
; tools/speedlock.py runs the chain in SkoolKit's simulator both ways: from the tape it gives this plain view, from
; this plain view it gives the tape's bytes back (identical, tools/build.sh). The last layer falls into LoaderStart
; $FBD4. Twelve layers whose loop ends with JP Z,next / JP loop leave a two-byte gap after the JP that no instruction
; runs: the LayerNNNGap entries.
; --------------------------------------------------------------------------------------------------------------------

; Layer 0: rewrite the 4374 bytes $EE10-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EE10-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $EE11. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer000:
  DI
  LD A,$42
  LD R,A
  LD BC,$3FFD
  LD A,$03
  NOP
  NOP
  LD HL,Layer000+$0011
  LD BC,$001E
  LD DE,Layer000+$0010
  LDDR
  LD HL,Layer000Loop+$000D
  LD BC,$1116
  LD D,$8C
Layer000Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer000Loop

; Layer 1: rewrite the 4346 bytes $EE2C-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $EE2C-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EE2F. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer001:
  JP Layer001Shift
Layer001Shift:
  LD HL,Layer001Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$10FA
  LD D,$84
Layer001Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer002
  JP Layer001Loop

; 2 bytes inside layer 1 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($EE2D).
Layer001Gap:
  DEFB $DD,$E9

; Layer 2: rewrite the 4316 bytes $EE4A-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EE4A-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EE4B. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer002:
  LD HL,Layer002
  LD BC,$001E
  LD DE,Layer001Gap+$0001
  LDDR
  LD HL,Layer002Loop+$000A
  LD BC,$10DC
Layer002Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer002Loop

; Layer 3: rewrite the 4264 bytes $EE7E-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EE7E-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $EE7E (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $EE78. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer003:
  JP Layer003Shift
Layer003Shift:
  LD HL,Layer003Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer003+$0002
  LD BC,$001E
  LDDR
  LD BC,$10A8
  LD HL,Layer004Shift
  CALL Layer003PopIx

; Layer003PopIx
;
; Used by the routine at Layer003.
Layer003PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer004.
Layer003Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer003Back

; Layer 4: rewrite the 4237 bytes $EE99-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EE99-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EE9A. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer004:
  JP Layer004Shift
; This entry point is used by the routine at Layer003PopIx.
Layer003Back:
  JP Layer003Loop         ; the loop's jump back, after layer 4's entry
Layer004Shift:
  LD HL,Layer004Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer003Back+$0002
  LDDR
  LD HL,Layer004Loop+$000A
  LD BC,$108D
Layer004Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer004Loop

; Layer 5: rewrite the 4203 bytes $EEBB-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EEBB-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $EEBC. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer005:
  JP Layer005Shift
Layer005Shift:
  LD HL,Layer005Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer005Shift+$0002
  LDDR
  LD HL,Layer005Loop+$000B
  LD BC,$106B
  LD D,$BB
Layer005Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer005Loop

; Layer 6: rewrite the 4172 bytes $EEDA-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EEDA-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EEDB. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer006:
  JP Layer006Shift
Layer006Shift:
  LD HL,Layer006Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer006+$0002
  LDDR
  LD HL,Layer006Loop+$000A
  LD BC,$104C
Layer006Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer006Loop

; Layer 7: rewrite the 4137 bytes $EEFD-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EEFD-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $EEFE. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer007:
  JP Layer007Shift
Layer007Shift:
  LD HL,Layer007Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer007Shift+$0003
  LDDR
  LD HL,Layer007Loop+$000C
  LD BC,$1029
  LD D,$C7
Layer007Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer007Loop

; Layer 8: rewrite the 4106 bytes $EF1C-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EF1C-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EF1D. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer008:
  JP Layer008Shift
Layer008Shift:
  LD HL,Layer008Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer008+$0002
  LDDR
  LD HL,Layer008Loop+$000A
  LD BC,$100A
Layer008Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer008Loop

; Layer 9: rewrite the 4063 bytes $EF47-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EF47-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $EF48. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer009:
  JP Layer009Shift
Layer009Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer009Shift+$000C
  LD BC,$001E
  LD DE,Layer009Shift+$000B
  LDDR
  LD HL,Layer009Loop+$000D
  LD BC,$0FDF
  LD D,$8C
Layer009Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer009Loop

; Layer 10: rewrite the 4035 bytes $EF63-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $EF63-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EF66. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer010:
  JP Layer010Shift
Layer010Shift:
  LD HL,Layer010Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$0FC3
  LD D,$84
Layer010Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer011
  JP Layer010Loop

; 2 bytes inside layer 10 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($EF64).
Layer010Gap:
  DEFB $DD,$E9

; Layer 11: rewrite the 4005 bytes $EF81-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EF81-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EF82. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer011:
  LD HL,Layer011
  LD BC,$001E
  LD DE,Layer010Gap+$0001
  LDDR
  LD HL,Layer011Loop+$000A
  LD BC,$0FA5
Layer011Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer011Loop

; Layer 12: rewrite the 3953 bytes $EFB5-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EFB5-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $EFB5 (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $EFAF. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer012:
  JP Layer012Shift
Layer012Shift:
  LD HL,Layer012Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer012+$0002
  LD BC,$001E
  LDDR
  LD BC,$0F71
  LD HL,Layer013Shift
  CALL Layer012PopIx

; Layer012PopIx
;
; Used by the routine at Layer012.
Layer012PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer013.
Layer012Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer012Back

; Layer 13: rewrite the 3926 bytes $EFD0-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EFD0-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $EFD1. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer013:
  JP Layer013Shift
; This entry point is used by the routine at Layer012PopIx.
Layer012Back:
  JP Layer012Loop         ; the loop's jump back, after layer 13's entry
Layer013Shift:
  LD HL,Layer013Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer012Back+$0002
  LDDR
  LD HL,Layer013Loop+$000A
  LD BC,$0F56
Layer013Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer013Loop

; Layer 14: rewrite the 3892 bytes $EFF2-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $EFF2-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $EFF3. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer014:
  JP Layer014Shift
Layer014Shift:
  LD HL,Layer014Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer014Shift+$0002
  LDDR
  LD HL,Layer014Loop+$000B
  LD BC,$0F34
  LD D,$BB
Layer014Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer014Loop

; Layer 15: rewrite the 3861 bytes $F011-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F011-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F012. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer015:
  JP Layer015Shift
Layer015Shift:
  LD HL,Layer015Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer015+$0002
  LDDR
  LD HL,Layer015Loop+$000A
  LD BC,$0F15
Layer015Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer015Loop

; Layer 16: rewrite the 3826 bytes $F034-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F034-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F035. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer016:
  JP Layer016Shift
Layer016Shift:
  LD HL,Layer016Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer016Shift+$0003
  LDDR
  LD HL,Layer016Loop+$000C
  LD BC,$0EF2
  LD D,$C7
Layer016Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer016Loop

; Layer 17: rewrite the 3795 bytes $F053-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F053-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F054. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer017:
  JP Layer017Shift
Layer017Shift:
  LD HL,Layer017Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer017+$0002
  LDDR
  LD HL,Layer017Loop+$000A
  LD BC,$0ED3
Layer017Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer017Loop

; Layer 18: rewrite the 3752 bytes $F07E-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F07E-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F07F. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer018:
  JP Layer018Shift
Layer018Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer018Shift+$000C
  LD BC,$001E
  LD DE,Layer018Shift+$000B
  LDDR
  LD HL,Layer018Loop+$000D
  LD BC,$0EA8
  LD D,$8C
Layer018Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer018Loop

; Layer 19: rewrite the 3724 bytes $F09A-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F09A-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F09D. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer019:
  JP Layer019Shift
Layer019Shift:
  LD HL,Layer019Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$0E8C
  LD D,$84
Layer019Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer020
  JP Layer019Loop

; 2 bytes inside layer 19 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F09B).
Layer019Gap:
  DEFB $DD,$E9

; Layer 20: rewrite the 3694 bytes $F0B8-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F0B8-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F0B9. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer020:
  LD HL,Layer020
  LD BC,$001E
  LD DE,Layer019Gap+$0001
  LDDR
  LD HL,Layer020Loop+$000A
  LD BC,$0E6E
Layer020Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer020Loop

; Layer 21: rewrite the 3642 bytes $F0EC-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F0EC-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F0EC (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F0E6. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer021:
  JP Layer021Shift
Layer021Shift:
  LD HL,Layer021Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer021+$0002
  LD BC,$001E
  LDDR
  LD BC,$0E3A
  LD HL,Layer022Shift
  CALL Layer021PopIx

; Layer021PopIx
;
; Used by the routine at Layer021.
Layer021PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer022.
Layer021Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer021Back

; Layer 22: rewrite the 3615 bytes $F107-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F107-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F108. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer022:
  JP Layer022Shift
; This entry point is used by the routine at Layer021PopIx.
Layer021Back:
  JP Layer021Loop         ; the loop's jump back, after layer 22's entry
Layer022Shift:
  LD HL,Layer022Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer021Back+$0002
  LDDR
  LD HL,Layer022Loop+$000A
  LD BC,$0E1F
Layer022Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer022Loop

; Layer 23: rewrite the 3581 bytes $F129-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F129-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F12A. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer023:
  JP Layer023Shift
Layer023Shift:
  LD HL,Layer023Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer023Shift+$0002
  LDDR
  LD HL,Layer023Loop+$000B
  LD BC,$0DFD
  LD D,$BB
Layer023Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer023Loop

; Layer 24: rewrite the 3550 bytes $F148-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F148-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F149. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer024:
  JP Layer024Shift
Layer024Shift:
  LD HL,Layer024Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer024+$0002
  LDDR
  LD HL,Layer024Loop+$000A
  LD BC,$0DDE
Layer024Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer024Loop

; Layer 25: rewrite the 3515 bytes $F16B-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F16B-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F16C. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer025:
  JP Layer025Shift
Layer025Shift:
  LD HL,Layer025Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer025Shift+$0003
  LDDR
  LD HL,Layer025Loop+$000C
  LD BC,$0DBB
  LD D,$C7
Layer025Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer025Loop

; Layer 26: rewrite the 3484 bytes $F18A-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F18A-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F18B. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer026:
  JP Layer026Shift
Layer026Shift:
  LD HL,Layer026Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer026+$0002
  LDDR
  LD HL,Layer026Loop+$000A
  LD BC,$0D9C
Layer026Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer026Loop

; Layer 27: rewrite the 3441 bytes $F1B5-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F1B5-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F1B6. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer027:
  JP Layer027Shift
Layer027Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer027Shift+$000C
  LD BC,$001E
  LD DE,Layer027Shift+$000B
  LDDR
  LD HL,Layer027Loop+$000D
  LD BC,$0D71
  LD D,$8C
Layer027Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer027Loop

; Layer 28: rewrite the 3413 bytes $F1D1-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F1D1-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F1D4. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer028:
  JP Layer028Shift
Layer028Shift:
  LD HL,Layer028Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$0D55
  LD D,$84
Layer028Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer029
  JP Layer028Loop

; 2 bytes inside layer 28 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F1D2).
Layer028Gap:
  DEFB $DD,$E9

; Layer 29: rewrite the 3383 bytes $F1EF-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F1EF-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F1F0. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer029:
  LD HL,Layer029
  LD BC,$001E
  LD DE,Layer028Gap+$0001
  LDDR
  LD HL,Layer029Loop+$000A
  LD BC,$0D37
Layer029Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer029Loop

; Layer 30: rewrite the 3331 bytes $F223-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F223-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F223 (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F21D. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer030:
  JP Layer030Shift
Layer030Shift:
  LD HL,Layer030Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer030+$0002
  LD BC,$001E
  LDDR
  LD BC,$0D03
  LD HL,Layer031Shift
  CALL Layer030PopIx

; Layer030PopIx
;
; Used by the routine at Layer030.
Layer030PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer031.
Layer030Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer030Back

; Layer 31: rewrite the 3304 bytes $F23E-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F23E-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F23F. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer031:
  JP Layer031Shift
; This entry point is used by the routine at Layer030PopIx.
Layer030Back:
  JP Layer030Loop         ; the loop's jump back, after layer 31's entry
Layer031Shift:
  LD HL,Layer031Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer030Back+$0002
  LDDR
  LD HL,Layer031Loop+$000A
  LD BC,$0CE8
Layer031Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer031Loop

; Layer 32: rewrite the 3270 bytes $F260-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F260-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F261. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer032:
  JP Layer032Shift
Layer032Shift:
  LD HL,Layer032Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer032Shift+$0002
  LDDR
  LD HL,Layer032Loop+$000B
  LD BC,$0CC6
  LD D,$BB
Layer032Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer032Loop

; Layer 33: rewrite the 3239 bytes $F27F-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F27F-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F280. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer033:
  JP Layer033Shift
Layer033Shift:
  LD HL,Layer033Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer033+$0002
  LDDR
  LD HL,Layer033Loop+$000A
  LD BC,$0CA7
Layer033Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer033Loop

; Layer 34: rewrite the 3204 bytes $F2A2-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F2A2-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F2A3. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer034:
  JP Layer034Shift
Layer034Shift:
  LD HL,Layer034Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer034Shift+$0003
  LDDR
  LD HL,Layer034Loop+$000C
  LD BC,$0C84
  LD D,$C7
Layer034Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer034Loop

; Layer 35: rewrite the 3173 bytes $F2C1-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F2C1-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F2C2. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer035:
  JP Layer035Shift
Layer035Shift:
  LD HL,Layer035Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer035+$0002
  LDDR
  LD HL,Layer035Loop+$000A
  LD BC,$0C65
Layer035Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer035Loop

; Layer 36: rewrite the 3130 bytes $F2EC-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F2EC-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F2ED. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer036:
  JP Layer036Shift
Layer036Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer036Shift+$000C
  LD BC,$001E
  LD DE,Layer036Shift+$000B
  LDDR
  LD HL,Layer036Loop+$000D
  LD BC,$0C3A
  LD D,$8C
Layer036Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer036Loop

; Layer 37: rewrite the 3102 bytes $F308-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F308-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F30B. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer037:
  JP Layer037Shift
Layer037Shift:
  LD HL,Layer037Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$0C1E
  LD D,$84
Layer037Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer038
  JP Layer037Loop

; 2 bytes inside layer 37 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F309).
Layer037Gap:
  DEFB $DD,$E9

; Layer 38: rewrite the 3072 bytes $F326-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F326-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F327. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer038:
  LD HL,Layer038
  LD BC,$001E
  LD DE,Layer037Gap+$0001
  LDDR
  LD HL,Layer038Loop+$000A
  LD BC,$0C00
Layer038Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer038Loop

; Layer 39: rewrite the 3020 bytes $F35A-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F35A-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F35A (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F354. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer039:
  JP Layer039Shift
Layer039Shift:
  LD HL,Layer039Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer039+$0002
  LD BC,$001E
  LDDR
  LD BC,$0BCC
  LD HL,Layer040Shift
  CALL Layer039PopIx

; Layer039PopIx
;
; Used by the routine at Layer039.
Layer039PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer040.
Layer039Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer039Back

; Layer 40: rewrite the 2993 bytes $F375-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F375-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F376. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer040:
  JP Layer040Shift
; This entry point is used by the routine at Layer039PopIx.
Layer039Back:
  JP Layer039Loop         ; the loop's jump back, after layer 40's entry
Layer040Shift:
  LD HL,Layer040Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer039Back+$0002
  LDDR
  LD HL,Layer040Loop+$000A
  LD BC,$0BB1
Layer040Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer040Loop

; Layer 41: rewrite the 2959 bytes $F397-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F397-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F398. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer041:
  JP Layer041Shift
Layer041Shift:
  LD HL,Layer041Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer041Shift+$0002
  LDDR
  LD HL,Layer041Loop+$000B
  LD BC,$0B8F
  LD D,$BB
Layer041Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer041Loop

; Layer 42: rewrite the 2928 bytes $F3B6-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F3B6-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F3B7. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer042:
  JP Layer042Shift
Layer042Shift:
  LD HL,Layer042Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer042+$0002
  LDDR
  LD HL,Layer042Loop+$000A
  LD BC,$0B70
Layer042Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer042Loop

; Layer 43: rewrite the 2893 bytes $F3D9-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F3D9-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F3DA. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer043:
  JP Layer043Shift
Layer043Shift:
  LD HL,Layer043Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer043Shift+$0003
  LDDR
  LD HL,Layer043Loop+$000C
  LD BC,$0B4D
  LD D,$C7
Layer043Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer043Loop

; Layer 44: rewrite the 2862 bytes $F3F8-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F3F8-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F3F9. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer044:
  JP Layer044Shift
Layer044Shift:
  LD HL,Layer044Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer044+$0002
  LDDR
  LD HL,Layer044Loop+$000A
  LD BC,$0B2E
Layer044Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer044Loop

; Layer 45: rewrite the 2819 bytes $F423-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F423-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F424. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer045:
  JP Layer045Shift
Layer045Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer045Shift+$000C
  LD BC,$001E
  LD DE,Layer045Shift+$000B
  LDDR
  LD HL,Layer045Loop+$000D
  LD BC,$0B03
  LD D,$8C
Layer045Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer045Loop

; Layer 46: rewrite the 2791 bytes $F43F-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F43F-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F442. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer046:
  JP Layer046Shift
Layer046Shift:
  LD HL,Layer046Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$0AE7
  LD D,$84
Layer046Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer047
  JP Layer046Loop

; 2 bytes inside layer 46 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F440).
Layer046Gap:
  DEFB $DD,$E9

; Layer 47: rewrite the 2761 bytes $F45D-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F45D-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F45E. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer047:
  LD HL,Layer047
  LD BC,$001E
  LD DE,Layer046Gap+$0001
  LDDR
  LD HL,Layer047Loop+$000A
  LD BC,$0AC9
Layer047Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer047Loop

; Layer 48: rewrite the 2709 bytes $F491-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F491-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F491 (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F48B. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer048:
  JP Layer048Shift
Layer048Shift:
  LD HL,Layer048Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer048+$0002
  LD BC,$001E
  LDDR
  LD BC,$0A95
  LD HL,Layer049Shift
  CALL Layer048PopIx

; Layer048PopIx
;
; Used by the routine at Layer048.
Layer048PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer049.
Layer048Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer048Back

; Layer 49: rewrite the 2682 bytes $F4AC-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F4AC-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F4AD. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer049:
  JP Layer049Shift
; This entry point is used by the routine at Layer048PopIx.
Layer048Back:
  JP Layer048Loop         ; the loop's jump back, after layer 49's entry
Layer049Shift:
  LD HL,Layer049Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer048Back+$0002
  LDDR
  LD HL,Layer049Loop+$000A
  LD BC,$0A7A
Layer049Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer049Loop

; Layer 50: rewrite the 2648 bytes $F4CE-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F4CE-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F4CF. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer050:
  JP Layer050Shift
Layer050Shift:
  LD HL,Layer050Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer050Shift+$0002
  LDDR
  LD HL,Layer050Loop+$000B
  LD BC,$0A58
  LD D,$BB
Layer050Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer050Loop

; Layer 51: rewrite the 2617 bytes $F4ED-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F4ED-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F4EE. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer051:
  JP Layer051Shift
Layer051Shift:
  LD HL,Layer051Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer051+$0002
  LDDR
  LD HL,Layer051Loop+$000A
  LD BC,$0A39
Layer051Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer051Loop

; Layer 52: rewrite the 2582 bytes $F510-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F510-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F511. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer052:
  JP Layer052Shift
Layer052Shift:
  LD HL,Layer052Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer052Shift+$0003
  LDDR
  LD HL,Layer052Loop+$000C
  LD BC,$0A16
  LD D,$C7
Layer052Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer052Loop

; Layer 53: rewrite the 2551 bytes $F52F-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F52F-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F530. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer053:
  JP Layer053Shift
Layer053Shift:
  LD HL,Layer053Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer053+$0002
  LDDR
  LD HL,Layer053Loop+$000A
  LD BC,$09F7
Layer053Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer053Loop

; Layer 54: rewrite the 2508 bytes $F55A-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F55A-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F55B. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer054:
  JP Layer054Shift
Layer054Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer054Shift+$000C
  LD BC,$001E
  LD DE,Layer054Shift+$000B
  LDDR
  LD HL,Layer054Loop+$000D
  LD BC,$09CC
  LD D,$8C
Layer054Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer054Loop

; Layer 55: rewrite the 2480 bytes $F576-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F576-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F579. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer055:
  JP Layer055Shift
Layer055Shift:
  LD HL,Layer055Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$09B0
  LD D,$84
Layer055Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer056
  JP Layer055Loop

; 2 bytes inside layer 55 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F577).
Layer055Gap:
  DEFB $DD,$E9

; Layer 56: rewrite the 2450 bytes $F594-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F594-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F595. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer056:
  LD HL,Layer056
  LD BC,$001E
  LD DE,Layer055Gap+$0001
  LDDR
  LD HL,Layer056Loop+$000A
  LD BC,$0992
Layer056Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer056Loop

; Layer 57: rewrite the 2398 bytes $F5C8-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F5C8-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F5C8 (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F5C2. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer057:
  JP Layer057Shift
Layer057Shift:
  LD HL,Layer057Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer057+$0002
  LD BC,$001E
  LDDR
  LD BC,$095E
  LD HL,Layer058Shift
  CALL Layer057PopIx

; Layer057PopIx
;
; Used by the routine at Layer057.
Layer057PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer058.
Layer057Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer057Back

; Layer 58: rewrite the 2371 bytes $F5E3-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F5E3-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F5E4. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer058:
  JP Layer058Shift
; This entry point is used by the routine at Layer057PopIx.
Layer057Back:
  JP Layer057Loop         ; the loop's jump back, after layer 58's entry
Layer058Shift:
  LD HL,Layer058Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer057Back+$0002
  LDDR
  LD HL,Layer058Loop+$000A
  LD BC,$0943
Layer058Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer058Loop

; Layer 59: rewrite the 2337 bytes $F605-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F605-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F606. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer059:
  JP Layer059Shift
Layer059Shift:
  LD HL,Layer059Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer059Shift+$0002
  LDDR
  LD HL,Layer059Loop+$000B
  LD BC,$0921
  LD D,$BB
Layer059Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer059Loop

; Layer 60: rewrite the 2306 bytes $F624-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F624-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F625. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer060:
  JP Layer060Shift
Layer060Shift:
  LD HL,Layer060Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer060+$0002
  LDDR
  LD HL,Layer060Loop+$000A
  LD BC,$0902
Layer060Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer060Loop

; Layer 61: rewrite the 2271 bytes $F647-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F647-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F648. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer061:
  JP Layer061Shift
Layer061Shift:
  LD HL,Layer061Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer061Shift+$0003
  LDDR
  LD HL,Layer061Loop+$000C
  LD BC,$08DF
  LD D,$C7
Layer061Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer061Loop

; Layer 62: rewrite the 2240 bytes $F666-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F666-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F667. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer062:
  JP Layer062Shift
Layer062Shift:
  LD HL,Layer062Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer062+$0002
  LDDR
  LD HL,Layer062Loop+$000A
  LD BC,$08C0
Layer062Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer062Loop

; Layer 63: rewrite the 2197 bytes $F691-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F691-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F692. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer063:
  JP Layer063Shift
Layer063Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer063Shift+$000C
  LD BC,$001E
  LD DE,Layer063Shift+$000B
  LDDR
  LD HL,Layer063Loop+$000D
  LD BC,$0895
  LD D,$8C
Layer063Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer063Loop

; Layer 64: rewrite the 2169 bytes $F6AD-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F6AD-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F6B0. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer064:
  JP Layer064Shift
Layer064Shift:
  LD HL,Layer064Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$0879
  LD D,$84
Layer064Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer065
  JP Layer064Loop

; 2 bytes inside layer 64 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F6AE).
Layer064Gap:
  DEFB $DD,$E9

; Layer 65: rewrite the 2139 bytes $F6CB-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F6CB-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F6CC. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer065:
  LD HL,Layer065
  LD BC,$001E
  LD DE,Layer064Gap+$0001
  LDDR
  LD HL,Layer065Loop+$000A
  LD BC,$085B
Layer065Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer065Loop

; Layer 66: rewrite the 2087 bytes $F6FF-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F6FF-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F6FF (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F6F9. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer066:
  JP Layer066Shift
Layer066Shift:
  LD HL,Layer066Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer066+$0002
  LD BC,$001E
  LDDR
  LD BC,$0827
  LD HL,Layer067Shift
  CALL Layer066PopIx

; Layer066PopIx
;
; Used by the routine at Layer066.
Layer066PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer067.
Layer066Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer066Back

; Layer 67: rewrite the 2060 bytes $F71A-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F71A-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F71B. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer067:
  JP Layer067Shift
; This entry point is used by the routine at Layer066PopIx.
Layer066Back:
  JP Layer066Loop         ; the loop's jump back, after layer 67's entry
Layer067Shift:
  LD HL,Layer067Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer066Back+$0002
  LDDR
  LD HL,Layer067Loop+$000A
  LD BC,$080C
Layer067Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer067Loop

; Layer 68: rewrite the 2026 bytes $F73C-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F73C-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F73D. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer068:
  JP Layer068Shift
Layer068Shift:
  LD HL,Layer068Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer068Shift+$0002
  LDDR
  LD HL,Layer068Loop+$000B
  LD BC,$07EA
  LD D,$BB
Layer068Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer068Loop

; Layer 69: rewrite the 1995 bytes $F75B-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F75B-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F75C. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer069:
  JP Layer069Shift
Layer069Shift:
  LD HL,Layer069Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer069+$0002
  LDDR
  LD HL,Layer069Loop+$000A
  LD BC,$07CB
Layer069Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer069Loop

; Layer 70: rewrite the 1960 bytes $F77E-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F77E-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F77F. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer070:
  JP Layer070Shift
Layer070Shift:
  LD HL,Layer070Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer070Shift+$0003
  LDDR
  LD HL,Layer070Loop+$000C
  LD BC,$07A8
  LD D,$C7
Layer070Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer070Loop

; Layer 71: rewrite the 1929 bytes $F79D-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F79D-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F79E. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer071:
  JP Layer071Shift
Layer071Shift:
  LD HL,Layer071Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer071+$0002
  LDDR
  LD HL,Layer071Loop+$000A
  LD BC,$0789
Layer071Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer071Loop

; Layer 72: rewrite the 1886 bytes $F7C8-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F7C8-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F7C9. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer072:
  JP Layer072Shift
Layer072Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer072Shift+$000C
  LD BC,$001E
  LD DE,Layer072Shift+$000B
  LDDR
  LD HL,Layer072Loop+$000D
  LD BC,$075E
  LD D,$8C
Layer072Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer072Loop

; Layer 73: rewrite the 1858 bytes $F7E4-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F7E4-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F7E7. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer073:
  JP Layer073Shift
Layer073Shift:
  LD HL,Layer073Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$0742
  LD D,$84
Layer073Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer074
  JP Layer073Loop

; 2 bytes inside layer 73 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F7E5).
Layer073Gap:
  DEFB $DD,$E9

; Layer 74: rewrite the 1828 bytes $F802-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F802-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F803. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer074:
  LD HL,Layer074
  LD BC,$001E
  LD DE,Layer073Gap+$0001
  LDDR
  LD HL,Layer074Loop+$000A
  LD BC,$0724
Layer074Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer074Loop

; Layer 75: rewrite the 1776 bytes $F836-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F836-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F836 (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F830. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer075:
  JP Layer075Shift
Layer075Shift:
  LD HL,Layer075Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer075+$0002
  LD BC,$001E
  LDDR
  LD BC,$06F0
  LD HL,Layer076Shift
  CALL Layer075PopIx

; Layer075PopIx
;
; Used by the routine at Layer075.
Layer075PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer076.
Layer075Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer075Back

; Layer 76: rewrite the 1749 bytes $F851-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F851-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F852. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer076:
  JP Layer076Shift
; This entry point is used by the routine at Layer075PopIx.
Layer075Back:
  JP Layer075Loop         ; the loop's jump back, after layer 76's entry
Layer076Shift:
  LD HL,Layer076Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer075Back+$0002
  LDDR
  LD HL,Layer076Loop+$000A
  LD BC,$06D5
Layer076Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer076Loop

; Layer 77: rewrite the 1715 bytes $F873-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F873-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F874. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer077:
  JP Layer077Shift
Layer077Shift:
  LD HL,Layer077Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer077Shift+$0002
  LDDR
  LD HL,Layer077Loop+$000B
  LD BC,$06B3
  LD D,$BB
Layer077Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer077Loop

; Layer 78: rewrite the 1684 bytes $F892-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F892-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F893. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer078:
  JP Layer078Shift
Layer078Shift:
  LD HL,Layer078Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer078+$0002
  LDDR
  LD HL,Layer078Loop+$000A
  LD BC,$0694
Layer078Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer078Loop

; Layer 79: rewrite the 1649 bytes $F8B5-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F8B5-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F8B6. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer079:
  JP Layer079Shift
Layer079Shift:
  LD HL,Layer079Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer079Shift+$0003
  LDDR
  LD HL,Layer079Loop+$000C
  LD BC,$0671
  LD D,$C7
Layer079Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer079Loop

; Layer 80: rewrite the 1618 bytes $F8D4-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F8D4-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F8D5. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer080:
  JP Layer080Shift
Layer080Shift:
  LD HL,Layer080Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer080+$0002
  LDDR
  LD HL,Layer080Loop+$000A
  LD BC,$0652
Layer080Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer080Loop

; Layer 81: rewrite the 1575 bytes $F8FF-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F8FF-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F900. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer081:
  JP Layer081Shift
Layer081Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer081Shift+$000C
  LD BC,$001E
  LD DE,Layer081Shift+$000B
  LDDR
  LD HL,Layer081Loop+$000D
  LD BC,$0627
  LD D,$8C
Layer081Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer081Loop

; Layer 82: rewrite the 1547 bytes $F91B-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $F91B-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F91E. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer082:
  JP Layer082Shift
Layer082Shift:
  LD HL,Layer082Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$060B
  LD D,$84
Layer082Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer083
  JP Layer082Loop

; 2 bytes inside layer 82 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($F91C).
Layer082Gap:
  DEFB $DD,$E9

; Layer 83: rewrite the 1517 bytes $F939-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F939-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F93A. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer083:
  LD HL,Layer083
  LD BC,$001E
  LD DE,Layer082Gap+$0001
  LDDR
  LD HL,Layer083Loop+$000A
  LD BC,$05ED
Layer083Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer083Loop

; Layer 84: rewrite the 1465 bytes $F96D-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F96D-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $F96D (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $F967. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer084:
  JP Layer084Shift
Layer084Shift:
  LD HL,Layer084Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer084+$0002
  LD BC,$001E
  LDDR
  LD BC,$05B9
  LD HL,Layer085Shift
  CALL Layer084PopIx

; Layer084PopIx
;
; Used by the routine at Layer084.
Layer084PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer085.
Layer084Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer084Back

; Layer 85: rewrite the 1438 bytes $F988-$FF25 (XOR (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F988-$FF25 into p = R XOR c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F989. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer085:
  JP Layer085Shift
; This entry point is used by the routine at Layer084PopIx.
Layer084Back:
  JP Layer084Loop         ; the loop's jump back, after layer 85's entry
Layer085Shift:
  LD HL,Layer085Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer084Back+$0002
  LDDR
  LD HL,Layer085Loop+$000A
  LD BC,$059E
Layer085Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer085Loop

; Layer 86: rewrite the 1404 bytes $F9AA-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F9AA-$FF25 into p = R + c - D, D =
; $BB (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $F9AB. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer086:
  JP Layer086Shift
Layer086Shift:
  LD HL,Layer086Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer086Shift+$0002
  LDDR
  LD HL,Layer086Loop+$000B
  LD BC,$057C
  LD D,$BB
Layer086Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer086Loop

; Layer 87: rewrite the 1373 bytes $F9C9-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F9C9-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $F9CA. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer087:
  JP Layer087Shift
Layer087Shift:
  LD HL,Layer087Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer087+$0002
  LDDR
  LD HL,Layer087Loop+$000A
  LD BC,$055D
Layer087Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer087Loop

; Layer 88: rewrite the 1338 bytes $F9EC-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $F9EC-$FF25 into p = NOT ((R XOR D) +
; c), D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $F9ED. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer088:
  JP Layer088Shift
Layer088Shift:
  LD HL,Layer088Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer088Shift+$0003
  LDDR
  LD HL,Layer088Loop+$000C
  LD BC,$053A
  LD D,$C7
Layer088Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer088Loop

; Layer 89: rewrite the 1307 bytes $FA0B-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FA0B-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $FA0C. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer089:
  JP Layer089Shift
Layer089Shift:
  LD HL,Layer089Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer089+$0002
  LDDR
  LD HL,Layer089Loop+$000A
  LD BC,$051B
Layer089Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer089Loop

; Layer 90: rewrite the 1264 bytes $FA36-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FA36-$FF25 into p = (R XOR D) + c -
; $07, D = $8C (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $FA37. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer090:
  JP Layer090Shift
Layer090Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer090Shift+$000C
  LD BC,$001E
  LD DE,Layer090Shift+$000B
  LDDR
  LD HL,Layer090Loop+$000D
  LD BC,$04F0
  LD D,$8C
Layer090Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  SUB $07
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer090Loop

; Layer 91: rewrite the 1236 bytes $FA52-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $FA52-$FF25 into p = (R XOR c)
; XOR D, D = $84 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $FA55. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer091:
  JP Layer091Shift
Layer091Shift:
  LD HL,Layer091Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$04D4
  LD D,$84
Layer091Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer092
  JP Layer091Loop

; 2 bytes inside layer 91 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($FA53).
Layer091Gap:
  DEFB $DD,$E9

; Layer 92: rewrite the 1206 bytes $FA70-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FA70-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $FA71. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer092:
  LD HL,Layer092
  LD BC,$001E
  LD DE,Layer091Gap+$0001
  LDDR
  LD HL,Layer092Loop+$000A
  LD BC,$04B6
Layer092Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer092Loop

; Layer 93: rewrite the 1154 bytes $FAA4-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FAA4-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $FAA4 (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $FA9E. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer093:
  JP Layer093Shift
Layer093Shift:
  LD HL,Layer093Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer093+$0002
  LD BC,$001E
  LDDR
  LD BC,$0482
  LD HL,Layer094Shift
  CALL Layer093PopIx

; Layer093PopIx
;
; Used by the routine at Layer093.
Layer093PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer094.
Layer093Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer093Back

; Layer 94: rewrite the 1124 bytes $FAC2-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FAC2-$FF25 into p = R + c - D, D =
; $89 (R the refresh register as LD A,R reads it, c the byte before, p after),
; and goes on at $FAC3. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer094:
  JP Layer094Shift
; This entry point is used by the routine at Layer093PopIx.
Layer093Back:
  JP Layer093Loop         ; the loop's jump back, after layer 94's entry
Layer094Shift:
  LD HL,Layer094Shift+$0003 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer094Shift+$0002
  LDDR
  LD HL,Layer094Loop+$000B
  LD BC,$0464
  LD D,$89
Layer094Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer094Loop

; Layer 95: rewrite the 1093 bytes $FAE1-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FAE1-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $FAE2. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer095:
  JP Layer095Shift
Layer095Shift:
  LD HL,Layer095Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer095+$0002
  LDDR
  LD HL,Layer095Loop+$000A
  LD BC,$0445
Layer095Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer095Loop

; Layer 96: rewrite the 1058 bytes $FB04-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FB04-$FF25 into p = NOT ((R XOR D) +
; c), D = $EA (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $FB05. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer096:
  JP Layer096Shift
Layer096Shift:
  LD HL,Layer096Shift+$0004 ; the shift and the set-up (the entry's JP lands
                            ; here)
  LD BC,$001E
  LD DE,Layer096Shift+$0003
  LDDR
  LD HL,Layer096Loop+$000C
  LD BC,$0422
  LD D,$EA
Layer096Loop:
  LD A,R                  ; one byte a pass
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer096Loop

; Layer 97: rewrite the 1027 bytes $FB23-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FB23-$FF25 into p = R + c (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $FB24. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer097:
  JP Layer097Shift
Layer097Shift:
  LD HL,Layer097Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD BC,$001E
  LD DE,Layer097+$0002
  LDDR
  LD HL,Layer097Loop+$000A
  LD BC,$0403
Layer097Loop:
  LD A,R                  ; one byte a pass
  ADD A,(HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,Layer097Loop

; Layer 98: rewrite the 975 bytes $FB57-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FB57-$FF25 into p = ((R XOR IXH) - c)
; XOR IXL, IX = $FB57 (CALL / POP IX) (R the refresh register as LD A,R reads
; it, c the byte before, p after), and goes on at $FB51. Known from the code
; and the chain run of tools/speedlock.py (all 103 layers; the tape masters
; back identical, tools/build.sh).
Layer098:
  JP Layer098Shift
Layer098Shift:
  LD HL,Layer098Shift     ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD DE,Layer098+$0002
  LD BC,$001E
  LDDR
  LD BC,$03CF
  LD HL,Layer099Shift
  CALL Layer098PopIx

; Layer098PopIx
;
; Used by the routine at Layer098.
Layer098PopIx:
  POP IX                  ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$001C
  ADD IX,DE
; This entry point is used by the routine at Layer099.
Layer098Loop:
  LD A,R                  ; one byte a pass
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,Layer098Back

; Layer 99: rewrite the 951 bytes $FB6F-$FF25 (XOR (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $FB6F-$FF25 into p = (R XOR c)
; XOR D, D = $B9 at the first byte, then the byte it wrote plus 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $FB72. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer099:
  JP Layer099Shift
; This entry point is used by the routine at Layer098PopIx.
Layer098Back:
  JP Layer098Loop         ; the loop's jump back, after layer 99's entry
Layer099Shift:
  LD HL,Layer099Loop+$0010 ; the shift and the set-up (the entry's JP lands
                           ; here)
  LD BC,$03B7
  LD D,$B9
Layer099Loop:
  LD A,R                  ; one byte a pass
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer100
  JP Layer099Loop

; 2 bytes inside layer 99 no instruction runs (DD E9)
;
; Not executed in the chain run (SkoolKit's simulator, every instruction of the
; 103 layers): the layer's loop jumps over them. Kept as bytes of the block;
; the layers before rewrite them like their neighbours. Known only from the
; code ($FB70).
Layer099Gap:
  DEFB $DD,$E9

; Layer 100: rewrite the 935 bytes $FB7F-$FF25 (DEC (HL)), run into them
;
; No LDDR shift. Then rewrites each byte c of $FB7F-$FF25 into p = c - 1 (R the
; refresh register as LD A,R reads it, c the byte before, p after), and goes on
; at $FB80. Known from the code and the chain run of tools/speedlock.py (all
; 103 layers; the tape masters back identical, tools/build.sh).
Layer100:
  LD DE,$03A7
  LD HL,Layer100Loop+$0007
Layer100Loop:
  DEC (HL)                ; one byte a pass
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,Layer100Loop

; Layer 101: rewrite the 892 bytes $FBAA-$FF25 (ADD A,(HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FBAA-$FF25 into p = (R XOR D) + c -
; $07, D = $C7 (R the refresh register as LD A,R reads it, c the byte before, p
; after), and goes on at $FBAB. Known from the code and the chain run of
; tools/speedlock.py (all 103 layers; the tape masters back identical,
; tools/build.sh).
Layer101:
  JP Layer101Shift
Layer101Shift:
  LD BC,$3FFD             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD A,$03
  NOP
  NOP
  LD HL,Layer101Shift+$000C
  LD BC,$001E
  LD DE,Layer101Shift+$000B
  LDDR
  LD HL,Layer101Loop+$000D
  LD BC,$037C
  LD D,$C7
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

; Layer 102: rewrite the 851 bytes $FBD3-$FF25 (SUB (HL)), run into them
;
; Shifts the 30 bytes up to its own LDDR down by one (the code already run is
; garbled). Then rewrites each byte c of $FBD3-$FF25 into p = (R XOR E) - c, E
; the low byte of the count (DE) (R the refresh register as LD A,R reads it, c
; the byte before, p after), and goes on at $FBD4. Known from the code and the
; chain run of tools/speedlock.py (all 103 layers; the tape masters back
; identical, tools/build.sh).
Layer102:
  JP Layer102Shift
Layer102Shift:
  LD BC,$001E             ; the shift and the set-up (the entry's JP lands
                          ; here)
  LD HL,Layer102Shift+$0002
  LD DE,Layer102Shift+$0001
  CALL Layer102PopIx

; Layer102PopIx
;
; Used by the routine at Layer102.
Layer102PopIx:
  LDDR                    ; CALL here, then POP IX: IX the address of this
                          ; code, the key
  LD DE,$0353
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
