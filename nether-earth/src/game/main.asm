; the entry from N1: the IM 2 table, the start-up, the menu
;
; Used by the routines at l_A69A, sub_AE6B and l_C282.
Start:
  DI
  LD SP,$0000
  LD HL,$FE00
  LD BC,$00FD
l_A60A:
  LD (HL),C
  INC HL
  DJNZ l_A60A
  LD (HL),C
  LD A,$C3
  LD ($FDFD),A
  LD HL,StartInterrupt
  LD ($FDFE),HL
  LD A,$FE
  LD I,A
  IM 2
  EI
  LD HL,$3039
  LD ($FD00),HL
  LD ($FD02),HL
  CALL sub_C100

; l_A62D
l_A62D:
  JR NZ,l_A68E
  LD HL,data_D6A8+$0358
  LD DE,data_D6A8+$0359
  LD BC,$02FF
  LD (HL),$00
  LDIR
  LD HL,$FD04
  LD DE,$FD05
  LD BC,$00F8
  LD (HL),$00
  LDIR
  LD HL,$FF01
  LD DE,$FF02
  LD BC,$00C8
  LD (HL),$00
  LDIR
  LD HL,data_D6A8+$012B
  LD DE,data_D6A8+$012C
  LD BC,$002C
  LD (HL),$00
  LDIR
  LD HL,data_D6A8+$0658
  LD (MapView),HL
  LD HL,$0000
  LD (ViewX),HL
  LD HL,$0011
  LD (ShipX),HL
  LD A,$0A
  LD (ShipY),A
  XOR A
  LD ($FD10),A
  LD A,$03
  LD ($FD30),A
  LD A,$14
  LD ($FD22),A
  LD ($FD4A),A
  CALL sub_BC6F

; l_A68E
;
; Used by the routines at l_A62D and l_A69A.
l_A68E:
  CALL sub_CFD7
  CALL sub_D0CA
  LD HL,PlayInterrupt
  LD ($FDFE),HL

; l_A69A
l_A69A:
  CALL WaitKey
  CALL MoveShip
  CALL sub_B0CA
  CALL sub_CCBD
  CALL sub_AD62
  CALL sub_CCA0
  BIT 6,(HL)
  JR Z,l_A70D
  CALL sub_CDD8
  JR NZ,l_A6C8
  LD A,B
  CP $19
  JR C,l_A70D
  LD A,($FD10)
  SUB (IY+$09)
  SUB (IY+$0D)
  CALL Z,sub_A720
  JR l_A70D
l_A6C8:
  CALL sub_CDF5
  JR NZ,l_A70D
  LD A,(IY+$02)
  OR A
  JR NZ,l_A70D
  LD A,($FD10)
  CP $0F
  JR NZ,l_A70D
  LD L,(IY+$00)
  LD A,(IY+$01)
  ADD A,$08
  LD H,A
  LD A,(HL)
  INC H
  INC H
  OR (HL)
  DEC HL
  OR (HL)
  INC HL
  INC HL
  OR (HL)
  AND $40
  JR NZ,l_A70D
  CALL sub_C849
  LD (IY+$05),$04
  LD (IY+$06),$05
  LD (IY+$0B),$00
  LD (IY+$0C),$64
  LD (IY+$0F),$01
  CALL sub_BB40
  CALL sub_D293
l_A70D:
  LD A,(Input)
  BIT 6,A
  JP NZ,Start
  BIT 5,A
  JP Z,l_A69A
  CALL sub_C28D
  JP l_A68E

; sub_A720
;
; Used by the routine at l_A69A.
sub_A720:
  PUSH IY
  POP IX
  LD (IX+$0A),$01
  LD A,$04
  LD ($FD1F),A
  LD A,$01
  LD ($FD39),A
; This entry point is used by the routines at l_A93B, sub_A941 and l_AB52.
l_A732:
  CALL sub_D2F6
  CALL sub_D42D
  LD BC,$1704
  LD (BC),A
  LD C,L
  LD B,H
  LD C,C
  LD D,D
  LD B,L
  LD B,E
  LD D,H
  JR NZ,l_A765
  INC BC
  JR NZ,l_A78B
  LD C,A
  LD C,(HL)
  LD D,H
  LD D,D
  LD C,A
  LD C,H
  INC BC
  INC BC
  LD B,A
  LD C,C
  LD D,(HL)
  LD B,L
  JR NZ,l_A776
  JR NZ,l_A778
  INC BC
  JR NZ,l_A77B
  LD C,A
  LD D,D
  LD B,H
  LD B,L
  LD D,D
  LD D,E
  INC BC
  INC BC
  LD B,E
  LD C,A
l_A765:
  LD C,L
  LD B,D
  LD B,C
  LD D,H
  JR NZ,l_A78B
  INC BC
  JR NZ,l_A78E
  JR NZ,l_A790
  LD C,L
  LD C,A
  LD B,H
  LD B,L
  INC BC
  INC BC
l_A776:
  LD C,H
  LD B,L
l_A778:
  LD B,C
  LD D,(HL)
  LD B,L
l_A77B:
  JR NZ,$A79D
  JR NZ,$A782
  JR NZ,$A7A1
  JR NZ,l_A7D5
  LD C,A
  LD B,D
  LD C,A
  LD D,H
  LD BC,$1711
  LD (BC),A
l_A78B:
  LD B,(HL)
  DEC L
  LD C,A
l_A78E:
  LD D,D
  LD B,H
l_A790:
  LD B,L
  LD D,D
  LD D,E
  DEC L
  NOP
  LD B,(IX+$0B)
  INC B
  LD HL,sub_A81D+$0010
  LD DE,$001B
l_A79F:
  ADD HL,DE
  DJNZ l_A79F
  LD DE,l_A79F+$0013
  LD BC,$001B
  LDIR
  CALL sub_D42D
  LD BC,$1712
  LD (BC),A
  LD B,L
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD A,(IX+$0B)
  DEC A
  CP $02
  JR NC,l_A7E4
l_A7D5:
  CALL sub_D42D
  LD BC,$1913
  NOP
  LD A,(IX+$0E)
  SRL A
  CALL sub_D3E5
l_A7E4:
  CALL sub_A81D
  LD HL,$5837
  LD E,$05
  LD A,($FD1F)
  CALL sub_ACD7
  LD ($FD1F),A
  DEC A
  JP Z,l_A93B
  DEC A
  JP Z,l_A971
  DEC A
  JP Z,l_AC00
  LD A,$78
  CALL sub_CCAC
  XOR A
  LD (IX+$06),A
  LD (IX+$0A),A
  LD A,$05
  LD ($FD30),A
; This entry point is used by the routines at sub_A941, l_AB52 and sub_ACD7.
l_A812:
  CALL sub_D2F6
  XOR A
  LD ($FD39),A
  CALL sub_D1E5
  RET

; sub_A81D
;
; Used by the routines at sub_A720, sub_A941, l_AB52 and sub_ACD7.
sub_A81D:
  CALL sub_D42D
  LD BC,$1716
  LD (BC),A
  LD B,(HL)
  LD D,E
  LD D,H
  LD D,D
  LD B,L
  LD C,(HL)
  LD B,A
  LD D,H
  LD C,B
  LD BC,$1917
  LD (BC),A
  LD B,A
  NOP
  LD A,(IX+$0C)
  OR A
  JP P,l_A83B
  XOR A
l_A83B:
  LD L,A
  LD H,$00
  LD E,$20
  CALL sub_D401
  LD A,$25
  JP sub_D427

; data_A848
data_A848:
  DEFB $20,$20,$53,$54,$4F,$50,$20,$20
  DEFB $03,$20,$20,$41,$4E,$44,$20,$20
  DEFB $20,$03,$20,$44,$45,$46,$45,$4E
  DEFB $44,$20,$00,$41,$44,$56,$41,$4E
  DEFB $43,$45,$20,$03,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$03,$20,$4D,$49
  DEFB $4C,$45,$53,$20,$20,$00,$52,$45
  DEFB $54,$52,$45,$41,$54,$20,$03,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$03
  DEFB $20,$4D,$49,$4C,$45,$53,$20,$20
  DEFB $00,$44,$45,$53,$54,$52,$4F,$59
  DEFB $20,$03,$20,$45,$4E,$45,$4D,$59
  DEFB $20,$20,$03,$20,$52,$4F,$42,$4F
  DEFB $54,$53,$20,$00,$44,$45,$53,$54
  DEFB $52,$4F,$59,$20,$03,$20,$45,$4E
  DEFB $45,$4D,$59,$20,$20,$03,$46,$41
  DEFB $43,$54,$4F,$52,$59,$53,$00,$44
  DEFB $45,$53,$54,$52,$4F,$59,$20,$03
  DEFB $20,$45,$4E,$45,$4D,$59,$20,$20
  DEFB $03,$57,$41,$52,$42,$41,$53,$45
  DEFB $53,$00,$43,$41,$50,$54,$55,$52
  DEFB $45,$20,$03,$4E,$45,$55,$54,$52
  DEFB $41,$4C,$20,$03,$46,$41,$43,$54
  DEFB $4F,$52,$59,$53,$00,$43,$41,$50
  DEFB $54,$55,$52,$45,$20,$03,$20,$45
  DEFB $4E,$45,$4D,$59,$20,$20,$03,$46
  DEFB $41,$43,$54,$4F,$52,$59,$53,$00
  DEFB $43,$41,$50,$54,$55,$52,$45,$20
  DEFB $03,$20,$45,$4E,$45,$4D,$59,$20
  DEFB $20,$03,$57,$41,$52,$42,$41,$53
  DEFB $45,$53,$00

; l_A93B
;
; Used by the routine at sub_A720.
l_A93B:
  CALL sub_A941
  JP l_A732

; sub_A941
;
; Used by the routines at l_A93B and l_AB52.
sub_A941:
  LD (IX+$0A),$02
  LD (IX+$05),$00
  CALL sub_AD57
l_A94C:
  CALL sub_B0CA
  CALL sub_CCBD
  CALL sub_B048
  CALL sub_AD62
  CALL sub_A81D
  LD A,(IX+$01)
  OR A
  RET Z
  CALL WaitKey
  AND $10
  JR Z,l_A94C
  LD (IX+$0A),$01
  LD A,$78
  CALL sub_CCAC
  RET
; This entry point is used by the routine at sub_A720.
l_A971:
  CALL sub_D2F6
  CALL sub_D42D
  LD BC,$1804
  LD (BC),A
  LD B,A
  LD D,E
  LD B,L
  LD C,H
  LD B,L
  LD B,E
  LD D,H
  INC BC
  LD C,A
  LD D,D
  LD B,H
  LD B,L
  LD D,D
  LD D,E
  LD (BC),A
  LD C,L
  LD BC,$1707
  LD D,E
  LD D,H
  LD C,A
  LD D,B
  JR NZ,l_A9D5
  LD C,(HL)
  LD B,H
  INC BC
  JR NZ,l_A9B9
  LD B,H
  LD B,L
  LD B,(HL)
  LD B,L
  LD C,(HL)
  LD B,H
  INC BC
  INC BC
  LD B,C
  LD B,H
  LD D,(HL)
  LD B,C
  LD C,(HL)
  LD B,E
  LD B,L
  JR NZ,$A9AD
  CCF
  CCF
  JR NZ,$A9FB
  LD C,C
  LD C,H
  LD B,L
  LD D,E
  INC BC
  INC BC
  LD D,D
  LD B,L
  LD D,H
  LD D,D
  LD B,L
l_A9B9:
  LD B,C
  LD D,H
  JR NZ,$A9C0
  CCF
  CCF
  JR NZ,l_AA0E
  LD C,C
  LD C,H
  LD B,L
  LD D,E
  INC BC
  INC BC
  LD D,E
  LD B,L
  LD B,C
  LD D,D
  LD B,E
  LD C,B
  JR NZ,$A9F5
  INC BC
  JR NZ,$AA16
  LD B,L
  LD D,E
  LD D,H
l_A9D5:
  LD D,D
  LD C,A
  LD E,C
  INC BC
  INC BC
  LD D,E
  LD B,L
  LD B,C
  LD D,D
  LD B,E
  LD C,B
  JR NZ,$AA08
  INC BC
  JR NZ,l_AA28
  LD B,C
  LD D,B
  LD D,H
  LD D,L
  LD D,D
  LD B,L
  NOP
  CALL sub_A81D
  LD HL,$5897
  LD E,$06
  LD A,$01
  CALL sub_ACD7
  PUSH AF
  CALL sub_AD57
  POP AF
  DEC A
  JR NZ,l_AA0C
  LD (IX+$0B),A
  LD A,$78
  CALL sub_CCAC
  JP l_A732
l_AA0C:
  CP $03
l_AA0E:
  JP NC,l_AACF
  LD (IX+$0B),A
  PUSH AF
  CALL sub_D2F6
  POP AF
  DEC A
  JR NZ,l_AA2F
  CALL sub_D42D
  LD BC,$1705
  LD (BC),A
  LD C,A
  LD B,C
  LD B,H
  LD D,(HL)
  LD B,C
l_AA28:
  LD C,(HL)
  LD B,E
  LD B,L
  JR NZ,l_AA2D
l_AA2D:
  JR l_AA40
l_AA2F:
  CALL sub_D42D
  LD BC,$1705
  LD (BC),A
  LD C,A
  LD D,D
  LD B,L
  LD D,H
  LD D,D
  LD B,L
  LD B,C
  LD D,H
  JR NZ,l_AA40
l_AA40:
  CALL sub_D42D
  INC BC
  CCF
  CCF
  JR NZ,$AA95
  LD C,C
  LD C,H
  LD B,L
  LD D,E
  LD BC,$1709
  LD (BC),A
  LD B,L
  JR NZ,$AAA6
  LD B,L
  LD C,H
  LD B,L
  LD B,E
  LD D,H
  INC BC
  LD B,H
  LD C,C
  LD D,E
  LD D,H
  LD B,C
  LD C,(HL)
  LD B,E
  LD B,L
  LD BC,$180D
  LD (BC),A
  LD B,(HL)
  JR NC,l_AA88
  LD C,L
  LD C,C
  LD C,H
  LD B,L
  LD D,E
  NOP
  LD D,$00
l_AA70:
  PUSH DE
  CALL sub_A81D
  CALL sub_B0CA
  CALL sub_CCBD
  CALL sub_B048
  CALL sub_AD62
  POP DE
  LD A,(IX+$01)
  OR A
  JP Z,l_A812
l_AA88:
  CALL WaitKey
  BIT 4,A
  JR NZ,l_AAB8
  LD C,D
  RRCA
  RRCA
  AND $03
  JR Z,l_AA70
  AND $02
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  SUB $05
  ADD A,C
  CP $33
  JR NC,l_AA70
  LD D,A
  CALL sub_D42D
  LD BC,$170D
  LD (BC),A
  LD B,(HL)
  NOP
  LD A,D
  CALL sub_D3E5
  LD A,$14
  CALL sub_CCAC
  JR l_AA70
l_AAB8:
  LD A,D
  RLCA
  LD (IX+$0E),A
  OR A
  JR NZ,l_AAC4
  LD (IX+$0B),$00
l_AAC4:
  LD A,$78
  CALL sub_CCAC
  CALL sub_AD57
  JP l_A732
l_AACF:
  JP NZ,l_AB4E
  CALL sub_D2F6
  CALL sub_D42D
  LD BC,$1704
  LD (BC),A
  LD C,A
  LD D,E
  LD B,L
  LD B,C
  LD D,D
  LD B,E
  LD C,B
  JR NZ,$AB0B
  INC BC
  JR NZ,l_AB2C
  LD B,L
  LD D,E
  LD D,H
  LD D,D
  LD C,A
  LD E,C
  LD BC,$1808
  LD (BC),A
  LD B,L
  LD D,E
  LD B,L
  LD C,H
  LD B,L
  LD B,E
  LD D,H
  INC BC
  LD D,H
  LD B,C
  LD D,D
  LD B,A
  LD B,L
  LD D,H
  LD BC,$170C
  LD (BC),A
  LD C,L
  LD B,L
  LD C,(HL)
  LD B,L
  LD C,L
  LD E,C
  JR NZ,l_AB2C
  JR NZ,l_AB11
  JR NZ,l_AB30
  LD D,D
l_AB11:
  LD C,A
  LD B,D
  LD C,A
  LD D,H
  LD D,E
  INC BC
  INC BC
  LD B,L
  LD C,(HL)
  LD B,L
  LD C,L
  LD E,C
  JR NZ,$AB3F
  JR NZ,l_AB24
  LD B,(HL)
  LD B,C
  LD B,E
l_AB24:
  LD D,H
  LD C,A
  LD D,D
  LD E,C
  LD D,E
  INC BC
  INC BC
  LD B,L
l_AB2C:
  LD C,(HL)
  LD B,L
  LD C,L
  LD E,C
l_AB30:
  JR NZ,l_AB52
  JR NZ,l_AB37
  LD D,A
  LD B,C
  LD D,D
l_AB37:
  LD B,D
  LD B,C
  LD D,E
  LD B,L
  LD D,E
  NOP
  CALL sub_A81D
  LD HL,$5937
  LD A,$01
  LD E,$04
  CALL sub_ACD7
  ADD A,$02
  JR l_ABC8
l_AB4E:
  CALL sub_D2F6

; data_AB51
data_AB51:
  DEFB $CD

; l_AB52
;
; Used by the routine at sub_A941.
l_AB52:
  DEC L
  CALL NC,$0401
  RLA
  LD (BC),A
  LD C,A
  LD D,E
  LD B,L
  LD B,C
  LD D,D
  LD B,E
  LD C,B
  JR NZ,l_AB87
  INC BC
  JR NZ,l_ABA7
  LD B,C
  LD D,B
  LD D,H
  LD D,L
  LD D,D
  LD B,L
  LD BC,$1808
  LD (BC),A
  LD B,L
  LD D,E
  LD B,L
  LD C,H
  LD B,L
  LD B,E
  LD D,H
  INC BC
  LD D,H
  LD B,C
  LD D,D
  LD B,A
  LD B,L
  LD D,H
  LD BC,$170C
  LD (BC),A
  LD C,L
  LD C,(HL)
  LD B,L
  LD D,L
  LD D,H
  LD D,D
  LD B,C
l_AB87:
  LD C,H
  JR NZ,l_AB8D
  LD B,(HL)
  LD B,C
  LD B,E
l_AB8D:
  LD D,H
  LD C,A
  LD D,D
  LD E,C
  LD D,E
  INC BC
  INC BC
  LD B,L
  LD C,(HL)
  LD B,L
  LD C,L
  LD E,C
  JR NZ,$ABBB
  JR NZ,l_ABA0
  LD B,(HL)
  LD B,C
  LD B,E
l_ABA0:
  LD D,H
  LD C,A
  LD D,D
  LD E,C
  LD D,E
  INC BC
  INC BC
l_ABA7:
  LD B,L
  LD C,(HL)
  LD B,L
  LD C,L
  LD E,C
  JR NZ,$ABCE
  JR NZ,l_ABB3
  LD D,A
  LD B,C
  LD D,D
l_ABB3:
  LD B,D
  LD B,C
  LD D,E
  LD B,L
  LD D,E
  NOP
  CALL sub_A81D
  LD HL,$5937
  LD A,$01
  LD E,$04
  CALL sub_ACD7
  ADD A,$05
; This entry point is used by the routine at sub_A941.
l_ABC8:
  LD (IX+$0B),A
  CP $04
  JR C,l_ABD9
  CP $06
  JR NC,l_ABD9
  BIT 6,(IX+$07)
  JR Z,l_ABF1
l_ABD9:
  LD L,(IX+$02)
  LD H,(IX+$03)
  PUSH AF
  XOR A
  LD ($FD51),A
  POP AF
  LD (IX+$0E),$FF
  CALL sub_B34D
  LD (IX+$0E),D
  JR NZ,l_ABF5
l_ABF1:
  LD (IX+$0B),$00
l_ABF5:
  LD A,$78
  CALL sub_CCAC
  CALL sub_AD57
  JP l_A732
; This entry point is used by the routine at sub_A720.
l_AC00:
  CALL sub_D2F6
  CALL sub_D42D
  LD BC,$1704
  LD (BC),A
  LD C,L
  LD C,(HL)
  LD D,L
  LD B,E
  LD C,H
  LD B,L
  LD B,C
  LD D,D
  JR NZ,$AC17
  JR NZ,$AC36
  JR NZ,$AC38
  LD B,D
  LD C,A
  LD C,L
  LD B,D
  INC BC
  INC BC
  LD B,(HL)
  LD C,C
  LD D,D
  LD B,L
  JR NZ,l_AC44
  JR NZ,l_AC46
  INC BC
  JR NZ,l_AC79
  LD C,B
  LD B,C
  LD D,E
  LD B,L
  LD D,D
  LD D,E
  INC BC
  INC BC
  LD B,(HL)
  LD C,C
  LD D,D
  LD B,L
  JR NZ,l_AC57
  JR NZ,l_AC59
  INC BC
  LD C,L
  LD C,C
  LD D,E
  LD D,E
  LD C,C
  LD C,H
  LD B,L
  LD D,E
  INC BC
  INC BC
l_AC44:
  LD B,(HL)
  LD C,C
l_AC46:
  LD D,D
  LD B,L
  JR NZ,l_AC6A
  JR NZ,l_AC6C
  INC BC
  JR NZ,$AC6F
  LD B,E
  LD B,C
  LD C,(HL)
  LD C,(HL)
  LD C,A
  LD C,(HL)
  INC BC
  INC BC
