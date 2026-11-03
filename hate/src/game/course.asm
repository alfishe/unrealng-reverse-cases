; Course tiles 0-22, 8 x 8 bytes
;
; The tile set of the course: 72 tiles of 8 bytes at $C400 + 8 x tile, one byte
; (8 pixels) a line, the first byte at the bottom of the strip. FreshStrip
; ($D51D) copies 15 of them into each fresh strip (docs/06-rendering.md 6.5).
; The tiles are split here only to name the two edge tiles 23 and 24.
Tiles:
  INCBIN "res/gfx/tiles.bin",$0000,184

; Edge tiles 23 and 24
;
; The first 8 lines of every fresh strip: tile 23 ($C4B8) for three strips in
; four, tile 24 ($C4C0) for the fourth (FreshStrip, $D534). No tile run uses
; them.
EdgeTiles:
  INCBIN "res/gfx/tiles.bin",$00B8,16

; Course tiles 25-71
;
; The rest of the tile set (see Tiles).
TilesHigh:
  INCBIN "res/gfx/tiles.bin",$00C8,376

; Runs of tile numbers, one per tile across the track
;
; A row of the course is the address of a run in here: tile numbers from the
; bottom of the strip up, read as row i at offset i by FreshStrip. Runs
; overlap: rows one byte apart are the same run shifted by one tile, which is
; how bends are drawn (docs/06-rendering.md 6.5). The rows of all ten courses
; point between $C640 and $C8DB.
TileRuns:
  INCBIN "res/course/tile-runs.bin",$0000,682

; Row lists of the course segments
;
; A course byte b selects the list at $C8EA + 2 x b: row addresses (into
; TileRuns), ended by a word with a zero high byte. Lists overlap, so a byte
; can start inside another byte's list. CourseExpand ($D4D9) copies them into
; RowList (docs/06-rendering.md 6.5). One line here is the slot of one even
; course byte. The 16 zero bytes $C99E-$C9AD, the slots of course bytes
; $5A-$61, which no course uses, are the static-object list of StampStatics
; ($EA38) in play.
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
  INCBIN "res/course/ground-anchors.bin",$0000,69

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
  INCBIN "res/course/round-07.bin",$0000,84

; Course data of round 8
Course8:
  INCBIN "res/course/round-08.bin",$0000,85

; Course data of round 9
Course9:
  INCBIN "res/course/round-09.bin",$0000,84

; Course data of round 10
Course10:
  INCBIN "res/course/round-10.bin",$0000,79

; Course data of round 3
Course3:
  INCBIN "res/course/round-03.bin",$0000,78

; Course data of round 2
Course2:
  INCBIN "res/course/round-02.bin",$0000,89

; Course data of round 1
Course1:
  INCBIN "res/course/round-01.bin",$0000,84

; Course data of round 6
Course6:
  INCBIN "res/course/round-06.bin",$0000,83

; Course data of round 5
Course5:
  INCBIN "res/course/round-05.bin",$0000,78

; Course data of round 4
Course4:
  INCBIN "res/course/round-04.bin",$0000,89

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
