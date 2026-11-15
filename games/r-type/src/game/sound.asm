; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The beeper sound: three channels run by the interrupt tasks
; --------------------------------------------------------------------------------------------------------------------

; Start sound H with the channel bits L (the priority and the timbre)
;
; Witness: L1 13762 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
PlaySound:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH IY
  EX AF,AF'
  PUSH AF
  CALL SoundStart
  POP AF
  EX AF,AF'
  POP IY
  POP IX
  POP DE
  POP BC
  POP AF
  EI
  RET

; Find a channel at the priority, set its timbre and its script
;
; Witness: L1 13762 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
SoundStart:
  LD C,L
  LD A,H
  EX AF,AF'
  LD A,C
  LD B,$03
  AND B
  LD HL,SoundData+$006C
  CP B
  JR Z,l_F8B2
  LD A,(HL)
  AND A
  JR Z,l_F8B2
  DEC HL
  DEC HL
  DEC B
  LD A,(HL)
  AND A
  JR Z,l_F8B2
  DEC HL
  DEC HL
  DEC B
  LD A,(HL)
  AND A
  RET NZ
l_F8B2:
  DEC HL
  PUSH HL
  POP IX
  LD A,B
  DEC A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD HL,SoundTask1+$0009
  ADD A,L
  LD L,A
  JR NC,l_F8C4
  INC H
l_F8C4:
  LD (SoundTimbre+$0001),HL
  LD A,C
  AND $E0
  JR Z,l_F8E0
  LD HL,TimbreHigh
  CP $80
  JR Z,SoundTimbre
  LD HL,TimbreMid
  CP $40
  JR Z,SoundTimbre
  LD HL,TimbreLow
SoundTimbre:
  LD ($0000),HL           ; the store patched by SoundStart
l_F8E0:
  LD A,C
  AND $03
  LD C,A
  EX AF,AF'
  JP SoundSetScript

; Interrupt task 1: run channel 1's script
;
; Witness: L1 51349 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
SoundTask1:
  LD IX,SoundData+$0067
  LD IY,SoundTask1
  CALL TimbreHigh
  JR SoundStep

; bytes after the task
SoundTask1Tail:
  DEFB $00,$00,$00

; Interrupt task 2: run channel 2's script
;
; Witness: L1 51953 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
SoundTask2:
  LD IX,SoundData+$0069
  LD IY,SoundTask2
  CALL TimbreMid
  JR SoundStep

; bytes after the task
SoundTask2Tail:
  DEFB $00,$00,$00

; Interrupt task 3: run channel 3's script
;
; Witness: L1 53982 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
SoundTask3:
  LD IX,SoundData+$006B
  LD IY,SoundTask3
  CALL TimbreLow

; One step of a channel's script: a command byte and its routine (the table at
; $FBEB)
;
; Witness: L1 157284 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
SoundStep:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,H
  OR L
  RET Z
  XOR A
  RRD
  LD C,A
  RRD
  LD B,A
  RRD
  INC HL
  LD A,(HL)
  INC HL
  LD (IX+$00),L
  LD (IX+$01),H
  ADD A,A
  LD D,$00
  LD E,A
  LD HL,SoundData
  ADD HL,DE
  PUSH HL
  LD A,B
  ADD A,B
  LD E,A
  LD HL,SoundData+$0085
  ADD HL,DE
  SLA C
  POP DE
  LD B,(HL)
  INC HL
  LD H,(HL)
  LD L,B
  LD B,$00
  JP (HL)

; SoundEnd
SoundEnd:
  LD (IX+$00),$00         ; command: the script ends
  LD (IX+$01),$00
  SCF
  RET

; Timbre for PlaySound bits $80: note length shift 2, mask 3, noise bursts high
; byte >> 2
;
; Witness: L1 78715 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
TimbreHigh:
  LD A,$04
  LD (l_F9EB+$0007),A
  LD (l_FA83+$0001),A
  DEC A
  LD (l_F9F7+$0007),A
  DEC A
  LD (NotePeriod+$0001),A
  RET

; Timbre for bits $40: shift 3, mask 7
;
; Witness: L1 27852 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
TimbreMid:
  LD A,$02
  LD (l_F9EB+$0007),A
  LD (l_FA83+$0001),A
  DEC A
  LD (NotePeriod+$0001),A
  LD A,$07
  LD (l_F9F7+$0007),A
  RET

