; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The objects, the enemies, the score, the energy, the messages and the end
;
; Objects $A43F holds Matt, his shot and six others. Each pass Spawn $BF2B fills an empty slot with the enemy kind of
; the screen (EnemyKind $BFB0, from RoomTable bytes 6-11), the kinds' first values coming from EnemyTemplates $BE3B;
; RunObjects $C284 moves each by its kind through ObjectJumps $C326, checks Matt's shot (ShotHits $BC96) and Matt
; (TouchesMatt $C2D9: Damage $C2CA takes +$1E from the Energy). A killed enemy gives its score (AwardScore $C2C1) and
; becomes an explosion (Explode $C26F).
; --------------------------------------------------------------------------------------------------------------------

  ORG $AD28

; Screen 0 messages: room 0 GOOD LUCK MATT; rooms 3, 7, 10, 11 CODE BROKEN and
; a password
;
; Room 11 shows MAYHEM, 3 TRANSMOGRIFY, 7 VALKYR, 10 PETALS OF DOOM, built by
; BuildMessage $ADBF and scrolled by ShowMessage $B0FF.
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
RoomMessage:
  LD A,(RoomScreen)
  AND A
  RET NZ
  LD HL,Messages
  LD A,(RoomNumber)
  AND A
  JP Z,ShowMessage
  LD HL,Messages+$0033
  LD DE,Passwords
  CALL BuildMessage
  LD HL,Messages+$0014
  CP $0B
  JP Z,ShowMessage
  LD HL,Messages+$0033
  LD DE,Passwords+$0007
  CALL BuildMessage
  LD HL,Messages+$0014
  CP $03
  JP Z,ShowMessage
  LD HL,Messages+$0033
  LD DE,Passwords+$0014
  CALL BuildMessage
  LD HL,Messages+$0014
  CP $07
  JP Z,ShowMessage
  LD HL,Messages+$0033
  LD DE,Passwords+$001B
  CALL BuildMessage
  LD HL,Messages+$0014
  CP $0A
  JP Z,ShowMessage
  RET

; GOOD LUCK MATT, CODE BROKEN, PASSWORD IS and the message buffer $ADAF
Messages:
  INCBIN "res/texts/messages.bin",$0000,67

; Copy the password text after PASSWORD IS
;
; Witness: L1 23 (door, door3, rzx- x5).
BuildMessage:
  PUSH AF
l_ADC0:
  LD A,(DE)
  AND A
  JR Z,l_ADCD
  CALL KeyCodeToChar
  LD (HL),A
  INC HL
  INC DE
  JP l_ADC0
l_ADCD:
  DEC HL
  SET 7,(HL)
  POP AF
  RET

; Zone 2: every PENETRATOR (kind 1) slot becomes EMPTY
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
MoonMasks:
  LD A,(ZoneSlots)
  CP $02
  RET NZ
  LD IX,MaskSlots
  LD DE,$0004
  LD B,$04
l_ADE1:
  LD A,(IX+$01)
  DEC A
  JR NZ,l_ADEF
  LD (IX+$01),$00
  LD (IX+$02),$00
l_ADEF:
  ADD IX,DE
  DJNZ l_ADE1
  JP DrawAllSlots

; Room 15, screen 5: YOU HAVE FOUND SCOTT, WELL DONE, then GameStart
;
; Jumps to GameStart without the high-score test of GameOver: the score of a
; won game is not kept (rzx-36000: 31 004 points, then the menu shows HISCORE
; 00000000).
;
; Witness: L1 1 (play2).
Ending:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1AFF
  LD (HL),$00
  LDIR
  LD DE,$0801
  LD HL,EndTexts
  CALL SlowPrint
  LD A,$20
  CALL PrintChar
  LD DE,$0C08
  LD HL,EndTexts+$001A
  CALL SlowPrint
  JP GameStart

; YOU HAVE FOUND SCOTT and WELL DONE
EndTexts:
  INCBIN "res/texts/end.bin",$0000,36

; 4 BCD bytes
Score:
  DEFB $00,$00,$00,$00

; Score + DE (BCD)
;
; Witness: L1 84 (kind6, rzx- x9).
AddScore:
  PUSH HL
  LD HL,Score+$0003
  LD A,E
  ADD A,(HL)
  DAA
  LD (HL),A
  DEC HL
  LD A,D
  ADC A,(HL)
  DAA
  LD (HL),A
  DEC HL
  LD A,$00
  ADC A,(HL)
  DAA
  LD (HL),A
  DEC HL
  LD A,$00
  ADC A,(HL)
  DAA
  LD (HL),A
  POP HL
  RET

; The score's eight digits (Digits $D3A0) at $5077
;
; Witness: L1 15175 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawScore:
  LD L,$77
  EXX
  LD DE,Score
  LD B,$04
l_AE68:
  LD A,(DE)
  RRCA
  RRCA
  RRCA
  RRCA
  CALL DrawDigit
  LD A,(DE)
  INC DE
  CALL DrawDigit
  DJNZ l_AE68
  RET

; One digit
;
; Witness: L1 121401 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawDigit:
  EXX
  AND $0F
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD DE,Digits
  ADD A,E
  LD E,A
  JR NC,l_AE87
  INC D
l_AE87:
  LD C,L
  LD A,$02
l_AE8A:
  EX AF,AF'
  LD H,$50
  LD B,$04
l_AE8F:
  LD A,(DE)
  INC DE
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  LD (HL),A
  INC H
  DJNZ l_AE8F
  LD A,C
  ADD A,$20
  LD L,A
  EX AF,AF'
  DEC A
  JP NZ,l_AE8A
  LD L,C
  INC L
  EXX
  RET

; Matt's energy, $FF full, 0 dead
Energy:
  DEFB $00
EnergyShown:
  DEFB $00                ; the energy last drawn

; The 8-cell energy bar at $506D, partial cells from EnergyParts
;
; Witness: L1 15170 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawEnergyBar:
  LD A,(Energy)
  SRL A
  SRL A
  LD HL,EnergyShown
  CP (HL)
  LD (HL),A
  RET Z
  LD E,A
  LD HL,Screen+4205
  SRL A
  SRL A
  SRL A
  JR Z,l_AEC9
  LD B,A
  LD C,$FF
l_AEC4:
  CALL FillCell
  DJNZ l_AEC4
l_AEC9:
  LD A,E
  AND $07
  LD DE,EnergyParts
  ADD A,E
  LD E,A
  JP NC,l_AED5
  INC D
l_AED5:
  LD A,(DE)
  LD C,A
  CALL FillCell
  LD C,$00
l_AEDC:
  LD A,L
  CP $75
  RET Z
  CALL FillCell
  JR l_AEDC

; Fill a cell's three lines with C
;
; Witness: L1 1360 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FillCell:
  PUSH HL
  PUSH BC
  LD B,$03
l_AEE9:
  LD A,H
  LD (HL),C
  INC H
  LD (HL),C
  INC H
  LD (HL),C
  INC H
  LD (HL),C
  INC H
  LD (HL),C
  INC H
  LD (HL),C
  INC H
  LD (HL),C
  INC H
  LD (HL),C
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
  DJNZ l_AEE9
  POP BC
  POP HL
  INC L
  RET

; The 8 partial-cell patterns
EnergyParts:
  DEFB $00,$80,$C0,$E0,$F0,$F8,$FC,$FE
PassCounter:
  DEFB $00,$00            ; counted up every main loop pass (the icon blink,
                          ; the jump's timing)
MaskNameShown:
  DEFB $00                ; the mask name on the scroller
ScrollerLeft:
  DEFB $00                ; characters left to scroll
ScrollerPtr:
  DEFB $00,$00            ; the next character
ScrollerShift:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the pixel step
  DEFB $00
PickupRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; two pick-up records of 8 bytes: y, x
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; ($FF once taken), kind, map address,
                                       ; PickupTable address, first sprite
                                       ; character
MaskSlots:
  DEFB $61,$00,$00,$00,$64,$00,$00,$00 ; four slots [screen column, kind, BCD
  DEFB $67,$00,$00,$00,$6A,$00,$00,$00 ; charges, level]
MaskLevels:
  DEFB $00,$00,$00,$00,$00,$01,$01,$03 ; the level a kind starts with, per kind
  DEFB $02,$06,$01                     ; 0-10
MaskColours:
  DEFB $00,$04,$02,$03,$04,$05,$06,$07 ; the icon colour per kind
  DEFB $07,$02,$03
CurrentSlot:
  DEFB $00,$00            ; the MaskSlots slot in use

; Blink the slot in use and redraw its charges
;
; Witness: L1 15390 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawCurrentSlot:
  LD IX,(CurrentSlot)
  LD H,$50
  LD L,(IX+$00)
  PUSH HL
  LD A,(IX+$01)
  CALL DrawIcon
  POP DE
  LD A,E
  ADD A,$40
  LD E,A
  LD A,(IX+$02)

; Print the BCD bytes at HL; its only caller is the menu's HISCORE ($9D35), the
; score in play is DrawScore $AE60
;
; Witness: L1 15546 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).
PrintBcd:
  PUSH AF
  RRCA
  RRCA
  RRCA
  RRCA
  CALL PrintBcdByte
  POP AF