l_AC57:
  LD C,L
  LD C,A
l_AC59:
  LD D,(HL)
  LD B,L
  JR NZ,$AC7D
  JR NZ,l_AC7F
  INC BC
  JR NZ,$AC82
  JR NZ,$ACB6
  LD C,A
  LD B,D
  LD C,A
  LD D,H
  INC BC
  INC BC
l_AC6A:
  LD D,E
  LD D,H
l_AC6C:
  LD C,A
  LD D,B
  JR NZ,$AC90
  JR NZ,$AC92
  INC BC
  JR NZ,$AC95
  LD B,E
  LD C,A
  LD C,L
  LD B,D
l_AC79:
  LD B,C
  LD D,H
  NOP
  CALL sub_A81D
l_AC7F:
  LD A,$06
l_AC81:
  LD HL,$5837
  LD E,$07
  CALL sub_ACD7
  CP $06
  JP Z,l_A732
  PUSH AF
  CP $05
  JR NZ,l_AC99
  CALL sub_A941
  POP AF
  JR l_AC81
l_AC99:
  LD C,A
  LD B,A
  INC B
  LD A,(IX+$07)
l_AC9F:
  RLCA
  DJNZ l_AC9F
  JR NC,l_ACCE
  POP AF
  CP $01
  JR NZ,l_ACB3
  PUSH IX
  POP IY
  CALL sub_B99F
  JP l_A812
l_ACB3:
  PUSH AF
  LD IY,data_D6A8+$012B
  LD A,(IY+$01)
  OR A
  JR NZ,l_ACCE
  LD A,$05
  SUB C
  CALL sub_B6D6
  CALL sub_CCBD
  CALL sub_AD62
  POP AF
  JP l_AC81
l_ACCE:
  LD A,$FA
  CALL sub_CCAC
  POP AF
  JP l_AC81

; sub_ACD7
;
; Used by the routines at sub_A720, sub_A941 and l_AB52.
sub_ACD7:
  PUSH AF
  CALL sub_AD57
  POP AF
  LD D,A
  LD C,$4E
  CALL sub_AD3C
l_ACE2:
  LD A,(IX+$01)
  OR A
  JR NZ,l_ACEC
  POP HL
  JP l_A812
l_ACEC:
  PUSH HL
  CALL WaitKey
  POP HL
  LD C,D
  LD A,(Input)
  BIT 4,A
  JR NZ,l_AD2F
  RRCA
  AND $06
  JR Z,l_AD1A
  AND $02
  DEC C
  ADD A,C
  JR Z,l_AD1A
  CP E
  JR NC,l_AD1A
  PUSH AF
  LD A,D
  LD C,$4D
  CALL sub_AD3C
  POP AF
  LD D,A
  LD C,$4E
  CALL sub_AD3C
  LD A,$14
  CALL sub_CCAC
l_AD1A:
  PUSH DE
  PUSH HL
  CALL sub_B0CA
  CALL sub_CCBD
  CALL sub_B048
  CALL sub_AD62
  CALL sub_A81D
  POP HL
  POP DE
  JR l_ACE2
l_AD2F:
  LD A,D
  LD C,$4F
  CALL sub_AD3C
  LD A,$64
  CALL sub_CCAC
  LD A,D
  RET

; sub_AD3C
;
; Used by the routine at sub_ACD7.
sub_AD3C:
  LD B,A
  PUSH DE
  PUSH HL
  LD DE,$0060
l_AD42:
  ADD HL,DE
  DJNZ l_AD42
  LD B,$08
  CALL sub_CBDB
  LD A,$18
  CALL sub_D351
  LD B,$08
  CALL sub_CBDB
  POP HL
  POP DE
  RET

; sub_AD57
;
; Used by the routines at sub_A941, l_AB52, sub_ACD7 and sub_AE6B.
sub_AD57:
  PUSH BC
  PUSH HL
l_AD59:
  CALL WaitKey
  OR A
  JR NZ,l_AD59
  POP HL
  POP BC
  RET

; sub_AD62
;
; Used by the routines at l_A69A, sub_A941, l_AB52 and sub_ACD7.
sub_AD62:
  CALL sub_D358
  LD HL,$FD35
  LD A,(HL)
  ADD A,$05
  LD (HL),A
  CP $3C
  JR NZ,l_AD85
  LD (HL),$00
  INC HL
  INC (HL)
  LD A,(HL)
  CP $18
  JR NZ,l_AD85
  LD (HL),$00
  LD HL,($FD37)
  INC HL
  LD ($FD37),HL
  CALL sub_AE38
l_AD85:
  CALL sub_D42D

; data_AD88
data_AD88:
  DEFB $01,$00,$1B,$04,$00,$02,$57,$00

; l_AD90
l_AD90:
  LD HL,($FD37)
  CALL sub_D3F3
  CALL sub_D470
  LD A,($FD36)
  CALL sub_D3EC
  LD A,$2E
  CALL sub_D427
  LD A,($FD35)
  CALL sub_D3EC
  CALL sub_AE6B
  PUSH IY
  LD IY,$FD70
  LD B,$1C
  LD C,$00
l_ADB7:
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD A,(IY+$02)
  CALL sub_CCA6
  BIT 6,(HL)
  JR NZ,l_ADCD
  LD (IY+$04),$00
  JR l_AE05
l_ADCD:
  INC (IY+$04)
  LD A,(IY+$04)
  CP $90
  JR C,l_AE05
  LD (IY+$04),$00
  PUSH BC
  PUSH IY
  CALL sub_CDD8
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD E,A
  POP IY
  LD A,B
  OR A
  JR Z,l_AE04
  POP BC
  INC C
  PUSH BC
  LD A,$1C
  SUB B
  CP $04
  JR NC,l_ADFE
  LD B,E
  CALL sub_BB86
  JR l_AE04
l_ADFE:
  SUB $04
  LD B,E
  CALL sub_BB61
l_AE04:
  POP BC
l_AE05:
  INC IY
  INC IY
  INC IY
  INC IY
  INC IY
  DJNZ l_ADB7
  POP IY
  LD A,C
  OR A
  JR Z,l_AE1D
  CALL sub_BB09
  CALL sub_D293
l_AE1D:
  LD A,($FD34)
  CP $0A
  JR C,l_AE1D
  XOR A
  LD ($FD34),A
  RET

; data_AE29
data_AE29:
  DEFB $3E,$EF,$DB,$FE,$E6,$18,$C0,$21
  DEFB $00,$A6,$E5,$F3,$C3,$B0,$04

; sub_AE38
;
; Used by the routine at sub_AD62.
sub_AE38:
  LD HL,$FD22
  LD DE,$FD3A
  CALL sub_AE4E
  LD HL,$FD4A
  LD DE,$FD42
  CALL sub_AE4E
  CALL sub_D293
  RET

; sub_AE4E
;
; Used by the routine at sub_AE38.
sub_AE4E:
  LD A,(DE)
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL sub_AE62
  LD B,$06
l_AE58:
  INC HL
  INC DE
  LD A,(DE)
  ADD A,A
  CALL sub_AE62
  DJNZ l_AE58
  RET

; sub_AE62
;
; Used by the routine at sub_AE4E.
sub_AE62:
  ADD A,(HL)
  CP $64
  JR C,l_AE69
  LD A,$63
l_AE69:
  LD (HL),A
  RET

; sub_AE6B
;
; Used by the routine at l_AD90.
sub_AE6B:
  LD A,($FD42)
  OR A
  JR Z,l_AEB1
  LD A,($FD3A)
  OR A
  RET NZ
  CALL sub_AF00
  CALL sub_D42D
  LD BC,$0016
  LD (BC),A
  LD B,L
  LD E,C
  LD C,A
  LD D,L
  JR NZ,l_AECE
  LD B,C
  LD D,(HL)
  LD B,L
  JR NZ,l_AED9
  LD C,A
  JR NZ,l_AED0
  LD B,C
  LD D,E
  LD B,L
  LD D,E
  JR NZ,$AEE0
  LD B,L
  LD B,(HL)
  LD D,H
  INC BC
  LD B,D
  LD B,L
  LD D,H
  LD D,H
  LD B,L
  LD D,D
  JR NZ,l_AEEC
  LD D,L
  LD B,E
  LD C,E
  JR NZ,$AEF3
  LD B,L
  LD E,B
  LD D,H
  JR NZ,$AEFE
  LD C,C
  LD C,L
  LD B,L
  LD HL,$1800
  ADD HL,SP
l_AEB1:
  CALL sub_AF00
  CALL sub_D42D
  LD BC,$0016
  LD (BC),A
  LD B,L
  JR NZ,$AF07
  LD C,(HL)
  LD D,E
  LD C,C
  LD B,A
  LD C,(HL)
  LD C,C
  LD B,C
  LD C,(HL)
  LD D,E
  JR NZ,l_AF0D
  LD B,L
  LD D,E
  LD D,H
  LD D,D
  LD C,A
l_AECE:
  LD E,C
  LD B,L
l_AED0:
  LD B,H
  JR NZ,$AED6
  JR NZ,$AEF5
  JR NZ,l_AEF7
  LD E,C
  LD C,A
l_AED9:
  LD D,L
  JR NZ,$AF24
  LD B,C
  LD D,(HL)
  LD B,L
  JR NZ,l_AF38
  LD C,A
  LD C,(HL)
  JR NZ,l_AF06
  JR NZ,$AF07
  JR NZ,l_AF09
  NOP
  LD A,$FA
l_AEEC:
  CALL sub_CCAC
  LD B,$64
l_AEF1:
  HALT
  DJNZ l_AEF1
  CALL sub_AD57
l_AEF7:
  CALL WaitKey
  OR A
  JR Z,l_AEF7
  JP Start

; sub_AF00
;
; Used by the routine at sub_AE6B.
sub_AF00:
  XOR A
  LD ($FD39),A

; data_AF04
data_AF04:
  DEFB $CD,$F6

; l_AF06
;
; Used by the routine at sub_AE6B.
l_AF06:
  JP NC,$E5CD
; This entry point is used by the routine at sub_AE6B.
l_AF09:
  POP DE
  LD HL,StartInterrupt
; This entry point is used by the routine at sub_AE6B.
l_AF0D:
  LD ($FDFE),HL
  RET

; the ship's move from Input: X by right / left, Y by down / up, each refused
; by CheckShipMove
;
; Used by the routines at l_A69A and sub_B471.
MoveShip:
  CALL sub_B01D
  LD A,(Input)
  AND $0C
  JR Z,l_AF25
  LD A,($FD30)
  OR A
  JR Z,l_AF25
  DEC A
  LD ($FD30),A
l_AF25:
  LD A,(Input)
  AND $03
  JR Z,l_AF77
  CP $03
  JR Z,l_AF77
  LD HL,(ShipX)
  RRCA
  JR C,l_AF42
  LD A,H
  OR A
; This entry point is used by the routine at sub_AE6B.
l_AF38:
  JR NZ,l_AF3F
  LD A,L
  CP $0E
  JR Z,l_AF77
l_AF3F:
  DEC HL
  JR l_AF4C
l_AF42:
  LD A,H
  OR A
  JR Z,l_AF4B
  LD A,L
  CP $F5
  JR Z,l_AF77
l_AF4B:
  INC HL
l_AF4C:
  LD A,(ShipY)
  CALL CheckShipMove
  JR C,l_AF57
  LD (ShipX),HL
l_AF57:
  LD HL,(ShipX)
  LD DE,(ViewX)
  XOR A
  SBC HL,DE
  LD A,L
  CP $0D
  JR NZ,l_AF67
  DEC DE
l_AF67:
  CP $16
  JR NZ,l_AF6C
  INC DE
l_AF6C:
  LD (ViewX),DE
  LD HL,data_D6A8+$0658
  ADD HL,DE
  LD (MapView),HL
l_AF77:
  LD A,(ShipY)
  LD C,A
  LD A,(Input)
  RRCA
  RRCA
  AND $03
  JR Z,l_AFA2
  CP $03
  JR Z,l_AFA2
  RRCA
  JR NC,l_AF8C
  INC C
l_AF8C:
  RRCA
  JR NC,l_AF90
  DEC C
l_AF90:
  LD A,C
  AND $0F
  JR Z,l_AFA2
  LD HL,(ShipX)
  LD B,A
  CALL CheckShipMove
  JR C,l_AFA2
  LD A,B
  LD (ShipY),A
l_AFA2:
  LD A,($FD30)
  OR A
  JR Z,l_AFAE
  DEC A
  LD ($FD30),A
  JR l_AFB5
l_AFAE:
  LD A,(Input)
  AND $10
  JR Z,l_AFC3
l_AFB5:
  LD A,($FD10)
  CP $30
  JR NC,l_AFDB
  ADD A,$02
  LD ($FD10),A
  JR l_AFDB
l_AFC3:
  LD A,($FD10)
  DEC A
  JP M,l_AFDB
  LD B,A
  LD A,(ShipY)
  LD HL,(ShipX)
  CALL CheckShipMove
  LD A,B
  CP C
  JR C,l_AFDB
  LD ($FD10),A
l_AFDB:
  CALL sub_AFE6
  LD HL,$FD1E
  INC (HL)
  CALL sub_B024
  RET

; sub_AFE6
;
; Used by the routine at MoveShip.
sub_AFE6:
  LD HL,(ShipX)
  LD A,($FD1B)
  LD C,A
  LD A,L
  RR H
  RRA
  SRL A
  SRL A
  SUB C
  CP $02
  JR C,l_AFFF
  CP $0E
  JR NC,l_B005
  RET
l_AFFF:
  LD A,C
  SUB $08
  RET M
  JR l_B00B
l_B005:
  LD A,C
  ADD A,$08
  CP $38
  RET Z
l_B00B:
  LD ($FD1B),A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  LD ($FD1C),HL
  LD A,$01
  LD ($FD52),A
  RET

; sub_B01D
;
; Used by the routine at MoveShip.
sub_B01D:
  CALL sub_CCA0
  RES 7,(HL)
  JR sub_B036

; sub_B024
;
; Used by the routines at MoveShip and sub_BC6F.
sub_B024:
  CALL sub_CCA0
  SET 7,(HL)
; This entry point is used by the routine at sub_B048.
l_B029:
  LD A,($FD52)
  OR A
  JR Z,sub_B036
  CALL sub_D5F8
  XOR A
  LD ($FD52),A

; sub_B036
;
; Used by the routines at sub_B01D, sub_B024 and sub_B048.
sub_B036:
  LD A,($FD1E)
  AND $01
  RET Z
  LD HL,(ShipX)
  LD A,(ShipY)
  LD C,A
  LD B,$00
  JP sub_D65A

; sub_B048
;
; Used by the routines at sub_A941 and sub_ACD7.
sub_B048:
  CALL sub_B036
  LD HL,$FD1E
  INC (HL)
  JP l_B029

; carry: the ship may not stand at HL (X), A (Y)
;
; Used by the routine at MoveShip.
CheckShipMove:
  PUSH HL
  CALL sub_CCA6
  EX DE,HL
  LD C,$00
  CALL sub_B096
  INC DE
  CALL sub_B096
  DEC D
  DEC D
  CALL sub_B096
  DEC DE
  CALL sub_B096
  DEC DE
  CALL sub_B099
  INC D
  INC D
  CALL sub_B099
  INC D
  INC D
  LD A,D
  CP $FD
  JR NC,l_B084
  CALL sub_B099
  INC DE
  CALL sub_B099
  INC DE
  CALL sub_B099
l_B084:
  LD A,($FD10)
  CP C
  POP HL
  RET

; sub_B08A
;
; Used by the routines at sub_B096 and sub_B5D6.
sub_B08A:
  LD A,(DE)
  AND $1F
  LD HL,data_D6A8+$0114
  CALL sub_D351
  LD A,(HL)
  JR l_B0AB

; sub_B096
;
; Used by the routine at CheckShipMove.
sub_B096:
  CALL sub_B08A

; sub_B099
;
; Used by the routine at CheckShipMove.
sub_B099:
  LD H,D
  LD L,E
  BIT 6,(HL)
  RET Z
  PUSH BC
  CALL sub_CDD8
  JR NZ,l_B0B0
  POP BC
  LD A,(IY+$09)
  ADD A,(IY+$0D)

; l_B0AB
;
; Used by the routine at sub_B08A.
l_B0AB:
  CP C
  JR C,l_B0AF
  LD C,A
l_B0AF:
  RET
; This entry point is used by the routine at sub_B099.
l_B0B0:
  CALL sub_CDF5
  POP BC
  RET NZ
  LD A,(IY+$02)
  LD HL,data_B0C1
  CALL sub_D351
  LD A,(HL)
  JR l_B0AB

; data_B0C1
data_B0C1:
  DEFB $0F,$16,$15,$15,$16,$16,$16,$19
  DEFB $19

; sub_B0CA
;
; Used by the routines at l_A69A, sub_A941 and sub_ACD7.
sub_B0CA:
  CALL sub_B7F4
  LD B,$30
  LD IY,data_D6A8+$0358
l_B0D3:
  PUSH BC
  LD A,(IY+$01)
  OR A
  CALL NZ,sub_B0FA
  LD DE,$0010
  ADD IY,DE
  POP BC
  DJNZ l_B0D3
  LD IY,data_D6A8+$012B
  LD B,$05
l_B0E9:
  PUSH BC
  LD A,(IY+$01)
  OR A
  CALL NZ,sub_B70D
  LD DE,$0009
  ADD IY,DE
  POP BC
  DJNZ l_B0E9
  RET

; sub_B0FA
;
; Used by the routine at sub_B0CA.
sub_B0FA:
  LD A,(IY+$0C)
  OR A
  JR Z,l_B116
  JP P,l_B154
  INC (IY+$0C)
  LD L,(IY+$00)
  LD H,(IY+$01)
  AND $01
  JR NZ,l_B113
  RES 6,(HL)
  RET
l_B113:
  SET 6,(HL)
  RET
l_B116:
  LD L,(IY+$00)
  LD H,(IY+$01)
  RES 6,(HL)
  LD A,(HL)
  INC HL
  OR (HL)
  DEC H
  DEC H
  OR (HL)
  DEC HL
  OR (HL)
  INC H
  INC H
  AND $3F
  JR NZ,l_B136
  CALL sub_D358
  AND $01
  ADD A,$06
  CALL sub_BD91
l_B136:
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  CALL sub_D65A
  LD (IY+$01),$00
  CALL sub_BB40
  CALL sub_D293
  RET

; l_B154
;
; Used by the routine at sub_B0FA.
l_B154:
  LD A,(IY+$0A)
  CP $01
  RET Z
  RLCA
  AND $01
  LD ($FD51),A
  DEC (IY+$0F)
  RET NZ
  LD L,(IY+$00)
  LD H,(IY+$01)
  RES 6,(HL)
  PUSH HL
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  CALL sub_D65A
  POP HL
  CALL sub_B513
  LD A,(IY+$0A)
  CP $02
  JP Z,l_B450
  PUSH BC
  CALL sub_B626
  POP BC
  LD A,E
  OR A
  JR Z,l_B1E9
  AND (IY+$08)
  JR Z,l_B1D7
  AND C
  LD (IY+$05),A
  PUSH IX
  PUSH IY
  PUSH IY
  POP IX
  CALL sub_B6B8
  JR NZ,l_B1CD
  CALL sub_D358
  AND $38
  AND (IX+$07)
  JR Z,l_B1CD
  LD C,$06
l_B1B7:
  DEC C
  RLCA
  JR NC,l_B1B7
  LD A,C
  CALL sub_B6D6
  POP IY
  POP IX
  LD (IY+$05),$00
  LD (IY+$06),$01
  JR l_B20D
l_B1CD:
  POP IY
  POP IX
  LD (IY+$06),$01
  JR l_B20D
l_B1D7:
  LD C,E
  LD B,C
  CALL sub_B505
  CALL NZ,sub_B33E
  LD (IY+$05),C
  LD (IY+$06),$02
  JP l_B20D
l_B1E9:
  DEC (IY+$06)
  JP M,l_B1F5
  LD A,(IY+$05)
  AND C
  JR NZ,l_B20D
l_B1F5:
  CALL sub_D358
  AND $03
  ADD A,$03
  LD (IY+$06),A
  CALL sub_B505
  CALL NC,sub_B222
  LD A,(IY+$01)
  OR A
  RET Z
  LD (IY+$05),C
; This entry point is used by the routine at sub_B41D.
l_B20D:
  LD A,(IY+$05)
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD B,(IY+$04)
  CALL sub_B471
  CALL sub_B5F3
  JP sub_CC7C

; sub_B222
;
; Used by the routine at l_B154.
sub_B222:
  LD B,C
  LD A,(IY+$0B)
  OR A
  JR NZ,l_B22B
  LD C,A
  RET
l_B22B:
  CP $03
  JP C,l_B326
  JR NZ,l_B289
  LD A,(IY+$0E)
  OR A
  JP M,l_B258
  CALL sub_B3F9
  INC HL
  LD A,(HL)
  OR A
  JR Z,l_B258
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD E,(IY+$02)
  LD D,(IY+$03)
  CALL sub_B3CA
  LD A,H
  OR A
  JR NZ,l_B258
  LD A,L
  CP $32
  JR C,l_B26D
l_B258:
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD (IY+$0E),$FF
  PUSH BC
  CALL sub_B41D
  POP BC
  LD (IY+$0E),D
  JP Z,sub_B33E
