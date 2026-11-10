; --------------------------------------------------------------------------------------------------------------------
; beeper.asm: The two beeper routines: the disaster noise and the refusal tone
;
; NoiseBurst (the disasters, through FireNoise, FloodNoise, CrashNoise and the earthquake) and ToneBeep (the two
; refusals of the tools, Refuse $71E4). Both write the speaker bit of port $FE directly. NoiseBurst runs with
; interrupts off (DI ... EI), so the frame's interrupt waits; ToneBeep leaves them on.
; --------------------------------------------------------------------------------------------------------------------

; The disaster noise: 200 loops of the beeper from Random, gated by the SOUND
; option
;
; Input: E the pitch mask (each loop sends a new random speaker bit when D AND
; E is 0: E = 0 every loop, 1 every second ...). Interrupts are off while it
; plays (DI ... EI), so the frame's interrupt is held and the task switch
; waits. Returns at once when SoundOn ($A32D) is 0, but after the DI: with
; SOUND off it returns with interrupts off, and they stay off until the next EI
; (a bug of the original). Callers: the disasters (Disaster $78BD, the fire and
; flood spread $9108, $9116).
;
; L1 764 (the disasters recording: 127-255 calls a disaster), 30 406 random
; bits sent.
NoiseBurst:
  DI
  LD A,(SoundOn)
  AND A
  RET Z
  LD BC,$00C8
  LD D,$00
NoiseLoop:
  INC D                   ; INC D; D AND E = 0: a new random bit to the speaker
  LD A,D
  AND E
  JR NZ,NoiseNext
  CALL Random
  AND $10
  OUT ($FE),A
NoiseNext:
  DEC BC                  ; 200 iterations
  LD A,B
  OR C
  JR NZ,NoiseLoop
  EI
  RET

; The refusal tone: 500 cycles of the speaker, 48 + 16 DJNZ loops a cycle (the
; beep of a refused tool)
;
; No inputs. The speaker on with L = $30 DJNZ loops, off with H = $10, 500
; times (DE = $01F4): 500 cycles of 889 T, 444 500 T uncontended, 127 ms;
; measured 164 ms (8.2 frames, tools frame 13 434), with contention and the
; interrupts. It is not gated by SoundOn. Reached by JP ToneBeep from Refuse
; $71E4 when a placement is refused (a tool too dear is refused silently by
; SelectTool's RET M). L1 3: 2 in tools (the occupied cell at frame 13 434
; traced, the other not located), 1 in bankrupt.
ToneBeep:
  LD HL,$1030
  LD DE,$01F4
ToneCycle:
  LD A,$10                ; speaker on for L loops
  OUT ($FE),A
  LD B,L
ToneHigh:
  DJNZ ToneHigh           ; DJNZ: the high half
  XOR A
  OUT ($FE),A
  LD B,H
ToneLow:
  DJNZ ToneLow            ; DJNZ: the low half
  DEC DE
  LD A,D
  OR E
  JR NZ,ToneCycle
  RET
