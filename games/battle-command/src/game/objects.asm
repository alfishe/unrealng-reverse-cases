; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The object table: 24 records of 60 bytes, spawning from the mission list, transform, depth sort, collisions, radar
;
; ObjectTable $75F0 (bank 5): 24 records of 60 bytes; record 0 is the player, 1-20 the general slots, 21 ($7ADC) the
; Helicarrier, 22 projectiles (FindProjectileSlot scans 1-22; 23 is never allocated). +1 type, +2 state flags (bit7
; present, bit6 wreck, bit2 on the radar), +3 handler flags (bit0 step handler on), +5/+6 height, +7 speed, +$13 hit
; points, +$14 damage, +$16/+$17 radius, +$18/+$19 step handler, +$1A/+$1B collision handler, +$1C/+$1D model,
; +$1E/+$1F score, +$22 heading, +$23-+$25 X, +$26-+$28 Y, +$31-+$3A per-type state, +$3B collision slot. +1 is the
; type, the 30 bytes +2..+$1F come from the type's template, +$20 is the serial.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A9FE

; Plot one radar pixel through the row table $6600
;
; Input: the blip's x and y on the radar. Looks up the screen row in the table
; `$6600`, ORs the pixel mask (E = `$49` + x AND 7 gives the bit) into the
; screen at the radar window `$5036`. Called by DrawRadar `$C05E` for each blip
; in the list `$6768`.
;
; Witness: L1 14562 (death, m2erbe, missions, play, play2).
PlotRadarPixel:
  LD A,L
  AND $07
  ADD A,$49
  LD E,A
  SRL L
  SRL L
  SRL L
  LD C,L
  LD B,$00
  LD A,H
  ADD A,A
  LD L,A
  LD H,$66
  LD D,(HL)
  INC L
  LD H,(HL)
  LD L,D
  ADD HL,BC
  LD D,$7C
  LD A,$01
  AND A
  JR NZ,l_AA23
  LD A,(DE)
  XOR A
  AND (HL)
  LD (HL),A
  RET
l_AA23:
  LD A,(DE)
  OR (HL)
  LD (HL),A
  RET

  ORG $B3C9

; The resident templates of the projectile types $80-$8C: 13 records of 30
; bytes from $B3CA
;
; ObjectSetType `$BD41` copies record (type - `$80`) when the type has bit 7:
; the 30 bytes become +2..+$1F of the object (the type itself is +1) (flags,
; colour, height, speed, box, hit points, damage, radius, step handler,
; collision handler, model, score). `$80` K-40 mortar shell (step `$B5E8`),
; `$81` cannon shell (`$B592`), `$82` Banshee RR, `$83` Phoenix RR, `$84`
; Banshee IR, `$85` Phoenix IR, `$86` Dragonfly, `$87` K-90 cluster bomb
; (`$CF4A`), `$88` Sleeper mine, `$89` Skeet bomb, `$8A` Phantasm (the decoy of
; the homing shell type 28), `$8B` Spectre, `$8C` the Helicarrier. The byte at
; `$B3C9` (`$C9`) is the RET of the routine before.
WeaponTemplates:
  DEFB $C9
ShellTemplate80:
  DEFB $85,$57,$07,$28,$00,$60,$C9,$B3,$08,$20,$00,$20,$00,$20,$00,$00,$7F,$00,$01,$20,$0A,$00,$E8,$B5,$AB,$B8,$80,$FE,$07,$00 ; template
  DEFB $85,$57,$07,$38,$00,$60,$C9,$B3,$08,$20,$00,$20,$00,$20,$00,$00,$7F,$00,$01,$20,$0A,$00,$92,$B5,$AB,$B8,$80,$FE,$07,$00 ; $80, the
  DEFB $85,$57,$07,$30,$00,$78,$C9,$B3,$08,$10,$00,$10,$00,$10,$00,$00,$7F,$00,$02,$20,$0A,$00,$53,$C4,$A8,$B8,$75,$87,$07,$00 ; K-40
  DEFB $85,$57,$07,$38,$00,$78,$C9,$B3,$08,$10,$00,$10,$00,$10,$00,$00,$7F,$00,$02,$20,$0A,$00,$A5,$C4,$A8,$B8,$75,$87,$07,$00 ; mortar
  DEFB $85,$57,$07,$38,$00,$78,$C9,$B3,$08,$10,$00,$10,$00,$10,$00,$00,$7F,$00,$02,$20,$0A,$00,$A5,$C4,$A8,$B8,$75,$87,$07,$00 ; shell; 30
  DEFB $85,$57,$07,$38,$00,$78,$C9,$B3,$08,$10,$00,$10,$00,$10,$00,$00,$7F,$00,$02,$20,$0A,$00,$53,$C4,$A8,$B8,$75,$87,$07,$00 ; bytes a
  DEFB $85,$57,$07,$40,$00,$78,$C9,$B3,$08,$10,$00,$10,$00,$10,$00,$00,$7F,$00,$02,$20,$0A,$00,$91,$C3,$65,$C3,$75,$87,$07,$00 ; type up to
  DEFB $85,$57,$07,$38,$00,$60,$C9,$B3,$08,$20,$00,$20,$00,$20,$00,$00,$7F,$00,$7F,$20,$0A,$00,$4A,$CF,$AB,$B8,$80,$FE,$07,$00 ; $8C
  DEFB $85,$57,$07,$38,$00,$7F,$C9,$B3,$08,$20,$00,$20,$00,$20,$00,$00,$7F,$00,$1F,$20,$0A,$00,$48,$D0,$E9,$D0,$39,$87,$07,$00
  DEFB $85,$57,$07,$40,$00,$40,$C9,$B3,$08,$20,$00,$40,$00,$20,$00,$00,$7F,$00,$04,$20,$0A,$00,$AE,$D2,$AB,$B8,$CA,$7E,$07,$00
  DEFB $85,$57,$07,$38,$00,$60,$C9,$B3,$08,$20,$00,$20,$00,$20,$00,$00,$7F,$00,$01,$20,$0A,$00,$05,$D4,$B0,$6B,$80,$FE,$07,$00
  DEFB $85,$57,$07,$38,$00,$60,$C9,$B3,$08,$40,$00,$40,$00,$40,$00,$00,$7F,$00,$1F,$20,$0A,$00,$69,$D3,$AB,$B8,$80,$FE,$07,$00
  DEFB $85,$07,$07,$68,$00,$64,$C9,$B3,$08,$00,$01,$80,$00,$00,$01,$00,$7F,$00,$01,$20,$0A,$00,$00,$DB,$AB,$DA,$A5,$D9,$07,$00

  ORG $B766

