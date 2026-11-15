; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The sound: beeper effects, their primitives, and the unused 128K and interrupt code
;
; Every effect is LD HL,params: CALL primitive(s): RET, followed by its AY register image: 16 bytes, R0-R13 and two
; zeros, the block WriteAyRegisters $F190 would write (doc 9, 9.5). No beeper primitive reads them (RomNoise only the
; address's low byte): they are the resource sound/ay-images.csv. The primitives drive the speaker (bit 4 of port $FE)
; with interrupts off: sweeps, random noise from R, and noise from ROM bytes.
;
; $F183-$F3C7 holds code no recording ran and nothing calls: a random number, an AY register writer for the 128K, a
; delay, a line-table builder, and two IM 2 set-ups whose handlers call empty hooks. It is the frame of a 128K music
; driver that this release does not have.
; --------------------------------------------------------------------------------------------------------------------

  ORG $F183

; A = a random byte from R (never called)
;
; R twice XORed into an address in HL, then R XOR (that address). HL kept.
; Nothing calls it (known only from the code).
;
; Witness: L1 0 ().
Random:
  PUSH HL
  LD A,R
  LD H,A
  LD A,R
  XOR H
  LD L,A
  LD A,R
  XOR (HL)
  POP HL
  RET

; Write AY registers 0-13 from the 14 bytes at HL (never called)
;
; For each register A = 0-13: C = (HL), WriteAyRegister. Nothing calls it
; (known only from the code).
;
; Witness: L1 0 ().
WriteAyRegisters:
  LD B,$0E
WriteAyRegistersLoop:
  PUSH BC
  LD A,$0E
  SUB B
  LD C,(HL)
  INC HL
  CALL WriteAyRegister
  POP BC
  DJNZ WriteAyRegistersLoop
  RET

; Write C to AY register A (128K ports $FFFD, $BFFD)
;
; Register 7 (the mixer) is masked with $3F, so the I/O ports stay inputs. OUT
; ($FFFD),A then OUT ($BFFD),C, interrupts off between. Known only from the
; code.
;
; Witness: L1 0 ().
WriteAyRegister:
  CP $07
  JR NZ,WriteAyRegisterSkip
  LD B,A
  LD A,$3F
  AND C
  LD C,A
  LD A,B
WriteAyRegisterSkip:
  DI
  LD E,C
  LD BC,$FFFD
  OUT (C),A
  LD A,E
  LD BC,$BFFD
  OUT (C),A
  EI
  RET

; 16 bytes: seven NOPs, $FF and eight NOPs
UnusedF1B8:
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; HALT, then a loop of 512 (never called)
;
; Known only from the code.
;
; Witness: L1 0 ().
DelayAfterFrame:
  PUSH HL
  EI
  HALT
  LD HL,$0200
DelayAfterFrameLoop:
  DEC HL
  LD A,L
  OR H
  JR NZ,DelayAfterFrameLoop
  POP HL
  RET

; Write the 192 Spectrum line addresses at $F206 (never called)
;
; For line 0-191: $4000 + (line & $C0) x 32 + (line & 7) x 256 + (line & $38) x
; 4, stored as words from $F206: the table $B52D holds the same addresses ready
; made. Run, it would write $F206-$F385 over this code and the IM 2 set-ups
; (known only from the code).
;
; Witness: L1 0 ().
BuildLineTable:
  LD IX,LineTableArea
  LD B,$C0
BuildLineTableLoop:
  LD A,$C0
  SUB B
  LD C,A
  LD H,C
  SRL H
  SRL H
  SRL H
  LD A,H
  AND $18
  LD H,A
  LD A,$07
  AND C
  OR H
  LD H,A
  LD A,C
  AND $38
  SLA A
  SLA A
  LD L,A
  SET 6,H
  LD (IX+$00),L
  INC IX
  LD (IX+$00),H
  INC IX
  DJNZ BuildLineTableLoop
  RET

; 35 bytes where BuildLineTable writes: a shifted copy of the code $F1E1-$F205
LineTableArea:
  DEFB $3C,$CB,$3C,$7C,$E6,$18,$67,$3E
  DEFB $07,$A1,$B4,$67,$79,$E6,$38,$CB
  DEFB $27,$CB,$27,$6F,$CB,$F4,$DD,$75
  DEFB $00,$DD,$23,$DD,$74,$00,$DD,$23
  DEFB $10,$D6,$C9

; 282 zeros
UnusedF229:
  DEFS $011A

; Install IM 2 with handler Im2HandlerKey, then call $B3B5 (never called)
;
; LDIR fills $FDFF-$FF00 with $FD, then a JP Im2HandlerKey put at $FDFD (its
; word overwrites $FDFF), I = $FE, IM 2, EI: the vectors are $FE00-$FF00, all
; $FDFD. Then BC = 0 and CALL ReadControlMaskKeepDE $B3B5 (inside the key slot
; reader ReadControlMask $B3B2: it reads the eight KeySlots into a bit mask at
; $B3CE). Nothing calls it (known only from the code).
;
; Witness: L1 0 ().
InstallIm2Key:
  DI
  LD HL,$FDFF
  LD DE,$FE00
  LD BC,$0101
  LD (HL),$FD
  LDIR
  LD A,$C3
  LD ($FDFD),A
  LD HL,Im2HandlerKey
  LD ($FDFE),HL
  LD A,$FE
  LD I,A
  IM 2
  EI
  LD BC,$0000
  CALL ReadControlMaskKeepDE
  EI
  RET

; The IM 2 handler of InstallIm2Key: save all, call Im2HookKey, RETI
;
; Witness: L1 0 ().
Im2HandlerKey:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  CALL Im2HookKey
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RETI

; RET: the place of a per-frame routine (music) the handler would call
;
; Witness: L1 0 ().
Im2HookKey:
  RET

; 5 bytes: LD HL,$F38A and two NOPs, never run
UnusedF383:
  DEFB $21,$8A,$F3,$00,$00

; Install IM 2 with handler Im2HandlerWait, then wait for a key (never called)
;
; As InstallIm2Key, with Im2HandlerWait in the JP at $FDFD and CALL $B3FA (wait
; for a key down and up). Nothing calls it (known only from the code).
;
; Witness: L1 0 ().
InstallIm2Wait:
  DI
  LD HL,$FDFF
  LD DE,$FE00
  LD BC,$0101
  LD (HL),$FD
  LDIR
  LD A,$C3
  LD ($FDFD),A
  LD HL,Im2HandlerWait
  LD ($FDFE),HL
  LD A,$FE
  LD I,A
  IM 2
  EI
  LD BC,$0000
  CALL WaitPress
  EI
  RET

; The IM 2 handler of InstallIm2Wait: save all, call Im2HookWait, RETI
;
; Witness: L1 0 ().
Im2HandlerWait:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  CALL Im2HookWait
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RETI

; RET: the place of a per-frame routine the handler would call
;
; Witness: L1 0 ().
Im2HookWait:
  RET

; Effect: the ball lands on a platform (the square tone)
;
; SquareTone $F54C. Called at $C79E, $C86D, $CAB3 when the landing sets $ABA7 =
; 1.
;
; Witness: L1 2628 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop,
; twoname, l x12, rzx00-rzx99).
SfxLand:
  LD HL,SfxLandParams
  CALL SquareTone
  RET

