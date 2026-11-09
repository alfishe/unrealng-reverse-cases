; --------------------------------------------------------------------------------------------------------------------
; loader.asm: The turbo loader: a copy of the ROM's LD-BYTES with its own timings, a 16-bit sum, the jump to the game
;
; BASIC line 30 (RANDOMIZE USR 61440) enters TurboStart. It loads the 25000 bytes of tape block 5 to $8000-$E1A7 with
; TurboLdBytes, a byte-for-byte copy of the ROM's LD-BYTES $0556 with three timing constants changed (the turbo
; block's zero is 660 T and its one 1320 T where the ROM's are 855 T and 1710 T), adds the bytes into a 16-bit sum,
; compares it with GameSum and jumps to the game at $8000.
;
; A load error or a wrong sum jumps to 0, a reset: TurboStart first writes 0 into the ERR_SP target, so the ROM's
; error return would reset too. c1: entered at frame 250 (T 15 109), the block loads from frame 300 to 5529, the game
; is entered at frame 5556 (T 25 555).
; --------------------------------------------------------------------------------------------------------------------

; Load the game, check its sum, run it
;
; Entered by BASIC line 30 (RANDOMIZE USR 61440, c1 frame 250, T 15 109; one
; entry). Writes 0 into the two bytes ERR_SP points at (the address on the
; machine stack that a BASIC error returns to), so an error report would jump
; to 0 and reset the machine.
;
; Then TurboLdBytes with IX = $8000, DE = $61A8 (25000), A = $FF (the flag of a
; data block), carry set (load, not verify). No carry back is a load error: JP
; 0. Then TurboSumLoop adds the 25000 bytes into HL (each byte as BC = 0..255),
; compares HL with GameSum ($2E3F) and jumps to 0 when they differ, to the game
; at $8000 when they agree (c1 frame 5556, T 25 555).
;
; Outputs: none (it never returns). The sum is of the data bytes only; the XOR
; checksum of the tape block is TurboLdBytes' own check (TurboLoadDone).
TurboStart:
  LD HL,(ErrSp)
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD IX,GameEntry
  LD DE,$61A8
  LD A,$FF
  SCF
  CALL TurboLdBytes
  JP NC,$0000             ; no carry: the load failed (BREAK, a bad flag, the
                          ; XOR check): reset
  LD IX,GameEntry
  LD DE,$61A8
  LD HL,$0000
TurboSumLoop:
  LD B,$00                ; HL += the byte at IX, 25000 times (c1: 25000
                          ; passes)
  LD C,(IX+$00)
  ADD HL,BC
  INC IX
  DEC DE
  LD A,D
  OR E
  JR NZ,TurboSumLoop
  LD BC,(GameSum)
  OR A                    ; HL - GameSum: not zero is a wrong sum, reset
  SBC HL,BC
  JP NZ,$0000
  JP GameEntry                ; enter the game

; The 16-bit sum of the 25000 bytes of block 5: $2E3F
;
; Read once by TurboStart (LD BC,(GameSum) at $F02F, c1). tools/image.py
; asserts the same sum on the tape's bytes.
GameSum:
  DEFW $2E3F

; LD-BYTES with the turbo timings: load DE bytes at IX, flag A
;
; A copy of the ROM's LD-BYTES $0556-$05E2 instruction for instruction, with
; three constants changed: the timing counter B starts at $C4 (ROM $B0) before
; the marker and each later bit, at $C6 (ROM $B2) before the first bit of each
; byte, and a bit is a one when B passes $D5 (ROM $CB). The edge loop itself is
; the ROM's: TurboEdge1 delays and jumps to the ROM at $05EC, which counts B up
; by one every 59 T until the EAR bit changes. Inputs: IX the destination, DE
; the length, A the flag, carry set for LOAD (clear would verify). Output:
; carry set when the flag, every byte and the XOR checksum were right.
;
; Like the ROM's it pushes SaLdRet ($053F) as its return: every exit goes
; through the ROM's SA/LD-RET (border back, BREAK test, EI). It saves A and the
; carry in AF' (INC D / EX AF,AF' / DEC D), sets DI and the border to 15 (OUT
; $FE, $0F), and keeps in C the last EAR level with the border colour in bits
; 0-2 (red/cyan stripes on the pilot, blue/yellow on the data after the XOR
; $03).
;
; c1: one entry at frame 250, the block's last byte at frame 5529 (T 63 143);
; TurboByteLoop 25001 passes (the flag and 25000 bytes; the checksum byte ends
; the loop), TurboBitLoop 200016.
TurboLdBytes:
  INC D
  EX AF,AF'
  DEC D
  DI
  LD A,$0F
  OUT ($FE),A
  LD HL,SaLdRet
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  OR $02
  LD C,A
  CP A
