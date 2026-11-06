; --------------------------------------------------------------------------------------------------------------------
; engine-play.asm: the frame: the channels' commands, the notes, the envelopes
;
; PlayFrame is one engine step, run from the glue's FramePlay once a TV frame on average (once an interrupt at the
; menus; in play twice a pass, at its start and its end, and a pass takes two TV frames because the next interrupt is
; lost under DI: one step a TV frame on average, the steps a third of a frame uneven; docs/09-sound.md 9.8). Each
; active channel counts down its note's frames; at 0 ReadCommands reads its commands up to the next note (PlayNote:
; the period from the data image's PeriodTable, the envelopes restarted, the mixer). Every frame each active channel
; then steps its volume and pitch envelopes, and the one noise envelope steps after channel A.
;
; An envelope is a list of three-byte steps (frames, change + $80, repeats) ended by $FF, which starts it again:
; VolumeEnvelope adds the change to the channel's volume register, PitchEnvelope 2 x the change to its period
; (PitchStep), NoiseEnvelope the change to R6. The formats of the commands and envelopes: src/res/sound/README.md and
; tools/sound_data.py.
; --------------------------------------------------------------------------------------------------------------------

; one frame of the engine: send the registers, then advance the three channels
;
; SendRegisters first (the values the last frame worked out), then PlayChannel
; for channel A (IY = AYToneA), the noise envelope (NoiseEnvelope), channel B
; (AYToneB), channel C (AYToneC). The registers so reach the AY one frame after
; they are made. 10393 runs, one a frame.
PlayFrame:
  CALL SendRegisters
  LD IX,ChannelA
  LD IY,AYRegisters
  CALL PlayChannel
  CALL NoiseEnvelope
  LD IX,ChannelB
  LD IY,AYToneB
  CALL PlayChannel
  LD IX,ChannelC
  LD IY,AYToneC
  CALL PlayChannel
  RET

; one frame of a channel: the next command when its wait ends, then its
; envelopes
;
; Input: IX = the channel's record, IY = its tone register pair in the image.
; Inactive (+$1E = 0): nothing. Else the wait (+$1F) - 1; at 0 ReadCommands;
; then, if still active, VolumeEnvelope and PitchEnvelope. 31179 runs.
PlayChannel:
  LD A,(IX+$1E)
  OR A
  RET Z
  DEC (IX+$1F)            ; the note's frames
  CALL Z,ReadCommands     ; at 0: the next commands, to the next note
  LD A,(IX+$1E)
  OR A
  RET Z
  CALL VolumeEnvelope     ; the volume envelope
  CALL PitchEnvelope      ; the pitch envelope
  RET
; This entry point is used by the routine at ReadCommands.
NextCommand:
  INC HL                  ; a 2-byte command done: past its operand
; This entry point is used by the routine at ReadCommands.
SetPointer:
  LD (IX+$22),H           ; the channel's current pointer = HL, then on reading
  LD (IX+$21),L

; read the channel's commands up to its next note
;
; Input: IX = the record, IY = its tone registers. Reads (+$21) on: A = the
; command, E = the next byte. 0 (a rest), 1-$64 (a note, + the transposition)
; and $65-$DB (a one-byte note A & $7F of 8 frames: ShortNote) end the read at
; PlayNote; the commands $E1 (CmdEnd), $E4 (CmdNoise), $E5 (CmdCall), $E6
; (CmdTranspose), $E8 (CmdVolEnv), $E9 (CmdPitchEnv), $EA (CmdNoiseEnv), $EB
; (CmdMixer), $EC (CmdSwap), $FF (CmdReturn) go on to the next command; any
; other byte is a one-byte note too. The formats: src/res/sound/README.md. 1352
; runs.
ReadCommands:
  LD H,(IX+$22)
  LD L,(IX+$21)
ReadCommand:
  LD A,(HL)               ; A = the command, E = its operand
  INC HL
  LD E,(HL)
  CP $00                  ; 0: a rest (period 0), E frames
  JP Z,PlayNote
  CP $65                  ; 1-$64: a note, E frames
  JP C,Note
  CP $DC                  ; $65-$DB: a one-byte note
  JP C,ShortNote
  CP $E4
  JR Z,CmdNoise
  CP $E1
  JR Z,CmdEnd
  CP $E9
  JR Z,CmdPitchEnv
  CP $E8
  JR Z,CmdVolEnv
  CP $EA
  JP Z,CmdNoiseEnv
  CP $E5
  JP Z,CmdCall
  CP $E6
  JR Z,CmdTranspose
  CP $EB
  JR Z,CmdMixer
  CP $EC
  JP Z,CmdSwap
  CP $FF
  JP Z,CmdReturn
  JP ShortNote
