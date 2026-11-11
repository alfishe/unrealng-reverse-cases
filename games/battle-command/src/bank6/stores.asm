; --------------------------------------------------------------------------------------------------------------------
; stores.asm: The stores screen: the weapons catalogue, the four launcher slots, the payload, the turning model
;
; StoresScreen $CA8B is screen node $7514 (zones StoresZones $CBC4). It unpacks the bank 7 picture PicStores ($C713 of
; bank 7), shows one of the 13 weapons of WeaponRecords $C373 at a time (its icon, its description and its 3D model,
; which turns in a 3D window drawn into the back buffer and blitted by BlitStoresView $D0A0), and lets the player fit
; it into one of four slots ($8368, four 6-byte records) or take one out. The total weight (the operand $C11B) may not
; pass 1000 kg, and a weapon may be fitted only as many times as its record allows.
;
; When the player leaves the screen, StoresToGauges $CC1B turns the slots into the panel's gauges and the screen list
; goes on to StartMission $694B (link 0 of the node).
; --------------------------------------------------------------------------------------------------------------------

; Print the payload's weight in kg on the payload line
;
; NumberToDigits `$C126` with C = `:` (the space of SmallFont `$7C59`) for the
; leading zeros into `$D9AB`, then PrintString `$6FB3` of PayloadText `$D9A8`.
; Witness: L1 24 (c1, death, m2erbe, missions, play, play2).
PrintPayloadWeight:
  LD HL,PaddedDigits
  LD C,$3A
  EXX
PayloadWeightOp:
  LD HL,$0000             ; LD HL,n: n ($C11B) the payload's total weight in kg
  CALL NumberToDigits
  LD HL,PayloadText
  JP $6FB3

  ORG $C165

; Zone of the slot at the top right: C = $24 (slot record $836E)
;
; Called through PointerZones `$6D42` (StoresZones). Witness: L1 3 (play,
; play2).
SlotZoneB:
  LD C,$24
  JR FitOrRemoveWeapon

; Zone of the slot at the top left: C = $1E (slot record $8368)
;
; Witness: L1 15 (c1, death, m2erbe, missions, play, play2).
SlotZoneA:
  LD C,$1E
  JR FitOrRemoveWeapon

; Zone of the slot at the bottom left: C = $2A (slot record $8374)
;
; Witness: L1 3 (play, play2).
SlotZoneC:
  LD C,$2A
  JR FitOrRemoveWeapon

; Zone of the slot at the bottom right: C = $30 (slot record $837A)
;
; Falls into FitOrRemoveWeapon. Witness: L1 3 (play, play2).
SlotZoneD:
  LD C,$30

; Fit the shown weapon into slot $834A+C, or take out the weapon that is in it
;
; Three POKEs of the release's .pok patch it (bank 6, the stores screen): Ammo
; Number Is Not Exceeded 1 at `$C1AE` (`JP Z,$C235` becomes `LD BC,nn`),
; Infinite Payload Weight 0 at `$C1B9` (the `ADD HL,BC` of the weight becomes
; NOP), No Weight Limit 58 at `$C1C6` (`JP NC,$C23A` becomes `LD A,(nn)`).
;
; Input: C the slot's offset from `$834A`. A slot record is the weapon's type,
; its weight (word), the icon's column and line, its ammunition. An empty slot:
; the weapon's count in the slots is compared with its maximum (record +2;
; equal: MaxNumberText `$D990`), the new total with 1001 kg
; (PayloadExceededText `$D963`); when both pass, the slot gets the type, weight
; and ammunition, DrawSlotIcon `$C263` draws the icon, and PrintPayloadWeight
; the new total. A full slot: RemoveWeapon clears it, subtracts its weight and
; blanks the icon (ClearSlotIcon `$C25C`).
;
; Around every change the interrupt's pointer job is off (`$83BF` = 0) and the
; pointer is put back (RestorePointerBackground `$D251`, SavePointerBackground
; `$D0CA`). An error message stays for 60 frames (StoresMessageTimer `$C2C0`).
; Witness: L1 24 (c1, death, m2erbe, missions, play, play2).
FitOrRemoveWeapon:
  LD HL,$834A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  AND A
  JP NZ,RemoveWeapon
  PUSH HL
  EXX
  XOR A
  LD ($83BF),A
  CALL RestorePointerBackground
  LD HL,(CurrentWeapon)
  LD A,(HL)
  LD (SlotTypeOp+$0001),A
  INC HL
  EXX
  LD HL,$8368
  LD DE,$0006
  LD B,$04
  LD C,$00
