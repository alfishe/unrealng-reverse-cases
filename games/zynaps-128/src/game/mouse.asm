; --------------------------------------------------------------------------------------------------------------------
; mouse.asm: the Kempston mouse driver (K-MOUSE): the ship follows the mouse, a button fires
;
; goodboy and tiboh's, no author mark. The set-up patches four places of the game when K-MOUSE is on (docs/03-build-
; and-load.md 3.5): the stick read at $A6D4 becomes CALL MouseRead; the menu's start test at $A74E reads the left
; button instead of the stick's fire (LD A,$FA: IN A,($DF): AND 2: a left click starts play in mouse mode); the game's
; IM 2 table fill starts at $FEE8, past the driver; the life start's CALL $B1B4 at $B212 becomes CALL MouseReset.
;
; The mouse's counters are free-running bytes; the driver keeps the last value read of each (MouseLastX, MouseLastY)
; and its own position (MouseX 0-239, MouseY 0-127), moved by the difference and clamped (MouseMove). The position
; goes straight into the ship's object record: the game's own movement from the stick bits does nothing then, as
; MouseRead returns no direction but bit 3.
; --------------------------------------------------------------------------------------------------------------------

; each life: the position to X = 0, Y = $44, the counters' present values
; taken, then LifeStart
;
; Reached from the life start (CALL MouseReset at $B212 instead of CALL
; LifeStart); jumps on to LifeStart, whose RET returns to the game. AF kept.
MouseReset:
  PUSH AF
  LD A,$00
  LD (MouseX),A
  LD A,$44
  LD (MouseY),A
  LD A,MOUSE_X            ; the counters now: the next read moves from here
  IN A,(MOUSE_PORT)
  LD (MouseLastX),A
  LD A,MOUSE_Y
  IN A,(MOUSE_PORT)
  LD (MouseLastY),A
  POP AF
  JP LifeStart

; the mouse to the ship's place; A = the stick value: $08, $18 with a button
; down
;
; Replaces the game's IN A,($1F): AND $1F (the Kempston stick) at $A6D4. For
; each axis: MouseMove with L = the position, E = the last counter value, A =
; the counter now, then the position into the ship's record (ShipX, ShipY). X:
; the column (X / 8 + 16) and the pixel in it; Y: the row (Y / 8 & 15) and the
; line. The clamp's limits and the Y axis's sign are written into MouseMove
; first (self-modifying: the CP and LD A operands at MouseMax, MouseMax2 and
; the byte at MouseSign). Then the buttons: either one down sets bit 4, the
; stick's fire. Bit 3, the stick's up, is always set; what the game does with
; it in mouse mode is not traced. DE and HL kept.
MouseRead:
  PUSH DE
  PUSH HL
  LD A,$EF                ; X: the limit 239 (EF), no sign change (NOP at
                          ; MouseSign)
  LD (MouseMax+$0001),A
  LD (MouseMax2+$0001),A
  XOR A
  LD (MouseSign),A
  LD A,(MouseX)           ; L = X, E = the last X counter; the counter now
  LD L,A
  LD A,(MouseLastX)
  LD E,A
  LD A,MOUSE_X
  IN A,(MOUSE_PORT)
  LD (MouseLastX),A
  CALL MouseMove          ; the new X; a result below 0 cannot come back (CP 0
                          ; with no carry: a leftover test)
  CP $00
  JR NC,MouseXSet
  LD L,$00
MouseXSet:
  LD A,L                  ; X kept; its column + 16 and its pixel (bits 5-7) to
                          ; the ship's X
  LD (MouseX),A
  PUSH AF
  AND $F8
  RRCA
  RRCA
  RRCA
  ADD A,$10
  LD (ShipX+1),A
  POP AF
  AND $07
  RLCA
  RLCA
  RLCA
  RLCA
  RLCA
  LD (ShipX),A
  LD A,H                  ; the difference kept (MouseDeltaX)
  LD (MouseDeltaX),A
  LD A,$7F                ; Y: the limit 127 (7F), the counter's sign turned
                          ; (NEG at MouseSign): the mouse up moves the ship up
  LD (MouseMax+$0001),A
  LD (MouseMax2+$0001),A
  LD A,$ED
  LD (MouseSign),A
  LD A,(MouseY)           ; L = Y, E = the last Y counter; the counter now
  LD L,A
  LD A,(MouseLastY)
  LD E,A
  LD A,MOUSE_Y
  IN A,(MOUSE_PORT)
  LD (MouseLastY),A
  CALL MouseMove          ; the new Y
  CP $00
  JR NC,MouseYSet
  LD L,$00
MouseYSet:
  LD A,L                  ; Y kept; its row and its line (bits 4-7) to the
                          ; ship's Y
  LD (MouseY),A
  PUSH AF
  LD E,A
  AND $78
  RRCA
  RRCA
  RRCA
  LD (ShipY+1),A
  POP AF
  AND $07
  RLCA
  RLCA
  RLCA
  RLCA
  RLCA
  AND $F0
  LD (ShipY),A
  LD A,H                  ; the difference kept (MouseDeltaY)
  LD (MouseDeltaY),A
  LD A,MOUSE_B            ; the buttons: either one down (a 0 bit) gives $18,
                          ; none $08
  IN A,(MOUSE_PORT)
  CPL
  AND $03
  LD A,$08
  JR Z,MouseReadDone
  LD A,$18
MouseReadDone:
  POP HL
  POP DE
  RET

; L = the position moved by A - E (the counter's step), clamped to 0..MouseMax
;
; Input: A = the counter now, E = the last, L = the position. Output: L the new
; position, H the counter's step before the sign, A = L. The step is the
; counter's byte difference, so a move of up to 127 counts a call is read
; right.
MouseMove:
  SUB E
  LD H,A
  JR Z,MouseMoved
MouseSign:
  NEG                     ; NEG for Y, NOP (with the next byte, LD B,H) for X:
                          ; written by MouseRead
  JP P,MouseUp            ; a step down: below 0 gives 0
  ADD A,L
  JR C,MouseDownSet
  XOR A
MouseDownSet:
  LD L,A
  JR MouseMoved
MouseUp:
  ADD A,L                 ; a step up: past the limit (or past 255) gives the
                          ; limit
  JR C,MouseMax2
MouseMax:
  CP $00                  ; CP limit (the operand written by MouseRead): 239
                          ; for X, 127 for Y
  JR C,MouseUpSet
MouseMax2:
  LD A,$00                ; LD A,limit: the same
MouseUpSet:
  LD L,A
MouseMoved:
  LD A,L                  ; a last clamp to 255 (it never changes L: a
                          ; leftover)
  CP $FF
  JR C,MouseMoveDone
  LD L,$FF
MouseMoveDone:
  RET

; the X counter's last value
MouseLastX:
  DEFB $00

; the Y counter's last value
MouseLastY:
  DEFB $00

; the position's X, 0-239
MouseX:
  DEFB $00

; the position's Y, 0-127 ($44 at a life's start)
MouseY:
  DEFB $44

; the last X step (written, not read)
MouseDeltaX:
  DEFB $00

; the last Y step (written, not read)
MouseDeltaY:
  DEFB $00