; SfxLand's AY register image: R0-R13 and two zeros, the block WriteAyRegisters
; $F190 would write; unread on the 48K
SfxLandParams:
  INCBIN "res/sound/ay-land.bin",$0000,16

; Effect: the ball strikes a cell that is not empty and not bricks
;
; RomNoise $F560 (its noise from the ROM at $04E6). Called at $CCE2.
;
; Witness: L1 1324 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12,
; rzx00-rzx77, rzx79-rzx99).
SfxHit:
  LD HL,SfxHitParams
  CALL RomNoise
  RET

; SfxHit's AY register image: R0-R13 and two zeros, the block WriteAyRegisters
; $F190 would write; on the 48K only the address's low byte $E6 is used, as
; RomNoise's start in the ROM
SfxHitParams:
  INCBIN "res/sound/ay-hit.bin",$0000,16

; Effect: an object picked up, a menu option chosen
;
; RandomNoise2 $F534. Called by the prize, key, water and hammer handlers
; ($B9AE, $B9C6, $B9E5, $BA04) and MenuRedraw.
;
; Witness: L1 1054 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12,
; rzx00-rzx99).
SfxPickup:
  LD HL,SfxPickupParams
  CALL RandomNoise2
  RET

; SfxPickup's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxPickupParams:
  INCBIN "res/sound/ay-pickup.bin",$0000,16

; Effect: the bottle, an extra life
;
; TripleSweep $F579 twice. Called at $BA21.
;
; Witness: L1 23 (menu, scoreloop, l10, l36, l45, l68, rzx x15).
SfxExtraLife:
  LD HL,SfxExtraLifeParams
  CALL TripleSweep
  CALL TripleSweep
  RET

; SfxExtraLife's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxExtraLifeParams:
  INCBIN "res/sound/ay-extra-life.bin",$0000,16

; Effect: a water drop falls on a fire (WaterA1 $C019, WaterB1 $C04C, WaterC1
; $C07F)
;
; RumbleHigh $F5AD.
;
; Witness: L1 55 (menu, l10, l36, l56, l59, rzx x28).
SfxWaterDrop:
  LD HL,SfxWaterDropParams
  CALL RumbleHigh
  RET

; SfxWaterDrop's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxWaterDropParams:
  INCBIN "res/sound/ay-water-drop.bin",$0000,16

