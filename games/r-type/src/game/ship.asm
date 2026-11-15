; --------------------------------------------------------------------------------------------------------------------
; ship.asm: The ship, the Force, the bits, the pick-ups, the shots, the beam and the missiles
; --------------------------------------------------------------------------------------------------------------------

; Move the homing missiles, count MissileTimer down
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveMissiles:
  LD IX,MissileLaunch
  LD IY,MissileLaunch+$0006
  CALL MoveMissile
  LD IX,MissileLaunch+$0006
  LD IY,MissileLaunch
  CALL MoveMissile
  LD A,(MissileTimer)
  AND A
  RET Z
  DEC A
  LD (MissileTimer),A
  RET

; Move one missile along its frame lists, turning toward a target
;
; Witness: L1 63293 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveMissile:
  LD A,(IX+$00)
  AND A
  RET Z
  LD H,A
  LD L,(IX+$01)
  LD C,(IX+$02)
  LD B,(IX+$03)
  LD A,(HL)
  CP $FF
  JR Z,MissileTurn
  LD A,C
  CP $1F
  JR NC,l_9411
  LD A,B
  AND A
  JR Z,l_9416
  CP $15
  JR C,l_9416
l_9411:
  LD (IX+$00),$00
  RET
l_9416:
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD A,E
  RRCA
  RRCA
  AND $0F
  CALL MoveByBits
  PUSH BC
  PUSH DE
  INC B
  CALL GetCell
  CALL SolidAny
  POP DE
  POP BC
  JR NC,l_9411
  LD (IX+$00),H
  LD (IX+$01),L
  LD (IX+$02),C
  LD (IX+$03),B
  LD A,E
  AND $03
  LD HL,DrawGame
  AND A
  JR Z,MissileDrawer
  LD HL,DrawGameMirrored
  CP $01
  JR Z,MissileDrawer
  LD HL,DrawGameFlipped
  CP $02
  JR Z,MissileDrawer
  LD HL,DrawGameBoth
MissileDrawer:
  LD (MissileDrawer+$000C),HL ; the drawer picked by the frame, patched into
                              ; the CALL below
  LD A,(FrameCounter)
  AND $01
  ADD A,D
  PUSH IX
  CALL $0000
  CALL ProcessHits
  POP IX
  JR Z,l_9411
  RET
MissileTurn:
  LD A,(IX+$05)           ; the frame list ended: the next one by state
  CP $01
  JR Z,l_949B
  CP $02
  JR Z,l_9496
  CP $03
  JR Z,l_9491
  CP $04
  JR Z,l_948C
  CP $05
  JR Z,l_9487
  LD HL,MissileTurns
  JR l_94E8
l_9487:
  LD HL,MissileTurns+$0012
  JR l_94E8
l_948C:
  INC (IX+$05)
  JR l_9487
l_9491:
  LD HL,MissileTurns+$0007
  JR l_94E8
l_9496:
  INC (IX+$05)
  JR l_9491
l_949B:
  LD DE,EnemySlots
  LD L,$1C
l_94A0:
  LD A,(DE)
  INC E
  INC E
  INC E
  AND A
  JR Z,l_94B6
  LD A,(DE)
  DEC A
  JR Z,l_94B6
  CP $20
  JR NC,l_94B6
  CP C
  JR Z,l_94C2
  DEC A
  CP C
  JR Z,l_94C2
l_94B6:
  LD A,E
  ADD A,$06
  LD E,A
  DEC L
  JR NZ,l_94A0
l_94BD:
  LD HL,MissileTurns
  JR l_94E8
l_94C2:
  LD A,(IY+$04)
  CP $14
  JR NC,l_94B6
  CP L
  JR Z,l_94B6
  LD (IX+$04),L
  INC E
  LD A,(DE)
  DEC E
  CP B
  JR Z,l_94BD
  JR NC,l_94DE
  LD A,$02
  LD HL,MissileTurns+$0003
  JR l_94E3
l_94DE:
  LD HL,MissileTurns+$000E
  LD A,$04
l_94E3:
  LD (IX+$05),A
  JR l_94E8
l_94E8:
  LD (IX+$00),H
  LD (IX+$01),L
  JP MoveMissile

; Move the ship by the controls, tilt it while it climbs or dives, test what it
; touches
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveShip:
  LD A,(ShipFrame)
  AND A
  RET Z
  LD HL,(ShipColumn)
  LD D,H
  LD E,L
  LD A,(ControlBits)
  LD B,A
  AND $0F
  JR NZ,l_951A
  LD A,(ShipFrame)
  CP $04
  JR C,l_9510
  DEC A
  LD (ShipFrame),A
  JR l_9559
l_9510:
  CP $03
  JR Z,l_9559
  INC A
  LD (ShipFrame),A
  JR l_9559
l_951A:
  BIT 0,B
  JR Z,l_951F
  DEC L
l_951F:
  BIT 1,B
  JR Z,l_9524
  INC L
l_9524:
  BIT 2,B
  JR Z,l_9534
  INC H
  LD A,(ShipFrame)
  CP $02
  JR Z,l_9534
  DEC A
  LD (ShipFrame),A
l_9534:
  BIT 3,B
  JR Z,l_9544
  DEC H
  LD A,(ShipFrame)
  CP $04
  JR Z,l_9544
  INC A
  LD (ShipFrame),A
l_9544:
  LD A,H
  CP $14
  JR C,l_954D
  AND A
  JR Z,l_954D
  LD H,D
l_954D:
  LD A,L
  AND A
  JR Z,l_9555
  CP $1D
  JR C,l_9556
l_9555:
  LD L,E
l_9556:
  LD (ShipColumn),HL
l_9559:
  LD BC,(ShipColumn)
  LD A,(ShipFrame)
  CALL DrawGame
  LD BC,(ShipColumn)
  INC C
  INC C
  INC C
  CALL GetCell
  JP NC,ShipDies
  LD A,(HitCount)
  AND A
  JP NZ,ShipDies

; While ShieldTimer runs: the shield; then the fire and detach controls
;
; Witness: L1 19736 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
ShipShield:
  LD A,(ShieldTimer)
  AND A
  JR Z,ShieldControls
  DEC A
  LD (ShieldTimer),A
  LD BC,(ShipColumn)
  DEC C
  DEC C
  LD A,$62
  CALL GameObject
  LD A,(FrameCounter)
  AND $01
  ADD A,$45
  LD (CellMark+$000F),A
  CP $45
  JR Z,l_959F
  CALL DrawSprite
  JR l_95A2
l_959F:
  CALL DrawSpriteFlipped
l_95A2:
  CALL ClearColourOverride
ShieldControls:
  NOP                     ; the patched byte: NOP in play, RET when the
                          ; controls are off
  LD A,(ControlBits)
  BIT 4,A
  JR NZ,l_95B3
  LD A,(BeamCharge)
  AND A
  JR Z,l_95B6
l_95B3:
  CALL FireBeam
l_95B6:
  LD A,(ControlBits)
  BIT 5,A
  RET Z
  LD A,(ForceLevel)
  AND A
  RET Z
  CALL ForceRecordOf
  EX DE,HL
  EX AF,AF'
  LD A,(ForceAttached)
  AND A
  JR Z,l_95EB
  CP $02
  LD A,(ShipColumn)
  JR Z,l_95DA
  CP $1A
  RET NC
  LD A,$04
  JR l_95DF
l_95DA:
  CP $04
  RET C
  LD A,$05
l_95DF:
  LD (HL),A
  XOR A
  LD (ForceAttached),A
  LD HL,$1481
  CALL PlaySound
  RET
l_95EB:
  LD A,(HL)
  CP $03
  JR Z,l_95F3
  CP $07
  RET NZ
l_95F3:
  LD (HL),$06
  RET

; Move the Force by its state, draw it, dock it at the ship
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveForce:
  LD A,(ForceRecord)
  AND A
  JR Z,l_9607
  LD BC,$7AB5
  LD HL,ForceRecord+$0001
  LD DE,$0C06
  JR l_9628
l_9607:
  LD A,(ForceRecord+$0003)
  AND A
  JR Z,l_9618
  LD BC,$7AB6
  LD HL,ForceRecord+$0004
  LD DE,$0C0C
  JR l_9628
l_9618:
  LD A,(ForceRecord+$0006)
  AND A
  JP Z,MoveCarriers
  LD BC,$7AB7
  LD HL,ForceRecord+$0007
  LD DE,$0812
l_9628:
  PUSH HL
  PUSH BC
  PUSH DE
  EX AF,AF'
  LD A,(Scratch+$0007)
  AND A
  JR Z,l_9636
  DEC A
  LD (Scratch+$0007),A
