; --------------------------------------------------------------------------------------------------------------------
; grid.asm: The room grid, the animated cells, the drones
; --------------------------------------------------------------------------------------------------------------------

; HL = the grid cell of SpriteX/SpriteY ($E19F + 32 x (Y / 8) + X / 8; A = 1
; the grid from $E19E)
;
; As REX 1's CellPointer $A503 (src/game/grid.asm).
;
; Witness: L1 68024 (d1, demo-cycle).
CellPointer:
  PUSH AF
  LD A,(SpriteY)
  LD L,A
  LD H,$00
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,RoomGrid
  POP AF
  OR A
  JP NZ,CellPointerAdd
  LD DE,CellIndexMap+$02FF
CellPointerAdd:
  ADD HL,DE               ; the column
  RET

; HL = the back buffer address of SpriteX / SpriteY
;
; As REX 1's BufferAddress $A535 (src/game/grid.asm).
;
; Witness: L1 504 (d1, demo-cycle).
BufferAddress:
  LD A,(SpriteY)
  LD L,A
  LD H,$00
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,$5800
  ADD HL,DE
  RET

; Every other pass: characters 252-255 from AnimFramesA $AFAE or AnimFramesB
; $AFCE, then AnimateCells2 and the two lists FramesChar68 $A0E0, FramesChar127
; $A0EE
;
; Changed from REX 1's AnimateCells $A55E (src/game/grid.asm).
;
; Witness: L1 6741 (d1, demo-cycle).
AnimateCells:
  LD HL,AnimFramesA
  LD A,(PassToggle)
  OR A
  JP Z,AnimFrameB
  LD HL,AnimFramesB
AnimFrameB:
  LD DE,AnimChar252       ; character 252's frames
  LD BC,$0020
l_A045:
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  JP PE,l_A045
  CALL AnimateCells2
  LD IY,AnimCount3
  LD DE,FramesChar68
  LD HL,AnimChar68
  LD BC,$0008
  CALL CopyFrame
  LD IY,AnimCount4
  LD DE,FramesChar127
  LD HL,AnimChar127
  LD BC,$0008
  JP CopyFrame

; The frames of character 250 from FramesList2 $A0D6
;
; As REX 1's AnimateCells2 $A5A7 (src/game/grid.asm).
;
; Witness: L1 6741 (d1, demo-cycle).
AnimateCells2:
  LD IY,AnimCount2
  LD DE,FramesList2
  LD HL,AnimChar250
  LD BC,$0010
  JP CopyFrame

; The restart marker's frames (character 249, FramesList3 $A0C8)
;
; As REX 1's AnimateRestart $A5B7 (src/game/grid.asm).
;
; Witness: L1 240 (d1, demo-cycle).
AnimateRestart:
  LD IY,AnimCount1
  LD DE,FramesList3
  LD HL,AnimChar249
  LD BC,$0008

; Copy the frame at HL into the character at DE (8 bytes), from the list
; position Temp1
;
; As REX 1's CopyFrame $A5C4 (src/game/grid.asm).
;
; Witness: L1 20463 (d1, demo-cycle).
CopyFrame:
  LD (Temp1),DE
  LD (Temp2),HL
  INC (IY+$00)
  INC (IY+$00)
CopyFrameNext:
  LD L,(IY+$00)           ; the list's next frame
  LD H,$00
  LD DE,(Temp1)
  ADD HL,DE
  EX DE,HL
  LD A,(DE)
  CP $FF
  JP NZ,CopyFrameDo
  LD (IY+$00),$00
  JP CopyFrameNext
CopyFrameDo:
  LD L,A                  ; copy it
  INC DE
  LD A,(DE)
  LD H,A
  LD DE,(Temp2)
  LDIR
  RET

; The frame lists of the animated characters, picture words to $FFFF: the
; restart marker (FramesList3, character 249), character 250 ($A0D6), character
; 68 ($A0E0), character 127 ($A0EE)
;
; As REX 1's FramesList3 $A5F4 (src/game/grid.asm).
FramesList3:
  DEFB $84,$85,$8C,$85,$94,$85,$9C,$85,$A4,$85,$AC,$85,$FF,$FF
FramesList2:
  DEFB $B4,$85,$C4,$85,$D4,$85,$C4,$85,$FF,$FF ; character 250 (AnimateCells2)
FramesChar68:
  DEFB $9C,$88,$A4,$88,$AC,$88,$B4,$88,$BC,$88,$C4,$88,$FF,$FF ; character 68
                                                               ; (AnimateCells,
                                                               ; AnimCount3)
FramesChar127:
  DEFB $CC,$88,$D4,$88,$DC,$88,$E4,$88,$EC,$88,$F4,$88,$FF,$FF ; character 127
                                                               ; (AnimateCells,
                                                               ; AnimCount4)

; The drones' table at $5E50: 8 records of 3 bytes, the angles 0, 8, 16, ... 56
;
; As REX 1's InitDrones $A628 (src/game/grid.asm).
;
; Witness: L1 87 (d1, demo-cycle).
InitDrones:
  LD HL,$5E85
  LD B,$08
  LD A,$00
InitDronesLoop:
  LD (HL),A               ; each drone
  LD DE,$0003
  ADD HL,DE
  ADD A,$08
  DJNZ InitDronesLoop
  RET

