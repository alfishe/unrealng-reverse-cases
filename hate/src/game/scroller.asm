; Copy the 32 strips of the playfield to the screen
;
; SP walks the address list BlitAddresses ($D5B2): every POP is the screen
; address of a cell's bottom line, and up to 8 lines are written upward from it
; (LD A,(DE); LD (HL),A; INC E; DEC H). DE starts at page $80 + $C32E, byte
; $C32F (the half), and moves 2 pages a column, wrapping in $80-$BF. Even
; columns take 17 POPs, the first and last writing 4 lines; odd columns 16 POPs
; of 8 lines. Clip entries point at $0800 in the ROM. Then the sprite lists
; ($DD6C), and falls into ScrollStep (docs/06-rendering.md 6.3).
Blit:
  LD (SavedStack),SP      ; SP kept in $C331
  LD SP,BlitAddresses     ; SP walks the address list
  LD D,$80                ; DE = page $80 + $C32E, byte $C32F
  LD A,(ScrollHalf)
  LD L,A
  RES 0,A
  LD E,A
  LD A,(ScrollPage)
  ADD A,D
  RES 7,L
  ADD A,L
  LD D,A
  LD C,$10                ; 16 column pairs
BlitEvenColumn:
  POP HL                  ; an even column: the first cell, 4 lines
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  LD B,$0F                ; 15 full cells
l_D38A:
  POP HL
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DJNZ l_D38A
  POP HL                  ; the last cell, 4 lines
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC D                   ; 2 pages on, wrapping in $80-$BF
  INC D
  RES 6,D
  LD A,(ScrollHalf)       ; the same half
  LD E,A
  LD B,$10                ; an odd column: 16 full cells
BlitOddColumn:
  POP HL                  ; one cell, 8 lines up
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DEC H
  LD A,(DE)
  LD (HL),A
  INC E
  DJNZ BlitOddColumn
  INC D                   ; 2 pages on, wrapping in $80-$BF
  INC D
  RES 6,D
  LD A,(ScrollHalf)
  LD E,A
  DEC C                   ; the next column pair
  JR NZ,BlitEvenColumn
  LD SP,(SavedStack)      ; SP back
  CALL RestoreUnderSprites ; the sprite lists; then on into the scroll step

; One scroll step: toggle the half, make one strip
;
; Called 128 times by the round start's pre-roll and entered once a pass from
; Blit. The scroll distance $D14D grows by 2, the half $C32F toggles and the
; page offset $C32E (0-63) counts up when the half goes back to 0. Each of the
; four states makes one strip (docs/06-rendering.md 6.4): half 0, offset even:
; FreshStrip ($D51D); half $80, even: StripPhase4 ($D413); half 0, odd:
; StripPhase2 ($D45B); half $80, odd: the course check ($D49C).
ScrollStep:
  LD HL,(ScrollDistance)  ; the scroll distance + 2
  INC HL
  INC HL
  LD (ScrollDistance),HL
  LD A,(ScrollHalf)       ; half $80:
  AND A
  JR Z,l_D44E
  XOR A                   ; back to half 0
  LD (ScrollHalf),A
  LD A,(ScrollPage)
  BIT 0,A                 ; odd offset: the course check
  JP NZ,CourseCheck

; Make the 4-pixel phase in page H - 1, half 0
;
; H is the page of the last fresh strip ($C3FC). Steps the page offset $C32E.
; Copies H's half 0 two lines up into page H - 1, half 0 (the two lines below
; cleared), then shifts it 4 pixels right with RRD, taking the nibble entering
; from H - 2's half 0 at line 2. The last byte is 0 (docs/06-rendering.md 6.4).
StripPhase4:
  LD A,(ScrollPage)       ; the page offset + 1, mod 64
  INC A
  AND $3F
  LD (ScrollPage),A
  LD HL,(FreshStripPage)  ; H = the page of the last fresh strip
  LD D,H                  ; DE = page H - 1, half 0, wrapping in $80-$BF
  DEC D
  SET 7,D
  RES 6,D
  LD E,$00
  LD L,E
  PUSH DE
  XOR A                   ; lines 0 and 1 clear
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD BC,$007E             ; H's half 0, two lines up
  LDIR
  POP HL                  ; HL = page H - 1, half 0
  LD D,H                  ; DE = page H - 2, line 2
  DEC D
  SET 7,D
  RES 6,D
  LD E,$02
  LD L,$00
  LD B,$7E
