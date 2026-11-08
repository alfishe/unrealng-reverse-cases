; --------------------------------------------------------------------------------------------------------------------
; music.asm: The 128K title tune on the AY
; --------------------------------------------------------------------------------------------------------------------

; The tune's channel volume limits: B = TuneVolume, A and C one more
;
; Channel record +8 (the volume ceiling): $BED5 (B) = TuneVolume $B6E0 (12),
; $BE85 (A) and $BF25 (C) = 13. Called by TuneStart.
TuneSetMaxVolumes:
  LD A,(TuneVolume)
  LD (TuneChannelB+$0008),A
  INC A
  LD (TuneChannels+$0008),A
  LD (TuneChannelC+$0008),A
  RET

; The title tune's player state
;
; +0 ($B6DF) and +3/+4 ($B6E2, $B6E3) have no reader or writer in any recording
; or in the code. The stream pointers hold stale values in the image (TuneStart
; writes them).
TuneState:
  DEFB $00
TuneVolume:
  DEFB $0C                ; 12: the start volume and the ceiling
                          ; (TuneSetMaxVolumes, TuneInitChannel)
TuneStreamRead:
  DEFB $00                ; 0 at each TuneTick; $FF once a channel has read its
                          ; stream in this tick (TuneNextEvent)
  DEFB $00                ; unused
  DEFB $03
TuneStopped:
  DEFB $FF                ; $FF: no tune (set in TuneStart and at the tune's
                          ; end, TuneEnd), 0 playing
TuneMixer:
  DEFB $00                ; the AY mixer value (register 7) the tune keeps: $B8
                          ; from AySilence, toggled by the stream code $64
TunePointerA:
  DEFB $01                ; channel A's stream pointer (IY between the ticks)
  DEFB $BA
TunePointerB:
  DEFB $7E                ; channel B's stream pointer
  DEFB $BB
TunePointerC:
  DEFB $01                ; channel C's stream pointer
  DEFB $BA

; Start the title tune: the three stream pointers, the channel records, the AY
; silenced
;
; TuneStopped = $FF while it works; the stream pointers = TuneStreamA $BA01,
; TuneStreamB $BB7E, TuneStreamC $BD06; TuneInitChannel for the records at
; $BE7D, $BECD, $BF1D; TuneSetMaxVolumes; AySilence; each record's +2 (the note
; count) = 1 so the first TuneTick reads every stream; TuneStopped = 0. Called
; once per menu entry ($6DB8, 117 calls in the runs); the tune then plays only
; on a 128K (TuneTick runs only with the AY flag $6E16 set, DrawSparkle).
TuneStart:
  LD BC,TuneStreamA
  LD DE,TuneStreamB
  LD HL,TuneStreamC
  LD A,$FF
  LD (TuneStopped),A
  LD (TunePointerA),BC
  LD (TunePointerB),DE
  LD (TunePointerC),HL
  LD IX,TuneChannels
  CALL TuneInitChannel
  LD IX,TuneChannelB
  CALL TuneInitChannel
  LD IX,TuneChannelC
  CALL TuneInitChannel
  CALL TuneSetMaxVolumes
  CALL AySilence
  LD A,$01
  LD (TuneChannels+$0002),A
  LD (TuneChannelB+$0002),A
  LD (TuneChannelC+$0002),A
  XOR A
  LD (TuneStopped),A
  RET

; Reset a tune channel record (IX)
;
; +3 the volume = TuneVolume; +9 the transpose, +$0C the call depth, +$0D the
; deferred flag, +0/+1 the period = 0; +2 the note count = 1; +4 and +5 = 5 (no
; reader in the player).
TuneInitChannel:
  LD A,(TuneVolume)
  LD (IX+$03),A
  XOR A
  LD (IX+$09),A
  LD (IX+$0C),A
  LD (IX+$0D),A
  LD (IX+$00),A
  LD (IX+$01),A
  LD (IX+$02),$01
  LD (IX+$04),$05
  LD (IX+$05),$05
  RET

; Mixer $B8 (tones on, noise off) and the three volumes 0
;
; TuneMixer = $B8; AY register 7 = $B8, registers 8, 9, 10 = 0 (AyWrite).
; Callers: the define keys ($6FAB), the game start ($758B), TuneStart, TuneEnd.
AySilence:
  LD A,$B8
  LD (TuneMixer),A
  LD C,A
  LD A,$07
  LD E,$04
