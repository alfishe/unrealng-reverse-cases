; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The panel: the weapon slots, their bars and the gauges
;
; The weapon table $68AB has nine 6-byte records (one per weapon kind: slot marks, bar position, colour, count); the
; four loaded slots are $8368, 6 bytes each, with the ammunition at +5 ($836D for slot 1, death: 79 at frame 7939, 69
; at 9939).
; --------------------------------------------------------------------------------------------------------------------

; A = 4 then DrawWeaponBars
;
; Witness: L1 1 (play).
DrawSlotBarsLow:
  LD A,$04
  JR DrawWeaponBars

; A = 0 then DrawWeaponBars
;
; Witness: L1 3 (play).
DrawSlotBars:
  XOR A

; Redraw each weapon record of $68AB whose value changed: its bar through
; DrawBar
;
; Witness: L1 4 (play).
DrawWeaponBars:
  LD HL,GaugeRecords
  LD (l_72FF+$000A),A
l_72FF:
  LD A,(HL)
  CP $FF
  RET Z
  INC HL
  AND A
  JP M,l_7321
  JR l_730E
  LD C,(HL)
  CP C
  JR Z,l_7321
l_730E:
  LD (HL),A
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  INC HL
  INC HL
  SRL A
  SRL A
  PUSH HL
  CALL DrawBar
  POP HL
  JR l_72FF
l_7321:
  LD BC,$0005
  ADD HL,BC
  JR l_72FF

; Bank 6 UpdatePanelBars $D58C (heading strip, bearing, speed, fuel), then
; UpdateAmmoBars
;
; Witness: L1 3601 (death, m2erbe, missions, play, play2).
UpdateSlotBars:
  CALL SaveBank
  CALL PageBank6
  CALL UpdatePanelBars
  CALL RestoreBank
  JP UpdateAmmoBars

; For the four slots of $8368: a bar for each ammunition count that changed
; (records $68C9)
;
; Witness: L1 3628 (death, m2erbe, missions, play, play2).
UpdateAmmoBars:
  LD A,$04
  LD (l_737A+$0001),A
  XOR A
  JR l_7343

; data_733E
data_733E:
  DEFB $3E,$04,$32,$5D,$73

; l_7343
;
; Used by the routine at UpdateAmmoBars.
l_7343:
  LD HL,WeaponSlots
  LD DE,$0006
  EXX
  LD HL,SlotGauges
; This entry point is used by the routine at l_7362.
l_734D:
  EXX
  LD A,(HL)
  AND A
  ADD HL,DE
  JR NZ,l_7356
  EXX
  JR l_7376
l_7356:
  EXX
  LD A,(HL)
  CP $FF
  RET Z
  INC HL
  JR l_7362

; data_735E
data_735E:
  DEFB $4E,$B9,$28,$14

; l_7362
;
; Used by the routine at l_7343.
l_7362:
  LD (HL),A
  INC HL
  INC HL
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  PUSH HL
  SRL A
  SRL A
  CALL DrawBar
  EXX
  POP HL
  JR l_737A
; This entry point is used by the routine at l_7343.
l_7376:
  LD BC,$0006
  ADD HL,BC
l_737A:
  LD A,$00
  DEC A
  RET Z
  LD (l_737A+$0001),A
  JR l_734D

; The nine weapon icons of the damage board ($834A records) with their frames
;
; Witness: L1 1 (play).
DrawDamagePanel:
  LD HL,GaugeRecords+$0002
  EXX
  LD HL,DamageBoardRecords
  EXX
  LD B,$09
  LD DE,$0006
l_7390:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,(HL)
  INC HL
  LD A,(HL)
  DEC C
  DEC C
  DEC C
  DEC C
  INC HL
  EX AF,AF'
  EXX
  LD A,(HL)
  AND A
  LD BC,$0006
  ADD HL,BC
  JR NZ,l_73A7
  LD A,$13
l_73A7:
  PUSH HL
  CALL DrawIcon
  LD A,(IconFrame+$0006)
  CALL IconFrame
  POP HL
  EXX
  POP BC
  POP DE
  POP HL
  ADD HL,DE
  DJNZ l_7390
  RET

; The icons of the four loaded slots ($8368 records, $68CD) with their frames
;
; Witness: L1 27 (death, m2erbe, missions, play, play2).
DrawSlotIcons:
  LD HL,SlotGauges+$0004
  EXX
  LD HL,WeaponSlots
  EXX
  LD B,$04
  LD DE,$0006