l_D440:
  LD A,(DE)               ; 4 pixels right, the nibble from H - 2 coming in
  RRD
  INC E
  INC L
  DJNZ l_D440
  XOR A                   ; the last two lines: nothing comes in
  RRD
  INC L
  LD (HL),$00
  RET
; This entry point is used by the routine at ScrollStep.
l_D44E:
  LD A,$80                ; half 0: to half $80
  LD (ScrollHalf),A
  LD A,(ScrollPage)
  BIT 0,A                 ; even offset: a fresh strip
  JP Z,FreshStrip

; Make the 2-pixel phase in page H - 1, half $80
;
; Copies H's half 0 one line up into page H - 1, half $80 (line 0 cleared),
; then shifts it 2 pixels right, the 2 bits entering from H - 2's half 0 at
; line 3. The last bytes shift with nothing coming in (docs/06-rendering.md
; 6.4).
StripPhase2:
  LD HL,(FreshStripPage)  ; H = the page of the last fresh strip
  LD D,H                  ; DE = page H - 1, half $80
  DEC D
  SET 7,D
  RES 6,D
  LD E,$80
  LD L,$00
  PUSH DE
  XOR A                   ; line 0 clear
  LD (DE),A
  INC E
  LD BC,$007F             ; H's half 0, one line up
  LDIR
  POP HL                  ; HL = page H - 1, half $80
  LD D,H                  ; DE = page H - 2, line 3
  DEC D
  SET 7,D
  RES 6,D
  LD E,$03
  LD L,$80
  LD B,$7D
l_D47E:
  LD A,(DE)               ; 2 pixels right, 2 bits from H - 2 coming in
  LD C,(HL)
  RRA
  RR C
  RRA
  RR C
  LD (HL),C
  INC E
  INC L
  DJNZ l_D47E
  LD A,(HL)               ; the last lines: nothing comes in
  SRL A
  SRL A
  LD (HL),A
  INC L
  LD A,(HL)
  SRL A
  SRL A
  LD (HL),A
  INC L
  LD (HL),$00
  RET
; This entry point is used by the routine at ScrollStep.
CourseCheck:
  LD A,(ScrollPage)       ; the page offset + 1, mod 64
  INC A
  AND $3F
  LD (ScrollPage),A
  LD HL,(CourseRowPtr)    ; the high byte of the row 15 ahead
  LD BC,$001F
  ADD HL,BC
  LD A,(HL)
  CP $FF                  ; $FF: the course has run out
  JR Z,CourseEnd
  LD HL,(StripCount)      ; strips drawn this course + 1
  INC HL
  LD (StripCount),HL
  LD A,H
  AND A
  RET NZ
  LD A,L                  ; the 32nd strip:
  CP $20
  RET NZ
  CALL RoundSetup         ; set up the round
  JP BuildGroundProfile   ; build the ground profile; returns to ScrollStep's
                          ; caller
CourseEnd:
  LD A,(DemoFlag)         ; the end of a course: the demo?
  AND A
  JR Z,NextCourse
  POP HL                  ; the demo: drop the return address, back to the menu
  JP MainLoop
NextCourse:
  LD HL,(CourseRecord)    ; otherwise the next course record, expanded
  LD BC,$0004
  ADD HL,BC
  LD (CourseRecord),HL

; Expand a course record into RowList
;
; HL = a course record (CourseRecords). At $FFFF wraps to $CF04 and sets
; CourseRecord. Each course byte b after the type selects the row list $C8EA +
; 2 x b (SegmentRows), copied word by word into RowList $CA43 until a word with
; a zero high byte. Then the next row $C3F8 = $CA43 and the strip count $C3FA =
; 0 (docs/06-rendering.md 6.5).
CourseExpand:
  LD E,(HL)               ; DE = the course data
  INC HL
  LD A,(HL)
  CP $FF                  ; $FFFF ends the table:
  JR NZ,l_D4E9
  LD HL,CourseTable       ; back to the record of round 1
  LD (CourseRecord),HL
  LD E,(HL)
  INC HL
  LD A,(HL)
l_D4E9:
  LD D,A
  INC DE                  ; skip the player's type
  LD BC,RowList           ; BC = RowList
CourseSegment:
  LD A,(DE)               ; the next course byte; $FF ends the course
  CP $FF
  JR Z,l_D510
  PUSH DE
  LD L,A                  ; its rows at $C8EA + 2 x b
  LD H,$00
  ADD HL,HL
  LD DE,SegmentRows
  ADD HL,DE
