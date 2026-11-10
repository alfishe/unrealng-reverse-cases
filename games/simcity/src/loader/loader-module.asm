; --------------------------------------------------------------------------------------------------------------------
; loader-module.asm: The loader: the R decryption of its own tail, three encrypted blocks through a changed LD-BYTES
;
; The ROM loads this block at $FE00 (BASIC line 20, LOAD "" CODE 65024) and line 30 calls it. LoaderStart decrypts
; $FE80-$FFFF with the R register and jumps to LoadGame, which loads the three headerless blocks 5-7 with LoadBlock, a
; copy of the ROM's LD-BYTES ($0556) that stores every byte XORed with a running key and the count, and jumps to the
; mover at $5000.
;
; c1: $FE00 is entered at frame 1258, T 65 246; $FE80 at frame 1259; the mover at frame 16 279 (docs/03-build-and-
; load.md 3.5).
; --------------------------------------------------------------------------------------------------------------------

; Decrypt $FE80-$FFFF with the R register, then run it
;
; R is set to 0, then each byte from $FE80 to $FFFF is XORed with the value LD
; A,R reads just before it. The loop takes eight M1 cycles a byte (LD A,R two,
; the other six one each) and R counts M1 cycles in its low seven bits, so the
; key of the byte at $FE80 + k is (2 + 8 k) AND $7F: it depends on the
; instruction timing, not on any byte. Interrupts are off (DI), so no interrupt
; acknowledge adds to R.
;
; Input: none (called from BASIC). Output: $FE80-$FFFF in clear. c1: L1 1 at
; $FE00, 384 runs of DecryptLoop, $FE80 entered at frame 1259.
; tools/decrypt_tape.py check: the decryption applied twice gives the tape's
; bytes back.
LoaderStart:
  DI
  LD HL,LoadGame
  XOR A
  LD R,A
DecryptLoop:
  LD A,R                  ; A = R, the key; XOR it into (HL), up to $FFFF
  XOR (HL)
  LD (HL),A
  INC HL
  LD A,H
  OR L
  JP NZ,DecryptLoop
  JP LoadGame

; Padding up to $FE80: the bytes $14-$7F in order
;
; No code reads these 108 bytes (c1: no L1 read). A leftover of the mastering,
; kept as bytes: each byte is its own address's low byte, so the clear part
; ends at $FE13 and the encrypted part starts at a round $FE80.
LoaderPadding:
  DEFB $14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$20,$21,$22,$23
  DEFB $24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F,$30,$31,$32,$33
  DEFB $34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F,$40,$41,$42,$43
  DEFB $44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$50,$51,$52,$53
  DEFB $54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5F,$60,$61,$62,$63
  DEFB $64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$70,$71,$72,$73
  DEFB $74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F

; Clear the screen, load blocks 5, 6 and 7, jump to the mover
;
; Sets SP to LoaderStack $61A7, zeroes the display file and attributes
; ($4000-$5AFF), then calls LoadBlock three times: block 5 to $4000, 6912 bytes
; (the loading screen, its attributes last, so the picture appears as the
; attributes come in); block 6 to Code1 $6B00, 37 633 bytes up to $FE00
; inclusive (the game's code1, its last byte over LoaderStart's DI, which has
; long run); the attributes zeroed again; block 7 to $4000, 4128 bytes (code2
; and the mover, invisible under the black attributes). Then JP Mover $5000.
;
; The carry LoadBlock returns is never tested here: a failed block does not
; come back (LoadExit). c1: L1 1; the three blocks start at frames 1259, 3862
; and 15 077 (docs/03 3.5).
LoadGame:
  DI
  LD SP,LoaderStack
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1AFF
  LD (HL),L
  LDIR
  LD IX,Screen
  LD DE,$1B00
  CALL LoadBlock
  LD IX,Code1
  LD DE,$9301
  CALL LoadBlock
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),L
  LDIR
  LD IX,Screen
  LD DE,$1020
  CALL LoadBlock
  JP Mover

