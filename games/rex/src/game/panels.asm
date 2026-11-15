; --------------------------------------------------------------------------------------------------------------------
; panels.asm: The panels: the framed box, the attribute shadow
; --------------------------------------------------------------------------------------------------------------------

; Draw a framed box: A attribute, D width, E height, H column, L line, C the
; frame's colour; the frame from the font's edge characters
;
; Witness: L1 52 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
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
; Witness: L1 209 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
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
; Witness: L1 1672 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
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
; Witness: L1 4835 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30,
; rzx-p1- x32).
FillShadowRow3:
  CALL FillShadowCells
  CALL FillShadowCells
  CALL FillShadowCells
  RET

; One row of three cells
;
; Witness: L1 14505 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30,
; rzx-p1- x32).
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
; Witness: L1 603 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30, rzx-p1- x32).
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
; Witness: L1 1809 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30,
; rzx-p1- x32).
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
; Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000,
; rzx-p1-64000).
SaveAttrs:
  LD DE,TitleScreen
  LD HL,$5800
  LD BC,$0060
  LDIR
  RET

; The explosion's attribute flash: the object's 3 x 3 cells in the shadow
; coloured from FlashAttrs $BFE7 at random
;
; Witness: L1 4835 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30,
; rzx-p1- x32).
FlashCells:
  CALL BufferAddress
  LD DE,$0020
  ADD HL,DE
  LD (Temp1),HL
  LD DE,$5800
  AND A
  SBC HL,DE
  LD DE,TitleScreen
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

  ORG $D858

; IX = the first dead object record; none: IX = $03E8
;
; Witness: L1 169 (p1-code, p1-speedup, p1-room30, rzx-p1- x10).
FindFreeObject:
  LD IX,$5E66
  LD A,(ObjectCount)
  LD B,A
FindFreeLoop:
  LD A,(IX+$0C)
  OR A
  RET Z
  LD DE,$0018
  ADD IX,DE
  DJNZ FindFreeLoop
  LD IX,$03E8
  RET

; A weapon station's panel (HL: the flag then the text), once a game: the
; screen saved, the panel, wait for fire, the screen back
;
; Witness: L1 95 (rzx-p1- x8).
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
  CALL SoundSilence
  PUSH HL
  POP IX
  CALL SaveScreen
  LD B,A
  CALL PrintBoxed
  LD BC,$2710
  CALL Delay
  CALL WaitFireOrAttract
  CALL BufferToScreen
  CALL CopyAttrs
  CALL SoundReset
  POP BC
  POP IY
  POP IX
  RET

; The screen's play lines into the back buffer (the panels draw over the
; screen; BufferToScreen puts it back)
;
; Witness: L1 7 (p1-speedup, rzx-p1- x6).
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
; Witness: L1 1326 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-kempston, p1-room30, rzx-p1- x14).
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
; Witness: L1 140 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
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

; Leftover: $C1 $C9 (POP BC: RET, nothing calls it), then the animated cells'
; work space
UnusedD92E:
  DEFB $C1,$C9,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00
SceneryCellList:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; every
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; visible
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; scenery
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; cell of
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the room,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 4 bytes
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; each
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; (buffer
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; address,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; picture
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; address),
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; filled by
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; DrawRoom
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; and
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; redrawn
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; each pass
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; by
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; DrawAnimCells
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; (364 cells
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; in room 0:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; past entry
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00         ; 255 the
                                                                       ; one-byte
                                                                       ; index of
                                                                       ; CellIndexMap
                                                                       ; wraps)
