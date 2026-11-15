; --------------------------------------------------------------------------------------------------------------------
; music-module.asm: The AY player and its tunes (RAM 4, 128K only)
;
; Ben Daglish's player (MUSIC BENN on the menu), 4000 bytes loaded into RAM 4 at $C000 by LoaderMain on a 128K only.
; The game pages RAM 4 in its interrupt and calls MusicStart $C000 (A = tune - 1), MusicPlay $C003 once a frame,
; MusicStop $C00A, and hands sound effects to EffectStart $C36A with IX = a channel's effect block. Three channels run
; order lists of patterns; each note sets a period from Periods $C5C6 and an instrument (volume and pitch envelopes)
; from Instruments $CBA2.
;
; Three tunes (src/res/music/tunes.txt): 1 the menu (looped by the interrupt while NotInPlay), 2 game over (GameOver
; $BACC), 3 the game start (MenuLoop on fire). Witness: work/stage2/NOTES.md (the tune requests in c1 and the
; recordings).
; --------------------------------------------------------------------------------------------------------------------

; JP MusicInit: start tune A + 1
;
; Witness: L1 9 (c1, menu, play2).
MusicStart:
  JP MusicInit

; JP MusicFrame: one frame of the tune
;
; Witness: L1 24214 (c1, menu, play2).
MusicPlay:
  JP MusicFrame

; non-zero while a tune plays ($FF at the start, 0 when every channel has
; ended)
MusicTune:
  DEFB $00
EffectByNumber:
  DEFB $C3,$13,$C0        ; JP $C013 (the bytes C3 13 C0): never called by the
                          ; game, known only from the code

; JP Silence
;
; Witness: L1 1 (c1).
MusicStop:
  XOR A
  LD (MusicTune),A
  JP Silence

; The effect pointer, the effect-by-number routine (never run) and the three
; channels' state blocks
;
; The channel blocks of $15 bytes are at $C03B, $C050 and $C065 (pattern
; pointer, note period, timers, transpose, instrument, envelope); the
; instrument map of each channel at $C07A.
PlayerState:
  DEFB $34,$C3,$F3,$6F,$5F,$26,$00,$54
  DEFB $29,$19,$29,$29,$19,$FD,$21,$0A
  DEFB $CC,$EB,$FD,$19,$FD,$6E,$0A,$FD
  DEFB $66,$0B,$FD,$4E,$0C,$DD,$2A,$11
  DEFB $C0,$CD,$6A,$C3,$DD,$CB,$11,$FE
  DEFB $FB,$C9,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$08
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$10,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; Start tune A + 1: the three order lists from Songs, every channel reset, the
; map filled
;
; Witness: L1 9 (c1, menu, play2).
MusicInit:
  PUSH AF
  CALL Silence
  POP AF
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,A
  LD HL,Songs
  ADD A,L
  LD L,A
  JR NC,l_C0A3

; data_C0A2
data_C0A2:
  DEFB $24

; l_C0A3
;
; Used by the routine at MusicInit.
l_C0A3:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (PlayerState+$002B),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (PlayerState+$0040),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (PlayerState+$0055),DE
  XOR A
  LD (PlayerState+$0034),A
  LD (PlayerState+$0049),A
  LD (PlayerState+$005E),A
  LD (PlayerState+$0039),A
  LD (PlayerState+$004E),A
  LD (PlayerState+$0063),A
  CPL
  LD (PlayerState+$0035),A
  LD (PlayerState+$004A),A
  LD (PlayerState+$005F),A
  LD A,$01
  LD (PlayerState+$0033),A
  LD (PlayerState+$0048),A
  LD (PlayerState+$005D),A
  LD (PlayerState+$0036),A
  LD (PlayerState+$004B),A
  LD (PlayerState+$0060),A
  LD HL,PlayerState+$0069
  LD BC,$030A
l_C0F2:
  XOR A
l_C0F3:
  LD (HL),A
  INC HL
  ADD A,C
  LD (HL),A
  INC HL
  ADD A,C
  CP $50
  JR NZ,l_C0F3
  DJNZ l_C0F2
  LD HL,Instruments
  LD (PlayerState+$0031),HL
  LD (PlayerState+$0046),HL
  LD (PlayerState+$005B),HL
  LD A,$FF
  LD (PlayerState+$0037),A
  LD (PlayerState+$004C),A
  LD (PlayerState+$0061),A
  LD (MusicTune),A
  RET

