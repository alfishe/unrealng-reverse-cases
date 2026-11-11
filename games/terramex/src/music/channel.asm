; --------------------------------------------------------------------------------------------------------------------
; channel.asm: A channel's frame: the events of its order list and its patterns
;
; Each channel has an order list (the tune's entry gives its three addresses) of bytes: $00-$7F play pattern n
; (PatternLo $CA37 / PatternHi $CA52, 27 patterns); $80 t: transpose t (signed semitones) for the following patterns;
; $A0+n: play the next pattern n times (n 0: 256); $C0 d: detune d (0-255, added to the 16-bit period) for the
; following notes; $E0+n m: instrument slot n of this channel = record offset m (SlotTable); $FF: the tune's end
; (EndTune $C780, from whichever channel meets it first: channel A in tune 0). Bits 0-4 of a command byte are its
; parameter, bits 5-6 pick the handler (ReadOrderList $C310), so $81-$9F take a byte as $80 does, and $C1-$DF as $C0.
;
; A pattern (PatternEvent $C36D) is a string of events ended by $FF: $00-$7F n, d: a note (period-table index n + 20 +
; transpose) lasting d frames (d 0: 256); $A0 d: a rest of d frames (period 0, the volume left as it was); $80-$8F:
; instrument slot 0-15 (SetInstrument $C3D8: SlotTable row of the channel); $90-$9F, $A1-$BE: arpeggio n = the low
; nibble (record 8n of ArpeggioTable $C927, 0 off); $BF: the slide off; $C0-$FE s lo hi c: a slide (SlideEffect $C72F)
; with delay s & $1F frames after each note start, step hi:lo (halved), count c frames ($FF endless; a finite slide
; stops at the next note), direction bit 5 (1: period up, the pitch falls). Events other than notes and rests take no
; time: a channel reads on until a note or a rest.
;
; Timing: a note or rest of d frames is read on frame t, its timer counts down, and the next event is read on frame t
; + d (UpdateTune ends the note when the timer is 1). A channel starts on EmptyPattern $C82D ($FF), so its first frame
; goes to the order list. The tune is a fixed grid: tune 0's channels A and B take 9696 frames, its channel C 10 236
; (its last 540 frames are never heard: channel A's end stops the tune first).
; --------------------------------------------------------------------------------------------------------------------

  ORG $C2E4

; Play one frame of the channel IX: the next event when its note is over, else
; the effects
;
; In: IX = the channel record, DE = its pattern (PatternPointers), the
; order-list operands and SlotRowOp set by UpdateTune $C1E4. Timer (+$03) not
; 0: CheckGateOff $C555 (the effects). Timer 0: a slide whose count is not $FF
; ends (+$11 = 0), then ReadPatternEvent $C2F6.
;
; Called 3 times a frame by UpdateTune (explorers: 45 565 = 3 x 15 189 less 2,
; the frame of EndTune).
;
; Witness: L1 250815 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
UpdateChannel:
  LD A,(IX+$03)
  OR A
  JP NZ,CheckGateOff      ; a note or a rest is running
  LD A,(IX+$11)           ; the slide count: $FF keeps it, any other value ends
                          ; it
  CP $FF
  JR Z,ReadPatternEvent
  LD (IX+$11),$00

; Read the byte at the channel's pattern position: an event, or the pattern's
; end
;
; HL = DE + the pattern position (+$02). Not $FF: PatternEvent $C36D. $FF:
; repeats left (+$04 not 0): one less, the position 0, read again; else
; ReadOrderList $C310. Reached from UpdateChannel $C2E4 and, after each event
; that takes no time, from PatternEvent's handlers and StartPattern $C34A.
;
; Witness: L1 21280 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
ReadPatternEvent:
  LD L,(IX+$02)
  LD H,$00
  ADD HL,DE
  LD A,(HL)
  CP $FF                  ; $FF: the pattern's end
  JR NZ,PatternEvent
  LD A,(IX+$04)           ; repeats left: the pattern again from its start
  OR A
  JR Z,ReadOrderList
  DEC (IX+$04)
  LD (IX+$02),$00
  JR ReadPatternEvent

; Read the channel's next order-list byte: a pattern, a command or the tune's
; end
;
; The byte at the order list (the self-modified operand of OrderListOp1) + the
; position (+$00), the position one on. $FF: EndTune $C780. $00-$7F:
; StartPattern $C34A. $80-$FE: CommandParam $C1E0 = the low 5 bits; bits 5-6 x
; 4 into the JR offset at OrderCommandJump+1: $80-$9F SetTranspose $C7E4,
; $A0-$BF SetRepeat $C81B (OrderJumpRepeat $C33F), $C0-$DF SetDetune $C7D1
; (OrderJumpDetune $C343), $E0-$FE SetSlot $C7F7 (OrderJumpSlot $C347). Each
; handler comes back here for the next byte.
;
; Witness: L1 873 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
ReadOrderList:
  LD L,(IX+$00)
  LD H,$00
OrderListOp1:
  LD BC,Tune0OrderA       ; LD BC,nn: nn = the channel's order list
                          ; (self-modified by UpdateTune; the image holds tune
                          ; 0's channel A)
  ADD HL,BC
  LD A,(HL)
  INC (IX+$00)
  CP $FF                  ; $FF: the tune's end
  JP Z,EndTune
  BIT 7,A                 ; bit 7 clear: a pattern number
  JP Z,StartPattern
  LD L,A                  ; a command: the parameter, then bits 5-6 as the jump
  AND $1F
  LD (CommandParam),A
  LD A,L
  AND $60
  SRL A
  SRL A
  SRL A
  LD (OrderCommandJump+$0001),A
OrderCommandJump:
  JR OrderCommandJump     ; JR d: d = 0, 4, 8 or 12 (self-modified at $C336;
                          ; the image holds $FE, a jump to itself)
  JP SetTranspose         ; d = 0, $80-$9F: SetTranspose

; A filler byte: the jump table's entries are 4 bytes apart
;
; Never executed or read: JR d lands on the JP after it (known only from the
; code).
OrderJumpPad1:
  DEFB $00

; d = 4, $A0-$BF: SetRepeat
;
; Witness: L1 123 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
OrderJumpRepeat:
  JP SetRepeat

; A filler byte between the jumps
;
; Never executed or read (known only from the code).
OrderJumpPad2:
  DEFB $00

; d = 8, $C0-$DF: SetDetune
;
; Witness: L1 17 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
OrderJumpDetune:
  JP SetDetune

; A filler byte between the jumps
;
; Never executed or read (known only from the code).
OrderJumpPad3:
  DEFB $00

; d = 12, $E0-$FE: SetSlot
;
; Witness: L1 21 (explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
OrderJumpSlot:
  JP SetSlot

; Start pattern A on the channel
;
; A = the pattern number (0-26, from ReadOrderList $C310).
; PatternPointers[ChannelIndex] = DE = PatternLo[A] + 256 x PatternHi[A]; the
; pattern position (+$02) = 0; ReadPatternEvent $C2F6. A new entry: the cut had
; it inside OrderJumpSlot's block; it is ReadOrderList's JP Z target at $C324.
;
; Witness: L1 479 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
StartPattern:
  LD C,A
  LD A,(ChannelIndex)     ; E = 2 x the channel, the PatternPointers offset
  ADD A,A
  LD E,A
  LD D,$00
  LD B,D
  LD HL,PatternLo         ; the pattern's address from PatternLo and PatternHi
  ADD HL,BC
  LD A,(HL)
  LD HL,PatternHi
  ADD HL,BC
  LD B,(HL)
  LD HL,PatternPointers   ; into PatternPointers, and DE
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),B
  LD E,A
  LD D,B
  LD (IX+$02),$00         ; from its first byte
  JP ReadPatternEvent

; Act on pattern byte A: a note, a rest, an instrument, an arpeggio or a slide
;
; A = the byte (not $FF), from ReadPatternEvent $C2F6. $00-$7F: StartNote
; $C4C9. $A0 d: a rest: the rest timer (+$16) and the note timer = d, the
; period 0, then ChannelEffects $C55E counts the first frame. $80-$8F:
; SetInstrument $C3D8. $90-$BE (but $A0): the arpeggio record 8 x (A & $0F)
; into +$10; $BF: the slide count 0. $C0-$FE: the slide: +$15 = A, its delay
; +$14 = A & $1F, then the step low (+$12), high (+$13) and the count (+$11).
; Each but the note and the rest goes on to the next byte (ReadPatternEvent). A
; new entry: the cut had it inside OrderJumpSlot's block; it is
; ReadPatternEvent's JR NZ target at $C2FF.
;
; The slide and the slide-off code ($C397-$C3C8) was not executed in any of the
; 34 recordings: only patterns 1 and 4 hold a slide, and tune 0 plays neither.
;
; Witness: L1 19804 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PatternEvent:
  BIT 7,A
  JP Z,StartNote
  CP $A0                  ; $A0: a rest, its duration next
  JR NZ,PatternEventCommand
  INC (IX+$02)
  CALL FetchPatternByte
  LD (IX+$16),A
  LD (IX+$03),A
  INC (IX+$02)
  XOR A                   ; a rest plays period 0
  LD (IX+$1D),A
  LD (IX+$1E),A
  JP ChannelEffects
PatternEventCommand:
  CP $90                  ; $80-$8F an instrument, $90-$BF an arpeggio, $C0-$FE
                          ; a slide
  JR C,SetInstrument
  CP $C0
  JR C,PatternEventArpeggio
  LD (IX+$15),A           ; the slide: the command byte, the delay, the step
                          ; and the count
  AND $1F
  LD (IX+$14),A
  INC (IX+$02)
  CALL FetchPatternByte
  LD (IX+$12),A
  INC (IX+$02)
  CALL FetchPatternByte
  LD (IX+$13),A
  INC (IX+$02)
  CALL FetchPatternByte
  LD (IX+$11),A
  INC (IX+$02)
  JP ReadPatternEvent
PatternEventArpeggio:
  CP $BF                  ; $BF: the slide off
  JR NZ,PatternEventSetArp
  LD (IX+$11),$00
  JR PatternEventNext
PatternEventSetArp:
  AND $0F                 ; the arpeggio record: 8 x the low nibble
  ADD A,A
  ADD A,A
  ADD A,A
  LD (IX+$10),A
PatternEventNext:
  INC (IX+$02)            ; the next byte
  JP ReadPatternEvent

; Instrument slot A & $0F: set the channel's mixer bits, envelope, gate-off
; time and vibrato
;
; A = $80-$8F (from PatternEvent $C36D). IY = Instruments + SlotTable[8 x
; channel + (A & $0F)] (SlotRowOp: the channel's 8 x n). The peak volume (+$2B)
; = record +8. MixerImage $C14E: record +2 bit 7 set: the channel's noise on,
; tone off; clear: tone on, noise off. The attack (step +$24, rate +$25) from
; the high nibble of +3 through AttackRates $CD36, the decay (+$21, +$22) from
; its low nibble, the sustain level (+$20) from the high nibble of +4, the
; release (+$27, +$28) from its low nibble, the last three through DecayRates
; $CD46; a rate byte with bit 7 is "one step every (byte & $7F) frames", the
; step 1, else "the byte's steps every frame"; nibble 0 is the step 15 every
; frame. +5 the gate-off time (+$06), +7 the vibrato record (+$0B). Then the
; next pattern byte (ReadPatternEvent $C2F6). A new entry, for the cut's l_C3D8
; inside OrderJumpSlot's block (PatternEvent's JR C at $C391).
;
; The slow attack ($C452) and the release with a step table entry below $80
; ($C4A9) was not executed in any of the 34 recordings: no instrument has them.
;
; Witness: L1 2250 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
SetInstrument:
  AND $0F
SlotRowOp:
  ADD A,$00               ; ADD A,n: n = 8 x the channel (self-modified by
                          ; UpdateTune $C212, $C24F, $C27B)
  LD L,A
  LD H,$00
  LD BC,SlotTable         ; the slot's record offset
  ADD HL,BC
  LD L,(HL)
  LD H,$00
  LD BC,Instruments       ; IY = the record
  ADD HL,BC
  PUSH HL
  POP IY
  LD A,(IY+$08)           ; +8: the peak volume
  LD (IX+$2B),A
  LD HL,MixerImage        ; the mixer: channel A bits 0 and 3
  LD A,(ChannelIndex)
  OR A
  JR NZ,SetInstrumentB
  RES 3,(HL)
  SET 0,(HL)
  BIT 7,(IY+$02)
  JR NZ,SetInstrumentEnvelope
  SET 3,(HL)
  RES 0,(HL)
  JR SetInstrumentEnvelope
SetInstrumentB:
  DEC A                   ; channel B: bits 1 and 4
  JR NZ,SetInstrumentC
  SET 1,(HL)
  RES 4,(HL)
  BIT 7,(IY+$02)
  JR NZ,SetInstrumentEnvelope
  RES 1,(HL)
  SET 4,(HL)
  JR SetInstrumentEnvelope
SetInstrumentC:
  SET 2,(HL)              ; channel C: bits 2 and 5
  RES 5,(HL)
  BIT 7,(IY+$02)
  JR NZ,SetInstrumentEnvelope
  RES 2,(HL)
  SET 5,(HL)
SetInstrumentEnvelope:
  LD (IX+$24),$0F         ; the attack: +3's high nibble through AttackRates
  LD (IX+$25),$01
  LD A,(IY+$03)
  PUSH AF
  AND $F0
  JR Z,SetInstrumentSustain
  RRCA
  RRCA
  RRCA
  RRCA
  LD C,A
  LD B,$00
  LD HL,AttackRates
  ADD HL,BC
  LD A,(HL)
  BIT 7,A
  JR NZ,SetInstrumentSlowAttack
  LD (IX+$24),A
  JR SetInstrumentSustain
SetInstrumentSlowAttack:
  AND $7F                 ; bit 7: one step every n frames
  LD (IX+$25),A
  LD (IX+$24),$01
SetInstrumentSustain:
  LD A,(IY+$04)           ; +4's high nibble: the sustain level; the decay:
                          ; +3's low nibble
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  LD (IX+$20),A
  LD (IX+$21),$0F
  LD (IX+$22),$01
  POP AF
  AND $0F
  JR Z,SetInstrumentRelease
  LD C,A
  LD B,$00
  LD HL,DecayRates
  ADD HL,BC
  LD A,(HL)
  BIT 7,(HL)
  JR NZ,SetInstrumentSlowDecay
  LD (IX+$21),A
  JR SetInstrumentRelease
SetInstrumentSlowDecay:
  AND $7F                 ; bit 7: one step every n frames
  LD (IX+$22),A
  LD (IX+$21),$01
SetInstrumentRelease:
  LD (IX+$27),$0F         ; the release: +4's low nibble through DecayRates
  LD (IX+$28),$01
  LD A,(IY+$04)
  AND $0F
  JR Z,SetInstrumentTimes
  LD C,A
  LD B,$00
  LD HL,DecayRates
  ADD HL,BC
  LD A,(HL)
  BIT 7,A
  JR NZ,SetInstrumentSlowRelease
  LD (IX+$27),A
  JR SetInstrumentTimes
SetInstrumentSlowRelease:
  AND $7F                 ; bit 7: one step every n frames
  LD (IX+$28),A
  LD (IX+$27),$01
SetInstrumentTimes:
  LD A,(IY+$05)           ; +5 the gate-off time, +7 the vibrato
  LD (IX+$06),A
  LD A,(IY+$07)
  LD (IX+$0B),A
  INC (IX+$02)
  JP ReadPatternEvent

; Start note A: its period, the gate and the envelope, its duration, the
; vibrato, the arpeggio and the slide delay
;
; A = the note (0-$7F), DE = the pattern, from PatternEvent $C36D. The
; period-table index (+$1C) = A + 20 + the transpose (+$01); the period
; (+$1D/+$1E) = PeriodLo/PeriodHi[index] + the detune (+$09). The gate on, the
; volume and the envelope counters 0, the done bits of attack, decay and
; release clear. The next byte is the duration: the note timer (+$03). With a
; vibrato (+$0B not 0): its delay or cycles (+$0A) = the record's first byte,
; the step (+$0C) 1. With an arpeggio (+$10 not 0): the first hold (+$18) =
; ((header & $78) >> 3) + 1, the step (+$17) 1. The slide delay (+$14) again
; from the slide command (+$15). Returns to UpdateChannel's caller: no effects
; on a note's first frame.
;
; A new entry, for the cut's l_C4C9 inside OrderJumpSlot's block
; (PatternEvent's JP Z at $C36F).
;
; Witness: L1 15424 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
StartNote:
  ADD A,$14
  ADD A,(IX+$01)
  LD C,A
  LD B,$00
  LD (IX+$1C),A
  LD HL,PeriodLo
  ADD HL,BC
  LD A,(HL)
  LD HL,PeriodHi
  ADD HL,BC
  LD H,(HL)
  LD L,A
  LD C,(IX+$09)           ; + the detune
  ADD HL,BC
  LD (IX+$1D),L
  LD (IX+$1E),H
  SET 0,(IX+$2A)          ; the gate on, the envelope from volume 0
  XOR A
  LD (IX+$26),A
  LD (IX+$23),A
  LD (IX+$29),A
  LD (IX+$1F),A
  RES 7,(IX+$25)
  RES 7,(IX+$22)
  RES 7,(IX+$28)
  LD L,(IX+$02)           ; the duration, kept in A' to the end
  LD H,$00
  INC L
  ADD HL,DE
  LD A,(HL)
  INC (IX+$02)
  INC (IX+$02)
  EX AF,AF'
  LD A,(IX+$0B)           ; the vibrato: the record's first byte, from step 1
  OR A
  JR Z,StartNoteArpeggio
  LD L,A
  LD H,$00
  LD BC,VibratoTable-8
  ADD HL,BC
  LD A,(HL)
  LD (IX+$0A),A
  LD (IX+$0C),$01
StartNoteArpeggio:
  LD A,(IX+$10)           ; the arpeggio: the hold of the base note
  OR A
  JR Z,StartNoteSlide
  LD L,A
  LD H,$00
  LD BC,ArpeggioTable
  ADD HL,BC
  LD A,(HL)
  AND $78
  SRL A
  SRL A
  SRL A
  INC A
  LD (IX+$18),A
  LD (IX+$17),$01
StartNoteSlide:
  LD A,(IX+$15)           ; the slide's delay again
  AND $1F
  LD (IX+$14),A
  EX AF,AF'
  LD (IX+$03),A
  RET

  ORG $C7D1

; Order command $C0: the next byte is the channel's detune (+$09)
;
; Then ReadOrderList $C310. Tune 0's channel B: $C0 10 at its start, $C0 0
; after the intro (pattern 5); a constant added to every period (and so a lower
; pitch, a little, for the 10).
;
; Witness: L1 17 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
SetDetune:
  LD L,(IX+$00)
  LD H,$00
OrderListOp2:
  LD BC,Tune0OrderA       ; LD BC,nn: nn = the channel's order list
                          ; (self-modified by UpdateTune)
  ADD HL,BC
  LD A,(HL)
  INC (IX+$00)
  LD (IX+$09),A
  JP ReadOrderList

; Order command $80: the next byte is the channel's transpose (+$01, signed
; semitones)
;
; Then ReadOrderList $C310. Reached by OrderCommandJump $C339 with offset 0.
;
; Witness: L1 227 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
SetTranspose:
  LD L,(IX+$00)
  LD H,$00
OrderListOp3:
  LD BC,Tune0OrderA       ; LD BC,nn: nn = the channel's order list
                          ; (self-modified by UpdateTune)
  ADD HL,BC
  LD A,(HL)
  INC (IX+$00)
  LD (IX+$01),A
  JP ReadOrderList

; Order command $E0+n: the next byte is the record offset of the channel's
; instrument slot n
;
; SlotTable[8 x channel + n] = the byte (SlotRowOp+1 gives 8 x channel,
; CommandParam $C1E0 n), through the self-modified SlotIndexOp. Then
; ReadOrderList $C310. Tune 0 uses it three times on channel B: slot 0 = $48
; (record 8), slot 6 = $51 (record 9), then $5A (record 10); the change
; outlives the tune (StartTune does not reset SlotTable).
;
; Witness: L1 21 (explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
SetSlot:
  LD A,(SlotRowOp+$0001)
  LD C,A
  LD A,(CommandParam)
  ADD A,C
  LD (SlotIndexOp+$0001),A
  LD L,(IX+$00)
  LD H,$00
OrderListOp4:
  LD BC,Tune0OrderA       ; LD BC,nn: nn = the channel's order list
                          ; (self-modified by UpdateTune)
  ADD HL,BC
  LD A,(HL)
  INC (IX+$00)
SlotIndexOp:
  LD L,$00                ; LD L,n: n = 8 x channel + n (self-modified at
                          ; $C7FF)
  LD H,$00
  LD BC,SlotTable
  ADD HL,BC
  LD (HL),A
  JP ReadOrderList

; Order command $A0+n: play the next pattern n times
;
; The repeats left (+$04) = n - 1 (n 0: 255, so 256 plays); ReadPatternEvent
; $C2F6 replays the pattern while it is not 0. Then ReadOrderList $C310.
;
; Witness: L1 123 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
SetRepeat:
  LD A,(CommandParam)
  DEC A
  LD (IX+$04),A
  JP ReadOrderList

; A = the byte at the channel's pattern position: DE + (+$02)
;
; Called by PatternEvent $C36D for a rest's duration and a slide's three bytes.
;
; Witness: L1 76 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx).
FetchPatternByte:
  LD L,(IX+$02)
  LD H,$00
  ADD HL,DE
  LD A,(HL)
  RET
