; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The interrupt and its task table, the stars, the keys and the control choice
; --------------------------------------------------------------------------------------------------------------------

; The IM 2 handler: count IntTicks, run the due tasks of TaskTable
;
; For each of the 5 entries (address, switch, counter, reload): when the
; switch's bit 0 is set the counter counts down, and at 0 is reloaded and the
; task called.
;
; Witness: L1 134792 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
Interrupt:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH IY
  PUSH HL
  EX AF,AF'
  PUSH AF
  LD HL,IntTicks
  INC (HL)
  LD HL,TaskTable
  LD B,$05
l_BE36:
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  LD C,(HL)
  INC L
  RRC C
  JR NC,l_BE4E
  DEC (HL)
  JR NZ,l_BE4E
  INC L
  LD A,(HL)
  DEC L
  LD (HL),A
  PUSH BC
  PUSH HL
  CALL RunTask
  POP HL
  POP BC
l_BE4E:
  INC HL
  INC HL
  DJNZ l_BE36
  POP AF
  EX AF,AF'
  POP HL
  POP IY
  POP IX
  POP DE
  POP BC
  POP AF
  EI
  RET

; JP (DE)
;
; Witness: L1 173253 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
RunTask:
  EX DE,HL
  JP (HL)

; The 5 interrupt tasks: address, switch, counter, reload
;
; Task 0 StarTask (off at the entry); tasks 1-3 the sound channels
; SoundTask1-3, every third tick; task 4 CycleTitleColour (off).
TaskTable:
  INCBIN "res/tables/task-table.bin",$0000,25

; Interrupt task 0: move the background stars in the empty cells
;
; Witness: L1 44791 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, ending,
; gameover, hiscore, hiscore-typed, l1-l8).
StarTask:
  LD IX,RowTable+$0004
  LD DE,PlayStarStates
  LD HL,StarFrame
  INC (HL)
l_BE84:
  LD A,(IX+$00)
  AND A
  RET Z
  LD L,A
  LD H,(IX+$01)
  CALL StarStep
  LD BC,$0004
  ADD IX,BC
  JR l_BE84

; Move one star; skip cells with something in them
;
; Witness: L1 851029 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
StarStep:
  LD A,(DE)
  INC E
  LD B,$01
  AND A
  JR Z,l_BEA4
  CP $03
  JR C,l_BEB1
  JR l_BECA
l_BEA4:
  LD B,$04
  LD A,(StarFrame)
  AND $01
  JR Z,l_BECA
  LD B,$40
  JR l_BF0C
l_BEB1:
  LD A,(StarFrame)
  LD B,$20
  AND $03
  JR Z,l_BECA
  LD B,$08
  CP $01
  JR Z,l_BECA
  LD B,$02
  CP $02
  JR Z,l_BECA
  LD B,$80
  JR l_BF0C
l_BECA:
  LD A,(DE)
  INC A
  LD (DE),A
  CP $20
  JR C,l_BEE4
  LD A,L
  XOR $1F
  LD L,A
  XOR A
  LD (HL),A
  INC H
  LD (HL),A
  INC A
  LD (DE),A
  LD A,R
  AND $03
  DEC E
  LD (DE),A
  INC E
  INC E
  RET
l_BEE4:
  LD A,B
  EX AF,AF'
  CALL StarCell
  INC C
  LD A,(BC)
  DEC C
  AND A
  JR NZ,l_BF11
  DEC B
  DEC B
  DEC B
  INC C
  LD A,(BC)
  CP $DC
  JR NC,l_BF06
  INC C
  LD A,(BC)
  DEC C
  CP $DC
  JR NC,l_BF06
  XOR A
  INC L
  LD (HL),A
  INC H
  LD (HL),A
  DEC H
  DEC L
l_BF06:
  INC B
  INC B
  INC B
  DEC C
  JR l_BF11
l_BF0C:
  LD A,B
  EX AF,AF'
  CALL StarCell
l_BF11:
  LD A,(BC)
  AND A
  RET NZ
  DEC B
  DEC B
  DEC B
  LD A,(BC)
  AND A
  RET NZ
  INC C
  LD A,(BC)
  AND A
  RET NZ
  INC C
  LD A,(BC)
  AND A
  RET NZ
  DEC C
  DEC C
  EX AF,AF'
  LD (HL),A
  CP $01
  JR Z,l_BF3E
  CP $04
  JR Z,l_BF32
  CP $40
  JR NZ,l_BF41
l_BF32:
  LD A,B
  SUB $06
  LD B,A
  LD A,R
  AND $06
  ADD A,$41
  LD (BC),A
  RET
l_BF3E:
  RLCA
  OR (HL)
  LD (HL),A
