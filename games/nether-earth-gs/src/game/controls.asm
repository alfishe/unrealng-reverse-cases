; --------------------------------------------------------------------------------------------------------------------
; controls.asm: the controls: KeyTable and the joystick into Input, the pause
;
; One byte for every input. ReadControls turns the eight redefinable keys of KeyTable and the joystick the main menu
; chose (Controls $D3E4: 1 keyboard, 2 Kempston, 3 Interface 2) into Input ($FD0C): bit 0 right, 1 left, 2 down, 3 up,
; 4 fire, 5 save, 6 abort, 7 pause. The joystick bits are ORed over the keys, so the keys always count. nether-
; earth/docs/05-controls.md 5.1.
;
; WaitKey is the only caller of ReadControls and the one entry every loop uses (PlayLoop, DirectControl, the menus,
; the end screens): with the pause key held it waits for another control, and the game stands meanwhile (the interrupt
; goes on: the radar blinks, a sound plays out).
;
; KeyTable: eight records of 3 bytes (the port's high byte, the bit mask, the key code shown by the redefine screen),
; entry 0 ending in Input bit 7: 1 pause, I abort, 5 save, SYMBOL SHIFT fire, Q up, A down, O left, P right. Then the
; byte Controls. RedefineKeys ($C34A, the main menu module) rewrites them.
; --------------------------------------------------------------------------------------------------------------------

; ReadControls; while key 1 (Input bit 7) is held, the pause: wait for another
; key
;
; In: nothing. Out: A = Input (also in Input $FD0C); the flags of the last OR
; A. When the pause key (bit 7) is held it loops in PauseLoop until some other
; control is pressed with the pause key up, then falls into ReadControls again:
; the control that ended the pause is this turn's input. Changes A, BC, HL.
; Called once a turn by PlayLoop, DirectControlLoop, DistanceLoop, ListMenu,
; WaitRelease, GameOverKey, RobotDirectControl and ConstructionMenuLoop.
WaitKey:
  CALL ReadControls       ; this turn's controls
  OR A                    ; bit 7, the pause, into the sign
  RET P                   ; not held: Input stands
PauseLoop:
  CALL ReadControls       ; key 1 held: wait for another control
  OR A                    ; nothing held?
  JR Z,PauseLoop          ; then wait on
  JP M,PauseLoop          ; the pause key still held: wait on; else read once
                          ; more, below

; Input from the redefinable keys (KeyTable) or the joystick the menu chose
; (Controls)
;
; The eight keys of KeyTable are rotated into C one by one (RL C, starting from
; C = 1: after the eighth the 1 drops into the carry and ends the loop), entry
; 0 ending in bit 7. Then the joystick by Controls ($D3E4): 2 Kempston (port
; $1F, bits 0-4 already right, left, down, up, fire), 3 Interface 2 (port
; $EFFE, keys 6-0, inverted and reordered), else none. Out: A = Input =
; joystick OR keys. Changes B, C, HL. 9814 calls in Nether Earth's deep
; recording.
ReadControls:
  LD HL,KeyTable          ; the eight key records
  LD C,$01                ; C = 1: the end marker, shifted out after 8 keys
KeyLoop:
  LD A,(HL)               ; A = the port's high byte: it selects the key's half
                          ; row
  INC HL                  ; to the mask
  IN A,($FE)              ; A = the half row's keys (0 = pressed)
  AND (HL)                ; Z: pressed
  INC HL                  ; past the mask
  INC HL                  ; past the key code: the next record
  JR NZ,KeyShift          ; not pressed: the AND left carry 0
  CCF                     ; pressed: carry 1
KeyShift:
  RL C                    ; the key's state (carry 1 pressed) into C
  JR NC,KeyLoop           ; no carry: the end marker is still in C, the next
                          ; key
  LD A,(Controls)         ; the joystick chosen in the menu
  CP $02                  ; 2: Kempston?
  JR Z,Kempston           ; (yes)
  CP $03                  ; 3: Interface 2?
  JR Z,Interface2         ; (yes)
  XOR A                   ; keyboard only
  JR InputDone            ; nothing to add
Kempston:
  XOR A                   ; port $1F: fire, up, down, left, right in bits 4-0
  IN A,($1F)              ; (port $001F)
  AND $1F                 ; bits 5-7 off: only the five directions and fire
  JR InputDone            ; on to the keys
Interface2:
  LD A,$EF                ; keys 6-0 (port $EFFE) into the Kempston order
  IN A,($FE)              ; bits 0-4 = keys 0, 9, 8, 7, 6 (0 = pressed)
  CPL                     ; 1 = pressed
  AND $1F                 ; the five keys
  LD B,A                  ; B = them
  XOR A                   ; A collects the Kempston order
  SRL B                   ; 0 (fire) to bit 4, 9 (up) to bit 3, 8 (down) to bit
                          ; 2
  RLA                     ; fire into A
  SRL B                   ; 9 (up)
  RLA                     ; into A
  SRL B                   ; 8 (down)
  RLA                     ; into A: now fire, up, down in bits 2-0
  RLA                     ; shifted ...
  RLA                     ; ... to bits 4-2
  OR B                    ; 7 (right) to bit 0, 6 (left) to bit 1
InputDone:
  OR C                    ; plus the keys
  LD (Input),A            ; Input: the byte every routine reads
  RET                     ; A = Input

; the keys, eight of 3 bytes: the port high byte, the bit mask, the key code
; (shown by the redefine menu)
;
; The bytes as built: F7 01 31 (key 1, Input bit 7, pause), DF 04 49 (I, bit 6,
; abort), F7 10 35 (5, bit 5, save), 7F 02 82 (SYMBOL SHIFT, bit 4, fire), FB
; 01 51 (Q, bit 3, up), FD 01 41 (A, bit 2, down), DF 02 4F (O, bit 1, left),
; DF 01 50 (P, bit 0, right). A key is LD A,(port byte) / IN A,($FE) / AND
; mask: Z when pressed. The code byte only serves the redefine screen (it
; prints the key and refuses one already taken).
;
; The ninth byte, $D3E4, is Controls: 1 in the image (the keyboard only);
; MainMenu sets 1-3 by the keys 1, 2, 3.
KeyTable:
  DEFB $F7,$01,$31        ; Input bit 7 pause: key 1, port $F7FE (1-5) mask
                          ; $01; the bytes: port high byte, mask, key code
                          ; (redefine only)
  DEFB $DF,$04,$49        ; Input bit 6 abort: key I, port $DFFE (P-Y) mask $04
  DEFB $F7,$10,$35        ; Input bit 5 save: key 5, port $F7FE (1-5) mask $10
  DEFB $7F,$02,$82        ; Input bit 4 fire: SYMBOL SHIFT, port $7FFE
                          ; (SPACE-B) mask $02, code $82 (a redefine stores
                          ; $0E)
  DEFB $FB,$01,$51        ; Input bit 3 up: key Q, port $FBFE (Q-T) mask $01
  DEFB $FD,$01,$41        ; Input bit 2 down: key A, port $FDFE (A-G) mask $01
  DEFB $DF,$02,$4F        ; Input bit 1 left: key O, port $DFFE (P-Y) mask $02
  DEFB $DF,$01,$50        ; Input bit 0 right: key P, port $DFFE (P-Y) mask $01

; the menu's choice: 1 keyboard, 2 Kempston, 3 Interface 2
Controls:
  DEFB $01                ; 1 in the image: keyboard only (2 Kempston, 3
                          ; Interface 2)
