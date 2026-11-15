; --------------------------------------------------------------------------------------------------------------------
; matt.asm: Matt: walking, jumping, pods, falling, dying
;
; MattStep $B3EB runs once a pass. State 1 is the walk (left, right, down into a pod, up to jump); the other states
; are a jump table at $B73A (state - 2): 2 step up, 3 step down, 4 crouch (down held takes a pick-up), 5 the jump
; (rising), 6 the fall, 7 JACKRABBIT's long jump, 8 stand, 9 out of energy, 10 the password-door warp, 11 the
; materialisation at a new game (effect 9), 12 the materialisation's dissolve. Leaving the screen at an edge goes to
; the next screen or room (LeftEdge $B659, RightEdge $B686).
; --------------------------------------------------------------------------------------------------------------------

  ORG $B3EB

; Matt's pass: controls, edges, the state routine
;
; Clears $F000-$F0BF, sets DeathFlag when Matt falls below the play area, sets
; the facing from left / right.
;
; Witness: L1 15289 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
MattStep:
  LD HL,CharMap+$003F
  LD BC,$1800
l_B3F1:
  LD (HL),C
  DEC L
  LD (HL),C
  DEC L
  LD (HL),C
  DEC L
  LD (HL),C
  DEC L
  LD (HL),C
  DEC L
  LD (HL),C
  DEC L
  LD (HL),C
  DEC L
  LD (HL),C
  DEC L
  DJNZ l_B3F1

; l_B403
;
; Used by the routines at l_B8A7 and l_B9A9.
l_B403:
  LD A,(Objects+$0004)
  ADD A,$30
  CP $A0
  JR C,l_B411
  LD A,$FF
  LD (DeathFlag),A
l_B411:
  LD IX,Objects
  LD A,(Dying)
  AND A
  JP NZ,MattWalk
  LD A,(Objects)
  CP $05
  JR Z,l_B446
  CP $06
  JR Z,l_B446
  LD (IX+$12),$00
  LD A,(Controls)
  BIT 1,A
  JR Z,l_B43A
  LD (IX+$02),$80
  LD (IX+$12),$FE
l_B43A:
  BIT 0,A
  JR Z,l_B446
  LD (IX+$02),$00
  LD (IX+$12),$02
l_B446:
  CALL MattCell
  LD (IX+$13),$00
  LD A,(Objects+$0003)
  CP $41
  JR NC,l_B458
  LD (IX+$13),$80
l_B458:
  CP $B2
  JR C,MattWalk
  LD (IX+$13),$9D
MattWalk:
  LD A,(Objects)          ; state 1
  CP $01
  JP NZ,l_B72D
  LD IY,l_B4C0

; l_B46C
;
; Used by the routine at MattStand.
l_B46C:
  LD A,(Controls)
  BIT 2,A
  JR Z,l_B4BE
  LD HL,(MattPlace+$0002)
  LD A,(HL)
  CP $14
  JP Z,Teleport
  CP $15
  JP Z,Teleport
  INC HL
  LD A,(HL)
  CP $14
  JP Z,Teleport
  CP $15
  JP Z,Teleport
  LD A,(RoomNumber)
  AND A
  JR NZ,l_B4BE
  LD A,(RoomScreen)
  CP $28
  JR NZ,l_B4BE
  LD HL,(MattPlace+$0002)
  LD DE,$0081
  ADD HL,DE
  LD A,(HL)
  CP $1C
  JR NZ,l_B4BE
  LD A,(Objects+$0003)
  SUB $40
  RLCA
  RLCA
  RLCA
  AND $03
  LD E,A
  LD D,$00
  LD HL,PasswordFlags
  ADD HL,DE
  LD A,(HL)
  AND A
  JR Z,l_B4BE
  JP StartWarp
l_B4BE:
  JP (IY)

; l_B4C0
l_B4C0:
  CALL FloorCheck
  AND A
  JP Z,l_B6E8
  BIT 7,(IX+$02)
  JR NZ,l_B4DB
  LD HL,(MattPlace+$0002)
  LD DE,$0082
  ADD HL,DE
  CALL IsSolid
  JR C,l_B502
  JR l_B4E7
l_B4DB:
  LD HL,(MattPlace+$0002)
  LD DE,$0081
  ADD HL,DE
  CALL IsSolid
  JR C,l_B502
