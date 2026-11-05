; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: Sprite builders and the per-row sprite strips of the objects
;
; The objects (16 of 44 bytes, $F36C-$F5FF, walked from $F600 down) are not drawn on their own: BuildObjectStrips cuts
; every visible object into one strip per character row and links the strips into the row records, and the renderer
; draws them with the scenery (StripDraw).
;
; The builders below prepare the sprite images the strips read: complemented 8-byte cells with blank cells between the
; columns, built at run time from the glyph data.
; --------------------------------------------------------------------------------------------------------------------

; Build a column-major sprite of C columns of B cells, complemented, with blank
; borders
;
; DE - 8 gets a blank (FillBlankCell), then per column B cells of 8 bytes
; copied from HL complemented (CPL), and a blank cell after every column; then
; B blank cells at the end.
;
; Input: HL = the source glyphs, DE = the destination, B = the cells a column,
; C = the columns. c2: 5 entries (frames 102-1274, from $ACD9), writing
; $E748-$E757 and $E760-$E76F from $64E0-$64FF and $65E0-$65FF.
BuildCellSprite:
  PUSH HL
  LD HL,-$0008
  ADD HL,DE
  EX DE,HL
  CALL FillBlankCell
  POP HL
CellSpriteColumn:
  PUSH BC
CellSpriteCell:
  PUSH BC
  LD B,$08
CellSpriteByte:
  LD A,(HL)
  CPL
  LD (DE),A
  INC HL
  INC DE
  DJNZ CellSpriteByte
  POP BC
  DJNZ CellSpriteCell
  CALL FillBlankCell
  POP BC
  DEC C
  JR NZ,CellSpriteColumn
CellSpriteTail:
  CALL FillBlankCell
  DJNZ CellSpriteTail

; Write a blank cell: eight $FF bytes at DE
;
; A and BC preserved. c2: 30 entries.
FillBlankCell:
  EX AF,AF'
  PUSH BC
  LD B,$08
  LD A,$FF
FillBlankByte:
  LD (DE),A
  INC DE
  DJNZ FillBlankByte
  POP BC
  EX AF,AF'
  RET

; Build a 7 x 9 cell image at $C000 from a one-bit cell map
;
; A = 1: the glyphs come from $66E0 (linear, INC HL) and the cell map from the
; 9 bytes at $8098; otherwise from the tile set at $5CDC (interleaved: INC H,
; then LD H,C; INC L after each glyph) and the map at $80A1. The step
; instructions are written into BigSpriteStep and BigSpriteNext.
;
; Each map bit (7 a byte, 9 bytes) set = the next glyph complemented
; (BigSpriteCell), clear = a blank cell. Called from $ACD9 when its A >= $14.
; Not entered in c1 or c2: probably the end-of-level guardian.
BuildBigSprite:
  LD DE,GlyphCache
  CALL FillBlankCell
  DEC A
  JR NZ,BigSpriteFromTiles
  LD HL,BigSpriteGlyphs
  EXX
  LD A,$23
  LD DE,$0000
  LD HL,BigSpriteMap1
  JR BigSpriteSetUp
BigSpriteFromTiles:
  LD HL,TileGraphics+$00DC
  EXX
  LD A,$24
  LD DE,$2C61
  LD HL,BigSpriteMap2
BigSpriteSetUp:
  LD (BigSpriteStep),A
  LD (BigSpriteNext),DE
  LD C,$09
BigSpriteRow:
  LD A,(HL)
  INC HL
  LD B,$07
BigSpriteBit:
  RLA
  EXX
  CALL NC,FillBlankCell
  CALL C,BigSpriteCell
  EXX
  DJNZ BigSpriteBit
  DEC C
  JR NZ,BigSpriteRow
  RET

; Copy one glyph complemented to DE
;
; Used by the routine at BuildBigSprite.
BigSpriteCell:
  EX AF,AF'
  LD B,$08
  LD C,H
BigSpriteByte:
  LD A,(HL)
  CPL
  LD (DE),A
BigSpriteStep:
  INC HL                  ; INC HL or INC H (written at $8F2F)
  INC DE
  DJNZ BigSpriteByte
BigSpriteNext:
  NOP                     ; NOP NOP or LD H,C; INC L (written at $8F32)
  NOP
  EX AF,AF'
  RET

; Rotate a column-major image one pixel right, the last bit wrapping to the
; first byte
;
; Input: HL = the image, C = its height in lines (also the column stride), B =
; its width in bytes. Each line is shifted right one pixel across its B bytes;
; the bit that falls out of the last byte goes into bit 7 of the first.
;
; Called from $AD44 (c2: 35 entries).
RotateSprite:
  LD E,C

; RotateSpriteRows
RotateSpriteRows:
  LD D,$00

; RotateLine
;
; Used by the routine at RotateLineCount.
RotateLine:
  PUSH BC

; RotateLineSave
RotateLineSave:
  PUSH HL

; RotateLineCarry
RotateLineCarry:
  XOR A                   ; the carry in: 0

; RotateByte
;
; Used by the routine at RotateNextByte.
RotateByte:
  RLA

; RotateByteShift
RotateByteShift:
  RR (HL)

; RotateByteOut
RotateByteOut:
  RRA
  ADD HL,DE

; RotateNextByte
RotateNextByte:
  DJNZ RotateByte

; RotateLineWrap
RotateLineWrap:
  POP HL                  ; the bit out of the last byte goes into the first

; RotateLineMerge
RotateLineMerge:
  OR (HL)

; RotateLineStore
RotateLineStore:
  LD (HL),A

; RotateLineNext
RotateLineNext:
  INC HL

; RotateLineRestore
RotateLineRestore:
  POP BC

