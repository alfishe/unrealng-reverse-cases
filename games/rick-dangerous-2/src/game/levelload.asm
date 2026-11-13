; --------------------------------------------------------------------------------------------------------------------
; levelload.asm: The tape level loader
;
; A level not in memory is read from side B: LoadLevel prints "START TAPE ON SIDE TWO", reads the next block into
; $A800 (21 760 bytes) and goes on until the block read is the wanted level (its LevelNumber, $C20C), then prints
; "STOP TAPE AND PRESS FIRE" and waits for fire. The loader is the ROM's LD-BYTES with the bits shifted in from the
; top (LD L,$80 / RR L), the verify branch removed and the parity test LD A,H / CPL / CP 1: side B's bytes are stored
; bit-reversed (stage 1). The RZX run's version has another loader here ($846A-$8510, a TAP version).
;
; The level blocks on side B carry the last 768 bytes of each level's maps enciphered; DecryptMaps restores them once
; the level is in memory. Side A's resident level 1 is stored plain.
; --------------------------------------------------------------------------------------------------------------------

  ORG $840C

; Read side B until the wanted level is in, then wait for fire
;
; $7A61, "START TAPE ON SIDE TWO" at $4845 (PrintText), LoadLevelBlock;
; LevelNumber not equal to Level: again (the blocks before the wanted one are
; read and dropped). Then $7A61, "STOP TAPE AND PRESS FIRE" at $4843 and
; LoadLevelWaitFire.
;
; Evidence: 16 runs in 6 builds (load-l2 2, load-l3 3, load-l4 4, load-l5 5:
; one more than the level's block number, side B holding levels 1-5 in order;
; rzx-l3-10000-poke 1, rzx-l4-20000-poke 1 run the RZX run's version).
;
; Witness: L1 18 (rzx-l3-10000-poke, rzx-l4-20000-poke, load-l2-load-l5).
LoadLevel:
  CALL ClearScreen
  LD HL,TapeTexts
  LD DE,Screen+2117
  CALL PrintText
  CALL LoadLevelBlock
  LD A,(Level)
  NOP                     ; NOP (a byte the TAP version patches?)
  LD C,A
  LD A,(LevelNumber)
  CP C
  JP NZ,LoadLevel
  CALL ClearScreen
  LD HL,StopTapeText      ; "STOP TAPE AND PRESS FIRE"
  LD DE,Screen+2115
  CALL PrintText

; Wait for fire, SPACE or ENTER after the load
;
; $7229 until Z.
;
; Evidence: 1 078 823 runs in 9 builds.
;
; Witness: L1 1238557 (rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke,
; rzx-l5-00000-poke, rzx-l5-full, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
LoadLevelWaitFire:
  CALL TestFireKeys
  JP NZ,LoadLevelWaitFire
  RET

; "START TAPE ON SIDE TWO", "STOP TAPE AND PRESS FIRE"
;
; Printed by LoadLevel with PrintText; $FF ends each.
TapeTexts:
  INCBIN "res/texts/tape.bin",$0000,23
StopTapeText:
  INCBIN "res/texts/tape.bin",$0017,25

; Load one bit-reversed block of 21 760 bytes into $A800
;
; IX = $A800, DE = 21 760, A = $FF (the flag of a data block), carry set
; (load): LdBytes, then EI (the loader leaves interrupts off).
;
; Evidence: 16 runs in 6 builds.
;
; Witness: L1 18 (rzx-l3-10000-poke, rzx-l4-20000-poke, load-l2-load-l5).
LoadLevelBlock:
  LD IX,CellFlags
  LD DE,21760
  LD A,$FF
  SCF
  CALL LdBytes
  EI
  RET

; LD-BYTES with the bits reversed: IX the address, DE the length, A the flag
;
; The ROM's $0556 step for step: DI, border 7 ($0F), LdBytesEnd pushed as the
; return, the leader, the sync, the flag byte, then the bytes. The differences
; from the ROM: each byte is shifted in from the top (L = $80, RR L), so the
; tape's bytes are stored bit-reversed; the verify branch is gone (every byte
; is stored); the end test is LD A,H / CPL / CP 1: carry when the XOR of the
; block was $FF. SPACE breaks (carry clear).
;
; Evidence: 14 runs in 4 builds (load-l2 ... load-l5; writes $A800-$FCFF; port
; $FE in and out).
;
; Witness: L1 14 (load-l2-load-l5).
LdBytes:
  INC D
  EX AF,AF'
  DEC D
  DI
  LD A,$0F
  OUT ($FE),A
  LD HL,LdBytesEnd
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  OR $02
  LD C,A
  CP A
LdBreak:
  RET NZ                  ; RET NZ: a break
LdStart:
  CALL LdEdge1            ; wait for the first edge
  JR NC,LdBreak
  LD HL,$0415
LdWait:
  DJNZ LdWait             ; a pause of about a second
  DEC HL
  LD A,H
  OR L
  JR NZ,LdWait
  CALL LdEdge2
  JR NC,LdBreak
LdLeader:
  LD B,$9C                ; the leader tone
  CALL LdEdge2
  JR NC,LdBreak
  LD A,$C6
  CP B
  JR NC,LdStart
  INC H
  JR NZ,LdLeader
LdSync:
  LD B,$C9                ; the sync pulses
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
  JR LdMarker
LdLoop:
  EX AF,AF'               ; a byte: the flag byte first
  JR NZ,LdFlag
  JR NC,LdStore
LdStore:
  LD (IX+$00),L           ; the byte stored (the ROM's verify is gone)
  JR LdNext
LdFlag:
  RL C                    ; the flag byte compared
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR LdDec
LdNext:
  INC IX                  ; IX + 1
LdDec:
  DEC DE                  ; DE - 1
  EX AF,AF'
  LD B,$B2
LdMarker:
  LD L,$80                ; L = $80: the byte comes in from the top
LdEightBits:
  CALL LdEdge2            ; a bit: RR L (the ROM: RL L)
  RET NC
  LD A,$CB
  CP B
  RR L
  LD B,$B0
  JP NC,LdEightBits
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,LdLoop
  LD A,H                  ; the checksum: CPL / CP 1, the XOR must be $FF
  CPL
  CP $01
  RET

; Two edges (the ROM's LD-EDGE-2)
;
; LdEdge1 twice.
;
; Evidence: 2 440 942 runs in 4 builds.
;
; Witness: L1 2440942 (load-l2-load-l5).
LdEdge2:
  CALL LdEdge1
  RET NC

; One edge (the ROM's LD-EDGE-1): B counts the time, the border flashes
;
; A delay of $16 loops, then B + 1 per sample of port $FE until the EAR bit
; changes; carry set on an edge (the border colour changed: (C AND 7) OR 8),
; clear on a time out (B wraps) or SPACE.
;
; Evidence: 4 899 114 runs in 4 builds (port $7FFE in, $FE out).
;
; Witness: L1 4899114 (load-l2-load-l5).
LdEdge1:
  LD A,$16
LdEdgeDelay:
  DEC A                   ; the delay before the samples
  JR NZ,LdEdgeDelay
  AND A
LdSample:
  INC B                   ; a sample of the EAR bit
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

; The loader's return: black border, or the load error
;
; Carry (a good block): border 0, return to LoadLevelBlock. No carry:
; LoadError.
;
; Evidence: 14 runs in 4 builds, every load good.
;
; Witness: L1 14 (load-l2-load-l5).
LdBytesEnd:
  JR NC,LoadError
  XOR A
  OUT ($FE),A
  RET

; POP HL / JP $8452: a load error
;
; The code bytes POP HL (the return to LoadLevelBlock dropped) and JP $8452, an
; address inside "STOP TAPE AND PRESS FIRE" ($8451): it would run the text as
; code. Probably an address from an earlier layout. Not executed in any
; recording (no load failed); a bad block would run it.
;
; Witness: L1 0 ().
LoadError:
  POP HL
  JP StopTapeText+1

; 204 bytes of $C9 (RET) up to $85F9
;
; Not read or run by any recording.
LoaderFill:
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9
  DEFB $C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9,$C9

  ORG $894E

; Decipher the last 768 bytes of the level's maps
;
; The 768 bytes from the maps' base (LevelHeader+4) + $600: each byte XOR a key
; that starts at 0 and becomes (key XOR the byte's address low byte) + 1 after
; each byte. Run once per loaded level, by the level start $7CDB after the tape
; load $840C (not for level 1 from side A, which is stored plain).
;
; Evidence: 9 runs in 9 builds (load-l2 ... load-l5 and the RZX level starts
; 2-5, rzx-l5-full), each over $E7ED-$ED6C for levels with the base $E1ED
; (level 4) and the same 768 bytes above each base; the deciphered bytes equal
; the RZX run's memory (NOTES).
;
; Witness: L1 48 (rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke,
; rzx-l5-00000-poke, rzx-l5-full, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DecryptMaps:
  LD HL,(LevelHeader+4)
  LD BC,$0600
  ADD HL,BC
  LD BC,$0300
  LD E,$00
DecryptMapsLoop:
  LD A,(HL)
  XOR E
  LD (HL),A
  LD A,E
  XOR L
  INC A
  LD E,A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,DecryptMapsLoop
  RET
