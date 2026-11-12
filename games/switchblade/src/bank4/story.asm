; --------------------------------------------------------------------------------------------------------------------
; story.asm: The 128K's intro story pages
;
; On a 48K the intro (Hiro's awakening, the Fireblade's fall, Havok) is shown once at the boot ($5CFD CALL $5D4F) from
; texts in the actor pages, which the play then overwrites. On a 128K the bootstrap puts NOPs at $5CFD and a CALL
; $85C5 at $5C9A (after the key choice, before every new game); $85C5 pages bank 4 in and calls StoryPages $D3D0, so
; the intro is shown before each game, from these bytes. The code is the 48K's $5D4F-$5E4C with its own copies of the
; helpers and of the texts.
;
; The text stream StoryEyesClosed $D4CB-$D862 is read in order through IY: picture strings in the story font StoryFont
; (two header bytes: Y, X; codes 1-$ED are glyphs code - 1; $FF the next line) and text strings in the game font
; (PrintString: Y, X, two style bytes, ASCII, $FF the next line), each ended by 0.
; --------------------------------------------------------------------------------------------------------------------

; Show the intro story: boxed pages of pictures and text, each waiting for key
; 0 or a time
;
; Page 1: the screen cleared to attribute 7, a box at Y $90 X $30 (8 x 5
; characters), Hiro's closed eyes and "FOR 10000 YEARS HE SLEPT..."; after the
; wait "NOW HE HAS AWAKENED" over it, the eyes open in three frames five frames
; apart (attribute $42 at $5A9C before the last), the wait. Page 2: StoryAttrs1
; at $5882, a box at Y 8 X 0 (7 x 19), the whole Fireblade and "AS THE NIGHT
; BLED CRIMSON...", the wait; a flash (border 7, StoryAttrs2, a delay of $2000
; passes, border 0), the shattered blade and "THEN THE SLAUGHTER BEGAN.", the
; wait. Page 3: PortraitAttrs at $5828, a box at Y 0 X $0F (18 x 15), Havok's
; portrait and "THEY NEVER THOUGHT HE WOULD RETURN. NOW HAVOK REIGNS THE
; UNDERCITY.", the wait; "I AM HIRO, ... AND BRING THE DAWN...", the wait, and
; 300 frames more (WaitFire, H = $3C). A wait is WaitFireLong: 200 frames or
; key 0.
;
; Called by the hook $85C5 (main memory) at $85D1: c1 once, menu and gameover
; twice (two games).
;
; Witness: L1 9 (c1, deaths, gameover, menu, opt x3).
StoryPages:
  LD A,$07
  CALL ClearScreen
  LD IY,StoryEyesClosed   ; IY = the first string
  LD DE,$3090
  LD BC,$0805
  CALL StoryBoxPage
  CALL PrintStoryText     ; "NOW HE HAS AWAKENED" over the first text
  CALL StoryFrame         ; the eyes open: three pictures
  CALL StoryFrame
  LD A,$42
  LD (Attributes+668),A
  CALL StoryFrame
  CALL WaitFireLong
  LD A,$07                ; page 2
  CALL ClearScreen
  LD HL,StoryAttrs1
  LD DE,Attributes+130
  LD BC,$0503
  CALL CopyAttrBlock
  LD DE,$0008
  LD BC,$0713
  CALL StoryBoxPage
  LD A,$07                ; the flash: border white, the bright attributes, a
                          ; delay
  OUT ($FE),A
  LD HL,StoryAttrs2
  LD DE,Attributes+130
  LD BC,$0503
  CALL CopyAttrBlock
  LD BC,$2000
  CALL DelayBC
  LD A,$00
  OUT ($FE),A
  CALL StoryPicturePage
  LD A,$07                ; page 3: Havok
  CALL ClearScreen
  LD HL,PortraitAttrs
  LD DE,Attributes+40
  LD BC,$0D10
  CALL CopyAttrBlock
  LD DE,$0F00
  LD BC,$120F
  CALL StoryBoxPage
  CALL StoryTextPage      ; Hiro's vow, the wait, then 300 frames more
  LD H,$3C
  CALL WaitFire
  RET