; Timbre for bits $20 (any other non-zero): shift 4, mask 15
;
; Witness: L1 50717 (boss, continue, deaths-l7, force, gameover, hiscore,
; hiscore-typed, restart, l1-l8).
TimbreLow:
  XOR A
  LD (l_F9EB+$0007),A
  LD (NotePeriod+$0001),A
  LD (l_FA83+$0001),A
  LD A,$0F
  LD (l_F9F7+$0007),A
  RET

; SoundCall
SoundCall:
  PUSH IY                 ; command 2 (Mark): keep the next step's place in
                          ; place p, run on at once

; Keep the script pointer
;
; Witness: L1 290 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; force, gameover, hiscore, hiscore-typed, pause, restart, l1-l7).
SoundPush:
  LD HL,SoundData+$006D
  ADD HL,BC
  LD D,(IX+$00)
  LD (HL),D
  INC HL
  LD D,(IX+$01)
  LD (HL),D

; SoundNop
SoundNop:
  XOR A                   ; XOR A, RET
  RET

; SoundReturn
;
; Used by the routine at SoundLoop.
SoundReturn:
  LD HL,SoundData+$006D   ; command 3 (Back): go to the place kept in p
  ADD HL,BC
  LD D,(HL)
  LD (IX+$00),D
  INC HL
  LD D,(HL)
  LD (IX+$01),D
SoundNext:
  JP (IY)                 ; JP (IY)

; SoundRepeat
SoundRepeat:
  CALL SoundPush          ; command: a repeat count
  LD L,(IX+$00)
  LD H,(IX+$01)
  DEC HL
  EX DE,HL
  LD HL,SoundData+$007D
  SRL C
  ADD HL,BC
  LD A,(DE)
SoundRepeatStore:
  LD (HL),A               ; store the count
  JP (IY)

; SoundLoop
SoundLoop:
  LD HL,SoundData+$007D   ; command: loop back while the count lasts
  SRL C
  ADD HL,BC
  SLA C
  DEC (HL)
  JR NZ,SoundReturn
  JP (IY)

; bytes of an unused command (known only from the code)
SoundCommandSpare:
  DEFB $CD,$87,$F9,$FD,$E5,$DD,$6E,$00
  DEFB $DD,$66,$01,$2B,$7E

; SoundSetScript
;
; Used by the routine at SoundStart.
SoundSetScript:
  ADD A,A                 ; the channel's script from the table
  LD C,A
  LD B,$00
  LD HL,SoundData+$00A5
  ADD HL,BC
  LD E,(HL)
SoundSetScriptB:
  INC HL                  ; the high byte
  LD D,(HL)
  LD (IX+$00),E
  LD (IX+$01),D
  XOR A
  RET

; DE = the period of a note
;
; Witness: L1 48828 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
NotePeriod:
  JR l_F9EB
  ADD A,A
  ADD A,A
l_F9EB:
  LD (l_F9F7+$000B),A
  LD E,(HL)
  INC HL
  LD A,(HL)
  JR l_F9F7
  SRL A
  SRL A
l_F9F7:
  SRL A
  SRL A
  LD D,A
  INC D
  LD A,$03
  AND (HL)
  DEC HL
  CP $00
  JR C,l_FA06
  INC D
l_FA06:
  XOR A
  RET

; Voices 1 and 2
;
; Witness: L1 3112 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
TonePair12:
  POP IX
  LD A,$01
  CALL NotePeriod
  PUSH DE
  LD A,$02
  CALL NotePeriod
  PUSH DE
  JP (IX)

; Voices 3 and 4
;
; Witness: L1 976 (boss, l1, l2).
TonePair34:
  POP IX
TonePair34A:
  LD A,$03                ; after the POP
  CALL NotePeriod
  PUSH DE
  LD A,$04
  CALL NotePeriod
TonePushLast:
  PUSH DE                 ; push and return
  JP (IX)

; Voices 1 and 2 sliding down
;
; Witness: L1 1965 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ToneDown12:
  POP IX
  LD A,$01
  CALL NotePeriod
  PUSH DE
  LD A,$02
  SBC HL,BC
  CALL NotePeriod
  PUSH DE
  JP (IX)

; Voices 3 and 4 sliding down
;
; Witness: L1 5077 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ToneDown34:
  POP IX
  LD A,$03
  SBC HL,BC
  CALL NotePeriod
  PUSH DE
  LD A,$04
  SBC HL,BC
  CALL NotePeriod
