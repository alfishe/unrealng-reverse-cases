; --------------------------------------------------------------------------------------------------------------------
; state.asm: The player's state: the instruments, the instrument slots, the channel records
;
; Instruments $C028: 27 records of 9 bytes, of which records 0-10 are real and 11-26 blank. A record: +0, +1 not read
; (+1 is 8 in every record); +2 bit 7: noise (the channel's tone off, noise on; bit 7 clear: tone on, noise off; the
; other bits are not read: the values $11, $17, $21, $41, $81 are those of the C64 SID's waveform register, $81
; noise); +3 the attack (high nibble) and decay (low nibble) rates, +4 the sustain level (high nibble) and the release
; rate (low nibble), each rate an index into AttackRates $CD36 or DecayRates $CD46 (0: the whole step, 15, in one
; frame); +5 the gate-off time: the release starts when the note timer reaches it (2 in every record); +6 not read; +7
; the vibrato: an offset into VibratoTable-8 (0 none); +8 the peak volume (0-15) the attack climbs to.
;
; A pattern's instrument command $8n takes slot n of the channel: SlotTable $C11B + 8 x channel + n holds the record's
; offset (9 x record) from Instruments. SlotTable starts as records 0-7 in slots 0-7 for every channel; the order-list
; command $E0+n, m writes m into slot n of the channel and the change stays: StartTune does not reset SlotTable, so
; tune 0's second and later passes start with channel B's slot 0 = record 8 (noise) and slot 6 = record 10 (peak 12),
; where the first pass had records 0 and 6 (explorers writes $C123 and $C129 at frames 5621-8645, the first EndTune at
; 9581).
;
; A channel record (45 bytes: ChannelA $C153, ChannelB $C180, ChannelC $C1AD; StartTune clears all three): +$00 the
; order-list position, +$01 the transpose (signed, in semitones), +$02 the pattern position, +$03 the note timer
; (frames left; 0: read the next event), +$04 the pattern repeats left, +$06 the gate-off time, +$09 the detune (added
; to the period), +$0A the vibrato delay or cycles, +$0B the vibrato record offset, +$0C the vibrato step (bits 0-6,
; 1-7) and direction (bit 7), +$10 the arpeggio record offset (8n, 0 none), +$11 the slide count ($FF endless),
; +$12/$13 the slide step, +$14 the slide delay, +$15 the slide command byte (bit 5 the direction), +$16 the rest
; timer, +$17 the arpeggio step ($FF, $FE: ended), +$18 the arpeggio hold, +$1C the note's period-table index,
; +$1D/$1E the tone period, +$1F the volume (0-15), +$20 the sustain level, +$21/$22/$23 the decay step, rate (bit 7:
; done) and counter, +$24/$25/$26 the same for the attack, +$27/$28/$29 for the release, +$2A bit 0 the gate (1
; attack/decay/sustain, 0 release), +$2B the peak volume. +$05, +$07, +$08, +$0D-$0F, +$19-$1B and +$2C are not used.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C027

; 0: start tune 0 at the next call; 1: a tune is playing
;
; Read by MusicTick $C014 and UpdateTune $C1E4, set to 1 by StartTune $C79F, to
; 0 by EndTune $C780. The image holds 0, so the first call after the copy
; starts tune 0. Explorers writes it at frames 9581 and 9582 (the tune's end
; and the restart).
PlayerState:
  DEFB $00

; The instruments: 27 records of 9 bytes (the shape in the module's header)
;
; Selected through SlotTable by SetInstrument $C3D8 (IY = the record). Rates
; below are AttackRates/DecayRates entries: "n/f" n volume steps a frame,
; "1/nf" one step every n frames. Who uses a record is tune 0's use (the
; channel and pattern). Every real record has sustain 0, release index 10
; (1/5f; with the gate off 2 frames before a note's end the release never
; steps: its code $C5F0 ran in no recording) and gate-off time 2.
;
; Witness: the recordings read records 0 and 2-10 (records 1 and 11-26 are read
; in none).
Instruments:
  INCBIN "res/music/instruments.bin",$0000,243