; One frame: the AY registers out (WriteRegisters), then each channel's step;
; MusicTune 0 when all end
;
; Witness: L1 24214 (c1, menu, play2).
MusicFrame:
  CALL WriteRegisters
  LD A,(MusicTune)
  AND A
  RET Z
  LD A,(PlayerState+$0037)
  LD HL,PlayerState+$004C
  OR (HL)
  LD HL,PlayerState+$0061
  OR (HL)
  LD (MusicTune),A
  JR NZ,l_C144
  XOR A
  LD (MusicTune),A
  LD A,(EffectBlocks)
  AND $3F
  CP $3F
  RET Z
  LD A,$01
  LD (MusicTune),A
  RET
l_C144:
  LD IY,PlayerState+$002A
  LD IX,EffectChannelA
  CALL ChannelStep
  LD IY,PlayerState+$003F
  LD IX,EffectChannelB
  CALL ChannelStep
  LD IY,PlayerState+$0054
  LD IX,EffectChannelC

; One channel: count down the note, at its end read the order list and the
; pattern's next event
;
; Witness: L1 36801 (c1, menu, play2).
ChannelStep:
  CALL Vibrato
  LD A,(IY+$0B)
  AND A
  JR Z,l_C1E7
  DEC (IY+$09)
  JR Z,l_C182
  LD A,(IY+$03)
  LD (IY+$05),A
  LD A,(IY+$04)
  LD (IY+$06),A
  LD (IY+$0B),$00
  JR l_C1E7
l_C182:
  LD (IY+$09),$01
  LD L,(IY+$01)
  LD H,(IY+$02)
; This entry point is used by the routine at l_C1C1.
l_C18C:
  LD A,(HL)
  CP $80
  JR C,l_C1C7
  CP $FE
  JR NZ,l_C19E
  INC HL
  LD A,(HL)
  LD (IY+$0A),A
  INC HL
  JP l_C18C
l_C19E:
  CP $FF
  JR NZ,l_C1A7
  XOR A
  LD (IY+$0D),A
  RET
l_C1A7:
  CP $C0
  JR NC,l_C1B4
  AND $1F
  LD (IY+$09),A
  INC HL
  JP l_C18C
l_C1B4:
  AND $07
  ADD A,(IY+$00)
  LD DE,PlayerState+$0069
  ADD A,E
  LD E,A
  JR NC,l_C1C1

; data_C1C0
data_C1C0:
  DEFB $14

; l_C1C1
;
; Used by the routine at ChannelStep.
l_C1C1:
  INC HL
  LDI
  JP l_C18C
; This entry point is used by the routine at ChannelStep.
l_C1C7:
  LD (IY+$0B),$00
  INC HL
  LD (IY+$01),L
  LD (IY+$02),H
  LD C,A
  LD B,$00
  LD HL,PatternLo
  ADD HL,BC
  LD E,(HL)
  LD HL,PatternHi
  ADD HL,BC
  LD D,(HL)
  LD (IY+$03),E
  LD (IY+$04),D
  JR l_C1ED
; This entry point is used by the routine at ChannelStep.
l_C1E7:
  LD E,(IY+$05)
  LD D,(IY+$06)
l_C1ED:
  DEC (IY+$0C)
  JR Z,l_C1FF
  LD A,(DE)
  CP $80
  CALL NC,PatternCommand
  LD (IY+$05),E
  LD (IY+$06),D
  RET
l_C1FF:
  LD A,(DE)
  CP $80
  JR C,l_C210
  CALL PatternCommand
  LD A,(IY+$0B)
  AND A
  JR Z,l_C1FF

; data_C20D
data_C20D:
  DEFB $C3,$6B,$C1

; l_C210
;
; Used by the routine at l_C1C1.
l_C210:
  CP $7F
  JR Z,l_C25C
  CP $7E
  JR NZ,l_C221

; data_C218
data_C218:
  DEFB $13,$1A,$6F,$13,$1A,$67,$C3,$35
  DEFB $C2

; l_C221
;
; Used by the routine at l_C210.
l_C221:
  ADD A,(IY+$0A)
  ADD A,$0C
  LD (IY+$0E),A
  LD HL,Periods
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(IY+$0F)
  OR $C0
  LD (IY+$14),A
  INC DE
  LD A,(DE)
  INC DE
  LD (IY+$0C),A
  LD C,A
  LD (IY+$05),E
  LD (IY+$06),D
  LD E,(IY+$07)
  LD A,(IY+$08)
  LD IYH,A
  LD IYL,E
  BIT 7,(IX+$11)
  RET NZ
  JP EffectStart
