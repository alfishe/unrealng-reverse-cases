; --------------------------------------------------------------------------------------------------------------------
; grid.asm: The room grid, the animated cells, the drones
; --------------------------------------------------------------------------------------------------------------------

; HL = the grid cell of SpriteX/SpriteY ($E19F + 32 x (Y / 8) + X / 8; A = 1
; the grid from $E19E)
;
; Witness: L1 215029 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
  LD DE,RoomGridLeft
CellPointerAdd:
  ADD HL,DE               ; the column
  RET

; HL = the back buffer address of SpriteX / SpriteY
;
; Witness: L1 4771 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room24, p1-room30, rzx-p1- x32).
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

; Every other pass: the animated characters' next frames (AnimFramesA $AE8D,
; AnimFramesB $AEAD, the frame lists $A60C, $A61A)
;
; Witness: L1 16879 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
AnimateCells:
  LD HL,AnimFramesA
  LD A,(PassToggle)
  OR A
  JP Z,AnimFrameB
  LD HL,AnimFramesB
AnimFrameB:
  LD DE,AnimChar252       ; character 252's frames
  LD BC,$0020
AnimFrameCopy:
  LDI                     ; copy a frame
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  JP PE,AnimFrameCopy
  CALL AnimateCells2
  LD IY,AnimCount3
  LD DE,FramesList1
  LD HL,AnimChar68
  LD BC,$0008
  CALL CopyFrame
  LD IY,AnimCount4
  LD DE,FramesList4
  LD HL,AnimChar127
  LD BC,$0008
  JP CopyFrame

; The frames of character 250 from FramesList2 $A602
;
; Witness: L1 16879 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
AnimateCells2:
  LD IY,AnimCount2
  LD DE,FramesList2
  LD HL,AnimChar250
  LD BC,$0010
  JP CopyFrame

; The restart marker's frames (character 249, FramesList3 $A5F4)
;
; Witness: L1 833 (c1, p1-cursor, p1-define, p1-kempston, p1-room24, p1-room30,
; rzx-p1- x23).
AnimateRestart:
  LD IY,AnimCount1
  LD DE,FramesList3
  LD HL,AnimChar249
  LD BC,$0008

; Copy the frame at HL into the character at DE (8 bytes), from the list
; position Temp1
;
; Witness: L1 51471 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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

; The frame lists of the animated characters: restart marker ($A5F4), character
; 250 ($A602), $A60C, $A61A
FramesList3:
  DEFB $2A,$8D,$32,$8D,$3A,$8D,$42,$8D,$4A,$8D,$52,$8D,$FF,$FF
FramesList2:
  DEFB $5A,$8D,$6A,$8D,$7A,$8D,$6A,$8D,$FF,$FF
FramesList1:
  DEFB $12,$94,$1A,$94,$22,$94,$2A,$94,$32,$94,$3A,$94,$FF,$FF
FramesList4:
  DEFB $42,$94,$4A,$94,$52,$94,$5A,$94,$62,$94,$6A,$94,$FF,$FF

; The drones' table at $5E50: 8 records of 3 bytes, the angles 0, 8, 16, ... 56
;
; Witness: L1 42 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x19).
InitDrones:
  LD HL,$5E50
  LD B,$08
  LD A,$00
InitDronesLoop:
  LD (HL),A               ; each drone
  LD DE,$0003
  ADD HL,DE
  ADD A,$08
  DJNZ InitDronesLoop
  RET

; The multiple weapon (Weapon 3): the drones orbit Rex (DroneOrbit $A6CB) and
; are drawn (DronePicture $A74B), one per power level
;
; Witness: L1 16841 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
  LD IY,$5E4E
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
  LD HL,DronePicture
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

; The drones' orbit: 64 X, Y offset pairs round Rex, then the drone pictures at
; DronePicture $A74B
DroneOrbit:
  DEFB $05,$00,$06,$00,$07,$00,$08,$00,$09,$00,$0A,$00,$0B,$01,$0C,$01
  DEFB $0D,$02,$0E,$02,$0F,$03,$10,$04,$11,$05,$11,$06,$12,$07,$12,$08
  DEFB $13,$09,$13,$0A,$13,$0B,$13,$0C,$13,$0D,$13,$0E,$12,$0F,$12,$10
  DEFB $11,$11,$11,$12,$10,$13,$0F,$14,$0E,$15,$0D,$15,$0C,$16,$0B,$16
  DEFB $0A,$17,$09,$17,$08,$17,$07,$17,$06,$17,$05,$17,$04,$16,$03,$16
  DEFB $02,$15,$01,$15,$00,$14,$FF,$13,$FE,$12,$FE,$11,$FD,$10,$FD,$0F
  DEFB $FC,$0E,$FC,$0D,$FC,$0C,$FC,$0B,$FC,$0A,$FC,$09,$FD,$08,$FD,$07
  DEFB $FE,$06,$FE,$05,$FF,$04,$00,$03,$01,$02,$02,$02,$03,$01,$04,$01
DronePicture:
  DEFB $60,$00,$C0,$00,$10,$00,$20,$00,$20,$00,$68,$00,$48,$00,$20,$00 ; the
  DEFB $08,$00,$24,$00,$34,$00,$10,$00,$0C,$00,$02,$00,$18,$00,$0C,$00 ; drone's
  DEFB $06,$00,$08,$00,$03,$00,$06,$00,$02,$00,$04,$80,$05,$80,$01,$00 ; pictures
  DEFB $00,$80,$02,$C0,$02,$40,$01,$00,$00,$C0,$00,$60,$01,$00,$00,$C0

  ORG $A7A9

; Roll an 8-byte character at HL one line up (the first line goes last): the
; conveyor characters
;
; Witness: L1 16878 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
; Witness: L1 33757 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