; Effect: the ball bounces back from a wall (a falling sweep)
;
; SweepDown $F510. Called at $C464, $C9A2, $CBE5.
;
; Witness: L1 119 (c1, menu, twoname, l x5, rzx x39).
SfxWallBounce:
  LD HL,SfxWallBounceParams
  CALL SweepDown
  RET

; SfxWallBounce's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxWallBounceParams:
  INCBIN "res/sound/ay-wall-bounce.bin",$0000,16

; Effect: a step of the lock animation at $C476
;
; RandomNoise1 $F521.
;
; Witness: L1 38 (l36, l59, l96, rzx x24).
SfxLockA:
  LD HL,SfxLockAParams
  CALL RandomNoise1
  RET

; SfxLockA's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxLockAParams:
  INCBIN "res/sound/ay-lock-a.bin",$0000,16

; Effect: a step of the lock animation at $C488
;
; RandomNoise2 $F534.
;
; Witness: L1 117 (menu, l x6, rzx x42).
SfxLockB:
  LD HL,SfxLockBParams
  CALL RandomNoise2
  RET

; SfxLockB's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxLockBParams:
  INCBIN "res/sound/ay-lock-b.bin",$0000,16

; Effect: the ball lands on fire without water (stage2/rec/fire)
;
; RumbleLow $F58C, as SfxSpikeDeath. Called at $CA7A, $CCBD, $CEF9, the
; landings on a burning platform with no water drop; stage2/rec/fire (Water
; POKEd to 0) is the only one.
;
; Witness: L1 1 (fire).
SfxFireDeath:
  LD HL,SfxFireDeathParams
  CALL RumbleLow
  RET

; SfxFireDeath's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxFireDeathParams:
  INCBIN "res/sound/ay-fire-death.bin",$0000,16

; Effect: the level is finished
;
; TripleSweep $F579 twice. Called at $B354.
;
; Witness: L1 102 (exitbelow, menu, l x12, rzx x88).
SfxLevelEnd:
  LD HL,SfxLevelEndParams
  CALL TripleSweep
  CALL TripleSweep
  RET

; SfxLevelEnd's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxLevelEndParams:
  INCBIN "res/sound/ay-level-end.bin",$0000,16

; Effect: the ball dies on platform 12
;
; RumbleLow $F58C. Called at $CA75, $CCB8, $CDC6, $CEF4.
;
; Witness: L1 14 (rightspike, rzx x8).
SfxSpikeDeath:
  LD HL,SfxSpikeDeathParams
  CALL RumbleLow
  RET

; SfxSpikeDeath's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxSpikeDeathParams:
  INCBIN "res/sound/ay-spike-death.bin",$0000,16

; Effect: a life is lost (the ball fell, or the S key)
;
; RumbleLow $F58C. Called at $B2B2 (the fall below the screen) and $BA90.
;
; Witness: L1 23 (gameover, scoreloop, twoname, rzx x6).
SfxLifeLost:
  LD HL,SfxLifeLostParams
  CALL RumbleLow
  RET

; SfxLifeLost's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxLifeLostParams:
  INCBIN "res/sound/ay-life-lost.bin",$0000,16

; Effect: a brick layer crumbles (BrickCrumble1 $BEBB)
;
; RumbleHigh $F5AD.
;
; Witness: L1 409 (l51, l59, l96, l98, rzx x27).
SfxBrickCrumble:
  LD HL,SfxBrickCrumbleParams
  CALL RumbleHigh
  RET

; SfxBrickCrumble's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxBrickCrumbleParams:
  INCBIN "res/sound/ay-brick-crumble.bin",$0000,16

; Effect: a tick of the timer counted into the score at the level's end
;
; SweepDown $F510. Called at $B36B.
;
; Witness: L1 5622 (exitbelow, menu, l x8, rzx x80).
SfxTimerTick:
  LD HL,SfxTimerTickParams
  CALL SweepDown
  RET

; SfxTimerTick's AY register image: R0-R13 and two zeros, the block
; WriteAyRegisters $F190 would write; unread on the 48K
SfxTimerTickParams:
  INCBIN "res/sound/ay-timer-tick.bin",$0000,16

; 100 speaker toggles, each delay one shorter (E = 100 down to 1): a rising
; tone
;
; Interrupts off; EI at the end.
;
; Witness: L1 5741 (c1, exitbelow, menu, twoname, l x11, rzx x94).
SweepDown:
  DI
  LD E,$64

; As SweepDown from the delay in E
;
; Witness: L1 6491 (c1, exitbelow, menu, scoreloop, twoname, l x12,
; rzx00-rzx34, rzx36-rzx82, rzx84-rzx97, rzx99).
SweepFromE:
  XOR A
SweepFromELoop:
  OUT ($FE),A
  XOR $10
  LD D,E
