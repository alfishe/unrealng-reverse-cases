; --------------------------------------------------------------------------------------------------------------------
; tapeload.asm: The level loader's tape reader
; --------------------------------------------------------------------------------------------------------------------

; Load DE bytes to IX from tape at the game's turbo speed
;
; Interrupts off; pushes LoadDone so that every return enables interrupts
; again; waits for the pilot and the sync, then reads the flag and the bytes
; with the border stripes; carry set when the check byte is right.
;
; Witness: L1 32 (c1, deaths-l7, ending, l1-l8).
LoadBytes:
  DI
  LD A,$E6
  OR A
  SCF
  EX AF,AF'
  LD A,$02
  LD (EdgeLoop+$0011),A
  LD A,$0F
  OUT ($FE),A
  LD HL,LoadDone
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  LD C,A
l_8F38:
  LD H,$00
l_8F3A:
  LD B,$90
  CALL EdgePair
  JR NC,l_8F38
  LD A,$BF
  CP B
  JR NC,l_8F38
  INC H
  JR NZ,l_8F3A
l_8F49:
  LD B,$C3
  CALL EdgeOne
  JR NC,l_8F38
  LD A,B
  CP $D4
  JR NC,l_8F49
  CALL EdgeOne
  RET NC
  LD A,$01
  LD (EdgeLoop+$0011),A
  LD H,$00
  LD B,$C0
  JR l_8F83
l_8F64:
  EX AF,AF'
  JR NZ,l_8F6E
  JR NC,l_8F78
  LD (IX+$00),L
  JR l_8F7D
l_8F6E:
  RL C
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR l_8F7F
l_8F78:
  LD A,(IX+$00)
  XOR L
  RET NZ
l_8F7D:
  INC IX
l_8F7F:
  DEC DE
  EX AF,AF'
  LD B,$C2
l_8F83:
  LD L,$01
l_8F85:
  CALL EdgePair
  RET NC
  LD A,$DB
  CP B
  RL L
  LD B,$C0
  JP NC,l_8F85
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,l_8F64
  LD A,H
  CP $01
  RET

; Wait for two edges
;
; Witness: L1 893818 (c1, deaths-l7, ending, l1-l8).
EdgePair:
  CALL EdgeOne
  RET NC

; Wait for one edge on the EAR bit, counting B; carry when found
;
; Each edge flips the border: AND (patched at $8FB4: $02 pilot and sync, $01
; data) OR $08: red/black, then blue/black.
;
; Witness: L1 1866762 (c1, deaths-l7, ending, l1-l8).
EdgeOne:
  AND A
EdgeLoop:
  INC B                   ; the counting loop
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC
  XOR C
  AND $20
  JR Z,EdgeLoop
  LD A,C
  CPL
  LD C,A
  AND $02
  OR $08
  OUT ($FE),A
  SCF
  RET

; bytes no recording reads (known only from the heatmap)
Unused8FBB:
  DEFB $20,$28,$F4,$79,$2F,$4F,$ED,$5F
  DEFB $E6,$06,$F6,$08,$D3,$FE,$37,$C9
