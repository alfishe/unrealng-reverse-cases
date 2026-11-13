; --------------------------------------------------------------------------------------------------------------------
; credits.asm: The credits: seven pages printed and wiped in a loop until SPACE
;
; CreditsLoop $9509 prints seven pages into the logo box, each line revealed by PrintText $9D72's dissolve: PROGRAMMED
; BY / NEIL DODWELL, GRAPHICS BY / CONCEPT ANIMATIONS, PRODUCED BY / SYSTEM THREE, ORIGINAL GAME DESIGN / MARK CALE,
; SOUND EFFECTS BY / NEIL DODWELL, DEVELOPED / IN ASSOCIATION WITH / MARJACQ MICRO, COPYRIGHT 1989 / SYSTEM 3 SOFTWARE
; / PRESS SPACE TO START. The headings are in the small font, the names in the large one. Each page: WaitOrSpace $9BA5
; with BC = 20 (40 frames), the page, BC = 70 (140 frames; 100, 200 frames, after the last page), the page's lines
; wiped (ClearTextLine $9D65), then the next. SPACE is read only inside WaitOrSpace: there it drops CreditsLoop's
; return and returns to FrontMain. A SPACE during a reveal (16 frames a line) is not seen.
;
; Each text is a resource in src/res/front-texts/ (font, start byte, pixel shift and screen line, then the text).
; --------------------------------------------------------------------------------------------------------------------

  ORG $9509

