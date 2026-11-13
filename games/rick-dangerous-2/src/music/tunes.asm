; --------------------------------------------------------------------------------------------------------------------
; tunes.asm: The tunes: patterns, the tune table, the order lists, the pattern addresses, ornaments, instruments
;
; A tune is three order lists, one per AY channel (TuneTable). An order list names patterns by number (PatternAddrLow
; / PatternAddrHigh) with a repeat count and a transpose before them; a pattern is a stream of notes (note, duration
; in frames), rests and instrument / ornament changes ending in $FF. A note starts the channel's voice with the
; current instrument (the volume envelope and pitch sweep of 10 bytes in Instruments) and, when an ornament is set,
; the ornament's semitone steps (Ornaments). The format in full: work/stage2/ann/06-notes.md.
;
; Resources: tunes/patterns.txt (the 54 patterns and their address table: patterns.bin, pattern-low.bin, pattern-
; high.bin), tunes/tunes.txt (the tune table and the order lists: tune-table.bin, order-lists.bin),
; tunes/ornaments.csv, tunes/instruments.csv.
; --------------------------------------------------------------------------------------------------------------------

; The 54 patterns of the 11 tunes (704 bytes, PatternAddrLow / PatternAddrHigh
; give each start)
;
; A pattern is read by SequenceChannel $CAF7 and PatternCommand $CBFE: $80-$87
; the instrument (slot n of the channel's InstrumentSlots, Instruments + 10 n),
; $88-$BF the ornament (bits 0-3; 0 none), $FF the end; a byte n below $7F is a
; note, period table index n + transpose + 12, followed by its duration in
; frames; $7F d a rest of d frames; $7E lo hi d a note of the period word lo hi
; (no pattern uses it); $C0-$FE skip 4 bytes ($C2 1 byte; no pattern uses
; them). Some patterns start inside another (3 holds the instrument byte and
; then 4, likewise 10 and 11, 21 and 22, 25 and 27, 35 and 36, 45 and 46; 48 is
; the last three notes of 43) and three numbers share a start (17/18, 31/32,
; 40/41). Patterns 3, 10, 17, 31, 34 and 40 are in no order list.
;
; Read by SequenceChannel in c1 and the control and load recordings (the reads
; of $C754's callers); which pattern belongs to which tune is in each inner
; line.
Patterns:
Pattern00:
  INCBIN "res/tunes/patterns.bin",$0000,40
Pattern02:
  INCBIN "res/tunes/patterns.bin",$0028,38
Pattern08:
  INCBIN "res/tunes/patterns.bin",$004E,3
Pattern01:
  INCBIN "res/tunes/patterns.bin",$0051,39
Pattern09:
  INCBIN "res/tunes/patterns.bin",$0078,21
Pattern03:
  INCBIN "res/tunes/patterns.bin",$008D,1
Pattern04:
  INCBIN "res/tunes/patterns.bin",$008E,28
Pattern05:
  INCBIN "res/tunes/patterns.bin",$00AA,3
Pattern06:
  INCBIN "res/tunes/patterns.bin",$00AD,18
Pattern07:
  INCBIN "res/tunes/patterns.bin",$00BF,18
Pattern10:
  INCBIN "res/tunes/patterns.bin",$00D1,1
Pattern11:
  INCBIN "res/tunes/patterns.bin",$00D2,10
Pattern12:
  INCBIN "res/tunes/patterns.bin",$00DC,6
Pattern13:
  INCBIN "res/tunes/patterns.bin",$00E2,6
Pattern14:
  INCBIN "res/tunes/patterns.bin",$00E8,20
Pattern15:
  INCBIN "res/tunes/patterns.bin",$00FC,18
Pattern16:
  INCBIN "res/tunes/patterns.bin",$010E,9
Pattern17:
  INCBIN "res/tunes/patterns.bin",$0117,8
Pattern19:
  INCBIN "res/tunes/patterns.bin",$011F,8
Pattern20:
  INCBIN "res/tunes/patterns.bin",$0127,8
Pattern21:
  INCBIN "res/tunes/patterns.bin",$012F,1
Pattern22:
  INCBIN "res/tunes/patterns.bin",$0130,29
Pattern23:
  INCBIN "res/tunes/patterns.bin",$014D,4
Pattern24:
  INCBIN "res/tunes/patterns.bin",$0151,22
Pattern25:
  INCBIN "res/tunes/patterns.bin",$0167,1
Pattern27:
  INCBIN "res/tunes/patterns.bin",$0168,25
Pattern26:
  INCBIN "res/tunes/patterns.bin",$0181,10
Pattern28:
  INCBIN "res/tunes/patterns.bin",$018B,4
Pattern29:
  INCBIN "res/tunes/patterns.bin",$018F,14
Pattern30:
  INCBIN "res/tunes/patterns.bin",$019D,10
Pattern31:
  INCBIN "res/tunes/patterns.bin",$01A7,6
Pattern33:
  INCBIN "res/tunes/patterns.bin",$01AD,34
Pattern34:
  INCBIN "res/tunes/patterns.bin",$01CF,10
Pattern35:
  INCBIN "res/tunes/patterns.bin",$01D9,3
Pattern36:
  INCBIN "res/tunes/patterns.bin",$01DC,17
Pattern37:
  INCBIN "res/tunes/patterns.bin",$01ED,18
Pattern38:
  INCBIN "res/tunes/patterns.bin",$01FF,3
Pattern39:
  INCBIN "res/tunes/patterns.bin",$0202,26
Pattern40:
  INCBIN "res/tunes/patterns.bin",$021C,18
Pattern42:
  INCBIN "res/tunes/patterns.bin",$022E,10
Pattern43:
  INCBIN "res/tunes/patterns.bin",$0238,9
Pattern48:
  INCBIN "res/tunes/patterns.bin",$0241,7
Pattern44:
  INCBIN "res/tunes/patterns.bin",$0248,16
Pattern45:
  INCBIN "res/tunes/patterns.bin",$0258,34
Pattern46:
  INCBIN "res/tunes/patterns.bin",$027A,15
Pattern47:
  INCBIN "res/tunes/patterns.bin",$0289,21
Pattern49:
  INCBIN "res/tunes/patterns.bin",$029E,7
Pattern50:
  INCBIN "res/tunes/patterns.bin",$02A5,14
Pattern51:
  INCBIN "res/tunes/patterns.bin",$02B3,5
Pattern52:
  INCBIN "res/tunes/patterns.bin",$02B8,5
Pattern53:
  INCBIN "res/tunes/patterns.bin",$02BD,3

; The 11 tunes: the order lists of channels A, B and C
;
; MusicStartTune $CA27 reads the three words at TuneTable + 6 A into the
; channels (+1/+2). Tunes: 0 the control menu and the CONGRATULATIONS end, 1
; the signal (cheats, the countdown bonus), 2 game over, 3 no caller in the
; game, 4 silence (OrderListEmpty on all three: before a level loads), 5-9 the
; levels 1-5, 10 the Fat Guy end after the lives tally.
;
; Read in c1 and the control and load recordings: tunes 0, 2 and 4-9
; ($C2C0-$C2C5, $C2CC-$C2D1, $C2D8-$C2FB in the reads of MusicStartTune).
TuneTable:
  INCBIN "res/tunes/tune-table.bin",$0000,66
  ASSERT {TuneTable} == Tune0OrderA && {TuneTable+2} == Tune0OrderB && {TuneTable+4} == Tune0OrderC
  ASSERT {TuneTable+6} == Tune1OrderA && {TuneTable+8} == Tune1OrderB && {TuneTable+10} == Tune1OrderC
  ASSERT {TuneTable+12} == Tune2OrderA && {TuneTable+14} == Tune2OrderB && {TuneTable+16} == Tune2OrderC
  ASSERT {TuneTable+18} == Tune3OrderA && {TuneTable+20} == Tune3OrderB && {TuneTable+22} == Tune3OrderC
  ASSERT {TuneTable+24} == OrderLists && {TuneTable+26} == OrderLists && {TuneTable+28} == OrderLists
  ASSERT {TuneTable+30} == Tune5OrderA && {TuneTable+32} == Tune5OrderB && {TuneTable+34} == Tune5OrderC
  ASSERT {TuneTable+36} == Tune6OrderA && {TuneTable+38} == Tune6OrderB && {TuneTable+40} == Tune6OrderC
  ASSERT {TuneTable+42} == Tune7OrderA && {TuneTable+44} == Tune7OrderB && {TuneTable+46} == Tune7OrderC
  ASSERT {TuneTable+48} == Tune8OrderA && {TuneTable+50} == Tune8OrderB && {TuneTable+52} == Tune8OrderC
  ASSERT {TuneTable+54} == Tune9OrderA && {TuneTable+56} == Tune9OrderB && {TuneTable+58} == Tune9OrderC
  ASSERT {TuneTable+60} == Tune10OrderA && {TuneTable+62} == Tune10OrderB && {TuneTable+64} == Tune10OrderC

; The order lists: the patterns of each channel of each tune
;
; An order list is read by SequenceChannel $CB17-$CB5C, one byte or two at a
; time: n below $80 plays pattern n; $80-$BF sets the times the next pattern
; plays (bits 0-4; 0 = 256; without one, once); $C0-$FD v sets the channel's
; instrument slot (bits 0-2) to the instrument offset v (Instruments + v; no
; list uses it); $FE t transposes the following patterns by t semitones
; (signed); $FF ends the channel (its +$0D = 0). The lists do not loop: a tune
; ends when all three are done and the voices have died away.
;
; $C381, $C385 and $C38A are spare $FF bytes and $C3C3, $C3CC and $C3DA three
; order lists TuneTable does not name.
OrderLists:
OrderListEmpty:
  INCBIN "res/tunes/order-lists.bin",$0000,1
Tune0OrderA:
  INCBIN "res/tunes/order-lists.bin",$0001,21
Tune0OrderB:
  INCBIN "res/tunes/order-lists.bin",$0016,22
Tune0OrderC:
  INCBIN "res/tunes/order-lists.bin",$002C,41
Tune3OrderA:
  INCBIN "res/tunes/order-lists.bin",$0055,5
Tune3OrderB:
  INCBIN "res/tunes/order-lists.bin",$005A,5
Tune3OrderC:
  INCBIN "res/tunes/order-lists.bin",$005F,5
Tune2OrderA:
  INCBIN "res/tunes/order-lists.bin",$0064,2
Tune2OrderB:
  INCBIN "res/tunes/order-lists.bin",$0066,2
Tune2OrderC:
  INCBIN "res/tunes/order-lists.bin",$0068,2
Tune1OrderA:
  INCBIN "res/tunes/order-lists.bin",$006A,2
Tune1OrderB:
  INCBIN "res/tunes/order-lists.bin",$006C,2
Tune1OrderC:
  INCBIN "res/tunes/order-lists.bin",$006E,2
Tune5OrderA:
  INCBIN "res/tunes/order-lists.bin",$0070,3
Tune5OrderB:
  INCBIN "res/tunes/order-lists.bin",$0073,5
Tune5OrderC:
  INCBIN "res/tunes/order-lists.bin",$0078,4
Tune9OrderA:
  INCBIN "res/tunes/order-lists.bin",$007C,4
Tune9OrderB:
  INCBIN "res/tunes/order-lists.bin",$0080,4
Tune9OrderC:
  INCBIN "res/tunes/order-lists.bin",$0084,5
Tune7OrderA:
  INCBIN "res/tunes/order-lists.bin",$0089,31
Tune7OrderB:
  INCBIN "res/tunes/order-lists.bin",$00A8,11
Tune7OrderC:
  INCBIN "res/tunes/order-lists.bin",$00B3,11
Tune6OrderA:
  INCBIN "res/tunes/order-lists.bin",$00BE,3
SpareOrderListA:
  INCBIN "res/tunes/order-lists.bin",$00C1,5
Tune6OrderB:
  INCBIN "res/tunes/order-lists.bin",$00C6,4
SpareOrderListB:
  INCBIN "res/tunes/order-lists.bin",$00CA,5
Tune6OrderC:
  INCBIN "res/tunes/order-lists.bin",$00CF,9
SpareOrderListC:
  INCBIN "res/tunes/order-lists.bin",$00D8,14
Tune8OrderA:
  INCBIN "res/tunes/order-lists.bin",$00E6,8
Tune8OrderB:
  INCBIN "res/tunes/order-lists.bin",$00EE,8
Tune8OrderC:
  INCBIN "res/tunes/order-lists.bin",$00F6,3
Tune10OrderA:
  INCBIN "res/tunes/order-lists.bin",$00F9,13
Tune10OrderB:
  INCBIN "res/tunes/order-lists.bin",$0106,27
Tune10OrderC:
  INCBIN "res/tunes/order-lists.bin",$0121,33

; The low bytes of the 54 pattern addresses
;
; SequenceChannel $CB5C: a pattern n starts at PatternAddrLow[n] + 256
; PatternAddrHigh[n].
PatternAddrLow:
  INCBIN "res/tunes/pattern-low.bin",$0000,54

; The high bytes of the 54 pattern addresses
;
; SequenceChannel $CB6F.
PatternAddrHigh:
  INCBIN "res/tunes/pattern-high.bin",$0000,54

; Ornaments 1 and 2: 8 bytes each
;
; UpdateOrnament $CC80 finds ornament n at $C4A8 + 8 n (n = 1-15; only 1 and 2
; lie here, a higher n would read Instruments or Effects). +0: bit 7 loop, bits
; 3-5 the frames the first step lasts, bits 0-2 the number of steps after it;
; each step: bits 3-7 semitones above the note, bits 0-2 its frames (0 = 256).
; Ornament 1 ($8A $21 $39): 0, +4, +7 a frame each, looping (a major chord);
; ornament 2 ($8A $21 $01): 0, +4, 0, looping. Patterns 1, 16 and 45 set
; ornament 1; no pattern sets ornament 2.
Ornaments:
  INCBIN "res/tunes/ornaments.bin",$0000,8
Ornament2:
  INCBIN "res/tunes/ornaments.bin",$0008,8

; Instruments 0-6: 10 bytes each (pattern bytes $80-$86)
;
; StartVoice $C754 copies an instrument into a voice: +0 attack step (volume
; per frame, unsigned), +1 decay step (signed), +2 sustain level, +3 release
; step (signed), +4 peak level (volume 0-127, the AY gets volume / 8), +5
; frames before the pitch sweep starts ($FF never), +6 sweep frames (bit 7:
; once; else the sweep swings back and forth, starting with half), +7/+8 sweep
; step (period units per frame, signed), +9 flags (bit 0 tone, bit 1 noise, bit
; 2 the AY's own envelope: shape +0 and period +4, bit 7 the voice is not taken
; by a note). With bit 2, +0 and +4 are the envelope's shape and period. The
; voice's period is the note's plus the sweep's offset.
;
; Read in c1 and the control and load recordings ($C4C5-$C505 in StartVoice's
; reads).
Instruments:
  INCBIN "res/tunes/instruments.bin",$0000,70
