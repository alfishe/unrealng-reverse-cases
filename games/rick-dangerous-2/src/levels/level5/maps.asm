; --------------------------------------------------------------------------------------------------------------------
; maps.asm: The sections' maps: rows of 8 block numbers
; --------------------------------------------------------------------------------------------------------------------

; The maps of the 8 sections, one row of 8 block numbers a line
;
; LevelHeader+4 points here. A section's map is a column of rows, 8 block
; numbers a row (8 x 4 cells = 256 pixels: one screen wide), the top row first;
; the section table's +0/+1 (big-endian) is the offset of its first row from
; here. No height is stored: BuildView $88D4 reads 11 rows from row ViewTop / 4
; into ViewCells (44 cell rows), the screen shows view rows 9-31 under the HUD,
; and the scroll limit (section table +3) is the last ViewTop. So a section
; shows block rows 2 to limit / 4 + 7 (rows 0-1 lie above the screen, rows
; limit / 4 + 8 to + 10 are built below it for the objects there).
;
; The maps follow each other in memory (in section order but for the
; section-table filler entries). A map often starts 2 rows before the end of
; the previous one's shown rows: those 2 rows are the next section's hidden
; rows 0-1 (a packing that costs nothing). The comment on each section gives
; its rows to the next map and what the limit asks for.
Maps:
  INCBIN "res/level/maps.bin",$0000,272
Section1Map:
  INCBIN "res/level/maps.bin",$0110,80
Section2Map:
  INCBIN "res/level/maps.bin",$0160,224
Section3Map:
  INCBIN "res/level/maps.bin",$0240,112
Section4Map:
  INCBIN "res/level/maps.bin",$02B0,56
Section5Map:
  INCBIN "res/level/maps.bin",$02E8,88
Section6Map:
  INCBIN "res/level/maps.bin",$0340,256
Section7Map:
  INCBIN "res/level/maps.bin",$0440,96

; 317 bytes of older data (5-byte groups such as 00 00 FD 03 03), read by no
; code
;
; Not level 4's bytes, and no section shows them; their origin is not known.
; BuildView reads the first 24 bytes as the 3 rows it builds below the view of
; the section whose shown rows end at $E88D (scrolled to its limit); no section
; shows them.
MapsTail1:
  DEFB $80,$C0,$00,$00,$5F
  DEFB $80,$E0,$00,$00,$7F
  DEFB $80,$C0,$00,$00,$7F
  DEFB $B0,$C0,$00,$00,$7F
  DEFB $BE,$FE,$2A,$00,$41
  DEFB $BE,$FE,$00,$00,$4F
  DEFB $80,$F0,$00,$00,$5F
  DEFB $80,$E0,$00,$00,$F7
  DEFB $35,$08,$00,$00,$BF
  DEFB $3F,$40,$00,$00,$1F
  DEFB $17,$E0,$00,$00,$0F
  DEFB $08,$F0,$00,$00,$1F
  DEFB $1F,$E0,$00,$00,$9E
  DEFB $9A,$61,$00,$00,$FC
  DEFB $04,$03,$00,$00,$F8
  DEFB $00,$07,$00,$00,$FD
  DEFB $7F,$7F,$54,$00,$81
  DEFB $7F,$7F,$00,$00,$F1
  DEFB $03,$0F,$00,$00,$F9
  DEFB $03,$07,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FF
  DEFB $FF,$FF,$AA,$00,$AA
  DEFB $FF,$FF,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FD
  DEFB $03,$03,$00,$00,$FF
  DEFB $FF,$FF,$55,$00,$55
  DEFB $FF,$FF,$00,$00,$7F
  DEFB $80,$C0,$00,$00,$7F
  DEFB $80,$C0,$00,$00,$6F
  DEFB $A0,$D0,$00,$00,$4F
  DEFB $80,$F0,$00,$00,$6F
  DEFB $A0,$D0,$00,$00,$7F
  DEFB $B0,$C0,$00,$00,$5A
  DEFB $3C,$FF,$FF,$00,$5A
  DEFB $3C,$FF,$FF,$00,$5A
  DEFB $3C,$FF,$FF,$00,$5A
  DEFB $3C,$FF,$FF,$00,$5A
  DEFB $3C,$FF,$FF,$00,$5A
  DEFB $3C,$FF,$FF,$00,$A5
  DEFB $18,$7E,$7E,$00,$DB
  DEFB $00,$3C,$3C,$00,$FF
  DEFB $10,$00,$00,$00,$E7
  DEFB $18,$00,$00,$00,$F7
  DEFB $08,$10,$00,$00,$F7
  DEFB $08,$10,$00,$00,$E7
  DEFB $0C,$10,$00,$00,$F5
  DEFB $19,$06,$00,$00,$F9
  DEFB $0A,$05,$00,$00,$FE
  DEFB $02,$01,$00,$00,$FF
  DEFB $00,$00,$00,$00,$E7
  DEFB $18,$00,$00,$00,$F7
  DEFB $08,$10,$00,$00,$F7
  DEFB $08,$10,$00,$00,$E7
  DEFB $30,$08,$00,$00,$AF
  DEFB $98,$60,$00,$00,$9F
  DEFB $50,$A0,$00,$00,$7F
  DEFB $40,$80

