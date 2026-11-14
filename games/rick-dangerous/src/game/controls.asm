; --------------------------------------------------------------------------------------------------------------------
; controls.asm: The keys and joysticks: the four control methods, the start, pause and quit keys
;
; ReadInput $A14E turns the selected control method (ControlMethod $A14C, 0-3, chosen with the keys 1-4 on the title
; at $E273-$E2D1) into one active-low byte, InputBits $A14D: bit 0 right, 1 left, 2 down, 3 up, 4 fire. Rick's code
; ($F8DC, $F9A4, $F9C4, $FBC2) reads only that byte.
;
; The methods: 0 keyboard (O up, K down, Z left, X right, ENTER fire), 1 Kempston, 2 cursor keys (5 left, 6 down, 7
; up, 8 right, 0 fire), 3 Sinclair (6 left, 7 right, 8 down, 9 up, 0 fire). Up beats down and left beats right on the
; keyboard; on the cursor keys the 5 (left) is read only when the 8 (right) is not held.
;
; The Kempston method never reads a port: InputKempston $A19F keeps A = 1 (the method number), AND $1F and CPL make
; $FE, so InputBits says "right" for ever and nothing else. The controls recording selected it: 52007 runs of $A1A4.
; Fire is lost too: StartPressed $A123 tests bit 4 of InputBits, always 1 here, so with the Kempston only ENTER starts
; a game. The re-releases (MCM, Erbe, IBSA, whose ZXDB archives hold a file named `Rick Dangerous (MCM)`, TOSEC [a2]
; and the three TOSEC Microdrive `.mdr` transfers) insert `IN A,($1F)` (`DB 1F`) and so fix it; the +3 disk and the
; hacks keep the bug (doc 5, 5.3).
;
; The single-key tests return Z when the key is held: the keys 1-4 (the title's method choice), the start (ENTER, a
; bit 7 of port $FEFE that a standard machine never pulls low, or fire), Q (quit the game, $E3C9) and P (pause, $E3D7:
; wait for the release, the next press and its release).
; --------------------------------------------------------------------------------------------------------------------

  ORG $A103

; Z if the key 1 is held
;
; Reads port $F7FE (keys 1-5) and tests bit 0. Output: A, BC, F. Title only
; ($E273): selects the keyboard (method 0).
;
; Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).
Key1Pressed:
  LD BC,$F7FE
  IN A,(C)
  BIT 0,A
  RET

; Z if the key 2 is held
;
; Port $F7FE bit 1. Title ($E289): selects the Kempston (method 1).
;
; Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).
Key2Pressed:
  LD BC,$F7FE
  IN A,(C)
  BIT 1,A
  RET

; Z if the key 3 is held
;
; Port $F7FE bit 2. Title ($E2A1): selects the cursor keys (method 2).
;
; Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).
Key3Pressed:
  LD BC,$F7FE
  IN A,(C)
  BIT 2,A
  RET

; Z if the key 4 is held
;
; Port $F7FE bit 3. Title ($E2B9): selects the Sinclair joystick (method 3).
;
; Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).
Key4Pressed:
  LD BC,$F7FE
  IN A,(C)
  BIT 3,A
  RET

; Z if ENTER, bit 7 of port $FEFE or the method's fire is held
;
; Tests ENTER (port $BFFE bit 0), then bit 7 of port $FEFE (no key: 1 on a
; standard machine), then calls ReadInput and tests fire (InputBits bit 4).
; Output: A, BC, F; InputBits updated when it gets that far.
;
; Callers: the title ($E219, $E2D1, $E2D7), the level text ($E327, $E32C), the
; game over ($E389, $E38E) and the level's end ($AC38, $AC3D); each waits for
; the release first, then for the press.
;
; Witness: L1 1340688 (beeper48, c1, controls, ending, ending2, gameover,
; l1end, level1-level4).
StartPressed:
  LD BC,$BFFE
  IN A,(C)
  BIT 0,A
  RET Z
  LD BC,$FEFE
  IN A,(C)
  BIT 7,A
  RET Z
  CALL ReadInput
StartFireTest:
  LD A,(InputBits)        ; ReadInput, then bit 4 (fire)
  BIT 4,A
  RET

; Z if Q is held
;
; Port $FBFE bit 0. Called once a game loop pass ($E3C9): Q ends the game (to
; the game over text at $E35A).
;
; Witness: L1 43345 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
QuitPressed:
  LD BC,$FBFE
  IN A,(C)
  BIT 0,A
  RET

; Z if P is held
;
; Port $DFFE bit 0. The game loop ($E3D7-$E3E9): P held waits for its release,
; the next press and that release; the frame loop ($E417) calls it once more
; without using the result.
;
; Witness: L1 244986 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
PausePressed:
  LD BC,$DFFE
  IN A,(C)
  BIT 0,A
  RET

