; --------------------------------------------------------------------------------------------------------------------
; tape.asm: The tape: one block through the game's own LD-BYTES, the bank to stay in
; --------------------------------------------------------------------------------------------------------------------

; Load a tape block to IX, length DE, flag A (carry: load) with the sound and
; the menu's flag set aside
;
; Under `DI`, with bank 6 `$D27C` (the pointer's save) and `$D283` = `$C010`,
; calls `LdBytes` `$8617`; restores `$D283` = `$C000` and the border, carry =
; loaded. Witness: L1 68 (c1, m10, m2erbe, m2ocean, menu, missions, search).
LoadBlock:
  DI
  CALL SaveBank
  PUSH IX
  PUSH DE
  PUSH AF
  CALL PageBank6
  LD HL,l_BFEB+$0025
  LD (FireDecoy+$0037),HL
  CALL DrawPointer
  CALL RestoreBank
  POP AF
  POP DE
  POP IX
  CALL LdBytes
  PUSH AF
  CALL SaveBank
  CALL PageBank6
  LD HL,l_BFEB+$0015
  LD (FireDecoy+$0037),HL
  CALL RestoreBank
  CALL BorderBlack
  POP AF
  EI
  RET

  ORG $8617

; The game's copy of the ROM's LD-BYTES ($0556): IX, DE, A, carry; border
; stripes; NC on an error
;
; The timings are the ROM's; the border colours of the stripes come from C. A
; block shorter than DE ends in a time-out of the edge reader (`LdEdge2`
; `$869F`), `RET NC`: Ocean's mission 2 header asks for 6406 bytes, its block
; holds 6384 (src/tape/side2.txt), so `LoadMissionBlock` retries for ever
; (m2ocean). Witness: L1 68 (c1, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
LdBytes:
  INC D
  EX AF,AF'
  DEC D
  LD A,$0F
  OUT ($FE),A
  IN A,($FE)
  RRA
  AND $20
  OR $02
  LD C,A
  CP A
l_8627:
  RET NZ
l_8628:
  CALL LdEdge1
  JR NC,l_8627
  LD HL,$0415
l_8630:
  DJNZ l_8630
  DEC HL
  LD A,H
  OR L
  JR NZ,l_8630
  CALL LdEdge2
  JR NC,l_8627
l_863C:
  LD B,$9C
  CALL LdEdge2
  JR NC,l_8627
  LD A,$C6
  CP B
  JR NC,l_8628
  INC H
  JR NZ,l_863C
l_864B:
  LD B,$C9
  CALL LdEdge1
  JR NC,l_8627
  LD A,B
  CP $D4
  JR NC,l_864B
  CALL LdEdge1
  RET NC
  LD A,C
  XOR $03
  LD C,A
  LD H,$00
  LD B,$B0
  JR l_8684
l_8665:
  EX AF,AF'
  JR NZ,l_866F
  JR NC,l_8679
  LD (IX+$00),L
  JR l_867E
l_866F:
  RL C
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR l_8680
l_8679:
  LD A,(IX+$00)
  XOR L
  RET NZ
l_867E:
  INC IX
l_8680:
  DEC DE
  EX AF,AF'
  LD B,$B2
l_8684:
  LD L,$01
l_8686:
  CALL LdEdge2
  RET NC
  LD A,$CB
  CP B
  RL L
  LD B,$B0
  JP NC,l_8686
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,l_8665
  LD A,H
  CP $01
  RET

; Two edges (the ROM's LD-EDGE-2)
;
; Witness: L1 1682113 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
LdEdge2:
  CALL LdEdge1
  RET NC

; One edge (the ROM's LD-EDGE-1), SPACE breaks
;
; Witness: L1 3507210 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
LdEdge1:
  LD A,$16
l_86A5:
  DEC A
  JR NZ,l_86A5
  AND A
l_86A9:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC
  XOR C
  AND $20
  JR Z,l_86A9
  LD A,C
  CPL
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET

; The game's copy of the ROM's SA-BYTES ($04C2): no recording runs it
;
; Witness: known only from the code (no caller found).
SaBytes:
  LD HL,$1F80
  BIT 7,A
  JR Z,l_86CB
  LD HL,$0C98
l_86CB:
  EX AF,AF'
  INC DE
  DEC IX
  LD A,$02
  LD B,A
l_86D2:
  DJNZ l_86D2
  OUT ($FE),A
  XOR $0F
  LD B,$A4
  DEC L
  JR NZ,l_86D2
  DEC B
  DEC H
  JP P,l_86D2
  LD B,$2F
l_86E4:
  DJNZ l_86E4
  OUT ($FE),A
  LD A,$0D
  LD B,$37
l_86EC:
  DJNZ l_86EC
  OUT ($FE),A
  LD BC,$3B0E
  EX AF,AF'
  LD L,A
  JP l_8701
l_86F8:
  LD A,D
  OR E
  JR Z,l_8708
  LD L,(IX+$00)
l_86FF:
  LD A,H
  XOR L
l_8701:
  LD H,A
  LD A,$01
  SCF
  JP l_871F
l_8708:
  LD L,H
  JR l_86FF
l_870B:
  LD A,C
  BIT 7,B
l_870E:
  DJNZ l_870E
  JR NC,l_8716
  LD B,$42
l_8714:
  DJNZ l_8714
l_8716:
  OUT ($FE),A
  LD B,$3E
  JR NZ,l_870B
  DEC B
  XOR A
  INC A
l_871F:
  RL L
  JP NZ,l_870E
  DEC DE
  INC IX
  LD B,$31
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC
  LD A,D
  INC A
  JP NZ,l_86F8
  LD B,$3B
l_8736:
  DJNZ l_8736
  RET

; Bytes after SaBytes up to the message timer: never read
SaveLeftover:
  DEFB $00,$F7,$67,$20,$20,$20,$01,$28,$A6,$66,$FF,$02,$05,$44,$05,$00
  DEFB $04,$94,$98,$88,$88,$98,$8C,$8C,$98,$90,$90,$98,$94,$0C,$04,$00
  DEFB $07,$03,$04,$94,$98,$88,$01,$07,$03,$05,$88,$98,$8C,$02,$07,$03
  DEFB $04,$8C,$98,$90,$03,$07,$03,$05,$90,$98,$94,$FF,$00,$F7,$67,$20
  DEFB $0E,$0E,$01,$23,$A8,$63,$F8,$67,$29,$64,$FF,$02,$06,$44,$05,$20
  DEFB $02,$98,$8C,$94,$90,$8C,$88,$0A,$20,$A9,$87,$D5,$87,$0C,$01,$21
  DEFB $07,$03,$01,$90,$8C,$9C,$14,$01,$21,$07,$03,$01,$9C,$8C,$90,$09
  DEFB $0A,$20,$C2,$87,$C1,$87,$0C,$01,$20,$07,$03,$03,$98,$8C,$94,$14
  DEFB $01,$20,$07,$03,$03,$94,$8C,$98,$09,$0C,$01,$21,$07,$03,$01,$9C
  DEFB $8C,$88,$14,$01,$21,$07,$03,$01,$88,$8C,$9C,$09,$FF