; 35 zero bytes after the maps
;
; Zero bytes up to the next block.
MapsTail2:
  DEFS $23

; 768 bytes: level 4's bytes at the same addresses (an older build)
;
; Byte for byte the level 4 block at $E9ED-$ECEC: its last map rows
; ($E9ED-$EABC), the bytes after them, its section table ($EAED-$EB54) and the
; first of its lists. Level 5 was laid over a level 4 image; no code reads them
; (level 5's table is at $ECED).
MapsTail3:
  DEFB $01,$B5,$3E,$40,$3E,$40,$97,$29
  DEFB $02,$B6,$D6,$FC,$7F,$86,$3D,$29
  DEFB $01,$B6,$34,$84,$82,$90,$3D,$84
  DEFB $02,$5D,$3F,$40,$40,$97,$3F,$40
  DEFB $07,$28,$A0,$A0,$A0,$A0,$92,$85
  DEFB $02,$7E,$7F,$7F,$7F,$7F,$7F,$80
  DEFB $01,$02,$01,$07,$01,$02,$01,$02
  DEFB $02,$01,$02,$01,$02,$01,$02,$07
  DEFB $01,$07,$01,$81,$82,$83,$01,$02
  DEFB $02,$81,$82,$96,$40,$84,$CE,$07
  DEFB $82,$96,$40,$A1,$3F,$40,$B9,$03
  DEFB $34,$39,$85,$D1,$D1,$9D,$BA,$03
  DEFB $7F,$9D,$8B,$89,$89,$9C,$8C,$03
  DEFB $01,$43,$57,$37,$55,$15,$57,$03
  DEFB $F5,$5B,$A7,$5B,$A7,$5B,$A7,$F6
  DEFB $14,$8A,$89,$89,$89,$89,$89,$12
  DEFB $04,$55,$26,$12,$14,$7D,$00,$03
  DEFB $04,$8A,$0C,$20,$81,$9A,$8C,$03
  DEFB $04,$8A,$89,$89,$9B,$B9,$8F,$03
  DEFB $01,$05,$05,$05,$2A,$F7,$05,$01
  DEFB $82,$82,$82,$83,$2A,$DC,$82,$83
  DEFB $40,$40,$40,$29,$5D,$3E,$3E,$29
  DEFB $7F,$B7,$3D,$29,$7E,$B8,$3C,$29
  DEFB $02,$98,$3F,$84,$82,$9F,$38,$29
  DEFB $01,$94,$3D,$34,$34,$39,$3C,$29
  DEFB $02,$7E,$7F,$7F,$7F,$7F,$7F,$80
  DEFB $01,$02,$01,$02,$01,$02,$07,$02
  DEFB $02,$07,$02,$01,$02,$01,$02,$01
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$01,$00,$00,$00,$00
  DEFB $00,$00,$00,$78,$00,$68,$00,$75
  DEFB $01,$30,$00,$08,$01,$7A,$01,$83
  DEFB $01,$70,$00,$48,$01,$A8,$01,$B1
  DEFB $02,$40,$00,$60,$02,$4A,$02,$5B
  DEFB $03,$40,$00,$18,$02,$FC,$03,$0D
  DEFB $03,$B0,$00,$30,$03,$66,$03,$77
  DEFB $04,$50,$00,$30,$03,$E0,$03,$E5
  DEFB $04,$F0,$00,$20,$04,$76,$04,$7B
  DEFB $05,$60,$00,$08,$04,$B8,$04,$BD
  DEFB $05,$A0,$00,$08,$04,$E6,$04,$EB
  DEFB $06,$00,$00,$C8,$05,$14,$05,$25
  DEFB $07,$C0,$00,$20,$06,$76,$06,$7F
  DEFB $08,$30,$00,$30,$06,$D0,$06,$D9
  DEFB $01,$47,$08,$17,$02,$4F,$01,$17
  DEFB $02,$8F,$03,$1F,$00,$75,$0D,$8C
  DEFB $88,$75,$11,$94,$80,$1A,$16,$18
  DEFB $11,$A0,$11,$87,$41,$13,$18,$90
  DEFB $09,$18,$18,$30,$01,$14,$18,$92
  DEFB $09,$60,$18,$30,$20,$78,$18,$18
  DEFB $01,$C0,$18,$03,$01,$03,$24,$5D
  DEFB $92,$E0,$1A,$10,$08,$58,$24,$30
  DEFB $20,$03,$24,$5D,$91,$58,$24,$30
  DEFB $20,$01,$31,$CE,$99,$60,$32,$12
  DEFB $04,$11,$36,$09,$11,$20,$2F,$B9
  DEFB $41,$17,$36,$14,$91,$80,$30,$AB
  DEFB $41,$75,$3D,$88,$98,$0F,$40,$AC
  DEFB $89,$38,$3E,$10,$08,$79,$45,$88
  DEFB $8C,$79,$45,$93,$88,$7C,$45,$00
  DEFB $41,$00,$44,$32,$01,$04,$50,$AC
  DEFB $99,$80,$4E,$10,$08,$05,$52,$94
  DEFB $89,$68,$50,$30,$01,$06,$5A,$95
  DEFB $8A,$70,$58,$30,$01,$A0,$58,$03
  DEFB $01,$44,$64,$D2,$A5,$80,$66,$16
  DEFB $04,$7A,$65,$84,$80,$7A,$65,$8B
  DEFB $80,$01,$65,$D9,$AD,$C8,$65,$22
  DEFB $01,$78,$6A,$04,$01,$20,$6B,$03
  DEFB $01,$09,$74,$40,$91,$18,$6E,$10
  DEFB $08,$0A,$76,$06,$11,$20,$6E,$9F
  DEFB $41,$0A,$76,$12,$11,$50,$72,$5F
  DEFB $41,$0B,$80,$9C,$89,$D0,$81,$22
  DEFB $04,$75,$81,$8C,$00,$0C,$84,$80
  DEFB $99,$10,$84,$30,$20,$04,$88,$A4
  DEFB $89,$80,$82,$10,$08,$7C,$8D,$1D
  DEFB $41,$E8,$8C,$32,$01,$16,$91,$78
  DEFB $02,$20,$8C,$04,$01,$F8,$8C,$30
  DEFB $01,$0E,$91,$C9,$89,$20,$8C,$03
  DEFB $01,$15,$91,$C9,$89,$20,$8C,$03
  DEFB $01,$00,$02,$17,$02,$27,$01,$17
  DEFB $00,$4F,$00,$02,$0C,$AE,$80,$17
  DEFB $12,$14,$91,$90,$0C,$8A,$41,$0E
  DEFB $19,$C8,$89,$10,$14,$30,$01,$01
  DEFB $19,$F4,$99,$90,$1A,$16,$04,$15
  DEFB $19,$C8,$89,$10,$14,$30,$01,$00
  DEFB $01,$27,$01,$17,$01,$5F,$03,$17
  DEFB $00,$01,$0D,$C8,$69,$40,$0D,$22
  DEFB $01,$02,$14,$AE,$81,$38,$0E,$10
  DEFB $08,$78,$15,$12,$01,$98,$14,$30
  DEFB $01,$17,$19,$84,$00,$17,$1D,$14
  DEFB $91,$90,$14,$C9,$41,$76,$21,$89
  DEFB $80,$75,$21,$90,$90,$01,$29,$D9
  DEFB $6D,$C8,$29,$22,$01,$1E,$31,$5C
  DEFB $92,$60,$30,$30,$20,$A0,$2D,$03
  DEFB $01,$1E,$31,$5C,$91,$60,$30,$30
  DEFB $20,$01,$39,$F8,$61,$C0,$39,$22
