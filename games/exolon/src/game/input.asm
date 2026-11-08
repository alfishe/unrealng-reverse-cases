; --------------------------------------------------------------------------------------------------------------------
; input.asm: The controls (keyboard, Interface 2, Kempston) and the tables built at the start
; --------------------------------------------------------------------------------------------------------------------

; Reads the five defined keys into ControlLeft..ControlFire (1 = pressed);
; DefineKeys patches each test
;
; Five tests of 10 bytes from $7AF0 (INC HL / LD B,row / IN A,(C) / AND mask /
; JR NZ / LD (HL),D), D = 1, HL from $7B91: the half-row's port high byte and
; the bit are written by DefineKeys (+2 and +6). The image's keys: O ($DF bit
; 1) left, P ($DF bit 0) right, Q ($FB bit 0) jump, A ($FD bit 0) duck, M ($7F
; bit 2) fire.
;
; Run by ReadControls when ControlType $7B97 is 0. Never ran in any recording:
; every play chose Kempston (5) or Interface 2 (4) before starting, and
; DefineKeys only patches it.
ReadKeyboard:
  LD D,$01
  LD HL,ClearControls+$000D
  LD C,$FE
KeyLeftTest:
  INC HL                  ; LEFT: LD B,$DF / AND $02 (O)
  LD B,$DF
  IN A,(C)
  AND $02
  JR NZ,KeyRightTest
  LD (HL),D
KeyRightTest:
  INC HL                  ; RIGHT: $DF / $01 (P)
  LD B,$DF
  IN A,(C)
  AND $01
  JR NZ,KeyJumpTest
  LD (HL),D
KeyJumpTest:
  INC HL                  ; JUMP: $FB / $01 (Q)
  LD B,$FB
  IN A,(C)
  AND $01
  JR NZ,KeyDuckTest
  LD (HL),D
KeyDuckTest:
  INC HL                  ; DUCK: $FD / $01 (A)
  LD B,$FD
  IN A,(C)
  AND $01
  JR NZ,KeyFireTest
  LD (HL),D
KeyFireTest:
  INC HL                  ; FIRE: $7F / $04 (M)
  LD B,$7F
  IN A,(C)
  AND $04
  RET NZ
  LD (HL),D
  RET

; Reads the Interface 2 stick (keys 6-0, port $EFFE) into
; ControlLeft..ControlFire
;
; CPL, AND $1F: bit 0 (0) fire, bit 1 (9) jump, bit 2 (8) duck, bit 3 (7)
; right, bit 4 (6) left, each 0 / 1 through NextInputBit. ControlType 1. c1:
; 443 runs.
ReadInterface2:
  LD BC,$EFFE
  IN A,(C)
  CPL
  AND $1F
  LD D,A
  CALL NextInputBit
  LD (ControlFire),A
  CALL NextInputBit
  LD (ControlJump),A
  CALL NextInputBit
  LD (ControlDuck),A
  CALL NextInputBit
  LD (ControlRight),A
  CALL NextInputBit
  LD (ControlLeft),A
  RET

; Reads the Kempston stick (port $1F) into ControlLeft..ControlFire
;
; Bit 0 right, 1 left, 2 duck (down), 3 jump (up), 4 fire. ControlType 2. c1:
; 2820 runs, c128 4181, all the warp runs.
ReadKempston:
  LD C,$1F
  IN D,(C)
  CALL NextInputBit
  LD (ControlRight),A
  CALL NextInputBit
  LD (ControlLeft),A
  CALL NextInputBit
  LD (ControlDuck),A
  CALL NextInputBit
  LD (ControlJump),A
  CALL NextInputBit
  LD (ControlFire),A
  RET

; A = bit 0 of D (0 or 1), D shifted right
;
; Used by the routines at ReadInterface2 and ReadKempston.
NextInputBit:
  XOR A
  SRL D
  RLA
  RET

; Reads the chosen controls into ControlLeft..ControlFire (cleared first)
;
; ControlType $7B97: 0 ReadKeyboard, 1 ReadInterface2, else ReadKempston.
; Called by MainLoop, WaitKeyOrFire and the bonus screen ($A92F).
ReadControls:
  CALL ClearControls
  LD A,(ControlType)
  OR A
  JP Z,ReadKeyboard
  CP $01
  JP Z,ReadInterface2
  JP ReadKempston

