; --------------------------------------------------------------------------------------------------------------------
; chain-module.asm: The decryption chain and the SpeedLock 7 reader
;
; The BASIC copies 4840 enciphered bytes to $EC00 and RETs there (CopyChain). Each layer of the chain first wipes the
; 100 bytes behind it with LDDR, then deciphers the rest of the chain in place with R (set to $45 at the start, so its
; count is part of the key) and its own constants: ADD / SUB / XOR with a running byte, or keyed by its own address (a
; CALL whose callee POPs the return address into IX and mixes IXH and IXL into each byte, then leaves through JP (IX)
; whose $DD,$E9 bytes the next layer leaves as data). tools/speedlock7.py follows the 119 rewrites; this view holds
; every layer as it runs.
;
; The last layer leaves the SpeedLock 7 reader at $FB7E: it checks the ROM ($0000 must be $F3), silences the interface
; ports, clears the RAM and the screen, then loads the second stage (TZX block 7) to $FEE8 with its own edge timing
; and a 7-pulse sync pattern.
; --------------------------------------------------------------------------------------------------------------------

; The first layer: R = $45, wipe behind, decipher $12B4 bytes keyed by the
; CALL's return address
;
; Witness: L1 1 (c1).
ChainStart:
  LD A,$45
  LD R,A
  LD HL,ChainStart+$0004
  LD DE,ChainStart+$0003
  LD BC,$0064
  LDDR
  LD BC,$12B4
  LD HL,l_EC34
  CALL LayerKeyed01

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed01:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_EC1F:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_EC31
  JP l_EC34
l_EC31:
  JP l_EC1F
l_EC34:
  LD HL,l_EC34+$0003
  LD BC,$0064
  LD DE,l_EC34+$0002
  LDDR
  LD HL,l_EC47+$000B
  LD BC,$1296
  LD D,$00
l_EC47:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_EC47
  JP l_EC56
l_EC56:
  LD HL,l_EC5E+$0010
  LD BC,$127A
  LD D,$04
l_EC5E:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer02
  JP l_EC5E

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit01:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer02:
  LD HL,Layer02+$0003
  LD BC,$0064
  LD DE,Layer02+$0002
  LDDR
  LD HL,l_EC84+$000B
  LD BC,$1259
  LD D,$0C
l_EC84:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_EC84
  JP l_EC93
l_EC93:
  LD HL,l_EC93
  LD DE,l_EC84+$000E
  LD BC,$0064
  LDDR
  LD BC,$1225
  LD HL,l_ECC3
  CALL LayerKeyed03

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed03:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_ECAE:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_ECC0
  JP l_ECC3
l_ECC0:
  JP l_ECAE
l_ECC3:
  LD HL,l_ECCB+$0010
  LD BC,$120D
  LD D,$00
l_ECCB:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer04
  JP l_ECCB

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit03:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer04:
  LD DE,Layer04+$0002
  LD HL,Layer04+$0003
  LD BC,$0064
  LDDR
  LD BC,$11EC
  LD SP,l_FED6+$0010
l_ECEF:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_ECEF
  JP l_ECFF
l_ECFF:
  LD HL,l_ECFF
  LD DE,l_ECEF+$000F
  LD BC,$0064
  LDDR
  LD BC,$11B9
  LD HL,l_ED2F
  CALL LayerKeyed05

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed05:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_ED1A:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_ED2C
  JP l_ED2F
l_ED2C:
  JP l_ED1A
l_ED2F:
  LD DE,$11AC
  LD HL,l_ED35+$0007
l_ED35:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_ED35
  JP l_ED40
l_ED40:
  LD HL,l_ED40
  LD DE,l_ED35+$000A
  LD BC,$0064
  LDDR
  LD BC,$1178
  LD HL,l_ED70
  CALL LayerKeyed06

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed06:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_ED5B:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_ED6D
  JP l_ED70
l_ED6D:
  JP l_ED5B
l_ED70:
  LD SP,l_ED70+$000F
  LD HL,l_ED70+$000C
  LD DE,l_ED70+$000B
  LD BC,$0020
  LDDR
  JP PE,l_ED94
  LD HL,l_ED8A+$0009
  LD DE,l_ED70+$000E
  LD BC,$1155
l_ED8A:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_ED8A
l_ED94:
  LD HL,l_ED9C+$0010
  LD BC,$113C
  LD D,$00
l_ED9C:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer07
  JP l_ED9C

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit06:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer07:
  LD DE,Layer07+$0002
  LD HL,Layer07+$0003
  LD BC,$0064
  LDDR
  LD BC,$111B
  LD SP,l_FED6+$0010
l_EDC0:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_EDC0
  JP l_EDD0
l_EDD0:
  LD DE,$110B
  LD HL,l_EDD6+$0007
l_EDD6:
  DEC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_EDD6
  JP l_EDE1
l_EDE1:
  LD HL,l_EDE1+$0004
  LD BC,$0032
  LD DE,l_EDE1+$0003
  LDDR
  LD HL,l_EDF4+$000C
  LD BC,$10E8
  LD D,$0C
l_EDF4:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_EDF4
  JP l_EE04
l_EE04:
  LD HL,l_EE0C+$0010
  LD BC,$10CC
  LD D,$00
l_EE0C:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer08
  JP l_EE0C

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit07:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer08:
  LD SP,Layer08+$000F
  LD HL,Layer08+$000C
  LD DE,Layer08+$000B
  LD BC,$0020
  LDDR
  JP PE,l_EE43
  LD HL,l_EE39+$0009
  LD DE,Layer08+$000E
  LD BC,$10A6
