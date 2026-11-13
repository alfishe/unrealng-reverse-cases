; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The sound: beeper effects, their primitives, and the unused 128K and interrupt code
;
; Every effect is LD HL,params: CALL primitive(s): RET, followed by 16 bytes of parameters. No primitive reads them
; (the CPC original's envelopes, known only from the code): they are kept as leftovers. The primitives drive the
; speaker (bit 4 of port $FE) with interrupts off: sweeps, random noise from R, and noise from ROM bytes.
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
; The vector table $FDFF-$FEFF is filled with $FD, a JP Im2HandlerKey put at
; $FDFD, I = $FE, IM 2, EI; BC = 0 and CALL $B3B5 (inside the key slot reader
; at $B3B1: it reads the eight KeySlots into a bit mask at $B3CE). Nothing
; calls it (known only from the code).
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
; Witness: L1 2605 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
SfxLand:
  LD HL,SfxLandParams
  CALL SquareTone
  RET

; SfxLand's 16 unread parameter bytes
SfxLandParams:
  INCBIN "res/leftovers/sfx-land-params.bin",$0000,16

; Effect: the ball strikes a cell that is not empty and not bricks
;
; RomNoise $F560 (its noise from the ROM at $04E6). Called at $CCE2.
;
; Witness: L1 1314 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SfxHit:
  LD HL,SfxHitParams
  CALL RomNoise
  RET

; SfxHit's 16 parameter bytes (only the address's low byte $E6 is used, as
; RomNoise's start in the ROM)
SfxHitParams:
  INCBIN "res/leftovers/sfx-hit-params.bin",$0000,16

; Effect: an object picked up, a menu option chosen
;
; RandomNoise2 $F534. Called by the prize, key, water and hammer handlers
; ($B9AE, $B9C6, $B9E5, $BA04) and MenuRedraw.
;
; Witness: L1 1034 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
SfxPickup:
  LD HL,SfxPickupParams
  CALL RandomNoise2
  RET

; SfxPickup's 16 unread parameter bytes
SfxPickupParams:
  INCBIN "res/leftovers/sfx-pickup-params.bin",$0000,16

; Effect: the bottle, an extra life
;
; TripleSweep $F579 twice. Called at $BA21.
;
; Witness: L1 20 (menu, l10, l36, l45, l68, rzx x15).
SfxExtraLife:
  LD HL,SfxExtraLifeParams
  CALL TripleSweep
  CALL TripleSweep
  RET

; SfxExtraLife's 16 unread parameter bytes
SfxExtraLifeParams:
  INCBIN "res/leftovers/sfx-extra-life-params.bin",$0000,16

; Effect: a step of the animations at $C019, $C04C, $C07F
;
; RumbleHigh $F5AD.
;
; Witness: L1 55 (menu, l10, l36, l56, l59, rzx x28).
SfxAnimA:
  LD HL,SfxAnimAParams
  CALL RumbleHigh
  RET

; SfxAnimA's 16 unread parameter bytes
SfxAnimAParams:
  INCBIN "res/leftovers/sfx-anim-a-params.bin",$0000,16

; Effect: the ball bounces back from a wall (a falling sweep)
;
; SweepDown $F510. Called at $C464, $C9A2, $CBE5.
;
; Witness: L1 119 (c1, menu, twoname, l x5, rzx x39).
SfxWallBounce:
  LD HL,SfxWallBounceParams
  CALL SweepDown
  RET

; SfxWallBounce's 16 unread parameter bytes
SfxWallBounceParams:
  INCBIN "res/leftovers/sfx-wall-bounce-params.bin",$0000,16

; Effect: a step of the lock animation at $C476
;
; RandomNoise1 $F521.
;
; Witness: L1 38 (l36, l59, l96, rzx x24).
SfxLockA:
  LD HL,SfxLockAParams
  CALL RandomNoise1
  RET

; SfxLockA's 16 unread parameter bytes
SfxLockAParams:
  INCBIN "res/leftovers/sfx-lock-a-params.bin",$0000,16

; Effect: a step of the lock animation at $C488
;
; RandomNoise2 $F534.
;
; Witness: L1 117 (menu, l x6, rzx x42).
SfxLockB:
  LD HL,SfxLockBParams
  CALL RandomNoise2
  RET

; SfxLockB's 16 unread parameter bytes
SfxLockBParams:
  INCBIN "res/leftovers/sfx-lock-b-params.bin",$0000,16

; Effect: the ball lands on fire without water (stage2/rec/fire)
;
; RumbleLow $F58C, as SfxSpikeDeath. Called at $CA7A, $CCBD, $CEF9, the
; landings on a burning platform with no water drop; no recording lost a ball
; to fire.
;
; Witness: L1 1 (fire).
SfxFireDeath:
  LD HL,SfxFireDeathParams
  CALL RumbleLow
  RET

; SfxFireDeath's 16 unread parameter bytes
SfxFireDeathParams:
  INCBIN "res/leftovers/sfx-fire-death-params.bin",$0000,16

; Effect: the level is finished
;
; TripleSweep $F579 twice. Called at $B354.
;
; Witness: L1 101 (menu, l x12, rzx x88).
SfxLevelEnd:
  LD HL,SfxLevelEndParams
  CALL TripleSweep
  CALL TripleSweep
  RET

; SfxLevelEnd's 16 unread parameter bytes
SfxLevelEndParams:
  INCBIN "res/leftovers/sfx-level-end-params.bin",$0000,16

; Effect: the ball dies on platform 12
;
; RumbleLow $F58C. Called at $CA75, $CCB8, $CDC6, $CEF4.
;
; Witness: L1 13 (rzx x8).
SfxSpikeDeath:
  LD HL,SfxSpikeDeathParams
  CALL RumbleLow
  RET

; SfxSpikeDeath's 16 unread parameter bytes
SfxSpikeDeathParams:
  INCBIN "res/leftovers/sfx-spike-death-params.bin",$0000,16

; Effect: a life is lost (the ball fell, or the S key)
;
; RumbleLow $F58C. Called at $B2B2 (the fall below the screen) and $BA90.
;
; Witness: L1 20 (gameover, twoname, rzx x6).
SfxLifeLost:
  LD HL,SfxLifeLostParams
  CALL RumbleLow
  RET

; SfxLifeLost's 16 unread parameter bytes
SfxLifeLostParams:
  INCBIN "res/leftovers/sfx-life-lost-params.bin",$0000,16

; Effect: a step of the animation at $BEBB
;
; RumbleHigh $F5AD.
;
; Witness: L1 409 (l51, l59, l96, l98, rzx x27).
SfxAnimB:
  LD HL,SfxAnimBParams
  CALL RumbleHigh
  RET

; SfxAnimB's 16 unread parameter bytes
SfxAnimBParams:
  INCBIN "res/leftovers/sfx-anim-b-params.bin",$0000,16

; Effect: a tick of the timer counted into the score at the level's end
;
; SweepDown $F510. Called at $B36B.
;
; Witness: L1 5598 (menu, l x8, rzx x80).
SfxTimerTick:
  LD HL,SfxTimerTickParams
  CALL SweepDown
  RET

; SfxTimerTick's 16 unread parameter bytes
SfxTimerTickParams:
  INCBIN "res/leftovers/sfx-timer-tick-params.bin",$0000,16

; 100 speaker toggles, each delay one shorter (E = 100 down to 1): a rising
; tone
;
; Interrupts off; EI at the end.
;
; Witness: L1 5717 (c1, menu, twoname, l x11, rzx x94).
SweepDown:
  DI
  LD E,$64

; As SweepDown from the delay in E
;
; Witness: L1 6443 (c1, menu, twoname, l x12, rzx00-rzx34, rzx36-rzx82,
; rzx84-rzx97, rzx99).
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
; Witness: L1 1151 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
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
; Witness: L1 2605 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
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
; Witness: L1 1314 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
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
; Witness: L1 242 (menu, l x12, rzx x91).
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
; Witness: L1 34 (fire, gameover, twoname, rzx x11).
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
; Witness: L1 438000 (fire, gameover, menu, twoname, l x7, rzx x48).
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
