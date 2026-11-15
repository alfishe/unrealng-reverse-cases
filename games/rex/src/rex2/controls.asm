; --------------------------------------------------------------------------------------------------------------------
; controls.asm: The controls: the self-modified key readers, the pause
; --------------------------------------------------------------------------------------------------------------------

; Fire reads DefinePort $A244, bit DefineBit $A246 (the operands at $A620,
; $A629)
;
; As REX 1's SetFire $A46A (src/game/controls.asm).
;
; Witness: L1 2 (c2, rzx-p2-00000).
SetFire:
  LD HL,(DefinePort)
  LD (ReadFire+$0001),HL
  LD A,(DefineBit)
  LD (ReadFire+$000A),A
  RET

; Z = fire pressed (default O, $DFFE bit 1)
;
; As REX 1's ReadFire $A477 (src/game/controls.asm).
;
; Witness: L1 349448 (c2, p2-room20, rzx-p2- x21).
ReadFire:
  LD BC,$DFFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
  BIT 1,A
  RET

; Left reads DefinePort, DefineBit
;
; As REX 1's SetLeft $A483 (src/game/controls.asm).
;
; Witness: L1 2 (c2, rzx-p2-00000).
SetLeft:
  LD HL,(DefinePort)
  LD (ReadLeft+$0001),HL
  LD A,(DefineBit)
  LD (ReadLeftBit+$0001),A
  RET

; Z = left pressed (default Q)
;
; As REX 1's ReadLeft $A490 (src/game/controls.asm).
;
; Witness: L1 8904 (c2, p2-room20, rzx-p2- x21).
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
; As REX 1's SetRight $A49C (src/game/controls.asm).
;
; Witness: L1 2 (c2, rzx-p2-00000).
SetRight:
  LD HL,(DefinePort)
  LD (ReadRight+$0001),HL
  LD A,(DefineBit)
  LD (ReadRight+$000A),A
  RET

; Z = right pressed (default W)
;
; As REX 1's ReadRight $A4A9 (src/game/controls.asm).
;
; Witness: L1 8904 (c2, p2-room20, rzx-p2- x21).
ReadRight:
  LD BC,$FBFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
  BIT 1,A
  RET

; Up reads DefinePort, DefineBit
;
; As REX 1's SetUp $A4B5 (src/game/controls.asm).
;
; Witness: L1 2 (c2, rzx-p2-00000).
SetUp:
  LD HL,(DefinePort)
  LD (ReadUp+$0001),HL
  LD A,(DefineBit)
  LD (ReadUpBit+$0001),A
  RET

; Z = up (jump) pressed (default I)
;
; As REX 1's ReadUp $A4C2 (src/game/controls.asm).
;
; Witness: L1 9003 (c2, p2-room20, rzx-p2- x21).
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
; As REX 1's SetDown $A4CE (src/game/controls.asm).
;
; Witness: L1 2 (c2, rzx-p2-00000).
SetDown:
  LD HL,(DefinePort)
  LD (ReadDown+$0001),HL
  LD A,(DefineBit)
  LD (ReadDownBit+$0001),A
  RET

; Z = down (the shield) pressed (default J)
;
; As REX 1's ReadDown $A4DB (src/game/controls.asm).
;
; Witness: L1 20852 (c2, p2-room20, rzx-p2- x21).
ReadDown:
  LD BC,$BFFE
  IN A,(C)
  LD HL,ControlXor
  XOR (HL)
ReadDownBit:
  BIT 3,A                 ; BIT n,A: n written by SetDown
  RET

; H: silence, wait for fire up, then for fire; the sound back
;
; As REX 1's Pause $A4E7 (src/game/controls.asm).
;
; Witness: L1 20392 (p2-room20).
Pause:
  CALL SoundSilence
  CALL ReadFire
  JP NZ,Pause
  CALL SoundReset
  RET

; OR the 8 bytes at DE into the buffer at HL (32-byte rows)
;
; As REX 1's OrChar $A4F4 (src/game/controls.asm).
;
; Witness: L1 12228 (c2, p2-room20, rzx-p2- x20).
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
