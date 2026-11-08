; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The beeper: the effects of the scenes, the background requests and the three generators
;
; The beeper is driven from the frame interrupt: IM2Handler calls SoundTick $9579 (through SoundTickVector $7125) once
; a frame (13398 runs), and each call plays one slice of the current effect inside the interrupt, so an effect sounds
; while the main loop waits; a long slice (the laser's sweep) holds the main loop for most of a frame (runtime-
; analysis.md 8). SoundRequests $7128 holds one bit per wanted effect (bit 0 the energy bomb, 1 the missile, 2 an
; explosion, 3 a ship hit by the laser, 4 the laser, 5 the ECM, 6 the player hit); SoundTick takes the lowest bit,
; arms its generator through SoundTable and clears the bit when the effect ends. SoundMode $9522 is the generator: 1 a
; sweep, 2 noise read from the ROM, 3 a pulse train; bit 7 adds a second phase. The three scene sounds (the launch,
; the jump, the arrival) instead play their whole effect at once with the interrupts off (SoundPlay); Game Over's
; (SoundGameOver) goes through SoundPlay with the interrupts on.
;
; Options bit 7 ($FC0E) is the sound switch: the pause menu's S turns it on (and clears the requests), Q off; every
; entry point returns at once when it is clear.
; --------------------------------------------------------------------------------------------------------------------

; The station not hostile (+$21 bit 2) and slots 1-7 free (energy +$22 zero),
; ShipCount 0
;
; Run by the launch and the jump: no ship survives them.
ClearShips:
  LD IX,ShipSlots
  RES 2,(IX+$21)
  XOR A
  LD (AllHostile),A
  LD DE,$0027
  LD B,$07
ClearShipsLoop:
  ADD IX,DE
  LD (IX+$22),A
  DJNZ ClearShipsLoop
  RET

; The generator playing: 0 none, 1 sweep, 2 noise, 3 pulses; bit 7 a second
; phase
SoundMode:
  DEFB $00

; E: the passes left, D: the pitch (the delay count)
SoundPitch:
  DEFW $0000

; The pulse and noise generators read their levels from this address (the ROM)
SoundSource:
  DEFW $0000

