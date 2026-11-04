; ReadControls; while key 1 (Input bit 7) is held, the pause: wait for another
; key
;
; Used by the routines at PlayLoop, DirectControl, DistanceSelect, ListMenu,
; WaitRelease, GameOverWait, FindNearestOpponent and ConstructionMenuLoop.
WaitKey:
  CALL ReadControls
  OR A
  RET P
PauseLoop:
  CALL ReadControls       ; key 1 held: wait for another control
  OR A
  JR Z,PauseLoop
  JP M,PauseLoop

; Input from the redefinable keys (KeyTable) or the joystick the menu chose
; (Controls)
;
; Used by the routine at WaitKey.
ReadControls:
  LD HL,KeyTable
  LD C,$01                ; C = 1: the end marker, shifted out after 8 keys
KeyLoop:
  LD A,(HL)               ; IN from the key's half row
  INC HL
  IN A,($FE)
  AND (HL)                ; Z: pressed
  INC HL
  INC HL
  JR NZ,KeyShift
  CCF                     ; pressed: carry 1
KeyShift:
  RL C                    ; the key's state (carry 1 pressed) into C
  JR NC,KeyLoop
  LD A,($D3E4)            ; the joystick chosen in the menu
  CP $02
  JR Z,Kempston
  CP $03
  JR Z,Interface2
  XOR A                   ; keyboard only
  JR InputDone
Kempston:
  XOR A                   ; port $1F: fire, up, down, left, right in bits 4-0
  IN A,($1F)
  AND $1F
  JR InputDone
Interface2:
  LD A,$EF                ; keys 6-0 (port $EFFE) into the Kempston order
  IN A,($FE)
  CPL
  AND $1F
  LD B,A
  XOR A
  SRL B                   ; 0 (fire) to bit 4, 9 (up) to bit 3, 8 (down) to bit
                          ; 2
  RLA
  SRL B
  RLA
  SRL B
  RLA
  RLA
  RLA
  OR B                    ; 7 (right) to bit 0, 6 (left) to bit 1
InputDone:
  OR C                    ; plus the keys
  LD (Input),A
  RET

; the keys, eight of 3 bytes: the port high byte, the bit mask, the key code
; (shown by the redefine menu)
KeyTable:
  DEFB $F7,$01,$31
  DEFB $DF,$04,$49
  DEFB $F7,$10,$35
  DEFB $7F,$02,$82
  DEFB $FB,$01,$51
  DEFB $FD,$01,$41
  DEFB $DF,$02,$4F
  DEFB $DF,$01,$50
  DEFB $01
