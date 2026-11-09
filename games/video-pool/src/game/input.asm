; --------------------------------------------------------------------------------------------------------------------
; input.asm: The controls: keyboard, Interface 2, Kempston, cursor; the key table; BREAK
;
; ReadInput $8106 runs as a task of the aim (AimTasks $84AA) and of the editor ($C518), once an interrupt. It calls
; one of four readers by the control choice $B8BD (0 keyboard, 1 Interface 2, 2 Kempston, 3 cursor joystick; set by
; the menu), each returning A with bit 0 right, bit 1 left, bit 2 up, bit 3 down, bit 4 fire; then ReadBreak adds bit
; 5 for CAPS SHIFT + SPACE and stores the byte in InputState $827C, which the aim tasks, the editor and SoundLoop
; read.
;
; The game never reads port $FE for the keys directly but in KeyDown $822E (one key by its character, through the key
; table) and ReadBreak; the cursor joystick also uses the ROM's KEY-SCAN and K-TEST for "any other key is fire".
; --------------------------------------------------------------------------------------------------------------------

; The input task: A = the directions and fire of the chosen control, into
; InputState
;
; Pushes ReadBreak as the return, then jumps through InputHandlers by the
; control choice $B8BD (0-3). Output: InputState $827C (bits 0 right, 1 left, 2
; up, 3 down, 4 fire, 5 BREAK). Witness: w1 6407 calls (keyboard only), m1 927
; (keyboard 317, Kempston 51 at frames 4922-4980, cursor 559 at frames
; 6272-6830), j1 (Kempston 1087 at frames 622-2185, Interface 2 836 at frames
; 2503-3540, a shot played with each).
ReadInput:
  LD HL,ReadBreak
  PUSH HL
  LD A,(Control)
  ADD A,A
  LD HL,InputHandlers
  ADD A,L
  LD L,A
  JR NC,InputHandlerGot
  INC H
InputHandlerGot:
  LD A,(HL)               ; HL = InputHandlers[choice]
  INC HL
  LD H,(HL)
  LD L,A
  JP (HL)

; The four readers by the control choice $B8BD
;
; Read by ReadInput: $811B/$811C in every build, $811D/$811E in j1, $811F/$8120
; in m1 and j1, $8121/$8122 in m1.
InputHandlers:
  DEFW ReadKeyboard       ; 0: the keyboard, the three keys of the menu
  DEFW ReadInterface2     ; 1: Interface 2
  DEFW ReadKempston       ; 2: Kempston
  DEFW ReadCursorKeys     ; 3: the cursor joystick (keys 5-8, any other key
                          ; fire)

; The keyboard: the three defined keys, left, right, fire
;
; The keys are the characters at $B8BE (left), $B8BF (right) and $B8C0 (fire),
; set by "reconfigure keys" (default m, symbol shift, space: the menu's last
; line). KeyDown for each: left gives bit 1, right bit 0, fire bit 4; there is
; no up and down on the keyboard (the cursor runs round the cushions with left
; and right alone, AimCursorMove $8546). w1: 6407 calls.
ReadKeyboard:
  LD E,$00
  LD HL,LeftKey
  LD A,(HL)
  CALL KeyDown
  JR NZ,KeyboardRight
  LD A,E
  OR $02
  LD E,A
KeyboardRight:
  LD HL,LeftKey
  INC HL
  LD A,(HL)
  CALL KeyDown
  JR NZ,KeyboardFire
  LD A,E
  OR $01
  LD E,A
KeyboardFire:
  LD HL,LeftKey
  INC HL
  INC HL
  LD A,(HL)
  CALL KeyDown
  JR NZ,KeyboardDone
  LD A,E
  OR $10
  LD E,A
KeyboardDone:
  LD A,E
  RET

