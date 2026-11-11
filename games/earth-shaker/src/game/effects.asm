; --------------------------------------------------------------------------------------------------------------------
; effects.asm: The beeper effects, the noise loops and the teleport's attribute flash
;
; Every sound but the tunes goes through ROM BEEPER $03B5 (HL = the period, DE = the cycles) or a loop that sends bit
; 4 of port $FE. One sound a pass is chosen by PassSound $E83A: a thud (ThudSound $8228) when a boulder landed or was
; pushed, else the fall noise (FallSound $E7A9) when an object fell. The gem, the exit, the timer, the death and the
; specials make their own sounds when they happen.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7300

; Four attribute screens of 768 bytes the teleport effect copies to $5800 in
; turn
;
; TeleportFlashOut $9230 and TeleportFlashIn $924F step AnimPhase $FD72 up or
; down (0-3) and copy frame AnimPhase ($7300 + 768 x phase) to the attributes.
; Witness: the rzx builds read all four frames.
TeleportFrames:
  INCBIN "res/graphics/teleport-frames.bin",$0000,3072

  ORG $8228

; The landing / push thud, registers kept
;
; NoiseThud $E77C with AF, BC, DE, HL saved.
;
; Witness: L1 3435 (c1, hiscore, rzx x29).
ThudSound:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  CALL NoiseThud
  POP BC
  POP HL
  POP DE
  POP AF
  RET

; Leftover: 28 bytes, never run
ThudSoundPad:
  DEFB $E1,$2B,$3E,$04,$BC,$20,$F3,$C9
  DEFB $21,$46,$00,$11,$01,$00,$E5,$D5
  DEFB $CD,$B5,$03,$D1,$E1,$2B,$3E,$32
  DEFB $BD,$20,$F3,$C9

; The pass sound: JP PassSoundJump
;
; JP PassSoundJump $E7E5 (the 1990 version moved the choice to PassSound
; $E83A).
;
; Witness: L1 44097 (c1, hiscore, lives, timer, rzx x32).
PassSoundEntry:
  JP PassSoundJump

; The fall noise if a boulder or another object fell
;
; A = BoulderFell $7FFF (from PassSound): not 0 plays FallSound $E7A9; else
; ObjectFell $7FFE not 0 does.
;
; Witness: L1 40715 (c1, hiscore, lives, timer, rzx x32).
FallSoundChoice:
  OR A
  LD A,A
  JR Z,FallSoundChoiceSkip
  CALL FallSound
  RET
FallSoundChoiceSkip:
  LD A,(ObjectFell)
  OR A
  RET Z
  CALL FallSound
  RET

; Leftover: one byte, never run
FallSoundPad:
  DEFB $C9

  ORG $82F9

; The gem sound
;
; ROM BEEPER HL = $0200, DE = 5, then HL = $0100, DE = 10.
;
; Witness: L1 1680 (c1, rzx x32).
GemSound:
  LD HL,$0200
  LD DE,$0005
  CALL RomBeeper
  LD HL,$0100
  LD DE,$000A
  CALL RomBeeper
  LD HL,$0080
  LD DE,$0014
  CALL RomBeeper
  RET

  ORG $8548

; The dig noise's entry: LD HL,$00FF, whose $00 is the loop's NOP at $854A
;
; CALL $8548 from DigNoiseIfDug $E860: HL = $00FF, then DigNoiseLoop $854A
; sends the ROM bytes $00FF-$0001 AND $18 to port $FE. mkgame keeps the two
; bytes as data because $854A starts an instruction too.
DigNoise:
  DEFB $21,$FF

; The noise loop: (HL) AND $18 to port $FE for HL down to 0
;
; Witness: L1 991362 (c1, rzx x31).
DigNoiseLoop:
  NOP
  LD A,(HL)
  AND $18
  OUT ($FE),A
  DEC HL
  LD A,H
  OR L
  JR NZ,DigNoiseLoop
  RET

  ORG $861F

