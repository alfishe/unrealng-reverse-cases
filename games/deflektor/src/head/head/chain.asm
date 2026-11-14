; --------------------------------------------------------------------------------------------------------------------
; chain.asm: D.G. Cooke's decryption chain: 30 layers keyed on sums of memory, then a 16-bit layer over the game
;
; The chain runs from $7B52 with SP = $5C00 (BlockHead's RET leaves it there; the CALLs' return addresses at
; $5BFE-$5BFF are summed with the rest); it depends on SP and on the whole of memory $4000-$FFFF: the loading screen,
; ChainFill's stream and the block itself (the loader and the BASIC are overwritten by then), so a changed byte
; anywhere breaks the keys. It is decrypted while it runs: each layer decrypts the bytes after its own call, so the
; code past a CALL exists only once that call has returned.
;
; ChainStart fills the printer buffer and the system variables' area $5B00-$7B51, then the space past the mover
; $FD1B-$FFFF, with a generated stream (D = $95, D = 17 x D + L + 11), then sums memory into A. Each of the 30 layers
; is a CALL followed by a key byte: XorLayer decrypts B bytes after the call with a running key (p = 17 x prev + C,
; XORed in), a sum layer (SumLayer1-3: three copies with their own addresses) adds memory from $4000 in steps of C + 1
; to A; both then add the key byte at the return address to A, write C over it and jump past it. On the original tape
; every layer's incoming A is 0: the key bytes are chosen so (src/head/keys.txt has them, the byte each layer finds
; and C, the byte it leaves).
;
; FinalSum makes a 16-bit sum of $4000-$FFFF (with its own operand at $7CA7 zeroed first), and Final16 decrypts
; $7D00-$FD19 in words with it: the whole game and the mover. The last decrypted word plus $7A3D is the jump: $FD00 on
; the original, the mover. A wrong key jumps wild.
; --------------------------------------------------------------------------------------------------------------------

; Fill $5B00-$7B51 with a generated stream (twice), then sum $4000-$FFFF into A
; and go to the first layer
;
; 1. D = `$95`, E = 2 passes: from HL = `$5B00`, BC = `$2052` bytes: (HL) = D,
; D = 17 x D + L + 11. After the first pass HL = `$FD1B`, BC = `$02E5` (the
; space past the mover, `$FD1B-$FFFF`), the second pass.
;
; 2. A = D, HL = `$4000`: A + each byte to `$FFFF` (the carry out of HL ends
; the loop); `JR C` to ChainLayers.
;
; The stream overwrites the BASIC, the system variables and the loader's stack
; area, so nothing of the BASIC loader survives.
;
; Witness: L1 2 (c1).
ChainStart:
  LD DE,$9502
  LD HL,MoveStub
  LD BC,$2052
ChainFill:
  LD A,D                  ; one byte of the stream
  LD (HL),A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,D
  ADD A,L
  ADD A,$0B
  LD D,A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,ChainFill
  LD HL,$FD1B
  LD BC,$02E5
  DEC E
  JR NZ,ChainFill
  LD HL,$4000             ; the sum of $4000-$FFFF into A
  LD BC,$0001
  LD A,D
ChainSum:
  ADD A,(HL)
  ADD HL,BC
  JP NC,ChainSum
  JR C,ChainLayers

; Decrypt the B bytes after the CALL with key A and step C, add the key byte at
; the return address to A, write C there, return past it
;
; In: A the key, B the count (0 = 256), C the step; the return address on the
; stack.
;
; Each byte: D = A, A = 17 x D + C, XOR (HL), stored; the decrypted byte is the
; next key. Then B restored from E, A + (return address), (return address) = C,
; `JP` to the return address + 1.
;
; c1: 3642 bytes decrypted over 372 addresses (`$7BC0-$7D33`), up to 17 layers
; on one address.
;
; Witness: L1 36 (c1).
XorLayer:
  POP HL
  PUSH HL
  LD E,B
XorLayerByte:
  INC HL
  LD D,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,D
  ADD A,C
  XOR (HL)
  LD (HL),A
  DJNZ XorLayerByte
  LD B,E
  POP HL
  ADD A,(HL)
  LD (HL),C
  INC HL
  JP (HL)