l_EE39:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_EE39
l_EE43:
  LD HL,l_EE43+$0004
  LD BC,$0032
  LD DE,l_EE43+$0003
  LDDR
  LD HL,l_EE56+$000C
  LD BC,$1086
  LD D,$08
l_EE56:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_EE56
  JP l_EE66
l_EE66:
  LD HL,l_EE66+$0003
  LD BC,$0064
  LD DE,l_EE66+$0002
  LDDR
  LD HL,l_EE79+$000B
  LD BC,$1064
  LD D,$08
l_EE79:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_EE79
  JP l_EE88
l_EE88:
  LD SP,l_EE88+$000F
  LD HL,l_EE88+$000C
  LD DE,l_EE88+$000B
  LD BC,$0020
  LDDR
  JP PE,l_EEAC
  LD HL,l_EEA2+$0009
  LD DE,l_EE88+$000E
  LD BC,$103D
l_EEA2:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_EEA2
l_EEAC:
  LD HL,l_EEB4+$0010
  LD BC,$1024
  LD D,$02
l_EEB4:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer09
  JP l_EEB4

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit08:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer09:
  LD HL,Layer09
  LD DE,LayerExit08+$0001
  LD BC,$0064
  LDDR
  LD BC,$0FF1
  LD HL,l_EEF7
  CALL LayerKeyed10

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed10:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_EEE2:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_EEF4
  JP l_EEF7
l_EEF4:
  JP l_EEE2
l_EEF7:
  LD HL,l_EEFF+$0010
  LD BC,$0FD9
  LD D,$00
l_EEFF:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer11
  JP l_EEFF

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit10:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer11:
  LD HL,Layer11
  LD BC,$0064
  LD DE,LayerExit10+$0001
  LDDR
  LD HL,l_EF23+$000A
  LD BC,$0FBB
l_EF23:
  LD A,R
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_EF23
  JP l_EF31
l_EF31:
  LD HL,l_EF39+$0010
  LD BC,$0F9F
  LD D,$00
l_EF39:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer12
  JP l_EF39

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit11:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer12:
  LD HL,Layer12
  LD DE,LayerExit11+$0001
  LD BC,$0064
  LDDR
  LD BC,$0F6C
  LD HL,l_EF7C
  CALL LayerKeyed13

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed13:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_EF67:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_EF79
  JP l_EF7C
l_EF79:
  JP l_EF67
l_EF7C:
  LD HL,l_EF7C+$0004
  LD BC,$0032
  LD DE,l_EF7C+$0003
  LDDR
  LD HL,l_EF8F+$000C
  LD BC,$0F4D
  LD D,$02
l_EF8F:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_EF8F
  JP l_EF9F
l_EF9F:
  LD HL,l_EF9F
  LD DE,l_EF8F+$000F
  LD BC,$0064
  LDDR
  LD BC,$0F19
  LD HL,l_EFCF
  CALL LayerKeyed14

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed14:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_EFBA:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_EFCC
  JP l_EFCF
l_EFCC:
  JP l_EFBA
l_EFCF:
  LD DE,l_EFCF+$0002
  LD HL,l_EFCF+$0003
  LD BC,$0064
  LDDR
  LD BC,$0EFB
  LD SP,l_FED6+$0010
l_EFE0:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_EFE0
  JP l_EFF0
l_EFF0:
  LD HL,l_EFF0
  LD DE,l_EFE0+$000F
  LD BC,$0064
  LDDR
  LD BC,$0EC8
  LD HL,l_F020
  CALL LayerKeyed15

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed15:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F00B:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F01D
  JP l_F020
l_F01D:
  JP l_F00B
l_F020:
  LD DE,$0EBB
  LD HL,l_F026+$0007
l_F026:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F026
  JP l_F031
l_F031:
  LD HL,l_F031
  LD BC,$0064
  LD DE,l_F026+$000A
  LDDR
  LD HL,l_F042+$000A
  LD BC,$0E9C
l_F042:
  LD A,R
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F042
  JP l_F050
l_F050:
  LD DE,l_F050+$0002
  LD HL,l_F050+$0003
  LD BC,$0064
  LDDR
  LD BC,$0E7A
  LD SP,l_FED6+$0010
l_F061:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F061
  JP l_F071
l_F071:
  LD HL,l_F079+$0010
  LD BC,$0E5F
  LD D,$04
l_F079:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer16
  JP l_F079

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit15:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer16:
  LD DE,Layer16+$0002
  LD HL,Layer16+$0003
  LD BC,$0064
  LDDR
  LD BC,$0E3E
  LD SP,l_FED6+$0010
l_F09D:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F09D
  JP l_F0AD
l_F0AD:
  LD HL,l_F0AD
  LD BC,$0064
  LD DE,l_F09D+$000F
  LDDR
  LD HL,l_F0BE+$000A
  LD BC,$0E20
l_F0BE:
  LD A,R
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F0BE
  JP l_F0CC
l_F0CC:
  LD DE,l_F0CC+$0002
  LD HL,l_F0CC+$0003
  LD BC,$0064
  LDDR
  LD BC,$0DFE
  LD SP,l_FED6+$0010
l_F0DD:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F0DD
  JP l_F0ED
l_F0ED:
  LD HL,l_F0F5+$0010
  LD BC,$0DE3
  LD D,$02
l_F0F5:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer17
  JP l_F0F5

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit16:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer17:
  LD DE,$0DD3
  LD HL,l_F10E+$0007
l_F10E:
  DEC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F10E
  JP l_F119
l_F119:
  LD HL,l_F121+$0010
  LD BC,$0DB7
  LD D,$0C
l_F121:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer18
  JP l_F121

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit17:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer18:
  LD HL,Layer18
  LD DE,LayerExit17+$0001
  LD BC,$0064
  LDDR
  LD BC,$0D84
  LD HL,l_F164
  CALL LayerKeyed19

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed19:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F14F:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F161
  JP l_F164