CmdEnd:
  LD (IX+$1E),$00         ; $E1: the channel stops, its volume 0
  LD H,(IX+$2C)
  LD L,(IX+$2B)
  LD (HL),$00
  RET
CmdNoise:
  LD A,E                  ; $E4 N: the noise period, noise on for the next note
  LD (AYNoise),A
  LD (IX+$28),$01         ; PlayNote turns the noise on for this channel
  INC HL
  JP ReadCommand          ; a 2-byte command that does not end the read
CmdTranspose:
  LD (IX+$27),E           ; $E6 N: added to the next notes
  JR NextCommand
CmdMixer:
  LD A,E                  ; $EB M: ORed into the mixer at each note
  LD (MixerExtra),A
  JR NextCommand
CmdSwap:
  LD BC,(SoundTable)           ; $EC: swap SoundTable's entries 0 and 1 (a 1-byte
                          ; command; not run in c1, the simulation runs it at
                          ; the music's frame 6528)
  PUSH BC
  LD BC,(SoundTable+2)
  LD (SoundTable),BC
  POP BC
  LD (SoundTable+2),BC
  JP SetPointer
CmdVolEnv:
  PUSH IX                 ; $E8 E: the volume envelope of the next notes
SetEnvelope:
  LD A,E                  ; IX+$18 (or +$1A, +$1C) = EnvelopeTable + 2 x E
  ADD A,A
  ADD A,EnvelopeTable & $FF
  LD E,A
  ADC A,EnvelopeTable >> 8
  SUB E
  LD D,A
  LD A,(DE)
  LD (IX+$18),A
  INC DE
  LD A,(DE)
  LD (IX+$19),A
  POP IX
  JP NextCommand
CmdPitchEnv:
  PUSH IX                 ; $E9 E: the pitch envelope (IX+$1A)
  INC IX
  INC IX
  JR SetEnvelope