CopyRow:
  LD A,(HL)               ; the next row
  EX AF,AF'
  INC HL
  LD A,(HL)
  AND A                   ; a zero high byte ends the list
  JR Z,l_D50C
  EX AF,AF'
  LD (BC),A               ; the row into RowList
  EX AF,AF'
  INC BC
  LD (BC),A
  INC HL
  INC BC
  JR CopyRow
l_D50C:
  POP DE
  INC DE
  JR CourseSegment
l_D510:
  LD HL,RowList           ; the next row to draw: the first
  LD (CourseRowPtr),HL
  LD HL,$0000             ; no strips drawn yet
  LD (StripCount),HL
  RET

; Make a fresh strip from tiles, and the phase 2 pixels left of it
;
; Half 0, even offset. The new strip is page $80 + $C32E, half 0: 8 lines of
; the edge tile (EdgeTiles), then 15 tiles, tile i read from row i at offset i,
; rows popped from $C3F8 on; $C3F8 moves one row on. The page is kept in $C3FC.
; The tail makes page H - 2, half $80: H - 2's half 0 at line 1 shifted 2
; pixels left, the 2 bits entering from H copied in at line 3
; (docs/06-rendering.md 6.4, 6.5).
FreshStrip:
  LD HL,TitlePlayer       ; the new strip: page $80 + $C32E, half 0
  LD A,(ScrollPage)
  ADD A,H
  LD H,A
  PUSH HL
  EX DE,HL
  LD HL,EdgeTiles         ; the edge tile 23
  LD A,(ScrollPage)       ; ...or 24 for one strip in four
  SRL A
  INC A
  AND $03
  JR NZ,l_D536
  LD L,$C0
l_D536:
  LDI                     ; 8 lines of edge
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD (SavedStack),SP      ; SP kept in $C331
  LD HL,(CourseRowPtr)    ; SP walks the rows from $C3F8
  LD SP,HL
  INC HL                  ; the next strip starts one row on
  INC HL
  LD (CourseRowPtr),HL
  XOR A                   ; tile i = 0
FreshTile:
  LD B,$00                ; row i at offset i
  LD C,A
  EX AF,AF'
  POP HL
  ADD HL,BC
  LD A,(HL)               ; the tile number
  ADD A,A                 ; HL = $C400 + 8 x tile
  LD L,A
  LD H,B
  ADD HL,HL
  ADD HL,HL
  LD BC,Tiles
  ADD HL,BC
  LDI                     ; 8 lines of the tile
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  EX AF,AF'               ; the next tile, 15 in all
  INC A
  CP $0F
  JR C,FreshTile
  LD SP,(SavedStack)      ; SP back
  POP HL                  ; the page of the fresh strip
  LD (FreshStripPage),HL
  LD D,H                  ; DE = page H - 2, half $80
  DEC D
  DEC D
  SET 7,D
  RES 6,D
  LD E,$80
  LD L,$00
  PUSH DE
  XOR A                   ; lines 0-2 clear
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD BC,$007D             ; H's half 0, three lines up
  LDIR
  POP HL                  ; HL = page H - 2, half $80
  LD D,H                  ; DE = page H - 2, line 1
  LD E,$01
  LD L,$80
  LD B,$7F
l_D5A2:
  LD A,(DE)               ; 2 pixels left, 2 bits from H coming in
  LD C,(HL)
  RL C
  RLA
  RL C
  RLA
  LD (HL),A
  INC E
  INC L
  DJNZ l_D5A2
  LD (HL),$00             ; the last line clear
  RET

; Blit addresses, column 0 (17 cells)
;
; 528 screen addresses, the bottom line of a character cell each, popped by
; Blit: 17 for each even column, 16 for each odd one, from the bottom of the
; screen up. Even columns sit 4 lines off the odd ones; the list carries the
; 2:1 isometric skew and the clipping, 43 entries $0800 pointing into the ROM
; (docs/06-rendering.md 6.3). PaintAttributes uses the same list to colour the
; playfield's cells. Split here by column.
BlitAddresses:
  DEFW $0800,$0800,$0800,$0800,$0800,$57E0,$57C0,$57A0,$5780
  DEFW $5760,$5740,$5720,$5700,$4FE0,$4FC0,$4FA0,$4F80

; Blit addresses, column 1 (16 cells)
BlitColumn01:
  DEFW $0800,$0800,$0800,$0800,$57E1,$57C1,$57A1,$5781
  DEFW $5761,$5741,$5721,$5701,$4FE1,$4FC1,$4FA1,$4F81

