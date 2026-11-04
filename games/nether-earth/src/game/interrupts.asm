; the interrupt handler of play, one a frame
PlayInterrupt:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,TurnFrames             ; the frame counter: the play loop waits for 10
                          ; ($AE1D)
  INC (HL)
  LD HL,RadarOwn          ; the player's radar picture, cyan
  LD C,$4D
  LD A,(RadarPhase)            ; the other picture each frame
  XOR $01
  LD (RadarPhase),A
  JR Z,InterruptRadar
  LD HL,RadarEnemy        ; the enemy's radar picture, yellow
  LD C,$4E
InterruptRadar:
  CALL ShowRadar          ; show this frame's radar picture
  LD A,(SoundFx)            ; a sound effect running?
  OR A
  JR Z,InterruptExit
  INC A                   ; counts up each frame; $80 ends a rising one, 0 a
                          ; falling one
  CP $80
  JR NZ,InterruptSoundStore
  XOR A
InterruptSoundStore:
  LD (SoundFx),A            ; SoundFx = the count, the effect's next step
  OR A                    ; the flags of A: M noise, P the falling tone
  CALL NZ,SoundEffect
InterruptExit:
  POP HL                  ; restore the registers, on into EI; RET
  POP DE
  POP BC
  POP AF

; the interrupt handler while the start-up runs
StartInterrupt:
  EI
  RET