l_B4E7:
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  JR NC,l_B502
  LD A,(IX+$12)
  LD (IX+$1B),A
  LD (IX+$10),$02
  LD A,$03
  LD (IX+$00),A
  JP l_B72D
l_B502:
  LD A,(Controls)
  AND $0F
  JR NZ,l_B511
  LD A,$08
  LD (Objects),A
  JP l_B72D
l_B511:
  LD C,A
  BIT 2,C
  JR Z,l_B526
  LD A,(Objects+$0004)
  ADD A,$08
  LD (Objects+$0004),A
  LD A,$04
  LD (Objects),A
  JP l_B72D
l_B526:
  BIT 3,C
  JR Z,l_B56B
  LD IY,(CurrentSlot)
  LD A,(IY+$01)
  CP $05
  JP Z,JackrabbitJump
  BIT 7,(IX+$13)
  JR NZ,l_B559
  LD A,(PenetratorOn)
  AND A
  JR NZ,l_B549
  LD HL,(MattPlace)
  CALL IsSolid
  RET C
l_B549:
  LD HL,(MattPlace+$0002)
  LD DE,$FFE0
  ADD HL,DE
  CALL IsSolid
  RET C
  INC L
  CALL IsSolid
  RET C
l_B559:
  LD (IX+$11),$F7
  LD A,(IX+$12)
  LD (IX+$1B),A
  LD A,$05
  LD (Objects),A
  JP l_B72D
l_B56B:
  BIT 1,C
  JR Z,l_B5B5
  BIT 7,(IX+$13)
  JR NZ,l_B5A7
  LD A,(PenetratorOn)
  AND A
  JR Z,l_B58C
  LD HL,(MattPlace)
  LD DE,$0040
  ADD HL,DE
  CALL IsSolid
  JR C,l_B5A7
  LD DE,$0020
  JR l_B5A0
l_B58C:
  LD HL,(MattPlace)
  CALL IsSolid
  RET C
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  RET C
  ADD HL,DE
  CALL IsSolid
  RET C
l_B5A0:
  ADD HL,DE
  CALL IsSolid
  JP C,l_B647
l_B5A7:
  LD A,(Objects+$0003)
  CP $3B
  JP C,LeftEdge
  SUB $02
  LD (Objects+$0003),A
  RET
l_B5B5:
  BIT 0,C
  RET Z
  BIT 7,(IX+$13)
  JR NZ,l_B5EF
  LD A,(PenetratorOn)
  AND A
  JR Z,l_B5D5
  LD HL,(MattPlace)
  LD DE,$0040
  ADD HL,DE
  CALL IsSolid
  JR C,l_B5EF
  LD DE,$0020
  JR l_B5E9
l_B5D5:
  LD HL,(MattPlace)       ; walking right: the head-row IsSolid result is
                          ; discarded (no RET C), unlike the left-hand test at
                          ; $B58C
  CALL IsSolid
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  RET C
  ADD HL,DE
  CALL IsSolid
  RET C
  ADD HL,DE
l_B5E9:
  CALL IsSolid
  JP C,l_B647
l_B5EF:
  LD A,(Objects+$0003)
  CP $B6
  JP NC,RightEdge
  ADD A,$02
  LD (Objects+$0003),A
  RET

; MattPlace from x and y
;
; Witness: L1 15326 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
MattCell:
  LD A,(Objects+$0003)
  SUB $3C
  RRCA
  RRCA
  AND $1F
  LD E,A
  LD D,$00
  LD A,(Objects+$0004)
  AND $F8
  LD L,A
  LD H,D
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD DE,CharMap+$003F
  ADD HL,DE
  LD (MattPlace+$0002),HL
  BIT 7,(IX+$02)
  JR NZ,l_B624
  LD DE,$0003
  ADD HL,DE
l_B624:
  LD (MattPlace),HL
  LD A,(HL)
  RET

; The map place ahead of Matt
;
; Witness: L1 405 (c1, door, door3, play2, rzx- x9).
MattCellAhead:
  LD A,(Objects+$0013)
  AND $1F
  LD E,A
  LD D,$00
  LD A,(Objects+$0004)
  AND $F8
  LD L,A
  LD H,D
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD DE,CharMap+$0040
  ADD HL,DE
  LD (MattPlace+$0002),HL
  LD DE,$0080
  ADD HL,DE
  RET

