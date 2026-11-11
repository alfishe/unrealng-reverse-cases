; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The menu, the title, the screen wipes
;
; GameEntry $8B20 (the BASIC's RANDOMIZE USR 35616) clears the variables, draws the title (DrawTitle $8AC8: the texts,
; the logo wiped in line by line, its colours), plays the title tune and reads keys 1-5 (MenuKeys $8B29): 1 a game, 2
; redefine the keys, 3 keyboard, 4 joystick, 5 reset. When the title tune runs out the high scores and the scroller
; show (ShowHiScores $B2E4), then the title tune again.
; --------------------------------------------------------------------------------------------------------------------

  ORG $85CF

; Clear the variables and set the start values
;
; ClearVars $821A, ResetGame $82E6.
;
; Witness: L1 9 (c1, lives, menu).
ResetAll:
  CALL ClearVars
  CALL ResetGame
  RET

  ORG $860E

; Clear the screen: attributes $47, then the pixel wipe
;
; Attributes $47 (bright white on black), WipeScreen $8DE3.
;
; Witness: L1 105 (c1, hiscore, lives, menu, timer, rzx x32).
ClearScreen:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$47
  LDIR
  CALL WipeScreen
  RET

  ORG $8979

; Wipe the title logo in, pixel line by line, from LogoPixels $B300
;
; 64 lines: each a Pause $8C0E, then the 32 bytes of the line and every 8th
; line below it from $B300 (the screen address + $7300).
;
; Witness: L1 9 (c1, lives, menu).
WipeInLogo:
  LD C,$00
WipeInLogoLoop:
  PUSH BC
  CALL Pause
  PUSH HL
  POP DE
  LD A,D
  ADD A,(LogoPixels-Screen)/256
  LD D,A
WipeInLogoLoop2:
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH HL
  POP BC
  PUSH DE
  POP HL
  PUSH BC
  POP DE
  LD BC,$0020
  LDIR
  POP HL
  POP DE
  POP BC
  INC C
  CALL LineAddr
  LD A,$48
  CP H
  JR NZ,WipeInLogoLoop2
  POP BC
  INC C
  LD A,$40
  CP C
  JR NZ,WipeInLogoLoop
  RET

  ORG $8A3C

; Print the menu's lines: MenuTexts $AB00 and ShowControlTexts $ECC5
;
; Witness: L1 10 (c1, lives, menu).
ShowMenuTexts:
  LD HL,MenuTexts
  LD D,$12
  LD BC,$0B04
  CALL PrintText
  LD HL,MenuRedefineText
  LD D,$15
  LD BC,$0D04
  CALL PrintText
  CALL ShowControlTexts
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD HL,MenuQuitText
  LD D,$11
  LD BC,$1304
  CALL PrintText
  LD HL,MenuCopyrightText
  LD D,$20
  LD BC,$1700
  CALL PrintText
  RET

; Fill D attributes with A from row B, column C
;
; Witness: L1 3260 (c1, hiscore, lives, menu, timer, rzx x32).
FillAttrs:
  PUSH AF
  PUSH DE
  PUSH BC
  CALL AttrAddr
  POP BC
  POP DE
  POP AF
  LD (HL),A
  INC C
  DEC D
  JR NZ,FillAttrs
  RET

; Colour the menu's lines
;
; Witness: L1 10 (c1, lives, menu).
ColourMenuTexts:
  LD A,$44
  LD D,$12
  LD BC,$0B04
  CALL FillAttrs
  LD A,$46
  LD D,$15
  LD BC,$0D04
  CALL FillAttrs
  LD A,$46
  LD D,$18
  LD BC,$1104
  CALL FillAttrs
  LD A,$44
  LD D,$16
  LD BC,$1304
  CALL FillAttrs
  RET

  ORG $8B20