l_9636:
  EX AF,AF'
  LD BC,(ShipColumn)
  CP $01
  JR NZ,l_9649
  INC C
  INC C
  INC C
l_9642:
  DEC B
  LD (HL),C
  INC L
  LD (HL),B
  JP ForceDraw
l_9649:
  CP $02
  JR NZ,l_9652
  DEC C
  DEC C
  DEC C
  JR l_9642
l_9652:
  LD C,(HL)
  INC L
  LD B,(HL)
  DEC L
  CP $03
  JR NZ,l_96D9
  CALL ForceTarget
  SUB C
  CP $0E
  JR NC,l_968F
  CP $0D
  JR Z,l_966E
  EX AF,AF'
  CALL DirRight
  CALL ForceTry
  EX AF,AF'
l_966E:
  EX AF,AF'
  LD A,C
  CP $FA
  JR NC,l_9678
  AND A
  JR Z,l_9678
  DEC C
l_9678:
  LD DE,$0607
; This entry point is used by the routine at ForceTarget.
l_967B:
  EX AF,AF'
  CP D
  JR NZ,l_968F
  LD A,(Scratch+$0007)
  AND A
  JR NZ,l_9692
  DEC L
  LD (HL),E
  INC L
  LD A,$20
  LD (Scratch+$0007),A
  JR l_9692
; This entry point is used by the routine at ForceTarget.
l_968F:
  CALL ForceSeek
l_9692:
  LD A,(FrameCounter)
  AND $03
  JR Z,l_969D
  LD BC,(Scratch)
l_969D:
  XOR A
  LD (ForceSeekEnd),A
  JP ForceStore

; Patch the Force's seek and return the ship's column + 1
;
; Witness: L1 4 (l1).
ForceTarget:
  LD (Scratch),BC
  LD A,$C9
  LD (ForceSeekEnd),A
  LD A,(ShipColumn)
  INC A
  RET
l_96B2:
  CP $07
  JP NZ,ForceDraw
  CALL ForceTarget
  LD E,A
  LD A,C
  SUB E
  CP $0B
  JR NC,l_968F
  CP $0A
  JR Z,l_96CD
  EX AF,AF'
  CALL DirLeft
  CALL ForceTry
  EX AF,AF'
l_96CD:
  EX AF,AF'
  LD A,C
  CP $1E
  JR NC,l_96D4
  INC C
l_96D4:
  LD DE,$0403
  JR l_967B
; This entry point is used by the routine at MoveForce.
l_96D9:
  CP $04
  JR NZ,l_9700
  PUSH BC
  INC C
  INC C
  INC C
  INC B
  CALL GetCell
  CALL SolidHard
  POP BC
  LD A,$07
  JR NC,l_96FB
  LD A,C
  CP $1D
  JR NC,l_96F7
  INC C
  LD (HL),C
  JP ForceDraw
l_96F7:
  LD (HL),$1D
  LD A,$07
l_96FB:
  DEC L
  LD (HL),A
  JP ForceDraw
l_9700:
  CP $05
  JR NZ,l_9725
  PUSH BC
  DEC C
  INC B
  CALL GetCell
  CALL SolidHard
  POP BC
  LD A,$03
  JR NC,l_96FB
  LD A,C
  CP $02
  JR C,l_971F
  AND A
  JR Z,l_971F
  DEC C
  LD (HL),C
  JP ForceDraw
l_971F:
  LD (HL),$01
  LD A,$03
  JR l_96FB
l_9725:
  CP $06
  JR NZ,l_96B2
  LD A,(FrameCounter)
  AND $03
  JP NZ,ForceDraw

; Step the Force toward its target, testing the cells it would enter
;
; Witness: L1 4 (l1).
ForceSeek:
  INC B
  INC C
  LD E,$00
  LD A,(ShipRow)
  CP B
  JR Z,l_974B
  JR C,l_9745
  CALL DirUp
  CALL ForceTry
  JR l_974B
l_9745:
  CALL DirDown
  CALL ForceTry
l_974B:
  LD A,(ShipColumn)
  CP C
  JR Z,l_9761
  JR C,l_975B
  CALL DirLeft
  CALL ForceTry
  JR l_9761
l_975B:
  CALL DirRight
  CALL ForceTry
l_9761:
  CALL DirUp
  CALL ForceProbe
  CALL DirDown
  CALL ForceProbe
  CALL DirLeft
  CALL ForceProbe
  CALL DirRight
  CALL ForceProbe
  DEC B
  DEC C
  LD A,C
  CP $FE
  JR C,l_9782
  LD C,$00
l_9782:
  LD A,B
  CP $FF
  JR NZ,ForceSeekEnd
  INC B
ForceSeekEnd:
  NOP                     ; the patched RET

; ForceStore
;
; Used by the routine at MoveForce.
ForceStore:
  LD (HL),C               ; store the Force's new position
  INC L
  LD (HL),B
  JR ForceDraw

; Test the cell in direction A; carry when it is free
;
; Witness: L1 16 (l1).
ForceProbe:
  PUSH BC
  LD (ForceProbe+$0008),A
  LD A,D
  LD (ForceProbe+$0011),A
  NOP
  CALL GetCell
  CALL SolidHard
  POP BC
  RET C
  NOP
  RET

; The up probe and its opposite
;
; Witness: L1 8 (l1).
DirUp:
  LD A,$04
  LD D,$05
  RET

; The down probe and its opposite
;
; Witness: L1 4 (l1).
DirDown:
  LD A,$05
  LD D,$04
  RET

; The left probe and its opposite
;
; Witness: L1 4 (l1).
DirLeft:
  LD A,$0C
  LD D,$0D
  RET

; The right probe and its opposite
;
; Witness: L1 4 (l1).
DirRight:
  LD A,$0D
  LD D,$0C
  RET

; Patch the probe operands and test the cell
;
; Witness: L1 4 (l1).
ForceTry:
  PUSH DE
  PUSH BC
  LD (ForceTry+$000F),A
  LD (ForceTry+$0010),A
  LD (ForceTry+$001A),A
  LD A,D
  LD (l_97D2+$0007),A
  NOP
  NOP
  CALL GetCell
  CALL SolidHard
  POP BC
  JR NC,l_97D2
  NOP
  JR l_97DA
l_97D2:
  LD A,(l_97D2+$0007)
  CP $06
  JR C,l_97DA
  NOP
l_97DA:
  POP DE
  RET

; ForceDraw
;
; Used by the routines at MoveForce, ForceTarget and ForceStore.
ForceDraw:
  POP DE                  ; draw the Force, dock it when it touches the ship
  POP HL
  LD A,(HL)
  INC A
  CP D
  JR NZ,l_97E4
  XOR A
l_97E4:
  LD (HL),A
  SRL A
  ADD A,E
  LD L,A
  LD A,(ForceRecord+$0003)
  CP $02
  LD A,L
  JR NZ,l_97F6
  CALL DrawGameMirrored
  JR l_97F9
l_97F6:
  CALL DrawGame
l_97F9:
  LD A,(HitCount)
  AND A
  JR Z,l_9826
  LD HL,HitList+$0001
  LD B,A
l_9803:
  LD A,(HL)
  CP $06
  JR C,l_980D
  INC HL
  DJNZ l_9803
  JR l_9826
l_980D:
  POP HL
  LD C,(HL)
  INC C
  DEC L
  LD A,(ShipColumn)
  LD B,$01
  CP C
  JR C,l_981A
  INC B
l_981A:
  LD A,B
  LD (HL),A
  LD (ForceAttached),A
  LD HL,$1481
  CALL PlaySound
  PUSH DE
l_9826:
  POP DE
  CALL AddScoreFlag

; MoveCarriers
;
; Used by the routine at MoveForce.
MoveCarriers:
  CALL ClearHits          ; move the pick-up carriers, then the bits
  CALL MoveCarrierA
  CALL ClearHits
  CALL MoveCarrierB
  CALL ClearHits
  JP MoveBitDevices

; Move carrier A and draw it; touching the ship takes its pick-up
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveCarrierA:
  LD A,(Carriers)
  AND A
  RET Z
  LD HL,Carriers+$0002
  CALL CarrierTimer
  JR Z,l_9897
  LD HL,Carriers+$0001
  CALL NextCarrierFrame
  LD BC,(Carriers+$0002)
  LD HL,Carriers

; CarrierDraw
;
; Used by the routine at MoveCarrierB.
CarrierDraw:
  EX AF,AF'               ; draw a carrier
  PUSH HL
  LD DE,CarrierColours
  LD L,(HL)
  DEC L
  XOR A
  LD H,A
  LD (HitCount),A
  ADD HL,DE
  LD A,(HL)
  AND A
  JR NZ,l_986E
  LD A,(FrameCounter)
  AND $03
  ADD A,$42
