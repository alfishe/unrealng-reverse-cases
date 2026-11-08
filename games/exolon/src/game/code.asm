  ORG $6D60

; l_6D60
;
; Used by the routine at l_A02A.
l_6D60:
  DI
  LD SP,$0000
  LD A,($386E)
  SUB $FF
  LD (data_6E16),A
  XOR A
  OUT ($FE),A
  LD (data_9CE2),A
  LD (data_9ED6+$0002),A
  LD (data_8523),A
  LD HL,$0000
  LD (data_9ED6),HL
  INC A
  LD (data_7D67),A
  CALL sub_7BEF
  CALL sub_7B99
  LD HL,data_AD82+$0008
  LD DE,data_AD82+$0009
  LD (HL),$30
  LD BC,$0005
  LDIR
  LD A,$09
  LD (data_8E7A),A
  LD A,(data_718D+$0063)
  OR A
  JP NZ,data_7046+$00FF

; l_6DA1
;
; Used by the routines at l_701E and l_7149.
l_6DA1:
  CALL sub_B04B
  CALL sub_8DF5
  CALL sub_8E03
  LD BC,$001F
  LDIR
  LD HL,data_6E16+$0001
  CALL sub_AF2B
  CALL sub_6F90
  CALL sub_B6EC
  LD A,(data_7D67)
  OR A
  JR Z,l_6DD1
  XOR A
  LD (data_7D67),A
  LD A,(data_6E16)
  OR A
  JR NZ,l_6DD1
  LD HL,data_7D67+$003C
  CALL sub_7D17
l_6DD1:
  CALL sub_8E11
  CALL sub_B0F3
  CALL sub_6F83
  LD BC,$09C4
l_6DDD:
  CALL sub_6EA9
  CALL sub_ACD1
  CP $31
  JR C,l_6E0D
  CP $36
  JR NC,l_6E0D
  CP $31
  JP Z,l_758A
  CP $32
  JP Z,l_6FAB
  SUB $33
  LD E,A
  LD A,(data_7B92+$0005)
  CP E
  JR Z,l_6E0D
  LD A,E
  LD (data_7B92+$0005),A
  LD HL,data_6E16+$0001
  PUSH BC
  CALL sub_AF2B
  CALL sub_6F90
  POP BC
l_6E0D:
  DEC BC
  LD A,B
  OR C
  JP Z,l_7149
  JP l_6DDD

; data_6E16
data_6E16:
  DEFB $00,$E8,$01,$DF,$00,$08,$E3,$FF
  DEFB $70,$E6,$E0,$D7,$DF,$07,$07,$E0
  DEFB $44,$42,$59,$20,$20,$52,$41,$46
  DEFB $46,$41,$45,$4C,$45,$20,$43,$45
  DEFB $43,$43,$4F,$DF,$0B,$09,$DA,$31
  DEFB $DC,$20,$53,$54,$41,$52,$54,$20
  DEFB $47,$41,$4D,$45,$7A,$F4,$DA,$32
  DEFB $DC,$20,$44,$45,$46,$49,$4E,$45
  DEFB $20,$4B,$45,$59,$53,$7A,$F3,$DA
  DEFB $33,$DC,$20,$4B,$45,$59,$42,$4F
  DEFB $41,$52,$44,$7A,$F6,$DA,$34,$DC
  DEFB $20,$49,$4E,$54,$45,$52,$46,$41
  DEFB $43,$45,$20,$32,$7A,$F3,$DA,$35
  DEFB $DC,$20,$4B,$45,$4D,$50,$53,$54
  DEFB $4F,$4E,$DF,$17,$02,$D9,$45,$58
  DEFB $4F,$4C,$4F,$4E,$20,$43,$4F,$50
  DEFB $59,$52,$49,$47,$48,$54,$20,$31
  DEFB $39,$38,$37,$20,$48,$45,$57,$53
  DEFB $4F,$4E,$FF

; sub_6EA9
;
; Used by the routine at l_6DA1.
sub_6EA9:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IY
  LD IY,data_B101+$0080
  LD HL,data_6F4D+$0011
l_6EB6:
  LD E,(HL)
  BIT 7,E
  JR Z,l_6EC2
  POP IY
  POP HL
  POP DE
  POP BC
  POP AF
  RET
l_6EC2:
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR NZ,l_6EFE
  CALL sub_AD36
  AND $1E
  LD E,A
  CALL sub_AD36
  AND $1F
  CP $16
  JR NC,l_6F14
  LD D,A
  CALL sub_8097
  LD BC,$6100
  ADD HL,BC
  LD A,(HL)
  INC HL
  OR (HL)
  LD BC,$0020
  ADD HL,BC
  OR (HL)
  DEC HL
  OR (HL)
  JR NZ,l_6F14
  POP HL
  PUSH HL
  LD A,E
  ADD A,A
  ADD A,A
  LD (HL),A
  INC HL
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  LD (HL),A
  INC HL
  LD (HL),$10
  JR l_6F14
l_6EFE:
  DEC (HL)
  LD L,A
  LD H,$00
  LD BC,data_6F4D
  ADD HL,BC
  LD A,(HL)
  LD B,D
  LD C,E
  PUSH IY
  POP HL
  CALL sub_6F1F
  LD C,$47
  CALL sub_7C8F
l_6F14:
  POP HL
  INC HL
  INC HL
  INC HL
  LD DE,$0030
  ADD IY,DE
  JR l_6EB6

; sub_6F1F
;
; Used by the routine at sub_6EA9.
sub_6F1F:
  CALL sub_795C
  PUSH AF
  LD A,(data_6E16)
  OR A
  JR Z,l_6F4B
  LD A,(data_6F4D)
  INC A
  LD (data_6F4D),A
  CP $04
  JR NZ,l_6F4B
  XOR A
  LD (data_6F4D),A
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  CALL sub_B767
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
l_6F4B:
  POP AF
  RET

; data_6F4D
data_6F4D:
  DEFB $00,$00,$0C,$0C,$0D,$0D,$0E,$0E
  DEFB $0F,$0F,$0F,$0E,$0E,$0D,$0E,$0C
  DEFB $0C,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$FF

; sub_6F83
;
; Used by the routines at l_6DA1 and l_6FAB.
sub_6F83:
  LD HL,data_6F4D+$0011
  LD DE,data_6F4D+$0012
  LD BC,$0023
  LD (HL),B
  LDIR
  RET

; sub_6F90
;
; Used by the routine at l_6DA1.
sub_6F90:
  LD A,(data_7B92+$0005)
  ADD A,A
  ADD A,$0F
  LD D,A
  LD E,$0B
  CALL sub_8097
  LD DE,$5800
  ADD HL,DE
  LD (HL),$47
  LD E,L
  LD D,H
  INC E
  LD BC,$000D
  LDIR
  RET

; l_6FAB
;
; Used by the routine at l_6DA1.
l_6FAB:
  CALL sub_B753
  CALL sub_B04B
  CALL sub_8DF5
  CALL sub_8E03
  LD BC,$001F
  LDIR
  XOR A
  LD (data_7B92+$0005),A
  LD HL,data_7046+$004F
  CALL sub_AF2B
  CALL sub_8E11
  CALL sub_B0F3
  CALL sub_6F83
  LD IX,data_7AD9+$0017
  LD IY,data_7046+$0045
  LD DE,$090F
  LD B,$05
; This entry point is used by the routine at l_701E.
l_6FDC:
  PUSH BC
  LD A,$3F
  LD C,$44
  CALL sub_ADE1
  PUSH DE
  CALL sub_AD18
l_6FE8:
  CALL sub_ACD1
  OR A
  JR Z,l_6FE8
  LD (IX+$02),D
  LD (IX+$06),E
  LD DE,$000A
  ADD IX,DE
  LD (IY+$00),A
  INC IY
  POP DE
  LD HL,data_7046+$0015
  CP $20
  JR NZ,l_7009
  LD HL,data_7046+$0019
l_7009:
  CP $0D
  JR NZ,l_7010
  LD HL,data_7046+$0021
l_7010:
  CP $01
  JR NZ,l_7017

; data_7014
data_7014:
  DEFB $21,$6F,$70

; l_7017
;
; Used by the routine at l_6FAB.
l_7017:
  CP $02
  JR NZ,l_701E

; data_701B
data_701B:
  DEFB $21,$7C,$70

; l_701E
;
; Used by the routine at l_7017.
l_701E:
  LD (data_7046+$0015),A
  LD C,$43
  CALL sub_AF2B
  PUSH DE
  LD B,$C8
  CALL sub_7C26
  POP DE
  POP BC
  DJNZ l_6FDC
  LD BC,$C350
  CALL sub_B0B7
  CALL sub_B0B7
  LD HL,data_7046+$0045
  LD DE,data_7046+$004A
  LD B,$05
  LD A,(DE)
  CP (HL)
  JP NZ,l_6DA1

; data_7046
data_7046:
  DEFB $23,$13,$10,$F7,$3A,$1D,$9D,$EE
  DEFB $3D,$32,$1D,$9D,$21,$68,$7D,$CC
  DEFB $17,$7D,$C3,$A1,$6D,$3F,$7A,$FF
  DEFB $FF,$53,$50,$41,$43,$45,$7A,$FB
  DEFB $FF,$45,$4E,$54,$45,$52,$7A,$FB
  DEFB $FF,$43,$41,$50,$53,$20,$53,$48
  DEFB $49,$46,$54,$7A,$F6,$FF,$53,$59
  DEFB $4D,$42,$4F,$4C,$20,$53,$48,$49
  DEFB $46,$54,$7A,$F4,$FF,$00,$00,$00
  DEFB $00,$00,$5A,$4F,$52,$42,$41,$DF
  DEFB $00,$08,$E3,$FF,$70,$E0,$46,$DF
  DEFB $06,$07,$E6,$E0,$D7,$53,$45,$4C
  DEFB $45,$43,$54,$20,$4B,$45,$59,$20
  DEFB $46,$4F,$52,$2E,$2E,$2E,$2E,$DE
  DEFB $7B,$EE,$4C,$45,$46,$54,$7A,$FC
  DEFB $52,$49,$47,$48,$54,$7A,$FB,$4A
  DEFB $55,$4D,$50,$7A,$FC,$44,$55,$43
  DEFB $4B,$7A,$FC,$46,$49,$52,$45,$70
  DEFB $04,$E5,$09,$20,$DF,$17,$02,$D9
  DEFB $45,$58,$4F,$4C,$4F,$4E,$20,$43
  DEFB $4F,$50,$59,$52,$49,$47,$48,$54
  DEFB $20,$31,$39,$38,$37,$20,$48,$45
  DEFB $57,$53,$4F,$4E,$FF,$E6,$E0,$D7
  DEFB $FF,$E6,$B0,$E6,$E0,$47,$DE,$00
  DEFB $01,$02,$03,$04,$05,$06,$07,$A7
  DEFB $DD,$08,$09,$0A,$0B,$0C,$0D,$0E
  DEFB $0F,$A7,$D5,$10,$11,$12,$13,$14
  DEFB $15,$16,$17,$76,$00,$DE,$18,$19
  DEFB $1A,$1B,$1C,$1D,$1E,$1F,$A7,$DD
  DEFB $20,$21,$22,$23,$24,$25,$26,$27
  DEFB $A7,$D5,$28,$29,$2A,$2B,$2C,$2D
  DEFB $2E,$2F,$79,$F2,$30,$31,$FF,$AF
  DEFB $32,$F0,$71

; l_7149
;
; Used by the routine at l_6DA1.
l_7149:
  LD C,$44
  CALL sub_B04D
  LD HL,data_718D
  CALL sub_AF2B
  LD HL,data_718D+$0064
  LD (data_7588),HL
  LD BC,$03C0
  LD HL,data_C7F4+$0FEC
  LD (sub_ADE1+$000E),HL
l_7163:
  PUSH BC
  NOP
  NOP
  NOP
  LD A,C
  AND $0F
  OR A
  LD BC,$0400
  CALL NZ,sub_B0B7
  CALL Z,sub_7568
  CALL sub_7522
  POP BC
  DEC BC
  LD A,B
  OR C
  JP Z,l_6DA1
  CALL sub_ACD1
  OR A
  JP Z,l_7163
  CP $31
  JP Z,l_758A
  JP l_6DA1

; data_718D
data_718D:
  DEFB $DF,$00,$08,$E3,$FF,$70,$E0,$43
  DEFB $E6,$E0,$D7,$DF,$04,$10,$E1,$13
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $A7,$E2,$DF,$00,$00,$E3,$07,$8A
  DEFB $DF,$01,$05,$E3,$71,$86,$DF,$05
  DEFB $03,$E3,$07,$8A,$DF,$0A,$00,$E3
  DEFB $4F,$86,$DF,$10,$04,$E3,$71,$86
  DEFB $DF,$13,$01,$E3,$9D,$8A,$DF,$00
  DEFB $1A,$E3,$4F,$86,$DF,$05,$1A,$E3
  DEFB $75,$8A,$DF,$09,$1C,$E3,$85,$8A
  DEFB $DF,$0E,$1A,$E3,$9D,$8A,$DF,$12
  DEFB $1E,$E3,$71,$86,$DF,$15,$1A,$E3
  DEFB $07,$8A,$FF,$00,$52,$41,$46,$46
  DEFB $41,$45,$4C,$45,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$53,$55,$52,$59
  DEFB $41,$4E,$49,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$53,$43,$52,$41
  DEFB $47,$47,$59,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$53,$41,$42,$41
  DEFB $54,$54,$41,$21,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$50,$41,$44,$44
  DEFB $59,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4C,$4F,$46,$54
  DEFB $59,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4A,$49,$4D,$42
  DEFB $4F,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4C,$45,$4F,$20
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$47,$4C,$45,$4E
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4D,$4F,$52,$41
  DEFB $4E,$47,$45,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$50,$55,$50,$50
  DEFB $59,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4F,$4E,$49,$4F
  DEFB $4E,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$52,$49,$50,$20
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$46,$49,$47,$41
  DEFB $52,$4F,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$49,$4E,$4B,$20
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$50,$45,$4E,$20
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$44,$55,$4D,$42
  DEFB $4F,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4D,$45,$50,$48
  DEFB $49,$53,$54,$4F,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$51,$55,$45,$45
  DEFB $4E,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$55,$4E,$59,$49
  DEFB $4C,$20,$3F,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$45,$51,$55,$49
  DEFB $4E,$4F,$58,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$52,$45,$41,$4C
  DEFB $4D,$53,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4D,$41,$4A,$41
  DEFB $4C,$41,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4C,$45,$4E,$47
  DEFB $4B,$41,$50,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4A,$41,$5A,$5A
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$48,$45,$57,$53
  DEFB $4F,$4E,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$54,$49,$4D,$2E
  DEFB $4D,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$43,$45,$43,$43
  DEFB $4F,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4C,$55,$43,$59
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$41,$4E,$54,$4F
  DEFB $4E,$59,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4E,$49,$41,$45
  DEFB $52,$45,$48,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$2A,$21,$2F,$3F
  DEFB $21,$40,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$50,$4F,$44,$20
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$48,$55,$54,$4E
  DEFB $45,$45,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$42,$55,$54,$4E
  DEFB $45,$45,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4A,$4F,$48,$4E
  DEFB $2E,$4F,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$43,$41,$52,$52
  DEFB $4F,$54,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$43,$4F,$4C,$49
  DEFB $4E,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$46,$4C,$41,$53
  DEFB $48,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$53,$45,$56,$49
  DEFB $4C,$4C,$45,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$54,$2D,$53,$54
  DEFB $41,$54,$45,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$43,$4C,$55,$42
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$48,$57,$50,$20
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$43,$44,$50,$20
  DEFB $20,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$54,$41,$43,$48
  DEFB $59,$4F,$4E,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$4B,$49,$4C,$4C
  DEFB $45,$52,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$44,$52,$4F,$4F
  DEFB $50,$59,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$52,$20,$34,$20
  DEFB $53,$20,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$52,$5A,$41,$53
  DEFB $4D,$32,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$48,$55,$4D,$50
  DEFB $54,$59,$20,$20,$20,$20,$30,$30
  DEFB $31,$30,$30,$30,$FF,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00

; sub_7522
;
; Used by the routine at l_7149.
sub_7522:
  PUSH BC
  LD (data_78CA+$0010),SP
  LD SP,$6740
  LD BC,$08B2
  POP DE
l_752E:
  POP HL
  LD (l_752E+$0025),HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  INC L
  INC E
  INC L
  INC E
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD DE,$0000
  JP PE,l_752E
  LD SP,(data_78CA+$0010)
  EX DE,HL
  LD E,L
  LD D,H
  INC E
  LD BC,$0010
  LD (HL),B
  LDIR
  POP BC
  RET

; sub_7568
;
; Used by the routine at l_7149.
sub_7568:
  LD HL,(data_7588)
  LD A,(HL)
  CP $FF
  JP Z,sub_B0B7
  LD DE,$1708
  LD BC,$1000
l_7577:
  LD A,(HL)
  CALL sub_AE26
  INC E
  INC HL
  DJNZ l_7577
  LD (data_7588),HL
  LD BC,$028E
  JP sub_B0B7

; data_7588
data_7588:
  DEFB $00,$00

; l_758A
;
; Used by the routines at l_6DA1 and l_7149.
l_758A:
  DI
  CALL sub_B753
  CALL sub_B04B
  LD A,$FF
  LD (data_8269),A
  LD A,(data_7BDA)
  OR A
  CALL NZ,sub_7BAA
  XOR A
  LD (data_82F2+$0005),A
  INC A
  LD (data_82F2+$0008),A
  LD HL,l_7010
  LD (data_82F2+$0003),HL
  LD (data_82F2+$0001),HL
  LD A,$63
  LD (data_8E5A),A
  LD A,$0A
  LD (data_8E66),A
  CALL sub_7690
  CALL sub_8494
l_75BE:
  XOR A
  LD (data_9E98),A
  LD (data_9EAE),A
  CALL sub_BF7E
  CALL sub_7B72
  CALL sub_81A4
  CALL sub_8485
  CALL sub_8338
  CALL sub_83DD
  CALL sub_90A2
  CALL sub_9CE3
  CALL sub_9152
  CALL sub_9208
  CALL sub_925F
  CALL sub_83DD
  CALL sub_9A23
  CALL sub_9C15
  CALL sub_9835
  CALL sub_9118
  CALL sub_9942
  CALL sub_955D
  CALL sub_83DD
  CALL sub_98BA
  CALL sub_BF7E
  LD A,(data_925A)
  CP $13
  CALL C,sub_925F
  CALL sub_83DD
  CALL sub_90A2
  CALL sub_8F54
  CALL sub_8F95
  CALL sub_83DD
  LD A,(data_925A)
  CP $13
  CALL C,sub_925F
  CALL sub_9D7F
  CALL sub_9DD6
  CALL sub_9EC1
  CALL sub_9EEE
  CALL sub_A553
  CALL sub_9FBD
  CALL sub_9F2D
  CALL sub_A26B
  CALL sub_A30B
  CALL sub_A360
  CALL sub_A7D6
  CALL sub_A817
  CALL sub_ABCF
  CALL sub_AC59
  CALL sub_AC7D
  CALL sub_90EA
  CALL sub_9BB4
  CALL sub_9C8B
  CALL sub_9E64
  CALL sub_A5F4
  CALL sub_AD21
  CALL sub_9A19
  LD BC,$01F4
  CALL sub_B0B7
  CALL sub_BF7E
  CALL sub_9E85
  CALL sub_9E99
  LD A,(data_768C+$0001)
  OR A
  JR Z,l_767E
  DEC A
  LD (data_768C+$0001),A
l_767E:
  LD HL,data_768C
  INC (HL)
  LD HL,(data_AC78+$0003)
  INC HL
  LD (data_AC78+$0003),HL
  JP l_75BE

; data_768C
data_768C:
  DEFB $00,$00,$ED,$4D

; sub_7690
;
; Used by the routines at l_758A and l_A8A5.
sub_7690:
  LD HL,data_76A2
  CALL sub_AF2B
  CALL sub_8E4F
  CALL sub_8E5B
  CALL sub_8E67
  JP sub_8E7B

; data_76A2
data_76A2:
  DEFB $DF,$16,$00,$E6,$E0,$D7,$E8,$01
  DEFB $E9,$DC,$41,$4D,$4D,$4F,$20,$DD
  DEFB $47,$52,$45,$4E,$41,$44,$45,$53
  DEFB $20,$DB,$50,$4F,$49,$4E,$54,$53
  DEFB $20,$DE,$4C,$49,$56,$45,$53,$20
  DEFB $DA,$5A,$4F,$4E,$45,$53,$DF,$17
  DEFB $00,$E4,$20,$20,$E3,$82,$AD,$FF

; l_76DA
;
; Used by the routine at sub_8229.
l_76DA:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH HL
  PUSH BC
  PUSH HL
  PUSH DE
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,E
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,DE
  LD DE,data_C7F4+$278C
  ADD HL,DE
  LD (data_78CA+$0010),SP
  LD SP,HL
  ADD A,A
  AND $07
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,data_78CA
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD IX,$0000
  ADD IX,DE
  LD HL,data_78CA+$0012
  LD A,$20

; l_7712
;
; Used by the routines at l_7729 and l_7760.
l_7712:
  POP BC
  POP DE
  DEC SP
  LD D,$00
  JP (IX)

; l_7719
l_7719:
  RL E
  RL B
  RL C
  RL D
  RL E
  RL B
  RL C
  RL D

; l_7729
l_7729:
  RL E
  RL B
  RL C
  RL D
  RL E
  RL B
  RL C
  RL D
  LD (HL),D
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),E
  INC HL
  DEC A
  JP NZ,l_7712
  JP l_776C

; data_7748
data_7748:
  DEFB $CB,$19,$CB,$18,$CB,$1B,$CB,$1A

; l_7750
l_7750:
  RR C
  RR B
  RR E
  RR D
  RR C
  RR B
  RR E
  RR D

; l_7760
l_7760:
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DEC A
  JP NZ,l_7712

; l_776C
;
; Used by the routine at l_7729.
l_776C:
  LD SP,(data_78CA+$0010)
  POP DE
  CALL sub_B088
  LD (l_77FB+$000D),HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  PUSH DE
  LD BC,$5B00
  ADD HL,BC
  PUSH HL
  LD A,D
  LD DE,$001D
  LD B,$04
  AND $07
  JR Z,l_778F
  INC B
l_778F:
  LD A,$FF
l_7791:
  AND (HL)
  INC HL
  AND (HL)
  INC HL
  AND (HL)
  INC HL
  AND (HL)
  ADD HL,DE
  DJNZ l_7791
  POP HL
  POP DE
  EX AF,AF'
  LD A,E
  CP $75
  JP C,l_77CF
  EXX
  LD HL,data_78CA+$0013
  CP $7C
  LD DE,$0000
  LD C,D
  JR NC,l_77BD
  CP $78
  LD DE,data_C7F4+$370C
  LD C,E
  JR NC,l_77BD
  LD DE,data_C7F4+$380B
  LD C,$00
l_77BD:
  LD B,$20
l_77BF:
  LD A,D
  AND (HL)
  LD (HL),A
  INC HL
  LD A,E
  AND (HL)
  LD (HL),A
  INC HL
  LD A,C
  AND (HL)
  LD (HL),A
  INC HL
  INC HL
  DJNZ l_77BF
  EXX
l_77CF:
  EX AF,AF'
  JR NZ,l_77FB
  LD A,$08
  LD (l_77ED+$000A),A
  LD A,D
  AND $07
  LD DE,data_78CA+$0012
  JR Z,l_77ED
  LD (l_77ED+$000A),A
  LD B,A
  LD A,$08
  SUB B
  LD B,A
  LD DE,data_78CA+$0012
  CALL sub_78A0
l_77ED:
  CALL sub_789E
  CALL sub_789E
  CALL sub_789E
  LD B,$00
  CALL sub_78A0
l_77FB:
  POP HL
  POP DE
  LD B,H
  LD C,L
  CALL sub_B088
  LD D,B
  LD E,C
  LD C,$07
  EXX
  LD HL,$0000
  LD (data_78CA+$0010),SP
  LD SP,data_78CA+$0012
  LD BC,$2007
l_7814:
  POP DE
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  POP DE
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  DEC L
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,l_7837
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_7837
  LD A,H
  SUB $08
  LD H,A
l_7837:
  EXX
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,l_785D
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_785D
  LD A,H
  SUB $08
  LD H,A
l_785D:
  EXX
  DJNZ l_7814
  LD SP,(data_78CA+$0010)
  POP DE
  PUSH DE
  AND A
  LD HL,data_B101
  SBC HL,DE
  JR Z,l_7897
  LD HL,data_78CA+$0012
  LD BC,$0080
l_7874:
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
  LDI
  LDI
  LDI
  LDI
  JP PE,l_7874
l_7897:
  POP HL
  POP IX
  POP DE
  POP BC
  POP AF
  RET

; sub_789E
;
; Used by the routine at l_776C.
sub_789E:
  LD B,$08

; sub_78A0
;
; Used by the routine at l_776C.
sub_78A0:
  LD A,(HL)
  LD (l_78B0+$0002),A
  INC HL
  LD A,(HL)
  LD (l_78B0+$0007),A
  INC HL
  LD A,(HL)
  LD (l_78B0+$000C),A
  INC HL
  LD C,(HL)
l_78B0:
  LD A,(DE)
  AND $00
  LD (DE),A
  INC DE
  LD A,(DE)
  AND $00
  LD (DE),A
  INC DE
  LD A,(DE)
  AND $00
  LD (DE),A
  INC DE
  LD A,(DE)
  AND C
  LD (DE),A
  INC DE
  DJNZ l_78B0
  LD BC,$001D
  ADD HL,BC
  RET

; data_78CA
data_78CA:
  DEFB $60,$77,$58,$77,$50,$77,$48,$77
  DEFB $19,$77,$21,$77,$29,$77,$31,$77
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; sub_795C
;
; Used by the routines at sub_6F1F, sub_9E99, sub_9FBD, sub_A26B, l_A367,
; sub_A62D, sub_A7D6 and sub_AC7D.
sub_795C:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH HL
  PUSH BC
  PUSH HL
  PUSH DE
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,E
  LD DE,data_C7F4+$30EC
  ADD HL,DE
  LD (data_78CA+$0010),SP
  LD SP,HL
  ADD A,A
  AND $07
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,data_7AD9
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD IX,$0000
  ADD IX,DE
  LD HL,data_78CA+$0012
  LD B,$10

; l_7990
;
; Used by the routines at l_799E and l_79C2.
l_7990:
  POP DE
  XOR A
  JP (IX)

; l_7994
l_7994:
  SLA D
  RL E
  RLA
  SLA D
  RL E
  RLA

; l_799E
l_799E:
  SLA D
  RL E
  RLA
  SLA D
  RL E
  RLA
  LD (HL),A
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DJNZ l_7990
  JP l_79CA

; data_79B3
data_79B3:
  DEFB $CB,$3B,$CB,$1A,$1F

; l_79B8
l_79B8:
  SRL E
  RR D
  RRA
  SRL E
  RR D
  RRA

; l_79C2
l_79C2:
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),A
  INC HL
  DJNZ l_7990

; l_79CA
;
; Used by the routine at l_799E.
l_79CA:
  LD SP,(data_78CA+$0010)
  POP DE
  CALL sub_B088
  LD (l_7A1E+$000D),HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  PUSH DE
  LD BC,$5B00
  ADD HL,BC
  PUSH HL
  LD A,D
  LD DE,$001E
  LD B,$02
  AND $07
  JR Z,l_79ED
  INC B
l_79ED:
  LD A,$FF
l_79EF:
  AND (HL)
  INC L
  AND (HL)
  INC L
  AND (HL)
  ADD HL,DE
  DJNZ l_79EF
  POP HL
  POP DE
  JR NZ,l_7A1E
  LD A,$08
  LD (l_7A16+$0004),A
  LD A,D
  AND $07
  LD DE,data_78CA+$0012
  JR Z,l_7A16
  LD (l_7A16+$0004),A
  LD B,A
  LD A,$08
  SUB B
  LD B,A
  LD DE,data_78CA+$0012
  CALL sub_7AB9
l_7A16:
  CALL sub_7AB7
  LD B,$00
  CALL sub_7AB9
l_7A1E:
  POP HL
  POP DE
  LD B,H
  LD C,L
  CALL sub_B088
  LD D,B
  LD E,C
  LD C,$07
  EXX
  LD HL,$0000
  LD (data_78CA+$0010),SP
  LD SP,data_78CA+$0012
  LD BC,$1007
l_7A37:
  POP DE
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  POP DE
  LD A,E
  XOR (HL)
  LD (HL),A
  DEC SP
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,l_7A56
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_7A56
  LD A,H
  SUB $08
  LD H,A
l_7A56:
  EXX
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC DE
  DEC L
  DEC L
  INC H
  LD A,H
  AND C
  JR NZ,l_7A76
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_7A76
  LD A,H
  SUB $08
  LD H,A
l_7A76:
  EXX
  DJNZ l_7A37
  LD SP,(data_78CA+$0010)
  POP DE
  PUSH DE
  AND A
  LD HL,data_B101
  SBC HL,DE
  JR Z,l_7AB0
  LD HL,data_78CA+$0012
  LD BC,$0030
l_7A8D:
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
  LDI
  LDI
  LDI
  LDI
  JP PE,l_7A8D
l_7AB0:
  POP HL
  POP IX
  POP DE
  POP BC
  POP AF
  RET

; sub_7AB7
;
; Used by the routine at l_79CA.
sub_7AB7:
  LD B,$08

; sub_7AB9
;
; Used by the routine at l_79CA.
sub_7AB9:
  LD A,(HL)
  LD (l_7AC4+$0002),A
  INC HL
  LD A,(HL)
  LD (l_7AC4+$0007),A
  INC HL
  LD C,(HL)
l_7AC4:
  LD A,(DE)
  AND $00
  LD (DE),A
  INC DE
  LD A,(DE)
  AND $00
  LD (DE),A
  INC DE
  LD A,(DE)
  AND C
  LD (DE),A
  INC DE
  DJNZ l_7AC4
  LD BC,$001E
  ADD HL,BC
  RET

; data_7AD9
data_7AD9:
  DEFB $C2,$79,$BD,$79,$B8,$79,$B3,$79
  DEFB $94,$79,$99,$79,$9E,$79,$A3,$79
data_7AD9_0:
  DEFB $16,$01,$21,$91,$7B,$0E,$FE,$23
  DEFB $06,$DF,$ED,$78,$E6,$02,$20,$01
  DEFB $72,$23,$06,$DF,$ED,$78,$E6,$01
  DEFB $20,$01,$72,$23,$06,$FB,$ED,$78
  DEFB $E6,$01,$20,$01,$72,$23,$06,$FD
  DEFB $ED,$78,$E6,$01,$20,$01,$72,$23
  DEFB $06,$7F,$ED,$78,$E6,$04,$C0,$72
  DEFB $C9

; l_7B22
;
; Used by the routine at sub_7B72.
l_7B22:
  LD BC,$EFFE
  IN A,(C)
  CPL
  AND $1F
  LD D,A
  CALL sub_7B6D
  LD (data_7B92+$0004),A
  CALL sub_7B6D
  LD (data_7B92+$0002),A
  CALL sub_7B6D
  LD (data_7B92+$0003),A
  CALL sub_7B6D
  LD (data_7B92+$0001),A
  CALL sub_7B6D
  LD (data_7B92),A
  RET

; l_7B4A
;
; Used by the routine at sub_7B72.
l_7B4A:
  LD C,$1F
  IN D,(C)
  CALL sub_7B6D
  LD (data_7B92+$0001),A
  CALL sub_7B6D
  LD (data_7B92),A
  CALL sub_7B6D
  LD (data_7B92+$0003),A
  CALL sub_7B6D
  LD (data_7B92+$0002),A
  CALL sub_7B6D
  LD (data_7B92+$0004),A
  RET

; sub_7B6D
;
; Used by the routines at l_7B22 and l_7B4A.
sub_7B6D:
  XOR A
  SRL D
  RLA
  RET

; sub_7B72
;
; Used by the routines at l_758A and sub_A8DB.
sub_7B72:
  CALL sub_7B84
  LD A,(data_7B92+$0005)
  OR A
  JP Z,data_7AD9_0
  CP $01
  JP Z,l_7B22
  JP l_7B4A

; sub_7B84
;
; Used by the routine at sub_7B72.
sub_7B84:
  LD HL,data_7B92
  LD DE,data_7B92+$0001
  LD (HL),$00
  LD BC,$0004
  LDIR
  RET

; data_7B92
data_7B92:
  DEFB $00,$00,$00,$00,$00,$00,$00

; sub_7B99
;
; Used by the routine at l_6D60.
sub_7B99:
  LD HL,$6400
l_7B9C:
  LD D,L
  LD B,$08
l_7B9F:
  SRL D
  RL C
  DJNZ l_7B9F
  LD (HL),C
  INC L
  JR NZ,l_7B9C
  RET

; sub_7BAA
;
; Used by the routines at l_758A, l_8295 and sub_9CE3.
sub_7BAA:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,(data_7BDA)
  XOR $01
  LD (data_7BDA),A
  LD HL,data_C7F4+$278C
  LD D,$64
  LD BC,$0300
l_7BBE:
  PUSH BC
  PUSH HL
  LD E,(HL)
  LD A,(DE)
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  LD (HL),A
  INC HL
  LD E,(HL)
  LD A,(DE)
  LD (HL),C
  INC HL
  POP BC
  LD (BC),A
  POP BC
  DEC BC
  LD A,B
  OR C
  JP NZ,l_7BBE
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; data_7BDA
data_7BDA:
  DEFB $00,$21,$00,$80,$36,$81,$11,$01
  DEFB $80,$01,$01,$01,$ED,$B0,$ED,$5E
  DEFB $3E,$80,$ED,$47,$C9

; sub_7BEF
;
; Used by the routine at l_6D60.
sub_7BEF:
  LD B,$C0
  LD IX,$6500
  LD IY,$6600
  LD HL,$4000
l_7BFC:
  LD (IX+$00),H
  LD (IY+$00),L
  INC IX
  INC IY
  CALL sub_B099
  DJNZ l_7BFC
  LD B,$C0
  LD HL,$4008
  LD IX,$6700
l_7C14:
  LD (IX+$00),L
  LD (IX+$01),H
  INC IX
  INC IX
  CALL sub_B099
  DJNZ l_7C14
  RET

; data_7C24
data_7C24:
  DEFB $06,$37

; sub_7C26
;
; Used by the routines at l_701E, sub_8338, sub_83DD, sub_9071, sub_9EC1,
; sub_9FBD and sub_A817.
sub_7C26:
  LD A,(data_6E16)
  OR A
  RET NZ
l_7C2B:
  LD A,R
  AND $F8
  OUT ($FE),A
  LD E,B
  INC E
l_7C33:
  DEC E
  JR NZ,l_7C33
  XOR A
  OUT ($FE),A
  DJNZ l_7C2B
  RET

; sub_7C3C
;
; Used by the routine at sub_9942.
sub_7C3C:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,(data_6E16)
  OR A
  JR NZ,l_7C5A
  XOR A
  LD DE,$1030
l_7C4A:
  LD H,$0A
l_7C4C:
  XOR $10
  OUT ($FE),A
  LD B,E
l_7C51:
  DJNZ l_7C51
  DEC H
  JR NZ,l_7C4C
  INC E
  DEC D
  JR NZ,l_7C4A
l_7C5A:
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; sub_7C5F
;
; Used by the routine at sub_8229.
sub_7C5F:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,$1D
  LD H,$00
  LD (l_7CA7+$000F),HL
  LD A,$03
  LD (l_7CA7+$0012),A
  LD A,$04
  LD (l_7CBE+$000A),A
  JP l_7CA7

; sub_7C77
;
; Used by the routines at l_9291, sub_955D, sub_9835, l_9A7F and sub_9DD6.
sub_7C77:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,$1F
  LD H,$00
  LD (l_7CA7+$000F),HL
  LD A,$01
  LD (l_7CA7+$0012),A
  LD A,$01
  LD (l_7CBE+$000A),A
  JP l_7CA7

; sub_7C8F
;
; Used by the routines at sub_6EA9, sub_9FBD, sub_A26B, l_A367, sub_A7D6 and
; sub_AC7D.
sub_7C8F:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,$1E
  LD H,$00
  LD (l_7CA7+$000F),HL
  LD A,$02
  LD (l_7CA7+$0012),A
  LD A,$02
  LD (l_7CBE+$000A),A
  JP l_7CA7

; l_7CA7
;
; Used by the routines at sub_7C5F, sub_7C77 and sub_7C8F.
l_7CA7:
  CALL sub_80DA
  LD A,C
  PUSH HL
  LD BC,$FA00
  ADD HL,BC
  LD C,A
  PUSH HL
  LD A,E
  AND $03
  LD HL,$001D
  LD A,$03
  JR Z,l_7CBE
  DEC HL
  INC A
l_7CBE:
  LD (l_7CCE+$0002),A
  LD (l_7CD6+$0006),HL
  LD A,D
  AND $07
  LD A,$04
  JR Z,l_7CCC
  INC A
l_7CCC:
  POP HL
  POP DE
l_7CCE:
  EX AF,AF'
  LD B,$00
l_7CD1:
  LD A,(DE)
  OR A
  JR NZ,l_7CD6
  LD (HL),C
l_7CD6:
  INC HL
  INC DE
  DJNZ l_7CD1
  LD A,C
  LD BC,$0000
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD C,A
  EX AF,AF'
  DEC A
  JR NZ,l_7CCE
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; data_7CEC
data_7CEC:
  DEFB $C5,$E5,$CD,$72,$7B,$3A,$96,$7B
  DEFB $B7,$3E,$30,$20,$1B,$21,$EF,$AC
  DEFB $16,$FE,$7A,$DB,$FE,$1E,$01,$06
  DEFB $05,$0F,$30,$0B,$23,$CB,$23,$10
  DEFB $F8,$CB,$02,$38,$ED,$18,$DB,$7E
  DEFB $E1,$C1,$C9

; sub_7D17
;
; Used by the routines at l_6DA1 and l_A02A.
sub_7D17:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,sub_7D17
  LD (data_7D67+$0288),HL
; This entry point is used by the routine at l_7D4E.
l_7D22:
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JP Z,l_7D2D
l_7D2C:
  RET
l_7D2D:
  LD HL,(data_7D67+$0288)
  LD A,(HL)
  OR A
  JP Z,l_7D2C
  INC HL
  LD (data_7D67+$0287),A
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (data_7D67+$0288),HL
  LD A,C
  OR B
  JP NZ,l_7D4E

; data_7D45
data_7D45:
  DEFB $3A,$EE,$7F,$CD,$04,$80,$C3,$22
  DEFB $7D

; l_7D4E
;
; Used by the routine at sub_7D17.
l_7D4E:
  LD H,$00
  LD L,C
  LD DE,data_8062
  ADD HL,DE
  LD D,(HL)
  LD H,$00
  LD L,B
  LD BC,data_8062
  ADD HL,BC
  LD E,(HL)
  LD A,(data_7D67+$0287)
  CALL sub_803D
  JP l_7D22

; data_7D67
data_7D67:
  DEFB $00,$0F,$1C,$28,$0F,$1C,$2C,$0F
  DEFB $1C,$2F,$0F,$1B,$27,$0F,$1B,$2B
  DEFB $0F,$1B,$2E,$0F,$1A,$26,$0F,$1A
  DEFB $2A,$0F,$1A,$2D,$0F,$19,$25,$0F
  DEFB $19,$29,$0F,$19,$2C,$0F,$18,$24
  DEFB $0F,$18,$28,$0F,$18,$2B,$0F,$17
  DEFB $23,$0F,$17,$27,$0F,$17,$2A,$2D
  DEFB $1C,$28,$00,$00,$12,$13,$2B,$12
  DEFB $13,$26,$12,$13,$2B,$12,$13,$2F
  DEFB $24,$13,$32,$24,$13,$26,$24,$18
  DEFB $28,$12,$18,$30,$12,$18,$2F,$12
  DEFB $18,$30,$12,$18,$2F,$24,$18,$2D
  DEFB $12,$1A,$2D,$12,$1A,$2A,$12,$1A
  DEFB $2B,$24,$1A,$2D,$12,$1A,$2A,$24
  DEFB $1A,$26,$24,$13,$30,$12,$13,$30
  DEFB $36,$13,$2F,$24,$13,$2B,$12,$13
  DEFB $2B,$12,$13,$26,$12,$13,$2B,$12
  DEFB $13,$2F,$24,$13,$32,$24,$13,$26
  DEFB $24,$18,$28,$12,$18,$30,$12,$18
  DEFB $2F,$12,$18,$30,$12,$18,$2F,$24
  DEFB $18,$2D,$12,$1A,$2D,$12,$1A,$2A
  DEFB $12,$1A,$2B,$24,$1A,$2D,$12,$1A
  DEFB $2A,$24,$1A,$26,$24,$13,$30,$12
  DEFB $13,$30,$36,$13,$2F,$24,$13,$2D
  DEFB $24,$10,$2B,$24,$10,$23,$24,$10
  DEFB $2B,$12,$10,$23,$24,$10,$2F,$12
  DEFB $10,$23,$12,$10,$2F,$12,$10,$23
  DEFB $12,$10,$2D,$12,$10,$23,$12,$10
  DEFB $2B,$12,$10,$23,$24,$0C,$2B,$24
  DEFB $0C,$24,$24,$0C,$2B,$12,$0C,$24
  DEFB $24,$0C,$2F,$12,$0C,$24,$12,$0C
  DEFB $2F,$12,$0C,$24,$12,$0C,$2D,$12
  DEFB $0C,$24,$12,$0C,$2B,$12,$0C,$24
  DEFB $24,$10,$2B,$24,$10,$23,$24,$10
  DEFB $2B,$12,$10,$23,$24,$10,$2F,$12
  DEFB $10,$23,$12,$10,$2F,$12,$10,$23
  DEFB $12,$10,$2D,$12,$10,$23,$12,$10
  DEFB $2B,$12,$10,$23,$24,$0C,$2B,$24
  DEFB $0C,$24,$24,$0C,$2B,$12,$0C,$24
  DEFB $24,$0C,$2F,$12,$0C,$24,$12,$0C
  DEFB $2F,$12,$0C,$24,$12,$0C,$2D,$12
  DEFB $0C,$24,$12,$0C,$2B,$12,$0C,$24
  DEFB $24,$10,$2F,$24,$10,$30,$12,$10
  DEFB $2D,$24,$10,$2F,$24,$10,$2B,$24
  DEFB $10,$2D,$24,$10,$2A,$12,$10,$2F
  DEFB $24,$10,$28,$24,$10,$2F,$24,$10
  DEFB $30,$12,$10,$2D,$24,$10,$2F,$24
  DEFB $10,$2B,$24,$10,$2D,$24,$10,$2A
  DEFB $12,$10,$2F,$24,$10,$28,$24,$0C
  DEFB $2D,$12,$0C,$2D,$5A,$0C,$2B,$24
  DEFB $0C,$18,$12,$0C,$2B,$24,$0C,$2D
  DEFB $12,$0C,$2D,$24,$0C,$2B,$24,$07
  DEFB $28,$12,$07,$28,$5A,$07,$26,$24
  DEFB $07,$13,$12,$07,$26,$24,$07,$28
  DEFB $12,$07,$28,$24,$07,$26,$24,$10
  DEFB $2F,$24,$10,$30,$12,$10,$2D,$24
  DEFB $10,$2F,$24,$10,$2B,$24,$10,$2D
  DEFB $24,$10,$2A,$12,$10,$2F,$24,$10
  DEFB $28,$24,$10,$2F,$24,$10,$30,$12
  DEFB $10,$2D,$24,$10,$2F,$24,$10,$2B
  DEFB $24,$10,$2D,$24,$10,$2A,$12,$10
  DEFB $2F,$24,$10,$28,$24,$0C,$2D,$12
  DEFB $0C,$2D,$5A,$0C,$2B,$24,$0C,$18
  DEFB $12,$0C,$2B,$24,$0C,$2D,$12,$0C
  DEFB $2D,$24,$0C,$2B,$24,$07,$28,$12
  DEFB $07,$28,$5A,$07,$26,$24,$07,$13
  DEFB $12,$07,$26,$24,$07,$28,$12,$07
  DEFB $26,$12,$07,$28,$12,$07,$26,$48
  DEFB $11,$24,$48,$11,$21,$24,$11,$24
  DEFB $12,$11,$21,$24,$11,$24,$12,$11
  DEFB $21,$12,$11,$28,$12,$11,$26,$48
  DEFB $0C,$24,$48,$0C,$1F,$24,$0C,$24
  DEFB $12,$0C,$1F,$24,$0C,$24,$12,$0C
  DEFB $1F,$12,$0C,$28,$12,$0C,$26,$24
  DEFB $11,$24,$24,$11,$21,$24,$11,$24
  DEFB $24,$11,$21,$24,$11,$24,$12,$11
  DEFB $21,$24,$11,$24,$12,$11,$21,$12
  DEFB $11,$28,$12,$11,$26,$24,$0C,$24
  DEFB $24,$0C,$1F,$24,$0C,$24,$24,$0C
  DEFB $1F,$12,$0C,$24,$12,$0C,$30,$12
  DEFB $0C,$30,$24,$0C,$24,$00,$00,$EE
  DEFB $00,$00,$E6,$FF,$08,$14,$C2,$1F
  DEFB $80,$00,$00,$00,$A9,$55,$10,$0F
  DEFB $25,$C2,$10,$80,$C9,$67,$DD,$6B
  DEFB $6A,$0E,$10,$AF,$08,$AF,$47,$B7
  DEFB $A7,$08,$1C,$00,$00,$00,$20,$DA
  DEFB $A9,$DD,$5D,$08,$14,$CA,$F8,$7F
  DEFB $00,$00,$00,$B7,$A7,$10,$E8,$25
  DEFB $C2,$10,$80,$C9

; l_802B
;
; Used by the routine at l_8049.
l_802B:
  AND $FF

; l_802D
l_802D:
  EX AF,AF'
  INC D
  JP NZ,l_8057

; l_8032
;
; Used by the routine at l_8049.
l_8032:
  OUT ($FE),A
  XOR C

; l_8035
l_8035:
  LD D,L
  DJNZ l_8047
  DEC H
  JP NZ,l_8049
  RET

; sub_803D
;
; Used by the routine at l_7D4E.
sub_803D:
  LD H,A

; l_803E
l_803E:
  LD IXL,E
  LD L,D
  LD C,$10
  XOR A
  EX AF,AF'
  XOR A
  LD B,A

; l_8047
;
; Used by the routines at l_8035 and l_8057.
l_8047:
  OR A

; l_8048
l_8048:
  AND A

; l_8049
;
; Used by the routines at l_8035 and l_8057.
l_8049:
  EX AF,AF'
  INC E
  OUT ($FE),A
  JR NZ,l_802B
  XOR C
  LD E,IXL
  EX AF,AF'
  INC D
  JP Z,l_8032

; l_8057
;
; Used by the routine at l_802D.
l_8057:
  OUT ($FE),A
  OR A
  AND A
  DJNZ l_8047
  DEC H
  JP NZ,l_8049
  RET

; data_8062
data_8062:
  DEFB $01,$10,$1D,$29,$34,$40,$4C,$54
  DEFB $5F,$69,$70,$78,$80,$87,$8E,$94
  DEFB $9A,$A0,$A5,$AA,$AF,$B4,$B8,$BC
  DEFB $C0,$C3,$C7,$CA,$CD,$D0,$D3,$D5
  DEFB $D8,$DA,$DC,$DE,$E0,$E2,$E4,$E5
  DEFB $E7,$E8,$E9,$EB,$EC,$ED,$EE,$EF
  DEFB $F0,$F1,$F2,$F3,$F4

; sub_8097
;
; Used by the routines at sub_6EA9, sub_6F90, sub_80C1, sub_80DA, sub_8F95,
; sub_9118, sub_91CF, sub_A23A, sub_A26B, sub_A2D5, l_AB97 and sub_ABCF.
sub_8097:
  LD A,D
  SRA A
  SRA A
  SRA A
  LD H,A
  LD A,D
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD L,A
  RET

; data_80A8
data_80A8:
  DEFB $F5,$D5,$7B,$E6,$7C,$0F,$0F,$5F
  DEFB $7A,$E6,$F8,$0F,$0F,$0F,$57,$CD
  DEFB $97,$80,$11,$00,$5B,$19,$D1,$F1
  DEFB $C9

; sub_80C1
;
; Used by the routines at sub_80F3, sub_8122, sub_814E, sub_8179, sub_8391,
; sub_9362, sub_9382, sub_93A2, sub_93C2 and sub_AF2B.
sub_80C1:
  PUSH AF
  PUSH DE
  LD A,E
  AND $7C
  RRCA
  RRCA
  LD E,A
  LD A,D
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  CALL sub_8097
  LD DE,$6100
  ADD HL,DE
  POP DE
  POP AF
  RET

; sub_80DA
;
; Used by the routine at l_7CA7.
sub_80DA:
  PUSH AF
  PUSH DE
  LD A,E
  AND $7C
  RRCA
  RRCA
  LD E,A
  LD A,D
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  CALL sub_8097
  LD DE,$5E00
  ADD HL,DE
  POP DE
  POP AF
  RET

; sub_80F3
;
; Used by the routines at sub_81A4 and l_8295.
sub_80F3:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  CP $74
  LD A,$00
  JR NC,l_811D
  LD A,E
  AND $03
  LD A,$00
  JR NZ,l_811D
  CALL sub_80C1
  INC L
  INC L
  INC L
  LD BC,$0020
  LD A,(HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,l_811D
  ADD HL,BC
  OR (HL)
l_811D:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; sub_8122
;
; Used by the routines at sub_81A4 and l_8295.
sub_8122:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  OR A
  LD A,$01
  JR Z,l_8149
  LD A,E
  AND $03
  LD A,$00
  JR NZ,l_8149
  CALL sub_80C1
  DEC L
  LD BC,$0020
  LD A,(HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,l_8149
  ADD HL,BC
  OR (HL)
l_8149:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; sub_814E
;
; Used by the routines at sub_81A4, l_8280 and sub_9CE3.
sub_814E:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,l_8174
  CALL sub_80C1
  LD BC,$0080
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  CP $74
  LD A,D
  JR NC,l_8174
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,l_8174
  INC L
  OR (HL)
l_8174:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; sub_8179
;
; Used by the routine at sub_81A4.
sub_8179:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,l_819F
  CALL sub_80C1
  LD BC,$FFE0
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  CP $74
  LD A,D
  JR NC,l_819F
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,l_819F
  INC L
  OR (HL)
l_819F:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; sub_81A4
;
; Used by the routine at l_758A.
sub_81A4:
  CALL sub_9D78
  XOR A
  LD (data_82F2),A
  LD DE,(data_82F2+$0003)
  LD A,(data_8294)
  OR A
  JP NZ,l_8280
  LD A,(data_82F2+$0005)
  OR A
  JR NZ,l_81E3
  CALL sub_814E
  JP Z,l_8280
  LD A,$FA
  LD (data_82F2+$0009),A
  LD A,(data_7B92+$0003)
  OR A
  LD A,$0A
  JP NZ,sub_8224
  XOR A
  LD (data_82F2+$0009),A
  LD A,(data_7B92+$0002)
  OR A
  JP Z,l_8280
  CALL sub_814E
  JP Z,l_8280
  LD A,$16
l_81E3:
  LD HL,data_8269
  LD C,A
  LD B,$00
  DEC A
  LD (data_82F2+$0005),A
  ADD HL,BC
  LD A,(HL)
  OR A
  JR Z,l_820A
  CP $0A
  JR NC,l_81FB
  CALL sub_814E
  JR l_81FE
l_81FB:
  CALL sub_8179
l_81FE:
  JR Z,l_8207
  XOR A
  LD (data_82F2+$0005),A
  JP l_8280
l_8207:
  LD A,(HL)
  ADD A,D
  LD D,A
l_820A:
  LD A,(data_82F2+$0006)
  OR A
  JR Z,l_8222
  DEC A
  JR Z,l_8218
  CALL sub_8122
  JR l_821B
l_8218:
  CALL sub_80F3
l_821B:
  JR NZ,l_8222
  LD A,(data_82F2+$0006)
  ADD A,E
  LD E,A
l_8222:
  LD A,$03

; sub_8224
;
; Used by the routines at sub_81A4, l_8280, l_8295, sub_98BA, sub_9CAF,
; sub_9CE3 and sub_9F2D.
sub_8224:
  LD C,A
  LD A,(data_9ED6+$0002)
  ADD A,C

; sub_8229
;
; Used by the routine at sub_9942.
sub_8229:
  EX AF,AF'
  LD A,E
  CP $80
  LD A,D
  JR Z,sub_8253
  LD C,$47
  EX AF,AF'
  CALL sub_7C5F
  LD BC,(data_82F2+$0003)
  LD (data_82F2+$0003),DE
  LD HL,(data_8269)
  CP L
  JR NZ,l_824A
  LD H,B
  LD L,C
  AND A
  SBC HL,DE
  RET Z
l_824A:
  LD (data_8269),A
  LD HL,data_B101+$0080
  JP l_76DA

; sub_8253
;
; Used by the routines at sub_8229 and l_A8A5.
sub_8253:
  LD (data_82F2+$0004),A
  LD (data_82F2+$0002),A
  LD (data_82F2),A
  LD A,(data_8523)
  INC A
  LD (data_8523),A
  LD A,$FF
  LD (data_8269),A
  RET

; data_8269
data_8269:
  DEFB $00,$04,$04,$02,$02,$02,$01,$01
  DEFB $01,$01,$00,$00,$00,$00,$FF,$FF
  DEFB $FF,$FF,$FE,$FE,$FE,$FC,$FC

; l_8280
;
; Used by the routine at sub_81A4.
l_8280:
  XOR A
  LD (data_8294),A
  CALL sub_814E
  JR NZ,l_8295
  INC D
  INC D
  INC D
  INC D
  LD A,$09
  LD (data_8294),A
  JR sub_8224

; data_8294
data_8294:
  DEFB $00

; l_8295
;
; Used by the routine at l_8280.
l_8295:
  LD HL,(data_7B92)
  LD A,H
  XOR L
  LD (data_82F2+$0006),A
  LD A,$05
  JP Z,sub_8224
  LD A,$01
  LD (data_82F2+$0008),A
  BIT 0,L
  JR Z,l_82C1
  LD A,$FF
  LD (data_82F2+$0006),A
  LD (data_82F2+$0008),A
  LD A,(data_7BDA)
  OR A
  CALL Z,sub_7BAA
  JR Z,l_82E8
  CALL sub_8122
  JR l_82CD
l_82C1:
  LD A,(data_7BDA)
  OR A
  CALL NZ,sub_7BAA
  JR NZ,l_82E8
  CALL sub_80F3
l_82CD:
  LD A,$05
  JP NZ,sub_8224
  LD A,(data_82F2+$0006)
  ADD A,E
  LD E,A
  LD A,(data_82F2+$0007)
  CP $0A
  JR NZ,l_82DF
  XOR A
l_82DF:
  LD B,A
  INC A
  LD (data_82F2+$0007),A
  LD A,B
  JP sub_8224
l_82E8:
  LD A,$FF
  LD (data_8269),A
  LD A,$05
  JP sub_8224

; data_82F2
data_82F2:
  DEFB $00,$00,$00,$00,$00,$00,$01,$00
  DEFB $01,$00

; sub_82FC
;
; Used by the routines at sub_8391, sub_83DD, sub_9B82 and sub_9F71.
sub_82FC:
  PUSH AF
  PUSH BC
  PUSH HL
  PUSH DE
  LD L,$BD
  LD H,$00
  LD A,E
  CPL
  AND $03
  INC A
  LD B,A
l_830A:
  ADD HL,HL
  ADD HL,HL
  DJNZ l_830A
  PUSH HL
  CALL sub_B088
  POP DE
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  LD A,E
  XOR (HL)
  LD (HL),A
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD BC,$5E00
  ADD HL,BC
  LD A,(HL)
  DEC L
  OR (HL)
  JR NZ,l_8333
  LD BC,$FA00
  ADD HL,BC
  LD (HL),$47
  INC L
  LD (HL),$47
l_8333:
  POP DE
  POP HL
  POP BC
  POP AF
  RET

; sub_8338
;
; Used by the routine at l_758A.
sub_8338:
  CALL sub_9D78
  LD A,(data_82F2+$0003)
  CP $76
  JR C,l_8347
  XOR A
  LD (data_7B92+$0006),A
  RET
l_8347:
  LD A,(data_7B92+$0004)
  OR A
  JR NZ,l_8351
  LD (data_83DC),A
  RET
l_8351:
  LD A,(data_83DC)
  OR A
  JR Z,l_835D
  INC A
  RET Z
  LD (data_83DC),A
  RET
l_835D:
  INC A
  LD (data_83DC),A
  LD A,(data_8E5A)
  OR A
  RET Z
  LD B,$3C
  CALL sub_7C26
  LD A,(data_8E5A)
  DEC A
  LD (data_8E5A),A
  CALL sub_C177
  CALL sub_8E4F
  CALL sub_8391
  LD A,(data_9ED6+$0002)
  OR A
  RET Z
  LD A,(data_82F2+$0004)
  PUSH AF
  ADD A,$06
  LD (data_82F2+$0004),A
  CALL sub_8391
  POP AF
  LD (data_82F2+$0004),A
  RET

; sub_8391
;
; Used by the routine at sub_8338.
sub_8391:
  LD HL,data_845F
l_8394:
  BIT 7,(HL)
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR NZ,l_8394
  DEC HL
  LD A,(data_82F2+$0008)
  LD (HL),A
  LD DE,(data_82F2+$0003)
  LD A,(data_82F2+$0009)
  OR A
  LD A,$0E
  JR Z,l_83B1
  LD A,$13
l_83B1:
  ADD A,D
  LD D,A
  DEC HL
  LD (HL),D
  DEC HL
  LD A,(data_82F2+$0008)
  INC A
  OR A
  LD A,$FC
  JR Z,l_83C1
  LD A,$0C
l_83C1:
  ADD A,E
  LD E,A
  CP $78
  JR NC,l_83D7
  CP $04
  JR C,l_83D7
  LD (HL),E
  PUSH HL
  CALL sub_80C1
  LD A,(HL)
  INC L
  OR (HL)
  POP HL
  JP Z,sub_82FC
l_83D7:
  INC HL
  INC HL
  LD (HL),$00
  RET

; data_83DC
data_83DC:
  DEFB $00

; sub_83DD
;
; Used by the routine at l_758A.
sub_83DD:
  CALL sub_9B52
  CALL sub_9E37
  CALL sub_A5CA
  CALL sub_AC04
  LD HL,data_845F
l_83EC:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_83EC
  CALL sub_82FC
  LD B,A
  LD C,D
  LD A,D
  AND $F8
  LD D,A
  LD A,B
  INC A
  JR NZ,l_840F
  CALL sub_9382
  CALL NZ,sub_C0E7
  JR NZ,l_8444
  JR l_841C
l_840F:
  LD A,E
  CP $7C
  JR Z,l_8459
  CALL sub_9362
  CALL NZ,sub_C0E7
  JR NZ,l_8444
l_841C:
  LD D,C
  LD A,E
  CP $7C
  JR Z,l_8459
  CP $01
  JR Z,l_8459
  LD A,(data_82F2+$0003)
  ADD A,$40
  CP E
  JR Z,l_8459
  LD A,(data_82F2+$0003)
  SUB $34
  CP E
  JR Z,l_8459
  LD A,B
  ADD A,E
  LD E,A
  PUSH HL
  DEC HL
  DEC HL
  DEC HL
  LD (HL),E
  POP HL
  CALL sub_82FC
  JR l_83EC
l_8444:
  DEC HL
  LD (HL),$00
  INC HL
  LD D,C
  CALL sub_981D
  LD B,$14
l_844E:
  PUSH BC
  LD B,$14
  CALL sub_7C26
  POP BC
  DJNZ l_844E
  JR l_83EC
l_8459:
  DEC HL
  LD (HL),$00
  INC HL
  JR l_83EC

; data_845F
data_845F:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF

; sub_8478
;
; Used by the routine at sub_8494.
sub_8478:
  LD HL,data_845F
  LD DE,data_845F+$0001
  LD BC,$0017
  LD (HL),B
  LDIR
  RET

; sub_8485
;
; Used by the routines at l_758A and l_A8A5.
sub_8485:
  LD A,(data_82F2)
  OR A
  RET Z
  XOR A
  LD (data_82F2+$0003),A
  LD (data_82F2+$0001),A
  CALL sub_8E7B

; sub_8494
;
; Used by the routine at l_758A.
sub_8494:
  LD HL,$0000
  LD (data_AC78+$0003),HL
  XOR A
  LD (data_925A),A
  LD (data_768C+$0001),A
  LD (data_AC78),A
  CALL sub_B0F3
  CALL sub_8E03
  CALL sub_8DF5
  CALL sub_8478
  CALL sub_910B
  CALL sub_91FA
  CALL sub_980F
  CALL sub_902F
  CALL sub_98AD
  CALL sub_9AFA
  CALL sub_9C7D
  CALL sub_9E0A
  CALL sub_9F20
  CALL sub_A545
  CALL sub_A01C
  CALL sub_A352
  CALL sub_B061
  LD A,(data_8523)
  LD BC,data_C7F4
  CALL sub_8524
  LD IX,data_9437
l_84E4:
  LD A,(HL)
  CP $FF
  JR Z,l_850A
  LD D,A
  INC HL
  LD E,(HL)
  INC HL
  PUSH HL
  LD A,(HL)
  CALL sub_9487
  LD BC,data_852E
  CALL sub_8524
  LD A,$01
  LD (l_AE03+$0018),A
  XOR A
  LD (l_AE03+$001E),A
  LD C,A
  CALL sub_AF2B
  POP HL
  INC HL
  JP l_84E4
l_850A:
  LD (IX+$00),$FF
  CALL sub_8E11
  CALL sub_A2D5
  CALL sub_8E86
  CALL sub_9B07
  CALL sub_A645
  CALL sub_A23A
  JP l_AB97

; data_8523
data_8523:
  DEFB $00

; sub_8524
;
; Used by the routines at sub_8494, l_93E2 and sub_99F8.
sub_8524:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET

; data_852E
data_852E:
  DEFB $AA,$85,$B9,$85,$E0,$85,$4F,$86
  DEFB $71,$86,$81,$86,$AD,$86,$CC,$86
  DEFB $EC,$86,$0C,$87,$2C,$87,$44,$87
  DEFB $90,$87,$9C,$87,$D5,$87,$ED,$87
  DEFB $22,$88,$47,$88,$7E,$88,$7E,$88
  DEFB $8F,$88,$A0,$88,$D9,$88,$DC,$88
  DEFB $24,$89,$48,$89,$66,$89,$8E,$89
  DEFB $B6,$89,$CA,$89,$07,$8A,$1D,$8A
  DEFB $42,$8A,$62,$8A,$6D,$8A,$75,$8A
  DEFB $85,$8A,$9D,$8A,$BF,$8A,$07,$8B
  DEFB $0A,$8B,$30,$8B,$57,$8B,$AC,$8B
  DEFB $BF,$8B,$DA,$8B,$F5,$8B,$10,$8C
  DEFB $2D,$8C,$3D,$8C,$4E,$8C,$57,$8C
  DEFB $85,$8C,$CD,$8C,$F3,$8C,$3B,$8D
  DEFB $46,$8D,$65,$8D,$85,$8D,$A5,$8D
  DEFB $C5,$8D,$DD,$8D,$E6,$B8,$DA,$DD
  DEFB $00,$D5,$01,$02,$AC,$DD,$03,$D5
  DEFB $04,$05,$FF,$E6,$B8,$DA,$DB,$06
  DEFB $07,$D3,$08,$09,$0A,$AA,$DD,$0B
  DEFB $0C,$D5,$0D,$0E,$0F,$AA,$E8,$02
  DEFB $DC,$10,$E8,$01,$DD,$11,$D5,$E8
  DEFB $11,$12,$E8,$01,$13,$E8,$02,$D4
  DEFB $14,$FF,$E6,$E8,$DB,$DE,$24,$25
  DEFB $25,$00,$01,$D9,$02,$D6,$03,$04
  DEFB $25,$25,$24,$A6,$DE,$05,$DC,$06
  DEFB $07,$D4,$08,$09,$0A,$D6,$0B,$A7
  DEFB $DE,$20,$DD,$0C,$DC,$0D,$0E,$D4
  DEFB $0F,$10,$11,$DD,$12,$DE,$22,$A6
  DEFB $DE,$21,$D5,$13,$DC,$14,$15,$D4
  DEFB $16,$17,$18,$D5,$19,$D6,$23,$A6
  DEFB $E8,$02,$DC,$E6,$B8,$DA,$10,$E8
  DEFB $01,$78,$01,$E6,$E8,$DB,$1A,$1B
  DEFB $D4,$1C,$1D,$1E,$78,$01,$E6,$B8
  DEFB $DA,$E8,$02,$14,$AA,$E6,$E8,$DB
  DEFB $E8,$01,$D4,$1F,$71,$FD,$DE,$27
  DEFB $AE,$26,$77,$03,$D6,$29,$AE,$28
  DEFB $FF,$E6,$38,$DD,$E8,$00,$EA,$D9
  DEFB $00,$01,$D1,$02,$03,$AB,$D9,$04
  DEFB $05,$D1,$06,$07,$AB,$D9,$08,$09
  DEFB $D1,$0A,$0B,$AB,$D9,$0C,$0D,$D1
  DEFB $0E,$0F,$FF,$E6,$38,$DD,$E8,$00
  DEFB $EA,$DA,$10,$D9,$11,$AD,$D2,$12
  DEFB $D1,$13,$FF,$E6,$D8,$DD,$E8,$03
  DEFB $DD,$12,$E8,$01,$13,$D6,$00,$77
  DEFB $00,$DB,$01,$02,$DC,$03,$AC,$D3
  DEFB $04,$05,$D4,$06,$AC,$D3,$07,$08
  DEFB $D4,$09,$AB,$DE,$0A,$0B,$D6,$0C
  DEFB $AC,$DE,$0D,$0E,$D6,$0F,$FF,$E6
  DEFB $D8,$DE,$D9,$0C,$D2,$0D,$D9,$0E
  DEFB $D2,$0F,$AB,$D2,$00,$D9,$01,$D2
  DEFB $02,$D9,$03,$AB,$D9,$10,$D2,$11
  DEFB $D9,$12,$D2,$13,$AB,$FF,$E6,$D8
  DEFB $DE,$D9,$D9,$0E,$D2,$0F,$D9,$0D
  DEFB $D2,$0C,$AB,$D2,$08,$D9,$09,$D2
  DEFB $0A,$D9,$0B,$AB,$D9,$11,$D2,$10
  DEFB $D9,$13,$D2,$12,$AB,$FF,$E6,$D8
  DEFB $DE,$D9,$D9,$0E,$D2,$0F,$D9,$0D
  DEFB $D2,$0C,$AB,$D2,$03,$D9,$02,$D2
  DEFB $01,$D9,$00,$AB,$D9,$12,$D2,$10
  DEFB $D9,$13,$D2,$11,$AB,$FF,$E6,$D8
  DEFB $DE,$DA,$D9,$0C,$D2,$0E,$D9,$0D
  DEFB $D2,$0F,$AB,$D2,$0B,$D9,$0A,$D2
  DEFB $09,$D9,$08,$AB,$D9,$13,$D2,$12
  DEFB $D9,$11,$D2,$10,$AB,$FF,$E1,$02
  DEFB $E3,$AD,$86,$78,$04,$E3,$CC,$86
  DEFB $78,$04,$E3,$EC,$86,$78,$04,$E3
  DEFB $0C,$87,$78,$04,$E2,$FF,$E6,$78
  DEFB $DF,$E9,$E8,$04,$D9,$0D,$78,$04
  DEFB $0D,$78,$04,$0D,$A4,$E8,$00,$DB
  DEFB $0A,$E4,$05,$0B,$D3,$E4,$04,$0B
  DEFB $0C,$A5,$E3,$77,$87,$78,$02,$DB
  DEFB $0E,$0F,$D3,$10,$11,$12,$E3,$77
  DEFB $87,$AB,$E8,$04,$D9,$13,$13,$13
  DEFB $FF,$DD,$08,$D5,$09,$AD,$E1,$05
  DEFB $DB,$00,$D3,$01,$AD,$E2,$DB,$02
  DEFB $D3,$03,$AC,$DB,$04,$05,$D3,$06
  DEFB $07,$FF,$E6,$B8,$DA,$DD,$E8,$05
  DEFB $1B,$E8,$01,$D5,$1C,$FF,$E6,$18
  DEFB $E0,$DD,$00,$D5,$01,$AC,$DD,$02
  DEFB $03,$D5,$04,$05,$AB,$DD,$06,$07
  DEFB $D5,$08,$09,$AB,$DD,$0A,$0B,$D5
  DEFB $0C,$0D,$AB,$DD,$0E,$0F,$D5,$10
  DEFB $11,$AB,$DD,$12,$13,$D5,$14,$15
  DEFB $AB,$DD,$16,$17,$D5,$18,$19,$AA
  DEFB $DD,$1E,$1A,$1B,$1C,$1D,$FF,$E1
  DEFB $02,$E3,$0C,$87,$78,$04,$E3,$EC
  DEFB $86,$78,$04,$E3,$CC,$86,$78,$04
  DEFB $E3,$AD,$86,$78,$04,$E2,$FF,$E6
  DEFB $10,$E1,$DE,$00,$D6,$01,$02,$03
  DEFB $04,$AA,$DE,$05,$D6,$06,$07,$08
  DEFB $09,$AA,$DE,$0A,$D6,$0B,$0C,$0D
  DEFB $0E,$AB,$DE,$0F,$D6,$10,$11,$AD
  DEFB $12,$AD,$DE,$13,$D6,$14,$15,$AC
  DEFB $DE,$16,$D6,$17,$18,$AC,$DE,$16
  DEFB $D6,$19,$18,$FF,$E6,$10,$E1,$DE
  DEFB $1A,$D6,$1B,$AD,$DE,$1C,$D6,$1D
  DEFB $AD,$DE,$1E,$D6,$1F,$AC,$DE,$20
  DEFB $21,$D6,$22,$23,$AC,$DE,$24,$D6
  DEFB $25,$26,$AC,$DE,$27,$D6,$28,$29
  DEFB $FF,$E6,$60,$E2,$DC,$00,$01,$D4
  DEFB $02,$03,$AB,$04,$DC,$E8,$06,$05
  DEFB $E8,$01,$D4,$06,$04,$AB,$E8,$04
  DEFB $07,$AE,$E8,$00,$DC,$04,$AE,$E8
  DEFB $04,$07,$76,$02,$07,$AE,$D4,$E8
  DEFB $00,$04,$AE,$E8,$04,$07,$AB,$E8
  DEFB $00,$DC,$08,$09,$D4,$0A,$0B,$FF
  DEFB $E6,$C0,$E2,$E8,$07,$DE,$00,$E8
  DEFB $00,$D6,$01,$AD,$DE,$02,$D6,$03
  DEFB $FF,$E6,$C0,$E2,$E8,$08,$DD,$00
  DEFB $E8,$00,$D5,$01,$AD,$DD,$02,$D5
  DEFB $03,$FF,$E6,$E0,$E2,$DC,$00,$01
  DEFB $D4,$02,$03,$AB,$DC,$04,$E8,$09
  DEFB $D9,$E7,$E8,$00,$E7,$E8,$01,$D4
  DEFB $05,$AB,$DC,$06,$E8,$00,$D9,$E7
  DEFB $E7,$E8,$01,$D4,$07,$AB,$DC,$08
  DEFB $09,$D4,$0A,$0B,$AB,$DD,$0C,$0D
  DEFB $D5,$0E,$0F,$AB,$DD,$10,$11,$D5
  DEFB $12,$13,$FF,$EB,$0A,$FF,$E6,$80
  DEFB $E3,$DB,$00,$01,$02,$06,$07,$00
  DEFB $02,$06,$07,$00,$01,$01,$02,$06
  DEFB $07,$00,$01,$02,$06,$07,$00,$02
  DEFB $00,$01,$02,$06,$07,$06,$07,$00
  DEFB $01,$02,$79,$E0,$D3,$03,$04,$05
  DEFB $08,$09,$03,$05,$08,$09,$03,$04
  DEFB $04,$05,$08,$09,$03,$04,$05,$08
  DEFB $09,$03,$05,$03,$04,$05,$08,$09
  DEFB $08,$09,$03,$04,$05,$FF,$E6,$80
  DEFB $E3,$E8,$00,$DE,$0A,$D6,$0B,$0C
  DEFB $AC,$DE,$0D,$D6,$0E,$0F,$AC,$DE
  DEFB $10,$D6,$11,$12,$AC,$DE,$13,$D6
  DEFB $14,$15,$AC,$DE,$16,$D6,$17,$18
  DEFB $AC,$FF,$E6,$78,$DF,$E8,$00,$DD
  DEFB $08,$D5,$09,$AD,$E1,$04,$DB,$00
  DEFB $D3,$01,$AD,$E2,$DB,$02,$D3,$03
  DEFB $AC,$DB,$04,$05,$D3,$06,$07,$FF
  DEFB $E6,$48,$E4,$E8,$0B,$DB,$09,$E8
  DEFB $0E,$DE,$0A,$E8,$00,$D3,$0B,$DD
  DEFB $0C,$AB,$DB,$E8,$0B,$09,$E8,$0E
  DEFB $DE,$0A,$E8,$00,$D3,$0B,$D5,$0D
  DEFB $AB,$DD,$0E,$D5,$0F,$10,$11,$FF
  DEFB $E6,$80,$E3,$E8,$00,$DA,$0A,$D2
  DEFB $0B,$D9,$0C,$AC,$DA,$0D,$D2,$0E
  DEFB $D9,$0F,$AC,$DA,$10,$D2,$11,$D9
  DEFB $12,$AC,$DA,$13,$D2,$14,$D9,$15
  DEFB $AC,$DA,$16,$D2,$17,$D9,$18,$FF
  DEFB $E6,$D8,$E4,$DD,$00,$D5,$01,$02
  DEFB $AC,$DD,$03,$D5,$04,$05,$AD,$E8
  DEFB $02,$D9,$06,$FF,$E6,$D8,$E4,$DA
  DEFB $E8,$0C,$07,$E8,$01,$08,$D2,$09
  DEFB $AD,$E8,$00,$DA,$0A,$AE,$0B,$AE
  DEFB $0B,$AE,$0C,$AC,$E8,$01,$0D,$0E
  DEFB $0F,$D2,$10,$11,$AB,$DA,$12,$D2
  DEFB $13,$14,$73,$FC,$EA,$E8,$00,$DE
  DEFB $15,$AE,$16,$AE,$17,$AE,$18,$75
  DEFB $03,$19,$AE,$1A,$AE,$1B,$AE,$1C
  DEFB $FF,$E6,$48,$E4,$EA,$E8,$00,$DB
  DEFB $00,$D3,$01,$02,$AC,$DB,$03,$D3
  DEFB $04,$05,$AC,$06,$07,$08,$FF,$E6
  DEFB $00,$E6,$E8,$0D,$DE,$00,$E8,$01
  DEFB $01,$D6,$02,$03,$AC,$DE,$04,$D6
  DEFB $05,$AC,$DE,$06,$DB,$07,$D3,$08
  DEFB $D6,$09,$AB,$DE,$0A,$DB,$0B,$D3
  DEFB $0C,$D6,$0D,$FF,$E6,$00,$E6,$E8
  DEFB $00,$DE,$0E,$D6,$0F,$AD,$DE,$10
  DEFB $D6,$11,$AD,$DA,$12,$D2,$13,$AD
  DEFB $DA,$12,$D2,$13,$AC,$DA,$14,$12
  DEFB $D2,$13,$15,$FF,$E6,$40,$E8,$E1
  DEFB $10,$DD,$00,$D5,$01,$E2,$FF,$E6
  DEFB $40,$E8,$DD,$E5,$04,$02,$FF,$E6
  DEFB $38,$DD,$E8,$00,$EA,$DD,$10,$D5
  DEFB $11,$AD,$DD,$12,$D5,$13,$FF,$E6
  DEFB $48,$E4,$EA,$E8,$00,$DA,$00,$D2
  DEFB $01,$D9,$02,$AC,$DA,$03,$D2,$04
  DEFB $D9,$05,$AC,$06,$07,$08,$FF,$E6
  DEFB $38,$DD,$E8,$00,$EA,$DC,$00,$01
  DEFB $D4,$02,$03,$AB,$DC,$04,$05,$D4
  DEFB $06,$07,$AB,$DC,$08,$09,$D4,$0A
  DEFB $0B,$AB,$DC,$0C,$0D,$D4,$0E,$0F
  DEFB $FF,$E6,$80,$E3,$DE,$00,$01,$02
  DEFB $06,$07,$00,$02,$06,$07,$00,$01
  DEFB $01,$02,$06,$07,$00,$01,$02,$06
  DEFB $07,$00,$02,$00,$01,$02,$06,$07
  DEFB $06,$07,$00,$01,$02,$79,$E0,$D6
  DEFB $03,$04,$05,$08,$09,$03,$05,$08
  DEFB $09,$03,$04,$04,$05,$08,$09,$03
  DEFB $04,$05,$08,$09,$03,$05,$03,$04
  DEFB $05,$08,$09,$08,$09,$03,$04,$05
  DEFB $FF,$EB,$09,$FF,$E6,$60,$E8,$D9
  DEFB $00,$01,$02,$D1,$03,$AB,$DB,$04
  DEFB $05,$05,$D3,$06,$AB,$DB,$07,$08
  DEFB $D3,$09,$0A,$AB,$DB,$0B,$0C,$D3
  DEFB $0D,$0E,$AB,$DE,$0F,$D6,$10,$11
  DEFB $12,$FF,$E6,$60,$E8,$D9,$13,$D2
  DEFB $14,$D9,$15,$AB,$D9,$16,$D2,$17
  DEFB $D9,$18,$D2,$19,$D9,$1A,$D2,$1B
  DEFB $A9,$E6,$D8,$DE,$D2,$00,$D9,$01
  DEFB $D2,$02,$D9,$03,$D2,$04,$D9,$05
  DEFB $FF,$E6,$40,$E9,$E3,$75,$8B,$78
  DEFB $02,$EB,$0F,$78,$04,$E3,$75,$8B
  DEFB $86,$FC,$E8,$01,$DC,$10,$11,$D4
  DEFB $12,$13,$73,$FD,$EB,$10,$FF,$E8
  DEFB $00,$DD,$00,$D5,$01,$AD,$DD,$02
  DEFB $D5,$03,$AD,$DE,$04,$D6,$05,$AD
  DEFB $DE,$06,$D4,$07,$AD,$DB,$08,$D3
  DEFB $09,$AD,$DB,$0A,$D3,$0B,$AD,$DA
  DEFB $0C,$D2,$0D,$AD,$E1,$06,$DA,$0E
  DEFB $D2,$0F,$AD,$E2,$DA,$14,$D2,$15
  DEFB $AD,$DA,$16,$D2,$17,$FF,$E6,$40
  DEFB $E9,$E8,$04,$E0,$03,$18,$AE,$E8
  DEFB $00,$DB,$19,$AD,$1A,$D3,$1B,$1C
  DEFB $FF,$E6,$D8,$DD,$E8,$03,$DD,$12
  DEFB $E8,$01,$13,$E6,$28,$EA,$DE,$00
  DEFB $01,$D6,$02,$03,$AA,$DB,$04,$05
  DEFB $D3,$06,$07,$FF,$E6,$28,$EA,$DD
  DEFB $E8,$0B,$08,$E8,$0E,$D5,$09,$DB
  DEFB $0A,$0B,$D3,$E8,$00,$0C,$0D,$AB
  DEFB $DD,$0E,$0F,$D5,$0F,$10,$FF,$E6
  DEFB $F0,$EA,$DB,$00,$01,$D3,$02,$AC
  DEFB $DB,$03,$04,$D3,$05,$AC,$DB,$06
  DEFB $D3,$07,$08,$AC,$DB,$09,$D3,$0A
  DEFB $0B,$FF,$E6,$F0,$EA,$E8,$00,$DD
  DEFB $0C,$D5,$0D,$0E,$AC,$DD,$0F,$D5
  DEFB $10,$11,$AC,$DD,$0F,$D5,$10,$11
  DEFB $AC,$DD,$12,$D5,$13,$14,$FF,$E6
  DEFB $F0,$EA,$EA,$DE,$15,$D6,$16,$AC
  DEFB $DE,$17,$D6,$18,$AD,$19,$FF,$E6
  DEFB $F0,$EA,$EA,$DE,$1A,$D6,$1B,$AE
  DEFB $DE,$1C,$D6,$1D,$AE,$DE,$1E,$FF
  DEFB $E1,$04,$E3,$10,$8C,$7C,$00,$E2
  DEFB $FF,$E6,$E8,$EB,$E3,$67,$8C,$7C
  DEFB $02,$EB,$0F,$74,$04,$E3,$67,$8C
  DEFB $FF,$DD,$00,$D5,$01,$AD,$DD,$02
  DEFB $D5,$03,$AD,$DE,$04,$DC,$05,$AD
  DEFB $DE,$06,$DC,$07,$AD,$DC,$08,$D4
  DEFB $09,$AD,$DC,$0A,$D4,$0B,$FF,$E6
  DEFB $48,$EC,$DD,$00,$01,$02,$06,$07
  DEFB $00,$02,$06,$07,$00,$01,$01,$02
  DEFB $06,$07,$00,$01,$02,$06,$07,$00
  DEFB $02,$00,$01,$02,$06,$07,$06,$07
  DEFB $00,$01,$02,$79,$E0,$D5,$03,$04
  DEFB $05,$08,$09,$03,$05,$08,$09,$03
  DEFB $04,$04,$05,$08,$09,$03,$04,$05
  DEFB $08,$09,$03,$05,$03,$04,$05,$08
  DEFB $09,$08,$09,$03,$04,$05,$FF,$E6
  DEFB $48,$EC,$E8,$00,$DC,$0A,$0B,$D4
  DEFB $0C,$AC,$DC,$0D,$78,$01,$D4,$0E
  DEFB $AC,$DC,$0D,$D6,$12,$D4,$0E,$AC
  DEFB $DC,$0D,$78,$01,$D4,$0E,$AC,$DC
  DEFB $0F,$D4,$10,$11,$FF,$E6,$48,$EC
  DEFB $DB,$00,$01,$02,$06,$07,$00,$02
  DEFB $06,$07,$00,$01,$01,$02,$06,$07
  DEFB $00,$01,$02,$06,$07,$00,$02,$00
  DEFB $01,$02,$06,$07,$06,$07,$00,$01
  DEFB $02,$79,$E0,$D3,$03,$04,$05,$08
  DEFB $09,$03,$05,$08,$09,$03,$04,$04
  DEFB $05,$08,$09,$03,$04,$05,$08,$09
  DEFB $03,$05,$03,$04,$05,$08,$09,$08
  DEFB $09,$03,$04,$05,$FF,$E6,$40,$E8
  DEFB $E1,$02,$DD,$00,$D5,$01,$E2,$FF
  DEFB $E6,$D8,$DE,$DC,$0C,$DB,$0D,$DC
  DEFB $0E,$DB,$0F,$AB,$DB,$00,$DC,$01
  DEFB $DB,$02,$DC,$03,$AB,$DC,$10,$DB
  DEFB $11,$DC,$12,$DB,$13,$AB,$FF,$E6
  DEFB $D8,$DE,$DC,$DC,$0E,$DB,$0F,$DC
  DEFB $0D,$DB,$0C,$AB,$DB,$08,$DC,$09
  DEFB $DB,$0A,$DC,$0B,$AB,$DC,$11,$DB
  DEFB $10,$DC,$13,$DB,$12,$AB,$FF,$E6
  DEFB $D8,$DE,$DC,$DC,$0E,$DB,$0F,$DC
  DEFB $0D,$DB,$0C,$AB,$DB,$03,$DC,$02
  DEFB $DB,$01,$DC,$00,$AB,$DC,$12,$DB
  DEFB $10,$DC,$13,$DB,$11,$AB,$FF,$E6
  DEFB $D8,$DE,$DB,$DC,$0C,$DB,$0E,$DC
  DEFB $0D,$DB,$0F,$AB,$DB,$0B,$DC,$0A
  DEFB $DB,$09,$DC,$08,$AB,$DC,$13,$DB
  DEFB $12,$DC,$11,$DB,$10,$AB,$FF,$E1
  DEFB $02,$E3,$46,$8D,$78,$04,$E3,$65
  DEFB $8D,$78,$04,$E3,$85,$8D,$78,$04
  DEFB $E3,$A5,$8D,$78,$04,$E2,$FF,$E1
  DEFB $02,$E3,$A5,$8D,$78,$04,$E3,$85
  DEFB $8D,$78,$04,$E3,$65,$8D,$78,$04
  DEFB $E3,$46,$8D,$78,$04,$E2,$FF

; sub_8DF5
;
; Used by the routines at l_6DA1, l_6FAB and sub_8494.
sub_8DF5:
  LD HL,$6100
  LD DE,$6101
  LD BC,$02BF
  LD (HL),$00
  LDIR
  RET

; sub_8E03
;
; Used by the routines at l_6DA1, l_6FAB and sub_8494.
sub_8E03:
  LD HL,$5B00
  LD DE,$5B01
  LD BC,$02BF
  LD (HL),$FF
  LDIR
  RET

; sub_8E11
;
; Used by the routines at l_6DA1, l_6FAB and sub_8494.
sub_8E11:
  LD DE,$5E00
  LD HL,$5800
  LD BC,$0300
  LDIR
  RET

; l_8E1D
;
; Used by the routines at sub_8E4F and sub_8E5B.
l_8E1D:
  PUSH BC
  PUSH HL
  LD HL,data_C7F4+$0FEC
  LD (sub_ADE1+$000E),HL
  LD B,$64
  CALL sub_8E37
  LD B,$0A
  CALL sub_8E37
  LD B,$01
  CALL sub_8E37
  POP HL
  POP BC
  RET

; sub_8E37
;
; Used by the routine at l_8E1D.
sub_8E37:
  LD L,$00
l_8E39:
  SUB B
  JR C,l_8E3F
  INC L
  JR l_8E39
l_8E3F:
  ADD A,B
  PUSH AF
  LD A,B
  CP $64
  JR Z,l_8E4D
  LD A,L
  ADD A,$30
  CALL sub_AE26
  INC E
l_8E4D:
  POP AF
  RET

; sub_8E4F
;
; Used by the routines at sub_7690, sub_8338, sub_9942 and sub_9CE3.
sub_8E4F:
  LD A,(data_8E5A)
  LD DE,$1701
  LD C,$47
  JP l_8E1D

; data_8E5A
data_8E5A:
  DEFB $63

; sub_8E5B
;
; Used by the routines at sub_7690, l_9237, sub_9942 and sub_9CE3.
sub_8E5B:
  LD A,(data_8E66)
  LD DE,$1708
  LD C,$43
  JP l_8E1D

; data_8E66
data_8E66:
  DEFB $0A

; sub_8E67
;
; Used by the routines at sub_7690 and sub_9CE3.
sub_8E67:
  LD A,(data_8E7A)
  ADD A,$30
  LD DE,$1717
  LD C,$46
  LD HL,data_C7F4+$0FEC
  LD (sub_ADE1+$000E),HL
  JP sub_AE26

; data_8E7A
data_8E7A:
  DEFB $09

; sub_8E7B
;
; Used by the routines at sub_7690 and sub_8485.
sub_8E7B:
  LD A,(data_8523)
  LD DE,$171C
  LD C,$46
  JP l_B0C6

; sub_8E86
;
; Used by the routine at sub_8494.
sub_8E86:
  LD HL,data_8EF4
  LD B,$10
l_8E8B:
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,$FF
  LD (DE),A
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  INC HL
  INC HL
  DJNZ l_8E8B
  LD HL,$6100
  LD BC,$02C0
l_8EA0:
  LD A,(HL)
  CP $02
  CALL NC,sub_8EAD
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_8EA0
  RET

; sub_8EAD
;
; Used by the routine at sub_8E86.
sub_8EAD:
  PUSH BC
  PUSH HL
  EX AF,AF'
  LD DE,l_9EF1+$000F
  ADD HL,DE
  LD A,L
  AND $1F
  LD E,A
  LD A,L
  SRL H
  RRA
  SRL H
  RRA
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  EX AF,AF'
  LD L,A
  LD H,$00
  ADD HL,HL
  LD B,H
  LD C,L
  ADD HL,HL
  ADD HL,BC
  LD BC,$8EE8
  ADD HL,BC
  PUSH HL
  POP IX
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD (HL),E
  INC HL
  LD (HL),D
  LD C,(IX+$04)
  LD B,$00
  DEC C
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  LD (HL),$FF
  POP HL
  LD A,(IX+$05)
  LD (HL),A
  POP BC
  RET

; data_8EF4
data_8EF4:
  DEFB $89,$8F,$00,$00,$02,$00,$22,$90
  DEFB $00,$00,$03,$03,$35,$91,$00,$00
  DEFB $02,$00,$B0,$91,$00,$00,$03,$01
  DEFB $30,$99,$00,$00,$02,$01,$F2,$99
  DEFB $00,$00,$02,$00,$F5,$99,$00,$00
  DEFB $02,$00,$4B,$9B,$00,$00,$02,$00
  DEFB $70,$9C,$00,$00,$03,$01,$C1,$9D
  DEFB $00,$00,$02,$00,$6E,$9F,$00,$00
  DEFB $02,$01,$66,$A2,$00,$00,$02,$0D
  DEFB $33,$A3,$00,$00,$03,$00,$14,$A8
  DEFB $00,$00,$02,$00,$EF,$AA,$00,$00
  DEFB $02,$00,$CC,$AB,$00,$00,$02,$01

; sub_8F54
;
; Used by the routine at l_758A.
sub_8F54:
  LD HL,data_C7F4+$12C4
  LD (sub_ADE1+$000E),HL
  LD A,(data_8F89+$000B)
  INC A
  CP $03
  JR NZ,l_8F63
  XOR A
l_8F63:
  LD (data_8F89+$000B),A
  ADD A,A
  ADD A,$15
  LD HL,data_8F89
l_8F6C:
  BIT 7,(HL)
  RET NZ
  EX AF,AF'
  CALL sub_AD36
  AND $07
  OR $42
  LD C,A
  EX AF,AF'
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC D
  INC HL
  CALL sub_AE26
  INC D
  INC A
  CALL sub_AE26
  DEC A
  JR l_8F6C

; data_8F89
data_8F89:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$FF,$00

; sub_8F95
;
; Used by the routine at l_758A.
sub_8F95:
  LD HL,data_C7F4+$15E4
  LD (sub_ADE1+$000E),HL
  LD HL,data_9019+$0009
l_8F9E:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_900D
  PUSH HL
  CALL sub_8097
  LD BC,$6100
  ADD HL,BC
  LD A,(HL)
  CP $03
  POP HL
  JR Z,l_8FD5
  PUSH HL
  LD A,(HL)
  LD (HL),$00
  CALL sub_9010
  LD C,$00
  CALL sub_AE5D
  INC A
  INC E
  CALL sub_AE5D
  LD A,$13
  CALL sub_AE5D
  DEC A
  DEC E
  CALL sub_AE5D
  POP HL
  JR l_900D
l_8FD5:
  LD A,(HL)
  CP $01
  JR NZ,l_8FEC
  CALL sub_AD36
  CP $FA
  JR C,l_900D
  LD (HL),$09
  LD C,$FF
  PUSH HL
  CALL sub_9071
  POP HL
  JR l_900D
l_8FEC:
  PUSH HL
  DEC (HL)
  CALL sub_9010
  LD C,$46
  CALL sub_AE5D
  INC A
  INC E
  LD C,$06
  CALL sub_AE5D
  DEC E
  DEC HL
  LD A,(HL)
  LD C,$46
  CALL sub_AE5D
  INC A
  INC E
  LD C,$06
  CALL sub_AE5D
  POP HL
l_900D:
  INC HL
  JR l_8F9E

; sub_9010
;
; Used by the routine at sub_8F95.
sub_9010:
  LD L,A
  LD H,$00
  LD BC,$9018
  ADD HL,BC
  LD A,(HL)
  RET

; data_9019
data_9019:
  DEFB $10,$12,$14,$16,$18,$1A,$1C,$1E
  DEFB $10,$00,$00,$02,$00,$00,$02,$00
  DEFB $00,$02,$00,$00,$02,$FF

; sub_902F
;
; Used by the routine at sub_8494.
sub_902F:
  LD HL,data_9019+$0009
  LD DE,data_9019+$000A
  LD (HL),$02
  LD BC,$000B
  LDIR
  RET

; sub_903D
;
; Used by the routines at sub_9071, sub_90A2 and sub_90EA.
sub_903D:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL sub_B088
  LD A,E
  AND $03
  INC A
  LD B,A
  LD A,$03
l_904B:
  RRCA
  RRCA
  DJNZ l_904B
  LD B,A
  XOR (HL)
  LD (HL),A
  INC H
  LD A,B
  XOR (HL)
  LD (HL),A
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD BC,$5E00
  ADD HL,BC
  LD A,(HL)
  DEC L
  OR (HL)
  JR NZ,l_906C
  LD BC,$FA00
  ADD HL,BC
  LD (HL),$47
l_906C:
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; sub_9071
;
; Used by the routine at sub_8F95.
sub_9071:
  LD HL,data_90CB
l_9074:
  BIT 7,(HL)
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_9080
  INC HL
  JR l_9074
l_9080:
  LD (HL),C
  DEC HL
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  INC A
  INC A
  INC A
  LD D,A
  LD (HL),A
  DEC HL
  LD A,E
  ADD A,A
  ADD A,A
  LD E,A
  LD (HL),A
  CALL sub_903D
  LD B,$0A
l_9096:
  PUSH BC
  LD B,$1E
  CALL sub_7C26
  POP BC
  DJNZ l_9096
  JP sub_C148

; sub_90A2
;
; Used by the routine at l_758A.
sub_90A2:
  LD HL,data_90CB
l_90A5:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_90A5
  CALL sub_903D
  ADD A,E
  LD E,A
  CP $7F
  JR C,l_90C0
  DEC HL
  LD (HL),$00
  INC HL
  JR l_90A5
l_90C0:
  PUSH HL
  DEC HL
  DEC HL
  DEC HL
  LD (HL),E
  POP HL
  CALL sub_903D
  JR l_90A5

; data_90CB
data_90CB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$FF

; sub_90EA
;
; Used by the routine at l_758A.
sub_90EA:
  LD HL,data_90CB
l_90ED:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_90ED
  LD BC,$0000
  CALL sub_9BD6
  OR A
  JR Z,l_90ED
  CALL sub_903D
  DEC HL
  LD (HL),$00
  JP sub_9CAF

; sub_910B
;
; Used by the routine at sub_8494.
sub_910B:
  LD HL,data_90CB
  LD DE,data_90CB+$0001
  LD BC,$001D
  LD (HL),B
  LDIR
  RET

; sub_9118
;
; Used by the routine at l_758A.
sub_9118:
  LD HL,data_9135
l_911B:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  CALL sub_8097
  LD DE,$5800
  ADD HL,DE
  LD A,(data_768C)
  AND $07
  OR $40
  LD (HL),A
  POP HL
  JR l_911B

; data_9135
data_9135:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$FF

; sub_9152
;
; Used by the routine at l_758A.
sub_9152:
  LD HL,data_C7F4+$12C4
  LD (sub_ADE1+$000E),HL
  LD A,(data_91AF)
  XOR $02
  LD (data_91AF),A
  LD HL,data_91AF+$0001
l_9163:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  DEC A
  JR Z,l_9186
  CALL sub_AD36
  AND $07
  OR $42
  LD C,A
  LD A,(data_91AF)
  ADD A,$1D
  CALL sub_ADE1
  INC A
  INC E
  CALL sub_ADE1
  JR l_9163
l_9186:
  LD B,D
  LD C,E
  CALL sub_9936
  DEC D
  LD A,(data_82F2+$0004)
  ADD A,$1F
  CP D
  JR NZ,l_9163
  LD A,(data_82F2+$0003)
  ADD A,$06
  SUB E
  SUB $09
  CP $F6
  JR C,l_9163
  DEC HL
  LD (HL),$00
  LD D,B
  LD E,C
  DEC D
  CALL sub_91CF
  CALL sub_C148
  JP l_9CAA

; data_91AF
data_91AF:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF

; sub_91CF
;
; Used by the routine at sub_9152.
sub_91CF:
  LD A,$03
  CALL sub_99F8
  INC D
  INC D
  CALL sub_8097
  DEC D
  DEC D
  LD BC,$5800
  ADD HL,BC
  LD A,(HL)
  LD (data_91ED+$0004),A
  LD HL,data_91ED
  CALL sub_AF2B
  XOR A
  JP sub_99F8

; data_91ED
data_91ED:
  DEFB $E6,$E0,$D7,$E0,$05,$E1,$05,$20
  DEFB $20,$78,$FE,$E2,$FF

; sub_91FA
;
; Used by the routine at sub_8494.
sub_91FA:
  LD HL,data_91AF+$0001
  LD DE,data_91AF+$0002
  LD (HL),$01
  LD BC,$001D
  LDIR
  RET

; sub_9208
;
; Used by the routine at l_758A.
sub_9208:
  CALL sub_9D78
  LD A,(data_82F2+$0003)
  CP $76
  RET NC
  LD A,(data_8E66)
  OR A
  RET Z
  LD A,(data_83DC)
  CP $0F
  RET C
  LD A,(data_925A)
  OR A
  RET NZ
  LD A,$20
  LD (data_925A),A
  LD HL,(data_82F2+$0003)
  LD A,L
  ADD A,$04
  LD L,A
  LD A,(data_82F2+$0009)
  OR A
  JR Z,l_9237

; data_9233
data_9233:
  DEFB $7C,$C6,$06,$67

; l_9237
;
; Used by the routine at sub_9208.
l_9237:
  LD (data_925A+$0001),HL
  LD A,(data_82F2+$0008)
  LD (data_925A+$0003),A
  EX DE,HL
  INC A
  LD A,$01
  JR Z,l_9247
  XOR A
l_9247:
  LD (data_925A+$0004),A
  CALL sub_92FB
  LD A,(data_8E66)
  DEC A
  LD (data_8E66),A
  CALL sub_C1BE
  JP sub_8E5B

; data_925A
data_925A:
  DEFB $00,$00,$00,$00,$00

; sub_925F
;
; Used by the routine at l_758A.
sub_925F:
  LD A,(data_925A)
  OR A
  RET Z
  LD C,A
  LD B,$00
  LD HL,l_92D4+$0006
  ADD HL,BC
  DEC A
  JR Z,l_9271
  LD (data_925A),A
l_9271:
  LD DE,(data_925A+$0001)
  LD A,(data_925A+$0004)
  CALL sub_92FB
  LD A,E
  CP $7C
  JR Z,l_92D4
  OR A
  JR Z,l_92D4
  LD A,(data_925A+$0003)
  LD B,A
  INC A
  JR NZ,l_9291

; data_928A
data_928A:
  DEFB $CD,$82,$93,$20,$45,$18,$05

; l_9291
;
; Used by the routine at sub_925F.
l_9291:
  CALL sub_9362
  JR NZ,l_92D4
  LD A,B
  ADD A,E
  LD E,A
  LD (data_925A+$0001),A
  LD A,(data_925A+$0002)
  LD D,A
  LD A,(HL)
  CP $FF
  JR NC,l_92AA
  CALL sub_93A2
  JR NZ,l_92D4
l_92AA:
  LD A,(HL)
  ADD A,D
  LD D,A
  CP $A8
  JR NC,l_92D4
  LD (data_925A+$0002),A
  LD A,(data_925A+$0004)
  LD C,$47
  CALL sub_7C77
  CALL sub_92FB
  LD A,(data_925A+$0003)
  INC A
  LD A,$04
  JR Z,l_92C9
  NEG
l_92C9:
  ADD A,E
  LD E,A
  LD A,(data_925A)
  CP $13
  JP NC,sub_981D
  RET
; This entry point is used by the routine at sub_925F.
l_92D4:
  XOR A
  LD (data_925A),A
  JP l_93E2

; data_92DB
data_92DB:
  DEFB $01,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF
  DEFB $FF,$FF,$FF,$FE,$FE,$FE,$FC,$FC

; sub_92FB
;
; Used by the routines at l_9237, sub_925F, l_9291, sub_94F9, sub_955D,
; sub_9835, l_9A26, l_9A7F, sub_9B07, sub_9B6B, l_9DA8, sub_9DD6, sub_9E4F and
; sub_9E85.
sub_92FB:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL sub_B088
  PUSH HL
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,E
  AND $03
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD BC,$ED40
  ADD HL,BC
  POP DE
  LD (data_78CA+$0010),SP
  LD SP,HL
  EX DE,HL
  LD BC,$0407
l_9325:
  POP DE
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  INC H
  LD A,H
  AND C
  JR NZ,l_933C
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_933C
  LD A,H
  SUB $08
  LD H,A
l_933C:
  POP DE
  LD A,D
  XOR (HL)
  LD (HL),A
  DEC L
  LD A,E
  XOR (HL)
  LD (HL),A
  INC H
  LD A,H
  AND C
  JR NZ,l_9353
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_9353
  LD A,H
  SUB $08
  LD H,A
l_9353:
  DJNZ l_9325
  LD SP,(data_78CA+$0010)
  LD HL,data_9E98
  INC (HL)
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; sub_9362
;
; Used by the routines at sub_83DD, l_9291 and l_9A26.
sub_9362:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  AND $03
  LD A,$00
  JR NZ,l_937D
  CALL sub_80C1
  INC L
  LD BC,$0020
  LD A,(HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,l_937D
  ADD HL,BC
  OR (HL)
l_937D:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; sub_9382
;
; Used by the routines at sub_83DD and l_9A26.
sub_9382:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  AND $03
  LD A,$00
  JR NZ,l_939D
  CALL sub_80C1
  DEC L
  LD BC,$0020
  LD A,(HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,l_939D
  ADD HL,BC
  OR (HL)
l_939D:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; sub_93A2
;
; Used by the routines at l_9291 and l_9A26.
sub_93A2:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,l_93BD
  CALL sub_80C1
  LD BC,$0020
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,l_93BD
  INC L
  OR (HL)
l_93BD:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; sub_93C2
;
; Used by the routine at l_9A26.
sub_93C2:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,l_93DD
  CALL sub_80C1
  LD BC,$FFE0
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,l_93DD
  INC L
  OR (HL)
l_93DD:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; l_93E2
;
; Used by the routine at l_9291.
l_93E2:
  LD A,E
  AND $7C
  RRCA
  RRCA
  LD E,A
  LD A,D
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  LD HL,data_9437
l_93F2:
  LD A,(HL)
  CP $FF
  RET Z
  CP $80
  PUSH HL
  JR Z,l_9430
  LD A,E
  CP (HL)
  INC HL
  JR C,l_9430
  CP (HL)
  INC HL
  JR NC,l_9430
  LD A,D
  CP (HL)
  INC HL
  JR C,l_9430
  CP (HL)
  INC HL
  JR NC,l_9430
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD BC,data_852E
  CALL sub_8524
  LD A,$03
  CALL sub_99F8
  CALL sub_AF2B
  XOR A
  CALL sub_99F8
  POP HL
  LD (HL),$80
  CALL sub_C148
  LD DE,data_AD82+$002C
  JP sub_AD53
l_9430:
  POP HL
  LD BC,$0007
  ADD HL,BC
  JR l_93F2

; data_9437
data_9437:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; sub_9487
;
; Used by the routine at sub_8494.
sub_9487:
  PUSH AF
  PUSH BC
  PUSH HL
  LD HL,data_94C6
l_948D:
  BIT 7,(HL)
  JR NZ,l_949A
  CP (HL)
  JR Z,l_949E
  LD BC,$0005
  ADD HL,BC
  JR l_948D
l_949A:
  POP HL
  POP BC
  POP AF
  RET
l_949E:
  LD (IX+$06),A
  LD (IX+$04),E
  LD (IX+$05),D
  INC HL
  LD A,(HL)
  ADD A,E
  LD (IX+$00),A
  INC HL
  ADD A,(HL)
  LD (IX+$01),A
  INC HL
  LD A,(HL)
  ADD A,D
  LD (IX+$02),A
  INC HL
  ADD A,(HL)
  LD (IX+$03),A
  LD BC,$0007
  ADD IX,BC
  POP HL
  POP BC
  POP AF
  RET

; data_94C6
data_94C6:
  DEFB $05,$FF,$08,$FE,$05,$0D,$FD,$05
  DEFB $FE,$0A,$0F,$FE,$07,$FF,$09,$10
  DEFB $FE,$06,$FE,$08,$12,$FA,$0B,$01
  DEFB $07,$15,$FE,$07,$FE,$08,$1F,$FF
  DEFB $06,$FE,$06,$28,$FF,$06,$FE,$08
  DEFB $2C,$FF,$08,$FE,$04,$2E,$FF,$05
  DEFB $FE,$06,$FF

; sub_94F9
;
; Used by the routine at l_AE95.
sub_94F9:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  LD BC,$0006
  LD HL,data_95B6
l_9503:
  LD A,(HL)
  OR A
  JR Z,l_950E
  CP $FF
  JR Z,l_9543
  ADD HL,BC
  JR l_9503
l_950E:
  LD (HL),$01
  INC HL
  LD A,E
  RLCA
  RLCA
  LD E,A
  LD (HL),E
  INC HL
  LD A,D
  RLCA
  RLCA
  RLCA
  LD D,A
  LD (HL),D
  INC HL
  CALL sub_AD36
  AND $07
  CALL sub_9548
  LD (HL),A
  LD C,A
  INC HL
l_9529:
  CALL sub_AD36
  AND $07
  CALL sub_9548
  ADD A,A
  LD B,A
  OR C
  JR Z,l_9529
  LD (HL),B
  LD A,$02
  CALL sub_92FB
  POP BC
  PUSH BC
  INC HL
  LD A,C
  AND $47
  LD (HL),A
l_9543:
  POP BC
  POP HL
  POP DE
  POP AF
  RET

; sub_9548
;
; Used by the routine at sub_94F9.
sub_9548:
  PUSH HL
  PUSH BC
  LD L,A
  LD H,$00
  LD BC,data_9555
  ADD HL,BC
  LD A,(HL)
  POP BC
  POP HL
  RET

; data_9555
data_9555:
  DEFB $FC,$FD,$FE,$00,$00,$02,$03,$04

; sub_955D
;
; Used by the routine at l_758A.
sub_955D:
  LD HL,data_95B6
l_9560:
  LD A,(HL)
  CP $FF
  RET Z
  CP $01
  JR Z,l_956E
  LD BC,$0006
  ADD HL,BC
  JR l_9560
l_956E:
  PUSH HL
  INC HL
  PUSH HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,$02
  CALL sub_92FB
  INC HL
  LD A,E
  ADD A,(HL)
  LD E,A
  CP $78
  JR NC,l_95AC
  INC HL
  LD A,D
  ADD A,(HL)
  LD D,A
  CP $A9
  JR NC,l_95AC
  INC HL
  LD C,(HL)
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  LD A,$02
  CALL sub_92FB
  CALL sub_7C77
  LD A,(data_6E16)
  OR A
  JR NZ,l_95A5
  LD A,E
  RLCA
  RLCA
  RLCA
  AND $F8
  OUT ($FE),A
l_95A5:
  POP HL
  LD BC,$0006
  ADD HL,BC
  JR l_9560
l_95AC:
  POP HL
  POP HL
  LD (HL),$00
  LD BC,$0006
  ADD HL,BC
  JR l_9560

; data_95B6
data_95B6:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF

; sub_980F
;
; Used by the routine at sub_8494.
sub_980F:
  LD HL,data_95B6
  LD DE,data_95B6+$0001
  LD BC,$0257
  LD (HL),$00
  LDIR
  RET

; sub_981D
;
; Used by the routines at sub_83DD, l_9291, sub_9B6B, sub_9E4F, sub_9EEE and
; sub_AC7D.
sub_981D:
  PUSH HL
  LD HL,data_9865+$000B
l_9821:
  BIT 7,(HL)
  JR NZ,l_9833
  INC HL
  INC HL
  LD A,(HL)
  OR A
  INC HL
  JR NZ,l_9821
  DEC HL
  LD (HL),$0A
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
l_9833:
  POP HL
  RET

; sub_9835
;
; Used by the routine at l_758A.
sub_9835:
  LD HL,data_9865+$000B
l_9838:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_9838
  PUSH HL
  DEC HL
  DEC (HL)
  LD L,A
  LD H,$00
  LD BC,$9864
  ADD HL,BC
  INC HL
  LD A,(HL)
  CALL sub_92FB
  DEC HL
  LD A,(HL)
  CALL sub_92FB
  LD A,R
  AND $07
  OR $42
  LD C,A
  CALL sub_7C77
  POP HL
  JR l_9838

; data_9865
data_9865:
  DEFB $06,$05,$05,$05,$04,$05,$03,$05
  DEFB $04,$03,$06,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF

; sub_98AD
;
; Used by the routine at sub_8494.
sub_98AD:
  LD HL,data_9865+$000B
  LD DE,data_9865+$000C
  LD BC,$003B
  LD (HL),B
  LDIR
  RET

; sub_98BA
;
; Used by the routine at l_758A.
sub_98BA:
  LD A,(data_7B92+$0002)
  OR A
  JR NZ,l_98C4
  LD (data_9930+$0005),A
  RET
l_98C4:
  LD A,(data_9930+$0005)
  OR A
  RET NZ
  INC A
  LD (data_9930+$0005),A
  LD DE,(data_9930)
  BIT 7,E
  RET NZ
  INC D
  CALL sub_9936
  LD A,(data_82F2+$0004)
  CP D
  JR NZ,l_9901
  LD A,(data_82F2+$0003)
  SUB E
  SUB $09
  CP $EB
  JR C,l_9901
  CALL sub_9ED9
  LD DE,(data_9930+$0002)
  INC D
  CALL sub_9936
  CALL sub_C162
  CALL sub_9ED9
  DEC E
  DEC E
  DEC E
  LD A,$05
  JP sub_8224
l_9901:
  LD DE,(data_9930+$0002)
  INC D
  CALL sub_9936
  LD A,(data_82F2+$0004)
  CP D
  RET NZ
  LD A,(data_82F2+$0003)
  SUB E
  SUB $09
  CP $EB
  RET C
  CALL sub_9ED9
  LD DE,(data_9930)
  INC D
  CALL sub_9936
  CALL sub_9ED9
  DEC E
  DEC E
  DEC E
  CALL sub_C162
  LD A,$05
  JP sub_8224

; data_9930
data_9930:
  DEFB $00,$00,$00,$00,$FF,$00

; sub_9936
;
; Used by the routines at sub_9152, sub_98BA, sub_9942, sub_9B07, sub_9D7F,
; sub_9F2D, sub_A30B, sub_A7D6, sub_A817, sub_ABCF, sub_AC04 and sub_AF2B.
sub_9936:
  PUSH AF
  LD A,E
  ADD A,A
  ADD A,A
  LD E,A
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  LD D,A
  POP AF
  RET

; sub_9942
;
; Used by the routine at l_758A.
sub_9942:
  LD DE,(data_99F2)
  BIT 7,E
  JR NZ,l_999B
  DEC D
  DEC D
  INC E
  CALL sub_9936
  LD A,(data_82F2+$0003)
  SUB E
  CP $F4
  JR C,l_999B
  LD A,(data_82F2+$0004)
  CP D
  JR NZ,l_999B
  LD DE,(data_99F2)
  LD A,$04
  CALL sub_99F8
  LD HL,data_852E+$0350
  LD C,$00
  CALL sub_AF2B
  XOR A
  CALL sub_99F8
  LD A,$FF
  LD (data_99F2),A
  LD A,$63
  LD (data_8E5A),A
  CALL sub_8E4F
  CALL sub_C0F4
  LD A,(data_8269)
  LD B,A
  LD A,$FF
  LD (data_8269),A
  LD A,B
  LD DE,(data_82F2+$0003)
  CALL sub_8229
  LD B,$05
l_9996:
  CALL sub_7C3C
  DJNZ l_9996
l_999B:
  LD DE,(data_99F2+$0003)
  BIT 7,E
  RET NZ
  DEC D
  DEC D
  INC E
  CALL sub_9936
  LD A,(data_82F2+$0003)
  SUB E
  CP $F4
  RET C
  LD A,(data_82F2+$0004)
  CP D
  RET NZ
  LD DE,(data_99F2+$0003)
  LD A,$04
  CALL sub_99F8
  LD HL,data_852E+$0361
  LD C,$00
  CALL sub_AF2B
  XOR A
  CALL sub_99F8
  LD A,$FF
  LD (data_99F2+$0003),A
  LD A,$0A
  LD (data_8E66),A
  CALL sub_8E5B
  CALL sub_C101
  LD A,(data_8269)
  LD B,A
  LD A,$FF
  LD (data_8269),A
  LD A,B
  LD DE,(data_82F2+$0003)
  CALL sub_8229
  LD B,$05
l_99EC:
  CALL sub_7C3C
  DJNZ l_99EC
  RET

; data_99F2
data_99F2:
  DEFB $00,$00,$FF,$00,$00,$FF

; sub_99F8
;
; Used by the routines at sub_91CF, l_93E2 and sub_9942.
sub_99F8:
  PUSH BC
  PUSH HL
  LD BC,data_9A0F
  CALL sub_8524
  LD (sub_AF2B+$0008),HL
  LD (l_AFBF+$0001),HL
  LD (l_AFD1+$0001),HL
  LD (l_AFEC+$0012),HL
  POP HL
  POP BC
  RET

; data_9A0F
data_9A0F:
  DEFB $E1,$AD,$26,$AE,$5D,$AE,$95,$AE
  DEFB $E4,$AE

; sub_9A19
;
; Used by the routine at l_758A.
sub_9A19:
  LD A,$EF
  IN A,($FE)
  AND $0F
  RET NZ

; data_9A20
data_9A20:
  DEFB $C3,$60,$6D

; sub_9A23
;
; Used by the routine at l_758A.
sub_9A23:
  LD HL,data_9A99

; l_9A26
;
; Used by the routine at l_9A7F.
l_9A26:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_9A91
  INC HL
  LD A,$07
  CALL sub_92FB
  LD A,E
  OR A
  JR Z,l_9A56
  CP $7B
  JR Z,l_9A56
  CALL sub_AD36
  CP $DC
  JR NC,l_9A56
  LD A,(HL)
  INC A
  JR NZ,l_9A50
  CALL sub_9382
  JR l_9A53
l_9A50:
  CALL sub_9362
l_9A53:
  OR A
  JR Z,l_9A5A
l_9A56:
  LD A,(HL)
  NEG
  LD (HL),A
l_9A5A:
  LD A,(HL)
  ADD A,E
  LD C,A
  CALL sub_AD36
  AND $01
  JR Z,l_9A65
  INC A
l_9A65:
  DEC A
  LD B,A
  CP $FF
  JR NZ,l_9A70
  CALL sub_93C2
  JR l_9A73
l_9A70:
  CALL sub_93A2
l_9A73:
  OR A
  JR Z,l_9A78
  LD B,$00
l_9A78:
  LD A,B
  ADD A,D
  LD D,A
  OR A
  JR NZ,l_9A7F

; data_9A7E
data_9A7E:
  DEFB $14

; l_9A7F
;
; Used by the routine at l_9A26.
l_9A7F:
  LD E,C
  LD A,$07
  CALL sub_92FB
  LD C,$42
  CALL sub_7C77
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  DEC HL
  JR l_9A92
; This entry point is used by the routine at l_9A26.
l_9A91:
  POP HL
l_9A92:
  LD DE,$0004
  ADD HL,DE
  JP l_9A26

; data_9A99
data_9A99:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF

; sub_9AFA
;
; Used by the routine at sub_8494.
sub_9AFA:
  LD HL,data_9A99
  LD DE,data_9A99+$0001
  LD BC,$005F
  LD (HL),B
  LDIR
  RET

; sub_9B07
;
; Used by the routine at sub_8494.
sub_9B07:
  LD IX,data_9A99
  LD HL,data_9B4B
l_9B0E:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  CALL sub_9936
  INC E
  INC E
  INC D
  INC D
  INC D
  LD BC,$0004
  LD A,$08
l_9B22:
  EX AF,AF'
  LD (IX+$00),E
  LD (IX+$01),D
  LD A,$04
  CALL sub_92FB
  LD (IX+$02),$01
  CALL sub_AD36
  AND $01
  OR A
  JR Z,l_9B3B
  INC A
l_9B3B:
  DEC A
  LD (IX+$03),A
  ADD IX,BC
  LD (IX+$00),$FF
  EX AF,AF'
  DEC A
  JR NZ,l_9B22
  JR l_9B0E

; data_9B4B
data_9B4B:
  DEFB $00,$00,$00,$00,$00,$00,$FF

; sub_9B52
;
; Used by the routine at sub_83DD.
sub_9B52:
  LD HL,data_9A99
l_9B55:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  OR A
  JR Z,l_9B55
  CALL sub_9B82
  OR A
  CALL NZ,sub_9B6B
  JR l_9B55

; sub_9B6B
;
; Used by the routines at sub_9B52 and sub_9BB4.
sub_9B6B:
  LD A,$07
  CALL sub_92FB
  DEC HL
  DEC HL
  LD (HL),$00
  INC HL
  INC HL
  CALL sub_981D
  CALL sub_C155
  LD DE,data_AD82+$001A
  JP sub_AD53

; sub_9B82
;
; Used by the routines at sub_9B52 and sub_9E37.
sub_9B82:
  PUSH BC
  PUSH DE
  PUSH HL
  INC E
  INC E
  LD HL,data_845F
l_9B8A:
  XOR A
  LD C,(HL)
  BIT 7,C
  JR NZ,l_9BB0
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_9B8A
  LD A,C
  SUB E
  CP $FC
  JR C,l_9B8A
  LD A,B
  SUB D
  SUB $09
  CP $F6
  JR C,l_9B8A
  LD D,B
  LD E,C
  CALL sub_82FC
  DEC HL
  LD (HL),$00
  LD A,$01
l_9BB0:
  POP HL
  POP DE
  POP BC
  RET

; sub_9BB4
;
; Used by the routine at l_758A.
sub_9BB4:
  LD HL,data_9A99
l_9BB7:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  OR A
  JR Z,l_9BB7
  LD BC,$0804
  CALL sub_9BD6
  OR A
  JR Z,l_9BB7
  CALL sub_9B6B
  CALL sub_C155
  JP sub_9CAF

; sub_9BD6
;
; Used by the routines at sub_90EA, sub_9BB4, sub_9E64, sub_A26B, sub_A30B,
; sub_A5F4 and sub_AC7D.
sub_9BD6:
  PUSH HL
  LD A,C
  ADD A,$0C
  NEG
  LD L,A
  LD A,(data_82F2+$0003)
  SUB E
  SUB C
  CP L
  LD A,$00
  JR C,l_9BFE
  LD A,(data_82F2+$0009)
  OR A
  JR NZ,l_9C00
  LD A,B
  ADD A,$20
  NEG
  LD H,A
  LD A,(data_82F2+$0004)
  SUB D
  SUB B
  CP H
  LD A,$00
  JR C,l_9BFE
  INC A
l_9BFE:
  POP HL
  RET
l_9C00:
  LD A,B
  ADD A,$1A
  NEG
  LD H,A
  LD A,(data_82F2+$0004)
  ADD A,$06
  SUB D
  SUB B
  CP H
  LD A,$00
  JR C,l_9BFE
  INC A
  POP HL
  RET

; sub_9C15
;
; Used by the routine at l_758A.
sub_9C15:
  LD IX,data_B101+$0080
  LD HL,data_9C25+$004B
  LD DE,$0080
  ADD IX,DE
  LD E,(HL)
  BIT 7,E
  RET NZ

; data_9C25
data_9C25:
  DEFB $23,$56,$42,$23,$7E,$34,$23,$FE
  DEFB $65,$38,$EC,$FE,$69,$30,$08,$15
  DEFB $2B,$2B,$72,$23,$23,$18,$1A,$FE
  DEFB $74,$38,$16,$FE,$78,$30,$08,$14
  DEFB $2B,$2B,$72,$23,$23,$18,$0A,$2B
  DEFB $CD,$36,$AD,$E6,$3F,$C6,$14,$77
  DEFB $23,$CD,$36,$99,$4B,$78,$87,$87
  DEFB $87,$47,$3E,$18,$E5,$DD,$E5,$E1
  DEFB $CD,$DA,$76,$0E,$44,$CD,$5F,$7C
  DEFB $E1,$18,$AC,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF

; sub_9C7D
;
; Used by the routine at sub_8494.
sub_9C7D:
  LD HL,data_9C25+$004B
  LD DE,data_9C25+$004C
  LD BC,$000B
  LD (HL),$5F
  LDIR
  RET

; sub_9C8B
;
; Used by the routine at l_758A.
sub_9C8B:
  LD HL,data_9C25+$004B
l_9C8E:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  CP $65
  JR C,l_9C8E

; data_9C9B
data_9C9B:
  DEFB $CD,$36,$99,$01,$0C,$20,$CD,$D6
  DEFB $9B,$B7,$28,$E7,$C3,$AA,$9C

; l_9CAA
;
; Used by the routine at sub_9152.
l_9CAA:
  LD A,(data_9ED6+$0002)
  OR A

; data_9CAE
data_9CAE:
  DEFB $C0

; sub_9CAF
;
; Used by the routines at sub_90EA, sub_9BB4, sub_9E64, sub_A26B, sub_A5F4,
; sub_ABCF and sub_AC7D.
sub_9CAF:
  LD A,(data_9CE2)
  OR A
  RET NZ
  LD A,(data_768C+$0001)
  OR A
  RET NZ
  PUSH AF
  PUSH DE
  LD HL,$0000
  LD (data_AC78+$0003),HL
  XOR A
  LD (data_82F2+$0005),A
  LD (data_83DC),A
  LD A,$2E
  LD (data_9CE2),A
  ADD A,$14
  LD (data_768C+$0001),A
  LD DE,(data_82F2+$0003)
  LD A,D
  AND $FC
  LD D,A
  LD A,$0B
  CALL sub_8224
  POP DE
  POP AF
  RET

; data_9CE2
data_9CE2:
  DEFB $00

; sub_9CE3
;
; Used by the routine at l_758A.
sub_9CE3:
  LD A,(data_9CE2)
  OR A
  RET Z
  LD DE,(data_82F2+$0003)
  LD C,A
  DEC A
  LD (data_9CE2),A
  JR Z,l_9D0E
  LD HL,data_9D47+$0002
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  CP $0A
  JR NC,l_9D06
  CALL sub_814E
  LD A,$0B
  JP NZ,sub_8224
l_9D06:
  LD A,(HL)
  ADD A,D
  LD D,A
  LD A,$0B
  JP sub_8224
l_9D0E:
  LD A,(data_7BDA)
  OR A
  CALL NZ,sub_7BAA
  LD A,$01
  LD (data_82F2+$0008),A
  LD A,(data_8E7A)
  DEC A
  LD (data_8E7A),A
  LD A,$63
  LD (data_8E5A),A
  LD A,$0A
  LD (data_8E66),A
  CALL sub_8E4F
  CALL sub_8E5B
  CALL sub_8E67
  LD A,(data_8E7A)
  OR A
  JP Z,l_A02A
  LD DE,(data_82F2+$0001)
  CALL sub_814E
  LD A,$05
  JP NZ,sub_8224

; data_9D47
data_9D47:
  DEFB $14,$18,$F5,$04,$04,$04,$04,$04
  DEFB $04,$04,$04,$04,$04,$04,$04,$04
  DEFB $04,$04,$04,$04,$04,$04,$04,$04
  DEFB $04,$04,$04,$04,$04,$02,$02,$02
  DEFB $01,$01,$01,$01,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$FE,$FE,$FE,$FC
  DEFB $FC

; sub_9D78
;
; Used by the routines at sub_81A4, sub_8338, sub_9208 and sub_A553.
sub_9D78:
  LD A,(data_9CE2)
  OR A
  RET Z
  POP AF
  RET

; sub_9D7F
;
; Used by the routine at l_758A.
sub_9D7F:
  LD HL,data_9DC1
; This entry point is used by the routine at l_9DA8.
l_9D82:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  CALL sub_AD36
  CP $F7
  JR C,l_9D82
  CALL sub_9936
  DEC E
  DEC E
  LD A,E
  SUB $1E
  LD C,A
  LD A,(data_82F2+$0003)
  CP C
  RET NC
  PUSH HL
  LD HL,data_9E18
; This entry point is used by the routine at l_9DA8.
l_9DA2:
  BIT 7,(HL)
  JR Z,l_9DA8

; data_9DA6
data_9DA6:
  DEFB $E1,$C9

; l_9DA8
;
; Used by the routine at sub_9D7F.
l_9DA8:
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR NZ,l_9DA2
  DEC HL
  LD (HL),$FE
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  LD A,$08
  CALL sub_92FB
  CALL sub_C13B
  POP HL
  JR l_9D82

; data_9DC1
data_9DC1:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$FF

; sub_9DD6
;
; Used by the routine at l_758A.
sub_9DD6:
  LD HL,data_9E18
l_9DD9:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD C,A
  INC HL
  OR A
  JR Z,l_9DD9
  PUSH HL
  LD A,$08
  CALL sub_92FB
  LD A,E
  OR A
  JR NZ,l_9DF6
  DEC HL
  LD (HL),$00
  POP HL
  JR l_9DD9
l_9DF6:
  LD A,C
  ADD A,E
  LD E,A
  LD A,$08
  CALL sub_92FB
  LD C,$47
  CALL sub_7C77
  DEC HL
  DEC HL
  DEC HL
  LD (HL),E
  POP HL
  JR l_9DD9

; sub_9E0A
;
; Used by the routine at sub_8494.
sub_9E0A:
  LD HL,data_9E18
  LD DE,data_9E18+$0001
  LD (HL),$00
  LD BC,$001D
  LDIR
  RET

; data_9E18
data_9E18:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$FF

; sub_9E37
;
; Used by the routine at sub_83DD.
sub_9E37:
  LD HL,data_9E18
l_9E3A:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_9E3A
  CALL sub_9B82
  OR A
  CALL NZ,sub_9E4F
  JR l_9E3A

; sub_9E4F
;
; Used by the routines at sub_9E37 and sub_9E64.
sub_9E4F:
  LD A,$08
  CALL sub_92FB
  DEC HL
  LD (HL),$00
  INC HL
  CALL sub_981D
  CALL sub_C155
  LD DE,data_AD82+$001A
  JP sub_AD53

; sub_9E64
;
; Used by the routine at l_758A.
sub_9E64:
  LD HL,data_9E18
l_9E67:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_9E67
  LD BC,$0804
  CALL sub_9BD6
  OR A
  JR Z,l_9E67
  CALL sub_9E4F
  CALL sub_C155
  JP sub_9CAF

; sub_9E85
;
; Used by the routine at l_758A.
sub_9E85:
  LD A,(data_9E98)
  CP $10
  RET NC
  LD B,A
  LD A,$10
  SUB B
  LD B,A
  LD A,$06
l_9E92:
  CALL sub_92FB
  DJNZ l_9E92
  RET

; data_9E98
data_9E98:
  DEFB $00

; sub_9E99
;
; Used by the routine at l_758A.
sub_9E99:
  LD A,(data_9EAE)
  CP $06
  RET NC
  LD B,A
  LD A,$06
  SUB B
  LD B,A
  LD HL,data_B101
  XOR A
l_9EA8:
  CALL sub_795C
  DJNZ l_9EA8
  RET

; data_9EAE
data_9EAE:
  DEFB $00

; sub_9EAF
;
; Used by the routines at sub_A26B and sub_A30B.
sub_9EAF:
  PUSH HL
  PUSH DE
  CALL sub_C12E
  LD E,A
  LD D,$00
  LD HL,(data_9ED6)
  ADD HL,DE
  LD (data_9ED6),HL
  POP DE
  POP HL
  RET

; sub_9EC1
;
; Used by the routine at l_758A.
sub_9EC1:
  LD HL,(data_9ED6)
  LD A,L
  OR H
  RET Z
  DEC HL
  LD (data_9ED6),HL
  LD DE,data_AD82+$0014
  CALL sub_AD53
  LD B,$28
  JP sub_7C26

; data_9ED6
data_9ED6:
  DEFB $00,$00,$00

; sub_9ED9
;
; Used by the routine at sub_98BA.
sub_9ED9:
  LD HL,data_9F13
l_9EDC:
  BIT 7,(HL)
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR NZ,l_9EDC
  DEC HL
  LD (HL),$14
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  RET

; sub_9EEE
;
; Used by the routine at l_758A.
sub_9EEE:
  LD HL,data_9F13
l_9EF1:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_9EF1
  DEC HL
  DEC (HL)
  INC HL
  CALL sub_AD36
  AND $03
  ADD A,E
  LD E,A
  CALL sub_AD36
  AND $0F
  ADD A,D
  LD D,A
  CALL sub_981D
  JR l_9EF1

; data_9F13
data_9F13:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$FF

; sub_9F20
;
; Used by the routine at sub_8494.
sub_9F20:
  LD HL,data_9F13
  LD DE,data_9F13+$0001
  LD BC,$000B
  LD (HL),B
  LDIR
  RET

; sub_9F2D
;
; Used by the routine at l_758A.
sub_9F2D:
  LD A,(data_7B92+$0002)
  OR A
  JR NZ,l_9F37
  LD (data_9F6D),A
  RET
l_9F37:
  LD A,(data_9F6D)
  OR A
  RET NZ
  INC A
  LD (data_9F6D),A
  LD DE,(data_9F6D+$0001)
  BIT 7,E
  RET NZ
  INC D
  CALL sub_9936
  LD A,(data_82F2+$0004)
  CP D
  RET NZ
  LD A,(data_82F2+$0003)
  SUB E
  SUB $09
  CP $EB
  RET C
  LD DE,(data_82F2+$0003)
  LD A,(data_9ED6+$0002)
  XOR $0C
  LD (data_9ED6+$0002),A
  CALL sub_C0F4
  LD A,$05
  JP sub_8224

; data_9F6D
data_9F6D:
  DEFB $00,$00,$00,$FF

; sub_9F71
;
; Used by the routine at sub_A5CA.
sub_9F71:
  PUSH BC
  PUSH DE
  PUSH HL
  INC E
  INC E
  LD HL,data_845F
l_9F79:
  XOR A
  LD C,(HL)
  BIT 7,C
  JR NZ,l_9F9F
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_9F79
  LD A,C
  SUB E
  CP $F8
  JR C,l_9F79
  LD A,B
  SUB D
  SUB $11
  CP $EE
  JR C,l_9F79
  LD D,B
  LD E,C
  CALL sub_82FC
  DEC HL
  LD (HL),$00
  LD A,$01
l_9F9F:
  POP HL
  POP DE
  POP BC
  RET

; sub_9FA3
;
; Used by the routines at sub_A26B, sub_A62D and sub_AC7D.
sub_9FA3:
  PUSH AF
  PUSH HL
  LD HL,data_A001+$000B
l_9FA8:
  BIT 7,(HL)
  JR NZ,l_9FBA
  INC HL
  INC HL
  LD A,(HL)
  OR A
  INC HL
  JR NZ,l_9FA8
  DEC HL
  LD (HL),$0B
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
l_9FBA:
  POP HL
  POP AF
  RET

; sub_9FBD
;
; Used by the routine at l_758A.
sub_9FBD:
  LD IY,data_B101+$0300
  LD HL,data_A001+$000B
l_9FC4:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_9FF6
  DEC (HL)
  LD L,A
  LD H,$00
  LD BC,$A000
  ADD HL,BC
  LD A,(HL)
  PUSH IY
  POP HL
  LD B,D
  LD C,E
  CALL sub_795C
  CALL sub_AD36
  AND $03
  ADD A,$42
  LD C,A
  CALL sub_7C8F
  CALL sub_AD36
  AND $1F
  INC A
  LD B,A
  CALL sub_7C26
l_9FF6:
  LD BC,$0030
  ADD IY,BC
  POP HL
  INC HL
  INC HL
  INC HL
  JR l_9FC4

; data_A001
data_A001:
  DEFB $00,$09,$09,$08,$08,$07,$07,$06
  DEFB $06,$05,$05,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$FF

; sub_A01C
;
; Used by the routine at sub_8494.
sub_A01C:
  LD HL,data_A001+$000B
  LD DE,data_A001+$000C
  LD BC,$000E
  LD (HL),$00
  LDIR
  RET

; l_A02A
;
; Used by the routine at sub_9CE3.
l_A02A:
  LD HL,data_A057
  CALL sub_AF2B
  LD HL,data_7D67+$0001
  CALL sub_7D17
  LD BC,$0000
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_A073
  CALL sub_AD18
  LD BC,$4E20
l_A048:
  CALL sub_ACD1
  OR A
  JP NZ,l_6D60
  DEC BC
  LD A,B
  OR C
  JR NZ,l_A048
  JP l_6D60

; data_A057
data_A057:
  DEFB $DF,$09,$0A,$E6,$E0,$D7,$E0,$56
  DEFB $E4,$0B,$20,$A4,$20,$47,$41,$4D
  DEFB $45,$20,$4F,$56,$45,$52,$20,$A4
  DEFB $E4,$0B,$20,$FF

; sub_A073
;
; Used by the routine at l_A02A.
sub_A073:
  LD HL,sub_B6D1
  LD IX,data_718D+$0064

; l_A07A
;
; Used by the routine at l_A14C.
l_A07A:
  BIT 7,(IX+$00)
  RET NZ
  PUSH IX
  LD DE,$000A
  ADD IX,DE
  LD HL,data_AD82+$0008
  LD B,$06

; l_A08B
;
; Used by the routine at l_A145.
l_A08B:
  LD A,(IX+$00)
  CP (HL)
  JP Z,l_A145
  JP NC,l_A14C

; data_A095
data_A095:
  DEFB $E1,$E5,$3E,$FF,$01,$E8,$03,$ED
  DEFB $B1,$21,$E8,$03,$A7,$ED,$42,$E5
  DEFB $C1,$11,$20,$75,$21,$10,$75,$ED
  DEFB $B8,$3E,$FF,$32,$11,$75,$E1,$E5
  DEFB $11,$0A,$00,$19,$EB,$21,$8A,$AD
  DEFB $01,$06,$00,$ED,$B0,$CD,$4B,$B0
  DEFB $21,$32,$A2,$11,$33,$A2,$01,$07
  DEFB $00,$36,$20,$ED,$B0,$21,$56,$A1
  DEFB $CD,$2B,$AF,$11,$0C,$0F,$21,$32
  DEFB $A2,$0E,$44,$3E,$3F,$CD,$E1,$AD
  DEFB $01,$E8,$03,$CD,$B7,$B0,$CD,$18
  DEFB $AD,$D5,$CD,$D1,$AC,$B7,$28,$FA
  DEFB $FE,$02,$28,$F6,$D1,$FE,$0D,$28
  DEFB $33,$FE,$01,$20,$20,$7B,$FE,$13
  DEFB $20,$09,$7E,$FE,$20,$28,$04,$36
  DEFB $20,$18,$CE,$7B,$FE,$0C,$28,$C9
  DEFB $3E,$2D,$0E,$47,$CD,$E1,$AD,$2B
  DEFB $36,$20,$1D,$18,$BC,$77,$0E,$46
  DEFB $CD,$E1,$AD,$7B,$FE,$13,$28,$B8
  DEFB $23,$1C,$18,$AD,$D1,$21,$32,$A2
  DEFB $01,$08,$00,$ED,$B0,$3E,$01,$32
  DEFB $F0,$71,$CD,$18,$AD,$C3,$60,$6D

; l_A145
;
; Used by the routine at l_A08B.
l_A145:
  INC HL
  INC IX
  DEC B
  JP NZ,l_A08B

; l_A14C
;
; Used by the routine at l_A08B.
l_A14C:
  POP IX
  LD DE,$0010
  ADD IX,DE
  JP l_A07A

; data_A156
data_A156:
  DEFB $E6,$E0,$EC,$DF,$00,$00,$E3,$10
  DEFB $A2,$DF,$02,$00,$E1,$0A,$DC,$04
  DEFB $D4,$05,$AD,$DC,$06,$D4,$07,$AD
  DEFB $E2,$E3,$10,$A2,$DF,$02,$1E,$E1
  DEFB $0A,$DC,$04,$D4,$05,$AD,$DC,$06
  DEFB $D4,$07,$AD,$E2,$DF,$03,$08,$E3
  DEFB $FF,$70,$DF,$08,$08,$E0,$46,$E6
  DEFB $E0,$D7,$43,$4F,$4E,$47,$52,$41
  DEFB $54,$55,$4C,$41,$54,$49,$4F,$4E
  DEFB $53,$21,$7A,$ED,$DB,$50,$4C,$45
  DEFB $41,$53,$45,$20,$45,$4E,$54,$45
  DEFB $52,$20,$59,$4F,$55,$52,$20,$4E
  DEFB $41,$4D,$45,$7A,$E7,$DA,$49,$4E
  DEFB $54,$4F,$20,$54,$48,$45,$20,$45
  DEFB $58,$4F,$4C,$4F,$4E,$20,$48,$41
  DEFB $4C,$4C,$20,$4F,$46,$20,$46,$41
  DEFB $4D,$45,$7B,$EE,$DE,$2D,$2D,$2D
  DEFB $2D,$2D,$2D,$2D,$2D,$7B,$F2,$DC
  DEFB $50,$52,$45,$53,$53,$20,$43,$41
  DEFB $50,$53,$20,$54,$4F,$20,$44,$45
  DEFB $4C,$45,$54,$45,$7A,$ED,$DD,$50
  DEFB $52,$45,$53,$53,$20,$45,$4E,$54
  DEFB $45,$52,$20,$54,$4F,$20,$45,$4E
  DEFB $44,$FF,$E3,$28,$A2,$DC,$78,$02
  DEFB $E1,$0E,$08,$09,$E2,$93,$D4,$E1
  DEFB $0E,$0A,$0B,$E2,$77,$00,$E3,$28
  DEFB $A2,$FF,$DC,$00,$D4,$01,$AD,$DC
  DEFB $02,$D4,$03,$FF,$20,$20,$20,$20
  DEFB $20,$20,$20,$20

; sub_A23A
;
; Used by the routines at sub_8494 and sub_A26B.
sub_A23A:
  XOR A
  LD (data_A266+$0004),A
  LD DE,(data_A266)
  BIT 7,E
  RET NZ
  LD A,(data_9CE2)
  OR A
  RET NZ
  CALL sub_8097
  LD BC,$6100
  ADD HL,BC
  LD A,(HL)
  CP $0D
  RET NZ
  LD (data_A266+$0004),A
  CALL sub_AD36
  AND $7F
  ADD A,$20
  LD H,A
  LD L,$78
  LD (data_A266+$0002),HL
  RET

; data_A266
data_A266:
  DEFB $00,$00,$00,$00,$00

; sub_A26B
;
; Used by the routine at l_758A.
sub_A26B:
  LD A,(data_A266+$0004)
  OR A
  JP Z,sub_A23A
  LD DE,(data_A266)
  CALL sub_8097
  LD DE,(data_A266+$0002)
  PUSH DE
  LD BC,$6100
  ADD HL,BC
  LD A,(HL)
  CP $0D
  JR NZ,l_A2AE
  LD L,$0A
  DEC E
  LD A,E
  CP $FF
  JR NC,l_A2B6
  CP $46
  JR NC,l_A295
  INC L
  DEC E
l_A295:
  LD A,(data_82F2+$0004)
  CP D
  JR Z,l_A2A0
  JR NC,l_A29F
  DEC D
  DEC D
l_A29F:
  INC D
l_A2A0:
  LD BC,$1008
  CALL sub_9BD6
  OR A
  JR Z,l_A2C4
  CALL sub_9CAF
  JR l_A2B3
l_A2AE:
  LD A,$22
  CALL sub_9EAF
l_A2B3:
  CALL sub_9FA3
l_A2B6:
  POP BC
  XOR A
  LD HL,data_B101+$03F0
  CALL sub_795C
  LD (data_A266+$0004),A
  JP sub_A23A
l_A2C4:
  LD (data_A266+$0002),DE
  POP BC
  LD A,L
  LD HL,data_B101+$03F0
  CALL sub_795C
  LD C,$47
  JP sub_7C8F

; sub_A2D5
;
; Used by the routine at sub_8494.
sub_A2D5:
  LD HL,data_C7F4+$204C
  LD (sub_ADE1+$000E),HL
  LD B,$16
l_A2DD:
  PUSH BC
  LD A,$03
l_A2E0:
  EX AF,AF'
  CALL sub_AD36
  AND $1F
  LD E,A
  LD D,B
  DEC D
  CALL sub_8097
  PUSH BC
  LD BC,$5E00
  ADD HL,BC
  POP BC
  LD A,(HL)
  OR A
  JR NZ,l_A303
  CALL sub_AD36
  AND $07
  OR $42
  LD C,A
  LD A,$03
  CALL sub_AE26
l_A303:
  EX AF,AF'
  DEC A
  JR NZ,l_A2E0
  POP BC
  DJNZ l_A2DD
  RET

; sub_A30B
;
; Used by the routine at l_758A.
sub_A30B:
  LD HL,data_A333
l_A30E:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_A30E
  PUSH DE
  CALL sub_9936
  LD BC,$0804
  CALL sub_9BD6
  POP DE
  OR A
  JR Z,l_A30E
  DEC HL
  LD (HL),$00
  CALL sub_C12E
  LD A,$28
  JP sub_9EAF

; data_A333
data_A333:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$FF

; sub_A352
;
; Used by the routine at sub_8494.
sub_A352:
  LD HL,data_A333
  LD DE,data_A333+$0001
  LD BC,$000B
  LD (HL),$01
  LDIR
  RET

; sub_A360
;
; Used by the routine at l_758A.
sub_A360:
  LD IY,data_B101+$0420
  LD HL,data_A406+$0102

; l_A367
;
; Used by the routine at l_A3F9.
l_A367:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JP Z,l_A3F9
  PUSH DE
  INC HL
  INC HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR NZ,l_A399
l_A380:
  LD A,(BC)
  CP $C4
  JP Z,l_A3A4
  CP $C3
  JP Z,l_A3B1
  ADD A,E
  LD E,A
  INC BC
  LD A,(BC)
  ADD A,D
  LD D,A
  INC BC
  DEC HL
  LD (HL),B
  DEC HL
  LD (HL),C
  JP l_A3C0
l_A399:
  DEC (HL)
  LD A,(BC)
  ADD A,E
  LD E,A
  INC BC
  LD A,(BC)
  ADD A,D
  LD D,A
  JP l_A3C0
l_A3A4:
  INC BC
  LD A,(BC)
  DEC A
  LD (HL),A
  INC BC
  DEC HL
  LD (HL),B
  DEC HL
  LD (HL),C
  INC HL
  INC HL
  JR l_A399
l_A3B1:
  DEC HL
  DEC HL
  DEC HL
  LD B,(HL)
  DEC HL
  LD C,(HL)
  INC HL
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  JP l_A380
l_A3C0:
  POP BC
  POP HL
  PUSH HL
  LD A,E
  CP $80
  JP NC,l_A3EE
  LD A,D
  CP $B0
  JP NC,l_A3EE
  LD (HL),E
  INC HL
  LD (HL),D
  PUSH DE
  LD DE,$0007
  ADD HL,DE
  LD A,(HL)
  INC (HL)
  AND $03
  ADD A,$01
  POP DE
  PUSH HL
  PUSH IY
  POP HL
  CALL sub_795C
  POP HL
  INC HL
  LD C,(HL)
  CALL sub_7C8F
  JP l_A3F9
l_A3EE:
  INC HL
  INC HL
  LD (HL),$00
  XOR A
  PUSH IY
  POP HL
  CALL sub_795C

; l_A3F9
;
; Used by the routine at l_A367.
l_A3F9:
  POP HL
  LD DE,$000A
  ADD HL,DE
  LD DE,$0030
  ADD IY,DE
  JP l_A367

; data_A406
data_A406:
  DEFB $FF,$00,$FF,$00,$FF,$FF,$FF,$FF
  DEFB $FF,$FE,$FF,$FE,$FF,$FD,$FF,$FD
  DEFB $FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD
  DEFB $FF,$FE,$FF,$FE,$FF,$FF,$FF,$FF
  DEFB $FF,$00,$FF,$01,$FF,$01,$FF,$02
  DEFB $FF,$02,$FF,$03,$FF,$03,$FF,$03
  DEFB $FF,$03,$FF,$03,$FF,$03,$FF,$02
  DEFB $FF,$02,$FF,$01,$FF,$01,$C3,$FF
  DEFB $00,$FF,$00,$FF,$FF,$FF,$FF,$FF
  DEFB $FE,$FF,$FE,$FF,$FD,$FF,$FD,$FF
  DEFB $FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF
  DEFB $FE,$FF,$FE,$FF,$FF,$FF,$FF,$FF
  DEFB $00,$FF,$01,$FF,$01,$FF,$02,$FF
  DEFB $02,$FF,$03,$FF,$03,$FF,$03,$FF
  DEFB $03,$FF,$03,$FF,$03,$FF,$02,$FF
  DEFB $02,$FF,$01,$FF,$01,$C4,$0F,$FF
  DEFB $00,$C4,$06,$FE,$00,$C4,$64,$FC
  DEFB $00,$C3,$C4,$22,$FE,$00,$C4,$04
  DEFB $FE,$FE,$C4,$02,$FE,$F8,$C4,$03
  DEFB $00,$F8,$C4,$02,$02,$F8,$C4,$04
  DEFB $02,$FE,$C4,$06,$02,$00,$C4,$04
  DEFB $02,$02,$C4,$02,$02,$08,$C4,$03
  DEFB $00,$08,$C4,$02,$FE,$08,$C4,$04
  DEFB $FE,$02,$C4,$64,$FE,$00,$C3,$C4
  DEFB $28,$FF,$00,$C4,$64,$FC,$00,$C3
  DEFB $C4,$12,$FE,$00,$C4,$20,$00,$FF
  DEFB $C4,$18,$00,$01,$C4,$06,$00,$00
  DEFB $C4,$64,$FC,$00,$C3,$C4,$08,$FE
  DEFB $FC,$C4,$08,$FE,$04,$C4,$08,$FE
  DEFB $FC,$C4,$08,$00,$04,$C4,$18,$FE
  DEFB $00,$C4,$06,$00,$FC,$C4,$06,$02
  DEFB $00,$C4,$06,$00,$04,$C4,$64,$FC
  DEFB $00,$C3,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$FF

; sub_A545
;
; Used by the routine at sub_8494.
sub_A545:
  LD HL,data_A406+$0102
  LD DE,data_A406+$0103
  LD BC,$003B
  LD (HL),$00
  LDIR
  RET

; sub_A553
;
; Used by the routine at l_758A.
sub_A553:
  CALL sub_9D78
  LD A,(data_A676)
  OR A
  RET Z
  LD HL,data_A5C9
  LD A,(HL)
  OR A
  JR Z,l_A564
  DEC (HL)
  RET
l_A564:
  LD A,(data_82F2+$0003)
  CP $54
  RET NC
  LD HL,data_A406+$0102
  LD BC,$000A
l_A570:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_A57F
  POP HL
  ADD HL,BC
  JR l_A570
l_A57F:
  POP HL
  CALL sub_AD36
  CP $C8
  RET C
  LD (HL),$78
  INC HL
  LD DE,(data_82F2+$0003)
  CALL sub_AD36
  CP $AF
  JR C,l_A599
  LD A,D
  SUB $0A
  JR l_A59F
l_A599:
  CALL sub_AD36
  AND $0F
  ADD A,D
l_A59F:
  LD (HL),A
  INC HL
  LD (HL),$01
  INC HL
  LD DE,data_A406
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$03
  INC HL
  CALL sub_AD36
  AND $07
  CP $02
  JR NC,l_A5C0
  ADD A,$04
l_A5C0:
  OR $40
  LD (HL),A
  LD A,$09
  LD (data_A5C9),A
  RET

; data_A5C9
data_A5C9:
  DEFB $00

; sub_A5CA
;
; Used by the routine at sub_83DD.
sub_A5CA:
  LD IY,data_B101+$0420
  LD HL,data_A406+$0102
l_A5D1:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_A5E8
  CALL sub_9F71
  OR A
  JR Z,l_A5E8
  POP HL
  PUSH HL
  CALL sub_A62D
l_A5E8:
  POP HL
  LD DE,$000A
  ADD HL,DE
  LD DE,$0030
  ADD IY,DE
  JR l_A5D1

; sub_A5F4
;
; Used by the routine at l_758A.
sub_A5F4:
  LD IY,data_B101+$0420
  LD HL,data_A406+$0102
l_A5FB:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_A621
  LD BC,$0804
  INC E
  INC E
  INC D
  INC D
  INC D
  INC D
  CALL sub_9BD6
  OR A
  JR Z,l_A621
  POP HL
  PUSH HL
  DEC E
  DEC D
  DEC D
  CALL sub_A62D
  CALL sub_9CAF
l_A621:
  POP HL
  LD DE,$000A
  ADD HL,DE
  LD DE,$0030
  ADD IY,DE
  JR l_A5FB

; sub_A62D
;
; Used by the routines at sub_A5CA and sub_A5F4.
sub_A62D:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  XOR A
  LD (HL),A
  PUSH IY
  POP HL
  CALL sub_795C
  CALL sub_9FA3
  CALL sub_C155
  LD DE,data_AD82+$002C
  JP sub_AD53

; sub_A645
;
; Used by the routine at sub_8494.
sub_A645:
  XOR A
  LD (data_A676),A
  LD HL,data_A676+$0001
  LD A,(data_8523)
  LD B,A
l_A650:
  LD A,(HL)
  CP $FF
  RET Z
  CP B
  JR Z,l_A65E
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  JR l_A650
l_A65E:
  LD A,$01
  LD (data_A676),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (l_A59F+$0006),DE
  INC HL
  LD A,(HL)
  LD (l_A3C0+$001C),A
  INC HL
  LD A,(HL)
  LD (l_A5C0+$0004),A
  RET

; data_A676
data_A676:
  DEFB $00,$03,$06,$A4,$10,$14,$04,$06
  DEFB $A4,$10,$14,$05,$06,$A4,$10,$14
  DEFB $0A,$45,$A4,$18,$14,$0B,$45,$A4
  DEFB $18,$28,$0D,$45,$A4,$18,$14,$0F
  DEFB $90,$A4,$01,$0D,$10,$45,$A4,$18
  DEFB $1E,$11,$06,$A4,$10,$14,$13,$C5
  DEFB $A4,$18,$14,$15,$06,$A4,$10,$1E
  DEFB $16,$90,$A4,$01,$0D,$1A,$C5,$A4
  DEFB $14,$08,$1C,$06,$A4,$01,$10,$1D
  DEFB $C5,$A4,$18,$19,$1E,$C5,$A4,$18
  DEFB $0F,$21,$06,$A4,$10,$14,$24,$90
  DEFB $A4,$14,$08,$25,$45,$A4,$01,$14
  DEFB $26,$45,$A4,$01,$08,$27,$06,$A4
  DEFB $10,$14,$2A,$C5,$A4,$18,$08,$2B
  DEFB $C5,$A4,$18,$08,$2C,$06,$A4,$10
  DEFB $14,$30,$C5,$A4,$18,$14,$31,$90
  DEFB $A4,$10,$08,$33,$CE,$A4,$25,$09
  DEFB $36,$E3,$A4,$29,$1E,$37,$06,$A4
  DEFB $10,$09,$38,$45,$A4,$29,$09,$3A
  DEFB $E3,$A4,$10,$14,$3B,$C5,$A4,$25
  DEFB $09,$3E,$CE,$A4,$01,$09,$3F,$06
  DEFB $A4,$25,$09,$40,$C5,$A4,$18,$09
  DEFB $42,$E3,$A4,$18,$1E,$44,$06,$A4
  DEFB $14,$08,$45,$C5,$A4,$18,$28,$48
  DEFB $E3,$A4,$10,$23,$4A,$E3,$A4,$18
  DEFB $0C,$4B,$06,$A4,$10,$09,$4C,$C5
  DEFB $A4,$10,$09,$4D,$CE,$A4,$25,$09
  DEFB $4F,$90,$A4,$01,$09,$50,$E3,$A4
  DEFB $29,$1E,$53,$E3,$A4,$29,$09,$54
  DEFB $CE,$A4,$29,$09,$55,$90,$A4,$10
  DEFB $08,$56,$C5,$A4,$14,$09,$59,$45
  DEFB $A4,$18,$09,$5A,$C5,$A4,$25,$08
  DEFB $5B,$CE,$A4,$29,$19,$5E,$45,$A4
  DEFB $14,$10,$60,$E3,$A4,$18,$1E,$62
  DEFB $E3,$A4,$29,$23,$63,$90,$A4,$10
  DEFB $08,$65,$C5,$A4,$14,$08,$67,$06
  DEFB $A4,$01,$0A,$68,$C5,$A4,$18,$0A
  DEFB $69,$C5,$A4,$18,$0A,$6C,$06,$A4
  DEFB $10,$0A,$6F,$90,$A4,$14,$08,$70
  DEFB $45,$A4,$01,$14,$71,$45,$A4,$01
  DEFB $08,$72,$06,$A4,$10,$0A,$75,$C5
  DEFB $A4,$18,$08,$76,$C5,$A4,$18,$08
  DEFB $77,$06,$A4,$10,$0A,$7B,$C5,$A4
  DEFB $18,$0A,$7C,$90,$A4,$10,$08,$FF

; sub_A7D6
;
; Used by the routine at l_758A.
sub_A7D6:
  LD HL,data_A814
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  CALL sub_9936
  LD HL,data_B101+$0540
  LD B,D
  LD C,E
  CALL sub_AD36
  AND $03
  ADD A,$1C
  CALL sub_795C
  LD BC,$0030
  ADD HL,BC
  LD C,A
  LD A,E
  ADD A,$08
  LD E,A
  LD A,C
  INC A
  LD B,D
  LD C,E
  CALL sub_795C
  CALL sub_AD36
  AND $07
  OR $40
  LD C,A
  CALL sub_7C8F
  LD B,A
  LD A,E
  SUB $08
  LD E,A
  JP sub_7C8F

; data_A814
data_A814:
  DEFB $00,$00,$FF

; sub_A817
;
; Used by the routine at l_758A.
sub_A817:
  LD DE,(data_A960+$018F)
  BIT 7,E
  RET NZ
  CALL sub_9936
  LD A,(data_82F2+$0003)
  CP E
  RET C
  LD HL,data_A960+$0192
  CALL sub_AF2B
  LD A,(data_8E7A)
  LD B,A
  ADD A,$30
  LD DE,$0C0D
  LD C,$46
  CALL sub_ADE1
  LD DE,data_AD82+$004A
l_A83D:
  CALL sub_AD53
  DJNZ l_A83D
  LD A,(data_9ED6+$0002)
  OR A
  JR NZ,l_A867
  LD C,$47
  LD A,$31
  LD DE,$080E
  CALL sub_ADE1
  LD BC,$0050
l_A855:
  PUSH BC
  LD DE,data_AD82+$0026
  CALL sub_AD53
  LD B,$3C
  CALL sub_7C26
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,l_A855
l_A867:
  LD A,(data_8523)
  CP $7C
  JR NZ,l_A894
  LD BC,$0000
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B04B
  LD HL,data_A960+$00DF
  CALL sub_AF2B
  LD A,$FF
  LD (data_8523),A
  LD BC,$0000
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B0B7
l_A894:
  CALL sub_A8DB
  LD HL,data_768C+$0002
  LD A,(data_8E7A)
  CP $09
  JR NC,l_A8A5

; data_A8A1
data_A8A1:
  DEFB $3C,$32,$7A,$8E

; l_A8A5
;
; Used by the routine at sub_A817.
l_A8A5:
  XOR A
  LD (data_9ED6+$0002),A
  LD A,$63
  LD (data_8E5A),A
  LD A,$0A
  LD (data_8E66),A
  LD A,$88
  CALL sub_8253
  CALL sub_8485
  CALL sub_7690
  XOR A
  LD (data_82F2+$0005),A
  LD HL,data_A960+$0180
  LD A,(data_8523)
  LD B,A
l_A8C9:
  LD A,(HL)
  CP B
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  JR NZ,l_A8C9
  LD (data_82F2+$0003),DE
  LD (data_82F2+$0001),DE
  RET

; sub_A8DB
;
; Used by the routine at sub_A817.
sub_A8DB:
  LD HL,data_C7F4+$0FEC
  LD (sub_ADE1+$000E),HL
  LD BC,$0000
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B04B
  LD HL,data_A960+$0001
  CALL sub_AF2B
  CALL sub_AD18
  LD BC,$0000
  CALL sub_B0B7
l_A908:
  LD A,(data_A960)
  INC A
  LD (data_A960),A
  AND $07
  ADD A,$0D
  LD D,A
  LD E,$16
  LD C,$47
  LD A,$2A
  CALL sub_ADE1
  LD A,(data_A960)
  DEC A
  AND $07
  ADD A,$0D
  LD D,A
  LD E,$16
  LD C,$47
  LD A,$20
  CALL sub_ADE1
  CALL sub_7B72
  LD BC,$1770
  CALL sub_B0B7
  LD A,(data_7B92+$0004)
  OR A
  JP Z,l_A908
  LD BC,$0000
  CALL sub_B0B7
  CALL sub_B0B7
  CALL sub_B0B7
  LD A,(data_A960)
  AND $01
  RET Z
  LD A,(data_A960)
  AND $07
  LD B,A
  LD DE,data_AD82+$004A
l_A95A:
  CALL sub_AD53
  DJNZ l_A95A
  RET

; data_A960
data_A960:
  DEFB $00,$E6,$E0,$EC,$DF,$00,$00,$E3
  DEFB $10,$A2,$DF,$02,$00,$E1,$0A,$DC
  DEFB $04,$D4,$05,$AD,$DC,$06,$D4,$07
  DEFB $AD,$E2,$E3,$10,$A2,$DF,$02,$1E
  DEFB $E1,$0A,$DC,$04,$D4,$05,$AD,$DC
  DEFB $06,$D4,$07,$AD,$E2,$DF,$03,$08
  DEFB $E3,$FF,$70,$E6,$E0,$D7,$DF,$08
  DEFB $06,$DE,$45,$58,$4F,$4C,$4F,$4E
  DEFB $20,$42,$4F,$4E,$55,$53,$20,$53
  DEFB $43,$52,$45,$45,$4E,$21,$DF,$0A
  DEFB $03,$DB,$50,$52,$45,$53,$53,$20
  DEFB $46,$49,$52,$45,$20,$54,$4F,$20
  DEFB $53,$54,$4F,$50,$20,$50,$4F,$49
  DEFB $4E,$54,$45,$52,$DF,$0D,$09,$DD
  DEFB $30,$30,$30,$30,$30,$20,$50,$4F
  DEFB $49,$4E,$54,$53,$A3,$DC,$30,$31
  DEFB $30,$30,$30,$20,$50,$4F,$49,$4E
  DEFB $54,$53,$A3,$DD,$30,$30,$30,$30
  DEFB $30,$20,$50,$4F,$49,$4E,$54,$53
  DEFB $A3,$DC,$30,$33,$30,$30,$30,$20
  DEFB $50,$4F,$49,$4E,$54,$53,$A3,$DD
  DEFB $30,$30,$30,$30,$30,$20,$50,$4F
  DEFB $49,$4E,$54,$53,$A3,$DC,$30,$35
  DEFB $30,$30,$30,$20,$50,$4F,$49,$4E
  DEFB $54,$53,$A3,$DD,$30,$30,$30,$30
  DEFB $30,$20,$50,$4F,$49,$4E,$54,$53
  DEFB $A3,$DC,$30,$37,$30,$30,$30,$20
  DEFB $50,$4F,$49,$4E,$54,$53,$FF,$E6
  DEFB $E0,$EC,$DF,$00,$00,$E3,$10,$A2
  DEFB $DF,$02,$00,$E1,$0A,$DC,$04,$D4
  DEFB $05,$AD,$DC,$06,$D4,$07,$AD,$E2
  DEFB $E3,$10,$A2,$DF,$02,$1E,$E1,$0A
  DEFB $DC,$04,$D4,$05,$AD,$DC,$06,$D4
  DEFB $07,$AD,$E2,$DF,$03,$08,$E3,$FF
  DEFB $70,$DF,$08,$08,$E0,$46,$E6,$E0
  DEFB $D7,$43,$4F,$4E,$47,$52,$41,$54
  DEFB $55,$4C,$41,$54,$49,$4F,$4E,$53
  DEFB $21,$7A,$EE,$DB,$59,$4F,$55,$20
  DEFB $48,$41,$56,$45,$20,$50,$52,$4F
  DEFB $56,$45,$4E,$20,$59,$4F,$55,$52
  DEFB $7A,$EE,$DA,$43,$4F,$4D,$42,$41
  DEFB $54,$20,$41,$42,$49,$4C,$49,$54
  DEFB $49,$45,$53,$7A,$F2,$DE,$54,$4F
  DEFB $20,$54,$48,$45,$20,$46,$55,$4C
  DEFB $4C,$7B,$F4,$DC,$50,$52,$45,$53
  DEFB $53,$20,$46,$49,$52,$45,$20,$54
  DEFB $4F,$7A,$F4,$DC,$52,$45,$53,$55
  DEFB $4D,$45,$20,$50,$4C,$41,$59,$FF
  DEFB $00,$10,$70,$19,$00,$78,$32,$00
  DEFB $20,$4B,$28,$80,$64,$10,$70,$00
  DEFB $00,$FF,$DF,$03,$07,$E0,$00,$E6
  DEFB $B0,$EA,$DD,$00,$D5,$01,$DD,$E4
  DEFB $0F,$04,$00,$D5,$01,$9C,$DD,$02
  DEFB $D5,$03,$E4,$0F,$05,$DD,$02,$D5
  DEFB $03,$9C,$E1,$0D,$DD,$06,$D5,$07
  DEFB $AD,$E2,$DD,$00,$D5,$01,$DD,$E4
  DEFB $0F,$04,$00,$D5,$01,$9C,$DD,$02
  DEFB $D5,$03,$E4,$0F,$05,$DD,$02,$D5
  DEFB $03,$6A,$FE,$E1,$0D,$DD,$06,$D5
  DEFB $07,$AD,$E2,$6B,$F1,$E6,$E0,$D7
  DEFB $E1,$0D,$E4,$0F,$20,$A0,$E2,$DA
  DEFB $6C,$01,$42,$52,$41,$56,$45,$52
  DEFB $59,$20,$42,$4F,$4E,$55,$53,$7A
  DEFB $F7,$DE,$30,$30,$30,$30,$30,$7A
  DEFB $F8,$DB,$4C,$49,$56,$45,$53,$20
  DEFB $42,$4F,$4E,$55,$53,$7A,$F9,$DD
  DEFB $58,$20,$31,$30,$30,$30,$7A,$F5
  DEFB $DC,$50,$52,$45,$53,$53,$20,$46
  DEFB $49,$52,$45,$20,$54,$4F,$7A,$F4
  DEFB $52,$45,$53,$55,$4D,$45,$20,$50
  DEFB $4C,$41,$59,$FF,$CD,$99,$B0

; l_AB97
;
; Used by the routine at sub_8494.
l_AB97:
  LD DE,(data_ABCC)
  BIT 7,E
  RET NZ
  INC D
  LD HL,data_C7F4+$12C4
  LD (sub_ADE1+$000E),HL
  XOR A
  LD (data_AC2B+$002D),A
  LD (l_AE03+$001E),A
  INC A
  LD (l_AE03+$0018),A
  LD BC,$0001
l_ABB3:
  LD A,$25
  CALL sub_ADE1
  INC D
  INC B
  CALL sub_8097
  PUSH DE
  LD DE,$6100
  ADD HL,DE
  POP DE
  LD A,(HL)
  OR A
  JR Z,l_ABB3
  LD A,B
  LD (data_AC2B+$002C),A
  RET

; data_ABCC
data_ABCC:
  DEFB $00,$00,$FF

; sub_ABCF
;
; Used by the routine at l_758A.
sub_ABCF:
  LD DE,(data_ABCC)
  BIT 7,E
  RET NZ
  CALL sub_C1A9
  INC D
  LD A,(data_AC2B+$002C)
  LD B,A
  CALL sub_8097
  LD DE,$5800
  ADD HL,DE
  LD DE,$0020
l_ABE8:
  LD A,(data_768C)
  AND $07
  OR $40
  LD (HL),A
  ADD HL,DE
  DJNZ l_ABE8
  LD DE,(data_ABCC)
  CALL sub_9936
  LD A,(data_82F2+$0003)
  ADD A,$0C
  CP E
  JP Z,sub_9CAF
  RET

; sub_AC04
;
; Used by the routine at sub_83DD.
sub_AC04:
  LD DE,(data_ABCC)
  BIT 7,E
  RET NZ
  DEC E
  CALL sub_9936
  LD HL,data_845F
l_AC12:
  LD C,(HL)
  BIT 7,C
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,l_AC12
  LD A,E
  CP C
  JR NZ,l_AC12
  LD A,(data_AC2B+$002D)
  INC A
  LD (data_AC2B+$002D),A
  CP $19
  RET C

; data_AC2B
data_AC2B:
  DEFB $21,$B8,$DA,$22,$EF,$AD,$ED,$5B
  DEFB $CC,$AB,$3A,$57,$AC,$47,$14,$CD
  DEFB $36,$AD,$E6,$07,$F6,$42,$4F,$3E
  DEFB $25,$CD,$95,$AE,$14,$10,$F0,$3E
  DEFB $FF,$32,$CC,$AB,$3E,$28,$CD,$48
  DEFB $C1,$C3,$AF,$9E,$00,$00

; sub_AC59
;
; Used by the routine at l_758A.
sub_AC59:
  LD A,(data_AC78)
  OR A
  RET NZ
  LD HL,(data_AC78+$0003)
  AND A
  LD DE,$02BC
  SBC HL,DE
  RET C
  LD DE,(data_82F2+$0003)
  LD E,$78
  LD (data_AC78+$0001),DE
  LD A,$01
  LD (data_AC78),A
  RET

; data_AC78
data_AC78:
  DEFB $00,$00,$00,$00,$00

; sub_AC7D
;
; Used by the routine at l_758A.
sub_AC7D:
  LD A,(data_AC78)
  OR A
  RET Z
  LD DE,(data_AC78+$0001)
  LD B,D
  LD C,E
  LD A,E
  OR A
  JR Z,l_ACC4
  CP $6F
  JR NC,l_ACA4
  CALL sub_AD36
  CP $80
  JR C,l_ACA4
  PUSH DE
  LD A,E
  ADD A,$06
  LD E,A
  LD A,D
  ADD A,$04
  LD D,A
  CALL sub_981D
  POP DE
l_ACA4:
  DEC E
  DEC E
  LD (data_AC78+$0001),DE
  LD A,$24
  LD HL,data_B101+$05A0
  CALL sub_795C
  LD C,$47
  CALL sub_7C8F
  LD BC,$1008
  CALL sub_9BD6
  OR A
  RET Z
  PUSH DE
  CALL sub_9CAF
  POP BC
l_ACC4:
  LD HL,data_B101+$05A0
  XOR A
  LD (data_AC78),A
  CALL sub_795C
  JP sub_9FA3

; sub_ACD1
;
; Used by the routines at l_6DA1, l_6FAB, l_7149 and l_A02A.
sub_ACD1:
  PUSH BC
  PUSH HL
  LD HL,data_ACEF
  LD D,$FE
l_ACD8:
  LD A,D
  IN A,($FE)
  LD E,$01
  LD B,$05
l_ACDF:
  RRCA
  JR NC,l_ACEB
  INC HL
  SLA E
  DJNZ l_ACDF
  RLC D
  JR C,l_ACD8
l_ACEB:
  LD A,(HL)
  POP HL
  POP BC
  RET

; data_ACEF
data_ACEF:
  DEFB $01,$5A,$58,$43,$56,$41,$53,$44
  DEFB $46,$47,$51,$57,$45,$52,$54,$31
  DEFB $32,$33,$34,$35,$30,$39,$38,$37
  DEFB $36,$50,$4F,$49,$55,$59,$0D,$4C
  DEFB $4B,$4A,$48,$20,$02,$4D,$4E,$42
  DEFB $00

; sub_AD18
;
; Used by the routines at l_6FAB, l_A02A and sub_A8DB.
sub_AD18:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,sub_AD18
  RET

; sub_AD21
;
; Used by the routine at l_758A.
sub_AD21:
  LD A,$F7
  IN A,($FE)
  AND $1F
  CP $1B
  RET NZ

; data_AD2A
data_AD2A:
  DEFB $01,$F4,$01,$CD,$B7,$B0,$CD,$18
  DEFB $AD,$C3,$EC,$7C

; sub_AD36
;
; Used by the routines at sub_6EA9, sub_8F54, sub_8F95, sub_9152, sub_94F9,
; l_9A26, sub_9B07, sub_9D7F, sub_9EEE, sub_9FBD, sub_A23A, sub_A2D5, sub_A553,
; sub_A7D6 and sub_AC7D.
sub_AD36:
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,(data_AD51)
  LD DE,$0007
  ADD HL,DE
  LD E,L
  LD D,H
  ADD HL,HL
  ADD HL,HL
  LD C,L
  LD B,H
  ADD HL,HL
  ADD HL,BC
  ADD HL,DE
  LD (data_AD51),HL
  XOR H
  POP BC
  POP DE
  POP HL
  RET

; data_AD51
data_AD51:
  DEFB $00,$00

; sub_AD53
;
; Used by the routines at l_93E2, sub_9B6B, sub_9E4F, sub_9EC1, sub_A62D,
; sub_A817 and sub_A8DB.
sub_AD53:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD C,$00
  LD HL,data_AD82+$000D
  LD B,$06
l_AD5E:
  LD A,(DE)
  ADD A,(HL)
  SUB $30
  ADD A,C
  CP $3A
  LD C,$01
  JR C,l_AD6D
  SUB $0A
  JR l_AD6E
l_AD6D:
  DEC C
l_AD6E:
  LD (HL),A
  DEC HL
  DEC DE
  DJNZ l_AD5E
  XOR A
  LD (l_AE03+$001E),A
  LD HL,data_AD82
  CALL sub_AF2B
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; data_AD82
data_AD82:
  DEFB $E0,$45,$E6,$E0,$D7,$DF,$17,$0E
  DEFB $30,$30,$30,$30,$30,$30,$FF,$30
  DEFB $30,$30,$30,$32,$35,$30,$30,$30
  DEFB $30,$35,$30,$30,$30,$30,$31,$30
  DEFB $30,$30,$30,$30,$31,$32,$35,$30
  DEFB $30,$30,$31,$35,$30,$30,$30,$30
  DEFB $32,$30,$30,$30,$30,$30,$32,$35
  DEFB $30,$30,$30,$30,$33,$30,$30,$30
  DEFB $30,$30,$33,$35,$30,$30,$30,$31
  DEFB $30,$30,$30,$7A,$90,$D6,$09,$FE
  DEFB $F1,$3E,$00,$D8,$7B,$91,$D6,$09
  DEFB $FE,$F1,$3E,$00,$D8,$3C,$C9

; sub_ADE1
;
; Used by the routines at l_6FAB, sub_9152, sub_A817, sub_A8DB, l_AB97 and
; sub_AF2B.
sub_ADE1:
  BIT 5,E
  RET NZ
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,$0000
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
l_AE03:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ l_AE03
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  POP BC
  LD (HL),C
  LD DE,$0900
  ADD HL,DE
  LD (HL),$00
  LD DE,data_C7F4+$320C
  ADD HL,DE
  LD (HL),$00
  POP HL
  POP DE
  POP AF
  RET

; sub_AE26
;
; Used by the routines at sub_7568, sub_8E37, sub_8E67, sub_8F54, sub_A2D5 and
; sub_B0E0.
sub_AE26:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(sub_ADE1+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
l_AE46:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ l_AE46
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  POP BC
  LD (HL),C
  POP HL
  POP DE
  POP AF
  RET

; sub_AE5D
;
; Used by the routine at sub_8F95.
sub_AE5D:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(sub_ADE1+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
l_AE7D:
  LD A,(DE)
  XOR (HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ l_AE7D
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  POP BC
  LD (HL),C
  POP HL
  POP DE
  POP AF
  RET

; l_AE95
l_AE95:
  BIT 5,E
  RET NZ
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(sub_ADE1+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
l_AEB8:
  LD A,(DE)
  XOR (HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ l_AEB8
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD L,E
  LD DE,$5B00
  ADD HL,DE
  POP BC
  LD (HL),$FF
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  POP HL
  POP DE
  POP AF
  CALL sub_94F9
  JP sub_94F9

; l_AEE4
l_AEE4:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(sub_ADE1+$000E)
  ADD HL,BC
  LD A,D
  AND $F8
  OR $40
  LD B,A
  LD A,D
  LD D,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD B,$08
l_AF04:
  LD A,(DE)
  XOR (HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ l_AF04
  DEC D
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD L,E
  LD DE,$5B00
  ADD HL,DE
  POP BC
  LD (HL),$FF
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  LD DE,$0300
  ADD HL,DE
  LD (HL),$00
  POP HL
  POP DE
  POP AF
  RET

; sub_AF2B
;
; Used by the routines at l_6DA1, l_6FAB, l_701E, l_7149, sub_7690, sub_8494,
; sub_91CF, l_93E2, sub_9942, l_A02A, sub_A817, sub_A8DB and sub_AD53.
sub_AF2B:
  LD A,(HL)
  INC HL
  CP $61
  JP NC,l_AF39
  CALL sub_ADE1
  INC E
  JP sub_AF2B
l_AF39:
  CP $90
  JP NC,l_AF49
  SUB $78
  ADD A,D
  LD D,A
  LD A,(HL)
  ADD A,E
  LD E,A
  INC HL
  JP sub_AF2B
l_AF49:
  CP $CF
  JP NC,l_AF56
  INC D
  SUB $AF
  ADD A,E
  LD E,A
  JP sub_AF2B
l_AF56:
  CP $DF
  JP NC,l_AF6F
  SUB $CF
  CP $08
  JP C,l_AF66
  SUB $08
  OR $40
l_AF66:
  LD B,A
  LD A,C
  AND $38
  OR B
  LD C,A
  JP sub_AF2B
l_AF6F:
  CP $DF
  JP NZ,l_AF7B
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  JP sub_AF2B
l_AF7B:
  CP $E0
  JP NZ,l_AF85
  LD C,(HL)
  INC HL
  JP sub_AF2B
l_AF85:
  CP $E1
  JP NZ,l_AF91
  LD B,(HL)
  INC HL
l_AF8C:
  PUSH HL
  PUSH BC
  JP sub_AF2B
l_AF91:
  CP $E2
  JP NZ,l_AFA1
  POP BC
  DJNZ l_AF9D
  POP AF
  JP sub_AF2B
l_AF9D:
  POP HL
  JP l_AF8C
l_AFA1:
  CP $E3
  JP NZ,l_AFB7
  LD A,(HL)
  INC HL
  PUSH HL
  LD H,(HL)
  LD L,A
  PUSH BC
  PUSH DE
  CALL sub_AF2B
  POP DE
  POP BC
  POP HL
  INC HL
  JP sub_AF2B
l_AFB7:
  CP $E4
  JP NZ,l_AFC9
  LD B,(HL)
  INC HL
  LD A,(HL)
l_AFBF:
  CALL sub_ADE1
  INC E
  DJNZ l_AFBF
  INC HL
  JP sub_AF2B
l_AFC9:
  CP $E5
  JP NZ,l_AFDB
  LD B,(HL)
  INC HL
  LD A,(HL)
l_AFD1:
  CALL sub_ADE1
  INC D
  DJNZ l_AFD1
  INC HL
  JP sub_AF2B
l_AFDB:
  CP $E6
  JR NZ,l_AFEC
  LD A,(HL)
  LD (sub_ADE1+$000E),A
  INC HL
  LD A,(HL)
  LD (sub_ADE1+$000F),A
  INC HL
  JP sub_AF2B
l_AFEC:
  CP $E7
  JR NZ,l_B009
  PUSH HL
  LD HL,(sub_ADE1+$000E)
  PUSH HL
  LD HL,data_C7F4+$0FEC
  LD (sub_ADE1+$000E),HL
  LD A,$20
  CALL sub_ADE1
  INC E
  POP HL
  LD (sub_ADE1+$000E),HL
  POP HL
  JP sub_AF2B
l_B009:
  CP $E8
  JR NZ,l_B015
  LD A,(HL)
  LD (l_AE03+$0018),A
  INC HL
  JP sub_AF2B
l_B015:
  CP $E9
  JR NZ,l_B020
  XOR A
  LD (l_AE03+$001E),A
  JP sub_AF2B
l_B020:
  CP $EA
  JR NZ,l_B02C
  LD A,$FF
  LD (l_AE03+$001E),A
  JP sub_AF2B
l_B02C:
  CP $EB
  RET NZ
  LD A,(HL)
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,(l_AFEC+$0012)
  LD BC,sub_ADE1
  SBC HL,BC
  JR NZ,l_B044
  CALL sub_9936
  CALL sub_80C1
  LD (HL),A
l_B044:
  POP HL
  POP DE
  POP BC
  INC HL
  JP sub_AF2B

; sub_B04B
;
; Used by the routines at l_6DA1, l_6FAB, l_758A, sub_A817 and sub_A8DB.
sub_B04B:
  LD C,$00

; sub_B04D
;
; Used by the routine at l_7149.
sub_B04D:
  LD HL,$5AFF
  LD DE,$5AFE
  LD (HL),C
  LD BC,$02FF
  LDDR
  LD (HL),$00
  LD BC,$17FF
  LDDR
  RET

; sub_B061
;
; Used by the routine at sub_8494.
sub_B061:
  LD C,$00
  LD HL,$5800
  LD (HL),C
  LD DE,$5801
  LD BC,$02BF
  LDIR
  LD HL,$4000
  LD B,$B0
l_B074:
  PUSH BC
  PUSH HL
  LD E,L
  LD D,H
  INC DE
  LD (HL),$00
  LD BC,$001F
  LDIR
  POP HL
  CALL sub_B099
  POP BC
  DJNZ l_B074
  RET

; sub_B088
;
; Used by the routines at l_776C, l_79CA, sub_82FC, sub_903D and sub_92FB.
sub_B088:
  PUSH AF
  LD L,D
  LD H,$65
  LD A,(HL)
  INC H
  LD L,(HL)
  LD H,A
  LD A,E
  AND $7C
  RRCA
  RRCA
  ADD A,L
  LD L,A
  POP AF
  RET

; sub_B099
;
; Used by the routines at sub_7BEF and sub_B061.
sub_B099:
  INC H
  LD A,H
  AND $07
  RET NZ
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; data_B0A8
data_B0A8:
  DEFB $7C,$25,$E6,$07,$C0,$7D,$D6,$20
  DEFB $6F,$D8,$7C,$C6,$08,$67,$C9

; sub_B0B7
;
; Used by the routines at l_701E, l_7149, sub_7568, l_758A, l_A02A, sub_A817
; and sub_A8DB.
sub_B0B7:
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,$0000
  LD DE,$0000
  LDIR
  POP HL
  POP DE
  POP BC
  RET

; l_B0C6
;
; Used by the routine at sub_8E7B.
l_B0C6:
  PUSH BC
  PUSH HL
  LD HL,data_C7F4+$0FEC
  LD (sub_ADE1+$000E),HL
  LD B,$64
  CALL sub_B0E0
  LD B,$0A
  CALL sub_B0E0
  LD B,$01
  CALL sub_B0E0
  POP HL
  POP BC
  RET

; sub_B0E0
;
; Used by the routine at l_B0C6.
sub_B0E0:
  LD L,$00
l_B0E2:
  SUB B
  JR C,l_B0E8
  INC L
  JR l_B0E2
l_B0E8:
  ADD A,B
  PUSH AF
  LD A,L
  ADD A,$30
  CALL sub_AE26
  POP AF
  INC E
  RET

; sub_B0F3
;
; Used by the routines at l_6DA1, l_6FAB and sub_8494.
sub_B0F3:
  LD HL,data_B101+$0080
  LD DE,data_B101+$0081
  LD BC,$054F
  LD (HL),$00
  LDIR
  RET

; data_B101
data_B101:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; sub_B6D1
;
; Used by the routine at sub_B6EC.
sub_B6D1:
  LD A,(data_B6DF+$0001)
  LD (data_BA01+$04D4),A
  INC A
  LD (data_BA01+$0484),A
  LD (data_BA01+$0524),A
  RET

; data_B6DF
data_B6DF:
  DEFB $00,$0C,$00,$00,$03,$FF,$00,$01
  DEFB $BA,$7E,$BB,$01,$BA

; sub_B6EC
;
; Used by the routine at l_6DA1.
sub_B6EC:
  LD BC,data_BA01
  LD DE,data_BA01+$017D
  LD HL,data_BA01+$0305
  LD A,$FF
  LD (data_B6DF+$0005),A
  LD (data_B6DF+$0007),BC
  LD (data_B6DF+$0009),DE
  LD (data_B6DF+$000B),HL
  LD IX,data_BA01+$047C
  CALL sub_B730
  LD IX,data_BA01+$04CC
  CALL sub_B730
  LD IX,data_BA01+$051C
  CALL sub_B730
  CALL sub_B6D1
  CALL sub_B753
  LD A,$01
  LD (data_BA01+$047E),A
  LD (data_BA01+$04CE),A
  LD (data_BA01+$051E),A
  XOR A
  LD (data_B6DF+$0005),A
  RET

; sub_B730
;
; Used by the routine at sub_B6EC.
sub_B730:
  LD A,(data_B6DF+$0001)
  LD (IX+$03),A
  XOR A
  LD (IX+$09),A
  LD (IX+$0C),A
  LD (IX+$0D),A
  LD (IX+$00),A
  LD (IX+$01),A
  LD (IX+$02),$01
  LD (IX+$04),$05
  LD (IX+$05),$05
  RET

; sub_B753
;
; Used by the routines at l_6FAB, l_758A, sub_B6EC and l_B9F7.
sub_B753:
  LD A,$B8
  LD (data_B6DF+$0006),A
  LD C,A
  LD A,$07
  LD E,$04
l_B75D:
  CALL sub_BF6D
  LD C,$00
  INC A
  DEC E
  JR NZ,l_B75D
  RET

; sub_B767
;
; Used by the routine at sub_6F1F.
sub_B767:
  XOR A
  LD (data_B6DF+$0002),A
  LD A,(data_B6DF+$0005)
  OR A
  JR NZ,l_B79E
  LD IX,data_BA01+$047C
  LD IY,(data_B6DF+$0007)
  CALL sub_B79F
  LD (data_B6DF+$0007),IY
  LD IX,data_BA01+$04CC
  LD IY,(data_B6DF+$0009)
  CALL sub_B79F
  LD (data_B6DF+$0009),IY
  LD IX,data_BA01+$051C
  LD IY,(data_B6DF+$000B)
  CALL sub_B79F
  LD (data_B6DF+$000B),IY

; l_B79E
;
; Used by the routines at sub_B767 and l_B9F7.
l_B79E:
  RET

; sub_B79F
;
; Used by the routine at sub_B767.
sub_B79F:
  LD A,(IX+$0D)
  OR A
  JR Z,l_B7AE
  LD (IX+$0D),$00
  CALL sub_B88F
  JR l_B7B4
l_B7AE:
  DEC (IX+$02)
  JP Z,sub_B88F
l_B7B4:
  DEC (IX+$1B)
  JP NZ,l_B822
  LD A,(IX+$19)
  ADD A,(IX+$1D)
  LD (IX+$19),A
  DEC (IX+$1C)
  JR NZ,l_B7F8
  LD A,(IX+$1A)
  ADD A,$03
  LD (IX+$1A),A
  CP (IX+$1F)
  JR NZ,l_B7D9
  XOR A
  LD (IX+$1A),A
l_B7D9:
  ADD A,$20
  LD (l_B7D9+$000F),A
  INC A
  LD (l_B7D9+$0015),A
  INC A
  LD (l_B7D9+$001B),A
  LD A,(IX+$00)
  LD (IX+$1C),A
  LD A,(IX+$00)
  LD (IX+$1D),A
  LD A,(IX+$00)
  LD (IX+$1E),A
l_B7F8:
  LD A,(IX+$1E)
  LD (IX+$1B),A
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,L
  OR H
  JR Z,l_B815
  LD D,$FF
  LD A,(IX+$19)
  OR A
  JP M,l_B813
  LD D,$00
l_B813:
  LD E,A
  ADD HL,DE
l_B815:
  LD A,(IX+$06)
  INC A
  LD C,H
  CALL sub_BF6D
  DEC A
  LD C,L
  CALL sub_BF6D
l_B822:
  DEC (IX+$36)
  JR NZ,l_B88E
  LD A,(IX+$03)
  ADD A,(IX+$38)
  JP P,l_B831
  XOR A
l_B831:
  LD (IX+$03),A
  LD A,(IX+$08)
  CP (IX+$03)
  JR NC,l_B83F
  LD (IX+$03),A
l_B83F:
  DEC (IX+$37)
  JR NZ,l_B87E
  LD A,(IX+$35)
  ADD A,$03
  LD (IX+$35),A
  CP (IX+$3A)
  JR NZ,l_B85F
  LD (IX+$38),$00
  LD (IX+$37),$FF
  LD (IX+$39),$FF
  JR l_B87E
l_B85F:
  ADD A,$3B
  LD (l_B85F+$000F),A
  INC A
  LD (l_B85F+$0015),A
  INC A
  LD (l_B85F+$001B),A
  LD A,(IX+$00)
  LD (IX+$37),A
  LD A,(IX+$00)
  LD (IX+$38),A
  LD A,(IX+$00)
  LD (IX+$39),A
l_B87E:
  LD A,(IX+$39)
  LD (IX+$36),A
  LD A,(IX+$03)
  LD C,A
  LD A,(IX+$07)
  JP sub_BF6D
l_B88E:
  RET

; sub_B88F
;
; Used by the routine at sub_B79F.
sub_B88F:
  LD A,(data_B6DF+$0002)
  OR A
  JR Z,l_B899
  LD (IX+$0D),A
  RET
l_B899:
  DEC A
  LD (data_B6DF+$0002),A
; This entry point is used by the routines at l_B944 and l_B9D8.
l_B89D:
  LD A,(IY+$00)
  CP $32
  JR NC,l_B8FC
l_B8A4:
  OR A
  JR Z,l_B8AA
  ADD A,(IX+$09)
l_B8AA:
  LD L,A
  SLA L
  LD H,$00
  PUSH DE
  LD DE,data_C218+$0503
  ADD HL,DE
  POP DE
  LD A,(HL)
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  LD (IX+$01),A
  LD A,(IX+$0A)
  LD (IX+$02),A
  LD (IX+$03),$00
  INC IY
  LD (IX+$05),$01
  LD (IX+$19),$00
  LD (IX+$1B),$01
  LD (IX+$1C),$01
  LD (IX+$1A),$FD
  LD (IX+$1D),$00
  LD A,(IX+$3B)
  LD (IX+$37),A
  LD A,(IX+$3C)
  LD (IX+$38),A
  LD A,(IX+$3D)
  LD (IX+$39),A
  LD (IX+$36),A
  LD (IX+$35),$00
  RET
l_B8FC:
  CP $64
  JR NC,l_B90F
  LD A,(IY+$01)
  LD (IX+$0A),A
  LD A,(IY+$00)
  INC IY
  SUB $32
  JR l_B8A4
l_B90F:
  CP $64
  JR NZ,l_B926
  LD HL,data_B6DF+$0006
  LD A,(HL)
  XOR (IX+$0B)
  LD (HL),A
  LD C,A
  LD A,$07
  CALL sub_BF6D
  INC IY
  JP l_B89D
l_B926:
  CP $79
  JR NZ,l_B939
  INC IY
  LD C,(IY+$00)
  LD A,$06
  CALL sub_BF6D
  INC IY
  JP l_B89D
l_B939:
  CP $75
  JR NC,l_B944

; data_B93D
data_B93D:
  DEFB $D6,$65,$DD,$77,$08,$18,$DD

; l_B944
;
; Used by the routine at sub_B88F.
l_B944:
  CP $75
  JR NZ,l_B974
  LD L,(IY+$01)
  LD H,(IY+$02)
  INC IY
  INC IY
  INC IY
  PUSH IY
  POP BC
  LD A,(IX+$0C)
  SLA A
  ADD A,$0E
  LD (l_B944+$0023),A
  INC A
  LD (l_B944+$0026),A
  LD (IX+$00),C
  LD (IX+$01),B
  INC (IX+$0C)
  PUSH HL
  POP IY
  JP l_B89D
l_B974:
  CP $76
  JR NZ,l_B995
  DEC (IX+$0C)
  LD A,(IX+$0C)
  SLA A
  ADD A,$0E
  LD (l_B974+$0017),A
  INC A
  LD (l_B974+$001A),A
  LD C,(IX+$00)
  LD B,(IX+$01)
  PUSH BC
  POP IY
  JP l_B89D
l_B995:
  CP $77
  JR NZ,l_B9A6

; data_B999
data_B999:
  DEFB $FD,$23,$FD,$7E,$00,$DD,$77,$09
  DEFB $FD,$23,$C3,$9D,$B8

; l_B9A6
;
; Used by the routine at l_B944.
l_B9A6:
  CP $78
  JR NZ,l_B9B6

; data_B9AA
data_B9AA:
  DEFB $FD,$6E,$01,$FD,$66,$02,$E5,$FD
  DEFB $E1,$C3,$9D,$B8

; l_B9B6
;
; Used by the routine at l_B9A6.
l_B9B6:
  CP $FF
  JR Z,l_B9F7
  CP $89
  JR NZ,l_B9D8

; data_B9BE
data_B9BE:
  DEFB $FD,$23,$FD,$7E,$00,$47,$04,$DD
  DEFB $E5,$FD,$7E,$00,$DD,$77,$1F,$FD
  DEFB $23,$DD,$23,$10,$F4,$DD,$E1,$C3
  DEFB $9D,$B8

; l_B9D8
;
; Used by the routine at l_B9B6.
l_B9D8:
  CP $8A
  JR NZ,data_B9F6
  INC IY
  LD A,(IY+$00)
  LD B,A
  INC B
  PUSH IX
l_B9E5:
  LD A,(IY+$00)
  LD (IX+$3A),A
  INC IY
  INC IX
  DJNZ l_B9E5
  POP IX
  JP l_B89D

; data_B9F6
;
; Used by the routine at l_B9D8.
data_B9F6:
  DEFB $C9

; l_B9F7
;
; Used by the routine at l_B9B6.
l_B9F7:
  LD (data_B6DF+$0005),A
  CALL sub_B753
  POP AF
  JP l_B79E

; data_BA01
data_BA01:
  DEFB $75,$F3,$BD,$75,$54,$BB,$75,$41
  DEFB $BB,$75,$41,$BB,$75,$32,$BB,$75
  DEFB $32,$BB,$75,$04,$BB,$75,$32,$BB
  DEFB $75,$32,$BB,$75,$04,$BB,$75,$D6
  DEFB $BA,$75,$32,$BB,$75,$32,$BB,$75
  DEFB $32,$BB,$75,$32,$BB,$75,$C9,$BA
  DEFB $75,$C9,$BA,$75,$AE,$BA,$75,$32
  DEFB $BB,$75,$32,$BB,$75,$32,$BB,$75
  DEFB $32,$BB,$75,$A1,$BA,$75,$A1,$BA
  DEFB $75,$92,$BA,$75,$92,$BA,$75,$75
  DEFB $BA,$75,$58,$BA,$4E,$A0,$FF,$55
  DEFB $14,$24,$53,$0A,$55,$14,$21,$23
  DEFB $1F,$51,$0A,$53,$14,$51,$14,$21
  DEFB $50,$0A,$51,$14,$1E,$1F,$1C,$4E
  DEFB $0A,$50,$14,$76,$50,$14,$1F,$4E
  DEFB $0A,$50,$14,$1E,$1F,$1C,$4E,$0A
  DEFB $50,$14,$50,$14,$1F,$4E,$0A,$50
  DEFB $14,$1B,$1C,$1E,$51,$0A,$53,$14
  DEFB $76,$4E,$14,$1D,$4C,$0A,$4E,$14
  DEFB $1C,$1D,$1A,$4C,$0A,$4E,$14,$76
  DEFB $4C,$14,$1C,$4A,$0A,$4C,$14,$17
  DEFB $18,$15,$49,$1E,$76,$50,$14,$1F
  DEFB $4E,$0A,$50,$14,$1B,$1C,$19,$4D
  DEFB $1E,$50,$14,$1F,$4E,$0A,$50,$14
  DEFB $1B,$1C,$1E,$51,$0A,$53,$14,$76
  DEFB $51,$14,$21,$50,$0A,$51,$14,$1C
  DEFB $1E,$1A,$4E,$1E,$76,$75,$71,$BE
  DEFB $4A,$28,$15,$4A,$1E,$18,$4E,$0A
  DEFB $1A,$4A,$28,$13,$4A,$1E,$18,$4E
  DEFB $0A,$1A,$4A,$28,$18,$4A,$1E,$18
  DEFB $4E,$0A,$1A,$4A,$28,$18,$4A,$0A
  DEFB $1C,$18,$1C,$1F,$1C,$1F,$23,$75
  DEFB $05,$BE,$76,$75,$EA,$BD,$53,$14
  DEFB $53,$0A,$75,$05,$BE,$51,$32,$51
  DEFB $14,$4A,$0A,$53,$14,$4A,$0A,$51
  DEFB $14,$75,$EA,$BD,$4E,$14,$4E,$0A
  DEFB $75,$05,$BE,$4C,$32,$4C,$14,$45
  DEFB $0A,$4E,$14,$45,$0A,$4C,$0A,$13
  DEFB $76,$55,$14,$24,$53,$0A,$55,$14
  DEFB $1F,$21,$1E,$55,$0A,$4E,$14,$76
  DEFB $51,$28,$51,$1E,$23,$55,$14,$21
  DEFB $1F,$51,$28,$51,$1E,$23,$55,$14
  DEFB $21,$1F,$76,$75,$5F,$BB,$51,$14
  DEFB $75,$5F,$BB,$53,$14,$76,$51,$0A
  DEFB $1A,$1F,$23,$58,$14,$1A,$1C,$56
  DEFB $0A,$23,$24,$23,$53,$1E,$50,$0A
  DEFB $1F,$53,$14,$50,$0A,$4C,$14,$24
  DEFB $56,$0A,$55,$1E,$76,$75,$E1,$BD
  DEFB $64,$75,$E7,$BC,$75,$E7,$BC,$75
  DEFB $E7,$BC,$75,$E7,$BC,$64,$75,$F3
  DEFB $BD,$75,$C6,$BC,$75,$C6,$BC,$75
  DEFB $B7,$BC,$75,$B7,$BC,$75,$89,$BC
  DEFB $75,$B7,$BC,$75,$B7,$BC,$75,$89
  DEFB $BC,$75,$61,$BC,$75,$B7,$BC,$75
  DEFB $B7,$BC,$75,$B7,$BC,$75,$B7,$BC
  DEFB $75,$54,$BC,$75,$54,$BC,$75,$39
  DEFB $BC,$75,$B7,$BC,$75,$B7,$BC,$75
  DEFB $B7,$BC,$75,$B7,$BC,$75,$2C,$BC
  DEFB $75,$2C,$BC,$75,$1D,$BC,$75,$1D
  DEFB $BC,$75,$00,$BC,$75,$E3,$BB,$49
  DEFB $A0,$FF,$51,$14,$21,$50,$0A,$51
  DEFB $14,$1E,$1F,$1C,$4E,$0A,$50,$14
  DEFB $4E,$14,$1E,$4C,$0A,$4E,$14,$1B
  DEFB $1C,$19,$4B,$0A,$4D,$14,$76,$4D
  DEFB $14,$1C,$4B,$0A,$4D,$14,$1B,$1C
  DEFB $19,$4B,$0A,$4D,$14,$4D,$14,$1C
  DEFB $4B,$0A,$4D,$14,$17,$19,$1B,$4E
  DEFB $0A,$50,$14,$76,$4A,$14,$1A,$49
  DEFB $0A,$4A,$14,$18,$1A,$17,$49,$0A
  DEFB $4A,$14,$76,$49,$14,$18,$47,$0A
  DEFB $49,$14,$13,$15,$12,$45,$1E,$76
  DEFB $4D,$14,$1C,$4B,$0A,$4D,$14,$17
  DEFB $19,$15,$49,$1E,$4D,$14,$1C,$4B
  DEFB $0A,$4D,$14,$17,$19,$1B,$4E,$0A
  DEFB $50,$14,$76,$4E,$14,$1E,$4C,$0A
  DEFB $4E,$14,$18,$1A,$17,$4A,$1E,$76
  DEFB $75,$71,$BE,$32,$28,$15,$32,$14
  DEFB $47,$1E,$15,$32,$28,$13,$32,$14
  DEFB $45,$1E,$13,$32,$14,$15,$00,$15
  DEFB $32,$14,$47,$1E,$15,$32,$14,$13
  DEFB $00,$13,$32,$50,$75,$05,$BE,$76
  DEFB $75,$EA,$BD,$4F,$14,$4F,$0A,$75
  DEFB $05,$BE,$4E,$32,$4E,$14,$4A,$0A
  DEFB $4F,$14,$4A,$0A,$4E,$14,$75,$EA
  DEFB $BD,$4A,$14,$4A,$0A,$75,$05,$BE
  DEFB $49,$32,$49,$14,$45,$0A,$4A,$14
  DEFB $45,$0A,$49,$0A,$13,$76,$51,$14
  DEFB $21,$50,$0A,$51,$14,$1C,$1E,$1A
  DEFB $50,$0A,$49,$14,$76,$4E,$14,$17
  DEFB $1C,$49,$0A,$51,$14,$49,$0A,$1F
  DEFB $17,$1E,$17,$1C,$17,$4E,$14,$18
  DEFB $1C,$4A,$0A,$51,$14,$4A,$0A,$1F
  DEFB $18,$1E,$18,$1C,$18,$76,$79,$1F
  DEFB $32,$14,$00,$00,$32,$05,$79,$0F
  DEFB $00,$79,$1F,$00,$79,$0F,$00,$79
  DEFB $1F,$32,$14,$00,$00,$79,$1F,$32
  DEFB $0A,$79,$0F,$00,$76,$75,$5F,$BE
  DEFB $75,$DB,$BD,$75,$DB,$BD,$75,$D7
  DEFB $BD,$75,$D7,$BD,$75,$5E,$BD,$75
  DEFB $5E,$BD,$75,$BC,$BD,$75,$5E,$BD
  DEFB $75,$5E,$BD,$75,$BC,$BD,$75,$AF
  DEFB $BD,$75,$A7,$BD,$75,$A7,$BD,$75
  DEFB $A7,$BD,$75,$D1,$BD,$75,$95,$BD
  DEFB $75,$9E,$BD,$75,$8A,$BD,$75,$8A
  DEFB $BD,$75,$8A,$BD,$75,$8A,$BD,$75
  DEFB $6F,$BD,$75,$6F,$BD,$75,$78,$BD
  DEFB $75,$78,$BD,$75,$81,$BD,$75,$81
  DEFB $BD,$75,$65,$BD,$FF,$75,$68,$BE
  DEFB $36,$50,$10,$76,$42,$50,$0E,$0C
  DEFB $0B,$75,$05,$BE,$10,$76,$75,$68
  DEFB $BE,$39,$8C,$45,$0A,$07,$76,$75
  DEFB $68,$BE,$3E,$8C,$4A,$0A,$0C,$76
  DEFB $75,$68,$BE,$3D,$8C,$49,$0A,$0B
  DEFB $76,$75,$68,$BE,$42,$78,$3D,$14
  DEFB $42,$0A,$0B,$76,$3E,$78,$39,$28
  DEFB $3E,$78,$39,$28,$76,$3D,$78,$38
  DEFB $28,$3D,$78,$3D,$28,$76,$75,$68
  DEFB $BE,$42,$78,$3D,$28,$76,$75,$71
  DEFB $BE,$43,$50,$11,$10,$10,$11,$11
  DEFB $10,$10,$76,$75,$EA,$BD,$3E,$14
  DEFB $75,$4D,$BE,$3E,$8C,$75,$EA,$BD
  DEFB $39,$14,$75,$4D,$BE,$39,$8C,$76
  DEFB $75,$68,$BE,$36,$A0,$76,$42,$A0
  DEFB $0C,$76,$39,$50,$0C,$0E,$07,$76
  DEFB $8A,$06,$01,$0F,$01,$0F,$FF,$01
  DEFB $76,$8A,$06,$01,$0F,$01,$0F,$FF
  DEFB $02,$76,$8A,$06,$02,$07,$01,$0F
  DEFB $FF,$03,$76,$8A,$06,$02,$07,$01
  DEFB $0F,$FF,$04,$76,$8A,$06,$02,$07
  DEFB $01,$0F,$FF,$05,$76,$8A,$06,$02
  DEFB $07,$01,$0F,$FF,$06,$76,$8A,$06
  DEFB $02,$07,$01,$0F,$FF,$07,$76,$8A
  DEFB $06,$02,$07,$01,$0F,$FF,$08,$76
  DEFB $8A,$06,$02,$07,$01,$0F,$FF,$09
  DEFB $76,$8A,$06,$02,$07,$01,$0F,$FF
  DEFB $0A,$76,$8A,$06,$02,$07,$01,$0F
  DEFB $FF,$0B,$76,$8A,$06,$02,$07,$01
  DEFB $0F,$FF,$0C,$76,$8A,$06,$02,$07
  DEFB $01,$0F,$FF,$0D,$76,$8A,$06,$02
  DEFB $07,$01,$0F,$FF,$0E,$76,$8A,$06
  DEFB $02,$07,$01,$0F,$FF,$0F,$76,$8A
  DEFB $06,$04,$04,$01,$0F,$FF,$17,$76
  DEFB $8A,$09,$01,$0F,$01,$03,$FF,$05
  DEFB $32,$00,$32,$76,$3C,$00,$1E,$0A
  DEFB $05,$05,$00,$08,$0F,$00,$1E,$09
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$01
  DEFB $01,$00,$00,$09,$02,$01,$02,$04
  DEFB $FF,$02,$02,$01,$02,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$01,$00,$00,$06,$03
  DEFB $05,$01,$0F,$FF,$03,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$3C,$00,$1E,$0A
  DEFB $04,$04,$02,$09,$0F,$00,$1E,$12
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$01
  DEFB $01,$00,$00,$09,$03,$01,$01,$06
  DEFB $FF,$01,$03,$01,$01,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$01,$00,$00,$06,$03
  DEFB $05,$01,$0F,$FF,$03,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$3C,$00,$1E,$0F
  DEFB $04,$04,$04,$0A,$0F,$00,$1E,$24
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$01
  DEFB $01,$00,$00,$09,$03,$01,$01,$06
  DEFB $FF,$01,$03,$01,$01,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$01,$00,$00,$06,$03
  DEFB $05,$01,$0F,$FF,$03,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; sub_BF6D
;
; Used by the routines at sub_B753, sub_B79F, sub_B88F, sub_BF7E, l_C097,
; l_C0B1 and l_C0CC.
sub_BF6D:
  PUSH AF
  PUSH BC
  PUSH HL
  LD H,C
  LD BC,$FFFD
  OUT (C),A
  LD B,$BF
  OUT (C),H
  POP HL
  POP BC
  POP AF
  RET

; sub_BF7E
;
; Used by the routine at l_758A.
sub_BF7E:
  XOR A
  LD (data_C218+$03D2),A
  LD A,$BF
  LD (data_C218+$03D1),A
  LD A,$F6
  LD (data_C218+$03CF),A
  LD IX,data_C218+$03D3
  LD B,$10
l_BF92:
  PUSH IX
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JR Z,l_BFA4
  CALL sub_BFBF
  LD HL,data_C218+$03CF
  RLC (HL)
l_BFA4:
  POP BC
  POP IX
  LD DE,$0010
  ADD IX,DE
  DJNZ l_BF92
  LD A,$06
  LD BC,(data_C218+$03D0)
  CALL sub_BF6D
  LD BC,(data_C218+$03D1)
  INC A
  JP sub_BF6D

; sub_BFBF
;
; Used by the routine at sub_BF7E.
sub_BFBF:
  DEC (IX+$03)
  CALL Z,sub_BFE1
  DEC (IX+$06)
  JP NZ,l_BFDE
  LD A,(IX+$07)
  LD (IX+$06),A
  LD A,(IX+$04)
  OR A
  JP Z,l_BFDE
  SUB (IX+$08)
  LD (IX+$04),A
l_BFDE:
  JP l_C05A

; sub_BFE1
;
; Used by the routine at sub_BFBF.
sub_BFE1:
  LD L,(IX+$01)
  LD H,(IX+$02)
; This entry point is used by the routine at l_C015.
l_BFE7:
  LD A,(HL)
  CP $FF
  JR NZ,l_BFF2
  LD (IX+$00),$FF
  POP AF
  RET
l_BFF2:
  CP $FE
  JR NZ,l_BFFE
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  INC HL
  JR l_BFE7
l_BFFE:
  CP $FD
  JR NZ,l_C015

; data_C002
data_C002:
  DEFB $23,$7E,$DD,$77,$07,$CB,$3F,$3C
  DEFB $DD,$77,$06,$23,$7E,$DD,$77,$08
  DEFB $23,$18,$D2

; l_C015
;
; Used by the routine at sub_BFE1.
l_C015:
  CP $FC
  JR NZ,l_C021
  INC HL
  LD A,(HL)
  LD (IX+$0B),A
  INC HL
  JR l_BFE7
l_C021:
  CP $FB
  JR NZ,l_C02A
  INC HL
  LD A,(HL)
  LD (data_C218+$03D0),A
l_C02A:
  CP $60
  JR C,l_C035
  SUB $60
  INC HL
  LD C,(HL)
  LD (IX+$0C),C
l_C035:
  INC HL
  LD (IX+$01),L
  LD (IX+$02),H
  LD L,A
  LD H,$00
  ADD HL,HL
  LD DE,data_C218+$04D3
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$09),E
  LD (IX+$0A),D
  LD A,(IX+$0C)
  LD (IX+$03),A
  LD A,(IX+$05)
  LD (IX+$04),A
  RET

; l_C05A
;
; Used by the routine at sub_BFBF.
l_C05A:
  LD A,(data_C218+$03D2)
  LD L,A
  INC A
  LD (data_C218+$03D2),A
  LD H,$00
  ADD HL,HL
  LD DE,data_C077
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD E,(IX+$09)
  LD D,(IX+$0A)
  LD C,(IX+$04)
  JP (HL)

; data_C077
data_C077:
  DEFB $97,$C0,$B1,$C0,$CC,$C0,$F3,$C7
  DEFB $F3,$C7,$F3,$C7,$F3,$C7,$F3,$C7
  DEFB $F3,$C7,$F3,$C7,$F3,$C7,$F3,$C7
  DEFB $F3,$C7,$F3,$C7,$F3,$C7,$F3,$C7

; l_C097
l_C097:
  LD HL,data_C218+$03D1
  LD A,(data_C218+$03CF)
  OR (IX+$0B)
  AND (HL)
  LD (HL),A
  LD A,$08
  CALL sub_BF6D
  XOR A
  LD C,E
  CALL sub_BF6D
  INC A
  LD C,D
  JP sub_BF6D

; l_C0B1
l_C0B1:
  LD HL,data_C218+$03D1
  LD A,(data_C218+$03CF)
  OR (IX+$0B)
  AND (HL)
  LD (HL),A
  LD A,$09
  CALL sub_BF6D
  LD A,$02
  LD C,E
  CALL sub_BF6D
  INC A
  LD C,D
  JP sub_BF6D

; l_C0CC
l_C0CC:
  LD HL,data_C218+$03D1
  LD A,(data_C218+$03CF)
  OR (IX+$0B)
  AND (HL)
  LD (HL),A
  LD A,$0A
  CALL sub_BF6D
  LD A,$04
  LD C,E
  CALL sub_BF6D
  INC A
  LD C,D
  JP sub_BF6D

; sub_C0E7
;
; Used by the routine at sub_83DD.
sub_C0E7:
  PUSH AF
  PUSH BC
  LD A,$0D
  LD BC,$C264
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C0F4
;
; Used by the routines at sub_9942 and sub_9F2D.
sub_C0F4:
  PUSH AF
  PUSH BC
  LD A,$02
  LD BC,data_C218
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C101
;
; Used by the routine at sub_9942.
sub_C101:
  PUSH AF
  PUSH BC
  LD A,$02
  LD BC,$C23E
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; data_C10E
data_C10E:
  DEFB $3E,$04,$01,$5D,$C5,$C3,$D3,$C1
  DEFB $3E,$0E,$01,$4D,$C5,$CD,$D3,$C1
  DEFB $3E,$05,$01,$6D,$C5,$C3,$D3,$C1
  DEFB $3E,$0D,$01,$BA,$C5,$C3,$D3,$C1

; sub_C12E
;
; Used by the routines at sub_9EAF and sub_A30B.
sub_C12E:
  PUSH AF
  PUSH BC
  LD A,$05
  LD BC,$C280
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C13B
;
; Used by the routine at l_9DA8.
sub_C13B:
  PUSH AF
  PUSH BC
  LD A,$07
  LD BC,$C2C7
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C148
;
; Used by the routines at sub_9071, sub_9152 and l_93E2.
sub_C148:
  PUSH AF
  PUSH BC
  LD A,$06
  LD BC,$C305
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C155
;
; Used by the routines at sub_9B6B, sub_9BB4, sub_9E4F, sub_9E64 and sub_A62D.
sub_C155:
  PUSH AF
  PUSH BC
  LD A,$08
  LD BC,$C33E
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C162
;
; Used by the routine at sub_98BA.
sub_C162:
  PUSH AF
  PUSH BC
  LD A,$0D
  LD BC,$C462
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; data_C16F
data_C16F:
  DEFB $3E,$0C,$01,$C8,$C5,$C3,$D3,$C1

; sub_C177
;
; Used by the routine at sub_8338.
sub_C177:
  LD A,$0F
  LD BC,$C5A1
  JP sub_C1D3

; data_C17F
data_C17F:
  DEFB $3E,$08,$01,$77,$C5,$CD,$D3,$C1
  DEFB $3C,$01,$85,$C5,$CD,$D3,$C1,$3C
  DEFB $01,$93,$C5,$C3,$D3,$C1,$F5,$C5
  DEFB $AF,$01,$4A,$C4,$CD,$D3,$C1,$3E
  DEFB $0F,$01,$3F,$C5,$CD,$D3,$C1,$C1
  DEFB $F1,$C9

; sub_C1A9
;
; Used by the routine at sub_ABCF.
sub_C1A9:
  PUSH AF
  PUSH BC
  LD A,$01
  LD BC,$C35C
  CALL sub_C1D3
  LD A,$0B
  LD BC,$C361
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C1BE
;
; Used by the routine at l_9237.
sub_C1BE:
  PUSH AF
  PUSH BC
  LD A,$09
  LD BC,$C366
  CALL sub_C1D3
  LD A,$0F
  LD BC,$C3D8
  CALL sub_C1D3
  POP BC
  POP AF
  RET

; sub_C1D3
;
; Used by the routines at sub_C0E7, sub_C0F4, sub_C101, sub_C12E, sub_C13B,
; sub_C148, sub_C155, sub_C162, sub_C177, sub_C1A9 and sub_C1BE.
sub_C1D3:
  PUSH IX
  PUSH HL
  PUSH DE
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,data_C218+$03D3
  ADD HL,DE
  PUSH HL
  POP IX
  LD (IX+$00),$FF
  LD (IX+$01),C
  LD (IX+$02),B
  LD (IX+$03),$01
  LD (IX+$04),$0F
  LD (IX+$05),$0F
  LD (IX+$08),$01
  LD (IX+$09),$00
  LD (IX+$0A),$00
  LD (IX+$0B),$38
  LD (IX+$0C),$01
  LD (IX+$00),$00
  POP DE
  POP HL
  POP IX
  RET

; data_C218
data_C218:
  DEFB $FE,$0D,$AF,$03,$47,$3F,$37,$FE
  DEFB $0B,$4F,$47,$3F,$37,$FE,$09,$4F
  DEFB $47,$3F,$37,$FE,$07,$4F,$47,$3F
  DEFB $37,$FE,$05,$4F,$47,$3F,$37,$FE
  DEFB $03,$4F,$47,$3F,$37,$FF,$FE,$0D
  DEFB $B4,$03,$4C,$44,$3C,$FE,$0B,$54
  DEFB $4C,$44,$3C,$FE,$09,$54,$4C,$44
  DEFB $3C,$FE,$07,$54,$4C,$44,$3C,$FE
  DEFB $05,$54,$4C,$44,$3C,$FE,$03,$54
  DEFB $4C,$44,$3C,$FF,$FC,$00,$FE,$0D
  DEFB $FB,$00,$AB,$01,$FE,$0C,$4B,$FE
  DEFB $0B,$4B,$FE,$0A,$4B,$FE,$05,$AB
  DEFB $03,$FE,$04,$4B,$FE,$03,$4B,$FF
  DEFB $FE,$0C,$9C,$03,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C
  DEFB $00,$3C,$00,$3C,$00,$3C,$FF,$FC
  DEFB $07,$FE,$0E,$FB,$00,$63,$01,$FB
  DEFB $02,$01,$FB,$04,$01,$FB,$06,$01
  DEFB $FB,$08,$01,$FB,$0A,$01,$FB,$0C
  DEFB $01,$FB,$0E,$01,$FB,$10,$01,$FB
  DEFB $12,$01,$FB,$14,$01,$FB,$16,$01
  DEFB $FE,$08,$FB,$18,$01,$FE,$06,$FB
  DEFB $1A,$01,$FE,$04,$FB,$1C,$01,$FE
  DEFB $02,$FB,$1E,$01,$FF,$FC,$00,$FB
  DEFB $1F,$FE,$0F,$88,$02,$27,$26,$25
  DEFB $24,$FE,$0E,$23,$22,$FE,$0D,$21
  DEFB $20,$FE,$0C,$1F,$FE,$0B,$1E,$FE
  DEFB $0A,$1D,$FE,$09,$1C,$FE,$08,$1A
  DEFB $FE,$07,$18,$FE,$06,$16,$FE,$05
  DEFB $14,$FE,$04,$12,$FE,$03,$10,$FE
  DEFB $02,$0E,$FE,$01,$0C,$FF,$FC,$00
  DEFB $FB,$00,$FE,$0E,$92,$01,$FE,$0D
  DEFB $30,$FE,$0C,$2E,$FE,$0B,$2C,$FE
  DEFB $09,$2A,$FE,$07,$28,$FE,$05,$26
  DEFB $FE,$03,$24,$FF,$FE,$0C,$61,$0A
  DEFB $FF,$FE,$0C,$62,$0A,$FF,$FE,$01
  DEFB $AF,$01,$FE,$03,$4E,$FE,$05,$4D
  DEFB $FE,$07,$4C,$FE,$09,$4B,$FE,$0B
  DEFB $4A,$FE,$0D,$49,$FE,$0F,$48,$47
  DEFB $46,$45,$FE,$0E,$44,$43,$42,$41
  DEFB $FE,$0D,$40,$3F,$3E,$3D,$FE,$0C
  DEFB $3C,$3B,$3A,$39,$FE,$0B,$38,$37
  DEFB $36,$35,$FE,$0A,$34,$33,$32,$31
  DEFB $FE,$09,$30,$2F,$2E,$2D,$FE,$08
  DEFB $2C,$2B,$2A,$29,$FE,$07,$28,$27
  DEFB $26,$25,$FE,$06,$24,$23,$22,$21
  DEFB $FE,$05,$20,$1F,$1E,$1D,$FE,$04
  DEFB $1C,$1B,$1A,$19,$FE,$03,$18,$17
  DEFB $16,$15,$FE,$02,$14,$14,$13,$12
  DEFB $FE,$01,$11,$10,$0F,$0E,$0D,$FF
  DEFB $FE,$01,$9B,$01,$FE,$03,$3A,$FE
  DEFB $05,$39,$FE,$07,$38,$FE,$09,$37
  DEFB $FE,$0B,$36,$FE,$0D,$35,$FE,$0F
  DEFB $34,$33,$32,$31,$FE,$0E,$30,$2F
  DEFB $2E,$2D,$FE,$0D,$2C,$2B,$2A,$29
  DEFB $FE,$0C,$28,$27,$26,$25,$FE,$0B
  DEFB $24,$23,$22,$21,$FE,$0A,$20,$1F
  DEFB $1E,$1D,$FE,$09,$1C,$1B,$1A,$19
  DEFB $FE,$08,$18,$17,$16,$15,$FE,$07
  DEFB $14,$13,$12,$11,$FE,$06,$10,$0F
  DEFB $0E,$0D,$FE,$05,$0C,$0B,$0A,$13
  DEFB $FE,$04,$12,$11,$10,$0F,$FE,$03
  DEFB $0E,$0D,$0C,$0B,$FE,$02,$0A,$0A
  DEFB $09,$08,$FE,$01,$07,$06,$05,$04
  DEFB $03,$FF,$FE,$0F,$9C,$02,$40,$43
  DEFB $3B,$3F,$42,$3A,$3E,$41,$39,$3D
  DEFB $40,$38,$3C,$3F,$37,$3B,$3E,$9C
  DEFB $06,$FF,$FC,$00,$FE,$0F,$9C,$01
  DEFB $FE,$0E,$3C,$FE,$0D,$3C,$FE,$0C
  DEFB $3C,$FE,$0F,$3C,$01,$FE,$0E,$3C
  DEFB $FE,$0D,$3C,$FE,$0C,$3C,$FE,$0E
  DEFB $3C,$FE,$0D,$3C,$FE,$0C,$3C,$FE
  DEFB $0B,$3C,$FE,$0E,$3C,$FE,$0D,$3C
  DEFB $FE,$0C,$3C,$FE,$0B,$3C,$FE,$0D
  DEFB $3C,$FE,$0C,$3C,$FE,$0B,$3C,$FE
  DEFB $0A,$3C,$FE,$0D,$3C,$FE,$0C,$3C
  DEFB $FE,$0B,$3C,$FE,$0A,$3C,$FE,$0C
  DEFB $3C,$FE,$0B,$3C,$FE,$0A,$3C,$FE
  DEFB $09,$3C,$FE,$0C,$3C,$FE,$0B,$3C
  DEFB $FE,$0A,$3C,$FE,$09,$3C,$FE,$0B
  DEFB $3C,$FE,$0A,$3C,$FE,$09,$3C,$FE
  DEFB $08,$3C,$FE,$0B,$3C,$FE,$0A,$3C
  DEFB $FE,$09,$3C,$FE,$08,$3C,$FE,$0A
  DEFB $3C,$FE,$09,$3C,$FE,$08,$3C,$FE
  DEFB $07,$3C,$FE,$0A,$3C,$FE,$09,$3C
  DEFB $FE,$08,$3C,$FE,$07,$3C,$FE,$09
  DEFB $3C,$FE,$08,$3C,$FE,$07,$3C,$FE
  DEFB $06,$3C,$FE,$09,$3C,$FE,$08,$3C
  DEFB $FE,$07,$3C,$FE,$06,$3C,$FE,$08
  DEFB $3C,$FE,$07,$3C,$FE,$06,$3C,$FE
  DEFB $05,$3C,$FE,$08,$3C,$FE,$07,$3C
  DEFB $FE,$06,$3C,$FE,$05,$3C,$FE,$07
  DEFB $3C,$FE,$06,$3C,$FE,$05,$3C,$FE
  DEFB $04,$3C,$FE,$07,$3C,$FE,$06,$3C
  DEFB $FE,$05,$3C,$FE,$04,$3C,$FF,$FE
  DEFB $0F,$FD,$01,$01,$90,$06,$2F,$2E
  DEFB $2D,$2C,$2B,$30,$FF,$FE,$0F,$FD
  DEFB $02,$01,$A3,$09,$A0,$03,$3E,$40
  DEFB $A1,$06,$40,$3C,$FF,$FE,$0F,$FD
  DEFB $01,$01,$A3,$01,$41,$46,$45,$43
  DEFB $41,$46,$A5,$02,$FF,$FE,$0C,$FD
  DEFB $04,$01,$9C,$0C,$37,$3C,$FF,$FE
  DEFB $0F,$FD,$01,$01,$A8,$04,$43,$40
  DEFB $3C,$40,$43,$48,$FF,$FE,$0A,$FD
  DEFB $01,$01,$A3,$04,$40,$3C,$37,$3C
  DEFB $40,$43,$FF,$FE,$0A,$FD,$01,$01
  DEFB $A0,$04,$3C,$37,$34,$37,$3C,$40
  DEFB $FF,$FC,$00,$FE,$0D,$FB,$0F,$74
  DEFB $01,$FE,$0B,$14,$FE,$09,$14,$FE
  DEFB $07,$14,$FE,$03,$74,$03,$FE,$02
  DEFB $14,$FF,$FE,$0F,$FD,$02,$01,$A5
  DEFB $02,$46,$47,$48,$47,$46,$45,$FF
  DEFB $FE,$0D,$FD,$03,$01,$FC,$00,$FB
  DEFB $00,$88,$03,$89,$01,$2A,$2B,$2C
  DEFB $2D,$2E,$2F,$30,$31,$32,$33,$34
  DEFB $35,$36,$37,$98,$04,$FF,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$84,$03,$92
  DEFB $03,$8E,$0C,$DA,$0B,$2F,$0B,$8F
  DEFB $0A,$F7,$09,$68,$09,$E1,$08,$61
  DEFB $08,$E9,$07,$77,$07,$0C,$07,$A7
  DEFB $06,$47,$06,$ED,$05,$98,$05,$47
  DEFB $05,$FC,$04,$B4,$04,$70,$04,$31
  DEFB $04,$F4,$03,$BC,$03,$86,$03,$53
  DEFB $03,$24,$03,$F6,$02,$CC,$02,$A4
  DEFB $02,$7E,$02,$5A,$02,$38,$02,$18
  DEFB $02,$FA,$01,$DE,$01,$C3,$01,$AA
  DEFB $01,$92,$01,$7B,$01,$66,$01,$52
  DEFB $01,$3F,$01,$2D,$01,$1C,$01,$0C
  DEFB $01,$FD,$00,$EF,$00,$E1,$00,$D5
  DEFB $00,$C9,$00,$BE,$00,$B3,$00,$A9
  DEFB $00,$9F,$00,$96,$00,$8E,$00,$86
  DEFB $00,$7F,$00,$77,$00,$71,$00,$6A
  DEFB $00,$64,$00,$5F,$00,$59,$00,$54
  DEFB $00,$50,$00,$4B,$00,$47,$00,$43
  DEFB $00,$3F,$00,$3C,$00,$38,$00,$35
  DEFB $00,$32,$00,$2F,$00,$2D,$00,$2A
  DEFB $00,$28,$00,$26,$00,$24,$00,$22
  DEFB $00,$20,$00,$1E,$00,$1C,$00,$1B
  DEFB $00,$19,$00,$18,$00,$16,$00,$15
  DEFB $00,$14,$00,$13,$00,$12,$00,$11
  DEFB $00,$10,$00,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$F3,$21,$AA
  DEFB $C7,$01,$0E,$F4,$ED,$49,$06,$F6
  DEFB $ED,$78,$E6,$30,$4F,$F6,$C0,$ED
  DEFB $79,$ED,$49,$04,$3E,$92,$ED,$79
  DEFB $C5,$CB,$F1,$06,$F6,$ED,$49,$06
  DEFB $F4,$ED,$78,$23,$77,$0C,$79,$E6
  DEFB $0F,$FE,$0A,$20,$EE,$C1,$3E,$82
  DEFB $ED,$79,$05,$ED,$49,$7E,$F6,$60
  DEFB $77,$FB,$C9

; l_C7F3
l_C7F3:
  RET

; data_C7F4
data_C7F4:
  DEFB $EE,$C8,$0A,$C9,$29,$C9,$4B,$C9
  DEFB $61,$C9,$77,$C9,$90,$C9,$B8,$C9
  DEFB $E0,$C9,$02,$CA,$2A,$CA,$4C,$CA
  DEFB $7D,$CA,$A5,$CA,$BE,$CA,$E6,$CA
  DEFB $FF,$CA,$18,$CB,$34,$CB,$5C,$CB
  DEFB $78,$CB,$9D,$CB,$C2,$CB,$DB,$CB
  DEFB $FA,$CB,$10,$CC,$35,$CC,$4E,$CC
  DEFB $70,$CC,$83,$CC,$B1,$CC,$D6,$CC
  DEFB $F8,$CC,$17,$CD,$39,$CD,$67,$CD
  DEFB $7D,$CD,$90,$CD,$AC,$CD,$CB,$CD
  DEFB $ED,$CD,$09,$CE,$31,$CE,$4A,$CE
  DEFB $69,$CE,$79,$CE,$9E,$CE,$C9,$CE
  DEFB $EE,$CE,$13,$CF,$32,$CF,$5D,$CF
  DEFB $73,$CF,$92,$CF,$BD,$CF,$D3,$CF
  DEFB $F2,$CF,$11,$D0,$39,$D0,$43,$D0
  DEFB $77,$D0,$9C,$D0,$C1,$D0,$DD,$D0
  DEFB $ED,$D0,$09,$D1,$25,$D1,$4D,$D1
  DEFB $7E,$D1,$AC,$D1,$E6,$D1,$26,$D2
  DEFB $4B,$D2,$6A,$D2,$8C,$D2,$A2,$D2
  DEFB $C1,$D2,$F2,$D2,$0B,$D3,$45,$D3
  DEFB $61,$D3,$80,$D3,$A2,$D3,$CD,$D3
  DEFB $E3,$D3,$FF,$D3,$0F,$D4,$2E,$D4
  DEFB $4D,$D4,$69,$D4,$8B,$D4,$B9,$D4
  DEFB $D8,$D4,$F1,$D4,$16,$D5,$32,$D5
  DEFB $51,$D5,$76,$D5,$98,$D5,$B7,$D5
  DEFB $D0,$D5,$E9,$D5,$FC,$D5,$1E,$D6
  DEFB $31,$D6,$5F,$D6,$84,$D6,$A6,$D6
  DEFB $C5,$D6,$E7,$D6,$15,$D7,$2B,$D7
  DEFB $3E,$D7,$5A,$D7,$79,$D7,$9B,$D7
  DEFB $B7,$D7,$DF,$D7,$F8,$D7,$17,$D8
  DEFB $27,$D8,$4C,$D8,$77,$D8,$9C,$D8
  DEFB $C1,$D8,$13,$00,$0A,$12,$00,$21
  DEFB $02,$00,$02,$08,$00,$0B,$01,$18
  DEFB $03,$04,$10,$1E,$05,$1D,$04,$0A
  DEFB $1D,$0D,$0E,$14,$05,$FF,$13,$00
  DEFB $0E,$12,$00,$21,$0A,$07,$0F,$0C
  DEFB $0E,$10,$0C,$12,$10,$0C,$16,$10
  DEFB $10,$1C,$14,$00,$00,$1E,$03,$0F
  DEFB $03,$02,$14,$04,$FF,$13,$00,$0A
  DEFB $12,$00,$21,$0B,$16,$17,$0D,$16
  DEFB $18,$05,$16,$11,$0E,$0E,$05,$0C
  DEFB $04,$11,$12,$1B,$16,$09,$1C,$13
  DEFB $01,$08,$03,$02,$02,$04,$FF,$13
  DEFB $00,$0E,$12,$00,$21,$0B,$E7,$17
  DEFB $0D,$04,$18,$0C,$18,$10,$0C,$1C
  DEFB $10,$10,$13,$14,$FF,$13,$00,$0A
  DEFB $12,$00,$21,$01,$04,$04,$03,$16
  DEFB $03,$07,$1B,$1E,$02,$09,$02,$0A
  DEFB $0D,$0F,$FF,$13,$F2,$0E,$12,$F2
  DEFB $21,$12,$12,$22,$14,$13,$17,$0E
  DEFB $17,$15,$03,$0B,$25,$00,$01,$23
  DEFB $02,$19,$24,$FF,$14,$F7,$17,$08
  DEFB $09,$17,$0A,$09,$1C,$0A,$13,$1C
  DEFB $02,$09,$11,$06,$18,$13,$06,$1B
  DEFB $14,$12,$17,$22,$12,$18,$21,$13
  DEFB $18,$0E,$11,$12,$1A,$0C,$19,$11
  DEFB $02,$11,$10,$FF,$13,$00,$0A,$12
  DEFB $E6,$21,$12,$06,$22,$08,$E7,$17
  DEFB $08,$18,$17,$08,$0E,$1C,$0A,$04
  DEFB $1C,$0A,$18,$1C,$04,$0C,$05,$0F
  DEFB $1A,$05,$13,$0A,$0C,$13,$0F,$0C
  DEFB $13,$14,$0C,$FF,$13,$F3,$0A,$14
  DEFB $13,$17,$08,$E8,$17,$02,$04,$11
  DEFB $0D,$08,$11,$0A,$05,$1C,$0F,$15
  DEFB $20,$0B,$14,$1F,$0E,$1A,$15,$00
  DEFB $11,$03,$04,$19,$04,$FF,$14,$F1
  DEFB $17,$12,$12,$21,$12,$11,$22,$13
  DEFB $12,$0E,$0B,$17,$1D,$10,$12,$13
  DEFB $10,$1D,$14,$0E,$08,$10,$14,$04
  DEFB $16,$14,$0C,$16,$01,$07,$24,$03
  DEFB $10,$1E,$00,$16,$03,$FF,$08,$00
  DEFB $0E,$13,$00,$0A,$12,$00,$21,$0B
  DEFB $01,$19,$0B,$1D,$19,$0F,$17,$1A
  DEFB $0C,$06,$11,$02,$00,$11,$02,$0A
  DEFB $10,$02,$0E,$10,$02,$12,$10,$FF
  DEFB $14,$0B,$17,$13,$EA,$0E,$13,$18
  DEFB $0E,$12,$19,$21,$12,$EA,$21,$12
  DEFB $0A,$22,$12,$18,$22,$0A,$17,$0F
  DEFB $12,$14,$13,$10,$1C,$14,$0B,$05
  DEFB $19,$08,$E7,$0E,$00,$0C,$04,$02
  DEFB $12,$1E,$0F,$10,$20,$0B,$0F,$1F
  DEFB $FF,$08,$00,$0B,$13,$EA,$0A,$12
  DEFB $EA,$21,$12,$0A,$22,$14,$0B,$26
  DEFB $0E,$0E,$11,$06,$14,$11,$0C,$14
  DEFB $0E,$0E,$14,$21,$10,$1A,$05,$0F
  DEFB $14,$1B,$0A,$1E,$14,$10,$05,$13
  DEFB $FF,$14,$00,$26,$0C,$00,$0E,$0E
  DEFB $00,$21,$0F,$0E,$1B,$06,$12,$15
  DEFB $11,$1B,$1A,$14,$06,$16,$00,$03
  DEFB $24,$FF,$14,$EE,$26,$14,$0E,$26
  DEFB $0C,$00,$0A,$0E,$00,$21,$0F,$04
  DEFB $1B,$00,$03,$24,$0F,$1A,$1B,$06
  DEFB $05,$11,$09,$12,$1A,$06,$17,$11
  DEFB $14,$08,$16,$14,$0F,$16,$14,$16
  DEFB $16,$FF,$0C,$E7,$0A,$0E,$E7,$21
  DEFB $0F,$04,$1B,$14,$00,$26,$0B,$18
  DEFB $1F,$0F,$19,$20,$00,$04,$03,$02
  DEFB $19,$1E,$FF,$0B,$1D,$0D,$13,$09
  DEFB $0E,$14,$E9,$26,$13,$0B,$0C,$13
  DEFB $13,$0C,$0F,$0D,$05,$02,$14,$03
  DEFB $05,$05,$1E,$FF,$13,$00,$0E,$0D
  DEFB $06,$11,$09,$00,$1C,$09,$0D,$1C
  DEFB $08,$F0,$21,$02,$00,$11,$06,$0A
  DEFB $13,$06,$0E,$14,$13,$12,$16,$FF
  DEFB $13,$00,$0E,$12,$0F,$22,$12,$10
  DEFB $21,$0C,$15,$15,$0B,$10,$19,$0D
  DEFB $04,$11,$03,$10,$11,$04,$16,$18
  DEFB $02,$16,$17,$09,$10,$17,$13,$0B
  DEFB $0C,$0C,$1C,$10,$07,$1B,$13,$FF
  DEFB $02,$00,$26,$09,$EF,$26,$09,$0F
  DEFB $26,$04,$04,$1B,$04,$19,$1B,$13
  DEFB $00,$0A,$12,$00,$21,$0B,$0F,$19
  DEFB $0E,$13,$05,$FF,$13,$00,$0E,$12
  DEFB $00,$21,$02,$00,$26,$09,$00,$26
  DEFB $04,$0E,$1B,$06,$1B,$1A,$0B,$01
  DEFB $19,$0B,$1D,$19,$0E,$18,$27,$0E
  DEFB $0F,$27,$12,$08,$16,$12,$15,$16
  DEFB $FF,$13,$00,$0A,$12,$00,$21,$0C
  DEFB $18,$10,$0C,$1C,$10,$10,$04,$13
  DEFB $10,$10,$14,$0B,$0A,$19,$09,$EC
  DEFB $26,$04,$06,$1B,$02,$E9,$26,$00
  DEFB $18,$25,$05,$0F,$27,$FF,$13,$00
  DEFB $0E,$12,$F4,$21,$11,$19,$29,$0D
  DEFB $08,$28,$0D,$0E,$28,$03,$0E,$25
  DEFB $00,$18,$03,$02,$02,$1E,$FF,$13
  DEFB $00,$0A,$0F,$1A,$2C,$11,$19,$2D
  DEFB $13,$05,$16,$09,$0D,$1C,$09,$1D
  DEFB $1C,$07,$0D,$26,$02,$0E,$28,$01
  DEFB $14,$10,$00,$05,$03,$FF,$13,$00
  DEFB $0E,$04,$0C,$2A,$00,$03,$24,$01
  DEFB $15,$03,$0B,$1D,$0D,$10,$09,$2B
  DEFB $10,$16,$2B,$FF,$13,$00,$0A,$00
  DEFB $00,$0E,$0B,$1D,$0D,$03,$02,$31
  DEFB $03,$09,$30,$03,$13,$31,$03,$1A
  DEFB $30,$03,$05,$32,$03,$16,$32,$0F
  DEFB $0B,$2E,$0F,$10,$2E,$03,$0B,$33
  DEFB $FF,$13,$00,$0E,$00,$EB,$0A,$03
  DEFB $02,$31,$03,$09,$30,$03,$05,$32
  DEFB $0E,$0B,$28,$0E,$11,$28,$13,$1A
  DEFB $0C,$FF,$13,$E8,$0A,$11,$09,$1C
  DEFB $10,$0E,$1C,$0F,$13,$1C,$0E,$18
  DEFB $1C,$0D,$1D,$1C,$0D,$13,$13,$0B
  DEFB $1D,$14,$02,$1A,$04,$00,$0C,$03
  DEFB $03,$04,$25,$FF,$14,$00,$17,$0D
  DEFB $02,$1C,$0D,$0C,$1C,$11,$10,$1A
  DEFB $0E,$1B,$15,$02,$09,$02,$FF,$14
  DEFB $EC,$17,$13,$0C,$0E,$12,$0C,$17
  DEFB $0E,$14,$05,$0C,$1B,$11,$08,$06
  DEFB $1C,$08,$0F,$1C,$08,$18,$1C,$06
  DEFB $00,$26,$02,$06,$2F,$02,$0F,$2F
  DEFB $02,$18,$2F,$00,$01,$11,$00,$06
  DEFB $26,$10,$0D,$13,$FF,$13,$00,$0E
  DEFB $12,$00,$17,$12,$0F,$16,$08,$06
  DEFB $1C,$0A,$0A,$1C,$0A,$15,$1C,$06
  DEFB $13,$05,$06,$E9,$26,$02,$06,$2F
  DEFB $00,$E9,$26,$0E,$09,$27,$0E,$09
  DEFB $27,$FF,$13,$00,$0A,$12,$EF,$17
  DEFB $13,$0F,$16,$13,$16,$16,$13,$1D
  DEFB $16,$11,$13,$13,$11,$1A,$14,$0A
  DEFB $05,$0F,$0A,$0A,$0F,$02,$08,$1E
  DEFB $04,$15,$03,$FF,$13,$00,$0E,$13
  DEFB $05,$0C,$0F,$0B,$2C,$11,$0A,$2D
  DEFB $0D,$12,$11,$0B,$18,$2F,$0F,$18
  DEFB $2F,$09,$18,$26,$03,$18,$11,$13
  DEFB $1D,$0C,$FF,$13,$00,$0A,$0B,$06
  DEFB $2F,$0F,$06,$2F,$0B,$18,$2F,$0F
  DEFB $18,$2F,$09,$00,$26,$11,$15,$13
  DEFB $07,$03,$14,$0D,$1C,$11,$03,$06
  DEFB $11,$06,$1B,$1A,$FF,$13,$00,$0E
  DEFB $0B,$06,$2F,$0F,$06,$2F,$0B,$18
  DEFB $2F,$0F,$18,$2F,$09,$FB,$26,$09
  DEFB $1B,$26,$07,$15,$13,$07,$19,$14
  DEFB $02,$0E,$1D,$13,$0A,$0C,$13,$0F
  DEFB $0C,$13,$14,$0C,$0F,$14,$27,$0F
  DEFB $13,$27,$FF,$13,$00,$0A,$09,$E9
  DEFB $26,$0B,$06,$2F,$0F,$06,$2F,$00
  DEFB $12,$01,$13,$13,$00,$13,$0D,$0C
  DEFB $FF,$13,$00,$0E,$12,$05,$22,$12
  DEFB $06,$21,$10,$09,$13,$02,$05,$1E
  DEFB $00,$10,$03,$FF,$13,$00,$0A,$12
  DEFB $00,$21,$0D,$06,$28,$0D,$0C,$28
  DEFB $0C,$12,$11,$0B,$19,$19,$08,$12
  DEFB $0E,$0A,$12,$21,$02,$12,$11,$FF
  DEFB $13,$00,$0E,$12,$00,$21,$0C,$04
  DEFB $11,$0C,$0C,$27,$10,$0C,$27,$0B
  DEFB $0F,$19,$08,$00,$0A,$0A,$00,$21
  DEFB $02,$04,$11,$05,$1B,$1A,$FF,$13
  DEFB $EC,$0A,$12,$EC,$21,$12,$0C,$22
  DEFB $14,$0D,$17,$0B,$06,$19,$08,$E8
  DEFB $0A,$0A,$E8,$21,$04,$03,$05,$00
  DEFB $15,$01,$12,$16,$00,$14,$1D,$16
  DEFB $FF,$14,$00,$17,$12,$06,$13,$0E
  DEFB $09,$15,$0E,$0E,$15,$0E,$14,$10
  DEFB $0E,$18,$10,$12,$1C,$14,$04,$08
  DEFB $03,$02,$18,$04,$FF,$14,$EC,$17
  DEFB $13,$0C,$0A,$12,$0C,$17,$12,$07
  DEFB $00,$0B,$0D,$19,$0C,$14,$15,$0C
  DEFB $1B,$11,$08,$0D,$0E,$02,$0D,$11
  DEFB $04,$14,$05,$06,$1B,$13,$06,$1E
  DEFB $14,$00,$06,$01,$FF,$13,$00,$0E
  DEFB $12,$E9,$17,$12,$09,$22,$0B,$07
  DEFB $19,$08,$00,$0A,$08,$13,$0C,$13
  DEFB $0E,$16,$13,$18,$16,$FF,$13,$00
  DEFB $0A,$08,$E6,$0A,$0A,$11,$1F,$0E
  DEFB $12,$20,$0B,$03,$1C,$00,$19,$1E
  DEFB $11,$08,$13,$13,$0D,$0C,$13,$17
  DEFB $0C,$0F,$1A,$2E,$FF,$13,$00,$0E
  DEFB $0D,$06,$10,$0D,$16,$10,$11,$0E
  DEFB $14,$09,$0A,$0B,$FF,$13,$E9,$0E
  DEFB $14,$09,$26,$0E,$13,$11,$0C,$0C
  DEFB $2F,$10,$0C,$2F,$0C,$1B,$2F,$10
  DEFB $1B,$2F,$0A,$0C,$26,$04,$0C,$11
  DEFB $06,$19,$2C,$08,$18,$2D,$00,$00
  DEFB $03,$FF,$14,$00,$26,$0A,$00,$26
  DEFB $0C,$03,$2F,$10,$03,$2F,$0C,$1A
  DEFB $2F,$10,$1A,$2F,$10,$14,$2C,$12
  DEFB $13,$2D,$06,$14,$2C,$08,$13,$2D
  DEFB $08,$06,$13,$08,$09,$14,$12,$0A
  DEFB $27,$10,$0F,$27,$FF,$14,$00,$26
  DEFB $0C,$06,$2F,$10,$06,$2F,$0A,$E9
  DEFB $26,$04,$05,$15,$09,$0E,$1C,$07
  DEFB $12,$1C,$07,$1C,$1C,$03,$10,$05
  DEFB $14,$0B,$16,$14,$12,$16,$14,$19
  DEFB $16,$FF,$14,$E9,$26,$13,$09,$0A
  DEFB $0F,$05,$28,$0D,$0F,$11,$10,$1C
  DEFB $1A,$0B,$15,$2F,$0F,$15,$2F,$09
  DEFB $15,$17,$08,$15,$21,$02,$15,$11
  DEFB $07,$00,$1C,$0A,$04,$1C,$FF,$13
  DEFB $00,$0A,$12,$0B,$22,$12,$0C,$21
  DEFB $0B,$06,$2F,$0F,$06,$2F,$0F,$0D
  DEFB $2B,$0F,$1C,$2B,$09,$E9,$17,$08
  DEFB $E9,$21,$03,$11,$2A,$FF,$13,$00
  DEFB $0E,$13,$03,$0C,$13,$06,$0C,$13
  DEFB $09,$0C,$13,$0C,$0C,$13,$0F,$0C
  DEFB $13,$12,$0C,$08,$00,$1C,$08,$0A
  DEFB $1C,$0E,$14,$1C,$0E,$18,$20,$0A
  DEFB $17,$1F,$00,$1B,$01,$13,$1C,$00
  DEFB $FF,$13,$00,$0A,$00,$07,$24,$02
  DEFB $1B,$1E,$0E,$0F,$20,$0A,$0E,$1F
  DEFB $09,$00,$0B,$09,$15,$0B,$FF,$13
  DEFB $EA,$0A,$14,$0A,$34,$0D,$0B,$34
  DEFB $0D,$06,$11,$07,$0B,$11,$0F,$0B
  DEFB $35,$0F,$1C,$35,$11,$18,$1A,$09
  DEFB $1D,$27,$09,$1C,$27,$FF,$14,$00
  DEFB $34,$0D,$F2,$34,$0D,$17,$34,$0F
  DEFB $06,$35,$08,$06,$35,$08,$17,$35
  DEFB $0F,$17,$35,$05,$06,$0E,$12,$0E
  DEFB $13,$12,$1B,$14,$09,$0D,$2C,$0B
  DEFB $0C,$2D,$01,$0A,$2E,$01,$10,$2E
  DEFB $FF,$14,$00,$34,$0D,$EF,$34,$0F
  DEFB $06,$35,$08,$06,$35,$08,$0A,$28
  DEFB $05,$E9,$0E,$12,$18,$13,$FF,$14
  DEFB $E6,$34,$12,$06,$22,$12,$07,$21
  DEFB $13,$07,$0A,$0C,$07,$10,$0C,$0B
  DEFB $10,$10,$0F,$14,$0C,$12,$10,$0C
  DEFB $16,$10,$12,$1D,$16,$FF,$13,$00
  DEFB $0A,$12,$00,$21,$0C,$0E,$11,$0D
  DEFB $14,$35,$0B,$14,$34,$00,$0E,$34
  DEFB $02,$0E,$1C,$02,$1D,$1C,$10,$1A
  DEFB $13,$05,$14,$11,$FF,$13,$00,$0E
  DEFB $12,$00,$21,$0D,$09,$35,$0D,$14
  DEFB $35,$0E,$1A,$2C,$10,$19,$2D,$0B
  DEFB $EC,$34,$0B,$14,$34,$09,$17,$14
  DEFB $09,$1A,$13,$02,$03,$1C,$02,$1B
  DEFB $1C,$00,$00,$34,$FF,$13,$00,$0A
  DEFB $12,$00,$21,$0B,$E6,$34,$FF,$14
  DEFB $F5,$34,$13,$E8,$0A,$12,$E8,$21
  DEFB $12,$08,$22,$15,$15,$21,$0C,$05
  DEFB $11,$09,$00,$1C,$09,$03,$1C,$03
  DEFB $00,$11,$0F,$0C,$35,$0F,$0F,$35
  DEFB $0B,$0C,$2F,$0B,$0F,$2F,$06,$0E
  DEFB $20,$02,$0D,$1F,$00,$18,$03,$07
  DEFB $04,$13,$FF,$15,$EC,$21,$14,$0C
  DEFB $34,$12,$18,$22,$12,$19,$21,$13
  DEFB $19,$0E,$0D,$06,$0F,$12,$0D,$14
  DEFB $11,$12,$2B,$10,$18,$13,$0B,$1B
  DEFB $1D,$00,$02,$24,$03,$12,$25,$FF
  DEFB $13,$00,$0A,$12,$00,$21,$0B,$07
  DEFB $19,$0B,$15,$19,$0C,$0B,$11,$10
  DEFB $18,$2D,$0E,$19,$2C,$09,$07,$34
  DEFB $03,$07,$11,$06,$0F,$2B,$06,$15
  DEFB $2B,$06,$1B,$2B,$FF,$13,$00,$0E
  DEFB $12,$00,$21,$0B,$07,$19,$09,$EA
  DEFB $34,$0A,$16,$0A,$0D,$16,$35,$0D
  DEFB $19,$35,$00,$0E,$01,$10,$0F,$00
  DEFB $FF,$13,$00,$0A,$12,$00,$21,$0D
  DEFB $06,$35,$0D,$17,$35,$0A,$00,$0E
  DEFB $FF,$13,$00,$0E,$12,$00,$21,$0D
  DEFB $06,$18,$0D,$17,$18,$0A,$E9,$0E
  DEFB $0A,$17,$0A,$12,$0A,$16,$12,$13
  DEFB $16,$00,$05,$1E,$FF,$13,$F1,$0A
  DEFB $12,$E9,$21,$12,$08,$22,$14,$11
  DEFB $36,$0D,$06,$35,$0E,$0B,$28,$0E
  DEFB $12,$15,$0E,$1B,$15,$0A,$E9,$0A
  DEFB $FF,$14,$00,$36,$0C,$0F,$2F,$10
  DEFB $0F,$2F,$0E,$13,$11,$0A,$0F,$36
  DEFB $02,$0F,$2F,$06,$0F,$2F,$04,$13
  DEFB $11,$04,$1B,$10,$00,$06,$36,$02
  DEFB $06,$33,$10,$0B,$27,$10,$08,$27
  DEFB $FF,$14,$00,$36,$0C,$06,$2F,$10
  DEFB $06,$2F,$0C,$17,$2F,$10,$17,$2F
  DEFB $0C,$0E,$0F,$0A,$00,$36,$02,$06
  DEFB $2F,$06,$06,$2F,$02,$17,$2F,$06
  DEFB $17,$2F,$08,$0A,$13,$07,$1B,$1A
  DEFB $05,$0E,$27,$14,$0A,$16,$00,$00
  DEFB $36,$FF,$14,$EF,$36,$12,$0F,$22
  DEFB $12,$10,$21,$13,$10,$0A,$12,$0B
  DEFB $13,$10,$10,$14,$12,$13,$16,$00
  DEFB $1B,$01,$10,$1C,$00,$0C,$06,$2F
  DEFB $10,$06,$2F,$0A,$E9,$36,$02,$06
  DEFB $2F,$06,$06,$2F,$00,$E9,$36,$FF
  DEFB $13,$00,$0A,$12,$00,$37,$12,$04
  DEFB $22,$12,$08,$22,$12,$09,$37,$12
  DEFB $0D,$22,$12,$11,$22,$12,$12,$37
  DEFB $12,$16,$22,$12,$1A,$22,$12,$1B
  DEFB $37,$12,$1F,$22,$0E,$12,$2E,$0C
  DEFB $1B,$15,$13,$05,$16,$13,$0E,$16
  DEFB $13,$17,$16,$02,$14,$24,$00,$05
  DEFB $03,$FF,$13,$00,$0E,$12,$00,$37
  DEFB $12,$04,$22,$12,$08,$22,$12,$09
  DEFB $37,$12,$0D,$22,$12,$11,$22,$12
  DEFB $12,$37,$12,$16,$22,$12,$1A,$22
  DEFB $12,$1B,$37,$12,$1F,$22,$0C,$11
  DEFB $11,$0B,$1C,$19,$09,$1C,$36,$03
  DEFB $1C,$11,$13,$06,$0C,$13,$0F,$0C
  DEFB $13,$18,$0C,$09,$09,$1F,$0D,$0A
  DEFB $20,$FF,$13,$00,$0A,$12,$00,$21
  DEFB $0B,$0D,$19,$0B,$16,$19,$09,$EF
  DEFB $36,$09,$16,$36,$01,$0B,$0F,$01
  DEFB $15,$0F,$0E,$1A,$2C,$10,$19,$2D
  DEFB $0C,$12,$27,$0B,$12,$27,$FF,$13
  DEFB $E9,$0E,$12,$E9,$21,$12,$08,$22
  DEFB $14,$09,$34,$0B,$05,$19,$09,$E7
  DEFB $36,$10,$1A,$05,$14,$12,$16,$00
  DEFB $12,$25,$03,$1E,$04,$FF,$14,$00
  DEFB $34,$12,$06,$22,$12,$07,$37,$12
  DEFB $0B,$22,$12,$12,$22,$12,$13,$37
  DEFB $12,$17,$22,$13,$07,$06,$13,$13
  DEFB $07,$0E,$12,$2C,$10,$11,$2D,$FF
  DEFB $14,$00,$36,$05,$0C,$2A,$00,$03
  DEFB $1E,$01,$15,$25,$0C,$1D,$0D,$11
  DEFB $09,$2B,$11,$16,$2B,$FF,$13,$E8
  DEFB $3C,$12,$E8,$21,$12,$08,$22,$0D
  DEFB $02,$28,$11,$10,$2B,$0F,$14,$28
  DEFB $0C,$1D,$0D,$02,$09,$02,$00,$03
  DEFB $03,$14,$09,$34,$FF,$14,$00,$36
  DEFB $12,$0C,$22,$12,$0D,$37,$12,$11
  DEFB $22,$12,$1A,$22,$12,$1B,$37,$12
  DEFB $1F,$22,$13,$0D,$3B,$13,$1B,$3A
  DEFB $0E,$1B,$2F,$0A,$1B,$2F,$08,$1B
  DEFB $36,$00,$0F,$1E,$02,$06,$24,$10
  DEFB $0E,$13,$12,$16,$14,$FF,$13,$00
  DEFB $3D,$12,$00,$21,$0C,$03,$11,$0F
  DEFB $15,$1A,$0A,$06,$1C,$0A,$18,$1C
  DEFB $08,$00,$36,$02,$00,$11,$FF,$13
  DEFB $00,$3C,$12,$00,$37,$12,$04,$22
  DEFB $12,$09,$22,$12,$0A,$37,$12,$0E
  DEFB $22,$12,$13,$22,$12,$14,$37,$12
  DEFB $18,$22,$12,$1D,$22,$12,$1E,$37
  DEFB $13,$06,$0C,$13,$10,$0C,$13,$1A
  DEFB $0C,$0D,$0A,$28,$08,$00,$36,$06
  DEFB $0A,$2D,$04,$0B,$2C,$03,$12,$28
  DEFB $FF,$13,$00,$3D,$12,$00,$21,$0C
  DEFB $08,$15,$0A,$0E,$2F,$0E,$0E,$2F
  DEFB $08,$F1,$36,$05,$0F,$2B,$10,$02
  DEFB $13,$10,$05,$14,$FF,$14,$0B,$34
  DEFB $13,$EA,$3C,$13,$16,$3D,$12,$0A
  DEFB $22,$12,$15,$22,$12,$16,$21,$12
  DEFB $EA,$21,$10,$03,$13,$0B,$0E,$1F
  DEFB $0F,$0F,$20,$FF,$13,$00,$3D,$12
  DEFB $00,$21,$0C,$08,$11,$04,$12,$11
  DEFB $12,$04,$16,$12,$0D,$16,$0D,$12
  DEFB $35,$0A,$12,$0A,$0A,$1C,$0C,$0E
  DEFB $18,$2C,$10,$17,$2D,$FF,$13,$EC
  DEFB $3C,$12,$EC,$21,$12,$0C,$22,$14
  DEFB $0D,$36,$0E,$16,$15,$0B,$1B,$1F
  DEFB $0F,$1C,$20,$0D,$04,$35,$0D,$09
  DEFB $35,$0A,$EC,$0E,$00,$15,$03,$05
  DEFB $1A,$1E,$12,$0E,$13,$12,$11,$14
  DEFB $FF,$13,$04,$3D,$14,$E4,$36,$10
  DEFB $07,$2B,$10,$18,$2B,$00,$05,$1E
  DEFB $03,$11,$03,$01,$1D,$04,$FF,$13
  DEFB $00,$3C,$12,$10,$21,$12,$0F,$22
  DEFB $10,$0C,$2B,$11,$04,$13,$10,$1C
  DEFB $14,$0C,$12,$10,$0C,$18,$10,$00
  DEFB $02,$03,$FF,$13,$00,$3D,$12,$00
  DEFB $21,$00,$00,$25,$04,$09,$1E,$00
  DEFB $19,$1E,$FF,$13,$00,$3C,$12,$00
  DEFB $21,$10,$04,$13,$0C,$07,$11,$0A
  DEFB $0C,$2F,$0E,$0C,$2F,$08,$0C,$36
  DEFB $0B,$14,$36,$0D,$14,$35,$02,$0C
  DEFB $11,$FF,$13,$00,$3D,$12,$00,$21
  DEFB $10,$04,$13,$0B,$EB,$36,$0A,$0E
  DEFB $2F,$0E,$0E,$2F,$08,$00,$36,$0D
  DEFB $08,$35,$05,$1B,$1A,$0F,$1A,$1A
  DEFB $FF,$13,$00,$3C,$12,$00,$21,$08
  DEFB $EF,$36,$00,$16,$03,$0A,$0C,$2F
  DEFB $0E,$0C,$2F,$12,$12,$16,$0D,$1A
  DEFB $20,$09,$19,$1F,$FF,$13,$00,$3D
  DEFB $12,$ED,$21,$10,$08,$13,$10,$0B
  DEFB $14,$12,$0C,$22,$13,$12,$0C,$13
  DEFB $16,$0C,$13,$1D,$0C,$04,$11,$02
  DEFB $02,$03,$1E,$00,$09,$04,$FF,$13
  DEFB $E6,$3D,$14,$06,$36,$11,$04,$13
  DEFB $12,$07,$14,$0D,$0C,$1D,$0C,$13
  DEFB $2F,$10,$13,$2F,$14,$17,$16,$14
  DEFB $1B,$16,$0A,$13,$17,$05,$13,$18
  DEFB $06,$17,$2E,$06,$1C,$2E,$03,$13
  DEFB $17,$01,$04,$24,$FF,$14,$00,$36
  DEFB $0E,$06,$11,$0C,$0F,$2F,$10,$0F
  DEFB $2F,$0F,$13,$28,$0F,$18,$28,$0A
  DEFB $00,$17,$03,$E6,$17,$05,$03,$18
  DEFB $04,$07,$11,$FF,$14,$00,$36,$0A
  DEFB $EC,$17,$0C,$09,$2F,$10,$09,$2F
  DEFB $0B,$13,$1F,$0F,$14,$20,$00,$19
  DEFB $01,$12,$1A,$00,$FF,$14,$E9,$36
  DEFB $13,$09,$3D,$13,$0B,$0C,$13,$10
  DEFB $0C,$11,$0D,$13,$12,$13,$22,$12
  DEFB $14,$21,$10,$16,$14,$0E,$19,$05
  DEFB $05,$1A,$1E,$00,$09,$03,$02,$00
  DEFB $04,$FF,$13,$00,$3D,$12,$00,$21
  DEFB $0D,$06,$28,$0D,$0B,$28,$0D,$10
  DEFB $28,$0C,$15,$15,$0C,$1A,$15,$00
  DEFB $0C,$1E,$05,$18,$24,$FF,$13,$00
  DEFB $3C,$12,$00,$21,$0C,$0C,$11,$0F
  DEFB $1B,$1A,$0A,$11,$1C,$0A,$1C,$1C
  DEFB $07,$11,$3D,$01,$11,$11,$05,$17
  DEFB $13,$10,$17,$14,$FF,$13,$00,$3D
  DEFB $12,$00,$21,$07,$00,$3C,$0A,$00
  DEFB $1C,$0A,$1D,$1C,$12,$0E,$16,$07
  DEFB $06,$0C,$07,$0A,$0C,$07,$0F,$0C
  DEFB $07,$15,$0C,$07,$1C,$0C,$0C,$18
  DEFB $15,$FF,$13,$00,$3C,$12,$00,$21
  DEFB $07,$00,$3D,$10,$07,$13,$05,$0C
  DEFB $14,$0A,$09,$1C,$0A,$13,$1C,$03
  DEFB $1A,$2C,$05,$19,$2D,$0E,$1A,$2C
  DEFB $10,$19,$2D,$FF,$13,$00,$3D,$12
  DEFB $EA,$21,$12,$0A,$22,$13,$0D,$0C
  DEFB $13,$13,$0C,$13,$19,$0C,$10,$10
  DEFB $27,$10,$17,$27,$04,$11,$02,$0A
  DEFB $07,$0F,$FF,$13,$00,$3D,$04,$0C
  DEFB $2A,$00,$01,$03,$01,$17,$1E,$0B
  DEFB $1D,$0D,$10,$09,$2B,$10,$16,$2B
  DEFB $13,$05,$0C,$FF,$13,$00,$3D,$12
  DEFB $EC,$21,$12,$0C,$22,$02,$00,$02
  DEFB $08,$00,$0B,$00,$19,$03,$05,$12
  DEFB $24,$0B,$1D,$0D,$FF,$13,$00,$3C
  DEFB $0E,$0E,$28,$0E,$14,$28,$13,$1C
  DEFB $0C,$00,$05,$03,$03,$0F,$1E,$FF
  DEFB $13,$E8,$3D,$11,$09,$1C,$10,$0E
  DEFB $1C,$0F,$13,$1C,$0E,$18,$1C,$0D
  DEFB $1D,$1C,$0D,$13,$13,$0B,$1D,$14
  DEFB $02,$1A,$04,$00,$0C,$03,$03,$04
  DEFB $25,$FF,$14,$00,$17,$0D,$02,$1C
  DEFB $0D,$0C,$1C,$11,$10,$1A,$0E,$1B
  DEFB $15,$02,$09,$02,$FF,$14,$EC,$17
  DEFB $13,$0C,$3C,$12,$0C,$17,$0E,$14
  DEFB $05,$0C,$1B,$11,$08,$06,$1C,$08
  DEFB $0F,$1C,$08,$18,$1C,$06,$00,$26
  DEFB $02,$06,$2F,$02,$0F,$2F,$02,$18
  DEFB $2F,$00,$01,$11,$00,$06,$26,$10
  DEFB $0D,$13,$FF,$13,$00,$3C,$12,$00
  DEFB $17,$12,$0F,$16,$08,$06,$1C,$0A
  DEFB $0A,$1C,$0A,$15,$1C,$06,$13,$05
  DEFB $06,$E9,$26,$02,$06,$2F,$00,$E9
  DEFB $26,$0E,$09,$27,$0E,$09,$27,$FF
  DEFB $13,$00,$3D,$12,$EF,$17,$13,$0F
  DEFB $16,$13,$16,$16,$13,$1D,$16,$11
  DEFB $13,$13,$11,$1A,$14,$0A,$05,$0F
  DEFB $0A,$0A,$0F,$02,$08,$1E,$04,$15
  DEFB $03,$FF,$13,$00,$3C,$13,$05,$0C
  DEFB $0F,$0B,$2C,$11,$0A,$2D,$0D,$12
  DEFB $11,$0B,$18,$2F,$0F,$18,$2F,$09
  DEFB $18,$26,$03,$18,$11,$13,$1D,$0C
  DEFB $FF,$13,$00,$3D,$0B,$06,$2F,$0F
  DEFB $06,$2F,$0B,$18,$2F,$0F,$18,$2F
  DEFB $09,$00,$26,$11,$15,$13,$07,$03
  DEFB $14,$0D,$1C,$11,$03,$06,$11,$06
  DEFB $1B,$1A,$FF,$13,$00,$3C,$0B,$06
  DEFB $2F,$0F,$06,$2F,$0B,$18,$2F,$0F
  DEFB $18,$2F,$09,$FB,$26,$09,$1B,$26
  DEFB $07,$15,$13,$07,$19,$14,$02,$0E
  DEFB $1D,$13,$0A,$0C,$13,$0F,$0C,$13
  DEFB $14,$0C,$0F,$14,$27,$0F,$13,$27
  DEFB $FF,$13,$00,$3D,$09,$E9,$26,$0B
  DEFB $06,$2F,$0F,$06,$2F,$00,$12,$01
  DEFB $13,$13,$00,$13,$0D,$0C,$FF,$13
  DEFB $00,$3C,$12,$05,$22,$12,$06,$21
  DEFB $10,$09,$13,$02,$05,$1E,$00,$10
  DEFB $03,$FF,$13,$00,$3D,$12,$00,$21
  DEFB $0D,$06,$28,$0D,$0C,$28,$0C,$12
  DEFB $11,$0B,$19,$19,$08,$12,$3C,$0A
  DEFB $12,$21,$02,$12,$11,$FF,$13,$00
  DEFB $3C,$12,$00,$21,$0C,$04,$11,$0C
  DEFB $0C,$27,$10,$0C,$27,$0B,$0F,$19
  DEFB $08,$00,$3D,$0A,$00,$21,$02,$04
  DEFB $11,$05,$1B,$1A,$FF,$13,$EC,$3D
  DEFB $12,$EC,$21,$12,$0C,$22,$14,$0D
  DEFB $17,$0B,$06,$19,$08,$E8,$3D,$0A
  DEFB $E8,$21,$04,$03,$05,$00,$15,$01
  DEFB $12,$16,$00,$14,$1D,$16,$FF,$14
  DEFB $00,$17,$12,$06,$13,$0E,$09,$15
  DEFB $0E,$0E,$15,$0E,$14,$10,$0E,$18
  DEFB $10,$12,$1C,$14,$04,$08,$03,$02
  DEFB $18,$04,$FF,$14,$EC,$17,$13,$0C
  DEFB $3D,$12,$0C,$17,$12,$07,$00,$0B
  DEFB $0D,$19,$0C,$14,$15,$0C,$1B,$11
  DEFB $08,$0D,$3C,$02,$0D,$11,$04,$14
  DEFB $05,$06,$1B,$13,$06,$1E,$14,$00
  DEFB $06,$01,$FF,$13,$00,$3C,$12,$E9
  DEFB $17,$12,$09,$22,$0B,$07,$19,$08
  DEFB $00,$3D,$08,$13,$0C,$13,$0E,$16
  DEFB $13,$18,$16,$FF,$13,$00,$3D,$08
  DEFB $E6,$3D,$0A,$11,$1F,$0E,$12,$20
  DEFB $0B,$03,$1C,$00,$19,$1E,$11,$08
  DEFB $13,$13,$0D,$0C,$13,$17,$0C,$0F
  DEFB $1A,$2E,$FF,$13,$00,$3C,$0D,$06
  DEFB $10,$0D,$16,$10,$11,$0E,$14,$09
  DEFB $0A,$0B,$FF,$13,$E9,$3C,$14,$09
  DEFB $26,$0E,$13,$11,$0C,$0C,$2F,$10
  DEFB $0C,$2F,$0C,$1B,$2F,$10,$1B,$2F
  DEFB $0A,$0C,$26,$04,$0C,$11,$06,$19
  DEFB $2C,$08,$18,$2D,$00,$00,$03,$FF
  DEFB $14,$00,$26,$0A,$00,$26,$0C,$03
  DEFB $2F,$10,$03,$2F,$0C,$1A,$2F,$10
  DEFB $1A,$2F,$10,$14,$2C,$12,$13,$2D
  DEFB $06,$14,$2C,$08,$13,$2D,$08,$06
  DEFB $13,$08,$09,$14,$12,$0A,$27,$10
  DEFB $0F,$27,$FF,$14,$00,$26,$0C,$06
  DEFB $2F,$10,$06,$2F,$0A,$E9,$26,$04
  DEFB $05,$15,$09,$0E,$1C,$07,$12,$1C
  DEFB $07,$1C,$1C,$03,$10,$05,$14,$0B
  DEFB $16,$14,$12,$16,$14,$19,$16,$FF
  DEFB $14,$E9,$26,$13,$09,$3D,$0F,$05
  DEFB $28,$0D,$0F,$11,$10,$1C,$1A,$0B
  DEFB $15,$2F,$0F,$15,$2F,$09,$15,$17
  DEFB $08,$15,$21,$02,$15,$11,$07,$00
  DEFB $1C,$0A,$04,$1C,$FF,$13,$00,$3D
  DEFB $12,$0B,$22,$12,$0C,$21,$0B,$06
  DEFB $2F,$0F,$06,$2F,$0F,$0D,$2B,$0F
  DEFB $1C,$2B,$09,$E9,$17,$08,$E9,$21
  DEFB $03,$11,$2A,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$38,$38,$38
  DEFB $38,$38,$00,$38,$00,$6C,$6C,$6C
  DEFB $00,$00,$00,$00,$00,$6C,$6C,$FE
  DEFB $6C,$FE,$6C,$6C,$00,$18,$7E,$90
  DEFB $7C,$16,$FC,$30,$00,$60,$66,$0C
  DEFB $18,$30,$66,$46,$00,$70,$D8,$D8
  DEFB $70,$DA,$CC,$76,$00,$0C,$18,$30
  DEFB $00,$00,$00,$00,$00,$1C,$38,$70
  DEFB $70,$70,$38,$1C,$00,$70,$38,$1C
  DEFB $1C,$1C,$38,$70,$10,$30,$7F,$FF
  DEFB $FF,$7F,$30,$10,$00,$00,$38,$38
  DEFB $FE,$38,$38,$00,$00,$00,$00,$00
  DEFB $00,$1C,$1C,$70,$00,$00,$00,$00
  DEFB $FE,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$38,$38,$00,$08,$0C,$7E
  DEFB $7F,$7E,$0C,$08,$00,$7C,$F2,$F6
  DEFB $FA,$F2,$F2,$7C,$00,$3C,$7C,$3C
  DEFB $3C,$3C,$3C,$3C,$00,$7C,$9E,$1E
  DEFB $7C,$F0,$F0,$FE,$00,$FE,$1E,$3C
  DEFB $1E,$1E,$9E,$7C,$00,$F0,$F4,$F4
  DEFB $FE,$FE,$04,$04,$00,$FE,$F0,$FC
  DEFB $1E,$1E,$9E,$7C,$00,$3C,$70,$F0
  DEFB $FC,$F2,$F2,$7C,$00,$FE,$1E,$1E
  DEFB $3C,$78,$78,$78,$00,$7C,$F2,$F2
  DEFB $7C,$F2,$F2,$7C,$00,$7C,$F2,$F2
  DEFB $7E,$1E,$1C,$78,$00,$00,$00,$38
  DEFB $38,$00,$38,$38,$00,$00,$38,$38
  DEFB $00,$38,$38,$70,$00,$1C,$38,$70
  DEFB $E0,$70,$38,$1C,$00,$00,$FE,$00
  DEFB $00,$FE,$00,$00,$00,$70,$38,$1C
  DEFB $0E,$1C,$38,$70,$00,$7C,$E6,$0C
  DEFB $38,$38,$00,$38,$00,$7C,$E6,$EE
  DEFB $EA,$EE,$E0,$7C,$00,$7C,$F2,$F2
  DEFB $FE,$F2,$F2,$F2,$00,$FC,$F2,$FC
  DEFB $F2,$F2,$F2,$FC,$00,$7C,$F2,$F0
  DEFB $F0,$F0,$F2,$7C,$00,$FC,$F2,$F2
  DEFB $F2,$F2,$F2,$FC,$00,$FE,$F0,$F0
  DEFB $FC,$F0,$F0,$FE,$00,$FE,$F0,$F0
  DEFB $FC,$F0,$F0,$F0,$00,$7C,$F2,$F0
  DEFB $F6,$F2,$F2,$7C,$00,$F2,$F2,$F2
  DEFB $FE,$F2,$F2,$F2,$00,$FC,$78,$78
  DEFB $78,$78,$78,$FC,$00,$FC,$78,$78
  DEFB $78,$78,$78,$F0,$00,$F2,$F4,$F8
  DEFB $F0,$F8,$F4,$F2,$00,$F0,$F0,$F0
  DEFB $F0,$F0,$F0,$FE,$00,$F2,$FE,$F2
  DEFB $F2,$F2,$F2,$F2,$00,$F2,$FA,$F6
  DEFB $F2,$F2,$F2,$F2,$00,$7C,$F2,$F2
  DEFB $F2,$F2,$F2,$7C,$00,$FC,$F2,$F2
  DEFB $F2,$FC,$F0,$F0,$00,$7C,$F2,$F2
  DEFB $F2,$F2,$F4,$7A,$00,$FC,$F2,$F2
  DEFB $F2,$FC,$F2,$F2,$00,$7C,$F2,$F0
  DEFB $7C,$1E,$9E,$7C,$00,$FC,$78,$78
  DEFB $78,$78,$78,$78,$00,$F2,$F2,$F2
  DEFB $F2,$F2,$F2,$7C,$00,$F2,$F2,$F2
  DEFB $F2,$F2,$74,$38,$00,$F2,$F2,$F2
  DEFB $F2,$F2,$FE,$F2,$00,$C6,$6E,$3C
  DEFB $38,$7C,$E6,$C2,$00,$FA,$78,$3C
  DEFB $3C,$3C,$3C,$3C,$00,$FE,$1E,$3C
  DEFB $78,$F0,$E0,$FE,$00,$00,$01,$03
  DEFB $07,$0F,$1F,$00,$00,$7E,$5A,$7E
  DEFB $7E,$5A,$7E,$00,$00,$00,$80,$40
  DEFB $A0,$50,$A8,$00,$7F,$7F,$7F,$7F
  DEFB $7F,$7F,$7F,$00,$7E,$42,$5A,$5A
  DEFB $5A,$42,$7E,$00,$AA,$54,$AA,$54
  DEFB $AA,$54,$AA,$00,$00,$06,$0F,$0D
  DEFB $00,$2E,$2E,$00,$00,$DB,$F6,$B6
  DEFB $37,$16,$63,$79,$FD,$3A,$FD,$FE
  DEFB $FD,$FE,$FD,$D5,$00,$DB,$4F,$AD
  DEFB $4C,$A8,$46,$1E,$00,$60,$F0,$B0
  DEFB $00,$5C,$5C,$00,$34,$7A,$75,$7A
  DEFB $75,$00,$75,$3A,$00,$7F,$7F,$7F
  DEFB $7F,$7F,$7F,$7F,$00,$7E,$42,$5A
  DEFB $5A,$5A,$42,$7E,$00,$AA,$54,$AA
  DEFB $54,$AA,$54,$AA,$74,$FA,$F4,$FA
  DEFB $F4,$00,$FA,$74,$00,$14,$2A,$2E
  DEFB $5D,$5E,$5D,$00,$00,$3F,$1F,$0F
  DEFB $07,$03,$01,$00,$00,$7E,$5A,$7E
  DEFB $7E,$5A,$7E,$00,$00,$A8,$50,$A0
  DEFB $40,$80,$00,$00,$00,$28,$54,$5C
  DEFB $BA,$BC,$BA,$00,$54,$18,$24,$18
  DEFB $20,$10,$00,$08,$10,$00,$00,$00
  DEFB $00,$00,$00,$00,$22,$14,$28,$14
  DEFB $30,$28,$40,$10,$04,$10,$00,$08
  DEFB $00,$00,$00,$00,$2A,$54,$22,$56
  DEFB $24,$08,$24,$10,$04,$22,$08,$28
  DEFB $00,$08,$00,$08,$03,$00,$0F,$6F
  DEFB $00,$7F,$7F,$00,$C0,$00,$B0,$56
  DEFB $00,$D6,$AA,$00,$10,$14,$55,$5D
  DEFB $4D,$0A,$2A,$00,$88,$98,$59,$59
  DEFB $4A,$52,$14,$40,$00,$00,$02,$20
  DEFB $08,$0D,$25,$00,$00,$00,$02,$80
  DEFB $88,$AC,$AC,$00,$24,$00,$49,$1C
  DEFB $08,$42,$00,$08,$00,$08,$00,$2A
  DEFB $00,$08,$00,$00,$00,$00,$00,$10
  DEFB $44,$10,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$3C,$3C,$3C,$3C
  DEFB $3C,$3C,$3C,$3C,$13,$3A,$F3,$5A
  DEFB $03,$07,$00,$FF,$00,$08,$04,$84
  DEFB $84,$4E,$00,$FE,$00,$00,$00,$00
  DEFB $18,$3C,$3C,$00,$00,$10,$20,$21
  DEFB $21,$73,$00,$7F,$C8,$94,$CF,$95
  DEFB $C0,$A0,$00,$FF,$01,$03,$06,$0E
  DEFB $0C,$1A,$1A,$30,$80,$2A,$AA,$A8
  DEFB $A3,$8F,$3E,$FC,$02,$8E,$3E,$F8
  DEFB $E3,$8C,$30,$C4,$FF,$BD,$FF,$00
  DEFB $FF,$81,$B1,$A1,$40,$71,$7C,$1F
  DEFB $C7,$31,$0C,$03,$01,$54,$55,$15
  DEFB $C5,$F1,$7C,$3F,$80,$C0,$60,$70
  DEFB $30,$58,$58,$0C,$26,$1E,$32,$6E
  DEFB $5E,$DE,$FE,$BE,$EE,$7F,$BF,$DF
  DEFB $EF,$F7,$FB,$CD,$48,$24,$92,$C8
  DEFB $E4,$72,$F9,$FC,$A1,$A1,$A1,$A1
  DEFB $A1,$A1,$81,$FF,$02,$04,$09,$13
  DEFB $27,$4E,$9F,$3F,$77,$FE,$FD,$FA
  DEFB $F5,$EA,$D5,$B2,$64,$78,$74,$7A
  DEFB $7C,$7A,$7D,$7A,$FE,$FE,$FE,$7E
  DEFB $7E,$3E,$1E,$06,$D6,$D3,$D5,$D4
  DEFB $D5,$D5,$D5,$E5,$FE,$7E,$BA,$DE
  DEFB $6E,$36,$5A,$4C,$00,$FF,$FF,$FF
  DEFB $FF,$FF,$81,$7E,$7F,$7E,$5D,$7B
  DEFB $76,$6C,$5A,$32,$69,$CA,$A9,$2A
  DEFB $A9,$AA,$A9,$A2,$7D,$7A,$7D,$72
  DEFB $6A,$74,$58,$60,$F9,$3E,$0F,$03
  DEFB $00,$00,$00,$00,$56,$56,$96,$E6
  DEFB $FE,$3E,$0E,$02,$FF,$FF,$FF,$E7
  DEFB $DB,$DB,$DB,$DB,$4A,$6A,$49,$66
  DEFB $59,$64,$50,$40,$99,$64,$90,$40
  DEFB $00,$00,$00,$00,$5A,$18,$18,$18
  DEFB $18,$24,$18,$00,$00,$00,$00,$00
  DEFB $00,$02,$06,$1A,$1C,$26,$38,$3E
  DEFB $00,$3E,$7B,$75,$00,$00,$00,$00
  DEFB $00,$40,$60,$58,$38,$64,$1C,$7C
  DEFB $00,$7C,$F6,$EA,$00,$00,$FF,$00
  DEFB $00,$00,$00,$00,$00,$00,$FF,$55
  DEFB $00,$00,$00,$00,$03,$02,$03,$02
  DEFB $03,$02,$03,$0A,$02,$02,$02,$02
  DEFB $02,$02,$02,$02,$C0,$80,$C0,$80
  DEFB $C0,$80,$C0,$90,$40,$40,$40,$40
  DEFB $40,$40,$40,$40,$00,$00,$01,$03
  DEFB $07,$0E,$1F,$3A,$0F,$7E,$D2,$96
  DEFB $72,$D1,$F5,$EB,$B0,$5A,$82,$E0
  DEFB $61,$B0,$89,$C0,$00,$00,$80,$40
  DEFB $00,$90,$00,$04,$3F,$7F,$7F,$7F
  DEFB $FF,$FF,$FF,$FF,$CB,$95,$77,$CF
  DEFB $F9,$FF,$DF,$F7,$34,$3A,$C0,$A8
  DEFB $AA,$A3,$EC,$21,$94,$02,$C0,$06
  DEFB $10,$03,$A0,$01,$FF,$FF,$FF,$FF
  DEFB $7F,$7F,$7F,$3F,$FD,$E6,$FE,$FE
  DEFB $FB,$F7,$D9,$FD,$A6,$F4,$F3,$D1
  DEFB $4E,$88,$44,$94,$2C,$40,$00,$09
  DEFB $92,$08,$22,$04,$3F,$1F,$0E,$07
  DEFB $03,$01,$00,$00,$F7,$FB,$EF,$D4
  DEFB $FF,$AA,$7E,$07,$AC,$48,$23,$E0
  DEFB $42,$A1,$4A,$B0,$84,$00,$50,$40
  DEFB $00,$00,$00,$00,$06,$1B,$3E,$6D
  DEFB $7F,$FA,$FF,$FE,$A0,$48,$A0,$52
  DEFB $24,$C1,$B4,$A1,$FB,$FE,$FF,$76
  DEFB $7D,$3E,$1B,$06,$C8,$A5,$90,$A2
  DEFB $D0,$64,$50,$A0,$0E,$6C,$EE,$EC
  DEFB $EE,$EC,$6E,$0A,$00,$00,$00,$3F
  DEFB $3F,$00,$7E,$FF,$00,$00,$00,$E0
  DEFB $E0,$EF,$6F,$6F,$00,$00,$00,$00
  DEFB $00,$00,$60,$78,$BD,$FE,$FF,$FE
  DEFB $FD,$FE,$FD,$BE,$6E,$4F,$6E,$4F
  DEFB $6E,$4F,$6E,$4D,$7C,$7C,$7E,$7E
  DEFB $7A,$7E,$74,$6C,$FD,$6A,$00,$35
  DEFB $3A,$00,$7D,$7E,$26,$49,$A5,$40
  DEFB $A0,$00,$50,$B0,$58,$60,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$01,$02
  DEFB $00,$05,$05,$00,$00,$FF,$3F,$FF
  DEFB $00,$FF,$FF,$00,$00,$A8,$D4,$EA
  DEFB $00,$F5,$EB,$00,$05,$05,$05,$05
  DEFB $05,$05,$05,$04,$FF,$FF,$FF,$FF
  DEFB $FF,$FE,$FD,$AA,$F5,$EA,$F5,$EA
  DEFB $D5,$AA,$55,$AA,$60,$00,$F8,$FB
  DEFB $FA,$A8,$00,$00,$00,$00,$00,$FE
  DEFB $AA,$00,$00,$00,$30,$00,$7C,$7D
  DEFB $7D,$54,$00,$00,$00,$00,$00,$FE
  DEFB $54,$00,$00,$00,$18,$00,$3E,$3E
  DEFB $3E,$2A,$00,$00,$00,$00,$00,$FE
  DEFB $AA,$00,$00,$00,$0C,$00,$1F,$1F
  DEFB $1F,$15,$00,$00,$00,$00,$00,$7E
  DEFB $54,$00,$00,$00,$06,$00,$0F,$0F
  DEFB $0F,$0A,$00,$00,$00,$00,$80,$BE
  DEFB $AA,$80,$00,$00,$03,$00,$07,$07
  DEFB $07,$05,$00,$00,$00,$00,$C0,$DE
  DEFB $D4,$40,$00,$00,$01,$00,$03,$03
  DEFB $03,$02,$00,$00,$80,$00,$E0,$EE
  DEFB $EA,$A0,$00,$00,$00,$00,$01,$01
  DEFB $01,$01,$00,$00,$C0,$00,$F0,$F6
  DEFB $F4,$50,$00,$00,$3C,$75,$7B,$7C
  DEFB $3A,$0C,$6C,$E1,$18,$3C,$7A,$7C
  DEFB $1A,$C8,$E2,$D7,$19,$7B,$63,$D7
  DEFB $E4,$E1,$09,$9E,$EE,$6D,$86,$B1
  DEFB $2C,$F2,$FA,$EE,$87,$D7,$E7,$33
  DEFB $01,$7C,$FA,$F4,$B7,$CE,$9D,$9E
  DEFB $20,$79,$69,$F4,$3C,$BA,$3C,$05
  DEFB $F1,$E7,$D7,$C7,$FC,$80,$1C,$DB
  DEFB $9D,$CE,$AF,$CE,$FA,$3E,$18,$62
  DEFB $7E,$F8,$F5,$1C,$F8,$0C,$E1,$FB
  DEFB $F1,$EB,$F0,$70,$03,$E0,$E6,$D7
  DEFB $E7,$B7,$C3,$01,$E0,$CC,$1F,$DD
  DEFB $9A,$5C,$8C,$80,$00,$1C,$34,$7A
  DEFB $FC,$FA,$FC,$18,$00,$3C,$76,$7A
  DEFB $F4,$EE,$F0,$C0,$00,$70,$54,$FA
  DEFB $F5,$7A,$74,$D9,$00,$18,$74,$7D
  DEFB $7A,$3D,$DB,$EC,$18,$FC,$FA,$FC
  DEFB $7A,$34,$1C,$00,$C0,$F0,$EE,$F4
  DEFB $7A,$76,$3C,$00,$D9,$74,$7A,$F5
  DEFB $FA,$54,$70,$00,$EC,$DB,$3D,$7A
  DEFB $7D,$74,$18,$00,$6E,$48,$68,$40
  DEFB $6E,$48,$68,$40,$74,$46,$44,$06
  DEFB $74,$46,$44,$06,$6F,$48,$6B,$4B
  DEFB $6B,$4B,$68,$4D,$E4,$16,$C4,$D6
  DEFB $C4,$D6,$04,$56,$00,$14,$2E,$2E
  DEFB $00,$7F,$7E,$55,$00,$7F,$50,$72
  DEFB $75,$52,$70,$55,$00,$FE,$0A,$AC
  DEFB $4A,$A8,$0A,$54,$00,$28,$5C,$5C
  DEFB $00,$FE,$D4,$AA,$DF,$DF,$DF,$00
  DEFB $6F,$6F,$6F,$00,$D5,$EA,$55,$00
  DEFB $EA,$F4,$AA,$00,$00,$FE,$7C,$2E
  DEFB $14,$0A,$00,$00,$00,$FF,$C3,$C3
  DEFB $FF,$AA,$55,$00,$00,$7F,$3A,$74
  DEFB $28,$50,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$18,$3C,$7F,$3F,$1F,$0F
  DEFB $17,$1B,$19,$00,$7E,$7E,$7E,$7E
  DEFB $7E,$7E,$7E,$7E,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$54,$2A,$54,$2A
  DEFB $54,$2A,$54,$2A,$AA,$54,$A8,$50
  DEFB $A8,$58,$98,$00,$00,$3C,$18,$00
  DEFB $00,$00,$00,$00,$06,$1F,$2E,$73
  DEFB $77,$7F,$3F,$2F,$80,$20,$A0,$50
  DEFB $A0,$54,$A2,$51,$00,$00,$00,$00
  DEFB $00,$00,$01,$03,$1C,$0B,$00,$18
  DEFB $20,$A0,$40,$80,$A1,$41,$00,$00
  DEFB $01,$01,$00,$01,$80,$40,$C0,$A0
  DEFB $00,$40,$A0,$C0,$03,$06,$04,$05
  DEFB $03,$03,$03,$06,$40,$00,$A0,$D0
  DEFB $B3,$C0,$9E,$3F,$03,$00,$05,$1F
  DEFB $FE,$FD,$7A,$BC,$A0,$40,$40,$00
  DEFB $00,$00,$00,$18,$04,$01,$03,$05
  DEFB $06,$07,$03,$01,$DE,$FF,$FF,$7F
  DEFB $FF,$7F,$FF,$FF,$DA,$6C,$A5,$55
  DEFB $A1,$50,$A4,$56,$72,$FA,$FD,$FA
  DEFB $FD,$FE,$FD,$1A,$00,$03,$03,$18
  DEFB $34,$08,$60,$E0,$77,$07,$E2,$C0
  DEFB $B0,$3C,$7B,$38,$B4,$66,$8D,$1A
  DEFB $F5,$1A,$01,$07,$CC,$40,$64,$45
  DEFB $68,$4D,$A8,$45,$D0,$80,$38,$35
  DEFB $78,$73,$46,$1B,$13,$17,$0E,$1C
  DEFB $1D,$4A,$A9,$47,$07,$40,$B1,$10
  DEFB $40,$A8,$D4,$EA,$18,$71,$AA,$D1
  DEFB $66,$0D,$0A,$05,$3D,$7F,$7F,$BF
  DEFB $FF,$FF,$EE,$5C,$A7,$47,$A6,$4D
  DEFB $AB,$4B,$87,$07,$E0,$0A,$75,$FA
  DEFB $FD,$FA,$FC,$C2,$02,$01,$02,$A1
  DEFB $50,$A9,$08,$A0,$31,$05,$AA,$F5
  DEFB $FA,$75,$7A,$35,$4F,$2E,$AC,$49
  DEFB $C7,$1F,$39,$80,$15,$7E,$FF,$FE
  DEFB $FF,$EA,$C5,$92,$50,$AA,$55,$AE
  DEFB $50,$A3,$4F,$9C,$00,$00,$00,$01
  DEFB $07,$1F,$6E,$DC,$00,$00,$00,$00
  DEFB $00,$01,$03,$06,$00,$07,$1C,$72
  DEFB $C5,$AA,$55,$AB,$FF,$81,$54,$AB
  DEFB $5F,$BF,$FF,$FF,$00,$E0,$38,$CE
  DEFB $F3,$FD,$FE,$FF,$00,$00,$00,$00
  DEFB $00,$80,$C0,$60,$05,$0C,$09,$1A
  DEFB $19,$1A,$19,$0A,$57,$AF,$5F,$AF
  DEFB $5F,$BF,$5F,$BF,$F7,$F7,$EB,$EB
  DEFB $C9,$D9,$EA,$F5,$FF,$FF,$FF,$FF
  DEFB $FF,$57,$AF,$7F,$A0,$B0,$D0,$D8
  DEFB $D8,$D8,$D8,$D0,$0D,$04,$06,$03
  DEFB $01,$00,$00,$00,$5F,$AF,$5F,$2F
  DEFB $97,$CB,$73,$1C,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$7E,$FF,$FF,$FF,$FE
  DEFB $FD,$E3,$CE,$38,$B0,$A0,$60,$C0
  DEFB $80,$00,$00,$00,$07,$00,$00,$00
  DEFB $00,$00,$00,$00,$81,$FF,$00,$34
  DEFB $38,$34,$38,$34,$E0,$00,$00,$00
  DEFB $00,$00,$00,$00,$38,$34,$38,$34
  DEFB $38,$34,$38,$34,$00,$00,$0E,$1E
  DEFB $00,$3F,$7F,$7F,$00,$FF,$BD,$FF
  DEFB $00,$7E,$5A,$7E,$00,$00,$50,$68
  DEFB $00,$54,$AA,$54,$7F,$7F,$7F,$7F
  DEFB $7F,$7F,$7F,$7F,$7E,$7E,$7E,$42
  DEFB $5A,$5A,$5A,$5A,$AA,$54,$AA,$54
  DEFB $AA,$54,$AA,$54,$5A,$42,$7E,$7E
  DEFB $7E,$7E,$5A,$7E,$00,$00,$00,$00
  DEFB $00,$01,$01,$03,$00,$00,$00,$00
  DEFB $00,$00,$00,$80,$03,$07,$07,$07
  DEFB $07,$0F,$0F,$0F,$80,$40,$80,$40
  DEFB $A0,$40,$A0,$40,$00,$0E,$0F,$0F
  DEFB $0F,$0F,$2E,$6E,$00,$A0,$40,$A0
  DEFB $40,$A0,$C8,$AC,$00,$01,$03,$03
  DEFB $03,$00,$00,$00,$EE,$EE,$EE,$EE
  DEFB $EE,$0F,$0F,$0F,$CE,$AD,$CE,$AD
  DEFB $CA,$A0,$C0,$A0,$00,$00,$80,$00
  DEFB $80,$00,$00,$00,$00,$1F,$0A,$1F
  DEFB $00,$03,$03,$07,$06,$F4,$A6,$F4
  DEFB $06,$84,$46,$84,$00,$00,$00,$80
  DEFB $C0,$A0,$D0,$68,$07,$07,$08,$00
  DEFB $FF,$FF,$FF,$FF,$46,$C0,$20,$00
  DEFB $F5,$FA,$F5,$AA,$14,$0A,$15,$0A
  DEFB $55,$AA,$55,$AA,$00,$06,$0F,$0D
  DEFB $00,$2C,$2C,$00,$00,$DB,$F6,$B6
  DEFB $37,$16,$03,$FB,$00,$DB,$4F,$AD
  DEFB $4C,$A8,$40,$9F,$00,$60,$F0,$B0
  DEFB $00,$2C,$2C,$00,$5A,$5C,$5A,$5C
  DEFB $5A,$5C,$5A,$5C,$8B,$AB,$A8,$8B
  DEFB $FB,$00,$56,$3F,$51,$D5,$15,$D1
  DEFB $DF,$00,$6A,$FC,$00,$3C,$3C,$3C
  DEFB $3C,$3C,$3C,$00,$5E,$5E,$58,$5B
  DEFB $5A,$5A,$5A,$5B,$3F,$56,$00,$FB
  DEFB $0B,$E8,$0B,$FB,$FC,$6A,$00,$DF
  DEFB $D0,$17,$D0,$DF,$7A,$7C,$1A,$DC
  DEFB $5A,$5C,$5A,$DC,$00,$09,$33,$00
  DEFB $77,$00,$6F,$68,$00,$90,$CC,$00
  DEFB $EE,$00,$F6,$16,$6B,$68,$6B,$68
  DEFB $6B,$6C,$77,$7B,$D6,$16,$D6,$16
  DEFB $D6,$36,$EE,$DE,$00,$00,$01,$03
  DEFB $0F,$0F,$1E,$3C,$0F,$7F,$FF,$F0
  DEFB $C4,$09,$20,$80,$50,$F6,$FD,$0F
  DEFB $A3,$10,$04,$01,$00,$00,$80,$40
  DEFB $A0,$D0,$68,$34,$38,$79,$70,$74
  DEFB $E2,$E0,$E8,$E0,$94,$1A,$4E,$0C
  DEFB $47,$15,$06,$15,$E0,$E8,$E0,$E0
  DEFB $72,$70,$79,$38,$46,$15,$06,$25
  DEFB $0E,$0C,$5A,$9C,$3C,$1E,$0F,$07
  DEFB $03,$01,$00,$00,$40,$10,$08,$C1
  DEFB $F0,$FF,$7F,$0D,$00,$44,$00,$23
  DEFB $0F,$FD,$AA,$50,$34,$68,$D0,$A0
  DEFB $C0,$80,$00,$00,$00,$00,$00,$00
  DEFB $01,$03,$03,$00,$00,$37,$6F,$DF
  DEFB $BF,$7F,$7F,$00,$00,$D4,$EA,$F5
  DEFB $EA,$F5,$EA,$00,$00,$00,$00,$00
  DEFB $80,$40,$C0,$00,$37,$6F,$00,$EF
  DEFB $EF,$EF,$EF,$EF,$FF,$FF,$00,$FF
  DEFB $FF,$FF,$FF,$FF,$F5,$FA,$00,$FD
  DEFB $FA,$FD,$FA,$D5,$54,$AA,$00,$55
  DEFB $AA,$55,$AA,$55,$00,$FF,$80,$95
  DEFB $AA,$95,$AA,$95,$00,$FF,$00,$55
  DEFB $AA,$55,$AA,$55,$00,$FE,$00,$56
  DEFB $AA,$56,$AA,$56,$AA,$95,$AA,$95
  DEFB $AA,$95,$AA,$BF,$AA,$55,$AA,$55
  DEFB $AA,$55,$AA,$FF,$AA,$56,$AA,$56
  DEFB $AA,$56,$AA,$FE,$00,$FF,$80,$B6
  DEFB $A4,$A4,$80,$B6,$00,$FE,$00,$DA
  DEFB $92,$92,$02,$DA,$A4,$A4,$80,$B6
  DEFB $A4,$A4,$80,$BF,$92,$92,$02,$DA
  DEFB $92,$92,$02,$FE,$00,$70,$39,$3B
  DEFB $7B,$7B,$7D,$1E,$00,$55,$AA,$D5
  DEFB $FE,$FD,$DE,$EF,$00,$64,$AA,$55
  DEFB $AA,$55,$AA,$55,$66,$76,$7C,$1D
  DEFB $1F,$3E,$3F,$3C,$F3,$7D,$BE,$AE
  DEFB $6E,$6E,$77,$DF,$2A,$54,$AA,$C4
  DEFB $A0,$D0,$A8,$D0,$1B,$1B,$03,$37
  DEFB $37,$31,$31,$2D,$DB,$DB,$DF,$FF
  DEFB $7B,$FB,$FB,$FC,$A8,$D4,$A8,$E4
  DEFB $8A,$D4,$8A,$94,$6D,$6F,$6F,$6F
  DEFB $51,$4F,$37,$37,$F3,$77,$EB,$EF
  DEFB $4F,$6D,$FE,$E7,$68,$D4,$EA,$D4
  DEFB $E8,$D4,$6A,$94,$38,$3F,$7F,$7F
  DEFB $77,$77,$77,$4F,$F7,$6F,$5E,$DD
  DEFB $BC,$B5,$AA,$01,$CA,$94,$2A,$54
  DEFB $A8,$54,$AA,$54,$00,$01,$07,$0D
  DEFB $1F,$3A,$3F,$7F,$76,$C0,$55,$E8
  DEFB $B2,$D5,$E9,$B0,$00,$40,$10,$40
  DEFB $04,$50,$06,$28,$7F,$FF,$FB,$FF
  DEFB $FF,$FF,$FF,$7F,$E5,$B8,$EC,$EA
  DEFB $BC,$E8,$D4,$AA,$02,$D1,$04,$A3
  DEFB $08,$41,$92,$80,$7B,$3F,$35,$1F
  DEFB $0F,$06,$01,$00,$B5,$E0,$F4,$20
  DEFB $B3,$C8,$F2,$55,$22,$84,$04,$48
  DEFB $00,$60,$80,$00,$1F,$5F,$5F,$5F
  DEFB $5F,$5F,$1F,$00,$00,$7F,$7F,$7F
  DEFB $7F,$7F,$00,$00,$6A,$F5,$FA,$F5
  DEFB $FA,$F5,$2A,$00,$00,$60,$68,$6A
  DEFB $69,$61,$01,$01,$01,$61,$69,$6A
  DEFB $68,$60,$00,$00,$15,$55,$00,$9D
  DEFB $95,$00,$55,$15,$55,$55,$00,$FF
  DEFB $FF,$00,$55,$55,$55,$55,$00,$FB
  DEFB $FA,$00,$55,$55,$00,$40,$00,$A0
  DEFB $A0,$00,$40,$00,$00,$EF,$EF,$EF
  DEFB $EF,$EF,$EF,$EF,$00,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FD,$00,$55,$AA,$55
  DEFB $AA,$55,$AA,$55,$00,$37,$1B,$0D
  DEFB $06,$03,$01,$00,$00,$FF,$FE,$FD
  DEFB $FE,$7D,$AA,$00,$00,$54,$A8,$50
  DEFB $A0,$40,$80,$00,$34,$7A,$7C,$FB
  DEFB $FD,$00,$FD,$00,$00,$07,$1C,$33
  DEFB $6F,$DF,$DF,$E1,$FB,$F5,$7E,$FF
  DEFB $FE,$FF,$FD,$FE,$00,$60,$A8,$54
  DEFB $AA,$55,$2B,$87,$FD,$7A,$7C,$7A
  DEFB $7C,$7A,$7C,$7A,$7C,$7A,$7C,$7A
  DEFB $7C,$7A,$7C,$7A,$7C,$7A,$7C,$7A
  DEFB $7C,$7A,$74,$EA,$0E,$0F,$0F,$0F
  DEFB $0F,$07,$03,$00,$01,$7E,$7F,$7F
  DEFB $7F,$BF,$DF,$00,$55,$AA,$55,$AA
  DEFB $D5,$EA,$F5,$00,$00,$AA,$55,$AA
  DEFB $55,$AA,$55,$00,$70,$B0,$50,$A0
  DEFB $50,$A0,$40,$00,$6F,$6F,$6F,$6F
  DEFB $6F,$6F,$6F,$6F,$FE,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$D5,$AA,$54,$AA,$D4
  DEFB $AA,$D4,$AA,$54,$01,$01,$01,$01
  DEFB $01,$01,$02,$02,$02,$02,$02,$02
  DEFB $02,$02,$02,$02,$04,$04,$04,$04
  DEFB $04,$04,$04,$04,$04,$04,$08,$08
  DEFB $08,$08,$08,$08,$80,$80,$80,$80
  DEFB $80,$80,$40,$40,$40,$40,$40,$40
  DEFB $40,$40,$40,$40,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$10,$10
  DEFB $10,$10,$10,$10,$FF,$F7,$E7,$F7
  DEFB $F7,$F7,$F7,$E3,$FF,$E7,$DB,$FB
  DEFB $F7,$EF,$DF,$C3,$FF,$C3,$FB,$F7
  DEFB $FB,$FB,$DB,$E7,$FF,$F7,$EF,$DF
  DEFB $B7,$83,$F7,$F7,$FF,$C3,$DF,$C7
  DEFB $FB,$FB,$DB,$E7,$00,$00,$00,$00
  DEFB $00,$00,$00,$7E,$FF,$7E,$00,$00
  DEFB $00,$00,$00,$7E,$FF,$7E,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$30
  DEFB $0C,$03,$00,$00,$81,$41,$21,$11
  DEFB $09,$01,$CD,$2D,$81,$82,$84,$88
  DEFB $90,$80,$B3,$B4,$00,$00,$00,$0C
  DEFB $30,$C0,$00,$00,$0D,$01,$01,$01
  DEFB $00,$07,$07,$00,$B0,$80,$80,$80
  DEFB $00,$E0,$E0,$00,$00,$00,$00,$03
  DEFB $02,$00,$16,$16,$07,$1B,$38,$77
  DEFB $66,$EE,$CF,$DF,$E0,$D8,$C4,$1E
  DEFB $FA,$FD,$61,$0C,$00,$00,$00,$C0
  DEFB $40,$00,$68,$68,$16,$16,$00,$02
  DEFB $03,$00,$00,$00,$18,$FB,$FB,$63
  DEFB $6C,$2F,$1F,$07,$F5,$E6,$ED,$E6
  DEFB $72,$3C,$98,$E0,$68,$68,$00,$40
  DEFB $C0,$00,$00,$00,$00,$02,$02,$02
  DEFB $02,$05,$05,$05,$00,$C0,$C0,$C0
  DEFB $C0,$E0,$E0,$E0,$0B,$0B,$17,$00
  DEFB $6F,$6F,$6F,$00,$F0,$F0,$F8,$00
  DEFB $FA,$FC,$FA,$00,$6F,$6F,$6F,$6F
  DEFB $6F,$6F,$6F,$6F,$DA,$F4,$DA,$F4
  DEFB $DA,$F4,$DA,$F4,$03,$0F,$3F,$7F
  DEFB $7F,$7F,$7F,$7F,$E0,$F8,$F6,$FD
  DEFB $FA,$FD,$FE,$FD,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $01,$00,$00,$00,$01,$00,$00,$00
  DEFB $FF,$FF,$7F,$FF,$FF,$FF,$7F,$3F
  DEFB $DF,$EF,$F7,$FB,$E0,$C0,$80,$C0
  DEFB $EC,$F0,$F8,$FC,$00,$00,$00,$00
  DEFB $3F,$1F,$0F,$1F,$00,$00,$00,$00
  DEFB $FC,$E9,$D3,$A7,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$01,$03,$07,$0F
  DEFB $1F,$3F,$7F,$FF,$FF,$FF,$F8,$F0
  DEFB $FF,$FE,$FC,$F8,$FD,$FE,$03,$02
  DEFB $00,$00,$00,$00,$FE,$FF,$7F,$3F
  DEFB $1F,$0F,$0F,$1F,$3F,$7E,$FD,$FA
  DEFB $F4,$E9,$E9,$F4,$4E,$9D,$3A,$74
  DEFB $E8,$F0,$F8,$FD,$83,$07,$0E,$1D
  DEFB $3A,$74,$E9,$D3,$01,$03,$07,$0F
  DEFB $1F,$3F,$7F,$FF,$FE,$FC,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$00,$00,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$00,$00,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$BF,$DF,$EF,$F6
  DEFB $F8,$FC,$FE,$FF,$FA,$FD,$7E,$3F
  DEFB $1F,$3F,$7F,$FF,$7F,$3F,$9E,$4D
  DEFB $A6,$D0,$E9,$F7,$A7,$4F,$9F,$3F
  DEFB $7F,$FF,$FF,$FF,$00,$00,$00,$00
  DEFB $F7,$FB,$E9,$D3,$00,$00,$00,$00
  DEFB $FF,$FD,$FA,$F4,$00,$00,$00,$00
  DEFB $83,$07,$0F,$1F,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$00,$00,$00,$00
  DEFB $FF,$FF,$FE,$FD,$00,$00,$00,$00
  DEFB $7F,$BF,$9F,$3F,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$00,$00,$00,$00
  DEFB $FE,$FF,$FD,$FA,$A7,$4F,$9F,$3F
  DEFB $7E,$FD,$FA,$F4,$E8,$D0,$A0,$41
  DEFB $83,$07,$0F,$1E,$3F,$7F,$FD,$FA
  DEFB $F4,$E8,$D0,$A0,$FF,$FF,$07,$0F
  DEFB $1F,$3F,$7E,$FD,$FA,$F4,$E9,$D3
  DEFB $A7,$4F,$9F,$3F,$7F,$FF,$FA,$F4
  DEFB $E8,$D0,$A0,$41,$FF,$FF,$0F,$1F
  DEFB $3F,$7E,$FD,$FA,$F4,$E8,$D0,$A0
  DEFB $40,$80,$00,$00,$E8,$D0,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$3D,$00,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$41,$83,$DF,$EF
  DEFB $F7,$FB,$FC,$FE,$FA,$F4,$E9,$D3
  DEFB $A7,$4F,$9F,$3F,$7E,$FD,$FA,$F4
  DEFB $E8,$D0,$E8,$F5,$83,$07,$0F,$1F
  DEFB $3F,$7E,$FF,$FF,$F4,$E8,$D0,$A0
  DEFB $40,$80,$40,$A0,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$01
  DEFB $03,$07,$0F,$00,$00,$7E,$FD,$FA
  DEFB $F4,$FA,$FD,$00,$00,$FF,$80,$95
  DEFB $AA,$95,$AA,$FF,$00,$FE,$02,$56
  DEFB $AA,$56,$AA,$FE,$00,$FE,$82,$96
  DEFB $AA,$96,$AA,$FE,$00,$00,$00,$00
  DEFB $10,$00,$00,$00,$00,$00,$01,$19
  DEFB $38,$76,$6A,$0C,$0E,$E3,$FC,$F5
  DEFB $51,$77,$07,$67,$70,$78,$68,$81
  DEFB $D3,$AB,$D9,$A1,$00,$00,$00,$E0
  DEFB $E0,$F4,$E8,$C0,$00,$FF,$80,$95
  DEFB $AA,$95,$AA,$FF,$00,$FF,$00,$55
  DEFB $AA,$55,$AA,$FF,$00,$FF,$01,$55
  DEFB $AB,$55,$AB,$FF,$00,$7F,$6F,$3F
  DEFB $3F,$1F,$1F,$0F,$00,$7F,$6F,$7F
  DEFB $BF,$BF,$BF,$BF,$00,$FE,$F6,$FE
  DEFB $FD,$FD,$FD,$FD,$00,$D6,$EA,$D4
  DEFB $EC,$D0,$E8,$B0,$0F,$07,$07,$03
  DEFB $03,$01,$00,$00,$BF,$DF,$DF,$DF
  DEFB $5F,$DB,$EF,$00,$FD,$FB,$FB,$FA
  DEFB $FB,$DB,$F7,$00,$D0,$60,$A0,$C0
  DEFB $40,$80,$00,$00,$03,$0E,$3D,$FE
  DEFB $FD,$FE,$FF,$F5,$7F,$40,$4A,$55
  DEFB $4A,$55,$4A,$7F,$FE,$02,$AA,$56
  DEFB $AA,$56,$AA,$FE,$C0,$F0,$EC,$F5
  DEFB $FA,$FD,$FA,$D5,$00,$30,$75,$6D
  DEFB $CF,$4F,$31,$74,$00,$01,$F1,$D9
  DEFB $EB,$80,$23,$4F,$00,$C4,$DE,$FA
  DEFB $FD,$7B,$7E,$18,$00,$0C,$29,$78
  DEFB $73,$FB,$F5,$50,$F9,$75,$E1,$06
  DEFB $CE,$8F,$E6,$A5,$EF,$C7,$F3,$2C
  DEFB $9D,$01,$9F,$1A,$C1,$8E,$BE,$3C
  DEFB $9C,$51,$C3,$8B,$20,$4C,$FA,$FE
  DEFB $FB,$EC,$B5,$C0,$00,$30,$68,$FA
  DEFB $F4,$9A,$D4,$D9,$07,$1C,$33,$6F
  DEFB $5F,$DF,$FF,$FF,$E0,$D8,$F4,$FA
  DEFB $FA,$FD,$FA,$FD,$FF,$FF,$FF,$7F
  DEFB $7F,$3F,$1F,$07,$FA,$FD,$FB,$FC
  DEFB $FA,$F4,$F8,$E0,$00,$03,$03,$03
  DEFB $03,$03,$03,$03,$00,$C0,$C0,$C0
  DEFB $C0,$C0,$C0,$C0,$00,$0D,$00,$0D
  DEFB $00,$0D,$00,$0D,$00,$F0,$00,$F0
  DEFB $00,$F0,$00,$F0,$00,$1B,$1B,$37
  DEFB $37,$6F,$6F,$00,$00,$D8,$E8,$F4
  DEFB $E8,$F6,$EA,$00,$DF,$DF,$DF,$DF
  DEFB $DF,$DF,$EF,$6F,$F5,$FA,$F5,$FA
  DEFB $F5,$FA,$F5,$EA,$00,$6F,$6F,$6F
  DEFB $6F,$6F,$6F,$6F,$00,$D4,$EA,$D4
  DEFB $EA,$F4,$EA,$F4,$6F,$6F,$6F,$6F
  DEFB $6F,$6F,$6F,$6F,$EA,$F4,$EA,$F4
  DEFB $EA,$F4,$EA,$F4,$00,$3B,$77,$77
  DEFB $00,$77,$77,$77,$00,$FF,$FF,$FF
  DEFB $00,$FF,$FF,$FF,$00,$FF,$FF,$EA
  DEFB $00,$FA,$F5,$AA,$00,$EC,$56,$AA
  DEFB $00,$AA,$54,$AA,$6F,$68,$6B,$6A
  DEFB $6B,$6A,$6B,$6A,$EA,$14,$CA,$54
  DEFB $CA,$54,$CA,$54,$6B,$6A,$6B,$6A
  DEFB $6B,$68,$6F,$6F,$CA,$54,$CA,$54
  DEFB $CA,$14,$EA,$F4,$00,$7E,$7E,$7E
  DEFB $7E,$7E,$7E,$00,$7A,$7C,$7A,$7C
  DEFB $7A,$7C,$7A,$7C,$00,$3F,$7F,$00
  DEFB $7F,$7F,$7F,$3F,$00,$FF,$FF,$00
  DEFB $FF,$FF,$FF,$FD,$00,$54,$AA,$00
  DEFB $AA,$D4,$AA,$54,$00,$37,$75,$77
  DEFB $77,$75,$37,$00,$3F,$60,$6A,$6A
  DEFB $6A,$6A,$60,$3F,$FE,$03,$AB,$AB
  DEFB $AB,$AA,$01,$EA,$00,$60,$70,$54
  DEFB $64,$50,$60,$00,$00,$00,$00,$00
  DEFB $00,$03,$0F,$3F,$00,$03,$0F,$3F
  DEFB $FF,$FF,$FF,$FF,$00,$FF,$80,$BF
  DEFB $AF,$BF,$80,$FF,$00,$FC,$06,$F2
  DEFB $D4,$F2,$04,$EA,$00,$3E,$5A,$7E
  DEFB $7E,$5A,$3E,$00,$00,$00,$FF,$FF
  DEFB $AA,$55,$00,$00,$00,$7F,$6F,$7F
  DEFB $7F,$6F,$3F,$00,$00,$FF,$EF,$FF
  DEFB $FF,$EF,$FF,$00,$00,$FF,$EF,$FF
  DEFB $FF,$EF,$FD,$00,$00,$AA,$D4,$AA
  DEFB $D4,$AA,$54,$00,$15,$55,$00,$9D
  DEFB $95,$00,$55,$15,$55,$55,$00,$FF
  DEFB $FF,$00,$55,$55,$54,$52,$00,$DD
  DEFB $D5,$00,$52,$54,$00,$7F,$40,$55
  DEFB $4A,$55,$4A,$55,$00,$FE,$02,$56
  DEFB $AA,$56,$AA,$56,$4A,$55,$4A,$55
  DEFB $4A,$55,$7F,$00,$AA,$56,$AA,$56
  DEFB $AA,$56,$FE,$00,$00,$03,$FB,$F6
  DEFB $16,$ED,$ED,$DB,$DB,$B7,$B7,$6F
  DEFB $6A,$D5,$C0,$00,$37,$37,$36,$39
  DEFB $27,$1E,$79,$67,$E6,$9E,$78,$E4
  DEFB $98,$74,$F8,$F4,$00,$01,$07,$0F
  DEFB $1E,$3C,$3C,$64,$7E,$E3,$C7,$E7
  DEFB $7C,$58,$44,$C7,$00,$80,$E0,$D0
  DEFB $78,$34,$7C,$E2,$67,$C7,$CF,$DC
  DEFB $70,$1E,$01,$00,$8F,$FF,$C0,$1A
  DEFB $F4,$FA,$7C,$7A,$C2,$C1,$D6,$1D
  DEFB $0A,$A8,$80,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$01,$7D,$FE,$7D,$7E
  DEFB $FD,$FE,$FD,$FE,$00,$00,$00,$00
  DEFB $00,$80,$00,$80,$03,$00,$03,$03
  DEFB $07,$0F,$36,$5F,$FD,$F0,$05,$FE
  DEFB $FD,$FA,$F5,$CB,$C0,$00,$40,$80
  DEFB $50,$A0,$58,$6D,$00,$3F,$7F,$63
  DEFB $55,$49,$55,$49,$00,$FF,$FF,$C7
  DEFB $AB,$93,$AB,$93,$00,$54,$AA,$84
  DEFB $52,$24,$52,$24,$55,$49,$55,$49
  DEFB $55,$49,$55,$49,$AB,$93,$AB,$93
  DEFB $AB,$93,$AB,$93,$52,$24,$52,$24
  DEFB $52,$24,$52,$24,$55,$49,$55,$49
  DEFB $55,$63,$7F,$3F,$AB,$93,$AB,$93
  DEFB $AB,$C7,$FF,$FF,$52,$24,$52,$24
  DEFB $52,$8C,$EA,$54,$01,$03,$07,$0F
  DEFB $1E,$3F,$7D,$F6,$FD,$9A,$94,$E8
  DEFB $D0,$A0,$40,$80,$01,$03,$06,$0F
  DEFB $1E,$3F,$7D,$F4,$FD,$BA,$F4,$E8
  DEFB $D0,$A0,$40,$80,$FD,$9A,$94,$E8
  DEFB $D0,$A0,$40,$80,$FE,$79,$39,$1F
  DEFB $0F,$07,$03,$01,$80,$40,$A0,$D0
  DEFB $68,$F4,$BA,$ED,$FE,$7D,$3F,$1F
  DEFB $0F,$07,$03,$01,$80,$40,$20,$D0
  DEFB $68,$F4,$BA,$AD,$FE,$79,$39,$1F
  DEFB $0F,$07,$03,$01,$FF,$C0,$DF,$D7
  DEFB $DF,$DF,$DF,$DF,$FE,$01,$FA,$E9
  DEFB $FA,$F9,$FA,$F9,$DF,$DF,$D7,$DF
  DEFB $C0,$FF,$7F,$00,$FA,$F9,$EA,$F9
  DEFB $02,$FD,$FA,$00,$1F,$1F,$00,$1F
  DEFB $1F,$0F,$07,$00,$D8,$E8,$00,$D8
  DEFB $E8,$D0,$E0,$00,$03,$00,$05,$00
  DEFB $03,$03,$03,$00,$40,$00,$A0,$00
  DEFB $C0,$C0,$C0,$00,$07,$1F,$39,$75
  DEFB $6B,$E7,$EF,$FF,$E0,$F8,$F4,$FA
  DEFB $FE,$FD,$FA,$FD,$FF,$FF,$FF,$7F
  DEFB $7F,$3F,$1F,$07,$FA,$FD,$FB,$FE
  DEFB $FA,$F4,$D8,$E0,$00,$FF,$80,$AE
  DEFB $AE,$A0,$BF,$83,$00,$FF,$00,$ED
  DEFB $ED,$E1,$ED,$0D,$00,$FE,$00,$AA
  DEFB $A8,$8A,$B8,$BA,$BB,$BB,$83,$BB
  DEFB $BB,$BB,$80,$AA,$6D,$61,$7F,$01
  DEFB $ED,$ED,$00,$AA,$B8,$BA,$80,$EA
  DEFB $E8,$EA,$00,$AA,$00,$FF,$80,$BF
  DEFB $AE,$BF,$BF,$BF,$00,$FE,$00,$FA
  DEFB $E8,$FA,$F8,$FA,$AF,$BF,$BF,$BF
  DEFB $AE,$BF,$80,$AA,$E8,$FA,$F8,$FA
  DEFB $E8,$FA,$00,$AA,$00,$77,$74,$77
  DEFB $70,$77,$75,$76,$00,$FF,$00,$FF
  DEFB $00,$FF,$FF,$00,$00,$EA,$24,$EA
  DEFB $04,$EA,$A4,$6A,$76,$76,$76,$76
  DEFB $76,$76,$76,$76,$64,$6A,$64,$6A
  DEFB $64,$6A,$64,$6A,$76,$75,$77,$70
  DEFB $77,$74,$75,$74,$00,$FF,$FF,$00
  DEFB $FF,$00,$55,$AA,$64,$AA,$E4,$0A
  DEFB $E4,$2A,$64,$AA,$00,$FF,$BD,$FF
  DEFB $FF,$BD,$FF,$00,$00,$7F,$40,$5F
  DEFB $5E,$5D,$5E,$5D,$00,$FE,$00,$FA
  DEFB $88,$2A,$78,$2A,$5E,$5D,$5E,$5F
  DEFB $5F,$40,$55,$00,$08,$0A,$88,$0A
  DEFB $F8,$02,$54,$00,$7C,$7C,$7E,$3E
  DEFB $3F,$1F,$0F,$07,$3E,$3E,$7E,$7C
  DEFB $3C,$98,$D0,$E0,$03,$0D,$1E,$3E
  DEFB $3E,$7C,$7C,$7C,$F0,$F8,$F8,$7C
  DEFB $7C,$3E,$3E,$3E,$00,$E0,$F8,$FC
  DEFB $FE,$FE,$1D,$03,$00,$07,$1F,$3F
  DEFB $7F,$FF,$FC,$F0,$07,$1F,$FF,$FF
  DEFB $FE,$F8,$E0,$00,$E0,$CC,$9F,$7F
  DEFB $3F,$1F,$07,$00,$C0,$00,$E0,$00
  DEFB $14,$00,$77,$00,$14,$00,$E0,$00
  DEFB $C0,$00,$00,$00,$30,$00,$38,$00
  DEFB $05,$00,$1D,$C0,$05,$00,$38,$00
  DEFB $30,$00,$00,$00,$0C,$00,$0E,$00
  DEFB $01,$40,$07,$70,$01,$40,$0E,$00
  DEFB $0C,$00,$00,$00,$03,$00,$03,$80
  DEFB $00,$50,$01,$DC,$00,$50,$03,$80
  DEFB $03,$00,$00,$00,$00,$00,$03,$00
  DEFB $07,$00,$28,$00,$EE,$00,$28,$00
  DEFB $07,$00,$03,$00,$00,$00,$00,$C0
  DEFB $01,$C0,$0A,$00,$3B,$80,$0A,$00
  DEFB $01,$C0,$00,$C0,$00,$00,$00,$30
  DEFB $00,$70,$02,$80,$0E,$E0,$02,$80
  DEFB $00,$70,$00,$30,$00,$00,$00,$0C
  DEFB $00,$1C,$00,$A0,$03,$B8,$00,$A0
  DEFB $00,$1C,$00,$0C,$1C,$00,$14,$84
  DEFB $70,$00,$C9,$08,$B8,$20,$D2,$00
  DEFB $70,$04,$14,$20,$07,$00,$49,$00
  DEFB $1F,$10,$3D,$40,$A6,$04,$34,$A0
  DEFB $1C,$08,$45,$00,$01,$C0,$11,$48
  DEFB $07,$82,$2C,$D0,$8A,$80,$0D,$A0
  DEFB $27,$04,$01,$40,$04,$70,$00,$D4
  DEFB $09,$E0,$21,$24,$02,$61,$53,$C8
  DEFB $01,$C2,$04,$50,$14,$00,$40,$00
  DEFB $15,$00,$88,$00,$54,$00,$81,$00
  DEFB $24,$00,$08,$00,$05,$00,$10,$00
  DEFB $05,$40,$22,$00,$15,$00,$20,$40
  DEFB $09,$00,$02,$00,$01,$40,$04,$00
  DEFB $01,$50,$08,$80,$05,$40,$08,$10
  DEFB $02,$40,$00,$80,$00,$50,$01,$00
  DEFB $00,$54,$02,$20,$01,$50,$02,$04
  DEFB $00,$90,$00,$20,$10,$00,$04,$00
  DEFB $28,$00,$52,$00,$08,$00,$50,$00
  DEFB $04,$00,$00,$00,$04,$00,$01,$00
  DEFB $0A,$00,$14,$80,$02,$00,$14,$00
  DEFB $01,$00,$00,$00,$01,$00,$00,$40
  DEFB $02,$80,$05,$20,$00,$80,$05,$00
  DEFB $00,$40,$00,$00,$00,$40,$00,$10
  DEFB $00,$A0,$01,$48,$00,$20,$01,$40
  DEFB $00,$10,$00,$00,$00,$00,$08,$00
  DEFB $00,$00,$2A,$00,$10,$00,$08,$00
  DEFB $00,$00,$00,$00,$00,$00,$02,$00
  DEFB $00,$00,$0A,$80,$04,$00,$02,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$80
  DEFB $00,$00,$02,$A0,$01,$00,$00,$80
  DEFB $00,$00,$00,$00,$00,$00,$00,$20
  DEFB $00,$00,$00,$A8,$00,$40,$00,$20
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$3C,$00,$7E,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $7E,$00,$3C,$00,$0F,$00,$1F,$80
  DEFB $3F,$C0,$3F,$C0,$3F,$C0,$3F,$C0
  DEFB $1F,$80,$0F,$00,$00,$00,$03,$C0
  DEFB $07,$E0,$07,$E0,$07,$E0,$07,$E0
  DEFB $03,$C0,$00,$00,$00,$00,$00,$F0
  DEFB $01,$F8,$01,$F8,$01,$F8,$01,$F8
  DEFB $00,$F0,$00,$00,$00,$00,$00,$00
  DEFB $2F,$00,$EF,$00,$2F,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $0B,$C0,$3B,$C0,$0B,$C0,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $02,$F0,$0E,$F0,$02,$F0,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$BC,$03,$BC,$00,$BC,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$88,$0D,$CF
  DEFB $70,$0B,$B7,$40,$1B,$4B,$78,$16
  DEFB $B5,$B0,$02,$7A,$C0,$0F,$7B,$70
  DEFB $1E,$BB,$00,$0E,$EB,$30,$01,$F0
  DEFB $7F,$01,$FD,$86,$00,$7D,$F8,$01
  DEFB $81,$B8,$00,$FC,$30,$02,$00,$00
  DEFB $05,$54,$00,$0A,$A0,$00,$34,$16
  DEFB $00,$03,$EE,$00,$0F,$9E,$00,$1F
  DEFB $0F,$00,$15,$0A,$80,$7C,$07,$00
  DEFB $F0,$07,$00,$E0,$03,$20,$70,$07
  DEFB $E0,$3C,$07,$80,$00,$00,$00,$00
  DEFB $00,$00,$00,$10,$00,$00,$20,$00
  DEFB $00,$21,$E0,$00,$C7,$F0,$06,$6F
  DEFB $88,$0D,$CF,$70,$0B,$B7,$40,$1B
  DEFB $4B,$78,$16,$B5,$B0,$02,$7A,$C0
  DEFB $0E,$FB,$70,$1D,$7B,$00,$0D,$D7
  DEFB $60,$03,$E0,$FE,$03,$FB,$0C,$00
  DEFB $FB,$F0,$01,$03,$70,$00,$FC,$60
  DEFB $02,$00,$00,$05,$54,$00,$0A,$A2
  DEFB $00,$14,$17,$00,$21,$F7,$00,$02
  DEFB $EE,$00,$02,$CA,$00,$0F,$4E,$00
  DEFB $0E,$1C,$00,$0C,$0C,$00,$0C,$1E
  DEFB $00,$04,$1F,$80,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$20,$00
  DEFB $00,$C1,$E0,$06,$67,$F0,$0D,$CF
  DEFB $88,$0B,$B7,$70,$1B,$4B,$40,$16
  DEFB $B5,$78,$02,$7A,$B0,$0E,$FB,$50
  DEFB $1D,$7B,$20,$0D,$D7,$60,$03,$E0
  DEFB $FE,$03,$FB,$0C,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$00
  DEFB $05,$54,$00,$02,$A0,$00,$05,$18
  DEFB $00,$08,$FC,$00,$01,$78,$00,$07
  DEFB $A0,$00,$07,$08,$00,$07,$38,$00
  DEFB $06,$70,$00,$02,$30,$00,$00,$78
  DEFB $00,$00,$7E,$00,$00,$10,$00,$00
  DEFB $20,$00,$00,$21,$E0,$00,$C7,$F0
  DEFB $06,$6F,$88,$0D,$CF,$70,$0B,$B7
  DEFB $40,$1B,$4B,$78,$16,$B5,$B0,$02
  DEFB $7A,$C0,$0E,$FB,$70,$1D,$7B,$00
  DEFB $0D,$D7,$60,$03,$E0,$FE,$03,$FB
  DEFB $0C,$00,$FB,$F0,$01,$03,$70,$00
  DEFB $FC,$60,$02,$00,$00,$01,$54,$00
  DEFB $02,$A2,$00,$05,$0F,$00,$02,$CF
  DEFB $80,$04,$97,$80,$01,$7D,$00,$01
  DEFB $F0,$00,$02,$78,$00,$01,$1E,$00
  DEFB $01,$80,$00,$01,$80,$00,$03,$C0
  DEFB $00,$03,$F0,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$88,$0D,$CF
  DEFB $70,$0B,$B7,$40,$1B,$4B,$78,$16
  DEFB $B5,$B0,$02,$7A,$C0,$0E,$FB,$70
  DEFB $1D,$7B,$00,$0D,$D7,$60,$03,$E0
  DEFB $FE,$03,$FB,$0C,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$00
  DEFB $05,$54,$00,$0A,$A2,$00,$05,$1F
  DEFB $00,$08,$EF,$80,$00,$F3,$80,$01
  DEFB $45,$40,$05,$43,$80,$03,$83,$80
  DEFB $07,$07,$00,$0E,$07,$80,$0F,$01
  DEFB $E0,$07,$C0,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$88,$0D,$CF
  DEFB $70,$0B,$B7,$40,$1B,$4B,$78,$16
  DEFB $B5,$B0,$02,$7A,$C0,$0E,$FB,$70
  DEFB $1D,$7B,$00,$0D,$D7,$60,$03,$E0
  DEFB $FE,$03,$FB,$0C,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$00
  DEFB $05,$54,$00,$0A,$A4,$00,$34,$1E
  DEFB $00,$03,$BE,$00,$0F,$9E,$00,$1F
  DEFB $0F,$00,$15,$0A,$80,$7C,$07,$00
  DEFB $F0,$07,$00,$E0,$03,$20,$70,$07
  DEFB $E0,$3C,$07,$80,$00,$00,$00,$00
  DEFB $00,$00,$00,$10,$00,$00,$20,$00
  DEFB $00,$21,$E0,$00,$C7,$F0,$06,$6F
  DEFB $88,$0D,$CF,$70,$0B,$B7,$40,$1B
  DEFB $4B,$78,$16,$B5,$B0,$02,$7A,$C0
  DEFB $0E,$FB,$70,$1D,$7B,$00,$0D,$D7
  DEFB $60,$03,$E0,$FE,$03,$FB,$0C,$00
  DEFB $FB,$F0,$01,$03,$70,$00,$FC,$60
  DEFB $02,$00,$00,$05,$54,$00,$0A,$A2
  DEFB $00,$14,$1F,$00,$21,$DF,$00,$02
  DEFB $DE,$00,$02,$AA,$00,$0F,$5E,$00
  DEFB $0E,$1C,$00,$0C,$0C,$00,$0C,$1E
  DEFB $00,$04,$1F,$80,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$20,$00
  DEFB $00,$C1,$E0,$06,$67,$F0,$0D,$CF
  DEFB $88,$0B,$B7,$70,$1B,$4B,$40,$16
  DEFB $B5,$78,$02,$7A,$B0,$0E,$FB,$40
  DEFB $1D,$7B,$30,$0D,$D7,$60,$03,$E0
  DEFB $FE,$03,$FB,$0C,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$00
  DEFB $05,$54,$00,$02,$A0,$00,$05,$18
  DEFB $00,$08,$F8,$00,$01,$78,$00,$06
  DEFB $70,$00,$06,$A8,$00,$06,$78,$00
  DEFB $06,$70,$00,$02,$30,$00,$00,$78
  DEFB $00,$00,$7E,$00,$00,$10,$00,$00
  DEFB $20,$00,$00,$21,$E0,$00,$C7,$F0
  DEFB $06,$6F,$88,$0D,$CF,$70,$0B,$B7
  DEFB $40,$1B,$4B,$78,$16,$B5,$B0,$02
  DEFB $7A,$C0,$0E,$FB,$70,$1D,$7B,$00
  DEFB $0D,$D7,$60,$03,$E0,$FE,$03,$FB
  DEFB $0C,$00,$FB,$F0,$01,$03,$70,$00
  DEFB $FC,$60,$02,$00,$00,$05,$54,$00
  DEFB $02,$A2,$00,$05,$1B,$00,$0A,$F7
  DEFB $80,$04,$F7,$80,$09,$ED,$00,$01
  DEFB $E0,$00,$02,$A8,$00,$03,$DE,$00
  DEFB $03,$80,$00,$01,$80,$00,$03,$C0
  DEFB $00,$03,$F0,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$88,$0D,$CF
  DEFB $70,$0B,$B7,$40,$1B,$4B,$78,$16
  DEFB $B5,$B0,$02,$7A,$C0,$0E,$FB,$70
  DEFB $1D,$7B,$00,$0D,$D7,$60,$03,$E0
  DEFB $FE,$03,$FB,$0C,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$00
  DEFB $05,$54,$00,$0A,$A2,$00,$05,$1B
  DEFB $00,$08,$F7,$80,$00,$E3,$80,$03
  DEFB $E5,$40,$02,$A3,$80,$03,$83,$80
  DEFB $07,$07,$00,$0E,$07,$80,$0F,$01
  DEFB $E0,$07,$C0,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$08
  DEFB $00,$00,$10,$00,$00,$10,$F0,$00
  DEFB $63,$F8,$03,$37,$C4,$06,$E7,$B8
  DEFB $05,$DB,$A0,$0D,$A5,$BC,$0B,$5A
  DEFB $D8,$01,$3D,$60,$07,$7D,$B8,$0E
  DEFB $BD,$80,$06,$EB,$B0,$01,$F0,$7F
  DEFB $01,$FD,$86,$00,$7D,$F8,$00,$81
  DEFB $B8,$00,$7E,$30,$01,$00,$80,$02
  DEFB $AB,$C0,$05,$57,$A0,$30,$02,$60
  DEFB $7E,$F0,$E0,$FC,$E0,$60,$CD,$E0
  DEFB $F0,$45,$C0,$FC,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$E0,$00,$01,$A0
  DEFB $00,$06,$80,$00,$07,$00,$00,$0A
  DEFB $00,$00,$0C,$E0,$00,$5D,$F0,$06
  DEFB $DD,$88,$0C,$BD,$70,$09,$BD,$40
  DEFB $1B,$5B,$78,$16,$71,$B0,$02,$FA
  DEFB $D7,$0E,$FB,$6D,$1E,$7B,$14,$0C
  DEFB $77,$68,$01,$86,$70,$01,$FE,$C0
  DEFB $01,$FE,$00,$01,$FC,$00,$00,$FC
  DEFB $00,$02,$00,$02,$01,$54,$02,$02
  DEFB $A8,$D6,$05,$53,$5D,$02,$A7,$95
  DEFB $05,$4F,$EB,$0A,$02,$DF,$10,$00
  DEFB $5E,$00,$00,$16,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$80,$0D,$CF
  DEFB $78,$0B,$B7,$78,$1B,$4B,$78,$16
  DEFB $B5,$B8,$02,$7A,$C0,$0F,$7B,$70
  DEFB $1E,$BB,$00,$0E,$EB,$31,$01,$F0
  DEFB $7F,$01,$FD,$81,$00,$7D,$F8,$01
  DEFB $81,$B8,$00,$FC,$30,$02,$00,$41
  DEFB $07,$FC,$7F,$0F,$E0,$31,$3C,$16
  DEFB $00,$03,$EE,$00,$0F,$9E,$00,$1F
  DEFB $0F,$00,$15,$0A,$80,$7C,$07,$00
  DEFB $F0,$07,$00,$E0,$03,$20,$70,$07
  DEFB $E0,$3C,$07,$80,$00,$00,$00,$00
  DEFB $00,$00,$00,$10,$00,$00,$20,$00
  DEFB $00,$21,$E0,$00,$C7,$F0,$06,$6F
  DEFB $80,$0D,$CF,$78,$0B,$B7,$78,$1B
  DEFB $4B,$78,$16,$B5,$B8,$02,$7A,$C0
  DEFB $0E,$FB,$70,$1D,$7B,$00,$0D,$D7
  DEFB $62,$03,$E0,$FE,$03,$FB,$02,$00
  DEFB $FB,$F0,$01,$03,$70,$00,$FC,$60
  DEFB $02,$00,$82,$07,$FC,$FE,$0F,$E2
  DEFB $62,$1C,$17,$00,$21,$F7,$00,$02
  DEFB $EE,$00,$02,$CA,$00,$0F,$4E,$00
  DEFB $0E,$1C,$00,$0C,$0C,$00,$0C,$1E
  DEFB $00,$04,$1F,$80,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$20,$00
  DEFB $00,$C1,$E0,$06,$67,$F0,$0D,$CF
  DEFB $80,$0B,$B7,$78,$1B,$4B,$78,$16
  DEFB $B5,$78,$02,$7A,$B8,$0E,$FB,$40
  DEFB $1D,$7B,$20,$0D,$D7,$62,$03,$E0
  DEFB $FE,$03,$FB,$02,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$82
  DEFB $07,$FC,$FE,$07,$E0,$62,$05,$18
  DEFB $00,$08,$FC,$00,$01,$78,$00,$07
  DEFB $A0,$00,$07,$08,$00,$07,$38,$00
  DEFB $06,$70,$00,$02,$30,$00,$00,$78
  DEFB $00,$00,$7E,$00,$00,$10,$00,$00
  DEFB $20,$00,$00,$21,$E0,$00,$C7,$F0
  DEFB $06,$6F,$80,$0D,$CF,$78,$0B,$B7
  DEFB $78,$1B,$4B,$78,$16,$B5,$B8,$02
  DEFB $7A,$C0,$0E,$FB,$70,$1D,$7B,$00
  DEFB $0D,$D7,$62,$03,$E0,$FE,$03,$FB
  DEFB $02,$00,$FB,$F0,$01,$03,$70,$00
  DEFB $FC,$60,$02,$00,$82,$03,$FC,$FE
  DEFB $03,$E2,$62,$07,$0F,$00,$06,$CF
  DEFB $80,$04,$97,$80,$01,$7D,$00,$01
  DEFB $F0,$00,$02,$78,$00,$01,$1E,$00
  DEFB $01,$80,$00,$01,$80,$00,$03,$C0
  DEFB $00,$03,$F0,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$80,$0D,$CF
  DEFB $78,$0B,$B7,$78,$1B,$4B,$78,$16
  DEFB $B5,$B8,$02,$7A,$C0,$0E,$FB,$70
  DEFB $1D,$7B,$00,$0D,$D7,$62,$03,$E0
  DEFB $FE,$03,$FB,$02,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$82
  DEFB $07,$FC,$FE,$0F,$E2,$62,$0D,$1F
  DEFB $00,$08,$EF,$80,$00,$F3,$80,$01
  DEFB $45,$40,$05,$43,$80,$03,$83,$80
  DEFB $07,$07,$00,$0E,$07,$80,$0F,$01
  DEFB $E0,$07,$C0,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$80,$0D,$CF
  DEFB $78,$0B,$B7,$78,$1B,$4B,$78,$16
  DEFB $B5,$B8,$02,$7A,$C0,$0E,$FB,$70
  DEFB $1D,$7B,$00,$0D,$D7,$62,$03,$E0
  DEFB $FE,$03,$FB,$02,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$82
  DEFB $07,$F4,$FE,$0F,$E4,$62,$3C,$1E
  DEFB $00,$03,$BE,$00,$0F,$9E,$00,$1F
  DEFB $0F,$00,$15,$0A,$80,$7C,$07,$00
  DEFB $F0,$07,$00,$E0,$03,$20,$70,$07
  DEFB $E0,$3C,$07,$80,$00,$00,$00,$00
  DEFB $00,$00,$00,$10,$00,$00,$20,$00
  DEFB $00,$21,$E0,$00,$C7,$F0,$06,$6F
  DEFB $80,$0D,$CF,$78,$0B,$B7,$78,$1B
  DEFB $4B,$78,$16,$B5,$B8,$02,$7A,$C0
  DEFB $0E,$FB,$70,$1D,$7B,$00,$0D,$D7
  DEFB $62,$03,$E0,$FE,$03,$FB,$02,$00
  DEFB $FB,$F0,$01,$03,$70,$00,$FC,$60
  DEFB $02,$00,$82,$07,$FC,$FE,$0F,$E2
  DEFB $62,$1C,$1F,$00,$21,$DF,$00,$02
  DEFB $DE,$00,$02,$AA,$00,$0F,$5E,$00
  DEFB $0E,$1C,$00,$0C,$0C,$00,$0C,$1E
  DEFB $00,$04,$1F,$80,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$20,$00
  DEFB $00,$C1,$E0,$06,$67,$F0,$0D,$CF
  DEFB $80,$0B,$B7,$78,$1B,$4B,$78,$16
  DEFB $B5,$78,$02,$7A,$B8,$0E,$FB,$40
  DEFB $1D,$7B,$30,$0D,$D7,$62,$03,$E0
  DEFB $FE,$03,$FB,$02,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$82
  DEFB $07,$F4,$FE,$07,$E0,$62,$07,$18
  DEFB $00,$08,$F8,$00,$01,$78,$00,$06
  DEFB $70,$00,$06,$A8,$00,$06,$78,$00
  DEFB $06,$70,$00,$02,$30,$00,$00,$78
  DEFB $00,$00,$7E,$00,$00,$10,$00,$00
  DEFB $20,$00,$00,$21,$E0,$00,$C7,$F0
  DEFB $06,$6F,$80,$0D,$CF,$78,$0B,$B7
  DEFB $78,$1B,$4B,$78,$16,$B5,$B8,$02
  DEFB $7A,$C0,$0E,$FB,$70,$1D,$7B,$00
  DEFB $0D,$D7,$62,$03,$E0,$FE,$03,$FB
  DEFB $02,$00,$FB,$F0,$01,$03,$70,$00
  DEFB $FC,$60,$02,$00,$82,$07,$FC,$FE
  DEFB $07,$E2,$62,$07,$1B,$00,$0E,$F7
  DEFB $80,$0C,$F7,$80,$09,$ED,$00,$01
  DEFB $E0,$00,$02,$A8,$00,$03,$DE,$00
  DEFB $03,$80,$00,$01,$80,$00,$03,$C0
  DEFB $00,$03,$F0,$00,$00,$00,$00,$00
  DEFB $10,$00,$00,$20,$00,$00,$21,$E0
  DEFB $00,$C7,$F0,$06,$6F,$80,$0D,$CF
  DEFB $78,$0B,$B7,$78,$1B,$4B,$78,$16
  DEFB $B5,$B8,$02,$7A,$C0,$0E,$FB,$70
  DEFB $1D,$7B,$00,$0D,$D7,$62,$03,$E0
  DEFB $FE,$03,$FB,$02,$00,$FB,$F0,$01
  DEFB $03,$70,$00,$FC,$60,$02,$00,$82
  DEFB $07,$FC,$FE,$0F,$E2,$62,$0F,$1B
  DEFB $00,$08,$F7,$80,$00,$E3,$80,$03
  DEFB $E5,$40,$02,$A3,$80,$03,$83,$80
  DEFB $07,$07,$00,$0E,$07,$80,$0F,$01
  DEFB $E0,$07,$C0,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$08
  DEFB $00,$00,$10,$00,$00,$10,$F0,$00
  DEFB $63,$F8,$03,$37,$C0,$06,$E7,$BC
  DEFB $05,$DB,$BC,$0D,$A5,$BC,$0B,$5A
  DEFB $DC,$01,$3D,$60,$07,$7D,$B8,$0E
  DEFB $BD,$80,$06,$EB,$B1,$01,$F0,$7F
  DEFB $01,$FD,$81,$00,$7D,$F8,$00,$81
  DEFB $B8,$00,$7E,$30,$01,$00,$41,$03
  DEFB $FB,$7F,$07,$F7,$B1,$30,$02,$40
  DEFB $7E,$F0,$E0,$FC,$E0,$60,$CD,$E0
  DEFB $F0,$45,$C0,$FC,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$E0,$00,$01,$A0
  DEFB $00,$06,$80,$00,$07,$00,$00,$0A
  DEFB $00,$00,$0C,$E0,$00,$5D,$F0,$06
  DEFB $DD,$80,$0C,$BD,$78,$09,$BD,$78
  DEFB $1B,$5B,$78,$16,$71,$B8,$02,$FA
  DEFB $D7,$0E,$FB,$6D,$1E,$7B,$14,$0C
  DEFB $77,$68,$01,$86,$70,$01,$FE,$C0
  DEFB $01,$FE,$00,$01,$FC,$00,$00,$FC
  DEFB $00,$02,$00,$02,$03,$FC,$02,$03
  DEFB $F8,$D6,$07,$F3,$5D,$07,$E7,$95
  DEFB $07,$4F,$EB,$0A,$02,$DF,$10,$00
  DEFB $5E,$00,$00,$16,$FF,$F5,$55,$C0
  DEFB $00,$02,$DF,$FE,$A9,$C0,$00,$02
  DEFB $FF,$D5,$55,$00,$00,$00,$00,$34
  DEFB $00,$00,$38,$00,$00,$34,$00,$00
  DEFB $38,$00,$00,$34,$00,$00,$38,$00
  DEFB $00,$34,$00,$00,$38,$00,$00,$34
  DEFB $00,$00,$38,$00,$00,$00,$00,$01
  DEFB $6A,$80,$02,$FD,$40,$06,$FE,$A0
  DEFB $0D,$FD,$50,$1B,$FE,$A8,$3B,$FD
  DEFB $54,$00,$00,$00,$EF,$FD,$55,$EF
  DEFB $FE,$AA,$EF,$FD,$55,$EF,$FE,$AA
  DEFB $EF,$FD,$55,$EF,$FE,$AA,$EF,$FD
  DEFB $55,$EF,$EA,$AA,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$07,$6C,$1E,$01
  DEFB $35,$C0,$44,$10,$4E,$00,$9E,$00
  DEFB $9C,$00,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$7E,$00,$7C,$10,$3D,$C0
  DEFB $1E,$01,$07,$6C,$07,$68,$1E,$04
  DEFB $35,$C1,$44,$00,$4E,$10,$9E,$00
  DEFB $9C,$00,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$7E,$10,$7C,$00,$3D,$C1
  DEFB $1E,$04,$07,$68,$07,$60,$1E,$0C
  DEFB $35,$80,$44,$41,$4E,$00,$9E,$10
  DEFB $9C,$00,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$10,$7E,$00,$7C,$41,$3D,$80
  DEFB $1E,$0C,$07,$60,$07,$68,$1E,$04
  DEFB $35,$C1,$44,$00,$4E,$10,$9E,$00
  DEFB $9C,$00,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$7E,$10,$7C,$00,$3D,$C1
  DEFB $1E,$04,$07,$68,$00,$00,$02,$40
  DEFB $07,$E0,$12,$48,$38,$1C,$11,$08
  DEFB $42,$80,$E5,$24,$4B,$CE,$05,$A4
  DEFB $23,$80,$70,$10,$24,$B8,$0F,$D0
  DEFB $04,$80,$00,$00,$00,$00,$02,$40
  DEFB $05,$A0,$12,$48,$28,$14,$10,$08
  DEFB $40,$80,$A2,$C4,$45,$8A,$02,$84
  DEFB $20,$00,$50,$10,$24,$A8,$0B,$50
  DEFB $04,$80,$00,$00,$00,$00,$02,$40
  DEFB $05,$A0,$10,$08,$20,$04,$10,$08
  DEFB $41,$80,$83,$04,$41,$82,$01,$04
  DEFB $20,$00,$40,$00,$20,$28,$0B,$50
  DEFB $04,$80,$00,$00,$00,$00,$02,$40
  DEFB $01,$20,$00,$00,$20,$04,$10,$08
  DEFB $00,$00,$81,$00,$41,$82,$00,$04
  DEFB $00,$00,$40,$00,$20,$08,$02,$50
  DEFB $04,$80,$00,$00,$00,$00,$00,$00
  DEFB $01,$20,$00,$00,$00,$00,$10,$08
  DEFB $00,$00,$00,$00,$40,$00,$00,$04
  DEFB $00,$00,$00,$00,$20,$00,$02,$50
  DEFB $04,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$01,$02,$BE
  DEFB $37,$7F,$F6,$BF,$37,$7F,$02,$BE
  DEFB $00,$01,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$03,$00,$07
  DEFB $00,$0F,$00,$1E,$00,$01,$02,$BE
  DEFB $37,$7F,$F6,$BF,$37,$7F,$02,$BE
  DEFB $00,$01,$00,$1E,$00,$0F,$00,$07
  DEFB $00,$03,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $01,$00,$03,$80,$01,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$01,$00,$01,$00
  DEFB $03,$80,$0F,$E0,$03,$80,$01,$00
  DEFB $01,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $01,$00,$01,$00,$01,$00,$05,$40
  DEFB $03,$80,$3F,$F8,$03,$80,$05,$40
  DEFB $01,$00,$01,$00,$01,$00,$00,$00
  DEFB $00,$00,$00,$00,$01,$00,$00,$00
  DEFB $01,$00,$11,$10,$01,$00,$05,$40
  DEFB $03,$80,$BF,$FA,$03,$80,$05,$40
  DEFB $01,$00,$11,$10,$01,$00,$00,$00
  DEFB $01,$00,$00,$00,$07,$E0,$1F,$F8
  DEFB $33,$F4,$6F,$FA,$5F,$FE,$DF,$FD
  DEFB $FF,$FB,$FF,$FE,$FF,$FD,$FF,$FE
  DEFB $FF,$FD,$7F,$FA,$7F,$FE,$3F,$F4
  DEFB $1F,$F8,$07,$E0,$00,$00,$03,$C0
  DEFB $0F,$F0,$19,$E8,$37,$F4,$2F,$FA
  DEFB $6F,$F4,$7F,$FA,$7F,$F4,$7F,$FA
  DEFB $3F,$F4,$3F,$FC,$1F,$E8,$0F,$F0
  DEFB $03,$C0,$00,$00,$00,$00,$00,$00
  DEFB $01,$80,$07,$E0,$0C,$D0,$1B,$E8
  DEFB $17,$F8,$37,$F4,$3F,$F8,$1F,$F4
  DEFB $1F,$E8,$0F,$F0,$07,$E0,$01,$80
  DEFB $00,$00,$00,$00,$00,$00,$03,$C0
  DEFB $0F,$F0,$19,$E8,$37,$F4,$2F,$FA
  DEFB $6F,$F4,$7F,$FA,$7F,$F4,$7F,$FA
  DEFB $3F,$F4,$3F,$FC,$1F,$E8,$0F,$F0
  DEFB $03,$C0,$00,$00,$BC,$00,$3D,$80
  DEFB $01,$B8,$00,$34,$03,$BA,$1B,$BE
  DEFB $5B,$BD,$DB,$BE,$DB,$BD,$5B,$BF
  DEFB $1B,$BC,$03,$BA,$00,$34,$01,$B8
  DEFB $3D,$80,$BC,$00,$00,$00,$BD,$80
  DEFB $3D,$B8,$00,$34,$03,$BA,$1B,$BE
  DEFB $5B,$BD,$DB,$BE,$DB,$BD,$5B,$BF
  DEFB $1B,$BC,$03,$BA,$00,$34,$3D,$B8
  DEFB $BD,$80,$00,$00,$00,$00,$01,$80
  DEFB $BD,$B8,$3C,$34,$03,$BA,$1B,$BE
  DEFB $5B,$BD,$DB,$BE,$DB,$BD,$5B,$BF
  DEFB $1B,$BC,$03,$BA,$3C,$34,$BD,$B8
  DEFB $01,$80,$00,$00,$00,$00,$BD,$80
  DEFB $3D,$B8,$00,$34,$03,$BA,$1B,$BE
  DEFB $5B,$BD,$DB,$BE,$DB,$BD,$5B,$BF
  DEFB $1B,$BC,$03,$BA,$00,$34,$3D,$B8
  DEFB $BD,$80,$00,$00,$00,$00,$00,$07
  DEFB $01,$6F,$00,$1F,$00,$3F,$00,$01
  DEFB $02,$FE,$36,$FF,$F6,$C0,$36,$FF
  DEFB $02,$FE,$00,$01,$00,$3F,$00,$1F
  DEFB $01,$6F,$00,$07,$00,$00,$00,$07
  DEFB $00,$AF,$00,$1F,$00,$3F,$00,$01
  DEFB $02,$FE,$36,$FF,$F6,$C0,$36,$FF
  DEFB $02,$FE,$00,$01,$00,$3F,$00,$1F
  DEFB $00,$AF,$00,$07,$00,$00,$00,$07
  DEFB $00,$4F,$00,$1F,$00,$3F,$00,$01
  DEFB $02,$FE,$36,$FF,$F6,$C0,$36,$FF
  DEFB $02,$FE,$00,$01,$00,$3F,$00,$1F
  DEFB $00,$4F,$00,$07,$00,$00,$00,$07
  DEFB $00,$AF,$00,$1F,$00,$3F,$00,$01
  DEFB $02,$FE,$36,$FF,$F6,$C0,$36,$FF
  DEFB $02,$FE,$00,$01,$00,$3F,$00,$1F
  DEFB $00,$AF,$00,$07,$00,$00,$00,$00
  DEFB $00,$60,$01,$A0,$06,$10,$18,$10
  DEFB $60,$10,$80,$08,$00,$08,$00,$09
  DEFB $00,$0A,$00,$06,$00,$04,$00,$00
  DEFB $00,$00,$00,$00,$04,$00,$0C,$00
  DEFB $0A,$00,$12,$00,$22,$00,$21,$00
  DEFB $41,$01,$81,$02,$81,$04,$00,$88
  DEFB $00,$88,$00,$90,$00,$60,$00,$40
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$10,$80,$10
  DEFB $40,$28,$20,$28,$10,$28,$0C,$44
  DEFB $02,$44,$01,$82,$00,$82,$00,$03
  DEFB $00,$01,$00,$01,$20,$00,$30,$00
  DEFB $30,$00,$48,$00,$48,$00,$44,$00
  DEFB $44,$00,$42,$01,$82,$06,$81,$18
  DEFB $81,$60,$80,$80,$80,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$10,$00,$18,$00,$28,$80,$24
  DEFB $40,$42,$20,$42,$10,$41,$08,$80
  DEFB $04,$80,$03,$00,$01,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$20,$00,$30
  DEFB $00,$50,$00,$48,$00,$88,$00,$84
  DEFB $00,$82,$01,$02,$01,$01,$82,$00
  DEFB $42,$00,$42,$00,$24,$00,$14,$00
  DEFB $18,$00,$08,$00,$02,$00,$05,$00
  DEFB $09,$00,$10,$81,$20,$81,$40,$41
  DEFB $80,$42,$00,$22,$00,$24,$00,$14
  DEFB $00,$14,$00,$08,$00,$08,$00,$00
  DEFB $00,$00,$00,$00,$01,$00,$82,$80
  DEFB $84,$40,$44,$20,$48,$10,$48,$10
  DEFB $50,$08,$30,$04,$20,$02,$00,$01
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$30,$00,$F8
  DEFB $03,$CC,$0D,$B6,$31,$B7,$C1,$CE
  DEFB $7F,$FC,$02,$AE,$02,$AE,$7F,$FC
  DEFB $C1,$CE,$31,$B7,$0D,$B6,$03,$CC
  DEFB $00,$F8,$00,$30,$00,$03,$00,$07
  DEFB $00,$4F,$02,$DF,$00,$00,$00,$3E
  DEFB $6F,$7F,$E9,$7F,$E9,$7F,$6F,$7F
  DEFB $00,$3E,$00,$00,$02,$DF,$00,$4F
  DEFB $00,$07,$00,$03,$00,$03,$00,$07
  DEFB $00,$4F,$02,$DF,$00,$00,$00,$3E
  DEFB $6F,$7F,$E9,$7F,$E9,$7F,$6F,$7F
  DEFB $00,$3E,$00,$00,$02,$DF,$00,$4F
  DEFB $00,$07,$00,$03,$00,$03,$00,$07
  DEFB $00,$4F,$02,$DF,$00,$00,$00,$3E
  DEFB $6F,$7F,$EF,$7F,$EF,$7F,$6F,$7F
  DEFB $00,$3E,$00,$00,$02,$DF,$00,$4F
  DEFB $00,$07,$00,$03,$00,$03,$00,$07
  DEFB $00,$4F,$02,$DF,$00,$00,$00,$3E
  DEFB $6F,$7F,$EF,$7F,$EF,$7F,$6F,$7F
  DEFB $00,$3E,$00,$00,$02,$DF,$00,$4F
  DEFB $00,$07,$00,$03,$00,$03,$03,$87
  DEFB $06,$8F,$0C,$9F,$18,$BF,$10,$80
  DEFB $5F,$B8,$D0,$BB,$D0,$BB,$5F,$B8
  DEFB $10,$80,$18,$BF,$0C,$9F,$06,$8F
  DEFB $03,$87,$00,$03,$00,$03,$03,$87
  DEFB $06,$8F,$0C,$9F,$18,$BF,$10,$80
  DEFB $5F,$B8,$D0,$BB,$D0,$BB,$5F,$B8
  DEFB $10,$80,$18,$BF,$0C,$9F,$06,$8F
  DEFB $03,$87,$00,$03,$00,$03,$03,$87
  DEFB $06,$8F,$0C,$9F,$18,$BF,$10,$80
  DEFB $5F,$B8,$D0,$BB,$D0,$BB,$5F,$B8
  DEFB $10,$80,$18,$BF,$0C,$9F,$06,$8F
  DEFB $03,$87,$00,$03,$00,$03,$03,$87
  DEFB $06,$8F,$0C,$9F,$18,$BF,$10,$80
  DEFB $5F,$B8,$D0,$BB,$D0,$BB,$5F,$B8
  DEFB $10,$80,$18,$BF,$0C,$9F,$06,$8F
  DEFB $03,$87,$00,$03,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$F3,$0D,$CE,$0B
  DEFB $E2,$50,$CE,$0B,$E3,$50,$1E,$17
  DEFB $DC,$0A,$CE,$0B,$E4,$50,$1D,$17
  DEFB $03,$1A,$FF,$FF,$FF,$FF,$DB,$02
  DEFB $4D,$00,$DB,$02,$4D,$00,$DB,$02
  DEFB $4D,$00,$BD,$58,$43,$02,$BC,$58
  DEFB $4C,$38,$C0,$57,$71,$0E,$F3,$0D
  DEFB $21,$17,$C6,$1E,$5F,$6D,$76,$1B
  DEFB $03,$13,$00,$3E,$00,$3C,$42,$42
  DEFB $7E,$42,$42,$00,$00,$7C,$42,$7C
  DEFB $42,$42,$7C,$00,$00,$3C,$42,$40
  DEFB $40,$42,$3C,$00,$00,$78,$44,$42
  DEFB $42,$44,$78,$00,$F3,$AF,$32,$DB
  DEFB $FF,$CD,$A7,$FF,$B7,$28,$17,$57
  DEFB $CD,$A7,$FF,$67,$CD,$A7,$FF,$6F
  DEFB $CD,$A7,$FF,$77,$23,$E6,$07,$D3
  DEFB $FE,$15,$20,$F4,$18,$E3,$3A,$DB
  DEFB $FF,$67,$CD,$A7,$FF,$BC,$C2,$00
  DEFB $00,$FB,$C9,$3E,$FE,$D3,$EF,$DB
  DEFB $F7,$07,$30,$F7,$DB,$F7,$07,$30
  DEFB $F2,$DB,$F7,$07,$30,$ED,$06,$23
  DEFB $10,$FE,$0E,$80,$DB,$F7,$07,$06
  DEFB $19,$10,$FE,$CB,$19,$30,$F5,$3E
  DEFB $EE,$D3,$EF,$79,$2F,$4F,$3A,$DB
  DEFB $FF,$A9,$32,$DB,$FF,$79,$C9,$00
  DEFB $30,$F2,$DB,$F7,$07,$30,$ED,$06
  DEFB $23,$10,$FE,$0E,$80,$DB,$F7,$07
  DEFB $06,$19,$10,$FE,$CB,$19,$30,$F5
  DEFB $3E,$EE,$D3,$EF,$79,$2F,$C9,$42
  DEFB $42,$42,$3C,$00