l_F161:
  JP l_F14F
l_F164:
  LD HL,l_F164+$0003
  LD BC,$0064
  LD DE,l_F164+$0002
  LDDR
  LD HL,l_F177+$000B
  LD BC,$0D66
  LD D,$02
l_F177:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F177
  JP l_F186
l_F186:
  LD HL,l_F186
  LD DE,l_F177+$000E
  LD BC,$0064
  LDDR
  LD BC,$0D32
  LD HL,l_F1B6
  CALL LayerKeyed20

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed20:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F1A1:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F1B3
  JP l_F1B6
l_F1B3:
  JP l_F1A1
l_F1B6:
  LD HL,l_F1B6+$0003
  LD BC,$0064
  LD DE,l_F1B6+$0002
  LDDR
  LD HL,l_F1C9+$000B
  LD BC,$0D14
  LD D,$09
l_F1C9:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F1C9
  JP l_F1D8
l_F1D8:
  LD HL,l_F1D8
  LD DE,l_F1C9+$000E
  LD BC,$0064
  LDDR
  LD BC,$0CE0
  LD HL,l_F208
  CALL LayerKeyed21

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed21:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F1F3:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F205
  JP l_F208
l_F205:
  JP l_F1F3
l_F208:
  LD DE,$0CD3
  LD HL,l_F20E+$0007
l_F20E:
  DEC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F20E
  JP l_F219
l_F219:
  LD DE,l_F219+$0002
  LD HL,l_F219+$0003
  LD BC,$0064
  LDDR
  LD BC,$0CB1
  LD SP,l_FED6+$0010
l_F22A:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F22A
  JP l_F23A
l_F23A:
  LD HL,l_F23A+$0003
  LD BC,$0064
  LD DE,l_F23A+$0002
  LDDR
  LD HL,l_F24D+$000B
  LD BC,$0C90
  LD D,$02
l_F24D:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F24D
  JP l_F25C
l_F25C:
  LD HL,l_F25C
  LD DE,l_F24D+$000E
  LD BC,$0064
  LDDR
  LD BC,$0C5C
  LD HL,l_F28C
  CALL LayerKeyed22

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed22:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F277:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F289
  JP l_F28C
l_F289:
  JP l_F277
l_F28C:
  LD HL,l_F28C+$0004
  LD BC,$0032
  LD DE,l_F28C+$0003
  LDDR
  LD HL,l_F29F+$000C
  LD BC,$0C3D
  LD D,$00
l_F29F:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F29F
  JP l_F2AF
l_F2AF:
  LD HL,l_F2AF+$0003
  LD BC,$0064
  LD DE,l_F2AF+$0002
  LDDR
  LD HL,l_F2C2+$000B
  LD BC,$0C1B
  LD D,$01
l_F2C2:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F2C2
  JP l_F2D1
l_F2D1:
  LD SP,l_F2D1+$000F
  LD HL,l_F2D1+$000C
  LD DE,l_F2D1+$000B
  LD BC,$0020
  LDDR
  JP PE,l_F2F5
  LD HL,l_F2EB+$0009
  LD DE,l_F2D1+$000E
  LD BC,$0BF4
l_F2EB:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_F2EB
l_F2F5:
  LD DE,$0BE6
  LD HL,l_F2FB+$0007
l_F2FB:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F2FB
  JP l_F306
l_F306:
  LD HL,l_F30E+$0010
  LD BC,$0BCA
  LD D,$04
l_F30E:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer23
  JP l_F30E

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit22:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer23:
  LD DE,$0BBA
  LD HL,l_F327+$0007
l_F327:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F327
  JP l_F332
l_F332:
  LD DE,l_F332+$0002
  LD HL,l_F332+$0003
  LD BC,$0064
  LDDR
  LD BC,$0B98
  LD SP,l_FED6+$0010
l_F343:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F343
  JP l_F353
l_F353:
  LD HL,l_F353
  LD DE,l_F343+$000F
  LD BC,$0064
  LDDR
  LD BC,$0B65
  LD HL,l_F383
  CALL LayerKeyed24

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed24:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F36E:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F380
  JP l_F383
l_F380:
  JP l_F36E
l_F383:
  LD HL,l_F383+$0003
  LD BC,$0064
  LD DE,l_F383+$0002
  LDDR
  LD HL,l_F396+$000B
  LD BC,$0B47
  LD D,$0A
l_F396:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F396
  JP l_F3A5
l_F3A5:
  LD HL,l_F3AD+$0010
  LD BC,$0B2B
  LD D,$0C
l_F3AD:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer25
  JP l_F3AD

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit24:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer25:
  LD HL,Layer25+$0003
  LD BC,$0064
  LD DE,Layer25+$0002
  LDDR
  LD HL,l_F3D3+$000B
  LD BC,$0B0A
  LD D,$08
l_F3D3:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F3D3
  JP l_F3E2
l_F3E2:
  LD HL,l_F3E2
  LD DE,l_F3D3+$000E
  LD BC,$0064
  LDDR
  LD BC,$0AD6
  LD HL,l_F412
  CALL LayerKeyed26

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed26:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F3FD:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F40F
  JP l_F412
l_F40F:
  JP l_F3FD
l_F412:
  LD DE,$0AC9
  LD HL,l_F418+$0007
l_F418:
  DEC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F418
  JP l_F423
l_F423:
  LD HL,l_F42B+$0010
  LD BC,$0AAD
  LD D,$06
l_F42B:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer27
  JP l_F42B

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit26:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer27:
  LD DE,Layer27+$0002
  LD HL,Layer27+$0003
  LD BC,$0064
  LDDR
  LD BC,$0A8C
  LD SP,l_FED6+$0010
