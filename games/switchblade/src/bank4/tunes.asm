; --------------------------------------------------------------------------------------------------------------------
; tunes.asm: The tunes: patterns, order lists, the tune table, arpeggios, instruments, effects, the note table
;
; Three tunes (TuneTable $CCF1): 0 the title (8484 frames, then looped by the glue), 1 the in-game music (10080
; frames, looped), 2 the start jingle (120 frames). They match the AY rips' songs 1, 3 and 2 (title, in-game, start;
; the rips are memory snapshots of this bank: 166 bytes differ, all in the player's state). 45 patterns, of which
; 42-44 (one $FF each) are in no order list.
;
; Every tune is exported as text by work/stage2/ann/BANK4-tmp/tune2txt.py; the format is in BANK4.md.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C4B8

; The 45 patterns: byte streams of notes and commands, each ended by $FF
;
; Read by SequenceChannel $C1C5 and ReadPatternCommand $C31F through
; PatternAddrLo / PatternAddrHi. An event: a note index 0-$7D then the length
; in frames; $7E lo hi length (a raw period); $7F length (a rest). Commands
; before it: $80-$8B instrument slot, $90-$9F arpeggio, $C0 a b c slide on, $C1
; slide off, $FC drum off, $FD a b drum on. Which tune and channel plays each
; pattern: BANK4.md.
Patterns:
Pattern00:
  INCBIN "res/music/tunes.bin",$0000,100
Pattern01:
  INCBIN "res/music/tunes.bin",$0064,30
Pattern02:
  INCBIN "res/music/tunes.bin",$0082,16
Pattern03:
  INCBIN "res/music/tunes.bin",$0092,51
Pattern04:
  INCBIN "res/music/tunes.bin",$00C5,14
Pattern05:
  INCBIN "res/music/tunes.bin",$00D3,26
Pattern06:
  INCBIN "res/music/tunes.bin",$00ED,50
Pattern07:
  INCBIN "res/music/tunes.bin",$011F,100
Pattern08:
  INCBIN "res/music/tunes.bin",$0183,19
Pattern09:
  INCBIN "res/music/tunes.bin",$0196,44
Pattern10:
  INCBIN "res/music/tunes.bin",$01C2,45
Pattern11:
  INCBIN "res/music/tunes.bin",$01EF,96
Pattern12:
  INCBIN "res/music/tunes.bin",$024F,20
Pattern13:
  INCBIN "res/music/tunes.bin",$0263,40
Pattern14:
  INCBIN "res/music/tunes.bin",$028B,112
Pattern15:
  INCBIN "res/music/tunes.bin",$02FB,35
Pattern16:
  INCBIN "res/music/tunes.bin",$031E,4
Pattern17:
  INCBIN "res/music/tunes.bin",$0322,4
Pattern18:
  INCBIN "res/music/tunes.bin",$0326,8
Pattern19:
  INCBIN "res/music/tunes.bin",$032E,40
Pattern20:
  INCBIN "res/music/tunes.bin",$0356,220
Pattern21:
  INCBIN "res/music/tunes.bin",$0432,100
Pattern22:
  INCBIN "res/music/tunes.bin",$0496,49
Pattern23:
  INCBIN "res/music/tunes.bin",$04C7,86
Pattern24:
  INCBIN "res/music/tunes.bin",$051D,35
Pattern25:
  INCBIN "res/music/tunes.bin",$0540,10
Pattern26:
  INCBIN "res/music/tunes.bin",$054A,12
Pattern27:
  INCBIN "res/music/tunes.bin",$0556,11
Pattern28:
  INCBIN "res/music/tunes.bin",$0561,38
Pattern29:
  INCBIN "res/music/tunes.bin",$0587,14
Pattern30:
  INCBIN "res/music/tunes.bin",$0595,17
Pattern31:
  INCBIN "res/music/tunes.bin",$05A6,78
Pattern32:
  INCBIN "res/music/tunes.bin",$05F4,57
Pattern33:
  INCBIN "res/music/tunes.bin",$062D,72
Pattern34:
  INCBIN "res/music/tunes.bin",$0675,75
