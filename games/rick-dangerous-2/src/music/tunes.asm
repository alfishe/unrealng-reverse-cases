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
  ; $C000 tune 0 channel A: instrument 0, 19 notes
  INCBIN "res/tunes/patterns.bin",$0000,40
Pattern02:
  ; $C028 tune 0 channel C: instrument 0
  INCBIN "res/tunes/patterns.bin",$0028,38
Pattern08:
  ; $C04E tune 0 channel C: one note of 96 frames
  INCBIN "res/tunes/patterns.bin",$004E,3
Pattern01:
  ; $C051 tune 0 channel B: instrument 1, ornament 1 (the major chord)
  INCBIN "res/tunes/patterns.bin",$0051,39
Pattern09:
  ; $C078 tune 0 channel B: no instrument byte
  INCBIN "res/tunes/patterns.bin",$0078,21
Pattern03:
  ; $C08D in no order list: instrument 4, then Pattern04
  INCBIN "res/tunes/patterns.bin",$008D,1
Pattern04:
  ; $C08E tune 0 channel A
  INCBIN "res/tunes/patterns.bin",$008E,28
Pattern05:
  ; $C0AA tune 0 channel A: one note of 96 frames
  INCBIN "res/tunes/patterns.bin",$00AA,3
Pattern06:
  ; $C0AD tune 0 channel B: instrument 3, eight notes of 96 frames
  INCBIN "res/tunes/patterns.bin",$00AD,18
Pattern07:
  ; $C0BF tune 0 channel C: instrument 2, eight notes of 12 frames
  INCBIN "res/tunes/patterns.bin",$00BF,18
Pattern10:
  ; $C0D1 in no order list: instrument 0, then Pattern11
  INCBIN "res/tunes/patterns.bin",$00D1,1
Pattern11:
  ; $C0D2 tune 3 channel A
  INCBIN "res/tunes/patterns.bin",$00D2,10
Pattern12:
  ; $C0DC tune 3 channel B: a rest of 56 frames, one note
  INCBIN "res/tunes/patterns.bin",$00DC,6
Pattern13:
  ; $C0E2 tune 3 channel C: a rest of 56 frames, one note
  INCBIN "res/tunes/patterns.bin",$00E2,6
Pattern14:
  ; $C0E8 tune 2 (game over) channel A
  INCBIN "res/tunes/patterns.bin",$00E8,20
Pattern15:
  ; $C0FC tune 2 channel B
  INCBIN "res/tunes/patterns.bin",$00FC,18
Pattern16:
  ; $C10E tune 2 channel C: instrument 2, ornament 1
  INCBIN "res/tunes/patterns.bin",$010E,9
Pattern17:
  ; $C117 also pattern 18: tune 1 (the signal) channel A
  INCBIN "res/tunes/patterns.bin",$0117,8
Pattern19:
  ; $C11F tune 1 channel B
  INCBIN "res/tunes/patterns.bin",$011F,8
Pattern20:
  ; $C127 tune 1 channel C
  INCBIN "res/tunes/patterns.bin",$0127,8
Pattern21:
  ; $C12F tune 5 (level 1) channel A: instrument 4, then Pattern22
  INCBIN "res/tunes/patterns.bin",$012F,1
Pattern22:
  ; $C130 tune 5 channel C
  INCBIN "res/tunes/patterns.bin",$0130,29
Pattern23:
  ; $C14D tune 5 channel C: a rest of 8 frames, instrument 5
  INCBIN "res/tunes/patterns.bin",$014D,4
Pattern24:
  ; $C151 tune 5 channel B: instrument 6, two rests of 128 frames, notes of
  ;   64
  INCBIN "res/tunes/patterns.bin",$0151,22
Pattern25:
  ; $C167 tune 9 (level 5) channel A: instrument 4, then Pattern27
  INCBIN "res/tunes/patterns.bin",$0167,1
Pattern27:
  ; $C168 tune 9 channel C
  INCBIN "res/tunes/patterns.bin",$0168,25
Pattern26:
  ; $C181 tune 9 channel B: instrument 6
  INCBIN "res/tunes/patterns.bin",$0181,10
Pattern28:
  ; $C18B tune 9 channel C: a rest of 8 frames, instrument 5
  INCBIN "res/tunes/patterns.bin",$018B,4
Pattern29:
  ; $C18F tune 7 (level 3) channel A
  INCBIN "res/tunes/patterns.bin",$018F,14