CountSameType:
  LD A,(HL)
SlotTypeOp:
  CP $00                  ; CP n: n ($C19C) the shown weapon's type
  JR NZ,CountNextSlot
  INC C
CountNextSlot:
  ADD HL,DE
  DJNZ CountSameType
  EXX
  LD A,(HL)
  INC HL
  LD (SlotAmmoOp+$0001),A
  EXX
  LD A,C
  EXX
  LD C,(HL)
  CP C
  JP Z,MaxNumberExceeded
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  EX DE,HL
  LD HL,(PayloadWeightOp+$0001)
  ADD HL,BC
  LD (SlotWeightOp+$0001),BC
  PUSH HL
  LD BC,$03E9
  AND A
  SBC HL,BC
  POP BC
  JP NC,PayloadExceeded
  LD (PayloadWeightOp+$0001),BC
  EX DE,HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  EXX
SlotWeightOp:
  LD BC,$0000             ; LD BC,n: n ($C1D5) the shown weapon's weight
  POP HL
  LD A,(SlotTypeOp+$0001)
  LD (HL),A
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  INC HL
  EX AF,AF'
SlotAmmoOp:
  LD A,$00                ; LD A,n: n ($C1E7) the shown weapon's ammunition
  LD (HL),A
  EX AF,AF'
  EXX
  LD C,$14
  LD D,$03
  EXX
  CALL DrawSlotIcon
  CALL SavePointerBackground
  CALL PrintPayloadWeight
  LD A,$FF
  LD ($83BF),A
  RET
RemoveWeapon:
  XOR A
  LD ($83BF),A
  PUSH HL
  CALL RestorePointerBackground
  POP HL
  XOR A
  LD (HL),A
  INC HL
  LD C,(HL)
  LD (HL),A
  INC HL
  LD B,(HL)
  LD (HL),A
  INC HL
  AND A
  EX DE,HL
  LD HL,(PayloadWeightOp+$0001)
  SBC HL,BC
  LD (PayloadWeightOp+$0001),HL
  EX DE,HL
  EX AF,AF'
  LD C,(HL)
  INC HL
  LD A,(HL)
  LD B,A
  EXX
  LD D,$03
  LD E,$18
  CALL ClearSlotIcon
  CALL SavePointerBackground
  CALL PrintPayloadWeight
  LD A,$FF
  LD ($83BF),A
  RET
MaxNumberExceeded:
  LD HL,MaxNumberText
  JR ShowStoresMessage
PayloadExceeded:
  LD HL,PayloadExceededText
ShowStoresMessage:
  PUSH HL
  LD HL,StoresMessageBox
  CALL $6CFB
  POP HL
  CALL $6FB3
  POP BC
  CALL SavePointerBackground
  LD A,$FF
  LD ($83BF),A
  LD A,$3C
  LD (StoresMessageTimer+$0001),A
  RET

; The attribute box of the error message line
;
; Read by FitOrRemoveWeapon at `$C23E`.
StoresMessageBox:
  DEFB $F9,$03,$11,$0E,$12