l_F44F:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F44F
  JP l_F45F
l_F45F:
  LD HL,l_F45F
  LD DE,l_F44F+$000F
  LD BC,$0064
  LDDR
  LD BC,$0A59
  LD HL,l_F48F
  CALL LayerKeyed28

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed28:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F47A:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F48C
  JP l_F48F
l_F48C:
  JP l_F47A
l_F48F:
  LD HL,l_F48F
  LD BC,$0064
  LD DE,l_F48C+$0002
  LDDR
  LD HL,l_F4A0+$000A
  LD BC,$0A3E
l_F4A0:
  LD A,R
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F4A0
  JP l_F4AE
l_F4AE:
  LD DE,l_F4AE+$0002
  LD HL,l_F4AE+$0003
  LD BC,$0064
  LDDR
  LD BC,$0A1C
  LD SP,l_FED6+$0010
l_F4BF:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F4BF
  JP l_F4CF
l_F4CF:
  LD HL,l_F4CF
  LD DE,l_F4BF+$000F
  LD BC,$0064
  LDDR
  LD BC,$09E9
  LD HL,l_F4FF
  CALL LayerKeyed29

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed29:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F4EA:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F4FC
  JP l_F4FF
l_F4FC:
  JP l_F4EA
l_F4FF:
  LD HL,l_F507+$0010
  LD BC,$09D1
  LD D,$02
l_F507:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer30
  JP l_F507

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit29:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer30:
  LD HL,Layer30+$0004
  LD BC,$0032
  LD DE,Layer30+$0003
  LDDR
  LD HL,l_F52D+$000C
  LD BC,$09AF
  LD D,$00
l_F52D:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F52D
  JP l_F53D
l_F53D:
  LD HL,l_F53D
  LD DE,l_F52D+$000F
  LD BC,$0064
  LDDR
  LD BC,$097B
  LD HL,l_F56D
  CALL LayerKeyed31

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed31:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F558:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F56A
  JP l_F56D
l_F56A:
  JP l_F558
l_F56D:
  LD HL,l_F575+$0010
  LD BC,$0963
  LD D,$02
l_F575:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer32
  JP l_F575

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit31:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer32:
  LD DE,Layer32+$0002
  LD HL,Layer32+$0003
  LD BC,$0064
  LDDR
  LD BC,$0942
  LD SP,l_FED6+$0010
l_F599:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F599
  JP l_F5A9
l_F5A9:
  LD SP,l_F5A9+$000F
  LD HL,l_F5A9+$000C
  LD DE,l_F5A9+$000B
  LD BC,$0020
  LDDR
  JP PE,l_F5CD
  LD HL,l_F5C3+$0009
  LD DE,l_F5A9+$000E
  LD BC,$091C
l_F5C3:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_F5C3
l_F5CD:
  LD HL,l_F5CD+$0004
  LD BC,$0032
  LD DE,l_F5CD+$0003
  LDDR
  LD HL,l_F5E0+$000C
  LD BC,$08FC
  LD D,$06
l_F5E0:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F5E0
  JP l_F5F0
l_F5F0:
  LD HL,l_F5F0+$0003
  LD BC,$0064
  LD DE,l_F5F0+$0002
  LDDR
  LD HL,l_F603+$000B
  LD BC,$08DA
  LD D,$00
l_F603:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F603
  JP l_F612
l_F612:
  LD SP,l_F612+$000F
  LD HL,l_F612+$000C
  LD DE,l_F612+$000B
  LD BC,$0020
  LDDR
  JP PE,l_F636
  LD HL,l_F62C+$0009
  LD DE,l_F612+$000E
  LD BC,$08B3
l_F62C:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_F62C
l_F636:
  LD HL,l_F636+$0004
  LD BC,$0032
  LD DE,l_F636+$0003
  LDDR
  LD HL,l_F649+$000C
  LD BC,$0893
  LD D,$08
l_F649:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F649
  JP l_F659
l_F659:
  LD HL,l_F659+$0003
  LD BC,$0064
  LD DE,l_F659+$0002
  LDDR
  LD HL,l_F66C+$000B
  LD BC,$0871
  LD D,$02
l_F66C:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F66C
  JP l_F67B
l_F67B:
  LD HL,l_F67B
  LD BC,$0064
  LD DE,l_F66C+$000E
  LDDR
  LD HL,l_F68C+$000A
  LD BC,$0852
l_F68C:
  LD A,R
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F68C
  JP l_F69A
l_F69A:
  LD DE,l_F69A+$0002
  LD HL,l_F69A+$0003
  LD BC,$0064
  LDDR
  LD BC,$0830
  LD SP,l_FED6+$0010
l_F6AB:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F6AB
  JP l_F6BB
l_F6BB:
  LD HL,l_F6BB
  LD DE,l_F6AB+$000F
  LD BC,$0064
  LDDR
  LD BC,$07FD
  LD HL,l_F6EB
  CALL LayerKeyed33

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed33:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F6D6:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F6E8
  JP l_F6EB
l_F6E8:
  JP l_F6D6
l_F6EB:
  LD HL,l_F6EB
  LD BC,$0064
  LD DE,l_F6E8+$0002
  LDDR
  LD HL,l_F6FC+$000A
  LD BC,$07E2
l_F6FC:
  LD A,R
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F6FC
  JP l_F70A
l_F70A:
  LD DE,$07D1
  LD HL,l_F710+$0007
l_F710:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F710
  JP l_F71B
l_F71B:
  LD HL,l_F71B
  LD BC,$0064
  LD DE,l_F710+$000A
  LDDR
  LD HL,l_F72C+$000A
  LD BC,$07B2
