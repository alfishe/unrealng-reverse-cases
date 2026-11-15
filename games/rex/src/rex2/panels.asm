; --------------------------------------------------------------------------------------------------------------------
; panels.asm: The panels: the framed box, the attribute shadow
; --------------------------------------------------------------------------------------------------------------------

  ORG $BADC

; Draw a framed box: A attribute, D width, E height, H column, L line, C the
; frame's colour; the frame from the font's edge characters
;
; As REX 1's PanelBox $CE7B (src/game/panels.asm).
;
; Witness: L1 17 (c2, rzx-p2-00000, rzx-p2-40000).
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
; Witness: L1 79 (c2, rzx-p2-00000, rzx-p2-40000).
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
; Witness: L1 632 (c2, rzx-p2-00000, rzx-p2-40000).
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
; Witness: L1 2038 (c2, p2-room20, rzx-p2- x20).
FillShadowRow3:
  CALL InkRow3White
  CALL InkRow3White
  CALL InkRow3White
  RET

; Three cells: those whose shadow attribute is $47 or $0F take ink C (paper
; kept)
;
; Witness: L1 6114 (c2, p2-room20, rzx-p2- x20).
InkRow3White:
  LD A,(DE)
  CP $47
  JP Z,InkWhite1
  CP $0F
  JP NZ,InkNext1
InkWhite1:
  LD A,(HL)               ; white: ink C
  AND $38
  OR C
  LD (HL),A
InkNext1:
  INC HL                  ; the next cell
  INC DE
  LD A,(DE)
  CP $47
  JP Z,InkWhite2
  CP $0F
  JP NZ,InkNext2
InkWhite2:
  LD A,(HL)               ; white: ink C
  AND $38
  OR C
  LD (HL),A
InkNext2:
  INC HL                  ; the next cell
  INC DE
  LD A,(DE)
  CP $47
  JP Z,InkWhite3
  CP $0F
  JP NZ,InkRowEnd
InkWhite3:
  LD A,(HL)               ; white: ink C
  AND $38
  OR C
  LD (HL),A
InkRowEnd:
  PUSH DE                 ; HL and DE one row on
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
; Witness: L1 386 (c2, p2-room20, rzx-p2- x21).
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
; Witness: L1 1158 (c2, p2-room20, rzx-p2- x21).
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
; Witness: L1 5 (c2, rzx-p2-00000).
SaveAttrs:
  LD DE,TitleScreen
  LD HL,$5800
  LD BC,$0060
  LDIR
  RET

; The 3 x 3 cells under SpriteX/SpriteY: the white ones take a random ink of
; PieceInks $C2DF
;
; Witness: L1 2038 (c2, p2-room20, rzx-p2- x20).
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
  LD HL,PieceInks
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD HL,(Temp1)
  LD DE,(Temp2)
  CALL FillShadowRow3
  RET

  ORG $D609

; A weapon station's panel (HL: the flag then the text), once a game: the
; screen saved, the panel, wait for fire, the screen back
;
; As REX 1's WeaponPanel $D871 (src/game/panels.asm).
;
; Known only from the code: REX 2 has no weapon station (GiveDoubleFire $A8F6).
;
; Witness: L1 0 ().
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
; As REX 1's SaveScreen $D8A3 (src/game/panels.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
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
; Witness: L1 43 (c2, rzx-p2-00000, rzx-p2-28000).
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
; Witness: L1 44 (c2, rzx-p2-00000, rzx-p2-40000).
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

; Leftover: POP BC: RET, the routine the development link calls ($62BD)
DebugHook:
  DEFB $C1,$C9
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
AnimCellList:
  DEFB $00,$00            ; the room's animated cells: 4 bytes each (cell,
  DEFB $00,$00            ; character, picture pointer), filled by DrawRoom
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
