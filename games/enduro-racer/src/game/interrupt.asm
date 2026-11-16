; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 handler: its own stack, the repair of the two bytes its push wrote, the sound
;
; Every vector of the table at $B200 reads $6464, JR Interrupt. The main code draws with SP as a data pointer
; (DrawRoad pops row addresses from RowTable $FE00, DrawHorizon pushes zeros into the back buffer, BlitRows pops
; rows), so the return address the interrupt pushes lands in that data. Interrupt saves SP in IntSavedSp, takes its
; own stack (IntStack, $6574-$6583), reads the return address from where it was pushed into the operand of the JP at
; IntReturn, and repairs the two bytes: inside RowTable ($FE00-$FF81) it writes back the row address that belongs
; there (RowEntry), anywhere else (the back buffer, where the pushes write zeros) it writes zeros; at the real stack
; ($FF82-$FFFF) it leaves them. It returns by EI and the patched JP, not RET.
;
; Then the sound: a change of TuneRequest at a tune's mark starts the other tune (the two AY channels, PlayChannel) or
; silences it; the channels step every interrupt; EngineSound runs every second one. One entry a frame (c1: 1.00 a
; frame over play).
;
; The repair has a hole: when SP points into the ROM ($0000-$3FFF) the push is lost and the JP returns to the word the
; ROM holds there. DrawRoad does that when the road's top row leaves the table (the stage 3 reset, reset3 frame 6759:
; RoadTopRow = $FF, SP = $00DE + 2n, IntSavedSp = $010A, the JP to $3CBD).
; --------------------------------------------------------------------------------------------------------------------

  ORG $643C

; Save SP, take IntStack, read the return address into IntReturn's JP, push the
; registers
;
; Entered through IntVector ($6464, JR here) on every interrupt in play and the
; menus. IntSavedSp = SP; SP = $6584; AF, BC, DE, HL, IX, IY pushed on
; IntStack. HL = the interrupted SP: the return address is read from (HL) into
; the operand of IntReturn's JP ($6524), IntSavedSp += 2 (the SP to restore),
; HL = the address of the two bytes the push wrote; A = H, and on at IntRepair.
;
; Recorded: c1, m128 and every play recording; 1.00 entries a frame in c1's
; play.
;
; Witness: L1 79550 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
Interrupt:
  LD (IntSavedSp),SP
  LD SP,IntStack+$001E
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  LD HL,(IntSavedSp)
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (IntSavedSp),HL
  DEC HL
  DEC HL
  LD (IntReturn+$0001),DE
  LD A,H
  JP IntRepair

; The AY skid noise: 0 none, else EngineSound's noise period (set by OffRoad,
; the dust on stage 3)
SkidLevel:
  DEFB $00
TuneMark:
  DEFB $02                ; 1 after a tune's $CA mark: the tune may change now
                          ; (PlayChannel sets it, Interrupt clears it)
TuneRequest:
  DEFB $00                ; the tune the game wants: 0 silence, 1 (odd stages)
                          ; or 2 (even), set by SetTune; also gates EngineSound
EffectTime:
  DEFB $00                ; the AY effect's count of interrupts (0: none);
                          ; AyEffectTick counts it down
EffectStep:
  DEFB $00                ; the effect's step, the AY register 10 sweep

; JR Interrupt (the vector of every IM 2 entry); then the repair and the sound
; part of the handler
;
; $6464 is the address every byte of the IM 2 table $B200-$B300 points at
; ($64,$64). The bytes after the JR are the handler's second half, reached by
; Interrupt's JP $6466 (IntRepair).
;
; IntRepair ($6466): H = $FE, or H = $FF and L < $82: RowEntry recomputes the
; address that belongs at that place of RowTable; H elsewhere but $FF: the two
; bytes become 0; the real stack ($FF82 up): nothing. IntSound ($6476):
; TuneRequest against TunePlaying; a change waits for TuneMark, then
; TunePlaying = TuneRequest, and 0 writes AySilence, 1 or 2 starts the tune
; (TuneTable's two streams into ChannelA and ChannelB, as stream and restart,
; counts 1, repeat depths $FF, TuneMark 0, the four pairs of AyTuneStart,
; AyMixer's value $38). A tune playing: on the 128K (Beeper 0) an effect
; (EffectTime) holds the channels (TuneHeld = EffectTime); its end writes
; AyTuneStart and AyMixer again; else both channels step (PlayChannel, ChannelA
; then ChannelB). TuneRequest nonzero: EngineSound. IntExit pops, SP =
; IntSavedSp, EI, JP to the interrupted code.
;
; n < $28: the screen line n's address (LineAddress); n < $40: $EB00 + 32 (n -
; $28), a back buffer row; n >= $40: the screen line n's address + $A600, a
; back buffer row. What SetRowTable left there in play.
;
; Witness: L1 79550 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
IntVector:
  JR Interrupt