SweepFromELoop2:
  DEC D
  JR NZ,SweepFromELoop2
  DEC E
  JR NZ,SweepFromELoop
  EI
  RET

; 100 speaker pulses, each delay taken from R, the speaker bit from R
;
; Witness: L1 38 (l36, l59, l96, rzx x24).
RandomNoise1:
  DI
  LD E,$64
  XOR A
RandomNoise1Loop:
  OUT ($FE),A
  LD A,R
  LD D,A
  AND $10
RandomNoise1Loop2:
  DEC D
  JR NZ,RandomNoise1Loop2
  DEC E
  JR NZ,RandomNoise1Loop
  EI
  RET

; 100 pulses, the speaker bit from R, delay $50 + (R & $3F)
;
; Witness: L1 1171 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12,
; rzx00-rzx99).
RandomNoise2:
  DI
  LD E,$64
RandomNoise2Loop:
  LD A,R
  AND $10
  OUT ($FE),A
  LD A,R
  AND $3F
  ADD A,$50
  LD D,A
RandomNoise2Loop2:
  DEC D
  JR NZ,RandomNoise2Loop2
  DEC E
  JR NZ,RandomNoise2Loop
  EI
  RET

; 100 half periods: on with a delay of 100, off at once
;
; Witness: L1 2628 (c1, exitbelow, fire, gameover, menu, rightspike, scoreloop,
; twoname, l x12, rzx00-rzx99).
SquareTone:
  DI
  LD E,$64
  XOR A
SquareToneLoop:
  OUT ($FE),A
  XOR $10
  JR Z,SquareToneSkip
  LD D,$64
SquareToneLoop2:
  DEC D
  JR NZ,SquareToneLoop2
SquareToneSkip:
  DEC E
  JR NZ,SquareToneLoop
  EI
  RET

; 100 pulses from ROM bytes $0400 + L on: the speaker bit and the delay $28 +
; (byte & $3F)
;
; L is the low byte of the effect's parameter address.
;
; Witness: L1 1324 (c1, exitbelow, gameover, menu, scoreloop, twoname, l x12,
; rzx00-rzx77, rzx79-rzx99).
RomNoise:
  DI
  LD E,$64
  LD H,$04
RomNoiseLoop:
  LD A,(HL)
  INC L
  AND $10
  OUT ($FE),A
  LD A,(HL)
  INC L
  AND $3F
  ADD A,$28
RomNoiseLoop2:
  DEC A
  JR NZ,RomNoiseLoop2
  DEC E
  JR NZ,RomNoiseLoop
  EI
  RET

; Three sweeps from R-based delays (R set to $3F first, so the same each time)
;
; Witness: L1 250 (exitbelow, menu, scoreloop, l x12, rzx x91).
TripleSweep:
  DI
  LD A,$3F
  LD R,A
  LD B,$02
TripleSweepLoop:
  LD A,R
  ADD A,$8C
  LD E,A
  CALL SweepFromE
  DJNZ TripleSweepLoop
  JR SweepFromE

; 600 samples from ROM $0000: border bits and speaker from the byte, delay
; (byte & $F0) + 1
;
; Writes the mask $F0 into the AND at $F59F; RomRumble does the rest.
;
; Witness: L1 38 (fire, gameover, rightspike, scoreloop, twoname, rzx x11).
RumbleLow:
  DI
  LD HL,$0000
  LD BC,$0258
  LD A,$F0
  LD (RomRumble+$0008),A

; The sample loop: HL the ROM, BC the count, the mask in the AND at $F59F
;
; Each byte: OUT ($FE),(byte & $F8) (border black, MIC and speaker bits from
; the ROM), then a delay of (byte & mask) + 1. EI at the end.
;
; Witness: L1 440400 (fire, gameover, menu, rightspike, scoreloop, twoname, l
; x7, rzx x48).
RomRumble:
  LD A,(HL)
  INC HL
  AND $F8
  OUT ($FE),A
  LD A,(HL)
  AND $3F
  INC A
RomRumbleLoop:
  NOP
  DEC A
  JR NZ,RomRumbleLoop
  DEC BC
  LD A,B
  OR C
  JR NZ,RomRumble
  EI
  RET

; 900 samples from ROM $1770, mask $0E
;
; Witness: L1 464 (menu, l x7, rzx x42).
RumbleHigh:
  DI
  LD HL,$1770
  LD BC,$0384
  LD A,$0E
  LD (RomRumble+$0008),A
  JR RomRumble

; An effect nothing calls: 900 samples from ROM $0BB8, mask $38
;
; Known only from the code.
;
; Witness: L1 0 ().
SfxUnused:
  DI
  LD HL,$0BB8
  LD BC,$0384
  LD A,$38
  LD (RomRumble+$0008),A
  JR RomRumble