; Blit addresses, column 2 (17 cells)
BlitColumn02:
  DEFW $0800,$0800,$0800,$0800,$57E2,$57C2,$57A2,$5782,$5762
  DEFW $5742,$5722,$5702,$4FE2,$4FC2,$4FA2,$4F82,$4F62

; Blit addresses, column 3 (16 cells)
BlitColumn03:
  DEFW $0800,$0800,$0800,$57E3,$57C3,$57A3,$5783,$5763
  DEFW $5743,$5723,$5703,$4FE3,$4FC3,$4FA3,$4F83,$4F63

; Blit addresses, column 4 (17 cells)
BlitColumn04:
  DEFW $0800,$0800,$0800,$57E4,$57C4,$57A4,$5784,$5764,$5744
  DEFW $5724,$5704,$4FE4,$4FC4,$4FA4,$4F84,$4F64,$4F44

; Blit addresses, column 5 (16 cells)
BlitColumn05:
  DEFW $0800,$0800,$57E5,$57C5,$57A5,$5785,$5765,$5745
  DEFW $5725,$5705,$4FE5,$4FC5,$4FA5,$4F85,$4F65,$4F45

; Blit addresses, column 6 (17 cells)
BlitColumn06:
  DEFW $0800,$0800,$57E6,$57C6,$57A6,$5786,$5766,$5746,$5726
  DEFW $5706,$4FE6,$4FC6,$4FA6,$4F86,$4F66,$4F46,$4F26

; Blit addresses, column 7 (16 cells)
BlitColumn07:
  DEFW $0800,$57E7,$57C7,$57A7,$5787,$5767,$5747,$5727
  DEFW $5707,$4FE7,$4FC7,$4FA7,$4F87,$4F67,$4F47,$4F27

; Blit addresses, column 8 (17 cells)
BlitColumn08:
  DEFW $0800,$57E8,$57C8,$57A8,$5788,$5768,$5748,$5728,$5708
  DEFW $4FE8,$4FC8,$4FA8,$4F88,$4F68,$4F48,$4F28,$4F08

; Blit addresses, column 9 (16 cells)
BlitColumn09:
  DEFW $57E9,$57C9,$57A9,$5789,$5769,$5749,$5729,$5709
  DEFW $4FE9,$4FC9,$4FA9,$4F89,$4F69,$4F49,$4F29,$4F09

; Blit addresses, column 10 (17 cells)
BlitColumn10:
  DEFW $53EA,$57CA,$57AA,$578A,$576A,$574A,$572A,$570A,$4FEA
  DEFW $4FCA,$4FAA,$4F8A,$4F6A,$4F4A,$4F2A,$4F0A,$47EA

; Blit addresses, column 11 (16 cells)
BlitColumn11:
  DEFW $57CB,$57AB,$578B,$576B,$574B,$572B,$570B,$4FEB
  DEFW $4FCB,$4FAB,$4F8B,$4F6B,$4F4B,$4F2B,$4F0B,$47EB

; Blit addresses, column 12 (17 cells)
BlitColumn12:
  DEFW $53CC,$57AC,$578C,$576C,$574C,$572C,$570C,$4FEC,$4FCC
  DEFW $4FAC,$4F8C,$4F6C,$4F4C,$4F2C,$4F0C,$47EC,$47CC

; Blit addresses, column 13 (16 cells)
BlitColumn13:
  DEFW $57AD,$578D,$576D,$574D,$572D,$570D,$4FED,$4FCD
  DEFW $4FAD,$4F8D,$4F6D,$4F4D,$4F2D,$4F0D,$47ED,$47CD

; Blit addresses, column 14 (17 cells)
BlitColumn14:
  DEFW $53AE,$578E,$576E,$574E,$572E,$570E,$4FEE,$4FCE,$4FAE
  DEFW $4F8E,$4F6E,$4F4E,$4F2E,$4F0E,$47EE,$47CE,$47AE

; Blit addresses, column 15 (16 cells)
BlitColumn15:
  DEFW $578F,$576F,$574F,$572F,$570F,$4FEF,$4FCF,$4FAF
  DEFW $4F8F,$4F6F,$4F4F,$4F2F,$4F0F,$47EF,$47CF,$47AF

; Blit addresses, column 16 (17 cells)
BlitColumn16:
  DEFW $5390,$5770,$5750,$5730,$5710,$4FF0,$4FD0,$4FB0,$4F90
  DEFW $4F70,$4F50,$4F30,$4F10,$47F0,$47D0,$47B0,$4790