; Bearing from IX to IY, a byte angle (vector $67C1)
;
; dx, dy of the two records, then the octant and the ratio (BearingOctant
; `$B916`, BearingRatio `$B94A`, the table `$B9DE`). Output A = 0-255.
;
; Witness: L1 7491 (death, m2erbe, missions, play, play2).
BearingTo:
  LD L,(IY+$26)
  LD H,(IY+$27)
  LD A,(IY+$28)
  LD E,(IX+$26)
  LD D,(IX+$27)
  LD C,(IX+$28)
  AND A
  SBC HL,DE
  SBC A,C
  SRA A
  RR H
  RR L
  SRA A
  RR H
  RR L
  EX DE,HL
  LD L,(IY+$23)
  LD H,(IY+$24)
  LD C,(IX+$23)
  LD B,(IX+$24)
  AND A
  SBC HL,BC
  LD A,(IY+$25)
  LD C,(IX+$25)
  SBC A,C
  SRA A
  RR H
  RR L
  SRA A
  RR H
  RR L
  JP BearingOctant

; Invert the screen rows of the table $6500 (a panel flash)
;
; HL = `$6500`, then InvertPanelRows `$B7BD`. Seen in m2erbe, missions and play
; (12 runs).
;
; Witness: L1 12 (m2erbe, missions, play).
InvertPanelA:
  EX AF,AF'
  XOR A
  LD (l_B7C3+$0009),A
  EX AF,AF'
  JR InvertPanelRows

; Invert the rows of the table $6550
;
; HL = `$6550` (or the caller's HL), then InvertPanelRows. RefreshWeaponPanel
; `$C632` calls it with `$6500`.
;
; Witness: L1 26 (death, play, play2).
InvertPanelB:
  EX AF,AF'
  LD A,$08
  LD (l_B7C3+$0009),A
  EX AF,AF'

; Invert N screen rows from a table of addresses
;
; Each table entry is a screen address; the row's bytes are complemented (a
; flash of the panel when a weapon is selected or hit).
;
; Witness: L1 38 (death, m2erbe, missions, play, play2).
InvertPanelRows:
  LD C,A
  LD B,$00
  EXX
  LD B,$18
l_B7C3:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  JR l_B7CD
l_B7CD:
  LD A,(DE)
  CPL
  LD (DE),A
  INC DE
  LD A,(DE)
  CPL
  LD (DE),A
  INC DE
  LD A,(DE)
  CPL
  LD (DE),A
  INC DE
  LD A,(DE)
  CPL
  LD (DE),A
  INC DE
  LD A,(DE)
  CPL
  LD (DE),A
  INC DE
  EXX
  DJNZ l_B7C3
  RET

; 3D script opcode 22: draw the carried object when the flag $B7EB is set
;
; Called from the script interpreter `$990F` (opcode 22, `$98E1` table). Pops
; the return address into the `JP nn` at `$B824` (operand `$B825`); the operand
; of `LD A,n` at `$B7EB` is the flag. When it is set: saves `$9A8E` / `$9AB3` /
; `$9A6C`, pages bank 3 (`$726C`), DrawModel `$B82A` with the record from
; `$68E6`, restores the view values. In every recording the flag is 0 and only
; the `JP` back runs.
;
; Witness: L1 4 (play2).
ScriptDrawCarried:
  POP DE
  LD (ScriptDrawCarriedReturn+$0001),DE
  LD A,$00
  AND A
  JR Z,ScriptDrawCarriedReturn
  LD HL,(l_9A85+$0009)
  LD DE,(l_9A9E+$0015)
  LD BC,(l_9A5E+$000E)
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,(MissionScore+$0004)
  PUSH HL
  PUSH IX
  CALL PageBank3
  LD IX,$0000
  CALL DrawModel
  CALL PageBank0
  POP IX
  POP HL
  LD (MissionScore+$0004),HL
  POP BC
  POP DE
  POP HL
  LD (l_9A85+$0009),HL
  LD (l_9A9E+$0015),DE
  LD (l_9A5E+$000E),BC
ScriptDrawCarriedReturn:
  JP ScriptDrawCarriedReturn ; JP nn: the script's return address

; Draw one object: its model, or the wreck model
;
; Input IX = the record. +2 bit 6 picks the wreck model +8/+9 instead of
; +$1C/+$1D; falls into DrawModel `$B82A`.
;
; Witness: L1 9194 (death, m2erbe, missions, play, play2).
DrawObject:
  PUSH DE
  POP IX

; Project and draw a 3D model at the object's view-space position
;
; Loads the view x / depth (+$2B..+$2E) into `$9A8E` / `$9AB3`, the night-sight
; mode `$757A`, and calls the 3D engine (bank 2 `$990F`).
;
; Witness: L1 9194 (death, m2erbe, missions, play, play2).
DrawModel:
  LD A,(AwolState+$0002)
  PUSH AF
  LD C,(IX+$2B)
  LD B,(IX+$2C)
  LD (l_9A85+$0009),BC
  LD C,(IX+$2D)
  LD B,(IX+$2E)
  LD (l_9A9E+$0015),BC
  LD A,(WorldVars+$0003)
  LD C,A
  LD A,(IX+$22)
  SUB C
  LD (MissionScore+$0005),A
  LD A,(IX+$2A)
  LD (BoxTiltPitch+$0001),A
  LD C,(IX+$2F)
  LD B,(IX+$30)
  LD (l_9A5E+$000E),BC
  LD A,(IX+$03)
  AND $02
  JR Z,l_B86F
  LD HL,$0800
  SBC HL,BC
  JR NC,l_B86F
  XOR A
  LD (AwolState+$0002),A
l_B86F:
  LD A,(IX+$04)
  LD (OpPolarPoints+$0013),A
  PUSH IX
  PUSH IY
  LD A,(IX+$02)
  AND $40
  JR Z,l_B88F
  LD E,(IX+$08)
  LD D,(IX+$09)
  LD BC,$0000
  LD (l_9A9E+$0015),BC
  JR l_B895
l_B88F:
  LD E,(IX+$1C)
  LD D,(IX+$1D)
l_B895:
  PUSH IX
  POP IY
  PUSH DE
  POP IX
  CALL RunScript
  POP IY
  POP IX
  POP AF
  LD (AwolState+$0002),A
  RET

; A CALL $C506 no recording runs
;
; `CALL $C506` (ResetSightTimer) at the end of the routine before; no recording
; takes that path.
DrawModelTail:
  DEFB $CD,$06,$C5

  ORG $B8B1

; Free a record: unregister its collision, clear +2
;
; Input IX. UnregisterCollision `$CA3B`, +2 = 0 (the slot is free for
; FindFreeObject).
;
; Witness: L1 61 (death, play, play2).
RemoveObject:
  CALL ApiVector05
  LD (IX+$02),$00
  RET

  ORG $B916

; BearingTo: the octant from the signs of dx, dy
;
; dx, dy signs give 8 octants; then BearingRatio.
;
; Witness: L1 7491 (death, m2erbe, missions, play, play2).
BearingOctant:
  BIT 7,H
  JR NZ,l_B92F
  BIT 7,D
  JR NZ,l_B926
  CALL BearingRatio
  NEG
  ADD A,$40
  RET
l_B926:
  CALL NegDE
  CALL BearingRatio
  ADD A,$40
  RET
l_B92F:
  BIT 7,D
  JR NZ,l_B93C
  CALL ApiVector07
  CALL BearingRatio
  SUB $40
  RET