; Two digits
;
; Witness: L1 31091 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).
PrintBcdByte:
  AND $0F
  ADD A,$30
  CP $3A
  JP C,PrintChar
  ADD A,$07
  JP PrintChar

; Interrupt: scroll the message line (row 23) one step
;
; Witness: L1 45122 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).
Scroller:
  LD A,(ScrollerLeft)
  AND A
  JR NZ,l_AFA2
  LD A,(MessageState+$0003)
  AND A
  JR Z,l_AF9D
  LD HL,(MessageState)
  LD (ScrollerPtr),HL
  LD A,(MessageState+$0002)
  LD (ScrollerLeft),A
  JP Scroller
l_AF9D:
  XOR A
  LD (ScrollerShift),A
  RET
l_AFA2:
  LD A,(ScrollerShift)
  DEC A
  CALL Z,ScrollerNextChar
  LD (ScrollerShift),A
  LD HL,ScrollerShift+$0002
  EXX
  LD B,$06
  LD HL,Screen+4587
l_AFB5:
  LD E,L
  EXX
  SLA (HL)
  INC HL
  EXX
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  LD L,E
  INC H
  DJNZ l_AFB5
  RET

; The next character's glyph into $AF15
;
; Witness: L1 2728 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
ScrollerNextChar:
  LD HL,(ScrollerPtr)
  LD A,(HL)
  INC HL
  LD (ScrollerPtr),HL
  CALL CharGlyph
  LD DE,ScrollerShift+$0003
  LD BC,$0005
  LDIR
  LD HL,ScrollerLeft
  DEC (HL)
  LD A,$08
  RET

; The four slots' icons and charges
;
; Witness: L1 38 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawAllSlots:
  LD A,(PassCounter)
  PUSH AF
  XOR A
  LD (PassCounter),A
  LD HL,(CurrentSlot)
  PUSH HL
  LD HL,MaskSlots
  LD B,$04
l_B00B:
  PUSH HL
  PUSH BC
  LD (CurrentSlot),HL
  CALL DrawCurrentSlot
  POP BC
  POP HL
  LD DE,$0004
  ADD HL,DE
  DJNZ l_B00B
  POP HL
  LD (CurrentSlot),HL
  POP AF
  LD (PassCounter),A
  RET

; A mask icon (MaskIcons $D580 + 32 x kind) at slot IX
;
; While PassCounter bit 3 is set the current slot gets icon 0 (EMPTY, 32 zero
; bytes, a blank): the blink of the slot in use.
;
; Witness: L1 15390 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawIcon:
  PUSH AF
  PUSH HL
  EX DE,HL
  LD H,$00
  LD L,A
  LD A,(PassCounter)
  BIT 3,A
  JR Z,l_B032
  LD L,H
l_B032:
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,MaskIcons
  ADD HL,BC
  LD B,$02
l_B03D:
  LD C,$02
  PUSH DE
l_B040:
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  LD A,(HL)
  INC HL
  LD (DE),A
  LD A,D
  SUB $07
  LD D,A
  LD A,E
  ADD A,$20
  LD E,A
  DEC C
  JP NZ,l_B040
  POP DE
  INC E
  DJNZ l_B03D
  POP HL
  POP AF
  LD H,$5A
  ADD A,$46
  LD E,A
  LD A,$00
  ADD A,$AF
  LD D,A
  LD A,(DE)
  OR $40
  LD (HL),A
  INC L
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC L
  LD (HL),A
  RET

; Keys 1-4 (port $F7FE) choose the slot, not while dying
;
; Witness: L1 15175 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
MaskKeys:
  LD A,(Dying)
  AND A
  RET NZ
  LD A,$F7
  IN A,($FE)
  AND $0F
  CP $0F
  RET Z
  PUSH AF
  CALL EndPenetrator
  POP AF
  LD C,A
  LD B,$00
l_B09F:
  INC B
  SRL C
  JR C,l_B09F
  LD HL,$0000
  LD DE,$0004
  JR l_B0AD
l_B0AC:
  ADD HL,DE
l_B0AD:
  DJNZ l_B0AC
  LD IX,MaskSlots
  EX DE,HL
  ADD IX,DE
  LD A,(IX+$01)
  AND A
  RET Z
  LD A,$06
  LD (PassCounter),A
  PUSH IX
  CALL DrawCurrentSlot
  POP IX
  LD (CurrentSlot),IX
  LD A,(IX+$01)

; Scroll the name of mask kind A
;
; Witness: L1 79 (c1, door3, masks, rzx- x9).
ShowMaskName:
  LD HL,MaskNameShown
  CP (HL)
  RET Z
  LD (MaskNameShown),A
  LD H,$00
  LD L,A
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,DE
  LD DE,MaskNames
  ADD HL,DE
  XOR A
  LD (MessageState+$0003),A
  LD A,$0C

; l_B0EA
;
; Used by the routine at ShowMessage.
l_B0EA:
  LD (ScrollerPtr),HL
  LD (ScrollerLeft),A
  LD A,(ScrollerShift)
  AND A
  RET NZ
  LD A,$01
  LD (ScrollerShift),A
  RET

; the message scroller's state
MessageState:
  DEFB $00,$00,$00,$00

; Start scrolling the message at HL
;
; Witness: L1 25 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).
ShowMessage:
  LD A,$FF
  LD (MaskNameShown),A
  LD (MessageState+$0003),A
  PUSH HL
  XOR A
l_B109:
  INC A
  BIT 7,(HL)
  JR NZ,l_B111
  INC HL
  JR l_B109
l_B111:
  POP HL
  LD (MessageState),HL
  LD (MessageState+$0002),A
  JP l_B0EA

; Matt pressing down (state 4) takes the pick-up under him
;
; Witness: L1 1254 (c1, door, door3, play2, rzx- x9).
CheckPickupsDown:
  LD IX,PickupRecords
  CALL CheckPickups
  LD IX,PickupRecords+$0008

; Take the mask at Matt's place into a slot with 99 charges and its kind's
; level
;
; The slot: the current one if EMPTY (its name shown), else the first EMPTY
; slot, else the current one, whose mask is replaced (there is no test for a
; slot of the same kind: rzx-16000 frame 49, BLASTER replaced by HEALER).
;
; Witness: L1 2508 (c1, door, door3, play2, rzx- x9).
CheckPickups:
  LD A,(IX+$01)
  INC A
  RET Z
  LD A,(Objects+$0003)
  SUB $36
  SRL A
  SRL A
  LD L,A
  LD A,(RoomScreen)
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  SUB (IX+$01)
  CP $04
  RET NC
  LD (IX+$01),$FF
  LD C,(IX+$02)
  LD L,(IX+$05)
  LD H,(IX+$06)
  SET 7,(HL)
  LD IX,(CurrentSlot)
  LD A,(IX+$01)
  AND A
  CALL Z,ShowNameKeep
  CALL NZ,FindEmptySlot
  LD (IX+$01),C
  LD (IX+$02),$99
  LD B,$00
  LD HL,MaskLevels
  ADD HL,BC
  LD A,(HL)
  LD (IX+$03),A
  CALL DrawAllSlots
  RET

; The first EMPTY slot
;
; Witness: L1 5 (rzx-00000, rzx-16000).
FindEmptySlot:
  PUSH BC
  LD IX,MaskSlots
  LD DE,$0004
  LD B,$04
l_B17E:
  LD A,(IX+$01)
  AND A
  JR Z,l_B18C
  ADD IX,DE
  DJNZ l_B17E
  LD IX,(CurrentSlot)
l_B18C:
  POP BC
  RET

; ShowMaskName keeping AF and BC
;
; Witness: L1 7 (c1, rzx- x5).
ShowNameKeep:
  PUSH AF
  PUSH BC
  LD A,C
  CALL ShowMaskName
  POP BC
  POP AF
  RET

; The 11 names of 11 characters: EMPTY, PENETRATOR, ULTRA FLASH, MIRAGE,
; HEALER, JACKRABBIT, LIFTER, BLASTER, BACKLASH, LAVA SHOT, STREAMER
MaskNames:
  INCBIN "res/texts/masks.bin",$0000,121

; Take A charges (BCD) from the slot in use; at none it becomes EMPTY; carry
; when there were not enough
;
; Witness: L1 649 (c1, cheat, door3, masks, rzx- x9).
UseCharge:
  EX AF,AF'
  LD A,(CheatOn)
  AND A
  RET NZ
  EX AF,AF'
  LD IY,(CurrentSlot)
  PUSH BC
  LD C,A
  LD A,(IY+$02)
  SUB C
  POP BC
  DAA
  LD (IY+$02),A
  JR Z,l_B22D
  RET NC
  LD (IY+$02),$00
