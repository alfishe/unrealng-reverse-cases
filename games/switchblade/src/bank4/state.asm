; --------------------------------------------------------------------------------------------------------------------
; state.asm: The sequencer's state: the channel records, the instrument slots, the drum
;
; A sequencer record (33 bytes, SeqChannelA $C03F, SeqChannelB $C060, SeqChannelC $C081): +$00 the channel's base in
; SlotTables (0, 16, 32; never written), +$01/+$02 the order-list pointer, +$03/+$04 the current pattern's start,
; +$05/+$06 the pattern pointer, +$07/+$08 the instrument (a pointer into Instruments), +$09 the pattern's repeats
; left, +$0A the transpose (signed semitones), +$0B the pattern-end flag ($FF: read the order list), +$0C the frames
; left of the current event, +$0D the channel's order list is running ($FF) or has ended (0), +$0E the note playing
; (with transpose), +$0F the arpeggio number, +$10/+$11 the arpeggio pointer, +$12 the frames left of the arpeggio
; step, +$13 the steps left, +$14 the arpeggio state ($C0 + n at a note: bit 7 on, bit 6 first frame), +$15 the slide
; switch ($FF on), +$16/+$17/+$18 the slide's delay, steps and interval, +$19 the slide state ($FF to set up, 1
; sliding, 0 off), +$1A the delay left, +$1B the steps left, +$1C/+$1D the step, +$1E/+$1F the whole change of period,
; +$20 the drum switch ($FF: every note starts a noise burst).
;
; The image's bytes in the three records are leftovers of the assembly (StartTune sets every field it needs); the AY
; rips, snapshots taken while playing, differ from the image only in these records, MusicState and the state bytes
; below.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C03F

; The sequencer record of channel A (33 bytes, the fields in the module's
; header)
;
; Written by StartTune $C0D7 and SequenceChannel $C1C5 (IY = $C03F), read by
; UpdateArpeggio $C390 and UpdatePortamento $C420. +$00 = 0: channel A's slots
; are SlotTables +0-15.
SeqChannelA:
  DEFB $00,$19,$18,$19,$1C,$19,$20,$19,$68,$39,$6C
  DEFB $9A,$0C,$14,$06,$22,$38,$64,$36,$72,$02,$6E
  DEFB $B2,$7A,$B2,$7E,$B2,$82,$B2,$89,$35,$62,$40
SeqChannelB:
  DEFB $10,$44,$62,$48,$6D,$29,$4F,$00,$52,$77,$5A ; the sequencer record of
  DEFB $6F,$62,$3A,$41,$3A,$45,$3F,$2D,$3F,$31,$3F ; channel B; +$00 = $10
  DEFB $35,$03,$24,$12,$19,$9B,$19,$7F,$39,$63,$AC
SeqChannelC:
  DEFB $20,$49,$F2,$AF,$25,$61,$3E,$61,$41,$FA,$09 ; the sequencer record of
  DEFB $14,$1B,$07,$39,$64,$32,$72,$01,$86,$35,$87 ; channel C; +$00 = $20
  DEFB $06,$9A,$01,$D6,$35,$D7,$B2,$79,$B2,$7C,$12

; The instrument slots: 16 a channel, each the offset (10 x instrument) of a
; record in Instruments
;
; A pattern's command $80 + n plays instrument slot n of its channel:
; SlotTables + the channel's base + n gives the offset from Instruments $CED4
; (ReadPatternCommand $C31F). StartTune $C0D7 fills every channel's slots with
; 0, 10, ..., 150 (slot n = instrument n); an order list's command $C0 + n, m
; sets slot n to instrument m (10 x m) until the next tune.
SlotTables:
  DEFB $93,$12,$A7,$12,$CF,$01,$BC,$6D,$29,$3D,$20,$74,$2D,$6E,$8D,$B1
  DEFB $7E,$28,$48,$22,$70,$22,$98,$22,$81,$22,$A9,$21,$BD,$25,$D1,$8F ; channel
                                                                       ; B's slots
  DEFB $10,$9B,$DB,$18,$00,$DB,$B2,$20,$AE,$20,$C2,$3A,$26,$3A,$43,$3A ; channel
                                                                       ; C's slots

; The started note's channel has the drum on: StartNote turns its noise on
;
; SequenceChannel $C1C5 copies the channel's +$20 here before StartNote $D0DA;
; StartNote clears it and starts the burst.
DrumPending:
  DEFB $00

; The noise burst's frames (pattern command $FD, first byte)
DrumLength:
  DEFB $00

; Frames left of the noise burst, $FF none
;
; Set from DrumLength by StartNote $D0DA, counted down by AyUpdate $D1C3, which
; turns the noise off when it passes 0 and takes the noise period from
; DrumNoise while it runs. StartTune sets $FF.
DrumTimer:
  DEFB $FF

; The burst's noise period (pattern command $FD, second byte; the AY gets it
; rotated right three times)
DrumNoise:
  DEFB $00

; The burst's channel: its noise-enable mask (AY register 7)
DrumChannel:
  DEFB $00