; "COPYRIGHT D.G.COOKE 1987" after a plant byte: ChainLayers writes $CB at
; $7B99 (the tape has $45 there) before the first layer
;
; Inside the first layers' range: XorLayer decrypts over it, so the text is
; also key material.
ChainText:
  DEFM $CB,"COPYRIGHT D.G.COOKE 1987"

; The 30 layers in turn: each CALL is followed by its key byte, and the code
; after it exists only once the call returns
;
; 1. `$CB` at ChainText (the plant), BC = `$46D9` with bit 7 of B set: the
; first XorLayer.
;
; 2. Then layer after layer, B and C changed by shifts and increments between
; the calls (the key byte after each CALL is data, `@inline`: the layer writes
; C over it and jumps past it; read as code it would be an EXX, an OR E and the
; like). Sum layers SumLayer1 `$7BD2`, SumLayer2 `$7C15`, SumLayer3 `$7C54` sit
; inside the run, jumped over by `JR`.
;
; 3. After the 30th layer (at `$7CA2`): FinalSum.
;
; c1: 30 layers, incoming A = 0 each (src/head/keys.txt).
;
; Witness: L1 2 (c1).
ChainLayers:
  LD HL,ChainText
  LD (HL),$CB
  LD BC,$46D9
  SET 7,B
  CALL XorLayer