; Blit addresses, column 17 (16 cells)
BlitColumn17:
  DEFW $5771,$5751,$5731,$5711,$4FF1,$4FD1,$4FB1,$4F91
  DEFW $4F71,$4F51,$4F31,$4F11,$47F1,$47D1,$47B1,$4791

; Blit addresses, column 18 (17 cells)
BlitColumn18:
  DEFW $5372,$5752,$5732,$5712,$4FF2,$4FD2,$4FB2,$4F92,$4F72
  DEFW $4F52,$4F32,$4F12,$47F2,$47D2,$47B2,$4792,$4772

; Blit addresses, column 19 (16 cells)
BlitColumn19:
  DEFW $0800,$0800,$5713,$4FF3,$4FD3,$4FB3,$4F93,$4F73
  DEFW $4F53,$4F33,$4F13,$47F3,$47D3,$47B3,$4793,$4773

; Blit addresses, column 20 (17 cells)
BlitColumn20:
  DEFW $0800,$0800,$5714,$4FF4,$4FD4,$4FB4,$4F94,$4F74,$4F54
  DEFW $4F34,$4F14,$47F4,$47D4,$47B4,$4794,$4774,$4754

; Blit addresses, column 21 (16 cells)
BlitColumn21:
  DEFW $0800,$5715,$4FF5,$4FD5,$4FB5,$4F95,$4F75,$4F55
  DEFW $4F35,$4F15,$47F5,$47D5,$47B5,$4795,$4775,$4755

; Blit addresses, column 22 (17 cells)
BlitColumn22:
  DEFW $0800,$5716,$4FF6,$4FD6,$4FB6,$4F96,$4F76,$4F56,$4F36
  DEFW $4F16,$47F6,$47D6,$47B6,$4796,$4776,$4756,$4736

; Blit addresses, column 23 (16 cells)
BlitColumn23:
  DEFW $5717,$4FF7,$4FD7,$4FB7,$4F97,$4F77,$4F57,$4F37
  DEFW $4F17,$47F7,$47D7,$47B7,$4797,$4777,$4757,$4737

; Blit addresses, column 24 (17 cells)
BlitColumn24:
  DEFW $5318,$4FF8,$4FD8,$4FB8,$4F98,$4F78,$4F58,$4F38,$4F18
  DEFW $47F8,$47D8,$47B8,$4798,$4778,$4758,$4738,$4718

; Blit addresses, column 25 (16 cells)
BlitColumn25:
  DEFW $4FF9,$4FD9,$4FB9,$4F99,$4F79,$4F59,$4F39,$4F19
  DEFW $47F9,$47D9,$47B9,$4799,$4779,$4759,$4739,$4719

; Blit addresses, column 26 (17 cells)
BlitColumn26:
  DEFW $4BFA,$4FDA,$4FBA,$4F9A,$4F7A,$4F5A,$4F3A,$4F1A,$47FA
  DEFW $47DA,$47BA,$479A,$477A,$475A,$473A,$471A,$0800

; Blit addresses, column 27 (16 cells)
BlitColumn27:
  DEFW $4FDB,$4FBB,$4F9B,$4F7B,$4F5B,$4F3B,$4F1B,$47FB
  DEFW $47DB,$47BB,$479B,$477B,$475B,$473B,$471B,$0800

; Blit addresses, column 28 (17 cells)
BlitColumn28:
  DEFW $4BDC,$4FBC,$4F9C,$4F7C,$4F5C,$4F3C,$4F1C,$47FC,$47DC
  DEFW $47BC,$479C,$477C,$475C,$473C,$471C,$0800,$0800

; Blit addresses, column 29 (16 cells)
BlitColumn29:
  DEFW $4FBD,$4F9D,$4F7D,$4F5D,$4F3D,$4F1D,$47FD,$47DD
  DEFW $47BD,$479D,$477D,$475D,$473D,$471D,$0800,$0800

; Blit addresses, column 30 (17 cells)
BlitColumn30:
  DEFW $4BBE,$4F9E,$4F7E,$4F5E,$4F3E,$4F1E,$47FE,$47DE,$47BE
  DEFW $479E,$477E,$475E,$473E,$471E,$0800,$0800,$0800

; Blit addresses, column 31 (16 cells)
BlitColumn31:
  DEFW $4F9F,$4F7F,$4F5F,$4F3F,$4F1F,$47FF,$47DF,$47BF
  DEFW $479F,$477F,$475F,$473F,$471F,$0800,$0800,$0800

; The end mark of BlitAddresses ($FFFF), and a spare zero word
BlitListEnd:
  DEFW $FFFF,$0000
