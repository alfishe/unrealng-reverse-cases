; --------------------------------------------------------------------------------------------------------------------
; tunes.asm: The tune data and the player's tables: periods, vibratos, arpeggios, tunes, order lists, patterns, envelope rates
;
; The tune format, for a converter (all of it in tunes, music/tunes, $C967-$CD35): TuneTable $C967 holds 4 entries of
; 3 little-endian words, each the address of a channel's order list (A, B, C). An order list is bytes read one after
; another: $00-$7F pattern n; $80 t transpose (t signed); $A0+n the next pattern n times (0: 256); $C0 d detune d;
; $E0+n m instrument slot n = record offset m (9 x record); $FF the tune's end (the first channel to meet it ends the
; tune; the next frame tune 0 starts again). A pattern, found through PatternLo $CA37 / PatternHi $CA52, is events
; ended by $FF: n d (n $00-$7F) a note of d frames; $A0 d a rest of d frames; $80+n instrument slot n; $90+n arpeggio
; n (0 off); $BF slide off; $C0+s lo hi c a slide (bit 5 of the command: period up). Note n sounds at period-table
; index n + 20 + the channel's transpose (MIDI n + 32 + transpose). A step of the text format is one event; the time
; of a note or rest is its d frames (0 = 256), every other event takes none.
;
; The instruments (Instruments $C028, music/instruments), the instrument slots (SlotTable $C11B, the state module),
; the vibratos (VibratoTable $C906), the arpeggios (ArpeggioTable $C927) and the envelope rates (AttackRates $CD36,
; DecayRates $CD46) belong to the tune too: a converter needs them to give each note its volume curve. The periods
; (PeriodLo $C82E, PeriodHi $C89A) are the player's equal-tempered table.
;
; Tune 0 (3 min 14 s): channel A plays the bass (patterns 0, 3, then pattern 5 transposed through -7, -12, -9, -7, -4,
; -6, then pattern 10, 15), channel B the same intro detuned by 10, then the melody (pattern 6), then the chords (13,
; 16, 18, 19 with arpeggios 2-6 and the noise beats of instrument 8), channel C the noise rhythm (pattern 2), the
; arpeggiated line (7-9, transposed +12 / +14), then 11, 14, 17, 20. Tune 1 is tune 0 from pattern 10 on.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C82D

; A pattern of no events: every channel's pattern at a tune's start
;
; StartTune $C79F points PatternPointers $C1DA at it, so a channel's first
; frame reads $FF and goes to its order list. Witness: read by every recording
; that starts a tune (c1, explorers, the rzx pieces with an EndTune).
EmptyPattern:
  DEFB $FF

