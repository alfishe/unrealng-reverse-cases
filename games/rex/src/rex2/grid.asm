; --------------------------------------------------------------------------------------------------------------------
; grid.asm: The room grid, the animated cells, the drones
; --------------------------------------------------------------------------------------------------------------------

; HL = the grid cell of SpriteX/SpriteY ($E19F + 32 x (Y / 8) + X / 8; A = 1
; the grid from $E19E)
;
; As REX 1's CellPointer $A503 (src/game/grid.asm).
;
; Witness: L1 115349 (c2, p2-room20, rzx-p2- x21).
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
; As REX 1's BufferAddress $A535 (src/game/grid.asm).
;
; Witness: L1 3102 (c2, p2-room20, rzx-p2- x21).
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

; Each pass: characters 252-255 from AnimFramesA $AF82 or AnimFramesB $AFA2
; (alternate passes, $A1B0), then the 16-byte animation at $6DD6 by FramesList2
; $A789
;
; Changed from REX 1's AnimateCells $A55E (src/game/grid.asm).
;
; Witness: L1 10855 (c2, p2-room20, rzx-p2- x21).
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
  RET

; The frames of characters 250-251 from FramesList2 $A789
;
; As REX 1's AnimateCells2 $A5A7 (src/game/grid.asm).
;
; Witness: L1 10855 (c2, p2-room20, rzx-p2- x21).
AnimateCells2:
  LD IY,AnimCount2
  LD DE,FramesList2
  LD HL,AnimChar250
  LD BC,$0010
  JP CopyFrame

; The restart marker's frames (character 249, FramesList3 $A77D)
;
; As REX 1's AnimateRestart $A5B7 (src/game/grid.asm).
;
; Witness: L1 375 (c2, p2-room20, rzx-p2- x15).
AnimateRestart:
  LD IY,AnimCount1
  LD DE,FramesList3
  LD HL,AnimChar73
  LD BC,$0008

; Copy the frame at HL into the character at DE (8 bytes), from the list
; position Temp1
;
; As REX 1's CopyFrame $A5C4 (src/game/grid.asm).
;
; Witness: L1 11230 (c2, p2-room20, rzx-p2- x21).
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
; restart marker (character 73: $8A68-$8A88 by 8), then FramesList2
;
; As REX 1's FramesList3 $A5F4 (src/game/grid.asm).
FramesList3:
  DEFB $68,$8A,$70,$8A,$78,$8A,$80,$8A,$88,$8A,$FF,$FF
FramesList2:
  DEFB $90,$8A,$A0,$8A,$B0,$8A,$A0,$8A,$FF,$FF ; characters 250-251: $8A90,
                                               ; $8AA0, $8AB0, $8AA0

; The drones' table at $5E50: 8 records of 3 bytes, the angles 0, 8, 16, ... 56
;
; As REX 1's InitDrones $A628 (src/game/grid.asm).
;
; Witness: L1 18 (c2, rzx-p2- x9).
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

; The multiple weapon (Weapon 3): the drones orbit Rex (DroneOrbit $A836) and
; are drawn (DronePicture $A8B6), one per power level
;
; As REX 1's UpdateDrones $A639 (src/game/grid.asm).
;
; Witness: L1 10440 (c2, p2-room20, rzx-p2- x21).
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
  LD DE,AttrShadowPlay+$02A0
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
; DronePicture $A8B6
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
DronePicture:
  DEFB $60,$00,$C0,$00,$10,$00,$20,$00,$20,$00,$68,$00,$48,$00,$20,$00 ; the
  DEFB $08,$00,$24,$00,$34,$00,$10,$00,$0C,$00,$02,$00,$18,$00,$0C,$00 ; drone's
  DEFB $06,$00,$08,$00,$03,$00,$06,$00,$02,$00,$04,$80,$05,$80,$01,$00 ; pictures
  DEFB $00,$80,$02,$C0,$02,$40,$01,$00,$00,$C0,$00,$60,$01,$00,$00,$C0
