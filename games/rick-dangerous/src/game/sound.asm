; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The sound: effects and tunes on the AY player in RAM 1, the 48K beeper effects
;
; A 128K runs every sound through the AY player that CopyPlayerToRam1 $A069 copies from the image's $5E00-$6BA3 to RAM
; 1 at $C000: PlayEffect pages RAM 1 in and calls its effect entry $C685, StartTune its tune entry $C3E4, and
; SoundTick its tick $C46C, 50 times a second from the interrupt handler (the CALL that $A069 writes at $FF11). Each
; of them pages RAM 0 back and enables interrupts.
;
; On a 48K (Is48K $A08D not 0, set by DetectPaging $A043) there are no tunes (StartTune returns at once, the handler's
; slot at $FF11 stays three NOPs) and the effects go to BeeperEffect $A08E, six tone patterns on bit 4 of port $FE.
; The beeper48 recording (work/stage2/beeper48: the original loaded on a 48K, level 1 played with our own keys) runs
; it: 98 effects, Is48K $FF and the handler's slot three NOPs in its start state.
; --------------------------------------------------------------------------------------------------------------------

; Play sound effect A: on the AY (128K) or the beeper (48K)
;
; Input: A the effect number. On a 48K (Is48K not 0) calls BeeperEffect with A
; (and the effect number in C, which the beeper's first OUT uses as the port's
; low byte). On a 128K pages RAM 1 in (OUT $7FFD = 1), calls AyPlayEffect $C685
; with A, pages RAM 0 back (OUT $7FFD = 0) and enables interrupts.
;
; Output: AF and C changed on the 128K path; HL, DE, BC preserved there.
; Interrupts enabled on return. 13 call sites, all in the game code from $EC93
; to $FD44.
;
; Witness: L1 5978 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
PlayEffect:
  LD C,A
  LD A,(Is48K)
  AND A
  LD A,C
  JR Z,PlayEffectAy
  PUSH HL
  CALL BeeperEffect
  POP HL
  RET
PlayEffectAy:
  DI                      ; the 128K path: page RAM 1, call the player, page
                          ; RAM 0
  PUSH HL
  PUSH DE
  PUSH BC
  LD D,A
  LD A,$01
  LD BC,$7FFD
  OUT (C),A
  LD A,D
  CALL AyPlayEffect
  XOR A
  LD BC,$7FFD
  OUT (C),A
  EI
  POP BC
  POP DE
  POP HL
  RET

; Start tune A on the AY player (128K only)
;
; Input: A the tune number. Returns at once on a 48K. Else pages RAM 1, calls
; AyPlayTune $C3E4, pages RAM 0 back, enables interrupts.
;
; The tunes the callers start: 5 the title ($E220), 0 the game start ($E324), 6
; the game over ($E386), at a level's end the number of the next level, 1-4
; ($AC20).
;
; Output: AF, BC, D changed.
;
; Witness: L1 30 (beeper48, c1, controls, ending2, gameover, L3Z12, level1).
StartTune:
  LD D,A
  LD A,(Is48K)
  AND A
  RET NZ
  DI
  LD A,$01
  LD BC,$7FFD
  OUT (C),A
  LD A,D
  CALL AyPlayTune
  XOR A
  LD BC,$7FFD
  OUT (C),A
  EI
  RET