; The tone periods' low bytes: 108 notes, C0 to B8
;
; Index i (StartNote $C4C9: the note + 20 + the transpose; ArpeggioEffect adds
; the step's semitones) is MIDI note i + 12 at the AY clock of 1.7734 MHz:
; index 57 = 252 = A4 (439.8 Hz). The period is PeriodLo[i] + 256 x
; PeriodHi[i]. Two flaws: every C# (indices 1, 13, 25, ..., 85) is 0.38
; semitone flat, and index 8 (G#0, 4526) is G0's period again. Tune 0 plays C#
; at indices 25 and 61 (7 notes). The recordings read indices 14-96.
PeriodLo:
  DEFB $7A,$8C,$97,$44,$04,$D6,$B9,$AC,$AE,$BE,$DC,$07 ; octave 0 (indices
                                                       ; 0-11)
  DEFB $3D,$C6,$CB,$22,$82,$EB,$5D,$D6,$57,$DF,$6E,$03 ; octave 1
  DEFB $9F,$63,$E6,$91,$41,$F6,$AE,$6B,$2C,$F0,$B7,$82 ; octave 2
  DEFB $4F,$31,$F3,$C8,$A0,$7B,$57,$35,$16,$F8,$DC,$C1 ; octave 3
  DEFB $A8,$99,$79,$64,$50,$3D,$2C,$1B,$0B,$FC,$EE,$E0 ; octave 4
  DEFB $D4,$CC,$BD,$B2,$A8,$9F,$96,$8D,$85,$7E,$77,$70 ; octave 5
  DEFB $6A,$66,$5E,$59,$54,$4F,$4B,$47,$43,$3F,$3B,$38 ; octave 6
  DEFB $35,$33,$2F,$2D,$2A,$28,$25,$23,$21,$1F,$1E,$1C ; octave 7
  DEFB $1A,$19,$18,$16,$15,$14,$13,$12,$11,$10,$0F,$0E ; octave 8

; The tone periods' high bytes: 108 notes
;
; As PeriodLo. Its last 8 bytes ($C8FE-$C905, all 0) are also VibratoTable-8's
; record 0, which no instrument names (offset 0 is no vibrato).
PeriodHi:
  DEFB $1A,$19,$17,$16,$15,$13,$12,$11,$11,$0F,$0E,$0E
  DEFB $0D,$0C,$0B,$0B,$0A,$09,$09,$08,$08,$07,$07,$07 ; octave 1
  DEFB $06,$06,$05,$05,$05,$04,$04,$04,$04,$03,$03,$03 ; octave 2
  DEFB $03,$03,$02,$02,$02,$02,$02,$02,$02,$01,$01,$01 ; octave 3
  DEFB $01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$00,$00 ; octave 4
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; octave 5
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; octave 6
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; octave 7
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; octave 8

; The vibrato record at offset 8: a delay of 40 frames, the deltas +1, 0, -1,
; 0, +1, 0, -1
;
; Addressed as VibratoTable-8 + the instrument's +7 (StartNote $C51E,
; VibratoStep $C631): byte 0 the delay (bit 7 clear) or cycles (bit 7 set),
; bytes 1-7 the signed period deltas of one half cycle. Instruments 4, 5 and 7
; name it. Witness: the recordings read all 8 bytes.
VibratoTable:
  INCBIN "res/music/vibratos.bin",$0000,8

; 25 bytes after the vibrato record that nothing reads
;
; No instrument's +7 points here and no recording reads them; as vibrato
; records their deltas would be 18 to 128 period units. Known only from the
; code: left over.
VibratoSpare:
  DEFB $10,$12,$14,$16,$20,$40,$50,$80
  DEFB $03,$15,$27,$15,$16,$04,$27,$10
  DEFB $14,$17,$02,$40,$52,$10,$16,$82
  DEFB $65

; The arpeggios: 8 records of 8 bytes, record n at ArpeggioTable + 8n (n 1-7; 0
; is off)
;
; A record: a header (bit 7: loop; bits 3-6: the hold of the base note at the
; note's start, + 1; bits 0-2: the number of steps), then the steps (bits 3-7:
; the semitones over the note, bits 0-2: the hold in frames, 0 = 256). Read by
; StartNote $C52A and ArpeggioEffect $C694. Witness: the recordings read
; records 1-6 (the header and the steps).
ArpeggioTable:
  INCBIN "res/music/arpeggios.bin",$0000,64

; The tunes: 4 entries of 3 words, the order lists of channels A, B and C
;
; StartTune $C79F: TunePointer $C14B = TuneTable + 6 x tune. Tunes 0, 2 and 3
; are the same entry; tune 1 has its own lists. Only tune 0 is ever started
; (the player module). Witness: the recordings read entry 0 ($C967-$C96C) only.
TuneTable:
  INCBIN "res/music/tunes.bin",$0000,24
  ASSERT {TuneTable} == Tune0OrderA && {TuneTable+2} == Tune0OrderB && {TuneTable+4} == Tune0OrderC
  ASSERT {TuneTable+6} == Tune1OrderA && {TuneTable+8} == Tune1OrderB && {TuneTable+10} == Tune1OrderC
  ASSERT {TuneTable+12} == Tune0OrderA && {TuneTable+14} == Tune0OrderB && {TuneTable+16} == Tune0OrderC
  ASSERT {TuneTable+18} == Tune0OrderA && {TuneTable+20} == Tune0OrderB && {TuneTable+22} == Tune0OrderC

; Tune 0, channel A: the order list (9696 frames)
;
; Read by ReadOrderList $C310 and the order commands. Witness: the recordings
; read it whole.
Tune0OrderA:
  INCBIN "res/music/tunes.bin",$0018,51

; Tune 0, channel B: the order list (9696 frames)
;
; Read by ReadOrderList $C310 and the order commands. Witness: the recordings
; read it whole.
Tune0OrderB:
  INCBIN "res/music/tunes.bin",$004B,40

; Tune 0, channel C: the order list (10 236 frames, cut at 9696 by channel A's
; end)
;
; Read by ReadOrderList $C310 and the order commands. Witness: the recordings
; read it whole.
Tune0OrderC:
  INCBIN "res/music/tunes.bin",$0073,43

; Tune 1, channel A: the order list (4728 frames)
;
; Known only from the code: tune 1 is never started, no recording reads it.
Tune1OrderA:
  INCBIN "res/music/tunes.bin",$009E,10

; Tune 1, channel B: the order list (4728 frames)
;
; Known only from the code: tune 1 is never started, no recording reads it.
Tune1OrderB:
  INCBIN "res/music/tunes.bin",$00A8,23

; Tune 1, channel C: the order list (5268 frames)
;
; Known only from the code: tune 1 is never started, no recording reads it.
Tune1OrderC:
  INCBIN "res/music/tunes.bin",$00BF,15

; Two $FF bytes after tune 1's channel C list
;
; Not read in any recording (known only from the code).
TuneSpare:
  INCBIN "res/music/tunes.bin",$00CE,2

; The 27 patterns' addresses: the low bytes
;
; StartPattern $C353: pattern n is at PatternLo[n] + 256 x PatternHi[n].
; Witness: the recordings read the entries of the patterns tune 0 plays.
PatternLo:
  INCBIN "res/music/tunes.bin",$00D0,27

; The 27 patterns' addresses: the high bytes
;
; As PatternLo.
PatternHi:
  INCBIN "res/music/tunes.bin",$00EB,27

; Pattern 0: 432 frames (tune 0 A x3, tune 0 B x5)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern0:
  INCBIN "res/music/tunes.bin",$0106,10

; Pattern 1: 432 frames (tune 1 B x2)
;
; Known only from the code: no played tune holds it, no recording reads it.
Pattern1:
  INCBIN "res/music/tunes.bin",$0110,15

; Pattern 2: 54 frames (tune 0 C x66, tune 1 C x30)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern2:
  INCBIN "res/music/tunes.bin",$011F,13

; Pattern 3: 216 frames (tune 0 A x1, tune 0 B x1)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern3:
  INCBIN "res/music/tunes.bin",$012C,8

; Pattern 4: 648 frames (no tune)
;
; Known only from the code: no played tune holds it, no recording reads it.
Pattern4:
  INCBIN "res/music/tunes.bin",$0134,17

; Pattern 5: 108 frames (tune 0 A x32, tune 0 B x4)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern5:
  INCBIN "res/music/tunes.bin",$0145,22

; Pattern 6: 1728 frames (tune 0 B x2)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern6:
  INCBIN "res/music/tunes.bin",$015B,52

; Pattern 7: 108 frames (tune 0 C x20)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern7:
  INCBIN "res/music/tunes.bin",$018F,27

; Pattern 8: 108 frames (tune 0 C x4)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern8:
  INCBIN "res/music/tunes.bin",$01AA,27

; Pattern 9: 108 frames (tune 0 C x4)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern9:
  INCBIN "res/music/tunes.bin",$01C5,28

; Pattern 10: 384 frames (tune 0 A x8, tune 1 A x8)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern10:
  INCBIN "res/music/tunes.bin",$01E1,66

; Pattern 11: 384 frames (tune 0 C x3, tune 1 C x3)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern11:
  INCBIN "res/music/tunes.bin",$0223,66

; Pattern 12: 144 frames (tune 0 B x1)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern12:
  INCBIN "res/music/tunes.bin",$0265,3

; Pattern 13: 384 frames (tune 0 B x6, tune 1 B x6)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern13:
  INCBIN "res/music/tunes.bin",$0268,98

; Pattern 14: 384 frames (tune 0 C x4, tune 1 C x4)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern14:
  INCBIN "res/music/tunes.bin",$02CA,46

; Pattern 15: 1656 frames (tune 0 A x1, tune 1 A x1)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern15:
  INCBIN "res/music/tunes.bin",$02F8,34

; Pattern 16: 384 frames (tune 0 B x1, tune 1 B x1)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern16:
  INCBIN "res/music/tunes.bin",$031A,96

; Pattern 17: 384 frames (tune 0 C x1, tune 1 C x1)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern17:
  INCBIN "res/music/tunes.bin",$037A,46

; Pattern 18: 96 frames (tune 0 B x2, tune 1 B x2)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern18:
  INCBIN "res/music/tunes.bin",$03A8,15

; Pattern 19: 72 frames (tune 0 B x3, tune 1 B x3)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern19:
  INCBIN "res/music/tunes.bin",$03B7,12

; Pattern 20: 192 frames (tune 0 C x1, tune 1 C x1)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern20:
  INCBIN "res/music/tunes.bin",$03C3,4

; Pattern 21: empty ($FF only); no tune plays it
;
; Not read in any recording (known only from the code).
Pattern21:
  INCBIN "res/music/tunes.bin",$03C7,1

; Pattern 22: empty ($FF only); no tune plays it
;
; Not read in any recording (known only from the code).
Pattern22:
  INCBIN "res/music/tunes.bin",$03C8,1

; Pattern 23: empty ($FF only); no tune plays it
;
; Not read in any recording (known only from the code).
Pattern23:
  INCBIN "res/music/tunes.bin",$03C9,1

; Pattern 24: empty ($FF only); no tune plays it
;
; Not read in any recording (known only from the code).
Pattern24:
  INCBIN "res/music/tunes.bin",$03CA,1

; Pattern 25: empty ($FF only); no tune plays it
;
; Not read in any recording (known only from the code).
Pattern25:
  INCBIN "res/music/tunes.bin",$03CB,1

; Pattern 26: 192 frames (tune 0 B x1, tune 0 C x2, tune 1 B x4, tune 1 C x2)
;
; Read by ReadPatternEvent $C2F6, PatternEvent $C36D, StartNote $C4C9 and
; FetchPatternByte $C825. Witness: the recordings read it whole.
Pattern26:
  INCBIN "res/music/tunes.bin",$03CC,3

; The attack rates: an instrument's +3 high nibble 1-15 (0 is the default, 15 a
; frame)
;
; Below $80: that many volume steps every frame; $80 + n: one step every n
; frames. Read by SetInstrument $C444. Witness: the recordings read entry 7 (4
; a frame, instruments 4 and 7).
AttackRates:
  INCBIN "res/music/envelope-rates.bin",$0000,16

