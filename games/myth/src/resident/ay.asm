; --------------------------------------------------------------------------------------------------------------------
; ay.asm: The AY driver: the effects and the three channels
;
; A stage plays an effect with CALL PlaySoundVector, E the effect number. StartEffect puts the effect into its channel
; (1-3); Im2Handler runs AyFrame every frame, which steps each busy channel: a segment's period and volume change each
; frame for its duration, then the next segment, and the channel goes quiet after the last. Every AY write is an OUT
; to $FFFD (the register) and $BFFD (the value): on a 48K these do nothing.
; --------------------------------------------------------------------------------------------------------------------

  ORG $F54D

; The 13 effects: channel, noise flag (0 a tone), segments, volume x 16,
; period, then the segments
;
; With the noise flag set the channel's tone is off, its noise on, and AyFrame
; writes the period's low byte to the noise period (register 6). A segment:
; duration in frames, period change a frame (signed), volume change a frame
; (signed, x 16). Read by StartEffect and ChannelStep (every stage recording).
EffectData:
  INCBIN "res/resident/effects.bin",$0000,9
Effect1:
  INCBIN "res/resident/effects.bin",$0009,9
Effect2:
  INCBIN "res/resident/effects.bin",$0012,9
Effect3:
  INCBIN "res/resident/effects.bin",$001B,9
Effect4:
  INCBIN "res/resident/effects.bin",$0024,9
Effect5:
  INCBIN "res/resident/effects.bin",$002D,21
Effect6:
  INCBIN "res/resident/effects.bin",$0042,12
Effect7:
  INCBIN "res/resident/effects.bin",$004E,9
Effect8:
  INCBIN "res/resident/effects.bin",$0057,9
Effect9:
  INCBIN "res/resident/effects.bin",$0060,12
Effect10:
  INCBIN "res/resident/effects.bin",$006C,12
Effect11:
  INCBIN "res/resident/effects.bin",$0078,9
Effect12:
  INCBIN "res/resident/effects.bin",$0081,9

; Two bytes after the last effect that no code reads: $06 $04, like the start
; of a second segment
;
; Effect 12 has one segment, so ChannelStep stops before them (known only from
; the code: the count at $F5D0 is 1). A leftover of the effect's editing.
EffectLeftover:
  DEFB $06,$04

  ORG $F66F

; Mixer := $38 (tones off), every channel idle, the three volumes 0
;
; Witness: L1 25 (c1, ending, joystick, s1-idle, s1-right, s2-right, s3-right,
; s4-right, s5-right, stageload, rzx-r1-rzx-r5).
SilenceAy:
  LD A,$38
  LD (Mixer),A
  CALL WriteMixer
  LD HL,Channels
  LD DE,Channels+$0001
  LD BC,$0017
  LD (HL),$FF
  LDIR
  JP SilenceVolumes
SilenceVolumes:
  PUSH IY
  LD E,$00
  LD D,$08
  CALL AyWrite
  INC D
  CALL AyWrite
  INC D
  CALL AyWrite
  POP IY
  RET

; Start effect E (through PlaySoundVector), every register kept
;
; Witness: L1 3077 (c1, c1o, deaths, ending, s1-right, s2-right, s3-right,
; s4-right, s5-right, stageload, rzx-r1-rzx-r5).
PlaySound:
  PUSH IY
  PUSH IX
  PUSH BC
  PUSH HL
  PUSH DE
  PUSH AF
  SLA E
  LD HL,EffectTable
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  PUSH BC
  POP IY
  CALL StartEffect
  POP AF
  POP DE
  POP HL
  POP BC
  POP IX
  POP IY
  RET

; The addresses of the 13 effects
;
; Read by PlaySound (every stage recording).
EffectTable:
  DEFW EffectData
  DEFW Effect1
  DEFW Effect2
  DEFW Effect3
  DEFW Effect4
  DEFW Effect5
  DEFW Effect6
  DEFW Effect7
  DEFW Effect8
  DEFW Effect9
  DEFW Effect10
  DEFW Effect11
  DEFW Effect12

; Put the effect at IY into its channel; set its tone or noise bits in the
; mixer
;
; Witness: L1 3077 (c1, c1o, deaths, ending, s1-right, s2-right, s3-right,
; s4-right, s5-right, stageload, rzx-r1-rzx-r5).
StartEffect:
  LD C,(IY+$00)
  DEC C
  SLA C
  SLA C
  SLA C
  LD B,$00
  LD IX,Channels
  ADD IX,BC
  LD A,(IY+$02)
  LD (IX+$00),A
  LD A,(IY+$06)
  LD (IX+$01),A
  PUSH IY
  POP HL
  LD BC,$0006
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  LD A,(IY+$04)
  LD (IX+$04),A
  LD A,(IY+$05)
  LD (IX+$05),A
  LD A,(IY+$03)
  LD (IX+$07),A
  LD A,(IY+$01)
  CP $00
  JR NZ,StartEffectNoise
  LD B,(IY+$00)
  LD C,$04
StartEffectShift:
  SLA C
  DJNZ StartEffectShift
  LD A,(IY+$01)
  CP $00
  JR NZ,StartEffectNoise
  LD A,(Mixer)
  LD B,A
  LD A,(IY+$00)
  CP $01
  JR NZ,StartEffectTone2
  SET 3,B
  RES 0,B
  JR StartEffectMixer
StartEffectTone2:
  CP $02
  JR NZ,StartEffectTone3
  SET 4,B
  RES 1,B
  JR StartEffectMixer