CmdNoiseEnv:
  PUSH IX                 ; $EA E: the noise envelope (one for all channels:
                          ; ChannelA's +$1C)
  LD IX,NoiseEnvCounter
  JP SetEnvelope
CmdCall:
  INC HL                  ; $E5 S: play sound S, come back here at its
                          ; CmdReturn
  LD (IX+$24),H           ; the return pointer: past this command
  LD (IX+$23),L
  LD A,E                  ; SoundTable + 2 x S
  ADD A,A
  ADD A,SoundTable & $FF
  LD L,A
  ADC A,SoundTable >> 8
  SUB L
  LD H,A
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP SetPointer
CmdReturn:
  LD H,(IX+$24)           ; $FF: back to the return pointer; at a second $FF
                          ; the sound's start
  LD L,(IX+$23)
  LD A,(HL)
  CP $FF
  JP NZ,SetPointer
  LD H,(IX+$26)           ; a $FF there too: the top level, start the sound
                          ; again
  LD L,(IX+$25)
  JP SetPointer
ShortNote:
  AND $7F                 ; a one-byte note: A & $7F for 8 frames
  DEC HL
  LD E,$08
Note:
  ADD A,(IX+$27)          ; the note + the channel's transposition
PlayNote:
  LD (IX+$1F),E           ; the period, the envelopes restarted, the mixer
  ADD A,A                 ; PeriodTable + 2 x the note: into the channel's tone
                          ; registers
  ADD A,PeriodTable & $FF
  LD E,A
  ADC A,PeriodTable >> 8
  SUB E
  LD D,A
  LD A,(DE)
  LD (IY+$00),A
  INC DE
  LD A,(DE)
  LD (IY+$01),A
  PUSH HL
  PUSH IX                 ; DE = the record
  POP DE
  LD HL,$0012             ; the templates (+$12-$1B) to the running envelopes:
                          ; counters (+0-5) 0, pointers (+6-9)
  ADD HL,DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  INC DE                  ; and the envelopes' loop points (+$C-$F)
  INC DE
  LDI
  LDI
  LDI
  LDI
  LD A,$00                ; the noise envelope restarts with every note of any
                          ; channel
  LD (NoiseEnvCounter),A
  LD (NoiseEnvCounter+$0001),A
  LD A,(NoiseEnvChosen)
  LD (NoiseEnvPointer),A
  LD (NoiseEnvLoop),A
  LD A,(NoiseEnvChosen+$0001)
  LD (NoiseEnvPointer+$0001),A
  LD (NoiseEnvLoop+$0001),A
  LD H,(IX+$2C)           ; the volume 0: the volume envelope's first step sets
                          ; it
  LD L,(IX+$2B)
  LD (HL),$00
  LD A,(AYMixer)          ; the mixer: this channel's tone and noise on
  AND (IX+$2A)
  DEC (IX+$28)            ; no CmdNoise before the note: noise off again
  JR Z,MixerNoiseDone
  OR (IX+$29)
MixerNoiseDone:
  LD HL,MixerExtra        ; MixerExtra ORed in
  OR (HL)
  AND $3F
  LD (AYMixer),A
  LD (IX+$28),$00
  POP HL                  ; the command's pointer: past the note
  INC HL
  LD (IX+$22),H
  LD (IX+$21),L
  RET

; one frame of the channel's volume envelope
;
; Input: IX = the record. The step's frame counter (+0) + 1; when it equals the
; step's first byte (frames) it is zeroed and the step's second byte - $80 is
; added to the channel's volume register (no clamp); then EnvelopeRepeat. A
; step is three bytes: frames, the change + $80, repeats; $FF after the last
; step starts the envelope again. 11801 runs.
VolumeEnvelope:
  PUSH IX
  POP HL
  LD D,(IX+$07)
  LD E,(IX+$06)
  INC (HL)
  LD A,(DE)
  SUB (HL)
  RET NZ
  LD (HL),A
  PUSH HL
  LD H,(IX+$2C)
  LD L,(IX+$2B)
  INC DE
  LD A,(DE)
  ADD A,(HL)
  SUB $80
  LD (HL),A
  POP HL
  JR EnvelopeRepeat       ; the repeats

; one frame of the channel's pitch envelope
;
; As VolumeEnvelope on IX+2 (the counters +2, +3, the pointer +8, the loop
; +$E): the period (IY) moves by 2 x (the step's change - $80) (PitchStep).
; 11801 runs.
PitchEnvelope:
  INC IX
  INC IX
  PUSH IX
  POP HL
  LD D,(IX+$07)
  LD E,(IX+$06)
  INC (HL)
  LD A,(DE)
  SUB (HL)
  RET NZ
  LD (HL),A
  PUSH HL
  LD H,(IY+$01)
  LD L,(IY+$00)
  INC DE
  LD B,A
  LD A,(DE)
  LD C,A
  CALL PitchStep
  SBC HL,BC
  LD (IY+$01),H
  LD (IY+$00),L
  POP HL
  JR EnvelopeRepeat

; one frame of the noise envelope
;
; The one noise envelope, kept in ChannelA's record at +4 (IX =
; NoiseEnvCounter: the counters +4, +5 of ChannelA, the pointer +$A, the loop
; +$10): AYNoise = (AYNoise + the change - $80) & $0F. 10393 runs, after
; channel A each frame.
NoiseEnvelope:
  LD IX,NoiseEnvCounter
  PUSH IX
  POP HL
  LD D,(IX+$07)
  LD E,(IX+$06)
  INC (HL)
  LD A,(DE)
  SUB (HL)
  RET NZ
  LD (HL),A
  LD A,(AYNoise)
  LD C,A
  INC DE
  LD A,(DE)
  ADD A,C
  SUB $80
  AND $0F
  LD (AYNoise),A
; This entry point is used by the routines at VolumeEnvelope and PitchEnvelope.
EnvelopeRepeat:
  INC DE                  ; the step's repeat counter + 1; at its count the
                          ; next step, or the start after $FF
  INC HL
  INC (HL)
  LD A,(DE)
  SUB (HL)
  RET NZ
  LD (HL),A
  INC DE
  LD A,(DE)
  INC A
  JP NZ,SetStepPointer
  LD D,(IX+$0D)           ; $FF: the envelope again from its loop point
  LD E,(IX+$0C)
SetStepPointer:
  LD (IX+$07),D           ; the step pointer for the next frame
  LD (IX+$06),E
  RET