; l_B647
;
; Used by the routine at l_B4C0.
l_B647:
  LD A,(IX+$12)
  LD (IX+$1B),A
  LD (IX+$10),$02
  LD A,$02
  LD (IX+$00),A
  JP l_B72D

; Off the left edge: the screen to the left, or the room RoomTable byte 0
;
; Witness: L1 38 (c1, rzx-00000, rzx-32000).
LeftEdge:
  LD A,(RoomScreen)
  AND A
  JR Z,l_B672
  SUB $08
  LD (RoomScreen),A
l_B664:
  LD (IX+$03),$B2
  PUSH IX
  CALL DrawRoom
  POP IX
  OR $FF
  RET
l_B672:
  LD IY,(RoomRecord)
  LD A,(IY+$00)
  CP $FF
  RET Z
  LD (RoomNumber),A
  LD A,$28
  LD (RoomScreen),A
  JR l_B664

; Off the right edge: the next screen, or the room RoomTable byte 1
;
; Witness: L1 64 (door, door3, play2, rzx- x9).
RightEdge:
  LD A,(RoomScreen)
  CP $28
  JR Z,l_B6A0
  ADD A,$08
  LD (RoomScreen),A
l_B692:
  LD (IX+$03),$3E
  PUSH IX
  CALL DrawRoom
  POP IX
  OR $FF
  RET
l_B6A0:
  LD IY,(RoomRecord)
  LD A,(IY+$01)
  CP $FF
  RET Z
  LD (RoomNumber),A
  XOR A
  LD (RoomScreen),A
  JR l_B692

; A pod: the room RoomTable byte 2, arriving at the place of byte 5
;
; Witness: L1 4 (rzx-00000, rzx-04000, rzx-12000, rzx-20000).
Teleport:
  LD IX,(RoomRecord)
  LD A,(IX+$02)
  CP $FF
  RET Z
  LD (RoomNumber),A
  LD A,(IX+$05)
  LD L,A
  AND $1F
  ADD A,A
  ADD A,A
  ADD A,$40
  LD (Objects+$0003),A
  LD A,L
  AND $E0
  RRCA
  RRCA
  LD (RoomScreen),A
  JP DrawRoom

; Never run: leave by RoomTable byte 3
;
; Known only from the code: byte 3 is $FF in every room.
ExitByte3:
  LD IX,(RoomRecord)
  LD A,(IX+$03)
  CP $FF
  RET Z
  LD (RoomNumber),A
  JP DrawRoom

; l_B6E8
;
; Used by the routines at l_B4C0 and l_B9A9.
l_B6E8:
  LD IY,(CurrentSlot)
  LD A,(IY+$01)
  CP $05
  JP Z,JackrabbitJump
  LD A,(IX+$12)
  LD (IX+$1B),A

; l_B6FA
;
; Used by the routine at MattJumpRise.
l_B6FA:
  LD (IX+$11),$01
  LD A,$06
  LD (Objects),A
  JP l_B72D

; A = what is under Matt's feet
;
; Witness: L1 11688 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FloorCheck:
  PUSH DE
  PUSH BC
  BIT 7,(IX+$13)
  JR Z,l_B713
  CALL MattCellAhead
  JR l_B71A
l_B713:
  LD HL,(MattPlace+$0002)
  LD DE,$0081
  ADD HL,DE
l_B71A:
  LD C,$00
  CALL IsSolid
  JR NC,l_B722
  INC C
l_B722:
  INC L
  CALL IsSolid
  JR NC,l_B729
  INC C
l_B729:
  LD A,C
  POP BC
  POP DE
  RET

; l_B72D
;
; Used by the routines at l_B403, l_B4C0, l_B647 and l_B6FA.
l_B72D:
  SUB $02
  LD L,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  LD DE,StateJumps
  ADD HL,DE
  JP (HL)

; StateJumps
StateJumps:
  JP MattStepUp           ; JP the routine of states 2-12

; l_B73D
l_B73D:
  JP MattStepDown

; l_B740
l_B740:
  JP MattCrouchState

; l_B743
l_B743:
  JP MattJumpRise

; l_B746
l_B746:
  JP MattFall

; l_B749
l_B749:
  JP MattLongJump

; l_B74C
l_B74C:
  JP MattStand

; l_B74F
l_B74F:
  JP MattNoEnergy

; JP PasswordWarp $B9D8: state 10's slot
;
; Witness: L1 100 (door, door3).
StateWarpJump:
  JP PasswordWarp