; The game's entry (RANDOMIZE USR 35616): reset, the title, the title tune, the
; menu
;
; ResetAll $85CF, DrawTitle $8AC8, PlayTitleTune $8A35, then MenuKeys.
;
; Witness: L1 9 (c1, lives, menu).
GameEntry:
  CALL ResetAll
  CALL DrawTitle
; This entry point is used by the routine at MenuKeys.
GameEntryLoop:
  CALL PlayTitleTune

; Keys 1-5 of the menu; the high scores when the title tune ran out
;
; HL = PlayTune's end; HL = $B269 (TitleTune's end) runs ShowHiScores $B2E4.
; Key 1 NewGame $8BE5, 2 RedefineKeys $8C30, 3 and 4 ChooseControl $ECE3, 5
; ResetMachine $8B65.
;
; Witness: L1 11 (c1, lives, menu, rzx x1).
MenuKeys:
  LD DE,TitleTune+$0569
  SBC HL,DE
  JR NZ,MenuKeysSkip
  CALL ShowHiScores
  JR Z,GameEntryLoop
MenuKeysSkip:
  LD A,$F7
  OUT ($FF),A
  IN A,($FE)
  AND $01
  JR NZ,MenuKeysSkip2
  CALL NewGame
  JP GameEntry
MenuKeysSkip2:
  LD A,$F7
  OUT ($FF),A
  IN A,($FE)
  AND $02
  JR NZ,MenuKeysSkip3
  CALL RedefineKeys
  JP GameEntry
MenuKeysSkip3:
  JP ChooseControl

; Leftover: 13 bytes, never run
MenuKeysPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00

; Key 5: interrupts off, then JP 0 (the machine resets)
;
; Witness: L1 1 (menu).
ResetMachine:
  LD A,$F7
  OUT ($FF),A
  IN A,($FE)
  AND $10
  JR NZ,ResetMachineSkip
  JP $0000
ResetMachineSkip:
  JP GameEntry

; Leftover: 3 bytes, never run
ResetMachinePad:
  DEFB $00,$00,$00

  ORG $8DE3

; Wipe the pixels away: 8 passes shifting each byte pair apart
;
; Witness: L1 105 (c1, hiscore, lives, menu, timer, rzx x32).
WipeScreen:
  DI
  LD B,$08
WipeScreenLoop:
  PUSH BC
  LD HL,Screen
  LD B,$C0
WipeScreenLoop2:
  PUSH BC
  LD B,$10
WipeScreenLoop3:
  SRL (HL)
  INC HL
  SLA (HL)
  INC HL
  DJNZ WipeScreenLoop3
  POP BC
  DJNZ WipeScreenLoop2
  POP BC
  DJNZ WipeScreenLoop
  EI
  RET

  ORG $9091

; Wipe in the logo, copy LogoAttrs $FC00 to the top third's attributes
;
; Witness: L1 9 (c1, lives, menu).
ShowLogo:
  CALL WipeInLogo
  LD HL,LogoAttrs
  LD DE,Attributes
  LD BC,$0100
  LDIR
  RET

  ORG $AB00

; The menu's lines
MenuTexts:
  INCBIN "res/texts/menu.bin",$0000,18
MenuRedefineText:
  INCBIN "res/texts/menu.bin",$0012,21
MenuDemoText:
  INCBIN "res/texts/menu.bin",$0027,17
MenuQuitText:
  INCBIN "res/texts/menu.bin",$0038,17
MenuCopyrightText:
  INCBIN "res/texts/menu.bin",$0049,33

  ORG $AC2E

; Leftover: the 1988 credit line, never printed
Credits:
  INCBIN "res/texts/credits.bin",$0000,49

  ORG $B300

; The title logo's pixels: 2048 bytes laid out as the screen's top third
LogoPixels:
  INCBIN "res/graphics/logo.bin",$0000,2048

  ORG $FC00

; The logo's attributes (8 rows of 32)
LogoAttrs:
  INCBIN "res/graphics/logo-attrs.bin",$0000,256
