; --------------------------------------------------------------------------------------------------------------------
; wavescript.asm: the wave script VM: the level's timeline of waves, scroll stops and checkpoints
;
; Each level is a script (the twelve at $6B8D-$72A4, F5's data) run by WaveScriptStep once a frame of play: at the
; interrupt's phase 2 ($AA96) and only while the player is alive (DeathTimer $7F7B = $FF; the death count-down stops
; the timeline). The state is 35 bytes at ScriptState $81D7: +1 the PC ($81D8), +3 the scroll flags ($81DA, bit 5 the
; scroll runs, bit 7 a mode flag), +4 the replay count ($81DB, the columns LevelStart scrolls through at a restart),
; +8 the call stack pointer ($81DF, growing down from $81F6), +$0A the wait counter ($81E1), +$0B the saved flags
; ($81E2), +$0C a flag ($81E3). The player record keeps a copy at +$0D (the checkpoint), and RestoreCheckpoint brings
; it back at each level start.
;
; An instruction is a delay byte and an opcode. The wait counter counts frames up to the delay; then the opcode runs
; and the next instruction is looked at in the same frame (so a run of delay-0 instructions runs at once). Opcodes
; $00-$3F: a command through ScriptCommands ($81FF, 18 words); $40-$7F: a jump on the condition opcode & $3F to the
; following word; $80-$BF: a wave: LaunchWave $91EC with A = opcode & $3F and B = the following byte (C = $C0);
; $C0-$FF: a call on the condition to the following word (the return address pushed on the script stack).
;
; The conditions (ScriptConditions $8223, 7 words) test the flags of the last word command, kept in $81E2 and taken
; into AF': 0 always, 1 Z, 2 NZ, 3 C, 4 NC, 5 P, 6 M. The commands: 0 nothing, 1 $81E3 = $FF, 2 the scroll stops, 3/4
; set/clear bit 7 of the scroll flags, 5 the level is done (EndPending = 2), 6 nothing, 7 store a word, 8 copy a word,
; 9 decrement a word, 10 increment a word, 11 test a word, 12 add to a word, 13 return, 14 the checkpoint, 15 reset
; the 18 records at $F12C, 16 let the first enemy escape (EnemyEscaped, FreeEnemySlot), 17 test for living enemies.
;
; What the twelve scripts use (work/f4/vmwalk.py, a walk of every path from the twelve level entries: 491 instructions
; cover $6B8D-$72A4 but for the two bytes $FF $00 after each script's level end): 204 waves, 80 stores and 65
; decrements of the counter at $81E4, 80 jumps all on NZ (the loops 'repeat n times' and 'wait while enemies live'),
; 15 enemy tests (17), 11 checkpoints (14), 9 scroll stops (2), 8 record resets (15), 5 escapes (16), 12 level ends
; (5), 2 nops. Never used: commands 1, 3, 4, 6, 8, 10, 11, 12, 13, the conditions other than NZ and every call opcode.
; Their handlers are code no recording ran. r1 (75001 frames, 11 level ends) agrees: it ran the handlers of commands
; 0, 2, 5, 7, 9, 14, 15, 16 and 17 and no other (WaveScriptStep 9138 entries).
; --------------------------------------------------------------------------------------------------------------------

; one frame of the level's script
;
; Called from the play interrupt at phase 2 ($AA96; c2: 165 entries in 165
; frames), returns at once unless DeathTimer ($7F7B) is $FF. When the wait
; counter ($81E1) equals the delay byte at the PC ($81D8): the counter is
; zeroed, the opcode is read and run, and the next instruction is looked at at
; once; else the counter + 1 and return. Callees: JumpTable $91E2 (commands),
; LaunchWave $91EC (waves), ScriptWord, ScriptByte, ScriptTest.
WaveScriptStep:
  LD A,(DeathTimer)
  INC A                   ; $FF + 1 = 0: alive
  RET NZ
ScriptNext:
  LD A,(ScriptWaitCount)  ; the wait counter against this instruction's delay
  LD HL,(ScriptPC)
  CP (HL)
  JP NZ,ScriptWait
  XOR A                   ; the delay is over: the counter from 0 for the next
                          ; one
  LD (ScriptWaitCount),A
  INC HL                  ; the opcode after the delay byte
  LD A,(HL)
  INC HL
  LD (ScriptPC),HL
  CP $40                  ; $00-$3F: a command
  JR NC,ScriptDecode
  LD HL,ScriptCommands    ; ScriptCommands, jump-by-index
  CALL JumpTable
  JR ScriptNext           ; and the next instruction in the same frame
ScriptWait:
  INC A                   ; one frame more
  LD (ScriptWaitCount),A
  RET
ScriptDecode:
  CP $80                  ; $40-$7F: a jump
  JR C,ScriptJump
  CP $C0                  ; $80-$BF: a wave
  JR C,ScriptWave
  CALL ScriptWord         ; $C0-$FF: a call: DE = the target
  AND $3F
  CALL ScriptTest         ; the condition (opcode & $3F) false: NC
  JR NC,ScriptNext
  LD BC,(ScriptPC)        ; the return address on the script stack ($81DF,
                          ; growing down)
  LD HL,(ScriptStackPtr)
  DEC HL
  LD (HL),B
  DEC HL
  LD (HL),C
  LD (ScriptStackPtr),HL
  LD (ScriptPC),DE        ; PC = the target
  JR ScriptNext
ScriptJump:
  CALL ScriptWord         ; DE = the target
  AND $3F
  CALL ScriptTest         ; the condition false: on with the next instruction
  JR NC,ScriptNext
  LD (ScriptPC),DE
  JR ScriptNext
ScriptWave:
  AND $3F                 ; A = the wave's kind, C = the following byte
  CALL ScriptByte
  LD B,C                  ; B = the byte, C = $C0
  LD C,$C0
  CALL LaunchWave         ; LaunchWave
  JR ScriptNext

; keep F of the last word command for the conditions
;
; PUSH AF / POP HL takes F into L, stored in ScriptFlags $81E2 (the conditions
; read $81E2/$81E3 as an AF pair). Called by the word commands 9-12 and 17.
ScriptSaveFlags:
  PUSH HL
  PUSH AF
  POP HL
  LD A,L
  LD (ScriptFlags),A
  POP HL
  RET

; DE = the next word of the script
;
; Reads the word at the PC ($81D8) and steps the PC past it; HL kept.
ScriptWord:
  PUSH HL
  LD HL,(ScriptPC)
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ScriptPC),HL
  POP HL
  RET

