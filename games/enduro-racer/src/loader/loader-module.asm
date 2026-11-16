; --------------------------------------------------------------------------------------------------------------------
; loader-module.asm: The SpeedLock 2 loader: two more decoders, the edge loader, its block table
;
; tools/speedlock2.py enciphers this view into the second BASIC's $5EFD-$6219 (src/tape/basic2.asm, LoaderTape).
; Chain1 there XORs those 797 bytes with R and copies them to $FCA3; Chain2 below XORs $FCD1-$FFBF with R once more,
; Chain3 runs 137 rounds of a running XOR over $FD2C-$FFBF keyed by the decoders' own bytes, checks the sum of
; $FF37-$FFBF and enters LoaderStart.
;
; LoaderStart probes the tape, loads the screen and then every block of BlockTable in one chain: each block ends with
; a 21-bit mark whose middle byte must be $7F, then the next row gives the address and the length. Each byte is stored
; as ((t XOR k) + a) AND 255, k and a the operands of Store ($FE04) or, for a block's last byte, StoreLast ($FE3C);
; blocks 9 and 10 load new k and a over them (tools/mktape.py). A failed check sets LoadFailed and the end wipes the
; RAM (Crash).
; --------------------------------------------------------------------------------------------------------------------

; Find its own address, then XOR $FCD1-$FFBF (751 bytes) with R in place and
; run into Chain3
;
; Entered by Chain1's RET. The first nine bytes are filler the decoder keys on
; (Chain3 reads $FCA3-$FD2B as its keys). EX (SP),IY with $FCD1 pushed leaves
; the return address +$2E in DE and HL: $FCD1. BC = 751; A = I sets the parity
; flag from IFF2 (interrupts off: PO), so the CALL PO,$3008 into the ROM (EXX /
; INC E / JR NZ / INC D / EXX / RET) only burns M1 cycles that set R.
; Chain2Loop is Chain1's loop: LD A,R / XOR (HL) / LD (HL),A / LDI, leaving by
; RET PO when BC reaches 0 into the next code (the DEC SP pair puts the return
; address back).
;
; R at the first byte is $8D: Chain1's last R plus 40 M1 cycles
; (tools/speedlock2.py r2_start, checked against the c1 dump at frame 1577 T
; 5842).
;
; Witness: L1 1 (c1).
Chain2:
  LD B,D
  LD D,L
  LD B,A
  LD A,(HL)
  LD C,A
  LD B,(HL)
  LD B,(HL)
  DEC SP
  DEC SP
  LD IYH,$FC
  LD IYL,$D1
  EX (SP),IY
  LD BC,$002E
  ADD IY,BC
  LD E,IYL
  LD D,IYH
  LD L,E
  LD H,D
  LD BC,$02EF
  LD A,I
  CALL PO,$3008
Chain2Loop:
  LD A,R                  ; A = R XOR byte, stored; LDI on; RET PO at the end,
                          ; RET PE back to the loop otherwise
  XOR (HL)
  LD (HL),A
  LDI
  RET PO
  DEC SP
  DEC SP
  RET PE

; 137 rounds of a running XOR over $FD2C-$FFBF, check the sum of $FF37-$FFBF
; and wipe itself
;
; C = the byte at $FFBF, B = 137 rounds, DE = $FCA3 (the keys: the decoders'
; own bytes). Each round: A = key - C, then for each of the 660 bytes
; $FD2C-$FFBF A = A XOR byte, byte = A; C = the last A. Then HL = the sum of
; the 137 bytes from $FF37; it must be $36FE. The 61 bytes $FCD1-$FD0D become
; $C9 (RET) and JP Z enters LoaderStart; a wrong sum falls into Crash.
;
; Witness: L1 1 (c1).
Chain3:
  LD BC,(LoaderPad+$0001)
  LD B,$89
  LD DE,Chain2
l_FCDA:
  PUSH BC
  LD A,(DE)
  PUSH DE
  LD DE,$0394
  SUB C
  LD HL,Edge
l_FCE4:
  XOR (HL)
  LD (HL),A
  INC HL
  DEC E
  JP NZ,l_FCE4
  DEC D
  JP NZ,l_FCE4
  POP DE
  INC DE
  POP BC
  LD C,A
  DEC B
  JP NZ,l_FCDA
  LD HL,$0000             ; the sum of $FF37-$FFBF (137 bytes)
  LD DE,LoaderStart
  LD B,$89
l_FCFF:
  PUSH BC
  LD A,(DE)
  INC DE
  LD B,$00
  LD C,A
  ADD HL,BC
  POP BC
  DEC B
  JP NZ,l_FCFF
  LD DE,$36FE
  AND A
  SBC HL,DE
  EX AF,AF'
  LD HL,Chain3            ; 61 RETs over Chain3's own code
  LD B,$3D