StartEffectTone3:
  SET 5,B
  RES 2,B
StartEffectMixer:
  LD A,B
  LD (Mixer),A
  CALL WriteMixer
  LD (IX+$06),$00
  RET
StartEffectNoise:
  LD A,(Mixer)
  LD B,A
  LD A,(IY+$00)
  CP $01
  JR NZ,StartEffectNoise2
  RES 3,B
  SET 0,B
  JR StartEffectNoiseMixer
StartEffectNoise2:
  CP $02
  JR NZ,StartEffectNoise3
  RES 4,B
  SET 1,B
  JR StartEffectNoiseMixer
StartEffectNoise3:
  RES 5,B
  SET 2,B
StartEffectNoiseMixer:
  LD A,B
  LD (Mixer),A
  CALL WriteMixer
  LD A,(IY+$01)
  LD (IX+$06),A
  RET

; AY register 7 := Mixer
;
; Witness: L1 3100 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
WriteMixer:
  LD A,(Mixer)
  LD D,$07
  LD E,A
  JP AyWrite

; Every frame: step the three channels, write their periods (a noise channel:
; the period's low byte to register 6)
;
; Witness: L1 125689 (c1, c1o, deaths, ending, joystick, menu, s1-idle,
; s1-right, s2-right, s3-right, s4-right, s5-right, stageload, rzx-r0-rzx-r5).
AyFrame:
  PUSH IY
  PUSH IX
  LD B,$03
  LD IX,Channels
  LD D,$00
  LD A,$01
  LD (ChannelNumber),A
AyFrameChannel:
  PUSH BC
  PUSH DE
  CALL ChannelStep
  POP DE
  PUSH DE
  LD A,(IX+$00)
  CP $FF
  JR Z,AyFrameNext
  LD A,(IX+$06)
  CP $00
  JR NZ,AyFrameNoise
  LD E,(IX+$04)
  CALL AyWrite
  INC D
  LD E,(IX+$05)
  CALL AyWrite
  JR AyFrameNext
AyFrameNoise:
  LD E,(IX+$04)
  LD D,$06
  CALL AyWrite
AyFrameNext:
  LD BC,$0008
  ADD IX,BC
  POP DE
  POP BC
  INC D
  INC D
  LD A,(ChannelNumber)
  INC A
  LD (ChannelNumber),A
  DJNZ AyFrameChannel
  POP IX
  POP IY
  RET

; One frame of the channel at IX: write its volume, move its period and volume,
; the next segment
;
; Witness: L1 379456 (c1, c1o, deaths, ending, joystick, menu, s1-idle,
; s1-right, s2-right, s3-right, s4-right, s5-right, stageload, rzx-r0-rzx-r5).
ChannelStep:
  LD A,(IX+$00)
  CP $FF
  RET Z
  CALL WriteVolume
  CALL AyWrite
  LD L,(IX+$02)
  LD H,(IX+$03)
  PUSH HL
  POP IY
  DEC (IX+$01)
  JR Z,ChannelNextSegment
  LD E,(IY+$01)
  LD C,E
  RL E
  SBC A,A
  LD B,A
  LD L,(IX+$04)
  LD H,(IX+$05)
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(IX+$07)
  ADD A,(IY+$02)
  LD (IX+$07),A
  RET
ChannelNextSegment:
  DEC (IX+$00)
  JR Z,ChannelDone
  INC IY
  INC IY
  INC IY
  PUSH IY
  POP HL
  LD (IX+$02),L
  LD (IX+$03),H
  LD A,(IY+$00)
  LD (IX+$01),A
  JR ChannelStep
ChannelDone:
  LD A,(ChannelNumber)    ; the last segment: volume 0, the channel idle
  ADD A,$07
  LD D,A
  LD E,$00
  CALL AyWrite
  LD (IX+$00),$FF
  RET

; AY volume of the current channel := its volume / 16
;
; Witness: L1 24735 (c1, c1o, deaths, ending, s1-right, s2-right, s3-right,
; s4-right, s5-right, stageload, rzx-r1-rzx-r5).
WriteVolume:
  LD A,(ChannelNumber)
  ADD A,$07
  LD D,A
  LD E,(IX+$07)
  SRL E
  SRL E
  SRL E
  SRL E

; AY register D := E
;
; Witness: L1 79117 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
AyWrite:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; The three channels, 8 bytes each
;
; +0 segments left ($FF idle), +1 frames left in the segment, +2 the segment's
; address, +4 the period, +6 the noise flag (0 a tone), +7 the volume x 16.
; Read and written by StartEffect, AyFrame and ChannelStep.
Channels:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
Channel2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
Channel3:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The AY mixer value (register 7)
Mixer:
  DEFB $00

; A byte no code reads (known only from the code: no operand names it)
MixerSpare:
  DEFB $00

; The channel AyFrame is on, 1-3
ChannelNumber:
  DEFB $00

; LoadStage's H, L and B: TurboLoad's length is 2 x (9B + H + L) pages
LoadLength:
  DEFB $00
LoadLengthL:
  DEFB $00                ; L
LoadLengthB:
  DEFB $00                ; B

; Zeros no code reads (known only from the code)
LoadLengthPad:
  DEFB $00,$00,$00,$00

  ORG $F9B0

; JP PlaySound: the stages' way in
;
; Witness: L1 3076 (c1, c1o, deaths, ending, s1-right, s2-right, s3-right,
; s4-right, s5-right, stageload, rzx-r1-rzx-r5).
PlaySoundVector:
  JP PlaySound