; This entry point is used by the routine at l_C210.
l_C25C:
  INC DE
  LD A,(DE)
  INC DE
  LD (IY+$0C),A
  LD (IY+$05),E
  LD (IY+$06),D
  RET

; A pattern byte $80 and up: instrument (80-87), form (88-BF), the end mark,
; the 4-byte commands
;
; Witness: L1 1399 (c1, menu, play2).
PatternCommand:
  LD A,(DE)
  CP $88
  JR NC,l_C287
  AND $07
  ADD A,(IY+$00)
  LD C,A
  LD B,$00
  LD HL,PlayerState+$0069
  ADD HL,BC
  LD C,(HL)
  LD HL,Instruments
  ADD HL,BC
  LD (IY+$07),L
  LD (IY+$08),H
  INC DE
  RET
l_C287:
  CP $FF
  JR NZ,l_C290
  LD (IY+$0B),$FF
  RET
l_C290:
  CP $C0
  JR NC,l_C29B
  AND $0F
  LD (IY+$0F),A
  INC DE
  RET
l_C29B:
  INC DE
  CP $C2
  RET Z
  INC DE
  INC DE
  INC DE
  RET

; The pitch envelope step of a channel
;
; Witness: L1 36801 (c1, menu, play2).
Vibrato:
  BIT 7,(IX+$11)
  RET NZ
  LD A,(IY+$14)
  BIT 7,A
  RET Z
  AND $3F
  JR NZ,l_C2B7
  RES 7,(IY+$14)
  RET
l_C2B7:
  LD D,$07
  BIT 6,(IY+$14)
  JR NZ,l_C2EB
  DEC (IY+$12)
  RET NZ
  DEC (IY+$13)
  JP Z,l_C2EB
  LD L,(IY+$10)
  LD H,(IY+$11)
  INC L
  LD (IY+$10),L
  JP NZ,l_C2DA

; data_C2D6
data_C2D6:
  DEFB $24,$FD,$74,$11

; l_C2DA
;
; Used by the routine at Vibrato.
l_C2DA:
  LD A,(HL)
  AND D
  LD (IY+$12),A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,(IY+$0E)
  JP l_C320
; This entry point is used by the routine at Vibrato.
l_C2EB:
  LD HL,Envelope+$0015
  LD A,(IY+$14)
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  ADD HL,DE
  BIT 7,(HL)
  JR NZ,l_C305

; data_C2FA
data_C2FA:
  DEFB $FD,$CB,$14,$76,$20,$05,$FD,$36
  DEFB $13,$01,$C9

; l_C305
;
; Used by the routine at l_C2DA.
l_C305:
  RES 6,(IY+$14)
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND D
  LD (IY+$12),A
  LD A,(HL)
  AND D
  INC A
  LD (IY+$13),A
  LD (IY+$10),L
  LD (IY+$11),H
  LD A,(IY+$0E)
; This entry point is used by the routine at l_C2DA.
l_C320:
  ADD A,A
  LD HL,Periods
  ADD A,L
  LD L,A
  JR NC,l_C329
  INC H
l_C329:
  LD A,(HL)
  LD (IX+$03),A
  INC HL
  LD A,(HL)
  LD (IX+$04),A
  RET

; The mixer, then the effect blocks of channels A ($C334), B ($C346) and C
; ($C358), $12 bytes each
EffectBlocks:
  DEFB $BF
EffectChannelA:
  DEFB $FE,$F7,$09,$00,$00,$00,$00,$00 ; channel A's block (+6 the stop flag
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the game writes)
  DEFB $00,$00
EffectChannelB:
  DEFB $FD,$EF,$12,$00,$00,$00,$00,$00 ; channel B's block
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00
EffectChannelC:
  DEFB $FB,$DF,$24,$00,$00,$00,$00,$00 ; channel C's block
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; Start the effect described at IX on its channel
;
; Witness: L1 4031 (c1, menu, play2).
EffectStart:
  DI
  LD A,IYL
  LD (IX+$0F),A
  LD A,IYH
  LD (IX+$10),A
  LD (IX+$03),L
  LD (IX+$04),H
  LD (IX+$06),C
  LD A,(IY+$05)
  LD (IX+$07),A
  LD A,(IY+$06)
  AND $7F
  SRL A
  JR NZ,l_C38F
  LD A,$01
