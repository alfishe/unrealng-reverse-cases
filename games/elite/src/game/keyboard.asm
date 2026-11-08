; --------------------------------------------------------------------------------------------------------------------
; keyboard.asm: The text tables, the key bytes, the keyboard scan, the joysticks, the steering accumulators and the IM2 interrupt
;
; Every frame the IM2 interrupt (IM2Handler, through the vector $FEFE that I = $FD and a floating bus byte $FF give)
; scans the eight keyboard half-rows (ScanKeyboard): each key down sets its bit in one of the key bytes $FC08-$FC0C or
; KeyDigits (KeyTable: an offset and a mask a key) and leaves its character in KeyCode. Then the joystick (Options
; bits 0-1: keyboard, Kempston, Cursor, Sinclair) replaces the four steering bits, Options bits 4 and 5 reverse both
; axes or the vertical one, and ReadControls turns the steering bits into the roll, pitch and speed accumulators the
; flight loop copies (CopyRates). The game code reads and clears the key bytes; nothing else polls the keyboard.
;
; The key bytes: KeyScreens $FC08 (ENTER, L, K, P, O, I, 0, Y), KeySteer $FC09 (N, M, X, S, SPACE, SYMBOL SHIFT),
; KeyViews $FC0A (1-4, H, G, J, CAPS SHIFT), KeyCombat $FC0B (A, T, F, U, E, W, Q, C), KeyChart $FC0C (B, D, R) and
; KeyDigits $FC0F (9, 5, 8, 6, 7). Z and V set no bit. All three recordings steered with the keyboard (Options $8C:
; sound, recentring and damping on): the joysticks are known from the code only.
; --------------------------------------------------------------------------------------------------------------------

; Three bytes no code reads (known from the code only)
TextSpare:
  DEFB $00,$00,$00

; The standard tokens' address ($F11E): PrintCode skips n zero-ended strings
; from it
TokenTable:
  DEFW StdTokens

; The other tokens' address ($F4F5): PrintOther skips n - 1
OtherTable:
  DEFW OtherTokens

; The standard set's 149 strings (tools/tokens.py --set std), each ended by a
; zero
StdTokens:
  INCBIN "res/text/tokens.bin",$0000,983

; The other set's 263 strings (tools/tokens.py --set other): the missions, the
; planet descriptions, the commander menu
OtherTokens:
  INCBIN "res/text/tokens.bin",$03D7,1803

; Eight zero bytes after the tables (known from the code only)
TokensSpare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Keys down: ENTER 1, L 2, K 4, P 8, O $10, I $20, 0 $40 (the joystick's fire),
; Y $80 (the cloak)
KeyScreens:
  DEFB $00

; N 1 (roll left), M 2 (roll right), X 4 (climb), S 8 (dive), SPACE $10
; (faster), SYMBOL SHIFT $20 (slower): the joystick's bits 0-3
KeySteer:
  DEFB $00

; 1-4 bits 0-3 (the views, docked the launch and the trading screens), H $10
; (hyperspace), G $20 (galactic), J $40 (the jump drive), CAPS SHIFT $80
; (pause)
KeyViews:
  DEFB $00

; A 1 (fire), T 2 (target a missile), F 4 (fire the missile), U 8 (unarm), E
; $10 (E.C.M.), W $20 (energy bomb), Q $40 (escape pod), C $80 (docking
; computer)
KeyCombat:
  DEFB $00

; B $10 (the cursor home), D $20 (the distance), R $40 (a planet's name)
KeyChart:
  DEFB $00

; The last key's character (KeyCodes); $FF none, $FE DELETE (CAPS SHIFT with 0)
KeyCode:
  DEFB $FF

; The pause menu's options: bits 0-1 the controls (0 keyboard, 1 Kempston, 2
; Cursor, 3 Sinclair), 2 recentring (R), 3 damping (D), 4 both axes reversed, 5
; the vertical axis reversed, 6 the misjump (F), 7 sound
Options:
  DEFB $8C

; 9 1, 5 2, 8 4, 6 8, 7 $10: the Cursor and Sinclair joysticks' keys
KeyDigits:
  DEFB $00

; ScanKeyboard's row loop end; after the last row the joystick's four bits
; replace KeySteer's, reversed as the options say
;
; Kempston (port $1F): bit 4 the fire (KeyCombat bit 0), bits 0-3 the
; directions, the axes' reversal options inverted. Cursor: KeyDigits / 2 (5
; left, 8 right, 6 down, 7 up). Sinclair: 6 left, 7 right, 8 down, 9 up. Both:
; the 0 key fires. Option bit 4 swaps left with right and down with up, bit 5
; down with up. With the keyboard, a steering key held clears CAPS SHIFT, F and
; C (keys a matrix can ghost from N, M, X, S held together; the reason is not
; stated in the code). Finally 0 with CAPS SHIFT is DELETE ($FE in KeyCode).
; 13398 runs, the keyboard only.
ScanJoystick:
  DEC D
  JP NZ,ScanKeyboardRow
  LD A,(KeySteer)
  AND $0F
  LD D,A
  LD A,(Options)
  LD E,A
  AND $03
  JR Z,ScanJoystickReverse
