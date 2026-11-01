; Course tiles 0-22, 8 x 8 bytes
;
; The tile set of the course: 72 tiles of 8 bytes at $C400 + 8 x tile, one byte
; (8 pixels) a line, the first byte at the bottom of the strip. FreshStrip
; ($D51D) copies 15 of them into each fresh strip (docs/06-rendering.md 6.5).
; The tiles are split here only to name the two edge tiles 23 and 24.
Tiles:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $AA,$55,$AA,$55,$AA,$55,$AA,$55
  DEFB $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
  DEFB $FC,$F3,$CF,$3F,$3F,$0F,$03,$00
  DEFB $FC,$F3,$CF,$3F,$FF,$FF,$FF,$FF
  DEFB $FC,$F3,$CF,$3F,$3F,$CF,$F3,$FC
  DEFB $AA,$55,$AA,$55,$0A,$C5,$F0,$FC
  DEFB $FF,$FF,$FF,$FF,$3F,$0F,$03,$00
  DEFB $FF,$FF,$FF,$FF,$3F,$CF,$F3,$FC
  DEFB $FC,$F3,$CF,$3F,$7F,$3F,$1F,$0F
  DEFB $FC,$F3,$CF,$3F,$7F,$BF,$DF,$EF
  DEFB $AA,$55,$AA,$55,$2A,$95,$CA,$E5
  DEFB $07,$03,$01,$00,$00,$00,$00,$00
  DEFB $F7,$FB,$FD,$FE,$FF,$FF,$FF,$FF
  DEFB $F2,$F9,$FC,$FE,$FF,$FF,$FF,$FF
  DEFB $7F,$3F,$1F,$0F,$07,$03,$01,$00
  DEFB $7F,$BF,$DF,$EF,$F7,$FB,$FD,$FE
  DEFB $2A,$95,$CA,$E5,$F2,$F9,$FC,$FE
  DEFB $FC,$F3,$CF,$00,$00,$00,$00,$00
  DEFB $FC,$F3,$CF,$3F,$FF,$FF,$FF,$00
  DEFB $FC,$F3,$CF,$00,$FF,$FF,$FF,$FF
  DEFB $AA,$55,$AA,$00,$FF,$FF,$FF,$FF

; Edge tiles 23 and 24
;
; The first 8 lines of every fresh strip: tile 23 ($C4B8) for three strips in
; four, tile 24 ($C4C0) for the fourth (FreshStrip, $D534). No tile run uses
; them.
EdgeTiles:
  DEFB $C0,$70,$AC,$57,$AA,$55,$AA,$55
  DEFB $C0,$60,$A0,$4F,$AE,$4D,$AE,$5D