; Draw a blank icon (the back buffer's $92C1) into the slot at column C', line
; A
;
; Falls into DrawSlotIcon with HL' = `$92C1`.
ClearSlotIcon:
  EXX
  PUSH BC
  LD HL,$92C1
  EXX
  POP BC

; Draw the 3 x 24 icon at HL' into a slot: column C', pixel line A
;
; The line address table `$6500`. The first 8 lines are copied two bytes wide
; one column to the right, the next 16 three bytes wide. Witness: L1 24 (c1,
; death, m2erbe, missions, play, play2).
DrawSlotIcon:
  EXX
  INC HL
  EXX
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,$6500
  ADD HL,DE
  LD A,$08
  LD B,$00
  INC C
SlotIconTop:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  PUSH DE
  EXX
  POP DE
  LD BC,$0002
  LDIR
  INC HL
  EXX
  DEC A
  JR NZ,SlotIconTop
  EXX
  DEC HL
  LD A,$10
  EXX
  DEC C
SlotIconBottom:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  PUSH DE
  EXX
  POP DE
  LD BC,$0003
  LDIR
  EXX
  DEC A
  JR NZ,SlotIconBottom
  RET

; A RET: the slot clearing that follows is switched off
;
; Called by StoresScreen `$CACE`. The first byte is `RET`, so ResetStoresBody
; never runs; ClearSlots `$CC01` does the work instead. Witness: L1 15 (c1,
; death, m2erbe, missions, play, play2).
ResetStores:
  RET

; Clear the 9 records at $834A, the payload weight and the hook $A9B9
;
; Known only from the code: behind the `RET` of ResetStores. Clears the first
; three bytes of nine 6-byte records from `$834A`, the weight `$C11B` = 0,
; `$A9B9` = `$6BB0` (NoAction).
ResetStoresBody:
  LD HL,$834A
  LD DE,$0004
  LD B,$09
  XOR A
ResetStoresLoop:
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  ADD HL,DE
  DJNZ ResetStoresLoop
  LD HL,$0000
  LD (PayloadWeightOp+$0001),HL
  LD HL,$6BB0
  LD ($A9B9),HL
  RET

; Count down the error message; at 0 clear the message line and print the
; payload again
;
; Called every frame by StoresScreen. The counter is the operand `$C2C1` of the
; first instruction (60 after a message). At 0: ScreenRowFill `$6D22`, the box
; PayloadLineBox, PayloadLineText `$D936`, PrintPayloadWeight, the pointer put
; back. Witness: L1 2525 (c1, death, m2erbe, missions, play, play2).
StoresMessageTimer:
  LD A,$00
  AND A
  RET Z
  DEC A
  LD (StoresMessageTimer+$0001),A
  JR Z,ClearStoresMessage
  RET
ClearStoresMessage:
  XOR A
  LD ($83BF),A
  LD A,$FF
  EX AF,AF'
  LD A,$99
  LD C,$11
  EXX
  LD D,$0E
  LD E,$06
  CALL $6D22
  LD HL,PayloadLineBox
  CALL $6CFB
  LD HL,PayloadLineText
  CALL $6FB3
  CALL PrintPayloadWeight
  CALL RestorePointerBackground
  CALL SavePointerBackground
  LD A,$FF
  LD ($83BF),A
  RET

; The attribute box of the payload lines
;
; Read by StoresMessageTimer `$C2DE`.
PayloadLineBox:
  DEFB $4F,$03,$11,$0E,$12

; Show the weapon CurrentWeapon points at: its icon, its description, its model
;
; ClearWeaponPanel `$C363`, CopyGraphic `$6D7F` of the 3 x 24 icon (record +5)
; at line `$30`, column 2, PrintString of the description (record +7), and the
; model (record +9) into StoresModelOp, the operand `$CB3B` of the stores' 3D
; loop. Witness: L1 54 (c1, death, m2erbe, missions, play, play2).
ShowWeapon:
  CALL ClearWeaponPanel
  LD HL,(CurrentWeapon)
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  EX DE,HL
  LD D,$03
  LD C,$18
  EXX
  LD C,$02
  LD A,$30
  CALL $6D7F
  POP HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  EX DE,HL
  CALL $6FB3
  POP HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (StoresModelOp+$0002),DE
  RET

; Zone: the next record of WeaponRecords (the first again after the end mark),
; then ShowWeapon
;
; Witness: L1 39 (play, play2).
NextWeapon:
  LD HL,(CurrentWeapon)
  LD DE,$000B
  ADD HL,DE
  LD A,(HL)
  CP $FF
  JR NZ,NextWeaponSet
  LD HL,WeaponTurret
  LD (CurrentWeapon),HL
  JR ShowWeapon
NextWeaponSet:
  LD (CurrentWeapon),HL
  JR ShowWeapon

; Zone: the record before (the last one before the start mark), then ShowWeapon
;
; Known only from the code: in StoresZones (`$CBD0`), but no recording clicks
; it.
PreviousWeapon:
  LD HL,(CurrentWeapon)
  DEC HL
  LD A,(HL)
  CP $FF
  JR NZ,PreviousWeaponStep
  LD HL,WeaponSlamLaser
  LD (CurrentWeapon),HL
  JR ShowWeapon
PreviousWeaponStep:
  LD DE,$000A
  AND A
  SBC HL,DE
  LD (CurrentWeapon),HL
  JR ShowWeapon

; Clear 48 pixel lines of 11 bytes at column 3 from line $30 (the weapon's icon
; and text)
;
; ScreenRowFill `$6D22` with 0. Witness: L1 54 (c1, death, m2erbe, missions,
; play, play2).
ClearWeaponPanel:
  XOR A
  EX AF,AF'
  LD A,$30
  LD C,$03
  EXX
  LD D,$0B
  LD E,$30
  JP $6D22

; The record of the shown weapon (WeaponRecords + 1 + 11n)
;
; Set by StoresScreen `$CAE3`, moved by NextWeapon and PreviousWeapon, read by
; ShowWeapon and FitOrRemoveWeapon.
CurrentWeapon:
  DEFW WeaponTurret

; $FF, the 13 weapon records of 11 bytes, $FF
;
; A record: +0 the type (1-13; IconTable `$75CA` entry type - 1), +1 the
; ammunition, +2 the most the four slots may hold, +3 the weight in kg (word),
; +5 the 3 x 24 icon, +7 the description text, +9 the model script (bank 3
; `$CExx`, or bank 2). The `$FF` before and after stop NextWeapon and
; PreviousWeapon.
;
; The Sleeper mine's record says 300 kg, its text 290 KG.
WeaponRecords:
  DEFB $FF                ; the start mark
WeaponTurret:
  DEFB $04,$50,$01,$90,$01,$44,$F4,$C0,$D8,$26,$CF ; type 4 Turret: ammo 80,
                                                   ; max 1, 400 kg, icon $F444
WeaponBansheeRRSS:
  DEFB $02,$08,$02,$2C,$01,$BC,$F1,$BB,$D7,$75,$87 ; type 2: ammo 8, max 2, 300
                                                   ; kg
WeaponBansheeIRSS:
  DEFB $06,$06,$02,$2C,$01,$74,$F1,$2E,$D7,$75,$87 ; type 6: ammo 6, max 2, 300
                                                   ; kg
WeaponPhoenixRRSA:
  DEFB $01,$08,$02,$FA,$00,$4C,$F2,$DA,$D6,$75,$87 ; type 1: ammo 8, max 2, 250
                                                   ; kg
WeaponPhoenixIRSA:
  DEFB $05,$06,$02,$FA,$00,$04,$F2,$04,$D7,$75,$87 ; type 5: ammo 6, max 2, 250
                                                   ; kg
WeaponK40Mortar:
  DEFB $03,$14,$02,$FA,$00,$9C,$F0,$96,$D8,$D1,$CE ; type 3: ammo 20, max 2,
                                                   ; 250 kg
WeaponSleeperMine:
  DEFB $09,$05,$02,$2C,$01,$94,$F2,$1D,$D8,$39,$87 ; type 9: ammo 5, max 2, 300
                                                   ; kg
WeaponDragonfly:
  DEFB $07,$03,$02,$F4,$01,$DC,$F2,$58,$D7,$75,$87 ; type 7: ammo 3, max 2, 500
                                                   ; kg
WeaponK90Cluster:
  DEFB $08,$14,$04,$FA,$00,$6C,$F3,$0B,$D9,$5B,$7F ; type 8: ammo 20, max 4,
                                                   ; 250 kg
WeaponSpectre:
  DEFB $0D,$0C,$02,$64,$00,$24,$F3,$70,$D8,$5B,$7F ; type 13: ammo 12, max 2,
                                                   ; 100 kg
WeaponPhantasm:
  DEFB $0C,$08,$02,$64,$00,$B4,$F3,$E5,$D8,$8F,$7E ; type 12: ammo 8, max 2,
                                                   ; 100 kg
WeaponSkeetBomb:
  DEFB $0B,$0C,$02,$C8,$00,$FC,$F3,$47,$D8,$CA,$7E ; type 11: ammo 12, max 2,
                                                   ; 200 kg
WeaponSlamLaser:
  DEFB $0A,$28,$01,$FA,$00,$2C,$F1,$F4,$D7,$47,$CE ; type 10: ammo 40, max 1,
                                                   ; 250 kg
  DEFB $FF                ; the end mark

; The attribute box of the title menu's 3D window
;
; Read by TitleMenu `$C4A7`.
TitleBox:
  DEFB $44,$0A,$00,$20,$08

  ORG $CA8B

; The stores: picture, slots, the weapon and its turning model, until the
; mission starts
;
; Pointer job off, the hooks `$7256`, `$9A93`, `$83F1` cleared, the arrow
; pointer, the clip mark `$A17C` = `$5F`, Bank3Fill5F `$74CD`, ClearSlots
; `$CC01`, DrawBank7Picture `$C713` (PicStores), the view parameters,
; ResetStores, the four play hooks `$6A46-$6A55` = NoAction `$6BB0`, the first
; weapon (ShowWeapon), PayloadLineText, StoresGraphicA-C, StoresTitleBox,
; StoresPointerLimits `$D337`, the stores blit (`$83E6` = BlitStoresView
; `$D0A0`), SetStoresWindow `$D102`.
;
; StoresLoop: StartViewPass, the weapon's model by Bank3Render (IX =
; StoresModelOp's operand), RequestViewBlit, the turn `$68E7`, PointerZones,
; StoresMessageTimer, until the view flag. Then: ShowWaitPointer, the 3D blit
; back, ResetCollisionTables `$6928` (bank 0), StoresToGauges, the object table
; `$762C` cleared (23 records of 60 bytes, the first byte `$FF`), `$7BFD-$7C05`
; = `$FF`, NumberObjectRecords, the mission's header patched (`$7E2C`), the
; score `$68E2-$68E5` cleared, the clock stopped, Bank3FillFF, `$83F1` = `RET`,
; NextView (StartMission). Witness: L1 15 (c1, death, m2erbe, missions, play,
; play2).
StoresScreen:
  XOR A
  LD ($83BF),A
  LD ($7256),A
  LD ($9A93),A
  LD ($83F1),A
  LD HL,PointerShapes
  LD (ShiftPointer+$0001),HL
  LD A,$5F
  LD ($A17C),A
  CALL $74CD
  CALL ClearSlots
  CALL $7268
  LD DE,RawGlyph+$0008
  CALL $74AA
  LD HL,$0020
  LD ($9AA3),HL
  LD L,$18
  LD ($9ABB),HL
  LD HL,$0200
  LD ($9A6C),HL
  LD H,$00
  LD ($9AB3),HL
  LD HL,$0040
  LD ($9A8E),HL
  CALL ResetStores
  LD HL,$6BB0
  LD ($6A46),HL
  LD ($6A4B),HL
  LD ($6A50),HL
  LD ($6A55),HL
  LD HL,WeaponTurret
  LD (CurrentWeapon),HL
  CALL ShowWeapon
  LD HL,PayloadLineText
  CALL $6FB3
  LD HL,StoresGraphicA
  LD D,$04
  LD C,$18
  EXX
  LD C,$02
  LD A,$90
  CALL $6D7F
  LD HL,StoresGraphicB
  LD D,$04
  LD C,$18
  EXX
  LD C,$0A
  LD A,$90
  CALL $6D7F
  LD HL,StoresGraphicC
  LD D,$0C
  LD C,$10
  EXX
  LD C,$12
  LD A,$B0
  CALL $6D7F
  LD HL,StoresTitleBox
  CALL $6CFB
  CALL SavePointerBackground
  CALL StoresPointerLimits
  LD HL,BlitStoresView
  LD ($83E6),HL
  CALL SetStoresWindow
  LD A,$FF
  LD ($83BF),A
StoresLoop:
  CALL $9882
StoresModelOp:
  LD IX,DecodeFlag9+$0006 ; LD IX,n: n ($CB3B) the shown weapon's model,
                          ; written by ShowWeapon
  CALL $72BE
  CALL $988D
  LD HL,$68E7
  INC (HL)
  CALL $6D42
  CALL StoresMessageTimer
  CALL $7E7A
  CALL $7256
  LD A,($6A6D)
  AND A
  JR Z,StoresLoop
  CALL $7225
  CALL ShowWaitPointer
  LD HL,$8999
  LD ($83E6),HL
  CALL $6928
  CALL StoresToGauges
  LD HL,$762C
  LD (HL),$00
  LD D,H
  LD E,L
  INC DE
  LD BC,$0564
  LDIR
  LD HL,$762C
  LD B,$17
  LD DE,$003C
ObjectMarkLoop:
  LD (HL),$FF
  ADD HL,DE
  DJNZ ObjectMarkLoop
  LD B,$09
  LD HL,$7BFD
ClearFlagsLoop:
  LD (HL),$FF
  INC HL
  DJNZ ClearFlagsLoop
  CALL NumberObjectRecords
  LD HL,($70A3)
  INC HL
  LD E,(HL)
  LD (HL),$0A
  INC HL
  INC HL
  LD D,(HL)
  LD (HL),$02
  LD ($7E2C),DE
  LD DE,$0000
  LD ($68E2),DE
  LD ($68E4),DE
  XOR A
  LD ($83BF),A
  LD ($7DFB),A
  LD A,$FF
  LD ($A17C),A
  CALL $74C9
  LD A,$C9
  LD ($83F1),A
  JP $6A91

; Zone table of the stores
;
; ScreenFromClick `$7055` (start), NextWeapon, PreviousWeapon, SlotZoneA,
; SlotZoneB, SlotZoneC, SlotZoneD.
StoresZones:
  DEFB $92,$EC,$B3,$B8,$55,$70
  DEFB $52,$6B,$93,$A4,$2E,$C3
  DEFB $12,$2B,$93,$A4,$47,$C3
  DEFB $88,$A7,$28,$47,$69,$C1
  DEFB $D8,$F7,$28,$47,$65,$C1
  DEFB $88,$A7,$58,$77,$6D,$C1
  DEFB $D8,$F7,$58,$77,$71,$C1
  DEFB $00

; An attribute box record no routine reads
;
; Known only from the code.
StoresSpareBox:
  DEFB $47,$06,$03,$09,$0F

; Pointer job off, the boxed shape WaitPointer, DrawPointer
;
; Called when a screen is left. Witness: L1 97 (c1, death, m10, m2erbe,
; m2ocean, menu, missions, play, play2, search).
ShowWaitPointer:
  XOR A
  LD ($83BF),A
  LD HL,WaitPointer
  LD (ShiftPointer+$0001),HL
  JP DrawPointer

; Empty the four slot records, the payload weight = 0, the hook $A9B9 =
; NoAction
;
; Witness: L1 15 (c1, death, m2erbe, missions, play, play2).
ClearSlots:
  LD HL,$8368
  LD DE,$0006
  LD B,$04
ClearSlotsLoop:
  LD (HL),$00
  ADD HL,DE
  DJNZ ClearSlotsLoop
  LD HL,$0000
  LD (PayloadWeightOp+$0001),HL
  LD HL,$6BB0
  LD ($A9B9),HL
  RET

; The four damage values $8301-$8304 = $7F, each weapon record of $834A to a
; gauge of $68AB
;
; Nine 6-byte records: a fitted one (non-zero) gives the gauge `$5F`, an empty
; one 0. `$7C57` = `$3F00`, `$7578` and `$68E8` cleared. Witness: L1 15 (c1,
; death, m2erbe, missions, play, play2).
StoresToGauges:
  LD A,$7F
  LD ($8301),A
  LD ($8302),A
  LD ($8303),A
  LD ($8304),A
  LD BC,$0006
  LD HL,$834A
  LD DE,$68AB
  EXX
  LD B,$09
GaugeLoop:
  EXX
  LD A,(HL)
  AND A
  EX DE,HL
  JR Z,GaugeEmpty
  LD (HL),$5F
  JR GaugeNext
GaugeEmpty:
  LD (HL),A
GaugeNext:
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EXX
  DJNZ GaugeLoop
  LD HL,$3F00
  LD ($7C57),HL
  XOR A
  LD ($7578),A
  LD ($68E8),A
  RET

  ORG $D0A0

; The stores' blit: 48 lines of 9 bytes of the back buffer to the screen (line
; table $65C0)
;
; Run by the interrupt through ViewBlit `$83E6`; the stack walks the line
; address table. Witness: L1 2525 (c1, death, m2erbe, missions, play, play2).
BlitStoresView:
  LD (StoresBlitSpOp+$0001),SP
  LD SP,$65C0
  LD HL,$8AF1
  LD A,$30
