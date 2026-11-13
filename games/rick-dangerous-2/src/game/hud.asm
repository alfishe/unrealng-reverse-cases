; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The HUD and the glyphs: score, detonators, ammunition, lives
;
; The top character row of the screen is the HUD: the score's six digits at columns 1-6 (white), up to six detonators
; at columns 9-14 (red), up to six ray-gun bolts at columns 17-22 (magenta) and up to six lives (Rick's head) at
; columns 25-30 (green). DrawHud $796F clears and colours the row and draws all four; the game calls DrawLives,
; DrawAmmo, DrawDetonators and DrawScore alone when one value changes. Glyphs are 8 x 8, drawn straight into the
; screen by DrawGlyph $7A2C.
;
; The same 40 glyphs $7080 are the game's text font: the text printer $88B1 points the cell drawers' graphics base at
; $7080 instead of CellGraphics, so a text is a buffer of glyph numbers (ASCII - $34: "A" = 13, "0" = -4, which is why
; the menus store a digit 4 higher, "5" for 1).
;
; PrintText draws a text straight on the screen with the font at $7080 ($7A2C a glyph): the tape messages and GAME
; OVER's second form.
; --------------------------------------------------------------------------------------------------------------------

; The 40 glyphs of the HUD and the texts, 8 bytes each: 0-9, bolt, detonator,
; life, A-Z, blank
;
; Glyph n at $7080 + 8n: 0-9 the digits ($7080-$70CF), 10 the ray gun's bolt
; ($70D0, DrawAmmo $79D1), 11 a detonator ($70D8, DrawDetonators $79DF), 12
; Rick's head ($70E0, DrawLives $79C3), 13-38 the letters A-Z ($70E8-$71B7), 39
; a blank ($71B8). Read by DrawGlyph $7A2C (the HUD and the texts: $7080-$70EF,
; $7100-$719F in the recordings) and, as cell graphics, by DrawChangedCells
; $76D4 and ComposeCell $7755 when the text printer $88B1 has switched them to
; the font ($7080-$71BF read by both).
Glyphs:
  INCBIN "res/graphics/glyphs.bin",$0000,80
GlyphBolt:
  INCBIN "res/graphics/glyphs.bin",$0050,8
GlyphDetonator:
  INCBIN "res/graphics/glyphs.bin",$0058,8
GlyphLife:
  INCBIN "res/graphics/glyphs.bin",$0060,8
GlyphLetters:
  INCBIN "res/graphics/glyphs.bin",$0068,208
GlyphBlank:
  INCBIN "res/graphics/glyphs.bin",$0138,8

  ORG $796F

; Clear the HUD row, colour it and draw the detonators, ammunition, lives and
; score
;
; Clears the 8 lines of screen row 0 with PUSH (interrupts off, SP saved at
; $7991), colours it (columns 0-6 $47 white, 7-14 $42 red, 15-22 $43 magenta,
; 23-31 $44 green, bright), then DrawDetonators, DrawAmmo, DrawLives,
; DrawScore. Called by the section start $8B16 (97) and $8767 (once): 98 runs
; in 44 builds.
;
; Witness: L1 275 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke,
; rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke,
; rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DrawHud:
  DI
  LD (ClearHudEnd+$0001),SP
  LD HL,Screen+32
  LD B,$08
  LD DE,$0000
ClearHudLoop:
  LD SP,HL
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  INC H
  DJNZ ClearHudLoop
ClearHudEnd:
  LD SP,$0000             ; LD SP,nn: nn = the caller's SP
  EI
  LD HL,ScreenAttrs
  LD DE,ScreenAttrs+1
  LD (HL),$47
  LD BC,$0007
  LDIR
  LD (HL),$42
  LD BC,$0008
  LDIR
  LD (HL),$43
  LD BC,$0008
  LDIR
  LD (HL),$44
  LD BC,$0008
  LDIR
  CALL DrawDetonators
  CALL DrawAmmo
  CALL DrawLives
  CALL DrawScore
  RET

; Draw the lives $8B3B as Rick's heads at columns 25-30
;
; Up to six GlyphLife, the rest blank (DrawIconRow). Callers: DrawHud $79BC,
; the life loss $8A34, the ending's tally $8739.
;
; Witness: L1 339 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke,
; rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke,
; rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DrawLives:
  LD DE,Screen+25
  LD A,(Lives)
  LD B,A
  LD HL,GlyphLife
  CALL DrawIconRow
  RET

; Draw the ammunition $8B3C as bolts at columns 17-22
;
; Callers: DrawHud $79B9, $95A3, $A5AA.
;
; Witness: L1 476 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DrawAmmo:
  LD DE,Screen+17
  LD A,(Ammunition)
  LD B,A
  LD HL,GlyphBolt
  CALL DrawIconRow
  RET

; Draw the detonators $8B3D at columns 9-14
;
; Callers: DrawHud $79B6, $9B45, $A5BA.
;
; Witness: L1 408 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DrawDetonators:
  LD DE,Screen+9
  LD A,(Detonators)
  LD B,A
  LD HL,GlyphDetonator
  CALL DrawIconRow
  RET

; Draw B copies of the glyph at HL from DE, then 6 - B blanks
;
; B = the count (0-6: more would draw 256 - (B - 6) blanks), HL = the glyph, DE
; = the screen address in row 0.
;
; Witness: L1 1223 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DrawIconRow:
  LD A,B
  AND A
  JP Z,DrawIconBlanks
  PUSH BC
  CALL DrawGlyphs
  POP BC
DrawIconBlanks:
  LD A,$06                ; the rest of the six: BlankGlyph
  SUB B
  RET Z
  LD B,A
  LD HL,BlankGlyph

; Draw the glyph at HL B times from DE rightwards
;
; Witness: L1 7338 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DrawGlyphs:
  PUSH BC
  PUSH HL
  PUSH DE
  CALL DrawGlyph
  POP DE
  INC DE
  POP HL
  POP BC
  DJNZ DrawGlyphs
  RET

; Draw the six score digits $7F1D-$7F22 at columns 1-6
;
; Each digit 0-9 is a glyph number. Callers: DrawHud $79BF, the score adder
; $7EED (149).
;
; Witness: L1 585 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DrawScore:
  LD DE,Screen+1
  LD HL,Score
  LD B,$06
DrawScoreLoop:
  PUSH DE
  PUSH HL
  PUSH BC
  LD L,(HL)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Glyphs
  ADD HL,BC
  CALL DrawGlyph
  POP BC
  POP HL
  POP DE
  INC DE
  INC HL
  DJNZ DrawScoreLoop
  RET

; Copy the 8 bytes at HL to the screen cell at DE
;
; DE = the cell's top line; DE ends on its last line (D + 7). Callers:
; DrawGlyphs $7A02, DrawScore $7A21 and the text printer $7F3B (the texts at
; rows 9-10). 4852 runs in 65 builds.
;
; Witness: L1 11588 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8,
; c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
DrawGlyph:
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  RET

; An empty glyph: the HUD's unused icon places
BlankGlyph:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

  ORG $7F23

; Print a text on the screen: HL the text ($FF the end), DE the screen address
;
; Each character: $FF ends, a space moves on a column, else the glyph $7080 + 8
; x (code - $34) is drawn at DE by $7A2C; DE + 1. So the digits are stored 4
; higher ("4" is the glyph 0). Out: HL on the $FF.
;
; Evidence: 512 runs in 9 builds (callers $7E94 x4 GAME OVER, $8415 x20 and
; $8430 x18 the tape messages, a run a character).
;
; Witness: L1 976 (controls-keyboard, rzx-l3-10000-poke, rzx-l4-20000-poke,
; rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
PrintText:
  LD A,(HL)
  CP $FF
  RET Z
  INC HL
  CP $20
  JP Z,PrintTextNext
  PUSH HL
  SUB $34
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Glyphs
  ADD HL,BC
  PUSH DE
  CALL DrawGlyph
  POP DE
  POP HL
PrintTextNext:
  INC DE                  ; the next column
  JP PrintText
