; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The sound: the AY effects
;
; All the game's sound but the explosion's crackle (DrawShard $BF66, the beeper bit) is the AY: SoundWrite puts
; register D = E through $FFFD / $BFFD. No routine tests for an AY: on a 48K Spectrum without one the writes go to no
; device and the game plays silent but for the crackle (see work/stage2/NOTES.md, 48K / 128K).
;
; An effect is a descriptor (SfxGun $D763 ...): [channel 1-3][noise flag: 0 a tone, else noise][steps][volume x
; 16][period word], then the steps, 3 bytes each: [count][period change, signed][volume change]. StartSfx copies it
; into its channel's 8 bytes at Channels $D832 ($FF free) and sets the mixer ($D855); SoundStep, called twice a pass,
; moves each channel one step (ChannelStep) and writes its tone and volume.
; --------------------------------------------------------------------------------------------------------------------

; The channels free, the mixer $38 (tones on, noise off), silence
;
; Witness: L1 84 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-rooms238,
; p1-speedup, p1-room x5, rzx-p1- x30).
SoundReset:
  LD A,$38
  LD (Mixer),A
  CALL WriteMixer
  LD HL,Channels
  LD DE,Channels+$0001
  LD BC,$001D
  LD (HL),$00
  LDIR
  LD IX,Channels
  LD (IX+$00),$FF
  LD (IX+$08),$FF
  LD (IX+$10),$FF
  CALL SoundSilence
  RET

; The three volumes (registers 8-10) to 0
;
; Witness: L1 52036 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x30).
SoundSilence:
  LD E,$00
  LD D,$08
  CALL SoundWrite
  INC D
  CALL SoundWrite
  INC D
  CALL SoundWrite
  RET

; Start the effect at DE (saves IX, IY, BC)
;
; Witness: L1 15747 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
StartSfx:
  PUSH IY
  PUSH IX
  PUSH BC
  PUSH DE
  POP IY
  CALL StartSfxIY
  POP BC
  POP IX
  POP IY
  RET

; The descriptor at IY into its channel; the mixer bits for tone and noise
;
; Witness: L1 15747 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
StartSfxIY:
  LD A,(IY+$00)
  DEC A
  SLA A
  SLA A
  SLA A
  LD C,A
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
  JP NZ,SfxMixerBits
  LD B,(IY+$00)
  LD C,$04
SfxMixer:
  SLA C
  DJNZ SfxMixer
  LD A,(Mixer)
  OR C
  LD (Mixer),A
  JP WriteMixer
SfxMixerBits:
  LD A,(Mixer)
  LD B,A
  LD A,(IY+$00)
  CP $01
  JP NZ,SfxChannel3
  RES 3,B
  SET 0,B
  JP SfxMixerSet
SfxChannel3:
  CP $02
  JP NZ,SfxNoise
  RES 4,B
  SET 1,B
  JP SfxMixerSet
SfxNoise:
  RES 5,B
  SET 2,B
SfxMixerSet:
  LD A,B
  LD (Mixer),A
  CALL WriteMixer
  LD A,(IY+$01)
  LD (IX+$06),A
  RET

; Register 7 = the mixer $D855
;
; Witness: L1 15831 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x33).
WriteMixer:
  LD A,(Mixer)
  LD D,$07
  LD E,A
  CALL SoundWrite
  RET

; Each of the 3 channels: ChannelStep, then its tone (registers 0-5) or noise
; period (6)
;
; Witness: L1 37230 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
SoundStep:
  LD B,$03
  LD IX,Channels
  LD D,$00
  LD A,$01
  LD (ChannelNumber),A
SoundChannelLoop:
  PUSH BC
  PUSH DE
  CALL ChannelStep
  POP DE
  PUSH DE
  LD A,(IX+$00)
  CP $FF
  JP Z,SoundNextChannel
  LD A,(IX+$06)
  CP $00
  JP NZ,SoundNoise
  LD E,(IX+$04)
  CALL SoundWrite
  INC D
  LD E,(IX+$05)
  CALL SoundWrite
  JP SoundNextChannel
SoundNoise:
  LD E,(IX+$04)
  LD D,$06
  CALL SoundWrite
