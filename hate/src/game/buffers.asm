; Bytes below the ground profile
;
; 76 bytes just below the ground profile $6000. In the image they hold
; mask/pixel byte pairs left from the build; the screen copy at $9F1C
; overwrites them from $BFB4-$BFFF (the image of $5B00-$5FFF) before play. The
; profile readers index from $5FF6-$5FF8 ($DA1E, $DAA1, $DB1B, $E3E5, $E94F),
; so the top of this block is the profile's left margin.
ProfileMargin:
  DEFB $3F,$00,$3F,$80,$3F,$80,$1F,$80,$0F,$C0,$0F,$60,$0F,$40,$1F,$80
  DEFB $3F,$00,$7F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$F0,$01,$F0,$06,$C0,$05,$80,$15,$80,$27,$80,$3B
  DEFB $80,$0B,$E0,$03,$F8,$03,$F8,$03,$F8,$03,$F8,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$F8,$00,$E0,$02

; Ground profile buffer (768 bytes)
;
; The course's profile under the scroll, one byte for every 2 units along the
; course: the ground height (bits 0-4) and the walls (bits 5-7);
; docs/07-objects.md 7.4. Cleared at every round start ($CF68, $D0EF). In the
; image it holds leftovers of the build, and the entry $61A8 sits inside it:
; code that runs once and then becomes buffer space (docs/02-architecture.md
; 2.2).
ProfileBuffer:
  DEFB $00,$0D,$00,$B3,$00,$AF,$00,$BF,$00,$BF,$00,$4F,$00,$32,$00,$CC
  DEFB $00,$E7,$00,$DE,$00,$84,$30,$02,$78,$01,$FC,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$3F,$00,$1F,$80,$1F,$C0,$1F,$C0
  DEFB $1F,$C0,$0F,$80,$0F,$60,$0F,$E0,$07,$E0,$03,$30,$03,$18,$03,$50
  DEFB $07,$20,$0F,$C0,$1F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$00,$F0,$01,$C0,$06,$C0,$19,$C0,$06,$C0,$1A
  DEFB $C0,$09,$E0,$06,$F0,$02,$F8,$00,$FE,$00,$FE,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$F0,$00,$C0,$06,$00,$19,$00,$66
  DEFB $00,$9B,$00,$6B,$00,$A7,$00,$99,$00,$60,$00,$86,$00,$1F,$00,$7D
  DEFB $00,$FE,$00,$FF,$00,$7E,$00,$3F,$80,$0F,$E0,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$3F,$00,$0F,$80,$03,$60,$00,$98,$00,$E6,$00,$F9
  DEFB $00,$FE,$00,$7F,$00,$1F,$00,$86,$00,$64,$01,$B0,$07,$50,$07,$E0
  DEFB $01,$D0,$01,$3C,$01,$0C,$E1,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00,$3F,$80,$3F,$00,$3F,$80,$3F,$00
  DEFB $7F,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FC,$00
  DEFB $F0,$01,$F0,$06,$F0,$01,$F0,$06,$F0,$02,$F8,$01,$FC,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FC,$00,$F0,$01,$C0,$06,$00,$19,$00,$66,$00,$9A,$00,$69,$00,$A6
  DEFB $00,$98,$00,$61,$00,$87,$00,$9F,$00,$3F,$80,$3F,$80,$1F,$C0,$0F
  DEFB $E0,$03,$F8,$00,$FF,$00,$FF,$00,$FF,$00,$3F,$00,$0F,$80,$03,$60
  DEFB $00,$98,$00,$E6,$00,$F9,$00,$FE,$00,$7F,$00,$1F,$00,$87,$00,$E1
  DEFB $00,$59,$00,$AC,$01,$D4,$01,$B8,$00,$F4,$00,$CF,$00,$03,$F8,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$FF,$00,$3F,$00,$0F,$80
  DEFB $0F,$60,$0F,$80,$0F,$E0,$0F,$C0,$1F,$80,$3F,$00,$7F,$00,$FF,$00
  DEFB $FF,$00,$7F,$00,$7F,$00,$7F,$00,$7F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00

; Game entry (RANDOMIZE USR 25000)
;
; The address BASIC line 30 calls. It sets the stack to the top of memory,
; disables interrupts and jumps to the start-up $9F12. Overwritten when the
; first round clears the profile buffer.
Entry:
  LD SP,$FFFF             ; the stack grows down from the top of RAM
  DI                      ; the game proper runs with interrupts off
  JP Startup              ; the start-up

; Ground profile buffer, after the entry
;
; The rest of the profile buffer, to $62FF. The first 42 bytes are leftover
; loader code that never runs, the rest is zero.
GroundProfileTail:
  DEFB $73,$30,$6D,$F3,$3A,$D9,$79,$B7,$CA,$02,$62,$3A,$10,$00,$FE,$C3
  DEFB $20,$41,$AF,$01,$FD,$7F,$ED,$79,$3A,$10,$00,$FE,$C3,$20,$34,$3E
  DEFB $30,$01,$FD,$7F,$ED,$79,$CD,$6B,$75,$8B,$06,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; Font, codes $20-$3A
;
; 64 glyphs of 8 bytes for codes $20-$5F at $6300-$64FF, glyph = $6300 + (code
; - $20) * 8; printed by $EE17 and, lines 2-6 only, by $EEA4
; (docs/08-hud-and-text.md 8.2). Codes $22-$2C are the big GAME OVER, $2E a red
; block, $2F a gauge segment. The glyph slots of ";" to "?" and "[" to "_" hold
; strings instead (next entries).
Font:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$18,$18,$18,$00,$18,$00
  DEFB $0F,$1F,$1C,$1C,$1C,$1C,$1F,$0F
  DEFB $E1,$E3,$07,$EE,$EF,$EF,$EE,$EE
  DEFB $83,$C7,$E7,$77,$F7,$F7,$77,$77
  DEFB $FF,$FF,$33,$33,$33,$33,$33,$33
  DEFB $3F,$BF,$B8,$BF,$BF,$B8,$BF,$BF
  DEFB $C0,$C0,$00,$C0,$C0,$00,$C0,$C0
  DEFB $3F,$7F,$71,$71,$71,$71,$7F,$3F
  DEFB $9C,$DC,$DC,$DC,$DC,$CF,$C7,$83
  DEFB $EF,$EF,$EE,$EF,$EF,$CE,$8F,$0F
  DEFB $F7,$F7,$07,$F7,$F7,$07,$F7,$F7
  DEFB $F0,$F8,$18,$F8,$F0,$70,$38,$38
  DEFB $00,$00,$00,$00,$3E,$00,$00,$00
  DEFB $00,$7E,$7C,$7C,$7C,$7C,$40,$00
  DEFB $00,$00,$FE,$FE,$FE,$FE,$FE,$00
  DEFB $00,$00,$3E,$63,$63,$63,$3E,$00
  DEFB $00,$00,$0C,$1C,$0C,$0C,$1E,$00
  DEFB $00,$00,$7E,$03,$3E,$60,$7F,$00
  DEFB $00,$00,$7E,$03,$1E,$03,$7E,$00
  DEFB $00,$00,$66,$66,$7F,$06,$06,$00
  DEFB $00,$00,$7F,$60,$7E,$03,$7E,$00
  DEFB $00,$00,$3E,$60,$7E,$63,$3E,$00
  DEFB $00,$00,$7F,$03,$06,$0C,$18,$00
  DEFB $00,$00,$3E,$63,$3E,$63,$3E,$00
  DEFB $00,$00,$3E,$63,$3F,$03,$3E,$00
  DEFB $00,$00,$00,$18,$00,$18,$00,$00