Pattern30:
  ; $C19D tune 7 channel B
  INCBIN "res/tunes/patterns.bin",$019D,10
Pattern31:
  ; $C1A7 also pattern 32: tune 7 channel C
  INCBIN "res/tunes/patterns.bin",$01A7,6
Pattern33:
  ; $C1AD tune 6 (level 2) channel A: instrument 5
  INCBIN "res/tunes/patterns.bin",$01AD,34
Pattern34:
  ; $C1CF in no order list: instrument 5, four notes of 48 frames
  INCBIN "res/tunes/patterns.bin",$01CF,10
Pattern35:
  ; $C1D9 tune 6 channel B: instrument 5, a rest of 6 frames, then
  ;   Pattern36
  INCBIN "res/tunes/patterns.bin",$01D9,3
Pattern36:
  ; $C1DC tune 6 channel B
  INCBIN "res/tunes/patterns.bin",$01DC,17
Pattern37:
  ; $C1ED tune 6 channel C: instrument 6
  INCBIN "res/tunes/patterns.bin",$01ED,18
Pattern38:
  ; $C1FF tune 6 channel C: a rest of 96 frames
  INCBIN "res/tunes/patterns.bin",$01FF,3
Pattern39:
  ; $C202 tune 8 (level 4) channel A: instrument 5
  INCBIN "res/tunes/patterns.bin",$0202,26
Pattern40:
  ; $C21C also pattern 41: tune 8 channel B
  INCBIN "res/tunes/patterns.bin",$021C,18
Pattern42:
  ; $C22E tune 8 channel C
  INCBIN "res/tunes/patterns.bin",$022E,10
Pattern43:
  ; $C238 tune 10 (the Fat Guy end) channel A: instrument 0
  INCBIN "res/tunes/patterns.bin",$0238,9
Pattern48:
  ; $C241 tune 10 channel A: the last three notes of Pattern43
  INCBIN "res/tunes/patterns.bin",$0241,7
Pattern44:
  ; $C248 tune 10 channel B
  INCBIN "res/tunes/patterns.bin",$0248,16
Pattern45:
  ; $C258 tune 10 channel C: instrument 4, ornament 1, then Pattern46
  INCBIN "res/tunes/patterns.bin",$0258,34
Pattern46:
  ; $C27A tune 10 channel C
  INCBIN "res/tunes/patterns.bin",$027A,15
Pattern47:
  ; $C289 tune 10 channel C
  INCBIN "res/tunes/patterns.bin",$0289,21
Pattern49:
  ; $C29E tune 10 channel A
  INCBIN "res/tunes/patterns.bin",$029E,7
Pattern50:
  ; $C2A5 tune 10 channel B: instrument 6
  INCBIN "res/tunes/patterns.bin",$02A5,14
Pattern51:
  ; $C2B3 tune 10 channel B
  INCBIN "res/tunes/patterns.bin",$02B3,5
Pattern52:
  ; $C2B8 tune 10 channel B
  INCBIN "res/tunes/patterns.bin",$02B8,5
Pattern53:
  ; $C2BD tune 10 channel B: one note of 96 frames
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
  ; $C2C0 tune 0: the control menu ($80B9) and the CONGRATULATIONS end
  ;   ($875D)
  ; $C2C6 tune 1: the signal (the cheat chords $7D3B, $7D55; the countdown
  ;   bonus start $9CC6 and stop $9CDB)
  ; $C2CC tune 2: game over ($7E20)
  ; $C2D2 tune 3: no call site in the game
  ; $C2D8 tune 4: silence, before a level loads ($7CD2)
  ; $C2DE tune 5: level 1 (LevelTune $7CE3, Level + 4)
  ; $C2E4 tune 6: level 2
  ; $C2EA tune 7: level 3
  ; $C2F0 tune 8: level 4
  ; $C2F6 tune 9: level 5
  ; $C2FC tune 10: the Fat Guy end after the lives tally ($874B)
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
  ; $C302 $FF: tune 4's three channels
  INCBIN "res/tunes/order-lists.bin",$0000,1
Tune0OrderA:
  ; $C303 patterns 0 0, +3: 0 0, -12: 4 5, -14: 4, -8: 5, 0: 0 0
  INCBIN "res/tunes/order-lists.bin",$0001,21
Tune0OrderB:
  INCBIN "res/tunes/order-lists.bin",$0016,22