; The launch's and the dock's whistle: a pulse train played at once
;
; Called by the launch (SceneLaunchNow, as the tunnel starts), the dock (after
; SceneDock's frames) and GameOver: 4 runs, the launches of f1, w1 and d1 and
; the death of w1.
SoundLaunch:
  LD A,(Options)
  BIT 7,A
  RET Z
  CALL SoundArmLaunch
  JR SoundPlay

; The arrival from the jump (TunnelDone): a pulse train played at once
;
; Used by the routine at TunnelDone.
SoundArrive:
  LD A,(Options)
  BIT 7,A
  RET Z
  CALL SoundArmArrive
  JR SoundPlay

; The jump's start (TunnelStart): a pulse train played at once
;
; Used by the routine at TunnelStart.
SoundJump:
  LD A,(Options)
  BIT 7,A
  RET Z
  CALL SoundArmJump
  JR SoundPlay

; Game Over's sound: SoundSecond's 160-level phase, played by SoundPlay with
; the interrupts on (1 run, the death of w1)
;
; The interrupt's SoundTick plays slices of the same effect while SoundPlay
; loops, and arms the explosion ShipsWreck requested in between. As SoundTick
; never set SoundBit for this effect, its SoundEnd flips the stale bit of the
; effect before (w1 frame 4308: the laser's bit 4 set again, SoundRequests
; $14); SoundPlay clears every request when it ends, so nothing is heard of it.
SoundGameOver:
  LD A,(Options)
  BIT 7,A
  RET Z
  CALL SoundSecond

; Play the armed effect to its end (the scene sounds have the interrupts off),
; then clear the requests and EI
;
; Used by the routines at SoundLaunch, SoundArrive and SoundJump.
SoundPlay:
  LD A,(SoundMode)
  AND A
  JR Z,SoundPlayDone
  CALL SoundPulses
  JR SoundPlay
SoundPlayDone:
  LD (SoundRequests),A
  EI
  RET

; SoundTable, bit 0: the energy bomb, falling pulses
;
; SoundTable is eight JPs, one per request bit; SoundTick computes the bit's
; number * 3. Bits 0, 1, 3 and 5 were set first in k2 (the bomb, the missile, a
; ship hit, the E.C.M.: SoundArmBomb, SoundArmMissile, SoundArmShipHit,
; SoundArmECM); bit 7 is never set and shares bit 6's code.
SoundBomb:
  JP SoundArmBomb

; SoundTable, bit 1: the missile launch, pulses
SoundMissile:
  JP SoundArmMissile

; SoundTable, bit 2: an explosion, two-phase pulses
SoundExplode:
  JP SoundArmTwoPhase

; SoundTable, bit 3: a ship hit, noise
SoundShipHit:
  JP SoundArmShipHit

; SoundTable, bit 4: the laser, a sweep
SoundLaser:
  JP SoundArmLaser

; SoundTable, bit 5: the ECM, a sweep
SoundECM:
  JP SoundArmECM

; SoundTable, bit 6: the player hit, noise
SoundHit:
  JP SoundArmHit

; SoundTable, bit 7: as bit 6 (never requested)
SoundSpare:
  JP SoundArmHit

; One slice of the effect playing, or arm the effect of the lowest request bit
;
; Runs once a frame from IM2Handler; with SoundMode 0 and no request it returns
; at once. The jump to SoundTable is computed (bit number * 3 + $9561), so the
; static walk does not see it.
SoundTick:
  LD A,(Options)
  BIT 7,A
  RET Z
  LD A,(SoundMode)
  AND A
  JR NZ,SoundTickMode
  LD A,(SoundRequests)
  AND A
  RET Z
  LD B,$FF
SoundTickBit:
  INC B
  RRA
  JR NC,SoundTickBit
  LD A,B
  LD (SoundBit),A
  ADD A,A
  ADD A,B
  LD HL,SoundBomb
  ADD A,L
  LD L,A
  JR NC,SoundTickJump
  INC H
SoundTickJump:
  JP (HL)
SoundTickMode:
  DEC A
  JP Z,SoundSweep
  DEC A
  JR Z,SoundNoise

; The pulse generator: 64 beeper levels from SoundSource, each held D loops;
; the pitch steps per pass
;
; The level is bit 3 or bit 4 of the ROM byte (the MIC and EAR bits of $FE), so
; the ROM's bytes give a rough waveform. The step added to D per pass is
; patched at $95BD and the 64 at $95AE. When E reaches 0: a second phase (bit
; 7, SoundSecond) or the end (SoundEnd).
SoundPulses:
  LD HL,(SoundSource)
  LD DE,(SoundPitch)

; SoundPulsesNow
;
; Used by the routine at SoundArmPulse.
SoundPulsesNow:
  LD C,$40
SoundPulsesLoop:
  LD A,(HL)
  AND $18
  OUT ($FE),A
  LD B,D
SoundPulsesDelay:
  DJNZ SoundPulsesDelay
  INC HL
  DEC C
  JR NZ,SoundPulsesLoop
SoundPulsesPass:
  LD A,D
  ADD A,$00
  LD D,A
  DEC E
  LD (SoundPitch),DE
  LD (SoundSource),HL
  RET NZ
  LD A,(SoundMode)
  BIT 7,A
  JR Z,SoundEnd

; The second phase of a two-phase effect: 160 levels a pass, pitch $40, 2
; passes
;
; Used by the routine at SoundGameOver.
SoundSecond:
  LD A,$03
  LD (SoundMode),A
  LD A,$A0
  LD (SoundPulsesNow+$0001),A
  LD HL,$0127
  LD DE,$4002
  LD (SoundPitch),DE
  LD (SoundSource),HL
  RET

; The noise generator: 100 pulses whose length is a ROM byte / 4 (or / 2 + 8),
; D passes
;
; SoundArmNoise patches the instruction at $95F2: SRL A ($CB $3F) for a ship
; hit, ADD A,$10 ($C6 $10) for the player hit, so the hit's pulses are longer.
; L steps through the ROM page in SoundSource.
SoundNoise:
  LD HL,(SoundSource)
  LD DE,(SoundPitch)

; SoundNoiseNow
;
; Used by the routine at SoundArmNoise.
SoundNoiseNow:
  LD C,$64
SoundNoiseLoop:
  LD A,(HL)
  INC L
  SRL A
  SRL A
  LD E,A
  LD B,A
  LD A,$30
  OUT ($FE),A
SoundNoiseHigh:
  DJNZ SoundNoiseHigh
  LD B,E
  XOR A
  OUT ($FE),A
SoundNoiseLow:
  DJNZ SoundNoiseLow
  DEC C
  JR NZ,SoundNoiseLoop

; One pass done: D (or E) one less, the state saved, the end at 0
;
; Used by the routine at SoundSweepNow.
SoundPassEnd:
  DEC D
  LD (SoundPitch),DE
  LD (SoundSource),HL
  RET NZ

; The effect over: SoundMode 0 and its request bit cleared
;
; Used by the routine at SoundPulsesNow.
SoundEnd:
  XOR A
  LD (SoundMode),A
  LD A,(SoundBit)
  INC A
  LD B,A
  LD A,$80
SoundEndBit:
  RLCA
  DJNZ SoundEndBit
  LD HL,SoundRequests
  XOR (HL)
  LD (HL),A
  RET

; The sweep generator: 15 square cycles a pass, each pass's half period 2 E +
; the patched step
;
; Used by the routine at SoundTick.
SoundSweep:
  LD DE,(SoundPitch)

; SoundSweepNow
;
; Used by the routine at SoundArmSweep.
SoundSweepNow:
  LD A,E
  ADD A,A
  ADD A,$05
  LD E,A
  LD C,$0F
SoundSweepLoop:
  LD A,$30
  LD B,E
  OUT ($FE),A
SoundSweepHigh:
  DJNZ SoundSweepHigh
  XOR A
  LD B,E
  OUT ($FE),A
SoundSweepLow:
  DJNZ SoundSweepLow
  DEC C
  JR NZ,SoundSweepLoop
  JR SoundPassEnd

; Arm the laser: a sweep of step $FD (falling), 2 passes
;
; Used by the routine at SoundLaser.
SoundArmLaser:
  LD A,$FD
  LD DE,$0200
  JR SoundArmSweep

; Arm the ECM: a sweep of step $D3, 8 passes (k2: 10 runs from frame 2573)
;
; Used by the routine at SoundECM.
SoundArmECM:
  LD A,$D3
  LD DE,$0800

; The step into SoundSweep, SoundMode 1, the first pass at once
;
; Used by the routine at SoundArmLaser.
SoundArmSweep:
  LD (SoundSweepNow+$0003),A
  LD A,$01
  LD (SoundMode),A
  JR SoundSweepNow

; Arm the player hit: noise from the ROM at $1A1A, 1 pass
;
; Used by the routines at SoundHit and SoundSpare.
SoundArmHit:
  LD A,$1A
  LD HL,$10C6
  JR SoundArmNoise

; Arm a ship hit: noise from the ROM at $031A, 1 pass (k2: 15 runs from frame
; 3187)
;
; Used by the routine at SoundShipHit.
SoundArmShipHit:
  LD A,$03
  LD HL,$3FCB

; The instruction patched in, SoundSource = A * 256 + $1A ($1A1A or $031A),
; SoundMode 2, the first pulses at once
;
; Used by the routine at SoundArmHit.
SoundArmNoise:
  LD DE,$0100
  LD (SoundNoiseLoop+$0002),HL
  LD H,A
  LD L,$1A
  LD A,$02
  LD (SoundMode),A
  JP SoundNoiseNow

; Arm the missile's launch: pulses stepping by $E4 a pass (k2: 1 run, frame
; 2542)
;
; Used by the routine at SoundMissile.
SoundArmMissile:
  LD C,$E4
  JR SoundArmPulses8
