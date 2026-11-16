; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The graphics and tables: sprites, the font, the perspective and edge tables, the big digits, the bend profiles, the horizons, the track tables
;
; Everything here is read through the descriptors and routines named in each entry; the editable forms are in src/res
; (each folder's README). Bytes no routine reads are kept as documented leftovers.
; --------------------------------------------------------------------------------------------------------------------

; $690F-$6BE7: 729 bytes no instruction reads in any recording (a repeated word
; pattern, an older table)
;
; L1's byte use has no read here in the seven recordings; no instruction's
; operand points into it.
Leftover690F:
  DEFB $57,$C2,$57,$48,$57,$B8,$57,$3E
  DEFB $57,$C2,$57,$48,$57,$B8,$57,$3E
  DEFB $57,$C2,$57,$48,$57,$B8,$57,$3E
  DEFB $57,$C2,$57,$48,$57,$B8,$57,$3E
  DEFB $57,$C2,$57,$48,$57,$B8,$57,$3E
  DEFB $36,$3A,$36,$3A,$36,$3A,$36,$3A
  DEFB $36,$3A,$36,$3A,$36,$3A,$36,$3A
  DEFB $36,$3A,$36,$3A,$36,$3A,$36,$3A
  DEFB $36,$3A,$36,$3A,$36,$3A,$36,$3A
  DEFB $36,$3A,$36,$3A,$36,$3A,$36,$3A
  DEFB $36,$3A,$36,$3A,$36,$3A,$36,$3A
  DEFB $36,$3A,$36,$3A,$36,$3A,$36,$3A
  DEFB $36,$3A,$36,$3A,$00,$1F,$14,$18
  DEFB $D8,$80,$80,$9C,$9C,$91,$95,$90
  DEFB $94,$91,$91,$91,$90,$9C,$8D,$81
  DEFB $80,$82,$80,$80,$84,$80,$80,$8C
  DEFB $8E,$82,$86,$80,$92,$9C,$8E,$80
  DEFB $A0,$8C,$8E,$82,$84,$95,$91,$9D
  DEFB $9D,$90,$92,$92,$92,$9C,$9C,$83
  DEFB $8F,$8C,$81,$85,$85,$81,$80,$A0
  DEFB $80,$91,$91,$91,$90,$90,$92,$92
  DEFB $92,$92,$90,$81,$81,$81,$81,$80
  DEFB $83,$83,$80,$80,$80,$92,$92,$92
  DEFB $90,$B0,$90,$86,$86,$84,$91,$9D
  DEFB $9D,$91,$90,$9F,$9F,$90,$94,$93
  DEFB $90,$87,$84,$81,$81,$85,$84,$80
  DEFB $9E,$9E,$92,$90,$B0,$90,$82,$86
  DEFB $84,$81,$89,$80,$96,$96,$96,$92
  DEFB $9A,$90,$94,$87,$83,$8B,$88,$91
  DEFB $95,$94,$94,$85,$81,$89,$89,$81
  DEFB $89,$88,$80,$FF,$FF,$88,$80,$FF
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$0F
  DEFB $00,$1F,$14,$18,$D8,$18,$00,$18
  DEFB $28,$18,$19,$18,$F6,$18,$DD,$14
  DEFB $14,$14,$DE,$14,$17,$14,$FC,$14
  DEFB $21,$14,$F6,$14,$2E,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$0F,$00,$1F
  DEFB $14,$18,$D8,$18,$00,$18,$28,$18
  DEFB $19,$18,$F6,$18,$DD,$14,$14,$14
  DEFB $DE,$14,$17,$14,$FC,$14,$21,$14
  DEFB $F6,$14,$2E,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$0F,$00,$1F,$14,$18
  DEFB $D8,$18,$00,$18,$28,$18,$19,$18
  DEFB $F6,$18,$DD,$14,$14,$14,$DE,$14
  DEFB $17,$14,$FC,$14,$21,$14,$F6,$14
  DEFB $2E,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$0F,$00,$1F,$14,$18,$D8,$18
  DEFB $00,$18,$28,$18,$19,$18,$F6,$18
  DEFB $DD,$14,$14,$14,$DE,$14,$17,$14
  DEFB $FC,$14,$21,$14,$F6,$14,$2E,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$36
  DEFB $3A,$36,$3A,$36,$3A,$36,$3A,$28
  DEFB $42,$28,$C0,$28,$42,$28,$C0,$28
  DEFB $42,$28,$C0,$28,$42,$28,$C0,$28
  DEFB $42,$00,$00,$28,$C0,$28,$42,$28
  DEFB $C0,$28,$42,$28,$C0,$28,$42,$28
  DEFB $C0,$28,$42,$28,$C0,$28,$42,$28
  DEFB $C0,$28,$42,$00,$00,$18,$BA,$1C
  DEFB $7F,$19,$BC,$1B,$50,$17,$B4,$1C
  DEFB $58,$1C,$B2,$16,$4A,$16,$9C,$12
  DEFB $4B,$16,$AB,$18,$42,$14,$B2,$1A
  DEFB $44,$00,$00,$18,$BA,$1C,$7F,$19
  DEFB $BC,$1B,$50,$17,$B4,$1C,$58,$1C
  DEFB $B2,$16,$4A,$16,$9C,$12,$4B,$16
  DEFB $AB

; The roadside objects' sprites (ObjectTypes' lists point into $6BE8-$75AF),
; and the bike's dust and splash elsewhere
;
; src/res/sprites/objects.png and .csv (tools/res_formats.py: every
; descriptor's sprite on a sheet).
ObjectSprites:
  INCBIN "res/sprites/objects.bin",$0000,2504

; 39 bytes RoadRowsOld points IX at: read by no recording
RoadRowsOldData:
  DEFB $FE,$82,$9E,$83,$F9,$B9,$43,$3E
  DEFB $7E,$C2,$9E,$83,$99,$99,$43,$3E
  DEFB $FF,$81,$B9,$F9,$12,$12,$12,$1E
  DEFB $7E,$C3,$99,$42,$99,$99,$C3,$7E
  DEFB $3C,$42,$B9,$B9,$C1,$79,$42

; BlendBend's steps: 16 rows of slowly rising values (49 bytes to $7607)
BendBlend:
  INCBIN "res/tables/bendblend.bin",$0000,49

; The 8x8 font, characters $20-$5E (PrintChar's base $7508 = Font - $100: code
; - $20 rows of 8)
;
; 63 characters; a $5F would read Perspective's first bytes. The frame pieces,
; the arrows, km/h and UP are among them (src/res/font/font.png, the order of
; the codes).
Font:
  INCBIN "res/font/font.bin",$0000,504

; Each of the 128 road rows' depth (the far row first: $9F ... $11), the road's
; perspective
Perspective:
  INCBIN "res/tables/perspective.bin",$0000,128

; The road edge's 3-byte patterns, 8 pixel shifts for each of 16 widths
; (DrawRoad, near rows)
EdgePatterns:
  INCBIN "res/tables/edges.bin",$0000,384

; The crest's change of each row's screen line (RoadRowsCrest: perspective *
; crest table / 512)
CrestTable:
  INCBIN "res/tables/crest.bin",$0000,128

; The second set of edge patterns (DrawRoad, chosen by bit 2 of the row)
EdgePatterns2:
  INCBIN "res/tables/edges2.bin",$0000,384

; The countdown's glyphs: G, O (8 lines each), then 1, 2, 3 (10 lines each) for
; CountGlyph
CountGlyphs:
  INCBIN "res/tables/countglyphs.bin",$0000,46

; The passes, + 1 each (the wheel animation's and the HUD's beat)
;
; The variables $7C2E-$7C53 are zeros in the image.
PassCount:
  DEFB $00
Beeper:
  DEFB $00                ; $FF on the 48K (the ROM test), 0 on the 128K
DemoMode:
  DEFB $00                ; a demo's segments left (8-15 at the start), 0 in a
                          ; game
GetUp:
  DEFB $00                ; the getting-up slide (LateralX toward 0)
Players:
  DEFB $00                ; 1 or 2
Speed:
  DEFB $00,$00            ; SPEED, 8.8 km/h ($7C34 the whole part, 0-199: the
                          ; throttle's curve nears $C800 and never reaches it)
TotalTime:
  DEFB $00,$00,$00        ; the player's total (minutes, seconds, hundredths)
SavedSp:
  DEFB $00,$00            ; SP while a routine uses it as a pointer
InGap:
  DEFB $00                ; the bike over stage 3's gap (GapRows)
  DEFB $00                ; unused (2 bytes)
ScoreDigits:
  DEFB $00,$00,$00,$00,$00,$00,$00 ; 7 digits (0-9) AddScore adds, read back
                                   ; from $7C42: the speed's each pass, the
                                   ; time bonus at $7C3D (with $7C3F-$7C42 as
                                   ; the last ScoreAdd left them: the bonus
                                   ; carries that pass's speed points)
  DEFB $00,$00,$00        ; unused
RunLines:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; DrawRoadRun's work: lines, x positions
  DEFB $00,$00,$00,$00,$00             ; and slopes ($7C46-$7C52)
ExtendedTime:
  DEFB $00                ; EXTENDED PLAY's flashing passes

; The ten big digits, 15 lines of 2 bytes (16 x 15 pixels) each (BigDigit)
BigDigits:
  INCBIN "res/font/bigdigits.bin",$0000,300

; The three bends' profiles, each row's sideways shift, 128 rows each
; (ScrollBends: $7D80 + 128 * (bend - 1))
BendProfiles:
  INCBIN "res/tables/bends.bin",$0000,384

; Two tables of 128 a road row: $7F00 + row the row's scale (edge pattern,
; sideways scale), $7F80 + row its half width
RowScale:
  INCBIN "res/tables/rowscale.bin",$0000,256

  ORG $B11D

; $B11D-$B1FF: 227 bytes of an older build's code (LD ($B1BA),A ...), never run
; or read
;
; They disassemble as code addressing $B1xx; no instruction of the game points
; here and L1 has no run or read (the seven recordings).
LeftoverCode:
  DEFB $80,$B1,$3D,$32,$BA,$B1,$DD,$7E
  DEFB $00,$4F,$F6,$80,$6F,$26,$7F,$7E
  DEFB $32,$61,$B1,$26,$5B,$7E,$69,$26
  DEFB $7F,$6E,$FE,$FF,$CA,$EA,$B1,$C6
  DEFB $00,$0E,$00,$30,$08,$CB,$7F,$CA
  DEFB $EA,$B1,$ED,$44,$0C,$CD,$AE,$8B
  DEFB $EB,$29,$29,$CB,$7C,$C2,$EA,$B1
  DEFB $7C,$0D,$20,$02,$ED,$44,$C6,$80
  DEFB $32,$7B,$B1,$06,$00,$CB,$38,$90
  DEFB $38,$03,$32,$80,$B1,$80,$80,$38
  DEFB $03,$32,$BA,$B1,$C1,$21,$00,$00
  DEFB $23,$CB,$AC,$7E,$AD,$C6,$00,$22
  DEFB $73,$B1,$FE,$00,$30,$36,$4F,$3A
  DEFB $23,$5E,$FE,$04,$38,$51,$21,$80
  DEFB $B1,$3A,$BA,$B1,$96,$ED,$44,$86
  DEFB $B9,$38,$2D,$79,$E6,$F8,$1F,$1F
  DEFB $1F,$2A,$CC,$B1,$B5,$6F,$79,$E6
  DEFB $07,$58,$47,$3E,$FF,$0E,$00,$28
  DEFB $05,$1F,$CB,$19,$10,$FB,$43,$77
  DEFB $2C,$71,$18,$23,$FE,$00,$30,$1F
  DEFB $4F,$3A,$23,$5E,$FE,$02,$20,$17
  DEFB $79,$E6,$F8,$1F,$1F,$1F,$21,$00
  DEFB $00,$B5,$6F,$79,$E6,$07,$C6,$7D
  DEFB $5F,$16,$9D,$1A,$3C,$B6,$77,$10
  DEFB $94,$FD,$2B,$FD,$2B,$DD,$2B,$08
  DEFB $3D,$C2,$F6,$B0,$C9,$3A,$2D,$5E
  DEFB $A7,$3E,$FF,$28,$01,$3C,$32,$80
  DEFB $B1,$32,$BA,$B1,$C3,$71,$B1,$00
  DEFB $02,$00,$02

; The IM 2 vector table, 257 bytes: Init fills it with $64 (vector $6464 =
; IntVector); the image holds older graphics here
Im2Table:
  DEFB $E6,$00,$10,$E6,$00,$10,$E6,$00,$18,$A6,$00,$18,$EE,$00,$18,$BA
  DEFB $40,$98,$D6,$40,$98,$BC,$40,$98,$D4,$40,$94,$AC,$C0,$94,$DC,$C0
  DEFB $DC,$AC,$C0,$CA,$D8,$C0,$CA,$B8,$C0,$CA,$D8,$C0,$CB,$B8,$C0,$CD
  DEFB $58,$C0,$A4,$A9,$40,$A5,$59,$40,$56,$A9,$40,$53,$79,$40,$51,$39
  DEFB $40,$51,$79,$40,$51,$3A,$C0,$49,$7A,$C0,$65,$3C,$80,$33,$51,$80
  DEFB $28,$E3,$80,$35,$D5,$00,$1A,$EB,$00,$1D,$57,$00,$1A,$AE,$00,$0D
  DEFB $16,$00,$0E,$AE,$00,$07,$1E,$00,$06,$BE,$00,$03,$5C,$00,$02,$BC
  DEFB $00,$02,$7C,$00,$02,$BC,$00,$01,$7C,$00,$01,$3C,$00,$01,$7C,$00
  DEFB $01,$3C,$00,$01,$7C,$00,$01,$3C,$00,$01,$5C,$00,$01,$3C,$00,$01
  DEFB $5C,$00,$01,$2C,$00,$01,$5C,$00,$01,$3C,$00,$01,$5C,$00,$02,$BC
  DEFB $00,$02,$5C,$00,$02,$BE,$00,$02,$5E,$00,$02,$BE,$00,$02,$5E,$00
  DEFB $02,$BE,$00,$05,$5E,$00,$04,$BE,$00,$05,$5F,$00,$04,$BF,$00,$09
  DEFB $5F,$00,$0A,$BF,$00,$09,$5F,$00,$0A,$AF,$00,$15,$5F,$00,$12,$AF
  DEFB $C0,$15,$57,$F0,$0E,$AF,$F8,$03,$FF,$F0,$00,$80,$00,$80,$00,$80
  DEFB $00,$80,$00,$80,$00,$80,$00,$80,$08,$80,$08,$80,$09,$80,$09,$80
  DEFB $0D,$90,$0D,$90,$0D,$90,$0D,$90,$07,$90,$05,$90,$02,$90,$11,$90
  DEFB $11

; 5 bytes between the table and the sprites ($90 $11 ...), never read
Gap5:
  DEFB $90,$11,$90,$11,$90

; The bike's, the riders', the trucks' and the splash and dust sprites
; ($B306-$E2BF), drawn through the descriptors
;
; BikePoses, RiderSprites, DrawSplash and DrawDust point into it. reset3's
; crash ran through $D253-$D26A as code (the bytes of a sprite);
; src/res/sprites/.
Sprites:
  INCBIN "res/sprites/sprites.bin",$0000,12218

; Stage 3's horizon, 25 lines of 32 bytes
Dunes:
  INCBIN "res/horizons/dunes.bin",$0000,800

; Stages 1 and 4's horizon, 32 lines
Mountains:
  INCBIN "res/horizons/mountains.bin",$0000,1024

; Stages 2 and 5's horizon, 9 lines
Clouds:
  INCBIN "res/horizons/clouds.bin",$0000,288

; StageList, TrackPatterns and Track as loaded (1456 bytes): Init copies them
; to $5E80; then the back buffer's first rows
;
; $EB00-$EB8B StageList (140 segments), $EB8C-$ED4F the patterns, $ED50-$F0AF
; the track. src/res/track/ (tools/course.py draws each stage).
TrackTables:
  INCBIN "res/track/tables.bin",$0000,1456

; $F0B0-$F5BF: 1296 bytes of older graphics under the back buffer, overwritten
; before any read
OldGraphics:
  DEFB $BF,$EB,$BB,$EB,$EA,$83,$FF,$FE
  DEFB $AB,$BB,$EA,$0F,$FF,$DF,$BB,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00
  DEFB $01,$FF,$FC,$00,$00,$00,$00,$32
  DEFB $00,$00,$00,$07,$00,$7F,$00,$1F
  DEFB $20,$00,$00,$C0,$FF,$80,$40,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $07,$7D,$47,$5F,$55,$1F,$FF,$51
  DEFB $14,$00,$00,$F5,$01,$FF,$55,$70
  DEFB $45,$3D,$FD,$10,$FF,$FB,$AC,$7F
  DEFB $20,$C0,$00,$00,$00,$0F,$EF,$1C
  DEFB $9D,$F0,$05,$D7,$57,$57,$D5,$05
  DEFB $5D,$54,$FF,$F7,$95,$41,$5F,$FD
  DEFB $35,$FF,$F5,$05,$71,$FF,$1D,$17
  DEFB $01,$41,$00,$00,$07,$FF,$54,$3F
  DEFB $FF,$FF,$F5,$5F,$F7,$55,$5F,$F5
  DEFB $D7,$D5,$75,$5F,$FF,$F5,$51,$07
  DEFB $D7,$F7,$75,$FF,$FF,$51,$FF,$FF
  DEFB $57,$5D,$DD,$9F,$FF,$AF,$F7,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$97
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $56,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$B7
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $56,$00,$00,$00,$00,$00,$00,$00
  DEFB $07,$FF,$FF,$00,$00,$00,$00,$69
  DEFB $00,$00,$00,$08,$80,$FF,$F0,$7F
  DEFB $90,$00,$01,$E1,$FF,$C0,$A0,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $A2,$FA,$8E,$2A,$AA,$8F,$FF,$A8
  DEFB $8A,$00,$01,$EA,$88,$FE,$AA,$E1
  DEFB $CA,$9F,$FE,$38,$7F,$F7,$5C,$3F
  DEFB $91,$A0,$00,$00,$00,$1F,$5F,$8E
  DEFB $AE,$B0,$0A,$FE,$AF,$AF,$EA,$82
  DEFB $AA,$AB,$FF,$FB,$82,$80,$EF,$FA
  DEFB $AA,$EF,$EA,$AA,$B8,$FE,$3E,$2B
  DEFB $80,$A0,$80,$00,$0F,$FF,$88,$7F
  DEFB $FF,$FF,$EE,$AF,$FA,$EE,$AA,$FF
  DEFB $EF,$FF,$EA,$FF,$FF,$FA,$AA,$A3
  DEFB $FF,$FA,$AE,$BF,$FF,$FF,$FF,$FF
  DEFB $AB,$AE,$BE,$7F,$FF,$DF,$BF,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00
  DEFB $1F,$FF,$FF,$C0,$00,$00,$00,$B0
  DEFB $80,$00,$00,$08,$41,$FF,$FE,$BF
  DEFB $08,$00,$03,$F7,$FF,$F1,$D0,$00
  DEFB $00,$00,$00,$00,$00,$00,$3C,$00
  DEFB $51,$F5,$DF,$05,$05,$4F,$FF,$45
  DEFB $47,$00,$03,$F5,$1C,$7D,$57,$E7
  DEFB $D5,$0F,$D7,$7D,$3F,$EA,$BC,$1F
  DEFB $CB,$20,$00,$00,$00,$3E,$AF,$87
  DEFB $F7,$50,$45,$7D,$5F,$D7,$55,$51
  DEFB $5D,$55,$FF,$DD,$45,$00,$5F,$FF
  DEFB $55,$F5,$DD,$75,$5C,$7C,$5D,$11
  DEFB $D4,$50,$40,$00,$1F,$AF,$C0,$FF
  DEFB $FF,$FF,$FF,$7F,$FD,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$D5,$54
  DEFB $7F,$FD,$5F,$7F,$FF,$FF,$FF,$FF
  DEFB $FD,$FF,$FF,$1F,$FF,$FF,$DF,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$97
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $56,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$B7
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $55,$55,$55,$55,$55,$55,$55,$55
  DEFB $56,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF,$FA,$FF,$F0,$06,$00,$01,$E8
  DEFB $40,$00,$00,$1C,$23,$FF,$FF,$7E
  DEFB $86,$00,$07,$DF,$FF,$FB,$C8,$00
  DEFB $00,$00,$00,$00,$00,$00,$C2,$18
  DEFB $B8,$EB,$8B,$8A,$22,$E7,$FE,$8E
  DEFB $82,$80,$07,$FB,$8E,$2A,$BF,$EF
  DEFB $A0,$07,$AB,$EB,$9F,$D5,$78,$0E
  DEFB $06,$90,$00,$00,$00,$7D,$5F,$E3
  DEFB $EF,$A9,$E2,$AA,$AF,$EA,$AE,$A3
  DEFB $BE,$AA,$FF,$AE,$AA,$A0,$3B,$FF
  DEFB $EA,$BA,$BE,$FA,$BE,$3A,$BE,$82
  DEFB $E8,$28,$20,$00,$7F,$57,$E0,$AF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FA,$AA
  DEFB $03,$FE,$BF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$83,$FF,$FF,$FF,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $AA,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FE,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF,$F5,$5F,$FC,$05,$00,$03,$D4
  DEFB $20,$00,$00,$3C,$17,$FF,$FE,$F5
  DEFB $43,$00,$0F,$CF,$FF,$FF,$A4,$00
  DEFB $00,$00,$00,$00,$00,$01,$01,$37
  DEFB $D4,$77,$C5,$C0,$71,$73,$FD,$1F
  DEFB $D1,$40,$0F,$F7,$17,$15,$FF,$DF
  DEFB $44,$13,$55,$D1,$CF,$AA,$F0,$07
  DEFB $11,$50,$00,$00,$00,$FE,$BD,$41
  DEFB $DF,$57,$F1,$55,$57,$F5,$5F,$45
  DEFB $FF,$77,$7F,$57,$75,$40,$0F,$FF
  DEFB $F5,$5D,$57,$F5,$5F,$15,$5F,$51
  DEFB $91,$50,$10,$00,$FE,$EB,$D1,$5F
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$55
  DEFB $54,$1F,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; $F5C0-$FDFF: zeros; the back buffer (lines 40-191) spans $EB00-$FDFF in play
BackBuffer:
  DEFS $0840

; The address of each of the 192 pixel lines: the screen's, or the back
; buffer's after SetRowTable $A600
RowTable:
  DEFW $4000,$4100,$4200,$4300,$4400,$4500,$4600,$4700
  DEFW $4020,$4120,$4220,$4320,$4420,$4520,$4620,$4720
  DEFW $4040,$4140,$4240,$4340,$4440,$4540,$4640,$4740
  DEFW $4060,$4160,$4260,$4360,$4460,$4560,$4660,$4760
  DEFW $4080,$4180,$4280,$4380,$4480,$4580,$4680,$4780
  DEFW $40A0,$41A0,$42A0,$43A0,$44A0,$45A0,$46A0,$47A0
  DEFW $40C0,$41C0,$42C0,$43C0,$44C0,$45C0,$46C0,$47C0
  DEFW $40E0,$41E0,$42E0,$43E0,$44E0,$45E0,$46E0,$47E0
  DEFW $4800,$4900,$4A00,$4B00,$4C00,$4D00,$4E00,$4F00
  DEFW $4820,$4920,$4A20,$4B20,$4C20,$4D20,$4E20,$4F20
  DEFW $4840,$4940,$4A40,$4B40,$4C40,$4D40,$4E40,$4F40
  DEFW $4860,$4960,$4A60,$4B60,$4C60,$4D60,$4E60,$4F60
  DEFW $4880,$4980,$4A80,$4B80,$4C80,$4D80,$4E80,$4F80
  DEFW $48A0,$49A0,$4AA0,$4BA0,$4CA0,$4DA0,$4EA0,$4FA0
  DEFW $48C0,$49C0,$4AC0,$4BC0,$4CC0,$4DC0,$4EC0,$4FC0
  DEFW $48E0,$49E0,$4AE0,$4BE0,$4CE0,$4DE0,$4EE0,$4FE0
  DEFW $5000,$5100,$5200,$5300,$5400,$5500,$5600,$5700
  DEFW $5020,$5120,$5220,$5320,$5420,$5520,$5620,$5720
  DEFW $5040,$5140,$5240,$5340,$5440,$5540,$5640,$5740
  DEFW $5060,$5160,$5260,$5360,$5460,$5560,$5660,$5760
  DEFW $5080,$5180,$5280,$5380,$5480,$5580,$5680,$5780
  DEFW $50A0,$51A0,$52A0,$53A0,$54A0,$55A0,$56A0,$57A0
  DEFW $50C0,$51C0,$52C0,$53C0,$54C0,$55C0,$56C0,$57C0
  DEFW $50E0,$51E0,$52E0,$53E0,$54E0,$55E0,$56E0,$57E0

; $FF80-$FFFF: the loader's leftovers (Stage0's copy, ROM glyphs); the game's
; stack below SP = 0
;
; Init sets SP = 0: the pushes go to $FFFF down (WALKTHROUGH 1: $FFE4-$FFFF
; used).
StackArea:
  DEFB $00,$60,$00,$41,$00,$42,$00,$43
  DEFB $00,$44,$00,$45,$00,$46,$00,$47
  DEFB $00,$42,$42,$7E,$42,$42,$42,$00
  DEFB $00,$3E,$08,$08,$08,$08,$3E,$00
  DEFB $00,$02,$02,$02,$42,$42,$3C,$00
  DEFB $00,$44,$48,$70,$48,$44,$42,$00
  DEFB $00,$40,$40,$40,$40,$40,$7E,$00
  DEFB $00,$42,$66,$5A,$42,$42,$42,$00
  DEFB $91,$57,$DE,$00,$00,$00,$00,$00
  DEFB $00,$00,$42,$42,$42,$42,$3C,$00
  DEFB $00,$7C,$DB,$02,$4D,$00,$00,$80
  DEFB $02,$ED,$6F,$18,$02,$ED,$01,$01
  DEFB $5C,$18,$3F,$FE,$FB,$9F,$7F,$FF
  DEFB $1D,$8B,$7F,$FF,$1D,$8B,$42,$01
  DEFB $4A,$8A,$55,$84,$CE,$84,$78,$07
  DEFB $08,$00,$EA,$80,$65,$33,$90,$61