SoundNextChannel:
  LD BC,$0008
  ADD IX,BC
  POP DE
  POP BC
  INC D
  INC D
  LD A,(ChannelNumber)
  INC A
  LD (ChannelNumber),A
  DJNZ SoundChannelLoop
  RET

; One step of the channel at IX: the volume written, the tone and volume
; changed, the next step; at the end the channel silent and free
;
; Witness: L1 113930 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
ChannelStep:
  LD A,(IX+$00)
  CP $FF
  RET Z
  CALL WriteVolume
  CALL SoundWrite
  LD L,(IX+$02)
  LD H,(IX+$03)
  PUSH HL
  POP IY
  DEC (IX+$01)
  JP Z,ChannelNextStep
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
ChannelNextStep:
  DEC (IX+$00)
  JP Z,ChannelEnd
  INC IY
  INC IY
  INC IY
  PUSH IY
  POP HL
  LD (IX+$02),L
  LD (IX+$03),H
  LD A,(IY+$00)
  LD (IX+$01),A
  JP ChannelStep
ChannelEnd:
  LD A,(ChannelNumber)
  ADD A,$07
  LD D,A
  LD E,$00
  CALL SoundWrite
  LD A,$FF
  LD (IX+$00),A
  RET

; Register 8 + channel = the channel's volume / 16
;
; Witness: L1 48180 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
WriteVolume:
  LD A,(ChannelNumber)
  ADD A,$07
  LD D,A
  LD E,(IX+$07)
  SRL E
  SRL E
  SRL E
  SRL E
  CALL SoundWrite
  RET

; AY register D = E: OUT ($FFFD),D, OUT ($BFFD),E
;
; Witness: L1 328483 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x33).
SoundWrite:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; The effect descriptors. The gun's shot
SfxGun:
  INCBIN "res/sound/rex1-effects.bin",$0000,9
SfxEnemyShot:
  ; $D76C an enemy's shot
  INCBIN "res/sound/rex1-effects.bin",$0009,9
SfxLaser:
  ; $D775 the laser
  INCBIN "res/sound/rex1-effects.bin",$0012,9
SfxSpray:
  ; $D77E the spray
  INCBIN "res/sound/rex1-effects.bin",$001B,9
SfxHitWall:
  ; $D787 a bullet meeting a wall
  INCBIN "res/sound/rex1-effects.bin",$0024,9
SfxExplosion:
  ; $D790 an object killed (noise)
  INCBIN "res/sound/rex1-effects.bin",$002D,12
SfxShield:
  ; $D79C the shield's hum while it is on (DrawRex)
  INCBIN "res/sound/rex1-effects.bin",$0039,4
SfxShieldTone:
  ; $D7A0 its period word: $04B0 + a random 0-31, written by DrawRex each
  ;   time it starts; the block's last nine bytes, $D7A5-$D7AD, are a full
  ;   descriptor (DEMO's shield-hit sound, SfxShieldHit) that nothing
  ;   refers to
  INCBIN "res/sound/rex1-effects.bin",$003D,14
SfxMaterialise:
  ; $D7AE Rex appears
  INCBIN "res/sound/rex1-effects.bin",$004B,12
SfxDematerialise:
  ; $D7BA Rex vanishes
  INCBIN "res/sound/rex1-effects.bin",$0057,12
SfxBigPod:
  ; $D7C6 a big power pod
  INCBIN "res/sound/rex1-effects.bin",$0063,21
SfxPowerPod:
  ; $D7DB a power pod
  INCBIN "res/sound/rex1-effects.bin",$0078,21
SfxBombPod:
  ; $D7F0 a bomb pod
  INCBIN "res/sound/rex1-effects.bin",$008D,21
SfxRestart:
  ; $D805 a restart point saved (three notes)
  INCBIN "res/sound/rex1-effects.bin",$00A2,33
SfxRecharge:
  ; $D826 the shield recharging
  INCBIN "res/sound/rex1-effects.bin",$00C3,12

; the three channels' state, 8 bytes each: [steps left or $FF free][count][step
; pointer][tone word][noise][volume]
Channels:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00
Mixer:
  DEFB $00,$00            ; the mixer value (register 7)
ChannelNumber:
  DEFB $00                ; the channel SoundStep is on