; Draw a box, then a picture, a text and wait
;
; DE = the box's position (E = Y in pixels, D = X in half columns), B = its
; width, C = its height in characters. DrawStoryBox $D479, then falls into
; StoryPicturePage.
;
; Witness: L1 27 (c1, deaths, gameover, menu, opt x3).
StoryBoxPage:
  CALL DrawStoryBox

; Print the next picture string, then the next text and wait
;
; Witness: L1 36 (c1, deaths, gameover, menu, opt x3).
StoryPicturePage:
  CALL PrintStoryPicture

; Print the next text string and wait for key 0 or 200 frames
;
; Witness: L1 45 (c1, deaths, gameover, menu, opt x3).
StoryTextPage:
  CALL PrintStoryText
  JP WaitFireLong

; Print the next picture string and wait 5 frames (one frame of the eyes'
; opening)
;
; Witness: L1 27 (c1, deaths, gameover, menu, opt x3).
StoryFrame:
  CALL PrintStoryPicture
  LD H,$01
  JP WaitFire

; Print the picture string at IY in the story font; IY = the next string
;
; Witness: L1 63 (c1, deaths, gameover, menu, opt x3).
PrintStoryPicture:
  PUSH IY
  POP HL
  LD BC,StoryFont
  CALL PrintStoryString
  JR NextStoryString

; Print the text string at IY with PrintString; IY = the next string
;
; Witness: L1 54 (c1, deaths, gameover, menu, opt x3).
PrintStoryText:
  PUSH IY
  POP HL
  CALL PrintString

; IY = HL: the string after the one printed
;
; Witness: L1 117 (c1, deaths, gameover, menu, opt x3).
NextStoryString:
  PUSH HL
  POP IY
  RET

; Build and print a box frame of B x C characters at DE
;
; Builds a PrintString record in BoxString $5B01: the position DE, style bytes
; 6 and 6, the top row ($22, $23 x (B - 2), $24), C - 2 middle rows ($25, a
; skip of B - 2 columns, $25), the bottom row ($27, $28 x (B - 2), $29), rows
; ended by $FF, the record by 0, and prints it: the frame glyphs $22-$29 of the
; game font.
;
; Witness: L1 27 (c1, deaths, gameover, menu, opt x3).
DrawStoryBox:
  LD (BoxString),DE
  LD A,$06
  LD (BoxString+2),A
  LD (BoxString+3),A
  LD HL,BoxString+4
  PUSH BC
  LD E,$22
  LD D,$24
  LD A,$23
  CALL BoxEdgeRow
  LD (HL),$FF             ; the end of the top row
  INC HL
  POP BC
  DEC C
  DEC C
BoxMiddleRows:
  PUSH BC
  CALL BoxMiddleRow
  POP BC
  DEC C
  JR NZ,BoxMiddleRows
  LD E,$27                ; the bottom row
  LD D,$29
  LD A,$28
  CALL BoxEdgeRow
  LD (HL),$00
  LD HL,BoxString
  CALL PrintString
  RET

; Write a box row: E, then A x (B - 2), then D
;
; HL = the buffer; returns HL past the row.
;
; Witness: L1 54 (c1, deaths, gameover, menu, opt x3).
BoxEdgeRow:
  DEC B
  DEC B
  LD (HL),E
  INC HL
BoxEdgeLoop:
  LD (HL),A
  INC HL
  DJNZ BoxEdgeLoop
  LD (HL),D
  INC HL
  RET

; Write a box middle row: $25, a skip of B - 2, $25, $FF
;
; A code below $20 in a PrintString text moves the print position by that many
; columns: the box's inside is left as it is.
;
; Witness: L1 297 (c1, deaths, gameover, menu, opt x3).
BoxMiddleRow:
  DEC B
  DEC B
  LD (HL),$25
  INC HL
  LD (HL),B
  INC HL
  LD (HL),$25
  INC HL
  LD (HL),$FF
  INC HL
  RET

; Picture: Hiro's closed eyes, 6 x 3 glyphs at Y $98 X $32
StoryEyesClosed:
  INCBIN "res/texts/story.bin",$0000,23

; "FOR 10000 YEARS HE SLEPT. / HIS MIND FEEDING... / ON THE NIGHTMARES OF THE
; WEAK."
;
; A PrintString record: Y $60, X 2, style $07 $47, the text, $FF line breaks,
; 0.
StoryText1:
  INCBIN "res/texts/story.bin",$0017,81