; This entry point is used by the routine at Interrupt.
IntRepair:
  CP $FE                  ; A = H of the pushed bytes' address: $FE or $FF
                          ; below $82 is RowTable, elsewhere zeros
  JP Z,RowEntry
  CP $FF
  JP NZ,IntZeroBytes
  LD A,L
  CP $82
  JP C,RowEntry
IntSound:
  LD HL,TunePlaying       ; the tune change, the channels, the engine
  LD A,(TuneRequest)
  CP (HL)
  JR Z,l_64D5
  LD D,A
  LD A,(TuneMark)
  AND A
  JR Z,l_64D5
  LD A,D
  LD (HL),A
  ADD A,A
  JR NZ,l_6495
  LD HL,AySilence
  LD E,$01
  CALL AyWrite
  JR l_650F
l_6495:
  ADD A,A
  LD L,A
  LD H,$00
  LD DE,TuneTable-4
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (ChannelA+$0004),DE
  LD (ChannelA+$0001),DE
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (ChannelB+$0001),DE
  LD (ChannelB+$0004),DE
  XOR A
  LD (TuneMark),A
  LD A,$01
  LD (ChannelB),A
  LD (ChannelA),A
  LD A,$FF
  LD (ChannelA+$0006),A
  LD (ChannelB+$0006),A
  LD E,$04
  LD HL,AyTuneStart
  CALL AyWrite
  LD A,$38
  LD (AyMixer+$0001),A
l_64D5:
  LD A,(TunePlaying)
  AND A
  JR Z,l_650F
  LD A,(Beeper)
  AND A
  JR NZ,l_6501
  LD A,(EffectTime)
  AND A
  JR Z,l_64EC
  LD (TuneHeld),A
  JR l_650F
l_64EC:
  LD A,(TuneHeld)
  AND A
  JR Z,l_6501
  XOR A
  LD (TuneHeld),A
  LD HL,AyTuneStart
  LD E,$04
  CALL AyWrite
  CALL WriteMixer
l_6501:
  LD IX,ChannelA
  CALL PlayChannel
  LD IX,ChannelB
  CALL PlayChannel
l_650F:
  LD A,(TuneRequest)
  AND A
  CALL NZ,EngineSound
IntExit:
  POP IY                  ; pop the registers, SP = IntSavedSp, EI
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  LD SP,(IntSavedSp)
  EI
IntReturn:
  JP $0000                ; JP nn: nn is the interrupted return address,
                          ; written by Interrupt
IntZeroBytes:
  LD (HL),$00             ; outside RowTable: the two bytes the push wrote
                          ; become 0
  INC HL
  LD (HL),$00
  JP IntSound
RowEntry:
  PUSH HL                 ; inside RowTable: entry n = (address - $FE00) / 2
                          ; gets its row address again
  LD DE,$0200
  ADD HL,DE
  AND A
  RR H
  RR L
  LD A,L
  CP $28
  JR NC,l_6542
  CALL LineAddress
  JR l_655F
l_6542:
  CP $40
  JR NC,l_6557
  SUB $28
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,TrackTables
  ADD HL,DE
  EX DE,HL
  JR l_655F
l_6557:
  CALL LineAddress
  LD HL,$A600
  ADD HL,DE
  EX DE,HL
l_655F:
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  JP IntSound

; The handler's stack, $6566-$6585 (SP = $6584 at the entry): six pushes and
; its calls; zeros in the image
;
; WALKTHROUGH 1 (the stack-flagged bytes of c1's L1) gives $6574-$6583 as the
; bytes the handler writes.
IntStack:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
IntSavedSp:
  DEFB $ED,$B0            ; the interrupted SP + 2 (the SP the handler
                          ; restores); the image holds $B0ED, an old value