; The AY player's frame tick, called by the interrupt handler
;
; Pages RAM 1, calls AyTick $C46C, pages RAM 0 back and enables interrupts.
; Called only from the slot at $FF11 inside the interrupt handler ($FEFE),
; which CopyPlayerToRam1 fills with CALL $A030 on a 128K: 50 times a second for
; the whole game (c1: 14301 runs in 33400 frames, most of them the loading's).
;
; Output: AF, BC changed (the handler saves every register).
;
; Witness: L1 106735 (c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
SoundTick:
  DI
  LD A,$01
  LD BC,$7FFD
  OUT (C),A
  CALL AyTick
  XOR A
  LD BC,$7FFD
  OUT (C),A
  EI
  RET

  ORG $A08D

; 0 on a 128K, $FF on a 48K (DetectPaging $A05F)
;
; Read by PlayEffect and StartTune. 0 in the image and in the 128K recordings;
; `$FF` in beeper48 (the 48K).
Is48K:
  DEFB $00

; Play a sound effect on the beeper (48K)
;
; Input: A the effect number, C its copy (PlayEffect). B = $FE, H = $10 and L =
; 0: BeeperTone toggles port $FE bit 4 (the speaker) with a black border. The
; six patterns, E being the half period in loops of DEC C / JR NZ:
;
; 0: 50 tones, the period falling 50 ... 1 (a rising chirp). 2: a warble, tones
; alternating between E + $32 and E, E climbing by 2 from $B0 until it wraps to
; 0. 6: 30 tones from $28, the period stepping down by 30, 29 ... 1 (modulo
; 256). $0B: 32 tones, the period rising 1, 5 ... $7D (a falling note). 4: a
; single tone of period $80. Any other: up 1, 9 ... $F9, then down by 8 (a
; siren).
;
; The very first OUT of an effect goes to port $FE00 + the effect number (C
; still holds it): for an odd effect ($0B) the ULA ignores that half wave;
; after it C is 0.
;
; Output: AF, C, DE changed. Run in beeper48 only (98 effects: the chirp, the
; warble, the descending steps, the falling note, the click and the siren
; branches all ran).
;
; Witness: L1 98 (beeper48).
BeeperEffect:
  LD B,$FE
  LD HL,$1000
  AND A
  JP NZ,BeeperNot0
  LD E,$32
BeeperChirpLoop:
  CALL BeeperTone         ; effect 0
  DEC E
  JR NZ,BeeperChirpLoop
  RET
BeeperNot0:
  CP $02
  JR NZ,BeeperNot2
  LD E,$B0
BeeperWarbleLoop:
  CALL BeeperTone         ; effect 2
  LD A,E
  ADD A,$32
  LD E,A
  CALL BeeperTone
  LD A,E
  ADD A,$D0
  LD E,A
  JR NZ,BeeperWarbleLoop
  RET
BeeperNot2:
  CP $06
  JR NZ,BeeperNot6
  LD D,$1E
  LD E,$28
BeeperDescendLoop:
  CALL BeeperTone         ; effect 6
  LD A,E
  SUB D
  LD E,A
  DEC D
  JR NZ,BeeperDescendLoop
  RET
BeeperNot6:
  CP $0B
  JR NZ,BeeperNotB
  LD E,$01
BeeperFallLoop:
  CALL BeeperTone         ; effect $0B
  LD A,E
  ADD A,$04
  LD E,A
  CP $80
  JR C,BeeperFallLoop
  RET
BeeperNotB:
  CP $04
  JR Z,BeeperClick
  LD E,$01
BeeperSirenUp:
  CALL BeeperTone         ; any other effect: up
  LD A,E
  ADD A,$08
  LD E,A
  JR NC,BeeperSirenUp
BeeperSirenDown:
  CALL BeeperTone         ; ... and down
  LD A,E
  ADD A,$F8
  LD E,A
  JR C,BeeperSirenDown
  RET
BeeperClick:
  LD E,$80                ; effect 4: one tone of period $80, through
                          ; BeeperTone's RET

; One square wave of the beeper: L out, wait E, H out, wait E
;
; Input: B = $FE, C the port's low byte for the first OUT, L and H the two port
; values, E the half period. Output: C = 0. Called by BeeperEffect only.
;
; Witness: L1 999 (beeper48).
BeeperTone:
  OUT (C),L
  LD C,E
BeeperWaitLow:
  DEC C
  JR NZ,BeeperWaitLow
  OUT (C),H
  LD C,E
BeeperWaitHigh:
  DEC C
  JR NZ,BeeperWaitHigh
  RET