; "NOW HE HAS AWAKENED", blank lines around it to rub out the first text
StoryText2:
  INCBIN "res/texts/story.bin",$0068,81

; Picture: the eyes opening, frame 1 (3 x 2 glyphs at Y $98 X $34)
StoryEyesOpen1:
  INCBIN "res/texts/story.bin",$00B9,10

; Picture: the eyes opening, frame 2
StoryEyesOpen2:
  INCBIN "res/texts/story.bin",$00C3,10

; Picture: the eyes open
StoryEyesOpen3:
  INCBIN "res/texts/story.bin",$00CD,10

; Picture: the whole Fireblade, 3 x 12 glyphs at Y $20 X 4
StoryFireblade:
  INCBIN "res/texts/story.bin",$00D7,50

; "AS THE NIGHT BLED CRIMSON / THE FIREBLADE SHATTERED / AND ITS POWER DIED."
StoryText3:
  INCBIN "res/texts/story.bin",$0109,74

; Picture: the shattered Fireblade, 3 x 12 glyphs
StoryBladeShattered:
  INCBIN "res/texts/story.bin",$0153,50

; "THEN THE SLAUGHTER BEGAN."
StoryText4:
  INCBIN "res/texts/story.bin",$0185,76

; Picture: Havok's portrait, 16 x 13 glyphs at Y 8 X $10
StoryPortrait:
  INCBIN "res/texts/story.bin",$01D1,223

; "THEY NEVER / THOUGHT HE WOULD RETURN. / NOW HAVOK REIGNS THE UNDERCITY."
StoryText5:
  INCBIN "res/texts/story.bin",$02B0,100

; "I AM HIRO, / THE LAST OF THE BLADEKNIGHTS. / I MUST REBUILD THE FIREBLADE, /
; AND BRING THE DAWN..."
StoryText6:
  INCBIN "res/texts/story.bin",$0314,132

; Print a picture string in the font at BC
;
; HL = the string (Y, X, then glyph codes: 0 the end, $FF the next line, n
; glyph n - 1 of the font), BC = the font. Uses PrintPosition and PrintGlyph of
; the main memory; returns HL past the 0.
;
; Witness: L1 63 (c1, deaths, gameover, menu, opt x3).
PrintStoryString:
  PUSH BC
  LD B,(HL)
  INC HL
  LD C,(HL)
  PUSH HL
  CALL PrintPosition
  POP HL
  POP BC
  INC HL
PrintStoryLoop:
  LD A,(HL)
  INC HL
  OR A
  RET Z
  PUSH BC
  PUSH HL
  INC A
  JR Z,PrintStoryNewLine
  DEC A
  DEC A
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,BC
  CALL PrintGlyph
PrintStoryNext:
  POP HL
  POP BC
  JR PrintStoryLoop
PrintStoryNewLine:
  LD BC,(PrintNextLine)           ; $FF: the next line (PrintNextLine)
  CALL PrintPosition
  JR PrintStoryNext

; Copy a block of C x B attributes from HL to the screen at DE
;
; C bytes a row, B rows, DE + 32 a row.
;
; Witness: L1 207 (c1, deaths, gameover, menu, opt x3).
CopyAttrBlock:
  PUSH BC
  PUSH DE
  LD B,$00
  LDIR
  POP DE
  LD A,$20
  ADD A,E
  LD E,A
  LD A,$00
  ADC A,D
  LD D,A
  POP BC
  DJNZ CopyAttrBlock
  RET

; Attributes, 3 x 5: the Fireblade's colours (page 2)
StoryAttrs1:
  INCBIN "res/graphics/story-attrs.bin",$0000,15

; Attributes, 3 x 5: the flash (page 2)
StoryAttrs2:
  INCBIN "res/graphics/story-attrs.bin",$000F,15

; Attributes, 16 x 13: Havok's portrait (page 3)
PortraitAttrs:
  INCBIN "res/graphics/story-attrs.bin",$001E,208

; The story font: 237 glyphs of 8 bytes (codes 1-$ED), the pictures' tiles
;
; Read through PrintStoryString $D863 (BC = StoryFont): every glyph is read
; when the intro runs.
StoryFont:
  INCBIN "res/graphics/story-font.bin",$0000,1896