; Credits, first part (in the font's ";" to "?" slots)
;
; A print string for $EE17 (records: attribute + $80, column, row, characters;
; $FF ends): "WRITTEN BY", "COSTA PANAYI", "MUSIC BY" at column 1, rows 17-19,
; attribute $30. Printed by the menu $F1AA; docs/08-hud-and-text.md 8.3.
CreditsText1:
  DEFM $B0,$01,$11,"WRITTEN BY",$B0,$01,$12,"COSTA PANAYI",$B0,$01,$13,"MUSIC BY",$FF

; Font, codes $40-$5A
;
; The second half of the font: the (c) sign at code $40 ("@" in the strings)
; and the capitals.
FontHigh:
  DEFB $00,$00,$7E,$9D,$B1,$9D,$7E,$00
  DEFB $00,$00,$08,$1C,$36,$7F,$63,$00
  DEFB $00,$00,$7E,$63,$7E,$63,$7E,$00
  DEFB $00,$00,$3F,$60,$60,$60,$3F,$00
  DEFB $00,$00,$7E,$63,$63,$63,$7E,$00
  DEFB $00,$00,$3F,$60,$7F,$60,$3F,$00
  DEFB $00,$00,$3F,$60,$7F,$60,$60,$00
  DEFB $00,$00,$3F,$60,$6F,$63,$3F,$00
  DEFB $00,$00,$63,$63,$7F,$63,$63,$00
  DEFB $00,$00,$7E,$18,$18,$18,$7E,$00
  DEFB $00,$00,$03,$03,$03,$03,$7E,$00
  DEFB $00,$00,$63,$6C,$70,$6C,$63,$00
  DEFB $00,$00,$60,$60,$60,$60,$3F,$00
  DEFB $00,$00,$36,$6B,$6B,$6B,$6B,$00
  DEFB $00,$00,$73,$7B,$6F,$67,$63,$00
  DEFB $00,$00,$3E,$63,$63,$63,$3E,$00
  DEFB $00,$00,$7E,$63,$7E,$60,$60,$00
  DEFB $00,$00,$3E,$63,$63,$6B,$3E,$08
  DEFB $00,$00,$7E,$63,$7E,$63,$63,$00
  DEFB $00,$00,$3F,$60,$3E,$03,$7E,$00
  DEFB $00,$00,$7E,$18,$18,$18,$18,$00
  DEFB $00,$00,$63,$63,$63,$63,$3E,$00
  DEFB $00,$00,$63,$63,$36,$1C,$08,$00
  DEFB $00,$00,$6B,$6B,$6B,$6B,$36,$00
  DEFB $00,$00,$63,$36,$1C,$36,$63,$00
  DEFB $00,$00,$66,$66,$3C,$18,$18,$00
  DEFB $00,$00,$7F,$06,$18,$60,$7F,$00

; Credits, second part (in the font's "[" to "_" slots)
;
; "BEN DAGLISH", "(c)1989 VORTEX" at column 1, rows 20-21. Printed by the menu
; $F1AA.
CreditsText2:
  DEFM $B0,$01,$14,"BEN DAGLISH",$B0,$01,$15,"@1989 VORTEX",$FF

; " AUTO " in the top window
;
; Printed at (2,6) by the AUTO start in $E68C (docs/05-controls.md 5.4).
AutoText:
  DEFM $87,$02,$06," AUTO ",$FF

; Visible-record list and sprite scratch page
;
; Work space of the sprite code. $EFA5 builds the list of visible records here
; each pass (pointer kept at $EF9F, $40 ends the list) and $F089 scans it;
; $DE08 fills $6500-$6543 with $FF as scratch. Zero in the image.
SpriteScratch:
  DEFS $80

; Sprite graphics, table slot $00
;
; The sprite graphics run from here to $7FFF. Each block is reached through the
; pointer table $C300 by a record's byte +8 (the low byte of the address into
; $C300): the player gets 2 x type ($D246 writes $C008), the templates
; $C2B4-$C2E1 and $C360/$C370 carry their own. The block boundaries below are
; the table's pointers.
SpriteGfx00:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FC,$00,$FC,$01,$F0,$01,$E0,$05
  DEFB $E0,$09,$E0,$0E,$E0,$02,$F8,$00
  DEFB $FE,$00,$FE,$00,$FE,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FE,$00,$F8,$00
  DEFB $00,$03,$00,$6C,$00,$AB,$00,$6F
  DEFB $00,$6F,$00,$D3,$00,$CC,$00,$F3
  DEFB $00,$F9,$00,$F7,$00,$E1,$0C,$C0
  DEFB $1E,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$07,$60,$07,$F0,$07,$F0
  DEFB $07,$F0,$03,$E0,$03,$D8,$03,$B8
  DEFB $01,$38,$00,$CC,$00,$86,$00,$14
  DEFB $01,$88,$03,$70,$07,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$00,$F8,$01
  DEFB $F8,$02,$F8,$03,$F8,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FE,$00
  DEFB $C0,$00,$00,$1B,$00,$6A,$00,$5B
  DEFB $00,$5B,$00,$74,$00,$B3,$00,$BC
  DEFB $00,$3E,$80,$3D,$80,$38,$83,$30
  DEFB $87,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$8F,$00
  DEFB $03,$20,$01,$D8,$01,$3C,$01,$FC
  DEFB $01,$FC,$00,$F8,$00,$F6,$00,$2E
  DEFB $00,$CE,$00,$73,$00,$E1,$00,$45
  DEFB $00,$22,$80,$1C,$C1,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$7F,$00,$3F,$00,$3F,$80
  DEFB $3F,$00,$7F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FE,$00
  DEFB $FE,$00,$FE,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $F0,$00,$C0,$06,$C0,$1A,$00,$16
  DEFB $00,$56,$00,$9D,$00,$EC,$00,$2F
  DEFB $80,$0F,$E0,$0F,$E0,$0E,$E0,$0C
  DEFB $E1,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$E3,$00
  DEFB $80,$08,$00,$36,$00,$CF,$00,$BF
  DEFB $00,$FF,$00,$FE,$00,$3D,$00,$CB
  DEFB $00,$33,$00,$9C,$00,$78,$00,$11
  DEFB $C0,$08,$E0,$07,$F0,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$7F,$00
  DEFB $7F,$00,$7F,$00,$3F,$00,$3F,$80
  DEFB $3F,$80,$1F,$80,$0F,$C0,$0F,$60
  DEFB $0F,$40,$1F,$80,$3F,$00,$7F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FC,$00
  DEFB $F0,$01,$F0,$06,$C0,$05,$80,$15
  DEFB $80,$27,$80,$3B,$80,$0B,$E0,$03
  DEFB $F8,$03,$F8,$03,$F8,$03,$F8,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$F8,$00,$E0,$02
  DEFB $00,$0D,$00,$B3,$00,$AF,$00,$BF
  DEFB $00,$BF,$00,$4F,$00,$32,$00,$CC
  DEFB $00,$E7,$00,$DE,$00,$84,$30,$02
  DEFB $78,$01,$FC,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$1F,$80,$1F,$C0,$1F,$C0
  DEFB $1F,$C0,$0F,$80,$0F,$60,$0F,$E0
  DEFB $07,$E0,$03,$30,$03,$18,$03,$50
  DEFB $07,$20,$0F,$C0,$1F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00

; Sprite graphics, table slot $02
SpriteGfx02:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FC,$00
  DEFB $F0,$01,$C0,$06,$C0,$19,$C0,$06
  DEFB $C0,$1A,$C0,$09,$E0,$06,$F0,$02
  DEFB $F8,$00,$FE,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$00,$C0,$06,$00,$19
  DEFB $00,$66,$00,$9B,$00,$6B,$00,$A7
  DEFB $00,$99,$00,$60,$00,$86,$00,$1F
  DEFB $00,$7D,$00,$FE,$00,$FF,$00,$7E
  DEFB $00,$3F,$80,$0F,$E0,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$03,$60,$00,$98,$00,$E6
  DEFB $00,$F9,$00,$FE,$00,$7F,$00,$1F
  DEFB $00,$86,$00,$64,$01,$B0,$07,$50
  DEFB $07,$E0,$01,$D0,$01,$3C,$01,$0C
  DEFB $E1,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$3F,$80,$3F,$00,$3F,$80
  DEFB $3F,$00,$7F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FC,$00,$F0,$01,$F0,$06,$F0,$01
  DEFB $F0,$06,$F0,$02,$F8,$01,$FC,$00
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$F0,$01,$C0,$06
  DEFB $00,$19,$00,$66,$00,$9A,$00,$69
  DEFB $00,$A6,$00,$98,$00,$61,$00,$87
  DEFB $00,$9F,$00,$3F,$80,$3F,$80,$1F
  DEFB $C0,$0F,$E0,$03,$F8,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$3F,$00,$0F,$80
  DEFB $03,$60,$00,$98,$00,$E6,$00,$F9
  DEFB $00,$FE,$00,$7F,$00,$1F,$00,$87
  DEFB $00,$E1,$00,$59,$00,$AC,$01,$D4
  DEFB $01,$B8,$00,$F4,$00,$CF,$00,$03
  DEFB $F8,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$0F,$60,$0F,$80,$0F,$E0
  DEFB $0F,$C0,$1F,$80,$3F,$00,$7F,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$7F,$00
  DEFB $7F,$00,$7F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$FC,$01,$FC,$00
  DEFB $FC,$01,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$00,$F0,$01
  DEFB $C0,$06,$00,$19,$00,$66,$00,$9A
  DEFB $00,$69,$00,$A6,$00,$98,$00,$61
  DEFB $00,$27,$80,$0F,$E0,$0F,$E0,$07
  DEFB $F0,$03,$F8,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$0F,$00,$03,$60
  DEFB $00,$98,$00,$66,$00,$B9,$00,$BE
  DEFB $00,$7F,$00,$9F,$00,$07,$00,$61
  DEFB $00,$F8,$00,$D6,$00,$EB,$00,$F5
  DEFB $00,$EE,$00,$FD,$00,$F3,$00,$00
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$3F,$00,$0F,$80
  DEFB $03,$60,$03,$98,$03,$E0,$03,$F8
  DEFB $03,$F0,$07,$60,$0F,$40,$1F,$00
  DEFB $7F,$00,$7F,$00,$1F,$00,$1F,$C0
  DEFB $1F,$C0,$1F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$00,$F0,$01
  DEFB $C0,$06,$00,$19,$00,$66,$00,$1A
  DEFB $00,$69,$00,$26,$80,$18,$C0,$09
  DEFB $E0,$03,$F8,$03,$F8,$01,$FC,$00
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$C3,$00,$00,$18,$00,$66
  DEFB $00,$99,$00,$6E,$00,$AF,$00,$9F
  DEFB $00,$67,$00,$81,$00,$18,$00,$7E
  DEFB $00,$F5,$00,$FA,$00,$FD,$00,$FB
  DEFB $00,$FF,$00,$3C,$80,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$0F,$80,$03,$60,$00,$98
  DEFB $00,$E6,$00,$F8,$00,$FE,$00,$7C
  DEFB $01,$18,$03,$90,$07,$C0,$1F,$40
  DEFB $1F,$80,$07,$40,$07,$F0,$07,$30
  DEFB $87,$00,$FF,$00,$FF,$00

; Sprite graphics, table slot $04
SpriteGfx04:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $E0,$00,$E0,$0B,$E0,$03,$F0,$06
  DEFB $F0,$02,$F8,$01,$FC,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$00,$00,$80,$00,$FD
  DEFB $00,$3D,$00,$0C,$00,$2F,$00,$98
  DEFB $00,$7F,$00,$1A,$80,$2B,$80,$15
  DEFB $C0,$02,$F8,$01,$FC,$01,$FC,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$00,$00
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$0E,$00,$F0,$00,$FF,$00,$BF
  DEFB $00,$EE,$00,$F8,$03,$78,$03,$B8
  DEFB $03,$18,$C3,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $7F,$00,$3F,$00,$3F,$80,$3F,$80
  DEFB $3F,$00,$7F,$00,$3F,$00,$3F,$80
  DEFB $3F,$80,$3F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $F8,$00,$F8,$02,$F8,$00,$FC,$01
  DEFB $FC,$00,$FE,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$00,$00,$E0,$00,$FF
  DEFB $00,$8F,$00,$83,$00,$4B,$00,$26
  DEFB $80,$1F,$C0,$06,$E0,$0A,$E0,$05
  DEFB $F0,$00,$FE,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$00,$00
  DEFB $00,$7F,$00,$7F,$00,$3F,$00,$FF
  DEFB $00,$03,$00,$FC,$00,$BF,$00,$EF
  DEFB $00,$7B,$00,$BE,$00,$5E,$00,$6E
  DEFB $00,$06,$F0,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $1F,$00,$0F,$C0,$0F,$E0,$0F,$E0
  DEFB $0F,$C0,$1F,$80,$0F,$00,$0F,$E0
  DEFB $0F,$E0,$0F,$80,$3F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$00,$FE,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$03,$00,$00,$B8,$00,$3F
  DEFB $00,$63,$00,$20,$80,$12,$C0,$09
  DEFB $E0,$07,$F0,$01,$F8,$02,$F8,$01
  DEFB $FC,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$00,$00
  DEFB $00,$DF,$00,$DF,$00,$CF,$00,$FF
  DEFB $00,$80,$00,$FF,$00,$AF,$00,$BB
  DEFB $00,$5E,$00,$2F,$80,$17,$C0,$1B
  DEFB $C0,$01,$FC,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $07,$00,$03,$F0,$03,$F8,$03,$F8
  DEFB $03,$F0,$07,$E0,$03,$00,$03,$F8
  DEFB $03,$F8,$03,$E0,$0F,$80,$3F,$80
  DEFB $3F,$80,$3F,$80,$3F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $80,$00,$80,$2E,$80,$0F,$C0,$18
  DEFB $C0,$08,$E0,$04,$F0,$02,$F8,$01
  DEFB $FC,$00,$FE,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$00,$00,$00,$F7
  DEFB $00,$F7,$00,$33,$00,$BF,$00,$60
  DEFB $00,$FF,$00,$6B,$00,$AE,$00,$57
  DEFB $00,$0B,$E0,$05,$F0,$06,$F0,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$01,$00
  DEFB $00,$FC,$00,$FE,$00,$FE,$00,$FC
  DEFB $01,$38,$00,$C0,$00,$FE,$00,$FE
  DEFB $00,$B8,$03,$E0,$0F,$E0,$0F,$E0
  DEFB $0F,$60,$0F,$00,$FF,$00

; Sprite graphics, table slot $06
SpriteGfx06:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FC,$00
  DEFB $F0,$01,$C0,$04,$C0,$10,$C0,$01
  DEFB $C0,$06,$C0,$1E,$C0,$06,$F0,$01
  DEFB $FC,$00,$FE,$00,$FE,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$00,$C0,$06,$00,$10
  DEFB $00,$40,$00,$06,$00,$1F,$00,$60
  DEFB $00,$90,$00,$4F,$00,$3F,$00,$7F
  DEFB $00,$7F,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$7F,$00,$7F,$00,$3F,$80,$0F
  DEFB $E0,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$03,$20,$00,$08,$00,$82
  DEFB $00,$60,$00,$98,$00,$26,$00,$C7
  DEFB $00,$E6,$00,$E8,$03,$F0,$07,$F0
  DEFB $07,$F0,$07,$E0,$0F,$E0,$0F,$C0
  DEFB $1F,$00,$7F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$3F,$80,$3F,$00,$3F,$00
  DEFB $3F,$80,$3F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FC,$00,$F0,$01,$F0,$07,$F0,$01
  DEFB $FC,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$F0,$01,$C0,$07
  DEFB $00,$18,$00,$61,$00,$85,$00,$95
  DEFB $00,$94,$00,$53,$00,$0F,$C0,$1F
  DEFB $80,$1F,$80,$3F,$80,$3F,$80,$3F
  DEFB $80,$1F,$C0,$1F,$C0,$0F,$E0,$03
  DEFB $F8,$00,$FF,$00,$3F,$00,$0F,$80
  DEFB $03,$E0,$00,$18,$00,$86,$00,$A1
  DEFB $00,$A9,$00,$29,$00,$CA,$00,$F0
  DEFB $03,$F8,$01,$F8,$01,$FC,$01,$FC
  DEFB $01,$FC,$01,$F8,$03,$F8,$03,$F0
  DEFB $07,$C0,$1F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$0F,$E0,$0F,$80,$3F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$FC,$01,$FC,$00
  DEFB $FC,$00,$FC,$01,$FC,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$00,$F0,$01
  DEFB $C0,$04,$00,$10,$00,$41,$00,$06
  DEFB $00,$19,$00,$64,$00,$E3,$00,$67
  DEFB $00,$17,$C0,$0F,$E0,$0F,$E0,$0F
  DEFB $E0,$07,$F0,$07,$F0,$03,$F8,$00
  DEFB $FE,$00,$FF,$00,$0F,$00,$03,$60
  DEFB $00,$08,$00,$02,$00,$60,$00,$F8
  DEFB $00,$06,$00,$09,$00,$F2,$00,$FC
  DEFB $00,$FE,$00,$FE,$00,$FF,$00,$FF
  DEFB $00,$FF,$00,$FE,$00,$FE,$00,$FC
  DEFB $01,$F0,$07,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$3F,$00,$0F,$80
  DEFB $03,$20,$03,$08,$03,$80,$03,$60
  DEFB $03,$78,$03,$60,$0F,$80,$3F,$00
  DEFB $7F,$00,$7F,$00,$7F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$00,$F0,$01
  DEFB $C0,$04,$00,$10,$00,$41,$00,$11
  DEFB $C0,$04,$F0,$01,$C0,$06,$00,$19
  DEFB $00,$7B,$00,$1B,$C0,$03,$F0,$01
  DEFB $FC,$01,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$C3,$00,$00,$18,$00,$42
  DEFB $00,$00,$00,$18,$00,$5A,$00,$42
  DEFB $00,$18,$00,$7E,$00,$81,$00,$7E
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$3C
  DEFB $81,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$0F,$80,$03,$20,$00,$08
  DEFB $00,$82,$00,$88,$03,$20,$0F,$80
  DEFB $03,$60,$00,$98,$00,$DE,$00,$D8
  DEFB $03,$C0,$0F,$80,$3F,$80,$3F,$00
  DEFB $7F,$00,$FF,$00,$FF,$00

; Sprite graphics, table slot $1C
SpriteGfx1C:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FE,$00
  DEFB $F8,$01,$E0,$06,$C0,$1F,$C0,$07
  DEFB $E0,$01,$F8,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$F9,$00,$E0,$06
  DEFB $80,$1F,$00,$47,$00,$59,$00,$56
  DEFB $00,$94,$00,$E4,$00,$F8,$00,$7E
  DEFB $00,$1F,$80,$06,$E0,$00,$F9,$00
  DEFB $FF,$00,$7F,$00,$1F,$80,$07,$E0
  DEFB $01,$F8,$00,$7E,$00,$1F,$00,$06
  DEFB $00,$00,$01,$00,$07,$80,$1F,$00
  DEFB $7F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$7F,$00
  DEFB $3F,$80,$3F,$00,$7F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$00,$F8,$01,$F0,$07,$F0,$01
  DEFB $F8,$00,$FE,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FE,$00,$F8,$01
  DEFB $E0,$03,$80,$1C,$00,$5F,$00,$57
  DEFB $00,$95,$00,$E5,$00,$79,$00,$1E
  DEFB $80,$07,$E0,$01,$F8,$00,$FE,$00
  DEFB $7F,$00,$1F,$80,$07,$E0,$01,$F8
  DEFB $00,$3E,$00,$CF,$00,$03,$00,$00
  DEFB $00,$00,$00,$00,$01,$80,$07,$80
  DEFB $1F,$00,$7F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$1F,$80
  DEFB $0F,$E0,$0F,$80,$1F,$00,$7F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FE,$00,$FC,$01,$FC,$00
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FE,$00
  DEFB $F8,$01,$E0,$07,$80,$17,$00,$57
  DEFB $00,$95,$00,$65,$00,$19,$80,$06
  DEFB $E0,$01,$F8,$00,$FE,$00,$FF,$00
  DEFB $9F,$00,$07,$60,$01,$98,$00,$E6
  DEFB $00,$F9,$00,$FC,$00,$F0,$00,$40
  DEFB $00,$40,$00,$40,$00,$80,$01,$60
  DEFB $07,$00,$9F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$7F,$00,$1F,$80,$07,$60
  DEFB $03,$18,$03,$00,$07,$00,$1F,$00
  DEFB $7F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FE,$00,$F8,$01
  DEFB $E0,$06,$80,$1F,$00,$7F,$00,$1F
  DEFB $80,$07,$E0,$01,$F8,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$E7,$00,$81,$18
  DEFB $00,$7E,$00,$FF,$00,$7F,$00,$9F
  DEFB $00,$E7,$00,$F9,$00,$FE,$00,$FF
  DEFB $00,$7E,$00,$18,$81,$00,$E7,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$1F,$80
  DEFB $07,$E0,$01,$F8,$00,$FE,$00,$F8
  DEFB $01,$60,$07,$80,$1F,$00,$7F,$00
  DEFB $FF,$00,$FF,$00

; Sprite graphics, table slot $1E
SpriteGfx1E:
  DEFB $FF,$00,$FC,$00,$F0,$01,$E0,$07
  DEFB $C0,$0F,$C0,$1F,$C0,$1F,$C0,$0F
  DEFB $C0,$06,$E0,$01,$F0,$00,$FC,$00
  DEFB $FF,$00,$FF,$00,$80,$00,$00,$29
  DEFB $00,$F2,$00,$F2,$00,$E2,$00,$D0
  DEFB $00,$B6,$00,$79,$00,$FF,$00,$FF
  DEFB $00,$3F,$00,$00,$80,$00,$FF,$00
  DEFB $1F,$00,$03,$40,$00,$F8,$00,$FE
  DEFB $00,$7F,$00,$BF,$00,$DF,$00,$EF
  DEFB $00,$F6,$00,$F8,$00,$C0,$03,$00
  DEFB $1F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$7F,$00,$3F,$00,$3F,$80
  DEFB $3F,$80,$3F,$00,$3F,$00,$7F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$00,$F8,$01
  DEFB $F0,$03,$F0,$07,$F0,$03,$F0,$01
  DEFB $F0,$00,$F8,$00,$FC,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$E0,$00,$00,$0C
  DEFB $00,$7C,$00,$F8,$00,$F4,$00,$ED
  DEFB $00,$DE,$00,$BF,$00,$7F,$00,$0F
  DEFB $00,$00,$00,$00,$E0,$00,$FF,$00
  DEFB $07,$00,$00,$B0,$00,$BE,$00,$9F
  DEFB $00,$2F,$00,$B7,$00,$7B,$00,$FD
  DEFB $00,$FE,$00,$F0,$00,$00,$00,$00
  DEFB $07,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$1F,$80,$0F,$C0,$0F,$E0
  DEFB $0F,$C0,$0F,$80,$0F,$00,$1F,$00
  DEFB $3F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FE,$00
  DEFB $FC,$00,$FC,$01,$FC,$01,$FC,$00
  DEFB $FC,$00,$FE,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$F8,$00,$C0,$02
  DEFB $00,$1F,$00,$7F,$00,$FE,$00,$FD
  DEFB $00,$FB,$00,$F7,$00,$6F,$00,$1F
  DEFB $00,$03,$C0,$00,$F8,$00,$FF,$00
  DEFB $01,$00,$00,$94,$00,$2F,$00,$2F
  DEFB $00,$27,$00,$0B,$00,$6D,$00,$9E
  DEFB $00,$FF,$00,$FF,$00,$FC,$00,$00
  DEFB $01,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$07,$E0,$03,$F0,$03,$F8
  DEFB $03,$F8,$03,$F0,$03,$60,$07,$80
  DEFB $0F,$00,$3F,$00,$FF,$00,$FF,$00
  DEFB $FE,$00,$F0,$00,$C0,$02,$80,$1F
  DEFB $00,$3F,$00,$7F,$00,$7F,$00,$7E
  DEFB $00,$3D,$80,$1B,$C0,$07,$F0,$00
  DEFB $FE,$00,$FF,$00,$00,$00,$00,$FF
  DEFB $00,$A5,$00,$CB,$00,$CB,$00,$89
  DEFB $00,$42,$00,$DB,$00,$E7,$00,$FF
  DEFB $00,$FF,$00,$FF,$00,$00,$FF,$00
  DEFB $7F,$00,$0F,$00,$03,$40,$01,$F8
  DEFB $00,$FC,$00,$FE,$00,$FE,$00,$7E
  DEFB $00,$BC,$01,$D8,$03,$E0,$0F,$00
  DEFB $7F,$00,$FF,$00

; Sprite graphics, table slot $14
SpriteGfx14:
  DEFB $FF,$00,$FC,$00,$F0,$01,$C0,$07
  DEFB $C0,$1F,$C0,$1F,$C0,$1F,$C0,$1F
  DEFB $C0,$1F,$C0,$1E,$C0,$19,$C0,$07
  DEFB $C0,$1F,$C0,$07,$F0,$01,$FC,$00
  DEFB $FF,$00,$0F,$00,$03,$40,$00,$E8
  DEFB $00,$D4,$00,$EA,$00,$D5,$00,$EA
  DEFB $00,$D5,$00,$8A,$00,$65,$00,$F8
  DEFB $00,$FE,$00,$FF,$00,$FE,$00,$F8
  DEFB $03,$60,$0F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$00,$3F,$80,$3F,$00
  DEFB $3F,$80,$3F,$00,$3F,$80,$3F,$00
  DEFB $3F,$80,$3F,$00,$3F,$80,$3F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$F0,$01,$F0,$07
  DEFB $F0,$07,$F0,$07,$F0,$07,$F0,$07
  DEFB $F0,$07,$F0,$06,$F0,$01,$F0,$07
  DEFB $F0,$01,$FC,$00,$FF,$00,$FF,$00
  DEFB $C3,$00,$00,$10,$00,$7A,$00,$F5
  DEFB $00,$FA,$00,$F5,$00,$FA,$00,$F5
  DEFB $00,$E2,$00,$99,$00,$7E,$00,$FF
  DEFB $00,$FF,$00,$FF,$00,$7E,$00,$18
  DEFB $C3,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$00,$0F,$A0,$0F,$40,$0F,$A0
  DEFB $0F,$40,$0F,$A0,$0F,$40,$0F,$20
  DEFB $0F,$80,$0F,$E0,$0F,$80,$3F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$FC,$01,$FC,$01
  DEFB $FC,$01,$FC,$01,$FC,$01,$FC,$01
  DEFB $FC,$01,$FC,$00,$FC,$01,$FC,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$F0,$00
  DEFB $C0,$04,$00,$1E,$00,$7D,$00,$FE
  DEFB $00,$FD,$00,$FE,$00,$FD,$00,$F8
  DEFB $00,$E6,$00,$9F,$00,$7F,$00,$FF
  DEFB $00,$7F,$00,$1F,$C0,$06,$F0,$00
  DEFB $FF,$00,$3F,$00,$0F,$80,$03,$40
  DEFB $03,$A8,$03,$50,$03,$A8,$03,$50
  DEFB $03,$A8,$03,$50,$03,$88,$03,$E0
  DEFB $03,$F8,$03,$E0,$0F,$80,$3F,$00
  DEFB $FF,$00,$FC,$00,$F0,$01,$C0,$07
  DEFB $00,$1F,$00,$7F,$00,$7F,$00,$7F
  DEFB $00,$7F,$00,$7E,$00,$79,$00,$67
  DEFB $00,$1F,$00,$7F,$00,$1F,$C0,$07
  DEFB $F0,$01,$FC,$00,$3F,$00,$0F,$00
  DEFB $03,$A0,$00,$50,$00,$AA,$00,$54
  DEFB $00,$AA,$00,$54,$00,$2A,$00,$94
  DEFB $00,$E2,$00,$F8,$00,$FE,$00,$F8
  DEFB $03,$E0,$0F,$80,$3F,$00

; Sprite graphics, table slot $08 (the type 4 missile template)
SpriteGfx08:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$00,$F8,$00,$E0,$03,$E0,$0B
  DEFB $E0,$07,$F0,$07,$E0,$07,$E0,$0F
  DEFB $E0,$03,$F8,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $1F,$00,$0F,$40,$00,$A0,$00,$52
  DEFB $00,$AC,$01,$D4,$01,$E8,$01,$D4
  DEFB $00,$E8,$00,$D2,$00,$C0,$0F,$40
  DEFB $1F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $F0,$00,$F0,$04,$F0,$02,$F8,$01
  DEFB $FC,$01,$F8,$01,$F0,$03,$F0,$04
  DEFB $F0,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$C7,$00,$C7,$10
  DEFB $83,$00,$00,$28,$00,$D4,$00,$EB
  DEFB $00,$F5,$00,$FA,$00,$F5,$00,$FA
  DEFB $00,$F4,$00,$30,$83,$10,$C7,$10
  DEFB $C7,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$1F,$00,$1F,$C0
  DEFB $1F,$00,$7F,$00,$7F,$00,$7F,$00
  DEFB $1F,$00,$1F,$C0,$1F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$00,$FE,$00,$FE,$00,$FF,$00
  DEFB $FE,$00,$FE,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$F1,$00,$E0,$04
  DEFB $80,$0A,$00,$35,$00,$BA,$00,$7D
  DEFB $00,$7E,$00,$7D,$00,$FE,$00,$3D
  DEFB $80,$0C,$E0,$04,$F1,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$00,$0F,$20,$0F,$C0
  DEFB $1F,$40,$1F,$80,$1F,$40,$0F,$80
  DEFB $0F,$20,$0F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$00,$E0,$02,$E0,$0D
  DEFB $C0,$0E,$C0,$1F,$C0,$1F,$C0,$1F
  DEFB $C0,$0F,$E0,$0F,$E0,$03,$F8,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$3F,$00,$0F,$80
  DEFB $0F,$40,$07,$A0,$07,$50,$07,$A0
  DEFB $07,$50,$07,$A0,$0F,$C0,$0F,$80
  DEFB $3F,$00,$FF,$00,$FF,$00

; Sprite graphics, table slots $0A and $0C (the type 6 missile template)
SpriteGfx0A:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$00,$FC,$00,$FC,$01,$F8,$00
  DEFB $E0,$03,$C0,$0C,$C0,$11,$C0,$17
  DEFB $C0,$0F,$E0,$0F,$E0,$07,$F0,$01
  DEFB $FC,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$00,$07,$A0,$07,$50
  DEFB $01,$00,$00,$FC,$00,$03,$00,$F8
  DEFB $00,$FE,$00,$FF,$00,$0F,$00,$0E
  DEFB $00,$F8,$03,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$3F,$00
  DEFB $3F,$80,$3F,$80,$3F,$00,$7F,$00
  DEFB $7F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FE,$00,$F8,$00
  DEFB $F0,$03,$F0,$04,$F0,$05,$F0,$03
  DEFB $F8,$03,$F8,$01,$FC,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$C1,$00,$80,$14
  DEFB $00,$2A,$00,$55,$00,$2A,$00,$00
  DEFB $00,$FF,$00,$00,$00,$7E,$00,$FF
  DEFB $00,$FF,$00,$C3,$00,$C3,$00,$7E
  DEFB $00,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$7F,$00,$7F,$00,$7F,$00
  DEFB $7F,$00,$1F,$00,$0F,$C0,$0F,$20
  DEFB $0F,$A0,$0F,$C0,$1F,$C0,$1F,$80
  DEFB $3F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FE,$00,$FC,$00
  DEFB $FC,$01,$FC,$01,$FC,$00,$FE,$00
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$F0,$00,$E0,$05
  DEFB $C0,$0A,$C0,$15,$80,$00,$00,$3F
  DEFB $00,$C0,$00,$1F,$00,$7F,$00,$FF
  DEFB $00,$F0,$00,$70,$00,$1F,$C0,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$7F,$00
  DEFB $3F,$00,$3F,$80,$3F,$00,$1F,$00
  DEFB $07,$C0,$03,$30,$03,$88,$03,$E8
  DEFB $03,$F0,$07,$F0,$07,$E0,$0F,$80
  DEFB $3F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$F8,$01,$F8,$02
  DEFB $E0,$00,$80,$0F,$00,$30,$00,$47
  DEFB $00,$5F,$00,$3F,$80,$3C,$80,$1C
  DEFB $C0,$07,$F0,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$3F,$00
  DEFB $3F,$80,$07,$00,$01,$F0,$00,$0C
  DEFB $00,$E2,$00,$FA,$00,$FC,$01,$3C
  DEFB $01,$38,$03,$E0,$0F,$00

; Sprite graphics, table slot $0E (the type 7 missile template)
SpriteGfx0E:
  DEFB $FF,$00,$FF,$00,$FE,$00,$FE,$00
  DEFB $F8,$00,$F0,$02,$E0,$05,$E0,$0A
  DEFB $E0,$05,$E0,$07,$C0,$0F,$C0,$1F
  DEFB $C0,$0F,$E0,$07,$F0,$03,$F8,$00
  DEFB $FE,$00,$FF,$00,$1F,$00,$0F,$40
  DEFB $0F,$A0,$03,$40,$03,$A8,$03,$50
  DEFB $03,$20,$00,$F8,$00,$FE,$00,$FF
  DEFB $00,$FF,$00,$FF,$00,$FE,$00,$FC
  DEFB $01,$F0,$07,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$7F,$00
  DEFB $3F,$00,$3F,$80,$3F,$00,$7F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$00,$FC,$00,$FC,$01,$FC,$00
  DEFB $F8,$01,$F0,$03,$F0,$07,$F0,$03
  DEFB $F8,$01,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$83,$00,$83,$28,$83,$10
  DEFB $81,$28,$00,$14,$00,$AA,$00,$55
  DEFB $00,$7E,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$3C
  DEFB $81,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$1F,$00
  DEFB $1F,$40,$1F,$80,$1F,$80,$0F,$C0
  DEFB $0F,$E0,$0F,$C0,$1F,$80,$3F,$00
  DEFB $7F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FE,$00
  DEFB $FC,$00,$FC,$01,$FC,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $F1,$00,$E0,$04,$E0,$0A,$E0,$04
  DEFB $E0,$0A,$E0,$04,$C0,$0A,$00,$1F
  DEFB $00,$7F,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$7F,$00,$3F,$80,$0F,$E0,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$07,$E0,$03,$F0,$03,$F8
  DEFB $03,$F0,$07,$E0,$0F,$C0,$1F,$00
  DEFB $7F,$00,$FF,$00,$FF,$00,$FC,$00
  DEFB $F8,$01,$F8,$02,$F8,$01,$C0,$02
  DEFB $C0,$15,$00,$07,$00,$5F,$00,$3F
  DEFB $00,$7F,$00,$3F,$80,$1F,$C0,$0F
  DEFB $E0,$03,$F8,$00,$FF,$00,$FF,$00
  DEFB $7F,$00,$3F,$00,$3F,$80,$3F,$00
  DEFB $07,$80,$03,$50,$03,$E8,$01,$F8
  DEFB $00,$FC,$00,$FE,$00,$FC,$01,$F8
  DEFB $03,$F0,$07,$C0,$1F,$00

; Sprite graphics, table slots $10 and $12 (the jet templates)
SpriteGfx10:
  DEFB $FF,$00,$FF,$00,$FF,$00,$C0,$00
  DEFB $C0,$16,$C0,$05,$E0,$0E,$E0,$07
  DEFB $F0,$03,$F8,$01,$FC,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$1F,$00,$01,$C0,$00,$2C
  DEFB $00,$A3,$00,$E0,$00,$DC,$00,$0F
  DEFB $00,$67,$00,$31,$80,$18,$C3,$08
  DEFB $E3,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$3F,$80,$3F,$80,$3F,$00
  DEFB $3F,$00,$3F,$80,$3F,$80,$3F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$F0,$00,$F0,$05
  DEFB $F0,$01,$F8,$03,$F8,$01,$FC,$00
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $07,$80,$00,$70,$00,$8B,$00,$E8
  DEFB $00,$F8,$00,$77,$00,$03,$C0,$19
  DEFB $C0,$0C,$E0,$06,$F0,$02,$F8,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$0F,$00
  DEFB $0F,$E0,$0F,$20,$0F,$00,$0F,$C0
  DEFB $0F,$E0,$0F,$60,$0F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$FC,$01,$FC,$00
  DEFB $FE,$00,$FE,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$0F,$00,$01,$60
  DEFB $00,$5C,$00,$E2,$00,$7A,$00,$3E
  DEFB $80,$1D,$C0,$00,$F0,$06,$F0,$03
  DEFB $F8,$01,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$1F,$00,$03,$C0,$03,$38
  DEFB $03,$08,$03,$C0,$03,$F0,$03,$78
  DEFB $03,$18,$03,$80,$3F,$80,$3F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $03,$00,$00,$58,$00,$17,$80,$38
  DEFB $80,$1E,$C0,$0F,$E0,$07,$F0,$00
  DEFB $FC,$01,$FC,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$07,$00
  DEFB $00,$B0,$00,$8E,$00,$82,$00,$70
  DEFB $00,$3C,$00,$9E,$00,$C6,$00,$60
  DEFB $0F,$20,$8F,$00,$FF,$00

; Sprite graphics, table slot $16
SpriteGfx16:
  DEFB $E0,$00,$C0,$0D,$C0,$10,$C0,$0D
  DEFB $C0,$10,$C0,$0D,$C0,$10,$C0,$0D
  DEFB $C0,$10,$C0,$0F,$C0,$1F,$C0,$0F
  DEFB $E0,$00,$7F,$00,$3F,$00,$3F,$80
  DEFB $3F,$00,$3F,$80,$3F,$00,$3F,$80
  DEFB $3F,$00,$3F,$80,$3F,$00,$3F,$80
  DEFB $3F,$00,$7F,$00,$F8,$00,$F0,$03
  DEFB $F0,$04,$F0,$03,$F0,$04,$F0,$03
  DEFB $F0,$04,$F0,$03,$F0,$04,$F0,$03
  DEFB $F0,$07,$F0,$03,$F8,$00,$1F,$00
  DEFB $0F,$40,$0F,$20,$0F,$40,$0F,$20
  DEFB $0F,$40,$0F,$20,$0F,$40,$0F,$20
  DEFB $0F,$C0,$0F,$E0,$0F,$C0,$1F,$00
  DEFB $FE,$00,$FC,$00,$FC,$01,$FC,$00
  DEFB $FC,$01,$FC,$00,$FC,$01,$FC,$00
  DEFB $FC,$01,$FC,$00,$FC,$01,$FC,$00
  DEFB $FE,$00,$07,$00,$03,$D0,$03,$08
  DEFB $03,$D0,$03,$08,$03,$D0,$03,$08
  DEFB $03,$D0,$03,$08,$03,$F0,$03,$F8
  DEFB $03,$F0,$07,$00,$81,$00,$00,$34
  DEFB $00,$42,$00,$34,$00,$42,$00,$34
  DEFB $00,$42,$00,$34,$00,$42,$00,$3C
  DEFB $00,$7E,$00,$3C,$81,$00

; Sprite graphics, table slot $18 (shots: templates $C360, $C2E1)
SpriteGfx18:
  DEFB $FF,$00,$FF,$00,$E3,$00,$C0,$18
  DEFB $E0,$06,$F0,$01,$E0,$00,$C0,$18
  DEFB $E0,$06,$F0,$01,$FC,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$7F,$00,$3F,$80,$7F,$00
  DEFB $FF,$00,$7F,$00,$3F,$80,$7F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $F8,$00,$F0,$06,$F8,$01,$FC,$00
  DEFB $F8,$00,$F0,$06,$F8,$01,$FC,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$3F,$00,$1F,$80
  DEFB $0F,$60,$1F,$00,$3F,$00,$1F,$80
  DEFB $0F,$60,$1F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FE,$00,$FC,$01
  DEFB $FE,$00,$FF,$00,$FE,$00,$FC,$01
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$00
  DEFB $0F,$80,$07,$60,$03,$18,$07,$00
  DEFB $0F,$80,$07,$60,$03,$18,$C7,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $8F,$00,$03,$60,$81,$18,$C0,$06
  DEFB $81,$00,$03,$60,$81,$18,$C0,$06
  DEFB $F1,$00,$FF,$00,$FF,$00

; Sprite graphics, table slot $1A (the shell: template $C370)
SpriteGfx1A:
  DEFB $FF,$00,$FF,$00,$F0,$00,$E0,$0A
  DEFB $C0,$1D,$C0,$1E,$C0,$1D,$C0,$1E
  DEFB $E0,$0F,$F0,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $7F,$00,$3F,$00,$3F,$80,$3F,$00
  DEFB $3F,$80,$7F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FC,$00,$F8,$02,$F0,$07,$F0,$07
  DEFB $F0,$07,$F0,$07,$F8,$03,$FC,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$00,$1F,$80,$0F,$40
  DEFB $0F,$A0,$0F,$40,$0F,$A0,$1F,$C0
  DEFB $3F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FE,$00
  DEFB $FC,$01,$FC,$01,$FC,$01,$FC,$01
  DEFB $FE,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$0F,$00
  DEFB $07,$A0,$03,$D0,$03,$E8,$03,$D0
  DEFB $03,$E8,$07,$F0,$0F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $C3,$00,$81,$28,$00,$74,$00,$7A
  DEFB $00,$74,$00,$7A,$81,$3C,$C3,$00
  DEFB $FF,$00,$FF,$00,$FF,$00

; Explosion frame, table slot $22
;
; The explosion: a hit record's byte +8 is set to $20 ($EBD1, $E262) and counts
; up by 2 a pass to $2C ($E235), so the frames are the slots $20-$2C; slot $20
; and $24 share one picture.
ExplosionGfx22:
  DEFB $FF,$00,$FF,$00,$FC,$00,$F0,$01
  DEFB $E0,$05,$C0,$0A,$C0,$15,$C0,$0B
  DEFB $C0,$0D,$80,$15,$80,$3B,$80,$3F
  DEFB $80,$1F,$80,$2F,$80,$16,$C0,$1F
  DEFB $C0,$06,$F0,$00,$FE,$00,$FF,$00
  DEFB $FF,$00,$FC,$00,$10,$01,$00,$46
  DEFB $00,$AF,$00,$7F,$00,$F7,$00,$FB
  DEFB $00,$F7,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$FF,$00,$EF,$00,$5F,$00,$BF
  DEFB $00,$7F,$00,$FF,$00,$FF,$00,$6A
  DEFB $00,$15,$C0,$00,$0F,$00,$00,$60
  DEFB $00,$AA,$00,$55,$00,$FB,$00,$FE
  DEFB $00,$FD,$00,$FA,$00,$FF,$00,$FF
  DEFB $00,$DF,$00,$EF,$00,$F3,$00,$ED
  DEFB $00,$F7,$00,$FF,$00,$FC,$01,$F8
  DEFB $03,$F0,$07,$40,$1F,$00,$FF,$00
  DEFB $FF,$00,$7F,$00,$7F,$00,$3F,$00
  DEFB $0F,$80,$07,$60,$07,$F0,$07,$D0
  DEFB $07,$E0,$07,$D0,$07,$E0,$07,$D0
  DEFB $07,$A0,$0F,$60,$0F,$80,$3F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00

; Explosion frame, table slots $20 and $24
ExplosionGfx20:
  DEFB $FE,$00,$F0,$00,$E0,$05,$E0,$0A
  DEFB $E0,$05,$E0,$0A,$80,$05,$00,$2A
  DEFB $00,$55,$00,$2A,$80,$17,$80,$2A
  DEFB $80,$15,$C0,$0B,$E0,$05,$F0,$02
  DEFB $F8,$01,$F8,$02,$F8,$00,$FF,$00
  DEFB $FF,$00,$20,$00,$00,$8A,$00,$55
  DEFB $00,$AA,$00,$55,$00,$AA,$00,$57
  DEFB $00,$AB,$00,$7F,$00,$FF,$00,$FF
  DEFB $00,$FF,$00,$D7,$00,$BF,$00,$7D
  DEFB $00,$AF,$00,$55,$00,$AE,$00,$55
  DEFB $00,$0A,$E0,$00,$83,$00,$00,$28
  DEFB $00,$15,$00,$AA,$00,$55,$00,$AA
  DEFB $00,$D5,$00,$FA,$00,$75,$00,$FF
  DEFB $00,$FE,$00,$FB,$00,$F5,$00,$FE
  DEFB $00,$DD,$00,$EA,$00,$7D,$00,$AA
  DEFB $00,$54,$01,$A0,$0F,$00,$FF,$00
  DEFB $7F,$00,$3F,$00,$07,$80,$07,$50
  DEFB $07,$A0,$03,$50,$03,$A8,$03,$50
  DEFB $03,$A8,$03,$D0,$07,$E0,$07,$50
  DEFB $07,$A0,$0F,$40,$1F,$80,$1F,$40
  DEFB $1F,$80,$3F,$00,$FF,$00,$FF,$00

; Explosion frame, table slot $26
ExplosionGfx26:
  DEFB $FF,$00,$FF,$00,$FC,$00,$E0,$01
  DEFB $E0,$08,$E0,$05,$F0,$00,$F0,$04
  DEFB $F0,$02,$F8,$01,$F0,$00,$F0,$05
  DEFB $F0,$02,$F8,$00,$FE,$00,$FE,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$C7,$00,$82,$10,$00,$28
  DEFB $00,$14,$00,$B9,$00,$5B,$00,$A9
  DEFB $00,$56,$00,$EF,$00,$5F,$00,$AF
  DEFB $00,$5F,$00,$AF,$00,$57,$00,$B2
  DEFB $00,$45,$00,$2A,$80,$01,$FC,$00
  DEFB $FF,$00,$FF,$00,$1F,$00,$08,$40
  DEFB $00,$E2,$00,$51,$00,$A2,$00,$89
  DEFB $00,$22,$00,$D6,$00,$E6,$00,$F4
  DEFB $00,$F2,$00,$F5,$00,$E8,$00,$D5
  DEFB $00,$AA,$00,$14,$00,$8A,$00,$50
  DEFB $07,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$3F,$80,$3F,$00,$1F,$80
  DEFB $1F,$40,$1F,$80,$1F,$C0,$1F,$00
  DEFB $1F,$40,$1F,$80,$3F,$00,$3F,$80
  DEFB $3F,$00,$7F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00

; Explosion frame, table slot $28
ExplosionGfx28:
  DEFB $FF,$00,$FF,$00,$FE,$00,$F0,$00
  DEFB $F0,$04,$F0,$02,$F8,$02,$F8,$00
  DEFB $F8,$02,$F8,$00,$F8,$02,$F8,$01
  DEFB $FC,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$00,$C0,$09,$00,$13
  DEFB $00,$B5,$00,$90,$00,$15,$00,$83
  DEFB $00,$57,$00,$8B,$00,$53,$00,$2A
  DEFB $00,$41,$00,$0A,$00,$51,$00,$04
  DEFB $F1,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$00,$00,$28
  DEFB $00,$E0,$00,$43,$00,$2B,$00,$41
  DEFB $00,$8A,$00,$D4,$00,$A0,$00,$85
  DEFB $00,$A9,$00,$42,$00,$A8,$02,$30
  DEFB $07,$40,$1F,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $3F,$00,$3F,$80,$0F,$00,$0F,$20
  DEFB $0F,$20,$0F,$80,$0F,$20,$0F,$80
  DEFB $1F,$40,$1F,$00,$3F,$00,$3F,$80
  DEFB $3F,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00

; Explosion frame, table slot $2A
ExplosionGfx2A:
  DEFB $FF,$00,$FE,$00,$FE,$00,$F8,$00
  DEFB $F8,$02,$F8,$00,$F8,$01,$FC,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$C4,$00,$00,$11,$00,$A4
  DEFB $00,$00,$00,$51,$00,$03,$60,$01
  DEFB $60,$08,$80,$05,$80,$20,$8F,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$00,$47,$00
  DEFB $00,$10,$00,$84,$00,$51,$00,$A4
  DEFB $00,$00,$18,$42,$00,$00,$63,$08
  DEFB $E3,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$00,$3F,$80,$3F,$00
  DEFB $3F,$00,$3F,$80,$3F,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00

; Explosion frame, table slot $2C (the last before the record is gone)
ExplosionGfx2C:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$E3,$00,$E2,$08
  DEFB $E0,$00,$88,$01,$88,$22,$80,$01
  DEFB $E0,$08,$E3,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$8F,$00
  DEFB $0F,$20,$03,$80,$23,$08,$23,$80
  DEFB $07,$00,$47,$10,$C7,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
