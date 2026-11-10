; --------------------------------------------------------------------------------------------------------------------
; tasks.asm: The task switcher
;
; The two tasks' stacks and frame, the switch state (TaskNow, SwitchOff) and Interrupt, the IM 2 handler. The vector
; table $FD00 and the jump $FCFC are at the end of the system module (a module is one stretch of addresses).
; --------------------------------------------------------------------------------------------------------------------

; The simulation task's stack (zeros)
SimStack:
  DEFS $6C

; The simulation task's first frame: 20 bytes of registers, then the entry
SimFrame:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; SimTask: the first switch returns into it
SimEntry:
  DEFW SimTask

; 0 the UI task runs, 1 the simulation
TaskNow:
  DEFB $00
SwitchOff:
  DEFB $00                ; nonzero: the interrupt does not switch tasks (the
                          ; UI's critical parts)
SwitchSpare:
  DEFB $00

; the stacks of the two tasks while the other runs
UiSP:
  DEFW $0000
SimSP:
  DEFW SimFrame

; IM 2: save all registers, ReadInput, then (unless SwitchOff) swap the stack
; with the other task's
;
; Each interrupt, 50 a second, gives the other task the CPU: the UI and the
; simulation run turn by turn, one frame each. c1: L1 407 762, 128 197 / 256
; 388 switches.
Interrupt:
  PUSH IX
  PUSH IY
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  EX AF,AF'
  EXX
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  CALL ReadInput
  LD A,(SwitchOff)
  AND A
  JR NZ,InterruptReturn
  LD HL,TaskNow
  LD A,(HL)
  AND A
  JR Z,InterruptToSim
  LD (SimSP),SP
  LD SP,(UiSP)
  JR InterruptFlip
InterruptToSim:
  LD (UiSP),SP
  LD SP,(SimSP)
InterruptFlip:
  XOR $01
  LD (HL),A
InterruptReturn:
  POP AF
  POP BC
  POP DE
  POP HL
  EX AF,AF'
  EXX
  POP AF
  POP BC
  POP DE
  POP HL
  POP IY
  POP IX
  EI
  RET