ToneDownLast:
  PUSH DE                 ; push and return
  JP (IX)

; Voices 1 and 2 sliding up
;
; Witness: L1 7130 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ToneUp12:
  POP IX
  LD A,$01
  CALL NotePeriod
  PUSH DE
  LD A,$02
  ADD HL,BC
  CALL NotePeriod
  PUSH DE
  JP (IX)

; Voices 3 and 4 sliding up
;
; Witness: L1 6154 (boss, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ToneUp34:
  POP IX
  LD A,$03
  ADD HL,BC
  CALL NotePeriod
  PUSH DE
  LD A,$04
  ADD HL,BC
  CALL NotePeriod
ToneUpLast:
  PUSH DE                 ; push and return
  JP (IX)

; NoiseBurst
NoiseBurst:
  LD A,C                  ; command: noise from the ROM's bytes through OUT
                          ; ($FE) at $FAA2
  AND A
  LD A,$F0
  JR NZ,l_FA79
  SUB $04
l_FA79:
  LD (l_FAA8+$0005),A
  EX DE,HL
  LD D,C
  LD E,$00
  LD B,(HL)
  INC HL
  LD C,(HL)
l_FA83:
  JR l_FA83
  SRL C
  SRL C
  SRL C
  SRL C
  LD HL,$00FF
  ADD HL,DE
  LD (l_FA83+$0018),HL
  LD A,(SoundData+$0062)
  AND $07
  LD D,A
  LD HL,$00FF
  LD E,B
l_FA9E:
  LD A,(HL)
  AND $F8
  OR D
  OUT ($FE),A
  DEC HL
  DJNZ l_FA9E
  LD B,E
l_FAA8:
  DJNZ l_FAA8
  LD B,E
  DEC C
  JR NZ,l_FA9E
  RET

; ChordPlay1
ChordPlay1:
  LD (SoundData+$0063),SP ; command: TonePair12 + ToneDown34
  LD SP,SoundStack+$0008
  EX DE,HL
  CALL TonePair12

; ChordPlay1B
ChordPlay1B:
  CALL ToneDown34         ; second half

; ChordPlay1C
ChordPlay1C:
  JR TonePlayer           ; to the player

; ChordPlay2
ChordPlay2:
  DEFB $ED,$73,$C9,$FB,$31,$7A,$F8,$EB ; command: TonePair12 + ToneUp34
  DEFB $CD,$08,$FA
ChordPlay2B:
  DEFB $CD,$5F,$FA        ; second half
ChordPlay2C:
  DEFB $18,$60            ; to the player

; ChordPlay3
ChordPlay3:
  LD (SoundData+$0063),SP ; command: ToneUp12 + TonePair34
  LD SP,SoundStack+$0008
  EX DE,HL
  CALL ToneUp12

; ChordPlay3B
ChordPlay3B:
  CALL TonePair34         ; second half

; ChordPlay3C
ChordPlay3C:
  JR TonePlayer           ; to the player

; ChordPlay4
ChordPlay4:
  DEFB $ED,$73,$C9,$FB,$31,$7A,$F8,$EB ; command: ToneDown12 + TonePair34
  DEFB $CD,$28,$FA
ChordPlay4B:
  DEFB $CD,$18,$FA        ; second half
ChordPlay4C:
  DEFB $18,$40            ; to the player

; ChordPlay5
ChordPlay5:
  LD (SoundData+$0063),SP ; command: ToneDown12 + ToneDown34
  LD SP,SoundStack+$0008
  EX DE,HL
  CALL ToneDown12

; ChordPlay5B
ChordPlay5B:
  CALL ToneDown34         ; second half

; ChordPlay5C
ChordPlay5C:
  JR TonePlayer           ; to the player

; ChordPlay6
ChordPlay6:
  LD (SoundData+$0063),SP ; command: ToneUp12 + ToneUp34
ChordPlay6B:
  LD SP,SoundStack+$0008  ; the SP set
  EX DE,HL
  CALL ToneUp12

; ChordPlay6C
ChordPlay6C:
  CALL ToneUp34           ; second half

; ChordPlay6D
ChordPlay6D:
  JR TonePlayer           ; to the player

; bytes no recording reads (known only from the code)
SoundCommandsSpare:
  DEFB $ED,$73,$C9,$FB,$31,$7A,$F8,$EB
  DEFB $CD,$4E,$FA,$CD,$3A,$FA,$18,$10
  DEFB $ED,$73,$C9,$FB,$31,$7A,$F8,$EB
  DEFB $CD,$28,$FA,$CD,$5F,$FA,$18,$00

; TonePlayer
;
; Used by the routines at ChordPlay1C, ChordPlay3C, ChordPlay5C and
; ChordPlay6D.
TonePlayer:
  LD HL,SoundStack        ; play the pushed periods as one tone: OUT ($FE) at
                          ; $FB52
  LD SP,(SoundData+$0063)
  LD A,(SoundData+$0062)
  JP TonePlayerNext
TonePlayerLoop:
  JP l_FB3F               ; the delay chain
l_FB3F:
  JP l_FB42
l_FB42:
  JP TonePlayerPeriod
TonePlayerPeriod:
  LD E,D                  ; one period
  JR l_FB48
l_FB48:
  JR l_FB4A
l_FB4A:
  JR l_FB4C
l_FB4C:
  JR l_FB4E
l_FB4E:
  ADD A,$00
  XOR $10
  OUT ($FE),A
l_FB54:
  DEC E
  JP l_FB58
l_FB58:
  JR NZ,l_FB54
  DJNZ TonePlayerLoop
TonePlayerNext:
  LD D,(HL)               ; the next voice pair
  INC L
  LD B,(HL)
  INC L
  DJNZ TonePlayerPeriod
  LD (SoundData+$0062),A
  RET

; The sound data: note periods, the channel slots, the command table ($FBEB),
; the script table ($FC0B)
;
; The script table at $FC0B holds 35 words, sounds $00-$22. By the code that
; starts them (the run counts of the starting instruction over all recordings):
; $00 silence (Silence, CommandWave); $01 shot (ShotSound, 3940 runs); $02 beam
; charging (FireBeam, 90); $03 a level 8 wave sound (wave command 6 at columns
; 35, 41, 48); $04 enemy hit (EnemyHit, 2492); $05 beam released (BeamRelease,
; 143); $06 missiles (FireMissiles, 482); $08 small explosion, $0A middle
; explosion, $09 big explosion (AwardScore by the enemy's size with bits $82,
; the first free channel, TimbreHigh: size $10 to $08, $40 to $0A, $20 and $30
; to $09;, 1377/848/747; BossDestroyed's $09 or $0A never ran); $09 also the
; ship hit (ShipDies, 38); $0A also a life lost (LoseLife, 37) and the level 7
; wave sound (columns 73-74, 94); $0B a key defined (DefineKeys, DefineKey:
; never ran); $0C the best pilots table entered (InsertHiScore, 10); $0D
; pick-up (TakePickup, 20); $0E extra life (ExtraLifeSound, 6); $0F a soft cell
; hit (ProcessHitsNext, 717); $10-$13 the level 2 wave sounds (columns 31-90:
; the boss's beat); $14 the Force docks (ForceDraw 1; ShieldControls never
; ran); $15 the level's end tune (LevelEnd, 8); $16 the name entered
; (InsertHiScore, 1); $18 a shot bounced off the scenery (BounceShot, 1576: one
; Chord1 step at about 1900 Hz, bits $41; it shares its script $5BD0 with the
; unused $17); $19, $1D, $1E the control method chosen (SelectControl, 3 each);
; $1A, $1B mission over (MissionOver, 4 each); $1C the Force on the ground
; (ForceGround, 507); $22 the CONTINUE count (Continue, 21).
;
; Sounds $07, $17 (the same script as $18) and $1F-$21 are started by no code
; and no wave script: known only from the table. $15-$1E have their scripts at
; $5B64-$5CFF, $1F-$21 at $F168-$F35C inside the level space (whatever the
; loaded level holds there), $22 at $72E8.
;
; The command table at $FBEB: 16 words: 0 End, 1 Rest (SoundNop), 2 Mark, 3
; Back, 4 Repeat, 5 Loop, 6 spare bytes $F9C7, 7 Noise, 8-13 Chord1-6, 14-15
; spare chord variants $FB0F/$FB1F (no script uses them).
SoundData:
  INCBIN "res/sound/sound-data.bin",$0000,310

; the sound scripts
SoundScripts:
  INCBIN "res/sound/sound-scripts.bin",$0000,259

; bytes no recording reads
SoundScriptsEnd:
  DEFB $C6,$24,$C6,$30,$00,$00
