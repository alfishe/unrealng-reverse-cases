; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The AY driver: the register shadow, the engine tone, the effect counters
;
; The AY registers are kept in a 14-byte shadow at $D674 and written every frame by WriteAY $D7DC (select at $FFFD,
; data at $BFFD). SoundFrame $D692 runs from the interrupt ($7E6E): the engine tone from the speed, then the effect
; counters set by the one-shot triggers $D841-$D898.
; --------------------------------------------------------------------------------------------------------------------

  ORG $D674

; The AY register shadow R0-R13, written by WriteAY $D7DC
AYRegs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$3F,$00,$00,$00,$00,$00,$00
SelectCount:
  DEFB $00                ; the weapon select counter (SoundSelect)
ExplosionCount:
  DEFB $00
KillCount:
  DEFB $00
ToneC8Count:
  DEFB $00
FireSoundCount:
  DEFB $00                ; the shot sound counter (SoundFire; FireCount $9718
                          ; is the fire key's)
MissileCount:
  DEFB $00
NoisePriority:
  DEFB $00                ; zeroed each frame, set only by the steady noise
                          ; path
SoundGate:
  DEFB $00                ; non-zero: SoundFrame returns; SilenceAY leaves $0E
RandomToneFlag:
  DEFB $00
MessageSoundCount:
  DEFB $00
SteadyNoiseCount:
  DEFB $00
SweepCount:
  DEFB $00
SirenCount:
  DEFB $00,$00,$00
SoundMaster:
  DEFB $01                ; 1 in the image, never written

; The sound step of a frame (the interrupt)
;
; Gated by `$D691` (1 in the image and never written: the test always passes)
; and `$D689`. EngineTone `$D8A1` from |`$75F7`|, then each effect counter
; `$D682`-`$D68B` counts down and sets its registers in the shadow
; `$D674`-`$D681`, then WriteAY `$D7DC` (B = `$FF` select port `$FFFD` at
; `$D7E4`, data port `$BFFD` at `$D7EB`). Called by the interrupt's `$7E6E` in
; every recording.
;
; Witness frames (first-last frame of the recording, runs): c1 24005-33298
; (4124), controls 0-330 (242), death 0-20038 (12655), m10 0-9028 (6434),
; m2erbe 0-7808 (3094), m2ocean 0-4799 (2244), menu 0-10996 (7559), missions
; 0-35997 (12811), play 0-10930 (5510), play2 0-23665 (12957), search 0-5043
; (2265).
;
; Witness: L1 65529 (death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
SoundFrame:
  LD A,(SoundMaster)
  AND A
  RET Z
  LD A,(SoundGate)
  AND A
  RET NZ
  LD HL,AYRegs+$0007
  LD (HL),$3F
  XOR A
  LD (AYRegs+$0008),A
  LD (AYRegs+$0009),A
  LD (AYRegs+$000A),A
  LD (NoisePriority),A
  LD A,$0E
  LD (l_D7E2+$000E),A
  CALL EngineTone
  LD A,(SelectCount)
  DEC A
  JP M,l_D6D4
  LD (SelectCount),A
  CP $10
  JR C,l_D6C6
  LD A,$0F
l_D6C6:
  SRL A
  LD (AYRegs+$0009),A
  LD DE,$0050
  LD (AYRegs+$0002),DE
  RES 1,(HL)
l_D6D4:
  LD A,(ExplosionCount)
  DEC A
  JP M,l_D6E2
  LD (ExplosionCount),A
  LD C,A
  CALL SetNoise
l_D6E2:
  LD A,(KillCount)
  DEC A
  JP M,l_D6F4
  LD (KillCount),A
  SRL A
  SRL A
  LD C,A
  CALL SetNoise
l_D6F4:
  LD A,(ToneC8Count)
  DEC A
  JP M,l_D70E
  LD (ToneC8Count),A
  LD DE,$00C8
  LD (AYRegs+$0002),DE
  LD A,$08
  LD (AYRegs+$0009),A
  RES 1,(HL)
  SET 4,(HL)
l_D70E:
  LD A,(MissileCount)
  DEC A
  JP M,l_D726
  LD (MissileCount),A
  LD (AYRegs+$0006),A
  CPL
  RRA
  AND $0F
  LD (AYRegs+$0009),A
  SET 1,(HL)
  RES 4,(HL)
l_D726:
  LD A,(RandomToneFlag)
  AND A
  JR Z,l_D745
  XOR A
  LD (RandomToneFlag),A
  CALL ApiVector06
  AND $F0
  LD E,A
  LD D,$00
  LD (AYRegs+$0002),DE
  LD A,$08
  LD (AYRegs+$0009),A
  RES 1,(HL)
  SET 4,(HL)
l_D745:
  LD A,(MessageSoundCount)
  DEC A
  JP M,l_D75F
  LD (MessageSoundCount),A
  SRL A
  LD (AYRegs+$0009),A
  LD DE,$0FFF
  LD (AYRegs+$0002),DE
  RES 1,(HL)
  SET 4,(HL)
l_D75F:
  LD A,(SteadyNoiseCount)
  AND A
  JR Z,l_D781
  DEC A
  LD (SteadyNoiseCount),A
  LD A,(NoisePriority)
  CP $0A
  JR NC,l_D781
  LD A,$0A
  LD (AYRegs+$0009),A
  LD (NoisePriority),A
  LD A,$1F
  LD (AYRegs+$0006),A
  RES 4,(HL)
  SET 1,(HL)
l_D781:
  LD A,(SweepCount)
  AND A
  JR Z,l_D7A7
  DEC A
  LD (SweepCount),A
  LD C,A
  SRL A
  SRL A
  ADD A,$05
  LD (AYRegs+$0009),A
  LD A,C
  XOR $1F
  ADD A,A
  ADD A,A
  ADD A,$7F
  LD E,A
  LD D,$00
  LD (AYRegs+$0002),DE
  RES 1,(HL)
  SET 4,(HL)
l_D7A7:
  LD A,(SirenCount)
  AND A
  JR Z,l_D7C6
  DEC A
  LD (SirenCount),A
  AND $10
  LD DE,$0080
  JR NZ,l_D7B9
  INC D
l_D7B9:
  LD (AYRegs+$0002),DE
  LD A,$08
  LD (AYRegs+$0009),A
  SET 4,(HL)
  RES 1,(HL)
l_D7C6:
  LD A,(FireSoundCount)
  AND A
  JR Z,l_D7DC
  DEC A
  LD (FireSoundCount),A
  LD (AYRegs+$0006),A
  AND $0F
  LD (AYRegs+$0009),A
  SET 1,(HL)
  RES 4,(HL)
l_D7DC:
  LD C,$FD
  LD HL,AYRegs
  XOR A
l_D7E2:
  LD B,$FF
  OUT (C),A
  EX AF,AF'
  LD A,(HL)
  INC HL
  LD B,$BF
  OUT (C),A
  EX AF,AF'
  INC A
  CP $0E
  JR NZ,l_D7E2
  RET

; Set the noise period and the volume of channel C, noise C on
;
; C as the noise period (`$D67A`; both callers pass C = A), A >> 1 as the
; volume of channel C (`$D67E`), the mixer's bit 5 cleared (noise C on);
; returns without a write when A >> 1 is not above NoisePriority `$D688`
; (death, play2).
;
; Witness frames (first-last frame of the recording, runs): c1 32619-33091
; (107), death 8122-18058 (896), play2 8608-17213 (553).
;
; Witness: L1 1449 (death, play2).
SetNoise:
  SRL A
  LD B,A
  LD A,(NoisePriority)
  CP B
  RET NC
  LD A,B
  LD (AYRegs+$000A),A
  LD A,C
  LD (AYRegs+$0006),A
  RES 5,(HL)
  RET

; Silence the AY
;
; Zeroes the 21 bytes from `$D674`, mixer `$3F` (all off), writes the 14
; registers.
;
; Witness frames (first-last frame of the recording, runs): c1 23974-24603 (2),
; controls 95-264 (2), m2erbe 7454-7522 (2), menu 95-1874 (4), missions
; 7955-34068 (16), play 10627-10693 (2), play2 9615-23533 (6).
;
; Witness: L1 30 (m2erbe, menu, missions, play, play2).
SilenceAY:
  LD HL,AYRegs
  LD B,$15
l_D80C:
  LD (HL),$00
  INC HL
  DJNZ l_D80C
  LD A,$3F
  LD (AYRegs+$0007),A
  LD C,$FD
  XOR A
l_D819:
  LD B,$FF
  OUT (C),A
  CP $07
  JR NZ,l_D826
  EX AF,AF'
  LD A,$3F
  JR l_D828
l_D826:
  EX AF,AF'
  XOR A
l_D828:
  LD B,$BF
  OUT (C),A
  EX AF,AF'
  INC A
  CP $0E
  JR NZ,l_D819
  LD (l_D7E2+$000E),A
  LD (SoundGate),A
  RET

; data_D839
data_D839:
  DEFB $F5,$3E,$1F,$32,$8D,$D6,$F1,$C9

; Effect trigger: the steady noise counter $D68C = $11
;
; `PUSH AF` / `LD A,$11` / `JR` 3 bytes into SoundNoise23's store.
;
; Known only from the code: no caller.
SoundNoise11:
  PUSH AF
  LD A,$11
  JR l_D849

; Effect trigger: the steady noise counter $D68C = $23
;
; Known only from the code: no caller.
SoundNoise23:
  PUSH AF
  LD A,$23
; This entry point is used by the routine at SoundNoise11.
l_D849:
  LD (SteadyNoiseCount),A
  POP AF
  RET

; Effect trigger $D68B
;
; `$D68B` = `$1E` (play2: 21 runs).
;
; Witness frames (first-last frame of the recording, runs): c1 32680-33293
; (15), play2 8700-17195 (21).
;
; Witness: L1 21 (play2).
SoundEffectA:
  PUSH AF
  LD A,$1E
  LD (MessageSoundCount),A
  POP AF
  RET

; Effect trigger: the random tone flag $D68A = 1
;
; Known only from the code: no caller.
SoundRandomTone:
  PUSH AF
  LD A,$01
  LD (RandomToneFlag),A
  POP AF
  RET

; Effect trigger: SelectCount $D682 = 1
;
; `LD A,1` then `JR` into SoundSelect's store.
;
; Known only from the code: no caller.
SoundSelectShort:
  PUSH AF
  LD A,$01
  JR l_D866

; Weapon select sound
;
; `$D682` = `$12`: the weapon select.
;
; Witness frames (first-last frame of the recording, runs): death 7705 (1),
; play 8425-9322 (4), play2 8362-23071 (9).
;
; Witness: L1 14 (death, play, play2).
SoundSelect:
  PUSH AF
  LD A,$12
; This entry point is used by the routine at SoundSelectShort.
l_D866:
  LD (SelectCount),A
  POP AF
  RET

; Explosion sound
;
; `$D683` = `$20`: an explosion.
;
; Witness frames (first-last frame of the recording, runs): c1 32618-33054 (5),
; death 8121-17902 (8), play2 8607-17180 (19).
;
; Witness: L1 27 (death, play2).
SoundExplosion:
  PUSH AF
  LD A,$20
  LD (ExplosionCount),A
  POP AF
  RET

; Kill sound
;
; `$D684`: a kill (death: 5 runs).
;
; Witness frames (first-last frame of the recording, runs): death 8187-17902
; (5).
;
; Witness: L1 5 (death).
SoundKill:
  PUSH AF
  LD A,$80
  LD (KillCount),A
  POP AF
  RET

; Effect trigger: ToneC8Count $D685 = 7
;
; Known only from the code: no caller.
SoundToneC8:
  PUSH AF
  LD A,$07
  LD (ToneC8Count),A
  POP AF
  RET

; Missile sound trigger
;
; `$D687` = `$1E`; JP from `$C450` (the missile).
;
; Known only from the code: no recording runs it (static walk).
SoundEffect687:
  PUSH AF
  LD A,$1E
  LD (MissileCount),A
  POP AF
  RET

; Effect trigger: the siren counter $D68E, meant to be $60
;
; Bug: `JR $D891` (`18 01`) lands on `LD A,$40`, so this entry stores `$40`
; too, never `$60`.
;
; Known only from the code: no caller.
SoundSiren60:
  PUSH AF
  LD A,$60
  JR l_D891

; Effect trigger: the siren counter $D68E = $40
;
; Known only from the code: no caller.
SoundSiren40:
  PUSH AF
; This entry point is used by the routine at SoundSiren60.
l_D891:
  LD A,$40
  LD (SirenCount),A
  POP AF
  RET

; Fire sound
;
; `$D686` = `$14`: a shot.
;
; Witness frames (first-last frame of the recording, runs): death 7897-19694
; (60), play 8800-9406 (4), play2 8442-16931 (6).
;
; Witness: L1 70 (death, play, play2).
SoundFire:
  PUSH AF
  LD A,$14
  LD (FireSoundCount),A
  POP AF
  RET

; A spare byte after SoundFire
;
; `$0A`, after the RET of SoundFire; no routine of this fragment reads it.
SoundFireVar:
  DEFB $0A

; Engine tone from the speed
;
; |speed| through `$67D6` gives the tone period of channel A in the shadow (17
; 682 runs).
;
; Witness frames (first-last frame of the recording, runs): c1 32219-33298
; (982), death 7592-20038 (10012), m2erbe 7090-7522 (281), missions 7592-34068
; (2195), play 8253-10693 (2004), play2 8184-23533 (3190).
;
; Witness: L1 17682 (death, m2erbe, missions, play, play2).
EngineTone:
  LD C,A
  LD A,(PlayerSpeed)
  AND A
  CALL ApiVector08
  ADD A,$08
  ADD A,A
  NEG
  LD C,A
  LD A,(AYRegs+$000B)
  CP C
  LD A,C
  LD (AYRegs+$000B),A
  JR NZ,l_D8BE
  LD A,$0B
  LD (l_D7E2+$000E),A
l_D8BE:
  XOR A
  LD (AYRegs),A
  LD (AYRegs+$0001),A
  LD A,$10
  LD (AYRegs+$0008),A
  LD A,$0E
  LD (AYRegs+$000D),A
  RES 0,(HL)
  SET 3,(HL)
  RET
