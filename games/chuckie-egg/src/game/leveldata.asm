; --------------------------------------------------------------------------------------------------------------------
; leveldata.asm: The level phrases, the vector table, the edge fall, the maps, and the author's leftover text
;
; The bytes between the code and the maps hold the IM 2 vector table, a routine the image keeps in the middle of the
; leftover text (FallOffEdge), and the text of the author's editor.
; --------------------------------------------------------------------------------------------------------------------

; The phrases LevelPhrase picks from
;
; Read at LevelPhrases + (R AND 7). The editable form is
; src/res/tables/LevelPhrases.csv.
LevelPhrases:
  INCBIN "res/tables/LevelPhrases.bin",$0000,8

; Leftover: the author's assembler source
;
; Never read (L1: no access). Lines of an earlier program (a scroller: SCRL2,
; SCROL), with BCD line numbers; src/res/text/SourceLeftoverB167.txt.
SourceLeftoverB167:
  INCBIN "res/text/SourceLeftoverB167.bin",$0000,153

; The IM 2 vector table: 263 bytes of $9C
;
; I = $B2 (Start): an interrupt with $FF on the bus reads $B2FF-$B300, $9C9C,
; PhraseVector. Witness: only $B2FF-$B300 are read (243 240 reads).
VectorTable:
  DEFS $0107,$9C

; Leftover: the author's assembler source
;
; Never read (L1: no access); src/res/text/SourceLeftoverB307.txt.
SourceLeftoverB307:
  INCBIN "res/text/SourceLeftoverB307.bin",$0000,69

; Start a fall when Harry walks off a platform's edge
;
; Only when x AND 7 is not 0. The cell under his feet (MapCellAt - $3F): a
; brick or more, or a ladder, keeps him. Else (empty, an egg, grain) JumpState
; 1, JumpDx his direction, JumpCount 4: he drifts four slow ticks, then falls
; (JumpStep $A21C). MainLoop calls it on foot when not on a lift ($99D6).
;
; Witness: 98 837 calls, 63 falls ($B368). This routine lies inside the
; leftover text: the code runs at $911E-$B15E and $B34C-$B380.
FallOffEdge:
  LD A,(HarryX)
  AND $07
  RET Z
  LD HL,(HarryX)
  CALL MapCellAt
  LD BC,$003F
  AND A
  SBC HL,BC
  LD A,(HL)
  CP $05
  RET NC
  CP $01
  RET Z
  CP $02
  RET Z
FallOffEdgeStart:
  LD A,$01
  LD (JumpState),A
  LD D,$FF
  LD A,(HarryDir)
  AND A
  JR NZ,FallOffEdgeDir
  LD D,$01
FallOffEdgeDir:
  LD A,D
  LD (JumpDx),A
  LD A,$04
  LD (JumpCount),A
  RET

; Leftover: the author's assembler source
;
; Never read (L1: no access); src/res/text/SourceLeftoverB381.txt.
SourceLeftoverB381:
  INCBIN "res/text/SourceLeftoverB381.bin",$0000,47

; The eight level maps of 21 rows of 32 cells, the bottom row first: level 1
;
; StartGame copies level 1 into every LiveMap slot, PlayLevel the next level's
; (LevelMaps + 672 x (Level AND 7)) into the map in play: levels 9-16 repeat
; 1-8, and so on. Codes: 0 empty, 1 and 2 a ladder, 3 an egg, 4 grain, 5 a
; brick, $A8-$B5 the cage. The editable forms are src/res/maps/Level1.txt ..
; Level8.txt (top row first), the figures docs/img/maps.
LevelMaps:
  INCBIN "res/maps/Level1.bin",$0000,672

; Level 2
LevelMap2:
  INCBIN "res/maps/Level2.bin",$0000,672

; Level 3
LevelMap3:
  INCBIN "res/maps/Level3.bin",$0000,672

; Level 4
LevelMap4:
  INCBIN "res/maps/Level4.bin",$0000,672

; Level 5
LevelMap5:
  INCBIN "res/maps/Level5.bin",$0000,672

; Level 6
LevelMap6:
  INCBIN "res/maps/Level6.bin",$0000,672

; Level 7
LevelMap7:
  INCBIN "res/maps/Level7.bin",$0000,672

; Level 8
LevelMap8:
  INCBIN "res/maps/Level8.bin",$0000,672
