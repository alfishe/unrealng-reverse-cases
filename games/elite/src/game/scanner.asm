; --------------------------------------------------------------------------------------------------------------------
; scanner.asm: The scanner, the condition light, the energy and the shields, the missile
;
; The scanner is the ellipse in the middle of the dashboard. Its background (13 bytes by 48 lines from $5049) is kept
; in ScannerSave $5B00 and copied back each frame before the ships are drawn (ScannerRestore). A ship within range
; ($40 in the high byte of each coordinate and x² + z² below $1600 in squares' units) is a dot of two or three pixels
; at (x * 3/16, z * 5/64) from the centre $558F, with a stalk of y * 5/64 lines up or down to it.
;
; The per-frame dashboard work (DashboardTick) prints the indicators, handles the missile keys and the damage, and
; recharges the energy banks. Condition $7104 is worked out again every frame: green by default, yellow while a ship
; other than the station is about (ConditionYellow), red with a shield down, flashing ($63) with the fourth energy
; bank not full; ConditionLight puts it on the two cells of the light and sets green for the next frame.
; --------------------------------------------------------------------------------------------------------------------

; The next slot
;
; Used by the routine at DrawScanner.
ScannerNext:
  JP ScannerSlotDone

; Restore the scanner's background, then a dot and a stalk for each ship within
; range
;
; Nothing is drawn while no slot is in use (ShipsPresent $9C96); a free slot
; has energy (+$22) 0; 553 of 1076 calls drew in f1, w1 and d1. The coordinates
; go through Divide16 with DE = $4000, so a high byte of $40 would be the
; scanner's edge.
DrawScanner:
  CALL ScannerRestore
  LD A,(ShipsPresent)
  AND A
  RET Z
  CALL ConditionYellow
  LD A,$08
  LD (SoundBit+$0004),A
  LD IX,ShipSlots
ScannerShip:
  LD A,(IX+$22)
  AND A
  JR Z,ScannerNext
  LD A,(IX+$01)
  CP $40
  JR NC,ScannerNext
  LD A,(IX+$04)
  CP $40
  JR NC,ScannerNext
  LD A,(IX+$07)
  CP $40
  JR NC,ScannerNext
  LD A,(IX+$01)
  CALL Square
  EX DE,HL
  LD A,(IX+$07)
  CALL Square
  ADD HL,DE
  JR C,ScannerNext
  LD DE,$1600
  AND A
  SBC HL,DE
  JR NC,ScannerNext
  LD A,$01
  LD (SoundBit+$0005),A
ScannerPlace:
  LD DE,$4000
  XOR A
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL Divide16Vector
  CALL ShiftBC3
  LD H,B
  LD L,C
  CALL ShiftBC1
  ADD HL,BC
  LD A,(IX+$02)
  AND $80
  LD A,H
  JR Z,DrawScannerSetSoundBit1
  OR $80
DrawScannerSetSoundBit1:
  LD (SoundBit+$0001),A
  XOR A
  LD L,(IX+$03)
  LD H,(IX+$04)
  CALL Divide16Vector
  CALL ShiftBC4
  LD H,B
  LD L,C
  CALL ShiftBC2
  ADD HL,BC
  LD A,(IX+$05)
  AND $80
  LD A,H
  JR Z,DrawScannerSetSoundBit2
  OR $80
DrawScannerSetSoundBit2:
  LD (SoundBit+$0002),A
  XOR A
  LD L,(IX+$06)
  LD H,(IX+$07)
  CALL Divide16Vector
  CALL ShiftBC4
  LD H,B
  LD L,C
  CALL ShiftBC2
  ADD HL,BC
  LD A,(IX+$08)
  AND $80
  LD A,H
  JR Z,DrawScannerSetSoundBit3
  OR $80
DrawScannerSetSoundBit3:
  LD (SoundBit+$0003),A
ScannerScreen:
  LD HL,$558F             ; HL = the centre; x moves it by bytes and C gets the
                          ; pixel
  LD A,(SoundBit+$0001)
  AND $7F
  SUB $04
  LD C,A
  JP C,ScannerNearX
  RRA
  RRA
  RRA
  AND $1F
  LD B,A
  LD A,C
  AND $07
  LD C,A
  JR Z,DrawScannerGetSoundBit1
  INC B
DrawScannerGetSoundBit1:
  LD A,(SoundBit+$0001)
  AND $80
  JR NZ,ScannerLeft
ScannerRight:
  INC HL
  DJNZ ScannerRight
DrawScannerLoop:
  LD A,C
  AND A
  LD B,A
  LD A,$01
  JR Z,ScannerDepth
  XOR A
  SCF
DrawScannerLoop2:
  RRA
  DJNZ DrawScannerLoop2
  JR ScannerDepth
ScannerNearX:
  ADD A,$08
  LD C,A
  LD A,(SoundBit+$0001)
  AND $80
  JR NZ,DrawScannerIfNotZero
  JR DrawScannerLoop
ScannerLeft:
  DEC HL
  DJNZ ScannerLeft
DrawScannerIfNotZero:
  LD A,C
  AND A
  LD B,A
  LD A,$80
  JR Z,ScannerDepth
  XOR A
  SCF
DrawScannerLoop3:
  RLA
  DJNZ DrawScannerLoop3
ScannerDepth:
  LD C,A                  ; z moves HL by pixel lines
  LD A,(SoundBit+$0003)
  LD D,A
  AND $7F
  LD B,A
  JR Z,ScannerStalk
  LD A,D
  AND $80
  JR NZ,ScannerDepthDown
DrawScannerLoop4:
  LD A,H
  DEC H
  AND $07
  CALL Z,NextLineUp
  DJNZ DrawScannerLoop4
  JR ScannerStalk
ScannerDepthDown:
  INC H
  LD A,H
  AND $07
  CALL Z,NextLineDown
  DJNZ ScannerDepthDown
ScannerStalk:
  LD A,(SoundBit+$0002)   ; y draws the stalk from there
  LD D,A
  AND $7F
  LD B,A
  JR Z,ScannerDot
  LD A,D
  AND $80
  JR NZ,ScannerStalkDown
DrawScannerLoop5:
  LD A,(HL)
  OR C
  LD (HL),A
  LD A,H
  DEC H
  AND $07
  CALL Z,ScannerLineUp
  DJNZ DrawScannerLoop5
  JR ScannerDot
ScannerStalkDown:
  LD A,(HL)
  OR C
  LD (HL),A
  INC H
  LD A,H
  AND $07
  CALL Z,ScannerLineDown
  DJNZ ScannerStalkDown
ScannerDot:
  LD A,C                  ; the dot: the stalk's pixel and its neighbours,
                          ; across a byte edge at $9852 and $985E
  ADD A,A
  JR C,ScannerDotEdge1
  OR C
  ADD A,A
  JR C,ScannerDotEdge2
  OR C
  LD E,A
  LD A,(HL)
  OR E
  LD (HL),A
; This entry point is used by the routines at ScannerNext, ScannerLineDown and
; ScannerLineUp.
ScannerSlotDone:
  LD A,(SoundBit+$0004)
  DEC A
  JR Z,ScannerTopClear
  LD (SoundBit+$0004),A
  LD DE,$0027
  ADD IX,DE
  JP ScannerShip
ScannerTopClear:
  XOR A                   ; the 13 bytes by 7 lines above the scanner cleared
                          ; (the stalks that ran out of it)
  LD C,$07
  LD HL,$5009
DrawScannerLoop6:
  LD B,$0D
  PUSH HL
DrawScannerLoop7:
  LD (HL),A
  INC L
  DJNZ DrawScannerLoop7
  POP HL
  INC H
  DEC C
  JR NZ,DrawScannerLoop6
  RET
ScannerDotEdge1:
  DEC L
  LD A,(HL)
  OR $03
  LD (HL),A
  INC L
  LD A,(HL)
  OR $80
  LD (HL),A
  JR ScannerSlotDone
ScannerDotEdge2:
  DEC L
  LD A,(HL)
  OR $01
  LD (HL),A
  INC L
  LD A,(HL)
  OR $C0
  LD (HL),A
  JR ScannerSlotDone

; Down a character row; leaving the dashboard ($58xx) abandons the ship's stalk
;
; Used by the routine at DrawScanner.
ScannerLineDown:
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,ScannerLineDownThird
  LD A,$58
  CP H
  RET NZ
  POP AF
  JR ScannerSlotDone
ScannerLineDownThird:
  LD A,H
  SUB $08
  LD H,A
  RET

; Up a character row; above the scanner's first row abandons the ship's stalk
;
; Used by the routine at DrawScanner.
ScannerLineUp:
  LD A,L
  CP $0F
  JR NZ,ScannerLineUpRow
  POP AF
  JP ScannerSlotDone
ScannerLineUpRow:
  SUB $20
  LD L,A
  RET C
  LD A,H
  ADD A,$08
  LD H,A
  RET

; Yellow while a ship other than the station is about, unless the condition is
; red or flashing
;
; Used by the routines at FlightLoop and DrawScanner.
ConditionYellow:
  LD A,(NonStationPresent)
  AND A
  RET Z
  LD A,(Condition)
  CP $63
  RET Z
  CP $02
  RET Z
  LD A,$06
  LD (Condition),A
  RET

; Patch ScannerCopy to save the screen into ScannerSave, then copy it (known
; from the code only: 3 runs after a new dashboard)
;
; The five patched bytes turn the copy around: EX DE,HL first, PUSH HL and POP
; HL in place of PUSH DE and POP DE, INC H for INC D. ScannerRestore puts the
; restore's bytes back.
ScannerSaveOn:
  CALL ScannerRestore
  LD BC,$0005
  LD A,$EB
  LD HL,ScannerCopyFlip
  LD (HL),A
  LD A,$E5
  LD HL,ScannerCopyRow
  LD (HL),A
  ADD HL,BC
  LD (HL),A
  LD A,$E1
  LD HL,ScannerCopyLine+$001B
  LD (HL),A
  INC HL
  LD A,$24
  LD (HL),A
  XOR A
  LD HL,ScannerCopyFlipBack+$0007
  LD (HL),A
  LD A,$EB
  LD HL,ScannerCopyFlipBack
  LD (HL),A
  JR ScannerCopy

; Once after a frame drew the scanner: clear the 11 x 8 bytes of the
; dashboard's middle and patch ScannerCopy back to a restore
;
; Used by the routines at FlightLoop, DashboardSave, DrawScanner and
; ScannerSaveOn.
ScannerRestore:
  LD A,(SoundBit+$0005)
  DEC A
  RET NZ
  LD (SoundBit+$0005),A
  XOR A
  LD C,$08
  LD HL,$502A
ScannerRestoreLine:
  LD B,$0B
  PUSH HL
ScannerRestoreByte:
  LD (HL),A
  INC L
  DJNZ ScannerRestoreByte
  POP HL
  INC H
  DEC C
  JR NZ,ScannerRestoreLine
  LD BC,$0005
  XOR A
  LD HL,ScannerCopyFlip
  LD (HL),A
  LD A,$D5
  LD HL,ScannerCopyRow
  LD (HL),A
  ADD HL,BC
  LD (HL),A
  LD A,$D1
  LD HL,ScannerCopyLine+$001B
  LD (HL),A
  INC HL
  LD A,$14
  LD (HL),A
  LD A,$EB
  LD HL,ScannerCopyFlipBack+$0007
  LD (HL),A
  XOR A
  LD HL,ScannerCopyFlipBack
  LD (HL),A

; Copy the scanner's 13 x 48 bytes between ScannerSave and the screen (patched
; for the direction)
;
; Used by the routine at ScannerSaveOn.
ScannerCopy:
  LD DE,$5049
  LD HL,ScannerSave