; Leftover: 15 bytes before DeathSound, never run
DeathSoundPad:
  DEFB $21,$00,$40,$7C,$BA,$28,$05,$CB
  DEFB $3E,$23,$18,$F7,$10,$F2,$C9

; The death sound's entry: LD HL,$0000, whose second $00 is the loop's NOP at
; $8630
;
; CALL $862E from PlayCave $8885 after a kill: HL = 0, then DeathLoop $8630.
; Witness: the c1 build's crush (frame 13218), death-crush (frame 30),
; death-fire (frame 288). mkgame keeps the two bytes as data because $8630
; starts an instruction too.
DeathSound:
  DEFB $21,$00

; 256 ROM BEEPER notes, periods and lengths from the ROM's bytes
;
; For L down from 0 (256 steps): HL = the period (the ROM byte at H = 0, L), DE
; = (L / 4) AND 15.
;
; Witness: L1 255 (c1).
DeathLoop:
  NOP
  LD A,L
  RRCA
  RRCA
  AND $0F
  LD E,A
  LD D,$00
  PUSH HL
  LD L,(HL)
  CALL RomBeeper
  POP HL
  DEC L
  JR NZ,DeathLoop
  RET

; Leftover: 17 bytes, never run
DeathLoopPad:
  DEFB $C9,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$E8,$1D,$7B,$FE,$01,$20,$DD
  DEFB $C9

  ORG $9072

; The exit opens: a sweep
;
; LD C,(HL) then AND $7F: the AND acts on A, so C keeps the full ROM byte (a 0
; byte gives a 256-turn low half).
;
; Witness: L1 32 (rzx x31).
ExitOpenSound:
  DI
  LD HL,$0180
ExitOpenSoundLoop:
  LD C,(HL)
  AND $7F
  LD B,$08
ExitOpenSoundLoop2:
  XOR A
  OUT ($FE),A
  LD E,C
ExitOpenSoundLoop3:
  DEC E
  JR NZ,ExitOpenSoundLoop3
  LD A,$18
  OUT ($FE),A
  LD E,L
ExitOpenSoundLoop4:
  DEC E
  JR NZ,ExitOpenSoundLoop4
  DJNZ ExitOpenSoundLoop2
  DEC L
  JR NZ,ExitOpenSoundLoop
  EI
  RET

  ORG $90A0

; A rasp: the key redefined, a bubble burst
;
; Witness: L1 145 (c1, menu, rzx x20).
RaspSound:
  LD HL,$0000
  LD DE,$0001
RaspSoundLoop:
  PUSH HL
  LD L,(HL)
  PUSH DE
  CALL RomBeeper
  POP DE
  POP HL
  DEC L
  JR NZ,RaspSoundLoop
  RET

  ORG $9230

; The teleport: the next attribute frame up
;
; Witness: L1 912 (rzx x19).
TeleportFlashOut:
  LD HL,TeleportFrames
  LD DE,$0300
  LD A,(AnimPhase)
  INC A
  AND $03
  LD (AnimPhase),A
  OR A
  JR Z,TeleportFlashOutSkip
  LD B,A
TeleportFlashOutLoop:
  ADD HL,DE
  DJNZ TeleportFlashOutLoop
TeleportFlashOutSkip:
  LD DE,Attributes
  LD BC,$0300
  LDIR
  RET

; The teleport: the next attribute frame down
;
; Witness: L1 912 (rzx x19).
TeleportFlashIn:
  LD HL,TeleportFrames
  LD DE,$0300
  LD A,(AnimPhase)
  DEC A
  AND $03
  LD (AnimPhase),A
  OR A
  JR Z,TeleportFlashInSkip
  LD B,A
TeleportFlashInLoop:
  ADD HL,DE
  DJNZ TeleportFlashInLoop
TeleportFlashInSkip:
  LD DE,Attributes
  LD BC,$0300
  LDIR
  RET

  ORG $A713

; A self-modified BEEPER sweep
;
; Witness: L1 81 (c1, menu, rzx x23).
Jingle:
  DI
  LD HL,$0140
