; --------------------------------------------------------------------------------------------------------------------
; input.asm: The controls: keyboard, cursor, Sinclair, Kempston joystick and mouse
;
; ReadControls $971A runs the reader of the device chosen in the options ($67B6, 0-4) through the table $9723. Every
; reader but the mouse ends in DecodeDirections $9758: the five bits right, left, down, up, fire, with acceleration
; (the step grows by one up to 8 while a direction is held, $9719 frames per step).
; --------------------------------------------------------------------------------------------------------------------

  ORG $9715

; The click position (X, Y), the fire timer (on, count), the frames per step
ClickState:
ClickX:
  DEFB $00
ClickY:
  DEFB $00
FireHeld:
  DEFB $00
FireCount:
  DEFB $00
StepFrames:
  DEFB $04

; Read the chosen device: the reader of $67B6 in the table $9723
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
ReadControls:
  LD A,(ControlDevice)
  LD HL,DeviceReaders
  JP CallTableEntry

; Five readers: Sinclair, cursor, Kempston mouse, Kempston joystick, keyboard
DeviceReaders:
  DEFW ReadSinclair,ReadCursor
  DEFW ReadMouse,ReadKempston
  DEFW ReadKeys

; Sinclair (Interface 2): port $EFFE
;
; Witness: menu, 11 runs in frames 115-140 after OPTIONS 1 (Sinclair selected;
; entered by `JP (HL)`, docs/05-controls.md 5.2).
ReadSinclair:
  LD BC,$EFFE
  IN A,(C)
  JR InvertDirections

; Cursor keys: ports $F7FE, $EFFE, $7FFE
;
; Witness: known only from the code (entered by `JP (HL)`).
ReadCursor:
  LD BC,$F7FE
  IN A,(C)
  RLA
  RLA
  RLA
  RLA
  RL E
  RLC B
  IN A,(C)
  RRA
  RRA
  RRA
  RL E
  RRA
  RRA
  RL E
  RLA
  RL E
  LD B,$7F
  IN A,(C)
  RRA
  RL E
  LD A,E

; CPL then DecodeDirections
;
; Witness: L1 1225 (menu).
InvertDirections:
  CPL

; Bits right, left, down, up, fire: the X and Y steps with acceleration ($985E,
; $985F), carry = fire
;
; Witness: L1 7771 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
DecodeDirections:
  AND $1F
  LD C,A
  AND $06
  JR Z,l_9767
  CP $06
  JR NZ,l_9773
  LD A,C
  AND $F9
  LD C,A
l_9767:
  XOR A
  LD (StepY),A
  LD A,(StepFrames)
  LD (RepeatY),A
  JR l_97B2
l_9773:
  LD B,A
  LD A,(LastDirections)
  AND $06
  CP B
  LD A,B
  JR Z,l_9790
  RRA
  RRA
  LD A,$01
  JR NC,l_9785
  NEG
l_9785:
  LD (StepY),A
  LD A,(StepFrames)
  LD (RepeatY),A
  JR l_97B2
l_9790:
  LD HL,RepeatY
  DEC (HL)
  JR NZ,l_97B2
  EX AF,AF'
  LD A,(StepFrames)
  LD (HL),A
  EX AF,AF'
  RRA
  RRA
  LD A,(StepY)
  JR C,l_97AA
  CP $08
  JR NC,l_97AF
  INC A
  JR l_97AF
l_97AA:
  CP $F9
  JR C,l_97AF
  DEC A
l_97AF:
  LD (StepY),A
l_97B2:
  LD A,C
  AND $18
  JR Z,l_97BF
  CP $18
  JR NZ,l_97CB
  LD A,C
  AND $E7
  LD C,A
l_97BF:
  XOR A
  LD (StepX),A
  LD A,(StepFrames)
  LD (RepeatX),A
  JR l_980E
l_97CB:
  LD B,A
  LD A,(LastDirections)
  AND $18
  CP B
  LD A,B
  JR Z,l_97EA
  RRA
  RRA
  RRA
  RRA
  LD A,$01
  JR C,l_97DF
  NEG
l_97DF:
  LD (StepX),A
  LD A,(StepFrames)
  LD (RepeatX),A
  JR l_980E
l_97EA:
  LD HL,RepeatX
  DEC (HL)
  JR NZ,l_980E
  EX AF,AF'
  LD A,(StepFrames)
  LD (HL),A
  EX AF,AF'
  RRA
  RRA
  RRA
  RRA
  LD A,(StepX)
  JR NC,l_9806
  CP $08
  JR NC,l_980B
  INC A
  JR l_980B
l_9806:
  CP $F9
  JR C,l_980B
  DEC A
l_980B:
  LD (StepX),A
l_980E:
  LD A,C
  LD (LastDirections),A
  RET

; Kempston mouse: X from $FBDF, Y from $FFDF, the deltas
;
; Reads X (`AND $7F`, doubled) and Y (inverted), stores them at `$67BB`, then
; the deltas over `$67BC-$67BD`: the delta word overwrites the new Y. It
; returns straight to the caller with A = the X delta and the carry of that
; subtraction: it never reaches `DecodeDirections`, so `$985E` / `$985F` keep
; their last values and `PointerFire` takes the carry for the fire button.
; Recording controls: 30 runs (frames 295-330) before the machine resets (see
; NOTES.md, open point 4). Witness: L1 0 (controls; entered by `JP (HL)`).
ReadMouse:
  LD HL,(MousePos)
  LD BC,$FBDF
  IN A,(C)
  AND $7F
  ADD A,A
  LD E,A
  LD BC,$FFDF
  IN A,(C)
  CPL
  LD D,A
  LD (MousePos),DE
  SUB H
  LD H,A
  LD A,E
  SUB L
  LD L,A
  LD (MousePos+$0001),HL
  RET

; Kempston joystick: port $1F, the bits reordered for DecodeDirections
;
; Witness: known only from the code (entered by `JP (HL)`; controls runs it).
ReadKempston:
  IN A,($1F)
  LD C,A
  RRCA
  RRCA
  RRCA
  RL C
  RRCA
  RL C
  RRCA
  LD A,C
  RLA
  JP DecodeDirections

; The keyboard: five keys from the table $9862 (port, mask)
;
; Witness: known only from the code (entered by `JP (HL)`; every recording runs
; it).
ReadKeys:
  LD HL,KeyTable
  LD E,$05
  LD C,$FE
l_984B:
  LD B,(HL)
  INC L
  IN A,(C)
  AND (HL)
  DEC A
  RLA
  RL D
  INC L
  DEC E
  JR NZ,l_984B
  LD A,D
  JP DecodeDirections

; The mouse's last position, the X and Y steps, the token table base
;
; `$9860`: PrintString's token table base (PrintString `$6FDB` uses StepY+1);
; its words are this table's bytes, not string pointers, and the token path is
; never taken (play2: the branch at `$6FBA` taken 0 of 3797).
InputState:
  DEFB $00,$00
StepX:
  DEFB $00
StepY:
  DEFB $00,$00,$00

; The five keys of ReadKeys: half-row high byte and bit mask
KeyTable:
  DEFB $DF,$02
  DEFB $DF,$01
  DEFB $FD,$01
  DEFB $FB,$01
  DEFB $7F,$01
  DEFB $FE,$08
  DEFB $FE,$02
  DEFB $FE,$04
  DEFB $FD,$02

; Jump to the word A of the table at HL
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
CallTableEntry:
  CALL TableEntry
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP (HL)

; HL = HL + 2A
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
TableEntry:
  ADD A,A
  ADD A,L
  LD L,A
  RET NC
  INC H
  RET