; l_B755
l_B755:
  JP PodStart

; l_B758
l_B758:
  JP MattPodDissolve

; MattStepUp
;
; Used by the routine at StateJumps.
MattStepUp:
  LD A,(Objects+$0003)    ; state 2: a step up, x + dx and y - 4 for two passes
  ADD A,(IX+$1B)
  LD (Objects+$0003),A
  LD A,(Objects+$0004)
  SUB $04
  LD (Objects+$0004),A
  DEC (IX+$10)
  RET NZ
  LD (IX+$00),$01
  RET

; MattStepDown
;
; Used by the routine at l_B73D.
MattStepDown:
  DEC (IX+$10)            ; state 3: a step down, x + dx and y + 4 for two
                          ; passes (also walking off an edge)
  JP M,l_B797
  LD A,(Objects+$0003)
  ADD A,(IX+$1B)
  CP $B6
  JP NC,RightEdge
  CP $3B
  JP C,LeftEdge
  LD (Objects+$0003),A
  LD A,(Objects+$0004)
  ADD A,$04
  LD (Objects+$0004),A
  RET
l_B797:
  LD (IX+$00),$01
  JP MattStep

; MattCrouchState
;
; Used by the routine at l_B740.
MattCrouchState:
  LD A,(Controls)         ; state 4
  BIT 2,A
  JR Z,l_B7A8
  JP CheckPickupsDown
l_B7A8:
  LD (IX+$00),$01
  LD A,(Objects+$0004)
  SUB $08
  LD (Objects+$0004),A
  RET

; MattJumpRise
;
; Used by the routine at l_B743.
MattJumpRise:
  LD A,(ZoneSlots)        ; state 5: the jump, v (+$11) from -9 up to 0 (every
                          ; fourth pass on the moon), then the fall
  CP $02
  JR NZ,l_B7C3
  LD A,(PassCounter)
  AND $03
  JR Z,l_B7D5
l_B7C3:
  LD A,(Objects+$0011)
  INC A
  LD (Objects+$0011),A
  CP $01
  JR NZ,l_B7D5
  LD (IX+$00),$01
  JP l_B6FA
l_B7D5:
  LD HL,(MattPlace+$0002)
  CALL IsSolid
  JP C,l_B83A
  INC L
  CALL IsSolid
  JP C,l_B83A
  LD A,(Objects+$0011)
  ADD A,(IX+$04)
  LD (Objects+$0004),A
  LD A,(Objects+$001B)
  AND A
  RET Z
  BIT 7,(IX+$13)
  JR NZ,l_B817
  LD A,(PenetratorOn)
  AND A
  JR NZ,l_B817
  LD HL,(MattPlace)
  LD DE,$0040
  CALL IsSolid
  RET C
  ADD HL,DE
  CALL IsSolid
  RET C
  SRL D
  RR E
  ADD HL,DE
  CALL IsSolid
  RET C
l_B817:
  LD A,(Objects+$0003)
  CP $3B
  JR NC,l_B824
  CALL LeftEdge
  JR Z,l_B835
  RET
l_B824:
  CP $B6
  JR C,l_B82E
  CALL RightEdge
  JR Z,l_B835
  RET
l_B82E:
  ADD A,(IX+$1B)
  LD (Objects+$0003),A
  RET
l_B835:
  LD (IX+$00),$01
  RET
l_B83A:
  LD (IX+$00),$01
  JP LavaDrain

; MattFall
;
; Used by the routine at l_B746.
MattFall:
  LD IY,(CurrentSlot)     ; state 6: the fall, v up to 8; JACKRABBIT in the
                          ; slot in use turns it into the long jump
  LD A,(IY+$01)
  CP $05
  JR NZ,l_B850
  JP JackrabbitJump

; A RET no branch reaches, then the jump's shared steps
;
; The RET at $B84F never ran (known only from the code); the steps from $B850
; run in every jump (c1).
MattJumpRet:
  RET
; This entry point is used by the routine at MattFall.
l_B850:
  LD A,(Objects+$001B)
  AND A
  JR Z,l_B8A7
  BIT 7,(IX+$13)
  JR NZ,l_B879
  LD A,(PenetratorOn)
  AND A
  JR NZ,l_B879
  LD HL,(MattPlace)
  LD DE,$0040
  CALL IsSolid
  JR C,l_B8A7
  ADD HL,DE
  CALL IsSolid
  JR C,l_B8A7
  ADD HL,DE
  CALL IsSolid
  JR C,l_B8A7