; The credits' seven pages, round and round until SPACE in one of the waits
;
; No input; returns (through WaitOrSpace's dropped return) when SPACE is held
; at the end of a wait's pass. Every page waits 40 frames, prints its lines,
; waits 140 frames (200 after the last) and wipes its lines with ClearTextLine
; $9D65. Writes the screen in the box (pixel lines 68-122, columns 7-24),
; TextBuffer and the variables of PrintText.
;
; c1: entered at frame 7967; page 1 printed at 8007-8039, SPACE seen at 8063 in
; its 140-frame wait (WaitOrSpace's abort ran once, c1 branch $9BB1 taken
; once): the credits ended on page 1. menu: not reached. Pages 2-7 are known
; only from the code.
;
; Witness: L1 2 (c1, rzx-r0).
CreditsLoop:
  LD BC,$0014
  CALL WaitOrSpace
  CALL PrintText

; PrintText: small font, byte 11, line 84: PROGRAMMED BY
TextProgrammedBy:
  INCBIN "res/front-texts/programmed-by.bin",$0000,18

; Page 1's second line
;
; CreditsLoop, continued after its string. c1: run once, frame 8023 (the
; front's bytes).
;
; Witness: L1 2 (c1, rzx-r0).
CreditsPage1Name:
  CALL PrintText

; PrintText: large font, byte 11, shift 2, line 100: NEIL DODWELL
TextNeilDodwell:
  INCBIN "res/front-texts/neil-dodwell.bin",$0000,17

; Hold page 1 for 140 frames, wipe it, page 2 heading
;
; CreditsLoop, continued: WaitOrSpace 70 (c1: SPACE ended the credits here,
; frame 8063), ClearTextLine with the lines 84 and 100, WaitOrSpace 20, then
; GRAPHICS BY.
;
; Witness: L1 2 (c1, rzx-r0).
CreditsPage2:
  LD BC,$0046
  CALL WaitOrSpace
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD BC,$0014
  CALL WaitOrSpace
  CALL PrintText

; PrintText: small font, byte 11, shift 7, line 84: GRAPHICS BY
TextGraphicsBy:
  INCBIN "res/front-texts/graphics-by.bin",$0000,16

; Page 2's second line
;
; CreditsLoop, continued. Not executed in any recording (c1 left the credits on
; page 1).
;
; Witness: L1 0 ().
CreditsPage2Name:
  CALL PrintText

; PrintText: large font, byte 8, line 100: CONCEPT ANIMATIONS
TextConceptAnimations:
  INCBIN "res/front-texts/concept-animations.bin",$0000,23

; Hold, wipe, page 3 heading
;
; CreditsLoop, continued: as CreditsPage2. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage3:
  LD BC,$0046
  CALL WaitOrSpace
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD BC,$0014
  CALL WaitOrSpace
  CALL PrintText

; PrintText: small font, byte 11, shift 7, line 84: PRODUCED BY
TextProducedBy:
  INCBIN "res/front-texts/produced-by.bin",$0000,16

; Page 3's second line
;
; CreditsLoop, continued. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage3Name:
  CALL PrintText

; PrintText: large font, byte 11, line 100: SYSTEM THREE
TextSystemThree:
  INCBIN "res/front-texts/system-three.bin",$0000,17

; Hold, wipe, page 4 heading
;
; CreditsLoop, continued: as CreditsPage2. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage4:
  LD BC,$0046
  CALL WaitOrSpace
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD BC,$0014
  CALL WaitOrSpace
  CALL PrintText

; PrintText: small font, byte 8, shift 5, line 84: ORIGINAL GAME DESIGN
TextOriginalGameDesign:
  INCBIN "res/front-texts/original-game-design.bin",$0000,25

; Page 4's second line
;
; CreditsLoop, continued. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage4Name:
  CALL PrintText

; PrintText: large font, byte 12, line 100: MARK CALE
TextMarkCale:
  INCBIN "res/front-texts/mark-cale.bin",$0000,14

; Hold, wipe, page 5 heading
;
; CreditsLoop, continued: as CreditsPage2. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage5:
  LD BC,$0046
  CALL WaitOrSpace
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD BC,$0014
  CALL WaitOrSpace
  CALL PrintText

; PrintText: small font, byte 10, line 84: SOUND EFFECTS BY
TextSoundEffectsBy:
  INCBIN "res/front-texts/sound-effects-by.bin",$0000,21

; Page 5's second line
;
; CreditsLoop, continued. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage5Name:
  CALL PrintText

; PrintText: large font, byte 11, shift 2, line 100: NEIL DODWELL (the same
; bytes as TextNeilDodwell)
TextNeilDodwellSound:
  INCBIN "res/front-texts/neil-dodwell-sound.bin",$0000,17

; Hold, wipe, page 6's first line
;
; CreditsLoop, continued: as CreditsPage2, then DEVELOPED on line 68. Not
; executed in any recording.
;
; Witness: L1 0 ().
CreditsPage6:
  LD BC,$0046
  CALL WaitOrSpace
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD BC,$0014
  CALL WaitOrSpace
  CALL PrintText

; PrintText: small font, byte 12, shift 5, line 68: DEVELOPED
TextDeveloped:
  INCBIN "res/front-texts/developed.bin",$0000,14

; Page 6's second line
;
; CreditsLoop, continued. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage6Line2:
  CALL PrintText

; PrintText: small font, byte 8, shift 7, line 84: IN ASSOCIATION WITH
TextInAssociationWith:
  INCBIN "res/front-texts/in-association-with.bin",$0000,24

; Page 6's third line
;
; CreditsLoop, continued. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage6Line3:
  CALL PrintText

; PrintText: large font, byte 10, shift 1, line 116: MARJACQ MICRO
TextMarjacqMicro:
  INCBIN "res/front-texts/marjacq-micro.bin",$0000,18

; Hold page 6, wipe lines 68, 84 and 116, page 7's first line
;
; CreditsLoop, continued: WaitOrSpace 70, ClearTextLine with 68, 84, 116,
; WaitOrSpace 20, COPYRIGHT 1989. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage7:
  LD BC,$0046
  CALL WaitOrSpace
  LD A,$44
  CALL ClearTextLine
  LD A,$54
  CALL ClearTextLine
  LD A,$74
  CALL ClearTextLine
  LD BC,$0014
  CALL WaitOrSpace
  CALL PrintText

; PrintText: small font, byte 10, shift 6, line 68: COPYRIGHT 1989
TextCopyright1989:
  INCBIN "res/front-texts/copyright-1989.bin",$0000,19

; Page 7's second line
;
; CreditsLoop, continued. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage7Line2:
  CALL PrintText

; PrintText: small font, byte 9, shift 2, line 84: SYSTEM 3 SOFTWARE
TextSystem3Software:
  INCBIN "res/front-texts/system-3-software.bin",$0000,22

; Page 7's third line
;
; CreditsLoop, continued. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage7Line3:
  CALL PrintText

; PrintText: small font, byte 8, shift 3, line 116: PRESS SPACE TO START
TextPressSpaceToStart:
  INCBIN "res/front-texts/press-space-to-start.bin",$0000,25

; Hold page 7 for 200 frames, wipe lines 68, 100 and 116, wait, start again at
; page 1
;
; CreditsLoop, continued: WaitOrSpace 100, ClearTextLine with 68, 100 and 116
; (line 84, SYSTEM 3 SOFTWARE, is left: page 1's heading is revealed over it),
; WaitOrSpace 20, JP CreditsLoop. Not executed in any recording.
;
; Witness: L1 0 ().
CreditsPage7End:
  LD BC,$0064
  CALL WaitOrSpace
  LD A,$44
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD A,$74
  CALL ClearTextLine
  LD BC,$0014
  CALL WaitOrSpace
  JP CreditsLoop