l_BF41:
  INC H
  LD (HL),A
  JR l_BF32

; The star's screen byte and its SolidMap cell
;
; Witness: L1 834718 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; ending, gameover, hiscore, hiscore-typed, l1-l8).
StarCell:
  LD A,(DE)
  INC E
  LD B,$00
  LD C,A
  AND A
  SBC HL,BC
  LD A,(IX+$03)
  ADD A,$29
  LD B,A
  LD C,L
  RET

; Scan the keyboard: the key's half-row and bit when exactly one key is down
;
; Witness: L1 50954 (c1, ending, l1-l8).
ReadKey:
  LD DE,$FF2F
  LD BC,$FEFE

; ReadKeyRow
;
; Used by the routine at ReadKeyNext.
ReadKeyRow:
  IN A,(C)                ; one half-row
  CPL
  AND $1F
  JR Z,ReadKeyNext
  INC D
  RET NZ
  LD H,A
  LD A,E
l_BF66:
  SUB $08
  SRL H
  JR NC,l_BF66
  RET NZ
  LD D,A
  LD L,B

; ReadKeyNext
;
; Used by the routine at ReadKeyRow.
ReadKeyNext:
  DEC E                   ; the next half-row
  RLC B
  JR C,ReadKeyRow
  LD A,D
  AND $38
  RRCA
  RRCA
  RRCA
  PUSH HL
  LD HL,KeyBitTable
  LD B,$00
  LD C,A
  ADD HL,BC
  LD B,(HL)
  POP HL
  LD H,B
  XOR A
  RET

; Wait for exactly one key
;
; Witness: L1 47723 (c1, ending, l1-l8).
WaitKey:
  CALL ReadKey
  JR NZ,WaitKey
  LD A,D
  CP $FF
  JR Z,WaitKey
  RET

; ENTER held: define the six keys by prompts
;
; Witness: L1 6476 (c1, gameover, hiscore).
DefineKeys:
  LD A,$BF
  IN A,($FE)
  RRA
  JR C,SelectControl
  LD HL,$0B41
  CALL PlaySound
  LD IX,DefinedKeys
  LD HL,DefinedKeys
  LD BC,$000C
  CALL ClearBlock
  LD HL,KeyNameLeft
  CALL DefineKey
  LD HL,KeyNameRight
  CALL DefineKey
  LD HL,KeyNameUp
  CALL DefineKey
  LD HL,KeyNameDown
  CALL DefineKey
  LD HL,KeyNameFire
  CALL DefineKey
  LD HL,KeyNameDetach
  CALL DefineKey
  CALL ClearTextRow
  RET

; Prompt for one key and store it
;
; Witness: L1 6 (c1).
DefineKey:
  PUSH HL
  LD C,$05
  LD HL,KeyPromptText
  CALL PrintRow22
  POP HL
  CALL PrintText
l_BFE1:
  CALL ReadKey
  LD A,D
  CP $FF
  JR NZ,l_BFE1
l_BFE9:
  CALL WaitKey
  EX DE,HL
  LD HL,DefinedKeys
  LD B,$06
l_BFF2:
  LD A,E
  CP (HL)
  JR NZ,l_BFFC
  INC L
  LD A,D
  CP (HL)
  JR Z,l_BFE9
  DEC L
l_BFFC:
  INC L
  INC L
  DJNZ l_BFF2
  LD (IX+$00),E
  LD (IX+$01),D
  INC IX
  INC IX
  LD HL,$0B41
  CALL PlaySound
  RET

; Pick the control method by the fire that is pressed
;
; Keys 2, Interface 2 1, Kempston 3 (only when KempstonAbsent is 0), Sinclair
; 4: ControlMethod, and out of the title through the stack.
;
; Witness: L1 123098 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover,
; hiscore).
SelectControl:
  CALL ReadKeys
  BIT 4,A
  JR Z,l_C01C
  LD A,$02
  JR l_C040
l_C01C:
  CALL ReadIf2
  BIT 4,A
  JR Z,l_C027
  LD A,$01
  JR l_C040
l_C027:
  LD A,(KempstonAbsent)
  AND A
  JR NZ,l_C038
  CALL ReadKempston
  BIT 4,A
  JR Z,l_C038
  LD A,$03
  JR l_C040
l_C038:
  CALL ReadCursor
  BIT 4,A
  RET Z
  LD A,$04
l_C040:
  POP BC
  POP BC
  LD (ControlMethod),A
  LD HL,$1983
  CALL PlaySound
  LD HL,$1D82
  CALL PlaySound
  LD HL,$1E81
  CALL PlaySound
  LD B,$07
  CALL WaitFrames
  RET
