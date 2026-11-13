; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 set-up and the interrupt handler: the ticks, the COMPUTER line, the beeper effects
;
; The game runs in IM 2 from the entry on: SetupInterrupts $A2FA writes JP $A32A at $FDFD and 257 bytes of $FD at
; $FE00, I = $FE, so whatever the data bus holds the vector is $FDFD. InterruptHandler $A32A runs every frame (as many
; entries as frames in every RZX segment): it counts EnergyTick $A506 and FrameCounter $837F, scrolls or blinks the
; COMPUTER line a pixel a frame, then plays at most one beeper effect chosen by SoundFlags $A8A6 (PlaySoundFlags
; $A8A7). In the menu (MenuScroller $A103 set) it only scrolls the menu line and plays the effects.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A2FA

; IM 2: JP InterruptHandler at $FDFD, the vector table $FE00-$FF00 of $FD, I =
; $FE; the COMPUTER line empty
;
; Called once, by the entry's new game `$8408` (at `$8409`, interrupts off).
; Writes `$C3` to `$FDFD` and InterruptHandler's address to `$FDFE`;
; MessageText = BlankMessage (pending), MessagePointer = 0; 257 bytes of `$FD`
; from `$FE00` (B = 0 gives 256, then one more at `$FF00`), I = `$FE`, IM 2.
; The interrupt is enabled later by the callers (`EI` at `$843B`).
;
; Evidence: ran once in `c1g` (frame 15 752, the entry); the other recordings
; start from snapshots taken after it.
;
; Witness: L1 2 (c1, c1g).
SetupInterrupts:
  LD A,$C3
  LD (Im2Jump),A
  LD HL,InterruptHandler
  LD (Im2Jump+1),HL
  LD HL,BlankMessage
  LD (MessageText),HL
  LD HL,$0000
  LD (MessagePointer),HL
  LD HL,Im2Table             ; the table: 256 bytes of $FD, then $FF00
  LD BC,$00FD
FillVectorTableLoop:
  LD (HL),C
  INC HL
  DJNZ FillVectorTableLoop
  LD (HL),C
  LD A,$FE                ; I = $FE, IM 2
  LD I,A
  IM 2
  RET

; I = $3E and IM 1: back to the ROM's interrupt (no caller)
;
; `LD A,$3E; IM 1; LD I,A; RET`. No instruction in the image calls or jumps
; here and no recording ran it (known only from the code): the way back to the
; ROM's interrupt mode, perhaps for a version that returned to BASIC.
;
; Witness: L1 0 ().
RestoreIm1:
  LD A,$3E
  IM 1
  LD I,A
  RET