l_B93C:
  CALL ApiVector07
  CALL NegDE
  CALL BearingRatio
  NEG
  SUB $40
  RET

; BearingTo: the ratio of the smaller to the larger delta
;
; Divides the smaller |delta| by the larger to an index of BearingTable.
;
; Witness: L1 7491 (death, m2erbe, missions, play, play2).
BearingRatio:
  PUSH HL
  AND A
  SBC HL,DE
  POP HL
  JR NC,BearingLookup
  EX DE,HL
  CALL BearingLookup
  LD B,A
  LD A,$40
  SUB B
  RET

; BearingTo: the angle from the table $B9DE
;
; Adds the octant base to the table angle.
;
; Witness: L1 7491 (death, m2erbe, missions, play, play2).
BearingLookup:
  CALL Divide
  JR C,l_B967
  EX DE,HL
  LD A,D
  AND A
  JR NZ,l_B969
  LD A,$20
  RET
l_B967:
  XOR A
  RET
l_B969:
  CP $01
  JR NZ,l_B975
  LD BC,$0D13
  LD HL,BearingTable+$000B
  JR l_B9D4
l_B975:
  CP $02
  JR NZ,l_B981
  LD BC,$060D
  LD HL,BearingTable+$0005
  JR l_B9D4
l_B981:
  CP $03
  JR NZ,l_B98D
  LD BC,$030A
  LD HL,BearingTable+$0002
  JR l_B9D4
l_B98D:
  CP $04
  JR NZ,l_B999
  LD BC,$0208
  LD HL,BearingTable
  JR l_B9D4
l_B999:
  CP $05
  JR NZ,l_B9A5
  LD A,E
  CP $5E
  LD A,$07
  RET NC
  INC A
  RET
l_B9A5:
  CP $06
  JR NZ,l_B9B1
  LD A,E
  CP $37
  LD A,$06
  RET NC
  INC A
  RET
l_B9B1:
  CP $09
  JR NC,l_B9B8
  LD A,$05
  RET
l_B9B8:
  CP $0C
  JR NC,l_B9BF
  LD A,$04
  RET
l_B9BF:
  CP $10
  JR NC,l_B9C6
  LD A,$03
  RET
l_B9C6:
  CP $1B
  JR NC,l_B9CD
  LD A,$02
  RET
l_B9CD:
  CP $51
  LD A,$00
  RET NC
  INC A
  RET
l_B9D4:
  LD A,E
l_B9D5:
  CP (HL)
  JR NC,l_B9DC
  INC C
  INC HL
  DJNZ l_B9D5
l_B9DC:
  LD A,C
  RET

; The arctangent table of BearingTo
;
; 24 bytes of angles read by BearingLookup `$B95A`.
BearingTable:
  DEFB $B9,$35,$CB,$72,$28,$E8,$B0,$80
  DEFB $55,$2E,$0C,$ED,$D1,$B7,$9F,$89
  DEFB $75,$62,$50,$3F,$30,$21,$F0,$75

  ORG $BBF0

; Saved operand of ActivateMissionObjects
;
; The byte before ActivateMissionObjects; its index operands are `$BBF2` /
; `$BBFA`.
ActivateIndexSave:
  DEFB $00

; Spawn the mission objects near the player, despawn the far ones (16 per call)
;
; Walks the ($DBD9) records of 8 bytes at ($DBDA), 16 per call (the index is
; kept in `$BBF2` / `$BBFA`). A live record (bit 7) not yet spawned within 9
; coarse units (InRange `$BD67`) gets a slot (FindSlot `$BCFD`), its type
; (ObjectSetType `$BD41`), a collision slot (`$C957`), its heading and position
; (CopyHeading `$BCBA`, CopyPosition `$BCC6`), and bit 6. A spawned one out of
; range is freed (bit 6 cleared; the slot found by +0 = the index in `$BC33`).
;
; Witness: L1 3550 (death, m2erbe, missions, play, play2).
ActivateMissionObjects:
  LD HL,SetHeightAndMove
  LD DE,$0008
  LD B,$10
  LD C,$00
l_BBFB:
  PUSH HL
  EXX
  POP HL
  LD A,(HL)
  LD (ActivateIndexSave),A
  AND A
  LD B,A
  JP P,l_BC60
  PUSH HL
  INC HL
  LD A,(HL)
  EX AF,AF'
  INC HL
  INC HL
  INC HL
  LD D,H
  LD E,L
  INC HL
  LD A,$E4
  LD C,(HL)
  CALL InRange
  JP C,l_BC86
  INC HL
  INC HL
  LD A,$3E
  LD C,(HL)
  CALL InRange
  JP C,l_BC86
  LD A,B
  SLA A
  JP M,l_BC82
  INC HL
  CALL FindSlot
  JP NC,l_BC82
  LD A,$00
  LD (HL),A
  INC HL
  EX AF,AF'
  EX DE,HL
  CALL ApiVector03
  LD A,(ActivateIndexSave)
  AND $02
  JR NZ,l_BC48
  CALL ApiVector04
  LD A,(ActivateIndexSave)
l_BC48:
  RRCA
  RRCA
  RRCA
  AND $40
  LD C,A
  LD HL,(l_C96D+$0006)
  LD A,(HL)
  AND $BF
  OR C
  LD (HL),A
  POP HL
  LD A,(HL)
  OR $40
  LD (HL),A
  INC HL
  INC HL
  CALL CopyHeading
l_BC60:
  LD HL,l_BBFB+$0038
  INC (HL)
  EXX
  DEC C
  JR NZ,l_BC77
  LD HL,(MissionHeader+$0015)
  LD A,(MissionHeader+$0014)
  LD C,A
  XOR A
  LD (l_BBFB+$0038),A
  DJNZ l_BBFB
  JR l_BC7A
l_BC77:
  ADD HL,DE
  DJNZ l_BBFB
l_BC7A:
  LD A,C
  LD (ActivateMissionObjects+$0009),A
  LD (ActivateMissionObjects+$0001),HL
  RET
l_BC82:
  POP HL
  JP l_BC60
l_BC86:
  POP HL
  LD A,B
  SLA A
  JP P,l_BC60
  LD A,B
  AND $BF
  LD (HL),A
  LD HL,ObjectTable
  LD DE,$003C
  LD B,$17
  LD A,(l_BBFB+$0038)
  LD C,A
l_BC9D:
  LD A,(HL)
  CP C
  JR Z,l_BCA6
  ADD HL,DE
  DJNZ l_BC9D
  JR l_BC60
l_BCA6:
  PUSH HL
  POP IX
  EXX
  PUSH HL
  PUSH DE
  PUSH BC
  CALL ApiVector05
  POP BC
  POP DE
  POP HL
  EXX
  LD (IX+$02),$00
  JR l_BC60

; Copy the list record's heading (+2) to the object
;
; The list record's +2 to the object's +$22.
;
; Witness: L1 183 (death, m2erbe, missions, play, play2).
CopyHeading:
  XOR A
  LD (DE),A
  INC DE
  LD A,(HL)
  INC HL
  INC HL
  EX DE,HL
  LD (HL),A
  INC HL
  CALL CopyPosition

