; --------------------------------------------------------------------------------------------------------------------
; beeper.asm: The beeper noise and sweep effects
; --------------------------------------------------------------------------------------------------------------------

; BeeperNoise with B = $37: nothing calls it
;
; Never ran in any recording, no caller in the image.
NoiseShort:
  LD B,$37

; A noise burst on the beeper: B pulses of random level, each shorter than the
; last (nothing on a 128K)
;
; Returns at once when SoundIsAy is set. Each of the B rounds: OUT ($FE) with R
; AND $F8 (the speaker and MIC bits random, border 0), a wait of B + 1 loops,
; OUT 0. So the bursts rise in pitch as they end. Callers: DefineKeys' click
; ($C8), $8338, $83DD, $9071, $9EC1, $9FBD, $A817. c1: 644 calls.
BeeperNoise:
  LD A,(SoundIsAy)
  OR A
  RET NZ
BeeperNoiseLoop:
  LD A,R
  AND $F8
  OUT ($FE),A
  LD E,B
  INC E
BeeperNoiseWait:
  DEC E
  JR NZ,BeeperNoiseWait
  XOR A
  OUT ($FE),A
  DJNZ BeeperNoiseLoop
  RET

; A falling beeper tone: 16 steps of 10 half-waves, the period from $30 to $3F
; loops (nothing on a 128K)
;
; Called by $9942. Keeps every register. Ran only in the warp runs (460 calls),
; never on a 128K path.
BeeperSweep:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,(SoundIsAy)
  OR A
  JR NZ,BeeperSweepDone
  XOR A
  LD DE,$1030
BeeperSweepStep:
  LD H,$0A                ; 10 half-waves of period E
BeeperSweepHalf:
  XOR $10
  OUT ($FE),A
  LD B,E
BeeperSweepWait:
  DJNZ BeeperSweepWait
  DEC H
  JR NZ,BeeperSweepHalf
  INC E
  DEC D
  JR NZ,BeeperSweepStep
BeeperSweepDone:
  POP HL
  POP DE
  POP BC
  POP AF
  RET