l_FD17:
  LD (HL),$C9
  INC HL
  DJNZ l_FD17
  EX AF,AF'
  JP Z,LoaderStart

; Wipe the RAM from $0075 upward with zeros until the machine resets
;
; IY from 0, LD (IY+$75),0 forever: the RAM is cleared, then the stack and this
; code, and the machine resets. Called by Chain3 on a bad sum, by LoaderStart
; when LoadFailed is set and by the end when the check byte leaves H nonzero.
Crash:
  LD IY,$0000
l_FD24:
  LD (IY+$75),$00
  INC IY
  JR l_FD24

; Wait A*16 T-states, then count in B until the EAR bit changes; border stripes
;
; In: A the delay, B the start count, C the last EAR level in bit 5. Out: carry
; set and B the count at the edge, the border flipped; carry clear (B wrapped
; to 0) on a timeout or BREAK (bit 0 of port $7FFE is SPACE: RRA puts it in
; carry... the ROM's LD-EDGE shape). The AND at $FD3F picks the border colours;
; LoadBlock and LeaderDone patch it ($FD40).
;
; Witness: L1 9845859 (c1).
Edge:
  DEC A
  JR NZ,Edge
  AND A
l_FD30:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  XOR C
  AND $20
  JR Z,l_FD30
  LD A,C
  CPL
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET

; Read a leader, the sync counts and the 6-bit mark $3A, then the bytes of the
; first block
;
; In: IX the address, DE the length - 1. Reads leader edges until about 1045 *
; 256 T-states of tone, then the sync: four groups of short pulses
; (SyncCounts), each followed by a long one; then a 6-bit mark that must be
; %111010 ($3A) or Crash. IY = BlockTable, H = 0 (the running XOR of the tape
; bytes) and the bit loop at ByteLoop.
;
; Witness: L1 2 (c1).
LoadBlock:
  DI
  INC D
  DEC D
  LD A,$02
  LD (l_FD30+$0010),A
  LD A,$0F
  OUT ($FE),A
  LD HL,LoadEnd+$0001
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  LD C,A
  CP A
l_FD5E:
  CALL Edge
  JR NC,l_FD5E
  LD HL,$0415
l_FD66:
  DJNZ l_FD66
  DEC HL
  LD A,H
  OR L
  JR NZ,l_FD66
  LD A,$0A
  CALL Edge
  JR NC,l_FD5E
l_FD74:
  LD B,$C4
  LD A,$16
  CALL Edge
  JR NC,l_FD5E
  LD A,$D6
  CP B
  JR C,l_FD74
l_FD82:
  LD B,$C4
  LD A,$16
  CALL Edge
  JR NC,l_FD5E
  LD A,$DF
  CP B
  JR C,l_FD74
l_FD90:
  LD IY,SyncCounts        ; IY = SyncCounts: four groups of pulses, each count
                          ; from -n to 0
l_FD94:
  LD H,(IY+$00)
l_FD97:
  LD B,$C4
  LD A,$16
  CALL Edge
  JR NC,l_FD5E
  LD A,$CD
  CP B
  JR NC,l_FD82
  INC H
  JR NZ,l_FD97
  LD B,$60
  LD A,$16
  CALL Edge
  JR NC,l_FD5E
  LD A,$16
  CALL Edge
  JR NC,l_FD5E
  LD A,$AB
  CP B
  JR C,LeaderDone
  INC IY
  LD A,IYL
  CP $89
  JR NZ,l_FD94
  JR l_FD90
LeaderDone:
  LD A,$01                ; border AND $01, read the 6 mark bits into L
  LD (l_FD30+$0010),A
  LD B,$B0
  LD L,$04
  LD A,$0B
  JR l_FDD6
l_FDD4:
  LD A,$0C
l_FDD6:
  CALL Edge
  RET NC
  NOP
  NOP
  LD A,$0E
  CALL Edge
  RET NC
  LD A,$13
  LD A,$C3
  CP B
  RL L
  LD B,$B0
  JP NC,l_FDD4
  LD A,$3A
  CP L
  JP NZ,Crash
  LD H,$86
  LD H,$00
  LD B,$C4
  LD L,$01
  LD IY,BlockTable        ; IY = BlockTable: the rows after the screen
  LD A,$07
  JR l_FE1A

; Store a byte ((L XOR $98) + $0B) and read the next one
;
; The store of every byte but a block's last. Its operands k = $98 and a = $0B
; are the keys: block 9 loads $3E,$07 over $FE04-$FE05, making k = $07 for the
; blocks after it.
;
; Witness: L1 47560 (c1).
Store:
  LD A,$98
  XOR L
  ADD A,$0B
  LD (IX+$00),A
  INC IX
  DEC DE
  LD B,$C4
  LD L,$01
  NOP
  LD A,$05
  JR l_FE1A
ByteLoop:
  LD A,$0C                ; read 8 bits into L (marker bit in L), H ^= L, loop
                          ; while DE > 0
; This entry point is used by the routines at LoadBlock and StoreLast.
l_FE1A:
  CALL Edge
  RET NC
  NOP
  NOP
  LD A,$0E
  CALL Edge
  RET NC
  LD A,$13
  LD A,$D7
  CP B
  RL L
  LD B,$C4
  JP NC,ByteLoop
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,Store
StoreLastJump:
  JP LoadEnd              ; JP to the last byte's store: StoreLast; the end
                          ; handler $FF7A for the last block

; Store a block's last byte, read the 21-bit end mark, take the next row of
; BlockTable
;
; The last byte's store has its own keys ($98, $0B; block 10 loads
; $3E,$07,$AD,$C6). Then three 7-bit groups via ReadMarkBits; the middle one
; must be $7F or LoadFailed = $7F. The row: page (IY+4) out to $7FFD when
; nonzero (always $10 here: ROM 1, bank 0 on a 128K), IX = (IY+0), DE = (IY+2),
; IY += 5, back to ByteLoop. A row with page 0 (row 11) keeps IX, sets
; StoreLastJump to $FF7A and DE = $0E00: the last block, 3585 bytes, whose last
; byte is the check.
;
; Witness: L1 11 (c1).
StoreLast:
  LD A,$98
  XOR L
  ADD A,$0B
  LD (IX+$00),A
  INC IX
  DEC DE
  LD L,$02
  LD A,$04
  LD B,$B3
  CALL ReadMarkBits
  RET NC
  LD A,(IY+$04)
  OR A
  JR Z,l_FEAD
  LD L,C
  LD BC,$7FFD
  OUT (C),A
  LD C,(IY+$00)
  LD B,(IY+$01)
  LD IX,$0000
  ADD IX,BC
  LD C,L
  LD A,$01