l_B26D:
  CALL sub_B3F9
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(IY+$04)
  SUB (HL)
  LD B,A
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE
  LD D,A
  JR Z,l_B2DC
  JR l_B2D5
l_B289:
  CALL sub_B3D5
  LD A,(IY+$0E)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  CALL sub_D351
  LD A,(HL)
  AND $E0
  CP E
  JR Z,l_B2BB
  LD A,(IY+$0B)
  PUSH BC
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL sub_B34D
  POP BC
  JR NZ,l_B2B8
  LD C,$00
  BIT 7,(IY+$0A)
  RET Z
  LD (IY+$0B),$03
  RET
l_B2B8:
  LD (IY+$0E),D
l_B2BB:
  DEC HL
  LD A,(IY+$04)
  SUB (HL)
  LD B,A
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE
  LD D,A
  JR Z,l_B2DC
  LD A,B
  SUB $03
  LD B,A
l_B2D5:
  LD A,H
  RRCA
  AND $03
  XOR $02
  LD D,A
l_B2DC:
  LD A,B
  OR A
  JR Z,l_B2E8
  RRCA
  RRCA
  AND $0C
  XOR $08
  OR D
  LD D,A
l_B2E8:
  LD A,D
  OR A
  JR NZ,l_B306
  LD C,A
  LD A,(IY+$0B)
  CP $04
  JR C,l_B2F9
  CP $06
  JP C,sub_B99F
l_B2F9:
  LD A,(IY+$08)
  CP $04
  RET Z
  LD C,$04
  LD (IY+$06),$FF
  RET
l_B306:
  LD A,L
  OR A
  JP P,l_B30E
  NEG
  LD L,A
l_B30E:
  CP $08
  LD B,C
  LD A,D
  JR NC,l_B326
  AND C
  JR Z,sub_B33E
  LD B,A
  AND $03
  JR Z,sub_B33E
  LD A,L
  OR A
  JR Z,sub_B33E
  DEC A
  LD (IY+$06),A
  JR sub_B33E
l_B326:
  AND $03
  LD D,A
  XOR $FC
  LD E,A
  LD A,C
  AND D
  JR Z,sub_B33E
  LD C,D
  CALL sub_D358
  AND D
  RET NZ
  CALL sub_D358
  AND D
  RET NZ
  LD A,B
  AND E
  LD B,A

; sub_B33E
;
; Used by the routines at l_B154 and sub_B222.
sub_B33E:
  LD C,B
l_B33F:
  CALL sub_D358
  AND C
  LD C,A
  CALL sub_B505
  RET Z
  JR NC,l_B33F
  LD C,B
  JR l_B33F

; sub_B34D
;
; Used by the routines at l_AB52, sub_B222 and sub_B7F4.
sub_B34D:
  CP $03
  JP Z,sub_B41D
  PUSH AF
  EX AF,AF'
  POP AF
  CALL sub_B411
  CALL sub_B3D5
l_B35B:
  LD A,(HL)
  AND $E0
  CP E
  CALL Z,sub_B36C
  LD A,L
  ADD A,$05
  LD L,A
  INC C
  DJNZ l_B35B
  LD A,D
  INC A
  RET

; sub_B36C
;
; Used by the routine at sub_B34D.
sub_B36C:
  PUSH IY
  PUSH BC
  PUSH DE
  EX AF,AF'
  LD E,A
  EX AF,AF'
  LD IY,data_D6A8+$0358
  LD A,($FD51)
  OR A
  JR Z,l_B381
  LD IY,data_D6A8+$04D8
l_B381:
  LD B,$18
l_B383:
  LD A,(IY+$01)
  OR A
  JR Z,l_B395
  LD A,(IY+$0B)
  CP E
  JR NZ,l_B395
  LD A,(IY+$0E)
  CP C
  JR Z,l_B3AE
l_B395:
  PUSH DE
  LD DE,$0010
  ADD IY,DE
  POP DE
  DJNZ l_B383
  POP DE
  POP BC
  POP IY
  PUSH HL
  DEC HL
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  CALL sub_B3B3
  POP HL
  RET
l_B3AE:
  POP DE
  POP BC
  POP IY
  RET

; sub_B3B3
;
; Used by the routines at sub_B36C and sub_B41D.
sub_B3B3:
  PUSH HL
  EXX
  POP HL
  CALL sub_B3CA
  LD A,H
  CP B
  JR C,l_B3C3
  JR NZ,l_B3C8
  LD A,L
  CP C
  JR NC,l_B3C8
l_B3C3:
  LD B,H
  LD C,L
  EXX
  LD D,C
  RET
l_B3C8:
  EXX
  RET

; sub_B3CA
;
; Used by the routines at sub_B222, sub_B3B3 and sub_B99F.
sub_B3CA:
  XOR A
  SBC HL,DE
  RET P
  SUB L
  LD L,A
  LD A,$00
  SBC A,H
  LD H,A
  RET

; sub_B3D5
;
; Used by the routines at sub_B222, sub_B34D and sub_B7F4.
sub_B3D5:
  LD HL,$FD87
  LD B,$18
  CP $05
  JR Z,l_B3E2
  CP $08
  JR NZ,l_B3E7
l_B3E2:
  LD HL,$FD73
  LD B,$04
l_B3E7:
  LD E,$20
  PUSH AF
  LD A,($FD51)
  OR A
  JR Z,l_B3F2
  RLC E
l_B3F2:
  POP AF
  CP $06
  RET NZ
  LD E,$00
  RET

; sub_B3F9
;
; Used by the routine at sub_B222.
sub_B3F9:
  LD DE,data_D6A8+$0358
  LD A,($FD51)
  OR A
  JR NZ,l_B405
  LD DE,data_D6A8+$04D8
l_B405:
  LD A,(IY+$0E)
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  RET

; sub_B411
;
; Used by the routines at sub_B34D and sub_B41D.
sub_B411:
  PUSH HL
  EXX
  POP DE
  LD BC,$2000
  EXX
  LD C,$00
  LD D,$FF
  RET

; sub_B41D
;
; Used by the routines at sub_B222 and sub_B34D.
sub_B41D:
  CALL sub_B411
  PUSH IY
  LD IY,data_D6A8+$0358
  LD A,($FD51)
  OR A
  JR NZ,l_B430
  LD IY,data_D6A8+$04D8
l_B430:
  LD B,$18
l_B432:
  LD A,(IY+$01)
  OR A
  JR Z,l_B441
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL sub_B3B3
l_B441:
  PUSH DE
  LD DE,$0010
  ADD IY,DE
  POP DE
  INC C
  DJNZ l_B432
  POP IY
  LD A,D
  INC A
  RET
; This entry point is used by the routine at l_B154.
l_B450:
  PUSH BC
  CALL WaitKey
  POP BC
  LD B,C
  CP (IY+$08)
  JR NZ,l_B45C
  AND C
l_B45C:
  LD C,A
  CALL sub_B505
  JR Z,l_B467
  LD A,(IY+$05)
  AND B
  LD C,A
l_B467:
  LD (IY+$05),C
  LD A,C
  LD (Input),A
  JP l_B20D

; sub_B471
;
; Used by the routine at l_B154.
sub_B471:
  OR A
  RET Z
  CP (IY+$08)
  JR Z,l_B495
  LD C,A
  OR (IY+$08)
  CP $03
  JR NZ,l_B486
  RLC C
  RLC C
  JR l_B48E
l_B486:
  CP $0C
  JR NZ,l_B48E
  RRC C
  RRC C
l_B48E:
  LD (IY+$08),C
  INC (IY+$06)
  RET
l_B495:
  CALL sub_B4B9
  CALL sub_B5D6
  LD (IY+$0D),A
  LD A,(IY+$0A)
  CP $02
  RET NZ
  PUSH BC
  PUSH HL
  PUSH IY
  CALL Z,MoveShip
  POP IY
  POP HL
  POP BC
  LD A,(IY+$09)
  ADD A,(IY+$0D)
  LD ($FD10),A
  RET

; sub_B4B9
;
; Used by the routine at sub_B471.
sub_B4B9:
  RRCA
  JR NC,l_B4C7
  INC HL
  LD A,(IY+$0B)
  DEC A
  JR Z,l_B4F2
  DEC A
  JR Z,l_B4DE
  RET
l_B4C7:
  RRCA
  JR NC,l_B4D5
  DEC HL
  LD A,(IY+$0B)
  DEC A
  JR Z,l_B4DE
  DEC A
  JR Z,l_B4F2
  RET
l_B4D5:
  RRCA
  JR NC,l_B4DA
  INC B
  RET
l_B4DA:
  RRCA
  RET NC
  DEC B
  RET
l_B4DE:
  LD A,(IY+$0A)
  CP $02
  RET Z
  INC (IY+$0E)
  LD A,(IY+$0E)
  CP $64
  RET C
  LD (IY+$0E),$63
  RET
l_B4F2:
  LD A,(IY+$0A)
  CP $02
  RET Z
  DEC (IY+$0E)
  RET NZ
  LD (IY+$0B),$00
  LD (IY+$06),$00
  RET

; sub_B505
;
; Used by the routines at l_B154, sub_B33E, sub_B41D and sub_B7F4.
sub_B505:
  PUSH BC
  LD B,$04
  XOR A
l_B509:
  RR C
  ADC A,$00
  DJNZ l_B509
  POP BC
  CP $01
  RET

; sub_B513
;
; Used by the routine at l_B154.
sub_B513:
  LD C,$00
  LD A,($FD10)
  SUB (IY+$09)
  SUB (IY+$0D)
  AND $80
  OR $40
  LD E,A
  LD A,(IY+$07)
  LD D,$08
  RRCA
  JR C,l_B532
  LD D,$0C
  RRCA
  JR C,l_B532
  LD D,$0F
l_B532:
  PUSH HL
  CALL sub_B557
  POP HL
  JR NZ,l_B53B
  SET 0,C
l_B53B:
  PUSH HL
  CALL sub_B56F
  POP HL
  JR NZ,l_B544
  SET 1,C
l_B544:
  PUSH HL
  CALL sub_B58F
  POP HL
  JR NZ,l_B54D
  SET 2,C
l_B54D:
  PUSH HL
  CALL sub_B5B1
  POP HL
  JR NZ,l_B556
  SET 3,C
l_B556:
  RET

; sub_B557
;
; Used by the routine at sub_B513.
sub_B557:
  INC HL
  INC HL
  DEC H
  DEC H
  CALL sub_B5CD
  RET NZ
  INC H
  INC H
  CALL sub_B5CD
  RET NZ
  INC H
  INC H
  LD A,H
  CP $FD
  JR NC,l_B5C8
  LD A,(HL)
  AND E
  RET

; sub_B56F
;
; Used by the routine at sub_B513.
sub_B56F:
  DEC H
  DEC H
  DEC HL
  CALL sub_B5CD
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  INC H
  INC H
  LD A,(HL)
  AND E
  RET NZ
  INC HL
  CALL sub_B5CD
  RET NZ
  DEC HL
  INC H
  INC H
  LD A,H
  CP $FD
  JR NC,l_B5C8
  LD A,(HL)
  AND E
  RET

; sub_B58F
;
; Used by the routine at sub_B513.
sub_B58F:
  INC H
  INC H
  LD A,H
  CP $FD
  JR NC,l_B5CA
  CALL sub_B5CD
  RET NZ
  INC HL
  CALL sub_B5CD
  RET NZ
  INC H
  INC H
  LD A,H
  CP $FD
  JR NC,l_B5C8
  LD A,(HL)
  AND E
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET

; sub_B5B1
;
; Used by the routine at sub_B513.
sub_B5B1:
  DEC H
  DEC H
  DEC H
  DEC H
  LD A,H
  CP $DD
  JR C,l_B5CA
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  INC HL
  CALL sub_B5CD
  RET NZ
  INC HL
  CALL sub_B5CD
  RET

; l_B5C8
;
; Used by the routines at sub_B557, sub_B56F and sub_B58F.
l_B5C8:
  XOR A
  RET

; l_B5CA
;
; Used by the routines at sub_B58F, sub_B5B1 and sub_B5CD.
l_B5CA:
  OR $01
  RET

; sub_B5CD
;
; Used by the routines at sub_B557, sub_B56F, sub_B58F and sub_B5B1.
sub_B5CD:
  LD A,(HL)
  AND $1F
  CP D
  JR NC,l_B5CA
  LD A,(HL)
  AND E
  RET

; sub_B5D6
;
; Used by the routines at sub_B471 and sub_B724.
sub_B5D6:
  PUSH HL
  PUSH BC
  LD A,B
  CALL sub_CCA6
  EX DE,HL
  LD C,$00
  CALL sub_B08A
  INC DE
  CALL sub_B08A
  DEC D
  DEC D
  CALL sub_B08A
  DEC DE
  CALL sub_B08A
  LD A,C
  POP BC
  POP HL
  RET

; sub_B5F3
;
; Used by the routine at l_B154.
sub_B5F3:
  PUSH BC
  PUSH HL
  LD A,(IY+$0D)
  LD C,$00
  OR A
  JR Z,l_B605
  LD C,$03
  CP $04
  JR C,l_B605
  LD C,$06
l_B605:
  LD A,(IY+$07)
  LD D,$FF
l_B60A:
  INC D
  RRCA
  JR NC,l_B60A
  LD A,C
  ADD A,D
  LD HL,data_B61D
  CALL sub_D351
  LD A,(HL)
  LD (IY+$0F),A
  POP HL
  POP BC
  RET

; data_B61D
data_B61D:
  DEFB $06,$04,$03,$08,$06,$03,$09,$07
  DEFB $04

; sub_B626
;
; Used by the routine at l_B154.
sub_B626:
  LD E,$00
  LD D,$08
l_B62A:
  RLC E
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD B,$08
  LD A,D
  CP (IY+$08)
  JR NZ,l_B666
  LD B,$0A
  BIT 7,(IY+$07)
  JR Z,l_B644
  LD B,$0C
l_B644:
  LD A,D
  AND $03
  JR NZ,l_B657
  LD C,B
  DEC HL
  CALL sub_B66E
  LD B,C
  INC HL
  CALL sub_B66E
  LD B,C
  INC HL
  JR l_B666
l_B657:
  LD C,B
  DEC H
  DEC H
  CALL sub_B66E
  LD B,C
  INC H
  INC H
  CALL sub_B66E
  LD B,C
  INC H
  INC H
l_B666:
  CALL sub_B66E
  RRC D
  JR NC,l_B62A
  RET

; sub_B66E
;
; Used by the routine at sub_B626.
sub_B66E:
  PUSH HL
  PUSH DE
  PUSH HL
  LD HL,l_B6AD+$0001
  LD A,D
l_B675:
  INC HL
  INC HL
  RRCA
  JR NC,l_B675
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
l_B67E:
  ADD HL,DE
  LD A,H
  SUB $DD
  CP $20
  JR NC,l_B6AD
  BIT 6,(HL)
  JR NZ,l_B68E
  DJNZ l_B67E
  JR l_B6AD
l_B68E:
  PUSH IY
  CALL sub_CDD8
  LD A,(IY+$0A)
  LD B,(IY+$0C)
  POP IY
  JR NZ,l_B6AD
  XOR (IY+$0A)
  JP P,l_B6AD
  DEC B
  JP M,l_B6AD
  POP DE
  LD A,E
  OR $01
  LD E,A
  PUSH DE
l_B6AD:
  POP DE
  POP HL
  RET

; data_B6B0
data_B6B0:
  DEFB $01,$00,$FF,$FF,$00,$02,$00,$FE

; sub_B6B8
;
; Used by the routine at l_B154.
sub_B6B8:
  LD IY,data_D6A8+$0134
  BIT 7,(IX+$0A)
  JR Z,l_B6C7
  LD DE,$0012
  ADD IY,DE
l_B6C7:
  LD A,(IY+$01)
  OR A
  RET Z
  LD DE,$0009
  ADD IY,DE
  LD A,(IY+$01)
  OR A
  RET

; sub_B6D6
;
; Used by the routines at l_AB52 and l_B154.
sub_B6D6:
  LD (IY+$07),A
  LD C,$05
  CP $02
  JR NZ,l_B6E1
  LD C,$07
l_B6E1:
  BIT 7,(IX+$07)
  JR Z,l_B6E8
  INC C
l_B6E8:
  LD (IY+$06),C
  LD A,(IX+$08)
  LD (IY+$05),A
  LD (IY+$08),$0A
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD B,(IX+$04)
  CALL sub_B724
  LD A,(IY+$01)
  OR A
  JR Z,l_B70C
  LD A,$01
  LD ($FD53),A
l_B70C:
  RET

; sub_B70D
;
; Used by the routine at sub_B0CA.
sub_B70D:
  LD L,(IY+$00)
  LD H,(IY+$01)
  RES 6,(HL)
  DEC (IY+$06)
  JP Z,l_B7EA
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD B,(IY+$04)

; sub_B724
;
; Used by the routine at sub_B6D6.
sub_B724:
  LD A,(IY+$05)
  RRCA
  JR NC,l_B72E
  INC HL
  INC HL
  JR l_B747
l_B72E:
  RRCA
  JR NC,l_B735
  DEC HL
  DEC HL
  JR l_B747
l_B735:
  RRCA
  JR NC,l_B73C
  INC B
  INC B
  JR l_B741
l_B73C:
  RRCA
  JR NC,l_B747
  DEC B
  DEC B
l_B741:
  LD A,B
  CP $10
  JP NC,l_B7EA
l_B747:
  LD (IY+$02),L
  LD (IY+$03),H
  LD (IY+$04),B
  CALL sub_B5D6
  CP (IY+$08)
  JP NC,l_B7EA
  LD A,B
  CALL sub_CCA6
  LD (IY+$00),L
  LD (IY+$01),H
  PUSH HL
  DEC HL
  DEC H
  DEC H
  LD A,H
  CP $DD
  JR C,l_B77C
  BIT 6,(HL)
  JR NZ,l_B7A7
  INC HL
  BIT 6,(HL)
  JR NZ,l_B7A7
  INC HL
  BIT 6,(HL)
  JR NZ,l_B7A7
  DEC HL
  DEC HL
l_B77C:
  INC H
  INC H
  BIT 6,(HL)
  JR NZ,l_B7A7
  INC HL
  BIT 6,(HL)
  JR NZ,l_B7A7
  INC HL
  BIT 6,(HL)
  JR NZ,l_B7A7
  DEC HL
  DEC HL
  INC H
  INC H
  LD A,H
  CP $FD
  JR NC,l_B7A3
  BIT 6,(HL)
  JR NZ,l_B7A7
  INC HL
  BIT 6,(HL)
  JR NZ,l_B7A7
  INC HL
  BIT 6,(HL)
  JR NZ,l_B7A7
l_B7A3:
  POP HL
  SET 6,(HL)
  RET
l_B7A7:
  PUSH IY
  LD E,(IY+$07)
  LD C,$FC
  CALL sub_CDD8
  JR NZ,l_B7DE
  LD A,(IY+$0C)
  DEC A
  JP M,l_B7DE
  LD A,$3C
  SUB (IY+$09)
  SUB (IY+$0D)
  SRL A
  SRL A
  LD D,A
  LD B,E
l_B7C8:
  ADD A,D
  DJNZ l_B7C8
  LD B,A
  LD C,$FA
  LD A,(IY+$0C)
  SUB B
  JR Z,l_B7D7
  JP P,l_B7DB
l_B7D7:
  LD A,$FC
  LD C,$C8
l_B7DB:
  LD (IY+$0C),A
l_B7DE:
  POP IY
  POP HL
  LD (IY+$01),$00
  LD A,C
  LD ($FD53),A
  RET
; This entry point is used by the routine at sub_B70D.
l_B7EA:
  LD (IY+$01),$00
  LD A,$FC
  LD ($FD53),A
  RET

; sub_B7F4
;
; Used by the routine at sub_B0CA.
sub_B7F4:
  CALL sub_D358
  AND $1F
  CP $18
  RET NC
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  LD DE,data_D6A8+$04D8
  ADD HL,DE
  PUSH HL
  POP IY
  LD A,$01
  LD ($FD51),A
  LD A,(IY+$01)
  OR A
  JP NZ,l_B920
  LD B,$04
  LD HL,$FD73
l_B81B:
  CALL sub_D358
  AND $01
  JR Z,l_B827
  LD A,(HL)
  CP $20
  JR Z,l_B82F
l_B827:
  LD A,$05
  CALL sub_D351
  DJNZ l_B81B
  RET
l_B82F:
  DEC HL
  LD B,(HL)
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  LD A,B
  PUSH HL
  EXX
  POP HL
  LD B,A
  EXX
  CALL sub_CCA6
  PUSH HL
  LD A,(HL)
  INC H
  INC H
  OR (HL)
  DEC HL
  OR (HL)
  INC HL
  INC HL
  OR (HL)
  AND $40
  POP HL
  RET NZ
  CALL sub_D358
  CALL sub_D358
  LD C,A
  LD (IY+$07),A
  AND $07
  CP $01
  JR Z,l_B864
  CP $02
  JR Z,l_B864
  CP $04
  RET NZ
l_B864:
  LD A,C
  RRCA
  RRCA
  RRCA
  AND $0F
  RET Z
  CP $0F
  RET Z
  LD C,A
  LD A,($FD49)
  RRCA
  RRCA
  RRCA
  INC A
  AND $03
  LD B,A
  CALL sub_B505
  CP B
  RET C
  LD HL,$FD4A
  LD DE,$FD29
  LD BC,$0007
  LDIR
  LD C,(IY+$07)
  LD D,$00
  LD B,$08
