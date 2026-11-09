; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 interrupt handler: FRAMES, the tune player and the play clock
;
; The IM 2 vector is the ROM word at $3AFF ($FFFF); the byte $18 at $FFFF and the ROM's $F3 make JR $FFF4, and JP
; $7F14 there enters Im2Handler. IM 2 is set only in play (SetIm2 $A7D4 at each life start); the menus run in IM 1
; with the ROM's handler, so none of this runs on the menu pages except the demo (DemoPage calls LifeStart at $8196:
; IM 2, with the tune off by $819B) (t1, the tape recording that never starts a game, has no entry at all).
;
; One entry per accepted frame interrupt: FRAMES + 1, TunePlayer (a note through the ROM's BEEPER every third entry),
; Im2Clock (the play time in BCD seconds every 50 entries). i1: 25 747 entries in 30 440 frames.
;
; The handler is not re-entrant by design (DI on entry, all registers on the stack, EI only before its RET), and the
; only EI inside it is the one BEEPER executes before its RET. Every note ends 19 000-34 000 T before the next frame
; interrupt (TunePlayer), so the window in which an interrupt could be accepted at $7F8D is never open: no recording
; has an interrupt taken inside $7F14-$7FBE or BEEPER (the L1 builds attribute every interrupt to the routine it
; interrupted, none to these).
;
; After the code: Atari's copyright line $7FBF and zero fill to $7FFF, never read by any build: a leftover. The title
; prints its own copyright (TitleText $8413).
; --------------------------------------------------------------------------------------------------------------------

; The IM 2 interrupt handler: FRAMES + 1, one TunePlayer step, one Im2Clock
; step
;
; Entered from JP $7F14 at $FFF4 (the IM 2 vector $FFFF). DI, then pushes AF,
; BC, DE, HL, AF again (EXX does not swap AF, so AF' is never saved: neither
; the handler nor BEEPER uses it), BC', DE', HL', IX, IY: with the return
; address 22 bytes. FRAMES $5C78 + 1, and FRAMES+2 ($5C7A, as IY+$40 with the
; BASIC's IY = $5C3A) + 1 when the low word wraps. Then TunePlayer $7F47 and
; Im2Clock $7F98, the registers back, EI, RET.
;
; The stack: interrupted at the game's lowest SP $C316, the frame fills
; $C300-$C315 (IY = $5C3A at $C300), CALL TunePlayer puts $7F34 at $C2FE,
; TunePlayer's CALL BEEPER puts $7F8D at $C2FC, then CALL Im2Clock overwrites
; $C2FE with $7F37. So the words stage 1 saw at $C2FC-$C311 (i1 frame 10000:
; $7F8D, $7F37, $5C3A ...) are one ordinary, non-nested frame: $7F8D left from
; the note, $7F37 from the clock call (not the tune player call), $5C3A the
; pushed IY. $C2FC is the deepest the stack goes.
;
; A nested entry is possible only at $7F8D: BEEPER ends EI, RET, so an
; interrupt still asserted when that RET ends would be taken before the DI at
; $7F8D. It would do no harm: it pushes a second frame below $C2FC (down to
; $C2E6), FRAMES + 1 and the clock + 1 are correct for the frame that passed,
; and the tune counter $B240, just reset to 0 by the outer pass, only goes to 1
; (no second note, the tune pointer $B23E untouched). It does not happen
; (Interrupt module header; open point in the notes).
;
; Witness: game 11 644 entries (frames 1560-16 759), a1 2090, g1 3351, p2 4612,
; h1 3351, i1 25 747 (264-30 439), i2 28 601, h2 288; t1 none. Each entry runs
; the whole body.
Im2Handler:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  EXX
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  EXX
  LD HL,(FRAMES)
  INC HL
  LD (FRAMES),HL
  LD A,H
  OR L
  JR NZ,Im2HandlerSteps
  INC (IY+$40)            ; FRAMES+2 through IY: the handler relies on IY =
                          ; $5C3A
Im2HandlerSteps:
  CALL TunePlayer         ; the tune, then the clock
  CALL Im2Clock
  EXX                     ; $7F37, the return of CALL Im2Clock, is the word
                          ; stage 1 saw at $C2FE
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EXX
  POP HL
  POP DE
  POP BC
  POP AF
  EI                      ; the only EI of the handler: the next interrupt is
                          ; taken after the RET, in the interrupted code
  RET

; One step of the tune: every third entry the next word of the tune at $B4E6, a
; note through BEEPER or a rest
;
; $B240 counts the handler's entries 0-2; on the third it goes back to 0 and
; one tune word is taken from the pointer $B23E (then pointer + 2): 0 is a
; rest, $FFFF sends the pointer back to $B4E6 and takes the first word again,
; anything else is BEEPER's period itself. With $B288 bit 7 set (the tune off:
; the T key, $AF15) a note is a rest too, so the tune keeps its place while
; silent.
;
; A note: HL = the word, BEEPER's period (INC HL at $7F68 for the end test, DEC
; HL at $7F7C back), DE = the cycles: the smallest n with n x H >= 16 (H the
; period's high byte), so every note lasts about the same: 8 n (HL + 30) T.
; Over the tune's 16 periods ($0231-$06CE) that is 35 700-50 500 T, so a note
; started by an entry at the frame interrupt ends well inside that frame, never
; across the next interrupt. A rest is a delay loop of $05C0 passes (about 38
; 000 T). After BEEPER (which ends EI) a DI at $7F8D before returning into the
; handler.
;
; Witness: entered once per handler entry (i1 25 747); a word taken i1 8600
; times, a note i1 7793 (BEEPER called from $7F8A), a rest i1 787; the tune
; wrapped at $7F6D i1 20 times, i2 22. a1: notes 341 of 626 words (the tune off
; 2540-2740).
TunePlayer:
  LD HL,TuneDivider
  LD A,(HL)
  INC A
  LD (HL),A
  CP $03
  RET NZ
  XOR A                   ; the third entry: counter back to 0, one tune word
  LD (HL),A
TuneNextWord:
  LD IX,(TunePointer)     ; HL = the next word, the pointer + 2
  LD L,(IX+$00)
  INC IX
  LD H,(IX+$00)
  INC IX
  LD (TunePointer),IX
  LD A,H                  ; 0: a rest
  OR L
  JR Z,TuneRest
  INC HL                  ; $FFFF: the end mark, back to the start of the tune
                          ; $B4E6
  LD A,H
  OR L
  JR NZ,TuneNote
  LD HL,Tune
  LD (TunePointer),HL
  JR TuneNextWord
TuneNote:
  LD A,(PlayerFlags)      ; the tune off ($B288 bit 7): a rest instead
  AND $80
  JR NZ,TuneRest
  DEC HL                  ; HL = the period, B = 16, DE = 1, A = H
  LD B,$10
  LD DE,$0001
  LD A,H
TuneCycles:
  CP B                    ; DE + 1 until DE x H >= 16
  JR NC,TuneBeep
  INC DE
  ADD A,H
  JR TuneCycles
TuneBeep:
  CALL BEEPER              ; BEEPER: HL period, DE cycles
  DI                      ; BEEPER's EI is undone here: the return address
                          ; $7F8D is the word at $C2FC on the deepest stack
  RET
TuneRest:
  LD BC,$05C0             ; a silent note: $05C0 passes of the delay loop
TuneRestLoop:
  DEC BC
  LD A,B
  OR C
  JR NZ,TuneRestLoop
  RET

; The play clock: every 50 entries the BCD seconds $B285/$B286 + 1 and the HUD
; time marked stale
;
; $B287 counts the handler's entries; at 50 it goes back to 0, $B239 = 0 (the
; HUD redraws the time: $922A) and the BCD seconds $B286 (low) / $B285 (high) +
; 1. It counts handler entries, not frames: an interrupt that is not taken is
; not counted.
;
; The branch $7FA1-$7FAB tests the tune counter $B240 for 3 and would set $B287
; to 49 (the second one entry later); TunePlayer always leaves $B240 at 0-2, so
; $7FA8 never ran in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2):
; known only from the code.
;
; Witness: one entry per handler entry; a second counted game 231 times, a1 41,
; i1 511, i2 570.
Im2Clock:
  LD HL,PlayerFrames
  LD A,(HL)
  INC A
  LD (HL),A
  CP $32
  RET NZ
  LD A,(TuneDivider)      ; the tune counter is never 3 here (TunePlayer resets
                          ; it): the next two lines never run
  CP $03
  JR NZ,ClockSecond
  LD A,$31
  LD (HL),A
  RET
ClockSecond:
  XOR A                   ; the next second: counter 0, the HUD time stale, BCD
                          ; + 1
  LD (HL),A
  LD (TimeShown),A
  LD HL,PlayerTime+$0001
  LD A,(HL)
  INC A
  DAA
  LD (HL),A
  DEC HL
  LD A,(HL)
  ADC A,$00
  DAA
  LD (HL),A
  RET

; Leftover: "c 1984 Atari Inc. All Rights Reserved" with a 0 after it, never
; read
;
; No build reads $7FBF-$7FFF (l1sum.py --reads 7FBF-7FFF: no reads in game, a1,
; g1, t1, p2, h1, i1, i2, h2) and no operand in the image points at it. The
; text the title prints is TitleText $8413.
CopyrightLeftover:
  DEFM "c 1984 Atari Inc. All Rights Reserved",$00

; Leftover: 27 zero bytes up to $7FFF, never read
CopyrightPadding:
  DEFS $1B