; Copy the list record's X / Y words, << 2 into 24 bits (WordToWorld $BD83)
;
; +4/+5 and +6/+7 of the list record through WordToWorld `$BD83` to +$23-+$25
; and +$26-+$28.
;
; Witness: L1 366 (death, m2erbe, missions, play, play2).
CopyPosition:
  EX DE,HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  CALL WordToWorld
  EX DE,HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  RET

; Find a free record for a projectile (up to record 23)
;
; D = `$17`, falls into FindFreeObject.
;
; Witness: L1 70 (death, play, play2).
FindProjectileSlot:
  LD D,$17
  JR FindFreeObjectD

; Find a free record 1-20 (vector $67C4)
;
; D = `$15`; carry set and IX = the record when found.
;
; Witness: L1 219 (death, m2erbe, missions, play, play2).
FindFreeObject:
  LD D,$15

; Find a free record below D: +2 = 0
;
; Stores 23 - E in `$C95C` and the record in `$C973`.
;
; Witness: L1 289 (death, m2erbe, missions, play, play2).
FindFreeObjectD:
  LD E,$01
  LD HL,PlayerY+$0018
  LD BC,$003C
l_BCE4:
  LD A,(HL)
  AND A
  JR Z,FindFreeLoop
  ADD HL,BC
  INC E
  LD A,E
  CP D
  JR NZ,l_BCE4
  AND A
  RET

; The scan loop
;
; Steps 60 bytes per record until +2 = 0 or the limit.
;
; Witness: L1 415 (death, m2erbe, missions, play, play2).
FindFreeLoop:
  LD A,$17
  SUB E
  LD (RegisterCollision+$0005),A
  LD (l_C96D+$0006),HL
  DEC HL
  DEC HL
  SCF
  RET

; Find a slot for a list record: the first free or evictable record of 1-20
;
; One scan of records 1-20 (it does not call FindFreeObject): the first record
; that is free (+2 = 0) or holds an enemy shell (+3 AND `$50` = `$10`) is
; taken; an evicted shell is unregistered (`$67CD`) and its +2 cleared. Then
; the list index to +0. NC when none.
;
; Witness: L1 185 (death, m2erbe, missions, play, play2).
FindSlot:
  LD D,$15
  LD E,$01
  LD HL,PlayerY+$0018
  LD BC,$003C
l_BD07:
  LD A,(HL)
  AND A
  JR Z,FindFreeLoop
  INC HL
  LD A,(HL)
  DEC HL
  AND $50
  CP $10
  JR Z,l_BD1C
  ADD HL,BC
  INC E
  LD A,E
  CP D
  JR NZ,l_BD07
  AND A
  RET
l_BD1C:
  LD A,$17
  SUB E
  LD (RegisterCollision+$0005),A
  LD (l_C96D+$0006),HL
  DEC HL
  DEC HL
  PUSH HL
  PUSH HL
  POP IX
  EX AF,AF'
  PUSH AF
  EXX
  PUSH HL
  PUSH DE
  PUSH BC
  CALL ApiVector05
  LD (IX+$02),$00
  POP BC
  POP DE
  POP HL
  EXX
  POP AF
  EX AF,AF'
  POP HL
  SCF
  RET

; Set the type and copy the 30-byte template (vector $67C7)
;
; Input A = type. Bit 7: the resident template `$B3CA` + 30 * (A - `$80`); else
; the mission's template table (`$DBD7`) + 30 * A. Stores the type at +1,
; copies the 30 template bytes to +2..+$1F and the serial to +$20.
;
; Witness: L1 431 (death, m2erbe, missions, play, play2).
ObjectSetType:
  LD (DE),A
  INC DE
  AND A
  JP P,l_BD4E
  SBC A,$80
  LD HL,ShellTemplate80
  JR l_BD51
l_BD4E:
  LD HL,(MissionHeader+$0012)
l_BD51:
  LD BC,$001E
  AND A
l_BD55:
  JP Z,l_BD5C
  ADD HL,BC
  DEC A
  JR l_BD55
l_BD5C:
  LDIR
  LD A,$00
  LD (DE),A
  INC A
  LD (l_BD5C+$0003),A
  INC DE
  RET

; Is the list record within range of the player (4 coarse units for type 0, 9
; for the others)
;
; |X word >> 8 - `$BC12`| and |Y - `$BC1D`| below the range: 4 for type 0
; (trees), 9 for every other type (type 1 trees included). Called for each list
; record (70 373 runs).
;
; Witness: L1 70373 (death, m2erbe, missions, play, play2).
InRange:
  AND A
  SBC A,C
  JP PO,l_BD6E
  CCF
  RRA
l_BD6E:
  LD C,A
  CALL ApiVector08
  EX AF,AF'
  CP $01
  JR C,l_BD7D
  EX AF,AF'
  CP $09
  LD A,C
  CCF
  RET
l_BD7D:
  EX AF,AF'
  CP $04
  LD A,C
  CCF
  RET

; A list word << 2 into a 24-bit coordinate
;
; HL << 2 with the carry into the third byte.
;
; Witness: L1 366 (death, m2erbe, missions, play, play2).
WordToWorld:
  LD A,B
  AND A
  LD A,$00
  JP P,l_BD8B
  DEC A
l_BD8B:
  SLA C
  RL B
  RL A
  SLA C
  RL B
  RL A
  RET

; Make every present object camera-relative, cull it, insert it into the depth
; tree
;
; For each record with +2 bit 7: position minus camera, RotateToView `$BBBC`,
; depth cull, OnScreen `$BEA2` with the radius, then DepthInsert `$BEDE` into
; the tree at `$6800`; a blip for the radar (RadarAddBlip `$C0B2`).
;
; Witness: L1 3550 (death, m2erbe, missions, play, play2).
TransformObjects:
  XOR A
  LD (ScriptDrawCarried+$0006),A
  LD HL,FaceFlags+$0040
  LD (FailReason+$0002),HL
  LD IX,PlayerY+$0016
  LD A,$17
  AND A
  RET Z
  LD (PolyWorkSpare+$0004),A
  XOR A
  LD (PolyWorkSpare),A
  CALL ClearDepthTree
l_BDB4:
  LD A,(IX+$02)
  LD C,A
  AND $DF
  LD (IX+$02),A
  LD A,C
  AND A
  JP P,l_BE83
  SRL A
  JP NC,l_BE83
  LD L,(IX+$23)
  LD H,(IX+$24)
  LD BC,(WorldVars+$0004)
  AND A
  SBC HL,BC
  LD (l_9A85+$0009),HL
  LD A,(WorldVars+$0006)
  LD E,A
  LD A,(IX+$25)
  SBC A,E
  LD D,H
  SLA D
  ADC A,$00
  JP NZ,l_BE83
  LD A,H
  AND A
  JP M,l_BDF4
  LD A,$1F
  CP H
  JR NC,l_BDFA
  JP l_BE83
