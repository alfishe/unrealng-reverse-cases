; --------------------------------------------------------------------------------------------------------------------
; tunedata.asm: the title tune's notes: the periods, the order, the four patterns
;
; The data TitleTune plays, at the top of memory after the screen buffers: TunePeriods (27 periods, index 0 unused),
; TuneOrder (7 pattern pointers), the patterns A-D. 211 bytes; the editable form is src/res/music/titletune.tune.txt.
; --------------------------------------------------------------------------------------------------------------------

; the period of each note number, in loop passes (index 0 unused)
TunePeriods:
  INCBIN "res/music/titletune.bin",$0000,27

; the patterns in play order: A A B A C C D
TuneOrder:
  INCBIN "res/music/titletune.bin",$001B,14

; pattern A (played 3 times): the opening phrase
TunePatternA:
  INCBIN "res/music/titletune.bin",$0029,55

; pattern B: the climbing arpeggios
TunePatternB:
  INCBIN "res/music/titletune.bin",$0060,59

; pattern C (twice): the ostinato
TunePatternC:
  INCBIN "res/music/titletune.bin",$009B,18

; pattern D: the closing phrase
TunePatternD:
  INCBIN "res/music/titletune.bin",$00AD,38