; C = the next byte of the script
;
; Reads the byte at the PC and steps it; HL kept.
ScriptByte:
  PUSH HL
  LD HL,(ScriptPC)
  LD C,(HL)
  INC HL
  LD (ScriptPC),HL
  POP HL
  RET

; carry when the condition A holds
;
; In: A the condition (0-6). Out: carry when it holds; A, BC, DE, HL kept (A is
; the condition again). The saved flags $81E2/$81E3 are loaded into AF' and the
; test routine (ScriptConditions $8223 through $91E2) takes them with EX
; AF,AF'.
ScriptTest:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,A
  PUSH BC
  LD HL,(ScriptFlags)     ; ScriptFlags and $81E3 as AF
  PUSH HL
  EX AF,AF'               ; into AF' for the test routine
  POP AF
  EX AF,AF'
  LD HL,ScriptConditions  ; ScriptConditions, jump-by-index
  CALL JumpTable
  POP BC
  LD A,C
  POP BC
  POP DE
  POP HL
  RET

; condition 0: always (SCF)
CondAlways:
  SCF
  RET

; condition 1: Z of the saved flags
CondZero:
  EX AF,AF'
  SCF
  RET Z
  CCF
  RET

; condition 2: NZ of the saved flags (the only one the scripts use)
CondNonZero:
  EX AF,AF'
  SCF
  RET NZ
  CCF
  RET

; condition 5: P of the saved flags
CondPositive:
  EX AF,AF'
  SCF
  RET P
  CCF
  RET

; condition 6: M of the saved flags
CondNegative:
  EX AF,AF'
  SCF
  RET M
  CCF
  RET

; condition 3: the saved carry
CondCarry:
  EX AF,AF'
  RET

; condition 4: the saved carry inverted
CondNoCarry:
  EX AF,AF'
  CCF
  RET

; command 0: nothing (2 uses)
CmdNop:
  RET

; command 1: $81E3 = $FF (never used by the scripts)
;
; $81E3 is the byte after ScriptFlags, so it is A of the AF pair the conditions
; load; SetLevelStart zeroes it.
CmdSetFlag:
  LD A,$FF
  LD (ScrollRestart),A
  RET

; command 2: the scroll stops (bit 5 of $81DA cleared; 9 uses)
;
; Also called by CmdLevelEnd. The scroll ($8AED area) runs while bit 5 is set;
; a level's guardian section stops it.
CmdScrollStop:
  LD HL,PlayFlags
  RES 5,(HL)
  RET

; command 3: bit 7 of the scroll flags $81DA set (never used)
CmdModeOn:
  LD HL,PlayFlags
  SET 7,(HL)
  RET

; command 4: bit 7 of the scroll flags cleared (never used)
CmdModeOff:
  LD HL,PlayFlags
  RES 7,(HL)
  RET

; command 5: the level is done
;
; The scroll stops, EndPending ($7F7C) = 2 (the play loop ends with code 2:
; LevelDone $B174 moves to the next level), the player record's +8 and +9
; zeroed (the side weapon and the double plasma do not go on to the next
; level). The last instruction of all twelve scripts.
CmdLevelEnd:
  CALL CmdScrollStop
  LD A,$02
  LD (EndPending),A
  LD IX,(PlayerRecord)
  XOR A
  LD (IX+$08),A
  LD (IX+$09),A
  RET

; command 6: nothing (never used)
CmdNop2:
  RET

; command 7: (word 1) = word 2 (80 uses, all on the counter $81E4)
CmdStore:
  CALL ScriptWord
  EX DE,HL
  CALL ScriptWord
  LD (HL),E
  INC HL
  LD (HL),D
  RET

