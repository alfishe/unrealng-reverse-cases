; --------------------------------------------------------------------------------------------------------------------
; util.asm: Printing, distances, random numbers
; --------------------------------------------------------------------------------------------------------------------

; Print a character of the ROM font at a screen address
;
; A = the character code, HL = the screen address (top pixel row of a cell).
; Copies the 8 bytes of the ROM font (`$3C00` + 8A: `$3D00` is the space) down
; the cell (INC D). Out: HL + 1 (the next column); BC, DE kept.
;
; Callers: PrintString `$94F9` (the menu), `$BD75`/`$BD78` (the score and high
; score), PrintDigitAt `$9136`.
;
; Witness: L1 1933 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PrintChar:
  PUSH BC
  PUSH DE
  PUSH HL
  EX DE,HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$3C00             ; the ROM font: $3C00 + 8 * code
  ADD HL,BC
  LD B,$08
PrintCharRow:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ PrintCharRow
  POP HL
  POP DE
  POP BC
  INC HL
  RET

; Print A in decimal, left-aligned in three columns
;
; A = 0-255, DE = the screen address. Builds three ASCII digits at
; `$5BA6-$5BA8` (hundreds, tens, units, by repeated subtraction), skips the
; leading zeros (the units digit always prints), prints the digits through
; PrintDigitAt `$9136` and then a space for each skipped zero, so the field is
; always three cells.
;
; The only callers are at `$A7F4`, `$A7FD` and `$A806` (the countdown's days,
; hours and minutes after a text printed by PrintString `$94F9`): not executed
; in any recording (c1, explorers, gameover, rzx x31); known only from the
; code.
;
; Witness: L1 0 ().
PrintByte:
  PUSH AF
  LD HL,DigitBuffer
  LD (HL),$30
PrintByteHundreds:
  CP $64
  JR C,PrintByteTensStart
  SUB $64
  INC (HL)
  JR PrintByteHundreds
PrintByteTensStart:
  INC HL
  LD (HL),$30
PrintByteTens:
  CP $0A
  JR C,PrintByteUnitsStart
  SUB $0A
  INC (HL)
  JR PrintByteTens
PrintByteUnitsStart:
  INC HL
  LD (HL),$30
PrintByteUnits:
  CP $01
  JR C,PrintByteDigits
  DEC A
  INC (HL)
  JR PrintByteUnits
PrintByteDigits:
  LD HL,DigitBuffer             ; B = 1 + the leading zeros
  LD A,$30
  LD B,$01
  CP (HL)
  JR NZ,PrintByte3Digits
  INC B
  INC HL
  CP (HL)
  JR NZ,PrintByte2Digits
  INC B
  INC HL
  JR PrintByte1Digit
PrintByte3Digits:
  CALL PrintDigitAt
  INC HL
  INC E
PrintByte2Digits:
  CALL PrintDigitAt
  INC HL
  INC E
PrintByte1Digit:
  CALL PrintDigitAt
  INC E
  EX DE,HL
  DJNZ PrintBytePad
  JR PrintByteDone
PrintBytePad:
  LD A,$20                ; a space for each leading zero
  CALL PrintChar
  DJNZ PrintBytePad
PrintByteDone:
  POP AF
  RET

; Print the character at (HL) at screen DE
;
; HL = the character, DE = the screen address; PrintChar `$90C6`; HL and DE
; kept. Called three times by PrintByte `$90E1`; not executed in any recording;
; known only from the code.
;
; Witness: L1 0 ().
PrintDigitAt:
  PUSH HL
  PUSH DE
  LD A,(HL)
  EX DE,HL
  CALL PrintChar
  POP DE
  POP HL
  RET

; Are two objects within 16 (or 8) pixels on both axes?
;
; IX = the first object (X at +0, Y at +1, the sprite frame at +2), IY = the
; second (X, Y). The distance is 16, or 8 when IX's frame is `$5C-$5F`
; (`$914E`: rzx only, 3169 runs). Out: carry set when |X1 - X2| and |Y1 - Y2|
; are both below it. BC kept.
;
; Callers: `$B44A`, `$B5E1`, `$B74D`/`$B765`, `$BB70` (52660 calls), `$C0E0`:
; the touch test of the hero against items and creatures. The SkoolKit title
; ("classify object type") names only its first lines.
;
; Witness: L1 67291 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
Near:
  PUSH BC
  LD A,(IX+$02)
  LD C,$10
  CP $5C
  JR C,NearDx
  CP $60
  JR NC,NearDx
  LD C,$08
NearDx:
  LD A,(IX+$00)
  SUB (IY+$00)
  JR NC,NearCheckX
  NEG
NearCheckX:
  CP C
  JR NC,NearDone
  LD A,(IX+$01)
  SUB (IY+$01)
  JR NC,NearCheckY
  NEG
NearCheckY:
  CP C
NearDone:
  POP BC                  ; carry: within the distance
  RET

  ORG $9390

; A pseudo-random byte from R and a 16-bit linear congruential state
;
; RandomState `$93AD` = RandomState * 257 + 41 (mod 65536: HL + L * 256 +
; `$29`); then with HL = `$8F47` + the state's low byte, A = (R XOR H) + L.
; `$8F47` is only an odd constant: nothing is read there (the SkoolKit "stride
; table" is not one). Out: A; HL and DE kept, flags changed.
;
; The only caller is `$BFA9` in `$BFA0` (382 calls over all builds).
;
; Witness: L1 382 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx).
Random:
  PUSH HL
  PUSH DE
  LD HL,(RandomState)
  LD D,L
  LD E,$00
  ADD HL,DE
  LD DE,$0029
  ADD HL,DE
  LD (RandomState),HL
  LD H,$00
  LD DE,$8F47             ; the constant $8F47, not an address
  ADD HL,DE
  LD A,R
  XOR H
  ADD A,L
  POP DE
  POP HL
  RET

; Random's 16-bit state: 12345 ($3039) as loaded
;
; Read and written only by Random `$9390`.
RandomState:
  DEFW $3039