; Every frame: EnergyTick, FrameCounter, the COMPUTER line (scroll or blink),
; then the beeper effect
;
; Entered through `JP $A32A` at `$FDFD` (the IM 2 vector). Saves HL, DE, BC, AF
; (not IX, IY or the alternate set). With MenuScroller `$A103` set it goes to
; MenuScrollerTick `$A459`. Else:
;
; 1. EnergyTick `$A506` + 1 (DrainEnergy `$A613` compares it with the level's
; rate) and FrameCounter `$837F` + 1.
;
; 2. A new message (MessageText's high byte not 0): if a static message is in
; its blank phase (MessageState `$E6-$EF`) it is drawn at once (state `$F0`)
; and the new one waits a frame; else MessagePointer = MessageText, the high
; byte cleared; a text that starts with `$FE` is static (state `$FE`: the next
; frame clears the line and the blink starts at `$E6`), any other starts
; scrolling at its first character.
;
; 3. No new message: a static message counts its blink (`$E6-$EF` blank, `$F0`
; draw the 14 characters at `$50E1`, `$FF` clear the line `$50E0-$50EF` and
; back to `$E6`); a scrolling one shifts the 5 pixel rows `$50E0-$50EF` (row
; 23, columns 0-15, scan lines 0-4) a pixel left with the next column of
; MessageGlyph coming in at the right, and every 8 pixels loads the next
; character (`$FF`: the word after it is where the text goes on; jumping back
; to BlankMessage clears MessageNumber).
;
; 4. InterruptExit `$A450`: PlaySoundFlags `$A8A7`, the registers back, `EI`,
; `RET`.
;
; The POKE file's "Infinite lives" 41784,0 writes `NOP` over the `INC A` at
; `$A338`: EnergyTick never moves, so the energy never drains.
;
; Evidence: 381 862 entries over all recordings, one a frame (`c1g` 4473 in
; 4808 frames: the load's frames before the entry have none; `rzx-004833` 7019
; in 7019 frames); 3377 T an entry on average in `c1g` (WALKTHROUGH 1).
;
; Witness: L1 466704 (c1, c1g, cheat, controls, ending, energy, energy-out,
; gameover, hof, kempston, menu, mine, overload, L x20, rzx x60).
InterruptHandler:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD A,(MenuScroller)     ; MenuScroller set: the menu's line instead, no ticks
  AND A
  JP NZ,MenuScrollerTick
  LD A,(EnergyTick)       ; EnergyTick + 1 ($A338 INC A: the POKE 41784,0 makes
                          ; it NOP)
  INC A
  LD (EnergyTick),A
  LD A,(FrameCounter)     ; FrameCounter + 1
  INC A
  LD (FrameCounter),A
  LD A,(MessageText+$0001) ; a new message (MessageText's high byte not 0)?
  AND A
  JR Z,ScrollMessageTick
  LD A,(MessageState)     ; yes: in a static message's blank phase ($E6-$EF)?
                          ; then draw it now, take the new one next frame
  CP $E6
  JR C,ScrollerTakeMessage
  CP $F0
  JR NC,ScrollerTakeMessage
  LD A,$F0
  LD (MessageState),A
  JR ShowStaticMessage
ScrollerTakeMessage:
  LD HL,(MessageText)     ; MessagePointer = MessageText, the high byte cleared
                          ; (taken)
  LD (MessagePointer),HL
  XOR A
  LD (MessageText+$0001),A
  LD A,(HL)               ; static ($FE first)? MessageState = $FE
  CP $FE
  JP NZ,ScrollNextChar
  LD (MessageState),A
StaticMessageTick:
  LD A,(MessageState)     ; MessageState + 1: $F0 draw, below $FF wait, $FF
                          ; clear and restart at $E6
  INC A
  LD (MessageState),A
  CP $F0
  JR Z,ShowStaticMessage
  CP $FF
  JP C,InterruptExit
  LD A,$E6                ; $FF: the blank phase again from $E6, the line
                          ; cleared
  LD (MessageState),A
  LD HL,Screen+4320             ; $50E0: 5 pixel rows of $80 (the panel's edge) and
                          ; 15 zeros
  XOR A
  LD C,$05
ClearLineRowLoop:
  LD (HL),$80
  LD B,$0F
ClearLineByteLoop:
  INC L
  LD (HL),A
  DJNZ ClearLineByteLoop
  LD L,$E0
  INC H
  DEC C
  JR NZ,ClearLineRowLoop
  JP InterruptExit
ShowStaticMessage:
  LD B,$0E                ; the 14 characters after the $FE at $50E1, font rows
                          ; 2-6 ($D202 + 8 x (c - 32))
  LD HL,(MessagePointer)
  INC HL
  LD DE,Screen+4321
StaticCharLoop:
  LD A,(HL)               ; a space draws nothing (the line was cleared)
  SUB $20
  JR Z,StaticNextChar
  PUSH BC
  PUSH HL
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$D202
  ADD HL,BC
  LD B,$05
StaticGlyphRowLoop:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ StaticGlyphRowLoop
  LD D,$50
  POP HL
  POP BC
StaticNextChar:
  INC E
  INC HL
  DJNZ StaticCharLoop
  JP InterruptExit
ScrollMessageTick:
  LD A,(MessageState)     ; no new message: static (state $E6 or more) or the
                          ; next pixel
  CP $E6
  JP NC,StaticMessageTick
  INC A
  LD (MessageState),A
  CP $08
  JR NZ,ScrollLinePixel
ScrollNextChar:
  XOR A                   ; every 8th pixel: the next character's glyph into
                          ; MessageGlyph
  LD (MessageState),A
  LD HL,(MessagePointer)
  LD A,(HL)
  CP $FF
  JR NZ,ScrollLoadGlyph
  INC HL                  ; $FF: the text goes on at the next word;
                          ; BlankMessage there ends the message (MessageNumber
                          ; 0)
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,BlankMessage
  AND A
  SBC HL,DE
  JR NZ,ScrollJumped
  XOR A
  LD (MessageNumber),A
ScrollJumped:
  EX DE,HL
  LD A,(HL)
ScrollLoadGlyph:
  INC HL                  ; MessagePointer to the next character, its 8 font
                          ; bytes to MessageGlyph
  LD (MessagePointer),HL
  SUB $20
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Font
  ADD HL,BC
  LD DE,MessageGlyph
  LD BC,$0008
  LDIR
ScrollLinePixel:
  LD HL,Screen+4335             ; 5 rows: shift $50EF down to $50E0 a pixel left, the
                          ; glyph's next bit in at the right
  LD DE,MessageGlyph+$0002
  LD B,$05
ScrollRowLoop:
  LD A,(DE)               ; 16 RL (HL) unrolled, from the right
  RLA
  LD (DE),A
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  LD A,(HL)               ; $50E0's bit 7 stays set (the panel's edge)
  RLA
  SET 7,A
  LD (HL),A
  LD L,$EF
  INC H
  INC DE
  DJNZ ScrollRowLoop

; The common end of the handler: the beeper effect of SoundFlags, the registers
; back, EI, RET
;
; Reached by the fall from the line's scroll and by the jumps of every other
; path. PlaySoundFlags `$A8A7` runs with the interrupt still off, so a long
; effect delays the main code (it never spans a frame: the longest flag effect,
; `$81D4`, takes 0.49 frame).
;
; Witness: L1 466704 (c1, c1g, cheat, controls, ending, energy, energy-out,
; gameover, hof, kempston, menu, mine, overload, L x20, rzx x60).
InterruptExit:
  CALL PlaySoundFlags
  POP AF
  POP BC
  POP DE
  POP HL
  EI
  RET

; The menu's line: row 21, columns 5-25 scrolled a pixel a frame; bytes $82-$FE
; in the text are pauses
;
; From InterruptHandler when MenuScroller `$A103` is set. A new message is
; taken (MessagePointer = MessageText, the high byte cleared) and the line
; `$51A5` (5 pixel rows of 21 bytes, scan lines 1-5) cleared. Then each frame:
; if the next text byte is `$81` or more it is a pause (MenuPause), else the 21
; bytes `$51A5-$51B9` of the 5 rows are shifted a pixel left with
; MessageGlyph's next column coming in (MenuScrollPixel), and every 8 pixels
; the next character is loaded (`$FF`: go on at the next word).
;
; A pause byte counts down in the text itself, a frame a step: `$FE` to `$E6`
; (24 frames) the line stands; `$E5` to `$82` (100 frames) its attributes
; (`$5AA5`, 21 bytes) flash, bit 4 of the count choosing `$3F` (white on white,
; hidden) or `$38` (black on white), 16 frames each; at `$81` the byte is set
; back to `$FE` and the text goes on. The callers write `$FE` again before they
; set the text (`$A769`, `$9CAE`), since an interrupted count stays in the
; text.
;
; No tick is counted on this path (EnergyTick, FrameCounter).
;
; Evidence: 2490 entries (`c1g`, `controls`, `energy`, `kempston`, `menu`,
; `rzx-344752`); the pause (`$A4AA`) only in `controls`: 126 frames, the flash
; 101, the end of the pause once.
;
; Witness: L1 3082 (c1, c1g, controls, energy, energy-out, hof, kempston, menu,
; rzx344752).
MenuScrollerTick:
  LD A,(MessageText+$0001)
  AND A
  JR Z,MenuScrollTick
  LD HL,(MessageText)     ; a new message: take it, clear the line
  LD (MessagePointer),HL
  XOR A
  LD (MessageText+$0001),A
  LD HL,Screen+4517             ; $51A5: 5 pixel rows of 21 bytes
  XOR A
  LD C,$05
MenuClearRowLoop:
  LD B,$15
MenuClearByteLoop:
  LD (HL),A
  INC L
  DJNZ MenuClearByteLoop
  LD L,$A5
  INC H
  DEC C
  JR NZ,MenuClearRowLoop
  JR MenuNextChar
MenuScrollTick:
  LD HL,(MessagePointer)  ; the next text byte: a pause ($81 or more, not $FF)?
  LD A,(HL)
  CP $FF
  JR Z,MenuScrollCount
  CP $81
  JR NC,MenuPause
MenuScrollCount:
  LD A,(MessageState)     ; MessageState + 1; the next character at 8
  INC A
  LD (MessageState),A
  CP $08
  JR NZ,MenuScrollPixel
MenuNextChar:
  XOR A
  LD (MessageState),A
  LD HL,(MessagePointer)
  LD A,(HL)
  CP $FF
  JR NZ,MenuCheckPause
  INC HL                  ; $FF: go on at the next word
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,(HL)
MenuCheckPause:
  CP $81
  JR C,MenuLoadGlyph
MenuPause:
  JR NZ,MenuPauseCount    ; a pause byte: $81 ends it
  LD (HL),$FE             ; $81: put $FE back for the next time round, go on
                          ; after it
  INC HL
  LD (MessagePointer),HL
  JP InterruptExit
MenuPauseCount:
  DEC A                   ; count down in the text; $E6 or more: the line just
                          ; stands
  LD (HL),A
  CP $E6
  JP NC,InterruptExit
  BIT 4,A                 ; below $E6: flash the line's attributes, 16 frames
                          ; white on white, 16 black on white
  JR Z,MenuPauseInk
  LD A,$3F
  JR MenuPausePaint
MenuPauseInk:
  LD A,$38
MenuPausePaint:
  LD HL,Attributes+677
  LD B,$15
MenuPausePaintLoop:
  LD (HL),A
  INC L
  DJNZ MenuPausePaintLoop
  JP InterruptExit
MenuLoadGlyph:
  INC HL                  ; MessagePointer to the next byte, the character's
                          ; font bytes to MessageGlyph
  LD (MessagePointer),HL
  SUB $20
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Font
  ADD HL,BC
  LD DE,MessageGlyph
  LD BC,$0008
  LDIR
MenuScrollPixel:
  LD HL,Screen+4537             ; 5 rows: shift $51B9 down to $51A5 a pixel left, the
                          ; glyph's next bit in at the right
  LD DE,MessageGlyph+$0002
  LD C,$05
MenuScrollRowLoop:
  LD A,(DE)
  RLA
  LD (DE),A
  LD B,$15
MenuScrollByteLoop:
  RL (HL)
  DEC L
  DJNZ MenuScrollByteLoop
  LD L,$B9
  INC H
  INC DE
  DEC C
  JR NZ,MenuScrollRowLoop
  JP InterruptExit
