; --------------------------------------------------------------------------------------------------------------------
; screen.asm: Screen addresses, icon drawing and clearing
;
; ScreenAddr and AttrAddr, the next pixel line, DrawIcon from IconTiles and IconAttrs, and the clears of the top
; third, the view area and the maps window.
; --------------------------------------------------------------------------------------------------------------------

; HL = the display file address of character row B (0-23), column C (0-31)
;
; No other register changes but A. L1 451 620: every print and drawing routine
; calls it.
ScreenAddr:
  LD A,B
ScreenAddrThird:
  AND $18                 ; the third: B AND $18 OR $40
ScreenAddrHigh:
  OR $40
ScreenAddrH:
  LD H,A
ScreenAddrRow:
  LD A,B                  ; the row in the third: (B AND 7) x 32
ScreenAddrRowBits:
  AND $07
ScreenAddrRot1:
  RRCA
ScreenAddrRot2:
  RRCA
ScreenAddrRot3:
  RRCA
ScreenAddrCol:
  OR C                    ; OR C
ScreenAddrL:
  LD L,A
  RET

; HL = the attribute address of row B, column C (C kept, B = $58)
;
; L1 1024 (the menu highlight HighlightLine $6933 and the graph windows).
AttrAddr:
  LD L,B
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD B,$58
  ADD HL,BC
  RET

; HL = the display file address one pixel line down
;
; The usual three cases: inside the character (INC H), into the next character
; row (L + 32, H - 8), into the next third (L + 32 with carry). L1 3 121 944.
NextPixelLine:
  INC H
  LD A,H
  AND $07
  RET NZ
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; Draw icon tile A (8 bytes at IconTiles + 8 A) at row B, column C, with its
; attribute from IconAttrs
;
; Sets PrintAddr to the cell, copies the eight bytes down the cell and the
; attribute IconAttrs + A ($F4F8 + A) through PutAttr $F774. Used for the tool
; palette, the box frames and the window graphics. L1 36 344.
DrawIcon:
  PUSH AF
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP AF
  LD L,A
  LD H,$00
  LD (TileIndex),HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,IconTiles
  ADD HL,BC
  EX DE,HL
  LD HL,(PrintAddr)
  LD B,$08
DrawIconLoop:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ DrawIconLoop
  EX DE,HL
  LD BC,(TileIndex)
  LD HL,IconAttrs
  ADD HL,BC
  LD A,(HL)
  EX DE,HL
  JP PutAttr

; Draw icon tile A at PrintAddr with the current PrintAttr (no position, no own
; attribute)
;
; Then JP PrintAttrHere $F76E (PrintAttr $FF leaves the attribute). L1 27 668
; (the box frames of DrawBoxRow).
DrawIconHere:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,IconTiles
  ADD HL,BC
  EX DE,HL
  LD HL,(PrintAddr)
  LD B,$08
DrawIconHereLoop:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ DrawIconHereLoop
  JP PrintGlyphAttr

; Clear the top third ($4000-$47FF) and give it attribute $38
;
; A = $38 (white paper, black ink) into $5800-$58FF. L1 40.
ClearTopBlack:
  LD A,$38
  JR ClearTopA

; Clear the top third with attribute $07 (black paper, white ink)
;
; L1 28.
ClearTopWhite:
  LD A,$07
; This entry point is used by the routine at ClearTopBlack.
ClearTopA:
  LD HL,Screen             ; the pixels zeroed, then the attributes A
  LD DE,Screen+1
  LD BC,$07FF
  LD (HL),$00
  LDIR
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$00FF
  LD (HL),A
  LDIR

; Clear the screen's rows 8-23 ($4800-$57FF), attribute $47 (bright white on
; black)
;
; The map view's area, cleared before a window or a dialog is drawn over it. L1
; 223.
ClearViewArea:
  LD HL,Screen+2048
  LD DE,Screen+2049
  LD BC,$0FFF
  LD (HL),$00
  LDIR
  LD HL,Attributes+256
  LD DE,Attributes+257
  LD BC,$01FF
  LD (HL),$47
  LDIR
  RET

; Clear the top third black on white, then every attribute row: 8 columns $07,
; 24 columns $21
;
; Called by the maps window ($7A9E) before it draws a map: the left 8 columns
; keep a black key, the 24 on the right are blue on red ($21). L1 5.
ClearForMaps:
  CALL ClearTopBlack
  LD HL,Attributes
  LD D,$18
MapsAttrRow:
  LD B,$08
MapsAttrKey:
  LD (HL),$07
  INC HL
  DJNZ MapsAttrKey
  LD B,$18
MapsAttrMap:
  LD (HL),$21
  INC HL
  DJNZ MapsAttrMap
  DEC D
  JR NZ,MapsAttrRow
  RET
