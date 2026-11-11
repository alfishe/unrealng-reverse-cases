; --------------------------------------------------------------------------------------------------------------------
; input.asm: The selector's input: the keyboard, Kempston and Sinclair joystick, polled together
;
; ReadAnyDevice $C3BF tries the keyboard (SPACE, Z, X, O, K), then a Kempston joystick if 256 reads of port $1F never
; show bits 5-7 (no Kempston: a floating bus reads them set), then Sinclair (6 7 8 9 0), and returns the first that
; has a direction or FIRE. The bits are the Kempston's: 0 right, 1 left, 2 down, 3 up, 4 FIRE; ReadDeviceFiltered
; $C3EC drops a reading with both left and right or both up and down. The game's own device menu ($93AF) is not used
; here. A cursor-key reader (5 6 7 8 0, ReadCursorKeys $C444) sits in the code but no path reaches it.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C3BD

; The device bits ReadDevice builds, and the device it reads
;
; InputBits: bit 0 right, 1 left, 2 down, 3 up, 4 FIRE; InputDevice $C3BE: 0
; keyboard, 1 Kempston, 2 Sinclair (ReadAnyDevice $C3BF sets it). explorers
; writes both ($C3BD-$C3BE).
InputBits:
  DEFB $00
InputDevice:
  DEFB $00                ; 0 keyboard, 1 Kempston, 2 Sinclair

; Poll the keyboard, a Kempston (when present), then Sinclair; A = the first
; nonzero reading
;
; Out: A = the bits (0 right, 1 left, 2 down, 3 up, 4 FIRE), NZ when any;
; InputDevice $C3BE = the device read last. Kempston presence: port $1F ORed
; over 256 reads, bits 5-7 must stay 0. After the Sinclair read InputBits is
; cleared (A keeps the reading). Called by MoveCursor $C1D5.
;
; c1: 1127 calls, 796 reach Sinclair (the Kempston moved the cursor there);
; explorers: keyboard FIRE and right ($C477, $C488), Sinclair left and FIRE
; ($C424, $C41E) taken.
;
; Witness: L1 3459 (c1, explorers).
ReadAnyDevice:
  XOR A
  LD (InputDevice),A
  CALL ReadDeviceFiltered
  OR A
  RET NZ
  LD A,$01                ; the keyboard gave nothing: Kempston, if one answers
  LD (InputDevice),A
  LD B,$00
  LD C,$00
KempstonProbe:
  IN A,($1F)              ; port $1F ORed over 256 reads
  OR C
  LD C,A
  DJNZ KempstonProbe
  LD A,C
  AND $E0
  JR NZ,TrySinclair
  CALL ReadDeviceFiltered
  OR A
  RET NZ
TrySinclair:
  LD A,$02                ; Sinclair, the last; InputBits cleared after
  LD (InputDevice),A
  CALL ReadDeviceFiltered
  LD (HL),$00
  RET

; ReadDevice, with left+right or up+down taken as nothing
;
; Out: A = E = the bits, or A = 0 when bits 0 and 1 or bits 2 and 3 are both
; set.
;
; Witness: L1 9690 (c1, explorers).
ReadDeviceFiltered:
  CALL ReadDevice
  LD E,A
  AND $03
  CP $03
  JR NZ,NoLeftRight
  XOR A
  RET
NoLeftRight:
  LD A,E                  ; up and down together?
  AND $0C
  CP $0C
  JR NZ,ReadingOk
  XOR A
  RET
ReadingOk:
  LD A,E                  ; A = the reading
  RET

; Read InputDevice's keys or port into InputBits; A = the bits
;
; HL = InputBits $C3BD, cleared, then by InputDevice $C3BE: 0 ReadKeyboard
; $C46E, 1 ReadKempston $C43C (port $1F AND $1F, already in this order), 2 the
; Sinclair keys on half row $EFFE: 0 FIRE, 6 left, 7 right, 8 down, 9 up. All
; end at InputDone $C4A0 (A = InputBits).
;
; Witness: L1 9690 (c1, explorers).
ReadDevice:
  LD HL,InputBits
  LD (HL),$00
  LD A,(InputDevice)
  OR A
  JP Z,ReadKeyboard
  DEC A
  JP Z,ReadKempston
ReadSinclair:
  LD BC,$EFFE             ; half row 6-0 (port $EFFE), a pressed key reads 0
  IN A,(C)
  AND $1F
  BIT 0,A
  JR NZ,SinclairLeft
  SET 4,(HL)
SinclairLeft:
  BIT 4,A                 ; 6: left
  JR NZ,SinclairRight
  SET 1,(HL)
SinclairRight:
  BIT 3,A                 ; 7: right
  JR NZ,SinclairUp
  SET 0,(HL)
SinclairUp:
  BIT 1,A                 ; 9: up
  JR NZ,SinclairDown
  SET 3,(HL)
SinclairDown:
  BIT 2,A                 ; 8: down
  JP NZ,InputDone
  SET 2,(HL)
  JP InputDone
ReadKempston:
  IN A,($1F)              ; port $1F: bits 0-4 as they are
  AND $1F
  LD (HL),A
  JP InputDone

; The cursor keys 5 6 7 8 and 0 to InputBits: no path reaches it
;
; Port $F7FE bit 4 (5) left; port $EFFE bit 0 (0) FIRE, bit 2 (8) right, bit 3
; (7) up, bit 4 (6) down; ends at InputDone $C4A0. ReadDevice $C403 has no
; device number for it and nothing jumps here (the bytes after ReadKempston's
; JP); its JP operand $C46C is in RelocTable, so it was assembled as live code.
; Not executed in any recording (c1, explorers); known only from the code.
;
; Witness: L1 0 ().
ReadCursorKeys:
  LD BC,$F7FE
  IN A,(C)
  BIT 4,A
  JR NZ,CursorFire
  SET 1,(HL)
CursorFire:
  LD BC,$EFFE
  IN A,(C)
  BIT 0,A
  JR NZ,CursorRight
  SET 4,(HL)
CursorRight:
  BIT 2,A
  JR NZ,CursorUp
  SET 0,(HL)
CursorUp:
  BIT 3,A
  JR NZ,CursorDown
  SET 3,(HL)
CursorDown:
  BIT 4,A
  RET NZ
  SET 2,(HL)
  JP InputDone

; The keyboard to InputBits: SPACE FIRE, Z left, X right, O up, K down
;
; Ports $7FFE (SPACE), $FEFE (Z, X), $DFFE (O), $BFFE (K); a pressed key reads
; 0. InputDone $C4A0 returns A = InputBits; ReadSinclair, ReadKempston and
; ReadCursorKeys jump there too.
;
; Witness: L1 3459 (c1, explorers).
ReadKeyboard:
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  JR NZ,KeyLeft
  SET 4,(HL)
KeyLeft:
  LD BC,$FEFE             ; Z, X
  IN A,(C)
  BIT 1,A
  JR NZ,KeyRight
  SET 1,(HL)
KeyRight:
  BIT 2,A
  JR NZ,KeyUp
  SET 0,(HL)
KeyUp:
  LD BC,$DFFE             ; O: up
  IN A,(C)
  BIT 1,A
  JR NZ,KeyDown
  SET 3,(HL)
KeyDown:
  LD BC,$BFFE             ; K: down
  IN A,(C)
  BIT 2,A
  JR NZ,InputDone
  SET 2,(HL)
; This entry point is used by the routines at ReadDevice and ReadCursorKeys.
InputDone:
  LD A,(HL)               ; A = InputBits
  RET
