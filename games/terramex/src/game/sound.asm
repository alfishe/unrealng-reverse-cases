; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The beeper sound effects
; --------------------------------------------------------------------------------------------------------------------

; Play beeper sound A (0-6), HL, DE, BC kept
;
; Calls SoundDispatch $C4BC. The callers and their sounds: PickUpItem $BBF2
; (2), DropFall $C051 (5), $A3E1 ($A484, 6), CreatureDeath $A89E ($A8A3, 3
; every pass), DeathFrames $A8AB ($A8B7, the sound in C at the end of a death's
; frames: 0 for FallDeath $A888, 4 for Room1ADeath $A88F), $B0B6, $AA3C. The
; players are busy loops with the interrupts on: the L1 builds record 58
; interrupts inside SoundChirp's loop ($C4D5-$C4D9, 16 builds), so the AY music
; of the IM 2 handler goes on and stretches the beeps: the half-wave the
; interrupt falls in grows by about 3700 T (the chirp's 7914 T to 11 679 T in
; c1 frame 23 509), and in the paper area the ULA's contention adds about 23 %
; (`EX (SP),HL` on the stack in RAM 5, `OUT ($FE)`); doc 9, 9.11.
;
; Witness: L1 339 (c1, explorers, gameover, rzx x26).
PlaySound:
  PUSH HL
  PUSH DE
  PUSH BC
  CALL SoundDispatch
  POP BC
  POP DE
  POP HL
  RET

; Jump to the player of sound A through SoundEffects $C55B, E = $10 (the
; speaker bit)
;
; A of 7 and more: nothing. The player's address is pushed and RET jumps to it.
;
; Witness: L1 339 (c1, explorers, gameover, rzx x26).
SoundDispatch:
  CP $07
  RET NC
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,SoundEffects
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  LD E,$10
  RET

; Sound 2, the pickup: four bursts of 10 half-waves, each shorter (H $7F, $1F,
; 7, 1)
;
; Half-wave length H loop turns of OUT ($FE) with two EX (SP),HL of delay; H /
; 4 after each burst. Played by PickUpItem $BBF2 (and 1 more, 31 runs in 16
; builds).
;
; Witness: L1 31 (c1, explorers, gameover, rzx x13).
SoundChirp:
  LD H,$7F
SoundChirpBurst:
  XOR A
  LD B,$0A
SoundChirpWave:
  PUSH BC
  LD B,H
SoundChirpDelay:
  OUT ($FE),A
  EX (SP),HL
  EX (SP),HL
  DJNZ SoundChirpDelay
  XOR $10
  POP BC
  DJNZ SoundChirpWave
  SRL H
  SRL H
  LD A,H
  OR A
  JR NZ,SoundChirpBurst
  RET

; Sound 1: 2250 bytes of ROM from $0000 to the speaker at a falling pitch, then
; sound 0
;
; HL = $0000, BC = 9000 counted down by 4: each byte of the ROM (AND E: the
; speaker bit) is sent after a delay of $23 - B loop turns, so the pitch falls
; as B does; then SoundRise $C506. Witness: gameover and rzx16000 play it once
; each.
;
; Witness: L1 2 (gameover, rzx x1).
SoundRomFall:
  LD HL,$0000
  LD BC,$2328
SoundRomFallLoop:
  LD A,$23
  SUB B
  JR Z,SoundRomFallByte
  PUSH BC
  LD B,A
SoundRomFallDelay:
  DJNZ SoundRomFallDelay
  POP BC
SoundRomFallByte:
  LD A,(HL)
  INC HL
  AND E
  OUT ($FE),A
  DEC BC
  DEC BC
  DEC BC
  DEC BC
  LD A,C
  OR B
  JR NZ,SoundRomFallLoop

