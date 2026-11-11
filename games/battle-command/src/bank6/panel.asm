; --------------------------------------------------------------------------------------------------------------------
; panel.asm: The panel jobs of the play views: messages, the damage colours, the attributes, the bars
;
; The play views keep part of their panel work in bank 6: StatusViewMessage $D3C9 (the message of the status view and
; the damage board), ShowDamageColours $D4A5 (the damage board's boxes), PanelAttributes $D521 (PanelSetup $6B32) and
; the bars of the cockpit, UpdatePanelBars $D58C (UpdateSlotBars $7327).
; --------------------------------------------------------------------------------------------------------------------

  ORG $D3C9

; Once per message: "TANK HAS BEEN HIT" or "COLLISION OCCURED", then
; MessageOnce off
;
; Returns when MessageOnce `$7D5D` is already a `RET`; else the timer `$87D7` =
; 100, the text by bit 4 of `$7D64`, and `$7D5D` = `RET`. Witness: L1 43
; (m2erbe, missions, play).
StatusViewMessage:
  LD A,($7D5D)
  CP $C9
  RET Z
  LD A,$64
  LD ($87D7),A
  LD HL,StatusMessages
  LD A,($7D64)
  BIT 4,A
  JR NZ,StatusMessagePrint
  LD HL,CollisionText
StatusMessagePrint:
  CALL $6FB3
  LD A,$C9
  LD ($7D5D),A
  RET

; Texts: "TANK HAS BEEN HIT", "COLLISION OCCURED"
;
; Read by StatusViewMessage.
StatusMessages:
  INCBIN "res/texts/status-messages.bin",$0000,23
CollisionText:
  INCBIN "res/texts/status-messages.bin",$0017,23

; Text: "MISSION COMPLETED:-", a blank line, "FINAL SCORE:-" and ten digits at
; $D461
;
; Printed only by PrintFinalScore (unused).
FinalScoreText:
  INCBIN "res/texts/final-score-text.bin",$0000,73
FinalScoreDigits:
  INCBIN "res/texts/final-score-text.bin",$0049,11

; Text: "MISSIONS COMPLETED" (code 8: MissionsCompleted), "SCORE TO DATE" and
; nine digits at $D49A
;
; Printed by PrintScore; the digits by LongToDigits and DotLeadingZeros.
StatusText:
  INCBIN "res/texts/status-text.bin",$0000,46
ScoreDigits:
  INCBIN "res/texts/status-text.bin",$002E,11

; Colour the Dragonfly's damage boxes by the four damage values $8301-$8304
;
; DamageColour for each, AttrBoxAt `$6CFD` with the records of DamageBoxes.
; Witness: L1 3 (play).
ShowDamageColours:
  LD A,($8301)
  CALL DamageColour
  PUSH BC
  LD HL,DamageBoxes+$0004
  CALL $6CFD
  POP BC
  LD HL,DamageBoxes+$0008
  CALL $6CFD
  LD A,($8302)
  CALL DamageColour
  PUSH BC
  LD HL,DamageBoxes+$000C
  CALL $6CFD
  POP BC
  LD HL,DamageBoxes+$0010
  CALL $6CFD
  LD A,($8303)
  CALL DamageColour
  PUSH BC
  LD HL,DamageBoxes+$0014
  CALL $6CFD
  POP BC
  LD HL,DamageBoxes+$0018
  CALL $6CFD
  LD A,($8304)
  CALL DamageColour
  LD HL,DamageBoxes
  CALL $6CFD
  RET

; B = DamageColourTable[A / 32]
;
; Witness: L1 12 (play).
DamageColour:
  SRL A
  SRL A
  SRL A
  SRL A
  SRL A
  LD HL,DamageColourTable
  LD C,A
  LD B,$00
  ADD HL,BC
  LD B,(HL)
  RET

; AttrBoxAt records of the damage board (height, column, attribute, row)
;
; Read by ShowDamageColours.
DamageBoxes:
  DEFB $02,$02,$0A,$09
  DEFB $07,$02,$04,$02
  DEFB $04,$02,$04,$0B
  DEFB $07,$06,$06,$02
  DEFB $04,$06,$06,$0B
  DEFB $07,$0C,$04,$02
  DEFB $06,$0C,$04,$09

; The values of the four damage steps
;
; Read by DamageColour.
DamageColourTable:
  DEFB $00,$50,$70,$60

; The cockpit panel's attributes: a cleared box, two boxes and the gauge
; colours
;
; Called by PanelSetup `$6B32`. ScreenRowFill, AttrBox PanelBoxB and PanelBoxA,
; single attributes at `$5A48-$5AAA` and `$580A-$5859`, then FillPanelRows
; `$6AAB`. Witness: L1 27 (c1, death, m2erbe, missions, play, play2).
PanelAttributes:
  LD A,$FF
  EX AF,AF'
  LD A,$78
  LD C,$0C
  EXX
  LD D,$08
  LD E,$28
  CALL $6D22
  LD HL,PanelBoxB
  CALL $6CFB
  LD HL,PanelBoxA
  CALL $6CFB
  LD A,$42
  LD HL,$5A48
  LD (HL),A
  INC HL
  INC HL
  LD A,$44
  LD (HL),A
  LD A,$46
  LD HL,$5A68
  LD (HL),A
  INC HL
  INC HL
  LD (HL),A
  LD HL,$5A88
  LD (HL),A
  INC HL
  INC HL
  LD (HL),A
  LD A,$44
  LD HL,$5AA8
  LD (HL),A
  INC HL
  INC HL
  LD A,$42
  LD (HL),A
  LD A,$44
  LD HL,$580A
  LD DE,$0005
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  LD HL,$582A
  LD A,$46
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  LD HL,$584A
  LD A,$42
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  JP $6AAB

; The four bars of the cockpit panel
;
; Called by UpdateSlotBars `$7327`. Witness: L1 3601 (c1, death, m2erbe,
; missions, play, play2).
UpdatePanelBars:
  CALL DrawHeadingStrip
  CALL DrawBearing
  CALL DrawSpeedBar
  JP DrawFuelBar

; Redraw the compass strip from the heading $7612 ($75F0 + $22) when it changed
;
; Shapes from BarShapesB, shifted to the pixel, five lines 12 bytes apart.
; Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).
DrawHeadingStrip:
  LD HL,$75F0
  LD B,$00
  LD C,$22
  ADD HL,BC
  LD A,(HL)
