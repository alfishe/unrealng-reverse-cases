; --------------------------------------------------------------------------------------------------------------------
; panels.asm: The panels: the framed box, the attribute shadow, the weapon panels
; --------------------------------------------------------------------------------------------------------------------

; Draw a framed box: A attribute, D width, E height, H column, L line, C the
; frame's colour; the frame from the font's edge characters
;
; As REX 1's PanelBox $CE7B (src/game/panels.asm).
;
; Witness: L1 43 (d1, demo-cycle).
PanelBox:
  PUSH IX
  LD (Temp1),A
  LD A,D
  LD (BoxWidth),A
  LD A,E
  LD (BoxHeight),A
  LD A,H
  LD (BoxX),A
  LD A,L
  LD (BoxY),A
  LD A,C
  LD (BoxAttr),A
  LD A,(BoxY)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(BoxX)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,$5802
  ADD HL,DE
  PUSH HL
  LD A,(BoxHeight)
  ADD A,$02
  LD B,A
  LD A,(BoxWidth)
  ADD A,$02
  LD E,A
  LD A,(Temp1)
  CALL FillAttrs
  POP HL
  LD DE,$0021
  ADD HL,DE
  LD A,(BoxHeight)
  LD B,A
  LD A,(BoxWidth)
  LD E,A
  LD A,(BoxAttr)
  CALL FillAttrs
  LD A,(BoxY)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,ScreenLineTable
  ADD HL,DE
  LD IX,Font+$0040
  LD IY,Font+$0060
  CALL PanelRow
  LD A,(BoxHeight)
  LD B,A
PanelBoxRow:
  PUSH BC                 ; each row of the box
  LD IX,Font+$00D8
  LD IY,Font+$00E8
  CALL PanelRow
  POP BC
  DJNZ PanelBoxRow
  LD IX,Font+$0050
  LD IY,Font+$0078
  CALL PanelRow
  POP IX
  RET

; 8 lines of a box row
;
; As REX 1's PanelRow $CF0A (src/game/panels.asm).
;
; Witness: L1 249 (d1, demo-cycle).
PanelRow:
  LD B,$08
PanelRowLine:
  LD E,(HL)               ; each pixel line
  INC HL
  LD D,(HL)
  INC DE
  INC DE
  PUSH HL
  LD A,(BoxX)
  LD L,A
  LD H,$00
  ADD HL,DE
  EX DE,HL
  POP HL
  CALL PanelLine
  DJNZ PanelRowLine
  RET

; One pixel line: the left edge, the middle B times, the right edge
;
; As REX 1's PanelLine $CF21 (src/game/panels.asm).
;
; Witness: L1 1992 (d1, demo-cycle).
PanelLine:
  PUSH BC
  LD A,(IX+$00)
  LD (DE),A
  INC DE
  LD A,(BoxWidth)
  LD B,A
PanelLineMiddle:
  LD A,(IY+$00)
  LD (DE),A
  INC DE
  DJNZ PanelLineMiddle
  LD A,(IX+$08)
  LD (DE),A
  INC IY
  INC IX
  INC HL
  POP BC
  RET

; Three rows of three: the cells of value $47 (white) take C
;
; As REX 1's FillShadowRow3 $CF3D (src/game/panels.asm).
;
; Witness: L1 504 (d1, demo-cycle).
FillShadowRow3:
  CALL FillShadowCells
  CALL FillShadowCells
  CALL FillShadowCells
  RET

; One row of three cells
;
; As REX 1's FillShadowCells $CF47 (src/game/panels.asm).
;
; Witness: L1 1512 (d1, demo-cycle).
FillShadowCells:
  LD A,(DE)
  CP $47
  JP NZ,ShadowCell2
  LD (HL),C
ShadowCell2:
  INC HL
  INC DE
  LD A,(DE)
  CP $47
  JP NZ,ShadowCell3
  LD (HL),C
ShadowCell3:
  INC HL
  INC DE
  LD A,(DE)
  CP $47
  JP NZ,ShadowRowEnd
  LD (HL),C
ShadowRowEnd:
  PUSH DE
  LD DE,$001E
  ADD HL,DE
  POP DE
  PUSH HL
  LD HL,$001E
  ADD HL,DE
  EX DE,HL
  POP HL
  RET

