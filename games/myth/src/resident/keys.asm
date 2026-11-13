; --------------------------------------------------------------------------------------------------------------------
; keys.asm: The key readers
;
; Five readers, one per control. Each calls KeyHook (a RET), reads its port, XORs KeyXorMask and tests its bit: Z when
; the control is on (keys are active low). The front's DEFINE KEYS and SELECT JOYSTICK rewrite the port word at +4 and
; the BIT byte at +13 of each. The tape's defaults: I J Q W O (front notes).
; --------------------------------------------------------------------------------------------------------------------

; UP: port $DFFE bit 2 (I)
;
; Witness: L1 41801 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
KeyUp:
  CALL KeyHook
  LD BC,$DFFE
  IN A,(C)
  LD HL,KeyXorMask
  XOR (HL)
  BIT 2,A
  RET

; DOWN: port $BFFE bit 3 (J)
;
; Witness: L1 33680 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
KeyDown:
  CALL KeyHook
  LD BC,$BFFE
  IN A,(C)
  LD HL,KeyXorMask
  XOR (HL)
  BIT 3,A
  RET

; LEFT: port $FBFE bit 0 (Q)
;
; Witness: L1 37050 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
KeyLeft:
  CALL KeyHook
  LD BC,$FBFE
  IN A,(C)
  LD HL,KeyXorMask
  XOR (HL)
  BIT 0,A
  RET

; RIGHT: port $FBFE bit 1 (W)
;
; Witness: L1 41800 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
KeyRight:
  CALL KeyHook
  LD BC,$FBFE
  IN A,(C)
  LD HL,KeyXorMask
  XOR (HL)
  BIT 1,A
  RET

; FIRE: port $DFFE bit 1 (O)
;
; Witness: L1 49911 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
KeyFire:
  CALL KeyHook
  LD BC,$DFFE
  IN A,(C)
  LD HL,KeyXorMask
  XOR (HL)
  BIT 1,A
  RET

; RET: each reader calls it first
;
; Witness: L1 788100 (c1, c1o, deaths, ending, joystick, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r1-rzx-r5).
KeyHook:
  RET

; Not executed in any recording: on a key bit 0 clear, IM 0, the stack and
; return the front saved, Im2Jump back from SavedIm2Jump
;
; All recordings checked. KeyHook's RET at $FCDB keeps it out of reach; with
; the RET replaced by a NOP the readers would run it. Known only from the code
; ($FCDC-$FCF9).
KeyHookExit:
  NOP
  NOP
  IN A,(C)
  BIT 0,A
  RET NZ
  DI
  IM 0
  LD SP,(SavedStack)
  LD HL,(SavedReturn)
  PUSH HL
  LD HL,WorkSpace
  LD DE,Im2Jump
  LD BC,$0003
  LDIR
  RET

; 0 for keys (active low), $FF for a Kempston (active high), written by the
; front
KeyXorMask:
  DEFB $00

; Zeros no code reads (known only from the code)
KeyXorMaskPad:
  DEFB $00,$00,$00,$00,$00