; The multiple weapon (Weapon 3): the drones orbit Rex (DroneOrbit $A19F) and
; are drawn (their pictures at $A21F), one per power level
;
; Changed from REX 1's UpdateDrones $A639 (src/game/grid.asm).
;
; Witness: L1 6753 (d1, demo-cycle).
UpdateDrones:
  LD A,(Dying)
  OR A
  RET NZ
  LD A,(Weapon)
  CP $03
  RET NZ
  LD A,(SparkleMode)
  OR A
  RET NZ
  LD IY,$5E83
  LD A,(PowerLevel)
  ADD A,$03
  LD B,A
DroneLoop:
  PUSH BC                 ; each drone
  LD A,(IY+$02)
  SLA A
  LD E,A
  LD D,$00
  LD HL,DroneOrbit
  ADD HL,DE
  LD A,(RexX)
  DEC A
  ADD A,(HL)
  LD (IY+$00),A
  INC HL
  LD A,(RexY)
  ADD A,$02
  ADD A,(HL)
  LD (IY+$01),A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,ShotBufferOrigin
  ADD HL,DE
  LD E,(IY+$00)
  SRL E
  SRL E
  SRL E
  LD D,$00
  ADD HL,DE
  PUSH HL
  LD A,(IY+$00)
  AND $07
  SLA A
  SLA A
  SLA A
  LD E,A
  LD D,$00
  LD HL,DronePictures
  ADD HL,DE
  EX DE,HL
  POP HL
  LD B,$04
DroneDraw:
  PUSH BC                 ; draw the drones
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC DE
  INC HL
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC DE
  LD BC,$001F
  ADD HL,BC
  POP BC
  DJNZ DroneDraw
  LD A,(IY+$02)
  INC A
  LD (IY+$02),A
  CP $40
  JP NZ,DroneNext
  LD (IY+$02),$00
DroneNext:
  LD DE,$0003             ; the next drone
  ADD IY,DE
  POP BC
  DJNZ DroneLoop
  RET

; The drones' orbit: X, Y offset pairs round Rex, then the drone pictures at
; $A21F
;
; As REX 1's DroneOrbit $A6CB (src/game/grid.asm).
DroneOrbit:
  DEFB $05,$00,$06,$00,$07,$00,$08,$00,$09,$00,$0A,$00,$0B,$01,$0C,$01
  DEFB $0D,$02,$0E,$02,$0F,$03,$10,$04,$11,$05,$11,$06,$12,$07,$12,$08
  DEFB $13,$09,$13,$0A,$13,$0B,$13,$0C,$13,$0D,$13,$0E,$12,$0F,$12,$10
  DEFB $11,$11,$11,$12,$10,$13,$0F,$14,$0E,$15,$0D,$15,$0C,$16,$0B,$16
  DEFB $0A,$17,$09,$17,$08,$17,$07,$17,$06,$17,$05,$17,$04,$16,$03,$16
  DEFB $02,$15,$01,$15,$00,$14,$FF,$13,$FE,$12,$FE,$11,$FD,$10,$FD,$0F
  DEFB $FC,$0E,$FC,$0D,$FC,$0C,$FC,$0B,$FC,$0A,$FC,$09,$FD,$08,$FD,$07
  DEFB $FE,$06,$FE,$05,$FF,$04,$00,$03,$01,$02,$02,$02,$03,$01,$04,$01
DronePictures:
  DEFB $60,$00,$C0,$00,$10,$00,$20,$00,$20,$00,$68,$00,$48,$00,$20,$00 ; the
  DEFB $08,$00,$24,$00,$34,$00,$10,$00,$0C,$00,$02,$00,$18,$00,$0C,$00 ; drones'
  DEFB $06,$00,$08,$00,$03,$00,$06,$00,$02,$00,$04,$80,$05,$80,$01,$00 ; pictures
  DEFB $00,$80,$02,$C0,$02,$40,$01,$00,$00,$C0,$00,$60,$01,$00,$00,$C0 ; (UpdateDrones)

  ORG $A27D

; Roll an 8-byte character at HL one line up (the first line goes last): the
; conveyor characters
;
; As REX 1's RollCharRight $A7A9 (src/game/grid.asm).
;
; Witness: L1 6741 (d1, demo-cycle).
RollCharRight:
  PUSH HL
  LD C,(HL)
  LD E,L
  LD D,H
  INC HL
  LD B,$07
RollRightLoop:
  LD A,(HL)               ; each line
  LD (DE),A
  INC DE
  INC HL
  DJNZ RollRightLoop
  LD A,C
  LD (DE),A
  POP HL
  RET

; Roll an 8-byte character at HL one line down
;
; As REX 1's RollCharLeft $A7BA (src/game/grid.asm).
;
; Witness: L1 13482 (d1, demo-cycle).
RollCharLeft:
  PUSH HL
  LD DE,$0007
  ADD HL,DE
  LD C,(HL)
  LD E,L
  LD D,H
  DEC HL
  LD B,$07
RollLeftLoop:
  LD A,(HL)               ; each line
  LD (DE),A
  DEC DE
  DEC HL
  DJNZ RollLeftLoop
  POP HL
  LD (HL),C
  RET