l_B879:
  CALL JumpEdges
  JP l_B8A7

; The jump at the screen edges
;
; Witness: L1 719 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
JumpEdges:
  LD A,(Objects+$0003)
  CP $3B
  JR NC,l_B891
  CALL LeftEdge
  JR NZ,l_B8A7
  LD (IX+$1B),$00
  JR l_B8A7
l_B891:
  CP $B6
  JR C,l_B8A0
  CALL RightEdge
  JR NZ,l_B8A7
  LD (IX+$1B),$00
  JR l_B8A7
l_B8A0:
  ADD A,(IX+$1B)
  LD (Objects+$0003),A
  RET

; l_B8A7
;
; Used by the routines at MattJumpRet and JumpEdges.
l_B8A7:
  CALL FloorCheck
  AND A
  JR NZ,l_B8CF
  LD A,(Objects+$0011)
  ADD A,(IX+$04)
  LD (Objects+$0004),A
  LD A,(Objects+$0011)
  CP $08
  RET Z
  LD C,$08
  LD A,(ZoneSlots)
  CP $02
  JR NZ,l_B8CB
  LD A,(PassCounter)
  AND $03
  RET NZ
l_B8CB:
  INC (IX+$11)
  RET
l_B8CF:
  LD (IX+$00),$01
  LD A,(Objects+$0004)
  AND $F8
  LD (Objects+$0004),A
  JP l_B403

; JackrabbitJump
;
; Used by the routines at l_B4C0, l_B6E8 and MattFall.
JackrabbitJump:
  LD (IX+$00),$07         ; JACKRABBIT: the long jump, state 7
  LD (IX+$11),$04
  RET

; MattLongJump
;
; Used by the routine at l_B749.
MattLongJump:
  LD IY,(CurrentSlot)     ; state 7: a charge each 5 passes, $15 (15 BCD) on
                          ; the moon
  LD A,(IY+$01)
  CP $05
  JR NZ,l_B94F
  INC (IX+$11)
  LD A,(IX+$11)
  CP $05
  JR NZ,l_B90F
  LD (IX+$11),$00
  LD C,$01
  LD A,(ZoneSlots)
  CP $02
  JR NZ,l_B90B
  LD C,$15
l_B90B:
  LD A,C
  CALL UseCharge
l_B90F:
  LD A,(Controls)
  BIT 3,A
  JR Z,l_B938
  LD HL,(MattPlace+$0002)
  CALL IsSolid
  CALL C,LavaDrain
  JR C,l_B954
  INC L
  CALL IsSolid
  CALL C,LavaDrain
  JR C,l_B954
  LD A,(IX+$04)
  CP $05
  JR C,l_B954
  SUB $04
  LD (IX+$04),A
  JR l_B954
l_B938:
  LD C,$02
  BIT 2,A
  JR Z,l_B940
  LD C,$04
l_B940:
  CALL FloorCheck
  AND A
  JR NZ,l_B94F
  LD A,(IX+$04)
  ADD A,C
  LD (IX+$04),A
  JR l_B954
l_B94F:
  LD (IX+$00),$01
  RET
l_B954:
  BIT 7,(IX+$13)
  JR NZ,l_B973
  LD HL,(MattPlace)
  LD DE,$0020
  CALL IsSolid
  RET C
  ADD HL,DE
  CALL IsSolid
  RET C
  ADD HL,DE
  CALL IsSolid
  RET C
  ADD HL,DE
  CALL IsSolid
  RET C
l_B973:
  LD A,(Objects+$0003)
  CP $3B
  JR NC,l_B981
  BIT 7,(IX+$12)
  JP NZ,LeftEdge
l_B981:
  CP $B6
  JR C,l_B98C
  BIT 7,(IX+$12)
  JP Z,RightEdge
l_B98C:
  ADD A,(IX+$12)
  LD (Objects+$0003),A
  RET

; Carry when the character at HL is solid (its ZoneAttrs bit 7)
;
; Witness: L1 81448 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
IsSolid:
  PUSH DE
  LD D,$EF
  LD E,(HL)
  LD A,(DE)
  ADD A,A
  POP DE
  RET