l_B890:
  RRC C
  JR NC,l_B8B8
  LD A,$08
  SUB B
  PUSH AF
  LD HL,data_CAF0
  CALL sub_D351
  LD E,(HL)
  POP AF
  LD HL,data_CAF0+$0008
  CALL sub_D351
  LD A,(HL)
  LD HL,$FD29
  CALL sub_D351
  LD A,(HL)
  SUB E
  JP P,l_B8B7
  NEG
  ADD A,D
  LD D,A
  XOR A
l_B8B7:
  LD (HL),A
l_B8B8:
  DJNZ l_B890
  LD HL,$FD29
  LD A,(HL)
  SRL A
  CP $0B
  JR NC,l_B8C6
  LD A,$0B
l_B8C6:
  CP D
  RET C
  LD A,(HL)
  SUB D
  RET M
  LD (HL),A
  LD DE,$FD4A
  LD BC,$0007
  LDIR
  LD (IY+$0A),$80
  EXX
  CALL sub_CC7C
  EXX
  LD (IY+$05),$04
  LD (IY+$08),$04
  LD (IY+$06),$03
  LD (IY+$0D),$00
  LD (IY+$0B),$00
  LD (IY+$0F),$01
  LD (IY+$0C),$64
  LD (IY+$0E),$FF
  LD C,(IY+$07)
  LD B,$08
  LD D,$00
l_B904:
  RRC C
  JR NC,l_B914
  LD A,$08
  SUB B
  LD HL,data_D6A8+$010C
  CALL sub_D351
  LD A,(HL)
  ADD A,D
  LD D,A
l_B914:
  DJNZ l_B904
  LD (IY+$09),D
  CALL sub_BB40
  CALL sub_D293
  RET
l_B920:
  LD A,(IY+$0B)
  OR A
  JR Z,l_B95D
  LD B,A
  CALL sub_D358
  AND $1F
  RET NZ
  LD A,B
  CP $04
  JR C,l_B95D
  LD A,(IY+$0B)
  CALL sub_B3D5
  LD A,(IY+$0E)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  CALL sub_D351
  LD A,(HL)
  AND $E0
  CP E
  JR Z,l_B95D
  DEC HL
  LD A,(IY+$04)
  SUB (HL)
  JR NZ,l_B95D
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE
  RET Z
l_B95D:
  LD (IY+$0B),$03
  BIT 6,(IY+$07)
  JR Z,l_B976
  CALL sub_D358
  LD B,A
  RLCA
  OR B
  AND $01
  ADD A,$04
  LD (IY+$0B),A
  JR l_B989
l_B976:
  LD C,$00
  CALL sub_D358
  RRCA
  JR C,l_B983
  INC C
  RRCA
  JR C,l_B983
  INC C
l_B983:
  LD A,C
  ADD A,$06
  LD (IY+$0B),A
l_B989:
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD (IY+$0E),$FF
  CALL sub_B34D
  LD (IY+$0E),D
  RET NZ
  LD (IY+$0B),$03
  RET

; sub_B99F
;
; Used by the routines at l_AB52 and sub_B222.
sub_B99F:
  LD HL,$FD73
  LD C,$00
  LD DE,$070A
l_B9A7:
  PUSH HL
  BIT 7,(HL)
  JR NZ,l_B9DD
  DEC HL
  LD A,C
  CP $04
  LD A,(IY+$04)
  JR NC,l_B9B7
  ADD A,$04
l_B9B7:
  INC A
  SUB (HL)
  JP P,l_B9BE
  NEG
l_B9BE:
  LD B,A
  CP D
  JR NC,l_B9DD
  PUSH DE
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL sub_B3CA
  POP DE
  LD A,H
  OR A
  JR NZ,l_B9DD
  LD A,L
  CP D
  JR NC,l_B9DD
  ADD A,B
  CP E
  JR C,l_B9F2
l_B9DD:
  POP HL
  LD A,$05
  CALL sub_D351
  INC C
  LD A,C
  CP $04
  JR C,l_B9A7
  LD DE,$0507
  CP $1C
  JR C,l_B9A7
  JR l_BA02
l_B9F2:
  POP HL
  LD A,C
  CP $04
  JR NC,l_B9FD
  CALL sub_BBF9
  JR l_BA02
l_B9FD:
  SUB $04
  CALL sub_BBD8
l_BA02:
  LD L,(IY+$00)
  LD H,(IY+$01)
  PUSH IY
  LD DE,data_D6A8+$2154
  ADD HL,DE
  LD BC,$0909
l_BA11:
  PUSH BC
  PUSH HL
  LD A,H
  CP $DF
  JR C,l_BA61
  CP $FD
  JR NC,l_BA61
  LD A,C
  CP $01
  JR Z,l_BA2D
  CP $02
  JR Z,l_BA30
  CP $08
  JR Z,l_BA30
  CP $09
  JR NZ,l_BA33
l_BA2D:
  INC HL
  DEC B
  DEC B
l_BA30:
  INC HL
  DEC B
  DEC B
l_BA33:
  PUSH BC
  LD A,(HL)
  BIT 6,A
  JR Z,l_BA44
  CALL sub_CDD8
  JR NZ,l_BA44
  LD (IY+$01),$00
  RES 6,(HL)
l_BA44:
  LD A,(HL)
  BIT 5,A
  JR NZ,l_BA5D
  AND $1F
  CP $11
  JR C,l_BA5D
  CP $15
  JR NC,l_BA5D
  CALL sub_D358
  AND $01
  ADD A,$06
  CALL sub_BD91
l_BA5D:
  POP BC
  INC HL
  DJNZ l_BA33
l_BA61:
  POP HL
  INC H
  INC H
  POP BC
  DEC C
  JR NZ,l_BA11
  CALL sub_CCA0
  SET 7,(HL)
  CALL sub_CCBD
  POP IY
  LD (IY+$01),$00
  CALL sub_BA87
  LD A,$01
  LD ($FD52),A
  CALL sub_BB40
  CALL sub_BB09
  JP sub_D293

; sub_BA87
;
; Used by the routine at sub_B99F.
sub_BA87:
  LD DE,data_5B00
  LD HL,$5821
  LD BC,$1414
l_BA90:
  PUSH BC
l_BA91:
  LDI
  INC C
  DJNZ l_BA91
  LD A,$0C
  CALL sub_D351
  POP BC
  DEC C
  JR NZ,l_BA90
  LD BC,$F401
l_BAA2:
  CALL sub_BAEE
  PUSH BC
  LD HL,$5821
  LD BC,$1414
l_BAAC:
  CALL sub_D358
  AND $38
  CP $10
  JR C,l_BAAC
  CP E
  JR Z,l_BAAC
  LD E,A
l_BAB9:
  PUSH BC
l_BABA:
  LD A,(HL)
  AND $38
  JR Z,l_BAC4
  LD A,(HL)
  AND $C7
  OR E
  LD (HL),A
l_BAC4:
  INC HL
  DJNZ l_BABA
  LD A,$0C
  CALL sub_D351
  POP BC
  DEC C
  JR NZ,l_BAB9
  POP BC
  DJNZ l_BAA2
  LD HL,data_5B00
  LD DE,$5821
  LD BC,$1414
l_BADC:
  PUSH BC
l_BADD:
  LDI
  INC C
  DJNZ l_BADD
  LD A,$0C
  ADD A,E
  LD E,A
  JR NC,l_BAE9
  INC D
l_BAE9:
  POP BC
  DEC C
  JR NZ,l_BADC
  RET

; sub_BAEE
;
; Used by the routine at sub_BA87.
sub_BAEE:
  PUSH BC
  LD HL,$0090
l_BAF2:
  PUSH BC
  LD A,(HL)
  AND $10
  OUT ($FE),A
  INC HL
l_BAF9:
  DEC C
  NOP
  NOP
  JR NZ,l_BAF9
  POP BC
  DJNZ l_BAF2
  POP BC
  DEC B
  DEC B
  DEC B
  INC C
  INC C
  INC C
  RET

; sub_BB09
;
; Used by the routines at l_AD90, sub_B99F and sub_BC6F.
sub_BB09:
  LD HL,$FD3A
  LD B,$07
l_BB0E:
  LD (HL),$00
  INC HL
  DJNZ l_BB0E
  INC HL
  LD B,$07
l_BB16:
  LD (HL),$00
  INC HL
  DJNZ l_BB16
  LD DE,$FD73
  LD B,$1C
l_BB20:
  LD A,(DE)
  OR A
  JP M,l_BB39
  LD HL,$FD3A
  BIT 6,A
  JR NZ,l_BB33
  LD HL,$FD42
  BIT 5,A
  JR Z,l_BB39
l_BB33:
  AND $07
  CALL sub_D351
  INC (HL)
l_BB39:
  LD A,E
  ADD A,$05
  LD E,A
  DJNZ l_BB20
  RET

; sub_BB40
;
; Used by the routines at l_A69A, sub_B0FA, sub_B7F4 and sub_B99F.
sub_BB40:
  LD HL,data_D6A8+$0359
  CALL sub_BB50
  LD ($FD41),A
  CALL sub_BB50
  LD ($FD49),A
  RET

; sub_BB50
;
; Used by the routine at sub_BB40.
sub_BB50:
  LD B,$18
  LD C,$00
  LD DE,$0010
l_BB57:
  LD A,(HL)
  OR A
  JR Z,l_BB5C
  INC C
l_BB5C:
  ADD HL,DE
  DJNZ l_BB57
  LD A,C
  RET

; sub_BB61
;
; Used by the routine at l_AD90.
sub_BB61:
  LD HL,$FD87
  CALL sub_BBB9
  DEC H
  DEC H
  DEC H
  DEC H
  INC HL
  INC HL
  CALL sub_BC5D
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  CALL sub_BC5D
  LD A,B
  OR A
  JR Z,l_BB7F
  INC HL
  INC HL
  INC HL
  INC HL
l_BB7F:
  ADD A,$07
  LD C,A
  CALL sub_BC43
  RET

; sub_BB86
;
; Used by the routines at l_AD90 and sub_BC6F.
sub_BB86:
  LD HL,$FD73
  CALL sub_BBB9
  LD A,H
  SUB $08
  LD H,A
  CALL sub_BC5D
  DEC L
  DEC L
  DEC L
  DEC L
  CALL sub_BC5D
  LD A,L
  ADD A,$08
  LD L,A
  CALL sub_BC5D
  LD C,$08
  LD A,B
  OR A
  JP NZ,sub_BC43
  DEC L
  DEC L
  DEC L
  DEC L
  LD C,A
  CALL sub_BC43
  DEC L
  DEC L
  DEC L
  DEC L
  LD C,$07
  JP sub_BC43

; sub_BBB9
;
; Used by the routines at sub_BB61 and sub_BB86.
sub_BBB9:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL sub_D351
  LD A,B
  OR A
  LD A,$40
  JR Z,l_BBC7
  RRCA
l_BBC7:
  LD C,A
  LD A,(HL)
  AND $1F
  OR C
  LD (HL),A
; This entry point is used by the routine at sub_BC1C.
l_BBCD:
  DEC HL
  LD C,(HL)
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  LD A,C
  JP sub_CCA6

; sub_BBD8
;
; Used by the routine at sub_B99F.
sub_BBD8:
  LD HL,$FD87
  CALL sub_BC1C
  PUSH HL
  DEC H
  DEC H
  DEC H
  DEC H
  INC HL
  INC HL
  CALL sub_BC5D
  DEC HL
  DEC HL
  CALL sub_BC5D
  DEC HL
  DEC HL
  CALL sub_BC5D
  POP HL
  LD DE,data_BDA9+$0239
  JP l_BC27

; sub_BBF9
;
; Used by the routine at sub_B99F.
sub_BBF9:
  LD HL,$FD73
  CALL sub_BC1C
  PUSH HL
  LD A,H
  SUB $08
  LD H,A
  CALL sub_BC5D
  DEC L
  DEC L
  DEC L
  DEC L
  CALL sub_BC5D
  LD A,L
  ADD A,$08
  LD L,A
  CALL sub_BC5D
  POP HL
  LD DE,data_BDA9+$0209
  JP l_BC27

; sub_BC1C
;
; Used by the routines at sub_BBD8 and sub_BBF9.
sub_BC1C:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL sub_D351
  LD (HL),$80
  JR l_BBCD
; This entry point is used by the routines at sub_BBD8 and sub_BBF9.
l_BC27:
  LD A,(DE)
  OR A
  JR Z,l_BC35
  CALL sub_D358
  AND $01
  ADD A,$06
  CALL sub_BD91
l_BC35:
  INC DE
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
  OR C
  RET Z
  CALL sub_BD7F
  JR l_BC27

; sub_BC43
;
; Used by the routines at sub_BB61, sub_BB86 and sub_BCF9.
sub_BC43:
  LD DE,$FF02
  LD B,$38
l_BC48:
  LD A,(DE)
  OR A
  JR Z,l_BC52
  INC DE
  INC DE
  INC DE
  DJNZ l_BC48
  RET
l_BC52:
  DEC DE
  SET 6,(HL)
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),C
  EX DE,HL
  RET

; sub_BC5D
;
; Used by the routines at sub_BB61, sub_BB86, sub_BBD8 and sub_BBF9.
sub_BC5D:
  PUSH IY
  PUSH BC
  CALL sub_CDF5
  JR NZ,l_BC6B
  LD (IY+$01),$00
  RES 6,(HL)
l_BC6B:
  POP BC
  POP IY
  RET

; sub_BC6F
;
; Used by the routine at l_A62D.
sub_BC6F:
  LD HL,data_D6A8+$0658
  LD D,H
  LD E,L
  INC DE
  LD BC,$1FFF
  LD (HL),$00
  LDIR
  LD HL,data_D6A8+$0158
  LD D,H
  LD E,L
  INC DE
  LD BC,$00FF
  LD (HL),$00
  LDIR
  LD HL,data_BDA9
  LD D,$00
  CALL sub_BCD6
  LD HL,data_BDA9+$00D0
  LD D,$01
  CALL sub_BCD6
  LD IY,$FD84
  LD IX,$FD70
  LD HL,data_BDA9+$019D
  LD D,$00
  CALL sub_BCF9
  LD HL,data_BDA9+$01C5
  LD D,$01
  CALL sub_BCF9
  XOR A
  LD B,A
  CALL sub_BB86
  LD A,$01
  LD B,A
  CALL sub_BB86
  LD A,$02
  LD B,$01
  CALL sub_BB86
  LD A,$03
  LD B,$01
  CALL sub_BB86
  CALL sub_BB09
  LD A,$01
  LD ($FD52),A
  CALL sub_B024
  RET

; sub_BCD6
;
; Used by the routine at sub_BC6F.
sub_BCD6:
  LD A,(HL)
  OR A
  RET Z
  LD C,A
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD HL,data_D6A8+$0658
  ADD A,A
  ADD A,H
  LD H,A
  ADD HL,DE
  LD A,C
  OR A
  JP M,l_BCF2
  CALL sub_BD91
  JR l_BCF5
l_BCF2:
  CALL sub_BD61
l_BCF5:
  POP DE
  POP HL
  JR sub_BCD6

; sub_BCF9
;
; Used by the routine at sub_BC6F.
sub_BCF9:
  LD A,(HL)
  OR A
  RET M
  LD C,A
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  LD B,A
  INC HL
  PUSH HL
  PUSH DE
  LD HL,data_D6A8+$0658
  ADD A,A
  ADD A,H
  LD H,A
  ADD HL,DE
  LD A,C
  OR A
  JR Z,l_BD3E
  LD (IY+$00),E
  LD (IY+$01),D
  LD (IY+$02),B
  LD (IY+$03),C
  LD (IY+$04),$00
  INC IY
  INC IY
  INC IY
  INC IY
  INC IY
  PUSH BC
  PUSH HL
  LD A,$81
  CALL sub_BD61
  POP HL
  POP BC
  DEC H
  DEC H
  DEC H
  DEC H
  CALL sub_BC43
  POP DE
  POP HL
  JR sub_BCF9
l_BD3E:
  LD (IX+$00),E
  LD (IX+$01),D
  LD (IX+$02),B
  LD (IX+$03),C
  LD (IX+$04),$00
  INC IX
  INC IX
  INC IX
  INC IX
  INC IX
  LD A,$80
  CALL sub_BD61
  POP DE
  POP HL
  JR sub_BCF9

; sub_BD61
;
; Used by the routines at sub_BCD6 and sub_BCF9.
sub_BD61:
  PUSH HL
  LD HL,data_BDA9+$01F3
  AND $7F
  CALL sub_D348
  EX DE,HL
  POP HL
l_BD6C:
  LD A,(DE)
  OR A
  CALL NZ,sub_BD91
  INC DE
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
  OR C
  RET Z
  CALL sub_BD7F
  JR l_BD6C

; sub_BD7F
;
; Used by the routines at sub_BC1C and sub_BD61.
sub_BD7F:
  PUSH DE
  LD E,C
  LD D,$00
  LD A,C
  OR A
  JP P,l_BD8A
  LD D,$FF
l_BD8A:
  ADD HL,DE
  LD A,H
  ADD A,B
  ADD A,B
  LD H,A
  POP DE
  RET

; sub_BD91
;
; Used by the routines at sub_B0FA, sub_B99F, sub_BC1C, sub_BCD6 and sub_BD61.
sub_BD91:
  PUSH DE
  LD E,A
  LD BC,$0202
  PUSH HL
l_BD97:
  PUSH BC
  PUSH HL
l_BD99:
  LD (HL),E
  SET 5,E
  INC HL
  DJNZ l_BD99
  POP HL
  POP BC
  DEC H
  DEC H
  DEC C
  JR NZ,l_BD97
  POP HL
  POP DE
  RET

; data_BDA9
data_BDA9:
  DEFB $86,$0C,$01,$86,$0C,$09,$11,$10
  DEFB $0E,$11,$20,$03,$82,$22,$0A,$05
  DEFB $20,$0C,$04,$2A,$0A,$07,$2A,$0C
  DEFB $06,$2A,$0E,$03,$2C,$0A,$09,$2C
  DEFB $0C,$07,$2C,$0E,$83,$2E,$0A,$03
  DEFB $30,$08,$04,$32,$08,$02,$36,$0C
  DEFB $06,$36,$0E,$03,$38,$0E,$12,$3F
  DEFB $02,$12,$41,$02,$12,$46,$01,$11
  DEFB $46,$0F,$11,$48,$0F,$87,$48,$02
  DEFB $87,$53,$08,$06,$53,$02,$05,$53
  DEFB $04,$83,$55,$02,$02,$55,$06,$04
  DEFB $5B,$06,$07,$5D,$02,$03,$5D,$04
  DEFB $85,$5E,$0F,$88,$68,$09,$88,$6E
  DEFB $09,$0D,$6E,$09,$85,$6A,$04,$85
  DEFB $6C,$0D,$84,$79,$09,$11,$7F,$0C
  DEFB $11,$81,$07,$85,$86,$04,$12,$85
  DEFB $0B,$12,$85,$0D,$87,$97,$06,$82
  DEFB $A5,$02,$83,$A7,$06,$83,$AD,$08
  DEFB $83,$B3,$0A,$12,$BF,$08,$89,$BF
  DEFB $03,$89,$C1,$08,$89,$BF,$0D,$89
  DEFB $C7,$03,$89,$C7,$0D,$89,$CF,$03
  DEFB $89,$C9,$08,$89,$CF,$0D,$12,$D1
  DEFB $08,$89,$D7,$0D,$89,$DF,$0D,$11
  DEFB $E5,$0B,$84,$E9,$09,$12,$E9,$07
  DEFB $82,$EB,$0A,$82,$F3,$0A,$02,$FB
  DEFB $0C,$04,$FB,$0E,$03,$FD,$0E,$00
  DEFB $83,$0E,$02,$83,$0C,$0A,$83,$10
  DEFB $0A,$08,$08,$0E,$09,$0A,$0C,$0A
  DEFB $0A,$0E,$08,$18,$0C,$0B,$18,$0E
  DEFB $12,$21,$03,$11,$2B,$09,$12,$33
  DEFB $0D,$11,$40,$0A,$11,$42,$0C,$11
  DEFB $44,$0E,$12,$49,$0C,$85,$50,$05
  DEFB $85,$50,$09,$85,$58,$05,$85,$58
  DEFB $09,$84,$60,$09,$12,$5E,$01,$12
  DEFB $5E,$03,$11,$58,$01,$11,$52,$03
  DEFB $11,$52,$0D,$11,$56,$0D,$11,$56
  DEFB $0F,$11,$58,$0F,$11,$5A,$0F,$11
  DEFB $5A,$0B,$8A,$64,$05,$11,$7B,$04
  DEFB $03,$7B,$0E,$04,$7D,$0C,$02,$7D
  DEFB $0E,$82,$7F,$0A,$05,$87,$0C,$02
  DEFB $87,$0E,$04,$89,$0E,$12,$8A,$01
  DEFB $11,$91,$0F,$12,$99,$01,$88,$96
  DEFB $05,$88,$99,$09,$88,$99,$0D,$87
  DEFB $A4,$08,$87,$A8,$02,$87,$AC,$08
  DEFB $87,$B0,$02,$09,$B4,$0E,$83,$B6
  DEFB $0A,$83,$BC,$0A,$04,$C0,$0A,$03
  DEFB $C2,$0A,$02,$C2,$0C,$88,$C5,$03
  DEFB $11,$D0,$0A,$11,$D3,$0D,$8A,$DE
  DEFB $01,$8A,$DC,$03,$8A,$DA,$05,$8A
  DEFB $DA,$09,$8A,$DC,$0B,$8A,$DE,$0D
  DEFB $8A,$E0,$0F,$8A,$E0,$05,$86,$F7
  DEFB $01,$86,$F7,$09,$00,$00,$16,$09
  DEFB $04,$27,$06,$06,$35,$03,$01,$3E
  DEFB $0A,$05,$4F,$03,$03,$61,$03,$02
  DEFB $7D,$03,$06,$8C,$0B,$01,$A0,$05
  DEFB $03,$B4,$03,$04,$D9,$03,$05,$E3
  DEFB $09,$06,$F1,$03,$FF,$00,$05,$08
  DEFB $03,$1A,$03,$01,$20,$0D,$02,$28
  DEFB $03,$04,$37,$07,$06,$42,$03,$00
  DEFB $71,$08,$03,$82,$03,$05,$91,$07
  DEFB $01,$A0,$03,$02,$B4,$05,$04,$BE
  DEFB $03,$05,$C8,$0A,$06,$D2,$03,$00
  DEFB $EE,$08,$FF,$B2,$BF,$E2,$BF,$F4
  DEFB $BF,$18,$C0,$3C,$C0,$48,$C0,$54
  DEFB $C0,$60,$C0,$6C,$C0,$78,$C0,$84
  DEFB $C0,$00,$FC,$FC,$10,$00,$FE,$10
  DEFB $02,$05,$0F,$00,$FE,$0F,$00,$FE
  DEFB $0F,$00,$FE,$10,$02,$05,$0F,$00
  DEFB $FE,$10,$00,$FE,$10,$02,$05,$0F
  DEFB $00,$FE,$0F,$00,$FE,$0F,$00,$FE
  DEFB $10,$02,$03,$10,$00,$FE,$10,$00
  DEFB $00,$00,$FE,$00,$0F,$00,$FE,$10
  DEFB $02,$00,$10,$02,$00,$10,$00,$02
  DEFB $0F,$00,$00,$02,$02,$00,$03,$02
  DEFB $00,$04,$02,$00,$05,$FA,$02,$04
  DEFB $02,$00,$05,$02,$00,$02,$02,$00
  DEFB $03,$FA,$02,$03,$02,$00,$02,$02
  DEFB $00,$05,$02,$00,$04,$00,$00,$08
  DEFB $02,$00,$09,$02,$00,$0A,$02,$00
  DEFB $0B,$FA,$02,$0A,$02,$00,$0B,$02
  DEFB $00,$08,$02,$00,$09,$FA,$02,$09
  DEFB $02,$00,$08,$02,$00,$0B,$02,$00
  DEFB $0A,$00,$00,$12,$00,$02,$12,$00
  DEFB $02,$12,$00,$02,$12,$00,$00,$12
  DEFB $02,$00,$12,$02,$00,$12,$02,$00
  DEFB $12,$00,$00,$15,$00,$02,$15,$00
  DEFB $02,$15,$00,$02,$15,$00,$00,$0C
  DEFB $00,$02,$0D,$00,$02,$0D,$00,$02
  DEFB $0E,$00,$00,$0C,$02,$00,$0D,$02
  DEFB $00,$0D,$02,$00,$0E,$00,$00,$11
  DEFB $02,$00,$11,$02,$00,$11,$02,$00
  DEFB $11,$00,$00,$11,$02,$00,$12,$02
  DEFB $00,$11,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00