; Course tiles 25-71
;
; The rest of the tile set (see Tiles).
TilesHigh:
  DEFB $AA,$55,$AA,$55,$AA,$55,$AA,$00
  DEFB $FC,$F1,$C7,$1D,$07,$C1,$F0,$FC
  DEFB $FC,$F1,$C7,$1D,$77,$DD,$77,$DD
  DEFB $FC,$F3,$CF,$3F,$3F,$CF,$73,$DC
  DEFB $77,$DD,$77,$1D,$07,$C1,$F0,$FC
  DEFB $77,$DD,$77,$FD,$FF,$FF,$7F,$DF
  DEFB $77,$DD,$F7,$FD,$FF,$FF,$7F,$DD
  DEFB $77,$DD,$77,$DD,$77,$DD,$77,$DD
  DEFB $77,$DD,$77,$FD,$FF,$FF,$7F,$DD
  DEFB $FF,$FF,$FF,$FF,$3F,$CF,$73,$DC
  DEFB $77,$DD,$77,$DD,$77,$DD,$77,$DF
  DEFB $7F,$FF,$FF,$FD,$77,$DD,$77,$DC
  DEFB $7F,$FF,$FF,$FD,$F7,$DD,$77,$DC
  DEFB $77,$DD,$77,$DD,$F7,$DD,$77,$DC
  DEFB $70,$C3,$0F,$3F,$3F,$CF,$F3,$FC
  DEFB $70,$C3,$0F,$3F,$FF,$FF,$FF,$FF
  DEFB $FC,$F3,$CF,$3F,$7F,$7F,$7F,$7F
  DEFB $FC,$F3,$CF,$3F,$3F,$4F,$A3,$54
  DEFB $FC,$F0,$C0,$00,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$3F,$4F,$A3,$54
  DEFB $AA,$54,$AA,$54,$AA,$54,$AA,$54
  DEFB $7C,$73,$4F,$3F,$3F,$0F,$03,$00
  DEFB $7C,$73,$4F,$3F,$3F,$CF,$F3,$FC
  DEFB $AA,$55,$AA,$55,$2A,$C5,$F2,$FC
  DEFB $AA,$54,$AA,$54,$2A,$C4,$F2,$FC
  DEFB $FC,$F1,$C2,$15,$2A,$C5,$F2,$FC
  DEFB $FC,$F0,$C2,$14,$2A,$54,$AA,$54
  DEFB $FC,$F3,$CF,$3F,$3F,$0C,$00,$00
  DEFB $FC,$F3,$CF,$3F,$FF,$FC,$F0,$C0
  DEFB $FC,$F3,$CF,$3F,$3F,$CC,$F0,$C0
  DEFB $BA,$7F,$BF,$73,$30,$C0,$F0,$C0
  DEFB $AA,$55,$AA,$55,$AA,$55,$EA,$F5
  DEFB $32,$08,$0A,$08,$0B,$0F,$03,$00
  DEFB $02,$08,$22,$88,$23,$8F,$3F,$FF
  DEFB $02,$08,$22,$88,$23,$8F,$33,$FC
  DEFB $FA,$35,$3A,$B5,$3A,$85,$30,$FC
  DEFB $FC,$F2,$C8,$22,$08,$02,$00,$00
  DEFB $FC,$F2,$C8,$22,$88,$22,$88,$22
  DEFB $AA,$55,$AA,$01,$80,$20,$88,$22
  DEFB $88,$22,$88,$22,$08,$02,$00,$00
  DEFB $88,$22,$88,$22,$88,$22,$88,$22
  DEFB $AA,$15,$0A,$01,$80,$20,$88,$22
  DEFB $AA,$15,$0A,$05,$82,$21,$88,$22
  DEFB $88,$23,$8F,$3F,$7F,$3F,$1F,$0F
  DEFB $88,$23,$8F,$3F,$FF,$FF,$FF,$FF
  DEFB $88,$23,$8F,$3F,$7F,$BF,$DF,$EF
  DEFB $AA,$55,$AA,$55,$2A,$95,$CA,$E5