; Show radar picture HL (16 lines x 16 bytes) at (22,6) in attribute C
;
; The interrupt alternates the two pictures $D800 (terrain + the player's
; robots, attribute $4D) and $D900 (terrain + the enemy's robots, $4E) every
; frame, so the terrain stays and each side's robots blink in their colour. The
; attributes are rows 22 and 23, columns 6-21.
ShowRadar:
  PUSH BC
  LD B,$10
  LD DE,$50C6             ; screen line 0 of character row 22, column 6
RadarLineLoop:
  PUSH BC
  PUSH DE
  LD BC,$0010
  LDIR
  POP DE
  EX DE,HL
  CALL NextScreenLine
  EX DE,HL
  POP BC
  DJNZ RadarLineLoop
  POP BC
  LD HL,$5AC6             ; the attributes of row 22
  CALL FillAttr16
  LD L,$E6                ; row 23

; Write C into 16 bytes from HL
;
; Used by the routine at ShowRadar.
FillAttr16:
  LD B,$10
FillAttrLoop:
  LD (HL),C
  INC HL
  DJNZ FillAttrLoop
  RET

; The interrupt's sound: A = $FD53 (1-$7F a falling tone, $FD-$FF noise)
;
; A positive: a tone of ~500 / (A+2) pulses with a delay of A between them, the
; levels taken from bit 4 of the ROM bytes from $0000 (a rough noise), so the
; pitch falls as A counts up each frame. $FD53 = 1 when a shot is fired
; ($B709). A negative: 30 random speaker levels (Random): the crackle of a hit.
; The shot code sets $FC (a miss: 3 frames), $FA (a hit: 5 frames) or $C8 (a
; robot destroyed: 55 frames). Seen in the deep recording at frames
; 18680-18712: 1, 2, ... $16, then $FA-$FF.
SoundEffect:
  JP M,NoiseSound
  LD B,A                  ; B = the delay between pulses
  INC A
  INC A
  LD HL,$01F4             ; C = about 500 / (A + 2) pulses
  LD E,A
  LD D,$00
  LD C,$00
  XOR A
PulseCountLoop:
  INC C
  SBC HL,DE
  JR NC,PulseCountLoop
  LD HL,$0000             ; the ROM as noise
PulseLoop:
  PUSH BC
  LD A,(HL)
  INC HL
  AND $10
  OUT ($FE),A
PulseDelay:
  DJNZ PulseDelay
  POP BC
  DEC C
  JR NZ,PulseLoop
  XOR A                   ; speaker off
  OUT ($FE),A
  RET
NoiseSound:
  LD B,$1E
NoiseLoop:
  CALL Random
  AND $10
  OUT ($FE),A
  DJNZ NoiseLoop
  RET

; Build both radar pictures for the 128 columns from $FD1C
;
; Each map cell of the window is one pixel: set when its block type is $0F or
; more (the tall blocks). Copies the terrain picture to $D900, then puts the
; dot of every robot in play (+$01 not 0, except the one under direct control,
; +$0A = 2) into its side's picture (ToggleRadarDot). Called by $B029 when the
; ship moves the window ($FD52); once in the deep recording, at frame 35.
BuildRadar:
  LD HL,RadarOwn
  LD DE,(RadarColumn)
  LD A,D
  ADD A,$DD
  LD D,A
  LD BC,$1010             ; 16 rows of 16 bytes
RadarRowLoop:
  PUSH BC
  PUSH DE
RadarByteLoop:
  PUSH BC
  LD B,$08
RadarBitLoop:
  LD A,(DE)
  INC DE
  AND $1F
  CP $0F                  ; carry: the type is $0F or more
  CCF
  RL (HL)
  DJNZ RadarBitLoop
  INC HL
  POP BC
  DJNZ RadarByteLoop
  POP DE
  POP BC
  INC D                   ; the next map row
  INC D
  DEC C
  JR NZ,RadarRowLoop
  LD HL,RadarOwn          ; the same terrain for the enemy's picture
  LD DE,RadarEnemy
  LD BC,$0100
  LDIR
  LD IY,Robots            ; the robots
  LD B,$30
RadarRobotLoop:
  PUSH BC
  LD A,(IY+$01)
  OR A
  JR Z,RadarRobotNext
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  LD A,(IY+$0A)           ; not the robot under direct control (the ship's dot
                          ; stands for it)
  CP $02
  CALL NZ,ToggleRadarDot
RadarRobotNext:
  LD DE,$0010             ; the next 16-byte robot record
  ADD IY,DE
  POP BC
  DJNZ RadarRobotLoop
  RET

; XOR a 2x2 dot at map column HL, row C into radar picture B (0 player, 1
; enemy)
;
; The dot covers (x, y), (x+1, y) and the line above. Nothing outside the
; window (RadarDotAddress returns past this routine). XOR: the same call
; removes the dot again, so the robot code toggles the old position before
; PlaceRobot toggles the new one.
ToggleRadarDot:
  CALL RadarDotAddress
  LD C,A                  ; C = the pixel mask
  PUSH HL
  LD A,(HL)
  XOR C
  LD (HL),A
  RRC C                   ; the next pixel, maybe in the next byte
  JR NC,RadarDotRight
  INC HL
RadarDotRight:
  LD A,(HL)               ; the right pixel, maybe in the next byte
  XOR C
  LD (HL),A
  POP HL
  LD A,L                  ; the line above
  SUB $10
  LD L,A
  RLC C
  LD A,(HL)
  XOR C
  LD (HL),A
  RRC C
  JR NC,RadarDotAboveRight
  INC HL
RadarDotAboveRight:
  LD A,(HL)               ; the right pixel of the line above
  XOR C
  LD (HL),A
  RET

; HL = the radar byte of column HL, row C in picture B, A = the pixel mask
;
; Column x - $FD1C must be 0-126, else it pops the return address and returns
; from ToggleRadarDot. Address = $D800 + $100*B + 16*y + (x-$FD1C)/8, mask =
; $80 >> ((x-$FD1C) AND 7).
RadarDotAddress:
  LD DE,(RadarColumn)
  XOR A
  SBC HL,DE
  LD A,H
  OR A
  JR NZ,RadarDotOutside
  LD A,L
  CP $7F
  JR NC,RadarDotOutside
  LD A,$D8                ; $D800 or $D900
  ADD A,B
  LD H,A
  LD A,L
  AND $07
  INC A
  LD B,A
  LD A,L                  ; L = 16*y + x/8
  RLCA
  AND $F0
  OR C
  RLCA
  RLCA
  RLCA
  RLCA
  LD L,A
  XOR A                   ; the mask: $80 shifted right x AND 7 times
  SCF
RadarMaskShift:
  RRA                     ; $80 shifted right (x AND 7) times
  DJNZ RadarMaskShift
  RET
RadarDotOutside:
  POP HL                  ; outside the window: return from ToggleRadarDot too
  RET
