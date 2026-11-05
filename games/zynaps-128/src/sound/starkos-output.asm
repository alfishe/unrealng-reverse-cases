; --------------------------------------------------------------------------------------------------------------------
; starkos-output.asm: the period table, sending the registers, Stop, Init
;
; SendRegisters writes the AY. The CPC's STarKos player keeps a cache of the 14 register values and the last value
; sent of each; here each register's value is the operand of LD A,n (AYRegN+1) and the value last sent the operand of
; CP n (AYRegN+3), and only a changed register is written, to $FFFD (the register number) and $BFFD (the value). Each
; write is followed by nine NOPs and a tenth before the next: the 28-byte rows keep the layout of a longer port
; sequence (the CPC writes the AY through its PPI) with the Spectrum's two OUTs in place. R13, the envelope shape, is
; written when it changed or when Retrigger is set (the hardware line's retrigger bit, at its first frame).
;
; PeriodTable is the CPC's: note 12 is 3822 (C0 at the CPC's 1 MHz AY clock) and each note a tempered semitone higher;
; notes 0-11 are 0 (their periods do not fit in 12 bits). The table was not converted for the ZX's 1.7734 MHz
; (Pentagon 1.75 MHz): docs/09-sound.md 9.6.
;
; Init takes the song's header into the player's operands and runs ResetTable (zero the register cache and counters,
; $FF the last-sent values and instrument speeds, OR A the loop flags), so a second Init starts the song afresh. Stop
; silences the AY.
; --------------------------------------------------------------------------------------------------------------------

; the tone period of notes 0-95 (the CPC's table)
;
; Read by InstrumentLine (PeriodOfNote, HardPeriod): $860D + 2 x the note (at
; most 95). 3822 at note 12 is C0 at 1 MHz; on the ZX the same period is 1.7734
; times higher (9.92 semitones; 9.69 on the Pentagon's 1.75 MHz).
PeriodTable:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0EEE,$0E18,$0D4D,$0C8E,$0BDA,$0B2F,$0A8F,$09F7,$0968,$08E1,$0861,$07E9
  DEFW $0777,$070C,$06A7,$0647,$05ED,$0598,$0547,$04FC,$04B4,$0470,$0431,$03F4
  DEFW $03BC,$0386,$0353,$0324,$02F6,$02CC,$02A4,$027E,$025A,$0238,$0218,$01FA
  DEFW $01DE,$01C3,$01AA,$0192,$017B,$0166,$0152,$013F,$012D,$011C,$010C,$00FD
  DEFW $00EF,$00E1,$00D5,$00C9,$00BE,$00B3,$00A9,$009F,$0096,$008E,$0086,$007F
  DEFW $0077,$0071,$006A,$0064,$005F,$0059,$0054,$0050,$004B,$0047,$0043,$003F
  DEFW $003C,$0038,$0035,$0032,$002F,$002D,$002A,$0028,$0026,$0024,$0022,$0020

; write the registers that changed to the AY, then R13 if changed or
; retriggered
;
; Input: A = R7 (the mixer). H = R7, C = $FD, D = $FF, E = $BF; per register in
; the order R0, R1, R8, R2, R3, R9, R4, R5, R10, R6, R7, R11, R12, R13: the
; value (AYRegN+1) compared with the last sent (AYRegN+3), written when they
; differ (OUT ($FFFD) the number, OUT ($BFFD) the value) and kept. R13: also
; when Retrigger is not 0 (an envelope restarts at each write). 567 runs (566
; frames and Stop).
SendRegisters:
  LD H,A
  LD C,$FD
  LD DE,$FFBF
  NOP
  NOP
  NOP
  NOP
AYReg0:
  LD A,$00                ; AYReg0+1: R0 to send (channel A period low, IY of
                          ; channel A), AYReg0+3: R0 sent
  CP $00
  JR Z,AYReg1
  LD L,$00
  LD B,D
  OUT (C),L               ; the register number to $FFFD
  LD B,E
  OUT (C),A               ; the value to $BFFD
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg0+$0003),A
  NOP
AYReg1:
  LD A,$00                ; R1 (IY+$1B of channel A)
  CP $00
  JR Z,AYReg8
  LD L,$01
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg1+$0003),A
  NOP