ScannerCopyFlip:
  NOP                     ; NOP or EX DE,HL
  LD A,$06
ScannerCopyRow:
  PUSH DE
  LD B,$08
  LD C,$FF
ScannerCopyLine:
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
  POP DE
  INC D
  DJNZ ScannerCopyLine
ScannerCopyFlipBack:
  NOP
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,ScannerCopyRow
  RET

; ScannerSpare
ScannerSpare:
  DEFB $00

; The new flight's dashboard: the missiles, the indicators, the bars full or
; empty, the scanner's colours
;
; The shields and the altitude full ($A0), the energy banks full, the cabin and
; laser temperatures 0, no missile armed, AutoDocked and ECMActive off. The two
; colour blocks either side of the scanner are 7 x 5 cells of $17 (red paper)
; or $1F (magenta) with the escape pod ($D089). 3 runs (the launches).
ResetFlight:
  CALL DrawMissiles
  CALL ClearHighlightsVector
  XOR A
  LD (MissileState),A
  LD (BarLaserTemp),A
  LD (BarCabinTemp),A
  LD (AutoDocked),A
  LD (ECMActive),A
  LD (MissileLaunchFlag),A
  LD A,$A0
  LD (BarForeShield),A
  LD (BarAftShield),A
  LD (BarAltitude),A
  LD HL,BarEnergy1
  LD B,$04