; Copy a 3 x 3 patch from DE to HL (the shadow's 32-byte rows)
;
; As REX 1's CopyCells3 $CF6E (src/game/panels.asm).
;
; Witness: L1 63 (d1, demo-cycle).
CopyCells3:
  CALL CopyCells
  LD BC,$001E
  ADD HL,BC
  CALL CopyCells
  ADD HL,BC
  CALL CopyCells
  RET

; One row of three
;
; As REX 1's CopyCells $CF7D (src/game/panels.asm).
;
; Witness: L1 189 (d1, demo-cycle).
CopyCells:
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  LD A,(DE)
  LD (HL),A
  PUSH HL
  LD HL,$001E
  ADD HL,DE
  EX DE,HL
  POP HL
  RET

; The screen's top 96 attributes ($5800) into the shadow at $E4FF
;
; As REX 1's SaveAttrs $CF8F (src/game/panels.asm).
;
; Witness: L1 7 (d1, demo-cycle).
SaveAttrs:
  LD DE,AttrShadow
  LD HL,$5800
  LD BC,$0060
  LDIR
  RET

; The explosion's attribute flash: the object's 3 x 3 cells in the shadow
; coloured from FlashAttrs $C6FB at random
;
; As REX 1's FlashCells $CF9B (src/game/panels.asm).
;
; Witness: L1 504 (d1, demo-cycle).
FlashCells:
  CALL BufferAddress
  LD DE,$0020
  ADD HL,DE
  LD (Temp1),HL
  LD DE,$5800
  AND A
  SBC HL,DE
  LD DE,AttrShadow
  ADD HL,DE
  EX DE,HL
  LD (Temp2),DE
  LD A,R
  AND $07
  LD E,A
  LD D,$00
  LD HL,FlashAttrs
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD HL,(Temp1)
  LD DE,(Temp2)
  CALL FillShadowRow3
  RET

  ORG $DA75

; A weapon station's panel (HL: the flag then the text), once a game: the
; screen saved, the panel, wait for fire, the screen back
;
; As REX 1's WeaponPanel $D871 (src/game/panels.asm).
;
; Witness: L1 244 (d1, demo-cycle).
WeaponPanel:
  LD A,(HL)
  OR A
  RET NZ
  LD (HL),$FF
  INC HL
  LD A,(HL)
  INC HL
  PUSH IX
  PUSH IY
  PUSH BC
  PUSH HL
  POP IX
  CALL SaveScreen
  LD B,A
  CALL PrintBoxed
  LD BC,60000
  CALL Delay
  CALL WaitQuiet
  CALL BufferToScreen
  CALL CopyAttrs
  POP BC
  POP IY
  POP IX
  RET

; The screen's play lines into the back buffer (the panels draw over the
; screen; BufferToScreen puts it back)
;
; As REX 1's SaveScreen $D8A3 (src/game/panels.asm).
;
; Witness: L1 33 (d1, demo-cycle).
SaveScreen:
  LD IY,ScreenLines
  LD B,$A8
  LD DE,BufferPlayOrigin
SaveScreenLine:
  PUSH BC
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD BC,$0020
  LDIR
  INC IY
  INC IY
  POP BC
  DJNZ SaveScreenLine
  RET

; Draw a picture straight on the screen from the 6 bytes after the CALL:
; picture word, column, line, width, height; returns after them
;
; As REX 1's DrawCharBlock $D8C0 (src/game/panels.asm).
;
; Witness: L1 1393 (d1, demo-cycle).
DrawCharBlock:
  LD (Temp1),IX
  LD (Temp2),IY
  POP IY
  LD L,(IY+$03)
  LD H,$00
  ADD HL,HL
  LD DE,ScreenLineTable
  ADD HL,DE
  PUSH HL
  POP IX
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD B,(IY+$05)
CharBlockRow:
  PUSH BC
  LD A,(IX+$00)
  LD D,(IX+$01)
  ADD A,(IY+$02)
  LD E,A
  LD C,(IY+$04)
  LD B,$00
  LDIR
  INC IX
  INC IX
  POP BC
  DJNZ CharBlockRow
  LD DE,$0006
  ADD IY,DE
  PUSH IY
  LD IY,(Temp2)
  LD IX,(Temp1)
  RET

; Fill B rows of E attributes from HL with A
;
; As REX 1's FillAttrs $D909 (src/game/panels.asm).
;
; Witness: L1 124 (d1, demo-cycle).
FillAttrs:
  PUSH AF
  PUSH DE
  PUSH BC
  PUSH HL
  LD (Temp1),A
  LD A,E
  LD (Temp2),A
