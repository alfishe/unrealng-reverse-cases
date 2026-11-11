; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The menu, the blits, the text printer and the HUD
; --------------------------------------------------------------------------------------------------------------------

; The menu: the frame, the logo, the texts, the control choice; 0 starts
;
; A frame of 16 x 16 blocks (MenuFrameTopEdge $BC02-$BD01) round the screen,
; the attributes $47, the border black, the two TUJAD logos (MenuLogo at $4064
; and $4078), the texts (MenuTexts: TUJAD, 1 KEYBOARD, 2 CURSOR JOYSTICK, 3
; KEMPSTON JOYSTICK, 0 START GAME; the copyright line after them is never
; printed). Then MenuPoll: Random, keys 1, 2 and 3 set Controls to $80, $40 or
; 0 and light their line (MenuLight*), 0 returns. L1 4 menus; MenuPoll 699 777
; loops in c1 and the menu builds.
Menu:
  LD HL,Screen
  LD DE,MenuFrameTopLeft
  CALL Blit16
  LD HL,Screen+2
  LD B,$0E
MenuFrameTop:
  PUSH BC
  LD DE,MenuFrameTopEdge
  PUSH HL
  CALL Blit16
  POP HL
  INC L
  INC L
  POP BC
  DJNZ MenuFrameTop
  LD HL,Screen+30
  LD DE,MenuFrameTopRight
  CALL Blit16
  LD HL,Screen+4288
  LD DE,MenuFrameBottomLeft
  CALL Blit16
  LD HL,Screen+4290
  LD B,$0E
MenuFrameBottom:
  PUSH BC
  LD DE,MenuFrameBottomEdge
  PUSH HL
  CALL Blit16
  POP HL
  INC L
  INC L
  POP BC
  DJNZ MenuFrameBottom
  LD HL,Screen+4318
  LD DE,MenuFrameBottomRight
  CALL Blit16
  LD HL,Screen+64
  LD B,$0A
MenuFrameLeft:
  PUSH BC
  LD DE,MenuFrameLeftEdge
  PUSH HL
  CALL Blit16
  POP HL
  LD A,L
  ADD A,$40
  LD L,A
  JR NC,MenuFrameLeftNext
  LD A,H
  ADD A,$08
  LD H,A
MenuFrameLeftNext:
  POP BC
  DJNZ MenuFrameLeft
  LD HL,Screen+94
  LD B,$0A
MenuFrameRight:
  PUSH BC
  LD DE,MenuFrameRightEdge
  PUSH HL
  CALL Blit16
  POP HL
  LD A,L
  ADD A,$40
  LD L,A
  JR NC,MenuFrameRightNext
  LD A,H
  ADD A,$08
  LD H,A
MenuFrameRightNext:
  POP BC
  DJNZ MenuFrameRight
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$47
  LDIR
  XOR A
  OUT ($FE),A
  LD HL,Screen+100
  LD (MenuLogoAt),HL
  CALL MenuLogo
  LD HL,Screen+120
  LD (MenuLogoAt),HL
  CALL MenuLogo
  LD HL,MenuTexts
  LD DE,Screen+205
  LD A,$47
  CALL PrintText
  LD HL,MenuTextKeyboard
  LD DE,Screen+2182
  LD A,$43
  CALL PrintText
  LD HL,MenuTextCursor
  LD DE,Screen+2246
  LD A,$45
  CALL PrintText
  LD HL,MenuTextKempston
  LD DE,Screen+4102
  LD A,$46
  CALL PrintText
  LD HL,MenuTextStart
  LD DE,Screen+4198
  LD A,$07
  CALL PrintText
  LD A,(Controls)
  BIT 7,A
  JR NZ,MenuLightKeyboard
  BIT 6,A
  JR NZ,MenuLightCursor
  JP MenuLightKempston
MenuPoll:
  CALL Random             ; Random stirred once a loop until 0 is pressed
  LD HL,Controls
  LD BC,$F7FE
  IN A,(C)
  BIT 0,A
  JR NZ,MenuPoll2
  LD (HL),$80
  JR MenuLightKeyboard
MenuPoll2:
  BIT 1,A
  JR NZ,MenuPoll3
  LD (HL),$40
  JR MenuLightCursor
MenuPoll3:
  BIT 2,A
  JR NZ,MenuPoll0
  LD (HL),$00
  JR MenuLightKempston
MenuPoll0:
  LD BC,$EFFE
  IN A,(C)
  BIT 0,A
  RET Z
  JR MenuPoll
