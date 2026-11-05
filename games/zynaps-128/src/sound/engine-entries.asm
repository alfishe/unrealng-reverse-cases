; --------------------------------------------------------------------------------------------------------------------
; engine-entries.asm: the entries: the jump table, the effect entries, starting and stopping, the AY output
;
; The engine's interface. The game (the 48K Zynaps, patched by the 128K glue) keeps bank 0 at $C000 and pages in page
; 4 only for a call: the glue's interrupt handler at $5B00 calls EnginePlay once a frame, $5B50 stops the music
; (EngineStop) and starts it again (EngineStart), and the fifteen hook stubs at $B30D-$B3A8 call one of the effect
; entries ($C971-$C9B1) with page 4 in (docs/09-sound.md 9.2). Every entry keeps no register: the callers save what
; they need.
;
; An effect entry loads A with a sound number of the data image's SoundTable ($0E-$1F) and jumps to StartSound, which
; takes channels B and C in turn (LastChannel XOR 1; channel A only before the music was ever started), or to
; StartOnChannelA (the player's shot), or to StartTwoSounds (A then B: two sounds on the two effect channels). The
; music is sounds $0B, $0C, $0D on channels A, B, C (StartMusic); an effect takes its channel from the music until the
; effect's end command, and the music's channel then stays silent until EngineStart restarts the music (the glue's
; $5B50 with A not 0: 6 runs in c1).
;
; The entries without a hook stub: EffectSound13 ($C983) and EffectSound17 ($C995) are called by nothing in the game
; or the glue (a static scan of every part for the call; not run in c1); EffectSound10 ($C9A5) is called by the glue
; at $5B75 (the game's call at $B024 patched to $5B6D), 18 runs in c1.
;
; The engine is the Amstrad CPC Zynaps's own sound driver (J. Dave Rogers's music, Hewson 1987) moved up by $5000: The
; Cyborg's AY rip of the CPC game (work/stage2/sound/cpc/local-modland/zynaps.cpc.emul, its code block at $7968) has
; the same 955 bytes but for: the high bytes of its own addresses ($7A25 there, $CA25 here); the output routine
; (SendRegisters to $CA5F: the CPC writes the AY through its PPI ports $F4xx / $F6xx, here OUT to $FFFD / $BFFD),
; whose shorter ZX form leaves room for PitchStep; the pitch envelope's step at $CC43 (the CPC adds step - $80 to the
; period in line, ADD HL,BC / LD C,$80; here CALL PitchStep adds twice that); StartMusic's LastChannel, $FF there and
; 3 here; and the variables ($CC8B on), which hold a running engine's values in the rip and a fresh engine's here. The
; doubled pitch step goes with the doubled periods: the data image's period table is the CPC's moved up 12 notes
; (docs/09-sound.md 9.6). Its data block ($D000-$FFFF in the rip) holds this data image at the same addresses, $DE48
; on (src/res/sound/README.md).
; --------------------------------------------------------------------------------------------------------------------

; the jump table: start the music ($C968), stop it ($C96B), play a frame
; ($C96E)
;
; The three entries of the engine's interface. $C968 JP StartMusic: 6 calls in
; c1's game window (the glue's $5B50 after a life). $C96B JP StopMusic: 29
; calls. $C96E JP PlayFrame: 10393 calls, one a frame (the glue's interrupt
; handler $5B00).
EngineStart:
  JP StartMusic
EngineStop:
  JP StopMusic            ; JP StopMusic
EnginePlay:
  JP PlayFrame            ; JP PlayFrame

; sound $0E on channel A: the player fires
;
; The hook stub $B32F (the 48K shot site $9C77): 91 runs in c1. Always channel
; A (StartOnChannelA), so a shot cuts the music's channel A.
EffectShot:
  LD A,$0E
  JR StartOnChannelA

; sounds $0F and $10 on the two effect channels
;
; The hook stub $B334 (after the level count at $ACA2); not run in c1
; (docs/09-sound.md 9.2).
EffectSound0F10:
  LD A,$0F
  LD B,$10
  JR StartTwoSounds