l_73C7:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,(HL)
  INC HL
  LD A,(HL)
  INC C
  INC HL
  EX AF,AF'
  EXX
  LD A,(HL)
  AND A
  LD BC,$0006
  ADD HL,BC
  JR NZ,l_73DB
  LD A,$13
l_73DB:
  PUSH HL
  CALL DrawIcon
  POP HL
  EXX
  POP BC
  POP DE
  POP HL
  ADD HL,DE
  DJNZ l_73C7
  RET

; Draw weapon icon A (1-19) from the icon table $75CA through CopyGraphic, 3 x
; 24
;
; Witness: L1 117 (death, m2erbe, missions, play, play2).
DrawIcon:
  DEC A
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,IconTable
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,$03
  LD D,$03
  LD C,$18
  EX AF,AF'
  EXX
  LD (IconFrame+$0001),BC
  LD (IconFrame+$0006),A
  JP CopyGraphic

; The attribute frame of an icon at column E, pixel line A
;
; Witness: L1 9 (play).
IconFrame:
  LD DE,$0000
  LD H,$00
  LD A,$00
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD BC,$5800
  ADD HL,BC
  LD D,$00
  ADD HL,DE
  LD BC,$0004
  ADD HL,BC
  LD C,$20
  LD (HL),$44
  ADD HL,BC
  LD (HL),$46
  ADD HL,BC
  LD (HL),$42
  SRL A
  SRL A
  SRL A
  LD L,A
  LD B,$47
  LD C,$03
  LD A,C
  EX AF,AF'
  JP AttrBoxRC

; A bar of A pixels on line E, $7E pattern, 32 wide
;
; Witness: L1 3794 (death, missions, play, play2).
DrawBarWide:
  EX AF,AF'
  XOR A
  LD (BarLines+$0016),A
  LD (BarLines+$0019),A
  LD (l_747E+$0019),A
  LD A,$7E
  LD (l_747E+$0016),A
  LD A,$20
  LD (BarLines+$0012),A
  JR BarLines

; A bar of A pixels on line E, $F8 pattern, 24 wide
;
; Witness: L1 5389 (death, m2erbe, missions, play, play2).
DrawBar:
  EX AF,AF'
  XOR A
  LD (BarLines+$0016),A
  LD (BarLines+$0019),A
  LD (l_747E+$0019),A
  LD A,$F8
  LD (l_747E+$0016),A
  LD A,$18
  LD (BarLines+$0012),A

; The bar's pixel lines through the line table $6500, $AA / $55 dither
;
; Witness: L1 9183 (death, m2erbe, missions, play, play2).
BarLines:
  EX AF,AF'
  LD D,$00
  LD B,D
  SLA E
  RL D
  LD HL,ScreenRowTable
  ADD HL,DE
  EXX
  LD (l_747E+$000F),A
  LD B,A
  LD A,$0C
  SUB B
  LD B,A
  LD A,$AA
  EX AF,AF'
  LD A,$55
l_747E:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  LD (HL),A
  EX DE,HL
  EXX
  EX AF,AF'
  DJNZ l_747E
  EX AF,AF'
  LD A,$00
  AND A
  RET Z
  LD B,A
  AND $01
  LD A,$FD
  EX AF,AF'
  LD A,$00
  EX AF,AF'
  JR Z,l_749C
  EX AF,AF'
l_749C:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  LD (HL),A
  EX DE,HL
  EX AF,AF'
  EXX
  DJNZ l_749C
  RET

; Page bank 7 and run its picture routine $FE95 with DE (a picture), then the
; bank back
;
; The panels and frames of the views are bank 7's pictures (DE = `$DD75` play,
; `$F9CD` map, `$D325` status, `$C000` Dragonfly). Clears `$83BF` (the play
; flag of the interrupt) and resets bank 6's `$D283` = `$C000`. Witness: L1 122
; (c1, death, m2erbe, menu, missions, play, play2, search).
DrawBank7Picture:
  DI
  EXX
  LD A,(SaveBank+$0002)
  PUSH AF
  CALL PageBank7
  EXX
  CALL UnpackPicture
  XOR A
  LD (PointerShown+$0001),A
  CALL PageBank6
  LD HL,l_BFEB+$0015
  LD (SkeetFire+$0037),HL
  EI
  POP AF
  JP PageBankA

; A = $FF then Bank3Fill
;
; Witness: L1 15 (menu, missions, search).
Bank3FillFF:
  LD A,$FF
  JR Bank3Fill

; A = $5F then Bank3Fill
;
; Witness: L1 15 (menu, missions, search).
Bank3Fill5F:
  LD A,$5F