AySilenceLoop:
  CALL AyWrite
  LD C,$00
  INC A
  DEC E
  JR NZ,AySilenceLoop
  RET

; One tick of the title tune: each channel's step (128K only)
;
; TuneStreamRead = 0; nothing while TuneStopped. Else channel A (IX = $BE7D, IY
; = TunePointerA), B ($BECD) and C ($BF1D), TuneChannelStep each, the pointer
; kept back. Called by DrawSparkle ($6F40) every fourth time the menu's
; animation draws a sprite (the count $6F4D), only when the AY flag $6E16 is
; set: in c128 10 554 calls, in the 48K runs none (the routine is code by the
; static walk).
TuneTick:
  XOR A
  LD (TuneStreamRead),A
  LD A,(TuneStopped)
  OR A
  JR NZ,TuneTickDone
  LD IX,TuneChannels
  LD IY,(TunePointerA)
  CALL TuneChannelStep
  LD (TunePointerA),IY
  LD IX,TuneChannelB
  LD IY,(TunePointerB)
  CALL TuneChannelStep
  LD (TunePointerB),IY
  LD IX,TuneChannelC
  LD IY,(TunePointerC)
  CALL TuneChannelStep
  LD (TunePointerC),IY

; The RET of TuneTick (also the end of TuneEnd's jump)
;
; TuneEnd ($B9FE) jumps here after dropping a return address, so the RET leaves
; TuneTick's caller's level.
TuneTickDone:
  RET

; One channel's tick: the next event when its note ends, the pitch and volume
; envelopes
;
; IX the channel record (80 bytes, TuneChannels $BE7D), IY its stream pointer.
; A deferred read (+$0D set: the channel's note ended while another channel had
; read its stream in this tick) is done now; else +2 (the note count) - 1, and
; at 0 TuneNextEvent is jumped to (this tick has no envelope step).
;
; The pitch envelope: +$1B counts the ticks of a step; at 0 the offset +$19 +=
; the step +$1D, and +$1C (the steps of the segment) - 1; at 0 the next
; segment: +$1A += 3 (back to 0 at +$1F, the table's length), the three bytes
; at +$20 + index copied to +$1C (steps), +$1D (step), +$1E (ticks a step)
; through the self-modified LD A,(IX+d) at $B7E6-$B7F2. Then +$1B = +$1E, and
; the period +0/+1 (when not 0) plus the signed offset is written to the tone
; registers +6 / +6 + 1 (AyWrite).
;
; The volume envelope, the same with +$36 (the ticks), +$38 (the step), +$37
; (the steps of the segment), +$35 (the index, step 3, to +$3A the length),
; entries from +$3B ($B86C-$B878): the volume +3 += +$38, kept in 0..+8 (the
; ceiling), written to the volume register +7. At the table's end the step is 0
; and the counters $FF (hold).
TuneChannelStep:
  LD A,(IX+$0D)
  OR A
  JR Z,TuneChannelCount
  LD (IX+$0D),$00
  CALL TuneNextEvent
  JR TunePitchStep
TuneChannelCount:
  DEC (IX+$02)            ; the note's ticks
  JP Z,TuneNextEvent
TunePitchStep:
  DEC (IX+$1B)            ; the pitch envelope's tick
  JP NZ,TuneVolumeStep
  LD A,(IX+$19)
  ADD A,(IX+$1D)
  LD (IX+$19),A
  DEC (IX+$1C)
  JR NZ,TunePitchWrite
  LD A,(IX+$1A)
  ADD A,$03
  LD (IX+$1A),A
  CP (IX+$1F)
  JR NZ,TunePitchSegment
  XOR A
  LD (IX+$1A),A
TunePitchSegment:
  ADD A,$20               ; the next segment's three bytes: the offsets of the
                          ; three LD A,(IX+d) below
  LD (TunePitchSegment+$000F),A
  INC A
  LD (TunePitchSegment+$0015),A
  INC A
  LD (TunePitchSegment+$001B),A
  LD A,(IX+$00)           ; LD A,(IX+d): d written at $B7DB (+$20 + index: the
                          ; steps)
  LD (IX+$1C),A
  LD A,(IX+$00)           ; d written at $B7DF (the step)
  LD (IX+$1D),A
  LD A,(IX+$00)           ; d written at $B7E3 (the ticks a step)
  LD (IX+$1E),A
TunePitchWrite:
  LD A,(IX+$1E)           ; the step's ticks reloaded, the tone period written
  LD (IX+$1B),A
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,L
  OR H
  JR Z,TunePeriodOut
  LD D,$FF
  LD A,(IX+$19)
  OR A
  JP M,TuneBendAdd
  LD D,$00
TuneBendAdd:
  LD E,A                  ; the pitch offset added to the period
  ADD HL,DE
TunePeriodOut:
  LD A,(IX+$06)           ; the period to the channel's two AY registers
  INC A
  LD C,H
  CALL AyWrite
  DEC A
  LD C,L
  CALL AyWrite
TuneVolumeStep:
  DEC (IX+$36)            ; the volume envelope's tick
  JR NZ,TuneChannelStepDone
  LD A,(IX+$03)
  ADD A,(IX+$38)
  JP P,TuneVolumeFloor
  XOR A
TuneVolumeFloor:
  LD (IX+$03),A           ; the volume kept at 0 or more
  LD A,(IX+$08)
  CP (IX+$03)
  JR NC,TuneVolumeCeiling
  LD (IX+$03),A
TuneVolumeCeiling:
  DEC (IX+$37)            ; the volume kept to the ceiling
  JR NZ,TuneVolumeWrite
  LD A,(IX+$35)
  ADD A,$03
  LD (IX+$35),A
  CP (IX+$3A)
  JR NZ,TuneVolumeSegment
  LD (IX+$38),$00
  LD (IX+$37),$FF
  LD (IX+$39),$FF
  JR TuneVolumeWrite
TuneVolumeSegment:
  ADD A,$3B               ; the next segment's three bytes, +$3B + index
  LD (TuneVolumeSegment+$000F),A
  INC A
  LD (TuneVolumeSegment+$0015),A
  INC A
  LD (TuneVolumeSegment+$001B),A
  LD A,(IX+$00)           ; LD A,(IX+d): d written at $B861 (the steps)
  LD (IX+$37),A
  LD A,(IX+$00)           ; d written at $B865 (the step)
  LD (IX+$38),A
  LD A,(IX+$00)           ; d written at $B869 (the ticks a step)
  LD (IX+$39),A
TuneVolumeWrite:
  LD A,(IX+$39)           ; the ticks reloaded, the volume to register +7
  LD (IX+$36),A
  LD A,(IX+$03)
  LD C,A
  LD A,(IX+$07)
  JP AyWrite
TuneChannelStepDone:
  RET

; Read a channel's stream: the codes up to the next note
;
; Only one channel reads its stream in a tick: when TuneStreamRead is set the
; read is deferred (+$0D = $FF) to the next TuneChannelStep. Then the codes at
; IY (TuneReadCode $B89D, the loop the other code handlers jump back to):
;
; $00-$31 a note: 0 or n + the transpose +9; the period = the word at $C71B +
; 2n (NotePeriods entry 24 + n: the tune is two octaves above the effects' note
; 0); +2 = the note's length +$0A; volume +3 = 0; the pitch envelope restarted
; (+$19 = 0, +$1A = -3 so the first segment is index 0, +$1B = +$1C = 1, +$1D =
; 0); the volume envelope from its first entry (+$37/+$38/+$39 =
; +$3B/+$3C/+$3D, +$36 = +$3D, +$35 = 0). Ends the read.
;
; $32-$63 n: the length +$0A = n, then the note code - $32. $64: TuneMixer XOR
; +$0B (the channel's tone and noise bits: A $09, B $12, C $24), register 7.
; $79 n: register 6 (the noise period) = n. $65-$74: the ceiling +8 = code -
; $65 (TuneSetCeiling, never ran). $75 lo hi: call the stream at hi lo
; (TuneCall), $76: return. $77 n: transpose (never ran). $78 lo hi: jump (never
; ran). $FF: the tune's end (TuneEnd). $89 n ...: n bytes of a pitch envelope
; to +$1F (never ran). $8A n ...: n bytes of a volume envelope to +$3A. Any
; other code: RET (TuneBadCode, never ran).
;
; The tune's streams use only notes, $64, $79, $75/$76 and $8A (tune.py over
; TuneStreamA-C).
TuneNextEvent:
  LD A,(TuneStreamRead)
  OR A
  JR Z,TuneChannelReads
  LD (IX+$0D),A
  RET
TuneChannelReads:
  DEC A                   ; this channel's turn to read the stream
  LD (TuneStreamRead),A
; This entry point is used by the routines at TuneCall, TuneTranspose,
; TuneJump, TunePitchEnvelope and TuneVolumeEnvelope.
TuneReadCode:
  LD A,(IY+$00)           ; the next stream code
  CP $32
  JR NC,TuneCheckLength
AyTuneNote:
  OR A                    ; a note: A = the note code
  JR Z,AyTuneNotePeriod
  ADD A,(IX+$09)
AyTuneNotePeriod:
  LD L,A                  ; the note's period from NotePeriods
  SLA L
  LD H,$00
  PUSH DE
  LD DE,NotePeriodsTune
  ADD HL,DE
  POP DE
  LD A,(HL)
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  LD (IX+$01),A
  LD A,(IX+$0A)
  LD (IX+$02),A
  LD (IX+$03),$00
  INC IY
  LD (IX+$05),$01
  LD (IX+$19),$00
  LD (IX+$1B),$01
  LD (IX+$1C),$01
  LD (IX+$1A),$FD
  LD (IX+$1D),$00
  LD A,(IX+$3B)
  LD (IX+$37),A
  LD A,(IX+$3C)
  LD (IX+$38),A
  LD A,(IX+$3D)
  LD (IX+$39),A
  LD (IX+$36),A
  LD (IX+$35),$00
  RET
TuneCheckLength:
  CP $64                  ; $32-$63: the length byte, then the note
  JR NC,TuneCheckMixer
  LD A,(IY+$01)
  LD (IX+$0A),A
  LD A,(IY+$00)
  INC IY
  SUB $32
  JR AyTuneNote
TuneCheckMixer:
  CP $64                  ; $64: the channel's tone / noise toggle
  JR NZ,TuneCheckNoise
  LD HL,TuneMixer
  LD A,(HL)
  XOR (IX+$0B)
  LD (HL),A
  LD C,A
  LD A,$07
  CALL AyWrite
; This entry point is used by the routine at TuneSetCeiling.
TuneNextCode:
  INC IY                  ; on to the next stream code
  JP TuneReadCode
TuneCheckNoise:
  CP $79                  ; $79 n: the noise period
  JR NZ,TuneCheckCeiling
  INC IY
  LD C,(IY+$00)
  LD A,$06
  CALL AyWrite
  INC IY
  JP TuneReadCode
TuneCheckCeiling:
  CP $75                  ; $65-$74 fall through to TuneSetCeiling
  JR NC,TuneCall

; Stream codes $65-$74: the channel's volume ceiling (never ran)
;
; +8 = code - $65, then the next code. No stream of the image holds these codes
; (tune.py), no recording ran it; the stream reader goes on with $B944 ($75 and
; up) otherwise.
TuneSetCeiling:
  SUB $65
  LD (IX+$08),A
  JR TuneNextCode

; Stream codes $75 (call a sub-stream) and $76 (return)
;
; $75 lo hi: the return point (IY + 3) saved at +$0E + 2 * depth through the
; self-modified LD (IX+d),C / LD (IX+d),B at $B965/$B968, depth +$0C + 1, IY =
; hi lo. $76: depth - 1, IY from the slot ($B989/$B98C, the same self-modified
; offsets). The tune's patterns and its envelope settings are called so
; (TuneStreamA calls 40, B 42, C 57). Then the next code.
TuneCall:
  CP $75
  JR NZ,TuneReturn
  LD L,(IY+$01)
  LD H,(IY+$02)
  INC IY
  INC IY
  INC IY
  PUSH IY
  POP BC
  LD A,(IX+$0C)
  SLA A
  ADD A,$0E
  LD (TuneCall+$0023),A
  INC A
  LD (TuneCall+$0026),A
  LD (IX+$00),C           ; LD (IX+d),C: d written at $B95E (+$0E + 2 * depth)
  LD (IX+$01),B           ; d written at $B962
  INC (IX+$0C)
  PUSH HL
  POP IY
  JP TuneReadCode
TuneReturn:
  CP $76                  ; $76: back to the saved point
  JR NZ,TuneCheckTranspose
  DEC (IX+$0C)
  LD A,(IX+$0C)
  SLA A
  ADD A,$0E
  LD (TuneReturn+$0017),A
  INC A
  LD (TuneReturn+$001A),A
  LD C,(IX+$00)           ; LD C,(IX+d): d written at $B982
  LD B,(IX+$01)           ; d written at $B986
  PUSH BC
  POP IY
  JP TuneReadCode
TuneCheckTranspose:
  CP $77                  ; $77
  JR NZ,TuneCheckJump

; Stream code $77 n: the channel's transpose (never ran)
;
; +9 = n (added to every note but 0). No stream of the image holds it.
TuneTranspose:
  INC IY
  LD A,(IY+$00)
  LD (IX+$09),A
  INC IY
  JP TuneReadCode

; Stream code $78?
;
; Not $78: on to TuneCheckEnd.
TuneCheckJump:
  CP $78
  JR NZ,TuneCheckEnd

; Stream code $78 lo hi: go on reading at hi lo (never ran)
;
; No stream of the image holds it: the tune does not loop, it ends with $FF.
TuneJump:
  LD L,(IY+$01)
  LD H,(IY+$02)
  PUSH HL
  POP IY
  JP TuneReadCode

; Stream codes $FF (the end) and $89?
;
; Used by the routine at TuneCheckJump.
TuneCheckEnd:
  CP $FF
  JR Z,TuneEnd
  CP $89
  JR NZ,TuneVolumeEnvelope

; Stream code $89 n b1..bn: the pitch envelope (never ran)
;
; n + 1 bytes (n and the entries) copied to +$1F: the length (a multiple of 3),
; then entries of 3 bytes (the steps, the step, the ticks a step). No stream of
; the image holds it; the records' pitch tables in the image keep what the
; composer's other tunes left.
TunePitchEnvelope:
  INC IY
  LD A,(IY+$00)
  LD B,A
  INC B
  PUSH IX
TuneCopyBytes:
  LD A,(IY+$00)           ; the call's bytes into the channel's record
  LD (IX+$1F),A
  INC IY
  INC IX
  DJNZ TuneCopyBytes
  POP IX
  JP TuneReadCode

; Stream code $8A n b1..bn: the volume envelope
;
; n + 1 bytes copied to +$3A: the length, then entries of 3 bytes (the steps,
; the step, the ticks a step). In the tune's envelope sub-streams ($BDE1-$BE7C)
; and in its streams (11, 12 and 29 times).
TuneVolumeEnvelope:
  CP $8A
  JR NZ,TuneBadCode
  INC IY
  LD A,(IY+$00)
  LD B,A
  INC B
  PUSH IX
TuneVolumeEnvelopeLoop:
  LD A,(IY+$00)
  LD (IX+$3A),A
  INC IY
  INC IX
  DJNZ TuneVolumeEnvelopeLoop
  POP IX
  JP TuneReadCode

; A stream code with no meaning: the read ends (never ran)
;
; The RET the chain of tests ends in for $7A-$88, $8B-$FE.
TuneBadCode:
  RET

; Stream code $FF: the tune is over
;
; TuneStopped = $FF, AySilence, then the return address to TuneChannelStep (or
; TuneTick) dropped and TuneTickDone's RET: the rest of the tick is skipped.
; The first channel to reach its $FF stops the tune for all three.
TuneEnd:
  LD (TuneStopped),A
  CALL AySilence
  POP AF
  JP TuneTickDone

; The title tune, channel A: the order list, then its patterns
;
; The codes of TuneNextEvent. $BA01-$BA57: calls ($75) of the patterns and the
; envelope settings, ending with $FF; $BA58-$BB7D the patterns, each ending
; with $76. tune.py: 340 notes, 40 calls, 11 volume envelopes.
TuneStreamA:
  DEFB $75,$F3,$BD,$75,$54,$BB,$75,$41,$BB,$75,$41,$BB,$75,$32,$BB,$75
  DEFB $32,$BB,$75,$04,$BB,$75,$32,$BB,$75,$32,$BB,$75,$04,$BB,$75,$D6
  DEFB $BA,$75,$32,$BB,$75,$32,$BB,$75,$32,$BB,$75,$32,$BB,$75,$C9,$BA
  DEFB $75,$C9,$BA,$75,$AE,$BA,$75,$32,$BB,$75,$32,$BB,$75,$32,$BB,$75
  DEFB $32,$BB,$75,$A1,$BA,$75,$A1,$BA,$75,$92,$BA,$75,$92,$BA,$75,$75
  DEFB $BA,$75,$58,$BA,$4E,$A0,$FF
TunePatternsA:
  DEFB $55,$14,$24,$53,$0A,$55,$14,$21,$23,$1F,$51,$0A,$53,$14,$51,$14 ; channel
  DEFB $21,$50,$0A,$51,$14,$1E,$1F,$1C,$4E,$0A,$50,$14,$76,$50,$14,$1F ; A's
  DEFB $4E,$0A,$50,$14,$1E,$1F,$1C,$4E,$0A,$50,$14,$50,$14,$1F,$4E,$0A ; patterns
  DEFB $50,$14,$1B,$1C,$1E,$51,$0A,$53,$14,$76,$4E,$14,$1D,$4C,$0A,$4E ; (sub-streams,
  DEFB $14,$1C,$1D,$1A,$4C,$0A,$4E,$14,$76,$4C,$14,$1C,$4A,$0A,$4C,$14 ; $76 each)
  DEFB $17,$18,$15,$49,$1E,$76,$50,$14,$1F,$4E,$0A,$50,$14,$1B,$1C,$19
  DEFB $4D,$1E,$50,$14,$1F,$4E,$0A,$50,$14,$1B,$1C,$1E,$51,$0A,$53,$14
  DEFB $76,$51,$14,$21,$50,$0A,$51,$14,$1C,$1E,$1A,$4E,$1E,$76,$75,$71
  DEFB $BE,$4A,$28,$15,$4A,$1E,$18,$4E,$0A,$1A,$4A,$28,$13,$4A,$1E,$18
  DEFB $4E,$0A,$1A,$4A,$28,$18,$4A,$1E,$18,$4E,$0A,$1A,$4A,$28,$18,$4A
  DEFB $0A,$1C,$18,$1C,$1F,$1C,$1F,$23,$75,$05,$BE,$76,$75,$EA,$BD,$53
  DEFB $14,$53,$0A,$75,$05,$BE,$51,$32,$51,$14,$4A,$0A,$53,$14,$4A,$0A
  DEFB $51,$14,$75,$EA,$BD,$4E,$14,$4E,$0A,$75,$05,$BE,$4C,$32,$4C,$14
  DEFB $45,$0A,$4E,$14,$45,$0A,$4C,$0A,$13,$76,$55,$14,$24,$53,$0A,$55
  DEFB $14,$1F,$21,$1E,$55,$0A,$4E,$14,$76,$51,$28,$51,$1E,$23,$55,$14
  DEFB $21,$1F,$51,$28,$51,$1E,$23,$55,$14,$21,$1F,$76,$75,$5F,$BB,$51
  DEFB $14,$75,$5F,$BB,$53,$14,$76,$51,$0A,$1A,$1F,$23,$58,$14,$1A,$1C
  DEFB $56,$0A,$23,$24,$23,$53,$1E,$50,$0A,$1F,$53,$14,$50,$0A,$4C,$14
  DEFB $24,$56,$0A,$55,$1E,$76
TuneStreamB:
  DEFB $75,$E1,$BD,$64,$75,$E7,$BC,$75,$E7,$BC,$75,$E7,$BC,$75,$E7,$BC ; channel B:
  DEFB $64,$75,$F3,$BD,$75,$C6,$BC,$75,$C6,$BC,$75,$B7,$BC,$75,$B7,$BC ; the order
  DEFB $75,$89,$BC,$75,$B7,$BC,$75,$B7,$BC,$75,$89,$BC,$75,$61,$BC,$75 ; list ($FF
  DEFB $B7,$BC,$75,$B7,$BC,$75,$B7,$BC,$75,$B7,$BC,$75,$54,$BC,$75,$54 ; at $BBE2),
  DEFB $BC,$75,$39,$BC,$75,$B7,$BC,$75,$B7,$BC,$75,$B7,$BC,$75,$B7,$BC ; 364 notes,
  DEFB $75,$2C,$BC,$75,$2C,$BC,$75,$1D,$BC,$75,$1D,$BC,$75,$00,$BC,$75 ; 28 noise
  DEFB $E3,$BB,$49,$A0,$FF                                             ; settings,
                                                                       ; 2 mixer
                                                                       ; toggles
TunePatternsB:
  DEFB $51,$14,$21,$50,$0A,$51,$14,$1E,$1F,$1C,$4E,$0A,$50,$14,$4E,$14
  DEFB $1E,$4C,$0A,$4E,$14,$1B,$1C,$19,$4B,$0A,$4D,$14,$76,$4D,$14,$1C
  DEFB $4B,$0A,$4D,$14,$1B,$1C,$19,$4B,$0A,$4D,$14,$4D,$14,$1C,$4B,$0A
  DEFB $4D,$14,$17,$19,$1B,$4E,$0A,$50,$14,$76,$4A,$14,$1A,$49,$0A,$4A
  DEFB $14,$18,$1A,$17,$49,$0A,$4A,$14,$76,$49,$14,$18,$47,$0A,$49,$14
  DEFB $13,$15,$12,$45,$1E,$76,$4D,$14,$1C,$4B,$0A,$4D,$14,$17,$19,$15
  DEFB $49,$1E,$4D,$14,$1C,$4B,$0A,$4D,$14,$17,$19,$1B,$4E,$0A,$50,$14
  DEFB $76,$4E,$14,$1E,$4C,$0A,$4E,$14,$18,$1A,$17,$4A,$1E,$76,$75,$71
  DEFB $BE,$32,$28,$15,$32,$14,$47,$1E,$15,$32,$28,$13,$32,$14,$45,$1E
  DEFB $13,$32,$14,$15,$00,$15,$32,$14,$47,$1E,$15,$32,$14,$13,$00,$13
  DEFB $32,$50,$75,$05,$BE,$76,$75,$EA,$BD,$4F,$14,$4F,$0A,$75,$05,$BE
  DEFB $4E,$32,$4E,$14,$4A,$0A,$4F,$14,$4A,$0A,$4E,$14,$75,$EA,$BD,$4A
  DEFB $14,$4A,$0A,$75,$05,$BE,$49,$32,$49,$14,$45,$0A,$4A,$14,$45,$0A
  DEFB $49,$0A,$13,$76,$51,$14,$21,$50,$0A,$51,$14,$1C,$1E,$1A,$50,$0A
  DEFB $49,$14,$76,$4E,$14,$17,$1C,$49,$0A,$51,$14,$49,$0A,$1F,$17,$1E
  DEFB $17,$1C,$17,$4E,$14,$18,$1C,$4A,$0A,$51,$14,$4A,$0A,$1F,$18,$1E
  DEFB $18,$1C,$18,$76,$79,$1F,$32,$14,$00,$00,$32,$05,$79,$0F,$00,$79
  DEFB $1F,$00,$79,$0F,$00,$79,$1F,$32,$14,$00,$00,$79,$1F,$32,$0A,$79
  DEFB $0F,$00,$76
TuneStreamC:
  DEFB $75,$5F,$BE,$75,$DB,$BD,$75,$DB,$BD,$75,$D7,$BD,$75,$D7,$BD,$75 ; channel C:
  DEFB $5E,$BD,$75,$5E,$BD,$75,$BC,$BD,$75,$5E,$BD,$75,$5E,$BD,$75,$BC ; the order
  DEFB $BD,$75,$AF,$BD,$75,$A7,$BD,$75,$A7,$BD,$75,$A7,$BD,$75,$D1,$BD ; list ($FF
  DEFB $75,$95,$BD,$75,$9E,$BD,$75,$8A,$BD,$75,$8A,$BD,$75,$8A,$BD,$75 ; at $BD5D),
  DEFB $8A,$BD,$75,$6F,$BD,$75,$6F,$BD,$75,$78,$BD,$75,$78,$BD,$75,$81 ; 90 notes,
  DEFB $BD,$75,$81,$BD,$75,$65,$BD,$FF                                 ; 29 volume
                                                                       ; envelopes
TunePatternsC:
  DEFB $75,$68,$BE,$36,$50,$10,$76,$42,$50,$0E,$0C,$0B,$75,$05,$BE,$10
  DEFB $76,$75,$68,$BE,$39,$8C,$45,$0A,$07,$76,$75,$68,$BE,$3E,$8C,$4A
  DEFB $0A,$0C,$76,$75,$68,$BE,$3D,$8C,$49,$0A,$0B,$76,$75,$68,$BE,$42
  DEFB $78,$3D,$14,$42,$0A,$0B,$76,$3E,$78,$39,$28,$3E,$78,$39,$28,$76
  DEFB $3D,$78,$38,$28,$3D,$78,$3D,$28,$76,$75,$68,$BE,$42,$78,$3D,$28
  DEFB $76,$75,$71,$BE,$43,$50,$11,$10,$10,$11,$11,$10,$10,$76,$75,$EA
  DEFB $BD,$3E,$14,$75,$4D,$BE,$3E,$8C,$75,$EA,$BD,$39,$14,$75,$4D,$BE
  DEFB $39,$8C,$76,$75,$68,$BE,$36,$A0,$76,$42,$A0,$0C,$76,$39,$50,$0C
  DEFB $0E,$07,$76
TuneEnvelopes:
  DEFB $8A,$06,$01,$0F,$01,$0F,$FF,$01,$76,$8A,$06,$01,$0F,$01,$0F,$FF ; envelope
  DEFB $02,$76,$8A,$06,$02,$07,$01,$0F,$FF,$03,$76,$8A,$06,$02,$07,$01 ; sub-streams
  DEFB $0F,$FF,$04,$76,$8A,$06,$02,$07,$01,$0F,$FF,$05,$76,$8A,$06,$02 ; called by
  DEFB $07,$01,$0F,$FF,$06,$76,$8A,$06,$02,$07,$01,$0F,$FF,$07,$76,$8A ; all three
  DEFB $06,$02,$07,$01,$0F,$FF,$08,$76,$8A,$06,$02,$07,$01,$0F,$FF,$09 ; channels
  DEFB $76,$8A,$06,$02,$07,$01,$0F,$FF,$0A,$76,$8A,$06,$02,$07,$01,$0F ; ($8A n ...
  DEFB $FF,$0B,$76,$8A,$06,$02,$07,$01,$0F,$FF,$0C,$76,$8A,$06,$02,$07 ; $76)
  DEFB $01,$0F,$FF,$0D,$76,$8A,$06,$02,$07,$01,$0F,$FF,$0E,$76,$8A,$06
  DEFB $02,$07,$01,$0F,$FF,$0F,$76,$8A,$06,$04,$04,$01,$0F,$FF,$17,$76
  DEFB $8A,$09,$01,$0F,$01,$03,$FF,$05,$32,$00,$32,$76

; The tune's three channel records, 80 bytes each: A, B, C
;
; TuneTick passes IX = $BE7D, $BECD, $BF1D. +0/+1 the note's period, +2 the
; note's ticks left, +3 the volume, +4/+5 (5 at the start, +5 = 1 at a note: no
; reader), +6 the tone register (A 0, B 2, C 4), +7 the volume register (8, 9,
; 10), +8 the volume ceiling, +9 the transpose, +$0A the note length, +$0B the
; mixer bits (A $09, B $12, C $24), +$0C the call depth, +$0D the deferred
; read, +$0E-+$18 the call return points (2 bytes each), +$19 the pitch offset,
; +$1A the pitch envelope index, +$1B/+$1C/+$1D/+$1E the pitch counters, the
; step and the reload, +$1F the pitch table's length and +$20 on its entries,
; +$35 the volume envelope index, +$36/+$37/+$38/+$39 the volume counters, the
; step and the reload, +$3A the volume table's length and +$3B on its entries.
;
; Only the fixed fields (+6, +7, +$0B) matter in the image; the rest is set by
; TuneStart and the streams (written in c128 only).
TuneChannels:
  DEFB $3C,$00,$1E,$0A,$05,$05,$00,$08,$0F,$00,$1E,$09,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$09
  DEFB $02,$01,$02,$04,$FF,$02,$02,$01,$02,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$06,$03,$05,$01,$0F,$FF
  DEFB $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
TuneChannelB:
  DEFB $3C,$00,$1E,$0A,$04,$04,$02,$09,$0F,$00,$1E,$12,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$09
  DEFB $03,$01,$01,$06,$FF,$01,$03,$01,$01,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$06,$03,$05,$01,$0F,$FF
  DEFB $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
TuneChannelC:
  DEFB $3C,$00,$1E,$0F,$04,$04,$04,$0A,$0F,$00,$1E,$24,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$09
  DEFB $03,$01,$01,$06,$FF,$01,$03,$01,$01,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$06,$03,$05,$01,$0F,$FF
  DEFB $03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