; command 8: (word 1) = (word 2) (never used)
CmdCopy:
  CALL ScriptWord
  EX DE,HL
  CALL ScriptWord
  EX DE,HL
  LDI
  LDI
  RET

; command 9: (word) - 1, the flags kept for the conditions (65 uses)
;
; The word is read, ADC HL,DE with HL = $FFFF gives word - 1 with Z when it
; reaches 0 (and carry unless it was 0); the flags go to ScriptFlags. With a
; following 'jump NZ' it is the loop 'repeat n times'.
CmdDecrement:
  CALL ScriptWord
  EX DE,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH HL
  LD HL,ColumnFlags+$001F
  AND A
  ADC HL,DE
  EX DE,HL
  POP HL
  LD (HL),D
  DEC HL
  LD (HL),E
  CALL ScriptSaveFlags
  RET

; command 10: (word) + 1, the flags kept (never used)
CmdIncrement:
  CALL ScriptWord
  EX DE,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH HL
  LD HL,$0001
  AND A
  ADC HL,DE
  EX DE,HL
  POP HL
  LD (HL),D
  DEC HL
  LD (HL),E
  CALL ScriptSaveFlags
  RET

; command 11: the flags of (word) (0 + word with ADC; never used)
CmdTest:
  CALL ScriptWord
  EX DE,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,$0000
  AND A
  ADC HL,DE
  CALL ScriptSaveFlags
  RET

; command 12: the flags of (word 1) + word 2 (never used)
;
; It keeps the flags of the sum but stores word 2 itself, not the sum (LD
; (HL),E / LD (HL),D after POP HL): a command no script uses, so the slip never
; shows.
CmdAdd:
  CALL ScriptWord
  EX DE,HL
  PUSH HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  CALL ScriptWord
  AND A
  ADC HL,DE
  CALL ScriptSaveFlags
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  RET

; command 13: return from a script call (never used)
CmdReturn:
  LD HL,(ScriptStackPtr)
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ScriptStackPtr),HL
  LD (ScriptPC),DE
  RET

; command 14: the checkpoint (11 uses)
;
; Copies the VM state $81D7-$81F9 (35 bytes, PC past this instruction) to the
; player record's +$0D: a lost life restarts the level here (RestoreCheckpoint,
; then LevelStart replays the scroll count). Measured (work/f4/invuln.py):
; level 0's checkpoint moved from $6B8D (replay $40) to $6BC4 with the replay
; count $122 between frames 1000 and 2000; with no checkpoint passed a death
; restarted the script at $6B8D.
CmdCheckpoint:
  LD HL,(PlayerRecord)
  LD DE,$000D
  ADD HL,DE
  EX DE,HL
  LD HL,ScriptState
  LD BC,$0023
  LDIR
  RET

; command 15: reset the 18 records of 32 bytes at $F12C (8 uses)
;
; For each record: +8 = 0, +6/+7 = $85E4; then of the 32 bytes below its
; pointer (+0/+1) every one whose byte $40 higher is 0 is cleared. F6's buffers
; at $F12C; the pointers lead into the map work space.
CmdResetRecords:
  LD IX,RowRecords
  LD B,$12
  LD DE,$0020
  LD HL,SentinelNode
ResetRecord:
  LD (IX+$08),$00         ; +8 = 0, +6/+7 = $85E4
  LD (IX+$06),L
  LD (IX+$07),H
  EXX
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD A,E
  ADD A,$40
  LD L,A
  LD H,D
  XOR A
  LD B,$20
ResetRecordByte:
  CP (HL)                 ; the byte $40 above is 0: clear this one
  JR NZ,ResetRecordNext
  LD (DE),A
ResetRecordNext:
  DEC L
  DEC E
  DJNZ ResetRecordByte
  EXX
  ADD IX,DE
  DJNZ ResetRecord
  RET

; command 16: when the enemy record $F398 is active, EnemyEscaped $994A and
; FreeEnemySlot $992A (5 uses)
CmdEnemyEscape:
  LD IY,EnemyObjects
  BIT 7,(IY+$08)
  RET Z
  CALL EnemyEscaped
  CALL FreeEnemySlot
  RET

; command 17: NZ while one of the five enemies at $F398 lives (15 uses)
;
; A record counts when +8 has bits 5 and 7 set and +$0D is not $FF. The flags
; go to ScriptFlags: the script's 'jump NZ' back waits for the wave to be shot
; down.
CmdEnemiesLeft:
  LD IX,EnemyObjects
  LD DE,$002C
  LD B,$05
EnemiesLeftNext:
  LD A,(IX+$08)           ; bits 5 and 7 of +8: a live enemy
  BIT 5,A
  JR Z,EnemiesLeftSkip
  BIT 7,A
  JR Z,EnemiesLeftSkip
  LD A,(IX+$0D)
  INC A
  JR NZ,EnemiesLeftDone
EnemiesLeftSkip:
  ADD IX,DE
  DJNZ EnemiesLeftNext
  XOR A
EnemiesLeftDone:
  CALL ScriptSaveFlags    ; NZ: one found, Z: none
  RET