; The instrument slots: 8 x channel + slot -> the record's offset (9 x record)
; in Instruments
;
; Read by SetInstrument $C3D8 (index 8 x channel + n, n 0-15), written by
; SetSlot $C7F7 (8 x channel + n, n 0-31), so 48 bytes: rows 0-2 are channels
; A, B and C, rows 3-5 are reached only by an n beyond the channel's 8 slots
; (no tune does).
;
; Witness: the recordings read channel A slots 0, 3, 6, channel B 0, 3, 4, 6,
; channel C 2, 5, 6, 7; explorers writes $C123 (B slot 0: $48, record 8) and
; $C129 (B slot 6: $51, then $5A).
SlotTable:
  INCBIN "res/music/slots.bin",$0000,48

; The current tune's entry in TuneTable
;
; Set by StartTune $C79F (TuneTable + 6 x tune), read by UpdateTune $C1E4 for
; each channel's order list.
TunePointer:
  DEFW $0000

; Not 0: a note ended this frame (no effects, no AY write)
;
; UpdateTune $C1E4 adds 1 for each channel whose note timer is 1 at the frame's
; start (the timer is set to 0 there, so the channel reads its next event this
; frame). ChannelEffects $C56D returns before the envelope and the effects,
; UpdateTune skips WriteAY $C290, and UpdateTuneEnd $C2DF clears the flag.
; explorers: 1778 of 15 189 updates skip the AY write.
NoteEndFlag:
  DEFB $00

; The AY mixer (register 7) the player writes: $B8 at the start
;
; Bits 0-2 tone off, 3-5 noise off for channels A, B, C, set by SetInstrument
; $C3D8 from the instrument's +2 bit 7; bits 6-7 stay %10 from the image.
; Written to register 7 by WriteAY $C2CB.
MixerImage:
  DEFB $B8

; Not used: $0F and three zeros
;
; No instruction reads or writes it (known only from the code).
PlayerSpare:
  DEFB $0F,$00,$00,$00

; Channel A's record (45 bytes, the fields in the module's header)
;
; IX for channel A in UpdateTune $C1E4; cleared by StartTune $C79F. WriteAY
; $C290 reads the period and the volume, EndTune $C780 zeroes the volume.
ChannelA:
  DEFB $00,$00,$00
ChannelATimer:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$03 the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                 ; note
                                                                   ; timer,
                                                                   ; tested by
                                                                   ; UpdateTune
ChannelAPeriod:
  DEFB $00,$00            ; +$1D/+$1E the tone period: AY registers 0 and 1
ChannelAVolume:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$1F the
                                                               ; volume: AY
                                                               ; register 8

; Channel B's record
;
; As ChannelA, AY registers 2, 3 and 9.
ChannelB:
  DEFB $00,$00,$00
ChannelBTimer:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$03 the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                 ; note timer
ChannelBPeriod:
  DEFB $00,$00            ; +$1D/+$1E the tone period: AY registers 2 and 3
ChannelBVolume:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$1F the
                                                               ; volume: AY
                                                               ; register 9

; Channel C's record
;
; As ChannelA, AY registers 4, 5 and 10 (written only while tune 0 plays,
; TuneNumberOp $C2AE).
ChannelC:
  DEFB $00,$00,$00
ChannelCTimer:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$03 the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                 ; note timer
ChannelCPeriod:
  DEFB $00,$00            ; +$1D/+$1E the tone period: AY registers 4 and 5
ChannelCVolume:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$1F the
                                                               ; volume: AY
                                                               ; register 10

; The pattern each channel is playing (A, B, C)
;
; Set to EmptyPattern $C82D by StartTune $C79F, to a pattern by StartPattern
; $C34A (PatternLo/PatternHi), read by UpdateTune $C1E4 into DE.
PatternPointers:
  DEFW $0000,$0000,$0000

; A scratch byte: an order command's parameter, then a vibrato step's size
;
; ReadOrderList $C32A writes the low 5 bits of an order-list command for
; SetRepeat $C81B and SetSlot $C7F7; VibratoStep $C636 keeps the step's size
; there.
CommandParam:
  DEFB $00

; Not used: two zeros
;
; No instruction reads or writes it (known only from the code).
PlayerSpare2:
  DEFB $00,$00

; The channel being updated: 0 A, 1 B, 2 C
;
; Set by UpdateTune $C1E4, read by StartPattern $C34B (PatternPointers) and
; SetInstrument $C3F6 (the mixer bits).
ChannelIndex:
  DEFB $00