l_F72C:
  LD A,R
  XOR (HL)
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F72C
  JP l_F73A
l_F73A:
  LD HL,l_F742+$0010
  LD BC,$0796
  LD D,$04
l_F742:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer34
  JP l_F742

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit33:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer34:
  LD DE,$0786
  LD HL,l_F75B+$0007
l_F75B:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F75B
  JP l_F766
l_F766:
  LD HL,l_F766+$0003
  LD BC,$0064
  LD DE,l_F766+$0002
  LDDR
  LD HL,l_F779+$000B
  LD BC,$0764
  LD D,$04
l_F779:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F779
  JP l_F788
l_F788:
  LD DE,$0753
  LD HL,l_F78E+$0007
l_F78E:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F78E
  JP l_F799
l_F799:
  LD HL,l_F799+$0003
  LD BC,$0064
  LD DE,l_F799+$0002
  LDDR
  LD HL,l_F7AC+$000B
  LD BC,$0731
  LD D,$01
l_F7AC:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F7AC
  JP l_F7BB
l_F7BB:
  LD HL,l_F7BB
  LD DE,l_F7AC+$000E
  LD BC,$0064
  LDDR
  LD BC,$06FD
  LD HL,l_F7EB
  CALL LayerKeyed35

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed35:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F7D6:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F7E8
  JP l_F7EB
l_F7E8:
  JP l_F7D6
l_F7EB:
  LD DE,l_F7EB+$0002
  LD HL,l_F7EB+$0003
  LD BC,$0064
  LDDR
  LD BC,$06DF
  LD SP,l_FED6+$0010
l_F7FC:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F7FC
  JP l_F80C
l_F80C:
  LD HL,l_F80C
  LD DE,l_F7FC+$000F
  LD BC,$0064
  LDDR
  LD BC,$06AC
  LD HL,l_F83C
  CALL LayerKeyed36

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed36:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F827:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F839
  JP l_F83C
l_F839:
  JP l_F827
l_F83C:
  LD DE,$069F
  LD HL,l_F842+$0007
l_F842:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F842
  JP l_F84D
l_F84D:
  LD SP,l_F84D+$000F
  LD HL,l_F84D+$000C
  LD DE,l_F84D+$000B
  LD BC,$0020
  LDDR
  JP PE,l_F871
  LD HL,l_F867+$0009
  LD DE,l_F84D+$000E
  LD BC,$0678
l_F867:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_F867
l_F871:
  LD HL,l_F871
  LD DE,l_F867+$0009
  LD BC,$0064
  LDDR
  LD BC,$0647
  LD HL,l_F8A1
  CALL LayerKeyed37

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed37:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F88C:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F89E
  JP l_F8A1
l_F89E:
  JP l_F88C
l_F8A1:
  LD DE,$063A
  LD HL,l_F8A7+$0007
l_F8A7:
  DEC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F8A7
  JP l_F8B2
l_F8B2:
  LD HL,l_F8BA+$0010
  LD BC,$061E
  LD D,$00
l_F8BA:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer38
  JP l_F8BA

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit37:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer38:
  LD DE,Layer38+$0002
  LD HL,Layer38+$0003
  LD BC,$0064
  LDDR
  LD BC,$05FD
  LD SP,l_FED6+$0010
l_F8DE:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F8DE
  JP l_F8EE
l_F8EE:
  LD SP,l_F8EE+$000F
  LD HL,l_F8EE+$000C
  LD DE,l_F8EE+$000B
  LD BC,$0020
  LDDR
  JP PE,l_F912
  LD HL,l_F908+$0009
  LD DE,l_F8EE+$000E
  LD BC,$05D7
l_F908:
  LD A,R
  XOR (HL)
  LD (HL),A
  LDI
  DEC DE
  RET PO
  JR l_F908
l_F912:
  LD HL,l_F912+$0003
  LD BC,$0064
  LD DE,l_F912+$0002
  LDDR
  LD HL,l_F925+$000B
  LD BC,$05B8
  LD D,$08
l_F925:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_F925
  JP l_F934
l_F934:
  LD HL,l_F93C+$0010
  LD BC,$059C
  LD D,$08
l_F93C:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer39
  JP l_F93C

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit38:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer39:
  LD DE,Layer39+$0002
  LD HL,Layer39+$0003
  LD BC,$0064
  LDDR
  LD BC,$057B
  LD SP,l_FED6+$0010
l_F960:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F960
  JP l_F970
l_F970:
  LD DE,$056B
  LD HL,l_F976+$0007
l_F976:
  DEC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_F976
  JP l_F981
l_F981:
  LD HL,l_F989+$0010
  LD BC,$054F
  LD D,$04
l_F989:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer40
  JP l_F989

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit39:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer40:
  LD HL,Layer40
  LD DE,LayerExit39+$0001
  LD BC,$0064
  LDDR
  LD BC,$051C
  LD HL,l_F9CC
  CALL LayerKeyed41

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed41:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_F9B7:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_F9C9
  JP l_F9CC
l_F9C9:
  JP l_F9B7
l_F9CC:
  LD DE,l_F9CC+$0002
  LD HL,l_F9CC+$0003
  LD BC,$0064
  LDDR
  LD BC,$04FE
  LD SP,l_FED6+$0010
l_F9DD:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_F9DD
  JP l_F9ED
l_F9ED:
  LD HL,l_F9ED
  LD DE,l_F9DD+$000F
  LD BC,$0064
  LDDR
  LD BC,$04CB
  LD HL,l_FA1D
  CALL LayerKeyed42

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed42:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_FA08:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_FA1A
  JP l_FA1D
l_FA1A:
  JP l_FA08
