; --------------------------------------------------------------------------------------------------------------------
; controls.asm: The controls: the self-modified key readers, the pause
;
; Each control has a reader: IN A,(C) from a port, XOR ControlXor $A0AE ($FF for Kempston, whose bits are active
; high), BIT n,A; the zero flag set means pressed. The port and the BIT opcode are operands inside the readers,
; written by the setters ($A46A-$A4CE) when the menu's choice is made (DEFINE, Kempston, Cursor or Sinclair). The
; tape's defaults: fire O ($DFFE bit 1), left Q ($FBFE bit 0), right W ($FBFE bit 1), up I ($DFFE bit 2), down J
; ($BFFE bit 3).
; --------------------------------------------------------------------------------------------------------------------

; Fire reads DefinePort $A0AB, bit DefineBit $A0AD (the operands at $A478,
; $A481)
;
; Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
SetFire:
  LD HL,(DefinePort)
  LD (ReadFire+$0001),HL
  LD A,(DefineBit)
  LD (ReadFireBit+$0001),A
  RET

; Z = fire pressed (default O, $DFFE bit 1)
;
; Witness: L1 3033772 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x33).
ReadFire:
  LD BC,$DFFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
ReadFireBit:
  BIT 1,A                 ; BIT n,A: n written by SetFire
  RET

; Left reads DefinePort, DefineBit
;
; Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
SetLeft:
  LD HL,(DefinePort)
  LD (ReadLeft+$0001),HL
  LD A,(DefineBit)
  LD (ReadLeftBit+$0001),A
  RET

; Z = left pressed (default Q)
;
; Witness: L1 16946 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
ReadLeft:
  LD BC,$FBFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
ReadLeftBit:
  BIT 0,A                 ; BIT n,A: n written by SetLeft
  RET

; Right reads DefinePort, DefineBit
;
; Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
SetRight:
  LD HL,(DefinePort)
  LD (ReadRight+$0001),HL
  LD A,(DefineBit)
  LD (ReadRightBit+$0001),A
  RET

; Z = right pressed (default W)
;
; Witness: L1 16976 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
ReadRight:
  LD BC,$FBFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
ReadRightBit:
  BIT 1,A                 ; BIT n,A: n written by SetRight
  RET

; Up reads DefinePort, DefineBit
;
; Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
SetUp:
  LD HL,(DefinePort)
  LD (ReadUp+$0001),HL
  LD A,(DefineBit)
  LD (ReadUpBit+$0001),A
  RET

; Z = up (jump) pressed (default I)
;
; Witness: L1 16687 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
ReadUp:
  LD BC,$DFFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
ReadUpBit:
  BIT 2,A                 ; BIT n,A: n written by SetUp
  RET

; Down reads DefinePort, DefineBit
;
; Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
SetDown:
  LD HL,(DefinePort)
  LD (ReadDown+$0001),HL
  LD A,(DefineBit)
  LD (ReadDownBit+$0001),A
  RET

; Z = down (the shield) pressed (default J)
;
; Witness: L1 37004 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
ReadDown:
  LD BC,$BFFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
ReadDownBit:
  BIT 3,A                 ; BIT n,A: n written by SetDown
  RET

; H: silence; loop while fire is not pressed (ReadFire); the sound back
;
; Witness: L1 51872 (c1, p1-cursor).
Pause:
  CALL SoundSilence
  CALL ReadFire
  JP NZ,Pause
  CALL SoundReset
  RET

; OR the 8 bytes at DE into the buffer at HL (32-byte rows)
;
; Witness: L1 23346 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-shots, p1-speedup, p1-room24, p1-room30,
; rzx-p1- x32).
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