ResetFlightLoop:
  LD (HL),A
  INC HL
  INC HL
  DJNZ ResetFlightLoop
; This entry point is used by the routine at AttrFillVector.
ResetFlightJoin:
  LD HL,$5A23
  LD A,(ViewIndex)
  CP $04
  JR C,ResetFlightColour
  INC H
ResetFlightColour:
  LD C,$17
  LD A,(Equipment+$0005)
  AND A
  JR Z,ResetFlightBlocks
  LD C,$1F
ResetFlightBlocks:
  LD DE,$001B
  PUSH HL
  CALL FillBlock
  POP HL
  LD A,L
  ADD A,$15
  LD L,A

; Fill 7 rows of 5 attribute cells with C (DE = 27 the row's rest)
;
; Used by the routine at ResetFlight.
FillBlock:
  LD B,$07
FillBlockRow:
  PUSH BC
  LD B,$05
FillBlockCell:
  LD (HL),C
  INC HL
  DJNZ FillBlockCell
  POP BC
  ADD HL,DE
  DJNZ FillBlockRow
  RET

; The flashing's counter: bit 1 picks red or black
ConditionFlash:
  DEFB $00

; Light the condition: red with a shield down, flashing every two frames, the
; colour on the two cells
;
; In the menus and charts (views 4 and up) the condition is a text instead:
; tokens $21-$24 at row 1, column $1B (known from the code only). The missile's
; light at $5AE7 gets paper green when armed, red when locked.
ConditionLight:
  LD HL,Condition
  LD A,(HL)
  AND A
  RET Z
  LD A,(BarForeShield)
  AND A
  JR Z,ConditionRed
  LD A,(BarAftShield)
  AND A
  JR NZ,ConditionColour
ConditionRed:
  LD A,(HL)
  CP $63
  JR Z,ConditionColour
  LD (HL),$02
ConditionColour:
  LD A,(HL)
  CP $63
  JR NZ,ConditionShow
  LD HL,ConditionFlash
  INC (HL)
  BIT 1,(HL)
  JR NZ,ConditionRedPhase
  XOR A
  JR ConditionShow
ConditionRedPhase:
  LD A,$02
ConditionShow:
  LD D,A
  LD A,(ViewIndex)
  CP $04
  JR NC,ConditionText
  LD HL,$5A28
  LD (HL),D
  INC HL
  LD (HL),D
  LD HL,$5A48
  LD (HL),D
  INC HL
  LD (HL),D
  CALL ConditionGreen
  LD A,(MissileState)
  CP $01
  JR NZ,ConditionMissile
  LD A,$04
ConditionMissile:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$07
  LD ($5AE7),A
  RET
ConditionText:
  LD HL,(PrintTarget)
  LD (HL),$00
  LD HL,$011B
  LD (TextColumn),HL
  CP $09
  JR NC,ConditionTextOther
  LD A,D
  AND A
  JR Z,ConditionTextGreen
  CP $02
  JR NZ,ConditionTextColour
  LD A,$21
  CALL PrintCodeVector
  LD A,$22
  CALL PrintCodeVector
  LD D,$17
  JR ConditionTextCells
ConditionTextGreen:
  LD D,$02
ConditionTextColour:
  LD A,$10
  ADD A,D
  LD D,A
ConditionTextOther:
  PUSH DE
  LD A,$23
  CALL PrintCodeVector
  LD A,$24
  CALL PrintCodeVector
  POP DE
ConditionTextCells:
  LD HL,$583C
  LD (HL),D
  INC HL
  LD (HL),D
  LD HL,(PrintTarget)
  LD (HL),$A9

; Condition green for the next frame
;
; Used by the routine at ConditionLight.
ConditionGreen:
  LD A,$04
  LD (Condition),A
  RET

; The flight views' dashboard: the indicators, the missile, the energy bomb,
; then the damage
;
; The missile keys are cleared after use (KeyCombat AND $91 keeps A, E and C:
; T, F, U, W and Q are cleared).
DashboardTick:
  LD A,(ViewIndex)
  CP $04
  RET NC
  CALL DrawIndicators
  CALL MissileKeys
  CALL EscapePod
  CALL EnergyBombVector
  LD HL,KeyCombat
  LD A,(HL)
  AND $91
  LD (HL),A

; Flashing with the fourth bank not full; the recharge; the shields take the
; hits, the banks what the shields cannot
;
; Front hits ($9CA3) on the front shield, aft hits ($9CA4) on the aft one, the
; drain ($9CA2, one more with CloakOn $D041) on the energy banks. All four
; banks at 0 sets TooClose: the end (1 run, the death of d1).
Damage:
  LD HL,Condition
  XOR A
  CP (HL)
  RET Z
  LD A,(BarEnergy4)
  CP $A0
  JR Z,DamageShields
  LD A,$63
  LD (Condition),A
DamageShields:
  CALL Recharge
  LD HL,BarForeShield
  LD A,(FrontHits)
  CALL ShieldHit
  LD HL,BarAftShield
  LD A,(AftHits)
  CALL ShieldHit
  LD A,(CloakOn)
  AND A
  LD A,(EnergyDrain)
  JR Z,DamageDrain
  INC A
DamageDrain:
  LD C,A
  LD B,$04

; Take C from each of B energy banks from E1 up; all empty ends the game
;
; Used by the routine at ShieldHit.
DrainBanks:
  LD HL,BarEnergy1
  LD D,$04
DrainBanksLoop:
  LD A,(HL)
  SUB C
  JR NC,DrainBanksNext
  LD (HL),$00
  INC HL
  INC HL
  DEC D
  JR NZ,DrainBanksLoop
  LD A,$01
  LD (TooClose),A
  RET
DrainBanksNext:
  LD (HL),A
  DJNZ DrainBanksLoop
  RET

; A shield (HL) loses 4 x the hit (C); past zero the banks lose the rest and
; the hit flash builds up
;
; A hit of $46 or more, or a flash count past 12, calls DamageItem
; (DamageVector $D0F3): a random loss of fuel, equipment or cargo. No hit: the
; flash count ($9ADA) goes down by one.
ShieldHit:
  LD C,A
  AND A
  JR NZ,ShieldHitNow
  LD HL,HitCount
  LD A,(HL)
  AND A
  RET Z
  DEC (HL)
  RET
ShieldHitNow:
  PUSH BC
  PUSH HL
  CP $46
  CALL NC,DamageVector
  POP HL
  POP BC
  LD B,$04
ShieldHitStep:
  LD A,(HL)
  SUB C
  JR C,ShieldDown
  LD (HL),A
  DJNZ ShieldHitStep
  RET
ShieldDown:
  LD (HL),$00
  DEC B
  RET Z
  CALL DrainBanks
  LD HL,HitCount
  LD A,(HL)
  ADD A,$05
  LD (HL),A
  CP $0D
  RET C
  JP DamageVector

; The hits that went through the shields, +5 each, cooling by one a frame
HitCount:
  DEFB $00

; One recharge step, two with the energy unit ($D08B)
;
; Used by the routine at Damage.
Recharge:
  LD A,(Equipment+$0007)
  AND A
  CALL NZ,RechargeStep

; The topmost bank not full gains 1; all full, each shield gains 1
;
; Used by the routine at Recharge.
RechargeStep:
  LD HL,BarEnergy4
  LD B,$04
RechargeBank:
  LD A,(HL)
  CP $A0
  JR Z,RechargeBankDown
  INC (HL)
  RET
RechargeBankDown:
  DEC HL
  DEC HL
  DJNZ RechargeBank
  LD HL,BarForeShield
  CALL ShieldGain
  LD HL,BarAftShield

; One more to a shield below $A0
;
; Used by the routine at RechargeStep.
ShieldGain:
  LD A,(HL)
  CP $A0
  RET Z
  INC (HL)
  RET

; The letters beside the bars and the two 2 x 2 indicators: E (ECM on) and S
; (the safe zone)
;
; Printed through PrintCode with the back-buffer switch ($D04B's byte) off, at
; text positions (row, column) $1108, $1208, $1607 and $1615.
DrawIndicators:
  LD HL,(PrintTarget)
  LD (HL),$00
  LD HL,$1108
  LD (TextColumn),HL
  LD A,$26
  CALL PrintCodeVector
  LD HL,$1208
  LD (TextColumn),HL
  LD A,$24
  CALL PrintCodeVector
  LD HL,$1607
  LD A,(ECMActive)
  AND A
  JR Z,IndicatorNoECM
  LD DE,IndicatorCodes+$0002
  JR IndicatorECM
IndicatorNoECM:
  LD DE,IndicatorCodes+$0006
IndicatorECM:
  CALL PrintBlock
  LD HL,$1615
  LD A,(SafeZone)
  AND A
  JR Z,IndicatorNoSafe
  LD DE,IndicatorCodes+$000A
  JR IndicatorSafe
IndicatorNoSafe:
  LD DE,IndicatorCodes+$000E
IndicatorSafe:
  CALL PrintBlock
  LD HL,(PrintTarget)
  LD (HL),$A9
  RET

; Print two rows of two codes from DE at HL (row, column)
;
; Used by the routine at DrawIndicators.
PrintBlock:
  CALL PrintPair

; Print two codes at HL, then the next row
;
; Used by the routine at PrintBlock.
PrintPair:
  LD (TextColumn),HL
  PUSH HL
  CALL PrintTwo
  POP HL
  INC H
  RET

; Print the codes at DE and DE+1
;
; Used by the routine at PrintPair.
PrintTwo:
  CALL PrintNext

; Print the code at DE, DE+1
;
; Used by the routine at PrintTwo.
PrintNext:
  LD A,(DE)
  PUSH DE
  CALL PrintCodeVector
  POP DE
  INC DE
  RET

; The bar letters ($26, $24) and the indicators: E on, E off, S on, S off
; (frame pieces when off)
IndicatorCodes:
  DEFB $26,$24
  DEFB $3B,$3C
  DEFB $3D,$3E
  DEFB $20,$20
  DEFB $40,$40
  DEFB $5B,$5C
  DEFB $5D,$5E
  DEFB $20,$5F
  DEFB $40,$2B

; The four missile cells at (row $17, column 2): a missile glyph ($25) for each
; left, a blank ($40) for the rest
;
; Used by the routines at ResetFlight and MissileKeys.
DrawMissiles:
  LD HL,$1702
  LD (TextColumn),HL
  LD HL,(PrintTarget)
  LD (HL),$00
  LD A,(Missiles)
  AND A
  JR Z,DrawMissilesGetMissiles
  LD B,A
DrawMissilesLeft:
  PUSH BC
  LD A,$25
  CALL PrintCodeVector
  POP BC
  DJNZ DrawMissilesLeft
DrawMissilesGetMissiles:
  LD A,(Missiles)
  NEG
  ADD A,$04
  RET Z
  LD B,A
DrawMissilesEmpty:
  PUSH BC
  LD A,$40
  CALL PrintCodeVector
  POP BC
  DJNZ DrawMissilesEmpty
  LD HL,(PrintTarget)
  LD (HL),$A9
  RET

; T arms the missile, U disarms it, F fires it at the locked target; an armed
; missile locks on the ship in the sights
;
; MissileState $D047: 0 off, 1 armed, 2 locked on MissileTarget $D0E3. The lock
; beeps through the ROM's BEEPER ($03B5, HL $70, DE $60). A fired missile is a
; new ship (ShipAction $9C9C with the target in the high nibble and action 2);
; no free slot flashes the button ($D0BD bit 7). k2 armed one (T, frame 2485),
; locked it and fired it (F from 2519, launched at 2542); a Thargoid's E.C.M.
; destroyed it.
MissileKeys:
  LD A,(Missiles)
  AND A
  RET Z
  LD A,(MissileState)
  CP $01
  JR NZ,MissileKey
  LD HL,MissileTarget
  LD A,(HL)
  AND A
  JR NZ,MissileKey
  LD A,(SightTarget)
  AND A
  JR Z,MissileKey
  LD (HL),A
  LD HL,MissileState
  LD (HL),$02
  LD HL,$0070
  LD DE,$0060
  CALL $03B5
MissileKey:
  LD HL,KeyCombat
  LD A,(HL)
  LD HL,MissileState
  SRL A
  SRL A
  JR C,MissileArm
  SRL A
  JR C,MissileFire
  SRL A
  JR C,MissileDisarm
  RET
MissileArm:
  LD A,(HL)
  CP $02
  RET Z
  LD (HL),$01
  XOR A
  LD (MissileTarget),A
  RET
MissileDisarm:
  LD (HL),$00
  RET
MissileFire:
  LD A,(HL)
  CP $02
  RET NZ
  LD A,(MissileTarget)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  OR $02
  PUSH HL
  CALL ShipActionVector
  POP HL
  JR Z,MissileGone
  LD HL,Messages
  SET 7,(HL)
  RET
MissileGone:
  LD (HL),$00
  LD HL,SoundRequests
  SET 1,(HL)
  LD HL,Missiles
  DEC (HL)
  JP DrawMissiles

; Cleared by ResetFlight; used by the next routine
MissileLaunchFlag:
  DEFB $00
