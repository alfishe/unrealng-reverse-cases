; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The sound: the AY effects
; --------------------------------------------------------------------------------------------------------------------

; The channels free, the mixer $38 (tones on, noise off), silence
;
; As REX 1's SoundReset $D5AE (src/game/sound.asm).
;
; Witness: L1 47 (d1, demo-cycle).
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
; As REX 1's SoundSilence $D5D7 (src/game/sound.asm).
;
; Witness: L1 89 (d1, demo-cycle).
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
; As REX 1's StartSfx $D5E7 (src/game/sound.asm).
;
; Witness: L1 3103 (d1, demo-cycle).
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
; As REX 1's StartSfxIY $D5F8 (src/game/sound.asm).
;
; Witness: L1 3103 (d1, demo-cycle).
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
; As REX 1's WriteMixer $D682 (src/game/sound.asm).
;
; Witness: L1 3150 (d1, demo-cycle).
WriteMixer:
  LD A,(Mixer)
  LD D,$07
  LD E,A
  CALL SoundWrite
  RET

; Each of the 3 channels: ChannelStep, then its tone (registers 0-5) or noise
; period (6)
;
; As REX 1's SoundStep $D68C (src/game/sound.asm).
;
; Witness: L1 13504 (d1, demo-cycle).
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
; As REX 1's ChannelStep $D6DB (src/game/sound.asm).
;
; Witness: L1 41533 (d1, demo-cycle).
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
; As REX 1's WriteVolume $D744 (src/game/sound.asm).
;
; Witness: L1 12728 (d1, demo-cycle).
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
; As REX 1's SoundWrite $D759 (src/game/sound.asm).
;
; Witness: L1 43117 (d1, demo-cycle).
SoundWrite:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; The effect descriptors. The gun's shot
;
; As REX 1's SfxGun $D763 (src/game/sound.asm).
SfxGun:
  INCBIN "res/sound/demo-effects.bin",$0000,9
SfxEnemyShot:
  ; $D970 an enemy's shot
  INCBIN "res/sound/demo-effects.bin",$0009,9
SfxLaser:
  ; $D979 the laser
  INCBIN "res/sound/demo-effects.bin",$0012,9
SfxSpray:
  ; $D982 the spray
  INCBIN "res/sound/demo-effects.bin",$001B,9
SfxHitWall:
  ; $D98B a bullet meeting a wall
  INCBIN "res/sound/demo-effects.bin",$0024,9
SfxExplosion:
  ; $D994 an object killed (noise)
  INCBIN "res/sound/demo-effects.bin",$002D,12
SfxShield:
  ; $D9A0 the shield's hum while it is on (DrawRex)
  INCBIN "res/sound/demo-effects.bin",$0039,4
SfxShieldTone:
  ; $D9A4 its period word: $04B0 + a random 0-31, written by DrawRex
  INCBIN "res/sound/demo-effects.bin",$003D,5
SfxShieldHit:
  ; $D9A9 an enemy bullet on the shield (ShieldHitSound)
  INCBIN "res/sound/demo-effects.bin",$0042,9
SfxMaterialise:
  ; $D9B2 Rex appears
  INCBIN "res/sound/demo-effects.bin",$004B,12
SfxDematerialise:
  ; $D9BE Rex vanishes
  INCBIN "res/sound/demo-effects.bin",$0057,12
SfxBigPod:
  ; $D9CA a big power pod
  INCBIN "res/sound/demo-effects.bin",$0063,21
SfxPowerPod:
  ; $D9DF a power pod
  INCBIN "res/sound/demo-effects.bin",$0078,21
SfxBombPod:
  ; $D9F4 a bomb pod
  INCBIN "res/sound/demo-effects.bin",$008D,21
SfxRestart:
  ; $DA09 a restart point saved
  INCBIN "res/sound/demo-effects.bin",$00A2,33
SfxRecharge:
  ; $DA2A the shield recharging
  INCBIN "res/sound/demo-effects.bin",$00C3,12

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
  DEFB $00,$DD,$21,$F6,$5E,$3A,$90,$5B ; the channel SoundStep is on
  DEFB $47,$DD,$7E,$0C,$B7,$C8,$11,$17
  DEFB $00,$DD,$19,$10,$F4,$DD,$21,$E8
  DEFB $03,$C9