l_B22D:
  LD (IY+$01),$00
  EX AF,AF'
  XOR A
  CALL ShowMaskName
  EX AF,AF'
  RET

; A flag of the never-run MaskEffect
UnusedFlag:
  DEFB $00

; Never run: ULTRA FLASH flashes the border, HEALER gives 1 energy a charge
;
; Known only from the code: no instruction calls $B239.
MaskEffect:
  LD IX,(CurrentSlot)
  LD A,(IX+$01)
  AND A
  RET Z
  CP $02
  JR NZ,l_B260
  LD A,(UnusedFlag)
  AND A
  RET Z
  DEC A
  LD (UnusedFlag),A
  BIT 0,A
  LD A,$00
  JR NZ,l_B257
  LD A,$07
l_B257:
  LD (BorderColour),A
  LD A,$01
  CALL UseCharge
  RET
l_B260:
  CP $04
  RET NZ
  LD A,(Energy)
  CP $FF
  RET Z
  INC A
  LD (Energy),A
  AND $03
  RET NZ
  LD A,$01
  CALL UseCharge
  RET

; Draw the pick-up icons into the character map, keeping the backgrounds
;
; Witness: L1 15361 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
PlacePickups:
  LD DE,PickupSaves
  LD IX,PickupRecords
  CALL PlaceOnePickup
  LD IX,PickupRecords+$0008
  CALL PlaceOnePickup
  LD (PickupSavePtr),DE

; One icon
;
; Witness: L1 46083 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
PlaceOnePickup:
  LD A,(IX+$01)
  INC A
  RET Z
  LD L,(IX+$03)
  LD H,(IX+$04)
  PUSH HL
  LD C,(IX+$07)
  LD B,$02
l_B29C:
  LD A,(HL)
  LD (DE),A
  INC DE
  LD (HL),C
  INC L
  LD A,(HL)
  LD (DE),A
  INC DE
  INC C
  INC C
  LD (HL),C
  DEC C
  LD A,L
  ADD A,$1F
  LD L,A
  JR NC,l_B2AF
  INC H
l_B2AF:
  DJNZ l_B29C
  POP HL
  INC H
  INC H
  INC H
  LD C,$02
  LD (HL),C
  INC L
  LD (HL),C
  LD A,L
  ADD A,$1F
  LD L,A
  JR NC,l_B2C1
  INC H
l_B2C1:
  LD (HL),C
  INC L
  LD (HL),C
  RET

; The backgrounds back
;
; Witness: L1 15357 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
RestorePickups:
  LD DE,PickupSaves
  LD IX,PickupRecords
  CALL RestoreOnePickup
  LD IX,PickupRecords+$0008

; One
;
; Witness: L1 30714 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
RestoreOnePickup:
  LD A,(IX+$01)
  INC A
  RET Z
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD B,$02
l_B2E0:
  LD A,(DE)
  INC DE
  LD (HL),A
  INC L
  LD A,(DE)
  INC DE
  LD (HL),A
  LD A,L
  ADD A,$1F
  LD L,A
  JR NC,l_B2EE
  INC H
l_B2EE:
  DJNZ l_B2E0
  RET

; The deadly floor and the items under Matt
;
; Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
Hazards:
  CALL DeadlyFloor
  CALL TakeBlockItem
  RET

; non-zero: Matt dies this pass (MainLoop jumps to Death)
DeathFlag:
  DEFB $00

; Matt on character $EA ($ED in zone 3) dies
;
; Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DeadlyFloor:
  LD A,(CheatOn)
  AND A
  RET NZ
  LD A,(ZoneSlots)
  CP $02
  CALL Z,MoonFloor
  LD C,$EA
  LD A,(ZoneSlots)
  CP $03
  JR NZ,l_B311
  LD C,$ED
l_B311:
  LD HL,(MattPlace+$0002)
  LD DE,$0081
  ADD HL,DE
  LD A,(HL)
  CP C
  JR NZ,l_B321
  LD A,$FF
  LD (DeathFlag),A
l_B321:
  INC HL
  LD A,(HL)
  CP C
  JR NZ,l_B32B
  LD A,$FF
  LD (DeathFlag),A
l_B32B:
  RET

; Zone 2: the character under Matt from $FE up kills
;
; Witness: L1 522 (door3, rzx-28000).
MoonFloor:
  LD HL,(MattPlace+$0002)
  LD DE,$0081
  ADD HL,DE
  LD A,(HL)
  CP $FE
  RET C
  LD A,$FF
  LD (DeathFlag),A
  RET

; A block-$1B item touched: block $47 in the map, an object, energy - $19
;
; The y test has only one bound (Matt's y + 20 at least the item's y). No
; recording took an item: the effect is known only from the code.
;
; Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
TakeBlockItem:
  LD A,(PenetratorOn)
  AND A
  RET NZ
  LD IX,BlockItems
  LD B,$04
  LD DE,$0004
  LD A,(Objects+$0003)
  LD L,A
  LD A,(Objects+$0004)
  LD H,A
l_B353:
  LD A,L
  ADD A,$0A
  SUB (IX+$00)
  JR C,l_B369
  CP $0E
  JR NC,l_B369
  LD A,H
  ADD A,$14
  SUB (IX+$01)
  JR C,l_B369
  JR l_B36E
l_B369:
  ADD IX,DE
  DJNZ l_B353
  RET
l_B36E:
  LD A,(IX+$01)
  ADD A,$08
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$00)
  SUB $40
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,CharMap+$0040
  ADD HL,DE
  XOR A
  LD (HL),A
  INC L
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC L
  LD (HL),A
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD (HL),$47
  LD IY,Enemies
  LD DE,$0026
  LD B,$06
l_B3A7:
  LD A,(IY+$00)
  AND $7F
  JR Z,l_B3B4
  ADD IY,DE
  DJNZ l_B3A7
  JR l_B3D8
l_B3B4:
  LD A,(IX+$00)
  LD (IX+$00),$00
  LD (IY+$03),A
  LD A,(IX+$01)
  ADD A,$08
  LD (IY+$04),A
  PUSH IY
  POP IX
  LD HL,EnemyTemplates+$00CC
  CALL Explode
  LD (IX+$1B),$00
  LD (IX+$1C),$FE
l_B3D8:
  LD A,(Energy)
  SUB $19
  LD (Energy),A
  RET NC
  XOR A
  LD (Energy),A
  RET

; Matt's map places: $B3E6 and $B3E8 (character map addresses)
MattPlace:
  DEFB $00,$00,$00,$00
PenetratorOn:
  DEFB $00                ; non-zero while PENETRATOR is used: Matt walks
                          ; through walls

  ORG $BC96

; Z when Matt's shot overlaps object IX (not an explosion, not kind 10); +$22 =
; the shot's power
;
; Witness: L1 91060 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
ShotHits:
  LD A,(MattShot)
  AND A
  JR Z,l_BCDD
  LD A,(IX+$00)
  AND $BF
  JR Z,l_BCDD
  CP $03
  JR Z,l_BCDD
  LD A,(MattShot+$0003)
  ADD A,$06
  SUB (IX+$03)
  LD L,A
  LD A,(IX+$05)
  ADD A,A
  ADD A,A
  ADD A,$04
  CP L
  JR C,l_BCDD
  LD A,(MattShot+$0004)
  ADD A,$0C
  SUB (IX+$04)
  LD L,A
  LD A,(IX+$06)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$08
  CP L
  JR C,l_BCDD
  LD A,(IX+$00)
  CP $0A
  JR Z,l_BCDD
  LD A,(MattShot+$0022)
  LD (IX+$22),A
  AND A
  RET
l_BCDD:
  OR $FF
  RET

; Fire with the mask in use: kinds 1-4 while fire is held, kinds 5-10 shoot on
; a new press
;
; Kind 1 PENETRATOR: PenetratorOn, Matt dissolves and walks through walls, a
; charge every second pass ($BE0E). Kinds 2 ULTRA FLASH and 3 MIRAGE: RET
; ($BE39, $BE3A), nothing happens. Kind 4 HEALER: Energy + 2 for a charge.
; Kinds 5-10 fire Matt's shot (MattShot $A465, picture $D6E0, animation kind -
; 5, effect kind - 5, power = the slot's level) for a charge, LIFTER 8 charges;
; LIFTER's shot sets +$22 = $FF. JACKRABBIT also jumps far (MattLongJump).
;
; Witness: L1 15176 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
FireMask:
  LD A,(Dying)
  AND A
  RET NZ
  LD A,(Objects)
  CP $0A
  JP Z,EndPenetrator
  LD IX,(CurrentSlot)
  LD A,(IX+$01)
  AND A
  RET Z
  CP $05
  JP C,HeldMasks
  LD A,(Controls)
  BIT 4,A
  RET Z
  LD A,(ControlsLast)
  BIT 4,A
  RET NZ
  LD A,(MattShot)
  AND A
  RET NZ
  LD C,$01
  LD A,(IX+$01)
  CP $06
  JR NZ,l_BD17
  LD C,$08