; RotateLineCount
RotateLineCount:
  DEC C
  JR NZ,RotateLine
  RET

; Clear the sprite-strip count of the 18 row records
;
; 0 into +$15 of every record ($F141 + 32k). c2: 660 entries (from
; ObjectStrips).
ClearStripCounts:
  LD HL,RowRecords+$0015
  LD DE,$0020
  XOR A
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  RET

; Cut every active object into sprite strips
;
; ClearStripCounts, then the 16 objects from IY = $F600 down by 44 bytes: an
; active object (+8 bit 7) goes through BuildObjectStrips. One beeper toggle
; per object (ObjectBeep $7F82 XOR $18, AND the mask $7F83): the strip part of
; the explosion noise, silent while the mask is 0.
;
; Called from the frame handler cycle $AA96 (c2: 660 entries).
ObjectStrips:
  CALL ClearStripCounts
  LD IY,SightObject
  LD B,$10
ObjectStripsLoop:
  BIT 7,(IY+$08)
  JR Z,ObjectStripsNext
  PUSH BC
  CALL BuildObjectStrips
  POP BC
ObjectStripsNext:
  LD DE,-$002C
  ADD IY,DE
  LD HL,ObjectBeep
  LD A,(HL)
  XOR $18
  LD (HL),A
  INC HL
  AND (HL)
  OUT ($FE),A
  DJNZ ObjectStripsLoop
  RET

; Link the strips of the object IY into the row records
;
; The object's sprite definition (+0/+1) is a list of words read with POP: the
; base image, the frame stride (times the frame +2), a stride and mask for the
; sub-frame (+3 bits 5-7), the height and the line length. The rows are clipped
; against the playfield (+4 - 16, 32 rows); an object fully out has +8 bit 5
; cleared (BuildStripsOff), else it is set (visible).
;
; The column (+5 bits 5-7) moves the start; +6 gives the shift; +$25 the
; colour. The strip entries go onto the object's strip buffer (+9/+10, as a
; stack); +$0B is a bit mask of the rows the object covers: each set bit adds a
; strip to that row's list (+$15 count + 1, +$16/+$17 linked).
;
; Saves SP into BuildStripsDone. c2: 3327 entries, 46 per mille.
BuildObjectStrips:
  PUSH IY
  LD (BuildStripsDone+$0001),SP
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD SP,HL
  POP HL
  POP DE
  LD B,(IY+$02)
StripFrame:
  ADD HL,DE
  DJNZ StripFrame
  POP DE
  POP DE
  LD A,(IY+$03)
  RLCA
  RLCA
  RLCA
  POP BC
  AND B
  JR Z,StripClip
  LD B,A
StripSubFrame:
  ADD HL,DE
  DJNZ StripSubFrame
StripClip:
  LD A,(IY+$04)
  SUB $10
  POP DE
  LD C,D
  LD D,$00
  JP P,StripClipBottom
  NEG
  CP C
  JP NC,BuildStripsOff
  LD B,A
StripClipTop:
  ADD HL,DE
  DJNZ StripClipTop
  NEG
  ADD A,C
  LD C,A
  XOR A
  JR StripVisible
StripClipBottom:
  LD B,A
  ADD A,C
  SUB $20
  JR C,StripClipped
  CP C
  JP NC,BuildStripsOff
  NEG
  ADD A,C
  LD C,A
StripClipped:
  LD A,B
StripVisible:
  SET 5,(IY+$08)
  LD B,C
  LD D,E
  LD E,A
  LD A,(IY+$05)
  RLCA
  RLCA
  RLCA
  AND $07
  LD C,A
  LD A,L
  SUB C
  LD L,A
  JR NC,StripShift
  DEC H
StripShift:
  LD A,(IY+$06)
  LD C,A
  ADD A,$01
  AND $07
  RRCA
  RRCA
  RRCA
  OR E
  LD E,A
  LD A,C
  LD C,(IY+$25)
  EXX
  LD L,(IY+$09)
  LD H,(IY+$0A)
  LD SP,HL
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD DE,RowRecords+$0015
  ADD HL,DE
  EX AF,AF'
  LD A,(IY+$0B)
  LD BC,$001F
  AND A
  JR Z,BuildStripsDone
  JP M,StripFirstRow
StripSkipRow:
  POP IY
  LD SP,IY
  EXX
  ADD HL,DE
  EXX
  SLA A
  JP P,StripSkipRow
StripFirstRow:
  LD IY,$000C
  ADD IY,SP
  LD SP,IY
StripLinkRow:
  EX AF,AF'
  INC (HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  EXX
  PUSH DE
  PUSH BC
  PUSH HL
  LD A,E
  ADD A,$20
  LD E,A
  LD A,L
  ADD A,$08
  LD L,A
  JR NC,StripLinkNext
  INC H
StripLinkNext:
  EXX
  DEC SP
  DEC SP
  DEC HL
  EX AF,AF'
  SLA A
  JR NC,StripRowDone
  LD (StripListHead+$0002),HL
StripListHead:
  LD ($0000),SP           ; LD (n),SP: n = the row's list field (written at
                          ; $908E)
StripRowDone:
  ADD HL,BC
  DEC SP
  DEC SP
  POP IY
  LD SP,$000C
  ADD IY,SP
  LD SP,IY
  AND A
  JR NZ,StripLinkRow
BuildStripsDone:
  LD SP,$0000             ; LD SP,n: n = the caller's SP
  POP IY
  RET
BuildStripsOff:
  RES 5,(IY+$08)          ; the object is out of the playfield: not visible
  LD SP,(BuildStripsDone+$0001)
  POP IY
  RET