; Runs of tile numbers, one per tile across the track
;
; A row of the course is the address of a run in here: tile numbers from the
; bottom of the strip up, read as row i at offset i by FreshStrip. Runs
; overlap: rows one byte apart are the same run shifted by one tile, which is
; how bends are drawn (docs/06-rendering.md 6.5). The rows of all ten courses
; point between $C640 and $C8DB.
TileRuns:
  DEFB $02,$02,$02,$07,$05,$06,$05,$06,$05,$06,$05,$06,$05,$04,$00,$00
  DEFB $00,$00,$02,$02,$02,$07,$01,$09,$01,$09,$01,$09,$01,$09,$01,$08
  DEFB $00,$00,$00,$00,$02,$02,$02,$0C,$05,$0B,$05,$0B,$05,$0B,$05,$0B
  DEFB $05,$0A,$00,$00,$00,$00,$02,$02,$02,$02,$0F,$01,$0E,$01,$0E,$01
  DEFB $0E,$01,$0E,$01,$0D,$00,$00,$00,$02,$02,$02,$02,$12,$01,$11,$01
  DEFB $11,$01,$11,$01,$11,$01,$10,$00,$00,$00,$02,$02,$19,$16,$14,$15
  DEFB $14,$15,$14,$15,$14,$15,$14,$13,$00,$00,$00,$00,$07,$05,$06,$05
  DEFB $1C,$1B,$1B,$1B,$1A,$05,$04,$00,$00,$00,$00,$07,$01,$09,$01,$22
  DEFB $1E,$1E,$1E,$1D,$01,$08,$00,$00,$00,$00,$07,$05,$06,$05,$1C,$1F
  DEFB $1F,$1F,$1D,$05,$04,$00,$00,$00,$00,$07,$01,$09,$01,$22,$20,$20
  DEFB $20,$1D,$01,$08,$00,$00,$00,$00,$07,$05,$06,$05,$1C,$20,$21,$20
  DEFB $1D,$05,$04,$00,$00,$00,$00,$07,$05,$06,$05,$1C,$23,$1E,$20,$1D
  DEFB $05,$04,$00,$00,$00,$00,$07,$01,$09,$01,$22,$26,$25,$24,$1D,$01
  DEFB $08,$00,$00,$00,$00,$07,$05,$06,$05,$06,$28,$27,$28,$27,$05,$04
  DEFB $00,$00,$00,$00,$07,$05,$06,$05,$06,$05,$2A,$05,$29,$05,$29,$00
  DEFB $00,$00,$00,$07,$01,$09,$01,$09,$01,$2C,$02,$01,$03,$01,$03,$00
  DEFB $00,$00,$07,$05,$06,$05,$06,$05,$2A,$2D,$02,$01,$03,$01,$03,$00
  DEFB $00,$07,$01,$09,$01,$09,$01,$2C,$02,$2D,$02,$01,$03,$01,$03,$00
  DEFB $07,$05,$06,$05,$06,$05,$2A,$2D,$02,$2D,$30,$05,$2F,$05,$2E,$07
  DEFB $01,$09,$01,$09,$01,$2C,$02,$2D,$02,$31,$01,$09,$01,$08,$07,$05
  DEFB $06,$05,$06,$05,$2A,$2D,$02,$2D,$30,$05,$06,$05,$04,$07,$05,$06
  DEFB $05,$06,$05,$06,$2D,$02,$2D,$30,$05,$06,$05,$04,$07,$01,$09,$01
  DEFB $09,$01,$09,$01,$2D,$02,$31,$01,$09,$01,$08,$07,$05,$06,$05,$06
  DEFB $05,$06,$05,$06,$2D,$30,$05,$06,$05,$04,$07,$01,$09,$01,$09,$01
  DEFB $09,$01,$09,$01,$31,$01,$09,$01,$08,$07,$05,$06,$05,$06,$05,$06
  DEFB $05,$06,$05,$04,$2B,$2B,$2B,$2B,$07,$05,$06,$05,$2A,$05,$29,$05
  DEFB $29,$05,$29,$00,$00,$00,$00,$07,$01,$09,$01,$2C,$02,$01,$03,$01
  DEFB $03,$01,$03,$00,$00,$00,$07,$05,$06,$05,$2A,$2D,$02,$01,$03,$01
  DEFB $03,$01,$03,$00,$00,$07,$01,$09,$01,$2C,$02,$2D,$02,$01,$03,$01
  DEFB $03,$01,$03,$00,$07,$05,$06,$05,$2A,$2D,$02,$2D,$30,$05,$2F,$05
  DEFB $2F,$05,$2E,$07,$01,$09,$01,$2C,$02,$2D,$02,$31,$01,$09,$01,$09
  DEFB $01,$08,$07,$05,$06,$05,$2A,$2D,$02,$2D,$30,$05,$06,$05,$06,$05
  DEFB $04,$07,$05,$06,$05,$06,$2D,$02,$2D,$30,$05,$06,$05,$06,$05,$04
  DEFB $07,$01,$09,$01,$09,$01,$2D,$02,$31,$01,$09,$01,$09,$01,$08,$07
  DEFB $05,$06,$05,$06,$05,$2A,$2D,$30,$05,$06,$05,$06,$05,$04,$07,$01
  DEFB $09,$01,$09,$01,$2C,$02,$31,$01,$09,$01,$09,$01,$08,$07,$05,$06
  DEFB $05,$06,$05,$2A,$2D,$02,$33,$32,$05,$06,$05,$04,$02,$02,$38,$37
  DEFB $35,$36,$35,$36,$35,$36,$35,$36,$35,$34,$00,$00,$00,$02,$02,$02
  DEFB $3C,$3A,$3B,$3A,$3B,$3A,$3B,$3A,$3B,$3A,$39,$00,$00,$00,$3F,$3E
  DEFB $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3D,$00,$00,$00,$00,$42,$41,$41
  DEFB $41,$41,$41,$41,$41,$41,$41,$40,$00,$00,$00,$00,$43,$41,$41,$41
  DEFB $41,$41,$41,$41,$41,$41,$40,$00,$00,$00,$00,$47,$45,$46,$45,$46
  DEFB $45,$46,$45,$46,$45,$44,$00,$00,$00,$00