l_FA1D:
  LD HL,l_FA25+$0010
  LD BC,$04B3
  LD D,$08
l_FA25:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer43
  JP l_FA25

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit42:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer43:
  LD HL,Layer43+$0004
  LD BC,$0032
  LD DE,Layer43+$0003
  LDDR
  LD HL,l_FA4B+$000C
  LD BC,$0491
  LD D,$00
l_FA4B:
  LD A,R
  XOR D
  ADD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_FA4B
  JP l_FA5B
l_FA5B:
  LD HL,l_FA5B+$0003
  LD BC,$0064
  LD DE,l_FA5B+$0002
  LDDR
  LD HL,l_FA6E+$000B
  LD BC,$046F
  LD D,$04
l_FA6E:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_FA6E
  JP l_FA7D
l_FA7D:
  LD DE,$045E
  LD HL,l_FA83+$0007
l_FA83:
  DEC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_FA83
  JP l_FA8E
l_FA8E:
  LD DE,$044D
  LD HL,l_FA94+$0007
l_FA94:
  INC (HL)
  DEC DE
  LD A,D
  INC HL
  OR E
  JP NZ,l_FA94
  JP l_FA9F
l_FA9F:
  LD DE,l_FA9F+$0002
  LD HL,l_FA9F+$0003
  LD BC,$0064
  LDDR
  LD BC,$042B
  LD SP,l_FED6+$0010
l_FAB0:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_FAB0
  JP l_FAC0
l_FAC0:
  LD HL,l_FAC0
  LD DE,l_FAB0+$000F
  LD BC,$0064
  LDDR
  LD BC,$03F8
  LD HL,l_FAF0
  CALL LayerKeyed44

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed44:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_FADB:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_FAED
  JP l_FAF0
l_FAED:
  JP l_FADB
l_FAF0:
  LD HL,l_FAF0+$0003
  LD BC,$0064
  LD DE,l_FAF0+$0002
  LDDR
  LD HL,l_FB03+$000B
  LD BC,$03DA
  LD D,$07
l_FB03:
  LD A,R
  ADD A,(HL)
  SUB D
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,l_FB03
  JP l_FB12
l_FB12:
  LD HL,l_FB1A+$0010
  LD BC,$03BE
  LD D,$02
l_FB1A:
  LD A,R
  XOR (HL)
  XOR D
  LD (HL),A
  LD D,A
  INC HL
  DEC BC
  INC D
  LD A,C
  OR B
  JP Z,Layer45
  JP l_FB1A

; $DD,$E9: the JP (IX) the keyed layer leaves through, as the next layer leaves
; it (deciphered after it ran)
LayerExit44:
  DEFB $DD,$E9

; The next layers: wipe the 100 bytes behind, decipher the rest with R and a
; running byte
;
; Witness: L1 1 (c1).
Layer45:
  LD DE,Layer45+$0002
  LD HL,Layer45+$0003
  LD BC,$0064
  LDDR
  LD BC,$039D
  LD SP,l_FED6+$0010
l_FB3E:
  POP DE
  LD A,R
  XOR D
  LD D,A
  PUSH DE
  DEC BC
  LD A,C
  DEC SP
  OR B
  JP NZ,l_FB3E
  JP l_FB4E
l_FB4E:
  LD HL,l_FB4E
  LD DE,l_FB3E+$000F
  LD BC,$0064
  LDDR
  LD BC,$036A
  LD HL,SL7Start
  CALL LayerKeyed46

; A keyed layer: POP IX (its return address) + 28, then each byte = ((R XOR
; IXH) - byte) XOR IXL
;
; Witness: L1 1 (c1).
LayerKeyed46:
  POP IX
  LD DE,$001C
  ADD IX,DE
l_FB69:
  LD A,R
  XOR IXH
  SUB (HL)
  XOR IXL
  LD (HL),A
  DEC BC
  LD A,C
  INC HL
  OR B
  JP NZ,l_FB7B
  JP SL7Start
l_FB7B:
  JP l_FB69
SL7Start:
  NOP                     ; the reader: the ROM check ($0000 = $F3), the ports
                          ; $1F, $7B, $BB, $7F, the RAM cleared
  CCF
  LD A,($0000)
  CP $F3
l_FB85:
  JP NZ,$0000
  IN A,($9F)
  LD A,($0000)
  CP $F3
  JR NZ,l_FB85
  XOR A
  LD L,A
  LD H,L
  OUT ($1F),A
  INC A
  LD E,$01
  OUT ($7B),A
  LD D,L
  OUT ($BB),A
  LD (HL),L
  LD A,$43
  LD BC,$3FFF
  LDIR
  DEC HL
  OUT ($7F),A
  LD BC,$3FFF
  DEC DE
  LD A,C
  LDDR
  LD HL,$4000
  LD DE,$4001
  LD BC,$1BFF
  LD (HL),L
  LDIR
  LD BC,$9F0E
  LD HL,l_FB85+$0040
  LD DE,l_FB85+$003F
  NOP
  LDDR
  JP SL7Main

; Zero memory upward from $FBD7 for ever: the end of a failed check
;
; Used by the routines at SL7LoadBlock and SL7BlockEnd.
SL7WipeTrap:
  LD IY,l_FB85+$0041
l_FBCF:
  LD (IY+$11),$00
  INC IY
  JR l_FBCF

; The per-bit hook: while $82FF is set, LDI 12 bytes from $8000 to the
; attributes a step (the screen revealed as it loads)
;
; Witness: L1 57161 (c1).
SL7Reveal:
  EXX
  EX AF,AF'
  LD A,($82FF)
  CP $00
  LD B,$0C
  JR Z,l_FBF9
  LD HL,l_FBF9+$0003
  LD (l_FD95+$0005),HL
  LD HL,$8000
  LD DE,$5800
  LD A,$41
  LD B,$09
