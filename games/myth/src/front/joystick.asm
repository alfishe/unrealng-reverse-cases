; --------------------------------------------------------------------------------------------------------------------
; joystick.asm: SELECT JOYSTICK: KEMPSTON, CURSOR KEYS, SINCLAIR, LEAVE THIS MENU; the readers patched for each
;
; Recorded in joystick (work/stage2/rec/joystick: CURSOR, SINCLAIR, LEAVE, KEMPSTON in turn). SelectJoystick $97D8
; prints its four lines (JoystickText $A0D9: KEMPSTON, CURSOR KEYS, SINCLAIR, LEAVE THIS MENU on lines 68, 84, 100,
; 116, large font), then JoystickHighlight $9A3B runs the moving highlight over them (the menu's timing: 96 frames a
; line, starting on KEMPSTON) until SPACE. The lines are wiped, and for line 0-2 the five readers are patched:
; KEMPSTON reads port $1F with KeyXorMask $FF (a Kempston interface sets its bits for a pressed direction), bit 3 up,
; 2 down, 1 left, 0 right, 4 fire; SINCLAIR reads half row $EFFE: 9 up, 8 down, 6 left, 7 right, 0 fire; CURSOR KEYS 7
; up, 6 down, 5 left (half row $F7FE), 8 right, 0 fire. Each pair (ReaderPort $FE4D, ReaderBitOp $FE4C) goes to one
; reader through a Patch*Reader routine; KeyXorMask is 0 for both key layouts. LEAVE THIS MENU (line 3) changes
; nothing; every choice goes back to the menu.
; --------------------------------------------------------------------------------------------------------------------

  ORG $97D8

; SELECT JOYSTICK: the four choices, the highlight, wipe, patch the readers for
; the chosen one
;
; Reached from Menu $99A8 (JP Z at $99D7, line 2). MenuHook $980A, JoystickText
; $A0D9, JoystickHighlight $9A3B (E = the line taken), ClearTextLine with 68,
; 84, 100, 116, then E = 0 SetKempston $9834, 1 SetCursorKeys $989F, 2
; SetSinclair $986A, 3 BackToMenu.
;
; Witness: L1 4 (joystick).
SelectJoystick:
  CALL MenuHook
  CALL JoystickText
  CALL JoystickHighlight
  PUSH DE
  LD A,$44
  CALL ClearTextLine
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD A,$74
  CALL ClearTextLine
SelectJoystickChoice:
  POP DE                  ; E = the line: 0 KEMPSTON, 1 CURSOR KEYS, 2
                          ; SINCLAIR, 3 LEAVE
  LD A,E
  CP $00
  JP Z,SetKempston
  CP $01
  JP Z,SetCursorKeys
  CP $02
  JP Z,SetSinclair
; This entry point is used by the routines at DefineKeysLoop, SetKempston,
; SetSinclair and SetCursorKeys.
BackToMenu:
  JP Menu                 ; the menu again (from DEFINE KEYS, every joystick
                          ; choice and LEAVE THIS MENU)