; Zeroes ControlLeft..ControlFire (5 bytes)
;
; Used by the routine at ReadControls.
ClearControls:
  LD HL,ControlLeft
  LD DE,ControlRight
  LD (HL),$00
  LD BC,$0004
  LDIR
  RET

; The controls as ReadControls left them: 1 = pressed. Left
ControlLeft:
  DEFB $00
ControlRight:
  DEFB $00                ; right
ControlJump:
  DEFB $00                ; jump (up)
ControlDuck:
  DEFB $00                ; duck (down)
ControlFire:
  DEFB $00                ; fire: read by $8347 (the fire hold count $83DC),
                          ; WaitKeyOrFire and the bonus screen
ControlType:
  DEFB $00                ; the control type: 0 keyboard (ReadKeyboard), 1
                          ; Interface 2, 2 Kempston; set by the menu keys 3-5,
                          ; 0 by DefineKeys
ControlSpare:
  DEFB $00                ; written 0 by $8343, read by nothing

; Builds the bit-reverse table at $6400: byte n holds n with its bits in
; reverse order
;
; Called once by Start. Read by FlipPlayerFrames.
BuildReverseTable:
  LD HL,BitReverse
ReverseByte:
  LD D,L
  LD B,$08
ReverseBit:
  SRL D
  RL C
  DJNZ ReverseBit
  LD (HL),C
  INC L
  JR NZ,ReverseByte
  RET

; Mirrors the player's 24 frames in place (24x32 at $EF80) and toggles
; PlayerFlipped
;
; 768 lines of 3 bytes from $EF80: each byte reversed through $6400 and the
; outer two swapped. Called when the player turns ($82B7, $82C5), by $9D12 and
; by StartGame (back to facing right). c1: 20 flips, c128: 24. Keeps every
; register.
FlipPlayerFrames:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,(PlayerFlipped)
  XOR $01
  LD (PlayerFlipped),A
  LD HL,PlayerFrames
  LD D,$64
  LD BC,$0300
FlipLine:
  PUSH BC                 ; one 3-byte line: reverse each, swap the outer two
  PUSH HL
  LD E,(HL)
  LD A,(DE)
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  LD (HL),A
  INC HL
  LD E,(HL)
  LD A,(DE)
  LD (HL),C
  INC HL
  POP BC
  LD (BC),A
  POP BC
  DEC BC
  LD A,B
  OR C
  JP NZ,FlipLine
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; 1 while the player's frames are mirrored (facing left), toggled by
; FlipPlayerFrames
PlayerFlipped:
  DEFB $00

; Sets IM 2 with a vector table of $81 at $8000-$8100: never ran, nothing calls
; it, and it would overwrite live code
;
; LD HL,$8000 / ($81 x 257) / IM 2 / I = $80. The game runs with DI throughout
; and $8000-$8100 holds the beeper engine's tail, the pitch table and live
; routines, so running this would break the game: a leftover of another build
; (compare the Amstrad keyboard code at $C7B5). Never ran in any recording.
SetupIm2:
  LD HL,$8000
  LD (HL),$81
  LD DE,RestTurnA+$0009
  LD BC,$0101
  LDIR
  IM 2
  LD A,$80
  LD I,A
  RET

; Builds the screen line tables: $6500 / $6600 the high / low address byte of
; each of 192 lines, $6700 the word of column 8
;
; $6500 + y, $6600 + y: the address of pixel line y's first byte (read by $B088
; for every sprite and character). $6700 + 2y: the address of line y's column 8
; (ScrollHallOfFame). Called once by Start.
BuildLineTables:
  LD B,$C0
  LD IX,LineAddrHigh
  LD IY,LineAddrLow
  LD HL,$4000
LineTableLoop:
  LD (IX+$00),H           ; line y: high byte, low byte
  LD (IY+$00),L
  INC IX
  INC IY
  CALL NextPixelLine
  DJNZ LineTableLoop
  LD B,$C0
  LD HL,$4008
  LD IX,LineCol8Addr
Column8Loop:
  LD (IX+$00),L           ; line y, column 8: a word
  LD (IX+$01),H
  INC IX
  INC IX
  CALL NextPixelLine
  DJNZ Column8Loop
  RET