l_FBF2:
  DJNZ l_FBF2
  EX AF,AF'
  EXX
  JP l_FCDE
l_FBF9:
  NOP
  JR l_FBF2
  EXX
  EX AF,AF'
  DEC A
  JR Z,l_FC1F
  EX AF,AF'
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  NOP
  EXX
  JP l_FCDE
l_FC1F:
  LD A,$01
  EX AF,AF'
  LD HL,l_FC37+$0006
  LD (l_FD95+$0005),HL
  XOR A
  LD (l_FCDF+$0010),A
  LD A,$08
  LD (l_FCDF+$0012),A
  LD B,$08
  LD B,$08
  LD B,$08
l_FC37:
  DJNZ l_FC37
  EXX
  JP l_FCDE
  EXX
  EX AF,AF'
  CP $98
  JR C,l_FCA0
  DEC C
  JR Z,l_FC54
  EX AF,AF'
  LD B,$04
l_FC49:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ l_FC49
  NOP
  LD B,$01
  JR l_FC8D
l_FC54:
  DEC A
  CP $98
  JR C,l_FC93
  LD C,$03
  LD HL,SL7Bytes+$0003
  LD DE,$50E5
  LD B,$08
  JR Z,l_FC80
  DEC HL
  DEC E
  DEC E
  NOP
  NOP
  LD B,$05
  CP $99
  JR Z,l_FC80
  DEC HL
  DEC E
  NOP
  LD B,$03
  CP $9A
  JR Z,l_FC80
  DEC HL
  DEC E
  DEC E
  NOP
  NOP
  LD B,$01
l_FC80:
  DJNZ l_FC80
  LD L,(HL)
  LD H,$FF
  EX AF,AF'
  EXX
  JP l_FCDE
l_FC8A:
  LD B,$0D
l_FC8C:
  EX AF,AF'
l_FC8D:
  DJNZ l_FC8D
  EXX
  JP l_FCDE
l_FC93:
  LD B,$0B
  JR l_FC8C
l_FC97:
  LD (HL),A
l_FC98:
  DJNZ l_FC98
  JR l_FCCA
l_FC9C:
  NOP
  NOP
  JR l_FCCA
l_FCA0:
  DEC A
  JR NZ,l_FC8A
  LD A,$9C
  EX AF,AF'
  LD HL,SL7Bytes+$0003
  LD DE,$78F8
  LD A,E
  ADD A,(HL)
  CP D
  LD B,$07
  JR NZ,l_FC97
  LD (HL),$C8
  DEC HL
  LD A,E
  ADD A,(HL)
  CP D
  LD B,$04
  JR NZ,l_FC98
  LD (HL),$C8
  DEC HL
  LD A,E
  ADD A,(HL)
  CP D
  JR NZ,l_FC9C
  LD (HL),$A8
  DEC HL
  LD A,E
  ADD A,(HL)
l_FCCA:
  LD (HL),A
  LD C,$01
  EXX
  JP l_FCDE

; four bytes $90, $98, $80, $90 between the routines
SL7Bytes:
  DEFB $90,$98,$80,$90

; Wait for two edges
;
; Witness: L1 282 (c1).
SL7Edge2:
  CALL SL7Edge1
  RET NC

; Wait for one edge after the standard delay
;
; Witness: L1 3292 (c1).
SL7Edge1:
  LD A,$16

; Delay A, then wait for an edge on EAR counting B; carry when found, the
; border striped
;
; Witness: L1 2521777 (c1).
SL7EdgeDelay:
  DEC A
  JR NZ,SL7EdgeDelay
; This entry point is used by the routine at SL7Reveal.
l_FCDE:
  AND A
l_FCDF:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  XOR C
  AND $20
  JR Z,l_FCDF
  LD A,C
  CPL
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET

; Load DE bytes to IX: the pilot, the sync and the 7-pulse pattern of
; SL7Pattern, then the bytes through the store hook
;
; Witness: L1 2 (c1).
SL7LoadBlock:
  DI
  LD A,$02
  LD (l_FCDF+$0010),A
  OR $08
  OUT ($FE),A
  LD HL,SL7BlockEnd+$0001
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  LD C,A
  PUSH DE
l_FD0B:
  LD E,$20
l_FD0D:
  LD B,$9C
  CALL SL7Edge2
  JR NC,l_FD0B
  LD A,$C2
  CP B
  JR NC,l_FD0B
  DEC E
  JR NZ,l_FD0D
l_FD1C:
  LD B,$C9
  CALL SL7Edge1
  JR NC,l_FD0B
  LD A,B
  CP $D4
  JR NC,l_FD1C
  CALL SL7Edge1
  JR NC,l_FD0B
  LD E,$07
  LD HL,SL7Pattern+$0001
l_FD32:
  LD B,(HL)
  INC HL
  CALL SL7Edge2
  JR NC,l_FD0B
  LD A,(HL)
  INC HL
  CP B
  JR NC,l_FD0B
  DEC E
  JR NZ,l_FD32
  LD A,$01
  LD (l_FCDF+$0010),A
  LD B,$9E
  POP DE
  LD L,$04
  LD A,$08
  JR l_FD51
l_FD4F:
  LD A,$09
l_FD51:
  CALL SL7EdgeDelay
  RET NC
  NOP
  NOP
  LD A,$0E
  CALL SL7EdgeDelay
  RET NC
  LD A,$13
  LD A,$BC
  CP B
  RL L
  LD B,$9E
  JP NC,l_FD4F
  LD A,$3A
  CP L
  JP NZ,SL7WipeTrap
  LD H,$86
  LD H,$00
  LD B,$B2
  LD L,$01
  LD IY,$FF49
  LD A,$04
  JR l_FD95