l_986E:
  LD (CellMark+$000F),A
  EX AF,AF'
  CP $80
  JR C,l_987D
  AND $7F
  CALL DrawGameBoth
  JR l_9880
l_987D:
  CALL DrawGame
l_9880:
  XOR A
  LD (CellMark+$000F),A
  POP DE
  LD A,(HitCount)
  AND A
  RET Z
  LD HL,HitList+$0001
  LD B,A
l_988E:
  LD A,(HL)
  CP $06
  JR C,TakePickup
  INC HL
  DJNZ l_988E
  RET
; This entry point is used by the routine at MoveCarrierA.
l_9897:
  XOR A
  LD (Carriers),A
  RET
; This entry point is used by the routine at MoveCarrierB.
l_989C:
  XOR A
  LD (Carriers+$0004),A
  RET

; Move carrier B
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveCarrierB:
  LD A,(Carriers+$0004)
  AND A
  RET Z
  LD HL,Carriers+$0006
  CALL CarrierTimer
  JR Z,l_989C
  LD HL,Carriers+$0005
  CALL NextCarrierFrame
  LD BC,(Carriers+$0006)
  LD HL,Carriers+$0004
  JR CarrierDraw
; This entry point is used by the routine at CarrierDraw.
TakePickup:
  PUSH DE                 ; the ship took a pick-up: by its kind the bits, the
                          ; missiles, the shield, a laser crystal and a Force
                          ; level
  LD HL,$0D83
  CALL PlaySound
  LD DE,$0403
  CALL AddScore
  POP HL
  LD A,(HL)
  LD (HL),$00
  CP $09
  JP Z,l_9964
  CP $08
  JR Z,l_9943
  CP $07
  JR Z,l_993D
  CP $06
  JR Z,l_9931
  SUB $02
  LD (WeaponKind),A
  LD A,(ForceLevel)
  INC A
  CP $04
  JR Z,l_98EF
  LD (ForceLevel),A
l_98EF:
  CALL ForceRecordOf
  EX DE,HL
  DEC A
  JR Z,l_98F9
  CALL ForceRecordOf
l_98F9:
  EX DE,HL
  LD A,(HL)
  EX AF,AF'
  XOR A
  LD (ForceRecord),A
  LD (ForceRecord+$0003),A
  LD (ForceRecord+$0006),A
  LD A,(ForceLevel)
  CP $01
  JR NZ,l_9918
  EX DE,HL
  LD A,$04
  LD (HL),A
  INC L
  LD (HL),$00
  INC L
  LD (HL),$08
  RET
l_9918:
  EX AF,AF'
  LD (DE),A
  INC E
  INC L
  LDI
  LDI
  RET

; DE = the Force record of level A
;
; Witness: L1 20 (l1-l8).
ForceRecordOf:
  LD DE,ForceRecord
  CP $01
  RET Z
  LD DE,ForceRecord+$0003
  CP $02
  RET Z
  LD DE,ForceRecord+$0006
  RET
; This entry point is used by the routine at MoveCarrierB.
l_9931:
  LD A,$30
  LD (ShieldTimer),A
  LD DE,$0603
  CALL AddScore
  RET
; This entry point is used by the routine at MoveCarrierB.
l_993D:
  LD A,$01
  LD (MissilesOn),A
  RET
; This entry point is used by the routine at MoveCarrierB.
l_9943:
  LD HL,BitUpperOn
  LD A,(HL)
  CP $01
  JR Z,l_9964
l_994B:
  LD A,(HL)
  AND A
  RET NZ
  LD (HL),$01
  LD HL,ShipTrail
  LD BC,(ShipColumn)
  LD (HL),C
  INC L
  LD (HL),B
  LD D,H
  LD E,L
  INC E
  DEC L
  LD BC,$0006
  LDIR
  RET
; This entry point is used by the routine at MoveCarrierB.
l_9964:
  LD HL,BitLowerOn
  JR l_994B

; MoveBitDevices
;
; Used by the routine at MoveCarriers.
MoveBitDevices:
  LD A,(BitUpperOn)       ; move the two bits behind the ship's trail
  AND A
  JR Z,l_998C
  CALL TrailPoint
  DEC D
  DEC D
  DEC D
  DEC D
  LD (BitPositions),DE
  LD B,$08
  LD HL,BitPositions+$0007
  CALL BitFrame
  LD BC,(BitPositions)
  CALL DrawGame
  CALL AddScoreFlag
l_998C:
  LD A,(BitLowerOn)
  AND A
  RET Z
  CALL TrailPoint
  INC D
  INC D
  INC D
  LD (BitPositions+$0002),DE
  LD B,$08
  LD HL,BitPositions+$0008
  CALL BitFrame
  LD BC,(BitPositions+$0002)
  CALL DrawGameFlipped
  CALL AddScoreFlag
  RET

; Step a bit's animation counter; A = its sprite
;
; Witness: L1 13446 (ending, l1, l4-l8).
BitFrame:
  LD A,(HL)
  INC A
  CP $10
  JR NZ,l_99B5
  XOR A
l_99B5:
  LD (HL),A
  SRA A
  ADD A,$16
  ADD A,B
  RET

; Step a carrier's animation; A = its character from CarrierFrames
;
; Witness: L1 5737 (l1-l8).
NextCarrierFrame:
  LD A,(HL)
  INC A
  CP $08
  JR NZ,l_99C3
  XOR A
l_99C3:
  LD (HL),A
  LD B,$00
  LD C,A
  LD HL,CarrierFrames
  ADD HL,BC
  LD A,(HL)
  RET

; Count a carrier's timer down; Z when it ran out
;
; Witness: L1 5759 (l1-l8).
CarrierTimer:
  LD B,$00
  LD A,(ScrollStep)
  AND A
  RET NZ
  LD A,(HL)
  DEC A
  LD (HL),A
  CP $FE
  RET

; Store the ship's position in the trail ring
;
; Witness: L1 13446 (ending, l1, l4-l8).
TrailPoint:
  LD A,(FrameCounter)
  AND $03
  ADD A,A
  LD HL,ShipTrail
  ADD A,L
  LD L,A
  LD DE,(ShipColumn)
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  LD A,(FrameCounter)
  AND $03
  CP $03
  JR NZ,l_99F9
  LD HL,ShipTrail
l_99F9:
  LD E,(HL)
  INC L
  LD D,(HL)
  INC E
  RET

; Draw game object A at BC as stored, with the hits gathered
;
; Witness: L1 284759 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
DrawGame:
  CALL DrawPrepare
  CALL DrawSprite
  JR DrawFinish

; Draw game object A upside down
;
; Witness: L1 3528 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; gameover, hiscore, hiscore-typed, l1-l8).
DrawGameFlipped:
  CALL DrawPrepare
  CALL DrawSpriteFlipped
  JR DrawFinish

; Draw game object A mirrored
;
; Witness: L1 2112 (l1-l8).
DrawGameMirrored:
  CALL DrawPrepare
  CALL DrawSpriteMirrored
  JR DrawFinish

; Draw game object A mirrored and upside down
;
; Witness: L1 3572 (l1-l8).
DrawGameBoth:
  CALL DrawPrepare
  CALL DrawSpriteBoth
  JR DrawFinish

; GameObject A and the hit gathering on (CellFree's RET made a NOP)
;
; Witness: L1 293971 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
DrawPrepare:
  CALL GameObject
  XOR A
  LD (CellFree+$0018),A
  RET

; DrawFinish
;
; Used by the routines at DrawGame, DrawGameFlipped, DrawGameMirrored and
; DrawGameBoth.
DrawFinish:
  LD A,$C9                ; the hit gathering off again
  LD (CellFree+$0018),A
  RET

; Fire: charge the beam while fire is held, release a beam or a shot
;
; Held: BeamCharge grows and the BEAM meter with it. Released: a short charge
; fires a plain shot and the Force's lasers by WeaponKind; a longer one a beam
; by the charge.
;
; Witness: L1 14604 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; gameover, hiscore, hiscore-typed, l1-l8).
FireBeam:
  LD A,(ControlBits)
  BIT 4,A
  JR NZ,l_9A45
  LD A,(BeamCharge)
  CP $0C
  JR NC,BeamRelease
  LD DE,(ShipColumn)
  INC E
  CALL ShotFire
  JP l_9AD5
l_9A45:
  LD A,(BeamCharge)
  CP $0C
  JR NZ,l_9A52
  LD HL,$0283
  CALL PlaySound