; Interface 2: both joysticks, keys 6-0 and 1-5
;
; j1 (menu I): 836 calls at frames 2503-3540; key 6 held 40 frames from 2565
; moved the cursor, key 0 held 30 frames from 2610 played the shot at 2640.
; Reads port $EFFE (keys 6-0, Interface 2's joystick 1: 6 left, 7 right, 8
; down, 9 up, 0 fire) and port $F7FE (keys 1-5, joystick 2: 1 left, 2 right, 3
; down, 4 up, 5 fire), each inverted with CPL, and ORs both into the result
; bits (fire $10, right $01, left $02, up $04, down $08), so either joystick
; works.
ReadInterface2:
  LD BC,$EFFE
  IN A,(C)
  CPL
  LD C,A                  ; the 6-0 half row, inverted: a bit set = pressed
  LD A,$00
  BIT 0,C
  JR Z,If2Right
  OR $10
If2Right:
  BIT 3,C
  JR Z,If2Left
  OR $01
If2Left:
  BIT 4,C
  JR Z,If2Down
  OR $02
If2Down:
  BIT 2,C
  JR Z,If2Up
  OR $08
If2Up:
  BIT 1,C
  JR Z,If2Stick2
  OR $04
If2Stick2:
  PUSH AF                 ; the 1-5 half row
  LD BC,$F7FE
  IN A,(C)
  CPL
  LD C,A
  POP AF                  ; the first half row's bits back in A
  BIT 4,C
  JR Z,If2Stick2Right
  OR $10
If2Stick2Right:
  BIT 1,C
  JR Z,If2Stick2Left
  OR $01
If2Stick2Left:
  BIT 0,C
  JR Z,If2Stick2Down
  OR $02
If2Stick2Down:
  BIT 2,C
  JR Z,If2Stick2Up
  OR $08
If2Stick2Up:
  BIT 3,C
  JR Z,If2Done
  OR $04
If2Done:
  RET

; Kempston: IN ($1F), active high
;
; IN A,($1F): bit 0 right, 1 left, 2 down, 3 up, 4 fire, moved to the game's
; bits (down to bit 3, up to bit 2). m1: 51 calls at frames 4922-4980 (option j
; on the menu, no stick held); j1 (menu J): 1087 calls at frames 622-2185, the
; stick left 40 frames from 1000 moved the cursor, fire 30 frames from 1045
; played the shot at 1075.
ReadKempston:
  IN A,($1F)
  LD C,A
  LD A,$00
  BIT 4,C
  JR Z,KempstonRight
  OR $10
KempstonRight:
  BIT 0,C
  JR Z,KempstonLeft
  OR $01
KempstonLeft:
  BIT 1,C
  JR Z,KempstonDown
  OR $02
KempstonDown:
  BIT 2,C
  JR Z,KempstonUp
  OR $08
KempstonUp:
  BIT 3,C
  JR Z,KempstonDone
  OR $04
KempstonDone:
  RET

; The cursor joystick: 8 right, 5 left, 7 up, 6 down, any other key fire
;
; KeyDown for '8', '5', '6', '7'; when none is down, the ROM's KEY_SCAN and
; K_TEST: any other key (not 5-8) gives fire ($10). m1: 559 calls at frames
; 6272-6830, 328 with no key ($8213).
ReadCursorKeys:
  LD E,$00
  LD A,$38
  CALL KeyDown
  JR NZ,CursorKeyLeft
  LD A,E
  OR $01
  LD E,A
CursorKeyLeft:
  LD A,$35
  CALL KeyDown
  JR NZ,CursorKeyDown
  LD A,E
  OR $02
  LD E,A
CursorKeyDown:
  LD A,$36
  CALL KeyDown
  JR NZ,CursorKeyUp
  LD A,E
  OR $08
  LD E,A
CursorKeyUp:
  LD A,$37
  CALL KeyDown
  JR NZ,CursorKeyDirs
  LD A,E
  OR $04
  LD E,A