l_FD7F:
  LD A,$C1
  XOR L
  ADD A,$11
  LD (IX+$00),A
  INC IX
  DEC DE
  LD B,$B2
  LD L,$01
  NOP
  LD A,$02
  JR l_FD95
l_FD93:
  LD A,$09
; This entry point is used by the routine at SL7Blocks.
l_FD95:
  CALL SL7EdgeDelay
  RET NC
  CALL SL7Reveal
  RET NC
  LD A,$13
  LD A,$D0
  CP B
  RL L
  LD B,$B2
  JP NC,l_FD93
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,l_FD7F
  JP SL7BlockEnd

; The byte store stage 2 points the reader at ($FDB1 = $FDB3): LD A,$C1 / XOR L
; / ADD A,$11 / LD (IX+0),A ...; bytes in this view (known only from the code)
SL7StoreHook:
  DEFB $3E,$C1,$AD,$C6,$11,$DD,$77,$00
  DEFB $DD,$23,$1B,$2E,$02,$3E,$04,$06
  DEFB $B3,$CD,$2A,$FE

; Walk the block table at IY: 5-byte records (address, length, the $7FFD bank
; or 0), each block loaded with SL7LoadBlock's bit loop
;
; Witness: L1 7 (c1).
SL7Blocks:
  RET NC
  LD A,(IY+$04)
  OR A
  JR Z,l_FE24
  LD L,C
  LD BC,$7FFD
  OUT (C),A
  LD C,(IY+$00)
  LD B,(IY+$01)
  LD IX,$0000
  ADD IX,BC
  LD C,L
  LD A,$01
l_FDE3:
  LD L,$02
  LD B,$B3
  CALL SL7ReadBit
  RET NC
  LD A,$7F
  CP L
  JR Z,l_FDF3
  LD (SL7Pattern),A
l_FDF3:
  LD E,(IY+$02)
  LD D,(IY+$03)
  LD L,C
  LD BC,$0005
  ADD IY,BC
  LD C,L
  LD L,$02
  LD A,$03
  LD B,$B3
  CALL SL7ReadBit
  RET NC
  LD A,E
  OR D
  LD B,$B2
  LD L,$01
  LD A,$06
  JP NZ,l_FD95
  LD DE,SL7BlockEnd
  LD (l_FD95+$001C),DE
  LD DE,$000E
  LD A,$02
  JP l_FD95
l_FE24:
  LD A,$06
  JR l_FDE3
; This entry point is used by the routine at SL7ReadBit.
l_FE28:
  LD A,$0C

; Read one bit into L (the edge time against $DB)
;
; Witness: L1 147 (c1).
SL7ReadBit:
  CALL SL7EdgeDelay
  NOP
  NOP
  LD A,$0E
  CALL SL7EdgeDelay
  RET NC
  LD A,$DB
  CP B
  RL L
  LD B,$B3
  JP NC,l_FE28
  RET

; Load the next stage, then sample the EAR line 255 times into $9000 and check
; it unless $006D holds $28
;
; Witness: L1 1 (c1).
SL7LoadStage2:
  CALL SL7LoadBlock
  LD HL,$9000
  LD B,$FF
l_FE48:
  PUSH BC
  CALL SL7CountEdges
  LD (HL),E
  INC HL
  POP BC
  DJNZ l_FE48
  LD A,($006D)
  CP $28
  RET Z
  CALL SL7CheckSamples
  RET

; Count the EAR changes in 255 loops into E
;
; Witness: L1 255 (c1).
SL7CountEdges:
  LD E,$00
  LD C,E
  LD B,$FF
l_FE60:
  LD A,$7F
  IN A,($FE)
  AND $40
  XOR C
  JR Z,l_FE72
  INC E
  LD A,C
  CPL
  AND $40
  LD C,A
l_FE6F:
  DJNZ l_FE60
  RET
l_FE72:
  NOP
  NOP
  JP l_FE6F

; Sum two runs of 50 samples; a bad pair sets SL7Pattern's flag byte
;
; Witness: L1 1 (c1).
SL7CheckSamples:
  LD HL,$0000
  LD DE,$9032
  LD B,$32
l_FE7F:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ l_FE7F
  PUSH HL
  LD HL,$0000
  LD DE,$90CD
  LD B,$32
l_FE92:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ l_FE92
  POP BC
  LD A,H
  CP $0D
  JR NC,l_FEAF
  AND A
  SBC HL,BC
  RET C
  LD BC,$0032
  AND A
  SBC HL,BC
  RET C
  LD A,$01
l_FEAF:
  LD (SL7Pattern),A
  RET

; The flag byte (non-zero: a failed check, the reader wipes memory) and the 7
; sync pulse limits (pairs)
SL7Pattern:
  DEFB $00,$E9,$EA,$D2,$E2,$B6,$E0,$B6
  DEFB $E0,$B6,$E0,$D2,$E2,$EC,$ED

; After a block: border black; a bad block wipes memory (SL7WipeTrap)
;
; Witness: L1 1 (c1).
SL7BlockEnd:
  POP DE
  XOR A
  OUT ($FE),A
  LD A,H
  CP $01
  RET C
  CALL SL7WipeTrap
; This entry point is used by the routine at LayerKeyed46.
SL7Main:
  LD SP,$FFFF             ; SP = $FFFF, the screen cleared, the second stage
                          ; (232 bytes) loaded to $FEE8
  LD HL,$4000
  LD BC,$001B
l_FED6:
  LD (HL),$00
  INC HL
  DJNZ l_FED6
  DEC C
  JR NZ,l_FED6
  LD IX,$FEE8
  LD DE,$00E8
  CALL SL7LoadStage2
