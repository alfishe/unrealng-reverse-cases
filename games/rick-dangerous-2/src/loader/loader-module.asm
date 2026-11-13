; --------------------------------------------------------------------------------------------------------------------
; loader-module.asm: The loader: decipher itself, read the screen and the game with a bit-reversed LD-BYTES, enter the game
;
; The loader reads two headerless blocks the ROM cannot read: every byte of them is stored with its bits in reversed
; order (bit 0 first on the tape), and their XOR checksum is $FF, not 0. LdBytesReversed is the ROM's LD-BYTES ($0556)
; copied with three changes: a byte is shifted in from the top (LD L,$80 and RR L where the ROM has LD L,$01 and RL
; L), the checksum test is LD A,H; CPL; CP 1, and the verify branch is gone. A failed block returns to LoadFailed,
; which resets the machine (JP NC,0).
;
; The block is enciphered from $FF0B on the tape: Decipher XORs $FF0B-$FFFF with IYH ($5C, the high byte of the ROM's
; IY = $5C3A). The first byte it deciphers is the operand of its own JR NZ ($AB on the tape, $F7 = back to
; DecipherLoop), so the loop is enciphered too and still runs.
; --------------------------------------------------------------------------------------------------------------------

; Decipher $FF0B-$FFFF (XOR IYH = $5C), then load the screen and the game and
; enter it
;
; Entered by the BASIC's RANDOMIZE USR 65280 with IY = $5C3A (the ROM's system
; variables base). DE runs from $FF0B to $FFFF; each byte XOR IYH. The loop
; ends when D wraps to 0. The first byte deciphered is DecipherLoop's own JR NZ
; operand ($FF0B: $AB XOR $5C = $F7, the jump back).
;
; Then SP = 0 (the stack under the top of memory: the game keeps it so, and it
; grows down over this page), LdBytesReversed reads the loading screen (6912
; bytes, flag $FF) to $4000 and the game block ($9EFE bytes) to $6000, EI and
; JP GameEntry $7B8F.
;
; c1: entered at frame 1110 T 65 924, the deciphering done by frame 1111, the
; game entered at frame 13 998 T 9477.
;
; Witness: L1 1 (c1).
Decipher:
  LD DE,DecipherLoop+$0008
DecipherLoop:
  LD A,(DE)
  XOR IYH
  LD (DE),A
  INC DE
  LD A,D
  AND A
  JR NZ,DecipherLoop
  LD SP,$0000
  LD IX,Screen
  LD DE,$1B00
  LD A,$FF
  SCF
  CALL LdBytesReversed
  LD IX,TapeCode
  LD DE,$9EFE
  LD A,$FF
  SCF
  CALL LdBytesReversed
  EI
  JP GameEntry                ; interrupts on again: the IM 1 handler of the ROM
                          ; until the game's entry sets IM 2

; LD-BYTES with every byte's bits in reversed order: IX = address, DE = length,
; A = flag, carry set
;
; A copy of the ROM's LD-BYTES ($0556) with the same timing constants (the
; pilot, sync and edge loops), border colours and flag test. Differences: the
; bit shift register L starts at $80 and takes each bit by RR L (LdByte), so
; the first bit on the tape becomes bit 0; the checksum H must end as $FF (LD
; A,H; CPL; CP 1: carry set when good); the return address pushed at the start
; is LoadFailed ($FFD8) instead of the ROM's SA/LD-RET, so an error (or BREAK)
; resets the machine; the verify branch jumps to the next instruction (only
; loading is possible).
;
; Inputs: IX = the first byte, DE = the length, A = the flag ($FF), carry set.
; Output: the bytes in memory; returns through LoadFailed.
;
; c1: two blocks, the screen and then the game, until frame 13 998.
;
; Witness: L1 2 (c1).
LdBytesReversed:
  INC D
  EX AF,AF'
  DEC D
  DI
  LD A,$0F
  OUT ($FE),A
  LD HL,LoadFailed
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  OR $02
  LD C,A
  CP A
LdBreak:
  RET NZ                  ; RET NZ: the ROM's LD-BREAK
LdStart:
  CALL LdEdge1            ; wait for an edge, then the pilot
  JR NC,LdBreak
  LD HL,$0415
LdWait:
  DJNZ LdWait             ; a pause of about one second before the pilot is
                          ; timed
  DEC HL
  LD A,H
  OR L
  JR NZ,LdWait
  CALL LdEdge2
  JR NC,LdBreak