; The decay and release rates: an instrument's +3 and +4 low nibbles 1-15
;
; As AttackRates; read by SetInstrument $C477 (decay) and $C4A0 (release).
; Witness: the recordings read entries 6-10, 12 and 13.
DecayRates:
  INCBIN "res/music/envelope-rates.bin",$0010,16

  ORG $CD5D

; The rest of the block: 1187 bytes the player never reads
;
; Known only from the code: no instruction reads $CD5D-$D1FF and no recording
; reads it in RAM 6; the copy brings it along with the player ($6D5D-$71FF on
; the tape). Bit patterns, not tune data (no pointer leads here).
MusicLeftover:
  DEFB $00,$02,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $3F,$FF,$FF,$FE,$E7,$FF,$00,$00,$00,$00,$00,$00,$00,$38,$38,$00
  DEFB $00,$78,$10,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03
  DEFB $F8,$15,$E3,$FF,$FF,$FB,$A0,$00,$00,$00,$00,$00,$00,$DB,$6D,$B6
  DEFB $B0,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $2D,$DF,$FF,$FA,$80,$0F,$BA,$C0,$00,$00,$00,$00,$00,$1F,$E1,$7F
  DEFB $FF,$A2,$00,$06,$08,$00,$02,$24,$91,$20,$00,$00,$00,$00,$00,$00
  DEFB $1F,$AF,$7F,$5C,$87,$E0,$00,$00,$00,$00,$00,$00,$07,$C8,$1F,$FF
  DEFB $FF,$DA,$00,$0A,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$0D,$58,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$05,$51,$FF,$FF,$D0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $03,$FF,$F3,$FF,$FF,$FD,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF
  DEFB $FF,$FF,$B9,$FF,$E7,$FD,$80,$00,$00,$00,$00,$00,$00,$0C,$0F,$80
  DEFB $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $0F,$FF,$FF,$FB,$B9,$FF,$C0,$00,$00,$00,$00,$00,$00,$30,$10,$00
  DEFB $00,$FC,$18,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03
  DEFB $FF,$67,$FC,$FF,$FF,$EE,$F0,$00,$00,$00,$00,$00,$01,$00,$00,$00
  DEFB $00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $53,$7F,$FF,$F6,$40,$00,$FF,$E0,$00,$00,$00,$00,$01,$FF,$FE,$3F
  DEFB $FF,$B5,$00,$00,$00,$00,$02,$91,$44,$0A,$A0,$00,$00,$00,$00,$00
  DEFB $3F,$9F,$DD,$F7,$3F,$F0,$00,$00,$00,$00,$00,$00,$00,$31,$4F,$FF
  DEFB $FF,$E4,$54,$50,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$FE,$A8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$0D,$A3,$FF,$FF,$70,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $03,$FF,$FC,$FF,$FF,$F7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$FF
  DEFB $FF,$FF,$EE,$3F,$F9,$FF,$00,$00,$00,$00,$00,$00,$00,$0C,$0E,$00
  DEFB $00,$01,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $13,$FF,$FF,$FE,$EA,$7F,$C0,$00,$00,$00,$00,$00,$00,$20,$00,$01
  DEFB $81,$FE,$08,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DEFB $FD,$DF,$FF,$1F,$FF,$FB,$B8,$00,$00,$00,$00,$00,$02,$00,$00,$00
  DEFB $00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $29,$DF,$FF,$FC,$A0,$00,$01,$F0,$00,$00,$00,$00,$03,$FF,$FF,$FF
  DEFB $FF,$D0,$A2,$AA,$A0,$00,$15,$44,$00,$95,$54,$00,$00,$00,$00,$00
  DEFB $3F,$AF,$77,$58,$7F,$F0,$00,$00,$00,$00,$00,$00,$00,$08,$01,$FF
  DEFB $FF,$D2,$0A,$88,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$3E,$FF,$F8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$1E,$0F,$FF,$FF,$D8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $03,$FF,$FF,$3F,$FF,$FD,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $50,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$FF
  DEFB $FF,$FF,$FB,$8F,$FE,$7D,$C0,$00,$00,$00,$00,$00,$00,$1F,$F8,$00
  DEFB $00,$00,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $1C,$7F,$FF,$FF,$BE,$8F,$C0,$00,$00,$00,$00,$00,$00,$20,$00,$03
  DEFB $C1,$CE,$08,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07
  DEFB $FF,$77,$FF,$C7,$FF,$FE,$EC,$00,$00,$00,$00,$00,$04,$00,$00,$00
  DEFB $00,$00,$00,$41,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $54,$77,$FF,$FB,$54,$00,$00,$30,$00,$00,$00,$00,$03,$FE,$FF,$FF
  DEFB $FF,$A5,$45,$01,$00,$00,$2A,$A0,$08,$0A,$AA,$00,$00,$00,$00,$00
  DEFB $1F,$DD,$DD,$F4,$FF,$E0,$00,$00,$00,$00,$00,$00,$00,$04,$44,$1F
  DEFB $FF,$A0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$7E,$7F,$F6,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$1F,$FF,$FF,$FF,$F4,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $18,$3F,$FF,$CF,$FF,$F7,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3F
  DEFB $FF,$F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$FF
  DEFB $FF,$FF,$FE,$E3,$FF,$9F,$40,$00,$00,$00,$00,$00,$00,$1F,$F0,$00
  DEFB $00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $38,$8F,$FF,$FF,$EB,$B3,$C0,$00,$00,$00,$00,$00,$00,$20,$00,$03
  DEFB $C1,$DE,$04,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0F
  DEFB $F5,$FF,$FF,$E1,$FF,$FB,$BA,$00,$00,$00,$00,$00,$08,$00,$00,$00
  DEFB $00,$00,$00,$20,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $0A,$9F,$FF,$E5,$8A,$00,$00,$00,$00,$00,$00,$00,$07,$FF,$7F,$FF
  DEFB $FF,$C0,$A2,$82,$20,$01,$54,$50,$40,$55,$15,$00,$00,$00,$00,$00
  DEFB $01,$77,$77,$53,$FF,$F0,$00,$00,$00,$00,$00,$00,$00,$20,$22,$A1
  DEFB $FF,$C0,$2A,$88,$00,$02,$AA,$28,$00,$0A,$80,$80,$00,$00,$00,$00
  DEFB $0D,$DD,$DD,$EF,$FF,$FC,$00,$00,$00,$00,$00,$00,$00,$00,$41,$04
  DEFB $7E,$90,$10
