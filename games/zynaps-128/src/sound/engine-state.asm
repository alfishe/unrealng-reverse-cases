; --------------------------------------------------------------------------------------------------------------------
; engine-state.asm: the AY register image and the three channel records
;
; The engine's variables, inside its loaded image: the AY register image AYRegisters (R0-R13, sent by SendRegisters
; every frame), MixerExtra, LastChannel and one 45-byte record a channel. The loaded values are zeros except each
; record's noise-off bit, mixer mask and volume register address (+$29-$2C): the image holds the state of a fresh
; engine (page 4 as the intro fills it, docs/03-build-and-load.md; work/images/game-entry-bank4.bin has these bytes at
; the game's entry).
; --------------------------------------------------------------------------------------------------------------------

; the AY register image R0-R13, sent by SendRegisters each frame
;
; Written by PlayNote (the tone), the envelopes (the volumes, the periods, the
; noise), CmdNoise, StopMusic, SilenceAndSend; read by SendRegisters. Loaded as
; zeros.
AYRegisters:
  DEFB $00,$00
AYToneB:
  DEFB $00,$00            ; R2-R3
AYToneC:
  DEFB $00,$00            ; R4-R5
AYNoise:
  DEFB $00                ; R6
AYMixer:
  DEFB $00                ; R7
AYVolumeA:
  DEFB $00                ; R8
AYVolumeB:
  DEFB $00                ; R9
AYVolumeC:
  DEFB $00                ; R10
AYEnvPeriod:
  DEFB $00,$00            ; R11-R12, never written
AYEnvShape:
  DEFB $00                ; R13, never written: 0

; mixer bits ORed in at each note (CmdMixer; 0 at each StartSound)
MixerExtra:
  DEFB $00

; a byte no instruction reads
Unused1:
  DEFB $00

; the channel StartSound took last (1-3; 0 as loaded)
;
; StartSound XORs it with 1 for the next effect's channel; StartMusic sets 3.
LastChannel:
  DEFB $00

; channel A's record: 45 bytes, the layout in src/res/sound/README.md
;
; +0-5 the envelopes' frame and repeat counters (volume, pitch, noise), +6-$B
; their step pointers, +$C-$11 their loop points, +$12-$17 the counters'
; templates (zeros), +$18-$1D the envelopes chosen by CmdVolEnv / CmdPitchEnv /
; CmdNoiseEnv, +$1E active, +$1F the frames left of the note, +$20 not used,
; +$21 the command pointer, +$23 the return pointer, +$25 the sound's start,
; +$27 the transposition, +$28 the noise request (CmdNoise), +$29 the channel's
; noise-off bit, +$2A the mixer mask clearing its tone and noise bits, +$2B the
; address of its volume register. Only the last four are set as loaded ($08,
; $36, AYVolumeA). The noise envelope lives at +4, +$A, +$10, +$1C of this
; record (NoiseEnvCounter).
ChannelA:
  DEFB $00,$00,$00,$00
NoiseEnvCounter:
  DEFB $00,$00,$00,$00,$00,$00 ; +4: the noise envelope's counters, IX for
                               ; NoiseEnvelope and CmdNoiseEnv
NoiseEnvPointer:
  DEFB $00,$00,$00,$00,$00,$00 ; +$A: the noise envelope's step pointer
NoiseEnvLoop:
  DEFB $00,$00            ; +$10: its loop point
  DEFB $00,$00,$00,$00,$00,$00 ; +$12: the templates
  DEFB $00,$00,$00,$00    ; +$18: the envelopes chosen
NoiseEnvChosen:
  DEFB $00,$00            ; +$1C: the noise envelope chosen
ChannelAActive:
  DEFB $00                ; +$1E: active
  DEFB $00,$00            ; +$1F: the note's frames left
  DEFB $00,$00,$00,$00,$00,$00 ; +$21: the command, return and start pointers
  DEFB $00,$00            ; +$27: the transposition, +$28 the noise request
  DEFB $08,$36,$93,$CC    ; +$29: noise-off bit $08, mask $36, volume register
                          ; AYVolumeA

; channel B's record, as ChannelA (noise-off bit $10, mask $2D, AYVolumeB)
ChannelB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
ChannelBActive:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$1E
  DEFB $10,$2D,$94,$CC    ; +$29

; channel C's record, as ChannelA (noise-off bit $20, mask $1B, AYVolumeC)
ChannelC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
ChannelCActive:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +$1E
  DEFB $20,$1B,$95,$CC    ; +$29