LdLeader:
  LD B,$9C                ; the pilot: 256 pulses of the leader length
  CALL LdEdge2
  JR NC,LdBreak
  LD A,$C6
  CP B
  JR NC,LdStart
  INC H
  JR NZ,LdLeader
LdSync:
  LD B,$C9                ; the sync pulse
  CALL LdEdge1
  JR NC,LdBreak
  LD A,B
  CP $D4
  JR NC,LdSync
  CALL LdEdge1
  RET NC
  LD A,C
  XOR $03
  LD C,A
  LD H,$00
  LD B,$B0
  JR LdByte
LdLoop:
  EX AF,AF'               ; one byte: the flag first, then the data
  JR NZ,LdFlag
  JR NC,LdStore
LdStore:
  LD (IX+$00),L           ; the ROM's LD-VERIFY test (JR NC) now jumps here as
                          ; well: the byte is always stored
  JR LdNext
LdFlag:
  RL C                    ; the first byte must equal the flag in A' (L XOR A)
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR LdDec
LdNext:
  INC IX
LdDec:
  DEC DE
  EX AF,AF'
  LD B,$B2
LdByte:
  LD L,$80                ; L = $80: the marker bit shifts out of bit 0 after 8
                          ; bits (RR L), the ROM's LD L,$01 and RL L reversed
LdBitLoop:
  CALL LdEdge2
  RET NC
  LD A,$CB
  CP B
  RR L
  LD B,$B0
  JP NC,LdBitLoop
  LD A,H
  XOR L
  LD H,A
LdParity:
  LD A,D                  ; DE = 0: the checksum test, H must be $FF
  OR E
  JR NZ,LdLoop
  LD A,H
  CPL
  CP $01
  RET

; Two edges: the ROM's LD-EDGE-2 (B = the time count, C = the border and EAR
; state)
;
; As the ROM's $05E3: LdEdge1 twice. Carry clear: timed out or BREAK. Witness:
; L1 0 (c1).
LdEdge2:
  CALL LdEdge1
  RET NC

; One edge: the ROM's LD-EDGE-1, the delay loop of 22, the border stripes
;
; As the ROM's $05E7: wait 358 T, then sample port $FE until the EAR bit
; changes or B wraps; on an edge the border colour toggles (C bits 0-2, OR 8
; for the MIC off). Carry clear: timed out or BREAK (SPACE in row $7F).
; Witness: L1 0 (c1).
LdEdge1:
  LD A,$16
LdDelay:
  DEC A
  JR NZ,LdDelay
  AND A
LdSample:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC
  XOR C
  AND $20
  JR Z,LdSample
  LD A,C
  CPL
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET

; The return of LdBytesReversed: a failed block resets the machine, a good one
; turns the border black
;
; Pushed by LdBytesReversed ($FF35) as its return address. Carry clear (a
; checksum error, a timeout or BREAK): JP 0, the machine resets. Carry set:
; border 0, RET to the loader. c1: two returns, both good.
;
; Witness: L1 0 (c1).
LoadFailed:
  JP NC,Reset
LoadGood:
  XOR A
  OUT ($FE),A
  RET

; 33 bytes of an older routine's tail, never run: the ROM's SA-BYTES fragments;
; the stack overwrites them
;
; LD A,$0D; LD B,$37; DJNZ; OUT ($FE),A; LD BC,$3B0E; EX AF,AF'; LD L,A; JP
; $FF7B; LD A,D; OR E; JR Z; LD L,(IX+0); LD A,H; XOR L; LD H,A; LD A,1; SCF;
; JP $FF99: the shape of the ROM's SA-BYTES ($04D0-$0510), its jumps pointing
; into this page. No instruction here runs in any recording (c1, the level
; loads). The game's stack grows down from $0000 into this tail (low mark $FFDC
; in c1, $FFE6 in the other recordings: docs/02-architecture.md 2.4), and the
; Kixx copy differs only here (32 bytes from offset 223).
LoaderTail:
  DEFB $3E,$0D,$06,$37,$10,$FE,$D3,$FE
  DEFB $01,$0E,$3B,$08,$6F,$C3,$7B,$FF
  DEFB $7A,$B3,$28,$0C,$DD,$6E,$00,$7C
  DEFB $AD,$67,$3E,$01,$37,$C3,$99,$FF
  DEFB $6C