MenuLightKeyboard:
  LD HL,Attributes+390
  LD DE,Attributes+391
  LD BC,$000B
  LD (HL),$C3
  LDIR
  LD HL,Attributes+454
  LD DE,Attributes+455
  LD BC,$0012
  LD (HL),$45
  LDIR
  LD HL,Attributes+518
  LD DE,Attributes+519
  LD BC,$0014
  LD (HL),$46
  LDIR
  JR MenuPoll
MenuLightCursor:
  LD HL,Attributes+390
  LD DE,Attributes+391
  LD BC,$000B
  LD (HL),$43
  LDIR
  LD HL,Attributes+454
  LD DE,Attributes+455
  LD BC,$0012
  LD (HL),$C5
  LDIR
  LD HL,Attributes+518
  LD DE,Attributes+519
  LD BC,$0014
  LD (HL),$46
  LDIR
  JP MenuPoll
MenuLightKempston:
  LD HL,Attributes+390
  LD DE,Attributes+391
  LD BC,$000B
  LD (HL),$43
  LDIR
  LD HL,Attributes+454
  LD DE,Attributes+455
  LD BC,$0012
  LD (HL),$45
  LDIR
  LD HL,Attributes+518
  LD DE,Attributes+519
  LD BC,$0014
  LD (HL),$C6
  LDIR
  JP MenuPoll

; The TUJAD logo at (MenuLogoAt): five 16-pixel blocks and its colours
;
; MenuLogoGraphic as three 16-row and two 8-row pieces, then MenuLogoAttrs (7
; rows of 4). L1 8 (two a menu).
MenuLogo:
  LD HL,(MenuLogoAt)
  INC HL
  LD DE,MenuLogoGraphic
  LD B,$10
  CALL Blit2
  LD HL,(MenuLogoAt)
  LD BC,$0060
  ADD HL,BC
  LD DE,MenuLogoGraphic
  LD B,$10
  CALL Blit2
  LD HL,(MenuLogoAt)
  LD BC,$0062
  ADD HL,BC
  LD DE,MenuLogoGraphic
  LD B,$10
  CALL Blit2
  LD HL,(MenuLogoAt)
  LD A,L
  ADD A,$C0
  LD L,A
  JR NC,MenuLogoLower
  LD A,H
  ADD A,$08
  LD H,A
MenuLogoLower:
  LD DE,MenuLogoLowerHalf
  LD B,$08
  CALL Blit2
  LD HL,(MenuLogoAt)
  LD A,L
  ADD A,$C2
  LD L,A
  JR NC,MenuLogoLowerRight
  LD A,H
  ADD A,$08
  LD H,A
MenuLogoLowerRight:
  LD DE,MenuLogoLowerHalf
  LD B,$08
  CALL Blit2
  LD HL,(MenuLogoAt)
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD DE,MenuLogoAttrs
  LD B,$07
MenuLogoAttrRow:
  PUSH BC
  LD B,$04
MenuLogoAttrCell:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  DJNZ MenuLogoAttrCell
  LD A,L
  ADD A,$1C
  LD L,A
  JR NC,MenuLogoAttrNext
  INC H
MenuLogoAttrNext:
  POP BC
  DJNZ MenuLogoAttrRow
  RET

; Copy B rows of 2 bytes from DE to the screen at HL
;
; L1 40.
Blit2:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC L
  INC H
  LD A,H
  AND $07
  JR NZ,Blit2Next
  LD A,L
  ADD A,$20
  LD L,A
  JR C,Blit2Next
  LD A,H
  SUB $08
  LD H,A
Blit2Next:
  DJNZ Blit2
  RET

; Copy an 8 x 8 character from DE to the screen at HL
;
; L1 1 758 (PrintBcd, PrintText, DrawHud, ShowWeapon).
Print8:
  PUSH HL
  LD B,$08
Print8Row:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  LD A,H
  AND $07
  JR NZ,Print8Next
  LD A,L
  ADD A,$20
  LD L,A
  JR C,Print8Next
  LD A,H
  SUB $08
  LD H,A
Print8Next:
  DJNZ Print8Row
  POP HL
  RET

; Copy a 16 x 16 block (32 bytes) from DE to the screen at HL
;
; L1 1 214 (the items, the HUD icons, the menu frame, the ED pieces).
Blit16:
  LD B,$10
Blit16Row:
  PUSH BC
  PUSH HL
  LD B,$02
Blit16Byte:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC L
  DJNZ Blit16Byte
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,Blit16Next
  LD A,L
  ADD A,$20
  LD L,A
  JR C,Blit16Next
  LD A,H
  SUB $08
  LD H,A