l_BD17:
  LD A,C
  CALL UseCharge
  JR NC,l_BD1E
  RET
l_BD1E:
  LD A,(IX+$01)
  SUB $05
  CALL PlayEffect
  LD IY,MattShot
  LD A,(Objects+$0004)
  ADD A,$05
  LD (MattShot+$0004),A
  LD A,(Objects+$0002)
  ADD A,A
  LD A,(Objects+$0003)
  JR C,l_BD45
  LD E,$06
  LD (IY+$02),$00
  ADD A,$04
  JR l_BD4B
l_BD45:
  LD E,$FA
  LD (IY+$02),$FF
l_BD4B:
  ADD A,$02
  LD (MattShot+$0003),A
  LD (IY+$1B),E
  LD (IY+$00),$01
  LD A,(IX+$01)
  SUB $05
  LD (IY+$18),A
  LD (IY+$16),$E0
  LD (IY+$17),$D6
  LD A,(IX+$03)
  LD (IY+$21),A
  LD A,(IX+$01)
  CP $06
  JR Z,l_BD79
  XOR A
  LD (IY+$22),A
  RET
l_BD79:
  OR $FF
  LD (IY+$22),A
  RET

; Matt's shot gone
;
; Witness: L1 86 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
ShotOff:
  XOR A
  LD (MattShot),A
  RET

; Matt's shot: x + dx; gone off $38-$C3 or in a wall
;
; Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
MoveShot:
  LD IX,MattShot
  LD A,(IX+$03)
  ADD A,(IX+$1B)
  LD (IX+$03),A
  CP $38
  JR C,l_BD9F
  CP $C4
  JR NC,l_BD9F
  CALL HitsWall
  JR C,l_BD9F
  RET
l_BD9F:
  LD (IX+$00),$00
  RET

; HeldMasks
;
; Used by the routine at FireMask.
HeldMasks:
  LD A,(Controls)         ; kinds 1-4
  BIT 4,A
  JR Z,EndPenetrator
  LD A,(IX+$01)
  CP $01
  JP Z,Penetrator
  CP $02
  JP Z,UltraFlash
  CP $03
  JP Z,Mirage
  LD A,(Energy)
  CP $FF
  RET Z
  ADD A,$02
  JR NC,l_BDC9
  LD A,$FF
l_BDC9:
  LD (Energy),A
  LD A,$01
  JP UseCharge

; Fire released after PENETRATOR: Matt inside a wall dies (Explosion, GameOver)
;
; Witness: L1 1143 (c1, door, door3, masks, rzx- x8).
EndPenetrator:
  LD A,(PenetratorOn)
  AND A
  RET Z
  XOR A
  LD (PenetratorOn),A
  DEC A
  LD (EffectStops),A
  LD HL,(MattPlace+$0002)
  INC L
  LD DE,$001F
  LD B,$03
l_BDE7:
  CALL IsSolid
  JR C,l_BDF7
  INC L
  CALL IsSolid
  JR C,l_BDF7
  ADD HL,DE
  DJNZ l_BDE7
  JR l_BE02
l_BDF7:
  LD A,$FF
  LD (Dying),A
  CALL Explosion
  JP GameOver
l_BE02:
  LD A,(DissolveCount)
  CP $02
  RET NZ
  XOR A
  LD (DissolveCount),A
  RET

; Extra charges of the next PENETRATOR step: KindChaser $C68E sets $10 (BCD, 10
; charges) every pass it runs while PenetratorOn; Penetrator $BE23 adds it to
; (PassBcd AND 1) and clears it
PenetratorCost:
  DEFB $00

; Penetrator
;
; Used by the routine at HeldMasks.
Penetrator:
  LD A,(PenetratorOn)     ; kind 1 held
  AND A
  JR NZ,l_BE1E
  LD A,$FF
  LD (PenetratorOn),A
  LD A,$07
  CALL PlayEffect
l_BE1E:
  LD A,$02
  LD (DissolveCount),A
  LD HL,PenetratorCost
  LD A,(PassBcd)
  AND $01
  ADD A,(HL)
  LD (HL),$00
  CALL UseCharge
  LD A,(IX+$01)
  AND A
  RET NZ
  JP EndPenetrator

; UltraFlash
;
; Used by the routine at HeldMasks.
UltraFlash:
  RET                     ; RET: ULTRA FLASH does nothing when fired

; Mirage
;
; Used by the routine at HeldMasks.
Mirage:
  RET                     ; RET: MIRAGE does nothing when fired

; 20 records of 12 bytes: score (BCD word), picture, damage, animation, mask,
; width, height, mode, hits, colour
;
; Copied into an object by SetupObject $BFF5: +$14/+$15, +$16/+$17, +$1E, +$18,
; +$1A, +5, +6, +$19, +$21, +$20 (bit 7 set: a random colour 1-7). Byte 10, the
; hits: 255 = never shot down (template 13, kind 10). Also
; src/res/tables/enemies.csv.
EnemyTemplates:
  INCBIN "res/tables/enemies.bin",$0000,240

; An empty object gets the screen's enemy kind (EnemyKind), every pass for
; kinds 5, 6, 8-10, else at random
;
; Witness: L1 91061 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
Spawn:
  LD A,(IX+$00)
  AND $7F
  RET NZ
  LD A,(EnemyKind)
  CP $05
  JR Z,l_BF4F
  CP $06
  JR Z,l_BF4F
  CP $08
  JR Z,l_BF4F
  CP $09
  JR Z,l_BF4F
  CP $0A
  JR Z,l_BF4F
  CALL Random
  AND $2E
  JR NZ,SpawnNothing
l_BF4F:
  LD A,(ChaserState)
  AND A
  JP NZ,SpawnNothing
  LD A,(EnemyKind)
  LD L,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  LD DE,SpawnJumps
  ADD HL,DE
  JP (HL)

; SpawnNothing
;
; Used by the routines at Spawn, SpawnGuard and SpawnBoss.
SpawnNothing:
  LD A,(Enemies)          ; mark the slot used, 2 x 2, kind none
  CP $08
  RET Z
  LD (IX+$03),$01
  LD (IX+$04),$00
  LD (IX+$05),$02
  LD (IX+$06),$02
  LD (IX+$00),$80
  RET

; ReviveObjects
;
; Used by the routine at RunObjects.
ReviveObjects:
  LD IX,Enemies           ; all six slots 0 ($40 and $80 count as taken):
                          ; object 2 back as a placeholder $80, 4 x 5 at x 1, y
                          ; 0, mode 6
  LD B,$06
  LD DE,$0026
  LD A,$00
l_BF8A:
  OR (IX+$00)
  ADD IX,DE
  DJNZ l_BF8A
  AND A
  RET NZ
  LD IX,Enemies
  LD (IX+$00),$80
  LD (IX+$05),$04
  LD (IX+$06),$05
  LD (IX+$04),$00
  LD (IX+$03),$01
  LD (IX+$19),$06
  RET

; The screen's enemy kind (RoomTable bytes 6-11)
EnemyKind:
  DEFB $00

; SpawnJumps
SpawnJumps:
  RET                     ; RET for kind 0, then JP the spawner of kinds 1-10

; Two bytes after kind 0's RET
SpawnJumpPad:
  DEFB $00,$00

; SpawnJumps1
SpawnJumps1:
  JP SpawnFlyer           ; kinds 1-5

; l_BFB7
l_BFB7:
  JP SpawnFaller

; l_BFBA
l_BFBA:
  JP SpawnWave

; l_BFBD
l_BFBD:
  JP SpawnWalker

; l_BFC0
l_BFC0:
  JP SpawnChaser

; JP SpawnKind6 $C0F7 (room 1, screen 2)
;
; No play recording reached room 1's screen 2, the only screen of kind 6
; (src/res/tables/rooms.csv); work/stage2/rec/kind6 POKEs EnemyKind $BFB0 = 6
; in room 0 (a cheat, said so in its script).
SpawnJump6:
  JP SpawnKind6

; SpawnJumps7
SpawnJumps7:
  JP SpawnRiser           ; kinds 7-9

; l_BFC9
l_BFC9:
  JP SpawnGuard

; l_BFCC
l_BFCC:
  JP SpawnBoss

; JP SpawnKind10 $C1F3 (room 7, screens 2 and 3)
;
; No play recording reached room 7's screens 2-3, the only screens of kind 10;
; work/stage2/rec/door3 POKEs EnemyKind $BFB0 = 10 in room 7, screen 0 (a
; cheat, said so in its script).
SpawnJump10:
  JP SpawnKind10

; SpawnFlyer
;
; Used by the routine at SpawnJumps1.
SpawnFlyer:
  LD A,(Objects+$0003)    ; kind 1: a flyer from the right that homes on Matt's
                          ; height (object kind 2)
  CP $91
  RET NC
  LD (IX+$00),$02
  LD (IX+$03),$C8
  CALL Random
  AND $3F
  LD (IX+$04),A
  CALL Random
  AND $1F
  SUB $0C
  LD (IX+$11),A
  LD HL,EnemyTemplates+$000C

