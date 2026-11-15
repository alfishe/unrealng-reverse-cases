; --------------------------------------------------------------------------------------------------------------------
; controls.asm: The controls: the tutor's input script in place of the keys, the pause
; --------------------------------------------------------------------------------------------------------------------

; NZ unless the script presses fire (TutorInput bit 0); part 1's KeyFire
;
; Witness: L1 13080 (d1, demo-cycle).
TutorKeyFire:
  LD HL,Temp1
  CALL TutorRead
  BIT 0,(HL)
  RET

; The script's left (bit 4)
;
; Witness: L1 6559 (d1, demo-cycle).
TutorKeyLeft:
  LD HL,Temp1
  CALL TutorRead
  BIT 4,(HL)
  RET

; The script's right (bit 3)
;
; Witness: L1 6562 (d1, demo-cycle).
TutorKeyRight:
  LD HL,Temp1
  CALL TutorRead
  BIT 3,(HL)
  RET

; The script's up (bit 1): the jump
;
; Witness: L1 6540 (d1, demo-cycle).
TutorKeyUp:
  LD HL,Temp1
  CALL TutorRead
  BIT 1,(HL)
  RET

; The script's down (bit 2): the shield
;
; Witness: L1 13492 (d1, demo-cycle).
TutorKeyShield:
  LD HL,Temp1
  CALL TutorRead
  BIT 2,(HL)
  RET

; TutorInput $6079 into Temp1 (the key tests read it there)
;
; Witness: L1 46233 (d1, demo-cycle).
TutorRead:
  LD A,(TutorInput)
  LD (HL),A
  RET

; Each pass: the script's count down; at 0 the next [input][count] pair;
; between pairs TutorInput $FF (nothing)
;
; Witness: L1 6746 (d1, demo-cycle).
TutorStep:
  LD A,(TutorCount)
  DEC A
  LD (TutorCount),A
  OR A
  JP NZ,l_9FA7
  LD HL,(TutorScriptPtr)
  INC HL
  LD A,(HL)
  LD (TutorInput),A
  LD HL,(TutorScriptPtr)
  INC HL
  INC HL
  LD A,(HL)
  LD (TutorCount),A
  LD HL,(TutorScriptPtr)
  INC HL
  INC HL
  LD (TutorScriptPtr),HL
  RET
l_9FA7:
  LD A,$FF
  LD (TutorInput),A
  RET

; SPACE: the sound off; wait for SPACE up, then down again; the sound on
;
; Witness: L1 1 (demo-cycle).
DemoPause:
  CALL SoundSilence
DemoPauseUp:
  LD BC,$7FFE             ; wait while SPACE is held
  IN A,(C)
  BIT 0,A
  JP Z,DemoPauseUp
DemoPauseDown:
  LD BC,$7FFE             ; wait for SPACE pressed again
  IN A,(C)
  BIT 0,A
  JP NZ,DemoPauseDown
  CALL SoundReset
  RET

; OR the 8 bytes at DE into the buffer at HL (32-byte rows)
;
; As REX 1's OrChar $A4F4 (src/game/controls.asm).
;
; Witness: L1 3024 (d1, demo-cycle).
OrChar:
  LD B,$08
OrCharLoop:
  LD A,(DE)               ; each line
  OR (HL)
  LD (HL),A
  INC DE
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ OrCharLoop
  RET