ScanJoystickKempston:
  DEC A
  JR NZ,ScanJoystickDigits
  LD BC,$FF1F
  IN A,(C)
  BIT 4,A
  JR Z,ScanJoystickKempstonBits
  LD HL,KeyCombat
  SET 0,(HL)
ScanJoystickKempstonBits:
  AND $0F
  LD D,A
  LD A,E
  XOR $30
  LD E,A
  JP ScanJoystickReverse
ScanJoystickDigits:
  DEC A
  LD A,(KeyDigits)
  RRA
  LD D,A
  JR Z,ScanJoystickFire
  LD D,$00
  RL D
  RRA
  RRA
  RL D
  SLA D
  RRA
  RR D
  RRA
  RL D
  RL D
ScanJoystickFire:
  LD HL,KeyScreens
  BIT 6,(HL)
  JR Z,ScanJoystickReverse
  LD HL,KeyCombat
  SET 0,(HL)
ScanJoystickReverse:
  BIT 4,E
  JR Z,ScanJoystickVertical
  LD A,D
  AND $05
  SLA A
  LD C,A
  LD A,D
  AND $0A
  SRL A
  OR C
  LD D,A
ScanJoystickVertical:
  BIT 5,E
  JR Z,ScanJoystickStore
  LD A,D
  AND $03
  LD B,A
  LD A,D
  AND $0C
  LD C,A
  SRL C
  SLA A
  OR C
  AND $0C
  OR B
  LD D,A
ScanJoystickStore:
  LD HL,KeySteer
  LD A,(Options)
  AND $03
  JR NZ,ScanJoystickSteer
  LD A,(HL)
  AND A
  JR Z,ScanJoystickSteer
  INC L
  RES 7,(HL)
  INC L
  RES 2,(HL)
  RES 7,(HL)
  DEC L
  DEC L
ScanJoystickSteer:
  LD A,(HL)
  AND $F0
  OR D
  LD (HL),A
  LD HL,KeyScreens
  BIT 6,(HL)
  RET Z
  RES 6,(HL)
  LD A,(KeyViews)
  AND $80
  RET Z
  LD A,$FE
  LD (KeyCode),A
  RET

; Key E (bit 5 - E) of row D (8 the CAPS SHIFT row): its character into
; KeyCode, its bit into its key byte
;
; The index is bit x 8 + row - 1: KeyCodes gives the character, KeyTable two
; bytes (the offset from $FC08 and the mask). 1203 runs.
KeyPressed:
  PUSH BC
  PUSH AF
  LD A,$05
  SUB E
  SLA A
  SLA A
  SLA A
  ADD A,D
  DEC A
  LD B,A
  SLA B
  LD HL,KeyCodes
  ADD A,L
  JR NC,KeyPressedCode
  INC H
KeyPressedCode:
  LD L,A
  LD A,(HL)
  LD (KeyCode),A
  LD HL,KeyTable
  LD A,L
  ADD A,B
  LD L,A
  LD A,(HL)
  INC HL
  LD B,(HL)
  LD HL,KeyScreens
  ADD A,L
  LD L,A
  LD A,(HL)
  OR B
  LD (HL),A
  POP AF
  POP BC
  RET

; $FE bytes: what is left of a 257-byte IM2 table $FD00-$FE00 (the bytes past
; $FD00 still give $FEFE for a low bus byte)
VectorFiller:
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE

; Each key's character by the index: SPACE, ENTER, P, 0, 1, Q, A, CAPS SHIFT
; (0), then the next bit of each row
KeyCodes:
  DEFM " ",$0D,"P01QA",$00
  DEFM $01,"LO92WSZ"
  DEFM "MKI83EDX"
  DEFM "NJU74RFC"
  DEFM "BHY65TGV"

; The eight half-rows from $FEFE to $7FFE: every key down through KeyPressed;
; KeyDigits 0 and KeyCode $FF first
;
; 13398 runs (every interrupt of c1, f1, w1 and d1); 1203 keys seen down.
ScanKeyboard:
  XOR A
  LD (KeyDigits),A
  DEC A
  LD (KeyCode),A
  LD BC,$7FFE
  LD D,$08

; ScanKeyboardRow
;
; Used by the routine at ScanJoystick.
ScanKeyboardRow:
  RLC B
  IN A,(C)
  AND $1F
  XOR $1F
  LD E,$05
ScanKeyboardBit:
  RRA
  CALL C,KeyPressed
  DEC E
  JR NZ,ScanKeyboardBit
  JP ScanJoystick