AYReg8:
  LD A,$00                ; R8, channel A's volume (IY+$36)
  CP $00
  JR Z,AYReg2
  LD L,$08
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg8+$0003),A
  NOP
AYReg2:
  LD A,$00                ; R2 (IY of channel B)
  CP $00
  JR Z,AYReg3
  LD L,$02
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg2+$0003),A
  NOP
AYReg3:
  LD A,$00                ; R3
  CP $00
  JR Z,AYReg9
  LD L,$03
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg3+$0003),A
  NOP
AYReg9:
  LD A,$00                ; R9, channel B's volume
  CP $00
  JR Z,AYReg4
  LD L,$09
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg9+$0003),A
  NOP
AYReg4:
  LD A,$00                ; R4 (IY of channel C)
  CP $00
  JR Z,AYReg5
  LD L,$04
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg4+$0003),A
  NOP
AYReg5:
  LD A,$00                ; R5
  CP $00
  JR Z,AYReg10
  LD L,$05
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg5+$0003),A
  NOP
AYReg10:
  LD A,$00                ; R10, channel C's volume
  CP $00
  JR Z,AYReg6
  LD L,$0A
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg10+$0003),A
  NOP
AYReg6:
  LD A,$00                ; R6, the noise period
  CP $00
  JR Z,AYReg7
  LD L,$06
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg6+$0003),A
  NOP
AYReg7:
  LD A,H                  ; R7 from H; AYReg7+2: R7 sent
  CP $C0
  JR Z,AYReg11
  LD L,$07
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg7+$0002),A
  NOP
AYReg11:
  LD A,$00                ; R11, the envelope period low
  CP $00
  JR Z,AYReg12
  LD L,$0B
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg11+$0003),A
  NOP
AYReg12:
  LD A,$00                ; R12
  CP $00
  JR Z,AYReg13
  LD L,$0C
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg12+$0003),A
  NOP
AYReg13:
  LD A,$00                ; R13, the envelope shape (AYReg13+3: the shape sent)
  CP $FF
  JR NZ,WriteR13          ; changed: write it
  LD H,A
Retrigger:
  LD A,$00                ; Retrigger+1: not 0, write R13 even unchanged (a
                          ; hardware line's bit 6)
  OR A
  RET Z
  LD A,H
WriteR13:
  LD L,$0D
  LD B,D
  OUT (C),L
  LD B,E
  OUT (C),A
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD (AYReg13+$0003),A
  RET

; silence the AY
;
; The three volumes' values 0 and their last-sent values $FF (so they are
; written), R7's last sent $FF, then SendRegisters with A = $3F: tone and noise
; off on all channels. Run once in c1, when the intro ends ($60BA).
Stop:
  XOR A
  LD (AYReg8+$0001),A
  LD (AYReg9+$0001),A
  LD (AYReg10+$0001),A
  DEC A
  LD (AYReg8+$0003),A
  LD (AYReg9+$0003),A
  LD (AYReg10+$0003),A
  LD (AYReg7+$0002),A
  LD A,$3F
  JP SendRegisters

