; --------------------------------------------------------------------------------------------------------------------
; system.asm: Interrupt set-up, random numbers, screen clear and fades
;
; The start-up routines that every other module leans on: the IM 2 vector table and its jump to the frame handler, the
; five-byte random number generator, the attribute fade and the screen clear.
;
; The vector table fills $FE00-$FF00 with $FD, so whatever the bus holds the CPU jumps to $FDFD, where a JP to the
; frame handler sits. The generator is seeded from R mixed with the first five bytes of the ROM.
; --------------------------------------------------------------------------------------------------------------------

; Install the IM 2 vector table and seed the random number generator
;
; Fills the 257 bytes $FE00-$FF00 with $FD, writes JP $A9E4 at $FDFD, sets I =
; $FE and IM 2. Interrupts stay disabled (DI on entry): the caller enables
; them.
;
; Then seeds RandomSeed ($7F71-$7F75): each byte is R XOR the matching ROM byte
; at $0000-$0004.
;
; Input: none. Output: A, B, DE, HL changed. Called once from the start-up (48K
; c1: 1 entry).
;
; With K-MOUSE the fill starts at $FEE8 (the operand at $851E), past the mouse
; driver at $FE00 (src/game/setup.asm).
SetUpInterrupts:
  DI
  LD A,$FE
  LD I,A
  IM 2
  LD HL,VectorTable
  LD A,$FD
FillVectorPage:
  LD (HL),A               ; $FE00-$FEFF, then one more byte at $FF00
  INC L
  JR NZ,FillVectorPage
  INC H
  LD (HL),A
  LD A,$C3
  LD (InterruptJump),A
  LD HL,TitleInterrupt
  LD (InterruptHandler),HL
  LD HL,$0000
  LD DE,RandomSeed
  LD B,$05
SeedRandomLoop:
  LD A,R                  ; R XOR ROM byte, five times
  XOR (HL)
  LD (DE),A
  INC L
  INC DE
  DJNZ SeedRandomLoop
  RET

; Next random number in A
;
; A shift-register generator over the five bytes $7F71-$7F75: rotates $7F75
; right through carry, mixes the neighbour bytes (nibble swap, XOR) and shifts
; the bytes down; the new $7F71 byte is returned in A.
;
; BC, DE and HL are preserved by storing them into the operands of the three
; loads at the end ($8581, $8584, $8587), so the routine needs no stack beyond
; its own return address (it is called while SP points into data, e.g. from
; InitStars).
;
; Output: A random byte, F changed. Callers all over the game (stars, enemies,
; effects): the most called helper.
Random:
  LD (RandomRestoreHL+$0001),HL
  LD (RandomRestoreDE+$0001),DE
  LD (RandomRestoreBC+$0001),BC
  LD HL,RandomSeed+$0004
  RR (HL)
  DEC HL
  LD A,(HL)
  LD E,A
  RRA
  LD D,A
  DEC HL
  LD A,(HL)
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD B,A
  DEC HL
  LD A,(HL)
  INC HL
  LD (HL),A
  SRL A
  SRL A
  SRL A
  SRL A
  OR B
  XOR D
  LD B,A
  LD A,C
  INC HL
  LD (HL),A
  LD A,(RandomSeed)
  LD (RandomSeed+$0001),A
  LD A,B
  LD (RandomSeed),A
  LD A,E
  INC HL
  LD (HL),A
  LD A,B
RandomRestoreBC:
  LD BC,$0000             ; operand written on entry: the caller's BC
RandomRestoreDE:
  LD DE,$0000             ; the caller's DE
RandomRestoreHL:
  LD HL,$0000             ; the caller's HL
  RET

; Fade out, then clear the attributes and the bitmap
;
; Calls FadeAttributes, waits for one frame, sets the border black, clears the
; attributes $5800-$5AFF to 0 and the bitmap $4000-$57FF to 0 (LD (HL),L with L
; = 0).
;
; Input: none. Output: BC, DE, HL changed; interrupts enabled. 48K c1: 4
; entries (between the screens of the attract cycle and the game start).
ClearScreen:
  CALL FadeAttributes
  LD HL,$5800
  LD DE,$5801
  LD BC,$02FF
  EI
  HALT
  XOR A
  OUT ($FE),A
  LD (HL),$00
  LDIR
  LD HL,$4000
  LD DE,$4001
  LD BC,$17FF
  LD (HL),L
  LDIR
  RET

; Fade the whole attribute area to black in four steps
;
; Four passes over $5800-$5AFF (3 pages): each pass ANDs every attribute with
; the mask 7, 3, 1, 0 (the ink fades, paper and bright vanish at once), three
; frames (HALT) apart. Enables interrupts.
;
; Output: BC, E, HL changed. Called by ClearScreen (48K c1: 4 entries).
FadeAttributes:
  LD E,$04
  LD C,$07
  EI
FadeStep:
  LD B,$03                ; one pass: 3 frames, then the mask over all 768
                          ; attributes
  LD HL,$5800
  HALT
  HALT
  HALT
FadeCell:
  LD A,(HL)
  AND C
  LD (HL),A
  INC L
  JP NZ,FadeCell
  INC H
  DJNZ FadeCell
  SRL C
  DEC E
  JR NZ,FadeStep
  RET
