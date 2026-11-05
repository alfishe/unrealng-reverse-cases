; --------------------------------------------------------------------------------------------------------------------
; input.asm: The controls: keys, Kempston and Sinclair or cursor joystick
;
; ReadControls reads the five defined keys and one joystick into the control bits $8186 (bit 0 right, 1 left, 2 down,
; 3 up, the Kempston order) and the fire counters $8184 (passes fire has been held, 0 when released) and $8185 ($FF in
; a pass fire changed).
;
; The joystick is the Kempston (port $1F) when $8187 bit 0 is set (TitleFireCheck sets it when the title is left with
; Kempston fire), otherwise the keys 5-0, read as the cursor joystick (5 left, 6 down, 7 up, 8 right, 0 fire) or the
; Sinclair joystick (6 left, 7 right, 8 down, 9 up, 0 fire). 9 selects Sinclair (sticky in $8187 bit 1), 5 goes back
; to cursor.
; --------------------------------------------------------------------------------------------------------------------

; Read the controls into $8184-$8186
;
; C collects the five keys of $8188 (fire into bit 4, then up, down, left,
; right), ORed with the joystick bits. $8184 counts the passes fire is held,
; $8185 = $FF when fire was pressed or released since the last read, $8186 the
; direction bits (fire removed). Registers kept.
;
; Callers: the player mover (PlayerHandler) and HighScoreEntry. Evidence: the
; bits and counters seen in c2 while the bot plays.
ReadControls:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,$00                ; five keys, the first into bit 4
  LD B,$05
  LD HL,KeyTable
ControlsKeyLoop:
  LD A,(HL)
  INC HL
  IN A,($FE)
  AND (HL)
  CP $01                  ; pressed (0): carry
  RL C
  INC HL
  DJNZ ControlsKeyLoop
  LD HL,JoystickFlags     ; the joystick flags
  BIT 0,(HL)
  JR Z,ControlsKeys56789
  IN A,($1F)              ; Kempston: fire bit 4, up 3, down 2, left 1, right 0
  AND $1F
  SET 0,(HL)
  JR ControlsMerge
ControlsKeys56789:
  LD A,$EF                ; the keys 6-0 and 1-5 rows
  IN A,($FE)
  CPL
  AND $1F
  LD E,A
  LD A,$F7
  IN A,($FE)
  BIT 1,E                 ; 9: the Sinclair joystick
  JR NZ,ControlsSinclair
  BIT 1,(HL)
  JR NZ,ControlsSinclair
ControlsCursor:
  RES 1,(HL)              ; cursor keys
  BIT 4,A                 ; 5: left
  JR NZ,ControlsCursorFire
  SET 1,B
ControlsCursorFire:
  LD A,E                  ; 0: fire
  RRCA
  JR NC,ControlsCursorRight
  SET 4,B
ControlsCursorRight:
  RRCA                    ; 8: right
  RRCA
  JR NC,ControlsCursorUp
  INC B
ControlsCursorUp:
  RRCA                    ; 7: up
  JR NC,ControlsCursorDown
  SET 3,B
ControlsCursorDown:
  RRCA                    ; 6: down
  JR NC,ControlsCursorDone
  SET 2,B
ControlsCursorDone:
  LD A,B
  JR ControlsMerge
ControlsSinclair:
  BIT 4,A                 ; 5 down: back to cursor
  JR Z,ControlsCursor
  SET 1,(HL)              ; Sinclair from now on
  XOR A                   ; fire, up, down out of bits 0-2 into bits 4-2
  SRL E
  RLA
  SRL E
  RLA
  SRL E
  RLA
  RLCA
  RLCA
  OR E                    ; left and right are left in E bits 1-0
ControlsMerge:
  OR C
  LD C,A
  LD HL,FireHeld          ; the fire counter
  LD A,(HL)
  LD E,A
  INC A
  BIT 4,C                 ; fire held: count, released: 0
  JR NZ,ControlsFireCount
  XOR A
ControlsFireCount:
  LD (HL),A
  RES 4,C
  LD D,A                  ; $8185 = (held now) XOR (held before)
  XOR A
  CP D
  SBC A,A
  LD D,A
  XOR A
  CP E
  SBC A,A
  XOR D
  LD (FireChanged),A
  LD HL,ControlBits
  LD (HL),C
  POP BC
  POP DE
  POP HL
  POP AF
  RET

; Is fire pressed on the title screen? Also picks the Kempston
;
; Carry set when the Kempston reads exactly fire ($10: then $8187 bit 0 stays
; set and the game uses the Kempston), or, with the Kempston flag cleared, when
; the fire key ($8188) or 0 is down. Callers: HighScoreEntry and the title loop
; (CreditsPage, HiScorePage, Pause, TitleTune).
TitleFireCheck:
  PUSH HL
  LD HL,JoystickFlags
  SET 0,(HL)
  IN A,($1F)              ; the Kempston fire alone
  AND $1F
  CP $10
  JR Z,TitleFireYes
  RES 0,(HL)              ; not the Kempston
  LD HL,KeyTable
  LD A,(HL)
  INC HL
  IN A,($FE)
  AND (HL)
  JR Z,TitleFireYes
  LD A,$EF                ; or 0
  IN A,($FE)
  RRA
  JR NC,TitleFireYes
  AND A                   ; no fire: no carry
  POP HL
  RET
TitleFireYes:
  SCF
  POP HL
  RET