Pattern35:
  INCBIN "res/music/tunes.bin",$06C0,56
Pattern36:
  INCBIN "res/music/tunes.bin",$06F8,44
Pattern37:
  INCBIN "res/music/tunes.bin",$0724,112
Pattern38:
  INCBIN "res/music/tunes.bin",$0794,14
Pattern39:
  INCBIN "res/music/tunes.bin",$07A2,14
Pattern40:
  INCBIN "res/music/tunes.bin",$07B0,14
Pattern41:
  INCBIN "res/music/tunes.bin",$07BE,30
Pattern42:
  INCBIN "res/music/tunes.bin",$07DC,1
Pattern43:
  INCBIN "res/music/tunes.bin",$07DD,1
Pattern44:
  INCBIN "res/music/tunes.bin",$07DE,1

; The patterns' addresses, low bytes (45)
;
; SequenceChannel $C1C5 at $C254: the address of pattern n is PatternAddrLo[n]
; + 256 x PatternAddrHi[n].
PatternAddrLo:
  INCBIN "res/music/tunes.bin",$07DF,45

; The patterns' addresses, high bytes (45)
PatternAddrHi:
  INCBIN "res/music/tunes.bin",$080C,45

; The three tunes: the order lists of channels A, B and C
;
; StartTune $C0D7 reads TuneTable + 6 x the tune.
TuneTable:
  INCBIN "res/music/tunes.bin",$0839,18
  ASSERT {TuneTable} == OrderLists && {TuneTable+2} == Tune0OrderB && {TuneTable+4} == Tune0OrderC
  ASSERT {TuneTable+6} == Tune1OrderA && {TuneTable+8} == Tune1OrderB && {TuneTable+10} == Tune1OrderC
  ASSERT {TuneTable+12} == Tune2OrderA && {TuneTable+14} == Tune2OrderB && {TuneTable+16} == Tune2OrderC

; The nine order lists: pattern numbers, repeat counts, instrument slots,
; transposes, $FF the end
;
; Read by SequenceChannel $C1C5 (ReadOrderList $C1E9). The lists and what they
; play are in BANK4.md (tune2txt.py prints them). The ends of tune 1's three
; lists ($CE12-$CE22, $CE3B-$CE43, $CE74-$CE7D) are read in no recording: none
; plays the in-game music for its 10080 frames.
OrderLists:
Tune0OrderA:
  INCBIN "res/music/tunes.bin",$084B,91
Tune0OrderB:
  INCBIN "res/music/tunes.bin",$08A6,76
Tune0OrderC:
  INCBIN "res/music/tunes.bin",$08F2,50
Tune1OrderA:
  INCBIN "res/music/tunes.bin",$0924,71
Tune1OrderB:
  INCBIN "res/music/tunes.bin",$096B,33
Tune1OrderC:
  INCBIN "res/music/tunes.bin",$098C,58
Tune2OrderA:
  INCBIN "res/music/tunes.bin",$09C6,3
Tune2OrderB:
  INCBIN "res/music/tunes.bin",$09C9,7
Tune2OrderC:
  INCBIN "res/music/tunes.bin",$09D0,4

; Arpeggios 1-9: 8 bytes each, a header and up to seven steps (two or one used,
; the rest 0)
;
; UpdateArpeggio $C390 reads arpeggio n at Arpeggios-8 + 8 x n; arpeggio 0
; means none, so its place ($CE84-$CE8B) is the end of the order lists. Header:
; bit 7 loop, bits 3-5 the first step's frames (the note itself), bits 0-2 + 1
; the steps. A step: bits 3-7 semitones above the note, bits 0-2 frames. All
; nine loop with one frame a step: 1 (0, 3, 7) minor, 2 (0, 3, 6) diminished, 3
; (0, 4, 9), 4 (0, 3, 9), 5 (0, 4, 7) major, 6 (0, 3, 8), 7 (0, 5, 9), 8 (0,
; 12) the octave, 9 (0, 3, 10).
;
; Read: the first three bytes of each used one; arpeggio 8 is in no pattern.
Arpeggios:
  INCBIN "res/music/arpeggios.bin",$0000,72