; take a song: its header into the player, the variables reset
;
; Input: DE = the song (SK10 at $8990). Header byte 6 to SpecialDrum+4 (the
; drum channel); bytes 9-24: the heights, linker, special list and instrument
; table addresses and the four loop points into HeightPointer+1,
; LinkerPointer+1, SpecialListPointer+1, TrackAInstrTable+1, TranspLoop+1,
; HeightLoop+1, LinkerLoop+1, SpecialListLoop+1; byte 25 the speed into Speed+1
; and SpeedCounter+1 (the first Play reads a line); the transposition stream
; from byte 26. LinkerEnd = the special list; SpecialMode and SpecialModeLoop
; from bit 0 of the special list's first and loop entries; the instrument table
; copied to tracks B and C; the instrument pointers, loop and end addresses of
; all three channels set to instrument 0's line; NewPatternFlag = SCF; then
; ResetTable. Run once in c1 (frame 2182 window, the intro's $6061).
Init:
  LD HL,$0006
  ADD HL,DE
  LD A,(HL)
  LD (SpecialDrum+$0004),A
  LD DE,$0003
  ADD HL,DE
  LD DE,HeightPointer+$0001
  LDI
  LDI
  LD DE,LinkerPointer+$0001
  LDI
  LDI
  LD DE,SpecialListPointer+$0001
  LDI
  LDI
  LD DE,TrackAInstrTable+$0001
  LDI
  LDI
  LD DE,TranspLoop+$0001
  LDI
  LDI
  LD DE,HeightLoop+$0001
  LDI
  LDI
  LD DE,LinkerLoop+$0001
  LDI
  LDI
  LD DE,SpecialListLoop+$0001
  LDI
  LDI
  LD A,(HL)
  INC HL
  LD (Speed+$0001),A
  LD (SpeedCounter+$0001),A
  LD (TranspPointer+$0001),HL
  LD HL,(SpecialListPointer+$0001)
  LD (LinkerEnd+$0001),HL
  LD A,(HL)
  AND $01
  LD (SpecialMode+$0001),A
  LD HL,(SpecialListLoop+$0001)
  LD A,(HL)
  AND $01
  LD (SpecialModeLoop+$0001),A
  LD HL,(TrackAInstrTable+$0001)
  LD (TrackBInstrTable+$0001),HL
  LD (TrackCInstrTable+$0001),HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD BC,$0007
  ADD HL,BC
  LD (ChanAInstrPointer+$0001),HL
  LD (ChanBInstrPointer+$0001),HL
  LD (ChanCInstrPointer+$0001),HL
  LD (ChanAInstrLoop+$0001),HL
  LD (ChanBInstrLoop+$0001),HL
  LD (ChanCInstrLoop+$0001),HL
  EX DE,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (ChanAZeroEnd+$0001),DE
  LD (ChanBZeroEnd+$0001),DE
  LD (ChanCZeroEnd+$0001),DE
  LD (ChanAInstrEnd+$0001),DE
  LD (ChanBInstrEnd+$0001),DE
  LD (ChanCInstrEnd+$0001),DE
  LD A,$37
  LD (NewPatternFlag),A
  LD HL,ResetTable        ; the reset table
ResetLoop:
  LD A,(HL)               ; a count (0 ends), a value, then count addresses
                          ; that get the value
  OR A
  RET Z
  LD B,A
  INC HL
  LD A,(HL)
  INC HL
ResetNext:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (DE),A
  DJNZ ResetNext
  JR ResetLoop

; the variables Init resets: groups of a count, a value and the count addresses
; that get it
;
; Read by ResetLoop. Three groups: 24 operands set to 0 (the register values
; R0-R6 and R8-R13, the transposition, height, special and special-list waits,
; the instrument frame counters, the tracks' attenuations), 17 set to $FF (the
; last-sent values of R0-R13, so that every register is written at the first
; frame, and the instruments' speeds), 3 set to $B7 (OR A: the instruments do
; not loop); a count of 0 ends it. R7's value is not in it: SendRegisters takes
; it from A.
ResetTable:
  DEFB $18,$00            ; 24 addresses get 0
ResetZeroList:
  DEFW AYReg0+1,AYReg1+1,AYReg2+1,AYReg3+1
  DEFW AYReg4+1,AYReg5+1,AYReg6+1,AYReg8+1
  DEFW AYReg9+1,AYReg10+1,AYReg11+1,AYReg12+1
  DEFW AYReg13+1,TranspWait+1,HeightWait+1,SpecialSameWait+1
  DEFW SpecialListWait+1,SpecialWait+1,ChanAInstrCounter+1,ChanBInstrCounter+1
  DEFW ChanCInstrCounter+1,TrackAVolume+1,TrackBVolume+1,TrackCVolume+1
ResetFF:
  DEFB $11,$FF            ; 17 addresses get $FF
ResetFFList:
  DEFW AYReg0+3,AYReg1+3,AYReg2+3,AYReg3+3
  DEFW AYReg4+3,AYReg5+3,AYReg6+3,AYReg7+2
  DEFW AYReg8+3,AYReg9+3,AYReg10+3,AYReg11+3
  DEFW AYReg12+3,AYReg13+3,ChanAInstrSpeed+1,ChanBInstrSpeed+1
  DEFW ChanCInstrSpeed+1
ResetLoops:
  DEFB $03,$B7            ; 3 addresses get $B7
ResetLoopsList:
  DEFW ChanAInstrLoops,ChanBInstrLoops,ChanCInstrLoops
ResetEnd:
  DEFB $00                ; 0: the end of the table

; three bytes no instruction reads, up to the song
Padding:
  DEFB $00,$00,$00