; sub_C100
;
; Used by the routines at Start and l_C192.
sub_C100:
  CALL sub_D0B9

; l_C103
l_C103:
  CALL sub_C1E3

; l_C106
;
; Used by the routine at l_C192.
l_C106:
  CALL sub_D42D

; data_C109
data_C109:
  DEFB $02,$46,$04,$21,$01,$0B,$08,$30
  DEFB $2E,$2E,$53,$54,$41,$52,$54,$20
  DEFB $47,$41,$4D,$45,$04,$00,$00

; l_C120
l_C120:
  LD C,$01
  CALL sub_C336
  CALL sub_D42D

; data_C128
data_C128:
  DEFB $03,$03,$03,$31,$2E,$2E,$4B,$45
  DEFB $59,$42,$4F,$41,$52,$44,$00

; l_C137
l_C137:
  LD C,$02
  CALL sub_C336
  CALL sub_D42D

; data_C13F
data_C13F:
  DEFB $03,$03,$32,$2E,$2E,$4B,$45,$4D
  DEFB $50,$53,$54,$4F,$4E,$20,$4A,$2F
  DEFB $53,$00

; l_C151
l_C151:
  LD C,$03
  CALL sub_C336
  CALL sub_D42D

; data_C159
data_C159:
  DEFB $03,$03,$33,$2E,$2E,$49,$4E,$54
  DEFB $45,$52,$46,$41,$43,$45,$20,$32
  DEFB $03,$03,$02,$46,$34,$2E,$2E,$52
  DEFB $45,$44,$45,$46,$49,$4E,$45,$20
  DEFB $4B,$45,$59,$53,$03,$03,$35,$2E
  DEFB $2E,$4C,$4F,$41,$44,$20,$53,$41
  DEFB $56,$45,$44,$20,$47,$41,$4D,$45
  DEFB $00

; l_C192
l_C192:
  HALT
  CALL sub_C820
  CALL $028E
  LD A,E
  OR A
  JP P,l_C192
  CALL sub_C4A7
l_C1A1:
  HALT
  CALL sub_C820
  CALL $028E
  LD A,E
  OR A
  JP M,l_C1A1
  LD HL,$0205
  ADD A,L
  LD L,A
  LD A,(HL)
  CP $35
  JR Z,l_C1FD
  CP $30
  JR Z,l_C1D1
  CP $31
  JR Z,l_C1D3
  CP $32
  JR Z,l_C1D7
  CP $33
  JR Z,l_C1DB
  CP $34
  JR NZ,l_C1A1
  CALL sub_C34A
  JP sub_C100
l_C1D1:
  XOR A
  RET
l_C1D3:
  LD A,$01
  JR l_C1DD
l_C1D7:
  LD A,$02
  JR l_C1DD
l_C1DB:
  LD A,$03
l_C1DD:
  LD (KeyTable+$0018),A
  JP l_C106

; sub_C1E3
;
; Used by the routines at l_C103 and l_C1FC.
sub_C1E3:
  CALL sub_D42D

; data_C1E6
data_C1E6:
  DEFB $01,$01,$0A,$02,$47,$04,$32,$4E
  DEFB $45,$54,$48,$45,$52,$01,$05,$0B
  DEFB $45,$41,$52,$54,$48,$00

; l_C1FC
l_C1FC:
  RET
; This entry point is used by the routine at l_C192.
l_C1FD:
  CALL sub_C1E3
  CALL sub_D42D
  LD BC,$0716
  LD (BC),A
  LD B,L
  INC B
  LD HL,$5250
  LD B,L
  LD D,E
  LD D,E
  JR NZ,$C261
  LD C,H
  LD B,C
  LD E,C
  JR NZ,l_C265
  LD C,(HL)
  JR NZ,$C26D
  LD B,C
  LD D,B
  LD B,L
  JR NZ,l_C21E

; l_C21E
;
; Used by the routine at l_C1FC.
l_C21E:
  LD A,$02
  OUT ($FE),A
  LD IX,data_5B00
  LD DE,$0002
  XOR A
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562
  LD IX,data_D6A8+$0283
  LD DE,$24D1
  XOR A
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562
  XOR A
  OUT ($FE),A
  CALL sub_C30F
  LD HL,(data_5B00)
  AND A
  SBC HL,DE
  LD A,H
  OR L
  JR NZ,l_C269
  LD HL,data_D6A8+$0283
  LD DE,data_D6A8+$012B
  LD BC,$002D
  LDIR
  LD DE,$FF01
  LD BC,$00A8
  LDIR
; This entry point is used by the routine at l_C1FC.
l_C265:
  EI
  OR $01
  RET
l_C269:
  CALL sub_D42D
  LD BC,$0216
  LD (BC),A
  LD B,A
  INC B
  LD ($4F4C),HL
  LD B,C
  LD B,H
  LD C,C
  LD C,(HL)
  LD B,A
  JR NZ,l_C2C1
  LD D,D
  LD D,D
  LD C,A
  LD D,D

; data_C280
data_C280:
  DEFB $21,$00

; l_C282
l_C282:
  LD A,$FA
  CALL sub_CCAC
  CALL sub_C325
  JP Start

; sub_C28D
;
; Used by the routine at l_A69A.
sub_C28D:
  LD HL,StartInterrupt
  LD ($FDFE),HL
  CALL sub_D42D
  LD BC,$0016
  LD (BC),A
  LD B,L
  LD D,B
  LD D,D
  LD B,L
  LD D,E
  LD D,E
  JR NZ,$C2F4
  LD B,L
  LD B,E
  LD C,A
  LD D,D
  LD B,H
  JR NZ,$C2EA
  LD C,(HL)
  LD B,H
  JR NZ,$C2FD
  LD C,H
  LD B,C
  LD E,C
  JR NZ,$C2B5
  JR NZ,l_C2D4
  JR NZ,$C2D6
  JR NZ,$C30C
  LD C,B
  LD B,L
  LD C,(HL)
  JR NZ,l_C2FE
  LD C,(HL)
  LD E,C
  JR NZ,$C30C
; This entry point is used by the routine at l_C21E.
l_C2C1:
  LD B,L
  LD E,C
  JR NZ,l_C2E5
  JR NZ,$C2E7
  JR NZ,l_C2C9

; l_C2C9
;
; Used by the routine at sub_C28D.
l_C2C9:
  CALL sub_C325
  LD A,$01
  LD ($FD52),A
  LD HL,data_D6A8+$012B
; This entry point is used by the routine at sub_C28D.
l_C2D4:
  LD DE,data_D6A8+$0283
  LD BC,$002D
  LDIR
  LD HL,$FF01
  LD BC,$00A8
  LDIR
  DI
; This entry point is used by the routine at sub_C28D.
l_C2E5:
  CALL sub_C30F
  LD (data_5B00),DE
  LD HL,$0900
  LD IX,data_5B00
  LD DE,$0002
  XOR A
  SCF
  CALL $04D0
  LD HL,$0900
; This entry point is used by the routine at sub_C28D.
l_C2FE:
  LD IX,data_D6A8+$0283
  LD DE,$24D1
  XOR A
  SCF
  CALL $04D0
  XOR A
  OUT ($FE),A
  EI
  RET

; sub_C30F
;
; Used by the routines at l_C21E and l_C2C9.
sub_C30F:
  LD HL,data_D6A8+$0283
  LD BC,$24D1
  LD DE,$0000
l_C318:
  LD A,(HL)
  INC HL
  ADD A,E
  LD E,A
  JR NC,l_C31F
  INC D
l_C31F:
  DEC BC
  LD A,B
  OR C
  JR NZ,l_C318
  RET

; sub_C325
;
; Used by the routines at l_C282 and l_C2C9.
sub_C325:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,sub_C325
l_C32D:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR Z,l_C32D
  RET

; sub_C336
;
; Used by the routines at l_C120, l_C137 and l_C151.
sub_C336:
  LD A,($D3E4)
  CP C
  JR Z,l_C343
  CALL sub_D42D

; data_C33F
data_C33F:
  DEFB $02,$46,$00

; l_C342
l_C342:
  RET
; This entry point is used by the routine at sub_C336.
l_C343:
  CALL sub_D42D

; data_C346
data_C346:
  DEFB $02,$45,$00

; l_C349
l_C349:
  RET

; sub_C34A
;
; Used by the routine at l_C192.
sub_C34A:
  CALL sub_D0B9
  CALL sub_D42D
  LD BC,$0902
  LD (BC),A
  LD B,A
  INC B
  LD HL,$4552
  LD B,H
  LD B,L
  LD B,(HL)
  LD C,C
  LD C,(HL)
  LD B,L
  JR NZ,l_C3AC
  LD B,L
  LD E,C
  LD D,E
  LD BC,$0305
  INC B
  NOP
  NOP

; l_C36A
l_C36A:
  CALL $028E
  LD A,E
  OR A
  JP P,l_C36A
  LD HL,KeyTable
  LD DE,KeyTable+$0001
  LD BC,$0017
  LD (HL),$00
  LDIR
  CALL sub_C40C
  JR NZ,l_C3A4
  JR NZ,$C3DB
  LD D,B
  NOP

; l_C388
l_C388:
  LD HL,KeyTable+$000E
  CALL sub_C427
  CALL sub_C40C
  JR NZ,$C3D7
  LD C,A
  LD D,A
  LD C,(HL)
  NOP

; l_C397
l_C397:
  LD HL,KeyTable+$0011
  CALL sub_C427
  CALL sub_C40C
  JR NZ,l_C3EE
  LD B,L
  LD B,(HL)
; This entry point is used by the routine at l_C36A.
l_C3A4:
  LD D,H
  NOP

; l_C3A6
l_C3A6:
  LD HL,KeyTable+$0014
  CALL sub_C427
; This entry point is used by the routine at sub_C34A.
l_C3AC:
  CALL sub_C40C
  LD D,D
  LD C,C
  LD B,A
  LD C,B
  LD D,H
  NOP

; l_C3B5
l_C3B5:
  LD HL,KeyTable+$0017
  CALL sub_C427
  CALL sub_C40C
  JR NZ,l_C406
  LD C,C
  LD D,D
  LD B,L
  NOP

; l_C3C4
l_C3C4:
  LD HL,KeyTable+$000B
  CALL sub_C427
  CALL sub_D470
  CALL sub_C40C
  LD D,B
  LD B,C
  LD D,L
  LD D,E
  LD B,L
  NOP

; l_C3D6
l_C3D6:
  LD HL,KeyTable+$0002
  CALL sub_C427
  CALL sub_C40C
  LD B,C
  LD B,D
  LD C,A
  LD D,D
  LD D,H
  NOP

; l_C3E5
l_C3E5:
  LD HL,KeyTable+$0005
  CALL sub_C427
  CALL sub_C40C
; This entry point is used by the routine at l_C397.
l_C3EE:
  JR NZ,$C443
  LD B,C
  LD D,(HL)
  LD B,L
  NOP

; l_C3F4
l_C3F4:
  LD HL,KeyTable+$0008
  CALL sub_C427
l_C3FA:
  CALL $028E
  LD A,E
  OR A
  JP P,l_C3FA
  LD BC,$0000
l_C405:
  DEC BC
; This entry point is used by the routine at l_C3B5.
l_C406:
  NOP
  LD A,C
  OR B
  JR NZ,l_C405
  RET

; sub_C40C
;
; Used by the routines at l_C36A, l_C388, l_C397, l_C3A6, l_C3B5, l_C3C4,
; l_C3D6 and l_C3E5.
sub_C40C:
  CALL sub_D42D
  INC BC
  INC BC
  LD (BC),A
  LD B,(HL)
  LD D,B
  LD D,D
  LD B,L
  LD D,E
  LD D,E
  JR NZ,l_C465
  LD B,L
  LD E,C
  JR NZ,l_C464
  LD C,A
  LD D,D
  JR NZ,l_C424
  LD B,L
  NOP

; l_C424
;
; Used by the routine at sub_C40C.
l_C424:
  JP sub_D42D

; sub_C427
;
; Used by the routines at l_C388, l_C397, l_C3A6, l_C3B5, l_C3C4, l_C3D6,
; l_C3E5 and l_C3F4.
sub_C427:
  PUSH HL
  CALL sub_D42D
  JR NZ,l_C44D
  LD (BC),A
  LD B,(HL)
  NOP

; l_C430
l_C430:
  CALL $028E
  LD A,E
  OR A
  JP M,l_C430
  LD HL,$0205
  ADD A,L
  LD L,A
  LD A,(HL)
  LD D,A
  LD HL,KeyTable+$0002
  LD B,$08
l_C444:
  CP (HL)
  JR Z,l_C430
  INC HL
  INC HL
  INC HL
  DJNZ l_C444
  POP HL
; This entry point is used by the routine at sub_C427.
l_C44D:
  LD (HL),A
  LD A,E
  AND $07
  LD C,A
  SRL E
  SRL E
  SRL E
  LD B,E
  INC B
  LD A,$20
l_C45C:
  RRCA
  DJNZ l_C45C
  DEC HL
  LD (HL),A
  LD B,C
  INC B
  XOR A
; This entry point is used by the routine at sub_C40C.
l_C464:
  DEC A
; This entry point is used by the routine at sub_C40C.
l_C465:
  RRA
  DJNZ l_C465
  DEC HL
  LD (HL),A
  LD A,D
  CP $0E
  JR NZ,l_C47A
  CALL sub_D42D
  LD D,E
  LD E,C
  LD C,L
  JR NZ,l_C4CA
  LD C,B
  NOP
  RET
l_C47A:
  CP $0D
  JR NZ,l_C488
  CALL sub_D42D
  LD B,L
  LD C,(HL)
  LD D,H
  LD B,L
  LD D,D
  NOP
  RET
l_C488:
  CP $E3
  JR NZ,l_C498
  CALL sub_D42D
  LD B,E
  LD B,C
  LD D,B
  LD D,E
  JR NZ,l_C4E8
  LD C,B
  NOP
  RET
l_C498:
  CP $20
  JP NZ,sub_D427
  CALL sub_D42D
  LD D,E
  LD D,B
  LD B,C
  LD B,E
  LD B,L
  NOP
; This entry point is used by the routines at sub_C53B and l_C56E.
l_C4A6:
  RET

; sub_C4A7
;
; Used by the routine at l_C192.
sub_C4A7:
  DI
  LD ($FD08),SP
  LD HL,MenuInterrupt
  LD ($FDFE),HL
  LD HL,data_C665+$0013
  LD DE,data_C665+$009D
  LD BC,$0101
  EXX
  LD HL,data_C665
  EI
  LD C,$01
  HALT
l_C4C3:
  PUSH AF
  LD A,(Input)
  LD (Input),A
; This entry point is used by the routine at l_C430.
l_C4CA:
  POP AF
l_C4CB:
  DEC D
  JP NZ,l_C4E0
  LD D,$00
  LD A,$18
  OUT ($FE),A
  LD A,$00
l_C4D7:
  DEC A
  JP NZ,l_C4D7
  OUT ($FE),A
  JP l_C4E8
l_C4E0:
  PUSH AF
  LD A,(Input)
  LD (Input),A
  POP AF
; This entry point is used by the routine at l_C430.
l_C4E8:
  DEC E
  JP NZ,l_C4C3
  LD E,$00
  LD A,$18
  OUT ($FE),A
  LD A,$00
l_C4F4:
  DEC A
  JP NZ,l_C4F4
  OUT ($FE),A
  JP l_C4CB

; the interrupt handler of the menu
MenuInterrupt:
  PUSH AF
  DEC C
  CALL Z,sub_C5DB
  EXX
  DEC C
  CALL Z,sub_C528
  DEC B
  CALL Z,sub_C53B
  CALL sub_C820
  LD A,$E7
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,l_C51B
  EXX
  POP AF
  EI
  RET
l_C51B:
  DI
  LD SP,($FD08)
  LD HL,StartInterrupt
  LD ($FDFE),HL
  EI
  RET

; sub_C528
;
; Used by the routines at MenuInterrupt, l_C58D, l_C5BB, l_C5CC, l_C635 and
; l_C63F.
sub_C528:
  LD A,(HL)
  CP $09
  JR C,l_C54F
  LD (l_C4E8+$0005),A
  RRCA
  RRCA
  AND $3F
  LD (l_C4E8+$000B),A
  INC HL
  LD C,(HL)
  INC HL
  RET

; sub_C53B
;
; Used by the routines at MenuInterrupt, l_C599, l_C5C3, l_C648 and l_C652.
sub_C53B:
  LD A,(DE)
  CP $09
  JR C,l_C56E
  LD (l_C4CB+$0005),A
  RRCA
  RRCA
  AND $3F
  LD (l_C4CB+$000B),A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
  RET
; This entry point is used by the routine at sub_C528.
l_C54F:
  PUSH HL
  CALL sub_C65B
  JP l_C4A6

; data_C556
data_C556:
  DEFB $C3,$A7,$C5

; l_C559
l_C559:
  JP l_C58D

; l_C55C
l_C55C:
  JP l_C5CC

; l_C55F
l_C55F:
  JP l_C635

; l_C562
l_C562:
  JP l_C63F

; l_C565
l_C565:
  JP l_C5BB

; data_C568
data_C568:
  DEFB $C3,$CC,$C5,$C3,$CC,$C5

; l_C56E
;
; Used by the routine at sub_C53B.
l_C56E:
  PUSH HL
  CALL sub_C65B
  JP l_C4A6

; data_C575
data_C575:
  DEFB $C3,$B0,$C5

; l_C578
l_C578:
  JP l_C599

; data_C57B
data_C57B:
  DEFB $C3,$CC,$C5

; l_C57E
l_C57E:
  JP l_C648

; l_C581
l_C581:
  JP l_C652

; l_C584
l_C584:
  JP l_C5C3

; data_C587
data_C587:
  DEFB $C3,$CC,$C5,$C3,$CC,$C5

; l_C58D
;
; Used by the routine at l_C559.
l_C58D:
  POP HL
  INC HL
  LD A,(HL)
  INC HL
  LD ($FD54),HL
  LD H,(HL)
  LD L,A
  JP sub_C528