l_9A52:
  LD A,(BitPositions+$0009)
  ADD A,$02
  AND $0F
  LD (BitPositions+$0009),A
  SRL A
  ADD A,$63
  EX AF,AF'
  LD A,(BeamCharge)
  INC A
  INC A
  CP $40
  JR Z,l_9A6D
  LD (BeamCharge),A
l_9A6D:
  CP $28
  JR NC,l_9A87
  LD HL,BeamMeter
  LD DE,BeamMeterFull
  AND $03
  JR NZ,l_9A7D
  INC (HL)
  INC E
l_9A7D:
  LD A,(HL)
  ADD A,$0B
  LD C,A
  LD B,$14
  EX DE,HL
  CALL PrintTextNormal
l_9A87:
  LD BC,(ShipColumn)
  INC C
  INC C
  INC C
  DEC B
  LD A,(ForceAttached)
  CP $01
  JR NZ,l_9A99
  INC C
  INC C
  INC C
l_9A99:
  EX AF,AF'
  CALL GameObject
  CALL DrawSprite
  JR l_9AE8
BeamRelease:
  LD DE,$181E             ; release the charged beam
  LD A,(BeamCharge)
  CP $24
  JR NC,l_9AB6
  LD DE,$1714
  CP $14
  JR NC,l_9AB6
  LD DE,$160A
l_9AB6:
  LD HL,BeamShot
  LD BC,(ShipColumn)
  LD A,(ForceAttached)
  AND A
  JR Z,l_9AC6
  INC C
  INC C
  INC C
l_9AC6:
  LD (HL),D
  INC L
  LD (HL),B
  INC L
  LD (HL),C
  LD A,E
  LD (BeamPower),A
  LD HL,$0543
  CALL PlaySound
l_9AD5:
  XOR A
  LD (BeamCharge),A
  LD (BitPositions+$0009),A
  LD (BeamMeter),A
  LD BC,$140B
  LD HL,BeamMeterEmpty
  CALL PrintTextNormal
l_9AE8:
  LD A,(ForceRecord)
  AND A
  JR Z,l_9B07
  LD A,(ForceAttached)
  AND A
  JR NZ,l_9B07
  LD A,(ControlBits)
  BIT 4,A
  JP NZ,FireBits
  LD DE,(ForceRecord+$0001)
  INC D
  CALL ShotFire
  JP FireBits
l_9B07:
  LD A,(ForceRecord+$0003)
  AND A
  JR Z,l_9B57
  LD A,(ControlBits)
  BIT 4,A
  JP NZ,FireBits
  LD A,(ForceAttached)
  AND A
  JR NZ,l_9B27
  LD DE,(ForceRecord+$0004)
  INC D
  INC C
  CALL ShotFireDouble
  JP FireBits
l_9B27:
  LD A,(WeaponKind)
  CP $03
  JR Z,l_9B3C
  CP $02
  JR Z,l_9B37
  LD A,$03
  JP l_9BDE
l_9B37:
  LD A,$03
  JP l_9C42
l_9B3C:
  XOR A
  LD (l_9D33+$000C),A
  LD BC,$7AAB
  LD DE,ForceRecord+$0004
  CALL ForceShotA
  LD A,$03
  LD (l_9D33+$000C),A
  LD BC,$7AAB
  LD DE,ForceRecord+$0004
  CALL ForceShotB
l_9B57:
  LD A,(ForceRecord+$0006)
  AND A
  JP Z,FireMissiles
  LD A,(ControlBits)
  BIT 4,A
  JP NZ,FireMissiles
  LD A,(ForceAttached)
  AND A
  JR NZ,l_9B76
  LD DE,(ForceRecord+$0007)
  CALL ShotFireTriple
  JP FireMissiles
l_9B76:
  LD A,(WeaponKind)
  AND $7F
  CP $01
  JR Z,l_9BDC
  CP $02
  JP Z,ForceGround
  CP $03
  JP NZ,FireMissiles
  LD HL,AntiAirShots
  LD A,(HL)
  AND A
  JR NZ,l_9B9A
  PUSH HL
  LD HL,$1641
  CALL PlaySound
  POP HL
  JR l_9BAA
l_9B9A:
  LD HL,AntiAirShots+$0004
  LD A,(HL)
  AND A
  JP NZ,FireMissiles
  PUSH HL
  LD HL,$1641
  CALL PlaySound
  POP HL
l_9BAA:
  LD A,(ForceAttached)
  CP $02
  JR Z,l_9BC6
  LD (HL),$01
  INC L
  LD (HL),$1F
  INC L
  LD DE,(ShipColumn)
  DEC D
  DEC D
  DEC D
  INC E
  INC E
  LD (HL),E
  INC L
  LD (HL),D
  JP FireMissiles
l_9BC6:
  LD (HL),$81
  INC L
  LD (HL),$FB
  INC L
  LD DE,(ShipColumn)
  LD A,D
  SUB $03
  LD D,A
  DEC E
  DEC E
  LD (HL),E
  INC L
  LD (HL),D
  JP FireMissiles
l_9BDC:
  LD A,$0F
l_9BDE:
  LD (l_A157+$000A),A
  LD (BounceEnd+$0005),A
  INC A
  LD (l_A1C4+$0002),A
  LD DE,(ShipColumn)
  LD A,(ForceAttached)
  CP $02
  JR Z,l_9C1E
  LD A,E
  ADD A,$05
  LD E,A
  LD A,$06
  PUSH AF
  LD A,$04
  PUSH AF
  LD A,$02
l_9BFF:
  LD HL,MissileA
  LD BC,$7AF3
  CALL StartMissile
  LD HL,MissileB
  LD BC,$7AF4
  POP AF
  CALL StartMissile
  LD HL,MissileC
  LD BC,$7AF5
  POP AF
  CALL StartMissile
  JR FireMissiles
l_9C1E:
  LD A,E
  SUB $03
  LD E,A
  LD A,$05
  PUSH AF
  LD A,$03
  PUSH AF
  LD A,$01
  JR l_9BFF

; Start a homing missile record HL if free
;
; Witness: L1 2850 (l1-l5, l8).
StartMissile:
  EX AF,AF'
  LD A,(HL)
  AND A
  RET NZ
  EX AF,AF'

; Write a record at HL
;
; Witness: L1 1990 (l1-l8).
StartRecord:
  LD (HL),$01
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  LD (HL),A
  LD A,(FrameCounter)
  ADD A,$20
  LD (BC),A
  RET

; ForceGround
;
; Used by the routine at FireBeam.
ForceGround:
  LD A,$07                ; the ground laser
; This entry point is used by the routine at FireBeam.
l_9C42:
  LD (BitStep+$002F),A
  LD (l_A3AC+$000A),A
  LD (BitEnd+$0005),A
  INC A
  LD (DrawBitTrail+$0002),A
  LD HL,$5EE4
  LD A,(HL)
  LD HL,$5FA5
  ADD A,(HL)
  AND A
  JR NZ,FireMissiles
  LD DE,(ShipColumn)
  LD A,(ForceAttached)
  CP $02
  JR NZ,l_9C6B
  DEC E
  LD HL,l_A3A4
  JR l_9C72
l_9C6B:
  LD A,E
  ADD A,$05
  LD E,A
  LD HL,l_A3A9
l_9C72:
  LD (l_A29A+$0007),HL
  LD (l_A2A6+$0007),HL
  XOR A
  LD (MissileTimer+$0001),A
  LD (MissileTimer+$0002),A
  LD (MissileTimer+$0003),A
  DEC D
  LD HL,$5EE4
  LD A,$01
  CALL StartRecord
  LD HL,$5FA5
  LD A,$02
  CALL StartRecord
  LD HL,$1C41
  CALL PlaySound

; FireMissiles
;
; Used by the routines at FireBeam and ForceGround.
FireMissiles:
  LD A,(MissilesOn)       ; launch the homing missiles when fitted and free
  AND A
  JR Z,FireBits
  LD A,(MissileTimer)
  AND A
  JR NZ,FireBits
  LD A,(MissileLaunch)
  AND A
  JR NZ,FireBits
  LD A,(MissileLaunch+$0006)
  AND A
  JR NZ,FireBits
  LD A,$20
  LD (MissileTimer),A
  LD IX,MissileLaunch
  LD BC,(ShipColumn)
  LD HL,MissileFrames
  DEC B
  LD (IX+$00),H
  LD (IX+$01),L
  LD (IX+$02),C
  LD (IX+$03),B
  XOR A
  LD (IX+$04),A
  LD (IX+$0A),A
  INC A
  INC B
  LD (IX+$05),A
  LD (IX+$0B),A
  LD (IX+$09),B
  LD (IX+$08),C
  LD HL,MissileFrames+$000B
  LD (IX+$07),L
  LD (IX+$06),H
  LD HL,$0681
  CALL PlaySound