Blit16Next:
  POP BC
  DJNZ Blit16Row
  RET

; Print text at HL to the screen at DE in the colour A, up to '.'
;
; Font characters (Font - $100 + 8 x code: LD BC,Font - 256) through Print8,
; each cell's attribute PrintAttr. L1 21 texts, 302 characters.
PrintText:
  LD (PrintAttr),A
PrintTextLoop:
  PUSH HL
  PUSH DE
  LD BC,Font-256
  LD A,(HL)
  LD L,A
  LD H,$00
  SLA L
  RL H
  SLA L
  RL H
  SLA L
  RL H
  ADD HL,BC
  EX DE,HL
  CALL Print8
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD A,(PrintAttr)
  LD (HL),A
  POP DE
  POP HL
  INC HL
  INC E
  LD A,(HL)
  CP $2E
  RET Z
  JR PrintTextLoop

; The HUD: the frame of the top five rows, the dividers, the colours, the
; icons, the lives and the energy
;
; Corners, edges and the divider from HudGraphics, the attributes ($43, then
; HudAttrs on rows 1-4 at column 2, 7 at the edges), the icons of weapon 0, GEN
; 19 (the lives) and the energy, Lives at $4085 and Energy at $4088 (PrintBcd).
; L1 4 (NewGame).
DrawHud:
  LD DE,HudCornerTopLeft
  LD HL,Screen
  CALL Print8
  LD HL,Screen+31
  CALL Print8
  LD HL,Screen+191
  CALL Print8
  LD HL,Screen+160
  CALL Print8
  LD HL,Screen+1
  LD B,$1E
DrawHudTop:
  PUSH BC
  LD DE,HudGraphics
  CALL Print8
  INC L
  POP BC
  DJNZ DrawHudTop
  LD B,$1E
  LD HL,Screen+161
DrawHudBottom:
  PUSH BC
  LD DE,HudBottomEdge
  CALL Print8
  INC L
  POP BC
  DJNZ DrawHudBottom
  LD B,$04
  LD HL,Screen+32
DrawHudLeft:
  PUSH BC
  LD DE,HudLeftEdge
  CALL Print8
  LD A,L
  ADD A,$20
  LD L,A
  POP BC
  DJNZ DrawHudLeft
  LD HL,Screen+63
  LD B,$04
DrawHudRight:
  PUSH BC
  LD DE,HudRightEdge
  CALL Print8
  LD A,L
  ADD A,$20
  LD L,A
  POP BC
  DJNZ DrawHudRight
  LD HL,Screen+11
  LD DE,HudDividerTop
  LD B,$05
DrawHudDivider:
  PUSH BC
  CALL Print8
  LD DE,HudDivider
  LD A,L
  ADD A,$20
  LD L,A
  POP BC
  DJNZ DrawHudDivider
  LD DE,HudDividerBottom
  CALL Print8
  LD HL,Attributes+32
  LD DE,Attributes+33
  LD BC,$007F
  LD (HL),$43
  LDIR
  LD DE,Attributes+34
  LD B,$04
DrawHudAttrRow:
  PUSH BC
  PUSH DE
  LD HL,HudAttrs
  LD BC,$0008
  LDIR
  POP DE
  LD A,E
  ADD A,$20
  LD E,A
  JR NC,DrawHudAttrNext
  INC D
DrawHudAttrNext:
  POP BC
  DJNZ DrawHudAttrRow
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$001F
  LD (HL),$07
  LDIR
  LD HL,Attributes+160
  LD DE,Attributes+161
  LD BC,$001F
  LD (HL),$07
  LDIR
  LD DE,$0020
  LD HL,Attributes+32
  LD B,$04
DrawHudLeftAttr:
  LD (HL),$07
  ADD HL,DE
  DJNZ DrawHudLeftAttr
  LD HL,Attributes+43
  LD B,$04
DrawHudDividerAttr:
  LD (HL),$07
  ADD HL,DE
  DJNZ DrawHudDividerAttr
  LD HL,Attributes+63
  LD B,$04
DrawHudRightAttr:
  LD (HL),$07
  ADD HL,DE
  DJNZ DrawHudRightAttr
  LD HL,Screen+1058
  LD DE,HudIcons
  CALL Blit16
  LD HL,Screen+1061
  LD DE,IconGen19
  CALL Blit16
  LD HL,Screen+1064
  LD DE,IconEnergy
  CALL Blit16
  LD HL,Screen+133
  LD A,(Lives)
  CALL PrintBcd
  LD HL,Screen+136
  LD A,(Energy)
  CALL PrintBcd
  RET

