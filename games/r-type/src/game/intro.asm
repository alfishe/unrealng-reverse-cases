; --------------------------------------------------------------------------------------------------------------------
; intro.asm: The loading screen scroller
; --------------------------------------------------------------------------------------------------------------------

; Show the title picture and scroll the credits along the bottom
;
; Copies TitleScreen (6912 bytes) to the screen; then each character of
; ScrollerText in turn is printed at the right of the bottom rows and the rows
; scrolled left (ScrollRowLeft) with a HALT a step, until the text's last
; character; then a wait.
;
; Witness: L1 1 (c1).
ShowLoadingScreen:
  XOR A
  OUT ($FE),A
  LD HL,TitleScreen
  LD DE,$4000
  LD BC,$1B00
  LDIR
  LD HL,ScrollerText
l_8160:
  BIT 7,(HL)
  JR NZ,l_8192
  SET 7,(HL)
  PUSH HL
  LD BC,$161F
  CALL PrintText
  LD B,$04
l_816F:
  PUSH BC
  LD HL,$50DF
  CALL ScrollRowLeft
  LD HL,$50FF
  CALL ScrollRowLeft
  LD HL,$50DF
  CALL ScrollRowLeft
  LD HL,$50FF
  CALL ScrollRowLeft
  HALT
  POP BC
  DJNZ l_816F
  POP HL
  RES 7,(HL)
  INC HL
  JR l_8160
l_8192:
  LD B,$64
  CALL WaitFrames
  RET

; Scroll 32 bytes of pixel lines left by one pixel (RL (HL) from the right end)
;
; Witness: L1 7440 (c1).
ScrollRowLeft:
  LD C,$08
l_819A:
  PUSH HL
  LD B,$1F
  AND A
l_819E:
  RL (HL)
  DEC HL
  DJNZ l_819E
  POP HL
  INC H
  DEC C
  JR NZ,l_819A
  RET

; `STOP THE TAPE $` and the credits: R TYPE, PROGRAMMED BY BOB PAPE, GRAPHICS,
; SOUND, IREM 1987, ELECTRIC DREAMS 1988
ScrollerText:
  INCBIN "res/texts/scroller.bin",$0000,466

; eight zeros after the text
ScrollerEnd:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The IM 2 target: JP Interrupt (every vector of Im2Table is $83, so the CPU
; jumps to $8383)
;
; Witness: L1 159333 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
Im2Jump:
  JP Interrupt

; The enemy shots, 3 bytes each (direction and kind, column, row):
; MoveEnemyShots
EnemyShots:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
ShipTrail:
  DEFB $00,$00,$00        ; the ship's last positions for the bits (TrailPoint)
  DEFB $00,$00,$00
  DEFB $00,$00
BeamShot:
  DEFB $00,$00,$00        ; the beam shot: length, row, column
AntiAirShots:
  DEFB $00,$00,$00        ; the two anti-air shot records ($83E5, $83E9)
  DEFB $00,$00,$00
  DEFB $00,$00
MissileTimer:
  DEFB $00,$00,$00        ; frames before the missiles may fire again
  DEFB $00,$00
ShipEntry:
  DEFB $00                ; the ship's fly-in: 1 flying in, 2 turning back, 0
                          ; done
BeamHudText:
  DEFB $3A,$3C,$3C        ; the HUD text DrawHud prints after BEAM-
  DEFB $3C,$3C,$3C
  DEFB $3C,$3C,$3C
  DEFB $3C,$3C,$BB
  DEFB $00
Im2Table:
  DEFB $83,$83,$83        ; the IM 2 vector table: 257 bytes of $83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83,$83
  DEFB $83,$83
EnemySlots:
  DEFB $00,$00,$00        ; 28 enemy slots of 9 bytes: flags, position, script
  DEFB $00,$00,$00        ; and kind pointers, movers
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