; sound $11
;
; The hook stub $B33C (an object's countdown at $9EC2); not run in c1.
EffectSound11:
  LD A,$11
  JR StartSound

; sound $12: the role of honour shown
;
; The hook stub $B344: 5 runs in c1, one a game.
EffectRoleOfHonour:
  LD A,$12
  JR StartSound

; sound $13
;
; No caller: no hook stub and no call in the game or the glue loads this entry
; (a scan of every part for $83 as the stub's L and for CALL $C983); not run in
; c1.
EffectSound13:
  LD A,$13
  JR StartSound

; sounds $14 and $15: the player's ship destroyed, the role of honour's result
;
; The hook stubs $B354 (the ship destroyed, 18 runs) and $B34C (the role of
; honour's result, 5 runs): 23 runs. Goes on at ShipLostSecond for the second
; sound.
EffectShipLost:
  LD A,$14
  JR ShipLostSecond

; sounds $1A and $1B
;
; The hook stub $B35C (an object launched from the ship at $9CFA); not run in
; c1.
EffectSound1A1B:
  LD A,$1A
  LD B,$1B
  JR StartTwoSounds

; sound $16: a pod taken
;
; The hook stub $B364: 1 run in c1 (frame 12017).
EffectPodTaken:
  LD A,$16
  JR StartSound

; sound $17
;
; No caller (as EffectSound13); not run in c1.
EffectSound17:
  LD A,$17
  JR StartSound

; sound $18
;
; The hook stub $B36C (the weapon slot $F5A8 launched); not run in c1.
EffectSound18:
  LD A,$18
  JR StartSound

; sound $19: an enemy fires a missile
;
; The hook stub $B374: 6 runs in c1.
EffectEnemyMissile:
  LD A,$19
  JR StartSound

; sound $0F: a pod taken with the power gauge full
;
; The hook stub $B379: 1 run in c1.
EffectPodFullGauge:
  LD A,$0F
  JR StartSound

; sound $10
;
; Called by the glue at $5B75 (the game's call at $B024 goes to $5B6D: the
; music stopped, then this sound): 18 runs in c1, as many as the ship was lost.
EffectSound10:
  LD A,$10
  JR StartSound

; sound $1C: a fuel pod changes state
;
; The hook stub $B381: 4 runs in c1.
EffectPodChange:
  LD A,$1C
  JR StartSound

; sound $1D: an explosion starts
;
; The hook stub $B386: 115 runs in c1 (L1 count; stage 1 counted 43 frames:
; several explosions start in one frame).
EffectExplosion:
  LD A,$1D
  JR StartSound

; sounds $1E and $1F: the game over (and the end of the game won)
;
; The hook stubs $B39C (the game-over wipe, 5 runs) and $B38F (not run in c1).
EffectGameOver:
  LD A,$1E
  LD B,$1F
  JR StartTwoSounds

; the second sound of EffectShipLost
;
; B = $15, then StartTwoSounds: 23 runs.
ShipLostSecond:
  LD B,$15
  JR StartTwoSounds

; start sound A on channel A
;
; Input: A = the sound number. C = A, A = 1 (channel A), on at SetUpChannel. 97
; runs (91 shots, 6 music starts).
StartOnChannelA:
  LD C,A
  LD A,$01
  JR SetUpChannel

; start sound A, then sound B, on the two effect channels
;
; Input: A, B = the sound numbers. StartSound with A, then A = B and on into
; StartSound. 28 runs.
StartTwoSounds:
  CALL StartSound
  LD A,B                  ; the second sound

; start sound A on the next effect channel
;
; Input: A = the sound number. LastChannel XOR 1 picks the channel: 2 or 3 (B
; or C) after StartMusic set it to 3; 1 or 0 (both channel A) before the music
; was ever started. SetUpChannel ($C9CD) takes A = 1, 2 or 3 and C = the sound:
; IX = the channel's record (ChannelA, ChannelB, ChannelC), the sound's address
; from SoundTable + 2 x C into the record's current, return and start pointers
; (+$21, +$23, +$25), active (+$1E) = 1, the wait (+$1F) = 1 (the first command
; is read at the next PlayFrame), the transposition (+$27) = 0, and MixerExtra
; = 0. Output: IX = the record. 218 runs.
StartSound:
  LD C,A
  LD A,(LastChannel)      ; the channel before
  XOR $01                 ; the other one: B and C alternate (2, 3)
  LD (LastChannel),A
; This entry point is used by the routine at StartOnChannelA.
SetUpChannel:
  LD IX,ChannelA          ; A = the channel 1-3, C = the sound
  CP $02                  ; 1: channel A
  JR C,ChannelChosen
  LD IX,ChannelB
  CP $03                  ; 2: channel B
  JR C,ChannelChosen
  LD IX,ChannelC          ; 3: channel C
ChannelChosen:
  LD HL,SoundTable             ; the sound's address: SoundTable + 2 x the sound
                          ; number
  LD A,C
  ADD A,A
  LD D,$00
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$1E),$01         ; active
  LD (IX+$1F),$01         ; the first command at the next frame
  XOR A
  LD (IX+$27),A           ; no transposition
  LD (MixerExtra),A       ; no extra mixer bits
  LD (IX+$21),E           ; the current pointer
  LD (IX+$22),D
  LD (IX+$23),E           ; the return pointer (CmdReturn's)
  LD (IX+$24),D
  LD (IX+$25),E           ; the start: CmdReturn at the top level starts the
                          ; sound again here
  LD (IX+$26),D
  RET

; stop all three channels, silence the AY
;
; All three records inactive (+$1E = 0), the volumes R8-R10 0, then on at
; SilenceAndSend (the mixer $3F, every register sent). An effect running is
; stopped too. 29 runs.
StopMusic:
  XOR A
  LD (ChannelAActive),A
  LD (ChannelBActive),A
  LD (ChannelCActive),A
  LD (AYVolumeA),A
  LD (AYVolumeB),A
  LD (AYVolumeC),A
  JP SilenceAndSend

; start the music: sounds $0B, $0C, $0D on channels A, B, C
;
; LastChannel = 3 (the CPC rip has $FF: StartSound's XOR 1 would then give $FE
; and $FF, both channel C, and channel B would get no music; the CPC register
; dump of cpc-power plays all three channels, so the rip's byte is not what
; that dump ran), then $0B on channel A (StartOnChannelA), $0C (3 XOR 1 = 2: B)
; and $0D (2 XOR 1 = 3: C) with StartSound; LastChannel ends 3, so the effects
; alternate B, C. Then SilenceAndSend. 6 runs.
StartMusic:
  LD A,$03
  LD (LastChannel),A
  LD A,$0B
  CALL StartOnChannelA
  LD A,$0C
  CALL StartSound
  LD A,$0D
  CALL StartSound
; This entry point is used by the routine at StopMusic.
SilenceAndSend:
  LD A,$3F                ; the mixer: tone and noise off on every channel
  LD (AYMixer),A

; write the register image R13 down to R0 to the AY
;
; A = 13, HL = AYEnvShape: OUT ($FFFD) the register number, OUTD ($BFFD) the
; value, down to R0 (AYToneA). R13 (the envelope shape, 0 throughout) is
; written every frame like the rest: no instrument here uses the hardware
; envelope. Output: A = $FF, HL = AYRegisters - 1. 10428 runs (PlayFrame's and
; the stops').
SendRegisters:
  LD A,$0D
  LD HL,AYEnvShape
  LD DE,$FFBF             ; D = $FF, E = $BF: the high bytes of the AY's ports
  LD C,$FD                ; C = $FD
SendNext:
  LD B,D                  ; $FFFD: the register number
  OUT (C),A
  LD B,E                  ; $BFFD: OUTD sends (HL) and moves HL down
  OUTD
  DEC A
  JP P,SendNext
  RET

; HL + 2 x C - $80 (the pitch envelope's step)
;
; Input: HL = the period, BC = the step byte (B = 0). HL + 2 x BC - $80 (- the
; carry); BC = $0080 on return, and PitchEnvelope subtracts it once more: the
; period moves by 2 x (step - $80). 9697 runs.
PitchStep:
  ADD HL,BC
  ADD HL,BC
  LD C,$80
  SBC HL,BC
  RET

; six bytes no instruction reads
;
; Zeros between PitchStep and PlayFrame: no instruction of the engine refers to
; them, and no run in c1 executed them.
Unused6:
  DEFB $00,$00,$00,$00,$00,$00