; FireBits
;
; Used by the routines at FireBeam and FireMissiles.
FireBits:
  LD A,(BitUpperOn)       ; the bits' shots
  AND A
  JR Z,l_9D42
  LD A,(ControlBits)
  BIT 4,A
  JR NZ,l_9D42
  XOR A
  LD (l_9D33+$000C),A
  LD BC,$7AAE
  LD DE,BitPositions
  CALL ForceShotA
  JR l_9D42

; Fire a reflect-laser pair from ForceShotsA
;
; Witness: L1 1947 (l1, l4-l8).
ForceShotA:
  LD HL,ForceShotsA
  JR ForceShotFrom

; Fire a reflect-laser pair from ForceShotsB
;
; Witness: L1 205 (l7).
ForceShotB:
  LD HL,ForceShotsB

; ForceShotFrom
;
; Used by the routine at ForceShotA.
ForceShotFrom:
  LD A,(BC)               ; the shot into the first free pair
  AND A
  RET Z
  CP $03
  RET NC
  LD A,(ForceAttached)
  AND A
  RET Z
  LD A,(WeaponKind)
  CP $03
  RET NZ
  LD B,$02
l_9D29:
  LD A,(HL)
  AND A
  JR Z,l_9D33
  INC L
  INC L
  INC L
  DJNZ l_9D29
  RET
l_9D33:
  LD A,(ForceAttached)
  RRCA
  RRCA
  LD (HL),A
  INC L
  EX DE,HL
  LDI
  LD A,(HL)
  ADD A,$00
  LD (DE),A
  RET
; This entry point is used by the routine at FireBits.
l_9D42:
  LD A,(BitLowerOn)
  AND A
  RET Z
  LD A,(ControlBits)
  BIT 4,A
  RET NZ
  LD A,$01
  LD (l_9D33+$000C),A
  LD BC,$7AAE
  LD DE,BitPositions+$0002
  CALL ForceShotB
  RET

; Start a plain ship shot
;
; Witness: L1 3769 (c1, continue, gameover, hiscore, hiscore-typed, l1-l8).
ShotFire:
  CALL FreeShot
  LD (HL),$18
  INC L
  LD (HL),E
  INC L
  LD (HL),D
; This entry point is used by the routine at ShotFireDouble.
ShotSound:
  LD HL,$0121             ; sound 1
  CALL PlaySound
  RET

; Start the three-way shot
;
; No recording ran it: known only from the code.
ShotFireTriple:
  CALL ShotFireDiagonal

; Start the two-cell shot
;
; No recording ran it: known only from the code.
ShotFireDouble:
  CALL FreeShot
  LD A,$19
  CALL ShotStore
  CALL FreeShot
  LD A,$1A
  CALL ShotStore
  JR ShotSound

; Start the diagonal pair
;
; No recording ran it: known only from the code.
ShotFireDiagonal:
  CALL FreeShot
  INC E
  LD A,$21
  CALL ShotStore
  CALL FreeShot
  INC D
  LD A,$32

; Write the shot A at E, D into the record HL
;
; No recording ran it: known only from the code.
ShotStore:
  LD (HL),A
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  RET

; HL = a free ship shot record; none: return to the caller's caller
;
; Witness: L1 3769 (c1, continue, gameover, hiscore, hiscore-typed, l1-l8).
FreeShot:
  LD HL,ShipShots
  LD B,$10
l_9D9B:
  LD A,(HL)
  AND A
  RET Z
  INC L
  INC L
  INC L
  DJNZ l_9D9B
  POP HL
  RET

; Move the ship's shots and draw them; a shot leaving the field or hitting
; scenery ends
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveShipShots:
  LD HL,ShipShots
  LD B,$10
l_9DAA:
  PUSH BC
  LD A,(HL)
  AND A
  JR NZ,l_9DB6
l_9DAF:
  INC L
  INC L
l_9DB1:
  INC L
  POP BC
  DJNZ l_9DAA
  RET
l_9DB6:
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  CALL MoveByBits
  PUSH AF
  AND $0F
  CP $03
  JR C,l_9DC7
  INC C
  JR l_9DCA
l_9DC7:
  CALL MoveByBits
l_9DCA:
  POP AF
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,$2D
  EX AF,AF'
  LD A,B
  CP $14
  JR NC,l_9DF4
  LD A,C
  CP $1F
  JR NC,l_9DF4
  CALL GetCell
  CP $FB
  JR NC,l_9DF4
  LD (HL),B
  DEC L
  LD (HL),C
  INC L
  PUSH HL
  EX AF,AF'
  CALL DrawGame
  CALL AddScoreFlag
  POP HL
  JR NZ,l_9DB1
l_9DF4:
  DEC L
  DEC L
  LD (HL),$00
  JR l_9DAF

; Move the reflect-laser pairs, bouncing off the scenery
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveForceShots:
  LD HL,ForceShotsA
  LD B,$04
l_9DFF:
  PUSH BC
  LD A,(HL)
  AND A
  JR NZ,l_9E0B
l_9E04:
  INC L
l_9E05:
  INC L
  INC L
  POP BC
  DJNZ l_9DFF
  RET
l_9E0B:
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  INC C
  INC C
  BIT 7,A
  JR Z,l_9E19
  DEC C
  DEC C
  DEC C
  DEC C
l_9E19:
  EX AF,AF'
  LD A,C
  CP $1F
  JR NC,l_9E65
  CALL GetCell
  CALL SolidAny
  JR NC,l_9E65
  INC DE
  INC DE
  INC DE
  INC DE
  LD A,(DE)
  CP $FB
  JR NC,l_9E65
  EX AF,AF'
  PUSH HL
  PUSH BC
  BIT 7,A
  JR Z,l_9E46
  LD HL,DrawGameMirrored
  LD A,(FrameCounter)
  AND $01
  JR Z,l_9E53
  LD HL,DrawGameBoth
  JR l_9E53
l_9E46:
  LD HL,DrawGame
  LD A,(FrameCounter)
  AND $01
  JR Z,l_9E53
  LD HL,DrawGameFlipped
l_9E53:
  LD (l_9E53+$0006),HL
  LD A,$33
  CALL DrawGame
  CALL AddScoreFlag
  POP BC
  POP HL
  LD (HL),B
  DEC L
  LD (HL),C
  JR l_9E05
l_9E65:
  DEC L
  DEC L
  LD (HL),$00
  JR l_9E04

; Move the beam shot, ending it at scenery
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveBeam:
  LD HL,BeamShot
  LD A,(HL)
  AND A
  RET Z
  EX AF,AF'
  INC L
  LD B,(HL)
  INC L
  LD A,(HL)
  ADD A,$02
  LD (HL),A
  CP $1F
  JR NC,l_9ECD
  LD C,A
  CALL GetCell
  JR NC,l_9ECD
  INC DE
  LD A,(DE)
  CP $FB
  JR NC,l_9ECD
  INC DE
  LD A,(DE)
  CP $FB
  JR NC,l_9ECD
  INC DE
  LD A,(DE)
  CP $FB
  JR NC,l_9ECD
  INC DE
  LD A,(DE)
  CP $FB
  JR NC,l_9ECD
  EX AF,AF'
  PUSH AF
  EX AF,AF'
  PUSH BC
  CALL DrawBeam
  POP BC
  POP DE
  LD A,(BeamPower)
  AND A
  JR Z,l_9ECD
  LD A,D
  EX AF,AF'
  CALL DrawBeam
  LD A,(BeamPower)
  AND A
  JR Z,l_9ECD
  RET

; Draw the beam's segment
;
; Witness: L1 1887 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; gameover, hiscore, hiscore-typed, l1-l8).
DrawBeam:
  LD A,(FrameCounter)
  AND $01
  JR Z,l_9EC5
  EX AF,AF'
  CALL DrawGameFlipped
  CALL AddScoreFlag
  RET
l_9EC5:
  EX AF,AF'
  CALL DrawGame
  CALL AddScoreFlag
  RET
; This entry point is used by the routine at MoveBeam.
l_9ECD:
  XOR A
  LD (BeamShot),A
  LD (BeamPower),A
  RET

; MoveAntiAir
;
; Used by the routine at MoveBitUnits.
MoveAntiAir:
  LD HL,AntiAirShots      ; move the two anti-air shots
  CALL MoveAntiAirShot
  LD HL,AntiAirShots+$0004
  CALL MoveAntiAirShot
  JP ClearColourOverride

; Move an anti-air shot along AntiAirPathUp or AntiAirPathDown
;
; Witness: L1 54107 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveAntiAirShot:
  LD (Scratch+$0004),HL
  LD A,(HL)
  AND A
  RET Z
  CP $80
  JP NC,AntiAirDown
  LD DE,AntiAirPathUp
  CALL ShotPathStep
  LD (Scratch),BC
  LD (Scratch+$0002),DE
  JR l_9F4F
