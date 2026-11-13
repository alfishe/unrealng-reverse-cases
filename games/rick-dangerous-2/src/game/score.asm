; --------------------------------------------------------------------------------------------------------------------
; score.asm: The score: the points records, the score digits, AddScore
;
; The score is six decimal digits, one a byte, the most significant first (Score, $7F1D-$7F22). AddScore adds a record
; of six digits in the same form; the records hold the points of each event. The HUD's score is drawn by $7A0C.
;
; The three counters beside the section variables: lives, the ray gun's bullets and the detonators, each 0-6, drawn in
; the HUD by $79C3, $79D1 and $79DF.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7ED3

; Add six decimal digits at HL to the score, draw it
;
; HL = a points record (six digits, the most significant first). From the last
; digit back: score digit + record digit + carry; 10 or more takes 10 off with
; the carry set. Then $7A0C draws the score. Changes A, B, DE, HL.
;
; The callers: $8C36 and $9F6D (Points50), $A595 (Points500), $9CD6
; (TimeBonus), TallyLives (Points100000) and level 5's own code at $F964;
; BonusTally (not run) adds Points100000, then Points5000 per bullet and
; Points10000 per detonator.
;
; Evidence: 149 runs in 47 builds (callers $8736 x5, $8C36 x5, $9CD6 x9, $9F6D
; x101, $A595 x28, $F964 x1); the RZX memory at level 5, frame 1000 holds 00 04
; 01 03 08 00 with "041380" on the screen (stage 1).
;
; Witness: L1 310 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke,
; rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, load-l5,
; sec-l2-s7, sec-l2-s12, sec-l5-s3).
AddScore:
  LD BC,$0005
  ADD HL,BC
  LD DE,Score+$0005
  LD B,$06
AddScoreLoop:
  LD A,(DE)               ; one digit, with the carry from the one after it
  ADC A,(HL)
  CP $0A
  JP C,AddScoreDigit
  SUB $0A
  SCF
  CCF
AddScoreDigit:
  CCF                     ; the digit stored, the carry for the next
  LD (DE),A
  DEC DE
  DEC HL
  DJNZ AddScoreLoop
  CALL DrawScore
  RET

  ORG $7EF3

; 50 points (000050)
;
; Added by $8C36 and $9F6D.
Points50:
  INCBIN "res/tables/points-50.bin",$0000,6

; 100 points (000100)
;
; No instruction in the image or the levels loads $7EF9 (no byte pair F9 7E in
; the 64 K image), and no recording reads it: unused.
Points100:
  INCBIN "res/tables/points-100.bin",$0000,6

; 500 points (000500)
;
; Added by $A595.
Points500:
  INCBIN "res/tables/points-500.bin",$0000,6

; 5000 points (005000): each bullet left at the Fat Guy's end
;
; Added by BonusTally ($86F1) for each bullet left (not executed in any
; recording).
Points5000:
  INCBIN "res/tables/points-5000.bin",$0000,6

; 10 000 points (010000): each detonator left at the Fat Guy's end
;
; Added by BonusTally ($8712) for each detonator left (not executed in any
; recording).
Points10000:
  INCBIN "res/tables/points-10000.bin",$0000,6

; 100 000 points (100000): the Fat Guy defeated, and each life left
;
; Added once by BonusTally ($86E0) and once a life by TallyLives (rzx-l5-23000:
; 5 additions).
Points100000:
  INCBIN "res/tables/points-100000.bin",$0000,6

; A bonus that counts down: 002000 when set, collected by $9CD6
;
; $9C97 sets its digits +2..+4 to 2, 0, 0 (2000) when Rick takes a certain
; object (the code at $9CAC), $9163 takes 1 off its digits +1..+4 every 25
; passes while $9BA9 is set, and $9CCA adds what is left to the score
; (AddScore, HL = $7F17).
TimeBonus:
  DEFB $00,$00,$00,$00,$00,$00

; The score: six decimal digits, the most significant first
;
; Cleared by ResetGame, added to by AddScore, drawn by $7A0C.
Score:
  DEFB $00,$00,$00,$00,$00,$00

  ORG $8B3B

; Rick's lives
;
; Set to 6 at a new game ($7CC2); a level start with fewer than 6 adds one
; ($7CE6; the bytes at $7CEE, INC A / LD ($8B3B),A: not executed in any
; recording); one off in LoseLife ($8A30, the POKE file's infinite lives); the
; main loop ends the game when Rick dies with 1 left ($7E10). Read by the HUD
; $79C3 and the end tally $8728.
Lives:
  DEFB $06

; The ray gun's bullets
;
; 6 at every level start ($7CF4) and after a death ($8A41), 6 again from an
; ammunition pickup ($A528), also written by $A2F7; one off per shot ($9593,
; unless $8066). The HUD: $79D1.
Ammunition:
  DEFB $06

; The detonators (bombs)
;
; 6 at every level start ($7CF7) and after a death ($8A44), 6 from a pickup
; ($A528), also written by $A2F7; one off per bomb ($95ED, $96B4, $9B27, unless
; $8066). The HUD: $79DF.
Detonators:
  DEFB $06

  ORG $9163

; Count the bonus down: 10 points every 25 passes
;
; Called by the object step ($86DB) every pass while BonusRunning is set (a map
; entry of kind $78 starts it, $9C97). BonusPrescaler counts 25 passes; then
; the digits $7F1B, $7F1A, $7F19, $7F18 (0-9 each, the bonus number $9C97 sets
; to 2000 with $7F19 = 2) are decremented with a borrow: the bonus loses 10
; every 25 passes (one a second at 25 passes a second; the value the HUD shows
; is for a run to confirm).
;
; Ran 12 127 times in 29 builds (levels 1, 2 and others; the borrow loop
; CountBonusDigitLoop 548 times). The bonus never ran out in any recording:
; from 0000 the borrow would leave 9999 and end at BonusRunOut.
;
; Witness: L1 24953 (cheats, rzx-l1-00000-poke, rzx-l1-06000-poke,
; rzx-l1-18000-poke, rzx-l1-24000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48).
CountBonus:
  LD A,(BonusPrescaler)
  DEC A
  LD (BonusPrescaler),A
  RET NZ
  LD A,$19
  LD (BonusPrescaler),A
  LD HL,TimeBonus+$0004
  LD B,$04
CountBonusDigitLoop:
  DEC (HL)                ; a digit below 0 becomes 9, borrow from the next one
                          ; up
  RET P
  LD (HL),$09
  DEC HL
  DJNZ CountBonusDigitLoop

; RET the end of CountBonus when all four digits borrowed (the bonus wrapped)
;
; A lone RET ($C9), reached only when the four digits $7F18-$7F1B all wrapped
; from 0 to 9. Not executed in any recording; a data entry because c1's
; power-on RAM test ($11CB) reads every byte, so the static walk does not take
; it as code.
;
; Witness: L1 0 ().
BonusRunOut:
  RET