; Copy the 12-byte template at HL into object IX
;
; Witness: L1 634 (door, door3, kind6, rzx- x9).
SetupObject:
  LD A,(HL)
  LD (IX+$14),A
  INC HL
  LD A,(HL)
  LD (IX+$15),A
  INC HL
  LD A,(HL)
; This entry point is used by the routine at Interrupt.
  LD (IX+$16),A
; This entry point is used by the routine at Interrupt.
  INC HL
  LD A,(HL)
  LD (IX+$17),A
  INC HL
  LD A,(HL)
; This entry point is used by the routine at Interrupt.
  LD (IX+$1E),A
  INC HL
  LD A,(HL)
  LD (IX+$18),A
  INC HL
  LD A,(HL)
  LD (IX+$1A),A
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  INC HL
  LD A,(HL)
  LD (IX+$06),A
  INC HL
  LD A,(HL)
  LD (IX+$19),A
  INC HL
  LD A,(HL)
  LD (IX+$21),A
  INC HL
  LD A,(HL)
  AND A
  JP P,l_C038
l_C031:
  CALL Random
  AND $07
  JR Z,l_C031
l_C038:
  OR $40
  LD (IX+$20),A
  XOR A
  LD (IX+$1D),A
  LD (IX+$02),A
  LD (IX+$1B),A
  LD (IX+$1C),A
  RET

; SpawnFaller
;
; Used by the routine at l_BFB7.
SpawnFaller:
  LD (IX+$00),$01         ; kind 2: from the top (object kind 1); dy = (x AND
                          ; 3) + 2 (2-5), dx = (Random AND 3) - 1, drawn again
                          ; when it is 2: -1, 0 or +1
  LD HL,EnemyTemplates
  CALL SetupObject
  LD (IX+$04),$E0
  CALL Random
  AND $7F
  ADD A,$40
  LD (IX+$03),A
  AND $03
  ADD A,$02
  LD (IX+$1C),A
l_C06A:
  CALL Random
  AND $03
  DEC A
  CP $02
  JR Z,l_C06A
  LD (IX+$1B),A
  CALL Random
  LD (IX+$02),A
  RET

; SpawnWave
;
; Used by the routine at l_BFBA.
SpawnWave:
  CALL Random             ; kind 3: a flyer on a wave (object kind 6), when
                          ; Random AND $44 = 0 and Matt's x < $91
  AND $44
  RET NZ
  LD A,(Objects+$0003)
  CP $91
  RET NC
  LD (IX+$00),$06
  CALL Random
  AND $0F
  ADD A,$C6
  LD (IX+$03),A
  CALL Random
  AND $07
  LD (IX+$11),A
  LD HL,EnemyTemplates+$0030
  JP SetupObject

; SpawnWalker
;
; Used by the routine at l_BFBD.
SpawnWalker:
  LD A,(IX+$1F)           ; kind 4: once a screen, a walker on FloorRow (object
                          ; kind 7)
  AND A
  RET NZ
  LD (IX+$1F),$FF
  LD (IX+$00),$07
  LD HL,EnemyTemplates+$003C
  CALL SetupObject
  LD (IX+$03),$C6
  LD A,(FloorRow)
  SUB $0F
  LD (IX+$04),A
  LD (IX+$1B),$FE
  LD (IX+$1C),$14
  LD (IX+$11),$00
  LD (IX+$12),$01
  RET

; one chaser at a time, and its timer ($0300)
ChaserState:
  DEFB $00,$00,$00

; SpawnChaser
;
; Used by the routine at l_BFC0.
SpawnChaser:
  LD A,(ChaserState)      ; kind 5: the chaser (object kind 8)
  AND A
  RET NZ
  LD (IX+$00),$08
  LD (IX+$04),$32
  LD A,$FF
  LD (ChaserState),A
  LD HL,$0300
  LD (ChaserState+$0001),HL
  LD HL,EnemyTemplates+$0048
  JP SetupObject

; Kind 6 (room 1, screen 2): object kind 16
;
; Run only with the EnemyKind POKE of work/stage2/rec/kind6 (frames 675-1891).
;
; Witness: L1 1919 (kind6).
SpawnKind6:
  LD A,(IX+$1F)
  AND A
  RET NZ
  LD A,$0A
  CALL PlayEffect
  CALL MarkOnce
  LD (IX+$00),$10
  LD (IX+$03),$DC
  LD (IX+$04),$00
  LD HL,EnemyTemplates+$0090
  JP SetupObject

; SpawnRiser
;
; Used by the routine at SpawnJumps7.
SpawnRiser:
  LD DE,(SpawnPoints)     ; kind 7: from SpawnPoints (object kind 12)
  LD HL,(SpawnPoints+$0002)
  LD A,D
  OR E
  RET Z
  LD A,H
  OR L
  JR Z,l_C12B
  CALL Random
  RRCA
  JR C,l_C12B
  EX DE,HL
l_C12B:
  LD (IX+$00),$0C
  LD HL,EnemyTemplates+$0060
  CALL SetupObject
  LD A,E
  ADD A,$0A
  LD (IX+$04),A
  CALL Random
  AND $07
  ADD A,D
  LD (IX+$03),A
  SUB D
  SUB $04
  LD (IX+$1B),A
  CALL Random
  AND $07
  ADD A,$05
  NEG
  LD (IX+$1C),A
  CALL Random
  RRCA
  LD (IX+$02),A
  LD A,$01
  JR C,l_C163
  LD A,$FF
l_C163:
  LD (IX+$11),A
  RET

; SpawnGuard
;
; Used by the routine at l_BFC9.
SpawnGuard:
  LD A,(IX+$1F)           ; kind 8: once a screen (object kind 13)
  AND A
  JP NZ,SpawnNothing
  CALL MarkOnce
  LD (IX+$00),$0D
  LD (IX+$03),$60
  LD (IX+$04),$E2
  LD HL,EnemyTemplates+$006C
  CALL SetupObject
  LD (IX+$1C),$08
  LD (IX+$11),$00
  RET

; Set +$1F of the six objects
;
; Witness: L1 3 (kind6, rzx-00000, rzx-24000).
MarkOnce:
  LD IY,Enemies
  LD DE,$0026
  LD B,$06
l_C195:
  LD (IY+$1F),$FF
  ADD IY,DE
  DJNZ l_C195
  RET

; SpawnBoss
;
; Used by the routine at l_BFCC.
SpawnBoss:
  LD A,(IX+$1F)           ; kind 9: once, on the floor (object kind 14)
  AND A
  JP NZ,SpawnNothing
  PUSH IX
  CALL MarkOnce
  LD IX,Enemies
  LD (IX+$00),$80
  LD (IX+$05),$02
  LD (IX+$06),$02
  LD (IX+$03),$01
  LD IX,Enemies+$0026
  LD (IX+$03),$A4
  LD HL,CharMap+$0059
  LD C,$00
  LD DE,$0020
l_C1CE:
  CALL IsSolid
  JR C,l_C1D7
  ADD HL,DE
  INC C
  JR l_C1CE
l_C1D7:
  LD A,C
  ADD A,A
  ADD A,A
  ADD A,A
  SUB $20
  LD (IX+$04),A
  LD (IX+$00),$0E
  LD (IX+$1F),$FF
  LD HL,EnemyTemplates+$0078
  CALL SetupObject
  POP IX
  RET

; Two zero bytes
SpawnPad:
  DEFB $00,$00

; Kind 10 (room 7, screens 2-3): a group of objects of kinds 18 and 19
;
; Run only with the EnemyKind POKE of work/stage2/rec/door3 (frame 1478).
;
; Witness: L1 1 (door3).
SpawnKind10:
  LD A,(IX+$23)
  CP $01
  RET NZ
  LD A,(IX+$1F)
  AND A
  JR Z,l_C203
  DEC (IX+$1F)
  RET
l_C203:
  LD A,(Enemies)
  AND $3F
  RET NZ
  LD (IX+$1F),$32
  PUSH IX
  LD C,$C0
  LD IX,Enemies
  LD DE,$0026
  LD (IX+$00),$12
  LD HL,EnemyTemplates+$009C
  CALL SetupObject
  LD (IX+$03),C
  LD (IX+$04),$50
  LD (IX+$11),$03
  LD (IX+$12),$00
  ADD IX,DE
  LD A,C
  ADD A,$06
  LD C,A
  LD B,$04
l_C239:
  LD (IX+$00),$13
  LD HL,EnemyTemplates+$00A8
  CALL SetupObject
  LD (IX+$03),C
  LD (IX+$04),$00
  LD (IX+$1B),$00
  LD A,C
  ADD A,$06
  LD C,A
  ADD IX,DE
  DJNZ l_C239
  LD (IX+$00),$13
  LD HL,EnemyTemplates+$00B4
  CALL SetupObject
  LD (IX+$03),C
  LD (IX+$04),$00
  LD (IX+$1B),$FF
  POP IX
  RET