l_9EFF:
  LD A,(FrameCounter)
  AND $01
  ADD A,A
  ADD A,$43
  LD (CellMark+$000F),A
  LD A,D
  CP $43
  JR NZ,l_9F15
  DEC A
  CALL DrawGameMirrored
  JR l_9F18
l_9F15:
  CALL DrawGame
l_9F18:
  CALL AddScoreFlag
  LD BC,(Scratch)
  LD DE,(Scratch+$0002)
  INC B
  INC B
  INC B
  LD A,(FrameCounter)
  AND $01
  XOR $01
  ADD A,A
  ADD A,$43
  LD (CellMark+$000F),A
  LD A,D
  CP $43
  JR NZ,l_9F3E
  DEC A
  CALL DrawGameBoth
  JR l_9F41
l_9F3E:
  CALL DrawGameFlipped
l_9F41:
  CALL AddScoreFlag
  LD A,(Scratch+$0006)
  AND A
  RET Z
  LD HL,(Scratch+$0004)
  LD (HL),$00
  RET
l_9F4F:
  INC B
  INC B
  INC B
  INC C
  CALL GetCell
  CP $FB
  JR NC,ShotEnd
  LD B,$05
l_9F5C:
  INC E
  LD A,(DE)
  CP $FB
  JR NC,ShotEnd
  DJNZ l_9F5C
  LD BC,(Scratch)
  LD DE,(Scratch+$0002)
  JR l_9EFF

; Step a shot along its path table; $63 ends it
;
; Witness: L1 1473 (l1).
ShotPathStep:
  INC (HL)
  DEC A
  ADD A,A
  ADD A,E
  LD E,A
  LD A,(DE)
  CP $63
  JR NZ,l_9F7E
  LD (HL),$00
  POP DE
  JP ClearColourOverride
l_9F7E:
  INC L
  LD C,(HL)
  INC L
  ADD A,(HL)
  CP $FA
  JR NC,l_9F91
  CP C
  JR C,l_9F91

; ShotEnd
;
; Used by the routines at MoveAntiAirShot and AntiAirDown.
ShotEnd:
  DEC L                   ; end the shot
  DEC L
  LD (HL),$00
  POP DE
  JP ClearColourOverride
; This entry point is used by the routine at ShotPathStep.
l_9F91:
  LD (HL),A
  LD C,A
  INC L
  INC E
  LD A,(DE)
  LD D,A
  LD B,(HL)
  RET

; AntiAirDown
;
; Used by the routine at MoveAntiAirShot.
AntiAirDown:
  AND $7F                 ; the downward shot
  LD DE,AntiAirPathDown
  CALL ShotPathStep
  LD (Scratch),BC
  LD (Scratch+$0002),DE
  JR l_9FFB
l_9FAB:
  LD A,(FrameCounter)
  AND $01
  ADD A,A
  ADD A,$43
  LD (CellMark+$000F),A
  LD A,D
  CP $43
  JR NZ,l_9FC1
  DEC A
  CALL DrawGame
  JR l_9FC4
l_9FC1:
  CALL DrawGameMirrored
l_9FC4:
  CALL AddScoreFlag
  LD BC,(Scratch)
  LD DE,(Scratch+$0002)
  INC B
  INC B
  INC B
  LD A,(FrameCounter)
  AND $01
  XOR $01
  ADD A,A
  ADD A,$43
  LD (CellMark+$000F),A
  LD A,D
  CP $43
  JR NZ,l_9FEA
  DEC A
  CALL DrawGameFlipped
  JR l_9FED
l_9FEA:
  CALL DrawGameBoth
l_9FED:
  CALL AddScoreFlag
  LD A,(Scratch+$0006)
  AND A
  RET Z
  LD HL,(Scratch+$0004)
  LD (HL),$00
  RET
l_9FFB:
  INC B
  INC B
  INC B
  LD A,C
  ADD A,$05
  LD C,A
  CALL GetCell
  CP $FB
  JP NC,ShotEnd
  LD B,$05
l_A00C:
  DEC E
  LD A,(DE)
  CP $FB
  JP NC,ShotEnd
  DJNZ l_A00C
  LD BC,(Scratch)
  LD DE,(Scratch+$0002)
  JR l_9FAB

; Move the three missile records, then the bit units
;
; Witness: L1 27064 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveMissileSet:
  LD A,(FrameCounter)
  AND $03
  ADD A,$43
  LD (CellMark+$000F),A
  LD HL,MissileA
  LD DE,Font+$0003
  CALL MoveMissileRec
  LD HL,MissileB
  LD DE,Font+$0004
  CALL MoveMissileRec
  LD HL,MissileC
  LD DE,Font+$0005
  CALL MoveMissileRec
  CALL ClearColourOverride
  JP MoveBitUnits

; Move one missile record and draw its trail
;
; Witness: L1 81192 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveMissileRec:
  LD A,(HL)
  AND A
  RET Z
  PUSH DE
  PUSH HL
  PUSH HL
  LD (Scratch+$0004),A
  CALL BounceShot
  POP HL
  CALL BounceShot
  POP HL
  POP DE
  CALL DrawTrail
  RET

; One step of a reflected shot: the next direction by the cells around it
; (ForceShotTurns)
;
; Witness: L1 24156 (l1-l5, l8).
BounceShot:
  LD A,(HL)
  LD (BitPositions+$000A),A
  INC A
  LD (HL),A
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  LD A,C
  DEC A
  CP $1E
  JP NC,BounceEnd
  LD A,B
  CP $14
  JP NC,BounceEnd
  INC L
  PUSH BC
  PUSH HL
  CALL GetCellWindow
  POP HL
  POP BC
  LD A,(HL)
  CP $01
  JR Z,l_A09B
  CP $02
  JP Z,l_A0FA
  CP $03
  JP Z,l_A10A
  CP $04
  JP Z,l_A11B
  CP $05
  JP Z,l_A12C
  JP l_A13C
l_A09B:
  LD IY,ForceShotTurns
  LD A,(IX+$03)
  LD D,(IX+$01)
  LD E,(IX+$00)
l_A0A8:
  LD (IY+$00),A
  LD (IY+$01),D
  LD (IY+$03),E
  CALL SolidAny
  JR C,l_A0E7
  LD A,(IY+$01)
  CALL SolidAny
  JR C,l_A0C4
  LD A,(IY+$02)
  JP l_A14C
l_A0C4:
  LD A,(IY+$03)
  CALL SolidAny
  JR C,l_A0D7
  LD A,(IY+$04)
  ADD A,B
  LD B,A
  LD A,(IY+$05)
  JP l_A14C
l_A0D7:
  LD A,(IY+$04)
  ADD A,B
  LD B,A
  LD A,(IY+$06)
  ADD A,C
  LD C,A
  LD A,(IY+$07)
  JP l_A14C
l_A0E7:
  LD A,(IY+$03)
  CALL SolidAny
  JR C,l_A0D7
  LD A,(IY+$06)
  ADD A,C
  LD C,A
  LD A,(IY+$08)
  JP l_A14C
l_A0FA:
  LD IY,ForceShotTurns+$0009
  LD A,(IX+$05)
  LD D,(IX+$01)
  LD E,(IX+$02)
  JP l_A0A8
l_A10A:
  LD A,(IX+$03)
  CALL SolidAny
  JR NC,l_A117
  DEC C
  LD A,$03
  JR l_A14C
l_A117:
  LD A,$04
  JR l_A14C
l_A11B:
  LD A,(IX+$05)
  CALL SolidAny
  JR NC,l_A128
  INC C
  LD A,$04
  JR l_A14C
l_A128:
  LD A,$03
  JR l_A14C
l_A12C:
  LD IY,ForceShotTurns+$0012
  LD A,(IX+$03)
  LD D,(IX+$07)
  LD E,(IX+$06)
  JP l_A0A8
l_A13C:
  LD IY,ForceShotTurns+$001B
  LD A,(IX+$05)
  LD D,(IX+$07)
  LD E,(IX+$08)
  JP l_A0A8
l_A14C:
  CP (HL)
  JR Z,l_A157
  PUSH HL
  LD HL,$1841
  CALL PlaySound
  POP HL
l_A157:
  LD (HL),A
  DEC L
  LD (HL),B
  DEC L
  LD (HL),C
  LD A,(BitPositions+$000A)
  DEC A
  AND $0F
  INC A
  LD E,A
  ADD A,A
  ADD A,E
  ADD A,L
  LD E,A
  LD D,H
  LD BC,$0003
  LDIR
  RET