; The equipment item of each laser kind 1-4 (5 pulse, 6 beam, 13 military, 14
; mining): read at $FD89 + kind
LaserItems:
  DEFB $05,$06,$0D,$0E

; The status page's colour bands (ColourBands: cells x 8 + rows, a row 0 ends)
StatusBands:
  DEFB $CB,$71,$89,$21,$21,$61,$32,$48

; The inventory's
InventoryBands:
  DEFB $7A,$21,$20

; The other set's 13 two-letter pairs (codes $D7 on); ControlRandomName uses
; those from $FD9B
OtherPairs:
  DEFM "@@ABOUSEITILETSTONLONUTHNO"

; The standard set's 32 pairs (codes $80-$9F), also the system names'
; syllables: AL LE XE GE ZA CE BI SO US ES AR MA IN DI RE A? ER AT EN BE RA LA
; VE TI ED OR QU AN TE IS RI ON, as BBC Elite's
StdPairs:
  DEFM "ALLEXEGEZACEBISO"
  DEFM "USESARMAINDIREA?"
  DEFM "ERATENBERALAVETI"
  DEFM "EDORQUANTEISRION"

; The data screen's colour bands
DataBands:
  DEFB $B2,$42,$3A,$52,$52,$54,$92,$70

; The market prices' colour bands
MarketBands2:
  DEFB $DA,$F1,$F0