l_FE6C:
  LD L,$02
  LD B,$B3
  CALL ReadMarkBits
  RET NC
  LD A,$7F
  CP L
  JR Z,l_FE7C
  LD (LoadFailed),A
l_FE7C:
  LD L,$02
  LD A,$08
  LD B,$B3
  CALL ReadMarkBits
  RET NC
  LD E,(IY+$02)
  LD D,(IY+$03)
  LD L,C
  LD BC,$0005
  ADD IY,BC
  LD C,L
  LD A,E
  OR D
  LD B,$C4
  LD L,$01
  LD A,$05
  JP NZ,l_FE1A
  LD DE,LoadEnd
  LD (StoreLastJump+$0001),DE
  LD DE,$0E00
  LD A,$01
  JP l_FE1A
l_FEAD:
  LD A,$06                ; page 0: no OUT
  JR l_FE6C
; This entry point is used by the routine at ReadMarkBits.
ReadMarkBit0:
  LD A,$0C                ; a long half pulse: a 0 bit

; Read one mark bit into L by two edges (threshold $DB)
;
; In: L with its marker, B the count. Loops by JP NC to $FEB1 for 0 bits;
; returns when the marker leaves L. Used by StoreLast for the 21-bit end mark.
;
; Witness: L1 231 (c1).
ReadMarkBits:
  CALL Edge
  NOP
  NOP
  LD A,$0E
  CALL Edge
  RET NC
  LD A,$DB
  CP B
  RL L
  LD B,$B3
  JP NC,ReadMarkBit0
  RET

; Load block 5 to $A000, sample the EAR 255 times to $9000 and check the
; samples
;
; Called by LoaderStart with IX = $A000, DE = $11: block 5 (18 tape bytes: the
; ROM bytes of $0032-$0042 decoded with k = $98, a = $0B, then the block's last
; byte; a decoy later overwritten). Then 255 samples by SampleEar to
; $9000-$90FE and CheckSamples; a bad tape sets LoadFailed. A copy without the
; tone after block 5 fails here.
;
; Witness: L1 1 (c1).
ProbeTape:
  CALL LoadBlock
  LD HL,$9000
  LD B,$FF
l_FED1:
  PUSH BC
  CALL SampleEar
  LD (HL),E
  INC HL
  POP BC
  DJNZ l_FED1
  CALL CheckSamples
  RET

; Count the EAR changes in 255 reads into E
;
; Witness: L1 255 (c1).
SampleEar:
  LD E,$00
  LD C,E
  LD B,$FF
l_FEE3:
  LD A,$7F
  IN A,($FE)
  AND $40
  XOR C
  JR Z,l_FEF5
  INC E
  LD A,C
  CPL
  AND $40
  LD C,A
l_FEF2:
  DJNZ l_FEE3
  RET
l_FEF5:
  NOP
  NOP
  JP l_FEF2