; Save the bank, call bank 3 $CFCD with A, restore
;
; Witness: L1 30 (menu, missions, search).
Bank3Fill:
  PUSH AF
  CALL SaveBank
  CALL PageBank3
  POP AF
  CALL SetClipWidth
  JP RestoreBank

; Page bank 0, call $CEA4, page bank 6
;
; Witness: known only from the code.
Bank0Call:
  CALL PageBank0
  CALL BinocularsOff
  JP PageBank6

; The menu screens: the current pointer, then pairs of words (draw routine,
; zone table)
;
; Read and moved by `SetScreen` `$7060`.
ScreenList:
  DEFB $EC,$74
  DEFB $09,$C4
  DEFB $E9,$C4
  DEFB $04,$75
  DEFB $F8,$74
  DEFB $F2,$74
  DEFB $F4,$F8
  DEFB $00,$00
  DEFB $E8,$74
  DEFB $78,$C5
  DEFB $29,$C7
  DEFB $E8,$74
  DEFB $FC,$C4
  DEFB $00,$00
  DEFB $6A,$75
  DEFB $90,$C7
  DEFB $51,$C8
  DEFB $14,$75
  DEFB $0E,$75
  DEFB $6A,$75
  DEFB $8A,$C9
  DEFB $10,$CA
  DEFB $04,$75
  DEFB $8B,$CA
  DEFB $C4,$CB
  DEFB $1A,$75
  DEFB $4B,$69
  DEFB $00,$00
  DEFB $28,$75
  DEFB $52,$75
  DEFB $5E,$75
  DEFB $64,$75
  DEFB $E8,$74
  DEFB $C7,$6B
  DEFB $00,$00
  DEFB $1A,$75
  DEFB $36,$75
  DEFB $5E,$75
  DEFB $64,$75
  DEFB $44,$75
  DEFB $DE,$6B
  DEFB $00,$00
  DEFB $1A,$75
  DEFB $36,$75
  DEFB $5E,$75
  DEFB $64,$75
  DEFB $44,$75
  DEFB $44,$6C
  DEFB $00,$00
  DEFB $1A,$75
  DEFB $36,$75
  DEFB $5E,$75
  DEFB $64,$75
  DEFB $44,$75
  DEFB $93,$6C
  DEFB $00,$00
  DEFB $1A,$75
  DEFB $00,$00
  DEFB $5E,$75
  DEFB $64,$75
  DEFB $1E,$CD
  DEFB $70,$CD
  DEFB $6A,$75
  DEFB $84,$CD
  DEFB $70,$CD
  DEFB $E8,$74
  DEFB $BF,$CD
  DEFB $DC,$C4
  DEFB $FE,$74
  DEFB $04,$75
  DEFB $B9,$6A
  DEFB $00,$00
  DEFB $1A,$75
AwolState:
  DEFB $00,$00            ; the AWOL state: 0 inside, 1 beyond the extent
  DEFB $FF,$FF            ; (GOING AWOL), 2 more than 4 beyond (desertion);
                          ; SetAwolState $D4E9

; Screen 1 unless the current mission ($757D) is $FF or not completed
;
; `LD A,n`: n (`$757D`) is the mission the tape gave (`$8528`: the header's
; digit - "1"). Witness: L1 10 (play).
ScreenOfMission:
  LD A,$00
  CP $FF
  RET Z
  CALL MissionDone
  RET NZ
  JP ScreenTwo

; If a mission is loaded: bank 6 $CBF4, $D27C, $CA23, then screen 0
;
; Witness: known only from the code (entered by a jump from `$75B8`).
MissionLoaded:
  LD A,(ScreenOfMission+$0001)
  CP $FF
  RET Z
  CALL ShowWaitPointer
  CALL DrawPointer
  CALL CopyMissionTextB6
  JP ScreenZero

; Load the mission the tape holds; mission 10 only when the nine completion
; flags are set
;
; If the current mission (C) is 9 (Grand Finale), the nine bytes `$6799-$67A1`
; are ANDed: if any is 0 the mission is refused (`RET Z` back into the
; catalogue's zone loop; recording m10: the catalogue stays on screen,
; 4972-7972). Otherwise `LoadMission` `$84C1`. Witness: L1 18 (m10, m2erbe,
; m2ocean, missions).
LoadMissionIfAllowed:
  CALL MissionDone
  RET NZ
  LD A,$09
  CP C
  JR NZ,l_75AF
  LD A,$FF
  LD HL,MissionsDone
  LD B,$09
l_75AA:
  AND (HL)
  INC HL
  DJNZ l_75AA
  RET Z
l_75AF:
  CALL LoadMission
  EX AF,AF'
  CALL PageBank6
  EX AF,AF'
  RET NC
  JP MissionLoaded