; $FE (the filler's last byte)
VectorByte:
  DEFB $FE

; $FEFE: the IM2 vector for the bus byte $FF (I = $FD), the handler's JR at
; $FEFE
IM2Vector:
  DEFW IM2Entry

; In a space view: the steering bits into the accumulators RollControl (N, M),
; PitchControl (X, S), SpeedControl (SPACE, SYMBOL SHIFT); KeySteer cleared
;
; The roll and the pitch are sign and magnitude words (bit 15 the sign): a key
; in the word's direction adds $FF (roll) or $66 (pitch) a frame up to a
; magnitude below $1000, a key against it takes as much off (with recentring,
; option bit 2: straight to 0), and with neither key the magnitude falls by $3C
; or $24 a frame (damping, option bit 3). The speed goes up $A0 a frame with
; SPACE (below $2000) and down with SYMBOL SHIFT (to 0). 13398 runs, 11035 in a
; space view.
ReadControls:
  LD A,(ViewIndex)
  CP $04
  RET NC
  LD A,(KeySteer)
  LD B,A
  LD A,(Options)
  LD C,A
  LD HL,(RollControl)
  BIT 0,B
  JR NZ,ReadControlsLeft
  BIT 1,B
  JR NZ,ReadControlsRight
  BIT 3,C
  JR Z,ReadControlsPitch
  LD DE,$003C
  AND A
  SBC HL,DE
  BIT 6,H
  JR Z,ReadControlsPitch
  LD HL,$0000
  JP ReadControlsPitch
ReadControlsRight:
  LD A,H
  AND $7F
  OR L
  JR NZ,ReadControlsRightMore
  LD HL,$00FF
  JP ReadControlsPitch
ReadControlsRightMore:
  BIT 7,H
  JR Z,ReadControlsRollUp
  JP ReadControlsRollDown
ReadControlsLeft:
  BIT 1,B
  JR NZ,ReadControlsPitch
  LD A,H
  AND $7F
  OR L
  JR NZ,ReadControlsLeftMore
  LD HL,$80FF
  JP ReadControlsPitch
ReadControlsLeftMore:
  BIT 7,H
  JR Z,ReadControlsRollDown
ReadControlsRollUp:
  LD DE,$00FF
  ADD HL,DE
  BIT 4,H
  JR Z,ReadControlsPitch
  AND A
  SBC HL,DE
  JP ReadControlsPitch
ReadControlsRollDown:
  BIT 2,C
  JR Z,ReadControlsRollLess
  LD HL,$0000
  JP ReadControlsPitch
ReadControlsRollLess:
  LD DE,$00FF
  AND A
  SBC HL,DE
  BIT 6,H
  JR Z,ReadControlsPitch
  LD HL,$0000
ReadControlsPitch:
  LD (RollControl),HL
  LD HL,(PitchControl)
  BIT 2,B
  JR NZ,ReadControlsDive
  BIT 3,B
  JR NZ,ReadControlsClimb
  BIT 3,C
  JR Z,ReadControlsSpeed
  LD DE,$0024
  AND A
  SBC HL,DE
  BIT 6,H
  JR Z,ReadControlsSpeed
  LD HL,$0000
  JP ReadControlsSpeed
ReadControlsClimb:
  LD A,H
  AND $7F
  OR L
  JR NZ,ReadControlsClimbMore
  LD HL,$0066
  JP ReadControlsSpeed
ReadControlsClimbMore:
  BIT 7,H
  JR Z,ReadControlsPitchUp
  JP ReadControlsPitchDown
ReadControlsDive:
  BIT 3,B
  JR NZ,ReadControlsSpeed
  LD A,H
  AND $7F
  OR L
  JR NZ,ReadControlsDiveMore
  LD HL,$8066
  JP ReadControlsSpeed
ReadControlsDiveMore:
  BIT 7,H
  JR Z,ReadControlsPitchDown
ReadControlsPitchUp:
  LD DE,$0066
  ADD HL,DE
  BIT 4,H
  JR Z,ReadControlsSpeed
  AND A
  SBC HL,DE
  JP ReadControlsSpeed
ReadControlsPitchDown:
  BIT 2,C
  JR Z,ReadControlsPitchLess
  LD HL,$0000
  JP ReadControlsSpeed
ReadControlsPitchLess:
  LD DE,$0066
  AND A
  SBC HL,DE
  BIT 6,H
  JR Z,ReadControlsSpeed
  LD HL,$0000

; ReadControlsSpeed
;
; Used by the routine at ReadControls.
ReadControlsSpeed:
  LD (PitchControl),HL
  LD HL,(SpeedControl)
  LD DE,$00A0
  BIT 4,B
  JR NZ,ReadControlsFaster
  BIT 5,B
  JR Z,ReadControlsDone
  AND A
  SBC HL,DE
  JR ReadControlsSlower

; The address the vector gives: JR IM2Handler
IM2Entry:
  JR IM2Handler
; This entry point is used by the routine at ReadControlsSpeed.
ReadControlsFaster:
  BIT 5,B
  JR NZ,ReadControlsDone
  ADD HL,DE
  JP ReadControlsFasterCap

; The roll accumulator (sign and magnitude): its high byte $FF09 is the roll
; rate CopyRates takes
RollControl:
  DEFW $0000

; The pitch accumulator, the rate in $FF0B
PitchControl:
  DEFW $0000

; The speed accumulator, the speed in $FF0D
SpeedControl:
  DEFW $0000

; ReadControlsSlower
;
; Used by the routine at ReadControlsSpeed.
ReadControlsSlower:
  JR NC,ReadControlsDone
  LD HL,$0000
  JP ReadControlsDone
; This entry point is used by the routine at IM2Entry.
ReadControlsFasterCap:
  BIT 5,H
  JR Z,ReadControlsDone
  AND A
  SBC HL,DE
; This entry point is used by the routines at ReadControlsSpeed and IM2Entry.
ReadControlsDone:
  LD (SpeedControl),HL
  XOR A
  LD (KeySteer),A
  RET

; The interrupt: its own stack below $FFBF, the registers saved, ScanKeyboard,
; ReadControls and the sound (SoundTickVector)
;
; 13398 runs: one a frame. SP is kept in IM2SavedSP.
IM2Handler:
  DI
  LD (IM2SavedSP),SP
  LD SP,$FFBF
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  PUSH IX
  PUSH IY
  CALL ScanKeyboard
  CALL ReadControls
  CALL SoundTickVector
  POP IY
  POP IX
  POP AF
  POP BC
  POP DE
  POP HL
  LD SP,(IM2SavedSP)
  EI
  RET

; I = $FD, IM 2 (known from the code only: it ran before the recordings
; started)
IM2On:
  LD A,$FD
  LD I,A
  IM 2
  RET

; IM 1 (for the tape routines in the ROM; known from the code only)
IM1On:
  IM 1
  RET

; The interrupted program's SP
IM2SavedSP:
  DEFW $0000

; Each key's (offset from $FC08, mask) by the index; Z and V have the mask 0
KeyTable:
  DEFB $01,$10
  DEFB $00,$01
  DEFB $00,$08
  DEFB $00,$40
  DEFB $02,$01
  DEFB $03,$40
  DEFB $03,$01
  DEFB $02,$80
  DEFB $01,$20
  DEFB $00,$02
  DEFB $00,$10
  DEFB $07,$01
  DEFB $02,$02
  DEFB $03,$20
  DEFB $01,$08
  DEFB $00,$00
  DEFB $01,$02
  DEFB $00,$04
  DEFB $00,$20
  DEFB $07,$04
  DEFB $02,$04
  DEFB $03,$10
  DEFB $04,$20
  DEFB $01,$04
  DEFB $01,$01
  DEFB $02,$40
  DEFB $03,$08
  DEFB $07,$10
  DEFB $02,$08
  DEFB $04,$40
  DEFB $03,$04
  DEFB $03,$80
  DEFB $04,$10
  DEFB $02,$10
  DEFB $00,$80
  DEFB $07,$08
  DEFB $07,$02
  DEFB $03,$02
  DEFB $02,$20
  DEFB $3C,$00
