; --------------------------------------------------------------------------------------------------------------------
; help.asm: Help: the 48K warning and the instructions, four text pages
;
; ShowHelp $C536 runs on FIRE over the Help box. A 48K first shows Help48KText $C5F9 (choose now, restart the tape; a
; new explorer means reloading); ENTER goes back to the selector, SPACE on. Then the instructions: HelpTitle $C708
; (TERRAMEX INSTRUCTIONS, about 2.9 s), HelpPage1 $C721 (the story), HelpPage2 $C97F (the quest), HelpPage3 $CB7D (the
; bearers and the keys). SPACE turns a page (after page 3 back to the title), ENTER returns to the selector
; (SelectorRestart $C106).
;
; PrintPage $C574 draws a page on a cleared screen (blue border and paper, white ink) from bytes: $16 column, row =
; position; $0D = the next row, column 0; $01 = pause about 10.2 M T-states (6 x 65 536 turns of a 26 T loop) and
; return; $00 = wait for SPACE (A = 1, NZ) or ENTER (A = 0, Z) and return; any other byte = a ROM-font glyph, the
; column wrapping at 32.
; --------------------------------------------------------------------------------------------------------------------

; Show the Help pages until ENTER, then back to the selector
;
; Reached by JP from SelectorLoop $C112 with FIRE on the Help box (Explorer
; $5B70 = $FE). Has128K $5FFE = 0: Help48KText $C5F9 first, then the keyboard
; must be released. Then the title and page 1, page 2, page 3 in a loop while
; SPACE answers; ENTER at any page jumps to SelectorRestart $C106.
;
; explorers: once (frames 13 750-15 190): the title and page 1 three times,
; pages 2 and 3 twice each.
;
; Witness: L1 1 (explorers).
ShowHelp:
  LD A,(Has128K)
  OR A
  JR NZ,HelpPagesLoop
  LD HL,Help48KText
  CALL PrintPage
  PUSH AF
WaitKeysUp:
  XOR A                   ; until no key is down
  IN A,($FE)
  AND $1F
  CP $1F
  JR NZ,WaitKeysUp
  POP AF
  OR A
  JR Z,HelpReturn
HelpPagesLoop:
  LD HL,HelpTitle         ; the title (pause), page 1
  CALL PrintPage
  LD HL,HelpPage1
  CALL PrintPage
  OR A
HelpReturn:
  JP Z,SelectorRestart    ; ENTER: back to the selector
  LD HL,HelpPage2         ; page 2
  CALL PrintPage
  OR A
  JR Z,HelpReturn
  LD HL,HelpPage3         ; page 3; SPACE repeats from the title
  CALL PrintPage
  JP Z,SelectorRestart
  JR HelpPagesLoop

; Clear the screen to blue and print a page of text bytes; A = 1 for SPACE, 0
; for ENTER
;
; In: HL = the page. Border 1, bitmap $4000-$57FF cleared, attributes $0F; B =
; row, C = column from 0, 0. The byte codes: $16 c r position, $0D next row,
; $01 pause and return (A = 0), $00 wait for SPACE or ENTER and return, else
; PrintGlyph $C4BB at H = $40 OR (B AND $18), L = (B x 32 AND $E0) OR C, the
; column wrapping at 32. Out: A = 1 (NZ) for SPACE, 0 (Z) for ENTER or after a
; pause.
;
; explorers: 10 calls, 3878 glyphs, 3 pauses.
;
; Witness: L1 10 (explorers).
PrintPage:
  PUSH HL
  LD A,$01
  OUT ($FE),A
  LD HL,Screen
  LD DE,Screen+1
  LD (HL),L
  LD BC,$1800
  LDIR
  LD HL,Attributes
  LD DE,Attributes+1
  LD (HL),$0F
  LD BC,$02FF
  LDIR
  POP HL
  LD BC,$0000
PageNextByte:
  LD A,(HL)
  INC HL
  CP $16
  JR NZ,PageControl
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  JR PageNextByte
PageControl:
  CP $01                  ; not a position
  JR NZ,PageEndOrCr
  LD DE,$0000             ; $01: pause and return
  LD B,$06
PauseLoop:
  DEC DE                  ; 6 x 65 536 turns of 26 T-states
  LD A,E
  OR D
  JR NZ,PauseLoop
  DJNZ PauseLoop
  RET
PageEndOrCr:
  OR A                    ; $00 ends the page
  JR Z,WaitSpaceOrEnter
  CP $0D
  JR NZ,PrintPageGlyph
  INC B                   ; $0D: next row
  LD C,$00
  JR PageNextByte
PrintPageGlyph:
  PUSH BC                 ; a glyph at row B, column C
  PUSH HL
  EX AF,AF'
  LD A,B
  AND $18
  OR $40
  LD H,A
  RRC B
  RRC B
  RRC B
  LD A,B
  AND $E0
  OR C
  LD L,A
  EX AF,AF'
  CALL PrintGlyph
  POP HL
  POP BC
  INC C
  LD A,C
  CP $20
  JR NZ,PageGlyphDone
  LD C,$00
  INC B
PageGlyphDone:
  JR PageNextByte         ; next byte
WaitSpaceOrEnter:
  LD BC,$7FFE             ; SPACE: A = 1; ENTER: A = 0
  IN A,(C)
  AND $01
  JR Z,SpacePressed
  LD BC,$BFFE
  IN A,(C)
  AND $01
  RET Z
  JR WaitSpaceOrEnter
SpacePressed:
  INC A
  RET

; Help on a 48K: choose now, restart the tape; SPACE goes on, ENTER returns
;
; PrintPage $C574 text: " As you have a 48K machine you must choose your
; explorer now and then load in the rest of the program. Restart the tape when
; you have chosen your explorer. You will have to switch off and reload the
; tape to choose a new explorer.", then at column 0, row 23 "<SPACE> Continue
; <ENTER> Returns" and $00. Not read in any recording (128K); known only from
; the code.
Help48KText:
  INCBIN "res/texts/help-48k.bin",$0000,271

; The title card: TERRAMEX INSTRUCTIONS at column 5, row 10, then $01 (pause)
;
; explorers reads it three times (ShowHelp $C536).
HelpTitle:
  INCBIN "res/texts/help-title.bin",$0000,25

; Instructions page 1: Professor Albert Eyestrain, the asteroid, his formula
;
; Professor Albert Eyestrain warned twenty years ago of a gigantic asteroid;
; ridiculed, he vanished, leaving a formula: "who finds it will be able to find
; me". The asteroid now hits within a month. Ends with "<SPACE> Continue
; <ENTER> Returns" at row 23 and $00.
HelpPage1:
  INCBIN "res/texts/help-page1.bin",$0000,606

; Instructions page 2: find the professor; 5 explorers; the VAC
;
; Find the professor and convince him to save the world; you are one of 5
; explorers in a desert mountain range with strange creatures and things that
; "do not behave normally"; a VAC flies over power sources in the ground
; ("Guess who made it ?").
HelpPage2:
  INCBIN "res/texts/help-page2.bin",$0000,510

; Instructions page 3: the invisible bearers and the keys
;
; Your invisible bearers carry things, but to use something you must carry it
; yourself. Keys: Z left, X right, O up, K down, SPACE jump; S swap the item
; with the nearest; 1 move bearers and objects right, 2 left; CAPS SHIFT + Q
; quits and restarts; the joystick is chosen on the title page; here up, down,
; left, right move the hand and FIRE selects. Ends with "<SPACE> Repeats
; <ENTER> Returns" and $00.
HelpPage3:
  INCBIN "res/texts/help-page3.bin",$0000,530