; The attributes of the HUD's rows 1-4 from column 2: two cells $47, a gap, two
; $45, a gap, two $42
;
; DrawHud $8B79 copies them four times (L1 reads).
HudAttrs:
  DEFB $47,$47,$00,$45,$45,$00,$42,$42

; The HUD frame's characters: the top and bottom edges, the left and right
; edges, four corners, the divider
;
; DrawHud draws each with Print8. The editable form:
; src/res/graphics/HudGraphics.png.
HudGraphics:
  INCBIN "res/graphics/HudGraphics.bin",$0000,8
HudBottomEdge:
  INCBIN "res/graphics/HudGraphics.bin",$0008,8
HudLeftEdge:
  INCBIN "res/graphics/HudGraphics.bin",$0010,8
HudRightEdge:
  INCBIN "res/graphics/HudGraphics.bin",$0018,8
HudCornerTopLeft:
  INCBIN "res/graphics/HudGraphics.bin",$0020,8
HudCornerTopRight:
  INCBIN "res/graphics/HudGraphics.bin",$0028,8
HudCornerBottomRight:
  INCBIN "res/graphics/HudGraphics.bin",$0030,8
HudCornerBottomLeft:
  INCBIN "res/graphics/HudGraphics.bin",$0038,8
HudDividerTop:
  INCBIN "res/graphics/HudGraphics.bin",$0040,8
HudDivider:
  INCBIN "res/graphics/HudGraphics.bin",$0048,8
HudDividerBottom:
  INCBIN "res/graphics/HudGraphics.bin",$0050,8

; Seven 16 x 16 icons: weapons 0-3, GEN 19, the energy (HUD), the energy source
;
; ShowWeapon $79CB-$79EF and DrawItem $6E58 read the weapon icons ($8C55 + 32 x
; weapon); DrawItem $6E4A GEN 19 ($8CD5) and $6E51 the energy source ($8D15);
; DrawHud the GEN 19 and energy icons ($8CF5). The editable form:
; src/res/sprites/HudIcons.png.
HudIcons:
  INCBIN "res/sprites/HudIcons.bin",$0000,32
IconWeapon1:
  INCBIN "res/sprites/HudIcons.bin",$0020,32
IconWeapon2:
  INCBIN "res/sprites/HudIcons.bin",$0040,32
IconWeapon3:
  INCBIN "res/sprites/HudIcons.bin",$0060,32
IconGen19:
  INCBIN "res/sprites/HudIcons.bin",$0080,32
IconEnergy:
  INCBIN "res/sprites/HudIcons.bin",$00A0,32
IconEnergySource:
  INCBIN "res/sprites/HudIcons.bin",$00C0,32

; The screen address MenuLogo draws at
MenuLogoAt:
  DEFW $0000

; PrintText's colour
PrintAttr:
  DEFB $00

; The menu's texts, each ending in '.', and a copyright line never printed
;
; Menu $88F6-$8922 prints the five texts. $8D85 (a $7F, the copyright sign in
; the ROM font, then " 1986 ORPHEUS LTD") is read by no build: a leftover. The
; editable form: src/res/text/MenuTexts.txt.
MenuTexts:
  INCBIN "res/text/MenuTexts.bin",$0000,6
MenuTextKeyboard:
  INCBIN "res/text/MenuTexts.bin",$0006,13
MenuTextCursor:
  INCBIN "res/text/MenuTexts.bin",$0013,20
MenuTextKempston:
  INCBIN "res/text/MenuTexts.bin",$0027,22
MenuTextStart:
  INCBIN "res/text/MenuTexts.bin",$003D,16
CopyrightText:
  INCBIN "res/text/MenuTexts.bin",$004D,17

; The logo's colours: 7 rows of 4
MenuLogoAttrs:
  DEFB $00,$01,$01,$00
  DEFB $00,$11,$21,$00
  DEFB $00,$10,$20,$00
  DEFB $01,$11,$21,$01
  DEFB $11,$21,$11,$21
  DEFB $10,$20,$10,$20
  DEFB $02,$04,$02,$04

; The logo's block: 16 rows of 2 bytes (a diamond); the lower half is used
; alone
;
; MenuLogo $89E9 draws it three times as 16 rows and twice from $8DC2 as 8.
MenuLogoGraphic:
  INCBIN "res/graphics/MenuLogoGraphic.bin",$0000,16
MenuLogoLowerHalf:
  INCBIN "res/graphics/MenuLogoGraphic.bin",$0010,16
