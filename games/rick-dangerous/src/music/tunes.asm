; --------------------------------------------------------------------------------------------------------------------
; tunes.asm: The tunes: 55 patterns, the tune table, the 24 order lists, the pattern pointers and the 8 instruments
;
; All of it, with the effects, is one editable text, src/res/music/music.txt (tools/res_music.py,
; src/res/music/README.md): the instruments, the effects, the tunes' order lists and the patterns, one line a note
; with its name. The pointer tables (TuneTable, PatternLo, PatternHi) are made from the layout when the text is built
; back.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C6E5

; The 55 patterns, one after the other: notes (note, frames), rests, instrument
; bytes, `$FF` at the end
;
; A pattern: `$80`-`$87` instrument slot, `$7F` FRAMES a rest, `$7E` LO HI
; FRAMES a period given directly, NOTE FRAMES a note (NOTE 0-`$7D`, played at
; PeriodTable[NOTE + transpose + 12]), `$FF` the end. The tunes use notes 6-52,
; durations of 4-96 frames (50 a second) and instruments 0-4 (instrument 5 only
; in pattern 42, which no tune uses). Patterns 34-37 are empty (only `$FF`),
; and 12 patterns are named by no order list: 21, 28-30, 34-37, 39, 42, 49, 50.
Patterns:
  INCBIN "res/music/patterns.bin",$0000,938

; 8 tunes x 3 order list pointers (channels A, B, C)
;
; Tune 0 `$E324` (a level's intro), 1-4 `$AC20` (a level's end), 5 `$E220` (the
; menu), 6 `$E386` (GAME OVER), 7 `$F531` (the bonus end marker). In the
; recordings (reads of this table): tunes 0, 5, 6 in `controls` and `gameover`;
; 0, 5, 6, 7 in `level1`; 4, 5, 6 in `ending`.
TuneTable:
  INCBIN "res/music/tunetable.bin",$0000,48

; The 24 order lists: pattern numbers, `$80`+N repeats, `$FE` N transpose,
; `$FF` end
;
; Stored for tunes 0-3, 5-7, then 4. Tunes 2, 3, 4, 6 and 7 leave a channel
; silent (a list that is only `$FF`). Transposes run from -12 (tune 2) to +28
; semitones (tune 0's last pattern).
OrderLists:
  INCBIN "res/music/orders.bin",$0000,395

; The low bytes of the 55 pattern addresses
PatternLo:
  INCBIN "res/music/patternlo.bin",$0000,55

; The high bytes of the 55 pattern addresses
PatternHi:
  INCBIN "res/music/patternhi.bin",$0000,55

; 8 instruments of 10 bytes: attack, decay, sustain, release, peak, vibrato
; delay, length, step, flags
;
; +0 attack step, +1 decay step (signed), +2 sustain level, +3 release step
; (signed), +4 peak volume (AY volume = /8), +5 vibrato delay in frames (`$FF`:
; none), +6 vibrato length (0: a slide that goes on, bit 7: a slide that
; stops), +7/+8 the step added to the period each frame, +9 flags (bit 0 tone,
; bit 1 noise, bit 2 fixed volume). Instruments 0-4 are tone with envelopes
; peaking at `$2D`-`$36`; 5 is noise, used only by pattern 42, which no order
; list names; 6 (a tone that slides down after 63 frames, step `$0500`) and 7
; (noise with a vibrato, step `$6400`: `$0400` in the AY's 12 bits) are used by
; no pattern.
Instruments:
  INCBIN "res/music/instruments.bin",$0000,80