l_BDF4:
  LD A,$DF
  CP H
  JP NC,l_BE83
l_BDFA:
  LD L,(IX+$26)
  LD H,(IX+$27)
  LD BC,(WorldVars+$0007)
  AND A
  SBC HL,BC
  LD (l_9A5E+$000E),HL
  LD A,(WorldVars+$0009)
  LD E,A
  LD A,(IX+$28)
  SBC A,E
  LD D,H
  SLA D
  ADC A,$00
  JR NZ,l_BE83
  LD A,H
  AND A
  JP M,l_BE26
  LD A,(l_BDB4+$0039)
  CP H
  JR NC,l_BE2C
  JR l_BE83
l_BE26:
  LD A,(l_BDF4+$0001)
  CP H
  JR NC,l_BE83
l_BE2C:
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD BC,(WorldVars+$000A)
  AND A
  SBC HL,BC
  LD (IX+$2D),L
  LD (IX+$2E),H
  CALL RotateToView
  LD (PolyWorkSpare+$0001),HL
  LD (IX+$2F),L
  LD (IX+$30),H
  EXX
  LD (IX+$2B),L
  LD (IX+$2C),H
  EXX
  LD A,(IX+$02)
  AND $04
  JR Z,l_BE5D
  CALL RadarAddBlip
l_BE5D:
  CALL OnScreen
  JR C,l_BE83
  LD HL,(PolyWorkSpare+$0001)
  LD A,(IX+$02)
  BIT 4,A
  JP NZ,l_BE94
  BIT 3,A
  JR NZ,l_BE75
  BIT 6,A
  JR Z,l_BE78
l_BE75:
  LD HL,MissionParams+$017D
l_BE78:
  LD A,(IX+$02)
  OR $20
  LD (IX+$02),A
  CALL DepthInsert
l_BE83:
  LD A,(PolyWorkSpare+$0004)
  DEC A
  RET Z
  LD (PolyWorkSpare+$0004),A
  LD C,$3C
  LD B,$00
  ADD IX,BC
  JP l_BDB4
l_BE94:
  PUSH IX
  POP BC
  LD (ScriptDrawCarried+$0023),BC
  LD A,$FF
  LD (ScriptDrawCarried+$0006),A
  JR l_BE83

; Is the object within the screen with its radius
;
; View x (+$2B/+$2C) against the depth with the radius +$16/+$17.
;
; Witness: L1 32872 (death, m2erbe, missions, play, play2).
OnScreen:
  LD B,H
  LD C,L
  SRA B
  RR C

; The x half of OnScreen
;
; The entry for the x test.
;
; Witness: L1 32885 (death, m2erbe, missions, play, play2).
OnScreenX:
  LD L,(IX+$16)
  LD H,(IX+$17)
  ADD HL,BC
  LD A,(IX+$2C)
  AND A
  JP P,l_BEC4
  LD E,(IX+$2B)
  LD D,(IX+$2C)
  AND A
  ADC HL,DE
  JP P,l_BED0
l_BEC2:
  SCF
  RET
l_BEC4:
  LD E,(IX+$2B)
  LD D,(IX+$2C)
  AND A
  SBC HL,DE
  JP M,l_BEC2
l_BED0:
  AND A
  RET

; Empty the depth tree at $6800
;
; Resets the node pointer and the root at `$6800`.
;
; Witness: L1 3550 (death, m2erbe, missions, play, play2).
ClearDepthTree:
  LD HL,PlayWork
  LD (DepthTreeVars+$0002),HL
  XOR A
  LD (HL),A
  LD (PolyWorkSpare+$0005),A
  RET

; Insert a record into the depth tree (6-byte nodes: depth, left, right,
; record)
;
; Walks from the root, left when nearer, right when farther, and links a new
; 6-byte node.
;
; Witness: L1 9829 (death, m2erbe, missions, play, play2).
DepthInsert:
  LD A,(PolyWorkSpare+$0005)
  EX AF,AF'
  LD C,L
  LD B,H
  LD HL,(DepthTreeVars+$0002)
  LD (DepthTreeVars),HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  XOR A
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  PUSH IX
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  LD (DepthTreeVars+$0002),HL
  EX AF,AF'
  INC A
  LD (PolyWorkSpare+$0005),A
  DEC A
  RET Z
  LD HL,PlayWork
l_BF07:
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  JR NC,l_BF13
  INC L
l_BF13:
  LD A,(HL)
  AND A
  JR Z,l_BF1B
  LD L,A
  JP l_BF07
l_BF1B:
  LD A,(DepthTreeVars)
  LD (HL),A
  RET

; Variables of the depth tree
;
; Zero in the image; the walk of the tree keeps its stack depth here.
DepthTreeVars:
  DEFB $00,$00,$00,$00

  ORG $BF53

; Draw the objects far to near (in-order walk of the depth tree)
;
; Calls DrawEntry `$BF83` per node.
;
; Witness: L1 3507 (death, m2erbe, missions, play, play2).
DrawObjectsInOrder:
  LD A,(PolyWorkSpare+$0005)
  AND A
  RET Z
  LD HL,$0000
  PUSH HL
  LD HL,PlayWork
l_BF5F:
  INC L
  INC L
  INC L
  LD A,(HL)
  AND A
  JP Z,l_BF6C
  PUSH HL
  LD L,A
  JP l_BF5F
l_BF6C:
  PUSH HL
  INC L
  CALL DrawEntry
  POP HL
  DEC L
  LD A,(HL)
  AND A
  JP Z,l_BF7C
  LD L,A
  JP l_BF5F
l_BF7C:
  POP HL
  INC H
  DEC H
  RET Z
  JP l_BF6C

; Draw one tree entry: an object (DrawObject) or a debris particle
;
; A pointer at or above `$CF00` is a particle of the bank 3 list, drawn as a
; dot.
;
; Witness: L1 9715 (death, m2erbe, missions, play, play2).
DrawEntry:
  LD E,(HL)
  INC HL
  LD A,(HL)
  LD D,A
  CP $CF
  JP C,DrawObject
  INC HL
  CALL SaveBank
  CALL PageBank3
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD (l_9A5E+$000E),BC
  PUSH DE
  POP IX
  LD E,(IX+$0B)
  LD D,(IX+$0C)
  LD (l_9A85+$0009),DE
  LD E,(IX+$0D)
  LD D,(IX+$0E)
  LD (l_9A9E+$0015),DE
  LD A,(WorldVars+$0003)
  LD C,A
  LD A,(IX+$09)
  SUB C
  LD (MissionScore+$0005),A
  LD A,(IX+$0A)
  LD (BoxTiltPitch+$0001),A
  CALL RestoreBank
  PUSH IX
  POP IY
  LD IX,data_FEBB+$0009
  CALL RunScript
  RET

; Move an object by its speed along its heading (vector $67BE)
;
; X += speed * sin(heading), Y += speed * cos(heading), through `$A8B2` /
; `$A7F2`.
;
; Witness: L1 14450 (death, m2erbe, missions, play, play2).
MoveObject:
  LD L,(IX+$21)
  LD H,(IX+$22)
  CALL SinCosHalf
  LD (RotateToView+$000C),A
  LD A,(IX+$07)
  CALL MulFrac
  LD E,$00
  LD A,H
  AND A
  JP P,l_BFEB
  DEC E