; Sound 0: six bursts of 10 half-waves, each longer
;
; As SoundChirp $C4CE, H shifted up with a 1 bit after each burst: 6 bursts, H
; 3, 7, $0F, $1F, $3F, $7F. Played alone and at the end of SoundRomFall $C4E9.
; Witness: gameover (twice), rzx10000, rzx16000, rzx24000.
;
; Witness: L1 5 (gameover, rzx x3).
SoundRise:
  LD H,$03
SoundRiseBurst:
  XOR A
  LD B,$0A
SoundRiseWave:
  PUSH BC
  LD B,H
SoundRiseDelay:
  OUT ($FE),A
  EX (SP),HL
  EX (SP),HL
  DJNZ SoundRiseDelay
  XOR $10
  POP BC
  DJNZ SoundRiseWave
  SCF
  RL H
  LD A,H
  CP $FF
  JR NZ,SoundRiseBurst
  RET

; Sound 3: 100 bits from the ROM bytes $0000-$003F picked by R
;
; Witness: rzx06000, rzx22000, rzx32000 play it 11 times each (the status $18
; handler CreatureDeath $A89E).
;
; Witness: L1 33 (rzx x3).
SoundHiss:
  LD B,$64
SoundHissLoop:
  LD A,R
  AND $3F
  LD L,A
  LD H,$00
  LD A,(HL)
  AND $10
  OUT ($FE),A
  DJNZ SoundHissLoop
  RET

; Sound 6: 3 square waves of $C8 loop turns a half
;
; HL = $03C8 (H the waves, L the half-wave), then SoundTone $C53A. Played by
; $A3E1 at $A484 (164 runs in 24 builds).
;
; Witness: L1 164 (gameover, rzx x23).
SoundBeepLow:
  LD HL,$03C8
  JR SoundTone

; Sound 5, the drop's splash: 5 square waves of $64 loop turns a half
;
; HL = $0564, then SoundTone $C53A (fallen into). Played by DropFall $C051, 105
; times.
;
; Witness: L1 105 (rzx x18).
SoundBeepHigh:
  LD HL,$0564

; H square waves of 2 x L loop turns on the speaker (E the speaker bit)
;
; Witness: L1 1017 (gameover, rzx x24).
SoundTone:
  XOR A
  LD B,L
  OUT ($FE),A
SoundToneLow:
  DJNZ SoundToneLow
  LD A,E
  OUT ($FE),A
  LD B,L
SoundToneHigh:
  DJNZ SoundToneHigh
  DEC H
  JR NZ,SoundTone
  RET

; Sound 4: 1280 bytes of ROM from $0000 to the speaker, no delay
;
; HL = $0000 (LD HL,$0000: SK took its operand for NOPs), B = 0: 256 x 5 bytes,
; each AND E sent. Witness: rzx10000 plays it once.
;
; Witness: L1 1 (rzx x1).
SoundRomBurst:
  LD HL,$0000
  LD B,L
SoundRomBurstLoop:
  LD C,$05
SoundRomBurstByte:
  LD A,(HL)
  AND E
  OUT ($FE),A
  INC HL
  DEC C
  JR NZ,SoundRomBurstByte
  DJNZ SoundRomBurstLoop
  RET

; The players of the sounds 0-6
;
; Read by SoundDispatch $C4BC: 0 SoundRise, 1 SoundRomFall, 2 SoundChirp, 3
; SoundHiss, 4 SoundRomBurst, 5 SoundBeepHigh, 6 SoundBeepLow. Witness: the
; play builds read the words of the sounds they play.
SoundEffects:
  DEFW SoundRise
  DEFW SoundRomFall
  DEFW SoundChirp
  DEFW SoundHiss
  DEFW SoundRomBurst
  DEFW SoundBeepHigh
  DEFW SoundBeepLow

; Leftover: 23 bytes ($00 x 16, then $03 $00 $02 $00 $01 $00 $00) no code
; refers to
;
; No instruction of the image names an address in $C569-$C57F and no play build
; reads them (the load in c1 only); known only from the code.
SoundPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $03,$00,$02,$00,$01,$00,$00
