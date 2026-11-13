; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The menu: PRESS SPACE TO SELECT, three lines, the moving highlight, SPACE takes the line
;
; Menu $99A8 prints PRESS SPACE TO SELECT (small font, line 68) and START GAME, DEFINE KEYS, SELECT JOYSTICK (large
; font, lines 84, 100, 116), then MenuHighlight $99E2 moves a two-row attribute bar over them: every two frames (HALT,
; HALT) the bar on line E gets the next colour of MenuBarColours $9A33 (bright red, magenta, green, cyan, yellow and
; back: the line flashes); after 48 passes (96 frames) E goes to the next line, 0-1-2-0. SPACE, read once a pass,
; takes the line E: the four text lines are wiped and the choice runs. D and E are registers kept on the stack, both 0
; at each entry, so the highlight starts on START GAME every time the menu is drawn.
;
; START GAME (StartGame $99DD) clears the screen and returns to the resident at $F090 (the stage loader with stage 1's
; record $F0EA); DEFINE KEYS (DefineKeys $971A) and SELECT JOYSTICK (SelectJoystick $97D8) come back to Menu. c1: the
; menu loop from frame 8195, the highlight on DEFINE KEYS at 8289, on SELECT JOYSTICK at 8385, on START GAME at 8481,
; SPACE at 8490 taken at 8491 (c1 branches $9A15, $9A1E, $9A2A).
; --------------------------------------------------------------------------------------------------------------------

  ORG $99A8

; The menu: draw it, the highlight until SPACE, wipe, then the chosen line's
; action
;
; MenuTitle $A166, MenuHook $980A, MenuLines $A184, MenuHighlight $99E2 (E =
; the line), ClearTextLine with 68, 84, 100, 116, then E = 0 StartGame $99DD, 1
; DefineKeys $971A, 2 SelectJoystick $97D8 (JP, no return: they JP back here).
;
; c1: entered at frame 8127 (the front's bytes: $99A8 to $99C9 ran once), START
; GAME. menu: the recording starts inside MenuHighlight: DEFINE KEYS taken
; (dispatch at frame 71), the menu again at 1354, START GAME at 1552.
Menu:
  CALL MenuTitle
  CALL MenuHook
  CALL MenuLines
  CALL MenuHighlight
MenuWipe:
  PUSH DE                 ; wipe the four lines, E kept
  LD A,$44
  CALL ClearTextLine
  LD A,$54
  CALL ClearTextLine
  LD A,$64
  CALL ClearTextLine
  LD A,$74
  CALL ClearTextLine
  POP DE
MenuDispatch:
  LD A,E                  ; E: 0 START GAME, 1 DEFINE KEYS, 2 SELECT JOYSTICK
  CP $00
  JP Z,StartGame
  CP $01
  JP Z,DefineKeys
  CP $02
  JP Z,SelectJoystick
MenuOther:
  JP Menu                 ; any other E (none: MenuHighlight gives 0-2)
StartGame:
  CALL ClearScreen        ; START GAME: clear the screen, drop FrontMain's
                          ; return, RET to the resident at $F090
  POP HL
  RET

; The moving highlight over the 3 menu lines until SPACE; E = the line taken
;
; D = 0 (the pass, 0-47), E = 0 (the line). A pass: HALT, HALT, ShimmerFrame
; $79AE, PaintBoxColours $7971 (which also clears the last bar), then
; FillAttrBox $9D31 over column 7, row 10 + 2E, 18 x 2 cells with
; MenuBarColours[D AND 7] (the row and the colour are patched into its
; parameters at $9A0C and $9A0F); D + 1; D = 48: D = 0 and E + 1 (3: E = 0).
; Then SPACE (port $7FFE bit 0): held, return with E; else the next pass. 2
; frames a pass, 96 frames a line, 288 a cycle.
;
; c1: 149 passes, frames 8195-8491 (2 frames each), E moved at 8289, 8385, 8481
; (to 0), SPACE at 8491 on START GAME. menu: 38 passes in two entries, DEFINE
; KEYS at frame 7 (E = 1 already in menu.szx), START GAME at 1488.
MenuHighlight:
  LD E,$00
  LD D,$00
MenuHighlightPass:
  PUSH BC                 ; two frames, the effects, the bar
  PUSH DE
  HALT
  HALT
  CALL ShimmerFrame
  CALL PaintBoxColours
  POP DE
  PUSH DE
  LD A,D
  AND $07
  LD C,A
  LD B,$00
  LD HL,MenuBarColours
  ADD HL,BC
  LD A,(HL)
  LD (MenuHighlightPass+$0029),A
  LD A,E
  SLA A
  ADD A,$0A
  LD (MenuHighlightPass+$0026),A
  CALL FillAttrBox
  DEFB $07,$0A,$12,$02,$00
MenuHighlightStep:
  POP DE                  ; the next pass; 48 passes a line
  INC D
  LD A,D
  CP $30
  JP NZ,MenuReadSpace
  LD D,$00
  INC E
  LD A,E
  CP $03
  JP NZ,MenuReadSpace
  LD E,$00
MenuReadSpace:
  LD BC,$7FFE             ; SPACE: the line E is taken
  IN A,(C)
  BIT 0,A
  JP Z,MenuHighlightTaken
  POP BC
  JP MenuHighlightPass
MenuHighlightTaken:
  POP BC                  ; SPACE held: return with E
  RET

; The menu bar's 8 colours, one a pass: $42 $43 $44 $45 $46 $45 $44 $43 (bright
; red, magenta, green, cyan, yellow on black)
;
; Read by MenuHighlight $99E2 (index D AND 7). menu: all 8 read.
MenuBarColours:
  INCBIN "res/front/menu-bar.bin",$0000,8

  ORG $A166

; PRESS SPACE TO SELECT on line 68 (small font)
;
; c1: frame 8127; menu: frame 1354.
MenuTitle:
  CALL PrintText

; PrintText: small font, byte 8, shift 2, line 68: PRESS SPACE TO SELECT
TextPressSpaceToSelect:
  INCBIN "res/front-texts/press-space-to-select.bin",$0000,26

; MenuTitle's RET
;
; c1: frame 8144; menu: frame 1371.
MenuTitleDone:
  RET

; START GAME, DEFINE KEYS, SELECT JOYSTICK on lines 84, 100, 116 (large font)
;
; c1: frames 8144-8193; menu: 1371-1420.
MenuLines:
  CALL PrintText

; PrintText: large font, byte 11, shift 5, line 84: START GAME
TextStartGame:
  INCBIN "res/front-texts/start-game.bin",$0000,15

; The second line
;
; MenuLines, continued. c1: frame 8160; menu: 1387.
MenuLines2:
  CALL PrintText

; PrintText: large font, byte 11, shift 4, line 100: DEFINE KEYS
TextDefineKeys:
  INCBIN "res/front-texts/define-keys.bin",$0000,16

; The third line
;
; MenuLines, continued. c1: frame 8176; menu: 1403.
MenuLines3:
  CALL PrintText

; PrintText: large font, byte 9, shift 7, line 116: SELECT JOYSTICK
TextSelectJoystick:
  INCBIN "res/front-texts/select-joystick.bin",$0000,20

; MenuLines's RET
;
; c1: frame 8193; menu: 1420.
MenuLinesDone:
  RET