l_C38F:
  LD (IX+$08),A
  LD A,(IY+$07)
  LD (IX+$0B),A
  LD A,(IY+$08)
  LD (IX+$0C),A
  XOR A
  LD (IX+$09),A
  LD (IX+$0A),A
  LD A,(EffectBlocks)
  OR (IX+$02)
  LD C,(IY+$09)
  LD (IX+$11),C
  BIT 0,C
  JR Z,l_C3B8
  AND (IX+$00)
l_C3B8:
  BIT 1,C
  JR Z,l_C3BF
  AND (IX+$01)
l_C3BF:
  LD (EffectBlocks),A
  BIT 2,C
  JR NZ,l_C3D1
  LD HL,l_C507
  LD (IX+$0D),L
  LD (IX+$0E),H
  EI
  RET
l_C3D1:
  LD HL,$FFBF
  LD C,$FD
  LD A,(IY+$00)
  LD E,$0D
  CALL WriteAY
  LD A,(IY+$04)
  LD E,$0B
  CALL WriteAY
  INC E
  XOR A
  CALL WriteAY
  LD (IX+$05),$FF
  EI
  RET

; Every AY volume and the mixer off
;
; Witness: L1 10 (c1, menu, play2).
Silence:
  LD C,$FD
  LD HL,$FFBF
  LD E,$07
  LD A,(EffectBlocks)
  OR $3F
  LD (EffectBlocks),A
  CALL WriteAY
  XOR A
  INC E
  CALL WriteAY
  INC E
  CALL WriteAY
  INC E
  LD (EffectChannelA+$0011),A
  LD (EffectChannelB+$0011),A
  LD (EffectChannelC+$0011),A
  LD (EffectChannelA+$0005),A
  LD (EffectChannelB+$0005),A
  LD (EffectChannelC+$0005),A
  JP WriteAY

; The frame's periods, volumes and mixer to the AY
;
; Witness: L1 24214 (c1, menu, play2).
WriteRegisters:
  LD A,(EffectBlocks)
  AND $3F
  CP $3F
  RET Z
  LD IX,EffectChannelA
  CALL Envelope
  LD IX,EffectChannelB
  CALL Envelope
  LD IX,EffectChannelC
  CALL Envelope
  LD IX,EffectChannelA
  LD HL,$FFBF
  LD C,$FD
  LD E,$07
  LD A,(EffectBlocks)
  CALL WriteAY
  LD E,$00
  LD A,(EffectChannelA+$0003)
  ADD A,(IX+$09)
  BIT 1,(IX+$11)
  JP Z,l_C460
  LD D,A
l_C460:
  CALL WriteAY
  INC E
  LD A,(EffectChannelA+$0004)
  ADC A,(IX+$0A)
  CALL WriteAY
  INC E
  LD A,(EffectChannelB+$0003)
  ADD A,(IX+$1B)
  BIT 1,(IX+$23)
  JP Z,l_C47C

; data_C47B
data_C47B:
  DEFB $57

; l_C47C
;
; Used by the routine at WriteRegisters.
l_C47C:
  CALL WriteAY
  INC E
  LD A,(EffectChannelB+$0004)
  ADC A,(IX+$1C)
  CALL WriteAY
  INC E
  LD A,(EffectChannelC+$0003)
  ADD A,(IX+$2D)
  BIT 1,(IX+$35)
  JP Z,l_C498
  LD D,A
