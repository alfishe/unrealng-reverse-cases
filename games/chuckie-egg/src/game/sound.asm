; --------------------------------------------------------------------------------------------------------------------
; sound.asm: Printing a character, the beeper and the speech phrases
;
; PrintChar is the one text routine of the game. Beep drives the speaker directly; the IM 2 handler sends the phrases
; to port $9F, one pair every few interrupts.
; --------------------------------------------------------------------------------------------------------------------

; Print character A at row H (from the bottom), column L
;
; Four NOPs (room for a patch), then: the screen address of character row H (0
; = row 23 at the bottom, 23 = the top) and column L, the glyph CharacterSet +
; 8 x A, eight bytes down the cell. Registers kept. Witness: 33 112 calls (the
; map, the HUD, the pages, the scrollers).
PrintChar:
  NOP
  NOP
  NOP
  NOP
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH AF
  LD A,H
  EX DE,HL
  LD HL,Screen
  LD BC,$0800
  CP $10
  JR NC,PrintCharRow
  CP $08
  JR NC,PrintCharThird
  ADD HL,BC
PrintCharThird:
  ADD HL,BC
PrintCharRow:
  AND $07
  XOR $07
  SLA A
  SLA A
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD C,E
  ADD HL,BC
  POP AF
  PUSH AF
  LD C,A
  XOR A
  SLA C
  RLA
  SLA C
  RLA
  SLA C
  RLA
  LD B,A
  EX DE,HL
  LD HL,CharacterSet
  ADD HL,BC
  LD B,$08
PrintCharLine:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ PrintCharLine
  POP AF
  POP DE
  POP BC
  POP HL
  RET

; Leftover: POP BC, POP HL, RET, then zeros
;
; Never read (L1: no access): the end of an older PrintChar.
LeftoverCode9C8E:
  DEFB $C1,$E1,$C9,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The IM 2 entry: jump to PhraseInterrupt
;
; VectorTable $B200 holds $9C9C at every place (I = $B2, Start $A410), so every
; interrupt comes here. Witness: 127 166 interrupts in the eight builds.
PhraseVector:
  JP PhraseInterrupt

; 5 zeros
;
; Never read (L1: no access).
Zeros9C9F:
  DEFS $05

; Sound the speaker: L cycles of half period H
;
; OUT ($FE) $10 (the speaker bit, black border), wait H, OUT 0, wait H, L
; times. B and L used, A = 0 at the end. Calls: the walk ($2805 and $2806 every
; 4 pixels), the climb ($1E14, $1E15), the jump click, the time tick ($0402),
; the pickup sweep, the bonus count ($1E04). One cycle 26 H + 47 T (high 13 H +
; 14, low 13 H + 33): 3 500 000 / (26 H + 47) Hz; levels-1-3 edges match to the
; T-state but for the ULA's wait on OUT ($FE). Witness: 127 975 calls.
Beep:
  LD A,$10
  OUT ($FE),A
  LD B,H
BeepHigh:
  DJNZ BeepHigh
  XOR A
  OUT ($FE),A
  LD B,H
BeepLow:
  DJNZ BeepLow
  DEC L
  JR NZ,Beep
  RET

; 13 zeros
;
; Never read (L1: no access).
Zeros9CB5:
  DEFS $0D

; The interrupt: send the phrase's next allophone to port $9F
;
; PhraseTimer $FF: nothing to do. Otherwise it counts down; at 0 it takes the
; next pair at PhrasePtr: the first byte is the new timer (in interrupts; $FF
; ends the phrase), the second goes to port $9F (an SP0256-AL2 allophone,
; sound/Phrases.txt). EI and RETI; no keyboard scan (the ROM's KSTATE stands
; still under IM 2, which is why EnterHiScore switches to IM 1). Witness: 127
; 166 calls, one an interrupt.
PhraseInterrupt:
  PUSH AF
  PUSH HL
  LD A,(PhraseTimer)
  CP $FF
  JR Z,PhraseDone
  DEC A
  JR Z,PhraseNext
  LD (PhraseTimer),A
  JR PhraseDone
PhraseNext:
  LD HL,(PhrasePtr)
  LD A,(HL)
  LD (PhraseTimer),A
  CP $FF
  JR Z,PhraseDone
  INC HL
  LD A,(HL)
  OUT ($9F),A
  INC HL
  LD (PhrasePtr),HL
PhraseDone:
  POP HL
  EI
  POP AF
  RETI

; Start phrase A unless one is playing
;
; Input: A the phrase number 1-33. When PhraseTimer is $FF: PhrasePtr = the
; phrase's address from PhraseTable (PhraseTable - 2 + 2A), PhraseTimer = 1
; (the first pair goes at the next interrupt). Otherwise the call is lost.
; Callers: the title (20), the instructions (24), a player's turn (25 +
; player), the name entry (7), LevelPhrase, DeathPhrase, LiftPhrase. Witness:
; 106 calls.
StartPhrase:
  LD B,A
  LD A,(PhraseTimer)
  CP $FF
  RET NZ
  LD HL,PhraseTable-2
StartPhraseFind:
  INC HL
  INC HL
  DJNZ StartPhraseFind
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (PhrasePtr),DE
  LD A,$01
  LD (PhraseTimer),A
  RET

; 2 zeros
;
; Never read (L1: no access).
Zeros9D06:
  DEFS $02