; l_C599
;
; Used by the routine at l_C578.
l_C599:
  POP HL
  EX DE,HL
  INC HL
  LD A,(HL)
  INC HL
  LD ($FD56),HL
  LD H,(HL)
  LD L,A
  EX DE,HL
  JP sub_C53B

; data_C5A7
data_C5A7:
  DEFB $E1,$23,$7E,$23,$66,$6F,$C3,$28
  DEFB $C5,$E1,$EB,$23,$7E,$23,$66,$6F
  DEFB $EB,$C3,$3B,$C5

; l_C5BB
;
; Used by the routine at l_C565.
l_C5BB:
  POP HL
  LD HL,($FD54)
  INC HL
  JP sub_C528

; l_C5C3
;
; Used by the routine at l_C584.
l_C5C3:
  POP HL
  LD DE,($FD56)
  INC DE
  JP sub_C53B

; l_C5CC
;
; Used by the routine at l_C55C.
l_C5CC:
  POP HL
  INC HL
  LD A,(HL)
  INC HL
  EXX
  LD L,A
  EXX
  LD A,(HL)
  INC HL
  EXX
  LD H,A
  EXX
  JP sub_C528

; sub_C5DB
;
; Used by the routine at MenuInterrupt.
sub_C5DB:
  LD A,(HL)
  INC HL
  CP $01
  JR Z,l_C601
  LD C,A
  LD A,(HL)
  INC HL
  CP $02
  JR Z,l_C616
  AND A
  JR Z,l_C608
  PUSH HL
  LD H,$00
  LD B,$50
l_C5F0:
  LD A,(HL)
  AND $18
  OUT ($FE),A
  LD A,B
  CPL
  AND $3F
l_C5F9:
  DEC A
  JR NZ,l_C5F9
  INC HL
  DJNZ l_C5F0
  POP HL
  RET
l_C601:
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP sub_C5DB
l_C608:
  PUSH HL
  LD H,$08
  LD B,$60
l_C60D:
  LD A,(HL)
  AND $18
  OUT ($FE),A
  DJNZ l_C60D
  POP HL
  RET
l_C616:
  LD A,(HL)
  INC HL
  PUSH HL
  LD B,$30
  LD L,A
  RRCA
  LD H,A
l_C61E:
  XOR A
  OUT ($FE),A
  DEC L
  LD A,L
l_C623:
  DEC A
  JR NZ,l_C623
  LD A,$18
  OUT ($FE),A
  LD A,$04
  ADD A,H
  LD H,A
l_C62E:
  DEC A
  JR NZ,l_C62E
  DJNZ l_C61E
  POP HL
  RET

; l_C635
;
; Used by the routine at l_C55F.
l_C635:
  POP HL
  LD A,$18
  LD (l_C4E8+$0007),A
  INC HL
  JP sub_C528

; l_C63F
;
; Used by the routine at l_C562.
l_C63F:
  POP HL
  XOR A
  LD (l_C4E8+$0007),A
  INC HL
  JP sub_C528

; l_C648
;
; Used by the routine at l_C57E.
l_C648:
  POP HL
  LD A,$18
  LD (l_C4CB+$0007),A
  INC DE
  JP sub_C53B

; l_C652
;
; Used by the routine at l_C581.
l_C652:
  POP HL
  XOR A
  LD (l_C4CB+$0007),A
  INC DE
  JP sub_C53B

; sub_C65B
;
; Used by the routines at sub_C53B and l_C56E.
sub_C65B:
  LD L,A
  ADD A,A
  ADD A,L
  POP HL
  ADD A,L
  LD L,A
  JR NC,l_C664
  INC H
l_C664:
  JP (HL)

; data_C665
data_C665:
  DEFB $20,$00,$01,$65,$C6,$20,$00,$10
  DEFB $01,$08,$00,$08,$00,$20,$02,$30
  DEFB $01,$6C,$C6,$03,$65,$C6,$02,$BD
  DEFB $C6,$02,$BD,$C6,$02,$BD,$C6,$02
  DEFB $BD,$C6,$03,$6C,$C6,$02,$CC,$C6
  DEFB $02,$CC,$C6,$02,$DD,$C6,$02,$DD
  DEFB $C6,$02,$DD,$C6,$02,$DD,$C6,$02
  DEFB $DD,$C6,$02,$DD,$C6,$02,$DD,$C6
  DEFB $02,$DD,$C6,$02,$CC,$C6,$02,$CC
  DEFB $C6,$02,$CC,$C6,$02,$CC,$C6,$02
  DEFB $CC,$C6,$03,$65,$C6,$01,$78,$C6
  DEFB $7C,$10,$05,$7C,$08,$04,$7C,$10
  DEFB $05,$7C,$40,$52,$18,$04,$06,$7C
  DEFB $40,$6E,$40,$68,$40,$5D,$40,$7C
  DEFB $40,$6E,$40,$68,$40,$5D,$40,$06
  DEFB $7C,$08,$05,$7C,$08,$04,$7C,$08
  DEFB $05,$7C,$08,$04,$7C,$08,$8B,$08
  DEFB $93,$08,$A5,$08,$BA,$08,$A5,$08
  DEFB $93,$08,$8B,$08,$7C,$08,$8B,$08
  DEFB $93,$08,$A5,$08,$06,$02,$89,$C7
  DEFB $02,$89,$C7,$02,$89,$C7,$02,$89
  DEFB $C7,$02,$AA,$C7,$02,$AA,$C7,$02
  DEFB $AA,$C7,$02,$AA,$C7,$05,$02,$AA
  DEFB $C7,$04,$02,$C5,$C7,$02,$C5,$C7
  DEFB $02,$C5,$C7,$02,$C5,$C7,$02,$C5
  DEFB $C7,$02,$D2,$C7,$02,$C5,$C7,$02
  DEFB $D2,$C7,$02,$C5,$C7,$02,$D2,$C7
  DEFB $02,$C5,$C7,$3E,$20,$37,$20,$02
  DEFB $AA,$C7,$02,$AA,$C7,$02,$DF,$C7
  DEFB $02,$DF,$C7,$02,$DF,$C7,$02,$DF
  DEFB $C7,$02,$89,$C7,$02,$89,$C7,$02
  DEFB $89,$C7,$02,$89,$C7,$02,$C5,$C7
  DEFB $02,$C5,$C7,$02,$C5,$C7,$02,$C5
  DEFB $C7,$02,$C5,$C7,$02,$C5,$C7,$02
  DEFB $C5,$C7,$02,$C5,$C7,$02,$89,$C7
  DEFB $02,$89,$C7,$02,$89,$C7,$02,$89
  DEFB $C7,$01,$02,$C7,$37,$10,$05,$37
  DEFB $08,$04,$37,$10,$05,$37,$08,$04
  DEFB $29,$08,$2E,$08,$29,$08,$2E,$08
  DEFB $29,$08,$2E,$08,$29,$08,$2E,$08
  DEFB $37,$08,$3E,$08,$06,$29,$10,$2E
  DEFB $10,$31,$10,$37,$10,$3E,$20,$49
  DEFB $10,$3E,$10,$45,$20,$2E,$20,$29
  DEFB $10,$2E,$10,$34,$10,$2E,$10,$06
  DEFB $3E,$10,$52,$08,$7C,$08,$3E,$10
  DEFB $52,$08,$7C,$08,$06,$45,$10,$5D
  DEFB $08,$8B,$08,$45,$10,$5D,$08,$8B
  DEFB $08,$06,$29,$04,$2E,$04,$34,$04
  DEFB $37,$04,$3E,$04,$45,$04,$49,$04
  DEFB $52,$04,$5D,$04,$68,$04,$6E,$04
  DEFB $7C,$04,$8B,$04,$93,$04,$A5,$04
  DEFB $BA,$04,$29,$04,$2E,$04,$34,$04
  DEFB $37,$04,$3E,$04,$45,$04,$49,$04
  DEFB $52,$04,$5D,$04,$68,$04,$6E,$04
  DEFB $7C,$04,$8B,$04,$93,$04,$A5,$04
  DEFB $BA,$04,$06

; sub_C820
;
; Used by the routines at l_C192 and MenuInterrupt.
sub_C820:
  PUSH BC
  PUSH HL
  LD HL,$582A
  LD A,($FD33)
  INC A
  AND $0F
  LD ($FD33),A
  RRCA
  JR C,l_C846
  OR $40
  LD BC,$0C07
l_C836:
  PUSH BC
l_C837:
  LD (HL),A
  INC HL
  DJNZ l_C837
  LD B,A
  LD A,$14
  CALL sub_D351
  LD A,B
  POP BC
  DEC C
  JR NZ,l_C836
l_C846:
  POP HL
  POP BC
  RET

; sub_C849
;
; Used by the routine at l_A69A.
sub_C849:
  LD IY,data_D6A8+$0358
  LD DE,$0010
  LD B,$18
l_C852:
  LD A,(IY+$01)
  OR A
  JR Z,l_C85D
  ADD IY,DE
  DJNZ l_C852
  RET
l_C85D:
  DI
  LD HL,StartInterrupt
  LD ($FDFE),HL
  EI
  CALL sub_D0B9
  LD B,$08
  LD DE,$57F0
l_C86D:
  PUSH BC
  PUSH DE
  LD A,$08
  SUB B
  ADD A,A
  ADD A,A
  INC A
  LD HL,data_D6A8+$0020
  CALL sub_D351
  LD A,(HL)
  ADD A,A
  INC A
  LD HL,data_D6A8+$0098
  CALL sub_D348
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,B
  ADD A,A
  CALL sub_D351
  DEC C
  LD A,C
  CP $18
  JR C,l_C895
  LD C,$18
l_C895:
  CALL sub_D315
  POP DE
  POP BC
  LD A,E
  SUB $60
  LD E,A
  JR NC,l_C8A4
  LD A,D
  SUB $08
  LD D,A
l_C8A4:
  DJNZ l_C86D
  LD BC,$0409
  LD HL,$59E0
l_C8AC:
  PUSH BC
l_C8AD:
  LD (HL),$46
  INC HL
  DJNZ l_C8AD
  LD A,$1C
  CALL sub_D351
  POP BC
  DEC C
  JR NZ,l_C8AC
  CALL sub_D42D
  INC B
  LD ($4702),HL
  LD BC,$0300
  LD D,D
  LD C,A
  LD B,D
  LD C,A
  LD D,H
  LD BC,$0202
  INC B
  LD HL,$4F43
  LD C,(HL)
  LD D,E
  LD D,H
  LD D,D
  LD D,L
  LD B,E
  LD D,H
  LD C,C
  LD C,A
  LD C,(HL)
  INC B
  NOP
  LD (BC),A
  LD B,L
  LD BC,$1501
  LD B,L
  LD C,H
  LD B,L
  LD B,E
  LD D,H
  LD D,D
  LD C,A
  LD C,(HL)
  LD C,C
  LD B,E
  LD D,E
  LD BC,$1504
  LD C,(HL)
  LD D,L
  LD B,E
  LD C,H
  LD B,L
  LD B,C
  LD D,D
  LD BC,$1507
  LD D,B
  LD C,B
  LD B,C
  LD D,E
  LD B,L
  LD D,D
  LD D,E
  LD BC,$150A
  LD C,L
  LD C,C
  LD D,E
  LD D,E
  LD C,C
  LD C,H
  LD B,L
  LD D,E
  LD BC,$150D
  LD B,E
  LD B,C
  LD C,(HL)
  LD C,(HL)
  LD C,A
  LD C,(HL)
  LD BC,$1510
  LD B,C
  LD C,(HL)
  LD D,H
  LD C,C
  DEC L
  LD B,A
  LD D,D
  LD B,C
  LD D,(HL)
  LD BC,$1513
  LD D,H
  LD D,D
  LD B,C
  LD B,E
  LD C,E
  LD D,E
  LD BC,$1516
  LD B,D
  LD C,C
  LD D,B
  LD C,A
  LD B,H
  LD BC,$0515
  LD B,L
  LD E,B
  LD C,C
  LD D,H
  JR NZ,l_C98E
  LD D,H
  LD B,C
  LD D,D
  LD D,H
  INC BC
  LD C,L
  LD B,L
  LD C,(HL)
  LD D,L
  JR NZ,$C998
  LD C,A
  LD B,D
  LD C,A
  LD D,H
  LD (BC),A
  LD B,E
  LD BC,$1602
  INC SP
  LD BC,$1605
  LD ($0130),A
  EX AF,AF'
  LD D,$34
  LD BC,$160B
  INC (HL)
  LD BC,$160E
  LD ($1101),A
  LD D,$31
  JR NC,l_C968
  INC D
l_C968:
  LD D,$35
  LD BC,$1617
  INC SP
  INC B
  NOP
  LD (BC),A
  LD B,(HL)
  LD BC,$0006
  DEC L
  DEC L
  JR NZ,l_C9CB
  LD B,L
  LD D,E
  LD C,A
  LD D,L
  LD D,D
  LD B,E
  LD B,L
  LD D,E
  JR NZ,$C9B0
  DEC L
  INC BC
  DEC L
  DEC L
  JR NZ,l_C9CA
  LD D,(HL)
  LD B,C
  LD C,C
  LD C,H
  LD B,C
l_C98E:
  LD B,D
  LD C,H
  LD B,L
  JR NZ,l_C9C0
  DEC L
  LD (BC),A
  LD B,H
  LD BC,$0409
  LD B,A
  LD B,L
  LD C,(HL)
  LD B,L
  LD D,D
  LD B,C
  LD C,H
  LD BC,$000B
  LD B,L
  LD C,H
  LD B,L
  LD B,E
  LD D,H
  LD D,D
  LD C,A
  LD C,(HL)
  LD C,C
  LD B,E
  LD D,E
  LD BC,$040C
  LD C,(HL)
  LD D,L
  LD B,E
  LD C,H
  LD B,L
  LD B,C
  LD D,D
  INC BC
  LD D,B
  LD C,B
  LD B,C
  LD D,E
  LD B,L
  LD D,D
  LD D,E
l_C9C0:
  LD BC,$030E
  LD C,L
  LD C,C
  LD D,E
  LD D,E
  LD C,C
  LD C,H
  LD B,L
l_C9CA:
  LD D,E
l_C9CB:
  LD BC,$050F
  LD B,E
  LD B,C
  LD C,(HL)
  LD C,(HL)
  LD C,A
  LD C,(HL)
  LD BC,$0410
  LD B,E
  LD C,B
  LD B,C
  LD D,E
  LD D,E
  LD C,C
  LD D,E
  LD BC,$0612
  LD D,H
  LD C,A
  LD D,H
  LD B,C
  LD C,H
  NOP
  LD (IY+$08),$04
  LD (IY+$0D),$00
  LD HL,$FD22
  LD DE,$FD29
  LD BC,$0007
  LDIR
  CALL sub_CBE0
  LD HL,$0002
  LD ($FD1F),HL
  XOR A
  LD ($FD21),A
  CALL sub_CC1F
  LD C,$46
  CALL sub_CBA9
; This entry point is used by the routine at l_CB00.
l_CA0F:
  CALL WaitKey
  AND $1F
  JR Z,l_CA0F
  LD HL,($FD1F)
  LD A,(Input)
  AND $10
  JP Z,l_CB00
  LD A,L
  OR A
  JP Z,l_CB8E
  DEC A
  JP Z,l_CB52
  LD A,H
  LD E,A
  LD B,A
  INC B
  XOR A
  SCF
l_CA30:
  RLA
  DJNZ l_CA30
  LD D,A
  LD A,($FD21)
  LD C,A
  AND D
  JR NZ,l_CAA4
  LD A,E
  CP $03
  JR NC,l_CA57
  LD A,C
  AND $07
  JR Z,l_CA57
  PUSH DE
  LD E,$FF
l_CA48:
  INC E
  RRCA
  JR NC,l_CA48
  CALL sub_CAC1
  LD A,C
  AND $F8
  LD C,A
  LD ($FD21),A
  POP DE
l_CA57:
  LD A,C
  OR D
  AND $78
  CP $78
  JP Z,l_CAAC
  LD HL,data_CAF0
  LD A,E
  CALL sub_D351
  LD B,(HL)
  LD HL,data_CAF0+$0008
  LD A,E
  CALL sub_D351
  LD A,(HL)
  LD HL,$FD29
  CALL sub_D351
  LD A,(HL)
  SUB B
  JP NC,l_CA89
  NEG
  LD B,A
  LD A,($FD29)
  SUB B
  JP C,l_CAAC
  LD ($FD29),A
  XOR A
l_CA89:
  LD (HL),A
  LD A,C
  OR D
  LD ($FD21),A
  LD A,$64
  CALL sub_CCAC
  CALL sub_CC1F
  CALL sub_CBE0
l_CA9A:
  CALL WaitKey
  AND $10
  JR NZ,l_CA9A
  JP l_CB4A
l_CAA4:
  CALL sub_CAC1
  LD A,C
  XOR D
  LD ($FD21),A
l_CAAC:
  LD A,$78
  CALL sub_CCAC
  CALL sub_CC1F
  CALL sub_CBE0
l_CAB7:
  CALL WaitKey
  AND $10
  JR NZ,l_CAB7
  JP l_CB4A

; sub_CAC1
;
; Used by the routine at sub_C849.
sub_CAC1:
  LD HL,data_CAF0
  LD A,E
  CALL sub_D351
  LD B,(HL)
  LD HL,data_CAF0+$0008
  LD A,E
  CALL sub_D351
  LD A,(HL)
  LD HL,$FD29
  CALL sub_D351
  LD A,(HL)
  ADD A,B
  LD (HL),A
  PUSH HL
  LD A,L
  SUB $07
  LD L,A
  LD B,(HL)
  POP HL
  LD A,(HL)
  CP B
  RET Z
  RET C
  LD (HL),B
  SUB B
  LD B,A
  LD A,($FD29)
  ADD A,B
  LD ($FD29),A
  RET

; data_CAF0
data_CAF0:
  DEFB $03,$05,$0A,$02,$04,$04,$14,$03
  DEFB $06,$06,$06,$05,$04,$03,$02,$01

; l_CB00
;
; Used by the routine at sub_C849.
l_CB00:
  LD A,(Input)
  AND $03
  JR Z,l_CB1B
  LD C,A
  LD A,L
  RR C
  JR NC,l_CB0E
  INC A
l_CB0E:
  RR C
  JR NC,l_CB13
  DEC A
l_CB13:
  CP $03
  JR NC,l_CB4A
  LD L,A
  JP l_CB36
l_CB1B:
  LD A,(Input)
  RRCA
  RRCA
  LD C,A
  LD A,L
  CP $02
  JR NZ,l_CB4A
  LD A,H
  RR C
  JR NC,l_CB2C
  DEC A
l_CB2C:
  RR C
  JR NC,l_CB31
  INC A
l_CB31:
  CP $08
  JR NC,l_CB4A
  LD H,A
l_CB36:
  PUSH HL
  LD C,$45
  CALL sub_CBA9
  POP HL
  LD ($FD1F),HL
  LD C,$46
  CALL sub_CBA9
  LD A,$14
  CALL sub_CCAC
; This entry point is used by the routine at sub_C849.
l_CB4A:
  LD B,$0A
l_CB4C:
  HALT
  DJNZ l_CB4C
  JP l_CA0F
; This entry point is used by the routine at sub_C849.
l_CB52:
  LD A,($FD21)
  LD C,A
  AND $07
  JR Z,l_CB4A
  LD A,C
  AND $78
  JR Z,l_CB4A
  LD HL,$FD29
  LD DE,$FD22
  LD BC,$0007
  LDIR
  LD HL,(ShipX)
  LD A,(ShipY)
  ADD A,$04
  LD B,A
  LD (IY+$0A),$00
  CALL sub_CC7C
  LD A,($FD21)
  LD (IY+$07),A
  LD B,$50
l_CB82:
  LD A,B
  CALL sub_CCAC
  LD A,B
  SUB $05
  LD B,A
  CP $14
  JR NC,l_CB82
; This entry point is used by the routine at sub_C849.
l_CB8E:
  LD A,$C8
  CALL sub_CCAC
  LD A,$05
  LD ($FD30),A
  PUSH IY
  CALL sub_CFFE
  CALL sub_D0CA
  POP IY
  LD HL,PlayInterrupt
  LD ($FDFE),HL
  RET

; sub_CBA9
;
; Used by the routines at sub_C849 and l_CB00.
sub_CBA9:
  LD HL,($FD1F)
  LD A,L
  CP $02
  JR Z,l_CBC6
  ADD A,A
  ADD A,L
  ADD A,A
  ADD A,$A4
  LD L,A
  LD H,$5A
  LD B,$05
  CALL sub_CBDB
  LD A,L
  ADD A,$1B
  LD L,A
  LD B,$05
  JR sub_CBDB
l_CBC6:
  LD A,H
  ADD A,A
  ADD A,H
  NEG
  ADD A,$16
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD DE,$5815
  ADD HL,DE
  LD B,$0B

; sub_CBDB
;
; Used by the routines at sub_AD3C and sub_CBA9.
sub_CBDB:
  LD (HL),C
  INC HL
  DJNZ sub_CBDB
  RET

; sub_CBE0
;
; Used by the routine at sub_C849.
sub_CBE0:
  LD DE,$FD29
  LD HL,$0000
  LD C,$09
  LD B,$07