; The 14 instruments: 10 bytes, the volume envelope, the vibrato and the mixer
;
; A record: +0 the attack step, +1 the decay step (signed), +2 the sustain
; level, +3 the release step (signed), +4 the peak, all on the volume scale
; 0-$7F (the AY gets volume / 8); +5 the vibrato delay (frames), +6 the vibrato
; width (frames a sweep: 0 one endless sweep, a pitch drop; bit 7 one half
; sweep then stop; else back and forth, the first sweep half as long), +7/+8
; the vibrato step added to the period each frame; +9 flags: bit 0 tone, bit 1
; noise (noise period from the tone period), bit 2 the AY's hardware envelope
; (shape +0, period +4; no instrument uses it).
;
; StartNote $D0DA and the envelope phases $D308-$D358 read it (IY). SlotTables
; gives the instrument for a pattern's $80 + n.
Instruments:
  INCBIN "res/music/instruments.bin",$0000,140

; The 14 sound effects: an instrument (10 bytes), the tone period (word), the
; gate time
;
; PlayEffect $C011 plays effect n from Effects + 13 x n on channel A (an octave
; below the period's pitch, as channel A doubles the period). The game requests
; them through $8454 (BANK4.md lists the sites). Read in the recordings: 7, 10
; and 11 (menu); the rest are known only from the code.
Effects:
  INCBIN "res/music/effects.bin",$0000,182

; The 67 tone periods: index n is MIDI note 40 + n (E2) on channels B and C, an
; octave lower on A
;
; At the 128K's AY clock 1.7734 MHz (f = 110 837 / period). Three entries are
; off the scale: 2 (1236, between F2 and F#2), 6 (988, about A2 where A#2 would
; be 951) and 66 (24, near D8 where A#7 would be 30). Read by SequenceChannel
; $C1C5 and SetNotePeriod $C40D (HL = NoteTable + 2 x the note).
NoteTable:
  INCBIN "res/music/notes.bin",$0000,134

; The copy of AY register 7 (the mixer): bits set = tone / noise off; bits 0-5
; all set = silent
;
; Written by StartNote $D0DA, EnvRelease $D358, Silence $D182 and AyUpdate
; $D1C3 (the drum's end), sent to the AY by AyUpdate.
AyMixer:
  DEFB $3F

; The AY record of channel A (20 bytes)
;
; A record: +$00 the tone-enable mask (AND), +$01 the noise-enable mask, +$02
; the channel's off bits (OR), +$03/+$04 the tone period, +$05 the volume
; 0-$7F, +$06 the gate timer (frames to the release; 0 or $FF stay), +$07 the
; vibrato delay ($FF stopped), +$08 the frames of the sweep, +$09/+$0A the
; vibrato offset, +$0B/+$0C the vibrato step, +$0D/+$0E the envelope phase
; (EnvAttack, EnvDecay, EnvSustain, EnvRelease), +$0F/+$10 the instrument, +$11
; the instrument's flags (bit 7: an effect holds the channel), +$12/+$13 the
; slide offset. Masks of A: $FE, $F7, $09.
;
; The glue reads +$05 ($D0A2), the volume, every frame into $9BA3.
AyChannelA:
  DEFB $FE,$F7,$09,$54,$32,$BB,$33,$BA,$00,$76
  DEFB $22,$05,$32,$06,$04,$0D,$14,$0E,$62,$08
AyChannelB:
  DEFB $FD,$EF,$12,$50,$FA,$33,$2E,$07,$3C,$33 ; channel B: masks $FD, $EF, $12
  DEFB $5B,$33,$6E,$22,$71,$35,$7F,$23,$84,$51
AyChannelC:
  DEFB $FB,$DF,$24,$23,$96,$31,$A0,$53,$A1,$33 ; channel C: masks $FB, $DF, $24
  DEFB $A4,$23,$A7,$B2,$AA,$3A,$B2,$B5,$B2,$BA

; The noise period from the last noise channel's tone period (low byte), sent
; rotated right three times
NoisePeriod:
  DEFB $00