; LD-BYTES changed: load DE bytes with flag $00 to IX, each stored as received
; XOR key XOR E
;
; A copy of the ROM's LD-BYTES ($0556-$05E2, with LD-EDGE-1 and LD-EDGE-2)
; moved to RAM, so the ROM's tape trap never fires. Input: IX the destination,
; DE the length; the flag byte must be $00 (A' = 0, carry set: LOAD, not
; VERIFY). Output: carry set when the parity came out right. It returns through
; LoadExit $FF9A, the address it pushes first (the ROM pushes SA/LD-RET $053F).
;
; The changes against the ROM: the border is black with MIC (LD A,$08, not $0F)
; and the colour bits OR $00, not $02; LdSync XORs C with $00 (the ROM $03);
; the stripe colour comes from an operand that counts up (LdBorderXor's $FF83,
; OR $F8 keeps its high bits set) instead of CPL; during the pilot two
; self-modified bytes keep the border still (LdStripe's OUT turned into LD A,n,
; LdColourStep's INC A into NOP) and LdSync turns them back; the store in
; LdLoop has no VERIFY branch: it counts key += 3 in the operand of LdKey
; ($FF32, zeroed per call), XORs it with E (the low byte of the count still to
; load) and L (the received byte), and stores at (IX+0).
;
; c1: L1 3 (three blocks); LdLoop 48 676 runs (6913 + 37 634 + 4129 bytes,
; flags included). tools/decrypt_tape.py check reproduces the stored bytes of
; the three blocks and encrypts them back identical.
LoadBlock:
  LD A,$3E
  LD (LdStripe),A
  XOR A
  LD (LdKey+$0001),A
  LD (LdColourStep),A
  LD A,$F9
  LD (LdBorderXor+$0001),A
  XOR A
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  LD A,$08
  OUT ($FE),A
  LD HL,LoadExit
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  OR $00
  LD C,A
  CP A
LdBreak:
  RET NZ                  ; RET NZ: the ROM's LD-BREAK, here only a return
LdStart:
  CALL LdEdge1            ; the ROM's LD-START: wait for an edge, then test for
                          ; about 1 s of silence
  JR NC,LdBreak
  LD HL,$0415
LdWait:
  DJNZ LdWait             ; the ROM's LD-WAIT
  DEC HL
  LD A,H
  OR L
  JR NZ,LdWait
  CALL LdEdge2
  JR NC,LdBreak
LdLeader:
  LD B,$9C                ; the ROM's LD-LEADER: 256 pilot pulses of the right
                          ; length
  CALL LdEdge2
  JR NC,LdBreak
  LD A,$C6
  CP B
  JR NC,LdStart
  INC H
  JR NZ,LdLeader
LdSync:
  LD B,$C9                ; the ROM's LD-SYNC: the short sync pulse, then the
                          ; stripes switched on
  CALL LdEdge1
  JR NC,LdBreak
  LD A,B
  CP $D4
  JR NC,LdSync
  CALL LdEdge1
  RET NC
  LD A,$D3
  LD (LdStripe),A
  LD A,$3C
  LD (LdColourStep),A
  LD A,C
  XOR $00
  LD C,A
  LD H,$00
  LD B,$B0
  JR LdMarker
LdLoop:
  EX AF,AF'               ; the ROM's LD-LOOP: the flag byte first (Z' set),
                          ; then the data bytes
  JR NZ,LdFlag
  PUSH AF
LdKey:
  LD A,$00                ; LD A,key: the byte key, +3 a byte; its operand
                          ; $FF32 is written here and zeroed per call
  ADD A,$03
  LD (LdKey+$0001),A
  XOR E
  XOR L
  LD (IX+$00),A
  POP AF
  JR LdNext
LdFlag:
  RL C                    ; the ROM's LD-FLAG: the flag must equal A' ($00),
                          ; else return with carry clear
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR LdDec
LdNext:
  INC IX                  ; the ROM's LD-NEXT: INC IX
LdDec:
  DEC DE                  ; the ROM's LD-DEC: one byte less to load
  EX AF,AF'
  LD B,$B2
LdMarker:
  LD L,$01                ; the ROM's LD-MARKER: L = 1, the bit marker
Ld8Bits:
  CALL LdEdge2            ; the ROM's LD-8-BITS: eight edge pairs make a byte
                          ; in L; H the running parity
  RET NC
  LD A,$CB
  CP B
  RL L
  LD B,$B0
  JP NC,Ld8Bits
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,LdLoop
  LD A,H
  CP $01
  RET

; The ROM's LD-EDGE-2: two edges
;
; Input: B the timing count, C the last edge's level and border colour. Output:
; carry set when both edges came before B overflowed. c1: L1 runs every bit of
; the three blocks.
LdEdge2:
  CALL LdEdge1
  RET NC

; The ROM's LD-EDGE-1: wait 358 T, then sample the EAR bit until it changes;
; stripe the border
;
; As the ROM's but for the border: the colour is C XOR the stripe colour (the
; ROM's CPL) AND 7, and after the OUT the stripe colour ($FF83, LdBorderXor's
; operand) is counted up, then the border goes back to black (LdStripe). During
; the pilot LdStripe holds LD A,$FE (byte $3E) and LdColourStep a NOP, set by
; LoadBlock's start; LdSync writes OUT ($FE),A ($D3) and INC A ($3C) back, so
; the stripes run only over the data.
LdEdge1:
  LD A,$16
LdDelay:
  DEC A                   ; the ROM's LD-DELAY
  JR NZ,LdDelay
  AND A
LdSample:
  INC B                   ; the ROM's LD-SAMPLE: B counts up, EAR read through
                          ; port $7FFE
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  XOR C
  AND $20
  JR Z,LdSample
  LD A,C
LdBorderXor:
  XOR $F9                 ; XOR n: the edge's colour; the operand $FF83 is the
                          ; stripe colour, counted at LdColourStep
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  LD A,(LdBorderXor+$0001)
LdColourStep:
  INC A                   ; INC A (during the pilot a NOP): the next stripe
                          ; colour
  OR $F8
  LD (LdBorderXor+$0001),A
  LD A,$08
LdStripe:
  OUT ($FE),A             ; OUT ($FE),A, black after each edge (during the
                          ; pilot LD A,$FE)
  SCF
  RET

; LoadBlock's return: black border; on carry return to LoadGame, else cycle the
; border for ever
;
; Reached by the RET of LoadBlock through the address it pushed (LD
; HL,LoadExit; PUSH HL). With carry set (the parity right) it returns to
; LoadGame. With carry clear (a parity error, a wrong flag, a break) it falls
; into LoadFailed, a loop that writes the border colours 1, 2, 3 ... with no
; exit: a bad load hangs with a striped border.
;
; c1: L1 3 at $FF9A and at the RET C; LoadFailed not executed in c1, the only
; recording that loads the tape (stage 1's docs/03 3.3 said a failed block runs
; on into what was loaded: the code says it hangs).
LoadExit:
  PUSH AF
  XOR A
  OUT ($FE),A
  POP AF
  RET C
LoadFailed:
  INC A                   ; INC A; OUT ($FE),A; loop: the endless striped
                          ; border of a failed load
  OUT ($FE),A
  JR LoadFailed

; Leftover: 91 bytes of the 48K ROM's font, $3E55-$3EAF ("J" from its sixth row
; to "U")
;
; No code reads them (c1: no L1 read). They equal the ROM's $3E55-$3EAF byte
; for byte (checked against data/rom/48.rom of unreal-ng): the master tape was
; saved from memory that held a copy of the font here. Kept as bytes, listed in
; src/res/README.md.
LoaderFontLeftover:
  DEFB $42,$3C,$00,$00,$44,$48,$70,$48
  DEFB $44,$42,$00,$00,$40,$40,$40,$40
  DEFB $40,$7E,$00,$00,$42,$66,$5A,$42
  DEFB $42,$42,$00,$00,$42,$62,$52,$4A
  DEFB $46,$42,$00,$00,$3C,$42,$42,$42
  DEFB $42,$3C,$00,$00,$7C,$42,$42,$7C
  DEFB $40,$40,$00,$00,$3C,$42,$42,$52
  DEFB $4A,$3C,$00,$00,$7C,$42,$42,$7C
  DEFB $44,$42,$00,$00,$3C,$40,$3C,$02
  DEFB $42,$3C,$00,$00,$FE,$10,$10,$10
  DEFB $10,$10,$00,$00,$42,$42,$42,$42
  DEFB $42,$3C,$00