; The zone's turret stem character (SwapZone writes TurretStems[zone] here);
; KindTurret draws it under a turret
TurretStem:
  DEFB $A7

; Object IX becomes an explosion (kind 3, 4 steps, template HL) with a random
; effect 11-14
;
; Witness: L1 272 (door, kind6, rzx- x9).
Explode:
  LD (IX+$10),$04
  LD (IX+$00),$03
  CALL SetupObject
  CALL Random
  AND $03
  ADD A,$0B
  JP PlayEffect

; The six objects: spawn, Matt's shot, the kind's routine; then ReviveObjects
;
; Witness: L1 15178 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
RunObjects:
  LD IX,Enemies
  LD B,$06
l_C28A:
  PUSH BC
  PUSH IX
  CALL Spawn
  LD (IX+$22),$00
  CALL ShotHits
  JR NZ,l_C2AB
  DEC (IX+$21)
l_C29C:
  LD IY,MattShot
  DEC (IY+$21)
  JR NZ,l_C2B1
  LD (IY+$00),$00
  JR l_C2B1
l_C2AB:
  LD A,(IX+$22)
  AND A
  JR NZ,l_C29C
l_C2B1:
  CALL RunKind
  POP IX
  POP BC
  LD DE,$0026
  ADD IX,DE
  DJNZ l_C28A
  JP ReviveObjects

; Score + the object's +$14/+$15
;
; Witness: L1 84 (kind6, rzx- x9).
AwardScore:
  LD D,(IX+$15)
  LD E,(IX+$14)
  JP AddScore

; Energy - the object's +$1E (not below 0)
;
; Witness: L1 133 (door, door3, kind6, rzx- x9).
Damage:
  LD A,(Energy)
  SUB (IX+$1E)
  LD (Energy),A
  RET NC
  XOR A
  LD (Energy),A
  RET

; Z when object IX overlaps Matt (never while PENETRATOR is on)
;
; Witness: L1 12174 (door, door3, kind6, rzx- x9).
TouchesMatt:
  LD A,(PenetratorOn)
  AND A
  JR NZ,l_C312
  LD A,(IX+$06)
  ADD A,A
  ADD A,A
  ADD A,A
  LD D,A
  LD A,(IX+$05)
  ADD A,A
  ADD A,A
  LD E,A
  LD A,(Objects+$0003)
  SUB (IX+$03)
  JR NC,l_C2FA
  CP $F6
  JR C,l_C312
  JR l_C2FF
l_C2FA:
  ADD A,$04
  CP E
  JR NC,l_C312
l_C2FF:
  LD A,(Objects+$0004)
  SUB (IX+$04)
  JR NC,l_C30D
  CP $E4
  JR C,l_C312
  XOR A
  RET
l_C30D:
  CP D
  JR NC,l_C312
  XOR A
  RET
l_C312:
  OR $FF
  RET

; JP the routine of kind +0 & $3F through ObjectJumps
;
; Witness: L1 91060 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
RunKind:
  LD A,(IX+$00)
  AND $3F
  RET Z
  LD L,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  LD DE,ObjectJumps
  ADD HL,DE
  JP (HL)

; JP of kinds 0-19: 0 HangLoop, 1 faller, 2 flyer, 3 explosion, 4 turret, 5
; turret shot, 6 wave, 7 walker, 8 chaser, 9-19 the rest
;
; Kinds 9 and 11 never ran in a recording (known for those only from the code);
; kinds 16, 18 and 19 ran only after an EnemyKind POKE (work/stage2/rec/kind6,
; door3).
ObjectJumps:
  JP HangLoop

; l_C329
l_C329:
  JP KindFaller

; l_C32C
l_C32C:
  JP KindFlyer

; l_C32F
l_C32F:
  JP KindExplosion

; l_C332
l_C332:
  JP KindTurret

; l_C335
l_C335:
  JP KindTurretShot

; l_C338
l_C338:
  JP KindWave

; l_C33B
l_C33B:
  JP KindWalker

; l_C33E
l_C33E:
  JP KindChaser

; KindNineJump
KindNineJump:
  DEFB $C3,$B7,$C6        ; JP KindNine: kind 9's slot; no recording spawned
                          ; kind 9, so its bytes stay data

; l_C344
l_C344:
  JP KindTen

; l_C347
l_C347:
  JP KindEleven

; l_C34A
l_C34A:
  JP KindTwelve

; l_C34D
l_C34D:
  JP KindThirteen

; l_C350
l_C350:
  JP KindFourteen

; l_C353
l_C353:
  JP KindFifteen

; l_C356
l_C356:
  JP KindSixteen

; l_C359
l_C359:
  JP KindSeventeen

; l_C35C
l_C35C:
  JP KindEighteen

; l_C35F
l_C35F:
  JP l_C9B8

; y + dy, then x + dx
;
; Witness: L1 4423 (door, kind6, rzx- x9).
MoveXY:
  LD A,(IX+$04)
  ADD A,(IX+$1C)
  LD (IX+$04),A

; MoveX
;
; Used by the routines at KindWalker, KindTen and KindTwelve.
MoveX:
  LD A,(IX+$03)           ; x + dx
  ADD A,(IX+$1B)
  LD (IX+$03),A
  RET

; KindFaller
;
; Used by the routine at l_C329.
KindFaller:
  LD A,(IX+$21)           ; 1
  AND A
  JR Z,l_C39D
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  INC (IX+$18)
  CALL MoveXY
  LD A,(IX+$04)
  ADD A,$30
  CP $A0
  JR NC,l_C3A0
  CALL HitsWall
  JR C,l_C3A0
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C39D:
  CALL AwardScore
l_C3A0:
  LD HL,EnemyTemplates+$00C0
  JP Explode

; KindFlyer
;
; Used by the routine at l_C32C.
KindFlyer:
  LD A,(IX+$21)           ; 2
  AND A
  JR Z,l_C3E3
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  INC (IX+$18)
  LD A,(IX+$03)
  SUB $02
  LD (IX+$03),A
  CP $28
  JR C,l_C3EC
  LD A,(Objects+$0004)
  ADD A,(IX+$11)
  CP (IX+$04)
  JR Z,l_C3D7
  JR C,l_C3D4
  INC (IX+$04)
  JR l_C3D7
l_C3D4:
  DEC (IX+$04)
l_C3D7:
  CALL HitsWall
  JR C,l_C3E6
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C3E3:
  CALL AwardScore
l_C3E6:
  LD HL,EnemyTemplates+$00CC
  JP Explode
l_C3EC:
  LD (IX+$00),$00
  RET

; KindExplosion
;
; Used by the routine at l_C32F.
KindExplosion:
  DEC (IX+$10)            ; 3
  JR NZ,l_C3FB
  LD (IX+$00),$00
  RET
l_C3FB:
  INC (IX+$18)
  JP MoveXY

; Carry when the object's corners touch a solid character
;
; Witness: L1 12137 (c1, cheat, door3, kind6, masks, rzx- x9).
HitsWall:
  LD A,(IX+$1D)
  AND A
  RET NZ
  LD A,(IX+$04)
  AND $80
  RET NZ
  LD H,A
  LD A,(IX+$04)
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$03)
  SUB $40
  AND A
  RET M
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,CharMap+$0040
  ADD HL,DE
  CALL IsSolid
  RET C
  LD E,L
  LD A,L
  AND $1F
  ADD A,(IX+$05)
  CP $20
  RET NC
  LD A,L
  ADD A,(IX+$05)
  DEC A
  LD L,A
  CALL IsSolid
  RET C
  LD L,E
  LD DE,$0020
  LD B,(IX+$06)
l_C447:
  ADD HL,DE
  DJNZ l_C447
  CALL IsSolid
  RET C
  LD A,L
  ADD A,(IX+$05)
  DEC A
  LD L,A
  JP IsSolid

; KindTurret
;
; Used by the routine at l_C332.
KindTurret:
  LD A,(IX+$21)           ; 4: bobs, now and then fires a turret shot (kind 5)
                          ; into slot+1 ($40) or a free slot+2 (AND $3F = 0),
                          ; then rises again for 6 passes (its animation reset
                          ; to 0); killed, Explode runs before AwardScore, so
                          ; the explosion template's score 0 is added: a turret
                          ; never scores
  AND A
  JP Z,l_C4D7
  LD A,(IX+$18)
  CP $03
  JR Z,l_C46E
  LD A,(PassBcd)
  RRCA
  RET C
  INC (IX+$18)
  RET
l_C46E:
  INC (IX+$1C)
  BIT 4,(IX+$1C)
  JR Z,l_C47C
  INC (IX+$04)
  JR l_C47F
l_C47C:
  DEC (IX+$04)
l_C47F:
  CALL ObjectCell
  LD (HL),$00
  LD DE,$0020
  ADD HL,DE
  LD A,(TurretStem)
  LD (HL),A
  CALL Random
  AND $53
  JR Z,l_C49D
  CALL TouchesMatt
  RET NZ
  CALL Damage
  JP l_C4D7