; MattStand
;
; Used by the routine at l_B74C.
MattStand:
  LD A,(Controls)         ; state 8
  AND $0F
  JR NZ,l_B9B1
  LD IY,l_B9A9
  JP l_B46C

; l_B9A9
l_B9A9:
  CALL FloorCheck
  AND A
  JP Z,l_B6E8
  RET
; This entry point is used by the routine at MattStand.
l_B9B1:
  LD (IX+$00),$01
  JP l_B403

; MattNoEnergy
;
; Used by the routine at l_B74F.
MattNoEnergy:
  DEC (IX+$10)            ; state 9: wait, then GameOver
  RET NZ
  CALL FlushDirty
  CALL FlushDirty
  JP GameOver

; StartWarp
;
; Used by the routine at l_B46C.
StartWarp:
  LD (IX+$00),$0A         ; the room-0 password door: state 10, dissolve
  LD (IX+$10),$32
  LD A,$01
  LD (DissolveCount),A
  LD A,$09
  CALL PlayEffect
  RET

; State 10: the warp through a room-0 password door to room 11, 3, 7 or 7
;
; Counts the dissolve down (IX+$10), then sets RoomNumber from WarpRooms
; $BA1D[door] (0B 03 07 07), RoomScreen 0, x $42, y + 8, state 8, and DrawRoom.
; Door 3 also calls WarpBonus $BA21. The door recording (work/stage2/rec/door,
; a POKE cheat for the password flags) took door 1 (x $68, state 10 at frame
; 845) to room 3 (frame 981); door3 (the same cheat, x $A0) took door 3 to room
; 7 and its LIFTER.
;
; Witness: L1 100 (door, door3).
PasswordWarp:
  LD A,(IX+$10)
  AND $0F
  JR NZ,l_B9E3
  LD HL,DissolveCount
  INC (HL)
l_B9E3:
  DEC (IX+$10)
  RET NZ
  LD A,(IX+$03)
  SUB $40
  RLCA
  RLCA
  RLCA
  AND $03
  LD E,A
  LD D,$00
  LD HL,WarpRooms
  ADD HL,DE
  LD A,(HL)
  LD (RoomNumber),A
  XOR A
  LD (RoomScreen),A
  LD (IX+$03),$42
  LD A,(IX+$04)
  ADD A,$08
  LD (IX+$04),A
  LD (IX+$00),$08
  XOR A
  LD (DissolveCount),A
  LD A,E
  CP $03
  CALL Z,WarpBonus
  JP DrawRoom

; The room behind each password door: 0B 03 07 07
WarpRooms:
  DEFB $0B,$03,$07,$07

; Door 3's bonus: BACKLASH to level 3, a LIFTER with 99 charges at level 1, its
; name
;
; FindLifterSlot $BA3E picks the first EMPTY or PENETRATOR slot (else slot 0),
; raising every BACKLASH slot it passes to level 3; the slot gets kind 6
; (LIFTER), 99 charges, level 1; ShowLifterName $BA60 when slot 0 was EMPTY;
; then DrawAllSlots.
;
; Witness: L1 1 (door3).
WarpBonus:
  LD IX,MaskSlots
  LD A,(IX+$01)
  AND A
  CALL Z,ShowLifterName
  CALL FindLifterSlot
  LD (IX+$01),$06
  LD (IX+$02),$99
  LD (IX+$03),$01
  JP DrawAllSlots

; IX = the first EMPTY or PENETRATOR slot, else slot 0; BACKLASH slots on the
; way get level 3
;
; Witness: L1 1 (door3).
FindLifterSlot:
  LD IX,MaskSlots
  LD DE,$0004
  LD B,$04
l_BA47:
  LD A,(IX+$01)
  CP $08
  JR NZ,l_BA52
  LD (IX+$03),$03
l_BA52:
  AND A
  RET Z
  CP $01
  RET Z
  ADD IX,DE
  DJNZ l_BA47
  LD IX,MaskSlots
  RET

; ShowMaskName(LIFTER), keeping AF
;
; Witness: L1 1 (door3).
ShowLifterName:
  PUSH AF
  LD A,$06
  CALL ShowMaskName
  POP AF
  RET

; State 11: the materialisation at a new game (effect 9), then the dissolve
;
; Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).
PodStart:
  LD A,$09
  CALL PlayEffect
  LD A,$32
  LD (IX+$10),A
  LD A,$04
  LD (DissolveCount),A
  INC (IX+$00)
  RET