StoresBlitLoop:
  POP DE
  LD BC,$0009
  INC E
  INC E
  INC E
  INC HL
  INC HL
  INC HL
  LDIR
  LD (StoresBlitDestOp+$0001),DE
  LD DE,$0014
  ADD HL,DE
StoresBlitDestOp:
  LD DE,$0000
  DEC A
  JR NZ,StoresBlitLoop
StoresBlitSpOp:
  LD SP,$0000             ; LD SP,n: n ($D0C7) the saved stack
  RET

  ORG $D6DA

; The weapon descriptions (Phoenix RRSA, Phoenix IRSA, Banshee IRSS,
; Dragonfly): name, weight, ammo, max
;
; Printed by ShowWeapon through the records' +7. Code 13 (attribute), code 2
; (at a line and column), code 9, code 11 (new line).
WeaponTexts:
TextPhoenixRRSA:
  DEFB $0D,$47,$02,$50,$02,$50,$68,$6F,$65,$6E,$69,$78,$20,$52,$52,$53
  DEFB $41,$09,$06,$02,$30,$06,$32,$35,$30,$20,$4B,$47,$0B,$41,$4D,$4D
  DEFB $4F,$20,$38,$0B,$4D,$41,$58,$20,$32,$FF
TextPhoenixIRSA:
  DEFB $0D,$47,$02,$50,$02,$50,$68,$6F,$65,$6E,$69,$78,$20,$49,$52,$53
  DEFB $41,$09,$06,$02,$30,$06,$32,$35,$30,$20,$4B,$47,$0B,$41,$4D,$4D
  DEFB $4F,$20,$36,$0B,$4D,$41,$58,$20,$32,$FF
