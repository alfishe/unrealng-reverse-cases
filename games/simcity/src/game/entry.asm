; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The keyboard rows and the entry
;
; The first bytes of code2: the eight keyboard half rows the interrupt reads every frame (ReadInput $F781) and the
; joysticks fold into, then the entry the mover jumps to: the stack, the Kempston test, IM 2 with I = $FD (the vector
; table $FD00, the task switcher Interrupt $F70B), the start menu.
; --------------------------------------------------------------------------------------------------------------------

; The keyboard's eight half rows, as IN read them in the last interrupt (0 =
; pressed, bits 0-4)
;
; ReadInput $F781 writes them every frame from ports $FEFE, $FDFE, $FBFE,
; $F7FE, $EFFE, $DFFE, $BFFE, $7FFE (in that order), then ReadKempston $7A01
; and ReadSinclair $7A32 clear the Q, A, O, P and SPACE bits when a joystick is
; pushed, so every reader sees one keyboard. Row 0 bit 0 CAPS SHIFT, row 1 bit
; 0 A (down), row 2 bit 0 Q (up), row 5 bit 0 P (right) and bit 1 O (left), row
; 7 bit 0 SPACE (fire) and bit 1 SYMBOL SHIFT. L1: 3 264 254 writes (8 a
; frame), 5 764 078 reads with KeyNone and BitMasks.
KeyRows:
  DEFB $FF
KeyRowA:
  DEFB $FF                ; $FDFE: A S D F G
KeyRowQ:
  DEFB $FF                ; $FBFE: Q W E R T
KeyRow1:
  DEFB $FF                ; $F7FE: 1 2 3 4 5
KeyRow0:
  DEFB $FF                ; $EFFE: 0 9 8 7 6
KeyRowP:
  DEFB $FF                ; $DFFE: P O I U Y
KeyRowEnter:
  DEFB $FF                ; $BFFE: ENTER L K J H
KeyRowSpace:
  DEFB $FF                ; $7FFE: SPACE SYMBOL SHIFT M N B
KeyNone:
  DEFB $FF                ; a ninth row, always $FF: ScanKey reads nine rows
PortHighs:
  DEFB $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F ; leftover: the eight port high bytes
                                       ; $FE-$7F; no code reads them (L1: 0
                                       ; reads)
BitMasks:
  DEFB $80,$40,$20,$10,$08,$04,$02,$01 ; $80, $40, ... $01: the bit of a
                                       ; column, read by the drawing of bars
                                       ; and graphs (L1: 1 415 565 reads)
EntryJump:
  DEFB $18,$00            ; JR $5B1B, two bytes no code runs (L1: never
                          ; executed): the entry is reached by JP $5B1B

; The game's entry: stack, black border, the Kempston test, IM 2 with I = $FD,
; then MainMenu
;
; MoveCode2 $5000 jumps here. SP = $F6C2 (the UI task's stack), the border
; black, NoSwitch $F705 = 1 (no task switch until the simulation task is set
; up), then the Kempston test: port $1F is read up to 32 768 times; a value $1F
; or more (a floating bus gives $FF) means no interface, otherwise
; KempstonFound = 1. Then I = $FD (the vector table ImTable $FD00, every vector
; $FCFC), IM 2, EI and JP MainMenu $8FA0.
;
; c1: L1 1 at frame 16 280; the loop ran 32 768 times (no Kempston in c1's
; setup); the ports recording sets KempstonFound (stage 1). No other code
; changes I or the mode.
Entry:
  DI
  LD SP,SimStack+$0040
  XOR A
  OUT ($FE),A
  LD A,$01
  LD (SwitchOff),A
  XOR A
  LD (KempstonFound),A
  LD HL,PowerFloodBudget+$0003
KempstonTest:
  IN A,($1F)              ; IN A,($1F): below $1F an interface answers
  CP $1F
  JR NC,SetIm2
  DEC HL
  LD A,H
  OR L
  JR NZ,KempstonTest
  LD A,$01
  LD (KempstonFound),A
SetIm2:
  LD A,$FD                ; I = $FD, IM 2, EI, JP MainMenu
  LD I,A
  IM 2
  EI
  JP UiTask
