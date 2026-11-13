; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The hand-over from the resident and the sequence: logo, credits, menu
;
; The resident loads the block (the turbo loader at $FF02, called from $F08A) and calls FrontMain $7800 (CALL $7800 at
; $F08D, c1 frame 7826). FrontMain shows the logo until SPACE, cycles the credits until SPACE, then runs the menu; the
; menu's START GAME returns from FrontMain (by dropping the menu's own return, at StartGame $99DD) to the resident at
; $F090, which clears the score, sets the lives and loads stage 1 (IY = $F0EA, the stage record of stage 1, then CALL
; $F1CA). The front passes nothing to the resident: no register and no variable; the key readers and KeyXorMask are
; what DEFINE KEYS and SELECT JOYSTICK leave.
;
; FrontColdEntry $781E, a second entry that saves the caller's return and stack and sets its own IM 2 vector, is never
; called (no caller in the resident or the block; not executed in c1 or menu).
; --------------------------------------------------------------------------------------------------------------------

  ORG $7800

; The front: the logo, the credits, wipe the text lines, the menu; returns on
; START GAME
;
; Called by the resident (CALL $7800 at $F08D) once the block is loaded.
; ShowLogo $785A (the logo until SPACE, then its box wiped), CreditsLoop $9509
; (until SPACE), the four text lines of the box wiped (ClearTextLine $9D65 with
; the lines 68, 84, 100, 116), then Menu $99A8. Menu returns only for START
; GAME, and then not here: StartGame $99DD drops FrontMain's return address, so
; the RET there goes straight back to the resident at $F090. The RET at $781D
; is not executed in any recording (c1, menu).
;
; c1: entered at frame 7826; the logo from 7848, SPACE seen at 7938, the
; credits from 7967, SPACE seen in the credits at 8063, the menu from 8127,
; START GAME at 8491, back in the resident at about 8558 (c1's L1 with the
; front's bytes: $7803, $7806, $7808, $780B, $7812-$781A ran once).
;
; Witness: L1 2 (c1, rzx-r0).
FrontMain:
  CALL ShowLogo
  CALL CreditsLoop
FrontWipeBox:
  LD A,$44                ; the credits returned (SPACE): wipe the four text
                          ; lines of the box
  CALL ClearTextLine
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD A,$74
  CALL ClearTextLine
FrontRunMenu:
  CALL Menu               ; the menu (returns only by StartGame's dropped
                          ; return, to the resident)
  RET

; A second entry: save the caller's return and SP, own stack, own IM 2 vector,
; keys active low, then FrontMain
;
; Pops the return address into SavedReturn $FE06, black border (OUT ($FE),0),
; keeps SP in SavedStack $FE04, sets SP = $FFFF, sets the IM 2 jump to
; Im2Handler $F9B3 with SetIm2Front $783B, clears KeyXorMask $FCFA and jumps to
; FrontMain. No instruction of the resident or the block jumps or calls here,
; and nothing reads SavedReturn or SavedStack: not executed in any recording
; (c1, menu). The resident's own set-up does the same work before it loads the
; block (SetIm2 $F635, c1 frame 5166).
;
; Witness: L1 0 ().
FrontColdEntry:
  DI
  POP HL
  LD A,$00
  OUT ($FE),A
  LD (SavedReturn),HL
  LD (SavedStack),SP
  LD SP,$FFFF
  LD HL,Im2Handler
  CALL SetIm2Front
  XOR A
  LD (KeyXorMask),A
  JP FrontMain

; Save the IM 2 jump's three bytes to SavedIm2Jump, write JP HL there, I = $FD,
; IM 2, EI
;
; In: HL = the handler. The three bytes at Im2Jump $FEFE go to SavedIm2Jump
; $FE01 first (LDIR), then $C3 and HL are written at $FEFE, I = $FD (the table
; $FD00-$FE00 of $FE), IM 2, EI. The resident's SetIm2 $F635 with the save
; added. Called only by FrontColdEntry: not executed in any recording (c1,
; menu).
;
; Witness: L1 0 ().
SetIm2Front:
  DI
  PUSH HL
  LD HL,Im2Jump
  LD DE,SavedIm2Jump
  LD BC,$0003
  LDIR
  POP HL
  DI
  LD A,$C3
  LD (Im2Jump),A
  LD (Im2Jump+1),HL
  LD A,$FD
  LD I,A
  IM 2
  EI
  RET