l_C498:
  CALL WriteAY
  INC E
  LD A,(EffectChannelC+$0004)
  ADC A,(IX+$2E)
  CALL WriteAY
  INC E
  LD A,D
  RRCA
  RRCA
  RRCA
  CALL WriteAY
  LD E,$08
  LD A,(EffectChannelA+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAY
  INC E
  LD A,(EffectChannelB+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAY
  INC E
  LD A,(EffectChannelC+$0005)
  SRL A
  SRL A
  SRL A
  JP WriteAY

; One channel's volume envelope step
;
; Witness: L1 38004 (c1, menu, play2).
Envelope:
  LD A,(EffectBlocks)
  AND (IX+$02)
  CP (IX+$02)
  RET Z
  LD A,(IX+$0F)
  LD IYL,A
  LD A,(IX+$10)
  LD IYH,A
  LD A,(IX+$06)
  AND A
  JR Z,l_C4F6
  CP $FF
  JR Z,l_C4F6
  DEC (IX+$06)
l_C4F6:
  CALL NoiseStep
  BIT 2,(IY+$09)
  JP NZ,l_C576
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  JP (HL)

; l_C507
l_C507:
  LD A,(IX+$05)
  ADD A,(IY+$00)
  CP (IY+$04)
  JR NC,l_C516
  LD (IX+$05),A
  RET
l_C516:
  LD A,(IY+$04)
  LD (IX+$05),A
  LD HL,l_C526
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; l_C526
l_C526:
  LD A,(IX+$05)
  ADD A,(IY+$01)
  JP M,l_C538
  CP (IY+$02)
  JR C,l_C538
  LD (IX+$05),A
  RET
l_C538:
  LD A,(IY+$02)
  LD (IX+$05),A
  LD HL,l_C548
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; l_C548
l_C548:
  LD A,(IX+$06)
  AND A
  RET NZ
  LD HL,l_C557
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; l_C557
l_C557:
  LD A,(IX+$05)
  ADD A,(IY+$03)
  JP M,l_C564
  LD (IX+$05),A
  RET

; l_C564
;
; Used by the routines at l_C557 and l_C576.
l_C564:
  LD (IX+$05),$00
  LD A,(EffectBlocks)
  OR (IX+$02)
  LD (EffectBlocks),A
  RES 7,(IX+$11)
  RET

; l_C576
;
; Used by the routine at Envelope.
l_C576:
  LD A,(IX+$06)
  AND A
  RET NZ
  JR l_C564

; The noise period step
;
; Witness: L1 33829 (c1, menu, play2).
NoiseStep:
  LD A,(IX+$07)
  AND A
  JR Z,l_C58A
  CP $FF
  RET Z
  DEC (IX+$07)
  RET NZ
l_C58A:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD C,(IX+$0B)
  LD B,(IX+$0C)
  ADD HL,BC
  LD (IX+$09),L
  LD (IX+$0A),H
  DEC (IX+$08)
  RET NZ
  LD A,(IY+$06)
  AND A
  RET Z
  JP P,l_C5AE
  LD (IX+$07),$FF
  RET
l_C5AE:
  LD (IX+$08),A
  LD A,C
  CPL
  LD C,A
  LD A,B
  CPL
  LD B,A
  INC BC
  LD (IX+$0B),C
  LD (IX+$0C),B
  RET

; AY register E = A (ports $FFFD, $BFFD)
;
; Witness: L1 139403 (c1, menu, play2).
WriteAY:
  LD B,H
  OUT (C),E
  LD B,L
  OUT (C),A
  RET

; 85 tone periods, a semitone apart (index 0 = $0EEE, about A#0 at 1.7734 MHz)
Periods:
  DEFW $0EEE,$0E18,$0D4D,$0C8E,$0BDA,$0B2F,$0A8F,$09F7
  DEFW $0968,$08E1,$0861,$07E9,$0777,$070C,$06A7,$0647
  DEFW $05ED,$0598,$0547,$04FC,$04D4,$0470,$0431,$03F4
  DEFW $03DC,$0386,$0353,$0324,$02F6,$02CC,$02A4,$027E
  DEFW $025A,$0238,$0218,$01FA,$01DE,$01C3,$01AA,$0192
  DEFW $017B,$0166,$0152,$013F,$012D,$011C,$010C,$00FD
  DEFW $00EF,$00E1,$00D5,$00C9,$00BE,$00B3,$00A9,$009F
  DEFW $0096,$008E,$0086,$007F,$0077,$0071,$006A,$0064
  DEFW $005F,$0059,$0054,$0050,$004B,$0047,$0043,$003F
  DEFW $003C,$0038,$0035,$0032,$002F,$002D,$002A,$0028
  DEFW $0026,$0024,$0022,$0020,$0018

; The 27 patterns, the pattern pointers, the songs and the order lists
; (tools/tunes.py)
;
; Witness: patterns read in c1 (the menu tune, tune 1) and in the RZX segments
; (tunes 2 and 3); src/res/music/tunes.txt.
Patterns:
  INCBIN "res/music/tunes.bin",$0000,1026
PatternLo:
  INCBIN "res/music/tunes.bin",$0402,27
PatternHi:
  INCBIN "res/music/tunes.bin",$041D,27
Songs:
  INCBIN "res/music/tunes.bin",$0438,18
Orders:
  INCBIN "res/music/tunes.bin",$044A,232

; The instruments: volume and pitch envelopes, to the end of the block
Instruments:
  INCBIN "res/music/instruments.bin",$0000,1022