l_C49D:
  LD B,(IX+$04)
  LD C,(IX+$03)
  LD DE,$0026
  LD A,(IX+$26)
  CP $40
  JR Z,l_C4BD
  LD A,(IX+$4C)
  AND $3F
  RET NZ
  LD (IX+$18),$00
  ADD IX,DE
  ADD IX,DE
  JR l_C4C3
l_C4BD:
  LD (IX+$18),$00
  ADD IX,DE
l_C4C3:
  LD (IX+$00),$05
  LD A,C
  LD (IX+$03),A
  LD A,B
  ADD A,$04
  LD (IX+$04),A
  LD HL,EnemyTemplates+$0024
  JP SetupObject
l_C4D7:
  LD L,(IX+$11)
  LD H,(IX+$12)
  LD (HL),$2B
  LD HL,EnemyTemplates+$00CC
  CALL Explode
  CALL ObjectCell
  LD DE,$0020
  LD A,(TurretStem)
  LD B,A
l_C4EF:
  ADD HL,DE
  LD A,(HL)
  AND A
  JR Z,l_C4EF
  CP B
  JP NZ,AwardScore
  LD (HL),$00
  LD C,H
  INC H
  INC H
  INC H
  LD (HL),$01
  LD H,C
  JR l_C4EF

; HL = the character map place of object IX
;
; Witness: L1 1891 (door, rzx- x7).
ObjectCell:
  LD A,(IX+$04)
  ADD A,$04
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$03)
  SUB $40
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,CharMap+$0041
  ADD HL,DE
  RET

; KindTurretShot
;
; Used by the routine at l_C335.
KindTurretShot:
  LD A,(IX+$21)           ; 5: damages Matt only while the slot before it holds
                          ; a turret (kind 4): the shot of a dead turret is
                          ; harmless, and so is a shot KindTurret put into
                          ; slot+2 (the slot before it is the first shot or its
                          ; $40); such a shot ends as 0, not $40
  AND A
  JR Z,l_C54E
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  INC (IX+$18)
  LD A,(IX+$03)
  SUB $02
  LD (IX+$03),A
  CP $40
  JR C,l_C551
  CALL TouchesMatt
  RET NZ
  LD A,(IX-$26)
  CP $04
  RET NZ
  LD (IX+$00),$40
  JP Damage
l_C54E:
  CALL AwardScore
l_C551:
  LD A,(IX-$26)
  CP $04
  JR NZ,l_C55D
  LD (IX+$00),$40
  RET
l_C55D:
  LD (IX+$00),$00
  RET

; KindWave
;
; Used by the routine at l_C338.
KindWave:
  LD A,(IX+$21)           ; 6, its heights WaveHeights $C5B5
  AND A
  JR Z,l_C5AC
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  INC (IX+$11)
  LD E,(IX+$11)
  LD A,E
  CP $11
  JR NZ,l_C57E
  LD (IX+$11),$FF
l_C57E:
  LD D,$00
  LD HL,WaveHeights
  ADD HL,DE
  LD A,(FloorRow)
  SUB (HL)
  LD (IX+$04),A
  LD DE,$0012
  ADD HL,DE
  LD A,(HL)
  LD (IX+$18),A
  AND A
  LD A,$06
  CALL Z,PlayEffect
  LD A,(IX+$03)
  SUB $02
  LD (IX+$03),A
  CP $40
  JR C,l_C5AF
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C5AC:
  CALL AwardScore
l_C5AF:
  LD HL,EnemyTemplates+$00C0
  JP Explode

; 18 heights and 18 animation steps of the wave
WaveHeights:
  DEFB $0D,$14,$1A,$1F,$24,$29,$2C,$2F
  DEFB $31,$32,$31,$2F,$2C,$29,$24,$1F
  DEFB $1A,$14,$00,$05,$05,$05,$05,$04
  DEFB $04,$04,$03,$03,$03,$02,$02,$02
  DEFB $01,$01,$01,$01

; KindWalker
;
; Used by the routine at l_C33B.
KindWalker:
  LD A,(IX+$21)           ; 7
  AND A
  JR Z,l_C60F
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  LD A,(IX+$18)
  ADD A,(IX+$12)
  LD (IX+$18),A
  JR Z,l_C5F5
  CP $03
  JR NZ,l_C5FD
l_C5F5:
  LD A,(IX+$12)
  NEG
  LD (IX+$12),A
l_C5FD:
  CALL TouchesMatt
  JR NZ,l_C61C
  CALL Damage
  INC (IX+$11)
  LD A,(IX+$11)
  CP $05
  JR NZ,l_C61C
l_C60F:
  LD (IX+$00),$00
  CALL AwardScore
  LD HL,EnemyTemplates+$00CC
  JP Explode
l_C61C:
  CALL MoveX
  CP $40
  JR C,l_C644
  CP $B4
  JR NC,l_C649
  DEC (IX+$1C)
  RET NZ
  LD A,(IX+$1B)
  NEG
  LD (IX+$1B),A
  CALL Random
  AND $0F
  BIT 7,(IX+$1B)
  JR Z,l_C640
  ADD A,$06
l_C640:
  LD (IX+$1C),A
  RET
l_C644:
  LD (IX+$00),$00
  RET
l_C649:
  LD (IX+$1B),$FE
  RET

; KindChaser
;
; Used by the routine at l_C33E.
KindChaser:
  LD A,(IX+$21)           ; 8: follows Matt for $0300 passes
  AND A
  JR Z,l_C6AC
  LD HL,(ChaserState+$0001)
  DEC HL
  LD (ChaserState+$0001),HL
  BIT 7,H
  JR NZ,l_C6AF
  EX DE,HL
  LD A,(RoomScreen)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  SBC HL,DE
  LD DE,$0040
  ADD HL,DE
  LD A,H
  AND A
  JR Z,l_C67E
  LD A,$FF
  LD (EffectStops+$0001),A
  LD L,$00
  JR l_C683
l_C67E:
  LD A,$0F
  CALL PlayEffect
l_C683:
  LD (IX+$03),L
  LD A,(PenetratorOn)
  AND A
  JR Z,l_C691
  LD A,$10
  LD (PenetratorCost),A
l_C691:
  LD A,(Objects+$0004)
  CP (IX+$04)
  JR Z,l_C6A2
  LD A,(IX+$04)
  JR NC,l_C6A1
  DEC A
  JR l_C6A2
l_C6A1:
  INC A
l_C6A2:
  LD (IX+$04),A
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C6AC:
  CALL AwardScore
l_C6AF:
  LD A,$FF
  LD (EffectStops+$0001),A
  JP ObjectGone

; RET: kind 9
;
; Known only from the code.
KindNine:
  RET

; ObjectShot
;
; Used by the routines at KindFaller, KindFlyer, KindTurretShot, KindWave,
; KindWalker, KindEleven, KindTwelve, KindThirteen, KindFifteen and
; KindEighteen.
ObjectShot:
  CALL AwardScore         ; hit by Matt's shot: score, explosion
  LD A,(IX+$00)
  LD (IX+$00),$0A
  LD (IX+$1B),$00
  CP $05
  JR Z,l_C6CF
  LD (IX+$11),$00
  RET
l_C6CF:
  LD (IX+$11),$40
  RET

; KindTen
;
; Used by the routine at l_C344.
KindTen:
  LD A,(IX+$04)           ; 10
  LD (IX+$1C),A
  SUB $08
  LD (IX+$04),A
  CALL MoveX
  LD A,(IX+$04)
  BIT 7,A
  RET Z
  CP $E0
  RET NC
  LD A,(IX+$11)
  LD (IX+$00),A
  RET

; Never run: kind 11
;
; Known only from the code.
KindEleven:
  LD A,(IX+$21)
  AND A
  JR Z,l_C71E
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  INC (IX+$18)
  LD A,(IX+$04)
  ADD A,$04
  LD (IX+$04),A
  ADD A,$30
  CP $A0
  JR NC,l_C721
  CALL TouchesMatt
  JR Z,l_C71B
  CALL HitsWall
  RET NC
  JR l_C721
l_C71B:
  CALL Damage
l_C71E:
  CALL AwardScore
l_C721:
  LD HL,EnemyTemplates+$00D8
  CALL Random
  RRCA
  JR C,l_C72D
  LD HL,EnemyTemplates+$00E4
l_C72D:
  CALL Explode
  DEC (IX+$03)
  DEC (IX+$03)
  LD (IX+$1C),$02
  LD A,$0B
  JP PlayEffect

; KindTwelve
;
; Used by the routine at l_C34A.
KindTwelve:
  LD A,(IX+$21)           ; 12, the riser
  AND A
  JR Z,l_C780
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  LD A,(IX+$18)
  ADD A,(IX+$11)
  LD (IX+$18),A
  CALL MoveX
  CP $30
  JR C,l_C783
  CP $C0
  JR NC,l_C783
  LD A,(IX+$04)
  ADD A,(IX+$1C)
  LD (IX+$04),A
  INC (IX+$1C)
  ADD A,$20
  CP $86
  JR NC,l_C783
  CALL TouchesMatt
  JR Z,l_C77D
  CALL HitsWall
  JR C,l_C783
  RET