l_CBEA:
  LD A,(DE)
  CALL sub_D351
  LD A,(DE)
  CALL sub_CC08
  INC DE
  INC C
  LD A,B
  CP $07
  JR NZ,l_CBFA
  INC C
l_CBFA:
  DJNZ l_CBEA
  CALL sub_D42D
  LD BC,$0C12
  NOP
  LD E,$20
  JP sub_D401

; sub_CC08
;
; Used by the routine at sub_CBE0.
sub_CC08:
  PUSH AF
  LD A,C
  LD (sub_CC08+$0009),A
  CALL sub_D42D
  LD BC,$0D00
  NOP
  POP AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL sub_D3E5
  POP HL
  POP DE
  POP BC
  RET

; sub_CC1F
;
; Used by the routine at sub_C849.
sub_CC1F:
  LD HL,$5810
  LD A,($FD21)
  LD C,A
  LD B,$08
l_CC28:
  LD E,$06
  RL C
  JR NC,l_CC30
  LD E,$47
l_CC30:
  PUSH BC
  LD BC,$0403
l_CC34:
  PUSH BC
l_CC35:
  LD (HL),E
  INC HL
  DJNZ l_CC35
  LD A,$1C
  CALL sub_D351
  POP BC
  DEC C
  JR NZ,l_CC34
  POP BC
  DJNZ l_CC28
  CALL sub_CFFE
  LD A,($FD21)
  LD (IY+$07),A
  LD DE,$0A07
  CALL sub_CEE8
  LD A,($CF3F)
  LD (IY+$09),A
  LD BC,$0448
  LD DE,data_5B00+$0668
  LD HL,$48E0
l_CC63:
  PUSH BC
  PUSH HL
l_CC65:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC HL
  DJNZ l_CC65
  LD A,E
  ADD A,$10
  LD E,A
  LD A,D
  ADC A,$00
  LD D,A
  POP HL
  CALL sub_D32A
  POP BC
  DEC C
  JR NZ,l_CC63
  RET

; sub_CC7C
;
; Used by the routines at l_B154, sub_B7F4 and l_CB00.
sub_CC7C:
  LD (IY+$02),L
  LD (IY+$03),H
  LD (IY+$04),B
  PUSH HL
  LD A,B
  CALL sub_CCA6
  LD (IY+$00),L
  LD (IY+$01),H
  SET 6,(HL)
  POP HL
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  JP sub_D65A

; sub_CCA0
;
; Used by the routines at l_A69A, sub_B01D, sub_B024 and sub_B99F.
sub_CCA0:
  LD HL,(ShipX)
  LD A,(ShipY)

; sub_CCA6
;
; Used by the routines at l_AD90, CheckShipMove, sub_B5D6, sub_B724, sub_B7F4,
; sub_BBB9, sub_CC7C and l_CE68.
sub_CCA6:
  ADD A,A
  ADD A,$DD
  ADD A,H
  LD H,A
  RET

; sub_CCAC
;
; Used by the routines at sub_A720, sub_A941, l_AB52, sub_ACD7, sub_AE6B,
; l_C282, sub_C849 and l_CB00.
sub_CCAC:
  PUSH BC
  LD B,A
  XOR A
  LD C,A
l_CCB0:
  PUSH BC
  XOR $10
  OUT ($FE),A
l_CCB5:
  DJNZ l_CCB5
  POP BC
  DEC C
  JR NZ,l_CCB0
  POP BC
  RET

; sub_CCBD
;
; Used by the routines at l_A69A, sub_A941, l_AB52, sub_ACD7, sub_B99F and
; sub_D0CA.
sub_CCBD:
  CALL sub_CFD7
  CALL sub_CCC6
  JP l_D071

; sub_CCC6
;
; Used by the routine at sub_CCBD.
sub_CCC6:
  LD HL,$0000
  LD ($FD11),HL
  XOR A
  LD (sub_CF2D+$0012),A
  LD HL,(ShipX)
  LD DE,(MapView)
  LD A,D
  AND $01
  LD D,A
  XOR A
  SBC HL,DE
  LD E,L
  LD A,(ShipY)
  LD D,A
  LD A,$01
  CALL sub_CF2D
  LD HL,(MapView)
  LD A,$20
  CALL sub_D351
  LD DE,$0020
l_CCF3:
  DEC HL
  DEC E
  PUSH HL
  PUSH DE
l_CCF7:
  LD A,E
  OR A
  JP M,l_CD01
  LD A,(HL)
  OR A
  CALL NZ,sub_CD18
l_CD01:
  INC H
  INC H
  INC HL
  INC D
  INC E
  LD A,D
  CP $10
  JR NC,l_CD10
  LD A,E
  CP $20
  JR NZ,l_CCF7
l_CD10:
  LD A,E
  POP DE
  POP HL
  CP $01
  JR NZ,l_CCF3
  RET

; sub_CD18
;
; Used by the routine at sub_CCC6.
sub_CD18:
  PUSH HL
  PUSH DE
  PUSH AF
  BIT 5,A
  JR NZ,l_CD2B
  AND $1F
  JR Z,l_CD2B
  LD HL,sub_CF2D+$0012
  LD (HL),$00
  CALL sub_CF2D
l_CD2B:
  POP AF
  POP DE
  POP HL
  BIT 6,A
  CALL NZ,sub_CE12
  LD A,(HL)
  BIT 7,A
  RET Z
  LD BC,($FD11)
  LD A,B
  OR C
  JR NZ,l_CD79
  PUSH DE
  LD D,H
  LD E,L
  CALL sub_CD96
  PUSH HL
  DEC HL
  DEC H
  DEC H
  CALL sub_CD90
  INC H
  INC H
  CALL sub_CD90
  INC H
  INC H
  LD A,H
  CP $FD
  JR NC,l_CD63
  CALL sub_CD90
  INC HL
  CALL sub_CD90
  INC HL
  CALL sub_CD90
l_CD63:
  POP HL
  LD A,D
  CP H
  JR NZ,l_CD6F
  LD A,E
  CP L
  JR NZ,l_CD6F
  POP DE
  JR l_CD81
l_CD6F:
  EX DE,HL
  SET 7,(HL)
  EX DE,HL
  POP DE
  LD ($FD11),DE
  RET
l_CD79:
  RES 7,(HL)
  PUSH HL
  PUSH DE
  LD D,B
  LD E,C
  JR l_CD83
l_CD81:
  PUSH HL
  PUSH DE
l_CD83:
  LD A,($FD10)
  LD (sub_CF2D+$0012),A
  XOR A
  CALL sub_CF2D
  POP DE
  POP HL
  RET

; sub_CD90
;
; Used by the routine at sub_CD18.
sub_CD90:
  BIT 6,(HL)
  RET Z
  CALL sub_CDBF

; sub_CD96
;
; Used by the routines at sub_CD18 and l_CE68.
sub_CD96:
  PUSH HL
  DEC HL
  INC H
  INC H
  LD A,H
  CP $FD
  JR NC,l_CDA7
  CALL sub_CDB8
  INC HL
  CALL sub_CDB8
  DEC HL
l_CDA7:
  DEC H
  DEC H
  CALL sub_CDB8
  INC HL
  INC HL
  INC H
  INC H
  LD A,H
  CP $FD
  CALL C,sub_CDB8
  POP HL
  RET

; sub_CDB8
;
; Used by the routine at sub_CD96.
sub_CDB8:
  BIT 5,(HL)
  RET NZ
  LD A,(HL)
  AND $1F
  RET Z

; sub_CDBF
;
; Used by the routine at sub_CD90.
sub_CDBF:
  LD A,E
  SUB L
  LD C,A
  LD A,D
  SUB $DD
  SRL A
  LD B,A
  LD A,H
  SUB $DD
  SRL A
  SUB B
  ADD A,C
  RET M
  JR NZ,l_CDD5
  LD A,C
  OR A
  RET P
l_CDD5:
  LD D,H
  LD E,L
  RET

; sub_CDD8
;
; Used by the routines at l_A69A, l_AD90, sub_B099, sub_B66E, sub_B724,
; sub_B99F and sub_CE12.
sub_CDD8:
  LD IY,data_D6A8+$0358
  LD B,$30
l_CDDE:
  LD A,(IY+$00)
  CP L
  JR NZ,l_CDE9
  LD A,(IY+$01)
  CP H
  RET Z
l_CDE9:
  PUSH DE
  LD DE,$0010
  ADD IY,DE
  POP DE
  DJNZ l_CDDE
  OR $01
  RET

; sub_CDF5
;
; Used by the routines at l_A69A, l_B0AB, sub_BC5D and sub_CE12.
sub_CDF5:
  LD IY,$FF01
  LD B,$38
l_CDFB:
  LD A,(IY+$00)
  CP L
  JR NZ,l_CE06
  LD A,(IY+$01)
  CP H
  RET Z
l_CE06:
  PUSH DE
  LD DE,$0003
  ADD IY,DE
  POP DE
  DJNZ l_CDFB
  OR $01
  RET

; sub_CE12
;
; Used by the routine at sub_CD18.
sub_CE12:
  CALL sub_CDD8
  JR Z,l_CE68
  CALL sub_CDF5
  JR Z,l_CE38
  LD IY,data_D6A8+$012B
  LD B,$05
l_CE22:
  LD A,(IY+$00)
  CP L
  JR NZ,l_CE2E
  LD A,(IY+$01)
  CP H
  JR Z,l_CE68
l_CE2E:
  PUSH DE
  LD DE,$0009
  ADD IY,DE
  POP DE
  DJNZ l_CE22
  RET
l_CE38:
  PUSH HL
  PUSH DE
  LD A,(IY+$02)
  LD C,A
  LD HL,data_CE56+$0009
  CALL sub_D351
  LD A,(HL)
  LD (sub_CF2D+$0012),A
  LD A,C
  LD HL,data_CE56
  CALL sub_D351
  LD A,(HL)
  CALL sub_CF2D
  POP DE
  POP HL
  RET

; data_CE56
data_CE56:
  DEFB $2C,$28,$25,$23,$20,$1D,$17,$2A
  DEFB $2B,$13,$0F,$0F,$0F,$0F,$0F,$0F
  DEFB $1A,$1A

; l_CE68
;
; Used by the routine at sub_CE12.
l_CE68:
  PUSH DE
  LD D,H
  LD E,L
  CALL sub_CD96
  LD A,D
  CP H
  JR NZ,l_CE76
  LD A,E
  CP L
  JR Z,l_CE82
l_CE76:
  EX DE,HL
  SET 6,(HL)
  LD (IY+$00),L
  LD (IY+$01),H
  EX DE,HL
  POP DE
  RET
l_CE82:
  POP DE
  PUSH DE
  EX DE,HL
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD A,(IY+$04)
  CALL sub_CCA6
  LD A,D
  CP H
  JR NZ,l_CE9C
  LD A,E
  CP L
  JR NZ,l_CE9C
  POP DE
  JR sub_CEC3
l_CE9C:
  LD (IY+$00),L
  LD (IY+$01),H
  LD B,H
  LD C,L
  EX DE,HL
  POP DE
  PUSH DE
  PUSH HL
  RES 6,(HL)
  DEC HL
  DEC E
l_CEAC:
  LD A,C
  CP L
  JR Z,l_CEB4
  INC HL
  INC E
  JR l_CEAC
l_CEB4:
  LD A,B
  CP H
  JR Z,l_CEBD
  DEC H
  DEC H
  DEC D
  JR l_CEB4
l_CEBD:
  CALL sub_CEC3
  POP HL
  POP DE
  RET

; sub_CEC3
;
; Used by the routine at l_CE68.
sub_CEC3:
  PUSH IY
  POP BC
  LD A,B
  CP $D8
  JP NC,sub_CEE8
  PUSH HL
  PUSH DE
  LD C,(IY+$07)
  LD A,(IY+$05)
  CP $03
  CCF
  RL C
  LD A,(IY+$08)
  LD (sub_CF2D+$0012),A
  LD A,$2B
  ADD A,C
  CALL sub_CF2D
  POP DE
  POP HL
  RET

; sub_CEE8
;
; Used by the routines at sub_CC1F and sub_CEC3.
sub_CEE8:
  PUSH HL
  LD C,(IY+$07)
  LD B,$08
  LD A,(IY+$0D)
  LD (sub_CF2D+$0012),A
l_CEF4:
  RR C
  CALL C,sub_CEFD
  DJNZ l_CEF4
  POP HL
  RET

; sub_CEFD
;
; Used by the routine at sub_CEE8.
sub_CEFD:
  PUSH BC
  PUSH DE
  LD A,$08
  SUB B
  PUSH AF
  LD C,(IY+$08)
  LD B,$FF
l_CF08:
  INC B
  RR C
  JR NC,l_CF08
  ADD A,A
  ADD A,A
  ADD A,B
  LD HL,data_D6A8+$0020
  CALL sub_D351
  LD A,(HL)
  ADD A,$16
  CALL sub_CF2D
  POP AF
  POP DE
  POP BC
  LD HL,data_D6A8+$010C
  CALL sub_D351
  LD A,($CF3F)
  ADD A,(HL)
  LD (sub_CF2D+$0012),A
  RET

; sub_CF2D
;
; Used by the routines at sub_CCC6, sub_CD18, sub_CE12, sub_CEC3 and sub_CEFD.
sub_CF2D:
  LD C,A
  RLC E
  LD A,E
  ADD A,D
  SUB $18
  LD L,A
  RLC E
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$64
  SUB E
  SUB $00
  LD H,A
  LD A,C
  AND $3F
  SRA L
  ADC A,A
  PUSH HL
  LD HL,data_D6A8+$0040
  CALL sub_D348
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  EX DE,HL
  POP HL
  XOR A
  LD (l_CFAC+$0003),A
  LD A,L
  CP $14
  RET P
  LD A,H
  CP $A0
  JR C,l_CF77
  CP $E2
  RET NC
  SUB $9F
  SUB C
  RET P
  NEG
  LD C,A
l_CF6B:
  PUSH BC
l_CF6C:
  INC DE
  INC DE
  DJNZ l_CF6C
  POP BC
  DEC H
  LD A,H
  CP $9F
  JR NZ,l_CF6B
l_CF77:
  LD A,L
  OR A
  JP P,l_CF85
  NEG
  LD (l_CFAC+$0003),A
  LD L,$00
  CP B
  RET NC
l_CF85:
  LD A,L
  ADD A,B
  CP $15
  JR C,l_CF95
  SUB $14
  LD (l_CFAC+$0003),A
l_CF90:
  DEC DE
  DEC DE
  DEC A
  JR NZ,l_CF90
l_CF95:
  PUSH DE
  LD A,L
  PUSH AF
  LD L,H
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  POP AF
  CALL sub_D351
  LD DE,data_5B00
  ADD HL,DE
  POP DE
  EX DE,HL
l_CFAC:
  PUSH BC
  PUSH DE
  LD A,$00
  OR A
  JP Z,l_CFBB
l_CFB4:
  INC HL
  INC HL
  DEC B
  DEC A
  JP NZ,l_CFB4
l_CFBB:
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ l_CFBB
  POP DE
  POP BC
  LD A,$EC
  ADD A,E
  LD E,A
  JP C,l_CFD2
  DEC D
  LD A,D
  CP $5A
  RET Z
l_CFD2:
  DEC C
  JP NZ,l_CFAC
  RET

; sub_CFD7
;
; Used by the routines at l_A68E and sub_CCBD.
sub_CFD7:
  CALL sub_CFFE
  CALL sub_D026
  LD HL,data_D6A8
  LD B,$06
  LD DE,data_5B00+$000A
  CALL sub_D057
  LD HL,data_D6A8
  LD B,$03
  LD DE,data_5B00+$0AB2
  CALL sub_D057
  LD HL,data_D6A8+$0010
  LD B,$04
  LD DE,data_5B00+$0A12
  JP sub_D057

; sub_CFFE
;
; Used by the routines at l_CB00, sub_CC1F and sub_CFD7.
sub_CFFE:
  LD ($FD08),SP
  LD SP,data_5B00+$0C80
  LD B,$C6
  LD HL,$0000
l_D00A:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ l_D00A
  LD SP,($FD08)
  LD HL,data_5B00
  LD DE,data_5B00+$0001
  LD BC,$001F
  LD (HL),$00
  LDIR
  RET

; sub_D026
;
; Used by the routine at sub_CFD7.
sub_D026:
  LD A,$0A
  LD (l_D036+$0002),A
  LD (l_D03B+$0006),A
  LD HL,data_5B00
  LD B,$05
l_D033:
  PUSH BC
  LD B,$08
l_D036:
  PUSH BC
  LD B,$0A
  LD A,$FF
l_D03B:
  LD (HL),A
  INC HL
  DJNZ l_D03B
  POP BC
  LD A,$0A
  CALL sub_D351
  DJNZ l_D036
  POP BC
  PUSH HL
  LD HL,l_D036+$0002
  DEC (HL)
  DEC (HL)
  LD HL,l_D03B+$0006
  INC (HL)
  INC (HL)
  POP HL
  DJNZ l_D033
  RET

; sub_D057
;
; Used by the routine at sub_CFD7.
sub_D057:
  PUSH BC
  PUSH HL
  LD BC,$08FF
l_D05C:
  LDI
  LDI
  LD A,$12
  ADD A,E
  LD E,A
  LD A,D
  ADC A,$00
  LD D,A
  DJNZ l_D05C
  POP HL
  POP BC
  DEC DE
  DEC DE
  DJNZ sub_D057
  RET

; l_D071
;
; Used by the routine at sub_CCBD.
l_D071:
  LD HL,data_5B00
  LD DE,$4021
  LD C,$14
l_D079:
  LD B,$08
l_D07B:
  PUSH BC
  PUSH DE
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
  LDI
  LDI
  LDI
  LDI
  POP DE
  POP BC
  INC D
  DJNZ l_D07B
  LD A,E
  ADD A,$20
  LD E,A
  JR C,l_D0B4
  LD A,D
  SUB $08
  LD D,A
l_D0B4:
  DEC C
  JP NZ,l_D079
  RET

; sub_D0B9
;
; Used by the routines at sub_C100, sub_C34A, sub_C849 and sub_D0CA.
sub_D0B9:
  XOR A
  OUT ($FE),A
  LD HL,$4000
  LD DE,$4001
  LD BC,$1AFF
  LD (HL),$00

; l_D0C7
l_D0C7:
  LDIR
  RET

; sub_D0CA
;
; Used by the routines at l_A68E and l_CB00.
sub_D0CA:
  CALL sub_D0B9
  CALL sub_CCBD
  LD HL,$4000
  LD DE,$4001
  LD BC,$0015
  LD (HL),$FF
  LDIR
  LD HL,$4701
  LD DE,$4702
  LD BC,$0013
  LD (HL),$FF
  LDIR
  LD HL,$50A1
  LD DE,$50A2
  LD BC,$0013
  LD (HL),$FF
  LDIR
  LD HL,$57A0
  LD DE,$57A1
  LD BC,$0015
  LD (HL),$FF
  LDIR
  LD HL,$4100
  LD B,$06
l_D109:
  LD (HL),$80
  INC H
  DJNZ l_D109
  LD HL,$4115
  LD B,$06
l_D113:
  LD (HL),$01
  INC H
  DJNZ l_D113
  LD HL,$50A0
  LD B,$07
l_D11D:
  LD (HL),$80
  INC H
  DJNZ l_D11D
  LD HL,$50B5
  LD B,$07
l_D127:
  LD (HL),$01
  INC H
  DJNZ l_D127
  LD HL,$4700
  LD B,$A2
l_D131:
  LD (HL),$81
  CALL sub_D32A
  DJNZ l_D131
  LD HL,$4715
  LD B,$A2
l_D13D:
  LD (HL),$81
  CALL sub_D32A
  DJNZ l_D13D
  LD HL,$5800
  LD DE,$5801
  LD BC,$02FF
  LD (HL),$07
  LDIR
  LD HL,$5800
  LD DE,$5801
  LD BC,$0015
  LD (HL),$78
  LDIR
  LD HL,$5AA0
  LD DE,$5AA1
  LD BC,$0015
  LD (HL),$78
  LDIR
  LD HL,$5820
  LD B,$14
l_D170:
  LD (HL),$78
  LD A,$15
  CALL sub_D351
  LD (HL),$78
  LD A,$0B
  CALL sub_D351
  DJNZ l_D170
  LD HL,$5821
  LD BC,$1414
l_D186:
  PUSH BC
l_D187:
  LD (HL),$70
  INC HL
  DJNZ l_D187
  POP BC
  LD A,$0C
  CALL sub_D351
  DEC C
  JR NZ,l_D186
  LD B,$04
  LD HL,$5A33
l_D19A:
  LD (HL),$71
  INC HL
  LD (HL),$71
  LD A,$1D
  CALL sub_D351
  DJNZ l_D19A
  LD HL,$5A53
  LD (HL),$41
  INC HL
  LD (HL),$41
  LD HL,$5A71
  LD B,$04
l_D1B3:
  LD (HL),$41
  INC HL
  DJNZ l_D1B3
  LD HL,$5A8F
  LD B,$06
l_D1BD:
  LD (HL),$41
  INC HL
  DJNZ l_D1BD
  CALL sub_D42D

; data_D1C5
data_D1C5:
  DEFB $02,$57,$01,$00,$16,$04,$00,$20
  DEFB $44,$41,$59,$3A,$03,$54,$49,$4D
  DEFB $45,$3A,$01,$16,$00,$04,$21,$02
  DEFB $45,$52,$41,$44,$41,$52,$3A,$00

