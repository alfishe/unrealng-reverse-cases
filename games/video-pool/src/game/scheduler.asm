; --------------------------------------------------------------------------------------------------------------------
; scheduler.asm: The task scheduler of the interrupt: 25 slots, add, remove, clear
;
; A task is a routine with a period: the scheduler calls it when its countdown goes below zero and reloads the
; countdown with the period, so a period p runs it every p + 1 interrupts (0: every one). A slot whose high byte is 0
; is free.
; --------------------------------------------------------------------------------------------------------------------

; The scheduler: count each slot down, call the routines whose time has come
;
; Called by Im2Handler on every interrupt (w1 9536 entries). Each of the 25
; slots of TaskSlots: skip if free; count +3 down; at -1 call the routine
; (CallTask, JP (HL)) and reload +3 from +2. Tasks run in slot order (the order
; they were added). w1: 34 301 task calls.
RunTasks:
  LD IX,TaskSlots
  LD B,$19
RunTasksLoop:
  LD A,(IX+$01)           ; the next slot
  OR A
  JR Z,RunTasksNext
  DEC (IX+$03)
  JP P,RunTasksNext
  LD L,(IX+$00)
  LD H,(IX+$01)
  PUSH IX
  PUSH BC
  CALL CallTask
  POP BC                  ; reload the countdown
  POP IX
  LD A,(IX+$02)
  LD (IX+$03),A
RunTasksNext:
  INC IX                  ; 4 bytes a slot
  INC IX
  INC IX
  INC IX
  DJNZ RunTasksLoop
  RET

; JP (HL)
;
; Used by the routine at RunTasks.
CallTask:
  JP (HL)

; Put routine HL with period C into the first free slot
;
; Countdown 0, so it first runs at the next interrupt. No free slot: nothing
; (25 are never all used). w1: 252 calls.
AddTask:
  LD IX,TaskSlots
  LD B,$19
AddTaskLoop:
  LD A,(IX+$01)
  OR A
  JR Z,AddTaskFree
  INC IX
  INC IX
  INC IX
  INC IX
  DJNZ AddTaskLoop
  RET
AddTaskFree:
  LD (IX+$00),L           ; the free slot
  LD (IX+$01),H
  LD (IX+$02),C
  LD (IX+$03),$00
  RET

; Free the slot of routine HL
;
; The first slot whose address is HL gets high byte 0. w1: 252 calls.
RemoveTask:
  LD IX,TaskSlots
  LD B,$19
RemoveTaskLoop:
  LD A,(IX+$00)
  CP L
  JR NZ,RemoveTaskNext
  LD A,(IX+$01)
  CP H
  JR NZ,RemoveTaskNext
  LD (IX+$01),$00
  RET
RemoveTaskNext:
  INC IX                  ; the next slot
  INC IX
  INC IX
  INC IX
  DJNZ RemoveTaskLoop
  RET

; Free all 25 slots (DI while it clears)
;
; Called by BreakRestart (one a BREAK) and by the editor. Zeros the 100 bytes
; of TaskSlots.
ClearTasks:
  DI
  LD HL,TaskSlots
  LD DE,TaskSlots+$0001
  LD BC,$0063
  LD (HL),$00
  LDIR
  EI
  RET

; 25 task slots: the routine (0 high byte = free), the period, the countdown
;
; Written by AddTask, RemoveTask, ClearTasks; read by RunTasks every interrupt.
TaskSlots:
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