SpeedLastOp:
  LD E,$00                ; LD E,n: n ($D5A2) the value last drawn
  CP E
  RET Z
  LD (SpeedLastOp+$0001),A
  SRL A
  SRL A
  LD E,A
  CPL
  AND $07
  LD (SpeedBarLine+$000C),A
  LD A,E
  LD HL,$6664
  LD C,$16
  EXX
  LD H,$D7
  SRL A
  SRL A
  SRL A
  ADD A,$7F
  LD L,A
  LD A,$05
  LD (SpeedBarStore+$001B),A
SpeedBarLine:
  PUSH HL
  LD D,(HL)
  INC L
  LD A,(HL)
  INC L
  LD E,(HL)
  INC L
  LD C,(HL)
  INC L
  LD L,(HL)
  EX AF,AF'
  LD A,$00
  LD B,A
  AND A
  JR NZ,SpeedBarShift
  EX AF,AF'
  JR SpeedBarStore
SpeedBarShift:
  EX AF,AF'
SpeedBarShiftLoop:
  SRL D
  RR A
  RR E
  RR C
  RR L
  DJNZ SpeedBarShiftLoop
SpeedBarStore:
  EXX
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  EX DE,HL
  ADD HL,BC
  LD (HL),A
  INC L
  EXX
  LD A,E
  EXX
  LD (HL),A
  INC L
  EXX
  LD A,C
  EXX
  LD (HL),A
  INC L
  EXX
  LD A,L
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  POP HL
  LD A,$00
  DEC A
  RET Z
  LD (SpeedBarStore+$001B),A
  LD A,$0C
  ADD A,L
  LD L,A
  JR SpeedBarLine

; The speed bar: $7E8E = abs(speed), line $90 column 8, when it changed
;
; Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).
DrawSpeedBar:
  LD A,($7E8E)
  CP $01
  RET Z
  LD (DrawSpeedBar+$0004),A
  LD E,$90
  LD C,$08
  CALL $67D6
  SRL A
  AND $1F
  JP $7438

; The fuel bar: Fuel high byte $7C58 / 2, line $90 column 10, redrawn every
; pass (no change test)
;
; Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).
DrawFuelBar:
  LD A,($7C58)
  SRL A
  AND $1F
  LD E,$90
  LD C,$0A
  JP $7438

; The bearing arrow: ApiVector01's bearing less the heading $7612, when it
; changed (shapes BarShapesA), x 32-55 y 138-142
;
; Witness: L1 3601 (c1, death, m2erbe, missions, play, play2).
DrawBearing:
  LD IX,$75F0
  LD IY,$7E5F
  CALL $67C1
  SUB (IX+$22)
  LD C,$00
  CP C
  RET Z
  LD (DrawBearing+$000F),A
  LD HL,$6614
  EXX
  SRL A
  SRL A
  LD E,A
  CPL
  AND $07
  LD (BarBLine+$0009),A
  LD A,E
  SRL A
  SRL A
  SRL A
  LD D,$00
  LD E,A
  LD HL,BarShapesA
  ADD HL,DE
  LD B,$05
BarBLine:
  PUSH BC
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  INC HL
  LD C,(HL)
  LD B,$00
  DEC B
  JP M,BarBStore
  INC B
BarBShiftLoop:
  SRL D
  RR E
  RR A
  RR C
  DJNZ BarBShiftLoop
BarBStore:
  EX AF,AF'
  LD A,E
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  INC HL
  INC HL
  INC HL
  INC HL
  LD (HL),A
  EX AF,AF'
  INC HL
  LD (HL),A
  INC HL
  EXX
  LD A,C
  LD BC,$0008
  ADD HL,BC
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  POP BC
  DJNZ BarBLine
  RET

; Bar shapes of DrawBarB
;
; Read by DrawBarB (`$D6A3-$D6D9`).
BarShapesA:
  DEFB $88,$18,$11,$11,$11,$18,$88,$88,$88,$18,$11
  DEFB $CC,$18,$33,$33,$33,$3C,$CC,$CC,$CC,$18,$33
  DEFB $EE,$18,$77,$77,$77,$7E,$EE,$EE,$EE,$18,$77
  DEFB $CC,$18,$33,$33,$33,$3C,$CC,$CC,$CC,$18,$33
  DEFB $88,$18,$11,$11,$11,$18,$88,$88,$88,$18,$11

  ORG $D77F

; Bar shapes of DrawSpeedBar
;
; Read by DrawSpeedBar (`$D77F-$D7BA`).
BarShapesB:
  DEFB $A0,$02,$20,$03,$E0,$01,$E0,$02,$A0,$02,$20,$03
  DEFB $A0,$03,$20,$02,$00,$02,$00,$02,$A0,$03,$20,$02
  DEFB $A4,$92,$A4,$93,$E1,$91,$C4,$92,$A4,$92,$A4,$93
  DEFB $A0,$02,$60,$02,$00,$00,$20,$02,$A0,$02,$60,$02
  DEFB $40,$02,$20,$03,$E0,$03,$C0,$01,$40,$02,$20,$03
