; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The AY driver: the register shadow, the engine tone, the effect counters
;
; The AY registers are kept in a 14-byte shadow at $D674 and written every frame by WriteAY $D7DC (select at $FFFD,
; data at $BFFD). SoundFrame $D692 runs from the interrupt ($7E6E): the engine tone from the speed, then the effect
; counters set by the one-shot triggers $D84E-$D898.
; --------------------------------------------------------------------------------------------------------------------

  ORG $D692

; The sound step of a frame (the interrupt)
;
; Gated by `$D691` / `$D689`. EngineTone `$D8A1` from |`$75F7`|, then each
; effect counter `$D682`-`$D68B` counts down and sets its registers in the
; shadow `$D674`-`$D681`, then WriteAY `$D7DC` (B = `$FF` select port `$FFFD`
; at `$D7E4`, data port `$BFFD` at `$D7EB`). Called by the interrupt's `$7E6E`
; in every recording.
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
  LD A,(HelicarrierData+$00C1)
  AND A
  RET Z
  LD A,(HelicarrierData+$00B9)
  AND A
  RET NZ
  LD HL,HelicarrierData+$00AB
  LD (HL),$3F
  XOR A
  LD (HelicarrierData+$00AC),A
  LD (HelicarrierData+$00AD),A
  LD (HelicarrierData+$00AE),A
  LD (HelicarrierData+$00B8),A
  LD A,$0E
  LD (l_D7E2+$000E),A
  CALL EngineTone
  LD A,(HelicarrierData+$00B2)
  DEC A
  JP M,l_D6D4
  LD (HelicarrierData+$00B2),A
  CP $10
  JR C,l_D6C6
  LD A,$0F
l_D6C6:
  SRL A
  LD (HelicarrierData+$00AD),A
  LD DE,$0050
  LD (HelicarrierData+$00A6),DE
  RES 1,(HL)
l_D6D4:
  LD A,(HelicarrierData+$00B3)
  DEC A
  JP M,l_D6E2
  LD (HelicarrierData+$00B3),A
  LD C,A
  CALL SetNoise
l_D6E2:
  LD A,(HelicarrierData+$00B4)
  DEC A
  JP M,l_D6F4
  LD (HelicarrierData+$00B4),A
  SRL A
  SRL A
  LD C,A
  CALL SetNoise
l_D6F4:
  LD A,(HelicarrierData+$00B5)
  DEC A
  JP M,l_D70E
  LD (HelicarrierData+$00B5),A
  LD DE,$00C8
  LD (HelicarrierData+$00A6),DE
  LD A,$08
  LD (HelicarrierData+$00AD),A
  RES 1,(HL)
  SET 4,(HL)
l_D70E:
  LD A,(HelicarrierData+$00B7)
  DEC A
  JP M,l_D726
  LD (HelicarrierData+$00B7),A
  LD (HelicarrierData+$00AA),A
  CPL
  RRA
  AND $0F
  LD (HelicarrierData+$00AD),A
  SET 1,(HL)
  RES 4,(HL)
l_D726:
  LD A,(HelicarrierData+$00BA)
  AND A
  JR Z,l_D745
  XOR A
  LD (HelicarrierData+$00BA),A
  CALL ApiVector06
  AND $F0
  LD E,A
  LD D,$00
  LD (HelicarrierData+$00A6),DE
  LD A,$08
  LD (HelicarrierData+$00AD),A
  RES 1,(HL)
  SET 4,(HL)
l_D745:
  LD A,(HelicarrierData+$00BB)
  DEC A
  JP M,l_D75F
  LD (HelicarrierData+$00BB),A
  SRL A
  LD (HelicarrierData+$00AD),A
  LD DE,$0FFF
  LD (HelicarrierData+$00A6),DE
  RES 1,(HL)
  SET 4,(HL)
l_D75F:
  LD A,(HelicarrierData+$00BC)
  AND A
  JR Z,l_D781
  DEC A
  LD (HelicarrierData+$00BC),A
  LD A,(HelicarrierData+$00B8)
  CP $0A
  JR NC,l_D781
  LD A,$0A
  LD (HelicarrierData+$00AD),A
  LD (HelicarrierData+$00B8),A
  LD A,$1F
  LD (HelicarrierData+$00AA),A
  RES 4,(HL)
  SET 1,(HL)
