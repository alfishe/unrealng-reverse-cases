; --------------------------------------------------------------------------------------------------------------------
; utils.asm: The keyboard, the pause, the random numbers, the score
; --------------------------------------------------------------------------------------------------------------------

; The first key down on the keyboard, as KeyTable gives it (ASCII; 1 CAPS
; SHIFT, 2 SYMBOL SHIFT, 13 ENTER), 0 for none
;
; The rows $FEFE to $7FFE in turn, bits 0-4 of each; the first 0 bit gives
; KeyTable's byte. BC and HL kept; D and E changed. Callers: the menu ($6DE0),
; the define keys ($6FE8), the Hall of Fame display ($717E), GameOver,
; HofNameRead. The same scan is inlined in WaitKeyOrFire $7CEC.
ReadKey:
  PUSH BC
  PUSH HL
  LD HL,KeyTable
  LD D,$FE
ReadKeyRow:
  LD A,D
  IN A,($FE)
  LD E,$01
  LD B,$05
ReadKeyBit:
  RRCA
  JR NC,ReadKeyFound
  INC HL
  SLA E
  DJNZ ReadKeyBit
  RLC D
  JR C,ReadKeyRow
ReadKeyFound:
  LD A,(HL)
  POP HL
  POP BC
  RET

; The 40 keys in the order of the rows $FE ... $7F and their bits 0-4, then 0
; (no key)
;
; CAPS SHIFT is 1, SYMBOL SHIFT 2, ENTER 13, SPACE 32, the rest their
; characters: (CS) Z X C V, A S D F G, Q W E R T, 1 2 3 4 5, 0 9 8 7 6, P O I U
; Y, (ENTER) L K J H, (SPACE) (SS) M N B. The define-keys screen ($7CF9) uses
; it too.
KeyTable:
  DEFB $01,$5A,$58,$43,$56
  DEFB $41,$53,$44,$46,$47
  DEFB $51,$57,$45,$52,$54
  DEFB $31,$32,$33,$34,$35
  DEFB $30,$39,$38,$37,$36
  DEFB $50,$4F,$49,$55,$59
  DEFB $0D,$4C,$4B,$4A,$48
  DEFB $20,$02,$4D,$4E,$42
  DEFB $00

; Waits until no key of the keyboard is down
;
; Used by the routines at DefineKeys, GameOver, HofMakeRoom, BonusScreen and
; PauseWait.
WaitNoKey:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,WaitNoKey
  RET

; Key 3 alone of the row 1-5 pauses the game until another key or fire
;
; Main loop ($765F). The row $F7FE AND $1F = $1B: only "3" down. Then
; PauseWait. c1 and the warps: 3260 / 61 667 passes, never "3" (the pause never
; ran in case.json's recordings). exD's d1 held "3" 20 frames in play, then P:
; PauseWait ($AD2A-$AD35) ran and WaitKeyOrFire $7CEC was entered once; the
; game went on after P.
PauseKey:
  LD A,$F7
  IN A,($FE)
  AND $1F
  CP $1B
  RET NZ

; The pause: a short delay, wait for 3 up, then WaitKeyOrFire $7CEC
;
; A short delay, wait for "3" up, then WaitKeyOrFire returns (to the main loop)
; on any key or fire. Ran only in exD's d1 (not a case.json build): no
; case.json run pressed 3.
PauseWait:
  LD BC,$01F4
  CALL Delay
  CALL WaitNoKey          ; WaitNoKey: 3 up
  JP WaitKeyOrFire        ; WaitKeyOrFire returns to the main loop

; A pseudo-random byte: Seed = 13 (Seed + 7), A = A XOR the seed's high byte
;
; The seed RandomSeed is a word; HL, DE, BC kept. The incoming A is XORed in
; (callers mostly then AND a mask). The game's one random source (c1: 20 875
; calls).
Random:
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,(RandomSeed)
  LD DE,$0007
  ADD HL,DE
  LD E,L
  LD D,H
  ADD HL,HL
  ADD HL,HL
  LD C,L
  LD B,H
  ADD HL,HL
  ADD HL,BC
  ADD HL,DE
  LD (RandomSeed),HL
  XOR H
  POP BC
  POP DE
  POP HL
  RET

; The random seed (Random)
RandomSeed:
  DEFW $0000

; Adds the 6 ASCII digits ending at DE to the score, then prints it on the HUD
;
; In: DE = the last digit of an addend of PointValues. The score's digits
; $AD8A-$AD8F from the last: digit + digit - "0" + carry, past "9" less 10 and
; a carry. A carry out of the sixth digit is lost (the score wraps at 1 000
; 000). Then PrintChar's $5B00 mark 0 and ScoreText printed. All registers
; kept. Warps: 5614 entries.
AddScore:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD C,$00
  LD HL,Score+$0005
  LD B,$06
AddScoreLoop:
  LD A,(DE)
  ADD A,(HL)
  SUB $30
  ADD A,C
  CP $3A
  LD C,$01
  JR C,AddScoreNoCarry
  SUB $0A
  JR AddScoreDigit
AddScoreNoCarry:
  DEC C
AddScoreDigit:
  LD (HL),A
  DEC HL
  DEC DE
  DJNZ AddScoreLoop
  XOR A
  LD (PrintCharLine+$001E),A
  LD HL,ScoreText
  CALL PrintString
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; The HUD score: attribute $45, font $D7E0, at 23,14, the six digits, $FF
ScoreText:
  DEFM $E0,"E",$E6,$E0,$D7,$DF,$17,$0E
Score:
  DEFM "000000"           ; the score: 6 ASCII digits (000000 at a new game,
                          ; $6D88)
  DEFM $FF                ; the end

; The ten addends of AddScore, 6 ASCII digits each: 25 50 100 125 150 200 250
; 300 350 1000
PointValues:
  DEFB $30,$30,$30,$30,$32,$35
Points50:
  DEFB $30,$30,$30,$30,$35,$30
Points100:
  DEFB $30,$30,$30,$31,$30,$30
Points125:
  DEFB $30,$30,$30,$31,$32,$35
Points150:
  DEFB $30,$30,$30,$31,$35,$30
Points200:
  DEFB $30,$30,$30,$32,$30,$30
Points250:
  DEFB $30,$30,$30,$32,$35,$30
Points300:
  DEFB $30,$30,$30,$33,$30,$30
Points350:
  DEFB $30,$30,$30,$33,$35,$30
Points1000:
  DEFB $30,$30,$31,$30,$30,$30

; A = 1 when D - B and E - C are both in -6..+8, else 0: a box test nothing
; calls
;
; LD A,D / SUB B / SUB 9 / CP $F1 / LD A,0 / RET C, the same for E and C, then
; INC A. Never ran in any recording: no CALL or JP in the image names $ADCD
; (dead code).
BoxOverlap:
  LD A,D
  SUB B
  SUB $09
  CP $F1                  ; D - B in -6..+8?
  LD A,$00
  RET C
  LD A,E                  ; the same for E - C
  SUB C
  SUB $09
  CP $F1
  LD A,$00
  RET C
  INC A                   ; both: A = 1
  RET