; sub_D1E5
;
; Used by the routine at sub_A720.
sub_D1E5:
  CALL sub_D2F6
  CALL sub_D42D

; data_D1EB
data_D1EB:
  DEFB $01,$03,$16,$02,$46,$20,$20,$53
  DEFB $54,$41,$54,$55,$53,$03,$49,$4E
  DEFB $53,$47,$20,$20,$48,$55,$4D,$4E
  DEFB $01,$06,$17,$02,$45,$57,$41,$52
  DEFB $42,$41,$53,$45,$53,$03,$45,$4C
  DEFB $45,$43,$54,$52,$27,$53,$03,$4E
  DEFB $55,$43,$4C,$45,$41,$52,$03,$50
  DEFB $48,$41,$53,$45,$52,$53,$03,$4D
  DEFB $49,$53,$53,$49,$4C,$45,$53,$03
  DEFB $20,$43,$41,$4E,$4E,$4F,$4E,$03
  DEFB $43,$48,$41,$53,$53,$49,$53,$03
  DEFB $20,$52,$4F,$42,$4F,$54,$53,$01
  DEFB $0F,$17,$02,$46,$52,$45,$53,$4F
  DEFB $55,$52,$43,$45,$53,$03,$03,$02
  DEFB $44,$47,$45,$4E,$45,$52,$41,$4C
  DEFB $03,$45,$4C,$45,$43,$54,$52,$27
  DEFB $03,$4E,$55,$43,$4C,$45,$41,$52
  DEFB $03,$50,$48,$41,$53,$45,$52,$53
  DEFB $03,$4D,$49,$53,$53,$49,$4C,$45
  DEFB $03,$43,$41,$4E,$4E,$4F,$4E,$03
  DEFB $43,$48,$41,$53,$53,$49,$53,$00

; sub_D293
;
; Used by the routines at l_A69A, l_AD90, sub_AE38, sub_B0FA, sub_B7F4 and
; sub_B99F.
sub_D293:
  LD A,($FD39)
  OR A
  RET NZ
  CALL sub_D42D

; data_D29B
data_D29B:
  DEFB $01,$10,$1E,$02,$4E,$04,$00,$00

; l_D2A3
l_D2A3:
  LD HL,$FD22
  LD B,$07
l_D2A8:
  PUSH BC
  PUSH HL
  CALL sub_D470
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  CALL sub_D3E5
  POP HL
  POP BC
  DJNZ l_D2A8
  CALL sub_D42D

; data_D2BB
data_D2BB:
  DEFB $01,$06,$16,$02,$47,$00

; l_D2C1
l_D2C1:
  LD HL,$FD42
  CALL sub_D2E3
  LD A,(HL)
  CALL sub_D3EC
  CALL sub_D42D

; data_D2CE
data_D2CE:
  DEFB $01,$06,$1F,$00

; l_D2D2
l_D2D2:
  LD HL,$FD3A
  CALL sub_D2E3
  CALL sub_D42D

; data_D2DB
data_D2DB:
  DEFB $01,$0D,$1E,$00

; l_D2DF
l_D2DF:
  LD A,(HL)
  JP sub_D3EC

; sub_D2E3
;
; Used by the routines at l_D2C1 and l_D2D2.
sub_D2E3:
  LD B,$07
l_D2E5:
  PUSH BC
  LD A,(HL)
  INC HL
  ADD A,$30
  CALL sub_D427
  PUSH HL
  CALL sub_D470
  POP HL
  POP BC
  DJNZ l_D2E5
  RET

; sub_D2F6
;
; Used by the routines at sub_A720, sub_A941, l_AB52 and sub_D1E5.
sub_D2F6:
  CALL sub_D42D

; data_D2F9
data_D2F9:
  DEFB $01,$02,$16,$04,$00,$02,$00,$00

; l_D301
l_D301:
  LD B,$16

; l_D303
;
; Used by the routine at l_D312.
l_D303:
  CALL sub_D42D

; data_D306
data_D306:
  DEFB $20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$03,$00

; l_D312
l_D312:
  DJNZ l_D303
  RET

; sub_D315
;
; Used by the routine at sub_C849.
sub_D315:
  PUSH BC
  PUSH DE
l_D317:
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ l_D317
  POP DE
  POP BC
  CALL sub_D339
  DEC C
  JP NZ,sub_D315
  RET

; sub_D32A
;
; Used by the routines at sub_CC1F, sub_D0CA, l_D4DA and sub_D59E.
sub_D32A:
  INC H
  LD A,$07
  AND H
  RET NZ
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; sub_D339
;
; Used by the routine at sub_D315.
sub_D339:
  LD A,D
  DEC D
  AND $07
  RET NZ
  LD A,E
  SUB $20
  LD E,A
  RET C
  LD A,D
  ADD A,$08
  LD D,A
  RET

; sub_D348
;
; Used by the routines at sub_BD61, sub_C849 and sub_CF2D.
sub_D348:
  ADD A,A
  CALL sub_D351
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET

; sub_D351
;
; Used by the routines at sub_AD3C, sub_B08A, l_B0AB, sub_B222, sub_B5F3,
; sub_B7F4, sub_B99F, sub_BA87, sub_BB09, sub_BBB9, sub_BC1C, sub_C820,
; sub_C849, sub_CAC1, sub_CBE0, sub_CC1F, sub_CCC6, sub_CE12, sub_CEFD,
; sub_CF2D, sub_D026, sub_D0CA, sub_D348 and l_D4DA.
sub_D351:
  ADD A,L
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  RET

; sub_D358
;
; Used by the routines at sub_AD62, sub_B0FA, l_B154, sub_B222, sub_B33E,
; sub_B7F4, sub_B99F, sub_BA87, sub_BC1C and sub_D5C4.
sub_D358:
  PUSH HL
  LD HL,$FD00
  LD A,(HL)
  AND $48
  ADD A,$38
  RLCA
  RLCA
  LD L,$03
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  LD L,$00
  LD A,(HL)
  AND $03
  LD L,A
  LD (sub_D358+$0019),A
  LD A,(HL)
  POP HL
  RET

; wait for a key or the fire button released then pressed
;
; Used by the routines at l_A69A, sub_A941, sub_ACD7, sub_AD57, sub_AE6B,
; sub_B41D and sub_C849.
WaitKey:
  CALL ReadControls
  OR A
  RET P
l_D381:
  CALL ReadControls
  OR A
  JR Z,l_D381
  JP M,l_D381

; Input from the redefinable keys (KeyTable) or the joystick the menu chose
; (Controls)
;
; Used by the routine at WaitKey.
ReadControls:
  LD HL,KeyTable
  LD C,$01
l_D38F:
  LD A,(HL)
  INC HL
  IN A,($FE)
  AND (HL)
  INC HL
  INC HL
  JR NZ,l_D399
  CCF
l_D399:
  RL C
  JR NC,l_D38F
  LD A,($D3E4)
  CP $02
  JR Z,l_D3AB
  CP $03
  JR Z,l_D3B2
  XOR A
  JR l_D3C7
l_D3AB:
  XOR A
  IN A,($1F)
  AND $1F
  JR l_D3C7
l_D3B2:
  LD A,$EF
  IN A,($FE)
  CPL
  AND $1F
  LD B,A
  XOR A
  SRL B
  RLA
  SRL B
  RLA
  SRL B
  RLA
  RLA
  RLA
  OR B
l_D3C7:
  OR C
  LD (Input),A
  RET

; the keys, eight of 3 bytes: the port high byte, the bit mask, the key code
; (shown by the redefine menu)
KeyTable:
  DEFB $F7,$01,$31
  DEFB $DF,$04,$49
  DEFB $F7,$10,$35
  DEFB $7F,$02,$82
  DEFB $FB,$01,$51
  DEFB $FD,$01,$41
  DEFB $DF,$02,$4F
  DEFB $DF,$01,$50
  DEFB $01

; sub_D3E5
;
; Used by the routines at sub_A720, sub_A941, sub_CC08 and l_D2A3.
sub_D3E5:
  LD L,A
  LD H,$00
  LD E,$20
  JR l_D407

; sub_D3EC
;
; Used by the routines at l_AD90, l_D2C1 and l_D2DF.
sub_D3EC:
  LD L,A
  LD H,$00
  LD E,$00
  JR l_D407

; sub_D3F3
;
; Used by the routine at l_AD90.
sub_D3F3:
  LD BC,$D8F0
  LD E,$20
  CALL sub_D413
  LD BC,$FC18
  CALL sub_D413

; sub_D401
;
; Used by the routines at sub_A81D and sub_CBE0.
sub_D401:
  LD BC,$FF9C
  CALL sub_D413

; l_D407
;
; Used by the routines at sub_D3E5 and sub_D3EC.
l_D407:
  LD BC,$FFF6
  CALL sub_D413
  LD A,L
  ADD A,$30
  JP sub_D427

; sub_D413
;
; Used by the routines at sub_D3F3, sub_D401 and l_D407.
sub_D413:
  XOR A
l_D414:
  ADD HL,BC
  INC A
  JR C,l_D414
  SBC HL,BC
  DEC A
  JR NZ,l_D424
  LD A,E
  CP $20
  JP Z,sub_D427
  XOR A
l_D424:
  INC E
  ADD A,$30

; sub_D427
;
; Used by the routines at sub_A81D, l_AD90, l_C430, sub_D2E3, l_D407 and
; sub_D413.
sub_D427:
  EXX
  CALL sub_D4B1
  EXX
  RET

; sub_D42D
;
; Used by the routines at sub_A720, sub_A81D, sub_A941, l_AB52, sub_AD62,
; sub_AE6B, l_C106, l_C120, l_C137, l_C151, sub_C1E3, l_C1FC, l_C21E, sub_C28D,
; sub_C336, l_C342, sub_C34A, sub_C40C, l_C424, sub_C427, l_C430, sub_C849,
; sub_CBE0, sub_CC08, sub_D0CA, sub_D1E5, sub_D293, l_D2A3, l_D2C1, l_D2D2,
; sub_D2F6 and l_D303.
sub_D42D:
  EXX
l_D42E:
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  OR A
  JR Z,l_D43A
  CALL sub_D43C
  JR l_D42E
l_D43A:
  EXX
  RET

; sub_D43C
;
; Used by the routine at sub_D42D.
sub_D43C:
  CP $01
  JR Z,l_D461
  CP $02
  JR Z,l_D457
  CP $03
  JR Z,sub_D470
  CP $04
  JR Z,l_D47C
  LD C,A
  LD A,($FD17)
  OR A
  LD A,C
  JR Z,sub_D4B1
  JP l_D4DA
l_D457:
  POP DE
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD ($FD13),A
  RET
l_D461:
  POP DE
  POP HL
  LD B,(HL)
  INC HL
  LD C,(HL)
  LD ($FD31),BC
  INC HL
  PUSH HL
  PUSH DE
  JP l_D493

; sub_D470
;
; Used by the routines at l_AD90, l_C3C4, l_D2A3, sub_D2E3 and sub_D43C.
sub_D470:
  LD BC,($FD31)
  INC B
  LD ($FD31),BC
  JP l_D493
; This entry point is used by the routine at sub_D43C.
l_D47C:
  POP DE
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD C,A
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD ($FD16),A
  LD A,C
  AND $0F
  LD ($FD17),A
  RET

; l_D493
;
; Used by the routines at sub_D43C and sub_D470.
l_D493:
  LD A,B
  AND $F8
  ADD A,$40
  LD H,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD L,A
  LD ($FD04),HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD ($FD14),HL
  RET

; sub_D4B1
;
; Used by the routines at sub_D427 and sub_D43C.
sub_D4B1:
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,data_5B00+$0B80
  ADD HL,DE
  LD DE,($FD04)
  PUSH DE
  LD B,$08
l_D4C2:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ l_D4C2
  POP DE
  INC DE
  LD ($FD04),DE
  LD HL,($FD14)
  LD A,($FD13)
  LD (HL),A
  INC HL
  LD ($FD14),HL
  RET

; l_D4DA
;
; Used by the routine at sub_D43C.
l_D4DA:
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,data_5B00+$0B80
  ADD HL,DE
  LD A,($FD17)
  CP $02
  JR NC,l_D502
  EX DE,HL
  LD HL,($FD04)
  LD C,$08
l_D4F1:
  LD A,($FD16)
  LD B,A
l_D4F5:
  LD A,(DE)
  LD (HL),A
  CALL sub_D32A
  DJNZ l_D4F5
  INC DE
  DEC C
  JR NZ,l_D4F1
  JR l_D532
l_D502:
  PUSH IX
  PUSH HL
  POP IX
  LD HL,($FD04)
  LD C,$08
l_D50C:
  LD A,(IX+$00)
  LD B,$08
l_D511:
  RLCA
  PUSH AF
  RL E
  RL D
  POP AF
  RL E
  RL D
  DJNZ l_D511
  LD A,($FD16)
  LD B,A
l_D522:
  LD (HL),D
  INC L
  LD (HL),E
  DEC L
  CALL sub_D32A
  DJNZ l_D522
  INC IX
  DEC C
  JR NZ,l_D50C
  POP IX
l_D532:
  LD HL,($FD04)
  LD A,($FD17)
  CALL sub_D351
  LD ($FD04),HL
  LD HL,($FD14)
  PUSH HL
  LD BC,($FD16)
  LD A,($FD13)
  LD E,A
l_D54A:
  PUSH HL
  PUSH BC
l_D54C:
  LD (HL),E
  INC HL
  DJNZ l_D54C
  POP BC
  POP HL
  LD A,L
  ADD A,$20
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  DEC C
  JR NZ,l_D54A
  POP HL
  LD A,B
  CALL sub_D351
  LD ($FD14),HL
  RET

; the interrupt handler of play, one a frame
PlayInterrupt:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,$FD34
  INC (HL)
  LD HL,data_D6A8+$0158
  LD C,$4D
  LD A,($FD1A)
  XOR $01
  LD ($FD1A),A
  JR Z,l_D582
  LD HL,data_D6A8+$0258
  LD C,$4E
l_D582:
  CALL sub_D59E
  LD A,($FD53)
  OR A
  JR Z,l_D598
  INC A
  CP $80
  JR NZ,l_D591
  XOR A
l_D591:
  LD ($FD53),A
  OR A
  CALL NZ,sub_D5C4
l_D598:
  POP HL
  POP DE
  POP BC
  POP AF

; the interrupt handler while the start-up runs
StartInterrupt:
  EI
  RET

; sub_D59E
;
; Used by the routine at PlayInterrupt.
sub_D59E:
  PUSH BC
  LD B,$10
  LD DE,$50C6
l_D5A4:
  PUSH BC
  PUSH DE
  LD BC,$0010
  LDIR
  POP DE
  EX DE,HL
  CALL sub_D32A
  EX DE,HL
  POP BC
  DJNZ l_D5A4
  POP BC
  LD HL,$5AC6
  CALL sub_D5BD
  LD L,$E6

; sub_D5BD
;
; Used by the routine at sub_D59E.
sub_D5BD:
  LD B,$10
l_D5BF:
  LD (HL),C
  INC HL
  DJNZ l_D5BF
  RET

; sub_D5C4
;
; Used by the routine at PlayInterrupt.
sub_D5C4:
  JP M,l_D5EC
  LD B,A
  INC A
  INC A
  LD HL,$01F4
  LD E,A
  LD D,$00
  LD C,$00
  XOR A
l_D5D3:
  INC C
  SBC HL,DE
  JR NC,l_D5D3
  LD HL,$0000
l_D5DB:
  PUSH BC
  LD A,(HL)
  INC HL
  AND $10
  OUT ($FE),A
l_D5E2:
  DJNZ l_D5E2
  POP BC
  DEC C
  JR NZ,l_D5DB
  XOR A
  OUT ($FE),A
  RET
l_D5EC:
  LD B,$1E
l_D5EE:
  CALL sub_D358
  AND $10
  OUT ($FE),A
  DJNZ l_D5EE
  RET

; sub_D5F8
;
; Used by the routine at sub_B024.
sub_D5F8:
  LD HL,data_D6A8+$0158
  LD DE,($FD1C)
  LD A,D
  ADD A,$DD
  LD D,A
  LD BC,$1010
l_D606:
  PUSH BC
  PUSH DE
l_D608:
  PUSH BC
  LD B,$08
l_D60B:
  LD A,(DE)
  INC DE
  AND $1F
  CP $0F
  CCF
  RL (HL)
  DJNZ l_D60B
  INC HL
  POP BC
  DJNZ l_D608
  POP DE
  POP BC
  INC D
  INC D
  DEC C
  JR NZ,l_D606
  LD HL,data_D6A8+$0158
  LD DE,data_D6A8+$0258
  LD BC,$0100
  LDIR
  LD IY,data_D6A8+$0358
  LD B,$30
l_D632:
  PUSH BC
  LD A,(IY+$01)
  OR A
  JR Z,l_D651
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  LD A,(IY+$0A)
  CP $02
  CALL NZ,sub_D65A
l_D651:
  LD DE,$0010
  ADD IY,DE
  POP BC
  DJNZ l_D632
  RET

; sub_D65A
;
; Used by the routines at sub_B036, sub_B0FA, l_B154, sub_CC7C and sub_D5F8.
sub_D65A:
  CALL sub_D67D
  LD C,A
  PUSH HL
  LD A,(HL)
  XOR C
  LD (HL),A
  RRC C
  JR NC,l_D667
  INC HL
l_D667:
  LD A,(HL)
  XOR C
  LD (HL),A
  POP HL
  LD A,L
  SUB $10
  LD L,A
  RLC C
  LD A,(HL)
  XOR C
  LD (HL),A
  RRC C
  JR NC,l_D679
  INC HL
l_D679:
  LD A,(HL)
  XOR C
  LD (HL),A
  RET

; sub_D67D
;
; Used by the routine at sub_D65A.
sub_D67D:
  LD DE,($FD1C)
  XOR A
  SBC HL,DE
  LD A,H
  OR A
  JR NZ,l_D6A6
  LD A,L
  CP $7F
  JR NC,l_D6A6
  LD A,$D8
  ADD A,B
  LD H,A
  LD A,L
  AND $07
  INC A
  LD B,A
  LD A,L
  RLCA
  AND $F0
  OR C
  RLCA
  RLCA
  RLCA
  RLCA
  LD L,A
  XOR A
  SCF
l_D6A2:
  RRA
  DJNZ l_D6A2
  RET
l_D6A6:
  POP HL
  RET

; data_D6A8
data_D6A8:
  DEFB $FF,$FF,$FF,$FC,$FF,$F0,$FF,$C0
  DEFB $FF,$00,$FC,$00,$F0,$00,$C0,$00
  DEFB $00,$03,$00,$0F,$00,$3F,$00,$FF
  DEFB $03,$FF,$0F,$FF,$3F,$FF,$FF,$FF
  DEFB $02,$02,$03,$03,$00,$00,$01,$01
  DEFB $04,$04,$04,$04,$05,$06,$07,$08
  DEFB $09,$09,$0A,$0A,$0B,$0C,$0D,$0E
  DEFB $0F,$0F,$0F,$0F,$10,$11,$12,$13
  DEFB $3A,$8E,$2C,$8F,$1E,$90,$B0,$90
  DEFB $72,$91,$72,$91,$F2,$91,$F2,$91
  DEFB $78,$92,$78,$92,$F8,$92,$F8,$92
  DEFB $9C,$9D,$34,$9E,$F6,$9E,$8E,$9F
  DEFB $72,$93,$72,$93,$0A,$94,$0A,$94
  DEFB $A8,$94,$A8,$94,$34,$95,$34,$95
  DEFB $C6,$95,$40,$96,$EA,$96,$76,$97
  DEFB $20,$98,$AC,$98,$14,$99,$16,$9A
  DEFB $18,$9B,$5A,$9C,$E2,$A0,$E4,$A1
  DEFB $E6,$A2,$28,$A4,$3A,$8E,$3A,$8E
  DEFB $3A,$8E,$3A,$8E,$50,$A0,$50,$A0
  DEFB $80,$69,$24,$6A,$FE,$6A,$A8,$6B
  DEFB $8A,$6C,$40,$6D,$32,$6E,$E2,$6E
  DEFB $CC,$6F,$58,$70,$12,$71,$BC,$71
  DEFB $9E,$72,$54,$73,$46,$74,$FC,$74
  DEFB $EE,$75,$86,$76,$50,$77,$F4,$77
  DEFB $CE,$78,$78,$79,$5A,$7A,$04,$7B
  DEFB $E6,$7B,$96,$7C,$80,$7D,$30,$7E
  DEFB $1A,$7F,$B8,$7F,$8A,$80,$3A,$81
  DEFB $24,$82,$B6,$82,$48,$83,$DA,$83
  DEFB $6C,$84,$FE,$84,$90,$85,$22,$86
  DEFB $B4,$86,$F8,$86,$52,$87,$96,$87
  DEFB $F0,$87,$58,$88,$E2,$88,$24,$89
  DEFB $66,$89,$B6,$89,$06,$8A,$8C,$8A
  DEFB $3E,$8B,$C4,$8B,$76,$8C,$DE,$8C
  DEFB $46,$8D,$C0,$8D,$0B,$07,$08,$06
  DEFB $06,$07,$07,$07,$00,$00,$02,$02
  DEFB $02,$02,$03,$03,$06,$06,$06,$06
  DEFB $00,$00,$00,$07,$0F,$07,$0F,$00
  DEFB $00,$63,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