JingleLoop:
  LD C,(HL)
  LD E,C
  LD D,$80
JingleHighLoop:
  DEC E
  JR NZ,JingleSkip
  LD A,C
JingleHighShift:
  LD B,$05
JingleLoop2:
  RRCA
  AND $7F
  DJNZ JingleLoop2
  LD E,A
  LD A,$18
  OUT ($FE),A
  JR JingleLowLoop
JingleSkip:
  DEC D
  JR NZ,JingleHighLoop
  JR JingleSkip3
JingleLowLoop:
  DEC E
  JR NZ,JingleSkip2
  LD A,C
JingleLowShift:
  LD B,$01
JingleLoop3:
  RRCA
  AND $7F
  DJNZ JingleLoop3
  LD E,A
  XOR A
  OUT ($FE),A
  JR JingleHighLoop
JingleSkip2:
  DEC D
  JR NZ,JingleLowLoop
JingleSkip3:
  DEC L
  JR NZ,JingleLoop
  EI
  RET

; The switch's sound
;
; Witness: L1 27 (c1, menu, rzx x23).
SwitchSound:
  LD A,$03
  LD (JingleHighShift+$0001),A
  LD A,$03
  LD (JingleLowShift+$0001),A
  CALL Jingle
  LD A,$04
  LD (JingleHighShift+$0001),A
  LD A,$02
  LD (JingleLowShift+$0001),A
  CALL Jingle
  LD A,$05
  LD (JingleHighShift+$0001),A
  LD A,$01
  LD (JingleLowShift+$0001),A
  CALL Jingle
  RET

; While FizzCount runs down: one beep a pass
;
; Witness: L1 44097 (c1, hiscore, lives, timer, rzx x32).
FizzSound:
  CALL PassSoundEntry
  NOP
  NOP
  NOP
  NOP
  NOP
  LD A,(FizzCount)
  OR A
  RET Z
  DEC A
  LD (FizzCount),A
  RLCA
  RLCA
  RLCA
  RLCA
  LD L,A
  LD H,$00
  LD DE,$0014
  CALL RomBeeper
  RET

  ORG $E740

; ROM bytes as noise
;
; Witness: L1 10973 (c1, hiscore, rzx x30).
NoiseBurst:
  DI
  LD HL,$0140
  XOR A
  OUT ($FE),A
NoiseBurstStep:
  LD BC,$1001
NoiseBurstPitch:
  LD D,$02
NoiseBurstLoop:
  LD A,(HL)
  AND $3F
  CP D
  JR C,NoiseBurstSkip
  OR $07
NoiseBurstSkip:
  SUB D
  LD E,A
NoiseBurstLoop2:
  DEC E
  JR NZ,NoiseBurstSkip2
  LD A,$18
  OUT ($FE),A
  JR NoiseBurstSkip3
NoiseBurstSkip2:
  DJNZ NoiseBurstLoop2
  DEC C
  JR NZ,NoiseBurstLoop2
  JR NoiseBurstSkip5
NoiseBurstSkip3:
  LD E,D
NoiseBurstLoop3:
  DEC E
  JR NZ,NoiseBurstSkip4
  XOR A
  OUT ($FE),A
  JR NoiseBurstLoop
NoiseBurstSkip4:
  DJNZ NoiseBurstLoop3
  DEC C
  JR NZ,NoiseBurstLoop3
NoiseBurstSkip5:
  DEC L
  JR NZ,NoiseBurstStep
  DEC H
  JR NZ,NoiseBurstStep
  EI
  RET

; The thud: NoiseBurst with a short length
;
; Witness: L1 3435 (c1, hiscore, rzx x29).
NoiseThud:
  LD D,$06
NoiseThudLoop:
  LD A,D
  LD (NoiseBurstPitch+$0001),A
  PUSH DE
  CALL NoiseBurst
  POP DE
  DEC D
  DEC D
  JR NZ,NoiseThudLoop
  RET

  ORG $E7A9