TextBansheeIRSS:
  DEFB $0D,$47,$02,$50,$02,$42,$61,$6E,$73,$68,$65,$65,$20,$49,$52,$53
  DEFB $53,$09,$06,$02,$30,$06,$33,$30,$30,$20,$4B,$47,$0B,$41,$4D,$4D
  DEFB $4F,$20,$36,$0B,$4D,$41,$58,$20,$32,$FF
TextDragonfly:
  DEFB $0D,$47,$02,$50,$02,$44,$72,$61,$67,$6F,$6E,$66,$6C,$79,$09,$06
  DEFB $02,$30,$06,$35,$30,$30,$20,$4B,$47,$0B,$41,$4D,$4D,$4F,$20,$33
  DEFB $0B,$4D,$41,$58,$20,$32,$FF

  ORG $D7BB

; The Banshee RRSS description
;
; Printed by ShowWeapon.
WeaponTextsB:
  DEFB $0D,$47,$02,$50,$02,$42,$61,$6E,$73,$68,$65,$65,$20,$52,$52,$53
  DEFB $53,$09,$06,$02,$30,$06,$33,$30,$30,$20,$4B,$47,$0B,$41,$4D,$4D
  DEFB $4F,$20,$38,$0B,$4D,$41,$58,$20,$32,$FF