l_BFEB:
  LD C,(IX+$23)
  LD B,(IX+$24)
  ADD HL,BC
  LD A,(IX+$25)
  ADC A,E
  LD (IX+$23),L
  LD (IX+$24),H
  LD (IX+$25),A
  LD A,(RotateToView+$000C)
  LD E,A
  LD A,(IX+$07)
  CALL MulFrac
  LD E,$00
  LD A,H
  AND A
  JP P,l_C011
  DEC E
l_C011:
  LD C,(IX+$26)
  LD B,(IX+$27)
  ADD HL,BC
  LD A,(IX+$28)
  ADC A,E
  LD (IX+$26),L
  LD (IX+$27),H
  LD (IX+$28),A
  RET

; Run each present object's step handler
;
; 24 records from `$75F0`: when +2 bit 7 and +3 bit 0 are set, CALL (+$18) with
; IX = the record.
;
; Witness: L1 3550 (death, m2erbe, missions, play, play2).
RunObjectHandlers:
  LD IX,ObjectTable
  LD A,$17
  INC A
  LD (l_C04F+$0001),A
l_C030:
  LD A,(IX+$02)
  AND A
  JP P,l_C04F
  LD A,(IX+$03)
  AND $01
  JR Z,l_C04F
  LD E,(IX+$18)
  LD D,(IX+$19)
  PUSH IX
  LD (l_C030+$001B),DE
  CALL $0000
  POP IX
l_C04F:
  LD A,$00
  DEC A
  RET Z
  LD (l_C04F+$0001),A
  LD BC,$003C
  ADD IX,BC
  JP l_C030

; Draw the radar: clear it, plot the blip list $6768
;
; ClearRadar `$C094`, then RadarPlotList `$C079` (3483 runs, every 3D frame but
; the first).
;
; Witness: L1 3483 (death, m2erbe, missions, play, play2).
DrawRadar:
  NOP
  CALL ClearRadar
  LD A,(GaugeRecords+$0018)
  AND A
  JR NZ,l_C071
  LD A,$C9
  LD (BlinkWarning),A
  LD (DrawRadar),A
  RET
l_C071:
  CP $10
  JR NC,RadarPlotList
  CALL ApiVector06
  RET P

; Plot the list of blips and reset it
;
; Resets the list pointer `$7BFB`, sets `$AA1A`, plots each pair at `$6768`
; through PlotRadarPixel `$A9FE`.
;
; Witness: L1 3483 (death, m2erbe, missions, play, play2).
RadarPlotList:
  LD HL,(FailReason+$0002)
  XOR A
  LD (HL),A
  INC A
  LD (PlotRadarPixel+$001C),A
  LD HL,FaceFlags+$0040
l_C085:
  LD A,(HL)
  AND A
  RET Z
  LD D,A
  INC HL
  LD E,(HL)
  INC HL
  PUSH HL
  EX DE,HL
  CALL PlotRadarPixel
  POP HL
  JR l_C085

; Clear 32 rows of 5 bytes at $5036 with stack pushes
;
; SP = the radar's screen rows, PUSH of zeros (32 rows, 5 bytes each at
; `$5036`).
;
; Witness: L1 3483 (death, m2erbe, missions, play, play2).
ClearRadar:
  DI
  LD (l_C0A5+$0009),SP
  LD SP,ScreenRowTable+$0108
  LD DE,$0016
  LD A,$20
l_C0A1:
  POP HL
  ADD HL,DE
  LD B,$05
l_C0A5:
  LD (HL),$00
  INC HL
  DJNZ l_C0A5
  DEC A
  JR NZ,l_C0A1
  LD SP,$0000
  EI
  RET

; Add an object to the radar list when within range
;
; Input: the object's offset from the player. RadarRange `$C104`, RadarScale
; `$C0D2`, RadarStoreBlip `$C0F7`.
;
; Witness: L1 27405 (death, m2erbe, missions, play, play2).
RadarAddBlip:
  PUSH HL
  EXX
  POP DE
  PUSH HL
  LD A,(l_BA1F+$0008)
  AND A
  JR Z,l_C0C4
  CALL ApiVector07
  EX DE,HL
  CALL ApiVector07
  EX DE,HL
l_C0C4:
  LD B,$08
l_C0C6:
  SRA H
  RR L
  DJNZ l_C0C6
  LD BC,$0014
  ADD HL,BC
  LD C,$28

; Scale the offsets to radar units
;
; SRA H / RR L 8 times on each offset.
;
; Witness: L1 27405 (death, m2erbe, missions, play, play2).
RadarScale:
  CALL RadarRange
  JR C,l_C101
  EX DE,HL
  LD B,$08
l_C0DA:
  SRA H
  RR L
  DJNZ l_C0DA
  LD B,H
  LD C,L
  LD HL,$0014
  AND A
  SBC HL,BC
  LD C,$20
  CALL RadarRange
  JR C,l_C101
  LD A,L
  ADD A,$04
  LD D,A
  LD A,E
  ADD A,$B0
  LD E,A

; Store the blip in the list at ($7BFB)
;
; Writes y, x to (`$7BFB`) and advances it.
;
; Witness: L1 14952 (death, m2erbe, missions, play, play2).
RadarStoreBlip:
  LD HL,(FailReason+$0002)
  LD (HL),D
  INC HL
  LD (HL),E
  INC HL
  LD (FailReason+$0002),HL
; This entry point is used by the routine at RadarScale.
l_C101:
  POP HL
  EXX
  RET

; Is the offset within the radar's range
;
; Carry set when the offset is out of the radar (|d| beyond the window).
;
; Witness: L1 48723 (death, m2erbe, missions, play, play2).
RadarRange:
  LD A,H
  AND A
  JP M,l_C10F
  JR NZ,l_C10F
  LD A,L
  CP C
  JR C,l_C111
l_C10F:
  SCF
  RET
l_C111:
  AND A
  RET

  ORG $C485

; Turn IX toward IY by at most 4 per pass
;
; Input IX, IY. BearingTo, the difference with +$22, |d| < 4 sets it, else +-4.
; Used by the Helicarrier (HelicarrierWait) and the missiles (545 runs).
;
; Witness: L1 545 (death, missions, play, play2).
TurnToward:
  CALL ApiVector01
  LD C,(IX+$22)
  AND A
  SBC A,C
  LD B,A
  CALL ApiVector08
  CP $04
  JR C,l_C4A4
  LD A,B
  AND A
  LD A,$04
  JP P,l_C49E
  NEG
l_C49E:
  ADD A,(IX+$22)
  LD (IX+$22),A
l_C4A4:
  RET

; The rest of TurnToward, not run
;
; The missile's hit and lifetime code.
TurnTowardTail:
  DEFB $CD,$7C,$C4,$CD,$5D,$C4,$DD,$6E
  DEFB $05,$DD,$66,$06,$FD,$4E,$05,$FD
  DEFB $46,$06,$A7,$ED,$42,$3E,$04,$CB
  DEFB $2C,$CB,$1D,$3D,$20,$F9,$09