; Row lists of the course segments
;
; A course byte b selects the list at $C8EA + 2 x b: row addresses (into
; TileRuns), ended by a word with a zero high byte. Lists overlap, so a byte
; can start inside another byte's list. CourseExpand ($D4D9) copies them into
; RowList (docs/06-rendering.md 6.5). One line here is the slot of one even
; course byte.
SegmentRows:
  DEFW $C643,$C655
  DEFW $0000,$0000
  DEFW $C642,$C654
  DEFW $0000,$0000
  DEFW $C641,$C653
  DEFW $0000,$0000
  DEFW TileRuns,$C652
  DEFW $0000,$0000
  DEFW $C667,$C679
  DEFW $C68B,$0000
  DEFW $C666,$C678
  DEFW $C68A,$0000
  DEFW $C665,$C677
  DEFW $C689,$0000
  DEFW $C69C,$0000
  DEFW $0000,$0000
  DEFW $C69B,$0000
  DEFW $0000,$0000
  DEFW $C69A,$0000
  DEFW $0000,$0000
  DEFW $C6AC,$C6BB
  DEFW $C6CA,$C6D9
  DEFW $0000,$0000
  DEFW $C6E8,$C6D9
  DEFW $C6E8,$C6D9
  DEFW $0000,$0000
  DEFW $C6F7,$C706
  DEFW $C715,$C655
  DEFW $0000,$0000
  DEFW $C724,$C733
  DEFW $C742,$C751
  DEFW $C760,$C76F
  DEFW $0000,$0000
  DEFW $C77E,$C76F
  DEFW $0000,$0000
  DEFW $C78D,$C79C
  DEFW $C7AB,$C7BA
  DEFW $C7C9,$C655
  DEFW $0000,$0000
  DEFW $C7D8,$C7E7
  DEFW $C7F6,$C805
  DEFW $C814,$C823
  DEFW $0000,$0000
  DEFW $C832,$C823
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $C841,$C850
  DEFW $C85F,$C86E
  DEFW $C87D,$C76F
  DEFW $0000,$0000
  DEFW $C88E,$C89F
  DEFW $0000,$0000
  DEFW $C88D,$C89E
  DEFW $0000,$0000
  DEFW $C88C,$C89D
  DEFW $0000,$0000
  DEFW $C8AE,$C8BD
  DEFW $0000,$0000
  DEFW $C8BD,$C8BD
  DEFW $0000,$0000
  DEFW $C8BD,$C8CC
  DEFW $0000,$0000
  DEFW $C8DB,$C679
  DEFW $C68B,$0000
  DEFW $C6E8,$C6D9
  DEFW $0000,$0000

; Ground profile anchors of the course segments
;
; A course byte b selects the list at $C9FE + b / 2, ended by $FF: one ground
; anchor byte for every 8 bytes of the profile at $6000 (height in bits 0-4,
; walls in bits 5-7, docs/07-objects.md 7.4). GroundProfile ($D0EF)
; interpolates between them.
GroundAnchors:
  DEFB $00,$FF,$08,$FF,$10,$FF,$18,$FF
  DEFB $08,$FF,$10,$FF,$18,$FF,$00,$FF
  DEFB $08,$FF,$10,$FF,$00,$00,$FF,$00
  DEFB $00,$FF,$00,$00,$FF,$40,$40,$40
  DEFB $FF,$40,$FF,$40,$00,$00,$FF,$80
  DEFB $80,$80,$FF,$80,$FF,$40,$00,$00
  DEFB $FF,$40,$40,$40,$FF,$28,$FF,$30
  DEFB $FF,$38,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$08,$FF,$00,$FF

; The row list of the current course (filled by CourseExpand)
;
; 176 words, zero in the image, where CourseExpand writes the course's rows
; (178 for every course, so the last two land on the first two words of
; RowListTail). $C3F8 points to the next row a fresh strip starts from.
RowList:
  DEFS $0160