; This entry point is used by the routine at SoundBomb.
SoundArmBomb:
  LD C,$FE                ; the energy bomb: pulses stepping by $FE
SoundArmPulses8:
  LD A,$03
  LD (SoundMode),A

; The first phase of the explosion: 64 levels, pitch $40, 8 passes
;
; Used by the routine at SoundArmTwoPhase.
SoundArmExplode:
  LD B,$40
  LD DE,$4008

; Patch the level count (B) and the pitch step (C) into SoundPulses and play a
; pass
;
; Used by the routines at SoundArmLaunch and SoundArmScene.
SoundArmPulse:
  LD HL,$0127
  LD A,C
  LD (SoundPulsesPass+$0002),A
  LD A,B
  LD (SoundPulsesNow+$0001),A
  JP SoundPulsesNow

; Arm the explosion: SoundMode $83, the pitch step 2
;
; Used by the routine at SoundExplode.
SoundArmTwoPhase:
  LD A,$83
  LD (SoundMode),A
  LD C,$02
  JR SoundArmExplode

; Arm SoundLaunch: 80 levels, the step 2, pitch $40, $20 passes, the interrupts
; off
;
; Used by the routine at SoundLaunch.
SoundArmLaunch:
  LD A,$03
  LD (SoundMode),A
  DI
  LD BC,$5002
  LD DE,$4020
  JR SoundArmPulse

; Arm SoundArrive: 192 levels, the step $F0, pitch $C0, 12 passes
;
; Used by the routine at SoundArrive.
SoundArmArrive:
  LD BC,$C0F0
  LD DE,$C00C

; SoundArmScene
;
; Used by the routine at SoundArmJump.
SoundArmScene:
  DI                      ; SoundMode 3 with the interrupts off
  LD A,$03
  LD (SoundMode),A
  JR SoundArmPulse

; Arm SoundJump: 192 levels, the step $10, pitch $10, 10 passes
;
; Used by the routine at SoundJump.
SoundArmJump:
  LD BC,$C010
  LD DE,$100A
  JR SoundArmScene

; The request bit playing; five spare bytes
SoundBit:
  DEFB $00,$00,$00,$00,$00,$00

; BC shifted right by 4 (ShiftBC3 by 3, ShiftBC2 by 2, ShiftBC1 by 1): the
; debris's scale
;
; Used by the routine at DrawScanner.
ShiftBC4:
  SRL B
  RR C

; ShiftBC3
;
; Used by the routine at DrawScanner.
ShiftBC3:
  SRL B
  RR C

; ShiftBC2
;
; Used by the routine at DrawScanner.
ShiftBC2:
  SRL B
  RR C

; ShiftBC1
;
; Used by the routine at DrawScanner.
ShiftBC1:
  SRL B
  RR C
  RET