; Attribute box records of the panel
;
; `$D7EA` and `$D7EF` read by PanelAttributes; `$D7E5` by nothing.
PanelBoxes:
  DEFB $45,$04,$00,$20,$00
PanelBoxA:
  DEFB $70,$03,$02,$06,$00
PanelBoxB:
  DEFB $78,$05,$0C,$08,$0F

; The descriptions of SLAM Laser, Sleeper mine, Skeet bomb, Spectre, K-40
; Mortar, Turret, Phantasm, K-90 Cluster
;
; Printed by ShowWeapon.
WeaponTextsC:
TextSlamLaser:
  DEFB $0D,$47,$02,$50,$02,$53,$4C,$41,$4D,$20,$4C,$61,$73,$65,$72,$09
  DEFB $06,$02,$30,$06,$32,$35,$30,$20,$4B,$47,$0B,$41,$4D,$4D,$4F,$20
  DEFB $34,$30,$0B,$4D,$41,$58,$20,$31,$FF
TextSleeperMine:
  DEFB $0D,$47,$02,$50,$02,$53,$6C,$65,$65,$70,$65,$72,$20,$6D,$69,$6E
  DEFB $65,$09,$06,$02,$30,$06,$32,$39,$30,$20,$4B,$47,$0B,$41,$4D,$4D
  DEFB $4F,$20,$35,$0B,$4D,$41,$58,$20,$32,$FF