; Store the height (HL) and move the object
;
; Static only: `$7298` (a bank 3 call in bank 5) resolves here too, but bank
; 0's bytes at `$C4C4` are this tail.
;
; Known only from the code: no recording runs it (static walk).
SetHeightAndMove:
  LD (IX+$05),L
  LD (IX+$06),H
  JP ApiVector00

; Draw the sight mask $FD80 into the back buffer $9000 while $C4DC is set
;
; The timer `$C4CE` counts down; at 0 ResetSightTimer. While `$C4DC` is set the
; 3D view gets the sight mask (3507 runs, every 3D frame).
;
; Witness: L1 3507 (death, m2erbe, missions, play, play2).
DrawSightOverlay:
  LD A,$00
  AND A
  JR Z,l_C4DB
  DEC A
  LD (DrawSightOverlay+$0001),A
  JR NZ,l_C4DB
  CALL ResetSightTimer
l_C4DB:
  LD A,$00
  AND A
  RET Z
  LD A,(DrawSightOverlay+$0001)
  AND $01
  RET NZ
  LD HL,MissionHeader+$21BB
  LD DE,BackBuffer+$050F
  LD BC,$001F
  EXX
  LD B,$10
l_C4F1:
  EXX
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  EXX
  DJNZ l_C4F1
  RET

; Clear the sight timer $C4CE and open the target gate $C198
;
; `$C4CE` = 0, `$C198` = 1 (TargetInCone runs its body).
;
; Known only from the code: no recording runs it (static walk).
ResetSightTimer:
  XOR A
  LD (DrawSightOverlay+$0001),A
  LD A,$01
  LD (TargetInCone+$0001),A
  RET

  ORG $C648

; The collision pair timers, the slot list $C775, the row pointers $C78C
;
; Filled with `$FF` by `$6928` before a mission.
CollisionTables:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$00,$01,$02,$03
  DEFB $04,$05,$06,$07,$08,$09,$0A,$0B
  DEFB $0C,$0D,$0E,$0F,$10,$11,$12,$13
  DEFB $14,$15,$16,$17,$48,$C6,$49,$C6
  DEFB $4B,$C6,$4E,$C6,$52,$C6,$57,$C6
  DEFB $5D,$C6,$64,$C6,$6C,$C6,$75,$C6
  DEFB $7F,$C6,$8A,$C6,$96,$C6,$A3,$C6
  DEFB $B1,$C6,$C0,$C6,$D0,$C6,$E1,$C6
  DEFB $F3,$C6,$06,$C7,$1A,$C7,$2F,$C7
  DEFB $45,$C7,$5C,$C7

; Test the registered pairs and call both collision handlers
;
; For each pair whose timer is due: distance minus the radii, then the boxes;
; on an overlap calls IX's +$1A with IY the other, then the other way. The
; Immunity POKE writes 58 at `$C875` (`JP M,$C8AF` becomes `LD A,(nn)`, the
; overlap branch is gone).
;
; Witness: L1 3550 (death, m2erbe, missions, play, play2).
CollisionPass:
  LD A,$14
  LD (l_C7FB+$0001),A
  EXX
  LD HL,CollisionTables+$012D
  LD B,$17
l_C7C7:
  LD A,(HL)
  AND A
  JP M,l_C7D9
l_C7CC:
  INC HL
  DJNZ l_C7C7
  LD A,(CollisionPass+$0001)
  INC A
  AND $7F
  LD (CollisionPass+$0001),A
  RET
l_C7D9:
  EXX
  AND $7F
  LD E,A
  LD (l_C7FB+$0018),A
  ADD A,A
  LD H,$00
  LD L,A
  LD BC,$C78C
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (l_C7FB+$0008),HL
  LD B,E
l_C7F0:
  LD A,(HL)
  AND A
  JP P,l_C7FB
l_C7F5:
  INC HL
  DJNZ l_C7F0
  EXX
  JR l_C7CC
l_C7FB:
  CP $00
  JP NZ,l_C7F5
  PUSH HL
  PUSH BC
  LD DE,$0000
  AND A
  SBC HL,DE
  LD B,L
  CALL RecordByIndex
  JP Z,l_C93F
  PUSH HL
  POP IX
  LD B,$00
  CALL RecordByIndex
  JP Z,l_C93F
  PUSH HL
  POP IY
  LD L,(IX+$23)
  LD H,(IX+$24)
  LD E,(IY+$23)
  LD D,(IY+$24)
  AND A
  SBC HL,DE
  JP P,l_C832
  CALL NegHL
l_C832:
  LD (l_C8AF+$000F),HL
  LD (PushBackWork),HL
  EX DE,HL
  LD L,(IX+$26)
  LD H,(IX+$27)
  LD C,(IY+$26)
  LD B,(IY+$27)
  AND A
  SBC HL,BC
  JP P,l_C84E
  CALL NegHL
l_C84E:
  LD (l_C8AF+$0026),HL
  LD (PushBackWork+$0002),HL
  LD B,H
  LD C,L
  AND A
  SBC HL,DE
  LD H,B
  LD L,C
  JR C,l_C85E
  EX DE,HL
l_C85E:
  SRA D
  RR E
  ADD HL,DE
  LD C,(IX+$16)
  LD B,(IX+$17)
  AND A
  SBC HL,BC
  LD C,(IY+$16)
  LD B,(IY+$17)
  AND A
  SBC HL,BC
  JP M,l_C8AF             ; the Immunity POKE writes 58 here: JP M,$C8AF
                          ; becomes LD A,(nn): no overlap is handled, the
                          ; player's own shells included (complete-NOTES)
  LD A,(IX+$12)
  LD C,(IY+$12)
  ADD A,C
l_C87F:
  SRL H
  RR L
  SRL A
  JP NZ,l_C87F
  LD A,L
  AND A
  JP M,l_C892
  LD A,H
  AND A
  JP Z,l_C896
l_C892:
  LD A,$7F
  JR l_C8A9
l_C896:
  LD A,L
  CP $06
  JP C,l_C89D
  LD A,L
l_C89D:
  AND A
  JP NZ,l_C8A2
  INC A
l_C8A2:
  LD H,A
  LD A,(CollisionPass+$0001)
  ADD A,H
  AND $7F
l_C8A9:
  POP BC
  POP HL
  LD (HL),A
  JP l_C7F5
l_C8AF:
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  LD E,(IY+$0B)
  LD D,(IY+$0C)
  ADD HL,DE
  EX DE,HL
  LD HL,$0000
  AND A
  SBC HL,DE
  JP P,l_C92E
  LD L,(IX+$0F)
  LD H,(IX+$10)
  LD E,(IY+$0F)
  LD D,(IY+$10)
  ADD HL,DE
  EX DE,HL
  LD HL,$0000
  AND A
  SBC HL,DE
  JP P,l_C92E
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  LD E,(IY+$0D)
  LD D,(IY+$0E)
  ADD HL,DE
  EX DE,HL
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD C,(IY+$05)
  LD B,(IY+$06)
  AND A
  SBC HL,BC
  JP P,l_C900
  CALL NegHL
