; --------------------------------------------------------------------------------------------------------------------
; hud.asm: the frame work of the panel: colour cycles, the speed bar, the fuel gauge
;
; PanelFrame runs once a frame from the play interrupt ($AA87 in the handler $A9ED) and only writes attributes of the
; panel's rows 20-23 ($5A80-$5AFF): it never touches pixels, so it costs nothing in the drawing code. 659 entries in
; c2, one a frame of play.
;
; What it shows: two cells at $5AC6 whose ink steps every fourth frame; the speed bar at $5AEE (one to four lit cells
; for the speeds $40-$A0, the player record's +$0B); the fuel gauge, two pairs of lamps at $5AC1 and $5ADD that go
; dark one by one as Fuel ($80E6) falls below $40 and $20; two colour blocks at $5A81 and $5A9D through $A8BE with a
; phase and a bouncing value ($7F78-$7F7A); and every other frame the burst of $7F77 (set to 6 when the player loses a
; life, $9C80): a pair of cells that walks out from column 15 of rows 21-22 while the counter runs down.
;
; CheckPauseAndEnd, the play interrupt's check of the key 4 (pause) and of a pending end code (from the phase dispatch
; at $AA96, once a frame of play), and StopAndSettle, which silences the effect and lets two frames pass under
; TitleInterrupt, are kept here: the pause runs inside the interrupt, so the play loop and the effect stand still
; under it.
; --------------------------------------------------------------------------------------------------------------------

; the panel's attribute work of one frame of play
;
; Called from PlayInterrupt $A9ED (at $AA87) once a frame; c2: 659 entries in
; 659 frames, 630704 T own (6 permille of the recording). Reads PassCount
; $7F62, the player record ($7F99: +$0B speed), Fuel $80E6, $7F77-$7F7A; writes
; only the attribute rows 20-23.
;
; 1. The ink of $5AC6-$5AC7 + 1 every fourth frame (PassCount & 3 = 0), kept in
; 0-7 with the paper and bright bits (AND $C7 drops the carry into paper).
;
; 2. The speed bar: $5AEE-$5AF1 = $01, then (speed >> 5) - 1 cells of $31 from
; $5AEE: one lit cell at $40 up to four at $A0, the top speed (FuelOut keeps it
; from going below $40, which would make B = 0 and the DJNZ write 256 cells).
;
; 3. The fuel lamps: DE = $3131 at $5AC1 and $5ADD; Fuel < $40 darkens D, < $20
; darkens E too.
;
; 4. The two colour blocks: PanelPhase $7F78 + (PassCount & 1) in 0-15 (C),
; PanelBounce $7F79 + PanelStep $7F7A on odd frames, the step reversed at 7 or
; 1 of the low 3 bits; $A8BE draws A at $5A81 and $5A9D with C.
;
; 5. On even frames: rows 21-22 columns 11-20 ($5AAB, $5ACB) cleared;
; PanelBurst $7F77 not 0: counted down, its new value n written as the
; attribute at columns 15+n and 16-n of both rows (the pair moves out as n
; falls and goes black at 0).
PanelFrame:
  LD A,(PassCount)        ; PassCount
  AND $03
  LD C,$01
  JR Z,PanelInkCells      ; C = 1 every fourth frame, else 0
  DEC C
PanelInkCells:
  LD HL,$5AC6             ; the two cells at row 22, columns 6-7
  LD B,$02
PanelInkStep:
  LD A,(HL)               ; ink + C, the bright and paper bits kept
  ADD A,C
  AND $C7
  LD (HL),A
  INC L
  DJNZ PanelInkStep
  LD IX,(PlayerRecord)    ; the current player's record
  LD A,(IX+$0B)           ; the speed: $20 a step in the top 3 bits
  AND $E0
  RLCA                    ; three RLCAs: the top 3 bits into bits 0-2
  RLCA
  RLCA
  DEC A                   ; the lit cells: the speed step less one
  LD B,A
  LD HL,$0101             ; the four bar cells unlit first
  LD ($5AEE),HL
  LD ($5AF0),HL
  LD HL,$5AEE             ; then B cells of $31 (blue ink on cyan paper: lit)
PanelSpeedBar:
  LD (HL),$31
  INC L
  DJNZ PanelSpeedBar
  LD DE,$3131             ; both lamps of each pair lit
  LD A,(Fuel)             ; Fuel: $5A at a level start and after each FuelOut,
                          ; $B4 when the pod selector wraps past the fifth pod
                          ; ($A237)
  CP $40
  JR NC,PanelFuelLamps
  LD D,$01                ; below $40: the first lamp of each pair dark
  CP $20
  JR NC,PanelFuelLamps
  LD E,$01                ; below $20: the second as well