BounceEnd:
  LD A,(BitPositions+$000A) ; the shot left the field
  DEC A
  AND $0F
  INC A
  LD E,A
  ADD A,A
  ADD A,E
  ADD A,L
  DEC A
  LD L,A
  LD (HL),$00
  RET

; Copy the 3 x 3 cells around BC
;
; Witness: L1 13408 (l1-l5, l8).
GetCellWindow:
  DEC B
  DEC C
  CALL GetCell
  EX DE,HL
  LD DE,$5F9C
  LD IX,$5F9C
  CALL CellWindowRow
  CALL CellWindowRow
  CALL CellWindowRow
  RET

; One row of 3 cells
;
; Witness: L1 40224 (l1-l5, l8).
CellWindowRow:
  PUSH BC
  LD A,B
  CP $14
  JR C,l_A1A8
  XOR A
  LD (DE),A
  INC HL
  INC D
  LD (DE),A
  INC HL
  INC D
  LD (DE),A
  INC HL
  INC D
  JR l_A1AE
l_A1A8:
  LDI
  LDI
  LDI
l_A1AE:
  LD BC,$001D
  ADD HL,BC
  POP BC
  INC B
  RET

; Draw a missile's trail
;
; Witness: L1 12078 (l1-l5, l8).
DrawTrail:
  LD A,(DE)
  LD C,A
  LD A,(FrameCounter)
  CP C
  JR NZ,l_A1C4
  LD BC,$0034
  CALL ClearBlock
  RET
l_A1C4:
  PUSH HL
  LD B,$10
  LD A,B
  LD (BitPositions+$000A),A
  LD A,L
  ADD A,$04
  LD L,A
l_A1CF:
  LD A,(HL)
  AND A
  JR NZ,l_A1DF
  INC L
  INC L
  INC L
  LD A,(BitPositions+$000A)
  DEC A
  LD (BitPositions+$000A),A
  JR l_A20C
l_A1DF:
  PUSH BC
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD A,(HL)
  INC L
  ADD A,$33
  PUSH HL
  EX AF,AF'
  CALL GetCell
  CP $80
  JR C,l_A203
  CP $A0
  JR NC,l_A203
  CALL SlotFlags
  JR NZ,l_A203
  POP HL
  POP BC
  DEC L
  DEC L
  DEC L
  LD (HL),$00
  JR l_A1CF
l_A203:
  EX AF,AF'
  CALL DrawGame
  CALL ProcessHits
  POP HL
  POP BC
l_A20C:
  DJNZ l_A1CF
  POP HL
  LD A,(BitPositions+$000A)
  AND A
  RET NZ
  LD (HL),B
  RET

; MoveBitUnits
;
; Used by the routine at MoveMissileSet.
MoveBitUnits:
  LD HL,$5EE4             ; move the bit units
  XOR A
  LD (MissileTimer+$0004),A
  CALL MoveBitUnit
  LD HL,$5FA5
  LD A,$01
  LD (MissileTimer+$0004),A
  CALL MoveBitUnit
  JP MoveAntiAir

; Move one bit unit and draw it
;
; Witness: L1 54128 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
MoveBitUnit:
  LD A,(HL)
  AND A
  RET Z
  XOR A
  LD (MissileTimer+$0001),A
  PUSH HL
  PUSH HL
  CALL BitStep
  POP HL
  LD A,$01
  LD (MissileTimer+$0001),A
  CALL BitStep
  POP HL
  CALL DrawBitTrail
  RET

; One step of a bit unit by the cells around it
;
; Witness: L1 24346 (l3-l8).
BitStep:
  LD A,(HL)
  LD (BitPositions+$000B),A
  INC A
  LD (HL),A
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  LD A,C
  DEC A
  CP $1E
  JP NC,BitEnd
  AND A
  JP Z,BitEnd
  LD A,B
  CP $14
  JP NC,BitEnd
  AND A
  JP Z,BitEnd
  INC L
  LD A,(HL)
  CP $03
  JR C,l_A27B
  LD A,(MissileTimer+$0001)
  AND A
  JR NZ,l_A27B
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_A27B
  DEC C
l_A27B:
  CALL ReadCellWindow
  LD A,(HL)
  CP $01
  JR Z,l_A29A
  CP $02
  JP Z,l_A2A6
  CP $03
  JP Z,l_A2B2
  CP $04
  JP Z,l_A2ED
  CP $05
  JP Z,l_A328
  JP l_A35C
l_A29A:
  LD A,(IX+$02)
  CALL SolidAny
  JP NC,l_A3A9
  JP l_A390
l_A2A6:
  LD A,(IX+$07)
  CALL SolidAny
  JP NC,l_A3A9
  JP l_A395
l_A2B2:
  LD A,(IX+$02)
  CALL SolidAny
  JR C,l_A2CF
  LD A,(IX+$04)
  CALL SolidAny
  JP C,l_A3A4
  LD A,(IX+$05)
  CALL SolidAny
  JP C,l_A3A9
  JP l_A39F
l_A2CF:
  LD A,(IX+$04)
  CALL SolidAny
  JP NC,l_A39A
  LD A,(IX+$05)
  CALL SolidAny
  JP NC,l_A39A
  LD A,(IX+$06)
  CALL SolidAny
  JP NC,l_A3A4
  JP l_A3A9
l_A2ED:
  LD A,(IX+$07)
  CALL SolidAny
  JR C,l_A30A
  LD A,(IX+$04)
  CALL SolidAny
  JP C,l_A3A4
  LD A,(IX+$05)
  CALL SolidAny
  JP C,l_A3A9
  JP l_A39A
l_A30A:
  LD A,(IX+$04)
  CALL SolidAny
  JP NC,l_A39F
  LD A,(IX+$05)
  CALL SolidAny
  JP NC,l_A39F
  LD A,(IX+$01)
  CALL SolidAny
  JP NC,l_A3A4
  JP l_A3A9
l_A328:
  LD A,(IX+$04)
  CALL SolidAny
  JR C,l_A342
  LD A,(IX+$02)
  CALL SolidAny
  JR C,l_A39A
  LD A,(IX+$07)
  CALL SolidAny
  JR C,l_A39F
  JR l_A3A9
l_A342:
  LD A,(IX+$02)
  CALL SolidAny
  JR NC,l_A3A4
  LD A,(IX+$07)
  CALL SolidAny
  JR NC,l_A3A4
  LD A,(IX+$03)
  CALL SolidAny
  JR NC,l_A39A
  JR l_A39F
l_A35C:
  LD A,(IX+$05)
  CALL SolidAny
  JR C,l_A376
  LD A,(IX+$02)
  CALL SolidAny
  JR C,l_A39A
  LD A,(IX+$07)
  CALL SolidAny
  JR C,l_A39F
  JR l_A3A4
l_A376:
  LD A,(IX+$02)
  CALL SolidAny
  JR NC,l_A3A9
  LD A,(IX+$07)
  CALL SolidAny
  JR NC,l_A3A9
  LD A,(IX+$01)
  CALL SolidAny
  JR NC,l_A39A
  JR l_A39F
l_A390:
  LD A,$01
  DEC B
  JR l_A3AC
l_A395:
  LD A,$02
  INC B
  JR l_A3AC
l_A39A:
  LD A,$03
  DEC B
  JR l_A3AC
l_A39F:
  LD A,$04
  INC B
  JR l_A3AC
l_A3A4:
  LD A,$05
  DEC C
  JR l_A3AC
l_A3A9:
  LD A,$06
  INC C
l_A3AC:
  LD (HL),A
  DEC L
  LD (HL),B
  DEC L
  LD (HL),C
  LD A,(BitPositions+$000B)
  DEC A
  AND $07
  INC A
  LD E,A
  ADD A,A
  ADD A,E
  ADD A,L
  LD E,A
  LD D,H
  LDI
  LDI
  LDI
  RET
BitEnd:
  LD A,(BitPositions+$000B) ; the bit left the field
  DEC A
  AND $07
  INC A
  LD E,A
  ADD A,A
  ADD A,E
  ADD A,L
  DEC A
  LD L,A
  LD (HL),$00
  RET

; Draw a bit unit's trail
;
; Witness: L1 12173 (l3-l8).
DrawBitTrail:
  PUSH HL
  LD A,$08
  LD B,A
  LD (BitPositions+$000B),A
  LD A,L
  ADD A,$04
  LD L,A
l_A3E0:
  LD A,(HL)
  AND A
  JR NZ,l_A3F0
  INC L
  INC L
  INC L
  LD A,(BitPositions+$000B)
  DEC A
  LD (BitPositions+$000B),A
  JR l_A427