l_C900:
  AND A
  SBC HL,DE
  JP P,l_C92E
  EXX
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH IY
  LD L,(IX+$1A)
  LD H,(IX+$1B)
  LD (l_C900+$0018),HL
  CALL $0000
  POP IX
  POP IY
  LD L,(IX+$1A)
  LD H,(IX+$1B)
  LD (l_C900+$0028),HL
  CALL $0000
  POP DE
  POP BC
  POP HL
  EXX
l_C92E:
  POP BC
  POP HL
  LD A,(HL)
  AND A
  JP M,l_C7F5
  LD A,(CollisionPass+$0001)
  INC A
  AND $7F
  LD (HL),A
  JP l_C7F5
l_C93F:
  POP BC
  POP HL
  JP l_C7F5

; HL = the record B (+2), A = its state
;
; Input B = the record number. Output HL = the record, A = +2.
;
; Witness: L1 15176 (death, m2erbe, missions, play, play2).
RecordByIndex:
  LD HL,ObjectTable+$0002
  LD DE,$003C
  LD A,B
  AND A
  JP Z,l_C952
l_C94F:
  ADD HL,DE
  DJNZ l_C94F
l_C952:
  LD A,(HL)
  DEC HL
  DEC HL
  AND A
  RET

; Give the record a collision slot (vector $67CA)
;
; Takes the first free entry of the slot list `$C775`, stores it in +$3B, sets
; the pair timers of the new row in `$C648`.
;
; Witness: L1 431 (death, m2erbe, missions, play, play2).
RegisterCollision:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,$00
  LD (l_C9D1+$0008),A
  LD C,A
  LD A,$17
  AND A
  SBC A,C
  LD (l_C9D1+$000F),A
  AND A
  JP NZ,l_C96D
  INC A
l_C96D:
  LD B,A
  EXX
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,$0000
  LD A,(l_C9D1+$000F)
  SLA A
  LD E,A
  INC HL
  LD A,(HL)
  BIT 2,A
  JP Z,l_CA32
  EXX
  LD C,A
  LD HL,ObjectTable+$0002
  LD DE,$003C
  EXX
  LD HL,CollisionTables+$0144
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EXX
; This entry point is used by the routine at CollisionFilter.
l_C996:
  LD A,(HL)
  AND A
  JP M,l_C9A1
; This entry point is used by the routine at CollisionFilter.
l_C99B:
  LD A,$FF
  EXX
  JP l_C9D1
l_C9A1:
  INC HL
  LD A,(HL)
  LD (l_C9B4+$0006),A
  DEC HL

; Which pairs collide: the state bits 2 / 4 / 6 / 7
;
; Inside CollisionPass: both +2 bytes decide whether the pair is tested (radar
; bit 2, bit 4 no-collide, wrecks bits 6 / 7).
;
; Witness: L1 4065 (death, m2erbe, missions, play, play2).
CollisionFilter:
  BIT 2,A
  JR Z,l_C99B
  BIT 4,A
  JP Z,l_C9B4
  BIT 4,C
  JR NZ,l_C99B
l_C9B4:
  OR C
  AND $02
  JR Z,l_C99B
  LD A,$00
  OR C
  AND $C0
  CP $C0
  JR Z,l_C99B
  LD A,(l_C9B4+$0006)
  OR C
  AND $D0
  CP $10
  JR Z,l_C99B
  EXX
  LD A,(CollisionPass+$0001)
  INC A
; This entry point is used by the routine at RegisterCollision.
l_C9D1:
  LD (DE),A
  INC DE
  EXX
  ADD HL,DE
  DJNZ l_C996
  ADD HL,DE
  LD B,$00
  EXX
  EX DE,HL
  LD HL,CollisionTables+$012C
  LD C,$00
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  OR $80
  LD (HL),A
  EXX
l_C9E9:
  EXX
  EX DE,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  EXX
  LD A,(HL)
  AND A
  JP M,l_C9FC
l_C9F7:
  LD A,$FF
  EXX
  JR l_CA2D
l_C9FC:
  INC HL
  LD A,(HL)
  DEC HL
  BIT 2,A
  JR Z,l_C9F7
  BIT 4,A
  JR Z,l_CA0B
  BIT 4,C
  JR NZ,l_C9F7
l_CA0B:
  LD (l_CA0B+$0009),A
  OR C
  AND $02
  JR Z,l_C9F7
  LD A,$00
  OR C
  AND $C0
  CP $C0
  JR Z,l_C9F7
  LD A,(l_CA0B+$0009)
  OR C
  AND $D0
  CP $10
  JR Z,l_C9F7
  EXX
  LD A,(CollisionPass+$0001)
  INC A
  AND $7F
l_CA2D:
  LD (HL),A
  EXX
  ADD HL,DE
  DJNZ l_C9E9
; This entry point is used by the routine at RegisterCollision.
l_CA32:
  POP HL
  POP DE
  POP BC
  EXX
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; Free the record's collision slot (vector $67CD)
;
; Returns the slot of +$3B to the list and marks the row's timers `$FF`.
;
; Witness: L1 230 (death, m2erbe, missions, play, play2).
UnregisterCollision:
  LD A,(IX+$3B)
  LD E,A
  LD B,$00
  LD C,A
  LD HL,CollisionTables+$012C
  ADD HL,BC
  EX AF,AF'
  LD A,(HL)
  AND $7F
  LD (HL),A
  EX AF,AF'
  LD HL,CollisionTables+$0144
  LD C,A
  SLA C
  ADD HL,BC
  LD C,A
  LD A,E
  AND A
  JR NZ,l_CA59
  INC A
l_CA59:
  LD B,A
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,$FF
l_CA60:
  LD (DE),A
  INC DE
  DJNZ l_CA60
  EXX
  LD B,(IX+$3B)
  LD A,$17
  AND A
  SBC A,B
  LD B,A
  LD A,$FF
l_CA6F:
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
  DJNZ l_CA6F
  RET

; A unit strikes the tank with no shell: PlayerHit with the unit as the hitter,
; damage doubled
;
; IX = the unit. Saves its +3 and +$14, sets +3 b4 and doubles +$14, calls
; PlayerHit `$CAA5` with IY = the unit and IX = the tank (`$75F0`), then
; restores both bytes. Called by mission 8's type 10 at `$E1FC` (a direct
; strike while it is aligned, docs/07-objects.md 7.14); no recording runs it.
StrikePlayer:
  LD C,(IX+$03)
  LD B,(IX+$14)
  PUSH IX
  POP IY
  PUSH BC
  PUSH IX
  LD A,C
  OR $10
  LD (IY+$03),A
  SLA B
  LD (IY+$14),B
  LD IX,ObjectTable
  CALL PlayerHit
  POP IX
  POP BC
  LD (IX+$03),C
  LD (IX+$14),B
  RET