; MattPodDissolve
;
; Used by the routine at l_B758.
MattPodDissolve:
  LD A,(IX+$10)           ; state 12
  AND $0F
  JR NZ,l_BA86
  LD HL,DissolveCount
  DEC (HL)
l_BA86:
  DEC (IX+$10)
  RET NZ
  LD (IX+$00),$08
  XOR A
  LD (DissolveCount),A
  RET

; Zone 1: 2 energy when Matt's head hits a solid character in a jump
; (MattJumpRise $B83E, JackrabbitJump $B91C / $B925)
;
; Witness: L1 51 (rzx-12000, rzx-16000, rzx-20000).
LavaDrain:
  PUSH AF
  LD A,(ZoneSlots)
  DEC A
  JR NZ,l_BAA5
  LD A,(Energy)
  SUB $02
  JR NC,l_BAA2
  XOR A
l_BAA2:
  LD (Energy),A
l_BAA5:
  POP AF
  RET

; non-zero while Matt dies
Dying:
  DEFB $00

; Matt sinks for 32 passes, effect 8, then GameOver
;
; Witness: L1 6 (rzx-04000, rzx-24000, rzx-28000, rzx-32000).
Death:
  LD A,$08
  CALL PlayEffect
  LD A,$FF
  LD (Dying),A
  XOR A
  LD (DissolveCount),A
  LD B,$20
l_BAB8:
  PUSH BC
  LD HL,Objects+$0004
  INC (HL)
  CALL AnimateZone
  CALL DrawObjects
  POP BC
  DJNZ l_BAB8
  CALL FlushDirty
  CALL FlushDirty

; GameOver
;
; Used by the routines at MattNoEnergy and EndPenetrator.
GameOver:
  LD A,(MachineFlag)            ; tune 2, MISSION TERMINATED, the high score,
                          ; GameStart
  LD (EffectStops),A
  LD A,$02
  LD (TuneRequest),A
  LD DE,$0407
  LD HL,GameOverText
  CALL SlowPrint
  LD HL,Hiscore
  LD DE,Score
  LD B,$04
l_BAE8:
  LD A,(DE)
  CP (HL)
  JP C,GameStart
  JR NZ,l_BAF3
  INC HL
  INC DE
  DJNZ l_BAE8
l_BAF3:
  LD HL,Score
  LD DE,Hiscore
  LD BC,$0004
  LDIR
  JP GameStart

; MISSION TERMINATED
GameOverText:
  DEFM "MISSION TERMINATE",$C4

; Print a string a character a few HALTs
;
; Witness: L1 17 (door3, kind6, masks, play2, rzx- x8).
SlowPrint:
  PUSH HL
  CALL ScreenAddr
  EX DE,HL
  POP HL
  CALL PrintSpace
  LD B,$46
l_BB1E:
  HALT
  DJNZ l_BB1E
l_BB21:
  LD A,(HL)
  CALL PrintChar
  CALL PrintSpace
  LD B,$04
l_BB2A:
  HALT
  DJNZ l_BB2A
  BIT 7,(HL)
  INC HL
  JR Z,l_BB21
  LD B,$64
l_BB34:
  HALT
  DJNZ l_BB34
  RET

; A space and a flash attribute at the cursor
;
; Witness: L1 341 (door3, kind6, masks, play2, rzx- x8).
PrintSpace:
  LD A,$20
  CALL PrintChar
  DEC E
  LD C,E
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD B,A
  LD A,$C7
  LD (BC),A
  RET

; Interrupt, in play: compare PasswordBuffer with CheatCode; equal sets CheatOn
; $BB77
;
; HL = $E406 + $BB6B = $9F71 (PasswordBuffer, the sum overflows): typing JUDGE
; DREDD at ENTER PASSWORD sets CheatOn, which UseCharge $B210 and DeadlyFloor
; $B2F9 read: the masks keep their charges and the deadly floors do not kill.
; Witness: L1 46478 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10);
; the cheat's effect is in work/stage2/NOTES.md.
CheatCheck:
  PUSH AF
  LD BC,$BA77
  INC B
  XOR A
  LD (BC),A
  LD DE,CheatCode
  LD HL,ZoneChars+$0406
  ADD HL,DE
l_BB5A:
  LD A,(DE)
  CP (HL)
  JR NZ,l_BB69
  AND A
  JR Z,l_BB66
  INC DE
  INC HL
  JP l_BB5A