FillAttrsRow:
  PUSH BC
  PUSH HL
  LD A,(Temp2)
  LD B,A
  LD A,(Temp1)
FillAttrsCell:
  LD (HL),A
  INC HL
  DJNZ FillAttrsCell
  POP HL
  LD DE,$0020
  ADD HL,DE
  POP BC
  DJNZ FillAttrsRow
  POP HL
  POP BC
  POP DE
  POP AF
  RET

; Leftover: the column that centres the text record at IX ((32 - length) / 2
; into IX+1); nothing calls it
;
; Witness: L1 0 ().
CentreText:
  PUSH IX
  LD DE,$0003
  ADD IX,DE
  LD L,$00
l_DB35:
  LD A,(IX+$00)
  OR A
  JR Z,l_DB40
  INC IX
  INC L
  JR l_DB35
l_DB40:
  LD A,$20
  SUB L
  SRL A
  POP IX
  LD (IX+$01),A
  RET

; Leftover: POP BC: RET, the return address of the development link's command
; $B5 ($62BE); nothing in the demo reaches it
;
; Witness: L1 0 ().
DevLinkReturn:
  POP BC
  RET

; The work space up to the tape's end $FFF9: zero on the tape but for one byte
; at $DCBA, the machine stack's remains at $FF25-$FF57 and the ROM's default
; user graphics A-U at $FF58 (the 48K UDG area, saved with the block); the game
; overwrites it all
WorkSpace:
  INCBIN "res/leftovers/demo-workspace.bin",$0000,169
SceneryCellList:
  ; $DBF6 every visible scenery cell of the room, 4 bytes each (buffer
  ;   address, picture address), filled by DrawRoomCell and redrawn each
  ;   pass by DrawAnimCells
  INCBIN "res/leftovers/demo-workspace.bin",$00A9,681
CellIndexMap:
  ; $DE9F each grid cell's index into SceneryCellList (DrawRoom,
  ;   DrawRoomCell, BulletHitsCell)
  INCBIN "res/leftovers/demo-workspace.bin",$0352,768
RoomGrid:
  ; $E19F the room grid's origin: the cell under (x, y) at $E19F + 32 x (y
  ;   / 8) + x / 8
  INCBIN "res/leftovers/demo-workspace.bin",$0652,96
RoomGridPlay:
  ; $E1FF the grid's first play row (line 24)
  INCBIN "res/leftovers/demo-workspace.bin",$06B2,768
AttrShadow:
  ; $E4FF the attribute shadow ($E4FF-$E7FE): FadeStep, SaveAttrs,
  ;   FlashCells
  INCBIN "res/leftovers/demo-workspace.bin",$09B2,20
ShieldAttrs:
  ; $E513 the shield figure's attributes in the shadow
  INCBIN "res/leftovers/demo-workspace.bin",$09C6,3
HeatAttr:
  ; $E516 HeatColour's cell in the shadow (ShowHeat)
  INCBIN "res/leftovers/demo-workspace.bin",$09C9,21
SweepAttrs:
  ; $E52B the HUD sweep's row in the shadow
  INCBIN "res/leftovers/demo-workspace.bin",$09DE,52
AttrShadowPlay:
  ; $E55F the shadow's play rows (CopyAttrs puts them at $5860)
  INCBIN "res/leftovers/demo-workspace.bin",$0A12,672
ShotBufferOrigin:
  ; $E7FF the back buffer's origin for a bullet: $E7FF + 32 x y + x / 8
  INCBIN "res/leftovers/demo-workspace.bin",$0CB2,160
SparkleBufferOrigin:
  ; $E89F the sparkle's origin
  INCBIN "res/leftovers/demo-workspace.bin",$0D52,96
SpriteBufferOrigin:
  ; $E8FF DrawSprite's origin
  INCBIN "res/leftovers/demo-workspace.bin",$0DB2,256
ObjectBufferOrigin:
  ; $E9FF the objects' origin (the kill flash's start, MainLoop and
  ;   ShowPoints)
  INCBIN "res/leftovers/demo-workspace.bin",$0EB2,256
BufferPlayOrigin:
  ; $EAFF the play lines' origin (one byte before the buffer)
  INCBIN "res/leftovers/demo-workspace.bin",$0FB2,1
BackBuffer:
  ; $EB00 the back buffer's play lines, 32 bytes a line, to $FFFF
  INCBIN "res/leftovers/demo-workspace.bin",$0FB3,5370