TextSkeetBomb:
  DEFB $0D,$47,$02,$50,$02,$53,$6B,$65,$65,$74,$20,$62,$6F,$6D,$62,$09
  DEFB $06,$02,$30,$06,$32,$30,$30,$20,$4B,$47,$0B,$41,$4D,$4D,$4F,$20
  DEFB $31,$32,$0B,$4D,$41,$58,$20,$32,$FF
TextSpectre:
  DEFB $0D,$47,$02,$50,$02,$53,$70,$65,$63,$74,$72,$65,$09,$06,$02,$30
  DEFB $06,$31,$30,$30,$20,$4B,$47,$0B,$41,$4D,$4D,$4F,$20,$31,$32,$0B
  DEFB $4D,$41,$58,$20,$32,$FF
TextK40Mortar:
  DEFB $0D,$47,$02,$50,$02,$4B,$2D,$34,$30,$20,$4D,$6F,$72,$74,$61,$72
  DEFB $09,$06,$02,$30,$06,$32,$35,$30,$20,$4B,$47,$0B,$41,$4D,$4D,$4F
  DEFB $20,$32,$30,$0B,$4D,$41,$58,$20,$32,$FF
TextTurret:
  DEFB $0D,$47,$02,$50,$02,$54,$75,$72,$72,$65,$74,$09,$06,$02,$30,$06
  DEFB $34,$30,$30,$20,$4B,$47,$0B,$41,$4D,$4D,$4F,$20,$38,$30,$0B,$4D
  DEFB $41,$58,$20,$31,$FF