; The fall noise
;
; Witness: L1 3591 (c1, rzx x32).
FallSound:
  DI
  LD HL,$010A
  XOR A
  OUT ($FE),A
FallSoundLoop:
  LD BC,$0001
  LD D,$01
FallSoundLoop2:
  LD A,(HL)
  AND $3F
  CP D
  JR C,FallSoundSkip
  OR $07
FallSoundSkip:
  SUB D
  LD E,A
FallSoundLoop3:
  DEC E
  JR NZ,FallSoundSkip2
  LD A,$18
  OUT ($FE),A
  JR FallSoundSkip3
FallSoundSkip2:
  DJNZ FallSoundLoop3
  DEC C
  JR NZ,FallSoundLoop3
  JR FallSoundSkip5
FallSoundSkip3:
  LD E,D
FallSoundLoop4:
  DEC E
  JR NZ,FallSoundSkip4
  XOR A
  OUT ($FE),A
  JR FallSoundLoop2
FallSoundSkip4:
  DJNZ FallSoundLoop4
  DEC C
  JR NZ,FallSoundLoop4
FallSoundSkip5:
  DEC L
  JR NZ,FallSoundLoop
  DEC H
  JR NZ,FallSoundLoop
  EI
  RET

; JP PassSound
;
; Witness: L1 44097 (c1, hiscore, lives, timer, rzx x32).
PassSoundJump:
  JP PassSound

; Leftover: an older pass sound choice (13 bytes)
PassSoundOld:
  DEFB $B7,$28,$04,$CD,$28,$82,$C9,$3A
  DEFB $FF,$7F,$C3,$53,$82

  ORG $E860

; The dig noise when DugEarth
;
; Witness: L1 20716 (c1, rzx x32).
DigNoiseIfDug:
  LD A,(DugEarth)
  CP $FF
  CALL Z,DigNoise
  RET

  ORG $E87B

; The teleport out: sound and attribute frames
;
; Witness: L1 57 (rzx x19).
TeleportOutEffect:
  DI
  XOR A
  LD B,$10
  LD HL,$00FF
  LD DE,$00FF
TeleportOutEffectLoop:
  PUSH BC
  LD BC,$0010
TeleportOutEffectLoop2:
  DEC E
  JR NZ,TeleportOutEffectSkip
  XOR $18
  OUT ($FE),A
  LD E,L
TeleportOutEffectSkip:
  DEC D
  JR NZ,TeleportOutEffectSkip2
  XOR $18
  OUT ($FE),A
  LD D,H
TeleportOutEffectSkip2:
  DJNZ TeleportOutEffectLoop2
  DEC C
  JR NZ,TeleportOutEffectLoop2
  PUSH BC
  PUSH HL
  PUSH DE
  PUSH AF
  CALL TeleportFlashOut
  POP AF
  POP DE
  POP HL
  POP BC
  POP BC
  DJNZ TeleportOutEffectLoop
  EI
  RET

; The teleport in: sound and attribute frames
;
; Witness: L1 57 (rzx x19).
TeleportInEffect:
  DI
  XOR A
  LD B,$10
  LD HL,$F1F2
  LD DE,$F1F2
TeleportInEffectLoop:
  PUSH BC
  LD BC,$0010
TeleportInEffectLoop2:
  DEC E
  JR NZ,TeleportInEffectSkip
  XOR $18
  OUT ($FE),A
  LD E,L
TeleportInEffectSkip:
  DEC D
  JR NZ,TeleportInEffectSkip2
  XOR $18
  OUT ($FE),A
  LD D,H
TeleportInEffectSkip2:
  DJNZ TeleportInEffectLoop2
  DEC C
  JR NZ,TeleportInEffectLoop2
  PUSH BC
  PUSH HL
  PUSH DE
  PUSH AF
  CALL TeleportFlashIn
  POP AF
  POP DE
  POP HL
  POP BC
  POP BC
  DJNZ TeleportInEffectLoop
  EI
  RET