; Run-out rows after a course, and the end mark $FFFF
;
; The rows that follow every course: $C643 and $C655 alternating, then $FFFF at
; $CBC1. With 178 course rows the list holds 191 rows before the mark. The
; course check ($D49C) looks at the high byte of the row 15 ahead and ends the
; course at $FF.
RowListTail:
  DEFW $C643,$C655,$C643,$C655,$C643,$C655,$C643
  DEFW $C655,$C643,$C655,$C643,$C655,$C643,$C655
  DEFW $C643,$FFFF

; Course data of round 7
;
; A course: the player's type (0 aircraft, 1 ground vehicle), then one segment
; byte per course piece (indexes into SegmentRows and GroundAnchors), ended by
; $FF (docs/04-game-loop.md 4.2, docs/06-rendering.md 6.5). The ten courses are
; stored in the order of rounds 7, 8, 9, 10, 3, 2, 1, 6, 5, 4.
Course7:
  DEFB $00,$00,$00,$00,$00,$28,$2E,$2E,$2E,$2E,$2E,$34,$00,$00,$10,$04
  DEFB $04,$04,$04,$1C,$10,$1C,$10,$1C,$10,$1C,$10,$1C,$10,$1C,$10,$1C
  DEFB $10,$1C,$10,$14,$08,$08,$08,$08,$08,$08,$08,$08,$20,$1C,$76,$7A
  DEFB $7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7E,$82,$04,$04
  DEFB $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$14,$6E
  DEFB $20,$1C,$00,$FF

; Course data of round 8
Course8:
  DEFB $01,$00,$00,$00,$00,$28,$86,$34,$00,$10,$04,$04,$04,$1C,$76,$7A
  DEFB $7A,$7A,$7A,$7A,$7A,$7A,$7A,$7E,$82,$04,$04,$04,$04,$04,$04,$04
  DEFB $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  DEFB $04,$1C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3A,$42
  DEFB $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$46,$00,$00
  DEFB $10,$6A,$1C,$00,$FF

; Course data of round 9
Course9:
  DEFB $00,$00,$00,$00,$00,$28,$2E,$2E,$2E,$2E,$2E,$34,$00,$00,$00,$00
  DEFB $10,$04,$04,$04,$04,$14,$18,$0C,$24,$20,$1C,$00,$00,$10,$1C,$00
  DEFB $10,$14,$18,$24,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$20
  DEFB $1C,$10,$14,$18,$24,$20,$1C,$10,$14,$18,$24,$20,$04,$04,$04,$04
  DEFB $14,$08,$08,$18,$24,$20,$1C,$76,$7A,$7A,$7E,$82,$14,$18,$72,$24
  DEFB $20,$1C,$00,$FF

; Course data of round 10
Course10:
  DEFB $01,$00,$00,$00,$00,$28,$86,$34,$10,$04,$04,$04,$04,$1C,$10,$04
  DEFB $04,$04,$1C,$00,$00,$00,$00,$00,$3A,$42,$42,$42,$42,$42,$42,$42
  DEFB $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42
  DEFB $42,$46,$10,$1C,$00,$00,$4E,$56,$56,$56,$56,$56,$56,$56,$56,$56
  DEFB $56,$56,$56,$56,$56,$56,$62,$42,$46,$00,$10,$6A,$1C,$00,$FF

; Course data of round 3
Course3:
  DEFB $00,$00,$00,$00,$00,$28,$2E,$2E,$2E,$2E,$2E,$34,$00,$00,$00,$00
  DEFB $4E,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56
  DEFB $56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56
  DEFB $56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$62,$42,$42,$42
  DEFB $42,$46,$10,$14,$08,$08,$08,$18,$72,$24,$20,$1C,$00,$FF

; Course data of round 2
Course2:
  DEFB $01,$00,$00,$00,$00,$28,$86,$34,$00,$00,$10,$04,$04,$04,$1C,$76
  DEFB $7A,$7A,$7A,$7E,$82,$1C,$76,$7E,$82,$1C,$76,$7A,$7A,$7A,$7E,$82
  DEFB $04,$04,$04,$04,$04,$04,$04,$14,$08,$08,$08,$08,$20,$14,$08,$08
  DEFB $08,$08,$08,$08,$20,$04,$04,$14,$20,$04,$04,$04,$04,$04,$14,$08
  DEFB $20,$1C,$76,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7E,$82,$04
  DEFB $14,$08,$18,$72,$24,$20,$1C,$00,$FF