l_C77D:
  CALL Damage
l_C780:
  CALL AwardScore
l_C783:
  LD HL,EnemyTemplates+$00C0
  JP Explode

; A RET no branch reaches
;
; Known only from the code.
KindThirteenRet:
  RET

; KindThirteen
;
; Used by the routine at l_C34D.
KindThirteen:
  LD A,(IX+$22)           ; 13, the guard
  AND A
  JR Z,l_C79B
  INC (IX+$11)
  LD A,(IX+$11)
  CP $0A
  JP Z,ObjectShot
l_C79B:
  LD A,(IX+$21)
  AND A
  JR Z,l_C7AB
  CALL GuardBob
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C7AB:
  CALL AwardScore
  LD A,(IX+$03)
  SUB $04
  LD (IX+$03),A
  LD A,(IX+$04)
  ADD A,$04
  LD (IX+$04),A
  LD HL,EnemyTemplates+$00D8
  CALL Explode
  LD (IX+$10),$08
  LD A,(IX+$23)
  CP $06
  RET Z
  LD A,(IX+$26)
  AND $3F
  RET NZ
  LD A,(IX+$03)
  ADD A,$0C
  LD (IX+$29),A
  LD A,(IX+$04)
  ADD A,$04
  LD (IX+$2A),A
  LD DE,$0026
  ADD IX,DE
  LD HL,EnemyTemplates+$00E4
  CALL Explode
  LD (IX+$10),$0C
  RET

; The guard's up and down
;
; Witness: L1 270 (rzx-00000, rzx-24000).
GuardBob:
  LD A,(IX+$1C)
  AND A
  JP M,l_C80B
  ADD A,(IX+$04)
  LD (IX+$04),A
  ADD A,$20
  CP $76
  RET C
  LD (IX+$1C),$FC
  RET
l_C80B:
  ADD A,(IX+$04)
  LD (IX+$04),A
  ADD A,$20
  CP $40
  RET NC
  LD (IX+$1C),$04
  RET

; KindFourteen
;
; Used by the routine at l_C350.
KindFourteen:
  LD A,(IX+$21)           ; 14, the boss (always slot 1): fires kind 15 into
                          ; slot 0 when Random AND $25 = 0 and slot 0 holds no
                          ; shot
  AND A
  JR Z,l_C856
  CALL Random
  AND $25
  JR NZ,l_C84F
  LD A,(IX-$26)
  AND $3F
  JR NZ,l_C84F
  PUSH IX
  LD IX,Enemies
  LD (IX+$00),$0F
  LD A,(IX+$29)
  LD (IX+$03),A
  LD A,(IX+$2A)
  ADD A,$08
  LD (IX+$04),A
  LD HL,EnemyTemplates+$0084
  CALL SetupObject
  POP IX
l_C84F:
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C856:
  LD (IX+$00),$00
  CALL AwardScore
  JP ObjectGone

; KindFifteen
;
; Used by the routine at l_C353.
KindFifteen:
  LD A,(IX+$21)           ; 15
  AND A
  JR Z,l_C889
  LD A,(IX+$22)
  AND A
  JP NZ,ObjectShot
  LD A,(IX+$03)
  SUB $06
  LD (IX+$03),A
  CP $34
  JR NC,l_C882
  LD (IX+$00),$40
  LD (IX+$03),$00
  RET
l_C882:
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C889:
  CALL AwardScore
  LD HL,EnemyTemplates+$00C0
  CALL Explode
  LD (IX+$1B),$FE
  LD (IX+$1C),$00
  RET

; Kind 16 (SpawnKind6's object)
;
; Run only in work/stage2/rec/kind6 (an EnemyKind POKE), frames 675-1891.
;
; Witness: L1 488 (kind6).
KindSixteen:
  LD A,(IX+$21)
  AND A
  JR Z,l_C8FA
  LD A,(IX+$03)
  SUB $02
  LD (IX+$03),A
  CP $DC
  LD A,$0A
  CALL Z,PlayEffect
  CALL Random
  AND $92
  JR NZ,l_C8F3
  LD H,(IX+$04)
  LD L,(IX+$03)
  LD A,L
  SUB $40
  JP M,l_C8F3
  PUSH IX
  LD IX,Enemies
  LD DE,$0026
  LD B,$06
l_C8CE:
  LD A,(IX+$00)
  AND $3F
  JR Z,l_C8DB
  ADD IX,DE
  DJNZ l_C8CE
  JR l_C8F1
l_C8DB:
  LD (IX+$00),$0B
  LD A,H
  ADD A,$08
  LD (IX+$04),A
  LD A,L
  ADD A,$04
  LD (IX+$03),A
  LD HL,EnemyTemplates+$0054
  CALL SetupObject
l_C8F1:
  POP IX
l_C8F3:
  CALL TouchesMatt
  RET NZ
  CALL Damage
l_C8FA:
  CALL AwardScore

; ObjectGone
;
; Used by the routines at KindChaser and KindFourteen.
ObjectGone:
  LD A,(IX+$03)           ; the object leaves
  LD (IX+$11),A
  LD A,(IX+$04)
  LD (IX+$12),A
  LD (IX+$00),$11
  LD (IX+$03),$00
  LD (IX+$05),$01
  LD (IX+$06),$01
  LD (IX+$19),$06
  LD (IX+$10),$19
  RET

; KindSeventeen
;
; Used by the routine at l_C359.
KindSeventeen:
  DEC (IX+$10)            ; 17: 25 passes of small explosions where the object
                          ; was (set up by ObjectGone)
  JR NZ,l_C92C
  LD (IX+$00),$00
  RET
l_C92C:
  CALL Random
  AND $0F
  SUB $02
  ADD A,(IX+$11)
  LD L,A
  CALL Random
  AND $0F
  SUB $04
  ADD A,(IX+$12)
  LD H,A
  LD IX,Enemies
  LD DE,$0026
  LD B,$06
l_C94B:
  LD A,(IX+$00)
  AND $3F
  JR Z,l_C957
  ADD IX,DE
  DJNZ l_C94B
  RET
l_C957:
  LD (IX+$03),L
  LD (IX+$04),H
  CALL Random
  AND $03
  BIT 1,A
  JR Z,l_C973
  LD HL,EnemyTemplates+$00C0
  BIT 0,A
  JR Z,l_C970
  LD HL,EnemyTemplates+$00CC
l_C970:
  JP Explode
l_C973:
  LD HL,EnemyTemplates+$00D8
  BIT 0,A
  JR Z,l_C97D
  LD HL,EnemyTemplates+$00E4
l_C97D:
  JP Explode

; Kinds 18 and 19 (SpawnKind10's group)
;
; Run only in work/stage2/rec/door3 (an EnemyKind POKE), frames 1478-1968.
;
; Kind 18 (the head) has no hits test, so shots never kill it; a LIFTER hit
; runs ObjectShot and sets +$1B = -1. Each pass it keeps its y in +$1C, bobs
; (+$12 grows for 8 passes and shrinks for 8, by bit 3 of +$11, and is added to
; y) and moves x - 1; a touch costs Damage and the head stays.
;
; Kind 19 at $C9B8 (the body) keeps its y in +$1C, takes the y the record
; before it had last pass (IX-$0A, that record's +$1C) and moves x - 1: the
; group follows the head as a chain, one pass behind each. A touch costs
; Damage. When its +$1B is non-zero (the tail) and x < $38, all six slots
; become the placeholder $80: the whole group leaves at once.
;
; Witness: L1 167 (door3).
KindEighteen:
  LD A,(IX+$22)
  AND A
  JR Z,l_C98E
  CALL ObjectShot
  LD (IX+$1B),$FF
  RET
l_C98E:
  LD A,(IX+$04)
  LD (IX+$1C),A
  INC (IX+$11)
  BIT 3,(IX+$11)
  JR Z,l_C9A2
  INC (IX+$12)
  JR l_C9A5
l_C9A2:
  DEC (IX+$12)
l_C9A5:
  LD A,(IX+$04)
  ADD A,(IX+$12)
  LD (IX+$04),A
  DEC (IX+$03)
  CALL TouchesMatt
  JP Z,Damage
  RET

; l_C9B8
;
; Used by the routine at l_C35F.
l_C9B8:
  LD A,(IX+$04)
  LD (IX+$1C),A
  LD A,(IX-$0A)
  LD (IX+$04),A
  DEC (IX+$03)
  CALL TouchesMatt
  CALL Z,Damage
  LD A,(IX+$1B)
  AND A
  RET Z
  LD A,(IX+$03)
  CP $38
  RET NC
  LD IX,Enemies
  LD DE,$0026
  LD B,$06
l_C9E1:
  LD (IX+$00),$80
  ADD IX,DE
  DJNZ l_C9E1
  RET