; An empty routine: RET (called at the start of the menu, DEFINE KEYS and
; SELECT JOYSTICK)
;
; Called from Menu at $99AB, DefineKeys $971A and SelectJoystick $97D8 before
; anything else; does nothing. menu: 2 runs; c1: 1 (the front's bytes).
;
; Witness: L1 14 (c1, joystick, menu, rzx-r0).
MenuHook:
  RET

  ORG $9834

; KEMPSTON: port $1F, fire bit 4, up 3, down 2, right 0, left 1, KeyXorMask $FF
;
; ReaderPort = $001F, then (ReaderBitOp, reader): $67 FIRE, $5F UP, $57 DOWN,
; $47 RIGHT, $4F LEFT, each through its Patch*Reader; KeyXorMask $FCFA := $FF,
; so a set bit (the Kempston's pressed direction) reads as a pressed key (Z
; after BIT). Back to the menu.
;
; Witness: L1 1 (joystick).
SetKempston:
  LD HL,$001F
  LD (ReaderPort),HL
  LD A,$67
  LD (ReaderBitOp),A
  CALL PatchFireReader
  LD A,$5F
  LD (ReaderBitOp),A
  CALL PatchUpReader
  LD A,$57
  LD (ReaderBitOp),A
  CALL PatchDownReader
  LD A,$47
  LD (ReaderBitOp),A
  CALL PatchRightReader
  LD A,$4F
  LD (ReaderBitOp),A
  CALL PatchLeftReader
  LD A,$FF
  LD (KeyXorMask),A
  JP BackToMenu

; SINCLAIR: half row $EFFE, fire 0 (bit 0), up 9, down 8, right 7, left 6,
; KeyXorMask 0
;
; ReaderPort = $EFFE; $47 FIRE, $4F UP, $57 DOWN, $5F RIGHT, $67 LEFT;
; KeyXorMask := 0. Back to the menu.
;
; Witness: L1 1 (joystick).
SetSinclair:
  LD HL,$EFFE
  LD (ReaderPort),HL
  LD A,$47
  LD (ReaderBitOp),A
  CALL PatchFireReader
  LD A,$4F
  LD (ReaderBitOp),A
  CALL PatchUpReader
  LD A,$57
  LD (ReaderBitOp),A
  CALL PatchDownReader
  LD A,$5F
  LD (ReaderBitOp),A
  CALL PatchRightReader
  LD A,$67
  LD (ReaderBitOp),A
  CALL PatchLeftReader
  XOR A
  LD (KeyXorMask),A
  JP BackToMenu

; CURSOR KEYS: half row $EFFE for fire 0, up 7, down 6, right 8; $F7FE for left
; 5; KeyXorMask 0
;
; ReaderPort = $EFFE; $47 FIRE, $57 RIGHT, $5F UP, $67 DOWN; ReaderPort =
; $F7FE, LEFT with $67 still in ReaderBitOp (bit 4: the 5 key); KeyXorMask :=
; 0. Back to the menu.
;
; Witness: L1 1 (joystick).
SetCursorKeys:
  LD HL,$EFFE
  LD (ReaderPort),HL
  LD A,$47
  LD (ReaderBitOp),A
  CALL PatchFireReader
  LD A,$57
  LD (ReaderBitOp),A
  CALL PatchRightReader
  LD A,$5F
  LD (ReaderBitOp),A
  CALL PatchUpReader
  LD A,$67
  LD (ReaderBitOp),A
  CALL PatchDownReader
  LD HL,$F7FE
  LD (ReaderPort),HL
  CALL PatchLeftReader
  XOR A
  LD (KeyXorMask),A
  JP BackToMenu

; KeyFire's port := ReaderPort, its BIT opcode := ReaderBitOp
;
; Writes KeyFire+4/+5 and KeyFire+13.
;
; Witness: L1 3 (joystick).
PatchFireReader:
  LD HL,(ReaderPort)
  LD (KeyFire+4),HL
  LD A,(ReaderBitOp)
  LD (KeyFire+13),A
  RET

; KeyLeft's port and BIT opcode from ReaderPort and ReaderBitOp
;
; Writes KeyLeft+4/+5 and KeyLeft+13.
;
; Witness: L1 3 (joystick).
PatchLeftReader:
  LD HL,(ReaderPort)
  LD (KeyLeft+4),HL
  LD A,(ReaderBitOp)
  LD (KeyLeft+13),A
  RET

; KeyRight's port and BIT opcode from ReaderPort and ReaderBitOp
;
; Writes KeyRight+4/+5 and KeyRight+13.
;
; Witness: L1 3 (joystick).
PatchRightReader:
  LD HL,(ReaderPort)
  LD (KeyRight+4),HL
  LD A,(ReaderBitOp)
  LD (KeyRight+13),A
  RET

; KeyUp's port and BIT opcode from ReaderPort and ReaderBitOp
;
; Writes KeyUp+4/+5 and KeyUp+13.
;
; Witness: L1 3 (joystick).
PatchUpReader:
  LD HL,(ReaderPort)
  LD (KeyUp+4),HL
  LD A,(ReaderBitOp)
  LD (KeyUp+13),A
  RET

; KeyDown's port and BIT opcode from ReaderPort and ReaderBitOp
;
; Writes KeyDown+4/+5 and KeyDown+13.
;
; Witness: L1 3 (joystick).
PatchDownReader:
  LD HL,(ReaderPort)
  LD (KeyDown+4),HL
  LD A,(ReaderBitOp)
  LD (KeyDown+13),A
  RET

  ORG $9A3B

; The moving highlight over the 4 joystick lines until SPACE; E = the line
; taken
;
; As MenuHighlight $99E2 with 4 lines: the bar on row 8 + 2E (rows 8, 10, 12,
; 14: lines 68, 84, 100, 116), colours from JoystickBarColours $9A8C, E 0-3. 96
; frames a line, 384 a cycle, starting on KEMPSTON.
;
; Witness: L1 4 (joystick).
JoystickHighlight:
  LD E,$00
  LD D,$00
JoystickHighlightPass:
  PUSH BC                 ; two frames, the effects, the bar
  PUSH DE
  HALT
  HALT
  CALL ShimmerFrame
  CALL PaintBoxColours
  POP DE
  PUSH DE
  LD A,D
  AND $07
  LD C,A
  LD B,$00
  LD HL,JoystickBarColours
  ADD HL,BC
  LD A,(HL)
  LD (JoystickHighlightPass+$0029),A
  LD A,E
  SLA A
  ADD A,$08
  LD (JoystickHighlightPass+$0026),A
  CALL FillAttrBox
  DEFB $07,$0A,$12,$02,$00
JoystickHighlightStep:
  POP DE                  ; the next pass; 48 passes a line
  INC D
  LD A,D
  CP $30
  JP NZ,JoystickReadSpace
  LD D,$00
  INC E
  LD A,E
  CP $04
  JP NZ,JoystickReadSpace
  LD E,$00
JoystickReadSpace:
  LD BC,$7FFE             ; SPACE: the line E is taken
  IN A,(C)
  BIT 0,A
  JP Z,JoystickHighlightTaken
  POP BC
  JP JoystickHighlightPass
JoystickHighlightTaken:
  POP BC                  ; SPACE held: return with E
  RET

; The joystick bar's 8 colours: the same as MenuBarColours
;
; Read by JoystickHighlight $9A3B (index D AND 7). Not read in any recording.
JoystickBarColours:
  INCBIN "res/front/joystick-bar.bin",$0000,8

  ORG $A0D9

; The SELECT JOYSTICK lines: KEMPSTON, CURSOR KEYS, SINCLAIR, LEAVE THIS MENU
;
; Four PrintText calls, large font, lines 68, 84, 100, 116 (64 frames).
;
; Witness: L1 4 (joystick).
JoystickText:
  CALL PrintText

; PrintText: large font, byte 12, shift 2, line 68: KEMPSTON
TextKempston:
  INCBIN "res/front-texts/kempston.bin",$0000,13

; The second line
;
; JoystickText, continued.
;
; Witness: L1 4 (joystick).
JoystickText2:
  CALL PrintText

; PrintText: large font, byte 11, shift 1, line 84: CURSOR KEYS
TextCursorKeys:
  INCBIN "res/front-texts/cursor-keys.bin",$0000,16

; The third line
;
; JoystickText, continued.
;
; Witness: L1 4 (joystick).
JoystickText3:
  CALL PrintText

; PrintText: large font, byte 12, shift 6, line 100: SINCLAIR
TextSinclair:
  INCBIN "res/front-texts/sinclair.bin",$0000,13

; The fourth line
;
; JoystickText, continued.
;
; Witness: L1 4 (joystick).
JoystickText4:
  CALL PrintText

; PrintText: large font, byte 9, shift 6, line 116: LEAVE THIS MENU
TextLeaveThisMenu:
  INCBIN "res/front-texts/leave-this-menu.bin",$0000,20

; JoystickText's RET
;
; Witness: L1 4 (joystick).
JoystickTextDone:
  RET