; Course data of round 1
Course1:
  DEFB $00,$00,$00,$00,$00,$28,$2E,$2E,$2E,$2E,$2E,$34,$10,$1C,$00,$00
  DEFB $10,$14,$20,$1C,$00,$00,$10,$14,$18,$24,$20,$14,$20,$04,$04,$14
  DEFB $08,$08,$20,$1C,$10,$1C,$10,$04,$04,$14,$20,$04,$04,$14,$20,$1C
  DEFB $76,$7A,$7E,$82,$14,$08,$08,$20,$04,$04,$04,$14,$08,$20,$1C,$10
  DEFB $04,$04,$1C,$10,$1C,$76,$7A,$7E,$82,$14,$18,$24,$20,$04,$14,$6E
  DEFB $20,$1C,$00,$FF

; Course data of round 6
Course6:
  DEFB $01,$00,$00,$00,$00,$28,$86,$34,$00,$00,$00,$4E,$56,$56,$56,$56
  DEFB $56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56,$56
  DEFB $56,$56,$56,$56,$56,$56,$56,$56,$62,$42,$42,$42,$42,$42,$42,$42
  DEFB $42,$42,$42,$46,$00,$00,$10,$04,$04,$04,$04,$04,$04,$04,$1C,$10
  DEFB $1C,$10,$1C,$10,$04,$04,$04,$04,$04,$04,$04,$04,$04,$14,$6E,$20
  DEFB $1C,$00,$FF

; Course data of round 5
Course5:
  DEFB $00,$00,$00,$00,$00,$28,$2E,$2E,$2E,$2E,$2E,$34,$10,$14,$20,$1C
  DEFB $10,$14,$08,$08,$20,$04,$04,$14,$08,$08,$20,$04,$04,$14,$08,$08
  DEFB $20,$04,$04,$04,$04,$04,$04,$04,$14,$18,$24,$20,$04,$04,$14,$18
  DEFB $24,$20,$04,$04,$14,$18,$24,$20,$1C,$00,$4E,$56,$56,$56,$56,$56
  DEFB $56,$56,$56,$56,$56,$56,$56,$62,$46,$10,$6A,$1C,$00,$FF

; Course data of round 4
Course4:
  DEFB $01,$00,$00,$00,$00,$28,$86,$34,$00,$10,$04,$04,$14,$08,$08,$08
  DEFB $08,$20,$1C,$76,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A
  DEFB $7A,$7E,$82,$04,$1C,$76,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A
  DEFB $7E,$82,$1C,$76,$7A,$7E,$82,$04,$04,$04,$04,$1C,$76,$7A,$7A,$7A
  DEFB $7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A,$7A
  DEFB $7E,$82,$04,$14,$6E,$20,$1C,$00,$FF

; Course records of rounds 1-10, ended by $FFFF
;
; Ten records of two words: the course data, and the round's 128-byte object
; block at $F300 + 128 x (round - 1) (docs/04-game-loop.md 4.2,
; docs/07-objects.md 7.2). $FFFF ends the table: CourseExpand wraps to $CF04
; there.
CourseTable:
  DEFW Course1,RoundObjects1
  DEFW Course2,RoundObjects2
  DEFW Course3,RoundObjects3
  DEFW Course4,RoundObjects4
  DEFW Course5,RoundObjects5
  DEFW Course6,RoundObjects6
  DEFW Course7,RoundObjects7
  DEFW Course8,RoundObjects8
  DEFW Course9,RoundObjects9
  DEFW Course10,RoundObjects10
  DEFW $FFFF

; The current course record
;
; The record of the course being played or scrolled into. NextCourse ($D4CF)
; steps it by 4.
CourseRecord:
  DEFW CourseTable

; The course record a round start uses
;
; RoundStart ($CF68) copies it into CourseRecord. Set by the game start, by
; RoundSetup ($D1E1) and by the look-back ($D027).
RestartRecord:
  DEFW CourseTable