l_BB66:
  LD A,$FF
  LD (BC),A
l_BB69:
  POP AF
  RET

; The cheat password JUDGE DREDD as key codes, 0-terminated, and CheatOn $BB77
CheatCode:
  DEFB $63,$53,$12,$14,$22,$70,$12,$23
  DEFB $22,$12,$12,$00
CheatOn:
  DEFB $00                ; $FF when the cheat password was typed

; 200 dots fly out of Matt: the PENETRATOR's death in a wall
;
; Reached only from EndPenetrator $BDF7, when fire is released with Matt inside
; a wall (effects 16 and 17). Witness: work/stage2/rec/masks (PENETRATOR given
; by POKE, fire held walking right into the hill, released at frame 1249).
;
; Witness: L1 1 (masks).
Explosion:
  LD A,$10
  CALL PlayEffect
  LD A,$11
  CALL PlayEffect
  CALL FlushDirty
  CALL FlushDirty
  LD HL,Attributes
  LD B,$03
  LD C,$3F
l_BB8F:
  LD A,(HL)
  AND C
  JR NZ,l_BB95
  LD (HL),$47
l_BB95:
  INC L
  JR NZ,l_BB8F
  INC H
  DJNZ l_BB8F
  LD A,(Objects+$0003)
  SUB $40
  ADD A,A
  ADD A,$10
  LD L,A
  LD A,(Objects+$0004)
  ADD A,$10
  LD H,A
  LD IX,SpriteChars
  LD DE,$0005
  LD B,$C8
l_BBB3:
  LD (IX+$00),$FF
  CALL Random
  AND $1F
  SUB $10
  ADD A,L
  LD (IX+$01),A
  LD E,A
  CALL Random
  LD C,A
  AND $07
  INC A
  BIT 7,C
  JR Z,l_BBD0
  NEG
l_BBD0:
  LD (IX+$03),A
  CALL Random
  AND $1F
  SUB $10
  ADD A,H
  LD (IX+$02),A
  LD D,A
  CALL Random
  LD C,A
  AND $07
  INC A
  BIT 7,C
  JR Z,l_BBEC
  NEG
l_BBEC:
  LD (IX+$04),A
  CALL PlotDot
  LD DE,$0005
  ADD IX,DE
  DJNZ l_BBB3
  LD B,$96
l_BBFB:
  PUSH BC
  HALT
  LD B,$C8
  LD IX,SpriteChars
l_BC03:
  LD A,(IX+$00)
  AND A
  JR Z,l_BC4D
  LD E,(IX+$01)
  LD D,(IX+$02)
  CALL PlotDot
  LD A,D
  ADD A,(IX+$04)
  LD D,A
  LD A,E
  ADD A,(IX+$03)
  LD E,A
  LD A,D
  XOR (IX+$02)
  JP P,l_BC30
  LD A,D
  ADD A,$10
  CP $21
  JR NC,l_BC30
  LD (IX+$00),$00
  JR l_BC4D
l_BC30:
  LD A,E
  XOR (IX+$01)
  JP P,l_BC44
  LD A,E
  ADD A,$10
  CP $21
  JR NC,l_BC44
  LD (IX+$00),$00
  JR l_BC4D
l_BC44:
  LD (IX+$02),D
  LD (IX+$01),E
  CALL PlotDot
l_BC4D:
  LD DE,$0005
  ADD IX,DE
  DJNZ l_BC03
  POP BC
  DJNZ l_BBFB
  RET

; XOR the dot at x E, y D
;
; Witness: L1 10085 (masks).
PlotDot:
  LD A,D
  CP $90
  RET NC
  PUSH HL
  LD HL,DotBits
  LD A,E
  AND $07
  ADD A,L
  LD L,A
  JR NC,l_BC68
  INC H
l_BC68:
  LD A,(HL)
  LD (l_BC68+$0021),A
  LD A,E
  RRCA
  RRCA
  RRCA
  AND $1F
  LD L,A
  LD A,D
  RLCA
  RLCA
  AND $E0
  OR L
  LD L,A
  LD A,D
  AND $07
  LD H,A
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $18
  OR H
  OR $40
  LD H,A
  LD A,$00
  XOR (HL)
  LD (HL),A
  POP HL
  RET

; The eight pixel bits
DotBits:
  DEFB $80,$40,$20,$10,$08,$04,$02,$01