l_D781:
  LD A,(HelicarrierData+$00BD)
  AND A
  JR Z,l_D7A7
  DEC A
  LD (HelicarrierData+$00BD),A
  LD C,A
  SRL A
  SRL A
  ADD A,$05
  LD (HelicarrierData+$00AD),A
  LD A,C
  XOR $1F
  ADD A,A
  ADD A,A
  ADD A,$7F
  LD E,A
  LD D,$00
  LD (HelicarrierData+$00A6),DE
  RES 1,(HL)
  SET 4,(HL)
l_D7A7:
  LD A,(HelicarrierData+$00BE)
  AND A
  JR Z,l_D7C6
  DEC A
  LD (HelicarrierData+$00BE),A
  AND $10
  LD DE,$0080
  JR NZ,l_D7B9
  INC D
l_D7B9:
  LD (HelicarrierData+$00A6),DE
  LD A,$08
  LD (HelicarrierData+$00AD),A
  SET 4,(HL)
  RES 1,(HL)
l_D7C6:
  LD A,(HelicarrierData+$00B6)
  AND A
  JR Z,l_D7DC
  DEC A
  LD (HelicarrierData+$00B6),A
  LD (HelicarrierData+$00AA),A
  AND $0F
  LD (HelicarrierData+$00AD),A
  SET 1,(HL)
  RES 4,(HL)
l_D7DC:
  LD C,$FD
  LD HL,HelicarrierData+$00A4
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

; Set the noise period and enable it
;
; A >> 1 as the noise period when below the current `$D688`; `$D67E` / `$D67A`
; and the mixer bit 5 (death, play2).
;
; Witness frames (first-last frame of the recording, runs): c1 32619-33091
; (107), death 8122-18058 (896), play2 8608-17213 (553).
;
; Witness: L1 1449 (death, play2).
SetNoise:
  SRL A
  LD B,A
  LD A,(HelicarrierData+$00B8)
  CP B
  RET NC
  LD A,B
  LD (HelicarrierData+$00AE),A
  LD A,C
  LD (HelicarrierData+$00AA),A
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
  LD HL,HelicarrierData+$00A4
  LD B,$15
l_D80C:
  LD (HL),$00
  INC HL
  DJNZ l_D80C
  LD A,$3F
  LD (HelicarrierData+$00AB),A
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
  LD (HelicarrierData+$00B9),A
  RET

; data_D839
data_D839:
  DEFB $F5,$3E,$1F,$32,$8D,$D6,$F1,$C9

; Effect triggers no recording runs
;
; One-shot triggers no recording runs: `$D68C` = `$11` or `$23`.
EffectTriggers:
  DEFB $F5,$3E,$11,$18,$03,$F5,$3E,$23
  DEFB $32,$8C,$D6,$F1,$C9

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
  LD (HelicarrierData+$00BB),A
  POP AF
  RET

; Effect triggers no recording runs
;
; Triggers no recording runs: `$D68A` = 1.
EffectTriggersB:
  DEFB $F5,$3E,$01,$32,$8A,$D6,$F1,$C9
  DEFB $F5,$3E,$01,$18,$03

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
  LD (HelicarrierData+$00B2),A
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
  LD (HelicarrierData+$00B3),A
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
  LD (HelicarrierData+$00B4),A
  POP AF
  RET

; Effect trigger no recording runs
;
; Trigger no recording runs: `$D685` = 7.
EffectTriggersC:
  DEFB $F5,$3E,$07,$32,$85,$D6,$F1,$C9

; Missile sound trigger
;
; `$D687` = `$1E`; JP from `$C450` (the missile).
;
; Known only from the code: no recording runs it (static walk).
SoundEffect687:
  PUSH AF
  LD A,$1E
  LD (HelicarrierData+$00B7),A
  POP AF
  RET

; Effect triggers no recording runs
;
; Triggers no recording runs: `$D68E` = `$60` / `$40`.
EffectTriggersD:
  DEFB $F5,$3E,$60,$18,$01,$F5,$3E,$40
  DEFB $32,$8E,$D6,$F1,$C9

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
  LD (HelicarrierData+$00B6),A
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
  LD A,(HelicarrierData+$00AF)
  CP C
  LD A,C
  LD (HelicarrierData+$00AF),A
  JR NZ,l_D8BE
  LD A,$0B
  LD (l_D7E2+$000E),A
l_D8BE:
  XOR A
  LD (HelicarrierData+$00A4),A
  LD (HelicarrierData+$00A5),A
  LD A,$10
  LD (HelicarrierData+$00AC),A
  LD A,$0E
  LD (HelicarrierData+$00B1),A
  RES 0,(HL)
  SET 3,(HL)
  RET