TextPhantasm:
  DEFB $0D,$47,$02,$50,$02,$50,$68,$61,$6E,$74,$61,$73,$6D,$09,$06,$02
  DEFB $30,$06,$31,$30,$30,$20,$4B,$47,$0B,$41,$4D,$4D,$4F,$20,$38,$0B
  DEFB $4D,$41,$58,$20,$32,$FF
TextK90Cluster:
  DEFB $0D,$47,$02,$50,$02,$4B,$2D,$39,$30,$20,$43,$6C,$75,$73,$74,$65
  DEFB $72,$09,$06,$02,$30,$06,$32,$35,$30,$20,$4B,$47,$0B,$41,$4D,$4D
  DEFB $4F,$20,$32,$30,$0B,$4D,$41,$58,$20,$34,$FF

; Texts of the payload: "MAX PAYLOAD 1000KG", "PAYLOAD WGT 0KG", the two
; errors, the weight
;
; `$D936` printed by StoresScreen and StoresMessageTimer, the errors by
; FitOrRemoveWeapon, PayloadText by PrintPayloadWeight.
PayloadLineText:
  DEFB $0D,$79,$07,$92,$17,$4D,$41,$58,$3A,$50,$41,$59,$4C,$4F,$41,$44
  DEFB $3A,$31,$30,$30,$30,$4B,$47,$07,$A2,$17,$50,$41,$59,$4C,$4F,$41
  DEFB $44,$3A,$57,$47,$54,$3A,$3A,$3A,$3A,$30,$4B,$47,$FF
PayloadExceededText:
  DEFB $07,$92,$17,$0D,$46,$3A,$50,$41,$59,$4C,$4F,$41,$44,$3A,$45,$58
  DEFB $43,$45,$45,$44,$45,$44,$3A,$07,$9A,$17,$3A,$3A,$3A,$3A,$3A,$3A
  DEFB $3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$FF
MaxNumberText:
  DEFB $07,$9A,$17,$0D,$46,$3A,$4D,$41,$58,$3A,$4E,$55,$4D,$3A,$45,$58
  DEFB $43,$45,$45,$44,$45,$44,$3A,$FF
PayloadText:
  DEFB $07,$A2,$22
PaddedDigits:
  DEFB $30,$30,$30,$30,$30,$FF,$FF ; five digits, written by NumberToDigits
