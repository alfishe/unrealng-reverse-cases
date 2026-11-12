; --------------------------------------------------------------------------------------------------------------------
; logo.asm: The ZYX logo: its glint and its reflection
;
; The logo (Logo $A900, four 40x40 sprites; src/res/graphics/logo.png) is printed by DrawScreen; DrawReflection $6DC6
; prints it upside down at the bottom. For the first 64 frames of every 256 LogoGlint $6D04 runs a diagonal red glint
; across the logo (the top one when Frames' high byte is even, the reflection when odd).
; --------------------------------------------------------------------------------------------------------------------

  ORG $6D04

; Frames 0-63 of every 256: the glint across the logo or its reflection
;
; At Frames low byte 0 the corner cells by the logo turn red (2). Then on every
; even frame up to 52 a glint step (26 steps): 5 rows, each row's three cells
; left of the step restored from ScreenCopy's attributes (RestoreGlintCells
; $6D6A) and three cells red, bright red, red drawn (DrawGlintRow $6D8A),
; mirrored about the screen's centre, the row above one cell further on.
;
; Witness: L1 13931 (c1-c4).
LogoGlint:
  LD A,(Frames)
  CP $40
  RET NC
  LD HL,Attributes+6
  LD (GlintCornerLeft+$0001),HL
  LD HL,Attributes+25
  LD (GlintCornerRight+$0001),HL
  LD HL,Attributes+128
  LD (GlintRowStart+$0001),HL
  LD A,(Frames+1)
GlintHalf:
  IFDEF GlintAdd
  ADD A,$01               ; variant: Z only for $FF: the logo glints only in frames $FF00-$FF34,
                          ; the reflection in every 256-frame block
  ELSE
  AND $01                 ; Frames high byte bit 0: the glint on the logo
                          ; (even) or on its reflection (odd)
  ENDIF
  JR Z,GlintStart
  LD HL,Attributes+614
  LD (GlintCornerLeft+$0001),HL
  LD HL,Attributes+633
  LD (GlintCornerRight+$0001),HL
  LD HL,Attributes+736
  LD (GlintRowStart+$0001),HL
GlintStart:
  LD A,(Frames)
  AND A
  JR NZ,GlintStep
  LD A,$02
GlintCornerLeft:
  LD (Attributes+6),A
GlintCornerRight:
  LD (Attributes+25),A
  RET
GlintStep:
  AND $01
  RET NZ
  LD A,(Frames)
  RRCA
  AND $1F
  CP $1B
  RET NC
  LD C,A
  LD B,$05
GlintRowStart:
  LD HL,Attributes+128
GlintRow:
  DEC C
  CALL RestoreGlintCells
  INC C
  CALL DrawGlintRow
  INC C
  PUSH BC
  LD BC,$0020
  IFDEF GlintDaa
  DAA                     ; variant: $27 for $A7, one bit off (a damaged byte)
  ELSE
  AND A
  ENDIF
  SBC HL,BC
  POP BC
  DJNZ GlintRow
  RET

; Copy 3 attribute cells at the glint's column and their mirror image from
; ScreenCopy
;
; Witness: L1 7605 (c1-c4).
RestoreGlintCells:
  PUSH BC
  PUSH HL
  LD A,L
  OR C
  LD L,A
  LD E,L
  LD A,H
  OR ScreenCopyHigh
  LD D,A
  PUSH HL
  PUSH DE
  EX DE,HL
  LD BC,$0003
  LDIR
  POP HL
  POP DE
  LD A,L
  XOR $1F
  LD L,A
  LD E,L
  LD C,$03
  LDDR
  POP HL
  POP BC
  RET

; Draw the glint's 3 cells (red, bright red, red) at the column and the mirror
; image
;
; Witness: L1 7605 (c1-c4).
DrawGlintRow:
  PUSH BC
  PUSH HL
  LD A,L
  OR C
  LD L,A
  PUSH HL
  CALL GlintRed
  INC HL
  CALL GlintBright
  INC HL
  CALL GlintRed
  POP HL
  LD A,L
  XOR $1F
  LD L,A
  CALL GlintRed
  DEC HL
  CALL GlintBright
  DEC HL
  CALL GlintRed
  POP HL
  POP BC
  RET

; (HL) = 2 (red ink) if HL's column is within the logo (6-25)
;
; Witness: L1 30420 (c1-c4).
GlintRed:
  LD A,L
  AND $1F
  CP $06
  RET C
  CP $1A
  RET NC
  LD (HL),GlintEdge
  RET

; (HL) = $42 (bright red) if HL's column is within the logo
;
; Witness: L1 15210 (c1-c4).
GlintBright:
  LD A,L
  AND $1F
  CP $06
  RET C
  CP $1A
  RET NC
  LD (HL),GlintCentre
  RET

; Print the logo upside down into ScreenCopy's bottom third and copy it to the
; screen
;
; FlipSprite $6E35 on each of the four logo sprites (they stay flipped),
; PrintSprite to $F066, $F06B, $F070, $F075 in ScreenCopy (the screen's
; $5066...), the logo's 5 attribute rows copied in reverse order to $FAE6
; upward, then ScreenCopy's bottom third ($F000, 2K) and its attribute rows
; 19-23 to the screen. DI around it.
;
; Witness: L1 4 (c1-c4).
DrawReflection:
  LD HL,Logo
  CALL FlipSprite
  LD HL,LogoPart2
  CALL FlipSprite
  LD HL,LogoPart3
  CALL FlipSprite
  LD HL,LogoPart4
  CALL FlipSprite
  DI
  LD DE,Logo
  LD HL,ScreenCopy+4198
  CALL PrintSprite
  LD DE,LogoPart2
  LD HL,ScreenCopy+4203
  CALL PrintSprite
  LD DE,LogoPart3
  LD HL,ScreenCopy+4208
  CALL PrintSprite
  LD DE,LogoPart4
  LD HL,ScreenCopy+4213
  CALL PrintSprite
  LD B,$05
  LD HL,ScreenCopy+6150
  LD DE,ScreenCopy+6886
ReflectAttrRow:
  PUSH BC
  LD BC,$0014
  LDIR
  LD C,$0C
  ADD HL,BC
  LD C,$34
  AND A
  EX DE,HL
  SBC HL,BC
  EX DE,HL
  POP BC
  DJNZ ReflectAttrRow
  LD HL,ScreenCopy+4096
  LD DE,Screen+4096
  LD BC,$0800
  LDIR
  LD HL,ScreenCopy+6752
  LD DE,Attributes+608
  LD C,$A0
  LDIR
  EI
  RET

; Turn the 40x40 sprite at HL upside down (RotateSprite twice: 180 degrees,
; then MirrorSprite)
;
; Witness: L1 16 (c1-c4).
FlipSprite:
  CALL RotateSprite
  CALL RotateSprite
  LD D,H
  LD E,L
  CALL MirrorSprite
  RET