; A = the completion flag of the current mission ($6799 + n): NZ when done
;
; Witness: L1 28 (m10, m2erbe, m2ocean, missions, play).
MissionDone:
  LD HL,MissionsDone
  LD A,(ScreenOfMission+$0001)
  AND A
  RET M
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  AND A
  RET

; The addresses of the 19 weapon icons (bank 6), read by DrawIcon
;
; 19 words at `$75CA-$75EF`: icon n at word n-1.
IconTable:
  DEFW $F24C,$F1BC
  DEFW $F09C,$F444
  DEFW $F204,$F174
  DEFW $F2DC,$F36C
  DEFW $F294,$F12C
  DEFW $F3FC,$F3B4
  DEFW $F324,$F054
  DEFW $F0E4,$EF34
  DEFW $EFC4,$F00C
  DEFW $F59C

; The 24 object records, 60 bytes each: 0 the player, 1-20 the mission's
; objects, 21 the Helicarrier, 22 projectiles (23 never allocated)
;
; +0 list index, +1 type, +2 state (bit 7 present, 6 wreck, 5 drawn, 2 on the
; radar), +3 handler flags, +4 colour, +5 height, +7 speed, +8 wreck model,
; +`$0B` box half-sizes, +`$13` hit points, +`$14` damage, +`$16` radius,
; +`$18` step handler, +`$1A` collision handler, +`$1C` model, +`$1E` score,
; +`$22` heading, +`$23` X (24 bits), +`$26` Y (24 bits), +`$2A` pitch, +`$2B`
; view position, +`$31` timer, +`$32` AI state, +`$3B` collision slot. +1 is
; the type, +2 to +`$1F` come from the type's template, +`$20` is the serial.
; Read by RunObjectHandlers `$C026`, written by the world code (frag of bank 2
; / 0, docs 05-07).
;
; Witness: every play build reads and writes `$75F0-$7B8F`.
ObjectTable:
  DEFB $FF,$00,$80,$87,$00
PlayerHeight:
  DEFB $20,$00
PlayerSpeed:
  DEFB $00,$00,$00,$00,$A0,$00,$60,$00,$A0,$00,$01,$40,$00,$00,$20,$87,$00
PlayerHandler:
  DEFB $C7,$A8,$A5,$CA,$00,$00,$00,$00,$00,$00
PlayerHeading:
  DEFB $C0
PlayerX:
  DEFB $D8,$2E,$00
PlayerY:
  DEFB $00,$F0,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
HelicarrierRecord:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
StoreTypes:
  DEFB $00,$00,$00,$00,$00,$00,$00 ; the store-type table base: 8 bytes a type,
                                   ; types 1-13 from $7B91 (words 0 K, 1 J, 2
                                   ; fire, 3 select)

; The per-store-type table and play variables, then the interrupt's stack (top
; $7C49) and the fuel word $7C57
;
; `$7B89` + 8 x type (type 1-13, from `$7B91`): the aim, fire and select
; routines of each weapon store; `$7BF9` the failure reason text pointer; the
; interrupt handler's stack below `$7C49`; `$7C57` the fuel (reset to `$3F00`
; by bank 6 `$CC1B`).
PlayWorkspace:
  DEFB $00,$FE,$B8,$09,$B9,$3E,$C1,$1E,$C1,$B0,$6B,$B0,$6B,$4D,$C1,$2C
  DEFB $C1,$B9,$B8,$C4,$B8,$9F,$B5,$CC,$B8,$B0,$6B,$B0,$6B,$68,$B5,$10
  DEFB $C5,$FE,$B8,$09,$B9,$0D,$C2,$1E,$C1,$B0,$6B,$B0,$6B,$1D,$C2,$2C
  DEFB $C1,$B0,$6B,$B0,$6B,$BC,$C2,$2C,$C1,$B0,$6B,$B0,$6B,$3F,$CF,$30
  DEFB $CF,$F4,$CF,$E9,$CF,$05,$D0,$26,$CF,$F5,$D0,$04,$D1,$B0,$6B,$5E
  DEFB $D4,$B0,$6B,$B0,$6B,$4C,$D2,$4B,$D2,$E4,$D2,$0B,$D3,$19,$D3,$6A
  DEFB $D4,$F7,$D2,$0B,$D3,$1F,$D3,$4E,$D3
FailReason:
  DEFB $00,$00,$68,$67,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$02,$B0,$08
  DEFB $0D,$49,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20,$20,$FF,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $80,$40,$20,$10,$08,$04,$02,$01,$14,$00,$14,$00,$00,$00
Fuel:
  DEFB $00,$3F
