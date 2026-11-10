; --------------------------------------------------------------------------------------------------------------------
; input.asm: Reading the controls
; --------------------------------------------------------------------------------------------------------------------

; Read the keyboard, the cursor keys or the Kempston joystick into Controls
;
; Called by the interrupt handler every frame (L1 54 811). Clears bits 0-4 of
; Controls and sets them from the method in bits 7-6: Kempston (0): IN ($1F)
; AND $1F (L1 47 334); the keyboard ($80): on the bottom row Z C M B left and X
; V N SYMBOL SHIFT right (every other key), A-G and H-L down, Q-T and Y-P up,
; 1-5 and 6-0 fire (2 138); the cursor keys ($40): 5 left, 6 down, 7 up, 8
; right, 0 fire (5 339). Bit 0 right, 1 left, 2 down, 3 up, 4 fire.
ReadControls:
  LD HL,Controls
  LD A,(HL)
  AND $E0
  LD (HL),A
  BIT 7,A
  JR NZ,ReadKeyboard
  BIT 6,A
  JP NZ,ReadCursor
  IN A,($1F)
  AND $1F
  OR (HL)
  LD (HL),A
  RET
ReadKeyboard:
  LD BC,$FEFE
  IN A,(C)
  BIT 1,A
  JR NZ,ReadKeyboardX
  SET 1,(HL)
ReadKeyboardX:
  BIT 2,A
  JR NZ,ReadKeyboardC
  SET 0,(HL)
ReadKeyboardC:
  BIT 3,A
  JR NZ,ReadKeyboardV
  SET 1,(HL)
ReadKeyboardV:
  BIT 4,A
  JR NZ,ReadKeyboardRow7F
  SET 0,(HL)
ReadKeyboardRow7F:
  LD B,$7F
  IN A,(C)
  BIT 1,A
  JR NZ,ReadKeyboardM
  SET 0,(HL)
ReadKeyboardM:
  BIT 2,A
  JR NZ,ReadKeyboardN
  SET 1,(HL)
ReadKeyboardN:
  BIT 3,A
  JR NZ,ReadKeyboardB
  SET 0,(HL)
ReadKeyboardB:
  BIT 4,A
  JR NZ,ReadKeyboardAG
  SET 1,(HL)
ReadKeyboardAG:
  LD B,$FD
  IN A,(C)
  AND $1F
  CP $1F
  JR Z,ReadKeyboardHL
  SET 2,(HL)
ReadKeyboardHL:
  LD B,$BF
  IN A,(C)
  AND $1E
  CP $1E
  JR Z,ReadKeyboardUp
  SET 2,(HL)
ReadKeyboardUp:
  LD B,$DB
  IN A,(C)
  AND $1F
  CP $1F
  JR Z,ReadKeyboardFire
  SET 3,(HL)
ReadKeyboardFire:
  LD B,$E7
  IN A,(C)
  AND $1F
  CP $1F
  RET Z
  SET 4,(HL)
  RET
ReadCursor:
  LD BC,$F7FE
  IN A,(C)
  BIT 4,A
  JR NZ,ReadCursorRow
  SET 1,(HL)
ReadCursorRow:
  LD B,$EF
  IN A,(C)
  BIT 4,A
  JR NZ,ReadCursor7
  SET 2,(HL)
ReadCursor7:
  BIT 3,A
  JR NZ,ReadCursor8
  SET 3,(HL)
ReadCursor8:
  BIT 2,A
  JR NZ,ReadCursor0
  SET 0,(HL)
ReadCursor0:
  BIT 0,A
  RET NZ
  SET 4,(HL)
  RET