Tune0OrderC:
  INCBIN "res/tunes/order-lists.bin",$002C,41
Tune3OrderA:
  ; $C357 11, +3: 11
  INCBIN "res/tunes/order-lists.bin",$0055,5
Tune3OrderB:
  INCBIN "res/tunes/order-lists.bin",$005A,5
Tune3OrderC:
  INCBIN "res/tunes/order-lists.bin",$005F,5
Tune2OrderA:
  ; $C366 14
  INCBIN "res/tunes/order-lists.bin",$0064,2
Tune2OrderB:
  ; $C368 15
  INCBIN "res/tunes/order-lists.bin",$0066,2
Tune2OrderC:
  ; $C36A 16
  INCBIN "res/tunes/order-lists.bin",$0068,2
Tune1OrderA:
  ; $C36C 18
  INCBIN "res/tunes/order-lists.bin",$006A,2
Tune1OrderB:
  ; $C36E 19
  INCBIN "res/tunes/order-lists.bin",$006C,2
Tune1OrderC:
  ; $C370 20
  INCBIN "res/tunes/order-lists.bin",$006E,2
Tune5OrderA:
  ; $C372 21 twelve times
  INCBIN "res/tunes/order-lists.bin",$0070,3
Tune5OrderB:
  ; $C375 24, +5: 24
  INCBIN "res/tunes/order-lists.bin",$0073,5
Tune5OrderC:
  ; $C37A 23, 22 twelve times
  INCBIN "res/tunes/order-lists.bin",$0078,4
Tune9OrderA:
  ; $C37E 25 eleven times
  ; $C381 a spare $FF
  INCBIN "res/tunes/order-lists.bin",$007C,4
Tune9OrderB:
  ; $C382 26 four times
  ; $C385 a spare $FF
  INCBIN "res/tunes/order-lists.bin",$0080,4
Tune9OrderC:
  ; $C386 28, 27 eleven times
  ; $C38A a spare $FF
  INCBIN "res/tunes/order-lists.bin",$0084,5
Tune7OrderA:
  ; $C38B pattern 29 sixteen times over the transposes 0, +3, +6
  INCBIN "res/tunes/order-lists.bin",$0089,31
Tune7OrderB:
  INCBIN "res/tunes/order-lists.bin",$00A8,11
Tune7OrderC:
  INCBIN "res/tunes/order-lists.bin",$00B3,11
Tune6OrderA:
  ; $C3C0 33 eight times
  INCBIN "res/tunes/order-lists.bin",$00BE,3
SpareOrderListA:
  ; $C3C3 not in TuneTable: +7, pattern 33 four times
  INCBIN "res/tunes/order-lists.bin",$00C1,5
Tune6OrderB:
  ; $C3C8 35, 36 fourteen times
  INCBIN "res/tunes/order-lists.bin",$00C6,4
SpareOrderListB:
  ; $C3CC not in TuneTable: +7, pattern 36 eight times
  INCBIN "res/tunes/order-lists.bin",$00CA,5
Tune6OrderC:
  INCBIN "res/tunes/order-lists.bin",$00CF,9
SpareOrderListC:
  ; $C3DA not in TuneTable: patterns 37 and 38 under -5, +7, 0
  INCBIN "res/tunes/order-lists.bin",$00D8,14
Tune8OrderA:
  INCBIN "res/tunes/order-lists.bin",$00E6,8
Tune8OrderB:
  INCBIN "res/tunes/order-lists.bin",$00EE,8
Tune8OrderC:
  ; $C3F8 42 sixteen times
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
  ; $C4C0 instrument 0: attack 114, decay -32 to 56, peak 64, release -4,
  ;   vibrato step 2 after 18 frames, 4 frames each way
  ; $C4CA instrument 1: attack 64 to 54, decay -4 to 0, no sweep
  ; $C4D4 instrument 2: as 0, sustain 50, peak 56
  ; $C4DE instrument 3: as 0, sustain 70, peak 80
  ; $C4E8 instrument 4: peak 127 at once, decay -4 to 0
  ; $C4F2 instrument 5: peak 100 at once, decay -4 to 0
  ; $C4FC instrument 6: slow attack 6 to 64, decay -1 to 60, release -1,
  ;   vibrato step 2 after 16 frames, 5 frames each way
  INCBIN "res/tunes/instruments.bin",$0000,70