; The control method: 0 keyboard, 1 Kempston, 2 cursor keys, 3 Sinclair
;
; Set by the title's keys 1-4 ($E27F, $E297, $E2AF, $E2C7), read by ReadInput
; and by the title to pick the line to highlight ($E249). 0 in the image.
ControlMethod:
  DEFB $00

; The controls, active low: bit 0 right, 1 left, 2 down, 3 up, 4 fire
;
; Written by ReadInput ($FF, then a RES for each thing held), read by
; StartFireTest and by Rick's code ($F8DC, $F9A4, $F9C4, $FBC2).
InputBits:
  DEFB $00

; Read the selected control method into InputBits
;
; InputBits = $FF, then one RES per direction or fire found held. Method 0
; (keyboard): O ($DFFE bit 1) up, else K ($BFFE bit 2) down; Z ($FEFE bit 1)
; left, else X ($FEFE bit 2) right; ENTER ($BFFE bit 0) fire. Methods 1-3 from
; InputKempston on.
;
; Input: none. Output: A, BC, F; HL preserved. Called by StartPressed and by
; Rick's update ($F86B).
;
; The keyboard ran in c1, controls, gameover and ending; the Kempston in
; controls (and 30 times in c1); the cursor keys in c1, controls and the four
; level recordings; the Sinclair in c1 and controls.
;
; Witness: L1 1332994 (beeper48, c1, controls, emptygun, ending, ending2,
; gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44,
; spotL1Z4-47).
ReadInput:
  PUSH HL
  LD HL,InputBits
  LD (HL),$FF
  LD A,(ControlMethod)
  AND A
  JP NZ,InputKempston
  LD BC,$DFFE
  IN A,(C)
  BIT 1,A
  JP NZ,ReadKeyDown
  RES 3,(HL)
  JP ReadKeyLeft
ReadKeyDown:
  LD BC,$BFFE             ; O not held: K
  IN A,(C)
  BIT 2,A
  JP NZ,ReadKeyLeft
  RES 2,(HL)
ReadKeyLeft:
  LD BC,$FEFE
  IN A,(C)
  BIT 1,A
  JP NZ,ReadKeyRight
  RES 1,(HL)
  JP ReadKeyFire
ReadKeyRight:
  LD BC,$FEFE             ; Z not held: X
  IN A,(C)
  BIT 2,A
  JP NZ,ReadKeyFire
  RES 0,(HL)
ReadKeyFire:
  LD BC,$BFFE
  IN A,(C)
  BIT 0,A
  JP NZ,ReadInputDone
  RES 4,(HL)
ReadInputDone:
  POP HL
  RET

; InputKempston
;
; Used by the routine at ReadInput.
InputKempston:
  CP $01                  ; methods 1-3; method 1: AND $1F and CPL on the
                          ; method number itself, A = $FE: "right" for ever, no
                          ; port read
  JP NZ,InputCursor
  AND $1F
  CPL
  LD (HL),A
  POP HL
  RET
InputCursor:
  CP $02                  ; method 2: port $EFFE (0 9 8 7 6), then $F7FE bit 4
                          ; (5)
  JP NZ,InputSinclair
  LD BC,$EFFE
  IN A,(C)
  BIT 0,A
  JP NZ,CursorRight
  RES 4,(HL)
CursorRight:
  BIT 2,A                 ; 8
  JP NZ,CursorUp
  RES 0,(HL)
CursorUp:
  BIT 3,A                 ; 7, else 6 down
  JP NZ,CursorDown
  RES 3,(HL)
  JP CursorLeft
CursorDown:
  BIT 4,A
  JP NZ,CursorLeft
  RES 2,(HL)
CursorLeft:
  BIT 0,(HL)              ; 5, only when 8 is not held
  JP Z,CursorDone
  LD BC,$F7FE
  IN A,(C)
  BIT 4,A
  JP NZ,CursorDone
  RES 1,(HL)
CursorDone:
  POP HL
  RET
InputSinclair:
  LD BC,$EFFE             ; method 3: port $EFFE: 0 fire, 6 left else 7 right,
                          ; 9 up else 8 down
  IN A,(C)
  BIT 0,A
  JP NZ,SinclairLeft
  RES 4,(HL)
SinclairLeft:
  BIT 4,A
  JP NZ,SinclairRight
  RES 1,(HL)
  JP SinclairUp
SinclairRight:
  BIT 3,A
  JP NZ,SinclairUp
  RES 0,(HL)
SinclairUp:
  BIT 1,A
  JP NZ,SinclairDown
  RES 3,(HL)
  POP HL
  RET
SinclairDown:
  BIT 2,A
  JP NZ,SinclairDone
  RES 2,(HL)
SinclairDone:
  POP HL
  RET