PanelFuelLamps:
  LD ($5AC1),DE           ; the pairs at row 22 column 1 and row 22 column 29
  LD ($5ADD),DE
  LD A,(PassCount)        ; PanelPhase + (PassCount & 1), 0-15
  AND $01
  LD HL,SpinnerFrame
  ADD A,(HL)
  AND $0F
  LD (HL),A
  LD C,A
  LD HL,SpinnerColour     ; PanelBounce: moved by PanelStep on odd frames
  LD A,(PassCount)
  AND $01
  JR Z,PanelBlocks
  LD A,(SpinnerColourStep)
  ADD A,(HL)
  LD (HL),A
  AND $07                 ; at 7 or 1 of its low bits the step turns
  CP $07
  JR Z,PanelTurn
  CP $01
  JR NZ,PanelBlocks
PanelTurn:
  LD A,(SpinnerColourStep) ; PanelStep = -PanelStep
  NEG
  LD (SpinnerColourStep),A
PanelBlocks:
  LD A,(HL)               ; A = PanelBounce, C = PanelPhase: $A8BE paints the
                          ; blocks at row 20 columns 1 and 29
  LD HL,$5A81
  PUSH AF
  PUSH BC
  CALL DrawSpinner
  POP BC
  POP AF
  LD HL,$5A9D
  CALL DrawSpinner
  LD A,(PassCount)        ; the burst only on even frames
  AND $01
  RET NZ
  LD HL,$5AAB             ; clear rows 21-22, columns 11-20
  LD DE,$5ACB
  LD B,$0A
  XOR A
PanelClearRow:
  LD (HL),A
  LD (DE),A
  INC L
  INC E
  DJNZ PanelClearRow
  LD HL,PanelBurst        ; PanelBurst: 0 = idle
  LD A,(HL)
  AND A
  RET Z
  DEC A                   ; one step less; the new value is both the colour and
                          ; the distance
  LD (HL),A
  LD C,A
  LD B,A
  LD H,$5A
  LD DE,$0020
  LD A,$AF                ; column 15 + n on row 21 and row 22
  ADD A,C
  LD L,A
  LD (HL),B
  ADD HL,DE
  LD (HL),B
  SUB C                   ; column 16 - n on both rows
  SUB C
  INC A
  LD L,A
  LD (HL),B
  ADD HL,DE
  LD (HL),B
  RET

; key 4 pauses; a pending end code ends the play loop
;
; Called by the play interrupt once a frame (the phase dispatch in the routine
; at $AA96; c2: 659 entries in 659 frames). Key 4 (half row $F7FE, bit 3) calls
; Pause ($B197). Then a pending end code in EndPending ($7F7C: 1 a life lost, 2
; the level done, 4 abort) is moved to EndCode ($7F7D), which ends the play
; loop at $B1E9, the interrupt handler ($FDFE) becomes TitleInterrupt $A9E4 (it
; only sets $7F96 = $80, no frame work) and StopAndSettle silences the effect.
; Returns with A = 0 when nothing is pending.
CheckPauseAndEnd:
  LD A,$F7                ; the half row 1-5
  IN A,($FE)
  BIT 3,A                 ; key 4 down (0)
  CALL Z,Pause
  LD A,(EndPending)       ; EndPending: set by the death code ($9B5B), the
                          ; level's end command ($AE40) and Pause (Q)
  AND A
  RET Z
  LD (EndCode),A          ; EndCode: the play loop sees it
  LD HL,TitleInterrupt    ; TitleInterrupt: no frame work from here on
  LD (InterruptHandler),HL
  CALL StopAndSettle
  RET

; silence the effect and let two frames pass under TitleInterrupt
;
; Requests effect 0 (RequestEffect $B2F0 takes 0 as $80: the stop), keeps
; InterruptHandler ($FDFE), installs TitleInterrupt $A9E4, two HALTs with
; interrupts on, DI and Handler back. Called by CheckPauseAndEnd and Pause; c2:
; 2 entries (one pause and one end in the play recording).
StopAndSettle:
  XOR A                   ; effect 0: stop the running one
  CALL RequestEffect
  LD DE,(InterruptHandler) ; the handler in use
  LD HL,TitleInterrupt
  LD (InterruptHandler),HL
  EI                      ; two frames under TitleInterrupt: its EffectTick =
                          ; $80 makes a playing effect take the stop
  HALT
  HALT
  DI                      ; back to the old handler with interrupts off
  LD (InterruptHandler),DE
  RET
