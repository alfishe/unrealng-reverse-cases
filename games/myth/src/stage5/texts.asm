; --------------------------------------------------------------------------------------------------------------------
; texts.asm: The intro and ending texts: their font, the drawing into buffers and the copy to the screen
;
; Stage 5 shows two texts of seven lines each, the intro ("HURTLING ACROSS THE VOID OF SPACE. PRAPARE TO CONFRONT THE
; EVIL ANGEL OF TIME.DAMERON.") before the duel and the ending ("WELL DONE. YOUR TASK IS COMPLETE. HISTORY IS RESTORED
; AND DAMERON IS BANISHED.") after it. Both are drawn once at the start (DrawIntroText, DrawEndingText) in a
; proportional font (TextFont) into seven 256-byte pages of the play buffer each ($5B00-$61FF and $6200-$68FF), a page
; holding one line of 12 bytes x 8 pixel lines; ShowTexts copies one set to screen rows 8-20, columns 16-27, while the
; duel timer DuelTimer $FE45 runs.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8C87

; Copy the intro or the ending text to the screen, or clear it, by the duel's
; phase and timer
;
; Jumped to from $87EB and $87F3 (the main loop's timer step) after the duel
; timer DuelTimer $FE45 was counted down by 2. HL = the timer, A = the phase
; DuelPhase $FE43.
;
; Phase 4 (Dameron beaten): ShowEnding. Otherwise by the timer's high byte: 2,
; or 1 with a low byte other than 0, shows the intro (TextShowing TextShown
; $FE47 = 1, the seven intro pages $5B00-$61FF copied by CopyTextLine to the
; screen at $4800, $4840, $4880, $48C0, $5000, $5040, $5080: character rows 8,
; 10, ... 20, columns 16-27), then waits 1300 loops of DEC HL (about 31 000
; T-states, under half a frame); exactly $0100 clears the text (ClearTextArea:
; TextShowing = 0, BlankTextLine copied to the same seven places); any other
; value returns at once.
;
; In s5-right the timer starts at $044C (set at $7826) and goes down by 2 a
; pass: the intro is copied on the 255 passes from $02FE to $0102, cleared once
; at $0100, and the duel starts at $00A0 ($87F6: phase 0, timer $FFC3).
;
; Output: none. Side effects: TextShowing TextShown $FE47, the screen's pixels
; in rows 8-20, columns 16-27.
;
; Witness: L1 5535 (ending, rzx-r5, s5-right).
ShowTexts:
  LD HL,(DuelTimer)
  LD A,(DuelPhase)
  CP $04
  JP Z,ShowEnding
  LD A,H
  CP $02
  JP Z,ShowIntro
  CP $01
  RET NZ
  LD A,L
  CP $00
  JP Z,ClearTextArea
ShowIntro:
  LD A,$01                ; the intro's seven pages to the screen
  LD (TextShown),A
  LD HL,PlayBuffer
  LD DE,Screen+2048
  CALL CopyTextLine
  LD HL,PlayBuffer+256
  LD DE,Screen+2112
  CALL CopyTextLine
  LD HL,PlayBuffer+512
  LD DE,Screen+2176
  CALL CopyTextLine
  LD HL,PlayBuffer+768
  LD DE,Screen+2240
  CALL CopyTextLine
  LD HL,PlayBuffer+1024
  LD DE,Screen+4096
  CALL CopyTextLine
  LD HL,PlayBuffer+1280
  LD DE,Screen+4160
  CALL CopyTextLine
  LD HL,PlayBuffer+1536
  LD DE,Screen+4224
  CALL CopyTextLine
  LD HL,$0514
ShowIntroDelay:
  DEC HL                  ; 1300 x (DEC HL until 0)
  LD A,L
  OR H
  JP NZ,ShowIntroDelay
  RET
ShowEnding:
  LD A,H                  ; phase 4: the timer's high byte $FF or $FE returns;
                          ; else the ending's pages $6200-$68FF, then the delay
  CP $FF
  RET Z
  CP $FE
  RET Z
  LD A,$01
  LD (TextShown),A
  LD HL,PlayBuffer+1792
  LD DE,Screen+2048
  CALL CopyTextLine
  LD HL,PlayBuffer+2048
  LD DE,Screen+2112
  CALL CopyTextLine
  LD HL,PlayBuffer+2304
  LD DE,Screen+2176
  CALL CopyTextLine
  LD HL,PlayBuffer+2560
  LD DE,Screen+2240
  CALL CopyTextLine
  LD HL,PlayBuffer+2816
  LD DE,Screen+4096
  CALL CopyTextLine
  LD HL,PlayBuffer+3072
  LD DE,Screen+4160
  CALL CopyTextLine
  LD HL,PlayBuffer+3328
  LD DE,Screen+4224
  CALL CopyTextLine
  LD HL,$0514
ShowEndingDelay:
  DEC HL
  LD A,L
  OR H
  JP NZ,ShowEndingDelay
  RET

; ClearTextArea
;
; Used by the routine at ShowTexts.
ClearTextArea:
  LD A,$00                ; timer $0100: TextShowing = 0 and BlankTextLine over
                          ; the seven text lines
  LD (TextShown),A
  LD HL,BlankTextLine
  LD DE,Screen+2048
  CALL CopyTextLine
  LD HL,BlankTextLine
  LD DE,Screen+2112
  CALL CopyTextLine
  LD HL,BlankTextLine
  LD DE,Screen+2176
  CALL CopyTextLine
  LD HL,BlankTextLine
  LD DE,Screen+2240
  CALL CopyTextLine
  LD HL,BlankTextLine
  LD DE,Screen+4096
  CALL CopyTextLine
  LD HL,BlankTextLine
  LD DE,Screen+4160
  CALL CopyTextLine
  LD HL,BlankTextLine
  LD DE,Screen+4224
  CALL CopyTextLine
  RET

; Copy one text page (8 lines of 12 bytes) from HL to the screen at DE + 16
;
; Input: HL = the page (12 bytes a pixel line, packed), DE = the screen address
; of the character row's first line. E + 16 (column 16); 8 lines, each 12 LDIs,
; then INC D (the next pixel line of the character row). Output: HL past the 96
; bytes. Corrupts A, BC, DE.
;
; Called 7 times from each of ShowIntro, ShowEnding and ClearTextArea.
;
; Witness: L1 31101 (ending, rzx-r5, s5-right).
CopyTextLine:
  LD A,E
  ADD A,$10
  LD E,A
  LD B,$08
CopyTextLineRow:
  PUSH BC
  LD A,E
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD E,A
  INC D
  POP BC
  DJNZ CopyTextLineRow
  RET

; Draw the intro's seven lines into the pages $5B00-$61FF
;
; IY = IntroText; DrawTextLine for each page PlayBuffer $5B00, $5C00, ... $6100
; (IY runs on from line to line). Called once at the stage start ($7831).
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
DrawIntroText:
  LD HL,PlayBuffer
  LD IY,IntroText
  CALL DrawTextLine
  LD HL,PlayBuffer+256
  CALL DrawTextLine
  LD HL,PlayBuffer+512
  CALL DrawTextLine
  LD HL,PlayBuffer+768
  CALL DrawTextLine
  LD HL,PlayBuffer+1024
  CALL DrawTextLine
  LD HL,PlayBuffer+1280
  CALL DrawTextLine
  LD HL,PlayBuffer+1536
  CALL DrawTextLine
  RET

; Draw the ending's seven lines into the pages $6200-$68FF
;
; IY = EndingText; DrawTextLine for each page $6200 ... $6800. Called once at
; the stage start ($7834), right after DrawIntroText: the ending waits in the
; play buffer's pages for the whole duel.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
DrawEndingText:
  LD HL,PlayBuffer+1792
  LD IY,EndingText
  CALL DrawTextLine
  LD HL,PlayBuffer+2048
  CALL DrawTextLine
  LD HL,PlayBuffer+2304
  CALL DrawTextLine
  LD HL,PlayBuffer+2560
  CALL DrawTextLine
  LD HL,PlayBuffer+2816
  CALL DrawTextLine
  LD HL,PlayBuffer+3072
  CALL DrawTextLine
  LD HL,PlayBuffer+3328
  CALL DrawTextLine
  RET

; The intro's seven lines: each 3 header bytes, the characters, 0
;
; Format of a line (DrawTextLine): byte 0 the start column in bytes (0-11)
; within the 12-byte line, byte 1 the start pixel offset (0-7), byte 2 a byte
; stored in TextScratch $FE4B and never used for the text, then ASCII
; characters (A-Z, space, `\` drawn as a full stop; digits would index past
; TextFont), then 0. All headers here are 0, 0, 0: every line starts at the
; left edge.
;
; The text, as printed (sic): HURTLING / ACROSS THE / VOID OF SPACE. / PRAPARE
; TO / CONFRONT THE / EVIL ANGEL OF / TIME.DAMERON. Read once by DrawIntroText
; through IY (DrawTextLine).
IntroText:
  INCBIN "res/stage5/textlines-intro.bin",$0000,12
IntroLine2:
  INCBIN "res/stage5/textlines-intro.bin",$000C,14
IntroLine3:
  INCBIN "res/stage5/textlines-intro.bin",$001A,18
IntroLine4:
  INCBIN "res/stage5/textlines-intro.bin",$002C,14
IntroLine5:
  INCBIN "res/stage5/textlines-intro.bin",$003A,16
IntroLine6:
  INCBIN "res/stage5/textlines-intro.bin",$004A,17
IntroLine7:
  INCBIN "res/stage5/textlines-intro.bin",$005B,17

; The ending's seven lines, in IntroText's format
;
; WELL DONE. / YOUR TASK / IS COMPLETE. / HISTORY IS / RESTORED AND / DAMERON
; IS / BANISHED. Read once by DrawEndingText (DrawTextLine); shown by
; ShowEnding once Dameron is beaten (phase 4). The text is drawn into the
; second page at the stage start (read once in every recording); rzx-r5 and
; ending reached the ending page (ShowEnding $8CEF 841 and 3284 passes).
EndingText:
  INCBIN "res/stage5/textlines-ending.bin",$0000,14
EndingLine2:
  INCBIN "res/stage5/textlines-ending.bin",$000E,13
EndingLine3:
  INCBIN "res/stage5/textlines-ending.bin",$001B,16
EndingLine4:
  INCBIN "res/stage5/textlines-ending.bin",$002B,14
EndingLine5:
  INCBIN "res/stage5/textlines-ending.bin",$0039,16
EndingLine6:
  INCBIN "res/stage5/textlines-ending.bin",$0049,14
EndingLine7:
  INCBIN "res/stage5/textlines-ending.bin",$0057,13

; Draw one text line into a 96-byte page with the proportional TextFont
;
; Input: HL = the page (its low byte 0), IY = the line (header, characters, 0).
; Clears the 96 bytes from HL (12 bytes x 8 lines). The pen: DE = H, header
; byte 0; the pixel offset TextPenShift $FE4A = header byte 1; header byte 2
; goes to TextScratch $FE4B (not read by the text code).
;
; Each character: '0'-'9' + $2C, space becomes $5B, then - 'A': A-Z are glyphs
; 0-25, space 26, `\` 27 (a full stop). The glyph is 8 bytes at TextFont + 8 x
; the index: byte 0 the width mask (kept in GlyphWidthMask $FE4C), 7 pixel
; rows. The rows go as pairs (row, 0) into the scratch $6A00-$6A0D (inside the
; play buffer), are shifted right by the pixel offset (TextPenShift $FE4A times
; SRL / RR over each pair), and ORed into the page at DE, DE + 1 (rows 12 bytes
; apart: pixel lines 0-6 of the line, line 7 stays blank). AdvanceTextPen moves
; the pen. A 0 ends the line (DrawTextLineDone) with IY past it, ready for the
; next line.
;
; Output: IY past the line's 0. Corrupts A, BC, DE, HL; TextPenShift $FE4A,
; TextScratch $FE4B, GlyphWidthMask $FE4C, $6A00-$6A0D.
;
; Witness: L1 42 (ending, rzx-r5, s5-right).
DrawTextLine:
  PUSH HL
  PUSH HL
  POP DE
  INC DE
  LD BC,$005F
  LD (HL),$00
  LDIR
  POP HL
  LD A,$00
  LD (TextPenShift),A
  LD D,H
  LD E,(IY+$00)
  LD A,(IY+$01)
  LD (TextPenShift),A
  LD A,(IY+$02)
  LD (TextScratch),A
  INC IY
  INC IY
  INC IY
DrawTextChar:
  LD A,(IY+$00)           ; the next character; 0 ends the line
  INC IY
  CP $00
  JP Z,DrawTextLineDone
  CP $3A
  JR NC,DrawTextGlyph
  CP $30
  JR C,DrawTextNotDigit
DrawTextDigit:
  ADD A,$2C               ; '0'-'9' + $2C (no text uses a digit)
  JR DrawTextGlyph
DrawTextNotDigit:
  CP $20                  ; space becomes $5B, glyph 26
  JR NZ,DrawTextGlyph
  LD A,$5B
DrawTextGlyph:
  SUB $41                 ; index = A - 'A'; the glyph's width mask to $FE4C
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,TextFont
  ADD HL,BC
  LD A,(HL)
  LD (GlyphWidthMask),A
  INC HL
  PUSH DE
  LD DE,TextGlyphRows
  LD B,$07
DrawTextCopyRow:
  LD A,(HL)               ; 7 rows into $6A00 as (row, 0) pairs
  LD (DE),A
  INC HL
  INC E
  LD A,$00
  LD (DE),A
  INC E
  DJNZ DrawTextCopyRow
  POP DE
  PUSH DE
  LD A,(TextPenShift)
  CP $00
  JR Z,DrawTextMerge
  LD C,A
DrawTextShift:
  LD HL,TextGlyphRows             ; shift the 7 pairs right by the pixel offset (C
                          ; times)
  LD B,$07
DrawTextShiftRow:
  SRL (HL)
  INC L
  RR (HL)
  INC L
  DJNZ DrawTextShiftRow
  DEC C
  JR NZ,DrawTextShift
DrawTextMerge:
  LD HL,TextGlyphRows             ; OR the 7 pairs into the page, 12 bytes a row
  LD B,$07
DrawTextMergeRow:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC L
  LD A,E
  ADD A,$0B
  LD E,A
  DJNZ DrawTextMergeRow
  POP DE
  CALL AdvanceTextPen
  JR DrawTextChar

; Move the pen past the glyph just drawn: its width + 1 pixel
;
; The width mask GlyphWidthMask $FE4C has the glyph's columns set from bit 7
; down: C = 9 - its trailing zero bits (8 for most letters, 7 for C, E, F ...,
; 9 for M and W, 6 for space, 5 for I and the full stop). The pixel offset
; TextPenShift $FE4A + C; at 8 or more, DE + 1 and the offset - 8 (once: after
; a 9-wide glyph from offset 7 the offset stays 8, which the shift loop
; handles). Called after each glyph by DrawTextLine ($8F73).
;
; Witness: L1 456 (ending, rzx-r5, s5-right).
AdvanceTextPen:
  LD A,(GlyphWidthMask)
  LD C,$09
AdvanceTextPenWidth:
  BIT 0,A                 ; count the mask's trailing zeros
  JR NZ,AdvanceTextPenAdd
  SRL A
  DEC C
  JR AdvanceTextPenWidth
AdvanceTextPenAdd:
  LD A,(TextPenShift)
  ADD A,C
  CP $08
  JR C,AdvanceTextPenStore
  INC DE
  SUB $08
AdvanceTextPenStore:
  LD (TextPenShift),A
  RET

; The RET DrawTextLine jumps to at a line's 0
;
; Reached by JP Z from $8F0B.
;
; Witness: L1 42 (ending, rzx-r5, s5-right).
DrawTextLineDone:
  RET

; The texts' proportional font: 28 glyphs of 8 bytes, A-Z, space, full stop
;
; Each glyph: byte 0 the width mask (bits set from bit 7 for the glyph's pixel
; columns; the advance, 9 less the trailing zeros, adds the gap: $FE for A, B,
; D, N, O, Q, R, Y, Z; $FC for C, E, F, G, H, J, K, P, S, T, U, V, X; $F8 for L
; and space; $F0 for I and the full stop; $FF for M and W), then 7 rows of
; pixels (bit 7 the left). Read by DrawTextGlyph $8F20 (TextFont + 8 x the
; index). Indexes 28-36 (the digits) would read past it into UpdateBurst's
; code; no text has a digit.
TextFont:
  INCBIN "res/stage5/bitmaps-text-font-1x8.bin",$0000,208
TextFontSpace:
  INCBIN "res/stage5/bitmaps-text-font-1x8.bin",$00D0,8
TextFontStop:
  INCBIN "res/stage5/bitmaps-text-font-1x8.bin",$00D8,8