TurboBreak:
  RET NZ                  ; RET NZ: BREAK pressed or the edge timed out (to
                          ; SaLdRet)
TurboStartSearch:
  CALL TurboEdge1         ; wait for the first edge, then a 1 s pause (DJNZ
                          ; over HL = $0415) and another edge
  JR NC,TurboBreak
  LD HL,$0415
TurboPause:
  DJNZ TurboPause         ; 1045 x 256 DJNZ passes, about a second (c1: 267 285
                          ; passes)
  DEC HL
  LD A,H
  OR L
  JR NZ,TurboPause
  CALL TurboEdge2
  JR NC,TurboBreak
TurboLeader:
  LD B,$9C                ; 256 pilot pulses each of B from $9C to more than
                          ; $C6
  CALL TurboEdge2
  JR NC,TurboBreak
  LD A,$C6
  CP B
  JR NC,TurboStartSearch
  INC H
  JR NZ,TurboLeader
TurboSync:
  LD B,$C9                ; wait for the short sync pulse (B below $D4), then
                          ; its second edge
  CALL TurboEdge1
  JR NC,TurboBreak
  LD A,B
  CP $D4
  JR NC,TurboSync
  CALL TurboEdge1
  RET NC
  LD A,C
  XOR $03
  LD C,A
  LD H,$00
  LD B,$C4
  JR TurboMarker
TurboByteLoop:
  EX AF,AF'               ; one byte: the first is the flag (TurboFlag), the
                          ; rest stored at IX (or verified)
  JR NZ,TurboFlag
  JR NC,TurboVerify
  LD (IX+$00),L
  JR TurboNext
TurboFlag:
  RL C                    ; the flag byte: wrong flag returns NZ; the byte loop
                          ; counts one more for it (INC DE)
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR TurboCount
TurboVerify:
  LD A,(IX+$00)           ; VERIFY: compare with the byte at IX (not executed
                          ; in c1, carry was set)
  XOR L
  RET NZ
TurboNext:
  INC IX                  ; IX + 1
TurboCount:
  DEC DE                  ; DE - 1, timing constant $C6 for the first bit
  EX AF,AF'
  LD B,$C6
TurboMarker:
  LD L,$01                ; L = 1: the marker bit, shifted out after 8 bits
TurboBitLoop:
  CALL TurboEdge2         ; one bit: two edges, B compared with $D5 (one when
                          ; it passed it), counter $C4 for the next
  RET NC
  LD A,$D5
  CP B
  RL L
  LD B,$C4
  JP NC,TurboBitLoop
TurboByteDone:
  LD A,H                  ; H ^= L: the XOR checksum; DE = 0 ends the block
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,TurboByteLoop
TurboLoadDone:
  LD A,H                  ; carry set when the XOR of the flag, the bytes and
                          ; the checksum byte is 0 (H = 0, CP 1)
  CP $01
  RET

; Two edges: TurboEdge1 twice (the ROM's LD-EDGE-2)
;
; Called 200 273 times in c1 (frames 300-5529): one per bit, one per pilot
; pulse and the sync's first half. Output as TurboEdge1; NC after the first
; edge returns NC.
TurboEdge2:
  CALL TurboEdge1
  RET NC

; One edge: the ROM's delay (A = $16) then the ROM's own edge loop at $05EC
;
; The ROM's LD-EDGE-1 $05E7 has the same delay; the loader keeps its own copy
; and jumps into the ROM after it, at $05EC (AND A, then LD-SAMPLE $05ED), so
; the ROM's edge loop counts B (INC B every pass, RET Z at the wrap = no edge),
; reads EAR, flips the border, and returns carry set with B the count. c1: 401
; 976 calls (frames 250-5529).
TurboEdge1:
  LD A,$16
TurboDelay:
  DEC A                   ; 22 passes of DEC A
  JR NZ,TurboDelay
  JP LdEdgeTail

; Bytes after the code no instruction reads: 10 bytes, then zeros, then
; "*TES*RESU*"
;
; No recording reads or runs $F0D7-$F0FF (c1: only the load writes them). 10
; bytes ($2B $24 $05 $00 $29 $40 $03 $00 $28 $21), 18 zeros, the text
; "*TES*RESU*" (USER and SET backwards), 3 zeros: what the author's development
; system left in the 256-byte block. Kept as bytes.
TurboLeftover:
  DEFB $2B,$24,$05,$00,$29,$40,$03,$00,$28,$21
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; zeros
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $2A,$54,$45,$53,$2A,$52,$45,$53,$55,$2A ; "*TES*RESU*"
  DEFB $00,$00,$00        ; zeros