CursorKeyDirs:
  LD A,E                  ; a direction is down: done
  CP $00
  RET NZ
  CALL KEY_SCAN
  CALL K_TEST
  CP $FF
  JR Z,CursorNoKey
  CP $38
  JR Z,CursorNoKey
  CP $35
  JR Z,CursorNoKey
  CP $36
  JR Z,CursorNoKey
  CP $37
  JR Z,CursorNoKey
  LD A,$10                ; another key: fire
  RET
CursorNoKey:
  LD A,$00                ; no key: 0
  RET

; BREAK into bit 5, then the result into InputState
;
; The return of every reader (pushed by ReadInput). CAPS SHIFT (port $FEFE bit
; 0) and SPACE (port $7FFE bit 0) both down add bit 5 ($20). Stores A into
; InputState. Taken (bit 5 set): p2 1, v1 1, m1 2 (the BREAKs of those
; recordings).
ReadBreak:
  LD BC,$FEFE
  IN C,(C)
  BIT 0,C
  JR NZ,StoreInput
  LD BC,$7FFE
  IN C,(C)
  BIT 0,C
  JR NZ,StoreInput
  OR $20
StoreInput:
  LD (InputState),A       ; store the input byte
  RET

; Is the key with character A down? Z = down
;
; Looks A up in KeyTable with CPIR (40 bytes), turns the position into the half
; row's port high byte (B = $FE, $FD, ... $7F) and the bit (D = $10 down to
; $01: KeyTable runs from the outer key inwards), reads the port and ANDs the
; bit: Z when the key is down (the port bit is 0). NZ when the character is not
; in the table. w1: 19 221 calls.
KeyDown:
  LD HL,KeyTable
  LD BC,$0028
  CPIR
  RET NZ
  LD A,C
  LD B,$7F
KeyRowLoop:
  SUB $05                 ; five keys a half row: B rotates one row on
  JR C,KeyBit
  SCF
  RR B
  JR KeyRowLoop
KeyBit:
  LD C,$FE                ; the key's bit in D
  ADD A,$06
  LD D,$10
KeyBitLoop:
  DEC A
  JR Z,KeyRead
  SRA D
  JR KeyBitLoop
KeyRead:
  IN A,(C)                ; read the half row
  AND D
  RET

; The 40 keys by half row, from the outer key in: the character each one stands
; for
;
; Read by KeyDown (CPIR) and by the menu's key-name code. Characters: CAPS
; SHIFT = $27, ENTER = $0D, SPACE = $20, SYMBOL SHIFT = $18, else the key's
; capital letter or digit. The rows are the ports $FEFE (CAPS Z X C V), $FDFE
; (A S D F G), $FBFE (Q W E R T), $F7FE (1 2 3 4 5), $EFFE (0 9 8 7 6), $DFFE
; (P O I U Y), $BFFE (ENTER L K J H), $7FFE (SPACE SYMBOL M N B). Stage 1's
; signature candidate at $8240 was this table.
KeyTable:
  INCBIN "res/tables/KeyTable.bin",$0000,40

; The controls this interrupt: bit 0 right, 1 left, 2 up, 3 down, 4 fire, 5
; BREAK
;
; Written by ReadBreak (every pass of ReadInput), cleared by AimCursorReset
; $85C8 and the editor ($C504). Read by SoundLoop (BREAK), AimPower $8506
; (fire), AimCursorMove $8546, the hall-of-fame entry ($AEBF...), the menu
; ($B2A7...) and the editor ($C11E...).
InputState:
  DEFB $00

; The sound SoundLoop plays: 0 none, 1 ball, 2 cushion, 3 pocket
;
; Written by the physics ($8993 = 1, $8DC0 / $8DF4 / $8E28 = 2, $8C17 = 3),
; cleared by GameRestart, SoundLoop, StopShotTasks, ShotReset and the editor
; ($C467). See SoundLoop.
SoundRequest:
  DEFB $00