l_A3F0:
  PUSH BC
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  INC L
  PUSH HL
  DEC C
  CALL BitHits
  ADD A,$3A
  CALL DrawGame
  CALL ProcessHits
  POP HL
  POP BC
  JR NZ,l_A413
  LD A,(Scratch+$0006)
  AND A
  JR NZ,l_A413
  CALL BitHits
  LD A,$01
  LD (DE),A
l_A413:
  CALL BitHits
  AND A
  JR Z,l_A427
  LD A,L
  DEC L
  DEC L
  DEC L
  LD (HL),$00
  LD L,A
  LD A,(BitPositions+$000B)
  DEC A
  LD (BitPositions+$000B),A
l_A427:
  DJNZ l_A3E0
  POP HL
  LD A,(BitPositions+$000B)
  AND A
  RET NZ
  LD (HL),A
  RET

; Read the cells around BC
;
; Witness: L1 19099 (l3-l8).
ReadCellWindow:
  LD IX,$5F9C
  PUSH HL
  DEC B
  DEC C
  CALL GetCell
  INC C
  INC B
  EX DE,HL
  LD DE,$001E
  LD A,(HL)
  LD (IX+$01),A
  INC L
  LD A,(HL)
  LD (IX+$02),A
  INC L
  LD A,(HL)
  LD (IX+$03),A
  ADD HL,DE
  LD A,(HL)
  LD (IX+$04),A
  INC L
  INC L
  LD A,(HL)
  LD (IX+$05),A
  ADD HL,DE
  LD A,(HL)
  LD (IX+$06),A
  INC L
  LD A,(HL)
  LD (IX+$07),A
  INC L
  LD A,(HL)
  LD (IX+$08),A
  POP HL
  RET

; Test A for hard scenery
;
; Witness: L1 21 (l1).
SolidHard:
  CP $FB
  RET NC
  JR SolidTest

; Test A for any blocking cell
;
; Witness: L1 78558 (l1-l8).
SolidAny:
  CP $FA
  RET NC

; SolidTest
;
; Used by the routine at SolidHard.
SolidTest:
  CP $80                  ; the enemy-cell part
  RET C
  CP $9C
  RET Z
  PUSH HL
  CALL SlotFlags
  POP HL
  JR Z,l_A482
  SCF
  RET
l_A482:
  LD A,$01
  AND A
  RET

; DE = the hit counter of the current bit unit
;
; Witness: L1 143860 (l3-l8).
BitHits:
  LD DE,MissileTimer+$0002
  LD A,(MissileTimer+$0004)
  ADD A,E
  LD E,A
  LD A,(DE)
  RET

; Mark the score, then ProcessHits
;
; Witness: L1 68907 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
AddScoreFlag:
  LD A,$01
  LD (ScoreDirty),A

; Process HitList: enemy slots lose a hit, soft cells explode
;
; Witness: L1 258153 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
ProcessHits:
  XOR A
  LD (Scratch+$0006),A
  LD (HitCellCount),A
  LD HL,HitList
  LD A,$01
  LD (HitResult),A

; ProcessHitsNext
;
; Used by the routines at HitEnemy and HitCounted.
ProcessHitsNext:
  LD (HL),$00             ; the next tag
  INC L
  LD A,(HL)
  AND A
  JR NZ,l_A4B9
  LD (HitCount),A
  LD (HitCellCount),A
  LD (ScoreDirty),A
  LD A,(HitResult)
  AND A
  RET
l_A4B9:
  CP $80
  JR C,ProcessHitsNext
  CP $FA
  JP NZ,HitEnemy
  LD A,(HitCellCount)
  INC A
  LD (HitCellCount),A
  DEC A
  ADD A,A
  LD BC,HitCells
  ADD A,C
  LD C,A
  LD A,(BC)
  EX AF,AF'
  INC C
  LD A,(BC)
  LD B,A
  EX AF,AF'
  LD C,A
  PUSH HL
  CALL ExplodeSoftCell
  LD HL,$0F21
  CALL PlaySound
  POP HL
  JP HitCounted

; Clear the soft cell at BC and its neighbours, draw the explosion
;
; Witness: L1 717 (l4).
ExplodeSoftCell:
  XOR A
  LD (DrawTag),A
  CALL GetCell
  CALL SoftCellsOn
  LD H,D
  LD L,E
  LD (HL),$00
  DEC L
  LD A,(HL)
  PUSH AF
  LD (HL),$00
  INC H
  INC H
  INC H
  LD (HL),$00
  INC L
  LD (HL),$00
  INC E
  LD A,(DE)
  DEC E
  CP $FA
  JR NZ,l_A513
  LD A,(FrameCounter)
  AND $07
  ADD A,$48
  CALL DrawCellBlast
  JR l_A518
l_A513:
  LD A,$48
  CALL DrawCellBlast
l_A518:
  DEC E
  POP AF
  CP $FA
  JR NZ,l_A536
  LD A,(ScrollHalted)
  AND A
  JR Z,l_A528
  LD A,$58
  JR l_A530
l_A528:
  LD A,(FrameCounter)
  DEC A
  AND $07
  ADD A,$50
l_A530:
  CALL DrawCellBlast
  LD A,$FA
  LD (DE),A
l_A536:
  CALL SoftCellsOff
  RET

; Draw level object A at the cell left of BC and clear the cells there
;
; Witness: L1 879 (l4).
DrawCellBlast:
  PUSH BC
  PUSH DE
  DEC C
  CALL LevelObject
  CALL DrawSprite
  POP DE
  POP BC
  PUSH BC
  DEC C
  LD A,$44
  LD HL,$0102
  CALL ClearCellsTag
  POP BC
  RET

; HitEnemy
;
; Used by the routine at ProcessHitsNext.
HitEnemy:
  CP $FA                  ; an enemy slot's tag
  JP NC,ProcessHitsNext
  CP $DC
  JR C,l_A55C
  SUB $DC
l_A55C:
  EX DE,HL
  CALL SlotFlags
  EX DE,HL
  AND $3F
  JR Z,l_A588
  CP $3F
  JR NZ,l_A57B
  LD (Scratch+$0006),A
  LD A,(BeamPower)
  AND A
  JR Z,l_A588
  XOR A
  LD (BeamPower),A
  CALL ClearHits
  INC A
  RET
l_A57B:
  EX DE,HL
  DEC (HL)
  DEC A
  JR NZ,l_A581
  LD (HL),A
l_A581:
  LD A,L
  ADD A,$08
  LD L,A
  SET 7,(HL)
  EX DE,HL
l_A588:
  LD A,(BeamPower)
  AND A
  JR Z,HitCounted
  DEC A
  LD (BeamPower),A

; HitCounted
;
; Used by the routines at ProcessHitsNext and HitEnemy.
HitCounted:
  XOR A                   ; a hit that counts
  LD (HitResult),A
  JP ProcessHitsNext

; An enemy is destroyed: an explosion and the score award
;
; Witness: L1 1313 (c1, continue, ending, gameover, hiscore, hiscore-typed,
; l1-l8).
EnemyDies:
  CALL FreeExplosion
  JR NZ,l_A5A1
  CALL AwardScore
l_A5A1:
  CALL AddScore
  RET

; HL = a free explosion record
;
; Witness: L1 1317 (c1, continue, ending, gameover, hiscore, hiscore-typed,
; l1-l8).
FreeExplosion:
  LD HL,Explosions
  LD B,$14
l_A5AA:
  LD A,(HL)
  AND A
  RET Z
  INC L
  INC L
  INC L
  DJNZ l_A5AA
  DEC A
  RET

; Start the explosion by the kind's size and return DE = the award
; (ScoreAwards)
;
; The kind's byte 2: high nibble the explosion size ($10 sound 8, $40 sound
; $0A, else 9), low nibble the award.
;
; Witness: L1 1317 (c1, continue, ending, gameover, hiscore, hiscore-typed,
; l1-l8).
AwardScore:
  LD (Scratch+$0002),HL
  LD E,(IY+$06)
  LD D,(IY+$07)
  INC DE
  INC DE
  LD A,(DE)
  AND $F0
  JR Z,l_A5E6
  PUSH HL
  LD L,$82
  LD H,$08
  CP $10
  JR Z,l_A5D5
  LD H,$0A
  CP $40
  JR Z,l_A5D5
  LD H,$09
l_A5D5:
  CALL PlaySound
  POP HL
  OR $08
  LD (HL),A
  INC L
  LD A,(Scratch)
  LD (HL),A
  INC L
  LD A,(Scratch+$0001)
  LD (HL),A
l_A5E6:
  LD A,(DE)
  DEC A
  AND $0F
  ADD A,A
  LD D,$00
  LD E,A
  LD HL,ScoreAwards
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  RET