KeyByte1:
  DEFB $D9                ; key byte 1 (XorLayer): A + 115 (the tape's byte),
                          ; then C = $D9 written here, 198 bytes decrypted
  SRL B
  SET 7,B
  CALL XorLayer
KeyByte2:
  DEFB $D9                ; key byte 2 (XorLayer): A + 69 (the tape's byte),
                          ; then C = $D9 written here, 227 bytes decrypted
  RRC B
  RLC C
  CALL XorLayer
KeyByte3:
  DEFB $B3                ; key byte 3 (XorLayer): A + 210 (the tape's byte),
                          ; then C = $B3 written here, 241 bytes decrypted
  JR ChainLayers2

; A + B + the sum of every (C + 1)th byte from $4000 to $FFFF, then the key
; byte at the return address, C written over it
;
; In: A the key, B, C the step - 1. HL = `$4000`, DE = C + 1; A + B, then A +
; (HL) until HL carries out past `$FFFF`; A + (return address), (return
; address) = C, `JP` past it.
;
; SumLayer2 `$7C15` and SumLayer3 `$7C54` are the same code at other addresses
; (the chain's own bytes take part in the sums, so three copies give three
; different chains of keys).
;
; Witness: L1 12 (c1).
SumLayer1:
  LD HL,$4000
  LD D,L
  LD E,C
  INC DE
  ADD A,B
SumLayer1Loop:
  ADD A,(HL)
  ADD HL,DE
  JP NC,SumLayer1Loop
  POP HL
  ADD A,(HL)
  LD (HL),C
  INC HL
  JP (HL)

; The chain goes on past SumLayer1 (jumped over by a JR): the next layers
;
; Part of ChainLayers, cut by the sum layer that sits inside the run.
;
; Witness: L1 2 (c1).
ChainLayers2:
  RRC C
  CALL XorLayer
KeyByte4:
  DEFB $D9                ; key byte 4 (XorLayer): A + 67 (the tape's byte),
                          ; then C = $D9 written here, 241 bytes decrypted
  SRA B
  INC C
  CALL XorLayer
KeyByte5:
  DEFB $DA                ; key byte 5 (XorLayer): A + 223 (the tape's byte),
                          ; then C = $DA written here, 248 bytes decrypted
Layers6:
  RLC C
  CALL SumLayer1
KeyByte6:
  DEFB $B5                ; key byte 6 (a sum layer): A + 87 (the tape's byte),
                          ; then C = $B5 written here
  INC B
  CALL XorLayer
KeyByte7:
  DEFB $B5                ; key byte 7 (XorLayer): A + 250 (the tape's byte),
                          ; then C = $B5 written here, 249 bytes decrypted
  RLC B
  SRA C
  CALL SumLayer1
KeyByte8:
  DEFB $DA                ; key byte 8 (a sum layer): A + 121 (the tape's
                          ; byte), then C = $DA written here
Layers9:
  CALL SumLayer1
KeyByte9:
  DEFB $DA                ; key byte 9 (a sum layer): A + 121 (the tape's
                          ; byte), then C = $DA written here
Layers10:
  RES 1,B
  CALL XorLayer
KeyByte10:
  DEFB $DA                ; key byte 10 (XorLayer): A + 3 (the tape's byte),
                          ; then C = $DA written here, 241 bytes decrypted
Layers11:
  SRL C
  CALL XorLayer
KeyByte11:
  DEFB $6D                ; key byte 11 (XorLayer): A + 69 (the tape's byte),
                          ; then C = $6D written here, 241 bytes decrypted
  JR ChainLayers3

; A copy of SumLayer1
;
; The same eleven instructions as SumLayer1 `$7BD2`.
;
; Witness: L1 6 (c1).
SumLayer2:
  LD HL,$4000
  LD D,L
  LD E,C
  INC DE
  ADD A,B
SumLayer2Loop:
  ADD A,(HL)
  ADD HL,DE
  JP NC,SumLayer2Loop
  POP HL
  ADD A,(HL)
  LD (HL),C
  INC HL
  JP (HL)

; The chain goes on past SumLayer2 (jumped over by a JR): the next layers
;
; Part of ChainLayers, cut by the sum layer that sits inside the run.
;
; Witness: L1 2 (c1).
ChainLayers3:
  RLC B
  SRA C
  CALL XorLayer
KeyByte12:
  DEFB $36                ; key byte 12 (XorLayer): A + 119 (the tape's byte),
                          ; then C = $36 written here, 227 bytes decrypted
Layers13:
  INC C
  CALL SumLayer2
KeyByte13:
  DEFB $37                ; key byte 13 (a sum layer): A + 91 (the tape's
                          ; byte), then C = $37 written here
  INC B
  CALL XorLayer
KeyByte14:
  DEFB $37                ; key byte 14 (XorLayer): A + 209 (the tape's byte),
                          ; then C = $37 written here, 228 bytes decrypted
  SLA B
  SRA C
  CALL XorLayer
KeyByte15:
  DEFB $1B                ; key byte 15 (XorLayer): A + 203 (the tape's byte),
                          ; then C = $1B written here, 200 bytes decrypted
  SRA B
  CALL XorLayer
KeyByte16:
  DEFB $1B                ; key byte 16 (XorLayer): A + 214 (the tape's byte),
                          ; then C = $1B written here, 228 bytes decrypted
  DEC B
  LD C,B
  CALL SumLayer1
KeyByte17:
  DEFB $E3                ; key byte 17 (a sum layer): A + 220 (the tape's
                          ; byte), then C = $E3 written here
  RLC B
  CALL SumLayer1
KeyByte18:
  DEFB $E3                ; key byte 18 (a sum layer): A + 248 (the tape's
                          ; byte), then C = $E3 written here
  JR ChainLayers4

; A copy of SumLayer1
;
; The same eleven instructions as SumLayer1 `$7BD2`.
;
; Witness: L1 6 (c1).
SumLayer3:
  LD HL,$4000
  LD D,L
  LD E,C
  INC DE
  ADD A,B
SumLayer3Loop:
  ADD A,(HL)
  ADD HL,DE
  JP NC,SumLayer3Loop
  POP HL
  ADD A,(HL)
  LD (HL),C
  INC HL
  JP (HL)

; The chain goes on past SumLayer3 (jumped over by a JR): the next layers
;
; Part of ChainLayers, cut by the sum layer that sits inside the run.
;
; Witness: L1 2 (c1).
ChainLayers4:
  RLC B
  CALL SumLayer3
KeyByte19:
  DEFB $E3                ; key byte 19 (a sum layer): A + 48 (the tape's
                          ; byte), then C = $E3 written here
  SET 0,C
  CALL XorLayer
KeyByte20:
  DEFB $E3                ; key byte 20 (XorLayer): A + 233 (the tape's byte),
                          ; then C = $E3 written here, 143 bytes decrypted
  CALL XorLayer
KeyByte21:
  DEFB $E3                ; key byte 21 (XorLayer): A + 116 (the tape's byte),
                          ; then C = $E3 written here, 143 bytes decrypted
  SET 7,B
  CALL XorLayer
KeyByte22:
  DEFB $E3                ; key byte 22 (XorLayer): A + 241 (the tape's byte),
                          ; then C = $E3 written here, 143 bytes decrypted
  CALL SumLayer3
KeyByte23:
  DEFB $E3                ; key byte 23 (a sum layer): A + 149 (the tape's
                          ; byte), then C = $E3 written here
  CALL XorLayer
KeyByte24:
  DEFB $E3                ; key byte 24 (XorLayer): A + 176 (the tape's byte),
                          ; then C = $E3 written here, 143 bytes decrypted
  DEC C
  CALL SumLayer1
KeyByte25:
  DEFB $E2                ; key byte 25 (a sum layer): A + 208 (the tape's
                          ; byte), then C = $E2 written here
Layers26:
  CALL XorLayer
KeyByte26:
  DEFB $E2                ; key byte 26 (XorLayer): A + 90 (the tape's byte),
                          ; then C = $E2 written here, 143 bytes decrypted
Layers27:
  SLA B
  RRC C
  SET 7,B
  CALL XorLayer
KeyByte27:
  DEFB $71                ; key byte 27 (XorLayer): A + 228 (the tape's byte),
                          ; then C = $71 written here, 158 bytes decrypted
  CALL SumLayer2
KeyByte28:
  DEFB $71                ; key byte 28 (a sum layer): A + 172 (the tape's
                          ; byte), then C = $71 written here
  INC B
  SRA C
  CALL SumLayer2
KeyByte29:
  DEFB $38                ; key byte 29 (a sum layer): A + 163 (the tape's
                          ; byte), then C = $38 written here
Layers30:
  INC C
  CALL SumLayer3
KeyByte30:
  DEFB $39                ; key byte 30 (a sum layer): A + 180 (the tape's
                          ; byte), then C = $39 written here

; Zero its own operand, sum $4000-$FFFF as 16-bit words into DE, decrypt
; $7D00-$FD19 with it, jump to the last word + $7A3D
;
; 1. DE = A (the 30th layer's A; E = 146 on the tape: the operand at `$7CA7`
; was 200 when it ran as part of the sums), A = 0 stored into that operand
; (`$7CA7`), so the sum below does not count it.
;
; 2. HL = `$4000`, BC = 1: DE + the word at HL, HL + 2, to `$FFFF`. On the tape
; DE = `$43FB` (src/head/keys.txt key16).
;
; 3. Final16 `$7CBE`: L = E, B = D (as H), C = `$29`; from `$7D00` in words: H
; = L, HL + BC, the low byte XOR L (L = the new byte), the high byte XOR H (B =
; the new byte), to `$FD1A`.
;
; 4. HL = the last word (`$82C3` on the tape) + `$7A3D` = `$FD00`; bit 7 of R
; set; `JP (HL)`: the mover.
;
; c1: the 16-bit layer over 32794 bytes, 16397 words.
;
; Witness: L1 2 (c1).
FinalSum:
  LD D,$00
  LD E,A
  XOR A
  LD (FinalSum+$0001),A
  LD HL,$4000
  LD BC,$0001
FinalSumLoop:
  LD A,E
  ADD A,(HL)
  LD E,A
  INC HL
  LD A,D
  ADC A,(HL)
  LD D,A
  ADD HL,BC
  JP NC,FinalSumLoop
Final16:
  EX DE,HL                ; the 16-bit layer over $7D00-$FD19
  LD DE,$7D00
  LD C,$29
  LD B,H
Final16Loop:
  LD H,L
  ADD HL,BC
  LD A,(DE)
  XOR L
  LD (DE),A
  LD L,A
  INC DE
  LD A,(DE)
  XOR H
  LD (DE),A
  INC DE
  LD B,A
  LD A,E
  CP $1A
  JP NZ,Final16Loop
  LD A,D
  CP $FD
  JR NZ,Final16Loop
  LD H,B                  ; the last word + $7A3D: the mover's address
  LD DE,$7A3D
  ADD HL,DE
  LD A,R
  SET 7,A
  LD R,A
  JP (HL)

; "COPYRIGHT D.G.COOKE 1987" again, the chain's last bytes before the game
;
; Not read by the chain's code; the 16-bit layer starts after it, at `$7D00`.
ChainText2:
  DEFM "COPYRIGHT D.G.COOKE 1987"