; Sum the samples $9032-$9063 and $90CD-$90FE; LoadFailed = 1 unless both are
; in range
;
; Sum 1 of the 50 bytes from $9032, sum 2 of the 50 bytes from $90CD.
; LoadFailed ($FF36) = 1 when sum 2 >= $0D00, or when sum 2 - sum 1 and sum 2 -
; sum 1 - 50 are both not negative; otherwise it stays 0.
;
; Witness: L1 1 (c1).
CheckSamples:
  LD HL,$0000
  LD DE,$9032
  LD B,$32
l_FF02:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ l_FF02
  PUSH HL
  LD HL,$0000
  LD DE,$90CD
  LD B,$32
l_FF15:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ l_FF15
  POP BC
  LD A,H
  CP $0D
  JR NC,l_FF32
  AND A
  SBC HL,BC
  RET C
  LD BC,$0032
  AND A
  SBC HL,BC
  RET C
  LD A,$01
l_FF32:
  LD (LoadFailed),A
  RET

; Nonzero after a bad end mark ($7F) or a bad probe (1); LoaderStart crashes on
; it
LoadFailed:
  DEFB $00

; Clear the attributes, probe the tape, load the screen and every block, then
; start the game
;
; Interrupts off, SP = $FFFF, $5800-$5AFF zero (the screen black). ProbeTape
; loads block 5; then IX = $4000, DE = $1AFF and StoreLastJump = StoreLast:
; LoadBlock loads the screen and the rows of BlockTable after it. The tail
; $FF63-$FF79 is block 12's: it checks LoadFailed, sets IY = $5C3A, IM 1, HL' =
; $2758, R = 0 and jumps on (src/loader/tail.asm). This view holds the original
; tail with JP $6000.
;
; Witness: L1 1 (c1).
LoaderStart:
  DI
  LD SP,$FFFF
  LD HL,$5800
  LD BC,$0003
l_FF41:
  LD (HL),$00
  INC HL
  DJNZ l_FF41
  DEC C
  JR NZ,l_FF41
  LD IX,$A000
  LD DE,$0011
  CALL ProbeTape
  LD IX,$4000
  LD DE,$1AFF
  LD HL,StoreLast
  LD (StoreLastJump+$0001),HL
  CALL LoadBlock
  LD A,(LoadFailed)       ; from here on block 12 rewrites the tail (JP $A000
                          ; in its version)
  OR A
  CALL NZ,Crash
  LD IY,$5C3A
  IM 1
  LD HL,$2758
  EXX
  XOR A
  LD R,A
  JP $6000

; The end: drop $FF7B, border black; H (the XOR of the stream) 0: return to
; LoaderStart's tail, else Crash
;
; LoadBlock pushes $FF7B first, so a timeout anywhere (RET NC) lands at $FF7B;
; the last block's StoreLastJump lands at $FF7A, whose POP DE drops that $FF7B.
; Either way H < 1 returns to the tail at $FF63, anything else is Crash. This
; is the plain view's version, known only from the code: block 14 rewrites
; $FF7A-$FF86 before the end (src/loader/tail.asm, TailEnd), and the 2 runs the
; witness counts are TailEnd's bytes (c1 frame 11632).
;
; Witness: L1 2 (c1).
LoadEnd:
  POP DE
  XOR A
  OUT ($FE),A
  LD A,H
  CP $01
  RET C
  CALL Crash

; The four sync groups: each the negated count of short pulses before a long
; one
SyncCounts:
  DEFB $16,$1E,$1A,$18

; The blocks after the screen: address, length - 1, page; 10 rows and an end
; row
;
; Row n is TZX block n + 6 (doc 03): $70C8 $11FF, $A0C8 $0FFF, $FE04 1 (the new
; Store key), $FE3C 3 (the new StoreLast key), $5BC8 $14FF, $FF63 $16 (the new
; tail), $B0C8 $4957, $FF7A $0C (the new end), $5B00 $3F (Mover), $82C8 $0FFF,
; then the end row (page 0): the last block follows at $92C8. The page is $10
; in every real row.
BlockTable:
  DEFB $C8,$70,$FF,$11,$10
  DEFB $C8,$A0,$FF,$0F,$10
  DEFB $04,$FE,$01,$00,$10
  DEFB $3C,$FE,$03,$00,$10
  DEFB $C8,$5B,$FF,$14,$10
  DEFB $63,$FF,$16,$00,$10
  DEFB $C8,$B0,$57,$49,$10
  DEFB $7A,$FF,$0C,$00,$10
  DEFB $00,$5B,$3F,$00,$10
  DEFB $C8,$82,$FF,$0F,$10
  DEFB $00,$00,$00

; The two bytes after the table, inside the enciphered range ($FFBF is Chain3's
; first C)
LoaderPad:
  DEFB $00,$00
